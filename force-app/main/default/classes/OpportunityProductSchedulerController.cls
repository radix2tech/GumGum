/*
Description  : OpportunityProductSchedulerController called from Update Multiple Product Start and End Date Flow to update Line Item Schedules.  
Created Date : 01-03-2023
Created By   : Kiran
Change Request : CR#1 Date: 15/11/2024
				 Description: Changes made to handle the update of the Opportunity Products with Verity Actual Revenue
*/
public class OpportunityProductSchedulerController {
    
    @InvocableMethod(label = 'Create Schedules for Opportunity Product')
    public static List<ReturnVariables> createSchedules(List<InputVariables> inputVariables){
        return saveProductInternal(inputVariables.get(0).oppLineItem);
    }
    public class InputVariables{
        @InvocableVariable
        public List<OpportunityLineItem> oppLineItem;   
    }
    public class ReturnVariables{
        @InvocableVariable
        public List<OpportunityLineItem> oppLineItemDisplay;
        @InvocableVariable
        public List<OpportunityLineItem> errorOppLineItemsDisplay;
        @InvocableVariable
        public List<String> errorMessageFromAPex;
    } 
    
    //To create schedules for Opportunity Products without actual verity revenue
    public static void establishSchedule(List<OpportunityLineItem> oliList){
        List<OpportunityLineItemSchedule> listOlis = new List<OpportunityLineItemSchedule>();
        for(OpportunityLineItem oli : oliList){
            Date startDate = oli.Start_Date__c;
            Date endDate = oli.End_Date__c;
            Integer totalMonths = startDate.monthsBetween(endDate) + 1;
            Integer totalDays = startDate.daysBetween(endDate) + 1;
            Double dailyAmountQuantity = oli.Quantity / totalDays;
            Double dailyAmountRevenue = oli.TotalPrice / totalDays;
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
                    Decimal leftOverRevenue = oli.TotalPrice - runningTotalRevenue;
                    scheduleRevenueRounded += leftOverRevenue;
                }
                Integer scheduleQuantityInteger = scheduleQuantityRounded.intValue();
                OpportunityLineItemSchedule olis = new OpportunityLineItemSchedule();
                olis.Type = 'Both';
                olis.OpportunityLineItemId = oli.Id;
                olis.ScheduleDate = endOfMonth;
                olis.Quantity = scheduleQuantityInteger;
                olis.Revenue = scheduleRevenueRounded;
                if((oli.Opportunity.RecordType.Name=='Advertising') && (oli.Product_Name_Text__c == 'Video Solution - CTV' || oli.Product_Name_Text__c == 'Video Solution - OLV')){
                    olis.Verity_Revenue__c = scheduleRevenueRounded*0.04;  
                }else if(oli.Opportunity.RecordType.Name=='Verity - Demand'){
                    olis.Verity_Revenue__c = scheduleRevenueRounded;
                }
                listOlis.add(olis);
                endOfMonth = endOfMonth.addMonths(2);
                endOfMonth = endOfMonth.toStartOfMonth();
                endOfMonth = endOfMonth.addDays(-1);
            }
        }
        insert(listOlis);     
    }
    
    //To create schedules for Opportunity Products that has the Verity Actuals
    public static void establishSchedule(List<OpportunityLineItem>oliList,List<OpportunityLineItemSchedule> actualOlis) {
        
        Map<String,Double> lineItemIdscheduleDate2ActualRevenueMap = new Map<String,Double>();
        for(OpportunityLineItemSchedule olis: actualOlis){
            lineItemIdscheduleDate2ActualRevenueMap.put(olis.OpportunityLineItemId + String.ValueOf(olis.ScheduleDate),olis.Actual_Revenue_Verity__c);
        }
        
        List<OpportunityLineItemSchedule> listOlis = new List<OpportunityLineItemSchedule>();
        for(OpportunityLineItem oli : oliList){
            Date startDate = oli.Start_Date__c;
            Date endDate = oli.End_Date__c;
            Integer totalMonths = startDate.monthsBetween(endDate) + 1;
            Integer totalDays = startDate.daysBetween(endDate) + 1;
            Double dailyAmountQuantity = oli.Quantity / totalDays;
            Double dailyAmountRevenue = oli.TotalPrice / totalDays;
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
                    Decimal leftOverRevenue = oli.TotalPrice - runningTotalRevenue;
                    scheduleRevenueRounded += leftOverRevenue;
                }
                Integer scheduleQuantityInteger = scheduleQuantityRounded.intValue();
                OpportunityLineItemSchedule olis = new OpportunityLineItemSchedule();
                olis.Type = 'Both';
                olis.OpportunityLineItemId = oli.Id;
                olis.ScheduleDate = endOfMonth;
                olis.Quantity = scheduleQuantityInteger;
                olis.Revenue = scheduleRevenueRounded;
                if((oli.Opportunity.RecordType.Name=='Advertising') && (oli.Product_Name_Text__c == 'Video Solution - CTV' || oli.Product_Name_Text__c == 'Video Solution - OLV')){
                    olis.Verity_Revenue__c = scheduleRevenueRounded*0.04;  
                }else if(oli.Opportunity.RecordType.Name=='Verity - Demand'){
                    olis.Verity_Revenue__c = scheduleRevenueRounded;
                }
                if(lineItemIdscheduleDate2ActualRevenueMap.containsKey(olis.OpportunityLineItemId + String.ValueOf(olis.ScheduleDate))){
                    olis.Actual_Revenue_Verity__c = lineItemIdscheduleDate2ActualRevenueMap.get(olis.OpportunityLineItemId + String.ValueOf(olis.ScheduleDate));
                }
                system.debug(olis);
                listOlis.add(olis);
                endOfMonth = endOfMonth.addMonths(2);
                endOfMonth = endOfMonth.toStartOfMonth();
                endOfMonth = endOfMonth.addDays(-1);
            }
        }
        insert(listOlis);     
    }
    
    public static List<ReturnVariables> saveProductInternal(List<OpportunityLineItem> oppProdList){
        Savepoint sp = Database.setSavepoint();
        try{
            List<ReturnVariables> returnVarList = new List<ReturnVariables>();
            ReturnVariables returnVars = new ReturnVariables();
            List<String> errorMessageList = new List<String>(); 
            Set<Id> successOldOliIds = new Set<Id>();
            Set<Id> errorOldOliIds = new Set<Id>();
            Set<Id> allOldOliIds = new Set<Id>();
            Set<Id> successNewOliIds = new Set<Id>();
            //List<OpportunityLineItem> OppProdListToInsert = new List<OpportunityLineItem>();
            List<OpportunityLineItem> oliForActualSchedulesList = new List<OpportunityLineItem>();
            for(OpportunityLineItem oli : oppProdList){
                allOldOliIds.add(oli.Id);
            }
            
            //updating the start and end date of olis that were set from the flow
            Database.saveResult[] oliSaveResult = Database.update(oppProdList,false);
            for (Database.SaveResult sr : oliSaveResult) {
                if (sr.isSuccess()){
                    successNewOliIds.add(sr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());      
                        errorMessageList.add(err.getMessage());
                    }
                }
            }
            
            oppProdList=[SELECT ID, TotalPrice,Total_Price_Custom__c, Start_Date__c, End_Date__c, Quantity, Incremental_New__c, Lightbox__c,
                         Custom_Creative__c,Extended_Animation__c,UnitPrice,Unit_Price__c,
                         Product_Name_Text__c,Start_Date_Text__c,Description,Verity_Revenue__c,Verity_Deal_ID__c,
                         End_Date_Text__c,Has_Actual_Verity_Amount__c,Opportunity.RecordType.Name FROM OpportunityLineItem WHERE Id in :successNewOliIds];
            
            //checking if the opp product has actuals
            for(OpportunityLineItem oli: oppProdList){
                if(oli.Has_Actual_Verity_Amount__c){
                    oliForActualSchedulesList.add(oli);
                    break;
                }
            }
            
            //deleting all the schedules for the selected olis
            List<OpportunityLineItemSchedule> olisList = [SELECT Id,OpportunityLineItemId,Actual_Revenue_Verity__c,ScheduleDate from OpportunityLineItemSchedule WHERE OpportunityLineItemId in :successNewOliIds];
            delete olisList;
            
            //checking for the actuals and creating schedules accordingly
            if(!oliForActualSchedulesList.isEmpty()){
                establishSchedule(oppProdList,olisList); 
            }else{
                establishSchedule(oppProdList);
            }
            
            //populating the error list to display in the flow screen if any
            if(successNewOliIds.size()!=allOldOliIds.size()){
                allOldOliIds.removeAll(successNewOliIds);
                errorOldOliIds.addAll(allOldOliIds);
                List<OpportunityLineItem> errorOppProdList = [SELECT ID, TotalPrice,Total_Price_Custom__c, Start_Date__c, End_Date__c, Quantity, Incremental_New__c, Lightbox__c,
                                                              Custom_Creative__c,Extended_Animation__c,UnitPrice,Unit_Price__c,
                                                              Product_Name_Text__c,Start_Date_Text__c,Description,Verity_Deal_ID__c,
                                                              End_Date_Text__c FROM OpportunityLineItem WHERE Id in :errorOldOliIds];
                returnVars.errorOppLineItemsDisplay = errorOppProdList;
            }
            if(errorMessageList.size()>0){
                returnVars.errorMessageFromAPex = errorMessageList;   
            }
            returnVars.oppLineItemDisplay = oppProdList;
            returnVarList.add(returnVars);
            
            /*for(OpportunityLineItem changeProduct : oppProdList){
                allOldOliIds.add(changeProduct.Id);
                OpportunityLineItem tempOp = New OpportunityLineItem();
                tempOp = changeProduct.clone(false, true, false, false);
                tempOp.UnitPrice=null;
                if(changeProduct.Product_Name_Text__c =='Video Solution - CTV' || changeProduct.Product_Name_Text__c =='Video Solution - OLV' ){
                    //Making Verity Revenue 4% of Total Price
                    tempOp.Verity_Revenue__c = changeProduct.Total_Price_Custom__c*0.04;
                }
                tempOp.tempOldId__c=changeProduct.Id;
                OppProdListToInsert.add(tempOp);
            }
            Database.saveResult[] oliSaveResult = Database.insert(OppProdListToInsert,false);
            for (Database.SaveResult sr : oliSaveResult) {
                if (sr.isSuccess()){
                    successNewOliIds.add(sr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());      
                        errorMessageList.add(err.getMessage());
                    }
                }
            }
            List<OpportunityLineItem> successOppLineItems = [SELECT ID,tempOldId__c,
                                                             Start_Date__c,End_Date__c,Quantity,TotalPrice,Product_Name_Text__c
                                                             FROM OpportunityLineItem WHERE Id in :successNewOliIds]; 
            for(OpportunityLineItem oli: successOppLineItems){
                successOldOliIds.add(oli.tempOldId__c);
            }
            Database.delete(new List<Id>(successOldOliIds));
            establishSchedule(successOppLineItems); 
            
            oppProdList=[SELECT ID, TotalPrice,Total_Price_Custom__c, Start_Date__c, End_Date__c, Quantity, Incremental_New__c, Lightbox__c,
                         Custom_Creative__c,Extended_Animation__c,UnitPrice,Unit_Price__c,
                         Product_Name_Text__c,Start_Date_Text__c,Description,Verity_Revenue__c,Verity_Deal_ID__c,
                         End_Date_Text__c FROM OpportunityLineItem WHERE Id in :successNewOliIds];
            
            if(successOldOliIds.size()!=allOldOliIds.size()){
                allOldOliIds.removeAll(successOldOliIds);
                errorOldOliIds.addAll(allOldOliIds);
                List<OpportunityLineItem> errorOppProdList = [SELECT ID, TotalPrice,Total_Price_Custom__c, Start_Date__c, End_Date__c, Quantity, Incremental_New__c, Lightbox__c,
                                                              Custom_Creative__c,Extended_Animation__c,UnitPrice,Unit_Price__c,
                                                              Product_Name_Text__c,Start_Date_Text__c,Description,Verity_Deal_ID__c,
                                                              End_Date_Text__c FROM OpportunityLineItem WHERE Id in :errorOldOliIds];
                returnVars.errorOppLineItemsDisplay = errorOppProdList;
            }
            if(errorMessageList.size()>0){
                returnVars.errorMessageFromAPex = errorMessageList;   
            }
            returnVars.oppLineItemDisplay = oppProdList;
            returnVarList.add(returnVars);*/
            
            return returnVarList;
        }catch(Exception e){
            Database.rollback(sp);
            Custom_Exception__c exceptionLog = new Custom_Exception__c();
            exceptionLog.Exception_Message__c = 'An error occurred saving record. ' + e.getMessage() + ' Line: ' + e.getLineNumber();
            exceptionLog.MethodName__c = 'OpportunityProductSchedulerController.saveProductInternal';
            insert exceptionLog;
            System.debug(e.getMessage());
            throw new SaveException('An error occurred saving record. ' + e.getMessage() + ' Line: ' + e.getLineNumber()); 
        }
    }
    
    public class SaveException extends Exception {}
}