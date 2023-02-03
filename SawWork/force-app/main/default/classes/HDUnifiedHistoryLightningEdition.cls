/*
Template: Apex Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date :

Base Line : Used as apart of component Class

Purpose : an implementation for Unified History component

Usage : used as an implementation for Histories , Action histories and Approval history.

Test Class Asssociated : NONE

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

component Associated : [ HD_Generic_History_relatedList, ]
Class used :

*/

public with sharing class HDUnifiedHistoryLightningEdition {
    
    @AuraEnabled public static String objectLabel {get; set;}
    @AuraEnabled public List<ProcessInstance> processInsList {get; set;}
    
    @AuraEnabled public static set<String> uniquedateSet {get;set;}
    
    //
    // @AuraEnabled private final BMCServiceDEsk__Incident__c incident;
    
    // Internal Variables
    @AuraEnabled public unifiedHistoryClass[] unifiedhistory;
    
    public static final Map<String, Schema.SObjectType> mySObjectTypeMap = Schema.getGlobalDescribe();
    public static Map<String, Schema.SObjectField> myObjectFieldMap;
    public static List<Schema.PicklistEntry> historyFieldPicklistValues;
    
    
    @AuraEnabled
    public static List<unifiedHistoryClass> getunifiedHistory(ID targetObjectIdvalue,Integer rowCount) {
        //populatind the List
        String unifiedhistoryclassListJSON ;
        List<unifiedHistoryClass> unifiedhistoryclassList;
        unifiedhistoryclassList  = new List<unifiedHistoryClass>();
        unifiedhistoryclassList.addAll(getObjectHistory(targetObjectIdvalue, rowCount));
        unifiedhistoryclassList.addAll(getActionHistory(targetObjectIdvalue, rowCount));
        unifiedhistoryclassList.addAll(getApprovalHistory(targetObjectIdvalue, rowCount));
        unifiedhistoryclassList.addAll(getAttachedNotesDocument(targetObjectIdvalue, rowCount));
        //json Stringify
        unifiedhistoryclassListJSON = JSON.serializePretty(unifiedhistoryclassList);
        // Lets Sort
        unifiedHistoryClass.sortBy = unifiedHistoryClass.SORT_BY.Bydatetime_unified;
        unifiedhistoryclassList.sort();     
        // descOrderofunifiedHist(unifiedhistoryclassList);
        system.debug('-->'+unifiedhistoryclassListJSON );
        
        return  descOrderofunifiedHist(unifiedhistoryclassList);
    }
    
    
    @AuraEnabled(cacheable=true)
    public static Map<String,Map<String,List<unifiedHistoryClass>>> getGroupedUnifiedHistoryByDate(ID targetObjectIdvalue, String rowCount)
    {   
        
        List<unifiedHistoryClass> uhList = getunifiedHistory(targetObjectIdvalue, Integer.valueOf(rowCount));
        Map<String,Map<String,List<unifiedHistoryClass>>> groupedbydateMap = new Map<String,Map<String,List<unifiedHistoryClass>>>();
        //set<String> uniquedateSet = new set<String>();
        uniquedateSet = new set<String>();
        List<String> uniqueObjectype  =  new List<String>();
        uniqueObjectype.add('History');
        uniqueObjectype.add('Action History');
        uniqueObjectype.add('Approval History');
        uniqueObjectype.add('Snote');
        
        //for getting unique date
        for(unifiedHistoryClass uhc : uhList)
        {
            if(!uniquedateSet.contains(uhc.datetime_unified))
            {
                uniquedateSet.add(uhc.datetime_unified);  
            }
            
        }//for(unifiedHistoryClass uhc : uhList)
        //Building nested dataset 
        for(String uniqdt : uniquedateSet )
        {
            Map<String,List<unifiedHistoryClass>> uniObjListbyObjectTypeMAp  = new Map<String,List<unifiedHistoryClass>>(); 
            for(String objType : uniqueObjectype)
            {               
                List<unifiedHistoryClass> uhobjTypeList = new List<unifiedHistoryClass>();                
                for(unifiedHistoryClass uhc1 : uhList)
                {
                    if( (uhc1.datetime_unified ==  uniqdt) && (uhc1.objecttype == objType) )
                    {
                        unifiedHistoryClass uhcObj = new unifiedHistoryClass();
                        uhcObj = uhc1;
                        uhobjTypeList.add(uhcObj);                          
                    }      
                    
                }//END for(unifiedHistoryClass uhc1 : uhList)
                uniObjListbyObjectTypeMAp.put(objType,uhobjTypeList);
            }//for(String objTypeList : uniqueObjectype )
            
            groupedbydateMap.put(uniqdt, uniObjListbyObjectTypeMAp);
            
        }//for(String uniqdt : uniquedateSet ) END
        
        return groupedbydateMap;
    }//
    
    
    
    //code for getting incident object   
    @AuraEnabled
    public static  List<unifiedHistoryClass> getObjectHistory(Id targetObjectIdvalue, Integer rowCount){
        Integer recordLimit = rowCount;
        //String myObjectId = String.valueOf(targetObjectIdvalue);
        set<String> filter = new set<String>();
        filter.add('Record Update Count');
        
        
        Schema.DescribeSObjectResult objectDescription = BMCServiceDesk__Incident__c.getSObjectType().getDescribe();
        
        myObjectFieldMap = objectDescription.fields.getMap();
        objectLabel = String.valueOf(objectDescription.getLabel());
        
        //Get the name of thew history table
        String objectHistoryTableName = objectDescription.getName();
        //if we have a custom object we need to drop the 'c' off the end before adding 'History' to get the history tables name
        if (objectDescription.isCustom()) {
            objectHistoryTableName = objectHistoryTableName.substring(0, objectHistoryTableName.length() - 1);
        }
        objectHistoryTableName = objectHistoryTableName + 'History';
        
        Schema.DescribeFieldResult objectHistoryFieldField = mySObjectTypeMap.get(objectHistoryTableName).getDescribe().fields.getMap().get('Field').getDescribe();
        historyFieldPicklistValues = objectHistoryFieldField.getPickListValues();
        
        list<unifiedHistoryClass> unifiedhistory = new list<unifiedHistoryClass>();
        
        String prevDate = '';
        
        if (recordLimit == null) {
            recordLimit = rowCount;
        }
        
        list<sObject> historyList = Database.query( 'SELECT CreatedDate,' +
                                                   'CreatedById,' +
                                                   'Field,' +
                                                   'NewValue,' +
                                                   'OldValue ' +
                                                   'FROM ' + String.escapeSingleQuotes(objectHistoryTableName) + ' ' +
                                                   'WHERE ParentId =:targetObjectIdvalue ' +
                                                   'ORDER BY CreatedDate DESC ' +
                                                   'LIMIT ' + String.valueOf(recordLimit));
        
        for (Integer i = 0; i < historyList.size(); i++) {
            sObject historyLine = historyList.get(i);
            if ((historyLine.get('newValue') == null && historyLine.get('oldValue') == null)
                || (historyLine.get('newValue') != null && !(string.valueOf(historyLine.get('newValue')).startsWith('005') || string.valueOf(historyLine.get('newValue')).startsWith('00G')))
                || (historyLine.get('oldValue') != null && !(string.valueOf(historyLine.get('oldValue')).startsWith('005') || string.valueOf(historyLine.get('oldValue')).startsWith('00G')))) {
                    unifiedHistoryClass tempHistory = new unifiedHistoryClass();
                    // Set the Date and who performed the action
                    if (String.valueOf(historyLine.get('CreatedDate')) != prevDate) {
                        tempHistory.datetime_unified = String.valueOf(historyLine.get('CreatedDate'));
                        tempHistory.user = String.valueOf(historyLine.get('CreatedById'));
                        tempHistory.who = String.valueOf(historyLine.get('CreatedById'));
                        tempHistory.objecttype = 'History';
                        
                    } else {
                        tempHistory.datetime_unified = String.valueOf(historyLine.get('CreatedDate'));
                        tempHistory.who = String.valueOf(historyLine.get('CreatedById'));
                        tempHistory.user = String.valueOf(historyLine.get('CreatedById'));
                        tempHistory.objecttype = 'History';
                        
                    }
                    prevDate = String.valueOf(historyLine.get('CreatedDate'));
                    
                    // Get the field label
                    String fieldLabel = HDUnifiedHistoryLightningEdition.returnFieldLabel(String.valueOf(historyLine.get('Field')));
                    
                    // Set the Action value
                    if (String.valueOf(historyLine.get('Field')) == 'created') { // on Creation
                        tempHistory.action = 'Created.';
                        tempHistory.objecttype = 'History';
                        tempHistory.datetime_unified = String.valueOf(datetime.valueof(historyLine.get('CreatedDate')).format('MM/dd/yyyy hh:mm:00 a'));
                        tempHistory.insertMe = true;
                    } else if (historyLine.get('oldValue') != null && historyLine.get('newValue') == null) { // when deleting a value from a field
                        // Format the Date and if there's an error, catch it and re
                        try {
                            tempHistory.action = 'Deleted ' + Date.valueOf(historyLine.get('oldValue')).format() + ' in <b>' + fieldLabel + '</b>.';
                            tempHistory.objecttype = 'History';
                            tempHistory.datetime_unified = String.valueOf(datetime.valueof(historyLine.get('CreatedDate')).format('MM/dd/yyyy hh:mm:00 a'));
                            tempHistory.insertMe = true;
                        } catch (Exception e) {
                            tempHistory.action = 'Deleted ' + String.valueOf(historyLine.get('oldValue')) + ' in <b>' + fieldLabel + '</b>.';
                            tempHistory.objecttype = 'History';
                            tempHistory.datetime_unified = String.valueOf(datetime.valueof(historyLine.get('CreatedDate')).format('MM/dd/yyyy hh:mm:00 a'));
                            tempHistory.insertMe = true;
                        }
                    } else { // all other scenarios
                        String fromText = '';
                        if (historyLine.get('oldValue') != null) {
                            try {
                                fromText = ' from ' + Date.valueOf(historyLine.get('oldValue')).format();
                            } catch (Exception e) {
                                fromText = ' from ' + String.valueOf(historyLine.get('oldValue'));
                            }
                        }
                        
                        String toText = '';
                        if (historyLine.get('oldValue') != null) {
                            try {
                                toText = Date.valueOf(historyLine.get('newValue')).format();
                            } catch (Exception e) {
                                toText = String.valueOf(historyLine.get('newValue'));
                            }
                        }
                        if (toText != '' && !(toText instanceOf Id)) {
                            if(!filter.contains(fieldLabel))
                            {
                                tempHistory.action = 'Changed <b>' + fieldLabel + '</b>' + fromText + ' to <b>' + toText + '</b>.';
                                tempHistory.objecttype = 'History';
                                datetime datetimeforHistory = datetime.valueof(historyLine.get('CreatedDate'));
                                tempHistory.datetime_unified = String.valueOf(datetime.valueof(historyLine.get('CreatedDate')).format('MM/dd/yyyy hh:mm:00 a'));
                                tempHistory.insertMe = true;
                            }//if(!filter.contains(fieldLabel))
                        } else if(historyLine.get('oldValue') == null){
                            toText = String.valueOf(historyLine.get('newValue'));
                            tempHistory.action = 'Changed <b>' + fieldLabel + '</b> to <b>' + toText + '</b>' ;
                            tempHistory.objecttype = 'History';
                            tempHistory.datetime_unified = String.valueOf(datetime.valueof(historyLine.get('CreatedDate')).format('MM/dd/yyyy hh:mm:00 a'));
                            if(toText !=null && !(toText instanceOf Id)){
                                tempHistory.insertMe = true;
                            }
                            
                            //toText = String.valueOf(historyLine.get('newValue'));
                            //if (toText != null) {
                            //  tempHistory.action = 'Changed <b>' + fieldLabel + '</b>';
                            //} else {
                            //  tempHistory.action = 'Changed <b>' + fieldLabel ;
                            //}
                            
                            //tempHistory.objecttype = 'History';
                            //tempHistory.datetime_unified = String.valueOf(historyLine.get('CreatedDate'));
                        }
                    }
                    
                    // Add to the list
                    if(tempHistory.insertMe){
                        if(( tempHistory.action.indexOf('Record Update Count') == -1)){
                            unifiedhistory.add(tempHistory);
                        }else{
                            continue;
                        }
                        
                    } 
                    
                }
        }
        List<Id> userIdList = new List<Id>();
        for (unifiedHistoryClass myHistory : unifiedhistory) {
            userIdList.add(myHistory.user);
        }
        Map<Id, User> userIdMap = new Map<ID, User>([SELECT Name FROM User WHERE Id IN : userIdList]);
        
        for (unifiedHistoryClass myHistory : unifiedhistory) {
            if (userIdMap.containsKey(myHistory.user) & (myHistory.who != '') ) {
                myHistory.who = userIdMap.get(myHistory.who).Name;
            }
        }

        return unifiedhistory;
    } //
    
    // Function to return Field Label of a object field given a Field API name
    public Static String returnFieldLabel(String fieldName) {
        
        if (HDUnifiedHistoryLightningEdition.myObjectFieldMap.containsKey(fieldName)) {
            return HDUnifiedHistoryLightningEdition.myObjectFieldMap.get(fieldName).getDescribe().getLabel();
        } else {
            for (Schema.PicklistEntry pickList : historyFieldPicklistValues) {
                if (pickList.getValue() == fieldName) {
                    if (pickList.getLabel() != null) {
                        return pickList.getLabel();
                    } else {
                        return pickList.getValue();
                    }
                }
            }
        }
        return '';
    }//
    
    //getting Action history component (fixed for Aura)
    public static List<unifiedHistoryClass> getActionHistory(Id targetObjectIdvalue, Integer rowCount) {
        List<unifiedHistoryClass> unifiedactionHistory = new List<unifiedHistoryClass>();
        for ( BMCServiceDesk__IncidentHistory__c inHist : [Select Id, Name, BMCServiceDesk__FKAction__c,
                                                           BMCServiceDesk__actionId__c,
                                                           BMCServiceDesk__Action_Duration__c,
                                                           BMCServiceDesk__Client_Contact__c,
                                                           BMCServiceDesk__Client_User__c,
                                                           BMCServiceDesk__date__c,
                                                           BMCServiceDesk__description__c,
                                                           BMCServiceDesk__duration__c,
                                                           BMCServiceDesk__EmailConversationData__c,
                                                           HD_Incident_ID__c,
                                                           BMCServiceDesk__inactive__c,
                                                           BMCServiceDesk__FKIncident__c,
                                                           BMCServiceDesk__incidentId__c,
                                                           BMCServiceDesk__note__c,
                                                           BMCServiceDesk__Reply__c,
                                                           BMCServiceDesk__Reply_Console__c,
                                                           BMCServiceDesk__RichTextNote__c,
                                                           BMCServiceDesk__FKUser__c,
                                                           BMCServiceDesk__FKUser__r.Name,
                                                           BMCServiceDesk__userId__c,
                                                           BMCServiceDesk__system__c
                                                           from BMCServiceDesk__IncidentHistory__c Where BMCServiceDesk__FKIncident__c = :targetObjectIdvalue ORDER BY CreatedDate DESC  Limit :rowCount]) {
                                                               unifiedHistoryClass unifiedhist = new unifiedHistoryClass();
                                                               //setting up values
                                                               unifiedhist.objecttype = 'Action History';
                                                               unifiedhist.incident_History_ID_name = inHist.Name;
                                                               unifiedhist.incident_History_ID = inHist.Id;
                                                               unifiedhist.actionId = inHist.BMCServiceDesk__actionId__c;
                                                               unifiedhist.datetime_unified = String.valueOf(datetime.valueof(inHist.BMCServiceDesk__date__c).format('MM/dd/yyyy hh:mm:ss a'));
                                                               unifiedhist.action_History_Description = inHist.BMCServiceDesk__description__c;
                                                               unifiedhist.note = inHist.BMCServiceDesk__note__c;
                                                               unifiedhist.richNote =  inHist.BMCServiceDesk__RichTextNote__c;
                                                               unifiedhist.duration = inHist.BMCServiceDesk__duration__c;
                                                               
                                                               if(unifiedhist.actionId == 'Email Received'){
                                                                   unifiedhist.action_History_Description = 'Email From';
                                                                   unifiedhist.note = inHist.BMCServiceDesk__note__c.substringBetween ('From:','Sent:');
                                                                   //added a fix for exeption   
                                                                   if( inHist.BMCServiceDesk__RichTextNote__c != null) 
                                                                   {
                                                                       unifiedhist.richNote = inHist.BMCServiceDesk__RichTextNote__c;//.substringBetween('From:');
                                                                   }else
                                                                   {
                                                                       unifiedhist.richNote = inHist.BMCServiceDesk__note__c; //added change for From:Null
                                                                   }
                                                                   //End if fix for exception where history is not shown because of this error
                                                               } 
                                                               
                                                               unifiedhist.user_staff_name = inHist.BMCServiceDesk__FKUser__r.Name;
                                                               unifiedhist.user_staff_ID = inHist.BMCServiceDesk__FKUser__c;
                                                               
                                                               unifiedhist.action = '<b>' + inHist.BMCServiceDesk__actionId__c + '</b>';
                                                               
                                                               system.debug('---->' + inHist.BMCServiceDesk__note__c);
                                                               system.debug('---->' + unifiedhist.actionId);
                                                               
                                                               unifiedactionHistory.add(unifiedhist);
                                                           }
        
        
        return unifiedactionHistory;
    }//
    
    /* Unable this for SPARK integration */
    //Getting Spark attached SNOTES Document 
    public static List<unifiedHistoryClass> getAttachedNotesDocument(Id LinkedEntityortargetObjectId, Integer rowCount)
    {   
        
        List<unifiedHistoryClass> unifiedactionHistory = new List<unifiedHistoryClass>();
        List<BMCServiceDesk__Incident__c> IncList = [SELECT Id,
                                                     (SELECT Id,
                                                      Title,
                                                      TextPreview,
                                                      CreatedDate, 
                                                      CreatedById,
                                                      CreatedBy.Name
                                                      FROM AttachedContentNotes)
                                                     FROM BMCServiceDesk__Incident__c where id = :LinkedEntityortargetObjectId LIMIT :rowCount];
        
        for( BMCServiceDesk__incident__c Inc : IncList )
        {
            for(AttachedContentNote ab: inc.AttachedContentNotes)
            {
                unifiedHistoryClass unifiedhist = new unifiedHistoryClass();
                //setting up values
                unifiedhist.objecttype = 'Snote';
                unifiedhist.incident_History_ID_name = ab.Title;
                unifiedhist.incident_History_ID = ab.Id;
                unifiedhist.actionId = '';
                unifiedhist.who = ab.CreatedBy.Name;
                unifiedhist.user = ab.CreatedById; 
                unifiedhist.datetime_unified = String.valueOf(datetime.valueof(ab.CreatedDate).format('MM/dd/yyyy hh:mm:ss a'));
                unifiedhist.action_History_Description = ab.TextPreview;
                unifiedhist.note = ab.TextPreview;
                unifiedhist.richNote =  ab.TextPreview;
                System.debug(ab.Title);
                //adding it to unified History
                unifiedactionHistory.add(unifiedhist);
            }
            // System.debug(''+inc.AttachedContentNotes);
        }
        
        return unifiedactionHistory;
        
    }//
    
    //method for approval history (fixed for Aura)
    @AuraEnabled(cacheable=true)
    public static List<unifiedHistoryClass> getApprovalHistory(Id targetObjectIdvalue, Integer rowCount) {
        Id loggedInUser = Userinfo.getUserId();
        Map<ID, boolean> User_Part_of_Queue ; 
        List<ProcessInstance> processInsList;
        boolean IsApprovalPending = false;
        ID WorkItemIDValue = null;
        
        if(rowCount>200){rowCount=1;} //added this specific condition for approval only to show only latest approval
        
        List<unifiedHistoryClass> unifiedapprovalHistory = new List<unifiedHistoryClass>();
        User_Part_of_Queue = new Map<ID, boolean>();
        User_Part_of_Queue.put(loggedInUser, false);
        processInsList = new List<ProcessInstance>();
        List<ProcessInstance>  processInsListPendingStatus =  new List<ProcessInstance>();
        processInsList = [ SELECT Id, TargetObjectId, CreatedDate, Status, (SELECT Id, ActorId, Actor.Name, OriginalActorId, OriginalActor.Name, StepStatus, Comments, CreatedDate  FROM StepsAndWorkitems ORDER BY CreatedDate DESC ) FROM ProcessInstance where TargetObjectId = :targetObjectIdvalue ORDER BY CreatedDate DESC  LIMIT 1 ]; //changed this as row count is for 1 record
        processInsListPendingStatus  = [ SELECT Id, Status, CreatedDate, (SELECT Id, ActorId, Actor.Name, OriginalActorId, OriginalActor.Name, StepStatus, Comments, CreatedDate  FROM StepsAndWorkitems ORDER BY CreatedDate DESC ) FROM ProcessInstance where TargetObjectId = :targetObjectIdvalue ORDER BY CreatedDate DESC LIMIT :rowCount ];//changed to rowCount attribute
        //getting if the uder is part of queue or not
        List<GroupMember> ActorPartofQueueIds = new List<GroupMember>();
        ActorPartofQueueIds = [ SELECT Id, Group.Name, Group.Id FROM GroupMember WHERE UserOrGroupId = :loggedInUser AND Group.Type = 'Queue' Limit 10000 ];//increased the count here since user base increased
        if (processInsListPendingStatus.size() > 0) {
            for (ProcessInstance prcIns : processInsListPendingStatus) {
                //applying to unified history object
                unifiedHistoryClass unifiedhist = new unifiedHistoryClass();
                unifiedhist.datetime_unified = String.valueOf(DateTime.valueOf(prcIns.CreatedDate).format('MM/dd/yyyy hh:mm:ss a'));//added the fix for NaN Problem 
                unifiedhist.objecttype = 'Approval History';
                unifiedhist.approval_overall_Status = prcIns.Status;
                unifiedhist.stepandworkitemunifiedlist = new List<unifiedStepsandworkitemClass>();
                if (true) { // prcIns.Status == 'Pending'
                    
                    for ( ProcessInstanceHistory stepswiid : prcIns.StepsAndWorkitems) {
                        
                        unifiedStepsandworkitemClass stwidcls = new unifiedStepsandworkitemClass();
                        /*stwidcls.assigned_To = stepswiid.Actor.Name;
                        stwidcls.assigned_To_id = stepswiid.ActorId;
                        stwidcls.actual_Approver = stepswiid.OriginalActor.Name;*/
                        
                        /* --------- Rectifiying the above three line by updating as below three line for JIRA Story PRTORES-1698-------- */
                        stwidcls.assigned_To = stepswiid.OriginalActor.Name;
                        stwidcls.assigned_To_id = stepswiid.OriginalActorId;
                        stwidcls.actual_Approver = stepswiid.Actor.Name;
                        stwidcls.actualApproverId = stepswiid.ActorId;
                        stwidcls.approval_Comment = stepswiid.Comments;
                        stwidcls.stepstatus = stepswiid.StepStatus;
                        stwidcls.stepcreatedDate = String.valueOf(stepswiid.CreatedDate);
                        //adding  the value to the lsit
                        unifiedhist.stepandworkitemunifiedlist.add(stwidcls);
                    }//for loop
                    
                    //for pending status
                    IsApprovalPending = true;
                    
                    for ( ProcessInstanceHistory stepswiid : prcIns.StepsAndWorkitems) {
                        if(stepswiid.StepStatus == 'Pending') {
                            
                            //checking if the USer is part of queue or not
                            if (ActorPartofQueueIds.size() > 0) {
                                for (  GroupMember grpmem : ActorPartofQueueIds ) {
                                    if ( grpmem.Group.Id == stepswiid.OriginalActorId ) {
                                        //adding to MAp
                                        User_Part_of_Queue.put(loggedInUser, true);
                                    }//
                                    
                                }//for( ActorPartofQueueIds )
                            }//if(ActorPartofQueueIds.size() > 0)
                            // else
                            //{
                            //   User_Part_of_Queue.put(loggedInUser,false);
                            // } //else of if(ActorPartofQueueIds.size() > 0)
                            
                            
                            WorkItemIDValue = stepswiid.id;
                            break;
                        }//
                    }//for( ProcessInstanceHistory stepswiid : prcIns.StepsAndWorkitems)
                    
                    
                }//if(prcIns.Status == '')
                else {
                    IsApprovalPending = false;
                }
                unifiedapprovalHistory.add(unifiedhist);
            }//for(ProcessInstance prcIns : processInsListPendingStatus)
            
        }//if(processInsListPendingStatus.size() > 0)
        return unifiedapprovalHistory;
    }//
    
    //creating selectlist for status
    
    public List<selectOption> getStatusPicklist() {
        List<selectOption> options = new List<selectOption>();
        options.add(new selectOption('', '- None -'));
        for (BMCServiceDesk__Status__c status : [Select Name, Id from BMCServiceDesk__Status__c WHERE BMCServiceDesk__appliesToIncident__c = true ]) {
            options.add(new selectOption(status.Id, status.Name));
        }//for
        
        return options;
    }//public List<selectOption> getStatusPicklist()
    
    //This method will be used to for ordering Unified sorted list in to descending order
    //@AuraEnabled
    public static List<unifiedHistoryClass> descOrderofunifiedHist( unifiedHistoryClass[] sortedUnifedhistoryList)
    {   
        unifiedHistoryClass[] decsUnifiedHistory = new unifiedHistoryClass[]{};
            for(integer i = sortedUnifedhistoryList.size() - 1;i>=0;i--)
        {
            decsUnifiedHistory.add(sortedUnifedhistoryList.get(i));
        }
        
        return decsUnifiedHistory;
    }
    
}//END