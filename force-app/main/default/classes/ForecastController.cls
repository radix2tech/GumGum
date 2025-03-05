//Controller for the Forecast Entry LWC

public class ForecastController {

    static Integer totalRecords = 0;
    static Set<Id> AllAFRecords = new Set<Id>();
    
    public static Map<String,DatedConversionRate> conversionRate = new Map<String,DatedConversionRate>();

    public static Decimal getConvertedRateFromUSD(String currencyCode,Decimal amount){

        if(conversionRate == null || conversionRate.isEmpty()){

            // Query all latest conversion rates for all currencies
            List<DatedConversionRate> DatedConversionRates = [
                SELECT ConversionRate, IsoCode, StartDate
                FROM DatedConversionRate
            ];

            // Step 3: Populate the map with the conversion rates
            for (DatedConversionRate rate : DatedConversionRates) {
                if(conversionRate.containsKey(rate.IsoCode) && conversionRate.get(rate.IsoCode).StartDate < rate.startDate ){
                    conversionRate.remove(rate.IsoCode);
                }
                
                conversionRate.put(rate.IsoCode,rate);
                
                
            }
        }

        return conversionRate.get(currencyCode).ConversionRate * amount;
    }

    public static Decimal getConvertedRateFromUSD1(String currencyCode){

        if(conversionRate == null || conversionRate.isEmpty()){

            // Query all latest conversion rates for all currencies
            List<DatedConversionRate> DatedConversionRates = [
                SELECT ConversionRate, IsoCode, StartDate
                FROM DatedConversionRate
            ];

            // Step 3: Populate the map with the conversion rates
            for (DatedConversionRate rate : DatedConversionRates) {
                if(conversionRate.containsKey(rate.IsoCode) && conversionRate.get(rate.IsoCode).StartDate < rate.startDate ){
                    conversionRate.remove(rate.IsoCode);
                }
                conversionRate.put(rate.IsoCode,rate);
            }
        }
        return conversionRate.get(currencyCode).ConversionRate;
    }


    public static Forecast convertCurrencyFields(Forecast f){
        Forecast convForecast = new Forecast(f);
         String userCurrencyIsoCode = UserInfo.getDefaultCurrency();
        if(f.currencyISOCode == null || f.currencyISOCode == userCurrencyIsoCode){
           f.currencyISOCode =  userCurrencyIsoCode;
           return convForecast;
        }
       
        system.debug('#### f.currencyISOCode'+f.currencyISOCode);
        DatedConversionRate dcr = [SELECT ConversionRate 
                                FROM DatedConversionRate 
                                WHERE IsoCode = :f.currencyISOCode 
                                AND StartDate <= :System.today() 
                                ORDER BY StartDate DESC LIMIT 1];
        if (dcr != null) {
            if(convForecast.q11 > 0)convForecast.q11 = convForecast.q11 * dcr.ConversionRate;
            if(convForecast.q21 > 0)convForecast.q21 = convForecast.q21 * dcr.ConversionRate;
            if(convForecast.q31 > 0)convForecast.q31 = convForecast.q31 * dcr.ConversionRate;
            if(convForecast.q41 > 0)convForecast.q41 = convForecast.q41 * dcr.ConversionRate;
        }
        return convForecast;
    }

