/*
Name           : OpportunityCampaignStatusBatch
Description    : This Batch updates the Campaign Status to Campaign Ended after 1 day of Contract End Date for Advertising Opportunities
Created Date   : 0-12-2023
Created By     : Kiran
Test Class     : OpportunityCampaignStatusBatchTest
*/
public class OpportunityCampaignStatusBatch implements Database.Batchable<sObject>,Database.Stateful,Schedulable{
    
    public Map<String,String> mapOfOppId2FailureReason;
    public List<String> otherExceptions;
    
    public OpportunityCampaignStatusBatch(){
        otherExceptions = new List<String>();
        mapOfOppId2FailureReason = new Map<String,String>();
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        String query =  'SELECT Id,Amount,CloseDate,Campaign_Status__c FROM Opportunity WHERE StageName =\'Closed/Won\' and RecordType.Name =\'Advertising\' and Campaign_Status__c!=\'Campaign Ended\' and Campaign_Status__c!=\'Campaign Cancelled\' and End_Date2__c<TODAY';   
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Opportunity> scope){
        try{
            for(Opportunity opp : scope){
                opp.Campaign_Status__c = 'Campaign Ended';
            }
            
            //Updating the Opportunities
            List<Database.SaveResult> srList = Database.update(scope,False);
            
            //Populating Error List if any
            for(Database.SaveResult sr: srList){
                if (sr.isSuccess()){    
                    //No Action
                }
                else {             
                    for(Database.Error err : sr.getErrors()) {
                        mapOfOppId2FailureReason.put(sr.getId(),err.getMessage());
                        //Add to attachments
                    }        
                }   
            }
      
        }catch(Exception e){
            otherExceptions.add(e.getMessage());
            system.debug(e);
        }
    }
    
    public void finish(Database.BatchableContext BC){
        try{
            if(mapOfOppId2FailureReason.keySet().size()>0 || otherExceptions.size()>0){
                //Sending Email with exception list
                sendExceptionEmailToSupport(mapOfOppId2FailureReason,otherExceptions);  
            }
        }catch(exception ex){
            HandleCustomException.LogException(ex);  
            system.debug(ex);
        }
    }
    
    //Sending Exception email to admin / Support
    public static void sendExceptionEmailToSupport(Map<String,String> mapOfOppId2FailureReason,List<String> otherExceptions){
        
        if(mapOfOppId2FailureReason.keySet().size()>0 || otherExceptions.size()>0){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setSubject('Campaign Status Updates Failed');  
            mail.setToAddresses(Label.OpportunityCampaignStatusBatchErrorEmail.split(','));            
            // Create Body      
            String body = '<html xmlns="http://www.w3.org/1999/xhtml"><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" /><title>Untitled Document</title><style type="text/css">table,tr{border: 1px solid black; border-collapse:collapse;} </style> </head>';       
            body += 'Hi Team,<br>';
            body += 'Please find the Opportunities which are failed to update the Campaign Status to Campaign Ended.<br>';
            body += 'Please review and take action to update Campaign Status for these Opportunities.<br>';
                 
            if(otherExceptions.size()>0){
                body += '<b><Strong> Other Exceptions<br> </Strong></b>';
                for(String ex : otherExceptions ){
                    body += '<Strong> Exception Message : ' + ex + '</Strong><br>';
                }
            }        
            body += '</body> </html>';  
            mail.setHtmlBody(body);
            Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
            String csvData = 'Id,Exception,Record Link\n';
            for(String idOfFailedRecord : mapOfOppId2FailureReason.keySet()){
                csvData += idOfFailedRecord + ',' + mapOfOppId2FailureReason.get(idOfFailedRecord).escapeCSV() + ',' + 'gumgum.lightning.force.com/lightning/r/Opportunity/'+idOfFailedRecord+'/view'+ '\n';
            }
            Blob csvBlob = blob.valueOf(csvData);
            String csvName = 'errors.csv';
            csvAttachment.setFileName(csvName);
            csvAttachment.setBody(csvBlob);
            mail.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttachment});
            List<Messaging.SendEmailResult> emailResultList = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
            
            //Checking Mail Status
            for(Messaging.sendEmailResult emailResult: emailResultList){
                if(emailResult.isSuccess()){
                    system.debug('Success');
                }else{
                    system.debug(emailResult.getErrors());
                    for(Messaging.SendEmailError er : emailResult.getErrors()){
                        system.debug(er.getMessage());    
                    }
                }
            }
        }
    }
    
    public void execute(SchedulableContext sc){
        OpportunityCampaignStatusBatch batchJob = new OpportunityCampaignStatusBatch();
        database.executeBatch(batchJob,1);
    }
    
}