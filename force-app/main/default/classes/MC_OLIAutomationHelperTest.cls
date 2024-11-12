/* Test Class for MC_OLIAutomationHelper
* RA, 07/16/2020
*/
@isTest
public class MC_OLIAutomationHelperTest {
    static testMethod void testOliAutomationHelper(){
        
        Account testAcc = new Account(name = 'TestAcc');
        insert testAcc;
        Id pricebookId = Test.getStandardPricebookId();
        
        Product2 prd1 = new Product2 (Name='Placeholder',CanUseQuantitySchedule = true,CanUseRevenueSchedule = true,Description='Test Product Entry 1',productCode = 'ABC', isActive = true);
        insert prd1;
        
        PricebookEntry pbe1 = new PricebookEntry (Product2ID=prd1.id,Pricebook2ID=pricebookId,UnitPrice=50, isActive=true);
        insert pbe1;
        
        Opportunity opp = new Opportunity(AccountId= testAcc.id,Agency_Name__c=testAcc.id,Start_Date__c = System.Today(),End_Date__c =System.Today()+ 10 ,name = 'Test Opp',CloseDate= System.Today()+ 3 ,Pricebook2Id = pbe1.Pricebook2Id, StageName ='Initial call' );
        insert opp;
       
        List<Opportunity> lstOpp = [select id,Agency_Name__c,Re_calculate_Products__c from Opportunity where id=:opp.Id];
        system.assertEquals(false, lstOpp[0].Re_calculate_Products__c, 'set opps recalculate flag to false');
        
        List<OpportunityLineItem > listOppLineItem = new List<OpportunityLineItem >();
        OpportunityLineItem opl1 = new OpportunityLineItem(OpportunityId=opp.id,
                                                           Start_Date__c =System.Today(),
                                                           End_Date__c =System.Today()+10,
                                                           PriceBookEntryID=pbe1.id,
                                                           Pricing__c ='VCPM',Quantity=1,Unit_Price__c =00 ,
                                                           Processing_Status__c ='New',TotalPrice=89);
        
        
        listOppLineItem.add(opl1);
        insert listOppLineItem;
        
        List<OpportunityLineItem > lstoli=[select OpportunityId,Processing_Status__c,Pricing__c,Unit_Price__c from OpportunityLineItem where id=:opl1.Id ];
        system.assertEquals('New',lstoli[0].Processing_Status__c , 'Proccessing Status is New');
        system.assertEquals('VCPM', lstoli[0].Pricing__c, 'Pricing is VCPM');
        
        Test.startTest();
        MC_OLIAutomationHelper.setOppToReprocess(new set<ID> {opp.Id});
        MC_OLIAutomationHelper.process(new set<ID> {opp.Id});
        MC_OLIAutomationHelper.establishSchedule(new List<OpportunityLineItem> {opl1});
        MC_OLIAutomationCtrl ctrl = new MC_OLIAutomationCtrl();
        ctrl.callAutomation();
        Test.stopTest();
        System.assertNotEquals(listOppLineItem.size(), 0);
    }
}