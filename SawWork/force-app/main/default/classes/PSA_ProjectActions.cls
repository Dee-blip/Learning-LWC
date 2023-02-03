/***
PSA_ProjectActions
@author Liz Ichihashi
@Description : This Class is called on before insert and update
It keeps the project manager and owner fields in sync.

This class supports PSA customization requirment 4.1.9 - Trigger to keep PM and Project owner consistent
@History
--Developer           --Date            --Change
Liz Ichihashi         01/04/2013        Created the class.
janantha              11/25/2014        Modified the class for CR 2808300
Vandhana              12/01/2015        Modified class for CR 3053831
Vandhana              01/04/2015        Modified class for CR 3123441
Sharath Prasanna      21 NOV 2016:      Modified for CR 3410681: Added a function to create assignment for case owner: When the case owner changes from PS queue to a user.
Sharath Prasanna      13 DEC 2016:      Modified for CR 3410681: Added a function to change the timecard approver on project manager change
Sharath Prasanna      4th August 2017   For FFPSA-238: Soasta Migration: if an attachment is created against test,
hasAttachment field has to be checked. On delete, check if the report status is complete
If so, then dont allow delete.
kusharma              21st Aug 2017     FFPSA-280 : Soasta Deployment Obj migration.
Sharath Prasanna      25th Oct 2017     FFPSA-335 : Dont send mail to POC/Trials deployment records for missing contract Contract_Detail_Id__c
Sharath Prasanna      19th Feb 2018     FFPSA - 142 Enabling Delegated Approval of timecards
Sujay                 27th March 2018   FFPSA-481, 480, 479 Delegated Approval Enhancements
Suhas                 21/05/2018        FFPSA-490 Alerting to project owner when BED extended
Sharath               21 Aug 2018       FFPSA-647 FF lightning migration. Changed Test object code
Sandeep               12th Nov 2018     FFPSA-616 Update to email template to alert Project Managers and Account Managers of BED extension
Sandeep               17 Jan 2018       FFPSA-772 Mandate the entry for 'Basic Implementation Complete' and 'Go-Live Date' in Project Products section
Sujay                 12 May 2020       FFPSA-1372 : Make CLI attachment mandatory for valid closed projects.

*/
public class PSA_ProjectActions
{
    
    map<pse__proj__c,double> submittedTimeProject = new map<pse__proj__c,double>();
    map<pse__proj__c,double> savedTimeProject = new map<pse__proj__c,double>();
    public static Boolean isFirstTime = true;
    
    
    // -----------------------------------------------------------------------------------------------------
    // start of changes by Vandhana for CR 3123441
    
    /* This helper function gets the Projects that have had their 'Closed for Time Entry' checkbox unchecked. The IDs of these projects are sent to uncheckCloseTimeEntry future method for processing.
*/
    
    public static void uncheckCloseTimeEntryHelper (Map<Id,pse__Proj__c> oldMap, Map<Id,pse__Proj__c> newMap)
    {
        System.debug('!!! Entered uncheckCloseTimeEntryHelper');
        
        List<Id> newProj = new List<Id>();
        
        for(Id projectId : newMap.keySet())
        {
            if(oldMap.get(projectId).pse__Closed_for_Time_Entry__c && !newMap.get(projectId).pse__Closed_for_Time_Entry__c)
            {
                newProj.add(projectId);
            }
        }
        
        uncheckCloseTimeEntry(newProj);
    }
    
    /* This function unchecks the 'Closed for Time Entry' checkbox for all Assignments and Milestones associated to Projects got from the uncheckCloseTimeEntryHelper method.
*/
    
    //20.6 - this method is to make sure there is a valid CLI linked just before users close the Project
    public static void checkForCLIPresense(Map<Id,pse__Proj__c> oldMap, Map<Id,pse__Proj__c> newMap)
    {
        Set<Id> projIds = new Set<Id>();
        Set<Id> invalidProjIds = new Set<Id>();
        Id intProjRectypeId = Schema.SObjectType.pse__Proj__c.getRecordTypeInfosByName().get('Internal Project').getRecordTypeId();
        
        for(Id projId : newMap.keySet())
        {
            if( !newMap.get(projId).RecordTypeId.equals(intProjRectypeId) &&
               newMap.get(projId).pse__Stage__c.equals('Closed') && newMap.get(projId).Close_Code__c != NULL && 
               ( ((oldMap.get(projId).Close_Code__c == NULL || !oldMap.get(projId).Close_Code__c.equals('Complete')) && newMap.get(projId).Close_Code__c.equals('Complete')) 
                || 
                ( (oldMap.get(projId).Close_Code__c == NULL || !oldMap.get(projId).Close_Code__c.equals('Non Responsive Customer') ) && newMap.get(projId).Close_Code__c.equals('Non Responsive Customer')) ) )
            {
                projIds.add(projId);
            }
        }
        
        if(!projIds.isEmpty())
        {
            for(pse__proj__c eProj : [SELECT 
                                        Id, pse__Stage__c, Close_Code__c,  
                                        (SELECT Id, Contract_Detail__c, Project__c FROM Project_Contract_Line_Items__r)
                                      FROM 
                                        pse__Proj__c
                                      WHERE 
                                        Id IN :projIds])
            {
                Boolean linePresent = false;
                for(Project_Contract_Line_Item__c ePCLI : eProj.Project_Contract_Line_Items__r)
                {
                    linePresent = true; 
                    if(ePCLI.Contract_Detail__c == NULL)
                    {
                        invalidProjIds.add(ePcli.Project__c);   
                    }
                }
                if(!linePresent)
                {
                    invalidProjIds.add(eProj.Id);                       
                }
            }
        }
        
        for(Id projId : newMap.keySet()){
            if( !newMap.get(projId).RecordTypeId.equals(intProjRectypeId) && newMap.get(projId).pse__Stage__c.equals('Closed') && newMap.get(projId).Close_Code__c != NULL &&
               (newMap.get(projId).Close_Code__c.equals('Complete') || newMap.get(projId).Close_Code__c.equals('Non Responsive Customer')) 
               && invalidProjIds.contains(projId) )
            {
                newMap.get(projId).addError('Please attach a contract line item before closing the project');
            }
        }
    }
    
    public static void uncheckCloseTimeEntry(List<Id> newProj)
    {
        System.debug('!!! Entered uncheckCloseTimeEntry');
        
        List<pse__Assignment__c> listAssignments = [Select Id,Name,pse__Closed_for_Time_Entry__c
                                                    from pse__Assignment__c
                                                    where pse__Project__c in :newProj];
        
        List<pse__Assignment__c> newListAs = new List<pse__Assignment__c>();
        List<pse__Milestone__c> newListMile = new List<pse__Milestone__c>();
        
        List<pse__Milestone__c> listMilestones = [Select Id,Name,pse__Closed_for_Time_Entry__c
                                                  from pse__Milestone__c
                                                  where pse__Project__c in :newProj];
        
        for(pse__Assignment__c assignment : listAssignments)
        {
            assignment.pse__Closed_for_Time_Entry__c = false;
            newListAs.add(assignment);
        }
        
        for(pse__Milestone__c milestone : listMilestones)
        {
            milestone.pse__Closed_for_Time_Entry__c = false;
            newListMile.add(milestone);
        }
        Database.update(newListAs,false);
        Database.update(newListMile,false);
    }
    // end of changes by Vandhana for CR 3123441
    // -----------------------------------------------------------------------------------------------------
    
    
    /*Start of change by janantha for CR 2808300*/
    public static void checkForEndDateChange(Map<Id,pse__Proj__c> oldMap, Map<Id,pse__Proj__c> newMap)
    {
        Set<ID> ids = newMap.keySet();
        
        List<pse__Proj__c> updatedProjects = [SELECT Id, Update_Milestone_Target_Date__c, pse__End_Date__c, (select ID, pse__Project__c, pse__Target_Date__c from pse__Milestones__r)
                                              FROM pse__Proj__c
                                              WHERE Id in :ids];
        
        List<pse__Milestone__c> milestonesToUpdate = new List<pse__Milestone__c>();
        
        for(pse__Proj__c proj : updatedProjects)
        {
            if(proj.Update_Milestone_Target_Date__c)
            {
                Date oldvalue = oldMap.get(proj.Id).pse__End_Date__c;
                Date newValue = proj.pse__End_Date__c;
                
                if(oldvalue != newValue )
                {
                    for(pse__Milestone__c mile: proj.pse__Milestones__r)
                    {
                        mile.pse__Target_Date__c = proj.pse__End_Date__c;
                        milestonesToUpdate.add(mile);
                    }
                    
                }
            }
        }
        
        if( !milestonesToUpdate.isEmpty() )
        {
            update milestonesToUpdate;
        }
    }
    /*End of change by janantha for CR 2808300*/
    
    /*Start of changes by janantha for CR 2576145*/
    
    /*  public static void checkForProjectManagerChange(Map<Id,pse__Proj__c> oldMap, Map<Id,pse__Proj__c> newMap)
{
Map<Id, String> UserIDName = new Map<Id, String>();
Map<Id, pse__Proj__c> projNewMap = new Map<Id, pse__Proj__c>(newMap);
Map<Id, pse__Proj__c> projOldMap = new Map<Id, pse__Proj__c>(oldMap);
List<pse__Proj__c> newProjects = [Select pse__Project_Manager__c,pse__Project_Manager__r.Name, Id, Name, (select Id,Name,pse__Project__c,pse__Resource__c,pse__Resource__r.Name from pse__Timecards__r where pse__Status__c = 'Submitted')
from pse__Proj__c
where Id in :projNewMap.keySet()];
Messaging.SingleEmailMessage emailMessage;
Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
String emailBody = '';
Set<Id> userIds = new Set<Id>();
Set<Id> timecardIds = new Set<Id>();

Integer countPendingTimecards = [select Count() from pse__Timecard_Header__c where pse__Status__c = 'Submitted'
and pse__Project__c in :projNewMap.keySet()];

if(countPendingTimecards>0)
{
for(pse__proj__c proj:oldMap.values())
{
userIds.add(proj.pse__Project_Manager__c);
}

List<Contact> users2 = new List<Contact>();
///*Query for getting the old project manager name. This cannot be got through relationship since it returns null in trigger
users2 = [select Id,Name from Contact where Id in :userIds];

for(Contact user1:users2)
{
UserIDName.put(user1.Id,user1.Name);
}

mailsToBeSent = new List<Messaging.SingleEmailMessage>();
for(pse__Proj__c proj:newProjects)
{
if(proj.pse__Project_Manager__c != projOldMap.get(proj.Id).pse__Project_Manager__c)
{
///*Send an email to the new manager.
emailBody = '';
emailMessage = new Messaging.SingleEmailMessage();
emailBody = '<html><body>'+'Hi '+proj.pse__Project_Manager__r.Name+',<br/><br/>';
emailBody += 'You have been assigned as the Project Manager of Project '+  proj.Name +'|'+proj.id +' Project.<br/><br/>';
emailBody += 'Project Link :- '+URL.getSalesforceBaseUrl().toExternalForm() +
'/' + proj.id+'<br/><br/>';
emailBody += 'Note that there are pending Timecards for which actions need to be taken by the Previous Project Manager ' + UserIDName.get(projOldMap.get(proj.Id).pse__Project_Manager__c)+'. Please make sure that you get in touch with the previous Project Manager so that necessary actions are taken against pending Timecards.<br/><br/>';
emailBody += 'Thanks,<br/>Notification Team';
emailMessage.setSubject('Project '+proj.Name+' Pending Timecards');
emailMessage.setHtmlBody(emailBody);
emailMessage.setTargetObjectId(proj.pse__Project_Manager__c);
emailMessage.setSaveAsActivity(false);
mailsToBeSent.add(emailMessage);

//              /*Send an email to the old manager.
emailBody = '';
emailMessage = new Messaging.SingleEmailMessage();
emailBody = '<html><body>'+'Hi '+UserIDName.get(projOldMap.get(proj.Id).pse__Project_Manager__c)+',<br/><br/>';
emailBody += 'You are no longer assigned to the Project '+  proj.Name +'|'+proj.id+'<br/>';
emailBody += 'However, there are pending Timecards that you need to attend to immediately.<br/>';
emailBody += 'Please take necessary actions on the Timecards that have been submitted to you previously by the resources assigned to this Project, as the New Project Manager will not be able to access them & will not be able to take necessary action.<br/><br/>';
//            /*Link to timecards
for(pse__Timecard_Header__c tcHeader:proj.pse__Timecards__r)
{
emailBody += URL.getSalesforceBaseUrl().toExternalForm() +
'/' +  tcHeader.Id+'<br/>';
}

emailBody += '<br/>Project Link :- '+URL.getSalesforceBaseUrl().toExternalForm() +
'/' + proj.id+'<br/><br/>';
emailBody += 'Thanks,<br/>Notification Team';
emailMessage.setSubject('Project '+proj.Name +' Pending Timecards');
emailMessage.setHtmlBody(emailBody);
emailMessage.setTargetObjectId(projOldMap.get(proj.Id).pse__Project_Manager__c);
emailMessage.setSaveAsActivity(false);
mailsToBeSent.add(emailMessage);

//              /*Send an email to the resource

for(pse__Timecard_Header__c tcHeader:proj.pse__Timecards__r)
{
emailBody = '';
emailMessage = new Messaging.SingleEmailMessage();
emailBody = '<html><body>'+'Hi '+tcHeader.pse__Resource__r.Name+',<br/><br/>';
emailBody += 'You have pending Timecards for Project '+proj.Name +'.<br/>';
emailBody += 'Note that the Project Manager for Project '+ proj.Name +'|'+proj.id
+ ' has been changed to '+proj.pse__Project_Manager__r.Name+'. However, you would require your Previous Project Manager '+UserIDName.get(projOldMap.get(proj.Id).pse__Project_Manager__c)+' to take necessary action on your Pending Timecards.<br/><br/>';
emailBody += 'Timecard:<br/>'+URL.getSalesforceBaseUrl().toExternalForm() + '/' +  tcHeader.Id+'<br/><br/>';
emailBody += 'Project:<br/>'+URL.getSalesforceBaseUrl().toExternalForm() + '/' +  proj.Id+'<br/><br/>';
emailBody += 'Thanks,<br/>Notification Team';
emailMessage.setSubject('Project '+proj.Name +' Pending Timecards');
emailMessage.setHtmlBody(emailBody);
emailMessage.setTargetObjectId(tcHeader.pse__Resource__c);
emailMessage.setSaveAsActivity(false);
mailsToBeSent.add(emailMessage);
}
}
}
if(mailsToBeSent != null && mailsToBeSent.size()>0)
Messaging.sendEmail(mailsToBeSent);
}
}
*/
    
