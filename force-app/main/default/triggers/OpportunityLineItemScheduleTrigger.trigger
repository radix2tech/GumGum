/*
Description	   : OpportunityLineItemScheduleTrigger
Created Date   :  01-05-2024
Created By     : Kiran 
Test Class     : LineItemScheduleTriggerHandlerTest
Change Request : CR#1 Date: 15/11/2024
				 Description: Changes made to handle the update of the field Maximum_Actual_Verity_Schedule_Date__c at Opportunity Product
							  When Verity Actual Revenue is update on the Schedule or When a Schedule is created with Verity Actual Revenue.
*/

trigger OpportunityLineItemScheduleTrigger on OpportunityLineItemSchedule (before update,after update,after insert,after delete) {
    
    if(Trigger.isAfter){
        if(Trigger.isInsert){
            LineItemScheduleTriggerHandler.updateActualVerityAmountOnOliAfterInsert(Trigger.New);
            // updates Maximum_Actual_Verity_Schedule_Date__c
            LineItemScheduleTriggerHandler.updateMaximumActualVeritySchedulDateOnInsertOrDelete(Trigger.New);
        }
        if(Trigger.isUpdate){
            LineItemScheduleTriggerHandler.updateVerityRevenueOnOpportunityProductAfterUpdate(Trigger.New,Trigger.OldMap);
            LineItemScheduleTriggerHandler.updateActualVerityAmountOnOliAfterUpdate(Trigger.New,Trigger.OldMap);
            // updates Maximum_Actual_Verity_Schedule_Date__c
            LineItemScheduleTriggerHandler.updateMaximumActualVeritySchedulDateOnUpdate(Trigger.New,Trigger.OldMap);
        }
        if(Trigger.isDelete){
            // updates Maximum_Actual_Verity_Schedule_Date__c
            //LineItemScheduleTriggerHandler.updateMaximumActualVeritySchedulDateOnInsertOrDelete(Trigger.Old);
        }
    }

}