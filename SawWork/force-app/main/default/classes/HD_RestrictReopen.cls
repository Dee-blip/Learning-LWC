/*
Template: Apex Class/Trigger Template

CopyRight: Bhaskar Verma @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : used as apart of requirement for remedyforce incidents reopen management

Purpose : an implementation for trigger HD_RemedyForceCustomizations.trigger
          
Usage : used as an implementation for the business logic , for trigger HD_RemedyForceCustomizations.trigger
          
Test Class Associated : NONE

Controller (Boolean): False

Page Used/Associated (default -> NONE) : NONE

Trigger Associated : HD_RemedyForceCustomizations.trigger
              
*/
/*
Code Statistics :  0 soql Query Used
CPU usage from test class : 100-200 cpu utilization based on batch size

*/

/*
    This class checks for active state of the owner when a ticket is reopened.
    if the owner is found to be inactive, the ticket would be assigned to the previous queue.
*/
public class HD_RestrictReopen{
    static HD_RestrictReopen instance = null;
    public List<BMCServiceDesk__Incident__c> newTrigger = new List<BMCServiceDesk__Incident__c>();
    public List<BMCServiceDesk__Incident__c>  oldTrigger = new List<BMCServiceDesk__Incident__c>();
    public Boolean noteAdded = false;
    Map<String,Group> groupNameMap = new Map<String,Group>();
    Map<id,user> activeUsersMap = new Map<id,user>();
    

    /*
        The private constructor populating old trigger, new trigger, users map and group name map.
    */
    private HD_RestrictReopen(List<BMCServiceDesk__Incident__c>  oldVersionObj, List<BMCServiceDesk__Incident__c> newVersionObj, Map<String,Group> pGroupNameMap, Map<id,user> pVpUserMap){
       System.debug('Reopen - constructor invoked.');
       oldTrigger.addAll(oldVersionObj);
       newTrigger.addAll(newVersionObj);
       groupNameMap= pGroupNameMap;
       activeUsersMap = pVpUserMap;
       
    }
   
   /*
        The singleton method for supplying the only instance of this class.
   */
    public static HD_RestrictReopen getInstance(List<BMCServiceDesk__Incident__c> oldTrigger, List<BMCServiceDesk__Incident__c> newTrigger, Map<String,Group> pGroupNameMap, Map<id,user> pVpUserMap){
        System.debug('Reopen - singleton getInstance called');
        if(instance == null){
            instance = new HD_RestrictReopen(oldTrigger,newTrigger,pGroupNameMap,pVpUserMap);
        }
        return instance;
    }
    
