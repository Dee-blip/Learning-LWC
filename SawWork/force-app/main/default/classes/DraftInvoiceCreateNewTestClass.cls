/**
 	Ali IM				24/04/2013		Created the class
										CR 2175581 - IR Case - For Ad hoc Manual Draft Invoices, auto-populate the Invoice number.
										-> Test class for DraftInvoiceCreateNew.cls
	Ankit Chawla	15/10/18  SFDC-3619: Changing name of profile Sales - Rep to Sales - Media
 */
@isTest(SeeAllData=false)
private class DraftInvoiceCreateNewTestClass
{
	private static Boolean initFlag = false;
	private static User newOwner;
	private static User newOwnerRSM;
	private static User cmgUser;
	private static User crmUser;
	private static User sysAdmin = SObjectFactory.ADMIN_USER;
	private static Account_Reassignment_Rule__c newOwnerRule;
	private static Date reviewDate;
	private static Account acc1;
	private static AccountTeamMember atmEscalOwner;
	private static AccountTeamMember atmCMGAnalyst;
	private static Opportunity opp1;
	private static Merge_Contract_Header__c mch1;
	private static Merge_Contract_Manual_List__c mcManList;
	private static Invoice__c prevMonthFinalInvoice;
	private static Map<String, GSM_Settings__mdt> testcaseCustomSettings = GsmUtilClass.getGSMSettingValue();

	/**
		createContractHeader
			- generates a new Contract record based on parameters
			- returns Contract
	*/
	private static Merge_Contract_Header__c createContractHeader(String pName, Id pAccId, Id pOpptyId)
	{
		Merge_Contract_Header__c ch=new Merge_Contract_Header__c();
		ch.Name=pName;
		ch.Account_Name__c=pAccId;
		ch.Opportunity_Name__c=pOpptyId;
		ch.Cancellation_Date__c=Date.today().addMonths(5);
		ch.Effective_Start_Date__c=Date.today().addMonths(-2);
		ch.Effective_End_Date__c=Date.today().addYears(1);
		ch.Locked__c=true;
		ch.Active__c=true;
		ch.Acceptance_Date__c=Date.today().addMonths(-1);
		ch.Contract_Type__c = 'Direct Customer';
		ch.Double_Invoice_Review__c=true;
		ch.Manual_List__c=true;
		return ch;
	}
	/**
		refreshContractHeaderList()
	*/
	private static List<Merge_Contract_Header__c> refreshContractHeaderList(List<Merge_Contract_Header__c> contractList)
	{
		return [select Id, Name, Acceptance_Date__c,Account_Name__c,Opportunity_Name__c,Opportunity_Name__r.AKAM_Opportunity_ID__c,Cancellation_Date__c,
			Effective_End_Date__c,Effective_Start_Date__c,Double_Invoice_Review__c,Manual_List__c,Order_Id__c,Contract_Type__c,OwnerId
		 		From Merge_Contract_Header__c where id IN :contractList];
	}
	/**
	 	refreshContractHeader()
	*/
	private static Merge_Contract_Header__c refreshContractHeader(Merge_Contract_Header__c contract)
	{
		return refreshContractHeaderList(new List<Merge_Contract_Header__c> {contract})[0];
	}

	/**
		createContractMList()
	*/
	private static Merge_Contract_Manual_List__c createContractManualList(String pMListName, String pCI_OriginalContractId)
	{
		Merge_Contract_Manual_List__c newMList = new Merge_Contract_Manual_List__c();
		newMList.CI_Original_Contract_Id__c = pCI_OriginalContractId;
		newMList.Manual_List_Id__c = pMListName;
		return newMList;
	}
	/**
		refreshContractMLists()
	*/
	public static List<Merge_Contract_Manual_List__c> refreshContractMLists(List<Merge_Contract_Manual_List__c> pContractMLists)
	{
		return [SELECT id, Contract_Id__c,End_Date__c,Manual_List_Id__c,Name,Original_Contract_Id__c,Priority__c,Review_Date__c,
			Review_Frequency__c,Owner__c from Merge_Contract_Manual_List__c where Id IN :pContractMLists];
	}
	/**
		refreshContractMList()
	*/
	public static Merge_Contract_Manual_List__c refreshContractMList(Merge_Contract_Manual_List__c pContractMList)
	{
		return refreshContractMLists(new List<Merge_Contract_Manual_List__c> {pContractMList})[0];
	}

