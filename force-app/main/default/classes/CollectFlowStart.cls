public with sharing class CollectFlowStart implements Queueable, Database.AllowsCallouts {

	Id currentSnapShotId {get;set;}
	string sessionId {get; set;}

	public CollectFlowStart(id currentSnapShotId1, string sessionId1) {
		currentSnapShotId = currentSnapShotId1;
		system.debug(logginglevel.error, '*****sessionId1='+sessionId1);
		sessionId = sessionId1;
	}

	public void execute(QueueableContext context) {
		list<MetadataService.FileProperties> fileProperties = CollectFileProperties();
		fileProperties.sort();
		if(FileProperties.size() < 1){
			return;
		}
		map<String, Integer> fullnameToNumberOfVersions = GetFullNameAndNumberOfVersions(fileProperties);
		map<String, list<MetadataService.FileProperties>> fullNameToFileProperties = GetFullNameAndFileProperties(fileProperties);
		list<MetadataServiceExtension.FlowFileExtensionWrapper> flowExtensionList = BuildWrapper(fullnameToNumberOfVersions,fullNameToFileProperties);
		CollectFlowBatch batch = new CollectFlowBatch(currentSnapShotId, sessionId, flowExtensionList, 0, 1);
		database.executeBatch(batch,1);



		//ID flowJob = System.enqueueJob(new CollectFlowQueueable(currentSnapShotId, sessionId, flowExtensionList, 0, 1));
	}

	private list<MetadataServiceExtension.FlowFileExtensionWrapper> BuildWrapper(map<String, Integer> fullnameToNumberOfVersions, map<String, list<MetadataService.FileProperties>> fullNameToFileProperties) {
		list<MetadataServiceExtension.FlowFileExtensionWrapper> returnList = new list<MetadataServiceExtension.FlowFileExtensionWrapper>();
		for(String s : fullnameToNumberOfVersions.keyset()){

			map<Integer, MetadataService.FileProperties> orderedFilePropertiesMap = SortFilePropertiesOrder(FullNameToFileProperties.get(s));
			Integer ver = 0;
				for(integer i : orderedFilePropertiesMap.keyset()){
					MetadataServiceExtension.FlowFileExtensionWrapper ffew = new MetadataServiceExtension.FlowFileExtensionWrapper();
					ffew.fileProperty = orderedFilePropertiesMap.get(i);
					ffew.fullName = s;
					ffew.flowId = orderedFilePropertiesMap.get(i).id;
					ffew.totalNumberOfVersions = orderedFilePropertiesMap.size();
					ver ++;
					ffew.versionNumber = ver;
					returnList.add(ffew);
				}
		}
		return returnList;
	}

	private map<Integer, MetadataService.FileProperties> SortFilePropertiesOrder(list<MetadataService.FileProperties> fileProperties){

		map<Integer, MetadataService.FileProperties> returnMap = new map<Integer, MetadataService.FileProperties>();
		for(MetadataService.FileProperties fileProp : fileProperties){
			if (fileProp.fullName.right(1).isNumeric()) {
				Integer i = Integer.valueOf(fileProp.fullName.subStringAfterLast('-'));
				returnMap.put(i,fileProp);
			} else {
				returnMap.put(0,fileProp);
			}
		}
		return returnMap;
	}

	private list<MetadataService.FileProperties> CollectFileProperties() {
		MetadataService.MetadataPort service = new MetadataService.MetadataPort();
		if (service.endpoint_x.startsWithIgnoreCase('http:')) {
			service.endpoint_x = service.endpoint_x.removeStartIgnoreCase('http');
			service.endpoint_x = 'https' + service.endpoint_x;
		}
		service.SessionHeader = new MetadataService.SessionHeader_element();
		service.SessionHeader.sessionId = sessionId;
		List<MetadataService.ListMetadataQuery> queries = new List<MetadataService.ListMetadataQuery>();
		MetadataService.ListMetadataQuery currentQuery = new MetadataService.ListMetadataQuery();
		currentQuery.type_x = 'Flow';
		queries.add(currentQuery);
		return service.listMetadata(queries, 30);
	}

	private map<String, Integer> GetFullNameAndNumberOfVersions(list<MetadataService.FileProperties> fileProperties) {
		map<String, Integer> returnMap = new map<String, Integer>();
		for (MetadataService.FileProperties fileProp : fileProperties) {
			if (fileProp.fullName.right(1).isNumeric()) {
				if (returnMap.containsKey(fileProp.fullName.subStringBeforeLast('-'))) {
					integer ver = returnMap.get(fileProp.fullName.subStringBeforeLast('-')) + 1;
					returnMap.put(fileProp.fullName.subStringBeforeLast('-'), ver);
				} else {
					returnMap.put(fileProp.fullName.subStringBeforeLast('-'),1);
				}
			} else {
				if (returnMap.containsKey(fileProp.fullName)) {
					integer ver = returnMap.get(fileProp.fullName) + 1;
					returnMap.put(fileProp.fullName, ver);
				} else {
					returnMap.put(fileProp.fullName, 1);
				}
			}
		}
		return returnMap;
	}

	private map<String, list<MetadataService.FileProperties>> GetFullNameAndFileProperties(list<MetadataService.FileProperties> fileProperties) {
		map<String, list<MetadataService.FileProperties>> returnMap = new map<String, list<MetadataService.FileProperties>>();
		for (MetadataService.FileProperties fileProp : fileProperties) {
			if (fileProp.fullName.right(1).isNumeric()) {
				if (returnMap.containsKey(fileProp.fullName.subStringBeforeLast('-'))) {
					returnMap.get(fileProp.fullName.subStringBeforeLast('-')).add(fileProp);
				} else {
					returnMap.put(fileProp.fullName.subStringBeforeLast('-'), new list<MetadataService.FileProperties> {fileProp});
				}
			} else {
				if (returnMap.containsKey(fileprop.fullName)) {
					returnMap.get(fileProp.fullName).add(fileProp);
				} else {
					returnMap.put(fileProp.fullName, new list<MetadataService.FileProperties> {fileProp});
				}
			}
		}
		return returnMap;
	}



}