/*
Author          : Sumukh SS/Vandhana Krishnamurthy
Description     : Controller for Unified Case Dashboard

Date                    Developer             		JIRA #                      Description                                                       
------------------------------------------------------------------------------------------------------------------
24 Aug 2020				Authors				 	    ESESP-3829				  Initial Development
17 Nov 2020           	Vandhana Krishnamurthy     	ESESP-4581                Commented out date filter for Milestones
23 Nov 2020				Vandhana Krishnamurthy     	ESESP-4599                New indicator for overdue Requested Completion Date (datetime in past)
28 Nov 2020           	Sumukh SS	                  21.1                    Cases in Queue Enhancements for full launch
23 Aug 2021           	Jay R	                    ESESP-5669                Replace PS_Product__c with Case_Product__c
------------------------------------------------------------------------------------------------------------------
*/
//Test Comment

public without sharing class SC_UCD_HomePage 
{        
    //CASE WRAPPER
    public class CaseWrapper
    {
        @AuraEnabled public String akamCaseId;
        @AuraEnabled public Id caseRecId;
        @AuraEnabled public string severity;
        @AuraEnabled public String caseUrl;
        @AuraEnabled public String ownerId;
        @AuraEnabled public String userNameRole;
        @AuraEnabled public String userNameRoleUrl;
        @AuraEnabled public String accountName;
        @AuraEnabled public String accountUrl;
        @AuraEnabled public String subject;
        @AuraEnabled public String caseloe;
        @AuraEnabled public Decimal caseloeval;
        @AuraEnabled public String reqCompletionDate;
        @AuraEnabled public Date reqCompletionDateVal;
        @AuraEnabled public String reqCompletionDateColour;
        @AuraEnabled public Double ageDays;
        @AuraEnabled public Decimal utilizedHours;
        @AuraEnabled public Decimal billableHours;
        @AuraEnabled public String billableHoursClass;
        @AuraEnabled public Decimal nonbillableHours;
        @AuraEnabled public Decimal internalHours;
        @AuraEnabled public String nextPlannedActivityDate;
        @AuraEnabled public Date nextPlannedActivityDateVal;
        @AuraEnabled public String livingSummary;
        @AuraEnabled public String livingSummaryTop3;
        @AuraEnabled public String livingSummaryConcat;
        @AuraEnabled public Boolean showlivingSummarybtn;
        @AuraEnabled public String caseCreator;
        @AuraEnabled public String caseOwner;
        @AuraEnabled public String status;
        @AuraEnabled public String Service;
        @AuraEnabled public String ReqType;
        @AuraEnabled public String timecard; 
        @AuraEnabled public String Project; 
        @AuraEnabled public String milestone; 
        @AuraEnabled public String projectProduct; 
        @AuraEnabled public String ProjectURL;
        @AuraEnabled public String pendingCaseReason;
        //@AuraEnabled public Boolean showpendingCaseReasonbtn;
        @AuraEnabled public Boolean disableCaseAckButton;
        @AuraEnabled public String caseAckButtonIcon;
        @AuraEnabled public String caseAckButtonBgClass;
        @AuraEnabled public Id caseProductId;
        @AuraEnabled public String caseProductName;
        @AuraEnabled public String caseOrigin;
    }
    
    // start of changes by Vandhana
    @AuraEnabled
    public static List<CaseWrapper> getMyCases(String view, Map<String,String> filter, String userView)
    {
        List<Case> lstCase = new List<Case>();
        
        List<CaseWrapper> lstMyCaseWrapper = new List<CaseWrapper>();
        
        CaseWrapper caseWrapRec;
        List<String> lstLivingSummaryRows = new List<String>();
        
        Id psRecTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        
        Date startDateVal = System.now().date().toStartOfWeek();
        Date endDateVal;
        Datetime dateForDayVal = DateTime.newInstance(startDateVal, Time.newInstance(0, 0, 0, 0));
        String dayOfWeek = dateForDayVal.format('EEE');
        if(dayOfWeek == 'Mon')
        {
            startDateVal = startDateVal.addDays(-1);
        }
        endDateVal = startDateVal.addDays(6);
        Id userId = UserInfo.getUserId();
        
        String caseBaseQuery = 'SELECT AKAM_Case_ID__c,Severity__c,AccountId,Account.Name,Subject,LOE_Hours__c,Requested_Completion_Date_UTC__c,Requested_Completion_Time_UTC__c, ' 
            + ' Age_days__c, Living_Summary_Next_Steps__c,Case_Owner_Name__c,CreatedBy.Name,Status,pse_Project__c,pse_Milestone__c,Next_Planned_Activity_Date__c, ' 
            + ' Billable_Hours__c,Non_Billable_Hours__c,Internal_Hours__c, OwnerId, CreatedById, CreatedBy.FirstName,Owner.FirstName,Owner.Name,Owner.Type,Case_Acknowledged__c,Case_Product__c,Case_Prod_Name__c,Description,Service__c,Request_Type__c, '
            + ' (SELECT Id, pse__Milestone__c, pse__Project__c, pse__Assignment__c, pse__Start_Date__c, pse__End_Date__c, pse__Status__c, pse__Project_Methodology_Object__c ' 
            + ' FROM Timecards__r WHERE ' //pse__Start_Date__c = :startDateVal AND pse__End_Date__c = :endDateVal AND 
            //+ ' pse__Status__c = \'Saved\' AND ' 
            + ' pse__Resource__r.pse__is_resource__c = true '
            + ' AND pse__Resource__r.pse__is_resource_active__c = true AND pse__Resource__r.pse__salesforce_user__c = :userId AND pse__Resource__r.Recordtype.Name = \'PSA Resource\' '
            + ' ORDER BY CreatedDate DESC LIMIT 1) '
            + ' FROM Case WHERE IsClosed = false AND RecordTypeId = :psRecTypeId ';
        
        if(String.isNotBlank(view))
        {
            if(view == 'myopen')
            {
                caseBaseQuery = caseBaseQuery + ' AND OwnerId = \'' + UserInfo.getUserId() + '\' ';
            }
            else if(view == 'mycreated')
            {
                caseBaseQuery = caseBaseQuery + ' AND CreatedById = \'' + UserInfo.getUserId() + '\' ';
            }
            else if(view == 'myteam')
            {
                User currentUser = [Select Id,ManagerId FROM User WHERE Id = :Userinfo.getUserId()];
                Id managerId = currentUser.ManagerId;
                
                Map<Id,User> teamIDs = new Map<Id,User>();                
                teamIDs = new Map<Id,User>([SELECT ID FROM User WHERE ManagerId = :UserInfo.getUserId() AND IsActive = TRUE]);
                if(teamIDs.isEmpty())
                {
                    teamIDs = new Map<Id,User>([SELECT ID FROM User WHERE ManagerId = :managerId AND IsActive = TRUE]);
                }
                Set<Id> idKeySet = teamIDs.keySet();
                caseBaseQuery = caseBaseQuery + ' AND OwnerId IN :idKeySet ';
            }
        }
        
        String filterString = ''; String filterColour = '';
        if(filter != null)
        {
            if(filter.containsKey('sevValue') && filter.get('sevValue') != '1,2,3,4')
            {
                List<String> sevVal = filter.get('sevValue').split(',');
                filterString += ' AND Severity__c IN :sevVal ';
            }
            if(filter.containsKey('reqCompDateVal') && filter.get('reqCompDateVal').equalsIgnoreCase('true'))
            {
                System.debug(filter.get('reqCompDateVal'));
                filterString += ' AND Requested_Completion_Date_UTC__c >= TODAY AND Requested_Completion_Date_UTC__c <= NEXT_N_DAYS:2 ';
            }
            if(filter.containsKey('utilizedHoursValue') && String.isNotBlank(filter.get('utilizedHoursValue')) && !filter.get('utilizedHoursValue').contains('all'))
            {
                if(filter.get('utilizedHoursValue').contains('red'))
                    filterColour += 'red,';
                if(filter.get('utilizedHoursValue').contains('yellow'))
                    filterColour += 'yellow,';
            }
            if(filter.containsKey('nextActDateVal') && filter.get('nextActDateVal').equalsIgnoreCase('true'))
            {
                filterString += ' AND Next_Planned_Activity_Date__c < TODAY ';
            }    
        }
        
        if(String.isNotBlank(filterString))
        {
            caseBaseQuery += filterString;
        }
        if(userView == 'TSC')
        { caseBaseQuery += ' ORDER BY Age_days__c LIMIT 500';}
        else 
        {
            caseBaseQuery += ' ORDER BY Requested_Completion_Date_UTC__c NULLS LAST, Severity__c  LIMIT 500';
            //caseBaseQuery += ' ORDER BY Requested_Completion_Date_UTC__c NULLS LAST, Requested_Completion_Time_UTC__c NULLS LAST ';
        }
        
        System.debug(caseBaseQuery);
        lstCase = Database.query(caseBaseQuery);
        
        if(!lstCase.isEmpty())
        {
            for(Case eachCase : lstCase)
            {
                caseWrapRec = new CaseWrapper();
                caseWrapRec.akamCaseId = eachCase.AKAM_Case_ID__c;
                caseWrapRec.severity = eachCase.Severity__c;//Integer.valueOf(eachCase.Severity__c);
                caseWrapRec.caseUrl = '/' + eachCase.Id;
                caseWrapRec.caseRecId = eachCase.Id;
                caseWrapRec.accountName = eachCase.Account.Name;
                caseWrapRec.accountUrl = '/' + eachCase.AccountId;
                caseWrapRec.subject = eachCase.Subject;
                /*
                if(String.isNotBlank(eachCase.Subject))
                {
                    if(eachCase.Subject.length() >= 70)
                    {
                        caseWrapRec.subject = eachCase.Subject.substring(0,70) + '...';
                    }
                    else 
                    {
                        caseWrapRec.subject = eachCase.Subject;
                    }
                }
                */
                caseWrapRec.livingSummary = eachCase.Description;
                caseWrapRec.caseloe = eachCase.LOE_Hours__c != null ? String.valueOf(eachCase.LOE_Hours__c) : '❓';
                caseWrapRec.caseloeval = eachCase.LOE_Hours__c != null ? eachCase.LOE_Hours__c : null;
                
                if(!eachCase.Timecards__r.isEmpty())
                {
                    caseWrapRec.timecard = eachCase.Timecards__r[0].Id;
                    caseWrapRec.Project = eachCase.Timecards__r[0].pse__Project__c;
                    caseWrapRec.milestone = eachCase.Timecards__r[0].pse__Milestone__c;
                    caseWrapRec.projectProduct = eachCase.Timecards__r[0].pse__Project_Methodology_Object__c;
                }   
                else
                {
                    caseWrapRec.Project = eachCase.pse_Project__c;
                    caseWrapRec.milestone = eachCase.pse_Milestone__c;
                }
                
                caseWrapRec.Service = eachCase.Service__c;
                caseWrapRec.ReqType = eachCase.Request_Type__c;
                caseWrapRec.caseProductId = eachCase.Case_Product__c;
                caseWrapRec.caseProductName = eachCase.Case_Prod_Name__c;
                
                if(String.isNotBlank(String.valueOf(eachCase.Requested_Completion_Date_UTC__c)))
                {
                    caseWrapRec.reqCompletionDate = eachCase.Requested_Completion_Date_UTC__c.format();
                    caseWrapRec.reqCompletionDateVal = eachCase.Requested_Completion_Date_UTC__c;
                    if(eachCase.Requested_Completion_Date_UTC__c >= System.today() && eachCase.Requested_Completion_Date_UTC__c <= System.today().addDays(2))
                    {
                        caseWrapRec.reqCompletionDateColour = 'reqDateBrown';
                    }
                    else if(eachCase.Requested_Completion_Date_UTC__c < System.today())
                    {
                        caseWrapRec.reqCompletionDateColour = 'reqDateRed';
                    }
                }
                else
                {
                    caseWrapRec.reqCompletionDate = 'Enter Date';
                    caseWrapRec.reqCompletionDateVal = null;
                }
                
                caseWrapRec.ageDays = eachCase.Age_days__c;
                
                caseWrapRec.utilizedHours = 0;
                
                if(eachCase.Billable_Hours__c != null)
                {
                    caseWrapRec.utilizedHours += eachCase.Billable_Hours__c;
                    caseWrapRec.billableHours = eachCase.Billable_Hours__c;
                    if(eachCase.Billable_Hours__c > eachCase.LOE_Hours__c)
                    { caseWrapRec.billableHoursClass = 'slds-col numberCircle redBubble';}
                    else if(eachCase.LOE_Hours__c != null && eachCase.Billable_Hours__c >= (0.8 * eachCase.LOE_Hours__c))
                    {caseWrapRec.billableHoursClass = 'slds-col numberCircle yellowBubble';}
                    else {caseWrapRec.billableHoursClass = 'slds-col numberCircle darkGreyBubble';}
                }
                else {caseWrapRec.billableHours = 0; caseWrapRec.billableHoursClass = 'slds-col numberCircle darkGreyBubble';}
                
                if(eachCase.Non_Billable_Hours__c != null)
                {
                    caseWrapRec.utilizedHours += eachCase.Non_Billable_Hours__c;
                    caseWrapRec.nonbillableHours = eachCase.Non_Billable_Hours__c;
                }
                else {caseWrapRec.nonbillableHours = 0; }
                
                if(eachCase.Internal_Hours__c != null)
                {
                    caseWrapRec.utilizedHours += eachCase.Internal_Hours__c;
                    caseWrapRec.internalHours = eachCase.Internal_Hours__c;
                }
                else {caseWrapRec.internalHours = 0; }
                
                if(String.isNotBlank(String.valueOf(eachCase.Next_Planned_Activity_Date__c)))
                {
                    caseWrapRec.nextPlannedActivityDate = eachCase.Next_Planned_Activity_Date__c.format();
                    caseWrapRec.nextPlannedActivityDateVal = eachCase.Next_Planned_Activity_Date__c;
                }
                
                if(String.isNotBlank(eachCase.Living_Summary_Next_Steps__c))
                {
                    //caseWrapRec.livingSummary = eachCase.Living_Summary_Next_Steps__c;
                    lstLivingSummaryRows = eachCase.Living_Summary_Next_Steps__c.stripHtmlTags().split('\n');
                    if(!lstLivingSummaryRows.isEmpty())
                    {
                        if(lstLivingSummaryRows.size() >= 3)
                            caseWrapRec.livingSummaryTop3 = lstLivingSummaryRows[0] + '\n' + lstLivingSummaryRows[1] + '\n' + lstLivingSummaryRows[2];
                        else if(lstLivingSummaryRows.size() >= 2)
                            caseWrapRec.livingSummaryTop3 = lstLivingSummaryRows[0] + '\n' + lstLivingSummaryRows[1];
                        else caseWrapRec.livingSummaryTop3 = lstLivingSummaryRows[0];
                        caseWrapRec.livingSummaryConcat = lstLivingSummaryRows[0].length() > 70 ? lstLivingSummaryRows[0].substring(0,70) + '...' : lstLivingSummaryRows[0];
                    }
                }
                
                caseWrapRec.caseAckButtonIcon = 'utility:like';
                if(eachCase.Case_Acknowledged__c)
                {
                    caseWrapRec.disableCaseAckButton = true;
                    caseWrapRec.caseAckButtonBgClass = 'brand';
                }
                else
                {
                    caseWrapRec.disableCaseAckButton = false;
                    caseWrapRec.caseAckButtonBgClass = 'neutral';
                    //caseWrapRec.caseAckButtonIcon = 'utility:like';
                }
                
                caseWrapRec.caseCreator = eachCase.CreatedBy.Name;
                caseWrapRec.status = eachCase.Status;
                
                caseWrapRec.ownerId = eachCase.OwnerId;
                
                if(String.isNotBlank(view) && (view == 'mycreated' || view == 'myteam'))
                {
                    caseWrapRec.userNameRoleUrl = '/' + eachCase.OwnerId;
                    if(eachCase.Owner.Type == 'User')
                    {
                        caseWrapRec.userNameRole = eachCase.Owner.FirstName;
                    }
                    else
                    {
                        caseWrapRec.userNameRole = eachCase.Owner.Name;
                    }
                }
                else if(String.isNotBlank(view) && view == 'myopen' && String.valueOf(eachCase.OwnerId).equalsIgnoreCase(UserInfo.getUserId()))
                {
                    caseWrapRec.userNameRole = eachCase.CreatedBy.FirstName;
                    caseWrapRec.userNameRoleUrl = '/' + eachCase.CreatedById;
                }
                
                if(String.isBlank(filterColour) || (String.isNotBlank(filterColour) && 
                                                    (filterColour.contains('red') && caseWrapRec.billableHoursClass.contains('red')) 
                                                    || (filterColour.contains('yellow') && caseWrapRec.billableHoursClass.contains('yellow'))))
                {
                    lstMyCaseWrapper.add(caseWrapRec);
                }
            }
        }
        return lstMyCaseWrapper;
    }
    
    @AuraEnabled
    public static String updateCaseLivingSummaryAndTimecard(String caseLivingSummaryInbound, String caseId,String akamCaseId, Boolean logForYesterday,
                                                            String projId, String milestoneId, String productId, String caseWhatWork, Decimal caseHowLong, Date caseNextActDate, Decimal bestGuess)
    {
        /* **************************************************** TIMECARD UPDATE ************************************************** */
        System.debug(caseLivingSummaryInbound);
        String returnMssg = 'Case and Timecard successfully updated';
        
        List<pse__Timecard_Header__c> timecardRecList = new List<pse__Timecard_Header__c>();
        pse__Timecard_Header__c timecardRec = new pse__Timecard_Header__c();
        
        Id contactId;
        pse__Milestone__c milestoneRec;
        pse__Assignment__c userAssignment;
        String milestoneType = 'nonbillable';
        List<sObject> lstSObjToInsert = new List<sObject>();
        
        //Datetime caseNextActivityDateTime = logForYesterday ? DateTime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0)) : DateTime.newInstance(caseNextActDate, Time.newInstance(0, 0, 0, 0));
        Datetime caseNextActivityDateTime = DateTime.newInstance(caseNextActDate, Time.newInstance(0, 0, 0, 0));
        
        Date assignmentDateVal = logForYesterday ? System.now().date().addDays(-1) : System.now().date();
        
        // calculate timecard startdate and enddate
        Date logWorkDate = logForYesterday ? System.today().addDays(-1) : System.today();
        Datetime logWorkDateTime = DateTime.newInstance(logWorkDate, Time.newInstance(0, 0, 0, 0));
        
        String currentDayOfWeek = logWorkDateTime.format('EEE');
        
        Date startDateVal = currentDayOfWeek == 'Sun' ? logWorkDate : logWorkDate.toStartOfWeek();
        Date endDateVal;
        
        Datetime dateForDayVal = DateTime.newInstance(startDateVal, Time.newInstance(0, 0, 0, 0));
        String dayOfWeek = dateForDayVal.format('EEE');
        
        if(dayOfWeek == 'Mon')
        {
            startDateVal = startDateVal.addDays(-1);
        }
        endDateVal = startDateVal.addDays(6);
        
        //System.assertEquals(startDateVal, endDateVal);
        
        Contact userContact = [SELECT Id FROM Contact where pse__is_resource__c = true AND pse__is_resource_active__c = true 
                               AND pse__salesforce_user__c = :UserInfo.getUserId() AND Recordtype.Name = 'PSA Resource' LIMIT 1];
        
        if(userContact == null)
        {
            throw new AuraHandledException('No active PSA Resource Contact found');
        }
        else
        {
            contactId = userContact.Id;
        }
        
        timecardRecList = [SELECT Id,pse__Sunday_Hours__c,pse__Monday_Hours__c,pse__Tuesday_Hours__c,pse__Wednesday_Hours__c,pse__Thursday_Hours__c,pse__Friday_Hours__c,pse__Saturday_Hours__c,
                           pse__Sunday_Notes__c,pse__Monday_Notes__c,pse__Tuesday_Notes__c,pse__Wednesday_Notes__c,pse__Thursday_Notes__c,pse__Friday_Notes__c,pse__Saturday_Notes__c,
                           pse__Milestone__r.RecordType.Name,pse__Milestone__r.Billable__c
                           FROM pse__Timecard_Header__c 
                           WHERE pse__Start_Date__c = :startDateVal AND pse__End_Date__c = :endDateVal
                           AND pse__Status__c = 'Saved'
                           AND Case__c = :caseId AND pse__Project__c = :projId 
                           AND pse__Milestone__c = :milestoneId AND pse__Project_Methodology_Object__c = :productId
                           AND pse__Resource__c = :contactId ORDER BY LastModifiedDate DESC LIMIT 1 
                          ];
        
        // Timecard present, update hours and notes
        if(!timecardRecList.isEmpty())        
        {
            timecardRec = timecardRecList[0];
            if(timecardRec.pse__Milestone__r.Billable__c)
            {
                milestoneType = 'billable';
            }
            else if(timecardRec.pse__Milestone__r.RecordType.Name == 'Task Milestone: Internal')
            {
                milestoneType = 'internal';
            }
            
            switch on currentDayOfWeek 
            {
                when 'Sun' 
                {timecardRec.pse__Sunday_Hours__c += caseHowLong; 
                 timecardRec.pse__Sunday_Notes__c = String.isNotBlank(timecardRec.pse__Sunday_Notes__c) ? akamCaseId + ': ' + caseWhatWork + '\n' + timecardRec.pse__Sunday_Notes__c : akamCaseId + ': ' + caseWhatWork;}   
                when 'Mon' 
                {timecardRec.pse__Monday_Hours__c += caseHowLong;
                 timecardRec.pse__Monday_Notes__c = String.isNotBlank(timecardRec.pse__Monday_Notes__c) ? akamCaseId + ': ' + caseWhatWork + '\n' + timecardRec.pse__Monday_Notes__c : akamCaseId + ': ' + caseWhatWork;}   
                when 'Tue' 
                {timecardRec.pse__Tuesday_Hours__c += caseHowLong;
                 timecardRec.pse__Tuesday_Notes__c = String.isNotBlank(timecardRec.pse__Tuesday_Notes__c) ? akamCaseId + ': ' + caseWhatWork + '\n' + timecardRec.pse__Tuesday_Notes__c : akamCaseId + ': ' + caseWhatWork;}
                when 'Wed' 
                {timecardRec.pse__Wednesday_Hours__c += caseHowLong;
                 timecardRec.pse__Wednesday_Notes__c = String.isNotBlank(timecardRec.pse__Wednesday_Notes__c) ? akamCaseId + ': ' + caseWhatWork + '\n' + timecardRec.pse__Wednesday_Notes__c : akamCaseId + ': ' + caseWhatWork;}
                when 'Thu' 
                {timecardRec.pse__Thursday_Hours__c += caseHowLong;
                 timecardRec.pse__Thursday_Notes__c = String.isNotBlank(timecardRec.pse__Thursday_Notes__c) ? akamCaseId + ': ' + caseWhatWork + '\n' + timecardRec.pse__Thursday_Notes__c : akamCaseId + ': ' + caseWhatWork;}
                when 'Fri' 
                {timecardRec.pse__Friday_Hours__c += caseHowLong;
                 timecardRec.pse__Friday_Notes__c = String.isNotBlank(timecardRec.pse__Friday_Notes__c) ? akamCaseId + ': ' + caseWhatWork + '\n' + timecardRec.pse__Friday_Notes__c : akamCaseId + ': ' + caseWhatWork;}
                when 'Sat' 
                {timecardRec.pse__Saturday_Hours__c += caseHowLong;
                 timecardRec.pse__Saturday_Notes__c = String.isNotBlank(timecardRec.pse__Saturday_Notes__c) ? akamCaseId + ': ' + caseWhatWork + '\n' + timecardRec.pse__Saturday_Notes__c : akamCaseId + ': ' + caseWhatWork;}
            }
            
            try
            {
                update timecardRec;
            }
            catch(Exception e)
            {
                throw new AuraHandledException(CommonUtilClass.extractValidationErrorMsg(e));
            }
        }
        // New Timecard, populate all relevant lookup fields and hours and notes
        // changes by Vandhana - changed the date filter to timecard log date and not start/end of week
        else
        {
            pse__Proj__c projRec = [SELECT Id,pse__Allow_Self_Staffing__c,pse__Allow_Timecards_Without_Assignment__c,RecordType.Name,pse__Is_Billable__c,pse__End_Date__c,pse__Start_Date__c,
                                    (SELECT Id,Billable__c,RecordType.Name FROM pse__Milestones__r WHERE Id = :milestoneId),
                                    //(SELECT Id, Product__c FROM pse__Project_Methodologies__r WHERE Id = :productId),
                                    (SELECT Id,Name 
                                     FROM pse__Assignments__r 
                                     WHERE pse__resource__r.pse__salesforce_user__c = :UserInfo.getUserId() 
                                     AND pse__Closed_for_Time_Entry__c = false 
                                     AND pse__project__c = :projId
                                     AND pse__project__r.pse__Allow_Timecards_Without_Assignment__c = false 
                                     AND pse__project__r.pse__Closed_for_Time_Entry__c = false 
                                     //AND pse__Start_Date__c <= :startDateVal and pse__End_Date__c >= :endDateVal 
                                     AND pse__Start_Date__c <= :assignmentDateVal and pse__End_Date__c >= :assignmentDateVal 
                                     ORDER BY pse__End_Date__c DESC LIMIT 1)
                                    FROM pse__Proj__c
                                    WHERE Id = :projId];
            
            milestoneRec = !projRec.pse__Milestones__r.isEmpty() ? projRec.pse__Milestones__r[0] : null;
            
            timecardRec.pse__Billable__c = false;
            if(milestoneRec != null)
            {
                if(milestoneRec.Billable__c)
                {
                    milestoneType = 'billable';
                    timecardRec.pse__Billable__c = true;
                }
                else if(milestoneRec.RecordType.Name == 'Task Milestone: Internal')
                {
                    milestoneType = 'internal';
                }
            }
            
            userAssignment = !projRec.pse__Assignments__r.isEmpty() ? projRec.pse__Assignments__r[0] : null;
            
            if(userAssignment == null)
            {
                if(projRec.pse__Allow_Self_Staffing__c && !projRec.pse__Allow_Timecards_Without_Assignment__c)
                {
                    pse__Schedule__c schedule = new pse__Schedule__c();
                    pse__Schedule__c scheduleLookUp = new pse__Schedule__c();
                    pse__Assignment__c newAssignment = new pse__Assignment__c();
                    pse__Assignment__c assignmentLookUp = new pse__Assignment__c();
                    
                    schedule.pse__Start_Date__c = projRec.pse__Start_Date__c; //Date.today();
                    schedule.pse__End_Date__c = projRec.pse__End_Date__c;
                    schedule.pse__Scheduled_Hours__c = 1;
                    schedule.External_Look__c = String.valueOf(caseId) + String.valueOf(projRec.id) + String.valueOf(contactId) + String.valueOf(System.now());
                    lstSObjToInsert.add(schedule);
                    
                    //Create another schedule record and set the external id of this record to the external id of the above created record.
                    scheduleLookUp = new pse__Schedule__c();
                    scheduleLookUp.External_Look__c = schedule.External_Look__c;
                    
                    //Create the assignment record. Set the resource and project look-ups. The schedule lookup is set to the scheduleLookUp record which references the schedule record. At the time of assignment creation, the lookup is set to the referenced record's ID
                    newAssignment.pse__Resource__c = contactId;
                    newAssignment.pse__Project__c = projRec.id;
                    newAssignment.pse__Bill_Rate__c = 0;
                    newAssignment.External_Id__c = String.valueOf(caseId) + String.valueOf(projRec.id) + String.valueOf(contactId) + String.valueOf(System.now());
                    newAssignment.pse__Schedule__r = scheduleLookUp;
                    lstSObjToInsert.add(newAssignment);
                    
                    userAssignment = new pse__Assignment__c();
                    userAssignment.External_Id__c = newAssignment.External_Id__c;  
                    returnMssg = 'Project Assignment did not exist, as self-staffing was allowed on Project, the Assignment was auto-created on the Project and Timecard saved successfully';
                }
                else if(!projRec.pse__Allow_Self_Staffing__c && !projRec.pse__Allow_Timecards_Without_Assignment__c)
                {
                    throw new AuraHandledException('Update failed as Assignment does not exist and the Project does not allow self-staffing. Please contact the Project Owner to create the Assignment');
                }   
            }
            
            timecardRec.pse__Start_Date__c = startDateVal;
            timecardRec.pse__End_Date__c = endDateVal;
            timecardRec.pse__Status__c = 'Saved';
            timecardRec.Case__c = caseId;
            timecardRec.pse__Project__c = projId;
            if(!projRec.pse__Allow_Timecards_Without_Assignment__c && userAssignment != null && String.isNotBlank(userAssignment.Id))
            {
                timecardRec.pse__Assignment__c = userAssignment.Id;
            }
            else if(userAssignment != null && String.isBlank(userAssignment.Id))
            {
                timecardRec.pse__Assignment__r = userAssignment;
            }
            
            timecardRec.pse__Milestone__c = milestoneId;
            timecardRec.pse__Project_Methodology_Object__c = productId;
            timecardRec.pse__Resource__c = contactId;
            lstSObjToInsert.add(timecardRec);
            
            switch on currentDayOfWeek 
            {
                when 'Sun' {timecardRec.pse__Sunday_Hours__c = caseHowLong; timecardRec.pse__Sunday_Notes__c = akamCaseId + ': ' + caseWhatWork;}   
                when 'Mon' {timecardRec.pse__Monday_Hours__c = caseHowLong; timecardRec.pse__Monday_Notes__c = akamCaseId + ': ' + caseWhatWork;}   
                when 'Tue' {timecardRec.pse__Tuesday_Hours__c = caseHowLong; timecardRec.pse__Tuesday_Notes__c = akamCaseId + ': ' + caseWhatWork;} 
                when 'Wed' {timecardRec.pse__Wednesday_Hours__c = caseHowLong; timecardRec.pse__Wednesday_Notes__c = akamCaseId + ': ' + caseWhatWork;}
                when 'Thu' {timecardRec.pse__Thursday_Hours__c = caseHowLong; timecardRec.pse__Thursday_Notes__c = akamCaseId + ': ' + caseWhatWork;}
                when 'Fri' {timecardRec.pse__Friday_Hours__c = caseHowLong; timecardRec.pse__Friday_Notes__c = akamCaseId + ': ' + caseWhatWork;}
                when 'Sat' {timecardRec.pse__Saturday_Hours__c = caseHowLong; timecardRec.pse__Saturday_Notes__c = akamCaseId + ': ' + caseWhatWork;}
            }
            try
            {
                insert lstSObjToInsert;
                //insert timecardRec;
            }
            catch(Exception e)
            {
                throw new AuraHandledException(CommonUtilClass.extractValidationErrorMsg(e));
            }
        }
        
        
        /* **************************************** CASE LIVING SUMMARY UPDATE ************************************************** */
        
        Case caseToUpdate = [SELECT Living_Summary_Next_Steps__c,Next_Planned_Activity_Date__c,Billable_Hours__c,Non_Billable_Hours__c,Internal_Hours__c,Best_guess_of_remaining_LOE__c 
                             FROM Case 
                             WHERE Id = :caseId
                             FOR UPDATE];
        
        DateTime dateToStamp = logForYesterday ? System.now().addDays(-1) : System.now();
                
        String livingSummary = '* ' + dateToStamp.day() + ' ' + dateToStamp.format('MMM') + caseLivingSummaryInbound + ' | Next Activity: ' + caseNextActivityDateTime.day() + ' ' + caseNextActivityDateTime.format('MMM') + ' | ' + UserInfo.getName() + '<br/>';
        
        caseToUpdate.Living_Summary_Next_Steps__c = String.isNotBlank(caseToUpdate.Living_Summary_Next_Steps__c) ? 
            livingSummary + caseToUpdate.Living_Summary_Next_Steps__c
            : livingSummary;
        
        if(milestoneType == 'internal')
        {
            caseToUpdate.Internal_Hours__c = caseToUpdate.Internal_Hours__c != null ? caseToUpdate.Internal_Hours__c + caseHowLong : caseHowLong;
        }
        else if(milestoneType == 'billable')
        {
            caseToUpdate.Billable_Hours__c = caseToUpdate.Billable_Hours__c != null ? caseToUpdate.Billable_Hours__c + caseHowLong : caseHowLong;
        }
        else if(milestoneType == 'nonbillable')
        {
            caseToUpdate.Non_Billable_Hours__c = caseToUpdate.Non_Billable_Hours__c != null ? caseToUpdate.Non_Billable_Hours__c + caseHowLong : caseHowLong;
        }
        
        //caseToUpdate.Next_Planned_Activity_Date__c = logForYesterday ? System.today() : caseNextActDate;
        caseToUpdate.Next_Planned_Activity_Date__c = caseNextActDate;
        caseToUpdate.Best_guess_of_remaining_LOE__c = bestGuess;
        
        try
        {
            update caseToUpdate;
        }
        catch(Exception e)
        {
            throw new AuraHandledException(CommonUtilClass.extractValidationErrorMsg(e));
        }
        
        return returnMssg;
    }
    
    public class SelectOption 
    {
        public SelectOption(String value, String label) 
        {
            this.value = value;
            this.label = label;
        }
        
        @AuraEnabled
        public String label { get;set; }
        @AuraEnabled
        public String value { get;set; }
    }
    
    // changes by Vandhana for ESESP-4581 : commented out date filter for Milestones
    @AuraEnabled
    public static Map<String,List<SelectOption>> fetchProjectMilestonesAndProducts(Id projId)
    {
        pse__Proj__c selectedProj = [SELECT Id,pse__Allow_Self_Staffing__c,pse__Allow_Timecards_Without_Assignment__c,RecordType.Name,pse__Is_Billable__c,
                                     pse__Closed_for_Time_Entry__c,pse__Start_Date__c,pse__End_Date__c,pse__Stage__c
                                     FROM pse__Proj__c 
                                     WHERE Id = :projId LIMIT 1
                                    ];
       
        if(selectedProj.pse__End_Date__c < System.today() || selectedProj.pse__Closed_for_Time_Entry__c || selectedProj.pse__Stage__c == 'Closed')
        {
            throw new AuraHandledException('Selected Project is inactive and does not accept Timecards. Please select a different Project or contact the Project Owner to change the Project status');
        }
        else
        {
            Map<String,List<SelectOption>> returnSelectOptions = new Map<String,List<SelectOption>>();
            
            List<pse__Milestone__c> lstMilestones = new List<pse__Milestone__c>();
            List<SelectOption> milestoneOptions = new List<SelectOption>();
            
            lstMilestones = [SELECT Name FROM pse__Milestone__c 
                             WHERE pse__Project__c = :projId 
                             //AND Start_Date__c <= TODAY AND pse__Target_Date__c >= TODAY
                             AND pse__Closed_for_Time_Entry__c != true
                             ORDER BY Name
                            ];
            
            for(pse__Milestone__c eachMilestone : lstMilestones)
            {
                milestoneOptions.add(new SelectOption(eachMilestone.Id,eachMilestone.Name));
            }
            returnSelectOptions.put('milestones', milestoneOptions);
            
            List<pse__Project_Methodology__c> lstProducts = new List<pse__Project_Methodology__c>();
            List<SelectOption> productOptions = new List<SelectOption>();
            
            lstProducts = [SELECT Product__c FROM pse__Project_Methodology__c 
                           WHERE pse__Project__c = :projId
                           ORDER BY Product__c
                          ];
            
            for(pse__Project_Methodology__c eachProduct : lstProducts)
            {
                productOptions.add(new SelectOption(eachProduct.Id,eachProduct.Product__c));
            }
            returnSelectOptions.put('products', productOptions);
            return returnSelectOptions;
        }
    }
    
    @AuraEnabled
    public static List<SelectOption> fetchAccountActiveProjects(Id accId)
    {
        List<pse__Proj__c> lstAccActProj = new List<pse__Proj__c>();
        lstAccActProj = [SELECT Id,Name
                         FROM pse__Proj__c 
                         WHERE pse__End_Date__c >= TODAY AND pse__Start_Date__c <= TODAY
                         AND pse__Closed_for_Time_Entry__c != true AND pse__Stage__c != 'Closed'
                         AND pse__Account__c = :accId 
                         ORDER BY Name
                         LIMIT 500
                        ];
        
        List<SelectOption> projectOptions = new List<SelectOption>();
        
        for(pse__Proj__c eachProj : lstAccActProj)
        {
            projectOptions.add(new SelectOption(eachProj.Id,eachProj.Name));
        }
        if(!projectOptions.isEmpty())
        {
            projectOptions.add(0,new SelectOption('','--None--'));
        }
        return projectOptions;
    }
    
    @AuraEnabled
    public static List<SelectOption> accountOption(Id accountId)
    {
        Account selectedAcc = [SELECT Id,Name
                               FROM Account 
                               WHERE Id = :accountId LIMIT 1];
        
        List<SelectOption> accountOption = new List<SelectOption>();
        accountOption.add(new SelectOption(selectedAcc.Id,selectedAcc.Name));
        return accountOption;
    }
    
    @AuraEnabled
    public static List<SelectOption> fetchSavedAccountForMultiClone()
    {
        List<SelectOption> accountOption = new List<SelectOption>();
        
        String ucdRecTypeId = Schema.SObjectType.SC_User_Filter__c.getRecordTypeInfosByName().get('UCD').getRecordTypeId();
        String userId = UserInfo.getUserId() + '-' + ucdRecTypeId;
        string serializedfilter;
        
        List<SC_User_Filter__c> searchedCases = new List<SC_User_Filter__c>();
        searchedCases = [SELECT Id,filter_values__c FROM SC_User_Filter__c WHERE Unique_ID__c = :userId LIMIT 1];
        if(searchedCases.size() > 0)
        {
            map<string,object> master_filter_values = (Map<String, object>) JSON.deserializeUntyped (searchedCases[0].filter_values__c);
            if(master_filter_values.containsKey('searchedAccounts'))
            {	
                String searchedCaseList = String.valueOf(master_filter_values.get('searchedAccounts'));
                List<String> accIds = searchedCaseList.split(',');
                List<Account> selectedAcc = [SELECT Id,Name
                                             FROM Account 
                                             WHERE Id IN :accIds LIMIT 10];
                for(Account acc : selectedAcc)
                {
                    accountOption.add(new SelectOption(acc.Id,acc.Name));
                }
            }
        }
        return accountOption;
    }
    
    @AuraEnabled
    public static String fetchCaseLivingSummary(String caseRecId)
    {
        Case caseRec = [SELECT Living_Summary_Next_Steps__c FROM Case WHERE Id = :caseRecId];
        return caseRec.Living_Summary_Next_Steps__c;
    }
    
    @AuraEnabled
    public static void updateCaseLOE(String caseId,Decimal newLOE,String loeReason)
    {
        Id userId = UserInfo.getUserId();
        Decimal oldLOE = null;
        
        Case caseRec = [SELECT Id,LOE_Hours__c,LOE_Change_Reason__c,(SELECT Id, pse__Project__r.Project_Manager_Email__c
                                                                     FROM Timecards__r 
                                                                     WHERE pse__Resource__r.pse__is_resource__c = true
                                                                     AND pse__Resource__r.pse__is_resource_active__c = true AND pse__Resource__r.pse__salesforce_user__c = :userId AND pse__Resource__r.Recordtype.Name = 'PSA Resource'
                                                                     ORDER BY CreatedDate DESC LIMIT 1),
                        CreatedBy.Email,Owner.Email,Account.Name
                        FROM Case WHERE Id = :caseId];
        
        if(String.isNotBlank(caseRec.LOE_Change_Reason__c))
        {
            caseRec.LOE_Change_Reason__c = caseRec.LOE_Hours__c != null ? 'LOE changed from ' + caseRec.LOE_Hours__c + ' to ' + newLOE + '|' + loeReason + '|' + Userinfo.getName() + '|' + System.today().format() + '\n' + caseRec.LOE_Change_Reason__c : 'LOE changed to ' + newLOE + '|' + loeReason + '|' + Userinfo.getName() + '|' + System.today().format() + '\n';
        }
        else
        {
            caseRec.LOE_Change_Reason__c = caseRec.LOE_Hours__c != null ? 'LOE changed from ' + caseRec.LOE_Hours__c + ' to ' + newLOE + '|' + loeReason + '|' + Userinfo.getName() + '|' + System.today().format() : 'LOE changed to ' + newLOE + '|' + loeReason + '|' + Userinfo.getName() + '|' + System.today().format();
        }
        
        oldLOE = caseRec.LOE_Hours__c;
        caseRec.LOE_Hours__c = newLOE;
        
        try
        {update caseRec;}
        catch(Exception e)
        {
            throw new AuraHandledException(CommonUtilClass.extractValidationErrorMsg(e));
        }
        
        emailLOEChange(caseId,oldLOE,newLOE,loeReason);
    }
    
    @future
    public static void emailLOEChange(String caseId,Decimal oldLOE,Decimal newLOE, String loeReason)
    {
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>(); 
        Messaging.SingleEmailMessage emailMsg = new Messaging.SingleEmailMessage();
        List<String> toAddresses = new List<String>();
        Id userId = UserInfo.getUserId();
        
        Case caseRec = [SELECT Id,LOE_Hours__c,LOE_Change_Reason__c,AccountId,(SELECT Id, pse__Project__r.Project_Manager_Email__c
                                                                               FROM Timecards__r 
                                                                               WHERE pse__Resource__r.pse__is_resource__c = true
                                                                               AND pse__Resource__r.pse__is_resource_active__c = true AND pse__Resource__r.pse__salesforce_user__c = :userId AND pse__Resource__r.Recordtype.Name = 'PSA Resource'
                                                                               ORDER BY CreatedDate DESC LIMIT 1),
                        CreatedBy.Email,Owner.Email,Account.Name,AKAM_Case_ID__c
                        FROM Case WHERE Id = :caseId];
        
        
        /*
        List<AccountTeamMember> lstAccTeamMem = new List<AccountTeamMember>();
        lstAccTeamMem = [SELECT AccountId,User.Email
                         FROM AccountTeamMember 
                         WHERE AccountId = :caseRec.AccountId 
                         AND TeamMemberRole = 'Services - Primary' 
                         AND User.IsActive = true];
        */

        Id noReply = SC_FromEmailAddress__c.getValues('Noreply').OrgAddressId__c;
        String noReplyEmailId = [SELECT Value_text__c FROM SC_Utility__mdt where DeveloperName = 'no_reply_id'].Value_text__c;
        
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/';
        String changeText = oldLOE != null ? ' has been updated from ' + oldLOE + ' hours to ' + newLOE + ' hours by ' + UserInfo.getName() + '.<br />Reason: ' +  loeReason : ' has been updated to ' + newLOE + ' hours by ' + UserInfo.getName()+ '.<br />Reason: ' +  loeReason ;
        String emailBody = 'This email is to notify you that the LOE for the case ' + '<a href="'+ baseUrl + caseRec.Id +'">' + caseRec.AKAM_Case_ID__c + '</a>' + changeText;
        
        toAddresses.add(caseRec.CreatedBy.Email);
        if(String.isNotBlank(caseRec.Owner.Email))
        {
            toAddresses.add(caseRec.Owner.Email);
        }
        if(!caseRec.Timecards__r.isEmpty())
        {
            if(String.isNotBlank(caseRec.Timecards__r[0].pse__Project__r.Project_Manager_Email__c))
            {
                toAddresses.add(caseRec.Timecards__r[0].pse__Project__r.Project_Manager_Email__c);
            }
        }  

        /*
        for(AccountTeamMember eachATM : lstAccTeamMem)
        {
            if(String.isNotBlank(eachATM.User.Email))
            {toAddresses.add(eachATM.User.Email);}
        }
        */

        System.debug(toAddresses);
        emailMsg.setToAddresses(toAddresses);
        emailMsg.setOrgWideEmailAddressId(noReply);
        emailMsg.setReplyTo(noReplyEmailId); 
        emailMsg.setWhatId(caseRec.Id);
        emailMsg.setSubject('LOE update notification for Case [' + caseRec.AKAM_Case_ID__c + '] for ' + caseRec.Account.Name);
        emailMsg.setHTMLBody(emailBody);
        emailList.add(emailMsg);
        Messaging.sendEmail(emailList);
    }
    
    @AuraEnabled
    public static Id getPSCaseRecTypeId()
    {
        Id psRecTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        return psRecTypeId;
    }
    
    @AuraEnabled
    public static String cloneSingleCase(String caseId) 
    {
        String caseQuery = 'Select Id,';
        Map<String, Schema.Sobjectfield> CaseFieldMap = Case.sObjectType.getDescribe().fields.getMap();
        
        for(String caseFlds : CaseFieldMap.keySet())
        {    
            Schema.DescribeFieldResult caseField = CaseFieldMap.get(caseFlds).getDescribe();
            if(caseField.isUpdateable())
            {
                caseQuery += caseFlds + ',';
            }
        }
        caseQuery = caseQuery.substring(0, caseQuery.length()-1);
        if(!caseQuery.containsIgnoreCase('AKAM_Case_ID__c')) 
        {
            caseQuery += ',AKAM_Case_ID__c';
        }
        caseQuery += ' FROM Case WHERE Id = :caseId';
        Case caseRec = Database.query(caseQuery);
        
        Case newCase = caseRec.clone(false,true);
        newCase.AKAM_Case_ID__c = null;
        newCase.Status = 'Assigned';
        newCase.OwnerId = UserInfo.getUserId();
        newCase.Case_Assignment_Using_Active_Rules__c = true;
        newCase.AKAM_Closed_Date__c = newCase.Resolved_Date__c = newCase.Last_Case_Update__c = newCase.Last_Customer_Activity_Date__c = newCase.Last_Case_Owner_Update__c = null;
        newCase.Last_Non_Case_Owner_Update__c = newCase.Next_Planned_Activity_Date__c = null;
        newCase.Living_Summary_Next_Steps__c = null;
        newCase.Reopened__c = newCase.Case_Acknowledged__c = false; 
        newCase.LOE_Change_Reason__c = null;
        newCase.LOE_Hours__c = newCase.Billable_Hours__c = newCase.Non_Billable_Hours__c = newCase.Internal_Hours__c = 0;
        newCase.Shift_Owner__c = null;
        
        try
        {
            insert newCase;
            return newCase.Id;
        }
        catch (exception e) 
        {
            throw new AuraHandledException(CommonUtilClass.extractValidationErrorMsg(e));
        }   
    }
    
    @AuraEnabled
    public static void cloneMultiCase(String caseId, List<String> lstAccId) 
    {
        List<Case> lstClonedCases = new List<Case>();
        String caseQuery = 'Select Id,';
        Map<String, Schema.Sobjectfield> CaseFieldMap = Case.sObjectType.getDescribe().fields.getMap();
        
        for(String caseFlds : CaseFieldMap.keySet())
        {    
            Schema.DescribeFieldResult caseField = CaseFieldMap.get(caseFlds).getDescribe();
            if(caseField.isUpdateable())
            {
                caseQuery += caseFlds + ',';
            }
        }
        caseQuery = caseQuery.substring(0, caseQuery.length()-1);
        if(!caseQuery.containsIgnoreCase('AKAM_Case_ID__c')) 
        {
            caseQuery += ',AKAM_Case_ID__c';
        }
        caseQuery += ' FROM Case WHERE Id = :caseId';
        Case caseRec = Database.query(caseQuery);
        
        for(String eachAccountId : lstAccId)
        {
            Case newCase = caseRec.clone(false,true);
            newCase.AKAM_Case_ID__c = null;
            newCase.AccountId = eachAccountId;
            //newCase.Status = 'Assigned';
            newCase.ContactId = null;
            newCase.Case_Product__c = null;
            newCase.pse_Milestone__c = null;
            newCase.pse_Project__c = null;
            newCase.Close_Code__c = null;
            newCase.OwnerId = UserInfo.getUserId();
            newCase.Case_Assignment_Using_Active_Rules__c = true;
            
            newCase.AKAM_Closed_Date__c = newCase.Resolved_Date__c = newCase.Last_Case_Update__c = newCase.Last_Customer_Activity_Date__c = newCase.Last_Case_Owner_Update__c = null;
            newCase.Last_Non_Case_Owner_Update__c = newCase.Next_Planned_Activity_Date__c = null;
            newCase.Reopened__c = newCase.Case_Acknowledged__c = false; 
            newCase.LOE_Change_Reason__c = newCase.Living_Summary_Next_Steps__c = null;
            newCase.Billable_Hours__c = newCase.Non_Billable_Hours__c = newCase.Internal_Hours__c = 0;
            newCase.Contract__c = newCase.Shift_Owner__c = null;
            //newCase.LOE_Hours__c = 0;
            lstClonedCases.add(newCase);
        }
        try
        {
            insert lstClonedCases;
        }
        catch (exception e) 
        {
            throw new AuraHandledException(CommonUtilClass.extractValidationErrorMsg(e));
        }   
        saveMultiCloneAccount(lstAccId);
    }
    
    @future
    public static void saveMultiCloneAccount(List<String> lstAccId)
    {
        String ucdRecTypeId = Schema.SObjectType.SC_User_Filter__c.getRecordTypeInfosByName().get('UCD').getRecordTypeId();
        String userId = UserInfo.getUserId() + '-' + ucdRecTypeId;
        string serializedfilter;
        String searchedAccList;
        List<String> lstToSave = new List<String>();
        
        if(!lstAccId.isEmpty() && lstAccId.size() >= 10)
        {
            for(Integer i=0; i<10; i++)
            {
                lstToSave.add(lstAccId[i]);
            }
            searchedAccList = String.join(lstToSave,',');
        }
        else {searchedAccList = String.join(lstAccId,',');}
        
        List<SC_User_Filter__c> searchedCases = new List<SC_User_Filter__c>();
        searchedCases = [SELECT Id,filter_values__c FROM SC_User_Filter__c WHERE Unique_ID__c = :userId LIMIT 1];
        if(searchedCases.size() > 0)
        {
            Map<String,Object> master_filter_values = (Map<String, Object>) JSON.deserializeUntyped(searchedCases[0].filter_values__c);
            master_filter_values.put('searchedAccounts',searchedAccList);
            serializedfilter  = JSON.serialize(master_filter_values);
        }
        else
        {
            map<string, string> initialFilter = new map<string,string>();
            initialFilter.put('searchedAccounts',searchedAccList);
            serializedfilter  = JSON.serialize(initialFilter);
        }            
        
        SC_User_Filter__c upsertUserData = new SC_User_Filter__c(Unique_ID__c = userid, filter_values__c = serializedfilter, recordtypeid = ucdRecTypeId);
        
        upsert upsertUserData Unique_ID__c; 
    }
    
    @AuraEnabled
    public static void acknowledgeCase(String caseId)
    {
        Case caseRec = [SELECT Id,CreatedBy.Name,Owner.Name,AKAM_Case_ID__c,Subject,CreatedBy.Email,Status FROM Case WHERE Id = :caseId];
        caseRec.Case_Acknowledged__c = true;
        caseRec.Status = 'Work in Progress';
        caseRec.Validation_Override__c = true;
        try
        {
            update caseRec;
            emailAcknowledgeCase(caseRec.CreatedBy.Email,caseRec.Id,caseRec.AKAM_Case_ID__c,caseRec.Subject);
        }
        catch(Exception e)
        {
            throw new AuraHandledException(CommonUtilClass.extractValidationErrorMsg(e));
        }
    }

	@future
    public static void emailAcknowledgeCase(String createdByEmail,String caseId,String caseAkamCaseId, String caseSubject)
    {		
        Id noReply = SC_FromEmailAddress__c.getValues('Noreply').OrgAddressId__c;
        Map<String,String> mapMDTVals = new Map<String,String>();
        List<SC_Utility__mdt> lstMDT = [SELECT DeveloperName,Value_text__c FROM SC_Utility__mdt where DeveloperName IN ('no_reply_id','UCD_ps_tix_email')];
        
        for(SC_Utility__mdt eachMDT : lstMDT)
        {
            mapMDTVals.put(eachMDT.DeveloperName,eachMDT.Value_text__c);
        }
        
        Messaging.SingleEmailMessage emailMsg = new Messaging.SingleEmailMessage();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>(); 
        
        String emailBody = 'I acknowledge receiving this case and I’m aware of the Requested Completion Date and Time.<br/> I will review details and contact case creator if there are further questions about the requirements and timeline. <br><br/>Thanks,<br/>' + UserInfo.getName();        
        List<String> toAddresses = new List<String>();
        List<String> ccAddresses = new List<String>();
        
        toAddresses.add(createdByEmail);
        ccAddresses.add(mapMDTVals.get('UCD_ps_tix_email'));
        
        emailMsg.setOrgWideEmailAddressId(noReply);
        emailMsg.setReplyTo(mapMDTVals.get('no_reply_id'));
        emailMsg.setToAddresses(toAddresses);   
        emailMsg.setCcAddresses(ccAddresses);   
        emailMsg.setWhatId(caseId);
        emailMsg.setSubject('[AKAM-CASE ' + caseAkamCaseId + '] - ' + caseSubject);
        emailMsg.setHTMLBody(emailBody);
        emailList.add(emailMsg);
        Messaging.sendEmail(emailList);        
    }  
    
    @AuraEnabled
    public static List<CaseWrapper> globalSearchAndRecentlyViewed(String akamCaseId, Boolean saveString)
    {        
        Map<String,CaseWrapper> mapAKAMIdCaseWrap = new Map<String,CaseWrapper>();
        List<CaseWrapper> lstMyCaseWrapper = new List<CaseWrapper>();
        CaseWrapper caseWrapRec = new CaseWrapper();
        List<Case> lstSearchedCase = new List<Case>();
        Id psRecTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        List<String> lstLivingSummaryRows = new List<String>();
        Id userId = UserInfo.getUserId();
        
        List<String> lstAKAMCaseIDs = new List<String>();
        List<CaseWrapper> lstFinalCaseWrap = new List<CaseWrapper>();
        
        System.debug(akamCaseId);
        
        if(akamCaseId.containsIgnoreCase(','))
        {
            lstAKAMCaseIDs = akamCaseId.split(',');
            
            lstSearchedCase = [SELECT AKAM_Case_ID__c,Severity__c,AccountId,Account.Name,Subject,LOE_Hours__c,Requested_Completion_Date_UTC__c,Requested_Completion_Time_UTC__c,
                               Age_days__c, Living_Summary_Next_Steps__c,Case_Owner_Name__c,CreatedBy.Name,Status,pse_Project__c,pse_Milestone__c,Next_Planned_Activity_Date__c,
                               Billable_Hours__c,Non_Billable_Hours__c,Internal_Hours__c, OwnerId, CreatedById, CreatedBy.FirstName,Owner.FirstName,Owner.Name,Owner.Type,
                               Case_Acknowledged__c,Case_Product__c,Case_Prod_Name__c,Description,Service__c,Request_Type__c,
                               (SELECT Id, pse__Milestone__c, pse__Project__c, pse__Assignment__c, pse__Start_Date__c, pse__End_Date__c, pse__Status__c, pse__Project_Methodology_Object__c
                                FROM Timecards__r WHERE pse__Resource__r.pse__is_resource__c = true
                                AND pse__Resource__r.pse__is_resource_active__c = true AND pse__Resource__r.pse__salesforce_user__c = :userId 
                                AND pse__Resource__r.Recordtype.Name = 'PSA Resource'
                                ORDER BY CreatedDate DESC LIMIT 1)
                               FROM Case WHERE IsClosed = false AND RecordTypeId = :psRecTypeId 
                               AND AKAM_Case_ID__c IN :lstAKAMCaseIDs
                              ];
        }
        else
        {
            lstSearchedCase = [SELECT AKAM_Case_ID__c,Severity__c,AccountId,Account.Name,Subject,LOE_Hours__c,Requested_Completion_Date_UTC__c,Requested_Completion_Time_UTC__c,
                               Age_days__c, Living_Summary_Next_Steps__c,Case_Owner_Name__c,CreatedBy.Name,Status,pse_Project__c,pse_Milestone__c,Next_Planned_Activity_Date__c,
                               Billable_Hours__c,Non_Billable_Hours__c,Internal_Hours__c, OwnerId, CreatedById, CreatedBy.FirstName,Owner.FirstName,Owner.Name,Owner.Type,
                               Case_Acknowledged__c,Case_Product__c,Case_Prod_Name__c,Description,Service__c,Request_Type__c,
                               (SELECT Id, pse__Milestone__c, pse__Project__c, pse__Assignment__c, pse__Start_Date__c, pse__End_Date__c, pse__Status__c, pse__Project_Methodology_Object__c
                                FROM Timecards__r WHERE pse__Status__c = 'Saved' AND pse__Resource__r.pse__is_resource__c = true
                                AND pse__Resource__r.pse__is_resource_active__c = true AND pse__Resource__r.pse__salesforce_user__c = :userId AND pse__Resource__r.Recordtype.Name = 'PSA Resource'
                                ORDER BY LastModifiedDate DESC LIMIT 1)
                               FROM Case WHERE IsClosed = false AND RecordTypeId = :psRecTypeId 
                               AND AKAM_Case_ID__c = :akamCaseId LIMIT 1
                              ];
        }
        
        if(!lstSearchedCase.isEmpty())
        {
            for(Case searchedCase : lstSearchedCase)
            {       
                caseWrapRec = new CaseWrapper();
                caseWrapRec.akamCaseId = searchedCase.AKAM_Case_ID__c;
                caseWrapRec.severity = searchedCase.Severity__c;
                caseWrapRec.caseUrl = '/' + searchedCase.Id;
                caseWrapRec.caseRecId = searchedCase.Id;
                caseWrapRec.accountName = searchedCase.Account.Name;
                caseWrapRec.accountUrl = '/' + searchedCase.AccountId;
                caseWrapRec.subject = searchedCase.Subject;
                caseWrapRec.livingSummary = searchedCase.Description;
                caseWrapRec.caseloe = searchedCase.LOE_Hours__c != null ? String.valueOf(searchedCase.LOE_Hours__c) : '❓';
                caseWrapRec.caseloeval = searchedCase.LOE_Hours__c != null ? searchedCase.LOE_Hours__c : -1;
                
                if(!searchedCase.Timecards__r.isEmpty())
                {
                    caseWrapRec.timecard = searchedCase.Timecards__r[0].Id;
                    caseWrapRec.Project = searchedCase.Timecards__r[0].pse__Project__c;
                    caseWrapRec.milestone = searchedCase.Timecards__r[0].pse__Milestone__c;
                    caseWrapRec.projectProduct = searchedCase.Timecards__r[0].pse__Project_Methodology_Object__c;
                }   
                else
                {
                    caseWrapRec.Project = searchedCase.pse_Project__c;
                    caseWrapRec.milestone = searchedCase.pse_Milestone__c;
                }
                
                caseWrapRec.Service = searchedCase.Service__c;
                caseWrapRec.ReqType = searchedCase.Request_Type__c;
                caseWrapRec.caseProductId = searchedCase.Case_Product__c;
                caseWrapRec.caseProductName = searchedCase.Case_Prod_Name__c;
                
                if(String.isNotBlank(String.valueOf(searchedCase.Requested_Completion_Date_UTC__c)))
                {
                    caseWrapRec.reqCompletionDate = searchedCase.Requested_Completion_Date_UTC__c.format();
                    caseWrapRec.reqCompletionDateVal = searchedCase.Requested_Completion_Date_UTC__c;
                    if(searchedCase.Requested_Completion_Date_UTC__c >= System.today() && searchedCase.Requested_Completion_Date_UTC__c <= System.today().addDays(2))
                    {
                        caseWrapRec.reqCompletionDateColour = 'reqDateBrown';
                    }
                    else if(searchedCase.Requested_Completion_Date_UTC__c < System.today())
                    {
                        caseWrapRec.reqCompletionDateColour = 'reqDateRed';
                    }
                }
                
                caseWrapRec.ageDays = searchedCase.Age_days__c;
                
                caseWrapRec.utilizedHours = 0;
                
                if(searchedCase.Billable_Hours__c != null)
                {
                    caseWrapRec.utilizedHours += searchedCase.Billable_Hours__c;
                    caseWrapRec.billableHours = searchedCase.Billable_Hours__c;
                    
                    if(searchedCase.Billable_Hours__c > searchedCase.LOE_Hours__c)
                    { 	caseWrapRec.billableHoursClass = 'slds-col numberCircle redBubble';}
                    else if(searchedCase.LOE_Hours__c != null && searchedCase.Billable_Hours__c >= (0.8 * searchedCase.LOE_Hours__c))
                    {	caseWrapRec.billableHoursClass = 'slds-col numberCircle yellowBubble';}
                    else {	caseWrapRec.billableHoursClass = 'slds-col numberCircle darkGreyBubble';}
                }
                else {caseWrapRec.billableHours = 0; caseWrapRec.billableHoursClass = 'slds-col numberCircle darkGreyBubble';}
                
                if(searchedCase.Non_Billable_Hours__c != null)
                {
                    caseWrapRec.utilizedHours += searchedCase.Non_Billable_Hours__c;
                    caseWrapRec.nonbillableHours = searchedCase.Non_Billable_Hours__c;
                }
                else {caseWrapRec.nonbillableHours = 0; }
                
                if(searchedCase.Internal_Hours__c != null)
                {
                    caseWrapRec.utilizedHours += searchedCase.Internal_Hours__c;
                    caseWrapRec.internalHours = searchedCase.Internal_Hours__c;
                }
                else {caseWrapRec.internalHours = 0; }
                
                if(String.isNotBlank(String.valueOf(searchedCase.Next_Planned_Activity_Date__c)))
                {
                    caseWrapRec.nextPlannedActivityDate = searchedCase.Next_Planned_Activity_Date__c.format();
                    caseWrapRec.nextPlannedActivityDateVal = searchedCase.Next_Planned_Activity_Date__c;
                }
                
                
                if(String.isNotBlank(searchedCase.Living_Summary_Next_Steps__c))
                {
                    lstLivingSummaryRows = searchedCase.Living_Summary_Next_Steps__c.stripHtmlTags().split('\n');
                    if(!lstLivingSummaryRows.isEmpty())
                    {
                        if(lstLivingSummaryRows.size() >= 3)
                            caseWrapRec.livingSummaryTop3 = lstLivingSummaryRows[0] + '\n' + lstLivingSummaryRows[1] + '\n' + lstLivingSummaryRows[2];
                        else if(lstLivingSummaryRows.size() >= 2)
                            caseWrapRec.livingSummaryTop3 = lstLivingSummaryRows[0] + '\n' + lstLivingSummaryRows[1];
                        else caseWrapRec.livingSummaryTop3 = lstLivingSummaryRows[0];
                        caseWrapRec.livingSummaryConcat = lstLivingSummaryRows[0].length() > 70 ? lstLivingSummaryRows[0].substring(0,70) + '...' : lstLivingSummaryRows[0];
                    }
                }
                caseWrapRec.caseCreator = searchedCase.CreatedBy.Name;
                caseWrapRec.userNameRole = searchedCase.CreatedBy.FirstName;
                caseWrapRec.userNameRoleUrl = '/' + searchedCase.CreatedById;
                caseWrapRec.status = searchedCase.Status;
                
                lstMyCaseWrapper.add(caseWrapRec);
                mapAKAMIdCaseWrap.put(searchedCase.AKAM_Case_ID__c,caseWrapRec);
            }
            
            if(saveString)
            {
                saveRecentlySearched(akamCaseId);
            }
            
            if(!lstAKAMCaseIDs.isEmpty())
            {
                for(String eachAKAMCaseId : lstAKAMCaseIDs)
                {
                    if(mapAKAMIdCaseWrap.containsKey(eachAKAMCaseId))
                    {
                        lstFinalCaseWrap.add(mapAKAMIdCaseWrap.get(eachAKAMCaseId));
                    }
                }
                return lstFinalCaseWrap;
            }
            else
            {
                return lstMyCaseWrapper;
            }
        }
        else {return null;}
        
    }
    
    @AuraEnabled
    public static void saveRecentlySearched(String akamCaseId)
    {
        String ucdRecTypeId = Schema.SObjectType.SC_User_Filter__c.getRecordTypeInfosByName().get('UCD').getRecordTypeId();
        String userId = UserInfo.getUserId() + '-' + ucdRecTypeId;
        String serializedfilter;
        Integer listLen = 0;
        
        List<String> lstSavedCases = new List<String>();
        List<String> lstToSave = new List<String>();
        Set<String> setSavedCaseId = new Set<String>();
        
        List<SC_User_Filter__c> searchedCases = new List<SC_User_Filter__c>();
        searchedCases = [SELECT Id,filter_values__c FROM SC_User_Filter__c WHERE Unique_ID__c = :userId LIMIT 1];
        if(searchedCases.size() > 0)
        {
            Map<String,Object> master_filter_values = (Map<String, Object>) JSON.deserializeUntyped(searchedCases[0].filter_values__c);
            String searchedCaseList = String.valueOf(master_filter_values.get('searchedCases'));
            
            if(master_filter_values.containsKey('searchedCases'))
            {	                
                lstSavedCases.addAll(searchedCaseList.split(','));
                lstSavedCases.add(0,akamCaseId);
                
                listLen = lstSavedCases.size() >= 10 ? 10 : lstSavedCases.size();
                {
                    for(Integer i=0; i<listLen; i++)
                    {
                        setSavedCaseId.add(lstSavedCases[i]);
                    }
                    searchedCaseList = String.join(new List<String>(setSavedCaseId),',');
                }

                System.debug(searchedCaseList);

                master_filter_values.put('searchedCases',searchedCaseList);
                serializedfilter  = JSON.serialize(master_filter_values);
            }
            else
            {
                searchedCaseList = akamCaseId;
                master_filter_values.put('searchedCases',searchedCaseList);
                serializedfilter  = JSON.serialize(master_filter_values);
            }
        }
        else
        {
            map<string, string> initialFilter = new map<string,string>();
            initialFilter.put('searchedCases',akamCaseId);
            serializedfilter  = JSON.serialize(initialFilter);
        }            
        
        SC_User_Filter__c upsertUserData = new SC_User_Filter__c(Unique_ID__c = userid, filter_values__c = serializedfilter, recordtypeid = ucdRecTypeId);
        
        upsert upsertUserData Unique_ID__c; 
    }
    
    public class MyCasesOnLoadWrapper
    {
        @AuraEnabled public String psRecordTypeId {get;set;}
        @AuraEnabled public Map<Id,CaseWrapper> lastSearchedCaseIds {get;set;}
        @AuraEnabled public List<CaseWrapper> lastSearchedCases {get;set;}
    }
    
    @AuraEnabled
    public static MyCasesOnLoadWrapper myCasesOnLoadWrap()
    {
        MyCasesOnLoadWrapper myCasesOnLoadWrapRec = new MyCasesOnLoadWrapper();
        List<CaseWrapper> lstSearchedCaseWrap = new List<CaseWrapper>();
        Map<Id,CaseWrapper> setLastSearchedCaseIds = new Map<Id,CaseWrapper>();
        
        myCasesOnLoadWrapRec.psRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Professional Services').getRecordTypeId();
        String ucdRecTypeId = Schema.SObjectType.SC_User_Filter__c.getRecordTypeInfosByName().get('UCD').getRecordTypeId();
        String userId = UserInfo.getUserId() + '-' + ucdRecTypeId;
        string serializedfilter;
        
        List<SC_User_Filter__c> searchedCases = new List<SC_User_Filter__c>();
        searchedCases = [SELECT Id,filter_values__c FROM SC_User_Filter__c WHERE Unique_ID__c = :userId LIMIT 1];
        if(searchedCases.size() > 0)
        {
            map<string,object> master_filter_values = (Map<String, object>) JSON.deserializeUntyped (searchedCases[0].filter_values__c);
            if(master_filter_values.containsKey('searchedCases'))
            {	
                String searchedCaseList = String.valueOf(master_filter_values.get('searchedCases'));
                lstSearchedCaseWrap = globalSearchAndRecentlyViewed(searchedCaseList, false);
            }
        }
        
        if(!lstSearchedCaseWrap.isEmpty())
        {
            for(CaseWrapper cw : lstSearchedCaseWrap)
            {
                setLastSearchedCaseIds.put(cw.caseRecId,cw);
            }
        }
        
        myCasesOnLoadWrapRec.lastSearchedCases = lstSearchedCaseWrap;
        myCasesOnLoadWrapRec.lastSearchedCaseIds = setLastSearchedCaseIds;
        System.debug(myCasesOnLoadWrapRec.lastSearchedCaseIds);
        return myCasesOnLoadWrapRec;
    }
    
    @AuraEnabled
    public static void bulkCloseCases(Map<String,Map<String,String>> mapCasesToClose)
    {
        List<Case> lstCaseToUpdate = new List<Case>();
        Case eachCase;String msg = '';
        for(String caseId : mapCasesToClose.keyset())
        {
            eachCase = new Case(Id = caseId);
            eachCase.Status = 'Closed';
            eachCase.Close_Code__c = mapCasesToClose.get(caseId).get('closeCode');
            eachCase.Solution_Summary__c = mapCasesToClose.get(caseId).get('solutionSummary');
            lstCaseToUpdate.add(eachCase);
        }
        try
        {
            update lstCaseToUpdate;
        }
        catch(DmlException e)
        {    
            for (Integer i = 0; i < e.getNumDml(); i++) 
            {
                msg =+ e.getDmlMessage(i);
            }
            throw new AuraHandledException(msg); 
        }
        catch(Exception e)
        {
            throw new AuraHandledException(CommonUtilClass.extractValidationErrorMsg(e)); 
        }
    }
    
    // end of changes by Vandhana
    
    //------------------------------CASES IN QUEUE APEX LOGIC-----------------------------
    
    @AuraEnabled
    public static list<sc_user_filter__c> getFilterRecord()
    {
        List<sc_user_filter__c> selectedFilters = new List<sc_user_filter__c>();
        string rectypeid= Schema.SObjectType.sc_user_filter__c.getRecordTypeInfosByName().get('UCD').getRecordTypeId();
        string userid=userinfo.getUserId()+'-'+rectypeid;
        
        selectedFilters=[select Unique_ID__c,filter_values__c,query_string__c from sc_user_filter__c WHERE Unique_ID__c=:userid limit 1];
        
        return selectedFilters;
    }
    
    //Gets the user saved dashboard view : Utility Bar toggle
    @AuraEnabled
    public static string getSavedDashboardView()
    {
        List<sc_user_filter__c> selectedFilters = new List<sc_user_filter__c>();
        selectedFilters=getFilterRecord();
        string choosenView;
        
        if(selectedFilters.size()>0)
        {	
            Map<String, object> allValues = (Map<String, object>) JSON.deserializeUntyped (selectedFilters[0].filter_values__c);
            if(allValues.containsKey('savedDashboardView'))
            { 
                choosenView=string.valueOf(allValues.get('savedDashboardView'));
            }
            else
            {
                choosenView=getViewbasedOnUser(); 
                saveUserUCDView(choosenView);
            }
        }
        else
        {
            choosenView=getViewbasedOnUser(); 
            saveUserUCDView(choosenView);
        }
        return choosenView;
    }
    
    //Saves the user view and calculates internal metrics. Utility bar toggle
    @AuraEnabled
    public static void saveUserUCDView(string choosenView)
    {
        string recordtypeid=Schema.SObjectType.sc_user_filter__c.getRecordTypeInfosByName().get('UCD').getRecordTypeId();
        string userid=userinfo.getUserId()+'-'+recordtypeid;
        string serializedfilter;
        
        List<sc_user_filter__c> selectedFilters = new List<sc_user_filter__c>();
        selectedFilters=[select id,filter_values__c from sc_user_filter__c WHERE Unique_ID__c=:userid limit 1];
        if(selectedFilters.size()>0)
        {
            map<string,object> master_filter_values = (Map<String, object>) JSON.deserializeUntyped (selectedFilters[0].filter_values__c);
            //if(master_filter_values.containsKey('savedDashboardView'))
            
            master_filter_values.put('savedDashboardView',choosenView);
            integer count=integer.valueof(master_filter_values.get('switchChangeCount'));
            count++;
            master_filter_values.put('switchChangeCount',string.valueOf(count));
            datetime lastswitchdate=DateTime.valueof(string.valueof(master_filter_values.get('lastSwitchDate')));
            
            if(choosenView=='TSC')
            {
                integer getMinuteValue = integer.valueof(system.now().getTime()/1000/60-lastswitchdate.getTime()/1000/60);
                integer gs2count = integer.valueof(master_filter_values.get('timeInGS2View'));
                gs2count=gs2count+getMinuteValue;
                master_filter_values.put('timeInGS2View',string.valueOf(gs2count));
            }
            else
            {
                integer getMinuteValue = integer.valueof(system.now().getTime()/1000/60-lastswitchdate.getTime()/1000/60);
                integer tsccount = integer.valueof(master_filter_values.get('timeInTSCView'));
                tsccount=tsccount+getMinuteValue;
                master_filter_values.put('timeInTSCView',string.valueOf(tsccount));
            }
            
            master_filter_values.put('lastSwitchDate',string.valueOf(system.now()));
            serializedfilter  = JSON.serialize(master_filter_values);
        }
        else
        {
            map<string, string> initialFilter = new map<string,string>();
            initialFilter.put('savedDashboardView',choosenView);
            initialFilter.put('lastSwitchDate',string.valueOf(system.now()));
            initialFilter.put('switchChangeCount','0');  
            initialFilter.put('timeInTSCView','0');            
            initialFilter.put('timeInGS2View','0');            
            
            serializedfilter  = JSON.serialize(initialFilter);
            
        }            
        
        sc_user_filter__c upsertUserData = new sc_user_filter__c
            (
                Unique_ID__c=userid, 
                filter_values__c =serializedfilter,
                recordtypeid=recordtypeid
            );
        
        upsert upsertUserData Unique_ID__c; 
        
    }
    
    //Calculates user view based on custom metadata cost center list
    private static string getViewbasedOnUser()
    {			
        string choosenView;
        
        SC_Utility__mdt AddMeta = [SELECT Value_text__c from SC_Utility__mdt where MasterLabel='UCD Cost Centers'];
        List<String> AddedQueues = AddMeta.Value_text__c.split(',');
        list<decimal> tsccostcenters = new list<decimal>();
        for(string eachcostcenter : AddedQueues)
        {
            tsccostcenters.add(decimal.valueOf(eachcostcenter));
        }
        list<user> isUserRecordPresent = [select id from user where id=:userinfo.getUserId() and cost_center__c IN :tsccostcenters];
        if(isUserRecordPresent.size()>0)
            choosenView='TSC';
        else
            choosenView='GS2';
        
        return choosenView;
    }

    //Onload Cases in Queue Wrapper
    public class CasesInQueue_OnLoad_Wrapper{
        
        @AuraEnabled public string choosenFilter {get;set;} //Currently set filter
        @AuraEnabled public string DashboardView {get;set;} //Dashboard View (UCD / GS2)
        @AuraEnabled public list<string> FilterNames {get;set;} //All Saved Filter Names
        @AuraEnabled public map<string, list<string>> filtername_selectedQueueids {get;set;} //Filtername, Choosen PS Queues
        @AuraEnabled public map<string, list<string>> filtername_selectedSeverity {get;set;} //Filtername, Choosen Severities
        @AuraEnabled public map<string, list<string>> filtername_selectedStatus {get;set;}  //Filtername, Choosen Status
        @AuraEnabled public map<string, list<string>> filtername_selectedTerritories {get;set;} //Filtername, Choosen DGRAT
        
        @AuraEnabled public list<sub_Terr_Mapping> Terr_Mapping_List; // DGRAT Record Wrapper 
        @AuraEnabled public list<string> territoryList {get;set;} // For setting all DGRAT values to checked by default
        @AuraEnabled public list<sub_Queue_Mapping> psqueue_List; // PS Queue List Wrapper
    }
    
    public class sub_Queue_Mapping{
        
        @AuraEnabled public string queueName {get;set;}
        @AuraEnabled public string queueId {get;set;}
        @AuraEnabled public integer queueCount {get;set;}
        
    }
    
    public class sub_Terr_Mapping{
        
        @AuraEnabled public string zone {get;set;}
        @AuraEnabled public string geography {get;set;}
        @AuraEnabled public string region {get;set;}
        @AuraEnabled public string area {get;set;}
        @AuraEnabled public string territory {get;set;}
        
    }
    
    //Onload Calculation : PS Queues / DGRAT / Saved Filters. Loads all PS queues (PS_%) and certain queues stored in metadata
    @AuraEnabled
    public static CasesInQueue_OnLoad_Wrapper getOnLoadValues()
    {
        CasesInQueue_OnLoad_Wrapper sub_OnLoad_Wrapper = new CasesInQueue_OnLoad_Wrapper();
        list<string> allPSQueueIDs = new list<string>();
        
        List<sc_user_filter__c> selectedFilters = new List<sc_user_filter__c>();
        selectedFilters=getFilterRecord();
        string choosenView;
        
        if(selectedFilters.size()>0)
        {	
            Map<String, object> allValues = (Map<String, object>) JSON.deserializeUntyped (selectedFilters[0].filter_values__c);
          
            //If the UCD Dashboard is loaded outside FFPSA App. Does not save the user view, just calculates it. Saving happens from utility bar toggle
            if(allValues.containsKey('savedDashboardView'))
            { 
                choosenView=string.valueOf(allValues.get('savedDashboardView'));
            }
            else
            {
                choosenView=getViewbasedOnUser(); 
            }                
            
            //If the user has choosen a GS2 view
            if(allValues.containsKey('CasesInQueue') && choosenView!='TSC'){
                
                sub_OnLoad_Wrapper.choosenFilter=string.valueof(allValues.get('ChoosenFilter'));
                //Getting all the saved filters
                string allfilters=string.valueOf(allValues.get('CasesInQueue'));
                Map<String, object> all_Filter_Values = (Map<String, object>) JSON.deserializeUntyped (allfilters);
                
                map<string, list<string>> filtername_selectedQueueids = new map<string, list<string>>();
                map<string, list<string>> filtername_selectedSeverity = new map<string, list<string>>();
                map<string, list<string>> filtername_selectedStatus = new map<string, list<string>>();
                map<string, list<string>> filtername_selectedTerritories = new map<string, list<string>>();
                
                list<string> FilterNameslist = new list<string>();
                //Iterating through each filter name and adding it into seperate maps. The LWC will perform map.get filtername for each when the user switches the filter.
                for (String FilterName : all_Filter_Values.keySet())
                {
                   
                    {
                        FilterNameslist.add(FilterName);
                    }
                    list<string> SavedQueues= new list<string>();
                    list<string> SavedSev= new list<string>();
                    list<string> SavedStatus= new list<string>();
                    list<string> SavedTerritory= new list<string>();
                    string filters = string.valueof(all_Filter_Values.get(FilterName));
                    
                    SavedQueues.addall(filters.split('&')[0].split(':')[1].split(','));
                    SavedSev.addall(filters.split('&')[1].split(':')[1].split(','));
                    SavedStatus.addall(filters.split('&')[2].split(':')[1].split(','));
                    
                    //filters are added after 3rd & character in the string, and not using split method as territory value can contain & character and split method can break the territory value
                    String filterStr = filters.substringAfter('&').substringAfter('&').substringAfter('&');
                    if(filterStr.split(':').size()>1)
                    SavedTerritory.addall(filterStr.split(':')[1].split(','));
                   
                    
                    filtername_selectedQueueids.put(FilterName,SavedQueues);
                    filtername_selectedSeverity.put(FilterName,SavedSev);
                    filtername_selectedStatus.put(FilterName,SavedStatus);
                    filtername_selectedTerritories.put(FilterName,SavedTerritory);
                }
                sub_OnLoad_Wrapper.FilterNames=FilterNameslist;
                sub_OnLoad_Wrapper.filtername_selectedQueueids=filtername_selectedQueueids;
                
                sub_OnLoad_Wrapper.filtername_selectedSeverity=filtername_selectedSeverity;
                
                sub_OnLoad_Wrapper.filtername_selectedStatus=filtername_selectedStatus;
                
                sub_OnLoad_Wrapper.filtername_selectedTerritories=filtername_selectedTerritories;
            }
            else
            {
                sub_OnLoad_Wrapper.FilterNames=null;
            }
            
        }
        else
        {
            sub_OnLoad_Wrapper.FilterNames=null;
            choosenView=getViewbasedOnUser(); 
        }
        //Queue related mappings and count calculation
        if(choosenView!='TSC'){
            map<string, string> QueueName_QueueIDMap = new map<string, string>();
            SC_Utility__mdt AddMeta = [SELECT Value_text__c from SC_Utility__mdt where MasterLabel='UCD Queues'];
            List<String> AddedQueues = AddMeta.Value_text__c.split(',');
            for(QueueSobject q :[Select QueueId,Queue.Name from QueueSobject where SobjectType = 'Case' and (Queue.DeveloperName like 'PS_%' or Queue.DeveloperName IN :AddedQueues) order by Queue.DeveloperName])
            {
                QueueName_QueueIDMap.put(q.Queue.Name,q.QueueId);
                allPSQueueIDs.add(q.QueueId);
            }
            
            List<sub_Queue_Mapping> sub_Queue_Mapping_List=new list<sub_Queue_Mapping>();
            sub_Queue_Mapping Each_sub_Queue_Mapping; 
            
            AggregateResult[] groupedResults =[select count(id), owner.name from case where ownerid IN :allPSQueueIDs and isclosed=false group by owner.name];
            for(AggregateResult ar : groupedResults)
            { 	
                Each_sub_Queue_Mapping = new sub_Queue_Mapping();
                Each_sub_Queue_Mapping.queueName = (string.valueOf(ar.get('Name')));
                Each_sub_Queue_Mapping.queueId= QueueName_QueueIDMap.get(Each_sub_Queue_Mapping.queueName);
                Each_sub_Queue_Mapping.queueCount = (Integer.valueOf(ar.get('expr0')));
                QueueName_QueueIDMap.remove(Each_sub_Queue_Mapping.queueName);
                
                sub_Queue_Mapping_List.add(Each_sub_Queue_Mapping);
            }
            //Adding those queues which have a count = 0
            if(!QueueName_QueueIDMap.isEmpty())
            {
                for (String QueueName : QueueName_QueueIDMap.keySet()){
                    Each_sub_Queue_Mapping = new sub_Queue_Mapping();
                    Each_sub_Queue_Mapping.queueName = QueueName;
                    Each_sub_Queue_Mapping.queueId= QueueName_QueueIDMap.get(Each_sub_Queue_Mapping.queueName);
                    Each_sub_Queue_Mapping.queueCount = 0;
                    sub_Queue_Mapping_List.add(Each_sub_Queue_Mapping);
                    
                }
            }
            
            sub_OnLoad_Wrapper.psqueue_List=sub_Queue_Mapping_List;
            
            //Territory Mappings
            List<sub_Terr_Mapping> sub_Terr_Mapping_List=new list<sub_Terr_Mapping>();
            
            sub_Terr_Mapping Each_sub_Terr_Mapping; 
            list<string> territoryList = new list<string>();
            //Changes done for GRAZT, ESESP-4942 BY:Bhavesh
            for( pse__region__c region : [SELECT Id, Name,
                        pse__Parent_Region__c, pse__Parent_Region__r.Name,
                        pse__Parent_Region__r.pse__Parent_Region__c, pse__Parent_Region__r.pse__Parent_Region__r.Name,
                        pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__c, pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.Name,
                        pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__c, pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.Name,
                        pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__c, pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.Name
                        FROM pse__region__c
                        WHERE psa_old__c = false
                        AND Name LIKE '% (Territory)'
                        AND (NOT Name Like '% _Old%')
                        Order By pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.Name, pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.Name, 
                                         pse__Parent_Region__r.pse__Parent_Region__r.Name, pse__Parent_Region__r.Name, Name ]){
                Each_sub_Terr_Mapping=new sub_Terr_Mapping();
                
                
                Each_sub_Terr_Mapping.Geography = region.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.Name.replace(' (Geography)', '');
                Each_sub_Terr_Mapping.Region = region.pse__Parent_Region__r.pse__Parent_Region__r.pse__Parent_Region__r.Name.replace(' (Region)', '');
                Each_sub_Terr_Mapping.Area = region.pse__Parent_Region__r.pse__Parent_Region__r.Name.replace(' (Area)', '');
                Each_sub_Terr_Mapping.Zone = region.pse__Parent_Region__r.Name.replace(' (Zone)', '');
                Each_sub_Terr_Mapping.Territory = region.Name.replace(' (Territory)', ''); 
                territoryList.add(Each_sub_Terr_Mapping.Territory);
                sub_Terr_Mapping_List.add(Each_sub_Terr_Mapping);

            }
            
            sub_OnLoad_Wrapper.Terr_Mapping_List=sub_Terr_Mapping_List;
            sub_OnLoad_Wrapper.territoryList = territoryList;
        }
        sub_OnLoad_Wrapper.DashboardView=choosenView;
        return sub_OnLoad_Wrapper;
    }
    
    //Gets Cases in Queue Records
    @AuraEnabled
    public static List<CaseWrapper> getCasesinQueue()
    {
        List<Case> lstCasesinQueue = new List<Case>();
        
        List<CaseWrapper> lstCaseWrapper = new List<CaseWrapper>();
        CaseWrapper caseWrapRec;
        
        string userid=userinfo.getUserId()+'-'+Schema.SObjectType.sc_user_filter__c.getRecordTypeInfosByName().get('UCD').getRecordTypeId();
        
        List<SC_User_Filter__c> getQueryString = [select query_string__c from SC_User_Filter__c WHERE Unique_ID__c=:userid limit 1];

        if(getQueryString.size()>0 && getQueryString[0].query_string__c!=null)
        {      
            string baseQuery = 'Select AKAM_Case_ID__c,Case_Product__c,Case_Prod_Name__c,Severity__c,Description,Service__c,Request_Type__c,pse_Project__r.Name,pse_Project__c,AccountId,Account.Name,Subject,Total_LOE_min__c,Requested_Completion_Date_UTC__c,Requested_Completion_Time_UTC__c, Age_days__c, Pending_Case_Reasons__c, Pending_Case_Others_Reason__c,Case_Owner_Name__c,Status,CreatedBy.Name,Origin FROM Case ';
            string finalQuery = baseQuery + getQueryString[0].query_string__c;
            lstCasesinQueue = Database.query(finalQuery);
            
            for(Case eachCase : lstCasesinQueue)
            {
                caseWrapRec = new CaseWrapper();
                caseWrapRec.akamCaseId = eachCase.AKAM_Case_ID__c;
                caseWrapRec.severity = eachCase.Severity__c;
                caseWrapRec.caseUrl = '/'+eachCase.Id;
                caseWrapRec.caseRecId=eachCase.Id;
                caseWrapRec.accountName = eachCase.Account.Name;
                if(eachCase.Account.Name!=null){
                caseWrapRec.accountUrl = '/'+eachCase.AccountId;}
                caseWrapRec.subject = eachCase.Subject;
                caseWrapRec.pendingCaseReason=eachCase.Pending_Case_Reasons__c;
                caseWrapRec.livingSummaryTop3=eachCase.Pending_Case_Others_Reason__c;
                caseWrapRec.caseloe = string.valueof((eachCase.Total_LOE_min__c)/60);
                if(String.isNotBlank(eachCase.Requested_Completion_Time_UTC__c) && String.isNotBlank(String.valueOf(eachCase.Requested_Completion_Date_UTC__c)))
                {
                    String[] timeSplit = eachCase.Requested_Completion_Time_UTC__c.split(':');
                    Time timeValue = Time.newInstance( Integer.valueOf(timeSplit[0]),Integer.valueOf(timeSplit[1]),0,0);      
                    caseWrapRec.reqCompletionDate = eachCase.Requested_Completion_Date_UTC__c.format();
                }

                if(String.isNotBlank(String.valueOf(eachCase.Requested_Completion_Date_UTC__c)))
                {
                    caseWrapRec.reqCompletionDate = eachCase.Requested_Completion_Date_UTC__c.format();
                    caseWrapRec.reqCompletionDateVal = eachCase.Requested_Completion_Date_UTC__c;
                }
                if(String.isNotBlank(eachCase.Description))
                {
                    caseWrapRec.showlivingSummarybtn=false;
                    caseWrapRec.livingSummary = eachCase.Description;
                }
                else
                {
                    caseWrapRec.showlivingSummarybtn=true;
                }
                if(String.isNotBlank(eachCase.pse_Project__c))
                {
                    caseWrapRec.ProjectURL='/'+eachCase.pse_Project__c;
                    caseWrapRec.Project=eachCase.pse_Project__r.Name;
                }
                caseWrapRec.ageDays = eachCase.Age_days__c;
                caseWrapRec.Service=eachCase.Service__c;
                caseWrapRec.ReqType=eachCase.Request_Type__c;
                caseWrapRec.caseCreator = eachCase.CreatedBy.Name;
                caseWrapRec.caseOwner = eachCase.Case_Owner_Name__c;
                caseWrapRec.caseProductId = eachCase.Case_Product__c;
                caseWrapRec.caseProductName = eachCase.Case_Prod_Name__c;
                caseWrapRec.status = eachCase.Status;
                caseWrapRec.caseOrigin = eachCase.Origin;
                /*if(eachCase.Status=='Pending')
                {
                    caseWrapRec.showpendingCaseReasonbtn=false;
                }
                else
                    caseWrapRec.showpendingCaseReasonbtn=true;
                */
                
                lstCaseWrapper.add(caseWrapRec);
            }
        }
        
        return lstCaseWrapper;
    }
    
    //Dynamic Query Generation (Preview / Edit / Save Filter options) - Only where clause is stored
    @AuraEnabled
    public static string generateDynamicQuery(list<String> SelectedQueueValues, list<string> SelectedSevValues, list<string> SelectedStatusValues, list<string> SelectedDGRAT)
    {
        //-------------------------------------------Constructing Query to be saved----------------------------------
        string query='WHERE IsClosed = false and RecordType.Name=\'Professional Services\' and ownerid IN (';
        for(integer i=0;i<SelectedQueueValues.size()-1;i++)
        {
            query=query + '\''+SelectedQueueValues[i]+'\''+',';
        }
        query=query + '\''+SelectedQueueValues[SelectedQueueValues.size()-1]+'\''+')';
        
        if(SelectedSevValues.size()<4)
        {
            query=query + ' and Severity__c IN (';
            for(integer i=0;i<SelectedSevValues.size()-1;i++)
            {
                query=query + '\''+SelectedSevValues[i]+'\''+',';
            }
            query=query + '\''+SelectedSevValues[SelectedSevValues.size()-1]+'\''+')';
        }
        
        if(SelectedStatusValues.size()<5)
        {
            query=query + ' and Status IN (';
            for(integer i=0;i<SelectedStatusValues.size()-1;i++)
            {
                query=query + '\''+SelectedStatusValues[i]+'\''+',';
            }
            query=query + '\''+SelectedStatusValues[SelectedStatusValues.size()-1]+'\''+')';
        }
        
        if(SelectedDGRAT.size()>0)
        {
            query=query+' and Account.TERR_HIER_5__c IN (';
            for(integer i=0;i<SelectedDGRAT.size()-1;i++)
            {
                query=query + '\''+SelectedDGRAT[i]+'\''+',';
            }
            query=query + '\''+SelectedDGRAT[SelectedDGRAT.size()-1]+'\''+')';
            
        }
        
        query=query+' order by createddate desc LIMIT 500';
        
        return query; 
    }
    
    //Saves the choosen Filter values (New Filter)
    @AuraEnabled
    public static void saveSelectedFilters(list<String> SelectedQueueValues, list<string> SelectedSevValues, list<string> SelectedStatusValues, list<string> SelectedDGRAT, string FilterName)
    {
        string recordtypeid=Schema.SObjectType.sc_user_filter__c.getRecordTypeInfosByName().get('UCD').getRecordTypeId();
        string userid=userinfo.getUserId()+'-'+recordtypeid;
        
        List<sc_user_filter__c> selectedFilters = new List<sc_user_filter__c>();
        selectedFilters=[select id,Unique_ID__c,filter_values__c,query_string__c from sc_user_filter__c WHERE Unique_ID__c=:userid limit 1];
        
        string query = generateDynamicQuery(SelectedQueueValues, SelectedSevValues, SelectedStatusValues,SelectedDGRAT);
        
        // --------------------------------Constructing Key - Value pair for all the filters ---------------------------------
        
        string FullFilter = 'Queue:'+string.join(SelectedQueueValues,',')+'&Sev:'+string.join(SelectedSevValues,',')+'&Status:'+string.join(SelectedStatusValues,',')+'&Territory:'+string.join(SelectedDGRAT,',');
        
        //Getting the current stored filter values for the user
        map<string,object> master_filter_values = (Map<String, object>) JSON.deserializeUntyped (selectedFilters[0].filter_values__c);
        
        if(master_filter_values.containsKey('CasesInQueue'))
        {
            //Getting the child filter's value in CasesInQueue
            string childfilters = string.valueof(master_filter_values.get('CasesInQueue'));
            map<string,object> child_filter_values = (map<string,object>) JSON.deserializeUntyped (childfilters);
            //Adding / replacing existing filter
            child_filter_values.put(FilterName,FullFilter);        
            
            //Converting back to json
            FullFilter = JSON.serialize(child_filter_values);
            master_filter_values.put('CasesInQueue',FullFilter);
        }
        else
        {
            map<string, string> initialFilter = new map<string,string>();
            initialFilter.put(FilterName,FullFilter);
            
            string initialFilterserialized = JSON.serialize(initialFilter);
            master_filter_values.put('CasesInQueue',initialFilterserialized);
            
        }
        
        master_filter_values.put('ChoosenFilter',FilterName);   
        FullFilter = JSON.serialize(master_filter_values);
        
        sc_user_filter__c upsertUserData = new sc_user_filter__c
            (
                Unique_ID__c=userid, 
                filter_values__c =FullFilter,
                query_string__c=query,
                recordtypeid=recordtypeid
            );
        
        upsert upsertUserData Unique_ID__c;
    }
    
    //Edits current Filter Selection and saves the query
    @AuraEnabled
    public static string editSelectedFilter(list<String> SelectedQueueValues, list<string> SelectedSevValues, list<string> SelectedStatusValues, list<string> SelectedDGRAT, string FilterName)
    {
        string recordtypeid=Schema.SObjectType.sc_user_filter__c.getRecordTypeInfosByName().get('UCD').getRecordTypeId();
        string userid=userinfo.getUserId()+'-'+recordtypeid;
        
        List<sc_user_filter__c> selectedFilters = new List<sc_user_filter__c>();
        selectedFilters=[select filter_values__c from sc_user_filter__c WHERE Unique_ID__c=:userid limit 1];
        
        string FullFilter = 'Queue:'+string.join(SelectedQueueValues,',')+'&Sev:'+string.join(SelectedSevValues,',')+'&Status:'+string.join(SelectedStatusValues,',')+'&Territory:'+string.join(SelectedDGRAT,',');
        map<string,object> master_filter_values = (Map<String, object>) JSON.deserializeUntyped (selectedFilters[0].filter_values__c);
        
        string childfilters = string.valueof(master_filter_values.get('CasesInQueue'));
        map<string,object> child_filter_values = (map<string,object>) JSON.deserializeUntyped (childfilters);
        child_filter_values.put(FilterName,FullFilter);        
        
        FullFilter = JSON.serialize(child_filter_values);
        master_filter_values.put('CasesInQueue',FullFilter);
        
        FullFilter = JSON.serialize(master_filter_values);
       
        string query = generateDynamicQuery(SelectedQueueValues, SelectedSevValues, SelectedStatusValues,SelectedDGRAT);
        sc_user_filter__c upsertUserData = new sc_user_filter__c
                (
                    Unique_ID__c=userid, 
                    query_string__c=query,
                    filter_values__c =FullFilter
                );
            
        upsert upsertUserData Unique_ID__c;
        return 'Success';
    }
    
    //Deletes the filter selection
    @AuraEnabled
    public static string DeleteFilterMapping(string FilterName)
    {
        string recordtypeid=Schema.SObjectType.sc_user_filter__c.getRecordTypeInfosByName().get('UCD').getRecordTypeId();
        string userid=userinfo.getUserId()+'-'+recordtypeid;
        
        List<sc_user_filter__c> selectedFilters = new List<sc_user_filter__c>();
        selectedFilters=[select filter_values__c from sc_user_filter__c WHERE Unique_ID__c=:userid limit 1];
        map<string,object> master_filter_values = (Map<String, object>) JSON.deserializeUntyped (selectedFilters[0].filter_values__c);
        
        if(master_filter_values.containsKey('CasesInQueue'))
        {
            string childfilters = string.valueof(master_filter_values.get('CasesInQueue'));
            map<string,object> child_filter_values = (map<string,object>) JSON.deserializeUntyped (childfilters);
            child_filter_values.remove(FilterName);
            
            string FullFilter = JSON.serialize(child_filter_values);
            
            master_filter_values.put('CasesInQueue',FullFilter);
            FullFilter = JSON.serialize(master_filter_values);
            
            sc_user_filter__c upsertUserData = new sc_user_filter__c
                (
                    Unique_ID__c=userid, 
                    filter_values__c =FullFilter
                );
            
            upsert upsertUserData Unique_ID__c;
            
            return 'Filter '+FilterName+' successfully removed from your saved filter list!';
        }
        else
            return 'Error!';
        
    }
    //Change Owner Buttion :  Gets Queue Options based on user search
    @AuraEnabled(cacheable=true)  
    public static List<sobject> findLookupRecords(String searchKey, String searchQuery) {  
        string searchText = '\'%' + String.escapeSingleQuotes(searchKey) + '%\'';
        string query = searchQuery+searchText+'ORDER BY Queue.Name ASC LIMIT 20';
        return Database.query(query); 
    }  
    
    //Applies the choosen filter : Changes the dynamic query and choosenfilter values
    @AuraEnabled
    public static string ApplyFilterMapping(list<String> SelectedQueueValues, list<string> SelectedSevValues, list<string> SelectedStatusValues, list<string> SelectedDGRAT,string filtername)
    {
        string query = generateDynamicQuery(SelectedQueueValues, SelectedSevValues, SelectedStatusValues,SelectedDGRAT);
        
        string recordtypeid=Schema.SObjectType.sc_user_filter__c.getRecordTypeInfosByName().get('UCD').getRecordTypeId();
        string userid=userinfo.getUserId()+'-'+recordtypeid;
        
        List<sc_user_filter__c> selectedFilters = new List<sc_user_filter__c>();
        selectedFilters=[select filter_values__c from sc_user_filter__c WHERE Unique_ID__c=:userid limit 1];
        map<string,object> master_filter_values = (Map<String, object>) JSON.deserializeUntyped (selectedFilters[0].filter_values__c);
        master_filter_values.put('ChoosenFilter',filtername);   
        string FullFilter = JSON.serialize(master_filter_values);  
        
        sc_user_filter__c upsertUserData = new sc_user_filter__c
            (
                Unique_ID__c=userid, 
                filter_values__c =FullFilter,
                query_string__c=query
            );
        
        upsert upsertUserData Unique_ID__c;  
        
        return filtername+' successfully applied!';
    }
    
    //Pending Case Reason Button (Reason only for other option)
    @AuraEnabled
    public static void assignPendingReasonToCase(boolean isCaseStatusChange, string pendingcaseoption,string CaseID,string othersreason)
    {
        case updatecase = new case();
        
        if(isCaseStatusChange)
        {
         updatecase = new case(id=CaseID, Status = 'Pending', Pending_Case_Reasons__c=pendingcaseoption,
                                   Pending_Case_Others_Reason__c =othersreason
                                  ); 
        }
        else
        {
         updatecase = new case(id=CaseID, Pending_Case_Reasons__c=pendingcaseoption,
                                Pending_Case_Others_Reason__c =othersreason
                                 ); 
        }
        try
        { update updatecase;}
        catch(Exception e)
        {                  throw new AuraHandledException(CommonUtilClass.extractValidationErrorMsg(e)); }
        
    }
    //Change case owner (Queue / User)
    @AuraEnabled
    public static void changeCaseOwnerQueue(List<string> setCaseIds, String newCaseOwner)
    {
        List<Case> lstCase = new List<Case>(); 
        
        if(String.isBlank(newCaseOwner))
        {newCaseOwner = UserInfo.getUserId();}
        
        
        for(string eachCaseid : setCaseIds)
        {
            case updatecase = new case(id=eachCaseid,ownerid=newCaseOwner); 
            lstCase.add(updatecase);
        }
        try
        {
            update lstCase;
        }
        catch(Exception e)
        {
            throw new AuraHandledException(CommonUtilClass.extractValidationErrorMsg(e));
        }
    }
}