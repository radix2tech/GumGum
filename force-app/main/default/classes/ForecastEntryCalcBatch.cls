public class ForecastEntryCalcBatch implements Database.Batchable<SObject>, Schedulable {

    public static final Id ActivationRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Activation').getRecordTypeId();
    public static final Id AdvertisingRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Advertising').getRecordTypeId();
    public static final Id VerityDemandRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Verity - Demand').getRecordTypeId();

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id,Product__c,currencyISOCode,AAR_Split_Owner__r.Advertiser_Agency_Relationship__r.Agency__c,AAR_Split_Owner__r.Advertiser_Agency_Relationship__r.Advertiser__c, AAR_Split_Owner__r.Owner__c, Name, Forecast_Q1__c, Forecast_Q2__c, Forecast_Q3__c, Forecast_Q4__c, Pipeline_Q1__c, Pipeline_Q2__c, Pipeline_Q3__c, Pipeline_Q4__c, Q1_PY_Bookings__c, Q2_PY_Bookings__c, Q3_PY_Bookings__c, Q4_PY_Bookings__c, Q1_NY_Pipeline__c, Q2_NY_Pipeline__c, Q3_NY_Pipeline__c, Q4_NY_Pipeline__c FROM Forecast_Entry__c WHERE  IsActive__c = true');
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Forecast_Entry__c> forecastEntries = (List<Forecast_Entry__c>) scope;
        processForecastEntries(forecastEntries);

    }

    public void finish(Database.BatchableContext bc) {
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new ForecastEntryCalcBatch(), 200);
    }

    public static void processForecastEntries(List<forecast_entry__c> forecastEntries) {

        Set<Id> entryIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> allAccountIds = new Set<Id>();
        Set<Id> AdvertiserIds = new Set<Id>();

        for(Forecast_Entry__c FE : forecastEntries){
            allAccountIds.add(FE.AAR_Split_Owner__r.Advertiser_Agency_Relationship__r.Agency__c);
            allAccountIds.add(FE.AAR_Split_Owner__r.Advertiser_Agency_Relationship__r.Advertiser__c);
            
            if(FE.Product__c == 'Core Media'){
                accountIds.add(FE.AAR_Split_Owner__r.Advertiser_Agency_Relationship__r.Agency__c);
                accountIds.add(FE.AAR_Split_Owner__r.Advertiser_Agency_Relationship__r.Advertiser__c);
                AdvertiserIds.add(FE.AAR_Split_Owner__r.Advertiser_Agency_Relationship__r.Advertiser__c);
            }
        }


        List<OpportunitySplit> OpportunitySplitList = [select id,SplitPercentage,OpportunityId,SplitOwnerId from OpportunitySplit 
                                                        where Opportunity.AccountId IN :AdvertiserIds
                                                        AND (Opportunity.RecordTypeId = :ActivationRecordTypeId
                                                            OR Opportunity.RecordTypeId = :AdvertisingRecordTypeId
                                                            OR Opportunity.RecordTypeId = :VerityDemandRecordTypeId)
                                                        AND Opportunity.StageName != 'Closed/Lost'
                                                        AND Opportunity.StageName != 'Discard'
                                                        ];
        Map<Id,Map<Id,Decimal>> OpptySplitPercentage = new Map<Id,Map<Id,Decimal>>();

        for(OpportunitySplit OS : OpportunitySplitList){
            if(OpptySplitPercentage.containsKey(OS.OpportunityId)){
                OpptySplitPercentage.get(OS.OpportunityId).put(OS.splitOwnerId,OS.SplitPercentage);
            }else{
                Map<Id,Decimal> splitOwnerToPercentage = new Map<Id,Decimal>();
                splitOwnerToPercentage.put(OS.splitOwnerId,OS.SplitPercentage);
                OpptySplitPercentage.put(OS.OpportunityId,splitOwnerToPercentage);
            }
        }

        Map<Id, Date> accountActivityDateMap  = getRecentActivityDate(allAccountIds);

        List<OpportunityLineItemSchedule> schedules = [
            SELECT Id, ScheduleDate,CurrencyIsoCode,  Revenue, OpportunityLineItem.OpportunityId,OpportunityLineItem.Opportunity.Agency_Name__c,OpportunityLineItem.Opportunity.AccountId,OpportunityLineItem.Opportunity.CurrencyISOCode,OpportunityLineItem.Opportunity.CloseDate,
                OpportunityLineItem.Opportunity.StageName,OpportunityLineItem.Opportunity.isClosed, OpportunityLineItem.Opportunity.OwnerId
            FROM OpportunityLineItemSchedule
            WHERE (OpportunityLineItem.Opportunity.AccountId IN :AdvertiserIds) 
            AND (OpportunityLineItem.Opportunity.RecordTypeId = :ActivationRecordTypeId
                OR OpportunityLineItem.Opportunity.RecordTypeId = :AdvertisingRecordTypeId
                OR OpportunityLineItem.Opportunity.RecordTypeId = :VerityDemandRecordTypeId)
            AND OpportunityLineItem.Opportunity.StageName != 'Closed/Lost'
            AND OpportunityLineItem.Opportunity.StageName != 'Discard'
            AND (ScheduleDate = THIS_YEAR OR ScheduleDate = NEXT_YEAR OR ScheduleDate = LAST_YEAR)
        ];

        Map<String,List<OpportunityLineItemSchedule>> advertiserAgencyIdToOLISchedulesMap = new Map<String,List<OpportunityLineItemSchedule>>();

        for(OpportunityLineItemSchedule sch : schedules){
            if(advertiserAgencyIdToOLISchedulesMap.get(sch.OpportunityLineItem.Opportunity.AccountId+'-'+sch.OpportunityLineItem.Opportunity.Agency_Name__c)==null){
                List<OpportunityLineItemSchedule> oliScheduleList = new List<OpportunityLineItemSchedule>();
                oliScheduleList.add(sch);
                advertiserAgencyIdToOLISchedulesMap.put(sch.OpportunityLineItem.Opportunity.AccountId+'-'+sch.OpportunityLineItem.Opportunity.Agency_Name__c,oliScheduleList);
            }else{
                advertiserAgencyIdToOLISchedulesMap.get(sch.OpportunityLineItem.Opportunity.AccountId+'-'+sch.OpportunityLineItem.Opportunity.Agency_Name__c).add(sch);
            }
        }

        Integer currentYear = Date.today().year();
        Date today = System.today();

        for (forecast_entry__c entry : forecastEntries) {
            
            entry.Activity_Last_30_Days__c = false;
            entry.Activity_Last_60_Days__c = false;

            if(accountActivityDateMap.get(entry.AAR_Split_Owner__r.Advertiser_Agency_Relationship__r.Agency__c) != null){
                
                Date lastActivityDate = accountActivityDateMap.get(entry.AAR_Split_Owner__r.Advertiser_Agency_Relationship__r.Agency__c);

                // Check the date range and set the checkboxes accordingly
                if (lastActivityDate <= today && lastActivityDate >= today.addDays(-30)) {
                    entry.Activity_Last_30_Days__c = true;
                }

                if (lastActivityDate <=  today && lastActivityDate >= today.addDays(-60)) {
                    entry.Activity_Last_60_Days__c = true;
                }
            }

            if(accountActivityDateMap.get(entry.AAR_Split_Owner__r.Advertiser_Agency_Relationship__r.Advertiser__c) != null){
                
                Date lastActivityDate = accountActivityDateMap.get(entry.AAR_Split_Owner__r.Advertiser_Agency_Relationship__r.Advertiser__c);

                // Check the date range and set the checkboxes accordingly
                if (lastActivityDate <= today && lastActivityDate >= today.addDays(-30)) {
                    entry.Activity_Last_30_Days__c = true;
                }

                if (lastActivityDate <=  today && lastActivityDate >= today.addDays(-60)) {
                    entry.Activity_Last_60_Days__c = true;
                }
            }
            
            if(entry.Product__c == 'Core Media'){
                //CY Bookings
                entry.Forecast_Q1__c = 0;
                entry.Forecast_Q2__c = 0;
                entry.Forecast_Q3__c = 0;
                entry.Forecast_Q4__c = 0;

                //CY Pipeline
                entry.Pipeline_Q1__c = 0;
                entry.Pipeline_Q2__c = 0;
                entry.Pipeline_Q3__c = 0;
                entry.Pipeline_Q4__c = 0;

                //PY Bookings
                entry.Q1_PY_Bookings__c = 0;
                entry.Q2_PY_Bookings__c = 0;
                entry.Q3_PY_Bookings__c = 0;
                entry.Q4_PY_Bookings__c = 0;

                //NY Pipeline
                entry.Q1_NY_Pipeline__c = 0;
                entry.Q2_NY_Pipeline__c = 0;
                entry.Q3_NY_Pipeline__c = 0;
                entry.Q4_NY_Pipeline__c = 0;
                
                if(advertiserAgencyIdToOLISchedulesMap.get(entry.AAR_Split_Owner__r.Advertiser_Agency_Relationship__r.Advertiser__c+'-'+entry.AAR_Split_Owner__r.Advertiser_Agency_Relationship__r.Agency__c) != null){
                    for (OpportunityLineItemSchedule schedule : advertiserAgencyIdToOLISchedulesMap.get(entry.AAR_Split_Owner__r.Advertiser_Agency_Relationship__r.Advertiser__c+'-'+entry.AAR_Split_Owner__r.Advertiser_Agency_Relationship__r.Agency__c)) {

                        if(OpptySplitPercentage.get(schedule.OpportunityLineItem.OpportunityId).get(schedule.OpportunityLineItem.Opportunity.OwnerId)==null){
                            continue;
                        }

                        Integer scheduleYear = schedule.ScheduleDate.year();
                        Integer quarter = checkScheduleDateQuarters(schedule.ScheduleDate);

                        Decimal revenue = schedule.Revenue;
                        if(revenue > 0){
                            revenue = revenue * (CurrencyConversionUtility.getExchangeRate(entry.CurrencyISOCode,schedule.ScheduleDate)/ CurrencyConversionUtility.getExchangeRate(schedule.CurrencyISOCode,schedule.ScheduleDate));
                        }

                        if(OpptySplitPercentage.get(schedule.OpportunityLineItem.OpportunityId)!=null){
                            revenue =  revenue * (OpptySplitPercentage.get(schedule.OpportunityLineItem.OpportunityId).get(schedule.OpportunityLineItem.Opportunity.OwnerId)/100);
                        }

                        if (quarter > 0) {
                            if (scheduleYear == currentYear) {
                                // Current Year logic
                                if (schedule.OpportunityLineItem.Opportunity.StageName == 'Closed/Won') {
                                    if (quarter == 1) entry.Forecast_Q1__c += revenue;
                                    else if (quarter == 2) entry.Forecast_Q2__c += revenue;
                                    else if (quarter == 3) entry.Forecast_Q3__c += revenue;
                                    else if (quarter == 4) entry.Forecast_Q4__c += revenue;
                                } else if (!schedule.OpportunityLineItem.Opportunity.isClosed) {
                                    if (quarter == 1) entry.Pipeline_Q1__c += revenue;
                                    else if (quarter == 2) entry.Pipeline_Q2__c += revenue;
                                    else if (quarter == 3) entry.Pipeline_Q3__c += revenue;
                                    else if (quarter == 4) entry.Pipeline_Q4__c += revenue;
                                }
                            } else if (scheduleYear == currentYear - 1 && schedule.OpportunityLineItem.Opportunity.StageName == 'Closed/Won') {
                                if (quarter == 1) entry.Q1_PY_Bookings__c += revenue;
                                else if (quarter == 2) entry.Q2_PY_Bookings__c += revenue;
                                else if (quarter == 3) entry.Q3_PY_Bookings__c += revenue;
                                else if (quarter == 4) entry.Q4_PY_Bookings__c += revenue;
                            } else if (scheduleYear == currentYear + 1 && !schedule.OpportunityLineItem.Opportunity.isClosed) {
                                if (quarter == 1) entry.Q1_NY_Pipeline__c += revenue;
                                else if (quarter == 2) entry.Q2_NY_Pipeline__c += revenue;
                                else if (quarter == 3) entry.Q3_NY_Pipeline__c += revenue;
                                else if (quarter == 4) entry.Q4_NY_Pipeline__c += revenue;
                            }
                        }
                
                    }
                }
            }
            
        }

        update forecastEntries;
    
    }

    public static Integer checkScheduleDateQuarters(Date scheduleDate) {
        Integer month = scheduleDate.month();
        if (month <= 3) return 1;   
        if (month <= 6) return 2;   
        if (month <= 9) return 3;   
        return 4;                   
    }


    public static Map<Id, Date> getRecentActivityDate(Set<Id> advertiserAgencyIds) {
        // Initialize a map to track the last activity dates
        Map<Id, Date> accountActivityMap = new Map<Id, Date>();

        List<Account> accList = [SELECT Id, 
                                (SELECT id,ActivityDate,ActivityType from ActivityHistories WHERE ActivityDate = LAST_N_DAYS:60 ORDER BY ActivityDate DESC LIMIT 1),
                                (SELECT Id,ActivityDate FROM OpenActivities WHERE ActivityDate = LAST_N_DAYS:60 ORDER BY ActivityDate DESC LIMIT 1)
                                FROM Account WHERE Id IN :advertiserAgencyIds];

        for(Account acc : accList){

            if(acc.activityhistories != null && !acc.activityhistories.isEmpty()){
                accountActivityMap.put(acc.Id,acc.activityhistories[0].ActivityDate);
            }

            if(acc.OpenActivities != null && !acc.OpenActivities.isEmpty()){
                if(accountActivityMap.get(acc.Id) == null || (accountActivityMap.get(acc.Id) != null && (accountActivityMap.get(acc.Id) < acc.OpenActivities[0].ActivityDate))){
                    accountActivityMap.put(acc.Id,acc.OpenActivities[0].ActivityDate);
                }
            }
        }

        return accountActivityMap;
    }
}