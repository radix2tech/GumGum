public with sharing class OliScheduleTriggerHandler {
	//public OliScheduleTriggerHandler() {
		
	//}

	//public void changeOppStartEndDates(Map<Id, OpportunityLineItem> mapOli) {

	//	Set<Id> setOppId = new Set<Id>();
	//	Map<Id, Opportunity> mapOpp;
	//	Map<Id, OpportunityLineItem> mapAllOliForOpp;
	//	Map<Id, List<OpportunityLineItemSchedule>> mapOppSchedules = new Map<Id, List<OpportunityLineItemSchedule>>();
	//	List<OpportunityLineItemSchedule> lstOliSchedule = new List<OpportunityLineItemSchedule>();

	//	// Collect Ids for all relevant Opportunities.
	//	for (OpportunityLineItem oli : mapOli.values()) {
	//		setOppId.add(oli.OpportunityId);
	//	}

	//	// Map of Opportunities.
	//	mapOpp = new Map<Id, Opportunity>([	SELECT Id, Start_Date__c, End_Date__c
	//										FROM Opportunity
	//										WHERE Id IN :setOppId ]);

	//	// Map of all OpportunityLineItems related to the relevant Opportunities.
	//	mapAllOliForOpp = new Map<Id, OpportunityLineItem>([SELECT Id, OpportunityId
	//														FROM OpportunityLineItem
	//														WHERE OpportunityId IN :setOppId ]);

	//	// Map of the OpportunityLineItemSchedules related to the relevant OpportunityLineItems.
	//	lstOliSchedule = [	SELECT Id, ScheduleDate, OpportunityLineItemId
	//						FROM OpportunityLineItemSchedule
	//						WHERE OpportunityLineItemId IN :mapAllOliForOpp.keySet() ];

	//	// Loop through each relevant OpportunityLineItemSchedule and add it to a list of schedules
	//	// that is part of a map with the OpportunityId as the key.
	//	for (OpportunityLineItemSchedule oliSchedule : lstOliSchedule) {
	//		OpportunityLineItem oli = mapAllOliForOpp.get(oliSchedule.OpportunityLineItemId);

	//		if (mapOppSchedules.containsKey(oli.OpportunityId)) {
	//			List<OpportunityLineItemSchedule> tempList = mapOppSchedules.get(oli.OpportunityId);
	//			tempList.add(oliSchedule);
	//			mapOppSchedules.put(oli.OpportunityId, tempList);
	//		} else {
	//			List<OpportunityLineItemSchedule> newList = new List<OpportunityLineItemSchedule>();
	//			newList.add(oliSchedule);
	//			mapOppSchedules.put(oli.OpportunityId, newList);
	//		}

	//	}

	//	for (Id oppId : setOppId) {
	//		OppDates oppDates = new OppDates();

	//		// Loop through each relevant OpportunityLineItemSchedule and determine the earliest date and the latest date.
	//		for (OpportunityLineItemSchedule oliSchedule : mapOppSchedules.get(oppId)) {
			
	//			// Check for earliest date.
	//			if (oppDates.dateEarliest == null || oliSchedule.ScheduleDate < oppDates.dateEarliest) {
	//				oppDates.dateEarliest = oliSchedule.ScheduleDate;
	//			}

	//			// Check for latest date.
	//			if (oppDates.dateLatest == null || oliSchedule.ScheduleDate > oppDates.dateLatest) {
	//				oppDates.dateLatest = oliSchedule.ScheduleDate;
	//			}

	//		}

	//		// Update the Opportunity in the map with the earliest date as the start date and the latest date as the end date.
	//		mapOpp.get(oppId).Start_Date__c = oppDates.dateEarliest;
	//		mapOpp.get(oppId).End_Date__c = oppDates.dateLatest;
	//	}

	//	update mapOpp.values();

	//}

	//// Holds the earliest date and the latest date for an Opportunity.
	//private class OppDates {
	//	public Date dateEarliest	{get;set;}
	//	public Date dateLatest		{get;set;}
	//}
}