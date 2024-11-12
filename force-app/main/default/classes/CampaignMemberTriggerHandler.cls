/*
Author       : KiranPunuru
Requested By : Valerie
Description  : This handler class maintains all the logic inside the account object trigger.
Createddate  : 09/8/2022 
*/
public class CampaignMemberTriggerHandler implements TriggerInterface{
    public static boolean shouldRun = false;
    public void BeforeInsert(List<SObject> newCMs) {
        for(CampaignMember cm : (List<CampaignMember>) newCMs){ 
            if(cm.Status == 'Responded'){ 
                cm.LastRespondedDateTime__c = System.now(); 
            }
        }
    }
    public void BeforeUpdate(Map<Id, SObject> newcmMap, Map<Id, SObject> oldcmMap) {
        Map<Id,String> oldMap = new Map<Id,String>();  
        for(CampaignMember cm : (List<CampaignMember>) oldcmMap.values()){
            oldMap.put(cm.Id,cm.Status);    
        }
        for(CampaignMember cm : (List<CampaignMember>) newcmMap.values()) {
            if(cm.Status != oldMap.get(cm.Id) && cm.Status == 'Responded'){ 
                cm.LastRespondedDateTime__c =  system.now();   
            }
        }
    }
    public void AfterInsert(List<sObject> newRecordsList , Map<Id, SObject> newItems) {
        try{
            List<CampaignMember> lstCampaignMem = [SELECT Id,LeadId,ContactId FROM CampaignMember WHERE ID IN :(List<CampaignMember>) newRecordsList AND (Campaign.RecordType.Name = 'Campaign' OR Campaign.RecordType.Name = 'Event Campaign') AND HasResponded = TRUE];
            if(!lstCampaignMem.isEmpty()){
                CampaignMemberHandler.getCampaignMembers(lstCampaignMem,'INSERT');
            }    
        }
        catch(Exception ex){
            HandleCustomException.LogException(ex); 
        }
        
    }
    public void AfterUpdate(Map<Id, SObject> newCMMap, Map<Id, SObject> oldCMMap) {
        try{
            Map<Id,CampaignMember> 	cmpMemberMap = new Map<Id,CampaignMember>();
            Map<Id,CampaignMember> oldMap = new Map<Id,CampaignMember>();  
            for(CampaignMember cm : (List<CampaignMember>) oldCMMap.values()){
                oldMap.put(cm.Id,cm);    
            }
           	List<CampaignMember> lstCmpMember = [SELECT Id,Campaign.RecordType.Name,Campaign.Name,HasResponded FROM CampaignMember WHERE ID IN :(List<CampaignMember>) newCMMap.values()];
            for(CampaignMember cmpMem: lstCmpMember){ 
                if(cmpMem.Campaign.RecordType.Name == 'Campaign' ||cmpMem.Campaign.RecordType.Name == 'Event Campaign'){
                	if(oldMap.get(cmpMem.Id).HasResponded == false && cmpMem.HasResponded == true){
                        cmpMemberMap.put(cmpMem.Id, cmpMem);   
                    }
                }  
            }
            if(cmpMemberMap.Values().size()>0){
                CampaignMemberHandler.getCampaignMembers(cmpMemberMap.Values(),'UPDATE');
            }
        } 
        catch(exception ex){ 
            HandleCustomException.LogException(ex); 
        }
    }
    public void BeforeDelete(List<sObject> newRecordsList , Map<Id, SObject> newItems) {
        try{
            List<CampaignMember> lstCampaignMem = [SELECT Id,LeadId,ContactId FROM CampaignMember WHERE ID IN :(List<CampaignMember>) newRecordsList AND (Campaign.RecordType.Name = 'Campaign' OR Campaign.RecordType.Name = 'Event Campaign') AND HasResponded = TRUE];
            if(!lstCampaignMem.isEmpty()){
                CampaignMemberHandler.getCampaignMembers(lstCampaignMem,'DELETE'); 
            }    
        }
        catch(Exception ex){
            HandleCustomException.LogException(ex);   
        } 
        
    }
    public void AfterDelete(Map<Id, SObject> oldCMMap) {
        
    }
    public void AfterUndelete(List<sObject> newRecordsList , Map<Id, sObject> newItems) {}
}