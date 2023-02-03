@isTest(seeAllData=false)
public class SC_CommunityCommentControllerJarvisTest {
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
    
    
    testmethod static void testInternalComment() {
                
        Test.startTest();
        Case cs = [select id from case where apply_jarvis_logic__c = true limit 1];
        SC_CommunityCommentController.OnLoadCommentWrapper ld = SC_CommunityCommentController.onLoadDetails(cs.Id);
        System.assertEquals(false, ld.isCommunityLoad, 'OnLoadCommentWrapper');
        System.assertEquals(true, ld.userHasWriteAccess, 'OnLoadCommentWrapper');
        System.assertEquals(true, ld.isCustomerCase, 'OnLoadCommentWrapper');
        List<Community_Comments__c> commComments = [select id from Community_Comments__c where parent_id__c = :cs.Id];
        Integer beforeInsertCommentCount = commComments.size();
        SC_CommunityCommentController.insertnewComment( (String)cs.Id, 'JARVIS', 'Case', 'Test Comment', 'Public');
                
        list<SC_CommunityCommentController.MainCommentWrapper> comments = SC_CommunityCommentController.getCommentDetails(cs.Id, 'JARVIS', 'Case', 'Public');

        System.assertEquals(beforeInsertCommentCount + 1, comments.size(), 'Community Comment Inserted');
        Test.stopTest();
    }
    
    
    testmethod static void testInternalFileComment() {
        
        Test.startTest();
        Case cs = [select id from case where apply_jarvis_logic__c = true limit 1];
        
        ContentVersion contentVersion = new ContentVersion(
            Title          = 'a picture',
            PathOnClient   = 'Pic.jpg',
            VersionData    = Blob.valueOf('Test Content'),
            IsMajorVersion = true,
            customvisibility_fileupload__c = 'AllUsers');
        insert contentVersion;
        
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument limit 1];
        
        //create ContentDocumentLink  record
        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = cs.Id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.ShareType = 'V';
        cdl.Visibility = 'AllUsers';
        insert cdl;
        
