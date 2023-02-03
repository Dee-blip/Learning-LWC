/*
Author          : Vandhana Krishnamurthy
Description     : CaseTrigger_ai helper class #3
TestClass       : SC_CaseTriggerHelperClass3Test, SC_RCA_AllUseCase_TC

Date                        Developer             JIRA #                      Description                                                       
----------------------------------------------------------------------------------------------------------------------------
22 June 2020                Vandhana             ESESP-2597         New "instant Engagement Request" flag for Sev 1 cases for support advocacy services
4 Aug 2020           		Sharath     		 ESESP-2467         Adding method to publish a platform notification
26 Nov 2020					Sumukh SS			 ESESP-2235			Akatec Enhanced Milestones
8 March 2021                Vandhana             ESESP-2346         Carrier LX Migration
20 Oct 2021                 Sharath              ESESP-6150         Update Business Unit on PS cases
29 Nov 2021                 Vishnu Sharma        ESESP-5772         Logic for OCID field edit restriction
04 Mar 2022                 Sharath              ESESP-6829         Adding validation override on case update
21 Apr 2022					Sheena				 ESESP-5433			Removed restriction for only Tech/AMG Parent Case for RCA Cases
9  May 2022					Vandhana			 ESESP-7167			Clear SC IP Scrubbed checkbox on cloned accounts
-----------------------------------------------------------------------------------------------------------------------------

*/ 

public class SC_CaseTriggerHelperClass3 
{
	//RCA:flag to stop recursion.
    public static boolean rcaRecursiveCheckEdit = false;
    public static boolean rcaRecursiveNonIraptCheck = false;
    public static boolean rcaErrorInCase = false;
    public static boolean rcaTransitionFlag = false;
    public static Boolean scAMGAssignmentFlag = true;
    
    
    // changes by Vandhana for ESESP-2597
    public static void createSpecialAdvocacyER(Map<Id,Case> mapIdCase, Set<Id> setAccId, Boolean isInsert, Boolean techCaseSevUpdatedTo1)
    {
        List<Case> lstCaseforERCreation = new List<Case>();
        DateTime triggerERDate;
        
        Map<String,Integer> mapEscalationAgingTime = new Map<String,Integer>();
        Map<String,Boolean> mapWeekendEscalation = new Map<String,Boolean>();
        Map<Id,Account> mapIdAccount = new Map<Id,Account>();
        
        
        for(Technical_Escalation_Config_Interface__c eachTECI :[SELECT Severity__c,Time_Hours__c,Include_Weekend__c 
                                                                FROM Technical_Escalation_Config_Interface__c
                                                                WHERE Support_Level__c = 'supportAdvocacySpecialEscalation'
                                                                AND Severity__c != null AND Time_Hours__c != null
                                                                ORDER BY CreatedDate
                                                               ])
        {
            //if(String.isNotBlank(String.valueOf(eachTECI.Time_Hours__c)))
            //{    
            mapEscalationAgingTime.put(eachTECI.Severity__c.toPlainString(),eachTECI.Time_Hours__c.intValue());
            //}
            mapWeekendEscalation.put(eachTECI.Severity__c.toPlainString(),eachTECI.Include_Weekend__c);
        }
        
        mapIdAccount = new Map<Id,Account>([SELECT Id,Support_Advocacy_Special_Escalation__c FROM Account WHERE Id IN :setAccId]);
        System.debug(mapIdAccount);
        for(Case eachCase : mapIdCase.values())
        {
            if(((isInsert && eachCase.Technical_Mgmt_Escalation_Date__c == null && eachCase.Escalate_Technical_Mgmt_Case__c == false)
                || (!isInsert && eachCase.Severity__c == '1' && techCaseSevUpdatedTo1))
               && (mapIdAccount.containsKey(eachCase.AccountId) && mapIdAccount.get(eachCase.AccountId).Support_Advocacy_Special_Escalation__c)
              )
            {
                if(!mapEscalationAgingTime.isEmpty() && mapEscalationAgingTime.containsKey(eachCase.Severity__c))
                {
                    triggerERDate = System.now().addHours(mapEscalationAgingTime.get(eachCase.Severity__c));// + (mapEscalationAgingTime.get(eachCase.Severity__c)/24.0));// - (5/(24.0*60));
                    if(mapWeekendEscalation.containsKey(eachCase.Severity__c) && mapWeekendEscalation.get(eachCase.Severity__c))
                    {    
                        eachCase.Technical_Mgmt_Escalation_Date__c = triggerERDate;
                    }
                    else
                    {
                        eachCase.Technical_Mgmt_Escalation_Date__c = CaseTriggerClass.dayOfWeek(triggerERDate); 
                    }
                }
                /*
else if(mapEscalationAgingTime.get(eachCase.Severity__c) == 0)
{
triggerERDate = System.now();
//eachCase.Escalate_Technical_Mgmt_Case__c = true;
//caseListforERCreation.add(eachCase);
}*/
                
                System.debug('!!!!!!! SPECIAL DATE :' + eachCase.Technical_Mgmt_Escalation_Date__c);
            }
            if(!isInsert 
               && eachCase.Technical_Mgmt_Escalation_Date__c != null 
               && eachCase.Escalate_Technical_Mgmt_Case__c
               && (mapIdAccount.containsKey(eachCase.AccountId) && mapIdAccount.get(eachCase.AccountId).Support_Advocacy_Special_Escalation__c)
              )
            {            
                lstCaseforERCreation.add(eachCase);        
            }
        } 
        
        if(!lstCaseforERCreation.isEmpty())
        {
            System.debug('!!!!!!! caseListforERCreation : ' + lstCaseforERCreation);
            CaseTriggerClass.createERForSupportAdvocacyEscalation(lstCaseforERCreation,mapIdAccount);
        }
    }
    
