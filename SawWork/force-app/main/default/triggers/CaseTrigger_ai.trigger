/******
CaseTrigger_ai
@version 1.0
@author Karteek Mekala <kmekala@akamai.com>
@Description : This trigger is called on 'after insert' event on the Case object.
It takes care of the following :
- Add the Case.Created By User to the Case Team if the User-Profile is not Admin or Operations...

@History
--Developer                                         --Date          --Change
Karteek Kumar M                                     12/04/2010      Created the trigger
Vinayendra T N                                      24/12/2010      Email to case, Send email if case is created on UI.
Pitamber Sharma                                         07/05/2013      Change owner based on avaialability if Case owner is Primary/Secondary Assignment Queue.
Denise Bacher (salesforce.com)      10/22/2013      automatic syncing of new case records with the DR organization and re-establish the lookup relationships if the record is recieved from another organization
Kunal Sharma: 11/29/2013: Modified class for record type checks.
Kunal Sharma: 05/21/2014: Removed extra SOQLs from the Trigger.
Akhila Vidapanapati : 05/22/2014 : Modified Trigger to invoke SendEmailToNotificationTeam Method
Commented out SendEmailToAccountTeam method by replacing it with workflow.
Sonia Sawhney:  05/24/2014: CR 2643825 - DR : Issues related to case sync to QA
Sonia Sawhney:  07/17/2014: CR 2712153 - DR: Reverse Update Issue for Objects
Akhila Vidapanapati : 30/07/2014: Added call for ChangePSCaseOwner
Akhila Vidapanapati : 08/01/2015: CR#2883378 : Added DR bypass condition
Akhila Vidapanapati : 03/23/2015: CR#2779077 : Trigger Case Notification Subscription emails when Case Account/RecordType is changed
Akhila Vidapanapati:  06/25/2015: CR#3024056 :Removed call for ChangePSCaseOwner and moved to SC_Monocle_CaseIssue
Sharath Prasanna: 21 Nov 2016: CR#3410681: get all the cases where the case owner changed from PS queue to a user
Vamsee Surya    : 24-Nov-2016: CR#3564721: Automate Billing case assignment to team members
Vandhana        : 27-May-2017   JIRA ESESP-551      Cases for Specialist Pre-Sales - Part 2
Vandhana        : 27-June-2017  JIRA ESESP-389      Better logging for field "Living Summary/Next Steps"
Vandhana        : 27-Oct-2017   JIRA ESESP-595      S2ET Case History Tracking
Vikas           : 21-Dec-2017   JIRA ESESP-822      Case Notifications for Authorized Contacts
Vandhana        : 12-April-2018 JIRA ESESP-834      Octoshape Escalation
Vandhana        : 19-Sept-2018  JIRA ESESP-430      Close activities as invalid when case is closed as invalid
Vandhana        : 19-Sept-2018  JIRA ESESP-688      Ownership of tasks included in a case should always reflect the case owner
Vandhana        : 19-Dec-2018   JIRA ESESP-1891     Xiphos Email Notifications to Customers
Ankit           : 03-June-2019  IRC-1: Removed the custom setting call from for loop and optimized it.
Sumanth         : 06-Aug-2019   JIRA ESESP 2006     Removed Closure Email sent to Additional Email SOCC
Sharath         : 18-Dec-2019   JIRA ESESP-2467     Changes for Subdomain Takeover. Sending Email to Primary and Secondary contacts
Sheena          : 05-Feb-2020   JIRA ESESP-2872     Related Cases functionality for AMG Cases
Sumukh/Pinkesh  : 19-March-2020 JIRA ESESP-2026     SOCC RunBook Changes
Vamsee          : 24-Apr-2020   JIRA ESESP-1342     BOCC to Technical Migration
Vandhana          10/05/2020         ESESP-3524     S2ET
Sumukh SS       : 29-June-2020  JIRA ESESP-3519     SOCC Runboooks
Vikas           : 09/06/2020         ESESP-3663     Provisioning
Sharath Prasanna :22 July 2020  JIRA ESESP-3659     Changes for Billing Case migration. Throwing a platform event from update
Vikas           : 24/09/2020    JIRA ESESP-4158     Added new Service values for Provisioning cases
Vishnu Vardhan  : 30/09/2020         ESESP-2826     PST related Case Trigger logic 
Sheena          : 11-Sep-2020   JIRA ESESP-3809     IRAPT : Impacted Account and Product functionality
Sumukh SS       : 26-Nov-2020   JIRA ESESP-2235     Akatec Enhanced Milestones
Vandhana        : 20-Feb-2021        ESESP-2346     Carrier LX Migration
Sharath Prasanna : july 7 2021  Jira ESESP-4356     Jarvis Changes  
Aditi Singh 	: 16/August/2021  	ESESP-5670 		PS Product - Provisioning Dashboard Changes - changed Platform Product occurrence with Case Product
Sujay           : 07-Sep-2021        ESESP-5678     24PS cases in s2et
Sujay           : 07-Oct-2021        ESESP-5981     24PS cases in s2et
Sharath         : 20 Oct 2021        ESESP-6150     Business Unit on PS cases
Jay             : 16 Feb 2022       ESESP-6703      Added status close check
Sharath         : 23 Feb 2022        ESESP-6716     Routing issue for PTS cases and Jarvis Global Beta changes
Sheena			: 24-Feb-2022		 ESESP-5143		Customer Surveys on internal AMG Cases
Tejaswini       : 01-Dec-2021        ESESP-6008     SOCC AIM Program  -  LA Rollout
******/

