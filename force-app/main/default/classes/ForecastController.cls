//Controller for the Forecast Entry LWC

public class ForecastController {

    @AuraEnabled(cacheable=false)
    public static ReturnDataClass  getForecastEntries(String recordId) {

        List<Data> returnDataList = new List<Data>();
        CumulativeData data = new CumulativeData();
        ReturnDataClass rd = new ReturnDataClass();

        Integer AccessLevel = getCurrentUserAccess(rd);

        List<Advertiser_Agency_Relationship__c> AARList = new List<Advertiser_Agency_Relationship__c>();
        AARList = getAARList(AccessLevel,recordId);

        //Process Relationship data to be sent to UI
        for(Advertiser_Agency_Relationship__c AAR : AARList){
            
            Data returnData = new Data();
            //If Account Forecast does not exist then return
            if( AAR.Account_Forecasts__r == null || AAR.Account_Forecasts__r.isEmpty()){
                continue;
            }

            //Capture Forecast data
            returnData.Id = AAR.Account_Forecasts__r[0].Id;
            returnData.Seller = AAR.Advertiser__r.Owner.Name;
            returnData.Advertiser = AAR.Advertiser__r.Name;
            returnData.SOPrimary = AAR.AAR_Split_Owners__r[0].Primary_owner__c;
            returnData.SOId = AAR.AAR_Split_Owners__r[0].Id;
            returnData.Agency = AAR.Agency__r.Name;
            returnData.Type = AAR.Account_Forecasts__r[0].Type__c;
            returnData.Channel = AAR.Account_Forecasts__r[0].Channel__c;
            returnData.TradingDeal = AAR.Account_Forecasts__r[0].Trading_Deal__c;
            returnData.BookingsCurrentYear = AAR.Account_Forecasts__r[0].Bookings_Current_Year__c ;
            returnData.BookingsNextYear= AAR.Account_Forecasts__r[0].Booking_Next_Year__c ;
            returnData.PipelineCurrentQuarter= AAR.Account_Forecasts__r[0].Pipeline_Current_Quarter__c ;
            returnData.PipelineNextQuarter= AAR.Account_Forecasts__r[0].Pipeline_Next_Quarter__c ;
            
            //Get Cumulative Data
            data.BookingsCurrentYear += AAR.Account_Forecasts__r[0].Bookings_Current_Year__c ;
            data.BookingsNextYear += AAR.Account_Forecasts__r[0].Booking_Next_Year__c ;
            data.PipelineCurrentQuarter += AAR.Account_Forecasts__r[0].Pipeline_Current_Quarter__c ;
            data.PipelineNextQuarter += AAR.Account_Forecasts__r[0].Pipeline_Next_Quarter__c ;


            returnData.ForecastList = new List<Forecast>();
            //Get Forecast Entry Data
            for(AAR_Split_Owner__c SplitOwner : AAR.AAR_Split_Owners__r){
                for(Forecast_Entry__c FE : SplitOwner.Forecast_Entries__r){
                    
                    Forecast forecastRecord = new Forecast();
                    forecastRecord.Id = FE.Id;
                    forecastRecord.OwnerName = SplitOwner.Owner.Name;
                    forecastRecord.name = FE.Product__c;
                    forecastRecord.q1 = FE.Forecast_Q1__c;
                    forecastRecord.q2 = FE.Forecast_Q2__c;
                    forecastRecord.q3 = FE.Forecast_Q3__c;
                    forecastRecord.q4 = FE.Forecast_Q4__c;
                    forecastRecord.q11 = FE.Forecast_Q11__c;
                    forecastRecord.q21 = FE.Forecast_Q21__c;
                    forecastRecord.q31 = FE.Forecast_Q31__c;
                    forecastRecord.q41 = FE.Forecast_Q41__c;

                    returnData.ForecastSum += FE.Forecast_Sum__c;

                    data.q1 += (FE.Forecast_Q11__c ?? 0);
                    data.q2 += (FE.Forecast_Q21__c ?? 0);
                    data.q3 += (FE.Forecast_Q31__c ?? 0);
                    data.q4 += (FE.Forecast_Q41__c ?? 0);

                    returnData.ForecastList.add(forecastRecord);
                    returnData.displayProducts = true;
                }
            }

            if(!returnData.ForecastList.isEmpty()){
                if(AccessLevel == 1 || AccessLevel == 2){
                    returnData.ForecastList[returnData.ForecastList.size()-1].displayAdd = true;
                }else if(AccessLevel == 3 && returnData.ForecastList.size() <4){
                    returnData.ForecastList[returnData.ForecastList.size()-1].displayAdd = true;
                } 
            }

            returnDataList.add(returnData);
            
        }
        
        rd.returnDataList = returnDataList;
        rd.data = data;

        return rd;
    }

