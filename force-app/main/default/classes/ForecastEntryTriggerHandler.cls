public class ForecastEntryTriggerHandler {

    public static void processForecastEntries(List<forecast_entry__c> forecastEntries) {
        
        for (forecast_entry__c entry : forecastEntries) {
            
            if (entry.Product__c == 'Core Media') {
                List<OpportunityLineItemSchedule> schedules = [
                    SELECT Id, ScheduleDate, Revenue, OpportunityLineItem.OpportunityId, 
                           OpportunityLineItem.Opportunity.StageName, OpportunityLineItem.Opportunity.OwnerId,
                           OpportunityLineItem.Opportunity.AccountId, OpportunityLineItem.Opportunity.Agency_Name__c, 
                           OpportunityLineItem.Product_Name__c
                    FROM OpportunityLineItemSchedule
                    WHERE OpportunityLineItem.Opportunity.StageName != 'Closed/Lost'
                    AND OpportunityLineItem.Opportunity.OwnerId = :entry.AAR_Split_Owner__r.OwnerId
                ];

                for (OpportunityLineItemSchedule schedule : schedules) {
                    Integer quarter = checkScheduleDateQuarters(schedule.ScheduleDate);

                    if (quarter > 0) {
                        if (schedule.OpportunityLineItem.Opportunity.StageName == 'Closed/Won') {
                            if (quarter == 1) {
                                entry.Forecast_Q1__c = (entry.Forecast_Q1__c == null ? 0 : entry.Forecast_Q1__c) + schedule.Revenue;
                            } else if (quarter == 2) {
                                entry.Forecast_Q2__c = (entry.Forecast_Q2__c == null ? 0 : entry.Forecast_Q2__c) + schedule.Revenue;
                            } else if (quarter == 3) {
                                entry.Forecast_Q3__c = (entry.Forecast_Q3__c == null ? 0 : entry.Forecast_Q3__c) + schedule.Revenue;
                            } else if (quarter == 4) {
                                entry.Forecast_Q4__c = (entry.Forecast_Q4__c == null ? 0 : entry.Forecast_Q4__c) + schedule.Revenue;
                            }
                        } else {
                            if (quarter == 1) {
                                entry.Pipeline_Q1__c = (entry.Pipeline_Q1__c == null ? 0 : entry.Pipeline_Q1__c) + schedule.Revenue;
                            } else if (quarter == 2) {
                                entry.Pipeline_Q2__c = (entry.Pipeline_Q2__c == null ? 0 : entry.Pipeline_Q2__c) + schedule.Revenue;
                            } else if (quarter == 3) {
                                entry.Pipeline_Q3__c = (entry.Pipeline_Q3__c == null ? 0 : entry.Pipeline_Q3__c) + schedule.Revenue;
                            } else if (quarter == 4) {
                                entry.Pipeline_Q4__c = (entry.Pipeline_Q4__c == null ? 0 : entry.Pipeline_Q4__c) + schedule.Revenue;
                            }
                        }
                    }
                }
            }
        }
    }

    public static Integer checkScheduleDateQuarters(Date scheduleDate) {
        Integer month = scheduleDate.month();
        if (month <= 3) return 1;   // Q1
        if (month <= 6) return 2;   // Q2
        if (month <= 9) return 3;   // Q3
        return 4;                   // Q4
    }
}