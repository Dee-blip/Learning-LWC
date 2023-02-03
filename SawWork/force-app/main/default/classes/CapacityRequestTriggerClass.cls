//Class Added as part of SFDC-7368
public class CapacityRequestTriggerClass {
	public static boolean sendEmailFlag = true;

	public static void updatecpallocationCapacity(List < Id > cprids, List < Capacity_Request__c > newList) {
		List < Capacity_Allocation__c > cpAlloc = new List < Capacity_Allocation__c > ();
		for (Capacity_Request__c cpr: [select id, (select id, Requested_Capacity__c, Approved_Capacity__c from Capacity_Allocations__r) from Capacity_Request__c where id in :cprids]) {
			for (Capacity_Allocation__c ca: cpr.Capacity_Allocations__r) {
				if (ca.Requested_Capacity__c != ca.Approved_Capacity__c) {
					ca.Approved_Capacity__c = ca.Requested_Capacity__c;
					cpAlloc.add(ca);
				}
			}
		}
		if (!cpAlloc.isEmpty()) {
			try {
				update cpAlloc;
			}
			catch(Exception ex) {
				Sawyer.saw(ex);
				newList[0].addError(ex.getMessage());
			}
		}
	}

	public static void reassignQueue(List <Capacity_Request__c> crList){
		String enhancedReviewQueueId = GsmUtilClass.getGSMSettingValue('Enhanced_Review_Queue');
		for(Capacity_Request__c cr : crList){
			cr.Assigned_To__c = enhancedReviewQueueId;
		}
	}

	public static void verifyUserAndSendEmail(List <Capacity_Request__c> crList, Set<Id> assigneeUserId){

		if(!sendEmailFlag){
			return;
		}
		List<Messaging.SingleEmailMessage> sendEmailList = new List<Messaging.SingleEmailMessage>();
		Id enhancedReviewQueueId = Id.valueOf(GsmUtilClass.getGSMSettingValue('Enhanced_Review_Queue'));
		Id pdgApproverQueueId = Id.valueOf(GsmUtilClass.getGSMSettingValue('CPR_Queue_Assignee_Id'));
		String pdgApproverPS = GsmUtilClass.getGSMSettingValue('PDG_Approver_Permission_set');
		Id dummyContactId = Id.valueOf(GsmUtilClass.getGSMSettingValue('Dummy_Contact_ID'));

		Set<Id> assigneeUserIdHavingPermissionSet = new Set<Id>();
		for(PermissionSetAssignment psa : [Select id, AssigneeId from PermissionSetAssignment where PermissionSetId = :pdgApproverPS and AssigneeId IN :assigneeUserId]){
			assigneeUserIdHavingPermissionSet.add(psa.AssigneeId);
		}
		EmailTemplate et = [SELECT Id, DeveloperName, subject, HtmlValue FROM EmailTemplate WHERE DeveloperName = 'GSM_CPR_Submitted'][0];

		for(Capacity_Request__c cr : crList){
			if(assigneeUserIdHavingPermissionSet.contains(cr.Assigned_To__c) || cr.Assigned_To__c == enhancedReviewQueueId || cr.Assigned_To__c == pdgApproverQueueId){
				Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
				mail.setTargetObjectId(dummyContactId);
				mail.setToAddresses(new List<Id>{cr.Assigned_To__c});
				mail.setTemplateId(et.id);
				mail.setSaveAsActivity(false);
				mail.setWhatId(cr.id);
				mail.setTreatTargetObjectAsRecipient(false); //This sfdc property stops sending email to targetobjectId //https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_email_outbound_single.htm
				sendEmailList.add(mail);
			}
			else{
				cr.addError('Capacity Request cannot be assigned to members outside the approver groups.');
			}
		}

		if(sendEmailList.size() > 0){
			Messaging.sendEmail(sendEmailList);
		}
		sendEmailFlag = false;
	}
}