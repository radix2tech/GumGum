public class CampaignMemberHandler {
    public static void getCampaignMembers(List<CampaignMember> lstCmpMem,String operationType) {
        List<CampaignMember> lstCampaignMem = [SELECT Id,LeadId,ContactId,Campaign.Name FROM CampaignMember WHERE ID IN :lstCmpMem]; 
        Map<Id,CampaignMember> leadId2CampignMemMap = new Map<Id,CampaignMember>();
        Map<Id,CampaignMember> contactId2CampignMemMap = new Map<Id,CampaignMember>();
        for(CampaignMember cm :lstCampaignMem){
        	if(cm.ContactId != null){
            	contactId2CampignMemMap.put(cm.ContactId,cm);   
            }
            if(cm.LeadId != null){ 
                leadId2CampignMemMap.put(cm.LeadId,cm);     
            }
        }
        if(operationType == 'INSERT' || operationType == 'UPDATE'){
            // Process Lead Records to update First Marketing Campaign, Most Recent Campaign Member,Date of Most Recent Marketing Campaign
            if(!leadId2CampignMemMap.keySet().isEmpty()){
                updateLeadRecords(leadId2CampignMemMap);    
            }
            // Process Contact Records to update First Marketing Campaign, Most Recent Campaign Member,Date of Most Recent Marketing Campaign
            if(!contactId2CampignMemMap.keySet().isEmpty()){ 
                updateContactRecords(contactId2CampignMemMap);       
            }    
        }
        else if(operationType == 'DELETE'){
            if(!leadId2CampignMemMap.keySet().isEmpty()){
            	updateLeadRecordsAfterDelete(leadId2CampignMemMap);    
            }
            if(!contactId2CampignMemMap.keySet().isEmpty()){
                updateContactRecordsAfterDelete(contactId2CampignMemMap);
            }
            
        }
        else{
            // No action to perform
        }
        
    }
    public static void updateLeadRecords(Map<Id,CampaignMember> leadId2CampignMemMap){
        List<Lead> lstLeads = [SELECT Id,Date_of_Most_Recent_Marketing_Campaign__c,First_Marketing_Campaign__c,Most_Recent_Marketing_Campaign__c FROM Lead WHERE ID IN :leadId2CampignMemMap.keySet()];
        List<Lead> lstLeadToUpdate = new List<Lead>();
        Database.SaveResult[] updateResults;
        for(Lead ld : lstLeads){
            if(ld.First_Marketing_Campaign__c == null || ld.First_Marketing_Campaign__c == ''){
                ld.First_Marketing_Campaign__c 				 = leadId2CampignMemMap.get(ld.Id).Campaign.Name;
                ld.Date_of_Most_Recent_Marketing_Campaign__c = date.today();
                ld.Most_Recent_Marketing_Campaign__c         =  leadId2CampignMemMap.get(ld.Id).Campaign.Name;
                lstLeadToUpdate.add(ld);
            } 
            else{
                ld.Date_of_Most_Recent_Marketing_Campaign__c = date.today();
                ld.Most_Recent_Marketing_Campaign__c         =  leadId2CampignMemMap.get(ld.Id).Campaign.Name;
                lstLeadToUpdate.add(ld);                
            }
        }
        updateResults = Database.update(lstLeadToUpdate, false);
    }
    public static void updateContactRecords(Map<Id,CampaignMember> contactId2CampignMemMap){
        List<Contact> lstContacts = [SELECT Id,Date_of_Most_Recent_Marketing_Campaign__c,First_Marketing_Campaign__c,Most_Recent_Marketing_Campaign__c FROM Contact WHERE ID IN :contactId2CampignMemMap.keySet()];
        List<Contact> lstConToUpdate = new List<Contact>();
        Database.SaveResult[] srList;
        for(Contact con : lstContacts){
            if(con.First_Marketing_Campaign__c == null || con.First_Marketing_Campaign__c == ''){
                con.First_Marketing_Campaign__c = contactId2CampignMemMap.get(con.Id).Campaign.Name;
                con.Date_of_Most_Recent_Marketing_Campaign__c = date.today();
                con.Most_Recent_Marketing_Campaign__c         =  contactId2CampignMemMap.get(con.Id).Campaign.Name;
                lstConToUpdate.add(con);
            } 
            else{
                con.Date_of_Most_Recent_Marketing_Campaign__c = date.today();
                con.Most_Recent_Marketing_Campaign__c         =  contactId2CampignMemMap.get(con.Id).Campaign.Name;
                lstConToUpdate.add(con);                
            }
        }
        srList = Database.update(lstConToUpdate, false);
    }
    public static void updateLeadRecordsAfterDelete(Map<Id,CampaignMember> leadId2CampignMemMap){
   		Map<Id,List<CampaignMember>> mapLeadId2LstCM = new Map<Id,List<CampaignMember>>();
        List<Lead> lstLeadToUpdate = new List<Lead>();
        List<CampaignMember> lstLeadCampaignMem = [SELECT Id,LeadId,Campaign.Name,LastRespondedDateTime__c,FirstRespondedDate FROM CampaignMember WHERE LeadId IN:leadId2CampignMemMap.keySet()  ORDER BY LastRespondedDateTime__c ASC];
        for(CampaignMember cm : lstLeadCampaignMem){
        	if(mapLeadId2LstCM.containsKey(cm.LeadId)) {
            	List<CampaignMember> lstCM = mapLeadId2LstCM.get(cm.LeadId);
                lstCM.add(cm);
                mapLeadId2LstCM.put(cm.LeadId, lstCM);
            }
            else {
                mapLeadId2LstCM.put(cm.LeadId, new List<CampaignMember> { cm });
            }
        }
        List<Lead> lstLeads = [SELECT Id,Date_of_Most_Recent_Marketing_Campaign__c,First_Marketing_Campaign__c,Most_Recent_Marketing_Campaign__c FROM Lead WHERE ID IN :leadId2CampignMemMap.keySet()];
        Database.SaveResult[] updateResults;
        for(Lead ld : lstLeads){
            // If first marketing campaign was deleted
            if(ld.First_Marketing_Campaign__c == leadId2CampignMemMap.get(ld.Id).Campaign.Name){
                if(ld.First_Marketing_Campaign__c == ld.Most_Recent_Marketing_Campaign__c){
                    ld.First_Marketing_Campaign__c = '';
                    ld.Most_Recent_Marketing_Campaign__c = '';
                    ld.Date_of_Most_Recent_Marketing_Campaign__c = NULL;
                }
                else{
                    if(mapLeadId2LstCM.get(ld.Id).size()>0){
                        ld.First_Marketing_Campaign__c = mapLeadId2LstCM.get(ld.Id).get(1).Campaign.Name;  
                    }  
                }
            }
            // If most recent campaign was deleted
            if(ld.Most_Recent_Marketing_Campaign__c == leadId2CampignMemMap.get(ld.Id).Campaign.Name){
                if(mapLeadId2LstCM.get(ld.Id).size() == 2){
                    ld.Most_Recent_Marketing_Campaign__c = ld.First_Marketing_Campaign__c;
                    ld.Date_of_Most_Recent_Marketing_Campaign__c = mapLeadId2LstCM.get(ld.Id).get(0).FirstRespondedDate;
                }
                else if(mapLeadId2LstCM.get(ld.Id).size() >2){
                    integer isize = mapLeadId2LstCM.get(ld.Id).size()-2; 
                    ld.Most_Recent_Marketing_Campaign__c = mapLeadId2LstCM.get(ld.Id).get(isize).Campaign.Name;  
                    ld.Date_of_Most_Recent_Marketing_Campaign__c = mapLeadId2LstCM.get(ld.Id).get(isize).FirstRespondedDate;
                }
            }
            
            lstLeadToUpdate.add(ld);   
        }
        updateResults = Database.update(lstLeadToUpdate, false); 
    }
    public static void updateContactRecordsAfterDelete(Map<Id,CampaignMember> contactId2CampignMemMap){
        Map<Id,List<CampaignMember>> mapContactId2LstCM = new Map<Id,List<CampaignMember>>();
        List<Contact> lstContactToUpdate = new List<Contact>();
        List<CampaignMember> lstContactCampaignMem = [SELECT Id,ContactId,Campaign.Name,LastRespondedDateTime__c,FirstRespondedDate FROM CampaignMember WHERE ContactId IN:contactId2CampignMemMap.keySet()  ORDER BY LastRespondedDateTime__c ASC];
        for(CampaignMember cm : lstContactCampaignMem){
        	if(mapContactId2LstCM.containsKey(cm.ContactId)) {
            	List<CampaignMember> lstCM = mapContactId2LstCM.get(cm.ContactId);
                lstCM.add(cm);
                mapContactId2LstCM.put(cm.ContactId, lstCM);
            }
            else {
                mapContactId2LstCM.put(cm.ContactId, new List<CampaignMember> { cm });
            }
        }
        List<Contact> lstContacts = [SELECT Id,Date_of_Most_Recent_Marketing_Campaign__c,First_Marketing_Campaign__c,Most_Recent_Marketing_Campaign__c FROM Contact WHERE ID IN :contactId2CampignMemMap.keySet()];
        Database.SaveResult[] updateResults;
        for(Contact con : lstContacts){
            // If first marketing campaign was deleted
            if(con.First_Marketing_Campaign__c == contactId2CampignMemMap.get(con.Id).Campaign.Name){
                if(con.First_Marketing_Campaign__c == con.Most_Recent_Marketing_Campaign__c){
                    con.First_Marketing_Campaign__c = '';
                    con.Most_Recent_Marketing_Campaign__c = '';
                    con.Date_of_Most_Recent_Marketing_Campaign__c = NULL;
                }
                else{
                    if(mapContactId2LstCM.get(con.Id).size()>0){
                        con.First_Marketing_Campaign__c = mapContactId2LstCM.get(con.Id).get(1).Campaign.Name;  
                    }  
                }
            }
            // If most recent campaign was deleted
            if(con.Most_Recent_Marketing_Campaign__c == contactId2CampignMemMap.get(con.Id).Campaign.Name){
                if(mapContactId2LstCM.get(con.Id).size() == 2){
                    con.Most_Recent_Marketing_Campaign__c = con.First_Marketing_Campaign__c;
                    con.Date_of_Most_Recent_Marketing_Campaign__c = mapContactId2LstCM.get(con.Id).get(0).FirstRespondedDate;
                }
                else if(mapContactId2LstCM.get(con.Id).size() >2){
                    integer isize = mapContactId2LstCM.get(con.Id).size()-2; 
                    con.Most_Recent_Marketing_Campaign__c = mapContactId2LstCM.get(con.Id).get(isize).Campaign.Name;  
                    con.Date_of_Most_Recent_Marketing_Campaign__c = mapContactId2LstCM.get(con.Id).get(isize).FirstRespondedDate;
                }
            }
            
            lstContactToUpdate.add(con);    
        }
        updateResults = Database.update(lstContactToUpdate, false); 
    }
}