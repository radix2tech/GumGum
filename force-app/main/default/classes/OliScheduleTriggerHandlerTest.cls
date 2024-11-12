@isTest
private class OliScheduleTriggerHandlerTest {

	//private static OpportunityLineItem setupOli() {

	//	Product2 p = new Product2(
	//		Name = 'Test Product',
	//		CanUseRevenueSchedule = true);
	//	insert p;

	//	Id standardPbId = Test.getStandardPricebookId();
	//	PricebookEntry standardPbe = new PricebookEntry(
	//		Pricebook2Id = standardPbId,
	//		Product2Id = p.Id,
	//		UnitPrice = 5.00,
	//		IsActive = true);
	//	insert standardPbe;

	//	Pricebook2 pb = new Pricebook2(
	//		Name = 'Test Price Book',
	//		IsActive = true);
	//	insert pb;

	//	PricebookEntry pbe = new PricebookEntry(
	//		Pricebook2Id = pb.Id,
	//		Product2Id = p.Id,
	//		UnitPrice = 10.00,
	//		IsActive = true);
	//	insert pbe;

	//	Account acct = new Account(Name = 'Test Account');
	//	insert acct;

	//	Opportunity opp = new Opportunity(
	//		Name = 'Test Opp',
	//		AccountId = acct.Id,
	//		Agency_Name__c = acct.Id,
	//		Type = 'Existing Business',
	//		ForecastCategoryName = 'Pipeline',
	//		CurrencyIsoCode = 'USD',
	//		Start_Date__c = Date.today().addDays(1),
	//		End_Date__c = Date.today().addDays(8),
	//		StageName = 'Closed/Won',
	//		CloseDate = Date.today());
	//	opp.Pricebook2Id = pb.Id;
	//	insert opp;

	//	OpportunityLineItem oli = new OpportunityLineItem(
	//		OpportunityId = opp.Id,
	//		PricebookEntryId = pbe.Id,
	//		UnitPrice = 20.00,
	//		Quantity = 5.00);
	//	insert oli;

	//	return oli;
	//}
	
	//@isTest static void test_add_schedule() {
	//	List<OpportunityLineItemSchedule> lstOliSchedules = new List<OpportunityLineItemSchedule>();
	//	Date expectedStart = Date.today().addDays(5);
	//	Date expectedEnd = Date.today().addDays(20);
	//	OpportunityLineItem oli = setupOli();

	//	for (Integer i = 5; i < 25; i = i + 5) {
	//		OpportunityLineItemSchedule oliSchedule = new OpportunityLineItemSchedule(
	//			OpportunityLineItemId = oli.Id,
	//			Type = 'Revenue',
	//			Revenue = 5.00,
	//			ScheduleDate = Date.today().addDays(i));
	//		lstOliSchedules.add(oliSchedule);
	//	}

	//	insert lstOliSchedules;

	//	List<Opportunity> lstOpp = [SELECT Id, Start_Date__c, End_Date__c
	//								FROM Opportunity
	//								WHERE Id = :oli.OpportunityId ];

	//	Opportunity opp = lstOpp[0];

	//	System.assertEquals(expectedStart, opp.Start_Date__c);
	//	System.assertEquals(expectedEnd, opp.End_Date__c);
	//}
	
}