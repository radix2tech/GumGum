/* Test Class for CalculateOLIQuantityCtrl
* RA, 03/07/2020
*/
@isTest
public class OLIManagerCtlrTest{
    static testMethod void testMethod1() {
        Account testAcc = new Account(name = 'TestAcc');
        insert testAcc;
        Id pricebookId = Test.getStandardPricebookId();
        
        Product2 prd1 = new Product2 (Name='Test Product Entry 1',Description='Test Product Entry 1',productCode = 'ABC', isActive = true);
        insert prd1;
        
        PricebookEntry pbe1 = new PricebookEntry (Product2ID=prd1.id,Pricebook2ID=pricebookId,UnitPrice=50, isActive=true);
        insert pbe1;
        
        Opportunity opp = new Opportunity(AccountId= testAcc.id,Agency_Name__c=testAcc.id,Start_Date__c = System.Today(),End_Date__c =System.Today()+ 100 ,name = 'Test Opp',CloseDate= System.Today()+ 3 ,Pricebook2Id = pbe1.Pricebook2Id, StageName ='Initial call' );
        insert opp;
        
        OpportunityLineItem opl1 = new OpportunityLineItem(OpportunityId= opp.id,Start_Date__c =  System.Today()-20,End_Date__c =System.Today()+ 10,PriceBookEntryID=pbe1.id,Quantity=1,TotalPrice= 50 ) ;
        OpportunityLineItem opl2 = new OpportunityLineItem(OpportunityId= opp.id,Start_Date__c =  System.Today(),End_Date__c =System.Today()+ 10,PriceBookEntryID=pbe1.id,Quantity=1,TotalPrice= 50 ) ;
        
        List<OpportunityLineItem > listOppLineItem = new List<OpportunityLineItem >();
        listOppLineItem.add(opl1);
        listOppLineItem.add(opl2 );
        Test.startTest();
        insert(listOppLineItem);
        Test.stopTest();
        OLIManagerCtlr ctrl = new OLIManagerCtlr();
        ctrl.opportunityId = opp.Id;
        ctrl.getoppLines();
        
        System.assertNotEquals(listOppLineItem.size(), 0);
    }
}