        list<SC_CommunityCommentController.MainCommentWrapper> comments = SC_CommunityCommentController.getCommentDetails(cs.Id, 'JARVIS', 'Case', 'Public');
        System.assertEquals(1, comments.size(), 'Community Comment Inserted');
        Test.stopTest();
    }
    
    testmethod static void testExternalFileComment() {
        
        Test.startTest();
        
        List<Contact> contacts = [select id from contact limit 1];
        
        User commUser = [select id, isactive from user where contactid = :contacts[0].Id];
        if(commUser.isActive == false) {
            User userRun = [SELECT Id FROM User WHERE Alias = 'CRMOPS' limit 1];
            system.runAs(userRun){
                commUser.isActive = true;
                update commUser;
            }
        }

        Case cs = [select id from case where apply_jarvis_logic__c = true limit 1];

        Insert new CaseShare(CaseId = cs.id, UserOrGroupId = commUser.Id, CaseAccessLevel = 'Edit');
        List<Network> networks = [SELECT Id, Name, Status FROM Network where name = 'Customer Community' and status = 'Live'];
        System.runAs(commUser) {
            
            ContentVersion contentVersion = new ContentVersion(
                Title          = 'a picture',
                PathOnClient   = 'Pic.jpg',
                VersionData    = Blob.valueOf('Test Content'),
                IsMajorVersion = true,
                networkid = networks[0].Id);
            insert contentVersion;
            
            List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument limit 1];
            
            //create ContentDocumentLink  record
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.LinkedEntityId = cs.Id;
            cdl.ContentDocumentId = documents[0].Id;
            cdl.ShareType = 'V';
            cdl.Visibility = 'AllUsers';
            insert cdl;
            
            list<SC_CommunityCommentController.MainCommentWrapper> comments = SC_CommunityCommentController.getCommentDetails(cs.Id, 'JARVIS', 'Case', 'Public');
            System.assertEquals(1, comments.size(), 'Community Comment Inserted');
        }
        
        
        SC_Jarvis_Case_Provision_Queue caseProvisionQueue = new SC_Jarvis_Case_Provision_Queue();
        List<String> caseids = new List<String>();
        for(Case cas: [select id from case limit 10]) {
            caseids.add(cas.Id);
        }
        caseProvisionQueue.caseIds = caseids;
        system.enqueueJob(caseProvisionQueue);
        
        
        Test.stopTest();
    }
    
    testmethod static void testExternalComments() {
                
        Test.startTest();
        Case cs = [select id from case where apply_jarvis_logic__c = true limit 1];
        List<Community_Comments__c> commComments = [select id from Community_Comments__c where parent_id__c = :cs.Id];
        Integer beforeInsertCommentCount = commComments.size();
        SC_CommunityCommentController.insertnewComment( (String)cs.Id, 'JARVIS', 'Case', 'Test Comment', 'Public');
        commComments = [select id from Community_Comments__c where parent_id__c = :cs.Id];
        Integer afterInsertCommentCount = commComments.size();
        
        System.assertEquals(beforeInsertCommentCount + 1, afterInsertCommentCount, 'Community Comment Inserted');
        Test.stopTest();
    }
    
    testmethod static void testInboundEmail() {

        Test.startTest();
        User userRun = [SELECT Id FROM User WHERE Alias = 'CRMOPS' limit 1];
        system.runAs(userRun){
            Case cs = [select id from Case limit 1];
            EmailMessage newEmail = new EmailMessage(FromAddress = 'test@example.com', 
                                                    Incoming = true, 
                                                    ToAddress= 'test@example.com', 
                                                    Subject = 'Test email', 
                                                    TextBody = 'hello this a test email Type: RESNOT ', 
                                                    Headers = 'test',
                                                    ParentId = cs.Id);
            Database.insert(newEmail);
        
            
            //emailmessage emailMsg = [select id from emailmessage limit 1];
            EmailMessage emsg = SC_CommunityCommentController.getEmailBody(newEmail.Id);
            
            System.assertEquals(newEmail.Id, emsg.Id, 'Community Comment Email');
                    
            list<SC_CommunityCommentController.MainCommentWrapper> comments = SC_CommunityCommentController.getCommentDetails(cs.Id, 'JARVIS', 'Case', 'Public');
            System.assertEquals(1, comments.size(), 'Community Comment Inserted');
            }
        Test.stopTest();
    }
    
    testmethod static void testOutboundEmail() {
        Test.startTest();
            User userRun = [SELECT Id FROM User WHERE Alias = 'CRMOPS' limit 1];
            system.runAs(userRun){
            Case cs = [select id from Case limit 1];
            EmailMessage newEmail = new EmailMessage(FromAddress = 'test@example.com', 
                                                    Incoming = false, 
                                                    ToAddress= 'test@example.com', 
                                                    Subject = 'Test email', 
                                                    TextBody = 'hello this a test email Type: RESNOT ', 
                                                    Headers = 'test',
                                                    ParentId = cs.Id);
            Database.insert(newEmail);
        
            list<SC_CommunityCommentController.MainCommentWrapper> comments = SC_CommunityCommentController.getCommentDetails(cs.Id, 'JARVIS', 'Case', 'Public');
            System.assertEquals(1, comments.size(), 'Community Comment Inserted');
        }
        Test.stopTest();
    }
    
    testmethod static void testOutboundEmail2() {
        Test.startTest();
            User userRun = [SELECT Id FROM User WHERE Alias = 'CRMOPS' limit 1];
            system.runAs(userRun){
            Case cs = [select id from Case limit 1];
            EmailMessage newEmail = new EmailMessage(FromAddress = 'test@example.com', 
                                                    Incoming = false, 
                                                    ToAddress= 'test@example.com', 
                                                    Subject = 'Test email', 
                                                    TextBody = 'hello this a test email Type: RESNOT ', 
                                                    Headers = 'test',
                                                    status = '5',
                                                    ParentId = cs.Id);
            Database.insert(newEmail);
            
            newEmail.status = '3';
            Database.update(newEmail);

            list<SC_CommunityCommentController.MainCommentWrapper> comments = SC_CommunityCommentController.getCommentDetails(cs.Id, 'JARVIS', 'Case', 'Public');
            System.assertEquals(1, comments.size(), 'Community Comment Inserted');
        }
        Test.stopTest();
    }
    
    testmethod static void testCaseWebupdate() {
        Test.startTest();
        Case cs = [select id from Case limit 1];
        Task taskRec = new Task(Task_Validation_Override__c = true, 
                                Subject = 'Test', Description = 'test', 
                                Type__c = 'Web Update', 
                                visibility__c = 'Customer',
                                whatId = cs.Id);
        insert taskRec; 
        list<SC_CommunityCommentController.MainCommentWrapper> comments = SC_CommunityCommentController.getCommentDetails(cs.Id, 'JARVIS', 'Case', 'Public');
        System.assert(comments.size() > 0, 'task comments');
        Test.stopTest();
    }
    
    testmethod static void testCaseCall() {
        Test.startTest();
        Case cs = [select id from Case limit 1];
        Task taskRec = new Task(Task_Validation_Override__c = true, 
                                Subject = 'Test', Description = 'test', 
                                Type__c = 'Call', 
                                visibility__c = 'Customer',
                                whatId = cs.Id);
        insert taskRec; 
        list<SC_CommunityCommentController.MainCommentWrapper> comments = SC_CommunityCommentController.getCommentDetails(cs.Id, 'JARVIS', 'Case', 'Public');
        System.assert(comments.size() > 0, 'task comments');
        Test.stopTest();
    }
    
    testmethod static void testCommentDeleteAndUndelete() {
                
        Test.startTest();
        Case cs = [select id from case where apply_jarvis_logic__c = true limit 1];
        SC_CommunityCommentController.insertnewComment( (String)cs.Id, 'JARVIS', 'Case', 'Test Comment', 'Public');                
        List<Community_Comments__c> commComments = [select id from Community_Comments__c where parent_id__c = :cs.Id];
        delete commComments[0];
        undelete commComments[0];
        commComments = [select id from Community_Comments__c where Id = :commComments[0].Id];
        System.assertEquals(1, commComments.size(), 'Community Comments');
        Test.stopTest();
    }
    
   /* testmethod static void commCommentsShare() {
        List<Account> acc = [select id, akam_account_id__c from Account where akam_Account_id__c = 'Test-ABC-123Jarvis'];
        new Set<String>{SC_Jarvis_utility.prepareGroupName('JARVIS_ACCOUNT' + caseRec.Community_Sharing_Set_Account_Lookup__r.AKAM_Account_id__c)
    }*/

    @IsTest
    public static void testGetEmail(){
        Test.startTest();

        User userRun = [SELECT Id FROM User WHERE Alias = 'CRMOPS' limit 1];
        system.runAs(userRun){
            Case cs = [select id from Case limit 1];
            EmailMessage newEmail = new EmailMessage(FromAddress = 'test@example.com',
                    Incoming = true,
                    ToAddress= 'test@example.com',
                    Subject = 'Test email',
                    TextBody = 'hello this a test email Type: RESNOT ',
                    Headers = 'test',
                    ParentId = cs.Id);
            Database.insert(newEmail);

            Attachment attach=new Attachment();
            attach.Name='Unit Test Attachment';
            Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
            attach.body=bodyBlob;
            attach.parentId=newEmail.id;
            insert attach;


            //emailmessage emailMsg = [select id from emailmessage limit 1];
            Map<String,Object> message = SC_CommunityCommentController.getEmail(newEmail.Id);
            System.assert(message.containsKey('email'));
            EmailMessage emsg = (EmailMessage) message.get('email');
            System.assertEquals(newEmail.Id, emsg.Id, 'Community Comment Email');
        }
        Test.stopTest();

    }

    @IsTest
    public static void testGetAttachments(){
        Test.startTest();

        User userRun = [SELECT Id FROM User WHERE Alias = 'CRMOPS' limit 1];
        system.runAs(userRun){

            Case cs = [select id from Case limit 1];
            EmailMessage newEmail = new EmailMessage(FromAddress = 'test@example.com',
                    Incoming = true,
                    ToAddress= 'test@example.com',
                    Subject = 'Test email',
                    TextBody = 'hello this a test email Type: RESNOT ',
                    Headers = 'test',
                    ParentId = cs.Id);
            insert newEmail;

            Attachment attach=new Attachment();
            attach.Name='Unit Test Attachment';
            Blob bodyBlob=Blob.valueOf('Unit Test Attachment Body');
            attach.body=bodyBlob;
            attach.parentId=newEmail.id;
            insert attach;



            //emailmessage emailMsg = [select id from emailmessage limit 1];
            List<Map<String,Object>> attachments = SC_CommunityCommentController.getAttachments(newEmail.Id);
            System.assert(attachments.size() > 0);
        }
        Test.stopTest();
    }

}