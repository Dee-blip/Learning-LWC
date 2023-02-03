public without sharing class SC_CreateCXMActivityController {
    /*Class is without sharing as it queries on all Users / Contacts /Leads / Groups in system.*/
    // Cache for UI API calls
   // private final static Map<String, PicklistEntries> uiApiCache = new Map<String, PicklistEntries>();
   private static final String base64Chars = '' +
        'ABCDEFGHIJKLMNOPQRSTUVWXYZ' +
        'abcdefghijklmnopqrstuvwxyz' +
        '0123456789+/';
        @AuraEnabled
        public static initWrapperClass fetchInitialDetails(Id recId){
           // System.debug('account Id**'+recId);
            initWrapperClass sampleWrapper = new initWrapperClass();
            Id userId = UserInfo.getUserId();
          //  Account acc = [Select Id,Name from Account where Id =:recId limit 1];
            sampleWrapper.relatedToName = [Select Id,Name from Account where Id =:recId limit 1].Name;
            sampleWrapper.relatedToId = recId;
            sampleWrapper.loggedinUserId = userId;
            sampleWrapper.loggedinUser = [Select Id,Name,title,profile.Name from User where Id =: userId limit 1];
            List<CXM_Activity_Creation_Values__mdt> cxmMetadataRec = CXM_Activity_Creation_Values__mdt.getAll().values();
            for(CXM_Activity_Creation_Values__mdt iteratedMetadataRec : cxmMetadataRec){
                if(iteratedMetadataRec.Label == 'CXM Activity'){
                    sampleWrapper.subjectList = iteratedMetadataRec.Subject__c.split(',');
                    sampleWrapper.statusList = iteratedMetadataRec.Status__c.split(',');
                    sampleWrapper.priorityList = iteratedMetadataRec.Priority__c.split(',');
                }
            }
           


            return sampleWrapper;
        }

        @AuraEnabled
        public static createActivityWrapperClass createCXMActivity(String subjectVal,String statusVal,String dueDateVal,String commentsVal,Id assignedToVal,Id relatedToVal,Id nameVal,String priorityVal,String product , String feature){
            createActivityWrapperClass sampleCreateActivityWrapperClass = new createActivityWrapperClass();
            List<Task> taskList= new List<Task>();
            Task cxmActivity = new Task();
            cxmActivity.recordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('CXM Activity').getRecordTypeId();
            cxmActivity.Subject = subjectVal;
            cxmActivity.Status = statusVal;
            if(dueDateVal != '')
            cxmActivity.ActivityDate = Date.valueOf(dueDateVal);
            cxmActivity.Description = commentsVal;
            cxmActivity.OwnerId = assignedToVal;
            cxmActivity.WhatId = relatedToVal;
            cxmActivity.WhoId = nameVal;
            cxmActivity.Priority = priorityVal;
            cxmActivity.Product__c = product;
            cxmActivity.Features__c = feature;
            taskList.add(cxmActivity);
            Database.SaveResult saveResultList = Database.Insert(cxmActivity);
          //  for(Database.SaveResult sr : saveResultList){
                if(!saveResultList.isSuccess()){
                    for(Database.Error err : saveResultList.getErrors()) {
                    
                        sampleCreateActivityWrapperClass.error = err.getMessage();
                    }
                }else{
                    sampleCreateActivityWrapperClass.taskId = cxmActivity.Id;
                }
           // }
            return sampleCreateActivityWrapperClass;
            
        }
     
    
         // lookup search results method (Called from SC_SI_LookupComponent lightning comp.)
        @AuraEnabled
        public static List < sObject > fetchLookUpValues(String searchKeyWord , String ObjectName) 
        {
            
            String searchKey = searchKeyWord + '%';
            
         List < sObject > returnList = new List < sObject > ();
            
            String sQuery;
            String val;
            // Create a Dynamic SOQL Query For Fetch Record List with LIMIT 5 
            
            if(ObjectName == 'User/Queue')
            {
                val = 'Queue';
            sQuery =  'SELECT Id, Name FROM User WHERE Name LIKE: searchKey ' 
                        + 'order by Name ASC limit 5'; 
            returnList.addAll(Database.query(sQuery));
            sQuery =  'SELECT Id, Name,(select SobjectType from QueueSobjects) FROM Group WHERE Name LIKE: searchKey AND Type = \''+val+'\''
            + 'order by Name ASC limit 5';    
             
                for(Group iteratedGroup : Database.query(sQuery)){
                    for(sObject supportedObject : iteratedGroup.QueueSobjects){
                       // System.debug('object name**'+supportedObject.SobjectType);
                       // System.debug('object name**'+String.valueOf(supportedObject));
                      //  if(supportedObject.SobjectType == 'Task'){
                            returnList.add(iteratedGroup);
                            break;
                      //  }*/
                    }
                }
            }
            if(ObjectName == 'Contact/Lead')
            {
              
            sQuery =  'SELECT Id, Name FROM Contact WHERE Name LIKE: searchKey ' 
                        + 'order by Name ASC limit 5'; 
            returnList.addAll(Database.query(sQuery));
            sQuery =  'SELECT Id, Name FROM Lead WHERE Name LIKE: searchKey ' 
                        + 'order by Name ASC limit 5'; 
            returnList.addAll(Database.query(sQuery)); 
               
            }

        else
            {
                sQuery =  'select id, Name from ' + ObjectName + ' where Name LIKE: searchKey order by createdDate DESC limit 5';
            }
            //return Database.query(sQuery);
            return returnList;
        }

        public class initWrapperClass{
            @AuraEnabled
            public string relatedToName;
            @AuraEnabled
            public string relatedToId;
            @AuraEnabled
            public string loggedinUserId;
            @AuraEnabled
            public User loggedinUser;
            @AuraEnabled
            public List<String> subjectList;
            @AuraEnabled
            public List<String> statusList;
            @AuraEnabled
            public List<String> priorityList;

        }   
        
        public class createActivityWrapperClass{
            @AuraEnabled
            public string error;
            @AuraEnabled
            public string taskId;
            public  createActivityWrapperClass(){
                error = '';
                taskId = '';
            }
        }  


        @AuraEnabled 
    public static PicklistWrapper getDependentPicklist(String ObjectName, string parentField, string childField) {
        Map<String,List<String>> pickListMap = new Map<String,List<String>>();
        PicklistWrapper pw = new PicklistWrapper();
        pw.pickListMap = pickListMap;
        
        if (Schema.getGlobalDescribe().get(ObjectName) ==null || String.isBlank(parentField) || String.isBlank(ChildField)){
            return pw;
        }
 
        Schema.sObjectType objType = Schema.getGlobalDescribe().get(ObjectName).newSObject().getSObjectType();
        Map<String, Schema.SObjectField> objFieldMap = objType.getDescribe().fields.getMap();
        
        if (!objFieldMap.containsKey(parentField) || !objFieldMap.containsKey(childField)){
            return pw;     
        }
        
        List<PicklistEntryWrapper> depEntries = (List<PicklistEntryWrapper>)JSON.deserialize(JSON.serialize(objFieldMap.get(ChildField).getDescribe().getPicklistValues()), List<PicklistEntryWrapper>.class);
        List<String> controllingValues = new List<String>();
        System.debug('****'+objFieldMap.get(parentField).getDescribe().getPicklistValues());
        for (Schema.PicklistEntry ple : objFieldMap.get(parentField).getDescribe().getPicklistValues()) {
            pickListMap.put(ple.getLabel(), new List<String>());
            controllingValues.add(ple.getLabel());
        }
        System.debug('pickListMap before***'+pickListMap);
        
        for (PicklistEntryWrapper plew : depEntries) {
            String validForBits = base64ToBits(plew.validFor);
            for (Integer i = 0; i < validForBits.length(); i++) {
                String bit = validForBits.mid(i, 1);
                if (bit == '1') {
                    pickListMap.get(controllingValues.get(i)).add(plew.label);
                }
            }
        }
        System.debug('pickListMap after***'+pickListMap.get('Ion'));
        
        pw.pickListMap = pickListMap;
        pw.parentFieldLabel = objFieldMap.get(parentField).getDescribe().getLabel();
        pw.childFieldLabel = objFieldMap.get(childField).getDescribe().getLabel();
        return pw;
    }
    
    
    public static String decimalToBinary(Integer val) {
        String bits = '';
        while (val > 0) {
            Integer remainder = Math.mod(val, 2);
            val = Integer.valueOf(Math.floor(val / 2));
            bits = String.valueOf(remainder) + bits;
        }
        return bits;
    }
    
    public static String base64ToBits(String validFor) {
        if (String.isEmpty(validFor)) return '';
        
        String validForBits = '';
        
        for (Integer i = 0; i < validFor.length(); i++) {
            String thisChar = validFor.mid(i, 1);
            Integer val = base64Chars.indexOf(thisChar);
            String bits = decimalToBinary(val).leftPad(6, '0');
            validForBits += bits;
        }
        
        return validForBits;
    }
    
    public class PicklistWrapper{
    	@AuraEnabled
        public Map<String, List<String>> pickListMap;
        @AuraEnabled
        public String parentFieldLabel;
        @AuraEnabled
        public String childFieldLabel;      
    }
        
    public class PicklistEntryWrapper{
        public String active;
        public String defaultValue;
        public String label;
        public String value;
        public String validFor;
        
    }
	//method to update files count on file deleting on Task
    public static void updateIsFileAttachedOnTask(List<ContentDocument> deletedContentDocuments){
        Set<Id> contentDocumentIdSet = new Set<Id>();
        List<Id> parentRecordIdList = new List<Id>();
        List<ContentDocumentLink> impactedContentDocumentLinkList = new List<ContentDocumentLink>(); 
        Task t;
        Id cxmRecordTypeId;
        Map<Id,Task> taskDetailsMap = new Map<Id,Task>();
        List<Task> tasksToUpdate = new List<Task>();
        for(ContentDocument iteratedContentDocument : deletedContentDocuments){
            contentDocumentIdSet.add(iteratedContentDocument.Id);
        }
        List<ContentDocumentLink> contentDocumentLinkList = [Select Id,LinkedEntityId from ContentDocumentLink where ContentDocumentId IN: contentDocumentIdSet];
        for(ContentDocumentLink iteratedContentDocumentLink : contentDocumentLinkList){
            if(iteratedContentDocumentLink.LinkedEntityId.getSObjectType().getDescribe().getName() == 'Task'){
              //  impactedContentDocumentLinkList.add(iteratedContentDocumentLink);
                parentRecordIdList.add(iteratedContentDocumentLink.LinkedEntityId);

                
            }
        }
        if(parentRecordIdList.size() > 0){
            cxmRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('CXM Activity').getRecordTypeId();
            taskDetailsMap = new Map<Id,Task>([Select Id,No_of_files_attached__c from task where Id IN : parentRecordIdList AND recordTypeId =:cxmRecordTypeId]);
            for(Id iteratedTaskId : parentRecordIdList){
                t = taskDetailsMap.get(iteratedTaskId);
               
                if(t != null && t.No_of_files_attached__c != 0){
                t.No_of_files_attached__c = t.No_of_files_attached__c  - 1;
                tasksToUpdate.add(t);
                }
            }
            
        }
        if(tasksToUpdate.size() > 0){
            update tasksToUpdate;
        }
       
    }
	//method to update files count on file linking on task
    public static void evaluateIsFileAttachedOnTask(List<ContentDocumentLink> newList,List<ContentDocumentLink> oldList){
        List<ContentDocumentLink> cdls = ( newList == null ? oldList : newList );
        Set<ID> parentIds = new Set<ID>();
        Map<Id,Task> taskMap = new Map<Id,Task>();
        List<Task> updateActivityList = new List<Task>();
        Map<Id,List<ContentDocumentLink>> recVsCDLList = new Map<Id,List<ContentDocumentLink>>();
        List<ContentDocumentLink> tempCDLList;
        Task activityRec ;
        Id cxmRecordTypeId;
        for ( ContentDocumentLink cdl : cdls ) {
           // System.debug('ObjectName***'+cdl.LinkedEntityId.getSObjectType().getDescribe().getName());
           System.debug('parent type***'+cdl.LinkedEntityId.getSObjectType().getDescribe().getName() );
            if(cdl.LinkedEntityId.getSObjectType().getDescribe().getName() == 'Task')
            {   parentIds.add( cdl.LinkedEntityId );
                
            }
            if(recVsCDLList.get(cdl.LinkedEntityId) != null){
                recVsCDLList.get(cdl.LinkedEntityId).add(cdl); 
            }else{
                tempCDLList = new List<ContentDocumentLink>();
                tempCDLList.add(cdl);
                recVsCDLList.put(cdl.LinkedEntityId,tempCDLList);
            }
        }
        System.debug('1***'+recVsCDLList);
        if(parentIds.size() > 0){
        cxmRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('CXM Activity').getRecordTypeId();
        
        
            taskMap = new Map<Id,Task>([Select Id,No_of_files_attached__c FROM Task WHERE Id IN :parentIds AND recordTypeId =: cxmRecordTypeId]);
            for(Id iteratedId : parentIds){
       
                activityRec = taskMap.get(iteratedId);
                
                    if(activityRec != null && recVsCDLList.get(iteratedId) != null){
                        activityRec.No_of_files_attached__c = activityRec.No_of_files_attached__c + recVsCDLList.get(iteratedId).size();
                        updateActivityList.add(activityRec);
                    }   
                       
                  
                    
          
            }    
            if(updateActivityList.size() > 0)
            update updateActivityList;
        }    
    }
	//method to update files count on file delinking on task
    public static void evaluateIsFileAttachedOnTaskUpdateScenario(Map<Id,ContentDocumentLink> oldMap){
        
                
        Set<ID> parentIds = new Set<ID>();
        Map<Id,Task> taskMap = new Map<Id,Task>();
        List<Task> updateActivityList = new List<Task>();
        Id cxmRecordTypeId ;
        Task activityRec ;
        for ( ContentDocumentLink cdl : oldMap.values()) {
            
           
            if(cdl.LinkedEntityId.getSObjectType().getDescribe().getName() == 'Task' )
            parentIds.add( cdl.LinkedEntityId );
           
        }
        if(parentIds.size() > 0){
            cxmRecordTypeId = Schema.SObjectType.Task.getRecordTypeInfosByName().get('CXM Activity').getRecordTypeId();
            taskMap = new Map<Id,Task>([Select Id,No_of_files_attached__c FROM Task WHERE Id IN :parentIds AND recordTypeId =: cxmRecordTypeId]);
            for(Id iteratedId : parentIds){
       
                activityRec = taskMap.get(iteratedId);
                if(activityRec != null && activityRec.No_of_files_attached__c > 0)
                    {
                    activityRec.No_of_files_attached__c = activityRec.No_of_files_attached__c - 1;
                    updateActivityList.add(activityRec);
                    }
          
            }  
            if(updateActivityList.size() > 0)
            update updateActivityList;
        } 
    }
    
}