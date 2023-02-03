/*
 	Modification Log ===============================================================
    Line Number     Date    Author  Modification
    Line 36     July 20th, 2020     Arihant Jain    PRTORES-1809 - HD Code scan 2020 - Blockers, Criticals Part 3
*/

public without sharing class HD_ActionMenu_ProviderV2 {
    
    @AuraEnabled
    public List<HD_Client_detail_lightning__mdt> ActionManagerMenu{get;set;}
    @AuraEnabled
    public BMCServiceDesk__Incident__c incident{get;set;}
    @AuraEnabled
    public Boolean isAccessibleRecord{get;set;}    
    @AuraEnabled
    public Boolean approvalRecordStatus{get;set;}
    
    @AuraEnabled
    public static HD_ActionMenu_ProviderV2 Classobject(Id IncidentId)
    {
        HD_ActionMenu_ProviderV2 obj = new HD_ActionMenu_ProviderV2();
        //getting Action menu config
        obj.ActionManagerMenu = [select id,
                                        Label,
                                 Available_for_EIS_Team__c,//Use this field to decided what to do for EIS teams
                                 Available_for_Status__c,
                                 Display_in_Action_Component__c,//Use this field to decided what to do for other teams
                                 Dont_show_for_incident_type__c,
                                 Available_for_Category_Types__c,
                                 Component_Associated_Name__c,
                                 Action_Menu_Display_Name__c,
                                 Icon_Name__c,
                                 Order__c, 
                                 Key_Name__c,
 								 Include_Subtree__c                                  
                                 from HD_Client_detail_lightning__mdt ORDER BY Order__c ASC limit 500];
        
        //getting incident details
        obj.incident = [ SELECT Id,Name,BMCServiceDesk__Category_ID__c,HD_Parent_Category__c,BMCServiceDesk__Status_ID__c,HD_Parent_Tree__c,HD_IncidentGroup__c,HD_Ticket_Priority__c,BMCServiceDesk__Type__c FROM BMCServiceDesk__Incident__c WHERE Id = :IncidentId][0];
        
        //getting the accessibility feature
        Id currentuserId = UserInfo.getUserId();
        boolean accessFlag = false;   
        UserRecordAccess ura = [SELECT RecordId, HasReadAccess, HasEditAccess FROM UserRecordAccess WHERE UserId =: currentuserId AND RecordId =: IncidentId][0];   
        if(ura.HasEditAccess == true)
        {
            accessFlag = true;
        }        
        obj.isAccessibleRecord = accessFlag;
        
        //the code used to check the weather the record is locked or not while approval
        List<ProcessInstance> ProcessInstanceList = new  List<ProcessInstance>();
        ProcessInstanceList = [ SELECT Id, TargetObjectId FROM ProcessInstance WHERE TargetObjectId =: IncidentId and STATUS = 'Pending' LIMIT 1]; 
        if(ProcessInstanceList.size() > 0)
        {
            obj.approvalRecordStatus =  true;
        }
        else
        {   
        obj.approvalRecordStatus =  false; 
        }
        
        return obj;
    }

}