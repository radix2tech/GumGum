@isTest
public class TDGAccountTriggerHandlerTest {
    @isTest
    static void testUpdateRegion() {
        User u = new User(ID = UserInfo.getUserId(), User_Region__c = 'US - West');
        update u;
        User billingIntegrationUser= [SELECT ID FROM User WHERE Name='Billing Integrations'];

        Test.startTest();
        Account acc = new Account(Name = 'Test');
        insert acc;
        
        Id billingEntityRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.Billing_Entity_Record_Type).getRecordTypeId();
        Account acc2 = new Account(Name = 'Test2',RecordTypeId=billingEntityRecordTypeId,Account_Region__c='EMEA - Belgium');
        insert acc2;
        Test.stopTest();
        
        acc = [select Id, Account_Region__c from Account where Id = :acc.Id];
        System.assertEquals('US - West', acc.Account_Region__c);
        update acc;
        System.assertEquals('US - West', acc.Account_Region__c);
        
        acc2 = [select Id, Account_Region__c from Account where Id = :acc2.Id];
        System.assertEquals('US - West', acc2.Account_Region__c);
        update acc2;
        System.assertEquals('US - West', acc2.Account_Region__c);
        
        System.runAs(billingIntegrationUser){
            Account acc3 = new Account(Name='Test 3',RecordTypeId=billingEntityRecordTypeId,Account_Region__c= 'EMEA - Netherlands');
            insert acc3;
            acc3 = [select Id, Account_Region__c from Account where Id = :acc3.Id];
            System.assertEquals('EMEA - Netherlands', acc3.Account_Region__c);
        }
    }
}