    @AuraEnabled 
    public static String processData(List<Data> returnDataList, List<String> deletedForecastList) {
		system.debug('### returnDataList '+returnDataList);
        List<Account_Forecast__c> AFList = new List<Account_Forecast__c>();
        List<Forecast_Entry__c> forecastList = new List<Forecast_Entry__c>();


        for(Data dataRecord : returnDataList){
            // Check if the current dataRecord has changed
            if(dataRecord.isChanged){
                // Create a new Account_Forecast__c record
                Account_Forecast__c AF = new Account_Forecast__c();
                AF.Id = dataRecord.Id; // Set the ID of the record
                AF.Channel__c = dataRecord.Channel; // Set the Channel field
                AF.Trading_Deal__c = dataRecord.TradingDeal; // Set the Trading Deal field
                AFList.add(AF); // Add the record to the AFList
            }


            for(Forecast forecastRecord : dataRecord.ForecastList){
                // Check if the current forecastRecord has changed
                if(forecastRecord.isChanged){
                    // Create a new Forecast_Entry__c record
                    Forecast_Entry__c FE = new Forecast_Entry__c();
                    FE.Product__c = forecastRecord.name; // Set the Product field
                    FE.Forecast_Q1__c = forecastRecord.q1; // Set Q1 forecast
                    FE.Forecast_Q2__c = forecastRecord.q2; // Set Q2 forecast
                    FE.Forecast_Q3__c = forecastRecord.q3; // Set Q3 forecast
                    FE.Forecast_Q4__c = forecastRecord.q4; // Set Q4 forecast

                    // Set additional forecast fields for quarters 11 to 41
                    FE.Forecast_Q11__c = forecastRecord.q11;
                    FE.Forecast_Q21__c = forecastRecord.q21;
                    FE.Forecast_Q31__c = forecastRecord.q31;
                    FE.Forecast_Q41__c = forecastRecord.q41;

                    FE.AAR_Split_Owner__c = dataRecord.SOId; // Set the owner field
                    FE.IsActive__c = true; 

                    forecastList.add(FE); 

                    // If the forecastRecord has a valid ID (18 characters long), create an inactive record
                    if(forecastRecord.Id.length() == 18){
                        FE = new Forecast_Entry__c(); 
                        FE.Id = forecastRecord.Id; 
                        FE.IsActive__c = false; 
                        forecastList.add(FE); 
                    }
                }
            }
        }

        // Loop through each ID in the deletedForecastList
        for(String Id : deletedForecastList){
            // If the ID is valid (18 characters long), create an inactive forecast entry
            if(Id.length() == 18){
                Forecast_Entry__c FE = new Forecast_Entry__c();
                FE.Id = Id; // Set the ID for the forecast entry
                FE.IsActive__c = false; // Mark the forecast entry as inactive
                forecastList.add(FE); // Add the inactive forecast entry to the list
            }
        }

        // Update the Account_Forecast__c records in the database
        Database.update(AFList);
        // Upsert (update or insert) the Forecast_Entry__c records in the database
        Database.upsert(forecastList);
        
        // Return a success message
        return 'Received data: ';
    }

