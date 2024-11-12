/*
	Description	   : OpportunityContactRoleTrigger that will call the RUN mthos of TriggerDispatcher class
	Created Date   : 09-12-2022
	Created By     : Kiran
	Change Request : 
*/
trigger OpportunityContactRoleTrigger on OpportunityContactRole (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    
    TriggerDispatcher.run(new OpportunityContactRoleTriggerHandler() , 'OpportunityContactRole');
}