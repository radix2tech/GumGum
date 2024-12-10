public class ForecastEntryTriggerHandler {
   public static void processForecastEntries(List<forecast_entry__c> forecastEntries) {
    if (ForecastEntryTriggerHelper.isTriggerExecuting) {
        return;
    }
    ForecastEntryTriggerHelper.isTriggerExecuting = true;

    try {
        Set<Id> entryIds = new Set<Id>();
        for (forecast_entry__c entry : forecastEntries) {
            entryIds.add(entry.Id);
        }

        List<forecast_entry__c> recordsToUpdate = [
            SELECT Id, Product__c, AAR_Split_Owner__r.OwnerId,
                   Forecast_Q1__c, Forecast_Q2__c, Forecast_Q3__c, Forecast_Q4__c,
                   Pipeline_Q1__c, Pipeline_Q2__c, Pipeline_Q3__c, Pipeline_Q4__c,
                   Q1_PY_Bookings__c, Q2_PY_Bookings__c, Q3_PY_Bookings__c, Q4_PY_Bookings__c,
                   Q1_NY_Pipeline__c, Q2_NY_Pipeline__c, Q3_NY_Pipeline__c, Q4_NY_Pipeline__c
            FROM forecast_entry__c
            WHERE Id IN :entryIds
        ];

        Integer currentYear = Date.today().year();

        for (forecast_entry__c entry : recordsToUpdate) {
            entry.Forecast_Q1__c = 0;
            entry.Forecast_Q2__c = 0;
            entry.Forecast_Q3__c = 0;
            entry.Forecast_Q4__c = 0;

            entry.Pipeline_Q1__c = 0;
            entry.Pipeline_Q2__c = 0;
            entry.Pipeline_Q3__c = 0;
            entry.Pipeline_Q4__c = 0;

            entry.Q1_PY_Bookings__c = 0;
            entry.Q2_PY_Bookings__c = 0;
            entry.Q3_PY_Bookings__c = 0;
            entry.Q4_PY_Bookings__c = 0;

            entry.Q1_NY_Pipeline__c = 0;
            entry.Q2_NY_Pipeline__c = 0;
            entry.Q3_NY_Pipeline__c = 0;
            entry.Q4_NY_Pipeline__c = 0;

            if (entry.Product__c == 'Core Media') {
                List<OpportunityLineItemSchedule> schedules = [
                    SELECT Id, ScheduleDate, Revenue, OpportunityLineItem.OpportunityId,
                           OpportunityLineItem.Opportunity.StageName,OpportunityLineItem.Opportunity.isClosed, OpportunityLineItem.Opportunity.OwnerId
                    FROM OpportunityLineItemSchedule
                    WHERE OpportunityLineItem.Opportunity.OwnerId = :entry.AAR_Split_Owner__r.OwnerId
                ];

                for (OpportunityLineItemSchedule schedule : schedules) {
                    Integer scheduleYear = schedule.ScheduleDate.year();
                    Integer quarter = checkScheduleDateQuarters(schedule.ScheduleDate);

                    if (quarter > 0) {
                        if (scheduleYear == currentYear) {
                            // Current Year logic
                            if (schedule.OpportunityLineItem.Opportunity.StageName == 'Closed/Won') {
                                updateForecastField(entry, quarter, schedule.Revenue, 'Forecast');
                            } else if (schedule.OpportunityLineItem.Opportunity.isClosed == false) {
                                updateForecastField(entry, quarter, schedule.Revenue, 'Pipeline');
                            }
                        } else if (scheduleYear == currentYear - 1 && schedule.OpportunityLineItem.Opportunity.StageName == 'Closed/Won') {
                            // Previous Year logic
                            updateForecastField(entry, quarter, schedule.Revenue, 'PY');
                        } else if (scheduleYear == currentYear + 1 && schedule.OpportunityLineItem.Opportunity.isClosed == false) {
                            // Next Year logic
                            updateForecastField(entry, quarter, schedule.Revenue, 'NY');
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

private static void updateForecastField(forecast_entry__c entry, Integer quarter, Decimal revenue, String type) {
    if (type == 'Forecast') {
        if (quarter == 1) entry.Forecast_Q1__c += revenue;
        else if (quarter == 2) entry.Forecast_Q2__c += revenue;
        else if (quarter == 3) entry.Forecast_Q3__c += revenue;
        else if (quarter == 4) entry.Forecast_Q4__c += revenue;
    } else if (type == 'Pipeline') {
        if (quarter == 1) entry.Pipeline_Q1__c += revenue;
        else if (quarter == 2) entry.Pipeline_Q2__c += revenue;
        else if (quarter == 3) entry.Pipeline_Q3__c += revenue;
        else if (quarter == 4) entry.Pipeline_Q4__c += revenue;
    } else if (type == 'PY') {
        if (quarter == 1) entry.Q1_PY_Bookings__c += revenue;
        else if (quarter == 2) entry.Q2_PY_Bookings__c += revenue;
        else if (quarter == 3) entry.Q3_PY_Bookings__c += revenue;
        else if (quarter == 4) entry.Q4_PY_Bookings__c += revenue;
    } else if (type == 'NY') {
        if (quarter == 1) entry.Q1_NY_Pipeline__c += revenue;
        else if (quarter == 2) entry.Q2_NY_Pipeline__c += revenue;
        else if (quarter == 3) entry.Q3_NY_Pipeline__c += revenue;
        else if (quarter == 4) entry.Q4_NY_Pipeline__c += revenue;
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