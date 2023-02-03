/*******************************************************************************************************
 Name         :   Engagement_RequestTriggerHandler
 Author       :   Vinod Kumar (Appirio Offshore)
 Created Date :   June 10,2013
 Task         :   T-150208
 Description  :   Handler class for  the Engagement_RequestTrigger
 Last Modified     Developer   Purpose            
 =============     =========   =======
 07-Mar-14         Himanshu      CR#2493858
                                 Added Else condition in "assignTier2TechnicalSupportRequests" method for case product Name 
                             
 15-JUN-14         Kunal         CR# 2530038
                                 Added method to sync Assign To and Owner Field.    
                                                    
 23-07-14          Akhila        Renamed assignTier2TechnicalSupportRequests to assignCCareTechnicalEscalationRequests
                                 Altered assignCCareTechnicalEscalationRequests to Route ERs based on Area
                                 Altered assignCCareTechnicalEscalationRequests to Rename Case Team Roles and Queues
                          
 14-AUG-14         Himanshu      CR# 2703225    
                                 Modified UpdateEngagementRequestOwner method and added condition to fire again when
                                 Assigned To Field = null
26-Sep-14          Akhila        Added afterInsertSeverityUpdate

15-Oct-14          Aditya        CR# 2810658
                                 Commenting Out Owner Sync logic between Engagement Request and Case Object
                                 
                                 CR# 3035271
 02-02-2016        Vamsee        Added method to update Accept Target Date
 03-Mar-16         Sonia         CR# 3068051 
                                 Modified updateEngagementRequesetCases method to bypass case validation rules
                                 
18-Sep-2016     Himanshu       CR#3290361 - Change Routing logic for Mgmt Escalation ER, Optimized the code

25-Nov-2016     Pinkesh         CR#3537361 - added routing logic for new queue CPD_ER_QUEUE,
                                             updated Accept_Target_Date__c logic for Carrier Escalation Record Type
09-Jan-16     Pinkesh Rathore   CR#3528581  - Update CCare queue label prefixes from CC to ATS (Akamai Technical Support)
29-Jan-16       Pinkesh         CR#3612751  - When ER is closed, push Resolution Notes into case
23-FEB-17       Pinkesh         CR#3635371 - added routing logic for new queue ENG_ER_ENTERPRISE_QUEUE,
                                             updated Accept_Target_Date__c logic for Enterprise Engineering Record Type

25-March-17       Vandhana        CR 3526491 - new Engagement Request for BOCC Case

12-April-2018   Vandhana        ESESP-834   Octoshape Escalation

22-May-2018     Vandhana        ESESP-319   OLAs for Escalation / PDG
17-Oct-2018     Vamsee S        ESESP-1650  Renamed ATS_ER_WEBEX_QUEUE --> ATS_ER_WEB_QUEUE
24-Feb-2020     Vandhana   ESESP-2039 - AMG Lightning Migration : New Record type AMG Escalation (similar to External Team)
*******************************************************************************************************/
public without sharing class Engagement_RequestTriggerHandler 
{
    
    // to check if already updated
    public static Boolean alreadyUpdate = false;
    
    // Map to store Case Id + Case Rec
    public static Map<Id,Case> caseId_CaseRecMap; 
    
    // Map to store Case Id + All External Team Escalation ID
    public static Map<Id,string> caseId_allEscalationMap = new Map<Id,string>();
    
    // Map to store QueueName - QueueId
    public static Map<string,Id> Quname_QuId;
    
    // Fetching Record Types for ER Object
    public static Map<Id, Schema.RecordTypeInfo> rtMap;
    
    // Parametrized Constructor for Singleton Pattern
    public Engagement_RequestTriggerHandler(list<Engagement_Request__c> newList)
    {
        // Pattern-1: For getting Case + Account Details
        caseId_CaseRecMap = new Map<Id,Case>();
        getAccountDetailsForER(newList);
        
        // Pattern-2: For getting ER Queue Names
        if(Quname_QuId == null)
        {
            Quname_QuId = new Map<string,Id>();
            
            // Query on Queue Object to get Eng Request Queues
            for(QueueSobject eachQU : [select QueueId,Queue.Name, SobjectType from QueueSobject where 
                                       SobjectType = 'Engagement_Request__c'])
            {
                
                Quname_QuId.put(eachQU.Queue.Name,eachQU.QueueId);
            }
        }
        
        // Pattern-3: For getting ER Record Types
        if(rtMap == null)
        {
            rtMap = Engagement_Request__c.sObjectType.getDescribe().getRecordTypeInfosById();
        }
    }
        
    // function to create case team member when assigned to update
    public static void CreateCaseMemberANdUpdateStatus(list<Engagement_Request__c> newList, map<id,Engagement_Request__c> oldMap, boolean isInsert)
    {
        list<Engagement_Request__c> updatedRequests = new list<Engagement_Request__c>();
        list<Engagement_Request__c> selectedRequests = new list<Engagement_Request__c>();
        list<CaseTeamMember> lstCaseTeamMembers = new list<CaseTeamMember>();
        List<CaseTeamMember> lstCaseTeamMembersUpdates = new List<CaseTeamMember>();
        Map<String, CaseTeamMember> caseTeamMemberMap = new Map<String, CaseTeamMember>();
        set<string> setMemberAlreadyForcaseInserts = new set<string>();
        set<string> setMemberAlreadyForcase = new set<string>();
        set<ID> caseIds = new set<ID>();
        for(Engagement_Request__c newRequest : newList)
        {
            Engagement_Request__c oldRequest = new Engagement_Request__c();
            if(!isInsert)
                oldRequest = oldMap.get(newRequest.ID);
            if((!isInsert && (rtMap.containsKey(newRequest.RecordTypeId) && newRequest.Assigned_To__c != null && newRequest.Assigned_To__c != oldRequest.Assigned_To__c && ((newRequest.IsDeleted && oldRequest.IsDeleted ) || (!newRequest.IsDeleted && !oldRequest.IsDeleted )))) ||
                (isInsert)){
                selectedRequests.add(newRequest);
                caseIds.add(newRequest.Case__c);
            }
        }
        // get allready created caseteammber
        
        for(CaseTeamMember cMember: [Select ParentId, MemberId, TeamRoleId From CaseTeamMember where ParentId in: caseIds])
        {
            if(!isInsert)
            {
                setMemberAlreadyForcase.add( string.valueOf(cMember.ParentId) +'$'+string.valueOf(cMember.MemberId));
                caseTeamMemberMap.put(string.valueOf(cMember.ParentId) +'$'+string.valueOf(cMember.MemberId), cMember);
            }
            else
                setMemberAlreadyForcaseInserts.add( string.valueOf(cMember.ParentId) +'$'+string.valueOf(cMember.MemberId));
        }
        
        // prepare case team roles map (Pitamber)
        Map<String, Id> caseTeamRoleMap = new Map<String, Id>();
        for(CaseTeamRole ct : [Select Name, Id From CaseTeamRole Where Name = 'Engagement' OR Name = 'Stability Eng' OR Name = 'Technical Escalation']) {
            caseTeamRoleMap.put(ct.Name, ct.Id);
        }
        
        CaseTeamMember ctm;
        // create the member and update selected request status
        for(Engagement_Request__c newRequest:selectedRequests)
        {    
            ID extTeamRecTypeId = Schema.SObjectType.Engagement_Request__c.getRecordTypeInfosByName().get('External Team').getRecordTypeId();

            ID amgEscTeamRecTypeId = Schema.SObjectType.Engagement_Request__c.getRecordTypeInfosByName().get('AMG Escalation').getRecordTypeId();

            if(newRequest.RecordTypeId != extTeamRecTypeId && newRequest.RecordTypeId != amgEscTeamRecTypeId)
            {
                // create the case teammember
                string strkey = string.valueOf(newRequest.Case__c) +'$'+ string.valueOf(newRequest.Assigned_To__c);
                
                //To disallow duplicate Team Members on ER inserts
                if(isInsert && setMemberAlreadyForcaseInserts.contains(strkey))
                {
                    newRequest.addError('Error : Duplicate Case Team Member. The member you have selected is already on the team. Please select another one.');
                }
                else if(!setMemberAlreadyForcase.contains(strkey))
                {
                    // case member already not exist
                    CaseTeamMember caseTeamMember = new CaseTeamMember();
                    
                    if(rtMap.get(newRequest.RecordTypeId).getname().equals('CCare Technical Escalation')) {
                        caseTeamMember.TeamRoleId = caseTeamRoleMap.get('Technical Escalation');
                    } 
                    else if(rtMap.get(newRequest.RecordTypeId).getname().equals('Stability Engineering')) {
                        caseTeamMember.TeamRoleId = caseTeamRoleMap.get('Stability Eng');
                    } 
                    else 
                    {
                        caseTeamMember.TeamRoleId = caseTeamRoleMap.get('Engagement');
                    }
                    caseTeamMember.MemberId = newRequest.Assigned_To__c;
                    caseTeamMember.ParentId = newRequest.Case__c;
                    if(newRequest.Assigned_To__c != null)
                        lstCaseTeamMembers.add(caseTeamMember);
                    // add the key in set
                    setMemberAlreadyForcase.add(strkey);
                } 
                else 
                {
                    ctm = caseTeamMemberMap.get(strkey);
                    if(ctm != null) 
                    {
                        if(rtMap.get(newRequest.RecordTypeId).getname().equals('CCare Technical Escalation') && ctm.TeamRoleId != caseTeamRoleMap.get('Technical Escalation')) {
                            ctm.TeamRoleId = caseTeamRoleMap.get('Technical Escalation');
                            lstCaseTeamMembersUpdates.add(ctm);
                        } 
                        else if(rtMap.get(newRequest.RecordTypeId).getname().equals('Stability Engineering') && ctm.TeamRoleId != caseTeamRoleMap.get('Stability Engineering')) {
                            ctm.TeamRoleId = caseTeamRoleMap.get('Stability Eng');
                            lstCaseTeamMembersUpdates.add(ctm);
                        } 
                        else if((rtMap.get(newRequest.RecordTypeId).getname().equals('Stability Engineering') && ctm.TeamRoleId == caseTeamRoleMap.get('Stability Engineering'))||
                                (rtMap.get(newRequest.RecordTypeId).getname().equals('CCare Technical Escalation') && ctm.TeamRoleId == caseTeamRoleMap.get('Technical Escalation')) ) {
                                    
                                }
                        else if(ctm.TeamRoleId != caseTeamRoleMap.get('Engagement')){
                            ctm.TeamRoleId = caseTeamRoleMap.get('Engagement');
                            lstCaseTeamMembersUpdates.add(ctm);
                        }
                    }
                }
                // update Request status
                updatedRequests.add(new Engagement_Request__c(ID=newRequest.ID, Request_Status__c = 'Accepted'));
            }
        }
        if(lstCaseTeamMembers.size() > 0){
            insert lstCaseTeamMembers;
        }
        if(updatedRequests.size() > 0){
            //update updatedRequests;
        }
        if(lstCaseTeamMembersUpdates.size() > 0){
            update lstCaseTeamMembersUpdates;
        }
    }
  

   // Method for Updating EngagementRequest Owner

   // changes by Vandhana : BOCC new ER ()
    public static void UpdateEngagementRequestOwner(boolean isInsert,list<Engagement_Request__c> newList, map<id,Engagement_Request__c> oldMap)
    {
        // Map to store RecordType + Area - QueueName
        Map<string,string> recType_Area_Quname = new Map<string,string>();
        
        // Loop for each value from Custom Setting - Engagement_Request_RecordType_With_Queue__c
        for(Engagement_Request_RecordType_With_Queue__c eachRec : Engagement_Request_RecordType_With_Queue__c.getall().values())
        {    
            recType_Area_Quname.put(eachRec.Record_Type__c,eachRec.Queue_Name__c);
        }
        
        // Stores the Calculated RecordType
        string setRecordTypeName ;
        
        // Get Parent Case Details
        Case parentCaseRec;
        
        // Loop for all Engagement Requests
        for(Engagement_Request__c newRequest: newList)
        {
            // Setting RecordType Name
            setRecordTypeName =rtMap.get(newRequest.RecordTypeId).getname();

            parentCaseRec = caseId_CaseRecMap.get(newRequest.Case__c);
            
            // Change the Owner for Insert Event or Assigned To = Null  
            if(newRequest.RecordTypeId != null && (isInsert || newRequest.Assigned_To__c == null) )
            {
                if(setRecordTypeName == 'CCare Mgmt Escalation')
                {
                    /*if(parentCaseRec != null && parentCaseRec.Account.Support_Level__c != null && 
                        (parentCaseRec.Account.Support_Level__c.contains('Premium_2.0') || 
                        (parentCaseRec.Account.Geography_Formula__c == 'Foundation' && 
                        !parentCaseRec.Account.Support_Level__c.contains('None') )
                        ) 
                    )*/
                    // modified for ESESP-603
                    if(parentCaseRec != NULL && (parentCaseRec.Account.Support_Advocate__c || parentCaseRec.Account.Support_Advocacy_Special_Escalation__c))
                    {
                        newRequest.OwnerId = Quname_QuId.get('ATS_ER_SDM_QUEUE');
                    }
                    else
                    {
                        newRequest.OwnerId = Quname_QuId.get('ATS_ER_MGMT_QUEUE');
                        //newRequest.OwnerId = Quname_QuId.get(recType_Area_Quname.get(setRecordTypeName));
                    }
                }
                else
                if(setRecordTypeName == 'BOCC Stability Engineering')
                {
                    newRequest.OwnerId = Quname_QuId.get('STBE Media Engagement Queue');
                }
                // Below Code commented for JIRA:ESESP-3430, By Bhavesh
                /*else
                if(setRecordTypeName == 'Octoshape Engineering')
                {
                    newRequest.OwnerId = Quname_QuId.get('ENG_ER_OCTOSHAPE_QUEUE');
                }*/
                else
                if(setRecordTypeName == 'External Team')
                {
                    newRequest.OwnerId = Quname_QuId.get('ATS_External_Team_Queue');
                }
                else
                if(setRecordTypeName == 'AMG Escalation')
                {
                    newRequest.OwnerId = UserInfo.getUserId();
                }
                else
                {
                    newRequest.OwnerId = (Quname_QuId.get(recType_Area_Quname.get(setRecordTypeName + ' - ' + 
                                    newRequest.Area__c)) == null) ? Quname_QuId.get('ATS_ER_WEB_QUEUE') :
                                    Quname_QuId.get(recType_Area_Quname.get(setRecordTypeName + ' - ' + 
                                    newRequest.Area__c));
                }   
            }
        }
    }
    
     // Method to fetch Account Details for ER
     public static void getAccountDetailsForER (List<Engagement_Request__c> newERList)
     {       
         // set to store all Case Ids
         set<Id> allCaseIds = new set<Id>(); 
         
         string allExtDepNames;
         
         // Loop for each ER
         for(Engagement_Request__c eachER: newERList)
         {
             
             if(eachER.Case__c != null)
                 allCaseIds.add(eachER.Case__c);
         }
         
         // Query on Case 
         if(allCaseIds.size() > 0)
         {
             for(Case eachCaseRec : [select Id,Account.Support_Level__c,Account.Geography_Formula__c,Severity__c,
                                     Account.Support_Advocate__c,AccountId,Account.Support_Advocacy_Special_Escalation__c,
                                     (select ID__c from External_Dependencies__r),
                                     (Select ID__c from Engagement_Requests__r where RecordType.Name = 'External Team')
                                     from Case where Id IN :allCaseIds])
             {
                 caseId_CaseRecMap.put(eachCaseRec.Id,eachCaseRec);
                 
                 allExtDepNames = ' ';
                 if(eachCaseRec.Engagement_Requests__r != null)
                 {
                     /* Commenting logic to stamp ED IDs on Escalations as they are replaced by External Team
                     for(External_Dependency__c eachExtDep : eachCaseRec.External_Dependencies__r)
                     {
                         if(eachExtDep.ID__c != null)
                             allExtDepNames += eachExtDep.ID__c + ';';    
                     }
                     */
                     for(Engagement_Request__c eachEsc : eachCaseRec.Engagement_Requests__r)
                     {
                         if(eachEsc.ID__c != null)
                             allExtDepNames += eachEsc.ID__c + ';';    
                     }
                     caseId_allEscalationMap.put(eachCaseRec.Id, allExtDepNames);
                 }
             }
         }
     }
     
     // Method for setting External Dependency
     public static void updateExtDependency(List<Engagement_Request__c> newERList)
     {
         // Loop for each ER
         for(Engagement_Request__c eachER: newERList)
         {
             eachER.External_Dependencies__c = caseId_allEscalationMap.get(eachER.Case__c);
         }   
     }
     
    /**
    * Function to be called on After Insert/Update events from Engagement Request Trigger 
    * Added By : Pitamber Sharma (Appirio Offshore)
    */
    public static void onAfterInsertUpdate(List<Engagement_Request__c> newERList, map<id,Engagement_Request__c> oldERMap, Boolean isUpdate) 
    {
        updateEngagementRequesetCases(newERList, oldERMap, isUpdate);
    }
    
    /**
    * Function to mark Engagement Request Cases as Escalated if an Escalation Engagement Request created on any case and change case owner
    * When Any such Engagement Request get assigned to any user.
    * Added By : Pitamber Sharma (Appirio Offshore)
    */
    private static void updateEngagementRequesetCases(List<Engagement_Request__c> newERList, map<id,Engagement_Request__c> oldERMap, Boolean isUpdate) 
    {
        // Variable to store Mgmt Escalation Queue Id
        Id mgmtEscalationQId = Quname_QuId.get('ATS_ER_MGMT_QUEUE');
        
        List<Engagement_Request__c> escalationReqs = new List<Engagement_Request__c>();
        for(Engagement_Request__c e : newERList) 
        {
            if(rtMap.get(e.RecordTypeId).getname() == 'CCare Mgmt Escalation') 
            {
                escalationReqs.add(e);
            }
        }
        List<Case> lstEscalatedCases = new list<Case>();
        Engagement_Request__c oldRequest;
        
        if(isUpdate) 
        {    
            for(Engagement_Request__c newRequest : escalationReqs)
            {
                oldRequest = oldERMap.get(newRequest.Id);
            
                if(newRequest.Request_Status__c != oldRequest.Request_Status__c && newRequest.Request_Status__c == 'Closed'){
                    lstEscalatedCases.add(new Case(Id = newRequest.Case__c, IsEscalated = false,validation_override__C = true));
                }
                if(oldRequest.Request_Status__c == 'Closed' && newRequest.Request_Status__c != 'Closed'){
                    lstEscalatedCases.add(new Case(Id = newRequest.Case__c, IsEscalated = true,validation_override__C = true));
                }
            }
        } 
        else 
        {
            for(Engagement_Request__c newRequest : escalationReqs) 
            {
                System.debug('<<< newRequest.ownerId : ' + newRequest.ownerId);
                if(mgmtEscalationQId != null && newRequest.ownerId == mgmtEscalationQId && newRequest.Request_Status__c != 'Closed') {
                    System.debug('<<< Case added to list : ' + newRequest.Case__c);
                    lstEscalatedCases.add(new Case(Id = newRequest.Case__c, IsEscalated = true,validation_override__C = true));
                }
            }
        }
        
        if(lstEscalatedCases.size() > 0) {
            update lstEscalatedCases;
        }
    }
    
    /*
    Kunal Sharma: Method added to Sync Assign To and Owner Field.
    CR: 2530038
    */
    public static void syncOwnerAndAssignedTo(boolean isInsert, map<Id, Engagement_Request__c> oldMap, 
                                              map<Id, Engagement_Request__c> newMap, list<Engagement_Request__c> lEngagementRequest){
        List<Id> lCaseIds = new List<Id>();
        List<Case> lCaseOwnerToUpdate = new List<Case>();
                                                  
                                                 
        Map<string, string> mCaseIdAndOwnerId = new Map<string,string>();                                          
        if(isInsert)
        {
            for(Engagement_Request__c varEngagementReq :lEngagementRequest)
            {
                if(varEngagementReq.Assigned_To__c != null 
                && rtMap.get(varEngagementReq.RecordTypeId).getname() != 'External Team'
                && rtMap.get(varEngagementReq.RecordTypeId).getname() != 'AMG Escalation'
                )
                {
                    varEngagementReq.OwnerId = varEngagementReq.Assigned_To__c;
                    varEngagementReq.Request_Status__c = 'Accepted';
                    // Changes done by Vamsee 
                    if(varEngagementReq.Accepted_Date__c == null)
                    {
                        varEngagementReq.Accepted_Date__c = System.now();
                    }
                    //Ends here
                    if(rtMap.get(varEngagementReq.RecordTypeId).getname() == 'CCare Mgmt Escalation')
                    {
                        lCaseIds.add(varEngagementReq.Case__c);
                        mCaseIdAndOwnerId.put(varEngagementReq.Case__c, varEngagementReq.Assigned_To__c);
                    }    
                }
                else if(!String.valueOf(varEngagementReq.OwnerId).startsWith('00G') && rtMap.get(varEngagementReq.RecordTypeId).getname() != 'AMG Escalation')
                {
                    varEngagementReq.Assigned_To__c = varEngagementReq.OwnerId;
                    varEngagementReq.Request_Status__c = 'Accepted';
                }
                
                if(rtMap.get(varEngagementReq.RecordTypeId).getName() != 'External Team' && 
                rtMap.get(varEngagementReq.RecordTypeId).getName() != 'AMG Escalation')
                {
                    varEngagementReq.Escalation_Owner__c = varEngagementReq.Assigned_To__c;
                    varEngagementReq.Escalation_Created_By__c = UserInfo.getUserId();
                    varEngagementReq.Escalation_Created_Date__c = System.now();
                }
            }
        }
        else
        {
            for(Engagement_Request__c varEngagementReq :lEngagementRequest)
            {
                if(varEngagementReq.Assigned_To__c != null && 
                   oldMap.get(varEngagementReq.Id).Assigned_To__c != newMap.get(varEngagementReq.Id).Assigned_To__c)
                {
                    varEngagementReq.OwnerId = varEngagementReq.Assigned_To__c;
                    varEngagementReq.Request_Status__c = 'Accepted'; 
                    // Changes done by Vamsee 
                    if(varEngagementReq.Accepted_Date__c == null)
                    {
                        varEngagementReq.Accepted_Date__c = System.now();
                    }
                    //Ends here  
                }
                else if(! String.valueOf(varEngagementReq.OwnerId).startsWith('00G') && 
                        oldMap.get(varEngagementReq.Id).OwnerId != newMap.get(varEngagementReq.Id).OwnerId)
                {
                    varEngagementReq.Assigned_To__c = varEngagementReq.OwnerId ;
                    varEngagementReq.Request_Status__c = 'Accepted';        
                }
                else if(String.valueOf(varEngagementReq.OwnerId).startsWith('00G') && rtMap.get(varEngagementReq.RecordTypeId).getName() != 'External Team')
                {
                    varEngagementReq.Assigned_To__c = null;
                    varEngagementReq.Request_Status__c = 'Unassigned';
                }
                if(rtMap.get(varEngagementReq.RecordTypeId).getName() != 'External Team' &&
                rtMap.get(varEngagementReq.RecordTypeId).getName() != 'AMG Escalation')
                {
                    varEngagementReq.Escalation_Owner__c = String.valueOf(varEngagementReq.OwnerId).startsWith('00G') ? NULL : varEngagementReq.Assigned_To__c;
                    varEngagementReq.Escalation_Created_Date__c = varEngagementReq.AKAM_Created_Date__c;
                }
                
            }
        }                                          
    }
    
    /*
     * This method sync the CaseTeamMember when a Engagement Request Record gets updated
     */
    public static void syncCaseTeamMembers(boolean isUpdate, map<Id,Engagement_Request__c> oldMap,
                                           map<Id, Engagement_Request__c> newMap, list<Engagement_Request__c> lEngagementRequest){
        list<CaseTeamMember> lCaseTeamMemberToRemove = new list<CaseTeamMember>();
        set<Id> sCaseIds = new set<Id>();
        set<Id> sCaseTeamMemberToRemove = new set<Id>();
        map<Id,set<Id>> mCaseAndCaseTeam = new map<Id,set<Id>>();
       
      if(isUpdate){
            for(Engagement_Request__c varEngagementReq :lEngagementRequest){
                if(varEngagementReq.Case__c != null){
                    if(oldMap.get(varEngagementReq.Id).OwnerId != newMap.get(varEngagementReq.Id).OwnerId &&
                       ! String.valueOf(oldMap.get(varEngagementReq.Id).OwnerId).startsWith('00G')){
                        sCaseIds.add(varEngagementReq.Case__c);
                        sCaseTeamMemberToRemove.add(oldMap.get(varEngagementReq.Id).OwnerId);
                        if(!mCaseAndCaseTeam.containsKey(varEngagementReq.Case__c)){
                             mCaseAndCaseTeam.put(varEngagementReq.Case__c, new set<Id>());
                        }
                        mCaseAndCaseTeam.get(varEngagementReq.Case__c).add(oldMap.get(varEngagementReq.Id).OwnerId);
                    } 
                }
            }                                           
        }
        
        if(sCaseIds.size()>0){
           for(CaseTeamMember varCaseTeamMember :[SELECT MemberId,TeamRoleId,ParentId,Id FROM CaseTeamMember WHERE 
                                                  ParentId IN :sCaseIds AND (TeamRole.Name = 'Engagement' OR TeamRole.Name = 'Stability Eng' OR TeamRole.Name = 'Technical Escalation')] ){
               if(mCaseAndCaseTeam.containsKey(varCaseTeamMember.ParentId) &&
                  mCaseAndCaseTeam.get(varCaseTeamMember.ParentId).contains(varCaseTeamMember.MemberId)){
                   lCaseTeamMemberToRemove.add(varCaseTeamMember);
               }                                       
           }
           
            if(lCaseTeamMemberToRemove.size() > 0){
                delete lCaseTeamMemberToRemove;
            } 
        }
      }
    
    // Method for setting ER severity only during Insert Event 
    public static void SeverityUpdate(List<Engagement_Request__c> allIncomingER, boolean isInsert)
    { 
            if(isInsert)
            {
                for(Engagement_Request__c eachER : allIncomingER)
                {
                    if(eachER.ER_Severity__c == null && eachER.RecordType_Name__c != 'External Team')  
                        eachER.ER_Severity__c = (caseId_CaseRecMap.get(eachER.Case__c) != null) ? 
                                             caseId_CaseRecMap.get(eachER.Case__c).Severity__c :
                                             null;
          
                }
    }
      
    }         
    
    // Function to update Accept target date  and accept target minutes
    public static void updateTargetDate(list<Engagement_Request__c> allEngagementRequest)
    {
        // Map to store ER Record Type + Severity - SLA Time 
        Map<string,Integer> ER_RecType_Severity_SLAMap = new Map<string,Integer>();
        
        // Fetching Business Hour
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE Name = 'Service Business Hours - 24x5'];
        
        // 1 Day Milli sec Value - For Business Hour Calculation
        Long milliSecValue;
        
        for(Engagement_Request_SLA_Severity__mdt eachERwithSeverityValue : [SELECT MasterLabel,SLA__c
                                                                            FROM Engagement_Request_SLA_Severity__mdt])
        {
            ER_RecType_Severity_SLAMap.put(eachERwithSeverityValue.MasterLabel,Integer.valueOf(eachERwithSeverityValue.SLA__c));
        }
        
        // changes by Vandhana for Octoshape
        for(Engagement_Request__c varEngagementReq :allEngagementRequest)
        {
            if(rtMap.get(varEngagementReq.RecordTypeId).getname() == 'CCare Technical Escalation' 
               || rtMap.get(varEngagementReq.RecordTypeId).getname() == 'Carrier Escalation' 
               /*|| rtMap.get(varEngagementReq.RecordTypeId).getname() == 'Octoshape Engineering' */
               || rtMap.get(varEngagementReq.RecordTypeId).getname() == 'Enterprise Engineering') 
            {
                varEngagementReq.Accept_Target_Mins__c = ER_RecType_Severity_SLAMap.get(rtMap.get(varEngagementReq.RecordTypeId).getname() + '-' +
                                                                                        varEngagementReq.ER_Severity__c); 
                System.debug(rtMap.get(varEngagementReq.RecordTypeId).getname() + '-' + varEngagementReq.ER_Severity__c);
                System.debug('MINS : ' + varEngagementReq.Accept_Target_Mins__c);
            }
            else 
                if(rtMap.get(varEngagementReq.RecordTypeId).getname() == 'CCare Mgmt Escalation')
            {
                varEngagementReq.Accept_Target_Mins__c = ER_RecType_Severity_SLAMap.get(rtMap.get(varEngagementReq.RecordTypeId).getname());
            }
            
            //update accept target date
            if((rtMap.get(varEngagementReq.RecordTypeId).getname() == 'Carrier Escalation' && varEngagementReq.ER_Severity__c == '3') 
               || (rtMap.get(varEngagementReq.RecordTypeId).getname() == 'Enterprise Engineering' && (varEngagementReq.ER_Severity__c == '2' 
                                                                                                      || varEngagementReq.ER_Severity__c == '3')))
            {
                milliSecValue = (Long)varEngagementReq.Accept_Target_Mins__c*60*1000;
                varEngagementReq.Accept_Target_Date__c = (varEngagementReq.Accept_Target_Mins__c != null)?
                    BusinessHours.add(bh.id, varEngagementReq.AKAM_Created_Date__c, milliSecValue) :
                null;
            }
            else
            {
                varEngagementReq.Accept_Target_Date__c =  (varEngagementReq.Accept_Target_Mins__c != null) ? 
                    varEngagementReq.AKAM_Created_Date__c + varEngagementReq.Accept_Target_Mins__c/1440 :
                null;
            }
        }                 
    }
    
    //CR 3612751 Function to post ER Resolution notes on chatter feed
    public static void PostResolutionNotes(Boolean isUpdate, List<Engagement_Request__c> lNewER, Map<Id, Engagement_Request__c> oldMap)
    {
        if(isUpdate)
        {
            List<FeedItem> lPost = new List<FeedItem>(); 
            for(Engagement_Request__c ER : lNewER)
            {
                if(ER.Request_Status__c  != oldMap.get(ER.Id). Request_Status__c && ER.Request_Status__c == 'Closed')
                {
                    //create and insert post
                    
                    FeedItem post = new FeedItem();
                    post.Body = ER.Name+' closed by '+ER.ER_Owner__c  ;
                    if(ER.ER_Resolution_Notes__c != NULL)
                        post.Body += ' with the following resolution: '+ER.ER_Resolution_Notes__c;
                    post.ParentId = ER.Case__c;
                    post.Title = 'FileName';
                    lPost.add(post);
                }
            }
            insert lPost;
        }
    }
}