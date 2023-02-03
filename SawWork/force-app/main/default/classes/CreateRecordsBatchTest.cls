/*
Author: Sonia Sawhney
Description: Contains test cases for CreateRecordsBatch
Created Date : 07/23/2013 
*/
@isTest
private class CreateRecordsBatchTest 
{ 
    static testMethod void testBatchS2SCreationWithoutParent() 
    {
       List<EB_NotificationType__c> templates =  CreateBulkTemplates();
       Test.StartTest();
       CreateRecordsBatch createRecords = new CreateRecordsBatch('EB_NotificationType__c', '');
       
       ID batchprocessid = Database.executeBatch(createRecords,200);
       Test.StopTest();
    
       /*System.AssertEquals(
               database.countquery('SELECT COUNT()'
              +' FROM PartnerNetworkRecordConnection WHERE LocalRecordId IN:templates'),
           200); */ 
   }
   
   static testMethod void testBatchS2SCreationWithParent() 
    {
       User currentUser = [ select Id from User where Id = :UserInfo.getUserId() ];
       System.runAs (currentUser) 
       {
           Test.StartTest();
           // Create an email template type to which the templates will be linked  
           EB_NotificationType__c type = new EB_NotificationType__c(Name='Test Type', 
                         Folder_Name__c = 'test folder');
           insert type;
           
           List<EB_EmailTemplate__c> templates =  CreateBulkTemplatesforTemplateTypes(type.Id);
    
           list<EB_NotificationType__c> lstTypes =  new list<EB_NotificationType__c>();
           lstTypes.add(type);
           ExternalSharingHelper.createS2Ssync('',lstTypes,null);
           
           CreateRecordsBatch createRecords = new CreateRecordsBatch('EB_EmailTemplate__c', 'EB_SFEmailTemplateId__c');
           
           ID batchprocessid = Database.executeBatch(createRecords,200);
           Test.StopTest();
       }
   }
   
   static private List<EB_EmailTemplate__c> CreateBulkTemplatesforTemplateTypes(Id typeId)
   {      
      // Create 200 test templates - this simulates one execute.  
      list<EmailTemplate> lstTemplate = new list<EmailTemplate>();
      Id folderId = [select Id from Folder where Name='Customer Notify Mass Email'].Id;
      Id BrandTempId= [select Id from BrandTemplate limit 1][0].Id;
      for(integer i = 0; i<200; i++)
      {
          EmailTemplate template = new EmailTemplate(Body='this is a test email',Description='some random template',
          DeveloperName='Test_Email_Template' + i,isActive=true, Name= 'Test_Email_Template' + i + '- Template',
          Templatetype='Text',TemplateStyle= 'Freeform', folderId = folderId,BrandTemplateId= BrandTempId);
          lstTemplate.add(template);
      }
      insert lstTemplate;
      
      list<EB_EmailTemplate__c> lstEmailTemplate = new list<EB_EmailTemplate__c>();
      for(EmailTemplate t: lstTemplate)
      {
         EB_EmailTemplate__c emailTemplate = new EB_EmailTemplate__c(Name = t.Name, EB_SFEmailTemplateId__c = t.Id,
                                                  EB_NotificationType__c = typeId);
         lstEmailTemplate.add(emailTemplate);
      }
      insert lstEmailTemplate; 
      return lstEmailTemplate;
   }
   
   static private List<EB_NotificationType__c> CreateBulkTemplates()
   {
      // Create 200 test templatetypes - this simulates one execute.  
      List <EB_NotificationType__c> types= new List<EB_NotificationType__c>();
      for(integer i = 0; i<200; i++){
         EB_NotificationType__c t = new EB_NotificationType__c(Name='Test Type'+i, 
                     Folder_Name__c = 'test folder'+i); 
         types.add(t);
      }  
      
      insert types;
      return types;  
   }
}