/*
Description	 : OpportunityLineItemTriggerHandler
Created Date : 10-04-2024
Created By   : Kiran 
*/
public class OpportunityLineItemTriggerHandler implements TriggerInterface{ 
    public void BeforeInsert(List<SObject> newRecordsList) {}
    public void BeforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {}
    public void BeforeDelete(List<sObject> oldRecordsList , Map<Id, SObject> oldItems) {}
    
    public void AfterInsert(List<sObject> newRecordsList , Map<Id, SObject> newItems) {
        try{
            List<OpportunityLineItem> newList = (List<OpportunityLineItem>)newRecordsList;
            Set<Id> allOppIds = new Set<Id>();
            Set<Id> advOppIds = new Set<Id>();
            //Map<Id,Decimal> oppId2NetTotalOrderedAmount = new Map<Id,Decimal>();
            //List<Opportunity> oppListToUpdate = new List<Opportunity>();
            
            for(OpportunityLineItem oli:newList){
                allOppIds.add(oli.OpportunityId);
            }
            List<Opportunity> oppList = [SELECT Id,RecordType.Name from Opportunity WHERE ID in :allOppIds];
            for(Opportunity opp: oppList){
                //Checking for Advertising Record Type
                if(opp.RecordType.Name =='Advertising'){
                    advOppIds.add(opp.Id);
                }
            }
            if(advOppIds.size()>0){
                updateNetTotalOrderedAmountOnOpportunity(advOppIds);
            }
        }catch(Exception ex){
            HandleCustomException.LogException(ex);  
            system.debug(ex);
        }
    }
    public void AfterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        
    }
    public void AfterDelete(Map<Id, SObject> oldItems) {
        
        try{
            Map<Id,OpportunityLineItem> oldMap = new Map<Id,OpportunityLineItem>();
            for(OpportunityLineItem oli : (List<OpportunityLineItem>) oldItems.values()){  
                oldMap.put(oli.Id,oli);  
            }
            Set<Id> allOppIds = new Set<Id>();
            Set<Id> advOppIds = new Set<Id>();
            //Map<Id,Decimal> oppId2NetTotalOrderedAmount = new Map<Id,Decimal>();
            //List<Opportunity> oppListToUpdate = new List<Opportunity>();
            
            for(OpportunityLineItem oli:oldMap.Values()){
                allOppIds.add(oli.OpportunityId);
            }
            List<Opportunity> oppList = [SELECT Id,RecordType.Name from Opportunity WHERE ID in :allOppIds];
            for(Opportunity opp: oppList){
                 //Checking for Advertising Record Type
                if(opp.RecordType.Name =='Advertising'){
                    advOppIds.add(opp.Id);
                }
            }
            if(advOppIds.size()>0){
                updateNetTotalOrderedAmountOnOpportunity(advOppIds);
            }
        }catch(Exception ex){
            HandleCustomException.LogException(ex);  
            system.debug(ex);
        }
    }
    public void AfterUndelete(List<sObject> newRecordsList , Map<Id, sObject> newItems) {}
    
    public static void updateNetTotalOrderedAmountOnOpportunity(Set<Id> oppIds){
        if(oppIds.size()>0){
            List<Opportunity> oppListToUpdate = new List<Opportunity>();
            Map<Id,Decimal> oppId2NetTotalOrderedAmount = new Map<Id,Decimal>();
            List<OpportunityLineItem> oliList = [SELECT OpportunityId,Net_Total_Price__c FROM OpportunityLineItem WHERE OpportunityId in :oppIds];
            for(OpportunityLineItem oli: oliList){
                if(oppId2NetTotalOrderedAmount.containsKey(oli.OpportunityId)){
                    
                    oppId2NetTotalOrderedAmount.put(oli.OpportunityId,(oppId2NetTotalOrderedAmount.get(oli.OpportunityId)) + (oli.Net_Total_Price__c??0));
                }else{
                    
                    oppId2NetTotalOrderedAmount.put(oli.OpportunityId,oli.Net_Total_Price__c??0);
                }
            }
             for(ID oppId: oppId2NetTotalOrderedAmount.keyset()){
                if(oppId2NetTotalOrderedAmount.containsKey(oppId)){
                    Opportunity opp = new Opportunity();
                    opp.ID = oppId;
                    opp.Net_Total_Ordered_Amount_1__c = oppId2NetTotalOrderedAmount.get(oppId);
                    oppListToUpdate.add(opp);
                }
            }
            update oppListToUpdate;
        }
    }
}