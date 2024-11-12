/*
    @Author : Kiran Punuru
    @BuiltDate : 09-Aug-2022 
*/
public interface TriggerInterface{
    
    /*
        @Description : Called by the trigger framework before insert of the records
        @params : List<sObject> newRecordsList 
    */
    void beforeInsert(List<sObject> newRecordsList);
    
    /*
        @Description : Called by the trigger framework after insert of the records
        @params : List<sObject> newRecordsList , Map<Id, sObject> newRecordsMap
    */
    void afterInsert(List<sObject> newRecordsList , Map<Id, sObject> newRecordsMap);
    
    /*
        @Description : Called by the trigger framework before update of the records
        @params : List<sObject> newRecordsList , Map<Id, sObject> newRecordsMap
                  List<sObject> oldRecordsList , Map<Id, sObject> oldRecordsMap
    */
    void beforeUpdate(Map<Id, sObject> newRecordsMap, Map<Id, sObject> oldRecordsMap);
    
    /*
        @Description : Called by the trigger framework after update of the records
        @params : List<sObject> newRecordsList , Map<Id, sObject> newRecordsMap
                  List<sObject> oldRecordsList , Map<Id, sObject> oldRecordsMap
    */
    void afterUpdate(Map<Id, sObject> newRecordsMap,  Map<Id, sObject> oldRecordsMap);
    
    /*
        @Description : Called by the trigger framework before delete of the records
        @params : List<sObject> newRecordsList , Map<Id, sObject> newRecordsMap
    */            
    void beforeDelete(List<sObject> oldRecordsList , Map<Id, sObject> oldRecordsMap);
    
    /*
        @Description : Called by the trigger framework after delete of the records
        @params : List<sObject> newRecordsList , Map<Id, sObject> newRecordsMap
    */
    void afterDelete(Map<Id, sObject> oldRecordsMap);
    
    /*
        @Description : Called by the trigger framework after undelete of the records
        @params : List<sObject> newRecordsList , Map<Id, sObject> newRecordsMap
    */
    void afterUnDelete(List<sObject> newRecordsList , Map<Id, sObject> newRecordsMap);
}