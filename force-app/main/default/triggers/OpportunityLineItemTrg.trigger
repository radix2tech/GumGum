/* Trigger On Opportunity Line Item To Update the Opportunity with the Earliest Start Date and Latest End Date
   Ankita Goel, 1/17/18  */

trigger OpportunityLineItemTrg on OpportunityLineItem (after insert, after update) {
    set<id> oppLnItmId = new Set<id>();
    // Check For After Insert of  OpportunityLineItem 
              
    if(Trigger.isInsert && Trigger.isAfter){

        for(OpportunityLineItem opl : trigger.new){
            oppLnItmId.add(opl.id);
        }
         System.debug('Opportunity line item Id @@@@@@@@@'+oppLnItmId);
         System.debug('@@@@@@@@@@@@@@@@@Size of oppLineItem'+oppLnItmId.size());
        if(oppLnItmId.size()>0){  
            OpportunityLineItemTrgHelper.setStartEndDate(oppLnItmId);
        }
    }
    // Check For After Update of  OpportunityLineItem 
       
    if(Trigger.isUpdate && Trigger.isAfter){

        for(OpportunityLineItem opl : trigger.new){
            OpportunityLineItem oldOppLineItem = Trigger.oldMap.get(opl.Id);
            if(opl.Start_Date__c != oldOppLineItem.Start_Date__c || opl.End_Date__c != oldOppLineItem.End_Date__c  ){
                oppLnItmId.add(opl.id);
            }
        }
        System.debug('Opportunity line item Id @@@@@@@@@'+oppLnItmId);
        System.debug('@@@@@@@@@@@@@@@@@Size of oppLineItem'+oppLnItmId.size());
        if(oppLnItmId.size()>0){
             OpportunityLineItemTrgHelper.setStartEndDate(oppLnItmId);
        }
    }

}