public class FieldsWrapperEmea { 
    public Fields fields { get; set; }
    
    public class Fields {
        
        public Project project { get; set; } // Project
        public String customfield_13403 { get; set; } // Campaign Name or Opportunity Name
        public CustomField assignee { get; set; } // Assignee
        public CustomField customfield_14646 { get; set; }//Seller Name - Salesrep - Owner
        public Reporter reporter { get; set; } // Reporter
        public CustomFieldOption customfield_13838 { get; set; } // Region (*) - Opportunity Region
        public String customfield_10031 { get; set; }//Advertiser Name - Account Name
        public String customfield_11860 { get; set; } // Agency - Agency Name
        public CustomFieldOption customfield_14540{ get; set;} // Exception Approved on SF?(ACE)
        public String customfield_13845 { get; set; }// Campaign Start Date
        public String customfield_14208 { get; set; }// Campaign End Date  
        public CustomFieldOption customfield_13917{ get; set;}// Currency(*)
        public Decimal customfield_14502 { get; set; }//Campaign budget NET(ACE)
        public String customfield_11874 { get; set; }// Salesfore Link
        public String customfield_14207 { get; set; }// Salesforce Id
        //public List<CustomFieldOption> customfield_14512 { get; set; }//Delivery Geo(ACE)
        //public String customfield_14508 { get; set; } 
        public String summary { get; set; } //Summary
        public IssueType issuetype { get; set; } //Issue Type
        public CustomField customfield_11875 { get; set; } // Account Manager
        
        
        
        /*public List<CustomFieldOption> customfield_14230 { get; set; }
        public CustomFieldDoc customfield_14571 { get; set; }
        public CustomFieldOption customfield_14570 { get; set; }
	    public List<CustomFieldOption> customfield_14213 { get; set; }
        
        public CustomFieldOption customfield_14217 { get; set; }
        public String customfield_14214 { get; set; }
        public CustomFieldOption customfield_14215 { get; set; }
        
        public CustomFieldDoc customfield_14209 { get; set; }
        public CustomFieldDoc customfield_14507 { get; set; }
       
        public List<CustomFieldOption> customfield_14548 { get; set; }
        
        public CustomFieldOption customfield_14509 { get; set; }
        
        public String customfield_14242 { get; set; }
        public CustomFieldDoc customfield_14221 { get; set; }
        public CustomFieldOption customfield_14222 { get; set; }
        public CustomFieldOption customfield_14541 { get; set; }
        public List<CustomFieldOption> customfield_13996 { get; set; }
        public CustomFieldOption customfield_14546 { get; set; }
       
        public CustomFieldDoc customfield_14206 { get; set; }
        public Decimal customfield_14503 { get; set; }
        public CustomFieldDoc customfield_14624 { get; set; }
        
        public CustomFieldOption customfield_14644 { get; set; }
       
        public CustomFieldOption customfield_14218 { get; set; }
        public CustomFieldOption customfield_14515 { get; set; }
        
        */
    }
    
    public class Project {
        public String key { get; set; }
    }
    
    public class CustomField {
        public String id { get; set; }
    }
    
    public class Reporter {
        public String id { get; set; }
    }
    
    public class CustomFieldOption {
        public String value { get; set; }
    }
    
    public class CustomFieldDoc {
        public Integer version { get; set; }
        public String type { get; set; }
        public List<DocContent> content { get; set; }
    }
    
    public class DocContent {
        public String type { get; set; }
        public List<ContentText> content { get; set; }
    }
    
    public class ContentText {
        public String type { get; set; }
        public String text { get; set; }
    }
    
