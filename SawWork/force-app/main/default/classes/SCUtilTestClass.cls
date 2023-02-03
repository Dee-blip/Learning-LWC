/**
 * SCUtilTestClass
 * History:
 * ==================================================================================================
 * Developer        Date        Description
 * --------------------------------------------------------------------------------------------------
   Kunal Sharma   08/18/2014    Util Class for creating data and reusable methods for SC.
   Sumanth Naik	  04/03/2019    Added test_AttachmentDeletionAMG for class AttachmentDeletionAMG ESESP-1916
   
 **/
@istest(seeAllData=false)
public class SCUtilTestClass {
    static List<User> lUser;
    static string userId;
    static list<sObject> lsObjectToInsert = new list<sObject>();
    static{
        utilTestClass.createCustomSettings();
        SCUserIdCustomSetting__c varUserIdCS = new SCUserIdCustomSetting__c();
        lUser= [SELECT Id FROM User WHERE Alias = 'CRMOPS'];
        userId = lUser[0].Id;
        string varOrgWideId = [SELECT Id, Address FROM OrgWideEmailAddress WHERE IsAllowAllProfiles = true][0].Id; 
        varUserIdCS.UserId__c = userId;
        varUserIdCS.Name = 'LunaPortalIntegration';
        lsObjectToInsert.add(varUserIdCS);
        SC_FromEmailAddress__c varFromEmailAddress = new SC_FromEmailAddress__c();
        varFromEmailAddress.Name = 'TechnialCaseNotification';
        varFromEmailAddress.OrgAddressId__c = varOrgWideId;
        lsObjectToInsert.add(varFromEmailAddress);
        System.runas(new User(Id = Userinfo.getUserId())){
            insert lsObjectToInsert;
        }
    }
    public static void createCustomSettingsForCase(){
       list<SObject> lSObjects = new list<SObject>(); 
       SCRecordTypeCustomSetting__c varSCRTCS = new SCRecordTypeCustomSetting__c();
       varSCRTCS.RecordTypeName__c = 'Technical,AMG,Billing,GSS CSAT,Emerging Products Engineering,Managed Security';
       varSCRTCS.Name = 'EmailToCaseRT ';
       lSObjects.add(varSCRTCS);

       SC_FromEmailAddress__c varSCFromEmailAdd = new SC_FromEmailAddress__c();
       varSCFromEmailAdd.Name = 'ProlexicFromEmailAddress';
       varSCFromEmailAdd.FromAddress__c = 'all@all.com';
       lSObjects.add(varSCFromEmailAdd); 
       
       EmailHandler_CS__c varEmailHandlerCS1 = new EmailHandler_CS__c(); 
       varEmailHandlerCS1.Name = 'billing';
       varEmailHandlerCS1.Email_Address__c = 'billing@akamai.com';
       varEmailHandlerCS1.Record_Type__c = 'Billing'; 
       lSObjects.add(varEmailHandlerCS1);
       
       EmailHandler_CS__c varEmailHandlerCS2 = new EmailHandler_CS__c(); 
       varEmailHandlerCS2.Name = 'care-att';
       varEmailHandlerCS2.Email_Address__c = 'ccare-att@akamai.com';
       varEmailHandlerCS2.Record_Type__c = 'Technical'; 
       lSObjects.add(varEmailHandlerCS2);
       
       EmailHandler_CS__c varEmailHandlerCS3 = new EmailHandler_CS__c(); 
       varEmailHandlerCS3.Name = 'ccare';
       varEmailHandlerCS3.Email_Address__c = 'ccare@akamai.com';
       varEmailHandlerCS3.Record_Type__c = 'Technical'; 
       lSObjects.add(varEmailHandlerCS3);
        
       EmailHandler_CS__c varEmailHandlerCS4 = new EmailHandler_CS__c(); 
       varEmailHandlerCS4.Name = 'ccare-att';
       varEmailHandlerCS4.Email_Address__c = 'ccare-att@akamai.com';
       varEmailHandlerCS4.Record_Type__c = 'Technical'; 
       lSObjects.add(varEmailHandlerCS4);
        
       EmailHandler_CS__c varEmailHandlerCS5 = new EmailHandler_CS__c(); 
       varEmailHandlerCS5.Name = 'client-endusersupport';
       varEmailHandlerCS5.Email_Address__c = 'client-endusersupport@akamai.com';
       varEmailHandlerCS5.Record_Type__c = 'Technical'; 
       lSObjects.add(varEmailHandlerCS5);
       
       EmailHandler_CS__c varEmailHandlerCS6 = new EmailHandler_CS__c(); 
       varEmailHandlerCS6.Name = 'CustomerCare';
       varEmailHandlerCS6.Email_Address__c = 'customercare@akamai.com';
       varEmailHandlerCS6.Record_Type__c = 'Technical'; 
       lSObjects.add(varEmailHandlerCS6);
        
       EmailHandler_CS__c varEmailHandlerCS7 = new EmailHandler_CS__c(); 
       varEmailHandlerCS7.Name = 'Emerging Product Group';
       varEmailHandlerCS7.Email_Address__c = 'epe-support@akamai.com';
       varEmailHandlerCS7.Record_Type__c = 'Emerging Products Engineering'; 
       lSObjects.add(varEmailHandlerCS7); 
       
       EmailHandler_CS__c varEmailHandlerCS8 = new EmailHandler_CS__c(); 
       varEmailHandlerCS8.Name = 'portal-feedback';
       varEmailHandlerCS8.Email_Address__c = 'portal-feedback@akamai.com';
       varEmailHandlerCS8.Record_Type__c = 'Technical'; 
       lSObjects.add(varEmailHandlerCS8); 
       
        /*
        EmailHandler_CS__c varEmailHandlerCS9 = new EmailHandler_CS__c(); 
        varEmailHandlerCS9.Name = 'prolexic';
        varEmailHandlerCS9.Email_Address__c = 'prolexic@akamai.com';
        varEmailHandlerCS9.Record_Type__c = 'Managed Security'; 
        lSObjects.add(varEmailHandlerCS9);
    */
       
       EmailHandler_CS__c varEmailHandlerCS10 = new EmailHandler_CS__c(); 
       varEmailHandlerCS10.Name = 'specialist';
       varEmailHandlerCS10.Email_Address__c = 'specialist@akamai.com';
       varEmailHandlerCS10.Record_Type__c = 'AMG'; 
       lSObjects.add(varEmailHandlerCS10);
       
       EmailHandler_CS__c varEmailHandlerCS11 = new EmailHandler_CS__c(); 
       varEmailHandlerCS11.Name = 'ps-tix';
       varEmailHandlerCS11.Email_Address__c = 'ps-tix@akamai.com';
       varEmailHandlerCS11.Record_Type__c = 'Technical'; 
       lSObjects.add(varEmailHandlerCS11);
        
       EmailHandler_CS__c varEmailHandlerCS12 = new EmailHandler_CS__c(); 
       varEmailHandlerCS12.Name = 'support';
       varEmailHandlerCS12.Email_Address__c = 'support@akamai.com';
       varEmailHandlerCS12.Record_Type__c = 'Technical'; 
       lSObjects.add(varEmailHandlerCS12); 
        
       /*SCUserIdCustomSetting__c varSCUSerIdCS = new SCUserIdCustomSetting__c();
       varSCUSerIdCS.Name = 'LunaPortalIntegration';
       varSCUSerIdCS.UserId__c = '005G0000003dnrRIAQ';
       lSObjects.add(varSCUSerIdCS);*/
       
       SurveyEmailHandler_CS__c varSurveyEmailCS1 = new SurveyEmailHandler_CS__c();
       varSurveyEmailCS1.Name = 'Billing Survey';
       varSurveyEmailCS1.Email_Address__c = 'billing_survey_feedback@akamai.com';
       lSObjects.add(varSurveyEmailCS1);
        
       SurveyEmailHandler_CS__c varSurveyEmailCS2 = new SurveyEmailHandler_CS__c();
       varSurveyEmailCS2.Name = 'ccare';
       varSurveyEmailCS2.Email_Address__c = 'ccare@akamai.com';
       lSObjects.add(varSurveyEmailCS2);
        
       SurveyEmailHandler_CS__c varSurveyEmailCS3 = new SurveyEmailHandler_CS__c();
       varSurveyEmailCS3.Name = 'specialist';
       varSurveyEmailCS3.Email_Address__c = 'specialist@akamai.com';
       lSObjects.add(varSurveyEmailCS3); 
        
       System.runas(new User(Id = Userinfo.getUserId())){ 
           insert lSObjects;
       }
    }
    public static Case createCase(){
        Case varCase = new Case();
        varCase.Subject = 'Test Case Subject';
        varCase.Description = 'Test Case Description';
        varCase.Recent_Update__c = false;
        varCase.origin = 'Others';
        insert varCase;
        return varCase;
    }
    
