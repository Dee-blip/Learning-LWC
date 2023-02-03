/*
Author          : Sumukh SS/Sharath P
Description     : Controller for JARVIS Permissioning calculator

WARNING : THIS IS AN  APEX CLASS THAT CALCULATES THE ENTIRE JARVIS CASE SECURITY AND PERMISSION PROVISIONING LOGIC. PLEASE PERFORM ALL CODE REVIEWS WITH REQUIRED TEAM MEMBERS BEFORE
DEPLOYING CODE TO PRODUCTION!

Date                    Developer                   JIRA #                      Description                                                       
-------------------------------------------------------
-----------------------------------------------------------
09 Feb 2021             Authors                                           Initial Development
------------------------------------------------------------------------------------------------------------------
*/

public without sharing class SC_Jarvis_CoreSecurityController {
    
    //Creating Public Group on new PD, new account, new contracts. Trigger Passes list of 'JARVIS_ObjID'
    public static Boolean createPublicGroupForSObjectRecChk = false;

    @future
    public static void createPublicGroupForSObject(list<string> sObjectgrps, String objectType)
    {        
        set<string> existinggroups = new set<string>();
        if(objectType == 'Account')
        {
            for(Account accountRec: [Select Akam_Account_Id__c from Account where id in :sObjectgrps and 
            Akam_Account_Id__c != null])
            {
                existinggroups.add('JARVIS_ACCOUNT'+SC_Jarvis_utility.prepareGroupName(accountRec.AKAM_Account_id__c));
            }
        }
        else if(objectType == 'Contract')
        {
            String childAccount, parentAccount;
            for(Merge_Contract_Header__c contractRec: [Select Jarvis_Indirect_Contract__c,Original_Contract_Id__c,Contract_Type__c,Account_Name__c, 
           	Parent_Contract__r.Account_Name__r.AKAM_Account_id__c,Parent_Contract__r.Account_Name__c, Account_Name__r.AKAM_Account_id__c  
            from Merge_Contract_Header__c where 
            id in :sObjectgrps and Original_Contract_Id__c != null])
            {
                existinggroups.add(SC_Jarvis_utility.prepareGroupName('JARVIS_CONTRACT'+contractRec.original_contract_id__c+'_READ'));
                existinggroups.add(SC_Jarvis_utility.prepareGroupName('JARVIS_CONTRACT'+contractRec.original_contract_id__c+'_WRITE'));
                if(contractRec.Jarvis_Indirect_Contract__c)
                {
                    childAccount = String.valueOf(contractRec.Account_Name__c).substring(0, 15);
                    parentAccount = String.valueOf(contractRec.Parent_Contract__r.Account_Name__c).substring(0, 15);
    
                    existinggroups.add(SC_Jarvis_utility.prepareGroupName('JA_' + childAccount +'_' + parentAccount + '_R'));
					existinggroups.add(SC_Jarvis_utility.prepareGroupName('JA_' + childAccount +'_' + parentAccount + '_W'));

                }
            }

        }
        else
        {
            existinggroups.addall(sObjectgrps);
        }
        
        
        for(group eachexistinggroup : [select name from group where name in :existinggroups])
        {
            existinggroups.remove(eachexistinggroup.name);
        }
        
        list<group> grpstobecreated = new list<group>();
        
        if(existinggroups.size()>0){    
            for(string eachnewgrp : existinggroups)
            {
                group grp = new Group( Name=eachnewgrp, DeveloperName = eachnewgrp, type='Regular' );
                grpstobecreated.add(grp);
            }
        }

        List<Database.SaveResult> updateResults = database.insert(grpstobecreated,false);
        SC_Jarvis_utility.populateErrorTableForUpdate(updateResults,grpstobecreated,'Jarvis: Group Creation Error','Jarvis: Group Creation Error');
        
    }
    
    //Adds group members to public groups. Trigger passes list of - 'contactid-parentobjectid'
    public static Boolean addAuthContToPublicGroupRecChk = false;
    @future
    public static void addContactToPublicGroups(list<string> contactIDsfromTrigger)
    {
        
        map<string,string> contactid_userid = new map<string,string>();
        map<string,string> groupname_groupid = new map<string,string>();
        
        set<id> contactidsset= new set<id>();
        set<string> groupnamesset= new set<string>();
        
        for(string eachstring : contactIDsfromTrigger)
        {   
            string groupname = 'JARVIS_PD' + SC_Jarvis_utility.convertToEighteen(eachstring.split('-')[1]);
            string contactid = eachstring.split('-')[0];
            contactidsset.add(contactid);
            groupnamesset.add(groupname);
        }
        
        for(group eachgroup : [select id, name from group where name in :groupnamesset])
        {
            groupname_groupid.put(eachgroup.name, eachgroup.id);
        }
        
        for(user eachuserrec : [select id,contactid from user where contactid IN :contactidsset])
        {
            contactid_userid.put(eachuserrec.contactid,eachuserrec.id);
        }
        
        list<GroupMember> associatedgrpmember= new list<GroupMember>();
        
        for( string eachrecord : contactIDsfromTrigger)
        {
            //Get list of contacts to be added from group name and contacts map
            string groupname = 'JARVIS_PD'+SC_Jarvis_utility.convertToEighteen(eachrecord.split('-')[1]);
            string contactid = eachrecord.split('-')[0];
            
            string userid = contactid_userid.get(contactid);
            if(userid!=null)
            {
                GroupMember grpmem = new GroupMember (GroupId=groupname_groupid.get(groupname), UserOrGroupId=userid); 
                associatedgrpmember.add(grpmem); 
            }
        }
        List<Database.SaveResult> updateResults = database.insert(associatedgrpmember,false);
        SC_Jarvis_utility.populateErrorTableForUpdate(updateResults,associatedgrpmember,'Jarvis: Authorized contact to PD Group Error','Jarvis: Authorized contact to PD Group Error');

    }
    
    //[Community User deprovisioning or removing from PD / contract public groups ]. Trigger passes list of - 'contactid-parentobjectid'. 
    //If user deprovisioning = true, trigger passes just contactIDs
    @future
    public static void removeContactFromPublicGroups(list<string> contactIDsfromTrigger)
    {
        map<string, Set<string>> parentobjID_contactIDs = new map<string,Set<string>>();
        list<string> contactidslst= new list<string>();
        
        for(string eachstring : contactIDsfromTrigger)
        {   
            string groupname = 'JARVIS_PD'+eachstring.split('-')[1];
            string contactid = eachstring.split('-')[0];
            contactidslst.add(contactid);
            
            if(!parentobjID_contactIDs.containskey(groupname))
            {
                parentobjID_contactIDs.put(groupname,new Set<String>());
            }
            parentobjID_contactIDs.get(groupname).add(contactid);
        }
        
        map<string,string> userid_contactid = new map<string,string>();
        
        for(user eachuserrec : [select id,contactid from user where contactid IN :contactidslst])
        {
            userid_contactid.put(eachuserrec.id,eachuserrec.contactid);
        }
        
        list<groupmember> groupmemberstobedeleted = new list<groupmember>();
        
        for(groupmember eachgrpmemrec : [select id,group.name,UserOrGroupId from groupmember where group.name IN : parentobjID_contactIDs.keyset() AND UserOrGroupId IN : userid_contactid.keyset()])
        {
            //list<string> contactstobedeleted = new list<string>();
            //Get list of contacts to be deleted from group name and contacts map
            //contactstobedeleted=parentobjID_contactIDs.get(eachgrpmemrec.group.name);
            //Get the contactid that is being iterated for the user in the group member object
            string contactid = userid_contactid.get(eachgrpmemrec.UserOrGroupId);
            
            if(parentobjID_contactIDs.containsKey(eachgrpmemrec.group.name) && parentobjID_contactIDs.get(eachgrpmemrec.group.name).contains(contactid))
            {
                groupmemberstobedeleted.add(eachgrpmemrec);
            }
        }
        
        try
        {
            delete(groupmemberstobedeleted);
        }
        catch(Exception e)
        {
            SC_Jarvis_utility.sendErrorMails('Jarvis Group Member Delete Error','Exception: ' , e.getMessage());
        }
        
    }
    
    
    // @future
    // public static void userDeProvisioningLogic(list<string> contactIDsfromTrigger)
    // {
        
    //     set<id> userids = new set<id>();
        
    //     list<user> usersForInactivation = new list<user>();
        
    //     for(user eachuserrec : [select id,IsActive from user where contactid IN :contactIDsfromTrigger])
    //     {
    //         userids.add(eachuserrec.id);
    //         eachuserrec.IsActive=false;
    //         usersForInactivation.add(eachuserrec);
    //     }
        
    //     list<groupmember> groupmemberstobedeleted = new list<groupmember>();
        
    //     for(groupmember eachgrpmemrec : [select id from groupmember where group.name like 'JARVIS_%' and UserOrGroupId IN :userids])
    //     {
    //         groupmemberstobedeleted.add(eachgrpmemrec);
    //     }
        
    //     list<AccountContactRelation> associatedrecstoinvalidate =  new list<AccountContactRelation>();
        
    //     for(AccountContactRelation eachrec : [select id, isactive, enddate from AccountContactRelation where contactid IN :contactIDsfromTrigger and isactive=true])
    //     {
    //         eachrec.IsActive=false;
    //         eachrec.enddate = system.today();
    //         associatedrecstoinvalidate.add(eachrec);
    //     }
        
    //     update associatedrecstoinvalidate; 
    //     update usersForInactivation;
    //     delete(groupmemberstobedeleted);
        
    // }
    
    // @future
    // public static void pdsforDeProvisioningCaseShareLogic(list<string> groupnamesfromTrigger)
    // {
    //     set<id> setofgrpIDs = new set<id>();
        
    //     for(group eachgrouprec :[select id from group where name IN : groupnamesfromTrigger])
    //     {
    //         setofgrpIDs.add(eachgrouprec.id);
    //     }
        
    //     list<caseshare> casesToBeUpdated = new list<caseshare>();
        
    //     for(caseshare eachrec : [select id,CaseAccessLevel,RowCause from caseshare where UserOrGroupId IN :setofgrpIDs and RowCause='Manual' limit 50000])
    //     {
    //         eachrec.CaseAccessLevel='Read';
    //         casesToBeUpdated.add(eachrec);
    //     }
        
    //     update casesToBeUpdated;
    // }
    

    public static Boolean caseTriggerRecursionCheckInsert = false;
    public static Boolean caseTriggerRecursionCheckUpdate = false;
    public static Boolean caseTriggerRecursionCheckUpdateDeprovision = false;
    public static Set<String> caseRecordTypesJarvis = new Set<String>{'Technical','AMG','Billing',
            'Professional Services','Emerging Products Engineering','Managed Security','Partner Technical Support'};

    public static Map<String,Set<String>> calculateAndAssignCaseShare(List<String> caseIds)
    {
        Set<String> caseProductNames = new Set<String>();
        Set<String> caseProductNamesPS = new Set<String>();

        Set<String> accountIds = new Set<String>();
        Set<String> accountIdPS = new Set<String>();

        Map<String, Set<String>> caseProductToMarketingProducts = new Map<String, Set<String>>();

        Set<String> marketingProducts = new Set<String> ();

        Set<String> services = new Set<String>();
        Map<String,Set<String>> casesToSetGroups = new Map<String,Set<String>>();
        Map<String,Set<String>> accountIdtoContractAkamId = new Map<String,Set<String>>();

        Map<String,String> caseProductToBusinessHours = new Map<String,String>();
        Map<String,Map<String,Set<String>>> marketingProductToAccountToContract = new Map<String,Map<String,Set<String>>>();
        Map<String,Map<String,String>> serviceToAccountToContracts = new Map<String,Map<String,String>>();

        Map<Id,Case> caseIdtoRec= new Map<Id,Case>([Select Id, Policy_Domain__c,RecordType.Name,Case_Product__r.Name,Contract_ID__c, Parent_Account__c,
        AccountId,Account.AKAM_Account_id__c, Created_By_Account__c,Created_By_Account__r.AKAM_Account_id__c, Indirect_Customer__c,Indirect_Customer__r.AKAM_Account_id__c,Service__c,Service_Contract_Id__c,Community_Sharing_Set_Account_Lookup__c,Community_Sharing_Set_Account_Lookup__r.AKAM_Account_id__c,PS_Product__c,Business_Unit__c,ATT_RecordType__c from Case where Id in :caseIds]);
        // Map<Id,Case> caseIdtoRec= new Map<Id,Case>([Select Id, Policy_Domain__c,RecordType.Name,Case_Product__r.Name,
        // AccountId,Account.AKAM_Account_id__c, Created_By_Account__c,Created_By_Account__r.AKAM_Account_id__c, Indirect_Customer__c,Indirect_Customer__r.AKAM_Account_id__c,Service__c,Service_Contract_Id__c,Community_Sharing_Set_Account_Lookup__c,Community_Sharing_Set_Account_Lookup__r.AKAM_Account_id__c,PS_Product__c,Business_Unit__c,ATT_RecordType__c from Case where Id in :caseIds]);

        Map<String, String> groupNameToId = new Map<String, String>();

        List<Case> casesToUpdate = new List<Case>();
        Map<String,Map<String,String>> platformProductToCase = new Map<String,Map<String,String>>();
        Set<String> caseProductAccounts = new Set<String>();
        String childAccount, parentAccount;

        for(Id caseId: caseIdtoRec.keySet())
        {
            Case caseRec = caseIdtoRec.get(caseId);
            if(caseRec.RecordType.Name == 'AMG' || caseRec.RecordType.Name == 'Billing' || 
                caseRec.ATT_RecordType__c == 'Billing' || caseRec.ATT_RecordType__c == 'AMG' ||
                (
                    (caseRec.RecordType.Name == 'Technical' || caseRec.RecordType.Name == 'Professional Services'
                    ||caseRec.RecordType.Name == 'Emerging Products Engineering' ||
                    caseRec.ATT_RecordType__c == 'Technical' || caseRec.ATT_RecordType__c == 'Professional Services')
                    && caseRec.Case_Product__c == null
                )
            )
            {
                casesToSetGroups.put(caseRec.Id, new Set<String>());
                if(caseRec.Community_Sharing_Set_Account_Lookup__c != null)
                {
					casesToSetGroups.get(caseRec.Id).add(SC_Jarvis_utility.prepareGroupName('JARVIS_ACCOUNT' + caseRec.Community_Sharing_Set_Account_Lookup__r.AKAM_Account_id__c));                    
                }
                else
                {
                    // String currentAccountAkamId = caseRec.Indirect_Customer__r.AKAM_Account_id__c == null?
                    //     caseRec.Account.AKAM_Account_id__c :caseRec.Indirect_Customer__r.AKAM_Account_id__c;
                    childAccount = caseRec.Indirect_Customer__c == null?
                    caseRec.AccountId :caseRec.Indirect_Customer__c;
                    childAccount = childAccount != null ?String.valueOf(childAccount).substring(0, 15) : null;
                    parentAccount = caseRec.Created_By_Account__c != null ? String.valueOf(caseRec.Created_By_Account__c).substring(0, 15) : null;
                    
                    if(caseRec.Parent_Account__c != null && (caseRec.RecordType.Name == 'AMG' || caseRec.RecordType.Name == 'Billing' || 
                                                             caseRec.ATT_RecordType__c == 'Billing' || caseRec.ATT_RecordType__c == 'AMG'))
                    {
                     	    parentAccount = String.valueOf(caseRec.Parent_Account__c).substring(0, 15);                       
                    }

                    if(childAccount != parentAccount && parentAccount != null && childAccount != null)
                    {
                        casesToSetGroups.get(caseRec.Id).add(SC_Jarvis_utility.prepareGroupName('JA_' + childAccount +'_' + parentAccount + '_R'));
                        casesToSetGroups.get(caseRec.Id).add(SC_Jarvis_utility.prepareGroupName('JA_' + childAccount +'_' + parentAccount + '_W'));
                    }
                }

                if(caseRec.Case_Product__r.Name == null && caseRec.PS_Product__c != null && (caseRec.RecordType.Name == 'Professional Services' || caseRec.ATT_RecordType__c == 'Professional Services') )
                {                    
                    if(!platformProductToCase.containsKey(caseRec.PS_Product__c))
                    {
                        platformProductToCase.put(caseRec.PS_Product__c,new Map<String,String>());
                    }
                    platformProductToCase.get(caseRec.PS_Product__c).put(caseRec.AccountId,null);
                    caseProductAccounts.add(caseRec.AccountId);
                    caseProductNames.add(caseRec.PS_Product__c);
                    caseProductNamesPS.add(caseRec.PS_Product__c);
                    
                }
            }
            else if(caseRec.RecordType.Name == 'Managed Security' || caseRec.ATT_RecordType__c == 'Managed Security')
            {
                casesToSetGroups.put(caseRec.Id, new Set<String>{'JARVIS_PD' + SC_Jarvis_utility.convertToEighteen(caseRec.Policy_Domain__c)});
            }
            else if(caseRec.RecordType.Name == 'Technical' || caseRec.RecordType.Name == 'Professional Services' 
            || caseRec.RecordType.Name == 'Emerging Products Engineering' || 
            caseRec.ATT_RecordType__c == 'Technical' || caseRec.ATT_RecordType__c == 'Professional Services')
            {
                accountIds.add(caseRec.AccountId);
                if(caseRec.Case_Product__r.Name != null)
                {
                    caseProductNames.add(caseRec.Case_Product__r.Name);
                }
                if(caseRec.RecordType.Name == 'Professional Services' || caseRec.ATT_RecordType__c == 'Professional Services')
                {
                    if(caseRec.Case_Product__r.Name != null)                
                    {
                        caseProductNamesPS.add(caseRec.Case_Product__r.Name);
                    }
                    if(caseRec.Service__c != null)
                    {
                        services.add(caseRec.Service__c);
                        accountIdPS.add(caseRec.AccountId);
                    }
                }
            }
        }
        //system.debug('platformProductToCase: ' + platformProductToCase);
        if(platformProductToCase.size() > 0)
        {
            //system.debug('platformProductToCase: ' + platformProductToCase);
            for(EB_AccountProductMap__c productRec: [select EB_Account__c, 
            Name, Id from EB_AccountProductMap__c where EB_MarkedForDeletion__c = false and 
            EB_Account__c in :caseProductAccounts and Name in :platformProductToCase.keySet()])
            {
                if(platformProductToCase.containsKey(productRec.Name)
                && platformProductToCase.get(productRec.Name) != null &&
                platformProductToCase.get(productRec.Name).containsKey(productRec.EB_Account__c))
                {
                    platformProductToCase.get(productRec.Name).put(productRec.EB_Account__c,productRec.Id);
                }
            }
            system.debug('platformProductToCase: ' + platformProductToCase);
        }
        if(caseProductNames.size() > 0 )
        {
            system.debug('caseProductNames: ' + caseProductNames);
            for (Siebel_Marketing_Prod_Case_Prod_Map__c mappingRec : SC_Jarvis_utility.getMappingRecords( caseProductNames, null))
            {
                if(!caseProductToMarketingProducts.containsKey(mappingRec.Case_Product_Name__c))
                {
                    caseProductToMarketingProducts.put(mappingRec.Case_Product_Name__c,new Set<String>());   
                }
                caseProductToMarketingProducts.get(mappingRec.Case_Product_Name__c).add(mappingRec.Marketing_Product_ID__c);
                marketingProducts.add(mappingRec.Marketing_Product_ID__c);
            }
            system.debug('marketingProducts: ' + marketingProducts);
            caseProductNames.clear();
            if(caseProductNamesPS.size() > 0)
            {
                for(String caseProductName: caseProductNamesPS)
                {
                    if(caseProductToMarketingProducts.get(caseProductName) != null)
                    {
                        caseProductNames.addAll(caseProductToMarketingProducts.get(caseProductName));
                    }
                    
                }
                system.debug('caseProductNames: ' + caseProductNames);
                if(caseProductNames.size() > 0)
                {
                    Map<String,String> productToBusinessHours = new Map<String,String>();

                    for(PAC_Product_Catalog__c pacRec: SC_Jarvis_utility.getBusinessUnit(caseProductNames, 0))
                    {
                        productToBusinessHours.put(pacRec.Marketing_Product_Id__c,pacRec.Business_Unit__c);
                    }
                    if(productToBusinessHours.size() > 0)
                    {
                        for(String caseProductName: caseProductNamesPS)
                        {
                            if(caseProductToMarketingProducts.get(caseProductName) != null)
                            {
                                for(String marketingProductId: caseProductToMarketingProducts.get(caseProductName))
                                {
                                    if(productToBusinessHours.get(marketingProductId) != null && 
                                    !caseProductToBusinessHours.containsKey(caseProductName))
                                    {
                                        caseProductToBusinessHours.put(caseProductName,productToBusinessHours.get(marketingProductId));
                                    }
                                    else if(productToBusinessHours.get(marketingProductId) != null && 
                                    caseProductToBusinessHours.get(caseProductName) != productToBusinessHours.get(marketingProductId))
                                    {
                                        caseProductToBusinessHours.put(caseProductName,'');
                                    }
                                }
                            }
                            
                        }
                        system.debug('caseProductToBusinessHours: ' + caseProductToBusinessHours);
                        productToBusinessHours.clear();
                        caseProductNames.clear();
                    }
                }

            }
            
            for(Merge_Contract_Detail__c contractDetail: SC_Jarvis_utility.getContractDetails(null, marketingProducts,accountIds,0))
            {                   
                if(!marketingProductToAccountToContract.containskey(contractDetail.Product_Id__c))
                {
                    marketingProductToAccountToContract.put(contractDetail.Product_Id__c, new Map<String,Set<String>>());
                }
                if(!marketingProductToAccountToContract.get(contractDetail.Product_Id__c).containsKey(contractDetail.Original_Contract_Id__r.Account_Name__c))
                {
                    marketingProductToAccountToContract.get(contractDetail.Product_Id__c).put(contractDetail.Original_Contract_Id__r.Account_Name__c,new Set<String>());                    
                }
                marketingProductToAccountToContract.get(contractDetail.Product_Id__c).get(contractDetail.Original_Contract_Id__r.Account_Name__c).add(contractDetail.Original_Contract_Id__r.Original_Contract_Id__c);
            }
            system.debug('marketingProductToAccountToContract: ' + marketingProductToAccountToContract);
        }
        if(services.size() > 0)
        {
            String serviceString = SC_Jarvis_utility.getServicesPS(accountIdPS, null, services,0);
            //system.debug('serviceString: ' + serviceString);
            try
            {
                serviceToAccountToContracts =  !String.isBlank(serviceString) && serviceString != '[]'? 
                (Map<String,Map<String,String>>) JSON.deserialize(serviceString,Map<String,Map<String,String>>.class):
                serviceToAccountToContracts;    
            }
            catch(Exception e)
            {
                
            }
            //system.debug('serviceToAccountToContracts: ' + serviceToAccountToContracts);
        }
        Case caseRec;
        String contractString;
        
        marketingProducts.clear();

        Set<String> currentContracts;
        for(Id caseId: caseIdtoRec.keySet())
        {
            caseRec = caseIdtoRec.get(caseId);
            
            if(caseRec.RecordType.Name == 'Technical' || caseRec.RecordType.Name == 'Professional Services' 
            || caseRec.RecordType.Name == 'Emerging Products Engineering' || 
            caseRec.ATT_RecordType__c == 'Technical' || caseRec.ATT_RecordType__c == 'Professional Services')
            {
                contractString = '';
                Boolean updatedRec = false;
                if(caseRec.RecordType.Name == 'Professional Services' || caseRec.ATT_RecordType__c == 'Professional Services')
                {
                    if(caseRec.Case_Product__r.Name != null && caseRec.Case_Product__r.Name != caseRec.PS_Product__c)
                    {
                        caseRec.PS_Product__c = caseRec.Case_Product__r.Name;
                        updatedRec = true;
                    }
                    else if(caseRec.PS_Product__c != null && caseRec.Case_Product__r.Name == null &&
                    platformProductToCase != null && platformProductToCase.size() > 0 &&
                    platformProductToCase.containsKey(caseRec.PS_Product__c) && 
                    platformProductToCase.get(caseRec.PS_Product__c) != null && 
                    platformProductToCase.get(caseRec.PS_Product__c).containsKey(caseRec.AccountId))
                    {
                        caseRec.Case_Product__c = platformProductToCase.get(caseRec.PS_Product__c).get(caseRec.AccountId);
                        caseRec.community_sharing_set_account_lookup__c = null;
                        updatedRec = true;
                    }

                }    
                marketingProducts = caseRec.Case_Product__r.Name != null?
                caseProductToMarketingProducts.get(caseRec.Case_Product__r.Name):
                caseRec.Case_Product__c != null && caseRec.Case_Product__r.Name == null && 
                caseRec.PS_Product__c != null?
                caseProductToMarketingProducts.get(caseRec.PS_Product__c):
                null;
                if(marketingProducts != null && marketingProducts.size() > 0)
                {
                    for(String productId : marketingProducts)
                    {
                        if(marketingProductToAccountToContract.containsKey(productId) && 
                        marketingProductToAccountToContract.get(productId) != null)
                        {
                            currentContracts = marketingProductToAccountToContract.get(productId).get(caseRec.AccountId);
                            if(currentContracts != null && currentContracts.size() > 0)
                            {
                                contractString += contractString != '' ? ',' + String.join((Iterable<String>)currentContracts,',') : 
                                String.join((Iterable<String>)currentContracts,',');
                                casesToSetGroups.put(caseRec.Id,new Set<String>());
                                for(String contractId : currentContracts)
                                {
                                    casesToSetGroups.get(caseRec.Id).add(SC_Jarvis_utility.prepareGroupName('JARVIS_CONTRACT' + contractId+'_READ'));
                                    casesToSetGroups.get(caseRec.Id).add(SC_Jarvis_utility.prepareGroupName('JARVIS_CONTRACT' + contractId+'_WRITE'));                    

                                }
                            }
                        }
                        
                    }
                }
                
                if(caseRec.Contract_ID__c != contractString)
                {
                   caseRec.Contract_ID__c = contractString;
                   updatedRec = true;
                }
                if(caseRec.RecordType.Name == 'Professional Services' || caseRec.ATT_RecordType__c == 'Professional Services')
                {
                    string currentCaseProductName = caseRec.Case_Product__r.Name == null && caseRec.Case_Product__c != null &&
                    caseRec.PS_Product__c != null ? caseRec.PS_Product__c : caseRec.Case_Product__r.Name != null ? caseRec.Case_Product__r.Name
                    : null;
                    if(currentCaseProductName == null || 
                    !caseProductToBusinessHours.containsKey(currentCaseProductName) ||
                    caseProductToBusinessHours.get(currentCaseProductName) == '' && caseRec.Business_Unit__c != null)
                    {
                        caseRec.Business_Unit__c= null;
                        updatedRec = true;
                    }
                    else if(caseRec.Business_Unit__c != caseProductToBusinessHours.get(currentCaseProductName))
                    {
                        caseRec.Business_Unit__c = caseProductToBusinessHours.get(currentCaseProductName);
                        updatedRec = true;
                    }
                    if((caseRec.Service__c == null && caseRec.Service_Contract_Id__c != null)
                    || serviceToAccountToContracts == null
                    || (serviceToAccountToContracts != null && !serviceToAccountToContracts.containsKey(caseRec.AccountId))
                    || (serviceToAccountToContracts != null && serviceToAccountToContracts.containsKey(caseRec.AccountId) &&
                    !serviceToAccountToContracts.get(caseRec.AccountId).containsKey(caseRec.Service__c))
                    )
                    {
                        caseRec.Service_Contract_Id__c = null;
                        updatedRec = true;
                    }
                    else if(caseRec.Service__c != null && serviceToAccountToContracts != null && 
                    serviceToAccountToContracts.containsKey(caseRec.AccountId)
                    && caseRec.Service_Contract_Id__c != serviceToAccountToContracts.get(caseRec.AccountId).get(caseRec.Service__c))
                    {
                        caseRec.Service_Contract_Id__c = serviceToAccountToContracts.get(caseRec.AccountId).get(caseRec.Service__c);
                        updatedRec = true;
                    }
                }

                if(updatedRec)
                {
                    caseRec.Validation_Override__c = true;
                    casesToUpdate.add(caseRec);
                    system.debug('casesToUpdate: ' + casesToUpdate);
                }

            }
        }
        marketingProductToAccountToContract.clear();
        //currentContracts.clear();
        serviceToAccountToContracts.clear();
        
        if(casesToUpdate.size() > 0)
        {

            List<Database.SaveResult> updateResults = Database.update(casesToUpdate,false);
            SC_Jarvis_utility.populateErrorTableForUpdate(updateResults,casesToUpdate,'Jarvis: Case Update Error','Jarvis: Case Update Error');
        }
    
        // //Changes for ESESP-5962: deleting case team members
        // try
        // {
        //     List<CaseTeamMember> members = [select Id from CaseTeamMember where TeamRole.name = 'Reporter' and ParentId in :caseIds 
        //                               and (not Member.email like '%@akamai.com%')];
        //     if(members.size() > 0)
        //     {
        //         delete members;
        //     }        
        // }
        // catch(Exception e)
        // {
        //     SC_Jarvis_utility.sendErrorMails('Jarvis Case Team Member Delete Error','Exception: ' , e.getMessage());
        // }       
        return casesToSetGroups; 
    }
    
    public static void assignCaseAndCommentShares(Map<String,Set<String>> casesToSetGroups,Map<String,Case> caseIdtoRec)
    {
        List<sObject> shareRecToInsert = new List<sObject>();
        List<sObject> shareRecToDelete = new List<sObject>();
        List<Database.SaveResult> updateResults;
        // List<CaseShare> caseShareToCreate = new List<CaseShare>();
        // List<CaseShare> caseShareToDelete = new List<CaseShare>();

        // List<community_comments__share> commentShareToCreate = new List<community_comments__share>();
        // List<community_comments__share> commentShareToDelete = new List<community_comments__share>();

        Set<String> groupNames = new Set<String>();
        Map<String, String> groupNameToId = new Map<String, String>();

        Map<String,Set<String>> casesToSetGroupsInsert = new Map<String,Set<String>>();

        for(CaseShare caseShareRec: SC_Jarvis_utility.getCaseSharesJarvis(caseIdtoRec.keySet()))
        {   
            if((casesToSetGroups.containsKey(caseShareRec.CaseId) && 
            !casesToSetGroups.get(caseShareRec.CaseId).contains(caseShareRec.UserOrGroup.Name)) ||
            !casesToSetGroups.containsKey(caseShareRec.CaseId))
            {
                //caseShareToDelete.add(caseShareRec);
                shareRecToDelete.add(caseShareRec);
            }
            else if(casesToSetGroups.containsKey(caseShareRec.CaseId) && 
            casesToSetGroups.get(caseShareRec.CaseId).contains(caseShareRec.UserOrGroup.Name))
            {
                if(!casesToSetGroupsInsert.containsKey(caseShareRec.CaseId))
                {
                    casesToSetGroupsInsert.put(caseShareRec.CaseId,new Set<String>());
                }
                casesToSetGroupsInsert.get(caseShareRec.CaseId).add(caseShareRec.UserOrGroup.Name);
            }
            
        }  

        for(community_comments__share commentShareRec: SC_Jarvis_utility.getCommentSharesJarvis(caseIdtoRec.keySet(),null))
        {   
            if((casesToSetGroups.containsKey(commentShareRec.parent.Parent_ID__c) && 
            !casesToSetGroups.get(commentShareRec.parent.Parent_ID__c).contains(commentShareRec.UserOrGroup.Name)) ||
            !casesToSetGroups.containsKey(commentShareRec.parent.Parent_ID__c))
            {
                //commentShareToDelete.add(commentShareRec);
                shareRecToDelete.add(commentShareRec);
            }            
        }  

        for(String caseId: casesToSetGroups.keySet())
        {
            if(casesToSetGroupsInsert.containsKey(caseId) && casesToSetGroupsInsert.get(caseId) != null
            && casesToSetGroupsInsert.get(caseId).size() > 0)
            {
                casesToSetGroups.get(caseId).removeAll(casesToSetGroupsInsert.get(caseId));
            }
            if(casesToSetGroups.get(caseId).size() > 0)
            {
                groupNames.addAll(casesToSetGroups.get(caseId));
            }

        }
        for(Group groupRec : [Select Id, Name from Group where name in :groupNames])
        {
            groupNameToId.put(groupRec.Name,groupRec.Id);
        }

        List<community_comments__c> commentsToUpdate = new List<community_comments__c>();
        system.debug('casesToSetGroups: ' + casesToSetGroups);
        if(casesToSetGroups.size() > 0)
        {

            for(community_comments__c commentRec: SC_Jarvis_utility.getComments(caseIdtoRec.keySet()))
            {
                if(commentRec.Account_ID_for_Community_Share__c != 
                caseIdtoRec.get(commentRec.Parent_ID__c ).Community_Sharing_Set_Account_Lookup__c)
                {
                    commentRec.Account_ID_for_Community_Share__c = caseIdtoRec.get(commentRec.Parent_ID__c ).Community_Sharing_Set_Account_Lookup__c;
                    commentsToUpdate.add(commentRec);
                }
    
                if(casesToSetGroups.containsKey(commentRec.Parent_ID__c) && 
                casesToSetGroups.get(commentRec.Parent_ID__c) != null && casesToSetGroups.get(commentRec.Parent_ID__c).size() > 0)
                {
                    for(String groupName: casesToSetGroups.get(commentRec.Parent_ID__c))
                    {
                        if(groupNameToId.containsKey(groupName))
                        {
                            //commentShareToCreate.add(SC_Jarvis_utility.createCommentShare(commentRec.Id, groupNameToId.get(groupName)));
                            shareRecToInsert.add(SC_Jarvis_utility.createCommentShare(commentRec.Id, groupNameToId.get(groupName)));
                        }
                        
                    }
                }
            }
    
            for(Id caseId : casesToSetGroups.keySet())
            {
                for(String groupName : casesToSetGroups.get(caseId))
                {
                    if(groupNameToId.get(groupName) != null)
                    {
                        //caseShareToCreate.add(SC_Jarvis_utility.createCaseShare(caseId, groupNameToId.get(groupName), groupName));  
                        shareRecToInsert.add(SC_Jarvis_utility.createCaseShare(caseId, groupNameToId.get(groupName), groupName));  
                    }
                }
            }
            if(commentsToUpdate.size() > 0)
            {
                updateResults = Database.update(commentsToUpdate , false);
                SC_Jarvis_utility.populateErrorTableForUpdate(updateResults,commentsToUpdate,'Jarvis: Comment Update Error','Jarvis: Comment Update Error');
            }
            system.debug('shareRecToInsert: ' + shareRecToInsert);
            system.debug('shareRecToDelete: ' + shareRecToDelete);
            if(shareRecToInsert.size() > 0)
            {
                updateResults = Database.insert(shareRecToInsert , false);
                SC_Jarvis_utility.populateErrorTableForUpdate(updateResults,shareRecToInsert,'Jarvis: Comment Share Insert','Jarvis: Comment Share Insert');
            }
            // if(commentShareToCreate.size() > 0)
            // {
            //     insert commentShareToCreate;
            // }

            if(shareRecToDelete.size() > 0)
            {
                try
                {
                    delete shareRecToDelete;
                }
                catch(Exception e)
                {
                    SC_Jarvis_utility.sendErrorMails('Jarvis Comment Share Delete Error','Exception: ' , e.getMessage());
                }
            }
            // if(commentShareToDelete.size() > 0)
            // {
            //     delete commentShareToDelete;
            // }
            
         }
        //Changes for ESESP-5962: deleting case team members
        try
        {
            List<CaseTeamMember> members = [select Id from CaseTeamMember where TeamRole.name = 'Reporter' and ParentId in :caseIdtoRec.keySet() 
                                      and (not Member.email like '%@akamai.com%')];
            if(members.size() > 0)
            {
                delete members;
            }        
        }
        catch(Exception e)
        {
            SC_Jarvis_utility.sendErrorMails('Jarvis Case Team Member Delete Error','Exception: ' , e.getMessage());
        }       

    }     
    @future 
    public static void caseShareListJarvisDeprovision(List<String> caseIds)
    {
        system.debug('caseIds: ' + caseIds);

        List<Community_Comments__c> comments = new List<Community_Comments__c>();
        for(Community_Comments__c commentRec: [select id, Parent_ID__c,Account_ID_for_Community_Share__c 
        from Community_Comments__c where Parent_ID__c in :caseIds and Account_ID_for_Community_Share__c != null])
        {
            commentRec.Account_ID_for_Community_Share__c = null;
            comments.add(commentRec);
        }
        List<CaseShare> caseshares = [Select Id from CaseShare where 
            caseId in :caseIds and userorgroup.name like 'JARVIS%'];                
             
        List<community_comments__share> commentShares = [select id, parent.Parent_ID__c from 
        community_comments__share where UserOrGroup.name like 'JARVIS%' 
        and parent.Parent_ID__c in :caseIds];

        if(comments.size() > 0)
        {
            List<Database.SaveResult> results = Database.update(comments , false);

            SC_Jarvis_utility.populateErrorTableForUpdate(results,comments,'Jarvis: Comment De-Provision Update','Jarvis: Comment De-Provision Update');                        
        }
        if(caseshares.size() > 0)
        {
            try
            {
                delete caseshares;
            }
            catch(Exception e)
            {
                SC_Jarvis_utility.sendErrorMails('Jarvis Comment Share Delete Error','Exception: ' , e.getMessage());
            }
        }
        if(commentShares.size() > 0)
        {
            try
            {
                delete commentShares;
            }
            catch(Exception e)
            {
                SC_Jarvis_utility.sendErrorMails('Jarvis Comment Share Delete Error','Exception: ' , e.getMessage());
            }
        }

    }

    @future
    public static void addUserToGroups(String groupMap)
    {
        Map<String,Set<String>> contactIdToGroups = (Map<String,Set<String>>)
            JSON.deserializeStrict(groupMap, Map<String,Set<String>>.class);
        
        Map<String,String> idToFedId = new Map<String,String>();
        Map<String,String> fedIdToId = new Map<String,String>();
        for(User userRec: [Select Id, FederationIdentifier from User where 
        FederationIdentifier in :contactIdToGroups.keySet() and isactive = true])
        {
            idToFedId.put(userRec.Id,userRec.FederationIdentifier);
            fedIdToId.put(userRec.FederationIdentifier,userRec.Id);
        }
        string contactId;
        List<GroupMember> membersToDelete = new List<GroupMember>();
        List<GroupMember> membersToInsert = new List<GroupMember>();
        Map<string,String> groupNameToId = new Map<string,String>();

        for(GroupMember memberRec: [Select Id, UserorGroupId, GroupId,Group.Name from 
        GroupMember where (Group.Name like 'JA_001%' or Group.Name like 'JARVIS_CONTRACT%' or Group.Name like 'JARVIS_ACCOUNT%') and UserorGroupId in :idToFedId.keySet()])
        {
            contactId = idToFedId.get(memberRec.UserorGroupId);
            if(contactIdToGroups.containsKey(contactId) && contactIdToGroups.get(contactId).contains(memberRec.Group.Name))
            {
                contactIdToGroups.get(contactId).remove(memberRec.Group.Name);
                if(contactIdToGroups.get(contactId).size() == 0)
                {
                    contactIdToGroups.remove(contactId);
                }
            }
            else 
            {
                membersToDelete.add(memberRec);
            }
            groupNameToId.put(memberRec.Group.Name,memberRec.GroupId);
        }
        
        List<String> groupNames = new List<String>();
        for(string contactRecId : contactIdToGroups.keySet())
        {
            groupNames.addAll(contactIdToGroups.get(contactRecId));
        }
        for(Group groupRec: [Select Id, name from Group where name in :groupNames and (not name in :groupNameToId.keySet())])
        {
            groupNameToId.put(groupRec.Name,groupRec.Id);
        }

        GroupMember groupRecord;
        for(string contactRecId : contactIdToGroups.keySet())
        {      
            for(String groupName : contactIdToGroups.get(contactRecId))      
            {
                groupRecord = new GroupMember();
                groupRecord.UserorGroupId = fedIdToId.get(contactRecId);
                groupRecord.GroupId = groupNameToId.get(groupName);
                membersToInsert.add(groupRecord);    
            }
        }

        if(membersToInsert.size() > 0)
        {
            List<Database.SaveResult> results = database.insert(membersToInsert,false);
            SC_Jarvis_utility.populateErrorTableForUpdate(results,membersToInsert,'Jarvis: Group Member Insert Error','Jarvis: Group Member Insert Error');            
        }

        if(membersToDelete.size() > 0)
        {
            database.delete(membersToDelete,false);
        }

    }
    // public static void addUserToGroups(List<String> contactsIds)
    // {
    //     Map<String,Set<String>> userToGroupNames = new Map<String,Set<String>>();
    //     List<Jarvis_Contact_ACC_Permission_Contract__c> contractPermissionRecords = [Select Customer_Permission__r.Contact__c,Customer_Permission__r.User__c,Account__c,Active__c,Contract__c,Permission__c from 
    //     Jarvis_Contact_ACC_Permission_Contract__c where Customer_Permission__r.Contact__c in :contactsIds and lastmodifieddate = last_n_days:1];
        
    //     String accessLevel;
    //     Set<String> groupNames = new Set<String>();

    //     Map<String,Set<String>> contactWithAccounts = new Map<String,Set<String>>();
    //     Set<String> accountIds = new Set<String>();
    //     Set<String> contactIdsToQuery = new Set<String>();
    //     for(Jarvis_Contact_ACC_Permission_Contract__c permissionRec : contractPermissionRecords)
    //     {
    //         if(!userToGroupNames.containsKey(permissionRec.Customer_Permission__r.User__c))
    //         {
    //             contactWithAccounts.put(permissionRec.Customer_Permission__r.Contact__c, new Set<String>());
    //             userToGroupNames.put(permissionRec.Customer_Permission__r.User__c,new Set<String>());
    //         }
            
    //         accessLevel = permissionRec.Permission__c.contains('CASE_MANAGEMENT_WRITE')?'Write' : 'Read';
    //         if(permissionRec.Active__c)
    //         {
    //             userToGroupNames.get(permissionRec.Customer_Permission__r.User__c).add('JARVIS_'+SC_Jarvis_utility.convertToEighteen(permissionRec.Contract__c) + '_' + accessLevel);
    //         }
    //         groupNames.add('JARVIS_'+SC_Jarvis_utility.convertToEighteen(permissionRec.Contract__c)+'_Read');
    //         groupNames.add('JARVIS_'+SC_Jarvis_utility.convertToEighteen(permissionRec.Contract__c)+'_Write');
    //         groupNames.add('JARVIS_'+SC_Jarvis_utility.convertToEighteen(permissionRec.Account__c));

    //         if(accessLevel == 'Write')
    //         {
    //             if(permissionRec.Active__c)
    //             {
    //                 if(contactWithAccounts.get(permissionRec.Customer_Permission__r.Contact__c).contains(permissionRec.Account__c))
    //                 {
    //                     contactWithAccounts.get(permissionRec.Customer_Permission__r.Contact__c).remove(permissionRec.Account__c);
    //                 }
    //                 userToGroupNames.get(permissionRec.Customer_Permission__r.User__c).add('JARVIS_'+SC_Jarvis_utility.convertToEighteen(permissionRec.Account__c) );
    //             }                
    //         }
    //         else 
    //         {
                
    //             if(! userToGroupNames.get(permissionRec.Customer_Permission__r.User__c).contains('JARVIS_'+SC_Jarvis_utility.convertToEighteen(permissionRec.Account__c) ))
    //             {
    //                 contactWithAccounts.get(permissionRec.Customer_Permission__r.Contact__c).add(permissionRec.Account__c);
    //             }
    //         }
    //     }
    //     for(string contactId: contactWithAccounts.keySet())
    //     {
    //         if(contactWithAccounts.get(contactId).size() > 0)
    //         {
    //             accountIds.addAll(contactWithAccounts.get(contactId));
    //             contactIdsToQuery.add(contactId);
    //         }
    //     }
    //     if(accountIds.size() > 0)
    //     {
    //         for(Jarvis_Contact_ACC_Permission_Contract__c permissionRec : [Select Customer_Permission__r.User__c,Account__c from 
    //         Jarvis_Contact_ACC_Permission_Contract__c where Customer_Permission__r.Contact__c in :contactIdsToQuery and Account__c in :accountIds and Active__c = true and Permission__c includes ('CASE_MANAGEMENT_WRITE')])
    //         {
    //             userToGroupNames.get(permissionRec.Customer_Permission__r.User__c).add('JARVIS_'+SC_Jarvis_utility.convertToEighteen(permissionRec.Account__c) );
    //         }
    //     }
    //     Map<String,String> groupIdToName = new Map<String,String>();
    //     for(Group groupRec: [Select Id, Name from Group where name in :groupNames])
    //     {
    //         groupIdToName.put(groupRec.Name, groupRec.Id);
    //     }
    //     List<GroupMember> recordsToDelete = new List<GroupMember>();
    //     List<GroupMember> recordsToInsert = new List<GroupMember>();
    //     system.debug('userToGroupNames: ' + userToGroupNames);
    //     for(GroupMember groupMemberRec : [Select Id, UserorGroupId, GroupId,Group.Name from 
    //     GroupMember where Group.Name in :groupNames and UserorGroupId in :userToGroupNames.keySet()])
    //     {
    //         if(!userToGroupNames.get(groupMemberRec.UserorGroupId).contains(groupMemberRec.Group.Name))
    //         {
    //             recordsToDelete.add(groupMemberRec);
    //         }
    //         else 
    //         {
    //             userToGroupNames.get(groupMemberRec.UserorGroupId).remove(groupMemberRec.Group.Name);
    //         }
    //     }
    //     GroupMember groupMemberRec;
    //     for(String userId: userToGroupNames.keySet())
    //     {
    //         for(String groupName: userToGroupNames.get(userId))
    //         {
    //             groupMemberRec = new GroupMember();
    //             groupMemberRec.UserorGroupId = userId;
    //             groupMemberRec.GroupId = groupIdToName.get(groupName);
    //             recordsToInsert.add(groupMemberRec);
    //         }
    //     }
    //     if(recordsToInsert.size() > 0)
    //     {
    //         //insert recordsToInsert;
    //     }
    //     if(recordsToDelete.size() > 0)
    //     {
    //         //delete recordsToDelete;
    //     }
    // }    
    
    public static void createPermissionRecords(List<SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper> responseWrappers,Set<String> contactIds)
    {
        system.debug('---responseWrappers---'+responseWrappers);
        Map<String,Jarvis_Contact_ACC_Permission_Contract__c> uniqueIdToContractExisting = new Map<String,Jarvis_Contact_ACC_Permission_Contract__c>();
        Map<String,String> contactIdToAkamId = new Map<String,String>();

        Map<String,Set<String>> userIdToGroup = new Map<String,Set<String>>();
        Map<String,Set<String>> contactIdToACR = new Map<String,Set<String>>();

        Map<String,String>contractIdsToAccountString = new Map<String,String>();
        //map to store the permission logic
        Map<String,Map<String,String>> existingPermissionMap = new Map<String,Map<String,String>>();
        Map<String,Map<String,String>> contactPermissionMap = new Map<String,Map<String,String>>();
        Set<String> attContractIds = new Set<String>();

        Set<String> contractsToQuery = new Set<String>();
        for(SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper accountContactWrapper: responseWrappers)
        {
            for(SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper contractWrapper : accountContactWrapper.authGrants)
            {
                contractsToQuery.add(contractWrapper.contractId);
            }            
        }
		String akamContractIdString;        
        for(Jarvis_Contact_ACC_Permission_Contract__c contractPermission : [Select Id, Active__c,Active_Contract__c,Permission__c,Akam_Contract_Id__c,Customer_Permission__r.Contact__r.AKAM_Contact_ID__c,
        Akam_Contact_ACC_Permission_Contract_ID__c,Customer_Permission__r.User__c,Customer_Permission__r.Contact__c,
		Contract__r.Parent_Contract__r.Account_Name__r.Akam_Account_ID__c,Contract__r.Parent_Contract__r.Account_Name__c, Contract__r.Account_Name__r.Akam_Account_ID__c, Contract__r.Contract_Type__c,
        Contract__r.Account_Name__c, Customer_Permission__r.Akamai_Case_Permission__c, Customer_Permission__r.ATT_Case_Permission__c, ATT_Contract__c, Case_Management__c, Contract__r.Jarvis_Direct_Contract__c,
        Contract__r.Jarvis_Indirect_Contract__c
		 from Jarvis_Contact_ACC_Permission_Contract__c where
        Customer_Permission__r.Contact__r.AKAM_Contact_Id__c in :contactIds and Active__c = true order by Customer_Permission__r.Contact__c,Account__c])
        {
            if(!existingPermissionMap.containsKey(contractPermission.Customer_Permission__r.Contact__r.AKAM_Contact_ID__c))
            {
                existingPermissionMap.put(contractPermission.Customer_Permission__r.Contact__r.AKAM_Contact_ID__c, new Map<String,String>());  
                existingPermissionMap.get(contractPermission.Customer_Permission__r.Contact__r.AKAM_Contact_ID__c).put('akamai',contractPermission.Customer_Permission__r.Akamai_Case_Permission__c);  
                existingPermissionMap.get(contractPermission.Customer_Permission__r.Contact__r.AKAM_Contact_ID__c).put('att',contractPermission.Customer_Permission__r.ATT_Case_Permission__c) ;  
            }
            uniqueIdToContractExisting.put(contractPermission.Customer_Permission__r.Contact__r.AKAM_Contact_ID__c+contractPermission.Akam_Contract_Id__c,contractPermission);
            contractsToQuery.remove(contractPermission.Akam_Contract_Id__c);
            if(contractPermission.ATT_Contract__c && !attContractIds.contains(contractPermission.Akam_Contract_Id__c))
            {
                attContractIds.add(contractPermission.Akam_Contract_Id__c);
            }            
            if(contractPermission.Contract__r.Jarvis_Indirect_Contract__c)
            {

                akamContractIdString = String.valueOf(contractPermission.Contract__r.Account_Name__C).substring(0, 15) + '_' +
                String.valueOf(contractPermission.Contract__r.Parent_Contract__r.Account_Name__C).substring(0, 15);
                contractIdsToAccountString.put(contractPermission.Akam_Contract_Id__c,akamContractIdString);
            }
            else if(contractPermission.Contract__r.Jarvis_Direct_Contract__c)
            {
                contractIdsToAccountString.put(contractPermission.Akam_Contract_Id__c,'');
            }
        }
        for(Merge_Contract_Header__c contractHeader : [Select ATT_Contract__c,Original_Contract_Id__c,Parent_Contract__r.Account_Name__r.Akam_Account_ID__c,
                                                    Parent_Contract__r.Account_Name__c, Account_Name__c,Jarvis_Direct_Contract__c,Jarvis_Indirect_Contract__c,
                                                       Account_Name__r.Akam_Account_ID__c, Contract_Type__c from Merge_Contract_Header__c where 
                                                       Original_Contract_Id__c in :contractsToQuery])
        {
            akamContractIdString = '';
            if(contractHeader.Jarvis_Indirect_Contract__c)
            {
                akamContractIdString = String.valueOf(contractHeader.Account_Name__c).substring(0, 15) + '_' +
                String.valueOf(contractHeader.Parent_Contract__r.Account_Name__c).substring(0, 15);
                contractIdsToAccountString.put(contractHeader.Original_Contract_Id__c,akamContractIdString);
            }
            else if(contractHeader.Jarvis_Direct_Contract__c)
            {
            	contractIdsToAccountString.put(contractHeader.Original_Contract_Id__c,akamContractIdString);    
            }
            if(contractHeader.ATT_Contract__c)
            {
                attContractIds.add(contractHeader.Original_Contract_Id__c);
            }
        }
        List<Jarvis_Contact_ACC_Permission_Contract__c> recordsForUpsert = new List<Jarvis_Contact_ACC_Permission_Contract__c>();
        Jarvis_Contact_ACC_Permission_Contract__c permissionRecord;
        String mapKey;
        String permission = '';
        Merge_Contract_Header__c mergeContractLookup;
        Account accountLookup;
        String accessLevel;
        String currentGroupName;
        String readGroupName;
        String writeGroupName;
        system.debug('responseWrappers' + JSON.serialize(responseWrappers));
        for(SC_Jarvis_Contact_ACC_Permission_Handler.AccountContactPermissionWrapper accountContactWrapper: responseWrappers)
        {
            contactIdToAkamId.put(accountContactWrapper.contactSalesforceId,accountContactWrapper.contactId);
            if(accountContactWrapper.accountId == null)
            {
                system.debug('ACCOUNT NULL' + accountContactWrapper);
            }
            for(SC_Jarvis_Contact_ACC_Permission_Handler.ContractPermissionWrapper contractWrapper : accountContactWrapper.authGrants)
            {
                mapKey = accountContactWrapper.contactId + contractWrapper.contractId;
                if(contractWrapper.scopes != null)
                {
                    permission = String.join( contractWrapper.scopes, ';' );
                    if(uniqueIdToContractExisting.containsKey(mapKey) )
                    {   
                        permissionRecord = uniqueIdToContractExisting.get(mapKey);
    
                        if(permissionRecord.Permission__c != permission)
                        {
                            System.debug('ADDING!!!!'  + permissionRecord.Permission__c );
                            System.debug(':::permission::' + permission);                            
                            permissionRecord.Permission__c = permission;

                            // mergeContractLookup = new Merge_Contract_Header__c();
                            // mergeContractLookup.Original_Contract_Id__c = contractWrapper.contractId;
                            // permissionRecord.Contract__r = mergeContractLookup;
    
                            permissionRecord.Case_Management__c = String.isBlank(permission) ? 'None' : 
                            permission.contains('WRITE') ? 'Create': 
                            ((permission.contains('READ') || permission.contains('UPDATE'))? 'View' : 'None');
                            
                            recordsForUpsert.add(permissionRecord);
                        }
                        uniqueIdToContractExisting.remove(mapKey);                        
        
                    }
                    else 
                    {
                        //system.debug('HEREEEE');
                        permissionRecord = new Jarvis_Contact_ACC_Permission_Contract__c();
                        permissionRecord.Permission__c = permission;
                        permissionRecord.Case_Management__c = String.isBlank(permission) ? 'None' : 
                        permission.contains('WRITE') ? 'Create': 
                        ((permission.contains('READ')|| permission.contains('UPDATE')) ? 'View' 
                        : 'None');

                        permissionRecord.Customer_Permission__c = accountContactWrapper.parentId;
                        permissionRecord.Active__c =true;
    
                        mergeContractLookup = new Merge_Contract_Header__c();
                        mergeContractLookup.Original_Contract_Id__c = contractWrapper.contractId;
                        permissionRecord.Contract__r = mergeContractLookup;
    
                        accountLookup = new Account();
                        accountLookup.AkAM_Account_Id__c = accountContactWrapper.accountId;
                        permissionRecord.Account__r = accountLookup;
    
                        permissionRecord.Akam_Contract_Id__c = contractWrapper.contractId;
                        permissionRecord.Akam_Contact_ACC_Permission_Contract_ID__c = mapKey;
    
                        //system.debug('recordsForUpsert: ' + recordsForUpsert);
                        recordsForUpsert.add(permissionRecord);
                            
                    }
                    if(!userIdToGroup.containsKey(accountContactWrapper.contactId))
                    {
                        userIdToGroup.put(accountContactWrapper.contactId,new Set<String> ());
                    }
                    
                    accessLevel = SC_Jarvis_utility.getAccessLevel(permission);
                    if(accessLevel != 'NONE')
                    {
                        currentGroupName = SC_Jarvis_utility.prepareGroupName('JARVIS_CONTRACT' + contractWrapper.contractId + accessLevel);                    
                        if(!userIdToGroup.get(accountContactWrapper.contactId).contains(currentGroupName))
                        {
                            userIdToGroup.get(accountContactWrapper.contactId).add(currentGroupName);
                        }
                        
                        if(!contactIdToACR.containsKey(accountContactWrapper.contactSalesforceId))
                        {
                            contactIdToACR.put(accountContactWrapper.contactSalesforceId,new Set<String> ());
                        }
                        if(contractIdsToAccountString.containsKey(contractWrapper.contractId))
                        {
                            if(contractIdsToAccountString.get(contractWrapper.contractId) == '')
                            {
                                currentGroupName = SC_Jarvis_utility.prepareGroupName('JARVIS_ACCOUNT' + accountContactWrapper.accountId);
                                if(accessLevel.contains('WRITE') && !userIdToGroup.get(accountContactWrapper.contactId).contains(currentGroupName))
                                {
                                    userIdToGroup.get(accountContactWrapper.contactId).add(currentGroupName);
                                } 
                                if(!contactIdToACR.get(accountContactWrapper.contactSalesforceId).contains(accountContactWrapper.accountId))
                                {
                                    contactIdToACR.get(accountContactWrapper.contactSalesforceId).add(accountContactWrapper.accountId);
                                }
                                
                            }
                            else
                            {
                                readGroupName = SC_Jarvis_utility.prepareGroupName('JA_' + contractIdsToAccountString.get(contractWrapper.contractId) + '_R');
                                writeGroupName = SC_Jarvis_utility.prepareGroupName('JA_' + contractIdsToAccountString.get(contractWrapper.contractId) + '_W');
                                if(accessLevel.contains('WRITE'))
                                {
                                    if(userIdToGroup.get(accountContactWrapper.contactId).contains(readGroupName))
                                    {
                                        userIdToGroup.get(accountContactWrapper.contactId).remove(readGroupName);
                                    }
                                    if(!userIdToGroup.get(accountContactWrapper.contactId).contains(writeGroupName))
                                    {
                                        userIdToGroup.get(accountContactWrapper.contactId).add(writeGroupName);
                                    }
                                }
                                else if(!userIdToGroup.get(accountContactWrapper.contactId).contains(readGroupName) &&
                                       !userIdToGroup.get(accountContactWrapper.contactId).contains(writeGroupName))
                                {
                                    userIdToGroup.get(accountContactWrapper.contactId).add(readGroupName);
                                }
                            }
                        }
        
                    }
                    
                    if(!contactPermissionMap.containsKey(accountContactWrapper.contactId))
                    {
                        contactPermissionMap.put(accountContactWrapper.contactId, new Map<String,String>());   
                        contactPermissionMap.get(accountContactWrapper.contactId).put('akamai','None');
                        contactPermissionMap.get(accountContactWrapper.contactId).put('att','None');                                                                    
                    }
                    if ( attContractIds.contains(contractWrapper.contractId) && 
                    SC_Jarvis_utility.getPermissionWeight(contactPermissionMap.get(accountContactWrapper.contactId).get('att')) <  SC_Jarvis_utility.getPermissionWeight(permissionRecord.Case_Management__c))
                    {
                        contactPermissionMap.get(accountContactWrapper.contactId).put('att',permissionRecord.Case_Management__c);
                    }
                    else if(!attContractIds.contains(contractWrapper.contractId) && 
                    SC_Jarvis_utility.getPermissionWeight(contactPermissionMap.get(accountContactWrapper.contactId).get('akamai')) <  SC_Jarvis_utility.getPermissionWeight(permissionRecord.Case_Management__c))
                    {
                        contactPermissionMap.get(accountContactWrapper.contactId).put('akamai',permissionRecord.Case_Management__c);
                    }
                
                        
                }

            }                                
        }
        system.debug('contactIdToACR: ' + contactIdToACR);
        if(uniqueIdToContractExisting.size() > 0)
        {
            for(String uniqueKey : uniqueIdToContractExisting.keySet())
            {
                permissionRecord = uniqueIdToContractExisting.get(uniqueKey);
                //if(permissionRecord.Active_Contract__c)
                {
                    permissionRecord.Active__c = false;
                    recordsForUpsert.add(permissionRecord);
                }
            }
        }
        if(recordsForUpsert.size() > 0)
        {
            system.debug('contactIdToACR: ' + contactIdToACR);
            List<Database.UpsertResult> results = Database.upsert(recordsForUpsert , Jarvis_Contact_ACC_Permission_Contract__c.Akam_Contact_ACC_Permission_Contract_ID__c, false);
            SC_Jarvis_utility.populateErrorTableForUpsert(results,recordsForUpsert,'Jarvis: Permission Upsert Error','Jarvis: Permission Upsert Error');

            List<Jarvis_Contact_ACC_Permission__c> permissionRecordsToUpsert = new List<Jarvis_Contact_ACC_Permission__c>();
            Jarvis_Contact_ACC_Permission__c permissionRecordInstance;
            if(contactPermissionMap.size() > 0)
            {
                for(String contactid: contactPermissionMap.keySet())
                {
                    if(
                        (
                            existingPermissionMap.size() > 0 && existingPermissionMap.containsKey(contactid) && 
                            (
                                contactPermissionMap.get(contactid).get('akamai') != existingPermissionMap.get(contactid).get('akamai') ||
                                contactPermissionMap.get(contactid).get('att') != existingPermissionMap.get(contactid).get('att')
                            )
                        )
                        ||
                        existingPermissionMap.size() == 0 
                        || 
                        !existingPermissionMap.containsKey(contactid)   
                    )
                    {
                        permissionRecordInstance = new Jarvis_Contact_ACC_Permission__c();
                        permissionRecordInstance.ATT_Case_Permission__c = contactPermissionMap.get(contactid).get('att');
                        permissionRecordInstance.Akamai_Case_Permission__c = contactPermissionMap.get(contactid).get('akamai');
                        permissionRecordInstance.Akam_Contact_ACC_Permission_Id__c = contactid;
                        permissionRecordsToUpsert.add(permissionRecordInstance);
                    }
                    if(existingPermissionMap.size() > 0 && existingPermissionMap.containsKey(contactid))
                    {
                        existingPermissionMap.remove(contactid);
                    }
                }
            }

            if(existingPermissionMap.size() > 0)
            {
                for(String contactid: existingPermissionMap.keySet())
                {
                    permissionRecordInstance = new Jarvis_Contact_ACC_Permission__c();
                    permissionRecordInstance.ATT_Case_Permission__c = 'None';
                    permissionRecordInstance.Akamai_Case_Permission__c = 'None';
                    permissionRecordInstance.Akam_Contact_ACC_Permission_Id__c = contactid;
                    permissionRecordsToUpsert.add(permissionRecordInstance);
                }
            }
            if(permissionRecordsToUpsert.size() > 0)
            {
                SC_Jarvis_Contact_ACC_Permission_Handler.recursionCheck = true;
                results = Database.upsert(permissionRecordsToUpsert , Jarvis_Contact_ACC_Permission__c.Akam_Contact_ACC_Permission_Id__c, false);
                SC_Jarvis_utility.populateErrorTableForUpsert(results,recordsForUpsert,'Jarvis: Case Management Permission Upsert Error','Jarvis: Case Management Permission Upsert Error');
            }
    
            List<AccountContactRelation> acrRecordsToUpsert = new List<AccountContactRelation>();
            List<AccountContactRelation> acrRecordsToUpdate = new List<AccountContactRelation>();
            //List<AccountContactRelation> acrRecordsToInsert = new List<AccountContactRelation>();
            AccountContactRelation recordToInsert;
            Set<String> accountIds = new Set<String>();
            for(AccountContactRelation acrRecord: [Select Id,Account.Akam_Account_id__c,AKAM_Account_Contact_Id__c, ContactId,Contact.Akam_Contact_Id__c,IsActive  
            from AccountContactRelation where ContactId in :contactIdToACR.keySet() and (IsActive = true or AKAM_Account_Contact_Id__c = null)])
            {

                if(contactIdToACR != null && contactIdToACR.containsKey(acrRecord.ContactId) &&
                   contactIdToACR.get(acrRecord.ContactId) != null && 
                   !contactIdToACR.get(acrRecord.ContactId).contains(acrRecord.Account.Akam_Account_id__c))
                {
                    if(acrRecord.IsActive || acrRecord.AKAM_Account_Contact_Id__c == null)
                    {
                        acrRecord.AKAM_Account_Contact_Id__c = acrRecord.AKAM_Account_Contact_Id__c == null?
                        acrRecord.Account.Akam_Account_id__c + Contact.Akam_Contact_Id__c: acrRecord.AKAM_Account_Contact_Id__c;
                        acrRecord.IsActive = false;
                        acrRecordsToUpdate.add(acrRecord);
                    }
                }
                else if(contactIdToACR != null && contactIdToACR.containsKey(acrRecord.ContactId) &&
                   contactIdToACR.get(acrRecord.ContactId) != null && 
                        contactIdToACR.get(acrRecord.ContactId).contains(acrRecord.Account.Akam_Account_id__c))
                {
                    if(!acrRecord.IsActive || acrRecord.AKAM_Account_Contact_Id__c == null)
                    {
                        acrRecord.AKAM_Account_Contact_Id__c = acrRecord.AKAM_Account_Contact_Id__c == null?
                        acrRecord.Account.Akam_Account_id__c + Contact.Akam_Contact_Id__c: acrRecord.AKAM_Account_Contact_Id__c;
                        acrRecord.IsActive = true;
                        acrRecordsToUpdate.add(acrRecord);    
                    }
                    contactIdToACR.get(acrRecord.ContactId).remove(acrRecord.Account.Akam_Account_id__c);
                    if(contactIdToACR.get(acrRecord.ContactId).size() == 0)
                    {
                        contactIdToACR.remove(acrRecord.ContactId);
                    }
                }
            }
            //system.debug('acrRecordsToUpdate: ' + acrRecordsToUpdate);
            Account accountPointer;
            for(String contactId : contactIdToACR.keySet())
            {                
                for(String accountId: contactIdToACR.get(contactId))
                {
                    if(accountId != null)
                    {
                        recordToInsert= new AccountContactRelation();
                        recordToInsert.isActive = true;
                        recordToInsert.contactid = contactId;
                        recordToInsert.EndDate = Date.today().addYears(100);
                        recordToInsert.StartDate = Date.today().addDays(-2);
                        recordToInsert.Application__c = 'JARVIS';
                        accountPointer = new Account();
                        accountPointer.Akam_Account_Id__c = accountId;
    
                        recordToInsert.account = accountPointer;
                        recordToInsert.AKAM_Account_Contact_Id__c = accountId + contactIdToAkamId.get(contactId);
    
                        acrRecordsToUpsert.add(recordToInsert);
    
                    }
                }
            }
            if(acrRecordsToUpsert.size() > 0)
            {
                results = Database.upsert(acrRecordsToUpsert , AccountContactRelation.AKAM_Account_Contact_Id__c, false);
                SC_Jarvis_utility.populateErrorTableForUpsert(results,acrRecordsToUpsert,'Jarvis: ACR Upsert Error','Jarvis: ACR Upsert Error');
                //Database.update(acrRecordsToUpdate, true);
            }
            if(acrRecordsToUpdate.size() > 0)
            {
                List<Database.SaveResult> saveResults = Database.update(acrRecordsToUpdate,false);
                SC_Jarvis_utility.populateErrorTableForUpdate(saveResults,acrRecordsToUpdate,'Jarvis: ACR Update Error','Jarvis: ACR Update Error');
            }
            
            if(userIdToGroup.size() > 0)
            {
                addUserToGroups(JSON.serialize(userIdToGroup));
            }
        }    
     
    }

    public class ContactPermissionWrapper
    {
        public String contactId;
        public String akamContactId;
        public String userId;
        public String login;
        public ContactPermissionWrapper(string contactIdString, String akamId, String userIdString, String loginName)
        {
            contactId = contactIdString;
            akamContactId = akamId;
            userId = userIdString;
            login = loginName;
        }
    }

    @future(callout=true)
    public static void getIdmPermissionFuture(String wrapperString)
    {
        if(wrapperString != null)
        {
            List<ContactPermissionWrapper> wrappers = (List<ContactPermissionWrapper>)JSON.deserialize(wrapperString,List<ContactPermissionWrapper>.class);
            getIdmPermission(wrappers);    
    
        }
    }
    
    public class MuleInputWrapper
    {
        public Boolean async;
        public List<ContactPermissionWrapper> contacts;
        public MuleInputWrapper(Boolean async,List<ContactPermissionWrapper> contacts)
        {
            this.async = async;
            this.contacts = contacts;
        }
    }

    public static String getAccessToken(SC_Case_Issue_Sync_Admin_Setting__c ipScrub)
    {
        String oAuthEndpoint = ipScrub.Hostname_Issues_API__c + ipScrub.Oauth_Endpoint_Issues_API__c; 
        //The client Id
        String clientId = ipScrub.Client_Id_Issues_API__c;
        //The client secret
        String clientSecret = ipScrub.Client_Secret_Issues_API__c;    
        //The scope: WRITE_ISSUES 
        String scope = ipScrub.Jarvis_IDM_Scope__c;
        if(Test.isRunningTest())
        {
            scope = scope == null? '123':scope;
        }
        //The certificate to connect: EAA_KMI_Signed_Certificate
        String certificate = ipScrub.Client_Certificate__c;
        
		Http http = new Http();
        HttpRequest request = new HttpRequest();     
        String accessToken = '';       
        HttpResponse response;
	
        //Create the new request: to get the token
        request.setEndpoint(oAuthEndpoint);
        request.setMethod('GET');
        request.setHeader('client_id', clientId);
        request.setHeader('client_secret',clientSecret);
        request.setHeader('Content-Type','application/json');
        request.setHeader('grant_type','client_credentials');
        request.setHeader('scope',scope);
        request.setClientCertificateName(certificate);
		        
        try
        {
            //Get the response
            response = http.send(request);        
            
    		//If the request is successful: assign the token to the accessToken variable
            if (response.getStatusCode() == 200) 
            {    
                Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());    
                accessToken = (String) results.get('access_token');   
                //System.debug('## access_token '+ accessToken);
            }
            else
            {
                //If the request status is not 200: Send a mail with the error body
                SC_Jarvis_utility.sendErrorMails('Jarvis Error Getting Access Token! Exception','Exception: ', response.getBody());
                // PSA_AutoCreateProjectUtil.sendErrorMails('Siebel Activity Sync: Error Getting Access Token!',
                //     response.getBody());
                
            }
            
        }
        catch(Exception e)
        {
            SC_Jarvis_utility.sendErrorMails('Jarvis Error Getting Access Token! Exception','Exception: ', e.getMessage());
            //If the request fails: Send a mail with the error body
            // PSA_AutoCreateProjectUtil.sendErrorMails('Siebel Activity Sync: Error Getting Access Token!',
            //         e.getMessage());            
        }
        return accessToken;

    }

    public static void getIdmPermission(List<ContactPermissionWrapper> wrappers)
    {
        if(wrappers == null || wrappers.size() == 0)
        {
            return;
        }
        Boolean asyncContext = wrappers.size() > 1 ? true : false;
        Boolean gotToken = false;
        String accessToken;
        MuleInputWrapper muleWrapper = new MuleInputWrapper(asyncContext,wrappers);
        //The HTTP connector
        Http http;
        //The Request object
        HttpRequest request;            
        //The Response object
        HttpResponse response;
        
        Id profileId = [SELECT Id FROM Profile WHERE name = 'System Administrator'].Id;
        SC_Case_Issue_Sync_Admin_Setting__c ipScrub = SC_Case_Issue_Sync_Admin_Setting__c.getInstance(profileId);
        String certificate = ipScrub.Client_Certificate__c; 

        if(ipScrub.Jarvis_Access_Token__c == null || ipScrub.Jarvis_Token_Expiry_Datetime__c == null ||
        Datetime.now() >= ipScrub.Jarvis_Token_Expiry_Datetime__c )
        {
            accessToken = getAccessToken(ipScrub);
            gotToken = true;
        }
        else
        {
            accessToken = ipScrub.Jarvis_Access_Token__c;
        }
        if(String.isBlank(accessToken))
        {
            return;
        }
        List<String> responseList = new List<String>();

        String endpoint = ipScrub.Hostname_Issues_API__c + ipScrub.Get_API_Jarvis__c;
        String postString = JSON.serialize(muleWrapper);      

        //create the Http Request
        http = new Http();
        request = new HttpRequest();                    
        request.setMethod('POST');
        request.setHeader('Content-Type','application/json');
        request.setHeader('access_token',accessToken);
        
        system.debug('The endpoint: ' + endPoint + 'postString: ' + postString);
        
        //request.setTimeout(4000);
        request.setEndpoint(endPoint);
        request.setBody(postString);
        request.setClientCertificateName(certificate);
        
        try
        {
            //Get the response
            //system.debug('The endpoint: ' + system.);
            Datetime startTime = system.now();
            response = http.send(request);
            Datetime endTime = system.now();
            if(response.getStatusCode() != 200)
            {
                //system.debug('response: ' + response.getBody());
                if(!gotToken && response.getStatusCode() == 403 && response.getStatus() == 'Forbidden')
                {
                    System.debug('new token!');
                    accessToken = getAccessToken(ipScrub);
                    gotToken = true;
                   
                    http = new Http();
                    request = new HttpRequest();                    
                    request.setMethod('POST');
                    request.setHeader('Content-Type','application/json');
                    request.setHeader('access_token',accessToken);
                    
                    //system.debug('The endpoint: ' + endPoint + 'postString: ' + postString);
                    
                    //request.setTimeout(4000);
                    request.setEndpoint(endPoint);
                    request.setBody(postString);
                    request.setClientCertificateName(certificate);
                    response = http.send(request);
                }
                else 
                {
                    SC_Jarvis_utility.sendErrorMails('Jarvis IDM Permission API Exception','Exception: ' + response.getStatusCode() + ': ' +  response.getStatus(), response.getBody());      
                }                
            }
            system.debug('response: ' + response);
            system.debug('time: ' + ((endTime.getTime() - startTime.getTime())/1000));
        }
        catch(Exception e)
        {
            SC_Jarvis_utility.sendErrorMails('Jarvis IDM Permission API Exception','Exception: ' + postString, e.getMessage());
            system.debug('exception: ' + e.getMessage());
        }
        if(gotToken)
        {
            ipScrub.Jarvis_Access_Token__c = accessToken;
            ipScrub.Jarvis_Token_Expiry_Datetime__c = Datetime.now().addHours(12);
            update ipScrub;
        }        
    }

    public class CreateUserWrapper
    {
        public List<ContactPermissionWrapper> wrappers;
        public Boolean upserted;
        public CreateUserWrapper(List<ContactPermissionWrapper> wrappers, Boolean upserted)
        {
            this.wrappers = wrappers;
            this.upserted = upserted;
        }
    }
    
    public Static Boolean isOneTimeSync=false;
    public static CreateUserWrapper checkForUser (List<String> contactIds)
    {
        system.debug('Queue Start: ');
        if(contactIds == null || contactIds.size() == 0)
        {
            return null;
        }
        Boolean updated = false;
        SFCommunity_NQLB_Topics__mdt communityMdt = [SELECT PartnerProfileId__c, PartnerCommunityProfileId__c, CustomerProfileId__c,PartnerPermissionSet__c,EmployeePermissionSet__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];        
        List<SC_Jarvis_CoreSecurityController.ContactPermissionWrapper> wrappers = new List<SC_Jarvis_CoreSecurityController.ContactPermissionWrapper>();
        List<User> usersToUpdate = new List<User>();
        List<User> usersToInsert = new List<User>();
        List<PermissionSetAssignment> permissionSets= new List<PermissionSetAssignment>();
        List<Database.SaveResult> results;
        Map<String,String> userIdtoPermissionSet = new Map<String,String>();



        map<string, contact> idToContact = new map<string, contact>();
        for(Contact contact: [select id,email, akam_contact_id__c, phone,firstname,lastname,title,account.name, Login__c
        from contact where id in :contactIds and login__c != null])
        {
            idToContact.put(contact.akam_contact_id__c,contact);
        }
        system.debug('idToContact: ' + idToContact);
        if(idToContact.size() > 0)
        {
            User loggedInUser = getLoggedInUser();
            User recordToInsert;

            Contact currentContactRec;
            String currentContactId;
            for(User currentUser: [Select id,contact.login__c,contactId,email,AKAM_User_Id__c,Profile.Name,ProfileId,Contact.AKAM_Contact_Id__c,
            Profile.UserLicense.Name,isActive from User where Contact.AKAM_Contact_Id__c in :idToContact.keyset() or AKAM_User_id__c in :idToContact.keyset() ])
            {
                currentContactId = currentUser.ContactId != null? currentUser.Contact.AKAM_Contact_Id__c : currentUser.AKAM_User_id__c;
                if(currentContactId != null && idToContact.get(currentContactId) != null)
                {
                    currentContactRec = idToContact.get(currentContactId);
                    updated = false;
                    system.debug('currentContactId: ' + currentContactId);
                    system.debug('currentContactRec: ' + currentContactRec);
                    if(!currentUser.isActive && currentUser.Profile.UserLicense.Name != 'Partner Community')
                    {
                        updated = true;
                        currentUser.isactive = true;
                    }
                    if(currentContactRec.Email != null && currentContactRec.Email.contains('@akamai.com') && currentContactRec.Account.Name.contains('Akamai Technologies - Assets'))
                    {
                        system.debug('currentUser.Profile.UserLicense.Name: ' + currentUser.Profile.UserLicense.Name);
                        if(currentUser.Profile.UserLicense.Name == 'Salesforce')
                        {
                            userIdtoPermissionSet.put(currentUser.Id,communityMdt.EmployeePermissionSet__c);
                        }
                        else 
                        {
                            userIdtoPermissionSet.put(currentUser.Id,communityMdt.PartnerPermissionSet__c);
                        }
                    }
                    else if(currentUser.ProfileId != communityMdt.CustomerProfileId__c && !string.valueOf(currentUser.ProfileId).contains(communityMdt.CustomerProfileId__c)
                    && currentUser.Profile.UserLicense.Name == 'Customer Community Plus Login' && !isOneTimeSync)
                    {
                        currentUser.ProfileId = communityMdt.CustomerProfileId__c;
                        updated = true;
                    }
                    if(updated)
                    {
                        usersToUpdate.add(currentUser);
                    }
                    if(currentUser.Profile.UserLicense.Name == 'Customer Community Plus Login' || 
                    currentUser.Profile.UserLicense.Name == 'Partner Community') 
                    {          
                        system.debug('currentUser.Profile.UserLicense.Name: ' + currentUser.Profile.UserLicense.Name);
                        wrappers.add(new SC_Jarvis_CoreSecurityController.ContactPermissionWrapper(currentUser.contactId,currentUser.Contact.AKAM_Contact_Id__c,currentUser.Id,currentUser.contact.Login__c));                
                        system.debug('wrappers: ' + wrappers);                              
                    }
                    idToContact.remove(currentContactId);
    
                }
            }
            if(idToContact.size() > 0)
            {
                for(Contact contactRec: idToContact.values())
                {
                    if(contactRec.Email != null && 
                    contactRec.AccountId != null && 
                    !contactRec.Email.contains('@akamai.com') && 
                    !contactRec.Account.Name.contains('Akamai Technologies - Assets'))
                    {
                        recordToInsert = createNewCustomerUser(contactRec, loggedInUser, communityMdt.CustomerProfileId__c);
                        if(recordToInsert != null)
                        {
                            usersToInsert.add(recordToInsert);                        
                        }
    
                    }

                }
            }
            if(usersToUpdate.size() > 0)
            {
                results = database.update(usersToUpdate, false);
                SC_Jarvis_utility.populateErrorTableForUpdate(results,usersToUpdate,'Jarvis: User Update','Jarvis: User Update');
            }
            if(usersToInsert.size() > 0)
            {
                results = database.insert(usersToInsert, false);
                SC_Jarvis_utility.populateErrorTableForUpdate(results,usersToInsert,'Jarvis: User Insert','Jarvis: User Insert');                
            }
            for(user userRec: usersToInsert)
            {
                system.debug('userRec: ' + userRec);
                wrappers.add(new SC_Jarvis_CoreSecurityController.ContactPermissionWrapper(userRec.contactId,userRec.AKAM_User_Id__c,userRec.Id,idToContact.get(userRec.AKAM_User_Id__c).Login__c));                
                system.debug('wrappers: ' + wrappers);
            }

            if(userIdtoPermissionSet.size() > 0)
            {
                system.debug('userIdtoPermissionSet: ' + userIdtoPermissionSet);
                PermissionSetAssignment permissionSetRecord;
                for(PermissionSetAssignment permissionAssignment :  [SELECT AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE 
                (PermissionSetId =: communityMdt.EmployeePermissionSet__c or PermissionSetId =: communityMdt.PartnerPermissionSet__c) 
                and AssigneeId =: userIdtoPermissionSet.keySet()])
                {
                    if(userIdtoPermissionSet.containsKey(permissionAssignment.AssigneeId))
                    {
                        userIdtoPermissionSet.remove(permissionAssignment.AssigneeId);
                    }
                }
                system.debug('userIdtoPermissionSet: ' + userIdtoPermissionSet);
                for(String userId: userIdtoPermissionSet.keySet())
                {
                    permissionSetRecord = new PermissionSetAssignment();
                    permissionSetRecord.AssigneeId = userId;
                    permissionSetRecord.PermissionSetId = userIdtoPermissionSet.get(userId);
                    permissionSets.add(permissionSetRecord);
                }
                if(permissionSets.size() > 0)
                {
                    system.debug('permissionSets: ' + permissionSets);                    
                    results = Database.insert(permissionSets,false);
                    SC_Jarvis_utility.populateErrorTableForUpdate(results,permissionSets,'Jarvis: PermissionSet Insert','Jarvis: PermissionSet Insert');                

                }
            }
        }
        Boolean upserted = usersToUpdate.size() > 0 || usersToInsert.size() > 0 || permissionSets.size() > 0? true: false;
        CreateUserWrapper userWrapper = new CreateUserWrapper(wrappers,upserted);
        return userWrapper;
    }

    public static user createNewCustomerUser (Contact contactrec, User userRecord, String profileId)
    {
        user userRec = new user();
        userRec.Username = contactrec != null ?contactrec.email : userRecord.Username;
        userRec.AKAM_User_Id__c = contactrec != null ?contactrec.akam_contact_id__c : userRecord.AKAM_User_Id__c;
        userRec.FederationIdentifier = contactrec != null ?contactrec.akam_contact_id__c : userRecord.FederationIdentifier;
        userRec.contactId = contactrec != null ?contactrec.Id : userRecord.contactId;
        userRec.Phone = contactrec != null ?contactrec.phone : userRecord.Phone;
        userRec.Email = contactrec != null ?contactrec.email : userRecord.Email;
        userRec.FirstName = contactrec != null ?contactrec.firstname : userRecord.FirstName;
        userRec.LastName = contactrec != null ?contactrec.LastName : userRecord.LastName;
        userRec.Title = contactrec != null ?contactrec.title : userRecord.Title;
        userRec.CompanyName = contactrec != null ?contactrec.account.name : userRecord.CompanyName;
        String alias = '';
        if(userRec.FirstName == null) 
        {
            alias = userRec.LastName.length() > 4 ? 'CCM-' + userRec.LastName.substring(0, 3) : 'CCM-'+userRec.LastName;
        } 
        else 
        {
            alias = userRec.LastName.length() > 4 ? 'CCM-' + userRec.FirstName.charAt(0) + userRec.LastName.substring(0, 3) : 'CCM-' +  userRec.FirstName.charAt(0) + userRec.LastName ;
        }
        if(alias.length() > 8) 
        {
            alias = alias.substring(0, 7);
        }
        userRec.Alias = alias;
        
        userRec.LocaleSidKey = userRecord.LocaleSidKey;
        userRec.LanguageLocaleKey = userRecord.LanguageLocaleKey;
        userRec.TimeZoneSidKey = userRecord.TimeZoneSidKey;
        userRec.EmailEncodingKey = userRecord.EmailEncodingKey;
        userRec.ProfileId = profileId;
        
        return userRec;
    }

    public static void customerDeprovisionLogic(List<string> userIds)
    {
        SFCommunity_NQLB_Topics__mdt  communityMdt = [SELECT PartnerProfileId__c, PartnerCommunityProfileId__c, CustomerProfileId__c,GuestProfileId__c,Guest_Profile__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];        
        
        list<user> usersToUpdate = new list<user>();
        //List<User> usersToInsert = new List<User>();
        User recordToInsert;
        
        for(user eachuserrec : [select id,profileId,Profile.Name,Profile.UserLicense.Name,Username ,AKAM_User_Id__c ,FederationIdentifier ,contactId ,Phone ,Email ,FirstName ,LastName ,Title ,CompanyName ,Alias ,LocaleSidKey ,LanguageLocaleKey ,TimeZoneSidKey ,EmailEncodingKey 
        from user where Id IN :userIds and isactive = true and Profile.UserLicense.Name = 'Customer Community Plus Login' and
        Profile.Name != :communityMdt.Guest_Profile__c])
        {
                eachuserrec.profileId = communityMdt.GuestProfileId__c;
                usersToUpdate.add(eachuserrec);
        }
        list<groupmember> groupmemberstobedeleted = new list<groupmember>();
        
        for(groupmember eachgrpmemrec : [select id from groupmember where group.name like 'JARVIS_%' and UserOrGroupId IN :userids])
        {
            groupmemberstobedeleted.add(eachgrpmemrec);
        }
        
        if(usersToUpdate.size() > 0)
        {
            List<Database.SaveResult> results = Database.update(usersToUpdate,false);
            SC_Jarvis_utility.populateErrorTableForUpdate(results,usersToUpdate,'Jarvis: User Deprovision Error ','Jarvis: User Deprovision Error');
        }

        if(groupmemberstobedeleted.size() > 0)
        {
            try
            {
                delete groupmemberstobedeleted;
            }            
            catch(Exception e)
            {
                SC_Jarvis_utility.sendErrorMails('Jarvis Group Member Delete Error','Exception: ' , e.getMessage());
            }
        }        
    }

    public static user getLoggedInUser()
    {
        String userId = UserInfo.getUserId();
        return [SELECT LocaleSidKey, LanguageLocaleKey, TimeZoneSidKey, EmailEncodingKey FROM User WHERE Id=:userId];

    }

    public static void forceSyncPermissions(Set<Jarvis_Contact_ACC_Permission__c> forceSyncRecords)
    {
        Set<Id> contactIds = new Set<Id>();
        List<ContactPermissionWrapper> wrappers = new List<ContactPermissionWrapper>();
        for(Jarvis_Contact_ACC_Permission__c permissionRec : forceSyncRecords)
        {
            contactIds.add(permissionRec.Contact__c);
            wrappers.add(new ContactPermissionWrapper(
                permissionRec.Contact__c,permissionRec.Akam_Contact_Id__c,permissionRec.User__c,
                permissionRec.Contact_Login__c));
        }
        List<AccountContactRelation> acrs = new List<AccountContactRelation>();
        for(AccountContactRelation acr : [select AKAM_Account_Contact_Id__c, Akam_Contact_Id__c,Akam_Account_Id__c
         from AccountContactRelation where AKAM_Account_Contact_Id__c = null  and Application__c != 'JARVIS' and 
         contactId in :contactIds])
        {
            acr.AKAM_Account_Contact_Id__c = acr.Akam_Account_Id__c + acr.Akam_Contact_Id__c;
            acrs.add(acr);
        }
        if(acrs.size() > 0)
        {
            
            List<Database.SaveResult> results = database.update(acrs,false);
            SC_Jarvis_utility.populateErrorTableForUpdate(results,acrs,'Jarvis: Account Contact Relation','Jarvis: Account Contact Relation Update Force Sync');

        }
        if(wrappers.size() > 0)
        {
            getIdmPermissionFuture(JSON.serialize(wrappers));
        }
        
        

    }
}