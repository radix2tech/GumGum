trigger trg_Client_Team on Client_Team__c (after insert,after delete) {
    System.debug('In trg_Client_Team Trigger');
    Map<id,set<id>> newCampMembers=new Map<id,set<id>> ();//campgnid, contactlist
    //Map<id,List<id>> removedCampMembers=new Map<id,List<id>> ();
    set<id> removedCampaignIds=new set<id>();
    String oprName='';
    If(Trigger.isInsert){
        system.debug('In Insert');
        oprName='Insert';
        for(campaignmember rec :[select id,campaignId,campaign.recordtypeid,contactId 
                                 from campaignmember 
                                 where contactId in (select agent__c from client_team__c where id in :trigger.newMap.keySet())
                                 and campaign.recordtypeid='0120P0000001uCUQAY'
                                 and Status='Attended']
           ){
               if(newCampMembers.get(rec.CampaignId)!=null){
                   newCampMembers.get(rec.CampaignId).add(rec.ContactId);
               }else{
                   newCampMembers.put(rec.CampaignId,new set<id>{rec.ContactId});
               }                            
        }
    }
    
    If(Trigger.isDelete){
        system.debug('In Delete'+trigger.oldMap);
        System.debug('trigger.oldMap.keySet(): '+ trigger.oldMap.keySet());        
        oprName='Delete';
        Set<id> deletedContactId=new set<id>();
        for(Client_team__c rec: Trigger.old){
            deletedContactId.add(rec.agent__c);
        }
        System.debug('deletedContactId: '+deletedContactId);
        for(campaignmember rec :[select id,campaignId,campaign.recordtypeid,contactId
                                 from campaignmember 
                                 where contactId in :deletedContactId
                                 and campaign.recordtypeid='0120P0000001uCUQAY'
                                 and status='Attended']
           ){
                if(rec.contactid!=null){
                    removedCampaignIds.add(rec.CampaignId);
                }               
        }        
    }
    System.debug('In trg_Client_Team Trigger(newCampMembers):'+newCampMembers);
    System.debug('In trg_Client_Team Trigger(removedCampaignIds):'+removedCampaignIds);
    System.debug('In trg_Client_Team Trigger(oprName):'+oprName);
    CampiagnMember_TrgHelper.addAccountJunctionToCampaign(newCampMembers,removedCampaignIds,oprName);
    System.debug('In trg_Client_Team Trigger end');
}