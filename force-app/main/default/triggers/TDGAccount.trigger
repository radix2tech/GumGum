trigger TDGAccount on Account (after insert, after update) {
    TDGAccountTriggerHandler handler = new TDGAccountTriggerHandler();

    switch on Trigger.operationType {
        when AFTER_INSERT {
            handler.afterInsert(Trigger.new);
        } when AFTER_UPDATE {
            handler.afterUpdate(Trigger.new, Trigger.oldMap);
        } 
    }
}