@isTest(seeAllData = true)
public class EB_SingleMailBatchTest {
    static EB_AkaMAccount__c acc = new EB_AkaMAccount__c();    
    static EB_AkaMContact__c mailerContact1;
    
    static EB_AkaMContact__c mailerContact2;
    static EB_AkaMAccount__c accMass = new EB_AkaMAccount__c();
    static EB_AkaMContact__c mailerContact1Mass;
    static EB_AkaMContact__c mailerContact2Mass;
    static EB_AkaMContact__c mailerContact3Mass;
    static EB_AkaMContact__c mailerContact3;
    static EB_AkaMContact__c mailerContact4;
    static EB_EmailTemplate__c testTemplate;
    static EB_AkaMailer__c mailer;
    static EB_AkaMailer__c massMailer;
    static Contact con1;
    static Contact con2;
    static Contact con3;
    static Account accOld;
    static Contact con4;
    static EB_AkaMAccount__c accWithoutContacts;
    static EB_AkaMailer__c mailerWithoutAccounts;
    static EB_AkaMAccount__c accWithAllContactsCcOrBcc;
    static EB_AkaMContact__c mailerContactCc;
    static EB_AkaMContact__c InvalidmailerContact; 
    static EB_AkaMAccount__c InvalidmailerAccount;
    static EB_NotificationType__c templateType;
    static EB_NotificationType__c templateType1;
    static EmailTemplate et;
    static String organizationId;
    //Start of changes for CR#967107
    /*this variable gives the total number of contacts for a particular mailer. this needs to be initialized 
    in the init method.*/
    static Integer totalContacts;
    public static EB_AkaMailer__c createMailer(String customTemplateId,String notificationType){
    //function to create Mailers
    // parameters - custom template id(Lookup), notificationType - Single Email/ Mass Email
        EB_AkaMailer__c mailerInit = new EB_AkaMailer__c();
        mailerInit.Email_Template__c = customTemplateId;
        mailerInit.EB_SINumber__c =100; 
        mailerInit.EB_Type__c = notificationType;
        mailerInit.EB_CustomNotificationText__c = 'ID0001';
        mailerInit.EB_IssueEndDateTime__c = Datetime.now();
        mailerInit.EB_IssueStartDateTime__c = Datetime.now();
        mailerInit.EB_ImpactedAkamaiProduct__c= 'product';
        mailerInit.EB_SingleMailBatchJobId__c = '';
        return mailerInit;
    }   
    static void init()  
    {         
         ManagedPkgErrorClass.isFromManagedPackage=false;
         // create new Email template for testing purpose
         //CR 794793, 794802- calling the method in the common class(EB_InitializeObjects) for initializing email template
         //CR#2308403 ssawhney - added to bypass the mixed dml exception error
         User usr = [Select id from User where Id = :UserInfo.getUserId()];
 
         System.RunAs(usr)
         {
            et = EB_InitializeObjects.createEmailTemplate('New_Email_Template','text');
            Database.insert(et);
         }
         
        list<EB_NotificationType__c> lstTypes = new list<EB_NotificationType__c>();
        //create Email Template Types Single Email and Mass Email
        templateType=new EB_NotificationType__c();
        templateType.Name= 'Single Email';
        templateType.Folder_Name__c=' EB_CNSingleMail';
        lstTypes.add(templateType);

        templateType1=new EB_NotificationType__c();
        templateType1.Name= 'Mass Email';
        templateType1.Folder_Name__c=' EB_CNMassMail';
        lstTypes.add(templateType1);
        database.insert(lstTypes);

        //create email template fot testing purpose
        //CR 794793,794802- calling the method in the common class(EB_InitializeObjects) for initializing custom template
        testTemplate= EB_InitializeObjects.createCustomTemplate('EB_Mailer_NotifyFailed','text', et.Id);
        database.insert(testTemplate);

        //create a mailer
        list<EB_AkaMailer__c> lstmailer = new list<EB_AkaMailer__c>();
        mailer = createMailer(testTemplate.Id,'Single Email');
        /*CR 1367210 change - to invoke chatter notification  method*/
        mailer.EB_ChatterNotification__c = true;
        lstmailer.add(mailer);
        
        massMailer = createMailer(testTemplate.Id,'Mass Email');
        /*CR 1367210 change - to invoke chatter notification  method*/
        massMailer.EB_ChatterNotification__c = true;
        lstmailer.add(massMailer);
        insert lstmailer;
        //System.debug('### ### ' + Database.insert(lstmailer));
        //System.debug('### ### ' + insert lstmailer);

        // create an account     
        accOld = EB_InitializeObjects.createAccount('TestAccount_01'); 
        Database.insert(accOld); 

        // Create contacts
        list<Contact> lstContact = new list<Contact>();
        con1 = EB_InitializeObjects.createContact('Fname','Lname',accOld.Id);
        lstContact.add(con1); 

        con2 = EB_InitializeObjects.createContact('Fname_1','Lname_1',accOld.Id);
        lstContact.add(con2);

        con3 = EB_InitializeObjects.createContact('Fname_2','Lname_3',accOld.Id);
        lstContact.add(con3);
        Database.insert(lstContact);    

        //create a mailer account
        list<EB_AkaMAccount__c> lstMailerAcc = new list<EB_AkaMAccount__c>();
        acc = EB_InitializeObjects.createMailerAccount(testTemplate.Id, mailer.Id, accOld.Id);
        lstMailerAcc.add(acc);
        
        accMass = EB_InitializeObjects.createMailerAccount(testTemplate.Id, massMailer.Id, accOld.Id);
        lstMailerAcc.add(accMass);
        Database.insert(lstMailerAcc);
        
        //create 5 mailer contacts
        list<EB_AkaMContact__c> lstMailerCon = new list<EB_AkaMContact__c>();
        mailerContact1 = EB_InitializeObjects.createMailerContact(testTemplate.Id, acc.Id, con1.Id);
        lstMailerCon.add(mailerContact1);
        
        mailerContact4 = EB_InitializeObjects.createMailerContact(testTemplate.Id, acc.Id, con1.Id);
        lstMailerCon.add(mailerContact4);  
        
        //Start of changes for CR#967107
        mailerContact1Mass = EB_InitializeObjects.createMailerContact(testTemplate.Id, accMass.Id, con1.Id);
        mailerContact1Mass.EB_IsBCC__c=true;
        //Start of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails 
        mailerContact1Mass.EB_ToList__c = 'janantha@akamai.com;shandatt@akamai.com';
        //End of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails
        lstMailerCon.add(mailerContact1Mass);  
              
        mailerContact2Mass = EB_InitializeObjects.createMailerContact(testTemplate.Id, accMass.Id, con1.Id);
        //Start of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails 
        mailerContact2Mass.EB_ToList__c = 'janantha@akamai.com;shandatt@akamai.com';
        //End of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails 
        lstMailerCon.add(mailerContact2Mass);
        
        mailerContact3Mass = EB_InitializeObjects.createMailerContact(testTemplate.Id, accMass.Id, con1.Id);
        //Start of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails
        mailerContact3Mass.EB_ToList__c = 'janantha@akamai.com;shandatt@akamai.com';
        //End of changes for CR# 1383743 by janantha for Lighter Foot Print Mass Mails
        lstMailerCon.add(mailerContact3Mass);  
        //End of changes for CR#967107
        
        mailerContact2 = EB_InitializeObjects.createMailerContact(testTemplate.Id, acc.Id, con2.Id);
        mailerContact2.EB_IsBCC__c=true;
        lstMailerCon.add(mailerContact2);  

        mailerContact3 = EB_InitializeObjects.createMailerContact(testTemplate.Id, acc.Id, con3.Id);
        mailerContact3.EB_IsCC__c=true;
        lstMailerCon.add(mailerContact3); 
        Database.insert(lstMailerCon);
        //Start of changes for CR#967107
        totalContacts = 2;
        //End of changes for CR#967107
    }
    
