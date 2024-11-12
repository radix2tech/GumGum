/*
Description   : Prevent Past Schedule Recalculation
Created Date :  08/28/2024
Created By   : Dan 
Test Class   : 
*/

trigger PreventPastScheduleRecalculation on OpportunityLineItemSchedule (before insert, before update) {
    Date currentDate = Date.today();

    for (OpportunityLineItemSchedule schedule : Trigger.new) {
        if (schedule.ScheduleDate < currentDate && schedule.Lock_Past_Schedules__c) {
            schedule.addError('This schedule is locked and cannot be updated because it is in the past and has been flagged as locked.');
        }
    }
}