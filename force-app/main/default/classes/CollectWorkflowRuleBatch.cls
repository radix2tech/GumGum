public class CollectWorkflowRuleBatch implements Database.Batchable<string>, Database.Stateful, Database.AllowsCallouts {

	list<String> fullnameList {get; set;}
	String ssnId {get;set;}
	map<String, MetadataService.FileProperties> filePropertiesMap {get; set;}
	list<MetadataService.IReadResult> readResult = new list<MetadataService.IReadResult>();
	id snapShotId {get; set;}
	MetadataService.MetadataPort service {get; set;}
	list<Item_Snapshot__c> workflowSnapshotsWithFieldUpdates {get;set;}

	public CollectWorkflowRuleBatch(id currentSnapShotId, string sessionId) {
		snapShotId = currentSnapShotId;
		ssnId = sessionId;
		service = new MetadataService.MetadataPort();
		system.debug(logginglevel.ERROR, '*****service.endpoint_x=' + service.endpoint_x);
		if (service.endpoint_x.startsWithIgnoreCase('http:')) {
			service.endpoint_x = service.endpoint_x.removeStartIgnoreCase('http');
			service.endpoint_x = 'https' + service.endpoint_x;
		}
		service.SessionHeader = new MetadataService.SessionHeader_element();
		service.SessionHeader.sessionId = sessionId;
		List<MetadataService.ListMetadataQuery> queries = new List<MetadataService.ListMetadataQuery>();
		MetadataService.ListMetadataQuery currentQuery = new MetadataService.ListMetadataQuery();
		currentQuery.type_x = 'WorkflowRule';
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
		MetadataService.IReadResult result = service.readMetadata('WorkflowRule', fullnameList);
		readResult.add(result);
	}

	public void finish(Database.BatchableContext BC) {
		list<Item_Snapshot__c> itsnList = new list<Item_Snapshot__c>();
		workflowSnapshotsWithFieldUpdates = new list<Item_Snapshot__c>();
		for (MetadataService.IReadResult result : readResult) {
			for (MetadataService.Metadata rules : result.getRecords()) {
				MetadataService.WorkflowRule rule = (MetadataService.WorkflowRule) rules;
				MetadataService.FileProperties fileProperty = filePropertiesMap.get(rule.fullName);
				Item_Snapshot__c itsn = new Item_Snapshot__c();
				itsn.Active__c = rule.active;
				itsn.Description__c = rule.description;
				itsn.Object__c = rule.fullName.substringBefore('.');
				itsn.Name = fileProperty.fullName.substringAfter('.').replace('_', ' ').left(80);
				itsn.Item_Full_Name__c = fileProperty.fullName.substringAfter('.').replace('_', ' ');
				itsn.Evaluation_Criteria__c = rule.triggerType;
				if (rule.criteriaItems == null) {
					itsn.Filter_or_Formula__c = 'Formula';
				} else {
					itsn.Filter_or_Formula__c = 'Filter';
				}
				if (rule.criteriaItems != null) {
					integer i = 1;
					itsn.Filter_Criteria__c = '';
					for (MetadataService.FilterItem fi : rule.criteriaItems) {
						itsn.Filter_Criteria__c += i + ' - ' + fi.field + ' ' + fi.operation + ' ';
						if (fi.valueField != null) {
							itsn.Filter_Criteria__c += fi.valueField;
						} else {
							itsn.Filter_Criteria__c += fi.value;
						}
						itsn.Filter_Criteria__c += ' \n';
						i++;
					}
					if (rule.booleanFilter != null) {
						itsn.Filter_Logic__c = rule.booleanFilter;
					}
				}
				if (rule.formula != null) {
					itsn.Rule_Criteria_Formula__c = rule.formula;
				}
				if(rule.actions != null){
					itsn.Workflow_Action_Name_Type__c = '';
					for(MetadataService.WorkflowActionReference wfar : rule.actions){
						itsn.Workflow_Action_Name_Type__c += itsn.Object__c + '.' + wfar.name + '|';
					}
				}
				itsn.Created_By__c = fileProperty.CreatedById;
				itsn.Created_Date__c = fileProperty.CreatedDate;
				itsn.Last_Modified_Date__c = fileProperty.lastModifiedDate;
				itsn.Last_Modified_By__c = fileProperty.lastModifiedById;
				itsn.Object_Id__c = fileProperty.id;
				itsn.System_Snapshot__c = snapShotId;
				itsn.Type__c = 'Workflow Rule';
				itsnList.add(itsn);
				if(rule.actions != null){
					for(MetadataService.WorkflowActionReference wfar : rule.actions){
						if(wfar.type_x == 'FieldUpdate'){
							workflowSnapshotsWithFieldUpdates.add(itsn);
						}
					}
				}
			}
		}
		Try{
			insert itsnList;
			ID workflowAlertJob = System.enqueueJob(new CollectWorkflowFieldUpdateQueueable(ssnId,itsnList));
		}
		Catch(exception e){
			system.debug(logginglevel.info, '*****'+e);
		}
	}

}