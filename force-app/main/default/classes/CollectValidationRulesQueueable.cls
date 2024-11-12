public with sharing class CollectValidationRulesQueueable implements Queueable, Database.AllowsCallouts {

	id currentSnapShotId {get; set;}
	string sessionId {get; set;}

	public CollectValidationRulesQueueable (id snapShotId, string sesnId) {
		currentSnapShotId = snapShotId;
		sessionId = sesnId;
	}

	public void execute(QueueableContext context) {
		CollectValidationRulesBatch batch = new CollectValidationRulesBatch(currentSnapShotId, sessionId);
		database.executebatch(batch, 1);
	}
}