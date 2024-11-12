/*
	Description	   : OpportunityContactRoleTriggerHandler test Class
	Created Date   : 09-12-2022
	Created By     : Kiran
	Change Request : 
*/
@isTest
public class OpportunityContactRoleTriggerHandlerTest {
    
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
        //Inserting Opportunity
        Opportunity opp1 = new Opportunity(AccountId= acc.id,Agency_Name__c=acc.id,
                                           Start_Date__c = System.Today(),
                                           End_Date__c =System.Today()+ 100,
                                           name = 'Test Opp1',
                                           SalesLoft1__Primary_Contact__c = conList[0].Id,
                                           CloseDate= System.Today()+ 3,
                                           StageName ='Initial call'); 
        insert opp1;
    }
    @isTest
    static void method1(){
        
        Opportunity opp = [SELECT Id,SalesLoft1__Primary_Contact__c FROM Opportunity LIMIT 1];
        List<Contact> conList = [SELECT Id FROM Contact];
        //Updating OpportunityContactRole(unchecking primary)
        OpportunityContactRole oppConRole = [SELECT Id,ContactId,OpportunityId,IsPrimary FROM OpportunityContactRole WHERE OpportunityId = :opp.Id AND IsPrimary=true LIMIT 1];
        oppConRole.IsPrimary = false;
        update oppConRole;
        
        Opportunity newOpp = [SELECT Id,SalesLoft1__Primary_Contact__c FROM Opportunity LIMIT 1];
        System.Assert(newOpp.SalesLoft1__Primary_Contact__c==null);
        
        //Inserting New Primary OpportunityContactRole
        OpportunityContactRole oppConRole2 = new OpportunityContactRole(OpportunityId=opp.Id,ContactId = conList[1].Id,IsPrimary=true);
        insert oppConRole2;
        
        Opportunity newOpp2 = [SELECT Id,SalesLoft1__Primary_Contact__c FROM Opportunity LIMIT 1];
        System.assertEquals(oppConRole2.contactId, newOpp2.SalesLoft1__Primary_Contact__c);
        
        //Changing the Primary OpportunityContactRole to other OpportunityContactRole
        OpportunityContactRole oppConRole3 = [SELECT Id,ContactId,OpportunityId,IsPrimary FROM OpportunityContactRole WHERE OpportunityId = :opp.Id AND IsPrimary=false LIMIT 1];
        oppConRole3.isPrimary = true;
        update oppConRole3;
        
        Opportunity newOpp3 = [SELECT Id,SalesLoft1__Primary_Contact__c FROM Opportunity LIMIT 1];
        System.assertEquals(oppConRole3.contactId, newOpp3.SalesLoft1__Primary_Contact__c); 
        
        //Trying to delete primary Contact
        Database.delete(oppConRole3,false);

    }
}