    /*
        This method contains the core logic of checking a user's state and reassigning the ticket to the queue.
    */
    public void beforeUpdateChanges(){
        System.debug('Reopen - before update code enters');
        String recordTypeIdSI = Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Service Incident').getRecordTypeId();
        //Reading the value of custom setting HD DataLoad for fetching the triage team id.
        HD_DataLoad__c triageTeam = HD_DataLoad__c.getValues('Triage_Team');
        String triageTeamID = null;
        if(triageTeam != null){
            triageTeamID = triageTeam.TextValue__c;
        }
        System.debug('Reopen - Triage Team ID read from custom setting is '+triageTeamID);
        Integer recordSize = newTrigger.size();
        System.debug('Reopen - Record Size is '+recordSize);
        Integer currentIndex = 0;
        while(currentIndex < recordSize)
        {
            BMCServiceDesk__Incident__c insobj = newTrigger[currentIndex];
            BMCServiceDesk__Incident__c oldIncObject = oldTrigger[currentIndex];
            //pranav
            //CR 3395561 - Cancelling to be enabled for end users and staff users and mandatroy to enter the note for the reason
            //added logic for status: cancelled status alongside status:closed
            if(insobj.RecordTypeId != recordTypeIdSI && ((oldIncObject.BMCServiceDesk__Status_ID__c == 'CLOSED' && insobj.BMCServiceDesk__Status_ID__c != 'CLOSED')||(oldIncObject.BMCServiceDesk__Status_ID__c == 'CANCELED' && insobj.BMCServiceDesk__Status_ID__c != 'CANCELED')))
            {
                System.debug('Reopen - Reopen condtion matched.');
                insobj.Effort_Estimation__c=null;
                Id ownerId = insobj.ownerId;
                System.debug('Reopen - ownerId is.'+ownerId);
                if(activeUsersMap.get(ownerId)==null)
                {
                    System.debug('Reopen - User found inactive.');
                    insobj.HD_OwnerLocked__c = false;
                    insobj.ownerId = triageTeamID;
                    String lastQueueName = insObj.BMCServiceDesk__queueName__c;
                    if(lastQueueName != null)
                    {
                        String lastQueueId = groupNameMap.get(lastQueueName).id;
                        insobj.ownerId = lastQueueId;
                        System.debug('Reopen - updating owner as'+ lastQueueName);
                    }//if(lastQueueName != null)
                }//if(vpUserMap.get(ownerId)==null)
            }
            
            if(insobj.RecordTypeId != recordTypeIdSI && oldIncObject.BMCServiceDesk__Status_ID__c == 'RESOLVED' && insobj.BMCServiceDesk__Status_ID__c == 'REOPENED')
            {              
                insobj.Effort_Estimation__c=null;
                Id ownerId = insobj.ownerId;                
                insobj.Last_Owner__c = ownerId;
                String lastQueueName = insObj.BMCServiceDesk__queueName__c;
                if(lastQueueName != null)
                    {                         
                        insobj.HD_OwnerLocked__c  = false;
                        String lastQueueId = groupNameMap.get(lastQueueName).id;
                        insobj.ownerId = lastQueueId;
                    }
            }
            
            currentIndex++;
        }
    }

    
    public void afterUpdateChanges()
    {
        List<BMCServiceDesk__Action__c> actionList = new List<BMCServiceDesk__Action__c>();
        actionList = [select Id from BMCServiceDesk__Action__c where BMCServiceDesk__Abbreviation__c = 'ESCALATION_NOTE'];
        if(!noteAdded){
        String recordTypeIdSI = Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Service Incident').getRecordTypeId();
        Integer recordSize = newTrigger.size();
        System.debug('Reopen - Record Size is '+recordSize);
        Integer currentIndex = 0;
        List<BMCServiceDesk__IncidentHistory__c> noteList = new List<BMCServiceDesk__IncidentHistory__c>();
        while(currentIndex < recordSize)
        {
            BMCServiceDesk__Incident__c insobj = newTrigger[currentIndex];
            System.debug('printing parent tree');
            
            BMCServiceDesk__Incident__c oldIncObject = oldTrigger[currentIndex];
            Boolean validIncidnet;
            Boolean ResolvedToReopenCase = (oldIncObject.BMCServiceDesk__Status_ID__c == 'RESOLVED' && insobj.BMCServiceDesk__Status_ID__c == 'REOPENED');
            //pranav
            //CR 3395561 - Cancelling to be enabled for end users and staff users and mandatroy to enter the note for the reason
            //added logic for status: cancelled status alongside status:closed
            if(insobj.RecordTypeId != recordTypeIdSI 
               && ((oldIncObject.BMCServiceDesk__Status_ID__c == 'CLOSED' && insobj.BMCServiceDesk__Status_ID__c != 'CLOSED')
                   ||(oldIncObject.BMCServiceDesk__Status_ID__c == 'CANCELED' && insobj.BMCServiceDesk__Status_ID__c != 'CANCELED')
                  || ResolvedToReopenCase ))
            {
                System.debug('old status: '+oldIncObject.BMCServiceDesk__Status_ID__c);
                System.debug('new status: '+insobj.BMCServiceDesk__Status_ID__c);
                try{
                    HD_Incident_Settings__c x = HD_Incident_Settings__c.getInstance('CORPORATE_EIS_PARENT_TREE');
                    List<String> ptrees  = x.value__c.split(',');
                    validIncidnet = false;
                    for(String ptree : ptrees){
                        //Boolean b = s.containsIgnoreCase('HE');
                        validIncidnet = insobj.HD_Parent_Tree__c.containsIgnoreCase(ptree.trim());
                        if(validIncidnet){
                            break;
                        }
                    }
                    if(validIncidnet && ((String.valueof(insobj.ownerId).substring(0,3)) =='005' || ResolvedToReopenCase) ){
                        System.debug('Reopen - Reopen condtion matched.');
                        Id ownerId = insobj.ownerId;
                        System.debug('Reopen - ownerId is.'+ownerId);
                        //Add a transfer note after reopening a ticket and clear the value in effort estimation
                        BMCServiceDesk__IncidentHistory__c currentNote = new BMCServiceDesk__IncidentHistory__c();
                        currentNote.BMCServiceDesk__FKIncident__c=oldIncObject.Id;
            //            Schema.DescribeSObjectResult userObject = User.SObjectType.getDescribe(); // To get prefix of the User object.    
                        //String prefix1 = userObject.getKeyPrefix();
                        currentNote.BMCServiceDesk__FKUser__c=ownerId;
                        if(ResolvedToReopenCase)
                            currentNote.BMCServiceDesk__FKUser__c=oldIncObject.ownerId;
                        
                        currentNote.BMCServiceDesk__duration__c=oldIncObject.Effort_Estimation__c;
                        currentNote.BMCServiceDesk__description__c='Transfer Note';
                        currentNote.BMCServiceDesk__note__c='System generated transfer note for reopened ticket.';
                        
                        if(actionList!=null){
                            
                            currentNote.BMCServiceDesk__FKAction__c=actionList[0].Id;
                            currentNote.HD_Action__c='ESCALATION_NOTE';
                            noteList.add(currentNote);
                       
                        }
                    }

                }catch(Exception e){
                    System.debug(e);    
                }
 
            }//if(oldIncObject.BMCServiceDesk__Status_ID__c == 'CLOSED')
            currentIndex++;
        }
        System.debug('node list size: '+ noteList.size());
        if(noteList.size()>0){
            HD_RestrictedAccess.SKIP_TRIGGER = true;
           try{
                insert noteList;
            }catch(Exception e){
                System.debug('error occured while inserting transfer note');
            }
           
            noteAdded = true;
            HD_RestrictedAccess.SKIP_TRIGGER = false;
        }
    }
    }// 
}