/*
Description	 : LineItemScheduleTriggerHandler
Created Date : 01-05-2024
Created By   : Kiran 
Test Class   : LineItemScheduleTriggerHandlerTest
*/
public class LineItemScheduleTriggerHandler {
    
    public static void updateVerityRevenueOnOpportunityProductAfterUpdate(List<OpportunityLineItemSchedule> newList,Map<Id,OpportunityLineItemSchedule> oldMap){
        
        try{
            Set<Id> oliIds = new Set<Id>();
            for(OpportunityLineItemSchedule olis: newList){
                if(olis.Verity_Revenue__c!=oldMap.get(olis.Id).Verity_Revenue__c){
                    oliIds.add(olis.OpportunityLineItemId);
                }
            }
            if(oliIds.size()>0){
                List<OpportunityLineItem> oliList = [SELECT ID,Product_Name_Text__c FROM OpportunityLineItem
                                                     WHERE Id in :oliIds AND
                                                     (Product_Name_Text__c ='Video Solution - OLV' OR Product_Name_Text__c ='Video Solution - CTV')];
                
                if(oliList.size()>0){
                    Map<Id,Double> oliId2VeritySum = new Map<Id,Double>();
                    List<OpportunityLineItem> oliListToUpdate = new List<OpportunityLineItem>();
                    List<OpportunityLineItemSchedule> olisList = [SELECT ID, Verity_Revenue__c,OpportunityLineItemId FROM OpportunityLineItemSchedule WHERE OpportunityLineItemId in :oliList];
                    for(OpportunityLineItemSchedule olis: olisList){
                        if(oliId2VeritySum.containsKey(olis.OpportunityLineItemId)){
                            
                            oliId2VeritySum.put(olis.OpportunityLineItemId,(oliId2VeritySum.get(olis.OpportunityLineItemId)) + (olis.Verity_Revenue__c??0));
                        }else{
                            
                            oliId2VeritySum.put(olis.OpportunityLineItemId,olis.Verity_Revenue__c??0);
                        }
                    }
                    system.debug(oliId2VeritySum);
                    for(Id oliId : oliId2VeritySum.keySet()){
                        if(oliId2VeritySum.containsKey(oliId)){
                            OpportunityLineItem oli = new OpportunityLineItem();
                            oli.Id = oliId;
                            oli.Verity_Revenue__c = oliId2VeritySum.get(oliId);
                            oliListToUpdate.add(oli);
                        }
                    }
                    update oliListToUpdate;
                }
            }
            
        }catch(Exception ex){
            HandleCustomException.LogException(ex);  
            system.debug(ex);
        }
    }
    
    public static void updateActualVerityAmountOnOliAfterUpdate(List<OpportunityLineItemSchedule> newList,Map<Id,OpportunityLineItemSchedule> oldMap){
        try{
            set<Id> oliIds = new Set<Id>();
            set<Id> affectedOliIds = new Set<Id>();
            for(OpportunityLineItemSchedule olis:newList){
                if(olis.Actual_Revenue_Verity__c!=oldMap.get(olis.Id).Actual_Revenue_Verity__c){
                    oliIds.add(olis.OpportunityLineItemId);
                }
            }
            if(oliIds.size()>0){
                List<OpportunityLineItem> advOlisList = [SELECT Id,Opportunity.RecordType.Name
                                                         FROM OpportunityLineItem
                                                         WHERE (Opportunity.RecordType.Name = 'Advertising' OR Opportunity.RecordType.Name='Verity - Demand')
                                                         AND Id in :oliIds];
                if(advOlisList.size()>0){
                    rollupActualVerityRevenue(advOlisList);
                }
            }            
        }catch(Exception ex){
            HandleCustomException.LogException(ex);  
            system.debug(ex);
        }  
    }
    public static void updateActualVerityAmountOnOliAfterInsert(List<OpportunityLineItemSchedule> newList){
        
        try{            
            set<Id> oliIds = new Set<Id>();
            set<Id> affectedOliIds = new Set<Id>();
            for(OpportunityLineItemSchedule olis:newList){
                if(olis.Actual_Revenue_Verity__c!=null){
                    oliIds.add(olis.OpportunityLineItemId);
                }
            }
            if(oliIds.size()>0){
                List<OpportunityLineItem> advOlisList = [SELECT Id,Opportunity.RecordType.Name
                                                         FROM OpportunityLineItem
                                                         WHERE (Opportunity.RecordType.Name = 'Advertising' OR Opportunity.RecordType.Name='Verity - Demand')
                                                         AND Id in :oliIds];
                if(advOlisList.size()>0){
                    rollupActualVerityRevenue(advOlisList);
                }
            }  
        }catch(Exception ex){
            HandleCustomException.LogException(ex);  
            system.debug(ex);
        }
    }
   
    
    public static void rollupActualVerityRevenue(List<opportunityLineItem> oliList){
        if(oliList.size()>0){
            List<OpportunityLineItem> oliListToUpdate = new List<OpportunityLineItem>();
            Map<Id,Decimal> oliId2ActualAmountVerityMap = new Map<Id,Decimal>();
            List<OpportunityLineItemSchedule> olisList = [SELECT Id,Actual_Revenue_Verity__c,OpportunityLineItemId FROM OpportunityLineItemSchedule WHERE OpportunityLineItemId in :oliList];
            
            for(OpportunityLineItemSchedule olis: olisList){
                if(oliId2ActualAmountVerityMap.containsKey(olis.OpportunityLineItemId)){
                    
                    oliId2ActualAmountVerityMap.put(olis.OpportunityLineItemId,(oliId2ActualAmountVerityMap.get(olis.OpportunityLineItemId)) + (olis.Actual_Revenue_Verity__c??0));
                }else{
                    
                    oliId2ActualAmountVerityMap.put(olis.OpportunityLineItemId,olis.Actual_Revenue_Verity__c??0);
                }
            }
            for(ID oliId: oliId2ActualAmountVerityMap.keyset()){
                if(oliId2ActualAmountVerityMap.containsKey(oliId)){
                    OpportunityLineItem oli = new OpportunityLineItem();
                    oli.ID = oliId;
                    oli.Actual_Amount_Verity__c = oliId2ActualAmountVerityMap.get(oliId);
                    oliListToUpdate.add(oli);
                }
            }
            update oliListToUpdate;
        }
    }
    
    
    
}