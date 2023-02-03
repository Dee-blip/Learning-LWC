/* 
Author          : Vishnu/ Sumukh SS/Sharath P
Description     : Trigger for Community Comments

Date                    Developer             		JIRA #                      Description                                                       
------------------------------------------------------------------------------------------------------------------
25 Jan 2021				Authors				 	   ESESP-5085				  Initial Development
------------------------------------------------------------------------------------------------------------------
*/

public without sharing class CommunityCommentHandler extends ApexTriggerHandlerAbstractClass {
    static Map<String, Object> JARVIS_CASE_FILTER = new Map<String, Object> {'Application__c' => 'JARVIS', 
                                                                             'Related_Object__c' => 'Case'};
                                                                             
    public CommunityCommentHandler() 
    {
        
    }
    public override void beforeInsertBeforeUpdateTrigger()
    {
        if(Trigger.isInsert)
        {
            try {
                List<Community_Comments__c> jvComments = SC_Utility.filterSObjList(Trigger.new, JARVIS_CASE_FILTER);
                if(jvComments.size() > 0) {
                    SC_CommunityCommentTriggerHandler.getCommentedByDetails(jvComments);
                }
            } Catch(Exception ex) {
                SC_Jarvis_utility.sendErrorMails('Community Comment After Insert Trigger', ex.getStackTraceString(), null);
            }
        }
        
    }

    
    public override void afterInsertAfterUpdateTrigger()
    {
        if(Trigger.isInsert)
        {
            try {
                List<Community_Comments__c> jvComments = SC_Utility.filterSObjList(Trigger.new, JARVIS_CASE_FILTER);

                if(jvComments.size() > 0) {
                    SC_CommunityCommentTriggerHandler.provisionCommentShareAccess(jvComments);
                    SC_CommunityCommentTriggerHandler.createFeed(jvComments);           
                    SC_JARVIS_CustomerTouchpoints.sendCommCommentEmailNotifications(jvComments);
                }
            } Catch(Exception ex) {
                SC_Jarvis_utility.sendErrorMails('Community Comment After Insert Trigger', ex.getStackTraceString(), null);
            }
        }	
    }
    
    public override void beforeDeleteBeforeUndeleteTrigger()
    {
    }
    
    public override void afterDeleteAfterUndeleteTrigger()
    {
    }
    
}