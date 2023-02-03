/**
 * @description       : 
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             : 
 * @last modified on  : 08-24-2020
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 * Modifications Log 
 * Ver   Date         Author                               Modification
 * 1.0   08-24-2020   ChangeMeIn@UserSettingsUnder.SFDoc   Initial Version
**/
public without sharing class L2Q_GenericApprovalClass {
	public L2Q_GenericApprovalClass() {}
	private Static Map<String, Schema.SObjectField > schemaFieldMap;
	/* Begin Rajesh Kumar JIRA # SFDC-6378  */
	private static final String PAEStepName = GsmUtilClass.getGSMSettingValue('ApprovalHistory_Step2');
	private static final String PAEStepName2 = GsmUtilClass.getGSMSettingValue('ApprovalHistory_Step3');
	private static final Integer fieldLength = Error_Log__C.Error_Message__c.getDescribe().getLength();
	/* End Rajesh Kumar JIRA # SFDC-6378  */
	public class FieldDescriptor {
		public FieldDescriptor() {
			picklistValues = new List<String> ();
		}
		String fieldAPIName;
		String fieldLabel;
		Boolean isRequired;
		String fieldType;
		List<String> picklistValues;
		String value;
		String referenceFieldType;
		String helpText;
		String lookupFilterQuery;
	}

	public class FieldDescriptorWrapper {
		public FieldDescriptorWrapper() {
			listOfFieldDescriptors = new List<FieldDescriptor> ();
		}
		String actionType;
		Boolean displayCommentsSection;
		List<FieldDescriptor> listOfFieldDescriptors;
	}

	public static Set<Id> getValidApprovers(String groupId) {
		Set<Id> listOfGroupMembers = new Set<Id> ();
		String userType = Schema.SObjectType.User.getKeyPrefix();
		String groupType = Schema.SObjectType.Group.getKeyPrefix();
		for (GroupMember eachGroupMember: [Select Id, UserOrGroupId From GroupMember Where GroupId =: groupId]) {
			if (String.valueOf(eachGroupMember.UserOrGroupId).startsWith(userType)) {
				listOfGroupMembers.add(eachGroupMember.UserOrGroupId);
			} else if (String.valueOf(eachGroupMember.UserOrGroupId).startsWith(groupType)) {
				listOfGroupMembers.addAll(getValidApprovers(eachGroupMember.UserOrGroupId));
			}
		}
		return listOfGroupMembers;
	}

	@AuraEnabled
	public static Map<String, String> getApprovalsForSpecifiedRecordId(String recordId) {
		Map<String, String> returnValMap = new Map<String, String> ();
		try {
			String jsonData = GenericApprovalProcessController.getReassignableData(recordId);
			//return jsonData;
			returnValMap.put('jsonData', jsonData);
			Map<String, String> mapOfApprovalData = (Map<String, String> ) JSON.deserialize(jsonData, Map<String, String> .Class);
			// List<GenericApprovalProcessUtil.item_to_approve_wrapper> lst = (List<GenericApprovalProcessUtil.item_to_approve_wrapper>) JSON.deserialize(mapOfApprovalData.get('myApprovalList'), List<GenericApprovalProcessUtil.item_to_approve_wrapper>.Class); // Commented as part of  JIRA# SFDC-6340 since not required hide and unhide functionality
			Id currentLoggedInUserId = UserInfo.getUserId();
			Id currentLoggedInUserProfileId = UserInfo.getProfileId();
			Boolean availableForApproval = false;
			Set<Id> listOfValidApproverIds = new Set<Id> ();
			String userType = Schema.SObjectType.User.getKeyPrefix();
			String groupType = Schema.SObjectType.Group.getKeyPrefix();
			/**Begin Rajesh Kumar JIRA# SFDC-6340 */
			/*for(GenericApprovalProcessUtil.item_to_approve_wrapper eachApproval : lst) {
			    if(eachApproval.status == 'Pending' && eachApproval.OriginalActorId != null ) {
			        if(String.valueOf(eachApproval.OriginalActorId).startsWith(groupType)) {
			            listOfValidApproverIds = getValidApprovers(eachApproval.OriginalActorId);
			        }
			        else if(String.valueOf(eachApproval.OriginalActorId).startsWith(userType)) {
			            listOfValidApproverIds.add(Id.valueOf(eachApproval.OriginalActorId));
			        }
			        if(listOfValidApproverIds.contains(currentLoggedInUserId) || GSMSettings.getValue('HigherApproverProfileIds').contains(currentLoggedInUserProfileId)) {
			            availableForApproval = true;
			        }
			        returnValMap.put('userIds', JSON.serialize(listOfValidApproverIds));
			        break;
			    }
			}*/
			//commented above code to only check from ProcessInstanceWorkItem Which will give current users pending Approval at single point of time
			// Written below code to directly query pending approver.
			//Important Note : below code is only for showing action for current pending Approver existing change will be still there for bringing approval history data
			for (ProcessInstanceWorkitem pw: [Select Id, actorId, originalActorId from ProcessInstanceWorkitem where ProcessInstance.targetObjectId =: recordId]) {
				if (String.valueOf(pw.actorId).startsWith(groupType)) {
					listOfValidApproverIds = getValidApprovers(pw.actorId); // Please note as per previous code it has been considered that we can never go to more than 4 to 5 multiple approvers at a time so we may not face too Many SQOL error.
				} else {

					listOfValidApproverIds.add(pw.actorId);
				}
			}
			if (listOfValidApproverIds.contains(currentLoggedInUserId) || GSMSettings.getValue('HigherApproverProfileIds').contains(currentLoggedInUserProfileId)) {
				availableForApproval = true;
			}
			/**End Rajesh Kumar JIRA# SFDC-6340 */

			returnValMap.put('availableForApproval', String.valueOf(availableForApproval));
			returnValMap.put('themeDisplayed', UserInfo.getUiThemeDisplayed());
			return returnValMap;
		} catch (Exception e) {
			/* Begin Rajesh Kumar JIRA # SFDC-6378  */
			String error = e.getMessage() + ' #; ' + e.getStackTraceString();
			error = (error.length() > fieldLength) ? error.substring(1, fieldLength) : error;
			insert(new Error_log__c(Name = 'getApprovalsForSpecifiedRecordId', Class__c = 'L2Q_GenericApprovalClass', Error_Message__c = error, RecordId__c = recordId));
			/* End Rajesh Kumar JIRA # SFDC-6378  */
			returnValMap.put('errorMessage', 'errorMessage : ' + String.valueOf(e));
			return returnValMap;
		}
	}

	@AuraEnabled
	public static string approveApprovalController(String recordId, String approvalComments, String approvalWorkItemId, Map<String, Object> mapOfFieldVsValue) {
		System.DEBUG('ND_ approveApprovalController: ' + mapOfFieldVsValue);
		//return 'Successful ' + recordId + ' ' + approvalComments + ' ' + approvalWorkItemId;
		try {
			String jsonData = GenericApprovalProcessController.approveItem(approvalWorkItemId, approvalComments, recordId, mapOfFieldVsValue);
			return jsonData;

		} catch (Exception e) {
			/* Begin Rajesh Kumar JIRA # SFDC-6378  */
			String error = e.getMessage() + ' #; ' + e.getStackTraceString();
			error = (error.length() > fieldLength) ? error.substring(1, fieldLength) : error;
			insert(new Error_log__c(Name = 'getApprovalsForSpecifiedRecordId', Class__c = 'L2Q_GenericApprovalClass', Error_Message__c = error, RecordId__c = recordId));
			/* End Rajesh Kumar JIRA # SFDC-6378  */
			return 'errorMessage : ' + String.valueOf(e);
		}
	}

	@AuraEnabled
	public static string rejectApprovalController(String recordId, String approvalComments, String approvalWorkItemId, Map<String, Object> mapOfFieldVsValue) {
		System.DEBUG('ND_ rejectApprovalController: ' + mapOfFieldVsValue);
		try {
			String jsonData = GenericApprovalProcessController.rejectItem(approvalWorkItemId, approvalComments, recordId, mapOfFieldVsValue);
			return jsonData;

		} catch (Exception e) {
			/* Begin Rajesh Kumar JIRA # SFDC-6378  */
			String error = e.getMessage() + ' #; ' + e.getStackTraceString();
			error = (error.length() > fieldLength) ? error.substring(1, fieldLength) : error;
			insert(new Error_log__c(Name = 'getApprovalsForSpecifiedRecordId', Class__c = 'L2Q_GenericApprovalClass', Error_Message__c = error, RecordId__c = recordId));
			/* End Rajesh Kumar JIRA # SFDC-6378  */
			return 'errorMessage : ' + String.valueOf(e);
		}
	}

	@AuraEnabled
	public static string reassignApprovalController(String recordId, String approvalComments, String reassignTo, String approvalWorkItemId) {
		//return 'Successful ' + recordId + ' ' + approvalComments + ' ' + approvalWorkItemId + ' ' + reassignTo;
		try {
			/* Begin Rajesh Kumar JIRA # SFDC-6378  */
			if (checkPAEstep(recordId)) {
				updateFCM(recordId, reassignTo);
			}
			/* End Rajesh Kumar JIRA # SFDC-6378  */
			String jsonData = GenericApprovalProcessController.reassignItem(approvalWorkItemId, reassignTo, recordId, approvalComments);
			return jsonData;

		} catch (Exception e) {
			/* Begin Rajesh Kumar JIRA # SFDC-6378  */
			String error = e.getMessage() + ' #; ' + e.getStackTraceString();
			error = (error.length() > fieldLength) ? error.substring(1, fieldLength) : error;
			insert(new Error_log__c(Name = 'getApprovalsForSpecifiedRecordId', Class__c = 'L2Q_GenericApprovalClass', Error_Message__c = error, RecordId__c = recordId));
			/* End Rajesh Kumar JIRA # SFDC-6378  */
			return 'errorMessage : ' + String.valueOf(e);
		}
	}

	public static List<FieldDescriptorWrapper> normalize(List<FieldDescriptorWrapper> fieldDescriptorObject, String recordId) {
		
		String pmaId = '';
		String sObjName = ((Id)recordId).getSObjectType().getDescribe().getName();
		List<Opportunity> oppty = new List<Opportunity>();
		if (sObjName == 'Opportunity') {
			oppty = [Select id, Partner_Marketing_Activity__c,Partner_Involved_Acct_Id__c From Opportunity where id =:recordId];
			if (oppty.size() > 0) {
				pmaId = oppty[0].Partner_Marketing_Activity__c;
			}
		}
		if (fieldDescriptorObject != null && fieldDescriptorObject.size() > 0) {
			for (FieldDescriptorWrapper eachFDW: fieldDescriptorObject) {
				for (FieldDescriptor eachFieldDescriptor: eachFDW.listOfFieldDescriptors) {
					Schema.DescribeFieldResult fieldResult = schemaFieldMap.get(eachFieldDescriptor.fieldAPIName).getDescribe();
					if (eachFieldDescriptor.fieldLabel == null) {
						eachFieldDescriptor.fieldLabel = String.valueOf(fieldResult.getLabel());
					}
					if (eachFieldDescriptor.fieldType == null) {
						eachFieldDescriptor.fieldType = String.valueOf(fieldResult.getType());
						// if(eachFieldDescriptor.fieldType == 'PICKLIST') {
						//     picklistValues = getPicklistValues();
						// }
					}
					if (eachFieldDescriptor.fieldType == 'REFERENCE' && eachFieldDescriptor.referenceFieldType == null) {
						for (Schema.SObjectType reference: fieldResult.getReferenceTo()) {
							eachFieldDescriptor.referenceFieldType = String.valueOf(reference.getDescribe().getName());
							break;
						}
						if (sObjName == 'Opportunity' && eachFieldDescriptor.fieldAPIName == 'Partner_Marketing_Activity__c') {
								eachFieldDescriptor.value = pmaId;
								if (eachFieldDescriptor.lookupFilterQuery != null) {
									eachFieldDescriptor.lookupFilterQuery += ' and Partner__c ='+'\''+oppty[0].Partner_Involved_Acct_Id__c + '\'';
								}

						}
					}
					
				}
				if (eachFDW.displayCommentsSection == null) {
					eachFDW.displayCommentsSection = true;
				}
			}
		}
		return fieldDescriptorObject;
	}

	@AuraEnabled
	public static Map<String, String> getInitialData(String sObjectName, String fieldOverrideMetadata, String recordId) {
		Map<String, String> mapOfReturnValues = new Map<String, String> ();
		if (fieldOverrideMetadata != null && fieldOverrideMetadata != '' && fieldOverrideMetadata != 'No Field Override Required') {
			try {

				String requiredMetadata = GSMSettings.getVerbose(fieldOverrideMetadata);
				List<FieldDescriptorWrapper> fieldDescriptorObject = (List<FieldDescriptorWrapper> ) JSON.deserialize(requiredMetadata, List<FieldDescriptorWrapper> .Class);
				schemaFieldMap = Schema.getGlobalDescribe().get(sObjectName).getDescribe().fields.getMap();
				fieldDescriptorObject = normalize(fieldDescriptorObject, recordId);
				mapofReturnValues.put('SpenderCheckboxMarked', 'false');
                //SFDC-8759
                if(sObjectName == 'SFDC_MDF__c'){

					SFDC_MDF__c fr = [ Select id, Spender_Confirmed__c from SFDC_MDF__c where id =: recordId][0];
					if (fr.Spender_Confirmed__c == true){
                        mapOfReturnValues.put('SpenderCheckboxMarked', 'true');
						for (FieldDescriptorWrapper eachFDW: fieldDescriptorObject) {
							for (FieldDescriptor eachFieldDescriptor: eachFDW.listOfFieldDescriptors) {
								Schema.DescribeFieldResult fieldResult = schemaFieldMap.get(eachFieldDescriptor.fieldAPIName).getDescribe();
								if (eachFieldDescriptor.fieldAPIName == 'Spender_Confirmed__c') {
									eachFieldDescriptor.isRequired  = Boolean.valueOf('false');
                                    //eachFieldDescriptor.value  = 'true';
                                    
								}
                        	}
                    	}
                    }
                    else{
                        mapofReturnValues.put('SpenderCheckboxMarked', 'false');
                    }
                        
    

				}
				mapOfReturnValues.put('fieldDescriptorWrapper', JSON.serialize(fieldDescriptorObject));
				if (UserInfo.getUserType().equals('PowerPartner')) {
					mapOfReturnValues.put('navigationPrefix', '/partners/');
					mapOfReturnValues.put('externalUser' ,'yes'); //SDFC 7024
					//system.debug(mapOfReturnValues);
				} else {
					mapOfReturnValues.put('navigationPrefix', '/');
				}
				/* Begin Rajesh Kumar JIRA # SFDC-6378  */ // Added one method argument String recordId to this method as well
				String whereClause = createPAElist(recordId);
				mapOfReturnValues.put('whereClause', whereClause);
				mapOfReturnValues.put('paeStep', String.valueOf(checkPAEstep(recordId)));
				/* End Rajesh Kumar JIRA # SFDC-6378  */

			} catch (Exception e) {
				/* Begin Rajesh Kumar JIRA # SFDC-6378  */
				String error = e.getMessage() + ' #; ' + e.getStackTraceString();
				error = (error.length() > fieldLength) ? error.substring(1, fieldLength) : error;
				insert(new Error_log__c(Name = 'getApprovalsForSpecifiedRecordId', Class__c = 'L2Q_GenericApprovalClass', Error_Message__c = error, RecordId__c = recordId));
				/* End Rajesh Kumar JIRA # SFDC-6378  */
				mapOfReturnValues.put('errorMessage', String.valueOf(e));
			}
		}
		return mapOfReturnValues;
	}

	/* Begin Rajesh Kumar JIRA # SFDC-6378  */
	public static String createPAElist(String recordId) {
		String whereClause = '';
		List<String> currentAcctorId = new List<String> ();
		for (ProcessInstanceWorkitem pw: [Select Id, actorId, originalActorId from ProcessInstanceWorkitem where ProcessInstance.targetObjectId =: recordId]) {
			currentAcctorId.add(pw.actorId);
		}
		System.debug('objName==#' + String.valueof(Id.valueOf(recordId).getSobjectType()).toLowerCase());
		if (checkPAEstep(recordId) && String.valueof(Id.valueOf(recordId).getSobjectType()).toLowerCase() == 'opportunity') {
			Opportunity opptyDetail = [Select id, FCM__c, Partner_Involved__c from Opportunity where Id =: recordId Limit 1];
			// for (Channel_Mapping__c cm: [SELECT Id, Partner_Name__c, Temp_PAE__c, PAE_ID__c, VAR_Manager_Team_Role__c, Partner_Name__r.Name, PAE_ID__r.Name FROM Channel_Mapping__c WHERE Active__c = true AND VAR_Manager_Status__c = 'Active'
			// 		and PAE_ID__r.Id !=: opptyDetail.FCM__c and Partner_Name__c =: opptyDetail.Partner_Involved__c
			// 	]) { //SFDC-8141
			for (Channel_Mapping__c cm: [SELECT Id, Partner_Name__c, Temp_PAE__c, PAE_ID__c, VAR_Manager_Team_Role__c, Partner_Name__r.Name, PAE_ID__r.Name FROM Channel_Mapping__c WHERE Active__c = true AND VAR_Manager_Status__c = 'Active'
					 and Partner_Name__c =: opptyDetail.Partner_Involved__c
				]) { //SFDC-8141
				whereClause = String.isNotBlank(cm.PAE_ID__c) ? whereClause + ',' + '\'' + cm.PAE_ID__c + '\'' : whereClause;
			}
		} else {
			for (String str: currentAcctorId) {
				whereClause = whereClause + ',' + '\'' + str + '\'';
			}
		}
		whereClause = String.isNotBlank(whereClause) ? '(' + whereClause.replaceFirst(',', '') + ')' : '';
		return whereClause;
	}

	public static void updateFCM(String opptyId, String fcmId) {
		Opportunity op = new Opportunity(Id = opptyId, FCM__c = fcmId, Validation_Override__c = true);
		update op;
	}

	public static boolean checkPAEstep(String opptyId) {
		Boolean ispaeStep = false;
		if (String.valueof(Id.valueOf(opptyId).getSobjectType()).toLowerCase() != 'opportunity') {
			return ispaeStep;
		}
		for (ProcessInstanceNode pi: [Select id, NodeStatus, ProcessNodeName from ProcessInstanceNode where ProcessInstance.targetObjectId =: opptyId ORDER BY CreatedDate DESC]) {
			if ((PAEStepName.contains(pi.ProcessNodeName) || PAEStepName2.contains(pi.ProcessNodeName)) && pi.NodeStatus.toLowerCase() == 'pending') {
				system.debug('NodeStatus-->' + pi.NodeStatus);
				system.debug('pi.ProcessNodeName' + pi.ProcessNodeName);
				ispaeStep = true;
				system.debug('PAE Step ' + ispaeStep);
				break;
			}
		}
		return ispaeStep;
	}
	/* End Rajesh Kumar JIRA # SFDC-6378  */
}