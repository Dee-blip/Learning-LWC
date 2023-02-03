/*
Author: Jayalakshmi A
Modified by: Sharath K
1. 9/21/2010- CR 794793: Implementing code review findings- This class now uses a common class EB_InitializeObjects to initialize the prerequisites for test cases
2. 11/14/11 for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
*/
@isTest
private class EB_UtilAccountPreview_Test
{
    static EB_NotificationType__c templateType;
    //Start of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
    static EB_NotificationType__c templateType1;
    //End of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
    static EB_EmailTemplate__c testTemplate1;
    static EB_EmailTemplate__c testTemplate2;
    //Start of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
    static EB_EmailTemplate__c testTemplate3;
    //End of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
    static Account accOld;
    static Account accO2d;
    static EB_AkaMAccount__c acc;
    static EB_AkaMAccount__c acc1;
    //Start of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
    static EB_AkaMAccount__c acc3;   
    //End of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
    static Contact con1;
    static Contact con2;
    static EB_AkaMContact__c mailerContact1;
    static EB_AkaMailer__c mailer;
    //Start of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
    static EB_AkaMailer__c mailer2;
    //End of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
    static EB_AkaMContact__c mailerContact2;
    //Start of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
    static EB_AkaMContact__c mailerContact3;
    //End of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
    static EmailTemplate et;
    static EmailTemplate et2;
    
    static testMethod void init()
    {
        ManagedPkgErrorClass.isFromManagedPackage=false;
        
        User thisUser = [Select ID from User where ID = :UserInfo.getUserId()];
        System.runAs(thisUser){
    // create new Email template for testing purpose
        //CR 794793- calling the method in the common class(EB_InitializeObjects) for initializing email template
        et = EB_InitializeObjects.createEmailTemplate('New_Email_Template','text');
        Database.insert(et);
        
        //Start of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
        et2 = EB_InitializeObjects.createEmailTemplate('New_Email_Template3','text');
        Database.insert(et2);
        //End of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
        }
        templateType=new EB_NotificationType__c();        
        templateType.Name= 'Single Email';        
        templateType.Folder_Name__c=' EB_CNSingleMail';       
        database.insert(templateType);
            
        //CR 794793- calling the method in the common class(EB_InitializeObjects) for initializing custom template
        testTemplate1= EB_InitializeObjects.createCustomTemplate('template 1','html', et.Id);
        database.insert(testTemplate1);
        
        //Start of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
        testTemplate3= EB_InitializeObjects.createCustomTemplate('template 3','html', et2.Id);
        database.insert(testTemplate3);
        //End of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
        
        String tempId1=[Select e.Id,developerName From EmailTemplate e where e.TemplateType='text' and e.FolderId in ( select Id from Folder where Name='Out of the box Templates') limit 1].Id;
        
        //CR 794793- calling the method in the common class(EB_InitializeObjects) for initializing custom template
        testTemplate2= EB_InitializeObjects.createCustomTemplate('template 2','text', tempId1);
        database.insert(testTemplate2);
  
        //CR 794793- calling the method in the common class(EB_InitializeObjects) for initializing mailer
        mailer = EB_InitializeObjects.createMailer(testTemplate1.Id,'Single Email');
        Database.insert(mailer);
        
        //Start of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
        mailer2 = EB_InitializeObjects.createMailer(testTemplate3.Id,'Mass Email');
        Database.insert(mailer2);
        //End of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
    
        // create an account
        //CR 794793- calling the method in the common class(EB_InitializeObjects) for initializing account    
        accOld = EB_InitializeObjects.createAccount('TestAccount_01'); 
        //accOld.OwnerId = user3.Id;
        Database.insert(accOld); 
        
        accO2d = EB_InitializeObjects.createAccount('TestAccount_02'); 
        Database.insert(accO2d); 
        
        //Start of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
        acc3 = EB_InitializeObjects.createMailerAccount(testTemplate1.Id, mailer2.Id, accOld.Id);
        Database.insert(acc3);
        //End of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
        
        //create a mailer account
        acc = EB_InitializeObjects.createMailerAccount(testTemplate1.Id, mailer.Id, accOld.Id);
        Database.insert(acc);
        //System.assertEquals(acc,null);
        
        acc1 = EB_InitializeObjects.createMailerAccount(testTemplate2.Id, mailer.Id, accO2d.Id);
        Database.insert(acc1);

        // Create contact
        con1 = EB_InitializeObjects.createContact('Fname','Lname',accOld.Id);
        Database.insert(con1); 
        
        con2 = EB_InitializeObjects.createContact('Fname1','Lname1',accO2d.Id);
        Database.insert(con2); 
        
        //Start of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
        mailerContact3 = EB_InitializeObjects.createMailerContact(testTemplate1.Id, acc3.Id, con1.Id);
        Database.insert(mailerContact3);
        //End of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271 
        
        mailerContact1 = EB_InitializeObjects.createMailerContact(testTemplate1.Id, acc.Id, con1.Id);
        Database.insert(mailerContact1); 
        
        mailerContact2 = EB_InitializeObjects.createMailerContact(testTemplate1.Id, acc1.Id, con2.Id);
        Database.insert(mailerContact2); 
        
    }
    
    static testMethod void testGetAkamContactId()
    {
        init();     
        test.startTest();
        //System.assertEquals(acc,'abd');
        EB_UtilAccountPreview.getAkamContactId(acc.Id);
        EB_UtilAccountPreview.getAkamContactId(acc1.Id);
        //Start of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
        EB_UtilAccountPreview.getAkamContactId(acc3.Id);
        //End of changes by janantha for enabling Preview Template for Text Templates in Mass Mails CR# 1404271
        test.stopTest();
    }
}