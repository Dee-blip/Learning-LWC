/**
 * @description       : 
 * @author            : Shivam Verma
 * @group             : 
 * @last modified on  : 08-25-2020
 * @last modified by  : Shivam Verma
 * Modifications Log 
 * Ver   Date         Author                                  
 * 1.0   08-24-2020   Added Debugs and roolback for failure   
**/
public class GenericApprovalProcessUtil {



        ApexPages.standardController stdController= null;
        public GenericApprovalProcessUtil(ApexPages.StandardController controller) {
                stdController=controller;
        }

        public list<item_to_approve_wrapper> my_items_to_approve { get; set; }
        public list<item_to_approve_wrapper> del_items_to_approve { get; set; }

        public Id approveRejectId {get; set;}
        public Set<Id> massApproveRejectIdSet {get; set;}
        public Set<Id> massReassignIdSet {get; set;}
        public Boolean showButtonsManageAll {get; set;}

        public List<User> userRecordList {get; set;} 
        public string searchString {get; set;} 

        public Boolean selectCheckbox {get; set;}
        public Integer limitCount;
        public Boolean showReAssignSection {get; set;}
        public Boolean showUserSearch {get; set;}
        public List<reAssign_approver_wrapper> userList {get; set;}
        public Id userID;
    
        public Map<Id,String> pIIdToPINMap;
        public Map<Id,ProcessInstanceNode> pNIdToNodemap;
        public Map<Id,Id> WiIdToPIIdMap;

        public Integer rowNum {get; set;}
        public integer messageCount;
        public boolean showApproveRejectMsg {get; set;}
        public boolean showReassignMsg {get; set;}
        private String pageID;
        private Boolean isTheme4d = false; 

		//Wrapper class to show all the table columns including Account Reassignment and Approval Request fields
        public class item_to_approve_wrapper {
                public item_to_approve_wrapper(String stepName,
                                                Id requestId,
                                                String submittedDate,
                                                String status,
                                                String comments,
                                                String originalActor,
                                                Id originalActorId,
                                               	String originalActorName,
                                                Id approvalid,
                                                Id approvalStepId,
                                              	Id lastActorId,
                                              	String lastActorName) {
                        this.requestName = stepName;
                        this.requestId = requestId;
                        this.submittedDate = submittedDate;
                        this.status = status;
                        this.comments = comments;
                        this.originalActor =originalActor;
                        this.originalActorId = originalActorId;
                        this.originalActorName = originalActorName;                            
                        this.approvalid =approvalid;
                        this.lastActorId = lastActorId;
                        this.lastActorName = lastActorName;
                        this.approvalStepId = approvalStepId;                           
                }
                public String requestName {get; set;}
                public Id requestId {get; set;}
                public String submittedDate { get; set; }
                public String status {get; set;}
                public Id approvalid {get; set;}
                public String originalActor {get; set;}
                public Id originalActorId {get; set;}
            	public String comments {get;set;}
            	public Id lastActorId {get; set;}
            	public String lastActorName {get;set;}
            	public String originalActorName {get;set;}
            	public Id approvalStepId {get; set;}
        }
    
        //Wrapper class to show the search User records and selected User for the Mass Reassign feature
        public class reAssign_approver_wrapper {
                public reAssign_approver_wrapper(String userName,Id userId)
                {
                        this.userId = userId;
                        this.userName = userName;
                }

                public Id userId {get; set;}
                public String userName {get; set;}
                public Boolean selectCheckBox {get; set;}
        }

