/*
* File Name: HD_Incident_PreviousStatus
* Description : Fetches the status of the incident before going to 'PENDING APPROVAL'. This is invoked from a flow
* @author : 
* Modification Log ===============================================================
* Date 				Author 				Modification
* Apr 16th, 2021    Aneesh Budnar       PRTORES-2086 - Tickets not getting closed after approval
* Jun 06th, 2021    Aneesh Budnar       PRTORES-2178 - EAE OPS Peer Review
* Sep 24th, 2021    Amogh MP			PRTORES-2286 - HD Use approval process name to identify the transition
*/
public without sharing class HD_Incident_PreviousStatus {
    private static Map<String, String> conditionToStatusMap = new Map<String, String>();
    private static Set<String> columns = new Set<String>();

    @TestVisible
    private static List<BMCServiceDesk__Incident__History> testData;
    
    @InvocableMethod(label='Get Incident Status Before Approval' description='Gets the status of the incident before moving to approval')
    public static List<String> getIncidentStatusBeforeApproval(List<String> incidentId) {
        String previousStatus = 'IN PROGRESS';
        try {	
        	if(!HD_Instance__mdt.SObjectType.getDescribe().isAccessible() ||
           	   !BMCServiceDesk__Incident__c.SObjectType.getDescribe().isAccessible() ||
               !BMCServiceDesk__Incident__History.SObjectType.getDescribe().isAccessible() ||
               !ProcessInstance.SObjectType.getDescribe().isAccessible()) {
               		return new List<String>{previousStatus};
        	   }
        	setExceptionConditionsFromConfig();
        	Id incId = incidentId[0];
        	BMCServiceDesk__Incident__c inc = (BMCServiceDesk__Incident__c)Database.query('SELECT Id, '+ String.join((Iterable<String>)columns, ',') + ' FROM BMCServiceDesk__Incident__c WHERE Id = :incId');
        	List<ProcessInstance> processes = [SELECT Id, Status, TargetObjectId, ProcessDefinition.DeveloperName 
                                               FROM ProcessInstance 
                                               WHERE TargetObjectId = :incId AND Status = 'Approved' ORDER BY CreatedDate DESC LIMIT 1];
            
        	// If the Incident belongs to the exception list, return the status from the metadata
			String status = getStatusIfIncidentIsException(inc, conditionToStatusMap, processes);

        	if(!String.isEmpty(status)) {
            	return new List<String>{status};
        	}
        
        	// If not an exception, the value is returned from the Incident History
        	List<BMCServiceDesk__Incident__History> incidentHistory = [SELECT Id, ParentId, Field, DataType, OldValue, NewValue 
                                                                       FROM BMCServiceDesk__Incident__History 
                                                                       WHERE ParentId = :incidentId[0] 
                                                                       AND Field = 'BMCServiceDesk__FKStatus__c' 
                                                                       AND DataType = 'Text' 
                                                                       ORDER BY CreatedDate desc];
        	if(Test.isRunningTest()) {
            	incidentHistory = testData;
        	}
        
        	for(BMCServiceDesk__Incident__History history : incidentHistory) {
            	if(history.NewValue == 'PENDING APPROVAL') {
                	previousStatus = history.OldValue.toString();
                	break;
            	}
        	}
        	return new List<String>{previousStatus};
        }
        catch(Exception e) {
            HD_UX_Exception_LoggerCls.logErrorRecord(e.getMessage(),e.getStackTraceString(),incidentId[0]);
            return new List<String>{previousStatus};
        }
    }
    
    private static void setExceptionConditionsFromConfig() {
        List<HD_Instance__mdt> approvalStatusTransitionExceptions = [SELECT Id, SettingValue__c FROM HD_Instance__mdt WHERE DeveloperName = 'Approval_Status_Transition_Exception'];
        List<String> settingsValue = approvalStatusTransitionExceptions[0].SettingValue__c.split(';');
        for(Integer setting = 0;setting < settingsValue.size();setting++) {
            List<String> entry = settingsValue[setting].split(':');
            conditionToStatusMap.put(entry[0],entry[1]);
            if(entry[0].contains('&&')) {
                List<String> conditions = entry[0].split('&&');
                for(String condition : conditions) {
                    String fieldName = condition.split('=')[0];
                    if(fieldName != 'ProcessName'){
                    	columns.add(fieldName);
                    }
                }
            }
            else {
                String fieldName = settingsValue[setting].split('=')[0];
                if(fieldName != 'ProcessName'){
                    columns.add(fieldName);
                }
            }
        }
    }
    
    private static String getStatusIfIncidentIsException(
        BMCServiceDesk__Incident__c inc, 
        Map<String, String> conditionToStatusMap, 
        List<ProcessInstance> processes) {
        for(String condition : conditionToStatusMap.keySet()) {
            Boolean isMatch = true;
            if(condition.contains('&&')) {
                List<String> conditions = condition.split('&&');
                for(String logicalCondition : conditions) {
                    String fieldName = logicalCondition.split('=')[0];
                    String fieldValue = logicalCondition.split('=')[1];
                    isMatch = isMatch && (((fieldName == 'ProcessName') ? processes[0].ProcessDefinition.DeveloperName:inc.get(fieldName)) == fieldValue);
                }
            }
            else {
                isMatch = (inc.get(condition.split('=')[0]) == condition.split('=')[1]);
            }
            if(isMatch) {
                return conditionToStatusMap.get(condition);
            }
        }
        return '';
    }
}