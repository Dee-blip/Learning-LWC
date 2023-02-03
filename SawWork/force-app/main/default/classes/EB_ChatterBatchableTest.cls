@IsTest(seeallData=True)
public class EB_ChatterBatchableTest
   {
   public static Account a1,a2,a3;
   
    public static AccountTeamMember atm1,atm2,atm3;
    public static EB_TechSupportTeams__c tst1,tst2,tst3;
    public static EB_AkaMailer__c mailer1,mailer2,massmailer;
    public static EB_AkaMAccount__c AA1,AA2,AA3;
     static Set<String> uniqueAccountListB = new Set<String>();
    static EB_EmailTemplate__c testTemplate2;
    static EB_NotificationType__c templateType;
    static EmailTemplate et;
   
    private static void Init()
    {
            ManagedPkgErrorClass.isFromManagedPackage=false;
       //create Email Template Types Single Email and Mass Email
            templateType=new EB_NotificationType__c();
            templateType.Name= 'Single Email1';
            templateType.Folder_Name__c=' EB_CNSingleMail';
            database.insert(templateType);
        User thisUser = [Select ID from User where ID = :Userinfo.getUserId()];
        System.runAs(thisUser){
            et = EB_InitializeObjects.createEmailTemplate('New_Email_Template','text');
            Database.insert(et);
        }
            String tempId2=[Select e.Id,developerName,BrandTemplateId From EmailTemplate e where e.TemplateType='HTML' and e.FolderId in ( select Id from Folder where Name='Customer Notify Single Email') limit 1].Id;
            //calling the method in the common class(EB_InitializeObjects) for initializing custom template 
            testTemplate2= EB_InitializeObjects.createCustomTemplate('Testtemplate 2','text',et.Id);
            database.insert(testTemplate2);
     a1=EB_InitializeObjects.createAccount('DummyAccount1');
     database.insert(a1);
     a2=EB_InitializeObjects.createAccount('DummyAccount2');
     database.insert(a2);
     a3=EB_InitializeObjects.createAccount('DummyAccount3');
     database.insert(a3);
      List<User> TestUsers = new List<User>(); 
      ID staffProfileID = [select id,name from profile where name = 'ServiceDesk Staff'].ID;
      User testUser1 = new User( email='testuser1@akamai.com',UserName='testuser1@akamai.com', alias='RFtuser1', CommunityNickName='RFtuser',
         TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',
            LanguageLocaleKey='en_US',profileid = staffProfileID ,FirstName = 'Test', LastName = 'User', IsActive = true);
        TestUsers.add(testUser1) ; 
        
            User testUser2 = new User(email='testuser2@akamai.com', 
            UserName='testuser2@akamai.com', alias='RFtuser2', CommunityNickName='RFtuser2',
             TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',
            LanguageLocaleKey='en_US',profileid = staffProfileID ,FirstName = 'Test2', LastName = 'User2', IsActive = true);
        TestUsers.add(testUser2) ;
        User testUser3 = new User(email='testuser3@akamai.com', 
            TimeZoneSidKey='America/New_York', LocaleSidKey='en_US', EmailEncodingKey='ISO-8859-1',
            LanguageLocaleKey='en_US',UserName='testuser3@akamai.com', alias='RFtuser3', CommunityNickName='RFtuser3',
            FirstName = 'Test3',  profileid = staffProfileID ,LastName = 'User3', IsActive = true);
        TestUsers.add(testUser3) ;      
         insert TestUsers;
     atm1=EB_InitializeObjects.createAccountTeamMember(a1.id,testUser1.id);
     database.insert(atm1);
     atm2=EB_InitializeObjects.createAccountTeamMember(a2.id,testUser2.id);
     database.insert(atm2);
     atm3=EB_InitializeObjects.createAccountTeamMember(a3.id,testUser3.id);
     database.insert(atm3);
     tst1=EB_InitializeObjects.createAccountTeamTechSupport(a1.id,testUser1.id);
     database.insert(tst1);
     tst2=EB_InitializeObjects.createAccountTeamTechSupport(a2.id,testUser2.id);
     database.insert(tst2);
     tst3=EB_InitializeObjects.createAccountTeamTechSupport(a3.id,testUser3.id);
     database.insert(tst3);
     mailer1=EB_InitializeObjects.createMailer(testTemplate2.Id,'Single Email');
     database.insert(mailer1);
     mailer2=EB_InitializeObjects.createMailer(testTemplate2.Id,'Single Email');
     database.insert(mailer2);
     massmailer=EB_InitializeObjects.createMailer(testTemplate2.Id,'Mass Email');
     database.insert(massmailer);
     AA1=EB_InitializeObjects.createMailerAccount(testTemplate2.Id,mailer1.Id,a1.Id);
     database.insert(AA1);
     AA2=EB_InitializeObjects.createMailerAccount(testTemplate2.Id,mailer1.Id,a2.Id);
     database.insert(AA2);
     AA3=EB_InitializeObjects.createMailerAccount(testTemplate2.Id,mailer1.Id,a3.Id);
     database.insert(AA3);
      uniqueAccountListB.add(a1.id);
      uniqueAccountListB.add(a2.id);
      uniqueAccountListB.add(a3.id);    
    }
    
     static testMethod void AccountProductSearchGeneralNotification_Mass() 
        {
                init();
                  String strReturnURL= 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/';
                  PageReference pageRef,pageRef1;
                 strReturnURL = strReturnURL + 'apex/EB_VfpNotifyUsersAboutMailerCreation?id='+mailer1.Id+'&type='+mailer1.EB_Type__c+'&incident_type=';
                 pageRef = new PageReference(strReturnURL);
                 Test.setCurrentPage(pageRef);
                EB_CtrlChatterNotfication controlchatter1=new EB_CtrlChatterNotfication();
                
                 String strReturnURL1 = strReturnURL + 'apex/EB_VfpNotifyUsersAboutMailerCreation?id='+mailer2.Id+'&type='+mailer2.EB_Type__c+'&incident_type=';
                 pageRef1 = new PageReference(strReturnURL1);
                 Test.setCurrentPage(pageRef);
               
                Id mailerIdtemp1=mailer1.Id;
                test.StartTest();
               
                controlchatter1.sendChatterNotification();
                controlchatter1.CallForMassmailTechteam();
                controlchatter1.CallForSinglemailTechteam();
                PageReference pg=controlchatter1.redirectToMailer();
                Boolean temp=controlchatter1.getRenderFinish();
                Set<String> uniqueAccountList=new Set<String>();
                
                
                
                
                Test.setCurrentPage(pageRef1);
                EB_CtrlChatterNotfication controlchatter2=new EB_CtrlChatterNotfication();
                Id mailerIdtemp2=mailer2.Id;
                
              
                controlchatter2.sendChatterNotification();
                controlchatter2.CallForMassmailTechteam();
                
                
               
                EB_BatchableNotification ctrlBatchableNotification3=new EB_BatchableNotification(NULL,uniqueAccountList,'AccountTeamMember'); 
                Test.stopTest();
                
         }
         static testMethod void AccountProductSearchGeneralNotification_Mass1()
         {
          init();
                  String strReturnURL= 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/';
                  PageReference pageRef1;
                  String strReturnURL1 = strReturnURL + 'apex/EB_VfpNotifyUsersAboutMailerCreation?id='+mailer2.Id+'&type='+mailer2.EB_Type__c+'&incident_type=';
                 pageRef1 = new PageReference(strReturnURL1);
                  Test.setCurrentPage(pageRef1);
                
                Test.startTest();
                
                EB_CtrlChatterNotfication controlchatter2=new EB_CtrlChatterNotfication();
                Id mailerIdtemp2=mailer2.Id;
                controlchatter2.sendChatterNotification();
                
                Test.stopTest();
         } 
         static testMethod void AccountProductSearchGeneralNotification_Mass2()
         {
          init();
                String strReturnURL= 'https://' + ApexPages.currentPage().getHeaders().get('Host') + '/';
                PageReference pageRef1;
                String strReturnURL1 = strReturnURL + 'apex/EB_VfpNotifyUsersAboutMailerCreation?id='+mailer1.Id+'&type='+mailer2.EB_Type__c+'&incident_type=';
                pageRef1 = new PageReference(strReturnURL1);
                Test.setCurrentPage(pageRef1);
                
                Test.startTest();
                
                EB_CtrlChatterNotfication controlchatter2=new EB_CtrlChatterNotfication();
                Id mailerIdtemp2=mailer1.Id;
                controlchatter2.sendChatterNotification();
                controlchatter2.CallForMassmailAccountteam();
                
               
                Test.stopTest();
         } 
          
          static testMethod void myUnitTest() 
            {
            init();
            Database.BatchableContext BC;
             
            Test.StartTest();
            EB_BatchableNotification AccountTeamMemberinternalbatch = new EB_BatchableNotification(massmailer.id,uniqueAccountListB,'AccountTeamMember');
            ID batchprocessidAccountTeamMember = Database.executeBatch(AccountTeamMemberinternalbatch,20);
           
            EB_BatchableNotification TechSupportTeaminternalbatch = new EB_BatchableNotification(massmailer.id,uniqueAccountListB,'EB_TechSupportTeams__c');
            ID batchprocessidTechSupportTeaminternalbatch = Database.executeBatch(TechSupportTeaminternalbatch ,20);
            Test.stopTest();
            }
    }