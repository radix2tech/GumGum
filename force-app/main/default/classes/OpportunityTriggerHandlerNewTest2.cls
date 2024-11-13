@isTest
public class OpportunityTriggerHandlerNewTest2 {
    @testSetup
    static void testData(){
        Trigger_Setting__c tsOppConRole = new Trigger_Setting__c();
        tsOppConRole.Object_Name__c   = 'OpportunityContactRole';
        tsOppConRole.After_Insert__c = true;
        tsOppConRole.After_Update__c = true;
        tsOppConRole.Before_Delete__c = true;
        tsOppConRole.Prevent_Recursion__c = 'isPrimary';
        tsOppConRole.Name             = 'Opportunity Contact Role';
        insert tsOppConRole;
        List<Account> accList = new List<Account>();
        for(Integer i=0;i<2;i++){
            Account acc = new Account();
            acc.Name = 'Test'+i;
            acc.Type = '3rd Party Supplier';
            acc.Account_Region__c = 'US - Central';
            acc.Industry = 'Automotive';
            accList.add(acc);
        }
        insert accList;
        List<Contact> conList = new List<Contact>();
        Contact con1 = new Contact(lastName='Test');
        Contact con2 = new Contact(lastName = 'Test2');
        conList.add(con1);
        conList.add(con2);
        insert conList;
        List<Opportunity> oppList = new List<Opportunity>();
        for(Account acc: accList){
            for(Integer i=0;i<10;i++){
                 Opportunity opp1 = new Opportunity(AccountId= acc.id,Agency_Name__c=acc.id,
                                           Start_Date__c = System.Today(),
                                           End_Date__c =System.Today()+ 100,
                                           name = acc.Name + 'i',
                                           CloseDate= System.Today()+ 3,
                                           SalesLoft1__Primary_Contact__c = conList[0].Id,
                                           Primary_KPI__c='Action Rate',
                                          // Why_GumGum__c='Attention',
                                           Amount=500,
                                           //Business_Objective__c = 'Acquire new customers',         
                                           StageName = (i==2?'Closed/Lost':'Initial call')); 
                oppList.add(opp1);
            }
        }
        insert oppList;
    }
    @isTest
    public static void method1(){
        List<Account> accList = [SELECT id,Only_Agency_Opp_Count__c FROM Account];
        system.assertEquals(10, accList[0].Only_Agency_Opp_Count__c);
        List<Opportunity> oppList = [SELECT Id,stageName,AccountId,Agency_Name__c FROM Opportunity WHERE Agency_Name__c = :accList[0].Id AND stageName='Initial call'];
        system.assertEquals(9, oppList.size());
        oppList[0].Agency_Name__c = accList[1].Id;
        oppList[1].stageName = 'Closed/Lost';
        oppList[1].Amount = 1000;
        update oppList;
        List<Account> accList2 = [SELECT Id,Only_Agency_Opp_Count__c,Only_Agency_Opp_Won_Count__c,Only_Agency_Open_Opp_Count__c,Only_Agency_Open_and_Won_Opp_Count__c FROM Account WHERE Id=:accList[0].Id OR Id = :accList[1].Id];
        system.assertEquals(9,accList2[0].Only_Agency_Opp_Count__c);
        system.assertEquals(7, accList2[0].Only_Agency_Open_Opp_Count__c);
        system.assertEquals(10, accList2[1].Only_Agency_Open_Opp_Count__c);
        system.assertEquals(11,accList2[1].Only_Agency_Opp_Count__c);
    }
}