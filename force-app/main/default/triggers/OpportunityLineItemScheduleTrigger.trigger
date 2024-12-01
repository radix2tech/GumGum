/*
Description	 : OpportunityLineItemScheduleTrigger
Created Date :  01-05-2024
Created By   : Kiran 
Test Class   : LineItemScheduleTriggerHandlerTest
*/

trigger OpportunityLineItemScheduleTrigger on OpportunityLineItemSchedule (before update,after update,after insert) {
    
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            LineItemScheduleTriggerHandler.updateActualVerityAmountOnOliAfterInsert(Trigger.New);
        }
        if(Trigger.isUpdate){
            LineItemScheduleTriggerHandler.updateVerityRevenueOnOpportunityProductAfterUpdate(Trigger.New,Trigger.OldMap);
            LineItemScheduleTriggerHandler.updateActualVerityAmountOnOliAfterUpdate(Trigger.New,Trigger.OldMap);
        }
    }

}