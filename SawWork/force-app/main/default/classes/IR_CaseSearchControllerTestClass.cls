@isTest
public class IR_CaseSearchControllerTestClass {

	private static Boolean initFlag = false;
	private static User newOwner;
	private static User newOwnerRSM;
	private static User cmgUser;
	private static User sysAdmin = SObjectFactory.ADMIN_USER;
	private static User crmInt;
	private static Account_Reassignment_Rule__c newOwnerRule;
	private static Map<String, GSM_Settings__mdt> testcaseCustomSettings = GsmUtilClass.getGSMSettingValue();
	private static Date reviewDate= Date.today().toStartOfMonth();
	private static String userRoleValue = GsmUtilClass.getGSMSettingValue('User_Role');

	private static Account acc1;
	private static Opportunity opp1;
	private static Merge_Contract_Header__c mch1; 


	public static Merge_Contract_Header__c createContractHeader(String pName, Id pAccId, Id pOpptyId)
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


	public static Draft_Invoice__c createDraftInvoice(String pCI_accountId, String pContractId, String pInvoiceId, Date pInvDate, Decimal pAmount)
	{
			Draft_Invoice__c newInvoice = new Draft_Invoice__c();
			//newInvoice.CI_Account_Name__c = pCI_accountId;
			//newInvoice.CI_Original_Contract_Id__c=pContractId;
			newInvoice.Invoice_Date__c= pInvDate;
			newInvoice.Name = pInvoiceId;
			newInvoice.Original_Amount__c=pAmount;
			return newInvoice;
	}

	public static Draft_Invoice__c refreshDraftInvoice(Draft_Invoice__c pInvoice)
	{
			return refreshDraftInvoiceList(new List<Draft_Invoice__c> {pInvoice})[0];
	}

	public static List<Draft_Invoice__c> refreshDraftInvoiceList(List<Draft_Invoice__c> pInvoiceList)
	{
			return [select Id,Name,Account_Name__c,Invoice_Review_Case_Audit__c,OwnerId,Case__c,Type__c,Original_Contract_Id__c,Invoice_Date__c,Original_Amount__c from Draft_Invoice__c where Id IN:pInvoiceList];
	}


	public static Case createInvoiceCase(String pInvoiceID, Date pInvDate, Id pAccId, Id pOpptyId,Id pContractId , Id pUserId)
	{
			Case existingCase = new Case();

			existingCase.IR_CurrentInvoiceImportDate__c =  Datetime.now().addDays(-1);
			existingCase.IR_CurrentInvoiceNumber__c = pInvoiceId;
			existingCase.OwnerId = pUserId;
			existingCase.IR_Original_Contract_Id__c = pContractId;
			existingCase.RecordTypeId  = GsmUtilClass.GetCustomSettingValue('IR_CaseDefaultRecordTypeId');
			existingCase.AccountID = pAccId;
			existingCase.IR_Escal_Owner__c = pUserId;
			existingCase.IRCache_Acceptance_Date__c =  Date.today().addMonths(-1);
			existingCase.IRCache_AkamOpportunityId__c =  pOpptyId;
			//existingCase.IRCache_hasDoubleInvoiceReview__c = true;
			existingCase.Validation_Override__c = true;
			existingCase.IR_Invoice_Date__c = pInvDate;
			existingCase.IR_Invoice_Number__c = pInvoiceId;

			return existingCase;
	}


	public static GSM_Custom_Settings__c initGSMCustomSetting(String name, String value){
		GSM_Custom_Settings__c newGSMCustomSetting = new GSM_Custom_Settings__c();
		newGSMCustomSetting.Name = name;
		newGSMCustomSetting.Value__c = value;
		return newGSMCustomSetting;
	}

