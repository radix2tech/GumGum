@isTest
private class CampaignMemTriggerHandlerTest {
    @testSetup static void setup() {
        // Insert Trigger Settings
        Trigger_Setting__c ts = new Trigger_Setting__c();
        ts.Object_Name__c   = 'CampaignMember';
        ts.After_Insert__c = true;	
        ts.Before_Insert__c = true;
        ts.After_Undelete__c = true;
        ts.Before_Update__c = true;
        ts.After_Delete__c  = true;
        ts.Before_Delete__c = true;
        ts.After_Update__c  = true;
        ts.Name             = 'Campaign Member';
        ts.Prevent_Recursion__c = 'HasResponded';
        insert ts;
         Id campRecordTypeId = Schema.SObjectType.Campaign.getRecordTypeInfosByName().get('Campaign').getRecordTypeId(); 
         system.debug('@@@campRecordTypeId'+campRecordTypeId);
        // Insert Campaign
        Campaign camp  = new Campaign();
        camp.Name = 'Test Campaign';
        camp.Region__c = 'Europe';
        camp.Type  =  'Email';
        camp.StartDate = date.today();
        camp.EndDate   = date.today() +30;
        camp.Location__c = 'Conference';
        camp.BudgetedCost = 1000;
        camp.RecordTypeId = campRecordTypeId;
        insert camp;
        // Insert Second Campaign
        Campaign camp2  = new Campaign();
        camp2.Name = 'Test Campaign1';
        camp2.Region__c = 'Europe';
        camp2.Type  =  'Email';
        camp2.StartDate = date.today();
        camp2.EndDate   = date.today() +30;
        camp2.Location__c = 'Conference';
        camp2.BudgetedCost = 1000;
        camp2.RecordTypeId = campRecordTypeId; 
        insert camp2;
        
        // Insert Third Campaign
        Campaign camp3  = new Campaign();
        camp3.Name = 'Test Campaign1';
        camp3.Region__c = 'Europe';
        camp3.Type  =  'Email';
        camp3.StartDate = date.today();
        camp3.EndDate   = date.today() +30;
        camp3.Location__c = 'Conference';
        camp3.BudgetedCost = 1000;
        camp3.RecordTypeId = campRecordTypeId;
        insert camp3;

        // Insert Lead
        Lead lead = new Lead();
        lead.FirstName = 'testlead';
        lead.LastName = 'campaignTest';
        lead.Email    = 'testlead@gumgum.com';
        lead.Status = 'Open';
        lead.Company = 'NA';
        lead.LeadSource = 'Event';
        insert lead;
        // Insert Account
        Account acc = new Account();
        acc.Name = 'Test Acc for Campaign test';
        acc.Type = 'Event';
        acc.Industry = 'Auto';
        insert acc;
        
        // Insert Contact
        Contact con = new Contact();
        con.FirstName = 'Test Contact';
        con.LastName = 'Event Test';
        con.Email    = 'testcon@gumgum.com';
        con.AccountId = acc.Id;
        insert con;
       
      
        
    }

