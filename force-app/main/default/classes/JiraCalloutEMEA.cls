public class JiraCalloutEMEA {
    
    @InvocableMethod(label='Create Jira Ticket' description='Returns the list of account names corresponding to the specified account IDs.' category='Account')
    public static void createJiraEmea(List<InputVariables> inputVariables){
        try{
             JiraCalloutEMEA.performJiraCallout(inputVariables.get(0).oppId,inputVariables.get(0).flowUserEmail); 
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
         
        FieldsWrapperEmea requestBody = new FieldsWrapperEmea();
        String jsonBody = JSON.serialize(requestBody.createJiraPostBody(oppId,flowUserEmail)); 
        system.debug(jsonBody); 
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setEndpoint('callout:Jira_Named_Cred/rest/api/3/issue');

        //Create Authorization user
        /*String userName = 'waqar.shaik@ic.gumgum.com';
        String password = '';
        Blob headervalue = Blob.valueOf(userName+':'+password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headervalue);*/
       // request.setHeader('Authorization',authorizationHeader);

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
            JiraCalloutNA.ExceptionhandlerForJiraCallouts(response.getBody(),oppId,flowUserEmail);
        }
        
    }
    
}