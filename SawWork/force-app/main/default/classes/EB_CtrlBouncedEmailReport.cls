/*
Author: Jayalakshmi A
Description: This is a custom visualforce report for identifying the bounced Email Ids for Mass Emails. CR 1414090.
Created Date: 12/1/2011
*/

public class EB_CtrlBouncedEmailReport 
{
    public String mailerId{get;set;}
    List<String> emailIds = new List<String>();
    Set<String> toListIds = new Set<String>();
    List<String> tempToListIds = new List<String>();
    public List<EB_AkaMContact__c> bouncedMailerContacts = new List<EB_AkaMContact__c>();
    Map<String,Contact> mailerContactIdContactRecord = new Map<String,Contact>();
    Map<String,EB_AkaMContact__c> EmailIdMailerCon = new Map<String,EB_AkaMContact__c>();
    List<BouncedDetailsInnerClass> mergedMailerDetails = new List<BouncedDetailsInnerClass>();     
    Map<String,Contact> emailIdContact = new Map<String,Contact>();
    Map<Contact,EB_AkaMContact__c> contactMailerContact = new Map<Contact,EB_AkaMContact__c>();
    List<String> bouncedEmailIds = new List<String>();
    public String mailerName{get;set;}
    
    /*Contructor which initializes the members of BouncedDetailsInnerClass*/
    public EB_CtrlBouncedEmailReport()
    {
        try
        {
            mailerId = ApexPages.currentPage().getParameters().get('mailerId');
            mailerName = [select Name from EB_AkaMailer__c where Id=:mailerId].Name;
           
            /*Get all the Mailer Contacts for that particular Mailer.
            Initialize a list of ToList Ids, prepare a map of (Email Id,Mailer Contact) - Map1.*/
            for(EB_AkaMContact__c mailerCon:[select EB_ToList__c,Name, EB_Email_Id__c,EB_AkaMAccount__r.Name,EB_AkaMAccount__r.EB_AkaMailer__r.Name, EB_AkaMAccount__r.Id, Id from EB_AkaMContact__c where EB_AkaMAccount__r.EB_AkaMailer__r.Id = :mailerId ])
            {
                emailIds.add(mailerCon.EB_Email_Id__c);
                if(mailerCon.EB_ToList__c != null || mailerCon.EB_ToList__c != '')
                {
                    toListIds.addAll(mailerCon.EB_ToList__c.split('\n'));
                    tempToListIds = mailerCon.EB_ToList__c.split('\n');
                }    
                
                for(String emailId:tempToListIds)
                {
                    EmailIdMailerCon.put(emailId,mailerCon);   
                }           
            } 
            
            /*Get all the bounced contacts with the email ids in the ToList ids, prepare a map of: (Email Id,Contact) - Map2 and 
            (Contact, Mailer Contact) - Map3 - Using Map1 and initialize a list of bounced email ids*/
            for(Contact contact:[select Email, EmailBouncedReason, Id, Name, Account.Name,Account.Id from Contact where ((Email in :emailIds) or (Email in :toListIds)) ])
            {
                if(contact.EmailBouncedReason != '' && contact.EmailBouncedReason != null)
                {
                    bouncedEmailIds.add(contact.Email);    
                    emailIdContact.put(contact.Email,contact);
                    contactMailerContact.put(contact,EmailIdMailerCon.get(contact.Email));          
                }
            }
            List<String> toListEmailIds = new List<String>();
            if(bouncedEmailIds.size()>0)
            {  
                Integer i = 0;
                boolean bouncedFlag = false;
                String concatBouncedEmails;
                /*Now we have a list of bounced email ids. Using the email id get the Contact details from Map2. Using the Contact get the Mailer Contact details from Map3.
                Initialize the TempClass members.*/     
                for(String emailId:bouncedEmailIds)
                {
                    BouncedDetailsInnerClass mailerContactInfo = new BouncedDetailsInnerClass();
                    Contact bouncedContact = emailIdContact.get(emailId);
                    
                    EB_AkaMContact__c mailerContact= contactMailerContact.get(bouncedContact);
                    mailerContactInfo.mailerAccountId = mailerContact.EB_AkaMAccount__r.Id;
                    mailerContactInfo.mailerAccountName = mailerContact.EB_AkaMAccount__r.Name;
                    mailerContactInfo.mailerName = mailerContact.EB_AkaMAccount__r.EB_AkaMailer__r.Name;
                    mailerContactInfo.mailerContactId = mailerContact.Id;
                    mailerContactInfo.mailerContactName = mailerContact.Name;
                    mailerContactInfo.toList = mailerContact.EB_ToList__c;
                
                    mailerContactInfo.contactId = bouncedContact.Id;
                    mailerContactInfo.contactName = bouncedContact.Name;
                    mailerContactInfo.bouncedEmailId = bouncedContact.Email;
                    mailerContactInfo.accountName = bouncedContact.Account.Name;
                    mailerContactInfo.accountId = bouncedContact.Account.Id;
                    mailerContactInfo.emailBouncedReason = bouncedContact.EmailBouncedReason;
                    mailerContactInfo.mailerId = mailerContact.EB_AkaMAccount__r.EB_AkaMailer__r.Id;             
                    mergedMailerDetails.add(mailerContactInfo); 
                }               
            }
        }
                         
        catch(Exception e)
        {
            ApexPages.Message myMsg1;
            myMsg1 = new ApexPages.Message(ApexPages.Severity.FATAL,'An error occured: '+e.getMessage());
            ApexPages.addMessage(myMsg1);
            /*EB_MailerException__c exception1 = new EB_MailerException__c();
            exception1.Exception_Message__c = e.getMessage();
            exception1.EB_Mailer__c = mailerId;
            exception1.EB_Type__c = 'Exception';
            insert exception1;*/
            
        }
    }
    
    /*
    descripion: This function returns a list of bounced email details CR 1414090
    created by: Jayalakshmi A
    Created Date: 12/1/2011
    */
    public List<BouncedDetailsInnerClass> getDetails()
    {       
        return mergedMailerDetails;
    }
    
    /*
    descripion: This function returns a reference to the root url.
    created by: Jayalakshmi A
    Created Date: 12/1/2011
    */
    public PageReference getRedirect()
    {
        PageReference mailerContactPage = new PageReference('/');
        return mailerContactPage;
    }
    
    /*This is an inner class used for displaying both the Mailer Contact and Contact details in a visualforce page.*/
    public class BouncedDetailsInnerClass
    {
        public String mailerName{get;set;}
        public String mailerAccountId{get;set;}
        public String mailerAccountName{get;set;}
        public String mailerContactId{get;set;}
        public String mailerContactName{get;set;}
        public String toList{get;set;}
        public String emailBouncedReason{get;set;}
        public String accountName{get;set;}
        public String contactId{get;set;}
        public String contactName{get;set;}
        public String bouncedEmailId{get;set;}
        public String mailerId{get;set;}
        public String accountId{get;set;}
    } 
}