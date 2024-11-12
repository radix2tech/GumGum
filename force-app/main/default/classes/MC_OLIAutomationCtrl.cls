public with sharing class MC_OLIAutomationCtrl {
    public MC_OLIAutomationCtrl(){
        
    }
    public PageReference callAutomation(){
        System.debug('****');
        Set<Id> oppIds = new Set<Id>();
        List<Opportunity> lstOfOpp = [Select Id, Name, Re_calculate_Products__c from Opportunity where Re_calculate_Products__c =: true];
        System.debug('>>>o'+lstOfOpp.size());
        if(lstOfOpp.size() > 0){
            for(Opportunity o: lstOfOpp){
                oppIds.add(o.Id);
            }
        }
        if(oppIds.size() > 0){
            MC_OLIAutomationHelper.process(oppIds);
        }
        return new PageReference('/006/o');
    }
}