    /*End of changes by janantha for CR 2576145*/
    
    
    //called on before insert and update of project.  Project Owner and project Project Manager must be kept in sync */
    public static void checkForProjectManagerOwnerChange(List<pse__Proj__c> oldList, List<pse__Proj__c> newList) {
        
        Map<Id, pse__Proj__c> oldMap;
        if (oldList != null && oldList.size() > 0) {
            oldMap = new Map<Id, pse__Proj__c>(oldList);
        }
        List<pse__Proj__c> projectsWithNewPM = new List<pse__Proj__c>();
        Set<String> pmIds = new Set<String>();
        List<pse__Proj__c> projectsWithNewOwner = new List<pse__Proj__c>();
        Set<String> ownerIds = new Set<String>();
        
        for (pse__Proj__c projRow : newList) {
            if (oldMap == null && projRow.pse__Project_Manager__c != null) {
                //if it is an insert and the project manager has been set - override the Owner field.
                projectsWithNewPM.add(projRow);
                pmIds.add(projRow.pse__Project_Manager__c);
            } else if (oldMap != null && projRow.pse__Project_Manager__c != oldMap.get(projRow.Id).pse__Project_manager__c) {
                //if it is an update and project manager is being changed
                projectsWithNewPM.add(projRow);
                pmIds.add(projRow.pse__Project_Manager__c);
            } else if (oldMap != null && projRow.Ownerid != oldMap.get(projRow.Id).Ownerid) {
                //if it is an update and owner is being changed
                projectsWithNewOwner.add(projRow);
                ownerIds.add(projRow.Ownerid);
            }
        }
        if (projectsWithNewPM.size() > 0) {
            Map<Id, Contact> contactMap = new Map<Id, Contact>([select Id, Name, pse__Salesforce_User__c from Contact where id in :pmIds]);
            for (pse__Proj__c projRow : projectsWithNewPM) {
                if (contactMap.containsKey(projRow.pse__Project_Manager__c)) {
                    if (contactMap.get(projRow.pse__Project_Manager__c).pse__Salesforce_User__c != null) {
                        projRow.OwnerId = contactMap.get(projRow.pse__Project_Manager__c).pse__Salesforce_User__c;
                    }
                }
            }
        }
        if (projectsWithNewOwner.size() > 0) {
            List<Contact> contactList = [select Id, Name, pse__Salesforce_User__c from Contact where pse__Salesforce_User__c in :ownerIds];
            Map<Id, Id> sfUserIdToContaactIdMap = new Map<Id, Id>();
            for (Contact contRow : contactList) {
                sfUserIdToContaactIdMap.put(contRow.pse__Salesforce_User__c, contRow.Id);
            }
            for (pse__Proj__c projRow : projectsWithNewOwner) {
                if (sfUserIdToContaactIdMap.containsKey(projRow.OwnerId)) {
                    projRow.pse__Project_Manager__c = sfUserIdToContaactIdMap.get(projRow.OwnerID);
                }
            }
        }
    }
    
    /* when project is being updated check to see if contract closed is yes.  If so, validate that a project contract */
    /* line item exists.  If not, do not allow the update. called on before update of project. */
    public static void checkForContractClosedWithoutProjectContractItems(List<pse__Proj__c> oldList, List<pse__Proj__c> newList) {
        Map<Id, pse__Proj__c> oldMap = new Map<Id, pse__Proj__c>(oldList);
        Set<Id> projIds = new Set<Id>();
        for (pse__Proj__c projRow : newList) {
            if (projRow.Contract_Closed__c == 'Yes' &&
                projRow.Contract_Closed__c != oldMap.get(projRow.Id).Contract_Closed__c) {
                    projIds.add(projRow.Id);
                }
        }
        
        if (projIds.size() > 0) {
            Map<Id, pse__Proj__c> projMap = new Map<Id, pse__Proj__c> ([select Id,
                                                                        (select Id from Project_Contract_Line_Items__r)
                                                                        from pse__Proj__c where id in :projIds]);
            for (pse__Proj__c projRow : newList) {
                if (projMap.get(projRow.Id).Project_Contract_Line_Items__r == null ||
                    projMap.get(projRow.Id).Project_Contract_Line_Items__r.size() == 0) {
                        projRow.addError('Project Contract Line Item is required when Contract Closed is "Yes".');
                    }
            }
        }
        
    }
    
    public static void checkForAssignmentUpdates(List<pse__Proj__c> oldList, List<pse__Proj__c> newList)
    {
        List<pse__proj__c>UpdateScheduleForProjects = new list<pse__proj__c>();
        List<Id>UpdateScheduleForProjectsId = new list<Id>();
        Map<Id,pse__Proj__c>oldMap = new Map<Id,pse__Proj__c>(oldList);
        Map<pse__Proj__c,list<pse__Assignment__c>> mapProjAssignment = new Map<pse__Proj__c,list<pse__Assignment__c>>();
        Map<pse__Assignment__c,list<pse__Schedule__c>> mapAssignmentSchedule = new Map<pse__Assignment__c,list<pse__Schedule__c>>();
        for(pse__Proj__c p : newList)
        {
            if(p.pse__end_date__c!= oldMap.get(p.Id).pse__end_date__c)
            {
                UpdateScheduleForProjects.add(p);
                UpdateScheduleForProjectsId.add(p.Id);
            }
        }
        List<pse__Assignment__c>assgn = [Select Id,pse__Schedule__c,pse__Project__c from pse__Assignment__c where pse__Project__c in :UpdateScheduleForProjects];
        //Prepare a map of Proj and related assignments
        for (pse__proj__c p:UpdateScheduleForProjects)
        {
            for(pse__Assignment__c assgntemp :assgn)
            {
                if(p.Id == assgntemp.pse__Project__c)
                {
                    if(mapProjAssignment.containsKey(p))
                    {
                        mapProjAssignment.get(p).add(assgntemp);
                    }
                    else
                    {
                        mapProjAssignment.put(p, new list<pse__Assignment__c>());
                        mapProjAssignment.get(p).add(assgntemp);
                    }
                }
            }
        }
        
        List<pse__Schedule__c> sched2UpdateList = new List<pse__Schedule__c>();
        List<Id> sched2Update = new List<Id>();
        
        for(pse__Assignment__c assgnIterator:assgn)
        {
            sched2Update.add(assgnIterator.pse__Schedule__c);
        }
        sched2UpdateList = [select Id, pse__end_date__c from pse__Schedule__c where Id in :sched2Update];
        //Prepare a map of Assignment and related schedules
        For(pse__Assignment__c assgnTemp2 : assgn)
        {
            for(pse__Schedule__c schedTemp : sched2UpdateList)
            {
                if(assgnTemp2.pse__Schedule__c == schedTemp.Id)
                {
                    if(mapAssignmentSchedule.containsKey(assgnTemp2))
                    {
                        mapAssignmentSchedule.get(assgnTemp2).add(schedTemp);
                    }
                    else
                    {
                        mapAssignmentSchedule.put(assgnTemp2, new list<pse__schedule__c>());
                        mapAssignmentSchedule.get(assgnTemp2).add(schedTemp);
                    }
                }
            }
        }
        List<pse__schedule__c> schedulesToUpdateList = new list<pse__schedule__c>();
        For(pse__proj__c pr1 : mapProjAssignment.keySet())
        {
            For(pse__Assignment__c as1: mapAssignmentSchedule.keySet())
            {
                For(pse__schedule__c sched:mapAssignmentSchedule.get(as1))
                {
                    if(sched.pse__end_date__c != pr1.pse__end_date__c)
                    {
                        sched.pse__end_date__c = pr1.pse__end_date__c;
                        schedulesToUpdateList.add(sched);
                    }
                }
            }
        }
        try
        {
            Database.Update(schedulesToUpdateList);
        }
        catch(Exception e)
        {
            //Do nothing for now
        }
    }
    
    public static void autoCreateAssignments(List<pse__Proj__c> newList)
    {
        list<Id> lProjectIds = new list<Id>();
        for(pse__proj__c eachNewProj : newList)
        {
            lProjectIds.add(eachNewProj.Id);
        }
        list<pse__proj__c> lprojects = [select Id,pse__Project_Type__c ,pse__Is_Template__c ,pse__project_Manager__c,pse__Start_Date__c,pse__End_Date__c, Cloned_Project__c ,(select Id,pse__Resource__c from pse__Assignments__r) from pse__proj__c where id in :lProjectIds];
        list<pse__proj__c> lProjsToAddAssign = new list<pse__proj__c>();
        Boolean assignExists;
        for(pse__proj__c eachProject: lprojects)
        {
            assignExists = False;
            for(pse__Assignment__c eachAssignment:eachProject.pse__Assignments__r)
            {
                if(eachAssignment.pse__Resource__c == eachProject.pse__Project_Manager__c || eachProject.Cloned_Project__c == TRUE || eachProject.pse__Is_Template__c == TRUE)
                {
                    assignExists = TRUE;
                    break;
                }
                else
                {
                    continue;
                }
            }
            if(assignExists == False)
            {
                lProjsToAddAssign.add(eachProject);
            }
        }
        if(lProjsToAddAssign != NULL)
        {
            list<pse__Schedule__c> schedule2Insert = new list<pse__Schedule__c>();
            for(pse__proj__c pToAddAssign:lProjsToAddAssign)
            {
                pse__Schedule__c sched2Insert = new pse__Schedule__c();
                sched2Insert.pse__Start_Date__c = pToAddAssign.pse__Start_Date__c;
                sched2Insert.pse__End_Date__c = pToAddAssign.pse__End_Date__c;
                sched2Insert.pse__Scheduled_Hours__c = 1;
                schedule2Insert.add(sched2Insert);
                
            }
            Insert schedule2Insert;
            integer scheduleCount = 0;
            list<pse__Assignment__c> lAssign2Insert = new list<pse__Assignment__c>();
            for(pse__proj__c pToAddAssign:lProjsToAddAssign)
            {
                pse__Assignment__c newAssignment = new pse__Assignment__c();
                newAssignment.pse__Project__c = pToAddAssign.Id;
                newAssignment.pse__Resource__c = pToAddAssign.pse__Project_Manager__c;
                newAssignment.pse__Schedule__c = schedule2Insert[scheduleCount].Id;
                if(pToAddAssign.pse__Project_Type__c != 'Internal')
                {
                    newAssignment.pse__Bill_Rate__c = 250;
                }
                else
                {
                    newAssignment.pse__Bill_Rate__c = 0;
                }
                lAssign2Insert.add(newAssignment);
                scheduleCount++;
                
            }
            insert lAssign2Insert;
        }
    }
    
