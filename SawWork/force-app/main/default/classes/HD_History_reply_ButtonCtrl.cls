/* Coder@ Hemant Barapatre
* Used as a part of HD_History_reply_Button Component
* 
*/

public class HD_History_reply_ButtonCtrl 
{
    @AuraEnabled
    public String ORG_WIDE_EMAIL{get;set;}
     
     
    @AuraEnabled 
    public BMCServiceDesk__IncidentHistory__c  action_History{get;set;}  
    
    @AuraEnabled
    public static BMCServiceDesk__IncidentHistory__c getActionHistory(Id actionId)
    {
        BMCServiceDesk__IncidentHistory__c INCHIST = [Select Id, name, BMCServiceDesk__Client_User__r.Email, BMCServiceDesk__EmailConversationData__c,BMCServiceDesk__description__c, BMCServiceDesk__RichTextNote__c,BMCServiceDesk__note__c from BMCServiceDesk__IncidentHistory__c WHERE Id =:actionId LIMIT 1 ];
        return  INCHIST;
    }
    
    @AuraEnabled
    public static HD_History_reply_ButtonCtrl classObject(Id actionId)
    {  
        HD_History_reply_ButtonCtrl obj = new HD_History_reply_ButtonCtrl();
        obj.action_History = [Select Id, name, BMCServiceDesk__Client_User__r.Email, BMCServiceDesk__EmailConversationData__c,BMCServiceDesk__description__c, BMCServiceDesk__RichTextNote__c,BMCServiceDesk__note__c from BMCServiceDesk__IncidentHistory__c WHERE Id =:actionId LIMIT 1 ];
        OrgWideEmailAddress[] owea = [select Id,Address,DisplayName from OrgWideEmailAddress where DisplayName = 'Akamai Ticketing' LIMIT 1];
        obj.ORG_WIDE_EMAIL = owea.get(0).Address;
        
      return obj;
    }
    
}