/*
 Author       : Kiran 
 Purpose      : To Update the contact No_longer_with_account__c field when user is deactivated.
 Created Date : 10/12/2022
 Test Class   :ContactUpdateHandlerTestClass
 */
public class ContactUpdateHandler {
    @InvocableMethod(label='Update Contact Record')
    public static void getContacts(List<String> emailIds) {
        updateContacts(emailIds);
    }
    @future
    public static void updateContacts(List<String> emailIds){
        try{
            List<Contact> lstConToUpdate = new List<Contact>();
            List<Contact> lstContacts = [SELECT Id,Email,No_longer_with_account__c FROM Contact WHERE Email in :emailIds];
            for (Contact con : lstContacts) {
                con.No_longer_with_account__c =  true;
                lstConToUpdate.add(con);
            }
            update lstConToUpdate;
        } Catch(Exception ex){
            HandleCustomException.LogException(ex);  
        } 
    }
}