/***************************************************************************
 * Name             : ACD2_SetupAutomation
 * Created By       : Sharath
 * Created Date     : 17-May-2021
 * Purpose          : Util Class for all ACD Webservices
 * Test Class		: ACD2_Webservices_Test
 
 Last Modified BY   		Last Modified Date  Purpose
 ----------------   		------------------  ---------
 Sharath                        17 May 2021        ACD user automation
 ****************************************************************************/
public without sharing class ACD2_SetupAutomation 
{
    @InvocableMethod
    public static void setupUserForACD(List<String> idsToCreate)
    {
        if(idsToCreate != null && idsToCreate.size() > 0)
        {
            String userId = idsToCreate.get(0);
            String result = ACD2_UtilClass.callNonSetupFlow(userId);
            if(!result.containsIgnoreCase('success'))
            {
                createIncidentRecord(userId);
            }
            else
            {
            	ACD2_UtilClass.callSetupFlowFuture(userId);        
            }            
        }
    }

    public static void createIncidentRecord(String clientId)
    {
        String categoryId;
        BMCServiceDesk__Urgency__c urg = [Select Id from BMCServiceDesk__Urgency__c where Name = 'Severity 2' Limit 1];
        BMCServiceDesk__Impact__c impact = [Select Id from BMCServiceDesk__Impact__c where Name = 'LOW' Limit 1];
        List<BMCServiceDesk__Category__c> categories = [Select id,Name from BMCServiceDesk__Category__c where name ='Salesforce Phone Widget (ACD) Issue'];
        if(categories != null && categories.size() ==1)
        {
            categoryId = categories.get(0).id;
            BMCServiceDesk__Incident__c inc1 = new BMCServiceDesk__Incident__c();
            inc1.BMCServiceDesk__FKUrgency__c = urg.Id;
            inc1.BMCServiceDesk__FKImpact__c = impact.Id;
            inc1.BMCServiceDesk__FKClient__c = clientId;
            inc1.BMCServiceDesk__FKCategory__c = categoryId;
            inc1.BMCServiceDesk__incidentDescription__c = 'ACD User Setup Automation failure. Please go to the user record and click on the link, ACD Setup';
            inc1.HD_Ticket_Priority__c = '2';
            inc1.RecordTypeId = Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Helpdesk').getRecordTypeId();
            insert inc1;        
            
        }
    }
}