public with sharing class CollectFlowBatch implements Database.Batchable<string>, Database.Stateful, Database.AllowsCallouts {

	id currentSnapShotId {get; set;}
	string sessionId {get; set;}
	list<MetadataServiceExtension.FlowFileExtensionWrapper> flowList {get;set;}
	Integer numberInList {get;set;}
	Integer versionNumber {get;set;}
	MetadataService.MetadataPort service {get;set;}
	list<String> fullnameList {get;set;}
	MetadataService.IReadResult result {get;set;}


	public CollectFlowBatch(id snapShotId1, string sesnId1, list<MetadataServiceExtension.FlowFileExtensionWrapper> flowList1, Integer numberInList1, Integer versionNumber1) {
		currentSnapShotId = snapShotId1;
		sessionId = sesnId1;
		flowList = flowList1;
		numberInList = numberInList1;
		versionNumber = versionNumber1;
		service = new MetadataService.MetadataPort();
		if (service.endpoint_x.startsWithIgnoreCase('http:')) {
			service.endpoint_x = service.endpoint_x.removeStartIgnoreCase('http');
			service.endpoint_x = 'https' + service.endpoint_x;
		}
		service.SessionHeader = new MetadataService.SessionHeader_element();
		service.SessionHeader.sessionId = sessionId;
		fullnameList = new list<String>();
		MetadataService.FileProperties fileProperty = flowList.get(numberInList).fileProperty;
		fullnameList.add(flowList.get(numberInList).fullName + '-' + versionNumber);
	}

	public Iterable<String> start(Database.BatchableContext BC) {
		return fullnameList;
	}

	public void execute(Database.BatchableContext BC, List<String> fullnameList) {
		result = service.readMetadata('Flow', fullnameList);
	}

	public void finish(Database.BatchableContext BC) {
		for (MetadataService.Metadata flow : result.getRecords()) {
			MetadataService.Flow workingFlow = (MetadataService.Flow) flow;
			if(workingFlow.label == null){
				CheckNextVersionNumber();
				return;
			} else {
				CreateItemSnapshot(workingFlow, flowList.get(numberInList).fileProperty);
				CheckNextItemInList();
			}
		}
	}

	private void CheckNextVersionNumber(){
		versionNumber ++;
		//if(versionNumber > 50){
		//	return;
		//}
		ID flowJob = System.enqueueJob(new CollectFlowQueueable(currentSnapShotId, sessionId, flowList, numberInList, versionNumber));
	}

	private void CheckNextItemInList(){
		Integer nextNumberInList = numberInList + 1;
		if(flowList.size() <= nextNumberInList){
			return;
		}
		if(flowList.get(numberInList).fullName == flowList.get(nextNumberInList).fullName){
			versionNumber ++;
		} else {
			versionNumber = 1;
		}
		numberInList ++;
		ID flowJob = System.enqueueJob(new CollectFlowQueueable(currentSnapShotId, sessionId, flowList, numberInList, versionNumber));
	}

	private void CreateItemSnapshot(MetadataService.Flow flow, MetadataService.FileProperties fileProperty){
		Item_Snapshot__c itsn = new Item_Snapshot__c();
		if(flow.processType == 'Workflow'){
			itsn.Type__c = 'Process Builder';
		} else {
			itsn.Type__c = 'Flow';
		}
		itsn.Name = flow.label.left(80);
		itsn.Created_By__c = fileProperty.createdById;
		itsn.Created_Date__c = fileProperty.createdDate;
		itsn.Description__c = flow.description;
		itsn.Item_Full_Name__c = flow.label;
		itsn.Last_Modified_By__c = fileProperty.lastModifiedById;
		itsn.Last_Modified_Date__c = fileProperty.lastModifiedDate;
		itsn.System_Snapshot__c = currentSnapShotId;
		itsn.API_Name__c = fileProperty.fullName;
		itsn.Version__c = versionNumber;
		insert itsn;
	}



}