	/**
		createInvoice()
	*/
	public static Invoice__c createInvoice(String pCI_accountId, String pContractId, String pInvoiceId, Date pInvDate, Decimal pAmount)
	{
		Invoice__c newInvoice = new Invoice__c();
		newInvoice.CI_Account_Name__c = pCI_accountId;
		newInvoice.CI_Original_Contract_Id__c=pContractId;
		newInvoice.Invoice_Date__c= pInvDate;
		newInvoice.Name = pInvoiceId;
		newInvoice.Original_Amount__c=pAmount;
		return newInvoice;
	}

	/**
	 	refreshInvoice()
	*/
	private static Invoice__c refreshInvoice(Invoice__c pInvoice)
	{
		return refreshInvoiceList(new List<Invoice__c> {pInvoice})[0];
	}
	/**
	 	refreshInvoiceList()
	*/
	private static List<Invoice__c> refreshInvoiceList(List<Invoice__c> pInvoiceList)
	{
		return [select Id,Name,Account_Name__c,Original_Contract_Id__c,Invoice_Date__c,Original_Amount__c from Invoice__c where Id IN:pInvoiceList];
	}

	/**
		createDraftInvoice()
	*/
	public static Draft_Invoice__c createDraftInvoice(String pCI_accountId, String pContractId, String pInvoiceId, Date pInvDate, Decimal pAmount)
	{
		Draft_Invoice__c newInvoice = new Draft_Invoice__c();
		//newInvoice.CI_Account_Name__c = pCI_accountId;
		//newInvoice.CI_Original_Contract_Id__c=pContractId;
		newInvoice.Invoice_Date__c= pInvDate;
		newInvoice.Name = pInvoiceId;
		newInvoice.Original_Amount__c=pAmount;
		newInvoice.Type__c= 'UI';
		return newInvoice;
	}
	/**
	 	refreshDraftInvoice()
	*/
	private static Draft_Invoice__c refreshDraftInvoice(Draft_Invoice__c pInvoice)
	{
		return refreshDraftInvoiceList(new List<Draft_Invoice__c> {pInvoice})[0];
	}
	/**
	 	refreshDraftInvoiceList()
	*/
	private static List<Draft_Invoice__c> refreshDraftInvoiceList(List<Draft_Invoice__c> pInvoiceList)
	{
		return [select Id,Name,Account_Name__c,Invoice_Review_Case_Audit__c,OwnerId,Case__c,Type__c,Original_Contract_Id__c,Invoice_Date__c,Original_Amount__c from Draft_Invoice__c where Id IN:pInvoiceList];
	}

/**
		getCasesBulk()
	*/
	public static List<Case> getCases(List<Merge_Contract_Header__c> mchList, Date pReviewDate)
	{
		return [Select Id,IR_Case_Locked__c, OwnerId, Description,RecordTypeId,Contract_Manual_List_Priority__c,IR_Defer_Until__c, IR_Escal_Owner__c,IR_Invoice_Number__c,IR_Invoice_Date__c,Status,IR_Original_Contract_Id__c,
            Validation_Override__c,CreatedDate,IR_CurrentInvoiceAmount__c, IR_CurrentInvoiceImportDate__c, IR_CurrentInvoiceNumber__c, IRCache_Acceptance_Date__c, IRCache_hasDoubleInvoiceReview__c, IRCache_isManual__c,
                IRCache_AkamOpportunityId__c,IRCache_isMissingFinalInvCheck__c, IRCache_isNewInvoice__c, IRCache_hasThresholdViolation__c from Case where IR_Invoice_Date__c = :pReviewDate AND
                    IR_Original_Contract_Id__c!=null AND IR_Original_Contract_Id__c IN :mchList AND CreatedDate=LAST_N_DAYS:30]; //AND RecordTypeId IN :irRectypesMap.values()
	}
	/**
		getCasesBulk()
	*/
	public static List<Case> getCases(List<Id> pCaseIdList)
	{
		return [Select Id,IR_Case_Locked__c, OwnerId, Description,RecordTypeId,Contract_Manual_List_Priority__c,IR_Defer_Until__c, IR_Escal_Owner__c,IR_Invoice_Number__c,IR_Invoice_Date__c,Status,IR_Original_Contract_Id__c,
            Validation_Override__c,CreatedDate,IR_CurrentInvoiceAmount__c, IR_CurrentInvoiceImportDate__c, IR_CurrentInvoiceNumber__c, IRCache_Acceptance_Date__c, IRCache_hasDoubleInvoiceReview__c, IRCache_isManual__c,
                IRCache_AkamOpportunityId__c,IRCache_isMissingFinalInvCheck__c, IRCache_isNewInvoice__c, IRCache_hasThresholdViolation__c from Case where Id IN :pCaseIdList];
	}

