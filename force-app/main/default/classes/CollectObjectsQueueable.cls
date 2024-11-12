public with sharing class CollectObjectsQueueable implements Queueable, Database.AllowsCallouts {

	id currentSnapShotId {get; set;}
	string sessionId {get; set;}
	
	public CollectObjectsQueueable(id snapShotId, string sesnId) {
		currentSnapShotId = snapShotId;
		sessionId = sesnId;
	}

	public void execute(QueueableContext context) {
		Map<String, Schema.SObjectType> SobjectSchemaMap = Schema.getGlobalDescribe();
		String[] objectList = CheckForCustomField(SobjectSchemaMap);
		Item_Snapshot__c[] snapshotList = ConvertObjectsToSnapshot(objectList, currentSnapShotId);
		Try{
			insert snapshotList;
			CollectFieldsBatch batch = new CollectFieldsBatch(currentSnapShotId, sessionId, snapshotList);
			database.executeBatch(batch,1);
		}
		Catch(exception e){
			system.debug(logginglevel.info, '*****'+e);
		}


	}

	String[] CheckForCustomField(Map<String, Schema.SObjectType> SobjectSchemaMap){
		list<String> returnList = new list<String>();
		for(String s : SobjectSchemaMap.keySet()){
			boolean included = false;
			Schema.DescribeSObjectResult SobjectResult = SobjectSchemaMap.get(s).getDescribe();
			Map<String, Schema.SObjectField> SobjtFieldMap = SobjectResult.fields.getMap();
			for (Schema.SObjectField SobjtField : SobjtFieldMap.values()) {
				if(SobjtField.getDescribe().getLocalName().endsWithIgnoreCase('__c')){
					returnList.add(s);
					included = true;
					break;
				}
			}
			if(included == false && s.endsWithIgnoreCase('__c')){
				returnList.add(s);
			}
		}
		return returnList;
	}

	Item_Snapshot__c[] ConvertObjectsToSnapshot(List<String> objectList,Id snapshotId){
		list<Item_Snapshot__c> itsnList = new list<Item_Snapshot__c>();
		for(String s : objectList){
			Map<String, Schema.SObjectField> SobjtField = Schema.getGlobalDescribe().get(s).getDescribe().fields.getMap();
			Item_Snapshot__c itsn = new Item_Snapshot__c();
				itsn.name = s.left(80);
				itsn.Item_Full_Name__c = s;
				itsn.Label__c = Schema.getGlobalDescribe().get(s).getDescribe().getLabel();
				//itsn.Fields__c = sobjectFieldMap.get(s);
				itsn.Type__c = 'Sobject';
				itsn.System_Snapshot__c = snapshotId;
			itsnList.add(itsn);
		}
		return itsnList;
	}

}