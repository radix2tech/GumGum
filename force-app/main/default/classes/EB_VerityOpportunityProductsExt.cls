public with sharing class EB_VerityOpportunityProductsExt {

    public Opportunity opp {get; set;}
    public Boolean selectPriceBook {get; set;}
    public Pricebook2 objPb {get; set;}
    public Date startDate {get; set;}
    public Date endDate {get; set;}
    public String pricingOption {get; set;}
    public List<SelectOption> pricingOptions {get; set;}
    public List<SelectOption> incrementalOptions {get; set;}
    public Boolean pricingError {get; set;}
    public String productOption {get; set;}
    public List<SelectOption> productOptions {get; set;}
    public Boolean productError {get; set;}
    public String strProductDescription {get; set;}
    public String strQuantForCpm {get; set;}
    public String strTotalPrice {get;set;}
    public Boolean quantityError {get; set;}
    public String strPrice {get; set;}
    public Boolean priceError {get; set;}
    public List<OpportunityLineItem> oppProducts {get; set;}
    public OpportunityLineItem oppProductToWorkWith {get; set;}
    public Id oppProductToWorkWithId {get; set;}
    public List<OpportunityLineItemSchedule> oppProductScheduleToView {get; set;}
    public List<OpportunityLineItemSchedule> oppProductScheduleToEdit {get; set;}
    public Id oppProductScheduleToViewId {get; set;}
    public Id oppProductScheduleToEditId {get; set;}
    public Boolean doRenderCurrentProducts {get; set;}
    public Boolean doRenderProductAdd {get; set;}
    public Boolean doRenderProductEdit {get; set;}
    public Boolean doRenderScheduleView {get; set;}
    public Boolean doRenderScheduleEdit {get; set;}
    public String strEdit {get; set;}
    public String strNew {get; set;}
    public String incremental {get; set;}
    public Boolean lightbox {get; set;}
    public Boolean customCreative {get;set;}
    public Boolean extendedAnimation {get;set;}
    public Boolean fixedSchedule { get; set; }
    public String headerTitle {get; set;}
    public String headerSubTitle {get; set;}
    public String editProductReturn {get; set;}
    public String currencySymbol {get; set;}
    public List<SelectOption> partnerOptions {get; set;}
    public List<SelectOption> segmentTypeOptions {get; set;}
    public String partnerOption {get; set;}
    public String segmentTypeOption {get; set;}
    public String verityDealId {get;set;}
    public Boolean renderPartNerAndSegment{get; set;} //it's set to true for Verity - Demand
    public Boolean partnerError {get; set;}
    public Boolean segmentTypeError {get; set;}
    public Boolean verityDealIdError {get; set;}
    public String strPercentOfBudget {get; set;}   
    public Boolean startDateError {get; set;} 
    public Boolean endDateError {get; set;} 
    public Boolean hasActuals {get; set;}
    public Date maxActualScheduleDate{get; set;}
    public String maxActualScheduleDateString {get; set;}
    public Boolean isVerityDemand{get; set;} 

    private Id standardPriceBookId;
    private static final Double DIVISOR = 1000.0;
    
    public Pricebook2 stdobjPb {get; set;}
    
    public EB_VerityOpportunityProductsExt(ApexPages.StandardController stdController) {
        this.opp = (Opportunity) stdController.getRecord();

        opp = [SELECT Id, Name, Pricebook2Id, Start_Date__c, End_Date__c, CurrencyIsoCode,RecordType.Name,Voiced_Budget__c,stageName
               FROM Opportunity
               WHERE Id = :opp.Id];
		renderPartNerAndSegment = false;
        isVerityDemand = false;
        If(opp.RecordType.Name == 'Verity - Demand'){
            renderPartNerAndSegment = true; 
            isVerityDemand = true;
        }
        currencySymbol = setCurrencySymbol(opp.CurrencyIsoCode);
        strEdit = 'edit';
        strNew = 'new';

        selectPriceBook = false;
        fixedSchedule = false;
        // If there is no price book for this opportunity, set the price book to the Standard price.
        objPb = [SELECT Id, Name FROM Pricebook2 WHERE Id = :opp.Pricebook2Id];
       // stdobjPb = [SELECT Id, Name FROM Pricebook2 WHERE Name = 'Standard Price Book'];
        standardPriceBookId = Label.StandardPricebookId;
        /*if (opp.Pricebook2Id == null || opp.Pricebook2Id != standardPriceBookId) {
            selectPriceBook = true;
        }*/

        pricingOptions = new List<SelectOption>();
        incrementalOptions = new List<SelectOption>();
        partnerOptions = new List<SelectOption>();
        segmentTypeOptions = new List<SelectOption>();
        
        
        pricingOptions.add(new SelectOption('', '-- Select --'));
        incrementalOptions.add(new SelectOption('', '-- Select --'));
        
        partnerOptions.add(new SelectOption('', '-- Select --'));
        segmentTypeOptions.add(new SelectOption('', '-- Select --'));
        
        Schema.DescribeFieldResult fieldResult = Product2.Pricing__c.getDescribe();
        List<Schema.PicklistEntry> ples = fieldResult.getPicklistValues();
        for ( Schema.PicklistEntry ple : ples) {
            //'% of Media' is only for Verity - Demand
            //
            If(opp.RecordType.Name != 'Verity - Demand' && ple.getLabel() == '% of Media'){
                continue;
            }
            If(opp.RecordType.Name == 'Verity - Demand' && ple.getLabel() != '% of Media'){
                continue;
            }
            pricingOptions.add(new SelectOption(ple.getLabel(), ple.getValue()));
        }
        If(opp.RecordType.Name == 'Verity - Demand'){
            pricingOption = '% of Media';
            strPercentOfBudget = '100';
        }
        
        Schema.DescribeFieldResult IncrementfieldResult = OpportunityLineItem.Incremental_New__c.getDescribe();
        List<Schema.PicklistEntry> Iples = IncrementfieldResult.getPicklistValues();
        for ( Schema.PicklistEntry ple : Iples) {
            incrementalOptions.add(new SelectOption(ple.getLabel(), ple.getValue()));
        }
        
        Schema.DescribeFieldResult partnerFieldResult = OpportunityLineItem.Partner__c.getDescribe();
        List<Schema.PicklistEntry>  partnerPles = partnerFieldResult.getPicklistValues();
        for ( Schema.PicklistEntry ple : partnerPles) {
            partnerOptions.add(new SelectOption(ple.getLabel(), ple.getValue()));
        }
        
        Schema.DescribeFieldResult segmentTypeFieldResult = OpportunityLineItem.Segment_Type__c.getDescribe();
        List<Schema.PicklistEntry> segmentPles = segmentTypeFieldResult.getPicklistValues();
        for ( Schema.PicklistEntry ple : segmentPles) {
            segmentTypeOptions.add(new SelectOption(ple.getLabel(), ple.getValue()));
        }

        productOptions = new List<SelectOption>();
        productOptions.add(new SelectOption('', '-- Select --'));
        List<PriceBookEntry> pbes = [SELECT Id, Name FROM PriceBookEntry WHERE Pricebook2Id = :objPb.Id AND IsActive = true AND Product2.Package_Product__c = false AND CurrencyIsoCode = : opp.CurrencyIsoCode Order By Name];
        for (PriceBookEntry pbe : pbes) {
            productOptions.add(new SelectOption(pbe.Id, pbe.Name));
        }
        updateCurrentOppProducts();
        doRenderCurrentProducts = true;
        doRenderProductAdd = false;
        doRenderProductEdit = false;
        doRenderScheduleView = false;
        doRenderScheduleEdit = false;

        headerTitle = 'Products for';
        headerSubTitle = opp.Name;
    }
    
    //On change of the pricing or product field and % of Budget on screen, updates the TotalPrice based on Voiced Budget on Opportunity and Verity Revenue on Product2
    public PageReference onProductOrPricingChange(){
        if(pricingOption == '% of Media'){
            strQuantForCpm = '1';
            List<PricebookEntry> priceBookEntryList = [SELECT Id,Name,Product2.Verity_Revenue__c from PricebookEntry where id=:productOption];
            if(priceBookEntryList.size()>0){
                if(priceBookEntryList[0].Product2.Verity_Revenue__c!=null && opp.Voiced_Budget__c!=null && strPercentOfBudget!=null && strPercentOfBudget!=''){   
                    strTotalPrice = String.valueOf((priceBookEntryList[0].Product2.Verity_Revenue__c*opp.Voiced_Budget__c*Double.valueOf(strPercentOfBudget))/10000);
                }
            }
        }
        return null;
    }
     
    public PageReference savePricebook() {
        opp.Pricebook2Id = standardPriceBookId;
        update opp;
        selectPriceBook = false;
        return null;
    }

    public PageReference saveNewProduct() {
        pricingError = false;
        productError = false;
        quantityError = false;
        priceError = false;
        partnerError = false;
        segmentTypeError = false;
        verityDealIdError = false;
        startDateError = false;
        endDateError = false;
        if(opp.Start_Date__c==null){
            startDateError = true;
        }
        if(opp.End_Date__c==null){
            endDateError = true;
        }
        
        if (pricingOption == null) { 
            pricingError = true;
        }
        if (productOption == null) {
            productError = true;
        }
        if(opp.StageName =='Closed/Won' && renderPartNerAndSegment && partnerOption == null){
            partnerError = true;
        }
        if(opp.StageName =='Closed/Won' && renderPartNerAndSegment && segmentTypeOption == null){
            segmentTypeError = true;
        }
        if(opp.StageName =='Closed/Won' && renderPartNerAndSegment && (verityDealId == null || verityDealId=='')){
            //verityDealIdError = true;
        }
        // Added logic to set the lightbox, customcreative, and extendedanimation to false.
        //Retrieve profile name
		String profileName = [SELECT Name FROM Profile WHERE Id =: userInfo.getProfileId()].Name;
        lightbox          = false;
        extendedanimation = false;
        customcreative    = false;
        customcreative    = false;
        if (!strQuantForCpm.replace(',', '').isNumeric()) {
            try {
                Integer quantityNum = Integer.valueOf(strQuantForCpm.replace(',', ''));
            } catch (Exception e) {
            quantityError = true;
            }        
        }
        try {
            Double num = Double.valueOf(strTotalPrice.replace(',', ''));
        } catch (Exception e) {
            priceError = true;
        }
        if (!verityDealIdError && !partnerError && !segmentTypeError && !pricingError && !productError && !quantityError && !priceError && !startDateError && !endDateError) {
            Double dblQuantForCpm = Double.valueOf(strQuantForCpm.replace(',', ''));
            Double dblPrice  = Double.valueOf(strTotalPrice.replace(',', ''));
            system.debug('FFFF_:'+dblPrice );
            
            
            OpportunityLineItem oli = new OpportunityLineItem();
            oli.OpportunityId = opp.Id;
            oli.Pricing__c = pricingOption;
            oli.PricebookEntryId = productOption;
            oli.Description = strProductDescription;
            oli.Quantity = dblQuantForCpm;
            
            oli.Total_Price_Custom__c = dblPrice;
            oli.Verity_Revenue__c = dblPrice;
            oli.TotalPrice = dblPrice;  
            //oli.UnitPrice = dblPrice;
            
           // oli.Unit_Price__c = dblPrice/(dblQuantForCpm/1000);
            oli.Incremental_New__c = incremental;
            oli.Lightbox__c = lightbox;
            oli.Custom_Creative__c = customcreative;
            oli.Extended_Animation__c = extendedanimation;
            
            oli.Partner__c = partnerOption;
            oli.Segment_Type__c = segmentTypeOption;
            oli.Verity_Deal_ID__c = verityDealId;
            if(strPercentOfBudget!=null && strPercentOfBudget!=''){
                oli.of_Budget__c = Double.valueOf(strPercentOfBudget);
            }
            insert oli;
            
            CalculatePricing(oli); 
            
            update (new OpportunityLineItem(Id = oli.Id, Unit_Price__c = oli.Unit_Price__c));

            establishNewSchedule(opp.Id, oli.Id);

            //clear quantity and price values on form
            strProductDescription = '';
            strQuantForCpm = '';
            strTotalPrice = '';
            incremental = '';
            lightbox = false;
            customcreative = false;
            extendedanimation = false;
            //update oppProducts on form
            updateCurrentOppProducts();
            resetPage();
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
                       Unit_Price__c,
                       CreatedDate,
                       TotalPrice,
                       Total_Price_Custom__c,
                       Verity_Revenue__c,
                       Start_Date__c,
                       End_Date__c,
                       Description,
                       Incremental_New__c,
                       Partner__c,
                       Segment_Type__c,
                       Verity_Deal_ID__c,
                       of_Budget__c,
                       Lightbox__c,
                       Custom_Creative__c,
                       Extended_Animation__c,
                       Name,
                       Opportunity.RecordType.Name,
                       Actual_Amount_Verity__c
                       FROM OpportunityLineItem
                       WHERE OpportunityId = :opp.Id
                       ORDER BY CreatedDate desc];
        return null;
    }

    public PageReference returnToOpportunity() {
        ApexPages.StandardController stdController = new ApexPages.StandardController(opp);
        return stdController.view();
    }

    public PageReference establishSchedule(OpportunityLineItem oli) {
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
        List<OpportunityLineItemSchedule> listOlis = new List<OpportunityLineItemSchedule>();
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
            olis.Verity_Revenue__c = scheduleRevenueRounded;
            listOlis.add(olis);
            system.debug('Inside establishSchedule');
            system.debug(olis);
            system.debug(listOlis);
            endOfMonth = endOfMonth.addMonths(2);
            endOfMonth = endOfMonth.toStartOfMonth();
            endOfMonth = endOfMonth.addDays(-1);
        }
        insert(listOlis);
        return null;
    }
    
    //establish schedules by retaining actuals
    public PageReference establishSchedule(OpportunityLineItem oli,List<OpportunityLineItemSchedule> actualOlis) {
        
        Map<Date,Double> scheduleDate2ActualRevenueMap = new Map<date,Double>();
        for(OpportunityLineItemSchedule olis: actualOlis){
            scheduleDate2ActualRevenueMap.put(olis.ScheduleDate,olis.Actual_Revenue_Verity__c);
        }
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
        List<OpportunityLineItemSchedule> listOlis = new List<OpportunityLineItemSchedule>();
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
            olis.Verity_Revenue__c = scheduleRevenueRounded;
            if(scheduleDate2ActualRevenueMap.containsKey(olis.ScheduleDate)){
                olis.Actual_Revenue_Verity__c = scheduleDate2ActualRevenueMap.get(olis.ScheduleDate);
            }
            listOlis.add(olis);
            system.debug('Inside establishSchedule');
            system.debug(olis);
            system.debug(listOlis);
            endOfMonth = endOfMonth.addMonths(2);
            endOfMonth = endOfMonth.toStartOfMonth();
            endOfMonth = endOfMonth.addDays(-1);
        }
        insert(listOlis);
        return null;
    }

    public PageReference establishNewSchedule(Id oppId, Id oliId) {
        OpportunityLineItem oli = [SELECT Id, Quantity, TotalPrice, Total_Price_Custom__c,Verity_Revenue__c,Start_Date__c, End_Date__c, Incremental_New__c,Partner__c,Segment_Type__c,Verity_Deal_ID__c,of_Budget__c, Lightbox__c,Custom_Creative__c,Extended_Animation__c FROM OpportunityLineItem WHERE Id = : oliId];

        oli.Start_Date__c = opp.Start_Date__c;
        oli.End_Date__c = opp.End_Date__c;
        update oli;

        oli = [SELECT Id, Quantity, TotalPrice,Total_Price_Custom__c,Verity_Revenue__c, Start_Date__c, End_Date__c, Incremental_New__c,Partner__c,Segment_Type__c,Verity_Deal_ID__c,of_Budget__c, Lightbox__c,Custom_Creative__c,Extended_Animation__c FROM OpportunityLineItem WHERE Id = : oliId];

        establishSchedule(oli);
        return null;
    }

    public PageReference reestablishSchedule(OpportunityLineItem oli) {
        //OpportunityLineItem oli = [SELECT Id, Quantity, TotalPrice, Start_Date__c, End_Date__c FROM OpportunityLineItem WHERE Id = : oliId];
        if (fixedSchedule == null || fixedSchedule == false) {
            establishSchedule(oli);
        }
        return null;
    }

    public PageReference saveProduct() {
        return saveProductInternal(oppProductToWorkWith, productOption);
    }
    
    @TestVisible private PageReference saveProductInternal(OpportunityLineItem changeProduct, String oldProduct){
        Savepoint sp = Database.setSavepoint();
        try {
            if (changeProduct.PriceBookEntryId != oldProduct && oldProduct != null) {
                changeProduct();
                return null;
            }
            //need to delete and reestablish the schedule so the change will stick
            List<OpportunityLineItemSchedule> olis = [SELECT Id,Actual_Revenue_Verity__c,ScheduleDate FROM OpportunityLineItemSchedule WHERE OpportunityLineItemId = : changeProduct.Id];
            if (fixedSchedule == null || fixedSchedule == false) {         
                delete olis;
            }
			system.debug('after delete olis2' + olis[0].Actual_Revenue_Verity__c);
            OpportunityLineItem tempOp = New OpportunityLineItem();
            //tempOp.Id = changeProduct.Id;
            tempOp.OpportunityId = changeProduct.OpportunityId;
            tempOp.Quantity = changeProduct.Quantity;
            //tempOp.Quantity = changeProduct.Quantity;
           // tempOp.Unit_Price__c = changeProduct.TotalPrice/changeProduct.Quantity; 
            
            
            //Checking if the opp record type is 'Verity - Demand'
            if(renderPartNerAndSegment){
                if(pricingOption == '% of Media'){
                    List<PricebookEntry> priceBookEntryList = [SELECT Id,Name,Product2.Verity_Revenue__c from PricebookEntry where id=:productOption];
                    if(priceBookEntryList.size()>0){
                        if(priceBookEntryList[0].Product2.Verity_Revenue__c!=null && opp.Voiced_Budget__c!=null && changeProduct.of_Budget__c!=null){   
                            
                            tempOp.Total_Price_Custom__c = (priceBookEntryList[0].Product2.Verity_Revenue__c*opp.Voiced_Budget__c*changeProduct.of_Budget__c/10000);
                            tempOp.TotalPrice = tempOp.Total_Price_Custom__c;
                        }
                    }
                }
            }else{
                tempOp.Total_Price_Custom__c = changeProduct.Total_Price_Custom__c; 
                tempOp.TotalPrice = changeProduct.Total_Price_Custom__c;  
            }
            tempOp.of_Budget__c = changeProduct.of_Budget__c;
            tempOp.Verity_Revenue__c = tempOp.Total_Price_Custom__c;
            tempOp.Pricing__c = changeProduct.Pricing__c;
            tempOp.Start_Date__c = changeProduct.Start_Date__c;
            tempOp.End_Date__c = changeProduct.End_Date__c;
            tempOp.Description = changeProduct.Description;
            tempOp.Incremental_New__c= changeProduct.Incremental_New__c;
            tempOp.Partner__c= changeProduct.Partner__c;
            tempOp.Segment_Type__c= changeProduct.Segment_Type__c;
            tempOp.Verity_Deal_ID__c= changeProduct.Verity_Deal_ID__c;
            
            tempOp.Lightbox__c = changeProduct.Lightbox__c;
            tempOp.Custom_Creative__c = changeProduct.Custom_Creative__c;
            tempOp.Extended_Animation__c = changeProduct.Extended_Animation__c;
            tempOp.PriceBookEntryId = productOption;
            System.debug('DEBUG 1: ' + tempOp);         
            CalculatePricing(tempOp); 
            System.debug('DEBUG 2: tempOp ' + tempOp);
            insert tempOp;
            delete changeProduct; 
            
            changeProduct=[SELECT ID, TotalPrice,Total_Price_Custom__c,Verity_Revenue__c, Start_Date__c, End_Date__c, Quantity, Incremental_New__c,Partner__c,Segment_Type__c,Verity_Deal_ID__c,of_Budget__c, Lightbox__c,Custom_Creative__c,Extended_Animation__c FROM OpportunityLineItem WHERE Id=:tempOp.Id];
            System.debug('DEBUG 3: ChangeProduct: ' + changeProduct);
            if(hasActuals){
                establishSchedule(changeProduct,olis); 
            }
            else{
                reestablishSchedule(changeProduct); 
            }
            oppProductScheduleToViewId = changeProduct.Id;
            renderScheduleView();
        } catch (Exception e) {
            Database.rollback(sp);
            throw new SaveException('An error occurred saving record. ' + e.getMessage() + ' Line: ' + e.getLineNumber());
        }
        return null;
    }

    public PageReference changeProduct() {
        Savepoint sp = Database.setSavepoint();
        try {

            //Need to delete the current product and rebuild it to change the product.

            List<OpportunityLineItemSchedule> olis = [SELECT Id,Actual_Revenue_Verity__c,ScheduleDate FROM OpportunityLineItemSchedule WHERE OpportunityLineItemId = : oppProductToWorkWithId];
            delete olis;

            OpportunityLineItem newOppProduct = oppProductToWorkWith.clone(false, true, false, false);
            newOppProduct.PriceBookEntryId = productOption;
            
            if(renderPartNerAndSegment){
                if(pricingOption == '% of Media'){
                    List<PricebookEntry> priceBookEntryList = [SELECT Id,Name,Product2.Verity_Revenue__c from PricebookEntry where id=:productOption];
                    if(priceBookEntryList.size()>0){
                        if(priceBookEntryList[0].Product2.Verity_Revenue__c!=null && opp.Voiced_Budget__c!=null && oppProductToWorkWith.of_Budget__c!=null){   
                            newOppProduct.TotalPrice = (priceBookEntryList[0].Product2.Verity_Revenue__c*opp.Voiced_Budget__c*oppProductToWorkWith.of_Budget__c/10000);
                            newOppProduct.Total_Price_Custom__c = newOppProduct.TotalPrice;
                        }
                    }
                }
            }else{ 
                newOppProduct.TotalPrice = oppProductToWorkWith.Total_Price_Custom__c;
            }
            newOppProduct.Verity_Revenue__c = newOppProduct.Total_Price_Custom__c;

            CalculatePricing(newOppProduct);
            
            newOppProduct.UnitPrice=null;
            
            insert newOppProduct;
            delete oppProductToWorkWith;
            
            newOppProduct=[SELECT ID, TotalPrice,Total_Price_Custom__c,Verity_Revenue__c, Start_Date__c, End_Date__c, Quantity, Incremental_New__c,Partner__c,Segment_Type__c,Verity_Deal_ID__c,of_Budget__c, Lightbox__c,Custom_Creative__c,Extended_Animation__c FROM OpportunityLineItem WHERE Id=:newOppProduct.Id];
            
            if(hasActuals){
                establishSchedule(newOppProduct,olis); 
            }else{
                establishSchedule(newOppProduct);
            }
            updateCurrentOppProducts();
        } catch (Exception e) {
            Database.rollback(sp);
            throw new SaveException('An error occurred updating record. ' + e.getMessage() + ' Line: ' + e.getLineNumber());
        }
        resetPage();
        return null;
    }

    public PageReference cloneProduct() {
        oppProductToWorkWith = [SELECT Id, TotalPrice,OpportunityId,Total_Price_Custom__c,Verity_Revenue__c, Product2.Name, PriceBookEntryId, Pricing__c, Quantity, Unit_Price__c, Description, Start_Date__c, End_Date__c, Incremental_New__c,Partner__c,Segment_Type__c,Verity_Deal_ID__c,of_Budget__c, Lightbox__c,Custom_Creative__c,Extended_Animation__c,Opportunity.RecordType.Name FROM OpportunityLineItem WHERE Id = : oppProductToWorkWithId];
        OpportunityLineItem newOppProduct = oppProductToWorkWith.clone(false, true, false, false);

        insert newOppProduct;
        //The Total price needs to be caclulated. We can not select it in the SOQL above as this throws an error when cloning.
        //newOppProduct.TotalPrice = newOppProduct.Quantity * newOppProduct.Unit_Price__c;
        
        
        establishSchedule(newOppProduct);

        updateCurrentOppProducts();
        resetPage();
        return null;
    }

    public PageReference deleteProduct() {
        OpportunityLineItem oli = [SELECT Id FROM OpportunityLineItem WHERE id = : oppProductToWorkWithId];
        delete oli;
        resetPage();
        return null;
    }

    public PageReference saveSchedule() {
        upsert oppProductScheduleToEdit;
        renderScheduleView();
        updateCurrentOppProducts();
        return null;
    }

    public PageReference renderProductAdd() {
        headerTitle = 'Add Product for';
        headerSubTitle = 'Opportunity ' + opp.Name;
        doRenderCurrentProducts = false;
        doRenderProductAdd = true;
        doRenderProductEdit = false;
        doRenderScheduleView = false;
        doRenderScheduleEdit = false;
        updateCurrentOppProducts();
        onProductOrPricingChange();
        return null;
    }

    public PageReference renderProductEditFromProducts() {
        editProductReturn = 'products';
        renderProductEdit();
        return null;
    }

    public PageReference renderProductEditFromSchedule() {
        editProductReturn = 'schedule';
        renderProductEdit();
        return null;
    }

    public PageReference renderProductEdit() {
        hasActuals = false;
        maxActualScheduleDate = null;
        maxActualScheduleDateString = null;   
        headerTitle = 'Opportunity Product Edit';
        oppProductToWorkWith = [SELECT Id,OpportunityID,TotalPrice,Total_Price_Custom__c,Verity_Revenue__c, Product2.Name, PriceBookEntryId, Pricing__c, Quantity, UnitPrice, Unit_Price__c, Description, Start_Date__c, End_Date__c, Incremental_New__c,Partner__c,Segment_Type__c,Verity_Deal_ID__c,of_Budget__c, Lightbox__c,Custom_Creative__c,Extended_Animation__c FROM OpportunityLineItem WHERE Id = : oppProductToWorkWithId];
        headerSubTitle = oppProductToWorkWith.Product2.Name;
        if (oppProductToWorkWith.Description != null) {
            headerSubTitle += '-- ' + oppProductToWorkWith.Description;
        }
        if(oppProductToWorkWith.TotalPrice != oppProductToWorkWith.Total_Price_Custom__c){
            oppProductToWorkWith.Total_Price_Custom__c = oppProductToWorkWith.TotalPrice;
            oppProductToWorkWith.Verity_Revenue__c = oppProductToWorkWith.TotalPrice;
        }
        List<OpportunityLineItemSchedule> olisActualList = [SELECT ID,Scheduledate,Actual_Revenue_Verity__c from OpportunityLineItemSchedule where Actual_Revenue_Verity__c>0 AND OpportunityLineItemId= :oppProductToWorkWithId order by ScheduleDate desc LIMIT 1];
        if(olisActualList.size()>0){
            hasActuals = true;
            if(olisActualList[0].Scheduledate!=null){
                maxActualScheduleDate = olisActualList[0].Scheduledate.toStartOfMonth();
                //mm/dd/yyyy
                maxActualScheduleDateString = maxActualScheduleDate.month()+'/'+maxActualScheduleDate.day()+'/'+maxActualScheduleDate.year();
                system.debug(maxActualScheduleDate);
            } 
        }
        productOption = oppProductToWorkWith.PricebookEntryId;
        doRenderCurrentProducts = false;
        doRenderProductAdd = false;
        doRenderProductEdit = true;
        doRenderScheduleView = false;
        doRenderScheduleEdit = false;
        updateCurrentOppProducts();
        return null;
    }

    public PageReference renderScheduleView() {
        headerTitle = 'Opportunity Product';
        oppProductToWorkWith = [SELECT Id, Product2.Name, Quantity, TotalPrice,Total_Price_Custom__c,Verity_Revenue__c, Unit_Price__c, Pricing__c, Start_Date__c, End_Date__c, Description, Incremental_New__c,Partner__c,Segment_Type__c,Verity_Deal_ID__c,of_Budget__c, Lightbox__c,Custom_Creative__c,Extended_Animation__c FROM OpportunityLineItem WHERE Id = : oppProductScheduleToViewId];
        oppProductScheduleToView = [SELECT Id, ScheduleDate, Quantity,Revenue, Verity_Revenue__c, Description FROM OpportunityLineItemSchedule WHERE OpportunityLineItemId = : oppProductScheduleToViewId];
        headerSubTitle = oppProductToWorkWith.Product2.Name;
        if (oppProductToWorkWith.Description != null) {
            headerSubTitle += ' -- ' + oppProductToWorkWith.Description;
        }
        headerSubTitle += ' for ' + opp.Name;
        doRenderCurrentProducts = false;
        doRenderProductAdd = false;
        doRenderProductEdit = false;
        doRenderScheduleView = true;
        doRenderScheduleEdit = false;
        updateCurrentOppProducts();
        return null;
    }

    public PageReference renderScheduleEdit() {
        oppProductToWorkWith = [SELECT Id, Product2.Name, Quantity, TotalPrice,Total_Price_Custom__c,Verity_Revenue__c, Unit_Price__c, Pricing__c, Start_Date__c, End_Date__c, Incremental_New__c,Partner__c,Segment_Type__c,Verity_Deal_ID__c,of_Budget__c, Lightbox__c,Custom_Creative__c,Extended_Animation__c FROM OpportunityLineItem WHERE Id = : oppProductScheduleToEditId];
        oppProductScheduleToEdit = [SELECT Id, ScheduleDate, Quantity, Revenue,Verity_Revenue__c, Description FROM OpportunityLineItemSchedule WHERE OpportunityLineItemId = : oppProductScheduleToEditId];
        headerSubTitle = 'Edit Schedule for ' + oppProductToWorkWith.Product2.Name;
        doRenderCurrentProducts = false;
        doRenderProductAdd = false;
        doRenderProductEdit = false;
        doRenderScheduleView = false;
        doRenderScheduleEdit = true;
        updateCurrentOppProducts();
        return null;
    }

    public PageReference resetPage() {
        doRenderCurrentProducts = true;
        doRenderProductEdit = false;
        doRenderProductAdd = false;
        doRenderScheduleView = false;
        doRenderScheduleEdit = false;
        updateCurrentOppProducts();
        headerTitle = 'Products for';
        headerSubTitle = opp.Name; 
        return null;
    }

    private void CalculatePricing(OpportunityLineItem oppLineItem) {
        if (oppLineItem.Pricing__c == 'VCPM' || oppLineItem.Pricing__c == 'CPM') {
       		oppLineItem.Unit_Price__c = oppLineItem.TotalPrice/(oppLineItem.Quantity / 1000);
           //oppLineItem.UnitPrice =  oppLineItem.UnitPrice / oppLineItem.Quantity;
        } else {
          	oppLineItem.Unit_Price__c = oppLineItem.TotalPrice/oppLineItem.Quantity; 
		  	//oppLineItem.UnitPrice =  oppLineItem.UnitPrice / oppLineItem.Quantity; 
        } 
    }

    public String setCurrencySymbol(String currencyCode) { 
        String symbol = '';
        if (currencyCode == 'CAD') { symbol = '$'; }
        if (currencyCode == 'USD') { symbol = '$'; }
        if (currencyCode == 'GBP') { symbol = '£'; } 
        if (currencyCode == 'EUR') { symbol = '€'; }
        if (currencyCode == 'AUD') { symbol = '$'; }
        
        if (currencyCode == 'HKD') { symbol = 'HK$'; }
        if (currencyCode == 'IDR') { symbol = 'Rp'; }
        if (currencyCode == 'THB') { symbol = '฿'; } 
        if (currencyCode == 'PHP') { symbol = '₱'; }

        return symbol; 
    }

    public class SaveException extends Exception {}
}