global class AccountReassignmentPageController {
	private string accountId;
    public Id pendingAccountReassignmentId {get;set;}
    public User accOwner {get;set;}
	public Account account {get;set;}
	public Account_Reassignment__c accReassign {get;set;}
	public Boolean isAccountActive {get;set;}
	public Boolean isAccountOwnerInactive {get;set;}
	public Boolean initializedFlag {get;set;}
	public Boolean isRevenueAccount {get;set;}
	public Boolean isAccountIdPresent {get;set;}
	public Boolean isNetOpsOwnedAccount {get;set;}
	public Boolean isAdminProfile {get;set;}
	public Boolean isNotInternalRevenueAccount {get;set;}
	public List<Account> acclist=new List<Account>();
	//public List<string> reasonCodeExcludeList =new List<string>();


    
    public PageReference cancel() {
		return new PageReference('/' + account.Id);
	}
    
    public AccountReassignmentPageController(){
        accountId = ApexPages.currentPage().getParameters().get('id');
        if(accountId == null || (accountId != null && accountId == '')){
            isAccountIdPresent = false;
            initializedFlag = false;
            showErrorAndDiscontinue(GsmUtilClass.getGSMSettingValue('AccReassign_MissingAccIdError'));
		}
        else
        {
            accList = [select Id,Name,Website,Account_Status__c,OwnerId,Old_Account_Owner__c,Owner.Status__c,
				/*Parent_Division__c,Region__c,Division__c,Area__c,Division_Formula__c,Geography_Formula__c,*/
				TERR_HIER_1__c, TERR_HIER_2__c, TERR_HIER_3__c, TERR_HIER_4__c, TERR_HIER_5__c,
				Anaplan_Sub_Territory__c,Akam_Territory_Mapping_Id__c,Normalized_Territory_ID__c,Normalized_Territory_Name__c,Customer_Type__c,Pipeline_Status__c,
				Revenue_Account__c,CurrencyIsoCode,Owner.Alias,Owner.ManagerId,AKAM_Account_ID__c 
				from Account where Id =: accountId
			];

			//reasonCodeExcludeList=AccountReassignmentDataClass.getCustomSettings('Revenue_Credit_Owner_Reason_Value').split(',');

			If(accList != null && !accList.isEmpty())
			account = accList[0];
            initializedFlag = true;
            isNotInternalRevenueAccount = true;
            
            map<Id, Account_Reassignment__c> pendingReassignmentRequests = AccountReassignmentTriggerClass.getPendingReassignmentRequests(new set<Id>{account.Id});
            if(pendingReassignmentRequests.containsKey(account.Id))
                pendingAccountReassignmentId = pendingReassignmentRequests.get(account.Id).Id;
            if(pendingAccountReassignmentId != null) {
                showErrorAndDiscontinue(AccountReassignmentDataClass.getCustomSettings('Error_Prevent_Duplicates'));
                initializedFlag = false;
            }
            
            string customSettingsIntRevAccOwnerChange = GSMUtilClass.getGSMSettingValue('AccReassign_InternalRevAccountToggle');
            String businessOpsProfileId = AccountReassignmentDataClass.getCustomSettings('BusinessOpeartionsProfileId');
            Set<String> accountAkamIdList = new Set<String> ();
            if(customSettingsIntRevAccOwnerChange == 'False' && !UserInfo.getProfileId().contains(businessOpsProfileId)) {
                for(GSM_Settings__mdt mdtRecord: [select Id, Value__c from GSM_Settings__mdt where DeveloperName like 'InternalRevAcc%']) {
                    accountAkamIdList.add(mdtRecord.value__c);
                }
                if (accountAkamIdList.contains(account.AKAM_Account_ID__c)) {
                    isNotInternalRevenueAccount = false;
                    showErrorAndDiscontinue(GSMUtilClass.getGSMSettingValue('AccReassign_InternalRevAccount'));
                }
            }
            
            if(initializedFlag){
                String strEffectiveMonthOftransfer = '';
				Boolean isPastCutOffDate = (Date.today().day() >= Integer.valueOf(AccountReassignmentDataClass.getCustomSettings('AssignNextMonthCutOffStart')) ? true : false);

				if (account.Revenue_Account__c || account.Opportunities.size() > 0 || account.Account_Status__c.contains('Active')) {
					isRevenueAccount = true;
					if(isPastCutOffDate) strEffectiveMonthOftransfer = 'next';
				}

				if(account.Owner.Status__c != 'Active') isAccountOwnerInactive = true;
				else isAccountOwnerInactive = false;

                if (isAccountOwnerInactive && account.Account_Status__c.contains('Lead')) {
                    strEffectiveMonthOftransfer = 'current';
                    if (account.Pipeline_Status__c == null || account.Pipeline_Status__c.contains(AccountReassignmentDataClass.getCustomSettings('DeferredAutoApprovedPipelineStatus')))
                        strEffectiveMonthOftransfer = 'next';
                }
                else if (!isAccountOwnerInactive && account.Account_Status__c.contains('Lead')) {
                    if (isPastCutOffDate) strEffectiveMonthOftransfer = 'next';
                    else strEffectiveMonthOftransfer = 'current';
                }
                else if (isAccountOwnerInactive && account.Account_Status__c.contains('Active'))
                    strEffectiveMonthOftransfer = 'next';

				accReassign = new Account_Reassignment__c();
				accReassign.CurrencyIsoCode = account.CurrencyIsoCode;
				accReassign.Account__c = account.Id;
				if (strEffectiveMonthOftransfer != null) {
					if (strEffectiveMonthOftransfer.equalsIgnoreCase('current'))
						accReassign.Effective_Month_Of_Transfer__c = 'Current Month';
					else if (strEffectiveMonthOftransfer.equalsIgnoreCase('next'))
						accReassign.Effective_Month_Of_Transfer__c = 'Next Month';
				}
            }
		}
    }
    
    public PageReference save() {
		try {
			/*if(accReassign.Reassign__c && !reasonCodeExcludeList.contains(accReassign.Reason_Code__c) 
            	&& acclist[0].Revenue_Account__c && accReassign.Revenue_credit_Owner__c ==null){

                accReassign.Revenue_credit_Owner__c.addError('Please enter the Revenue Credit Owner before submitting the request');
                return null;
                }else{*/
            insert accReassign;
       // }

		}catch (DMLException e) {
			for (Integer i = 0; i<e.getNumDml(); i++) {
				if (e.getDmlType(i) == Statuscode.FIELD_CUSTOM_VALIDATION_EXCEPTION ||
					e.getDmlType(i) == StatusCode.FIELD_FILTER_VALIDATION_EXCEPTION ||
					e.getDmlType(i) == StatusCode.CANNOT_INSERT_UPDATE_ACTIVATE_ENTITY) {
					String errMessage = e.getDmlMessage(i);
					String error = GsmUtilClass.getGSMSettingValue('AccountReassignment_ErrorToCompare');
					if (errMessage.contains(error)) {
						errMessage = '.Error : ' + GsmUtilClass.getGSMSettingValue('AccountReassignment_ErrorToShow');
					}
					showErrorAndDiscontinue(errMessage);
				}
                else throw e;
			}
			return null;
		}
		return new PageReference('/' + accReassign.Id);
	}
    
    public static void showErrorAndDiscontinue(string pErrorMessage){
		ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.ERROR, pErrorMessage);
		ApexPages.addMessage(errMsg);
	}
}