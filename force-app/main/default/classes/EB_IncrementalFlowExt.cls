/**
 *  ================================================================================================
 *    Version     Date             Author                          Comment
 *  ================================================================================================
 *    v1.0     Sept-26-2016     Nupur Singh     Apex controller to redirect to new Opportunity 
 *                                              detail page on finish of Incremental flow. 
 */
 
public with sharing class EB_IncrementalFlowExt {
    
    //Instance of the Flow
    public Flow.Interview.Opportunity_Advertising_Incremental myFlow {get; set;}
    
    public EB_IncrementalFlowExt(ApexPages.StandardController controller) {
    }
    
    /**
     * method to redirect to newly created Opportunity record
     */
    public PageReference getNewOpportunityRecord() {
        if(myFlow == null)
            return null;
        else
            return new PageReference('/' + myFlow.var_IncrementalOpptyID);
    }
    
}