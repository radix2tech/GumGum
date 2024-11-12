@isTest
public class OpportunityLineItemScheduleTest {
    @isTest
    static void testTrigger() {
        Account acc = new Account(
            Name = 'Test',
            Industry = 'Test'
        );
        insert acc;
        
        Contact con = new Contact(
            AccountId = acc.Id,
            FirstName = 'Test',
            LastName = 'Test',
            Email = 'test@test.com',
            Phone = '555-555-5555'
        );
        
        insert con;
        
        Opportunity opp = new Opportunity(
            AccountId = acc.Id,
            Name = 'Test',
            StageName = 'Prospecting',
            CloseDate = Date.today(),
            SalesLoft1__Primary_Contact__c = con.Id
        );
        
        insert opp;
        opp.Pricebook2Id = Test.getStandardPricebookId();
        update opp;
        
        Product2 prod = new Product2(
            Name = 'Test',
            IsActive = true,
            CanUseQuantitySchedule = true,
            CanUseRevenueSchedule = true
        );
        
        insert prod;
        
        PricebookEntry pbEnt = new PricebookEntry(
            Product2Id = prod.Id,
            Pricebook2Id = Test.getStandardPricebookId(),
            UnitPrice = 100,
            IsActive = true
        );
        
        insert pbEnt;
        
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            PricebookEntryId = pbEnt.Id,
            UnitPrice = 100,
            Quantity = 2
        );
        
        insert oli;
        
        OpportunityLineItemSchedule oliSched = new OpportunityLineItemSchedule(
            OpportunityLineItemId = oli.Id,
            Type = 'Both',
            Quantity = 2,
            Revenue = 200,
            ScheduleDate = Date.today()
        );
        
        insert oliSched;
    }
}