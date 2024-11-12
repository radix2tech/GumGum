/*
Description	 : OpportunityTriggerHandler Test Class
Created Date : 9-12-2022
Created By   : Kiran
*/
@isTest
public class OpportunityTriggerHandlerNewTest {
    
    @testSetup
    public static void testData(){
        
        // Insert Trigger Settings for OpportunityContactRole
        Trigger_Setting__c tsOppConRole = new Trigger_Setting__c();
        tsOppConRole.Object_Name__c   = 'OpportunityContactRole';
        tsOppConRole.After_Insert__c = true;
        tsOppConRole.After_Update__c = true;
        tsOppConRole.Before_Delete__c = true;
        tsOppConRole.Prevent_Recursion__c = 'isPrimary';
        tsOppConRole.Name             = 'Opportunity Contact Role';
        insert tsOppConRole;
        //Inserting Account
        Account acc = new Account();
        acc.Name = 'Test';
        acc.Type = '3rd Party Supplier';
        acc.Account_Region__c = '	US - Central';
        acc.Industry = 'Automotive';
        insert acc;
        //Inserting Contacts
        List<Contact> conList = new List<Contact>();
        Contact con1 = new Contact(lastName='Test');
        Contact con2 = new Contact(lastName = 'Test2');
        conList.add(con1);
        conList.add(con2);
        insert conList;
        
    }
    @isTest
    public static void method1(){
        Account acc = [SELECT Id,Name FROM Account limit 1];
        List<Contact> conList = [SELECT Id,Name FROM Contact];
        //Inserting Opportunity
        Opportunity opp1 = new Opportunity(AccountId= acc.id,Agency_Name__c=acc.id,
                                           Start_Date__c = System.Today(),
                                           End_Date__c =System.Today()+ 100,
                                           name = 'Test Opp1',
                                           SalesLoft1__Primary_Contact__c = conList[0].Id,
                                           CloseDate= System.Today()+ 3,
                                           StageName ='Initial call'); 
        insert opp1;
        //After Opportunity Insert, Querying Primary OpportunityContactRole
        List<OpportunityContactRole> oppConRole = [SELECT Id,OpportunityId,ContactId,IsPrimary FROM OpportunityContactRole Limit 1];
        system.assertEquals(conList[0].Id, oppConRole[0].ContactId); 
        
        //Updating OpportunityContactRole 
        oppConRole[0].isPrimary = false;
        update oppConRole;
        Opportunity newOpp1 = [SELECT ID,SalesLoft1__Primary_Contact__c FROM Opportunity Limit 1];
        system.Assert(newOpp1.SalesLoft1__Primary_Contact__c ==Null);
        /*//Updating Opportunity with new Primary Contact - Update test
        opp1.SalesLoft1__Primary_Contact__c = conList[1].Id;
        update opp1;
        List<OpportunityContactRole> newOppConRole = [SELECT Id,OpportunityId,ContactId,IsPrimary FROM
                                                   OpportunityContactRole WHERE OpportunityId=:opp1.Id AND isPrimary=True];
        system.assertEquals(conList[1].Id, newOppConRole[0].ContactId);*/
    }

}