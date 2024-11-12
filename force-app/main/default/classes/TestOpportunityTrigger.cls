/**
Class Name - TestOpportunityTrigger
Description - Test class for OpportunityTrigger

Method Name - testMethod1
Description - Testing to insert Opportunity which does not have Original Opportunity Id and then adding Targeting and Geotargeting 
              with that and again insert opportunity having riginal Opportunity Id same as first.
              
Method Name - testMethod2
Description - Testing to insert Opportunity with Original Opportunity Id with Opportunity Id having more than 1 Targeting and Geotargeting.              .
**/

@isTest
Public class TestOpportunityTrigger{

static testMethod void testMethod1() {
    Test.startTest();
    
    Account testAcc = new Account(name = 'TestAcc');
    insert testAcc;
        
    Opportunity opp1 = new Opportunity(AccountId= testAcc.id,Agency_Name__c=testAcc.id,Start_Date__c = System.Today(),End_Date__c =System.Today()+ 100 ,name = 'Test Opp1',CloseDate= System.Today()+ 3 , StageName ='Initial call' );  
    insert opp1;
    
    Targeting__c target = new Targeting__c(Name='Test Target',Insertion_Order__c = opp1.id);
    insert target;
    
    Geo_Targeting__c geo = new Geo_Targeting__c(Name='Test GeoTarget',Opportunity__c=opp1.id);
    insert geo;
    
    string originalOpp = string.valueof(opp1.id).substring(0, 15);
    
    Opportunity opp2 = new Opportunity(AccountId= testAcc.id,Agency_Name__c=testAcc.id,Start_Date__c = System.Today(),End_Date__c =System.Today()+ 100 ,name = 'Test Opp2',CloseDate= System.Today()+ 3 , StageName ='Initial call',Original_Opportunity_Id__c= originalOpp );
    insert opp2;
    
    Test.stopTest();
    
    Opportunity testOpp = [select id,Original_Opportunity_Id__c from Opportunity where id =:opp2.id];
    
    List<Targeting__c > listOfTarget = new List<Targeting__c >();
    List<Geo_Targeting__c > listOfGeoTarget = new List<Geo_Targeting__c >();
    
    listOfTarget  = [select id from Targeting__c where Insertion_Order__c =: testOpp.Original_Opportunity_Id__c ];
    listOfGeoTarget  = [select id from Geo_Targeting__c where Opportunity__c =: testOpp.Original_Opportunity_Id__c ];
    
    System.assertEquals(listOfTarget.size(),1); 
    System.assertEquals(listOfGeoTarget.size(),1); 

}

static testMethod void testMethod2() {
    Test.startTest();
    
    Account testAcc = new Account(name = 'TestAcc');
    insert testAcc;
        
    Opportunity opp1 = new Opportunity(AccountId= testAcc.id,Agency_Name__c=testAcc.id,Start_Date__c = System.Today(),End_Date__c =System.Today()+ 100 ,name = 'Test Opp1',CloseDate= System.Today()+ 3 , StageName ='Initial call' );  
    insert opp1;
    
    Targeting__c target1 = new Targeting__c(Name='Test Target1',Insertion_Order__c = opp1.id);
    insert target1;
    
    Targeting__c target2 = new Targeting__c(Name='Test Target2',Insertion_Order__c = opp1.id);
    insert target2;
    
    Geo_Targeting__c geo1 = new Geo_Targeting__c(Name='Test GeoTarget1',Opportunity__c=opp1.id);
    insert geo1;
    
    Geo_Targeting__c geo2 = new Geo_Targeting__c(Name='Test GeoTarget2',Opportunity__c=opp1.id);
    insert geo2;
    
    string originalOpp = string.valueof(opp1.id).substring(0, 15);
    
    Opportunity opp2 = new Opportunity(AccountId= testAcc.id,Agency_Name__c=testAcc.id,Start_Date__c = System.Today(),End_Date__c =System.Today()+ 100 ,name = 'Test Opp2',CloseDate= System.Today()+ 3 , StageName ='Initial call',Original_Opportunity_Id__c= originalOpp );
    insert opp2;
    
    Test.stopTest();
    
    List<Targeting__c > listOfTarget = new List<Targeting__c >();
    List<Geo_Targeting__c > listOfGeoTarget = new List<Geo_Targeting__c >();
    
    listOfTarget  = [select id from Targeting__c where Insertion_Order__c =: opp2.id];
    listOfGeoTarget  = [select id from Geo_Targeting__c where Opportunity__c =: opp2.id];
    
    System.assertEquals(listOfTarget.size(),2); 
    System.assertEquals(listOfGeoTarget.size(),2); 

}
   
   //this method provides coverage to setPricebookOnOppty() method in OpportunityTriggerHandler
 /*  static testMethod void testSetPBOnOppty() {
      //Sports Record type Id
      Id sportsRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sports').getRecordTypeId();
      //Advertising record type Id
      Id adRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Advertising').getRecordTypeId();
      //Dental record type Id
      Id denRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Dental').getRecordTypeId();
      
      List<Pricebook2> pbList = new List<Pricebook2>();
      
      Pricebook2 sportsPB = new Pricebook2(Name = 'Sports Opportunity');
      pbList.add(sportsPB); 
      
      Pricebook2 adPB = new Pricebook2(Name = 'Advertising Opportunity');
      pbList.add(adPB); 
      
      Id stdPBId = Test.getStandardPricebookId();
      
      Account testAcc = new Account(name = 'TestAcc');
      insert testAcc;
        
      Opportunity opp1 = new Opportunity(AccountId= testAcc.id,Agency_Name__c=testAcc.id,Start_Date__c = System.Today(),End_Date__c =System.Today()+ 100 ,name = 'Test Opp1',CloseDate= System.Today()+ 3 , StageName ='Initial call', RecordTypeId = sportsRecTypeId);  
      Opportunity opp2 = new Opportunity(AccountId= testAcc.id,Agency_Name__c=testAcc.id,Start_Date__c = System.Today(),End_Date__c =System.Today()+ 100 ,name = 'Test Opp2',CloseDate= System.Today()+ 3 , StageName ='Initial call', RecordTypeId = adRecTypeId );  
      Opportunity opp3 = new Opportunity(AccountId= testAcc.id,Agency_Name__c=testAcc.id,Start_Date__c = System.Today(),End_Date__c =System.Today()+ 100 ,name = 'Test Opp3',CloseDate= System.Today()+ 3 , StageName ='Initial call', RecordTypeId = denRecTypeId );  
      
      List<Opportunity> oppList = new List<Opportunity>();
      oppList.add(opp1);
      oppList.add(opp2);
      oppList.add(opp3);
      
      Test.startTest();
      
      insert pbList;
      insert oppList;
      
      Test.stopTest();
      
      List<Opportunity> oList = new List<Opportunity>([Select Id, RecordTypeId, Pricebook2Id From Opportunity]);
      for(Opportunity o :oList){
         if(o.RecordTypeId == sportsRecTypeId){
            system.assertEquals(o.Pricebook2Id, sportsPB.Id);
         } else if(o.RecordTypeId == adRecTypeId){
            system.assertEquals(o.Pricebook2Id, adPB.Id);
         }else{
            system.assertEquals(o.Pricebook2Id, stdPBId);
         }
      }
   }*/

}