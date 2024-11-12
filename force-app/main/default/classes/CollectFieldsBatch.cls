public class CollectFieldsBatch implements Database.Batchable<Item_Snapshot__c> {
	
	id currentSnapShotId {get; set;}
	string sessionId {get; set;}
	Item_Snapshot__c[] objectSnapshotList {get;set;}
	
	public CollectFieldsBatch(id snapShotId, string sesnId, Item_Snapshot__c[] snapshotList) {
		currentSnapShotId = snapShotId;
		sessionId = sesnId;
		objectSnapshotList = snapshotList;
	}
	
	public Iterable<Item_Snapshot__c> start(Database.BatchableContext BC) {
		return objectSnapshotList;
	}

   	public void execute(Database.BatchableContext BC, List<Item_Snapshot__c> scope) {
		Map<String, Schema.SObjectType> SobjectSchemaMap = Schema.getGlobalDescribe();
		list<Item_Snapshot_Field__c> allItemSnapshotFields = new list<Item_Snapshot_Field__c>();
		for (Item_Snapshot__c itsn : scope) {
			Schema.DescribeSObjectResult SobjectResult = SobjectSchemaMap.get(itsn.Item_Full_Name__c).getDescribe();
			Map<String, Schema.SObjectField> SobjtFieldMap = SobjectResult.fields.getMap();
			for (Schema.SObjectField SobjtField : SobjtFieldMap.values()) {
				allItemSnapshotFields.add(ConvertFieldToItemSnapshotField(SobjtField, itsn.Id));
			}
		}
		Try{
			insert allItemSnapshotFields;
		}
		Catch(exception e){
			system.debug(logginglevel.info, '*****'+e);
		}
	}

	Item_Snapshot_Field__c ConvertFieldToItemSnapshotField(Schema.SObjectField SobjtField, Id i) {
		Item_Snapshot_Field__c isf = new Item_Snapshot_Field__c();
			isf.name = SobjtField.getDescribe().getLabel().left(80);
			isf.Field_Api_Name__c = SobjtField.getDescribe().getLocalName();
			isf.Field_Label__c = SobjtField.getDescribe().getLabel();
			isf.Item_Snapshot__c = i;
			isf.Type__c = String.valueof(SobjtField.getDescribe().getType());
			if (SobjtField.getDescribe().getScale() > 0) {
				isf.Decimal_Places__c = SobjtField.getDescribe().getScale();
			}
			if (SobjtField.getDescribe().getDefaultValue() != null) {
				isf.Default_Value__c = String.valueof(SobjtField.getDescribe().getDefaultValue());
			} else if (SobjtField.getDescribe().getDefaultValueFormula() != null) {
				isf.Default_Value__c = SobjtField.getDescribe().getDefaultValueFormula();
			}
			if (SobjtField.getDescribe().getFilteredLookupInfo() != null) {
				if (SobjtField.getDescribe().getFilteredLookupInfo().isOptionalFilter() == true) {
					isf.Filtered__c = 'Filter Optional';
				} else {
					isf.Filtered__c = 'Filter Required';
				}
			} else {
				isf.Filtered__c = 'No Filter';
			}
			isf.Formula__c = SobjtField.getDescribe().getCalculatedFormula();
			if (SobjtField.getDescribe().getSoapType() == Schema.SoapType.String) {
				isf.Length__c = SobjtField.getDescribe().getLength();
			} else if (SobjtField.getDescribe().getSoapType() == Schema.SoapType.Double || SobjtField.getDescribe().getSoapType() == Schema.SoapType.Integer) {
				isf.Length__c = SobjtField.getDescribe().getPrecision();
			}
		return isf;
	}
	
	public void finish(Database.BatchableContext BC) {}
	
}