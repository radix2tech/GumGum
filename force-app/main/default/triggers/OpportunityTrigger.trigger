/**
Trigger Name               - OpportunityTrigger 
Description                - Trigger to fetch the Targeting and GeoTargeting records on cloning of Opportunity
Change Request             - CR-001(01-04-2024) SOP-2656 - Advertising Opportunity Updates for Gross vs Net Calculations
                             Updated the code to populate Net_Total_Ordered_Amount_1__c on Opportunity with aggregate of Net_Total_Price__c(OpportunityLineItem)
							 CR-002(2024-09-15) For Verity - Demand, On change of Voiced Budget, recalculate the products
**/

trigger OpportunityTrigger on Opportunity (before update,before insert, after insert,after update,after delete) 
{
  
    // Commented the below code as this part of code moved to flow
    /*if(trigger.isBefore){
       OpportunityTriggerHandler.setPricebookOnOppty(trigger.new);
    } */
    //Checking if trigger is Active From Metadata 
    if(Trigger_Settings__mdt.getInstance('Opportunity').Active__c){
        if(trigger.isBefore){
            if(trigger.isUpdate){
                //Updating Gross to Net Fields on Opportunity
                OpportunityTriggerHandlerNew.grossToNetCalculationsAfterUpdate(Trigger.New,Trigger.OldMap);    
                
                //Updating the Currency Conversin Field - Deprecated
                //OpportunityTriggerHandlerNew.updateCurrencyRateBeforeUpdate(Trigger.New,Trigger.OldMap);
            }
        }
        if(trigger.isAfter){
            if(trigger.isInsert){
                OpportunityTriggerHandler.cloneRelatedRecords(Trigger.newMap.keySet());
                
                //Inserting The Primary Contact field from opportunity as Primary Opportunity Contact Role
                OpportunityTriggerHandlerNew.insertPrimaryContactRole(Trigger.New);
                //Update Opportunity_Count_Brand_and_Agency__c field On Acount
                OpportunityTriggerHandlerNew.countOfOpportunityAfterInsertOrDelete(Trigger.New);
                
            }
            if(trigger.isUpdate){
                //Upsert on OpportunityContactRole depending on the Primary Contact field on Opportunity
                //OpportunityTriggerHandlerNew.insertPrimaryContactRoleOnUpdate(Trigger.NewMap,Trigger.OldMap);
                
                //Update Opportunity_Count_Brand_and_Agency__c field On Acount
                OpportunityTriggerHandlerNew.countOfOpportunityAfterUpdate(Trigger.New,Trigger.OldMap);
                
                //Update Net_Total_Ordered_Amount_1__c field On Opportunity
                OpportunityTriggerHandlerNew.updateNetTotalOrderedAMountAfterUpdate(Trigger.New,Trigger.OldMap);
                
                //Recalculate Products on change of Voiced Budget on Verity - Demand Opportunities
                OpportunityTriggerHandlerNew.recalculateProductOnVerityDemandVoicedBudgetUpdate(Trigger.New,Trigger.OldMap);
                
                
            }
            if(trigger.isDelete){
                //Update Opportunity_Count_Brand_and_Agency__c field On Acount
                OpportunityTriggerHandlerNew.countOfOpportunityAfterInsertOrDelete(Trigger.old);
            }
        }
    }
}