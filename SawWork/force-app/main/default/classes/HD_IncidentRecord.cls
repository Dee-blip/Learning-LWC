/*
* File Name: HD_IncidentRecord
* Description : 
* @author :
* Modification Log ===============================================================
* Date 				Author 				Modification
* Aug 08th, 2020    Aneesh Budnar       PRTORES-1810 - Code scanner fixes
*/
public with sharing class HD_IncidentRecord {
    
    public static List<Id> incIds;
    public static String query;
    public class wrapperClass
    {
        @AuraEnabled 
        public Integer noOfPages;
        @AuraEnabled 
        public Integer noOfRecords;
        @AuraEnabled
        public List<BMCServiceDesk__Incident__c> records;
        
        
    }
    
   
    @AuraEnabled
    public static wrapperClass getIncidentList(Id filterId,String noOfRecs,String ticketNumber,Integer pageNo,String orderBy,String sortDirection){
        
        //String query = queryGenerator();
        
        if(String.isNotBlank(ticketNumber))
        {
            String q = queryGenerator();
            q = String.escapeSingleQuotes(q) + 'where Name =:ticketNumber LIMIT 1 ';  //cs fix - PRTORES-1581 - shegade
            wrapperClass wc = new wrapperClass();
            wc.noOfPages = 1;
            wc.noOfRecords = 1;
            wc.records = Database.query(q);
            return wc;
            
        }
        
        initRecords(filterId);
        String q = query+' where id in :incIds and Record_Type__c != \'Service Incident\'ORDER BY '+orderBy+' '+sortDirection+' LIMIT 9000 ' ;
        
        ApexPages.StandardSetController srmObject2 = new ApexPages.StandardSetController(Database.getQueryLocator(q));
        Integer pageSize = Integer.valueOf(noOfRecs);
        srmObject2.setPageSize(pageSize);
        Integer page_number = Integer.valueOf(pageNo);
        
        srmObject2.setPageNumber(page_number);
        
        wrapperClass wc = new wrapperClass();
        wc.noOfPages = (Integer)Math.ceil((Decimal)srmObject2.getResultSize()/(Decimal)pageSize);
        wc.noOfRecords = srmObject2.getResultSize();
        wc.records = srmObject2.getRecords();
        
        return wc;
    }
    
    
    @AuraEnabled
    public static wrapperClass getIncidentList_V2(Id filterId,String noOfRecs,String ticketNumber,Integer pageNo,String orderBy,String sortDirection){
        
         if(String.isNotBlank(ticketNumber))
        {
            String q = queryGenerator();
            q = String.escapeSingleQuotes(q) + 'where Name =:ticketNumber LIMIT 1 ';  //cs fix - PRTORES -1581 shegade
            wrapperClass wc = new wrapperClass();
            wc.noOfPages = 1;
            wc.noOfRecords = 1;
            wc.records = Database.query(q);
            return wc;
            
        }
        boolean present = false;
        List<ListView> incViews = getListViews('Incident');
        for(ListView lv : incViews){
            if(lv.id == filterId){
               present = true;
                break;
            }
        }
        if(filterId==null || (String)filterId=='' || !present){
            System.debug((ID)incViews[0].id);
            filterId = (ID)incViews[0].id;
        }
        

        initRecords(filterId);
        String q = query+' where id in :incIds and Record_Type__c != \'Service Incident\'ORDER BY '+orderBy+' '+sortDirection+' LIMIT 9000 ' ;
        
        ApexPages.StandardSetController srmObject2 = new ApexPages.StandardSetController(Database.getQueryLocator(q));
        Integer pageSize = Integer.valueOf(noOfRecs);
        srmObject2.setPageSize(pageSize);
        Integer page_number = Integer.valueOf(pageNo);
        
        srmObject2.setPageNumber(page_number);
        
        wrapperClass wc = new wrapperClass();
        wc.noOfPages = (Integer)Math.ceil((Decimal)srmObject2.getResultSize()/(Decimal)pageSize);
        wc.noOfRecords = srmObject2.getResultSize();
        wc.records = srmObject2.getRecords();
        
        return wc;

    }
    @AuraEnabled
    public static List<ListView> getListViews(String type) {
        List<ListView> listviews;
        if(type == 'Incident')
        {
            listviews = [SELECT Id, Name FROM ListView WHERE SobjectType = 'BMCServiceDesk__Incident__c' and (not name like 'SRM%' ) and (not name like '%DONOTUSE%' )  ORDER BY Name];
        }
        else if(type == 'Service Request')
        {
            listviews = [SELECT Id, Name FROM ListView WHERE SobjectType = 'BMCServiceDesk__Incident__c' and  name like 'SRM%' and (not name like '%DONOTUSE%' ) ORDER BY Name];               
        }
        else
        {
            listviews = [SELECT Id, Name FROM ListView WHERE SobjectType = 'BMCServiceDesk__Incident__c'];
        }
        return listviews;
    }
   
    @AuraEnabled
    public static Map<String, String> getColumns() {
        Map<String, String> cols = new Map<String, String>();
        List<Schema.FieldSetMember> filesset1 = SObjectType.BMCServiceDesk__Incident__c.FieldSets.LightningColumns.getFields();
        for (Schema.FieldSetMember fsm : filesset1) {
            // System.debug('Field api names: '+fsm.getfieldpath());
            //cols.put((String) fsm.getLabel().substringBefore('~'),(String) fsm.getFieldPath());
            cols.put((String) fsm.getLabel(),(String) fsm.getFieldPath());
        }
        return cols;
    }

    @AuraEnabled
    public static Map<String,String> getUserColumns() {
        Map<String,String> cols = new Map<String,String>();
        String field;
        try
        {
            
            
            HD_UserConfig__c userConfig = HD_UserConfig__c.getValues(System.UserInfo.getUserId());
            
            if(userConfig==null)
            {
                userConfig = HD_UserConfig__c.getOrgDefaults();
                
            }
            
            String value; 
            for(Integer i=1;i<15;i++)
            {
                field = 'Field'+i+'__c';
                value = (String)userConfig.get(field); 
                if(value!=null)
                {
                    cols.put(value.split(':::')[0].trim(), value.split(':::')[1].trim());
                }
            }
        }
        
        catch(Exception e)
        {
           HD_UX_Exception_LoggerCls.logErrorRecord(e.getMessage(),e.getStackTraceString(),null);
        }
        return cols;
    }
    
    @AuraEnabled
    public static void updateSelectedColumns(Map<String, String> selectedColumns) {
        try
        {
           List<String> selCols = new List<String>();
            String field;
            for(String key : selectedColumns.keySet())
            {
                selCols.add(key+':::'+selectedColumns.get(key));
            }
            
            HD_UserConfig__c userConfig = HD_UserConfig__c.getValues(System.UserInfo.getUserId());
            if(userConfig == null)
            {
                userConfig = new HD_UserConfig__c();
            }
            for(Integer i=1;i<=selCols.size();i++)
            {
                field = 'Field'+i+'__c';
                userConfig.put(field, selCols[i-1]);
                
            }
            for(Integer i=selCols.size()+1;i<15;i++)
            {
                field = 'Field'+i+'__c';
                userConfig.put(field, null);
            }
            userConfig.SetupOwnerId = System.UserInfo.getUserId();
            upsert(userConfig); 
        }
        catch(Exception e)
        {
           HD_UX_Exception_LoggerCls.logErrorRecord(e.getMessage(),e.getStackTraceString(),null);
        }
    }
    
    public static String queryGenerator()
    {
        Map<String, String> userColumns = getUserColumns();
        Set<String> fields = new Set<String>{'name','BMCServiceDesk__Client_Name__c','BMCServiceDesk__Category_ID__c','HD_Owner_user_queue__c','BMCServiceDesk__Type__c', 'BMCServiceDesk__clientEmail__c' ,'HD_Client_City__c','VIP_Ticket__c' ,'Response_Threshold_Crossed__c', 'SR_Priority__c', 'BMCServiceDesk__openDateTime__c','BMCServiceDesk__dueDateTime__c', 'BMCServiceDesk__closeDateTime__c'};
        //String fsetq = 'Select id,name,BMCServiceDesk__Type__c, BMCServiceDesk__clientEmail__c ,HD_Client_City__c,VIP_Ticket__c ,Response_Threshold_Crossed__c, SR_Priority__c, BMCServiceDesk__openDateTime__c,BMCServiceDesk__dueDateTime__c, BMCServiceDesk__closeDateTime__c  ';
        String  fieldString = 'Select id';
        for(String key : userColumns.keySet())
        {
            fields.add(userColumns.get(key));
        }
        for(String s:fields)
        {
            fieldString+=','+s;
        }
        /*String fsetq = 'Select id,name,SR_Priority__c';    
        List<Schema.FieldSetMember> filesset1 = SObjectType.BMCServiceDesk__Incident__c.FieldSets.LightningColumns.getFields();
        for(Schema.FieldSetMember fsm : filesset1 )
        {
            fsetq+=','+fsm.getfieldpath();
        }
        fsetq+=' from BMCServiceDesk__Incident__c ';*/
        fieldString+=' from BMCServiceDesk__Incident__c ';
        
        
        return fieldString;
    }//
    
    public class fileClass
    {
        public String fileName;
        public String fileType;
        public String fileContents;
    }
    
    @AuraEnabled
    public static String createIncident(Id userId, String priority, Id category, String description,Boolean sbi,Boolean whitehat,Boolean dlEIS,Boolean ntfyCreation,Boolean ntfyStatus,Boolean ntfyNotes,Boolean pageSupportValue,Boolean vipValue,Boolean excludeNotificationValue,String sourceValue,String ccValues, List<String> fileData){
        BMCServiceDesk__Incident__c createdInc;
        HD_Ticket_Priority__c ticket_priority = HD_Ticket_Priority__c.getInstance(priority);
        //BMCServiceDesk__Category__c categoryId = [Select ID FROM BMCServiceDesk__Category__c where name = :category Limit 1][0];
        String clientId = System.UserInfo.getUserId();
        BMCServiceDesk__Incident__c incident = new BMCServiceDesk__Incident__c();
        incident.BMCServiceDesk__FKCategory__c = category;
        incident.HD_Ticket_Priority__c = priority;
        //incident.BMCServiceDesk__FKClient__c = clientId;
        if(userId!=null){
            incident.BMCServiceDesk__FKClient__c = userId;
        }
        else{
            incident.BMCServiceDesk__FKClient__c = clientId;
        }
        //incident.BMCServiceDesk__incidentDescription__c = 'Ticket created from code';
        incident.BMCServiceDesk__incidentDescription__c = description;
        //incident.BMCServiceDesk__shortDescription__c = shortDesc;
        incident.HD_System_Admin_Incident__c = sbi;
        incident.HD_WhiteHat_Incident__c = whitehat;
        incident.Notify_dl_sysadmin_on_creation__c = ntfyCreation;
        incident.Notify_dl_sysadmin_on_status_change__c = ntfyStatus;
        incident.HD_Notify_DL_EIS_on_Notes_Update__c = ntfyNotes;
        incident.HD_High_Customer_Impact__c = pageSupportValue;
        incident.VIP_Ticket__c = vipValue;
        incident.Exclude_Client_Notifications__c = excludeNotificationValue;
        incident.BMCServiceDesk__contactType__c = sourceValue;
        incident.CCText__c = ccValues;
        incident.RecordTypeId = Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Helpdesk').getRecordTypeId();//'012G0000000yTCBIA2'; //Record Type Id for "Helpdesk"
        try{
            insert incident;
            //createdInc = [SELECT ID,Name,OwnerId,HD_System_Admin_Incident__c,HD_WhiteHat_Incident__c,Notify_dl_sysadmin_on_creation__c,Notify_dl_sysadmin_on_status_change__c,HD_Notify_DL_EIS_on_Notes_Update__c,HD_High_Customer_Impact__c from BMCServiceDesk__Incident__c where ID = :incident.id Limit 1][0];
            createdInc = [SELECT ID,Name from BMCServiceDesk__Incident__c where ID = :incident.id Limit 1][0];
            //remove
        }
        catch (Exception e) {
            //throw new AuraHandledException(e.getMessage().substringAfterLast('FIELD_CUSTOM_VALIDATION_EXCEPTION,'));
            throw new AuraHandledException(e.getMessage());
            //return e.getMessage();
        }
        List<Attachment> attachmentList = new List<Attachment>();
        for(String f:fileData){
            fileClass file = (fileClass) System.JSON.deserialize(f, fileClass.class);
            String base64Data = EncodingUtil.urlDecode(file.fileContents, 'UTF-8');
            Attachment a = new Attachment();
            a.parentId = incident.Id;
            a.Body = EncodingUtil.base64Decode(base64Data);
            a.Name = file.fileName;
            a.IsPrivate = false;
            //a.ContentType = contentType;  
            attachmentList.add(a);
        }
        
        insert attachmentList;
        return  incident.Id+';'+createdInc.Name;
    }
    
    @AuraEnabled
    public static String initRecords(Id filterId){
        query = queryGenerator();
        //List<HD_BMCIncidentSortWrapper> listForSort = new List<HD_BMCIncidentSortWrapper>();
        
        Integer count = 0;
        //String debugstr;
        Integer pageNum =1;
        String q = query+' limit 1000';
        ApexPages.StandardSetController srmObject = new ApexPages.StandardSetController(Database.getQueryLocator(q));
        srmObject.setPageSize(2000);
        srmObject.setPageNumber(pageNum);
        srmObject.setFilterID(filterId);
        incIds = new List<Id>();
        
        /*for(SObject inc: srmObject.getRecords()){
incIds.add(inc.Id);
HD_BMCIncidentSortWrapper hdw = new HD_BMCIncidentSortWrapper((BMCServiceDesk__Incident__c)inc);
hdw.fieldToCompare = 'BMCServiceDesk__clientEmail__c';
listForSort.add(hdw);
count++;            
}  */
        
        for(SObject inc: srmObject.getRecords())
        {
            
            incIds.add(inc.Id);
            count++;            
        }
        
        while(srmObject.getHasNext())
        {
            srmObject.next();
            for(SObject inc: srmObject.getRecords()){
                //HD_BMCIncidentSortWrapper hdw = new HD_BMCIncidentSortWrapper((BMCServiceDesk__Incident__c)inc);
                //hdw.fieldToCompare = 'BMCServiceDesk__clientEmail__c';
                //listForSort.add(hdw);
                
                incIds.add(inc.Id);
                count++;            
            }
            
        }
        
        return 'initialized';
        
    }
    
    @AuraEnabled 
    public static BMCServiceDesk__Category__c[] getCategories() {
        return [SELECT Id,Name,BMCServiceDesk__FKParentCategory__c,BMCServiceDesk__parentTree__c, BMCServiceDesk__FKParentCategory__r.Name,BMCServiceDesk__FKParentCategory__r.BMCServiceDesk__FKParentCategory__c FROM BMCServiceDesk__Category__c where BMCServiceDesk__AvailableForIncidents__c = true and BMCServiceDesk__inactive__c = false order by Name];
        
    }
    
    @AuraEnabled
    public static Map<String,Id> getActiveUsers(String startsWith){
        String searchText = '%' +startsWith+'%';
        List<User> userList = [Select Id, Name, Username, Title, Phone, UserRoleId, ProfileId from User where IsActive = true and (Name like :searchText or Email like :searchText)];
        Map<String,Id> userMap = new Map<String,Id>();
        for(User usr : userList ){
            userMap.put(usr.Name+'|'+usr.Title+'|'+usr.Phone+'|'+usr.Username+'|'+usr.UserRoleId+'|'+usr.ProfileId,usr.Id);
        }
        
        return userMap;
        
    }
    
    @AuraEnabled
    public static Map<String,Id> getRequestDefinitionsList(){
        Map<String,Id> rdMap = new Map<String,Id>();
        List<BMCServiceDesk__SRM_RequestDefinition__c> rdList = [Select Id, Name from BMCServiceDesk__SRM_RequestDefinition__c where BMCServiceDesk__Inactive__c = false and BMCServiceDesk__Online__c = true];
        for(BMCServiceDesk__SRM_RequestDefinition__c rd: rdList){
            rdMap.put(rd.Name, rd.Id);
        }
        return rdMap;
    }
    
    
    
    
}