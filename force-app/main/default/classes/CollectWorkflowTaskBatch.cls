public with sharing class CollectWorkflowTaskBatch implements Database.Batchable<string>, Database.Stateful, Database.AllowsCallouts {

	list<Item_Snapshot__c> itsnList {get;set;}
	String ssnId {get;set;}
	list<String> fullnameList {get; set;}
	map<String, MetadataService.FileProperties> filePropertiesMap {get; set;}
	list<MetadataService.IReadResult> readResult = new list<MetadataService.IReadResult>();
	MetadataService.MetadataPort service {get; set;}
	
	public CollectWorkflowTaskBatch(string sessionId, list<Item_Snapshot__c> itemSnapList) {
		system.debug(logginglevel.ERROR, '*****sessionId='+sessionId);
		itsnList = new list<Item_Snapshot__c>();
		itsnList.addall(itemSnapList);
		service = new MetadataService.MetadataPort();
		if (service.endpoint_x.startsWithIgnoreCase('http:')) {
			service.endpoint_x = service.endpoint_x.removeStartIgnoreCase('http');
			service.endpoint_x = 'https' + service.endpoint_x;
		}
		ssnId = sessionId;
		service.SessionHeader = new MetadataService.SessionHeader_element();
		service.SessionHeader.sessionId = sessionId;
		List<MetadataService.ListMetadataQuery> queries = new List<MetadataService.ListMetadataQuery>();
		MetadataService.ListMetadataQuery currentQuery = new MetadataService.ListMetadataQuery();
		currentQuery.type_x = 'WorkflowTask';
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
		MetadataService.IReadResult result = service.readMetadata('WorkflowTask', fullnameList);
		readResult.add(result);
	}

	public void finish(Database.BatchableContext BC) {
		list<Item_Snapshot_Task__c> istList = new list<Item_Snapshot_Task__c>();
		for (MetadataService.IReadResult result : readResult) {
			for (MetadataService.Metadata task : result.getRecords()) {
				MetadataService.WorkflowTask tsk = (MetadataService.WorkflowTask) task;
				MetadataService.FileProperties fileProperty = filePropertiesMap.get(tsk.fullName);
				Item_Snapshot_Task__c ist = new Item_Snapshot_Task__c();
					ist.name = tsk.fullName.left(80);
					ist.Description__c = tsk.description;
					ist.assignedTo__c = tsk.assignedTo;
					ist.assignedToType__c = tsk.assignedToType;
					ist.dueDateOffset__c = tsk.dueDateOffset;
					ist.Full_Name__c = tsk.fullName;
					ist.Created_By__c = fileProperty.createdById;
					ist.Created_Date__c = fileProperty.createdDate;
					ist.Last_Modified_By__c = fileProperty.lastModifiedById;
					ist.Last_Modified_Date__c = fileProperty.lastModifiedDate;
					if(tsk.notifyAssignee != null){
						ist.notifyAssignee__c = tsk.notifyAssignee;
					}					
					ist.offsetFromField__c = tsk.offsetFromField;
					ist.priority__c = tsk.priority;
					if(tsk.protected_x != null){
						ist.protected_x__c = tsk.protected_x;
					}					
					ist.status__c = tsk.status;
					ist.subject__c = tsk.subject;
				istList.add(ist);
			}
		}
		Try{
			system.debug(logginglevel.ERROR, '*****istList='+istList);
			insert istList;
			list<Task_Workflow_Junction__c> twjList = new list<Task_Workflow_Junction__c>();
			for(Item_Snapshot_Task__c ist : istList){
				for(Item_Snapshot__c itsn : itsnList){
					if(itsn.Workflow_Action_Name_Type__c != null && ist.Full_Name__c != null && itsn.Workflow_Action_Name_Type__c.contains(ist.Full_Name__c.replaceAll(' ','_'))){
						Task_Workflow_Junction__c twj = new Task_Workflow_Junction__c();
							twj.Item_Snapshot__c = itsn.id;
							twj.Item_Snapshot_Task__c = ist.id;
						twjList.add(twj);
					}
				}
			}
			insert twjList;
			ID workflowFieldUpdateJob = System.enqueueJob(new CollectWorkflowEmailAlertQueueable(ssnId,itsnList));
		}
		Catch(exception e){
			system.debug(logginglevel.info, '*****'+e);
		}
	}



}