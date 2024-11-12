public with sharing class TDGOpportunityTriggerHandler {
    public static final String SETTING_NAME = Test.isRunningTest() ? 'TestContext' : 'Default';
    
    public void afterInsert(List<Opportunity> newList) {
        updateRegion(newList, null);
    }

    public void afterUpdate(List<Opportunity> newList, Map<ID, Opportunity> oldMap) {
        updateRegion(newList, oldMap);
    }

    private void updateRegion(List<Opportunity> newList, Map<ID, Opportunity> oldMap) {
        if(!General_Setting__mdt.getInstance(SETTING_NAME).Enable_TDG_Opportunity_Trigger__c) return;
        List<Opportunity> oppsToProcess = new List<Opportunity>();

        for(Opportunity opp : newList) {
            if(oldMap != null) {
                Opportunity oldOpp = oldMap.get(opp.Id);

                if(opp.OwnerId == oldOpp.OwnerId) continue;
            }

            if(opp.Opportunity_Owner_Region__c != null) {
                oppsToProcess.add(new Opportunity(
                    ID = opp.Id,
                    Opportunity_Region__c = opp.Opportunity_Owner_Region__c
                ));
            }
        }

        if(oppsToProcess.size() > 0) {
            update oppsToProcess;
        }
    }
}