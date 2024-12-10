public class ForecastEntryCalcBatch implements Database.Batchable<SObject>, Schedulable {

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id,Product__c, AAR_Split_Owner__r.OwnerId, Name, Forecast_Q1__c, Forecast_Q2__c, Forecast_Q3__c, Forecast_Q4__c, Pipeline_Q1__c, Pipeline_Q2__c, Pipeline_Q3__c, Pipeline_Q4__c, Q1_PY_Bookings__c, Q2_PY_Bookings__c, Q3_PY_Bookings__c, Q4_PY_Bookings__c, Q1_NY_Pipeline__c, Q2_NY_Pipeline__c, Q3_NY_Pipeline__c, Q4_NY_Pipeline__c FROM Forecast_Entry__c');
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        List<Forecast_Entry__c> forecastEntries = (List<Forecast_Entry__c>) scope;
        
        ForecastEntryTriggerHandler.processForecastEntries(forecastEntries);
    }

    public void finish(Database.BatchableContext bc) {
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new ForecastEntryCalcBatch(), 200);
    }
}