@isTest
public class OpportunityTriggerHandlerNewTest2 {
    @testSetup
    static void testData(){
        Trigger_Setting__c tsOppConRole = new Trigger_Setting__c();
        tsOppConRole.Object_Name__c   = 'OpportunityContactRole';
        tsOppConRole.After_Insert__c = true;
        tsOppConRole.After_Update__c = true;
        tsOppConRole.Before_Delete__c = true;
        tsOppConRole.Prevent_Recursion__c = 'isPrimary';
        tsOppConRole.Name             = 'Opportunity Contact Role';
        insert tsOppConRole;
        List<Account> accList = new List<Account>();
        for(Integer i=0;i<2;i++){
            Account acc = new Account();
            acc.Name = 'Test'+i;
            acc.Type = '3rd Party Supplier';
            acc.Account_Region__c = 'US - Central';
            acc.Industry = 'Automotive';
            accList.add(acc);
        }
        insert accList;
        List<Contact> conList = new List<Contact>();
        Contact con1 = new Contact(lastName='Test');
        Contact con2 = new Contact(lastName = 'Test2');
        conList.add(con1);
        conList.add(con2);
        insert conList;
        List<Opportunity> oppList = new List<Opportunity>();
        for(Account acc: accList){
            for(Integer i=0;i<10;i++){
                 Opportunity opp1 = new Opportunity(AccountId= acc.id,Agency_Name__c=acc.id,
                                           Start_Date__c = System.Today(),
                                           End_Date__c =System.Today()+ 100,
                                           name = acc.Name + 'i',
                                           CloseDate= System.Today()+ 3,
                                           SalesLoft1__Primary_Contact__c = conList[0].Id,
                                           Primary_KPI__c='Action Rate',
                                          // Why_GumGum__c='Attention',
                                           Amount=500,
                                           //Business_Objective__c = 'Acquire new customers',         
                                           StageName = (i==2?'Closed/Lost':'Initial call')); 
                oppList.add(opp1);
            }
        }
        insert oppList;
    }
    @isTest
    public static void method1(){
        List<Account> accList = [SELECT id,Only_Agency_Opp_Count__c FROM Account];
        system.assertEquals(10, accList[0].Only_Agency_Opp_Count__c);
        List<Opportunity> oppList = [SELECT Id,stageName,AccountId,Agency_Name__c FROM Opportunity WHERE Agency_Name__c = :accList[0].Id AND stageName='Initial call'];
        system.assertEquals(9, oppList.size());
        oppList[0].Agency_Name__c = accList[1].Id;
        oppList[1].stageName = 'Closed/Lost';
        oppList[1].Amount = 1000;
        update oppList;
        List<Account> accList2 = [SELECT Id,Only_Agency_Opp_Count__c,Only_Agency_Opp_Won_Count__c,Only_Agency_Open_Opp_Count__c,Only_Agency_Open_and_Won_Opp_Count__c FROM Account WHERE Id=:accList[0].Id OR Id = :accList[1].Id];
        system.assertEquals(9,accList2[0].Only_Agency_Opp_Count__c);
        system.assertEquals(7, accList2[0].Only_Agency_Open_Opp_Count__c);
        system.assertEquals(10, accList2[1].Only_Agency_Open_Opp_Count__c);
        system.assertEquals(11,accList2[1].Only_Agency_Opp_Count__c);
    }
    
     @isTest
    static void method2(){
        Trigger_Setting__c tsOppLineItem = new Trigger_Setting__c();
        tsOppLineItem.Object_Name__c   = 'OpportunityLineItem';
        tsOppLineItem.After_Insert__c = true;
        tsOppLineItem.After_Update__c = true;
        tsOppLineItem.After_Delete__c = true;
        tsOppLineItem.Name             = 'OpportunityLineItem'; 
        insert tsOppLineItem;
        
        Account testAcc = new Account(name = 'TestAcc');
        insert testAcc;
        
        Contact con2 = new Contact(lastName = 'Test2',AccountId=testAcc.ID);
        
        Id RecordTypeIdOpp = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Verity - Demand').getRecordTypeId();
        
        Id pricebookId = Test.getStandardPricebookId();
        
        Product2 prd1 = new Product2 (Name='test product 1',Verity_Revenue__c=5,Description='Test Product Entry 1',productCode = 'ABC', isActive = true,CanUseQuantitySchedule =true,CanUseRevenueSchedule=true);
        insert prd1;
        
        PricebookEntry pbe1 = new PricebookEntry (Product2ID=prd1.id,Pricebook2ID=pricebookId,UnitPrice=50, isActive=true);
        insert pbe1;
        
        Opportunity opp = new Opportunity(AccountId= testAcc.id,SalesLoft1__Primary_Contact__c = con2.Id,
                                          Agency_Name__c=testAcc.id,Start_Date__c = System.Today(),End_Date__c =System.Today()+ 100 ,name = 'Test Opp',CloseDate= System.Today()+ 3 ,Pricebook2Id = pbe1.Pricebook2Id,RecordTypeId = RecordTypeIdOpp, StageName ='Opportunity Identified' );
        insert opp;
        
        opportunity getOpp = [SELECT ID,pricebook2Id from opportunity where Id = :opp.Id];
        getOpp.Pricebook2Id = pricebookId;
        update getOpp;
        
        OpportunityLineItem opl1 = new OpportunityLineItem(OpportunityId= opp.id,Start_Date__c =  System.Today().toStartOfMonth(),End_Date__c =System.Today().toStartOfMonth().addMonths(1),PriceBookEntryID=pbe1.id,Quantity=1,TotalPrice= 50,of_Budget__c=100 ) ;
        insert opl1;
        
        system.debug('oppPricebookId'+ [SELECT ID,pricebook2Id from opportunity where Id = :opp.Id].pricebook2Id);
        system.debug('Std PricebookId' + pricebookId);
        
        List<OpportunityLineItemSchedule> oliScheList = new List<OpportunityLineItemSchedule>();
        
        OpportunityLineItemSchedule oliSched = new OpportunityLineItemSchedule(
            OpportunityLineItemId = opl1.Id,
            Type = 'Both',
            Quantity = 2,
            Revenue = 200,Verity_Revenue__c = 10,Actual_Revenue_Verity__c = 100,
            ScheduleDate = System.Today().toStartOfMonth().addMonths(1)-1
        );
        oliScheList.add(oliSched);
        OpportunityLineItemSchedule oliSched2 = new OpportunityLineItemSchedule(
            OpportunityLineItemId = opl1.Id,
            Type = 'Both',
            Quantity = 2,
            Revenue = 200,Verity_Revenue__c = 10,Actual_Revenue_Verity__c = 100,
            ScheduleDate = System.Today().toStartOfMonth().addMonths(2)-1
        );
        oliScheList.add(oliSched2);
        insert oliScheList;
        
        oliScheList[0].Verity_Revenue__c = 90;
        oliScheList[0].Actual_Revenue_Verity__c = 200;
        update oliScheList;
        Test.startTest();
        opp.Voiced_Budget__c = 200;
        update opp;
        Test.stopTest();   
    }

}