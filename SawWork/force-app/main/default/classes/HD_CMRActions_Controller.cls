public class HD_CMRActions_Controller {
    private static Map<String,BMCServiceDesk__Status__c> statusListMap = new Map<String,BMCServiceDesk__Status__c>() ;
    static{
        for(BMCServiceDesk__Status__c status: [select Id,Name from BMCServiceDesk__Status__c limit 1000]){
            statusListMap.put(status.Name,status);
        }
    }
    
    @AuraEnabled
    public static String cloneCMR(String currentCMRId){
        
        String query='SELECT ID,Name ';
        List<String> cmrFields=new List<String>();
        List<Schema.FieldSetMember> filesset1 = SObjectType.BMCServiceDesk__Change_Request__c.FieldSets.HD_CMR_CloneFields.getFields();
        for (Schema.FieldSetMember fsm : filesset1) {
            cmrFields.add((String) fsm.getFieldPath());
            query=query+', '+String.escapeSingleQuotes(fsm.getFieldPath()); //cs-fix PRTORES-1581 shegade
        }

        query=query+' from BMCServiceDesk__Change_Request__c where Id=:currentCMRId LIMIT 1';
        BMCServiceDesk__Change_Request__c currentCMR=Database.query(query);


        BMCServiceDesk__Change_Request__c newCMR = new BMCServiceDesk__Change_Request__c();
        
        
        
        
        for(String cloneField:cmrFields){
            String field=cloneField;
            newCMR.put(field,currentCMR.get(field));
        }

        newCMR.Service_Element_Impact_duration__c='01:01';
        
        insert newCMR;
        
        String newCMRId = newCMR.Id;
        return newCMRId;
    }
    
    
    
    /*
*@author: Nikhil Karn
*@CreatedDate:
*@MethodDetails:
*/
    @AuraEnabled
    public static BMCServiceDesk__Change_Request__c submitForApproval(ID cmrId, String comment){
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments(comment);
        req1.setObjectId(cmrId);
        req1.setSubmitterId(UserInfo.getUserId());
        
        Approval.ProcessResult result =  Approval.process(req1);
        if(result.isSuccess())
        {
            return HD_CMR_ChangeCalendar.getCMR(cmrId);
        }else {
            return null;
        }
    }
    
    
    @AuraEnabled
    public static Map<String,Object> getFieldValues(BMCServiceDesk__Change_Request__c currentCMR){
        Map<String,Object> fieldValueMap = new Map<String,Object>();
        String fieldsList='Id';
        List<String> cmrFields=new List<String>();
        //cmrFields.add('Id');
        List<Schema.FieldSetMember> filesset1 = SObjectType.BMCServiceDesk__Change_Request__c.FieldSets.HD_CMR_CloneFields.getFields();
        for (Schema.FieldSetMember fsm : filesset1) {
            fieldsList=fieldsList+','+(String) fsm.getFieldPath();
            cmrFields.add((String) fsm.getFieldPath());
        }
        Id currentCMRId = currentCMR.Id;
        String q = 'Select '+fieldsList+' from BMCServiceDesk__Change_Request__c where Id=:currentCMRId';
        sObject currentChangeRequest = Database.query(q)[0];
        for(String cloneField:cmrFields){
            String field=cloneField;
            fieldValueMap.put(field,currentChangeRequest.get(field));
        }
        return fieldValueMap;
    }
    
    @AuraEnabled
    public static BMCServiceDesk__Change_Request__c getPIR(BMCServiceDesk__Change_Request__c currentCMR){
        BMCServiceDesk__Change_Request__c changeRequest = [Select Id,Post_Implementation_RollUp__c,BMCServiceDesk__FKStatus__c  from BMCServiceDesk__Change_Request__c where Id=:currentCMR.Id][0];
        return changeRequest;
    }
    
    @AuraEnabled
    public static BMCServiceDesk__Change_Request__c changeCMRStatus(BMCServiceDesk__Change_Request__c currentCMR,String status){
        currentCMR.BMCServiceDesk__FKStatus__c = statusListMap.get(status).Id;
        currentCMR.HD_Change_Status__c=status;
        update currentCMR;
        
        return currentCMR;
    }
    
    @AuraEnabled
    public static BMCServiceDesk__Change_Request__c  createPIR(BMCServiceDesk__Change_Request__c changeRequest, String changeDeliveredResults, String serviceImpactDetails, String changeImplementedAsPlanned, String implementationWinDetails, String additionalLessons, String statusVal){
        Change_Review__c newPIR = new Change_Review__c();
        newPIR.Change_Request__c  = changeRequest.Id;
        newPIR.required_results_delivered__c  = changeDeliveredResults;
        newPIR.Additional_lessons_learnt__c = additionalLessons;
        newPIR.Details_of_implementation_window_varied__c = implementationWinDetails;
        newPIR.Unaccounted_Impact_On_Services__c  = serviceImpactDetails;
        newPIR.Was_the_change_implemented_as_planned__c  = changeImplementedAsPlanned;
        insert newPIR;
        changeCMRStatus(changeRequest,statusVal);


        
        return HD_CMR_ChangeCalendar.getCMR(changeRequest.Id);
    }
    
    @AuraEnabled
    public static void recallForApproval(ID cmrId, String comment){
        ProcessInstanceWorkitem[] workItems = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :cmrId 
                                               AND ProcessInstance.Status = 'Pending'];
        if(workItems.size() == 0){
            throw new AuraHandledException('No Approvals to Recall');
        }
        try{
            Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
            pwr.setAction('Removed');
            pwr.setWorkItemId(workItems[0].id);
            Approval.ProcessResult result = Approval.process(pwr);
        }catch(Exception e){
            throw new AuraHandledException('Only Submitters can Recall Approvals');
        }
        
    }
    
}