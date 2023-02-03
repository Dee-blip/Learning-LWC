/*************
    CaseTrigger_bi_bu
    @version 1.0
    @author Karteek Mekala <kmekala@akamai.com>
    @Description : This trigger is called on 'before insert' and 'before update' events on the Case object.
                   It takes care of the following :
                   - Update the Case.ContactId with the Case.CreatedById when Case.ContactId = null

    @History
    --Developer                                         --Date          --Change
    Karteek Kumar M                                     18/03/2010      Created the trigger
    Vinayendra T N                                  8/12/2010       CR 884692 Momentum Email to Case
                                    - The trigger should run only if Email To Case is false.
     Ali KM               11/Mar/2013       CR 2068273 - Invoice Review Cases Process migration from Siebel to SF.
                                            - Update the Manual Invoice Approved By / Date field once Manual Invoice is checked.                                                                                                - The trigger should run only if Email To Case is false.
    Pitamber Sharma(Appirio Offshore)   09/05/2013      Update Case Entitlement (T-140779)
    Pitamber Sharma(Appirio Offshore)       10/05/2013      Assign Business Hours to Cases (T-140865)
    Vinod Kumar(Appirio Offshore)               13/06/2013     Addd trigger update the Case-Entitlement if case is a Stability Engineering
    Pitamber Sharma (Appirio Offshore)  11/07/2013      Update Case.ContactPhone to Contact.Phone on insert and update
  Denise Bacher (salesforce.com)      10/22/2013      automatic syncing of new case records with the DR organization and re-establish the lookup relationships if the record is recieved from another organization
  Sripadraj                           04/02/2014     CR 2486721 Commented old field and added new field for update on Manual Invoice Case Approval
    Kunal Sharma: 05/21/2014    Removed extra SOQLs from the Trigger.
    Sonia Sawhney: 07/17/2014   CR 2712153 - DR: Reverse Update Issue for Objects and Commented Logic for populating the Owner_RW__c field as this is no longer used
    Akhila Vidapanapati : 08/01/2015 CR#2883378 : Added DR bypass condition
    Akhila Vidapanapati: 24/02/2015 CR 2921691 - Emails not sent when using 'Send Notification Email' check box
    Ankit Chawla: 24/03/2015 CR 2965556 - Updating Approved_On__c field once a case is moved to Approved Status
    Akhila Vidapanapati 27-04-15    CR# 2919657: IR Milestone for AMG customer onboarding Cases
    Akhila Vidapanapati:  06/25/2015: CR#3024056 :Removed call for ChangePSCaseOwner
    Aditya Sonam: 25-04-2016 : CR:3290661 - CCare Technical Escalation Automation
    Himanshu Kar        17-JUN-2016     3333321(16.6)     Create BOCC Entitlement
    Aditya Sonam        26-09-2016      3310661    Do Not Show in Portal and Visibility Changes
    Chakradhar Kasturi  09-JAN-2017     3280651,3504121 Updating the resolution owner in case of FIN_IR_INTL_QUEUE
    Ankit Chawla        08-Mar-2017     3412081 - Fixed 201 soql query error as select was happening in a loop
    Vandhana        : 27-May-2017   JIRA ESESP-551      Cases for Specialist Pre-Sales - Part 2
    Aditya Sonam        19th June,2017  ESESP-574 : Legacy Type field Update based on Legacy Type Products
    Aditya Sonam        21-Sept-2017    ESESP-435 : NQLB Connector Setup -> Community Response Milestone Setup
    Vandhana            26 Oct 2017     ESESP-595 : S2ET Case History Tracker
    Vandhana            20 Nov 2017     ESESP-820 : Policy Domain on Managed Sec Cases
    Sumanth             20 March 2018   ESESP-1004 : Check for External Dependency JIRA for Solution Code - Nominum
    Vandhana            20 April 2018   ESESP-603 : Specifying Support Advocacy (SDM) + Time Based Escalations for Premium_2.0 accounts
    Sumanth             18 May 2018     ESESP-1204 : Send email to Old/New/ owner & Case Creator whenever ownership changes
    Vandhana            21 June 2018    ESESP-692 : Force close activities before closing ECOB/NCOB AMG cases
    Aditya              18-Jan-2019     ESESP-1402: Creation of a queue for AMP
    Sumanth             26 Feb 2019     ESESP-1916: Make Attachment Mandatory for AMG Migration Cases before Case Closure

    Aditya              19th Feb 2019   ESESP-1901: Assign AMG user to AMG Case on RT change from Tech to AMG
    Pinkesh             5th Mar 2019    ESESP-2080: Bulk Close Case-Invalid from Case view in Lightning
    Vikas               20-Feb-2019     ESESP-1869: Validation for Small Deal Order Approvals and other validations
    Vandhana            13th Mar 2019   ESESP-1942: Assign the case for Sub-type = Edgesuite Transition Approval
    Vishnu              01-Jul-2019     ESESP-758: AMG SLA improvements
                                        - on case transition from Akatech to AMG - fill Transition__c and Amg_received_date__c fields
                                        - on AMG Case Closure, Auto Complete open milestones ( Initial Response or AMG Initial Response)
    Ankit               03-June-2019    IRC-1: Removed the custom setting call from for loop and optimized it.
    Vishnu              19-Aug-2019     ESESP-2362  Adding CMG Case type to SCCases && UpdateCaseEntitlement
    Sumanth             18-Sep-2019     ESESP-2198 SOCC Related Changes
    Vandhana            26-Sept-2019    ESESP-2635 AMG : AMG cases to be assigned ONLY to AMG queues (or AMG agents)
    Pinkesh             21-Oct-2019     ESESP-2776 AMG : AMG Auto Provisioning CP Code cases
    Sharath             18-Dec-2019     ESESP-2467 Sub-domain Takeover
    Sheena              05-Feb-2020     ESESP-3075: Partner Account and Indirect Customer functionality for AMG Cases 
    Sheena              10-Feb-2020     ESESP-3152: Populating Account Owner and AMG Aligned Rep fields for AMG cases
    Vandhana            13-Feb-2020     ESESP-2039: Set all SiteShield Map Degradation AMG cases to High priority
    Vandhana Krishnamurthy 10/05/2020   ESESP-3524 : S2ET
    Vikas               02/06/2020      ESESP-3663 : Provisioning 
    Vandhana Krishnamurthy 22/07/2020   ESESP-2597 : New "instant Engagement Request" flag for Sev 1 cases for support advocacy services
    Vikas               24/09/2020      ESESP-4158  Added new Service values for Provisioning cases
    Vishnu Vardhan      10/10/2020      ESESP-2826 :PST related Case Trigger logic 
    Sumukh SS           26-Nov-2020     ESESP-2235 :Akatec Enhanced Milestones
    Vandhana Krishnamurthy 23/Feb/2021  ESESP-2346 : Carrier to Technical LX Migration
    Vikas R 			22/June/2021    ESESP-4647 : Check specific field update for MS cases
    Sharath             March 2021      ESESP-4356 : JARVIS 
    Aditi Singh 		16/August/2021  ESESP-5670 : PS Product - Provisioning Dashboard Changes - changed Platform Product occurrence with Case Product
    Sujay               07-Sep-2021     ESESP-5678 : Adding new entry for email to Case
    Sujay               11-Oct-2021     ESESP-5981 : Avoiding Tasks closure before case closure, Auto Task on 24 PS Cases.
    Vishnu Sharma       29-Nov-2021     ESESP-5772 : Added logic to restrict edit for OCID field if user is not account team member with required role
    Sharath Prasanna    01-Dec-2021     ESESP-6367 : Reseller Use-cases.Changing the way Case is shared for Resellers AND ATT Usecase
    Jay Rathod          11-Feb-2022     ESESP-6678 : Added validation override and status change check
    Jay Rathod          15-Feb-2022     ESESP-6711 : Populate Created By Account if Case Contact is Akamai contact
*/


