/* Helper Class for OpportunityLineItemTrg To Update the Opportunity with the Earliest Start Date and Latest End Date
   Ankita Goel, 1/17/18  */

public class OpportunityLineItemTrgHelper{

    @future
    // method To Update the Opportunity with the Earliest Start Date and Latest End Date
    public static void setStartEndDate(Set<Id> OppLineItmId){

        Map<Id,Opportunity > oppIdToOpportunityMap = new Map<Id,Opportunity >();
        Map<Id,List<OpportunityLineItem> > oppIdToListOppLineItmMap = new Map<Id,List<OpportunityLineItem> >();
        Map<Id,Opportunity>  idToOppToUpdateMap = new Map<Id,Opportunity>();
        
        System.debug('@@@@@@@@@@@@@@@@@ Opp Line Item Id'+OppLineItmId);       

// populating the map of opportunity ids to the list of Opp Line Items

        for(OpportunityLineItem opL :[select id,name,Start_Date__c,End_Date__c,OpportunityId from OpportunityLineItem where id in : OppLineItmId]){

            if(oppIdToListOppLineItmMap.containsKey(opL.OpportunityId) && oppIdToListOppLineItmMap.get(opL.OpportunityId) != null) {
                List<OpportunityLineItem> listOppLineItm = oppIdToListOppLineItmMap.get(opL.OpportunityId);
                listOppLineItm.add(opL);
                oppIdToListOppLineItmMap.put(opL.OpportunityId,listOppLineItm); 
            }   
            else{
                oppIdToListOppLineItmMap.put(opL.OpportunityId, new List<OpportunityLineItem> {opL});
            }
        }
        System.debug('@@@@@@@@@@@@@@@@@ oppIdToListOppLineItmMap'+oppIdToListOppLineItmMap);            
        
 // populating the map of opportunity id to opportunity      
        for(Opportunity opp :[select id, name,Start_Date__c,End_Date__c from Opportunity where id in: oppIdToListOppLineItmMap.keyset()]){
            oppIdToOpportunityMap.put(opp.id,opp);
        } 
        System.debug('@@@@@@@@@@@@@@@@@ oppIdToOpportunityMap'+oppIdToOpportunityMap);    
  //   iterating each opportunity to the corresponding opp line items to find the earliest start date and latest End Date       
        for(Opportunity opp : oppIdToOpportunityMap.values() ){
            for (OpportunityLineItem opL :oppIdToListOppLineItmMap .get(opp.id)){

                if(opL.Start_Date__c < opp.Start_Date__c || opp.Start_Date__c == null ){
                    if(idToOppToUpdateMap.keySet().contains(opp.id)){
                        idToOppToUpdateMap.get(opp.id).Start_Date__c = opL.Start_Date__c ;
                    }
                    else{
                        idToOppToUpdateMap.put(opp.id,opp);
                        idToOppToUpdateMap.get(opp.id).Start_Date__c = opL.Start_Date__c ;
                    }     
                }

                if(opL.End_Date__c > opp.End_Date__c || opp.End_Date__c == null ){
                    if(idToOppToUpdateMap.keySet().contains(opp.id)){
                        idToOppToUpdateMap.get(opp.id).End_Date__c = opL.End_Date__c;
                    }
                    else{
                        idToOppToUpdateMap.put(opp.id,opp);
                        idToOppToUpdateMap.get(opp.id).End_Date__c = opL.End_Date__c ;
                    }                 
                } 

            }
        }
        // System.debug('@@@@@@@@@@@@@@@@@ Opportunity To Update Start date'+oppToUpdateStartDate);
        // System.debug('@@@@@@@@@@@@@@@@@ Opportunity To Update End Date'+oppToUpdateStartDate);
// Updating the opportunity 
        try{
            if(idToOppToUpdateMap.size()>0){
                update idToOppToUpdateMap.values();
            }
        }  
        catch (Exception e){
        }                     
    }
}