    public class IssueType {
        public String name { get; set; }
    }
    public FieldsWrapperEmea createJiraPostBody(Id oppId,String flowUserEmail){ 

        Opportunity opp = [SELECT Id,Name,Account.Name,Agency_Name__r.Name,
                           Exception_Approval__c,Start_Date2__c,End_Date2__c,
                           currencyIsoCode,Net_Total_Ordered_Amount_1__c,
                           Opportunity_Region__c,Owner.Email,Account_Manager__r.Email  from Opportunity WHERE Id=:oppId];
        FieldsWrapperEmea wrapper = new FieldsWrapperEmea();
        
        wrapper.fields = new FieldsWrapperEmea.Fields();
        
        //Calling Jira to get the Seller and Assignee user Jira Id's 
        String sellerNameJiraId = JiraUserClass.getJiraUser(opp.Owner.Email);
        String assigneeNameJiraId = JiraUserClass.getJiraUser(flowUserEmail);
        
        //Assigning the Project
        wrapper.fields.project = new FieldsWrapperEmea.Project();
        wrapper.fields.project.key = 'ACE';
        
        //Assigning the Opportunty Name
        wrapper.fields.customfield_13403 = opp.Name;
        
        
        //Seller Name - Salesrep - Owner
        wrapper.fields.customfield_14646 = new FieldsWrapperEmea.CustomField();
        
        wrapper.fields.customfield_14646.id = sellerNameJiraId;
        
        //Account Manager
        wrapper.fields.customfield_11875 = new FieldsWrapperEmea.CustomField();
        String accountManagerJiraId = JiraUserClass.getJiraUser(opp.Account_Manager__r.Email); // Getting Account Manager Jira Id 
        if(accountManagerJiraId!=null && accountManagerJiraId!=''){
            wrapper.fields.customfield_11875.id = accountManagerJiraId; 
        }else{
            wrapper.fields.customfield_11875.id = null;
        }

        //Assignee
        wrapper.fields.assignee = new FieldsWrapperEmea.CustomField() ;
        wrapper.fields.assignee.id = assigneeNameJiraId; 
        
        //Reporter
        wrapper.fields.reporter = new FieldsWrapperEmea.Reporter();
        wrapper.fields.reporter.id = sellerNameJiraId;
        
        //Assigning Region (*) - Opportunity Region
        wrapper.fields.customfield_13838 = new FieldsWrapperEmea.CustomFieldOption();
        Map<String,String> oppRegion2JiraRegion = new Map<String,String>{'EMEA - Belgium'=>'Belgium',
            'EMEA - Germany'=>'DACH',
            'EMEA - Netherlands'=>'Netherlands',
            'EMEA - Nordics'=>'Nordics',
            'EMEA - Spain'=>'Spain',
            'EMEA - UK'=>'UK'};
                //Opp Regon - Region(*)
                if(oppRegion2JiraRegion.containsKey(opp.Opportunity_Region__c)){
                    wrapper.fields.customfield_13838.value = oppRegion2JiraRegion.get(opp.Opportunity_Region__c);
                    system.debug('Opp region Assigned');
                }else{
                    wrapper.fields.customfield_13838.value = 'UK';
                }
        
        //Account Name - Advertiser Name
        wrapper.fields.customfield_10031 = opp.Account.Name;
        
        //Agency Name - Agency
        system.debug('Agency Name --------' + opp.Agency_Name__r.Name);
        wrapper.fields.customfield_11860 = opp.Agency_Name__r.Name;
        
        //Exception Approval Status - Rejected - No, Approved - Yes
        wrapper.fields.customfield_14540 = new FieldsWrapperEmea.CustomFieldOption();
        if(opp.Exception_Approval__c == 'Exception Approved'){
            wrapper.fields.customfield_14540.value = 'Yes';
        }else if(opp.Exception_Approval__c == 'Exception Rejected'){
            wrapper.fields.customfield_14540.value = 'No';
        }else{
            wrapper.fields.customfield_14540.value = 'N/A';
        }
        
        //Start Date
        if(opp.Start_Date2__c!=null){
            wrapper.fields.customfield_13845 = String.valueOf(opp.Start_Date2__c);
        }else{
            wrapper.fields.customfield_13845 = '2020-01-01';
        } 
        
        //End Date
        if(opp.End_Date2__c!=null){
            wrapper.fields.customfield_14208 = String.valueOf(opp.End_Date2__c);
        }else{
            wrapper.fields.customfield_14208 = '2020-01-01';
        }
        
        //Opportunity Currency
        wrapper.fields.customfield_13917 = new FieldsWrapperEmea.CustomFieldOption();
        wrapper.fields.customfield_13917.value = opp.CurrencyIsoCode;
        
        //Net Total Ordered Amount
        wrapper.fields.customfield_14502 = opp.Net_Total_Ordered_Amount_1__c;
        
        //Salesforce Link
        wrapper.fields.customfield_11874 = Label.OpportunityURL+opp.Id+'/view'; 
        
        //Salesforce Id
        wrapper.fields.customfield_14207 = opp.Id;
        
        //Delivery Geo(ACE)      
       /* wrapper.fields.customfield_14512 = new List<FieldsWrapperEmea.CustomFieldOption>();
        FieldsWrapperEmea.CustomFieldOption option3 = new FieldsWrapperEmea.CustomFieldOption();
        option3.value = '(GB) United Kingdom';
        wrapper.fields.customfield_14512.add(option3);*/
        
        //JIRA avails ticket link  
        //wrapper.fields.customfield_14508 = 'https://gumgum.jira.com/browse/CST-0000';
        
        //Summary
        wrapper.fields.summary = 'ACE - Direct - Test - Ignore '+opp.Name;
        
        //Issue Type
        wrapper.fields.issuetype = new FieldsWrapperEmea.IssueType();
        wrapper.fields.issuetype.name = 'ACE - Direct';
        
       /* wrapper.fields.customfield_14230 = new List<FieldsWrapperEmea.CustomFieldOption>();
        FieldsWrapperEmea.CustomFieldOption option1 = new FieldsWrapperEmea.CustomFieldOption();
        option1.value = 'Business & Finance';
        wrapper.fields.customfield_14230.add(option1);*/
        
        /*wrapper.fields.customfield_14571 = new FieldsWrapperEmea.CustomFieldDoc();
        wrapper.fields.customfield_14571.version = 1;
        wrapper.fields.customfield_14571.type = 'doc';
        wrapper.fields.customfield_14571.content = new List<FieldsWrapperEmea.DocContent>();
        FieldsWrapperEmea.DocContent docContent1 = new FieldsWrapperEmea.DocContent();
        docContent1.type = 'paragraph';
        docContent1.content = new List<FieldsWrapperEmea.ContentText>();
        FieldsWrapperEmea.ContentText contentText1 = new FieldsWrapperEmea.ContentText();
        contentText1.type = 'text';
        contentText1.text = 'Test - Other targeting info';
        docContent1.content.add(contentText1);
        wrapper.fields.customfield_14571.content.add(docContent1);*/
        
        /*wrapper.fields.customfield_14570 = new FieldsWrapperEmea.CustomFieldOption();
        wrapper.fields.customfield_14570.value = 'Yes';*/
        
        
        
        /*wrapper.fields.customfield_14213 = new List<FieldsWrapperEmea.CustomFieldOption>();
        FieldsWrapperEmea.CustomFieldOption option2 = new FieldsWrapperEmea.CustomFieldOption();
        option2.value = 'Desktop Skin';
        wrapper.fields.customfield_14213.add(option2);*/
        
       
        
        
        
        /*wrapper.fields.customfield_14217 = new FieldsWrapperEmea.CustomFieldOption();
        wrapper.fields.customfield_14217.value = 'Yes';
        
        wrapper.fields.customfield_14214 = 'Test customfield_14214';
        
        wrapper.fields.customfield_14215 = new FieldsWrapperEmea.CustomFieldOption();
        wrapper.fields.customfield_14215.value = 'No';
        
        
        
        wrapper.fields.customfield_14209 = new FieldsWrapperEmea.CustomFieldDoc();
        wrapper.fields.customfield_14209.version = 1;
        wrapper.fields.customfield_14209.type = 'doc';
        wrapper.fields.customfield_14209.content = new List<FieldsWrapperEmea.DocContent>();
        FieldsWrapperEmea.DocContent docContent2 = new FieldsWrapperEmea.DocContent();
        docContent2.type = 'paragraph';
        docContent2.content = new List<FieldsWrapperEmea.ContentText>();
        FieldsWrapperEmea.ContentText contentText2 = new FieldsWrapperEmea.ContentText();
        contentText2.type = 'text';
        contentText2.text = 'Test -Campaign Objective customfield_14209';
        docContent2.content.add(contentText2);
        wrapper.fields.customfield_14209.content.add(docContent2);
        
        wrapper.fields.customfield_14507 = new FieldsWrapperEmea.CustomFieldDoc();
        wrapper.fields.customfield_14507.version = 1;
        wrapper.fields.customfield_14507.type = 'doc';
        wrapper.fields.customfield_14507.content = new List<FieldsWrapperEmea.DocContent>();
        FieldsWrapperEmea.DocContent docContent3 = new FieldsWrapperEmea.DocContent();
        docContent3.type = 'paragraph';
        docContent3.content = new List<FieldsWrapperEmea.ContentText>();
        FieldsWrapperEmea.ContentText contentText3 = new FieldsWrapperEmea.ContentText();
        contentText3.type = 'text';
        contentText3.text = 'Test - Number of impressions per format';
        docContent3.content.add(contentText3);
        wrapper.fields.customfield_14507.content.add(docContent3); 
        
       
        
        wrapper.fields.customfield_14548 = new List<FieldsWrapperEmea.CustomFieldOption>();
        FieldsWrapperEmea.CustomFieldOption option4 = new FieldsWrapperEmea.CustomFieldOption();
        option4.value = 'None';
        wrapper.fields.customfield_14548.add(option4);
        
        

        
        
        
        wrapper.fields.customfield_14509 = new FieldsWrapperEmea.CustomFieldOption();
        wrapper.fields.customfield_14509.value = 'GG Benchmarks';
        
       
        
        wrapper.fields.customfield_14242 = '0 per day';
        
        wrapper.fields.customfield_14221 = new FieldsWrapperEmea.CustomFieldDoc();
        wrapper.fields.customfield_14221.version = 1;
        wrapper.fields.customfield_14221.type = 'doc';
        wrapper.fields.customfield_14221.content = new List<FieldsWrapperEmea.DocContent>();
        FieldsWrapperEmea.DocContent docContent4 = new FieldsWrapperEmea.DocContent();
        docContent4.type = 'paragraph';
        docContent4.content = new List<FieldsWrapperEmea.ContentText>();
        FieldsWrapperEmea.ContentText contentText4 = new FieldsWrapperEmea.ContentText();
        contentText4.type = 'text';
        contentText4.text = 'Test- first paragraph';
        docContent4.content.add(contentText4);
        wrapper.fields.customfield_14221.content.add(docContent4);
        FieldsWrapperEmea.DocContent docContent5 = new FieldsWrapperEmea.DocContent();
        docContent5.type = 'paragraph';
        docContent5.content = new List<FieldsWrapperEmea.ContentText>();
        FieldsWrapperEmea.ContentText contentText5 = new FieldsWrapperEmea.ContentText();
        contentText5.type = 'text';
        contentText5.text = 'Test -second paragraph';
        docContent5.content.add(contentText5);
        wrapper.fields.customfield_14221.content.add(docContent5);
        
        wrapper.fields.customfield_14222 = new FieldsWrapperEmea.CustomFieldOption();
        wrapper.fields.customfield_14222.value = 'Yes';
        
        wrapper.fields.customfield_14541 = new FieldsWrapperEmea.CustomFieldOption();
        wrapper.fields.customfield_14541.value = 'No';
        
        wrapper.fields.customfield_13996 = new List<FieldsWrapperEmea.CustomFieldOption>();
        FieldsWrapperEmea.CustomFieldOption option5 = new FieldsWrapperEmea.CustomFieldOption();
        option5.value = 'Cross Device';
        wrapper.fields.customfield_13996.add(option5);
        
        wrapper.fields.customfield_14546 = new FieldsWrapperEmea.CustomFieldOption();
        wrapper.fields.customfield_14546.value = 'Yes';
        
		
        
        wrapper.fields.customfield_14206 = new FieldsWrapperEmea.CustomFieldDoc();
        wrapper.fields.customfield_14206.version = 1;
        wrapper.fields.customfield_14206.type = 'doc';
        wrapper.fields.customfield_14206.content = new List<FieldsWrapperEmea.DocContent>();
        FieldsWrapperEmea.DocContent docContent6 = new FieldsWrapperEmea.DocContent();
        docContent6.type = 'paragraph';
        docContent6.content = new List<FieldsWrapperEmea.ContentText>();
        FieldsWrapperEmea.ContentText contentText6 = new FieldsWrapperEmea.ContentText();
        contentText6.type = 'text';
        contentText6.text = 'Test - Agency Contact Details - --';
        docContent6.content.add(contentText6);
        wrapper.fields.customfield_14206.content.add(docContent6);
        
        wrapper.fields.customfield_14503 = 400894.39;
        
        wrapper.fields.customfield_14624 = new FieldsWrapperEmea.CustomFieldDoc();
        wrapper.fields.customfield_14624.version = 1;
        wrapper.fields.customfield_14624.type = 'doc';
        wrapper.fields.customfield_14624.content = new List<FieldsWrapperEmea.DocContent>();
        FieldsWrapperEmea.DocContent docContent7 = new FieldsWrapperEmea.DocContent();
        docContent7.type = 'paragraph';
        docContent7.content = new List<FieldsWrapperEmea.ContentText>();
        FieldsWrapperEmea.ContentText contentText7 = new FieldsWrapperEmea.ContentText();
        contentText7.type = 'text';
        contentText7.text = 'APEX RATES';
        docContent7.content.add(contentText7);
        wrapper.fields.customfield_14624.content.add(docContent7);
        
        
        
        wrapper.fields.customfield_14644 = new FieldsWrapperEmea.CustomFieldOption();
        wrapper.fields.customfield_14644.value = 'Platinum (100k+)';
        
        
        
        wrapper.fields.customfield_14218 = new FieldsWrapperEmea.CustomFieldOption();
        wrapper.fields.customfield_14218.value = 'Yes';
        
        wrapper.fields.customfield_14515 = new FieldsWrapperEmea.CustomFieldOption();
        wrapper.fields.customfield_14515.value = 'Inclusion';
        
        */
        
        System.debug(wrapper);
        return wrapper;
    }
}