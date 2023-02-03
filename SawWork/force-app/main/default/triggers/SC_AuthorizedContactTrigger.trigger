/*---------------------------------------------------------------------------------
* Trigger Name         : SC_AuthorizedContactTrigger
* Developer Name       : Pinkesh Rathore
* Date                 : 24th Oct,2017
* JIRA                 : ESESP-763 
* Test Class           : SC_PolicyDomain_Test
* HISTORY

* Name      |   Date        |   Comments
* Vikas     |   22-Jan-2018 |   Changed the Error message (ESESP-928)
* Vikas     |   22-Jan-2018 |   Added check for Add/Delete Authorized Contacts (ESESP-929)
* Vamsee    |   26-Jun-2018 |   Added Email address to Contact Field for Global Search(ESESP-1447 & ESESP-1483)
* Sharath/Sumukh 10-Feb-2021     Jarvis Security related changes  
* Tejaswini |   04-Aug-2021 |    Added logic to create default Availability records to Authorised Contacts if they don't have any records(ESESP-5132)

---------------------------------------------------------------------------------------------*/ 
trigger SC_AuthorizedContactTrigger on Authorized_Contact__c (before insert, before update, after insert, after update, before delete, after delete) {
    
    //Fetch the Custom metadata "SC SOC Passphrase Access"
    
    SC_SOC_Passphrase_Access__mdt lSOCPDAccess = [Select id, Account_Team_title__c, ProfileId__c, User_Title__c from SC_SOC_Passphrase_Access__mdt where DeveloperName =:'PD_Access' limit 1]; 
    String userTitle = [Select Title from User where id =:UserInfo.getUserId()].Title;
    Boolean hasAccess = false;
    List<Authorized_Contact__c> authConList = new List<Authorized_Contact__c>();
    Map<Id,Id> PDAccMap = new Map<Id,Id>();
    Map<Id,String> contactMap = new Map<Id,String>();
    List<Id> lPolicyDomain = new List<Id>();
    Map<Id, String> sValidAccTitleMap = new Map<Id, String>();
    Map<Id, String> sValidAccTeamRoleMap = new Map<Id, String>();
    
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
        if(Trigger.IsInsert || Trigger.IsUpdate)
        {
            authConList = Trigger.New;//List used to throw the error message
            for(Authorized_Contact__c eachrec: Trigger.New)
            {
                PDAccMap.put(eachrec.Policy_Domain__c, null);
                if(Trigger.IsInsert){
                    contactMap.put(eachrec.Contact_Name__c, '');
                }
                
            }
        }
        if(Trigger.IsDelete)
        {
            authConList = Trigger.Old;//List used to throw the error message
            for(Authorized_Contact__c eachrec: Trigger.Old)
                PDAccMap.put(eachrec.Policy_Domain__c, null);
        }
    }
    

    //Changes for ESESP-5132
    Map < Integer, String > mDayNoDay = new Map < Integer, String >{1=>'Monday',2=>'Tuesday',3=>'Wednesday',4=>'Thursday',5=>'Friday',6=>'Saturday',7=>'Sunday'};
    if(Trigger.IsAfter && Trigger.isinsert)
    {
        System.debug('After insert trigger of Authorised contact');
        Set<Id> sConId = new Set<Id>();

        for(Authorized_Contact__c eachrec : Trigger.new){
             sConId.add(eachrec.Contact_Name__c);
        }
           
        //Set of contacts who has atleast 1 available records
        Set<Id> sAvailCont = new Set<Id>();        
        List<SC_SOCC_Availability__c> lAvailRecs = [Select Id,Contact__c from SC_SOCC_Availability__c where Contact__c IN :sConId];
        for(SC_SOCC_Availability__c rec:lAvailRecs)
        {
            sAvailCont.add(rec.Contact__c);
        }
        
        List<SC_SOCC_Availability__c> lAvailabilityRecords = new List<SC_SOCC_Availability__c>();
        for(Id conId:sConId)
        {
            if(!sAvailCont.contains(conId))
            {
                for(Integer i=1;i<=7;i++)
                {
                    SC_SOCC_Availability__c rec = new SC_SOCC_Availability__c();
                    rec.Contact__c = conId ;
                    rec.Day_Of_Week__c = mDayNoDay.get(i);
                    rec.Start_Time__c = Time.newInstance(0, 0, 0, 0);
                    rec.End_Time__c = Time.newInstance(23, 59, 0, 0);
                    lAvailabilityRecords.add(rec);
                }
            }
        }
        insert lAvailabilityRecords;
            
    }
    

    //--------JARVIS RELATED CHANGES----------
    if(Trigger.IsAfter && (Trigger.isinsert || Trigger.isdelete))
    {
        try 
        {
            list<string> authcontIDsforJarvis = new list<string>();
            string pdID;
            List<string> authorizedContactIds =new List<string>();

            List<Authorized_Contact__c> authContactList = Trigger.isinsert ? (List<Authorized_Contact__c>)Trigger.New:
            (List<Authorized_Contact__c>)Trigger.Old;

            for(Authorized_Contact__c eachRec: authContactList)
            {  
                if(eachrec.Policy_Domain__c != null)
                {
                    string contactid_pd = eachrec.Contact_Name__c + '-' + SC_Jarvis_utility.convertToEighteen(eachrec.Policy_Domain__c);
                    authcontIDsforJarvis.add(contactid_pd);   
                    authorizedContactIds.add(eachrec.id);  
                }
            }
            
            if(!SC_Jarvis_CoreSecurityController.addAuthContToPublicGroupRecChk && authcontIDsforJarvis.size() > 0)
            {
                SC_Jarvis_CoreSecurityController.addAuthContToPublicGroupRecChk=true;
                SC_Jarvis_AuthorizedContact_Queue contactQueue = new SC_Jarvis_AuthorizedContact_Queue();
                contactQueue.isProvision = Trigger.isinsert? true: false;
                contactQueue.authorizedContactIds = authorizedContactIds;
                contactQueue.authorizedContactGroups = authcontIDsforJarvis;
                system.enqueueJob(contactQueue);
            }
                
        } catch (Exception e) 
        {
            
        }
    }
    
    // if(Trigger.IsAfter && Trigger.isdelete)
    // {
    //     try 
    //     {
    //         list<string> authcontacts = new list<string>();
    //         List<string> authorizedContactIds =new List<string>();
            
    //         for(Authorized_Contact__c eachrec: Trigger.Old)
    //         {
    //             if(eachrec.Policy_Domain__c != null)
    //             {
    //                 string contactid_pd = eachrec.Contact_Name__c + '-' + SC_Jarvis_utility.convertToEighteen(eachrec.Policy_Domain__c);
    //                 authorizedContactIds.add(eachrec.id);
    //                 authcontacts.add(contactid_pd);     
    //             }
    //         }
    //         if(authcontacts.size() > 0)
    //         {
    //             SC_Jarvis_CoreSecurityController.removeContactFromPublicGroups(authcontacts);
    //         }
                
    //     } catch (Exception e) 
    //     {
            
    //     }        
    // }
    
    

    if(!hasAccess)
    {
        //Map of PD id and Account to check Account Team member roles
        for(Policy_Domain__c eachrec: [Select id, Account_Name__c from Policy_Domain__c where Id IN :PDAccMap.keySet()]){
            PDAccMap.put(eachrec.id,eachrec.Account_Name__c);
        }
    }
    
    //Map of AC id and Contact name to update the contact field on AC
    if(contactMap.keySet().size() > 0)
    {
        for(Contact eachrec: [Select id, Name, Email from Contact where Id IN :contactMap.keySet()]){
            contactMap.put(eachrec.id, eachrec.Name + ' ' + eachrec.Email);
        }
    }
    if((PDAccMap != null && PDAccMap.keySet().size() > 0) || (contactMap != null && contactMap.keySet().size() > 0)){
        if(!hasAccess)
        {
            List<AccountTeamMember> lValidAccTeamMem = [SELECT Id, AccountID, Title, TeamMemberRole FROM AccountTeamMember where AccountID IN :PDAccMap.values() and UserId = :UserInfo.getUserId() and TeamMemberRole IN('Security Services - Primary','Services - Primary','Services - Secondary')]; 
            for(AccountTeamMember eachrec : lValidAccTeamMem)
            {
                sValidAccTitleMap.put(eachrec.AccountID, eachrec.Title);
                sValidAccTeamRoleMap.put(eachrec.AccountID, eachrec.TeamMemberRole);
            }
        }
        
        
        for(Authorized_Contact__c eachRec: authConList)
        {
            //Updating Contact__c field for global search functionality
            if(contactMap != null && contactMap.get(eachRec.Contact_Name__c) != null)
            {
                eachRec.Contact__c = contactMap.get(eachRec.Contact_Name__c);
            }
            if(sValidAccTeamRoleMap != null && sValidAccTeamRoleMap.keySet().size() > 0)
            {
                //Check if current user is an Account Team members with roles specified
                if(sValidAccTeamRoleMap.get(PDAccMap.get(eachRec.Policy_Domain__c)) == 'Security Services - Primary')
                    hasAccess = true;
                else if(sValidAccTeamRoleMap.get(PDAccMap.get(eachRec.Policy_Domain__c)) == 'Services - Primary' || sValidAccTeamRoleMap.get(PDAccMap.get(eachRec.Policy_Domain__c)) == 'Services - Secondary')
                {
                    if(sValidAccTitleMap != null && sValidAccTitleMap.keySet().size() > 0 && sValidAccTitleMap.get(PDAccMap.get(eachRec.Policy_Domain__c)) != null){
                        if(lSOCPDAccess.Account_Team_title__c.containsIgnoreCase(sValidAccTitleMap.get(PDAccMap.get(eachRec.Policy_Domain__c)))){
                            hasAccess = true;
                        }
                    }
                }
            }
            if(!hasAccess)
                eachRec.addError('You need to be SOCC or S/SP to have access.');
        }
    }
    
    //Delete related Escalation Contacts and Escalations vis Case Email if Authorized Contact is deleted
    if(Trigger.isBefore && Trigger.isDelete && hasAccess){
        Set<Id> sAuthCon = new Set<Id>();
        
        for(Authorized_Contact__c eachrec : Trigger.old)
            sAuthCon.add(eachrec.Id);
        
        List<SC_SOCC_Escalation_Contact__c> lEscCOn = [SELECT Id FROM SC_SOCC_Escalation_Contact__c WHERE Authorized_Contact__c in :sAuthCon];
        if(lEscCon.size()>0)
            delete lEscCon;
        
        List<SC_SOCC_Escalation_via_Case_Email__c> lEscViaCaseEmail = [SELECT Id FROM SC_SOCC_Escalation_via_Case_Email__c WHERE Authorized_Contact__c in :sAuthCon];
        if(lEscViaCaseEmail.size()>0)
            delete lEscViaCaseEmail;
    }
}