    //Changes by Bhavesh : AMG checking case reopen condition ESESP-3404
    public static void checkAMGCaseReopenCondition(Case varCase, Map<Id,Case> newMap ){
        Integer closedDays = varCase.AKAM_Closed_Date__c.date().daysBetween(system.today());
        
        If(closedDays <=45)
        {
            varCase.Reopened__c = true;
            //varCase.Status = 'Reopened';
            varCase.AKAM_Closed_Date__c = null;
            varCase.AKAM_Reopened_Date__c = system.now();
            varCase.Is_IP_Scrubbed__c = false;
            varCase.IP_Scrubbing_Failed_Objects__c = null;
        }
        else
        {
            String errorMsg = 'Cases can only be reopened within 45 days of case closure. Please create a new case.';
            newMap.get(varCase.id).addError(errorMsg);
        }
    }
    
    //Changes by Sharath for Billing migration: Method to publish platform event
    public static Boolean publishBilling = false;
    
    @future
    public static void publishPlatformEventBilling()
    {
        Billing_Cases__e publishRec = new Billing_Cases__e();
        EventBus.publish(publishRec);
    }
    
    // Changes by Sumukh for Akatec Enhanced Milestones
    public static Boolean createenhmilestone = false;
    
    public static void createEnhancedMilestone(map<id,id> caseIdforEnhancedMilestoneCreation)
    {
        list<CaseMilestone> caseMilestoneList = new list<CaseMilestone>();
        
        if(test.isRunningTest())
        {
            caseMilestoneList = [  SELECT MilestoneType.Name, Id, IsCompleted,caseid,IsViolated,StartDate, TargetDate ,CompletionDate FROM CaseMilestone  
                             WHERE CaseId IN :caseIdforEnhancedMilestoneCreation.keyset()];
      
        }
        else
        {
        caseMilestoneList = [  SELECT MilestoneType.Name, Id, IsCompleted,caseid,IsViolated,StartDate, TargetDate ,CompletionDate FROM CaseMilestone  
                             WHERE CaseId IN :caseIdforEnhancedMilestoneCreation.keyset() AND (IsCompleted = true OR IsViolated=true) ];
        }
        if(caseMilestoneList.size()>0)
        {
            map<id,CaseMilestone> casemilestonemap = new map<id,CaseMilestone>();
            for(CaseMilestone eachmilestonerec : caseMilestoneList)
            {
                casemilestonemap.put(eachmilestonerec.id, eachmilestonerec);
            }
            
            list<Enhanced_Milestone__c > enhancedMilestoneList = new list<Enhanced_Milestone__c >();    
            enhancedMilestoneList =[select Milestone_ID__c from Enhanced_Milestone__c where Milestone_ID__c IN :casemilestonemap.keyset()];
            
            for(Enhanced_Milestone__c eachenhancedMilestonerec : enhancedMilestoneList)
            {
                casemilestonemap.remove(eachenhancedMilestonerec.Milestone_ID__c);
            }
            
            if(!casemilestonemap.isEmpty())
            {
                List<Enhanced_Milestone__c> newEnhMilList = new List<Enhanced_Milestone__c>();
                for (String milestoneid : casemilestonemap.keySet())
                {
                    Enhanced_Milestone__c newMilestone = new Enhanced_Milestone__c();
                    
                    newMilestone.Case__c = casemilestonemap.get(milestoneid).caseid;
                    newMilestone.Milestone_ID__c = casemilestonemap.get(milestoneid).id;
                    newMilestone.Is_Violation__c = casemilestonemap.get(milestoneid).IsViolated;
                    newMilestone.Is_Complete__c = casemilestonemap.get(milestoneid).IsCompleted;
                    newMilestone.Target_Date__c =casemilestonemap.get(milestoneid).TargetDate;
                    newMilestone.Start_Date__c =casemilestonemap.get(milestoneid).StartDate;
                    newMilestone.Milestone_Type__c =casemilestonemap.get(milestoneid).MilestoneType.Name; 
                    newMilestone.Completion_Date__c =casemilestonemap.get(milestoneid).CompletionDate;
                    newMilestone.ownerid = caseIdforEnhancedMilestoneCreation.get(newMilestone.Case__c);
                    newMilestone.User_Type__c = string.valueOf(newMilestone.OwnerId).startsWith('005') ? 'User' : 'Queue';
                    newMilestone.Enhanced_Date__c  = (newMilestone.Is_Complete__c) ? newMilestone.Completion_Date__c : newMilestone.Target_Date__c;
                    
                    newEnhMilList.add(newMilestone);
                }
                try
                {
                    insert newEnhMilList;
                }
                catch(exception e)
                {
                    
                }
            }
        }
        
    }
    
