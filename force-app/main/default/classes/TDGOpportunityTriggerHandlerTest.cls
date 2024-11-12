@isTest
public class TDGOpportunityTriggerHandlerTest {
    @isTest
    static void testUpdateRegion() {
        User u = new User(ID = UserInfo.getUserId(), User_Region__c = 'US - West');
        update u;

        Test.startTest();
        Account acc = new Account(Name = 'Test');
        insert acc;

        Opportunity opp = new Opportunity(
            Name = 'Test',
            AccountId = acc.Id,
            StageName = 'Prospecting',
            CloseDate = Date.today()
        );

        insert opp;

        Test.stopTest();

        opp = [select Id, Opportunity_Region__c from Opportunity where Id = :opp.Id];
        System.assertEquals('US - West', opp.Opportunity_Region__c);
        update opp;
        System.assertEquals('US - West', opp.Opportunity_Region__c);
    }
}