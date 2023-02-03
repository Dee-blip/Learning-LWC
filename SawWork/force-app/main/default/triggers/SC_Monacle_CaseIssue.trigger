/*=====================================================================================================+
Trigger name        :   SC_Monacle_CaseIssue 
Author              :   Himanshu
Created             :   24-Jul-13
Purpose             :   Case Trigger for SC Team for all the Events

Last Modified BY        Last Modified Date  Purpose
----------------        ------------------  ---------
Akhila Vidpanapati      24-Jul-13           This trigger is called when a case record is inserted or updated for
                                            Req1# For Monacle Case Issue                            
Himanshu                04-Dec-13           Req2# For AutoGen Case 
Vijetha                 07-Feb-14           Added Before Update handler for CP_Account_Name
Himanshu                02-May-14           Added condition-5 in After Update for Updating Attachments
Aditya Sonam            27-Nov-14           Added Condition to change the record type for Riverbed SAAS OEM Product
Akhila                  06-01-14            CR#2883378 : Changed the DR bypass condition from Primary to Connection User
Aditya                  27-01-15            Added condition for Existing COB to sync owner of case and task
Jay                     28-01-2015          CR#2852373 logic to pupulate new field   
Aditya                  18-02-2015          Removing error condition for Riverbed SAAS OEM Product and handling in Validation rule
Jay                     19-Feb-15           Custom check box for assignment rule (CR 2703000)  
Himanshu                11-Mar-15           Create Engagement Req for Premium Accounts(2871795) 
Akhila Vidapanapati     25-Jun-15           CR#3024056 :Added call for ChangePSCaseOwner 
Jay                     15-July-2015          Transition Requirements: CR 3018620 
Himanshu                14-Sep-2015         CR#2886546 : Automated Process for CashApps Team
Himanshu                12-Nov-2015         3117831/3117841(4.13) - Autogen GDS/MDS Use case for setting Task Owner = Case owner
Deepak                  14-dec-2015         CR#3212261 - CCare Lifecycle Changes
Deepak Saxena           06-Jan-2016         Roll Back for CCare Minor Edit Functionality
Deepak Saxena           07-Jan-2016         CR#3098331 :Removed call for ChangePSCaseOwner
Himanshu                14-Feb-2016         CR#3200701 : Added Override Next Case Update Functionality
Himanshu                16-Apr-16           3239491(16.4) - Added KSD and KONA use case for changing Task Owner
Himanshu                16-May-16           3239521(16.5) - Added KDD use case for changing Task Owner
Himanshu Kar            17-JUN-2016         3333321(16.6) - Create BOCC Entitlement
Himanshu Kar            17-AUG-2016         3183601(16.8) - Service Cloud Compliance
Himanshu Kar            17-SEP-2016         3511921(16.9) - Modified Condition for Riverbed Sas OEM
Vamsee                  17-SEP-2016         3517491(16.9) - Case owner cannot be changed to Transition Queue 

Vandhana Krishnamurthy  10-JAN-2017         3562411(17.2) - Auto-gen Onboarding Case for PSE and TAS
Vandhana Krishnamurthy  15-FEB-2017         3337441(17.2) - Auto-gen Onboarding Case for PLX-Connect
Pinkesh                 27-Apr-2017         JIRA ESESP-542   - Added case transition feature for BOCC
Aditya Sonam            21-Jun-2017         ESESP-534: BOCC Milestone Updates
Vamsee Surya            23-Jun-2017         ESESP-590: Added Autogen Use Case
Aditya Sonam            23-Nov-2017         ESESP-781: Attach Accuracy Check logic
Vamsee                  23-Feb-2018         ESESP-1011: Pause/Resume the SLA Clock for Carrier Product
Vamsee                  21-May-2020         ESESP-3567: Removed BOCC Related Code
Vandhana                23-Feb-2021         ESESP-2346 : Carrier to Tech migration
+=====================================================================================================*/
/*==== Test Classes=====
Test_TaskTriggerHandler
CaseTriggerTestClass
Test_EmailToCaseHandler
SC_Case_Trgr_EmlServc_Class_TC
SC_Case_Trgr_EmlServc_Class_TC2
SC_Billing_Configuration_Test
=========================*/