	/**
		getCase()
	*/
	public static Case getCase(Merge_Contract_Header__c mch, Date pReviewDate)
	{
		return getCases(new List<Merge_Contract_Header__c> {mch}, pReviewDate)[0];
	}

	/**
		getCase()
	*/
	public static Case getCase(Id pCaseId)
	{
		return getCases(new List<Id> {pCaseId})[0];
	}

	/**
		RefreshOpportunity()
		- Overloaded to refresh Single Opportunity
	*/
	private static List<Opportunity> RefreshOpportunity(Opportunity pOpp)
	{
		return RefreshOpportunityList(new List<Opportunity> {pOpp});
	}

	/**
		RefreshOpportunityList()
		- Overloaded to refresh bulk Opportunities
	*/
	private static List<Opportunity> RefreshOpportunityList(List<Opportunity> pOppList)
	{
		return [select Id,Name,AKAM_Opportunity_ID__c,OwnerId,CreatedById from Opportunity where Id IN :pOppList];
	}

	/**
		RefreshAccount(Account acc)
		- Refresh single account
	*/
	private static Account RefreshAccount(Account acc)
	{
		ManagedPkgErrorClass.isFromManagedPackage = false;
		return RefreshAccountList(new Account[]{acc})[0];
	}
	/**
		RefreshAccountList(Account[] acc)
		- Refresh bulk accounts
	*/
	private static Account[] RefreshAccountList(Account[] accounts)
	{
		return [select Id,OwnerId,AKAM_Account_ID__c,Account_Status__c from Account where Id IN :accounts];
	}

	public static GSM_Custom_Settings__c initGSMCustomSetting(String name, String value){
		GSM_Custom_Settings__c newGSMCustomSetting = new GSM_Custom_Settings__c();
		newGSMCustomSetting.Name = name;
		newGSMCustomSetting.Value__c = value;
		return newGSMCustomSetting;
	}

	public static User GetUser(String name){
		return [select Id from User where Alias = :name LIMIT 1];
	}

