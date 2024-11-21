trigger ForecastEntryTrigger on forecast_entry__c (after insert, after update) {
    // Call the handler to process forecast entries, filtering by product condition
    ForecastEntryTriggerHandler.processForecastEntries(Trigger.new);
}