    //execute the batch to calculte Account Forecast data
    @AuraEnabled
    public static Boolean runBatchJob(Boolean disableBatchButton) {


        List<AsyncApexJob> jobList = [SELECT Status,CompletedDate FROM AsyncApexJob WHERE ApexClass.Name = 'AccountForecastBatch' AND Status IN ('Holding','Preparing','Processing','Queued') AND Id != : System.Label.AccountForecastBatchJobId order BY CompletedDate DESC LIMIT 1];
        if(jobList == null || jobList.isEmpty()){
            if(!disableBatchButton){
                AccountForecastBatch batch = new AccountForecastBatch();
                Database.executeBatch(batch);
                return false;
            }
            return true;
        }

        return false;
        
    }

    //Get users
    @AuraEnabled(cacheable=true)
    public static List<User> getUsers(String searchTerm) {
        return [SELECT Id, Name FROM User WHERE Name LIKE :('%' + searchTerm + '%') LIMIT 5];
    }

    //Get Relationships
    @AuraEnabled(cacheable=true)
    public static List<Advertiser_Agency_Relationship__c> getAARs(String searchTerm) {
        return [SELECT Id, Name ,Advertiser_Agency_Name__c FROM Advertiser_Agency_Relationship__c WHERE (Name LIKE :('%' + searchTerm + '%') OR  Advertiser_Agency_Name__c LIKE :('%' + searchTerm + '%')) AND ID NOT IN (SELECT Advertiser_Agency_Relationship__c FROM AAR_Split_Owner__c WHERE  Is_Active__c = true AND OwnerId = :UserInfo.getUserId()) LIMIT 5];
    }

    //Create split
    @AuraEnabled
    public static void createSplitOwner(String recordId) {
        AAR_Split_Owner__c AARSplitOwnerRecord;
        try{
            AARSplitOwnerRecord = [SELECT Id FROM AAR_Split_Owner__c Where Advertiser_Agency_Relationship__c = :recordId AND OwnerId = :UserInfo.getUserId() AND Is_Active__c = false limit 1];
            AARSplitOwnerRecord.Is_Active__c = true;
            update AARSplitOwnerRecord;
            
        }
        catch(Exception e){
            AARSplitOwnerRecord = new AAR_Split_Owner__c();
            AARSplitOwnerRecord.Advertiser_Agency_Relationship__c = recordId;
            AARSplitOwnerRecord.Is_Active__c = true;
            insert AARSplitOwnerRecord;
        }
        
    }

    //Deactivate split 
    @AuraEnabled
    public static void removeAAR(String recordId) {
        
        AAR_Split_Owner__c AARSplitOwnerRecord = new AAR_Split_Owner__c();
        AARSplitOwnerRecord.Id = recordId;
        AARSplitOwnerRecord.Is_Active__c = false;
        update AARSplitOwnerRecord;
    }

    //Submit for approval process
    @AuraEnabled
    public static void submitForApproval(String recordId, String selectedNewOwner) {
        // Replace with your approval logic, e.g., submitting an object for approval
        // Here, we're assuming there's an Approval Process defined in your org.

        Account_Forecast__c AF = [Select Id,Advertiser_Agency_Relationship__r.Advertiser__c from Account_Forecast__c Where Id =:recordId LIMIT 1];

        Account acc = new Account();
        acc.Id = AF.Advertiser_Agency_Relationship__r.Advertiser__c;
        acc.New_Owner__c = selectedNewOwner;
        update acc;

        // Example: submit for approval (assuming we have a process)
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setObjectId(AF.Advertiser_Agency_Relationship__r.Advertiser__c);

        // Optional: You can add comments, additional parameters, etc.
        //req.setComments('Submitting for approval: ' + selectedAdvertiserName);

        // Submit for approval
        Approval.ProcessResult result = Approval.process(req);

        // Check the result
        if (result.isSuccess()) {
            // Handle success (e.g., log, update record, etc.)
        } else {
            // Handle errors (e.g., log, throw exception, etc.)
            throw new AuraHandledException('Error submitting for approval: ' + result.getErrors()[0].getMessage());
        }
    }

