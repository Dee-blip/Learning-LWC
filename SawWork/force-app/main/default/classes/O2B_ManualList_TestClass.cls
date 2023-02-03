/*
  * Test class for code coverage
  * Author : CKASTURI

  Ankit Chawla	15/10/18  SFDC-3619: Changing name of profile Sales - Rep to Sales - Media
  
*/
@isTest(SeeAllData=false)
public class O2B_ManualList_TestClass
{
    private static Boolean initFlag = false;
    private static User newOwner;
    private static User newOwnerRSM;
    private static User cmgUser;
    private static User crmUser;
    private static User sysAdmin = SObjectFactory.ADMIN_USER;
    private static Account_Reassignment_Rule__c newOwnerRule;
    private static Map<String, GSM_Settings__mdt> testcaseCustomSettings = GsmUtilClass.getGSMSettingValue();
    private static Date reviewDate;

    private static Account acc1;
    private static AccountTeamMember atmEscalOwner;
    private static AccountTeamMember atmCMGAnalyst;
    private static Opportunity opp1;
    private static Merge_Contract_Header__c mch1;
    private static Merge_Contract_Manual_List__c mcManList;
    private static Invoice__c prevMonthFinalInvoice;
    private static Attachment attachments;
    private static Case existingCases;
    private static IRCaseCreationData irCaseData;
    private static List<Merge_Contract_Header__c> mchIdList;
    private static Map<Id,IRCaseWrapper> contractIDCaseWrapperMap;
    private static Map<Id,Id> accOwnerIdMap;
    private static Map<Id,AccountTeamMember> accIRCaseEscalOwnerATMMap;
    private static Map<Id,Id> mchIdAccIdMap;

     /**
        refreshAttachment()
    */
    private static Attachment refreshAttachment(Id attachmentID)
    {
        return [SELECT Id,ParentID FROM Attachment WHERE Id = :attachmentID];
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
    private static void Init()
    {
        if(initFlag)
            return;

        String profileName = 'Sales - Media';
        String roleName = testcaseCustomSettings.get('User_Role').Value__c;
        //Id adminProfileId = (ID) GsmUtilClass.GetCustomSettingValue('ApprovalHistory#SysAdminId');

        newOwner = utilTestClass.CreateUser('TST_NUSR', roleName, profileName);
        newOwnerRSM = utilTestClass.CreateUser('TST_NRSM', roleName, profileName);
        cmgUser = utilTestClass.CreateUser('CMG_USER', 'CMG', 'CMG');
        String adminProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator' LIMIT 1].Id;
        String cmgProfileId = [SELECT Id FROM Profile WHERE Name = 'CMG' LIMIT 1].Id;
        crmUser = utilTestClass.CreateUser('TST_CMG', 'Worldwide', 'CRM Integration');

        insert (new User[] {newOwner, newOwnerRSM, cmgUser, crmUser});

        System.runAs(sysAdmin) {
            //Test.startTest();
            list<GSM_Custom_Settings__c> lstGSM = new list<GSM_Custom_Settings__c>();
            lstGSM.add(initGSMCustomSetting('User_Role','2018_ECG'));
            lstGSM.add(initGSMCustomSetting('IRCase_DefaultInvoiceNumber','N/A'));
            lstGSM.add(initGSMCustomSetting('IRCase_CutOffDayOfMonth','24'));
            lstGSM.add(initGSMCustomSetting('IR_RecordTypeName_Default','Invoice_Review_Case'));
            lstGSM.add(initGSMCustomSetting('CRM_Integration',crmUser.Id));
            lstGSM.add(initGSMCustomSetting('CMGProfileId',cmgProfileId.substring(0,15)));
            lstGSM.add(initGSMCustomSetting('ApprovalHistory#SysAdminId',adminProfileId.substring(0,15)));
				

            insert lstGSM;
            
            newOwnerRule = utilTestClass.CreateAccountReassignmentRule(newOwner.Name, newOwner.Id, roleName);
            newOwnerRule.Associated_User_RSM__c = newOwnerRSM.Id;

                insert (new Account_Reassignment_Rule__c[] {newOwnerRule});


            acc1 = utilTestClass.CreateAccount('IRCaseTestAcc1');
            insert acc1;
            acc1 = IRCasesTestClass.RefreshAccount(acc1);

            opp1 = utilTestClass.CreateOpportunity('IRCaseOppty1', '1-Create');
            opp1.AccountId=acc1.Id;
            opp1.CloseDate=Date.today().addDays(10);
            insert opp1;

            mch1 = IRCasesTestClass.createContractHeader('IRCaseMCH1', acc1.Id, opp1.Id);
            insert mch1;

            mcManList = IRCasesTestClass.createContractManualList('IRCaseMlist1', mch1.Name);
            mcManList.Review_Frequency__c = 'Monthly';
            mcManList.End_Date__c = Date.today().addMonths(2);
            mcManList.Owner__c = 'UNKNOWN';
            mcManList.Review_Date__c = reviewDate;
            mcManList.Priority__c = 'TESTPRIORITY';
            insert mcManList;

            initFlag = true;
        }
    }


    static testMethod void mchAttachmentDelete_Positive()
    {
        init();
        Attachment attach;
        System.runAs(sysAdmin)
        {
            Test.startTest();
            // add an Attachment to ManualList
            attach = new Attachment();
            Blob b = Blob.valueOf('Test Data');
            attach.Body = b;
            attach.Name = 'Test Attachment for Parent';
            attach.ParentID = mcManList.Id;
            insert attach;
            // Refresh Attachment
            attach = refreshAttachment(attach.Id);
            // Assert if it matches the manualListId
            System.assertEquals(mcManList.Id, attach.ParentID);
            delete attach;
            Test.stopTest();
        }
    }
}