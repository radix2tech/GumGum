/*
    @Author : Kiran Punruu
    @BuiltDate : 09-Aug-2022
    @Description : Campaign Member Trigger that will call the RUN mthos of TriggerDispatcher class
*/

trigger CampaignMemberTrigger on CampaignMember(before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    TriggerDispatcher.run(new CampaignMemberTriggerHandler() , 'CampaignMember'); 
}