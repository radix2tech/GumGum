public class CollectValidationRulesBatch implements Database.Batchable<string>, Database.Stateful, Database.AllowsCallouts {

	list<String> fullnameList {get; set;}
	map<String, MetadataService.FileProperties> filePropertiesMap {get; set;}
	list<MetadataService.IReadResult> readResult = new list<MetadataService.IReadResult>();
	id snapShotId {get; set;}
	MetadataService.MetadataPort service {get; set;}

	public CollectValidationRulesBatch(id currentSnapShotId, string sessionId) {
		snapShotId = currentSnapShotId;
		service = new MetadataService.MetadataPort();
		system.debug(logginglevel.ERROR, '*****service.endpoint_x=' + service.endpoint_x);
		if (service.endpoint_x.startsWithIgnoreCase('http:')) {
			service.endpoint_x = service.endpoint_x.removeStartIgnoreCase('http');
			service.endpoint_x = 'https' + service.endpoint_x;
		}
		system.debug(logginglevel.ERROR, '*****service.endpoint_x=' + service.endpoint_x);
		service.SessionHeader = new MetadataService.SessionHeader_element();
		service.SessionHeader.sessionId = sessionId;
		List<MetadataService.ListMetadataQuery> queries = new List<MetadataService.ListMetadataQuery>();
		MetadataService.ListMetadataQuery currentQuery = new MetadataService.ListMetadataQuery();
		currentQuery.type_x = 'ValidationRule';
		queries.add(currentQuery);
		MetadataService.FileProperties[] fileProperties = service.listMetadata(queries, 30);
		filePropertiesMap = new map<String, MetadataService.FileProperties>();
		fullnameList = new list<String>();
		if(fileProperties != null){
			for (MetadataService.FileProperties fileProperty : fileProperties) {
				filePropertiesMap.put(fileProperty.fullName, fileProperty);
				fullnameList.add(fileProperty.fullName);
			}
		}			
	}

	public Iterable<String> start(Database.BatchableContext BC) {
		return fullnameList;
	}

	public void execute(Database.BatchableContext BC, List<String> fullnameList) {
		MetadataService.IReadResult result = service.readMetadata('ValidationRule', fullnameList);
		readResult.add(result);
	}

	public void finish(Database.BatchableContext BC) {
		list<Item_Snapshot__c> itsnList = new list<Item_Snapshot__c>();
		for (MetadataService.IReadResult result : readResult) {
			for (MetadataService.Metadata rules : result.getRecords()) {
				MetadataService.ValidationRule rule = (MetadataService.ValidationRule) rules;
				MetadataService.FileProperties fileProperty = filePropertiesMap.get(rule.fullName);
				system.debug(logginglevel.ERROR, '*****rule=' + rule);
				system.debug(logginglevel.ERROR, '*****fileProperty=' + fileProperty);
				Item_Snapshot__c itsn = new Item_Snapshot__c();
				itsn.Active__c = rule.active;
				itsn.Error_Condition_Formula__c = rule.errorConditionFormula;
				itsn.Error_Message__c = rule.errorMessage;
				itsn.Item_Full_Name__c = fileProperty.fullName.substringAfter('.').replace('_', ' ');
				itsn.name = fileProperty.fullName.substringAfter('.').replace('_', ' ').left(80);
				itsn.Object__c = rule.fullName.substringBefore('.');
				itsn.Description__c = rule.description;
				itsn.Last_Modified_Date__c = fileProperty.lastModifiedDate;
				itsn.Last_Modified_By__c = fileProperty.lastModifiedById;
				itsn.Object_Id__c = fileProperty.id;
				itsn.System_Snapshot__c = snapShotId;
				itsn.Type__c = 'Validation Rule';
				itsn.Created_By__c = fileProperty.CreatedById;
				itsn.Created_Date__c = fileProperty.CreatedDate;
				system.debug(logginglevel.ERROR, '*****itsn=' + itsn);
				itsnList.add(itsn);
			}
		}
		Try{
			insert itsnList;
		}
		Catch(exception e){
			system.debug(logginglevel.info, '*****'+e);
		}
	}

	//used for the item snapshots that needs attatchments.
	public class SnapshotWrapper {
		public Item_Snapshot__c itsn {get; set;}
		public Attachment att {get; set;}
	}

}