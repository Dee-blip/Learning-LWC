public with sharing class EB_CtrlChatterNotfication {

    public Boolean getRenderFinish() {
        return renderFinish;
    }


/*
Created : 11/29/2011
Author: Sharath
Description: Created for CR 1367210 - Chatter notification for internal account teams

*/

transient List<EB_AkaMContact__c> massMailerContacts = new List <EB_AkaMContact__c>();
transient List<EB_AkaMAccount__c> singleMailerAccounts = new List<EB_AkaMAccount__c>(); 
public String mailerName { get;set;}
public String siNumber {get;set;}
transient Set<EB_AkaMContact__c> massMailerContactsNotNull = new Set <EB_AkaMContact__c>();
public static Set<EB_AkaMAccount__c> singleMailerAccountsNotNull = new Set<EB_AkaMAccount__c>(); 
Set<String> uniqueAccountList = new Set<String> ();
public String mailerId;
EB_AkaMailer__c mailer;
Boolean PageLoadFirstTime = True;
Boolean renderFinish=false;
public EB_CtrlChatterNotfication(){      
      mailerId = Apexpages.currentpage().getparameters().get('id');
      try{
      mailer = [select Id,EB_SINumber__c,Name from EB_AkaMailer__c where Id = :mailerId];
      mailerName = mailer.Name;
      siNumber = mailer.EB_SINumber__c.format();
      }
      catch(Exception e){
        system.debug('Invalid mailer Id');
      }
}

public PageReference sendChatterNotification()
{
    EB_AkaMailer__c mailer = [select Id,EB_Type__c,EB_SINumber__c from EB_AkaMailer__c where Id=:mailerId];
    if(PageLoadFirstTime)
    {
        List<FeedItem> ChatterList = new List<FeedItem>();
        try{
            
            /* get unique accounts for single mail*/
            
            
            if(mailer.EB_Type__c == 'Single Email'){
                    singleMailerAccounts = [select EB_Account__c,EB_Account__r.name,EB_Account__r.AKAM_Account_ID__c,EB_SINumber__c from EB_AkaMAccount__c where EB_AkaMailer__c = :mailerId];
                    singleMailerAccountsNotNull = new Set<EB_AkaMAccount__c>(); 
                    for(EB_AkaMAccount__c acc :singleMailerAccounts){
                        uniqueAccountList.add(acc.EB_Account__c);
                        singleMailerAccountsNotNull.add(acc);
                    }                    
            }
            /*get unique accounts for mass mail. More than 1 contact can belong to same account, so using a 'SET' instead of a 'List' to remove duplicates*/
            else{
                    massMailerContacts = [select EB_ImpactedAccountIds__c from EB_AkaMContact__c where EB_AkaMAccount__r.EB_AkaMailer__r.Id = :mailer.Id];
                    massMailerContactsNotNull = new Set <EB_AkaMContact__c>();
                    for(EB_AkaMContact__c mailerContact :massMailerContacts){
                         List<String> accountIds ;
                         if(mailerContact.EB_ImpactedAccountIds__c != null){
                             accountIds  = mailerContact.EB_ImpactedAccountIds__c.split('\n');
                             uniqueAccountList.addAll(accountIds);
                             massMailerContactsNotNull.add(mailerContact);
                         }
                    }
            }
            
           if(mailer.EB_Type__c == 'Single Email') //For single mail call twice, once for EB_TechSupportTeams__c and once for AccountTeamMembers
            {  if(uniqueAccountList.size()==0)
                {
                                EB_MailerException__c mailerException = new EB_MailerException__c();
                                mailerException.EB_Mailer__c = mailerId;
                                mailerException.Exception_Message__c ='uniqueAccountList is empty so did not call Batched Process';
                                mailerException.EB_Type__c = 'Exception';
                                insert mailerException;
                
                }
                else
                
                {
                /*//Call for AccountTeamMember
                EB_BatchableNotification AccountTeamMemberinternalbatch = new EB_BatchableNotification(mailerId,uniqueAccountList,'AccountTeamMember',singleMailerAccountsNotNull);
                //Id userRoleId = UserInfo.getUserRoleId();
                //user current_user=[Select id,Email from user where id= :userRoleId][0];
                AccountTeamMemberinternalbatch.email='eae-ops@akamai.com';
                ID batchprocessidAccountTeamMember = Database.executeBatch(AccountTeamMemberinternalbatch,20);
            */
                 CallForSinglemailAccountteam();
                //Call for EB_TechSupportTeams__c
                if(Test.isrunningtest()==False)
                {
                /*EB_BatchableNotification TechSupportTeamsinternalbatch = new EB_BatchableNotification(mailerId,uniqueAccountList,'EB_TechSupportTeams__c',singleMailerAccountsNotNull);
                TechSupportTeamsinternalbatch.email='eae-ops@akamai.com';
                ID batchprocessidTechSupportTeams = Database.executeBatch(TechSupportTeamsinternalbatch,1);
                */
                CallForSinglemailTechteam();
                }
                }
            
            
            }
            else if(mailer.EB_Type__c == 'Mass Email') //For mass mail call twice, once for EB_TechSupportTeams__c and once for AccountTeamMembers
            {
                if(uniqueAccountList.size()==0)
                {
                                EB_MailerException__c mailerException = new EB_MailerException__c();
                                mailerException.EB_Mailer__c = mailerId;
                                mailerException.Exception_Message__c ='uniqueAccountList is empty so did not call Batched Process';
                                mailerException.EB_Type__c = 'Exception';
                                insert mailerException;
                
                }
                else
                {
                /*EB_BatchableNotification AccountTeamMemberinternalbatch = new EB_BatchableNotification(mailerId,uniqueAccountList,'AccountTeamMember');
                //Id userRoleId = UserInfo.getUserRoleId();
                //user current_user=[Select id,Email from user where id= :userRoleId][0];
                AccountTeamMemberinternalbatch.email='eae-ops@akamai.com';
                ID batchprocessidAccountTeamMember = Database.executeBatch(AccountTeamMemberinternalbatch,20);*/
                CallForMassmailAccountteam();
            
                //Call for EB_TechSupportTeams__c
               if(Test.isrunningtest()==False)
                {
                /*EB_BatchableNotification TechSupportTeamsinternalbatch = new EB_BatchableNotification(mailerId,uniqueAccountList,'EB_TechSupportTeams__c');
                TechSupportTeamsinternalbatch.email='eae-ops@akamai.com';
                ID batchprocessidTechSupportTeams = Database.executeBatch(TechSupportTeamsinternalbatch,20);*/
                CallForMassmailTechteam();
                }
                }
            
            }
            
            /* create a chatter feed item for each account in the mailer*/
            if(uniqueAccountList.size()>0){
                     //Start of changes by Samir for CR 2019889:CNotify: Chatter email sent to account teams should point to service incident record on Remedyforce.
					 Eb_SI_Url__c URL_String=Eb_SI_Url__c.getInstance('URL');
                      Decimal comp=mailer.EB_SINumber__c;
                      Id IncidentId;
                      try
                      {
                      IncidentId=[select Id from BMCServiceDesk__Incident__c where EB_SI__c = :comp][0].Id;
                      }
                      catch(exception e)
                      {
                      IncidentId=NULL;
                      }
                      String SI_URL=URL_String.SI_URL__c;
                    for(String accountId : uniqueAccountList){
                            FeedItem post = new FeedItem();
                            post.ParentId = accountId;
                            //post.Title = 'SI Notification - Internal';
                            post.Body = 'An email notification was sent out to 24x7 contacts associated with this customer account related to  #SI-'+  mailer.EB_SINumber__c + ' . Please contact the GSS Incident Manager associated with the Service Incident to get more details.';
                            post.LinkUrl = SI_URL+'/'+ IncidentId;
                            ChatterList.add(post);                            
                    }
					//END of changes by Samir for CR 2019889
                    /*
                    Author: Vineet
                    CR: 1685596
                    Description: Code To Send Mails to Account Team Members informing them about the incident.                    
                    */                     
                    //CR 1685596 CNotify: 2012 Jun-2012 Enhance the Account Team Chatter Notification to include the functionality to send mails
                    //List<User> users = [select Email,AccountId from User where Id IN  (select UserId from AccountTeamMember where AccountId IN :uniqueAccountList) and Email != '' and Email != null];
                   
                    
                    //End CR 1685596
                    database.insert(ChatterList);
            }
        }
        catch(Exception e){
          //ApexPages.Message myMsg;
          //myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage());
          //ApexPages.addMessage(myMsg);
          //system.assertEquals(e.getMessage(),null);  
        }
        renderFinish=true;
        PageLoadFirstTime =false;   
        return null;
        }
        //samir changed to call the class EB_BatchableNotification to send notifications to internal team members
            
            
        return null;
}

/* redirect back to the mailer page*/


public void CallForSinglemailAccountteam()
{
EB_BatchableNotification AccountTeamMemberinternalbatch = new EB_BatchableNotification(mailerId,uniqueAccountList,'AccountTeamMember',singleMailerAccountsNotNull);
AccountTeamMemberinternalbatch.email='sajha@akamai.com';
ID batchprocessidAccountTeamMember = Database.executeBatch(AccountTeamMemberinternalbatch,20);
}
public void CallForSinglemailTechteam()
{
EB_BatchableNotification TechSupportTeamsinternalbatch = new EB_BatchableNotification(mailerId,uniqueAccountList,'EB_TechSupportTeams__c',singleMailerAccountsNotNull);
TechSupportTeamsinternalbatch.email='sajha@akamai.com';
ID batchprocessidTechSupportTeams = Database.executeBatch(TechSupportTeamsinternalbatch,20);
}
public void CallForMassmailAccountteam()
{
EB_BatchableNotification AccountTeamMemberinternalbatch = new EB_BatchableNotification(mailerId,uniqueAccountList,'AccountTeamMember');
                //Id userRoleId = UserInfo.getUserRoleId();
                //user current_user=[Select id,Email from user where id= :userRoleId][0];
                AccountTeamMemberinternalbatch.email='sajha@akamai.com';
                ID batchprocessidAccountTeamMember = Database.executeBatch(AccountTeamMemberinternalbatch,20);
}
public void CallForMassmailTechteam()
{
EB_BatchableNotification TechSupportTeamsinternalbatch = new EB_BatchableNotification(mailerId,uniqueAccountList,'EB_TechSupportTeams__c');
TechSupportTeamsinternalbatch.email='sajha@akamai.com';
ID batchprocessidTechSupportTeams = Database.executeBatch(TechSupportTeamsinternalbatch,20);

}


public PageReference redirectToMailer(){
    String mailerId = Apexpages.currentpage().getparameters().get('id');
    if(mailerId!= null){
        PageReference pg = new PageReference('/'+ mailerId);
        return pg;
    }
    return null;
}
}