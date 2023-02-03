/*
Author:Samir Jha
Date:12/12/12
This class implements batchable sending of mails to Account Team Members and Members of Tech-Support Teams.
*/
global class EB_BatchableNotification implements Database.Batchable<sObject>
{
    Global Set<EB_AkaMAccount__c> singleMailerAccountsNotNull; 
    List<EB_AkaMAccount__c> singleMailerAccountsNotNullList;
    private String Query;
    global final String mailerId;
    String type;
    global String email;
    EB_AkaMailer__c mailer;
    list<String> uniqueAccount;
    List<String> RoleList = new List<String>();
    global Set<String> uniqueAccountList;
    //Constructor with pararmeters for single mails.
    global EB_BatchableNotification(String Mailer_Id,Set<String> uniqueAccountList_Param,String Object_type,Set<EB_AkaMAccount__c> singleMailerAccountsNotNull_param )
    { 
        mailerId=Mailer_Id;
        uniqueAccountList=uniqueAccountList_Param.clone();
        uniqueAccount=new list<String>(uniqueAccountList_Param);
        singleMailerAccountsNotNullList=new list<EB_AkaMAccount__c>(singleMailerAccountsNotNull_param );
        type=Object_type;
        singleMailerAccountsNotNull=singleMailerAccountsNotNull_param.clone();
        mailer = [select Id,EB_Type__c,EB_SINumber__c,Name from EB_AkaMailer__c where Id = :Mailer_Id];
    }
    //Constructor with pararmeters for mass mails.
    global EB_BatchableNotification(String Mailer_Id,Set<String> uniqueAccountList_Param,String Object_type)
    {
          
        try
 {
        if(((uniqueAccountList_Param).isEmpty())==True)
        {
            EB_MailerException__c mailerException = new EB_MailerException__c();
            mailerException.EB_Mailer__c = mailerId;
            mailerException.Exception_Message__c ='Account list empty' + 'Mass Mail';
            mailerException.EB_Type__c = 'Exception';
            insert mailerException;
        
        
        }
        else
        {
        uniqueAccount=new list<String>(uniqueAccountList_Param);
        mailerId=Mailer_Id;
        mailer = [select Id,EB_Type__c,EB_SINumber__c,Name from EB_AkaMailer__c where Id = :Mailer_Id];
        uniqueAccountList=uniqueAccountList_Param.clone();
        type=Object_type;
        }
    }   
catch(exception e)
        {
            EB_MailerException__c mailerException = new EB_MailerException__c();
            mailerException.EB_Mailer__c = mailerId;
            mailerException.Exception_Message__c = e.getMessage() + 'Mass Mail';
            mailerException.EB_Type__c = 'Exception';
            insert mailerException;
          
        }       
    }
    /*
    Author:Samir Jha
    Date:12/12/12
    This method returns the records fetched using the Query in Batches. 
    */
    global Database.QueryLocator start(Database.BatchableContext BC)  
    {  
       if(type=='AccountTeamMember')
       Query='select User.ContactId,User.Email,Account.Name,Account.Id,Account.AKAM_Account_ID__c,Id,TeamMemberRole from AccountTeamMember where AccountId IN :uniqueAccountList and User.Email != \'\' and User.Email != null  order by AccountId';
       else if(type=='EB_TechSupportTeams__c')
       {
       //Sajha: 2581815 :Changed Query to exclude all other roles other than Primary or Secondary Account Teams
       Query='select EB_Email__c,EB_Account_Id__r.Name,Eb_Account_Id__c,AccountId__c,EB_Account_Id__r.AKAM_Account_ID__c,Id,EB_Tech_Support_Role__c from EB_TechSupportTeams__c where EB_IsDeleted__c != TRUE and EB_NotifyMember__c = TRUE and Eb_Account_Id__c IN :uniqueAccount and EB_Email__c != \'\' and EB_Email__c != null order by EB_Account_Id__c';
       //List<EB_TechSupportTeams__c> Query1=new List<EB_TechSupportTeams__c>([select EB_Email__c,EB_Account_Id__r.Name,Eb_Account_Id__c,AccountId__c,EB_Account_Id__r.AKAM_Account_ID__c,Id,EB_Tech_Support_Role__c from EB_TechSupportTeams__c where EB_IsDeleted__c != TRUE and EB_Tech_Support_Role__c.contains('Technical') and Eb_Account_Id__c IN :uniqueAccount and EB_Email__c != \'\' and EB_Email__c != null order by EB_Account_Id__c]);
       //system.assertEquals(Query1,Null);
       }
       return Database.getQueryLocator(query);
       
    }  
    /*
    Author:Samir Jha
    Date:12/12/12
    This method sends mails in Batches to the Account Teams and Tech Support Teams..    
    */
    global void execute(Database.BatchableContext BC,list<sObject> scope)
    { 
    
        if(type=='AccountTeamMember')
        {
             try
                {   
                List<AccountTeamMember> members=scope;
                Messaging.Sendemailresult[] result ;
                    if(mailer.EB_Type__c == 'Single Email')
                    {   
                        Map<EB_AkaMAccount__c,List<String>> MailsToBeSent = new Map<EB_AkaMAccount__c,List<String>>();
                        Map<ID,EB_AkaMAccount__c> tempMap = new Map<ID,EB_AkaMAccount__c>();
                        
                        for(EB_AkaMAccount__c acc:singleMailerAccountsNotNull)
                        {
                            
                            tempMap.put(acc.EB_Account__c,acc);
                        }
                        for(AccountTeamMember member:members)
                        {
                            if(member.TeamMemberRole != 'CMG - Analyst')
                            {
                                if((MailsToBeSent.get(tempMap.get(member.Account.Id)) ==null))
                                {
                                    MailsToBeSent.put(tempMap.get(member.Account.Id),new List<String>()); 
                                }
                                MailsToBeSent.get(tempMap.get(member.Account.Id)).add(member.User.Email);
                                                          
                            }
                        }
                        EB_UtilEmailNotification.sendMailToAccountTeamMembersForSingleMail(MailsToBeSent);  
                    }
                   else if(mailer.EB_Type__c == 'Mass Email')
                    {
                        Map<Account,List<String>> MassMailsToBeSent = new Map<Account,List<String>>();
                        for(AccountTeamMember member:members)
                        {
                            if(member.TeamMemberRole != 'CMG - Analyst')
                            {
                                if((MassMailsToBeSent.get(member.Account))== null)
                                {   
                                    MassMailsToBeSent.put(member.Account,new List<String>());                                                       
                                }
                                MassMailsToBeSent.get(member.Account).add(member.User.Email);         
                            }
                        
                        }
                    EB_UtilEmailNotification.sendMailToAccountTeamMembersForMassMail(MassMailsToBeSent,mailer);    
                    }
             }
             catch(Exception e1)
                        {
                                EB_MailerException__c mailerException = new EB_MailerException__c();
                                mailerException.EB_Mailer__c = mailerId;
                                mailerException.Exception_Message__c = e1.getMessage() + ' Account Team ';
                                mailerException.EB_Type__c = 'Exception';
                                insert mailerException;
                                 
                            
                        }
        }
        else if(type=='EB_TechSupportTeams__c')
        {
             List<EB_TechSupportTeams__c> Techmembers=scope;
             if(mailer.EB_Type__c == 'Single Email')
             {          
                           try
                        {                        
                            Map<EB_AkaMAccount__c,List<String>> MailsToBeSent = new Map<EB_AkaMAccount__c,List<String>>();
                            Map<ID,EB_AkaMAccount__c> tempMap = new Map<ID,EB_AkaMAccount__c>();
                            
                            for(EB_AkaMAccount__c acc:singleMailerAccountsNotNullList)
                            { 
                              
                                tempMap.put(acc.EB_Account__r.id,acc);
                            }
                            for(EB_TechSupportTeams__c Techmember:Techmembers)
                            {
                            if((MailsToBeSent.get(tempMap.get(Techmember.EB_Account_Id__c))) ==null)
                                    {
                                        MailsToBeSent.put(tempMap.get(Techmember.EB_Account_Id__c),new List<String>()); 
                                    }
                                    MailsToBeSent.get(tempMap.get(Techmember.EB_Account_Id__c)).add(Techmember.EB_Email__c);
                            
                            }
                            
                            EB_UtilEmailNotification.sendMailToAccountTeamMembersForSingleMail(MailsToBeSent);
            
                        }
                        catch(Exception e1)
                        {
                                EB_MailerException__c mailerException = new EB_MailerException__c();
                                mailerException.EB_Mailer__c = mailerId;
                                mailerException.Exception_Message__c = e1.getMessage() + 'EB_TechSupport';
                                mailerException.EB_Type__c = 'Exception';
                                insert mailerException;
                                 
                                
                        }
             }
             else if(mailer.EB_Type__c == 'Mass Email')
             {     try{
             
                        Map<Account,List<String>> MassMailsToBeSent = new Map<Account,List<String>>();
                        Account temp;
                        for(EB_TechSupportTeams__c Techmember:Techmembers)
                            {
                              temp = [select id from account where id= :Techmember.EB_Account_Id__c][0];
                              if((MassMailsToBeSent.get(temp))== null)
                                {
                                 MassMailsToBeSent.put(temp,new List<String>());
                                
                                }
                            MassMailsToBeSent.get(temp).add(Techmember.EB_Email__c);
                            
                            }
                EB_UtilEmailNotification.sendMailToAccountTeamMembersForMassMail(MassMailsToBeSent,mailer);
                        }
                        catch(Exception e1)
                        {
                                EB_MailerException__c mailerException = new EB_MailerException__c();
                                mailerException.EB_Mailer__c = mailerId;
                                mailerException.Exception_Message__c = e1.getMessage() + 'EB_TechSupport';
                                mailerException.EB_Type__c = 'Exception';
                                insert mailerException;
                                 
                               
                        }
             
                }
        }

    }
    
    /*
    Author:Samir Jha
    Date:12/12/12
    This method sends mail to the submitter of the batch job about the success or failure of the batch process. 
    */
    global void finish(Database.BatchableContext BC)
    {
       Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
       // obtain status of job.
        AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed,TotalJobItems, CreatedBy.Email from AsyncApexJob where Id = :BC.getJobId()];
        if(a.Status=='Completed' && a.NumberOfErrors==0)
        {
            // if job has been successful,notify the user that account team notification is complete
            String[] toAddresses = new String[] {a.CreatedBy.Email};
            mail.setToAddresses(toAddresses);
            mail.setSubject('Notify account teams successful');
            mail.setPlainTextBody ('The Notify Account teams batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
        else
        {
        // Some error has occured.Send an email to the Apex job's submitter notifying of job failure.
           
            String[] toAddresses = new String[] {a.CreatedBy.Email};
            mail.setToAddresses(toAddresses);
            mail.setSubject('Notify account teams Failed' );
            mail.setPlainTextBody ('The Notify Account teams batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
       
        
       
    
    }
    
    
    
}