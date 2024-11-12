/**
 * MC, RA, 07/15/2020
 * Automation for OLI
 */
trigger OLIAutomationTrigger on OpportunityLineItem (after insert, after Update) {
    Set<Id> oppIds = new Set<Id>();
    for(OpportunityLineItem item: Trigger.new) {
        // if the total price changes for the opp line due to change in schedule
        /*if(Trigger.isUpdate && 
           Trigger.isBefore && item.TotalPrice != Trigger.oldmap.get(item.id).TotalPrice && 
           item.Processing_Status__c == 'Processed') {
            item.Processing_Status__c = 'New';
        }*/
        if(item.Processing_Status__c == 'New') {
            oppIds.add(item.opportunityId);
        }
    }    
    if(oppIds.size() > 0) {
        //if(Trigger.isBefore) {
            MC_OLIAutomationHelper.setOppToReprocess(oppIds);
        //}        
        //if(Trigger.isAfter && !MC_OLIAutomationHelper.hasExecuted) {
            //MC_OLIAutomationHelper.process(oppIds);
        //}
    }
}