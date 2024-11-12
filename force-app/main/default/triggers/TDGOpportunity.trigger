trigger TDGOpportunity on Opportunity (after insert, after update) {
    TDGOpportunityTriggerHandler handler = new TDGOpportunityTriggerHandler();

    switch on Trigger.operationType {
        when AFTER_INSERT {
            handler.afterInsert(Trigger.new);
        } when AFTER_UPDATE {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}