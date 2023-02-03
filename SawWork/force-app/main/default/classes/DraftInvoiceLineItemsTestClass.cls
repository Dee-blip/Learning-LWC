/**
Gautam Sargur    18/06/2013    Created the class   
                 CR 2274149    Need to create Trigger on Draft Invoice Line Items to resolve ids for parent Draft Invoices.
                               -> Test class for DraftInvoiceLineItemsTrigger.tgr  
*/

@isTest(seeAllData=false)
private class DraftInvoiceLineItemsTestClass {
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
	private static Merge_Contract_Manual_List__c createContractManualList(String pMListName, String pciOriginalContractId)
	{
		Merge_Contract_Manual_List__c newMList = new Merge_Contract_Manual_List__c();
		newMList.CI_Original_Contract_Id__c = pciOriginalContractId;
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
    
    public static Invoice_Review_Case_Audit__c createIRCARec(Date pInvDate, String pJobId)
  {
      Invoice_Review_Case_Audit__c newIRCA = new Invoice_Review_Case_Audit__c();
      newIRCA.Import_Status__c = 'Success';
      newIRCA.Import_Start_Date__c = Datetime.now().addDays(-1);
      newIRCA.Import_End_Date__c = Datetime.now().addDays(-1);
      newIRCA.Invoice_Review_Date__c = pInvDate;
      newIRCA.InvLoaderJobId__c = pJobId;
      return newIRCA;
  }

	/**
		createInvoice()
	*/
	public static Invoice__c createInvoice(Map<String, String> invoiceDetails, Date pInvDate, Decimal pAmount)
	{
		Invoice__c newInvoice = new Invoice__c();
		newInvoice.CI_Account_Name__c = invoiceDetails.get('pciAccountId');
		newInvoice.CI_Original_Contract_Id__c=invoiceDetails.get('pContractId');
		newInvoice.Invoice_Date__c= pInvDate;
		newInvoice.Name = invoiceDetails.get('pInvoiceId');
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
	public static Draft_Invoice__c createDraftInvoice(String pInvoiceId, Date pInvDate, Decimal pAmount)
	{
		Draft_Invoice__c newInvoice = new Draft_Invoice__c();
		//newInvoice.CI_Account_Name__c = pciAccountId;
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
		refreshOpportunity()
		- Overloaded to refresh Single Opportunity
	*/
	private static List<Opportunity> refreshOpportunity(Opportunity pOpp)
	{
		return refreshOpportunityList(new List<Opportunity> {pOpp});
	}

	/**
		refreshOpportunityList()
		- Overloaded to refresh bulk Opportunities
	*/
	private static List<Opportunity> refreshOpportunityList(List<Opportunity> pOppList)
	{
		return [select Id,Name,AKAM_Opportunity_ID__c,OwnerId,CreatedById from Opportunity where Id IN :pOppList];
	}

	/**
		refreshAccount(Account acc)
		- Refresh single account
	*/
	private static Account refreshAccount(Account acc)
	{
		ManagedPkgErrorClass.isFromManagedPackage = false;
		return refreshAccountList(new Account[]{acc})[0];
	}
	/**
		refreshAccountList(Account[] acc)
		- Refresh bulk accounts
	*/
	private static Account[] refreshAccountList(Account[] accounts)
	{
		return [select Id,OwnerId,AKAM_Account_ID__c,Account_Status__c from Account where Id IN :accounts];
	}

	public static GSM_Custom_Settings__c initGSMCustomSetting(String name, String value){
		GSM_Custom_Settings__c newGSMCustomSetting = new GSM_Custom_Settings__c();
		newGSMCustomSetting.Name = name;
		newGSMCustomSetting.Value__c = value;
		return newGSMCustomSetting;
	}

	/**
		init()
		- Intialize the static variables for this Test Class
	*/
    @testSetUp static void init()
    {
    	ManagedPkgErrorClass.isFromManagedPackage = false;
    	if(initFlag) {
    		return;
		}

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
				acc1 = refreshAccount(acc1);

				reviewDate = IRCaseHelperClass.getCurrentReviewCycleInvoiceDate();
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

				Map<String, String> invoiceDetails = new Map<String, String>();
				invoiceDetails.put('pciAccountId', acc1.AKAM_Account_ID__c);
				invoiceDetails.put('pContractId', mch1.Name);
				invoiceDetails.put('pInvoiceId', '1303123567');
				
				prevMonthFinalInvoice = createInvoice(invoiceDetails, reviewDate.addMonths(-1), 500);
				insert prevMonthFinalInvoice;

				initFlag = true;
				Test.stopTest();
			}
    }

    static testMethod void validateDraftInvoiceLineItems() {
        System.runAs(sysAdmin){
        Account acc = SobjectRepository.getAccount();
        
        Merge_Contract_Header__c mch1Id = [select Id from Merge_Contract_Header__c where Name = 'IRCaseMCH1' limit 1];
        Merge_Contract_Header__c contract = refreshContractHeader(mch1Id);

        Invoice_Review_Case_Audit__c firstCaseAudit = createIRCARec(Date.today().toStartOfMonth(),'IRCaseTest1');
        insert firstCaseAudit;

        Draft_Invoice__c firstInvoice = createDraftInvoice('12345678', reviewDate, 500);
        firstInvoice.Invoice_Review_Case_Audit__c=firstCaseAudit.Id;
        insert firstInvoice;
        
        // Invoice_Review_Case_Audit__c firstCaseAudit = new Invoice_Review_Case_Audit__c(Invoice_Review_Date__c=Date.today(), Import_Status__c='Success', Import_Start_Date__c=Datetime.now());
        // insert firstCaseAudit;

        // Draft_Invoice__c firstInvoice = createDraftInvoice(acc.Id, contract.Name, '12345678', reviewDate, 500);
        
        // Draft_Invoice__c firstInvoice = new Draft_Invoice__c(Name='12345678', Invoice_Review_Case_Audit__c=firstCaseAudit.Id, Account_Name__c=acc.Id, Original_Contract_Id__c=contract.Id);
        // insert firstInvoice;

        firstCaseAudit = [Select Id, Name, Case_Creation_Status__c, Case_Creation_Completed__c From Invoice_Review_Case_Audit__c Where Id = :firstCaseAudit.Id];
        firstCaseAudit.Case_Creation_Status__c = 'Success';
        firstCaseAudit.Case_Creation_Completed__c = true;
        update firstCaseAudit;

    //     Draft_Invoice_Line_Item__c diLineItem = new Draft_Invoice_Line_Item__c();
    // diLineItem.Draft_Invoice__c = di.id;
    // diLineItem.CI_Draft_Invoice_id__c = '12345678';
    // diLineItem.Account_ID__c = acc.id;
    // diLineItem.Create_Date__c = Date.today();
    // diLineItem.Create_User__c = sysAdmin.id;
    // diLineItem.Part_Number__c = '1';
    // diLineItem.Update_Date__c = Date.today();

    // insert diLineItem;
        
        List<Draft_Invoice_Line_Item__c> firstInsert = new List<Draft_Invoice_Line_Item__c>();
        for ( integer i = 0 ; i < 10 ; ++i ) {
            firstInsert.add( new Draft_Invoice_Line_Item__c( CI_Draft_Invoice_Id__c='12345678', Account_Id__c=acc.id, Create_Date__c=date.newInstance(2013, 7, 1),
                                                             Create_User__c=sysAdmin.id, Item_Line_Number__c=i+1, Item_Product__c='ABCD', Item_Sequence_Number__c=i+1,
                                                             Part_Number__c='10', Taxes__c=10, UOM__c='Mbps', Unit_Price__c=10, Update_date__c=date.newInstance(2013, 7, 1) ) );
        }
        insert firstInsert;
        
        firstInvoice = [Select Id, Name, Line_Items_Count__c From Draft_Invoice__c Where Id = :firstInvoice.Id];
        
        system.assertEquals(10, firstInvoice.Line_Items_Count__c);
        system.assertEquals('12345678', firstInvoice.Name);

        
        Invoice_Review_Case_Audit__c secondCaseAudit = createIRCARec(Date.today().toStartOfMonth(),'IRCaseTest2');
        // Invoice_Review_Case_Audit__c secondCaseAudit = new Invoice_Review_Case_Audit__c(Invoice_Review_Date__c=Date.today(), Import_Status__c='Success', Import_Start_Date__c=Datetime.now().addDays(1));
        insert secondCaseAudit;

        Draft_Invoice__c secondInvoice = createDraftInvoice('12345678', reviewDate, 500);
        secondInvoice.Invoice_Review_Case_Audit__c=secondCaseAudit.Id;
        
        // Draft_Invoice__c secondInvoice = new Draft_Invoice__c(Name='12345678', Invoice_Review_Case_Audit__c=secondCaseAudit.Id, Account_Name__c=acc.Id, Original_Contract_Id__c=contract.Id);
        insert secondInvoice;
        
        // List<Draft_Invoice_Line_Item__c> secondInsert = new List<Draft_Invoice_Line_Item__c>();
        // for ( integer i = 0 ; i < 10 ; ++i ) {
        //     secondInsert.add( new Draft_Invoice_Line_Item__c( CI_Draft_Invoice_Id__c='12345678', Account_Id__c='12345', Create_Date__c=date.newInstance(2013, 7, 1),
        //                                                      Create_User__c='gsargur', Item_Line_Number__c=i+1, Item_Product__c='ABCD', Item_Sequence_Number__c=i+1,
        //                                                      Part_Number__c='10', Taxes__c=10, UOM__c='Mbps', Unit_Price__c=10, Update_date__c=date.newInstance(2013, 7, 1) ) );
        // }
        // insert secondInsert;


        List<Draft_Invoice_Line_Item__c> secondInsert = new List<Draft_Invoice_Line_Item__c>();
        for ( integer i = 0 ; i < 10 ; ++i ) {
            secondInsert.add( new Draft_Invoice_Line_Item__c(Draft_Invoice__c=secondInvoice.id, CI_Draft_Invoice_Id__c='12345678', Account_Id__c=acc.id, Create_Date__c=date.newInstance(2013, 7, 1),
                                                             Create_User__c=sysAdmin.id, Item_Line_Number__c=i+1, Item_Product__c='ABCD', Item_Sequence_Number__c=i+1,
                                                             Part_Number__c='10', Taxes__c=10, UOM__c='Mbps', Unit_Price__c=10, Update_date__c=date.newInstance(2013, 7, 1) ) );
        }
        insert secondInsert;
        
        firstInvoice = [Select Id, Name, Line_Items_Count__c From Draft_Invoice__c Where Id = :firstInvoice.Id];
        secondInvoice = [Select Id, Name, Line_Items_Count__c From Draft_Invoice__c Where Id = :secondInvoice.Id];
        
        system.assertEquals(10, firstInvoice.Line_Items_Count__c);
        system.assertEquals('12345678', firstInvoice.Name);
        system.assertEquals(10, secondInvoice.Line_Items_Count__c);
        system.assertEquals('12345678', secondInvoice.Name);

        
        // Draft_Invoice__c thirdInvoice = new Draft_Invoice__c(Name='12345678', Account_Name__c=acc.Id, Original_Contract_Id__c=contract.Id);
        // insert thirdInvoice;

        Draft_Invoice__c thirdInvoice = createDraftInvoice('12345678', reviewDate, 500);
        insert thirdInvoice;
        
        List<Draft_Invoice_Line_Item__c> thirdInsert = new List<Draft_Invoice_Line_Item__c>();
        for ( integer i = 0 ; i < 10 ; ++i ) {
            
            thirdInsert.add( new Draft_Invoice_Line_Item__c( CI_Draft_Invoice_Id__c='12345678', Account_Id__c=acc.id, Create_Date__c=date.newInstance(2013, 7, 1),
                                                             Create_User__c=sysAdmin.id, Item_Line_Number__c=i+1, Item_Product__c='ABCD', Item_Sequence_Number__c=i+1,
                                                             Part_Number__c='10', Taxes__c=10, UOM__c='Mbps', Unit_Price__c=10, Update_date__c=date.newInstance(2013, 7, 1),
                                                             Is_From_Refresh__c=true ) );
        }
        try{
            insert thirdInsert;
        } catch( Exception e ) {
            List<String> error = new List<String>();
            error.add('Draft_Invoice__c');
            System.assertEquals( 'System.DmlException', e.getTypeName() );
            System.assertEquals( error, e.getDmlFieldNames(0) );
        }
        
        thirdInvoice = [Select Id, Name, Line_Items_Count__c From Draft_Invoice__c Where Id = :thirdInvoice.Id];
        secondInvoice = [Select Id, Name, Line_Items_Count__c From Draft_Invoice__c Where Id = :secondInvoice.Id];
        
        system.assertEquals(0, thirdInvoice.Line_Items_Count__c);
        system.assertEquals('12345678', thirdInvoice.Name);
        system.assertEquals(10, secondInvoice.Line_Items_Count__c);
        system.assertEquals('12345678', secondInvoice.Name);
    }
    }
}