trigger CaseTrigger_ai on Case (after insert, after update)
{
    //Check for preventing recursive trigger calls
    if(!ExternalSharingHelper.isTriggerFutureControl && (!system.Test.isRunningTest() || (system.Test.isRunningTest() && ExternalSharingHelper.RunFromtestClass == true)))
    {
        if(Trigger.isAfter){
            if(Trigger.isInsert){
                //Modified by ssawhney CR 2643825- added Engagement request in the related list section for cases
                // Engagement request should also be synced along with the case
                ExternalSharingHelper.createS2Ssync('', Trigger.new, 'CaseComment,Attachment,Case_Transition__c,Case_Update_History__c,External_Dependency__c,Status_Report__c,Engagement_Request__c');
            }
            else if(Trigger.isUpdate)
            {
                ExternalSharingHelper.CaptureRecordUpdate('Case', Trigger.newMap.keyset());
            }

            //Commented out by ssawhney for CR 2712153 - removed the logic from after trigger and moved to before trigger
            // call future method to link all lookups for the Case object
            /*Set<Id> ids = ExternalSharingHelper.filterRecordIds('Case', Trigger.isUpdate, Trigger.new, Trigger.oldMap);
            if (ids.size() > 0) {
            ExternalSharingHelper.linkObjects('Case', ids, ExternalSharingHelper.mpFields);
            } */
        }
    }

    /* Add the Case.Created By User to the Case Team if the User-Profile is not Admin or Operations*/
    // Get the Profile Ids of the Admin / Operations profiles.
    Set<Id> superProfileIds = new Set<Id>();
    for(SC_SuperProfileID__c objSuperProfileId : SC_SuperProfileID__c.getAll().Values()){
        superProfileIds.add(objSuperProfileId.ProfileId__c.trim());
    }
    /*for(Profile pr:[select Id from Profile where (Name = 'System Administrator') or (Name like '%Operations%') or (Name like '%Ops%')])
    superProfileIds.add(pr.Id);*/

    //added by Denise Batcher for S2S created records
    if(Trigger.isInsert && UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        list<Case> cases = new list<Case>();
        set<string> userAliases = new set<string>();
        map<string, Id> caseUserMap = new map<string, Id>();
        for (Case cs:Trigger.New)
        {
            userAliases.add(cs.AKAM_Created_By__c);
        }
        list<User> caseUsers = [SELECT ProfileId, Alias FROM User WHERE Alias in :userAliases];
        for(User u:caseUsers)
        {
            caseUserMap.put(u.Alias, u.ProfileId);
        }

        for(Case cs:Trigger.New)
        {
            if(!superProfileIds.contains(caseUserMap.get(cs.AKAM_Created_By__c)))
            {
                cases.add(cs);
            }
        }
        // for each record whose original creator is not Admin/Operations, then add to Case Team
        if(cases.size() > 0){
            CaseTriggerClass.AddCreatedByToCaseTeam(cases);
        }
            
    }
    // If the User is not Admin/Operations, and this is not an S2S record, then add to Case Team
    else if(Trigger.isInsert && !superProfileIds.contains(Userinfo.getProfileId())){
        CaseTriggerClass.AddCreatedByToCaseTeam(Trigger.new);
    }
        


    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        //Aug 20, 2020     Vishnu Vardhan   ESESP-2826      PST related Case Trigger logic
        if(Trigger.isAfter && Trigger.isInsert) {
            SC_PSTCaseHandler.handlePSTCasesAi(Trigger.new);
        }

        //Jan 14, 2021  ESESP-4574   Vishnu Vardhan PST related Case Trigger logic
        if(Trigger.isAfter && Trigger.isUpdate) {
            SC_PSTCaseHandler.handlePSTCasesAu(Trigger.new,Trigger.oldMap);
        }
        
        Email_to_Case__c customSettingsMomentum = Email_to_Case__c.getInstance('Momentum');
        Email_to_Case__c customSettingsProdMgmt = Email_to_Case__c.getInstance('ProdMgmt');

        map<Id, Schema.RecordTypeInfo> mCaseRecordType = Case.sObjectType.getDescribe().getRecordTypeInfosById();
        map<Id, string> rTypesMap = new map<Id,string>();
        for(string varCaseRecordTypeId :mCaseRecordType.keySet()){
            rTypesMap.put(varCaseRecordTypeId, mCaseRecordType.get(varCaseRecordTypeId).getName());
        }
        /*
        Map<Id, String> rTypesMap = new Map<Id, String>();
        for(RecordType rt : [SELECT id, Name FROM RecordType WHERE isActive=true And sObjectType = 'Case']) {
        rTypesMap.put(rt.Id, rt.Name);
        }
        */
        List<Case> lCaseForSC = new List<Case>();
        List<Case> lnonPSCaseForSC = new List<Case>();
        List<Case> lAMGCSATCases = new List<Case>();
        //Order Approval Changes
        Map<Id,String> parentCaseIdADNameMap = new Map<Id,String>();
        Map<Id,Id> parentCaseIdMap = new Map<Id,Id>();
        Map<Id,Id> caseOppIdMap = new Map<Id,Id>();
        List<Id> lOAReopenCaseId = new List<Id>();
        List<Id> lOAReopenOAId = new List<Id>();
        List<Id> lOACloseCaseId = new List<Id>();
        List<Id> lOAIdCloseCaseAll = new List<Id>();
        List<Id> lOAApproverChangeCaseId = new List<Id>();
        //Vamsee : Jarvis Changes ESESP-4356
        List<Id> jarvisCaseIdList = new List<Id>();

        //Changes by Sharath for ESESP-6790
        Boolean jarvisSkipCreateEmail = false;
        for( SC_Utility__mdt utilRecord : [SELECT Value_Text__c FROM SC_Utility__mdt WHERE DeveloperName = 'JarvisSkipCreateEmail'])
        {
            jarvisSkipCreateEmail = utilRecord.Value_Text__c != null? Boolean.valueOf(utilRecord.Value_Text__c) : false;
        }

        //OA to send email to OM case owner and Opp Owner
        //Map<Id,String> caseIdWithEmail = new Map<Id,String>();
        Map<Id,List<Id>> oaIdWithListCaseId = new Map<Id,List<Id>>();
        //Map<Id,String> oaIdWithOppEmailId = new Map<Id,String>();
        //Set<Id> caseIdsToSearchCreatedByEmailId = new Set<Id>();
        Map<Id,Id> caseIdWithOppIdMap = new Map<Id,Id>();
        List<Id> oaCaseIdOwnerAssignenment = new List<Id>();
        
        //Added by Bhavesh,ESESP-3590, RCA request changes
        List<Id> rcaRequestCaseList = new List<Id>();
        List<Id> caseClosedIds = new LIst<Id>();
        List<Id> caseInitialMilestoneIDs = new LIst<Id>();
        List<Id> transitionCaseIds = new LIst<Id>();
        Map<Id,Id> caseWithServIncIdMap = new Map<Id, Id>();
        
        // changes by Vandhana
        // added Pre-Sales record type for Cases
        for(Case c : Trigger.new)
        {
            if(rTypesMap.get(c.RecordTypeId) != null && (rTypesMap.get(c.RecordTypeId).equals('Technical')
                                                         || rTypesMap.get(c.RecordTypeId).equals('AMG')
                                                         || rTypesMap.get(c.RecordTypeId).equals('Billing')
                                                         || rTypesMap.get(c.RecordTypeId).equals('GSS CSAT')
                                                         || rTypesMap.get(c.RecordTypeId).equals('Invalid Case')
                                                         || rTypesMap.get(c.RecordTypeId).equals('Professional Services')
                                                         || rTypesMap.get(c.RecordTypeId).equals('Revenue Recognition')
                                                         || rTypesMap.get(c.RecordTypeId).equals('Stability Engineering')
                                                         || rTypesMap.get(c.RecordTypeId).equals('Partner Technical Support')
                                                         || rTypesMap.get(c.RecordTypeId).equals('Emerging Products Engineering')
                                                          //|| rTypesMap.get(c.RecordTypeId).equals('Carrier Products')
                                                         || rTypesMap.get(c.RecordTypeId).equals('Managed Security')
                                                         || rTypesMap.get(c.RecordTypeId).equals('Pre-Sales')
                                                         || rTypesMap.get(c.RecordTypeId).equals('RCA Request')))
            {
                lCaseForSC.add(c);
                if(rTypesMap.get(c.RecordTypeId) != 'Professional Services'){
                    lnonPSCaseForSC.add(c);
                }
                    
                if(rTypesMap.get(c.RecordTypeId).equals('AMG') || rTypesMap.get(c.RecordTypeId).equals('GSS CSAT')){
                     lAMGCSATCases.add(c);
                }
                   
            }
            //Vikas: Order Approval Escalation case insert
            if(Trigger.isInsert && rTypesMap.get(c.RecordTypeId) != null)
            {
                if(rTypesMap.get(c.RecordTypeId).equals('Order Approval-Escalations'))
                {
                    parentCaseIdADNameMap.put(c.parentId, c.Approval_Detail_ID__c);
                    parentCaseIdMap.put(c.parentId, c.id);
                }
                if(rTypesMap.get(c.RecordTypeId).equals('Order Approval-Deal Desk')
                   || rTypesMap.get(c.RecordTypeId).equals('Order Approval-Legal')
                   || rTypesMap.get(c.RecordTypeId).equals('Order Approval-Order Management')
                   || rTypesMap.get(c.RecordTypeId).equals('Order Approval-Escalations')
                   || rTypesMap.get(c.RecordTypeId).equals('Order Approval-Others')
                   || rTypesMap.get(c.RecordTypeId).equals('Order Approval-Sales Manager'))
                {
                    caseOppIdMap.put(c.id, c.Opportunity__c);
                }
                
            }
            //Vamsee : Jarvis Changes ESESP-4356
            // Changes by Sharath for ESESP-6790            
            if(Trigger.isInsert && !jarvisSkipCreateEmail && !c.Do_Not_Show_in_Portal__c && !c.IsMicrosoftAzureAccount__c && 
            SC_Jarvis_CoreSecurityController.caseRecordTypesJarvis.contains(rTypesMap.get(c.RecordTypeId))){
                jarvisCaseIdList.add(c.Id);   
            }
            
            // reopen Case for Closed Opportunities/Order Approvals, update status of OA to In Progress
            if(Trigger.isUpdate &&
               (rTypesMap.get(c.RecordTypeId).equals('Order Approval-Deal Desk')
                || rTypesMap.get(c.RecordTypeId).equals('Order Approval-Legal')
                || rTypesMap.get(c.RecordTypeId).equals('Order Approval-Order Management')
                || rTypesMap.get(c.RecordTypeId).equals('Order Approval-Escalations')
                || rTypesMap.get(c.RecordTypeId).equals('Order Approval-Others')
                || rTypesMap.get(c.RecordTypeId).equals('Order Approval-Sales Manager')
               )
              )
            {
                if(c.Status != Trigger.oldMap.get(c.Id).Status && c.Status == 'Reopened'){
                    lOAReopenCaseId.add(c.Id);
                    lOAReopenOAId.add(c.Order_Approval__c);
                }
                //send email to case creator when case is assigned for the first time from queue
                if(c.OwnerId != Trigger.oldMap.get(c.Id).OwnerId && string.valueOf(c.OwnerId).startsWith('005') && string.valueOf(Trigger.OldMap.get(c.id).OwnerId).startsWith('00G')){
                    oaCaseIdOwnerAssignenment.add(c.Id);
                }
                if(c.Status != Trigger.oldMap.get(c.Id).Status && (c.Status == 'Closed-Approved'||c.Status == 'Closed-Auto Approved'
                   ||c.Status == 'Closed-Approval Not Needed'||c.Status == 'Closed' || c.Status == 'Closed-Insufficient Information' || c.Status == 'Closed-Quote Term Updated'|| c.Status == 'Closed-Quote Approved'))
                {
                    lOACloseCaseId.add(c.Id);  
                    lOAIdCloseCaseAll.add(c.Order_Approval__c);
                    if(c.Opportunity__c != null){
                        caseIdWithOppIdMap.put(c.id,c.Opportunity__c);
                    }
                    
                    //send email to OM case Owner
                    if(c.Order_Approval__c != NULL && !rTypesMap.get(c.RecordTypeId).equals('Order Approval-Order Management')){
                        if(!oaIdWithListCaseId.containsKey(c.Order_Approval__c)){
                            oaIdWithListCaseId.put(c.Order_Approval__c, new List<Id>());
                        }
                        List<Id> caseIds = new List<Id>(oaIdWithListCaseId.get(c.Order_Approval__c));
                        caseIds.add(c.Id);
                        oaIdWithListCaseId.put(c.Order_Approval__c , caseIds);
                    }
                } 
                
                if(c.Approver__c != Trigger.oldMap.get(c.Id).Approver__c && c.Approver__c != null){
                    lOAApproverChangeCaseId.add(c.Id);
                }
            }
            //Added by Bhavesh,ESESP-3590, RCA request changes
            //RCA can be created only under AMG or Technical, so when Service incident is updated on AMG or Technical cases, that should reflect on RCA case and Knowledge record as well.
            if ((rTypesMap.get(c.RecordTypeId).equals('AMG') || rTypesMap.get(c.RecordTypeId).equals('Technical')) && Trigger.isAfter && Trigger.isUpdate) {
                if( c.Service_Incident__c != Trigger.oldMap.get(c.Id).Service_Incident__c && c.Service_Incident__c != NULL ){
                    caseWithServIncIdMap.put(c.Id, c.Service_Incident__c);
                }
            }
            if (rTypesMap.get(c.RecordTypeId).equals('RCA Request') && Trigger.isAfter) {
                if (Trigger.isInsert )
                    rcaRequestCaseList.add (c.Id);
                if (Trigger.isUpdate){
                    if( c.Status == 'RCA Delivered' && c.Status != Trigger.oldMap.get(c.Id).Status ) {
                        caseClosedIds.add (c.id);
                    }
                    
                    if(c.Status != Trigger.oldMap.get(c.Id).Status && Trigger.oldMap.get(c.Id).Status == 'Unassigned'){
                           caseInitialMilestoneIDs.add (c.id);
                    }
                    //when RCA is in SERVICE_INCIDENTS_QUEUE and owner id is updated to user, then complete the transition record.
                    if(string.valueOf(c.OwnerId).startsWith('005') && string.valueOf(Trigger.OldMap.get(c.id).OwnerId).startsWith('00G')){
                        //List<Group> queueList = [select Id from Group where (Name = 'SERVICE_INCIDENTS_QUEUE' OR Name = 'ATS_IRAPT_TRANSITION_QUEUE') and Type = 'Queue'];
                        //if( queueList[0].Id == Trigger.OldMap.get(c.id).OwnerId || queueList[1].Id == Trigger.OldMap.get(c.id).OwnerId) 
                        transitionCaseIds.add(c.Id);
                    }
                    
                }
            }
        }
        //Added by Bhavesh,ESESP-3590, RCA request changes
        if(rcaRequestCaseList.size() > 0) {
            SC_CaseTriggerHelperClass3.sendEmailRCACreation (Trigger.New);
        }
        //Complete final RCA milestone
        if (caseClosedIds.size() > 0){
            SC_CaseTriggerHelperClass3.completeMilestone (caseClosedIds, 'Final RCA', DateTime.now());
        }
            
        //Mark completed the transition record.
        if (transitionCaseIds.size() > 0){
            SC_CaseTriggerHelperClass3.completeTransition (transitionCaseIds, Trigger.NewMap);
        }
            
        //Complete Initial Assessment RCA milestone
        if(caseInitialMilestoneIDs.size()>0){
            SC_CaseTriggerHelperClass3.completeMilestone (caseInitialMilestoneIDs, 'Initial Assessment', DateTime.now());
        }
        if(caseWithServIncIdMap.size() > 0){
            SC_CaseTriggerHelperClass3.updateRCAServIncdValue( caseWithServIncIdMap );
        }
        
        if( !System.isBatch() && !CaseTriggerClass_OA.oaRecursiveCheckSendEmail && (!oaIdWithListCaseId.isEmpty() 
             || !lOACloseCaseId.isEmpty() || !oaCaseIdOwnerAssignenment.isEmpty())){ 
            CaseTriggerClass_OA.caseClosureNotificationLogic(lOACloseCaseId,oaIdWithListCaseId,caseIdWithOppIdMap,oaCaseIdOwnerAssignenment);
        } 
        //Vikas: Update AD on escalation creation
        if(parentCaseIdADNameMap.keySet().size() > 0 && parentCaseIdMap.keySet().size() > 0)
        {
            CaseTriggerClass_OA.updateADOnEscalation(parentCaseIdADNameMap,parentCaseIdMap);
        }
        if(caseOppIdMap.keySet().size() > 0)
        {
            CaseTriggerClass_OA.shareCaseWithOppTM(caseOppIdMap,Trigger.new);
        }
        if(!lOAReopenCaseId.isEmpty())
        {
            CaseTriggerClass_OA.reopenOACase(lOAReopenCaseId,lOAReopenOAId,Trigger.newMap);
        }
        if(!lOACloseCaseId.isEmpty())
        {
            CaseTriggerClass_OA.closeOACaseAndPendingAD(lOACloseCaseId,Trigger.newMap,lOAIdCloseCaseAll);
        }
        if(!lOAApproverChangeCaseId.isEmpty())
        {
            CaseTriggerClass_OA.updateADApprover(lOAApproverChangeCaseId,Trigger.newMap);
        }
		
        //Vamsee : Jarvis Changes ESESP-4356
        if(jarvisCaseIdList.size() > 0 && !System.isfuture() && !system.isBatch() && !system.isQueueable()){
            //EmailMessageTriggerHandler.byPassIRUpdateSOCC = True;
            SC_Jarvis_utility.sendEmailtoAlsoNotify(jarvisCaseIdList);            
        }

        if(Trigger.isAfter && !SC_CPSNotifications.cpsRecCheck){
            SC_CPSNotifications instanceOfCPS = new SC_CPSNotifications();
            instanceOfCPS.triggerInputHandler(Trigger.isInsert, Trigger.isUpdate, Trigger.newMap, Trigger.oldMap, rTypesMap);
        }

        //Send email for email to case
        if(Trigger.isInsert)
        {
            List<Case> updateList = new List<Case>();
            List<Case> updateListProdMgmt = new List<Case>();

            for(Case c:Trigger.new)
            {
                //check if record type is momentum and email to case is false
                if(c.RecordTypeId==customSettingsMomentum.CaseRecord__c && c.Email_to_case__c==False)
                    updateList.add(c);
                if(c.RecordTypeId==customSettingsProdMgmt.CaseRecord__c && c.Email_to_case__c==False)
                    updateListProdMgmt.add(c);
            }

            if(updateList.size()>0){
                CaseTriggerClass.EmailToCaseSendEmail(updateList,CustomSettingsMomentum,new String[] {});
            }
                
            if(updateListProdMgmt.size()>0){
                CaseTriggerClass.EmailToCaseSendEmail(updateListProdMgmt,CustomSettingsProdMgmt,new String[] {});
            }
                
        }

        //Start of changes by Sharath for CR 3410681: After Update, Check for PS cases assigned to a user from a PS queue
        if(Trigger.isUpdate)
        {
            List<Case> caseForAssignmentCreation = new List<Case>();
            //Get the recordTypeID for Professional Services & Technical
            Id professionalServicesId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
            Id technicalRTId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
    
            //Check for cases with Professional Services record type, whose owner has changed from a queue, (ID starts with 00G) to a user (ID starts with 005) and is linked to a project
            //List to store the cases where owner need to be updated
            List<Case> billingCaseList = new List<Case>();

            List<Case> caseOwnerOppTeamLst = new List<Case>();
            
            //To mark Technical(BOCC) milestones complete
            List<Id> caseIdforMitigationMilestonesUpdate = new List<Id>(); 
            List<Id> caseIdforRootCauseMilestonesUpdate = new List<Id>(); 
            List<Id> caseIdforCarrierMitigationMilestones = new List<Id>(); 
            
            //Map of CaseID and Previous Case Owner ID
            map<Id,id> caseIdforEnhancedMilestoneCreation = new map<Id,id>(); 
            
            map<Id,boolean> caseIDforIRUpdateHasSevChanged = new map<Id,boolean>(); 

            for(Case c:Trigger.new)
            {        
                if(c.RecordTypeId == professionalServicesId && string.valueOf(c.OwnerId).startsWith('005') && string.valueOf(Trigger.OldMap.get(c.id).OwnerId).startsWith('00G'))
                {
                    caseForAssignmentCreation.add(c);
                }

                //Start of changes by Vamsee for CR 3564721
                if(!c.IsClosed && rTypesMap.get(c.RecordTypeId).equals('Billing') && c.ownerid == SCUserIdCustomSetting__c.getInstance('Billing Queue').UserId__c)
                {
                    billingCaseList.add(c);
                }

                // changes by Vandhana
                if(rTypesMap.get(c.RecordTypeId).equals('Pre-Sales') && String.valueOf(c.OwnerId).startsWith(Schema.SObjectType.User.getKeyPrefix()) && (String.valueOf(Trigger.OldMap.get(c.id).OwnerId) != c.OwnerId) && c.Opportunity__c != NULL)
                {
                    caseOwnerOppTeamLst.add(c);
                }
                
                // Changes by Sumukh for Akatec Enhanced Milestones
                
                if(c.RecordTypeId == technicalRTId)
                {
                    boolean isCaseSameRecType = c.RecordTypeId==Trigger.OldMap.get(c.id).recordtypeid ? true : false;
                    
                    if(c.Severity__c != trigger.oldMap.get(c.id).Severity__c)
                    {
                        caseIDforIRUpdateHasSevChanged.put(c.id,true); //For resetting IR milestones
                    }
                    
                    if(!isCaseSameRecType || (c.Do_Not_Show_in_Portal__c!=Trigger.OldMap.get(c.id).Do_Not_Show_in_Portal__c && c.Do_Not_Show_in_Portal__c==false))
                    {
                        caseIDforIRUpdateHasSevChanged.put(c.id,false); // For starting the entitlement process from first - Casetrigger bu has milestone fire code
                    }
                    
                    //Added by Vamsee - Adding Severity Change check - ESESP-4735
                    if(c.isclosed != Trigger.OldMap.get(c.id).isclosed && c.IsClosed || (String.valueOf(Trigger.OldMap.get(c.id).OwnerId) != c.OwnerId) && (isCaseSameRecType) || c.Override_Next_Case_Update__c  != Trigger.OldMap.get(c.id).Override_Next_Case_Update__c || c.Severity__c != Trigger.OldMap.get(c.id).Severity__c)
                    {
                        caseIdforEnhancedMilestoneCreation.put(c.id, Trigger.OldMap.get(c.id).ownerid);
                    }
                    
                    //Added by Vamsee (ESESP-1342)
                    // changes by Vandhana for Carrier
                    if((c.Status == 'Mitigated / Solution Provided' && 
                        trigger.oldmap.get(c.Id).Status != 'Mitigated / Solution Provided') && (c.Sub_Type__c == 'BOCC' || c.Sub_Type__c == 'Carrier'))
                    {
                        caseIdforMitigationMilestonesUpdate.add(c.Id);
                    } 
                    //Added by Vamsee (ESESP-1342)
                    else if(trigger.oldmap.get(c.Id).Root_Cause_technical__c == null && c.Root_Cause_technical__c != null)
                    {
                        caseIdforRootCauseMilestonesUpdate.add(c.Id);
                    } 
                    else if(c.Sub_Type__c == 'Carrier' && trigger.oldMap.get(c.Id).MitigationDate__c != c.MitigationDate__c && String.isNotBlank(String.valueOf(c.MitigationDate__c)))
                    {
                        caseIdforCarrierMitigationMilestones.add(c.Id);
                    }
                }
            }
            
          
            //Call the createAssignmentForCaseOWner method
            if(caseForAssignmentCreation != null && caseForAssignmentCreation.size() > 0)
            {
                PSA_ProjectActions.createAssignmentForCaseOWner(caseForAssignmentCreation);
            }

            // Call for Update owner method
            if(billingCaseList.size()>0 && billingCaseList != null)
            {
                CaseTriggerClass.UpdateOwnerForBilling(billingCaseList);
            }
            // End of Changes by Vamsee
            if(caseOwnerOppTeamLst.size()>0 && caseOwnerOppTeamLst != null)
            {
                CaseTriggerClass.preSalesCaseOwnerOppTeam(caseOwnerOppTeamLst);
            }
            
            // Changes by Sumukh for Akatec Enhanced Milestones
            if(caseIdforEnhancedMilestoneCreation.size()>0 && !SC_CaseTriggerHelperClass3.createenhmilestone)
            {
                SC_CaseTriggerHelperClass3.createenhmilestone=true;
                SC_CaseTriggerHelperClass3.createEnhancedMilestone(caseIdforEnhancedMilestoneCreation);
            }
            if(caseIDforIRUpdateHasSevChanged.size() > 0){
                 SC_CaseTriggerHelperClass3.technicalIRMilestoneUpdate(caseIDforIRUpdateHasSevChanged);
            }
               
            
            //Added by Vamsee (ESESP-1342)
            if(caseIdforMitigationMilestonesUpdate.size() > 0){
                SC_CaseTriggerHelperClass.technicalBOCCnCarrierMilestonesUpdate(caseIdforMitigationMilestonesUpdate, 'Resolution');
            }
                
            if(caseIdforCarrierMitigationMilestones.size() > 0){
                SC_CaseTriggerHelperClass.technicalBOCCnCarrierMilestonesUpdate(caseIdforCarrierMitigationMilestones, 'Mitigation');
            }
                
            if(caseIdforRootCauseMilestonesUpdate.size() > 0){
                SC_CaseTriggerHelperClass.technicalBOCCnCarrierMilestonesUpdate(caseIdforRootCauseMilestonesUpdate, 'Root Cause Analysis');
            }
                
    
        }
        //End of changes by Sharath
        if (Trigger.isInsert || Trigger.isUpdate)
        {
            /*
            For IRCases, Escal_Owner should have read/write access to the case. Below code to manually grant 'edit' access on the case.
            */
            List<Case> toUpdateCaseShareList = new List<Case>();

            //List<Case> caseForOctoshape = new List<Case>();
            //Set<Id> caseForOctoshape_future = new Set<Id>();

            Map<Id,Case> psOldCase = new Map<Id,Case>();
            Map<Id,Case> psNewCase = new Map<Id,Case>();

            Map<Id,Case> caseAMGCloseInvalid = new Map<Id,Case>();
            //JIRA: IRC-1
            String irCaseDefaultRecordTypeIds = GSMUtilClass.GetCustomSettingValue('IR_CaseRecordTypeIds');
            
            //ESESP-2467: Sud-domain Takeover tool
            List<Id> subdomainNotificationCases = new List<Id>();

            //Changes for JARVIS: ESESP-4356
            List<Id> caseShareListJarvis = new List<Id>();
            List<Id> caseShareListJarvisDeprovision = new List<Id>();
            //Changes for JARVIS: ESESP-6150
            List<Id> casesForBusinessUnit = new List<Id>();
            
            // Changes by Vandhana for S2ET ESESP-3524
            // Added 'Plx_Products','Plx_Queue_Id' by Vikas for Provisioning: ESESP-3663
            //ESESP-5678 : Adding 24PS queue Id
            List<SC_Utility__mdt> lstSCUtilMDT = [SELECT DeveloperName,Value_Text__c
                                                  FROM SC_Utility__mdt
                                                  WHERE DeveloperName IN ('Security_Services_Task_RT','PS24_Queue_Id','S2ET_Queue_Id','Owner_Not_Assigned_User_Id','Plx_Products','Plx_Queue_Id','Plx_Service_Values')];
            
            Map<String,String> mapSCUtilMDTVal = new Map<String,String>();
            Map<Id,Case> mapS2ETCase = new Map<Id,Case>();
            List<Id> lstS2ETCaseId = new List<Id>();
            Map<Id,Case> mapPlxCase = new Map<Id,Case>();//Changes by Vikas for Provisioning: ESESP-3663
            
            for(SC_Utility__mdt eachRec : lstSCUtilMDT)
            {
                mapSCUtilMDTVal.put(eachRec.DeveloperName,eachRec.Value_Text__c);
            }
            
            for (Case c: Trigger.new)
            {
                if (irCaseDefaultRecordTypeIds.containsIgnoreCase(c.RecordTypeId))
                {
                    if ((Trigger.isInsert && c.IR_Escal_Owner__c!=null) || (Trigger.isUpdate && c.IR_Escal_Owner__c != Trigger.oldMap.get(c.Id).IR_Escal_Owner__c))
                    {
                        toUpdateCaseShareList.add(c);
                    }
                }

                //changes by Vandhana for ESESP-595
                if(Trigger.isUpdate && rTypesMap.get(c.RecordTypeId).equals('Professional Services') && CheckRecursion.runOnce())
                {
                    psOldCase.put(Trigger.oldMap.get(c.Id).Id,Trigger.oldMap.get(c.Id));
                    psNewCase.put(c.Id,c);
                }
                
                // changes by Vandhana for S2ET
                if(rTypesMap.get(c.RecordTypeId).equals('Professional Services') 
                   && !c.IsClosed  
                   //ESESP-5678 Adding 24PS Queue Id
                   && (mapSCUtilMDTVal.get('S2ET_Queue_Id').containsIgnoreCase(c.OwnerId) || mapSCUtilMDTVal.get('PS24_Queue_Id').containsIgnoreCase(c.OwnerId))
                   && (Trigger.isInsert || (Trigger.IsUpdate 
                                            && (Trigger.oldMap.get(c.Id).Case_Transition_Date__c == NULL && c.Case_Transition_Date__c != NULL 
                                                && Trigger.oldMap.get(c.Id).Case_Transition_Date__c != c.Case_Transition_Date__c)
                                            && (c.RecordTypeId != Trigger.oldMap.get(c.Id).RecordTypeId 
                                                || c.OwnerId != Trigger.oldMap.get(c.Id).OwnerId))
                      )
                   && SC_CaseTriggerHelperClass2.s2etTaskRecursion
                  )
                {
                    mapS2ETCase.put(c.Id,c);
                }
                
                if(!c.IsClosed
                   //changes by Sujay : Add 24 PS cases : ESESP-5981
                   && ( mapSCUtilMDTVal.get('S2ET_Queue_Id').containsIgnoreCase(c.OwnerId) 
                        || mapSCUtilMDTVal.get('PS24_Queue_Id').containsIgnoreCase(c.OwnerId) ) //&& !System.isFuture()
                   && Trigger.IsUpdate &&
                   (
                       (c.Last_Case_Update__c != NULL && Trigger.oldMap.get(c.Id).Last_Case_Update__c != c.Last_Case_Update__c 
                        && (c.Last_Customer_Activity_Date__c == NULL || c.Last_Customer_Activity_Date__c < c.Last_Case_Update__c)
                       )
                       || 
                       (c.Last_Customer_Activity_Date__c != NULL && Trigger.oldMap.get(c.Id).Last_Customer_Activity_Date__c != c.Last_Customer_Activity_Date__c 
                        && (c.Last_Case_Update__c == NULL || c.Last_Customer_Activity_Date__c > c.Last_Case_Update__c)
                       )
                   )
                  )
                {
                    //System.debug('TRIGGER CALLING FUTURE S2ET');
                    lstS2ETCaseId.add(c.Id);
                }
                // end of changes by Vandhana for S2ET

                // changes by Vikas for Provisioning: ESESP-3663	
                if(rTypesMap.get(c.RecordTypeId).equals('Professional Services') && !c.IsClosed	
                    &&(mapSCUtilMDTVal.get('Plx_Queue_Id').containsIgnoreCase(c.OwnerId) || 	
                    (mapSCUtilMDTVal.get('Plx_Service_Values').split(',').contains(c.Service__c) 
                    && mapSCUtilMDTVal.get('Plx_Products').split(',').contains(c.Case_Prod_Name__c)))	
                    && (Trigger.isInsert || (Trigger.IsUpdate 	
                                            && (c.RecordTypeId != Trigger.oldMap.get(c.Id).RecordTypeId 	
                                            || c.OwnerId != Trigger.oldMap.get(c.Id).OwnerId	
                                            || c.Service__c != Trigger.oldMap.get(c.Id).Service__c	
                                            || c.Case_Product__c != Trigger.oldMap.get(c.Id).Case_Product__c))	
                      )	
                )	
                {	
                    mapPlxCase.put(c.Id,c);	
                }

                //ESESP-2467: Sud-domain Takeover tool
                if(Trigger.isInsert && rTypesMap.get(c.RecordTypeId).equals('Technical') && c.Sub_Type__c == 'Subdomain Takeover')
                {
                    subdomainNotificationCases.add(c.id);
                }
                
                //ESESP-4356: Changes for Jarvis:
                if(rTypesMap.get(c.RecordTypeId) != null &&   
                SC_Jarvis_CoreSecurityController.caseRecordTypesJarvis.contains(rTypesMap.get(c.RecordTypeId))                  
                && !c.Do_Not_Show_In_Portal__c && c.Apply_Jarvis_Logic__c && (Trigger.isInsert ||
                         (Trigger.isUpdate && 
                            (Trigger.oldMap.get(c.Id).RecordTypeId != c.RecordTypeId ||
                            Trigger.oldMap.get(c.Id).Case_Product__c != c.Case_Product__c || 
                            Trigger.oldMap.get(c.Id).OwnerId != c.OwnerId || 
                            Trigger.oldMap.get(c.Id).Policy_Domain__c != c.Policy_Domain__c ||
                            Trigger.oldMap.get(c.Id).AccountId != c.AccountId ||
                            Trigger.oldMap.get(c.Id).Do_Not_Show_In_Portal__c != c.Do_Not_Show_In_Portal__c || 
                            Trigger.oldMap.get(c.Id).Apply_Jarvis_Logic__c != c.Apply_Jarvis_Logic__c ||
                            (
                                (rTypesMap.get(c.RecordTypeId).equals('Professional Services') || c.ATT_RecordType__c == 'Professional Services') 
                                && Trigger.oldMap.get(c.Id).Service__c != c.Service__c
                            ))
                        )
                    )
                )
                {
                    caseShareListJarvis.add(c.Id);
                }
                
                else if(
                    Trigger.isUpdate && 
                    Trigger.oldMap.get(c.Id).Apply_Jarvis_Logic__c &&
                    !c.Apply_Jarvis_Logic__c
                )
                {
                    caseShareListJarvisDeprovision.add(c.Id);
                }
                //ESESP-6150: Business Unit
                if(                    
                    !c.Apply_Jarvis_Logic__c &&
                    (
                        rTypesMap.get(c.RecordTypeId).equals('Professional Services') ||
                        c.ATT_RecordType__c == 'Professional Services'
                    )                 

                && (
                    (Trigger.isInsert && c.Case_Product__c != null) || 
                    (Trigger.isUpdate && 
                        (Trigger.oldMap.get(c.Id).Case_Product__c != c.Case_Product__c || 
                        c.Business_Unit__c == null)
                    )
                    )
                )
                {
                    casesForBusinessUnit.add(c.Id);
                }
                
                //changes by Sharath for ESESP-3659 - Billing Case migration
                if(rTypesMap.get(c.RecordTypeId).equals('Billing') && c.ownerId != null && 
                  (c.owner.Name == 'Billing Queue' || String.valueOf(c.OwnerId).startsWith('005')) 
                   && !SC_CaseTriggerHelperClass3.publishBilling)
                {
                    SC_CaseTriggerHelperClass3.publishBilling = true;
                    //SC_CaseTriggerHelperClass3.publishPlatformEventBilling();
                }

                // changes by Vandhana for ESESP-834 : Octoshape Escalation
                // Below Code commented, JIRA:ESESP-3430, By Bhavesh
                /*if((Trigger.isInsert || (Trigger.isUpdate &&
                                         (Trigger.oldMap.get(c.Id).Severity__c != c.Severity__c
                                          || Trigger.oldMap.get(c.Id).Case_Product__c != c.Case_Product__c
                                         )))
                   && rTypesMap.get(c.RecordTypeId).equals('Technical')
                   && c.Severity__c == '1'
                   && (String.isNotBlank(c.Case_Product__c) && c.Case_Prod_Name__c == 'Octoshape')
                   && (c.Status != 'Rejected' || c.Status != 'Closed' || c.Status != 'Closed - Duplicate')
                   && CheckRecursion.runOnce()
                   && !c.Do_Not_Show_in_Portal__c
                   )
                {
                    if(System.isFuture() || System.isScheduled() || System.isBatch() || Trigger.isUpdate)
                        caseForOctoshape.add(c);
                    else
                        caseForOctoshape_future.add(c.Id);
                }*/

                // changes by Vandhana for ESESP-430 : Close tasks for Close-Invalid AMG ECOB cases
                if(Trigger.isUpdate //&& CheckRecursion.runOnce()
                   && (Trigger.oldMap.get(c.Id).RecordTypeId != c.RecordTypeId
                       && rTypesMap.get(Trigger.oldMap.get(c.Id).RecordTypeId).equals('AMG')
                       && rTypesMap.get(c.RecordTypeId).equals('Invalid Case')
                      )
                   && String.isNotBlank(c.Origin) && c.Origin == 'Autogen'
                   && String.isNotBlank(c.Autogen_UseCase__c)
                   && ((c.Request_Type__c == 'Existing Customer Onboarding' && c.Autogen_UseCase__c == 'ECOB')
                       || (c.Autogen_UseCase__c == 'COB' && c.Request_Type__c == 'Customer Onboarding'))
                   && (Trigger.oldMap.get(c.Id).Status != c.Status && c.Status == 'Closed')
                  )
                {
                    caseAMGCloseInvalid.put(c.Id,c);
                }
            }
            
            // changes by Vandhana for S2ET ESESP-3524
            // ESESP-5678 The same method covers the Task creation for 24PS cases as well.
            if(!mapS2ETCase.isEmpty())
            {
                SC_CaseTriggerHelperClass2.autogenTaskForS2ETCase(mapS2ETCase,mapSCUtilMDTVal);
            }
            
            if(!lstS2ETCaseId.isEmpty() && 
               !(System.isFuture() || System.isScheduled() || System.isBatch()))
            {
                SC_CaseTriggerHelperClass2.setS2ETNoCommCheckbox(lstS2ETCaseId);
            }
            
            // changes by Vikas for Provisioning ESESP-3663	
            if(!mapPlxCase.isEmpty())	
            {	
                SC_CaseTriggerHelperClass2.autogenTaskForPlxCase(mapPlxCase,mapSCUtilMDTVal);	
            }

            if(!subdomainNotificationCases.isEmpty() && 
               !(System.isFuture() || System.isScheduled() || System.isBatch()))
            {
                SC_CaseTriggerHelperClass2.sendSubdomainTakeoverToolNotification(subdomainNotificationCases);
            }
            
            if(caseShareListJarvis.size() > 0 && 
            !(System.isFuture() || System.isScheduled() || System.isBatch()) 
            && !SC_Jarvis_CoreSecurityController.caseTriggerRecursionCheckInsert )
            {
                SC_Jarvis_CoreSecurityController.caseTriggerRecursionCheckInsert = true;

                // SC_Jarvis_CoreSecurityController.caseTriggerRecursionCheckUpdate = Trigger.isUpdate? true : 
                // SC_Jarvis_CoreSecurityController.caseTriggerRecursionCheckUpdate;

                SC_Jarvis_Case_Provision_Queue caseProvisionQueue = new SC_Jarvis_Case_Provision_Queue();
                caseProvisionQueue.caseIds = caseShareListJarvis;
                system.enqueueJob(caseProvisionQueue);
                //SC_Jarvis_CoreSecurityController.calculateAndAssignCaseShare(caseShareListJarvis);
            }


            if(caseShareListJarvisDeprovision.size() > 0 && 
            !(System.isFuture() || System.isScheduled() || System.isBatch()) 
            && (Trigger.isUpdate && !SC_Jarvis_CoreSecurityController.caseTriggerRecursionCheckUpdateDeprovision))
            {
                SC_Jarvis_CoreSecurityController.caseTriggerRecursionCheckUpdateDeprovision = true;

                SC_Jarvis_CoreSecurityController.caseShareListJarvisDeprovision(caseShareListJarvisDeprovision);
            }
            
            //ESESP-6150: Business Unit            
            if(!(System.isFuture() || System.isScheduled() || System.isBatch()) && 
            !SC_CaseTriggerHelperClass3.updateBusinessHours && casesForBusinessUnit.size() > 0)
            {
                SC_CaseTriggerHelperClass3.updateBusinessHours = true;
                SC_CaseTriggerHelperClass3.updateBusinessHoursCases(casesForBusinessUnit);
            }

            //changes by Sharath for ESESP-3659 - Billing Case migration
            if(SC_CaseTriggerHelperClass3.publishBilling && 
               !(System.isFuture() || System.isScheduled() || System.isBatch()))
            {
                SC_CaseTriggerHelperClass3.publishPlatformEventBilling();
            }
            
            if (toUpdateCaseShareList.size()>0)
                CaseTriggerClass.updateCaseShare(Trigger.isInsert,Trigger.isUpdate,toUpdateCaseShareList,Trigger.oldMap);
			
            // Below Code commented for JIRA:ESESP-3430, By Bhavesh
            /*if(!caseForOctoshape.isEmpty())
            {
                CaseTriggerClass.createERForOctoshape(caseForOctoshape);
            }
            else
            if(!caseForOctoshape_future.isEmpty())
                CaseTriggerClass.createERForOctoshape_future(caseForOctoshape_future);*/

            if(!caseAMGCloseInvalid.isEmpty())
            {
                CaseTriggerClass.closeAMGTasks(caseAMGCloseInvalid);
            }

            if(!psNewCase.isEmpty() && !psOldCase.isEmpty())
            {
                SC_CaseTriggerHelperClass2.createCaseHistoryTrackerRec(psOldCase,psNewCase);
            }

        }
        list<String> lCaseIdsForAuthContacts = new list<String>();
        list<String> lCaseIdsForVerivueUpdates = new list<String>();
        list<String> lCaseIdsForCaseCloserMails = new list<String>();

        List<Case> msCaseLst = new List<Case>();

        //Added by Vikas for ESESP-822 : Created 4 maps to store Case-PolicyDomain mapping and Case-CaseProduct mapping
        Map<Id,Id> lCasePolicyDomainIdMap = new Map<Id,Id>();
        Map<Id,String> caseProductMap = new Map<Id,String>();
        Map<Id,Id> lClosedCasePolicyDomainIdMap = new Map<Id,Id>();
        Map<Id,String> closedCaseProductMap = new Map<Id,String>();
        Map<Id,Boolean> additionalEmailMap = new Map<Id,Boolean>();
        Map<Id,Boolean> authConEmailMap = new Map<Id,Boolean>();

        Set<Id> msAttackReportCase = new Set<Id>();

        // changes by Vandhana for ESESP-688 : Ownership of tasks included in a case should always reflect the case owner
        Map<Id,Case> caseECOBAMGChangeOwner = new Map<Id,Case>();
        Id primSecGroupID = [Select Id From Group Where Type = 'Queue'
                             And Name = 'Primary/Secondary Assignment Queue'].Id;

        if(Trigger.isAfter && lCaseForSC.size()>0 && (Trigger.isInsert || Trigger.isUpdate))
        {
            if(lnonPSCaseForSC.size() > 0){
                CaseTriggerClass.changeCaseOwner(lAMGCSATCases, Trigger.isInsert ? null : Trigger.oldMap, Trigger.isInsert, rTypesMap);
            }
                

            // List<Case> sendEmailToAccountTeamCases = new List<Case>();
            List<Case> sendEmailToContactCases = new List<Case>();
            //Map<Id, Schema.RecordTypeInfo> CaseRecordTypeMap = Case.sObjectType.getDescribe().getRecordTypeInfosById();

            /* list<string> lRecordTypeName = SCRecordTypeCustomSetting__c.getValues('AccountTeam').RecordTypeName__c == null ? new list<string>() : SCRecordTypeCustomSetting__c.getValues('AccountTeam').RecordTypeName__c.split('&&');
                Set<String> RTSet = new Set<String>();
                for(String RT : lRecordTypeName)
                {
                RTSet.add(RT);
                }
            */
            for(Case c:Trigger.new)
            {
                /* if(c.AKAM_System__c <> 'MYAKAMAI' && RTSet.contains(CaseRecordTypeMap.get(c.RecordTypeId).getname()))
                {
                sendEmailToAccountTeamCases.add(c);
                }*/
                
                //// ESESP-2872 :Related Cases functionality for AMG Cases ///
                if(Trigger.isInsert)
                {
                    //system.debug('In After Insert');
                    Set<Id> caseIds = new Set<Id>();
                    map<Id,Id> mcaseIds = new map<Id,Id>();
                    for(Case cs: Trigger.new)
                    {
                        //system.debug('cs.RecordType_Name__c newww//'+cs.RecordType_Name__c);
                        if(cs.RecordType_Name__c=='AMG' && cs.Related_Cases_Check__c == true)
                        {
                            mcaseIds.put(cs.ParentId,cs.Id);
                        }
                    }
                    //system.debug('mcaseIds//'+mcaseIds);
                    
                    if(!mcaseIds.isEmpty())
                    {
                        //system.debug('Calling handler//');
                        CaseTriggerClass.createRelatedRecs(mcaseIds);
                    }
                }

                //Added by Vikas for ESESP-822 - On update of "Authorized contacts" or "policy domain" create list/map to send emails.
                if(Trigger.isUpdate && Trigger.isAfter && rTypesMap.get(c.RecordTypeId).equals('Managed Security'))
                {
                    if(c.AuthorizedContacts__c != Trigger.oldMap.get(c.Id).AuthorizedContacts__c
                       && String.isBlank(Trigger.oldMap.get(c.Id).AuthorizedContacts__c))
                    {
                        lCaseIdsForAuthContacts.add(c.Id);
                        additionalEmailMap.put(c.Id, true);
                    }
                    if(c.Policy_Domain__c != Trigger.oldMap.get(c.Id).Policy_Domain__c
                       && String.isBlank(Trigger.oldMap.get(c.Id).Policy_Domain__c))
                    {
                        lCasePolicyDomainIdMap.put(c.Id, c.Policy_Domain__c);
                        caseProductMap.put(c.Id, c.Case_Prod_Name__c);
                        authConEmailMap.put(c.Id, true);
                    }
                }

                //Added by Vikas for ESESP-822 - On Insert of a case, create a list of cases whose "Additional Emails" is not blank. To send emails to the additional emails field.
                //a map of caseid and policydomain and a map of caseid and caseproduct. To send emails to the authorized contacts.
                if(Trigger.isInsert && rTypesMap.get(c.RecordTypeId).equals('Managed Security'))
                {
                    if(!String.isBlank(c.AuthorizedContacts__c))
                    {
                        lCaseIdsForAuthContacts.add(c.Id);
                        additionalEmailMap.put(c.Id, false);
                    }
                    if(c.Policy_Domain__c != null)
                    {
                        lCasePolicyDomainIdMap.put(c.Id, c.Policy_Domain__c);
                        caseProductMap.put(c.Id, c.Case_Prod_Name__c);
                        authConEmailMap.put(c.Id, false);
                    }
                }
                
                if(Trigger.isUpdate && Trigger.isAfter && rTypesMap.get(c.RecordTypeId).equals('Technical') && c.Sub_Type__c == 'Carrier'
                   && c.NextStepsExternal__c != Trigger.oldMap.get(c.Id).NextStepsExternal__c
                   && SC_CaseTriggerHelperClass.verivueRecCheck && !c.Do_Not_Show_in_Portal__c && c.ContactId != null)
                {
                    lCaseIdsForVerivueUpdates.add(c.Id);
                }

                //Changes by Vikas for ESESP-822 - On closure of case, create a list to send emails to the additional emails field.
                //a map of caseid and policydomain and a map of caseid and caseproduct. To send emails to the authorized contacts.
                if(Trigger.isUpdate && Trigger.isAfter && rTypesMap.get(c.RecordTypeId).equals('Managed Security')
                   && c.Status != Trigger.oldMap.get(c.Id).Status
                   && (c.Status == 'Closed' || c.Status == 'Closed - No Customer Response' || c.Status == 'Closed-Auto'))
                {
                    if(!String.isBlank(c.AuthorizedContacts__c))
                    {
                        lCaseIdsForCaseCloserMails.add(c.Id);
                    }
                    if(c.Policy_Domain__c != null)
                    {
                        lClosedCasePolicyDomainIdMap.put(c.Id, c.Policy_Domain__c);
                        closedCaseProductMap.put(c.Id, c.Case_Prod_Name__c);
                    }

                    //Changes by Tejaswini for ESESP-6008 : Call bigpanda to resolve incidents that are associated to case                    
                    if(CheckRecursion.runOnce())
                    {   System.debug('Test inside the CaseTrigger_ai class');
                        SC_CaseTriggerHelperClass.updateBPIncident(c.Id,'Case Close');
                    }
                }

                //Changes by Tejaswini for ESESP-6008 : Call bigpanda to Update incidents tags and add comment whenever case escalates , problem changes from Technician to Specialist
                if(Trigger.isUpdate && Trigger.isAfter && rTypesMap.get(c.RecordTypeId).equals('Managed Security')
                   && (Trigger.oldMap.get(c.Id).Problem__c =='Technicians' && Trigger.newMap.get(c.Id).Problem__c =='Specialist' ) && CheckRecursion.runOnce())
                {
                    SC_CaseTriggerHelperClass.updateBPIncidentTags(c.Id);
                    SC_CaseTriggerHelperClass.updateBPIncident(c.Id,'Case Escalation');
                }

                // changes by Vandhana for Managed Security Living_Summary_Next_Steps__c
                if(((Trigger.isUpdate && c.Living_Summary_Next_Steps__c != Trigger.oldMap.get(c.Id).Living_Summary_Next_Steps__c) || Trigger.isInsert) && rTypesMap.get(c.RecordTypeId).equals('Managed Security') &&
                   String.isNotEmpty(c.Living_Summary_Next_Steps__c) && CheckRecursion.runOnce()
                  )
                {
                    msCaseLst.add(c);
                }

                // changes by Vandhana for Xiphos Email Notifications to Customers ESESP-1891
                if( rTypesMap.get(c.RecordTypeId).equals('Managed Security')
                   && !(c.Status == 'Closed')
                   && Trigger.isAfter
                   && String.isNotBlank(c.Attack_Report_Link__c)
                   && ((Trigger.isUpdate && c.Attack_Report_Link__c != Trigger.oldMap.get(c.Id).Attack_Report_Link__c)
                       || Trigger.isInsert)
                   && CheckRecursion.runOnce())
                {
                    msAttackReportCase.add(c.Id);
                }

                if(Trigger.isUpdate
                   && rTypesMap.get(c.RecordTypeId).equals('AMG')
                   && String.isNotBlank(c.Origin) && c.Origin == 'Autogen'
                   && String.isNotBlank(c.Autogen_UseCase__c)
                   && (c.Autogen_UseCase__c == 'COB' || c.Autogen_UseCase__c == 'ECOB')
                   && (Trigger.oldMap.get(c.Id).OwnerId != c.OwnerId)
                   && c.OwnerId != primSecGroupID
                  )
                {
                    caseECOBAMGChangeOwner.put(c.Id,c);
                }

                if(c.AKAM_System__c <> 'MYAKAMAI' && c.Origin != 'Web' && c.Origin != 'Email' && c.Is_Incoming_NIE__c == false &&
                   (rTypesMap.get(c.RecordTypeId).equals('Technical')
                    || rTypesMap.get(c.RecordTypeId).equals('AMG')
                    || rTypesMap.get(c.RecordTypeId).equals('Billing')
                    || rTypesMap.get(c.RecordTypeId).equals('Stability Engineering')))
                {
                    sendEmailToContactCases.add(c);
                }
            }

            if(lCaseIdsForVerivueUpdates.size()>0 && !(System.isFuture() || System.isScheduled() || System.isBatch())
               && SC_CaseTriggerHelperClass.verivueRecCheck)
            {
                SC_CaseTriggerHelperClass.verivueRecCheck = false;
                // commenting out as part of Carrier LX Migration
                //SC_CaseTriggerHelperClass.sendEmailOnVerivueUpdate(lCaseIdsForVerivueUpdates);
            }

            //Changes by Vikas for ESESP-822: added lCasePolicyDomainIdMap & caseProductMap check and passing lCasePolicyDomainIdMap & caseProductMap as parameters for method
            if((lCaseIdsForAuthContacts.size()>0 || lCasePolicyDomainIdMap.keySet().size()>0 || caseProductMap.keySet().size()>0) && !(System.isFuture() || System.isScheduled() || System.isBatch())
               && !SC_CaseTriggerHelperClass.authContactRecCheck){
                   SC_CaseTriggerHelperClass.authContactRecCheck = true;
                   //Commenting out for ESESP-2746
                   //SC_CaseTriggerHelperClass.sendEmailToAuthorisedContacts(lCaseIdsForAuthContacts, false, lCasePolicyDomainIdMap, caseProductMap, additionalEmailMap, authConEmailMap);//Changed by Vikas for ESESP-822
               }

            //Changes by Vikas for ESESP-822: added lClosedCasePolicyDomainIdMap & closedCaseProductMap check and passing lCasePolicyDomainIdMap & caseProductMap as parameters for method
            if((lCaseIdsForCaseCloserMails.size()>0 || lClosedCasePolicyDomainIdMap.keySet().size()>0 || closedCaseProductMap.keySet().size()>0) && !(System.isFuture() || System.isScheduled() || System.isBatch())
               && !SC_CaseTriggerHelperClass.authContactCloserMailCheck){
                   SC_CaseTriggerHelperClass.authContactCloserMailCheck = true;
                   //Commenting out for ESESP-2006
                   //SC_CaseTriggerHelperClass.sendEmailToAuthorisedContacts(lCaseIdsForCaseCloserMails, true, lClosedCasePolicyDomainIdMap, closedCaseProductMap, null, null);//Changed by Vikas for ESESP-822
                }

            /*if(sendEmailToAccountTeamCases.size() > 0) {
            CaseTriggerClass.sendEmailToAccountTeam(sendEmailToAccountTeamCases, rTypesMap, Trigger.isInsert);
            }*/
            if(sendEmailToContactCases.size() > 0){
                //CaseTriggerClass.sendEmailToContact(sendEmailToContactCases, rTypesMap, Trigger.isInsert);
            }

            if(msCaseLst.size() > 0)
            {
                CaseTriggerClass.livingSummaryCaseFeed(msCaseLst);
            }

            if(!caseECOBAMGChangeOwner.isEmpty() && SC_CaseTriggerHelperClass3.scAMGAssignmentFlag == TRUE)
            {
                CaseTriggerClass.changeCOBTaskOwnerAMG(caseECOBAMGChangeOwner);
                //added flag condition for ESESP-3381, function was called twice and two emails were sent.
                SC_CaseTriggerHelperClass3.scAMGAssignmentFlag = False;
            }

            if(!msAttackReportCase.isEmpty())
            {
                CaseTriggerClass.msAttackReportCaseEmailNotif(msAttackReportCase);
            }
        }
        
        // changes by Vandhana - custom history tracking
        if(Trigger.isUpdate && SC_CaseTriggerHelperClass2.customHistoryTrackerRecCheck)
        {
            SC_CaseTriggerHelperClass2.customHistoryTrackerRecCheck = false;
            SC_CaseTriggerHelperClass2.createCaseHistoryCustomRecords(Trigger.oldMap,Trigger.newMap);
        }

        /***** SOCC RUN BOOK Initial Notification Piece Changes *****/
         //Collect list of Managed security Cases for which the policy domain is updated.
         if(Trigger.isAfter)
         {
             List<String> eligibleCaseIdsInitialNotifyMS = new List<String>();
             if(Trigger.isInsert)
             {
                 for(Case c:Trigger.new)
                 {
                     if((c.Policy_Domain__c!=null ||c.accountid!=null )  && rTypesMap.get(c.RecordTypeId).equals('Managed Security') && c.Do_Not_Show_in_Portal__c == false)
                     {
                         eligibleCaseIdsInitialNotifyMS.add(c.Id);
                     }
                     
                 }
                 
             }
             
             
             if(Trigger.isUpdate)
             {
                 for(Case c:Trigger.new)
                 {
                     if(c.Policy_Domain__c != Trigger.oldMap.get(c.Id).Policy_Domain__c && c.Do_Not_Show_in_Portal__c == false
                        && String.isBlank(Trigger.oldMap.get(c.Id).Policy_Domain__c) && rTypesMap.get(c.RecordTypeId).equals('Managed Security'))
                     {
                         eligibleCaseIdsInitialNotifyMS.add(c.Id);
                     }
                 }
             }
             
             
             //Dispatch Cases for Processing
             if(eligibleCaseIdsInitialNotifyMS.size()>0 && !(System.isFuture() || System.isScheduled() || System.isBatch()) && !SC_CaseTriggerHelperClass.authContactInitialCommunication)
             {
                 SC_CaseTriggerHelperClass.authContactInitialCommunication = true;
                 SC_CaseTriggerHelperClass.initialNotifyMSCases(eligibleCaseIdsInitialNotifyMS,Trigger.isInsert);
             }
         }
        /***** End of SOCC RUN BOOK Initial Notification Piece Changes *****/

        if(Trigger.isAfter && (Trigger.isUpdate||Trigger.isInsert))
        {
            // Changes by Sheena : Commenting the functionality of Impacted Accounts for BMC_objects 
            // CaseTriggerClass.UpdateAccountsProductsonSI(Trigger.New,Trigger.isInsert?null:Trigger.oldMap, Trigger.isInsert);
            // IRAPT : Impacted Accounts and Products functionality
            if(SC_SI_Utility.impAccRecursiveCheck)
                SC_SI_Utility.UpdateImpactedAccountsonSI(Trigger.New,Trigger.isInsert?null:Trigger.oldMap, Trigger.isInsert);
            if(SC_SI_Utility.impProdRecursiveCheck)
                SC_SI_Utility.UpdateCaseProductsonSI(Trigger.New,Trigger.isInsert?null:Trigger.oldMap, Trigger.isInsert);
            // Changes End
            
            //To fetch Akam_Case_Id which gets updated only after workflow field update gets executed, we bypass after insert and execute on first update
            if(Trigger.isInsert)
            {
                SC_CaseTriggerHelperClass.flags=true;
                return;
            }

            // Lists to store Cases for regular and future methods
            List<Case> sendEmailToCaseNotificationSubscription = new List<Case>();
            List<Id> sendEmailToCaseNotificationSubscription_future = new List<Id>();

            Map<Id, Schema.RecordTypeInfo> CaseRecordTypeMap = Case.sObjectType.getDescribe().getRecordTypeInfosById();
            list<string> lRecordTypeName = SCRecordTypeCustomSetting__c.getValues('NotificationTeam').RecordTypeName__c == null ? new list<string>() : SCRecordTypeCustomSetting__c.getValues('NotificationTeam').RecordTypeName__c.split('&&');
            Set<String> rtSet = new Set<String>();
            if(lRecordTypeName.size()>0){
                for(String rt : lRecordTypeName)
                {
                    rtSet.add(rt);
                }

                for(Case c: Trigger.New)
                {
                    //execute if its first update or if its a Record type or account change
                    
                    if(c.AKAM_System__c <> 'MYAKAMAI' && RTSet.contains(CaseRecordTypeMap.get(c.RecordTypeId).getName()) &&
                       (SC_CaseTriggerHelperClass.flags || (!SC_CaseTriggerHelperClass.sentEmailFlag && Trigger.isUpdate && (c.RecordTypeId != Trigger.OldMap.get(c.Id).RecordTypeId || c.AccountId != Trigger.OldMap.get(c.Id).AccountId || c.Severity__c != Trigger.OldMap.get(c.Id).Severity__c || c.Service_Incident__c != Trigger.OldMap.get(c.Id).Service_Incident__c))))
                    {

                        //if the call is from a future method/batch class
                        if(System.isFuture() || System.isScheduled() || System.isBatch())
                            sendEmailToCaseNotificationSubscription.add(c);
                        else
                            sendEmailToCaseNotificationSubscription_future.add(c.Id);
                    }
                }

                if(sendEmailToCaseNotificationSubscription.size()>0)
                {
                    //CaseTriggerClass.sendEmailToCaseNotificationSubscription(sendEmailToCaseNotificationSubscription);
                    SC_CaseTriggerHelperClass2.sendEmailToCaseNotificationSubscription(sendEmailToCaseNotificationSubscription,Trigger.oldMap,SC_CaseTriggerHelperClass.flags );
                }
               
                if(sendEmailToCaseNotificationSubscription_future.size()>0)
                {
                    //CaseTriggerClass.sendEmailToCaseNotificationSubscription_future(sendEmailToCaseNotificationSubscription_future);
                    String serializeOldMap = JSON.serialize(Trigger.oldMap);
                    
                    SC_CaseTriggerHelperClass2.sendEmailToCaseNotificationSubscription_future(sendEmailToCaseNotificationSubscription_future,serializeOldMap,SC_CaseTriggerHelperClass.flags );
                }

                //Setting the flag to false after the notification is sent out on first update
                SC_CaseTriggerHelperClass.flags = false;
                //Setting the flag to false to avoid recursion after the notification is sent out on record type or account change
                SC_CaseTriggerHelperClass.sentEmailFlag = true;
            }
            
            // Changes by Sheena: 5143 - Customer Surveys on Internal AMG Cases
            List<Case> caseList = new  List<Case>();
            for(Case c : Trigger.new){
                if(rTypesMap.get(c.RecordTypeId).equals('AMG')){
                    caseList.add(c);
                }
            }
            if(!caseList.isEmpty() && !SC_CaseTriggerHelperClass.surveyEnableCheck){
                SC_CaseTriggerHelperClass.checkSurveyEnabledAMGCase(caseList, Trigger.isInsert?null:Trigger.oldMap, Trigger.isInsert);
            }
            
        }
        //Kunal: Adding record type Checks
        if(Trigger.isAfter && Trigger.isUpdate && lCaseForSC.size()>0) {
            CaseTriggerClass.addCaseHistory(lCaseForSC, Trigger.oldMap);
        }
        
    }
}