        private void genricApprovalProcessUtilInit(Id targetRecordId) {
            
                System.DEBUG('Enter: ');
                my_items_to_approve = new list<item_to_approve_wrapper>();
                del_items_to_approve = new list<item_to_approve_wrapper>();
                selectCheckbox = false;
                showButtonsManageAll = true;
                showApproveRejectMsg = false;
                showReassignMsg = false;

                showReAssignSection = false;
                //pIIdToWIListMap = new Map<Id,List<ProcessInstanceWorkItem>>();
                pIIdToPINMap = new Map<Id,String>();
                pNIdToNodemap = new Map<Id,ProcessInstanceNode>();
                WiIdToPIIdMap = new Map<Id,Id>();

                //To redirect to the Detail page from homepage based on parameter
                if(!String.isEmpty(pageID))
                {
                        if(pageID.contains('detailPage'))
                        {
                                selectCheckbox = true;
                                showButtonsManageAll = false;
                        }
                }
                system.debug('Limit Count '+limitCount);
                List<User> deleagtedUserList  = [Select Id From User Where DelegatedApproverId  = :Userinfo.getUserId()];
                Set<Id> delegatedUserIds = new Set<Id>();
                Set<Id> userIDset = new Set<Id>();

                if(deleagtedUserList.size() > 0)
                {
                        for(User usr: deleagtedUserList)
                        {
                                userIDset.add(usr.Id);
                                delegatedUserIds.add(usr.Id);
                        }
                }

                //Adding the current user too
                userIDset.add(Userinfo.getUserId());


                List<ProcessInstanceWorkItem> piwiList = new List<ProcessInstanceWorkItem>();
                Map<Id,ProcessInstanceWorkItem> objectIdToPIWIMap = new Map<Id,ProcessInstanceWorkItem>();
                Map<Id,ProcessInstanceHistory> piHITToHistoryMap = new Map<Id,ProcessInstanceHistory>();

                //Get all Pending Approval Requests where Actor or Orginal Actor is logged in User and Request belongs to Account Reassignment Object
                //List<ProcessInstanceWorkItem> PIWIList = [select ActorId,Actor.Name,OriginalActorId,ProcessInstance.TargetObjectId,CreatedDate ,ProcessInstance.TargetObject.Name,ProcessInstance.TargetObject.type from ProcessInstanceWorkItem where ActorId IN :userIDset AND ProcessInstance.TargetObject.Type = 'Account_Reassignment__c' AND ProcessInstance.Status= 'Pending' Order by CreatedDate Desc Limit :limitCount];
                List<ProcessInstance> PIList =  [Select 
                                                        Status,
                                                        TargetObjectId,
                                                 	(Select Id,
                                                     		ActorId,
                                                     		Actor.Name,
                                                     		OriginalActorId,
                                                     		ProcessInstance.TargetObjectId,
                                                     		CreatedDate,
                                                     		ProcessInstance.TargetObject.Name,
                                                     		ProcessInstance.TargetObject.type 
                                                        From Workitems 
                                                        Where ActorId IN :userIDset ORDER BY CreatedDate DESC),
                                                        (Select Id, 
                                                                IsDeleted, 
                                                                LastActorId,
                                                         		LastActor.Name,
                                                                NodeStatus, 
                                                                ProcessInstanceId,
                                                                ProcessNodeId, 
                                                                ProcessNodeName 
                                                        From Nodes 
                                                        ORDER BY CreatedDate DESC) ,
                                                        (Select Id, 
                                                                StepStatus, 
                                                                OriginalActorId,
                                                         		OriginalActor.Name,
                                                                ActorId,
                                                                Actor.name, 
                                                                Comments, 
                                                                CreatedDate,
                                                                ProcessNodeId,
                                                                ProcessInstanceId,
                                                                ProcessNode.Name
                                                        From StepsAndWorkitems 
                                                        ORDER BY CreatedDate DESC)
                                                 From ProcessInstance p 
                                                 WHERE TargetObjectId =:targetRecordId 
                                                 Order by CreatedDate Desc];

                system.debug('List size '+PIList.size());

                for(ProcessInstance pi :PIList)
                {
                        for(ProcessInstanceNode pin: pi.Nodes) {
                                        pIIdToPINMap.put(pi.Id,pin.ProcessNodeName);
                                        pNIdToNodemap.put(pin.ProcessNodeId,pin);
                        }

                        for(ProcessInstanceWorkItem piWI : pi.Workitems)
                        {
                                WiIdToPIIdMap.put(piWI.Id,pi.Id);
                                piwiList.add(piWI);

                        }

                        for (ProcessInstanceHistory pH: pi.StepsAndWorkitems) {
                                piHITToHistoryMap.put(pH.ProcessInstanceId,pH);
                        }

                        if(pi.StepsAndWorkitems.size() > 0)
                        {
                                for(ProcessInstanceHistory piStep : pi.StepsAndWorkitems)
                                {
                                        WiIdToPIIdMap.put(piStep.Id,pi.Id);

                                        if (piStep.StepStatus == 'Started') {
                                                my_items_to_approve.add(new item_to_approve_wrapper(
                                                                        'Approval Request Submitted',
                                                                        null,
                                                                        piStep.CreatedDate.format(),
                                                                        piStep.StepStatus,
                                                                        piStep.comments,
                                                                        piStep.ActorId,
                                                                        piStep.OriginalActorId,
                                                    			piStep.OriginalActor.Name,
                                                                        piHITToHistoryMap.get(pi.Id).Id,
                                                    			piStep.Id,
                                                			piStep.ActorId,
                                                    			piStep.Actor.Name
                                                ));
                                        } 
                                        else {
                                                System.debug('pNIdToNodemap :'+pNIdToNodemap);
                                                System.debug('StepNodeId :'+piStep.ProcessNodeId);
                                                my_items_to_approve.add(new item_to_approve_wrapper(
                                                                        //(String)pNIdToNodemap.get(piStep.ProcessNodeId).ProcessNodeName,
                                                                        //(Id)pNIdToNodemap.get(piStep.ProcessNodeId).ProcessNodeId,
                                                                        piStep.ProcessNode.Name,
                                                                        (Id)piStep.ProcessNodeId,
                                                                        piStep.CreatedDate.format(),
                                                                        piStep.StepStatus,
                                                                        piStep.comments,
                                                                        piStep.ActorId,
                                                                        piStep.OriginalActorId,
                                                    			piStep.OriginalActor.Name,
                                                                        piHITToHistoryMap.get(pi.Id).Id,
                                                    			piStep.Id,
                                                			piStep.ActorId,
                                                    			piStep.Actor.Name
                                                ));
                                        }
                                }

                        }
                        
                }

        }

