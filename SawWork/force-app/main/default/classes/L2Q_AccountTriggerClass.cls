public without sharing class L2Q_AccountTriggerClass 
{
	public static Boolean checkDuplicatesFirstRunFlag = true;
	public static Boolean updateIndustryFirstRunFlag = true;
	public static Boolean CreditCheckFirstRunFlag = true;
	public static Boolean createUpdateEntitlementFirstRunFlag = true;
	public static Boolean partnerSellableUpdateFirstRunFlag = true;
	public static Boolean updateContactAndLeadsWithVerticalFirstRunFlag = true;
	public static Boolean updateOpptysChannelLevelFirstRunFlag = true;
	public static Boolean handlePartnerTypeChangeFirstRunFlag = true;
    public static Boolean approveLastPendingReassignmentFirstRunFlag= true;
    //public static Boolean sendEmailToUpdateAnaplanSubTerritoryFirstRunFlag = true;
    public static Boolean partnerInvolvedAndSetPartnerAuthorisedCountryFlag = false;
    public static Boolean accountIdAndSetPartnerAuthorisedCountryFlag = false;
    public static Boolean wasTriggerAndWfOverrideSet = false;
    public static Boolean UpdateVerticalSubVerticalStatusFirstRun = true;
    public static Boolean updateVerticalSubVerticalFromDuns = true;
	public static Boolean upsertAccountHelperFirstRun = true;

    //SFDC-6867
	public static void updateVerticalSubVerticalStatus(List<Account> AccList, Map<Id, Account> oldMap, Boolean isInsert){
	       
			if(!UpdateVerticalSubVerticalStatusFirstRun) {
			    return;
			}

			String profileIds = GsmUtilClass.getGSMSettingValue('VerticalSub_Vertical_UpdatedProfileIds'); //Sales Operations
			string marketingBusinesProfile = GsmUtilClass.getGSMSettingValue('Marketing_wo_Import'); //Marketing - wo Import, Business Operations
			string marketProfileIds = profileIds +','+ marketingBusinesProfile;

			for(Account acc : AccList){ 
				/*
				if(isInsert && acc.vertical__c != null && acc.sub_vertical__c != null){
					acc.Vertical_Sub_Vertical_Status__c ='Initial Assignment';
					acc.Validation_Override__c = true;
				}
				else*/
				if(!isInsert){
					System.debug('inside updateVerticalSubVerticalStatus:');
					Account oldAcc = oldMap.get(acc.Id);
					if(!marketProfileIds.contains(userinfo.getprofileid()) && ((oldAcc.vertical__c == null && oldAcc.sub_vertical__c == null) || (oldAcc.vertical__c == 'Unknown' && oldAcc.sub_vertical__c == 'Unknown'))){
				        acc.Vertical_Sub_Vertical_Status__c ='Initial Assignment';
				        //acc.Validation_Override__c = true;
				    }
				  	else if(profileIds.contains(userinfo.getprofileid())){
				        acc.Vertical_Sub_Vertical_Status__c ='Manually Assigned';
				        //acc.Validation_Override__c = true;       
				   	}	
				   	else if(marketingBusinesProfile.contains(userinfo.getprofileid())){
				        acc.Vertical_Sub_Vertical_Status__c ='Override';
				        //acc.Validation_Override__c = true; 
				    }
				}
			}
			UpdateVerticalSubVerticalStatusFirstRun = false;
	}

	//SFDC-7114
	public static Map<String, String> initializeIndustryVerticalSubVerticalMapping(List<String> accVerticalList){
		Map<String, String> verticalSubVerticalIndustryMapping = new Map<String, String>();
		if(accVerticalList.size() > 0){
			for(Industry_Vertical_Sub_Vertical_Mapping__c mapping : [Select Id, Name, Industry__c, Vertical__c, Sub_Vertical__c from Industry_Vertical_Sub_Vertical_Mapping__c where Vertical__c in :accVerticalList limit 50000]){
				String key = (!String.isBlank(mapping.Vertical__c) ? mapping.Vertical__c.trim() : mapping.Vertical__c) + (!String.isBlank(mapping.Sub_Vertical__c) ? mapping.Sub_Vertical__c.trim() : mapping.Sub_Vertical__c); 
				verticalSubVerticalIndustryMapping.put(key, mapping.Industry__c);
			}
		}
		return verticalSubVerticalIndustryMapping;
	}

	//SFDC-7114
	public static void updateIndustryField(List<Account> accList, List<String> accVerticalList){

		if (!updateIndustryFirstRunFlag)
			return;

		Map<String, String> verticalSubVerticalIndustryMap = initializeIndustryVerticalSubVerticalMapping(accVerticalList);

		for(Account acc : accList){
			String key = (!String.isBlank(acc.Vertical__c) ? acc.Vertical__c.trim() : acc.Vertical__c) + (!String.isBlank(acc.Sub_Vertical__c) ? acc.Sub_Vertical__c.trim() : acc.Sub_Vertical__c); 
			if(verticalSubVerticalIndustryMap.containsKey(key)){
				acc.Industry__c = verticalSubVerticalIndustryMap.get(key);
			}
			else{
				acc.Industry__c = '';
			}
			acc.IVSV_Automation__c = false;
		}
		updateIndustryFirstRunFlag = false;
	}

	//SFDC-7114
    public static void updateVerticalSubVerticalStatusAndIndustryField(Boolean isInsert, List<Account> oldAccounts, List<Account> newAccounts, Map<Id, Account> oldMapAccount, Map<Id, Account> newMapAccount){
    	List<Account> updateVerticalSubVerticalStatusFieldList = new List<Account>();
    	List<Account> updateIndustryFieldList = new List<Account>();
    	List<String> accountsVerticalList = new List<String>();

    	for(Account newAcc : newAccounts){
    		//Update Industry based on vertical/Sub-vertical field on account.
			if ((isInsert || (!isInsert && (newAcc.Vertical__c != oldMapAccount.get(newAcc.Id).Vertical__c || newAcc.Sub_Vertical__c != oldMapAccount.get(newAcc.id).Sub_Vertical__c))) && newAcc.Vertical__c != null && newAcc.Vertical__c != 'Not Defined' ){
				updateIndustryFieldList.add(newAcc);
				accountsVerticalList.add(newAcc.Vertical__c);
			}
			//Update Vertical/Sub-Vertical status field on vertical/Sub-vertical field on account.
			//System.debug('Account Status:'+newAcc.Account_Status__c+' - Parent Division:'+newAcc.Parent_Division__c+'- isInsert:'+isInsert+'- Vertical:'+newAcc.Vertical__c+' - oldMap:'+oldMapAccount);
			if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('IVSVToggle') && !isInsert && !String.isBlank(newAcc.Account_Status__c) && (!newAcc.Account_Status__c.contains('Active') || newAcc.Account_Status__c.contains('Inactive')) && newAcc.Parent_Division__c != null  && newAcc.Parent_Division__c.endsWith('Web')){
				if(newAcc.Parent_Division__c != oldMapAccount.get(newAcc.id).Parent_Division__c && newAcc.Vertical__c != null){
					newAcc.Vertical_Sub_Vertical_Status__c ='Initial Assignment';
				}
				else if(newAcc.Vertical__c != oldMapAccount.get(newAcc.Id).Vertical__c || newAcc.Sub_Vertical__c != oldMapAccount.get(newAcc.id).Sub_Vertical__c){
					updateVerticalSubVerticalStatusFieldList.add(newAcc);
				}	
			}
    	}
    	//System.debug('updateVerticalSubVerticalStatusFieldList:'+updateVerticalSubVerticalStatusFieldList);
    	if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('IVSVToggle') && updateVerticalSubVerticalStatusFieldList.size() > 0){
    		updateVerticalSubVerticalStatus(updateVerticalSubVerticalStatusFieldList, oldMapAccount, isInsert);
    	}

    	if(updateIndustryFieldList.size() > 0){
    		updateIndustryField(updateIndustryFieldList, accountsVerticalList);
    	}
    }

    /* SFDC-7114
	public static void initializeIndustryVerticalMapping(List<String> accountsVerticalList)
	{	
		if (verticalSubVerticalMap.size()<1)
		{
			String strVerticalIndustryName = '';
			for (Industry_Vertical_Sub_Vertical_Mapping__c ivm : [Select Id, Name, Industry__c, Vertical__c, Sub_Vertical__c from Industry_Vertical_Sub_Vertical_Mapping__c where Vertical__c in :accountsVerticalList])
			{
				strVerticalIndustryName = ivm.Vertical__c+'#'+ivm.Industry__c;
				if (verticalSubVerticalMap.containsKey(strVerticalIndustryName))
				{
				  List<String> tempList = verticalSubVerticalMap.get(strVerticalIndustryName);
				  tempList.add(ivm.Sub_Vertical__c);
				  verticalSubVerticalMap.put(strVerticalIndustryName,tempList);
				}
				else
				  verticalSubVerticalMap.put(strVerticalIndustryName, new List<String>{ivm.Sub_Vertical__c});
			}
		}
	}
	
	public static Boolean checkForSubVertical(String[] pSubVerticalList, String pAccSubVertical)
	{
		Boolean hasSubVertical = false;
		if (pSubVerticalList.size()<1 && pAccSubVertical==null)
			return hasSubVertical;
		for (String subVertical :  pSubVerticalList)
		{
			if (subVertical == pAccSubVertical)
			{
				hasSubVertical = true;
				break;
			}
		}
		return hasSubVertical;
	}
	
	public static void updateAccountIndustry(Account[] pUpdateAccountIndustryList, Map<Id, Account> pTriggerNewMap)
	{
		if (!updateIndustryFirstRunFlag)
			return;
		
		//SFDC-2393
		List<String> accountsVerticalList = new List<String>();

		for(Account eachAccount : pUpdateAccountIndustryList)
		{
			accountsVerticalList.add(eachAccount.Vertical__c);
		}

		// fetch all the Industry_Vertical_Sub_Vertical_Mapping__c records.
		initializeIndustryVerticalMapping(accountsVerticalList);
		//End of SFDC-2393
		
		for (Account acc : pUpdateAccountIndustryList)
		{
			Boolean notFound = true;
			if (verticalSubVerticalMap.size()>0)
			{	
				for (String svi : verticalSubVerticalMap.keySet())
				{
					List<String> tempSVI = svi.split('#');
					
					
					if(tempSVI[0] == acc.Vertical__c && checkForSubVertical(verticalSubVerticalMap.get(svi), acc.Sub_Vertical__c))
					{	
			   	    	acc.Industry__c = tempSVI[1];
			   	    	notFound = false;
			   	    	break;
					}
				}
			}
			if (acc.Vertical__c == null || notFound)
	    		acc.Industry__c = '';
	
		}
		updateIndustryFirstRunFlag = false;
	}
	*/
	
	/**
	   CheckDuplicates(Account[] triggerNew)
	   - Check for duplicates when a new Account is created or when the Account.Name/Website is changed.
	   - Account.Name + Account.Website + Account.BillingCountry + Account.BillingState should be unique.
	*/
	public static void CheckDuplicates(Account[] triggerNew)
	{
		if(!checkDuplicatesFirstRunFlag)
			return;
		//commented SDFC 7618
		/*Set<String> websiteSet = new Set<String>();
		Set<String> countrySet = new Set<String>();
		Map<String, Account> newAccMap = new Map<String, Account>();
		for(Account acc: triggerNew)
		{
			if(acc.Validation_Override__c != true)
			{
				newAccMap.put(acc.Name, acc);
				if(acc.Website != null)
					websiteSet.add(acc.Website);
				if(acc.BillingCountry != null)
					countrySet.add(acc.BillingCountry);
			}
		}	
			if(newAccMap.size() > 0)
		{
			Account tempNewAcc;
			for(Account existingAcc: [select Name, Website, BillingCountry, BillingState from Account where Name IN :newAccMap.keySet()  and BillingCountry IN :countrySet and Id NOT IN :triggerNew])
			{
				tempNewAcc = newAccMap.get(existingAcc.Name);
				if (tempNewAcc!=null && existingAcc.website != null && tempNewAcc.Website != null)
				{
					String tempTLD = getTLD(tempNewAcc.Website);
					String existingTLD = getTLD(existingAcc.website);
					if(tempNewAcc!=null && tempTLD == existingTLD && tempNewAcc.BillingCountry == existingAcc.BillingCountry )
					{
						String address;
						Boolean HasError=false;
						if(tempNewAcc.BillingState == null || existingAcc.BillingState==null)
							{
								address = tempNewAcc.BillingCountry;
								HasError=true;
							}
						else
							{
								if(tempNewAcc.BillingState == existingAcc.BillingState)
								{
									address = tempNewAcc.BillingState + ', ' + tempNewAcc.BillingCountry;
									HasError=true;
								}
							}
						if(HasError==true)	
							tempNewAcc.addError('An account with Account Name = "'+tempNewAcc.Name+'", Domain = "'+tempTLD + '" and Address = "' + address + '" already exists. Please contact Globalsalesops@akamai.com to resolve any issues.');
					}
				}
			}
		}*/
		checkDuplicatesFirstRunFlag = false;
	}
			
	public static String getTLD(String url)
	{
		if (url == null)
			return '';	
			
		//forget TLD just compare the stuff between the slashes. 
		
		if(url.contains('https://') == true) url = url.replace('https://','');

		if(url.contains('http://')==true) url = url.replace('http://','');

		if(url.contains('www.') == true) url = url.replace('www.','');

		String domain = url.split('/')[0];
		
		TLDParser t = new TLDParser();
		Integer a = t.getEffectiveTLDLength(domain);
        if(a ==-1)
        {
            return '';
        }
		
		String tld = domain.substring(0,a);
		
		return tld;		
		
	}
	
	
	public static void updatePartnerContactsWithRebateDetails(List<Account> accountList)
	{
		List<Contact> partnerContactList=[select Id, 
		                                          Rebate_TC_Status__c,
		                                          isRebateTCToShow__c,
		                                          Account.Rebate_TC_Accepted_At__c,
		                                          Account.Rebate_TC_Status__c,
		                                          Account.Rebate_TC_Rejected_At__c,
		                                          Validation_Override__c 
		                                   from Contact 
		                                   where accountId in : accountList 
		                                   and partner_User__c != null 
		                                   and partner_user__r.isActive =true];
        for(Contact con : partnerContactList)
        {
        	DateTime acceptedDate=con.Account.Rebate_TC_Accepted_At__c;
        	DateTime rejectedDate=con.Account.Rebate_TC_Rejected_At__c;
        	con.Validation_Override__c=true;
        	if((con.Account.Rebate_TC_Status__c=='' ||con.Account.Rebate_TC_Status__c==null))
        	{
        		con.isRebateTCToShow__c=true;
        		con.Rebate_TC_Status__c='';
        	}
        	else if((con.Account.Rebate_TC_Status__c=='Accepted' && (acceptedDate!=null && acceptedDate.year()<DateTime.now().year())) 
        	        || (con.Account.Rebate_TC_Status__c=='Rejected' && (rejectedDate!=null && rejectedDate.year()<DateTime.now().year() )))
        	{
        		con.isRebateTCToShow__c=true;
        		con.Rebate_TC_Status__c=con.Account.Rebate_TC_Status__c;
        	}
        	else
        	{
        		con.isRebateTCToShow__c=false;
        		con.Rebate_TC_Status__c=con.Account.Rebate_TC_Status__c;
        	}
        }
              	                                   
	  update partnerContactList;	
	}
	
	public static void afterDelete(Account[] accountList) {

        if(accountList==null || accountList.size()==0) return;

		String accountDeleteEnabledProfileIds = GsmUtilClass.getGSMSettingValue('AccountDelete_EnabledProfileId'); //SFDC-2304
	    String accountMergeEnabledProfileIds = GsmUtilClass.getGSMSettingValue('AccountMerge_EnabledProfileId'); //SFDC-2304
	    //System.debug('accountDeleteEnabledProfileIds=' + accountDeleteEnabledProfileIds);
	    //System.debug('accountMergeEnabledProfileIds=' + accountMergeEnabledProfileIds);

	    //SFDC-2389 starts
	    List<User> userListForAcc = new List<User>();
	    List<User> userListForMasterAcc = new List<User>();
	    List<Account> masterAccList = new List<Account>();
	    Map<String, User> accOwnerIDToUserMap = new Map<String, User>();
	    Map<String, Account> accMasterRecordIDToAccountMap = new Map<String, Account>();
	    Map<String, User> masterAccOwnerIDToUserMap = new Map<String, User>();
	    List<String> accOwnerID = new List<String>();
	    List<String> masterOwnerID = new List<String>();
	    List<String> accMasterRecordID = new List<String>();
	    List<String> masterOwnerIDList = new List<String>();

	    for(Account acc: accountList){
	    	accOwnerID.add(acc.ownerid);
	    	accMasterRecordID.add(acc.MasterRecordId);
	    }

	    // There is no account in CRM which has MasterRecordId actual value, so loop wan't work  because of if condition

	    userListForAcc = [Select name,alias,email from User where id in :accOwnerID];
	    masterAccList = [Select name,ownerid from Account where id in :accMasterRecordID];

	    for(User user : userListForAcc){
	    	accOwnerIDToUserMap.put(user.id, user);
	    }

	    for(Account massterAcc : masterAccList){
	    	accMasterRecordIDToAccountMap.put(massterAcc.id, massterAcc);
	    	masterOwnerIDList.add(massterAcc.ownerid);
	    }

	    userListForMasterAcc = [Select email from User where id in :masterOwnerIDList];

	    for(User user : userListForMasterAcc){
	    	masterAccOwnerIDToUserMap.put(user.id, user);
	    }

	    List<Merged_Account__c> mergedAccountList = new List<Merged_Account__c>();
	    
	    for(Account acc: accountList) {
	        //System.debug('acc.MasterRecordId=' + acc.MasterRecordId);
	        if(!accountDeleteEnabledProfileIds.contains(UserInfo.getProfileId()) && !(acc.MasterRecordId!=null && accountMergeEnabledProfileIds.contains(UserInfo.getProfileId())))
				acc.addError('Insufficient access. Please contact System Administrator for Account deletion.');    
	        
	        if(acc.MasterRecordId != null) {
	            
	            
	            Merged_Account__c ma = new Merged_Account__c();
	            
	            // User us = accOwnerIDToUserMap.get(acc.ownerid);
	            //for(User u: [Select name,alias,email from User where id =:acc.ownerid]) {
	              User us = accOwnerIDToUserMap.get(acc.ownerid);
	           /*   if(user != null) {
	              	System.debug('Mayank, User : ' +user);
	                us = user;
	            }*/
	            
	            Account master = accMasterRecordIDToAccountMap.get(acc.MasterRecordId);
	            //for(Account m:[Select name,ownerid from Account where id=:acc.MasterRecordId]){
	             
	              //  master = m;
	       //     }
	            
	            User parent_us = masterAccOwnerIDToUserMap.get(master.ownerid);
	          /*  for(User u: [Select email from User where id =:master.ownerid]) {
	                parent_us = u;
	            }*/
	            
	            ma.Parent_Account__c = acc.MasterRecordId;
	            ma.Merged_Into_Account_Name__c = master.Name;
	            ma.name = acc.name;
	            
	            ma.Account_Owner__c = us.alias;
	            ma.Merged_Account_Owner_Email__c = us.email;
	            ma.Merged_Into_Account_Owner_Email__c = parent_us.email;
	            
	            ma.AKAM_Account_ID__c = acc.AKAM_Account_ID__c;
	            ma.Customer_Add__c = acc.Customer_Add__c;
	            ma.Customer_Drop__c = acc.Customer_Drop__c;
	            ma.NPS__c = acc.CS_NPS__c;
	            ma.Account_Status__c = acc.Account_Status__c; 
	            
	            String address = '';
	            address = address + 'Primary Street : ' + acc.BillingStreet + '\n';
	            address = address + 'Primary City : ' + acc.BillingCity + '\n';
	            address = address + 'Primary State : ' + acc.BillingState + '\n';
	            address = address + 'Primary Zip/Postal Code : ' + acc.BillingPostalCode + '\n';
	            address = address + 'Primary Country : ' + acc.BillingCountry + '\n';
	            ma.Primary_Address__c = address;
	            ma.Target_List__c = acc.Target_Lists__c;
	            ma.Vertical__c = acc.Vertical__c;
	            
	            String ccinfo = '';
	            /*******************Field Removed*****************/
	            //ccinfo = ccinfo + 'Credit Check Approval # : ' + acc.Credit_Check_Approval__c + '\n';
	            ccinfo = ccinfo + 'Credit Check Date : ' + acc.Credit_Check_Date__c  + '\n';
	            ccinfo = ccinfo + 'Credit Check Status : ' + acc.Credit_Check_Status__c + '\n';         
	            ccinfo = ccinfo + 'Credit Check Comments : ' + acc.Credit_Check_Comments__c + '\n';                     
	            ccinfo = ccinfo + 'Credit Check Type : ' + acc.Credit_Check_Type__c + '\n';
	            ccinfo = ccinfo + 'Credit Check Initial Review : ' + acc.Credit_Check_Initial_Review__c + '\n'; 
	            ccinfo = ccinfo + 'PO Comment : ' + acc.PO_Comment__c + '\n';
	            ccinfo = ccinfo + 'PO Required : ' + acc.PO_Required__c + '\n';
	            ma.Credit_Check_Info__c = ccinfo;
	            mergedAccountList.add(ma);
	                    
	        }
	    }

		if (mergedAccountList.size() > 0) {
            insert mergedAccountList;
        }


		// SFDC-8288 Rajul Vishwakarma 
		// Start
		String businessOpsIdsList = GsmUtilClass.getGSMSettingValue('Business_Ops_User_Ids');
		if(businessOpsIdsList.contains(Userinfo.getUserId())){
			List<Account_Merge_Request__c> accountMergeRequests =[select Merge_Status__c from Account_Merge_Request__c where Merge_Status__c = 'Approved' and Winning_Account__c in :accMasterRecordID];
			for(Account_Merge_Request__c amr : accountMergeRequests){
				amr.Merge_Status__c = 'Merged';
			}
			if(accountMergeRequests.size()>0){
				update accountMergeRequests;
			}
		}
		// End

		//Start of SFDC-9138 - Rajul Vishwakarma
		if(accMasterRecordID.size()>0){
			List<Id> accMasterRecordIDList = new List<Id>((List<Id>)accMasterRecordID);
			updateAndInsertAccountHelperObjects(new Set<Id>(accMasterRecordIDList));
		}
		//End of SFDC-9138
	}
	
	public static void beforeInsertUpdate(Boolean isInsert, Account[] oldAccounts, Account[] newAccounts, Map<Id, Account> oldMap, Map<Id, Account> newMap) {

        if(newAccounts==null || newAccounts.size()==0) return;

        //CR 2988866: rsharma: Contacts & Contracts: created in Siebel has Akam System "FORCE" in SFDC
        if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
        {
            If(isInsert) 
            {
                AkamFieldHandler akamFieldHandler = new AkamFieldHandler();
                AkamFieldHandler.insertHandler(newAccounts);
            } 
            else
            {
                AkamFieldHandler akamFieldHandler = new AkamFieldHandler();
                AkamFieldHandler.updateHandler(newAccounts);
            }

            /*Code By Knagal: 
              Code to check if any of the fields which are synced  to Siebel are updated by any user other than CrmIntegration
             */  
            SyncToSiebelFieldsClass.populateSyncToSiebelField('Account');

            if(!isInsert)
                L2Q_AccountTriggerClass.updateFinancialRiskCreditCheck(newAccounts, oldMap);      

        }
		
		if (Test.isRunningTest() && ManagedPkgErrorClass.isFromManagedPackage)
		{
			System.debug('Running Test:' + Test.isRunningTest() + 'From Managed Package:' + ManagedPkgErrorClass.isFromManagedPackage);
			return;
		}
	  	System.debug('Outside test statement in TRigger' + 'Running Test:' + Test.isRunningTest() + 'From Managed Package:' + ManagedPkgErrorClass.isFromManagedPackage);
		for (account a : newAccounts)
			a.OwnerIDAlt__c = a.ownerID;
		
		/* CR 872300 Code cleanup - enable feature toggle for PDRA auto-reassignment */    
		//Features_Toggle__c customSettingsPDRAUpdate = Features_Toggle__c.getInstance('AutoPDRAUpdateOnAcctInsert'); //SFDC-2304
	    //Account_Reassignment_Settings__c customSettingsRuleExceptionProfileIds = Account_Reassignment_Settings__c.getInstance('RuleExceptionProfileIds'); //SFDC-2304
	
	    /* Check for duplicates */
	
	    List<Account> checkDuplicateList = new List<Account>();
	    List<Account> updateIndustryList = new List<Account>();
	    List<Account> listOfAccountsWithChangedPartnerType = new List<Account>();
	    //List<Account> listOfAccountsWithChangedGDRAT = new List<Account>();
        List<Account> listOfAccountsWithChangedCountry = new List<Account>();
        List<Account> accListWithChangedGlobalAcc = new List<Account>(); //SFDC-2860
        Set<String> globalAccSet = new Set<String>(); //SFDC-2860
	    list<account> SICAccList =new list<Account>(); //SFDC-5436
        set<string> SICCode = new set<string>(); //SFDC-5436
        list<account> USAAccountList =new list<Account>(); //SFDC-5913
        

	    List<Account> partnerAdminAccountShareList=new List<Account>();
	    String chinaAccountOwnerId=GSMUtilClass.getGSMSettingValue('AccountTrigger_ChinaAccOwnerId'); //SFDC-2304
	    String chinaADEProfileId=GSMUtilClass.getGSMSettingValue('AccountTrigger_ChinaProfileId'); //SFDC-2304
	    List<String> isleManfieldList = new List<String>();//SFDC-7471
        isleManfieldList = GSMUtilClass.getGSMSettingValue('Isle_of_Man_Field_Check').replaceAll(' ', '').split(','); //SFDC-7471
		list<string> IsleofManCountryList =new list<string>();
    	IsleofManCountryList= GsmUtilClass.getGSMSettingValue('RestrictedPlaceList').toLowerCase().split(','); //SFDC-7803
                
	    for(Account acc: newAccounts)
	    {
	    	Boolean showIsleOfManWarning =false;//SFDC-7471
        	Boolean fieldvalueChangeFlag=false; //SFDC-7471
        	Boolean isleofManFlag = True;

	        // If new Account or Account.Name/ Website/ BillingCountry is changing, then check for duplicates
	        Account oldAcc;

	        if(Util.hasChanges('DUNS_SIC__c', oldAcc, acc) && acc.DUNS_SIC__c != null && acc.DUNS_SIC__c.length() > 6){
                acc.DUNS_SIC__c = acc.DUNS_SIC__c.substring(0,6);
            }

	        if(!isInsert)
			{
             if ((acc.Type == 'Direct Customer - Active' && ((oldMap.get(acc.Id).Type == 'Indirect Customer - Active') || oldMap.get(acc.Id).Type == 'Indirect Customer - Inactive')) && !oldMap.get(acc.Id).taskCreatedForCreditCheck__c )
             	acc.taskCreatedForCreditCheck__c = true;
                oldAcc = oldMap.get(acc.Id);	
           	}
           	//SFDC-2130 - PSOR

           	/* SFDC-7114
           	if (isInsert && (acc.Vertical__c != null && acc.Vertical__c != 'Not Defined' && acc.Industry__c == null) || (!isInsert && (acc.Vertical__c!=oldMap.get(acc.Id).Vertical__c || acc.Sub_Vertical__c!=oldMap.get(acc.id).Sub_Vertical__c)))
	       	if (isInsert || (!isInsert && ((acc.Vertical__c!=oldMap.get(acc.Id).Vertical__c || acc.Sub_Vertical__c!=oldMap.get(acc.id).Sub_Vertical__c) ||(acc.Vertical__c != null || acc.Vertical__c != 'Not Defined' && acc.Industry__c == null))))
				updateIndustryList.add(acc);
			*/
			//SFDC-9221 - Manish Mahajan
            
            if((!isInsert && ((acc.GST__c  != oldMap.get(acc.Id).GST__c  && acc.GST__c  != '') || (acc.BillingCountry  != oldMap.get(acc.Id).BillingCountry  && acc.BillingCountry  != '')) ) || (isInsert && acc.GST__c !='')){
                if(String.isNotBlank( acc.BillingCountry) && String.isNotBlank( acc.GST__c) && acc.BillingCountry.toLowerCase() == 'india'){
                    if(acc.GST__c.length()<15){
                        acc.addError('GST Length should be more than 15 characters.');
                        return;
                    }else if(acc.GST__c.length() > 30){
                        acc.addError('GST Length should be less than 30 characters.');   
                        return;
                    }
                    //code to check if there is any special characters.
                    String input =acc.GST__c;
                    Pattern MyPattern = Pattern.compile('[^A-Za-z0-9]');
                    Matcher MyMatcher = MyPattern.matcher(input);
                    //System.debug('result---'+MyMatcher.find());
                    if(MyMatcher.find()){
                        acc.addError('GST should not contain any special characters.');   
                        return;
                    }
                    
                    List<L2Q_GST_India_State_Code__mdt> listMdt = [Select Id,Code__c,State_Name__c from L2Q_GST_India_State_Code__mdt];
                    //Map<String, L2Q_GST_India_State_Code__mdt> mcs = L2Q_GST_India_State_Code__mdt.getAll();
                    for(L2Q_GST_India_State_Code__mdt mdt : listMdt){
                        if(acc.BillingState.toLowerCase() == mdt.State_Name__c.toLowerCase()){
                            if(mdt.Code__c == acc.GST__c.substring(0,2)){
                                break;
                            }else{
                                acc.addError('GST Code is incorrect for the Shipping Address.');
                            }
                        }
                    }
                }
                else{
                    if(String.isNotBlank( acc.GST__c)){
                        List<L2Q_TaxID_Country_Code__mdt> listMdt = [Select Id,Prefix__c,Country_Name__c from L2Q_TaxID_Country_Code__mdt];
                        //Map<String, L2Q_TaxID_Country_Code__mdt> mapCountryCodes = L2Q_TaxID_Country_Code__mdt.getAll();
                        for(L2Q_TaxID_Country_Code__mdt mdt : listMdt){
                            if( String.isNotBlank( acc.BillingCountry) && acc.BillingCountry.toLowerCase() == mdt.Country_Name__c.toLowerCase()){
								if(acc.BillingCountry.toLowerCase()=='indonesia'){
                                    break;
                                }
                                if(acc.GST__c.length() > 30){
                                    acc.addError('Tax ID Length should be less than 30 characters.');   
                                    return;
                                }
                                
                                if(acc.GST__c.indexOf(' ') > -1){
                                    acc.addError('Spaces are not allowed in VAT ID.'); 
                                    return;
                                }
                                else if(mdt.Prefix__c  == acc.GST__c.substring(0,2)){
                                    break;
                                }else{
                                    acc.addError('Tax ID Code is incorrect for the Shipping Address.');
                                }
                            }
                        }
                    }
                }
            }
            //End--

		// SFDC-8735 Changes - Rajul Vishwakarma
			// Start
			if(!isInsert){
				if(Util.hasChanges(new Set<String>{ 'BillingState', 'BillingCountry', 'Vertical__c', 'Website', 'Sub_Vertical__c', 'BillingCity', 'BillingAddress', 'BillingPostalCode', 'BillingStreet' }, oldMap.get(acc.Id), acc)){
					acc.Ops_Validated__c = null;
    				acc.Last_Validated_Date__c = null;
				}
				if(acc.Ops_Validated__c != oldMap.get(acc.Id).Ops_Validated__c && acc.Ops_Validated__c != null){
					acc.Last_Validated_Date__c = System.today();
				}
			}

				// SFDC-9167 - Rajul Vishwakarma	
				if(isInsert){
					String businessOpsIdsList = GsmUtilClass.getGSMSettingValue('Business_Ops_User_Ids');
					if(businessOpsIdsList.contains(Userinfo.getUserId())){
						acc.Ops_Validated__c = UserInfo.getUserId();
						acc.Last_Validated_Date__c = System.today();
					}	
				}
			//End

		

	        if(isInsert || (!isInsert && ((acc.Name != oldAcc.Name || (acc.WebSite != oldAcc.Website) || (acc.BillingState != oldAcc.BillingState) || (acc.BillingCountry != oldAcc.BillingCountry)))))
				checkDuplicateList.add(acc);
				
		    if(isInsert && UserInfo.getProfileId()==chinaADEProfileId)
		    {
		    	acc.OwnerId=chinaAccountOwnerId;
		    }
            
            if(acc.OwnerId != null && (isInsert || !isInsert && Util.hasChanges('OwnerId', oldAcc, acc)))
                acc.Old_Account_Owner__c = acc.OwnerId;
            
		    if ((Trigger.isUpdate && acc.Partner_Type__c!=oldAcc.Partner_Type__c) || Trigger.isInsert)
                listOfAccountsWithChangedPartnerType.add(acc);

            //Jira Story SFDC-1407
			if ((Trigger.isUpdate && (acc.DirectCustomerRollup__c !=oldAcc.DirectCustomerRollup__c || acc.IndirectCustomerRollup__c  != oldAcc.IndirectCustomerRollup__c  )) || Trigger.isInsert)
                {
                    if(acc.DirectCustomerRollup__c > 0)
                        acc.Direct_Customer__c = True;
                    else 
                        acc.Direct_Customer__c = False;
                    
                    if(acc.IndirectCustomerRollup__c > 0)
                        acc.Indirect_Customer__c = True;
                    else 
                        acc.Indirect_Customer__c = False;
                }

            /* CR 2962001 - Country Conversion for Data.com */
		    if (acc.BillingCountry == 'United States' || acc.BillingCountry == 'United States of America') 
		    	acc.BillingCountry = 'USA';

	    	if (acc.ShippingCountry == 'United States' || acc.ShippingCountry == 'United States of America') 
		    	acc.ShippingCountry = 'USA';
		    /* End of Country Conversion for Data.com */

		     // Start of Anaplan sub territory - CR 3176781 
		    /*if((isInsert || (!isInsert && (acc.OwnerId != oldAcc.OwnerId || acc.AKAM_Territory_Mapping_ID__c != oldAcc.AKAM_Territory_Mapping_ID__c)))
            && acc.Anaplan_Sub_Territory__c == 'Multiple')
		    {
		    	System.debug('Im here');
		    	listOfAccountsWithChangedGDRAT.add(acc);
		    }*/

		    // SFDC-7471
		    for(string fieldname : isleManfieldList){
               if((isInsert && acc.get(fieldname)!=null) || (Trigger.isUpdate && Util.hasChanges(fieldname, oldAcc, acc))){
                       fieldvalueChangeFlag=true;
                 }
                if(acc.get(fieldname)!=null && IsleofManCountryList.Contains(string.valueof(acc.get(fieldname)).toLowerCase())){
                    IsleofManFlag =false;
                  }  
                }
                if(fieldvalueChangeFlag){
                    for(string fields : isleManfieldList){
    
                        if(acc.get(fields)!=null && IsleofManCountryList.Contains(string.valueof(acc.get(fields)).toLowerCase())){
                         showIsleOfManWarning=true;
                        break;
                        }
                    }
                    if(showIsleOfManWarning){
		                acc.Sales_Approval_Status__c='Both Restricted';
		                acc.Is_Restricted_Country__c=true;
		            }else{

		                if(Trigger.isUpdate && ((oldAcc.billingstate !=null && IsleofManCountryList.Contains(oldacc.billingstate.toLowerCase()))
						|| (oldAcc.shippingstate !=null && IsleofManCountryList.Contains(oldacc.shippingstate.toLowerCase()))) )
						{
	                        acc.Sales_Approval_Status__c='';
	                        acc.Is_Restricted_Country__c=False;
	                    }
                	}
		          
             }
            
            

             //IsleofManFlag is used for Exclude Isle of man Logic 
            if((((isInsert && acc.BillingCountry!=null) || Trigger.isUpdate && Util.hasChanges('BillingCountry', oldAcc, acc)) ||
                ((isInsert && acc.ShippingCountry!=null) || Trigger.isUpdate && Util.hasChanges('ShippingCountry', oldAcc, acc)))
                && isleofManFlag)
                 {

                System.Debug('AGH_DEBUG 2');
                listOfAccountsWithChangedCountry.add(acc);
            }

            //SFDC-2860
            if((isInsert && !String.isBlank(acc.Global_Account_Relationships__c)) || (!isInsert && acc.Global_Account_Relationships__c != oldMap.get(acc.Id).Global_Account_Relationships__c)){
                accListWithChangedGlobalAcc.add(acc);
                globalAccSet.add(acc.Global_Account_Relationships__c);
            }
            
            //SFDC-5436 IVSVToggle is used to disable IVSV automation
            if(!isInsert && GsmUtilClass.isFeatureToggleEnabledCustomMetadata('IVSVToggle') && acc.Account_Status__c != null && (!acc.Account_Status__c.contains('Active') || acc.Account_Status__c.contains('Inactive')) && acc.Parent_Division__c != null && acc.Parent_Division__c.endsWith('Web')) {
               
                if(Util.hasChanges('DUNS_SIC__c', oldAcc, acc) && acc.DUNS_SIC__c != null && GsmUtilClass.getGSMSettingValue('SicCodeUpdatedByIntegrationProfileIds').contains(userinfo.getprofileid()) && acc.Vertical_Sub_Vertical_Status__c != 'Override' && acc.Vertical_Sub_Vertical_Status__c != 'Manually Assigned'){
                        SICCode.add(acc.DUNS_SIC__c);
                        SICAccList.add(acc);
                }
                /* SFDC-7114
                if(Util.hasChanges('vertical__c', oldAcc, acc) || Util.hasChanges('sub_vertical__c', oldAcc, acc))
                    VerticalAccList.add(acc);
                */
             
            }

            //SFDC-5913
           if(acc.BillingCountry == 'USA' && acc.phone !=null && Util.hasChanges('Phone', oldAcc, acc)){
                string inputstring = acc.phone.replaceAll('\\D','');
               // system.debug('(' + inputstring.substring(0, 3) + ') ' + inputstring.substring(3, 6) + '-' + inputstring.substring(6));
               // system.debug('swati::'+if(acc.phone == '(' + inputstring.substring(0, 3) + ') ' + inputstring.substring(3, 6) + '-' + inputstring.substring(6)));
                if(inputstring.length() >= 10){
                if(acc.phone != '(' + inputstring.substring(0, 3) + ') ' + inputstring.substring(3, 6) + '-' + inputstring.substring(6) ){
                  USAAccountList.add(acc);
                  system.debug('USAAccountList::'+USAAccountList);  
              } }
              
            }

	    }

	    //SFDC-5913
        if(USAAccountList.size()>0)
            L2Q_AccountTriggerClass.UpdateUSPhoneFormat(USAAccountList);

	     //SFDC-5436
        if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('IVSVToggle') && SICAccList.size()>0)
            L2Q_AccountTriggerClass.UpdateVerticalSubVertical(SICAccList,SICCode);

        /* Update Industry and Vertical/Sub-Vertical status field on Account */ 
        L2Q_AccountTriggerClass.updateVerticalSubVerticalStatusAndIndustryField(isInsert, oldAccounts, newAccounts, oldMap, newMap);

	    //SFDC-2860
        if(accListWithChangedGlobalAcc.size()>0){
            setMarketingParentOnAccount(accListWithChangedGlobalAcc, globalAccSet);
        }

        if(listOfAccountsWithChangedCountry.size()>0)
            SalesApprovedCountryClass.updateRestrictedCountryOnAccounts(listOfAccountsWithChangedCountry);
            
        System.Debug('AGH_DEBUG 3');


	    /*if(listOfAccountsWithChangedGDRAT.size()>0)
	    {
	    	if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('AnaplanSubTerritoryEmailToggle')) //SFDC-2304
	    		L2Q_AccountTriggerClass.sendEmailToUpdateAnaplanSubTerritory(listOfAccountsWithChangedGDRAT);

	    }*/
	
	    if(checkDuplicateList.size() > 0) 
	        L2Q_AccountTriggerClass.CheckDuplicates(checkDuplicateList);
	        
	    /* Address Validation */

	    AddressValidationClass.CallValidateAddress(newAccounts);
	        
	    if (listOfAccountsWithChangedPartnerType.size()>0)
            L2Q_AccountTriggerClass.handlePartnerTypeChange(listOfAccountsWithChangedPartnerType);
	    
		//CR 1131031 PRM: Portal access error message when conditions are not met
	
		if (!isInsert)
		{
	    	PRM_opportunity.AddErrorToAccount(newAccounts,oldMap);
		}
         
        
        //SFDC-1632
        String soastaUserAlias = GsmUtilClass.getGSMSettingValue('soasta_user_alias');
        for(Account acc: newAccounts){
        	system.debug(LoggingLevel.ERROR,'Account_Owner_Alias__c: '+acc.Account_Owner_Alias__c+ ' soastaUserAlias: '+soastaUserAlias);
        	system.debug(LoggingLevel.ERROR,'ownerId: '+acc.ownerId+' :isInsert: '+isInsert);
        	if((isInsert || (!isInsert && util.hasChanges('ownerId',oldMap.get(acc.id),acc))) && acc.Account_Owner_Alias__c==soastaUserAlias)
        		acc.Soasta_pool_user_Assignment__c=Date.Today();
        }
	}

	//SFDC-2860
    public static void setMarketingParentOnAccount(List<Account> listOfAccounts, Set<String> globalAcc){
        Map<String,Id> globalAccToAccMap =  new Map<String,Id>();
        for(Account ac : [select Id, AKAM_Account_ID__c from Account where AKAM_Account_ID__c != NULL AND AKAM_Account_ID__c IN : globalAcc]){
            if(!globalAccToAccMap.containsKey(ac.AKAM_Account_ID__c)){
                globalAccToAccMap.put(ac.AKAM_Account_ID__c, ac.Id);
            }
        }
        for(Account a : listOfAccounts){
        	if(!String.isBlank(a.Global_Account_Relationships__c) && a.Global_Account_Relationships__c != a.AKAM_Account_ID__c)
            	a.Marketing_Parent_Account__c = globalAccToAccMap.get(a.Global_Account_Relationships__c);
            else
            	a.Marketing_Parent_Account__c = NULL;
        }
    }


	 /** Start -Sonali Tandon - CR 3176781 - Anaplan Sub-Territory Needs to be integrated with the Account Assignment
    Send email to Sales Ops public groups based on Account's GDRAT when Account.Anaplan Sub Territory = Multiple
    **/
    /*public static void sendEmailToUpdateAnaplanSubTerritory(List<Account> listOfAccounts)
	{	
		if(!sendEmailToUpdateAnaplanSubTerritoryFirstRunFlag)
			return;

		AccountReassignmentInterfaceClass accReassignmentObj = new AccountReassignmentInterfaceClass(listOfAccounts, true);
		Map<Id,List<String>> mapOfAccountIdToEmailList = new Map<Id,List<String>>();
		Map<Id,Account> mapOfAccountIdToAccount = new Map<Id,Account>();
        List<User> salesOpsUsers= new List<User>();
        List<Messaging.SingleEmailMessage> emailList = new List<Messaging.SingleEmailMessage>();
        //Messaging.SingleEmailMessage mail;
        String baseUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/';
		String accountName;
		String geoString;
		String emailHead;
		String emailBody;
	

		for(Account acc : listOfAccounts)
		{
			// SalesOpsDetails contains sales ops user ids as first element and sales ops email ids as second 
			salesOpsUsers = accReassignmentObj.getRegionalSalesOps(acc.Geography_Formula__c, acc.Division_Formula__c, acc.Region__c,acc.Division__c);
            if(salesOpsUsers.size()>0)
            {
                mapOfAccountIdToEmailList.put(acc.Id,Util.pluckField(salesOpsUsers, User.Email));
                mapOfAccountIdToAccount.put(acc.Id, acc);
            }
		}


		emailHead = 'The following Account territory assignment has been changed and requires that SubTerritory be updated with the correct value:</br>';
		// generate emails 
		for(Id accId : mapOfAccountIdToEmailList.keySet())
		{
			// initialization
			 emailBody = null;
			 accountName = null;
			 geoString = null;
			 Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

			 // email addresses 
	         List<String> toAddresses= mapOfAccountIdToEmailList.get(accId);
	         System.debug('toaddresses'+toAddresses);
             if(toAddresses!=null && toAddresses.size()>0)
             {
                 mail.setToAddresses(toAddresses);

                 mail.setReplyTo('noreply@salesforce.com');
                 mail.setSenderDisplayName('Anaplan Sub Territory Action User');

                 // email subject and body
                 mail.setSubject('SubTerritory assignment needed for ' + mapOfAccountIdToAccount.get(accId).Parent_Division__c +' : ' +  mapOfAccountIdToAccount.get(accId).AKAM_Account_ID__c);

                 accountName = '</br>Account : <a href="'+ baseUrl+ accId +'">' +  mapOfAccountIdToAccount.get(accId).Name + '</a> ';    
                 geoString =  '</br>Geography : ' + mapOfAccountIdToAccount.get(accId).Geography_Formula__c 
                     + '</br>Division :' + mapOfAccountIdToAccount.get(accId).Division_Formula__c 
                     + '</br>Region : ' + mapOfAccountIdToAccount.get(accId).Division__c 
                     + '</br>Area : ' + mapOfAccountIdToAccount.get(accId).Region__c 
                     + '</br>Territory : ' + mapOfAccountIdToAccount.get(accId).Area__c;

                 emailBody = emailHead + accountName + geoString; 
                 mail.setPlainTextBody(emailBody);
                 mail.setHtmlBody(emailBody);
                 emailList.add(mail);
             }
        }

		System.debug('emailList : ' + emailList); 

        if(emailList.size()>0)
            Messaging.sendEmail(emailList);

		 sendEmailToUpdateAnaplanSubTerritoryFirstRunFlag = false;
		 
	}*/
	
	public static void handlePartnerTypeChange(List<Account> listOfAccountsWithChangedPartnerType)
    {
        if(!handlePartnerTypeChangeFirstRunFlag)
            return;      
        Map<Id, List<Merge_Contract_Header__c>> accountToContractsMap = new Map<Id, List<Merge_Contract_Header__c>>();
        List<String> listOfAccountIds = new List<Id>();
        for(Account acc : listOfAccountsWithChangedPartnerType)
        {
            listOfAccountIds.add(acc.Id);
        }
        List<Merge_Contract_Header__c> listOfMCH = [select Id, Partner_Type__c, Account_Name__c from Merge_Contract_Header__c where Account_Name__c in :listOfAccountIds];
        for(Merge_Contract_Header__c mch : listOfMCH)
        {
            if(!accountToContractsMap.containsKey(mch.Account_Name__c))
                accountToContractsMap.put(mch.Account_Name__c, new List<Merge_Contract_Header__c>());
            accountToContractsMap.get(mch.Account_Name__c).add(mch);
        }
            
        for(Account acc : listOfAccountsWithChangedPartnerType)
        {
            Integer allNullContracts = 1;
            acc.Validation_Override__c = true;
            if(acc.get('Partner_Type__c')==null)
            {
                acc.put('Partner_status__c', null);
            }
            else
            {
                if(Trigger.isUpdate)
                {
                    List<Merge_Contract_Header__c> listOfAssociatedContracts ;
                    if(accountToContractsMap.containsKey(acc.Id))
                    {
                        listOfAssociatedContracts= accountToContractsMap.get(acc.Id);
                        if (listOfAssociatedContracts.size() > 0)
                        {
                            for(Merge_Contract_Header__c currentContract : listOfAssociatedContracts)
                            {
                                if (String.isNotBlank(currentContract.Partner_Type__c))
                                {  
                                    acc.put('Partner_status__c', 'Partner');
                                    allNullContracts=0;
                                    break;
                                 }
                             }
                             if(allNullContracts==1)
                             {
                                acc.put('Partner_status__c', 'Prospect');         
                              }
                        }
                    }
                    else
                    {
                        acc.put('Partner_status__c', 'Prospect');
                    }
                }
                else if(Trigger.isInsert)
                {
                    acc.put('Partner_status__c', 'Prospect');
                }
            }
        }
        handlePartnerTypeChangeFirstRunFlag = false;
    }
	
	public static void afterInsertUpdate(Boolean isInsert, Account[] oldAccounts, Account[] newAccounts, Map<Id, Account> oldMap, Map<Id, Account> newMap) {

        if(newAccounts==null || newAccounts.size()==0) return;

			if (Test.isRunningTest() && ManagedPkgErrorClass.isFromManagedPackage)
		{
			return;
		}
		//Features_Toggle__c customSettingsPDRAUpdate = Features_Toggle__c.getInstance('AutoPDRAUpdateOnAcctInsert');
		//Account_Reassignment_Settings__c customSettingsRuleExceptionProfileIds = Account_Reassignment_Settings__c.getInstance('RuleExceptionProfileIds');
			
		// ------------- CR 900397 - Remove Other-New Other-Existing drop and add logic - START	
		  if(!isInsert) {
		  		// SFDC 1014
				// Contract Share Update.
				//List<Account> updateAccOwnerCShareList = new List<Account>();
				List<Account> updateRebateStatusToPartnerContactList=new List<Account>();
				//List<Account> updatePartnerAdminAccountShareList=new List<Account>();   // Added by chandra for CR 1625737  
				for (Account acc:newAccounts) {
					/*if (acc.OwnerId != oldMap.get(acc.Id).OwnerId && acc.OwnerID!=null) {
						updateAccOwnerCShareList.add(acc);
						updatePartnerAdminAccountShareList.add(acc);              // Added by chandra for CR 1625737
					}*/
					if(acc.Rebate_TC_Status__c !=oldMap.get(acc.id).Rebate_TC_Status__c 
					   || acc.Rebate_TC_Accepted_At__c!=oldMap.get(acc.id).Rebate_TC_Accepted_At__c
					   || acc.Rebate_TC_Rejected_At__c!=oldMap.get(acc.id).Rebate_TC_Rejected_At__c)
					{
						updateRebateStatusToPartnerContactList.add(acc);
					}
				}
				if(updateRebateStatusToPartnerContactList.size()>0)
				{
					L2Q_AccountTriggerClass.updatePartnerContactsWithRebateDetails(updateRebateStatusToPartnerContactList);
				}	
				/* Start Added by chandra for CR 1625737 */ 
				/*if(updatePartnerAdminAccountShareList.size()>0) {
					AccountReassignmentInterfaceClass.updateAccountShareForPartnerAdmins(updatePartnerAdminAccountShareList);
				}*/	
			   /* End Added by chandra for CR 1625737 */ 	
	    	}
		// ------------- CR 900397 - Remove Other-New Other-Existing drop and add logic - STOP
		
		//Create new Account_Reassignment__c object for each account insert for auto updating of PDRA values
		
		if(isInsert) {
			String userProfileId = userinfo.getProfileId();
			//SFDC-6598 Skip Assignment for SDO created Accounts based on IsAccountGovernanceProcessed__c
			List<Account> accReassignmentList = new List<Account>();
            if (GsmUtilClass.isFeatureToggleEnabledCustomMetadata('AutoPDRAUpdateOnAcctInsert') && !(userProfileId.contains(GsmUtilClass.getAccountReassignSettingValue('RuleExceptionProfileIds')))) {
                {
					for(Account acc :newAccounts)
					{
						if(!acc.IsAccountGovernanceProcessed__c)
						accReassignmentList.add(acc);
					}
				}
			if(accReassignmentList.size() > 0)
				AccountReassignmentTriggerClass.createAccountReassignmentRequests(accReassignmentList);
            }
        } 					
	}
	
	public static void afterUpdate(List<Account> lstAccounts, Map<Id, Account> oldMap) {

        if(lstAccounts==null || lstAccounts.size()==0) return;

		// Sonali Tandon - Start -- CR 3094031 -- Copy account vertical, subvertical, website onto lead and contact.
		Set<ID> changedVerticalAccountIDs = new Set<ID>();
		string akamAccIdsWithSOQLError = MarketingUtilClass.getMarketingSettingsValue('AccountsHavingSOQLLimitException');
		//Id marketoRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
		
		String exclusionAccounts = GsmUtilClass.getGSMSettingValue('AccTriggerCls_ExclusionAccountList'); //SFDC-2304
                Set<String> exclusionList= new Set<String>();
                if(exclusionAccounts!= null ){
                        exclusionList.addAll(exclusionAccounts.split(','));
                }
         System.debug('List of exclusionAccounts ' + exclusionList);
         //System.debug('MarketoRecordId' +marketoRecordTypeId);

        
		
		 //List<Account> listOfNetOpsAccountsToBeReassigned = new List<Account>();
        //Anand Hegde - automatically reassign netops accounts when sales_account is checked
        String netOpsUserId=GSMUtilClass.getGSMSettingValue('OppSchCls_NetOpsId'); //SFDC-2304
		
		//updated accounts
		/* MARIT-502
		for( Account acc : lstAccounts)
		{
			if(!exclusionList.contains(acc.Name))
				if(acc.Vertical__c!=oldMap.get(acc.Id).Vertical__c || acc.Sub_Vertical__c!=oldMap.get(acc.id).Sub_Vertical__c)
					if(acc.Vertical__c!=null && acc.Vertical__c!='' && !acc.Vertical__c.equals('Akamai Internal') && !akamAccIdsWithSOQLError.contains(acc.AKAM_Account_ID__c))
						changedVerticalAccountIDs.add(acc.Id);
		 /*if(acc.Sales_Account__c==true && acc.Sales_Account__c!=oldMap.get(acc.Id).Sales_Account__c && acc.OwnerIDAlt__c==netOpsUserId && acc.Network_Account__c==true && acc.request_for_sales_account__c==true)
            {
                listOfNetOpsAccountsToBeReassigned.add(acc);
            }*/
        //}
        /*if(listOfNetOpsAccountsToBeReassigned.size()>0)
        {
            approveLastPendingReassignment(listOfNetOpsAccountsToBeReassigned);
		}*/
        /* MARIT-502
		System.debug('Updated accs' + changedVerticalAccountIDs);
        if(changedVerticalAccountIDs.size() > 0)
		    updateContactAndLeadsWithVertical(changedVerticalAccountIDs);
		*/
		//updateOpptysChannelLevel(lstAccounts,oldMap);
		if(!partnerSellableUpdateFirstRunFlag) {
			return;
		}
		if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('Partner_Sellable_Country_Toggle')) //SFDC-2304
		{	
			// Sonali Tandon - SFDC-1096 -NAP -- Partner Country Implementation work- Start
	        Map<Id, String> mapOfAccountIdToBillingCountry                  = new Map<Id,String>();
	        Map<Id,String> mapOfPartnerInvolvedToPartnerSellableCountries   = new Map<Id,String>();

			for(Account acc : lstAccounts)
			{
				if(acc.isPartnerCustom__c == true && acc.Partner_Sellable_Countries__c!=oldMap.get(acc.Id).Partner_Sellable_Countries__c)
				{
					if(String.isBlank(acc.Partner_Sellable_Countries__c))
	               		mapOfPartnerInvolvedToPartnerSellableCountries.put(acc.Id, ''); 
	               	else
						mapOfPartnerInvolvedToPartnerSellableCountries.put(acc.Id, acc.Partner_Sellable_Countries__c);
				}

				if(acc.BillingCountry!=null && acc.BillingCountry!=oldMap.get(acc.Id).BillingCountry)
					mapOfAccountIdToBillingCountry.put(acc.Id, acc.BillingCountry);
			}

			if(mapOfPartnerInvolvedToPartnerSellableCountries.size()>0)
				L2Q_AccountTriggerClass.getAccountIdAndSetPartnerAuthorisedCountryFlag(mapOfPartnerInvolvedToPartnerSellableCountries);

			if(mapOfAccountIdToBillingCountry.size()>0)
				L2Q_AccountTriggerClass.getPartnerInvolvedAndSetPartnerAuthorisedCountryFlag(mapOfAccountIdToBillingCountry);

			// Sonali Tandon - SFDC-1096 -NAP -- Partner Country Implementation work - End 
		}
		
		partnerSellableUpdateFirstRunFlag = false;
		
	}
	/* MARIT-502
	static void updateContactAndLeadsWithVertical(Set<ID> changedVerticalAccountIDs){
		if(!updateContactAndLeadsWithVerticalFirstRunFlag) {
			return;
		}
		List<Contact> updateableContacts = new List<Contact>();
		List<Lead> updateableLeads = new List<Lead>();
		Id marketoRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
		// get the associated contacts and leads
		if(changedVerticalAccountIDs.size()>0)
		{
			updateableContacts = [Select Akamai_Vertical__c,Sub_Vertical__c, Account.Vertical__c, Account.Sub_Vertical__c from Contact where Contact.AccountId IN : changedVerticalAccountIDs];
			updateableLeads = [Select Website,Associated_Account__r.Website,Akamai_Vertical__c,Sub_Vertical__c, Associated_Account__r.Vertical__c, Associated_Account__r.Sub_Vertical__c from Lead where (Status='New' OR status = 'In Process') AND Lead.Associated_Account__c IN : changedVerticalAccountIDs AND RecordTypeId !=: marketoRecordTypeId];
		}
		//sync account and contact vertical & sub vertical
		if(updateableContacts.size()>0)
		{
			for(Contact c : updateableContacts)
			{
				c.Akamai_Vertical__c = c.Account.Vertical__c;
				c.Sub_Vertical__c = c.Account.Sub_Vertical__c;
				c.Validation_Override__c = true;
			}
		}
		//sync account and lead vertical & sub vertical
		if(updateableLeads.size()>0)
		{
			for(Lead l : updateableLeads)
			{
				l.Akamai_Vertical__c = l.Associated_Account__r.Vertical__c;
				l.Sub_Vertical__c = l.Associated_Account__r.Sub_Vertical__c;
				l.Website = l.Associated_Account__r.Website;
				l.Validation_Override__c = true;
			}

		}
		System.debug('List of contacts to be updated' + updateableContacts);
		System.debug('List of leads to be updated' + updateableLeads);

		update updateableContacts;
		update updateableLeads;
		updateContactAndLeadsWithVerticalFirstRunFlag = false;
	}
	*/
	//SFDC-1595
	/*static void updateOpptysChannelLevel(List<Account> lstAccounts, Map<Id, Account> oldMap){
		if(!updateOpptysChannelLevelFirstRunFlag) {
			return;
		}
		List<Opportunity> populateChannelLevelList = new List<Opportunity>();
		List<Account> changedFieldsAcc = new List<Account>();
		Set<String> fields = new Set<String>();
		fields.addAll(GsmUtilClass.getPRMSettingValue('ChannelLevel_AccFieldChange').split(','));
		system.debug(LoggingLevel.ERROR,'fields: '+fields+' lstAccounts: '+lstAccounts.size());
		for(Account acc: lstAccounts){
			//for an indirect account if akam territory mapping id got changed
			system.debug(LoggingLevel.ERROR,'Tigger: '+Trigger.isUpdate+'acc in class: '+acc.Region__c+' acc parent: '+acc.Parent_Division__c);
			system.debug(LoggingLevel.ERROR,'oldMap.get(acc.id):: '+oldMap.get(acc.id).Gssm_class__c+' : new '+acc.gssm_class__c);
			if((acc.Indirect_Customer__c || acc.IsPartnerCustom__c || acc.IsPartner) && util.hasChanges(fields,oldMap.get(acc.id),acc))
				changedFieldsAcc.add(acc);
			}
			system.debug(LoggingLevel.ERROR,'changedFieldsAcc: '+changedFieldsAcc);
			if(!changedFieldsAcc.isEmpty()){
				//get only open indirect opptys 
				populateChannelLevelList = [select id,GSSM_Key__c,Channel_Hierarchy_Map__c from Opportunity where Deal_Type__c!=null AND Deal_Type__c='Indirect' AND (accountId in :changedFieldsAcc OR Partner_Involved__c in :changedFieldsAcc) AND Partner_Involved__c!=null AND (NOT stageName Like 'Closed%')];
				system.debug(LoggingLevel.ERROR,'populateChannelLevelList: '+populateChannelLevelList);
				if(populateChannelLevelList!=null){
					List<Opportunity> populatedChannelLevel = OpportunityPRMTriggerClass.populateChannelLevel(populateChannelLevelList,true);
					system.debug(LoggingLevel.ERROR,'populatedChannelLevel: '+populatedChannelLevel);
					if(!populatedChannelLevel.isEmpty())
						GsmUtilClass.doDatabaseUpdate(populatedChannelLevel,'AccountTriggerClass','populateChannelLevel');
					}
			}
	}*/

	@future
	public static void getPartnerInvolvedAndSetPartnerAuthorisedCountryFlag(Map<Id, String> mapOfAccountIdToBillingCountry)
	{
		Map<Id,String> mapOfPartnerInvolvedToPartnerSellableCountries   = new Map<Id,String>();
		List<Id> listOfPartnerInvolvedIds = new List<Id>();
		List<Opportunity> listOfOpptysForPartnerAuthorisedCountryFlag = new List<Opportunity>();

		if(mapOfAccountIdToBillingCountry.size()>0)
		{
			// get all Partner involved account ids for the opportunities whose Account's Billing country has changed
			for(Opportunity oppty : [Select Id,Partner_Involved__c, Partner_Involved__r.Partner_Sellable_Countries__c,Is_Authorized_Partner_Sellable_Country__c,AccountId, Account.BillingCountry, Validation_Override__c from Opportunity where AccountId IN : mapOfAccountIdToBillingCountry.keySet() AND 
				Partner_Involved__c!=null AND isWon = false AND isClosed = false])
			{
				
                    listOfOpptysForPartnerAuthorisedCountryFlag.add(oppty);
                    if(String.isBlank(oppty.Partner_Involved__r.Partner_Sellable_Countries__c))
                		mapOfPartnerInvolvedToPartnerSellableCountries.put(oppty.Partner_Involved__c, '');  
                	else
                		mapOfPartnerInvolvedToPartnerSellableCountries.put(oppty.Partner_Involved__c, oppty.Partner_Involved__r.Partner_Sellable_Countries__c);  

                
			}

			if(mapOfPartnerInvolvedToPartnerSellableCountries.size()>0)
				L2Q_AccountTriggerClass.setPartnerAuthorisedCountryFlag(mapOfAccountIdToBillingCountry,mapOfPartnerInvolvedToPartnerSellableCountries,listOfOpptysForPartnerAuthorisedCountryFlag, 'Account');
		}
	}
	@future
	public static void getAccountIdAndSetPartnerAuthorisedCountryFlag(Map<Id, String> mapOfPartnerInvolvedToPartnerSellableCountries)
	{
		Map<Id,String> mapOfAccountIdToBillingCountry = new Map<Id,String>();   
		List<Opportunity> listOfOpptysForPartnerAuthorisedCountryFlag = new List<Opportunity>();

		if(mapOfPartnerInvolvedToPartnerSellableCountries.size()>0)
		{
			// get all account ids and account's billing country for the opportunties whose Partner Involved Account's Partner Sellable Countries has changed
			for(Opportunity oppty : [Select Id, Partner_Involved__c,Account.BillingCountry, AccountId, Is_Authorized_Partner_Sellable_Country__c,Validation_Override__c from Opportunity where Partner_Involved__c IN : mapOfPartnerInvolvedToPartnerSellableCountries.keySet() AND 
				AccountId!=null AND isWon = false AND isClosed = false AND Account.BillingCountry!=null])
			{
				mapOfAccountIdToBillingCountry.put(oppty.AccountId,oppty.Account.BillingCountry);
				listOfOpptysForPartnerAuthorisedCountryFlag.add(oppty);
			}

			if(mapOfAccountIdToBillingCountry.size()>0)
				L2Q_AccountTriggerClass.setPartnerAuthorisedCountryFlag(mapOfAccountIdToBillingCountry,mapOfPartnerInvolvedToPartnerSellableCountries,listOfOpptysForPartnerAuthorisedCountryFlag, 'Account');
		}

	}


    public static void setPartnerAuthorisedCountryFlag(Map<Id,String> mapOfAccountIdToBillingCountry,Map<Id,String>  mapOfPartnerInvolvedToPartnerSellableCountries, List<Opportunity> listOfOpptysForPartnerAuthorisedCountryFlag, String source)
    {

        List<Opportunity> listOfOpportunitiesToUpdate = new List<Opportunity>();

        for(Opportunity opportunity : listOfOpptysForPartnerAuthorisedCountryFlag)
        {
            if((mapOfPartnerInvolvedToPartnerSellableCountries.get(opportunity.Partner_Involved__c))!=null && mapOfAccountIdToBillingCountry.get(opportunity.AccountId)!=null)
            {
            	// if account's billing country is in the list of partner authorised selling countries
                if(mapOfPartnerInvolvedToPartnerSellableCountries.get(opportunity.Partner_Involved__c).containsIgnoreCase(mapOfAccountIdToBillingCountry.get(opportunity.AccountId)))
                {
                	if(opportunity.Is_Authorized_Partner_Sellable_Country__c!=true)
                	{
                		opportunity.Is_Authorized_Partner_Sellable_Country__c = true;
                		if(source == 'Account')
                		{
                			opportunity.Validation_Override__c = true;
                			listOfOpportunitiesToUpdate.add(opportunity);
                		}
                	}
                }
                else
                {
                	if(opportunity.Is_Authorized_Partner_Sellable_Country__c!=false)
                	{
                		opportunity.Is_Authorized_Partner_Sellable_Country__c = false;
                    	if(source == 'Account')
                		{
                			opportunity.Validation_Override__c = true;
                			listOfOpportunitiesToUpdate.add(opportunity);
                		}
                	}

                }
            }
        }
        system.debug(LoggingLevel.ERROR,' opportunity.Is_Authorized_Partner_Sellable_Country__c: '+opportunity.Is_Authorized_Partner_Sellable_Country__c);
       	if(listOfOpportunitiesToUpdate.size()>0)
       	{
       		partnerInvolvedAndSetPartnerAuthorisedCountryFlag = true;
       		accountIdAndSetPartnerAuthorisedCountryFlag = true;
       		update listOfOpportunitiesToUpdate;
       	}
       
    }
    
    /*public static void approveLastPendingReassignment(List<Account> listOfNetOpsAccountsToBeReassigned)
    {
        if(!approveLastPendingReassignmentFirstRunFlag)
            return;

        //get the list of Account_Reassignment__c which have approval pending
        // form a map of account id -> Account_Reassignment__c latest
        // mark these reassignments as accepted, reassign=true
        List<Account_Reassignment__c> listOfPendingReassignmentRequests = [select id, Account__c, Reassign_Status__c, Reassignment_Due_Date__c, Reassign__c from Account_Reassignment__c where Account__c in :listOfNetOpsAccountsToBeReassigned and Reassign_Status__c='Approval Pending' order by CreatedDate ASC];
        Map<Id, Account_Reassignment__c> accIdToLastPendingReassignment = new Map<Id, Account_Reassignment__c>();
        System.Debug('#### approveLastPendingReassignment ' + listOfPendingReassignmentRequests);

        if(listOfPendingReassignmentRequests.size()>0)
        {
            for(Account_Reassignment__c ithReassignment : listOfPendingReassignmentRequests)
            {
                //this makes sure that we are updating only the last pending reassignment for every account
                accIdToLastPendingReassignment.put(ithReassignment.Account__c, ithReassignment);
            }
        }

        List<Account_Reassignment__c> listOfReassignmentsToBeApproved = new List<Account_Reassignment__c>();
        for(Account_Reassignment__c ithReassignment: accIdToLastPendingReassignment.values())
        {
            listOfReassignmentsToBeApproved.add(new Account_Reassignment__c(id=ithReassignment.Id, Reassign_Status__c='Approved', Reassign__c=true, Reassignment_Due_Date__c=Date.today()));
        }
        if(listOfReassignmentsToBeApproved.size()>0)
        {
            update listOfReassignmentsToBeApproved;
        }
        approveLastPendingReassignmentFirstRunFlag = false;
    }*/
   

    /* =====Added by Hitesh CR 2988722====
    If Financial Risk field is populated Credit check field gets wiped out and vice versa*/
    public static void updateFinancialRiskCreditCheck(List<Account> accountList,Map<Id, Account> oldMap)
    {
    	List<String> financialRiskNonCovidValue1 = GSMUtilClass.getGSMSettingValue('Financial_Risk_Non_CoVID_Values').split(',');
    	List<String> financialRiskNonCovidValue2 = GSMUtilClass.getGSMSettingValue('Financial_Risk_Non_CoVID_Values2').split(',');
    	
    	for(Account acc : accountList){

		      if( (acc.Credit_Check_Status__c != oldMap.get(acc.Id).Credit_Check_Status__c ) /*&& ( (oldMap.get(acc.Id).Credit_Check_Status__c == '') || (oldMap.get(acc.Id).Credit_Check_Status__c == null) )*/ && financialRiskNonCovidValue1.contains(acc.Financial_Risk__c))    
		          acc.Financial_Risk__c = null;
		      if( (acc.Financial_Risk__c != oldMap.get(acc.Id).Financial_Risk__c ) /*&& ( (oldMap.get(acc.Id).Financial_Risk__c == '') || (oldMap.get(acc.Id).Financial_Risk__c == null) )*/ && financialRiskNonCovidValue2.contains(acc.Financial_Risk__c))
		          acc.Credit_Check_Status__c = null;
		          
    	}
    }

    //SFDC-5433
    public static void addGlobalAccountManager(List<Id> childAccountIds, List<Id> companyIds){

    	String queryStr = 'SELECT Id, Company__r.OwnerId FROM Account WHERE Company__c != NULL AND Company__r.IsGlobalAccount__c = TRUE AND ';
    	if(childAccountIds != null)
    		queryStr = queryStr + 'Id IN : childAccountIds';
    	else
    		queryStr = queryStr + 'Company__c IN : companyIds';

    	List<AccountTeamMember> atmToInsert = new List<AccountTeamMember>();
        List<AccountShare> shareToInsert = new list<AccountShare>();

        List<Account> childAccounts = Database.query(queryStr);
        Map<String,AccountTeamMember> ownerToExistingATM = new Map<String,AccountTeamMember>();
	    for(AccountTeamMember existingATM : [SELECT Id, UserId, AccountId, CaseAccessLevel, TeamMemberRole FROM AccountTeamMember WHERE AccountId IN : childAccounts]){
	    	ownerToExistingATM.put(existingATM.AccountId+'#'+existingATM.UserId,existingATM);
	    }

	    String userExclusionList = GsmUtilClass.getGSMSettingValue('ONAPoolOpsIdList');
	    
        for(Account child : childAccounts){
        	if(!userExclusionList.contains(child.Company__r.OwnerId)){
	            AccountTeamMember atm = new AccountTeamMember();
	            AccountShare share = new AccountShare();
	            atm.AccountId = child.Id;
	            atm.UserId = child.Company__r.OwnerId;
	            share.AccountId = child.Id;
	            share.UserOrGroupId = child.Company__r.OwnerId;
	            share.AccountAccessLevel = 'Edit';
	            share.OpportunityAccessLevel = 'Edit';

	            String key = child.Id+'#'+child.Company__r.OwnerId;
	            if(ownerToExistingATM.containsKey(key)){
	            	atm.TeamMemberRole = ownerToExistingATM.get(key).TeamMemberRole;
	            	share.CaseAccessLevel = ownerToExistingATM.get(key).CaseAccessLevel;
	            }
	            else{
	            	atm.TeamMemberRole = 'Sales - Global Account Manager';
	            	share.CaseAccessLevel = 'None';
	            }

	            shareToInsert.add(share);
	            atmToInsert.add(atm);
        	}
        }

        if(atmToInsert.size() > 0){
            //L2Q_AaccountTeamMemberTriggerClass.AccountTeamMemberUpdateExclusion=true;
            GsmUtilClass.doDatabaseInsert(atmToInsert,'L2Q_AccountTriggerClass','addGlobalAccountManager',true);
			//L2Q_AaccountTeamMemberTriggerClass.AccountTeamMemberUpdateExclusion=false;
		}
        if(shareToInsert.size() > 0)
            GsmUtilClass.doDatabaseInsert(shareToInsert,'L2Q_AccountTriggerClass','addGlobalAccountManager',true);
    }

    //SFDC-5433
    public static void removeGlobalAccountManager(List<Id> childAccountIds, List<Id> companyIds, List<Id> ownerIds, Boolean isParent){

    	String queryStr = 'SELECT Id, OwnerId FROM Account WHERE ';
    	if(isParent)
    		queryStr = queryStr + 'Company__c IN : companyIds';
    	else
    		queryStr = queryStr + 'Id IN : companyIds';

    	for(Account child : Database.query(queryStr)){
    		if(isParent)
    			childAccountIds.add(child.Id);
    		else
    			ownerIds.add(child.OwnerId);
    	}

    	List<AccountTeamMember> atmDeleteList = [select Id from AccountTeamMember where AccountId IN : childAccountIds AND UserId IN : ownerIds AND TeamMemberRole = 'Sales - Global Account Manager'];
    	if(atmDeleteList.size() > 0){
			//L2Q_AaccountTeamMemberTriggerClass.AccountTeamMemberUpdateExclusion=true;
    		Database.Delete(atmDeleteList,false);
			//L2Q_AaccountTeamMemberTriggerClass.AccountTeamMemberUpdateExclusion=false;
		}
    }
    //SFDC-5436
    Public static void UpdateVerticalSubVertical(List<Account> AccList,Set<String> SICCodeSet){

		if(!updateVerticalSubVerticalFromDuns)
			return;
    
        map<string,list<string>> VerticalSubVerticalMapping =new map<string,list<string>>();
        for(SIC_Code_Mapping__c Rec :[select id,SIC_Code__c, Sub_Vertical__c, Vertical__c from SIC_Code_Mapping__c where SIC_Code__c in: SICCodeSet ]){
    
                 if (!VerticalSubVerticalMapping.containsKey(Rec.SIC_Code__c))
                      VerticalSubVerticalMapping.put(Rec.SIC_Code__c, new List<String>{Rec.vertical__c,rec.Sub_Vertical__c});
        }
         
        for(account acc : acclist){
         	if(VerticalSubVerticalMapping.containskey(acc.DUNS_SIC__c)){      
				acc.vertical__c = VerticalSubVerticalMapping.get(acc.DUNS_SIC__c)[0];
				acc.sub_vertical__c = VerticalSubVerticalMapping.get(acc.DUNS_SIC__c)[1];    
                }
			else{
				acc.vertical__c = 'Unknown';
				acc.sub_vertical__c = 'Unknown';
			}
        	acc.Vertical_Sub_Vertical_Status__c ='Automated'; 
			acc.IVSV_Automation__c = True;
		}
		updateVerticalSubVerticalFromDuns = false;
 	}
 	
 /* SFDC-6867
 public static void UpdateVerticalSubVerticalStatus(List<Account> AccList,Map<Id, Account> oldMap,Boolean BeforeAfterFlag){
       
       if(!UpdateVerticalSubVerticalStatusFirstRun) {
            return;
        }
       String ProfileIds = GsmUtilClass.getGSMSettingValue('VerticalSub_Vertical_UpdatedProfileIds'); 
       string marketingBusinesProfile=GsmUtilClass.getGSMSettingValue('Marketing_wo_Import'); 
       string MarketProfileIds= ProfileIds + marketingBusinesProfile; 
	
	list<account> UpdateAccountList=new list<account>();     
 	  system.debug('Swati>>'+BeforeAfterFlag);
        for(Account acc : AccList){ 

        	if(BeforeAfterFlag){
        		 Account aux  = new Account(Id = acc.Id);
        		 system.debug('Swati>>'+aux);
       
        		if(!MarketProfileIds.contains(userinfo.getprofileid()) && acc.vertical__c != null && acc.sub_vertical__c != null){
                    aux.Vertical_Sub_Vertical_Status__c ='Initial Assignment';
                   }
              else if(profileIds.contains(userinfo.getprofileid()) && acc.vertical__c != null && acc.sub_vertical__c != null ){
                        aux.Vertical_Sub_Vertical_Status__c ='Manually Assigned';
                        
               }
               else if(marketingBusinesProfile.contains(userinfo.getprofileid())){
                         aux.Vertical_Sub_Vertical_Status__c ='Override'; 
                }
                aux.Validation_Override__c = true;
					UpdateAccountList.add(aux); 
					system.debug('Swati>>'+aux);

        	}else{
        		if(!MarketProfileIds.contains(userinfo.getprofileid()) && (String.isEmpty(oldMap.get(acc.Id).vertical__c) || String.isEmpty(oldMap.get(acc.Id).sub_vertical__c) || oldMap.get(acc.Id).vertical__c =='Unknown' || oldMap.get(acc.Id).sub_vertical__c == 'Unknown') && !GsmUtilClass.getGSMSettingValue('SicCodeUpdatedByIntegrationProfileIds').contains(userinfo.getprofileid())){
                   		acc.Vertical_Sub_Vertical_Status__c ='Initial Assignment';
                }
                else if(profileIds.contains(userinfo.getprofileid()) ){
                        acc.Vertical_Sub_Vertical_Status__c ='Manually Assigned';
               }
               else if(marketingBusinesProfile.contains(userinfo.getprofileid())){
                         acc.Vertical_Sub_Vertical_Status__c ='Override'; 
                }
        	}
         }
         UpdateVerticalSubVerticalStatusFirstRun=false;
       if(BeforeAfterFlag && UpdateAccountList.size() > 0)
                 GsmUtilClass.doDatabaseUpdate(UpdateAccountList,'L2Q_AccountTriggerClass','UpdateVerticalSubVerticalStatus');
                     
      
 }
 */

    //SFDC-5913
    Public static void UpdateUSPhoneFormat(list<account> acclist){
    string str;
    for(account acc:acclist){
        //string phnumber = acc.phone;

        if(acc.phone.substring(0,2) =='+1'){

            str= acc.phone.substring(2,acc.phone.length());
        }
        else{

            str= acc.phone;
        }
        //system.debug('phone no::'+str);
        String onlyNumber= str.replaceAll('[^0-9]','');
        system.debug('value of s::'+onlyNumber);
        if(onlyNumber.length() == 10)
            acc.phone='(' + onlyNumber.substring(0, 3) + ') ' + onlyNumber.substring(3, 6) + '-' + onlyNumber.substring(6);
        else if(onlyNumber.length() > 10){
            string finalNum = onlyNumber.substring(0,10);
            acc.phone = '(' + finalNum.substring(0, 3) + ') ' + finalNum.substring(3, 6) + '-' + finalNum.substring(6);
        }
    }


 }

  //Start of SFDC-9138 -- Rajul Vishwakarma
  public static void updateAndInsertAccountHelperObjects(Set<Id> uniqueAccountIds){
	if(!upsertAccountHelperFirstRun){
		return;
	} 	
	  Map<Id,Account> accWithIdMap = new Map<Id,Account>([SELECT Id FROM Account WHERE (NOT Name LIKE '%DO NOT DELETE%') AND Id = :uniqueAccountIds]);
	  Set<Count_Leads_And_Contacts_On_Acc_Helper__c> updatedAccountHelperObj = new Set<Count_Leads_And_Contacts_On_Acc_Helper__c>();
	  for(Id aid:accWithIdMap.keySet()){
		Count_Leads_And_Contacts_On_Acc_Helper__c accHelp = new Count_Leads_And_Contacts_On_Acc_Helper__c(Account_Id__c = aid+'');
		  accHelp.isProcessed__c = false;
		  updatedAccountHelperObj.add(accHelp);
	  }
	  List<Count_Leads_And_Contacts_On_Acc_Helper__c> updatedAccountHelperObjList = new List<Count_Leads_And_Contacts_On_Acc_Helper__c>(updatedAccountHelperObj);
	  if(updatedAccountHelperObjList.size()>0){
		upsert updatedAccountHelperObjList Account_Id__c;
	}
	upsertAccountHelperFirstRun = false;
  }
  // End of Start of SFDC-9138
}