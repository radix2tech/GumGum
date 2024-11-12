public class CollectWorkflowFieldUpdateBatch implements Database.Batchable<string>, Database.Stateful, Database.AllowsCallouts {
	
	list<Item_Snapshot__c> itsnList {get;set;}
	String ssnId {get;set;}
	list<String> fullnameList {get; set;}
	map<String, MetadataService.FileProperties> filePropertiesMap {get; set;}
	list<MetadataService.IReadResult> readResult = new list<MetadataService.IReadResult>();
	MetadataService.MetadataPort service {get; set;}
	
	public CollectWorkflowFieldUpdateBatch(string sessionId, list<Item_Snapshot__c> itemSnapList) {
		system.debug(logginglevel.ERROR, '*****sessionId='+sessionId);
		itsnList = new list<Item_Snapshot__c>();
		itsnList.addall(itemSnapList);
		service = new MetadataService.MetadataPort();
		if (service.endpoint_x.startsWithIgnoreCase('http:')) {
			service.endpoint_x = service.endpoint_x.removeStartIgnoreCase('http');
			service.endpoint_x = 'https' + service.endpoint_x;
		}
		service.SessionHeader = new MetadataService.SessionHeader_element();
		service.SessionHeader.sessionId = sessionId;
		ssnId = sessionId;
		List<MetadataService.ListMetadataQuery> queries = new List<MetadataService.ListMetadataQuery>();
		MetadataService.ListMetadataQuery currentQuery = new MetadataService.ListMetadataQuery();
		currentQuery.type_x = 'WorkflowFieldUpdate';
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
		MetadataService.IReadResult result = service.readMetadata('WorkflowFieldUpdate', fullnameList);
		readResult.add(result);
	}
	
	public void finish(Database.BatchableContext BC) {
		list<Item_Snapshot_Field_Update__c> isfuList = new list<Item_Snapshot_Field_Update__c>();
		for (MetadataService.IReadResult result : readResult) {
			for (MetadataService.Metadata fieldUpdate : result.getRecords()) {
				MetadataService.WorkflowFieldUpdate fu = (MetadataService.WorkflowFieldUpdate) fieldUpdate;
				MetadataService.FileProperties fileProperty = filePropertiesMap.get(fu.fullName);
				Item_Snapshot_Field_Update__c isfu = new Item_Snapshot_Field_Update__c();
					isfu.name = fu.name.left(80);
					isfu.Description__c = fu.description;
					isfu.Field__c = fu.field;
					isfu.Formula__c = fu.formula;
					isfu.Full_Name__c = fu.name;
					isfu.LiteralValue__c = fu.literalValue;
					isfu.LookupValue__c = fu.lookupValue;
					isfu.LookupValueType__c = fu.lookupValueType;
					isfu.Created_By__c = fileProperty.createdById;
					isfu.Created_Date__c = fileProperty.createdDate;
					isfu.Last_Modified_By__c = fileProperty.lastModifiedById;
					isfu.Last_Modified_Date__c = fileProperty.lastModifiedDate;
					if(fu.notifyAssignee != null){
						isfu.NotifyAssignee__c = fu.notifyAssignee;
					}
					isfu.Operation__c = fu.operation;
					if(fu.protected_x != null){
						isfu.Protected_x__c = fu.protected_x;
					}
					if(fu.reevaluateOnChange != null){
						isfu.Reevaluate_On_Change__c = fu.reevaluateOnChange;
					}
					isfu.TargetObject__c = fu.targetObject;
				isfuList.add(isfu);
			}
		}
		Try{
			insert isfuList;
			list<Field_Update_Object_Junction__c> fuojList = new list<Field_Update_Object_Junction__c>();
			for(Item_Snapshot_Field_Update__c isfu : isfuList){
				for(Item_Snapshot__c itsn : itsnList){
					if(itsn.Workflow_Action_Name_Type__c != null && isfu.Full_Name__c != null && itsn.Workflow_Action_Name_Type__c.contains(isfu.Full_Name__c.replaceAll(' ','_'))){
						Field_Update_Object_Junction__c fuoj = new Field_Update_Object_Junction__c();
							fuoj.Item_Snapshot__c = itsn.id;
							fuoj.Item_Snapshot_Field_Update__c = isfu.id;
						fuojList.add(fuoj);
					}
				}
			}
			insert fuojList;
			ID workflowTaskJob = System.enqueueJob(new CollectWorkflowTaskQueueable(ssnId,itsnList));
		}
		Catch(exception e){
			system.debug(logginglevel.info, '*****'+e);
		}
	}
	
}