    // changes by Vandhana for ESESP-2346 Carrier LX Migration
    @future
    public static void technicalIRMilestoneUpdate(map<id,boolean> caseIDforIRUpdate_hasSevChanged)
    {
        list<CaseMilestone> caseMilestoneList = new list<CaseMilestone>();
        
        // changes by Vandhana - added Resolution and Mitigation milestones for Carrier cases
        for(CaseMilestone eachMilestone: [SELECT  Id, startdate,IsCompleted,IsViolated,completiondate,CaseId 
                                          FROM CaseMilestone  
                                          WHERE CaseId IN :caseIDforIRUpdate_hasSevChanged.keySet() 
                                          AND MilestoneType.Name IN ('Initial Response','Mitigation','Resolution') AND
                                          Case.IsClosed = false])
        {
            //Logic for updating IR milestones if the case's severity has changed
            if(caseIDforIRUpdate_hasSevChanged.get(eachMilestone.CaseID))
            {
             	if(!eachMilestone.IsCompleted && !eachMilestone.IsViolated)
                {
                    eachMilestone.startdate = DateTime.now();
                }   
            }
            else //Logic for updating IR milestones if the case's recordtype has changed
            {
                if(!eachMilestone.IsCompleted) //If Milestone is violated
                {
                    eachMilestone.startdate = DateTime.now();
                }
                else if(eachMilestone.IsCompleted)
                {
                    eachMilestone.completiondate = null;
                    eachMilestone.startdate = DateTime.now();
                }
            }
            caseMilestoneList.add(eachMilestone);
        }
        if(caseMilestoneList.size() > 0)
        {
            update caseMilestoneList;               
        }
    }
    
