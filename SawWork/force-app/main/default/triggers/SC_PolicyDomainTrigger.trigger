/*---------------------------------------------------------------------------------
* Trigger Name         : SC_PolicyDomainTrigger
* Developer Name       : Pinkesh Rathore
* Date                 : 24th Oct,2017
* JIRA                 : ESESP-762 
* Test Class           : SC_PolicyDomain_Test

* HISTORY
* Name          Date            Comments
* Vikas         22-Jan-2018     Added check for PD Access (ESESP-929)
* Vikas         07-Apr-2021     Added logic to update Encrypted PD ID field (ESESP-5193)
* Vikas         08-Apr-2021     Multiple Service Account (ESESP-4953)
* Vikas         15-Apr-2021     Validation-Mandatory Situations not mapped (ESESP-3897)
* Sharath/Sumukh 07-Jul-2021     Jarvis Security related changes  
---------------------------------------------------------------------------------*/ 
trigger SC_PolicyDomainTrigger on Policy_Domain__c (before insert, before update, after insert, after update, before delete, after delete) {
    //Fetch the Custom metadata "SC SOC Passphrase Access"
    SC_SOC_Passphrase_Access__mdt lSOCPDAccess = [Select id, Account_Team_title__c, ProfileId__c, User_Title__c from SC_SOC_Passphrase_Access__mdt where DeveloperName =:'PD_Access' limit 1]; 
    Boolean hasAccess = false;
    List<Policy_Domain__c> policyDomainList = new List<Policy_Domain__c>();
    Map<Id,Id> pdAccMap = new Map<Id,Id>();
    Map<Id, String> sValidAccTitleMap = new Map<Id, String>();
    Map<Id, String> sValidAccTeamRoleMap = new Map<Id, String>();
    //List<Id> lPdToDelAC = new List<Id>(); Commented for ESESP-4953
    List<Id> lDelPD = new List<Id>();
    
    //ESESP-3897
    List<Id> pdIdList = new List<Id>();
    Set<String> productSet = new Set<String>();
    List<Id> unmappedSituationIdList = new List<Id>();
    List<SC_SOCC_Situation_Catalog__c> unmappedSituationCatalogs = new List<SC_SOCC_Situation_Catalog__c>();
    String unmappedSituationNames = '';
    
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
        if(Trigger.IsInsert || Trigger.IsUpdate){
            policyDomainList = Trigger.New;//List used to throw the error message
            for(Policy_Domain__c eachRec: Trigger.New){
                pdAccMap.put(eachRec.id, eachRec.Account_Name__c);
                
                //commented for ESESP-4953, going further Service Account will not be changed, it can only be removed from 
                //Service_Account_PD_Mapping__c object, removing the Authorized contacts  is moved to SC_ServiceAccountPDMapTrigger
                /*if(Trigger.IsUpdate && eachRec.Service_Account__c!=Trigger.OldMap.get(eachRec.id).Service_Account__c){
                    lPdToDelAC.add(eachRec.Id);
                }*/
                
                //ESESP-3897
                if(Trigger.IsInsert && eachRec.Runbook_name__c == 'Transitioned'){
                    pdIdList.add(eachRec.Id);
                }
                if(Trigger.IsUpdate && eachRec.Runbook_name__c == 'Transitioned' && eachRec.Runbook_name__c != Trigger.oldMap.get(eachRec.Id).Runbook_name__c){
                    pdIdList.add(eachRec.Id);
                }
                //Create Product Set
                productSet.add(eachRec.Product__c);
                if(eachRec.Additional_Product__c!=null)
                {
                    productSet.addAll(eachRec.Additional_Product__c.split(';'));
                }
            }
            if(pdIdList.size() > 0){
                for(SC_SOCC_Situation_to_Handler_Mapping__c s2h:[Select Id, Name,  Policy_Domain__c, Handler__c, Situation__c FROM SC_SOCC_Situation_to_Handler_Mapping__c Where Policy_Domain__c=:pdIdList])
                {
                    unmappedSituationIdList.add(s2h.Situation__c);
                }
                for(SC_SOCC_Situation_Catalog__c eachSituation : [Select Name from SC_SOCC_Situation_Catalog__c where ((Id NOT in: unmappedSituationIdList) AND (Name like '%mandatory%')) AND (Product__c in:productSet OR Product__c = '')]){
                    unmappedSituationNames+= '\"'+eachSituation.Name+'\",'+'<br/>' ;
                }
                
                for(Policy_Domain__c eachRec: Trigger.New){
                    if(unmappedSituationNames != ''){
                        eachRec.addError('Following Mandatory Situations for this PD do not have a mapping:\n'+unmappedSituationNames);
                    }
                }
            }
            //End of ESESP-3897
            
        }
        

        if(Trigger.IsDelete){
            policyDomainList = Trigger.Old;//List used to throw the error message
            for(Policy_Domain__c eachRec: Trigger.Old){
                pdAccMap.put(eachRec.id, eachRec.Account_Name__c);
                lDelPD.add(eachRec.Id);
            } 
        }
    }
    //--------JARVIS RELATED CHANGES----------
    try
    {
        if(Trigger.IsAfter)
        {
            list<string> pdIDsforJarvis = new list<string>();
            list<string> pdIDsforDeProvisioning = new list<string>();

                for(Policy_Domain__c eachRec: Trigger.New)
                {  
                    string recordID = SC_Jarvis_utility.convertToEighteen(eachRec.id);
                    if(trigger.isupdate && eachRec.Policy_Domain_State__c!=Trigger.OldMap.get(eachRec.id).Policy_Domain_State__c && eachRec.Policy_Domain_State__c=='Active')
                    {
                        pdIDsforJarvis.add('JARVIS_PD'+recordID);
                    }
                    
                        if(trigger.isupdate && eachRec.Policy_Domain_State__c!=Trigger.OldMap.get(eachRec.id).Policy_Domain_State__c && (eachRec.Policy_Domain_State__c=='Deprovisioned' || eachRec.Policy_Domain_State__c=='Suspended'))
                    {
                        pdIDsforDeProvisioning.add('JARVIS_PD'+recordID);
                    }
                    
                    if(Trigger.isinsert && eachRec.Policy_Domain_State__c=='Active')
                    {
                        
                        pdIDsforJarvis.add('JARVIS_PD'+recordID);
                    }
                }
            
            if(!SC_Jarvis_CoreSecurityController.createPublicGroupForSObjectRecChk && pdIDsforJarvis.size()>0)
            {
                SC_Jarvis_CoreSecurityController.createPublicGroupForSObjectRecChk=true;
                SC_Jarvis_CoreSecurityController.createPublicGroupForSObject(pdIDsforJarvis,'PolicyDomain');
            }
            
            if(pdIDsforDeProvisioning.size()>0)
            {
                //SC_Jarvis_CoreSecurityController.pdsforDeProvisioningCaseShareLogic(pdIDsforDeProvisioning);
            }
        }

    }
    catch(Exception e)
    {
    
    }
    if(!hasAccess)
    {
        if(pdAccMap != null && pdAccMap.keySet().size() > 0){
            List<AccountTeamMember> lValidAccTeamMem = [SELECT Id, AccountID, Title, TeamMemberRole FROM AccountTeamMember where AccountID IN :pdAccMap.values() and UserId = :UserInfo.getUserId() and TeamMemberRole IN('Security Services - Primary','Services - Primary','Services - Secondary')]; 
            for(AccountTeamMember eachrec : lValidAccTeamMem)
            {
                sValidAccTitleMap.put(eachrec.AccountID, eachrec.Title);
                sValidAccTeamRoleMap.put(eachrec.AccountID, eachrec.TeamMemberRole);
            }
            for(Policy_Domain__c eachRec: policyDomainList)
            {
                if(sValidAccTeamRoleMap != null && sValidAccTeamRoleMap.keySet().size() > 0)
                {
                    //Check if current user is an Account Team members with roles specified
                    if(sValidAccTeamRoleMap.get(pdAccMap.get(eachRec.Id)) == 'Security Services - Primary')
                        hasAccess = true;
                    else if(sValidAccTeamRoleMap.get(pdAccMap.get(eachRec.Id)) == 'Services - Primary' || sValidAccTeamRoleMap.get(pdAccMap.get(eachRec.Id)) == 'Services - Secondary')
                    {
                        if(sValidAccTitleMap != null && sValidAccTitleMap.keySet().size() > 0 && sValidAccTitleMap.get(pdAccMap.get(eachRec.Id)) != null)
                            if(lSOCPDAccess.Account_Team_title__c.containsIgnoreCase(sValidAccTitleMap.get(pdAccMap.get(eachRec.Id))))
                                hasAccess = true;
                    }
                }
                if(!hasAccess)
                    eachRec.addError('Insufficient Privileges');
            }
        }
    }
    //Delete the Authrized Contacts which belongs to the Service Account which were changed
    List<Authorized_Contact__c> lDelAuthContacts = [Select Id, Policy_Domain__c, Service__c from Authorized_Contact__c where /*(Policy_Domain__c IN :lPdToDelAC and Service__c = true) or* commented and moved to SC_ServiceAccountPDMapTrigger*/ Policy_Domain__c IN :lDelPD];
    if(lDelAuthContacts.size()>0)
        delete(lDelAuthContacts);
    
    //ESESP-5193 : Added logic to update Encrypted PD ID field
    List<Policy_Domain__c> afterInsertPDList = new List<Policy_Domain__c>();
    if(Trigger.IsAfter){
        if(Trigger.IsUpdate){
            for(Policy_Domain__c eachRec: Trigger.New){
                if(eachRec.AKAM_Policy_Domain_ID__c != null && eachRec.Encrypted_PD_Id__c == null){
                    String encryptedPDID = SC_SOCC_CommunityController.encryptPDId(eachRec.AKAM_Policy_Domain_ID__c);
                    if(!String.isBlank(encryptedPDID)){
                        Policy_Domain__c newPD = new Policy_Domain__c(Id=eachRec.Id, Encrypted_PD_Id__c=encryptedPDID);
                        afterInsertPDList.add(newPD);
                    }
                }
            }
        }
    }
    if(afterInsertPDList.size() > 0){
        update afterInsertPDList;
    }

}