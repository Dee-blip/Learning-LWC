@IsTest
public class SC_Jarvis_CaseUpdate_Batch_Test {

    Public Static Account accRec;
    Static Account accRec2;
    Static Contact conRec;
    Static task taskRec;
    Static Policy_Domain__c pdRec;
    Static Authorized_Contact__c  acRec;


    static void testDataSetup(){
        SC_Case_Issue_Sync_Admin_Setting__c adminRec =  new SC_Case_Issue_Sync_Admin_Setting__c();
        adminRec.Access_Token_Issues_API__c = '';
        adminRec.Client_Certificate__c = 'EAA_KMI_Signed_Certificate';
        adminRec.Client_Id_Issues_API__c = '90f8e0f1-696b-46f9-a504-3811b8ce00fc';
        adminRec.Client_Secret_Issues_API__c = 'b8a4f2c9-24e5-4d5e-a794-6b98730b6915';
        adminRec.Hostname_Issues_API__c = 'https://qa.dash-ext.akamai.com/';
        adminRec.Oauth_Endpoint_Issues_API__c = 'oauth2/token';
        adminRec.Scope_Issues_API__c = 'network-services/issues/v1/issues/';
        insert adminRec;
        utilTestClass.createCustomSettings();
        User userRun = [SELECT Id FROM User WHERE Alias = 'CRMOPS' limit 1];
        system.runAs(userRun){

            //Account Setup
            List<Account> accountList = new List<Account>();
            accountList.add(new Account(Name='Test Account Jarvis',AKAM_Account_ID__c='Test-ABC-123Jarvis',Type='Brand - Active'));
            accountList.add(new Account(Name='Test Account Jarvis 2',AKAM_Account_ID__c='Test-ABC-12Jarvis',Type='Brand - Active'));
            Insert accountList;

            accRec = accountList[0];
            accRec2 = accountList[1];

            //Contact Setup
            conRec = new Contact(AccountId = accRec.Id, Login__c = 'Test_xyz2',Akam_Contact_id__c ='test-222', Email = 'test222@test.com' ,No_Longer_with_Company__c = false, LastName = 'Test Contact2', Contact_Type__c ='Technical Primary - 24x7', Active_Portal_Login__c = True, Primary_Contact_Method__c = 'Phone', Validation_Override__c = True);
            insert conRec;


            AccountContactRelation acrRec = new AccountContactRelation(AccountID = accRec2.Id, ContactId = conRec.Id, IsActive = true);
            insert acrRec;

        }

    }

    public static testmethod void TestJarvisCaseUpdate(){
        testDataSetup();
        Test.startTest();
        Id caseTechnicalRT = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        List<case> caselist = new List<case>();
        Case caseRec= new Case(contactid = conRec.id, Subject = 'Test', accountid = accRec.Id, recordtypeid= caseTechnicalRT, Description = 'Test', Validation_override__c = true, Origin = 'Email', Do_not_show_in_portal__c = False, Community_Sharing_Set_Account_Lookup__c = accRec.Id );
        caselist.add(caseRec);
        Case caseRec2= new Case(contactid = conRec.id, Subject = 'Test2', accountid = accRec.Id, recordtypeid= caseTechnicalRT, Description = 'Test', Validation_override__c = true, Origin = 'Email', Do_not_show_in_portal__c = False , Community_Sharing_Set_Account_Lookup__c = accRec.Id);
        caselist.add(caseRec2);
        insert caselist;

        taskRec = new Task(Task_Validation_Override__c = true, Subject = 'Test', Description = 'test', Type__c = 'Web Update', whatId = caseRec.Id);
        insert taskRec;


        Database.executeBatch(new SC_Jarvis_CaseUpdate_Batch('\'AMG\',\'Technical\',\'Billing\',\'Professional Services\'',null, false));
        Test.stopTest();

    }

    public static testmethod void TestJarvisCaseUpdate2(){
        testDataSetup();
        Test.startTest();

        pdRec = new Policy_Domain__c(Name = 'Testpd', Account_Name__c = accRec.Id, AKAM_Policy_Domain_ID__c = 'Test_ABC_Jarvis', Policy_Domain_Description__c = 'default Test-Pd-123', Policy_Domain_State__c = 'Active', Product__c = 'defaulttestproduct', Additional_Product__c = 'test add prod');
        insert pdRec;


        Id caseTechnicalRT = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();


        List<case> caselist = new List<case>();
        Case caseRec= new Case(contactid = conRec.id, Subject = 'Test', Policy_Domain__c = pdRec.Id, accountid = accRec.Id, recordtypeid= caseTechnicalRT, Description = 'Test', Validation_override__c = true, Origin = 'Email', Do_not_show_in_portal__c = False, Community_Sharing_Set_Account_Lookup__c = accRec.Id );
        caselist.add(caseRec);
        insert caseList;


        taskRec = new Task(Task_Validation_Override__c = true, Subject = 'Test', Description = 'test', Type__c = 'Web Update', whatId = caseRec.Id);
        insert taskRec;


        Database.executeBatch(new SC_Jarvis_CaseUpdate_Batch('Managed Security','\'Test-ABC-123Jarvis\'', false));

        Test.stopTest();

    }

    public static testmethod void TestJarvisCaseUpdate3(){
        testDataSetup();
        Test.startTest();

        pdRec = new Policy_Domain__c(Name = 'Testpd', Account_Name__c = accRec.Id, AKAM_Policy_Domain_ID__c = 'Test_ABC_Jarvis', Policy_Domain_Description__c = 'default Test-Pd-123', Policy_Domain_State__c = 'Active', Product__c = 'defaulttestproduct', Additional_Product__c = 'test add prod');
        insert pdRec;


        Id caseTechnicalRT = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();


        List<case> caselist = new List<case>();
        Case caseRec= new Case(contactid = conRec.id, Subject = 'Test', Policy_Domain__c = pdRec.Id, accountid = accRec.Id, recordtypeid= caseTechnicalRT, Description = 'Test', Validation_override__c = true, Origin = 'Email', Do_not_show_in_portal__c = False, Community_Sharing_Set_Account_Lookup__c = accRec.Id );
        caselist.add(caseRec);
        insert caseList;


        taskRec = new Task(Task_Validation_Override__c = true, Subject = 'Test', Description = 'test', Type__c = 'Web Update', whatId = caseRec.Id);
        insert taskRec;


        Database.executeBatch(new SC_Jarvis_CaseUpdate_Batch('Limited Beta','\'Test-ABC-123Jarvis\'', false));

        Test.stopTest();

    }




}