    //ESESP-3590:Changes by Bhavesh, RCA case creation validation and field udpates from parent record.
    public static void rcaCreationValidation (List<Case> newList, List<Id> parentCaseIds, Map<Id,String> mRecordType) {
        Map <Id, Case> caseMap = new Map <Id, Case> ([Select Id, RecordTypeId, AccountId, Account.Indirect_Customer__c , RecordType.Name, Support_Level__c, Service_Incident__c FROM Case WHERE Id IN: parentCaseIds ]);
        for (Case cs : newList) {
            // Changes by Sheena for ESESP-5433: Removed restriction for only Tech/AMG Parent Case for RCA Cases
            if (cs.ParentId == NULL || 
                (cs.ParentId  != NULL && caseMap.get(cs.ParentId).RecordTypeId != NULL && 
                 mRecordType.get(caseMap.get(cs.ParentId).RecordTypeId) == 'Invalid Case')) {
                     cs.addError('Parent Case cannot be an Invalid Case');
                 } 
            else {
                cs.AccountId = caseMap.get(cs.ParentId).AccountId;
                if(caseMap.get(cs.ParentId).RecordType.Name == 'Technical'){
                    cs.IRAPT_Owned__c = True;
                }
                cs.Support_Level__c = caseMap.get(cs.ParentId).Support_Level__c;
                cs.AccountId = cs.AccountId;
                cs.Indirect_Account__c = cs.Account.Indirect_Customer__c;
                if( caseMap.get(cs.ParentId).Service_Incident__c != NULL ){
                    cs.Service_Incident__c = caseMap.get(cs.ParentId).Service_Incident__c;
                }
            }
        }
    }
	//ESESP-3590, By:Bhavesh, RCA case creation email notification .
    public static void sendEmailRCACreation (List<Case> newList){
        Environment_Setup__c environmentSetup = Environment_Setup__c.getOrgDefaults();
        String akamCaseIdStart = environmentSetup.Akam_Id_Start_String__c;
        String iratpEmailId = '';	
        String iraptDocLink = '';	
        for( RCA_Request_Value__mdt  md : [ Select Id, DeveloperName , Value__c FROM RCA_Request_Value__mdt ]){	
            if(md.DeveloperName  == 'IRAPT_Email_Id'){	
                iratpEmailId = md.Value__c;	
            } else if(md.DeveloperName  == 'RCA_Document_Link'){	
                iraptDocLink = md.Value__c;	
            }	
        }
        List<Messaging.Singleemailmessage> emailList = new List<Messaging.Singleemailmessage>();
        Map <Id, Case> caseMap = new Map <Id, Case> ([Select Id, Parent.Owner.Email, Parent.AccountId, Parent.Account.Name, Parent.AKAM_Case_ID__c,
                                                     CreatedBy.Name, CreatedBy.Email FROM Case Where Id IN: newList]);
       
        
        for (Case cs : newList) {
            List <String> emailIds = new List <String> ();
            emailIds.add(iratpEmailId); 
            if (caseMap.get(cs.Id).Parent.OwnerId != NULL && caseMap.get(cs.Id).Parent.Owner.Email != NULL){
                emailIds.add(caseMap.get(cs.Id).Parent.Owner.Email);
            }  
            emailIds.add(caseMap.get(cs.Id).CreatedBy.Email);
            OrgWideEmailAddress[] owea = [select Id from OrgWideEmailAddress where Address = 'sf-no-reply@akamai.com'];
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                                     
            String link = iraptDocLink;
            String subject = 'RCA Request [AKAM-CASE #'+akamCaseIdStart+cs.CaseAutoId__c+'] has been assigned to the SERVICE_INCIDENTS_QUEUE';
            String body = 'Please refer to  <a href="'+link+'">'+link+'</a> for details about the RCA process.<br><br>'+
            '<table border="1" style="border-collapse: collapse; width:60%">'+
                        '<tr><td>Case #:</td><td>'+ akamCaseIdStart+cs.CaseAutoId__c+'</td></tr>'+
                        '<tr><td>Parent Case: </td><td>'+caseMap.get(cs.Id).Parent.AKAM_Case_ID__c+'</td></tr>'+
                        '<tr><td>Account:</td><td>'+caseMap.get(cs.Id).Parent.Account.Name+'</td></tr>'+
                        '<tr><td>Type:</td><td>RCA Request</td></tr>'+
                        '<tr><td>Opened Date:</td><td>'+cs.createdDate.formatGMT('dd MMM yyyy, HH:MM')+' UTC</td></tr>'+
                        '<tr><td>Created By:</td><td>'+caseMap.get(cs.Id).CreatedBy.Name+'</td></tr>'+
            '</table>';
            email.setOrgWideEmailAddressId(owea.get(0).Id);
            email.setHtmlBody(body);
            email.setSubject(subject);
            email.setToAddresses(emailIds);
            email.setSaveAsActivity(true);
            emailList.add(email);   
        }
        if(emailList.size()>0)
        	Messaging.sendEmail(emailList);
    }
	
   
    
	//ESESP-3590, By:Bhavesh, RCA case owner Validation.
    public static void checkRCA_OwnerValidation (List < Case> newList, Map <Id, Case> oldMap, Set <Id> userIdList, Map<Id,String> mRecordType) {
        Map <Id, User> userMap = new Map <id, User>([Select Id, SC_SI_IRAPT_User__c FROM User WHERE Id IN: userIdList]);
        for (Case cs : newList) {
            if( mRecordType.get(cs.RecordTypeId) == 'RCA Request' ){
                //for insert, check if rca owner is an irapt user. for insert Case owner will be a queue, so need to check owner.
                if( oldMap == NULL ){
                    if ( cs.RCA_Owner__c != NULL && userMap.get(cs.RCA_Owner__c).SC_SI_IRAPT_User__c == FALSE ) {
                        cs.addError ('Only IRAPT users can be a RCA Owner.');
                    }
                } else {
                    //for update scenario
                    //check if rca owner is an IRAPT user
                    if ( cs.RCA_Owner__c != oldMap.get(cs.Id).RCA_Owner__c && userMap.get(cs.RCA_Owner__c).SC_SI_IRAPT_User__c == FALSE ) {
                        cs.addError ('Only IRAPT users can be a RCA Owner.');
                    }
                    //check if case owner is an IRAPT user.
                    if ( cs.OwnerId != oldMap.get(cs.Id).OwnerId && string.valueOf(cs.OwnerId).startsWith('005') && userMap.get(cs.OwnerId).SC_SI_IRAPT_User__c == FALSE ) {
                        cs.addError ('Only IRAPT users can be a Case Owner.');
                    } 
                    // if status is changed and status is rejected then check only irapt user can reject a rca case.
                    if ( cs.Status != oldMap.get(cs.Id).Status && cs.Status == 'Rejected' && userMap.get(cs.LastModifiedById).SC_SI_IRAPT_User__c == FALSE ) {
                        cs.addError ('Only IRAPT users can Reject an RCA request.');
                    }
                }
            }
            
            
        }
    }
	
