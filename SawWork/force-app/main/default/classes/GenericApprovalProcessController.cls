public with sharing class GenericApprovalProcessController {

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
        public static String getReassignableData(String targetRecordId) {
                GenericApprovalProcessUtil approvalObject = new GenericApprovalProcessUtil('Theme4d',targetRecordId);
                System.DEBUG('Data from GenericComponent: ' + approvalObject.my_items_to_approve);
                Map<String,String> returnDataJSON = reassignableDataWrapper(JSON.serialize(approvalObject.my_items_to_approve), JSON.serialize(approvalObject.del_items_to_approve), String.valueOf(approvalObject.rowNum));
                System.debug('JSON data :'+JSON.serialize(returnDataJSON));
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
        public static String reassignItem(String workItemId, String reassignTo, String sObjectRecordId, String comments) {
                System.DEBUG('workItemId: ' + workItemId + 'reassignTo: ' + reassignTo + 'sObjectRecordId: ' + sObjectRecordId + 'comments: ' + comments);
                GenericApprovalProcessUtil approvalObject = new GenericApprovalProcessUtil('Theme4d',sObjectRecordId);
                approvalObject.userID = reassignTo;
                approvalObject.approveRejectId = workItemId;
                String temp = approvalObject.reassignRequests(workItemId,reassignTo,comments);
                return temp;
        }

        @AuraEnabled
        public static String approveItem(String approveRejectId, String approveRejectComment, String sObjectRecordId, Map<String, Object> fieldDetails) {
                GenericApprovalProcessUtil approvalObject = new GenericApprovalProcessUtil('Theme4d',sObjectRecordId);
                approvalObject.approveRejectComment = approveRejectComment;
                approvalObject.approveRejectId = approveRejectId;
                String result = approvalObject.approveSelected(approveRejectId, approveRejectComment, fieldDetails, sObjectRecordId);
                return result;
        }

        @AuraEnabled
        public static String rejectItem(String approveRejectId, String approveRejectComment, String sObjectRecordId, Map<String, Object> fieldDetails) {
                
                //System.debug('rejectType :'+rejectType + '    :::::: sObjectRecordId :'+sObjectRecordId);
                GenericApprovalProcessUtil approvalObject = new GenericApprovalProcessUtil('Theme4d',sObjectRecordId);
                approvalObject.approveRejectComment = approveRejectComment;
                approvalObject.approveRejectId = approveRejectId;
                String result = approvalObject.rejectSelected( approveRejectId, approveRejectComment, fieldDetails, sObjectRecordId);
                return result;
        }

}