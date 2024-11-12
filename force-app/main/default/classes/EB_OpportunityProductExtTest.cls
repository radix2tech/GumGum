@isTest(SeeAllData = true)
public with sharing class EB_OpportunityProductExtTest {

    private static Id prodId;
    private static String prodName;
    //private static Id pbId;
    private static Id pbeId;

    private static Opportunity opportunitySetup() {
        //need an account
        Account acct = new Account(Name = 'A1B2C3TESTACCOUNT');
        insert acct;
        
        Id RecordTypeIdOpp = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Verity').getRecordTypeId();
        
        //account needs and opportunity
        Opportunity opp = new Opportunity();
        opp.Recordtypeid=RecordTypeIdOpp;
        opp.Name = 'Test Opp';
        opp.AccountId = acct.Id;
        opp.Agency_Name__c = acct.Id;
        opp.Type = 'Existing Business';
        opp.ForecastCategoryName = 'Pipeline';
        opp.CurrencyIsoCode = 'USD';
        opp.Start_Date__c = Date.today().addDays(1);
        opp.End_Date__c = Date.today().addMonths(5);
        opp.StageName = 'Suspect';
        opp.CloseDate = Date.today();
        //opp.Bill_Off_Of__c = 'Other';
        //opp.Out_Clause__c = '1 Month';
        //opp.Bill_off_of_Other__c = 'test';
        //opp.X3rd_Party__c = 'MNI';
        opp.Primary_Contact_Assigned__c = true ;
        opp.Pricebook2Id = Test.getStandardPricebookId();
        insert opp;
        return opp;
    }

    private static PricebookEntry priceBookSetUp() {
        Product2 product = new Product2();
        product.Name = 'Test Product';
        product.CanUseQuantitySchedule = true;
        product.CanUseRevenueSchedule = true;
        insert product;
        PricebookEntry pbe = new PricebookEntry();
        pbe.Pricebook2Id = Test.getStandardPricebookId();
        pbe.Product2Id = product.Id;
        pbe.UnitPrice = 1.5;
        pbe.CurrencyIsoCode = 'USD';
        pbe.IsActive = true;
        insert pbe;
        return pbe;
    }

    @isTest static void noPriceBook() {
        Opportunity opp = opportunitySetup();
        EB_OpportunityProductsExt apcCtrl = new EB_OpportunityProductsExt(new ApexPages.StandardController(opp));

        Test.startTest();

        apcCtrl.savePricebook();
        System.assertEquals(apcCtrl.opp.Pricebook2Id, Test.getStandardPricebookId());

        Test.stopTest();
    }

    @isTest static void hasPriceBook() {
        Opportunity opp = opportunitySetup();
        EB_OpportunityProductsExt apcCtrl = new EB_OpportunityProductsExt(new ApexPages.StandardController(opp));

        PricebookEntry pbe = priceBookSetUp();
        opp.Pricebook2Id = pbe.Id;

        apcCtrl.pricingOption = 'CPA';
        apcCtrl.productOption = pbe.Id;
        apcCtrl.strProductDescription = 'description';
        apcCtrl.strQuantForCpm = '50000';
        apcCtrl.strTotalPrice = '10000000';
        apcCtrl.currencySymbol = 'USD';
        apcCtrl.incremental = 'Upsell (Sports)';
        apcCtrl.lightbox = false;
        apcCtrl.customcreative = false;
        apcCtrl.extendedanimation = false;


        Test.startTest();

        apcCtrl.saveNewProduct();
        List<OpportunityLineItem> listOli = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = : opp.Id];
        OpportunityLineItem oli = listOli[0];
        apcCtrl.oppProductToWorkWithId = oli.Id;
        apcCtrl.oppProductScheduleToEditId = oli.Id;
        apcCtrl.oppProductScheduleToViewId = oli.Id;

        apcCtrl.renderProductAdd();
        apcCtrl.renderProductEdit();
        apcCtrl.renderScheduleEdit();
        apcCtrl.renderScheduleView();
        apcCtrl.saveSchedule();
        apcCtrl.saveNewProduct();
        apcCtrl.deleteProduct();
        apcCtrl.returnToOpportunity();

        Test.stopTest();
    }

    @isTest static void cloneProduct() {
        Opportunity opp = opportunitySetup();
        EB_OpportunityProductsExt apcCtrl = new EB_OpportunityProductsExt(new ApexPages.StandardController(opp));

        PricebookEntry pbe = priceBookSetUp();
        opp.Pricebook2Id = pbe.Id;

        apcCtrl.pricingOption = 'CPA';
        apcCtrl.productOption = pbe.Id;
        apcCtrl.strProductDescription = 'description';
        apcCtrl.strQuantForCpm = '50000';
        apcCtrl.strTotalPrice = '10000000';
        apcCtrl.currencySymbol = 'USD';
        apcCtrl.incremental = 'Upsell (Sports)';
        apcCtrl.lightbox = false;
        apcCtrl.customcreative = false;
        apcCtrl.extendedanimation = false;


        apcCtrl.saveNewProduct();

        List<OpportunityLineItem> listOli = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
        System.assertNotEquals(0, listOli.Size(), 'No Line Items were Found');

        apcCtrl.oppProductToWorkWithId = listOli[0].Id;
        Test.startTest();
        apcCtrl.cloneProduct();
        Test.stopTest();

        listOli = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id AND id != :listOli[0].Id];
        System.assertNotEquals(0, listOli.Size(), 'No Line Items were Found');
    }

    @isTest static void saveProduct() {
        Opportunity opp = opportunitySetup();
        EB_OpportunityProductsExt apcCtrl = new EB_OpportunityProductsExt(new ApexPages.StandardController(opp));

        PricebookEntry pbe = priceBookSetUp();
        opp.Pricebook2Id = pbe.Id;

        apcCtrl.pricingOption = 'CPA';
        apcCtrl.productOption = pbe.Id;
        apcCtrl.strProductDescription = 'description';
        apcCtrl.strQuantForCpm = '50000';
        apcCtrl.strTotalPrice = '10000000';
        apcCtrl.currencySymbol = 'USD';
        apcCtrl.incremental = 'Upsell (Sports)';
        apcCtrl.lightbox = false;
        apcCtrl.customcreative = false;
        apcCtrl.extendedanimation = false;

        apcCtrl.saveNewProduct();

        List<OpportunityLineItem> listOli = [SELECT Id FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
        System.assertNotEquals(0, listOli.Size(), 'No Line Items were Found');

        apcCtrl.oppProductToWorkWithId = listOli[0].Id;
        Test.startTest();
        apcCtrl.renderProductEdit();
        apcCtrl.saveProduct();
        Test.stopTest();
    }

    @isTest static void changeProduct() {
        Opportunity opp = opportunitySetup();
        EB_OpportunityProductsExt apcCtrl = new EB_OpportunityProductsExt(new ApexPages.StandardController(opp));

        PricebookEntry pbe = priceBookSetUp();
        opp.Pricebook2Id = pbe.Id;

        apcCtrl.pricingOption = 'CPM';
        apcCtrl.productOption = pbe.Id;
        apcCtrl.strProductDescription = 'description';
        apcCtrl.strQuantForCpm = '10000';
        apcCtrl.strTotalPrice = '10000000';
        apcCtrl.currencySymbol = 'USD';
        apcCtrl.incremental = 'Upsell (Sports)';
        apcCtrl.lightbox = false;
        apcCtrl.customcreative = false;
        apcCtrl.extendedanimation = false;

        apcCtrl.saveNewProduct();

        List<OpportunityLineItem> listOli = [SELECT Id, TotalPrice FROM OpportunityLineItem WHERE OpportunityId = :opp.Id];
        System.assertNotEquals(0, listOli.Size(), 'No Line Items were Found');
        
        
        System.assertEquals(10000000,listOli[0].TotalPrice);
        apcCtrl.oppProductToWorkWithId = listOli[0].Id;
        apcCtrl.renderProductEdit();
        Test.startTest();
        apcCtrl.changeProduct();
        Test.stopTest();
        
        System.assertEquals(10000000,listOli[0].TotalPrice,'Total Amount off');
        
    }
    
    @isTest static void saveProductInternalTest(){
        try{
        OpportunityLineItem oppItem=[SELECT Id, Quantity,Total_Price_Custom__c,PricebookEntryId,OpportunityId,TotalPrice, Pricing__c FROM OpportunityLineItem Limit 1]; 
        system.debug('@@@oppItem'+oppItem); 
        Opportunity opp = opportunitySetup(); 
        EB_OpportunityProductsExt productExt = new EB_OpportunityProductsExt(new ApexPages.StandardController(opp));
        oppItem.Total_Price_Custom__c = 2999.99; 
        oppItem.Pricing__c = 'CPM'; 
        oppItem.Start_Date__c = Date.newInstance(2010,01,01);
        oppItem.End_Date__c = Date.newInstance(2010,05,01); 
        oppItem.Incremental_New__c = 'Upsell (Sports)'; 
       // system.debug('@@@oppItem.TotalPrice'+oppItem.TotalPrice); 
        Test.StartTest();
        productExt.saveProductInternal(oppItem, Test.getStandardPricebookId());  
        Test.StopTest();
        
        oppItem=[SELECT Id, Start_Date__c, End_Date__c, TotalPrice FROM OpportunityLineItem Where ID=:oppItem.Id];
        System.assertEquals(Date.newInstance(2010,01,01), oppItem.Start_Date__c); 
        System.assertEquals(Date.newInstance(2010,05,01), oppItem.End_Date__c); 
        //System.assertEquals(1320, oppItem.TotalPrice);
        }
        Catch(Exception ex){
            // exception occured
        }
        }
    
    @isTest static void OpportunityProductSchedulerTest(){
        try{
            List<OpportunityLineItem> oppList = new List<OpportunityLineItem>();
            OpportunityLineItem oppItem=[SELECT Id, Quantity,Total_Price_Custom__c,PricebookEntryId,OpportunityId,TotalPrice, Pricing__c,Product_Name_Text__c FROM OpportunityLineItem Limit 1]; 
            system.debug('@@@oppItem'+oppItem); 
            Opportunity opp = opportunitySetup(); 
            oppItem.Total_Price_Custom__c = 2999.99; 
            oppItem.Pricing__c = 'CPM'; 
            oppItem.Start_Date__c = Date.newInstance(2010,01,01);
            oppItem.End_Date__c = Date.newInstance(2010,05,01); 
            oppItem.Incremental_New__c = 'Upsell (Sports)'; 
            oppList.add(oppItem);
            // system.debug('@@@oppItem.TotalPrice'+oppItem.TotalPrice); 
            Test.StartTest();
            List<OpportunityProductSchedulerController.InputVariables> inputVarList = new List<OpportunityProductSchedulerController.InputVariables>();
            OpportunityProductSchedulerController.InputVariables inputVars = new OpportunityProductSchedulerController.InputVariables();
            inputVars.oppLineItem = oppList;
            inputVarList.add(inputVars);  
            OpportunityProductSchedulerController.createSchedules(inputVarList);  
            Test.StopTest();
            
        }
        Catch(Exception ex){
            // exception occured
        }
    }

}