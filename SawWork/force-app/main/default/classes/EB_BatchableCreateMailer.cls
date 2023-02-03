/*
Author: Sharath
Version: 1.0
Created date: 09/16/2010
Description: CR-819957- Batchable child class for EB_BatchableMailerWizard. This class creates mailers of 'Single Mail' type in Batches
Modified: 
3/25/2011 CR 845804 CNotify: User should be able to pick the default Email Template during Mailer creation
4/21/2014 CR 2611929: Filter all Contacts that have Email Bounce set to true
*/

global class EB_BatchableCreateMailer extends EB_BatchableMailerWizard implements Database.Batchable<sObject>
{
    List<EB_AkaMAccount__c> insertAkamAccount = new List<EB_AkaMAccount__c>();
    List<String> akamAccountList = new List<String>();
    EB_AkaMAccount__c akamAccount;
    List<EB_AkaMContact__c> insertAkamContact = new List<EB_AkaMContact__c>();
    List<EB_SelectedAccounts__c> updateList = new List<EB_SelectedAccounts__c>();
    EB_AkaMContact__c akamContact;
    Map<String, String> objAccountAkamAccountMap = new Map<String, String>();
    EB_AkaMailer__c Mailer;
    String token;
    Boolean createMailerDirect;
    List<String>  allAccounts = new List<String>();
    List<String> allOmmitedAccounts = new List<String>();
    Map<String,List<String>> OmittedMap=new Map<String,List<String>>();
    string ommitedAccountsstring;
    String omittedmapstring='';
    list<String>ParentContractAccountNames=new list<String>();
    list<String> ConAccID=new list<String>();
    Map<Contact,Account> tempMap = new Map<Contact,Account>();
    /* 
    Author: Sharath
    Version: 1.0
    Created date: 09/16/2010
    Description: Contructor which calls the Parent class constructor for initialising the query
    */
    global EB_BatchableCreateMailer(String q,EB_AkaMailer__c Mailer,String token,Boolean createMailerDirect, List<String>  allAccounts,list<Account> ResellerAccountsOmitted )
    {
        
        super(q,allAccounts); 
        this.Mailer=Mailer;
        this.token=token;
        this.createMailerDirect=createMailerDirect;
        this.allAccounts=allAccounts;
        if(ResellerAccountsOmitted!=NULL)
        {
        for(Account a: ResellerAccountsOmitted)
        {
         this.allOmmitedAccounts.add(a.Name);
         this.ommitedAccountsstring=this.ommitedAccountsstring+a.Name;
        }
        }
        else
        {
        this.allOmmitedAccounts.add('No reseller Accounts found');
        
        }
        
    }
    
    /* 
    Author: Sharath
    Version: 1.0
    Created date: 09/16/2010
    Description: This method calls the Parent class start method. 
    */
    override global Database.QueryLocator start(Database.BatchableContext BC)
    {
        return super.start(BC);
    }
    
    /* 
    Author: Sharath
    Version: 1.0
    Created date: 09/16/2010
    Description: Contains the logic for creating mailer accounts & mailer contacts
    Modified : 3/25/2011
    CR 845804 CNotify: User should be able to pick the default Email Template during Mailer creation
        - If mailer has a default email template, populate the email template at the mailer account & mailer contact level too
    */
    override global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        String existingAccountId='';
        insertAkamAccount.clear();
        objAccountAkamAccountMap.clear();
        akamAccountList.clear();
        insertAkamContact.clear();
        updateList.clear();
        List<Contact> selectedContacts = new List<Contact>();
        List<EB_MailerException__c> bounceContacts = new List<EB_MailerException__c>();
        selectedContacts =scope;
        List<Account>CheckResellerAcc=new List<Account>();
        list<Merge_Contract_Header__c> resellerparentcontracts1= new List<Merge_Contract_Header__c>();
            list<Merge_Contract_Header__c> resellerchildcontracts1= new List<Merge_Contract_Header__c>();
            list<Account> ResellerAccounts1=new list<Account>();
            list<EB_ResellerContractId__c > ContractIdsCustomSettings1=new list<EB_ResellerContractId__c >();
            list<String> ResellerContractIds1=new list<String>();
            set<Merge_Contract_Header__c> resellerchildcontracts2= new set<Merge_Contract_Header__c>();
            String AccountNames='Not initialized by now';
            Account checkReseller;
            String AccName='No Reseller found';
            try
            {
            
            ContractIdsCustomSettings1= EB_ResellerContractId__c.getAll().values(); //[select Original_Contract_Id__c,Name from EB_ResellerContractId__c];
            String s;
            String s1;
            for (EB_ResellerContractId__c RCId: ContractIdsCustomSettings1)
            {
             s=RCId.Original_Contract_Id__c;
             ResellerContractIds1.add(s);
            }
            Date T2day2=Date.today();
            resellerparentcontracts1=[select Id,Account_Name__c from Merge_Contract_Header__c where Active__c=TRUE and Effective_End_Date__c>=:T2day2 and Name in :ResellerContractIds1];
            
            resellerchildcontracts1=[select Id,Account_Name__c from Merge_Contract_Header__c where Active__c=TRUE and Effective_End_Date__c>=:T2day2 and Parent_Contract__c in :resellerparentcontracts1];
            
            for(Merge_Contract_Header__c c:resellerparentcontracts1)
            {
             ParentContractAccountNames.add(c.Account_Name__c);
            
            } 
            ResellerAccounts1=[Select Id,Name from Account where Id in :ParentContractAccountNames];
            For(Account a:ResellerAccounts1)
            {
            AccountNames=AccountNames+a.Name+' ';
            }
            Boolean result1 =  resellerchildcontracts2.addAll([select Id,Account_Name__c,Account_Name__r.name,Parent_Contract__r.Account_Name__c,Parent_Contract__r.Account_Name__r.name from Merge_Contract_Header__c where Active__c=TRUE and Effective_End_Date__c>=:T2day2 and Parent_Contract__c in :resellerparentcontracts1 and Parent_Contract__r.Account_Name__c in :ResellerAccounts1 ]);

            integer count=0;
            Boolean Duplicate=False;
           For(Merge_Contract_Header__c c:resellerchildcontracts2)
           {
            //system.assertequals(1,0);    
            if(OmittedMap.containsKey(c.Parent_Contract__r.Account_Name__r.name) && ommitedAccountsstring.contains(c.Account_Name__r.Name))
            {
            for(string s3:OmittedMap.get(c.Parent_Contract__r.Account_Name__r.name))
            {
            if(s3.contains(c.Account_Name__r.name)==true)
            {
            Duplicate=True;
            }
            }
            if(Duplicate==False)
            {
            count++;
            OmittedMap.get(c.Parent_Contract__r.Account_Name__r.name).add(count+'. ');
            OmittedMap.get(c.Parent_Contract__r.Account_Name__r.name).add(c.Account_Name__r.name);
            OmittedMap.get(c.Parent_Contract__r.Account_Name__r.name).add('\n');
            }
            //OmittedMap.get(c.Parent_Contract__r.Account_Name__r.name).add('\n');
            
            }
            else if(ommitedAccountsstring.contains(c.Account_Name__r.Name))
            {
            count++;
            s1=count+'. ';
            List<String>s2=new List<String>();
            s2.add(s1);
            OmittedMap.put(c.Parent_Contract__r.Account_Name__r.name,new List<String>(s2));
            OmittedMap.get(c.Parent_Contract__r.Account_Name__r.name).add(c.Account_Name__r.name);
            OmittedMap.get(c.Parent_Contract__r.Account_Name__r.name).add('\n');
            //OmittedMap.get(c.Parent_Contract__r.Account_Name__r.name).add('\n');+ c.Account_Name__r.name;+'\n'
            }
           }
          }
          catch(exception e)
          {
          //system.assertEquals(e,null);
          /*Just Move on for now*/
              
          }
        
          for( Contact selectedContact: selectedContacts )
          {
          ConAccID.add(selectedContact.Account.Id);
          
          }
          
         CheckResellerAcc=[Select Id,Name from Account where Id in :ConAccID];
        
         for( Contact selectedContact: selectedContacts )
          {
            for(Account selectedAccount: CheckResellerAcc)
            {
                if(selectedContact.Account.Id == selectedAccount.Id)
                {
                    tempMap.put(selectedContact,selectedAccount);
                    break;
                }
            }
          }
          //system.assertEquals(tempMap,Null);
        for( Contact selectedContact: selectedContacts ){
        try
        {
        checkReseller=tempMap.get(selectedContact);
        AccName=checkReseller.Name;
        }
        catch(Exception e)
        {
        AccName='No Reseller found';
        
        }
        //system.assertEquals(AccountNames,AccName);
        //system.assertequals(String.valueOf(OmittedMap.get(selectedContact.Account.name)),null);
        if(AccountNames.contains(AccName)== False)
        {
            String account_Id=selectedContact.Account.Id;
            if(account_Id!=existingAccountId){ 
                // prevent duplicate mailer account from being created for the same account
                //This is a new Mailer Account, create one
                akamAccount = new EB_AkaMAccount__c();
                akamAccount.EB_Account__c = selectedContact.Account.Id;
                akamAccount.EB_AkaMailer__c = Mailer.Id;
                akamAccount.EB_Status__c = 'New';
                akamAccount.EB_EnableValidationRules__c=false;
                //akamAccount.Eb_AssociatedResellerAccounts__c = allOmmitedAccounts+' not found' ;
                //CR 845804 - default email template is populated at amiler level 
                if(Mailer.Email_Template__c != null){
                    akamAccount.Email_Template__c = Mailer.Email_Template__c;
                }
                insertAkamAccount.add(akamAccount);
                existingAccountId=account_Id;
            }
            }
            else
            {
            String account_Id=selectedContact.Account.Id;
            if(account_Id!=existingAccountId){ 
                // prevent duplicate mailer account from being created for the same account
                //This is a new Mailer Account, create one
                akamAccount = new EB_AkaMAccount__c();
                akamAccount.EB_Account__c = selectedContact.Account.Id;
                akamAccount.EB_AkaMailer__c = Mailer.Id;
                akamAccount.EB_Status__c = 'New';
                akamAccount.EB_EnableValidationRules__c=false;
                try{
                if(OmittedMap.get(selectedContact.Account.name)!= Null)
                {
                 for(String ac:OmittedMap.get(selectedContact.Account.name))
                 {
                 omittedmapstring=omittedmapstring+ac+' ';
                 }
            
                 akamAccount.Eb_AssociatedResellerAccounts__c =omittedmapstring;
                 //String.valueOf(OmittedMap.get(selectedContact.Account.name));
                 //String.valueOf(OmittedMap.get(selectedContact.Account.name));
                }
                }
                catch(exception e)
                {
                 //system.assertEquals(e,null);
                //do nothing for now.
                }
                //CR 845804 - default email template is populated at amiler level 
                if(Mailer.Email_Template__c != null){
                    akamAccount.Email_Template__c = Mailer.Email_Template__c;
                }
                insertAkamAccount.add(akamAccount);
                existingAccountId=account_Id;
            }
            }
        }
        insert insertAkamAccount;

        // create a map of account Id to AkamAccount Id
        for (EB_AkamAccount__c objAkamAcc : insertAkamAccount){
            objAccountAkamAccountMap.put(objAkamAcc.EB_Account__c, objAkamAcc.Id);
            akamAccountList.add(objAkamAcc.EB_Account__c);
        }
            
        for( Contact selectedContact: selectedContacts){
            // Start of changes by ssawhney for CR 2611929: Filter all Contacts that have Email Bounce set to true
            //if email bounce is set to true create exception 
            if(selectedContact.EmailBouncedReason != null && selectedContact.EmailBouncedReason != ''){
                EB_MailerException__c excp = new EB_MailerException__c();
                excp.Exception_Message__c='Email Id Bounce checked for Contact: ' + selectedContact.firstname + ' ' + selectedContact.lastname + ' of Account: ' + selectedContact.Account.Name + ' Id: ' + selectedContact.Id;
                excp.EB_Mailer__c=Mailer.Id;
                excp.EB_Type__c = 'Warning';
                bounceContacts.add(excp);
            }
            else
            {
                // create mailer contact
                akamContact = new EB_AkaMContact__c();
                akamContact.EB_Contact__c = selectedContact.Id;
                akamContact.EB_Status__c = 'New';
                akamContact.EB_AkaMAccount__c = objAccountAkamAccountMap.get(selectedContact.Account.Id);
                akamContact.EB_EnableValidationRules__c=false;
                //CR 845804 - default email template is populated at amiler level 
                if(Mailer.Email_Template__c != null){
                        akamContact.Email_Template__c = Mailer.Email_Template__c;
                    }
                insertAkamContact.add(akamContact);
            }
        }
        
       
        insert insertAkamContact;

        if(bounceContacts != null && bounceContacts.size()>0)
            insert bounceContacts;
        //End of changes by ssawhney for CR 2611929: Filter all Contacts that have Email Bounce set to true
        if(createMailerDirect==false){
        // creating a mailer by Selecting accounts on UI. Single Mails can be created this way only
            for(EB_SelectedAccounts__c updateRecord :[select EB_Account__c from EB_SelectedAccounts__c where EB_ParentToken__c = :token AND EB_Account__c IN :akamAccountList]){
                //update all selected accounts for which we have updated mailer accounts and mailer contacts
                updateRecord.EB_IsProcessed__c=true;
                updateList.add(updateRecord);
            }
            // update the isProcessed flag to TRUE
            update updateList;
        }
    }
    
    /* 
    Author: Sharath
    Version: 1.0
    Created date: 09/16/2010
    Description: This method overrides the parent class finish method. Send notification to User about the success/failure of batch job
    */
    override global void finish(Database.BatchableContext BC)
    {
      // obtain status of job.
        AsyncApexJob a = [Select Id, Status, NumberOfErrors, JobItemsProcessed,TotalJobItems, CreatedBy.Email from AsyncApexJob where Id = :BC.getJobId()];
        EB_AkaMailer__c akamMailer = new EB_AkaMailer__c();
        akamMailer = [select EB_Operation__c,EB_BatchStatus__c, EB_OperationStatus__c, EB_OperationProcessedCount__c, Owner.Email, CreatedBy.Email,
                      EB_EmailSentToOwner__c, EB_CountToAddresses__c, EB_CalcWarningCount__c, EB_CalcWarningMessage__c from EB_AkaMailer__c where Id = :Mailer.Id];
        
        if(!akamMailer.EB_EmailSentToOwner__c){
          List<Contact> lContact = [SELECT Id, Name, Account.Id, Email FROM Contact WHERE (Email =:akamMailer.CreatedBy.Email OR Email =:akamMailer.Owner.Email OR Email =:a.CreatedBy.Email)
                                      AND Account.Akam_Account_Id__c = '1-599K'];
            List<EB_AkaMContact__c> lMailerContactInternal = [SELECT Id, Mailer__c, EB_Email_Id__c,EB_AkaMAccount__c,Email_Template__c FROM EB_AkaMContact__c
                                                              WHERE EB_AkaMAccount__r.EB_AkaMailer__r.Id =:Mailer.Id AND EB_AkaMAccount__r.EB_Account__r.Akam_Account_Id__c = '1-599K'];
            String internalAkamAccountId = lMailerContactInternal[0].EB_AkaMAccount__c;
            String emailTemplateId = lMailerContactInternal[0].Email_Template__c;
            Set<String> sInternalContactEmail = new Set<String>();
            for(EB_AkaMContact__c varMailerContact :lMailerContactInternal){
                sInternalContactEmail.add(varMailerContact.EB_Email_Id__c);
            }
            List<EB_AkaMContact__c> insertAkamContact = new List<EB_AkaMContact__c>();
            for(Contact varContact: lContact){
                if(! sInternalContactEmail.contains(varContact.Email)){
                    EB_AkaMContact__c akamContactCreation = new EB_AkaMContact__c();
                    akamContactCreation.EB_Contact__c = varContact.Id;
                akamContactCreation.EB_Status__c = 'New';
                akamContactCreation.EB_AkaMAccount__c = internalAkamAccountId;
                   akamContactCreation.EB_EnableValidationRules__c=false;
                    akamContactCreation.Email_Template__c = emailTemplateId;
                    insertAkamContact.add(akamContactCreation);
                }
            }
            insert insertAkamContact;
            akamMailer.EB_EmailSentToOwner__c = true;
            update akamMailer;
        }
        
        list<EB_AkaMAccount__c> lMailerAccountToModify = new list<EB_AkaMAccount__c>();
        list<EB_AkaMAccount__c> lMailerAccountDelete = new list<EB_AkaMAccount__c>();
        list<EB_MailerException__c> lAccountWithoutContactException = new list<EB_MailerException__c>();
        list<EB_AkaMContact__c> lAkamContactForInternalUse = new List<EB_AkaMContact__c>();

       
        lMailerAccountToModify = [SELECT Id, EB_TotalContacts__c, EB_Account__c, EB_Account__r.Akam_Account_Id__c,EB_Account__r.Name FROM EB_AkaMAccount__c                                  
                                  WHERE EB_AkaMailer__c =: Mailer.Id AND (EB_TotalContacts__c = 0 OR EB_Account__r.Akam_Account_Id__c = 'Akamai Internal')];
        for(EB_AkaMAccount__c varMailerAccount: lMailerAccountToModify){
        
            if(varMailerAccount.EB_Account__r.Akam_Account_Id__c != 'Akamai Internal'){
            
                EB_MailerException__c excp = new EB_MailerException__c();
                excp.Exception_Message__c='No Mailer Contact found for Account: ' + varMailerAccount.EB_Account__r.Name;
                excp.EB_Mailer__c=Mailer.Id;
                excp.EB_Type__c = 'Warning';
                lAccountWithoutContactException.add(excp);
                lMailerAccountDelete.add(varMailerAccount);
            }
            
            else if(varMailerAccount.EB_Account__r.Akam_Account_Id__c == 'Akamai Internal'){            
            }
        }  
        
        try{
            insert lAccountWithoutContactException;
            delete lMailerAccountDelete;
        }                        
        
        catch(exception e){
        }
        
        // if job has been successful, update the mailer, which in turn triggers a workflow to notify the user that mailer creation is complete
        if(a.Status=='Completed' && a.NumberOfErrors==0){
            Mailer.EB_AssociatedToken__c= token;
            update Mailer;
        }
        else{
        // Some error has occured.Send an email to the Apex job's submitter notifying of job failure.
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String[] toAddresses = new String[] {a.CreatedBy.Email};
        mail.setToAddresses(toAddresses);
        mail.setSubject('Mailer Creation Failed' );
        mail.setPlainTextBody ('The batch Apex job processed ' + a.TotalJobItems + ' batches with '+ a.NumberOfErrors + ' failures.');
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
        }
    }
}