    //ESESP-3590, By:Bhavesh, RCA case Milestone Complete.
    public static void completeMilestone(List<Id> caseIds, String milestoneName, DateTime complDate) {  
        List <CaseMilestone> cmsToUpdate = new List <CaseMilestone> ([select Id, completionDate
                from CaseMilestone cm
                where caseId in :caseIds and cm.MilestoneType.Name=:milestoneName 
                and completionDate = null limit 1]);
        if (cmsToUpdate.isEmpty() == false){
            for (CaseMilestone cm : cmsToUpdate){
                cm.completionDate = complDate;
                }
            update cmsToUpdate;
        }
    }

    //ESESP-3590, By:Bhavesh, RCA case Transition Completion.
    public static void completeTransition (List<Id> caseIds, Map<Id, Case> newMap){
        List<Case_Transition__c> caseTransitionList = new List<Case_Transition__c>();
        for(Case_Transition__c ct: [Select Id,Case__c FROM Case_Transition__c where Case__c in: caseIds AND completed__c = False]){
            ct.New_Owner__c = newMap.get(ct.Case__c).OwnerId;
            ct.completed__c = true;
            ct.Completed_Date__c = Date.Today();
            caseTransitionList.add(ct);
        }
        if(!caseTransitionList.isEmpty()){
        	rcaTransitionFlag = true;
            update caseTransitionList;
        }
    }
    
    //ESESP-3590, By:Bhavesh, update SI on RCA when SI is updated on parent case.
    public static void updateRCAServIncdValue( Map<Id, Id> caseIdWithServIncdMap ){
        Id rcaRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('RCA Request').getRecordTypeId();
        List<Case> rcaToUpdate = new List<Case>();
        Map<Id,Id> rcaIdToSI_IdMap = new Map<Id,Id>();
        List<Knowledge__KAV> rcaKAVToUpdate = new List<Knowledge__KAV>();
        for( Case cs :[Select Id, ParentId FROM Case where ParentId in: caseIdWithServIncdMap.keySet() AND Status != 'Closed'] ){
            cs.Service_Incident__c  = caseIdWithServIncdMap.get(cs.ParentId);
            cs.Validation_Override__c = True;
            rcaToUpdate.add(cs);
            rcaIdToSI_IdMap.put(cs.Id,caseIdWithServIncdMap.get(cs.ParentId));
        }
        if( rcaToUpdate.size() > 0){
            update rcaToUpdate;
        }
        if( !rcaToUpdate.isEmpty() ){
            for( Knowledge__KAV kav :[Select Id, Service_Incident_Number__c, Source_Case__c FROM Knowledge__KAV where Source_Case__c in: rcaToUpdate AND Service_Incident_Number__c = NULL and PublishStatus = 'Draft'] ){
                kav.Service_Incident_Number__c  = rcaIdToSI_IdMap.get(kav.Source_Case__c);
                rcaKAVToUpdate.add(kav);
            }
            if( rcaKAVToUpdate.size() > 0){
                update rcaKAVToUpdate;
            }
        }
    }
    

    static Integer getDayOfWeek(Date value) {
        Date monday = Date.newInstance(1900, 1, 3);
        return Math.mod(monday.daysBetween(value), 7);
    }
	//ESESP-3590, By:Bhavesh, for RCA, get working days between two days.
	public static Integer getWorkingDays(Date startDate, Date endDate) {
        List<Boolean> isWorkingDay;
        Integer workingDaysInWeek;
        isWorkingDay = new List<Boolean> { true, true, true, true, true, false, false };
        workingDaysInWeek = 5;
        if(workingDaysInWeek == 0 || startDate == null || endDate == null) {
            return 0;
        } else {
            Integer difference = startDate.daysBetween(endDate);
            if(difference == 0) {
                //If the 2 dates are the same day check if the day is a working day or not
                return isWorkingDay[getDayOfWeek(startDate)] ? 1 : 0;
            } else if(workingDaysInWeek == 7) {
                //when every day is a working day return the difference
                return difference;
            } else {
                Integer wholeWeeks = Math.floor(difference / 7).intValue();
                Integer workingDays = wholeWeeks * workingDaysInWeek;
                Integer dayOfWeek = getDayOfWeek(endDate);
                for(Integer remainder = Math.mod(difference, 7); remainder >= 0; remainder--) {
                    if(isWorkingDay[dayOfWeek]) {
                        workingDays++;
                    }
                    dayOfWeek--;
                    if(dayOfWeek < 0) {
                        dayOfWeek = 6;
                    }
                }
                return workingDays;
            }
        }
    }
    
