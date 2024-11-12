public class CampiagnMember_TrgHelper {
    public static void addAccountJunctionToCampaign(Map<id,set<id>> newCampMembers,set<id> campaignIdsWhereMemberRemoved, String oprName){
		map<id,set<id>> survivingAcct=new map<id,set<id>>();
        map<id,set<id>> survivingCampMemberContactList=new map<id,set<id>>();
        set<id> allContacts=new set<id> ();
        List<Client_team__c> accForAllContactsList;
        map<id,set<id>> contactAccList=new map<id,set<id>>();
        Map<id,List<Account_Campaign_Junction__c>> allAccCampJunObjList=new map<id,list<Account_Campaign_Junction__c>>();
        List<Account_Campaign_Junction__c> toBeDeletedAccCampJuncObj=new list<Account_Campaign_Junction__c>();
        System.debug('In CampiagnMember_TrgHelper(newCampMembers): '+newCampMembers);
        System.debug('In CampiagnMember_TrgHelper(campaignIdsWhereMemberRemoved): '+campaignIdsWhereMemberRemoved);
        System.debug('In CampiagnMember_TrgHelper(oprName): '+oprName);
        //remove logic..query all the surviving account, and delete the non surviving ones
        try{
            if(!campaignIdsWhereMemberRemoved.isEmpty()){
                System.debug('In Delete operation(campaignIdsWhereMemberRemoved): '+ campaignIdsWhereMemberRemoved);
                //get all the contacts for the survising campaign members
                for(CampaignMember c: [select id,campaignId,contactId from campaignmember where campaignid in :campaignIdsWhereMemberRemoved
                                      and status='Attended' and Campaign.recordtypeid='0120P0000001uCUQAY']){if(survivingCampMemberContactList.get(c.CampaignId)!=null){ survivingCampMemberContactList.get(c.CampaignId).add(c.ContactId);}else{ survivingCampMemberContactList.put(c.CampaignId,new set<id>{c.ContactId});}
                    allContacts.add(c.ContactId);
                }
                System.debug('In Delete operation(allContacts): '+ allContacts);
                //populate contact account list
                accForAllContactsList=[select id,name,client_account__c,agent__c from client_team__c where agent__c in :allContacts];
                for(Client_team__c rec: accForAllContactsList){
                    if(contactAccList.get(rec.agent__c)!=null){contactAccList.get(rec.agent__c).add(rec.client_account__c);      }else{contactAccList.put(rec.agent__c,new set<id>{rec.client_account__c}); }}
                System.debug('In Delete operation(contactAccList): '+ contactAccList);
                System.debug('In Delete operation(survivingCampMemberContactList): '+ survivingCampMemberContactList);
                //populate all survicing account list
                set<id> tempAcctList=new set<id>();
                if(survivingCampMemberContactList!=null){
                    for(Id campnId: survivingCampMemberContactList.keySet()){
                        for(Id conctId: survivingCampMemberContactList.get(campnId)){
                            if(contactAccList!=null && contactAccList.get(conctId)!=null){
                            	tempAcctList.addAll(contactAccList.get(conctId));
                            }
                        }
                        System.debug('I am here 400');
                        survivingAcct.put(campnId,tempAcctList);
                    }
                }
                System.debug('In Delete operation(survivingAcct): '+ survivingAcct);
                for(Account_Campaign_Junction__c rec: [select id,Account__c,Campaign__c,name from Account_Campaign_Junction__c where Campaign__c in :campaignIdsWhereMemberRemoved]){
                    /*if(allAccCampJunObjList.get(rec.Campaign__c)!=null){
                        allAccCampJunObjList.get(rec.Campaign__c).add(rec);
                    }else{
                        allAccCampJunObjList.put(rec.Campaign__c,new list<Account_Campaign_Junction__c>{rec});
                    }*/
                    if(survivingAcct.get(rec.Campaign__c)==null){                        
                        toBeDeletedAccCampJuncObj.add(rec);
                    }else if(!survivingAcct.get(rec.Campaign__c).Contains(rec.Account__c)){toBeDeletedAccCampJuncObj.add(rec);}}
                System.debug('toBeDeletedAccCampJuncObj: '+ toBeDeletedAccCampJuncObj);
                if(toBeDeletedAccCampJuncObj!=null && toBeDeletedAccCampJuncObj.size()>0){
                    delete toBeDeletedAccCampJuncObj;
                }
            }
            
            
            //Add Logic
            //select all account for the contact
            //select all the existing account in junction object
            //insert a new one if the account does not exists
            if(!newCampMembers.isEmpty()){
                system.debug('I am in insert(newCampMembers): '+ newCampMembers);
                for(id campgnId: newCampMembers.keySet()){
                    allContacts.addAll(newCampMembers.get(campgnId));
                }
                accForAllContactsList=[select id,name,client_account__c,agent__c from client_team__c where agent__c in :allContacts];
                for(Client_team__c rec: accForAllContactsList){
                    if(contactAccList.get(rec.agent__c)!=null){
                        contactAccList.get(rec.agent__c).add(rec.client_account__c);
                    }else{
                        contactAccList.put(rec.agent__c,new set<id>{rec.client_account__c});
                    }
                }
                system.debug('I am in insert(contactAccList): '+ contactAccList);
                Map<id,set<id>> allAccCampJunObj=new map<id,set<id>>();
                List<Account_Campaign_Junction__c> toBeInsertedAccCampJuncObjList=new list<Account_Campaign_Junction__c>();
                for(Account_Campaign_Junction__c rec: [select id,Account__c,Campaign__c,name from Account_Campaign_Junction__c where Campaign__c in :newCampMembers.keySet()]){
                    if(allAccCampJunObj.get(rec.Campaign__c)!=null){allAccCampJunObj.get(rec.Campaign__c).add(rec.Account__c);}else{ allAccCampJunObj.put(rec.Campaign__c,new set<id>{rec.Account__c});}
                }
                system.debug('I am in insert(allAccCampJunObj): '+ allAccCampJunObj);
                for(id campgnId: newCampMembers.keySet()){
                    system.debug('I am in insert(100)');
                    for(id cntctId: newCampMembers.get(campgnId)){
                        system.debug('I am in insert(200)');
                        if(contactAccList!=null){
                            for(id actId: contactAccList.get(cntctId)){
                                system.debug('I am in insert(300)');
                                if(allAccCampJunObj!=null){
                                    if(allAccCampJunObj.get(campgnId)!=null && allAccCampJunObj.get(campgnId).contains(actId)){
                                        continue;
                                    }else{
                                        toBeInsertedAccCampJuncObjList.add(new Account_Campaign_Junction__c(Account__c=actId,Campaign__c=campgnId));
                                    }
                                }else{
                                    toBeInsertedAccCampJuncObjList.add(new Account_Campaign_Junction__c(Account__c=actId,Campaign__c=campgnId)); 
                                }}}}}
                System.debug('toBeInsertedAccCampJuncObjList: '+ toBeInsertedAccCampJuncObjList);
                if(toBeInsertedAccCampJuncObjList!=null && toBeInsertedAccCampJuncObjList.size()>0){
                    insert toBeInsertedAccCampJuncObjList;
                }                
            }

		}catch(Exception e){System.debug('In Exception CampiagnMember_TrgHelper: '+ e);	}	}}