	/**
			Init()
			- Intialize the static variables for this Test Class
	*/
	@testSetUp static void Init()
	{
			if(initFlag)
					return;

			reviewDate = Date.today().toStartOfMonth();
			System.debug('reviewDate in TEST Method=' + reviewDate);

			String profileName = 'Sales - Media';
			String roleName = userRoleValue;

			newOwner = utilTestClass.CreateUser('TST_NUSR', roleName, profileName);
			newOwnerRSM = utilTestClass.CreateUser('TST_NRSM', roleName, profileName);
			cmgUser = utilTestClass.CreateUser('CMG_USER', 'CMG', 'CMG');
			crmInt = utilTestClass.CreateUser('CRM_USER', 'Worldwide', 'CRM Integration');

			insert (new User[] {newOwner, newOwnerRSM, cmgUser, crmInt});

			System.runAs(sysAdmin){
				Test.startTest();
				newOwnerRule = utilTestClass.CreateAccountReassignmentRule(newOwner.Name, newOwner.Id, roleName);
				newOwnerRule.Associated_User_RSM__c = newOwnerRSM.Id;

				insert (new Account_Reassignment_Rule__c[] {newOwnerRule});

				list<GSM_Custom_Settings__c> lstGSM = new list<GSM_Custom_Settings__c>();

				lstGSM.add(initGSMCustomSetting('IR_NewMissingProcess_BatchSize','15'));
				lstGSM.add(initGSMCustomSetting('IR_CaseDefaultRecordTypeId','012G0000000ygAxIAI'));
				lstGSM.add(initGSMCustomSetting('IRCasesEAlert_RecipientList','achawla@akamai.com'));
				lstGSM.add(initGSMCustomSetting('IR_RecordTypeName_Default','Invoice_Review_Case'));
				lstGSM.add(initGSMCustomSetting('IR_RecordTypeName_Readonly','Invoice_Review_Read_Only'));
				lstGSM.add(initGSMCustomSetting('IR_Unassigned_QueueDevName','IR_Unassigned'));
				lstGSM.add(initGSMCustomSetting('IR_FIN_US_QueueDevName','FIN_IR_US'));
				lstGSM.add(initGSMCustomSetting('IR_FIN_Intl_QueueDevName','FIN_IR_International'));
				lstGSM.add(initGSMCustomSetting('IR_EscalOwner_TeamMemberRole','Services - Secondary'));
				lstGSM.add(initGSMCustomSetting('IR_Owner_TeamMemberRole','CMG - Analyst'));
				lstGSM.add(initGSMCustomSetting('IRCA_FinalInvThresPercent','50'));
				lstGSM.add(initGSMCustomSetting('IRCA_DraftInvThresPercent','25'));
				lstGSM.add(initGSMCustomSetting('IR_EscalStatus_Default','Pending Review'));
				lstGSM.add(initGSMCustomSetting('IR_Status_Default','Pending Review'));
				lstGSM.add(initGSMCustomSetting('CaseTrigger#updateContact','Collections, International Business Development, Invoice Review Case, Invoice Review Read Only, Momentum Case Record, Partner Portal Case, Product Management, SF Feedback'));
				lstGSM.add(initGSMCustomSetting('IR_CaseRecordTypeIds','012G0000000ygAxIAI,012G0000000ygB2IAI'));
				lstGSM.add(initGSMCustomSetting('CRM_Integration','005A0000000NHQc'));
				lstGSM.add(initGSMCustomSetting('AccountDelete#EnabledProfileId','00eA0000000QpNLIA0,00eA0000000VTG1IAO'));
				lstGSM.add(initGSMCustomSetting('IRCase_CutOffDayOfMonth','24'));
				lstGSM.add(initGSMCustomSetting('IR_CaseAccessProfileIDs','00eA0000000QpNLIA0,00eA0000000VTG1IAO,00eA0000000QpQUIA0'));
				insert lstGSM;

				//To be removed once Service Cloud fixes triggers

				SCUserIdCustomSetting__c scUserIdCS = new SCUserIdCustomSetting__c();
				scUserIdCS.Name = 'Primary/SecondaryAssignmentQueue';
				scUserIdCS.UserId__c = '00GG0000002igPLMAY';

				insert scUserIdCS;

				list<Email_to_Case__c> lstEmail2Case = new list<Email_to_Case__c>();

				Email_to_Case__c emailToCaseMomentum = new  Email_to_Case__c();
				emailToCaseMomentum.Name = 'Momentum';
				emailToCaseMomentum.CaseRecord__c = '012A0000000OWfW';
				lstEmail2Case.add(emailToCaseMomentum);

				Email_to_Case__c emailToCaseProdMgmnt = new  Email_to_Case__c();
				emailToCaseProdMgmnt.Name = 'ProdMgmt';
				emailToCaseProdMgmnt.CaseRecord__c = '012A0000000OmQ8';
				lstEmail2Case.add(emailToCaseProdMgmnt);

				insert lstEmail2Case;

				SC_RiverbedCaseProdID__c rvrBed = new SC_RiverbedCaseProdID__c();
				rvrBed.Name = 'Riverbed_SAAS_OEM';
				rvrBed.RecordTypeID__c = '012G0000000z10xIAA';
				insert rvrBed;

				SCRecordTypeCustomSetting__c scRTCustomSetting = new SCRecordTypeCustomSetting__c();
				scRTCustomSetting.Name = 'NotificationTeam';
				scRTCustomSetting.RecordTypeName__c = 'Professional Services&&AMG&&Technical&&Managed Security&&Carrier Products&&Emerging Products Engineering';

				insert scRTCustomSetting;
				//To be removed once Service Cloud fixes triggers

				Account acc1 =  (Account)new SobjectBuilder(Account.sObjectType)
					.eagerPopulate()
					.put(Account.Type, 'Lead')
					.create()
					.getRecord();

				Opportunity opp1 = (Opportunity)new SobjectBuilder(Opportunity.sObjectType)
						.eagerPopulate()
						.put(Opportunity.AccountId, acc1.Id)
						.put(Opportunity.StageName, '1-Create')
						.put(Opportunity.Name, 'IRCaseOppty1')
						.put(Opportunity.CloseDate, Date.today().addDays(10))
						.create()
						.getRecord();

				initFlag = true;
				Test.stopTest();
			}
	}

