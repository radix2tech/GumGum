@isTest
public class AccountForecastBatchTest {

    @testSetup
    static void setupData() {

        List<Trigger_Setting__c> TSList = new List<Trigger_Setting__c>();
        
        Trigger_Setting__c tsOppLineItem = new Trigger_Setting__c();
        tsOppLineItem.Object_Name__c   = 'OpportunityLineItem';
        tsOppLineItem.After_Insert__c = true;
        tsOppLineItem.After_Update__c = true;
        tsOppLineItem.After_Delete__c = true;
        tsOppLineItem.Name             = 'OpportunityLineItem';
        TSList.add(tsOppLineItem);
        
        // Insert Trigger Settings for OpportunityContactRole
        Trigger_Setting__c tsOppConRole = new Trigger_Setting__c();
        tsOppConRole.Object_Name__c   = 'OpportunityContactRole';
        tsOppConRole.After_Insert__c = false;
        tsOppConRole.After_Update__c = false;
        tsOppConRole.Before_Delete__c = false;
        tsOppConRole.Prevent_Recursion__c = 'isPrimary';
        tsOppConRole.Name             = 'Opportunity Contact Role';
        TSList.add(tsOppConRole);
        
        insert TSList;
        
        Account testAcc = new Account(Name = 'Test Advertiser');
        insert testAcc;

        // Create Advertiser-Agency Relationship
        Advertiser_Agency_Relationship__c aar = new Advertiser_Agency_Relationship__c(
            Advertiser__c = testAcc.Id
        );
        insert aar;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        Product2 prd1 = new Product2 (Name='Video Solution - OLV',Description='Test Product Entry 1',productCode = 'ABC', isActive = true,CanUseQuantitySchedule =true,CanUseRevenueSchedule=true);
        insert prd1;
        
        PricebookEntry pbe1 = new PricebookEntry (Product2ID=prd1.id,Pricebook2ID=pricebookId,UnitPrice=50, isActive=true);
        insert pbe1;
        
        Id ActivationRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Activation').getRecordTypeId();

        Opportunity opp = new Opportunity(AccountId= testAcc.id,RecordTypeId = ActivationRecordTypeId,Agency_Name__c=testAcc.id,Start_Date__c = System.Today(),End_Date__c =System.Today()+ 100 ,name = 'Test Opp',CloseDate= System.Today()+ 3 ,Pricebook2Id = pbe1.Pricebook2Id, StageName ='Closed/Won' );
        insert opp;
        
        opportunity getOpp = [SELECT ID,pricebook2Id from opportunity where Id = :opp.Id];
        getOpp.Pricebook2Id = pricebookId;
        update getOpp;
        
        OpportunityLineItem opl1 = new OpportunityLineItem(OpportunityId= opp.id,Start_Date__c =  System.Today()-20,End_Date__c =System.Today()+ 10,PriceBookEntryID=pbe1.id,Quantity=1,TotalPrice= 50 ) ;
		insert opl1;
        
        OpportunityLineItemSchedule oliSched = new OpportunityLineItemSchedule(
            OpportunityLineItemId = opl1.Id,
            Type = 'Both',
            Quantity = 2,
            Revenue = 200,Verity_Revenue__c = 10,
            ScheduleDate = Date.today()
        );
        insert oliSched;

        OpportunityLineItemSchedule oliSched3 = new OpportunityLineItemSchedule(
            OpportunityLineItemId = opl1.Id,
            Type = 'Both',
            Quantity = 2,
            Revenue = 200,Verity_Revenue__c = 10,
            ScheduleDate = Date.today().addYears(1)
        );
        insert oliSched3;

        OpportunityLineItemSchedule oliSched5 = new OpportunityLineItemSchedule(
            OpportunityLineItemId = opl1.Id,
            Type = 'Both',
            Quantity = 2,
            Revenue = 200,Verity_Revenue__c = 10,
            ScheduleDate = Date.today().addMonths(-2)
        );
        insert oliSched5;


        Opportunity opp1 = new Opportunity(AccountId= testAcc.id,RecordTypeId = ActivationRecordTypeId,Agency_Name__c=testAcc.id,Start_Date__c = System.Today(),End_Date__c =System.Today()+ 100 ,name = 'Test Opp1',CloseDate= System.Today()+ 3 ,Pricebook2Id = pbe1.Pricebook2Id, StageName ='Proposal' );
        insert opp1;
        
        opportunity getOpp1 = [SELECT ID,pricebook2Id from opportunity where Id = :opp1.Id];
        getOpp1.Pricebook2Id = pricebookId;
        update getOpp1;
        
        OpportunityLineItem opl2 = new OpportunityLineItem(OpportunityId= opp1.id,Start_Date__c =  System.Today()-20,End_Date__c =System.Today()+ 10,PriceBookEntryID=pbe1.id,Quantity=1,TotalPrice= 50 ) ;
		insert opl2;
        
        OpportunityLineItemSchedule oliSched2 = new OpportunityLineItemSchedule(
            OpportunityLineItemId = opl2.Id,
            Type = 'Both',
            Quantity = 2,
            Revenue = 200,Verity_Revenue__c = 10,
            ScheduleDate = Date.today()
        );
        insert oliSched2;

        OpportunityLineItemSchedule oliSched4 = new OpportunityLineItemSchedule(
            OpportunityLineItemId = opl2.Id,
            Type = 'Both',
            Quantity = 2,
            Revenue = 200,Verity_Revenue__c = 10,
            ScheduleDate = Date.today().addMonths(3)
        );
        insert oliSched4;

        
    }

    @IsTest
    static void testMethod1() {
        Test.startTest();
        
        String cronExp = '0 0 1 * * ?'; 
		AccountForecastBatch scheduler = new AccountForecastBatch();
		System.schedule('AccountForecastBatch_', cronExp, scheduler);
        
        Test.stopTest();

    }

}