    //ESESP-3590, By:Bhavesh, RCA case closing condition.
    public static void rcaCaseClosingCondition (List<Id> caseIds, List<Case> caseList){
        Set<Id> caseIdWithStatus_KB_ArticleCreated =  new Set<Id> ();
        Set<Id> caseIdWithKB_ArticleCreated =  new Set<Id> ();
        for( CaseHistory ch : [Select Id, CaseId, OldValue, NewValue FROM CaseHistory WHERE CaseId In: caseIds AND Field = 'Status' ]){
            if((ch.OldValue == 'KB Article Created' || ch.NewValue == 'KB Article Created')){
                caseIdWithStatus_KB_ArticleCreated.add(ch.CaseId);
            }
        }
        
        for( Knowledge__KAV kv : [Select Id, Source_Case__c FROM Knowledge__KAV WHERE Source_Case__c In: caseIds ]){
            caseIdWithKB_ArticleCreated.add(kv.Source_Case__c);
        }


        for(Case cs: caseList){
            
            if( cs.Status == 'Closed' && !(caseIdWithKB_ArticleCreated.contains (cs.Id) && (caseIdWithStatus_KB_ArticleCreated.contains (cs.Id) || cs.Status == 'KB Article Created' ) ) ){
                cs.addError('Please create a Knowledge Article and udpate the RCA Request status to \'KB Article Created\' before closing this case.');
            } else if(cs.Status == 'KB Article Created' && !(caseIdWithKB_ArticleCreated.contains (cs.Id))){
                cs.addError('Please create a Knowledge Article before updating the case status to \'KB Article Created\'.');
            }
        }
       
    }

