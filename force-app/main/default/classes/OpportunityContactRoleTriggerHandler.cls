/*
	Description	   : OpportunityContactRoleTrigger Handler Class
	Created Date   : 09-12-2022
	Created By     : Kiran
	Change Request : 
*/
public with sharing class OpportunityContactRoleTriggerHandler implements TriggerInterface{
    
    public void BeforeInsert(List<SObject> newRecordList){}
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
    
    public void BeforeDelete(List<sObject> oldRecordsList , Map<Id, SObject> oldItems) {
        //Avoiding Delete of Primary Contact
        List<OpportunityContactRole> oppConRoleList = (List<OpportunityContactRole>)oldRecordsList;
        for(OpportunityContactRole oppConRole: oppConRoleList){
            if(oppConRole.isPrimary){
                oppConRole.addError('Cannot Delete Primary Contact Role');
            }
        }
    }
    
    public void AfterInsert(List<sObject> newRecordsList , Map<Id, SObject> newItems) {
        List<OpportunityContactRole> oppConRoleList = (List<OpportunityContactRole>)newRecordsList;
        List<Opportunity> oppList = new List<Opportunity>();
        //To store Only Primary Contact Roles
        List<OpportunityContactRole> newOppConRoleList = new List<OpportunityContactRole>();
        for(OpportunityContactRole oppConRole:oppConRoleList){
            if(oppConRole.IsPrimary){
                newOppConRoleList.add(oppConRole);
            }
        }

        if(newOppConRoleList.size()>0){      
            for(OpportunityContactRole oppConRole:newOppConRoleList){
                Opportunity opp = new Opportunity();
                opp.Id = oppConRole.OpportunityId;
                opp.SalesLoft1__Primary_Contact__c = oppConRole.ContactId;
                oppList.add(opp);
            }
            if(oppList.size()>0){
                try{
                    update oppList;
                }catch(Exception e){
                    system.debug(e);
                }        
            }
        } 
    }
    
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {

        List<OpportunityContactRole> oppConRoleList = (List<OpportunityContactRole>)newItems.values();
        Map<Id,OpportunityContactRole> oppConRoleOldMap = new Map<Id,OpportunityContactRole>();
        for(OpportunityContactRole oppConRole: (List<OpportunityContactRole>)oldItems.values()){
            oppConRoleOldMap.put(oppConRole.Id,oppConRole);
        }

        Set<Id> oppIds = new Set<Id>();
        for(OpportunityContactRole oppConRole:oppConRoleList){
            if(oppConRole.IsPrimary!=oppConRoleOldMap.get(oppConRole.Id).IsPrimary){
                oppIds.add(oppConRole.OpportunityId);
            }
        }    
        if(oppIds.size()>0){ 
            List<Opportunity> oppList =[SELECT Id,SalesLoft1__Primary_Contact__c,(SELECT Id,IsPrimary,ContactId,OpportunityId FROM OpportunityContactRoles WHERE IsPrimary = True) FROM Opportunity WHERE Id in :oppIds];
            for(Opportunity opp : oppList){
                if(opp.OpportunityContactRoles.size()>0){                
                    opp.SalesLoft1__Primary_Contact__c = opp.OpportunityContactRoles[0].ContactId;
                }else {
                    opp.SalesLoft1__Primary_Contact__c = null;
                }
            }
            if(oppList.size()>0){  
                try{
                    update oppList;
                }catch(Exception e){
                    system.debug(e);
                } 
            }           
        }      
    }
    public void AfterDelete(Map<Id, SObject> oldItems) {}
    public void AfterUndelete(List<sObject> newRecordsList , Map<Id, sObject> newItems) {}
}