    private static testMethod void 	campaignMemberBeforeInsert(){
        Campaign cmp = [SELECT ID,Name from Campaign LIMIT 1];
        Lead lead = [SELECT Id,First_Marketing_Campaign__c FROM Lead LIMIT 1];
        system.assertEquals(null, lead.First_Marketing_Campaign__c);
        // Insert Campaign Member
        CampaignMember cmMem = new CampaignMember();
        cmMem.LeadId = lead.Id;
        cmMem.CampaignId = cmp.Id;
        cmMem.Status = 'Responded';
        insert cmMem;
        Lead lead1 = [SELECT Id,First_Marketing_Campaign__c FROM Lead LIMIT 1];
        system.assertEquals(cmp.Name, lead1.First_Marketing_Campaign__c);
    }
    private static testMethod void campaignMemberAfterUpdate(){
       Campaign cmp = [SELECT ID,Name from Campaign LIMIT 1];
       Contact con = [SELECT Id,First_Marketing_Campaign__c FROM Contact LIMIT 1];
       system.debug('@@@beforeUpdate@@'+con.First_Marketing_Campaign__c);
      // Insert Campaign Member 2
       CampaignMember cm2 = new CampaignMember();
       cm2.ContactId = con.Id;
       cm2.CampaignId = cmp.Id;
       cm2.Status = 'Sent';
       insert cm2;
       system.debug('@@@CMstatus'+cm2.Status);
        
     CampaignMember cmpMem = [SELECT ID,Status,Campaign.Name,ContactId FROM CampaignMember WHERE ID =:cm2.Id];
     cmpMem.Status = 'Responded';
     update cmpMem;
     system.debug('@@@CMstatusafterupdate'+cmpMem.Status);
        
     Contact con1 = [SELECT ID,First_Marketing_Campaign__c FROM Contact WHERE ID =: con.Id];
     system.debug('@@@afterUpdate@@'+con1.First_Marketing_Campaign__c);
     system.assertEquals(cmp.Name, con1.First_Marketing_Campaign__c);
        
     // delete campaign member
     delete cmpMem;
        try{
             // undelete campaign member
             undelete cmpMem;
         }
        Catch(Exception e){
            HandleCustomException.LogException(e); 
        }
    } 
     private static testMethod void campaignMemberLeadBeforeDelete1(){
        List<Campaign> lstcmp = [SELECT ID,Name from Campaign ];
        Lead lead = [SELECT Id,First_Marketing_Campaign__c FROM Lead LIMIT 1];
        system.assertEquals(null, lead.First_Marketing_Campaign__c);
         
        // Scenario #1 Delete First Marketing Campaign
        // Insert Campaign Member
        CampaignMember cmMem = new CampaignMember();
        cmMem.LeadId = lead.Id;
        cmMem.CampaignId = lstcmp[0].Id;
        cmMem.Status = 'Responded';
        cmMem.LastRespondedDateTime__c = system.now(); 
        insert cmMem;
        delete cmMem;
        Lead lead1 = [SELECT Id,First_Marketing_Campaign__c FROM Lead LIMIT 1]; 
        system.assertEquals(NULL, lead1.First_Marketing_Campaign__c);
        //Scenario #2 Delete First Marketing Campaign Where First Marketing Campaign Not equal to Most Recent Campaign
        CampaignMember cmMem1 = new CampaignMember();
        cmMem1.LeadId = lead.Id;
        cmMem1.CampaignId = lstcmp[0].Id;
        cmMem1.Status = 'Responded';
        cmMem1.LastRespondedDateTime__c = system.now(); 
        insert cmMem1;
        CampaignMember cmMem2 = new CampaignMember();
        cmMem2.LeadId = lead.Id;
        cmMem2.CampaignId = lstcmp[1].Id;
        cmMem2.Status = 'Responded';
        cmMem2.LastRespondedDateTime__c = system.now(); 
        insert cmMem2;
        delete cmMem1;
        Lead lead2 = [SELECT Id,First_Marketing_Campaign__c,Most_Recent_Marketing_Campaign__c FROM Lead LIMIT 1];
        system.assertEquals(lstcmp[1].Name, lead2.First_Marketing_Campaign__c);
         
       
    }
    private static testMethod void campaignMemberLeadBeforeDelete2(){
        List<Campaign> lstcmp = [SELECT ID,Name from Campaign ];
        Lead lead = [SELECT Id,First_Marketing_Campaign__c,Most_Recent_Marketing_Campaign__c FROM Lead LIMIT 1];
        // Scenario #3 Delete Most Recent Marketing Campaign Where First Marketing Campaign Not equal to Most Recent Campaign
        CampaignMember cmMem3 = new CampaignMember();
        cmMem3.LeadId = lead.Id;
        cmMem3.CampaignId = lstcmp[0].Id; 
        cmMem3.Status = 'Responded';
        cmMem3.LastRespondedDateTime__c = system.now(); 
        insert cmMem3;
        CampaignMember cmMem4 = new CampaignMember();
        cmMem4.LeadId = lead.Id;
        cmMem4.CampaignId = lstcmp[1].Id; 
        cmMem4.Status = 'Responded';
        cmMem4.LastRespondedDateTime__c = system.now(); 
        insert cmMem4;
        delete cmMem4;
        Lead lead3 = [SELECT Id,First_Marketing_Campaign__c,Most_Recent_Marketing_Campaign__c FROM Lead LIMIT 1];
        system.assertEquals(lstcmp[0].Name, lead3.Most_Recent_Marketing_Campaign__c);  
        
       
        
    }
    private static testMethod void campaignMemberLeadBeforeDelete3(){
        List<Campaign> lstcmp = [SELECT ID,Name from Campaign ];
        Lead lead = [SELECT Id,First_Marketing_Campaign__c,Most_Recent_Marketing_Campaign__c FROM Lead LIMIT 1];
        // Scenario #4 Delete Most Recent Marketing Campaign Where Lead is added under 3 campaigns as campaign members
        CampaignMember cmMem5 = new CampaignMember();
        cmMem5.LeadId = lead.Id;
        cmMem5.CampaignId = lstcmp[0].Id;
        cmMem5.Status = 'Responded'; 
        cmMem5.LastRespondedDateTime__c = system.now(); 
        insert cmMem5;
        CampaignMember cmMem6 = new CampaignMember();
        cmMem6.LeadId = lead.Id;
        cmMem6.CampaignId = lstcmp[1].Id; 
        cmMem6.Status = 'Responded';
        cmMem6.LastRespondedDateTime__c = system.now(); 
        insert cmMem6;
        CampaignMember cmMem7 = new CampaignMember();
        cmMem7.LeadId = lead.Id;
        cmMem7.CampaignId = lstcmp[2].Id; 
        cmMem7.Status = 'Responded';
        cmMem7.LastRespondedDateTime__c = system.now();  
        insert cmMem7;
        
		delete cmMem7;
        Lead lead4 = [SELECT Id,First_Marketing_Campaign__c,Most_Recent_Marketing_Campaign__c FROM Lead LIMIT 1];
        system.assertEquals(lstcmp[2].Name, lead4.Most_Recent_Marketing_Campaign__c);  
        
        
    }
    private static testMethod void campaignMemberContactBeforeDelete1(){
        List<Campaign> lstcmp = [SELECT ID,Name from Campaign ];
        Contact con = [SELECT Id,First_Marketing_Campaign__c FROM Contact LIMIT 1];
        system.assertEquals(null, con.First_Marketing_Campaign__c);
         
        // Scenario #1 Delete First Marketing Campaign
        // Insert Campaign Member
        CampaignMember cmMem = new CampaignMember();
        cmMem.ContactId = con.Id;
        cmMem.CampaignId = lstcmp[0].Id;
        cmMem.Status = 'Responded';
        cmMem.LastRespondedDateTime__c = system.now(); 
        insert cmMem;
        delete cmMem;
        Lead lead1 = [SELECT Id,First_Marketing_Campaign__c FROM Lead LIMIT 1]; 
        system.assertEquals(NULL, lead1.First_Marketing_Campaign__c);
        //Scenario #2 Delete First Marketing Campaign Where First Marketing Campaign Not equal to Most Recent Campaign
        CampaignMember cmMem1 = new CampaignMember();
        cmMem1.ContactId = con.Id;
        cmMem1.CampaignId = lstcmp[0].Id;
        cmMem1.Status = 'Responded';
        cmMem1.LastRespondedDateTime__c = system.now(); 
        insert cmMem1;
        CampaignMember cmMem2 = new CampaignMember();
        cmMem2.ContactId = con.Id;
        cmMem2.CampaignId = lstcmp[1].Id;
        cmMem2.Status = 'Responded';
        cmMem2.LastRespondedDateTime__c = system.now(); 
        insert cmMem2;
        delete cmMem1;
        Contact con2 = [SELECT Id,First_Marketing_Campaign__c,Most_Recent_Marketing_Campaign__c FROM Contact LIMIT 1];
        system.assertEquals(lstcmp[1].Name, con2.First_Marketing_Campaign__c);
         
       
    }
    private static testMethod void campaignMemberContactBeforeDelete2(){
        List<Campaign> lstcmp = [SELECT ID,Name from Campaign ];
        Contact con = [SELECT Id,First_Marketing_Campaign__c FROM Contact LIMIT 1];
        system.assertEquals(null, con.First_Marketing_Campaign__c);
         
       
        //Scenario #2 Delete First Marketing Campaign Where First Marketing Campaign Not equal to Most Recent Campaign
        CampaignMember cmMem1 = new CampaignMember();
        cmMem1.ContactId = con.Id;
        cmMem1.CampaignId = lstcmp[0].Id;
        cmMem1.Status = 'Responded';
        cmMem1.LastRespondedDateTime__c = system.now(); 
        insert cmMem1;
        CampaignMember cmMem2 = new CampaignMember();
        cmMem2.ContactId = con.Id;
        cmMem2.CampaignId = lstcmp[1].Id;
        cmMem2.Status = 'Responded';
        cmMem2.LastRespondedDateTime__c = system.now(); 
        insert cmMem2;
        delete cmMem2;
        Contact con2 = [SELECT Id,First_Marketing_Campaign__c,Most_Recent_Marketing_Campaign__c FROM Contact LIMIT 1];
        system.assertEquals(lstcmp[0].Name, con2.Most_Recent_Marketing_Campaign__c);
         
       
    }
    private static testMethod void campaignMemberContactBeforeDelete3(){
        List<Campaign> lstcmp = [SELECT ID,Name from Campaign ];
        Contact con = [SELECT Id,First_Marketing_Campaign__c FROM Contact LIMIT 1];
        system.assertEquals(null, con.First_Marketing_Campaign__c);
         
       
        //Scenario #2 Delete First Marketing Campaign Where First Marketing Campaign Not equal to Most Recent Campaign
        CampaignMember cmMem1 = new CampaignMember();
        cmMem1.ContactId = con.Id;
        cmMem1.CampaignId = lstcmp[0].Id;
        cmMem1.Status = 'Responded';
        cmMem1.LastRespondedDateTime__c = system.now(); 
        insert cmMem1;
        CampaignMember cmMem2 = new CampaignMember();
        cmMem2.ContactId = con.Id;
        cmMem2.CampaignId = lstcmp[1].Id;
        cmMem2.Status = 'Responded';
        cmMem2.LastRespondedDateTime__c = system.now(); 
        insert cmMem2;
        CampaignMember cmMem3 = new CampaignMember();
        cmMem3.ContactId = con.Id;
        cmMem3.CampaignId = lstcmp[2].Id;
        cmMem3.Status = 'Responded';
        cmMem3.LastRespondedDateTime__c = system.now(); 
        insert cmMem3;
        delete cmMem3; 
        Contact con2 = [SELECT Id,First_Marketing_Campaign__c,Most_Recent_Marketing_Campaign__c FROM Contact LIMIT 1];
        system.assertEquals(lstcmp[1].Name, con2.Most_Recent_Marketing_Campaign__c);
         
       
    }
}