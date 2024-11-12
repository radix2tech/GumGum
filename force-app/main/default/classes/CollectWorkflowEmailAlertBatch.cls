public with sharing class CollectWorkflowEmailAlertBatch implements Database.Batchable<string>, Database.Stateful, Database.AllowsCallouts {

	list<Item_Snapshot__c> itsnList {get;set;}
	String ssnId {get;set;}
	list<String> fullnameList {get; set;}
	map<String, MetadataService.FileProperties> filePropertiesMap {get; set;}
	list<MetadataService.IReadResult> readResult = new list<MetadataService.IReadResult>();
	MetadataService.MetadataPort service {get; set;}
	
	public CollectWorkflowEmailAlertBatch(string sessionId, list<Item_Snapshot__c> itemSnapList) {
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
		List<MetadataService.ListMetadataQuery> queries = new List<MetadataService.ListMetadataQuery>();
		MetadataService.ListMetadataQuery currentQuery = new MetadataService.ListMetadataQuery();
		currentQuery.type_x = 'WorkflowAlert';
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
		MetadataService.IReadResult result = service.readMetadata('WorkflowAlert', fullnameList);
		readResult.add(result);
	}

	public class wrapper{
		public Item_Snapshot_Email_Alert__c isea {get;set;}
		public List<String> ccAddresses {get;set;}
		public list<MetadataService.WorkflowEmailRecipient> recipients {get;set;}
	}

	public void finish(Database.BatchableContext BC) {
		list<Item_Snapshot_Email_Alert__c> iseaList = new list<Item_Snapshot_Email_Alert__c>();
		list<wrapper> wrapList = new list<wrapper>();
		for (MetadataService.IReadResult result : readResult) {
			for (MetadataService.Metadata alert : result.getRecords()) {
				wrapper w = new wrapper();
				MetadataService.WorkflowAlert alrt = (MetadataService.WorkflowAlert) alert;
				MetadataService.FileProperties fileProperty = filePropertiesMap.get(alrt.fullName);
				Item_Snapshot_Email_Alert__c isea = new Item_Snapshot_Email_Alert__c();
					w.isea = isea;
					isea.name = alrt.fullName.left(80);
					isea.Description__c = alrt.description;
					isea.Full_Name__c = alrt.fullName;
					isea.Created_By__c = fileProperty.createdById;
					isea.Created_Date__c = fileProperty.createdDate;
					isea.Last_Modified_By__c = fileProperty.lastModifiedById;
					isea.Last_Modified_Date__c = fileProperty.lastModifiedDate;
					if(alrt.protected_x != null){
						isea.protected_x__c = alrt.protected_x;
					}	
					if(alrt.senderAddress != null){
						isea.senderAddress__c = alrt.senderAddress;
					}
					isea.senderType__c = alrt.senderType;
					isea.template__c = alrt.template;
					if(alrt.ccEmails != null){
						//emailAlertToCcadresses.put(isea,alrt.ccEmails);
						w.ccAddresses = alrt.ccEmails;
					}
					if(alrt.recipients != null){
						//emailAlertToRecipients.put(isea,alrt.recipients);
						w.recipients = alrt.recipients;
					}
				iseaList.add(isea);
				wrapList.add(w);
			}
		}
		Try{
			system.debug(logginglevel.error, '*****wrapList='+wrapList);
			insert iseaList;
			system.debug(logginglevel.error, '*****wrapList='+wrapList);
			list<Email_Alert_Workflow_Junction__c> twjList = new list<Email_Alert_Workflow_Junction__c>();
			for(Item_Snapshot_Email_Alert__c isea : iseaList){
				for(Item_Snapshot__c itsn : itsnList){
					if(itsn.Workflow_Action_Name_Type__c != null && isea.Full_Name__c != null && itsn.Workflow_Action_Name_Type__c.contains(isea.Full_Name__c.replaceAll(' ','_'))){
						Email_Alert_Workflow_Junction__c eawj = new Email_Alert_Workflow_Junction__c();
							eawj.Item_Snapshot__c = itsn.id;
							eawj.Item_Snapshot_Email_Alert__c = isea.id;
						twjList.add(eawj);
					}
				}
			}
			insert twjList;
			list<Email_Alert_Recipient__c> earList = new list<Email_Alert_Recipient__c>();
			for(wrapper w : wrapList){
				if(w.ccAddresses != null){
					for(String s : w.ccAddresses){
						Email_Alert_Recipient__c ear = new Email_Alert_Recipient__c();
							ear.Item_Snapshot_Email_Alert__c = w.isea.id;
							ear.Name = s;
							ear.type_x__c = 'ccAddress';
						earList.add(ear);
					}
				}
				if(w.recipients != null){
					for(MetadataService.WorkflowEmailRecipient mwer : w.recipients){
						Email_Alert_Recipient__c ear = new Email_Alert_Recipient__c();
							ear.Item_Snapshot_Email_Alert__c = w.isea.id;
							ear.Name = mwer.recipient;
							ear.Recipient_Field__c = mwer.field;
							ear.type_x__c = mwer.type_x;
						earList.add(ear);
					}
				}
			}
			//for(Item_Snapshot_Email_Alert__c isea : emailAlertToCcadresses.keyset()){
			//	if(emailAlertToCcadresses.get(isea) == null || emailAlertToCcadresses.get(isea).size() == null){
			//		continue;
			//	}
			//	for(String s : emailAlertToCcadresses.get(isea)){
			//		Email_Alert_Recipient__c ear = new Email_Alert_Recipient__c();
			//			ear.Item_Snapshot_Email_Alert__c = isea.id;
			//			ear.Name = s;
			//			ear.type_x__c = 'ccAddress';
			//		earList.add(ear);
			//	}					
			//}
			//for(Item_Snapshot_Email_Alert__c isea : emailAlertToRecipients.keyset()){
			//	if(emailAlertToRecipients.get(isea) == null || emailAlertToRecipients.get(isea).size() == null){
			//		continue;
			//	}
			//	for(MetadataService.WorkflowEmailRecipient mwer : emailAlertToRecipients.get(isea)){
			//		Email_Alert_Recipient__c ear = new Email_Alert_Recipient__c();
			//			ear.Item_Snapshot_Email_Alert__c = isea.id;
			//			ear.Name = mwer.recipient;
			//			ear.Recipient_Field__c = mwer.field;
			//			ear.type_x__c = mwer.type_x;
			//		earList.add(ear);
			//	}
			//}
			system.debug(logginglevel.error, '*****earList='+earList);
			insert earList;
		}
		Catch(exception e){
			system.debug(logginglevel.info, '*****'+e);
		}
	}


}