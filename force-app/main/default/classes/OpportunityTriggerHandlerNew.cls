/*
Description    : OpportunityTrigger New  Handler Class
Created Date   : 12-12-2022 
Created By     : Kiran
Change Request : CR-001(07-04-2023) Gross to Net Calculatins
Change Request : CR-002(11-07-2023) Method - updateCurrencyRateBeforeUpdate -Added logic to calculate the Conversion rate whenever the stage is chagned to Closed/Won
Change Request : CR-003(27-10-2023) Updated the Code where Opportunity_Record_Types__mdt fetch recordTypes
Change Request : CR-004(01-04-2024) Updated the code to populate Net_Total_Ordered_Amount_1__c on Opportunity with aggregate of Net_Total_Price__c(OpportunityLineItem)
Change Request : CR-005(2024-09-15) For Verity - Demand, On change of Voiced Budget, recalculate the products
Change Request : CR-006(2025-01-30) For Verity - Demand, On change of Voiced Budget, fixed the bug on verity actuals during products recalculation
*/
public without sharing class OpportunityTriggerHandlerNew {
    
    //Inserting The Primary Contact field from opportunity as Primary Opportunity Contact Role
    public static void insertPrimaryContactRole(List<Opportunity> newOppList){
        List<OpportunityContactRole> OppConRoleList = new List<OpportunityContactRole>();
        for(Opportunity opp:newOppList){
            OpportunityContactRole oppConRole = new OpportunityContactRole();
            oppConRole.OpportunityId = opp.Id;
            oppConRole.ContactId = opp.SalesLoft1__Primary_Contact__c;
            oppConRole.IsPrimary = true;
            OppConRoleList.add(oppConRole);
        } 
        if(OppConRoleList.size()>0){
            try{
                insert OppConRoleList;
            }catch(Exception e){
                system.debug('Exception: '+e);
            }
        }
    }
    
    /* public static void insertPrimaryContactRoleOnUpdate(Map<Id,Opportunity> newMap,Map<Id,Opportunity> oldMap){
system.debug('afterUpdateOpp');
//filtering Opportunities 
Set<Id> filterOppIds = new Set<Id>();
for(Opportunity opp:newMap.values()){
if((opp.SalesLoft1__Primary_Contact__c!=oldMap.get(opp.Id).SalesLoft1__Primary_Contact__c) && oldMap.get(opp.Id).SalesLoft1__Primary_Contact__c==null){
filterOppIds.add(opp.Id);
}
}
system.debug(filterOppIds);
List<OpportunityContactRole> OppConRoleList = new List<OpportunityContactRole>();
List<OpportunityContactRole> getOppConRoleList = [SELECT Id,OpportunityId,ContactId,IsPrimary FROM OpportunityContactRole WHERE OpportunityId in :filterOppIds];
//map - value - contactRoleId, key = 'conId+oppId';
Map<String,String> conIdOppId2OppConRoleIdMap = new Map<String,String>();
//To update exisiting ContactRoles to Primary
for(OpportunityContactRole oppConRole:getOppConRoleList){
conIdOppId2OppConRoleIdMap.put((oppConRole.ContactId+''+oppConRole.OpportunityId) ,oppConRole.Id);
}      
for(Id oppId:filterOppIds){

OpportunityContactRole oppConRole = new OpportunityContactRole();
if(conIdOppId2OppConRoleIdMap.containsKey(newMap.get(oppId).SalesLoft1__Primary_Contact__c+''+oppId)){
oppConRole.Id = conIdOppId2OppConRoleIdMap.get(newMap.get(oppId).SalesLoft1__Primary_Contact__c+''+oppId);
oppConRole.IsPrimary = true;
oppConRoleList.add(oppConRole);
}else{
oppConRole.OpportunityId = oppId;
oppConRole.ContactId = newMap.get(oppId).SalesLoft1__Primary_Contact__c;
oppConRole.IsPrimary = true;
OppConRoleList.add(oppConRole);
}  

} 
if(OppConRoleList.size()>0){
try{
upsert OppConRoleList;
}catch(Exception e){
system.debug('Exception: '+e);
}
}  
}*/
    
    //On Insert or Delete of Opportunity, Update the Opportunity_Count_Brand_and_Agency__c field on Account with both Brand And Agency Opportunities
    public static void countOfOpportunityAfterInsertOrDelete(List<Opportunity> oppList){
        List<Account> accList = new List<Account>();
        //To store RecordTypeIds From Custom Metadata
        List<Id> recordTypeIds = new List<Id>();
        //Adding Effected AccountIds
        Set<Id> accountIdSet = new Set<Id>();
        for(Opportunity_Record_Types__mdt oppRecordTypeMdt: Opportunity_Record_Types__mdt.getAll().values()){
            recordTypeIds.add(Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(oppRecordTypeMdt.Record_Type_Name__c).getRecordTypeId());
        }
        for(Opportunity opp: oppList){
            if(recordTypeIds.contains(opp.RecordTypeId)){
                if(opp.Agency_Name__c!=Null){
                    AccountIdSet.add(opp.Agency_Name__c);
                }      
            }  
        }
        if(accountIdSet.size()>0){
            try{
                Map<Id,Integer> AccountId2onlyAgencyOppCount = new Map<Id,Integer>();
                Map<Id,Integer> AccountId2onlyAgencyOppWonCount = new Map<Id,Integer>();
                Map<Id,Integer> AccountId2onlyAgencyOppOpenCount = new Map<Id,Integer>();
                Map<Id,Integer> AccountId2onlyAgencyOppWonAndOpenCount = new Map<Id,Integer>();
                for(Opportunity opp: [SELECT Id,AccountId,Agency_Name__c,StageName,RecordTypeId FROM Opportunity WHERE Agency_Name__c in :accountIdSet AND Agency_Name__c!=Null AND RecordTypeId in :recordTypeIds]){
                    if(AccountId2onlyAgencyOppCount.containsKey(opp.Agency_Name__c)){
                        AccountId2onlyAgencyOppCount.put(opp.Agency_Name__c,AccountId2onlyAgencyOppCount.get(opp.Agency_Name__c)+1);
                    }else{
                        AccountId2onlyAgencyOppCount.put(opp.Agency_Name__c,1);
                    }
                    if(opp.stageName == 'Closed/Won'){
                        if(AccountId2onlyAgencyOppWonCount.containsKey(opp.Agency_Name__c)){
                            AccountId2onlyAgencyOppWonCount.put(opp.Agency_Name__c,AccountId2onlyAgencyOppWonCount.get(opp.Agency_Name__c)+1);
                        }else{
                            AccountId2onlyAgencyOppWonCount.put(opp.Agency_Name__c,1);
                        }       
                    }
                    if(opp.stageName !='Closed/Won' && opp.stageName !='Closed/Lost' && opp.stageName !='Discard'){
                        if(AccountId2onlyAgencyOppOpenCount.containsKey(opp.Agency_Name__c)){
                            AccountId2onlyAgencyOppOpenCount.put(opp.Agency_Name__c,AccountId2onlyAgencyOppOpenCount.get(opp.Agency_Name__c)+1);
                        }else{
                            AccountId2onlyAgencyOppOpenCount.put(opp.Agency_Name__c,1);
                        }   
                    }
                    if(opp.stageName !='Closed/Lost' && opp.stageName !='Discard'){
                        if(AccountId2onlyAgencyOppWonAndOpenCount.containsKey(opp.Agency_Name__c)){
                            AccountId2onlyAgencyOppWonAndOpenCount.put(opp.Agency_Name__c,AccountId2onlyAgencyOppWonAndOpenCount.get(opp.Agency_Name__c)+1);
                        }else{
                            AccountId2onlyAgencyOppWonAndOpenCount.put(opp.Agency_Name__c,1);
                        }  
                    }   
                }
                Account acc;
                for(Id accId : AccountIdSet){
                    acc = new Account();
                    acc.Id = accId;
                    if(AccountId2onlyAgencyOppCount.containsKey(accId)){
                        acc.Only_Agency_Opp_Count__c = AccountId2onlyAgencyOppCount.get(accId);
                    }else{
                        
                    }
                    if(AccountId2onlyAgencyOppWonCount.containsKey(accId)){
                        acc.Only_Agency_Opp_Won_Count__c = AccountId2onlyAgencyOppWonCount.get(accId);
                    }else{
                        acc.Only_Agency_Opp_Won_Count__c = 0;
                    }
                    if(AccountId2onlyAgencyOppOpenCount.containsKey(accId)){
                        acc.Only_Agency_Open_Opp_Count__c = AccountId2onlyAgencyOppOpenCount.get(accId);
                    }else{
                        acc.Only_Agency_Open_Opp_Count__c = 0;
                    }
                    if(AccountId2onlyAgencyOppWonAndOpenCount.containsKey(accId)){
                        acc.Only_Agency_Open_and_Won_Opp_Count__c = AccountId2onlyAgencyOppWonAndOpenCount.get(accId);    
                    }else{
                        acc.Only_Agency_Open_and_Won_Opp_Count__c = 0;
                    }
                    accList.add(acc);
                }        
                update accList;
            }catch(Exception ex){
                HandleCustomException.LogException(ex);  
                system.debug(ex);
            } 
        }   
    } 
    
    //On Update of Opportunity,Update the Opportunity_Count_Brand_and_Agency__c field on Account with both Brand And Agency Opportunities
    public static void countOfOpportunityAfterUpdate(List<Opportunity> newOppList,Map<Id,Opportunity> oldMap){  
        List<Account> accList = new List<Account>();
        //To store RecordTypeIds From Custom Metadata
        List<Id> recordTypeIds = new List<Id>();
        //Adding Effected AccountIds
        Set<Id> accountIdSet = new Set<Id>();
        for(Opportunity_Record_Types__mdt oppRecordTypeMdt: Opportunity_Record_Types__mdt.getAll().values()){
            recordTypeIds.add(Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(oppRecordTypeMdt.Record_Type_Name__c).getRecordTypeId());
        }
        for(Opportunity opp:newOppList){
            if(opp.Agency_Name__c!= oldMap.get(opp.Id).Agency_Name__c && recordTypeIds.contains(opp.RecordTypeId)){
                if(opp.Agency_Name__c!=Null){
                    accountIdSet.add(opp.Agency_Name__c);
                }
                if(oldMap.get(opp.Id).Agency_Name__c!= Null){
                    accountIdSet.add(oldMap.get(opp.Id).Agency_Name__c);
                }    
            }
            if(opp.StageName!=oldMap.get(opp.Id).stageName){
                if(opp.Agency_Name__c!=Null){
                    accountIdSet.add(opp.Agency_Name__c);
                }   
            }
        }
        if(AccountIdSet.size()>0){
            try{
                Map<Id,Integer> AccountId2onlyAgencyOppCount = new Map<Id,Integer>();
                Map<Id,Integer> AccountId2onlyAgencyOppWonCount = new Map<Id,Integer>();
                Map<Id,Integer> AccountId2onlyAgencyOppOpenCount = new Map<Id,Integer>();
                Map<Id,Integer> AccountId2onlyAgencyOppWonAndOpenCount = new Map<Id,Integer>();
                for(Opportunity opp: [SELECT Id,AccountId,Agency_Name__c,StageName,RecordTypeId FROM Opportunity WHERE Agency_Name__c in :AccountIdSet AND Agency_Name__c!=Null AND RecordTypeId in :recordTypeIds]){
                    if(AccountId2onlyAgencyOppCount.containsKey(opp.Agency_Name__c)){
                        AccountId2onlyAgencyOppCount.put(opp.Agency_Name__c,AccountId2onlyAgencyOppCount.get(opp.Agency_Name__c)+1);
                    }else{
                        AccountId2onlyAgencyOppCount.put(opp.Agency_Name__c,1);
                    }
                    if(opp.stageName == 'Closed/Won'){
                        if(AccountId2onlyAgencyOppWonCount.containsKey(opp.Agency_Name__c)){
                            AccountId2onlyAgencyOppWonCount.put(opp.Agency_Name__c,AccountId2onlyAgencyOppWonCount.get(opp.Agency_Name__c)+1);
                        }else{
                            AccountId2onlyAgencyOppWonCount.put(opp.Agency_Name__c,1);
                        }       
                    }
                    if(opp.stageName !='Closed/Won' && opp.stageName !='Closed/Lost' && opp.stageName !='Discard'){
                        if(AccountId2onlyAgencyOppOpenCount.containsKey(opp.Agency_Name__c)){
                            AccountId2onlyAgencyOppOpenCount.put(opp.Agency_Name__c,AccountId2onlyAgencyOppOpenCount.get(opp.Agency_Name__c)+1);
                        }else{
                            AccountId2onlyAgencyOppOpenCount.put(opp.Agency_Name__c,1);
                        }   
                    }
                    if(opp.stageName !='Closed/Lost' && opp.stageName !='Discard'){
                        if(AccountId2onlyAgencyOppWonAndOpenCount.containsKey(opp.Agency_Name__c)){
                            AccountId2onlyAgencyOppWonAndOpenCount.put(opp.Agency_Name__c,AccountId2onlyAgencyOppWonAndOpenCount.get(opp.Agency_Name__c)+1);
                        }else{
                            AccountId2onlyAgencyOppWonAndOpenCount.put(opp.Agency_Name__c,1);
                        }  
                    }   
                }
                Account acc;
                for(Id accId : AccountIdSet){
                    acc = new Account();
                    acc.Id = accId;
                    if(AccountId2onlyAgencyOppCount.containsKey(accId)){
                        acc.Only_Agency_Opp_Count__c = AccountId2onlyAgencyOppCount.get(accId);
                    }
                    if(AccountId2onlyAgencyOppWonCount.containsKey(accId)){
                        acc.Only_Agency_Opp_Won_Count__c = AccountId2onlyAgencyOppWonCount.get(accId);
                    }else{
                        acc.Only_Agency_Opp_Won_Count__c = 0;
                    }
                    if(AccountId2onlyAgencyOppOpenCount.containsKey(accId)){
                        acc.Only_Agency_Open_Opp_Count__c = AccountId2onlyAgencyOppOpenCount.get(accId);
                    }else{
                        acc.Only_Agency_Open_Opp_Count__c = 0;
                    }
                    if(AccountId2onlyAgencyOppWonAndOpenCount.containsKey(accId)){
                        acc.Only_Agency_Open_and_Won_Opp_Count__c = AccountId2onlyAgencyOppWonAndOpenCount.get(accId);    
                    }else{
                        acc.Only_Agency_Open_and_Won_Opp_Count__c = 0;
                    }
                    accList.add(acc);
                }
                update accList;
            }catch(Exception ex){
                HandleCustomException.LogException(ex);  
                system.debug(ex);
            } 
        }
    }
    public static void grossToNetCalculationsAfterUpdate(List<Opportunity> newOppList,Map<Id,Opportunity> oldMap){
        system.debug('grossToNetCalculationsAfterUpdate');
        try{
            Decimal currencyConversionNumber;
            Id AdvertisingRecordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Advertising').getRecordTypeId();
            Map<Id,Decimal> oppId2totalCoreAmount = new Map<Id,Decimal>();
            Map<Id,Decimal> oppId2totalInGameAmount = new Map<Id,Decimal>();
            Map<Id,Decimal> oppId2totalInVideoAmount = new Map<Id,Decimal>();
            List<Opportunity> oppList = new List<Opportunity>();
            for(Opportunity opp: newOppList){
                if(opp.RecordTypeId==AdvertisingRecordTypeID &&(opp.Amount!=oldMap.get(opp.Id).Amount || opp.Type_of_Agreement__c!=oldMap.get(opp.Id).Type_of_Agreement__c || (opp.Is_Bulk_Update_Gross_to_Net__c!=oldMap.get(opp.Id).Is_Bulk_Update_Gross_to_Net__c && opp.Is_Bulk_Update_Gross_to_Net__c))){
                    oppList.add(Opp);
                }
            }
            if(oppList.size()>0){
                List<AggregateResult> totalCoreOrderedAmount = [SELECT SUM(TotalPrice)sum,OpportunityId FROM OpportunityLineItem WHERE PricebookEntry.Product2.Product_Category__c='Core Media' AND OpportunityId IN :oppList GROUP BY OpportunityId];
                List<AggregateResult> totalInGameOrderedAmount = [SELECT SUM(TotalPrice)sum,OpportunityId FROM OpportunityLineItem WHERE PricebookEntry.Product2.Product_Category__c='New Product' AND PricebookEntry.Product2.Product_Sub_category__c='In-Game' AND OpportunityId IN :oppList GROUP BY OpportunityId];
                List<AggregateResult> totalInVideoOrderedAmount = [SELECT SUM(TotalPrice)sum,OpportunityId FROM OpportunityLineItem WHERE PricebookEntry.Product2.Product_Category__c='New Product' AND PricebookEntry.Product2.Product_Sub_category__c='In-Video' AND OpportunityId IN :oppList GROUP BY OpportunityId];
                for(AggregateResult ar: totalCoreOrderedAmount){
                    oppId2totalCoreAmount.put((ID)ar.get('OpportunityId'),(Decimal)ar.get('sum'));
                }
                for(AggregateResult ar: totalInGameOrderedAmount){
                    oppId2totalInGameAmount.put((ID)ar.get('OpportunityId'),(Decimal)ar.get('sum'));
                }
                for(AggregateResult ar: totalInVideoOrderedAmount){
                    oppId2totalInVideoAmount.put((ID)ar.get('OpportunityId'),(Decimal)ar.get('sum'));
                }
                
                for(Opportunity opp: oppList){
                    
                    if(oppId2totalCoreAmount.containsKey(opp.Id)){
                        opp.Total_Core_Ordered_Amount__c=oppId2totalCoreAmount.get(opp.Id);
                        
                    }else{
                        opp.Total_Core_Ordered_Amount__c=0;
                    }
                    if(oppId2totalInGameAmount.containsKey(opp.Id)){
                        opp.Total_In_Game_Ordered_Amount__c=oppId2totalInGameAmount.get(opp.Id);
                        
                    }else{
                        opp.Total_In_Game_Ordered_Amount__c=0;
                    }
                    if(oppId2totalInVideoAmount.containsKey(opp.Id)){
                        opp.Total_In_Video_Ordered_Amount__c=oppId2totalInVideoAmount.get(opp.Id);
                        
                    }else{
                        opp.Total_In_Video_Ordered_Amount__c=0;
                    }
                    if(opp.Amount>0){
                        currencyConversionNumber = (opp.Total_Core_Ordered_Amount__c+opp.Total_In_Game_Ordered_Amount__c+opp.Total_In_Video_Ordered_Amount__c)/(opp.Amount);
                        if(currencyConversionNumber>0){
                            opp.Total_Core_Ordered_Amount__c = (opp.Total_Core_Ordered_Amount__c)/(currencyConversionNumber);
                            opp.Total_In_Game_Ordered_Amount__c = (opp.Total_In_Game_Ordered_Amount__c)/(currencyConversionNumber);
                            opp.Total_In_Video_Ordered_Amount__c = (opp.Total_In_Video_Ordered_Amount__c)/(currencyConversionNumber); 
                        }  
                    }
                }
                netOppCalculations(oppList);
            }
        }catch(exception ex){
            HandleCustomException.LogException(ex);  
            system.debug(ex);
        }
    }
    public static void netOppCalculations(List<Opportunity> oppList){
        Final Decimal barterYcore = Gross_to_Net_Opportunity__mdt.getInstance('default').Barter_Y_Core__c;
        Final Decimal barterYInGame = Gross_to_Net_Opportunity__mdt.getInstance('default').Barter_Y_In_Game__c;
        Final Decimal barterYInVideo = Gross_to_Net_Opportunity__mdt.getInstance('default').Barter_Y_In_Video__c;
        Final Decimal barterNcore = Gross_to_Net_Opportunity__mdt.getInstance('default').Barter_N_Core__c;
        Final Decimal barterNInGame = Gross_to_Net_Opportunity__mdt.getInstance('default').Barter_N_In_Game__c;
        Final Decimal barterNInVideo = Gross_to_Net_Opportunity__mdt.getInstance('default').Barter_N_In_Video__c;
        
        for(Opportunity opp : oppList){
            if(opp.Type_of_Agreement__c == 'Gross'){  
                opp.Net_Total_Core_Ordered_Amount__c = opp.Total_Core_Ordered_Amount__c*barterYcore;
                opp.Net_Total_In_Game_Ordered_Amount__c= opp.Total_In_Game_Ordered_Amount__c*barterYInGame;  
                opp.Net_Total_In_Video_Ordered_Amount__c = opp.Total_In_Video_Ordered_Amount__c*barterYInVideo;             
            }else{
                opp.Net_Total_Core_Ordered_Amount__c = opp.Total_Core_Ordered_Amount__c*barterNcore;
                opp.Net_Total_In_Game_Ordered_Amount__c= opp.Total_In_Game_Ordered_Amount__c*barterNInGame;
                opp.Net_Total_In_Video_Ordered_Amount__c = opp.Total_In_Video_Ordered_Amount__c*barterNInVideo;
            }
            opp.Net_Total_Ordered_Amount__c=opp.Net_Total_Core_Ordered_Amount__c+opp.Net_Total_In_Game_Ordered_Amount__c+opp.Net_Total_In_Video_Ordered_Amount__c;
        }
    }
 
    public static void updateNetTotalOrderedAMountAfterUpdate(List<Opportunity> newOppList,Map<Id,Opportunity> oldMap){
        try{
            Set<Id> oppIds = new Set<Id>();
            Map<Id,Decimal> oppId2NetTotalOrderedAmount = new Map<Id,Decimal>();
            for(Opportunity opp: newOppList){
                if(opp.Agency_Discount__c!=oldMap.get(opp.Id).Agency_Discount__c || opp.Barter_Trading_Discount__c!=oldMap.get(opp.Id).Barter_Trading_Discount__c){
                    oppIds.add(opp.Id);
                }  
            }
            if(oppIds.size()>0){
                
                List<OpportunityLineItem> oliList = [SELECT Id,OpportunityId,Net_Total_Price__c FROM OpportunityLineItem WHERE OpportunityId in :oppIds];
                List<Opportunity> oppList = new List<Opportunity>();
                for(OpportunityLineItem oli: oliList){
                    if(oppId2NetTotalOrderedAmount.containsKey(oli.OpportunityId)){
                        
                        oppId2NetTotalOrderedAmount.put(oli.OpportunityId,(oppId2NetTotalOrderedAmount.get(oli.OpportunityId)) + (oli.Net_Total_Price__c??0));
                    }else{
                        
                        oppId2NetTotalOrderedAmount.put(oli.OpportunityId,oli.Net_Total_Price__c??0);
                    }
                }
                
                for(ID oppId: oppId2NetTotalOrderedAmount.keySet()){
                    if(oppId2NetTotalOrderedAmount.containsKey(oppId)){
                        Opportunity opp = new Opportunity();
                        opp.ID = oppId;
                        opp.Net_Total_Ordered_Amount_1__c = oppId2NetTotalOrderedAmount.get(oppId);
                        oppList.add(opp);
                    }
                }
                update oppList;
            }
            
        }catch(Exception ex){
            HandleCustomException.LogException(ex);  
            system.debug(ex);
        }
    }
    
    public static void recalculateProductOnVerityDemandVoicedBudgetUpdate(List<Opportunity> newOppList,Map<Id,Opportunity> oldMap){
        
            List<Opportunity> verityDemandOppList = new List<Opportunity>();
            for(Opportunity opp: newOppList){
                //Checking if Voiced Budget is changed for Verity - Demand
                if(opp.Voiced_Budget__c!=oldMap.get(opp.Id).Voiced_Budget__c && opp.RecordTypeId==Label.Verity_Demand_RecordTypeId){
                    verityDemandOppList.add(opp);
                }
            }
            if(!verityDemandOppList.isEmpty()){
                List<OpportunityLineItem> oliList = [SELECT ID,Start_Date__c,End_Date__c,Quantity,Unit_Price__c,Pricing__c,
                                                     PricebookEntryId,of_Budget__c,Opportunity.Voiced_Budget__c FROM opportunityLineItem WHERE OpportunityID in :verityDemandOppList];
                if(!oliList.isEmpty()){
                    Set<Id> priceBookEntryIds = new Set<Id>();
                    Map<Id,Decimal> priceBookEntryId2VerityRevenueMap = new Map<Id,Decimal>();
                    Map<Id,Decimal> oliId2TotalPriceMap = new Map<Id,Decimal>();
                    Map<String,Decimal> oliIdScheduleDate2ActualRevenueMap = new map<String,Decimal>();
                    List<OpportunityLineItemSchedule> olisList = [SELECT ID,OpportunityLineItemId,Actual_Revenue_Verity__c,
                                                                  Revenue,
                                                                  ScheduleDate FROM OpportunityLineItemSchedule WHERE
                                                                  OpportunityLineItemId in :oliList];
                    for(OpportunityLineItemSchedule olis: olisList){
                        if(olis.Actual_Revenue_Verity__c!=null && olis.ScheduleDate!=null){
                            oliIdScheduleDate2ActualRevenueMap.put(String.valueOf(olis.OpportunityLineItemId)+String.ValueOf(olis.ScheduleDate),olis.Actual_Revenue_Verity__c);
                        }
                    }
                    for(OpportunityLineItem oli:oliList){
                        priceBookEntryIds.add(oli.PricebookEntryId);
                    }
                    List<PricebookEntry> priceBookEntryList = [SELECT Id,Name,Product2.Verity_Revenue__c from PricebookEntry where Id in :priceBookEntryIds];
                    for(PricebookEntry pb: priceBookEntryList){
                        priceBookEntryId2VerityRevenueMap.put(pb.Id,pb.Product2.Verity_Revenue__c);
                    }
                    for(OpportunityLineItem oli: oliList){
                        if(priceBookEntryId2VerityRevenueMap.containsKey(oli.PricebookEntryId) && oli.Opportunity.Voiced_Budget__c!=null && oli.of_Budget__c!=null){
                            oliId2TotalPriceMap.put(oli.Id,priceBookEntryId2VerityRevenueMap.get(oli.PricebookEntryId)*oli.Opportunity.Voiced_Budget__c*oli.of_Budget__c/10000);  
                        } 
                    }
                    delete olisList;
                    establishSchedule(oliList,oliId2TotalPriceMap,oliIdScheduleDate2ActualRevenueMap);
                    
                    //update Unit_Price__c on Opportunity Product
                    List<OpportunityLineItem> oliListToUpdate = new List<OpportunityLineItem>();
                    for(OpportunityLineItem oppLineItem: oliList){ 
                        if(oliId2TotalPriceMap.containsKey(oppLineItem.Id)){
                            OpportunityLineItem oli = new OpportunityLineItem();
                            oli.Id = oppLineItem.Id;
                            if (oppLineItem.Pricing__c == 'VCPM' || oppLineItem.Pricing__c == 'CPM') {
                                oli.Unit_Price__c = oliId2TotalPriceMap.get(oppLineItem.Id)/(oppLineItem.Quantity / 1000);
                            } else {
                                oli.Unit_Price__c = oliId2TotalPriceMap.get(oppLineItem.Id)/oppLineItem.Quantity; 
                            }
                            oliListToUpdate.add(oli);
                        }  
                    }
                    if(!oliListToUpdate.isEmpty()){
                        update oliListToUpdate;
                    }
                }
            }
    } 
 
    public static void establishSchedule(List<OpportunityLineItem> oliList,Map<Id,Decimal> oliId2TotalPriceMap,Map<String,Decimal> oliIdScheduleDate2ActualRevenueMap){
        List<OpportunityLineItemSchedule> listOlis = new List<OpportunityLineItemSchedule>();
        for(OpportunityLineItem oli : oliList){
            Date startDate = oli.Start_Date__c;
            Date endDate = oli.End_Date__c;
            Integer totalMonths = startDate.monthsBetween(endDate) + 1;
            Integer totalDays = startDate.daysBetween(endDate) + 1;
            Double dailyAmountQuantity = oli.Quantity / totalDays;
            //Double dailyAmountRevenue = oli.TotalPrice / totalDays;
            Double dailyAmountRevenue = oliId2TotalPriceMap.get(oli.Id) / totalDays;
            Date endOfMonth = startDate.addMonths(1);
            endOfMonth = endOfMonth.toStartOfMonth();
            endOfMonth = endOfMonth.addDays(-1);
            Decimal runningTotalQuantity = 0;
            Decimal runningTotalRevenue = 0;
            for (Integer i = 1; i <= totalMonths; i++) {
                Integer numDaysInMonth;
                if (i == 1) {
                    numDaysInMonth = startDate.daysBetween(endOfMonth) + 1;
                } else {
                    Date firstDayOfMonth = endOfMonth.toStartOfMonth();
                    if (i == totalMonths) {
                        numDaysInMonth = firstDayOfMonth.daysBetween(endDate) + 1;
                    } else {
                        numDaysInMonth = firstDayOfMonth.daysBetween(endOfMonth) + 1;
                    }
                }
                Decimal scheduleQuantity = dailyAmountQuantity * numDaysInMonth;
                Decimal scheduleQuantityRounded = scheduleQuantity.setScale(0, RoundingMode.DOWN);
                runningTotalQuantity += scheduleQuantityRounded;
                Decimal scheduleRevenue = dailyAmountRevenue * numDaysInMonth;
                Decimal scheduleRevenueRounded = scheduleRevenue.setScale(2, RoundingMode.DOWN);
                runningTotalRevenue += scheduleRevenueRounded;
                if (i == totalMonths) {
                    Decimal leftOverQuantity = oli.Quantity - runningTotalQuantity;
                    scheduleQuantityRounded += leftOverQuantity;
                    //Decimal leftOverRevenue = oli.TotalPrice - runningTotalRevenue;
                    Decimal leftOverRevenue = oliId2TotalPriceMap.get(oli.Id) - runningTotalRevenue;
                    scheduleRevenueRounded += leftOverRevenue;
                }
                Integer scheduleQuantityInteger = scheduleQuantityRounded.intValue();
                OpportunityLineItemSchedule olis = new OpportunityLineItemSchedule();
                olis.Type = 'Both';
                olis.OpportunityLineItemId = oli.Id;
                olis.ScheduleDate = endOfMonth;
                olis.Quantity = scheduleQuantityInteger;
                olis.Revenue = scheduleRevenueRounded;
                olis.Verity_Revenue__c = scheduleRevenueRounded;
                if(oliIdScheduleDate2ActualRevenueMap.containsKey(String.ValueOf(oli.Id)+String.ValueOf(olis.ScheduleDate))){
                    olis.Actual_Revenue_Verity__c = oliIdScheduleDate2ActualRevenueMap.get(String.ValueOf(oli.Id)+String.ValueOf(olis.ScheduleDate));
                }
                listOlis.add(olis);
                endOfMonth = endOfMonth.addMonths(2);
                endOfMonth = endOfMonth.toStartOfMonth();
                endOfMonth = endOfMonth.addDays(-1);
            }
        }
        if(!listOlis.isEmpty()){
            insert(listOlis);
        }          
    }
}