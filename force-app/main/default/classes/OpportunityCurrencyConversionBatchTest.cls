/*
Name           : OpportunityCurrencyConversionBatchTest
Description    : This is a test class for OpportunityCurrencyConversionBatch
Created Date   : 20-07-2023
Created By     : Kiran
*/
@isTest
public class OpportunityCurrencyConversionBatchTest {
    @isTest
    public static void testMethod1(){
        Account acc = new Account();
        acc.Name = 'Test';
        acc.Type = '3rd Party Supplier';
        acc.Account_Region__c = '	US - Central';
        acc.Industry = 'Automotive';
        insert acc;
        Opportunity opp1 = new Opportunity(AccountId= acc.id,Agency_Name__c=acc.id,
                                           Start_Date__c = System.Today(),
                                           End_Date__c =System.Today()+ 100,
                                           name = acc.Name + 'test1',
                                           CloseDate= System.Today()+ 3,
                                           Primary_KPI__c='Action Rate',
                                           Amount=500,  
                                           StageName = 'Closed/Won'); 
        insert opp1;
        Date d1 = date.newInstance(2023, 02, 01);
        Date d2 = system.today() +5;
        Database.executeBatch(new OpportunityCurrencyConversionBatch(d1,d2),1);
        Map<String,String> mapOfOppId2FailureReason = new Map<String,String>();
        mapOfOppId2FailureReason.put('testId','testReason');
        List<String> otherExceptions = new List<String>();
        OpportunityCurrencyConversionBatch.sendExceptionEmailToSupport(mapOfOppId2FailureReason,otherExceptions);      
    }
}