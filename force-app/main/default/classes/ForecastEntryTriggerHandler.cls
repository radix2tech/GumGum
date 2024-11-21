public class ForecastEntryTriggerHandler {

    // Main method to process forecast entries
    public static void processForecastEntries(List<forecast_entry__c> forecastEntries) {
        
        // Loop through the forecast entries and check if the product is "Core Media"
        for (forecast_entry__c entry : forecastEntries) {
            
            if (entry.Product__c == 'Core Media') {
                List<OpportunityLineItemSchedule> schedules = [
                    SELECT Id, ScheduleDate, Revenue, OpportunityLineItem.OpportunityId, 
                           OpportunityLineItem.Opportunity.StageName, OpportunityLineItem.Opportunity.OwnerId,
                           OpportunityLineItem.Opportunity.AccountId, OpportunityLineItem.Opportunity.Agency_Name__c, 
                           OpportunityLineItem.Product_Name__c
                    FROM OpportunityLineItemSchedule
                    WHERE OpportunityLineItem.Opportunity.StageName = 'Closed/Won'
                    AND OpportunityLineItem.Opportunity.OwnerId = :entry.AAR_Split_Owner__r.OwnerId
                ];

                for (OpportunityLineItemSchedule schedule : schedules) {
                    Integer quarter = checkScheduleDateQuarters(schedule.ScheduleDate);

                    if (quarter > 0) {
                       
                        if (quarter == 1) {
                            entry.Forecast_Q1__c = (entry.Forecast_Q1__c == null ? 0 : entry.Forecast_Q1__c) + schedule.Revenue;
                        } else if (quarter == 2) {
                            entry.Forecast_Q2__c = (entry.Forecast_Q2__c == null ? 0 : entry.Forecast_Q2__c) + schedule.Revenue;
                        } else if (quarter == 3) {
                            entry.Forecast_Q3__c = (entry.Forecast_Q3__c == null ? 0 : entry.Forecast_Q3__c) + schedule.Revenue;
                        } else if (quarter == 4) {
                            entry.Forecast_Q4__c = (entry.Forecast_Q4__c == null ? 0 : entry.Forecast_Q4__c) + schedule.Revenue;
                        }
                    }
                }

                update entry;
            }
        }
    }

    public static Integer checkScheduleDateQuarters(Date scheduleDate) {
        Date today = Date.today();
        Integer currentMonth = today.month();
        Integer currentQuarter = (currentMonth - 1) / 3 + 1;

        Date currentQuarterStart = getQuarterStart(today.year(), currentQuarter);
        Date currentQuarterEnd = currentQuarterStart.addMonths(3).addDays(-1);
        Integer nextQuarter = currentQuarter == 4 ? 1 : currentQuarter + 1;
        Date nextQuarterStart = getQuarterStart(today.year(), nextQuarter);
        Date nextQuarterEnd = nextQuarterStart.addMonths(3).addDays(-1);
        Integer thirdQuarter = currentQuarter == 3 ? 4 : (currentQuarter == 4 ? 1 : 3);
        Date thirdQuarterStart = getQuarterStart(today.year(), thirdQuarter);
        Date thirdQuarterEnd = thirdQuarterStart.addMonths(3).addDays(-1);
        Integer fourthQuarter = currentQuarter == 4 ? 1 : (currentQuarter == 3 ? 4 : 2);
        Date fourthQuarterStart = getQuarterStart(today.year(), fourthQuarter);
        Date fourthQuarterEnd = fourthQuarterStart.addMonths(3).addDays(-1);

        // Check for current quarter
        if (scheduleDate >= currentQuarterStart && scheduleDate <= currentQuarterEnd) {
            return 1; 
        } 
        // Check for next quarter
        else if (scheduleDate >= nextQuarterStart && scheduleDate <= nextQuarterEnd) {
            return 2; 
        } 
        // Check for third quarter
        else if (scheduleDate >= thirdQuarterStart && scheduleDate <= thirdQuarterEnd) {
            return 3;
        } 
        // Check for fourth quarter
        else if (scheduleDate >= fourthQuarterStart && scheduleDate <= fourthQuarterEnd) {
            return 4;
        }

        return 0;  
    }

    private static Date getQuarterStart(Integer year, Integer quarter) {
        if (quarter == 1) return Date.newInstance(year, 1, 1);  
        if (quarter == 2) return Date.newInstance(year, 4, 1);   
        if (quarter == 3) return Date.newInstance(year, 7, 1);  
        return Date.newInstance(year, 10, 1);  
    }
}