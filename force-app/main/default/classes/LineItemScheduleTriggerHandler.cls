/*
Description	 : LineItemScheduleTriggerHandler
Created Date : 01-05-2024
Created By   : Kiran 
Test Class   : LineItemScheduleTriggerHandlerTest
Change Request : CR#1 Date: 15/11/2024
				 Description: Changes made to handle the update of the field Maximum_Actual_Verity_Schedule_Date__c at Opportunity Product
							  When Verity Actual Revenue is update on the Schedule or When a Schedule is created with Verity Actual Revenue.
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
    
    //updates Maximum_Actual_Verity_Schedule_Date__c on Opportunity Products when a Schedule with Actual Verity Revenue is Created/Deleted
    public static void updateMaximumActualVeritySchedulDateOnInsertOrDelete(List<OpportunityLineItemSchedule> olisList){
        
        try{
            Set<Id> effectedOliIdSet = new Set<Id>();
            for(OpportunityLineItemSchedule olis: olisList){
                if(olis.Actual_Revenue_Verity__c !=null && olis.Actual_Revenue_Verity__c >0){
                    effectedOliIdSet.add(olis.OpportunityLineItemId);
                }
            }
            if(!effectedOliIdSet.isEmpty()){
                rollupMaxActualVerityRevenueDate(effectedOliIdSet);
            }
        }catch(Exception ex){
            HandleCustomException.LogException(ex);  
            system.debug(ex);
        }
    }
    
    //updates Maximum_Actual_Verity_Schedule_Date__c when Actual_Revenue_Verity__c is changed
    public static void updateMaximumActualVeritySchedulDateOnUpdate(List<OpportunityLineItemSchedule> olisList,Map<Id,OpportunityLineItemSchedule> oldMap){
        
        try{
            Set<Id> effectedOliIdSet = new Set<Id>();
            for(OpportunityLineItemSchedule olis: olisList){
                //checking if the Actual_Revenue_Verity__c is changed from blank or 0 to Valid value and vice versa
                if(
                    (olis.Actual_Revenue_Verity__c!=oldMap.get(olis.Id).Actual_Revenue_Verity__c) &&
                    (
                        (olis.Actual_Revenue_Verity__c>0 && (oldMap.get(olis.Id).Actual_Revenue_Verity__c==0 ||oldMap.get(olis.Id).Actual_Revenue_Verity__c==null))||
                        (oldMap.get(olis.Id).Actual_Revenue_Verity__c>0 && (olis.Actual_Revenue_Verity__c==null || olis.Actual_Revenue_Verity__c==0))
                    )
                ){
                    effectedOliIdSet.add(olis.OpportunityLineItemId);
                }
            }
            if(!effectedOliIdSet.isEmpty()){
                rollupMaxActualVerityRevenueDate(effectedOliIdSet);
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
    
    //Rolling up the Max Actual Verity Schedule Date
    public static void rollupMaxActualVerityRevenueDate(Set<Id> oliIdSet){
        if(oliIdSet.size()>0){
            Map<Id,Date> oliId2MaxActualVerityScheDate = new Map<Id,Date>();
            List<OpportunityLineItem> oliListToUpdate = new List<OpportunityLineItem>();
            List<AggregateResult> groupedOliMaxScheduleDateResult = [SELECT OpportunityLineItemId,Max(ScheduleDate)maxScheduleDate FROM
                                         OpportunityLineItemSchedule
                                         WHERE OpportunityLineItemId in :oliIdSet AND Actual_Revenue_Verity__c>0  GROUP BY OpportunityLineItemId];
            for(AggregateResult ar: groupedOliMaxScheduleDateResult){
                system.debug('maxScheduleDate'+ar.get('maxScheduleDate'));
                oliId2MaxActualVerityScheDate.put((Id)ar.get('OpportunityLineItemId'),(Date)ar.get('maxScheduleDate'));
            }
            for(Id oliId: oliIdSet){
                OpportunityLineItem oliRecord = new OpportunityLineItem();
                oliRecord.Id = oliId;
                if(oliId2MaxActualVerityScheDate.containsKey(oliId)){
                    oliRecord.Maximum_Actual_Verity_Schedule_Date__c = oliId2MaxActualVerityScheDate.get(oliId);
                }else{
                    oliRecord.Maximum_Actual_Verity_Schedule_Date__c = null;
                }
                oliListToUpdate.add(oliRecord);
            }
            if(!oliListToUpdate.isEmpty()){
                system.debug('@@@@@@@@oliList'+oliListToUpdate);
                update oliListToUpdate;
            }
        }
    }
  
}