    public static void checkForValidClosedForTimeEntry(List<pse__Proj__c> oldList, List<pse__Proj__c> newList)
    {
        Map<Id, pse__Proj__c> oldMap = new Map<Id, pse__Proj__c>(oldList);
        list<pse__Proj__c> proj2check = new list<pse__Proj__c>();
        for(pse__proj__c p1: newList)
        {
            if(oldMap.get(p1.Id).pse__Closed_for_Time_Entry__c != TRUE && p1.pse__Closed_for_Time_Entry__c == TRUE && !p1.Validation_Override__c)
            {
                proj2check.add(p1);
            }
        }
        if(proj2check.size()>0)
            checkforSavedSubmittedTimecards(proj2check);
        
    }
    public static void checkforSavedSubmittedTimecards(list<pse__Proj__c> projList)
    {
        double numSubmittedHours,numSavedHours;
        //optimising the code as per JIRA:FFPSA-1941
        //inner query to avoid extra logic to create the map of project and timecardList
        Map<Id, pse__Proj__c> projectsMap = new Map<Id, pse__Proj__c>([select id, (select id, pse__Total_Hours__c,pse__Status__c, pse__Project__c from PSE__Timecards__r where pse__Status__c in ('Saved','Submitted','Approver Level 1','Rejected') LIMIT 50000) from pse__Proj__c where id IN: projList]);
        for(pse__Proj__c proj : projList){
            numSubmittedHours = 0;
            numSavedHours = 0;
            if( projectsMap.containsKey(proj.Id) ) {
                for(pse__timecard_header__c timecard : projectsMap.get(proj.Id).PSE__Timecards__r){
                    if(timecard.pse__Status__c == 'Submitted' || timecard.pse__Status__c == 'Approver Level 1'){
                        numSubmittedHours+= timecard.pse__Total_Hours__c;
                    }
                    else if(timecard.pse__Status__c == 'Saved' || timecard.pse__Status__c =='Rejected'){
                        numSavedHours+= timecard.pse__Total_Hours__c;
                    }
                }
            }
            if(numSubmittedHours==0 && numSavedHours!= 0 && proj.PSA_Ignore_Saved_Timecards__c == FALSE )
                proj.addError('Note that this Project has Saved/Rejected Hours = ' + numSavedHours +'. If you check "Closed for Time Entry" flag resources will not be able to Submit these hours. Check the "Ignore Saved Timecards" flag to lose saved hours and continue.');
            else if(numSubmittedHours!=0)
                proj.addError('Please take action on the Pending Timecards before closing it for Time Entry. This Project has Submitted Hours = '+ numSubmittedHours + ' Hours');
        }
  
    }
    
    //Start of changes by Samir for Release 4.11
    public static void CheckUncheckIgnoreSavedTimecards(List<pse__Proj__c> oldList, List<pse__Proj__c> newList)
    {
        Map<Id, pse__Proj__c> oldMap = new Map<Id, pse__Proj__c>(oldList);
        list<Id> proj2checkIds = new list<Id>();
        list<pse__Milestone__c> Milestone2Update = new list<pse__Milestone__c>();
        list<pse__Assignment__c> Assignment2Update = new list<pse__Assignment__c>();
        for(pse__proj__c p1: newList)
        {
            if((oldMap.get(p1.Id).PSA_Ignore_Saved_Timecards__c != TRUE && p1.PSA_Ignore_Saved_Timecards__c  == TRUE) || (oldMap.get(p1.Id).PSA_Ignore_Saved_Timecards__c == TRUE && p1.PSA_Ignore_Saved_Timecards__c  != TRUE))
            {
                proj2checkIds.add(p1.Id);
            }
        }
        list<pse__Proj__c> Proj2Update = [Select Id,PSA_Ignore_Saved_Timecards__c,(Select PSA_Ignore_Saved_Timecards__c from pse__Milestones__r ),(Select PSA_Ignore_Saved_Timecards__c from pse__Assignments__r ) from pse__Proj__c where Id in :proj2checkIds];
        
        for(pse__Proj__c p1:Proj2Update)
        {
            //System.assertEquals(!p1.PSA_Ignore_Saved_Timecards__c, NULL);
            for(pse__Milestone__c m1: p1.pse__Milestones__r)
            {
                m1.PSA_Ignore_Saved_Timecards__c = !(p1.PSA_Ignore_Saved_Timecards__c);
                Milestone2Update.add(m1);
            }
            for(pse__Assignment__c a1:p1.pse__Assignments__r)
            {
                a1.PSA_Ignore_Saved_Timecards__c = !(p1.PSA_Ignore_Saved_Timecards__c);
                Assignment2Update.add(a1);
            }
        }
        
        
        Database.Update(Milestone2Update,False);
        
        Database.Update(Assignment2Update,False);
        
    }
    //End of changes by Samir for Release 4.11
    
    /*Start of Changes by Samir for CR:3120521
* Added Release: 4.12
* Update Approver field on Saved/Rejected Timecards if project manager changes
*/
    /*public static void CheckForSavedTimecardsWhenPMChanges(List<pse__Proj__c> oldList, List<pse__Proj__c> newList)
{
Map<Id, pse__Proj__c> oldMap;

//Stores Trigger.new IDs
List<Id> UpdatedProjIds = new list<Id>();

list<pse__Timecard_Header__c> TC2Update = new list<pse__Timecard_Header__c>();

Map<Id,list<pse__Timecard_Header__c>> ProjTCMap = new Map<Id,list<pse__Timecard_Header__c>>();

for (pse__Proj__c projRow : newList)
{
UpdatedProjIds.add(projRow.Id);
}

list<pse__Timecard_Header__c> TC2check = [select Id,pse__Project__c,pse__Approver__c from pse__Timecard_Header__c where pse__Project__c in :UpdatedProjIds and pse__status__c in ('Saved','Rejected')];

if(TC2check!=NULL && TC2check.size()!=0)
{
if (oldList != null && oldList.size() > 0)
{
oldMap = new Map<Id, pse__Proj__c>(oldList);
}
for(pse__Timecard_Header__c tch1:TC2check)
{
if(ProjTCMap!=NULL && ProjTCMap.get(tch1.pse__Project__c)!=NULL)
{
ProjTCMap.get(tch1.pse__Project__c).add(tch1);
}
else
{
ProjTCMap.put(tch1.pse__Project__c,new list<pse__Timecard_Header__c>());
ProjTCMap.get(tch1.pse__Project__c).add(tch1);
}
}
for (pse__Proj__c projRow : newList)
{
if (oldMap != null && projRow.Ownerid != oldMap.get(projRow.Id).Ownerid)
{
for(pse__Timecard_Header__c tch2:ProjTCMap.get(projRow.Id))
{
tch2.pse__Approver__c =  projRow.Ownerid;
TC2Update.add(tch2);
}
}
}
}
//system.assertEquals(TC2Update,NULL);
Database.Update(TC2Update);
}*/
    
    /*End of Changes by Samir for CR:3120521
* Added Release: 4.12
* Update Approver field on Saved/Rejected Timecards if project manager changes
*/
    
    
    // Start of changes for CR 3053831 by Vandhana Krishnamurthy
    /* Email notifications to be sent out to Technical Sales - Primary on the assocatied Opportunity in Project when there is a change in
*/
    
    public static void sendEmailTSP(Map<Id,pse__Proj__c> oldMap, Map<Id,pse__Proj__c> newMap,boolean isUpdate)
    {
        List<pse__Proj__c> newProjects = [SELECT Id, Basic_Implementation_Complete__c, Implementation_Complete__c, Name,pse__Account__c,pse__Account__r.Name, pse__End_Date__c, pse__Opportunity__c
                                          FROM pse__Proj__c
                                          WHERE Id in :newMap.keySet()];
        
        List<Id> oppIds = new List<Id>();
        for(pse__Proj__c proj : newProjects)
        {
            oppIds.add(proj.pse__Opportunity__c);
        }
        
        /*Map of Opportunity Id and Opportunity. Inner query has a list of Opportunity Team Members for this Opportunity. */
        
        Map<Id,Opportunity> oppIdTeamMembers = new Map<Id,Opportunity>();
        oppIdTeamMembers = new Map<Id,Opportunity>(new List<Opportunity>([select Id, (select User.Email from OpportunityTeamMembers where TeamMemberRole = 'Technical Sales - Primary')
                                                                          from Opportunity where Id in :oppIds]));
        
        
        //String fromAddress = PSA_Settings__c.getInstance('FromEmailAdress').Value__c;
        
        String fromAddress = [Select Value_Long__c from PSA_Common_Setting__mdt where Name__c = 'FromEmailAdress'].Value_Long__c ;
        
        System.debug('From Address: '+fromAddress);
        String orgWideEmailId = [select Id from OrgWideEmailAddress where Address = :fromAddress limit 1].Id;
        System.debug(orgWideEmailId);
        List<Messaging.SingleEmailMessage> mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        Messaging.SingleEmailMessage email;
        List<String> sendTo = new List<String>();
        
        
        for(pse__Proj__c project : newProjects)
        {
            System.debug('!!! Entered projects for loop, project ' + project);
            //email = new Messaging.SingleEmailMessage();
            sendTo = new List<String>();
            
            Opportunity opp = oppIdTeamMembers.get(project.pse__Opportunity__c);
            System.debug('!!! Opportunity - '+opp);
            
            if(opp != NULL && opp.OpportunityTeamMembers != null && opp.OpportunityTeamMembers.size() > 0)
            {
                for(OpportunityTeamMember oppTeam:opp.OpportunityTeamMembers)
                {
                    sendTo.add(oppTeam.User.Email);
                    System.debug('!!! User email - '+ oppTeam.User.Email);
                }
                
                // Generate email content
                
                if(sendTo != NULL && sendTo.size() > 0)
                {
                    System.debug('!!! Entered sendTo if');
                    if (isUpdate == false || (oldMap.get(project.Id).pse__Opportunity__c != project.pse__Opportunity__c))
                    {
                        System.debug('!!! Entered isInsert if for new project');
                        email = new Messaging.SingleEmailMessage();
                        email.setToAddresses(sendTo);
                        email.setOrgWideEmailAddressId(orgWideEmailId);
                        email.setSubject('NOTIFICATION: A digital property for '+ project.pse__Account__r.Name +' has a new project');
                        email.setHTMLBody('<html><body>Hi TSP,<br/><br/>A new project has been created for the ' + project.pse__Account__r.Name + ' account : ' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + project.pse__Account__c +  ' - Project ' + project.Name +' : '+ URL.getSalesforceBaseUrl().toExternalForm() + '/' + project.Id + '.</body></html>');
                        mailsToBeSent.add(email);
                        System.debug('!!! Final email isInsert - '+ email);
                    }
                    else if (isUpdate ==  true)
                    {
                        System.debug('!!! Entered isInsert if for updated projects');
                        Date oldDate = oldMap.get(project.Id).Basic_Implementation_Complete__c;
                        Date newDate = project.Basic_Implementation_Complete__c;
                        if(oldDate != newDate)
                        {
                            System.debug('!!! Entered 1st date - basic implemention');
                            email = new Messaging.SingleEmailMessage();
                            email.setToAddresses(sendTo);
                            email.setOrgWideEmailAddressId(orgWideEmailId);
                            email.setSubject('NOTIFICATION: A digital property for '+ project.pse__Account__r.Name +' has reached basic');
                            email.setHTMLBody('<html><body>Hi TSP,<br/><br/>Project '+project.Name+' : '+ URL.getSalesforceBaseUrl().toExternalForm() + '/' + project.Id + ' for '+ project.pse__Account__r.Name + ' : ' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + project.pse__Account__c + ' account has reached basic integration on ' + newDate.format() + '.</body></html>');
                            mailsToBeSent.add(email);
                            System.debug('!!! Final email isUpdate basic implemention - '+email);
                        }
                        oldDate = oldMap.get(project.Id).Implementation_Complete__c;
                        newDate = project.Implementation_Complete__c;
                        if(oldDate != newDate )
                        {
                            System.debug('!!! Entered 2nd date - implemention complete');
                            email = new Messaging.SingleEmailMessage();
                            email.setToAddresses(sendTo);
                            email.setOrgWideEmailAddressId(orgWideEmailId);
                            email.setSubject('NOTIFICATION: A digital property for '+ project.pse__Account__r.Name +' is live on Akamai');
                            email.setHTMLBody('<html><body>Hi TSP,<br/><br/>Project '+project.Name+' : '+ URL.getSalesforceBaseUrl().toExternalForm() + '/' + project.Id + ' for '+ project.pse__Account__r.Name + ' : ' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + project.pse__Account__c + ' account is now live on Akamai as on ' + newDate.format() + '.</body></html>');
                            mailsToBeSent.add(email);
                            System.debug('!!! Final email isUpdate implemention complete - '+email);
                        }
                        oldDate = oldMap.get(project.Id).pse__End_Date__c;
                        newDate = project.pse__End_Date__c;
                        if(oldDate != newDate)
                        {
                            System.debug('!!! Entered 3rd date - end date');
                            email = new Messaging.SingleEmailMessage();
                            email.setToAddresses(sendTo);
                            email.setOrgWideEmailAddressId(orgWideEmailId);
                            email.setSubject('NOTIFICATION: A digital property for '+ project.pse__Account__r.Name +' has changed completion date');
                            email.setHTMLBody('<html><body>Hi TSP,<br/><br/>Project '+project.Name+' : '+ URL.getSalesforceBaseUrl().toExternalForm() + '/' + project.Id + ' for '+ project.pse__Account__r.Name + ' : ' + URL.getSalesforceBaseUrl().toExternalForm() + '/' + project.pse__Account__c + ' account has had a change in its expected completion date.<br/><br/>Previous completion date : ' + oldDate.format() + '<br/>New completion date : ' + newDate.format() + '</body></html>');
                            mailsToBeSent.add(email);
                            System.debug('!!! Final email isUpdate end date - '+email);
                        }
                    }
                }
            }
        }
        
        if(mailsToBeSent != null && mailsToBeSent.size()>0)
        {
            Messaging.sendEmail(mailsToBeSent,false);
            //List<Messaging.SendEmailResult> results =  Messaging.sendEmail(mailsToBeSent,false);
        }
    }
    // End of changes for CR 3053831 by Vandhana Krishnamurthy
    
