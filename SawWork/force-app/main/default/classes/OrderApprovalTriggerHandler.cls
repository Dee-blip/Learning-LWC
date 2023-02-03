public without sharing class OrderApprovalTriggerHandler extends ApexTriggerHandlerAbstractClass {

	public override void beforeInsertBeforeUpdateTrigger(){
		List<Order_Approval__c> orderApprovalTriggerNew = (List<Order_Approval__c>)newList;
		Map<Id,Order_Approval__c> orderApprovalTriggerOldMap = (Map<Id,Order_Approval__c>)oldMap;

		List<Order_Approval__c> oaList = new List<Order_Approval__c>();
		List<Order_Approval__c> oaListSetNull = new List<Order_Approval__c>();

		//SFDC-4178
		/*
		OrderApprovalClass.UpdateRecType(orderApprovalTriggerNew);
		OrderApprovalClass.DefaultOwners(orderApprovalTriggerNew);

		for (Order_Approval__c oa: orderApprovalTriggerNew)
		{
	        if(oa.CCG_Status__c == 'Completed' && oa.Is_Restricted_Country__c && ((Trigger.isUpdate && orderApprovalTriggerOldMap.get(oa.Id).CCG_Status__c!= oa.CCG_Status__c) || Trigger.isInsert) && !oa.Validation_Override__c && !oa.IALT_Received__c && GsmUtilClass.getGSMSettingValue('OrderApprovalIALTRestriction').containsIgnoreCase('true') &&
	                !GsmUtilClass.getGSMSettingValue('OAIALTExceptionProfileIds').containsIgnoreCase(UserInfo.getProfileId().substring(0,15)))
	        {
	            oa.addError(GsmUtilClass.getGSMSettingValue('OrderApprovalIALTError'));
	        }

	        if(Trigger.isUpdate){
	            if((oa.Deal_Desk_Status__c == 'Completed' && orderApprovalTriggerOldMap.get(oa.id).Deal_Desk_Status__c !=oa.Deal_Desk_Status__c) || (oa.Deal_Desk_Status__c == 'Completed' && orderApprovalTriggerOldMap.get(oa.id).Deal_Desk_Approval_Notes__c !=oa.Deal_Desk_Approval_Notes__c))
	                oaList.add(oa);
                if(oa.Deal_Desk_Status__c == 'Not Needed' && orderApprovalTriggerOldMap.get(oa.id).Deal_Desk_Status__c !=oa.Deal_Desk_Status__c)
                    oaListSetNull.add(oa);
	        }
	    }
		
		if (oaList.size() > 0)
			OrderApprovalClass.updateDealDeskDetails(oaList, false);
		
		if(oaListSetNull.size() > 0)
			OrderApprovalClass.updateDealDeskDetails(oaListSetNull, true);
			*/

		ByPassAndLimitUtils.setAkamField(Trigger.isInsert, Trigger.isUpdate, orderApprovalTriggerNew);
	}

	public override void afterInsertAfterUpdateTrigger(){
		List<Order_Approval__c> orderApprovalTriggerNew = (List<Order_Approval__c>)newList;
        List<Order_Approval__c> orderApprovalTriggerOld = (List<Order_Approval__c>)oldList;
        Map<Id,Order_Approval__c> orderApprovalTriggerNewMap = (Map<Id,Order_Approval__c>)newMap;
        Map<Id,Order_Approval__c> orderApprovalTriggerOldMap = (Map<Id,Order_Approval__c>)oldMap;
		//OrderApprovalClass.UpdateOppty(orderApprovalTriggerNew);
		//SFDC-4178
		List<Order_Approval__c> OAList = new List<Order_Approval__c>();
		for(Order_Approval__c oa : orderApprovalTriggerNew){
			if(Trigger.isUpdate && oa.CCG_Status__c != orderApprovalTriggerOldMap.get(oa.id).CCG_Status__c && oa.CCG_Status__c == 'Closed' ){
				OAList.add(oa);
			}
		}
		if(OAList.size()>0){
			OrderApprovalClass.UpdateCaseAutoCloseField(OAList);
		}
	}

	public override void beforeDeleteBeforeUndeleteTrigger(){

	}

	public override void afterDeleteAfterUndeleteTrigger(){

	}

}