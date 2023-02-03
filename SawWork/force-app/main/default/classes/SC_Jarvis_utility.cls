/*
Author          : Sumukh SS/Sharath P
Description     : Utility Class for JARVIS

WARNING : THIS IS A CUSTOMER FACING APEX CLASS. PLEASE PERFORM ALL CODE REVIEWS WITH REQUIRED TEAM MEMBERS BEFORE
DEPLOYING CODE TO PRODUCTION.

Date                    Developer                   JIRA #                      Description                                                       
------------------------------------------------------------------------------------------------------------------------------
25 Jan 2021             Authors                     							Initial Development
01 Dec 2021				Harshil						ESESP-6070					Added function to calc #days since case closed
01 Dec 2021				Vamsee						ESESP-5691					File Size flag against Case
12 May 2022				Harshil						ESESP-7212					Populate origin Ccaddress in ack mail (based on mdt)
06 Jun 2022				Vamsee						ESESP-7043					Parent Account field for AMG & Billing
------------------------------------------------------------------------------------------------------------------------------
*/
public without sharing class SC_Jarvis_utility 
{
    public SC_Jarvis_utility() 
    {

    }

    public static Map<String,List<String>> keyToSeverityValues;
    // public static List<Account> getAccountRecords(String contactId)
    // {
    //     Set<Id> accountIds =  new Set<Id>();
    //     List<Account> accountRecs = new List<Account>();
    //     Account accountRec;
    //     if(contactId != null)
    //     {
    //         for(AccountContactRelation accountContactRec : [Select AccountId, Account.name, Account.Akam_Account_id__c from AccountContactRelation where ContactId = :contactId and IsActive = true])
    //         {
    //             if(!accountIds.contains(accountContactRec.AccountId))
    //             {
    //                 accountRec = new Account(Name=accountContactRec.Account.name,Id=accountContactRec.AccountId,Akam_Account_id__c=accountContactRec.Account.Akam_Account_id__c);
    //                 accountIds.add(accountContactRec.AccountId);
    //                 accountRecs.add(accountRec);
    //             }
    //         }
    //         for(Authorized_Contact__c authorizedContact: getAuthorizedContact(contactId,0))
    //         {
    //             if(!accountIds.contains(authorizedContact.Policy_Domain__r.Account_Name__c))
    //             {
    //                 accountIds.add(authorizedContact.Policy_Domain__r.Account_Name__c);
    //                 accountRec = new Account(Name=authorizedContact.Policy_Domain__r.Account_Name__r.Name,Id=authorizedContact.Policy_Domain__r.Account_Name__c,Akam_Account_id__c=authorizedContact.Policy_Domain__r.Account_Name__r.Akam_Account_id__c);
    //                 accountRecs.add(accountRec);
    //             }
                
    //         }
    //     }
    //     return accountRecs;
    // }
    
    public static Set<String> getAccessSet(String mode)
    {
        String accessString;
        Set<String> accessSet = new Set<String>();
        String recordName =  'Jarvis'+mode+'Access';
        for(SC_CommunityUtility__mdt communityUtil : [Select DeveloperName, Case_Field_API__c from SC_CommunityUtility__mdt where 
        DeveloperName = :recordName])
        {
            accessString = communityUtil.Case_Field_API__c ;
        }
        if(!String.isBlank(accessString))
        {
            accessSet.addAll(accessString.split(','));
        }
        return accessSet;
    }
    public static List<Account> getAccountRecords(String contactId, String mode)
    {
        Set<Id> accountIds =  new Set<Id>();
        List<Account> accountRecs = new List<Account>();
        Account accountRec;
        if(contactId != null)
        {
            if(mode == 'ReadMode')
            {
                for(Jarvis_Contact_ACC_Permission_Contract__c accountContactRec : [select Account__c,Account__r.Name, Account__r.Akam_Account_id__c from 
                Jarvis_Contact_ACC_Permission_Contract__c where Active__c = true and Active_Contract__c = true and 
                Customer_Permission__r.Contact__c = :contactId and Case_Management__c in ('Create','View')])
                {
                    if(!accountIds.contains(accountContactRec.Account__c))
                    {
                        accountRec = new Account(Name=accountContactRec.Account__r.Name,Id=accountContactRec.Account__c,Akam_Account_id__c=accountContactRec.Account__r.Akam_Account_id__c);
                        accountIds.add(accountContactRec.Account__c);
                        accountRecs.add(accountRec);
                    }
                }

                
                // for(AccountContactRelation accountContactRec : [Select AccountId, Account.name, Account.Akam_Account_id__c from AccountContactRelation where ContactId = :contactId and IsActive = true])
                // {
                //     if(!accountIds.contains(accountContactRec.AccountId))
                //     {
                //         accountRec = new Account(Name=accountContactRec.Account.name,Id=accountContactRec.AccountId,Akam_Account_id__c=accountContactRec.Account.Akam_Account_id__c);
                //         accountIds.add(accountContactRec.AccountId);
                //         accountRecs.add(accountRec);
                //     }
                // }
    
            }
            else if(mode == 'EditMode')
            {
                for(Jarvis_Contact_ACC_Permission_Contract__c accountContactRec : getPermissionRecords(contactId,null,getAccessSet('Write'),0))
                {
                    if(!accountIds.contains(accountContactRec.Account__c))
                    {
                        accountRec = new Account(Name=accountContactRec.Account__r.Name,Id=accountContactRec.Account__c,Akam_Account_id__c=accountContactRec.Account__r.Akam_Account_id__c);
                        accountIds.add(accountContactRec.Account__c);
                        accountRecs.add(accountRec);
                    }
                }

            }
            for(Authorized_Contact__c authorizedContact: getAuthorizedContact(contactId,0,null,null))
            {
                if(!accountIds.contains(authorizedContact.Policy_Domain__r.Account_Name__c))
                {
                    accountIds.add(authorizedContact.Policy_Domain__r.Account_Name__c);
                    accountRec = new Account(Name=authorizedContact.Policy_Domain__r.Account_Name__r.Name,Id=authorizedContact.Policy_Domain__r.Account_Name__c,Akam_Account_id__c=authorizedContact.Policy_Domain__r.Account_Name__r.Akam_Account_id__c);
                    accountRecs.add(accountRec);
                }
                
            }
        }
        return accountRecs;
    }

    public static List<Jarvis_Contact_ACC_Permission_Contract__c> getPermissionRecords (String contactId, String accountId,Set<String> permissions,Integer limitValue)
    {
        system.debug('contactId: ' + contactId);
        system.debug('permissions: ' + permissions);

        String permissionString = String.join((Iterable<String>)permissions,'","');
        system.debug('permissionString: ' + permissionString);
        String query = 'select Id, Contract__c, Contract__r.Original_Contract_Id__c, Contract__r.Parent_Account_Name__c, Contract__r.Parent_Account_Name__r.Name, Contract__r.Parent_Account_Name__r.AKAM_Account_Id__c, Contract__r.Jarvis_Direct_Contract__c, Contract__r.Jarvis_Indirect_Contract__c , Permission__c,Account__c,Account__r.Name, Account__r.Akam_Account_id__c from Jarvis_Contact_ACC_Permission_Contract__c';
        query += ' where Active__c = true and Active_Contract__c = true and ATT_Contract__c = false' ;
        query += accountId != null ? ' and Account__c = :accountId' : '';
        query += ' and Customer_Permission__r.Contact__c = :contactId and Permission__c includes';
        query += ' (:permissionString)';
        
        if(limitValue >0)
        {
            query += ' limit :limitValue';
        }
        
        system.debug('query: ' + query);
        return Database.query(query);
    }

    public static List<Authorized_Contact__c> getAuthorizedContact(String contactId, Integer limitValue,List<String> accountIds,List<String> policyDomains)
    {
        Set<String>states = new Set<String>{'Active'};
        String query = 'select Instruct__c, Policy_Domain__r.Account_Name__c, Policy_Domain__r.Account_Name__r.Akam_Account_id__c, Policy_Domain__r.Account_Name__r.Name,Policy_Domain__c, Policy_Domain__r.Name'; 
        query += ' from Authorized_Contact__c where Policy_Domain__r.Policy_Domain_State__c in :states'; 
        query += ' and Contact_Name__c = :contactId'; 
        query += accountIds != null && accountIds.size() > 0 ? ' and Policy_Domain__r.Account_Name__c in :accountIds' : ''; 
        query += policyDomains != null && policyDomains.size() > 0 ? ' and Policy_Domain__c in :policyDomains' : ''; 
        if(limitValue >0)
        {
            query += ' limit :limitValue';
        }
        return Database.query(query);
    }
    
    //Changes By Vamsee (ESESP-7043 - Sorry Page Issue)
    public static Set<Account> getParentAccountRecords(String contactId, String accountId, String contactAccountId)
    {
        Set<Account> accountRecs = new Set<Account>();
        
        if(contactId != null){
            Account accountRec;
            for(Jarvis_Contact_ACC_Permission_Contract__c eachPermission : getPermissionRecords(contactId,accountId,getAccessSet('Write'),0)){
                system.debug('---eachPermission---'+eachPermission.Id);
                if(eachPermission.Contract__r.Jarvis_Direct_Contract__c == True){
                    return null;
                }
                else if(eachPermission.Contract__r.Jarvis_Indirect_Contract__c == True){
                    if(contactAccountId == eachPermission.Contract__r.Parent_Account_Name__c){
                        accountRecs = new Set<Account>();
                        accountRec = new Account(Name=eachPermission.Contract__r.Parent_Account_Name__r.Name,Id=eachPermission.Contract__r.Parent_Account_Name__c,Akam_Account_id__c=eachPermission.Contract__r.Parent_Account_Name__r.Akam_Account_id__c);
                    	accountRecs.add(accountRec); 
                        return accountRecs;
                    }
                    else{
                        accountRec = new Account(Name=eachPermission.Contract__r.Parent_Account_Name__r.Name,Id=eachPermission.Contract__r.Parent_Account_Name__c,Akam_Account_id__c=eachPermission.Contract__r.Parent_Account_Name__r.Akam_Account_id__c);
                        accountRecs.add(accountRec); 
                    }
                }
            }
            
        }
        
        return accountRecs;
        
    }
    
    //Changes By Vamsee (ESESP-7043 - Sorry Page Issue)
    public static boolean parentAccountCheckForClone(String parentAccountId, List<Jarvis_Contact_ACC_Permission_Contract__c> permissionList)
    {
        for(Jarvis_Contact_ACC_Permission_Contract__c eachPermission : permissionList){
            if(eachPermission.Contract__r.Jarvis_Indirect_Contract__c == True && parentAccountId == eachPermission.Contract__r.Parent_Account_Name__c){
                return true;
            }
        }
        return false;
    }
    
    
    
    public static List<Case_Product_Siebel_LOV__c> getLOVs(Set<String> areaFilter, String accountFilter, Set<String> products)
    {
        List<Account> accountRecs;
        String akamAccountId;
        if(!String.isBlank(accountFilter) )
        {
            accountRecs = [Select Akam_Account_Id__c from Account where id = :accountFilter];
            akamAccountId = accountRecs.get(0).Akam_Account_Id__c;
        }

        String query = 'Select Product__c,Problem__c,Area__c from Case_Product_Siebel_LOV__c where Marked_For_Deletion__c = false';
        query += areaFilter !=null && areaFilter.size() > 0 ? ' and Area__c in :areaFilter' : '';
        query +=  !String.isBlank(accountFilter)?' and Account_ID__c = :akamAccountId' : '';
        query += products != null && products.size() > 0? ' and Product__c in :products' : '';
        query += ' order by Area__c,Product__c,Problem__c';

        return database.query(query);

    }

    public static List<Siebel_Marketing_Prod_Case_Prod_Map__c> getMappingRecords(Set<String> caseProducts, Set<String> marketingProducts)
    {
        String query = 'Select Marketing_Product_ID__c,Case_Product_Name__c from Siebel_Marketing_Prod_Case_Prod_Map__c';
        query += ' where Marked_for_Deletion__c = false';        
        query +=caseProducts != null && caseProducts.size() > 0 ? ' and Case_Product_Name__c in : caseProducts':'';
        query +=marketingProducts != null && marketingProducts.size() > 0 ? ' and Marketing_Product_ID__c in : marketingProducts':'';

        return Database.query(query);
    }

    public static String getServicesPS(Set<String> accounts,Set<String> contractIds, Set<String> productNames, Integer limitValue)
    {
        Map<String,String> contractToAccount = new Map<String,String>();
        Set<String> contractIdsToQuery = new Set<String>();
        if(accounts!= null && accounts.size() > 0)
        {
            
            for(Merge_Contract_Header__c headerRec: [Select Original_Contract_Id__c,Account_Name__c from Merge_Contract_Header__c where
            Account_Name__c in :accounts and Effective_end_date__c > today])
            {
                contractToAccount.put(headerRec.Original_Contract_Id__c,headerRec.Account_Name__c);
            }
            contractIdsToQuery.addAll(contractToAccount.keySet());
        }
        else if(contractIds != null && contractIds.size() > 0)
        {
            contractIdsToQuery.addAll(contractIds);
        }
        // system.debug('contractIdsToQuery: ' + contractIdsToQuery);
        String areaFilter = 'Professional_Services::Luna_PS_Request';
        String query = 'Select  Id, contract_id__c, MARKETING_PRODUCT_NAME__c';         
        query += ' from CONTRACT_ENGINEERING_PRODUCT_DETAIL__c where ENGINEERING_PRODUCT_NAME__c = :areaFilter and EFFECTIVE_END_DATE__c >= today';
        query += productNames != null && productNames.size() > 0? ' and MARKETING_PRODUCT_NAME__c in :productNames' : '';
        query += contractIdsToQuery != null && contractIdsToQuery.size() > 0?  ' and contract_id__c in :contractIdsToQuery' : '';
        query += ' order by MARKETING_PRODUCT_NAME__c';
        if(limitValue >0)
        {
            query += ' limit :limitValue';
        }
        Map<String,Map<String,String>> accountToContracts = new Map<String,Map<String,String>>();
        Set<String> products = new Set<String>();
        String accountId;
        String currentContractString;
        for(CONTRACT_ENGINEERING_PRODUCT_DETAIL__c cepdRec : Database.query(query))
        {
            // system.debug('cepdRec: ' + cepdRec); 
            if(contractToAccount.size() > 0)
            {
                system.debug('HERE!!!: ' + accountToContracts);
                accountId = contractToAccount.get(cepdRec.contract_id__c);
                if(!accountToContracts.containsKey(accountId))
                {
                    accountToContracts.put(accountId,new Map<String,String>());
                }
                if(!accountToContracts.get(accountId).containsKey(cepdRec.MARKETING_PRODUCT_NAME__c))
                {
                    accountToContracts.get(accountId).put(cepdRec.MARKETING_PRODUCT_NAME__c,'');
                }
                currentContractString = accountToContracts.get(accountId).get(cepdRec.MARKETING_PRODUCT_NAME__c);
                currentContractString += currentContractString.contains(cepdRec.contract_id__c) ? 
                '' :  ',' + cepdRec.contract_id__c;
                accountToContracts.get(accountId).put(cepdRec.MARKETING_PRODUCT_NAME__c,currentContractString);
            }
            else
            {
                products.add(cepdRec.MARKETING_PRODUCT_NAME__c);
            }
        }
        // system.debug('products: ' + products); 
        // system.debug('HERE!!!: ' + accountToContracts);
        return (accountToContracts.size() > 0? JSON.serialize(accountToContracts) : JSON.serialize(products));
    }


    public static List<PAC_Product_Catalog__c> getBusinessUnit(Set<String> marketingProductIds, Integer limitValue)
    {
        String query = 'Select  Marketing_Product_Id__c,Business_Unit__c'; 
        query += ' from PAC_Product_Catalog__c';
        query += marketingProductIds != null && marketingProductIds.size() > 0?  ' where Marketing_Product_Id__c in :marketingProductIds' : '';

        if(limitValue >0)
        {
            query += ' limit :limitValue';
        }

        return Database.query(query);

    }
    public static List<EB_AccountProductMap__c> getCaseProduct(String caseProduct, String accountId)
    {
        String query = 'Select  Id from EB_AccountProductMap__c where EB_MarkedForDeletion__c = false';
        query += !string.isBlank(caseProduct)?' and EB_Product__c = :caseProduct': '';
        query += !string.isBlank(accountId)?' and EB_Account__c = :accountId': '';
        return Database.query(query);
    }

    public static List<Merge_Contract_Detail__c> getContractDetails(Set<String> contracts, Set<String> products,Set<String> accounts, Integer limitValue)
    {
        String query = 'Select Original_Contract_Id__c,Product_Id__c,Original_Contract_Id__r.Account_Name__c,Original_Contract_Id__r.Original_Contract_Id__c from Merge_Contract_Detail__c';
        query += ' where Effective_End_Date__c >= today';
        query += contracts != null && contracts.size() > 0? ' and Original_Contract_Id__c in :contracts': '';
        query += products != null && products.size() > 0? ' and Product_Id__c in :products': '';
        query += accounts != null && accounts.size() > 0? ' and Original_Contract_Id__r.Account_Name__c in :accounts': '';

        if(limitValue >0)
        {
            query += ' limit :limitValue';
        }

        return Database.query(query);
    }
    public static Set<String> getAreas(String category)
    {
        Set<String> categoryFilter = new Set<String>();
        switch on category 
        {
            when 'AMG' 
            {       // when block 1
                categoryFilter.add('Business Support');
            }   
            when 'Billing' 
            {       // when block 2
                categoryFilter.add('Billing Support');
            }
            when 'Technical'
            {       // when block 3
                categoryFilter.add('Technical Support');
                categoryFilter.add('Emerging Products Eng');
                categoryFilter.add('Carrier Products');
            }
            when 'PS' 
            {       // when block 3
                categoryFilter.add('Technical Support');
                categoryFilter.add('Emerging Products Eng');
                categoryFilter.add('Carrier Products');
                categoryFilter.add('Security Event');
            }
            when 'SOCC'
            {
                categoryFilter.add('Security Event');
            }
        }    
            return categoryFilter;
    }
   

    public static void setSeverityMap()
    {
        if(keyToSeverityValues == null)
        {
            keyToSeverityValues = new Map<String,List<String>>();
            for(SC_CommunityUtility__mdt communityUtil : [Select DeveloperName, Case_Field_API__c from SC_CommunityUtility__mdt where 
            DeveloperName in ('AMG_Severity_Default','Billing_Severity_Default','Severity_Carrier'
            ,'Severity_Default','Severity_Emerging','Severity_Riverbed','SOCC_Severity_Default','Riverbed_Account',
            'AMG_Severity_RiverBed_Default','Billing_Severity_RiverBed_Default','SOCC_Severity_RiverBed_Default')])
            {
                switch on communityUtil.DeveloperName
                {
                    when 'AMG_Severity_Default' 
                    {       
                        keyToSeverityValues.put('AMG',new List<String>{communityUtil.Case_Field_API__c});
                    }   
                    when 'Billing_Severity_Default' 
                    {       
                        keyToSeverityValues.put('Billing',new List<String>{communityUtil.Case_Field_API__c});
        
                    }
                    when 'SOCC_Severity_Default'
                    {
                        keyToSeverityValues.put('Managed Security',new List<String>{communityUtil.Case_Field_API__c});
                    }
                    when 'Severity_Carrier'
                    {
                        keyToSeverityValues.put('Carrier',communityUtil.Case_Field_API__c.split(';'));
                    }
                    when 'Severity_Emerging'
                    {
                        keyToSeverityValues.put('Emerging',communityUtil.Case_Field_API__c.split(';'));
                    }
                    when 'Severity_Riverbed'
                    {
                        keyToSeverityValues.put('RiverBed',communityUtil.Case_Field_API__c.split(';'));
                    }
                    when 'Severity_Default'
                    {
                        keyToSeverityValues.put('Default',communityUtil.Case_Field_API__c.split(';'));
                    }
                    when 'Riverbed_Account'
                    {
                        keyToSeverityValues.put('Account',new List<String>{communityUtil.Case_Field_API__c});
                    }
                    when 'AMG_Severity_RiverBed_Default'
                    {
                        keyToSeverityValues.put('AMG_Account',new List<String>{communityUtil.Case_Field_API__c});
                    }
                    when 'Billing_Severity_RiverBed_Default'
                    {
                        keyToSeverityValues.put('Billing_Account',new List<String>{communityUtil.Case_Field_API__c});
                    }
                    when 'SOCC_Severity_RiverBed_Default'
                    {
                        keyToSeverityValues.put('Managed Security_Account',new List<String>{communityUtil.Case_Field_API__c});
                    }

                }
                        
            }
                
        }

    }
    public static List<String> getSeverityValuesCreateCase(String accountId,String category,String carrierEmerging)
    {
        setSeverityMap();
        String riverBedAccount = SC_Jarvis_utility.keyToSeverityValues.get('Account').get(0);
        Set<String> recordTypes = new Set<String>{'AMG','Billing','Managed Security'};

        List<String> severity = new List<String>();
        String recordTypeToCheck = category == 'SOCC'? 'Managed Security' : category;

        String severityKey = riverBedAccount == accountId && recordTypes.contains(recordTypeToCheck)? recordTypeToCheck+'_Account':
        recordTypes.contains(recordTypeToCheck)? recordTypeToCheck :
        riverBedAccount == accountId? 'RiverBed':
        carrierEmerging != null && keyToSeverityValues.containsKey(carrierEmerging)? carrierEmerging : 'Default';

        
        system.debug('severityKey: '+ severityKey);
        
        severity.addAll(keyToSeverityValues.get(severityKey));

        
        return severity;

    }

    public static String getSeverityValuesCorrespondingToCase(String recordType, String subtype, String accountId, String caseSeverity)
    {
        if(String.isBlank(recordType) || String.isBlank(accountId) || String.isBlank(caseSeverity))
        {
            return '';
        }
        setSeverityMap();

        String riverBedAccount = SC_Jarvis_utility.keyToSeverityValues.get('Account').get(0);
        Set<String> recordTypes = new Set<String>{'AMG','Billing','Managed Security'};
        Pattern pat = Pattern.compile('([0-9]+)');
        Matcher matcher;

        
        String severityKey = riverBedAccount == accountId && recordTypes.contains(recordType)? recordType+'_Account':
        recordTypes.contains(recordType)? recordType :
        riverBedAccount == accountId? 'RiverBed':
        recordType == 'Technical' && !String.isBlank(subtype) && subtype == 'Carrier' ? 'Carrier':
        recordType == 'Emerging Products Engineering' ? 'Emerging': 'Default';


        
        String currentSeverity;
        List<String> severitiesToConsider = new List<String>();
        severitiesToConsider.addAll(keyToSeverityValues.get(severityKey));
        if(severityKey != 'Default')
        {
            severitiesToConsider.addAll(keyToSeverityValues.get('Default'));
        }
        try
        {
            for(String severityValue : severitiesToConsider)
            {
                matcher = pat.matcher(caseSeverity);
                if(severityValue == caseSeverity || severityValue.contains(caseSeverity) ||
                matcher.find() && severityValue.contains(String.valueOf(matcher.group(1))))
                {
                    currentSeverity = severityValue;
                }
                if(currentSeverity != null)
                {
                    break;
                }   
            }
        }
        catch (Exception e)
        {
            if(keyToSeverityValues.get('Default') != null && keyToSeverityValues.get('Default').size() > 0)
            {
                currentSeverity = keyToSeverityValues.get('Default').get(keyToSeverityValues.get('Default').size()-1);
            }
        }
        currentSeverity = currentSeverity == null && caseSeverity == '4'? '4-Low Impact' : currentSeverity;

        return currentSeverity;
    }

    
    public static String convertToEighteen(String recordId)
    {
        String idStr = recordId;   // 15 character id
        Id idval = idStr;                   // assign to ID variable
        idStr = idval;                      // back to string to prove the point
        return idStr;
    }

    public static List<CaseShare> getCaseSharesJarvis(Set<String> caseIds)
    {
        String groupName = 'JARVIS%';
        String rowCauseVal = 'Manual';
        String query = 'select CaseAccessLevel, CaseId, Id, RowCause, UserOrGroup.Name from CaseShare';
        query += ' where UserOrGroup.Name like :groupName and RowCause = :rowCauseVal';
        query += caseIds != null && caseIds.size() > 0? ' and CaseId in :caseIds': '';

        return Database.query(query);

    }

    public static List<community_comments__share> getCommentSharesJarvis(Set<String> caseIds,set<String> commentIds)
    {
        String groupName = 'JARVIS%';
        String rowCauseVal = 'Manual';
        String query = 'select parent.Parent_ID__c, Id, RowCause, UserOrGroup.Name from community_comments__share';
        query += ' where UserOrGroup.Name like :groupName and RowCause = :rowCauseVal';
        query += caseIds != null && caseIds.size() > 0? ' and parent.Parent_ID__c in :caseIds': '';
        query += commentIds != null && commentIds.size() > 0? ' and Id in :commentIds': '';

        return Database.query(query);

    }

    public static List<community_comments__c> getComments(Set<String> caseIds)
    {
        String query = 'Select Id,Parent_ID__c,Account_ID_for_Community_Share__c';
        query += ' from community_comments__c Where Visibility__c = \'Public\'';
        query += caseIds != null && caseIds.size() > 0 ? ' and Parent_ID__c in :caseIds': '';
        return Database.query(query);

    }

    public static community_comments__share createCommentShare(String commentId, String groupId)
    {
        community_comments__share shareRec= new community_comments__share();
        shareRec.ParentID = commentId;
        shareRec.RowCause = 'Manual';
        shareRec.AccessLevel = 'Read';
        shareRec.UserOrGroupId = groupId;
        return shareRec;

    }
    
    public static CaseShare createCaseShare(String caseId, String groupId, String groupName)
    {
        CaseShare caseShareRec = new CaseShare();
        caseShareRec.CaseId = caseId;
        caseShareRec.RowCause = 'Manual';
        caseShareRec.CaseAccessLevel = groupName.contains('READ')? 'Read' : 'Edit';
        caseShareRec.UserOrGroupId = groupId;    

        return caseShareRec;
    }

    public static List<Case_Questionnaire__c> getQuestions(Set<String> product, Set<String> problem)
    {
        String query = 'Select Id,Answer_Options__c,Help_Text__c,Question__c,Question_Type__c,';
        query += 'Required__c from Case_Questionnaire__c where Is_Active__c = true';
        query += product != null && product.size() > 0 ? ' and Case_Product__c in :product': '';
        query += problem != null && problem.size() > 0 ? ' and Problem__c in :problem': '';
        return Database.query(query);
    }

    // public static List<list<SObject>> searchKnowledge(String subject, String caseProduct,String searchObject)
    // {
    //     if(subject == null && caseProduct == null)
    //     {
    //         return null;
    //     }

    //     String searchString = subject != null && caseProduct != null? 
    //     '"' + subject + '" AND"' + caseProduct + '"' : 
    //     subject != null ? '"' + subject + '"' : 
    //     '"' + caseProduct + '"';

    //     system.debug('searchString: ' + searchString);
    //     List<list<SObject>> searchList = new List<list<SObject>>();
    //     String searchquery = 'FIND :searchString IN ALL Fields RETURNING';

    //     String articleQuery = 'Knowledge__kav (Id, AKAM_Article_Number__c, Title, Summary,ArticleTotalViewCount';
    //     articleQuery+= ' Where IsLatestVersion = true and PublishStatus = \'Online\'';
    //     articleQuery+= ' ORDER by ArticleTotalViewCount desc limit 5 )';

    //     String feedQuery = 'FeedItem (Id, title,CommentCount,BestCommentId';
    //     feedQuery+= ' Where Visibility = \'AllUsers\' and Type = \'QuestionPost\'';
    //     feedQuery+= ' ORDER by BestCommentId nulls last, CommentCount desc limit 5 )';

    //     switch on searchObject
    //     {
    //         when 'Article' 
    //         {        
    //             searchquery += ' ' + articleQuery;
    //         }    
    //         when 'Feed' 
    //         {        
    //             searchquery += ' ' + feedQuery;

    //         }
    //         when 'Both'
    //         {
    //             searchquery += ' ' + articleQuery + ' , ' + feedQuery;
    //         }
    //     }
    //     system.debug('searchquery: ' + searchquery);
    //     searchList = search.query(searchquery);

    //     return searchList;
    // }

    // public static List<FeedItem> searchDisussion(String searchString)
    // {
    //     String inputString = '"' + searchString + '"';
    //     List<list<SObject>> searchList = new List<list<SObject>>();
        
    //     searchList = [FIND :inputString IN ALL Fields RETURNING FeedItem (Id, title,CommentCount,BestCommentId
    //      Where Visibility = 'AllUsers' and Type = 'QuestionPost'
    //     ORDER by CommentCount desc limit 40 )]; 

    //     List<FeedItem> feedList = new List<FeedItem>();
    //     feedList = ((List<FeedItem>)searchList[0]);

    //     return feedList;
    // }

    @AuraEnabled
    public static Knowledge__kav getArticle (String articleId)
    {
        return [Select Id,KnowledgeArticleId,AKAM_Article_Number__c, ArticleTotalViewCount, Article_Record_Type__c,ArticleNumber, Title, Summary, Symptoms__c, 
        Description__c, Explanation__c, Solution__c, How_To_Procedure__c from Knowledge__kav
        Where IsLatestVersion = true and PublishStatus = 'Online' and Id = :articleId limit 1];
    }

    public static Vote getVoteRec (String parentId, String userId)
    {
        List<Vote> voteRecs = [Select Id,Type from Vote where parentid = :parentId and LastModifiedById = :userId
        order by LastModifiedDate desc limit 1];
        if(voteRecs.size() > 0)
        {
            return voteRecs.get(0);
        }
        return null;
    }

    public static Boolean getUserEditAccess(String userId, String recordId)
    {
        List<UserRecordAccess> accessRecs = [SELECT RecordId FROM UserRecordAccess where RecordId  = :recordId and UserId = :userinfo.getUserId() and
        HasEditAccess = true];        
        return (accessRecs != null && accessRecs.size() > 0) ? true: false;
    }

    public static Set<String> getCategoriesAccounts(String contactId, List<String>accountIds)
    {
        Set<String> categories = new Set<String>();
        if(getAuthorizedContact(contactId,1,accountIds,null).size() == 1)
        {
            categories.add('Managed Security');
        }
        //String permissionString = String.join((Iterable<String>)getAccessSet('All'),'","');

        List<Jarvis_Contact_ACC_Permission_Contract__c> permissions = [Select id from Jarvis_Contact_ACC_Permission_Contract__c 
        where Active__c = true and Customer_Permission__r.Contact__c = :contactId and Account__c in :accountIds
        and Permission__c != null limit 1];
        if(permissions.size() == 1)
        {
            categories.add('AMG');
            categories.add('Billing');
            categories.add('Technical');
            categories.add('Professional Services');
        }
        return categories;
    }

    public static Boolean hasCreateAccess(String contactId)
    {
        List<Jarvis_Contact_ACC_Permission_Contract__c> permissions = getPermissionRecords(contactId,null,getAccessSet('Write'),1);
        return (permissions != null && permissions.size() == 1)? true : false;
    }

    public static String getAccessLevel(String permissionString)
    {
        return (permissionString.contains('CASE_MANAGEMENT_WRITE') ||permissionString.contains('CASE_MANAGEMENT_UPDATE'))  ? '_WRITE' : 
        permissionString.contains('CASE_MANAGEMENT_READ') ?  '_READ' : 'NONE';
    }

    public static String prepareGroupName(String groupName)
    {
        return groupName != null && groupName.contains('-')? groupName.replaceAll('-','_') : groupName;
    }

    public static String stripHtmlTag(String str, String tag, String replaceText) {
        String startTag = '<'+tag;
        String endTag = '</'+ tag + '>';
        String formattedStr = str.replaceAll('(?<=\\<'+ tag +')(.*)(?=</'+tag+'>)', replaceText)
                    .replaceAll(startTag, '')
                    .replaceAll(endTag, '');

        return formattedStr;
    }
    
    
    @future
    //Here Case query is needed because IsEmailBounced field will not be available in Case Trigger
    //We cannot move this to Future because Initial response will be marked complete 
    public static void sendEmailtoAlsoNotify(List<Id> caseIdList){
        
        List<Case> caseList = [SELECT Id, RecordType.Name, Contactid, Contact.IsEmailBounced, Jarvis_Also_Notify__c, Alternate_Contact_Email__c, (SELECT Id, CcAddress FROM EmailMessages Order By CreatedDate Desc Limit 1) FROM Case WHERE Id in :caseIdList];
        
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage eachEmail;
        
        String templateId;
        String orgWideId;
        List<String> ackMailRTs = new List<String>();
        //SC_CommunityUtility__mdt jvSetting =  [SELECT Id, DeveloperName, Value__c FROM SC_CommunityUtility__mdt where DeveloperName = 'Case_Notification_Template'];
        For(SC_CommunityUtility__mdt eachMDT : [SELECT Id, DeveloperName, Value__c FROM SC_CommunityUtility__mdt where DeveloperName in('Case_Notification_Template', 'Auto_Reply','Jarvis_Ack_Email_RTs')]){
            If(eachMDT.DeveloperName == 'Case_Notification_Template')
                templateId = eachMDT.Value__c;
            if(eachMDT.DeveloperName == 'Auto_reply')
                orgWideId  = eachMDT.Value__c;
            //ESESP-7212
            if(eachMDT.DeveloperName == 'Jarvis_Ack_Email_RTs')
                ackMailRTs = eachMDT.Value__c.split(',');
                
        }
        for(Case eachCase : caseList){
            if(eachCase.ContactId != null && eachCase.Contact.IsEmailBounced == False){
                eachEmail = new Messaging.SingleEmailMessage();
                eachEmail.setTargetObjectId(eachCase.ContactId);
                eachEmail.setWhatId(eachCase.Id);
                eachEmail.setTemplateId(templateId);
                eachEmail.setOrgWideEmailAddressId(orgWideId);
                eachEmail.setUseSignature(false);

                List<String> ccEmailList = new List<String>();
                
                if(eachCase.Jarvis_Also_Notify__c != null && eachCase.Jarvis_Also_Notify__c != ''){
                    List<String> alsoNotifyEmailList = new List<String>();
                    ccEmailList = eachCase.Jarvis_Also_Notify__c.split('[,;\\s\n]+');
                }
                
                if(SC_Jarvis_utility.isValidEmail(eachCase.Alternate_Contact_Email__c)){
                        ccEmailList.add(eachCase.Alternate_Contact_Email__c);
                }
                
                //ESESP-7212
                if(ackMailRTs.contains(eachCase.RecordType.Name) && eachCase.emailMessages.size() > 0 && eachCase.emailMessages[0].CcAddress != null){
                    ccEmailList.addAll(eachCase.emailMessages[0].CcAddress.split('; '));  
                }
                
                if(ccEmailList.size() > 0){
                    eachEmail.setCcAddresses(new List<String>(new Set<String>(ccEmailList)));
                }
               emailList.add(eachEmail); 
            }
        }
        if(emailList.size() > 0)
            EmailMessageTriggerHandler.byPassIRUpdateSOCC = True;
            EmailMessageTriggerHandler.bypassMilestoneClosure = true;
        
            Messaging.SendEmail(emailList, False);
     }


    static final String EMAIL_REGEX = '([a-zA-Z0-9_\\-\\.]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,4}|[0-9]{1,3})';
    static final Pattern EMAIL_PATTERN = Pattern.compile(EMAIL_REGEX);

    public static Boolean isValidEmail(String email) {
        return String.isNotBlank(email) 
                && EMAIL_PATTERN
                    .matcher(email)
                    .matches();
    }

    public static Set<String> filterValidEmails(Set<String> emailList) {
        Set<String> validEmailList = new Set<String>();

        for(String eml: emailList) {
            if(isValidEmail(eml)) {
                validEmailList.add(eml);
            }
        }
        return validEmailList;
    }

    public static Map<String,String> statusMap;
    public static String getStatusValue(String status)
    {
        if(statusMap == null)
        {
            statusMap = new Map<String,String>();
            for(SC_CommunityUtility__mdt metadataRec: [select Case_Field_API__c from SC_CommunityUtility__mdt where
                                                        MasterLabel like 'JarvisStatusMapping%'])
            {
                if(!String.isBlank(metadataRec.Case_Field_API__c))
                {
                    for(String mappingValues : metadataRec.Case_Field_API__c.split(','))
                    {
                        if(mappingValues.contains(':'))
                        {
                            statusMap.put((mappingValues.split(':'))[0],(mappingValues.split(':'))[1]);
                        }
                    }   
                }
                
            }            
        }
        return statusMap != null && statusMap.containsKey(status) ? statusMap.get(status) : status;        
    }

    public static void populateErrorTableForUpdate(List<Database.SaveResult> results,List<SObject> objectLists,String subject
    ,String body)
    {
        String errors = '';    
        String errorRecords = '';    
        String table = ''; 
        for(Integer i = 0; results != null && objectLists != null &&  i < results.size(); i++)
        {
          Database.SaveResult sr = results.get(i);
            if (!sr.isSuccess()) 
            {
                errorRecords += '<tr><td>' + JSON.serialize(objectLists.get(i)) + '</td><td>';
                for(Database.Error err : sr.getErrors()) 
                {
                   errors += '<tr><td>' + err.getStatusCode() + ': ' + err.getMessage() + '</td><td>'+ objectLists.get(i).id + '</td></tr>';                   
                }
            }

        }
        if(errors != '')
        {
          table = '<table><tr><th>' + 'The error in Record </th>' + '<th> The Record ID </th></tr>';
          table += errors;
          table += '</table><br/><br/>';    

          table += '<table><tr><th>' + 'The errored Record </th></tr>';
          table += errorRecords;
          table += '</table><br/><br/>';    

          sendErrorMails(subject ,body, table);
        }
        
    }

    //The function to loop over the List of upsert results. If there is any failure, send a mail with the error table
    public static void populateErrorTableForUpsert(List<Database.UpsertResult> results,List<SObject> objectLists,String subject
    ,String body)
    {
        String errors = '';            
        String table = ''; 
        String errorRecords = '';   
        for(Integer i = 0; results != null && objectLists != null &&  i < results.size(); i++)
        {
            Database.UpsertResult sr = results.get(i);
            if (!sr.isSuccess()) 
            {
                errorRecords += '<tr><td>' + JSON.serialize(objectLists.get(i)) + '</td><td>';
                for(Database.Error err : sr.getErrors()) 
                {
                   errors += '<tr><td>' + err.getStatusCode() + ': ' + err.getMessage() + '</td><td>'+ err.getFields() + '</td></tr>';
                }
            }
        } 
        if(errors != '')
        {
          table = '<table><caption><b>' +subject + '</b></caption><tr><th>' + 'The error in Record </th>' + '<th> The fields that affected this error </th></tr>';
          table += errors;
          table += '</table><br/><br/>';  

          table += '<table><tr><th>' + 'The errored Record </th></tr>';
          table += errorRecords;
          table += '</table><br/><br/>';    

          sendErrorMails(subject ,body, table);        
        }
        
    }

    //This takes in the subject and the error message string: sends a mail to the engg team
    public static void sendErrorMails(String subject,String initialMessage, String errorTable)
    {
        List<SC_CommunityUtility__mdt> communityUtil = [Select Case_Field_API__c from SC_CommunityUtility__mdt where 
        DeveloperName = 'JarvisErrorEmail'];
        String recipient = communityUtil.size() == 1? 
        communityUtil.get(0).Case_Field_API__c:
        'shprasan@akamai.com';

        String hostName = URL.getSalesforceBaseUrl().getHost(); 
        String body =  '<html><style> table {border-collapse: collapse;} td,th {border: 1px solid black;}</style><body>Hi ' + UserInfo.getName() +', <br/> Instance : '+  hostName + '<br/><br/>';  
        body += !String.isBlank(initialMessage)? + initialMessage + '<br /><br />' : '';
        body += !String.isBlank(errorTable)? + errorTable + '<br /><br />' : '';
        body += '</body></html>';
        Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        Messaging.Singleemailmessage objEmail;
        objEmail = new Messaging.Singleemailmessage();
        objEmail.setReplyTo('noreply@akamai.com');
        objEmail.setToAddresses(new list<String>{recipient});            
        objEmail.setSubject(subject + ' ' + hostName);
        objEmail.setHTMLBody( body );
        mailsToBeSent.add(objEmail);
        Messaging.sendEmail(mailsToBeSent,false);

    }

    public static void saveUserCustomizations(List<Id> accountIds, Integer pageSize, String queryType) {
        User currentUser = [select id, contactid, contact.AKAM_Contact_ID__c 
                                            from User where id = :UserInfo.getUserId()];
        
        list<Jarvis_Contact_ACC_Permission__c> accPermissionRecords = [select id, User_Filters__c from                  Jarvis_Contact_ACC_Permission__c where User__c  = :userinfo.getUserId() limit 1];

        Jarvis_Contact_ACC_Permission__c toSaveUserCustz;

        String currentUserCustz;
        if(accPermissionRecords.size() > 0) {
            currentUserCustz = accPermissionRecords[0].User_Filters__c;
            toSaveUserCustz =new Jarvis_Contact_ACC_Permission__c(id = accPermissionRecords[0].Id);
        } else {
            toSaveUserCustz = new Jarvis_Contact_ACC_Permission__c(
                                        User__c = userinfo.getUserId(), 
                                        Contact__c = currentUser.contactid, 
                                        Akam_Contact_ACC_Permission_Id__c = currentUser.Contact.AKAM_Contact_ID__c);
        }

        Map<String, Object> userCustz = currentUserCustz != null 
                                        ? (Map<String, Object>)JSON.deserializeUntyped(currentUserCustz)
                                        : new Map<String, Object>();

        userCustz.put('accounts', accountIds);
        userCustz.put('pageSize', pageSize);

        if(String.isNotBlank(queryType)) {
            Map<String, Object> sessionInfo = new Map<String, Object> {
                'sessionIdHash' => getSessionIdHash(),
                'queryType' => queryType
            };
            userCustz.put('sessionInfo', sessionInfo);
        }

        toSaveUserCustz.User_Filters__c = JSON.serialize(userCustz);

        upsert toSaveUserCustz;
    }

    public static integer getSessionIdHash() {
        return UserInfo.getSessionId().hashCode();
    }


    public static Map<String, Object> getExistingUserCustz(Id userId) {

        Map<String, Object> userCustz = new Map<String, Object>();
        list<Jarvis_Contact_ACC_Permission__c> userSavedFilter = [select id, User_Filters__c from Jarvis_Contact_ACC_Permission__c where User__c  = :userinfo.getUserId() limit 1];
        
        if(userSavedFilter.isempty() || String.isBlank(userSavedFilter[0].User_Filters__c))  {
            userCustz.put('pageSize', 10);
        }
        else {
            userCustz = (Map<String, Object>)JSON.deserializeUntyped(userSavedFilter[0].User_Filters__c);
        }
        return userCustz;
    }

    public static String getCategoryRecordType(String getCategoryRecordType)
    {
        String mappingValue='';
        switch on getCategoryRecordType 
        {
            when 'Client Services Manager/ Business Support Issue' 
            {       
                mappingValue = 'AMG';
            }   
            when 'Billing Support Issue or Question' 
            {       
                mappingValue = 'Billing';
            }
            when 'Technical Support Issue'
            {       // when block 3
                mappingValue = 'Technical';
            }
            when 'Professional Services Request (billable)'
            {       // when block 3
                mappingValue = 'PS';
            }
            when 'Managed Security Support'
            {
                mappingValue = 'SOCC';
            }
        }    
        return mappingValue;
       
         
    }


    public static list<SC_CommunityCommentController.MainCommentWrapper> getCommentDetails(Id parentid, string application, string parentobject, String visibility)
    {
        List<SC_CommunityCommentController.MainCommentWrapper> mainCommentWrapperList=new list<SC_CommunityCommentController.MainCommentWrapper>();
        
        for(Community_Comments__c eachCommentrec : [select Id, CreatedByUserType__c,AKAMCreatedByUserType__c,Comment__c, Commented_By__c, AKAM_Created_By__c, Akam_created_by__r.Name,
                                        Commented_By_User__c,Posted_By_Email__c, Application__c, CreatedBy.UserType, AKAM_Created_Date__c, Type__c
                                                        from Community_Comments__c 
                                                        where Parent_ID__c =:parentid 
                                                            and Visibility__c =:visibility 
                                                            and Application__c =:application 
                                                            and Related_Object__c=:parentobject  
                                                        order by AKAM_Created_Date__c asc]) 
        {
            mainCommentWrapperList.add(new SC_CommunityCommentController.MainCommentWrapper(eachCommentrec));
        }
        return mainCommentWrapperList;
    }

    public static List<Merge_Contract_Header__c> getChildContracts(Set<String> parentContracts,Integer limitValue)
    {
        String directFilter = 'Direct%';
        String query = 'select id, parent_contract__c, contract_type__c from Merge_Contract_Header__c where';
        query += ' Effective_End_Date__c > today and (not Contract_Type__c like :directFilter) ';
        query += parentContracts != null & parentContracts.size() > 0? 
        ' and parent_contract__c  in : parentContracts ' 
        : '';        
        query += limitValue > 0 ? ' limit :limitValue' : '';
        return database.query(query);       
    }
    
    
    //ESESP-6070 - Start of changes
    public static integer getDaysSinceClosed(DateTime closedDate){
        return Integer.valueOf((DateTime.now().getTime() - closedDate.getTime())/(1000*60*60*24));
    }
    //End of changes

     //ESESP-5691(Vamsee) - File Size flag against Case 
    @future
    public static void updateCaseAttachmentFlag(Set<Id> caseIdSet){
        //52428800kb = 50 GB
        Integer fileSizeLimit = Integer.valueOf([SELECT Value_text__c FROM SC_Utility__mdt WHERE DeveloperName = 'File_Size_Limit'].Value_text__c);
        
        //Map that indicates whether File Limit on the case is Exceeded
        Map<id, boolean> caseIdFileLimitMap = new  Map<id, boolean>();
        
        //Case List to Update
        List<Case> caseListToUpdate = new List<Case>();
        
        for(Case eachCase : [SELECT Id, Files_Size_Limit_Exceeded__c FROM Case WHERE Id in :caseIdSet ]){
            caseIdFileLimitMap.put(eachCase.Id, eachCase.Files_Size_Limit_Exceeded__c);
        }
        
        Case eachCase;
        Id caseId;
        for (AggregateResult eachAR : [SELECT linkedentityid, sum(ContentDocument.ContentSize) FROM ContentDocumentlink WHERE linkedentityid in :caseIdSet GROUP BY linkedentityid]){
            caseId = String.ValueOf(eachAR.get('linkedentityid'));
            decimal filesSize = Decimal.valueOf(string.valueOf(eachAR.get('expr0')));
    		Long fileSizeInMB = Long.valueOf(filesSize.toPlainString()) / 1024;
    
            if(fileSizeInMB > fileSizeLimit && caseIdFileLimitMap.get(caseId) == False){
                eachCase = new Case();
                eachCase.Id = caseId;
                eachCase.Files_Size_Limit_Exceeded__c = True;
                eachCase.Validation_Override__c = True;
                caseListToUpdate.add(eachCase);
            }
            else if(fileSizeInMB < fileSizeLimit && caseIdFileLimitMap.get(caseId) == True){
                eachCase = new Case();
                eachCase.Id = caseId;
                eachCase.Files_Size_Limit_Exceeded__c = False;
                eachCase.Validation_Override__c = True;
                caseListToUpdate.add(eachCase);
            }
        }
        
        if(caseListToUpdate.size() > 0)
            Update caseListToUpdate;

    }
    
    //ESESP-5691(Vamsee) - File Size flag against Case 
    public static void HandleContentDocumentDelete(List<Id> contentDocumentIdList){
        Set<id> caseIdsetforUpdate = new Set<id>();
        for(ContentDocumentLink eachLink : [SELECT Id, linkedentityid FROM ContentDocumentLink WHERE ContentDocument.Id in :contentDocumentIdList]){
            if(String.valueOf(eachLink.LinkedEntityId.getsobjecttype()) == 'Case'){
                caseIdsetforUpdate.add(eachLink.linkedentityid);
            }
        }
        if(caseIdsetforUpdate.size() > 0){
            SC_Jarvis_utility.updateCaseAttachmentFlag(caseIdsetforUpdate);
        }
    }

    //@future
    public static void beforeDeleteTriggerVam(List<id> IdList){
        for(Id eachDoc : IdList){
            System.debug('---Query---'+[SELECT Id FROM ContentDocumentLink WHERE ContentDocumentID = :eachDoc]);
        }
	}

    public static Map<String,Map<String,String>> getCaseManagementContacts(Set<String> contactIds)
    {
            Map<String,Map<String,String>> contactPermissionMap = new Map<String,Map<String,String>>();
            string contactId,permission;
            for(AggregateResult groupedResult :[select Customer_Permission__r.Akam_Contact_ACC_Permission_Id__c, 
                                                Case_Management__c, count(Id) counter from 
                                                Jarvis_Contact_ACC_Permission_Contract__c where 
                                                Active__c = true and ATT_Contract__c = false and Case_Management__c in ('Create','View') 
                                                and Customer_Permission__r.Akam_Contact_ACC_Permission_Id__c in :contactIds
                                                group by 
                                                Customer_Permission__r.Akam_Contact_ACC_Permission_Id__c,
                                                Case_Management__c])
            {
                contactId = String.valueOf(groupedResult.get('Akam_Contact_ACC_Permission_Id__c'));
                permission = String.valueOf(groupedResult.get('Case_Management__c'));
                if(!contactPermissionMap.containsKey(contactId))
                {
                    contactPermissionMap.put(contactId, new Map<String,String>());   
                    contactPermissionMap.get(contactId).put('akamai','None');                                  
                }
                if ( getPermissionWeight(contactPermissionMap.get(contactId).get('akamai')) <  getPermissionWeight(permission))
                {
                    contactPermissionMap.get(contactId).put('akamai',permission);
                }
            }
            for(AggregateResult groupedResult :[select Customer_Permission__r.Akam_Contact_ACC_Permission_Id__c, 
                                                Case_Management__c, count(Id) counter from 
                                                Jarvis_Contact_ACC_Permission_Contract__c where 
                                                Active__c = true and ATT_Contract__c = true and Case_Management__c in ('Create','View') 
                                                and Customer_Permission__r.Akam_Contact_ACC_Permission_Id__c in :contactIds
                                                group by 
                                                Customer_Permission__r.Akam_Contact_ACC_Permission_Id__c,
                                                Case_Management__c])
            {
                contactId = String.valueOf(groupedResult.get('Akam_Contact_ACC_Permission_Id__c'));
                permission = String.valueOf(groupedResult.get('Case_Management__c'));
                if(!contactPermissionMap.containsKey(contactId))
                {
                    contactPermissionMap.put(contactId, new Map<String,String>());   
                    contactPermissionMap.get(contactId).put('att','None');                 
                }
                if ( getPermissionWeight(contactPermissionMap.get(contactId).get('att')) <  getPermissionWeight(permission))                
                {
                    contactPermissionMap.get(contactId).put('att',permission);
                }
            }                        

            return contactPermissionMap;
    }

    public static Integer getPermissionWeight(string permission)
    {
        Integer permissionWeight = 0;
        switch on permission 
        {
            when 'Create' 
            {       // when block 1
                permissionWeight = 2;
            }   
            when 'View' 
            {       // when block 2
                permissionWeight = 1;
            }
            when 'None'
            {       // when block 3
                permissionWeight = 0;
            }
        }    

        return permissionWeight;
    }

    public static String getAkamaiRecordType(String recordTypeName, String subType)
    {
        String recordType;
        if(recordTypeName == 'Partner Technical Support')
        {
            switch on subType 
            {
                when 'Billing Support' 
                {       // when block 1
                    recordType = 'Billing';
                }   
                when 'Business Support' 
                {       // when block 2
                    recordType = 'AMG';
                }
                when 'Technical Support'
                {       // when block 3
                    recordType = 'Technical';
                }
                when 'Professional-Services Support' 
                {       // when block 2
                    recordType = 'Professional Services';
                }
            }
        }    
        
        return recordType;
        
    }
}