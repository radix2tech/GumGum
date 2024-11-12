@isTest
private class AddProductCustomControllerTest {

    private static Id prodId;
    private static String prodName;
    //private static Id pbId;
    private static Id pbeId;

    private static Opportunity opportunitySetup(Boolean includePricebook, String pbName) {
    
        Account acct = new Account(Name = 'Test Account');
        insert acct;
        
        Id RecordTypeIdOpp = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Advertising').getRecordTypeId();
        
        Opportunity opp = new Opportunity(
            Recordtypeid=RecordTypeIdOpp,
            Name = 'Test Opp',
            AccountId = acct.Id,
            Agency_Name__c = acct.Id,
            Type = 'Existing Business',
            ForecastCategoryName = 'Pipeline',
            CurrencyIsoCode = 'USD',
            Start_Date__c = Date.today().addDays(1),
            End_Date__c = Date.today().addDays(8),
            StageName = 'Closed/Won',
            CloseDate = Date.today());
            
        if (includePricebook) {
            Product2 p = new Product2(Name = 'Test Product');
            insert p;
            prodId = p.Id;
            prodName = p.Name;
            Id standardPbId = Test.getStandardPricebookId();
            PricebookEntry standardPbe = new PricebookEntry(
                Pricebook2Id = standardPbId,
                Product2Id = p.Id,
                UnitPrice = 5.00,
                IsActive = true);
            insert standardPbe;
            Pricebook2 pb = new Pricebook2(
                Name = pbName,
                IsActive = true);
            insert pb;
            //pbId = pb.Id;
            PricebookEntry pbe = new PricebookEntry(
                Pricebook2Id = pb.Id,
                Product2Id = p.Id,
                UnitPrice = 10.00,
                IsActive = true);
            insert pbe;
            pbeId = pbe.Id;
            opp.Pricebook2Id = pb.Id;
        }
        insert opp;
        return opp;
    }
    
    @isTest static void test_with_pricebook_selected() {
        //PageReference pageRef = Page.success;
        //Test.setCurrentPage(pageRef);

        Opportunity opp = opportunitySetup(true, 'Standard Price Book');
        AddProductCustomController apcCtrl = new AddProductCustomController(new ApexPages.StandardController(opp));

        //System.assertEquals(false, apcCtrl.selectPricebook);
        //System.assertEquals(apcCtrl.opp.Pricebook2Id, apcCtrl.pbId);

        apcCtrl.pricingOption = 'CPM';
        apcCtrl.productOption = pbeId;
        apcCtrl.strQuantForCpm = '50000';
        apcCtrl.strPrice = '10';
        apcCtrl.saveProduct();

        //OpportunityLineItem oli = [SELECT Id, Name, UnitPrice, Quantity, TotalPrice
        //                          FROM OpportunityLineItem
        //                          WHERE PricebookEntryId = :pbeId AND OpportunityId = :opp.Id ];
        //System.assertEquals(prodName, oli.Name);
        //System.assertEquals(10.00, oli.UnitPrice);
        //System.assertEquals(50.0, oli.Quantity);
        //System.assertEquals(500.00, oli.TotalPrice);
    }
    
    //@isTest static void test_cancel() {
        //Opportunity opp = opportunitySetup(false, 'Standard Price Book');
        //AddProductCustomController apcCtrl = new AddProductCustomController(new ApexPages.StandardController(opp));
        //apcCtrl.cancel();
    //}
    
}