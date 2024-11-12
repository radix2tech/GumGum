/*
Name           : OpportunityCurrencyConversionBatch
Description    : This Batch updates the Currency Conversion rate field on Opportunity for the give range of Close Dates
Created Date   : 12-07-2023
Created By     : Kiran
Test Class     : OpportunityCurrencyConversionBatchTest
*/
public class OpportunityCurrencyConversionBatch implements Database.Batchable<sObject>,Database.Stateful {
    
    public Date startCloseDate;
    public Date endCloseDate;
    public Map<String,String> mapOfOppId2FailureReason;
    public List<String> otherExceptions;
    
    public OpportunityCurrencyConversionBatch(Date startDate, Date endDate){
        startCloseDate = startDate;
        endCloseDate = endDate;
        otherExceptions = new List<String>();
        mapOfOppId2FailureReason = new Map<String,String>();
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        String query =  'SELECT Id,Amount,CloseDate,Currency_Conversion_Rate__c FROM Opportunity WHERE Amount>0 and StageName =\'Closed/Won\' and CloseDate>='+String.escapeSingleQuotes(String.ValueOf(startCloseDate)) + ' AND CloseDate <='+String.escapeSingleQuotes(String.ValueOf(endCloseDate));   
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Opportunity> scope){
        try{    
            List<Opportunity> oppList = [SELECT Id,ConvertCurrency(Amount) FROM Opportunity WHERE Id in : scope];
            Map<Id,Opportunity> newConvertedMap = new Map<Id,Opportunity>([SELECT Id,ConvertCurrency(Amount),Currency_Conversion_Rate__c FROM Opportunity WHERE Id in : scope]);
            for(Opportunity opp: scope){
                if(newConvertedMap.containsKey(opp.Id)){
                    //e.g,. GBP/USD
                    opp.Currency_Conversion_Rate__c = opp.Amount / newConvertedMap.get(opp.Id).Amount;
                    opp.Currency_Conversion_Rate__c = opp.Currency_Conversion_Rate__c.setScale(6);
                }
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
            mail.setSubject('Currency Conversion Rate Update Failures');  
            List<String> toAddress = new List<String>{Label.CurrencyConversionBatchErrorEmail};
            mail.setToAddresses(toAddress);
            
            /*List<OrgWideEmailAddress> orgWideEmailList = [SELECT Id, Address FROM OrgWideEmailAddress where Address = 'kirankumar.punuru@ic.gumgum.com ' limit 1];
            if(orgWideEmailList.size()>0){
                //mail.setOrgWideEmailAddressId(orgWideEmailList[0].Id);
            }
            Id testOrgWideEmail = '0D277000000KyvvCAC';
            mail.setOrgWideEmailAddressId(testOrgWideEmail);*/
            
            // Create Body      
            String body = '<html xmlns="http://www.w3.org/1999/xhtml"><head><meta http-equiv="Content-Type" content="text/html; charset=utf-8" /><title>Untitled Document</title><style type="text/css">table,tr{border: 1px solid black; border-collapse:collapse;} </style> </head>';       
            body += 'Hi Team,<br>';
            body += 'Please find the Opportunities which are failed to update the currency conversion rate due to the errors in the excel sheet attached.<br>';
            body += 'Please review and take action to update conversion rates for these Opportunities.<br>';
      
            /*if(mapOfOppId2FailureReason.keySet().size()>0){
                body += '<table style="width:100%">';
                body += '<tr><th align="middle" valign="middle" class="table_body_text" Style="background:#314C67; color: white; width:400px"> Id </th> <th align="middle" valign="middle" class="table_body_text" Style="background:#314C67; color: white; width:400px"> Exception </th> </tr>'; 
                for(Id idOfFailedRecord : mapOfOppId2FailureReason.keySet()){
                    //body += '<Strong>Id : '+ i+' Exception Message :' + IdToFailReason.get(i) + '</Strong><br>';
                    body += '<tr><td width="140" align="middle" valign="middle" class="table_body_text"> ' + idOfFailedRecord + ' </td> <td width="140" align="middle" valign="middle" class="table_body_text"> ' +mapOfOppId2FailureReason.get(idOfFailedRecord)+ ' </td></td>';
                }
                body += '</table></td></tr><br><br>';  
            }*/
            
            if(otherExceptions.size()>0){
                body += '<b><Strong> Other Exceptions<br> </Strong></b>';
                for(String ex : otherExceptions ){
                    body += '<Strong> Exception Message : ' + ex + '</Strong><br>';
                }
            }        
            body += '</body> </html>';  
            mail.setHtmlBody(body);
            Messaging.EmailFileAttachment csvAttachment = new Messaging.EmailFileAttachment();
            String csvData = 'Id,Exception\n';
            for(String idOfFailedRecord : mapOfOppId2FailureReason.keySet()){
                csvData += idOfFailedRecord + ',' + mapOfOppId2FailureReason.get(idOfFailedRecord).escapeCSV() + '\n';
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
}