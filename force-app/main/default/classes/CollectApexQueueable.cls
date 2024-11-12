public with sharing class CollectApexQueueable implements Queueable, Database.AllowsCallouts {
	
	id currentSnapShotId {get; set;}
	string sessionId {get; set;}
	Item_Snapshot__c[] snapshotsNeedingAttachments {get;set;}
	Item_Snapshot__c[] snapshotsNotNeedingAttachments {get;set;}

	public CollectApexQueueable(id snapShotId, string sesnId) {
		currentSnapShotId = snapShotId;
		sessionId = sesnId;
	}

	public void execute(QueueableContext context) {
		list<ApexClass> acList = CollectApexClass();
		Item_Snapshot__c[] snapshotList = ConvertClassToSnapshot(acList);
		CheckBodyLengthAndSortLists(snapshotList);
		Try{
			InsertAllSnapshots();
		}
		Catch(exception e){
			system.debug(logginglevel.info, '*****'+e);
		}
	}

	class SnapshotWrapper{
		public Item_Snapshot__c itsn {get;set;}
		public Attachment att {get;set;}
	}

	void InsertAllSnapshots(){
		insert snapshotsNotNeedingAttachments;
		list<SnapshotWrapper> snapShotWrapList = new list<SnapshotWrapper>();
		for(Item_Snapshot__c isna : snapshotsNeedingAttachments){
			SnapshotWrapper ssw = new SnapshotWrapper();
				Attachment atch = new Attachment();
				atch.Name = 'body.txt';
				atch.Body = blob.valueof(isna.Body__c);
				atch.ContentType = '.txt';
				isna.Body__c = 'See Attachment';
				ssw.itsn = isna;
				ssw.att = atch;
			snapShotWrapList.add(ssw);
		}
		insert snapshotsNeedingAttachments;
		list<Attachment> attList = new list<Attachment>();
		for(SnapshotWrapper sw : snapShotWrapList){
			sw.att.ParentId = sw.itsn.id;
			attList.add(sw.att);
		}
		insert attList;
	}

	void CheckBodyLengthAndSortLists(Item_Snapshot__c[] allSnapshots){
		snapshotsNeedingAttachments = new Item_Snapshot__c[]{};
		snapshotsNotNeedingAttachments = new Item_Snapshot__c[]{};
		for(Item_Snapshot__c itsn : allSnapshots){
			if(itsn.Body__c != null && itsn.Body__c.length() > 130000){
				snapshotsNeedingAttachments.add(itsn);
			} else {
				snapshotsNotNeedingAttachments.add(itsn);
			}
		}
	}

	ApexClass[] CollectApexClass(){
		Map<String, Schema.SObjectType> SobjectSchemaMap = Schema.getGlobalDescribe();
		Schema.DescribeSObjectResult SobjectResult = SobjectSchemaMap.get('ApexClass').getDescribe();
		Map<String, Schema.SObjectField> SobjtField = SobjectResult.fields.getMap();
		string qry = '';
		for (Schema.SObjectField s : SobjtField.values()) {
		    qry += s + ',';
		}
		qry = qry.removeend(',');
		qry = 'select '+qry+' from '+ 'ApexClass where NamespacePrefix = null';
		return database.query(qry);		
	}

	Item_Snapshot__c[] ConvertClassToSnapshot(list<ApexClass> acList){
		list<Item_Snapshot__c> isList = new list<Item_Snapshot__c>();
		for(ApexClass ac : acList){
			Item_Snapshot__c itsn = new Item_Snapshot__c();
				itsn.name = ac.Name.left(80);
				itsn.Body__c = ac.Body;
				itsn.Created_By__c = ac.CreatedById;
				itsn.Created_Date__c = ac.CreatedDate;
				itsn.Item_Full_Name__c = ac.Name;
				itsn.Last_Modified_By__c = ac.LastModifiedById;
				itsn.Last_Modified_Date__c = ac.LastModifiedDate;
				itsn.Object_Id__c = ac.Id;
				itsn.System_Snapshot__c = currentSnapShotId;
				itsn.Type__c = 'ApexClass';
			isList.add(itsn);
		}
		return isList;
	}

}