    //ESESP-3590, By:Bhavesh, RCA case Pending Follow-up condition.
    public static void rcaCasePendingFollowupCondition(List<Id> caseIds, List<Id> servIncidentIds, Map<Id, Case> newMap){
        Set<Id> valid_SI_Ids = new Set<Id>();
        for( SC_SI_External_Dependency__c ed : [ Select Id, Service_Incident__c FROM SC_SI_External_Dependency__c WHERE Type__c = 'Jira' AND Category__c = 'RCA Follow-up' AND Service_Incident__c IN: servIncidentIds]){
            valid_SI_Ids.add( ed.Service_Incident__c );
        }
        for( Id csId : caseIds ){
            Case cs = newMap.get(csId);
            if(!valid_SI_Ids.contains(cs.Service_Incident__c)){
                cs.addError('Error: Related Incident should have an External Dependency Type as Jira with Category as RCA follow-up.');
            }
        }
    }
    //ESESP-3590, By:Bhavesh, RCA case closing condition.
    public static void checkIsUserInternal(List<Id> userIds, List<Case> newList){
        Set<Id> externalUsrIds = new Set<Id>();
        for( User usr: [Select Id, Email FROM User WHERE Id IN: userIds]){
            if( !usr.Email.containsIgnoreCase('@akamai.com') ){
                externalUsrIds.add( usr.Id );
            }
        }
        if(externalUsrIds.size() > 0){
            for( Case cs : newList ){
                if( externalUsrIds.contains(cs.IRAPT_Approver__c)){
                    cs.addError('IRAPT Approver should be an Internal user.');
                } else if( externalUsrIds.contains(cs.Legal_Reviewer__c)){
                    cs.addError('Legal Reviewer should be an Internal user.');
                } else if( externalUsrIds.contains(cs.Exec_Approver__c)){
                    cs.addError('Exec Approver should be an Internal user.');
                } 
            }
        }
        
    }
    //ESESP-3590, By:Bhavesh, if rca case status is RCA Delivered then atleast one peer review record should be there.
    public static void checkPeerReviewValidation(List<Id> caseIds, Map<Id, Case> newMap){
        Set<Id> caseIdsWithPeerReviewRecord = new Set<Id>();
        For ( Peer_Reviewer__c pr: [Select Id,Case__c FROM Peer_Reviewer__c WHERE Case__c in: caseIds ]){
            caseIdsWithPeerReviewRecord.add( pr.Case__c );
        }
        for(Id caseId : caseIds ){
            Case csRec = newMap.get(caseId);
            if( !caseIdsWithPeerReviewRecord.contains(caseId)){
                csRec.addError('There should be at least one Peer Reviewer associated with the Case if the status is RCA Delivered state');
            }
        }
        
    }
    //ESESP-3590, By:Bhavesh, Called from PeerReviewTrigger  
    public static void checkRcaIraptReviewerCondition( List<Id> caseIds, List<Id> reviewerIds, List<Peer_Reviewer__c> newList ){
        Map<Id,String> caseIdWithIraptReviewer = new Map<Id,String>();
        Map<Id, User> userMap = new Map<Id, User>([ Select ID, SC_SI_IRAPT_User__c, Email FROM User WHERE Id IN: reviewerIds]);
        for( Case cs: [Select Id, IRAPT_Approver__c FROM Case WHERE Id IN: caseIds AND IRAPT_Approver__c != NULL]){
            caseIdWithIraptReviewer.put(cs.Id, cs.IRAPT_Approver__c);
        }
        for( Peer_Reviewer__c pr: newList ){
            if( caseIdWithIraptReviewer.containsKey(pr.Case__c) && pr.Reviewer_Name__c == caseIdWithIraptReviewer.get(pr.Case__c)){
                pr.addError('Reviewer Name value cannot be same as IRAPT Approver on RCA');
            } else if( !userMap.get(pr.Reviewer_Name__c).Email.containsIgnoreCase('@akamai.com') ){
                pr.addError('Reviewer should be an Internal user.');
            }
        }
    }
    //ESESP-3590, By:Bhavesh, checking non irapt field updates. as non irapt can update only resolution summary field
    public static void rcaNonIraptValidationCheck(Set<Id> userSet, list<Case> newList, Map<Id, Case> oldMap ){
        Boolean isUserIrapt = [Select Id, SC_SI_IRAPT_User__c FROM User WHERE Id =: UserInfo.getUserId()].SC_SI_IRAPT_User__c;
        if( !isUserIrapt ){
            List<Metadata.Metadata> layouts = 
            Metadata.Operations.retrieve(Metadata.MetadataType.Layout, 
                                        new List<String> {'Case-RCA Request Layout'});

            Metadata.Layout layoutMd = (Metadata.Layout)layouts.get(0);
            for( Case cs : newList ){
                for (Metadata.LayoutSection section : layoutMd.layoutSections) {
                    if( section.label== 'Case Information' || section.label== 'Resolution Summary' || section.label== 'Other Fields'){
                        for (Metadata.LayoutColumn column : section.layoutColumns) {
                            if (column.layoutItems != null) {
                                for (Metadata.LayoutItem item : column.layoutItems) {
                                    if( oldMap == NULL ){
                                        if( item.behavior != metadata.UiBehavior.Readonly && !(item.field == 'Resolution_Summary__c'  || item.field == 'ParentId' || item.field == 'Status' || item.field == 'OwnerId' || item.field == 'Area__c' || item.field == 'RCA_Creator__c' || item.field == 'Indirect_Account__c' || item.field == 'Subject' || item.field == 'Priority' || item.field == 'PartnerCaseBoolean__c' || item.field == 'RCA_for_Incident__c' || item.field == 'IRAPT_Owned__c' || item.field == 'Interim_RCA_delivered__c' || item.field == 'Customer_Push_Back__c' || item.field == 'Origin')
                                            &&  cs.get(item.field) != NULL
                                            &&  cs.Validation_Override__c == False
                                        ){
                                            cs.addError('Non-Irapt users are allowed to fill Resolution Summary and Parent Case only.');
                                            rcaErrorInCase = true;
                                            break;
                                        }
                                    } else {
                                        if(item.behavior != metadata.UiBehavior.Readonly && !(item.field == 'Resolution_Summary__c') && cs.get(item.field) != oldMap.get(cs.Id).get(item.field)){
                                            cs.addError('Non-Irapt users are allowed to fill Resolution Summary field only.');
                                            rcaErrorInCase = true;
                                            break;
                                        }
                                    }
                                    
                                }
                            }
                        }
                    }
                }
            }
            SC_CaseTriggerHelperClass3.rcaRecursiveNonIraptCheck = True;
        }
    }
    //
    public static void checkIraptApproverValidation( Set<Id> iraptAprvSet, List<Case> newList){
        Map<Id, Set<Id>> caseIdWithPeerUserIdMap = new Map<Id, Set<Id>>();
        for( Peer_Reviewer__c pr : [Select Id, Case__c,Reviewer_Name__c FROM Peer_Reviewer__c WHERE Reviewer_Name__c IN: iraptAprvSet AND Case__c IN: newList]){
            if(caseIdWithPeerUserIdMap.containsKey(pr.Case__c)){
                Set<Id> userSet = caseIdWithPeerUserIdMap.get(pr.Case__c);
                userSet.add(pr.Reviewer_Name__c);
                caseIdWithPeerUserIdMap.put(pr.Case__c, userSet);

            } else {
                caseIdWithPeerUserIdMap.put(pr.Case__c, new Set<Id>{pr.Reviewer_Name__c});
            }
        }
        for( Case cs : newList ){
            if( cs.IRAPT_Approver__c != NULL && caseIdWithPeerUserIdMap.containsKey(cs.Id) && caseIdWithPeerUserIdMap.get(cs.Id).contains(cs.IRAPT_Approver__c)){
                cs.addError('Irapt Approver cannot be same as Peer Reviewer.');
            }
        }
    }
   

    public static Boolean updateBusinessHours = false;    
    