    //Start of changes by Sharath for CR 3410681
    
    public static void createAssignmentForCaseOWner(List<Case>updatedCaseList)
    {
        //map for case ID to case Owner
        Map<Id,Id> caseToOwner = new Map<Id,Id>();
        //map of User ID to Contact ID
        Map<Id,Id> ownerToResource = new Map<Id,Id>();
        //Map of project ID to Set of case IDs. A project can be linked to multiple cases.
        Map<Id,Set<Id>> projectToCase = new Map<Id,Set<Id>>();
        //Map of schedule Id to project End Date
        Map<Id,Date> scheduleToEndDate = new Map<Id,Date>();
        //Map of Contact Id to Set of assignments. A resource can have multiple assignments
        Map<Id,Set<pse__Assignment__c>> resourceToAssignment;
        
        pse__Schedule__c scheduleLookUp;
        
        
        List<pse__Assignment__c> assignmentsToInsert = new List<pse__Assignment__c>();
        List<pse__Schedule__c> schedulesForUpsert = new List<pse__Schedule__c>();
        pse__Schedule__c schedule;
        
        Id resourceId;
        Id caseId;
        pse__Assignment__c newAssignment;
        
        List<Database.UpsertResult> upsertResultRecords = new List<Database.UpsertResult>();
        List<Database.SaveResult> saveResultRecords = new List<Database.SaveResult>();
        
        for (Case c: updatedCaseList)
        {
            //Populate the projectToCase map using the project lookup
            if(c.pse_Project__c != null)
            {
                if(!projectToCase.containsKey(c.pse_Project__c))
                {
                    projectToCase.put(c.pse_Project__c ,new Set<Id>());
                }
                
                projectToCase.get(c.pse_Project__c).add(c.id);
            }
            //populate the caseToOwner map
            caseToOwner.put(c.id,c.ownerID);
            
        }
        
        //Get the PSA Resource contact record type
        Id PSAResourceId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('PSA Resource').getRecordTypeId();
        
        //Query for the Active PSA Contact records correponding to the Case owners and populate the ownerToResource map
        for (Contact ownerContact: [select id,pse__salesforce_user__c from Contact where pse__salesforce_user__c in :caseToOwner.values() and recordTypeid = :PSAResourceId and pse__Is_Resource__c  = true and pse__Is_Resource_Active__c = true])
        {
            ownerToResource.put(ownerContact.pse__salesforce_user__c,ownerContact.id);
        }
        
        //Query for the Project_Case_Association__c records corresponding to the updated cases. Projects are linked to cases via the lookup and the junction object Project_Case_Association__c. Populate the map projectToCase.
        for (Project_Case_Association__c projectCaseAssociations: [select Case__c,Project__c from Project_Case_Association__c where Case__c in :caseToOwner.keyset()])
        {
            
            if(! projectToCase.containsKey(projectCaseAssociations.Project__c))
            {
                projectToCase.put(projectCaseAssociations.Project__c,new Set<Id>());
            }
            projectToCase.get(projectCaseAssociations.Project__c).add(projectCaseAssociations.Case__c);
        }
        
        //Query for the non-autogen projects using the projectToCase map. Sub-query the assignment records using the contact ids from the map ownerToResource.
        for (pse__Proj__c project: [select id, pse__Closed_for_Time_Entry__c,pse__Stage__c,pse__End_Date__c,(select id, pse__Resource__c,pse__End_Date__c,pse__Closed_for_Time_Entry__c,pse__Schedule__c  from pse__Assignments__r where pse__Resource__c in :ownerToResource.values())  from pse__Proj__c where id in :projectToCase.keyset()])
        {
            //resourceToAssignment map is re-initialized for every project
            resourceToAssignment = new Map<Id,Set<pse__Assignment__c>>();
            
            //If the project is in the closed stage or if it is closed for time entry, dont consider it for assignment creation.
            if(project.pse__Closed_for_Time_Entry__c  || project.pse__Stage__c == 'Closed')
            {
                projectToCase.remove(project.id);
                continue;
            }
            // If the pse__Assignments__r list is not null and has elements, loop over and populate the resourceToAssignment map. A resource may have multiple assignments for the same project.
            if(project.pse__Assignments__r != null && project.pse__Assignments__r.size() > 0)
            {
                
                for (pse__Assignment__c assignment: project.pse__Assignments__r)
                {
                    if(!resourceToAssignment.containsKey(assignment.pse__Resource__c))
                    {
                        resourceToAssignment.put(assignment.pse__Resource__c,new Set<pse__Assignment__c>());
                    }
                    resourceToAssignment.get(assignment.pse__Resource__c).add(assignment);
                    
                }
                
            }
            //Loop over all the cases linked to the project
            for(Id projectCaseId: projectToCase.get(project.id))
            {
                //get the case id and the resource Id(contact Id of the case owner)
                caseId = projectCaseId;
                resourceId = ownerToResource.get(caseToOwner.get(caseId));
                //Check for existing assignments for the case owner against the project
                if(resourceToAssignment.containsKey(resourceId) )
                {
                    //if the existing assignments have expired and are not closed for time entry, then update the end date of the corresponding schedule to the project end date. The assignment start and end date fields are not writable
                    if(resourceToAssignment.get(resourceId) != null && resourceToAssignment.get(resourceId).size() > 0)
                    {
                        for(pse__Assignment__c assignmentUpdate: resourceToAssignment.get(resourceId))
                        {
                            if(assignmentUpdate.pse__End_Date__c < Date.today() && !assignmentUpdate.pse__Closed_for_Time_Entry__c)
                            {
                                //Add the schedule Id and the project end date to the scheduleToEndDate map
                                scheduleToEndDate.put(assignmentUpdate.pse__Schedule__c,project.pse__End_Date__c);
                            }
                            
                        }
                        //Clear the assignment set once they have been looped through. The resource id now maps to an empty set
                        resourceToAssignment.get(resourceId).clear();
                        
                    }
                    system.debug('Here for case:' + caseId);
                    //remove the case ID from the case ID set mapped by the current project. The project has an existing assignment for the current case owner
                    projectToCase.get(project.Id).remove(caseId);
                    
                }
                //If the case doesnt have an existing assignment, then the id is not removed from the Set. Then a new assignment is created
                if(projectToCase.containsKey(project.Id) && projectToCase.get(project.Id).contains(caseId))
                {
                    
                    // A schedule is required for assignment creation. set the start date to today, end date to project end date and the external id to the unique combination of caseID + projectId + resourceId + current time
                    schedule = new pse__Schedule__c();
                    schedule.pse__Start_Date__c = Date.today();
                    schedule.pse__End_Date__c = project.pse__End_Date__c;
                    schedule.pse__Scheduled_Hours__c = 1;
                    schedule.External_Look__c = String.valueOf(caseId) + String.valueOf(project.id) + String.valueOf(resourceId) + String.valueOf(system.now());
                    schedulesForUpsert.add(schedule);
                    
                    //Create another schedule record and set the external id of this record to the external id of the above created record.
                    scheduleLookUp = new pse__Schedule__c();
                    scheduleLookUp.External_Look__c = schedule.External_Look__c;
                    
                    //Create the assignment record. Set the resource and project look-ups. The schedule lookup is set to the scheduleLookUp record which references the schedule record. At the time of assignment creation, the lookup is set to the referenced record's ID
                    newAssignment = new pse__Assignment__c();
                    newAssignment.pse__Resource__c = resourceId;
                    newAssignment.pse__Project__c = project.id;
                    newAssignment.pse__Bill_Rate__c = 0;
                    //set the non_clonable flag. This assignment should not be cloned
                    newAssignment.Non_Clonable__c = true;
                    newAssignment.pse__Schedule__r = scheduleLookUp;
                    assignmentsToInsert.add(newAssignment);
                    
                    //If there is no entry in the resourceToAssignment map, for the resource, add an entry with empty assignment set. This is for multiple cases with the same owner linked to the same project. An entry in the map means there is an existing assignment for the resource and duplicate assignments wont be created.
                    if(! resourceToAssignment.containsKey(resourceId))
                    {
                        resourceToAssignment.put(resourceId,new Set<pse__Assignment__c>());
                    }
                    //remove the case id from the set
                    projectToCase.get(project.Id).remove(caseId);
                }
                
            }
            projectToCase.remove(project.id);
            
        }
        
        //If there are schedules to update, query for the schedules and add the records to the schedulesForUpsert list
        if(scheduleToEndDate != null && scheduleToEndDate.size() > 0)
        {
            for(pse__Schedule__c scheduleRecord: [select id, pse__End_Date__c from pse__Schedule__c where id in :scheduleToEndDate.keyset()])
            {
                scheduleRecord.pse__End_Date__c = scheduleToEndDate.get(scheduleRecord.id);
                schedulesForUpsert.add(scheduleRecord);
            }
        }
        
        //upsert the schedule list
        if(schedulesForUpsert != null && schedulesForUpsert.size() > 0)
        {
            try
            {
                upsertResultRecords = Database.Upsert(schedulesForUpsert,false);
                PSA_AutoCreateProjectUtil.PopulateErrorTableForUpsert(upsertResultRecords,'Schedules Upsert');
            }
            catch(Exception e)
            {
                PSA_AutoCreateProjectUtil.sendErrorMails('Schedule Upsert Exception',e.getMessage());
                return;
            }
            
        }
        //Insert the assignments
        if(assignmentsToInsert != null && assignmentsToInsert.size() > 0)
        {
            try
            {
                saveResultRecords = Database.Insert(assignmentsToInsert,false);
                PSA_AutoCreateProjectUtil.PopulateErrorTableForUpdate(saveResultRecords,assignmentsToInsert);
            }
            Catch(Exception e)
            {
                PSA_AutoCreateProjectUtil.sendErrorMails('Assignments Creation Exception',e.getMessage());
                
            }
            
        }
        
        
        
    }
    //End of changes by Sharath
    
