public class JiraCallout {
    
    
    public class RequestBody {
        public FieldData fields;
        
        public RequestBody() {
            this.fields = new FieldData();
        }
        
        
    }
    
    public class FieldData {
        public Project project;
        public Assignee assignee;
        public String summary;
        public CustomField customfield_13839;
        public IssueType issuetype;
        
        public FieldData() {
            this.project = new Project();
            this.assignee = new Assignee();
            this.customfield_13839 = new CustomField();
            this.issuetype = new IssueType();
            this.summary = 'This is an autogenerated issue from a demo set in the constructor';
        }
    }
    
    public class Project {
        public String key;
        
        public Project() {
            this.key = 'SOP';
        }
    }
    
    public class Assignee {
        public String id;
        
        public Assignee() {
            this.id = 'JiraUseId';
        }
    }
    
    public class CustomField {
        public Integer version;
        public String type;
        public List<Content> content;
        
        public CustomField() {
            this.type = 'doc';
            this.version = 1;
            this.content = new List<Content>{new Content()};
                }
    }
    
    public class Content {
        public String type;
        public List<TextContent> content;
        
        public Content() {
            this.type = 'paragraph';
            this.content = new List<TextContent>{new TextContent()};
                }
    }
    
    public class TextContent {
        public String type;
        public String text;
        
        public TextContent() {
            this.type = 'text';
            this.text = 'sam';
        }
    }
    
    public class IssueType {
        public String name;
        
        public IssueType() {
            this.name = 'Task';
        }
    }
    public RequestBody initializeData() {
        
        
        JiraCallout.RequestBody requestBody = new JiraCallout.RequestBody();
        FieldData fields = new FieldData();
        // Initialize Project
        Project project = new Project();
        project.key = 'SOP';
        fields.project = project;
        
        // Initialize Assignee
        Assignee assignee = new Assignee();  
        String assigneeUserAccountIdKir = JiraUserClass.getJiraUser('kiran');
        String assigneeUserAccountId = JiraUserClass.getJiraUser('waqar');
        system.debug('assigneeUserAccountIdKir'+ assigneeUserAccountIdKir);
        system.debug('assigneeUserAccountId'+ assigneeUserAccountId);
        
        //assignee.id = '6422342a4b23217e558dff0c';
        assignee.id = assigneeUserAccountIdKir;
        fields.assignee = assignee;
        
        // Initialize Summary
        fields.summary = 'test';
        
        // Initialize CustomField
        CustomField customfield_13839 = new CustomField();
        customfield_13839.type = 'doc';
        customfield_13839.version = 1;
        
        // Initialize Content
        Content content = new Content();
        content.type = 'paragraph';
        
        // Initialize TextContent
        TextContent textContent = new TextContent();
        textContent.type = 'text';
        textContent.text = 'This is from sf';
        
        // Assign TextContent to Content
        content.content = new List<TextContent>{ textContent };
            // Assign Content to CustomField
            customfield_13839.content = new List<Content>{ content };
                fields.customfield_13839 = customfield_13839;
        
        // Initialize IssueType
        IssueType issuetype = new IssueType();
        issuetype.name = 'Task';
        fields.issuetype = issuetype;
        requestBody.fields = fields;
        system.debug(requestBody);
        return requestBody;
    }
    
    public static HttpResponse performJiraCallout(){
        
        
        JiraCallout requestBody = new JiraCallout();
        // Serializing the instance to JSON
        String jsonBody = JSON.serialize(requestBody.initializeData());
        system.debug(jsonBody);
        
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        //request.setEndpoint('https://gumgum-sandbox-629.atlassian.net/rest/api/3/issue');
        
        
        //Create Authorization user
        /*String userName = 'waqar.shaik@ic.gumgum.com';
        String password = 'ATATT3xFfGF0JNnioOH-SKCHS22BC7tfBw081fG0t0XkT4XVi8HXVQDfWYEKMOuzDf9WRTil3kVe2hVvtrLiJq2I9fu-6vLWiOPlE4dtGgZXn-pDIs8DY-QW0cD1oF3c27z6O-GYzcZ3urdxmsvoRr_sHqexBfvN2Jal077TXXCMfw5qWyjA8e8=B4169BAD';
        Blob headervalue = Blob.valueOf(userName+':'+password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headervalue);
        request.setHeader('Content-Type', 'application/json');*/
        request.setEndpoint('callout:Jira_Named_Cred/rest/api/3/issue');
        //request.setHeader('Content-Type', 'application/json'); 
       // request.setHeader('Authorization',authorizationHeader);
        request.setBody(jsonBody);
        HttpResponse response = http.send(request);
        system.debug(response.getBody());
        system.debug(response.getStatusCode());
        
        return response;
    }
    
    
}