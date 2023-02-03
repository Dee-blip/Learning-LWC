public class EB_InitializeObjects{

public static Account createAccount(String pAccName){
    //function to create accounts
    // parameters - Account Name
        Account newAccount = new Account();
        newAccount.Name = pAccName;
        newAccount.BillingCountry = 'India';
        newAccount.BillingState = 'Delhi';
        return newAccount;

    }

//Start of changes by Samir to initialize Account Team Members for test classes
public static AccountTeamMember createAccountTeamMember(String accId,String UId)
  {
    //function to create account team members
    // parameters - AccountId,UserId;
        AccountTeamMember newAccountMember = new AccountTeamMember();
        newAccountMember.AccountId = accId;
        newAccountMember.UserId=UId;
        system.assertNotEquals([Select id from User where Id=:UId],Null);
        newAccountMember.TeamMemberRole='Technical Support - Primary';
        return newAccountMember ;

    }
 
//Start of changes by Samir to initialize Tech Support Team Members for test classes  
public static EB_TechSupportTeams__c createAccountTeamTechSupport(String accId,String UId)
  {
    //function to create account team members
    // parameters - AccountId,UserId;
        EB_TechSupportTeams__c newAccountMember = new EB_TechSupportTeams__c();
        newAccountMember.EB_Account_Id__c = accId;
        newAccountMember.EB_Akam_User_Id__c=UId;
        newAccountMember.EB_Unique_Id__c=accId+UId;
        newAccountMember.EB_Email__c='testMail'+UId+'@akamai.com.test';
        return newAccountMember ;

    }

   
public static Contact createContact(String fName, String lName, String accId){
    //function to create Contacts
    // parameters - Contact 1st Name, Contact Last Name, Associated Account Id
        Contact newContact = new Contact();
        newContact.FirstName = fName;
        newContact.LastName = lName;
        newContact.AccountId = accId;
        newContact.Phone = '99999';
        newContact.Validation_Override__c = true;
        String strCustomGUID = CS_InitializeObjects.getCustomGUID('Test');
        //Start of changes by janantha for CR 1744933
        newContact.Email = 'janantha'+strCustomGUID+'@akamai.com';
        //Endof changes by janantha for CR 1744933
        newContact.Title = 'Tester';   
        newContact.MailingCountry = 'India';
        return newContact;
    }

public static EmailTemplate createEmailTemplate(String devName,String templateType){
    //function to create Email Templates
    // parameters - Developer Name, email template type (html/text)
        EmailTemplate newEmailTemplate = new EmailTemplate();
        newEmailTemplate.Body='this is a test email';
        newEmailTemplate.Description='some random template';
        newEmailTemplate.DeveloperName=devName;
        newEmailTemplate.isActive=true;
        newEmailTemplate.Name=devName+'- Template';
        newEmailTemplate.Templatetype=templateType;
        newEmailTemplate.FolderId=[select Id from Folder where Name='Customer Notify Mass Email'].Id;
        if(templateType=='HTML')
        {
        newEmailTemplate.BrandTemplateId=[select Id from BrandTemplate limit 1][0].Id;
        
        }
        return newEmailTemplate;
    }
    
public static EB_AkaMailer__c createMailer(String customTemplateId,String notificationType){
    //function to create Mailers
    // parameters - custom template id(Lookup), notificationType - Single Email/ Mass Email
        EB_AkaMailer__c mailer = new EB_AkaMailer__c();
        mailer.Email_Template__c = customTemplateId;
        mailer.EB_SINumber__c =100; 
        mailer.EB_Type__c = notificationType;
        mailer.EB_CustomNotificationText__c = 'ID0001';
        mailer.EB_IssueEndDateTime__c = Datetime.now();
        mailer.EB_IssueStartDateTime__c = Datetime.now();
        mailer.EB_ImpactedAkamaiProduct__c= 'product';
        return mailer;
}

public static EB_AkaMAccount__c createMailerAccount(String customTemplateId,String mailerId, String accountId){
    //function to create mailer account
    // parameters - custom template id(Lookup), Associated Mailer Id, Associated Account Id(Lookup)
        EB_AkaMAccount__c mailerAccount = new EB_AkaMAccount__c();
        mailerAccount.Email_Template__c = customTemplateId;
        mailerAccount.EB_Account__c = accountId;
        mailerAccount.EB_AkaMailer__c = mailerId;
        mailerAccount.EB_EnableValidationRules__c = false;
        return mailerAccount;
}

public static EB_AkaMContact__c createMailerContact(String customTemplateId,String mailerAccountId, String contactId){
    //function to create mailer contact
    // parameters - custom template id(Lookup), Associated Mailer Account Id, Assosciated Contact Id(lookup)
        EB_AkaMContact__c mailerContact= new EB_AkaMContact__c();
        mailerContact.Email_Template__c = customTemplateId;
        mailerContact.EB_AkaMAccount__c = mailerAccountId;
        mailerContact.EB_Contact__c = contactId;
        mailerContact.EB_IsBCC__c=false;
        mailerContact.EB_IsCC__c=false;
        mailerContact.EB_EnableValidationRules__c = false;
        return mailerContact;
}

public static EB_EmailTemplate__c createCustomTemplate(String templateName,String templateType,String stdTemplateId){
    //function to create
    // parameters - Template name, template type(html/text), lookup to the EmailTemplate object
        EB_EmailTemplate__c testTemplate=new EB_EmailTemplate__c();
        testTemplate.Name=templateName;
        testTemplate.EB_Template_Type__c=templateType;
        testTemplate.EB_SFEmailTemplateId__c=stdTemplateId;
		String notificationTypeId;
		list<EB_NotificationType__c> lstNotify =[select Id from EB_NotificationType__c where Name='Single Email' and Folder_Name__c != null];
		
		if(lstNotify != null && lstNotify.size()>0)
		{
			notificationTypeId = lstNotify[0].Id;
		}
		else
		{
			EB_NotificationType__c notificationType= new EB_NotificationType__c(Name = 'Test Type',Folder_Name__c = 'test folder');
			insert notificationType;
			notificationTypeId = notificationType.Id;
		}
        testTemplate.EB_NotificationType__c=notificationTypeId; 
        return testTemplate;
    }
	
    public static EB_Token__c createToken(ID templateID)
    {
    //function to create test token
    // parameters - template Id
    EB_Token__c testToken=new EB_Token__c();
    testToken.EB_TokenAdditionalReason__c='This is a test token';
    testToken.EB_TokenEmailTemplate__c=templateId;
    testToken.EB_TokenImpactedProduct__c='Test Product';
    return testToken;
    }

 public static BRANDTEMPLATE createletterhead(string NameParam,string HTMLValue)
    {
    //function to create test token
    // parameters - template Id
    BRANDTEMPLATE testletterhead=new BRANDTEMPLATE();
    testletterhead.Name=NameParam;
    testletterhead.Value=HTMLValue;
    return testletterhead;
    }
}