    //Start of changes by Sharath for CR: 3593271: Check for the project manager change and change the approver of the pending timecards
    public static void changeTimecardApprover(Map<id,pse__Proj__c> oldMap,Map<id,pse__Proj__c> newMap)
    {
        // the project variable
        pse__Proj__c proj;
        // Map of project to list of contacts -> old and new project managers
        Map<id,List<Contact>> projectToContacts = new Map<id,List<Contact>>();
        //set of contact Ids
        Set<id> contactIds = new Set<id>();
        //Map of Id to Contact
        Map<Id,Contact> idTocontact = new Map<Id,Contact>();
        //Set of userIds
        Set<Id> userIds = new Set<Id>();
        //Set of projectIds
        Set<Id> projectIds = new Set<Id>();
        //Loop through the new map
        for (Id projId: newMap.keySet())
        {
            //Get the current project
            proj = newMap.get(projId);
            // if the old manager and new manager are different: project manager change
            if(proj.pse__Project_Manager__c != oldMap.get(projId).pse__Project_Manager__c)
            {
                // populate the contactIds and the projectIds set
                contactIds.add(oldMap.get(projId).pse__Project_Manager__c);
                contactIds.add(proj.pse__Project_Manager__c);
                projectIds.add(proj.id);
            }
        }
        //query for the contacts whose ids are in the set contactIds
        idTocontact = new Map<Id,Contact>([select id,pse__Salesforce_User__c,email from Contact where id in :contactIds]);
        
        if(idTocontact != null && idTocontact.size() > 0)
        {
            // loop through the project ids in the projectIds set
            for(Id projId: projectIds)
            {
                //get the corresponding project record
                proj = newMap.get(projId);
                // the idTocontact map should have an entry for the old and new managers
                if(idTocontact.containsKey(proj.pse__Project_Manager__c) && idTocontact.containsKey(oldMap.get(projId).pse__Project_Manager__c))
                {
                    // populate the map projectToContacts. Index 0 -> old manager and Index 1 ->  new manager
                    projectToContacts.put(projId,new List<Contact>());
                    projectToContacts.get(projId).add(idTocontact.get(oldMap.get(projId).pse__Project_Manager__c));
                    projectToContacts.get(projId).add(idTocontact.get(proj.pse__Project_Manager__c));
                    // Add the user Id of the old manager to the set userIds
                    userIds.add(idTocontact.get(oldMap.get(projId).pse__Project_Manager__c).pse__Salesforce_User__c);
                    
                }
            }
            // Check if the projectToContacts map is not null and has an entry
            if(userIds != null && userIds.size() > 0 && projectToContacts != null && projectToContacts.size() > 0)
            {
                // Create an object of the class PSA_TimecardApproverChange. Set the queryType to project
                PSA_TimecardApproverChange timecardApproverChange = new PSA_TimecardApproverChange();
                timecardApproverChange.queryType = 'project';
                timecardApproverChange.projectToContacts = projectToContacts;
                timecardApproverChange.userIds = userIds;
                System.enqueueJob(timecardApproverChange);
            }
            
        }
        
    }
    //End of changes by Sharath
    
    public static void createOpptyTask(List<pse__Proj__c> lProjects, Map<Id,pse__Proj__c> oldMap){
        System.debug('##@! ' + lProjects + ' #@! ' + oldMap);
        //Set<String> sWebAccountId = new Set<String>();
        //Set<String> sMediaAccountId = new Set<String>();
        //Set<String> sAccountId = new Set<String>();
        
        List<String> lOpptyId = new List<String> ();
        List<String> lAccountId = new List<String>();
        
        Map<String, AccountTeamMember> mAccountAndTeamMembers = new Map<String, AccountTeamMember>();
        Map<String, OpportunityTeamMember> mOpptyAndTeamMembers = new Map<String, OpportunityTeamMember>();
        Map<String, String> mAccIdAndAccName = new Map<String, String>();
        Map<String, String> mOpptyIdAndAccountName = new Map<String, String>();
        
        for(pse__Proj__c varProject : lProjects){
            if(varProject.Customer_Live__c != oldMap.get(varProject.Id).Customer_Live__c
               && varProject.Customer_Live__c && !varProject.Is_Auto_Task_Created__c ){
                   
                   List<String> lAccountDetails = varProject.PSA_Account_Details__c.split(':#');
                   mAccIdAndAccName.put(varProject.pse__Account__c, lAccountDetails[3].trim());
                   if(lAccountDetails[0].trim().equalsIgnoreCase('Media')
                      || lAccountDetails[0].trim().equalsIgnoreCase('web')){
                          varProject.Is_Auto_Task_Created__c = true;
                          if(varProject.pse__Opportunity__c != null){
                              lOpptyId.add(varProject.pse__Opportunity__c);
                              mOpptyIdAndAccountName.put(varProject.pse__Opportunity__c, lAccountDetails[3].trim());
                          }
                          else{
                              lAccountId.add(varProject.pse__Account__c);
                          }
                      }
               }
        }
        
        
        if(! lAccountId.isEmpty()){
            for(AccountTeamMember varAccountTeamMember : [SELECT AccountId, TeamMemberRole,
                                                          UserId, Id, Account.Name
                                                          FROM AccountTeamMember
                                                          WHERE AccountId IN :lAccountId
                                                          AND TeamMemberRole = 'Technical Sales - Primary']){
                                                              mAccountAndTeamMembers.put(varAccountTeamMember.AccountId, varAccountTeamMember);
                                                          }
        }
        
        if(! lOpptyId.isEmpty()){
            for(OpportunityTeamMember varOpptyTeamMember :[SELECT UserId, OpportunityId,
                                                           Id, TeamMemberRole
                                                           FROM OpportunityTeamMember
                                                           WHERE OpportunityId IN :lOpptyId
                                                           AND TeamMemberRole = 'Technical Sales - Primary']){
                                                               mOpptyAndTeamMembers.put(varOpptyTeamMember.OpportunityId, varOpptyTeamMember);
                                                           }
        }
        
        //if(! mAccountAndTeamMembers.keySet().isEmpty()){
        createActivity(lAccountId, lOpptyId, mAccountAndTeamMembers,
                       mOpptyAndTeamMembers, mAccIdAndAccName, mOpptyIdAndAccountName);
        //}
    }
    
