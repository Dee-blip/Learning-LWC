/*******************************************************************************************************
 Name         :   Engagement_RequestTrigger
 Author       :   Vinod Kumar (Appirio Offshore)
 Created Date :   June 10,2013
 Task         :   T-150208
 Description  :   Engagement_Request__c object trigger
 
 //Update : Added some updates related to escalation requests (T-155379)
 //Update : kusharma: Added method to sync Assigned To and Owner Fields (CR: 2530038)
 //Update : VS: Added method to update Accept Target Date(CR: 3035271)
  Last Modified     Developer   Purpose            
 =============     =========   =======
 16-AUG-16       Himanshu    CR#3290361 - Redesign the ER Trigger
 29-Jan-16       Pinkesh     CR#3612751 - Post Resolution Notes when ER is closed 
 31-May-18      Vandhana    ESESP-319  - OLA Jira to SFDC integration
 24-Feb-2020     Vandhana   ESESP-2039 - AMG Lightning Migration : New Record type AMG Escalation (similar to External Team)
 20-Jul-2020     Vandhana   ESESP-3948 - Uppercase JIRA IDs on External Team Escalations
 13-oct-2020    Sharath     ESESp-3767 - Calling the jira create method
 15 Mar 2021    Vandhana    ESESP-2346 Carrier LX Migration
 15 Mar 2022    Vandhana    ESESP-4541 Modify JIRA URL logic to accommodate ENTESC requirements
*******************************************************************************************************/
trigger Engagement_RequestTrigger on Engagement_Request__c (after update, after insert, before insert, before update) 
{    
    //Changes by Sharath: List of Jira Ids
    Set<String> jiraIds = new Set<String>();
    // List of Non-Azure ERs
    List<Engagement_Request__c> lNewER = new List<Engagement_Request__c>();
    Map<Id,Engagement_Request__c> mpExtTeamER = new Map<Id,Engagement_Request__c>();
    Map<Id,Engagement_Request__c> mpExtTeamERJIRA = new Map<Id,Engagement_Request__c>();
    
    // List of Azure ERs
    List<Engagement_Request__c> lAzureEscalationRequest  = new List<Engagement_Request__c>();
    List<Engagement_Request__c> lAzureERsForEmailValidation = new List<Engagement_Request__c>();
    
    Map<String,String> sys2URLMap = new Map<String,String>();
    List<System_to_Area_Mapping__c> sys2AreaMapping = [SELECT System__c, System_URL__c 
                                                       FROM System_to_Area_Mapping__c
                                                       ORDER BY System__c
                                                      ];
    for(System_to_Area_Mapping__c eachRec : sys2AreaMapping)
    {
        sys2URLMap.put(eachRec.System__c,eachRec.System_URL__c);
    }
    
    // changes by Vandhana for ESESP-2346 Carrier LX Migration
    //String nominumJIRABase = [SELECT Value_Text__c FROM SC_Utility__mdt WHERE DeveloperName = 'Nominum_JIRA_URL_base'].Value_Text__c;
    
    Map<String,String> mapMDTDevNameVal = new Map<String,String>();
    
    // changes by Vandhana for ESESP-4541 Modify JIRA URL logic to accommodate ENTESC requirements
    for(SC_Utility__mdt eachMDTRec : [SELECT DeveloperName,Value_Text__c 
                                      FROM SC_Utility__mdt 
                                      WHERE DeveloperName IN ('Nominum_JIRA_URL_base','ENTESC_JIRA_ID_prefix','ENTESC_JIRA_URL_base')])
    {
        if(String.isNotBlank(eachMDTRec.Value_Text__c))
        {
            mapMDTDevNameVal.put(eachMDTRec.DeveloperName,eachMDTRec.Value_Text__c);
        }
    }
    
    // Loop for all ERS to differentiate Azure vs Non-Azure ERs
    for(Engagement_Request__c varER :Trigger.New)
    {
        if(varER.RecordType_Name__c != 'Escalation to Microsoft Azure'
           && varER.RecordType_Name__c != 'Escalation From Microsoft Azure')
        {
            lNewER.add(varER);
        }
        else if(varER.RecordType_Name__c == 'Escalation to Microsoft Azure' && varER.Request_Status__c == 'Open' && MSAzureHandler.varActivateMSAzureCode)
        {
            lAzureEscalationRequest.add(varER);
        }
        //Code for checking if Email Address entered is valid or not for Azure  
        //CR :3339061
        if(varER.RecordType_Name__c == 'Escalation to Microsoft Azure' && MSAzureHandler.varActivateMSAzureCode)
        {
            lAzureERsForEmailValidation.add(varER);
        }
        
        // changes by Vandhana
        if(varER.RecordType_Name__c == 'External Team' || varER.RecordType_Name__c == 'AMG Escalation')
        {
            // changes by Vandhana - capitalise JIRA ID
            if(Trigger.isBefore && varER.System__c.equalsIgnoreCase('JIRA') && String.isNotBlank(varER.ID__c))
            {
                varER.ID__c = varER.ID__c.toUpperCase();
            }
            
            //Changes by Sharath for jira sync
            //on Insert/on change of Jira Ids, create a record in the Jira Ticket object
            if(Trigger.isAfter && varER.System__c.equalsIgnoreCase('JIRA') && String.isNotBlank(varER.ID__c) && 
            (Trigger.isInsert || (Trigger.isUpdate && varER.ID__c != Trigger.oldMap.get(varER.Id).ID__c)))
            {
                jiraIds.add(varER.ID__c);   
            }  
            
            // changes by Vandhana for ESESP-2346
            // added URL changes for Nominum Jira area under JIRA System
            if(Trigger.isBefore && sys2URLMap.containsKey(varER.System__c) )
            {
                varER.URL__c = '';
                
                if(String.isNotBlank(varER.Area__c) && String.isNotBlank(varER.ID__c) 
                   && varER.Area__c.toLowerCase() == 'nominum jira' && mapMDTDevNameVal.containsKey('Nominum_JIRA_URL_base'))
                {
                    varER.URL__c = mapMDTDevNameVal.get('Nominum_JIRA_URL_base') + varER.ID__c;
                }
                // changes by Vandhana for ESESP-4541 Modify JIRA URL logic to accommodate ENTESC requirements
                else 
                    if(String.isNotBlank(varER.ID__c) && mapMDTDevNameVal.containsKey('ENTESC_JIRA_ID_prefix') && varER.ID__c.startsWith(mapMDTDevNameVal.get('ENTESC_JIRA_ID_prefix')))
                {
                    varER.URL__c = mapMDTDevNameVal.get('ENTESC_JIRA_URL_base') + varER.ID__c;
                }
                else 
                    if(String.isNotBlank(sys2URLMap.get(varER.System__c)))
                {
                    varER.URL__c = sys2URLMap.get(varER.System__c) + varER.ID__c;
                }
            }
            
            if(Trigger.isInsert && Trigger.isBefore && !varER.System__c.equalsIgnoreCase('JIRA'))
            {
                varER.Escalation_Created_Date__c = System.now();
                varER.Escalation_Created_By__c = UserInfo.getUserId();
            }
            else
            if(Trigger.isUpdate && Trigger.isBefore && !varER.System__c.equalsIgnoreCase('JIRA') && Trigger.oldMap.get(varER.Id).System__c != varER.System__c)
            {
                varER.Escalation_Created_Date__c = varER.CreatedDate;
                varER.Escalation_Created_By__c = varER.CreatedById;
                varER.Error_Message__c = '';
            }
            else
            if(Trigger.isUpdate && Trigger.isBefore && varER.System__c.equalsIgnoreCase('JIRA') && Trigger.oldMap.get(varER.Id).System__c != varER.System__c)
            {
                varER.Escalation_Created_Date__c = NULL;
                varER.Escalation_Created_By__c = NULL;
            }
            
            if((Trigger.isInsert || Trigger.isUpdate) && Trigger.isBefore && varER.RecordType_Name__c == 'AMG Escalation')
            {
                if(String.isNotBlank(sys2URLMap.get(varER.System__c)))
                {
                    varER.URL__c = sys2URLMap.get(varER.System__c) + varER.ID__c;
                }
            }
        }
        // end of changes
        
        if(Trigger.IsUpdate && Trigger.isBefore 
           && ((Trigger.oldMap.get(varER.Id).RecordTypeId == Schema.SObjectType.Engagement_Request__c.getRecordTypeInfosByName().get('External Team').getRecordTypeId() || Trigger.oldMap.get(varER.Id).RecordTypeId == Schema.SObjectType.Engagement_Request__c.getRecordTypeInfosByName().get('AMG Escalation').getRecordTypeId()))
           && varER.RecordTypeId != Trigger.oldMap.get(varER.Id).RecordTypeId)
        {
            varER.ID__c = '';
        }
    }
    //Changes by Sharath
    if(!jiraIds.isEmpty() && !(System.isFuture() || System.isScheduled() || System.isBatch()))
    {
        SC_JiraTicketInfo_Handler.getJiraRecordsFuture(jiraIds);
    }    
            
    // .............Scenario-1 : Before Insert.................
    if(Trigger.IsInsert && Trigger.IsBefore && !UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        System.debug('ENTERED before Insert');
        
        // Calling paramterised constructor for setup
        Engagement_RequestTriggerHandler erh = new Engagement_RequestTriggerHandler(lNewER);
        
        // Calling Methods
        Engagement_RequestTriggerHandler.updateTargetDate(lNewER);  
        Engagement_RequestTriggerHandler.UpdateEngagementRequestOwner(trigger.isInsert, lNewER, trigger.isInsert?null:trigger.oldMap);
        Engagement_RequestTriggerHandler.syncOwnerAndAssignedTo(trigger.isInsert, trigger.isInsert?null:trigger.oldMap, trigger.newMap, lNewER);
        Engagement_RequestTriggerHandler.SeverityUpdate(lNewER,trigger.isInsert);
        Engagement_RequestTriggerHandler.updateExtDependency(lNewER);
        
        if(!lAzureERsForEmailValidation.isEmpty()){
            MSAzureHandler azureHandler = new MSAzureHandler();      
            azureHandler.validateAdditionalEmailAddress(lAzureERsForEmailValidation);
        }
    }
    
    // .............Scenario-2 : After Insert.............
    if(Trigger.IsInsert && Trigger.IsAfter && !UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        //1: Calling Azure Method for Calculation
        if( !lAzureEscalationRequest.isEmpty() )
        {    
            MSAzureHandler azureHandler = new MSAzureHandler();   
            azureHandler.createPayloadForPostTicket(lAzureEscalationRequest);
        }
        
        // 2: Calling Methods
        Engagement_RequestTriggerHandler.CreateCaseMemberAndUpdateStatus(lNewER, trigger.oldMap, trigger.isInsert);
        Engagement_RequestTriggerHandler.onAfterInsertUpdate(lNewER, Trigger.isInsert ? null : Trigger.oldMap, Trigger.isUpdate);
    }
    
    // .............Scenario-3 : Before Update.............
    if(Trigger.IsUpdate && Trigger.IsBefore && !UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        // Calling paramterised constructor for setup
        Engagement_RequestTriggerHandler erh = new Engagement_RequestTriggerHandler(lNewER);
        
        // Calling Methods
        Engagement_RequestTriggerHandler.updateTargetDate(lNewER);  
        Engagement_RequestTriggerHandler.UpdateEngagementRequestOwner(trigger.isInsert, lNewER, trigger.isInsert ? null : trigger.oldMap);
        Engagement_RequestTriggerHandler.syncOwnerAndAssignedTo(trigger.isInsert, trigger.isInsert?null:trigger.oldMap, trigger.newMap, lNewER);
        Engagement_RequestTriggerHandler.SeverityUpdate(lNewER,trigger.isInsert);
        Engagement_RequestTriggerHandler.updateExtDependency(lNewER);
        
        if(!lAzureERsForEmailValidation.isEmpty()){
            MSAzureHandler azureHandler = new MSAzureHandler();      
            azureHandler.validateAdditionalEmailAddress(lAzureERsForEmailValidation);
        }
    }
    
    // .............Scenario-4 : After Update.............
    if(Trigger.IsUpdate && Trigger.IsAfter && !UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        // 1: Calling Methods
        Engagement_RequestTriggerHandler.CreateCaseMemberAndUpdateStatus(lNewER, trigger.oldMap, trigger.isInsert);
        Engagement_RequestTriggerHandler.onAfterInsertUpdate(lNewER, Trigger.isInsert ? null : Trigger.oldMap, Trigger.isUpdate);
        Engagement_RequestTriggerHandler.syncCaseTeamMembers(Trigger.isUpdate, trigger.oldMap, trigger.newMap, lNewER);
        
        //CR 3612751
        if(!Engagement_RequestTriggerHandler.alreadyUpdate)   
        {
            Engagement_requestTriggerHandler.PostResolutionNotes(Trigger.isUpdate, trigger.new, trigger.oldmap);
            Engagement_RequestTriggerHandler.alreadyUpdate = TRUE;
        }
    }
    
}