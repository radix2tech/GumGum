//Batch to create and calculate Account Forecast
public class AccountForecastBatch implements Database.Batchable<sObject>,Schedulable  {

    public static final Id ActivationRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Activation').getRecordTypeId();
    public static final Id AdvertisingRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Advertising').getRecordTypeId();
    public static final Id VerityDemandRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Verity - Demand').getRecordTypeId();

    // Method to start the batch job and define the query
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = Label.AccountForecastBatchQuery;
        return Database.getQueryLocator(query);
    }
    
    // Execute method processes each batch of records
    public void execute(Database.BatchableContext info, List<Advertiser_Agency_Relationship__c> scope) {
        Set<Id> AdvertiserIds = new Set<Id>();
        Set<Id> PrimaryAccountForecastForAdvertisers = new Set<Id>();
        Map<String, Account_Forecast__c> accountForecastMap = new Map<String, Account_Forecast__c>();
        Map<String, Advertiser_Agency_Relationship__c> AARMap = new Map<String, Advertiser_Agency_Relationship__c>();
        List<Account_Forecast__c> AFListToUpsert = new List<Account_Forecast__c>();

        // Collect Advertiser and Agency IDs, and prepare Account Forecast records
        for (Advertiser_Agency_Relationship__c AAR : scope) {
            AdvertiserIds.add(AAR.Advertiser__c);
            AARMap.put(AAR.Advertiser__c +'-'+ AAR.Agency__c ,AAR);
        }


        // Fetch Opportunity Line Item Schedule records
        List<OpportunityLineItemSchedule> oliSchedulePipelineNextQuarterList = [SELECT Id, ScheduleDate, FORMAT(convertCurrency(Revenue)),CurrencyIsoCode, OpportunityLineItem.Opportunity.IsClosed,OpportunityLineItem.Opportunity.StageName, OpportunityLineItem.Opportunity.AccountId, OpportunityLineItem.Opportunity.Agency_Name__c 
                                                              FROM OpportunityLineItemSchedule 
                                                              WHERE (OpportunityLineItem.Opportunity.AccountId IN :AdvertiserIds)
                                                              AND (OpportunityLineItem.Opportunity.RecordTypeId = :ActivationRecordTypeId
                                                                    OR OpportunityLineItem.Opportunity.RecordTypeId = :AdvertisingRecordTypeId
                                                                    OR OpportunityLineItem.Opportunity.RecordTypeId = :VerityDemandRecordTypeId)
                                                              AND OpportunityLineItem.Opportunity.isClosed = false
                                                              AND (ScheduleDate = NEXT_QUARTER)];

        // Calculate account forecast data based on the fetched schedules
        for (OpportunityLineItemSchedule oliSchedule : oliSchedulePipelineNextQuarterList) {
            if (accountForecastMap.get(oliSchedule.OpportunityLineItem.Opportunity.AccountId+'-'+oliSchedule.OpportunityLineItem.Opportunity.Agency_Name__c) == null) {
                Account_Forecast__c AFRecord = new Account_Forecast__c();
                accountForecastMap.put(oliSchedule.OpportunityLineItem.Opportunity.AccountId+'-'+oliSchedule.OpportunityLineItem.Opportunity.Agency_Name__c,AFRecord);
            }
            Account_Forecast__c AFRecord = accountForecastMap.get(oliSchedule.OpportunityLineItem.Opportunity.AccountId+'-'+oliSchedule.OpportunityLineItem.Opportunity.Agency_Name__c);
            AFRecord.Pipeline_Next_Quarter__c = (AFRecord.Pipeline_Next_Quarter__c == null ? 0 : AFRecord.Pipeline_Next_Quarter__c) + oliSchedule.Revenue;
        }

        // Fetch Opportunity Line Item Schedule records
        List<OpportunityLineItemSchedule> oliSchedulePipelineCurrentQuarterList = [SELECT Id, ScheduleDate, FORMAT(convertCurrency(Revenue)),CurrencyIsoCode, OpportunityLineItem.Opportunity.IsClosed,OpportunityLineItem.Opportunity.StageName, OpportunityLineItem.Opportunity.AccountId, OpportunityLineItem.Opportunity.Agency_Name__c 
                                                              FROM OpportunityLineItemSchedule 
                                                              WHERE (OpportunityLineItem.Opportunity.AccountId IN :AdvertiserIds)
                                                              AND (OpportunityLineItem.Opportunity.RecordTypeId = :ActivationRecordTypeId
                                                                    OR OpportunityLineItem.Opportunity.RecordTypeId = :AdvertisingRecordTypeId
                                                                    OR OpportunityLineItem.Opportunity.RecordTypeId = :VerityDemandRecordTypeId)
                                                              AND OpportunityLineItem.Opportunity.isClosed = false
                                                              AND (ScheduleDate = THIS_QUARTER)];

        // Calculate account forecast data based on the fetched schedules
        for (OpportunityLineItemSchedule oliSchedule : oliSchedulePipelineCurrentQuarterList) {
            if (accountForecastMap.get(oliSchedule.OpportunityLineItem.Opportunity.AccountId+'-'+oliSchedule.OpportunityLineItem.Opportunity.Agency_Name__c) == null) {
                Account_Forecast__c AFRecord = new Account_Forecast__c();
                accountForecastMap.put(oliSchedule.OpportunityLineItem.Opportunity.AccountId+'-'+oliSchedule.OpportunityLineItem.Opportunity.Agency_Name__c,AFRecord);
            }
            Account_Forecast__c AFRecord = accountForecastMap.get(oliSchedule.OpportunityLineItem.Opportunity.AccountId+'-'+oliSchedule.OpportunityLineItem.Opportunity.Agency_Name__c);
            AFRecord.Pipeline_Current_Quarter__c = (AFRecord.Pipeline_Current_Quarter__c == null ? 0 : AFRecord.Pipeline_Current_Quarter__c) + oliSchedule.Revenue;
        }



        // Fetch Opportunity Line Item Schedule records
        List<OpportunityLineItemSchedule> oliScheduleBookingCurrentYearList = [SELECT Id, ScheduleDate, Revenue,CurrencyIsoCode, OpportunityLineItem.Opportunity.IsClosed,OpportunityLineItem.Opportunity.StageName,OpportunityLineItem.Opportunity.CloseDate, OpportunityLineItem.Opportunity.AccountId, OpportunityLineItem.Opportunity.Agency_Name__c 
                                                              FROM OpportunityLineItemSchedule 
                                                              WHERE (OpportunityLineItem.Opportunity.AccountId IN :AdvertiserIds)
                                                              AND (OpportunityLineItem.Opportunity.RecordTypeId = :ActivationRecordTypeId
                                                                    OR OpportunityLineItem.Opportunity.RecordTypeId = :AdvertisingRecordTypeId
                                                                    OR OpportunityLineItem.Opportunity.RecordTypeId = :VerityDemandRecordTypeId)
                                                              AND OpportunityLineItem.Opportunity.isClosed = true
                                                              AND OpportunityLineItem.Opportunity.StageName != 'Closed/Lost'
                                                              AND OpportunityLineItem.Opportunity.StageName != 'Discard' 
                                                              AND OpportunityLineItem.Opportunity.StageName = 'Closed/Won' 
                                                              AND (ScheduleDate = THIS_YEAR)];

        // Calculate account forecast data based on the fetched schedules
        for (OpportunityLineItemSchedule oliSchedule : oliScheduleBookingCurrentYearList) {
            if (accountForecastMap.get(oliSchedule.OpportunityLineItem.Opportunity.AccountId+'-'+oliSchedule.OpportunityLineItem.Opportunity.Agency_Name__c) == null) {
                Account_Forecast__c AFRecord = new Account_Forecast__c();
                accountForecastMap.put(oliSchedule.OpportunityLineItem.Opportunity.AccountId+'-'+oliSchedule.OpportunityLineItem.Opportunity.Agency_Name__c,AFRecord);
            }
            Account_Forecast__c AFRecord = accountForecastMap.get(oliSchedule.OpportunityLineItem.Opportunity.AccountId+'-'+oliSchedule.OpportunityLineItem.Opportunity.Agency_Name__c);
            if(oliSchedule.Revenue == null) oliSchedule.Revenue = 0;
            if(oliSchedule.Revenue > 0) oliSchedule.Revenue = oliSchedule.Revenue/CurrencyConversionUtility.getExchangeRate(oliSchedule.CurrencyIsoCode,oliSchedule.OpportunityLineItem.Opportunity.CloseDate);
            AFRecord.Bookings_Current_Year__c = (AFRecord.Bookings_Current_Year__c == null ? 0 : AFRecord.Bookings_Current_Year__c) + oliSchedule.Revenue.setScale(2);
        }

        // Fetch Opportunity Line Item Schedule records
        List<OpportunityLineItemSchedule> oliScheduleBookingNextYearList = [SELECT Id, ScheduleDate, Revenue,CurrencyIsoCode, OpportunityLineItem.Opportunity.IsClosed,OpportunityLineItem.Opportunity.StageName, OpportunityLineItem.Opportunity.CloseDate,OpportunityLineItem.Opportunity.AccountId, OpportunityLineItem.Opportunity.Agency_Name__c 
                                                              FROM OpportunityLineItemSchedule 
                                                              WHERE (OpportunityLineItem.Opportunity.AccountId IN :AdvertiserIds)
                                                              AND (OpportunityLineItem.Opportunity.RecordTypeId = :ActivationRecordTypeId
                                                                    OR OpportunityLineItem.Opportunity.RecordTypeId = :AdvertisingRecordTypeId
                                                                    OR OpportunityLineItem.Opportunity.RecordTypeId = :VerityDemandRecordTypeId)
                                                              AND OpportunityLineItem.Opportunity.isClosed = true
                                                              AND OpportunityLineItem.Opportunity.StageName != 'Closed/Lost'
                                                              AND OpportunityLineItem.Opportunity.StageName != 'Discard' 
                                                              AND OpportunityLineItem.Opportunity.StageName = 'Closed/Won' 
                                                              AND (ScheduleDate = NEXT_YEAR)];

        // Calculate account forecast data based on the fetched schedules
        for (OpportunityLineItemSchedule oliSchedule : oliScheduleBookingNextYearList) {
            if (accountForecastMap.get(oliSchedule.OpportunityLineItem.Opportunity.AccountId+'-'+oliSchedule.OpportunityLineItem.Opportunity.Agency_Name__c) == null) {
                Account_Forecast__c AFRecord = new Account_Forecast__c();
                accountForecastMap.put(oliSchedule.OpportunityLineItem.Opportunity.AccountId+'-'+oliSchedule.OpportunityLineItem.Opportunity.Agency_Name__c,AFRecord);
            }
            Account_Forecast__c AFRecord = accountForecastMap.get(oliSchedule.OpportunityLineItem.Opportunity.AccountId+'-'+oliSchedule.OpportunityLineItem.Opportunity.Agency_Name__c);
            if(oliSchedule.Revenue == null) oliSchedule.Revenue = 0;
            if(oliSchedule.Revenue > 0) oliSchedule.Revenue = oliSchedule.Revenue/CurrencyConversionUtility.getExchangeRate(oliSchedule.CurrencyIsoCode,oliSchedule.OpportunityLineItem.Opportunity.CloseDate);
            AFRecord.Booking_Next_Year__c = (AFRecord.Booking_Next_Year__c == null ? 0 : AFRecord.Booking_Next_Year__c) + oliSchedule.Revenue.setScale(2);
        }

        // Fetch Opportunity Line Item Schedule records
        List<OpportunityLineItemSchedule> oliScheduleRenewalList = [SELECT Id, ScheduleDate, FORMAT(convertCurrency(Revenue)),CurrencyIsoCode, OpportunityLineItem.Opportunity.IsClosed,OpportunityLineItem.Opportunity.StageName, OpportunityLineItem.Opportunity.AccountId, OpportunityLineItem.Opportunity.Agency_Name__c 
                                                              FROM OpportunityLineItemSchedule 
                                                              WHERE (OpportunityLineItem.Opportunity.AccountId IN :AdvertiserIds)
                                                              AND (OpportunityLineItem.Opportunity.RecordTypeId = :ActivationRecordTypeId
                                                                    OR OpportunityLineItem.Opportunity.RecordTypeId = :AdvertisingRecordTypeId
                                                                    OR OpportunityLineItem.Opportunity.RecordTypeId = :VerityDemandRecordTypeId)
                                                              AND OpportunityLineItem.Opportunity.isClosed = true
                                                              AND OpportunityLineItem.Opportunity.StageName != 'Closed/Lost'
                                                              AND OpportunityLineItem.Opportunity.StageName != 'Discard' 
                                                              AND OpportunityLineItem.Opportunity.StageName = 'Closed/Won' 
                                                              AND (ScheduleDate = LAST_N_MONTHS:13)];

        // Calculate account forecast data based on the fetched schedules
        for (OpportunityLineItemSchedule oliSchedule : oliScheduleRenewalList) {
            if (accountForecastMap.get(oliSchedule.OpportunityLineItem.Opportunity.AccountId+'-'+oliSchedule.OpportunityLineItem.Opportunity.Agency_Name__c) == null) {
                Account_Forecast__c AFRecord = new Account_Forecast__c();
                accountForecastMap.put(oliSchedule.OpportunityLineItem.Opportunity.AccountId+'-'+oliSchedule.OpportunityLineItem.Opportunity.Agency_Name__c,AFRecord);
            }
            accountForecastMap.get(oliSchedule.OpportunityLineItem.Opportunity.AccountId+'-'+oliSchedule.OpportunityLineItem.Opportunity.Agency_Name__c).Type__c = 'Renewal';
        }

        List<Opportunity> OpportunityList = [
            SELECT 
                AccountId, 
                Agency_Name__c, 
                Amount,
                CloseDate,
                CurrencyISOCode
            FROM Opportunity 
            WHERE 
                AccountId IN :AdvertiserIds 
                AND (RecordTypeId = :ActivationRecordTypeId 
                    OR RecordTypeId = :AdvertisingRecordTypeId 
                    OR RecordTypeId = :VerityDemandRecordTypeId) 
                AND IsClosed = true 
                AND StageName != 'Closed/Lost' 
                AND StageName != 'Discard' 
                AND StageName = 'Closed/Won' 
                AND CreatedDate >= 2023-01-01T00:00:00.000+00:00
        ];

        // Iterate through results to process the grouped data
        Map<String, Decimal> accountAgencyTotalMap = new Map<String, Decimal>();
        for (Opportunity opp : OpportunityList) {
            
            if(opp.Amount == null)
            opp.Amount = 0;

            String targetKey = opp.AccountId + '-' + opp.Agency_Name__c;
            


            if(opp.Amount > 0 && AARMap.get(targetKey) != null){
                opp.Amount = opp.Amount * (CurrencyConversionUtility.getExchangeRate(AARMap.get(targetKey).CurrencyISOCode,opp.CloseDate)/ CurrencyConversionUtility.getExchangeRate(opp.CurrencyISOCode,opp.CloseDate));
            }
            
            // Initialize inner map if not present
            if (!accountAgencyTotalMap.containsKey(targetKey)) {
                accountAgencyTotalMap.put(targetKey, opp.Amount);
            }else{
                accountAgencyTotalMap.put(targetKey, ((accountAgencyTotalMap.get(targetKey) + opp.Amount)/2).setScale(2));
            }
        }

        // Query to get total opportunities grouped by AccountId and Agency_Name__c
        AggregateResult[] totalOpportunitiesResults = [
            SELECT 
                AccountId, 
                Agency_Name__c, 
                COUNT(Id) totalOpportunities
            FROM Opportunity
            WHERE IsClosed = true AND StageName != 'Discard'
            AND CreatedDate >= 2023-01-01T00:00:00.000+00:00
            GROUP BY AccountId, Agency_Name__c
        ];

        // Query to get Closed/Won opportunities grouped by AccountId and Agency_Name__c
        AggregateResult[] closedWonResults = [
            SELECT 
                AccountId, 
                Agency_Name__c, 
                COUNT(Id) closedWonCount
            FROM Opportunity
            WHERE IsClosed = true AND StageName = 'Closed/Won'
            AND CreatedDate >= 2023-01-01T00:00:00.000+00:00
            GROUP BY AccountId, Agency_Name__c
        ];

        // Combine results in a map structure
        Map<String, Integer> totalOpportunitiesMap = new Map<String, Integer>();
        Map<String, Integer> closedWonMap = new Map<String, Integer>();

        // Process total opportunities results
        for (AggregateResult result : totalOpportunitiesResults) {
            Id accountId = (Id) result.get('AccountId');
            String agencyName = (Id) result.get('Agency_Name__c');
            Integer totalOpportunities = (Integer) result.get('totalOpportunities');

            if (!totalOpportunitiesMap.containsKey(accountId+'-'+agencyName)) {
                totalOpportunitiesMap.put(accountId+'-'+agencyName,totalOpportunities);
            }
        }

        // Process Closed/Won results
        for (AggregateResult result : closedWonResults) {
            Id accountId = (Id) result.get('AccountId');
            String agencyName = (Id) result.get('Agency_Name__c');
            Integer closedWonCount = (Integer) result.get('closedWonCount');

            if (!closedWonMap.containsKey(accountId+'-'+agencyName)) {
                closedWonMap.put(accountId+'-'+agencyName,closedWonCount);
            }
        }

        for (Advertiser_Agency_Relationship__c AAR : scope) {
            Account_Forecast__c AFRecord = new Account_Forecast__c(Advertiser_Agency_Relationship__c = AAR.Id,Bookings_Current_Year__c = 0,Booking_Next_Year__c = 0,Pipeline_Current_Quarter__c=0,Pipeline_Next_Quarter__c=0 );
            AFRecord.CurrencyIsoCode = UserInfo.getDefaultCurrency();
            if (AAR.Account_Forecasts__r != null && !AAR.Account_Forecasts__r.isEmpty()) {
                AFRecord.Id = AAR.Account_Forecasts__r[0].Id;
            }

            if(accountForecastMap.get(AAR.Advertiser__c+'-'+AAR.Agency__c)!=null){
                AFRecord.Bookings_Current_Year__c = accountForecastMap.get(AAR.Advertiser__c+'-'+AAR.Agency__c).Bookings_Current_Year__c;
                AFRecord.Booking_Next_Year__c = accountForecastMap.get(AAR.Advertiser__c+'-'+AAR.Agency__c).Booking_Next_Year__c;
                AFRecord.Pipeline_Current_Quarter__c = accountForecastMap.get(AAR.Advertiser__c+'-'+AAR.Agency__c).Pipeline_Current_Quarter__c;
                AFRecord.Pipeline_Next_Quarter__c = accountForecastMap.get(AAR.Advertiser__c+'-'+AAR.Agency__c).Pipeline_Next_Quarter__c;    
            }

            AFListToUpsert.add(AFRecord);

            if (accountAgencyTotalMap.containsKey(AAR.Advertiser__c+'-'+AAR.Agency__c)) {
                AAR.Average_Deal_Size__c = accountAgencyTotalMap.get(AAR.Advertiser__c+'-'+AAR.Agency__c);
                
                AAR.Average_Deal_Size__c =  (AAR.Average_Deal_Size__c != null ? AAR.Average_Deal_Size__c : 0) ;
            }

            if (totalOpportunitiesMap.containsKey(AAR.Advertiser__c+'-'+AAR.Agency__c)) {

                AAR.Total_Historical_Opportunity__c = totalOpportunitiesMap.get(AAR.Advertiser__c+'-'+AAR.Agency__c);
                AAR.Win_Rate__c = 0;
                if(closedWonMap.containsKey(AAR.Advertiser__c+'-'+AAR.Agency__c)){
                    // Calculate win rate
                    Decimal winRate = totalOpportunitiesMap.get(AAR.Advertiser__c+'-'+AAR.Agency__c) > 0
                            ? (Decimal.valueOf(closedWonMap.get(AAR.Advertiser__c+'-'+AAR.Agency__c)) / totalOpportunitiesMap.get(AAR.Advertiser__c+'-'+AAR.Agency__c)) * 100
                            : 0;
                    winRate = winRate.setScale(2, RoundingMode.HALF_UP);
                    AAR.Win_Rate__c = winRate;
                }
                

            }
        }


        // Upsert the Account Forecast records and log any errors
        List<Database.UpsertResult> updateScopeResult = Database.upsert(scope, false);
        for (Integer i = 0; i < updateScopeResult.size(); i++) {
            Database.UpsertResult updateResult = updateScopeResult[i]; // Use a properly scoped variable
            if (!updateResult.isSuccess()) {
                for (Database.Error dberr : updateResult.getErrors()) {
                    System.debug('Error with Advertiser Agency Relationship: ' + scope[i].Id);
                    System.debug('Error message: ' + dberr.getMessage());
                }
            }
        }


        // Upsert the Account Forecast records and log any errors
        List<Database.UpsertResult> upsertaccountForecastResult = Database.upsert(AFListToUpsert, false);
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

    // Empty finish method for batch completion
    public void finish(Database.BatchableContext bc) {
    }

    public void execute(SchedulableContext SC) {
        // Execute the batch job
        AccountForecastBatch batch = new AccountForecastBatch();
        Database.executeBatch(batch, 200); // 200 is the batch size
    }
}