    private static void createActivity(List<String> lAccountId,List<String> lOpptyId, Map<String, AccountTeamMember> mAccountAndTeamMembers,
                                       Map<String, OpportunityTeamMember> mOpptyAndTeamMembers, Map<String, String> mAccIdAndAccName,
                                       Map<String, String> mOpptyIdAndAccountName){
                                           set<String> sAccountWithoutSalesPrimary = new Set<String>();
                                           Id standardActivityRT = Task.sObjectType.getDescribe().getRecordTypeInfosByName().get('Standard Activity').getRecordTypeId();
                                           List<Task> lActivitiesToInsert = new List<Task>();
                                           for(String varAccountId :lAccountId){
                                               String ownerId = mAccountAndTeamMembers.containsKey(varAccountId) ? mAccountAndTeamMembers.get(varAccountId).UserId
                                                   : GSM_Custom_Settings__c.getValues('Common#ONAUserId').Value__c;
                                               String accountName =  mAccountAndTeamMembers.containsKey(varAccountId) ? mAccountAndTeamMembers.get(varAccountId).Account.Name : mAccIdAndAccName.get(varAccountId);
                                               System.debug('### user and What Id' + ownerId + ' ' + accountName);
                                               lActivitiesToInsert.add(initializeTask(varAccountId,ownerId,
                                                                                      'PIVC Meeting - Delivery', accountName,
                                                                                      'QBR/Value Confirmation', 'Deliver Post Integration Value Confirmation for',
                                                                                      '', 30, standardActivityRT));
                                               
                                           }
                                           
                                           for(String varOpptyId :lOpptyId){
                                               string ownerId = mOpptyAndTeamMembers.containsKey(varOpptyId) ? mOpptyAndTeamMembers.get(varOpptyId).UserId : '005A0000000OLet';
                                               lActivitiesToInsert.add(initializeTask(varOpptyId,ownerId,
                                                                                      'PIVC Meeting - Delivery', mOpptyIdAndAccountName.get(varOpptyId),
                                                                                      'QBR/Value Confirmation', 'Deliver Post Integration Value Confirmation for',
                                                                                      '', 30,standardActivityRT));
                                           }
                                           System.debug('#@!!@##@! ' + lActivitiesToInsert);
                                           insert lActivitiesToInsert;
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
    
    // Changes by Sharath Prasanna for FFPSA-238: Soasta Migration: if an attachment is created against hasAttachment field has to be checked.
    
    public static void updateTestRecordsTrue(Set<Id> testIds)
    {
        List<Test__c> testRecords = new List<Test__c>();
        testRecords = [Select id, Has_Attachment__c from Test__c where id in: testIds and Has_Attachment__c = false];
        
        List<Test__c> updateTests = new List<Test__c>();
        for(Test__c testRecord : testRecords)
        {
            testRecord.Has_Attachment__c = true;
            updateTests.add(testRecord);
        }
        if(!updateTests.isEmpty())
        {
            update updateTests;
        }
    }
    //Changes by Sharath for FFPSA-238: On delete, check if the report status is complete. If so, then dont allow delete.
    //public static void checkTestRecords(List<Attachment> attachmentList)
    //{
    //   //system.assertEquals(attachmentList,null);
    //   String testObjectPrefix;
    //   PSA_Settings__c psaSetting = PSA_Settings__c.getValues('TestObjectPrefix');
    //   List<Id> testToUpdate = new List<id>();
    //   if(psaSetting != null)
    //   {
    //       testObjectPrefix = psaSetting.value__c;
    //   }
    //   else
    //   {
    //       testObjectPrefix = 'aAE';
    //   }
    //   //String testObjectPrefix = PSA_Settings__c.getValues('TestObjectPrefix').value__c;
    //   Set<Id> testIdsToQuery = new Set<Id>();
    //   Set<Id> testIds = new Set<Id>();
    //   for(Attachment attachmentRecord: attachmentList)
    //   {
    //         if(String.valueOf(attachmentRecord.ParentId).startsWith(testObjectPrefix) && !testIdsToQuery.contains(attachmentRecord.ParentId))
    //         {
    //           testIdsToQuery.add(attachmentRecord.ParentId);
    //         }
    
    //   }
    //     Map<Id,Test__c> testRecordsMap = new Map<Id,Test__c>([Select id, Scenario_Status__c,Report_Required__c, Has_Attachment__c,(select id from Attachments) from Test__c where id in: testIdsToQuery]);
    //     for(Id testId: testRecordsMap.keySet())
    //     {
    //         Test__c testRecord = testRecordsMap.get(testId);
    //         if(testRecord.Attachments != null && testRecord.Attachments.size() == 1 && testRecord.Scenario_Status__c == 'Report Complete' && testRecord.Report_Required__c != 'None' && testRecord.Report_Required__c != 'Undetermined' && testRecord.Has_Attachment__c)
    //         {
    //             testIds.add(testId);
    //         }
    //         //Changes to remove the condition as part of FFPSA: 380: testRecord.Scenario_Status__c != 'Report Complete'
    //         //else if(testRecord.Attachments != null && testRecord.Attachments.size() == 1 && testRecord.Scenario_Status__c != 'Report Complete' && testRecord.Has_Attachment__c )
    //         else if(testRecord.Attachments != null && testRecord.Attachments.size() == 1 && testRecord.Has_Attachment__c )
    //         {
    //             testToUpdate.add(testRecord.Id);
    //         }
    //     }
    //     for(Attachment attachmentRecord: attachmentList)
    //     {
    //         if(testIds.contains(attachmentRecord.ParentId))
    //         {
    //             attachmentRecord.addError('Attachments can not be deleted when Test Status is “Report complete”. Please change the Test status in-order to delete the attachment');
    //         }
    //     }
    //     if (testToUpdate != null && !testToUpdate.isEmpty())
    //     {
    //         updateTestRecordsFalse(testToUpdate);
    //     }
    //}
    
    public static Set<Id> checkTestRecordsForDelete(set<Id> testIdsToCheck)
    {
        Map<Id,Integer> testToFiles = new Map<Id,Integer>();
        Integer count = 0;
        Set<Id> testIds = new Set<Id>();
        List<Id> testToUpdate = new List<Id>();
        for(ContentDocumentLink ContentDocumentLinkRecord: [select LinkedEntityId from ContentDocumentLink where LinkedEntityId in: testIdsToCheck])
        {
            if(!testToFiles.containsKey(ContentDocumentLinkRecord.LinkedEntityId))
            {
                testToFiles.put(ContentDocumentLinkRecord.LinkedEntityId,1);
            }
            else
            {
                
                count = testToFiles.get(ContentDocumentLinkRecord.LinkedEntityId);
                testToFiles.put(ContentDocumentLinkRecord.LinkedEntityId,count + 1);
            }
        }
        
        Map<Id,Test__c> testRecordsMap = new Map<Id,Test__c>([Select id, Scenario_Status__c,Report_Required__c, Has_Attachment__c,(select id from Attachments) from Test__c where id in: testIdsToCheck]);
        for(Id testId: testRecordsMap.keySet())
        {
            Test__c testRecord = testRecordsMap.get(testId);
            Integer fileCount = testToFiles.get(testRecord.Id) == null ? 0: testToFiles.get(testRecord.Id);
            
            if((((testRecord.Attachments == null || testRecord.Attachments.size() == 0) && fileCount == 1) || (testRecord.Attachments != null && testRecord.Attachments.size() == 1 && fileCount == 0)) && testRecord.Scenario_Status__c == 'Report Complete' && testRecord.Report_Required__c != 'None' && testRecord.Report_Required__c != 'Undetermined' && testRecord.Has_Attachment__c)
            {
                testIds.add(testId);
            }
            else if((((testRecord.Attachments == null || testRecord.Attachments.size() == 0) && fileCount == 1) || (testRecord.Attachments != null && testRecord.Attachments.size() == 1 && fileCount == 0)) && testRecord.Has_Attachment__c )
            {
                testToUpdate.add(testRecord.Id);
            }
        }
        if (testToUpdate != null && !testToUpdate.isEmpty())
        {
            updateTestRecordsFalse(testToUpdate);
        }
        return testIds;
    }
    
    @future
    public static void updateTestRecordsFalse(List<Id> tests)
    {
        List<test__c> testsToUpdate = new List<test__c>();
        if(tests != null && !tests.isEmpty())
        {
            for(Test__c test: [select id, Has_Attachment__c from test__c where id in :tests])
            {
                test.Has_Attachment__c = false;
                testsToUpdate.add(test);
            }
            if(testsToUpdate != null && !testsToUpdate.isEmpty())
            {
                update testsToUpdate;
            }
            
        }
    }
    //Changes by Sharath for FFPSA-238: After insert, assign the resource to the Test Multi resource field if he has an active assignment; otherwise assign the project manager
    public static void addTestResource(List<Test__c> testRecords)
    {
        
        //Map<Id,Test__c> creatorIdsToTest = new Map<Id,Test__c>();
        map<Id,Id> creatorIds = new map<id,Id>();
        Set<Id> projectIDs = new Set<Id>();
        map<id,String> idToName = new map<id,String>();
        map<id,set<id>> resourceToProjects = new map<id,set<id>>();
        date today = Date.today();
        List<Test__c> testRecordsToUpdate = new List<Test__c>();
        for (Test__c testRecord: testRecords)
        {
            creatorIds.put(testRecord.id,testRecord.createdById);
            projectIds.add(testRecord.Engagement__c);
        }
        
        List<pse__Assignment__c> assignments = new List<pse__Assignment__c>();
        assignments = [select id, pse__project__c,pse__Resource__c,pse__Resource__r.name,pse__Resource__r.pse__Salesforce_User__c from pse__Assignment__c where pse__project__c in :projectIds and pse__Resource__r.pse__Salesforce_User__c in :creatorIds.values() and pse__Closed_for_Time_Entry__c = false and pse__End_Date__c >= :today];
        
        for (pse__Assignment__c assignment: assignments)
        {
            if(!resourceToProjects.containsKey(assignment.pse__Resource__r.pse__Salesforce_User__c))
            {
                resourceToProjects.put(assignment.pse__Resource__r.pse__Salesforce_User__c, new Set<Id>());
            }
            resourceToProjects.get(assignment.pse__Resource__r.pse__Salesforce_User__c).add(assignment.pse__Project__c);
            if(!idToName.containsKey(assignment.pse__Resource__r.pse__Salesforce_User__c))
            {
                idToName.put(assignment.pse__Resource__r.pse__Salesforce_User__c,assignment.pse__Resource__r.name);
            }
        }
        //system.assertEquals(resourceToProjects, null);
        for(Test__c testRecord: [select id, Engagement__c,Engagement__r.pse__Project_Manager__r.pse__Salesforce_User__c,Engagement__r.pse__project_manager__r.Name from test__c where id in :creatorIds.keyset()])
        {
            Id creatorId = creatorIds.get(testRecord.Id);
            if(resourceToProjects != null && resourceToProjects.containsKey(creatorId) && resourceToProjects.get(creatorId).contains(testRecord.Engagement__c))
            {
                testRecord.Testing_PE_multi__c = idToName.get(creatorId);
            }
            else
            {
                
                testRecord.Testing_PE_multi__c = testRecord.Engagement__r.pse__project_manager__r.Name;
            }
            testRecordsToUpdate.add(testRecord);
        }
        //system.assertEquals(resourceToProjects,null);
        if(!testRecordsToUpdate.isEmpty())
        {
            update testRecordsToUpdate;
        }
    }
    
    public static void checkInvalidTestDelete(list<Test__c> toDelete)
    {
        for(Test__c test: toDelete)
        {
            if(test.Valid_Delete__c == false)
            {
                test.addError('Test Record may not be deleted');
            }
        }
    }
    /*
* Soasta Deployment Obj related changes.
* Send email when CLI is getting deleted.
*/
    
    public void sendCLIDeletionEmail(){
        //Changes by Sharath Prasanna for FFPSA-335: Added the filters: CT_TT_POC__c = false AND POC__c = false
        List<Deployment__c> lDeploymentWithoutCLI = [SELECT Id, CreatedBy.Email , CreatedBy.Name, Additional_Notification__c,
                                                     Additional_Notification__r.Email, CLI_Deletion_Notification_Sent__c,
                                                     LastModifiedBy.Email, LastModifiedBy.Name, Account__r.Name, CLI_Deleted__c,
                                                     Last_Modified_By_User__c
                                                     FROM Deployment__c
                                                     WHERE LastModifiedDate = LAST_N_DAYS:1
                                                     AND CLI_Deleted__c = false
                                                     AND Contract_Detail_Id__c = NULL AND CT_TT_POC__c = false
                                                     AND POC__c = false];
        List<Deployment__c> lDeploymentToUpdate = new List<Deployment__c>();
        
        if(! lDeploymentWithoutCLI.isEmpty()){
            for(Deployment__c varDeployment :lDeploymentWithoutCLI){
                varDeployment.CLI_Deleted__c = true;
                varDeployment.Last_Modified_By_User__c = varDeployment.LastModifiedById;
                lDeploymentToUpdate.add(varDeployment);
            }
            update lDeploymentToUpdate;
        }
        
        
    }
    
    //Changes by Sharath for Delegated Approval of timecards: FFPSA-142
    public static void updateCustomDelegatedApproverField(Map<Id,user>oldMap,Map<Id,user>newMap)
    {
        Set<Id> userIdToDelegatedApprover = new Set<Id>();
        Set<Id> delgUserIds = new Set<Id>();
        
        for(User usr : newMap.values()){
            delgUserIds.add(usr.DelegatedApproverid);
        }
        
        Map<Id,User> currentUsers_DelegatedApprover  = new Map<Id,User>([SELECT Id,TimeZoneSidKey from User where Id =: delgUserIds]);
        
        for (Id userId: oldMap.keySet())
        {
            //Checking if there is a change in the delegated approver and set the id to a custom field
            if(oldMap.get(userID).DelegatedApproverid != newMap.get(userID).DelegatedApproverid || oldMap.get(userID).Delegation_EndTime__c != newMap.get(userID).Delegation_EndTime__c)
            {
                if(newMap.get(userID).DelegatedApproverid != null && oldMap.get(userID).DelegatedApproverid != newMap.get(userID).DelegatedApproverid)
                {
                    newMap.get(userID).Delegation_StartTime__c = Datetime.now();
                }
                else if(newMap.get(userID).DelegatedApproverid == null)
                {
                    newMap.get(userID).Delegation_StartTime__c = null;
                    newMap.get(userID).Delegation_EndTime__c = null;
                    newMap.get(userID).DA_EndTime__c = null;
                }
                newMap.get(userID).Delegated_Approver_Custom__c = newMap.get(userID).DelegatedApproverid;
                userIdToDelegatedApprover.add(userID);
            }
            
            //Checking if the custom delegated approver field was set to NULL. Then clear the Delegated Approver Id, the delegation start and end times
            if(oldMap.get(userID).DelegatedApproverid == newMap.get(userID).DelegatedApproverid && oldMap.get(userID).Delegated_Approver_Custom__c != newMap.get(userID).Delegated_Approver_Custom__c && newMap.get(userID).Delegated_Approver_Custom__c == null)
            {
                newMap.get(userID).DelegatedApproverid = null;
                newMap.get(userID).Delegation_EndTime__c = null;
                newMap.get(userID).Delegation_StartTime__c = null;
                newMap.get(userID).DA_EndTime__c = null;
                userIdToDelegatedApprover.add(userID);
                
            }
            
            //Changes by Sujay : FFPSA-479 Adding below condition to stamp Delegation EndDate
            if(newMap.get(userID).Delegation_EndTime__c  != NULL
               && (oldMap.get(userID).Delegation_EndTime__c  != newMap.get(userID).Delegation_EndTime__c || oldMap.get(userID).DelegatedApproverId != newMap.get(userID).DelegatedApproverId) )
            {
                Integer dte,month,year,diffSeconds;
                DateTime DT;
                
                dte = newMap.get(userID).Delegation_EndTime__c.day();
                month = newMap.get(userID).Delegation_EndTime__c.month();
                year = newMap.get(userID).Delegation_EndTime__c.year();
                DT = DateTime.newInstance(year, month, dte);
                //DateTime DT = DateTime.newInstance(yr, mo, d, 00, 00, 00);
                system.debug('NOW: ' + datetime.now());
                System.debug('DT :: ' + DT);
                newMap.get(userID).DA_EndTime__c = DT;
                System.debug('newMap.get(userID).DA_EndTime__c :: ' + newMap.get(userID).DA_EndTime__c);
                
                TimeZone tz1 = Timezone.getTimeZone(newMap.get(userID).TimeZoneSidKey);
                System.debug('tz1 :: '+ tz1);
                System.debug('tz1.getOffset(DT) ::'+ tz1.getOffset(DT));
                
                TimeZone tz2 = Timezone.getTimeZone(currentUsers_DelegatedApprover.get(newMap.get(userID).DelegatedApproverid).TimeZoneSidKey);
                System.debug('tz2 :: '+ tz2);
                System.debug('tz2.getOffset(DT) ::'+ tz2.getOffset(DT));
                
                if(tz1.getOffset(DT) > 0 && tz2.getOffset(DT) > 0){
                    diffSeconds = tz1.getOffset(DT) > tz2.getOffset(DT) ? (tz1.getOffset(DT) - tz2.getOffset(DT)) : -(tz2.getOffset(DT) - tz1.getOffset(DT));
                    newMap.get(userID).DA_EndTime__c = DT.addSeconds(diffSeconds/1000);
                }
                else if(tz1.getOffset(DT) > 0 && tz2.getOffset(DT) < 0){
                    newMap.get(userID).DA_EndTime__c = DT.addSeconds((tz1.getOffset(DT) - tz2.getOffset(DT))/1000);
                }
                else if(tz1.getOffset(DT) < 0 && tz2.getOffset(DT) > 0){
                    newMap.get(userID).DA_EndTime__c = DT.addSeconds(-(tz2.getOffset(DT) - tz1.getOffset(DT))/1000);
                }
                else if(tz1.getOffset(DT) < 0 && tz2.getOffset(DT) < 0){
                    diffSeconds = tz1.getOffset(DT) > tz2.getOffset(DT) ? -(tz2.getOffset(DT) - tz1.getOffset(DT)) : (tz1.getOffset(DT) - tz2.getOffset(DT));
                        newMap.get(userID).DA_EndTime__c = DT.addSeconds(diffSeconds/1000);
                }
                else if(tz1.getOffset(DT) == 0 && tz2.getOffset(DT) < 0){
                    newMap.get(userID).DA_EndTime__c = DT.addSeconds(-(tz2.getOffset(DT))/1000);
                }
                else if(tz1.getOffset(DT) == 0 && tz2.getOffset(DT) > 0){
                    newMap.get(userID).DA_EndTime__c = DT.addSeconds(-(tz2.getOffset(DT))/1000);
                }
                else if(tz1.getOffset(DT) > 0 && tz2.getOffset(DT) == 0){
                    newMap.get(userID).DA_EndTime__c = DT.addSeconds((tz1.getOffset(DT))/1000);
                }
                else if(tz1.getOffset(DT) < 0 && tz2.getOffset(DT) == 0){
                    newMap.get(userID).DA_EndTime__c = DT.addSeconds((tz1.getOffset(DT))/1000);
                }
            }
            
        }//end of OldMap.KeySet() loop
        
        //Check if the function is not called in a future call or batch or a scheduled job context. Call the future method to create the history record
        if(!(System.isFuture() || System.isScheduled() || System.isBatch()) && !userIdToDelegatedApprover.isEmpty())
        {
            createDelegationHistoryRecord(userIdToDelegatedApprover);
        }
        
    }
    
    @future
    public static void createDelegationHistoryRecord(Set<Id> userIdToDelegatedApprover)
    {
        
        Map<id,FF_Delegation_History__c> userIdToDelegatedHistories = new Map<id,FF_Delegation_History__c>();
        
        for(FF_Delegation_History__c delgatedHistoryRecord: [select Id, Delegated_Approver__c, Delegation_For__c, Delegation_Start_Time__c,Delegation_End_Time__c  from FF_Delegation_History__c where Delegation_For__c in: userIdToDelegatedApprover])
        {
            userIdToDelegatedHistories.put(delgatedHistoryRecord.Delegation_For__c,delgatedHistoryRecord);
        }
        
        FF_Delegation_History__c delgatedHistory;
        
        List<FF_Delegation_History__c> delgatedHistoriesToUpsert = new List<FF_Delegation_History__c>();
        
        //Check if the history record is present for the user, if so, update the record; Otherwise create the record
        for(User userRecord: [select id,DelegatedApproverid,Delegation_EndTime__c,Delegation_StartTime__c from User where id in :userIdToDelegatedApprover])
        {
            if(userIdToDelegatedHistories.containsKey(userRecord.Id))
            {
                delgatedHistory = userIdToDelegatedHistories.get(userRecord.Id);
                
            }
            else if(userIdToDelegatedApprover.contains(userRecord.Id))
            {
                delgatedHistory = new FF_Delegation_History__c();
                delgatedHistory.Delegation_For__c = userRecord.Id;
            }
            if(delgatedHistory != null)
            {
                delgatedHistory.Delegated_Approver__c = userRecord.DelegatedApproverid;
                if(delgatedHistory.Delegated_Approver__c != null)
                {
                    delgatedHistory.Delegation_Start_Time__c = userRecord.Delegation_StartTime__c;
                    delgatedHistory.Delegation_End_Time__c = userRecord.Delegation_EndTime__c;
                }
                else
                {
                    delgatedHistory.Delegation_Start_Time__c = null;
                    delgatedHistory.Delegation_End_Time__c = null;
                }
                delgatedHistoriesToUpsert.add(delgatedHistory);
            }
            
        }
        
        Database.upsert(delgatedHistoriesToUpsert,false);
    }
    
    //Changes by Suhas for FFPSA-490
    public static void preventDupBED(List<Task> newTriggerTasks, List<Task> oldTriggerTasks, Boolean isInsert)
    {
        
        List<Id> tasksprojid = new List<Id>();
        List<Id> tasksid = new List<Id>();
        List<Task> lstMatchingTasks = new List<Task>();
        Schema.DescribeSObjectResult projDes = pse__Proj__c.SObjectType.getDescribe();
        String keyPrefix = projDes.getKeyPrefix();
        Id PSAActivityId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('PSA Activity').getRecordTypeId();
        String taskType =  [Select Value__C from PSA_Common_Setting__mdt where Name__c = 'Project Task Record Types'].Value__C;
        Set<String> taskTypes = new Set<String>(taskType.split(','));
        Map<Id, Task> projIdToTask = new Map<Id, Task>();
        
        for(Task tsk: newTriggerTasks)
        {
            if( (tsk.RecordTypeId == PSAActivityId) &&  ( tsk.WhatId !=  null && String.valueof(tsk.WhatId).startsWith(keyPrefix))  && ( taskTypes.contains(tsk.Type__c) ) )
            {
                tasksprojid.add(tsk.WhatId);
                if(! isInsert)
                {
                    tasksid.add(tsk.Id);
                }
            }
        }
        
        if(tasksprojid.size() > 0 )
        {
            lstMatchingTasks = [SELECT Id, WhatId
                                FROM task
                                WHERE WhatId IN : tasksprojid
                                AND Type__c IN : taskTypes
                                AND Id NOT IN : tasksid
                                AND Status NOT IN ('Completed','Completed Important')];
        }
        
        
        // hols projId and Task records
        
        for(Task tsk  : lstMatchingTasks){
            if(! projIdToTask.containsKey(tsk.WhatId)){
                projIdToTask.put(tsk.WhatId , tsk);
            }
        }
        
        for(Task tsk: newTriggerTasks){
            if( (tsk.RecordTypeId == PSAActivityId) && ( tsk.WhatId !=  null && String.valueof(tsk.WhatId).startsWith(keyPrefix)) )
            {
                if(projIdToTask.containsKey(tsk.WhatId) && ( taskTypes.contains(tsk.Type__c) ))
                {
                    tsk.addError('There is already a Task open with this project of similar type');
                }
            }
        }
        
        
    }
    public static void notifyBED(List<Task> newTriggerTasks, List<Task> oldTriggerTasks, Boolean isInsert, Map<Id, Task> oldTriggerMap)
    {
        if(isFirstTime)
        {
            isFirstTime = false;
            Schema.DescribeSObjectResult projDesc = pse__Proj__c.SObjectType.getDescribe();
            String keyPrefix = projDesc.getKeyPrefix();
            Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
            Messaging.Singleemailmessage objEmail;
            List<pse__Proj__c> projAccEmail = new List<pse__Proj__c>();
            Id PSAActivityId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('PSA Activity').getRecordTypeId();
            PSA_Settings__c fromAddress = PSA_Settings__c.getInstance('FromEmailAdress');
            String emailAddress = fromAddress != null ?fromAddress.Value__c : 'services-engg@akamai.com';
            String orgWideEmailId;
            try
            {
                orgWideEmailId = [select Id from OrgWideEmailAddress where Address = :emailAddress limit 1].Id;
            }
            catch(Exception e)
            {
                orgWideEmailId = null;
            }
            
            Map<Id, pse__Proj__c> projsforEmail = new Map<Id, pse__Proj__c>();
            
            
            List<String> taskProjIdLst = new List<String>();
            
            for(Task tsk: newTriggerTasks)
            {
                if( (tsk.RecordTypeId == PSAActivityId) && (tsk.WhatId !=  null && String.valueof(tsk.WhatId).startsWith(keyPrefix)) && tsk.Type__c == 'BED Extension Required' )
                {
                    taskProjIdLst.add(tsk.WhatId);
                }
            }
            
            if(taskProjIdLst.size() > 0)
            {
                projAccEmail = [Select pse__Project_ID__c,Name,pse__Project_Manager__r.Name,Billing_Effective_Date__c,pse__Account__r.Owner.Email, pse__Account__r.Owner.Name , pse__Account__r.Name , Id from pse__Proj__c where Id IN : taskProjIdLst ];
                
                for(pse__Proj__c proj : projAccEmail)
                {
                    projsforEmail.put(proj.Id, proj);
                }
            }
            for(Task tsk: newTriggerTasks)
            {
                Task oldTask = new Task();
                if(! isInsert && ( (tsk.RecordTypeId == PSAActivityId) && tsk.WhatId !=  null && String.valueof(tsk.WhatId).startsWith(keyPrefix)) && tsk.Type__c == 'BED Extension Required' )
                {
                    oldTask = oldTriggerMap.get(tsk.Id) ;
                }
                
                if( ( (tsk.RecordTypeId == PSAActivityId) && tsk.WhatId !=  null && String.valueof(tsk.WhatId).startsWith(keyPrefix)) &&  ((  isInsert && tsk.Type__c == 'BED Extension Required') || ( !isInsert && ( tsk.Type__c == 'BED Extension Required' && oldTask.Type__c != 'BED Extension Required' )) ))
                {
                    String projIdURL = system.URL.getSalesforceBaseUrl().toExternalForm() + '/' + tsk.WhatId; 
                    String projNameURL = system.URL.getSalesforceBaseUrl().toExternalForm() + '/' + tsk.WhatId;
                    String projManagerURL = system.URL.getSalesforceBaseUrl().toExternalForm() + '/' + projsforEmail.get(tsk.WhatId).pse__Project_Manager__c;
                    
                    String htmlbody = '<html><body><p>Hi ' ;
                    
                    htmlbody = htmlbody + projsforEmail.get(tsk.WhatId).pse__Account__r.Owner.Name ;
                    htmlbody = htmlbody + ',</p><p>You are receiving this e-mail because your customer, <span style="font-weight:bold">' + projsforEmail.get(tsk.WhatId).pse__Account__r.Name ;
                    htmlbody = htmlbody + '</span>, has a service order which will not have the basic implementation completed prior to the billing effective date on their service agreement.</br>';
                    htmlbody = htmlbody + '</br>To prevent issuing an invoice to this customer in advance of the services being live, it is recommended that you defer the billing effective date on their service agreement.';
                    htmlbody = htmlbody + '<span>  We anticipate that their services will be live by</span> <span style="font-weight:bold">' +tsk.ActivityDate.month()+'/'+tsk.ActivityDate.day()+'/'+tsk.ActivityDate.year();
                    htmlbody = htmlbody + ' </span> .Please click <a href="https://ac.akamai.com/docs/DOC-46119"> here </a>';
                    htmlbody = htmlbody + '    for the guide with instructions on how to defer the billing effective date of this order.</br>';
                    htmlbody = htmlbody + '</br>For questions about this customer’s implementation, please contact our Delivery Excellence team (<a href="mailto:AskDelEx@akamai.com" >AskDelEx@akamai.com</a>).  For questions related to processing a deferral for your customer, please contact our Order Management team (<a href="mailto:ordermanagement@akamai.com" >ordermanagement@akamai.com</a>).</p>';
                    
                    //Changes by Sandeep for FFPSA-616
                    htmlbody = htmlbody + '</br><B>BED Extension Information: </B></br></br>';
                    htmlbody = htmlbody + '</br>Project ID: <a href='+projIdURL+'>'+projsforEmail.get(tsk.WhatId).pse__Project_ID__c+'</a> </br>';
                    htmlbody = htmlbody + '</br>Project Name: <a href='+projNameURL+'>'+projsforEmail.get(tsk.WhatId).Name+'</a> </br>';
                    htmlbody = htmlbody + '</br>Project Manager: <a href='+projManagerURL+'>'+projsforEmail.get(tsk.WhatId).pse__Project_Manager__r.Name+'</a> </br>';
                    htmlbody = htmlbody + '</br>Current BED: ' + projsforEmail.get(tsk.WhatId).Billing_Effective_Date__c + '</br>';
                    
                    htmlbody = htmlbody + '</br></br><p>Thanks in advance for your prompt attention to this matter.</br> Global Service & Support </p></br>';
                    
                    htmlbody = htmlbody + '</body></html>';
                    
                    sendMail_BED(projsforEmail.get(tsk.WhatId).pse__Account__r.Owner.Email, null , null ,null , orgWideEmailId, mailsToBeSent, null, 'ACTION REQUIRED - Billing Deferral Required' , htmlbody);
                    
                }
            }
            
            if(mailsToBeSent.size() > 0)
            {
                Messaging.SendEmailResult [] mailSendResult = Messaging.sendEmail(mailsToBeSent,false);
                for(Messaging.SendEmailResult result : mailSendResult)
                {
                    System.debug('Email result ' + result.IsSuccess());
                    System.debug('Individ rsl :' + result);
                }
            }
        }
    }
    
    public static void notifyforBEDExtension(List<pse__Proj__c> newTriggerProjects, Map<Id, pse__Proj__c> oldTriggerProjectsMap )
    {
        if(isFirstTime)
        {
            isFirstTime = false;
            Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
            Messaging.SingleEmailMessage objEmail;
            List<Task> tasktoClose = new List<Task>();
            Map<Id, String> projOwnerEmail = new Map<Id, String>();
            Map<Id, Id> projManagerId = new Map<Id, Id>();
            Map<Id, pse__Proj__c> projsforEmail = new Map<Id, pse__Proj__c>();
            PSA_Settings__c fromAddress = PSA_Settings__c.getInstance('FromEmailAdress');
            String emailAddress = fromAddress != null ?fromAddress.Value__c : 'services-engg@akamai.com';
            String orgWideEmailId;
            try
            {
                orgWideEmailId = [select Id from OrgWideEmailAddress where Address = :emailAddress limit 1].Id;
            }
            catch(Exception e)
            {
                orgWideEmailId = null;
            }
            List<id> taskforProject = new List<id>();
            
            
            for(pse__Proj__c proj: newTriggerProjects)
            {
                if( (proj.Billing_Effective_Date__c > oldTriggerProjectsMap.get(proj.Id).Billing_Effective_Date__c) && proj.pse__Stage__c != 'Closed')
                {
                    taskforProject.add(proj.Id);
                }
            }
            
            if(taskforProject.size() > 0)
            {
                for(pse__Proj__c prj: [select Owner.Email, Owner.Id, pse__Project_Manager__r.Id ,Id from pse__Proj__c where id IN : taskforProject] )
                {
                    projOwnerEmail.put(prj.Id, prj.Owner.Email);
                    projManagerId.put(prj.Id, prj.pse__Project_Manager__r.Id);
                    
                    projsforEmail.put(prj.Id, prj);
                }
                List<EmailTemplate> template = [SELECT id FROM EmailTemplate WHERE developerName = 'BEDUpdated' limit 1];
                
                for(Task tsk :[ select Id, WhatId from Task where WhatId IN : taskforProject and Type__c IN ('BED Extension Required') AND Status NOT IN ('Completed','Completed Important')  ])
                {
                    tsk.Status = 'Completed';
                    tasktoClose.add(tsk);
                    sendMail_BED( projsforEmail.get(tsk.WhatId).Owner.Email, projsforEmail.get(tsk.WhatId).pse__Project_Manager__r.Id , template.get(0).Id , tsk.WhatId , orgWideEmailId , mailsToBeSent, null, null, null);
                }
            }
            
            if(mailsToBeSent.size() > 0)
            {
                Messaging.SendEmailResult [] mailSendResult = Messaging.sendEmail(mailsToBeSent,false);
                for(Messaging.SendEmailResult result : mailSendResult)
                {
                    System.debug('Email result ' + result.IsSuccess());
                    System.debug('Individ rsl :' + result);
                }
            }
            
            if(tasktoClose.size() > 0 )
            {
                Database.update(tasktoClose,false);
            }
        }
    }
    
    public static void sendMail_BED(String toAddress, Id targetObjectId , Id templateId ,Id whatId, String orgWideEmailId, Messaging.SingleEmailMessage[] mailsToBeSent, String ccAddress, String subject, String htmlbody)
    {
        Messaging.SingleEmailMessage objEmail = new Messaging.Singleemailmessage();
        objEmail.setToAddresses(new list<String>{toAddress});
        
        objEmail.setReplyTo('noreply@akamai.com');
        if(targetObjectId != null)
        {
            objEmail.setTargetObjectId(targetObjectId);
        }
        if(templateId != null)
        {
            objEmail.setTemplateId(templateId);
        }
        if(ccAddress != null)
        {
            objEmail.setCcAddresses(new list<String>{ccAddress});
        }
        if( subject != null )
        {
            objEmail.setSubject(subject);
        }
        if(whatId != null)
        {
            objEmail.setWhatId(whatId);
        }
        if(htmlbody != null)
        {
            objEmail.setHtmlBody(htmlbody);
        }
        if (orgWideEmailId != null)
        {
            objEmail.setOrgWideEmailAddressId(orgWideEmailId);
        }
        
        objEmail.saveAsActivity = false ;
        mailsToBeSent.add(objEmail);
    }
    // End of Changes by Suhas for FFPSA-490
    
    
    //Start of Changes by Sandeep for FFPSA-772
    //This helper function is used to auto-update BIC and IC values on Project with max values of BIC and Go-Live Date of all project products corresponding to it.
    public static void updateBICAndICOnProject(Map<Id,pse__Proj__c> oldMap,List<pse__Proj__c> newProjectList)
    {
        System.debug('##newProjectList: '+newProjectList);
        System.debug('##oldProjectList: '+oldMap);
        List<Id> projectIdList = new List<Id>();
        Set<Id> projectsIdsWithCustomerLiveList = new Set<Id>();
        
        //Add all the projects with type = 'New Implementation' and are being closed and complete in the current update to projectIdList
        for(pse__Proj__c eachProj : newProjectList)
        {
            if(eachProj.pse__Project_Type__c=='New Implementation' && oldMap.get(eachProj.id).pse__Stage__c!='Closed' && oldMap.get(eachProj.id).Close_Code__c!='Complete' && eachProj.pse__Stage__c=='Closed' && eachProj.Close_Code__c=='Complete')
            {
                projectIdList.add(eachProj.id);
                
                if(eachProj.Customer_Live__c)
                {
                    projectsIdsWithCustomerLiveList.add(eachProj.id);
                }
            }
        }
        
        
        
        if(projectIdList.size()>0)
        { 
            //Query for all project products of all projects that are being updated and above conditions are met.
            List<pse__Project_Methodology__c> projectProducts = [
                SELECT pse__Project__c, Basic_Implementation_Complete__c, Go_Live_Date__c
                FROM pse__Project_Methodology__c
                WHERE 
                pse__Project__c IN :projectIdList
            ];
            
            
            System.debug('#####DEBUG######');
            System.debug('### projectIdList: '+projectIdList);
            System.debug('### projectsIdsWithCustomerLiveList: '+projectsIdsWithCustomerLiveList);
            System.debug('### projectIdList: '+projectIdList);
            
            //Query all the project products for each project and determine if all BIC and Go-Lice date are filled on all project Products
            //If so, then update the BIC and IC of the project with the latest of all Project Product BIC and Go-Live Dates from the corresponding project.
            Set<Id> bicErrorOnProjectProductList = new Set<Id>(); 
            Set<Id> gldErrorOnProjectProductList = new Set<Id>(); 
            Map<Id,Date> latestProjectBICMap = new Map<Id,Date>();
            Map<Id,Date> latestProjectICMap = new Map<Id,Date>();
            
            for(pse__Project_Methodology__c eachProduct : projectProducts)
            {
                System.debug('### Entered first for');
                if(!bicErrorOnProjectProductList.contains(eachProduct.pse__Project__c) && eachProduct.Basic_Implementation_Complete__c == NULL)
                {
                    bicErrorOnProjectProductList.add(eachProduct.pse__Project__c); 
                }
                if(!gldErrorOnProjectProductList.contains(eachProduct.pse__Project__c) && projectsIdsWithCustomerLiveList.contains(eachProduct.pse__Project__c) && eachProduct.Go_Live_Date__c == NULL)
                {
                    gldErrorOnProjectProductList.add(eachProduct.pse__Project__c); 
                }
                
                //Map the Project Ids(Project) to latest BIC and Go-Live Date (if Customer_Live__c is checked) values of project products
                if((!bicErrorOnProjectProductList.contains(eachProduct.pse__Project__c) && !gldErrorOnProjectProductList.contains(eachProduct.pse__Project__c)))
                {
                    System.debug('### Entered third if');
                    //Fetch latest BIC
                    Date latestBIC = latestProjectBICMap.get(eachProduct.pse__Project__c);
                    System.debug('## Null latestBIC check ' + latestBIC);
                    if(latestBIC == NULL || eachProduct.Basic_Implementation_Complete__c > latestBIC)
                    {
                        latestProjectBICMap.put(eachProduct.pse__Project__c,eachProduct.Basic_Implementation_Complete__c);
                    }
                    
                    //Fetch latest IC only if Customer_Live__c is checked
                    if(projectsIdsWithCustomerLiveList.contains(eachProduct.pse__Project__c))
                    {
                        Date latestIC = latestProjectICMap.get(eachProduct.pse__Project__c);
                        System.debug('## Null latestIC check ' + latestIC);
                        if(latestIC == NULL || eachProduct.Go_Live_Date__c > latestIC)
                        {
                            latestProjectICMap.put(eachProduct.pse__Project__c,eachProduct.Go_Live_Date__c);
                        }
                    }
                }
            }
            
            System.debug('### bicErrorOnProjectProductList: '+bicErrorOnProjectProductList);
            System.debug('### gldErrorOnProjectProductList: '+gldErrorOnProjectProductList);
            
            for(pse__Proj__c eachProject : newProjectList)
            {        
                System.debug('### Entered for 2');
                //For all the projects with error, throw error message
                if(bicErrorOnProjectProductList.contains(eachProject.id) || gldErrorOnProjectProductList.contains(eachProject.id))
                {
                    System.debug('### Entered for 2 if');
                    if(bicErrorOnProjectProductList.contains(eachProject.id))
                    {
                        eachProject.addError('Basic Implementation Complete is  mandatory on all the Project Products to "Close" the Project with "Complete"');
                    }
                    if(gldErrorOnProjectProductList.contains(eachProject.id))
                    {
                        eachProject.addError('Go-Live Date is  mandatory on all the Project Products to "Close" the Project with "Complete"');
                    } 
                }
                
                
                //For all other projects update the value of BIC and IC on newProjectList(trigger.new) from latestBIC and latestIC maps
                else 
                {
                    System.debug('### Entered for 2 else');
                    if(latestProjectBICMap.get(eachProject.id)!=NULL)
                        eachProject.Basic_Implementation_Complete__c = latestProjectBICMap.get(eachProject.id);
                    if(latestProjectICMap.get(eachProject.id)!=NULL )
                        eachProject.Implementation_Complete__c = latestProjectICMap.get(eachProject.id);
                }
                
            }
            System.debug('### latestProjectBICMap: '+latestProjectBICMap);
            System.debug('### latestProjectICMap: '+latestProjectICMap);
        }
    }
    //End of Changes by Sandeep for FFPSA-772  


    //Changes By Suhas for FFPSA-636
    public static void restrictCurrentTermFieldAccess(Map<id, pse__Proj__c > oldMap, List<pse__Proj__c> newList )
    {
        String currentUserEmail = UserInfo.getUserEmail();
        Id profileId= userinfo.getProfileId();
        System.debug('prof id : ' +  profileId);

        Id systemAdminId = [select Value__c from PSA_Common_Setting__mdt where DeveloperName = 'System_Admin_Id' ].value__c ;        

        for (pse__Proj__c eachProj : newList) {

            if ( (eachProj.Current_Contract_Term_Start_Date__c != oldMap.get(eachProj.id).Current_Contract_Term_Start_Date__c  )
                && !( eachProj.Owner_Manager_Email_address__c == currentUserEmail || eachProj.Owner_Email_address__c == currentUserEmail || profileId == systemAdminId ) 
                && !eachProj.Validation_Override__c && !Test.isRunningTest() ) 
            {
                eachProj.addError('Only Project Manager and Project Manager\'s direct Manager will be able to edit Current Contract Term Start Date field');
            }
            
        }


    }
    
}