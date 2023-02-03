/***
    AccountTrigger_ai_au
    @version 1.0
    @author Karteek Mekala <kmekala@akamai.com>
    @Description : This trigger is called on 'after insert' and 'after update' events on the Accounts object.
                   It takes care of the following :
                   - Account Reassignment.
                   - Adding Account.Owner to Account Team on Account creation
    
	@History
	--Developer		      --Date			--Change
	Karteek Kumar M		  11/12/2010		CR 900397 Remove Other-New Other-Existing drop and add logic
    Karteek Kumar M		  16/12/2010  		CR 900397 Remove Other-New Other-Existing drop and add logic
 											- Put in Feature Toggles for 
 								  			  -) Other New/ Other Existing Add/Drop Logic
 								  			  -) Product Grouping	       
	Ali KM				19/05/2012		 CR 1588081 Exception - Too many scripts statements when reassigning 200 Accounts.
												- Commenting out the Contract Share code in Account Trigger as its redundant. Reason: Account Owner
												is always added to Account Team which also triggers Contract Sharing so running same code on Account level is redundant.
*/   
trigger AccountTrigger_ai_au on Account (after insert, after update) 
{
	/*
	Features_Toggle__c customSettingsPDRAUpdate = Features_Toggle__c.getInstance('AutoPDRAUpdateOnAcctInsert');
	Account_Reassignment_Settings__c customSettingsRuleExceptionProfileIds = Account_Reassignment_Settings__c.getInstance('RuleExceptionProfileIds');
	*/	
	// ------------- CR 900397 - Remove Other-New Other-Existing drop and add logic - START	
	/*
	  if(!Trigger.isInsert)
	  {
		    if (Features_Toggle__c.getInstance('Oppty Products-Other Drop & Add').Toggle__c)
		    {	
				//Opportunity Line Items Fix
				List<Account> opptyLineItemsFixAccountList = new List<Account>();
				for(Account acc:Trigger.new)
				{
					if(acc.Customer_Add__c != Trigger.oldMap.get(acc.Id).Customer_Add__c || acc.Customer_Drop__c != Trigger.oldMap.get(acc.Id).Customer_Drop__c || acc.Account_Split__c != Trigger.oldMap.get(acc.Id).Account_Split__c )
						opptyLineItemsFixAccountList.add(acc);
				}
				if(opptyLineItemsFixAccountList.size()>0)
					AccountTriggerClass.FixOpptyLineItems(opptyLineItemsFixAccountList);
		    }	
		    //Commenting out code for: CR 1259743 Make Contracts: a parent-child with accounts?
			// Contract Share Update.
			List<Account> updateAccOwnerCShareList = new List<Account>();
			List<Account> updatePartnerAdminAccountShareList=new List<Account>();   // Added by chandra for CR 1625737  
			for (Account acc:Trigger.new)
			{
				if (acc.OwnerId != Trigger.oldMap.get(acc.Id).OwnerId && acc.OwnerID!=null)
				{
					updateAccOwnerCShareList.add(acc);
					updatePartnerAdminAccountShareList.add(acc);              // Added by chandra for CR 1625737
				}
			}
			//if (updateAccOwnerCShareList.size()>0 && GsmUtilClass.isFeatureToggleEnabled('isContractShareEnabled')) // if toggle is off; dont do anything.
				//ContractSharing.updateAccountOwnerContractShare(updateAccOwnerCShareList, Trigger.oldMap);
				
			// Start Added by chandra for CR 1625737
			if(updatePartnerAdminAccountShareList.size()>0)
			{
				AccountReassignmentInterfaceClass.updateAccountShareForPartnerAdmins(updatePartnerAdminAccountShareList);
			}	
		   // End Added by chandra for CR 1625737 	
    	}
	// ------------- CR 900397 - Remove Other-New Other-Existing drop and add logic - STOP
	
	//Create new Account_Reassignment__c object for each account insert for auto updating of PDRA values
	
	if(Trigger.isInsert)
		{
			String userProfileId = userinfo.getProfileId();
			//system.assertEquals(customSettingsRuleExceptionProfileIds.value__c, userProfileId); 
			if (customSettingsPDRAUpdate.Toggle__c && !(userProfileId.contains(customSettingsRuleExceptionProfileIds.value__c)))
			{
				AccountReassignmentInterface accReassignInterface=new AccountReassignmentInterfaceClass(Trigger.New);
				accReassignInterface.doService();
				
			}
		}
	*/					
}