        public GenericApprovalProcessUtil(String fromWhere,String targetRecordId) {
                if(fromWhere == 'Theme4d') {
                  isTheme4d = true;
                }
                genricApprovalProcessUtilInit(targetRecordId);
        }

        public GenericApprovalProcessUtil(String targetRecordId) {
                genricApprovalProcessUtilInit(targetRecordId);
        }
        
        public String approveRejectComment {get; set;}

        public static String getConsolidatedErrors(Database.Error[] listOfErrors) {
                String errorMessage = '';
                for(Database.Error eachError : listOfErrors) {
                        errorMessage = errorMessage + eachError.getMessage() + '\n';
                }
                return errorMessage;                                                               
        }
        //Method to mass approve selected requests
        public String approveSelected(String approveRejectId, String approveRejectComment, Map<String, Object> fieldDetails, String sObjectRecordId){

                System.debug('SH : fieldDetails'+fieldDetails);
                Map<String,Set<Id>> stepNameToIDMap = new Map<String,Set<Id>>();

                system.debug(' List of Ids to approve '+approveRejectId + '  Comment '+approveRejectComment);
                if(approveRejectId != null)
                {
                        
                        String sobjectname = ((ID)sObjectRecordId).getSObjectType().getDescribe().getName();
                        Savepoint sp = Database.setSavepoint();
                        try {  
                                if(sobjectname == 'Opportunity') {
                                        System.debug('SH : Checking validation for Opportunity');
                                        String validation = '';

                                        //Remove -none-- from Map
                                        for(String s:fieldDetails.keySet()) {
                                                if ((String)fieldDetails.get(s) == '--None--') {
                                                        fieldDetails.remove(s);
                                                }
                                        }
                                        Opportunity currentOp = [SELECT Id, Channel_Manager__c, Channel_Manager__r.Partner_Group__c, Deal_Reg_Approval_Level__c FROM Opportunity WHERE Id = :sObjectRecordId];
                                        if(currentOp != null && currentOp.Deal_Reg_Approval_Level__c != null && currentOp.Deal_Reg_Approval_Level__c == 'First-Level Approved') {
                                                if(currentOp.Channel_Manager__c != null && currentOp.Channel_Manager__r.Partner_Group__c != null && currentOp.Channel_Manager__r.Partner_Group__c != 'PUBSEC VAR' && !fieldDetails.containsKey('Rebate_Justification__c')) {
                                                        validation += 'Rebate Justification';
                                                }
                                                System.debug('SH : Conditions :'+ fieldDetails.containsKey('Managed_By__c'));
                                                System.debug('SH : Conditions 2 :'+(String)fieldDetails.get('Managed_By__c') == 'Partner');
                                                System.debug('SH : Conditions 3 :'+ !fieldDetails.containsKey('Partner_Led_POC__c'));
                                                if (fieldDetails.containsKey('Managed_By__c') 
                                                        && (String)fieldDetails.get('Managed_By__c') == 'Partner'
                                                        && !fieldDetails.containsKey('Partner_Led_POC__c')) {
                                                                if(validation != '') {
                                                                        validation += ', ';
                                                                }
                                                                validation += 'Partner Led Trial';
                                                }
                                                System.debug('SH : Validation:'+validation);
                                                if(validation != '') {
                                                        validation += ' value(s) required before Approval';
                                                        return validation;
                                                }
                                        }
                                }

                                Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                                req.setComments(approveRejectComment);
                                req.setAction('Approve');
                                req.setNextApproverIds(new Id[] {});
                                req.setWorkitemId(approveRejectId);
                                Approval.ProcessResult result =  Approval.process(req);

                                if(result.isSuccess()) {
                                        String retVal = '';
                                        sobjectname = ((Id)sObjectRecordId).getSObjectType().getDescribe().getName();
                                        if(fieldDetails.size() >0) {
                                                 retVal = updateObject(fieldDetails, sObjectName, '', false, false, sObjectRecordId);
                                        }
                                        System.DEBUG('ND_ ' + retVal);
                                        if(retVal.contains('Failure')) {
                                                Database.rollback(sp);
                                                return  retVal;
                                        } else {
                                                return 'Successfully Accepted';
                                        }
                                }
                                else {
                                        return getConsolidatedErrors(result.getErrors());
                                }
                        } catch(Exception e) {
                                //System.debug('Exception :'+e.getMessage());
                                Database.rollback(sp); Error_Log__c el = new Error_Log__c(Name='GenericApprovalProcessUtil', Class__c='GenericApprovalProcessUtil', Error_Message__c=e.getMessage() , RecordId__c=sObjectRecordId);
                                insert el; List<Error_Log__c> errorLogs = new List<Error_Log__c>(); errorLogs.add(el); Sawyer.saw(errorLogs, 'GenericApprovalProcessUtil', 'GenericApprovalProcessUtil'); return e.getMessage();
                        }
                        
                } else {
                        return 'Error Occurred, contact System Administrator';
                }

        }

