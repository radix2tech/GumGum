//Batch to create and calculate Account Forecast

public class AccountForecastBatch implements Database.Batchable<sObject>,Schedulable  {

    // Method to start the batch job and define the query
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = Label.AccountForecastBatchQuery;
        return Database.getQueryLocator(query);
    }
    
    // Execute method processes each batch of records
    public void execute(Database.BatchableContext info, List<Advertiser_Agency_Relationship__c> scope) {
        Set<Id> AdvertiserIds = new Set<Id>();
        Set<Id> AgencyIds = new Set<Id>();
        Map<String, Advertiser_Agency_Relationship__c> AdvertiserAgencyMap = new Map<String, Advertiser_Agency_Relationship__c>();
        Map<String, Account_Forecast__c> accountForecastMap = new Map<String, Account_Forecast__c>();
        
        // Collect Advertiser and Agency IDs, and prepare Account Forecast records
        for (Advertiser_Agency_Relationship__c AAR : scope) {
            AdvertiserIds.add(AAR.Advertiser__c);
            AgencyIds.add(AAR.Agency__c);
            AdvertiserAgencyMap.put(AAR.AdvertiserAgency__c, AAR);

            // Initialize Account Forecast if not already present
            if (accountForecastMap.get(AAR.AdvertiserAgency__c) == null) {
                Account_Forecast__c AFRecord = new Account_Forecast__c();
                if (AAR.Account_Forecasts__r != null && !AAR.Account_Forecasts__r.isEmpty()) {
                    AFRecord.Id = AAR.Account_Forecasts__r[0].Id;   
                } else {
                    AFRecord.Advertiser_Agency_Relationship__c = AAR.Id;
                }
                accountForecastMap.put(AAR.AdvertiserAgency__c, AFRecord);
            }
        }
        
        // Fetch Opportunity Line Item Schedule records
        List<OpportunityLineItemSchedule> oliScheduleList = [SELECT Id, ScheduleDate, Revenue, OpportunityLineItem.Opportunity.IsClosed, OpportunityLineItem.Opportunity.AccountId, OpportunityLineItem.Opportunity.Agency_Name__c 
                                                              FROM OpportunityLineItemSchedule 
                                                              WHERE (OpportunityLineItem.Opportunity.AccountId IN :AdvertiserIds) AND (OpportunityLineItem.Opportunity.StageName = 'Closed/Won') 
                                                              AND (ScheduleDate = THIS_YEAR OR ScheduleDate = NEXT_YEAR OR ScheduleDate = LAST_N_MONTHS:13)];

        // Calculate account forecast data based on the fetched schedules
        for (OpportunityLineItemSchedule oliSchedule : oliScheduleList) {
            String AdvertiserAgencyKey = oliSchedule.OpportunityLineItem.Opportunity.AccountId + '-' + oliSchedule.OpportunityLineItem.Opportunity.Agency_Name__c;
            if (accountForecastMap.get(AdvertiserAgencyKey) != null) {
                calculateAccountForecastData(oliSchedule, accountForecastMap.get(AdvertiserAgencyKey));    
            }
        }

        // Upsert the Account Forecast records and log any errors
        List<Database.UpsertResult> upsertaccountForecastResult = Database.upsert(accountForecastMap.values(), false);
        for (Integer i = 0; i < upsertaccountForecastResult.size(); i++) {
            Database.UpsertResult sr = upsertaccountForecastResult[i];
            if (!sr.isSuccess()) {
                for (Database.Error dberr : sr.getErrors()) {
                    System.debug('Error with Advertiser Agency Relationship: ' + accountForecastMap.values()[i].Advertiser_Agency_Relationship__c);
                    System.debug('Error message: ' + dberr.getMessage());
                }
            }
        }
    }
    
    // Method to calculate account forecast data based on the schedule
    public Account_Forecast__c calculateAccountForecastData(OpportunityLineItemSchedule oliSchedule, Account_Forecast__c AFRecord) {
        if (oliSchedule.OpportunityLineItem.Opportunity.IsClosed) {
            // Update current or next year bookings
            if (oliSchedule.ScheduleDate.year() == Date.today().year()) {
                AFRecord.Bookings_Current_Year__c = (AFRecord.Bookings_Current_Year__c == null ? 0 : AFRecord.Bookings_Current_Year__c) + oliSchedule.Revenue;
            } else if (oliSchedule.ScheduleDate.year() == (Date.today().year() + 1)) {
                AFRecord.Booking_Next_Year__c = (AFRecord.Booking_Next_Year__c == null ? 0 : AFRecord.Booking_Next_Year__c) + oliSchedule.Revenue;
            }

            // Set type for renewals
            if (oliSchedule.ScheduleDate <= Date.today()) {
                AFRecord.Type__c = 'Renewal';
            }
        } else {
            // Update pipeline forecasts based on the schedule date quarters
            if (checkScheduleDateQuarters(oliSchedule.ScheduleDate) == 1) {
                AFRecord.Pipeline_Current_Quarter__c = (AFRecord.Pipeline_Current_Quarter__c == null ? 0 : AFRecord.Pipeline_Current_Quarter__c) + oliSchedule.Revenue;
            } else if (checkScheduleDateQuarters(oliSchedule.ScheduleDate) == 2) {
                AFRecord.Pipeline_Next_Quarter__c = (AFRecord.Pipeline_Next_Quarter__c == null ? 0 : AFRecord.Pipeline_Next_Quarter__c) + oliSchedule.Revenue;
            }
        }
        
        return AFRecord;
    }
    
    // Empty finish method for batch completion
    public void finish(Database.BatchableContext bc) {
    }
    
    // Determine which quarter the schedule date falls into
    public Integer checkScheduleDateQuarters(Date scheduleDate) {
        Date today = Date.today();
        Integer currentMonth = today.month();
        Integer currentQuarter = (currentMonth - 1) / 3 + 1;

        // Determine the start and end dates of the current and next quarters
        Date currentQuarterStart = getQuarterStart(today.year(), currentQuarter);
        Date currentQuarterEnd = currentQuarterStart.addMonths(3).addDays(-1);
        Integer nextQuarter = currentQuarter == 4 ? 1 : currentQuarter + 1;
        Date nextQuarterStart = getQuarterStart(today.year(), nextQuarter);
        Date nextQuarterEnd = nextQuarterStart.addMonths(3).addDays(-1);

        // Check if ScheduleDate falls within current or next quarter
        if (scheduleDate >= currentQuarterStart && scheduleDate <= currentQuarterEnd) {
            return 1;
        } else if (scheduleDate >= nextQuarterStart && scheduleDate <= nextQuarterEnd) {
            return 2;
        }
        return 0;
    }

    // Helper method to get the start date of the quarter
    private Date getQuarterStart(Integer year, Integer quarter) {
        if (quarter == 1) return Date.newInstance(year, 1, 1);   // Q1: January
        if (quarter == 2) return Date.newInstance(year, 4, 1);   // Q2: April
        if (quarter == 3) return Date.newInstance(year, 7, 1);   // Q3: July
        return Date.newInstance(year, 10, 1);  // Q4: October
    }

    public void execute(SchedulableContext SC) {
        // Execute the batch job
        AccountForecastBatch batch = new AccountForecastBatch();
        Database.executeBatch(batch, 200); // 200 is the batch size
    }
}