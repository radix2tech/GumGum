@isTest
public class OpportunityTriggerHandlerNewTest3 {
    @isTest
    static void method1(){
        Trigger_Setting__c tsOppConRole = new Trigger_Setting__c();
        tsOppConRole.Object_Name__c   = 'OpportunityContactRole';
        tsOppConRole.After_Insert__c = true;
        tsOppConRole.After_Update__c = true;
        tsOppConRole.Before_Delete__c = true;
        tsOppConRole.Prevent_Recursion__c = 'isPrimary';
        tsOppConRole.Name             = 'Opportunity Contact Role';
        insert tsOppConRole;
        
        Trigger_Setting__c tsOppLineItem = new Trigger_Setting__c();
        tsOppLineItem.Object_Name__c   = 'OpportunityLineItem';
        tsOppLineItem.After_Insert__c = true;
        tsOppLineItem.After_Update__c = true;
        tsOppLineItem.After_Delete__c = true;
        tsOppLineItem.Name             = 'OpportunityLineItem'; 
        insert tsOppLineItem;
        
        Account testAcc = new Account(name = 'TestAcc');
        insert testAcc;
        
        Id RecordTypeIdOpp = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Verity - Demand').getRecordTypeId();
        
        Id pricebookId = Test.getStandardPricebookId();
        
        Product2 prd1 = new Product2 (Name='test product 1',Verity_Revenue__c=5,Description='Test Product Entry 1',productCode = 'ABC', isActive = true,CanUseQuantitySchedule =true,CanUseRevenueSchedule=true);
        insert prd1;
        
        PricebookEntry pbe1 = new PricebookEntry (Product2ID=prd1.id,Pricebook2ID=pricebookId,UnitPrice=50, isActive=true);
        insert pbe1;
        
        Opportunity opp = new Opportunity(AccountId= testAcc.id,
                                          Agency_Name__c=testAcc.id,
                                          Start_Date__c = System.Today(),End_Date__c =System.Today()+ 100,
                                          name = 'Test Opp',CloseDate= System.Today()+ 3,Voiced_Budget__c =100, 
                                          Pricebook2Id = pbe1.Pricebook2Id,RecordTypeId = RecordTypeIdOpp, StageName ='Opportunity Identified');
        insert opp;
        system.debug(opp);
        
        opportunity getOpp = [SELECT ID,pricebook2Id from opportunity where Id = :opp.Id];
        getOpp.Pricebook2Id = pricebookId;
        update getOpp;
        
        Date startDate = Date.newInstance(2024, 03, 01);
        Date endDate = Date.newInstance(2024, 04, 30);
        
        OpportunityLineItem opl1 = new OpportunityLineItem(OpportunityId= opp.id,Start_Date__c = startDate,End_Date__c =endDate,PriceBookEntryID=pbe1.id,Quantity=1,TotalPrice= 50,of_Budget__c=100 ) ;
        insert opl1;
        
        List<OpportunityLineItemSchedule> oliScheList = new List<OpportunityLineItemSchedule>();
        
        OpportunityLineItemSchedule oliSched = new OpportunityLineItemSchedule(
            OpportunityLineItemId = opl1.Id,
            Type = 'Both',
            Quantity = 2,
            Revenue = 200,Verity_Revenue__c = 10,Actual_Revenue_Verity__c = 100,
            ScheduleDate = Date.newInstance(2024, 03, 31)
        );
        oliScheList.add(oliSched);
        OpportunityLineItemSchedule oliSched2 = new OpportunityLineItemSchedule(
            OpportunityLineItemId = opl1.Id,
            Type = 'Both',
            Quantity = 2,
            Revenue = 200,Verity_Revenue__c = 10,Actual_Revenue_Verity__c = 100,
            ScheduleDate = Date.newInstance(2024, 04, 30)
        );
        oliScheList.add(oliSched2);
        insert oliScheList;
        
        Test.startTest();
        opp.Voiced_Budget__c = 200;
        update opp;
        Test.stopTest();   
    }
    
}