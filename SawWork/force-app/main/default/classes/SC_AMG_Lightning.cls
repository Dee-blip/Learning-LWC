/*
Author          : Sheena Bhan
Description     : Controller for AMG Home Page and Case Record Page in Lightning
Test Class      : SC_AMG_Lightning_Test


Date                Developer             JIRA #                            Description                                                       
------------------------------------------------------------------------------------------------------------------
25 Nov 2019         Sheena               ESESP-2039                	   AMG Migration to Lightning
9  May 2022			Vandhana			 ESESP-7167					   ESESP-6457 Clear SC IP Scrubbed checkbox on cloned Cases
------------------------------------------------------------------------------------------------------------------
*/



public class SC_AMG_Lightning {
    
    
    @AuraEnabled(cacheable=true)
    public static list<string> getCaseRecType()
    {   
        
        List<string> recordTypes = new List<string>();
        for(RecordTypeInfo info: Case.SObjectType.getDescribe().getRecordTypeInfos()) {
            if(info.isAvailable()) {
                if(info.Name!='Master') {
                    recordTypes.add(info.getName());
                }
            }
        }
        system.debug('recordTypes///1'+recordTypes);
        return recordTypes;
    }
    
    
    @AuraEnabled(cacheable=true)
    public static map<String,String> getAccountData(String caseId)
    {  
        List<Case> caseLst = [select id,AccountId,Account.Name,Subject from Case where id =: caseId limit 1];
        String accId = caseLst[0].AccountId;
        String accName = caseLst[0].Account.Name;
        map<String,String> multiSelectPicklst = new map<String,String>();
        Id userId = UserInfo.getUserId();
        List<AccountTeamMember> actQuery = [SELECT Id,Account.Name,AccountId 
                                            FROM AccountTeamMember 
                                            WHERE UserId = :userId and AccountId != :accId ORDER BY Account.Name];
        multiSelectPicklst.put(accName,accId);
        for(AccountTeamMember accTeamMem: actQuery)
        {
            multiSelectPicklst.put(accTeamMem.Account.Name,accTeamMem.AccountId);
        }
        return multiSelectPicklst;
    }
    
    @AuraEnabled
    public static map<String,String> getAccounts(String accId) {
        map<String,String> accMap = new map<String,String>();
        Account accountVal = [select id, name from account where id =: accId limit 1];
        accMap.put(accountVal.Name, accountVal.Id);
        return accMap;
    }
    
