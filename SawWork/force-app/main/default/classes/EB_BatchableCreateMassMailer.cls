/*
Author: Sharath
Version: 1.0
Created date: 09/16/2010
Description: CR-819957- Batchable child class for EB_BatchableMailerWizard. This class creates mailers of 'Mass Mail' type in Batches
Modified: 
4/21/2014 CR 2611929: Filter all Contacts that have Email Bounce set to true 
*/
 global class EB_BatchableCreateMassMailer extends EB_BatchableMailerWizard implements Database.Batchable<sObject> {
    List<Contact> selectedContacts = new List<Contact>();
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
    Description: Contructor which calls the Parent class constructor for initialising the query. Initialize the parameters.
    */
    global EB_BatchableCreateMassMailer(String q,EB_AkaMailer__c Mailer,String token, EB_AkaMAccount__c akamAccount,Boolean createMailerDirect,List<String>  allAccounts,list<Account> ResellerAccountsOmitted)
    {
        super(q,allAccounts);
        this.Mailer=Mailer;
        this.token= token ;
        this.akamAccount=akamAccount;
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
    Description: Contains the logic for creating mailer contacts
    */
    override global void execute(Database.BatchableContext BC, List<sObject> scope)
    {
        /* - old code - removing this for CR 1387154 - Create Lighter Foot Print Mailer for Mass Mails
        selectedContacts.clear();
        selectedContacts=scope;
        
        for( Contact selectedContact: selectedContacts){
            // create mailer contact
            akamContact = new EB_AkaMContact__c();
            akamContact.EB_Contact__c = selectedContact.Id;
            akamContact.EB_Status__c = 'New';
            akamContact.EB_AkaMAccount__c = akamAccount.Id;
            akamContact.EB_EnableValidationRules__c=false;
            insertAkamContact.add(akamContact);
            akamAccountList.add(selectedContact.Account.Id);
        }
        insert insertAkamContact;
        
        insertAkamAccount.clear();
        objAccountAkamAccountMap.clear();
        akamAccountList.clear();
        insertAkamContact.clear();
        updateList.clear(); 
        */
        /* CR 1387154 - Create Lighter Foot Print Mailer for Mass Mails
        Modified - 11/25/2011
        Author- Sharath
        Description - lighter mailers for mass mail , each mailer contact to have a maximum of 25 emails in the To-List.
        Mailer contact also to carry the names and ids of all accounts that is contained in the To-List.
        */
        String existingAccountId='';
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
            list<Merge_Contract_Header__c> resellerchildcontracts2= new List<Merge_Contract_Header__c>();
            String AccountNames='Not initialized by now';
            ContractIdsCustomSettings1= EB_ResellerContractId__c.getAll().values(); //[select Original_Contract_Id__c,Name from EB_ResellerContractId__c];
            String s;
            String s1;
            try
            {
                        for (EB_ResellerContractId__c RCId: ContractIdsCustomSettings1)
                        {
                         s=RCId.Original_Contract_Id__c;
                         ResellerContractIds1.add(s);
                        }
                         Date T2day1=Date.today();
                        resellerparentcontracts1=[select Id,Account_Name__c from Merge_Contract_Header__c where Active__c=TRUE  and Effective_End_Date__c>=:T2day1 and Name in :ResellerContractIds1];
                        
                        resellerchildcontracts1=[select Id,Account_Name__c from Merge_Contract_Header__c where Active__c=TRUE and Effective_End_Date__c>=:T2day1 and Parent_Contract__c in :resellerparentcontracts1];
                        
                        for(Merge_Contract_Header__c c:resellerparentcontracts1)
                        {
                         ParentContractAccountNames.add(c.Account_Name__c);
                        
                        } 
                        ResellerAccounts1=[Select Id,Name from Account where Id in :ParentContractAccountNames];
                        For(Account a:ResellerAccounts1)
                        {
                        AccountNames=AccountNames+a.Name+' ';
                        }
                        resellerchildcontracts2=[select Id,Account_Name__c,Account_Name__r.name,Parent_Contract__r.Account_Name__c,Parent_Contract__r.Account_Name__r.name from Merge_Contract_Header__c where  Active__c=TRUE and Effective_End_Date__c>=:T2day1 and Parent_Contract__c in :resellerparentcontracts1 and Parent_Contract__r.Account_Name__c in :ResellerAccounts1 ];
                        integer count=0;
                        Boolean Duplicate=False;
                       For(Merge_Contract_Header__c c:resellerchildcontracts2)
                        {
                        
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
                    
                            /*count++;
                            s1=count+'. ' + c.Account_Name__r.name;
                            List<String>s2=new List<String>();
                            s2.add(s1+'\n');
                            OmittedMap.put(c.Parent_Contract__r.Account_Name__r.name,new List<String>(s2));
                            */
                        }
                       }
        }
        catch(exception e)
        {
        //do nothing for now.
        }
        String emailIdList = '';
        Integer count = 0;
        String accountIdList='';
        String accountNameList='';
        Set<String> uniqueAccountIds = new Set<String>();
        Set<String> uniqueAccountNames = new Set<String>();
        Account checkReseller;
        String AccName1='No Reseller found';
       for(Contact selectedContact: selectedContacts )
          {
          ConAccID.add(selectedContact.Account.Id);
          //system.assertEquals(ConAccID,Null);
          }
          CheckResellerAcc=[Select Id,Name from Account where Id in :ConAccID];
        //system.assertEquals(CheckResellerAcc,Null);
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
        for( Contact selectedContact: selectedContacts )
        {
        
            try
            {
                checkReseller=tempMap.get(selectedContact);
                AccName1=checkReseller.Name;
            }
            catch(Exception e)
            {
                AccName1='No Reseller found';
                //system.assertEquals(e,null);
            }
            // Start of changes by ssawhney for CR 2611929: Filter all Contacts that have Email Bounce set to true
            //if email bounce is set to true create exception 
            if(selectedContact.EmailBouncedReason != null && selectedContact.EmailBouncedReason != '')
            {
                EB_MailerException__c excp = new EB_MailerException__c();
                excp.Exception_Message__c='Email Id Bounce checked for Contact: ' + selectedContact.firstname + ' ' + selectedContact.lastname + ' of Account: ' + selectedContact.Account.Name + ' Id: ' + selectedContact.Id;
                excp.EB_Mailer__c=Mailer.Id;
                excp.EB_Type__c = 'Warning';
                bounceContacts.add(excp);
            }
            else
            {
                //1st contact - should be the mailer contact
                if(count==0 || AccountNames.contains(AccName1)== TRUE){
                    emailIdList = selectedContact.Email ;
                    accountNameList = selectedContact.Account.Name;
                    accountIdList = selectedContact.Account.Id;
                    uniqueAccountNames.add(selectedContact.Account.Name);
                    uniqueAccountIds.add(selectedContact.Account.Id);
                    akamContact = new EB_AkaMContact__c();
                    if(AccountNames.contains(AccName1)==FALSE)
                    {
                    EBCS_Application__c customSetting = EBCS_Application__c.getInstance('InternalContactId');
                    akamContact.EB_Contact__c = customSetting.Value__c;
                    }
                    else
                    {
                    akamContact.EB_Contact__c =selectedContact.Id;
                     if(OmittedMap.get(selectedContact.Account.name)!= Null)
                    {
                     for(String ac:OmittedMap.get(selectedContact.Account.name))
                     {
                     omittedmapstring=omittedmapstring+ac+' ';
                     }
                     akamContact.Eb_ResellerMailerAccounts__c=omittedmapstring;
                    }
                   
                    }
                    akamContact.EB_Status__c = 'New';
                    akamContact.EB_AkaMAccount__c = akamAccount.Id;
                    akamContact.EB_EnableValidationRules__c=false;
                    akamContact.EB_ToList__c = emailIdList;
                    // count starts from zero. count + 2 to include the email in the targetObject i.e Mailer contact' email id
                    akamContact.EB_EmailIdCount__c = count + 2;
                    akamContact.EB_ImpactedAccounts__c = selectedContact.Account.Name;
                    akamContact.EB_ImpactedAccountIds__c = selectedContact.Account.Id;
                    insertAkamContact.add(akamContact);
                }
                // all other contacts - just copy email id into ToList
                else if(count <23){
                    emailIdList = emailIdList + '\n' + selectedContact.Email ;
                    uniqueAccountNames.add(selectedContact.Account.Name);
                    uniqueAccountIds.add(selectedContact.Account.Id);
                    accountIdList = '';
                    accountNameList = '';
                    for(String accid:uniqueAccountIds){
                        accountIdList = accountIdList + '\n' + accId;
                    }
                    accountIdList = accountIdList.substring(1,accountIdList.length());
                    for(String accName :uniqueAccountNames ){
                        accountNameList = accountNameList + '\n' + accName;
                    }
                    akamContact.EB_EmailIdCount__c = count + 2;
                    akamContact.EB_ToList__c = emailIdList;
                    akamContact.EB_ImpactedAccounts__c = accountNameList;
                    akamContact.EB_ImpactedAccountIds__c = accountIdList;
                }
                // last contact that can be added to the To-List, reset the count to 0 so that next contact will be the mailer contact
            if(count == 23){
                emailIdList = emailIdList + '\n' + selectedContact.Email ;
                akamContact.EB_ToList__c = emailIdList;
                uniqueAccountNames.add(selectedContact.Account.Name);
                uniqueAccountIds.add(selectedContact.Account.Id);
                accountIdList = '';
                    accountNameList = '';
                    for(String accid:uniqueAccountIds){
                        accountIdList = accountIdList + '\n' + accId;
                    }
                    for(String accName:uniqueAccountNames ){
                        accountNameList = accountNameList + '\n' + accName;
                    }
                    accountIdList = accountIdList.substring(1,accountIdList.length());
                akamContact.EB_EmailIdCount__c = count + 2;
                akamContact.EB_ImpactedAccounts__c = accountNameList;
                akamContact.EB_ImpactedAccountIds__c = accountIdList;
                // maximum size of To-List reached, next contact- if any, should be a mailer contact
                count = 0;
                uniqueAccountNames.clear();
                uniqueAccountIds.clear();
                continue;
                }
            count++ ;
           }
        }
        insert insertAkamContact;
        if(bounceContacts != null && bounceContacts.size()>0)
            insert bounceContacts;
        //End of changes by ssawhney for CR 2611929: Filter all Contacts that have Email Bounce set to true
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
        akamMailer = [select Email_Template__r.EB_SFEmailTemplateId__c, EB_Operation__c,EB_BatchStatus__c,EB_OperationStatus__c,EB_OperationProcessedCount__c,EB_CalcWarningCount__c, EB_CalcWarningMessage__c, EB_CountToAddresses__c, 
                      Owner.Email, CreatedBy.Email, EB_EmailSentToOwner__c  from EB_AkaMailer__c where Id = :Mailer.Id];
        if(!akamMailer.EB_EmailSentToOwner__c){
          List<Contact> lContact = [SELECT Id, Name, Account.Id, Email FROM Contact WHERE (Email =:akamMailer.CreatedBy.Email OR Email =:akamMailer.Owner.Email OR Email =:a.CreatedBy.Email)
                                      AND Account.Akam_Account_Id__c = '1-599K'];
            List<EB_AkaMContact__c> lMailerContactInternal = [SELECT Id, Mailer__c, EB_Email_Id__c,EB_AkaMAccount__c,Email_Template__c, EB_ImpactedAccounts__c,EB_ToList__c FROM EB_AkaMContact__c
                                                              WHERE EB_AkaMAccount__r.EB_AkaMailer__r.Id =:Mailer.Id];
            String internalAkamAccountId = lMailerContactInternal[0].EB_AkaMAccount__c;
            String emailTemplateId = lMailerContactInternal[0].Email_Template__c;
            Set<String> sInternalContactEmail = new Set<String>();
            for(EB_AkaMContact__c varMailerContact :lMailerContactInternal){
              if(varMailerContact.EB_ImpactedAccounts__c.containsIgnoreCase('Akamai Technologies - Assets') 
           && varMailerContact.EB_ToList__c != null){
                for(String varEmail :varMailerContact.EB_ToList__c.split('\n')){
                  sInternalContactEmail.add(varEmail);
                }
              }
            }
            List<EB_AkaMContact__c> insertAkamContact = new List<EB_AkaMContact__c>();
            String emailIdList = '';
            for(Contact varContact: lContact){
                if(! sInternalContactEmail.contains(varContact.Email)){
                  emailIdList += varContact.Email + '\n';
                }
            }      
                    if(emailIdList.trim() != '' && emailIdList.trim()!=null){
                      EB_AkaMContact__c akamContactCreation = new EB_AkaMContact__c();
                      EBCS_Application__c customSetting = EBCS_Application__c.getInstance('InternalContactId');
                      akamContactCreation.EB_Contact__c = customSetting.Value__c;
                      akamContactCreation.EB_Status__c = 'New';
                      akamContactCreation.EB_AkaMAccount__c = internalAkamAccountId;
                      akamContactCreation.EB_EnableValidationRules__c=false;
                      akamContactCreation.EB_ToList__c = emailIdList.trim();
                      akamContactCreation.EB_ImpactedAccounts__c = 'Akamai Technologies - Assets';
                      insertAkamContact.add(akamContactCreation);
                    }
            if(insertAkamContact.size()>0)
            insert insertAkamContact;
            akamMailer.EB_EmailSentToOwner__c = true;
            update akamMailer;
        }
        if(a.Status=='Completed' && a.NumberOfErrors==0){
            // if job has been successful, update the mailer, which in turn triggers a workflow to notify the user that mailer creation is complete
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