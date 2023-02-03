/*
Authors: Jayalakshmi A & Sharath K
Description: Contains web services that update templates on mailers/mailer accounts/mailer contacts , web service that retieves Environment URL, web service that 
            returns partial URL for parameterized reports , web service that clones a particular Mailer
Modified: 1)on 09/22/2010 by janantha for optionally cloning the follow up flag. CR# 808734
          2)on 09/23/2010 by janantha for Implementing Custom Batchable to be able to update the Email Templates for more than 
            1000 records CR# 794811
          3)on 10/01/2010 by janantha for cloning Failed/Processed Mailer Contacts CR# 819966
          4)on 11/4/2010 by janantha for throwing an error if the Email Template chosen for preview is already deleted. CR# 856235
          5)on 3/21/2011 by janantha for updating templates using action poller at the Mailer Acconts and Mailer Contacts
            in order to avoid multiple clicks to the Update Template button. CR#967107
          6)on 08/25/2011 by janantha for fixing the bug of "invalid integer" when number of contacts is more than 1000. CR#1064001
          7)on 07/06/2012 by vsriram CR 1766810 CNotify: Q32012 Clone Fix copying new default fields such as Si#, Impacted Region, Impacted Product, etc at Mailer
          8)on 21/8/2012 by mshardul CR 1799662: Q32012 Roll clone fix changes to other clone functionalities.  
          9)On 14/04/2014 by ssawhney CR 2499348: Customer Notification app should not create mailer if customer-notifications@akamai.com is marked as bad
          10)On 01/01/2016 by ssawhney CR 2812593: Email preview in Mailer not working for HTML templates
*/
global class EB_UtilMailer {
    /* ==============================================================================================
    descripion: this function returns the URL stored in the custom setting.
    created by: Jayalakshmi A
    test class & test method:   
    modifications: date, by, description
        1.Created :6/23/2010
        2. Modified: 9/03/2010 CR-785487 :Enabling OnDemand HTTP Sync for Email Templates Sync - Added refresh_email_templates() for this
    code review:
    =================================================================================================== */
   //start of changes CR- 1799662
   public String cloneType = '';
   //End of changes CR-1799662
   
    webservice static String getUrl()
    {
        String url = EB_UtilApplication.getProperty_EnvironmentURL();
        return url;
    }
     
    WebService static String update_template (String template,String ID)
    {  
        List<EB_AkaMContact__c> contacts=new List<EB_AkaMContact__c>();
        String strExceptionMessage='';
        
        try{
        EB_EmailTemplate__c temp= [select Id from EB_EmailTemplate__c where Name = :template][0];
        for (EB_AkaMContact__c MContact : [select Email_Template__c,EB_IsCC__c,EB_IsBCC__c  from EB_AkaMContact__c where EB_AkaMContact__c.EB_AkaMAccount__r.ID = :ID])    
        {    
            if(MContact.EB_IsCC__c != true && MContact.EB_IsBCC__c != true)
            {
            MContact.Email_Template__c = temp.Id;    
            contacts.add(MContact);
            }
        }    
        update contacts;
        }
        catch(DMLException e)
        {
            strExceptionMessage = e.getMessage();
            return strExceptionMessage;
        }
        catch(QueryException e1)
        {
            strExceptionMessage = e1.getMessage();
            return strExceptionMessage;
        }
        catch(Exception e2)
        {
            strExceptionMessage = e2.getMessage();
            return strExceptionMessage;
        }
        return strExceptionMessage;
    }    
    
    /* ==============================================================================================
    descripion: this function updates the templates of all the accounts under a mailer 
    and all the contacts under all the accounts
    created by: Jayalakshmi A
    test class & test method:   
    modifications: date, by, description
        1.Created :6/-/2010
        Modified: on 09/23/2010 by janantha for Implementing Custom Batchable to be able to update the Email Templates for more than 
                  1000 records CR# 794811
                  On 11/4/2010 by janantha for including the CC, BCC condition in the soql. CR# 856235
    code review:
    =================================================================================================== */
    webservice static String updateTemplate(String ID,String TemplateName)
    {
        List<EB_AkaMAccount__c> accountTemp = new List<EB_AkaMAccount__c>();
        List<EB_AkaMContact__c> contactTemp = new List<EB_AkaMContact__c>();
        Boolean CC = false;
        Boolean BCC = false;
        List<EB_AkaMContact__c> MContact = new List<EB_AkaMContact__c>();
        List<EB_AkaMAccount__c> MAccount = new List<EB_AkaMAccount__c>(); 
        String strExceptionMessage='';
        //start of change by janantha on 09/23/2010 for updating email templates for more than 1000 records. CR# 794811
        EB_AkaMailer__c akamMailer = new EB_AkaMailer__c(); 
        Integer numberOfRecordsProcessed = 0;
        Integer batch_Size;
        try
        {
            akamMailer = [select EB_OperationStatus__c,EB_Operation__c,EB_OperationProcessedCount__c,EB_CountToAddresses__c from EB_AkaMailer__c where Id = :ID];
            akamMailer.EB_Operation__c = 'UpdateTemplate';
            akamMailer.EB_OperationStatus__c = 'Start';
            update akamMailer;
            
            EB_EmailTemplate__c temp= [select Id from EB_EmailTemplate__c where name = :TemplateName][0];
            
            EBCS_Application__c batchSize = EBCS_Application__c.getInstance('UpdateTemplateBatchSize'); 
            batch_Size = Integer.valueof((batchSize.Value__c).trim());
            
            MAccount = [select ID, Email_Template__c from EB_AkaMAccount__c 
            where EB_AkaMAccount__c.EB_AkaMailer__r.ID = :ID and Email_Template__c!=:temp.Id limit :batch_Size];
            //end of change by janantha on 09/23/2010 for updating email templates for more than 1000 records. CR# 794811
            //update the value of the template in Mailer Account. 
            for(EB_AkaMAccount__c AkamAccount:MAccount)
            {
                AkamAccount.Email_Template__c = temp.Id;
                accountTemp.add(AkamAccount);
            }
            
            if(accountTemp.size()>0)
            {
                update(accountTemp);
            }
            //start of change by janantha on 09/23/2010 for updating email templates for more than 1000 records. CR# 794811
            //start of change by janantha on 11/4/2010 by janantha for including the CC, BCC condition in the soql. CR# 856235
            MContact = [select Email_Template__c, EB_IsCC__c,EB_IsBCC__c from EB_AkaMContact__c
            where EB_AkaMContact__c.EB_AkaMAccount__r.EB_AkaMailer__r.ID = :ID and Email_Template__c!=:temp.Id and EB_IsCC__c = false and EB_IsBCC__c = false limit :batch_Size];
            //end of change by janantha on 09/23/2010 for updating email templates for more than 1000 records. CR# 794811
            //end of change by janantha on 11/4/2010 by janantha for including the CC, BCC condition in the soql. CR# 856235
            for(EB_AkaMContact__c AkamContact:MContact)
            {
                CC = AkamContact.EB_IsCC__c;
                BCC = AkamContact.EB_IsBCC__c;
                if(CC != true && BCC != true)
                {
                    //start of change by janantha on 09/23/2010 for updating email templates for more than 1000 records. CR# 794811
                    numberOfRecordsProcessed++;
                    //end of change by janantha on 09/23/2010 for updating email templates for more than 1000 records. CR# 794811
                    contactTemp.add(AkamContact); 
                    AkamContact.Email_Template__c = temp.Id;
                }
            }  
            //start of change by janantha on 09/23/2010 for updating email templates for more than 1000 records. CR# 794811
            if(contactTemp.size()>0)
                update(contactTemp);
            
            if(numberOfRecordsProcessed == 0)
            {
                akamMailer.EB_Operation__c = '';
                akamMailer.EB_OperationStatus__c = 'End';
                akamMailer.EB_OperationProcessedCount__c = 0;
                update akamMailer; 
                return 'End';
            }
            if(akamMailer.EB_OperationProcessedCount__c == 0)
            {
                akamMailer.EB_OperationProcessedCount__c = numberOfRecordsProcessed;
                update akamMailer;
            }
            else
            {
                akamMailer.EB_OperationProcessedCount__c = akamMailer.EB_OperationProcessedCount__c + numberOfRecordsProcessed;
                update akamMailer;
            }
            if(akamMailer.EB_OperationProcessedCount__c == akamMailer.EB_CountToAddresses__c)
            {
                akamMailer.EB_Operation__c = '';
                akamMailer.EB_OperationStatus__c = 'End';
                akamMailer.EB_OperationProcessedCount__c = 0;
                update akamMailer; 
                return 'End';
            }
            //end of change by janantha on 09/23/2010 for updating email templates for more than 1000 records. CR# 794811
        }
        catch(DMLException e)
        {
            strExceptionMessage = e.getMessage();
            return strExceptionMessage;
        }
        catch(QueryException e1)
        {
            strExceptionMessage = e1.getMessage();
            return strExceptionMessage;
        }
        catch(Exception e2)
        {
            strExceptionMessage = e2.getMessage();
            return strExceptionMessage;
        }
        return strExceptionMessage;
    }   
    //start of changes for CR#967107
   /*This function takes the Mailer Id and Template Name as the input and updates the template of all the contacts belonging to that particular mailer.
   The progress information is displayed on a VF Page which uses Action Poller to carry out the operation in batches.CR#967107*/
    webservice static String updateTemplateActionPoller(String ID,String TemplateName)
    {
        List<EB_AkaMAccount__c> accountTemp = new List<EB_AkaMAccount__c>();
        List<EB_AkaMContact__c> contactTemp = new List<EB_AkaMContact__c>();
        Boolean CC = false;
        Boolean BCC = false;
        List<EB_AkaMContact__c> MContact = new List<EB_AkaMContact__c>();
        List<EB_AkaMAccount__c> MAccount = new List<EB_AkaMAccount__c>(); 
        String strExceptionMessage='';
        EB_AkaMailer__c akamMailer = new EB_AkaMailer__c(); 
        Integer numberOfRecordsProcessed = 0;
        Integer batch_Size;
        
        try
        {
            akamMailer = [select EB_OperationStatus__c,EB_BatchStatus__c,EB_Operation__c,EB_OperationProcessedCount__c,EB_CountToAddresses__c from EB_AkaMailer__c where Id = :ID];
            akamMailer.EB_Operation__c = 'UpdateTemplate';
            akamMailer.EB_OperationStatus__c = 'Start';                      
            akamMailer.EB_BatchStatus__c = 'StartOfBatch';
            
            update akamMailer;
            
            EB_EmailTemplate__c temp= [select Id from EB_EmailTemplate__c where name = :TemplateName][0];
            
            EBCS_Application__c batchSize = EBCS_Application__c.getInstance('UpdateTemplateBatchSize'); 
            batch_Size = Integer.valueof((batchSize.Value__c).trim());
            
            MAccount = [select ID, Email_Template__c from EB_AkaMAccount__c 
            where EB_AkaMAccount__c.EB_AkaMailer__r.ID = :ID and Email_Template__c!=:temp.Id limit :batch_Size];           
            //update the value of the template in Mailer Account. 
            for(EB_AkaMAccount__c AkamAccount:MAccount)
            {
                AkamAccount.Email_Template__c = temp.Id;
                accountTemp.add(AkamAccount);
            }
            
            if(accountTemp.size()>0)
            {
                update(accountTemp);
            }
                      
            MContact = [select Email_Template__c, EB_IsCC__c,EB_IsBCC__c from EB_AkaMContact__c
            where EB_AkaMContact__c.EB_AkaMAccount__r.EB_AkaMailer__r.ID = :ID and Email_Template__c!=:temp.Id and EB_IsCC__c = false and EB_IsBCC__c = false limit :batch_Size];
            
            for(EB_AkaMContact__c AkamContact:MContact)
            {
                CC = AkamContact.EB_IsCC__c;
                BCC = AkamContact.EB_IsBCC__c;
                if(CC != true && BCC != true)
                {
                    numberOfRecordsProcessed++;
                    contactTemp.add(AkamContact); 
                    AkamContact.Email_Template__c = temp.Id;
                }
            }  
            
            if(contactTemp.size()>0)
                update(contactTemp);
            if(numberOfRecordsProcessed == batch_Size)
            {
                akamMailer.EB_BatchStatus__c = 'EndOfBatch';
                update akamMailer;
            }
            if(numberOfRecordsProcessed == 0)
            {
                akamMailer.EB_Operation__c = '';
                akamMailer.EB_OperationStatus__c = 'End';
                akamMailer.EB_OperationProcessedCount__c = 0;
                akamMailer.EB_BatchStatus__c = 'EndOfBatch';
                update akamMailer; 
                return 'End';
            }
            if(akamMailer.EB_OperationProcessedCount__c == 0)
            {
                akamMailer.EB_OperationProcessedCount__c = numberOfRecordsProcessed;
                update akamMailer;
            }
            else
            {
                akamMailer.EB_OperationProcessedCount__c = akamMailer.EB_OperationProcessedCount__c + numberOfRecordsProcessed;
                update akamMailer;
            }
            
            if(akamMailer.EB_OperationProcessedCount__c == akamMailer.EB_CountToAddresses__c)
            {
                akamMailer.EB_Operation__c = '';
                akamMailer.EB_OperationStatus__c = 'End';
                akamMailer.EB_BatchStatus__c = 'EndOfBatch';
                akamMailer.EB_OperationProcessedCount__c = 0;
                update akamMailer; 
                return 'End';
            }
        }
        catch(DMLException e)
        {
            strExceptionMessage = e.getMessage();
            return strExceptionMessage;
        }
        catch(QueryException e1)
        {
            strExceptionMessage = e1.getMessage();
            return strExceptionMessage;
        }
        catch(Exception e2)
        {
            strExceptionMessage = e2.getMessage();
            return strExceptionMessage;
        }
        return strExceptionMessage;
    }   
    //End of changes for CR#967107
    
    //TODO: CR Info
    //CR 1766810 CNotify: Q32012 Clone Fix copying new default fields such as Si#, Impacted Region, Impacted Product, etc at Mailer
    //Private Variable used in DeepClone
    public String strMailerId;
    private String strTemplateId;
    private Object totalContactInMailers;
    /* ==============================================================================================
    descripion: this function clones the mailer, accounts and contacts and returns the 
    mailer Id of the cloned mailer
    created by: Jayalakshmi A
    test class & test method:   
    modifications: date, by, description
        1.Created :6/23/2010
        2.Modified on 9/1/2010 by janantha CR# 785451
            change: removed the copying of Email Templates in the cloned record
        3.Modified on 09/22/2010 by janantha for optionally cloning the follow up flag. CR# 808734
    code review:
    SHANDATT 08182010 code change
    webservice static String deepClone(String strMailerId, String strTemplate, Decimal strCaseId, String strInternalList)
    =================================================================================================== */
    public System.PageReference deepClone()
    {
    
        List<EB_AkaMAccount__c> accountRecords = new List<EB_AkaMAccount__c>();  
        List<EB_AkaMContact__c> contactRecords = new List<EB_AkaMContact__c>();
        List<String> accountIds = new List<String>();
        Map<String,String> old_new_account_id = new Map<String,String>();
        String strCustomNotification;
        List<String> tempAccountIds = new List<String>();
        //List<String> tempTemplates = new List<String>();
        List<String> tempAccountName = new List<String>();
        List<String> newAccountId = new List<String>();
        List<Boolean> tempContactccEmailIds = new List<Boolean>();
        List<Boolean> tempContactbccEmailIds = new List<Boolean>();
        //List<String> tempContactTemplates = new List<String>();
        List<String> tempEmailId = new List<String>();
        List<String> tempParentContactId = new List<String>();
        Integer increment = 0;
        String clonedMailerId;
        String strExceptionMessage = '';
        Boolean followUp;
        String strDescription;
        //start of changes on 9/22/2010 by janantha for optionally cloning the follow up flag. CR# 808734
        String ignoreFollowUp;
        //end of changes on 9/22/2010 by janantha for optionally cloning the follow up flag. CR# 808734
        EB_AkaMailer__c clonedMailer = new EB_AkaMailer__c();
        EB_AkaMailer__c akamMailer = new EB_AkaMailer__c();
        try
        {
            //Start of change by janantha for CR# 785451 on 9/1/2010
            //EB_EmailTemplate__c temp= [select Id from EB_EmailTemplate__c where name = :strTemplate][0];
            //End of change by janantha for CR# 785451 on 9/1/2010
            
            strCustomNotification = [select EB_CustomNotificationText__c from EB_AkaMailer__c where Id=:strMailerId].EB_CustomNotificationText__c;
            //start of changes on 9/22/2010 by janantha for optionally cloning the follow up flag. CR# 808734 
            EBCS_Application__c cloneFollowUp = EBCS_Application__c.getInstance('IgnoreFollowUpDuringClone'); 
            ignoreFollowUp = cloneFollowUp.Value__c;
            if(ignoreFollowUp == 'FALSE')
            {
                followUp = [select Follow_Up__c from EB_AkaMailer__c where Id = :strMailerId].Follow_Up__c;
                clonedMailer.Follow_Up__c = followUp;
            }
            //end of changes on 9/22/2010 by janantha for optionally cloning the follow up flag. CR# 808734 
            strDescription = [select EB_Description__c from EB_AkaMailer__c where Id = :strMailerId].EB_Description__c;
            clonedMailer.EB_Description__c = strDescription;
            //Start of change by janantha for CR# 785451 on 9/1/2010
            //clonedMailer.Email_Template__c = temp.Id;
            //End of change by janantha for CR# 785451 on 9/1/2010
            clonedMailer.EB_Status__c = 'New';
            //CR 1766810 CNotify: Q32012 Clone Fix copying new default fields such as Si#, Impacted Region, Impacted Product, etc at Mailer
            //Vineet Start Of Changes
            clonedMailer.EB_SINumber__c = newtoken.EB_TokenSINumber__c;
            clonedMailer.EB_CustomNotificationText__c = strCustomNotification;
            clonedMailer.EB_AdditionalIssueDescription__c = newtoken.EB_TokenAdditionalReason__c;
            clonedMailer.EB_ImpactedAkamaiProduct__c = newtoken.EB_TokenImpactedProduct__c;
            clonedMailer.EB_ImpactedRegion__c =  newtoken.EB_TokenImpactedRegion__c;
            clonedMailer.EB_IssueEndDateTime__c = newtoken.EB_TokenEndDate__c;
            clonedMailer.EB_IssueReason__c = newtoken.EB_TokenIssueReason__c;
            clonedMailer.EB_IssueStartDateTime__c = newtoken.EB_TokenStartDate__c;
            clonedMailer.Email_Template__c =newtoken.EB_TokenEmailTemplate__c;
            clonedMailer.EB_ChatterNotification__c = newtoken.EB_ChatterNotification__c;
            for(EB_emailTemplate__c et:[select name from EB_EmailTemplate__c where id = :clonedMailer.Email_Template__c limit 1])
            strTemplateId = et.name;
            //End Of Changes
            /*start of changes*/
            /*EB_AkaMailer__c mailer = [select EB_ImpactedAkamaiProduct__c,EB_ImpactedRegion__c,EB_IssueEndDateTime__c,EB_IssueReason__c,EB_IssueStartDateTime__c,EB_AdditionalIssueDescription__c from EB_AkaMailer__c where Id = :strMailerId];
            clonedMailer.EB_AdditionalIssueDescription__c = mailer.EB_AdditionalIssueDescription__c;
            clonedMailer.EB_ImpactedAkamaiProduct__c = mailer.EB_ImpactedAkamaiProduct__c;
            clonedMailer.EB_ImpactedRegion__c = mailer.EB_ImpactedRegion__c;
            clonedMailer.EB_IssueEndDateTime__c = mailer.EB_IssueEndDateTime__c;
            clonedMailer.EB_IssueReason__c = mailer.EB_IssueReason__c;
            clonedMailer.EB_IssueStartDateTime__c = mailer.EB_IssueStartDateTime__c;*/
            /*end of changes*/
           // clonedMailer.EB_InternalList__c = strInternalList;
            
            insert clonedMailer;
            clonedMailerId = clonedMailer.Id;
            
            for(EB_AkaMAccount__c tempAccount:[select EB_AkaMAccount__c.Id, EB_Account__c, EB_AkaMailer__c, EB_Status__c, Email_Template__c from EB_AkaMAccount__c where EB_AkaMAccount__c.EB_AkaMailer__r.Id = :strMailerId])
            {
                tempAccountIds.add(tempAccount.Id);
                //Start of change by janantha for CR# 785451 on 9/1/2010
                //tempTemplates.add(tempAccount.Email_Template__c);
                //End of change by janantha for CR# 785451 on 9/1/2010
                tempAccountName.add(tempAccount.EB_Account__c);
                accountIds.add(tempAccount.Id);
            }
       
            while(increment<tempAccountIds.size())
            {
                EB_AkaMAccount__c newAccount = new EB_AkaMAccount__c();
                newAccount.EB_AkaMailer__c = clonedMailer.Id;
                //Start of change by janantha for CR# 785451 on 9/1/2010
                //newAccount.Email_Template__c = tempTemplates.get(increment);
                //End of change by janantha for CR# 785451 on 9/1/2010
                newAccount.EB_Account__c = tempAccountName.get(increment);
                newAccount.EB_Status__c = 'New';
                //Vineet CR 1766810 CNotify: Q32012 Clone Fix copying new default fields such as Si#, Impacted Region, Impacted Product, etc at Mailer
                newAccount.Email_Template__c = clonedMailer.Email_Template__c;
                accountRecords.add(newAccount);
                
                increment++;
            }
            
            insert accountRecords;
            
            for(EB_AkaMAccount__c newAcc:accountRecords)
            {
                newAccountId.add(newAcc.Id);
            }
            
            increment = 0;
            
            for(EB_AkaMContact__c tempContact:[select EB_AkaMContact__c.Id,  EB_AkaMAccount__c,EB_Contact__c, EB_IsBCC__c, EB_IsCC__c, EB_Status__c,EB_Email_Id__c, Email_Template__c from EB_AkaMContact__c where EB_AkaMContact__c.EB_AkaMAccount__r.Id in :accountIds])
            {
                tempContactbccEmailIds.add(tempContact.EB_IsBCC__c);
                tempContactccEmailIds.add(tempContact.EB_IsCC__c);
                //Start of change by janantha for CR# 785451 on 9/1/2010
                //tempContactTemplates.add(tempContact.Email_Template__c);
                //End of change by janantha for CR# 785451 on 9/1/2010
                tempEmailId.add(tempContact.EB_Email_Id__c);
                tempParentContactId.add(tempContact.EB_Contact__c);
            }
            
            Integer i = 0;
            while(i<tempAccountIds.size())
            {
                old_new_account_id.put(tempAccountIds.get(i), newAccountId.get(i));
                i++;
            }
            
            Integer increment2 = 0;
            
            for(EB_AkaMContact__c tempContact1:[select EB_AkaMAccount__c from EB_AkaMContact__c where EB_AkaMContact__c.EB_AkaMAccount__r.Id in :accountIds])
            {
                EB_AkaMContact__c newContact = new EB_AkaMContact__c();
                newContact.EB_Status__c = 'New';
                String oldAccountId = tempContact1.EB_AkaMAccount__c;
                String newAccountId1 = old_new_account_id.get(oldAccountId);
                newContact.EB_AkaMAccount__c = newAccountId1;
                newContact.EB_IsBCC__c = tempContactbccEmailIds.get(increment2);
                newContact.EB_IsCC__c = tempContactccEmailIds.get(increment2);
                //Start of change by janantha for CR# 785451 on 9/1/2010
                //newContact.Email_Template__c = tempContactTemplates.get(increment2);
                //End of change by janantha for CR# 785451 on 9/1/2010
                newContact.EB_Contact__c = tempParentContactId.get(increment2);
                //Vineet CR 1766810 CNotify: Q32012 Clone Fix copying new default fields such as Si#, Impacted Region, Impacted Product, etc at Mailer
                newContact.Email_Template__c = clonedMailer.Email_Template__c;
                contactRecords.add(newContact);
                increment2++;
            }
            insert contactRecords;
        }
        catch(DMLException e)
        {
            strExceptionMessage = e.getMessage();
            //return '-1'+strExceptionMessage;
            //system.Assertequals('1st','Place');
            return null;
        }
        catch(QueryException e1)
        {
            strExceptionMessage = e1.getMessage();
            //return '-1'+strExceptionMessage;
            //system.Assertequals('1st','Place');
            return null;
        }
        catch(Exception e2)
        {
            strExceptionMessage = e2.getMessage();
            //return '-1'+strExceptionMessage;
            //system.Assertequals('1st','Place');
            return null;
        }
        //return clonedMailerId;
        PageReference newPage = new PageReference('/' + clonedMailerId);
        newPage.SetRedirect(true);
       return newPage;
       //Vineet Calls the UpdateTemplates After Cloning
       //PageReference newPage = new PageReference('/apex/EB_VfpUpdateTemplateActionPoller?TotalContacts='+totalContactInMailers+'&id='+ clonedMailerId + '&OrganizationId=00DK00000004pLv' +'&TemplateId='+ strTemplateId );
       //newPage.SetRedirect(true);
        //return newPage;
        //return Page.EB_VfpUpdateTemplateActionPoller;
        
        
    }
    
    /* ==============================================================================================
    descripion: this function builds the url which will take the user to the preview of a mail at the  
    mailer contact level
    created by: Jayalakshmi A
    test class & test method:   
    modifications: date, by, description
        1.Created :7/6/2010 
        2.Modified: 10/5/2010 by janantha for enabling both text and html previews to be displayed from the list button CR# 794811
                    On 11/4/2010 by janantha for throwing an error if the Email Template chosen for preview is already deleted. CR# 856235
                    On 01/01/2016 by ssawhney for changing the email preview links CR# 2812593 
    code review:
    =================================================================================================== */
    webservice static List<String> getPreviewURL(String contactId, String template_Id ,List<String> akamContactIds)
    {
        String url = EB_UtilApplication.getProperty_EnvironmentURL();
        List<String> previewURLs = new List<String>();
        //start of changes on 11/4/2010 by janantha for throwing an error if the Email Template chosen for preview is already deleted. CR# 856235
        Set<String> invalidContacts = new Set<String>();
        List<String> invalidIds = new List<String>();
        //end of changes on 11/4/2010 by janantha for throwing an error if the Email Template chosen for preview is already deleted. CR# 856235
        String previewUrl = '';
        try
        {
            //List<EB_AkaMContact__c> selectedAkamTemplates = [select EB_TemplateId__c, Email_Template__r.EB_Template_Type__c, EB_Contact__c, Id, EB_PreviewUrl__c from EB_AkaMContact__c where Id in :akamContactIds];
            List<EB_AkaMContact__c> selectedAkamTemplates = [select EB_TemplateId__c,name,Email_Template__r.EB_SFEmailTemplateId__c, Email_Template__r.EB_Template_Type__c, EB_Contact__c, Id, EB_PreviewUrl__c, EB_MailerType__c from EB_AkaMContact__c where Id in :akamContactIds];
            //start of changes on 11/4/2010 by janantha for throwing an error if the Email Template chosen for preview is already deleted. CR# 856235
            List<String> existingTemplateIds = new List<String>();
            for(EmailTemplate template:[select Id from EmailTemplate WHERE isActive = true])
            {
                existingTemplateIds.add(template.Id);
            }
            List<EB_AkaMContact__c> invalidTemplates = [select Id from EB_AkaMContact__c where (Id in :akamContactIds) and (EB_TemplateId__c not in :existingTemplateIds) and (EB_TemplateId__c!='' and EB_TemplateId__c!=null)];
            for(EB_AkaMContact__c con:invalidTemplates)
            {
                invalidIds.add(con.Id);
            }
            invalidContacts.addAll(invalidIds);
            //end of changes on 11/4/2010 by janantha for throwing an error if the Email Template chosen for preview is already deleted. CR# 856235
            for(EB_AkaMContact__c temp:selectedAkamTemplates)
            {
                //start of change on 10/5/2010 by janantha for enabling both text and html previews to be displayed from the list button CR# 794811
                if(invalidContacts.contains(temp.Id))
                {
                    previewURLs.add('-1'+temp.name);
                }
                else
                {
                    //Start of changes for CR 2812593 
                    /*if(temp.Email_Template__r.EB_Template_Type__c == 'html')
                        previewURLs.add(url+'email/author/emailauthorframe.jsp?email_type=html&template_id='+temp.EB_TemplateId__c+'&id=00YS0000000S3Zk&'+'p2_lkid='+temp.EB_Contact__c+'&'+'p3_lkid='+temp.Id+'&preview=1');
                    else if(temp.Email_Template__r.EB_Template_Type__c == 'text')
                        previewURLs.add(url+'apex/EB_VfpPreviewEmailAsText?Id='+temp.Id);
                    */                        
                    previewURLs.add(url+'apex/EB_EmailPreview?Id='+temp.Id+'&MailerType=' + temp.EB_MailerType__c);
                    //End of changes for CR 2812593 
                }
                //end of change on 10/5/2010 by janantha for enabling both text and html previews to be displayed from the list button CR# 794811
            }
        }
        catch(QueryException e)
        {
            previewURLs.clear();
            previewURLs.add('-1'+e.getMessage());
            return previewURLs;
        }
        catch(Exception e1)
        {
            previewURLs.clear();
            previewURLs.add('-1'+e1.getMessage());
            return previewURLs;
        }
        //System.assertEquals(previewURLs,null);
        return previewURLs;
    } 

// function to fetch all the parameterized reports
//Author - Sharath
// 08-16-2010 - adding a new report - mailer Warning Report
webservice static String parameter_report(String mailerName,String reportName){
String reportId;
String returnVal;
EBCS_Reports__c  report=new EBCS_Reports__c();
    if(reportName=='Mailer Exception Report')
    {   
        report=EBCS_Reports__c.getInstance('Mailer Exception Report'); 
        reportId = report.ReportId__c;
        returnVal =  reportId + '?pv0=' + mailerName; 
    }
    else if (reportName=='Email Bounce Report')
    {
      report=EBCS_Reports__c.getInstance('Email Bounce Report'); 
      reportId = report.ReportId__c;
      returnVal =  reportId + '?pv1=' + mailerName;  
    }
    else
    {
        report=EBCS_Reports__c.getInstance('Mailer Warning Report'); 
        reportId = report.ReportId__c;
        returnVal =  reportId + '?pv0=' + mailerName; 
   }
    return returnVal;
    }

//function to sync email templates On Demand - send a http-request to CAST IRON
// part of CR-785487
    webservice static String refresh_email_templates()
    {
    // hardcoded values for v 1.0
    EBCS_Application__c cast_url = new EBCS_Application__c();
    String returnVal;
    cast_url =EBCS_Application__c.getInstance('CastIron URL'); 
      returnVal= cast_url.Value__c;
      // append the particular cast iron orchestration name
      returnVal= returnVal + 'EBSyncTemplates';
    return returnVal;
    }
    /* ==============================================================================================
    descripion: this function clones only the Mailer Accounts and Mailer Contacts that are in the Failed status, and returns the 
    mailer Id of the cloned mailer. CR# 819966
    created by: Jayalakshmi A
    test class & test method:   
    modifications: date, by, description
        1.Created :10/1/2010
        2.Modification : 21/8/2012 
            CR- 1799662 : CNotify: Q32012 Rolling Clone Fix To Other Clone Functionality
                i.e. to Clone failed records and clone processed records.
    code review:
    =================================================================================================== */
 //Start of changes CR-1799662 By: Shardul
  public System.PageReference cloneFailedRecords( )
 //End of changes CR-1799662  
    {
        List<EB_AkaMAccount__c> accountRecords = new List<EB_AkaMAccount__c>();  
        List<EB_AkaMContact__c> contactRecords = new List<EB_AkaMContact__c>();
        List<String> accountIds = new List<String>();
        Map<String,String> old_new_account_id = new Map<String,String>();
        String strCustomNotification;
        List<String> tempAccountIds = new List<String>();
        List<String> tempAccountName = new List<String>();
        List<String> newAccountId = new List<String>();
        List<Boolean> tempContactccEmailIds = new List<Boolean>();
        List<Boolean> tempContactbccEmailIds = new List<Boolean>();
        List<String> tempEmailId = new List<String>();
        List<String> tempParentContactId = new List<String>();
        Integer increment = 0;
        String clonedMailerId;
        String strExceptionMessage = '';
        Boolean followUp;
        String strDescription;
        String ignoreFollowUp;
        
        EB_AkaMailer__c clonedMailer = new EB_AkaMailer__c();
        EB_AkaMailer__c akamMailer = new EB_AkaMailer__c();
        try
        {
            strCustomNotification = [select EB_CustomNotificationText__c from EB_AkaMailer__c where Id=:strMailerId].EB_CustomNotificationText__c;
             
            EBCS_Application__c cloneFollowUp = EBCS_Application__c.getInstance('IgnoreFollowUpDuringClone'); 
            ignoreFollowUp = cloneFollowUp.Value__c;
            if(ignoreFollowUp == 'FALSE')
            {
                followUp = [select Follow_Up__c from EB_AkaMailer__c where Id = :strMailerId].Follow_Up__c;
                clonedMailer.Follow_Up__c = followUp;
            }
             
            strDescription = [select EB_Description__c from EB_AkaMailer__c where Id = :strMailerId].EB_Description__c;
            clonedMailer.EB_Description__c = strDescription;
            
            clonedMailer.EB_Status__c = 'New';
          
            clonedMailer.EB_CustomNotificationText__c = strCustomNotification;
            
            // start of changes (1)  CR-1799662  Rolling Clone Fix To Other Clone Functionality. Author : Shardul
            
            clonedMailer.EB_SINumber__c = newtoken.EB_TokenSINumber__c;
            clonedMailer.EB_CustomNotificationText__c = strCustomNotification;
            clonedMailer.EB_AdditionalIssueDescription__c = newtoken.EB_TokenAdditionalReason__c;
            clonedMailer.EB_ImpactedAkamaiProduct__c = newtoken.EB_TokenImpactedProduct__c;
            clonedMailer.EB_ImpactedRegion__c =  newtoken.EB_TokenImpactedRegion__c;
            clonedMailer.EB_IssueEndDateTime__c = newtoken.EB_TokenEndDate__c;
            clonedMailer.EB_IssueReason__c = newtoken.EB_TokenIssueReason__c;
            clonedMailer.EB_IssueStartDateTime__c = newtoken.EB_TokenStartDate__c;
            clonedMailer.Email_Template__c =newtoken.EB_TokenEmailTemplate__c;
            clonedMailer.EB_ChatterNotification__c = newtoken.EB_ChatterNotification__c;
            for(EB_emailTemplate__c et:[select name from EB_EmailTemplate__c where id = :clonedMailer.Email_Template__c limit 1])
            strTemplateId = et.name;
            //End Of Changes
            
            /*start of changes*/
            /*EB_AkaMailer__c mailer = [select EB_ImpactedAkamaiProduct__c,EB_ImpactedRegion__c,EB_IssueEndDateTime__c,EB_IssueReason__c,EB_IssueStartDateTime__c,EB_AdditionalIssueDescription__c from EB_AkaMailer__c where Id = :strMailerId];
            clonedMailer.EB_AdditionalIssueDescription__c = mailer.EB_AdditionalIssueDescription__c;
            clonedMailer.EB_ImpactedAkamaiProduct__c = mailer.EB_ImpactedAkamaiProduct__c;
            clonedMailer.EB_ImpactedRegion__c = mailer.EB_ImpactedRegion__c;
            clonedMailer.EB_IssueEndDateTime__c = mailer.EB_IssueEndDateTime__c;
            clonedMailer.EB_IssueReason__c = mailer.EB_IssueReason__c;
            clonedMailer.EB_IssueStartDateTime__c = mailer.EB_IssueStartDateTime__c;*/
            /*end of changes*/
           
           // clonedMailer.EB_InternalList__c = strInternalList;
            //End of changes (1) Shardul
            insert clonedMailer;
            clonedMailerId = clonedMailer.Id;
            
            for(EB_AkaMAccount__c tempAccount:[select EB_AkaMAccount__c.Id, EB_Account__c, EB_AkaMailer__c, EB_Status__c, Email_Template__c from EB_AkaMAccount__c where EB_AkaMAccount__c.EB_AkaMailer__r.Id = :strMailerId and EB_Status__c = 'Failed'])
            {
                tempAccountIds.add(tempAccount.Id);
                tempAccountName.add(tempAccount.EB_Account__c);
                accountIds.add(tempAccount.Id);
            }
            //System.assertEquals(tempAccountIds.size(),100);
            while(increment<tempAccountIds.size())
            {
                EB_AkaMAccount__c newAccount = new EB_AkaMAccount__c();
                newAccount.EB_AkaMailer__c = clonedMailer.Id;
                newAccount.EB_Account__c = tempAccountName.get(increment);
                newAccount.EB_Status__c = 'New';
               // start of changes (2)  CR-1799662  Rolling Clone Fix To Other Clone Functionality. Author : Shardul
                newAccount.Email_Template__c = clonedMailer.Email_Template__c;
                //end of changes (2)
                accountRecords.add(newAccount);
                
                increment++;
            }
            
            insert accountRecords;
            
            for(EB_AkaMAccount__c newAcc:accountRecords)
            {
                newAccountId.add(newAcc.Id);
            }
            
            increment = 0;
            
            for(EB_AkaMContact__c tempContact:[select EB_AkaMContact__c.Id,  EB_AkaMAccount__c,EB_Contact__c, EB_IsBCC__c, EB_IsCC__c, EB_Status__c,EB_Email_Id__c, Email_Template__c from EB_AkaMContact__c where ((EB_AkaMContact__c.EB_AkaMAccount__r.Id in :accountIds) and (EB_Status__c = 'Failed')) or ((EB_AkaMContact__c.EB_AkaMAccount__r.Id in :accountIds) and (EB_Status__c = 'New') and ((EB_isCC__c = true) or (EB_isBCC__c = true)))])
            {
                tempContactbccEmailIds.add(tempContact.EB_IsBCC__c);
                tempContactccEmailIds.add(tempContact.EB_IsCC__c);
                tempEmailId.add(tempContact.EB_Email_Id__c);
                tempParentContactId.add(tempContact.EB_Contact__c);
            }
            
            Integer i = 0;
            while(i<tempAccountIds.size())
            {
                old_new_account_id.put(tempAccountIds.get(i), newAccountId.get(i));
                i++;
            }
            
            Integer increment2 = 0;
            
            for(EB_AkaMContact__c tempContact1:[select EB_AkaMAccount__c from EB_AkaMContact__c where ((EB_AkaMContact__c.EB_AkaMAccount__r.Id in :accountIds) and (EB_Status__c = 'Failed')) or ((EB_AkaMContact__c.EB_AkaMAccount__r.Id in :accountIds) and (EB_Status__c = 'New') and ((EB_isCC__c = true) or (EB_isBCC__c = true)))])
            {
                EB_AkaMContact__c newContact = new EB_AkaMContact__c();
                newContact.EB_Status__c = 'New';
                String oldAccountId = tempContact1.EB_AkaMAccount__c;
                String newAccountId1 = old_new_account_id.get(oldAccountId);
                newContact.EB_AkaMAccount__c = newAccountId1;
                newContact.EB_IsBCC__c = tempContactbccEmailIds.get(increment2);
                newContact.EB_IsCC__c = tempContactccEmailIds.get(increment2);
                //Start of change by janantha for CR# 785451 on 9/1/2010
                //newContact.Email_Template__c = tempContactTemplates.get(increment2);
                //End of change by janantha for CR# 785451 on 9/1/2010
                newContact.EB_Contact__c = tempParentContactId.get(increment2);
                 // start of changes (3)  CR-1799662  Rolling Clone Fix To Other Clone Functionality. Author : Shardul
                newContact.Email_Template__c = clonedMailer.Email_Template__c;
                // end of changes (3)
                contactRecords.add(newContact);
                increment2++;
            }
            insert contactRecords;
        }
        catch(DMLException e)
        {
            strExceptionMessage = e.getMessage();
            //return '-1'+strExceptionMessage;
            //system.Assertequals('1st','Place');
            return null;
        }
        catch(QueryException e1)
        {
            strExceptionMessage = e1.getMessage();
            //return '-1'+strExceptionMessage;
            //system.Assertequals('1st','Place');
            return null;
        }
        catch(Exception e2)
        {
            strExceptionMessage = e2.getMessage();
            //return '-1'+strExceptionMessage;
            //system.Assertequals('1st','Place');
            return null;
        }
        //return clonedMailerId;
         
            // start of changes (4)  CR-1799662  Rolling Clone Fix To Other Clone Functionality. Calling the new page Author : Shardul
        PageReference newPage = new PageReference('/' + clonedMailerId);
        newPage.SetRedirect(true);
       return newPage;
       //End of changes (4)
    }
      
    /* ==============================================================================================
    descripion: this function clones only the Mailer Accounts and Mailer Contacts that are in the Processed status, and returns the 
    mailer Id of the cloned mailer. CR# 819966
    created by: Jayalakshmi A
    test class & test method:   
    modifications: date, by, description
        1.Created :10/1/2010
        2.Modification : 21/8/2012 
            CR- 1799662 : CNotify: Q32012 Rolling Clone Fix To Other Clone Functionality
                i.e. to Clone failed records and clone processed records.
    code review:
    =================================================================================================== */
     //Start of changes CR-1799662 By: Shardul
     public System.PageReference cloneProcessedRecords( )
    //End of changes CR-1799662
    {
        List<EB_AkaMAccount__c> accountRecords = new List<EB_AkaMAccount__c>();  
        List<EB_AkaMContact__c> contactRecords = new List<EB_AkaMContact__c>();
        List<String> accountIds = new List<String>();
        Map<String,String> old_new_account_id = new Map<String,String>();
        String strCustomNotification;
        List<String> tempAccountIds = new List<String>();
        List<String> tempAccountName = new List<String>();
        List<String> newAccountId = new List<String>();
        List<Boolean> tempContactccEmailIds = new List<Boolean>();
        List<Boolean> tempContactbccEmailIds = new List<Boolean>();
        List<String> tempEmailId = new List<String>();
        List<String> tempParentContactId = new List<String>();
        Integer increment = 0;
        String clonedMailerId;
        String strExceptionMessage = '';
        Boolean followUp;
        String strDescription;
        String ignoreFollowUp;
       
        EB_AkaMailer__c clonedMailer = new EB_AkaMailer__c();
        EB_AkaMailer__c akamMailer = new EB_AkaMailer__c();
        
        try
        {
            strCustomNotification = [select EB_CustomNotificationText__c from EB_AkaMailer__c where Id=:strMailerId].EB_CustomNotificationText__c; 
            EBCS_Application__c cloneFollowUp = EBCS_Application__c.getInstance('IgnoreFollowUpDuringClone'); 
            ignoreFollowUp = cloneFollowUp.Value__c;
            if(ignoreFollowUp == 'FALSE')
            {
                followUp = [select Follow_Up__c from EB_AkaMailer__c where Id = :strMailerId].Follow_Up__c;
                clonedMailer.Follow_Up__c = followUp;
            }
             
            strDescription = [select EB_Description__c from EB_AkaMailer__c where Id = :strMailerId].EB_Description__c;
            clonedMailer.EB_Description__c = strDescription;
            clonedMailer.EB_Status__c = 'New';
            //clonedMailer.EB_SINumber__c = [select EB_SINumber__c from EB_AkaMailer__c where Id = :strMailerId].EB_SINumber__c;
            clonedMailer.EB_CustomNotificationText__c = strCustomNotification;
            
            // start of changes (5)  CR-1799662  Rolling Clone Fix To Other Clone Functionality. Author : Shardul
            
            clonedMailer.EB_SINumber__c = newtoken.EB_TokenSINumber__c;
            clonedMailer.EB_CustomNotificationText__c = strCustomNotification;
            clonedMailer.EB_AdditionalIssueDescription__c = newtoken.EB_TokenAdditionalReason__c;
            clonedMailer.EB_ImpactedAkamaiProduct__c = newtoken.EB_TokenImpactedProduct__c;
            clonedMailer.EB_ImpactedRegion__c =  newtoken.EB_TokenImpactedRegion__c;
            clonedMailer.EB_IssueEndDateTime__c = newtoken.EB_TokenEndDate__c;
            clonedMailer.EB_IssueReason__c = newtoken.EB_TokenIssueReason__c;
            clonedMailer.EB_IssueStartDateTime__c = newtoken.EB_TokenStartDate__c;
            clonedMailer.Email_Template__c =newtoken.EB_TokenEmailTemplate__c;
            clonedMailer.EB_ChatterNotification__c = newtoken.EB_ChatterNotification__c;
            for(EB_emailTemplate__c et:[select name from EB_EmailTemplate__c where id = :clonedMailer.Email_Template__c limit 1])
            strTemplateId = et.name;
            //End of changes (5) Shardul
            
            insert clonedMailer;
            clonedMailerId = clonedMailer.Id;
            
            for(EB_AkaMAccount__c tempAccount:[select EB_AkaMAccount__c.Id, EB_Account__c, EB_AkaMailer__c, EB_Status__c, Email_Template__c from EB_AkaMAccount__c where EB_AkaMAccount__c.EB_AkaMailer__r.Id = :strMailerId and EB_Status__c = 'Processed'])
            {
                tempAccountIds.add(tempAccount.Id);
                tempAccountName.add(tempAccount.EB_Account__c);
                accountIds.add(tempAccount.Id);
            }
       
            while(increment<tempAccountIds.size())
            {
                EB_AkaMAccount__c newAccount = new EB_AkaMAccount__c();
                newAccount.EB_AkaMailer__c = clonedMailer.Id;
                newAccount.EB_Account__c = tempAccountName.get(increment);
                newAccount.EB_Status__c = 'New';
                 // start of changes (6)  CR-1799662  Rolling Clone Fix To Other Clone Functionality. Author : Shardul
                newAccount.Email_Template__c = clonedMailer.Email_Template__c;
                //end of changes (6)
                accountRecords.add(newAccount);
                
                increment++;
            }
            
            insert accountRecords;
            
            for(EB_AkaMAccount__c newAcc:accountRecords)
            {
                newAccountId.add(newAcc.Id);
            }
            
            increment = 0;
            
            for(EB_AkaMContact__c tempContact:[select EB_AkaMContact__c.Id,  EB_AkaMAccount__c,EB_Contact__c, EB_IsBCC__c, EB_IsCC__c, EB_Status__c,EB_Email_Id__c, Email_Template__c from EB_AkaMContact__c where ((EB_AkaMContact__c.EB_AkaMAccount__r.Id in :accountIds) and (EB_Status__c = 'Processed')) or ((EB_AkaMContact__c.EB_AkaMAccount__r.Id in :accountIds) and ((EB_Status__c = 'New') and ((EB_isCC__c = true) or (EB_isBCC__c = true)))) ])
            {
                tempContactbccEmailIds.add(tempContact.EB_IsBCC__c);
                tempContactccEmailIds.add(tempContact.EB_IsCC__c);
                tempEmailId.add(tempContact.EB_Email_Id__c);
                tempParentContactId.add(tempContact.EB_Contact__c);
            }
            
            Integer i = 0;
            while(i<tempAccountIds.size())
            {
                old_new_account_id.put(tempAccountIds.get(i), newAccountId.get(i));
                i++;
            }
            
            Integer increment2 = 0;
            
            for(EB_AkaMContact__c tempContact1:[select EB_AkaMAccount__c from EB_AkaMContact__c where ((EB_AkaMContact__c.EB_AkaMAccount__r.Id in :accountIds) and (EB_Status__c = 'Processed')) or ((EB_AkaMContact__c.EB_AkaMAccount__r.Id in :accountIds) and ((EB_Status__c = 'New') and ((EB_isCC__c = true) or (EB_isBCC__c = true))))])
            {
                EB_AkaMContact__c newContact = new EB_AkaMContact__c();
                newContact.EB_Status__c = 'New';
                String oldAccountId = tempContact1.EB_AkaMAccount__c;
                String newAccountId1 = old_new_account_id.get(oldAccountId);
                newContact.EB_AkaMAccount__c = newAccountId1;
                newContact.EB_IsBCC__c = tempContactbccEmailIds.get(increment2);
                newContact.EB_IsCC__c = tempContactccEmailIds.get(increment2);
                newContact.EB_Contact__c = tempParentContactId.get(increment2);
                 // start of changes (7)  CR-1799662  Rolling Clone Fix To Other Clone Functionality. Author : Shardul
                newContact.Email_Template__c = clonedMailer.Email_Template__c;
                // end of changes (7)
                contactRecords.add(newContact);
                increment2++;
            }
            insert contactRecords;
        }
        catch(DMLException e)
        {
            strExceptionMessage = e.getMessage();
            //return '-1'+strExceptionMessage;
            //system.Assertequals('1st','Place');
            return null;
        }
        catch(QueryException e1)
        {
            strExceptionMessage = e1.getMessage();
           //return '-1'+strExceptionMessage;
            //system.Assertequals('1st','Place');
            return null;
        }
        catch(Exception e2)
        {
            strExceptionMessage = e2.getMessage();
            //return '-1'+strExceptionMessage;
            //system.Assertequals('1st','Place');
            return null;
        }
          //return clonedMailerId;
         
            // start of changes (8)  CR-1799662  Rolling Clone Fix To Other Clone Functionality. Calling the new page Author : Shardul
        PageReference newPage = new PageReference('/' + clonedMailerId);
        newPage.SetRedirect(true);
       return newPage;
       //End of changes (8)
    }
    /*Start of changes for CR#967107 for using action poller to update templates at the Mailer accounts and
    Mailer contacts in order to avoid multiple clicks by the user.*/
    
    String batchStatus = '';
    String operationStatus = '';
    String mailerStatus = '';
    public String MailerLink = '';
    public String status = 'Pending';
    EBCS_Application__c batchSize = EBCS_Application__c.getInstance('UpdateTemplateBatchSize'); 
    Integer batch_Size = Integer.valueof((batchSize.Value__c).trim());
    double processedCount = 0;
    double totalContacts;
    
    /*
    Author: Jayalakshmi A
    Created Date: 21 March 2011
    Description: This function invokes the updateTemplateActionPoller() if the current batch is completed and sets the 'status' to
    'Completed' after all the contacts are updated with the templates and builds the 'MailerLink' CR#967107*/
    public PageReference updateTemplateActionPoller()
    {
        MailerLink = '';
        status = 'Pending';
        String strMailer_Id = ApexPages.currentPage().getParameters().get('id');
        EB_AkaMailer__c mailer1 = [select EB_BatchStatus__c,EB_CountToAddresses__c,EB_Operation__c,EB_OperationProcessedCount__c,EB_Status__c from EB_AkaMailer__c where Id = :strMailer_Id];
        batchStatus = mailer1.EB_BatchStatus__c;
        processedCount = mailer1.EB_OperationProcessedCount__c;
        mailerStatus = mailer1.EB_Status__c;
        totalContacts = mailer1.EB_CountToAddresses__c;
        /*the Template Id of the Email Template at the Mailer is passed as a Url parameter.*/
        String templateId = ApexPages.currentPage().getParameters().get('TemplateId'); 
        
        /*check for the batch status='EndOfBatch' before invoking the update templates function.
          This is to ensure that the previous batch operation has completed before invoking the next batch*/
          
        if(batchStatus == 'EndOfBatch' || mailer1.EB_Operation__c == 'UpdateTemplate')
        {
            String result = updateTemplateActionPoller(strMailer_Id,templateId);
        }
        
        /*Query for Operation status of the mailer after the invocation of update templates function to check for the new status*/
        EB_AkaMailer__c mailer2 = [select EB_OperationStatus__c from EB_AkaMailer__c where Id = :strMailer_Id];
        if(mailer2.EB_OperationStatus__c == 'End')
        {
            status = 'Completed';
            MailerLink = getUrl()+strMailer_Id;
        }
        return null;
    }
    
    /*Author: Jayalakshmi A
      Created Date: 21 March 2011
      Description: This function returns the number of Contacts for which templates are updated.CR#967107*/
    public double getProcessedContacts()
    {
        /*If the status is not 'Completed' then return the number of contacts for which the template has been updated*/
        if(status!='Completed')
        {
            return processedCount;
        }
        /*If the status is 'Completed' indicates that the templates have been updated for all the Contacts. Hence return the total number of Contacts.*/
        else if(status =='Completed')
        {
            return totalContacts;
        }
        return 0;
    }
    
    /*Author: Jayalakshmi A
      Created Date: 21 March 2011
      Description: This function returns the number of Contacts for which templates needs to be updated.CR#967107*/
    public double getPendingContacts()
    {
        /* Start of changes for fixing the bug of "invalid integer" when number of contacts is more than 1000. CR#1064001 */
        String strTotalToAddress = ApexPages.currentPage().getParameters().get('TotalContacts');
        String newStrTotalToAddress = strTotalToAddress.replaceAll(',','');
        double totalToAddress = Integer.valueOf(newStrTotalToAddress);
        //double totalToAddress = Integer.valueOf(ApexPages.currentPage().getParameters().get('TotalContacts'));
        /* End of changes for fixing the bug of "invalid integer" when number of contacts is more than 1000. CR#1064001 */
        return totalToAddress - getProcessedContacts();
    }
    
    /*Author: Jayalakshmi A
      Created Date: 21 March 2011
      Description: This function returns the total number of Contacts in the Mailer if the number of contacts is less than the batch size
      else it returns the batch size.CR#967107*/
    public Integer getPendingBatchSize()
    {
        /* Start of changes for fixing the bug of "invalid integer" when number of contacts is more than 1000. CR#1064001 */
        String strTotalToAddresses = ApexPages.currentPage().getParameters().get('TotalContacts');
        String newStrTotalToAddresses = strTotalToAddresses.replaceAll(',','');
        Integer totalToAddresses = Integer.valueOf(newStrTotalToAddresses);
        //Integer totalToAddresses = Integer.valueOf(ApexPages.currentPage().getParameters().get('TotalContacts'));
        /* End of changes for fixing the bug of "invalid integer" when number of contacts is more than 1000. CR#1064001 */
        if(status!='Completed')
        {
            if(totalToAddresses<batch_size)
            {
                return totalToAddresses;
            }
            else if(totalToAddresses>batch_size)
            {
                return batch_size;
            }
        }
        else
        {
            return 0;   
        }   
        return 0;
    }
    
    /*Author: Jayalakshmi A
      Created Date: 21 March 2011
      Description:This function returns the batch size of update templates.CR#967107*/
    public Integer getBatchSizeCustomSetting()
    {
        return batch_size;
    }
    
    public EB_AkaMailer__c mailer{get;set;}
    
    /*Author: Jayalakshmi A
      Created Date: 21 March 2011
      Description: This function returns the mailer record.CR#967107*/
    public EB_AkaMailer__c getMailerRecord()
    {
        /*Mailer Id is passed as a url parameter*/
        String strMailer_Id = ApexPages.currentPage().getParameters().get('id');
        mailer = [select EB_OperationStatus__c,EB_CountToAddresses__c,EB_OperationProcessedCount__c from EB_AkaMailer__c where Id = :strMailer_Id];
        return mailer;
    }
    
    /*Author: Jayalakshmi A
      Created Date: 21 March 2011
      Description: This function returns the appropriate icon corresponding to the progress of update templates.CR#967107*/
    public String getImage()
    {   
        /*retrive the image id from hirarchical custom setting*/
                    
        EBCS_CNProgressImages__c inProcess = EBCS_CNProgressImages__c.getOrgDefaults();
        String inProcessImage = inProcess.InProcess__c;
        
        EBCS_CNProgressImages__c processed = EBCS_CNProgressImages__c.getOrgDefaults();
        String processedImage = processed.Processed2__c;
        
        /*Organization Id is passed as a url parameter.*/
        String strOrganizationId = ApexPages.currentPage().getParameters().get('OrganizationId');
        
        String url = EB_UtilMailer.getUrl();
        
        if(status!='Completed')
        {
            return url+'servlet/servlet.ImageServer?id='+inProcessImage+'&oid='+strOrganizationId;
        }
        else if(status == 'Completed')
        {
            return url+'servlet/servlet.ImageServer?id='+processedImage+'&oid='+strOrganizationId;
        }
        return url+'servlet/servlet.ImageServer?id='+inProcessImage+'&oid='+strOrganizationId;
    }
    
    /*Author: Jayalakshmi A
      Created Date: 21 March 2011
      Description: This function returns the link which takes the user back to the Mailer. getRenderMailerLink() renders this link once all the templates have been updated.CR#967107*/
    public String getMailerLink()
    {
        if(MailerLink == '' || MailerLink == null)
            return null;
        else
            return MailerLink;
    }
    
    /*Author: Jayalakshmi A
      Created Date: 21 March 2011
      Description: This function renders the 'Finish' link which will take the user back to the mailer when all the templates are updated. CR#967107*/
    public Boolean getRenderMailerLink()
    {
        if(status == 'Completed')
        {
            return true;
        }
        else
            return false;
    }
    
    /*Author: Jayalakshmi A
      Created Date: 21 March 2011
      Description: This function renderes the warning message on the VF Page when the templates updation is in progress.CR#967107*/
    public Boolean getRenderWarningText()
    {
        if(status == 'Completed')
            return false;
        else
            return true;
    }
    
    /*Author: Jayalakshmi A
      Created Date: 21 March 2011
      Description: This function returns the appropriate status message after Update Templates is completed. This message is rendered
      on the visualforce page based on the value returned by getRenderWarningText() CR#967107*/
    public String getStatusMessage()
    {
        if(status =='Completed')
        {
                return ' Update Template operation has been successfully completed. Please click on the link to navigate to the Mailer.';       
        }
        else
        {
            return '';
        }
        return '';
    }
    
    //End of changes for CR#967107
               //TODO: CR Info
     //CR 1766810 CNotify: Q32012 Clone Fix copying new default fields such as Si#, Impacted Region, Impacted Product, etc at Mailer
     //Vineet
     public EB_Token__c newtoken = new EB_Token__c();
     /*Author: Vineet S
      Created Date: 27 june 2012
      Description: This function returns the Page Parameters CR 1766810*/
      
    public EB_Token__c getNewtoken() { 
        EB_AkaMailer__c mailerc = getMailerFromQueryParameter();
        try
        {
        newtoken.EB_TokenEmailTemplate__c = mailerc.Email_Template__c;
        
        newtoken.EB_TokenSINumber__c = mailerc.EB_SINumber__c;
        newtoken.EB_TokenAdditionalReason__c = mailerc.EB_AdditionalIssueDescription__c;
        newtoken.EB_TokenImpactedProduct__c = mailerc.EB_ImpactedAkamaiProduct__c;
        newtoken.EB_TokenImpactedRegion__c = mailerc.EB_ImpactedRegion__c;
        newtoken.EB_TokenEndDate__c = mailerc.EB_IssueEndDateTime__c;
        newtoken.EB_TokenIssueReason__c = mailerc.EB_IssueReason__c;
        newtoken.EB_TokenStartDate__c = mailerc.EB_IssueStartDateTime__c;
        }
        catch(Exception e)
        {
                 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
        }
        return newtoken ;
    }
      /*Author: Vineet S
      Created Date: 27 june 2012
      Description: This function Mailer Object and also sets a few private variables CR 1766810*/
    public EB_AkaMailer__c  getMailerFromQueryParameter()
    {
        try
        {
           strMailerId = ApexPages.currentPage().getParameters().get('mailer_Id');
           for (AggregateResult ar : [SELECT sum(EB_TotalContacts__c)  from EB_AkamAccount__c where EB_AkaMailer__c = :strMailerId])  {
            totalContactInMailers = ar.get('expr0');
            }
            
           return [select  Email_Template__c,EB_SINumber__c ,EB_AdditionalIssueDescription__c,EB_ImpactedAkamaiProduct__c,EB_ImpactedRegion__c,EB_IssueEndDateTime__c,EB_IssueReason__c,EB_IssueStartDateTime__c from EB_AkaMailer__c where Id = :ApexPages.currentPage().getParameters().get('mailer_Id')][0];
        }
        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
            
            return null;
        }
    }
    //Start of changes CR-1799662 By: Shardul
    //Added three methods to render buttons on VFP page depending on type of cloning chosen by user.
    
    public Boolean getRenderdeepClone()
    {
       cloneType = ApexPages.currentPage().getParameters().get('cloneType');
        if(cloneType == 'deepClone')
        {
            return true;
        }
        
        return false;
    }
   public Boolean getRendercloneFailedRecords()
    {
        cloneType = ApexPages.currentPage().getParameters().get('cloneType');
        if(cloneType == 'cloneFailedRecords')
        {
            return true;
        }
        
        return false;
    }
    public Boolean getRendercloneProcessedRecords()
    {
        cloneType = ApexPages.currentPage().getParameters().get('cloneType');
        if(cloneType == 'cloneProcessedRecords')
        {
            return true;
        }
        
        return false;
    }
   //End of changes CR-1799662 
   
   
    //Start of changes by ssawhney for CR 2499348
    /*Author: Sonia Sawhney
      Created Date: 14 April 2014
      Description: This function validate if customer-notifications@akamai.com is marked as bad.CR#2499348*/
    webservice static string ValidateContactEmail()
    {
        string error;
        
        //Validate the contact email id
        EBCS_Application__c customSetting = EBCS_Application__c.getInstance('InternalContactId');
        Contact c = [Select EmailBouncedReason, Email from Contact where Id = :customSetting.Value__c];
        string emailBounce = c.EmailBouncedReason;
        if(emailBounce != null && emailBounce != '')
        {   
            // CR 3302521
            error= c.Email + ' is marked as bad. Please update the email bounce information on the contact for the same and retry.';
        }
        return error;
    }
    //End of changes CR 2499348
}