    @future
    public static void updateBusinessHoursCases(List<Id> caseIds)
    {
        Map<Id,Case> caseIdtoRec= new Map<Id,Case>([Select Id,Case_Product__r.Name, 
        Business_Unit__c,Validation_Override__c from Case where Id in :caseIds]);
        Set<String> caseProductNamesPS = new Set<String>();
        Map<String, Set<String>> caseProductToMarketingProducts = new Map<String, Set<String>>();
        Set<String> marketingProducts = new Set<String> ();
        List<Case> casesToUpdate = new List<Case>();
        Map<String,String> caseProductToBusinessHours = new Map<String,String>();
        
        Case caseRec;
        for(Id caseId: caseIdtoRec.keySet())
        {
            caseRec = caseIdtoRec.get(caseId);
            if(caseRec.Case_Product__r.Name != null)                
            {
                caseProductNamesPS.add(caseRec.Case_Product__r.Name);
            }
        }

        if(caseProductNamesPS.size() > 0)
        {
            for (Siebel_Marketing_Prod_Case_Prod_Map__c mappingRec : SC_Jarvis_utility.getMappingRecords( caseProductNamesPS, null))
            {
                if(!caseProductToMarketingProducts.containsKey(mappingRec.Case_Product_Name__c))
                {
                    caseProductToMarketingProducts.put(mappingRec.Case_Product_Name__c,new Set<String>());   
                }
                caseProductToMarketingProducts.get(mappingRec.Case_Product_Name__c).add(mappingRec.Marketing_Product_ID__c);                
            }

            for(String caseProductName: caseProductNamesPS)
            {
                if(caseProductToMarketingProducts.get(caseProductName) != null)
                {
                    marketingProducts.addAll(caseProductToMarketingProducts.get(caseProductName));
                }
            }
            if(marketingProducts.size() > 0)
            {
                Map<String,String> productToBusinessHours = new Map<String,String>();

                for(PAC_Product_Catalog__c pacRec: SC_Jarvis_utility.getBusinessUnit(marketingProducts, 0))
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
                }
            }
        }
        for(Id caseId: caseIdtoRec.keySet())
        {
            caseRec = caseIdtoRec.get(caseId);
            string currentCaseProductName = caseRec.Case_Product__r.Name;
            if(currentCaseProductName == null || 
            !caseProductToBusinessHours.containsKey(currentCaseProductName) ||
            caseProductToBusinessHours.get(currentCaseProductName) == '' && caseRec.Business_Unit__c != null)
            {
                caseRec.Business_Unit__c= null;
                caseRec.Validation_Override__c = true;
                casesToUpdate.add(caseRec);
            }
            else if(caseRec.Business_Unit__c != caseProductToBusinessHours.get(currentCaseProductName))
            {
                caseRec.Business_Unit__c = caseProductToBusinessHours.get(currentCaseProductName);
                caseRec.Validation_Override__c = true;
                casesToUpdate.add(caseRec);
            }

        }
        if(casesToUpdate.size() > 0)
        {

            List<Database.SaveResult> updateResults = Database.update(casesToUpdate,false);
            SC_Jarvis_utility.populateErrorTableForUpdate(updateResults,casesToUpdate,'Jarvis: Case Update Error','Jarvis: Case Update Error');
        }

    }  
    
    // ESESP-5772 , By : Vishnu Sharma : Method to restrict OCID field change on PS case for ineligibe Users.
    public static void validationForAuthorizedUserForOCIDEdit(List<Case> newCaseList , Map<Id,Case> oldCaseMap,Boolean isInsert){
        List<Case> casesInScope = new List<Case>();
        List<Id> accountsInScope = new List<Id>();
        
        List<AccountTeamMember> atmList = new List<AccountTeamMember>();
        Map<Id,List<Id>> accountVSTeamMemberMap = new Map<Id,List<Id>>();
        for(Case iteratedCase : newCaseList){
            System.debug('****'+ iteratedCase.IR_Original_Contract_Id__c);
            
            if(iteratedCase.recordTypeId == Schema.SObjectType.Case.getRecordTypeInfosByName().get('Professional Services').getRecordTypeId() && ((isInsert && iteratedCase.IR_Original_Contract_Id__c != null) || (!isInsert && iteratedCase.IR_Original_Contract_Id__c != oldCaseMap.get(iteratedCase.Id).IR_Original_Contract_Id__c))){
                casesInScope.add(iteratedCase);
                accountsInScope.add(iteratedCase.AccountId);
            
            }
        }
        if(accountsInScope.size() > 0){
            atmList = [Select Id,UserId,AccountId from AccountTeamMember where TeamMemberRole = 'Security Services - Primary' AND AccountId IN : accountsInScope];
            if(atmList.size() > 0){
                for(AccountTeamMember iteratedATM : atmList){
                    if(accountVSTeamMemberMap.containsKey(iteratedATM.AccountId)){
                        accountVSTeamMemberMap.get(iteratedATM.AccountId).add(iteratedATM.UserId);  
                    }else{
                        List<Id> tempList = new List<Id>();
                        tempList.add(iteratedATM.UserId);
                        accountVSTeamMemberMap.put(iteratedATM.AccountId,tempList);
                    }
                }
            }

            for(Case iteratedCase : casesInScope){
                if(!accountVSTeamMemberMap.containsKey(iteratedCase.AccountId) || !accountVSTeamMemberMap.get(iteratedCase.AccountId).contains(UserInfo.getUserId())){
                    iteratedCase.addError('User should be Account team member with Security Services - Primary role to change Original Contract Id field.');
                }
            }

        }
    }
}