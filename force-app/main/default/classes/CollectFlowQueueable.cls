public with sharing class CollectFlowQueueable implements Queueable, Database.AllowsCallouts {

	id currentSnapShotId {get; set;}
	string sessionId {get; set;}
	list<MetadataServiceExtension.FlowFileExtensionWrapper> flowList {get;set;}
	Integer numberInList {get;set;}
	Integer versionNumber {get;set;}

	public CollectFlowQueueable (id currentSnapShotId1, string sessionId1, list<MetadataServiceExtension.FlowFileExtensionWrapper> flowList1, Integer numberInList1, Integer versionNumber1) {
		currentSnapShotId = currentSnapShotId1;
		sessionId = sessionId1;
		flowList = flowList1;
		numberInList = numberInList1;
		versionNumber = versionNumber1;
	}

	public void execute(QueueableContext context) {
		CollectFlowBatch batch = new CollectFlowBatch(currentSnapShotId, sessionId, flowList, numberInList, versionNumber);
		database.executeBatch(batch,1);
	}

	
}