/*
 Change Request : CR-001(01-04-2024) - Deactivated Light Box and Extended Animation
*/

public with sharing class EB_OpportunityProductsExt {

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
    public String verityDealId {get;set;}
    public Boolean renderSaveProductForVideoSoultionProducts { get; set; }
    public Boolean hasActuals {get; set;}
    public Date maxActualScheduleDate{get; set;}
    public String maxActualScheduleDateString {get; set;}

    private Id standardPriceBookId;
    private static final Double DIVISOR = 1000.0;
    
    public Pricebook2 stdobjPb {get; set;}

    public EB_OpportunityProductsExt(ApexPages.StandardController stdController) {
        this.opp = (Opportunity) stdController.getRecord();

        opp = [SELECT Id, Name, Pricebook2Id, Start_Date__c, End_Date__c, CurrencyIsoCode,RecordType.Name
               FROM Opportunity
               WHERE Id = :opp.Id];


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
        pricingOptions.add(new SelectOption('', '-- Select --'));
        incrementalOptions.add(new SelectOption('', '-- Select --'));
        Schema.DescribeFieldResult fieldResult = Product2.Pricing__c.getDescribe();
        List<Schema.PicklistEntry> ples = fieldResult.getPicklistValues();
        for ( Schema.PicklistEntry ple : ples) {
             If(opp.RecordType.Name != 'Verity - Demand' && ple.getLabel() == '% of Media'){
                continue;
            }
            pricingOptions.add(new SelectOption(ple.getLabel(), ple.getValue()));
        }
        
        Schema.DescribeFieldResult IncrementfieldResult = OpportunityLineItem.Incremental_New__c.getDescribe();
        List<Schema.PicklistEntry> Iples = IncrementfieldResult.getPicklistValues();
        for ( Schema.PicklistEntry ple : Iples) {
            incrementalOptions.add(new SelectOption(ple.getLabel(), ple.getValue()));
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
        if (pricingOption == null) {
            pricingError = true;
        }
        if (productOption == null) {
            productError = true;
        }
        // Added logic to set the lightbox, customcreative, and extendedanimation to false.
        //Retrieve profile name
		String profileName = [SELECT Name FROM Profile WHERE Id =: userInfo.getProfileId()].Name;
        lightbox          = false;
        extendedanimation = false;
        if(profileName.contains('Playground')){ 
            customcreative    = false; 
        } 
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
        if (!pricingError && !productError && !quantityError && !priceError) {
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
            oli.TotalPrice = dblPrice;  
            //oli.UnitPrice = dblPrice;
            
           // oli.Unit_Price__c = dblPrice/(dblQuantForCpm/1000);
            oli.Incremental_New__c = incremental;
            oli.Lightbox__c = lightbox;
            oli.Custom_Creative__c = customcreative;
            oli.Extended_Animation__c = extendedanimation;
            oli.Verity_Deal_ID__c = verityDealId;
            
            //Checkin If the selecated product is Video Solution OLV or Video Solution CTV
			PriceBookEntry getPriceBookEntry = [SELECT ID,Product2.Name FROM PriceBookEntry WHERE ID = :productOption];
            if(getPriceBookEntry.Product2.Name =='Video Solution - CTV' || getPriceBookEntry.Product2.Name =='Video Solution - OLV' ){
                //Making Verity Revenue 4% of Total Price
                oli.Verity_Revenue__c = dblPrice*0.04; 
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
                       Start_Date__c,
                       End_Date__c,
                       Description,
                       Incremental_New__c,
                       Lightbox__c,
                       Custom_Creative__c,
                       Extended_Animation__c,
                       Name,
                       Net_Total_Price__c,
                       Verity_Deal_ID__c,
                       Verity_Revenue__c,
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
        OpportunityLineItem newOli = [SELECT ID,Product_Name_Text__c FROM OpportunityLineItem WHERE id = :oli.Id];
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
            if(newOli.Product_Name_Text__c == 'Video Solution - CTV' || newOli.Product_Name_Text__c == 'Video Solution - OLV'){
              olis.Verity_Revenue__c = scheduleRevenueRounded*0.04;  
            }
            listOlis.add(olis);
            endOfMonth = endOfMonth.addMonths(2);
            endOfMonth = endOfMonth.toStartOfMonth();
            endOfMonth = endOfMonth.addDays(-1);
        }
        insert(listOlis);
        return null;
    }
    
    public PageReference establishSchedule(OpportunityLineItem oli,List<OpportunityLineItemSchedule> actualOlis) {
        
        Map<Date,Double> scheduleDate2ActualRevenueMap = new Map<date,Double>();
        for(OpportunityLineItemSchedule olis: actualOlis){
            scheduleDate2ActualRevenueMap.put(olis.ScheduleDate,olis.Actual_Revenue_Verity__c);
        }
        
        OpportunityLineItem newOli = [SELECT ID,Product_Name_Text__c FROM OpportunityLineItem WHERE id = :oli.Id];
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
            if(newOli.Product_Name_Text__c == 'Video Solution - CTV' || newOli.Product_Name_Text__c == 'Video Solution - OLV'){
              olis.Verity_Revenue__c = scheduleRevenueRounded*0.04;  
            }
            if(scheduleDate2ActualRevenueMap.containsKey(olis.ScheduleDate)){
                olis.Actual_Revenue_Verity__c = scheduleDate2ActualRevenueMap.get(olis.ScheduleDate);
            }
            listOlis.add(olis);
            endOfMonth = endOfMonth.addMonths(2);
            endOfMonth = endOfMonth.toStartOfMonth();
            endOfMonth = endOfMonth.addDays(-1);
        }
        insert(listOlis);
        return null;
    }

    public PageReference establishNewSchedule(Id oppId, Id oliId) {
        OpportunityLineItem oli = [SELECT Id, Quantity, TotalPrice, Total_Price_Custom__c,Start_Date__c, End_Date__c, Incremental_New__c, Lightbox__c,Custom_Creative__c,Extended_Animation__c,Verity_Deal_ID__c,Verity_Revenue__c FROM OpportunityLineItem WHERE Id = : oliId];

        oli.Start_Date__c = opp.Start_Date__c;
        oli.End_Date__c = opp.End_Date__c;
        update oli;

        oli = [SELECT Id, Quantity, TotalPrice,Total_Price_Custom__c, Start_Date__c, End_Date__c, Incremental_New__c, Lightbox__c,Custom_Creative__c,Extended_Animation__c,Verity_Deal_ID__c,Verity_Revenue__c FROM OpportunityLineItem WHERE Id = : oliId];

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

            OpportunityLineItem tempOp = New OpportunityLineItem();
            //tempOp.Id = changeProduct.Id;
            tempOp.OpportunityId = changeProduct.OpportunityId;
            tempOp.Quantity = changeProduct.Quantity;
            //tempOp.Quantity = changeProduct.Quantity;
           // tempOp.Unit_Price__c = changeProduct.TotalPrice/changeProduct.Quantity;
            
            tempOp.Total_Price_Custom__c = changeProduct.Total_Price_Custom__c;
            tempOp.TotalPrice = changeProduct.Total_Price_Custom__c;  
            tempOp.Pricing__c = changeProduct.Pricing__c;
            tempOp.Start_Date__c = changeProduct.Start_Date__c;
            tempOp.End_Date__c = changeProduct.End_Date__c;
            tempOp.Description = changeProduct.Description;
            tempOp.Incremental_New__c= changeProduct.Incremental_New__c;
            tempOp.Lightbox__c = changeProduct.Lightbox__c;
            tempOp.Custom_Creative__c = changeProduct.Custom_Creative__c;
            tempOp.Extended_Animation__c = changeProduct.Extended_Animation__c;
            tempOp.PriceBookEntryId = productOption;
            tempOp.Verity_Deal_ID__c = changeProduct.Verity_Deal_ID__c;
            
            /*//Make changes for Verity Revenue
            PriceBookEntry getPriceBookEntry = [SELECT ID,Product2.Name FROM PriceBookEntry WHERE ID = :productOption];
            if(getPriceBookEntry.Product2.Name =='Video Solution - CTV' || getPriceBookEntry.Product2.Name =='Video Solution - OLV' ){
                //Making Verity Revenue 4% of Total Price
                tempOp.Verity_Revenue__c = changeProduct.Total_Price_Custom__c*0.04;
            }*/
            if(changeProduct.Product2.Name =='Video Solution - CTV' || changeProduct.Product2.Name =='Video Solution - OLV' ){
                //Making Verity Revenue 4% of Total Price
                tempOp.Verity_Revenue__c = changeProduct.Total_Price_Custom__c*0.04;
            }        
            CalculatePricing(tempOp); 
            insert tempOp;
            delete changeProduct; 
            
            changeProduct=[SELECT ID, TotalPrice,Total_Price_Custom__c, Start_Date__c, End_Date__c, Quantity, Incremental_New__c, Lightbox__c,Custom_Creative__c,Extended_Animation__c,Verity_Deal_ID__c,Verity_Revenue__c FROM OpportunityLineItem WHERE Id=:tempOp.Id];
            
            if(hasActuals){
                establishSchedule(changeProduct,olis); 
            }else{
                reestablishSchedule(changeProduct);  
            }
            
            oppProductScheduleToViewId = changeProduct.Id; 
            renderScheduleView();
        } catch (Exception e) {
            Database.rollback(sp);
            throw new SaveException('An error occurred saving record. ' + e.getMessage() + ' Line: ' + e.getLineNumber());
            System.debug(e.getMessage());
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
			newOppProduct.TotalPrice = oppProductToWorkWith.Total_Price_Custom__c;
            
             PriceBookEntry getPriceBookEntry = [SELECT ID,Product2.Name FROM PriceBookEntry WHERE ID = :productOption];
            if(getPriceBookEntry.Product2.Name =='Video Solution - CTV' || getPriceBookEntry.Product2.Name =='Video Solution - OLV' ){
                //Making Verity Revenue 4% of Total Price
                newOppProduct.Verity_Revenue__c = oppProductToWorkWith.Total_Price_Custom__c*0.04;
            }else{
                newOppProduct.Verity_Revenue__c = null;
            }
            
            CalculatePricing(newOppProduct);
            
            newOppProduct.UnitPrice=null;
            
            insert newOppProduct;
            delete oppProductToWorkWith;
            
            newOppProduct=[SELECT ID, TotalPrice,Total_Price_Custom__c, Start_Date__c, End_Date__c, Quantity, Incremental_New__c, Lightbox__c,Custom_Creative__c,Extended_Animation__c,Verity_Deal_ID__c,Verity_Revenue__c FROM OpportunityLineItem WHERE Id=:newOppProduct.Id];
            
            if(hasActuals){
                establishSchedule(newOppProduct,olis);  
            }else{
                establishSchedule(newOppProduct);
            }

            updateCurrentOppProducts();
        } catch (Exception e) {
            Database.rollback(sp);
            throw new SaveException('An error occurred updating record. ' + e.getMessage() + ' Line: ' + e.getLineNumber());
            System.debug(e.getMessage());
        }
        resetPage();
        return null;
    }

    public PageReference cloneProduct() {
        oppProductToWorkWith = [SELECT Id, TotalPrice,OpportunityId,Total_Price_Custom__c, Product2.Name, PriceBookEntryId, Pricing__c, Quantity, Unit_Price__c, Description, Start_Date__c, End_Date__c, Incremental_New__c, Lightbox__c,Custom_Creative__c,Extended_Animation__c,Verity_Deal_ID__c,Verity_Revenue__c FROM OpportunityLineItem WHERE Id = : oppProductToWorkWithId];
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
        renderSaveProductForVideoSoultionProducts = false;
        hasActuals = false;
        maxActualScheduleDate = null;
        maxActualScheduleDateString = null;  
        headerTitle = 'Opportunity Product Edit';
        oppProductToWorkWith = [SELECT Id, OpportunityID,TotalPrice,Total_Price_Custom__c, Product2.Name, PriceBookEntryId, Pricing__c, Quantity, UnitPrice, Unit_Price__c, Description, Start_Date__c, End_Date__c, Incremental_New__c, Lightbox__c,Custom_Creative__c,Extended_Animation__c,PricebookEntry.Product2.Name,Verity_Deal_ID__c,Verity_Revenue__c FROM OpportunityLineItem WHERE Id = : oppProductToWorkWithId];
        headerSubTitle = oppProductToWorkWith.Product2.Name;
        if (oppProductToWorkWith.Description != null) {
            headerSubTitle += '-- ' + oppProductToWorkWith.Description;
        }
        if(oppProductToWorkWith.TotalPrice != oppProductToWorkWith.Total_Price_Custom__c){
            oppProductToWorkWith.Total_Price_Custom__c = oppProductToWorkWith.TotalPrice;
        }
        
        if(oppProductToWorkWith.PricebookEntry.Product2.Name=='Video Solution - OLV' || oppProductToWorkWith.PricebookEntry.Product2.Name=='Video Solution - CTV'){
            renderSaveProductForVideoSoultionProducts = true; 
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
        oppProductToWorkWith = [SELECT Id, Product2.Name, Quantity, TotalPrice,Total_Price_Custom__c, Unit_Price__c, Pricing__c, Start_Date__c, End_Date__c, Description, Incremental_New__c, Lightbox__c,Custom_Creative__c,Extended_Animation__c,Verity_Revenue__c,Verity_Deal_ID__c FROM OpportunityLineItem WHERE Id = : oppProductScheduleToViewId];
        oppProductScheduleToView = [SELECT Id, ScheduleDate, Quantity, Revenue, Description,Verity_Revenue__c FROM OpportunityLineItemSchedule WHERE OpportunityLineItemId = : oppProductScheduleToViewId];
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
        oppProductToWorkWith = [SELECT Id, Product2.Name, Quantity, TotalPrice,Total_Price_Custom__c, Unit_Price__c, Pricing__c, Start_Date__c, End_Date__c, Incremental_New__c, Lightbox__c,Custom_Creative__c,Extended_Animation__c FROM OpportunityLineItem WHERE Id = : oppProductScheduleToEditId];
        oppProductScheduleToEdit = [SELECT Id, ScheduleDate, Quantity, Revenue, Description,Verity_Revenue__c FROM OpportunityLineItemSchedule WHERE OpportunityLineItemId = : oppProductScheduleToEditId];
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