    public static testMethod void testSendMailBatchController(){
        init();
        string asyncFailId = ' ';
        string asyncCompleteId = ' ';
        //AsyncApexJob asyncJob = [SELECT Id FROM AsyncApexJob WHERE JobType = 'BatchApex'];
        for(AsyncApexJob objAsyncJob: [SELECT Id,Status FROM AsyncApexJob WHERE JobType = 'BatchApex' LIMIT 1000]){
            if(objAsyncJob.Status == 'Completed' ){
                asyncCompleteId = objAsyncJob.Id;
            }
            if(objAsyncJob.Status == 'Failed' || objAsyncJob.Status == 'Aborted'){
                asyncFailId = objAsyncJob.Id;
            }
            if(asyncFailId != ' ' && asyncCompleteId != ' '){
                break;
            }
        }
        system.debug('$$$$$ ' + asyncCompleteId + ' ' + asyncFailId);
        Test.startTest();
        PageReference sendMailsBatchClass = Page.EB_SendSingleMailBatchJobStatus;
        Test.setCurrentPageReference(sendMailsBatchClass);
        organizationId = [select Id from Organization limit 1 ][0].Id;
        sendMailsBatchClass.getParameters().put('mailerId', mailer.Id);
        mailer.EB_BatchStatus__c = 'EndOfBatch';
        mailer.EB_Operation__c = 'SendMails';
        
        EB_SendSingleMailBatchJobStatusCtrl controller = new EB_SendSingleMailBatchJobStatusCtrl();
        PageReference pgRef = controller.fetchMailerDetails();
        boolean boolValue = controller.isApexQueueEmpty();
        controller.retrySubmitingJob();
        mailer.EB_SingleMailBatchJobId__c = asyncFailId;
        update mailer; 
        PageReference pgRef1 = controller.fetchMailerDetails();
        boolean boolValue1 = controller.isApexQueueEmpty();
        controller.retrySubmitingJob();
        mailer.EB_SingleMailBatchJobId__c = asyncCompleteId;
        update mailer;
        PageReference pgRef2 = controller.fetchMailerDetails();
        boolean boolValue2 = controller.isApexQueueEmpty();
        controller.retrySubmitingJob();
        update mailer;
        Test.stopTest();
    }
    
    public static testMethod void testMarkMailerFail(){
        init();
        Test.startTest();
        	system.debug('### Mailer Id ' + mailer.Id);
            string results = EB_SingleMailBatchUtilClass.changeMailerContactsStatusToFail(mailer.Id);
        Test.stopTest();
    }    
    
    public static testMethod void testExceptionMethod(){
        try{
            EB_AkaMailer__c testMailer;
            testMailer.EB_SingleMailBatchJobId__c = '';
            update testMailer;
        }
        
        catch(Exception e){
            EB_SingleMailBatchUtilClass.sendMailOnException(e, 'TestClass', 'testExceptionMethod');
        }
    }
}