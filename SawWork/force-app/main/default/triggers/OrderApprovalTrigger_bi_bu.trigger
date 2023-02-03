/***
    OrderApprovalTrigger_bi_bu
    @author Karteek Mekala <kmekala@akamai.com>
    @Description : This trigger is called on 'before insert, before update' 
                   The following is done :
                   - The "Order Approval.Record Type" is updated according to "Order Approval.Approvals Required"
                   - The "Deal Desk Owner","CCG Owner" and "Legal Owner" are defaulted.
	@History
	--Developer		      --Date			--Change
	Karteek Kumar M		  17/02/2010	    Added logic to update new custom field "oa.CCG_Owner__c"
	Karteek Kumar M		  10/03/2010		Updated the logic to update the new custom field "oa.CCG_Owner__c"      
											Old logic is commented out   
	Karteek Kumar M		  11/03/2010		Fixed the buggy logic for Update_CCG_Owner()
	Karteek Kumar M		  28/06/2010		CR 568963  Yitong Data Visibility
											Removing Update_CCG_Owner() 
	Ali KM				  17/May/2011		CR 1088616 1Click Enhancement: Notify Rep of recent extension
											- Trigger an update to Merge_Contract_Header__c.X1Click_Extension_Status__c 
											when Order_approval__c.X1ClickUpdateContractCheck__c is checked.
											- Order_approval__c.X1ClickUpdateContractCheck__c is checked via Contract Extension WFs (Contract Extension - Order Form Failed, Contract Extension - Order Form Uploaded)											
	Ali KM				  14/Jun/2011		CR 1130536 Implementation 1-click deferment of b.e.d
											- Commenting the logic for updating the OA upload information to Contract fields. Instead
											this logic not resides on OA level in Class - ContractExtensionClass.cls
*/   
trigger OrderApprovalTrigger_bi_bu on Order_Approval__c (before insert, before update) 
{
	List<Order_Approval__c> oaList = new List<Order_Approval__c>();
	List<Order_Approval__c> oaListSetNull = new List<Order_Approval__c>();
	OrderApprovalClass.UpdateRecType(Trigger.new);
	OrderApprovalClass.DefaultOwners(Trigger.new);

	for (Order_Approval__c oa: Trigger.new)
    {
        if(oa.CCG_Status__c == 'Completed' && oa.Is_Restricted_Country__c && ((Trigger.isUpdate && Trigger.oldMap.get(oa.Id).CCG_Status__c!= oa.CCG_Status__c) || Trigger.isInsert) && !oa.Validation_Override__c && !oa.IALT_Received__c && GsmUtilClass.getGSMSettingValue('OrderApprovalIALTRestriction').containsIgnoreCase('true') &&
                !GsmUtilClass.getGSMSettingValue('OAIALTExceptionProfileIds').containsIgnoreCase(UserInfo.getProfileId().substring(0,15)))
        {
            oa.addError(GsmUtilClass.getGSMSettingValue('OrderApprovalIALTError'));
        }

        if(Trigger.isUpdate)
        {
            if((oa.Deal_Desk_Status__c == 'Completed' && Trigger.oldMap.get(oa.id).Deal_Desk_Status__c !=oa.Deal_Desk_Status__c) || (oa.Deal_Desk_Status__c == 'Completed' && Trigger.oldMap.get(oa.id).Deal_Desk_Approval_Notes__c !=oa.Deal_Desk_Approval_Notes__c))
                oaList.add(oa);
                    
                    if(oa.Deal_Desk_Status__c == 'Not Needed' && Trigger.oldMap.get(oa.id).Deal_Desk_Status__c !=oa.Deal_Desk_Status__c)
                        oaListSetNull.add(oa);
        }
    }
	
	if (oaList.size() > 0)
		OrderApprovalClass.updateDealDeskDetails(oaList, false);
	
	if(oaListSetNull.size() > 0)
		OrderApprovalClass.updateDealDeskDetails(oaListSetNull, true);
	/*
	// CR 1088616 1Click Enhancement: Notify Rep of recent extension -- start --
	// 1Click Extension, calling of code to update Contract Extension upload status.
	if (!trigger.isInsert)
	{
		Map<Id, Order_Approval__c> oaContractExtensionMap = new Map<Id, Order_Approval__c>();
		Map<String, Boolean> oaMap = new Map<String, Boolean>();
		for (Order_Approval__c oa : Trigger.new)
		{	
			if (oa.X1ClickUpdateContractCheck__c)
			{
				//oaList.add(oa);
				//if (oa.Contract_Extension_Original_Contract_Id__c != null)
					//oaMap.put(oa.Contract_Extension_Original_Contract_Id__c, oa.X1ClickUpdateContractCheck__c);
				oaContractExtensionMap.put(oa.Id, oa);
				
				// revert the checkbox to false
				oa.X1ClickUpdateContractCheck__c = false;
			}
		} 
		if (oaContractExtensionMap.size()>0)
			OrderApprovalClass.oneClickExtensionStatusUpdate(oaContractExtensionMap);
	}
	// CR 1088616 1Click Enhancement: Notify Rep of recent extension -- end --
	*/
	
  //  Code By Rahul : AKAM field updation Through The code
  if(Trigger.isBefore) {
    //Id CrmIntegration = Id.valueOf(GSM_Custom_Settings__c.getInstance('CRM_Integration').value__c); //SFDC-2304
    Id CrmIntegration = Id.valueOf(GsmUtilClass.getGSMSettingValue('CRM_Integration')); //SFDC-2304
    for(Order_Approval__c oa : Trigger.new){
      //This code takes care OF AKAM fields while insert if any of these field is null or Empty
      if(Trigger.isInsert){
        if((UserInfo.getUserId() == CrmIntegration && (oa.AKAM_Created_By__c =='' || 
          oa.AKAM_Created_Date__c == null ||oa.AKAM_System__c =='')) || UserInfo.getUserId() != CrmIntegration ) {
          oa.AKAM_Created_By__c = oa.AkaM_Alias__c ;
          oa.AKAM_Created_Date__c = system.now();
          oa.AKAM_System__c ='FORCE';
        }
      }      
    // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
      if((UserInfo.getUserId() == CrmIntegration && (oa.AKAM_Modified_Date__c  == null|| 
        oa.AKAM_Modified_By__c == '' || oa.AKAM_Modified_By__c == null)) || UserInfo.getUserId() != CrmIntegration )  {
        oa.AKAM_Modified_By__c = oa.AkaM_Alias__c;
        oa.AKAM_Modified_Date__c =  system.now();  
      }
    }
  }       
}