        //Method to mass reject the requests
        public String rejectSelected(String approveRejectId, String approveRejectComment, Map<String, Object> fieldDetails, String sObjectRecordId){

                Map<String,Set<Id>> stepNameToIDMap = new Map<String,Set<Id>>();
                System.debug('SH:fieldDetails '+fieldDetails);

                system.debug(' List of Ids to approve '+approveRejectId + 'Comment '+approveRejectComment);
                if(approveRejectId != null)
                {
                        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
                        req.setComments(approveRejectComment);
                        req.setAction('Reject');
                        req.setNextApproverIds(new Id[] {});
                        req.setWorkitemId(approveRejectId);
                        Savepoint sp = Database.setSavepoint();
                        try {
                                String sobjectname = ((Id)sObjectRecordId).getSObjectType().getDescribe().getName();
                                
                                Approval.ProcessResult result =  Approval.process(req);
                                //handleRejection(sObjectRecordId, rejectType);
                                
                                if(result.isSuccess()) {
                                        String retVal = '';
                                        if(fieldDetails.size() >0) {
                                                 retVal = updateObject(fieldDetails, sObjectName, '', false, false, sObjectRecordId);
                                        }
                                        System.DEBUG('ND_ ' + retVal);
                                        if(retVal.contains('Failure')) {
                                                Database.rollback(sp);
                                               return  retVal;
                                        } else {
                                                return 'Successfully Rejected';
                                        }
                                }
                                else {
                                        return getConsolidatedErrors(result.getErrors());
                                }
                        } catch(Exception e) {
                                //System.debug('Exception :'+e.getMessage());
                                Error_Log__c el = new Error_Log__c(Name='GenericApprovalProcessUtil', Class__c='GenericApprovalProcessUtil', Error_Message__c=e.getMessage() , RecordId__c=sObjectRecordId); insert el;
                                List<Error_Log__c> errorLogs = new List<Error_Log__c>(); errorLogs.add(el); Sawyer.saw(errorLogs, 'GenericApprovalProcessUtil', 'GenericApprovalProcessUtil'); return e.getMessage();
                        }
                } else { return 'Error Occurred, contact System Administrator'; }
        }

