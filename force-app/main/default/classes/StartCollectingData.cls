public with sharing class StartCollectingData {

	public System_Snapshot__c currentSnapShot {get;set;}
	list<Item_Snapshot__c> itemSnapshotsToInsert {get;set;}
	list<Item_Snapshot__c> itemSnapshotsNeedingAttachments {get;set;}

	//creates the system snapshot in the variable called currentSnapShot
	public StartCollectingData() {
		currentSnapShot = new System_Snapshot__c(Time_Snapshot_Started__c = datetime.now());
	}

	public StartCollectingData(ApexPages.StandardController controller) {
		currentSnapShot = new System_Snapshot__c(Time_Snapshot_Started__c = datetime.now());
	}

	//collects the item snapshots
	public Void CollectItemSnapshots(){
		itemSnapshotsToInsert = new list<Item_Snapshot__c>();
		itemSnapshotsNeedingAttachments = new list<Item_Snapshot__c>();
		list<Item_Snapshot__c> allItemSnapshotList = new list<Item_Snapshot__c>();
		insert currentSnapShot;
		//collect Apex classes
			ID apexJob = System.enqueueJob(new CollectApexQueueable(currentSnapShot.id, UserInfo.getSessionId()));
			//list<Item_Snapshot__c> apexClassSnapShotList = CollectApexInfo.StartApexCollection(currentSnapShot.id);
			//allItemSnapshotList.addall(apexClassSnapShotList);
		//collect objects
			ID objectJob = System.enqueueJob(new CollectObjectsQueueable(currentSnapShot.id, UserInfo.getSessionId()));
			//list<Item_Snapshot__c> sobjectSnapShotList = CollectObjects.StartObjectCollection(currentSnapShot.id);
			//allItemSnapshotList.addall(sobjectSnapShotList);
		//collect Validation rules these are finished and inserted by the batch process they are not returned.
			ID validationRuleJob = System.enqueueJob(new CollectValidationRulesQueueable(currentSnapShot.id, UserInfo.getSessionId()));
		//collect Triggers		
			ID triggerJob = System.enqueueJob(new CollectApexTriggersQueueable(currentSnapShot.id, UserInfo.getSessionId()));
			//list<Item_Snapshot__c> apexTriggerSnapShotList = CollectApexTriggers.StartApexCollection(currentSnapShot.id);
			//allItemSnapshotList.addall(apexTriggerSnapShotList);
		//collect Workflow rules these are finished and inserted by the batch process they are not returned.
			/*
			This method stacks a number of different queueable and batch classes together.  Here is the order:
			CollectWorkflowRuleQueueable -> CollectWorkflowRuleBatch -> 
			CollectWorkflowFieldUpdateQueueable -> CollectWorkflowFieldUpdateBatch -> 
			CollectWorkflowTaskQueueable -> CollectWorkflowTaskBatch -> 
			CollectWorkflowEmailAlertQueueable -> CollectWorkflowEmailAlertBatch
			*/
			ID workflowRuleJob = System.enqueueJob(new CollectWorkflowRuleQueueable(currentSnapShot.id, UserInfo.getSessionId()));
		//Collect flow and process builder information.
			ID flowStartQueable = System.enqueueJob(new CollectFlowStart(currentSnapShot.id, UserInfo.getSessionId()));
			
	}




}