public class JiraUserClass {
    
    public class UserWrapper {
    public List<Users> users { get; set; } 
    public Integer total { get; set; }
    public String header { get; set; }
    }

    // Inner class to represent each user
    public class Users {
        public String accountId { get; set; }
        public String accountType { get; set; }
        public String html { get; set; }
        public String displayName { get; set; }

    }
    
    public static String getJiraUser(String email){
        
        if(email!='' && email!=null){
            email = String.escapeSingleQuotes(email);
            Http http = new Http();
            HttpRequest request = new HttpRequest();
            request.setMethod('GET');
            request.setHeader('Content-Type', 'application/json');
            request.setEndpoint('callout:Jira_Named_Cred/rest/api/3/user/picker?query='+email);
            HttpResponse response = http.send(request);
            system.debug(response.getBody());
            system.debug(response.getStatusCode());//200
            UserWrapper wrapper = (UserWrapper)Json.deserialize(response.getBody(), UserWrapper.class);
            system.debug(wrapper);
            system.debug(wrapper.users);
            if(wrapper.users.size()>0){
                system.debug(wrapper.users[0].accountId);
                return wrapper.users[0].accountId;  
            }else{
                return '';
            }
            
        }else{
            return '';
        } 
        
        
    }
}