public with sharing class MetadataServiceExtension {
	public MetadataServiceExtension() {}

	public class FlowFileExtensionWrapper {
		public MetadataService.FileProperties fileProperty {get; set;}
		public String fullName {get; set;}
		public String flowId {get; set;}
		public Integer totalNumberOfVersions {get; set;}
		public Integer versionNumber {get; set;}
		public Integer previousFlowVersion {get; set;}
	}





}