/*=====================================================================================================+
    Class name          :   SC_PartnerCaseCreation_Layer_TC 
    Author              :   Himanshu Kar
    Created             :   09-APR-15
    Purpose             :   This test class is used for Partner Case Creation via Email Service. Components Involved as below:
                            1. SC_PartnerCaseCreation_Layer
                            
    Last Modified    Developer  Purpose            
    =============    =========  =======
    09-APR-15        Himanshu   Partner Email Service(CR# 2920026)
+=====================================================================================================*/

@isTest(seeAllData = false)
public class SC_PartnerCaseCreation_Layer_TC{
  
  //Create Test Data variables 
  static List<string> setToAdd;
  static List<Messaging.Inboundemail.TextAttachment> textAttList;
  static List<Messaging.Inboundemail.BinaryAttachment> binaryAttList;
  static Case CaseRec;
  
  //Creates the test data 
  static void createTestData() {
     	 utilTestClass.createCustomSettings();
		 SC_SupportEmail__c SC_SupportEmail_Rec;
        
         SC_SupportEmail_Rec = new SC_SupportEmail__c();
         SC_SupportEmail_Rec.Name = '1';
         SC_SupportEmail_Rec.Default_Task_Owner__c = 'ONA';
         SC_SupportEmail_Rec.Support_Email_AMS__c = 'sc-dev@akamai.com';
         SC_SupportEmail_Rec.Support_Email_AutoGen__c = 'sc-dev@akamai.com';
         SC_SupportEmail_Rec.PartnerCaseEmail__c = 'asfsa@adf.com;adfas@dfad.com';
         insert SC_SupportEmail_Rec;
         User currentusr = [Select id from User where Id = :UserInfo.getUserId()];
 
         System.RunAs(currentusr)
         {
           Environment_Setup__c environmentSetup = Environment_Setup__c.getOrgDefaults();
           environmentSetup.Active_Org__c = true;
           update environmentSetup;
         }
     
        // Creating Account Data
        Account accountData = new Account(Name='Test Account1',AKAM_Account_ID__c='Test-111');
        insert accountData;
    
        // Creating Contact Record
        Contact contactData = new Contact(AccountId = accountData.Id, Login__c = 'Test_xyz', Email = 'Test_xyz@akamai.com',
                        LastName = 'Test Contact');
        Insert contactData;
    
        // Creating To Add
        setToAdd = new List<string>();
        setToAdd.addAll(SC_SupportEmail__c.getValues('1').PartnerCaseEmail__c.split(';'));
     
        // Creating Text Attachment
        textAttList = new List<Messaging.Inboundemail.TextAttachment>();
        Messaging.Inboundemail.TextAttachment textAttachment1 = new Messaging.Inboundemail.TextAttachment();
        textAttachment1.fileName = 'testAttach1.txt';
        textAttachment1.body='This is the body of the test attachment1!';
        textAttList.add(textAttachment1);  
    
        // Creating Binary Attachment
        binaryAttList = new List<Messaging.Inboundemail.BinaryAttachment>();
        Messaging.Inboundemail.BinaryAttachment binaryAttachment1 = new Messaging.Inboundemail.BinaryAttachment();
        binaryAttachment1.fileName = 'testAttach1.txt';
        binaryAttachment1.body=Blob.valueOf('This is the body of the test attachment1!');
        binaryAttList.add(binaryAttachment1);
        
        // Create a new Case
            CaseRec = new case();
        CaseRec.Status = 'Unassigned';
        CaseRec.Origin = 'Email';
        CaseRec.subject = 'Partner Case Creation For Attching Email Message';
        insert CaseRec;
                        
   
  }
    
    
    // Method # 1: For Creating new Case + Handling Out of Office
    static testmethod void PartnerEmailService_Test_1() {
    
            // Calling Test data method
        createTestData();
            
            Test.StartTest();
    
            //Setting Email Service Values
            Messaging.InboundEmail email = new Messaging.InboundEmail() ;
            Messaging.InboundEnvelope env = new Messaging.InboundEnvelope();
    
            email.subject = 'Partner Case Creation';
            email.fromAddress = 'Test_xyz@akamai.com';
            email.plainTextBody = 'Partner Case Creation';
            email.toAddresses = setToAdd;
        
            // Setting Email Attachments
            email.textAttachments=textAttList;
            email.binaryAttachments=binaryAttList;
  
            SC_PartnerCaseCreation_Layer partnerCaseEmailInbound = new SC_PartnerCaseCreation_Layer();
            partnerCaseEmailInbound.handleInboundEmail(email, env);
            
            // For Covering Out Of Office Reply
            Messaging.InboundEmail email_13 = new Messaging.InboundEmail() ;
            email_13.subject = 'Partner Case Creation:Out Of Office';
            email_13.fromAddress = 'Test_xyz@akamai.com';
            email_13.plainTextBody = 'Partner Case Creation';
            email_13.toAddresses = setToAdd;
            SC_PartnerCaseCreation_Layer partnerCaseEmailInbound1 = new SC_PartnerCaseCreation_Layer();
            partnerCaseEmailInbound1.handleInboundEmail(email_13, env);
        
        Test.StopTest();
    }
    
