/*
Author          : Vandhana Krishnamurthy
Description     : Controller for AMG Homescreen in Lightning


Date                Developer             JIRA #                      		Description                                                       
------------------------------------------------------------------------------------------------------------------
25 Nov 2019     	Vandhana      		 ESESP-1900     		AMG Homescreen Lightning Development
23 Feb 2021         Vandhana             ESESP-4720             Email Notification for Case assignment has stopped working
------------------------------------------------------------------------------------------------------------------
*/

public class SC_AMG_Home_Lightning 
{   
    public SC_AMG_Home_Lightning() {}
    
    public class CaseWrapper
    {
        @AuraEnabled public Case caseRec{get;set;}
        @AuraEnabled public Id caseRecId{get;set;}
        @AuraEnabled public String subject{get;set;}
        @AuraEnabled public String region{get;set;}
        
        @AuraEnabled public String description{get;set;}
        @AuraEnabled public String akamcaseid{get;set;}
        @AuraEnabled public String visibility{get;set;}
        @AuraEnabled public Decimal agedays{get;set;}
        @AuraEnabled public String origin{get;set;}
        @AuraEnabled public String accountName{get;set;}
        @AuraEnabled public String accountId{get;set;}
        @AuraEnabled public String supportLevel{get;set;}
        @AuraEnabled public String service{get;set;}
        
        @AuraEnabled public String requestType{get;set;}
        
        @AuraEnabled public String lastOwnerUpdate{get;set;}
        @AuraEnabled public String lastCustUpdate{get;set;}
        @AuraEnabled public String lastAkamUpdate{get;set;}
        
        @AuraEnabled public String lastOwnerUpdateColour{get;set;}
        @AuraEnabled public String lastCustUpdateColour{get;set;}
        @AuraEnabled public String lastAkamUpdateColour{get;set;}

        @AuraEnabled public String url{get;set;}
        
        @AuraEnabled public String contactName{get;set;}
        @AuraEnabled public String contactId{get;set;}
        @AuraEnabled public Boolean transitioned{get;set;}
        @AuraEnabled public String sla{get;set;}
        @AuraEnabled public Integer slaInMinutes{get;set;}
        @AuraEnabled public String ageColour{get;set;}
        @AuraEnabled public String lastUpdateColour{get;set;}
        @AuraEnabled public String slaColour{get;set;}
        @AuraEnabled public String liveChatId {get;set;}
        @AuraEnabled public String chatTranscript {get;set;}
        @AuraEnabled public String incident {get;set;} 
        @AuraEnabled public String incidentId {get;set;} 
        @AuraEnabled public String hand {get;set;}
        @AuraEnabled public String ownername {get;set;}
        @AuraEnabled public String status {get;set;}
        @AuraEnabled public String priority{get;set;}
    }
    
    @AuraEnabled(cacheable=true)
    public static String getCasesForAMGQueue(String queueName)
    {
        List<Case> caseList = new List<Case>();
        Id amgRecType = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        /*
        String baseQuery = 'SELECT Id, Age_days__c,AccountId,AKAM_Case_ID__c,Do_Not_Show_In_Portal_Picklist__c,Origin,Account.Name,Contact.Name,Age_Business_Days__c,Last_Update_By__c,AMG_Transition__c ,'
            + ' ContactId,Case_Account_Name__c,Support_Level__c,Subject,Severity__c, Service__c,BusinessHoursId,Override_Next_Case_Update__c,Owner.Name,AMG_Transition__c,AKAM_Modified_By__c,Last_Case_Owner_Update__c,LastModifiedDate,Last_Case_Update__c,Last_Customer_Activity_Date__c ,'
            + ' Request_Type__c,Description,OwnerId,CreatedDate,Account.Support_Level__c,Priority,Status ' +
            + ' FROM Case WHERE RecordTypeId = \'' + amgRecType + '\'';
        */
        String baseQuery = 'SELECT Id, Age_days__c, Account.TERR_HIER_2__c,AKAM_Case_ID__c,Do_Not_Show_In_Portal_Picklist__c,Origin,Account.Name,Contact.Name,Age_Business_Days__c,Last_Update_By__c,AMG_Transition__c ,'
            + ' ContactId,Case_Account_Name__c,AccountId,Support_Level__c,Subject,Severity__c, Service__c,BusinessHoursId,Override_Next_Case_Update__c,Owner.Name,AKAM_Modified_By__c,Service_Incident__c,Do_Not_Show_in_Portal__c,'

            + ' Request_Type__c,Description,OwnerId,CreatedDate,Account.Support_Level__c,Status,Priority,IsClosed,Last_Case_Owner_Update__c,LastModifiedDate,Last_Case_Update__c,Last_Customer_Activity_Date__c ,Last_Non_Case_Owner_Update__c,' 
            + ' (Select MilestoneType.Name,StartDate,IsCompleted,IsViolated,TargetResponseInMins,TimeRemainingInMins, BusinessHoursId, TimeRemainingInDays, TimeSinceTargetInMins, TimeSinceTargetInDays,TargetDate,ElapsedTimeInMins From CaseMilestones'
            + ' WHERE ( MilestoneType.Name =\'Initial Response\' AND Case.RecordType.Name = \'AMG\' AND Case.AMG_Transition__c = false )'
            + ' OR ( MilestoneType.Name =\'User Setup\' AND Case.RecordType.Name = \'AMG\') '
            + ' OR ( MilestoneType.Name =\'AMG Post Transition Initial Response\' AND Case.RecordType.Name = \'AMG\' AND Case.AMG_Transition__c = true ))'
            + ' FROM Case WHERE RecordTypeId = \'' + amgRecType + '\'';
        
        String openCaseQuery = ' AND IsClosed = FALSE';
        String mapQuery = ' and Owner.Name = \'' + queueName + '\'';
        if(queueName.equalsIgnoreCase('Transition Queue'))
            mapQuery = ' AND Owner.Name like \'%AMG%Queue%\' AND AMG_Transition__c = TRUE';
        
        baseQuery = baseQuery + openCaseQuery + mapQuery;
        return baseQuery;
    }
    
    @AuraEnabled
    public static Boolean isUserManagerCheck()
    {
        User currentUser = [Select Id,Availability__c,Profile.Name,Backup_User__c,Backup_User__r.Profile.Name,Backup_User__r.Availability__c,ManagerId
                            FROM User 
                            WHERE Id = :Userinfo.getUserId()];
        Id managerId = currentUser.ManagerId;
        
        Map<Id,User> teamIDs = new Map<Id,User>();
        Boolean isUserManager = FALSE;
        
        teamIDs = new Map<Id,User>([SELECT ID FROM User 
                                    WHERE ManagerId = :UserInfo.getUserId() 
                                    AND IsActive = TRUE]);
        if(teamIDs.isEmpty())
            return false;
        else return true;
    }
    
    @AuraEnabled
    public static List<CaseWrapper> getCaseListForAMG(String ownerFilterValue, String userOrQueue,Integer recordLimit, Integer recordOffset)
    {
        System.debug(ownerFilterValue + userOrQueue);
        List<Case> caseLst = new List<Case>();
        Id amgRecType = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        
        Integer intLimit = Integer.valueof(recordLimit);
        Integer intOffset = Integer.valueof(recordOffset);
        
        String baseQuery = 'SELECT Id, Account.TERR_HIER_2__c, Age_days__c,AKAM_Case_ID__c, Do_Not_Show_In_Portal_Picklist__c,Origin,Account.Name,Contact.Name,Age_Business_Days__c,Last_Update_By__c,AMG_Transition__c , '
            + ' ContactId,Case_Account_Name__c,AccountId,Support_Level__c,Subject,Severity__c, Service__c,BusinessHoursId,Override_Next_Case_Update__c,Owner.Name,AKAM_Modified_By__c,Service_Incident__c, Do_Not_Show_in_Portal__c, '
  	 + 'Request_Type__c,Description,OwnerId,CreatedDate,Account.Support_Level__c,Status,Priority,IsClosed,Last_Case_Owner_Update__c,Last_Non_Case_Owner_Update__c,LastModifiedDate,Last_Case_Update__c,Last_Customer_Activity_Date__c, ' 
            + ' (Select Id from Tasks), '
            + ' (Select MilestoneType.Name,StartDate,IsCompleted,IsViolated,TargetResponseInMins,TimeRemainingInMins, BusinessHoursId, TimeRemainingInDays, TimeSinceTargetInMins, TimeSinceTargetInDays,TargetDate,ElapsedTimeInMins From CaseMilestones'
            + ' WHERE ( MilestoneType.Name =\'Initial Response\' AND Case.RecordType.Name = \'AMG\' AND Case.AMG_Transition__c = false )'
            + ' OR ( MilestoneType.Name =\'User Setup\' AND Case.RecordType.Name = \'AMG\') '
            + ' OR ( MilestoneType.Name =\'AMG Post Transition Initial Response\' AND Case.RecordType.Name = \'AMG\' AND Case.AMG_Transition__c = true ))'
            + ' FROM Case WHERE RecordTypeId = \'' + amgRecType + '\'';
        
        String closedCaseQuery = ' AND IsClosed = TRUE AND ClosedDate >= LAST_N_MONTHS:2 ';
        String openCaseQuery = ' AND IsClosed = FALSE';
        String loggedInUserQuery = ' AND OwnerId = \'' + UserInfo.getUserId() + '\'';
        
        if(userOrQueue == 'user')
        {
            User currentUser = [Select Id,Availability__c,Profile.Name,Backup_User__c,Backup_User__r.Profile.Name,Backup_User__r.Availability__c,ManagerId
                                FROM User 
                                WHERE Id = :Userinfo.getUserId()];
            Id managerId = currentUser.ManagerId;
            
            Map<Id,User> teamIDs = new Map<Id,User>();
            
            Boolean isAvailable = currentUser.Availability__c;
            Boolean isUserManager = FALSE;
            
            teamIDs = new Map<Id,User>([SELECT ID FROM User 
                                        WHERE ManagerId = :UserInfo.getUserId() 
                                        AND IsActive = TRUE]);
            if(teamIDs.isEmpty())
            {
                teamIDs = new Map<Id,User>([SELECT ID FROM User WHERE ManagerId = :managerId AND IsActive = TRUE ORDER BY ID]);
            }
            
            if(ownerFilterValue.equalsIgnoreCase('My Open Cases') || ownerFilterValue.equalsIgnoreCase('My Open Cases with Tasks'))
                baseQuery+= loggedInUserQuery + openCaseQuery;
            else
                if(ownerFilterValue.equalsIgnoreCase('My Closed Cases (Last 3 Months)'))
                baseQuery+= loggedInUserQuery + closedCaseQuery;
            else
                if(ownerFilterValue.equalsIgnoreCase('My Team\'s Open Cases with SLA Running') && !teamIDs.isEmpty())
            {
                Set<Id> idKeySet = teamIDs.keySet();
                baseQuery+= ' and OwnerId IN :idKeySet ' + openCaseQuery;
            }
        }
        else if(userOrQueue == 'queue')
        {
            baseQuery = getCasesForAMGQueue(ownerFilterValue);
        }
        
        //caseLst = Database.query(baseQuery);
        
        String orderByQuery = ' ORDER BY CreatedDate DESC LIMIT :intLimit OFFSET :intOffset';
        
        baseQuery+= orderByQuery;
        
        caseLst = Database.query(baseQuery);
        //system.assertEquals(1, caseLst.size());

        System.debug(caseLst);
        
        
        List<CaseWrapper> lstCaseWrapper = new List<CaseWrapper>();
        
        List<CaseWrapper> lstCaseWithTaskWrapper = new List<CaseWrapper>();
        List<CaseWrapper> lstCaseWithMilestoneWrapper = new List<CaseWrapper>();
        
        CaseWrapper caseWrapperRec;
        String milestoneSLA = ''; Integer ageBusDay = 0;
        
        List<Id> caseIdList = new List<Id>();
        
        for(Case eachCase : caseLst)
            caseIdList.add(eachCase.Id);
        
        Map<Id,Boolean> caseChatMap = new Map<Id,Boolean>();
        caseChatMap = akachatTranscript(caseIdList);
        
        for(Case eachCase : caseLst)
        {
            caseWrapperRec = new CaseWrapper();
            caseWrapperRec.caseRec = eachCase;
            caseWrapperRec.caseRecId = eachCase.Id;
            caseWrapperRec.url = '/lightning/r/Case/' + eachCase.Id + '/view';

            caseWrapperRec.contactName = eachCase.Contact.Name;
            caseWrapperRec.region = eachCase.Account.TERR_HIER_2__c;
            caseWrapperRec.contactId = eachCase.ContactId;
            caseWrapperRec.subject = eachCase.Subject;
            caseWrapperRec.description = eachCase.Description;
            caseWrapperRec.akamcaseid = eachCase.AKAM_Case_ID__c;
            caseWrapperRec.visibility = eachCase.Do_Not_Show_In_Portal_Picklist__c;
            caseWrapperRec.agedays = eachCase.Age_days__c;
            caseWrapperRec.origin = eachCase.Origin;
            caseWrapperRec.accountName = eachCase.Case_Account_Name__c;
            caseWrapperRec.accountId = eachCase.AccountId;
            caseWrapperRec.supportLevel = eachCase.Support_Level__c;
            caseWrapperRec.service = eachCase.Service__c;
            caseWrapperRec.transitioned = eachCase.AMG_Transition__c;
            caseWrapperRec.requestType = eachCase.Request_Type__c;
            
            if(eachCase.Last_Case_Owner_Update__c != NULL)
            {
                caseWrapperRec.lastOwnerUpdate = (eachCase.Last_Case_Owner_Update__c).format();
                //System.debug('Last_Case_Owner_Update__c : ' + (eachCase.Last_Case_Owner_Update__c).format());

                if(Date.valueOf(eachCase.Last_Case_Owner_Update__c).daysBetween(Date.valueOf(System.now())) <= 2)
                    caseWrapperRec.lastOwnerUpdateColour = 'green';
                else
                    caseWrapperRec.lastOwnerUpdateColour = 'yellow';
            }
            
            if(eachCase.Last_Non_Case_Owner_Update__c != NULL)
            {
                caseWrapperRec.lastAkamUpdate = (eachCase.Last_Non_Case_Owner_Update__c).format();
                //System.debug('Last_Non_Case_Owner_Update__c : ' + (eachCase.Last_Non_Case_Owner_Update__c).format());

                if(Date.valueOf(eachCase.Last_Non_Case_Owner_Update__c).daysBetween(Date.valueOf(System.now())) <= 2)
                    caseWrapperRec.lastAkamUpdateColour = 'green';
                else
                    caseWrapperRec.lastAkamUpdateColour = 'yellow';
            }
            if(eachCase.Last_Customer_Activity_Date__c != NULL)
            {
                caseWrapperRec.lastCustUpdate = (eachCase.Last_Customer_Activity_Date__c).format();
                if(Date.valueOf(eachCase.Last_Customer_Activity_Date__c).daysBetween(Date.valueOf(System.now())) <= 2)
                    caseWrapperRec.lastCustUpdateColour = 'yellow';
                else if(Date.valueOf(eachCase.Last_Customer_Activity_Date__c).daysBetween(Date.valueOf(System.now())) <= 5)
                    caseWrapperRec.lastCustUpdateColour = 'orange';
                else
                    caseWrapperRec.lastCustUpdateColour = 'red';
            }
            //System.assertEquals(1, 2);
            
            caseWrapperRec.ownername = eachCase.Owner.Name;
            caseWrapperRec.priority = eachCase.Priority;
            caseWrapperRec.status = eachCase.Status;
            caseWrapperRec.hand = '✋🏼';
            if(!caseChatMap.isEmpty() && caseChatMap.containsKey(eachCase.Id))
                caseWrapperRec.chatTranscript = '💬';
            
            if(String.isNotBlank(eachCase.Service_Incident__c))
            {
                caseWrapperRec.incident = '⚠️';
                caseWrapperRec.incidentId = eachCase.Service_Incident__c;
            }
            
            // age colour
            if(eachCase.Request_Type__c != 'Customer Onboarding' && eachCase.Request_Type__c != 'Existing Customer Onboarding' 
                    && eachCase.Request_Type__c != 'SiteShield Map Degradation')
            {
                if(eachCase.Age_days__c <= 10)
                    caseWrapperRec.ageColour = 'green';
                else if(eachCase.Age_days__c <= 20)
                    caseWrapperRec.ageColour = 'yellow';
                else if (eachCase.Age_days__c <= 30)
                    caseWrapperRec.ageColour = 'orange';
                else caseWrapperRec.ageColour = 'red';
            }
            
            string SLAValue; 
            DateTime milestoneTargetDate;     
            Integer getMinuteValue;
            Boolean openMS = false;
            
            // Milestone Details
            if(!eachCase.CaseMilestones.isEmpty() && !eachCase.isClosed)
            {    
                for(CaseMilestone eachCaseMS :eachCase.CaseMilestones)
                {
                    milestoneSLA = eachCaseMS.TimeRemaininginMins; 
                    SLAValue = milestoneSLA; 
                    milestoneTargetDate = eachCaseMS.TargetDate; 
                    
                    if(!eachCaseMS.IsCompleted)
                    {
                        openMS = true;
                        if(SLAValue == '00:00')
                        { // Means already violated & Calculate the overdue    
                            //getMinuteValue = integer.valueOf((milestoneTargetDate.getTime()/1000/60 - System.now().getTime()/1000/60) );
                            getMinuteValue = Integer.valueOf(eachCaseMS.TimeSinceTargetInMins.substringBefore(':'));
                            caseWrapperRec.slaInMinutes = getMinuteValue * -1;
                            //caseWrapperRec.sla = (getMinuteValue/60 * -1) + 'h ' +  Math.mod(getMinuteValue,60) + 'm';
                            caseWrapperRec.sla='Expired';
                            caseWrapperRec.slaColour='red';
                        }
                        else
                        {
                            getMinuteValue = integer.valueOf(SLAValue.substring(0,SLAValue.indexOf(':')));
                            caseWrapperRec.slaInMinutes = getMinuteValue;
                            caseWrapperRec.sla = getMinuteValue/60 + 'h ' +  Math.mod(getMinuteValue,60) + 'm';
                            if(getMinuteValue <= 240)
                            { 
                                caseWrapperRec.slaColour = 'orange'; // Set Orange 
                            }
                            else 
                            {
                                if(getMinuteValue > 240) 
                                {
                                    caseWrapperRec.slaColour='yellow';
                                }
                            }
                        }
                    }
                    else
                    {
                        if(eachCaseMS.IsViolated)
                        {
                            caseWrapperRec.slaColour='red';
                            caseWrapperRec.sla='Expired';
                            getMinuteValue = Integer.valueOf(eachCaseMS.TimeSinceTargetInMins.substringBefore(':'));
                            caseWrapperRec.slaInMinutes = getMinuteValue * -1;
                        }
                        else
                        {
                            caseWrapperRec.slaColour='green';
                            caseWrapperRec.sla='Met';
                            caseWrapperRec.slaInMinutes = eachCaseMS.TargetResponseInMins;
                        }
                    }
                }
                
                if(openMS)
                    lstCaseWithMilestoneWrapper.add(caseWrapperRec);  
            }
            else
            if(!eachCase.CaseMilestones.isEmpty() && eachCase.isClosed)
            {
                for(CaseMilestone eachCaseMS :eachCase.CaseMilestones)
                {
                    if(eachCaseMS.IsViolated)
                    {
                        caseWrapperRec.slaColour='red';
                        caseWrapperRec.sla='Expired';
                    }
                    else
                    {
                        caseWrapperRec.slaColour='green';
                        caseWrapperRec.sla='Met';
                    }
                }
            }
            
            if(eachCase.CaseMilestones.isEmpty())
            {
                caseWrapperRec.sla = 'N/A';  
                caseWrapperRec.slaColour = 'N/A';  
                caseWrapperRec.slaInMinutes = 9999;
            }
            
            if(!eachCase.Tasks.isEmpty())
            {
                lstCaseWithTaskWrapper.add(caseWrapperRec);
            }
            
            lstCaseWrapper.add(caseWrapperRec);
        }
        System.debug(lstCaseWrapper);
        if(ownerFilterValue.equalsIgnoreCase('My Open Cases with Tasks'))
            return lstCaseWithTaskWrapper;
        else
            if(ownerFilterValue.equalsIgnoreCase('My Team\'s Open Cases with SLA running'))
            return lstCaseWithMilestoneWrapper;
        else
            return lstCaseWrapper;
    }
    