        /*public static void handleRejection(Id sObjectRecordId, String rejectionType) {

                /*String sobjectname = sObjectRecordId.getSObjectType().getDescribe().getName();
                System.debug('sobjectname :'+sobjectname);

                if (sobjectname == 'SFDC_MDF__c') {

                        String query = 'SELECT id, Status__c, Soft_Rejected_Date__c FROM SFDC_MDF__c WHERE Id = \'' + sObjectRecordId + '\'';
                        System.debug('query :'+query);
                        SFDC_MDF__c[] fundReq = Database.query(query);

                        System.debug('fundReq :'+fundReq);

                        if(fundReq.size() > 0){
                                fundReq[0].put('Status__c',rejectionType);
                                if (rejectionType == 'Rejected for Re-submit') {
                                        fundReq[0].put('Soft_Rejected_Date__c',System.today());
                                }
                                Database.update(fundReq[0]);
                                System.debug('Updated FR');
                        }
                } else if (sobjectname == 'SFDC_MDF_Claim__c') {
                        String query = 'SELECT id, Status__c, Soft_Rejected_Date__c FROM SFDC_MDF_Claim__c WHERE Id = \'' + sObjectRecordId + '\'';
                        SFDC_MDF_Claim__c[] fundClaim = Database.query(query);

                        if(fundClaim.size() > 0){
                                fundClaim[0].put('Status__c',rejectionType);
                                if (rejectionType == 'Rejected for Re-submit') {
                                        fundClaim[0].put('Soft_Rejected_Date__c',System.today());
                                }
                                Database.update(fundClaim[0]);
                        }
                }
        }*/

        //Method to mass reassign the requests
        public String reassignRequests(String workItemId, String assignToUserId,String reassignComment){

                system.debug('WorkItem Id '+workItemId +'AssignTouserId '+assignToUserId);

                List<ProcessInstanceWorkitem>  listWorkitemTemp = new List<ProcessInstanceWorkItem>();
                if(workItemId != null && assignToUserId != null)
                {     
                        List<ProcessInstanceWorkitem>  listWorkitem = new List<ProcessInstanceWorkitem>([select Id, ActorId, OriginalActorId, ProcessInstanceId from ProcessInstanceWorkitem where Id =:workItemId]);
                        if(listWorkitem.size() > 0 )
                        {
                                for(ProcessInstanceWorkitem pwi :listWorkitem)
                                {
                                        pwi.ActorId = assignToUserId;
                                        listWorkitemTemp.add(pwi);
                                }
                        }
                }

                try {
                        if(listWorkitemTemp.size() > 0)
                                update listWorkitemTemp;

                        return 'Successfully Reassigned';
                }
                catch(DmlException e) {
                        //System.debug('The following exception has occurred: ' + e.getMessage());
                        Error_Log__c el = new Error_Log__c(Name='GenericApprovalProcessUtil', Class__c='GenericApprovalProcessUtil', Error_Message__c=e.getMessage() , RecordId__c=workItemId); insert el;
                        List<Error_Log__c> errorLogs = new List<Error_Log__c>(); errorLogs.add(el); Sawyer.saw(errorLogs, 'GenericApprovalProcessUtil', 'GenericApprovalProcessUtil'); return 'Error Occurred, contact System Administrator';
                }

        }

