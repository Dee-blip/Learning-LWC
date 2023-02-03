/*
Author: Samir Jha
Description: Contains all the test cases for Eb_CtrlPreviewTemplateFirstPage

*/
@isTest
private class Eb_CtrlPreviewTemplateFirstPage_Test
{
    static EB_EmailTemplate__c testTemplate1;
    static EB_EmailTemplate__c testTemplate2;
    static Eb_CtrlPreviewTemplateFirstPage textHTMLEmailPreview;
    static EB_NotificationType__c templateType;
    static EB_NotificationType__c templateType1;
    static Eb_Token__c testTokenHTMLTemplate;   
    static Eb_Token__c testTokenTEXTTemplate;   
        
    
  /*
     Author : Samir Jha
     Description: This method is used to initialise data for test method.
     Created On: 25/03/2013
     
  */
     static void Init()
        {
			ManagedPkgErrorClass.isFromManagedPackage=false;
         //create Email Template Types Single Email and Mass Email
            templateType=new EB_NotificationType__c();
            templateType.Name= 'Single Email';
            templateType.Folder_Name__c=' EB_CNSingleMail';
            database.insert(templateType);
            
            templateType1=new EB_NotificationType__c();
            templateType1.Name= 'Mass Email';
            templateType1.Folder_Name__c=' EB_CNMassMail';
            database.insert(templateType1);
            
            String tempId1=[Select e.Id,developerName From EmailTemplate e where e.TemplateType='text' and e.FolderId in ( select Id from Folder where Name='Customer Notify Mass Email') limit 1].Id;
            //CR 794793- calling the method in the common class(EB_InitializeObjects) for initializing custom template 
            testTemplate1= EB_InitializeObjects.createCustomTemplate('template 2','text', tempId1);
            database.insert(testTemplate1);
      
           String tempId2=[Select e.Id,developerName,BrandTemplateId From EmailTemplate e where e.TemplateType='HTML' and e.FolderId in ( select Id from Folder where Name='Customer Notify Single Email') limit 1].Id;
            //CR 794793- calling the method in the common class(EB_InitializeObjects) for initializing custom template 
            testTemplate2= EB_InitializeObjects.createCustomTemplate('template 2','HTML', tempId2);
            database.insert(testTemplate2);
            
            
            testTokenTEXTTemplate=EB_InitializeObjects.createToken(testTemplate1.Id);
            database.insert(testTokenTEXTTemplate);
            
            testTokenHTMLTemplate=EB_InitializeObjects.createToken(testTemplate2.Id);
            database.insert(testTokenHTMLTemplate);
            //system.assertEquals(testTokenHTMLTemplate.Id,NULL);
        }
   /*
     Author : Samir Jha
     Description: This method is a positive test case for preview of HTML Email templates.
     Created On: 25/03/2013
    */
     static testMethod void Eb_CtrlPreviewTemplateFirstPage_HTMLTest() 
        {
            Init();
            String testtokenId = testTokenHTMLTemplate.Id;
            String testtemplateIDParam=testTemplate2.Id;
            PageReference Pg = Page.EB_VfpPreviewTemplate; 
            Test.setCurrentPageReference(Pg);
            ApexPages.currentPage().getParameters().put('token',testtokenId);
            ApexPages.currentPage().getParameters().put('templateidParam',testtemplateIDParam);
            test.startTest();
            textHTMLEmailPreview = new Eb_CtrlPreviewTemplateFirstPage();
            test.stopTest();
         
        }
        
    /*
     Author : Samir Jha
     Description: This method is a positive test case for preview of text based Email templates.
     Created On: 25/03/2013
    */
    static testMethod void Eb_CtrlPreviewTemplateFirstPage_TEXTTest() 
        {
            Init();
            String testtokenId = testTokenTEXTTemplate.Id;
            String testtemplateIDParam=testTemplate1.Id;
            PageReference Pg = Page.EB_VfpPreviewTemplate; 
            Test.setCurrentPageReference(Pg);
            ApexPages.currentPage().getParameters().put('token',testtokenId);
            ApexPages.currentPage().getParameters().put('templateidParam',testtemplateIDParam);
            test.startTest();
            textHTMLEmailPreview = new Eb_CtrlPreviewTemplateFirstPage();
            test.stopTest();
         
        }
}