trigger SC_Monacle_CaseIssue on Case (before insert,after insert,before update,after update,before delete) {

    Environment_Setup__c environmentSetup = Environment_Setup__c.getInstance();

    //map to store all the record types
    map<Id, Schema.RecordTypeInfo> mCaseRecordType = Case.sObjectType.getDescribe().getRecordTypeInfosById();
    map<Id, string> rTypesMap = new map<Id,string>();
    for(string varCaseRecordTypeId :mCaseRecordType.keySet()){
        rTypesMap.put(varCaseRecordTypeId, mCaseRecordType.get(varCaseRecordTypeId).getName());
    }

    //Below code should be excuted twice once befor Assignment Rule execution and once after
    if(!UserInfo.getName().equalsIgnoreCase('Connection User')) {
        
        if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {    
        
            //Akhila - List to store PS cases for routing and their Accounts/Indirect Customer Ids
            //List<Case> lPSCase = new List<Case>();
            //Set<Id> accIds = new Set<Id>(); 
            
            for(Case c: Trigger.new) {
                
                    //PS Cases for routing
                    /*Commented by Vamsee(ESESP_1604) because this functionality is not used any more
                     if(rTypesMap.get(c.RecordTypeId) != null && (rTypesMap.get(c.RecordTypeId).equals('Professional Services')) && (c.AccountId!=null || c.Indirect_Customer__c!=null)) {
                    
                        Id psqueueID = SCUserIdCustomSetting__c.getValues('Primary/SecondaryAssignmentQueue').UserId__c;
                        //Either it should be first Trigger call to update Primary/Secondary flag or it should change the owner
                        if(!CaseTriggerClass.isPrimarySecondaryFlagSet ||
                            (CaseTriggerClass.isPrimarySecondaryFlagSet && !CaseTriggerClass.isAccountTeamMemberLogicExecuted && Trigger.isUpdate && c.OwnerId == psqueueID && Trigger.OldMap.get(c.Id).OwnerId != c.OwnerId)) {    
                        
                            lPSCase.add(c);
                            accIds.add(c.Indirect_Customer__c != null ? c.Indirect_Customer__c : c.AccountId);
                        }
                    }*/
                        
                    /* Changes by Vamsee for ESESP-1011
                     * Pause/Resume when case status is updated
                     */
                // changes by Vandhana for ESESP-2346 : Carrier to Tech migration
                    if(CaseTriggerClass.isOneTimeRun && Trigger.isUpdate && rTypesMap.get(c.RecordTypeId) != null 
                       && rTypesMap.get(c.RecordTypeId).equals('Technical') && c.Sub_Type__c == 'Carrier'
                       && Trigger.OldMap.get(c.Id).Status != c.Status)
                    {
                           //if(c.Status == 'Awaiting Customer Response' && c.IsStopped == False)
                           //if(c.Next_Action__c == 'Customer' && c.IsStopped == false)
                               //c.IsStopped = true;
                           if(c.Status == 'Work in Progress' && c.IsStopped == true)
                               c.IsStopped = false;
                    }
                    // Calculation for Case Status = Mitigated / Solution Provided
                    if(CaseTriggerClass.isOneTimeRun && rTypesMap.get(c.RecordTypeId).equals('Technical'))
                    {
                    
                        //Deepak - CR 3212261...  Total Time where Case Status = Mitigated / Solution Provided
                        if(c.Status == 'Mitigated / Solution Provided' && ( Trigger.isInsert || trigger.oldmap.get(c.Id).Status != 'Mitigated / Solution Provided'))
                        {
                            c.Start_Time__c = System.now();  
                        }
                        else if(Trigger.isUpdate && c.Status != 'Mitigated / Solution Provided' && trigger.oldmap.get(c.Id).Status == 'Mitigated / Solution Provided')
                        {
                            if(c.Start_Time__c != null)
                            {
                                if(c.Total_Time_Minutes__c != null)
                                    c.Total_Time_Minutes__c = c.Total_Time_Minutes__c + (Integer)((System.now().getTime() - c.Start_Time__c.getTime())/1000)/60 ;
                                else
                                    c.Total_Time_Minutes__c = (Integer)((System.now().getTime() - c.Start_Time__c.getTime())/1000)/60;
                            }
                        }
                    }
                    
                    // For Override Next Case Update. By pass the validations if Validation_Override__c = true
                    // Should be run only once.
                    if(CaseTriggerClass.isOneTimeRun && c.Validation_Override__c == false && rTypesMap.get(c.RecordTypeId) != null && 
                        (rTypesMap.get(c.RecordTypeId).equals('Technical')))
                    {   
                        // Scenario-1 : You can not set Override Next Update fields for Milestones other than Case Update
                        if(c.MilestoneFire__c != 'Case Update' && (c.Override_Next_Case_Update__c != null || c.Override_Next_Case_Update_Reason__c != null ) )
                            c.addError('You can not set Override Next Update fields for Milestones other than Case Update');
                            
                        // Scenario-2 : Override Next Case Update != null and Reason for Update = null
                        else if(Trigger.isUpdate && c.Override_Next_Case_Update__c != null && 
                                Trigger.OldMap.get(c.Id).Override_Next_Case_Update__c != c.Override_Next_Case_Update__c && 
                                c.Override_Next_Case_Update_Reason__c == null && Trigger.OldMap.get(c.Id).IsStopped == false)
                            c.addError('Please provide the Reason for Override Next Case Update');
                            
                        // Scenario-3 : Override Next Case Update = null and Reason for Update != null
                        else if(Trigger.isUpdate && c.Override_Next_Case_Update__c == null && 
                                Trigger.OldMap.get(c.Id).Override_Next_Case_Update_Reason__c != c.Override_Next_Case_Update_Reason__c && 
                                c.Override_Next_Case_Update_Reason__c != null && Trigger.OldMap.get(c.Id).IsStopped == false)
                            c.addError('Please provide the Override Next Case Update');
                            
                        // Scenario-4 : Override Next Case Update != null and Reason for Update != null
                        else if(Trigger.isUpdate && c.Override_Next_Case_Update__c != null && c.Override_Next_Case_Update_Reason__c != null 
                                && Trigger.OldMap.get(c.Id).IsStopped == false){
                        
                            // Scenario-5 : Override Next Case Update should not be in future
                            if(Trigger.OldMap.get(c.Id).Override_Next_Case_Update__c != c.Override_Next_Case_Update__c && 
                                c.Override_Next_Case_Update__c > system.now().addDays(7))
                                c.addError('Next Case Update should not be in future more than 7 days');
                            
                            // Scenario-6 : Override Next Case Update should not be in Past
                            if(Trigger.OldMap.get(c.Id).Override_Next_Case_Update__c != c.Override_Next_Case_Update__c && 
                                c.Override_Next_Case_Update__c < system.now())
                                c.addError('Next Case Update should not be in Past'); 
                            
                        }
                        // Scenario-7 : If Milestone is paused and Override_Next_Case_Update__c = blank, then unpause the Milestone
                        else if(Trigger.isUpdate && c.IsStopped == true && 
                                Trigger.OldMap.get(c.Id).Override_Next_Case_Update__c != null && 
                                c.Override_Next_Case_Update__c == null  ){
                                
                                c.IsStopped = false;
                        }
                            
                    }
                    
            }  // End of For Loop
            
            CaseTriggerClass.isOneTimeRun = false;  
            
            //Set Primary/Secondary Available flag based on Account Team memeer availabilty
            // COmmented as part of CR 3098331 in 16.1 Release
            //if(lPSCase.size() > 0 )
            //    CaseTriggerClass.changePSCaseOwner(lPSCase,accIds,Trigger.isInsert ? null : Trigger.oldMap, Trigger.isInsert, rTypesMap);
        }
    }

    // ......... Before Delete...............................
    if(!SC_CaseTriggerHelperClass.flagvalue && !UserInfo.getName().equalsIgnoreCase('Connection User')) {

        // Preventing User to delete Case record except System Admin and CRM Integration user
        if(Trigger.isdelete && Trigger.isBefore) {

            // String to store Profile Id for System Admin and CRM Integration user
            string profileList = '..';

            // Getting Profile Id for System Admin and CRM Integration User
            for (Profile eachProfile : [Select id from Profile where Name In ('CRM Integration','System Administrator')]){
                profileList += eachProfile.Id + ':';
            }

            // Getting Current User Profile
            user userRec = [select Id, ProfileId from User where Id = :UserInfo.getUserId()];

            // Checking Validation
            if(!profileList.Contains(userRec.ProfileId)){
                Trigger.old[0].addError('Error: You do not have permission to Delete Record.');
            }

        }

        // Instantiate The Class
        SC_CaseIssueClass IssueObj = new SC_CaseIssueClass();

        if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate)) {

            // 1. List to filter Case objects containing CP_Account_Name__c
            List<Case> caseList = new List<Case>();

            // 2. Set to store the Unique CP_Account_Name__c strings
            Set<String> cp_acc_names = new Set<String>();

            // 3. List to store new case records
            List<Case> newcaseList = Trigger.new;

            //new List to calculate HAS ARTICLE LINKED and update value
            List<Id> updatingCaseIdList = new List<Id>();

            // Stores Case Id - Owner Id for Changing Task Owner
            Map<Id,Id> CaseId_OwnerIdMap = new Map<Id,Id>();
            String newOwnerId;
            
            // List to store all Cases for Which WorkType is going to be Updated()
            List<Case> caseListForWorkTypeUpdate = new List<Case>();
            
            for(Integer i=0; i<newCaseList.size(); i++) {

                //add all case Ids which are getting updated
                updatingCaseIdList.add(newcaseList[i].id);

                //Scenario 1 & 2 (Null -> Not Null & Not Null -> Not Null)
                if((Trigger.isInsert && newcaseList[i].CP_Account_Name__c != NULL) || (Trigger.isUpdate && ((Trigger.old[i].CP_Account_Name__c == null && newCaseList[i].CP_Account_Name__c != null) || (Trigger.old[i].CP_Account_Name__c != null && newCaseList[i].CP_Account_Name__c != null && Trigger.old[i].CP_Account_Name__c != newCaseList[i].CP_Account_Name__c)))) {
                    caseList.add(newCaseList[i]);
                    cp_acc_names.add(newCaseList[i].CP_Account_Name__c);
                }

            // changes by Vandhana
            // added usecases for PSE, TAS and PLX-Connect
            // For Scenario-3
                newOwnerId = newCaseList[i].OwnerId;
            if(Trigger.IsUpdate && Trigger.Old[i].OwnerId != newCaseList[i].OwnerId && newOwnerId.startsWith('005') 
                    && newCaseList[i].Autogen_UseCase__c <> null && 
                    (newCaseList[i].Autogen_UseCase__c.contains('SMP-NonSecurity') || newCaseList[i].Autogen_UseCase__c.contains('GDS') || 
                        newCaseList[i].Autogen_UseCase__c.contains('MDS') || newCaseList[i].Autogen_UseCase__c == 'KSD-COB' || 
                        newCaseList[i].Autogen_UseCase__c == 'KONA-COB-WithKSD' || newCaseList[i].Autogen_UseCase__c == 'KONA-COB-WithoutKSD' || 
                        newCaseList[i].Autogen_UseCase__c == 'KDD' || newCaseList[i].Autogen_UseCase__c.contains('SOA') || newCaseList[i].Autogen_UseCase__c.contains('PSE-COB')|| newCaseList[i].Autogen_UseCase__c.contains('TAS-COB') || 
                        newCaseList[i].Autogen_UseCase__c.contains('PLXC-COB') || newCaseList[i].Autogen_UseCase__c.contains('PLXR-COB') || newCaseList[i].Autogen_UseCase__c.contains('RRS') || newCaseList[i].Autogen_UseCase__c.contains('PSS-COB')|| newCaseList[i].Autogen_UseCase__c.contains('PPSOPSM')|| newCaseList[i].Autogen_UseCase__c.contains('PPPPSC')|| newCaseList[i].Autogen_UseCase__c.contains('PPPPMK')|| newCaseList[i].Autogen_UseCase__c.contains('PPMKPSM')
                    )
                    ){
                   
                    CaseId_OwnerIdMap.put(newCaseList[i].Id, newCaseList[i].OwnerId); 
                }
                
                // For Scenario-4(For Technical and AMG Recordtype)
                if(newCaseList[i].RecordTypeId != null && (rTypesMap.get(newCaseList[i].RecordTypeId).equals('Technical') || 
                                            rTypesMap.get(newCaseList[i].RecordTypeId).equals('AMG')) &&
                    newCaseList[i].Work_Type__c == null 
                ){
                
                    caseListForWorkTypeUpdate.add(newCaseList[i]);
                }
                
            }
               
                //call to assignAccount
                if(caseList.size() > 0) {
                    IssueObj.assignAccount(caseList, cp_acc_names);
                }
                
                // For Scenario-3
                if(CaseId_OwnerIdMap.size() > 0){
                    IssueObj.changeTaskOwner_Case(CaseId_OwnerIdMap);
                    CaseId_OwnerIdMap.clear();
                }
                
                // For Scenario-4
                if(caseListForWorkTypeUpdate.size() > 0){
                    IssueObj.updateWorkType(caseListForWorkTypeUpdate,rTypesMap,Trigger.isInsert);
                    caseListForWorkTypeUpdate.clear();
                }

            //Added by Jay for 4.4 release, Jan 28 2014
            //case will never be attached on before insert. so get only before update actions
            if(trigger.isUpdate && trigger.isBefore){
            
            IssueObj.calculateNextActionDetails(Trigger.New,Trigger.OldMap);
               IssueObj.updateRecentUpdateFlag_SOCC(Trigger.New,rTypesMap);

                if (updatingCaseIdList.size() > 0){

                    /* it is very necessary to always check for all records. initially case might be attached with article.
                    later it might be detachded. so always try to get latest data whenever data update happens
                    */
                    
                    Set<Id> casesWithArticlesSet = new Set<Id>();
                    List<id> caseTransitionList = new List<id>();
                    Map<String, Id> mRecordTypeTransitionQueueId = new Map<String, Id>();
                    for(SC_Case_Transition_RecordType_Map__mdt ct: [Select Case_RecordType__c , Queue_Id__c from SC_Case_Transition_RecordType_Map__mdt])
                        mRecordTypeTransitionQueueId.put(ct.Case_RecordType__c, ct.Queue_Id__c);
                     id transitionQueueId = null;

                    //ESESP-781 : Attach Accuracy Check Logic
                    //Added KnowledgeArticleId in query to handle Attach Accuracy Check Logic
                    List<CaseArticle> caseArticleList = [select id,caseId,KnowledgeArticleId from CaseArticle where caseId in :updatingCaseIdList ];
                    
                    //List to store knowlege article id for fetching Article Number(Article Number can't be queried directly)
                    List<Id> kaId = new List<Id>();
                    for(caseArticle eachKAId :caseArticleList){
                        kaId.add(eachKAId.KnowledgeArticleId);  
                    }
                    
                    //Map to store KA Id and Knowledge Article
                    Map<Id,String> mapKAIdandArticleNumber;
                    if(kaId.size()>0){
                        mapKAIdandArticleNumber = new Map<Id,String>();
                        for(Knowledge__kav eachKav : [Select KnowledgeArticleId,AKAM_Article_Number__c from Knowledge__kav where PublishStatus = 'Online' and Language = 'en_US' and KnowledgeArticleId IN :kaId]){
                            mapKAIdandArticleNumber.put(eachKav.KnowledgeArticleId, eachKav.AKAM_Article_Number__c);
                        }
                        for(Knowledge__kav eachKav : [Select KnowledgeArticleId,AKAM_Article_Number__c from Knowledge__kav where PublishStatus = 'Archived' and Language = 'en_US' and KnowledgeArticleId IN :kaId]){
                            mapKAIdandArticleNumber.put(eachKav.KnowledgeArticleId, eachKav.AKAM_Article_Number__c);
                        }
                        system.debug('---mapKAIdandArticleNumber---'+mapKAIdandArticleNumber);
                    }
   
                    //Map to store KA ID and Article Number,used to populate Article_Number_s__c on Technical Case
                    Map<Id,String> caseArticleMap = new Map<Id,String>();
                    
                    //Stores all artcile number for each case
                    String allArticles;
                    
                    //dont worry about duplicates
                    for(caseArticle p: caseArticleList){
                        casesWithArticlesSet.add(p.caseId);
                        
                        //Logic for creating a map of Case Id and Article Number
                        if(caseArticleMap.get(p.caseId) == Null){
                            caseArticleMap.put(p.caseId,'');
                        }
                        if(!mapKAIdandArticleNumber.isEmpty() && caseArticleMap.containsKey(p.caseId) ){
                            if(caseArticleMap.get(p.caseId) != null && mapKAIdandArticleNumber.get(p.KnowledgeArticleId) != null)
                                allArticles = caseArticleMap.get(p.caseId)+','+mapKAIdandArticleNumber.get(p.KnowledgeArticleId);
                            else if(mapKAIdandArticleNumber.get(p.KnowledgeArticleId) != null)
                                allArticles = mapKAIdandArticleNumber.get(p.KnowledgeArticleId);
                            
                            if(allArticles != null)
                                allArticles = allArticles.removeStart(',');
                            caseArticleMap.put(p.caseId,allArticles);
                        }       
                    }

                    //now loop through all updating articles and set it value
                    set<String> allUniqueArticle;
                    
                    for(case cas:trigger.new){
                        //check if case Id is in article List. set to true
                        system.debug('---caseArticleMap---'+caseArticleMap);
                        if (casesWithArticlesSet.contains(cas.id)){
                            cas.has_article_linked__c = true;
                            if(caseArticleMap.containsKey(cas.id)){
                                cas.Article_Number_s__c = caseArticleMap.get(cas.Id);
                                system.debug('---caseArticleMap.get(cas.Id);---'+caseArticleMap.get(cas.Id));
                                /*allUniqueArticle = new set<String>();
                                string articleString = cas.Article_Number_s__c != Null ? cas.Article_Number_s__c + ','+caseArticleMap.get(cas.id) : caseArticleMap.get(cas.id);// ESESP-781: Adding artcile number on Case
                                list <string> allArticle = articleString != Null ? articleString.split(',') : new list<string>{};
                                allUniqueArticle.addAll(allArticle);
                                if(allUniqueArticle.size()>0){
                                    string allArticleString = '';
                                    for(string eachArticle :allUniqueArticle){
                                        allArticleString += eachArticle+',';    
                                    }
                                    allArticleString = allArticleString.removeEnd(',');
                                    cas.Article_Number_s__c = caseArticleMap.get(cas.Id);
                                }*/
                            }
                        }
                        else {
                            cas.has_article_linked__c = false;
                        }
                        
                        /* below logic will update transition.
                        Case might be in transition. When case owner changes , transition flag needs
                        to be updated. */
                        
                        case oldCaseRecord = trigger.oldmap.get(cas.id);
                        transitionQueueId = mRecordTypeTransitionQueueId.get(cas.RecordType_Name__c);
                         //change of owner
                        if (oldCaseRecord.OwnerId != cas.ownerId){ 
                             /*if previous owner is CC TRANSITION QUEUE and new owner is user and not queue
                             if case has transition and new owner is user and not queue 
                            */
                             if(oldCaseRecord.has_active_transition__c && cas.OwnerId != null &&  String.valueof(cas.ownerId).substring(0,3) == '005'){
                                  caseTransitionList.add(cas.id);
                                  cas.Case_In_Transition_Queue__c = false;
                             }
                             if (oldCaseRecord.OwnerId == transitionQueueId && cas.OwnerId != null && String.valueof(cas.ownerId).substring(0,3) == '005'){
                                  caseTransitionList.add(cas.id); 
                                  cas.Case_In_Transition_Queue__c = false;                       
                             }
                             if (cas.OwnerId == transitionQueueId ){
                                  cas.has_active_transition__c = false;                      
                             }
                             /*if previous owner is transition queue and new owner is also transition queue then active
                             transition flag should be set */
                             if (oldCaseRecord.OwnerId == transitionQueueId && cas.OwnerId != null && String.valueof(cas.ownerId).substring(0,3) != '005'){
                                  cas.has_active_transition__c = true;
                                  cas.Case_In_Transition_Queue__c = false;                        
                             }
                         }    
                    }
                    if(caseTransitionList != null && caseTransitionList.size() > 0){
                     /* pull only those transitions which are approved , but not completed.
                      */
              
                         List<Case_transition__c> caseTransitionUpDateList = [SELECT id,
                                                                                Completed__c,
                                                                                Case__c,
                                                                                RecordType.Name
                                                                       FROM case_transition__c
                                                                       where completed__c = false
                                                                       AND approved_by__c != null
                                                                       AND case__c in :caseTransitionList];
                         
                         /* initial thought was to set JUST completed flag and calculate rest
                          * of parameters in CASE TRANSITION trigger.  But case transition is child of
                          * Case. when we update case , transition triggers also fire and vice versa.
                          * Triggers refiring was screwing calculatons. So did all calculations here
                          */ 
                         for(case_transition__c transitionRecord:caseTransitionUpDateList){
                             transitionRecord.completed__c = true;
                             transitionRecord.Next_Shift_Assignment__c = SC_Utility.getCurrentShiftDetails(transitionRecord.RecordType.Name);
                             
                             transitionRecord.New_Owner__c = trigger.newmap.get(transitionRecord.case__c).ownerId;
                             transitionRecord.Completed_Date__c = system.now();
                             //flip flag back to false. transition is taken over
                             
                             trigger.newmap.get(transitionRecord.case__c).has_active_transition__c = false;
                         }
                         update caseTransitionUpDateList;
                     }


                }
            }  
        }       

        //........For After Insert ...............
        if(Trigger.isInsert && Trigger.isAfter) {
            //(Scenario -1)List of Cases for which Assignment Rule will fire
            List<case> caseListToFireAssignments = new List<Case>();

            //(Scenario -2)Create map to store caseid and issue value
            Map<Id,String> caseid_issuemap = new Map<Id,String>();

            //Create map to store caseid and issue value
            Map<Id,Case> caseIdRecMap = new Map<Id,Case>();

            //(Scenario -3)Store Case ID for case created for Riverbed SAAS OEM Product
            Set<Id> Caselist = new Set<Id>();

            //(Scenario -4)Store List of Case ID for Which ER record will be created
            Set<Id> CaselistForER = new Set<Id>();

            // Fetching Case Record Type Id for Technical
            Id getTechRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();

            //Loop for each case record
            for(Case ocase: Trigger.new) {
                /* added by jay for POC for active assignment checkbox.SFDC standard checkbox for assignment firing is at bottom.
                users were finding hard to notice. hence added custom checkbox.if user selects checkbox,we need to fire assignment rule.
                reference CR 2703000 */

                //...Scenario -1 
                if(ocase.Case_Assignment_Using_Active_Rules__c)
                {
                    
                    Database.DMLOptions dmo = new Database.DMLOptions();
                    dmo.assignmentRuleHeader.useDefaultRule= true;
                    dmo.EmailHeader.TriggerUserEmail = true;

                    case newCasetoFireDml = ocase.clone(true,true,true);
                    newCasetoFireDml.setOptions(dmo);
                    newCasetoFireDml.Case_Assignment_Using_Active_Rules__c = false;
                    caseListToFireAssignments.add(newCasetoFireDml);
                }

                //...Scenario -2
                if(ocase.Issue__c != NULL) {
                    caseid_issuemap.put(ocase.id,ocase.Issue__c);
                    caseIdRecMap.put(ocase.id,ocase);
                }

                //...Scenario -3 If Record Type is Technical and Case Product = Riverbed SAAS OEM 
                if((SC_RiverbedCaseProdID__c.getValues('Riverbed_SAAS_OEM').RecordTypeID__c).contains(ocase.RecordTypeID) && 
                ocase.Case_Product__c <> null && 
                ((SC_RiverbedCaseProdID__c.getValues('Riverbed_SAAS_OEM').Case_Product_ID__c).contains(ocase.Case_Product__c) )){

                    Caselist.add(ocase.Id);
                }

                //...Scenario -4 Condition for checking if it meets ER creation criteria
                if(ocase.Severity__c == '1' && ocase.Sub_Type__c == 'Product Support' && ocase.Work_Type__c <> 'Proactive' && ocase.RecordTypeID == getTechRecordTypeId){

                    CaselistForER.add(ocase.Id);
                }
            }

            // (For Scenario - 1)
            if (caseListToFireAssignments.size() > 0 )
            {
                Database.update(caseListToFireAssignments);   
            }

            // (For Scenario - 2)call for insert method
            if(caseid_issuemap.size() > 0)
                IssueObj.insertcall(caseid_issuemap);  

            //call for task insert method
            if(caseIdRecMap.size() > 0)
                IssueObj.taskinsert(caseIdRecMap);  

            SC_CaseTriggerHelperClass.flagvalue = True;

            // (For Scenario - 3)  
            if( Caselist.size() > 0){

                // Riverbed SAAS OEM: Calling class and passing CasesID as parameter  
                SC_CaseIssueClass.ChangeRecordType(Caselist); 
            }

            // For Scenario- 4
            if(CaselistForER.size() > 0){

                // Calling createERForPrmAccounts Method
                SC_CaseIssueClass.createERForPrmAccounts(CaselistForER);
            }

        } 

    
        if(Trigger.isUpdate && Trigger.isAfter) {
            
            //List to store old and new case records
            List<Case> oldcaselist = Trigger.old;
            List<Case> newcaseList = Trigger.new;

            // Map to store CaseId-IssueNum (For Scenario-1)
            Map<Id,String> Issue_CaseIdmap = new Map<Id,string>();

            // List to store Old Case Id - Issue Id (For Scenario-2)
            List<string> oldCaseList2 = new List<string> ();
            String caseid2;

            // (For Scenario-3)
            Map<Id,string> Issue_CaseIdmap3 = new Map<Id,String>();
            List<string> oldCaseList3 = new List<string> ();
            String caseid3;

            // (For Scenario-4)
            Map<Id,Id> CaseId_OwnerIdMap4 = new Map<Id,Id>();
            string newOwnerId;
            /*RecordType AMGRecType = [select Id from RecordType where name = 'AMG'
            and SobjectType = 'Case' 
            and IsActive = True limit 1]; */
            Id AMGRecTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId();

            // (For Scenario-5 -- Updating Attachments for Do not show in Portal = Unchecked)
            set<Id> caseIdForAttachmntUpdate = new set<Id>();

            // (For Scenario-6) -- Stores Riverbed Case ID
            Set<Id> caseID = new Set<Id>();

            // (For Scenario-7) 
            LIst<Case> caseListToFireAssignmentRule = new List<Case>();

            //(For Scenario-8) -- Store List of Case ID for Which ER record will be created
            Set<Id> CaselistForER = new Set<Id>();
            
            // (For Scenario-9) -- To Store Case Id when Case Owner = CashApps Team
            Set<Id> CaselistForCashApps = new Set<Id>();
            
            
            // Fetching Case Record Type Id for Technical
            Id getTechRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();

            // Loop for each Case    
            for(Integer i=0; i < newCaseList.size(); i++){

                // Scenario -1 (Null -> Not Null)
                if(oldCaseList[i].Issue__c == Null && newCaseList[i].Issue__c != null)
                    Issue_CaseIdmap.put(newCaseList[i].Id, newCaseList[i].Issue__c);

                // Scenario -2 (Not Null -> Null)
                if(oldCaseList[i].Issue__c != Null && newCaseList[i].Issue__c == null)
                {
                    caseid2 = oldCaseList[i].Id;
                    oldCaseList2.add(caseid2 + '-' + oldCaseList[i].Issue__c);
                }

                // Scenario -3 (Not Null -> Not Null)

                if(oldCaseList[i].Issue__c != Null && newCaseList[i].Issue__c != null && oldCaseList[i].Issue__c != newCaseList[i].Issue__c){

                    caseid3 = oldCaseList[i].Id;
                    Issue_CaseIdmap3.put(newCaseList[i].Id, newCaseList[i].Issue__c);
                    oldCaseList3.add(caseid3 + '-' + oldCaseList[i].Issue__c);
                }

                // Scenario-4 (For Change of Case Owner from Queue to User for AutoGen Cases)
                newOwnerId = newCaseList[i].OwnerId;
                if(newCaseList[i].Origin == 'Autogen' && (oldCaseList[i].OwnerId != newCaseList[i].OwnerId) && newCaseList[i].Request_Type__c != Null &&
                (newOwnerId.startsWith('005')) &&  (newCaseList[i].Request_Type__c == 'Customer Onboarding' || (newCaseList[i].Request_Type__c == 'Existing Customer Onboarding')) &&
                newCaseList[i].RecordTypeId == AMGRecTypeId && (newCaseList[i].AKAM_Created_By__c == 'CRMOPS') &&
                newCaseList[i].Service__c == 'Accounts Audits'){

                    CaseId_OwnerIdMap4.put(newCaseList[i].Id, newCaseList[i].OwnerId);
                }

                // Scenario-5 (Updating Attachments for Do not show in Portal = Unchecked)
                if(oldCaseList[i].Do_Not_Show_in_Portal__c != newCaseList[i].Do_Not_Show_in_Portal__c &&
                newCaseList[i].Do_Not_Show_in_Portal__c == False){

                    caseIdForAttachmntUpdate.add(newCaseList[i].Id);
                }

                //Scenario-6 Riverbed SAAS OEM: checks if the old record type was technical and new product is Riverbed SAAS OEM
                // If Case Product is changed and status Should not be Closed

                if((SC_RiverbedCaseProdID__c.getValues('Riverbed_SAAS_OEM').RecordTypeID__c).contains(oldCaseList[i].RecordTypeID) && 
                newCaseList[i].Case_Product__c <> null && 
                newCaseList[i].Case_Product__c != oldCaseList[i].Case_Product__c &&
                !(newCaseList[i].Status.contains('Close')) && 
                ((SC_RiverbedCaseProdID__c.getValues('Riverbed_SAAS_OEM').Case_Product_ID__c).contains(newCaseList[i].Case_Product__c) )){

                    caseID.add(newCaseList[i].id);
                }

                /* added by jay for POC for active assignment checkbox.SFDC standard checkbox for assignment firing is at bottom.
                users were finding hard to notice. hence added custom checkbox.if user selects checkbox,we need to fire assignment rule.
                reference CR 2703000 */

                //Scenario-7 if old value of assignment is unchecked and new value is checked
                //indicates user wants to fire assignment
                if(newCaseList[i].Case_Assignment_Using_Active_Rules__c && oldCaseList[i].Case_Assignment_Using_Active_Rules__c != newCaseList[i].Case_Assignment_Using_Active_Rules__c){

                    case caseupdateToFireAssignment = newCaseList[i].clone(true,true,true);
                    Database.DMLOptions dmo = new Database.DMLOptions();
                    dmo.assignmentRuleHeader.useDefaultRule= true;
                    dmo.EmailHeader.TriggerUserEmail = true;

                    caseupdateToFireAssignment.setOptions(dmo);
                    caseupdateToFireAssignment.Case_Assignment_Using_Active_Rules__c = false;
                    caseListToFireAssignmentRule.add(caseupdateToFireAssignment);
                }

                //...Scenario -8 Condition for checking if it meets ER creation criteria(Req Criteria + Severity Change / Account Change || it is an enterprise case product)
                if(newCaseList[i].Severity__c == '1' && newCaseList[i].Sub_Type__c == 'Product Support' && newCaseList[i].Work_Type__c <> 'Proactive' && 
                newCaseList[i].RecordTypeID == getTechRecordTypeId && 
                (oldCaseList[i].Severity__c != newCaseList[i].Severity__c || oldCaseList[i].AccountId != newCaseList[i].AccountId)){

                    CaselistForER.add(newCaseList[i].Id);
                }
                
                // Scenario-9
                if(newCaseList[i].OwnerId <> oldCaseList[i].OwnerId && newCaseList[i].OwnerId == SCUserIdCustomSetting__c.getValues('Cash Apps').UserId__c){
                    
                    CaselistForCashApps.add(newCaseList[i].Id);
                    
                }
                
            } 

            // For Scenario-1
            if(Issue_CaseIdmap.size() > 0){
                IssueObj.insertcall(Issue_CaseIdmap);
                Issue_CaseIdmap.clear();
            }

            // For Scenario-2
            if(oldCaseList2.size() > 0){
                IssueObj.deletecall(oldcaselist2);
                oldCaseList2.clear();
            }

            // For Scenario-3
            if(oldCaseList3.size() > 0){
                IssueObj.deletecall(oldcaselist3);
                IssueObj.insertcall(Issue_CaseIdmap3);
                oldcaselist3.clear();
                Issue_CaseIdmap3.clear();
            }

            // For Scenario-4
            if(CaseId_OwnerIdMap4.size() > 0){
                IssueObj.changeTaskOwner_Case(CaseId_OwnerIdMap4);
                CaseId_OwnerIdMap4.clear();
            }

            // For Scenario-5
            if(caseIdForAttachmntUpdate.size() > 0){
                IssueObj.updateAttachment(caseIdForAttachmntUpdate);
                caseIdForAttachmntUpdate.clear();
            }

            // For Scenario-6 : Riverbed SAAS OEM: Calling class and passing CasesID as parameter 
            if(caseID.size() > 0){
                SC_CaseIssueClass.ChangeRecordType(CaseId);
            }

            SC_CaseTriggerHelperClass.flagvalue = True;

            // For Scenario-7 : 
            if(caseListToFireAssignmentRule.size() > 0){
                Database.update(caseListToFireAssignmentRule);
            }

            // For Scenario-8 : 
            if(CaselistForER.size() > 0){

                // Calling createERForPrmAccounts Method
                    SC_CaseIssueClass.createERForPrmAccounts(CaselistForER);
            }
            
            // For Scenario-9 : 
            if(CaselistForCashApps.size() > 0){

                SC_Billing_CashApps.SendEmailToCashAppsTeam(CaselistForCashApps);
            }
             
            
        }  
    }
}