        @AuraEnabled
        public static String updateObject(Map<String, Object> fieldDetails, String sObjectName, String recordTypeId, Boolean assignUsingActiveReassignmentRules, Boolean sendNotificationEmailToContact, String recId) {
                String returnVal;
                Schema.SObjectType sobjectType = Schema.getGlobalDescribe().get(sObjectName);
                Map<String, Schema.SObjectField> schemaFieldMap = sobjectType.getDescribe().fields.getMap();
                System.DEBUG('recordTypeId: ' + recordTypeId);
                System.DEBUG('assignUsingActiveReassignmentRules: ' + assignUsingActiveReassignmentRules);
                System.DEBUG('sendNotificationEmailToContact: ' + sendNotificationEmailToContact);
                try {
                        SObject sObj = Schema.getGlobalDescribe().get(String.valueOf(sObjectName)).newSObject();
                        sObj.put('Id',recId);
                        
                        for ( String fieldName : fieldDetails.keySet() ) {
                                Schema.DescribeFieldResult fieldResult = schemaFieldMap.get(fieldName).getDescribe();
                                String fieldType = String.valueOf(fieldResult.getType());
                                if(fieldDetails.get(fieldName) != null) {
                                        if(fieldType == 'DATE') {
                                                List<String> dateString =  String.Valueof(fieldDetails.get(fieldName)).split('-');
                                                sObj.put(fieldName, Date.newInstance(Integer.valueOf(dateString.get(0)), Integer.valueOf(dateString.get(1)), Integer.valueOf(dateString.get(2))));
                                        } else if(fieldType == 'DATETIME') {
                                                List<String> dateTimeSeparator =  String.Valueof(fieldDetails.get(fieldName)).split('T');
                                                List<String> dateString =  (dateTimeSeparator.get(0)).split('-');
                                                List<String> timeString =  (dateTimeSeparator.get(1)).split(':');
                                                sObj.put(fieldName, DateTime.newInstance(Integer.valueOf(dateString.get(0)), Integer.valueOf(dateString.get(1)), Integer.valueOf(dateString.get(2)), Integer.valueOf(timeString.get(0)), Integer.valueOf(timeString.get(1)), Integer.valueOf(timeString.get(2))));
                                        } else if(fieldType == 'DOUBLE' || fieldType == 'CURRENCY') {
                                                sObj.put(fieldName, Decimal.valueOf(String.Valueof(fieldDetails.get(fieldName))).setScale(fieldResult.getScale()));
                                        } else if(fieldType == 'INTEGER') {
                                                sObj.put(fieldName, Integer.valueOf(String.Valueof(fieldDetails.get(fieldName))));
                                        } else if(fieldType == 'BOOLEAN') {
                                                sObj.put(fieldName, Boolean.valueOf(fieldDetails.get(fieldName)));
                                        }else if(fieldType == 'CHECKBOX') {
                                                sObj.put(fieldName, Boolean.valueOf(fieldDetails.get(fieldName)));
                                        } 
                                         else {
                                                sObj.put(fieldName, String.valueOf(fieldDetails.get(fieldName)));
                                        }
                                }
                        }
                        if(assignUsingActiveReassignmentRules || sendNotificationEmailToContact) {
                                Database.DMLOptions dmo = new Database.DMLOptions();
                                if(assignUsingActiveReassignmentRules) {
                                        dmo.assignmentRuleHeader.useDefaultRule = true;
                                }
                                if(sendNotificationEmailToContact) {
                                        dmo.EmailHeader.triggerAutoResponseEmail = true;
                                }
                                sObj.setOptions(dmo);
                        }

                        update sObj;
                        returnVal = sObj.Id;
                }
                catch(Exception e) {
                        System.DEBUG(String.valueOf(e)); String error = String.valueOf(e).substringAfter('EXCEPTION,');
                        if(error.contains('Available')) { returnVal = 'Failure:' + error.remove(': []'); } else { returnVal = 'Failure:' + error.substringBefore(':').remove('&quot').remove(';'); }
                        //returnVal += String.valueOf(e);
                }
                return returnVal;
        }

}