/*
Description	 : OpportunityLineItemTrigger
Created Date : 10-04-2024
Created By   : Kiran  
*/

trigger OpportunityLineItemTrigger on OpportunityLineItem (before insert,before update,after insert,after update,before delete,after delete,after undelete){
    TriggerDispatcher.run(new OpportunityLineItemTriggerHandler() , 'OpportunityLineItem'); 
}