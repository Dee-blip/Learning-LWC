@IsTest
private class SC_Jarvis_CC_Share_Batch_Test {

    @testSetup static void testDataSetup(){

        utilTestClass.createCustomSettings();
        OrgWideEmailAddress owemail = [SELECT Id, IsAllowAllProfiles FROM OrgWideEmailAddress where IsAllowAllProfiles = true limit 1];
        insert new SC_FromEmailAddress__c(Name = 'auto-reply', OrgAddressId__c = owemail.Id);

        User userRun = [SELECT Id FROM User WHERE Alias = 'CRMOPS' limit 1];
        system.runAs(userRun){
            //Account Setup
            Account accRec = new Account(Name='Test Account Jarvis',AKAM_Account_ID__c='Test-ABC-123Jarvis',Type='Brand - Active');
            Account accRec2 = new Account(Name='Test Account Jarvis 2',AKAM_Account_ID__c='Test-ABC-12Jarvis',Type='Brand - Active');
            insert new List<Account> { accRec, accRec2};

            //Contact Setup
            Contact conRec = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz2',
                    Akam_Contact_id__c ='test-222', Email = 'test222@test.com' ,
                    No_Longer_with_Company__c = false, LastName = 'Test Contact2',
                    Contact_Type__c ='Technical Primary - 24x7',
                    Active_Portal_Login__c = True);
            conRec.Primary_Contact_Method__c = 'Phone';
            insert conRec;


            AccountContactRelation acrRec = new AccountContactRelation(AccountID = accRec2.Id, ContactId = conRec.Id, IsActive = true);
            insert acrRec;

            Policy_Domain__c pdRec = new Policy_Domain__c(Name = 'Testpd', Account_Name__c = accRec.Id, AKAM_Policy_Domain_ID__c = 'Test_ABC_Jarvis', Policy_Domain_Description__c = 'default Test-Pd-123', Policy_Domain_State__c = 'Active', Product__c = 'defaulttestproduct', Additional_Product__c = 'test add prod');
            insert pdRec;

            Authorized_Contact__c acRec = new Authorized_Contact__c (Contact_Name__c = conRec.Id, Emergency_Email__c = true, Policy_Domain__c = pdRec.Id, Product_Interests__c = 'All');
            insert acRec;

            Id caseTechnicalRT = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
            Case jarvisCaseRec = new Case(Subject = 'Test',
                    accountid = accRec.Id,
                    recordtypeid= caseTechnicalRT,
                    Description = 'Test',
                    Validation_override__c = true,
                    Origin = 'Email');

            jarvisCaseRec.Do_Not_Show_in_Portal__c = false;
            jarvisCaseRec.Apply_Jarvis_Logic__c = true;
            jarvisCaseRec.Community_Sharing_Set_Account_Lookup__c = accRec.Id;

            insert jarvisCaseRec;

            String groupName = SC_Jarvis_utility.prepareGroupName('JARVIS_ACCOUNTTest-ABC-123Jarvis');
            Group accGrp = new Group( Name=groupName, DeveloperName = groupName, type='Regular' );
            insert accGrp;
            insert new CaseShare(CaseId = jarvisCaseRec.id, UserOrGroupId = accGrp.Id, CaseAccessLevel = 'Edit');

        }

        SC_Case_Issue_Sync_Admin_Setting__c adminRec =  new SC_Case_Issue_Sync_Admin_Setting__c();
        adminRec.Access_Token_Issues_API__c = '';
        adminRec.Client_Certificate__c = 'EAA_KMI_Signed_Certificate';
        adminRec.Client_Id_Issues_API__c = '90f8e0f1-696b-46f9-a504-3811b8ce00fc';
        adminRec.Client_Secret_Issues_API__c = 'b8a4f2c9-24e5-4d5e-a794-6b98730b6915';
        adminRec.Hostname_Issues_API__c = 'https://qa.dash-ext.akamai.com/';
        adminRec.Oauth_Endpoint_Issues_API__c = 'oauth2/token';
        adminRec.Scope_Issues_API__c = 'network-services/issues/v1/issues/';
        insert adminRec;
    }

    @IsTest
    static void testBehavior1() {
        Case cs = [select id from case where apply_jarvis_logic__c = true limit 1];
        SC_CommunityCommentController.OnLoadCommentWrapper ld = SC_CommunityCommentController.onLoadDetails(cs.Id);
        System.assertEquals(false, ld.isCommunityLoad, 'OnLoadCommentWrapper');
        System.assertEquals(true, ld.userHasWriteAccess, 'OnLoadCommentWrapper');
        System.assertEquals(true, ld.isCustomerCase, 'OnLoadCommentWrapper');
        Test.startTest();
        SC_CommunityCommentController.insertnewComment( (String)cs.Id, 'JARVIS', 'Case', 'Test Comment', 'Public');
        Database.executeBatch(new SC_Jarvis_CC_Share_Batch());
        Test.stopTest();
    }

    @IsTest
    static void testSendEmail(){
        Test.startTest();
        SC_Jarvis_CC_Share_Batch batch = new SC_Jarvis_CC_Share_Batch();
        batch.sendEmailforException('Test Message');
        System.assert(Limits.getEmailInvocations() > 0);
        Test.stopTest();

    }
}