     // Method # 2: Attaching Email Message to Existing Case based on ref: Id on Subject
    static testmethod void PartnerEmailService_Test_2() {
    
            // Calling Test data method
        createTestData();
        
            Test.StartTest();
            
            // Generating Email Thread Id from Case Id
            String caseId = CaseRec.Id;
            string Case_ThreadID = 'ref:' + '_'  + UserInfo.getOrganizationId().left(4)  + '0'  + 
                            UserInfo.getOrganizationId().mid(11,4) +
                            '._'  + caseId.left(4) + '0'  + caseId.mid(10,5) + ':ref';
                
                // Instantiating the Messaging Service
            Messaging.InboundEmail email_1 = new Messaging.InboundEmail() ;
            Messaging.InboundEnvelope env1 = new Messaging.InboundEnvelope();
    
            email_1.subject = 'Partner Case Creation ' + Case_ThreadID;
            email_1.fromAddress = 'Test_xyz@akamai.com';
            email_1.plainTextBody = 'Partner Case Creation' +  Case_ThreadID;
            email_1.toAddresses = setToAdd;
  
            // Sending Email with ref no in subject Line
            SC_PartnerCaseCreation_Layer partnerCaseEmailInbound3 = new SC_PartnerCaseCreation_Layer();
            partnerCaseEmailInbound3.handleInboundEmail(email_1, env1);
            
            // Sending Email with ref no in Email Body
            Messaging.InboundEmail email_12 = new Messaging.InboundEmail() ;
            Messaging.InboundEnvelope env3 = new Messaging.InboundEnvelope();
        List<Case> caseList = [select id,AKAM_Case_ID__c from Case where id = :caseId ];
        if (caseList != null && caseList.size() > 0)
            email_12.subject = 'Partner Case Creation '+'F-CS-'+caseList.get(0).AKAM_Case_ID__c;
            email_12.fromAddress = 'Test_xyz@akamai.com';
            email_12.plainTextBody = 'Partner Case Creation' ;
            email_12.toAddresses = setToAdd; 
            
            SC_PartnerCaseCreation_Layer partnerCaseEmailInbound4 = new SC_PartnerCaseCreation_Layer();
            partnerCaseEmailInbound4.handleInboundEmail(email_12, env3);
        
        // Instantiating the Messaging Service
            Messaging.InboundEmail email_123 = new Messaging.InboundEmail() ;
            Messaging.InboundEnvelope env123 = new Messaging.InboundEnvelope();
    
            email_123.subject = 'Partner Case Creation ' ;
            email_123.fromAddress = 'Test_xyz@akamai.com';
            email_123.plainTextBody = 'Partner Case Creation' +  Case_ThreadID;
            email_123.toAddresses = setToAdd;
        
         	SC_PartnerCaseCreation_Layer partnerCaseEmailInbound44 = new SC_PartnerCaseCreation_Layer();
        	Messaging.InboundEnvelope env4 = new Messaging.InboundEnvelope();
            partnerCaseEmailInbound44.handleInboundEmail(email_123, env4);
        
        // Instantiating the Messaging Service
            Messaging.InboundEmail email_1234 = new Messaging.InboundEmail() ;
            Messaging.InboundEnvelope env1234 = new Messaging.InboundEnvelope();
    
            email_1234.subject = 'Partner Case Creation ' ;
            email_1234.fromAddress = 'Test_xyz@akamai.com';
        	Case_ThreadID = 'ref:12345:ref';
            email_1234.plainTextBody = 'Partner Case Creation' +  Case_ThreadID;
            email_1234.toAddresses = setToAdd;
        
         	SC_PartnerCaseCreation_Layer partnerCaseEmailInbound444 = new SC_PartnerCaseCreation_Layer();
        	Messaging.InboundEnvelope env444 = new Messaging.InboundEnvelope();
            partnerCaseEmailInbound444.handleInboundEmail(email_1234, env444);

			Messaging.InboundEmail email_12345 = new Messaging.InboundEmail() ;
            Messaging.InboundEnvelope env12345 = new Messaging.InboundEnvelope();
    
            email_12345.subject = 'Partner Case Creation ' ;
            email_12345.fromAddress = 'Test_xyz@akamai.com';
        	//Case_ThreadID = 'ref:12345:ref';
            email_12345.plainTextBody = 'Partner Case Creation'+'[AKAM-CASE #'+caseList.get(0).AKAM_Case_ID__c + ']'; 
            email_12345.toAddresses = setToAdd;
        
         	SC_PartnerCaseCreation_Layer partnerCaseEmailInbound4444 = new SC_PartnerCaseCreation_Layer();
        	Messaging.InboundEnvelope env4444 = new Messaging.InboundEnvelope();
            partnerCaseEmailInbound4444.handleInboundEmail(email_12345, env4444);  
        
        //Test Scenario for Setting Delimiter {Case #} from Akamai Format      
           Messaging.InboundEmail email_123456 = new Messaging.InboundEmail() ;
            Messaging.InboundEnvelope env123456 = new Messaging.InboundEnvelope();
    
            email_123456.subject = 'Case # FD-CS- Test 1234 ' ;
            email_123456.fromAddress = 'Test_xyz@akamai.com';
        	//Case_ThreadID = 'ref:12345:ref';
            email_123456.plainTextBody = 'Case # FD-CS- Test 1234'; 
            email_123456.toAddresses = setToAdd;
        
         	SC_PartnerCaseCreation_Layer partnerCaseEmailInbound5555 = new SC_PartnerCaseCreation_Layer();
        	Messaging.InboundEnvelope env5555 = new Messaging.InboundEnvelope();
            partnerCaseEmailInbound5555.handleInboundEmail(email_123456, env5555);
        	
            Test.StopTest();
    } 

    
     
 }