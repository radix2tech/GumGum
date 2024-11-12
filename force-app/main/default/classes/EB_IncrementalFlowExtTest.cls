/**
 *  ================================================================================================
 *    Version     Date          Author                          Comment
 *  ================================================================================================
 *    v1.0     Sept-26-2016   Nupur Singh       Test class to test the functionality of visualforce
 *                                              page 'EB_IncrementalFlow'.
 */
@isTest
private class EB_IncrementalFlowExtTest {
    
    /**
     * method to test functionality of visualforce page 'EB_IncrementalFlow'
     */
    static testMethod void testIncrementalFlowExt() {
        
        Account objAccount = new Account();
        objAccount.Name = 'Test Account 001';
        insert objAccount;
        
        Id RecordTypeIdOpp = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Dental').getRecordTypeId();
        
        Opportunity objOpportunity = new Opportunity();
        objOpportunity.Recordtypeid=RecordTypeIdOpp;
        objOpportunity.Name = 'Test Opp 001';
        objOpportunity.Account__c = objAccount.Id;
        objOpportunity.StageName = 'Proposal';
        objOpportunity.CloseDate = System.Date.today();
        objOpportunity.Agency_Name__c = objAccount.id;
        insert objOpportunity;
        
        PageReference pageRef = Page.EB_IncrementalFlow;
        Test.setCurrentPage(pageRef);
        ApexPages.StandardController stdController = new ApexPages.StandardController(objOpportunity);
        EB_IncrementalFlowExt objIncrementalFlowExt = new EB_IncrementalFlowExt(stdController);
        
        PageReference newPageRef = objIncrementalFlowExt.getNewOpportunityRecord();
        
        Map<String, Object> valueMap = new Map<String, Object>();
        valueMap.put('var_OpptyID', objOpportunity.Id);
        valueMap.put('var_IncrementalOpptyID', objOpportunity.Id);
        
        System.Test.startTest();
        
        objIncrementalFlowExt.myFlow = new Flow.Interview.Opportunity_Advertising_Incremental(valueMap);
        try {
            newPageRef = objIncrementalFlowExt.getNewOpportunityRecord();
        }
        catch(Exception exp) {
            system.debug(exp);
        }
        System.Test.stopTest();
        
        System.assertEquals(newPageRef,null);
        
    }
}