@isTest
public class LineItemScheduleTriggerHandlerTest {
    
    @istest
    private static void testMethod1() {
        Trigger_Setting__c tsOppLineItem = new Trigger_Setting__c();
        tsOppLineItem.Object_Name__c   = 'OpportunityLineItem';
        tsOppLineItem.After_Insert__c = true;
        tsOppLineItem.After_Update__c = true;
        tsOppLineItem.After_Delete__c = true;
        tsOppLineItem.Name             = 'OpportunityLineItem';
        insert tsOppLineItem;
        
        Account testAcc = new Account(name = 'TestAcc');
        insert testAcc;
        
        Id pricebookId = Test.getStandardPricebookId();
        Id RecordTypeIdOpp = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Verity - Demand').getRecordTypeId();
        
        Product2 prd1 = new Product2 (Name='Video Solution - OLV',Verity_Revenue__c=5,Description='Test Product Entry 1',productCode = 'ABC', isActive = true,CanUseQuantitySchedule =true,CanUseRevenueSchedule=true);
        insert prd1;
        
        PricebookEntry pbe1 = new PricebookEntry (Product2ID=prd1.id,Pricebook2ID=pricebookId,UnitPrice=50, isActive=true);
        insert pbe1;
        
        Opportunity opp = new Opportunity(AccountId= testAcc.id,RecordTypeId=RecordTypeIdOpp,Agency_Name__c=testAcc.id,Start_Date__c = System.Today(),End_Date__c =System.Today()+ 100 ,name = 'Test Opp',CloseDate= System.Today()+ 3 ,Pricebook2Id = pbe1.Pricebook2Id, StageName ='Opportunity Identified' );
        insert opp;
        
        opportunity getOpp = [SELECT ID,pricebook2Id from opportunity where Id = :opp.Id];
        getOpp.Pricebook2Id = pricebookId;
        update getOpp;
        
        system.debug('oppPricebookId'+ [SELECT ID,pricebook2Id from opportunity where Id = :opp.Id].pricebook2Id);
        system.debug('Std PricebookId' + pricebookId);
        
        OpportunityLineItem opl1 = new OpportunityLineItem(OpportunityId= opp.id,
                                                           Start_Date__c =  System.Today()-20,End_Date__c =System.Today()+ 10,PriceBookEntryID=pbe1.id,Quantity=1,TotalPrice= 50,of_Budget__c=100 ) ;
		insert opl1;
        
        OpportunityLineItemSchedule oliSched = new OpportunityLineItemSchedule(
            OpportunityLineItemId = opl1.Id,
            Type = 'Both',
            Quantity = 2,
            Revenue = 200,Verity_Revenue__c = 10,Actual_Revenue_Verity__c = 100,
            ScheduleDate = Date.today()
        );
        
        insert oliSched;
        
        oliSched.Verity_Revenue__c = 90;
        oliSched.Actual_Revenue_Verity__c = 200;
        update oliSched;
        opp.Voiced_Budget__c = 200;
        update opp;

    }
    
}