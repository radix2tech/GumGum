@isTest
private class ContactUpdateHandlerTestClass {
	private static testMethod void updateContactTest(){
    	// Insert User
    	Profile profile = [select id from profile where name LIKE '%Sales%' LIMIT 1];
        User user = new User();
        user.firstName = 'GumGum';
        user.lastName ='admin test';
        user.profileId = profile.id;
        user.username = 'admin@gumgumtest.com';
        user.email = 'admintest@gumgum.com';
        user.Department = 'Salesforce';
        user.Title = 'Manager';  
        user.Alias = 'adm';
        user.TimeZoneSidKey = 'America/Los_Angeles';
     	user.EmailEncodingKey = 'UTF-8';
     	user.LanguageLocaleKey = 'en_US';
     	user.LocaleSidKey = 'en_US';
        insert user;
        
        // Insert Account
        Account acc = new Account();
        acc.Name = 'GumGum Inc';
        insert acc;
        // Insert Contact
        Contact con = new Contact();
        con.AccountId = acc.Id;
        con.Email  = 'admin@gumgum.com';
        con.FirstName = 'test admin1';
        con.LastName  =  'GumGum Test';
        con.Department = 'Salesforce';
        con.Title  = 'Manager';
        insert con;
        con.Email = user.Email;
        update con;
        // Check if Contact is Created
        Contact con1 = [SELECT Id,Email,No_longer_with_account__c FROM Contact WHERE Email =: user.Email];
        system.assertEquals(user.Email, con1.Email);
        system.assertEquals(false, con1.No_longer_with_account__c);
        List<String> lstEmailIds = new List<String>();
        lstEmailIds.add(con1.Email);
        ContactUpdateHandler.getContacts(lstEmailIds);
    }
}