    public static Integer getCurrentUserAccess(ReturnDataClass rd){
		
        Id profileId = UserInfo.getProfileId();
        Profile profile = [SELECT Name FROM Profile WHERE Id = :profileId];

        if(profile.Name.equalsIgnoreCase('System Administrator')){
            rd.isManager = true;
            return 1;
        }

        List<GroupMember> gmList = [SELECT Id,Group.DeveloperName FROM GroupMember WHERE Group.DeveloperName IN ('FE_Admin_Access','FE_Manager_Access','FE_Sales_Access') AND UserOrGroupId =:UserInfo.getUserId()  ORDER BY Group.DeveloperName];
        For(GroupMember gmRecord : gmList){
            if(gmRecord.Group.DeveloperName.equalsIgnoreCase('FE_Admin_Access')){
                rd.isManager = true;
                return 1;
            }
            else if(gmRecord.Group.DeveloperName.equalsIgnoreCase('FE_Manager_Access')){
                rd.isManager = true;
                return 2;
            }
            else if(gmRecord.Group.DeveloperName.equalsIgnoreCase('FE_Sales_Access')){
                return 3;
            }
        }
        return 0;
    }

    public static List<Advertiser_Agency_Relationship__c> getAARList(Integer AccessLevel, String recordId){
        
        if(AccessLevel == 0) return null;

        List<Advertiser_Agency_Relationship__c> AARList = new List<Advertiser_Agency_Relationship__c>();

        String AccessCondition = '';
        String AccountCondition = '';
        
        if(AccessLevel == 2){
            AccessCondition = ' AND (Owner_s_Manager__c = \''+UserInfo.getUserId()+'\' OR OwnerId = \''+UserInfo.getUserId()+'\') ';
        }else if(AccessLevel == 3){
            AccessCondition = ' AND OwnerId = \''+UserInfo.getUserId()+'\'';
        }

        if(recordId != null){
            AccountCondition = ' AND Advertiser__c = \''+recordId+'\'';
        }

        String query = 'SELECT Id,	Agency__c,	Agency__r.Name,	Advertiser__c,	Advertiser__r.Name, Advertiser__r.Owner.Name,(SELECT Id,Type__c,Channel__c,Trading_Deal__c,	Booking_Next_Year__c, convertCurrency(Bookings_Current_Year__c),Pipeline_Current_Quarter__c,Pipeline_Next_Quarter__c FROM Account_Forecasts__r LIMIT 1),(SELECT Id,Primary_owner__c,Advertiser_Agency_Relationship__c,	OwnerId,Owner.Name,(SELECT Id, Forecast_Q1__c,	Forecast_Q2__c, Forecast_Q3__c,	Forecast_Q4__c,Forecast_Q11__c,	Forecast_Q21__c,Forecast_Q31__c,Forecast_Q41__c,Product__c,	Forecast_Sum__c	FROM Forecast_Entries__r WHERE IsActive__c = true) FROM AAR_Split_Owners__r	WHERE Is_Active__c = true '+AccessCondition+' ORDER BY Owner.Name ) FROM Advertiser_Agency_Relationship__c WHERE ID IN (SELECT Advertiser_Agency_Relationship__c FROM Account_Forecast__c) AND ID IN (SELECT Advertiser_Agency_Relationship__c FROM AAR_Split_Owner__c WHERE Is_Active__c = true'+AccessCondition+')'+AccountCondition+' ORDER BY Advertiser__r.Name';

        AARList = Database.query(query);

        return AARList;
    }
    
