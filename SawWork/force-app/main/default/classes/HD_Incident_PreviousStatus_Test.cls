/*
* File Name: HD_Incident_PreviousStatus_Test
* Description : Test class for 'HD_Incident_PreviousStatus'
* @author : 
* Modification Log ===============================================================
* Date 				Author 				Modification
* Apr 16th, 2021    Aneesh Budnar       PRTORES-2086 - Tickets not getting closed after approval
* Jun 06th, 2021    Aneesh Budnar       PRTORES-2178 - EAE OPS Peer Review
* Sep 24th, 2021    Amogh MP			PRTORES-2286 - HD Use approval process name to identify the transition
*/
@IsTest
public class HD_Incident_PreviousStatus_Test {
    static {
        HD_Test_Data_Factory.init();
    }
    
	@isTest
    public static void whenIncidentPreviousStatusIsInvokedExpectStatusReturned() {
        BMCServiceDesk__Incident__c testIncident = new IncidentTestHelper.IncidentBuilder()
            .withCategory(HD_Test_Data_Factory.categoryMap.get('Compensation'))
            .withRecordTypeId(Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Helpdesk').getRecordTypeId())
            .buildAndSave();
        HD_Incident_PreviousStatus.testData = new List<BMCServiceDesk__Incident__History>{
                new BMCServiceDesk__Incident__History(Field = 'BMCServiceDesk__FKStatus__c', ParentId = testIncident.Id),
                new BMCServiceDesk__Incident__History(Field='Owner', ParentId = testIncident.Id),
                new BMCServiceDesk__Incident__History(Field='BMCServiceDesk__dueDateTime__c', ParentId = testIncident.Id),
                new BMCServiceDesk__Incident__History(Field='BMCServiceDesk__FKStatus__c', ParentId = testIncident.Id),
                new BMCServiceDesk__Incident__History(Field='BMCServiceDesk__FKUrgency__c', ParentId = testIncident.Id),
                new BMCServiceDesk__Incident__History(Field='BMCServiceDesk__FKPriority__c', ParentId = testIncident.Id),
                new BMCServiceDesk__Incident__History(Field='HD_IncidentGroup__c', ParentId = testIncident.Id),
                new BMCServiceDesk__Incident__History(Field='BMCServiceDesk__Service_Request_Title__c', ParentId = testIncident.Id),
                new BMCServiceDesk__Incident__History(Field='BMCServiceDesk__FKImpact__c', ParentId = testIncident.Id)};
        List<String> previousStatus = HD_Incident_PreviousStatus.getIncidentStatusBeforeApproval(new List<String>{testIncident.Id});
        System.assertEquals('IN PROGRESS', previousStatus[0], 'Expected value not same as actual value');
    }
    
	@isTest
    public static void whenIncidentPreviousStatusIsInvokedwithSRTitleExpectInProgressStatusReturned() {
        BMCServiceDesk__Incident__c testIncident = new IncidentTestHelper.IncidentBuilder()
            .withCategory(HD_Test_Data_Factory.categoryMap.get('Compensation'))
            .withSRTitle('Engineering VM - New')
            .withRecordTypeId(Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Helpdesk').getRecordTypeId())
            .buildAndSave();
        HD_Incident_PreviousStatus.testData = new List<BMCServiceDesk__Incident__History>{
                new BMCServiceDesk__Incident__History(Field = 'BMCServiceDesk__FKStatus__c', ParentId = testIncident.Id),
                new BMCServiceDesk__Incident__History(Field='Owner', ParentId = testIncident.Id),
                new BMCServiceDesk__Incident__History(Field='BMCServiceDesk__dueDateTime__c', ParentId = testIncident.Id),
                new BMCServiceDesk__Incident__History(Field='BMCServiceDesk__FKStatus__c', ParentId = testIncident.Id),
                new BMCServiceDesk__Incident__History(Field='BMCServiceDesk__FKUrgency__c', ParentId = testIncident.Id),
                new BMCServiceDesk__Incident__History(Field='BMCServiceDesk__FKPriority__c', ParentId = testIncident.Id),
                new BMCServiceDesk__Incident__History(Field='HD_IncidentGroup__c', ParentId = testIncident.Id),
                new BMCServiceDesk__Incident__History(Field='BMCServiceDesk__Service_Request_Title__c', ParentId = testIncident.Id),
                new BMCServiceDesk__Incident__History(Field='BMCServiceDesk__FKImpact__c', ParentId = testIncident.Id)};
        List<String> previousStatus = HD_Incident_PreviousStatus.getIncidentStatusBeforeApproval(new List<String>{testIncident.Id});
        System.assertEquals('IN PROGRESS', previousStatus[0], 'Expected value not same as actual value');
    }
    
	@isTest
    public static void whenIncidentPreviousStatusIsInvokedwithIncGroupExpectCloseStatusReturned() {
        BMCServiceDesk__Incident__c testIncident = new IncidentTestHelper.IncidentBuilder()
            .withCategory(HD_Test_Data_Factory.categoryMap.get('Access'))
            .withIncidentGroup('Q_EAE_OPS')
            .withRecordTypeId(Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Helpdesk').getRecordTypeId())
            .withClient(System.userInfo.getUserId()).withVIPStatus(false)
            .withDescription('close after approval')
            .withResolution('Approved closing it')
            .withEffort('00:10')
            .withSupportType('L1')
            .buildAndSave();
        HD_Incident_PreviousStatus.testData = new List<BMCServiceDesk__Incident__History>{
                new BMCServiceDesk__Incident__History(Field = 'BMCServiceDesk__FKStatus__c', ParentId = testIncident.Id),
                new BMCServiceDesk__Incident__History(Field='Owner', ParentId = testIncident.Id),
                new BMCServiceDesk__Incident__History(Field='BMCServiceDesk__dueDateTime__c', ParentId = testIncident.Id),
                new BMCServiceDesk__Incident__History(Field='BMCServiceDesk__FKStatus__c', ParentId = testIncident.Id),
                new BMCServiceDesk__Incident__History(Field='BMCServiceDesk__FKUrgency__c', ParentId = testIncident.Id),
                new BMCServiceDesk__Incident__History(Field='BMCServiceDesk__FKPriority__c', ParentId = testIncident.Id),
                new BMCServiceDesk__Incident__History(Field='HD_IncidentGroup__c', ParentId = testIncident.Id),
                new BMCServiceDesk__Incident__History(Field='BMCServiceDesk__Service_Request_Title__c', ParentId = testIncident.Id),
                new BMCServiceDesk__Incident__History(Field='BMCServiceDesk__FKImpact__c', ParentId = testIncident.Id)};
                    
        Approval.ProcessSubmitRequest psr = new Approval.ProcessSubmitRequest();
        psr.setObjectId(testIncident.Id);
        psr.setProcessDefinitionNameOrId('peer_review');
        psr.setSkipEntryCriteria(true);
        
        Approval.ProcessResult result = Approval.process(psr);
        Approval.ProcessResult resultPWR;

        if(result.isSuccess()) {
            List<Id> workItem = result.getNewWorkItemIds();
            
            Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
        	pwr.setAction('Approve');
        	pwr.setWorkItemId(workItem.get(0));

            resultPWR = Approval.process(pwr);
        }
           
        if(resultPWR.isSuccess()) {
        	List<String> previousStatus = HD_Incident_PreviousStatus.getIncidentStatusBeforeApproval(new List<String>{testIncident.Id});
        	System.assertEquals('CLOSED', previousStatus[0], 'Expected value not same as actual value');
        }
    }
}