    @AuraEnabled(cacheable=false)
    public static ReturnDataClass  getForecastEntries(String recordId, Integer pageSize, Integer pageNumber ,List<String> sellerLabelSet, List<String> advertiserLabelSet ,List<String> agencyLabelSet,List<String> typeLabelSet, List<String> channelLabelSet) {

        List<Data> returnDataList = new List<Data>();
        CumulativeData data = new CumulativeData();
        ReturnDataClass rd = new ReturnDataClass();

        String currentUsersCurrency = UserInfo.getDefaultCurrency();
        Decimal CurrentUserConversionRate = 1;
        if(currentUsersCurrency != 'USD'){
            CurrentUserConversionRate = getConvertedRateFromUSD1(currentUsersCurrency);
            //CurrentUserConversionRate = 1/CurrentUserConversionRate;
        }

        Integer AccessLevel = getCurrentUserAccess(rd);

        List<Account_Forecast__c> AFList = getAFList(AccessLevel,recordId,pageSize,pageNumber,sellerLabelSet,advertiserLabelSet, agencyLabelSet,typeLabelSet,channelLabelSet);

        AggregateResult[] AFAggregateResult1 = [
            SELECT 
                SUM(Booking_Next_Year__c) totalBookingNextYear, 
                SUM(Bookings_Current_Year__c) totalBookingsCurrentYear, 
                SUM(Pipeline_Current_Quarter__c) totalPipelineCurrentQuarter, 
                SUM(Pipeline_Next_Quarter__c) totalPipelineNextQuarter 
            FROM Account_Forecast__c WHERE Id IN :AllAFRecords
        ];

        System.debug('AFAggregateResult1: ' + AFAggregateResult1);

        data.BookingsCurrentYear = (Decimal)AFAggregateResult1[0].get('totalBookingsCurrentYear') ;
        data.BookingsCurrentYear =  (data.BookingsCurrentYear != null ? data.BookingsCurrentYear : 0) * CurrentUserConversionRate;

        data.BookingsNextYear = (Decimal)AFAggregateResult1[0].get('totalBookingNextYear') ;
        data.BookingsNextYear = (data.BookingsNextYear != null ? data.BookingsNextYear : 0) * CurrentUserConversionRate;

        data.PipelineCurrentQuarter = (Decimal)AFAggregateResult1[0].get('totalPipelineCurrentQuarter') ;
        data.PipelineCurrentQuarter = (data.PipelineCurrentQuarter != null ? data.PipelineCurrentQuarter : 0) * CurrentUserConversionRate;

        data.PipelineNextQuarter = (Decimal)AFAggregateResult1[0].get('totalPipelineNextQuarter') ;
        data.PipelineNextQuarter = (data.PipelineNextQuarter != null ? data.PipelineNextQuarter : 0) * CurrentUserConversionRate;

        String AFAggregateResultQuery2 = 'SELECT SUM(Forecast_Q11__c) Total_Forecast_Q11,  SUM(Forecast_Q21__c) Total_Forecast_Q21, SUM(Forecast_Q31__c) Total_Forecast_Q31,  SUM(Forecast_Q41__c) Total_Forecast_Q41, SUM(Forecast_Q1__c) Total_Forecast_Q1,SUM(Forecast_Q2__c) Total_Forecast_Q2, SUM(Forecast_Q3__c) Total_Forecast_Q3, SUM(Forecast_Q4__c) Total_Forecast_Q4 FROM Forecast_Entry__c  WHERE '+ SellerForecastEntryConditionQuery +' IsActive__c = true'+ AccessConditionCumulative;
        AggregateResult[] AFAggregateResult2 = Database.query(AFAggregateResultQuery2);

        data.q1 = (Decimal)AFAggregateResult2[0].get('Total_Forecast_Q11') ;
        data.q1 = (data.q1 != null ? data.q1 : 0) * CurrentUserConversionRate;

        data.q2 = (Decimal)AFAggregateResult2[0].get('Total_Forecast_Q21') ;
        data.q2 = (data.q2 != null ? data.q2 : 0) * CurrentUserConversionRate;

        data.q3 = (Decimal)AFAggregateResult2[0].get('Total_Forecast_Q31') ;
        data.q3 = (data.q3 != null ? data.q3 : 0) * CurrentUserConversionRate;

        data.q4 = (Decimal)AFAggregateResult2[0].get('Total_Forecast_Q41') ;
        data.q4 = (data.q4 != null ? data.q4 : 0) * CurrentUserConversionRate;

        data.ForecastNextYear = (data.q1 != null ? data.q1 : 0) + 
                                (data.q2 != null ? data.q2 : 0) + 
                                (data.q3 != null ? data.q3 : 0) + 
                                (data.q4 != null ? data.q4 : 0);

        data.CYq1 = (Decimal)AFAggregateResult2[0].get('Total_Forecast_Q1') ;
        data.CYq1 = (data.CYq1 != null ? data.CYq1 : 0) * CurrentUserConversionRate;

        data.CYq2 = (Decimal)AFAggregateResult2[0].get('Total_Forecast_Q2') ;
        data.CYq2 = (data.CYq2 != null ? data.CYq2 : 0) * CurrentUserConversionRate;

        data.CYq3 = (Decimal)AFAggregateResult2[0].get('Total_Forecast_Q3') ;
        data.CYq3 = (data.CYq3 != null ? data.CYq3 : 0) * CurrentUserConversionRate;

        data.CYq4 = (Decimal)AFAggregateResult2[0].get('Total_Forecast_Q4') ;
        data.CYq4 = (data.CYq4 != null ? data.CYq4 : 0) * CurrentUserConversionRate;

        data.ForecastCY = (data.CYq1 != null ? data.CYq1 : 0) + 
                                (data.CYq2 != null ? data.CYq2 : 0) + 
                                (data.CYq3 != null ? data.CYq3 : 0) + 
                                (data.CYq4 != null ? data.CYq4 : 0);                        

        //Process Relationship data to be sent to UI
        for(Account_Forecast__c AF : AFList){
            
            Data returnData = new Data();

            //Capture Forecast data
            returnData.Id = AF.Id;
            returnData.AARId = AF.Advertiser_Agency_Relationship__c;
            system.debug('### returnData.Id ' +returnData.Id);
            returnData.Seller = AF.Advertiser_Agency_Relationship__r.Advertiser__r.Owner.Name;
            returnData.Advertiser = AF.Advertiser_Agency_Relationship__r.Advertiser__r.Name;
            returnData.AdvertiserId = AF.Advertiser_Agency_Relationship__r.Advertiser__c;
            //returnData.SOPrimary = AAR.AAR_Split_Owners__r[0].Primary_owner__c;
            //returnData.SOId = AAR.AAR_Split_Owners__r[0].Id;
            returnData.Agency = AF.Advertiser_Agency_Relationship__r.Agency__r.Name;
            returnData.AgencyId = AF.Advertiser_Agency_Relationship__r.Agency__c;
            returnData.Type = AF.Type__c;
            returnData.Channel = AF.Channel__c;
            returnData.TradingDeal = AF.Trading_Deal__c;
            returnData.BookingsCurrentYear = AF.Bookings_Current_Year__c ;
            returnData.BookingsNextYear= AF.Booking_Next_Year__c ;
            returnData.PipelineCurrentQuarter= AF.Pipeline_Current_Quarter__c ;
            returnData.PipelineNextQuarter= AF.Pipeline_Next_Quarter__c ;

            /*if(sellerLabelSet!= null && !sellerLabelSet.isEmpty()){
                returnData.isExpanded = true;
            }*/

            returnData.ForecastList = new List<Forecast>();
            //Get Forecast Entry Data
            for(AAR_Split_Owner__c SplitOwner : AF.AAR_Split_Owners__r){
                for(Forecast_Entry__c FE : SplitOwner.Forecast_Entries__r){
                    
                    if(sellerLabelSet!= null && !sellerLabelSet.isEmpty()){
                        returnData.isExpanded = true;
                    }

                    Forecast forecastRecord = new Forecast();
                    forecastRecord.Id = FE.Id;
                    forecastRecord.OwnerName = FE.AAR_Split_Owner__r.Owner__r.Name;
                    forecastRecord.SplitOwnerRecId = FE.AAR_Split_Owner__c;
                    forecastRecord.name = FE.Product__c;
                    forecastRecord.q1 = FE.Q1_PY_Bookings__c;
                    forecastRecord.q2 = FE.Q2_PY_Bookings__c;
                    forecastRecord.q3 = FE.Q3_PY_Bookings__c;
                    forecastRecord.q4 = FE.Q4_PY_Bookings__c;
                    forecastRecord.q11 = FE.Forecast_Q11__c;
                    forecastRecord.q21 = FE.Forecast_Q21__c;
                    forecastRecord.q31 = FE.Forecast_Q31__c;
                    forecastRecord.q41 = FE.Forecast_Q41__c;
                    forecastRecord.currencyISOCode = FE.CurrencyIsoCode;
                    forecastRecord.productCumulative = FE.Forecast_Sum__c;

                    returnData.ForecastSum += FE.Forecast_Sum__c;

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
        rd.currencySymbol = currentUsersCurrency+' ';
        rd.data = data;
        rd.totalRecords = totalRecords;
        return rd;
    }

    public static String SellerForecastEntryConditionQuery = '';
    public static string AccessCondition = '';
    public static string AccessConditionCumulative = '';
    public static Set<Id> allSubordinateUsers = new Set<Id>();

    @AuraEnabled 
    public static List<Account_Forecast__c> getAFList(Integer AccessLevel, String recordId,Integer pageSize, Integer pageNumber,List<String> sellerLabelSet, List<String> advertiserLabelSet, List<String> agencyLabelSet, List<String> typeLabelSet, List<String> channelLabelSet){

        if(AccessLevel == 0) return null;

        String SellerConditionQuery = '';
        String SellerForecastConditionQuery = '';

        //String SellerForecastEntryConditionQuery = '';

        if(sellerLabelSet!= null && !sellerLabelSet.isEmpty()){
            List<String> sellerConditions = new List<String>();
            List<String> sellerForecastConditions = new List<String>();

            List<String> sellerForecastEntryConditions = new List<String>();

            for (String pattern : sellerLabelSet) {
                sellerConditions.add('Advertiser_Agency_Relationship__r.Advertiser__r.Owner.Name LIKE \'' + pattern + '\'');
                sellerForecastConditions.add('Owner__r.Name LIKE \'' + pattern + '\'');

                sellerForecastEntryConditions.add('Owner__r.Name LIKE \'' + pattern + '\'');
            }

            SellerConditionQuery = ' ( ' + String.join(sellerConditions, ' OR ') + ') AND ';
            SellerForecastConditionQuery = 'ID IN ( SELECT Account_Forecast__c FROM AAR_Split_Owner__c WHERE ( ' + String.join(sellerForecastConditions, ' OR ') + ')) AND';

            SellerForecastEntryConditionQuery = 'AAR_Split_Owner__c IN ( SELECT ID FROM AAR_Split_Owner__c WHERE ( ' + String.join(sellerForecastEntryConditions, ' OR ') + ')) AND';
        }

        String AdvertiserConditionQuery = '';
        if(advertiserLabelSet!= null && !advertiserLabelSet.isEmpty()){
            List<String> AdvertiserConditions = new List<String>();
 
            for (String pattern : advertiserLabelSet) {
                AdvertiserConditions.add('Advertiser_Agency_Relationship__r.Advertiser__r.Name LIKE \'' + pattern + '\'');
            }

            AdvertiserConditionQuery = ' ( ' + String.join(AdvertiserConditions, ' OR ') + ') AND ';
        }
        


        String AgencyConditionQuery = '';
        if(AgencyLabelSet!= null && !AgencyLabelSet.isEmpty()){
            List<String> AgencyConditions = new List<String>();
 
            for (String pattern : AgencyLabelSet) {
                AgencyConditions.add('Advertiser_Agency_Relationship__r.Agency__r.Name LIKE \'' + pattern + '\'');
            }

            AgencyConditionQuery = ' ( ' + String.join(AgencyConditions, ' OR ') + ') AND ';
            system.debug('#### AgencyConditionQuery'+AgencyConditionQuery);
        }

        String TypeConditionQuery = '';
        if(typeLabelSet!= null && !typeLabelSet.isEmpty()){
            List<String> TypeConditions = new List<String>();
 
            for (String pattern : typeLabelSet) {
                TypeConditions.add('Type__c = \'' + pattern + '\'');
            }

            TypeConditionQuery =  ' ( ' + String.join(TypeConditions, ' OR ') + ') AND';
            system.debug('#### TypeConditionQuery'+TypeConditionQuery);
        }


        String ChannelConditionQuery = '';
        if(ChannelLabelSet!= null && !ChannelLabelSet.isEmpty()){
            List<String> ChannelConditions = new List<String>();
 
            for (String pattern : ChannelLabelSet) {
                ChannelConditions.add('Channel__c = \'' + pattern + '\'');
            }

            ChannelConditionQuery =  '  ( ' + String.join(ChannelConditions, ' OR ') + ') AND ';

            system.debug('#### ChannelConditionQuery'+ChannelConditionQuery);
        }

        Integer offset = (pageNumber - 1) * pageSize;


        String AccountCondition = '';
        
        if(AccessLevel == 2){
            //List<User> allSubordinateUsers = getAllSubordinateUsers(UserInfo.getUserId());
            allSubordinateUsers = getAllSubordinates(UserInfo.getUserRoleId());
            if(allSubordinateUsers != null && !allSubordinateUsers.isEmpty()){
                AccessCondition = ' AND ( OwnerId = \''+UserInfo.getUserId()+'\' OR OwnerId IN :allSubordinateUsers ) ';
                AccessConditionCumulative = ' AND ( AAR_Split_Owner__r.OwnerId = \''+UserInfo.getUserId()+'\' OR AAR_Split_Owner__r.OwnerId IN :allSubordinateUsers ) ';
            }else{
                AccessCondition = ' AND OwnerId = \''+UserInfo.getUserId()+'\'';
                AccessConditionCumulative = ' AND AAR_Split_Owner__r.OwnerId = \''+UserInfo.getUserId()+'\'';
            }
        }else if(AccessLevel == 3){
            AccessCondition = ' AND OwnerId = \''+UserInfo.getUserId()+'\'';
        }

        if(recordId != null){
            AccountCondition = ' AND Advertiser_Agency_Relationship__r.Advertiser__c = \''+recordId+'\'';
        }


        List<Account_Forecast__c> AFList1 = new List<Account_Forecast__c>();
        List<Account_Forecast__c> AFList2 = new List<Account_Forecast__c>();
        

        String query1 = 'SELECT Id FROM Account_Forecast__c WHERE '+SellerConditionQuery+AdvertiserConditionQuery+AgencyConditionQuery+TypeConditionQuery+ChannelConditionQuery+' ID IN (SELECT Account_Forecast__c FROM AAR_Split_Owner__c WHERE Is_Active__c = true ' + AccessCondition + ')' + AccountCondition + ' ORDER BY Advertiser_Agency_Relationship__r.Advertiser__r.Name';
        String query2 = 'SELECT Id FROM Account_Forecast__c WHERE '+SellerForecastConditionQuery+AdvertiserConditionQuery+AgencyConditionQuery+TypeConditionQuery+ChannelConditionQuery+' ID IN (SELECT Account_Forecast__c FROM AAR_Split_Owner__c WHERE Is_Active__c = true ' + AccessCondition + ')' + AccountCondition + ' ORDER BY Advertiser_Agency_Relationship__r.Advertiser__r.Name';

        system.debug('## query1 '+query1);
        system.debug('## query2 '+query2);

        AFList1 = Database.query(query1);
        AFList2 = Database.query(query2);

        //AFList1.addAll(AFList2);
        //totalRecords = AFList1.size();

        Map<Id, Account_Forecast__c> AFMap1 = new Map<Id, Account_Forecast__c>(AFList1);
        Map<Id, Account_Forecast__c> AFMap2 = new Map<Id, Account_Forecast__c>(AFList2);


        AFMap2.putAll(AFMap1);

        totalRecords = AFMap2.size();
        AllAFRecords = AFMap2.keySet() ;

        List<Account_Forecast__c> AFList3 = new List<Account_Forecast__c>();

        //String query3 = 'SELECT Id, Type__c, Channel__c, Trading_Deal__c, Advertiser_Agency_Relationship__c, Advertiser_Agency_Relationship__r.Agency__c, Advertiser_Agency_Relationship__r.Agency__r.Name, Advertiser_Agency_Relationship__r.Advertiser__c, Advertiser_Agency_Relationship__r.Advertiser__r.Name, Advertiser_Agency_Relationship__r.Advertiser__r.Owner.Name, CONVERTCURRENCY(Booking_Next_Year__c), CONVERTCURRENCY(Bookings_Current_Year__c), CONVERTCURRENCY(Pipeline_Current_Quarter__c), CONVERTCURRENCY(Pipeline_Next_Quarter__c), (SELECT Id, (SELECT Id, AAR_Split_Owner__r.Owner__r.Name, Product__c, Forecast_Q1__c, Forecast_Q2__c, Forecast_Q3__c, Forecast_Q4__c, Forecast_Q11__c, Forecast_Q21__c, Forecast_Q31__c, Forecast_Q41__c, CurrencyIsoCode, Forecast_Sum__c FROM Forecast_Entries__r WHERE IsActive__c = true) FROM AAR_Split_Owners__r WHERE Is_Active__c = true ' + AccessCondition + ' ORDER BY Owner__r.Name) FROM Account_Forecast__c WHERE '+SellerConditionQuery+AdvertiserConditionQuery+AgencyConditionQuery+TypeConditionQuery+ChannelConditionQuery+' ID IN (SELECT Account_Forecast__c FROM AAR_Split_Owner__c WHERE Is_Active__c = true ' + AccessCondition + ')' + AccountCondition + ' ORDER BY Advertiser_Agency_Relationship__r.Advertiser__r.Name LIMIT ' + pageSize + ' OFFSET ' + offset;
        
        String idsString = String.join(new List<Id>(AFMap2.keySet()), '\',\'');

        String query3 = 'SELECT Id, Type__c, Channel__c, Trading_Deal__c, Advertiser_Agency_Relationship__c, Advertiser_Agency_Relationship__r.Agency__c, Advertiser_Agency_Relationship__r.Agency__r.Name, Advertiser_Agency_Relationship__r.Advertiser__c, Advertiser_Agency_Relationship__r.Advertiser__r.Name, Advertiser_Agency_Relationship__r.Advertiser__r.Owner.Name, CONVERTCURRENCY(Booking_Next_Year__c), CONVERTCURRENCY(Bookings_Current_Year__c), CONVERTCURRENCY(Pipeline_Current_Quarter__c), CONVERTCURRENCY(Pipeline_Next_Quarter__c), (SELECT Id, (SELECT Id, AAR_Split_Owner__r.Owner__r.Name, Product__c, CONVERTCURRENCY(Q1_PY_Bookings__c), CONVERTCURRENCY(Q2_PY_Bookings__c), CONVERTCURRENCY(Q3_PY_Bookings__c), CONVERTCURRENCY(Q4_PY_Bookings__c),CONVERTCURRENCY(Forecast_Q1__c), CONVERTCURRENCY(Forecast_Q2__c), CONVERTCURRENCY(Forecast_Q3__c), CONVERTCURRENCY(Forecast_Q4__c), CONVERTCURRENCY(Forecast_Q11__c), CONVERTCURRENCY(Forecast_Q21__c), CONVERTCURRENCY(Forecast_Q31__c),CONVERTCURRENCY(Forecast_Q41__c), CurrencyIsoCode, CONVERTCURRENCY(Forecast_Sum__c) FROM Forecast_Entries__r WHERE '+ SellerForecastEntryConditionQuery +' IsActive__c = true) FROM AAR_Split_Owners__r WHERE Is_Active__c = true ' + AccessCondition + ' ORDER BY Owner__r.Name) FROM Account_Forecast__c WHERE Id IN (\'' + idsString + '\') LIMIT ' + pageSize + ' OFFSET ' + offset;
        AFList3 = Database.query(query3);

        return AFList3;
    }

    @AuraEnabled 
    public static String processData(List<Data> returnDataList, List<String> deletedForecastList) {
        List<Account_Forecast__c> AFList = new List<Account_Forecast__c>();
        List<Forecast_Entry__c> forecastList = new List<Forecast_Entry__c>();


        for(Data dataRecord : returnDataList){
            // Check if the current dataRecord has changed
            Account_Forecast__c AF = new Account_Forecast__c();
            if(dataRecord.isChanged){
                // Create a new Account_Forecast__c record
                AF = new Account_Forecast__c();
                AF.Id = dataRecord.Id; // Set the ID of the record
                AF.Channel__c = dataRecord.Channel; // Set the Channel field
                AF.Trading_Deal__c = dataRecord.TradingDeal; // Set the Trading Deal field
                AFList.add(AF); // Add the record to the AFList
                system.debug('### AF.Id '+AF.Id);
            }
            

            for(Forecast forecastRecord : dataRecord.ForecastList){
                system.debug('### forecastRecord'+forecastRecord);
                // Check if the current forecastRecord has changed
                if(forecastRecord.isChanged){
                    // Create a new Forecast_Entry__c record
                    Forecast_Entry__c FE = new Forecast_Entry__c();
                    FE.Product__c = forecastRecord.name; // Set the Product field
                    //FE.Forecast_Q1__c = forecastRecord.q1; // Set Q1 forecast
                    //FE.Forecast_Q2__c = forecastRecord.q2; // Set Q2 forecast
                    //FE.Forecast_Q3__c = forecastRecord.q3; // Set Q3 forecast
                    //FE.Forecast_Q4__c = forecastRecord.q4; // Set Q4 forecast

                    // Set additional forecast fields for quarters 11 to 41
                    forecastRecord = convertCurrencyFields(forecastRecord);
                    FE.Forecast_Q11__c = forecastRecord.q11;
                    FE.Forecast_Q21__c = forecastRecord.q21;
                    FE.Forecast_Q31__c = forecastRecord.q31;
                    FE.Forecast_Q41__c = forecastRecord.q41;
                    FE.currencyISOCode = forecastRecord.currencyISOCode;
                   

                    
                     // Set the owner field
                    //if(forecastRecord.Id != null && forecastRecord.Id.length() == 18) 
                    //FE.Id = forecastRecord.Id; // Set the owner field
                    FE.IsActive__c = true; 

                    //forecastList.add(FE); 

                    // If the forecastRecord has a valid ID (18 characters long), create an inactive record
                    if(forecastRecord.Id.length() == 18){
                        FE.AAR_Split_Owner__c = forecastRecord.SplitOwnerRecId;
                        Forecast_Entry__c FE1 = new Forecast_Entry__c(); 
                        FE1.Id = forecastRecord.Id; 
                        FE1.IsActive__c = false; 
                        forecastList.add(FE1); 
                        system.debug('### FE1 '+FE1);
                    }else{
                        List<AAR_Split_Owner__c> splitOwner = [SELECT Id,OwnerId,Is_Active__c FROM AAR_Split_Owner__c  
                                                                                            WHERE Account_Forecast__c = :dataRecord.Id 
                                                                                            AND OwnerId = :UserInfo.getUserId() LIMIT 1];
                        if(splitOwner != null && !splitOwner.isEmpty()){
                            FE.AAR_Split_Owner__c = splitOwner[0].Id;
                            if(!splitOwner[0].Is_Active__c)
                            {
                                splitOwner[0].Is_Active__c = true;
                                Update splitOwner;
                            }
                        }else{
                            AAR_Split_Owner__c AARSplitOwnerRecord = new AAR_Split_Owner__c();
                            AARSplitOwnerRecord.Advertiser_Agency_Relationship__c = [SELECT Advertiser_Agency_Relationship__c FROM Account_Forecast__c WHERE Id =:dataRecord.Id LIMIT 1].Advertiser_Agency_Relationship__c;
                            AARSplitOwnerRecord.Is_Active__c = true;
                            insert AARSplitOwnerRecord;
                            FE.AAR_Split_Owner__c = AARSplitOwnerRecord.Id;
                        }
                        
                    }
                    system.debug('### FE '+FE);
                    forecastList.add(FE);
                }
            }
        }

        // Loop through each ID in the deletedForecastList
        if(deletedForecastList!=null)
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

    @AuraEnabled(cacheable=true)
    public static List<String> getActiveCurrencies() {
        List<CurrencyType> currencyRecords = [SELECT IsoCode FROM CurrencyType WHERE IsActive = true];
        List<String> currencies = new List<String>();
        for (CurrencyType curr : currencyRecords) {
            currencies.add(curr.IsoCode);
        }
        return currencies;
    }
    
    public static List<User> getAllSubordinateUsers(Id managerId) {
        List<User> allSubordinates = new List<User>();
        List<Id> currentManagers = new List<Id>{managerId};
    
        // Governor limits tracking
        Integer maxSOQL = Limits.getLimitQueries();          // Total allowed SOQL queries
        Integer maxDML = Limits.getLimitDmlStatements();     // Total allowed DML statements
        Integer maxCPU = Limits.getLimitCpuTime();           // Total allowed CPU time in ms
        Integer maxHeap = Limits.getLimitHeapSize();         // Total allowed heap size in bytes
    
        while (!currentManagers.isEmpty()) {
            // Check SOQL limits
            if (Limits.getQueries() + 1 > maxSOQL) {
                System.debug('SOQL limit reached!');
                break;
            }
    
            // Check CPU time limits
            if (Limits.getCpuTime() > maxCPU - 10) { // Leave 10 ms buffer
                System.debug('CPU time limit is close!');
                break;
            }
    
            // Query to fetch subordinates
            List<User> subordinates = [SELECT Id, Name, Email, ManagerId
                                       FROM User
                                       WHERE ManagerId IN :currentManagers];
    
            // Check heap size limits
            if (Limits.getHeapSize() > maxHeap - 50000) { // Leave 50KB buffer
                System.debug('Heap size limit is close!');
                break;
            }
    
            // Add to the result list
            allSubordinates.addAll(subordinates);
    
            // Prepare the next set of managers
            currentManagers = new List<Id>();
            for (User subordinate : subordinates) {
                currentManagers.add(subordinate.Id);
            }
        }
    
        return allSubordinates;
    }

     public static Set<Id> getAllSubordinates(String roleId) {
        List<String> subordinateRoleIds = new List<String>();
        fetchSubordinateRoles(roleId, subordinateRoleIds);

        if (!subordinateRoleIds.isEmpty()) {
            Map<Id, User> userMap = new Map<Id, User>([SELECT Id, Name, Email FROM User WHERE UserRoleId IN :subordinateRoleIds]);
            return userMap.keySet();
        } else {
            return null;
        }
    }

    private static void fetchSubordinateRoles(String roleId, List<String> subordinateRoleIds) {
        List<UserRole> roles = [SELECT Id FROM UserRole WHERE ParentRoleId = :roleId];
        for (UserRole role : roles) {
            subordinateRoleIds.add(role.Id);
            fetchSubordinateRoles(role.Id, subordinateRoleIds); // Recursive call
        }
    }


    //Inner Class to return result to LWC
    public Class ReturnDataClass{
        @AuraEnabled
        public List<Data> returnDataList { get; set; }
        @AuraEnabled
        public CumulativeData data { get; set; }  
        @AuraEnabled
        public Boolean isManager  { get; set; }
        @AuraEnabled
        public String currencySymbol  { get; set; }
        @AuraEnabled
        public Integer totalRecords  { get; set; }
        
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
        public String AARId { get; set; }
        @AuraEnabled   
        public String Seller { get; set; }
        @AuraEnabled
        public String Advertiser { get; set; } 
        @AuraEnabled
        public String AdvertiserId { get; set; } 
        @AuraEnabled
        public String SOId { get; set; }  
        @AuraEnabled
        public Boolean SOPrimary { get; set; } 
        @AuraEnabled
        public String Agency { get; set; }
        @AuraEnabled
        public String AgencyId { get; set; }
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
        public String SplitOwnerRecId { get; set; }
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
        public String currencyISOCode { get; set; }

        @AuraEnabled
        public Decimal productCumulative { get; set; }

        @AuraEnabled
        public Boolean displayAdd { get; set; } 
        @AuraEnabled
        public Boolean isChanged { get; set; }

        public Forecast() {
            this.displayAdd = false;
            this.isChanged = false;
        }
        
        public Forecast(Forecast f) {
            this.Id = f.Id;
            this.OwnerName = f.OwnerName;
            this.SplitOwnerRecId = f.SplitOwnerRecId;
            this.name = f.name;
            this.q1 = f.q1;
            this.q2 = f.q2;
            this.q3 = f.q3;
            this.q4 = f.q4;
            this.q11 = f.q11;
            this.q21 = f.q21;
            this.q31 = f.q31;
            this.q41 = f.q41;
            this.currencyISOCode = f.currencyISOCode;
            this.productCumulative = f.productCumulative;
            this.displayAdd = f.displayAdd;
            this.isChanged = f.isChanged;
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

        @AuraEnabled
        public Decimal ForecastNextYear { get; set; }

        @AuraEnabled
        public Decimal CYq1 { get; set; }
        @AuraEnabled
        public Decimal CYq2 { get; set; }
        @AuraEnabled
        public Decimal CYq3 { get; set; }
        @AuraEnabled
        public Decimal CYq4 { get; set; }

        @AuraEnabled
        public Decimal ForecastCY { get; set; }

        public CumulativeData() {
            this.BookingsCurrentYear = 0;
            this.BookingsNextYear = 0;
            this.PipelineCurrentQuarter = 0;
            this.PipelineNextQuarter = 0;

            this.q1 = 0;
            this.q2 = 0;
            this.q3 = 0;
            this.q4 = 0;
            this.ForecastNextYear = 0;

            this.CYq1 = 0;
            this.CYq2 = 0;
            this.CYq3 = 0;
            this.CYq4 = 0;
            this.ForecastCY = 0;

        }

    }
    
}