     static testMethod void testAttachmentNotification() {
         Case varCase = SCUtilTestClass.createCase();
         //string userId = [SELECT Id FROM User WHERE Alias = 'LCASE'][0].Id;
         Attachment varAttachment = new Attachment();
         varAttachment.ParentId = varCase.Id;
         varAttachment.Body = Blob.valueOf('Test Attachment Body');
         varAttachment.Name = 'Test Attachment Name';
         varAttachment.OwnerId = userId;
         insert varAttachment;
         delete varAttachment;
    }
    
    static testMethod void testTaskNotification(){
        Case varCase = SCUtilTestClass.createCase();
        Task varTask = new Task();
        varTask.Subject = 'Test Task Subject';
        varTask.OwnerId = userId;
        varTask.WhatId = varCase.Id;
        system.runAs(lUser[0]){
            insert varTask;
        }
    }
    
    //Test class for ESESP-1916
     static testMethod void test_AttachmentDeletionAMG()
     {
         
         
         //Create Account
           Account acc = new Account(Name='Test Account');
           insert acc;
        
         //Case2
          Case c2 = new Case();
          c2.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('AMG').getRecordTypeId();
          c2.Service__c='Contract Management';
          c2.Request_Type__c='Contract Migration';
          c2.Request_Sub_Type__c='Migration';
          c2.Origin = 'Email';
          c2.Subject = 'AMG Tech Case 1';
          c2.AccountId = acc.Id;
          insert c2;
          
          //Insert attachment with type other than excel
          String myString = 'StringToBlob';
          Blob myBlob = Blob.valueof(myString);
          Attachment a = new Attachment(parentid=c2.id, Name = 'xyz.xls' , Body = myBlob );
          insert a;
          
          //Updated Case to Closed
          Case c3 = [Select status,OwnerId from Case where id = :c2.id];
          c3.Status = 'Closed';
          c3.Resolved_Date__c = System.now();
          c3.Resolution_Field__c = 'Known Issue/ No workaround';
          c3.Solution_Summary__c = 'Test Data';
          c3.LOE_Hours__c = 1;
          c3.LOE_Minutes__c =1;
          c3.ResolvableByPartner__c='No';
          Test.startTest();
          update c3;
          Test.StopTest();
          
          //Try and delete the attachment
          try
          {
          
             Delete a;
          
          }
          catch(Exception e)
          {
            
             Boolean ExpectedError = e.getMessage().contains('A file cannot be deleted from a closed case')?true:false;
             system.debug('Error '+ExpectedError);
             System.AssertEquals(ExpectedError,true);
          
          }          
      }

}