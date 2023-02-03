/**
 * @description       : FFPSA-1906 to Auto-creation of Time-Off Projects every year on dec 31
 * @author            : Sujay
 * date               : October 2021
 * @last modified on  : October 2021
**/

public class PSA_AutoCreateTimeOffProjectYOY implements Database.batchable<sObject>, Database.Stateful
{

    public String query;
    public Date yearEndDate;
    public Id regionId,practiceId,accountId;
    public pse__Proj__c newTimeOffProj = new pse__Proj__c();


    public PSA_AutoCreateTimeOffProjectYOY()
    {
        if(!Test.isRunningTest())
        {
            regionId    = [select Id,Name from pse__Region__c where Name = 'Corporate' limit 1].Id;
            practiceId  = [select Id,Name from pse__Practice__c where Name = 'Internal' limit 1].Id;
            accountId   = [select Id, Name from Account where Name = 'Akamai Technologies - Assets' limit 1].Id; 
        }
        
    }


    public Database.QueryLocator start( Database.BatchableContext BC )
    {
        yearEndDate = (yearEndDate == null) ? Date.newInstance(Date.today().year(), 12, 31) : yearEndDate;
        System.debug('yearEndDate in start:: '+ yearEndDate);

        if(query == null)
        {
            query = Test.isRunningTest() ? 'select id, pse__Project_Type__c, Project_Sub_Type__c, pse__Region__c, pse__Practice__c, pse__Start_Date__c, pse__End_Date__c, pse__Stage__c, Close_Code__c, pse__Is_Active__c, pse__Closed_for_Time_Entry__c, pse__Project_Status__c, pse__Project_Status_Notes__c  from pse__Proj__c limit 1' : 'select id, pse__Project_Type__c, Project_Sub_Type__c, pse__Region__c, pse__Practice__c, pse__Start_Date__c, pse__End_Date__c, pse__Stage__c, Close_Code__c, pse__Is_Active__c, pse__Closed_for_Time_Entry__c, pse__Project_Status__c, pse__Project_Status_Notes__c  from pse__Proj__c where pse__stage__c != \'Closed\' and pse__Project_Type__c = \'Internal\' and Project_Sub_Type__c = \'Time Off\' and pse__Account__c = \''+ accountId + '\'  and pse__Practice__c = \''+ practiceId + '\'  and pse__Region__c = \''+ regionId + '\' and  pse__End_Date__c =: yearEndDate  limit 1'  ;
            System.debug('query:: ' + query);
        }
        return Database.getQueryLocator( query );

    }