    @AuraEnabled
    public static Integer getCaseListForAMGCount(String ownerFilterValue, String userOrQueue)
    {
        Integer caseCount = 0;Integer caseCountMilestone = 0;Integer caseCountTask = 0;
        System.debug(ownerFilterValue + userOrQueue);
        List<Case> caseLst = new List<Case>();
        Id amgRecType = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        
        String baseQuery = 'SELECT Id,isClosed,AKAM_Case_ID__c, ' 
            + ' (Select Id from Tasks), '
            + ' (Select MilestoneType.Name,StartDate,IsCompleted,IsViolated,TargetResponseInMins,TimeRemainingInMins, BusinessHoursId, TimeRemainingInDays, TimeSinceTargetInMins, TimeSinceTargetInDays,TargetDate,ElapsedTimeInMins From CaseMilestones'
            + ' WHERE ( MilestoneType.Name =\'Initial Response\' AND Case.RecordType.Name = \'AMG\' AND Case.AMG_Transition__c = false )'
            + ' OR ( MilestoneType.Name =\'User Setup\' AND Case.RecordType.Name = \'AMG\') '
            + ' OR ( MilestoneType.Name =\'AMG Post Transition Initial Response\' AND Case.RecordType.Name = \'AMG\' AND Case.AMG_Transition__c = true ))'
            + ' FROM Case WHERE RecordTypeId = \'' + amgRecType + '\'';
        
        String closedCaseQuery = ' AND IsClosed = TRUE AND CLOSEDDATE >= LAST_N_MONTHS:2';
        String openCaseQuery = ' AND IsClosed = FALSE';
        String loggedInUserQuery = ' and OwnerId = \'' + UserInfo.getUserId() + '\'';
        
        if(userOrQueue == 'user')
        {
            User currentUser = [Select Id,Availability__c,Profile.Name,Backup_User__c,Backup_User__r.Profile.Name,Backup_User__r.Availability__c,ManagerId
                                FROM User 
                                WHERE Id = :Userinfo.getUserId()];
            Id managerId = currentUser.ManagerId;
            
            Map<Id,User> teamIDs = new Map<Id,User>();
            
            Boolean isAvailable = currentUser.Availability__c;
            Boolean isUserManager = FALSE;
            
            teamIDs = new Map<Id,User>([SELECT ID FROM User 
                                        WHERE ManagerId = :UserInfo.getUserId() 
                                        AND IsActive = TRUE]);
            if(teamIDs.isEmpty())
            {
                teamIDs = new Map<Id,User>([SELECT ID FROM User WHERE ManagerId = :managerId AND IsActive = TRUE]);
            }
            
            if(ownerFilterValue.equalsIgnoreCase('My Open Cases') || ownerFilterValue.equalsIgnoreCase('My Open Cases with Tasks'))
                baseQuery+= loggedInUserQuery + openCaseQuery;
            else
                if(ownerFilterValue.equalsIgnoreCase('My Closed Cases (Last 3 Months)'))
                baseQuery+= loggedInUserQuery + closedCaseQuery;
            else
                if(ownerFilterValue.equalsIgnoreCase('My Team\'s Open Cases with SLA running') && !teamIDs.isEmpty())
            {
                Set<Id> idKeySet = teamIDs.keySet();
                baseQuery+= ' and OwnerId IN :idKeySet ' + openCaseQuery;
            }
        }
        else if(userOrQueue == 'queue')
        {
            baseQuery = getCasesForAMGQueue(ownerFilterValue);
        }
        
        String orderByQuery = ' ORDER BY CreatedDate DESC LIMIT 5000';
        
        baseQuery+= orderByQuery;
        
        caseLst = Database.query(baseQuery);
        Boolean openMS = false;
        
        for(Case eachCase : caseLst)
        {
            openMS = false;
            /*
            if(!eachCase.CaseMilestones.isEmpty())
            {    
                caseCountMilestone++;
            }
            */

            if(!eachCase.CaseMilestones.isEmpty() && !eachCase.isClosed)
            {    
                for(CaseMilestone eachCaseMS :eachCase.CaseMilestones)
                {
                    if(!eachCaseMS.IsCompleted)
                    {
                        openMS = true;
                    }
                }
                
                if(openMS)
                {
                    caseCountMilestone++;
                }
            }
            
            if(!eachCase.Tasks.isEmpty())
            {
                caseCountTask++;
            }
            caseCount++;
        }
        
        if(ownerFilterValue.equalsIgnoreCase('My Open Cases with Tasks'))
            return caseCountTask;
        else
            if(ownerFilterValue.equalsIgnoreCase('My Team\'s Open Cases with SLA Running'))
            return caseCountMilestone;
        else
            return caseCount;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<Id> getCaseOwnerList(String owner)
    {
        List<Id> ownerIdLst = new List<Id>();
        Map<Id,User> ownerMap = new Map<Id,User>();
        if(owner == 'team')
        {
            //ownerMap = new Map<Id,User>([SELECT Id FROM User WHERE ManagerId = :loggedInManagerId and isActive=true]);
        }
        return ownerIdLst;
    }
    
    @AuraEnabled
    public static List<User> searchAMGManagers( String searchTerm ) 
    {
        List<User> users = new List<User>();
        if ( String.isNotBlank( searchTerm ) ) {
            List<List<SObject>> searchResults = [
                FIND :searchTerm
                RETURNING User(
                    Id,Name,FirstName,LastName,Email
                    WHERE IsActive = TRUE AND Profile.Name like '%AMG%'
                    ORDER BY Name
                    LIMIT 10
                )
            ];
        }
        return users;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<String> getAMGQueues()
    {
        List<String> amgQueues = new List<String>();
        List<Group> amgQueue = [Select Id, Name From Group Where Type = 'Queue' 
                                And Name like '%AMG%'];
        for(Group eachGroup : amgQueue)
        {
            amgQueues.add(eachGroup.Name);
        }
        amgQueues.add('Transition Queue');
        return amgQueues;
    }
    
    @AuraEnabled
    public static Boolean toggleUserAvailability()
    {
        User userRec = [SELECT Availability__c,Backup_User__c,Backup_User__r.Availability__c FROM User WHERE Id = :UserInfo.getUserId()];
        userRec.Availability__c = !userRec.Availability__c;
        if(userRec.Availability__c)
            userRec.Backup_User__c = NULL;
        try
        {
            update userRec;
        }
        catch(Exception e) {}
        return userRec.Availability__c;
    }
    
    @AuraEnabled
    public static String addBackupUser(String backupId)
    {
        User u;String backupName = '';
        if(String.isBlank(backupId))
        {
            System.debug('Blank Backup');
            u = [SELECT Backup_User__c,Profile.Name,IsActive FROM User WHERE Id = :UserInfo.getUserId()];
            u.Backup_User__c = NULL;
            try {update u;}
            catch(Exception e){throw new AuraHandledException(e.getMessage());  }
            return NULL;
        }
        else
        {
            if(backupId.equalsIgnoreCase(UserInfo.getUserId())) {throw new AuraHandledException('You cannot add yourself as Backup'); }
            else
            {
                System.debug('Update Backup');
                List<String> amgProfileSet = [SELECT Value_Text__c FROM SC_Utility__mdt WHERE DeveloperName = 'AMG_Agent_Profile_List' AND Active__c = TRUE].Value_Text__c.split(',');
                Map<Id,User> userMap = new Map<Id,User>([SELECT Backup_User__c,Backup_User__r.Name,Profile.Name,IsActive,Name FROM User WHERE Id = :UserInfo.getUserId() OR Id = :backupId]);
                if(!userMap.isEmpty() && !amgProfileSet.contains(userMap.get(backupId).Profile.Name))
                {throw new AuraHandledException('Please select an AMG Agent as Backup');}
                else
                {
                    u =  userMap.get(UserInfo.getUserId());
                    backupName = u.Name;
                    u.Backup_User__c = backupId;
                    try
                    {
                        update u;
                    }
                    catch(Exception e){throw new AuraHandledException(e.getMessage());}
                }
            }
            return backupName;
        }
    }
    
    @AuraEnabled
    public static String SLAAlertButtonColor(String ownerFilterValue)
    {        
        Integer caseCount = 0;Integer caseCountMilestone = 0;Integer caseCountTask = 0;
        
        List<Case> lstCasesForButton = new List<Case>();
        List<Case> msCases = new List<Case>();
        List<Case> taskCases = new List<Case>();
        List<Case> lstCasesToProcess = new List<Case>();
        Id amgRecType = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        
        String baseQuery = 'SELECT Id,Request_Type__c,Do_Not_Show_in_Portal__c,IsClosed,' 
            + ' (Select Id from Tasks where Status != \'Completed\'), '
            + ' (Select MilestoneType.Name,StartDate,IsCompleted,IsViolated,TargetResponseInMins,TimeRemainingInMins, BusinessHoursId, TimeRemainingInDays, TimeSinceTargetInMins, TimeSinceTargetInDays,TargetDate,ElapsedTimeInMins From CaseMilestones'
            + ' WHERE ( MilestoneType.Name =\'Initial Response\' AND Case.RecordType.Name = \'AMG\' AND Case.AMG_Transition__c = false )'
            + ' OR ( MilestoneType.Name =\'User Setup\' AND Case.RecordType.Name = \'AMG\') '
            + ' or ( MilestoneType.Name =\'AMG Post Transition Initial Response\' AND Case.RecordType.Name = \'AMG\' AND Case.AMG_Transition__c = true ))'
            + ' FROM Case WHERE RecordTypeId = \'' + amgRecType + '\'';
        
        String closedCaseQuery = ' AND IsClosed = TRUE AND ClosedDate >= LAST_N_MONTHS:2 ';
        String openCaseQuery = ' AND IsClosed = FALSE';
        String loggedInUserQuery = ' and OwnerId = \'' + UserInfo.getUserId() + '\'';
        
        User currentUser = [Select Id,Availability__c,Profile.Name,Backup_User__c,Backup_User__r.Profile.Name,ManagerId
                            FROM User 
                            WHERE Id = :Userinfo.getUserId()];
        Id managerId = currentUser.ManagerId;
        
        Map<Id,User> teamIDs = new Map<Id,User>();
        
        Boolean isAvailable = currentUser.Availability__c;
        Boolean isUserManager = FALSE;
        Map<String,String> slaMap = new Map<String,String>();
        String slaColourCount = 'green_0::Green(0)';
        
        teamIDs = new Map<Id,User>([SELECT ID FROM User 
                                    WHERE ManagerId = :UserInfo.getUserId() 
                                    AND IsActive = TRUE]);
        if(teamIDs.isEmpty())
        {
            teamIDs = new Map<Id,User>([SELECT ID FROM User WHERE ManagerId = :managerId AND IsActive = TRUE]);
        }
        
        if(ownerFilterValue.equalsIgnoreCase('My Open Cases') || ownerFilterValue.equalsIgnoreCase('My Open Cases with Tasks'))
            baseQuery+= loggedInUserQuery + openCaseQuery;
        else
            if(ownerFilterValue.equalsIgnoreCase('My Closed Cases (Last 3 Months)'))
            baseQuery+= loggedInUserQuery + closedCaseQuery;
        else
            if(ownerFilterValue.equalsIgnoreCase('My Team\'s Open Cases with SLA Running') && !teamIDs.isEmpty())
        {
            Set<Id> idKeySet = teamIDs.keySet();
            baseQuery+= ' and OwnerId IN :idKeySet ' + openCaseQuery;
        }
        
        String orderByQuery = ' ORDER BY CreatedDate DESC LIMIT 5000';
        
        baseQuery+= orderByQuery;
        System.debug(baseQuery);
        
        lstCasesForButton = Database.query(baseQuery);
        
        String SLAValue = ''; 
        DateTime milestoneTargetDate;     
        Integer getMinuteValue;
        Boolean openMS = false;
        
        List<CaseWrapper> lstCaseWrapper = new List<CaseWrapper>();
        CaseWrapper caseWrapperRec = new CaseWrapper();
        Map<String,Set<Case>> slaColourCaseSetMap = new Map<String,Set<Case>>();
        Set<Case> orangeCase = new Set<Case>();Set<Case> yellowCase = new Set<Case>();
        Set<Case> redCase = new Set<Case>();Set<Case> greenCase = new Set<Case>();
        
        for(Case eachCase : lstCasesForButton)
        {
            if(!eachCase.CaseMilestones.isEmpty() && !eachCase.isClosed)
            {    
                for(CaseMilestone eachCaseMS :eachCase.CaseMilestones)
                {
                    if(!eachCaseMS.IsCompleted)
                    {
                        msCases.add(eachCase);
                    }
                }
                
                if(!eachCase.Tasks.isEmpty()) {taskCases.add(eachCase);}
                lstCasesToProcess.add(eachCase);
            }
        }
        
        if(ownerFilterValue.equalsIgnoreCase('My Open Cases') || ownerFilterValue.equalsIgnoreCase('My Closed Cases (Last 3 Months)'))
            lstCasesForButton = lstCasesToProcess;
        else
            if(ownerFilterValue.equalsIgnoreCase('My Open Cases with Tasks'))
            lstCasesForButton = taskCases;
        else
            if(ownerFilterValue.equalsIgnoreCase('My Team\'s Open Cases with SLA Running'))
            lstCasesForButton = msCases;        
        
        System.debug('SIZE : ' + lstCasesForButton.size());
        
        for(case eachCase : lstCasesForButton)
        {
            if(!eachCase.CaseMilestones.isEmpty())
            { 
                for(CaseMilestone eachCaseMS : eachCase.CaseMilestones)
                {
                    SLAValue = eachCaseMS.TimeRemaininginMins; 
                    milestoneTargetDate = eachCaseMS.TargetDate; 
                    
                    String milestoneName = eachCaseMS.MilestoneType.Name;
                    
                    if((milestoneName == 'Initial Response' || milestoneName == 'User Setup' || milestoneName == 'AMG Post Transition Initial Response') 
                       && !eachCase.IsClosed)
                    {
                        if(!eachCaseMS.IsCompleted && !eachCaseMS.IsViolated)
                        {
                            getMinuteValue = Integer.valueOf(SLAValue.substring(0,SLAValue.indexOf(':')));
                            
                            // COMPUTE FOR ORANGE/YELLOW
                            if(getMinuteValue <= 240) { orangeCase.add(eachCase);}
                            else if(getMinuteValue > 240) 
                                yellowCase.add(eachCase);
                        }
                        else if(!eachCaseMS.IsViolated && eachCaseMS.IsCompleted) {greenCase.add(eachCase);}
                        else if(eachCaseMS.IsViolated) {redCase.add(eachCase);}
                    }
                    else
                    {
                        if((milestoneName == 'Initial Response' || milestoneName == 'User Setup' || milestoneName == 'AMG Post Transition Initial Response') 
                           && eachCase.IsClosed)
                        {
                            if(!eachCaseMS.IsViolated && eachCaseMS.IsCompleted) {greenCase.add(eachCase);}
                            else if(eachCaseMS.IsViolated) {redCase.add(eachCase);}         
                        }
                    }
                }
            }
        }
        
        System.debug('orangeCase : ' + orangeCase);
        System.debug('yellowCase : ' + yellowCase);
        System.debug('redCase : ' + redCase);
        System.debug('greenCase : ' + greenCase);
        
        if(!greenCase.isEmpty())
        {
            slaColourCount = 'green_' + greenCase.size() + '::' + 'Green(' + greenCase.size() + ')';
            slaMap.put('colour','green');
            slaMap.put('count',String.valueOf(greenCase.size()));
        }
        
        if(!redCase.isEmpty())
        {
            slaColourCount = 'red_' + redCase.size() + '::' + 'Red(' + redCase.size() + ')';
            slaMap.put('colour','red');
            slaMap.put('count',String.valueOf(redCase.size()));
        }
        
        if(!yellowCase.isEmpty())
        {
            slaColourCount = 'yellow_' + yellowCase.size() + '::' + 'Yellow(' + yellowCase.size() + ')';
            slaMap.put('colour','yellow');
            slaMap.put('count',String.valueOf(yellowCase.size()));
        }
        
        if(!orangeCase.isEmpty())
        {
            Integer sum = orangeCase.size() + yellowCase.size();
            if(!yellowCase.isEmpty()) {slaColourCount = 'orange_' + sum + '::' + 'Orange (' + orangeCase.size() + '), Yellow (' + yellowCase.size() + ')';}
            else
            {slaColourCount = 'orange_' + sum + '::' + 'Orange(' + sum + ')';}
            slaMap.put('colour','orange');
            slaMap.put('count',String.valueOf(orangeCase.size() + yellowCase.size()));
        }
                
        if(slaMap.isEmpty())
        {
            slaMap.put('colour','green');
            slaMap.put('count','0');
        }
        return slaColourCount;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<CaseWrapper> populateSLACases(String ownerFilterValue)
    {
        Integer caseCount = 0;Integer caseCountMilestone = 0;Integer caseCountTask = 0;
        
        List<Case> lstCasesForButton = new List<Case>();
        List<Case> msCases = new List<Case>();
        List<Case> taskCases = new List<Case>();
        List<Case> lstCasesToProcess = new List<Case>();
        
        Id amgRecType = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        
        String baseQuery = 'SELECT Id, Age_days__c,AKAM_Case_ID__c,Do_Not_Show_In_Portal_Picklist__c,Origin,Account.Name,Contact.Name,Age_Business_Days__c,Last_Update_By__c,AMG_Transition__c , '
            + ' ContactId,Case_Account_Name__c,AccountId,Support_Level__c,Subject,Severity__c, Service__c,BusinessHoursId,Override_Next_Case_Update__c,Owner.Name,AKAM_Modified_By__c, '
            + ' Request_Type__c,Description,OwnerId,CreatedDate,Account.Support_Level__c,Status,Priority,IsClosed,Last_Case_Owner_Update__c,Last_Non_Case_Owner_Update__c,LastModifiedDate,Last_Case_Update__c,Last_Customer_Activity_Date__c ,Service_Incident__c,Do_Not_Show_in_Portal__c, ' 
            + ' (Select Id from Tasks where Status != \'Completed\'), '
            + ' (Select MilestoneType.Name,StartDate,IsCompleted,IsViolated,TargetResponseInMins,TimeRemainingInMins, BusinessHoursId, TimeRemainingInDays, TimeSinceTargetInMins, TimeSinceTargetInDays,TargetDate,ElapsedTimeInMins From CaseMilestones'
            + ' WHERE ( MilestoneType.Name =\'Initial Response\' AND Case.RecordType.Name = \'AMG\' AND Case.AMG_Transition__c = false ) '
            + ' OR ( MilestoneType.Name =\'User Setup\' AND Case.RecordType.Name = \'AMG\') '
            + ' OR ( MilestoneType.Name =\'AMG Post Transition Initial Response\' AND Case.RecordType.Name = \'AMG\' AND Case.AMG_Transition__c = true ))'
            + ' FROM Case WHERE RecordTypeId = \'' + amgRecType + '\'';
        
        String closedCaseQuery = ' AND IsClosed = TRUE and CLOSEDDATE >= LAST_N_MONTHS:2';
        String openCaseQuery = ' AND IsClosed = FALSE';
        String loggedInUserQuery = ' and OwnerId = \'' + UserInfo.getUserId() + '\'';
        
        User currentUser = [Select Id,Availability__c,Profile.Name,Backup_User__c,Backup_User__r.Profile.Name,ManagerId
                            FROM User 
                            WHERE Id = :Userinfo.getUserId()];
        Id managerId = currentUser.ManagerId;
        
        Map<Id,User> teamIDs = new Map<Id,User>();
        
        Boolean isAvailable = currentUser.Availability__c;
        Boolean isUserManager = FALSE;
        
        teamIDs = new Map<Id,User>([SELECT ID FROM User 
                                    WHERE ManagerId = :UserInfo.getUserId() 
                                    AND IsActive = TRUE]);
        if(teamIDs.isEmpty())
        {
            teamIDs = new Map<Id,User>([SELECT ID FROM User WHERE ManagerId = :managerId AND IsActive = TRUE]);
        }
        
        if(ownerFilterValue.equalsIgnoreCase('My Open Cases') || ownerFilterValue.equalsIgnoreCase('My Open Cases with Tasks'))
            baseQuery+= loggedInUserQuery + openCaseQuery;
        else
            if(ownerFilterValue.equalsIgnoreCase('My Closed Cases (Last 3 Months)'))
            baseQuery+= loggedInUserQuery + closedCaseQuery;
        else
            if(ownerFilterValue.equalsIgnoreCase('My Team\'s Open Cases with SLA Running') && !teamIDs.isEmpty())
        {
            Set<Id> idKeySet = teamIDs.keySet();
            baseQuery+= ' and OwnerId IN :idKeySet ' + openCaseQuery;
        }
        
        String orderByQuery = ' ORDER BY CreatedDate DESC LIMIT 5000';
        
        baseQuery+= orderByQuery;
        System.debug(baseQuery);
        
        lstCasesForButton = Database.query(baseQuery);
        
        String SLAValue = ''; 
        DateTime milestoneTargetDate;     
        Integer getMinuteValue;
        Boolean openMS = false;
        
        List<CaseWrapper> lstCaseWrapper = new List<CaseWrapper>();
        CaseWrapper caseWrapperRec = new CaseWrapper();
        Map<String,Set<Case>> slaColourCaseSetMap = new Map<String,Set<Case>>();
        
        Set<Case> orangeCase = new Set<Case>();Set<Case> yellowCase = new Set<Case>();
        Set<Case> redCase = new Set<Case>();Set<Case> greenCase = new Set<Case>();
        
        for(Case eachCase : lstCasesForButton)
        {
            if(!eachCase.CaseMilestones.isEmpty() && !eachCase.isClosed)
            {    
                for(CaseMilestone eachCaseMS :eachCase.CaseMilestones)
                {
                    if(!eachCaseMS.IsCompleted)
                    {
                        msCases.add(eachCase);
                    }
                }
                
                if(!eachCase.Tasks.isEmpty()) {taskCases.add(eachCase);}
                lstCasesToProcess.add(eachCase);
            }
        }
        
        if(ownerFilterValue.equalsIgnoreCase('My Open Cases') || ownerFilterValue.equalsIgnoreCase('My Closed Cases (Last 3 Months)'))
            lstCasesForButton = lstCasesToProcess;
        else
            if(ownerFilterValue.equalsIgnoreCase('My Open Cases with Tasks'))
            lstCasesForButton = taskCases;
        else
            if(ownerFilterValue.equalsIgnoreCase('My Team\'s Open Cases with SLA Running'))
            lstCasesForButton = msCases;        
        
        System.debug('SIZE : ' + lstCasesForButton.size());
        
        for(case eachCase : lstCasesForButton)
        {
            if(!eachCase.CaseMilestones.isEmpty())
            { 
                for(CaseMilestone eachCaseMS : eachCase.CaseMilestones)
                {
                    SLAValue = eachCaseMS.TimeRemaininginMins; 
                    milestoneTargetDate = eachCaseMS.TargetDate; 
                    
                    String milestoneName = eachCaseMS.MilestoneType.Name;
                    
                    if((milestoneName == 'Initial Response' || milestoneName == 'User Setup' || milestoneName == 'AMG Post Transition Initial Response') 
                       && !eachCase.IsClosed)
                    {
                        if(!eachCaseMS.IsCompleted && !eachCaseMS.IsViolated)
                        {
                            getMinuteValue = Integer.valueOf(SLAValue.substring(0,SLAValue.indexOf(':')));
                            
                            // COMPUTE FOR ORANGE/YELLOW
                            if(getMinuteValue <= 240) { orangeCase.add(eachCase);}
                            else if(getMinuteValue > 240) 
                                yellowCase.add(eachCase);
                        }
                        else if(!eachCaseMS.IsViolated && eachCaseMS.IsCompleted) {greenCase.add(eachCase);}
                        else if(eachCaseMS.IsViolated) { redCase.add(eachCase);}
                    }
                    else
                    {
                        if((milestoneName == 'Initial Response' || milestoneName == 'User Setup' || milestoneName == 'AMG Post Transition Initial Response') 
                           && eachCase.IsClosed)
                        {
                            if(!eachCaseMS.IsViolated && eachCaseMS.IsCompleted){greenCase.add(eachCase);}
                            else if(eachCaseMS.IsViolated) {redCase.add(eachCase);}         
                        }
                    }
                }
            }
        }
        
        System.debug('orangeCase : ' + orangeCase.size());
        System.debug('yellowCase : ' + yellowCase.size());
        System.debug('redCase : ' + redCase.size());
        System.debug('greenCase : ' + greenCase.size());
        if(!orangeCase.isEmpty())
        {
            for(Case eachCase : orangeCase)
            {
                caseWrapperRec = new CaseWrapper();
                caseWrapperRec.caseRec = eachCase;
                caseWrapperRec.caseRecId = eachCase.Id;
                caseWrapperRec.contactName = eachCase.Contact.Name;
                caseWrapperRec.contactId = eachCase.ContactId;
                caseWrapperRec.subject = eachCase.Subject;
                caseWrapperRec.description = eachCase.Description;
                caseWrapperRec.akamcaseid = eachCase.AKAM_Case_ID__c;
                caseWrapperRec.visibility = eachCase.Do_Not_Show_In_Portal_Picklist__c;
                caseWrapperRec.agedays = eachCase.Age_days__c;
                caseWrapperRec.origin = eachCase.Origin;
                caseWrapperRec.accountName = eachCase.Case_Account_Name__c;
                caseWrapperRec.accountId = eachCase.AccountId;
                caseWrapperRec.supportLevel = eachCase.Support_Level__c;
                caseWrapperRec.service = eachCase.Service__c;
                caseWrapperRec.transitioned = eachCase.AMG_Transition__c;
                caseWrapperRec.requestType = eachCase.Request_Type__c;
                caseWrapperRec.url = '/lightning/r/Case/' + eachCase.Id + '/view';
                
                if(eachCase.Last_Case_Owner_Update__c != NULL)
                {
                    caseWrapperRec.lastOwnerUpdate = eachCase.Last_Case_Owner_Update__c.format();
                    
                    if(Date.valueOf(eachCase.Last_Case_Owner_Update__c).daysBetween(System.today()) <= 2)
                        caseWrapperRec.lastOwnerUpdateColour = 'green';
                    else
                        caseWrapperRec.lastOwnerUpdateColour = 'yellow';
                }
                if(eachCase.Last_Non_Case_Owner_Update__c  != NULL)
                {
                    caseWrapperRec.lastAkamUpdate = eachCase.Last_Non_Case_Owner_Update__c.format();
                    if(Date.valueOf(eachCase.Last_Non_Case_Owner_Update__c).daysBetween(System.today()) <= 2)
                        caseWrapperRec.lastAkamUpdateColour = 'green';
                    else
                        caseWrapperRec.lastAkamUpdateColour = 'yellow';
                }
                if(eachCase.Last_Customer_Activity_Date__c != NULL)
                {
                    caseWrapperRec.lastCustUpdate = eachCase.Last_Customer_Activity_Date__c.format();
                    if(Date.valueOf(eachCase.Last_Customer_Activity_Date__c).daysBetween(System.today()) <= 2)
                        caseWrapperRec.lastCustUpdateColour = 'yellow';
                    else if(Date.valueOf(eachCase.Last_Customer_Activity_Date__c).daysBetween(System.today()) <= 5)
                        caseWrapperRec.lastCustUpdateColour = 'orange';
                    else
                        caseWrapperRec.lastCustUpdateColour = 'red';
                }
                
                //getMinuteValue = integer.valueOf(SLAValue.substring(0,SLAValue.indexOf(':')));
                //caseWrapperRec.slaInMinutes = getMinuteValue;
                caseWrapperRec.ownername = eachCase.Owner.Name;
                caseWrapperRec.priority = eachCase.Priority;
                caseWrapperRec.status = eachCase.Status;
                caseWrapperRec.hand = '✋🏼';
                caseWrapperRec.slaColour = 'orange';
                
                if(String.isNotBlank(eachCase.Service_Incident__c))
                {
                    caseWrapperRec.incident = '⚠️';
                    caseWrapperRec.incidentId = eachCase.Service_Incident__c;
                }
                
                // age colour
                if(eachCase.Request_Type__c != 'Customer Onboarding' && eachCase.Request_Type__c != 'Existing Customer Onboarding' 
                   && eachCase.Request_Type__c != 'SiteShield Map Degradation')
                {
                    if(eachCase.Age_days__c <= 10)
                        caseWrapperRec.ageColour = 'green';
                    else if(eachCase.Age_days__c <= 20)
                        caseWrapperRec.ageColour = 'yellow';
                    else if (eachCase.Age_days__c <= 30)
                        caseWrapperRec.ageColour = 'orange';
                    else caseWrapperRec.ageColour = 'red';
                }
                if(!eachCase.CaseMilestones.isEmpty() && !eachCase.isClosed)
                {    
                    for(CaseMilestone eachCaseMS :eachCase.CaseMilestones)
                    {
                        SLAValue = eachCaseMS.TimeRemaininginMins; 
                        milestoneTargetDate = eachCaseMS.TargetDate; 
                        
                        if(!eachCaseMS.IsCompleted)
                        {
                            if(SLAValue == '00:00')
                            { 
                                getMinuteValue = integer.valueOf((milestoneTargetDate.getTime()/1000/60 - System.now().getTime()/1000/60) );
                                caseWrapperRec.slaInMinutes = getMinuteValue;
                                caseWrapperRec.sla = '-' + (getMinuteValue/60 * -1) + 'h ' +  Math.mod(getMinuteValue * -1,60) + 'm';
                            }
                            else
                            {
                                getMinuteValue = integer.valueOf(SLAValue.substring(0,SLAValue.indexOf(':')));
                                caseWrapperRec.slaInMinutes = getMinuteValue;
                                caseWrapperRec.sla = getMinuteValue/60 + 'h ' +  Math.mod(getMinuteValue,60) + 'm';
                            }
                        }
                    }
                    
                    // For SLA Color
                    if (getMinuteValue < 0)
                        caseWrapperRec.slaColour = 'red'; 
                    else if(getMinuteValue <= 240)
                    { 
                        caseWrapperRec.slaColour = 'orange'; // Set Orange 
                    }
                    else if(getMinuteValue > 240) 
                        caseWrapperRec.slaColour='yellow';
                    else
                    {
                        caseWrapperRec.slaColour='green';
                        caseWrapperRec.sla='Complete';
                    }
                }
                lstCaseWrapper.add(caseWrapperRec);
            }
        }
        if(!yellowCase.isEmpty())
        {
            for(Case eachCase : yellowCase)
            {
                caseWrapperRec = new CaseWrapper();
                caseWrapperRec.caseRec = eachCase;
                caseWrapperRec.caseRecId = eachCase.Id;
                caseWrapperRec.contactName = eachCase.Contact.Name;
                caseWrapperRec.contactId = eachCase.ContactId;
                caseWrapperRec.subject = eachCase.Subject;
                caseWrapperRec.description = eachCase.Description;
                caseWrapperRec.akamcaseid = eachCase.AKAM_Case_ID__c;
                caseWrapperRec.visibility = eachCase.Do_Not_Show_In_Portal_Picklist__c;
                caseWrapperRec.agedays = eachCase.Age_days__c;
                caseWrapperRec.origin = eachCase.Origin;
                caseWrapperRec.accountName = eachCase.Case_Account_Name__c;
                caseWrapperRec.accountId = eachCase.AccountId;
                caseWrapperRec.supportLevel = eachCase.Support_Level__c;
                caseWrapperRec.service = eachCase.Service__c;
                caseWrapperRec.transitioned = eachCase.AMG_Transition__c;
                caseWrapperRec.requestType = eachCase.Request_Type__c;
                caseWrapperRec.url = '/lightning/r/Case/' + eachCase.Id + '/view';
                
                if(eachCase.Last_Case_Owner_Update__c != NULL)
                {
                    caseWrapperRec.lastOwnerUpdate = eachCase.Last_Case_Owner_Update__c.format();
                    
                    if(Date.valueOf(eachCase.Last_Case_Owner_Update__c).daysBetween(System.today()) <= 2)
                        caseWrapperRec.lastOwnerUpdateColour = 'green';
                    else
                        caseWrapperRec.lastOwnerUpdateColour = 'yellow';
                }
                if(eachCase.Last_Non_Case_Owner_Update__c  != NULL)
                {
                    caseWrapperRec.lastAkamUpdate = eachCase.Last_Non_Case_Owner_Update__c.format();
                    if(Date.valueOf(eachCase.Last_Non_Case_Owner_Update__c).daysBetween(System.today()) <= 2)
                        caseWrapperRec.lastAkamUpdateColour = 'green';
                    else
                        caseWrapperRec.lastAkamUpdateColour = 'yellow';
                }
                if(eachCase.Last_Customer_Activity_Date__c != NULL)
                {
                    caseWrapperRec.lastCustUpdate = eachCase.Last_Customer_Activity_Date__c.format();
                    if(Date.valueOf(eachCase.Last_Customer_Activity_Date__c).daysBetween(System.today()) <= 2)
                        caseWrapperRec.lastCustUpdateColour = 'yellow';
                    else if(Date.valueOf(eachCase.Last_Customer_Activity_Date__c).daysBetween(System.today()) <= 5)
                        caseWrapperRec.lastCustUpdateColour = 'orange';
                    else
                        caseWrapperRec.lastCustUpdateColour = 'red';
                }
                
                caseWrapperRec.ownername = eachCase.Owner.Name;
                caseWrapperRec.priority = eachCase.Priority;
                caseWrapperRec.status = eachCase.Status;
                caseWrapperRec.hand = '✋🏼';
                //caseWrapperRec.slaInMinutes = Integer.valueOf(SLAValue.substring(0,SLAValue.indexOf(':')));;
                caseWrapperRec.slaColour = 'yellow';
                
                if(String.isNotBlank(eachCase.Service_Incident__c))
                {
                    caseWrapperRec.incident = '⚠️';
                    caseWrapperRec.incidentId = eachCase.Service_Incident__c;
                }
                
                // age colour
                if(eachCase.Request_Type__c != 'Customer Onboarding' && eachCase.Request_Type__c != 'Existing Customer Onboarding' 
                   && eachCase.Request_Type__c != 'SiteShield Map Degradation')
                {
                    if(eachCase.Age_days__c <= 10)
                        caseWrapperRec.ageColour = 'green';
                    else if(eachCase.Age_days__c <= 20)
                        caseWrapperRec.ageColour = 'yellow';
                    else if (eachCase.Age_days__c <= 30)
                        caseWrapperRec.ageColour = 'orange';
                    else caseWrapperRec.ageColour = 'red';
                }
                if(!eachCase.CaseMilestones.isEmpty() && !eachCase.isClosed)
                {    
                    for(CaseMilestone eachCaseMS :eachCase.CaseMilestones)
                    {
                        SLAValue = eachCaseMS.TimeRemaininginMins; 
                        milestoneTargetDate = eachCaseMS.TargetDate; 
                        
                        if(!eachCaseMS.IsCompleted)
                        {
                            if(SLAValue == '00:00')
                            { 
                                getMinuteValue = integer.valueOf((milestoneTargetDate.getTime()/1000/60 - System.now().getTime()/1000/60) );
                                caseWrapperRec.slaInMinutes = getMinuteValue;
                                caseWrapperRec.sla = '-' + (getMinuteValue/60 * -1) + 'h ' +  Math.mod(getMinuteValue * -1,60) + 'm';
                            }
                            else
                            {
                                getMinuteValue = integer.valueOf(SLAValue.substring(0,SLAValue.indexOf(':')));
                                caseWrapperRec.slaInMinutes = getMinuteValue;
                                caseWrapperRec.sla = getMinuteValue/60 + 'h ' +  Math.mod(getMinuteValue,60) + 'm';
                            }
                        }
                    }
                    
                    // For SLA Color
                    if (getMinuteValue < 0) caseWrapperRec.slaColour = 'red'; 
                    else if(getMinuteValue <= 240) { caseWrapperRec.slaColour = 'orange'; }
                    else if(getMinuteValue > 240) 
                        caseWrapperRec.slaColour='yellow';
                    else
                    {
                        caseWrapperRec.slaColour='green';
                        caseWrapperRec.sla='Complete';
                    }
                }
                lstCaseWrapper.add(caseWrapperRec);
            }
        }
        if(!redCase.isEmpty() && orangeCase.isEmpty() && yellowCase.isEmpty())
        {
            for(Case eachCase : redCase)
            {
                caseWrapperRec = new CaseWrapper();
                caseWrapperRec.caseRec = eachCase;
                caseWrapperRec.caseRecId = eachCase.Id;
                caseWrapperRec.contactName = eachCase.Contact.Name;
                caseWrapperRec.contactId = eachCase.ContactId;
                caseWrapperRec.subject = eachCase.Subject;
                caseWrapperRec.description = eachCase.Description;
                caseWrapperRec.akamcaseid = eachCase.AKAM_Case_ID__c;
                caseWrapperRec.visibility = eachCase.Do_Not_Show_In_Portal_Picklist__c;
                caseWrapperRec.agedays = eachCase.Age_days__c;
                caseWrapperRec.origin = eachCase.Origin;
                caseWrapperRec.accountName = eachCase.Case_Account_Name__c;
                caseWrapperRec.accountId = eachCase.AccountId;
                caseWrapperRec.supportLevel = eachCase.Support_Level__c;
                caseWrapperRec.service = eachCase.Service__c;
                caseWrapperRec.transitioned = eachCase.AMG_Transition__c;
                caseWrapperRec.requestType = eachCase.Request_Type__c;
                caseWrapperRec.url = '/lightning/r/Case/' + eachCase.Id + '/view';
                
                if(eachCase.Last_Case_Owner_Update__c != NULL)
                {
                    caseWrapperRec.lastOwnerUpdate = eachCase.Last_Case_Owner_Update__c.format();
                    
                    if(Date.valueOf(eachCase.Last_Case_Owner_Update__c).daysBetween(System.today()) <= 2)
                        caseWrapperRec.lastOwnerUpdateColour = 'green';
                    else
                        caseWrapperRec.lastOwnerUpdateColour = 'yellow';
                }
                if(eachCase.Last_Non_Case_Owner_Update__c  != NULL)
                {
                    caseWrapperRec.lastAkamUpdate = eachCase.Last_Non_Case_Owner_Update__c.format();
                    if(Date.valueOf(eachCase.Last_Non_Case_Owner_Update__c).daysBetween(System.today()) <= 2)
                        caseWrapperRec.lastAkamUpdateColour = 'green';
                    else
                        caseWrapperRec.lastAkamUpdateColour = 'yellow';
                }
                if(eachCase.Last_Customer_Activity_Date__c != NULL)
                {
                    caseWrapperRec.lastCustUpdate = eachCase.Last_Customer_Activity_Date__c.format();
                    if(Date.valueOf(eachCase.Last_Customer_Activity_Date__c).daysBetween(System.today()) <= 2)
                        caseWrapperRec.lastCustUpdateColour = 'yellow';
                    else if(Date.valueOf(eachCase.Last_Customer_Activity_Date__c).daysBetween(System.today()) <= 5)
                        caseWrapperRec.lastCustUpdateColour = 'orange';
                    else
                        caseWrapperRec.lastCustUpdateColour = 'red';
                }
                
                caseWrapperRec.ownername = eachCase.Owner.Name;
                caseWrapperRec.priority = eachCase.Priority;
                caseWrapperRec.status = eachCase.Status;
                caseWrapperRec.hand = '✋🏼';
                getMinuteValue = Integer.valueOf((milestoneTargetDate.getTime()/1000/60 - System.now().getTime()/1000/60) );
                
                //caseWrapperRec.slaInMinutes = getMinuteValue;
                caseWrapperRec.slaColour = 'red';
                if(String.isNotBlank(eachCase.Service_Incident__c))
                {
                    caseWrapperRec.incident = '⚠️';
                    caseWrapperRec.incidentId = eachCase.Service_Incident__c;
                }
                
                // age colour
                if(eachCase.Request_Type__c != 'Customer Onboarding' && eachCase.Request_Type__c != 'Existing Customer Onboarding' 
                   && eachCase.Request_Type__c != 'SiteShield Map Degradation')
                {
                    if(eachCase.Age_days__c <= 10)
                        caseWrapperRec.ageColour = 'green';
                    else if(eachCase.Age_days__c <= 20)
                        caseWrapperRec.ageColour = 'yellow';
                    else if (eachCase.Age_days__c <= 30)
                        caseWrapperRec.ageColour = 'orange';
                    else caseWrapperRec.ageColour = 'red';
                }
                
                if(!eachCase.CaseMilestones.isEmpty() && !eachCase.isClosed)
                {    
                    for(CaseMilestone eachCaseMS :eachCase.CaseMilestones)
                    {
                        SLAValue = eachCaseMS.TimeRemaininginMins; 
                        milestoneTargetDate = eachCaseMS.TargetDate; 
                        
                        if(!eachCaseMS.IsCompleted)
                        {
                            if(SLAValue == '00:00')
                            { 
                                getMinuteValue = integer.valueOf((milestoneTargetDate.getTime()/1000/60 - System.now().getTime()/1000/60) );
                                caseWrapperRec.slaInMinutes = getMinuteValue;
                                caseWrapperRec.sla = '-' + (getMinuteValue/60 * -1) + 'h ' +  Math.mod(getMinuteValue * -1,60) + 'm';
                            }
                            else
                            {
                                getMinuteValue = integer.valueOf(SLAValue.substring(0,SLAValue.indexOf(':')));
                                caseWrapperRec.slaInMinutes = getMinuteValue;
                                caseWrapperRec.sla = getMinuteValue/60 + 'h ' +  Math.mod(getMinuteValue,60) + 'm';
                            }
                        }
                    }
                    
                    // For SLA Color
                    if (getMinuteValue < 0)
                        caseWrapperRec.slaColour = 'red'; 
                    else if(getMinuteValue <= 240)
                    { 
                        caseWrapperRec.slaColour = 'orange'; // Set Orange 
                    }
                    else if(getMinuteValue > 240) 
                        caseWrapperRec.slaColour='yellow';
                    else
                    {
                        caseWrapperRec.slaColour='green';
                        caseWrapperRec.sla='Complete';
                    }
                }
                    
                lstCaseWrapper.add(caseWrapperRec);
            }
        }
        
        if(!greenCase.isEmpty() && redCase.isEmpty() && orangeCase.isEmpty() && yellowCase.isEmpty())
        {
            for(Case eachCase : greenCase)
            {
                caseWrapperRec = new CaseWrapper();
                caseWrapperRec.caseRec = eachCase;
                caseWrapperRec.caseRecId = eachCase.Id;
                caseWrapperRec.contactName = eachCase.Contact.Name;
                caseWrapperRec.contactId = eachCase.ContactId;
                caseWrapperRec.subject = eachCase.Subject;
                caseWrapperRec.description = eachCase.Description;
                caseWrapperRec.akamcaseid = eachCase.AKAM_Case_ID__c;
                caseWrapperRec.visibility = eachCase.Do_Not_Show_In_Portal_Picklist__c;
                caseWrapperRec.agedays = eachCase.Age_days__c;
                caseWrapperRec.origin = eachCase.Origin;
                caseWrapperRec.accountName = eachCase.Case_Account_Name__c;
                caseWrapperRec.accountId = eachCase.AccountId;
                caseWrapperRec.supportLevel = eachCase.Support_Level__c;
                caseWrapperRec.service = eachCase.Service__c;
                caseWrapperRec.transitioned = eachCase.AMG_Transition__c;
                caseWrapperRec.requestType = eachCase.Request_Type__c;
                caseWrapperRec.url = '/lightning/r/Case/' + eachCase.Id + '/view';
                
                if(eachCase.Last_Case_Owner_Update__c != NULL)
                {
                    caseWrapperRec.lastOwnerUpdate = eachCase.Last_Case_Owner_Update__c.format();
                    
                    if(Date.valueOf(eachCase.Last_Case_Owner_Update__c).daysBetween(System.today()) <= 2)
                        caseWrapperRec.lastOwnerUpdateColour = 'green';
                    else
                        caseWrapperRec.lastOwnerUpdateColour = 'yellow';
                }
                if(eachCase.Last_Non_Case_Owner_Update__c  != NULL)
                {
                    caseWrapperRec.lastAkamUpdate = eachCase.Last_Non_Case_Owner_Update__c.format();
                    
                    if(Date.valueOf(eachCase.Last_Non_Case_Owner_Update__c).daysBetween(System.today()) <= 2)
                        caseWrapperRec.lastAkamUpdateColour = 'green';
                    else
                        caseWrapperRec.lastAkamUpdateColour = 'yellow';
                }
                
                if(eachCase.Last_Customer_Activity_Date__c != NULL)
                {
                    caseWrapperRec.lastCustUpdate = eachCase.Last_Customer_Activity_Date__c.format();
                    if(Date.valueOf(eachCase.Last_Customer_Activity_Date__c).daysBetween(System.today()) <= 2)
                        caseWrapperRec.lastCustUpdateColour = 'yellow';
                    else if(Date.valueOf(eachCase.Last_Customer_Activity_Date__c).daysBetween(System.today()) <= 5)
                        caseWrapperRec.lastCustUpdateColour = 'orange';
                    else
                        caseWrapperRec.lastCustUpdateColour = 'red';
                }
                
                caseWrapperRec.ownername = eachCase.Owner.Name;
                caseWrapperRec.priority = eachCase.Priority;
                caseWrapperRec.status = eachCase.Status;
                caseWrapperRec.hand = '✋🏼';
                caseWrapperRec.slaColour='green';
                
                if(String.isNotBlank(eachCase.Service_Incident__c))
                {
                    caseWrapperRec.incident = '⚠️';
                    caseWrapperRec.incidentId = eachCase.Service_Incident__c;
                }
                
                // age colour
                if(eachCase.Request_Type__c != 'Customer Onboarding' && eachCase.Request_Type__c != 'Existing Customer Onboarding' 
                   && eachCase.Request_Type__c != 'SiteShield Map Degradation')
                {
                    if(eachCase.Age_days__c <= 10)
                        caseWrapperRec.ageColour = 'green';
                    else if(eachCase.Age_days__c <= 20)
                        caseWrapperRec.ageColour = 'yellow';
                    else if (eachCase.Age_days__c <= 30)
                        caseWrapperRec.ageColour = 'orange';
                    else caseWrapperRec.ageColour = 'red';
                }
                
                if(!eachCase.CaseMilestones.isEmpty() && !eachCase.isClosed)
                {    
                    for(CaseMilestone eachCaseMS :eachCase.CaseMilestones)
                    {
                        SLAValue = eachCaseMS.TimeRemaininginMins; 
                        milestoneTargetDate = eachCaseMS.TargetDate; 
                        
                        if(!eachCaseMS.IsCompleted)
                        {
                            if(SLAValue == '00:00')
                            { 
                                getMinuteValue = integer.valueOf((milestoneTargetDate.getTime()/1000/60 - System.now().getTime()/1000/60) );
                                caseWrapperRec.slaInMinutes = getMinuteValue;
                                caseWrapperRec.sla = '-' + (getMinuteValue/60 * -1) + 'h ' +  Math.mod(getMinuteValue * -1,60) + 'm';
                            }
                            else
                            {
                                getMinuteValue = integer.valueOf(SLAValue.substring(0,SLAValue.indexOf(':')));
                                caseWrapperRec.slaInMinutes = getMinuteValue;
                                caseWrapperRec.sla = getMinuteValue/60 + 'h ' +  Math.mod(getMinuteValue,60) + 'm';
                            }
                        }
                    }
                    
                    // For SLA Color
                    if (getMinuteValue < 0)
                        caseWrapperRec.slaColour = 'red'; 
                    else if(getMinuteValue <= 240)
                    { 
                        caseWrapperRec.slaColour = 'orange'; // Set Orange 
                    }
                    else if(getMinuteValue > 240) 
                        caseWrapperRec.slaColour='yellow';
                    else
                    {
                        caseWrapperRec.slaColour='green';
                        caseWrapperRec.sla='Complete';
                    }
                }
                lstCaseWrapper.add(caseWrapperRec);
            }
        }
        return lstCaseWrapper;
    }
    
    @AuraEnabled(cacheable=true)
    public static String ageingCasesCount(String ownerFilterValue)
    {
        List<Case> caseList = new List<Case>();
        List<Case> caseWithTaskList = new List<Case>();

        String ageingColourCount = 'green_0::G(0)';
        List<Case> orangeAgedCases = new List<Case>();
        List<Case> yellowAgedCases = new List<Case>();
        List<Case> redAgedCases = new List<Case>();
        List<Case> greenAgedCases = new List<Case>();

        User currentUser = [Select Id,Availability__c,Profile.Name,Backup_User__c,Backup_User__r.Profile.Name,
                            ManagerId 
                            FROM User 
                            WHERE Id = :Userinfo.getUserId()];
        Id managerId = currentUser.ManagerId;
        
        Map<Id,User> teamIDs = new Map<Id,User>();
        
        Boolean isAvailable = currentUser.Availability__c;
        Boolean isUserManager = TRUE;
        
        teamIDs = new Map<Id,User>([SELECT ID FROM User 
                                    WHERE ManagerId = :UserInfo.getUserId() 
                                    AND IsActive = TRUE]);
        if(teamIDs.isEmpty())
        {
            isUserManager = FALSE;
            teamIDs = new Map<Id,User>([SELECT ID FROM User WHERE ManagerId = :managerId AND IsActive = TRUE]);
        }
        
        if(ownerFilterValue.equalsIgnoreCase('My Open Cases with Tasks'))
        {   
            caseList = [SELECT Id,AKAM_Case_ID__c,Subject,Case_Account_Name__c,AccountId,Status,Age_days__c,Do_Not_Show_In_Portal_Picklist__c,isClosed,
                        Service__c,Request_Type__c,Owner.Name,OwnerId,Last_Case_Owner_Update__c,LastModifiedDate,Last_Case_Update__c,Last_Non_Case_Owner_Update__c,Last_Customer_Activity_Date__c ,
                        (Select Id from Tasks where Status != 'Completed')
                        FROM Case
                        WHERE OwnerId = :UserInfo.getUserId() 
                        AND IsClosed = FALSE
                        AND Request_Type__c != 'Customer Onboarding' AND Request_Type__c != 'Existing Customer Onboarding' 
                        AND (Request_Type__c != 'SiteShield Map Degradation' AND Service__c != 'Escalation Management')
                        AND RecordType.Name = 'AMG' LIMIT 1000];
        }  
        else
        {
            caseList = [SELECT Id,AKAM_Case_ID__c,Subject,Case_Account_Name__c,AccountId,Status,Age_days__c,Do_Not_Show_In_Portal_Picklist__c,isClosed,
                        Service__c,Request_Type__c,Owner.Name,OwnerId,Last_Case_Owner_Update__c,LastModifiedDate,Last_Case_Update__c,Last_Non_Case_Owner_Update__c,Last_Customer_Activity_Date__c
                        FROM Case
                        WHERE OwnerId = :UserInfo.getUserId() 
                        AND IsClosed = FALSE
                        AND Request_Type__c != 'Customer Onboarding' AND Request_Type__c != 'Existing Customer Onboarding' 
                        AND (Request_Type__c != 'SiteShield Map Degradation' AND Service__c != 'Escalation Management')
                        AND RecordType.Name = 'AMG' LIMIT 1000];
        }

        if(ownerFilterValue.equalsIgnoreCase('My Open Cases with Tasks'))
        {
            for(Case eachCase : caseList)
            {
                if(!eachCase.Tasks.isEmpty())
                {
                    caseWithTaskList.add(eachCase);
                }
            }
            caseList = caseWithTaskList;
        }


        for(Case eachCase : caseList)
        {
            if(eachCase.Age_days__c <= 10)
                greenAgedCases.add(eachCase);
            else if(eachCase.Age_days__c <= 20)
                yellowAgedCases.add(eachCase);
            else if (eachCase.Age_days__c <= 30)
                orangeAgedCases.add(eachCase);
            else redAgedCases.add(eachCase);
        }
        if(!greenAgedCases.isEmpty())
        {
            ageingColourCount = 'green_' + greenAgedCases.size() + '::' + 'Green(' + greenAgedCases.size() + ')';
        }
        if(!redAgedCases.isEmpty())
        {
            ageingColourCount = 'red_' + redAgedCases.size() + '::' + 'Red(' + redAgedCases.size() + ')';
        }
        if(!yellowAgedCases.isEmpty())
        {
            ageingColourCount = 'yellow_' + yellowAgedCases.size() + '::' + 'Yellow(' + yellowAgedCases.size() + ')';
        }
        if(!orangeAgedCases.isEmpty())
        {
            ageingColourCount = 'orange_' + orangeAgedCases.size() + '::' + 'Orange(' + orangeAgedCases.size() + ')';
        }
        
        return ageingColourCount;
    }

    @AuraEnabled(cacheable=true)
    public static List<CaseWrapper> populateAgeingCases(String ownerFilterValue)
    {
        List<CaseWrapper> caseWrapList = new List<CaseWrapper>();
        
        List<Case> caseList = new List<Case>();
        List<Case> caseWithTaskList = new List<Case>();
        List<Case> caseWithMSList = new List<Case>();

        List<Case> greenAgedCases = new List<Case>();
        List<Case> redAgedCases = new List<Case>();
        List<Case> orangeAgedCases = new List<Case>();
        List<Case> yellowAgedCases = new List<Case>();
        
        CaseWrapper cw = new CaseWrapper();
        
        User currentUser = [Select Id,Availability__c,Profile.Name,Backup_User__c,Backup_User__r.Profile.Name,ManagerId
                            FROM User 
                            WHERE Id = :Userinfo.getUserId()];
        Id managerId = currentUser.ManagerId;
        
        Map<Id,User> teamIDs = new Map<Id,User>();
        
        Boolean isAvailable = currentUser.Availability__c;
        Boolean isUserManager = TRUE;
        
        teamIDs = new Map<Id,User>([SELECT ID FROM User 
                                    WHERE ManagerId = :UserInfo.getUserId() 
                                    AND IsActive = TRUE]);
        if(teamIDs.isEmpty())
        {
            isUserManager = FALSE;
            teamIDs = new Map<Id,User>([SELECT ID FROM User WHERE ManagerId = :managerId AND IsActive = TRUE]);
        }
        
        if(!isUserManager)
        {
            caseList = [SELECT Id,AKAM_Case_ID__c,Subject,Case_Account_Name__c,AccountId,Status,Age_days__c,Do_Not_Show_In_Portal_Picklist__c,isClosed,
                        Service__c,Request_Type__c,Owner.Name,OwnerId,Last_Case_Owner_Update__c,LastModifiedDate,Last_Case_Update__c,Last_Non_Case_Owner_Update__c,Last_Customer_Activity_Date__c ,
                        (Select MilestoneType.Name,StartDate,IsCompleted,IsViolated,TargetResponseInMins,
                         TimeRemainingInMins, BusinessHoursId, TimeRemainingInDays, TimeSinceTargetInMins, 
                         TimeSinceTargetInDays,TargetDate,ElapsedTimeInMins From CaseMilestones),
                         (Select Id from Tasks where Status != 'Completed')
                        FROM Case
                        WHERE OwnerId = :UserInfo.getUserId() 
                        AND IsClosed = FALSE
                        AND Request_Type__c != 'Customer Onboarding' AND Request_Type__c != 'Existing Customer Onboarding' 
                        AND (Request_Type__c != 'SiteShield Map Degradation' AND Service__c != 'Escalation Management')
                        AND RecordType.Name = 'AMG' LIMIT 1000];
        }
        else
        if(isUserManager && !teamIDs.isEmpty())
        {
            caseList = [SELECT Id,AKAM_Case_ID__c,Subject,Case_Account_Name__c,AccountId,Status,Age_days__c,Do_Not_Show_In_Portal_Picklist__c,isClosed,
                        Service__c,Request_Type__c,Owner.Name,OwnerId,Last_Case_Owner_Update__c,LastModifiedDate,Last_Case_Update__c,Last_Non_Case_Owner_Update__c,Last_Customer_Activity_Date__c ,
                        (Select MilestoneType.Name,StartDate,IsCompleted,IsViolated,TargetResponseInMins,
                         TimeRemainingInMins, BusinessHoursId, TimeRemainingInDays, TimeSinceTargetInMins, 
                         TimeSinceTargetInDays,TargetDate,ElapsedTimeInMins From CaseMilestones WHERE IsCompleted = FALSE)
                        FROM Case
                        WHERE OwnerId IN :teamIDs.keySet()
                        AND IsClosed = FALSE
                        AND Request_Type__c != 'Customer Onboarding' AND Request_Type__c != 'Existing Customer Onboarding' 
                        AND (Request_Type__c != 'SiteShield Map Degradation' AND Service__c != 'Escalation Management')
                        AND RecordType.Name = 'AMG' LIMIT 1000];
        }
        
        if(isUserManager)
        {
            for(Case eachCase : caseList)
            {
                if(!eachCase.CaseMilestones.isEmpty())
                {
                    caseWithMSList.add(eachCase);
                }
                caseList = caseWithMSList;
            }
        }
        else 
        {
            if(ownerFilterValue.equalsIgnoreCase('My Open Cases with Tasks'))
            {
                for(Case eachCase : caseList)
                {
                    if(!eachCase.Tasks.isEmpty())
                    {
                        caseWithTaskList.add(eachCase);
                    }
                }
                caseList = caseWithTaskList;
            }
        }

        for(Case eachCase : caseList)
        {
            if(eachCase.Age_days__c <= 10)
                greenAgedCases.add(eachCase);
            else if(eachCase.Age_days__c <= 20)
                yellowAgedCases.add(eachCase);
            else if (eachCase.Age_days__c <= 30)
                orangeAgedCases.add(eachCase);
            else redAgedCases.add(eachCase);
        }
        
        caseList.clear();
        
        if(!orangeAgedCases.isEmpty())
            caseList = orangeAgedCases;
        else if(!yellowAgedCases.isEmpty())
            caseList = yellowAgedCases;
        else if(!redAgedCases.isEmpty())
            caseList = redAgedCases;
        else if(!greenAgedCases.isEmpty())
            caseList = greenAgedCases;
        
        for(Case eachCase : caseList)
        {
            cw = new CaseWrapper();
            cw.caseRecId = eachCase.Id;
            cw.subject = eachCase.Subject;
            cw.accountName = eachCase.Case_Account_Name__c;
            cw.akamcaseid = eachCase.AKAM_Case_ID__c;
            cw.status = eachCase.Status;
            cw.agedays = eachCase.Age_days__c;
            cw.visibility = eachCase.Do_Not_Show_In_Portal_Picklist__c;
            cw.service = eachCase.Service__c;
            cw.requestType = eachCase.Request_Type__c;
            cw.url = '/lightning/r/Case/' + eachCase.Id + '/view';

            if(eachCase.Last_Case_Owner_Update__c != NULL)
            {
                cw.lastOwnerUpdate = eachCase.Last_Case_Owner_Update__c.format();
                
                if(Date.valueOf(eachCase.Last_Case_Owner_Update__c).daysBetween(System.today()) <= 2)
                    cw.lastOwnerUpdateColour = 'green';
                else
                    cw.lastOwnerUpdateColour = 'yellow';
            }
            
            if(eachCase.Last_Non_Case_Owner_Update__c != NULL)
            {
                cw.lastAkamUpdate = eachCase.Last_Non_Case_Owner_Update__c.format();
                if(Date.valueOf(eachCase.Last_Non_Case_Owner_Update__c).daysBetween(System.today()) <= 2)
                    cw.lastAkamUpdateColour = 'green';
                else
                    cw.lastAkamUpdateColour = 'yellow';
            }
            if(eachCase.Last_Customer_Activity_Date__c != NULL)
            {
                cw.lastCustUpdate = eachCase.Last_Customer_Activity_Date__c.format();
                if(Date.valueOf(eachCase.Last_Customer_Activity_Date__c).daysBetween(System.today()) <= 2)
                    cw.lastCustUpdateColour = 'yellow';
                else if(Date.valueOf(eachCase.Last_Customer_Activity_Date__c).daysBetween(System.today()) <= 5)
                    cw.lastCustUpdateColour = 'orange';
                else
                    cw.lastCustUpdateColour = 'red';
            }
            
            // age colour
            if(eachCase.Request_Type__c != 'Customer Onboarding' && eachCase.Request_Type__c != 'Existing Customer Onboarding' 
               && eachCase.Request_Type__c != 'SiteShield Map Degradation')
            {
                if(eachCase.Age_days__c <= 10)
                    cw.ageColour = 'green';
                else if(eachCase.Age_days__c <= 20)
                    cw.ageColour = 'yellow';
                else if (eachCase.Age_days__c <= 30)
                    cw.ageColour = 'orange';
                else cw.ageColour = 'red';
            }
            
            cw.ownername = eachCase.Owner.Name;
            
            string SLAValue; 
            DateTime milestoneTargetDate;     
            Integer getMinuteValue;
            Boolean openMS = false;
            String milestoneSLA = '';
            
            if(!eachCase.CaseMilestones.isEmpty() && !eachCase.isClosed)
            {    
                for(CaseMilestone eachCaseMS :eachCase.CaseMilestones)
                {
                    milestoneSLA = eachCaseMS.TimeRemaininginMins; 
                    SLAValue = milestoneSLA; 
                    milestoneTargetDate = eachCaseMS.TargetDate; 
                    
                    if(!eachCaseMS.IsCompleted)
                    {
                        openMS = true;
                        if(SLAValue == '00:00')
                        { // Means already violated & Calculate the overdue    
                            getMinuteValue = integer.valueOf((milestoneTargetDate.getTime()/1000/60 - System.now().getTime()/1000/60) );
                            cw.slaInMinutes = getMinuteValue;
                            cw.sla = '-' + (getMinuteValue/60 * -1) + 'h ' +  Math.mod(getMinuteValue * -1,60) + 'm';
                        }
                        else
                        {
                            getMinuteValue = integer.valueOf(SLAValue.substring(0,SLAValue.indexOf(':')));
                            cw.slaInMinutes = getMinuteValue;
                            cw.sla = getMinuteValue/60 + 'h ' +  Math.mod(getMinuteValue,60) + 'm';
                        }
                    }
                }
                
                // For SLA Color
                if (getMinuteValue < 0)
                    cw.slaColour = 'red'; 
                else if(getMinuteValue <= 240)
                { 
                    cw.slaColour = 'orange';
                }
                else if(getMinuteValue > 240) 
                    cw.slaColour='yellow';
                else
                {
                    cw.slaColour='green';
                    cw.sla='Complete';
                }
            }
            
            if(eachCase.CaseMilestones.isEmpty())
            {
                cw.sla='N/A';  
            }
            
            caseWrapList.add(cw);
        }
        
        System.debug(caseWrapList);
        return caseWrapList;
    }
    
    public class EscalationWrapper
    {
        @AuraEnabled public Engagement_Request__c escRec{get;set;}
        @AuraEnabled public Id escRecId{get;set;}
        @AuraEnabled public Id caseRecId{get;set;}
        @AuraEnabled public String escIDVal{get;set;}
        @AuraEnabled public String akamcaseid{get;set;}
        @AuraEnabled public String systemVal{get;set;}	
        @AuraEnabled public String area{get;set;}	
        @AuraEnabled public String status{get;set;}	
        @AuraEnabled public String accountName{get;set;}	
        @AuraEnabled public String subject{get;set;}	
        @AuraEnabled public String description{get;set;}	
        @AuraEnabled public String akamcreateddate{get;set;}	
    }
    
    @AuraEnabled(cacheable=true)
    public static Integer populateEscalationsCount()
    {
        List<Engagement_Request__c> lstEsc = new List<Engagement_Request__c>();
        
        User currentUser = [Select Id,Availability__c,Profile.Name,Backup_User__c,Backup_User__r.Profile.Name,ManagerId
                            FROM User 
                            WHERE Id = :Userinfo.getUserId()];
        
        Id managerId = currentUser.ManagerId;
        
        Map<Id,User> teamIDs = new Map<Id,User>();
        
        Boolean isUserManager = TRUE;
        
        teamIDs = new Map<Id,User>([SELECT ID FROM User 
                                    WHERE ManagerId = :UserInfo.getUserId() 
                                    AND IsActive = TRUE]);
        if(teamIDs.isEmpty())
        {
            isUserManager = FALSE;
            teamIDs = new Map<Id,User>([SELECT ID FROM User WHERE ManagerId = :managerId AND IsActive = TRUE]);
        }
        
        String escQuery = 'SELECT Id, Case__c,Case__r.Id,Case__r.AKAM_Case_ID__c, ID__c, System__c, Area__c, Request_Status__c,Owner.Name, '
            			+ ' Subject__c,Description__c,AKAM_Created_Date__c,Case__r.Account.Name,Case__r.AccountId,CreatedDate ' 
            			+ ' FROM Engagement_Request__c '
            			+ ' WHERE RecordType.Name = \'AMG Escalation\' ';
        String userQuery = ' AND CreatedById = \'' + UserInfo.getUserId() + '\' ';
        Set<Id> idKeySet = teamIDs.keySet();
        String teamQuery = ' AND CreatedById IN :idKeySet ';
        if(isUserManager) {escQuery+= teamQuery + ' AND Request_Status__c != \'Closed\' LIMIT 500';}
        else
        {
            escQuery+= userQuery + ' AND Request_Status__c != \'Closed\' LIMIT 500';
        }
        
        lstEsc = Database.query(escQuery);
        return lstEsc.size();
    }
    
    @AuraEnabled(cacheable=true)
    public static List<EscalationWrapper> populateEscalations(String filterValue)
    {
        List<Engagement_Request__c> lstEsc = new List<Engagement_Request__c>();
        List<EscalationWrapper> lstEscWrapper = new List<EscalationWrapper>();
        EscalationWrapper escWrapperRec;
        
        //User currentUser = [Select Id,Availability__c,Profile.Name,Backup_User__c,Backup_User__r.Profile.Name,ManagerId FROM User WHERE Id = :Userinfo.getUserId()];
        
        //Id managerId = currentUser.ManagerId;
        
        Map<Id,User> teamIDs = new Map<Id,User>();
        
        Boolean isUserManager = TRUE;
        
        teamIDs = new Map<Id,User>([SELECT ID FROM User 
                                    WHERE ManagerId = :UserInfo.getUserId() 
                                    AND IsActive = TRUE]);
        if(teamIDs.isEmpty())
        {
            isUserManager = FALSE;
            //teamIDs = new Map<Id,User>([SELECT ID FROM User WHERE ManagerId = :managerId AND IsActive = TRUE]);
        }
        
        String escQuery = 'SELECT Id, Case__c,Case__r.Id,Case__r.AKAM_Case_ID__c, ID__c, System__c, Area__c, Request_Status__c,Owner.Name, '
            			+ ' Subject__c,Description__c,AKAM_Created_Date__c,Case__r.Account.Name,Case__r.AccountId,CreatedDate ' 
            			+ ' FROM Engagement_Request__c '
            			+ ' WHERE RecordType.Name = \'AMG Escalation\' ';
        String userQuery = ' AND CreatedById = \'' + UserInfo.getUserId() + '\' ';
        Set<Id> teamIDKeySet = teamIDs.keySet();
        
        //teamIDKeySet.add(UserInfo.getUserId());
        String teamQuery = ' AND (CreatedById IN :teamIDKeySet OR CreatedById = \'' + UserInfo.getUserId() + '\' ) ';
        
        String orderByQuery = ' ORDER BY CreatedDate DESC LIMIT 500';
        if(isUserManager)
        {
            if(filterValue == 'Open Escalations')
            {
                escQuery+= teamQuery + ' AND Request_Status__c != \'Closed\' ';
            }
            else if(filterValue == 'Closed Escalations')
            {
                escQuery+= teamQuery + ' AND Request_Status__c = \'Closed\' AND (CreatedDate >= LAST_N_MONTHS:2) ';
            }
        }
        else
        {
            if(filterValue == 'Open Escalations')
            {
                escQuery+= userQuery + ' AND Request_Status__c != \'Closed\' ';
            }
            else if(filterValue == 'Closed Escalations') {escQuery+= userQuery + ' AND Request_Status__c = \'Closed\' AND (CreatedDate >= LAST_N_MONTHS:2) ';}
        }
        
        escQuery+= orderByQuery;
        System.debug('ESC Query : ' + escQuery);
        lstEsc = Database.query(escQuery);
        
        for(Engagement_Request__c engReq : lstEsc)
        {
            escWrapperRec = new EscalationWrapper();
            escWrapperRec.escRec = engReq;
            escWrapperRec.escRecId = engReq.Id;
            escWrapperRec.escIDVal = engReq.ID__c;
            escWrapperRec.caseRecId = engReq.Case__r.Id;
            escWrapperRec.akamcaseid = engReq.Case__r.AKAM_Case_ID__c;
            escWrapperRec.systemVal = engReq.System__c;
            escWrapperRec.area = engReq.Area__c;
            escWrapperRec.subject = engReq.Subject__c;
            escWrapperRec.accountName = engReq.Case__r.Account.Name;
            escWrapperRec.description = engReq.Description__c;
            escWrapperRec.status = engReq.Request_Status__c;
            escWrapperRec.akamcreateddate = engReq.AKAM_Created_Date__c.format();
            lstEscWrapper.add(escWrapperRec);
        }
        return lstEscWrapper;
    }
    
    @AuraEnabled
    public static String amgEscalationRecTypeId()
    {
        Id amgEscRecTypeId = Engagement_Request__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG Escalation').getRecordTypeId();
        return amgEscRecTypeId;
    }
    
    
    public class SIWrapper
    {
        @AuraEnabled public SC_SI_Service_Incident__c  siRec{get;set;}
        @AuraEnabled public Id siRecId{get;set;}
        @AuraEnabled public String IncidentNumber{get;set;}
        @AuraEnabled public String Title{get;set;}
        @AuraEnabled public String Status{get;set;}	
        @AuraEnabled public String IncidentStart{get;set;}	
        @AuraEnabled public String Urgency{get;set;}	
    }
    
    @AuraEnabled(cacheable=true)
    public static List<SIWrapper> populateIncidents(String incidentFilter)
    {
        String dt = (DateTime.now() - 1).format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        
        List<SC_SI_Service_Incident__c > lstSI = new List<SC_SI_Service_Incident__c >();
        List<SIWrapper> lstSIWrapper = new List<SIWrapper>();
        SIWrapper siWrapperRec;
                
         String baseSIQuery = 'SELECT Id, Name, Severity__c , Impact_Started__c , Title__c ,Status__c '
            + ' FROM SC_SI_Service_Incident__c ' ;
        
       if(incidentFilter.equals('Last 24 Hours')) {baseSIQuery += ' WHERE SI_Incident_Requested_Date__c > ' + dt + ' LIMIT 500';} 

        else if(incidentFilter.equals('All Open Incidents'))
        {
            baseSIQuery += ' WHERE Status__c != \'Closed\' LIMIT 500';
        }
        
        System.debug('baseSIQuery//'+baseSIQuery);
        lstSI = Database.query(baseSIQuery);
        system.debug('lstSI//'+lstSI);
        
        for(SC_SI_Service_Incident__c  si : lstSI)
        {
            siWrapperRec = new SIWrapper();
            siWrapperRec.siRec = si;
            siWrapperRec.siRecId = si.Id;
            siWrapperRec.IncidentNumber = si.Name;
            siWrapperRec.Title = si.Title__c;
            siWrapperRec.Status = si.Status__c;
            siWrapperRec.IncidentStart =  string.valueOf(si.Impact_Started__c.format());
            siWrapperRec.Urgency = si.Severity__c;
            lstSIWrapper.add(siWrapperRec);
        }   
        return lstSIWrapper;
    }  
    
    @AuraEnabled(cacheable=true)
    public static Integer populateIncidentsCount(String incidentFilter)
    {
        String dt = (DateTime.now() - 1).format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        Agent_Home_Collection_Limit__c cl = Agent_Home_Collection_Limit__c.getValues('Limit Value');
        Integer cLimit = cl.Collection_Limit__c.intValue();
        List<SC_SI_Service_Incident__c > lstSI = new List<SC_SI_Service_Incident__c >();
        List<SIWrapper> lstSIWrapper = new List<SIWrapper>();
        SIWrapper siWrapperRec;
                        
         String baseSIQuery = 'SELECT Id, Name, Severity__c , Impact_Started__c , Title__c ,Status__c '
            + ' FROM SC_SI_Service_Incident__c ' ;
        
        if(incidentFilter.equals('Last 24 Hours')) 
        {
          baseSIQuery += ' WHERE SI_Incident_Requested_Date__c > ' + dt + ' LIMIT ' + cLimit;

        } 
        else if(incidentFilter.equals('All Open Incidents'))
        {
            baseSIQuery += ' WHERE Status__c  != \'Closed\' LIMIT ' + cLimit;
        }
        
        System.debug(baseSIQuery);
        lstSI = Database.query(baseSIQuery);
        
        return lstSI.size();
    }
    
    @AuraEnabled
    public static void assignCase(Id caseRecId)
    {
        Case c = [SELECT Id,ContactId from Case WHERE Id = :caseRecId];
        c.OwnerId = UserInfo.getUserId();
        
        String msg = '';
        
        try
        {
            update c;
            sendEmailToOwner(caseRecId,UserInfo.getUserId(),c.ContactId);
        }
        
        catch(Exception e)
        {
            for (Integer i = 0; i < e.getNumDml(); i++) 
            {
                msg =+ e.getDmlMessage(i) +  '\n' ;
            }
        
            throw new AuraHandledException(msg);
        }
    }
    
    @AuraEnabled
    public static void assignCaseToUser(Id caseRecId,String userId)
    {
        Case c = [SELECT Id,OwnerId,ContactId,Validation_Override__c from Case where Id = :caseRecId];
        
        c.OwnerId = userId;
        c.Validation_Override__c = true;

        String msg = '';

        try
        {
            update c;
            sendEmailToOwner(caseRecId,userId,c.ContactId);
        }
        catch(Exception e)
        {   for (Integer i = 0; i < e.getNumDml(); i++) {msg =+ e.getDmlMessage(i) +  '\n' ;}
            throw new AuraHandledException(msg);
        }
    }
    
    // changes by Vandhana for ESESP-4720 : Email Notification for Case assignment has stopped working
    @future
    public static void sendEmailToOwner(Id caseRecId, String userId, String contactId)
    {
        List<Messaging.Singleemailmessage> emailList = new List<Messaging.Singleemailmessage>();
        
        EmailTemplate caseAssignmentTemplate = [SELECT Id
                                                FROM EmailTemplate WHERE DeveloperName = 'Case_Assignment_Notification'];
        
        Messaging.SingleEmailMessage singleEmail = new Messaging.SingleEmailMessage();
        singleEmail = Messaging.renderStoredEmailTemplate(caseAssignmentTemplate.Id, contactId, caseRecId);
        singleEmail.setTargetObjectId(userId);
        singleEmail.saveAsActivity = false;
        singleEmail.setOrgWideEmailAddressId(SC_FromEmailAddress__c.getValues('Noreply').OrgAddressId__c);
        singleEmail.saveAsActivity = false;
        singleEmail.setUseSignature(false);
        emailList.add(singleEmail);
        if(emailList.size() > 0) 
        {
            Messaging.SendEmailResult [] r = Messaging.sendEmail(emailList);
        }
    }
    
    @AuraEnabled
    public static User getUserAvailabilility()
    {
        User u = [SELECT Id,Availability__c,Backup_User__c,Backup_User__r.Name,Backup_User__r.Availability__c,Name FROM User WHERE Id = :UserInfo.getUserId()];
        return u;
    }
    
    public class UserWrapper
    {
        @AuraEnabled public String userName{get;set;}
        @AuraEnabled public String backupUserName{get;set;}
        @AuraEnabled public Id userId{get;set;}
        @AuraEnabled public Id backupUserId{get;set;}
        @AuraEnabled public String available{get;set;}
        @AuraEnabled public String backupAvailable{get;set;}
        @AuraEnabled public String atmRole{get;set;}
        @AuraEnabled public String managerName{get;set;}
    }
    
    @AuraEnabled
    public static List<UserWrapper> fetchUserBackup(String userId)
    {
        System.debug('USER ID : ' + userId);
        List<UserWrapper> userWrapperLst = new List<UserWrapper>();
        UserWrapper uw;
        
        User currentUser = [Select Id,Availability__c,Name,Profile.Name,Backup_User__c,Backup_User__r.Profile.Name,Backup_User__r.Availability__c,ManagerId
                            FROM User 
                            WHERE Id = :userId];
        
        Id managerId = currentUser.ManagerId;
        
        Map<Id,User> userTeamMap = new Map<Id,User>();
        
        userTeamMap = new Map<Id,User>([SELECT ID,Name,Availability__c,Backup_User__c,Backup_User__r.Name,          
                                    Backup_User__r.Id,Backup_User__r.Availability__c 
                                    FROM User 
                                    WHERE ManagerId = :userId 
                                    AND IsActive = TRUE order by Name]);
        
        if(userTeamMap.isEmpty())
        {
            userTeamMap = new Map<Id,User>([SELECT ID,Name,Availability__c,Backup_User__c,Backup_User__r.Name,Backup_User__r.Id,Backup_User__r.Availability__c FROM User 
                                        WHERE ManagerId = :managerId 
                                        AND IsActive = TRUE order by Name]);
        }
        

        for(User eachUser : userTeamMap.values())
        {
            uw = new UserWrapper();
            uw.userName = eachUser.Name;
            uw.userId = eachUser.Id;
            uw.backupUserName = eachUser.Backup_User__r.Name;
            uw.backupUserId = eachUser.Backup_User__r.Id;
            uw.available = eachUser.Availability__c ? 'Yes' : 'No';
            if(String.isNotBlank(eachUser.Backup_User__c))
                uw.backupAvailable = eachUser.Backup_User__r.Availability__c ? 'Yes' : 'No';
            
            if(String.valueOf(eachUser.Id).containsIgnoreCase(userId) && userWrapperLst.size() > 0)
                userWrapperLst.add(0,uw);
            else 
                userWrapperLst.add(uw);
        }
        
        return userWrapperLst;
    }
    
    @AuraEnabled
    public static UserWrapper fetchSelectedAMGUser(Id userId)
    {
        UserWrapper uw = new UserWrapper();
        
        User eachUser = [Select Id,Availability__c,Name,Backup_User__c,Backup_User__r.Id,Backup_User__r.Name,ManagerId,Backup_User__r.Availability__c,Manager.Name
                         FROM User 
                         WHERE Id = :userId];
        
        uw.userName = eachUser.Name;
        uw.userId = eachUser.Id;
        uw.backupUserName = eachUser.Backup_User__r.Name;
        uw.backupUserId = eachUser.Backup_User__r.Id;
        uw.available = eachUser.Availability__c ? 'Yes' : 'No';
        if(String.isNotBlank(eachUser.Backup_User__c))
            uw.backupAvailable = eachUser.Backup_User__r.Availability__c ? 'Yes' : 'No';
        uw.managerName = eachUser.Manager.Name;
        return uw;
    }
    
    @AuraEnabled
    public static List<UserWrapper> fetchAccountTeamMembers(String accountId)
    {
        List<UserWrapper> userWrapperLst = new List<UserWrapper>();
        UserWrapper uw;
        
        Set<String> amgProfileNameSet = new Set<String>([Select Value_Text__c 
                                                from SC_Utility__mdt 
                                                where DeveloperName = 'AMG_Agent_Profile_List'].Value_Text__c.split(','));

        List<AccountTeamMember> atmList = new List<AccountTeamMember>();
        atmList = [Select AccountId, UserId,User.Name,User.Backup_User__c,User.Backup_User__r.Name,User.Backup_User__r.Id,User.Backup_User__r.Availability__c,User.Availability__c,
                   TeamMemberRole,User.Manager.Name,User.Profile.Name 
                   From AccountTeamMember 
                   Where AccountId = :accountId 
                   AND (TeamMemberRole = 'Services - Secondary' 
                        OR TeamMemberRole = 'Services - Primary') 
                   AND User.IsActive = true
                   AND User.Profile.Name IN :amgProfileNameSet];
        
        system.debug('atmList//'+atmList);
        
        for(AccountTeamMember eachUser : atmList)
        {
            uw = new UserWrapper();
            uw.userName = eachUser.User.Name;
            uw.userId = eachUser.UserId;
            uw.backupUserName = eachUser.User.Backup_User__r.Name;
            uw.backupUserId = eachUser.User.Backup_User__r.Id;
            uw.available = eachUser.User.Availability__c ? 'Yes' : 'No';
            if(String.isNotBlank(eachUser.User.Backup_User__c))
                uw.backupAvailable = eachUser.User.Backup_User__r.Availability__c ? 'Yes' : 'No';
            uw.atmRole = eachUser.TeamMemberRole;
            uw.managerName = eachUser.User.Manager.Name;
            userWrapperLst.add(uw);
        }
        
        return userWrapperLst;
    }
    
    public class TaskWrapper
    {
        @AuraEnabled public Task taskRec{get;set;}
        @AuraEnabled public Id taskRecId{get;set;}
        @AuraEnabled public Case caseRec{get;set;}
        @AuraEnabled public Id caseRecId{get;set;}
        @AuraEnabled public String caseRecAKAM{get;set;}
        @AuraEnabled public String accountName{get;set;}
        @AuraEnabled public String accountId{get;set;}
        @AuraEnabled public String subject{get;set;}
        @AuraEnabled public String taskType{get;set;}
        @AuraEnabled public String status{get;set;}
        @AuraEnabled public Date dueDate {get;set;}	
        @AuraEnabled public String owner{get;set;}
    }
    
    @AuraEnabled(cacheable=true)
    public static List<TaskWrapper> getOpenTaskAMG(String filterVal,Integer recordLimit, Integer recordOffset)
    {
        List<TaskWrapper> taskWrapperList = new List<TaskWrapper>();
        List<Task> taskList = new List<Task>();
        
        Integer intLimit = Integer.valueof(recordLimit);
        Integer intOffset = Integer.valueof(recordOffset);
        
        Set<Id> caseId = new Set<Id>();
        
        User currentUser = [Select Id,Availability__c,Profile.Name,Backup_User__c,Backup_User__r.Profile.Name,ManagerId
                            FROM User 
                            WHERE Id = :Userinfo.getUserId()];
        Id managerId = currentUser.ManagerId;
        
        Map<Id,User> teamIDs = new Map<Id,User>();
        
        Boolean isAvailable = currentUser.Availability__c;
        Boolean isUserManager = FALSE;
        
        teamIDs = new Map<Id,User>([SELECT ID FROM User 
                                    WHERE ManagerId = :UserInfo.getUserId() 
                                    AND IsActive = TRUE]);
        if(teamIDs.isEmpty())
        {
            teamIDs = new Map<Id,User>([SELECT ID FROM User WHERE ManagerId = :managerId AND IsActive = TRUE]);
        }
        
        String baseTaskQuery = 'SELECT Id, RecordTypeId, WhoId, WhatId, Subject, ActivityDate, Type,Type__c, Status,AKAM_Activity_ID__c,Owner.Name,OwnerId' 
            				   + ' FROM Task ' ; 
        
        String taskUserOwnerQuery = ' WHERE OwnerId = \'' + UserInfo.getUserId() + '\'';
        
        String orderByTaskQuery = ' ORDER BY CreatedDate DESC';
        String limitTaskQuery = ' LIMIT :intLimit OFFSET :intOffset';
        String filterTaskQuery = '';
        
        
        if(filterVal.equalsIgnoreCase('My Tasks Due Today'))
            baseTaskQuery+= taskUserOwnerQuery + ' AND ActivityDate = TODAY AND Status != \'Completed\' AND Status != \'Not Applicable\' ';
        else
            if(filterVal.equalsIgnoreCase('My Open Tasks'))
            baseTaskQuery+= taskUserOwnerQuery + ' AND Status IN (\'Not Started\', \'In Progress\', \'Postponed - Agreed with Customer/IAT\') ';       
        else
            if(filterVal.equalsIgnoreCase('My Overdue Tasks'))
            baseTaskQuery+= taskUserOwnerQuery + ' AND ActivityDate < TODAY AND (Status != \'Completed\' AND Status != \'Not Applicable\') ';
        else
            if(filterVal.equalsIgnoreCase('My Team\'s Open Tasks') && !teamIDs.isEmpty())
        {
            Set<Id> idKeySet = teamIDs.keySet();
            baseTaskQuery+= ' WHERE OwnerId IN :idKeySet ' + ' AND Status IN (\'Not Started\', \'In Progress\', \'Postponed - Agreed with Customer/IAT\') ';
        }
         system.debug('baseTaskQuery2//'+baseTaskQuery);
        baseTaskQuery+= orderByTaskQuery + limitTaskQuery;
        //baseTaskQuery+= orderByTaskQuery;
        system.debug('baseTaskQuery//'+baseTaskQuery);
        
        taskList = Database.query(baseTaskQuery);
         system.debug('taskList//'+taskList);
        
        for(Task t : taskList)
            caseId.add(t.WhatId);
        Map<Id,Case> caseMap = new Map<Id,Case>([SELECT Id,AKAM_Case_ID__c,AccountId,Account.Name FROM CASE
                                                 WHERE Id in :caseId]);
        
        for(Task t : taskList)
        {
            TaskWrapper taskWrap = new TaskWrapper();
            taskWrap.taskRec = t;
            taskWrap.taskRecId = t.Id;
            taskWrap.subject = t.Subject;
            taskWrap.taskType = t.Type__c;
            taskWrap.status = t.Status;
            taskWrap.dueDate = t.ActivityDate;
            taskWrap.owner = t.Owner.Name;
            
            if(caseMap.containsKey(t.WhatId))
            {
                taskWrap.caseRec = caseMap.get(t.WhatId);
                taskWrap.caseRecId = caseMap.get(t.WhatId).Id;
                taskWrap.caseRecAKAM = caseMap.get(t.WhatId).AKAM_Case_ID__c;
                taskWrap.accountName = caseMap.get(t.WhatId).Account.Name;
                taskWrap.accountId = caseMap.get(t.WhatId).AccountId;
            }
            taskWrapperList.add(taskWrap);
        }
        
        return taskWrapperList;
    }
    
    @AuraEnabled(cacheable=true)
    public static Integer getOpenTaskAMGCount(String filterVal)
    {
        List<Task> taskList = new List<Task>();
        Set<Id> caseId = new Set<Id>();
        
        User currentUser = [Select Id,Availability__c,Profile.Name,Backup_User__c,Backup_User__r.Profile.Name,ManagerId
                            FROM User 
                            WHERE Id = :Userinfo.getUserId()];
        Id managerId = currentUser.ManagerId;
        
        Map<Id,User> teamIDs = new Map<Id,User>();
        
        Boolean isAvailable = currentUser.Availability__c;
        Boolean isUserManager = FALSE;
        
        teamIDs = new Map<Id,User>([SELECT ID FROM User 
                                    WHERE ManagerId = :UserInfo.getUserId() 
                                    AND IsActive = TRUE]);
        if(teamIDs.isEmpty())
        {
            teamIDs = new Map<Id,User>([SELECT ID FROM User WHERE ManagerId = :managerId AND IsActive = TRUE]);
        }
        
        String baseTaskQuery = 'SELECT Id, RecordTypeId, WhoId, WhatId, Subject, ActivityDate, Type,Type__c, Status,AKAM_Activity_ID__c,Owner.Name,OwnerId' 
            				   + ' FROM Task ' ; 
        
        String taskUserOwnerQuery = ' WHERE OwnerId = \'' + UserInfo.getUserId() + '\'';
        
        String orderByTaskQuery = ' ORDER BY CreatedDate DESC';
        String limitTaskQuery = ' LIMIT 5000';
        String filterTaskQuery = '';
        
        
        if(filterVal.equalsIgnoreCase('My Tasks Due Today'))
            baseTaskQuery+= taskUserOwnerQuery + ' AND ActivityDate = TODAY AND Status != \'Completed\' AND Status != \'Not Applicable\' ';
        else
            if(filterVal.equalsIgnoreCase('My Open Tasks'))
            baseTaskQuery+= taskUserOwnerQuery + ' AND Status IN (\'Not Started\', \'In Progress\', \'Postponed - Agreed with Customer/IAT\') ';
        else
            if(filterVal.equalsIgnoreCase('My Overdue Tasks'))
            baseTaskQuery+= taskUserOwnerQuery + ' AND ActivityDate < TODAY AND (Status != \'Completed\' AND Status != \'Not Applicable\') ';
        else
            if(filterVal.equalsIgnoreCase('My Team\'s Open Tasks') && !teamIDs.isEmpty())
        {
            Set<Id> idKeySet = teamIDs.keySet();
            baseTaskQuery+= ' WHERE OwnerId IN :idKeySet ' + ' AND Status IN (\'Not Started\', \'In Progress\', \'Postponed - Agreed with Customer/IAT\') ';
        }
        
        baseTaskQuery+= orderByTaskQuery + limitTaskQuery;
        //baseTaskQuery+= orderByTaskQuery;
        
        taskList = Database.query(baseTaskQuery);
        
        return taskList.size();
    }
    
    @AuraEnabled
    public static Map<Id,Boolean> akachatTranscript(List<Id> caseIdList)
    {    
        Map<Id,LiveChatTranscript> lctMap = new Map<Id,LiveChatTranscript>();
        Map<Id,Boolean> caseIfLCTMap = new Map<Id,Boolean>();
        
        lctMap = new Map<Id,LiveChatTranscript>([SELECT Id,CaseId from LiveChatTranscript WHERE caseid IN :caseIdList]);
        
        for(Id eachLCTId : lctMap.keySet())
        {
            caseIfLCTMap.put(lctMap.get(eachLCTId).CaseId,true);
        }
        
        return caseIfLCTMap;        
    }
    
    @AuraEnabled
    public static String akachatTranscriptBody(Id caseId)
    {    
        livechattranscript lct = [SELECT Id,CaseId,Body from livechattranscript where caseid = :caseId];
        return lct.Body;        
    }
    @AuraEnabled
    public static void setDefaultListViewInCache(String listViewName, String value)
    {    
        try{
            if(listViewName == 'filterSelect')
                Cache.Session.put('local.AMGHomeScreen.myCase', value);
            else if(listViewName == 'queueFilter')
                Cache.Session.put('local.AMGHomeScreen.myQueue', value);
            else if(listViewName == 'taskFilter')
                Cache.Session.put('local.AMGHomeScreen.myTask', value); 
        } Catch (exception e){
    
}        
        
    }
    @AuraEnabled
    public static String getDefaultListViewInCache(String listViewName)
    {    
        String val = '';
        try{
            if(listViewName == 'filterSelect' && Cache.Session.contains('myCase')){
                val = (String)Cache.Session.get('myCase');
            } else if(listViewName == 'queueFilter' && Cache.Session.contains('myQueue')){
                val = (String)Cache.Session.get('myQueue');
            } else if(listViewName == 'taskFilter' && Cache.Session.contains('myTask')){
                val = (String)Cache.Session.get('myTask');
            }
        } Catch (exception e){
            val = '';
        }
    
        return val;   
    }
        
    @AuraEnabled
    public static string reopenClosedCase(String caseId){ 
        return SC_AMG_Lightning.reopenClosedCase(caseId);
    }  
}