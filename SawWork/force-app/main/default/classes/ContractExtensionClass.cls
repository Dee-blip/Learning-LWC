/***
        ContractExtensionClass (this class is called from Buttons on Contract: object, buttons are - 'Extend Contract' & 'BED Deferment')
        
        Requirements :
        CR 1092945 Only Account team members and SA should be able to Extend Term from SF
        CR 1115760 1Click Extension of term: More informative message on contract extension
                1. Create a "Extend Contract" & 'BED Deferment' button on the Contract detail page
                2. Should allow a user to extend a contract OR Defer the billing effective date user is SA * / Sys Admin profiles OR part of associated Accounts' Account Team.
                3. Do the following validation
                        - Check if user profile ID is part of SA or if user is part of Account Team
                        - If Contract was already extended/deferred then show a alert pop-up informing the user of the previous request status if last request it not older than 1 day (24 hrs)
                        
        Implementation Notes :
        - NA
        
        History :
        -- Developer            -- Date                         -- Change
        Ali KM			        14/Jun/2011                      Created the class
        
        Lisha Murthy			09/Aug/2012						CR 1801867 Customer Save Program - Manually create Renewal Opportunities
        														Added function to create renewal opportunities from Contract through a button click
        														
        Lisha Murthy			30/09/2012						CR 1908127 - Send an error mail to renewal Opportunity requestor when there is some error while creating Opportunity.
        														Added the field update to "Renewal_Opportunity_Requester__c" field to be stamped as current user.
*/
global class ContractExtensionClass 
{
	public static User currentUserRecord;

    public Id contractId {get; set;}
    public String pRequestType {get; set;}
    public Id accountId {get; set;}
    public String result {get; set;}
    
    public void init(){
        contractId = ApexPages.currentPage().getParameters().get('contractId');
        pRequestType = ApexPages.currentPage().getParameters().get('pRequestType');
        accountId = ApexPages.currentPage().getParameters().get('accountId');
        result = ContractExtensionClass.isContractExtensionEnabledProfileCheck(contractId,pRequestType,accountId);
    }
    
    public static void initializeCurrentUserRecord()
	{
		if(currentUserRecord == null) // || UserInfo.getUserId() != currentUserRecord.Id
			currentUserRecord = [select Id, Profile.Name, Profile.UserType from User where Id=:Userinfo.getUserId()][0]; 
	}
    
	/**
    	isContractExtensionEnabledProfile(String pContractId)
    	- This method is called by sControl to check if currentUser 
    	  is authorized to the Extend Contract.
    
    webService static String isContractExtensionEnabledProfile( Id pContractId )
    {   
    	Boolean showPopUp = false;
    	Boolean isEnabledProfile = false;
    	String result = GetCustomSettingValue('BtnErrorMsg');
    	Merge_Contract_Header__c contractHeader;
    	for(Merge_Contract_Header__c ch:[select Id, 
                                                Name, 
                                                Original_Contract_Id__c,
                                                Active__c,
                                                Locked__c,
                                                Effective_End_Date__c ,
                                                Effective_Start_Date__c,
                                                Account_Name__c,
                                                Account_Name__r.Partner_Type__c,
                                                Contract_Type__c,
                                                Parent_Account_Name__c,
                                                Opportunity_Name__c,
                                                Opportunity_Name__r.CurrencyIsoCode,
                                                Opportunity_Name__r.Deal_Type__c,
                                                Opportunity_Name__r.Order_Locale__c,
                                                Opportunity_Name__r.Order_Region__c,
                                                Opportunity_Name__r.Partner_Involved__c,
                                                X1Click_Extension_Status__c,
                                                X1Click_Last_Extended_Date__c,
                                                X1Click_Last_Extended_OA_Id__c,
                                                fewClick_Last_Extended_Date__c
                                         from Merge_Contract_Header__c
                                         where Id = :pContractId])
    	contractHeader = ch;
    	
    	if (contractHeader == null)
    		return '0:Unable to find the Contract, please get in touch with your administrator';
    	initializeCurrentUserRecord();
    	String saProfileName = GetCustomSettingValue('SAProfileNames');
    	if (saProfileName.contains(currentUserRecord.Profile.Name))
    	{
    		isEnabledProfile = true;
    	}
		if (!isEnabledProfile)
		{
			for(AccountTeamMember atm:[select Id, UserId,AccountId from AccountTeamMember where AccountID = :contractHeader.Account_Name__c])
			{
				if( atm.UserId == Userinfo.getUserId() )
				{
					//System.debug('atmUserId=' + atm.UserId + ' userInfo.getUserId=' + Userinfo.getUserId());
					isEnabledProfile = true;
					break;
				}
			}
		}
		//System.debug('isEnabledProfile=' + isEnabledProfile);
		if (isEnabledProfile)
		{
			result = '1:SUCCESS';
			if ( contractHeader.fewClick_Last_Extended_Date__c != null && contractHeader.X1Click_Extension_Status__c != null && contractHeader.X1Click_Last_Extended_OA_Id__c != null)
			{
				Datetime thresholdDate = Datetime.now().addDays(-1 * Integer.valueOf(GetCustomSettingValue('ExistsDaysOld')));
				Datetime contractExtensionDate = contractHeader.fewClick_Last_Extended_Date__c; //dateGmt();
				//System.debug('thresholdDate=' + thresholdDate + ';contractExtensionDate' + contractExtensionDate + ', now=' + Datetime.now());
				if (contractExtensionDate >= thresholdDate && contractExtensionDate <= Datetime.now())
					result = '1:POPUP';
			}
		}
		return result;
    }
    */
    /**
    	isContractExtensionEnabledProfileCheck( Id pContractId, String pRequestType, Id pContractAccountName )
    	- This method is called by Contract.Button to check if currentUser 
    	  is authorized to the Extend Contract.
    	- If Pop-UP is applicable it also returns the Pop-UP message. 
    */ 
    public static String isContractExtensionEnabledProfileCheck( Id pContractId, String pRequestType, Id pContractAccountName )
    {   
    	Boolean showPopUp = false;
    	Boolean isEnabledProfile = false;
    	String result = '0:Error';
    	String requestType = pRequestType;
    	String popupMessage;
    	Order_Approval__c orderApproval;
		Id oaID;
    	
    	// intialize
    	if (pRequestType == 'CE')
			result = GsmUtilClass.getGSMSettingValue('Contract_Extension_BtnErrorMsg');
		else if (pRequestType == 'BEDD')    
			result = GsmUtilClass.getGSMSettingValue('Contract_Extension_BED_BtnErMsg');
		System.debug('Initialized value of Result=' + result);                            	
		System.debug('pRequestType=' + pRequestType);
    	
    	for(Merge_Contract_Header__c ch:[select Id, Name, Original_Contract_Id__c, ContractExtension_OA_Id__c,BEDDeferment_OA_Id__c 
    				from Merge_Contract_Header__c where Id = :pContractId])
			         {
						if (pRequestType == 'CE')
							oaID = ch.ContractExtension_OA_Id__c;
						else if (pRequestType == 'BEDD')    
							oaID = ch.BEDDeferment_OA_Id__c;                             	
						System.debug('pRequestType=' + pRequestType);  
			         }                         
        if (oaId != null)
        {                                    	
	    	for(Order_Approval__c oa:[select 	Id,
												Name,
												AKAM_OrderApproval_ID__c,
												AKAM_Created_Date__c,
												ContractExtension_OrderFormUploadCheck__c,
												Order_Form_Uploaded__c,
												Automation_Request_Type__c
	                                     from Order_Approval__c
                                         where Id = :oaId])
		    orderApproval = oa;
		    System.debug('OA ID =' + orderApproval.Id);
        }
    	
    	initializeCurrentUserRecord();
    	String saProfileName = GsmUtilClass.getGSMSettingValue('Contract_Extension_SAProfileNames');
    	if (saProfileName.contains(currentUserRecord.Profile.Name))
    	{
    		isEnabledProfile = true;
    	}
		if (!isEnabledProfile)
		{
			for(AccountTeamMember atm:[select Id, UserId, AccountId from AccountTeamMember where AccountID = :pContractAccountName])
			{
				if( atm.UserId == Userinfo.getUserId() )
				{
					System.debug('atmUserId=' + atm.UserId + ' userInfo.getUserId=' + Userinfo.getUserId());
					isEnabledProfile = true;
					break;
				}
			}
		}
		System.debug('isEnabledProfile=' + isEnabledProfile);
		if (isEnabledProfile && orderApproval != null)
		{
			Datetime thresholdDate = Datetime.now().addDays(-1 * Integer.valueOf(GsmUtilClass.getGSMSettingValue('Contract_Extension_ExistsDaysOld')));
			if ( orderApproval.AKAM_Created_Date__c >= thresholdDate && orderApproval.AKAM_Created_Date__c <= Datetime.now())
				showPopUp = true;
			System.debug('thresholdDate=' + thresholdDate + '; AKAM_Created_Date__c' + orderApproval.AKAM_Created_Date__c + ', Now=' + Datetime.now());
		}
		if (isEnabledProfile && !showPopUp)	
			result = '1:SUCCESS';
		else if (isEnabledProfile && showPopUp)
        {
            if (orderApproval.Automation_Request_Type__c == 'CE')
                popupMessage = GsmUtilClass.getGSMSettingValue('Contract_Extension_PopUPMsg');
            else if (orderApproval.Automation_Request_Type__c == 'BEDD')    
                popupMessage = GsmUtilClass.getGSMSettingValue('Contract_Extension_BED_PopUPMsg');
            popupMessage += ' Last Request:- AKAM Order Approval Id: ' + orderApproval.AKAM_OrderApproval_ID__c ;
            String requestStatus = 'Failed';
            if (orderApproval.Order_Form_Uploaded__c)
                requestStatus = 'Successful';
            else if (DateTime.now() <= orderApproval.ContractExtension_OrderFormUploadCheck__c)
                requestStatus = 'In Progress';
            popupMessage += ', Request Status: ' + requestStatus;
            result = '1:POPUP:' + popupMessage + '. ' + GsmUtilClass.getGSMSettingValue('Contract_Extension_popUPOKMsg'); //Click on \'OK\' to continue or \'Cancel\' to return to Contract page.';
            System.debug('result=' + result);
        }
		return result;
    }
    
    /*
    checkDuplicateRenewalOppty(String pOriginalContractId)
    	- Get the Original Contract Id value from the contract from the button is clicked.
    	- Check if there is already an existing Opportunity which is tied to this contract.
    		- If yes, then redirect to that Opportunity.
    		- If no, then check if the current contract has already been submitted for renewal.
    		- If both conditions (No oppty and current not already submitted for renewal), only then submit for renewal.
    */
     /*  SFDC 5392. Since the method is not not used, commenting it. It is required to remove reference for Renewal_Contract__c 
    webservice static String checkDuplicateRenewalOppty(String pOriginalContractId)
    {
    	List <Opportunity> oppList = new List<Opportunity>();
    	List <Merge_Contract_Header__c> headerList = new List<Merge_Contract_Header__c>();
    	
    	String res = '1:Confirm';
    	initializeCurrentUserRecord();
    	
    	//if(!currentUserRecord.Profile.Name.contains('Sales%') && !currentUserRecord.Profile.name.contains('System Administrator'))
    		//return '2:Sorry. You do not have the necessary permission for creating renewal opportunities';
    	
    	//Check if there are any existing Opportunities with the current contract.
    	for(Opportunity o: [SELECT Id, Name, Opportunity_Type__c, Contract_Id__c, Renewal_Contract__c, Renew_Contract_Id_Text__c 
    	                                    FROM Opportunity 
    	                                    WHERE Renew_Contract_Id_Text__c =: pOriginalContractId 
    	                                    AND Opportunity_Type__c != null 
    	                                    AND Opportunity_Type__c != '' 
    	                                    AND Opportunity_Type__c LIKE '%Renewal%' 
    	                                    AND (Not stagename  Like 'Closed%')
    	                                    order by CreatedDate Desc])
    		oppList.add(o);
    	
    	System.debug('Oppty List '+oppList);
    	
    	if(oppList.size() > 0)
    	{
    		res = '2:' + oppList[0].Id;
    		System.debug('Opportunity selected '+oppList[0]);
    		System.debug('Opportunity List '+oppList);
    	}
    	
    	if(res.startsWith('1'))
    	{
    		//If there is not Oppty > Check if the button has been clicked already and submitted for renewal.
    		for(Merge_Contract_Header__c header: [SELECT Id, Original_Contract_Id__c, Renewal_Process_Status__c FROM Merge_Contract_Header__c WHERE Original_Contract_Id__c =: pOriginalContractId])
    			headerList.add(header);
    			
    		if(headerList.size() > 0)
    		{
    			System.debug('Contract List is '+headerList.size());
    			
    			//If button already clicked, status is set to Pending > Show the appropriate message.
    			if(headerList[0].Renewal_Process_Status__c == 'Pending')
    				res = '2:Request to create a renewal Opportunity has already been submitted for this contract';
    				
    			//If no oppty found for this contract and button click is for first time, then submit the contract for renewal.
    			else
    			{
    				headerList[0].Renewal_Process_Status__c = 'Pending';
    				headerList[0].Renewal_Opportunity_Requester__c = userInfo.getUserId();
    				update headerList;
    			}
    		}
    	}
    	
    	return res;
    }*/
}