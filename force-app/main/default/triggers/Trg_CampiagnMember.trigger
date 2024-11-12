trigger Trg_CampiagnMember on CampaignMember (after insert,after delete,after update) {
    System.debug('In Trg_CampiagnMember Trigger');
    Map<id,set<id>> newCampMembers=new Map<id,set<id>> ();
    //Map<id,List<id>> removedCampMembers=new Map<id,List<id>> ();
    set<id> removedCampaignIds=new set<id>();
    //List<CampaignMember> removedCampMembers=new list<CampaignMember>();
    CampaignMember tCampMember;
    map<id,id> campaignRecordTypeIdList=new map<id,id>();
    set<id> campId=new set<id>();
    String oprName='';
    if(Trigger.isAfter){
        if(Trigger.IsInsert ){
            System.debug('In Trg_CampiagnMember Trigger: in insert');
            for(CampaignMember rec: Trigger.new){
               campId.add(rec.campaignid); 
            }
            for(campaign rec:[select id,recordtypeid from campaign where id in :campId]){
                campaignRecordTypeIdList.put(rec.id, rec.recordtypeid);
            }
            system.debug('campaignRecordTypeIdList: '+campaignRecordTypeIdList);
            for(CampaignMember rec: Trigger.new){
                System.debug('In Trg_CampiagnMember Trigger(rec.Status): '+rec.Status);
                System.debug('In Trg_CampiagnMember Trigger(rec.ContactId): '+ rec.ContactId);
                System.debug('In Trg_CampiagnMember Trigger(campaignRecordTypeIdList.get(rec.campaignid)==0120P0000001uCUQAY): '+ (campaignRecordTypeIdList.get(rec.campaignid)=='0120P0000001uCUQAY'));
                system.debug(rec.ContactId!=null && campaignRecordTypeIdList.get(rec.campaignid)=='0120P0000001uCUQAY' && rec.Status=='Attended');
                if(rec.ContactId!=null && campaignRecordTypeIdList.get(rec.campaignid)=='0120P0000001uCUQAY' && rec.Status=='Attended'){
                    if(newCampMembers.get(rec.CampaignId)!=null){
                        newCampMembers.get(rec.CampaignId).add(rec.ContactId);
                    }else{
                        newCampMembers.put(rec.CampaignId,new set<id>{rec.ContactId});
                    }
                }
            }
            oprName='Insert';
        }else if(Trigger.IsDelete ){
            System.debug('In Trg_CampiagnMember Trigger: in delete');
            for(CampaignMember rec: Trigger.old){
               campId.add(rec.campaignid); 
            }
            for(campaign rec:[select id,recordtypeid from campaign where id in :campId]){
                campaignRecordTypeIdList.put(rec.id, rec.recordtypeid);
            }            
            for(CampaignMember rec: Trigger.Old){
                System.debug('In Trg_CampiagnMember Trigger: in Delete(rec):'+ rec);
                if(rec.contactid!=null&& campaignRecordTypeIdList.get(rec.campaignid)=='0120P0000001uCUQAY' && rec.Status=='Attended'){
                    /*if(removedCampMembers.get(rec.CampaignId)!=null){
                        removedCampMembers.get(rec.CampaignId).add(rec.ContactId);
                    }else{
                        removedCampMembers.put(rec.CampaignId,new list<id>{rec.ContactId});
                    }*/
                    removedCampaignIds.add(rec.CampaignId);
                }
            }
            oprName='Delete';
        }else if(Trigger.IsUpdate ){
            for(CampaignMember rec: Trigger.old){
               campId.add(rec.campaignid); 
            }
            for(CampaignMember rec: Trigger.new){
               campId.add(rec.campaignid); 
            }            
            for(campaign rec:[select id,recordtypeid from campaign where id in :campId]){
                campaignRecordTypeIdList.put(rec.id, rec.recordtypeid);
            } 
            for(CampaignMember rec: Trigger.New){
                tCampMember=Trigger.oldMap.get(rec.Id);
                if(rec.status!= tCampMember.status && campaignRecordTypeIdList.get(rec.campaignid)=='0120P0000001uCUQAY'){
                    if(rec.contactid!=null && rec.Status=='Attended'){
                        //newCampMembers.add(rec);
                        if(newCampMembers.get(rec.CampaignId)!=null){
                            newCampMembers.get(rec.CampaignId).add(rec.ContactId);
                        }else{
                            newCampMembers.put(rec.CampaignId,new set<id>{rec.ContactId});
                        }
                    }
                    if(tCampMember.contactid!=null && tCampMember.Status=='Attended'){
                        //removedCampMembers.add(tCampMember);
                        removedCampaignIds.add(rec.CampaignId);
                        /*if(removedCampMembers.get(tCampMember.CampaignId)!=null){
                            removedCampMembers.get(tCampMember.CampaignId).add(tCampMember.ContactId);
                        }else{
                            removedCampMembers.put(tCampMember.CampaignId,new set<id>{tCampMember.ContactId});
                        }*/                        
                    }
                }
            }
            oprName='Update';
        }  
        System.debug('In Trg_CampiagnMember Trigger(newCampMembers):'+newCampMembers);
        System.debug('In Trg_CampiagnMember Trigger(removedCampaignIds):'+removedCampaignIds);
        System.debug('In Trg_CampiagnMember Trigger(oprName):'+oprName);
        CampiagnMember_TrgHelper.addAccountJunctionToCampaign(newCampMembers,removedCampaignIds,oprName);
        System.debug('In Trg_CampiagnMember Trigger end');
    }
}