    public void execute( Database.BatchableContext BC, List < sObject > scope )
    {
        System.debug('In Execute');
        List<pse__proj__c> timeOffProj = (List<pse__proj__c>)scope;
        System.debug('timeOffProj :: ' + timeOffProj);
        List<pse__proj__c> timeOffProjectsUpsert = new List<pse__proj__c>();

        if(!timeOffProj.isEmpty() && timeOffProj.size() == 1)
        {
            regionId    = [select Id,Name from pse__Region__c where Name = 'Corporate' limit 1].Id;
            practiceId  = [select Id,Name from pse__Practice__c where Name = 'Internal' limit 1].Id;
            accountId   = [select Id, Name from Account where Name = 'Akamai Technologies - Assets' limit 1].Id;
            
            System.debug('timeOffProj inside if :: ' + timeOffProj);
            pse__Proj__c newTimeOffProject = new pse__Proj__c();

            for(pse__Proj__c eProj : timeOffProj)
            {
                System.debug('eProj.pse__End_Date__c : '+ eProj.pse__End_Date__c);
                System.debug('yearEndDate in execute: '+ yearEndDate);
                if(yearEndDate.isSameDay(eProj.pse__End_Date__c))
                {
                    System.debug('yearEndDate ' + yearEndDate);
                    newTimeOffProj.pse__Account__c      =   accountId;
                    newTimeOffProj.Name                 =   'Time off - ' + (Date.today().year() + 1);
                    newTimeOffProj.pse__Project_Type__c =   'Internal';
                    newTimeOffProj.Project_Sub_Type__c  =   'Time Off';
                    newTimeOffProj.pse__Region__c       =   regionId;
                    newTimeOffProj.pse__Practice__c     =   practiceId;
                    newTimeOffProj.pse__Start_Date__c   =   Date.newInstance((Date.today().year()+1), 01, 01);
                    newTimeOffProj.pse__End_Date__c     =   Date.newInstance((Date.today().year()+1), 12, 31);
                    newTimeOffProj.pse__Stage__c        =   'In Progress';
                    newTimeOffProj.Contract_Closed__c   =   'Internal';
                    newTimeOffProj.pse__Billing_Type__c =   'N/A';
                    newTimeOffProj.pse__Is_Active__c    =   true;
                    newTimeOffProj.pse__Daily_Timecard_Notes_Required__c        = true;
                    newTimeOffProj.pse__Allow_Timecards_Without_Assignment__c   = true;

                    insert newTimeOffProj;

                    /*try
                    {

                    }
                    catch(Exception e)
                    {
                        System.debug('Exception while creating time-off Project :: ' + e.getMessage());
                        PSA_AutoCreateProjectUtil.sendErrorMails('Error: Exception while creating time-off Project (Class:PSA_AutoCreateTimeOffProjectYOY), ',(System.Url.getSalesforceBaseURL().toExternalForm())  +'\n' +e.getMessage() );
                    }*/

                }
                break;
            }

            if(newTimeOffProj.Id != null)
            {
                newTimeOffProject = [select Id, pse__Project_Id__c from pse__Proj__c where Id =: newTimeOffProj.Id limit 1];

                List<pse__Milestone__c> milestoneToInsert  = new List<pse__Milestone__c>();

                for(pse__Milestone__c eMilestone : [ SELECT Id, Name, Milestone_Type_List__c, Task_Milestone_Name__c, Internal_Time_Only__c,Billable__c, pse__Milestone_Amount__c, Start_Date__c,pse__Start_Date__c, pse__Target_Date__c, pse__Status__c, RecordtypeId, pse__Project__c FROM pse__Milestone__c WHERE pse__Project__c =: timeOffProj ])
                {
                    pse__Milestone__c newMilestone = new pse__Milestone__c();    
                    newMilestone.Milestone_Type_List__c     = eMilestone.Milestone_Type_List__c;
                    newMilestone.Task_Milestone_Name__c     = eMilestone.Task_Milestone_Name__c;
                    newMilestone.Internal_Time_Only__c      = eMilestone.Internal_Time_Only__c;
                    newMilestone.pse__Milestone_Amount__c   = eMilestone.pse__Milestone_Amount__c;
                    newMilestone.Start_Date__c              = Date.newInstance((Date.today().year()+1), 01, 01);
                    newMilestone.pse__Start_Date__c         = Date.newInstance((Date.today().year()+1), 01, 01);
                    newMilestone.pse__Target_Date__c        = Date.newInstance((Date.today().year()+1), 12, 31);
                    newMilestone.pse__Status__c             = eMilestone.pse__Status__c;
                    newMilestone.RecordtypeId               = eMilestone.RecordtypeId;
                    newMilestone.pse__Project__c            = newTimeOffProject.Id;
                    newMilestone.Billable__c                = eMilestone.Billable__c;

                    milestoneToInsert.add(newMilestone);

                }

                insert milestoneToInsert;

                for(pse__proj__c eProj : timeOffProj)
                {
                    eProj.pse__stage__c                     = 'Closed';
                    eProj.Close_Code__c                     = 'Complete';
                    eProj.pse__Is_Active__c                 = false;
                    eProj.pse__Closed_for_Time_Entry__c     = true;
                    eProj.Basic_Implementation_Complete__c  = eProj.pse__End_Date__c;
                    eProj.Customer_Acceptance_Requested__c  = eProj.pse__End_Date__c;
                    eProj.pse__Project_Status_Notes__c      = 'New Time - Off Project for ' + (Date.today().year()+1) + ' is ' + newTimeOffProject.pse__Project_Id__c;
                    eProj.PSA_Ignore_Saved_Timecards__c     = true;

                    break;
                }

                update timeOffProj;
                /*try
                {

                }
                catch(Exception e)
                {
                    System.debug('Exception while closing time-off Project :: ' + e.getMessage());
                    PSA_AutoCreateProjectUtil.sendErrorMails('Error: Exception while closing time-off Project and Creation of new Time Off Project is Stopped(Class:PSA_AutoCreateTimeOffProjectYOY), ', (System.Url.getSalesforceBaseURL().toExternalForm()) +'\n' +e.getMessage() );
                }*/
            }

        }

    }

    public void finish( Database.BatchableContext BC )
    {
        System.debug('in finish');
        if(newTimeOffProj != null)
        {
            PSA_Settings__c EnggEmail = PSA_Settings__c.getInstance('Engineering Team Email');
            String emailAddress = EnggEmail != null ?EnggEmail.Value__c : 'services-engg@akamai.com';

            Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
            String subject ='Year End Auto Time-Off Projects';
            email.setSubject(subject);
            email.setToAddresses( new List<String>{emailAddress});
            email.setPlainTextBody('Time-Off Projects for year ' + (Date.today().year()+1)+ ' are created and the current year Time-Off Project is closed');
            Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
            System.debug('email sent: ' + r);
        }
        else
        {
            System.debug('No Time-Off Projects to be created for year :'+ Date.today().year()+ 1);
            PSA_AutoCreateProjectUtil.sendErrorMails('No Time-Off Projects to be created for year :  ' + Date.today().year()+ 1, (System.Url.getSalesforceBaseURL().toExternalForm()) +'\n' );
        }
    }

}