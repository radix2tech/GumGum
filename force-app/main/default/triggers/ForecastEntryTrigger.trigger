trigger ForecastEntryTrigger on forecast_entry__c (after insert, after update) {
    if (Trigger.isAfter) {
        //ForecastEntryTriggerHandler.processForecastEntries(Trigger.new);
    }
}