	public static User GetUser(String name){
		return [select Id from User where Alias = :name LIMIT 1];
	}

	@isTest static void fetchCases(){
		System.runAs(sysAdmin){
			Account acc1 = SobjectRepository.getAccount();
			Opportunity opp1 = SobjectRepository.getOpportunity();
			User newOwnerRSM = GetUser('TST_NRSM');
			User cmgUser = GetUser('CMG_USER');

			Invoice_Review_Case_Audit__c ircaExisting = new Invoice_Review_Case_Audit__c();


			Account acc2 = utilTestClass.CreateAccount('IRCaseTestAcc2');
			insert acc2;

			Opportunity opp2 = utilTestClass.CreateOpportunity('IRCaseOppty2', '1-Create');
			opp2.AccountId=acc2.Id;
			opp2.CloseDate= Date.today().addDays(10);
			insert opp2;

			Merge_Contract_Header__c mch1 = createContractHeader('IRCaseMCH1', acc1.Id, opp1.Id);
			mch1.Manual_List__c = false;
			mch1.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);

			insert mch1;

			Merge_Contract_Header__c mch2 = createContractHeader('IRCaseMCH2', acc2.Id, opp2.Id);
			mch2.Manual_List__c = false;
			mch2.Acceptance_Date__c = reviewDate.addMonths(-1).addDays(10);

			insert mch2;

			Draft_Invoice__c di1=createDraftInvoice(acc1.Id, mch1.Name, '1704123788', reviewDate, 500);
			di1.CI_Original_Contract_Id__c=mch1.Name;
			di1.processedForIRCase__c = true;
			//di1.Invoice_Review_Case_Audit__c=ircaCurrent.Id;

			Draft_Invoice__c di2=createDraftInvoice(acc2.Id, mch2.Name, '1704123789', reviewDate, 500);
			di2.CI_Original_Contract_Id__c=mch2.Name;
			di2.processedForIRCase__c = true;
			//di2.Invoice_Review_Case_Audit__c=ircaCurrent.Id;

			insert di1;
			insert di2;

			di1 = refreshDraftInvoice(di1);
			di1.hasAttachment__c=true;
			update di1;

			di2 = refreshDraftInvoice(di2);
			di2.hasAttachment__c=true;
			update di2;

			Test.startTest();
			List<Case> existinginvCaseList = new List<Case>();

			Case existinginvCase = createInvoiceCase (di1.Name, reviewDate, acc1.Id, opp1.Id , mch1.Id, newOwnerRSM.Id);
			existinginvCase.IR_Escal_Status__c = 'Pending Review';
			existinginvCase.status = 'Rejected';
			existinginvCase.Description = 'Test Case Reject Threshold Positive';
			existinginvCase.IR_CurrentInvoiceAmount__c = 500;
			existinginvCase.CurrencyIsoCode = 'USD';
			existingInvCase.Approved_On__c = Datetime.now().addHours(2);
			existinginvCaseList.add(existinginvCase);

			Case existinginvCase2 = createInvoiceCase (di2.Name, reviewDate, acc2.Id, opp2.Id , mch2.Id, newOwnerRSM.Id);
			existinginvCase2.IR_Escal_Status__c = 'Pending Review';
			existinginvCase2.status = 'Deferred';
			existinginvCase2.Description = 'Test Case Reject Threshold Positive';
			existinginvCase2.IR_CurrentInvoiceAmount__c = 500;
			existinginvCase2.CurrencyIsoCode = 'USD';
			existingInvCase2.Approved_On__c = Datetime.now().addHours(2);
			existinginvCase2.IR_Defer_Until__c = Date.today().addMonths(1);

			existinginvCaseList.add(existinginvCase2);
			insert existinginvCaseList;

			String pageSize = '2';
			String pgNum = '1';
			String whereClause = 'AND IR_Original_Contract_Id__r.Name = \'IRCaseMCH1\'';
			List<Case> result = IR_CaseSearchController.fetchCases(pageSize, pgNum, whereClause);
			Test.stopTest();

			System.assertEquals(result.size(), 1);

		}
	}


	@isTest static void getPicklistValues(){
		List<String> lstPickvals = IR_CaseSearchController.getPicklistValues('Case', 'Status');
		System.assertEquals(lstPickvals.size() > 0, true);
	}

}