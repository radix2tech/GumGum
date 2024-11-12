public with sharing class CollectWorkflowEmailAlertQueueable implements Queueable, Database.AllowsCallouts {
	
	id currentSnapShotId {get; set;}
	string sessionId {get; set;}
	list<Item_Snapshot__c> itsnList {get;set;}

	public CollectWorkflowEmailAlertQueueable(string sesnId, list<Item_Snapshot__c> itemSnapList) {
		system.debug(logginglevel.ERROR, '*****sesnId='+sesnId);
		sessionId = sesnId;
		itsnList = new list<Item_Snapshot__c>();
		itsnList.addall(itemSnapList);
	}

	public void execute(QueueableContext context) {
		CollectWorkflowEmailAlertBatch batch = new CollectWorkflowEmailAlertBatch(sessionId, itsnList);
		system.debug(logginglevel.ERROR, '*****sessionId='+sessionId);
		database.executebatch(batch, 1);
	}
}