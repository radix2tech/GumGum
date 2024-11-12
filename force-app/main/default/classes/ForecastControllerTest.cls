@IsTest
public class ForecastControllerTest {

    // Create necessary test data for tests
    private static void setupTestData() {
        
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

        Account testAccount = new Account(Name = 'Test Advertiser');
        insert testAccount;
        
        Account agencyAccount = new Account(Name = 'Test Agency');
        insert agencyAccount;

        Advertiser_Agency_Relationship__c aar = new Advertiser_Agency_Relationship__c(
            Advertiser__c = testAccount.Id,
            Agency__c = agencyAccount.Id
        );
        insert aar;

        Account_Forecast__c forecast = new Account_Forecast__c(
            Advertiser_Agency_Relationship__c = aar.Id,
            Bookings_Current_Year__c = 10000,
            Pipeline_Current_Quarter__c = 5000
        );
        insert forecast;

        AAR_Split_Owner__c splitOwner = new AAR_Split_Owner__c(
            Advertiser_Agency_Relationship__c = aar.Id,
            Is_Active__c = true
        );
        insert splitOwner;

        Forecast_Entry__c forecastEntry = new Forecast_Entry__c(
            Product__c = 'CTV',
            Forecast_Q1__c = 1000,
            Forecast_Q2__c = 2000,
            AAR_Split_Owner__c = splitOwner.Id,
            IsActive__c = true
        );
        insert forecastEntry;

        // Create Advertiser-Agency Relationship
        Advertiser_Agency_Relationship__c aar2 = new Advertiser_Agency_Relationship__c(
            Advertiser__c = testAccount.Id
        );
        insert aar2;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        Product2 prd1 = new Product2 (Name='Video Solution - OLV',Description='Test Product Entry 1',productCode = 'ABC', isActive = true,CanUseQuantitySchedule =true,CanUseRevenueSchedule=true);
        insert prd1;
        
        PricebookEntry pbe1 = new PricebookEntry (Product2ID=prd1.id,Pricebook2ID=pricebookId,UnitPrice=50, isActive=true);
        insert pbe1;
        
        Opportunity opp = new Opportunity(AccountId= testAccount.id,Agency_Name__c=testAccount.id,Start_Date__c = System.Today(),End_Date__c =System.Today()+ 100 ,name = 'Test Opp',CloseDate= System.Today()+ 3 ,Pricebook2Id = pbe1.Pricebook2Id, StageName ='Opportunity Identified' );
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
    }

    @IsTest
    static void testGetForecastEntries() {
        setupTestData();
        String AccountId;
        Forecast_Entry__c FE = [Select id from Forecast_Entry__c limit 1];
        List<String> Ids = new List<String>();
        Ids.add(FE.Id);
        Test.startTest();
        ForecastController.ReturnDataClass result = ForecastController.getForecastEntries(AccountId);
        
        result.returnDataList[0].isChanged=true;
        result.returnDataList[0].TradingDeal=true;
        
        ForecastController.processData(result.returnDataList, Ids);
        
        Test.stopTest();
    }

    @IsTest
    static void testRunBatchJob() {
        setupTestData();

        Boolean disableBatchButton = false;

        Test.startTest();
        Boolean result = ForecastController.runBatchJob(disableBatchButton);
        Test.stopTest();

    }

    @IsTest
    static void testGetUsers() {
        setupTestData();

        Test.startTest();
        List<User> users = ForecastController.getUsers('Geeth');
        Test.stopTest();

        System.assert(users.size() > 0, 'Expected some users in the result');
    }

    @IsTest
    static void testGetAARs() {
        setupTestData();

        Test.startTest();
        List<Advertiser_Agency_Relationship__c> aarList = ForecastController.getAARs('Test');
        Test.stopTest();

    }

    @IsTest
    static void testCreateSplitOwner() {
        setupTestData();
		Advertiser_Agency_Relationship__c AAR = [Select Id from Advertiser_Agency_Relationship__c limit 1];
        Test.startTest();
        ForecastController.createSplitOwner(AAR.Id);
        Test.stopTest();

        List<AAR_Split_Owner__c> activeSplits = [SELECT Id FROM AAR_Split_Owner__c WHERE Is_Active__c = true];
        System.assert(activeSplits.size() > 0, 'Expected at least one active split owner record');
    }

    @IsTest
    static void testRemoveAAR() {
        setupTestData();

        AAR_Split_Owner__c aarSplit = [SELECT Id FROM AAR_Split_Owner__c LIMIT 1];

        Test.startTest();
        ForecastController.removeAAR(aarSplit.Id);
        Test.stopTest();

        AAR_Split_Owner__c updatedSplit = [SELECT Is_Active__c FROM AAR_Split_Owner__c WHERE Id = :aarSplit.Id];
        System.assertEquals(false, updatedSplit.Is_Active__c, 'Expected the split owner to be inactive');
    }

    @IsTest
    static void testSubmitForApproval() {
        setupTestData();

        Account_Forecast__c forecast = [SELECT Id FROM Account_Forecast__c LIMIT 1];
        User testUser = [SELECT Id FROM User LIMIT 1];

        Test.startTest();
        ForecastController.submitForApproval(forecast.Id, testUser.Id);
        Test.stopTest();

    }
}