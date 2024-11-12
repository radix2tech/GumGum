public with sharing class SystemSnapshotPDF {

	public list<ObjectsAndFields> objectFieldList {get; set;}
	public list<Workflow> workflowList {get; set;}
	public System_Snapshot__c sysSnap {get; set;}
	public Item_Snapshot__c[] apexClassList {get;set;}
	public Item_Snapshot__c[] triggerList {get;set;}
	public Item_Snapshot__c[] flowList {get;set;}
	public Item_Snapshot__c[] pbList {get;set;}


	/**
	 * this class is a wrapper class for the objects and fields
	 */
	public class ObjectsAndFields {
		public Item_Snapshot__c objectSnapshots {get; set;}
		public list<Item_Snapshot_Field__c> fieldList {get; set;}
	}

	/**
	 * this class is a wrapper class for the workflows and their sub-items
	 */
	public class Workflow {
		public Item_Snapshot__c snapshot {get; set;}
		public list<Item_Snapshot_Task__c> tasks {get; set;}
		public list<Item_Snapshot_Field_Update__c> fieldUpdates {get; set;}
		public list<Item_Snapshot_Email_Alert__c> emailAlerts {get; set;}
	}



	public SystemSnapshotPDF(apexpages.standardcontroller controller) {
		sysSnap = QuerySystemSnapshot();
		Item_Snapshot__c[] sobjectList = QueryItemSnapshotsThatAreObjects('Sobject');
		Item_Snapshot_Field__c[] fieldList = QueryItemSnapshotFields(sobjectList);
		objectFieldList = BuildObjectAndFieldMap(sobjectList, fieldList);
		Item_Snapshot__c[] workflowItemSnapshots = QueryItemSnapshotsThatAreObjects('Workflow Rule');
		map<Id, Workflow> workflowMap = QueryEmailAlerts(workflowItemSnapshots);
		workflowMap = AddFieldUpdateToWorkflowMap(workflowMap);
		workflowMap = AddTasksToWorkflowMap(workflowMap);
		ConvertWorkflowMapToWorkflowList(workflowMap);
		apexClassList = QueryItemSnapshotsThatAreObjects('ApexClass');
		triggerList = QueryItemSnapshotsThatAreObjects('ApexTrigger');
		flowList = OrderFlowlist(QueryItemSnapshotsThatAreObjects('Flow'));
		pbList = OrderFlowlist(QueryItemSnapshotsThatAreObjects('Process Builder'));

	}

	Item_Snapshot__c[] OrderFlowlist(Item_Snapshot__c[] flows){
		map<String,Decimal> nameToVersion = new map<String,Decimal>();
		for(Item_Snapshot__c itsn : flows){
			String itsnName;
			if(itsn.API_Name__c.right(1).isNumeric()){
				itsnName = itsn.API_Name__c.substringBeforeLast('-');
			} else {
				itsnName = itsn.API_Name__c;
			}
			if(nameToVersion.containsKey(itsnName)){
				if(itsn.Version__c > nameToVersion.get(itsnName)){
					nameToVersion.put(itsnName,itsn.Version__c);
				}
			}
		}
		list<Item_Snapshot__c> returnList = new list<Item_Snapshot__c>();
		for(item_Snapshot__c itsn : flows){
			String itsnName;
			if(itsn.API_Name__c.right(1).isNumeric()){
				itsnName = itsn.API_Name__c.substringBeforeLast('-');
			} else {
				itsnName = itsn.API_Name__c;
			}
			if(itsn.Version__c == nameToVersion.get(itsnName)){
				returnList.add(itsn);
			}
		}
		return returnList;
	}








	/**
	 * Adds workflow tasks to the workflow map
	 * @param  workflowMap map of Item_Snapshot__c id to workflow
	 * @return             map of Item_Snapshot__c id to workflow
	 */
	map<Id, Workflow> AddTasksToWorkflowMap(map<Id, Workflow> workflowMap) {
		Task_Workflow_Junction__c[] twjList = QueryTaskWorkflowJunctions(workflowMap.keyset());
		Item_Snapshot_Task__c[] istList = QueryTasks(twjList);
		map<Id,Item_Snapshot_Task__c> taskMap = new map<Id,Item_Snapshot_Task__c>();
		taskMap.putall(istList);
		for(Task_Workflow_Junction__c twj : twjList){
			workflowMap.get(twj.Item_Snapshot__c).tasks.add(taskMap.get(twj.Item_Snapshot_Task__c));
		}
		return workflowMap;
	}

	/**
	 * gets all of the Item_Snapshot_Task__c
	 * @param  twjList Task_Workflow_Junction__c list
	 * @return         Item_Snapshot_Task__c list
	 */
	Item_Snapshot_Task__c[] QueryTasks(list<Task_Workflow_Junction__c> twjList){
		set<id> snapshotIds = new set<id>();
		for(Task_Workflow_Junction__c twj : twjList){
			snapshotIds.add(twj.Item_Snapshot_Task__c);
		}
		Map<String, Schema.SObjectField> SobjtField = Schema.getGlobalDescribe().get('Item_Snapshot_Task__c').getDescribe().fields.getMap();
		string qry = '';
		for (Schema.SObjectField s : SobjtField.values()) {
		    qry += s + ',';
		}
		qry = qry.removeend(',');
		qry = 'select '+qry+' from '+ 'Item_Snapshot_Task__c' + ' where id in :snapshotIds';
		return database.Query(qry);

	}

	/**
	 * gets all of the Task_Workflow_Junction__c
	 * @param  itemSnapshotIds set of the Item_Snapshot__c ids
	 * @return                 Task_Workflow_Junction__c list
	 */
	list<Task_Workflow_Junction__c> QueryTaskWorkflowJunctions(set<Id> itemSnapshotIds){
		Map<String, Schema.SObjectField> SobjtField = Schema.getGlobalDescribe().get('Task_Workflow_Junction__c').getDescribe().fields.getMap();
		string qry = '';
		for (Schema.SObjectField s : SobjtField.values()) {
		    qry += s + ',';
		}
		qry = qry.removeend(',');
		qry = 'select '+qry+' from '+ 'Task_Workflow_Junction__c' + ' where Item_Snapshot__c in :itemSnapshotIds';
		return database.Query(qry);
	}


	/**
	 * Main method to add the field updates to the workflow map
	 * @param workflowMap map of Item_Snapshot__c id to Workflow
	 */
	map<Id, Workflow> AddFieldUpdateToWorkflowMap(map<Id, Workflow> workflowMap) {
		Field_Update_Object_Junction__c[] fieldUpdateJunctionList = QueryFieldUpdatesJunctions(workflowMap.keyset());
		Item_Snapshot_Field_Update__c[] fieldUpdateList = QueryFieldUpdates(fieldUpdateJunctionList);
		map<Id, Item_Snapshot_Field_Update__c> fieldUpdateMap = new map<id, Item_Snapshot_Field_Update__c>();
		fieldUpdateMap.putall(fieldUpdateList);
		for (Field_Update_Object_Junction__c fuoj : fieldUpdateJunctionList) {
			workflowMap.get(fuoj.Item_Snapshot__c).fieldUpdates.add(fieldUpdateMap.get(fuoj.Item_Snapshot_Field_Update__c));
		}
		return workflowMap;
	}

	/**
	 * this gets the list of Item_Snapshot_Field_Update__c objects from the Field_Update_Object_Junction__c junctions
	 * @param  fuojList list of Field_Update_Object_Junction__c
	 * @return          list of Item_Snapshot_Field_Update__c
	 */
	Item_Snapshot_Field_Update__c[] QueryFieldUpdates(list<Field_Update_Object_Junction__c> fuojList) {
		set<id> snapshotIds = new set<id>();
		for (Field_Update_Object_Junction__c fuoj : fuojList) {
			snapshotIds.add(fuoj.Item_Snapshot_Field_Update__c);
		}
		Map<String, Schema.SObjectField> SobjtField = Schema.getGlobalDescribe().get('Item_Snapshot_Field_Update__c').getDescribe().fields.getMap();
		string qry = '';
		for (Schema.SObjectField s : SobjtField.values()) {
			qry += s + ',';
		}
		qry = qry.removeend(',');
		qry = 'select ' + qry + ' from ' + 'Item_Snapshot_Field_Update__c' + ' where id in :snapshotIds';
		return database.Query(qry);
	}

	/**
	 * takes the Item_Snapshot__c ids and gets the Field_Update_Object_Junction__c that match
	 * @param  itemSnapshotIds set of Item_Snapshot__c ids
	 * @return 				   list of Field_Update_Object_Junction__c
	 */
	list<Field_Update_Object_Junction__c> QueryFieldUpdatesJunctions(set<Id> itemSnapshotIds) {
		Map<String, Schema.SObjectField> SobjtField = Schema.getGlobalDescribe().get('Field_Update_Object_Junction__c').getDescribe().fields.getMap();
		string qry = '';
		for (Schema.SObjectField s : SobjtField.values()) {
			qry += s + ',';
		}
		qry = qry.removeend(',');
		qry = 'select ' + qry + ' from ' + 'Field_Update_Object_Junction__c' + ' where Item_Snapshot__c in :itemSnapshotIds';
		return database.Query(qry);
	}

	/**
	 * Takes the map of Id to workflow and pulls just the workflow out and adds it to the list
	 * @param workflowMap map of item_Snapshot__c id to workflow
	 */
	void ConvertWorkflowMapToWorkflowList(map<Id, Workflow> workflowMap) {
		workflowList = new list<Workflow>();
		for (Workflow w : workflowMap.values()) {
			workflowList.add(w);
		}
	}

	/**
	 * this gets the list of Item_Snapshot_Email_Alert__c objects from the Email_Alert_Workflow_Junction__c junctions
	 * @param  eawjList list of Email_Alert_Workflow_Junction__c
	 * @return          list of Item_Snapshot_Email_Alert__c
	 */
	Item_Snapshot_Email_Alert__c[] QueryEmailAlertList(list<Email_Alert_Workflow_Junction__c> eawjList) {
		set<id> snapshotIds = new set<id>();
		for (Email_Alert_Workflow_Junction__c eawj : eawjList) {
			snapshotIds.add(eawj.Item_Snapshot_Email_Alert__c);
		}
		Map<String, Schema.SObjectField> SobjtField = Schema.getGlobalDescribe().get('Item_Snapshot_Email_Alert__c').getDescribe().fields.getMap();
		string qry = '';
		for (Schema.SObjectField s : SobjtField.values()) {
			qry += s + ',';
		}
		qry = qry.removeend(',');
		qry = 'select ' + qry + ' from ' + 'Item_Snapshot_Email_Alert__c' + ' where id in :snapshotIds';
		return database.Query(qry);
	}

	/**
	 * this method gets a map of Item_Snapshot__c Id to workflow  it queires the junction object and then the email alerts and pairs it all up
	 * @param  itemSnaps list of Item_Snapshot__c
	 * @return map with key of Item_Snapshot__c Id to workflow
	 */
	map<Id, Workflow> QueryEmailAlerts(list<Item_Snapshot__c> itemSnaps) {
		map<Id, Item_Snapshot__c> snapshotMap = new map<Id, Item_Snapshot__c>();
		snapshotMap.putall(itemSnaps);
		Email_Alert_Workflow_Junction__c[] eawjList = QueryEmailAlertJunctions(snapshotmap.keyset());
		Item_Snapshot_Email_Alert__c[] emailAlertList = QueryEmailAlertList(eawjList);
		map<Id, Item_Snapshot_Email_Alert__c> emailAlertMap = new map<Id, Item_Snapshot_Email_Alert__c>();
		emailAlertMap.putall(emailAlertList);
		map<Id, Workflow> returnMap = new map<Id, Workflow>();
		for (Email_Alert_Workflow_Junction__c eawj : eawjList) {
			if (returnMap.containsKey(eawj.Item_Snapshot__c)) {
				returnMap.get(eawj.Item_Snapshot__c).emailAlerts.add(emailAlertMap.get(eawj.Item_Snapshot_Email_Alert__c));
			} else {
				Workflow w = new Workflow();
				w.emailAlerts = new list<Item_Snapshot_Email_Alert__c> {emailAlertMap.get(eawj.Item_Snapshot_Email_Alert__c)};
				w.fieldUpdates = new list<Item_Snapshot_Field_Update__c>();
				w.tasks = new list<Item_Snapshot_Task__c>();
				w.snapshot = snapshotMap.get(eawj.Item_Snapshot__c);
				returnMap.put(eawj.Item_Snapshot__c, w);
			}
		}
		//this will add the workflow for item snapshots that don't have an email alert
		for (Item_Snapshot__c itsn : itemSnaps) {
			if (returnMap.containsKey(itsn.id)) {
				continue;
			} else {
				Workflow w = new Workflow();
				w.emailAlerts = new list<Item_Snapshot_Email_Alert__c>();
				w.fieldUpdates = new list<Item_Snapshot_Field_Update__c>();
				w.tasks = new list<Item_Snapshot_Task__c>();
				w.snapshot = itsn;
				returnMap.put(itsn.id, w);
			}
		}
		return returnMap;
	}

	/**
	 * queries the Email_Alert_Workflow_Junction__c items based on the Item Snapshot ids
	 * @param  itemSnapshotIds set of Item_Snapshot__c ids
	 * @return                 list of Email_Alert_Workflow_Junction__c
	 */
	list<Email_Alert_Workflow_Junction__c> QueryEmailAlertJunctions(set<Id> itemSnapshotIds) {
		return [select Item_Snapshot__c, Item_Snapshot_Email_Alert__c
		        from Email_Alert_Workflow_Junction__c
		        where Item_Snapshot__c in :itemSnapshotIds];
	}


	/**
	 * this will get the system snapshot and all of its fields
	 * @return System_Snapshot__c
	 */
	System_Snapshot__c QuerySystemSnapshot() {
		if (ApexPages.CurrentPage().getParameters().get('id') == null) {
			return null;
		}
		Map<String, Schema.SObjectField> SobjtField = Schema.getGlobalDescribe().get('System_Snapshot__c').getDescribe().fields.getMap();
		string qry = '';
		for (Schema.SObjectField s : SobjtField.values()) {
			qry += s + ',';
		}
		qry = qry.removeend(',');
		Id i = ApexPages.CurrentPage().getParameters().get('id');
		qry = 'select ' + qry + ' from ' + 'System_Snapshot__c' + ' where id = :i';
		return database.query(qry);
	}

	/**
	 * this will return all of the Item Snapshots that have the type passed in
	 * @return list of Item_Snapshot__c
	 */
	list<Item_Snapshot__c> QueryItemSnapshotsThatAreObjects(String type) {
		Map<String, Schema.SObjectField> SobjtField = Schema.getGlobalDescribe().get('Item_Snapshot__c').getDescribe().fields.getMap();
		string qry = '';
		for (Schema.SObjectField s : SobjtField.values()) {
			qry += s + ',';
		}
		qry = qry.removeend(',');
		Id i = sysSnap.id;
		qry = 'select ' + qry + ' from ' + 'Item_Snapshot__c' + ' where Type__c = :type AND System_Snapshot__c = :i';
		return database.query(qry);
	}

	/**
	 * this will query and return all item snapshot fields
	 * @param objectList list of Item_Snapshot__c
	 * @return list of Item_Snapshot_Field__c
	 */
	list<Item_Snapshot_Field__c> QueryItemSnapshotFields(list<Item_Snapshot__c> objectList) {
		set<Id> objectIds = new set<Id>();
		for (Item_Snapshot__c obj : objectList) {
			objectIds.add(obj.id);
		}
		Map<String, Schema.SObjectField> SobjtField = Schema.getGlobalDescribe().get('Item_Snapshot_Field__c').getDescribe().fields.getMap();
		string qry = '';
		for (Schema.SObjectField s : SobjtField.values()) {
			qry += s + ',';
		}
		qry = qry.removeend(',');
		qry = 'select ' + qry + ' from ' + 'Item_Snapshot_Field__c where Item_Snapshot__c in :objectIds AND Is_Custom_Field__c = true';
		return database.query(qry);
	}

	/**
	 * This puts the item snapshots into a map so I can access them by the id
	 * then puts all of the items snapshots into a map of item snapshot id to a new ObjectsAndFields
	 * then adds the fields to the map of item id to objecandfields
	 * then finally returns just the ObjectsAndFields
	 * @param  objectList [a list of all of the Object Item_Snapshot__c]
	 * @param  fields     [a List of all of the Item_Snapshot_Field__c]
	 * @return            [a list of ObjectsAndFields]
	 */
	list<ObjectsAndFields> BuildObjectAndFieldMap(list<Item_Snapshot__c> objectList, List<Item_Snapshot_Field__c> fields) {
		map<Id, Item_Snapshot__c> itsnMap = new map<Id, Item_Snapshot__c>();
		itsnMap.putall(objectList);
		map<Id, ObjectsAndFields> tempReturnMap = new map<Id, ObjectsAndFields>();
		for (Id i : itsnMap.keyset()) {
			ObjectsAndFields oaf = new ObjectsAndFields();
			oaf.objectSnapshots = itsnMap.get(i);
			oaf.fieldList = new list<Item_Snapshot_Field__c>();
			tempReturnMap.put(i, oaf);
		}
		for (Item_Snapshot_Field__c field : fields) {
			tempReturnMap.get(field.Item_Snapshot__c).fieldList.add(field);
		}
		list<ObjectsAndFields> returnList = new list<ObjectsAndFields>();
		for (ObjectsAndFields oaf : tempReturnMap.values()) {
			returnList.add(oaf);
		}
		return returnList;
	}

}