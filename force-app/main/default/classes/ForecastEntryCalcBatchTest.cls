@isTest
public class ForecastEntryCalcBatchTest {
	
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

        // Create a task with a due date in the past
        Task pastTask = new Task(
            Subject = 'Follow Up',
            WhatId = testAccount.Id,
            ActivityDate = Date.today().addDays(-10), // 10 days in the past
            Status = 'Not Started',
            Priority = 'Normal'
        );
        insert pastTask;
        
        // Create an event with a start date and end date in the past
        Event pastEvent = new Event(
            Subject = 'Past Meeting',
            WhatId = testAccount.Id,
            StartDateTime = DateTime.now().addDays(-7).addHours(-2), // 7 days and 2 hours in the past
            EndDateTime = DateTime.now().addDays(-7).addHours(-1),   // 7 days and 1 hour in the past
            DurationInMinutes = 60,
            Location = 'Conference Room',
            Description = 'Test meeting for past event',
            IsAllDayEvent = false
        );
        insert pastEvent;
        
        Account agencyAccount = new Account(Name = 'Test Agency');
        insert agencyAccount;

        // Create a task with a due date in the past
        Task pastTask1 = new Task(
            Subject = 'Follow Up',
            WhatId = agencyAccount.Id,
            ActivityDate = Date.today().addDays(-10), // 10 days in the past
            Status = 'Not Started',
            Priority = 'Normal'
        );
        insert pastTask1;
        
        // Create an event with a start date and end date in the past
        Event pastEvent1 = new Event(
            Subject = 'Past Meeting',
            WhatId = agencyAccount.Id,
            StartDateTime = DateTime.now().addDays(-7).addHours(-2), // 7 days and 2 hours in the past
            EndDateTime = DateTime.now().addDays(-7).addHours(-1),   // 7 days and 1 hour in the past
            DurationInMinutes = 60,
            Location = 'Conference Room',
            Description = 'Test meeting for past event',
            IsAllDayEvent = false
        );
        insert pastEvent1;
        
        Advertiser_Agency_Relationship__c aar = new Advertiser_Agency_Relationship__c(
            Advertiser__c = testAccount.Id
            //Agency__c = agencyAccount.Id
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

       

        // Create Advertiser-Agency Relationship
        Advertiser_Agency_Relationship__c aar2 = new Advertiser_Agency_Relationship__c(
            Advertiser__c = testAccount.Id,
            Agency__c = agencyAccount.Id
        );
        insert aar2;
        
        Id pricebookId = Test.getStandardPricebookId();
        
        Product2 prd1 = new Product2 (Name='Video Solution - OLV',Description='Test Product Entry 1',productCode = 'ABC', isActive = true,CanUseQuantitySchedule =true,CanUseRevenueSchedule=true);
        insert prd1;
        
        PricebookEntry pbe1 = new PricebookEntry (Product2ID=prd1.id,Pricebook2ID=pricebookId,UnitPrice=50, isActive=true);
        insert pbe1;
        
        Id ActivationRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Activation').getRecordTypeId();

        Opportunity opp = new Opportunity(AccountId= testAccount.id,RecordTypeId = ActivationRecordTypeId,/*Agency_Name__c=testAccount.id,*/Start_Date__c = System.Today(),End_Date__c =System.Today()+ 100 ,name = 'Test Opp',CloseDate= System.Today()+ 3 ,Pricebook2Id = pbe1.Pricebook2Id, StageName ='Opportunity Identified' );
        insert opp;
        
        opportunity getOpp = [SELECT ID,pricebook2Id,stageName from opportunity where Id = :opp.Id];
        getOpp.Pricebook2Id = pricebookId;
        getOpp.StageName = 'Closed/Won';
        
        update getOpp;
        

        // Query an existing OpportunitySplitType
        /*OpportunitySplitType splitType = [SELECT Id, IsActive FROM OpportunitySplitType WHERE IsActive = TRUE AND DeveloperName = 'Overlay' LIMIT 1];

        // Create an OpportunitySplit record
        OpportunitySplit oppSplit = new OpportunitySplit(
            OpportunityId = opp.Id,
            SplitTypeId = splitType.Id,
            SplitPercentage = 100,
            SplitOwnerId = UserInfo.getUserId()
        );
        insert oppSplit;*/

        system.debug('##### '+[select id,SplitPercentage,OpportunityId,SplitOwnerId,Opportunity.recordtype.Name,opportunity.stageName,Opportunity.AccountId from OpportunitySplit]);

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
        
        OpportunityLineItemSchedule oliSched1 = new OpportunityLineItemSchedule(
            OpportunityLineItemId = opl1.Id,
            Type = 'Both',
            Quantity = 2,
            Revenue = 200,Verity_Revenue__c = 10,
            ScheduleDate = Date.today().addYears(-1)
        );
        
        insert oliSched1;
        
        OpportunityLineItemSchedule oliSched2 = new OpportunityLineItemSchedule(
            OpportunityLineItemId = opl1.Id,
            Type = 'Both',
            Quantity = 2,
            Revenue = 200,Verity_Revenue__c = 10,
            ScheduleDate = Date.today().addYears(+1)
        );
        
        insert oliSched2;
         
         Forecast_Entry__c forecastEntry = new Forecast_Entry__c(
            Product__c = 'Core Media',
            Forecast_Q1__c = 1000,
            Forecast_Q2__c = 2000,
            AAR_Split_Owner__c = splitOwner.Id,
            IsActive__c = true
        );
        insert forecastEntry;
    }

	@IsTest
    static void testforecastEntries() {
        setupTestData();

        Test.startTest();

        Database.executeBatch(new ForecastEntryCalcBatch(), 200);
        Test.stopTest();

    }

}