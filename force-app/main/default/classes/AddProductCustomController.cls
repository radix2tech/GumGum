public with sharing class AddProductCustomController {
    
    public Opportunity opp {get;set;}
    public Boolean selectPriceBook {get;set;}
    public Pricebook2 objPb {get;set;}
    public String pricingOption {get;set;}
    public List<SelectOption> pricingOptions {get;set;}
    public Boolean pricingError {get;set;}
    public String productOption {get;set;}
    public List<SelectOption> productOptions {get;set;}
    public Boolean productError {get;set;}
    public String strQuantForCpm {get;set;}
    public Boolean quantityError {get;set;}
    public String strPrice {get;set;}
    public Boolean priceError {get;set;}
    public List<OpportunityLineItem> oppProducts {get;set;}
    
    private Id standardPriceBookId;
    private static final Double DIVISOR = 1000.0;
    
    public AddProductCustomController(ApexPages.StandardController stdController) {
        this.opp = (Opportunity) stdController.getRecord();
        
        opp = [SELECT Id, Name, Pricebook2Id
               FROM Opportunity
               WHERE Id = :opp.Id];
        
        selectPriceBook = false;
        // If there is no price book for this opportunity, set the price book to the Standard price.
        objPb = [SELECT Id, Name FROM Pricebook2 WHERE Name = 'Standard Price Book'];
        standardPriceBookId = objPb.Id;
        if (opp.Pricebook2Id == null || opp.Pricebook2Id != standardPriceBookId) {
            selectPriceBook = true;
        }

        pricingOptions = new List<SelectOption>();
        pricingOptions.add(new SelectOption('', '-- Select --'));
        Schema.DescribeFieldResult fieldResult = Product2.Pricing__c.getDescribe();
        List<Schema.PicklistEntry> ples = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry ple : ples)
        {
            pricingOptions.add(new SelectOption(ple.getLabel(), ple.getValue()));
        }

        productOptions = new List<SelectOption>();
        productOptions.add(new SelectOption('', '-- Select --'));
        List<PriceBookEntry> pbes = [SELECT Id, Name FROM PriceBookEntry WHERE Pricebook2Id = :objPb.Id AND IsActive = true AND Product2.Package_Product__c = false];
        for (PriceBookEntry pbe :pbes) 
        {
            productOptions.add(new SelectOption(pbe.Id, pbe.Name));
        }
        updateCurrentOppProducts();
    }
        
    public PageReference savePricebook() {
        opp.Pricebook2Id = standardPriceBookId;
        update opp;
        selectPriceBook = false;
        return null;
    }

    public PageReference saveProduct() {
        pricingError = false;
        productError = false;
        quantityError = false;
        priceError = false;
        if (pricingOption == null) {
            pricingError = true;
        }
        if (productOption == null) {
            productError = true;
        } 
        if (!strQuantForCpm.replace(',','').isNumeric()) {
                quantityError = true;
        }
        try 
        {
            Double num = Double.valueOf(strPrice.replace(',',''));
        } 
        catch (Exception e)
        {
            priceError = true;
        }
        if (!pricingError && !productError && !quantityError && !priceError) {
            Double dblQuantForCpm = Double.valueOf(strQuantForCpm.replace(',',''));
            Double dblPrice = Double.valueOf(strPrice.replace(',',''));
            
            OpportunityLineItem oli = new OpportunityLineItem();
            oli.OpportunityId = opp.Id;
            oli.Pricing__c = pricingOption;
            oli.PricebookEntryId = productOption;
            oli.UnitPrice = dblPrice;
            oli.Quantity = dblQuantForCpm;
            
            //if (pricingOption == 'VCPM' || pricingOption == 'CPM') {
            //    oli.Quantity = dblQuantForCpm / DIVISOR;
            //} else {
            //    oli.Quantity = dblQuantForCpm;
            //}
            
            insert oli;
            
            //clear quantity and price values on form
            strQuantForCpm = '';
            strPrice = '';
            
            //update oppProducts on form
            updateCurrentOppProducts();      
        }
        return null;
    }
    
    public PageReference updateCurrentOppProducts() {
        oppProducts = [SELECT Id,
                       Pricing__c,
                       HasSchedule,
                       PricebookEntry.Product2.Name, 
                       Quantity, 
                       UnitPrice, 
                       CreatedDate,
                       TotalPrice
                       FROM OpportunityLineItem 
                       WHERE OpportunityId = :opp.Id
                       ORDER BY CreatedDate desc];
        return null;
    }
    
    public PageReference cancel() {
        ApexPages.StandardController stdController = new ApexPages.StandardController(opp);
        return stdController.view();
    }
}