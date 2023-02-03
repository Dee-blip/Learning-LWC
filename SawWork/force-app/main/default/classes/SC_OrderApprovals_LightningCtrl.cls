/*=====================================================================================================+
Class name          :   SC_OrderApprovals_LightningCtrl
Test Class          :   SC_OrderApprovals_LightningCtrlTest
Author              :   Vikas
Created             :   06-Feb-19
Purpose             :   This class is a generic class for all the lightning component of Order Approval application

Last Modified   Developer   Purpose            
=============   =========   ============ 
12 May 2021     Vandhana    ESESP-4590 : OA case creation by MPCC (added AKAM_System__c in query for fetchCaseDetails)          
23 Sep 2021     Aravind     ESESP-4261 : Added areAnyRelatedOACasesPending method to check if any related cases are pending
+=====================================================================================================*/
public class SC_OrderApprovals_LightningCtrl 
{
    //CASE WRAPPER
    public class ADWrapper
    {
        @AuraEnabled public Approval_Details__c ADRec;
        @AuraEnabled public String ADname;
    }
    
    @AuraEnabled
    public static Case fetchCaseDetails(String caseRecordId){
        Case caseRec = [Select AccountId, Opportunity__c, Sub_Type__c,RecordType.Name,RecordType.DeveloperName,RecordTypeId,Opportunity__r.StageName,
                        IsClosed,Status,Validation_Override__c, Order_Approval__c,Re_open_Reason_Code__c,Re_open_Comments__c,OwnerId,AutoClose__c,IsCreatedbyCPQ__c,
                        AKAM_System__c
                        from Case 
                        where id =: Id.ValueOf(caseRecordId)];
        return caseRec;
    }
    @AuraEnabled
    public static List<Case> fetchCaseApprovalDetails(String caseRecordId){
        List<Case> caseList = new List<Case>();
        List<Approval_Details__c> ADList = new List<Approval_Details__c>();
        ADList = [Select Id,Related_To__r.Status from Approval_Details__c where Related_To__c =: Id.ValueOf(caseRecordId)];
        caseList = [Select id,Status, (Select id from Approval_Details__r where Related_To__c =: Id.ValueOf(caseRecordId)) from Case where id =: Id.ValueOf(caseRecordId)];
        return caseList;
    }
    
    
    @AuraEnabled
    public static String returnLayoutSectionFields(){
        List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(Metadata.MetadataType.Layout, 
                                     new List<String> {'Approval_Details__c-Approval Details DD'});
        String queryString = 'Case_Record_Type__c,Case_RT_ST__c';
        Metadata.Layout layoutMd = (Metadata.Layout)layouts.get(0);
        for (Metadata.LayoutSection section : layoutMd.layoutSections) {
            if(section.label == 'Request Details'){
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
        return queryString;
    }
    @AuraEnabled
    public static Approval_Details__c fetchApprovalDetailRecord(String recordId, String commaSeperatedFields){
        String queryString = 'Select Id, RecordTypeId, ' + commaSeperatedFields + ' From Approval_Details__c where Id = \'' + recordId + '\'';
        Approval_Details__c ad = new Approval_details__c();
        ad = Database.query(queryString );
        return ad;
    } 
    
    @AuraEnabled
    public static Id fetchADRecTypeId(String recordTypeLabel){
        Id recid = Schema.SObjectType.Approval_Details__c.getRecordTypeInfosByName().get(recordTypeLabel).getRecordTypeId(); 
        return recid;
    } 
    
    @AuraEnabled
    public static Approval_Details__c fetchParentCaseId(String ADId){
        Approval_Details__c ADRec = new Approval_Details__c();
        ADRec = [select Name,Related_To__c,Related_To__r.recordtype.developername from Approval_Details__c where id=: Id.valueOf(ADId) limit 1];
        return ADRec;
    }
    
    @AuraEnabled
    public static Account fetchAccountDetails(String accRecordId){
        Account acc = [Select Name,Type,Credit_Check_Comments__c,
                       Credit_Check_Type__c,OwnerId,Credit_Check_Status__c,Credit_Check_Date__c
                       from Account
                       where id =: Id.ValueOf(accRecordId)];
        return acc;
    } 
    
    @AuraEnabled
    public static String fetchControllingPLValues(){
        String selectOptions = '';
        Schema.DescribeFieldResult fieldResult = Approval_Details__c.Case_Record_Type__c.getDescribe();
        List<Schema.PicklistEntry> PLE = fieldResult.getPicklistValues();
        if(PLE != null)
            selectOptions = json.serialize(PLE);
        return selectOptions;
    }
    
    @AuraEnabled
    public static String fetchDependentPLValues(){
        String selectOptions = '';
        Schema.DescribeFieldResult fieldResult = Approval_Details__c.Approval_Status__c.getDescribe();
        List<Schema.PicklistEntry> PLE = fieldResult.getPicklistValues();
        if(PLE != null)
            selectOptions = json.serialize(PLE);
        return selectOptions;
    }

    @AuraEnabled(cacheable=true)
    public static list <ADWrapper> fetchApprovalDetails(String caseId) {
        system.debug('caseId : '+caseId);
        List<ADWrapper> ADWrapperList = new List<ADWrapper>();
        for(Approval_Details__c eachAD : [Select id, Related_To__c, Related_To__r.RecordType.Name, Name, Approval_Request__c, 
                                          Approval_Details_Description__c, Approval_Status__c, Case_Record_Type__c, AKAM_Modified_Date__c, 
                                          Business_Justification__c,Approval_Requested_By__r.name,lastmodifieddate from Approval_Details__c 
                                          where Related_To__c =: Id.valueOf(caseId) order by CreatedDate asc])
        {
            String truncatedDesc = '';
            if(eachAD.Approval_Details_Description__c != null){
                truncatedDesc = eachAD.Approval_Details_Description__c;
            }
            String lastModifiedDateString = (String.valueOf(eachAD.lastmodifieddate)).substring(0,10);
            if(!String.isEmpty(truncatedDesc) && truncatedDesc.length() >= 200)
                truncatedDesc = truncatedDesc.substring(0,200);
            ADWrapper ADwrap = new ADWrapper();
            ADwrap.ADRec = eachAD;
            /*ADwrap.ADname = '['+eachAD.Name+']' + ' | [' + eachAD.Approval_Requested_By__r.name + '] | [' + eachAD.Approval_Status__c+']';
            if((eachAD.Related_To__r.RecordType.Name == 'Order Approval-Deal Desk' || eachAD.Related_To__r.RecordType.Name == 'Order Approval-Escalations') && eachAD.Business_Justification__c != null)
                ADwrap.ADname += ' | '+'[Business Justification: '+eachAD.Business_Justification__c+']. ';*/
            
            //CHanges for ANkita
            ADwrap.ADname = eachAD.Name + ' | Status: ' + eachAD.Approval_Status__c + ' | Requested By: ' + eachAD.Approval_Requested_By__r.name;
            //ADwrap.ADname = eachAD.Name + ' | Requested By: ' + eachAD.Approval_Requested_By__r.name + ' | Status: ' + eachAD.Approval_Status__c;
            ADwrap.ADname += ' | Last Modified Date: '+lastModifiedDateString+' | Request Description: '+truncatedDesc+'. ';
            ADWrapperList.add(ADwrap);
        }
        system.debug('ADWrapperList : '+ADWrapperList);
        return ADWrapperList;
    }
    
    @AuraEnabled
    public static List<String> fetchStatusList() {
        List<String> statusList= new List<String>();
        statusList.add('--None--');
        Schema.DescribeFieldResult fieldResult = Approval_Details__c.Approval_Status__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            statusList.add(pickListVal.getLabel());
        }     
        return statusList;
    }
    
    @AuraEnabled
    public static String updateRecords(List<String> recordIdList, String statusValue) {
        String returnMessage = '';
        String oErrorMsg = '';
        String oErrorRecords = '';
        List<Id> approvalDetailsIdList = new List<Id>();
        List<Approval_Details__c> updateRecordList = new List<Approval_Details__c>();
        Integer successCount = 0;
        Integer errorCount = 0;
        String successMsg = '';
        String errorMsg = '';
        approvalDetailsIdList.addAll(recordIdList);
        for(Approval_Details__c updatedRecord : [Select id, Name, Approval_Status__c 
                                                 from Approval_Details__c 
                                                 where id IN: approvalDetailsIdList]){
                                                     updatedRecord.Approval_Status__c = statusValue;
                                                     updateRecordList.add(updatedRecord);
                                                 }  
        Database.SaveResult[] srList = Database.update(updateRecordList, false);
        for (Database.SaveResult sr: srList) 
        {
            if (sr.isSuccess()) {
                successCount++;
                system.debug('Successfully updated the status'+sr.getId());
                successMsg = '';
            } 
            else {
                errorMsg = '';
                errorCount++;
                oErrorMsg = '';
                for (Database.Error err: sr.getErrors()) {
                    // add Error message to oErrorMsg list and return the list
                    oErrorMsg = err.getStatusCode() + ': '+err.getMessage();
                    oErrorMsg = oErrorMsg.remove('FIELD_CUSTOM_VALIDATION_EXCEPTION: ');
                    system.debug('oErrorMsg : '+oErrorMsg);
                }
            }
        }
        for(integer i=0; i<srList.size(); i++){
            if(!srList[i].isSuccess()){
                oErrorRecords+= updateRecordList[i].Name+':';
                for(integer j=0;j<srList[i].getErrors().size();j++){
                    oErrorRecords+= srList[i].getErrors()[j].getMessage()+'\n';
                }
            }
        }
        if(successCount > 0)
            successMsg+=successCount+' Record(s) updated successfully. ';
        if(errorCount > 0)
            errorMsg+=errorCount+' Records(s) failed.\n'+oErrorRecords.removeEnd(',');
        //errorMsg+=errorCount+' Records(s) '+oErrorRecords.removeEnd(',')+' failed. '+'['+oErrorMsg+']';
        returnMessage = successMsg+'\n&&'+errorMsg;
        return returnMessage;
    }    
    
    @AuraEnabled
    public static String getIconName(String sObjectName){
        String u;
        List<Schema.DescribeTabSetResult> tabSetDesc = Schema.describeTabs();
        List<Schema.DescribeTabResult> tabDesc = new List<Schema.DescribeTabResult>();
        List<Schema.DescribeIconResult> iconDesc = new List<Schema.DescribeIconResult>();
        
        for(Schema.DescribeTabSetResult tsr : tabSetDesc) { tabDesc.addAll(tsr.getTabs()); }
        for(Schema.DescribeTabResult tr : tabDesc) {
            if( sObjectName == tr.getSobjectName() ) {
                system.debug('tr Custom : '+tr.isCustom());
                if( tr.isCustom() == true ) {
                    iconDesc.addAll(tr.getIcons());
                } else {
                    u = 'standard:' + sObjectName.toLowerCase();
                }
            }
        }
        for (Schema.DescribeIconResult ir : iconDesc) {
            if (ir.getContentType() == 'image/svg+xml'){
                u = 'custom:' + ir.getUrl().substringBetween('custom/','.svg').substringBefore('_');
                break;
            }
        }
        return u;
    }
    
    @AuraEnabled        
    public static List<String> fetchOARecordTypes(){
        //Stores default Record type
        string Default_returnRecType;
        //Set of all Rec types
        Set<string> allRecTypes = new Set<string>();
        //List of all Rec types used to return to Lightning controller
        List<String> allRecTypes_List= new List<string>();
        
        // For getting default Rec type
        for(Schema.RecordTypeInfo eachRecType : Schema.SObjectType.Case.getRecordTypeInfosById().values()){
            if(eachRecType.isDefaultRecordTypeMapping()){
                Default_returnRecType = eachRecType.getName();
                break;
            }
        }
        //Adding default Rec type to Set in first position
        //allRecTypes.add(Default_returnRecType);
        
        //Adding remaining Rec types to the set 
        for(RecordTypeInfo rt : case.SObjectType.getDescribe().getRecordTypeInfos()){
            if(rt.getName() != 'Master' && rt.isActive() == true && rt.isAvailable() == true ){
                if(rt.getName().contains('Order Approval-'))
                    allRecTypes.add(rt.getName());
            }
            
        }
        //converting set of Rec types into a list of Rec types
        allRecTypes_List.addAll(allRecTypes);
        return allRecTypes_List;
    }
    
    @AuraEnabled
    public static Id fetchRecTypeId(String recordTypeLabel){
        Id recid = Schema.SObjectType.Case.getRecordTypeInfosByName().get(recordTypeLabel).getRecordTypeId(); 
        return recid;
    } 
    
    @AuraEnabled
    public static Order_Approval__c fetchOADetails(String OAId){
        try{
            Order_Approval__c OA = [Select id,Associated_Opportunity__r.AccountId, Associated_Opportunity__c from Order_Approval__c where id=:OAId limit 1]; 
            return OA;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    @AuraEnabled
    public static Case createOACase(String OAId, String caseRecordType, String isAssignUsingRule){
       try{
            Order_Approval__c OA = [Select id,Associated_Opportunity__r.AccountId, Associated_Opportunity__c from Order_Approval__c where id=:OAId limit 1]; 
            Case newOACase = new Case();
            newOACase.RecordTypeId = Id.ValueOf(caseRecordType);
            newOACase.Order_Approval__c = OA.Id;
            newOACase.AccountId = OA.Associated_Opportunity__r.AccountId;
            newOACase.Opportunity__c = OA.Associated_Opportunity__c;
            newOACase.Case_Assignment_Using_Active_Rules__c = true;
            insert newOACase;
            return newOACase;
        }catch(Exception e){
            throw new AuraHandledException(CommonUtilClass.ExtractValidationExMsg(e)); 
        }
    }
    
    @AuraEnabled
    public static Case closeCase(String caseRecId,String closeStatus)
    {
        Case c = [Select id,Status,RecordTypeId from Case where Id = :caseRecId limit 1]; 
        UserRecordAccess ura = [SELECT RecordId, HasEditAccess FROM UserRecordAccess WHERE UserId =: userinfo.getUserId() AND RecordId =:caseRecId limit 1];
        String exceptionMessage = '';
        if(c != NULL)
        {
            c.Status = closeStatus;
            if(closeStatus == 'Closed-Insufficient Information'){
                c.Validation_Override__c = true;
            }
        }
        try
        {
            system.debug('HAS EDIT ACCESS  :'+ura.HasEditAccess);
            if(!ura.HasEditAccess){
                exceptionMessage = 'You do not have permission to close the case. Please contact Case Owner/Approver';
                throw new AuraHandledException(exceptionMessage);
            }
            else{
                update c;
            }
        }
        catch(Exception e)
        {
            if(String.isBlank(exceptionMessage))
                throw new AuraHandledException(CommonUtilClass.ExtractValidationExMsg(e));
            else
                throw new AuraHandledException(exceptionMessage);
        }
        
        return c;
    }
    
    @AuraEnabled
    public static Case reopenCase(Case caseR,String reason)
    {
        return CaseTriggerClass_OA_WithoutSharing.reopenCase(caseR,reason);
    }
    
    @AuraEnabled
    public static Map<String, String> getOARecordTypes(){
        try{
            Map<String, String> mRecTypeIdLabel = new Map<String, String>();
            List<Schema.RecordTypeInfo> recordtypes = Case.SObjectType.getDescribe().getRecordTypeInfos();
            for(RecordTypeInfo rt : recordtypes){
                if(rt.getName().contains('Order Approval-') && !rt.getName().equalsIgnoreCase('Order Approval-Escalations') && rt.isActive() && rt.isAvailable())
                    mRecTypeIdLabel.put(rt.getRecordTypeId(), rt.getName());
            }
            return mRecTypeIdLabel;
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Boolean checkEscalationAccess(){
        Map<String, String> mRecTypeIdLabel = new Map<String, String>();
        Boolean hasEscalationAccess = false;
        List<Schema.RecordTypeInfo> recordtypes = Case.SObjectType.getDescribe().getRecordTypeInfos();
        for(RecordTypeInfo rt : recordtypes){
            if(rt.getName().equalsIgnoreCase('Order Approval-Escalations') && rt.isActive() && rt.isAvailable())
                hasEscalationAccess = true;
        }
        return hasEscalationAccess;
    }
    
    @AuraEnabled
    public static List<String> pickilstReopenReasonCode(){
        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = Case.Re_open_Reason_Code__c.getDescribe();
        List<Schema.PicklistEntry> pList = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry p: pList) {
            options.add(p.getLabel());
        }
        return options;
    }
    
    @AuraEnabled
    public static void saveToCase(String caseId, List<String> adList){
        String caseFinalApprovalNotes = '';
        List<Id> adIdList = new List<Id>();
        try{
            for(String eachId : adList){
                adIdList.add(Id.valueOf(eachId));
            }
            
            for(Approval_Details__c eachAD : [Select id, Approver_Notes__c from Approval_Details__c where id in: adIdList 
                                                order by CreatedDate desc])
            {
                if(eachAD.Approver_Notes__c != null)
                    caseFinalApprovalNotes += eachAD.Approver_Notes__c+'\n';
            }
            
            //Case updateCase = new Case(Id = Id.valueOf(caseId));
            Case updateCase = [Select id, Final_Approval_Notes__c from case where id =: Id.valueOf(caseId)];
            if(updateCase.Final_Approval_Notes__c != null)
                updateCase.Final_Approval_Notes__c = caseFinalApprovalNotes+'\n'+updateCase.Final_Approval_Notes__c;
            else
                updateCase.Final_Approval_Notes__c = caseFinalApprovalNotes;
            update updateCase;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Boolean areAnyRelatedOACasesPending(String caseId) {
        return CaseTriggerClass_OA_WithoutSharing.areAnyRelatedOACasesPending(caseId);
    }
}