trigger CaseTrigger_bi_bu on Case (before insert, before update, after undelete)
{
    //Check for preventing recursive trigger calls
    if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true)))
    {
        // on insert/update set Owner_RW__c field
        if(Trigger.isBefore){
            ExternalSharingHelper.linkUserLookups('Case', Trigger.new, Trigger.isUpdate, Trigger.oldMap);
            ExternalSharingHelper.linkRecordType('Case', 'Record_Type_RW__c', Trigger.new);
            //Added by ssawhney for CR 2712153 - Moved logic to before trigger for populating the lookups
            ExternalSharingHelper.linkObjectsSync('Case', Trigger.new, Trigger.isUpdate, Trigger.oldMap);
            //Commented out by ssawhney on 07/17/2014 - Owner_RW__c field is no longer used
            //ExternalSharingHelper.CaseSetOwnerRW(Trigger.new, Trigger.oldMap, Trigger.isUpdate);
        }
    }

    //Email_to_Case__c CustomSettingsMomentum = Email_to_Case__c.getInstance('Momentum');
    Email_to_Case__c CustomSettingsProdMgmt = Email_to_Case__c.getInstance('ProdMgmt');
    List<Case> scCases = new List<Case>();
    list<Case> lEPECases = new list<Case>();
    List<String> listOfRecordTypes = GSMUtilClass.GetCustomSettingValue('CaseTrigger#updateContact').split(',');
    Set<String> setOfRecords = new Set<String>();
    for(String rtype : listOfRecordTypes)
    {
         setOfRecords.add(rtype.trim());
    }
    //Get the Map of Case RecordTypes
    map<Id, Schema.RecordTypeInfo> mCaseRecordType = Case.sObjectType.getDescribe().getRecordTypeInfosById();
    map<Id, string> mRecordType = new map<Id,string>();
    List<Case> caseListOA = new List<Case>();
    List<Id> oppIdList = new LIst<Id>();
    for(string varCaseRecordTypeId :mCaseRecordType.keySet()){
        mRecordType.put(varCaseRecordTypeId, mCaseRecordType.get(varCaseRecordTypeId).getName());
    }

    //Map<Id, RecordType> rTypes =
                    //new Map<Id, RecordType>([SELECT id, Name FROM RecordType WHERE isActive=true and sObjectType = 'Case']);

    for(Case c : Trigger.new)
    {
        //Pinkesh Rathore ESESP-2080: Adding check to mark case as Invalid if Close_Case_Invalid__c is checked.
        if(Trigger.IsUpdate && c.Close_Case_Invalid__c)
            c.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Invalid Case').getRecordTypeId();
        
        // changes by Vandhana for ESESP-2346 : Carrier LX Migration
        if(mRecordType.get(c.RecordTypeId) != null && mRecordType.get(c.RecordTypeId).equals('Carrier Products'))
        {
            c.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
            c.Service_Category__c = c.Sub_Type__c;
            c.Sub_Type__c = 'Carrier';
        }
        
        if(mRecordType.get(c.RecordTypeId) != null && (mRecordType.get(c.RecordTypeId).equals('Technical')
                                                       || mRecordType.get(c.RecordTypeId).equals('AMG')
                                                       || mRecordType.get(c.RecordTypeId).equals('Billing')
                                                       || mRecordType.get(c.RecordTypeId).equals('CMG')
                                                       || mRecordType.get(c.RecordTypeId).equals('GSS CSAT')
                                                       || mRecordType.get(c.RecordTypeId).equals('Invalid Case')
                                                       || mRecordType.get(c.RecordTypeId).equals('Professional Services')
                                                       || mRecordType.get(c.RecordTypeId).equals('Revenue Recognition')
                                                       || mRecordType.get(c.RecordTypeId).equals('Stability Engineering')
                                                       || mRecordType.get(c.RecordTypeId).equals('Partner Technical Support')
                                                       || mRecordType.get(c.RecordTypeId).equals('Emerging Products Engineering')
                                                       //|| mRecordType.get(c.RecordTypeId).equals('Carrier Products')
                                                       || mRecordType.get(c.RecordTypeId).equals('Community Response')))
        {
            scCases.add(c);
        }
    }

    //Setting scPSUpdateFlag to False to avoid recursive calls
    //CaseTriggerClass.scPSUpdateFlag = False;

    /* Update the Case.ContactId with the Current User when Case.ContactId = null */
    if(Trigger.isInsert)
    {
        List<Case> updateList = new List<Case>();
        //List<Case> updateEntitlementList = new List<Case>();
        List<Case> updateBusinessHoursList = new List<Case>();
        if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
        {
            for(Case c:Trigger.new)
            {
                //ESESP-2776
                //ESESP-4265:added 'c.Request_Sub_Type__c != 'Peer Review' condition to bypass the logic when case is cloned for peer review
                if(c.Subject != null && c.Subject.containsIgnoreCase('Auto-provisioned CP Code') && c.Request_Sub_Type__c != 'Peer Review')
                {
                    String cpReqEmail = '';
                    c.Service__c = 'CP Code Management';
                    c.Request_Type__c = 'New CP Code';
                    if(c.Description != null)
                        cpReqEmail = EmailToCaseUtility.findString(c.Description, 'CP Code Requestor :');
                    if(String.isNotBlank(cpReqEmail) && cpReqEmail.contains('@') && !cpReqEmail.contains('akamai'))
                        c.Request_Sub_Type__c = 'Customer-Provisioned';
                    else
                        c.Request_Sub_Type__c = 'N/A - Not Applicable';
                }

                //throw new CustomException('Created By : ' + c.CreatedById);
                //System.Debug('casecheckpoint'+ setOfRecords + 'and' + rTypes.get(c.RecordTypeId).Name);
                if(c.ContactId == null && c.Email_to_case__c==false && setOfRecords.contains(mRecordType.get(c.RecordTypeId)))
                    updateList.add(c);
            }
            //CaseTriggerClass.UpdateContactName(updateList);
            SC_CaseTriggerHelperClass2.UpdateContactName(updateList);
        }

        //CaseTriggerClass.updateCaseEntitlement(updateEntitlementList, mRecordType);
        //Kunal: Added record type check for SC
        //Added by Vamsee : Recursion Check - ESESP-1514
        if(CaseTriggerClass.avoidRecursionBusinessHours){
            CaseTriggerClass.avoidRecursionBusinessHours = false;
            if(scCases.size()>0)
            {
                CaseTriggerClass.updateBusinessHours(scCases, mRecordType, false);
            }
        }

        List<String> lContractIds = new List<String>();
        List<Case> lCPSCases = new List<Case>();

        List<Id> lstCasePreSales = new List<Id>();

        if(Trigger.isBefore)
        {
            if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
            {
                for(Case varCase :Trigger.new)
                {
                    if(mRecordType.get(varCase.RecordTypeId).equals('Web Experience'))
                    {
                        lContractIds.add(varCase.IR_Original_Contract_Id__c);
                        lCPSCases.add(varCase);
                    }

                    /*  Changes by Vandhana Krishnamurthy for JIRA ESESP-551
                    Pre-Sales cases should get routed automatically upon creation to respective queues
                    */
                    if(mRecordType.get(varCase.RecordTypeId).equals('Pre-Sales'))
                    {
                        varCase.Case_Assignment_Using_Active_Rules__c = true;
                    }

                    //ESESP-2467: Sud-domain Takeover tool
                    if(mRecordType.get(varCase.RecordTypeId).equals('Technical') && varCase.Sub_Type__c == 'Subdomain Takeover')
                    {
                        varCase.status = 'Closed';
                        varCase.Validation_Override__c = true;

                    }                    
                }

                if(lContractIds.size()>0 && lCPSCases.size()>0)
                    SC_CPSNotifications.populateAccountIdBasedOnContractId(lContractIds, lCPSCases);
            }
        }
    }

    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
       // Profile loggedUserProfile =  [Select Name from Profile where Id=:UserInfo.getProfileId() limit 1];
        //string lunaPortalIntProfId = SC_PSEditCaseProfileId__c.get('LunaPortalIntegration').ProfileId;
        SC_PSEditCaseProfileId__c lunaPortalIntCust = SC_PSEditCaseProfileId__c.getInstance('LunaPortalIntegration');
        SC_Enable_Service_Validation__mdt enableServVal = [Select Enable_Service_Validation__c from SC_Enable_Service_Validation__mdt where Label = 'Professional Services' limit 1];

        List<Case> lstPSCases = new List<Case>();
        Set<Id> psCaseAccId = new Set<Id>();

        List<Case_History_Tracker__c> chList = new List<Case_History_Tracker__c>();

        Case_History_Tracker__c ch = new Case_History_Tracker__c();
        List<SC_Case_History_Tracker__mdt> histTrackMDT = [Select Tracked_Field_Name__c, Tracked_Field_API_Name__c,
                                                           Duration_Field_API__c , Value_stored_in_Case_Field__c,Last_Update_field_on_Case__c
                                                           from SC_Case_History_Tracker__mdt];

        Map<String,SC_Case_History_Tracker__mdt> histTrackMDTMap = new Map<String,SC_Case_History_Tracker__mdt>();

        for(SC_Case_History_Tracker__mdt eachMDT : histTrackMDT)
        {
            histTrackMDTMap.put(eachMDT.Tracked_Field_API_Name__c,eachMDT);
        }

        /* Changes by Vandhana Krishnamurthy for JIRA ESESP-354
            * Adding service entitlement validation
        */

        /*  Changes by Vandhana Krishnamurthy for JIRA ESESP-820
            * Association of Policy Domain on Managed Security Cases
            * Ensure Case Product matches with selected PD's Product/Additional Product
        */
        List<Case> lstMSCases = new List<Case>();
        List<Id> polDomId = new List<Id>();

        List<Case> lstAMGCases = new List<Case>();
        List<Id> lstAMGCaseOwnerIds = new List<Id>();
        
        Map<Id,Case> mpAMGCOBCases = new Map<Id,Case>();
        SC_Utility__mdt util = [SELECT Value_Text__c
                                FROM SC_Utility__mdt
                                WHERE DeveloperName = 'COB_Case_Status_Values' limit 1];
        Set<String> statusVals = new Set<String>(util.Value_Text__c.split(','));
        
        //OA Changes
        List<Case> lOACaseOppOwner = new List<Case>();
        List<Id> lOACaseOppId = new List<Id>();
        
        List<SC_Order_Approval__mdt> lErrorMessages = [SELECT Value__c,MasterLabel,DeveloperName,Active__c
                                                FROM SC_Order_Approval__mdt 
                                                WHERE Active__c = TRUE
                                               ];    
        
        Map<String,String> mErrorMssgRec = new Map<String,String>();
        
        for(SC_Order_Approval__mdt eachMDTRec : lErrorMessages)
        {
            mErrorMssgRec.put(eachMDTRec.MasterLabel,eachMDTRec.Value__c);
        }
        
        List<Case> lOACase = new List<Case>();
        List<Id> lOACloseCaseId = new List<Id>();
        List<Id> lOACloseCaseOppId = new List<Id>();
        List<Id> parentCaseIdList = new List<Id>();
        
        List<Id> oaCheckOwnerId = new List<Id>();
        List<Case> oaCheckOwnerIdCase = new List<Case>();
        List<Case> caseApproverList = new List<Case>();
        List<Id> accountIdsToCheckGST = new List<Id>();
        List<Id> oppIdListGST= new List<Id>();
        List<Case> caseListOAForGSTcheck = new List<Case>();
        //SFDC-8991
        Set<Id> caseOpptyOAAutoRenewal = new Set<Id>();
		//OA Changes End
        
        //Added by Bhavesh,ESESP-3590, RCA request changes
        List<Id> rcaRequestCaseList = new List<ID>();
        Set<Id> rcaStatusUpdatedByUserSet = new Set<Id>();
        List<Id> rcaStatusUpdatedCaseList = new List<Id>();
        
        List<Id> closedCaseIds = new List<Id>();
        List<Id> pendingCaseIds = new List<Id>();
        List<Id> servIncidentIds = new List<Id>();
        List<Id> rcaUsrIds = new List<Id>();
        List<Id> caseIdsToCheckPeerValue = new List<Id>();
        Set<Id> rcaCreatedUpdatedByUserList = new Set<Id>();
        Set<Id> rcaIraptApproverUserList = new Set<Id>();
        
        // changes by Vandhana for S2ET ESESP-3524
        Map<Id,Case> s2etCaseClose = new Map<Id,Case>();
        
        // changes by Vikas for Provisioning ESESP-3663	
        Map<Id,Case> plxCaseClose = new Map<Id,Case>();
        // changes by Vikas for Provisioning ESESP-3663
        Map<String,String> mapSCUtilMDTVal = new Map<String,String>();
        
        //Changes for jarvis: Fetching JarvisLimitedBetaAccount as well.
        Set<String> limitedBetaAccountIds;

        //ESESP-5678 : Fetch 24PS queue Id with existing one's
        List<SC_Utility__mdt> lstSCUtilMDT = [SELECT DeveloperName,Value_Text__c
                                              FROM SC_Utility__mdt
                                              WHERE DeveloperName IN ('S2ET_Queue_Id','PS24_Queue_Id' ,'Plx_Queue_Id', 'Plx_Products','Plx_Service_Values','JarvisLimitedBetaAccountSFId','JarvisLimitedBetaAccountSFId2')];
        
        for(SC_Utility__mdt eachRec : lstSCUtilMDT)
        {
            if(eachRec.DeveloperName.contains('JarvisLimitedBetaAccountSFId'))
            {
                if(eachRec.Value_Text__c != null && eachRec.Value_Text__c != 'ALL')
                {                    
                    if(limitedBetaAccountIds == null)
                    {
                        limitedBetaAccountIds = new Set<String>();
                    }
                    limitedBetaAccountIds.addAll(eachRec.Value_Text__c.split(','));
                }
                //system.debug('limitedBetaAccountIds: ' + limitedBetaAccountIds.size());
            }
            else 
            {
                mapSCUtilMDTVal.put(eachRec.DeveloperName,eachRec.Value_Text__c);    
            }            
        }
        
        if(Trigger.isBefore)
        {
            Set<Id> contactIds = new Set<Id>();
            Set<Id> akamaiContactsIds = new Set<Id>();
            if(Trigger.isInsert){
                for(Case c : Trigger.new){
                    if(c.ContactId != null){
                        contactIds.add(c.ContactId);
                    }
                }
                if(!contactIds.isEmpty()){
                    for(Contact c : [SELECT Id,Account.Name FROM Contact WHERE Id IN :contactIds AND AccountId != NULL AND Account.Name LIKE '%Akamai%']){
                        akamaiContactsIds.add(SC_Jarvis_utility.convertToEighteen(c.Id));
                    }
                }
            }


            for(Case varCase : Trigger.new)
            {
            
                /*  Changes by Sumukh SS for Akatec Enhanced Milestones ESESP-2235*/
                
                                if(trigger.isUpdate && mRecordType.get(varCase.RecordTypeId).equals('Technical') && ((varCase.RecordTypeId!=Trigger.OldMap.get(varCase.id).recordtypeid)|| (varCase.Do_Not_Show_in_Portal__c!=Trigger.OldMap.get(varCase.id).Do_Not_Show_in_Portal__c && varCase.Do_Not_Show_in_Portal__c==false)))
                    {
                        varCase.MilestoneFire__c=null;
                    }


                //changes for Jarvis: Setting Lookup
                // Changes for ESESP-6367
                if(varCase.Isclosed == False){
                    
                Id currentAccountId = varCase.accountId != null? SC_Jarvis_utility.convertToEighteen(varCase.accountId) : null;
                system.debug('---Vamsee--Bi-BU--'+currentAccountId);
                if(Trigger.isInsert)
                {
                    varCase.Apply_Jarvis_Logic__c= false;
                	//Jarvis Changes by Vamsee - ESESP-6207
                    Id contactId = varCase.ContactId != null ? SC_Jarvis_utility.convertToEighteen(varCase.ContactId) : null;
                    varCase.Created_By_Account__c = varCase.Created_By_Account__c == null ? (varCase.Contact_Account__c != null && !akamaiContactsIds.contains(contactId)? varCase.Contact_Account__c :varCase.accountId) : varCase.Created_By_Account__c;
                    //if(varCase.Accountid != varCase.Contact_Account__c && limitedBetaAccountIds.contains(varCase.Contact_Account__c))
                    //{
                   	//	varCase.Created_By_Account__c = varCase.Contact_Account__c;
	                //}
	                
                }
                
                if(currentAccountId != null && !varCase.Do_Not_Show_in_Portal__c && varCase.RecordTypeId != null &&
                   (limitedBetaAccountIds == null || Test.isRunningTest() ||
                    limitedBetaAccountIds.contains(currentAccountId)
                   )
                  )                    
                {
                    //varCase.Created_By_Account__c = varCase.Created_By_Account__c == null?
                    //varCase.AccountId : varCase.Created_By_Account__c;
                    
                    if(
                        varCase.ATT_RecordType__c != '' ||
                        mRecordType.get(varCase.RecordTypeId).equals('Professional Services') ||
                        mRecordType.get(varCase.RecordTypeId).equals('Technical') || 
                        mRecordType.get(varCase.RecordTypeId).equals('AMG') ||
                        mRecordType.get(varCase.RecordTypeId).equals('Billing')||
                        mRecordType.get(varCase.RecordTypeId).equals('Emerging Products Engineering')||
                        (mRecordType.get(varCase.RecordTypeId).equals('Managed Security')                                    
                            && varCase.Policy_Domain__c != null)                        
                    )
                    {
                           varCase.Apply_Jarvis_Logic__c = true;
                    }
                    //Changes for Sorry Page Issue (Vamsee -ESESP-7043) - Parent Account Needs to populated for the cases not created in Community or Open API
                    System.debug('---Vamsee0---'+varCase.Origin);
                    if((varCase.Apply_Jarvis_Logic__c) && (mRecordType.get(varCase.RecordTypeId).equals('AMG') ||
                        mRecordType.get(varCase.RecordTypeId).equals('Billing') ||
                        varCase.ATT_RecordType__c == 'AMG' ||
                        varCase.ATT_RecordType__c == 'Billing') && varCase.Parent_Account__c == null && (varCase.Origin != 'Community Web' && varCase.Origin != 'Jarvis API'))
                    {
                        if(varCase.Created_By_Account__c != varCase.AccountId){
                            varCase.Parent_Account__c = varCase.Created_By_Account__c;
                        }
                        if(varCase.Indirect_Customer__c != null && varCase.Indirect_Customer__c != varCase.AccountId){
                            varCase.Parent_Account__c = varCase.AccountId;
                        }
                        
                    }
                    
                    
                    
                    
                    if(
                        (mRecordType.get(varCase.RecordTypeId).equals('AMG') ||
                        mRecordType.get(varCase.RecordTypeId).equals('Billing') ||
                        varCase.ATT_RecordType__c == 'AMG' ||
                        varCase.ATT_RecordType__c == 'Billing' ||
                        (
                            (mRecordType.get(varCase.RecordTypeId).equals('Professional Services') || 
                            mRecordType.get(varCase.RecordTypeId).equals('Emerging Products Engineering')||
                            mRecordType.get(varCase.RecordTypeId).equals('Technical') ||
                            varCase.ATT_RecordType__c == 'Professional Services' ||
                            varCase.ATT_RecordType__c == 'Technical')
                            && varCase.Case_Product__c == null
                        ))
                        &&
                        varCase.Created_By_Account__c == varCase.AccountId
                        &&
                        varCase.Indirect_Customer__c == null
                        &&
                        varCase.Parent_Account__c == null
                    )
                    {
                        varCase.Community_Sharing_Set_Account_Lookup__c = varCase.Created_By_Account__c;
                    }
                    //Users with Third Party Access (ESESP-7043) - Direct Case 
                    else if((varCase.Apply_Jarvis_Logic__c) && (mRecordType.get(varCase.RecordTypeId).equals('AMG') ||
                        mRecordType.get(varCase.RecordTypeId).equals('Billing') ||
                        varCase.ATT_RecordType__c == 'AMG' ||
                        varCase.ATT_RecordType__c == 'Billing') && varCase.Parent_Account__c == null && (varCase.Origin == 'Community Web' || varCase.Origin == 'Jarvis API'))
                    {
                        varCase.Community_Sharing_Set_Account_Lookup__c = varCase.AccountId;
                    }
                    else if(Trigger.isUpdate && varCase.Community_Sharing_Set_Account_Lookup__c != null)
                    {
                        varCase.Community_Sharing_Set_Account_Lookup__c = null;
                    }
                    
                }
                if(
                        Trigger.isUpdate && varCase.Apply_Jarvis_Logic__c && 
                        (
                            currentAccountId == null 
                            ||
                            (
                                currentAccountId != null && 
                                limitedBetaAccountIds != null && 
                                !limitedBetaAccountIds.contains(currentAccountId) 
                            )
                            ||
                            varCase.Do_Not_Show_in_Portal__c
                            ||
                            varCase.RecordTypeId == null
                            ||
                            (
                                Trigger.oldMap.get(varCase.Id).RecordTypeId != varCase.RecordTypeId &&                             
                                !SC_Jarvis_CoreSecurityController.caseRecordTypesJarvis.contains(mRecordType.get(varCase.RecordTypeId))
                            )
                            ||
                            (
                                (mRecordType.get(varCase.RecordTypeId).equals('Managed Security') ||
                                varCase.ATT_RecordType__c == 'Managed Security')
                                && varCase.Policy_Domain__c == null
                            )

                        ) && Test.isRunningTest() == false
                )
                {
                        varCase.Apply_Jarvis_Logic__c = false;
                        varCase.Community_Sharing_Set_Account_Lookup__c= null;                    
                }
            }
                    
                    
                if((Trigger.isInsert && varCase.Origin != 'Autogen' && varCase.Origin != 'SF.com') || (Trigger.isUpdate &&
                                        ((Trigger.oldMap.get(varCase.Id).Service__c != Trigger.newMap.get(varCase.Id).Service__c)
                                         ||(Trigger.oldMap.get(varCase.Id).AccountId != Trigger.newMap.get(varCase.Id).AccountId) )))
                {
                    if(mRecordType.get(varCase.RecordTypeId).equals('Professional Services') && !varCase.Validation_Override__c
                       && enableServVal.Enable_Service_Validation__c && (lunaPortalIntCust.ProfileId__c != UserInfo.getProfileId())
                      )
                    {
                        lstPSCases.add(varCase);
                        psCaseAccId.add(varCase.AccountId);
                    }
                }
                					
                /* Changes by Vandhana Krishnamurthy for JIRA ESESP-1942*/
                if(mRecordType.get(varCase.RecordTypeId).equals('Order Approval-Others') 
                   && String.isNotBlank(varCase.Sub_Type__c) 
                   && (varCase.Sub_Type__c == 'Edgesuite Transition Approval' || varCase.Sub_Type__c == 'Revenue Alignment')
                   && (Trigger.isInsert 
                       || (Trigger.isUpdate && varCase.Sub_Type__c != Trigger.oldMap.get(varCase.Id).Sub_Type__c))
                  )
                {
                    varCase.Case_Assignment_Using_Active_Rules__c = true;
                }
                
                /* Changes by Vandhana Krishnamurthy for JIRA ESESP-1942*/
                if((mRecordType.get(varCase.RecordTypeId).equals('Order Approval-Order Management') 
                    || mRecordType.get(varCase.RecordTypeId).equals('Order Approval-Deal Desk') 
                    || mRecordType.get(varCase.RecordTypeId).equals('Order Approval-Legal'))
                   && Trigger.isInsert && varCase.AKAM_System__c != 'OA DataLoad'
                  )
                {
                    varCase.Case_Assignment_Using_Active_Rules__c = true;
                }
                
                //Changes for Order Approval - restrict Record Type changes within and to/from Order Approval 
                if(Trigger.isUpdate
                   && Trigger.oldMap.get(varCase.Id).RecordTypeId != varCase.RecordTypeId 
                   && ((mRecordType.get(varCase.RecordTypeId).equals('Order Approval-Deal Desk') 
                       || mRecordType.get(varCase.RecordTypeId).equals('Order Approval-Legal')
                       || mRecordType.get(varCase.RecordTypeId).equals('Order Approval-Order Management')
                       || mRecordType.get(varCase.RecordTypeId).equals('Order Approval-Escalations')
                       || mRecordType.get(varCase.RecordTypeId).equals('Order Approval-Others')
                       || mRecordType.get(varCase.RecordTypeId).equals('Order Approval-Sales Manager')
                       )
                       ||
                       (mRecordType.get(Trigger.oldMap.get(varCase.Id).RecordTypeId).equals('Order Approval-Deal Desk') 
                       || mRecordType.get(Trigger.oldMap.get(varCase.Id).RecordTypeId).equals('Order Approval-Legal')
                       || mRecordType.get(Trigger.oldMap.get(varCase.Id).RecordTypeId).equals('Order Approval-Order Management')
                       || mRecordType.get(Trigger.oldMap.get(varCase.Id).RecordTypeId).equals('Order Approval-Escalations')
                       || mRecordType.get(Trigger.oldMap.get(varCase.Id).RecordTypeId).equals('Order Approval-Others')
                       || mRecordType.get(Trigger.oldMap.get(varCase.Id).RecordTypeId).equals('Order Approval-Sales Manager')
                      ))
                  )
                {
                    varCase.addError('We\'re watching you! You cannot change the Record Type for Order Approval Cases. 🙅🏻'); 
                }
                
                if(Trigger.isUpdate
                   && Trigger.oldMap.get(varCase.Id).OwnerId != varCase.OwnerId 
                   && String.valueOf(varCase.OwnerId).startsWith(Schema.SObjectType.User.getKeyPrefix())
                   && (
                       (mRecordType.get(Trigger.oldMap.get(varCase.Id).RecordTypeId).equals('Order Approval-Deal Desk') 
                       || mRecordType.get(Trigger.oldMap.get(varCase.Id).RecordTypeId).equals('Order Approval-Legal')
                       || mRecordType.get(Trigger.oldMap.get(varCase.Id).RecordTypeId).equals('Order Approval-Order Management')
                      ))
                  )
                {
                    oaCheckOwnerId.add(varCase.OwnerId);
                    oaCheckOwnerIdCase.add(varCase);
                }
                
                if(Trigger.isUpdate || Trigger.isInsert)
                {
                    if(mRecordType.get(varCase.RecordTypeId).equals('Order Approval-Deal Desk')
                       || mRecordType.get(varCase.RecordTypeId).equals('Order Approval-Escalations')
                       || mRecordType.get(varCase.RecordTypeId).equals('Order Approval-Legal')
                       || mRecordType.get(varCase.RecordTypeId).equals('Order Approval-Order Management')
                       || mRecordType.get(varCase.RecordTypeId).equals('Order Approval-Others')
                       || mRecordType.get(varCase.RecordTypeId).equals('Order Approval-Sales Manager'))
                    {  
                        if(Trigger.isInsert && varCase.Approver__c != null){
							caseApproverList.add(varCase);
                        }
                        if(Trigger.isUpdate && Trigger.oldMap.get(varCase.id).Approver__c != varCase.Approver__c){
                            caseApproverList.add(varCase);
                        }
                        
                        // changes by Vandhana for ESESP-45690
                        if((!varCase.Validation_Override__c && varCase.AKAM_System__c != 'MPCC') || varCase.AKAM_System__c == 'MPCC')
                        	lOACase.add(varCase);
                        
                        if(Trigger.isUpdate &&
                           ((varCase.Status != Trigger.oldMap.get(varCase.Id).Status && (varCase.Status == 'Closed-Approved'||varCase.Status == 'Closed-Auto Approved'||varCase.Status == 'Closed-Approval Not Needed'||varCase.Status == 'Closed'||varCase.Status == 'Closed-Insufficient Information'||varCase.Status == 'Closed-Quote Term Updated'||varCase.Status == 'Closed-Quote Approved'))
                           || varCase.AutoClose__c)
                          )
                        {
                            lOACloseCaseId.add(varCase.Id);   
                            lOACloseCaseOppId.add(varCase.Opportunity__c);
                        }
                        
                        if(Trigger.isInsert)
                        {
                            lOACaseOppOwner.add(varCase);
                            lOACaseOppId.add(varCase.Opportunity__c);
                            if(mRecordType.get(varCase.RecordTypeId).equals('Order Approval-Escalations') && !varCase.Validation_Override__c){
                                parentCaseIdList.add(varCase.parentId);
                            }
                        }
                        //ESESP-2796 added by-Bhavesh
                        //limit hit for the use of reference field in validation rule, hence adding validation in code
                        if( mRecordType.get(varCase.RecordTypeId).equals('Order Approval-Order Management') && !varCase.Validation_Override__c  && varCase.Customer_Segment_Order_Treatment__c == NULL 
                            && Trigger.isUpdate && Trigger.oldMap.get(varCase.Id).Status != varCase.Status 
                            && varCase.Opportunity__c != null  && (varCase.Status == 'Closed-Approved' || varCase.Status == 'Closed-Auto Approved' || varCase.Status == 'Closed-Approval Not Needed'||varCase.Status == 'Closed-Insufficient Information'||varCase.Status == 'Closed-Quote Term Updated'||varCase.Status == 'Closed-Quote Approved')){
                            oppIdList.add(varCase.Opportunity__c);
                            caseListOA.add(varCase);
                        }
                        //Account gst
                        if(Trigger.isInsert
                           && mRecordType.get(varCase.RecordTypeId).equals('Order Approval-Order Management')
                           && varCase.Opportunity__c != NULL
                           && varCase.AccountId != NULL
                           && !varCase.Validation_Override__c 
                           && !varCase.AutoClose__c )
                        {
                            oppIdListGST.add(varCase.Opportunity__c);
                            caseListOAForGSTcheck.add(varCase);
                            accountIdsToCheckGST.add(varCase.AccountId);
                        }
                        
                        //Dont allow others to edit the record
                        if(Trigger.isUpdate)
                        	CaseTriggerClass_OA.validateCaseEdit(Trigger.oldMap.get(varCase.Id),Trigger.newMap.get(varCase.Id),mRecordType.get(varCase.RecordTypeId),mErrorMssgRec);
                        //SFDC-8991 OA Auto renewal Change                       
                        if(Trigger.isInsert && varCase.Opportunity__c != null  && varCase.Order_Approval__c != null && (varCase.Order_Type__c == null || (varCase.Order_Type__c != null && varCase.Order_Type__c != 'Auto Renewal')))
                        {
                            system.debug('HC Inside If Oppty' +varCase.Opportunity__c +' Order Type '+varCase.Order_Type__c +' Order Approval '+varCase.Order_Approval__c);
                            caseOpptyOAAutoRenewal.add(varCase.Opportunity__c);
                        }
                    }
                    
                }
                

                /* Changes by Vandhana Krishnamurthy for JIRA ESESP-595
                 * insert records into Case Tracker History object
                 * update Case Severity Last Update & Case Owner Last Update values on change of Severity/Owner
                */

                /*  Changes by Vandhana Krishnamurthy for JIRA ESESP-595
                Populate Case Severity Last Update & Case Owner Last Update values for all PS cases
                */

                if( mRecordType.get(varCase.RecordTypeId).equals('Professional Services'))
                {
                    for(String caseFieldAPI : histTrackMDTMap.keySet())
                    {
                        if(Trigger.isInsert || (Trigger.isUpdate && Trigger.oldMap.get(varCase.Id).get(caseFieldAPI) != Trigger.newMap.get(varCase.Id).get(caseFieldAPI)) )
                        {
                            varCase.put(histTrackMDTMap.get(caseFieldAPI).Last_Update_field_on_Case__c, System.now());
                        }
                    }
                    
                    // changes by Vandhana - S2ET
                    // ESESP-5981 : Sujay
                    // Add 24 PS queue check here - this is to ensure Tasks are closed before closing the case
                    if(Trigger.isUpdate && (mapSCUtilMDTVal.get('S2ET_Queue_Id').containsIgnoreCase(varCase.OwnerId) 
                                                || mapSCUtilMDTVal.get('PS24_Queue_Id').containsIgnoreCase(varCase.OwnerId))
                       && varCase.IsClosed == TRUE 
                       && varCase.Status == 'Closed' 
                       && !varCase.Validation_Override__c
                       && varCase.Status != Trigger.oldMap.get(varCase.Id).Status
                      )
                    {
                        s2etCaseClose.put(varCase.Id,varCase);
                    }
                    
                    // changes by Vandhana for S2ET
                    if(!varCase.IsClosed
                       //ESESP-5678 : include 24 PS Cases
                       && (mapSCUtilMDTVal.get('S2ET_Queue_Id').containsIgnoreCase(varCase.OwnerId) || mapSCUtilMDTVal.get('PS24_Queue_Id').containsIgnoreCase(varCase.OwnerId))
                       && (Trigger.isInsert || (Trigger.IsUpdate 
                                                && Trigger.oldMap.get(varCase.Id).Case_Transition_Date__c == NULL
                                                && (varCase.RecordTypeId != Trigger.oldMap.get(varCase.Id).RecordTypeId 
                                                    || varCase.OwnerId != Trigger.oldMap.get(varCase.Id).OwnerId))
                          )
                      )
                    {
                        varCase.Case_Transition_Date__c = System.now();
                    }
                        
                    if(!varCase.IsClosed
                       //Sujay - ESESP-5981 : Adding 24PS check for checking the No comm check
                       && (mapSCUtilMDTVal.get('S2ET_Queue_Id').containsIgnoreCase(varCase.OwnerId) 
                            || mapSCUtilMDTVal.get('PS24_Queue_Id').containsIgnoreCase(varCase.OwnerId) ) //&& !System.isFuture()
                       && Trigger.IsUpdate &&
                           (
                               (varCase.Last_Case_Update__c != NULL 
                                && Trigger.oldMap.get(varCase.Id).Last_Case_Update__c != varCase.Last_Case_Update__c 
                                && (varCase.Last_Customer_Activity_Date__c == NULL || varCase.Last_Customer_Activity_Date__c < varCase.Last_Case_Update__c))
                               || 
                               (varCase.Last_Customer_Activity_Date__c != NULL 
                                && Trigger.oldMap.get(varCase.Id).Last_Customer_Activity_Date__c != varCase.Last_Customer_Activity_Date__c 
                                && (varCase.Last_Case_Update__c == NULL || varCase.Last_Customer_Activity_Date__c > varCase.Last_Case_Update__c))
                           )
                      )
                    {
                        varCase.S2ET_No_Comm_Check__c = false;
                        System.debug('TRIGGER BEFORE');
                    }

                    // changes by Vikas for Provisioning : ESESP-3663	
                    if(Trigger.isUpdate && (mapSCUtilMDTVal.get('Plx_Queue_Id').containsIgnoreCase(varCase.OwnerId) || 	
                          (mapSCUtilMDTVal.get('Plx_Service_Values').split(',').contains(varCase.Service__c)
                          && mapSCUtilMDTVal.get('Plx_Products').split(',').contains(varCase.Case_Prod_Name__c))) 	
                       && varCase.IsClosed == TRUE 	
                       && varCase.Status == 'Closed' && !varCase.Validation_Override__c	
                       && varCase.Status != Trigger.oldMap.get(varCase.Id).Status	
                      )	
                    {	
                        plxCaseClose.put(varCase.Id,varCase);	
                    }	
                    	
                    // changes by Vikas for Provisioning : ESESP-3663	
                    if(!varCase.IsClosed	
                        &&(mapSCUtilMDTVal.get('Plx_Queue_Id').containsIgnoreCase(varCase.OwnerId) || 	
                        (mapSCUtilMDTVal.get('Plx_Service_Values').split(',').contains(varCase.Service__c) 
                        && mapSCUtilMDTVal.get('Plx_Products').split(',').contains(varCase.Case_Prod_Name__c)))	
                        && (Trigger.isInsert || (Trigger.IsUpdate 	
                                                && (varCase.RecordTypeId != Trigger.oldMap.get(varCase.Id).RecordTypeId 	
                                                    || varCase.OwnerId != Trigger.oldMap.get(varCase.Id).OwnerId	
                                                    || varCase.Service__c != Trigger.oldMap.get(varCase.Id).Service__c	
                                                    || varCase.Case_Product__c != Trigger.oldMap.get(varCase.Id).Case_Product__c))	
                          )	
                      )	
                    {	
                        varCase.Case_Transition_Date__c = System.now();	
                    }
                }

                //Commented by Vikas for JIRA ESESP-4647	
                /*	
                // Changes by Vandhana Krishnamurthy for JIRA ESESP-820	
                if(mRecordType.get(varCase.RecordTypeId).equals('Managed Security')	
                   && String.isNotBlank(varCase.Policy_Domain__c)	
                   && String.isNotBlank(varCase.AccountId) && String.isNotBlank(varCase.Case_Product__c))	
                {	
                    lstMSCases.add(varCase);	
                    polDomId.add(varCase.Policy_Domain__c);	
                }	
				*/	
                	
                // Changes by Vikas for JIRA ESESP-4647	
                if(mRecordType.get(varCase.RecordTypeId).equals('Managed Security') 	
                   && 	
                   (Trigger.isInsert	
                    && String.isNotBlank(varCase.Policy_Domain__c)	
                    && String.isNotBlank(varCase.AccountId) && String.isNotBlank(varCase.Case_Product__c)) 	
                   || 	
                   (Trigger.isUpdate && 	
                    ((Trigger.oldMap.get(varCase.Id).Policy_Domain__c != varCase.Policy_Domain__c && String.isNotBlank(varCase.Policy_Domain__c))	
                     || (Trigger.oldMap.get(varCase.Id).AccountId != varCase.AccountId && String.isNotBlank(varCase.AccountId))	
                     || (Trigger.oldMap.get(varCase.Id).Case_Product__c != varCase.Case_Product__c && String.isNotBlank(varCase.Case_Product__c)))))
                {
                    lstMSCases.add(varCase);
                    polDomId.add(varCase.Policy_Domain__c);
                }

                /*  Changes by Vandhana Krishnamurthy
                AMG cases should get routed automatically if not created by AMG agents
                */

                if(mRecordType.get(varCase.RecordTypeId).equals('AMG'))
                {
                    if(Trigger.isInsert || (Trigger.isUpdate
                                            && Trigger.oldMap.get(varCase.Id).OwnerId != varCase.OwnerId
                                            && CheckRecursion.runOnce() )
                      || (Trigger.isUpdate && Trigger.oldMap.get(varCase.Id).RecordTypeId != varCase.RecordTypeId 
                          && CheckRecursion.runOnce()
                          && !varCase.Case_Assignment_Using_Active_Rules__c
                         )
                      )
                    {
                        lstAMGCases.add(varCase);
                        lstAMGCaseOwnerIds.add(varCase.OwnerId);
                    }

                    // changes by Vandhana for ESESP-692 (Force close activities before closing ECOB/NCOB AMG cases)
                    if(Trigger.isUpdate && Trigger.isBefore
                       && Trigger.oldMap.get(varCase.Id).Status != varCase.Status
                       && statusVals.contains(varCase.Status)
                       && varCase.Origin == 'Autogen'
                       && (varCase.Autogen_UseCase__c == 'COB' || varCase.Autogen_UseCase__c == 'ECOB'))
                    {
                        mpAMGCOBCases.put(varCase.Id,varCase);
                    }
                    
                    if((Trigger.isInsert || (Trigger.isUpdate && varCase.Service__c != Trigger.oldMap.get(varCase.Id).Service__c))
                       && varCase.Request_Type__c == 'SiteShield Map Degradation' && varCase.Service__c == 'Escalation Management'
                       && !varCase.IsClosed)
                    {
                        varCase.Priority = 'High';
                    }
                }
                //Added by Bhavesh,ESESP-3590, RCA request changes
                if(mRecordType.get(varCase.RecordTypeId).equals('RCA Request') ){
                    //check: only internal users can be the IRAPT approver, Legal Reviewer, and Exec APprover
                    if( (Trigger.isInsert && varCase.IRAPT_Approver__c != NULL) || (Trigger.isUpdate && varCase.IRAPT_Approver__c != NULL && varCase.IRAPT_Approver__c != Trigger.oldMap.get(varCase.Id).IRAPT_Approver__c)){
                        rcaUsrIds.add( varCase.IRAPT_Approver__c );
                    }
                    if( (Trigger.isInsert && varCase.Legal_Reviewer__c != NULL) || (Trigger.isUpdate && varCase.Legal_Reviewer__c != NULL && varCase.Legal_Reviewer__c != Trigger.oldMap.get(varCase.Id).Legal_Reviewer__c)){
                        rcaUsrIds.add( varCase.Legal_Reviewer__c );
                    }
                    if( (Trigger.isInsert && varCase.Exec_Approver__c != NULL) || (Trigger.isUpdate && varCase.Exec_Approver__c != NULL && varCase.Exec_Approver__c != Trigger.oldMap.get(varCase.Id).Exec_Approver__c)){
                        rcaUsrIds.add( varCase.Exec_Approver__c );
                    }
                    if (Trigger.isInsert || (Trigger.isUpdate && varCase.RecordTypeId != Trigger.oldMap.get(varCase.Id).RecordTypeId)) {
                        varCase.Status = 'Unassigned';
                        varCase.Status_Path_RCA__c = varCase.Status;
                        if(Trigger.isInsert){
                            varCase.Case_Assignment_Using_Active_Rules__c = True;
                            if( !varCase.Validation_Override__c )
                                rcaCreatedUpdatedByUserList.add(varCase.CreatedById);
                        }
                        //ParentCase should be attached to RCA case.
                        if (varCase.ParentId == NULL){
                            varCase.addError('Parent case should be selected for RCA Request.');
                        }
                        else {
                            Map<String,EntitlementID__c> entitlementIds = EntitlementID__c.getAll();
                            varCase.EntitlementId = entitlementIds.get('RCA').EntitlementID__c;
                            varCase.RCA_Creator__c  = Userinfo.getUserEmail();
                            if(varCase.Subject == NULL) 
                            	varCase.Subject  = 'RCA Request';
                            //check if parent is case amg or technical, else throw error.
                            rcaRequestCaseList.add (varCase.ParentId);
                            //To check  rca owner is an IRAPT user.
                            rcaStatusUpdatedByUserSet.add (varCase.RCA_Owner__c);
                            varCase.RCA_Request_Submit_Datetime_UTC__c = ''+Datetime.now().formatGMT('dd MMM yyyy, HH:MM')+' UTC';
                        }
                            
                    } else if (Trigger.isUpdate) {
                    	if(varCase.ParentId != Trigger.oldMap.get(varCase.Id).ParentId){
                            rcaRequestCaseList.add (varCase.ParentId);
                        }
                        if( varCase.Status_Path_RCA__c != Trigger.oldMap.get(varCase.Id).Status_Path_RCA__c ){
                            varCase.Status = varCase.Status_Path_RCA__c;
                        }
                        if( varCase.Status != Trigger.oldMap.get(varCase.Id).Status ){
                            varCase.Status_Path_RCA__c = varCase.Status;
                        }
                        if( !varCase.Validation_Override__c )
                            rcaCreatedUpdatedByUserList.add(varCase.LastModifiedById);
                        if( varCase.Status != Trigger.oldMap.get(varCase.Id).Status ){
                            if( varCase.Status == 'RCA Delivered' ){
                                varCase.Delivered_to_Requestor_on__c = Datetime.now();
                            	varCase.Time_to_Complete_Request__c = SC_CaseTriggerHelperClass3.getWorkingDays( varCase.CreatedDate.Date(), Date.today());
                                caseIdsToCheckPeerValue.add( varCase.Id );
                            }
                            if( varCase.Date_RCA_Delivered__c == NULL && (varCase.Status == 'RCA Delivered' || varCase.Status == 'Rejected' || varCase.Status == 'Closed')){
                                varCase.Date_RCA_Delivered__c   = Datetime.now();
                            }
                            if( varCase.Status == 'Closed' || varCase.Status == 'KB Article Created'){
                                closedCaseIds.add(varCase.Id);
                            }
                            //Related Incident should have an External Dependency type Jira with Category as RCA follow-up.  
                            if(varCase.Status == 'Pending Follow-up Tracking'){
                                if( varCase.Service_Incident__c == NULL){
                                    varCase.addError('Error: Related Incident should have an External Dependency type Jira with Category as RCA follow-up.');
                                }
                                pendingCaseIds.add(varCase.Id);
                                servIncidentIds.add(varCase.Service_Incident__c);
                            }
                        }
                        if( Trigger.oldMap.get(varCase.Id).Status == 'Closed' && varCase.Validation_Override__c == False && SC_CaseTriggerHelperClass3.rcaRecursiveCheckEdit == False ){
                                varCase.addError('You cannot edit a closed Case.');
                        }
                        //to stop recursive call RCA.
                        SC_CaseTriggerHelperClass3.rcaRecursiveCheckEdit = True;
                        
                        if( (varCase.OwnerId != Trigger.oldMap.get(varCase.Id).OwnerId && string.valueOf(varCase.OwnerId).startsWith('005'))
                                || (varCase.RCA_Owner__c != Trigger.oldMap.get(varCase.Id).RCA_Owner__c )
                                || (varCase.Status != Trigger.oldMap.get(varCase.Id).Status && varCase.Status == 'Rejected') ){
                            rcaStatusUpdatedByUserSet.add (varCase.OwnerId);
                            rcaStatusUpdatedByUserSet.add (varCase.RCA_Owner__c);
                            rcaStatusUpdatedByUserSet.add (varCase.LastModifiedById);
                        } 
                        if (varCase.Status != Trigger.oldMap.get(varCase.Id).Status && varCase.Status == 'Rejected' && varCase.SC_EQ_Notes__c == NULL)
                            varCase.addError ('Please enter details in Notes to Reject the RCA Request.');
                        else if (varCase.Status != Trigger.oldMap.get(varCase.Id).Status && varCase.Status == 'Unassigned' && string.valueOf(varCase.OwnerId).startsWith('005')) {
                            varCase.Case_Assignment_Using_Active_Rules__c = True;
                        } else if (varCase.Status != Trigger.oldMap.get(varCase.Id).Status && varCase.Status != 'Unassigned'
                                && varCase.Status != 'Rejected' && string.valueOf(varCase.OwnerId).startsWith('00G')) {
                            varCase.OwnerId = Userinfo.getUserId();
                            rcaStatusUpdatedByUserSet.add (varCase.OwnerId);
                        }
                        
                        if(varCase.IRAPT_Approver__c != Trigger.oldMap.get(varCase.Id).IRAPT_Approver__c && varCase.IRAPT_Approver__c != NULL){
                            rcaIraptApproverUserList.add(varCase.IRAPT_Approver__c);
                        }
                        //pause the milesotne if rca status is rejected
                        if(varCase.Status != Trigger.oldMap.get(varCase.Id).Status && varCase.Status == 'Rejected'){
                            varCase.isStopped = true;
                        }
                        //unpause the milestone if rca status is moved back to any other status from rejected.
                        if(varCase.Status != Trigger.oldMap.get(varCase.Id).Status && varCase.isStopped == True && varCase.Status != 'Rejected'){
                            varCase.isStopped = false;
                        }
                        
                       
                        
                    }
                    
                }
            }
            //Added by Bhavesh,ESESP-3590, RCA request changes
            if(rcaCreatedUpdatedByUserList.size()>0 && SC_CaseTriggerHelperClass3.rcaRecursiveNonIraptCheck == False ){
                SC_CaseTriggerHelperClass3.rcaNonIraptValidationCheck (rcaCreatedUpdatedByUserList, Trigger.New, Trigger.oldMap);
            } 
            if(rcaRequestCaseList.size() > 0 && SC_CaseTriggerHelperClass3.rcaErrorInCase == False) {
                SC_CaseTriggerHelperClass3.rcaCreationValidation (Trigger.New, rcaRequestCaseList, mRecordType);
            }
            if(rcaStatusUpdatedByUserSet.size() > 0 && SC_CaseTriggerHelperClass3.rcaErrorInCase == False) {
                SC_CaseTriggerHelperClass3.checkRCA_OwnerValidation (Trigger.New, Trigger.OldMap, rcaStatusUpdatedByUserSet, mRecordType);
            }
            
            if(closedCaseIds.size()>0 && SC_CaseTriggerHelperClass3.rcaErrorInCase == False){
                SC_CaseTriggerHelperClass3.rcaCaseClosingCondition (closedCaseIds, Trigger.New);
            }
            if(pendingCaseIds.size()>0 && SC_CaseTriggerHelperClass3.rcaErrorInCase == False){
                SC_CaseTriggerHelperClass3.rcaCasePendingFollowupCondition (pendingCaseIds, servIncidentIds, Trigger.NewMap);
            }
            if(rcaUsrIds.size()>0 && SC_CaseTriggerHelperClass3.rcaErrorInCase == False){
                SC_CaseTriggerHelperClass3.checkIsUserInternal (rcaUsrIds, Trigger.New);
            }
            if(caseIdsToCheckPeerValue.size()>0 && SC_CaseTriggerHelperClass3.rcaErrorInCase == False){
                SC_CaseTriggerHelperClass3.checkPeerReviewValidation (caseIdsToCheckPeerValue, Trigger.NewMap);
            }
            if(rcaIraptApproverUserList.size()>0 && SC_CaseTriggerHelperClass3.rcaErrorInCase == False){
                SC_CaseTriggerHelperClass3.checkIraptApproverValidation (rcaIraptApproverUserList, Trigger.New);
            }
            
            
            if((caseListOA.size() > 0 || caseListOAForGSTcheck.size() > 0) && CaseTriggerClass_OA.oaRecursiveCustSegUpdate == False){ 
                CaseTriggerClass_OA.checkCustSegTreatmentFieldNull( oppIdList, mErrorMssgRec, caseListOA, accountIdsToCheckGST, caseListOAForGSTcheck, oppIdListGST );
            }
            CaseTriggerClass_OA.oaRecursiveCustSegUpdate = True; 
            system.debug('lOACase : '+lOACase);
            if(!lOACase.isEmpty())
            {
                CaseTriggerClass_OA.validateOACase(lOACase,mRecordType,Trigger.isInsert,Trigger.oldMap,Trigger.newMap,mErrorMssgRec);
            }
            
            if(!oaCheckOwnerId.isEmpty() && !oaCheckOwnerIdCase.isEmpty())
            {
                CaseTriggerClass_OA.validateOACaseOwnerChange(oaCheckOwnerId,oaCheckOwnerIdCase,mRecordType,mErrorMssgRec);
            }
            
            if(!lOACloseCaseId.isEmpty() && CaseTriggerClass_OA.recursiveCheckCloseCase == False)
            {
                CaseTriggerClass_OA.validateCloseCase(lOACloseCaseId,mErrorMssgRec,Trigger.newMap,lOACloseCaseOppId,mRecordType,false);
            }
            CaseTriggerClass_OA.recursiveCheckCloseCase = True;
            
            if(!lOACaseOppOwner.isEmpty() && !lOACaseOppId.isEmpty())
            {
                CaseTriggerClass_OA.populateOppOwnerOACase(lOACaseOppOwner,lOACaseOppId,mErrorMssgRec);
            }
            if(!parentCaseIdList.isEmpty())
            {
                CaseTriggerClass_OA.validateEscalationCase(parentCaseIdList,Trigger.new,mErrorMssgRec);
            }
            if(!caseApproverList.isEmpty())
            {
                CaseTriggerClass_OA.populateOAApproverChange(caseApproverList,mRecordType,Trigger.oldMap,mErrorMssgRec);
            }
            
            if(!lstPSCases.isEmpty())
            {
                CaseTriggerClass.validateServiceEntitlement(lstPSCases,psCaseAccId);
            }

            // Changes by Vandhana Krishnamurthy for JIRA ESESP-820
            if(!lstMSCases.isEmpty())
            {
                CaseTriggerClass.managedSecPolDomCheck(lstMSCases,polDomId);
            }

            // changes by Vandhana for ESESP-791
            // changes by Vandhana for ESESP-2634
            if(!lstAMGCases.isEmpty())
            {
                CaseTriggerClass.routeAMGCases(lstAMGCases,lstAMGCaseOwnerIds,Trigger.isInsert);
            }
            

            // changes by Vandhana for ESESP-692
            if(!mpAMGCOBCases.isEmpty())
            {
                CaseTriggerClass.checkActCOBCases(mpAMGCOBCases);
            }
            
            // changes by Vandhana - S2ET
            if(!s2etCaseClose.isEmpty())
            {
                SC_CaseTriggerHelperClass2.checkTaskCloseS2ETCase(s2etCaseClose);
            }
            // changes by Vikas - Provisioning : ESESP-3663
            if(!plxCaseClose.isEmpty())
            {
                SC_CaseTriggerHelperClass2.checkTaskCloseS2ETCase(plxCaseClose);
            }
            //SFDC-8991 OA Auto renewal Change
            if(caseOpptyOAAutoRenewal.size() > 0)
            {
                system.debug('Inside Method call '+caseOpptyOAAutoRenewal);
                CaseTriggerClass_OA.caseValidationOnAutoRenewalOppty(caseOpptyOAAutoRenewal,Trigger.new,mErrorMssgRec);
            }
        }
    }


    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        //Set Associated email if momentum record type
        /*if(Trigger.isInsert)
        {
            List<Case> CaseupdateList = new List<Case>();
            for(Case c:Trigger.new)
            {
                //check if record type is momentum and email to case is false
                if((c.RecordTypeId==CustomSettingsMomentum.CaseRecord__c || c.RecordTypeId==CustomSettingsProdMgmt.CaseRecord__c) && c.Email_to_case__c==False && c.Associated_Email__c==null)
                    CaseupdateList.add(c);
            }

            CaseTriggerClass.updateAssociatedEmail(CaseupdateList);
        }*/

        // IR Case Manual Approval update.
        //CR:3412081
        List<Id> ownerIdList = new List<Id>();
        String irCaseDefaultRecordTypeId = GSMUtilClass.GetCustomSettingValue('IR_CaseDefaultRecordTypeId');

        for (Case c: Trigger.new)
        {
            if (irCaseDefaultRecordTypeId.containsIgnoreCase(c.RecordTypeId))
            {
                if(c.IR_Manual_Invoice_Approval__c && (Trigger.isInsert || (Trigger.isUpdate && c.IR_Manual_Invoice_Approval__c!=Trigger.oldMap.get(c.Id).IR_Manual_Invoice_Approval__c)))
                {
                    c.IR_Manual_Invoice_Approved_by__c = Userinfo.getUserId();
                    //c.IR_Manual_Invoice_Approved_Date__c = Date.today();
                    c.IRC_Manual_Invoice_Approved_Date__c = System.now();
                }
                //CR:3412081
                ownerIdList.add(c.OwnerId);
            }
        }

        //ownerIdList.size Check added by Vamsee - ESESP-1530
        if(ownerIdList.size() > 0)
        {
            //CR:3412081
            Map<Id, Group> grPMap = new Map<Id, Group>([select Id,Name from Group where id in :ownerIdList]);

            for (Case c: Trigger.new)
            {
                if (irCaseDefaultRecordTypeId.containsIgnoreCase(c.RecordTypeId))
                {
                    /*
                    CR#         :3280651
                    Description : IR Case update the Resolution Owner
                    */
                    System.debug('Case Owner Id::'+c.OwnerId);
                    //List<Group> mapUser = [select id,Name from Group where id = :c.OwnerId ];
                    //System.debug(mapUser);
                    //if(mapUser.size() > 0 && mapUser[0].name.equalsIgnoreCase('FIN IR International Queue')){
                    //        c.IRCA_Resolution_Owner__c = 'CMG-Reviewer';
                    //}

                    if(grPMap.size() > 0 && grPMap.get(c.OwnerId)!=null && grPMap.get(c.OwnerId).Name.equalsIgnoreCase('FIN IR International Queue')){
                        c.IRCA_Resolution_Owner__c = 'CMG-Reviewer';
                    }
                }
            }
        }

        // IR Case Set Approval Flag CR 2965556
        for (Case cs: Trigger.New)
        {
            if (irCaseDefaultRecordTypeId.containsIgnoreCase(cs.RecordTypeId))
            {
                if(Trigger.isUpdate && cs.Status.containsIgnoreCase('Approved') && !Trigger.oldmap.get(cs.Id).Status.containsIgnoreCase('Approved'))
                {
                    cs.Approved_On__c = System.now();
                }
            }
        }
    }


  //Added by Kunal Sharma: Adding the list of SC cases instead of Trigger.New
  //Added by Vamsee : Recursion Check - ESESP-1514
        if(Trigger.isUnDelete && scCases.size()>0)
        {
            if(CaseTriggerClass.avoidRecursionBusinessHours)
            {
                CaseTriggerClass.avoidRecursionBusinessHours = false;
                CaseTriggerClass.updateBusinessHours(scCases, mRecordType, true);
            }
        }

    if(Trigger.isUpdate)
    {
        if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
        {
            List<Case> recentUpdatedCases = new List<Case>();
            //Added by Kunal: Adding the list of SC cases instead of Trigger.New
            for(Case c :scCases)
            {
                if(c.CreatedById != c.OwnerId)
                {
                    recentUpdatedCases.add(c);
                }
            }
            //Kunal: Added size check for list to stop unwanted calling of class method.
            if(recentUpdatedCases.size()>0)
            {
                CaseTriggerClass.setRecentUpdateTrue(recentUpdatedCases, Trigger.oldMap);
            }

            if(Trigger.isBefore)
            {
                Id amgRectypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId();
                for(Case varCase: scCases)
                {
                    if(mRecordType.get(varCase.RecordTypeId).equals('Emerging Products Engineering') &&
                       varCase.R_D_Escalation__c && varCase.EscalationDateEPE__c == Null)
                    {
                        varCase.EscalationDateEPE__c = DateTime.now();
                    }
                    //AMG checking case reopen condition ESESP-3404
                    if(varCase.RecordTypeId == amgRectypeId && Trigger.oldMap.get(varCase.Id).Status != varCase.Status && 
                       Trigger.oldMap.get(varCase.Id).Status == 'Closed' && varCase.Validation_Override__c == False 
                       && varCase.AKAM_Closed_Date__c != null){
                           SC_CaseTriggerHelperClass3.checkAMGCaseReopenCondition(varCase,Trigger.newMap);
                    }
                }
                //ESESP-758 AMG SLA improvements - populate AkaTech to AMG transition fields
                
                List<Case> lAmgCases = SC_Utility.filterSObjList(Trigger.new, new Map<String, Object> {'RecordTypeId' => amgRectypeId});

                CaseTriggerClass.caseTransitionToAMG(lAmgCases, Trigger.oldMap, mRecordType);


                //ESESP-758 AMG SLA improvements - reject AMG customer case closures which have open milestones
                //Changes by Jay, added validation override check and status change check
//                List<Case> closedAmgCases = SC_Utility.filterSObjList(Trigger.new,  new Map<String, Object> {'RecordTypeId' => amgRectypeId, 'Status' => 'Closed', 'Do_Not_Show_In_Portal_Picklist__c' => 'Customer'});
                List<Case> closedAmgCases = new List<Case>();
                Map<Id,Case> oldMap = Trigger.oldMap;
                for(Case c : Trigger.new){
                    if(!c.Validation_Override__c && c.RecordTypeId == amgRectypeId && c.Do_Not_Show_In_Portal_Picklist__c == 'Customer' && c.Status == 'Closed' && oldMap.get(c.Id).Status != c.Status){
                        closedAmgCases.add(c);
                    }
                }
                List<String> amgMs = new List<String> {'Initial Response', 'AMG Post Transition Initial Response'};
                    CaseTriggerClass.rejectCasesWithOpenMs(closedAmgCases, amgMs);
            }

        }
        //Added checks to reduce the number of SOQL
        //Added by Vamsee : Recursion Check - ESESP-1514
        if(CaseTriggerClass.avoidRecursionBusinessHours){
            CaseTriggerClass.avoidRecursionBusinessHours = false;
            if(scCases.size()>0)
            {
                CaseTriggerClass.updateBusinessHours(scCases, mRecordType, false);
            }
        }
    }

    // Legacy Type field Update based on Legacy Type Products
    // JIRA : ESESP-574
    // Added By : Aditya- 19th June,2017
    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        Id technicalRTId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        List<Case> caseListForLegacyTypeUpdate = new List<Case>();
        List<Case> caseListWithNoProduct = new List<Case>();
        if(Trigger.isBefore && Trigger.isUpdate ){
            for(integer i=0;i<Trigger.New.Size();i++){
                if(Trigger.New[i].RecordTypeId == technicalRTId && (Trigger.New[i].Case_Product__c != Null && Trigger.New[i].Case_Product__c != Trigger.Old[i].Case_Product__c))
                {
                    caseListForLegacyTypeUpdate.add(Trigger.New[i]);
                }
                else if(Trigger.New[i].RecordTypeId == technicalRTId && Trigger.New[i].Case_Product__c != Trigger.Old[i].Case_Product__c && Trigger.New[i].Case_Product__c == Null)
                {
                    caseListWithNoProduct.add(Trigger.New[i]);
                }
            }
        }

        if(Trigger.isBefore && Trigger.isInsert )
        {
            for(integer i=0;i<Trigger.New.Size();i++){
                if(Trigger.New[i].RecordTypeId == technicalRTId && Trigger.New[i].Case_Product__c != Null){
                    caseListForLegacyTypeUpdate.add(Trigger.New[i]);
                }
            }
        }

        if(!caseListForLegacyTypeUpdate.isEmpty())
            CaseTriggerClass.updateLegacyType(caseListForLegacyTypeUpdate,true);
        if(!caseListWithNoProduct.isEmpty())
            CaseTriggerClass.updateLegacyType(caseListWithNoProduct,false);
    }


    // Trigger to update the case Entitlement
    // Related task:T-151317
    //Kunal: Added Record Type Checks.
    //Akhila : Added condition to bypass support level based entitlement logic for Auto Gen cases
    if(trigger.isBefore && scCases.size()>0 &&  (trigger.isUpdate || trigger.isInsert)){
        List<Case> updateEntitlementList = new List<Case>();
        //Added by Vamsee : Recursion Check - ESESP-1514
        if(CaseTriggerClass.avoidRecursionUpdateEntitlement)
        {
            CaseTriggerClass.avoidRecursionUpdateEntitlement = false;
            
            for(Case c : Trigger.new)
            {
                if((mRecordType.get(c.RecordTypeId).equals('Technical') && c.Sub_Type__c != 'Security Event' && c.Sub_Type__c != 'SSL Support')  
                   ||(mRecordType.get(c.RecordTypeId).equals('AMG') && !(c.Service__c == 'Accounts Audits' && c.Request_Type__c == 'Customer Onboarding'
                                                                         && c.Work_Type__c == 'Proactive' && c.Severity__c == '3' && c.Do_Not_Show_in_Portal__c))
                   || mRecordType.get(c.RecordTypeId).equals('Billing') 
                   //|| mRecordType.get(c.RecordTypeId).equals('Carrier Products')
                   || mRecordType.get(c.RecordTypeId).equals('Community Response')
                   || mRecordType.get(c.RecordTypeId).equals('CMG')

                  )
                {
                    updateEntitlementList.add(c);
                }
            }
        }

        if(updateEntitlementList.size()>0)
                SC_CaseTriggerHelperClass.updateCaseEntitlement(updateEntitlementList, mRecordType);

        //Moved updatecaseentitlement method from casetriggerclass
        SC_CaseTriggerHelperClass.updateCaseEntitlement_PartB(trigger.isInsert, scCases, trigger.isInsert ? null : trigger.oldMap, mRecordType);

        if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
        {
            //Call handler method to update the Case.ContactPhone
            CaseTriggerClass.updateCaseContactPhone(scCases, Trigger.isInsert ? null : Trigger.oldMap, Trigger.isInsert);
        }
    }
    
    //Start of NQLB: Milestone Completion on Case Status change
    Map<Id,Case> mapNQLBCase = new Map<Id,case>();
    Id communityNQLBRTId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Community Response').getRecordTypeId();
    if(trigger.isBefore && trigger.isUpdate && scCases.size()>0){
        for(Case eachCase : Trigger.new){
            if(eachCase.RecordTypeId == communityNQLBRTId && (eachCase.Status == 'Work in Progress' || eachCase.Has_Best_Answer__c == true))
                mapNQLBCase.put(eachCase.Id,eachCase);
        }
    }

    if(!mapNQLBCase.isEmpty()){
        // List to store all Milestones for Update
        List<CaseMilestone> caseMilestoneUpdateWIP = new List<CaseMilestone>();
        List<CaseMilestone> caseMilestoneUpdateClosed = new List<CaseMilestone>();
        List<CaseMilestone> caseNQLBMilestone = new List<CaseMilestone>();
        for(CaseMilestone csMilestone: [Select MilestoneType.Name, Id, CaseId, CompletionDate From CaseMilestone
                                        where CaseId in:mapNQLBCase.keyset() and
                                        IsCompleted = false and
                                        MilestoneType.Name IN ('Work Started','Closed') and
                                        case.IsClosed = false]){

                                            if(mapNQLBCase.get(csMilestone.CaseId).Status == 'Work in Progress' && csMilestone.MilestoneType.Name == 'Work Started'){
                                                csMilestone.CompletionDate = Datetime.now();
                                                caseMilestoneUpdateWIP.add(csMilestone);
                                            }
                                            else if(mapNQLBCase.get(csMilestone.CaseId).Has_Best_Answer__c == true && csMilestone.MilestoneType.Name == 'Closed'){
                                                csMilestone.CompletionDate = Datetime.now();
                                                caseMilestoneUpdateClosed.add(csMilestone);
                                            }
                                        }
        if(caseMilestoneUpdateWIP.size() > 0){
            update caseMilestoneUpdateWIP;
        }
        if(caseMilestoneUpdateClosed.size()>0){
            update caseMilestoneUpdateClosed;
        }
    }
    //End of NQLB Milestone Changes

    if(Trigger.isBefore && Trigger.isUpdate
       && MSAzureHandler.varActivateMSAzureCode){
           MSAzureHandler MSAzureHandlerInstance = new MSAzureHandler();
           MSAzureHandlerInstance.createPayloadForCaseUpdates(Trigger.New,Trigger.oldMap);
       }

    //CCare Technical Escalation Automation : Calling CaseTriggerClass.updateTechnicalEscalationDate method to process record
    // CR:3310661 : Visibility and Do not show in portal changes
    Id caseTechnicalRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
    Id caseAMGRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId();
    //Id caseCarrierProductsRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Carrier Products').getRecordTypeId();
    //Id caseBOCCRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('BOCC').getRecordTypeId();

    List<Case> caseList = new List<Case>();
    List<Case> caseListMgmt = new List<Case>();
    
    Map<Id,Case> mapSpecialEscAdvCase = new Map<Id,Case>();
    Set<Id> setSpecialEscAdvCaseAccId = new Set<Id>();
    Boolean techCaseSevUpdatedTo1 = false;

    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        if(Trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert))
        {
            for(integer i=0;i<Trigger.New.Size();i++)
            {
                //Added By Vamsee : ESESP-3566 (Restrict BOCC case creation from SF UI)
                //Commenting out By Vamsee - ESESP-4029
                /*if(Trigger.new[i].RecordtypeId == caseBOCCRecordTypeId){
                    if(String.valueOf(URL.getCurrentRequestUrl()).contains('/services'))
                    {
                        Trigger.new[i].RecordtypeId = caseTechnicalRecordTypeId;
                        Trigger.new[i].Sub_Type__c = 'BOCC';
                        Trigger.new[i].Validation_Override__c = True;
                        if(Trigger.new[i].Service_Category__c == 'Monocle Alerts')
                            Trigger.new[i].Service_Category__c = 'BOCC - Monocle Alerts';
                        
                    }
                    else
                        Trigger.new[i].addError('You cannot create a BOCC Case. Please Create a Technical case with Subtype = \'BOCC\'');
                }*/

                if((Trigger.isInsert && Trigger.New[i].RecordTypeId == caseTechnicalRecordTypeId)
                   || (Trigger.isUpdate && Trigger.New[i].Escalate_Technical_Case__c != Trigger.Old[i].Escalate_Technical_Case__c))
                {
                    caseList.add(Trigger.New[i]);
                }

                if((Trigger.isInsert && Trigger.New[i].RecordTypeId == caseTechnicalRecordTypeId)
                   || 
                   (Trigger.isUpdate && Trigger.New[i].Escalate_Technical_Mgmt_Case__c != Trigger.Old[i].Escalate_Technical_Mgmt_Case__c))
                {
                    caseListMgmt.add(Trigger.New[i]);
                }

                //Code for setting Visibility and Do not show in portal
                if(Trigger.New[i].RecordTypeId == caseTechnicalRecordTypeId || Trigger.New[i].RecordTypeId == caseAMGRecordTypeId 
                   //|| Trigger.New[i].RecordTypeId == caseCarrierProductsRecordTypeId
                  )
                {
                    if(Trigger.isUpdate && Trigger.New[i].Status != Trigger.Old[i].Status && Trigger.New[i].Status == 'Reopened' && Trigger.New[i].Reopened__c == true){
                        Trigger.New[i].Do_Not_Show_In_Portal_Picklist__c = Trigger.New[i].Do_Not_Show_in_Portal__c ? 'Internal Only':'Customer';
                    }

                    if(Trigger.isInsert && ((Trigger.New[i].Do_Not_Show_In_Portal_Picklist__c  == Null && Trigger.New[i].Do_Not_Show_in_Portal__c) || Trigger.New[i].Do_Not_Show_In_Portal_Picklist__c  == 'Internal Only')){
                        Trigger.New[i].Do_Not_Show_In_Portal_Picklist__c  = 'Internal Only';
                        Trigger.New[i].Do_Not_Show_in_Portal__c = true;
                    }
                    if(Trigger.isInsert && ((Trigger.New[i].Do_Not_Show_In_Portal_Picklist__c  == Null && !Trigger.New[i].Do_Not_Show_in_Portal__c) || Trigger.New[i].Do_Not_Show_In_Portal_Picklist__c  == 'Customer')){
                        Trigger.New[i].Do_Not_Show_In_Portal_Picklist__c  = 'Customer';
                        Trigger.New[i].Do_Not_Show_in_Portal__c = false;
                    }

                    if(Trigger.isUpdate && (((Trigger.New[i].Do_Not_Show_In_Portal_Picklist__c  != Trigger.Old[i].Do_Not_Show_In_Portal_Picklist__c  && Trigger.New[i].Do_Not_Show_In_Portal_Picklist__c  == 'Internal Only') && !Trigger.New[i].Do_Not_Show_in_Portal__c)
                                            || (Trigger.New[i].Do_Not_Show_In_Portal_Picklist__c  == 'Customer' && (Trigger.New[i].Do_Not_Show_in_Portal__c != Trigger.old[i].Do_Not_Show_in_Portal__c && Trigger.New[i].Do_Not_Show_in_Portal__c)))){
                                                Trigger.New[i].Do_Not_Show_In_Portal_Picklist__c  = 'Internal Only';
                                                Trigger.New[i].Do_Not_Show_in_Portal__c = true;
                                            }
                    if(Trigger.isUpdate && (((Trigger.New[i].Do_Not_Show_In_Portal_Picklist__c  != Trigger.Old[i].Do_Not_Show_In_Portal_Picklist__c  && Trigger.New[i].Do_Not_Show_In_Portal_Picklist__c  == 'Customer') && Trigger.New[i].Do_Not_Show_in_Portal__c)
                                            || (Trigger.New[i].Do_Not_Show_In_Portal_Picklist__c  == 'Internal Only' && (Trigger.New[i].Do_Not_Show_in_Portal__c != Trigger.old[i].Do_Not_Show_in_Portal__c && !Trigger.New[i].Do_Not_Show_in_Portal__c)))){
                                                Trigger.New[i].Do_Not_Show_In_Portal_Picklist__c  = 'Customer';
                                                Trigger.New[i].Do_Not_Show_in_Portal__c = false;
                                            }
                }
                
                // changes for ESESP-2497 : Support Advocacy Special Escalation
                if(Trigger.new[i].RecordTypeId == caseTechnicalRecordTypeId 
                   && Trigger.new[i].Sub_Type__c == 'Product Support' 
                   && Trigger.new[i].Work_Type__c != 'Proactive' 
                   && (Trigger.new[i].Do_Not_Show_in_Portal__c == false)
                   && Trigger.new[i].Resolved_Date__c == null
                   && (Trigger.new[i].Status != 'Closed' || Trigger.new[i].Status != 'Resolved'
                       || Trigger.new[i].Status != 'Rejected' || Trigger.new[i].Status != 'Closed - Duplicate')
                   && (Trigger.isInsert 
                       || (Trigger.isUpdate 
                           && 
                           (Trigger.New[i].Escalate_Technical_Mgmt_Case__c != Trigger.Old[i].Escalate_Technical_Mgmt_Case__c && Trigger.New[i].Escalate_Technical_Mgmt_Case__c)
                           ||(Trigger.New[i].Severity__c != Trigger.Old[i].Severity__c && Trigger.New[i].Severity__c == '1')
                          )
                       )
                  )
                {
                    if(Trigger.isUpdate && Trigger.New[i].Severity__c != Trigger.Old[i].Severity__c && Trigger.New[i].Severity__c == '1') 
                    { 
                        techCaseSevUpdatedTo1 = true;
                    }
                    System.debug('!!!!!!! CASE CONSIDERED FOR SPECIAL ESC ');
                    mapSpecialEscAdvCase.put(Trigger.new[i].Id,Trigger.new[i]);
                    setSpecialEscAdvCaseAccId.add(Trigger.new[i].AccountId);
                }
                // end of changes for ESESP-2497 : Support Advocacy Special Escalation
            }
            
            if(!caseList.isEmpty())
                CaseTriggerClass.updateTechnicalEscalationDate(caseList,Trigger.isUpdate,Trigger.isInsert);

            if(!caseListMgmt.isEmpty())
                CaseTriggerClass.updateTechnicalMgmtEscalationDate(caseListMgmt,Trigger.isInsert);
            
            // changes for ESESP-2497 : Support Advocacy Special Escalation
            if(!mapSpecialEscAdvCase.isEmpty())
            {
                SC_CaseTriggerHelperClass3.createSpecialAdvocacyER(mapSpecialEscAdvCase,setSpecialEscAdvCaseAccId, Trigger.isInsert,techCaseSevUpdatedTo1);
            }
        }
    }


    /*****************
        Changes by Sumanth
        JIRA Number : ESEP 1004
        Purpose: To add a check if Solution Code = New Software Failure OR Pre-existing Software Failure then an External dependency of Type Jira must be there else throw an Error.
    ******************/
    
    // changes by Vandhana for ESESP-2346 : Carrier to Technical LX Migration

    //if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    //{
    if(Trigger.isBefore && Trigger.IsUpdate)
    {
        /** Variable added by Sumanth as part of JIRA ESEP 1004 **/
        List<Case> lstCarrierProductCases = new List<Case>();
        
        if(CaseTriggerClass.isFirstTime)
        {
            if(!Test.isRunningTest())
            {
                CaseTriggerClass.isFirstTime = false;
            }
            
            for(Case varCase : Trigger.New)
            {
                if(mRecordType.get(varCase.RecordTypeId).equals('Technical') && varCase.Sub_Type__c == 'Carrier' 
                   && (varCase.Solution_Code__c != null) 
                   && (Trigger.oldMap.get(varCase.Id).Solution_Code__c != Trigger.newMap.get(varCase.Id).Solution_Code__c) 
                   && (varCase.Solution_Code__c=='New Software Failure' || varCase.Solution_Code__c == 'Pre-existing Software Failure') 
                   && !varCase.Validation_Override__c )
                {
                    lstCarrierProductCases.add(varCase);
                }
            }
        }
        
        if(!lstCarrierProductCases.isEmpty())
        {
            CaseTriggerClass.checkEDDependency(lstCarrierProductCases);
        }
    }
    //}

    // changes by Sumanth ESESP-934
    if(Trigger.IsInsert)
    {
        if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
        {
            if(!Test.isRunningTest())
            {
                CaseTriggerClass.avoidAssignment = true;
            }
        }
    }

    if(Trigger.isUpdate)
    {
        if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
        {
            List<Case> lstManagedSecurityCase = new List<Case>();

            if(CaseTriggerClass.avoidRecurrsionms)
            {
                if(!Test.isRunningTest())
                {
                    CaseTriggerClass.avoidRecurrsionms = false;
                }

                for(Case varCase:Trigger.New)
                {
                    if(mRecordType.get(varCase.RecordTypeId).equals('Managed Security') && (Trigger.oldMap.get(varCase.Id).OwnerId != Trigger.newMap.get(varCase.Id).OwnerId) &&(Trigger.oldMap.get(varCase.Id).OwnerId.getsobjecttype()==User.sobjecttype) && !CaseTriggerClass.avoidAssignment)
                    {
                        lstManagedSecurityCase.add(varCase);
                    }
                }
            }

            if(!lstManagedSecurityCase.isEmpty())
            {
                    CaseTriggerClass.sendemailMS(lstManagedSecurityCase,Trigger.oldMap);
            }
        }
    }

    //Changes made for ESESP-1204
    if(Trigger.isUpdate)
    {
        if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
        {
            List<Case> PreSalesCase = new List<Case>();

            if(CaseTriggerClass.avoidRecurrsionpresales)
            {
                if(!Test.isRunningTest())
                {
                    CaseTriggerClass.avoidRecurrsionpresales = false;
                }

                for(Case varCase:Trigger.New)
                {
                    if(mRecordType.get(varCase.RecordTypeId).equals('Pre-Sales') && varCase.Request_Type__c=='Web Performance Architect' && (Trigger.oldMap.get(varCase.Id).OwnerId != Trigger.newMap.get(varCase.Id).OwnerId))
                    {
                        PreSalesCase.add(varCase);
                    }
                }
            }
            if(!PreSalesCase.isEmpty())
            {
                //method to send email to previous owner
                CaseTriggerClass.sendEmailPreSales(PreSalesCase,Trigger.oldMap,Trigger.NewMap);
            }
        }
    }
    
    //ESESP-1402 : Updating Case Product on AMP Cases based on Account's contract
    if(Trigger.isInsert)
    {
        List<Case> caseList = new List<Case>();
        Id caseTechnicalRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        for(Case c : Trigger.New){
            if(c.RecordTypeId == caseTechnicalRecordTypeId && c.Service_Category__c == 'Media-AMP'){
                caseList.add(c);
            }
        }
        CaseTriggerClass.addAMPCaseProduct(caseList);
    }

    //Changes made for 1916 to check if there is an attachment before closing case for AMG
       if(Trigger.isUpdate)
       {
           if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
           {
               Map<Id,Case> caseMap = new Map<Id,Case>();
               Map<Id,Case> oldMap = Trigger.oldMap;
               for(Case varCase:Trigger.New)
               {
                   //Changes by Jay, added validation override and status change check
                   if(!varCase.Validation_Override__c && mRecordType.get(varCase.RecordTypeId).equals('AMG') && varCase.Status=='Closed' && oldMap.get(varCase.Id).Status != varCase.Status)
                   {
                       if((varCase.Service__c=='Contract Management' && varCase.Request_Type__c=='Contract Migration' && varCase.Request_Sub_Type__c=='Migration') ||
                          (varCase.Service__c=='Contract Management' && varCase.Request_Type__c=='Service Migration' && varCase.Request_Sub_Type__c=='Migration'))
                       {
                            caseMap.put(varCase.Id,varCase);
                       }
                   }
               }

               if(!caseMap.isEmpty())
               {
                   CaseTriggerClass.checkAMGAttachments(caseMap);
               }
          }

       }
       
       /*********** Case dispatcher method for SOCC Related Changes **********/
        if(!UserInfo.getName().equalsIgnoreCase('Connection User') && CaseTriggerClass.avoidRecursionSOCCLogic == true)
        {
            CaseTriggerClass.soccCaseTriggerDispatcher(Trigger.New,Trigger.NewMap,Trigger.OldMap,Trigger.IsInsert,Trigger.IsUpdate,mRecordType);
        }
       /*********** End of Case dispatcher method for SOCC Related Changes *****/
    
     /***********ESESP-3075: Populating the partner account for AMG cases **********/
    If(trigger.isInsert)
    {
        Set<Id> updatedAccIds =  new Set<Id>();
        Set<Id> accountIds =  new Set<Id>();
        for(Case cs : Trigger.new)
        {
            If(mRecordType.get(cs.RecordTypeId).equals('AMG') && cs.Partner_Account__c==null)
            {
                updatedAccIds.add(cs.AccountId);
            }
            If(mRecordType.get(cs.RecordTypeId).equals('AMG') && cs.Partner_Account__c!=null)
            {
                accountIds.add(cs.AccountId);
            }
        } 
        
        If(!updatedAccIds.isEmpty())
        {
            CaseTriggerClass.addPartnerAccount(updatedAccIds,Trigger.new);
        }
        If(!accountIds.isEmpty())
        {
            CaseTriggerClass.validatePartnerAccount(accountIds, Trigger.new);
            
        }
        
    }
    /***********ESESP-3075: Validating the partner account for AMG cases **********/
    If(trigger.isUpdate)
    {
        Set<Id> updatedAccIds =  new Set<Id>();
        Set<Id> accountIds =  new Set<Id>();
        for(Case cs : Trigger.new)
        {
            case oldCase = Trigger.oldMap.get(cs.Id);
            
            If(cs.RecordType_Name__c == 'AMG' && (oldCase.RecordType_Name__c != 'AMG'  || oldCase.AccountId != cs.AccountId))
            {
                updatedAccIds.add(cs.AccountId);
            }
            If(oldCase.Partner_Account__c != cs.Partner_Account__c && cs.Partner_Account__c != null)
            {
                
                accountIds.add(cs.AccountId);
            }
        } 
        
        If(!updatedAccIds.isEmpty())
        {
            CaseTriggerClass.addPartnerAccount(updatedAccIds,Trigger.new);
        }
        If(!accountIds.isEmpty())
        {
            CaseTriggerClass.validatePartnerAccount(accountIds, Trigger.new);
        }
        
    }
    
    /*********** ESESP-3075: Populating the Indirect Customer for AMG cases **********/
    
    if(trigger.isInsert)
    {
        Set<Id> updatedAccIds =  new Set<Id>();
        Set<Id> accountIds =  new Set<Id>();
        for(Case cs : Trigger.new)
        {
            If(mRecordType.get(cs.RecordTypeId).equals('AMG') && cs.Indirect_Customer__c==null)
            {
                updatedAccIds.add(cs.AccountId);
            }
            If(mRecordType.get(cs.RecordTypeId).equals('AMG') && cs.Indirect_Customer__c != null)
            {
                accountIds.add(cs.AccountId);
            }
        } 
        
        If(!updatedAccIds.isEmpty())
        {
            CaseTriggerClass.addIndirectCustomer(updatedAccIds,Trigger.new);
        }
        If(!accountIds.isEmpty())
        {
            CaseTriggerClass.validateIndirectCustomer(accountIds, Trigger.new);
            
        }
    }
    
    /*********** ESESP-3075: Validating the Indirect Customers for AMG cases **********/
    If(trigger.isUpdate)
    {
        system.debug('In Update');
        Set<Id> updatedAccIds =  new Set<Id>();
        Set<Id> accountIds =  new Set<Id>();
        for(Case cs : Trigger.new)
        {
            case oldCase = Trigger.oldMap.get(cs.Id);
            
            If(cs.RecordType_Name__c == 'AMG' && (oldCase.RecordType_Name__c != 'AMG'  || oldCase.AccountId != cs.AccountId))
            {
                updatedAccIds.add(cs.AccountId);
            }
            If(oldCase.Indirect_Customer__c != cs.Indirect_Customer__c && cs.Indirect_Customer__c != null)
            {
                accountIds.add(cs.AccountId);
            }
        } 
        
        If(!updatedAccIds.isEmpty())
        {
            CaseTriggerClass.addIndirectCustomer(updatedAccIds,Trigger.new);
        }
        If(!accountIds.isEmpty())
        {
            CaseTriggerClass.validateIndirectCustomer(accountIds, Trigger.new);
        }
        
    }
    
    /*********** ESESP-3152: ESESP-3152: Populating Account Owner and AMG Aligned Rep fields for AMG cases **********/
    
    if(trigger.isInsert)
    {
        Set<Id> accountIds = new Set<Id>();
        for(Case cs : Trigger.new)
        {
            If(mRecordType.get(cs.RecordTypeId).equals('AMG'))
            {
                accountIds.add(cs.AccountId);
            }
        }
        
        If(!accountIds.isEmpty())
        {
            CaseTriggerClass.addPathFields(accountIds, Trigger.new);
        }
    }
    
    if(trigger.isUpdate)
    {
        Set<Id> accountIds = new Set<Id>();
        for(Case cs : Trigger.new)
        {
            case oldCase = Trigger.oldMap.get(cs.Id);
             If(cs.RecordType_Name__c == 'AMG' && (oldCase.RecordType_Name__c != 'AMG'  || oldCase.AccountId != cs.AccountId))
            {
                accountIds.add(cs.AccountId);
            }
        }
        
        If(!accountIds.isEmpty())
        {
            CaseTriggerClass.addPathFields(accountIds, Trigger.new);
        }
    }
    //Oct 10, 2020     Vishnu Vardhan   ESESP-2826      PST related Case Trigger logic
    if(trigger.isInsert) {
        SC_PSTCaseHandler.handlePSTCasesBi(Trigger.new);
    } else if(trigger.isUpdate) {
        SC_PSTCaseHandler.handlePSTCasesBu(Trigger.new, Trigger.oldMap);
    }
    
    //Nov 29, 2021     Vishnu Sharma   ESESP-5772      Logic to restrict edit for OCID field if user is not account team member with required role.
    if(trigger.isInsert || trigger.isUpdate){
        SC_CaseTriggerHelperClass3.validationForAuthorizedUserForOCIDEdit(Trigger.new, Trigger.oldMap,Trigger.isInsert);
    }
}