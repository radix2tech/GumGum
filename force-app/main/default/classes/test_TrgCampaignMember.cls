@isTest
public class test_TrgCampaignMember {
    @isTest
    public static void testCampaignMemberTrigger(){
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
        list<account> acctList=new list<account>();
        acctList.add(new account(name='Test 005',
                                 phone='22322342342',
                                 BillingCity='Test',
                                 BillingCountry='United States',
                                 BillingPostalCode='Test',
                                 BillingState='New York',
                                 BillingStreet='Test'));
        acctList.add(new account(name='Test 004'));
        system.debug('acctList: '+ acctList);
        insert acctList;
        List<contact> contactList=new list<contact>();
        contactList.add(new contact(LastName='Test Contact',Persona__c='General',email='aa@aa.com',accountid=acctList[0].id));
        contactList.add(new contact(LastName='Test Contact2',Persona__c='General',email='aa@aa.com',accountid=acctList[1].id));
        insert contactList;
        system.debug('contactList: '+ contactList);
        
        list<client_team__c> ct= new list<client_team__c>();
        ct.add(new client_team__c(agent__c=contactList[0].id,Client_Account__c=acctList[0].id));
        ct.add(new client_team__c(agent__c=contactList[1].id,Client_Account__c=acctList[1].id));
        insert ct;
        
        Campaign c=new campaign(name='Test Campaign',
                               //type='Internal Event',
                               recordtypeid='0120P0000001uCUQAY',
                               StartDate=System.today(),
                               endDate=System.today()+7,
                               BudgetedCost=1000,
                               Cost_Breakdown__c='ashdashdg',
                               Approved_by_Management__c='Yes',
                               Event_Registration_Method__c='Sponsored');
        insert c;
		CampaignMemberStatus cms1 = new CampaignMemberStatus(CampaignId=c.Id, HasResponded=true, Label='Attended', SortOrder=6);
        CampaignMemberStatus cms2 = new CampaignMemberStatus(CampaignId=c.Id, HasResponded=True, Label='Registered', SortOrder=13); 
        //CampaignMemberStatus cms3 = new CampaignMemberStatus(CampaignId=c.Id, HasResponded=True, Label='Attended', SortOrder=4);        
        insert cms1;
        insert cms2;
        
        list<CampaignMember>  cm=new list<CampaignMember>();
        cm.add(new campaignmember(campaignid=c.id,contactid=contactList[0].id,status='Attended'));
        cm.add(new campaignmember(campaignid=c.id,contactid=contactList[1].id,status='Attended'));
        insert cm;
        list<Account_Campaign_Junction__c> juctObjList=[select id from Account_Campaign_Junction__c]; 
        system.assertEquals(2, juctObjList.size());
        cm=[select id,contactid,status from campaignmember];
        cm[0].status='Sent';
        //cm[1].status='Sent';
        update cm;
        system.debug(cm[0].status);
        system.debug(cm[1].status);
        juctObjList=[select id from Account_Campaign_Junction__c];
        system.assertEquals(1, juctObjList.size());
    }
}