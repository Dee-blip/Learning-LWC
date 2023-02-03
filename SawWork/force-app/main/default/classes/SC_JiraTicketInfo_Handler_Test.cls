/* 
/***************************************************************************
 * Name             : SC_JiraTicketInfo_Handler_Test
 * Created By       : Sharath Prasanna
 * Created Date     : 25 Nov 2020
 * Purpose          : Code Coverage for below Components:
 						1. SC_JiraTicketInfo_Handler - Apex Class
                        2. SC_JiraTicketInfo_Trigger - Apex Trigger
 Last Modified BY   Last Modified Date  Purpose
 ----------------   ------------------  ---------
 
 *****************************************************************************/ 


@isTest(SeeAllData=false)
public class SC_JiraTicketInfo_Handler_Test 
{
    public static Case newCasetech;
    public static Engagement_Request__c newEscalation;

    public SC_JiraTicketInfo_Handler_Test() 
    {

    }
    static
    {
        createTestData();
    }
    Public static void createTestData()
    {
        utilTestClass.createCustomSettings();
        
        newCasetech = new Case();
        newCasetech.Subject = 'TestCasetechnical';
        newCasetech.Description = 'TestDescription';
        newCasetech.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        newCasetech.validation_override__c = true;
        newCasetech.origin='Email';
        newCasetech.recent_update__c=true;
        
        Insert newCasetech;

    
        newEscalation = new Engagement_Request__c();
        newEscalation.ID__c = 'FFPSA-1234';
        newEscalation.System__c = 'JIRA';
        newEscalation.Case__c = newCasetech.Id;
        newEscalation.RecordTypeId = Schema.SObjectType.Engagement_Request__c.getRecordTypeInfosByName().get('AMG Escalation').getRecordTypeId();
        insert newEscalation;            

    }

    @isTest static void testJiraHandler()
    {
        test.startTest();
            SC_JiraTicketInfo_Handler handler = new SC_JiraTicketInfo_Handler();
            handler.beforeDeleteBeforeUndeleteTrigger();
            handler.afterDeleteAfterUndeleteTrigger();

            List<SC_Jira_Ticket_Info__c> jiras = new List<SC_Jira_Ticket_Info__c>();
            SC_Jira_Ticket_Info__c jiraRec = new SC_Jira_Ticket_Info__c();
            SC_Jira_Ticket_Info__c jiraRec2 = new SC_Jira_Ticket_Info__c();
            jiraRec2.Name = 'FFPSA-1234';
            jiras.add(jiraRec2);

            jiraRec = new SC_Jira_Ticket_Info__c();
            jiraRec.Name = 'FFPSA-1299';
            jiras.add(jiraRec);

            jiraRec = new SC_Jira_Ticket_Info__c();
            jiraRec.Name = 'FFPSA-1299';
            jiras.add(jiraRec);

            List<Database.SaveResult> saveResults = database.insert(jiras,false);
            Map<String,String> parameters = new Map<String,String>();
            parameters.put('Caption','test');
            parameters.put('emailBody','test');
            parameters.put('recepients','test');
            parameters.put('subject','test');

            SC_JiraTicketInfo_Handler.PopulateErrorTableForUpdate(saveResults,jiras,true,parameters);

            SC_JiraTicketInfo_Handler.getJiraRecords(new Set<String> {'FFPSA-1299','ESESP-1234'});
            SC_JiraTicketInfo_Handler.getJiraRecordsFuture(new Set<String> {'FFPSA-1299','ESESP-1234'});

            jiras.clear();
            jiraRec2.Status__c = 'test';
            jiras.add(jiraRec2);

            jiraRec = new SC_Jira_Ticket_Info__c();
            jiraRec.Name = 'FFPSA-1299';
            jiras.add(jiraRec);
            
            List<Database.UpsertResult> results = Database.Upsert(jiras,false);
            SC_JiraTicketInfo_Handler.PopulateErrorTableForUpsert(results,true,parameters);            

        test.stopTest();
    }
}