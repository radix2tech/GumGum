public class FieldsWrapperNA {
    
    public Fields fields { get; set; }
    
    public class Fields {
        public Project project { get; set; } // Project
        public String summary { get; set; } //Summary
        public IssueType issuetype { get; set; } //Issue Type
        public String customfield_13403 { get; set; } // Campaign Name or Opportunity Name
        public CustomField assignee { get; set; } // Assignee
        public Reporter reporter { get; set; } // Reporter
        public String customfield_11860 { get; set; } // Agency - Agency Name
        public String customfield_11861{ get; set; }// Advertiser - Account Name
        public CustomFieldOption customfield_13301{ get; set;}// Campaign Type - Channel
        public String customfield_11874 { get; set; }// Salesfore Link
        public String customfield_13910 { get; set; }// Salesforce Id
        public List<CustomFieldOption> customfield_14016 { get; set; }// DSP
        public CustomFieldOption customfield_13592{ get; set;}// Has the campaign been approved to be expedited? 
        public String customfield_13590 { get; set; }// Campaign Start Date
        public String customfield_13591 { get; set; }// Campaign End Date  
        public CustomFieldOption customfield_13534{ get; set;}// Currency(*)
        public Decimal customfield_13400 { get; set; }//Campaign Value - Total Ordered Amount
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
    
    public FieldsWrapperNA createJiraPostBody(Id oppId,String flowUserEmail){ 
        
        system.debug('CPU Time before NA JIRA BODY  '+Limits.getCpuTime());
        Opportunity opp = [SELECT Id,Name,Account.Name,Agency_Name__r.Name,
                           Exception_Approval__c,Start_Date2__c,End_Date2__c,
                           currencyIsoCode,Net_Total_Ordered_Amount_1__c,
                           Opportunity_Region__c,Owner.Email,Account_Manager__r.Email,
                           Expediting_Approval_Status__c,Amount,Channel__c,DSP__c  from Opportunity WHERE Id=:oppId];
        system.debug('CPU Time after query  '+Limits.getCpuTime());
        String sellerNameJiraId = JiraUserClass.getJiraUser(opp.Account_Manager__r.Email);
        system.debug('CPU Time after 1 user call  '+Limits.getCpuTime());
        String assigneeNameJiraId = JiraUserClass.getJiraUser(flowUserEmail);
        system.debug('CPU Time after 2 user call  '+Limits.getCpuTime());
        
        FieldsWrapperNA wrapper = new FieldsWrapperNA();
        wrapper.fields = new FieldsWrapperNA.Fields();
        
        //Assigning the Project
        wrapper.fields.project = new FieldsWrapperNA.Project();
        wrapper.fields.project.key = 'AC'; 
        
        //Assignee
        wrapper.fields.assignee = new FieldsWrapperNA.CustomField() ;
        wrapper.fields.assignee.id = assigneeNameJiraId; 
        
        //Reporter
        wrapper.fields.reporter = new FieldsWrapperNA.Reporter();
        wrapper.fields.reporter.id = sellerNameJiraId;
        
         //Assigning the Opportunty Name
        wrapper.fields.customfield_13403 = opp.Name;

        //Account Name - Advertiser Name
        wrapper.fields.customfield_11861 = opp.Account.Name;
        
        //Agency Name - Agency
        system.debug('Agency Name --------' + opp.Agency_Name__r.Name);   
        wrapper.fields.customfield_11860 = opp.Agency_Name__r.Name;
        //Campaign Type - Channel
        wrapper.fields.customfield_11860 = opp.Channel__c;
        
        //Salesforce Link
        wrapper.fields.customfield_11874 = Label.OpportunityURL+opp.Id+'/view'; 
        
          //Salesforce Id
        wrapper.fields.customfield_13910 = opp.Id;
        
        //Expedite Approval Status - Rejected - No, Approved - Yes
        wrapper.fields.customfield_13592 = new FieldsWrapperNA.CustomFieldOption();
        if(opp.Expediting_Approval_Status__c == 'Approved'){
            wrapper.fields.customfield_13592.value = 'Yes';
        }else{
            wrapper.fields.customfield_13592.value = 'No';
        }

        
        //DSP - From the Custom Metadata SF_Jira_DSP_Map__mdt 
        wrapper.fields.customfield_14016 = new List<FieldsWrapperNA.CustomFieldOption>();
        FieldsWrapperNA.CustomFieldOption option2 = new FieldsWrapperNA.CustomFieldOption();
        
        /*Map<String,String> sfDsp2JiraDsp = new Map<String,String>{'Adelphic/Viant'=>'Adelphic',
            'Adobe'=>'Adobe',
            'Amobee'=>'Amobee',
            'DBM'=>'Google DV360',
            'MediaMath'=>'MediaMath',
            'PulsePoint'=>'PulsePoint',
            'Supership'=>'Supership (JP)',
            'TheTradeDesk'=>'theTradeDesk',
            'AppNexus'=>'Xandr'
            };*/
        Map<String,String> sfDsp2JiraDsp = new Map<String,String>();
        for(SF_Jira_DSP_Map__mdt sfJiraDspMdt: SF_Jira_DSP_Map__mdt.getAll().values()){
            sfDsp2JiraDsp.put(sfJiraDspMdt.DSP_SF__c,sfJiraDspMdt.DSP_Jira__c );		
        }
        
        if(opp.DSP__c!=null){
            system.debug(opp.DSP__c);
            if(sfDsp2JiraDsp.containsKey(opp.DSP__c)){
                option2.value = sfDsp2JiraDsp.get(opp.DSP__c);
                wrapper.fields.customfield_14016.add(option2);
            }
        }        
        
        
        //Start Date
        if(opp.Start_Date2__c!=null){
            wrapper.fields.customfield_13590 = String.valueOf(opp.Start_Date2__c);
        }else{
            wrapper.fields.customfield_13590 = '2020-01-01';
        } 
        
        //End Date
        if(opp.End_Date2__c!=null){
            wrapper.fields.customfield_13591 = String.valueOf(opp.End_Date2__c);
        }else{
            wrapper.fields.customfield_13591 = '2020-01-01';
        }
        
        //Opportunity Currency
        wrapper.fields.customfield_13534 = new FieldsWrapperNA.CustomFieldOption();
        wrapper.fields.customfield_13534.value = opp.CurrencyIsoCode;
        
        //Net Total Ordered Amount
        wrapper.fields.customfield_13400 = opp.Amount;
           
        //Summary
        wrapper.fields.summary = opp.Name;
        
        //Issue Type
        wrapper.fields.issuetype = new FieldsWrapperNA.IssueType();
        wrapper.fields.issuetype.name = 'Ad Campaign';
        
        System.debug(wrapper);
        system.debug('CPU Time after NA JIRA BODY  '+Limits.getCpuTime());
        return wrapper;
    }
}