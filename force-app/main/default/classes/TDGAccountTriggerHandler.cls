/*
Description       : TDGAccountTriggerHandler
Last Updated Date : 20-03-2023
Last Updated By   : Kiran
Change Request    : Skips the trigger if the Record Type is 'Billing Entity' and User = 'Billing Integrations'
*/
public class TDGAccountTriggerHandler {
    public static final String SETTING_NAME = Test.isRunningTest() ? 'TestContext' : 'Default';

    public void afterInsert(List<Account> newList) {
        updateRegion(newList, null);
    }

    public void afterUpdate(List<Account> newList, Map<ID, Account> oldMap) {
        updateRegion(newList, oldMap);
    }

    private void updateRegion(List<Account> newList, Map<ID, Account> oldMap) {
        if(!General_Setting__mdt.getInstance(SETTING_NAME).Enable_TDG_Account_Trigger__c) return; 
        List<Account> accsToProcess = new List<Account>();
        Id billingEntityRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get(Label.Billing_Entity_Record_Type).getRecordTypeId();
        for(Account acc : newList) {
            if(acc.RecordTypeId==billingEntityRecordTypeId && UserInfo.getUserId()==Label.Billing_Integration_UserId) continue;
            if(oldMap != null) {
                Account oldAcc = oldMap.get(acc.Id);
                if(acc.OwnerId == oldAcc.OwnerId) continue;
            }
            
            accsToProcess.add(new Account(
                ID = acc.Id,
                Account_Region__c = acc.Account_Owner_User_Region__c
            ));
        }

        if(accsToProcess.size() > 0) {
            update accsToProcess;
        }
    }
}