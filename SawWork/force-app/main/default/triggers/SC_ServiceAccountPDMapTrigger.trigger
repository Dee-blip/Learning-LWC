/*---------------------------------------------------------------------------------
* Trigger Name         : SC_ServiceAccountPDMapTrigger
* Developer Name       : Vikas Rudrappa
* Date                 : 06th Apr,2021
* JIRA                 : ESESP-4953
* Test Class           : SC_PolicyDomain_Test 

* HISTORY
* Name          Date            Comments
* Vikas         06-Apr-2021     Delete the Authorized Contacts which belongs to the Service Account which were removed
* Tejaswini     29-Apr-2021     Before Inserting or Updating the Record check if the same combination of record already present & account can't be set as Service account
---------------------------------------------------------------------------------*/ 
trigger SC_ServiceAccountPDMapTrigger on Service_Account_PD_Mapping__c (before insert,before update,before delete, after delete) {
    
    List<Id> lstPdId = new List<Id>();
    Map<Id,Id> mapPdIdAccId= new Map<Id,Id>();
    Map<Id, String> sValidAccTitleMap = new Map<Id, String>();
    Map<Id, String> sValidAccTeamRoleMap = new Map<Id, String>();
    List<Service_Account_PD_Mapping__c> serviceAccPdList = new List<Service_Account_PD_Mapping__c>();
    
    //Fetch the Custom metadata "SC SOC Passphrase Access"
    SC_SOC_Passphrase_Access__mdt lSOCPDAccess = [Select id, Account_Team_title__c, ProfileId__c, User_Title__c from SC_SOC_Passphrase_Access__mdt where DeveloperName =:'PD_Access' limit 1]; 
    Boolean hasAccess = false;
    
    if(lSOCPDAccess != null)
    {
        //Check if the logged in User has the "profile" specified in the custom metadata
        if(lSOCPDAccess.ProfileId__c.contains(UserInfo.getProfileId()))
            hasAccess = true;
        //Check if the logged in User has the "title" specified in the custom metadata
        if(!hasAccess)
        {
            String userTitle = [Select Title from User where id =:UserInfo.getUserId()].Title;
            if(!String.isBlank(userTitle))
            {
                if(userTitle.containsIgnoreCase(lSOCPDAccess.User_Title__c))
                    hasAccess = true;
            }
        }
    }
    
    if(Trigger.IsBefore){
        
    if(Trigger.isInsert || Trigger.isUpdate){
        //List<Id> lstPdId = new List<Id>();
        serviceAccPdList = Trigger.New;
        for(Service_Account_PD_Mapping__c newRec: Trigger.new){
            if(Trigger.isInsert){
                lstPdId.add(newRec.Policy_Domain__c);
            }           
            if(Trigger.isUpdate && Trigger.oldMap.get(newRec.Id).Service_Account__c != newRec.Service_Account__c){
                lstPdId.add(newRec.Policy_Domain__c);
            }
        }
        if(lstPdId.size()>0){
            List<Policy_Domain__c> lstPd = [Select Id,Account_Name__c from Policy_Domain__c where Id in :lstPdId];
            //Map<Id,Id> mapPdIdAccId= new Map<Id,Id>();
            for(Policy_Domain__c pd:lstPd){
                mapPdIdAccId.put(pd.Id,pd.Account_Name__c);
            }
            for(Service_Account_PD_Mapping__c rec: Trigger.new){
                if(mapPdIdAccId.get(rec.Policy_Domain__c)==rec.Service_Account__c){
                    rec.addError('Service Account cannot be same as Account of Policy Domain');
                }
            }
            
            List<Service_Account_PD_Mapping__c> lstSerAccountPdMap = [Select Id,Policy_Domain__c,Service_Account__c from Service_Account_PD_Mapping__c where Policy_Domain__c in :lstPdId];
            Map<Id,List<Id>> mapPdIdSerAccIds= new Map<Id,List<Id>>();
            
            for(Service_Account_PD_Mapping__c rec:lstSerAccountPdMap){
                if(mapPdIdSerAccIds.containsKey(rec.Policy_Domain__c)) {
                    List<Id> lServiceAccId = mapPdIdSerAccIds.get(rec.Policy_Domain__c);
                    lServiceAccId.add(rec.Service_Account__c);
                    mapPdIdSerAccIds.put(rec.Policy_Domain__c, lServiceAccId);
                } 
                else 
                {
                    mapPdIdSerAccIds.put(rec.Policy_Domain__c, new List<Id> { rec.Service_Account__c });
                }
                
            }
            
            if(mapPdIdSerAccIds.size()>0){
                for(Service_Account_PD_Mapping__c rec: Trigger.new){
                    system.debug('rec : '+rec);
                    system.debug('mapPdIdSerAccIds : '+mapPdIdSerAccIds.get(rec.Policy_Domain__c));
                    if(mapPdIdSerAccIds.get(rec.Policy_Domain__c) != null && (mapPdIdSerAccIds.get(rec.Policy_Domain__c)).contains(rec.Service_Account__c)){
                        rec.addError('Service Account already exists for the PD');             
                    }
                }
            }            
        }        
    }
        if(Trigger.IsDelete){
             serviceAccPdList = Trigger.Old;
			for(Service_Account_PD_Mapping__c newRec: Trigger.Old){
				lstPdId.add(newRec.Policy_Domain__c);
                
			}
            if(lstPdId.size()>0){
            	List<Policy_Domain__c> lstPd = [Select Id,Account_Name__c from Policy_Domain__c where Id in :lstPdId];
            	//Map<Id,Id> mapPdIdAccId= new Map<Id,Id>();
            	for(Policy_Domain__c pd:lstPd){
                	mapPdIdAccId.put(pd.Id,pd.Account_Name__c);
                    
            	}
			}
        }
  }
    
   if(!hasAccess)
    {
        if(mapPdIdAccId != null && mapPdIdAccId.keySet().size() > 0){
            List<AccountTeamMember> lValidAccTeamMem = [SELECT Id, AccountID, Title, TeamMemberRole FROM AccountTeamMember where AccountID IN :mapPdIdAccId.values() and UserId = :UserInfo.getUserId() and TeamMemberRole IN('Security Services - Primary','Services - Primary','Services - Secondary')]; 
            for(AccountTeamMember eachrec : lValidAccTeamMem)
            {
                sValidAccTitleMap.put(eachrec.AccountID, eachrec.Title);
                sValidAccTeamRoleMap.put(eachrec.AccountID, eachrec.TeamMemberRole);
            }
            for(Service_Account_PD_Mapping__c eachRec: serviceAccPdList)
            {
                if(sValidAccTeamRoleMap != null && sValidAccTeamRoleMap.keySet().size() > 0)
                {
                    //Check if current user is an Account Team members with roles specified
                    if(sValidAccTeamRoleMap.get(mapPdIdAccId.get(eachRec.Policy_Domain__c)) == 'Security Services - Primary')
                        hasAccess = true;
                    else if(sValidAccTeamRoleMap.get(mapPdIdAccId.get(eachRec.Policy_Domain__c)) == 'Services - Primary' || sValidAccTeamRoleMap.get(mapPdIdAccId.get(eachRec.Policy_Domain__c)) == 'Services - Secondary')
                    {
                        if(sValidAccTitleMap != null && sValidAccTitleMap.keySet().size() > 0 && sValidAccTitleMap.get(mapPdIdAccId.get(eachRec.Policy_Domain__c)) != null)
                            if(lSOCPDAccess.Account_Team_title__c.containsIgnoreCase(sValidAccTitleMap.get(mapPdIdAccId.get(eachRec.Policy_Domain__c))))
                                hasAccess = true;
                    }
                }
                if(!hasAccess)
                    eachRec.addError('Insufficient Privileges');
            }
        }
    }
    if(Trigger.isAfter && Trigger.isDelete){
        List<Id> deletedServiceAccountPDIdList = new List<Id>();
        List<Id> deletedServiceAccountIdList = new List<Id>();
        for(Service_Account_PD_Mapping__c eachRec : Trigger.old){
            deletedServiceAccountPDIdList.add(eachRec.Policy_Domain__c);
            deletedServiceAccountIdList.add(eachRec.Service_Account__c);
        }
        //Delete the Authrized Contacts which belongs to the Service Account which were changed
        List<Authorized_Contact__c> lDelAuthContacts = [Select Id, Policy_Domain__c, Service__c from Authorized_Contact__c where (Policy_Domain__c IN :deletedServiceAccountPDIdList and Service__c = true and Contact_Name__r.AccountId IN :deletedServiceAccountIdList)];
        if(lDelAuthContacts.size()>0)
            delete(lDelAuthContacts);
    }
}