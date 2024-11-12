public class JiraCalloutNA {
    
    @InvocableMethod(label='Create Jira Ticket NA' description='Returns the list of account names corresponding to the specified account IDs.' category='Account')
    public static void createJiraEmea(List<InputVariables> inputVariables){
        try{
             JiraCalloutNA.performJiraCallout(inputVariables.get(0).oppId,inputVariables.get(0).flowUserEmail); 
        }catch(Exception ex){
            system.debug(ex.getMessage());
        }  
    }
    
    public class InputVariables{
        @InvocableVariable
        public Id oppId;   
        @InvocableVariable
        public String flowUserEmail;
    }
    
    @future(callout=true)
    public static void performJiraCallout(Id oppId,String flowUserEmail){   
         
        FieldsWrapperNA requestBody = new FieldsWrapperNA();
        String jsonBody = JSON.serialize(requestBody.createJiraPostBody(oppId,flowUserEmail)); 
        system.debug(jsonBody); 
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setEndpoint('callout:Jira_Named_Cred/rest/api/3/issue');

        request.setBody(jsonBody);
        HttpResponse response = http.send(request);
        system.debug(response.getBody());
        system.debug(response.getStatusCode());
        system.debug('CPU Time after calling posting the ticket to jira'+Limits.getCpuTime());
        if(response.getStatusCode() == 201){
            Map<String,Object> responseMap = (Map<String,Object>)JSON.deserializeUntyped(response.getBody());
            system.debug(responseMap.get('key'));
            Opportunity opp = new Opportunity();
            opp.Id = oppId;
            opp.Ad_Campaign_JIRA_Link__c = Label.JiraURL+responseMap.get('key');
            update opp;
            system.debug('CPU Time after calling updating the opp'+Limits.getCpuTime());
        }else{
            ExceptionhandlerForJiraCallouts(response.getBody(),oppId,flowUserEmail);
        }
        
    }
    
    public static void ExceptionhandlerForJiraCallouts(String message,String oppId,String flowUserEmail){
        
        Custom_Exception__c exceptionObj = new Custom_Exception__c(); 
        exceptionObj.ComponentName__c = 'SF Jira Callout';
        exceptionObj.Exception_Message__c = message + '    '+ flowUserEmail;
        exceptionObj.RecordId__c = oppId;
        insert exceptionObj;
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        List<String> toAddress = new List<String>();
        List<String> ccAddress = new List<String>();
        mail.setSubject('SF Jira callout exception ');     
        toAddress.add('waqar.shaik@ic.gumgum.com');
      //  ccAddress.add('waqar.shaik@ic.gumgum.com');       
        mail.setToAddresses(toAddress);  
       // mail.setCcAddresses(ccAddress);      
             // Create Body       
            String body = '<html xmlns="http://www.w3.org/1999/xhtml"><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" /><title>Untitled Document</title><style type="text/css"> <!-- body,td,tr {    font-family:Arial, Helvetica, sans-serif;   font-size:12px; } .table_body_text {    background:#7799B2;     font-family:Arial, Helvetica, sans-serif;   font-size:12px;     font-weight:bold;   border-bottom:1px solid #FFF;   border-left:1px solid #FFF;     padding:5px; } .table_body_text_bold{   background:#3CBBEC;     font-family:Arial, Helvetica, sans-serif;   font-size:12px;     font-weight:bold;   color:#FFF;     border-bottom:1px solid #FFF;   border-left:1px solid #FFF;     padding:5px; } .table_body_text_grey {  background:#E9E9E9;     font-family:Arial, Helvetica, sans-serif;   font-size:12px;     border-bottom:1px solid #FFF;   border-left:1px solid #FFF;     padding:5px; } strong{     color:#006895; } strong a{     color:#006895;    text-decoration:none; } strong a:hover{     color:#006895;  text-decoration:none; } --> </style> </head>';        
              body += ' <br><br><Strong>An exceptioon has occured in SF Jira Integration.</Strong> <br><br>';
              body += '<br><br><Strong>Opportunity ID:</Strong>' + oppId + '<br><br>';
              body += '<br><br><Strong>flow User Email:</Strong>' + flowUserEmail + '<br><br>';
              body += ' <br><br><Strong>Please find the below exception message :</Strong> <br><br>';
              body += '<br><br>' + message + '<br><br>';
              
              body += '<br><br> <b><Strong> Thank you,<br> </Strong></b>';
              body += '<b><Strong> SFDC Team <br><br></Strong></b>';          
              body += '</body> </html>';  
              mail.setHtmlBody(body);       
              mails.add(mail);   
        system.debug('mails Size'+mails.size());
           Messaging.sendEmail(mails); 
    }
}