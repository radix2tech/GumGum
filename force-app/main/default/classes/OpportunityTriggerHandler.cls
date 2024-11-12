/**
Class Name - OpportunityTriggerHandler
Description - Class called from trigger 'OpportunityTrigger' to fetch the Targeting and GeoTargeting records of Opportunity on cloning

Method Name - cloneRelatedRecords
Description - Future methods fetch all the Targeting and Geotargeting records from parent Opportunity and insert with child Opportunity 
              if Origional Opportunity Id is not equal to null
**/

public with sharing class OpportunityTriggerHandler{

@future
public static void cloneRelatedRecords(Set<Id> setOfOppID){

List<Targeting__c> listOfTargeting = new List<Targeting__c>();
List<Targeting__c> newListofTargeting;
List<Geo_Targeting__c> listOfGeoTargeting = new List<Geo_Targeting__c>();
List<Geo_Targeting__c> newListOfGeoTargeting;
Map<String,String> mapOforiOppIdWithOppId = new Map<String,String>();
Set<String> oriOppId = new Set<String>();
List<Opportunity> updatedOppId = new List<Opportunity>();

List<Opportunity> listOfOpp = [Select ID,Original_Opportunity_Id__c from Opportunity where Id in: setOfOppID];

for(Opportunity o : listOfOpp )
{
    mapOforiOppIdWithOppId.put(o.Original_Opportunity_Id__c,o.id );
    
    oriOppId.add(o.Original_Opportunity_Id__c);
}

if(!oriOppId.isempty() && !oriOppId.contains(null))
{
    
    listOfTargeting =[Select Name,Behavioral__c,Count__c,Custom_Description__c,Description__c,Event__c,Keywords__c,Type__c,Vertical__c,Insertion_Order__c from Targeting__c where Insertion_Order__c in: oriOppId];
    listOfGeoTargeting =[select Name,Campaign_City__c,Campaign_Country__c,Campaign_DMA__c,Campaign_State_Province__c,Campaign_Zip_Code__c,Opportunity__c from Geo_Targeting__c where Opportunity__c in: oriOppId];
    
}

if(!listOfTargeting.isempty() && listOfTargeting != null)
{
    Map<String,List<Targeting__c>> mapOfOidWithTid = new Map<String,List<Targeting__c>>();
    newListofTargeting = new List<Targeting__c>();
    for(Targeting__c target : ListOfTargeting )
    {
        if(mapOfOidWithTid.containskey(target.Insertion_Order__c))
        {
            mapOfOidWithTid.get(target.Insertion_Order__c).add(target);
        }
        else
        {
            mapOfOidWithTid.put(target.Insertion_Order__c,new List<Targeting__c>{target});
        }
    }
    
    for(String s : mapOfOidWithTid.keySet())
    {
        for(Targeting__c t : mapOfOidWithTid.get(s))
        {
            Targeting__c targetNew = t.clone();
            targetnew.Insertion_Order__c = mapOforiOppIdWithOppId.get(s.substring(0, 15));            
            newListofTargeting.add(targetNew);
        }
    }
    
    try
    {
        insert newListofTargeting;
    }
    catch(Exception e)
    {
        for(Opportunity opp : listOfOpp)
        {
            opp.addError('The following error occured' + e);
        }
        
    }

}

if(!listOfGeoTargeting.isempty() && listOfGeoTargeting != null)
{
    Map<String,List<Geo_Targeting__c >> mapOfOidWithGtid = new Map<String,List<Geo_Targeting__c >>();
    newListOfGeoTargeting = new List<Geo_Targeting__c >();
    for(Geo_Targeting__c gTarget : listOfGeoTargeting)
    {
        if(mapOfOidWithGtid.containskey(gtarget.Opportunity__c ))
        {
            mapOfOidWithGtid.get(gTarget.Opportunity__c ).add(gTarget);
        }
        else
        {
            mapOfOidWithGtid.put(gTarget.Opportunity__c ,new List<Geo_Targeting__c >{gTarget});
        }
    }
    
    for(String s : mapOfOidWithGtid.keySet())
    {
        for(Geo_Targeting__c gt : mapOfOidWithGtid.get(s))
        {
            Geo_Targeting__c gTargetNew = gt.clone();
            gTargetnew.Opportunity__c = mapOforiOppIdWithOppId.get(s.substring(0, 15));
            newListOfGeoTargeting .add(gTargetNew);
        }
    }
    
    try
    {
        insert newListOfGeoTargeting ;
    }
    catch(Exception e)
    {
        for(Opportunity opp : listOfOpp)
        {
            opp.addError('The following error occured' + e);
        }
        
    }

}


for(Opportunity opp : listOfOpp )
{
    opp.Original_Opportunity_Id__c = string.valueof(opp.Id).substring(0, 15);
    updatedOppId.add(opp);

}
try
{
    Update updatedOppId ;
}
catch(Exception e)
{
    for(Opportunity opp : listOfOpp)
    {
        opp.addError('The following error occured' + e);
    }
    
}
}

//this method sets the Pricebook on Opportunity at the time of insert
// Commenting the below code as we are handling the below logic from flow.
/*public static void setPricebookOnOppty(List<Opportunity> newOpptyList){
   //Sports Record type Id
   Id sportsRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Sports').getRecordTypeId();
   //Advertising record type Id
   Id adRecTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Advertising').getRecordTypeId();
   
   Id sportsPBId, adPBId, stdPBId;
   
   List<Pricebook2> pbList = new List<Pricebook2>([Select Id, Name From Pricebook2]);
   
   if(pbList.size() > 0){
      for(Pricebook2 pb :pbList){
         if(pb.Name == 'Sports Opportunity'){
            sportsPBId = pb.Id;
         } else if(pb.Name == 'Advertising Opportunity'){
            adPBId = pb.Id;
         } else if(pb.Name == 'Standard Price Book'){
            stdPBId = pb.Id;
         }
      }
   }
   
   //setting Pricebook on Opportunity
   for(Opportunity o :newOpptyList){
      if(o.RecordTypeId == sportsRecTypeId){
         o.Pricebook2Id = sportsPBId;
      } else if(o.RecordTypeId == adRecTypeId){
         o.Pricebook2Id = adPBId;
      } else{
         o.Pricebook2Id = stdPBId;
      } 
   }
} */

}