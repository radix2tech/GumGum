public class ForecastEntryTriggerHandler {
    public static void processForecastEntries(List<forecast_entry__c> forecastEntries) {
        // Prevent recursion by checking a static Boolean flag
        if (ForecastEntryTriggerHelper.isTriggerExecuting) {
            return;
        }
        ForecastEntryTriggerHelper.isTriggerExecuting = true; // Mark the trigger as executing

        try {
            Set<Id> entryIds = new Set<Id>();
            for (forecast_entry__c entry : forecastEntries) {
                entryIds.add(entry.Id);
            }

            // Query forecast_entry__c records to avoid modifying Trigger.new directly
            List<forecast_entry__c> recordsToUpdate = [
                SELECT Id, Product__c, AAR_Split_Owner__r.OwnerId,
                       Forecast_Q1__c, Forecast_Q2__c, Forecast_Q3__c, Forecast_Q4__c,
                       Pipeline_Q1__c, Pipeline_Q2__c, Pipeline_Q3__c, Pipeline_Q4__c
                FROM forecast_entry__c
                WHERE Id IN :entryIds
            ];

            for (forecast_entry__c entry : recordsToUpdate) {
               		entry.Forecast_Q1__c = 0;
                    entry.Forecast_Q2__c = 0;
                    entry.Forecast_Q3__c = 0;
                    entry.Forecast_Q4__c = 0;

                    entry.Pipeline_Q1__c = 0;
                    entry.Pipeline_Q2__c = 0;
                    entry.Pipeline_Q3__c = 0;
                    entry.Pipeline_Q4__c = 0;

                if (entry.Product__c == 'Core Media') {
                    // Query related OpportunityLineItemSchedules
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
                                // Update forecast fields
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
                                // Update pipeline fields
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

            if (!recordsToUpdate.isEmpty()) {
                update recordsToUpdate;
            }
        } finally {
            ForecastEntryTriggerHelper.isTriggerExecuting = false;
        }
    }

    public static Integer checkScheduleDateQuarters(Date scheduleDate) {
        Integer month = scheduleDate.month();
        if (month <= 3) return 1;   
        if (month <= 6) return 2;   
        if (month <= 9) return 3;   
        return 4;                   
    }
}