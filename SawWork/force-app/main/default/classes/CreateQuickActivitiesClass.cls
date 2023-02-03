global class CreateQuickActivitiesClass {

    // Quick_Activity_Setting__mdt holds all quick activity related data 
    public static String generateQuery(String source)
    {
       System.debug('Select Category__c,Fieldname__c,Insert__c,NewOperator__c,New_Value__c,OldOperator__c,OldValue__c,Type__c,Update__c,Source__c from Quick_Activity_Setting__mdt where Source__c =:source');
       return 'Select Category__c,Fieldname__c,Insert__c,NewOperator__c,New_Value__c,OldOperator__c,OldValue__c,Type__c,Update__c,Source__c from Quick_Activity_Setting__mdt where Source__c =:source';
    }

    private static Map<Id, String> generateMapOfAccountIdToAccountName(Map<Id,Id> mapOfWhatIdToAccountId)
    {
        Map<Id, String> mapOfAccountIdToAccountName = new Map<Id,String>();

        for(Account acc : [Select Id,Name from Account where Id =: mapOfWhatIdToAccountId.values()])
            mapOfAccountIdToAccountName.put(acc.Id,acc.Name);

        return mapOfAccountIdToAccountName;
    }

    private static Task generateTaskRecord(String category, String type, Id whoId, Id whatId, String accountName, String comments)
    {   
        
        Task taskObj        = new Task();
        taskObj.WhatId      = whatId;
        taskObj.Type__c     = type; 
        taskObj.QuickActionType__c     = type; 
        taskObj.Quick_Action_Category__c = category;
        if(whoId!=null)
            taskObj.WhoId   = whoId;

        if(accountName!=null)
            taskObj.Subject = type +  ' : ' + accountName;
        else
            taskObj.Subject = type +  ' : ' +'Dummy Account';

        taskObj.RecordTypeId= Schema.SObjectType.Task.getRecordTypeInfosByName().get('Sales Rep Activity').getRecordTypeId();
        // store in custom setting
        taskObj.Priority    = 'Normal';
        taskObj.Status      = 'Completed';
        taskObj.ActivityDate= Date.today();
        if(comments!=null)
            taskObj.Description = comments;

        return taskObj;
    }

    private static void insertTaskRecords(List<Task> listOfTasks)
    {
        insert listOfTasks;
    }

    private static void insertTaskRecords(Task taskRecord)
    {
        insert taskRecord;
    }

    // Called from a button click
    webservice static void quickActivityFromButton(String source,Id whoId, Id whatId, Id accountId)
    {
        String inputQuery;
        Quick_Activity_Setting__mdt activityData;
        Map<Id,Id> mapOfWhatIdToAccountId           = new Map<Id,Id>();
        Map<Id, String> mapOfAccountIdToAccountName = new Map<Id,String>();

        inputQuery                  = generateQuery(source);
        activityData                = Database.query(inputQuery);
        mapOfWhatIdToAccountId.put(whatId,accountId);
        mapOfAccountIdToAccountName = generateMapOfAccountIdToAccountName(mapOfWhatIdToAccountId);
        Task taskRecord             = generateTaskRecord(activityData.Category__c,activityData.Type__c,whoId,whatId,mapOfAccountIdToAccountName.get(accountId), 'This is an automated activity entry from Quote Button.');
        insertTaskRecords(taskRecord);
    }

    
    // Called from a trigger 
    public static void quickActivityFromTrigger(String source, SObject[] listOfSObjects, Map<Id, SObject> SObjectOldMap,Map<Id,Id> mapOfWhatIdToAccountId)
    {
        List<Quick_Activity_Setting__mdt> listOfActivityData    = new List<Quick_Activity_Setting__mdt>();
        List<Task> listOfTasks                                  = new List<Task>();
        Map<Id, String> mapOfAccountIdToAccountName             = new Map<Id,String>();
        Boolean insertFlag;
        Boolean updateFlag;
        Boolean newFlag;
        Boolean oldFlag;
        String inputQuery;

        inputQuery                  = generateQuery(source);
        listOfActivityData          = Database.query(inputQuery);
        mapOfAccountIdToAccountName = generateMapOfAccountIdToAccountName(mapOfWhatIdToAccountId);


        for(SObject sObj : listOfSObjects)
        {
            for(Quick_Activity_Setting__mdt qeSettingObj : listOfActivityData)
            {
                insertFlag = false;
                updateFlag = false;

                // check for insert 
                if(qeSettingObj.Insert__c && Util.isInserted(qeSettingObj.Fieldname__c, sObj))
                {
                    insertFlag = true;
                    // check if new value is inserted 
                    if(qeSettingObj.New_Value__c!=null)
                    {
                        newFlag     = Util.hasChangedTo(qeSettingObj.Fieldname__c,sObj,qeSettingObj.New_Value__c,qeSettingObj.NewOperator__c);
                        insertFlag  = newFlag;
                    }   
                }
                // check for update
                if(qeSettingObj.Update__c && Trigger.isUpdate && Util.hasChanges(qeSettingObj.Fieldname__c,SObjectOldMap.get(sObj.Id),sObj))
                { 
                    updateFlag = true;

                    // check if old value has changed
                    // use String.isblank
                    if(qeSettingObj.OldValue__c!=null)
                    {
                        oldFlag     = Util.hasChangedFrom(qeSettingObj.Fieldname__c,SObjectOldMap.get(sObj.Id),qeSettingObj.OldValue__c,qeSettingObj.OldOperator__c);
                        updateFlag  = oldFlag;
                    }
                    // check if new value has changed
                    if(qeSettingObj.New_Value__c!=null)
                    {
                        newFlag     = Util.hasChangedTo(qeSettingObj.Fieldname__c,sObj,qeSettingObj.New_Value__c,qeSettingObj.NewOperator__c);
                        updateFlag  = updateFlag && newFlag;
                    }   
                }
                // create a quick activity on update/insert
                if(insertFlag || updateFlag)
                {
                    Task taskRecord = generateTaskRecord(qeSettingObj.Category__c,qeSettingObj.Type__c,null,sObj.Id,mapOfAccountIdToAccountName.get(mapOfWhatIdToAccountId.get(sObj.Id)), 'This is a quick activity entry');
                    listOfTasks.add(taskRecord);
                }
            }
        }

        insertTaskRecords(listOfTasks);
    }    
    // called from QuickActivityEntryPageController
    public static void quickActivityFromVFPage(String category, String type, Id whoId, Id whatId, Id accountId, String description)
    {
        Map<Id,Id> mapOfWhatIdToAccountId           = new Map<Id,Id>();
        Map<Id, String> mapOfAccountIdToAccountName = new Map<Id,String>();

        mapOfWhatIdToAccountId.put(whatId,accountId);
        mapOfAccountIdToAccountName = generateMapOfAccountIdToAccountName(mapOfWhatIdToAccountId);
        Task taskRecord             = generateTaskRecord(category,type,whoId,whatId,mapOfAccountIdToAccountName.get(accountId),description);
        insertTaskRecords(taskRecord);

    }
}