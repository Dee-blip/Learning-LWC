/***
    Karteek Kumar M       09/08/10          CR 656101 Need to make changes to the field Opportunity.Customer Status
                                            - Customer_Status is now New/Churn/- (before : New/Churn/Existing).
    Ali KM                22/09/10          CR 734770 Automate Account Reassignment - Next Steps
                                            - Updated all test methods to use System.runAs for all account inserts.
                                            - Ex: System.runAs(accOldOwnerUser){insert acc;}
    Ali KM                21/10/10         CR 812208 PDRA Update part-2
                                            - Added logic to run ONA if Account.Owner does not have an AccountReassignmentRule
                                            - Implemented ONA Name using Custom Settings - Account_Reassignment_Class_Settings__c
                                            - Also added new field Account_Reassignment_Rule__c.User_Role__c to all AssignmentRules in new methods:
                                            - Following methods have been updated to Assert for No Owner as Account Owner
                                                -) UpdateOldOwnerTest()     
                                                -) FixOpptyLineItems_Single()
    Ali KM                10/11/2010        CR 837489 Modification request for - CR 734770
                                                    - Update field -> LastAccRessignDeniedTo__c
                                                    - Used in Trigger: AccountTrigger_bi_bu
    Karteek Kumar M       16/12/2010        CR 900397 Remove Other-New Other-Existing drop and add logic
                                            Getting Rid of FixOpptyLineItems()
    Ali KM                28/12/2010        CR 872300 Code cleanup - enable feature toggle for PDRA auto-reassignment
                                                - added new Custom Settings > Toggle Feature for PDRA -> AutoPDRAUpdateOnAcctInsert                         
                                                - Following test method is updated to check assertion based on feature ON/OFF mode
                                                    -) UpdateOldOwnerTest()     
    Ali KM                20/12/2011        CR 1389646 Rethink the Inbound Outbound design in Leads - part2
                                                - In-order to automate population of Account.Industry, created a new custom object - 'Industry Vertica/Sub-Vertical'
                                                - On Insert or change in value for Vertical__c/Sub_Vertical__c fields, picking up Industry__c value from new custom object & updating Account.Industry__c                                                                                                                                                                                                                   
    Ali KM                17/08/2012        CR 1521982 Credit check approval # deletion and fix related WF
                                            -> Commenting out all lines referring: Credit_Check_Approval__c field.
        
                                        
    Pitamber Sharma(Appirio Offshore)  13/05/2013  Added afterUpdate method.
    Vijetha Vijayendran                 23-April-14 Added Named_Enhanced Support level
    Akhila Vidapanapati                 18-Aug-14   afterUpdate method - Added Indirect_Customer,Premium_2.0 and Premium_2.0_EnhancedSLA Support Level
    Anand Hegde                         Sept-22-2014 For netops account, automatically reassign the account when 'sales account' is checked
    Akhila Vidapanapati                 24-09-14    Removed hardcoding on SL_ENTITLEMENT_MAP,moved it to Custom settings - CR 2770626
    Sonali Tandon                     31/09/2014  CR 2801946- Populate lead and contact vertical & sub vertical if associated account vertical & subvertical are updated. 
    Shivam Verma                        25-03-15    Country COnversion for Data.com
    Vamsee Surya                        31-08-17    ESESP-727 - Updated AfterUpdate Method
    Vishnu Sharma                       25-03-20    ESESP-1588 - Updated AfterUpdate,Created AfterInsert,createCaseNotificationOnUpdate,genericMethodForCNSCreateUpdate Method
    Sharath Prasanna                    22 July 2020 ESESP-3659 - Changes for Billing Case migration
    Vandhana Krishnamurthy              15 Jun 20201    ESESP-5494 Support Differentiation for AkaTec (Saturn)
    Vandhana Krishnamurthy              26 Aug 2021     ESESP-5953 Elevate Account Akatec
    Sharath Prasanna                    22 July 2021 ESESP-4356 - Jarvis Phase0
    Vandhana Krishnamurthy              23 Sep 2021    ESESP-6141 Delete field Finance Tier from Account object
    Aditi Singh                         24 Dec 2021    Saturn: Support Delivery Type Exceptions for APJ

*/
public without sharing class AccountTriggerClass 
{
    public static Boolean createUpdateEntitlementFirstRunFlag = true;
    public static Boolean approveLastPendingReassignmentFirstRunFlag= true;

    public static void beforeInsertUpdate(Boolean isInsert, Account[] oldAccounts, Account[] newAccounts, Map<Id, Account> oldMap, Map<Id, Account> newMap) 
    {

        if(newAccounts==null || newAccounts.size()==0) return;
        
        if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
        {
            //changes: adding recursive check for Account update
            if(!isInsert && RAMDProcessor.isFirstTime)
            {
                RAMDProcessor.isFirstTime = false;
                RAMDProcessor instanceRAMDProcessor = new RAMDProcessor();
                instanceRAMDProcessor.accountCountryChange(newAccounts, oldMap, false);
            }

        }
         
        //CR 3298201: Added by kusharma
        //Method for creating Task On Account for Media and Web Accounts.         
        createTaskForAccount(newAccounts, isInsert,
                           oldMap);
        
        setSupportDeliveryType(isInsert,newAccounts,oldMap);
        
        validateElevationDLOnAccount(isInsert,newAccounts,oldMap);
    }
    
    // Vishnu Sharma - Start - ESESP-1588
    public static void afterInsert(List<Account> lstAccounts) 
    {
        //JARVIS changes
        list<string> accIDsforJarvis = new list<string>();

        List<Case_Notification_Subscription__c> caseNotificationSubsList= new List<Case_Notification_Subscription__c>();
        Case_Notification_Subscription__c tempCaseNotificationSubscription;
       // String[] activeStatuses = Label.Account_Statuses_For_Case_Notification.split(',');
        if(lstAccounts.size() > 0){
            for(Account iteratedAccount : lstAccounts){
                if(iteratedAccount.Type.contains('- Active')){

                    //--------JARVIS RELATED CHANGES----------
                    accIDsforJarvis.add(iteratedAccount.Id);
                    
                    tempCaseNotificationSubscription = new Case_Notification_Subscription__c();
                    tempCaseNotificationSubscription.Account__c = iteratedAccount.Id;
                    tempCaseNotificationSubscription.Case_Record_Type__c = 'All';
                    tempCaseNotificationSubscription.Severity__c = '1;2';
                    tempCaseNotificationSubscription.Incident__c = 'Yes';
                    tempCaseNotificationSubscription.Portal_Visibility__c = 'All';
                    tempCaseNotificationSubscription.User__c = iteratedAccount.OwnerId;
                    tempCaseNotificationSubscription.Sub_Type__c = '';
                    tempCaseNotificationSubscription.Case_Origin__c = '';
                    tempCaseNotificationSubscription.Origin__c = 'Implicit';
                    caseNotificationSubsList.add(tempCaseNotificationSubscription);
                }     
            }
            if(caseNotificationSubsList.size() > 0){
                insert caseNotificationSubsList;
            }
            //--------JARVIS RELATED CHANGES----------
            if(!SC_Jarvis_CoreSecurityController.createPublicGroupForSObjectRecChk && !system.isFuture() && accIDsforJarvis.size() > 0)
            {
                SC_Jarvis_CoreSecurityController.createPublicGroupForSObjectRecChk=true;
                SC_Jarvis_CoreSecurityController.createPublicGroupForSObject(accIDsforJarvis,'Account');
            }
        }
    }
    //Vishnu Sharma - End - ESESP-1588
    
    public static void afterUpdate(List<Account> lstAccounts, Map<Id, Account> oldMap) 
    {
        if(lstAccounts==null || lstAccounts.size()==0) return;
        
        // Vamsee Surya - Start - ESESP-727 
        if(createUpdateEntitlementFirstRunFlag) {
            List<SupportLevel_Sla_Map__c> listSuppSla = SupportLevel_Sla_Map__c.getall().values();
            Map<String, String> SL_ENTITLEMENT_MAP = new Map<String,String>();
            for(SupportLevel_Sla_Map__c SuppSla_Rec: listSuppSla){
                SL_ENTITLEMENT_MAP.put(SuppSla_Rec.Name,SuppSla_Rec.SlaProcess__c);
            }
            Set<Id> accIds = new Set<Id>();

            for(Account a : lstAccounts) {
                if(a.Support_Level__c != null && !a.Support_Level__c.equals(oldMap.get(a.Id).Support_Level__c)) {
                    accIds.add(a.Id);       
                }
            }
            
            if(accIds.size() > 0) {
                Map<String, SlaProcess> entProcessMap = new Map<String, SlaProcess>(); 
                List<Entitlement> updateableEntitlements = new List<Entitlement>();
                List<Entitlement> createableEntitlements = new List<Entitlement>();
                Entitlement entitlement;
                //changes by Sharath for ESESP-3659: commenting the code for Billing
                //Boolean hasFound;
                
                for(SlaProcess sp : [Select Id, Name from SlaProcess where IsVersionDefault = true]) {
                    entProcessMap.put(sp.Name.toLowerCase(), sp);
                }
                
                for(Account a : [Select Id, Support_Level__c, (Select Id, Name, EndDate From Entitlements) From Account Where Id IN : accIds]) {
                    //changes by Sharath for ESESP-3659: commenting the code for Billing 
                    //hasFound = false;
                    for(Entitlement e : a.Entitlements) {
                        if(!e.Name.equals('Billing Support') && e.EndDate == null) {
                            e.EndDate = Date.today();
                            updateableEntitlements.add(e);
                        } 
                        //changes by Sharath for ESESP-3659: commenting the code for Billing  
                        //else if(e.Name.equals('Billing Support')) {
                        //    hasFound = true;
                        //}
                    }
                    //changes by Sharath for ESESP-3659: commenting the code for Billing 
                    //if(!hasFound && entProcessMap.containsKey('billing support')){
                    //    createableEntitlements.add(createEntitlement(a.Id, 'Billing Support', entProcessMap.get('billing support').Id));
                    //}
                    if(SL_ENTITLEMENT_MAP.containsKey(a.Support_Level__c) && entProcessMap.containsKey(SL_ENTITLEMENT_MAP.get(a.Support_Level__c).toLowerCase())) {
                        createableEntitlements.add(createEntitlement(a.Id, a.Support_Level__c, entProcessMap.get(SL_ENTITLEMENT_MAP.get(a.Support_Level__c).toLowerCase()).Id));
                    }
                }
            
                if(updateableEntitlements.size() > 0) {
                    update updateableEntitlements;
                }
                if(createableEntitlements.size() > 0) {
                    insert createableEntitlements;
                }
        
            }
            createUpdateEntitlementFirstRunFlag = false;
        }
        // Vamsee Surya - End - ESESP-727 
        //--------JARVIS RELATED CHANGES----------

        list<string> accIDsforJarvis = new list<string>();
        for(Account a : lstAccounts) 
        {
            if(a.type != oldMap.get(a.Id).Type && a.Type.contains('- Active'))
            {
                accIDsforJarvis.add(a.Id);
            }        
        }
        if(!SC_Jarvis_CoreSecurityController.createPublicGroupForSObjectRecChk && !system.isFuture() && accIDsforJarvis.size() > 0)
        {
            SC_Jarvis_CoreSecurityController.createPublicGroupForSObjectRecChk=true;
            SC_Jarvis_CoreSecurityController.createPublicGroupForSObject(accIDsforJarvis,'Account');
        }
        // Vishnu Sharma - Start - ESESP-1588
        createCaseNotificationOnUpdate(lstAccounts,oldMap);
        // Vishnu Sharma - End - ESESP-1588
        
    }

    // Vishnu Sharma - Start - ESESP-1588
    public static void createCaseNotificationOnUpdate(List<Account> lstAccounts, Map<Id, Account> oldMap)
    {
        
        List<Case_Notification_Subscription__c> caseNotificationSubsList= new List<Case_Notification_Subscription__c>();
        List<Case_Notification_Subscription__c> caseNotificationSubsListToUpdate= new List<Case_Notification_Subscription__c>();
        List<Case_Notification_Subscription__c> caseNotificationSubsListToDelete= new List<Case_Notification_Subscription__c>();
        Case_Notification_Subscription__c tempCaseNotificationSubscription;
        SC_Utility__mdt teamRolerec = [Select Id,Value_Text__c from SC_Utility__mdt where Label = 'CXM value team role' limit 1];
        List<Id> accountIdList = new List<Id>();
        List<Account> accountsToProcess = new List<Account>();
        Map<Id,List<Case_Notification_Subscription__c>> accountVsCNSMap = new Map<Id,List<Case_Notification_Subscription__c>>();
        Map<Id,List<AccountTeamMember>> accountVsATMMap = new Map<Id,List<AccountTeamMember>>();
        Map<Id,List<String>> accountVsATMIds = new Map<Id,List<String>>();
        
        for(Account iteratedAcc : lstAccounts){
            
            if(iteratedAcc.Type.contains('- Active') && (!oldMap.get(iteratedAcc.Id).Type.contains('- Active') || iteratedAcc.OwnerId != oldMap.get(iteratedAcc.Id).OwnerId)){
                accountIdList.add(iteratedAcc.Id);
                accountsToProcess.add(iteratedAcc);
            }    
        }
    
        // Creating map for account vs CNS list
        List<Case_Notification_Subscription__c> existingCaseNotificationList = new List<Case_Notification_Subscription__c>();
        existingCaseNotificationList = [Select id,Account__c,User__c,Severity__c from Case_Notification_Subscription__c where Account__c IN: accountIdList AND Case_Record_Type__c = 'All'];
        for(Case_Notification_Subscription__c iteratedCNS : existingCaseNotificationList){
            if(!accountVsCNSMap.containsKey(iteratedCNS.Account__c)){
                accountVsCNSMap.put(iteratedCNS.Account__c,new List<Case_Notification_Subscription__c>());
            }
            
            accountVsCNSMap.get(iteratedCNS.Account__c).add(iteratedCNS);
        }

        // Creating map for account vs ATM list
        List<AccountTeamMember> existingATMList = new List<AccountTeamMember>();
        existingATMList = [Select Id,UserId,AccountId from AccountTeamMember where AccountId IN: accountIdList AND TeamMemberRole =: teamRolerec.Value_Text__c];
        for(AccountTeamMember iteratedATM : existingATMList){
            if(!accountVsATMMap.containsKey(iteratedATM.AccountId)){
                accountVsATMMap.put(iteratedATM.AccountId,new List<AccountTeamMember>());
            }
            if(!accountVsATMIds.containsKey(iteratedATM.AccountId)){
                accountVsATMIds.put(iteratedATM.AccountId,new List<String>());
            }
            accountVsATMMap.get(iteratedATM.AccountId).add(iteratedATM);
            accountVsATMIds.get(iteratedATM.AccountId).add(iteratedATM.UserId);
        }
    
        for(Account iteratedAccount : accountsToProcess){
            Set<Case_Notification_Subscription__c> CNSToBeUpdated = new Set<Case_Notification_Subscription__c>();
            Boolean ATMCNSFound = false;
            Integer count;
            Integer listSize;
            Case_Notification_Subscription__c newOwnerCNS = new Case_Notification_Subscription__c();
            
            if(accountVsCNSMap.containsKey(iteratedAccount.Id)){
                listSize = 0;
                listSize =  accountVsCNSMap.get(iteratedAccount.Id).size(); 
                
                // To delete previous owner's CNS record only if owner is changed.
                if(iteratedAccount.OwnerId != oldMap.get(iteratedAccount.Id).OwnerId){
                   
                    for(Case_Notification_Subscription__c iteratedCNS : accountVsCNSMap.get(iteratedAccount.Id)){
                        
                            
                                if(iteratedCNS.User__c == oldMap.get(iteratedAccount.Id).OwnerId){
                                    if(accountVsATMIds.containsKey(iteratedAccount.Id)){
                                        if(!accountVsATMIds.get(iteratedAccount.Id).contains(oldMap.get(iteratedAccount.Id).OwnerId)){
                                            caseNotificationSubsListToDelete.add(iteratedCNS);
                                        }
                                    }else{
                                        caseNotificationSubsListToDelete.add(iteratedCNS);
                                    }
                                }
                            
                        
                    }
                }
                count = 0;
                // To create/update CNS record for both account actions i.e. activation or owner change
                for(Case_Notification_Subscription__c iteratedCNS : accountVsCNSMap.get(iteratedAccount.Id)){
                    
                      
                    if(iteratedCNS.User__c == iteratedAccount.OwnerId){
                        //CNSToBeUpdated = iteratedCNS;
                        caseNotificationSubsListToUpdate.add(genericMethodForCNSCreateUpdate(iteratedCNS,iteratedAccount.OwnerId,iteratedAccount.Id));
                        break;
                    }
                    count = count+1;
                    if(count == listSize){
                        caseNotificationSubsListToUpdate.add(genericMethodForCNSCreateUpdate(new Case_Notification_Subscription__c(),iteratedAccount.OwnerId,iteratedAccount.Id));
                    }
                    
                }
                
            }else{
                caseNotificationSubsListToUpdate.add(genericMethodForCNSCreateUpdate(new Case_Notification_Subscription__c(),iteratedAccount.OwnerId,iteratedAccount.Id));
            }
            
            // Logic to create new CNS for team members only if account status is changed. 
            if(iteratedAccount.Type != oldMap.get(iteratedAccount.Id).Type){
                if(accountVsATMMap.containsKey(iteratedAccount.Id)){
                    for(AccountTeamMember iteratedATM : accountVsATMMap.get(iteratedAccount.Id)){
                        if(iteratedATM.UserId != iteratedAccount.OwnerId){
                            if(accountVsCNSMap.containsKey(iteratedAccount.Id)){
                                listSize = 0;    
                                listSize =  accountVsCNSMap.get(iteratedAccount.Id).size();   
                                count = 0;
                                for(Case_Notification_Subscription__c iteratedCNS : accountVsCNSMap.get(iteratedAccount.Id)){
                                    
                                    if(iteratedCNS.User__c == iteratedATM.UserId){
                                        ATMCNSFound = true;
                                        caseNotificationSubsListToUpdate.add(genericMethodForCNSCreateUpdate(iteratedCNS,iteratedATM.UserId,iteratedAccount.Id));
                                        break;
                                    }
                                    count = count + 1;
                                    if(count == listSize){
                                        caseNotificationSubsListToUpdate.add(genericMethodForCNSCreateUpdate(new Case_Notification_Subscription__c(),iteratedATM.UserId,iteratedAccount.Id));
                                    }
                                }
                            }else{
                                caseNotificationSubsListToUpdate.add(genericMethodForCNSCreateUpdate(new Case_Notification_Subscription__c(),iteratedATM.UserId,iteratedAccount.Id));
                            }
                        }
                    }
                }
            }

         
            
            
           
        }

       

        if(caseNotificationSubsListToDelete.size() > 0){
            delete(caseNotificationSubsListToDelete);
        }
        if(caseNotificationSubsListToUpdate.size() > 0){
            Upsert(caseNotificationSubsListToUpdate);
        }
    }
    // Vishnu Sharma - End - ESESP-1588 
    
    // Vishnu Sharma - Start - ESESP-1588 
    public static Case_Notification_Subscription__c genericMethodForCNSCreateUpdate(Case_Notification_Subscription__c caseNotificationRec,Id userId,Id accountId){
        //Generic method for create/update case notification subscription record
        caseNotificationRec.Account__c = accountId;
        caseNotificationRec.User__c = userId;
        caseNotificationRec.Case_Record_Type__c = 'All';
        if(!String.isBlank(caseNotificationRec.Severity__c) && caseNotificationRec.Severity__c.contains('3 & below')){
            caseNotificationRec.Severity__c = '1;2;3 & below'; 
        }else{
            caseNotificationRec.Severity__c = '1;2'; 
        }
        caseNotificationRec.Incident__c = 'Yes';
        caseNotificationRec.Portal_Visibility__c = 'All';
        caseNotificationRec.Sub_Type__c = '';
        caseNotificationRec.Case_Origin__c = '';
        caseNotificationRec.Origin__c = 'Implicit';
        return caseNotificationRec;
    }
    // Vishnu Sharma - End - ESESP-1588 

    private static Entitlement createEntitlement(Id accId, String eName, String eProcessId) {
        Entitlement ent = new Entitlement();
        ent.AccountId = accId;
        ent.SlaProcessId = eProcessId;
        ent.Name = eName;
        ent.StartDate = Date.Today();
        return ent;
    }
   
    /*
    * CR 3298201: Added by kusharma
    * Method for creating Task On Account for Media and Web Accounts.
    */
    private static void createTaskForAccount(List<Account> lAccount, boolean isInsert,
                                             Map<Id, Account> oldMap){
        System.debug('##@! New Logic PSA ' + lAccount +' ' + isInsert + ' '+ oldMap);
        
        List<String> lAllAccountId = new List<String>();
        List<Task> lTasksToInsert = new List<Task>();
        
        Set<String> sWebAccountId = new Set<String>();
        Set<String> sMediaAccountId = new Set<String>();
        
        Map<String, AccountTeamMember> mAccountAndTeamMembers = new Map<String, AccountTeamMember>();
        Map<String, Account> mWebAccount = new Map<String, Account>();
        Map<String, Account> mMediaAccount = new Map<String, Account> ();
        Map<String, Account> mAllAccounts = new Map<String, Account>();
        
        Id standardActivityRT = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Standard Activity').getRecordTypeId();
        
        // changes by Vandhana for ESESP-6141 : commented out reference to Finance_Tier__c as the field will be deleted                                 
        for(Account varAccount :lAccount){
            if(isInsert || 
                (!isInsert && ! varAccount.Is_Auto_Task_Created__c
                 && (varAccount.Division_Formula__c != oldMap.get(varAccount.Id).Division_Formula__c 
                     || varAccount.Target_Category__c != oldMap.get(varAccount.Id).Target_Category__c
                     //|| varAccount.Finance_Tier__c != oldMap.get(varAccount.Id).Finance_Tier__c 
                    )
                )
              )
            {
                System.debug('##@! New Logic PSA crieteria match ');
                
                if(varAccount.Division_Formula__c != null && varAccount.Division_Formula__c.equalsIgnoreCase('Web') 
                   && varAccount.Target_Category__c != null && varAccount.Target_Category__c.equalsIgnoreCase(GsmUtilClass.getGSMSettingValue('Wallet_Grade_Picklist_Value_Strategic'))){
                    varAccount.Is_Auto_Task_Created__c = true;
                    sWebAccountId.add(varAccount.Id);
                    mAllAccounts.put(varAccount.Id, varAccount);
                }
                
                // changes by Vandhana for ESESP-6141 : commented out reference to Finance_Tier__c as the field will be deleted                                 
                if(varAccount.Division_Formula__c != null && varAccount.Division_Formula__c.equalsIgnoreCase('Media and Carrier') 
                   //&& varAccount.Finance_Tier__c != null && varAccount.Finance_Tier__c.equalsIgnoreCase('A')
                  )
                {
                    varAccount.Is_Auto_Task_Created__c = true;
                    System.debug('##@! New Logic PSA crieteria match ');
                    sMediaAccountId.add(varAccount.Id);
                    mAllAccounts.put(varAccount.Id, varAccount);
                }
                // end of changes by Vandhana
            }
        }            
            lAllAccountId.addAll(sWebAccountId);
            lAllAccountId.addAll(sMediaAccountId);
            
            if(! lAllAccountId.isEmpty()){
                if(! isInsert){
                    for(AccountTeamMember varAccountTeamMember : [SELECT AccountId, TeamMemberRole, 
                                                                  UserId, Id, Account.Name
                                                                  FROM AccountTeamMember 
                                                                  WHERE AccountId IN :lAllAccountId 
                                                                  AND TeamMemberRole = 'Technical Sales - Primary']){
                        mAccountAndTeamMembers.put(varAccountTeamMember.AccountId, varAccountTeamMember);
                    }
                }
                for(String varAccountId :lAllAccountId){
                    String ownerId = mAccountAndTeamMembers.containsKey(varAccountId) ? mAccountAndTeamMembers.get(varAccountId).UserId 
                                     : GSM_Custom_Settings__c.getValues('Common#ONAUserId').Value__c ;
                    String subjectEnd = sWebAccountId.contains(varAccountId) ? 'Monthly Touchpoint – Cat 1' : 'Monthly Touchpoint – Finance Tier';
                    lTasksToInsert.add(initializeTask(varAccountId,ownerId, 'Regular Cadence Customer Meeting',
                                                      mAllAccounts.get(varAccountId).Name, 'Customer Work/Meeting',
                                                      '',subjectEnd,28, standardActivityRT)); 
                }
                
                if(! lTasksToInsert.isEmpty()){
                    try{
                        insert lTasksToInsert;
                    }
                    catch(Exception e){
                        
                    }
                }
            }
    }
    
    private static Task initializeTask(String whatId, String OwnerId, String preSalesCat, String accountName,
                                       String preSalesActType, String subjectStart,String subjectEnd, Integer dueDate,
                                       String recordTypeId){
        Task varTask = new Task();
        varTask.WhatId = whatId;
        varTask.OwnerId = OwnerId;
        varTask.Technical_Pre_Sales_Category__c = preSalesCat;
        varTask.Technical_Presales_Activity_Type__c = preSalesActType;
        varTask.Subject = (subjectStart + ' ' + accountName + ' ' + subjectEnd).trim();
        varTask.ActivityDate = System.today().addDays(dueDate);
        varTask.Priority = 'Normal';
        varTask.Status = 'In Progress';
        varTask.RecordTypeId = recordTypeId;
        System.debug('#@!!@# ' + varTask);
        return varTask;
    }
    
    // changes by Vandhana for ESESP-5494 Support Differentiation for AkaTec (Saturn)
    public static void setSupportDeliveryType(Boolean isInsert, List<Account> newAccounts, Map<Id,Account> oldMap)
    {
        List<Account_Support_Delivery_Type_Mapper__c> lstDelTypeMapper = new List<Account_Support_Delivery_Type_Mapper__c>();
        Map<String,Set<String>> mapSuppDelTypeSuppLevel = new Map<String,Set<String>>();
        List<String> lstAccSupportLevel = new List<String>();
        Set<String> setAccSupportLevel = new Set<String>();
        Set<String> exemptedCountries = new Set<String>();//Added by Aditi - ESESP-5717
        Set<String> exemptedTerritory = new Set<String>();//Added by Aditi - ESESP-5717
        Map<String,Set<String>> mapSuppDelTypeExemptCountry = new Map<String,Set<String>>();//Added by Aditi - ESESP-5717
        Map<String,Set<String>> mapSuppDelTypeExemptTerritory = new Map<String,Set<String>>();//Added by Aditi - ESESP-5717
        
        Map<Id,Account> mapValidAccounts = new Map<Id,Account>();
        
        String additionalSuppLevel = '';
        
        for(Account eachAcc : newAccounts)
        {
            //Updated below query by Aditi - ESESP-5717 - The method should fire when there is a change in BillingCountry or Territory and the Support Level is not blank
            if(String.isNotBlank(eachAcc.Type) && eachAcc.Type != 'Lead' && !eachAcc.Type.containsIgnoreCase('inacti') && String.isNotBlank(eachAcc.Support_Level__c)
                &&
                ( isInsert
                 || 
                 (!isInsert && (eachAcc.Support_Level__c != oldMap.get(eachAcc.Id).Support_Level__c || eachAcc.Type != oldMap.get(eachAcc.Id).Type || eachAcc.BillingCountry != oldMap.get(eachAcc.Id).BillingCountry
                 || eachAcc.TERR_HIER_5__c != oldMap.get(eachAcc.Id).TERR_HIER_5__c))
                )
               )
            {
                mapValidAccounts.put(eachAcc.Id,eachAcc);
            }
        }
        
        if(!mapValidAccounts.isEmpty())
        {
            //Updated below query by Aditi - ESESP-5717
            lstDelTypeMapper = [SELECT Support_Delivery_Type__c,Support_Level__c,Additional_Support_Levels__c, Exception_Countries__c,Exemption_Territories__c  
                                FROM Account_Support_Delivery_Type_Mapper__c];
            
            for(Account_Support_Delivery_Type_Mapper__c eachMapper : lstDelTypeMapper)
            {   
                lstAccSupportLevel = new List<String>();
                if(String.isNotBlank(eachMapper.Support_Level__c))
                {
                    lstAccSupportLevel.addAll(eachMapper.Support_Level__c.split(';'));
                }
                
                if(String.isNotBlank(eachMapper.Additional_Support_Levels__c))
                {
                    additionalSuppLevel = eachMapper.Additional_Support_Levels__c.replace('\r\n','\n');
                    additionalSuppLevel.replaceAll('[\n,]',';');
                    lstAccSupportLevel.addAll(additionalSuppLevel.split(';'));
                }
                
                for(Integer i=0; i<lstAccSupportLevel.size();i++)
                {
                    setAccSupportLevel.add(lstAccSupportLevel[i].trim());
                }
                
                
                //Added below by Aditi - ESESP-5717
                if(String.isNotBlank(eachMapper.Exception_Countries__c))
                {
                    String temp = eachMapper.Exception_Countries__c.replace('\r\n','\n');
                    temp.replaceAll('[\n,]',';');
                    exemptedCountries.addAll(temp.split(';'));
                }
                if(String.isNotBlank(eachMapper.Exemption_Territories__c))
                {
                    String temp = eachMapper.Exemption_Territories__c.replace('\r\n','\n');
                    temp.replaceAll('[\n,]',';');
                    exemptedTerritory.addAll(temp.split(';'));
                }
                
                mapSuppDelTypeSuppLevel.put(eachMapper.Support_Delivery_Type__c,setAccSupportLevel);
                //Added below by Aditi - ESESP-5717
                mapSuppDelTypeExemptCountry.put(eachMapper.Support_Delivery_Type__c,exemptedCountries);
                mapSuppDelTypeExemptTerritory.put(eachMapper.Support_Delivery_Type__c,exemptedTerritory);
            }
            
            for(Id eachAccId : mapValidAccounts.keySet())
            {
                mapValidAccounts.get(eachAccId).Support_Delivery_Type__c = 'Geo';
                if(!mapSuppDelTypeSuppLevel.isEmpty())
                {
                    for(String eachSuppDelType : mapSuppDelTypeSuppLevel.keyset())
                    {
                        Boolean isExemptedCountry = String.isNotBlank(mapValidAccounts.get(eachAccId).BillingCountry) && mapSuppDelTypeExemptCountry.get(eachSuppDelType).contains(mapValidAccounts.get(eachAccId).BillingCountry)?true:false;
                        Boolean isExemptedTerritory = String.isNotBlank(mapValidAccounts.get(eachAccId).TERR_HIER_5__c) && mapSuppDelTypeExemptTerritory.get(eachSuppDelType).contains(mapValidAccounts.get(eachAccId).TERR_HIER_5__c)?true:false;
                        //Updated by Aditi - to exempt China, Japan and Korea from APJ rule - ESESP-5717
                        if(String.isNotBlank(mapValidAccounts.get(eachAccId).Support_Level__c) && mapSuppDelTypeSuppLevel.get(eachSuppDelType).contains(mapValidAccounts.get(eachAccId).Support_Level__c)
                          && (!isExemptedCountry || (isExemptedCountry && isExemptedTerritory)))
                        {
                            if(mapValidAccounts.get(eachAccId).Support_Delivery_Type__c != eachSuppDelType)
                                mapValidAccounts.get(eachAccId).Support_Delivery_Type__c = eachSuppDelType;
                        }
                    }
                }
            }
        }            
    }
    public static void validateElevationDLOnAccount(Boolean isInsert, List<Account> newAccounts, Map<Id,Account> oldMap)
    {
        Map<Id,Account> mapValidAccounts = new Map<Id,Account>();
        
        for(Account eachAcc : newAccounts)
        {
            if(String.isNotBlank(eachAcc.Account_Elevation_Mailing_List__c) 
               && (isInsert || (!isInsert && (eachAcc.Account_Elevation_Mailing_List__c != oldMap.get(eachAcc.Id).Account_Elevation_Mailing_List__c))))
            {
                List<String> accElevDLEmailIDs = eachAcc.Account_Elevation_Mailing_List__c.replace('\r','\n').replaceAll('[\\n;]',',').split(',');
                System.debug(accElevDLEmailIDs);
                List<String> validatedEmailIDs = new List<String>();
                
                if(!accElevDLEmailIDs.isEmpty())
                {
                    for(String eachEmailId : accElevDLEmailIDs)
                    {
                        // String emailRegex = '([a-zA-Z0-9_\\-\\.+]+)@((\\[a-z]{1,3}\\.[a-z]{1,3}\\.[a-z]{1,3}\\.)|(([a-zA-Z0-9\\-]+\\.)+))([a-zA-Z]{2,10}|[0-9]{1,3})';
                        // Pattern.matches('^((\\w+([-+.\']\\w+)*@akamai\\.com*([\\s]*?[;][\\s]*))*)$'
                        if(String.isNotBlank(eachEmailId.trim()))
                        {
                            if(!Pattern.matches('^((\\w+([-+.\']\\w+)*@akamai\\.com*([\\s]*?[\\s]*))*)$',eachEmailId.trim()))
                            {
                                eachAcc.addError('\'' + eachEmailId + '\' is not valid. Please enter valid Akamai email addresses separated by comma.');
                            }
                            else
                            {
                                validatedEmailIDs.add(eachEmailId.trim());
                            }
                        }
                    }
                    eachAcc.Account_Elevation_Mailing_List__c = String.join(validatedEmailIDs,',');
                }
            }
        }
    }    
}