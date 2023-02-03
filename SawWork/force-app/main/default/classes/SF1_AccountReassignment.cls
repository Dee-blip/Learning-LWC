/**
    History

        --Developer         --Date          --Description
        Nagaraj Desai       19 Jan 2018       Created this Class as part of MOB-360
        Nagaraj Desai       27 Jan 2018       Updated this Class as part of MOB-337
 */
public with sharing class SF1_AccountReassignment {

        public static Map<String,String> resultSetCustom(Boolean errorOccured, String returnMessage, String accReassignId, String accountDetails) {

                Map<String,String> mapObject = new Map<String,String>();
                if(errorOccured != null) {
                        mapObject.put('errorOccured', String.valueOf(errorOccured));
                }
                if(returnMessage != null) {
                        mapObject.put('returnMessage', returnMessage);
                }
                if(accReassignId != null) {
                        mapObject.put('accReassignId', accReassignId);
                }
                if(accountDetails != null) {
                        mapObject.put('accountDetails', accountDetails);
                }

                return mapObject;
        }

        public static Map<String,String> initialValuesSF1(Boolean isBusinessOpsUser, String pendingAccountReassignmentDetails, String accountDetails, String pickListValues) {

                Map<String,String> mapObject = new Map<String,String>();
                if(isBusinessOpsUser != null) {
                        mapObject.put('isBusinessOpsUser', String.valueOf(isBusinessOpsUser));
                }
                if(pendingAccountReassignmentDetails != null) {
                        mapObject.put('pendingAccountReassignmentDetails', pendingAccountReassignmentDetails);
                }
                if(accountDetails != null) {
                        mapObject.put('accountDetails', accountDetails);
                }
                if(accountDetails != null) {
                        mapObject.put('pickListValues', pickListValues);
                }

                return mapObject;
        }

        private static String loadPicklistValues(String sobjectName, String picklistFieldName) {
                return GSMLite_UtilClass.populatePickListWithLabelAndValues(sobjectName, picklistFieldName);
        }

        private static String getAccountDetails(String accountId) {
                Account accountDetails = [SELECT Id, Name, OwnerId, Owner.Name, Owner.Alias, Account_Status__c, Account_Owner_Alias__c FROM Account WHERE Id =: accountId ];
                return JSON.serialize(accountDetails);
        }

        private static String isPendingAccountReassignment(String accountId) {
                Id pendingAccountReassignmentId = AccountReassignmentInterfaceClass.getPendingReassignmentRequestId(Id.valueOf(accountId));
                if(pendingAccountReassignmentId != null) {
                        return JSON.serialize(resultSetCustom(true, AccountReassignmentDataClass.getCustomSettings('Error : Prevent Duplicates'), pendingAccountReassignmentId, null));
                }
                return null;
        }

        private static Boolean isFieldUpdatable() {
                return Schema.sObjectType.Account_Reassignment__c.fields.Reassign__c.isUpdateable();
// System.DEBUG('Accessible: ' + Schema.sObjectType.Account_Reassignment__c.fields.Reassign__c.isAccessible());
// System.DEBUG('Updatable: ' + Schema.sObjectType.Account_Reassignment__c.fields.Reassign__c.isUpdateable());
        }

        @AuraEnabled
        public static String getUIThemeDescription() {
                return GSMLite_UtilClass.getUIThemeDescription();
        }

        @AuraEnabled
        public static String getInitialValues(String sobjectName, String picklistFieldName, String accountId) {
                return JSON.serialize(initialValuesSF1(isFieldUpdatable(), isPendingAccountReassignment(accountId), getAccountDetails(accountId), loadPicklistValues(sobjectName, picklistFieldName)));
        }

        @AuraEnabled
        public static String reassignAccount(String accountId, String assignTo, String reasonCode, String reasonForChange, Boolean reassignFlag) {

                AccountReassignmentInterfaceClass accReassignVar = new AccountReassignmentInterfaceClass(Id.valueOf(accountId));
                AccountReassignmentInterfaceClass.ResultSetCustom tempReturnVal = new AccountReassignmentInterfaceClass.ResultSetCustom();

                accReassignVar.accReassign.Assign_To__c = assignTo;
                accReassignVar.accReassign.Reason_Code__c = reasonCode;
                accReassignVar.accReassign.Reason_for_Change__c = reasonForChange;
                if(isFieldUpdatable()) {
                        accReassignVar.accReassign.Reassign__c = reassignFlag;
                }

                PageReference pg = accReassignVar.save();
                tempReturnVal = (AccountReassignmentInterfaceClass.ResultSetCustom)JSON.deserialize(accReassignVar.sf1ReturnMessageJSON, AccountReassignmentInterfaceClass.ResultSetCustom.Class);
                if(tempReturnVal.errorOccured == false) {
                        return JSON.serialize(resultSetCustom(tempReturnVal.errorOccured, tempReturnVal.returnMessage, String.valueOf(accReassignVar.accReassign.Id), getAccountDetails(accountId)));
                }

                return JSON.serialize(resultSetCustom(tempReturnVal.errorOccured, tempReturnVal.returnMessage, null, null));
        }
        @AuraEnabled
        public static String overrideCutOffSF1(String accountReassignmentID) {
                AccountReassignmentEntension accReassignObject = new AccountReassignmentEntension(Id.valueOf(accountReassignmentID));
                PageReference pg = accReassignObject.overrideCutOff();
                return accReassignObject.sf1ReturnMessageJSON;
        }

        public static Map<String,String> reassignableDataWrapper(String myApprovalList, String delegatedApprovalList, String rowsToDisplay) {
                Map<String,String> mapObject = new Map<String,String>();

                if(myApprovalList != null) {
                        mapObject.put('myApprovalList', myApprovalList);
                }
                if(delegatedApprovalList != null) {
                        mapObject.put('delegatedApprovalList', delegatedApprovalList);
                }
                if(rowsToDisplay != null) {
                        mapObject.put('rowsToDisplay', rowsToDisplay);
                }

                return mapObject;
        }
        @AuraEnabled
        public static String getReassignableData() {
                AccountMovesPendingRequestController accountMovesObject = new AccountMovesPendingRequestController('Theme4d');
                System.DEBUG('Data from SF1: ' + accountMovesObject.my_items_to_approve);
                Map<String,String> returnDataJSON = reassignableDataWrapper(JSON.serialize(accountMovesObject.my_items_to_approve), JSON.serialize(accountMovesObject.del_items_to_approve), String.valueOf(accountMovesObject.rowNum));
                return JSON.serialize(returnDataJSON);
        }


        public static Map<String,String> reassignmentResults(String returnMessage, String returnDataJSON) {

                Map<String,String> mapObject = new Map<String,String>();

                if(returnMessage != null) {
                        mapObject.put('returnMessage', returnMessage);
                }
                if(returnDataJSON != null) {
                        mapObject.put('returnDataJSON', returnDataJSON);
                }

                return mapObject;
        }
        @AuraEnabled
        public static String reassignMultipleApprovals(List<String> selectedIds, String reassignTo) {
                AccountMovesPendingRequestController accountMovesObject = new AccountMovesPendingRequestController('Theme4d');
                accountMovesObject.userID = reassignTo;
                for(String eachId : selectedIds) {
                        accountMovesObject.massApproveRejectIdSet.add(eachId);
                }
                PageReference temp = accountMovesObject.massReassignRequests();
                return JSON.serialize(reassignmentResults(JSON.serialize(temp.getParameters()), getReassignableData()));
        }
        @AuraEnabled
        public static String approveMultipleApprovals(List<String> selectedIds, String userComment) {
                AccountMovesPendingRequestController accountMovesObject = new AccountMovesPendingRequestController('Theme4d');
                accountMovesObject.approveRejectComment = userComment;
                for(String eachId : selectedIds) {
                        accountMovesObject.massApproveRejectIdSet.add(eachId);
                }
                PageReference temp = accountMovesObject.approveSelected();
                return JSON.serialize(reassignmentResults(JSON.serialize(temp.getParameters()), getReassignableData()));
        }
        @AuraEnabled
        public static String rejectMultipleApprovals(List<String> selectedIds, String userComment) {
                AccountMovesPendingRequestController accountMovesObject = new AccountMovesPendingRequestController('Theme4d');
                accountMovesObject.approveRejectComment = userComment;
                for(String eachId : selectedIds) {
                        accountMovesObject.massApproveRejectIdSet.add(eachId);
                }
                PageReference temp = accountMovesObject.rejectSelected();
                return JSON.serialize(reassignmentResults(JSON.serialize(temp.getParameters()), getReassignableData()));
        }

}