public with sharing class CollectWorkflowRuleQueueable implements Queueable, Database.AllowsCallouts {

	id currentSnapShotId {get; set;}
	string sessionId {get; set;}

	public CollectWorkflowRuleQueueable(id snapShotId, string sesnId) {
		currentSnapShotId = snapShotId;
		sessionId = sesnId;
	}

	public void execute(QueueableContext context) {
		CollectWorkflowRuleBatch batch = new CollectWorkflowRuleBatch(currentSnapShotId, sessionId);
		database.executebatch(batch, 1);
	}

}