    //Inner Class to return result to LWC
    public Class ReturnDataClass{
        @AuraEnabled
        public List<Data> returnDataList { get; set; }
        @AuraEnabled
        public CumulativeData data { get; set; }  
        @AuraEnabled
        public Boolean isManager  { get; set; }

        public ReturnDataClass(){
            this.returnDataList = new List<Data>();
            this.isManager = false;
            data = new CumulativeData();
        }
    }

    //Inner Class to return account forecast data to LWC
    public class Data {
        @AuraEnabled
        public String Id { get; set; }
        @AuraEnabled   
        public String Seller { get; set; }
        @AuraEnabled
        public String Advertiser { get; set; } 
        @AuraEnabled
        public String SOId { get; set; }  
        @AuraEnabled
        public Boolean SOPrimary { get; set; } 
        @AuraEnabled
        public String Agency { get; set; }
        @AuraEnabled
        public String Type { get; set; }
        @AuraEnabled
        public String Channel { get; set; }
        @AuraEnabled
        public Boolean TradingDeal { get; set; }
        @AuraEnabled
        public Decimal BookingsCurrentYear { get; set; }
        @AuraEnabled
        public Decimal BookingsNextYear { get; set; }
        @AuraEnabled
        public Decimal PipelineCurrentQuarter { get; set; }
        @AuraEnabled
        public Decimal PipelineNextQuarter { get; set; }
        @AuraEnabled
        public List<Forecast> ForecastList { get; set; }
        @AuraEnabled
        public Boolean isExpanded  { get; set; }
        @AuraEnabled
        public Boolean isChanged  { get; set; }
        @AuraEnabled
        public Boolean isDisplayed  { get; set; }

        @AuraEnabled
        public Decimal ForecastSum { get; set; }

        @AuraEnabled
        public Boolean displayProducts  { get; set; }

        public Data(){
            this.isExpanded = false;
            this.isChanged = false;
            this.isDisplayed = true;
            this.displayProducts = false;
            this.ForecastSum = 0;
            this.SOPrimary = false;
            this.ForecastList = new List<Forecast>();
        }


    }
    
    //Inner Class to return forecast to LWC
    public class Forecast {
        @AuraEnabled
        public String Id { get; set; }
        @AuraEnabled   
        public String OwnerName { get; set; }
        @AuraEnabled   
        public String name { get; set; }
        @AuraEnabled
        public Decimal q1 { get; set; }
        @AuraEnabled
        public Decimal q2 { get; set; }
        @AuraEnabled
        public Decimal q3 { get; set; }
        @AuraEnabled
        public Decimal q4 { get; set; }

        @AuraEnabled
        public Decimal q11 { get; set; }
        @AuraEnabled
        public Decimal q21 { get; set; }
        @AuraEnabled
        public Decimal q31 { get; set; }
        @AuraEnabled
        public Decimal q41 { get; set; }

        @AuraEnabled
        public Boolean displayAdd { get; set; } 
        @AuraEnabled
        public Boolean isChanged { get; set; }

        public Forecast() {
            this.displayAdd = false;
            this.isChanged = false;
        }
    }

    //Inner Class to return cumulative data to LWC
    public class CumulativeData {

        @AuraEnabled
        public Decimal BookingsCurrentYear { get; set; }
        @AuraEnabled
        public Decimal BookingsNextYear { get; set; }
        @AuraEnabled
        public Decimal PipelineCurrentQuarter { get; set; }
        @AuraEnabled
        public Decimal PipelineNextQuarter { get; set; }

        @AuraEnabled
        public Decimal q1 { get; set; }
        @AuraEnabled
        public Decimal q2 { get; set; }
        @AuraEnabled
        public Decimal q3 { get; set; }
        @AuraEnabled
        public Decimal q4 { get; set; }

        public CumulativeData() {
            this.BookingsCurrentYear = 0;
            this.BookingsNextYear = 0;
            this.PipelineCurrentQuarter = 0;
            this.PipelineNextQuarter = 0;

            this.q1 = 0;
            this.q2 = 0;
            this.q3 = 0;
            this.q4 = 0;

        }

    }
    
}