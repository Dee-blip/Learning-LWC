/*
 	Modification Log ===============================================================
    Line Number     Date    Author  Modification
    Line 13    July 20th, 2020     Arihant Jain    PRTORES-1809 - HD Code scan 2020 - Blockers, Criticals Part 3
*/

public class HD_ActionMenu_Provider 
{
    
    @AuraEnabled 
    public static List<HD_Client_detail_lightning__mdt> getClientDetailLightningMenu()
    {
        return [select id,Label,Available_for_EIS_Team__c,Available_for_Status__c,Display_in_Action_Component__c,Dont_show_for_incident_type__c,Available_for_Category_Types__c from HD_Client_detail_lightning__mdt ORDER BY ID ASC limit 500];
    }//
    
    @AuraEnabled
    public static BMCServiceDesk__Incident__c getIncident(String id) {
        
        
        BMCServiceDesk__Incident__c incident = [ SELECT Id,Name,BMCServiceDesk__Category_ID__c,BMCServiceDesk__Status_ID__c,HD_Parent_Tree__c,HD_IncidentGroup__c,HD_Ticket_Priority__c,BMCServiceDesk__Type__c FROM BMCServiceDesk__Incident__c
                                                WHERE Id = :id][0];
        
        // Perform isAccessible() check here 
        return incident;
    }//
    
    //This method will provide the indepth analysis on the record accessisbility via simple call
    @AuraEnabled(cacheable=true)
    public static boolean isAccessibleRecord( Id recordID ){
        Id currentuserId = UserInfo.getUserId();
        boolean accessFlag = false;   
        UserRecordAccess ura = [SELECT RecordId, HasReadAccess, HasEditAccess FROM UserRecordAccess WHERE UserId =: currentuserId AND RecordId =: recordID][0];   
        if(ura.HasEditAccess == true)
        {
            accessFlag = true;
        }        
        return accessFlag;
        
    }//
    
    //the method is used to check the weather the record is locked or not while approval
    @AuraEnabled
    public static boolean approvalRecordStatus(Id TargetRecordID)
    { 
        List<ProcessInstance> ProcessInstanceList = new  List<ProcessInstance>();
        ProcessInstanceList = [ SELECT Id, TargetObjectId FROM ProcessInstance WHERE TargetObjectId =: TargetRecordID and STATUS = 'Pending' LIMIT 1]; 
        if(ProcessInstanceList.size() > 0)
        {
            return true;
        }
        return false;
    }//public static boolean recordStatus(Id TargetRecordID)
    
    
    
}//END