	/**
		Init()
		- Intialize the static variables for this Test Class
	*/
    @testSetUp static void Init()
    {
    	ManagedPkgErrorClass.isFromManagedPackage = false;
    	if(initFlag)
    		return;

    	String profileName = 'Sales - Media' ;
			String roleName = testcaseCustomSettings.get('User_Role').Value__c;
        newOwner = utilTestClass.CreateUser('TST_NUSR', roleName, profileName);
        newOwnerRSM = utilTestClass.CreateUser('TST_NRSM', roleName, profileName);
        cmgUser = utilTestClass.CreateUser('CMG_USER', 'CMG', 'CMG');
        sysAdmin = utilTestClass.CreateUser('SYS_USER', 'System Administrator', 'System Administrator');
        crmUser = utilTestClass.CreateUser('CRM_USER', 'Worldwide', 'CRM Integration');
        insert (new User[] {newOwner, newOwnerRSM, cmgUser, sysAdmin, crmUser});

			System.runAs(sysAdmin){
				Test.startTest();
				list<GSM_Custom_Settings__c> lstGSM = new list<GSM_Custom_Settings__c>();

				lstGSM.add(initGSMCustomSetting('User_Role','2018_ECG'));
				lstGSM.add(initGSMCustomSetting('IRCase_DefaultInvoiceNumber','N/A'));
				lstGSM.add(initGSMCustomSetting('IRCase_CutOffDayOfMonth','24'));
				lstGSM.add(initGSMCustomSetting('IR_RecordTypeName_Default','Invoice_Review_Case'));
				lstGSM.add(initGSMCustomSetting('CRM_Integration',crmUser.Id));

				insert lstGSM;
				newOwnerRule = utilTestClass.CreateAccountReassignmentRule(newOwner.Name, newOwner.Id, roleName);
				newOwnerRule.Associated_User_RSM__c = newOwnerRSM.Id;
				insert (new Account_Reassignment_Rule__c[] {newOwnerRule});

				acc1 = utilTestClass.CreateAccount('IRCaseTestAcc1');
				insert acc1;
				acc1 = RefreshAccount(acc1);

				reviewDate = IRCaseHelperClass.getCurrentReviewCycleInvoiceDate();
				System.debug('reviewDate in TEST Method=' + reviewDate);

				opp1 = utilTestClass.CreateOpportunity('IRCaseOppty1', '1-Create');
				opp1.AccountId=acc1.Id;
				opp1.CloseDate=Date.today().addDays(10);
				insert opp1;

				mch1 = createContractHeader('IRCaseMCH1', acc1.Id, opp1.Id);
				insert mch1;
				mcManList = createContractManualList('IRCaseMlist1', mch1.Name);
				mcManList.Review_Frequency__c = 'Monthly';
				mcManList.End_Date__c = Date.today().addMonths(2);
				mcManList.Owner__c = 'UNKNOWN';
				mcManList.Review_Date__c = reviewDate;
				mcManList.Priority__c = 'TESTPRIORITY';
				insert mcManList;

				prevMonthFinalInvoice = createInvoice(acc1.AKAM_Account_ID__c, mch1.Name, '1303123567', reviewDate.addMonths(-1), 500);
				insert prevMonthFinalInvoice;

				initFlag = true;
				Test.stopTest();
			}
    }
    static testMethod void myUnitTest()
    {
			System.runAs(sysAdmin){
				reviewDate = IRCaseHelperClass.getCurrentReviewCycleInvoiceDate();
				User cmgUser = GetUser('CMG_USER');
				Account acc1 = SobjectRepository.getAccount();
				Opportunity opp1 = SobjectRepository.getOpportunity();
				Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
				Merge_Contract_Header__c mch1 = refreshContractHeader(mch1Id);
				Draft_Invoice__c di = createDraftInvoice(acc1.Id, mch1.Name, '1304123789', reviewDate, 500);
				di.OwnerId=cmgUser.Id;
				di.Original_Contract_Id__c=mch1.Id;
				insert di;
				Test.startTest();
				PageReference pageRef = Page.DraftInvoiceCreateNew;
        System.debug('mch1 =' + mch1);
        System.debug('di =' + di);
        pageRef.getParameters().put('CF00NG0000009avbL_lkid',mch1.Id);
        Test.setCurrentPageReference(pageRef);
        //ApexPages.Standardcontroller stdController = new ApexPages.Standardcontroller(new Draft_Invoice__c());
        DraftInvoiceCreateNew controller = new DraftInvoiceCreateNew(); //stdController
        PageReference returnUrl = controller.pageRedirect();
        Test.stopTest();
        // Assert
        system.assert(returnUrl.getUrl().contains('/a8b/e?'));
        String invoiceNumber = GsmUtilClass.GetCustomSettingValue('IRCase_DefaultInvoiceNumber'); //'N/A';
        system.assertEquals(di.Name,returnUrl.getParameters().get('Name')); // invoiceNumber
        system.assertEquals('1',returnUrl.getParameters().get('nooverride'));
        system.assertEquals(mch1.Id,returnUrl.getParameters().get('CF00NG0000009avbL_lkid'));
			}
    }
}