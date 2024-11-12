@istest
public class OpportunityCampaignStatusBatchTest {
     @isTest
    public static void testMethod1(){
        Account acc = new Account();
        acc.Name = 'Test';
        acc.Type = '3rd Party Supplier';
        acc.Account_Region__c = 'US - Central';
        acc.Industry = 'Automotive';
        insert acc;
        
        Opportunity opp1 = new Opportunity(AccountId= acc.id,Agency_Name__c=acc.id,
                                           Start_Date__c = System.Today(),
                                           End_Date__c =System.Today()+ 100,
                                           name = acc.Name + 'test1',
                                           CloseDate= System.Today()+ 3,
                                           Primary_KPI__c='Action Rate',
                                           Amount=500, 
                                           CurrencyIsoCode='USD',
                                           StageName = 'Closed/Won'); 
        insert opp1;
        opp1.Pricebook2Id= Test.getStandardPricebookId();
        update opp1;
        

        Product2 product = new Product2();
        product.Name = 'Test Product';
        product.CanUseQuantitySchedule = true;
        product.CanUseRevenueSchedule = true;
        insert product;
        PricebookEntry pbe = new PricebookEntry();
        pbe.Pricebook2Id = Test.getStandardPricebookId();
        pbe.Product2Id = product.Id;
        pbe.UnitPrice = 1.5;
        pbe.CurrencyIsoCode = 'USD';
        pbe.IsActive = true;
        insert pbe;
                
        //Adding Opportunity Product
        Date d1 = date.newInstance(2023, 02, 01);
        Date d2 = d1-10;
        OpportunityLineItem oli = new OpportunityLineItem();
        oli.OpportunityId= opp1.Id;
        oli.TotalPrice = 100;
        oli.End_Date__c = d1;
        oli.Start_Date__c = d2; 
        oli.Pricing__c = 'CPM';
        oli.PricebookEntryId = pbe.ID;
        oli.Quantity = 200;
        insert oli; 
        
        Database.executeBatch(new OpportunityCampaignStatusBatch(),1);
        Map<String,String> mapOfOppId2FailureReason = new Map<String,String>();
        mapOfOppId2FailureReason.put('testId','testReason');
        List<String> otherExceptions = new List<String>();
        OpportunityCampaignStatusBatch.sendExceptionEmailToSupport(mapOfOppId2FailureReason,otherExceptions);    
        
        String CRON_EXP = '0 0 0 * * ?';
        String jobId = System.schedule('Campaign Status Job',CRON_EXP, new OpportunityCampaignStatusBatch());
    }

}