    @AuraEnabled
    public static void cloneMulti(List<String> accountIds, String caseId) {
        
        List<Case> caseCloneList = new List<Case>();
        String accId;
        String caseQuery = 'Select ';
        
        Map<String, Schema.Sobjectfield> CaseFieldMap = Case.sObjectType.getDescribe().fields.getMap();
        system.debug('CaseFieldMap//'+CaseFieldMap);
        for(String caseFlds : CaseFieldMap.keySet()){
            system.debug('caseFlds//'+caseFlds);
            Schema.DescribeFieldResult caseField = CaseFieldMap.get(caseFlds).getDescribe();
            if(caseField.isUpdateable() && caseField.isAccessible()){
                caseQuery += caseFlds + ',';
            }
        }
        caseQuery = caseQuery.substring(0, caseQuery.length()-1);
        if(!caseQuery.containsIgnoreCase('AKAM_Case_ID__c')) 
        {
            caseQuery += ',AKAM_Case_ID__c';
        }
        caseQuery += ',CaseNumber,Account.Name,Contact.AccountId From Case Where Id = :caseId';
        Case originalCase = Database.query(caseQuery);
        
        system.debug('originalCase//'+originalCase);
        accId = originalCase.AccountId;
        for(Id accIdVar : accountIds)
        {
            Case cs = originalCase.clone(false,true);
            cs.AccountId = accIdVar;
            if(cs.AccountId != accId)
            {
                cs.ContactId = null;
            }
            cs.AKAM_Case_ID__c = null;
            cs.Status = 'Assigned';
            cs.Contract__c = NULL;
            cs.OwnerId = UserInfo.getUserId();
            cs.AKAM_Closed_Date__c = NULL;
            cs.Resolved_Date__c = NULL;
            cs.Last_Case_Update__c = NULL;
            cs.Partner_Account__c = NULL;
            cs.Siebel_Request_Status__c = NULL;
            cs.Indirect_Customer__c = NULL;
            cs.LOE_Hours__c = NULL;
            cs.LOE_Minutes__c = NULL;
            cs.Task_LOE__c = NULL;
            cs.Last_Customer_Activity_Date__c  = NULL;
            cs.Last_Case_Owner_Update__c   = NULL;
            cs.Last_Non_Case_Owner_Update__c   = NULL;
            cs.Reopened__c = false;
            cs.AKAM_Created_Date__c = NULL;
            cs.AKAM_Created_By__c  = NULL;
            cs.AKAM_Modified_By__c  = NULL;
            cs.AKAM_Modified_Date__c  = NULL;
            cs.AKAM_Reopened_Date__c = Null;
            
            // changes by Vandhana for ESESP-7167
            cs.Is_IP_Scrubbed__c = false;
            cs.IP_Scrubbing_Failed_Objects__c = null;
            
            caseCloneList.add(cs);  
        }
        
        try{
            if(!caseCloneList.isEmpty())
            {
                system.debug('In Tryyyy');
                insert caseCloneList;
                system.debug('caseCloneList Inserted//'+caseCloneList.size());
                
            }
        }
        catch (exception e) 
        {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static map<Id, Case> createChildcase(String caseId, String recType) {
        system.debug('In Single Apex');
        system.debug('caseId///'+caseId);
        map<Id, Case> caseMap = new map<Id, Case>();
        Id RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get(recType).getRecordTypeId();
        
        String caseQuery = 'Select Id,';
        
        List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(Metadata.MetadataType.Layout, 
                                                                       new List<String> {'Case-Converted: AMG Case Feed Layout'});
        String queryString = 'Subject,Description';
        Metadata.Layout layoutMd = (Metadata.Layout)layouts.get(0);
        for (Metadata.LayoutSection section : layoutMd.layoutSections) {
            if(section.label == 'Customer Information'){
                for (Metadata.LayoutColumn column : section.layoutColumns) {
                    if (column.layoutItems != null) {
                        for (Metadata.LayoutItem item : column.layoutItems) {
                            if(item.field != null){
                                queryString += ','+item.field;
                            }
                        }
                    }
                }
            }
        }
        system.debug('queryString//'+queryString);
        caseQuery += queryString;
        system.debug('caseQuery///'+caseQuery);
        caseQuery += ' From Case Where Id = :caseId';
        Case originalCase = Database.query(caseQuery);
        originalCase.Id = null;
        //originalCase.AKAM_Case_ID__c = null;
        originalCase.ParentId = caseId;
        originalCase.Do_Not_Show_In_Portal_Picklist__c  = 'Internal Only';
        originalCase.Case_Assignment_Using_Active_Rules__c  = true;
        If(recType == 'AMG')
        {
            originalCase.Related_Cases_Check__c  = true;
        }
        
        caseMap.put(RecordTypeId,originalCase);
        
        return caseMap;               
    }
    
    @AuraEnabled
    public static string reopenClosedCase(String caseId){ 
        Integer closedDays;
        string errorMsg = '';
        map<string,string> errorMap = new map<string,string>();
        
        system.debug('caseId//'+caseId);
        system.debug('In reopenClosedCase APex');
        Case caseRec = [select id,Reopened__c, Status, AKAM_Closed_Date__c, AKAM_Reopened_Date__c, Is_IP_Scrubbed__c from Case where  id =: caseId];    
        
        
        if(caseRec.Status != 'Closed'){
            errorMsg = 'Re-open is only available on closed cases.';
            // errorMap.put('Status','Re-open is only available on closed cases.');
            return errorMsg;
            //  caseRec.addError('Re-open is only available on closed cases.');
        }
        else{
            
            closedDays = caseRec.AKAM_Closed_Date__c.date().daysBetween(system.today());
            system.debug('caseRec//'+caseRec);
            system.debug('closedDays//'+closedDays);
            
            If(closedDays <= 45)
            {
                system.debug('In If');
                //caseRec.Id = '{!Case.Id}';
                caseRec.Reopened__c = true;
                caseRec.Status = 'Reopened';
                caseRec.AKAM_Closed_Date__c = null;
                caseRec.AKAM_Reopened_Date__c = system.now();
                caseRec.Is_IP_Scrubbed__c = false;
                caseRec.IP_Scrubbing_Failed_Objects__c = null;
            }
            else
            {
                errorMsg = 'Cases can only be reopened within 45 days of case closure. Please create a new case.';
                // errorMap.put('Age','Cases can only be reopened within 30 days of case closure. Please create a new case.');
                return errorMsg;
            }
        }
        
        try{
            if(caseRec!=null){
                system.debug('errorMap//'+errorMap);
                update caseRec;
            }
        }catch (exception e){
            throw new AuraHandledException(e.getMessage());
        }
        
        return errorMsg;
        
    }
    
    @AuraEnabled
    public static String cloneCaseRec(String caseId) 
    {
        system.debug('In Single Apex');
        system.debug('caseId///'+caseId);
        List<Case> caseCloneList = new List<Case>();
        String caseQuery = 'Select Id,';
        
        Map<String, Schema.Sobjectfield> CaseFieldMap = Case.sObjectType.getDescribe().fields.getMap();
        system.debug('CaseFieldMap//'+CaseFieldMap);
        for(String caseFlds : CaseFieldMap.keySet()){
            system.debug('caseFlds//'+caseFlds);
            Schema.DescribeFieldResult caseField = CaseFieldMap.get(caseFlds).getDescribe();
            if(caseField.isUpdateable()){
                caseQuery += caseFlds + ',';
            }
        }
        caseQuery = caseQuery.substring(0, caseQuery.length()-1);
        if(!caseQuery.containsIgnoreCase('AKAM_Case_ID__c')) 
        {
            caseQuery += ',AKAM_Case_ID__c';
        }
        system.debug('caseQuery///'+caseQuery);
        caseQuery += ' From Case Where Id = :caseId';
        system.debug('caseQuery222//'+caseQuery);
        Case originalCase = Database.query(caseQuery);
        
        //caseObj = Database.query(caseQuery);
        system.debug('originalCase//'+originalCase);
        //return originalCase;
        
        Case newCase = originalCase.clone(false,true);
        
        //cs.AccountId = accIdVar;
        
        newCase.AKAM_Case_ID__c = null;
        newCase.Status = 'Assigned';
        newCase.Contract__c = NULL;
        newCase.OwnerId = UserInfo.getUserId();
        newCase.AKAM_Closed_Date__c = NULL;
        newCase.Resolved_Date__c = NULL;
        newCase.Last_Case_Update__c = NULL;
        newCase.Last_Customer_Activity_Date__c  = NULL;
        newCase.Last_Case_Owner_Update__c   = NULL;
        newCase.Last_Non_Case_Owner_Update__c   = NULL;
        newCase.Reopened__c = false;
        // changes by Vandhana for ESESP-7167
		newCase.Is_IP_Scrubbed__c = false;
        newCase.IP_Scrubbing_Failed_Objects__c = null;
        //caseCloneList.add(newCase);  
        
        try
        {
            insert newCase;
            system.debug('caseCloneList Inserted//'+caseCloneList.size());
            return newCase.Id;
            
        }
        catch (exception e) 
        {
            return e.getMessage();
        }   
    }
    
    @AuraEnabled
    public static void closeCaseInvalid(String caseId, String commentsData){
        system.debug('commentsData//'+commentsData);
        
        Case caseRec = [Select id,Close_Case_Invalid__c,Status,Validation_Override__c,Comments__c,RecordTypeId from Case where id =: caseId];
        
        //caseRec.Close_Case_Invalid__c = true;
        caseRec.Status = 'Closed'; 
        caseRec.Validation_Override__c = true;
        caseRec.Comments__c = commentsData;
        caseRec.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Invalid Case').getRecordTypeId();
        
        If(caseRec != null)
        {
            update caseRec;
            system.debug('caseRec//'+caseRec);
        }
        
    }
    
    @AuraEnabled(cacheable=true)
    public static string getAMGCaseRecTypeId()
    {   
        String recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        system.debug('recTypeId//'+recTypeId);
        return recTypeId;   
    }
    
    @AuraEnabled
    public static void closeCases(String caseId, Map<String,String> caseFieldValues)
    {
        List<Case> caseCloseList = new List<Case>();
        Integer numofcasesClosed;
        
        Set<Id> allSet = new Set<Id>();
        
        for(Case cs : [Select id, Status, Resolution_Field__c, Solution_Summary__c, ResolvableByPartner__c, Recommended_Partner_Action__c,
                       Resolution__c, Origin, Unique_Case__c, Service__c, Request_Type__c, Request_Sub_Type__c, LOE_Hours__c, LOE_Minutes__c, Task_LOE__c
                       from case where id =: caseId])
        {
            cs.Status = caseFieldValues.get('Status');
            cs.Resolution_Field__c = caseFieldValues.get('Resolution_Field__c');
            cs.Solution_Summary__c = caseFieldValues.get('Solution_Summary__c');
            cs.ResolvableByPartner__c = caseFieldValues.get('ResolvableByPartner__c');
            cs.Recommended_Partner_Action__c = caseFieldValues.get('Recommended_Partner_Action__c');
            //cs.Resolution__c = caseFieldValues.get('Resolution__c');
            cs.Origin = caseFieldValues.get('Origin');
            //cs.Unique_Case__c = Boolean.valueOf(caseFieldValues.get('Unique_Case__c'));
            cs.Service__c = caseFieldValues.get('Service__c');
            cs.Request_Type__c = caseFieldValues.get('Request_Type__c');
            cs.Request_Sub_Type__c = caseFieldValues.get('Request_Sub_Type__c');
            cs.LOE_Hours__c = Decimal.ValueOf(caseFieldValues.get('LOE_Hours__c'));
            cs.LOE_Minutes__c = Decimal.ValueOf(caseFieldValues.get('LOE_Minutes__c'));
            cs.PRISM_Used__c  = caseFieldValues.get('PRISM_Used__c');
            
            allSet.add(cs.id);
            caseCloseList.add(cs);
        }
        
        System.debug('+++caseCloseList'+caseCloseList);
        
        String msg = '';
        try{
            update caseCloseList; 
            
        }catch(DmlException e){
            
            //Get All DML Messages
            for (Integer i = 0; i < e.getNumDml(); i++) {
                msg =+ e.getDmlMessage(i);
            }
            //throw DML exception message
            throw new AuraHandledException(msg);
            
        }catch(Exception e){
            //throw all other exception message
            throw new AuraHandledException(e.getMessage());
        }
        
    }
    
    @AuraEnabled(cacheable=false)
    public static Object updateClosedCases(String caseDetails) {
        
        system.debug('Testing ' + caseDetails);
        List<Case> lCaseToUpdate = new List<Case>(); 
        Set<Id> allSet = new Set<Id>();
        caseDetails = caseDetails.replaceall('\\r\\n',' ');
        caseDetails = caseDetails.replaceAll('\\n', ' ');
        caseDetails = caseDetails.replaceAll('\\r', ' ');
        caseDetails = caseDetails.replaceAll('\\t', ' ');
        system.debug('caseDetails ' + caseDetails);
        try{
            List<ParseCaseClosePayload> lCloseCasePayload = (List<ParseCaseClosePayload>)JSON.deserialize(caseDetails, List<ParseCaseClosePayload>.class);
            //Map<String, object> jsonMap = (Map<String, object>)JSON.deserializeUntyped(caseDetails);
            
            for(ParseCaseClosePayload varCaseClose :lCloseCasePayload)
            {
                Case varCase = new Case();
                varCase.Id = varCaseClose.Id;
                varCase.Akam_Case_Id__c = varCaseClose.Akam_Case_Id;
                varCase.Service__c = varCaseClose.Service;
                varCase.Request_Type__c = varCaseClose.Request_Type;
                varCase.Request_Sub_Type__c = varCaseClose.Request_Sub_Type;
                varCase.LOE_Hours__c = Decimal.valueOf((varCaseClose.LOE_Hours==null || varCaseClose.LOE_Hours ==
                                                        '')?'0':varCaseClose.LOE_Hours);
                varCase.LOE_Minutes__c = Integer.valueOf((varCaseClose.LOE_Minutes==null || varCaseClose.LOE_Minutes == '')?'0':varCaseClose.LOE_Minutes);
                varCase.Resolution_Field__c = varCaseClose.Resolution_Field;
                //ESESP-4511 Bhavesh,checking null condition for below fields, as these fields are pasting 'null' string value in fields.
                if( varCaseClose.ResolvableByPartner != 'null' && varCaseClose.ResolvableByPartner != '')
                	varCase.ResolvableByPartner__c = varCaseClose.ResolvableByPartner;
                else 
                    varCase.ResolvableByPartner__c = null;
                if( varCaseClose.Recommended_Partner_Action != 'null' && varCaseClose.Recommended_Partner_Action != '')
                	varCase.Recommended_Partner_Action__c = varCaseClose.Recommended_Partner_Action;
                else 
                    varCase.Recommended_Partner_Action__c = null;
                if( varCaseClose.Solution_Summary != 'null' && varCaseClose.Solution_Summary != '')
                	varCase.Solution_Summary__c = varCaseClose.Solution_Summary;
                else 
                    varCase.Solution_Summary__c = NULL;
                if( varCaseClose.PRISM_Used != 'null' && varCaseClose.PRISM_Used != '')
                	varCase.PRISM_Used__c = varCaseClose.PRISM_Used;
                else
                    varCase.PRISM_Used__c = NULL;
                varCase.Status = 'Closed';
                //varCase.AccountId = varCaseClose.AccountId;
                //Below if else statement Added by Ashin - ESESP-6631	
                system.debug('acount id -------'+varCaseClose.AccountId );	
                if(varCaseClose.AccountId != 'null' && varCaseClose.AccountId != '')	
                {	
                    system.debug(' inside acount id -------'+varCaseClose.AccountId );	
                  varCase.AccountId = varCaseClose.AccountId;	
                }
                else
                {
                    varCase.AccountId = null;
                }
                //Above if else statement added by Ashin - ESESP-6631
                if( varCaseClose.Subject != 'null' && varCaseClose.Subject != '')
                	varCase.Subject = varCaseClose.Subject;
                else 
                    varCase.Subject = NULL;
                if( varCaseClose.Do_Not_Show_In_Portal_Picklist != 'null' && varCaseClose.Do_Not_Show_In_Portal_Picklist != '')
                	varCase.Do_Not_Show_In_Portal_Picklist__c = varCaseClose.Do_Not_Show_In_Portal_Picklist;
                else 
                    varCase.Do_Not_Show_In_Portal_Picklist__c = null;
                allSet.add(varCase.id);
                lCaseToUpdate.add(varCase);
            }
            List<Database.SaveResult> updateRes = Database.update(lCaseToUpdate, false);
            system.debug('updateRes//'+updateRes);
            
            
            set<Id> failedSet = new Set<Id>();
            set<Id> passedSet = new Set<Id>();
            String erMsg;
            map<String, Database.SaveResult> mAkamIdCaseRec = new map<String, Database.SaveResult>();
            map<String,String> mError = new map<String,String>();
            
            
            
            for(Integer i=0; i<lCaseToUpdate.size(); i++){
                system.debug('lCaseToUpdate[i]////'+lCaseToUpdate[i]);
                if(!updateRes[i].isSuccess())
                {
                    mAkamIdCaseRec.put(lCaseToUpdate[i].Akam_Case_Id__c, updateRes[i]);
                    failedSet.add(lCaseToUpdate[i].id); 
                }            
            }
            
            
            system.debug('mAkamIdCaseRec//'+mAkamIdCaseRec);
            
            for(String cs: mAkamIdCaseRec.keySet() )
            {
                for(Database.Error err : mAkamIdCaseRec.get(cs).getErrors())
                {
                    mError.put(cs,err.getMessage());
                }
            }
            
            
            List<String> exmsg2 = new List<String>();
            String errorDispMsg = '';
            String finalErrorMsgs = '';
            for(String csId: mError.keySet())
            {
                errorDispMsg += csId + ': ' + mError.get(csId) + ',' + '\n' ;
            }
            finalErrorMsgs = errorDispMsg.removeEnd(',');
            system.debug('finalErrorMsgs//'+finalErrorMsgs);
            
            
            WrapperResponse retWrap = new WrapperResponse();
            retWrap.errorMessage = errorDispMsg;
            retWrap.closedCaseCount = lCaseToUpdate.size()-mAkamIdCaseRec.size();
            retWrap.erroredCaseCount = mAkamIdCaseRec.size();
            retWrap.failedSet = failedSet;
            return JSON.serialize(retWrap);
        }
        catch(Exception e){
            Set<Id> failedSet = new Set<Id>();
            for(Integer i=0; i<lCaseToUpdate.size(); i++){
                failedSet.add(lCaseToUpdate[i].id); 
            }
            WrapperResponse retWrap = new WrapperResponse();
            retWrap.errorMessage = 'ALL: Issue while parsing the JSON. Please check if special characters are present in text. \n';
            retWrap.closedCaseCount = 0;
            retWrap.erroredCaseCount = lCaseToUpdate.size();
            retWrap.failedSet = failedSet;
            return JSON.serialize(retWrap);
        }
        
    }
    
    public Class ParseCaseClosePayload{
        String AKAM_Case_ID;
        String Id;
        String AccountId;
        String Service;
        String Request_Type;
        String Request_Sub_Type;
        String LOE_Hours;
        String LOE_Minutes;
        String Resolution_Field;
        String ResolvableByPartner;
        String Recommended_Partner_Action;
        String Solution_Summary;
        String PRISM_Used;
        String Subject;
        String Do_Not_Show_In_Portal_Picklist;
    }
    public class WrapperResponse
    {
        public set<Id> failedSet;
        public String errorMessage;
        public Integer closedCaseCount;
        public Integer erroredCaseCount;
    }
    
    @AuraEnabled(cacheable=false)
    public static string getCaseStatus(Id caseId)
    {
        Case cs = [select id, status from case where id =: caseId];
        return cs.status;
    }
    
    @AuraEnabled
    public static List<Task> allOpenTaskRelatedToCase(String caseId,Integer recordLimit, Integer recordOffset)
    {   
        Integer intLimit = Integer.valueof(recordLimit);
        Integer intOffset = Integer.valueof(recordOffset);
        List<Task> taskList = new List<Task>([Select Id, Status,Type__c,AKAM_Modified_Date__c,Subject FROM Task where Status in ('Not Started','In Progress','Postponed - Agreed with Customer/IAT') 
                                              AND WhatId =: caseId ORDER BY CreatedDate DESC LIMIT :intLimit OFFSET :intOffset]);
        return taskList;
    }
    
    @AuraEnabled
    public static Integer openTaskCount(String caseId)
    {   
        
        List<Task> taskList = new List<Task>([Select Id, Status,Type__c,AKAM_Modified_Date__c,Subject FROM Task where Status in ('Not Started','In Progress','Postponed - Agreed with Customer/IAT') 
                                              AND WhatId =: caseId  LIMIT 5000]);
        return taskList.size();
    }
    
    @AuraEnabled(cacheable=false)
    public static String updateBulkTaskStatus( String status, List<String> taskIdsList )
    {   
        List<Task> taskList = new List<Task>();
        for( String tId : taskIdsList ){
            Task ts = new Task();
            ts.Id = tId;
            ts.Status = status;
            taskList.add(ts);
        }
        List<String> errorList = new List<String>();
        if(taskList.size()>0){
			List<Database.SaveResult> updateRes = Database.update(taskList, false);
            
            for (Database.SaveResult sr : updateRes) {
                if (!sr.isSuccess()) {
                    for(Database.Error err : sr.getErrors()) {
                        errorList.add(''+err.getMessage());
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }
            
        }
        if(errorList.size()>0){
            return JSON.serialize(errorList);
        } else {
            return '';
        }
        
    }
    
    
   @AuraEnabled        
    public static List<String> fetchRecordTypeValues(){
        List<Schema.RecordTypeInfo> recordtypes = Task.SObjectType.getDescribe().getRecordTypeInfos();    
        Map<Id, String> recordtypemap = new Map<Id, String>();
        for(RecordTypeInfo rt : recordtypes){
            if(rt.getName() != 'Master')
            recordtypemap.put(rt.getRecordTypeId(), rt.getName());
        }        
        return recordtypemap.values();
    }
    
    @AuraEnabled
    public static Id getRecTypeId(String recordTypeLabel){
        Id recid = Schema.SObjectType.Task.getRecordTypeInfosByName().get(recordTypeLabel).getRecordTypeId();        
        return recid;
    }   
    
    //ESESP-4265:return case record, to display clone peer review button when certain condition is satisfied.
    @AuraEnabled
    public static Case getCaseFields(String caseId){
        Case caseRec = new Case();
        if(caseId != NULL){
            for(Case cs  : [Select Id, Service__c, Request_Type__c, Request_Sub_Type__c,Is_Peer_Review_Clone__c, IsClosed FROM Case WHERE Id =: caseId]){
                caseRec = cs;
            }
        }
        return caseRec;
    } 
    //ESESP-4265:clone functionality
    @AuraEnabled
    public static map<Id, Case> peerReviewClone(String caseId) {
        map<Id, Case> caseMap = new map<Id, Case>();
        Id RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        
        String caseQuery = 'Select Id';
        
        List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(Metadata.MetadataType.Layout, 
                                                                       new List<String> {'Case-Converted: AMG Case Feed Layout'});
        String queryString = '';
        Metadata.Layout layoutMd = (Metadata.Layout)layouts.get(0);
        for (Metadata.LayoutSection section : layoutMd.layoutSections) {
            if(section.label != 'System Info'){
                for (Metadata.LayoutColumn column : section.layoutColumns) {
                    if (column.layoutItems != null) {
                        for (Metadata.LayoutItem item : column.layoutItems) {
                            if(item.field != null){
                                queryString += ','+item.field;
                            }
                        }
                    }
                }
            }
        }
        caseQuery += queryString;
        if(!caseQuery.contains('Customer_Temperature__c'))
            caseQuery += ', Customer_Temperature__c';
        if(!caseQuery.contains('Level_of_Impact__c'))
            caseQuery += ', Level_of_Impact__c';
        caseQuery += ' From Case Where Id = :caseId';
        System.debug('==caseQuery: '+caseQuery);
        Case originalCase = Database.query(caseQuery);
        Case clonedCase = originalCase.clone(false, true);
        clonedCase.Id = null;
        //originalCase.AKAM_Case_ID__c = null;
        clonedCase.ParentId = caseId;
        
        clonedCase.Request_Sub_Type__c = 'Peer Review';
        clonedCase.Do_Not_Show_In_Portal_Picklist__c  = 'Internal Only';
        clonedCase.Case_Assignment_Using_Active_Rules__c  = true;
        clonedCase.Related_Cases_Check__c  = true;
        clonedCase.parentId = caseId;
        clonedCase.Is_Peer_Review_Clone__c = true;
        clonedCase.Akam_Case_Id__c = null;
        
        caseMap.put(RecordTypeId,clonedCase);
        System.debug('case: '+clonedCase);
        return caseMap;                
    }
   
}