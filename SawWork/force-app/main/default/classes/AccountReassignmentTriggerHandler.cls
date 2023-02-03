public without sharing class AccountReassignmentTriggerHandler extends ApexTriggerHandlerAbstractClass {

	public override void beforeInsertBeforeUpdateTrigger(){

		/*List<Account_Reassignment__c> arTriggerNew = (List<Account_Reassignment__c>)newList;
		Map<Id,Account_Reassignment__c> arTriggerOldMap = (Map<Id,Account_Reassignment__c>)oldMap;

		AccountReassignmentInterface accReassignObject=new AccountReassignmentInterfaceClass(arTriggerNew, Trigger.isInsert, Trigger.isBefore, arTriggerOldMap);
     	accReassignObject.doService();

     	for (Account_Reassignment__c ar : arTriggerNew)
	    	if(ar.Reassign__c)
	    		ar.Approval_Level__c = 'Reassignment Approved';

     	if (Trigger.isUpdate) {
	        for (Account_Reassignment__c ar : arTriggerNew) {
	            if (ar.Approval_Level__c !=  arTriggerOldMap.get(ar.id).Approval_Level__c && ar.Approval_Level__c == 'Reassignment Approved') {
	                AccountReassignmentInterfaceClass.accept(ar);
	            }
	        }
	    }*/

	}

	public override void afterInsertAfterUpdateTrigger(){

		/*List<Account_Reassignment__c> arTriggerNew = (List<Account_Reassignment__c>)newList;
		Map<Id,Account_Reassignment__c> arTriggerOldMap = (Map<Id,Account_Reassignment__c>)oldMap;

		AccountReassignmentInterface accReassignObject=new AccountReassignmentInterfaceClass(arTriggerNew, Trigger.isInsert, Trigger.isBefore, arTriggerOldMap);
     	accReassignObject.doService();

     	Map<String,AccountReassignmentInterfaceClass.ReasonCodeSettings> accReasonCodeSettingsmap =  AccountReassignmentInterfaceClass.getAccountReasonCodeSettings();

     	List<Id> requestIds = new List<Id>();
		Set<String> criteriaFields = new Set<String>{'Reassign_status__c','Reassign__c'};

		List<Id> noApprovalRequiredList = new List<Id>();

		for (Account_Reassignment__c req : arTriggerNew) {
		    if (req.Reason_Code__c != null) {
		        String reasonCode = req.Reason_Code__c.replace(' ','_');
		        reasonCode = reasonCode.replace('-','_');
		        
		        AccountReassignmentInterfaceClass.ReasonCodeSettings reasonCodeSettings = accReasonCodeSettingsmap.get(reasonCode);
		        if ((Trigger.isInsert && req.Reassign_status__c=='Approval Pending' && !req.Reassign__c) ||
		            (Trigger.isUpdate && Util.hasChanges(criteriaFields,req,arTriggerOldMap.get(req.id)) && req.Reassign_status__c=='Approval Pending' && !req.Reassign__c))
		        {
		            if (reasonCodeSettings.approvalRequired) {
		                /*if (req.Requesting_User__c == req.Account_Owner_RSM__c && req.Requesting_User__c == req.Assign_To_User_RSM__c && req.Reason_Code__c == 'AQL Reassignment') {
		                    noApprovalRequiredList.add(req.id);
		                }*/
		                //else
		                /*requestIds.add(req.id);
		            } else {
		                noApprovalRequiredList.add(req.id);
		            }
		        }
		    }
		}

		if (requestIds.size() > 0)
		    AccountReassignmentInterfaceClass.submitForApproval(requestIds);

		if (noApprovalRequiredList.size() > 0)
		    AccountReassignmentInterfaceClass.noApprovalRequired(noApprovalRequiredList);*/
	}

	public override void beforeDeleteBeforeUndeleteTrigger(){

	}

	public override void afterDeleteAfterUndeleteTrigger(){

	}

}