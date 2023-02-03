/*---------------------------------------------------------------------------------
    Class name          :   SC_PSAutomationController_PublishBatch
    Test Class          :   
    Author              :   Vishnu Sharma
    Created             :   24-Jan-2022
    JIRA                :   ESESP-5612
    Purpose             :   Batch class to create Child Customer Mailer records on click of Publish button from Master Mailer records.
             
    Last Modified         Developer                           Purpose            
    ============= ========================         		    	  ==========
    24-Jan-2022     Vishnu Sharma                             Initial Version
	Test Class : SC_PS_AutomationTest
* --------------------------------------------------------------------------------*/
  public class SC_PSAutomationController_PublishBatch implements Database.Batchable < SC_PSAutomationController.publishBatchClassWrapper  >,Database.Stateful {
  
  // class level variables
  public Id masterRecId = Null;
  public PS_Customer_Mailers__c masterRec = new PS_Customer_Mailers__c();
  public Id securityBulletinRecTypeId;
  //Public List<Attachment> filesToUpload;
  public List < ContentDocumentLink > filesToUpload;
  Map < String, list<PS_Customer_Mailers__c> > accVsMailerRec = new Map < String, list<PS_Customer_Mailers__c> > (); //added by Ashin
  public SC_PSAutomationController.EmailWrapper emailDetail; // added by Ashin
  Map<String, List<SC_PSAutomationController.targetAccountWrapperClass>>  finalmemberIdVsApplicableAccounts = new Map<String, List<SC_PSAutomationController.targetAccountWrapperClass>>(); // Added by Ashin

  
  // Method 1 : Contructor to fetch details from Master Mailer Record to create child mailers.
  public SC_PSAutomationController_PublishBatch(Id masterRecId) {

    this.masterRecId = masterRecId;
    this.masterRec = [Select Id, Product_Name__c, Instructions__c, Subject__c, Content__c, PS_Customer_Mailer_Name__c from PS_Customer_Mailers__c where Id =: masterRecId limit 1];
    this.securityBulletinRecTypeId = Schema.SObjectType.PS_Customer_Mailers__c.getRecordTypeInfosByName().get('Security Bulletin').getRecordTypeId();
    this.filesToUpload = [Select Id, ContentDocumentId from ContentDocumentLink where LinkedEntityId =: masterRecId];
  
  }

  // Method 1 : Reusable method to create messaging instance to notify SSP team members.
  /*public messaging.SingleEmailMessage mailerInstanceCreationMethod(List < String > toAddress, String Subject, String body, String whatId, List < Attachment > attachList) {
    
    messaging.SingleEmailMessage mail = new messaging.SingleEmailMessage();
    mail.setToAddresses(toAddress);
    mail.setSenderDisplayName(UserInfo.getFirstName() + ' ' + UserInfo.getLastName());
    mail.setSubject(Subject);
    mail.setHtmlBody(body);
    if (whatId != '' && whatId != null) {
      mail.setWhatId(whatId);
      mail.setSaveAsActivity(true);
    }

    if (attachList != null && attachList.size() > 0) {
      List < Messaging.EmailFileAttachment > attachmemnts = new List < Messaging.EmailFileAttachment > ();
      Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
      efa.setFileName(attachList[0].Name);
      efa.setBody(attachList[0].body);
      attachmemnts.add(efa);
      mail.setFileAttachments(attachmemnts);
    }

    return mail;

  }*/

  // Method 2 : Start method of batch class
  public Iterable < SC_PSAutomationController.publishBatchClassWrapper  > start(Database.BatchableContext BC) {
    
    //Method level variables
    List < String > prodList = new List < String > ();
    String productName;
    Integer count = 0;
    Map < Id, String > accVsProducts = new Map < Id, String > ();
    List < SC_PSAutomationController.publishBatchClassWrapper> wrapperList =   new List < SC_PSAutomationController.publishBatchClassWrapper>();
    SC_PSAutomationController.publishBatchClassWrapper wrapperRec = new SC_PSAutomationController.publishBatchClassWrapper();

    if (masterRec != null && masterRec.Product_Name__c != '') {
      prodList = masterRec.Product_Name__c.split(';');
    }

    //Creating dynamic query based on products selected to fetch ACHD records
    String baseQuery = 'Select count(Id), Parent_Contract_Header__r.Account_Name__c accName, Marketing_Product_Name__c,Original_Detail_ID__c from Autogen_Contract_Header_Detail__c where (';

    for (String iteratedProduct: prodList) {
      productName = '';
      if (iteratedProduct == 'Managed Kona') {
        productName = 'Managed Kona';
      } else if (iteratedProduct == 'MSS') {
        productName = 'Managed Security Service';
      } else if (iteratedProduct == 'PLX') {
        productName = 'Prolexic';
      }
      count = count + 1;
      baseQuery = baseQuery + ' Marketing_Product_Name__c Like \'%' + productName + '%\'';
      if (count != prodList.size()) {
        baseQuery = baseQuery + 'OR ';
      } else {
        baseQuery = baseQuery + ') and Effective_End_Date__c >= today and Original_Detail_ID__c != \'\' and recordtype.name = \'Line\' and Parent_Contract_Header__r.Account_Name__c != \'\' and Parent_Contract_Header__r.Account_Name__r.Type like \'%- Active%\' and (NOT Parent_Contract_Header__r.Account_Name__r.Vertical__c like \'Akamai Internal\') GROUP BY Parent_Contract_Header__r.Account_Name__c,Marketing_Product_Name__c,Original_Detail_ID__c ';
      }

    }

    List<AggregateResult> lstachd = database.query(baseQuery);
    List<String> originalDetailIdSet = new List<String>();

    // Creating list of all Original Detail Id to validate if they are available in CLI records.
    for (AggregateResult ar : lstachd) {
      originalDetailIdSet.add(String.valueOf(ar.get('Original_Detail_ID__c')));
    } 
  
  
  Map<String,Id> ocdVsMCD = new Map<String,Id>();
  for(Merge_Contract_Detail__c itrMCD: [select id,name,Original_Detail_Id__c  from Merge_Contract_Detail__c where Original_Detail_Id__c IN:originalDetailIdSet]){
      ocdVsMCD.put(itrMCD.Original_Detail_Id__c,itrMCD.Id);
  }
    
  // If valid ACHD , creating map of account vs all appliable products.
  for (AggregateResult ar : lstachd) {
      if(ocdVsMCD.containsKey(String.valueOf(ar.get('Original_Detail_ID__c')))){
        if (accVsProducts.containsKey(Id.valueOf(String.valueOf(ar.get('accName'))))) {
          accVsProducts.put(Id.valueOf(String.valueOf(ar.get('accName'))), accVsProducts.get(Id.valueOf(String.valueOf(ar.get('accName')))) + ';' + String.valueOf(ar.get('Marketing_Product_Name__c')));
          // accVsProducts.get(Id.valueOf(String.valueOf(ar.get('accName')))).add(String.valueOf(ar.get('Marketing_Product_Name__c')));
        } else {
          accVsProducts.put(Id.valueOf(String.valueOf(ar.get('accName'))), String.valueOf(ar.get('Marketing_Product_Name__c')));
        }
      }
    } 

    // Creating wrapper list to return from Start method 
    if(accVsProducts.keySet().size() > 0){
      for(Id accId : accVsProducts.keySet()){
        wrapperRec = new SC_PSAutomationController.publishBatchClassWrapper();
        wrapperRec.Id = accId;
        //wrapperRec.accountName = appAccMap.get(accId);
        wrapperRec.products = accVsProducts.get(accId);
        wrapperList.add(wrapperRec);
      }
    }

   // return new AggregateResultIterable(baseQuery);
   return wrapperList;
  }

  // Method 3 : Execute method of batch class
  public void execute(Database.BatchableContext batchableContext, List < SC_PSAutomationController.publishBatchClassWrapper > scope) {
    
    // Method level variables 
    messaging.SingleEmailMessage mailerInstance;
    List < messaging.SingleEmailMessage > finalMailerList = new List < messaging.SingleEmailMessage > ();
    List < PS_Customer_Mailers__c > childRecs = new List < PS_Customer_Mailers__c > ();
    PS_Customer_Mailers__c childRecInstance;
    Map < Id, String > accVsProducts = new Map < Id, String > ();
    Map < Id, String > accIdvsManagersId = new Map < Id, String > ();
    Map < Id, String > accIdvsTeamMembersId = new Map < Id, String > ();
    List < Account > accList = new List < Account > ();
    Map < Id, Account > accountMap = new Map < Id, Account > ();
    Map < Id, List < String >> accountVsTeamMemberIds = new Map < Id, List < String >> ();
    //Map < String, Id > accVsMailerRec = new Map < String, Id > ();
    List < Attachment > attachmentsToUpload = new List < Attachment > ();
    Map<String, List<Account>>  memberIdVsApplicableAccounts = new Map<String, List<Account>>(); // Added by Ashin

    ContentDocumentLink conDocLink = new ContentDocumentLink();
    List < ContentDocumentLink > conDocLinkList = new List < ContentDocumentLink > ();
    Set < String > prodCategory = new Set < String > ();
    String finalBody = '';
    String subject = '';


  /*  for (sObject sObj: scope) {
      AggregateResult ar = (AggregateResult) sObj;
      // accountIds.add(Id.valueOf(String.valueOf(ar.get('accName'))));
      if (accVsProducts.containsKey(Id.valueOf(String.valueOf(ar.get('accName'))))) {
        accVsProducts.put(Id.valueOf(String.valueOf(ar.get('accName'))), accVsProducts.get(Id.valueOf(String.valueOf(ar.get('accName')))) + ';' + String.valueOf(ar.get('Marketing_Product_Name__c')));
        // accVsProducts.get(Id.valueOf(String.valueOf(ar.get('accName')))).add(String.valueOf(ar.get('Marketing_Product_Name__c')));
      } else {
        accVsProducts.put(Id.valueOf(String.valueOf(ar.get('accName'))), String.valueOf(ar.get('Marketing_Product_Name__c')));
      }
    }
    System.debug('accVsProducts**' + accVsProducts);
    System.debug('accVsProducts**' + accVsProducts.keySet().size());*/

    
    try{
    // Converting wrapper list to map of account vs applicable products.
    for(SC_PSAutomationController.publishBatchClassWrapper itrWrapper:scope){
      accVsProducts.put(itrWrapper.Id,itrWrapper.products);
    }
    
    if (accVsProducts.keySet().size() > 0) {
      accountMap = new Map < Id, Account > ([Select Id, Name, (Select Id, UserId, User.ManagerId, User.Email from AccountTeamMembers where TeamMemberRole = 'Security Services - Primary') from Account where Id IN: accVsProducts.keySet()]);
      
      // Creating map to store team members and their managers
      for (Account iteratedAcc: accountMap.values()) {
        for (AccountTeamMember iteratedMember: iteratedAcc.AccountTeamMembers) {

          if (accIdvsManagersId.containsKey(iteratedAcc.Id)) {
            String newValue = accIdvsManagersId.get(iteratedAcc.Id) + ';' + iteratedMember.User.ManagerId;
            accIdvsManagersId.put(iteratedAcc.Id, newValue);
          } else {
            accIdvsManagersId.put(iteratedAcc.Id, iteratedMember.User.ManagerId);
          }
          if (accIdvsTeamMembersId.containsKey(iteratedAcc.Id)) {
            String newValue = accIdvsTeamMembersId.get(iteratedAcc.Id) + ';' + iteratedMember.UserId;
            accIdvsTeamMembersId.put(iteratedAcc.Id, newValue);
            accountVsTeamMemberIds.get(iteratedAcc.Id).add(iteratedMember.User.id);
            
          } else {
            accIdvsTeamMembersId.put(iteratedAcc.Id, iteratedMember.UserId);
            accountVsTeamMemberIds.put(iteratedAcc.Id, new List < String > {
              iteratedMember.User.id
            });
          }
          
          }
        }
      }
      System.debug('accountVsTeamMemberIds**' + accountVsTeamMemberIds);
      System.debug('accIdvsTeamMembersId**' + accIdvsTeamMembersId);
      System.debug('accIdvsManagersId**' + accIdvsManagersId);
      // Creating child mailer records for each Account
      for (Id itrAcc: accVsProducts.keySet()) {

        childRecInstance = new PS_Customer_Mailers__c();
        childRecInstance.Account__c = itrAcc;
        childRecInstance.Audience_Type__c = 'Internal';
        childRecInstance.Instructions__c = masterRec.Instructions__c;
        childRecInstance.Publish_Date__c = Datetime.now();

        if (accIdvsManagersId.containsKey(itrAcc)) {
          childRecInstance.Manager_Id__c = accIdvsManagersId.get(itrAcc);
        }
        if (accIdvsTeamMembersId.containsKey(itrAcc)) {
          childRecInstance.Team_Member_Id__c = accIdvsTeamMembersId.get(itrAcc);
        }
        // logic to save product value just once if multile products of same category found
        List < String > applicableProds = accVsProducts.get(itrAcc).split(';');
        String finalProdString = '';
        for (String itrProd: applicableProds) {

          if (itrProd.contains('Prolexic')) {
            prodCategory.add('PLX');
            
          } else if (itrProd.contains('Managed Security Service')) {
            prodCategory.add('MSS');
            
          } else if (itrProd.contains('Managed Kona')) {
            prodCategory.add('Managed Kona');
            
          }
        }
        childRecInstance.Product_Name__c = '';
        for (String itrProdCategory: prodCategory) {
          childRecInstance.Product_Name__c = childRecInstance.Product_Name__c + itrProdCategory + ';';
        }
        

        childRecInstance.PS_Customer_Mailer_Name__c = masterRec.PS_Customer_Mailer_Name__c;
        childRecInstance.Subject__c = masterRec.Subject__c;
        childRecInstance.Content__c = masterRec.Content__c;
        childRecInstance.Parent_PS_Customer_Mailer__c = masterRec.Id;
        childRecInstance.RecordTypeId = securityBulletinRecTypeId;
        childRecs.add(childRecInstance);

      }

      // Inserting child mailer records
      if (childRecs.size() > 0) {
        insert childRecs;
      }

      
      for (PS_Customer_Mailers__c itrRec: childRecs) 
      {
        // Account Vs mailers - below 273-282 added by Ashin
        if(itrRec.Account__c!=NULL) 
            {
            if(accVsMailerRec.containsKey(itrRec.Account__c))
            {
              accVsMailerRec.get(itrRec.Account__c).add(itrRec);
            }
            else 
            {
              accVsMailerRec.put(itrRec.Account__c, new list<PS_Customer_Mailers__c> {itrRec});
            }
          }
        for (ContentDocumentLink att: filesToUpload) {
          conDocLink = new ContentDocumentLink();
          conDocLink.LinkedEntityId = itrRec.Id; // Specify RECORD ID here i.e Any Object ID (Standard Object/Custom Object)
          conDocLink.ContentDocumentId = att.ContentDocumentId; //ContentDocumentId Id from ContentVersion
          conDocLink.shareType = 'V';
          conDocLinkList.add(conDocLink);
        }

      }
      //CDL insert
      if (conDocLinkList.size() > 0) {
        insert conDocLinkList;
      }

     // Sending email to SCs
     List<String> memberIds = new List<String>(); //Added by Ashin as per ESESP - 6983 2.a
     for (Id itrAcc: accountMap.keySet()) 
     {
        if (accountVsTeamMemberIds.containsKey(itrAcc)) 
          {
              //Below lines 301 - 339 Added by Ashin as per ESESP - 6983 2.a
              memberIds = accountVsTeamMemberIds.get(itrAcc);
              for(String e : memberIds)
              {
                if(memberIdVsApplicableAccounts.containsKey(e))
                {
                  //String member Vs applicable accounts
                  memberIdVsApplicableAccounts.get(e).add(accountMap.get(itrAcc));
                }
                else 
                {
                  memberIdVsApplicableAccounts.put(e, new List<Account>{accountMap.get(itrAcc)});
                }
              }
          }
      } 

    // Looping through the above populated map, inorder to add to a wrapper and send it to queable apex to send emails
    for(String m:memberIdVsApplicableAccounts.keySet())
      {
        List<Account> accountList = memberIdVsApplicableAccounts.get(m);
        for(Account a : accountList)
        {
          SC_PSAutomationController.targetAccountWrapperClass targetAcc = new SC_PSAutomationController.targetAccountWrapperClass();
          targetAcc.id=a.id;
          targetAcc.name=a.name;
          if(finalmemberIdVsApplicableAccounts.containsKey(m))
          {
            finalmemberIdVsApplicableAccounts.get(m).add(targetAcc);
          }
          else 
          {
            //This map will be sent to queable apex for sending emails in finish method
           finalmemberIdVsApplicableAccounts.put(m, new List<SC_PSAutomationController.targetAccountWrapperClass>{targetAcc});
          }
        }
    }
  
  }
  catch(Exception e)
  {
      System.debug('Exception occured  :: ' + e.getMessage());
      string setEmailSub          = 'Exception: In execute method of SC_PSAutomationController_PublishBatch.';
      string errorMessage         = 'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' + 'Class Name = SC_PSAutomationController_PublishBatch\n' +'Method Name = execute\n';
      errorMessage               += e.getCause()+' .. '+e.getLineNumber()+' .. '+e.getMessage()+' .. '+e.getTypeName()+' .. '+e.getStackTraceString();
      SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support();
      sc_COBSupportCls.senEmailForError(setEmailSub, errorMessage);  
  } 
}

  // Method 4: Finish method of batch class
  public void finish(Database.BatchableContext batchableContext) 
  {
    string finalinstructions='';
    List < SC_PSAutomationController.itemsForSendingEmailsWrapper> wrapperList =   new List < SC_PSAutomationController.itemsForSendingEmailsWrapper>();
    SC_PSAutomationController.itemsForSendingEmailsWrapper wrapperRec = new SC_PSAutomationController.itemsForSendingEmailsWrapper();

    //Creating and email wrapper to store subject and content so that we can use this in a common wrapper to send to queable apex
    SC_PSAutomationController.EmailWrapper emailwrap = new SC_PSAutomationController.EmailWrapper();
    emailwrap.body=masterRec.content__c;
    emailwrap.subject=masterRec.Subject__c;


    //If incase user doesnt enter any instructions in UI, then we are storing instructions as 'N/A'
    if(masterRec.Instructions__c == null || masterRec.Instructions__c=='')
    {
      finalinstructions='N/A';
    }
    else {
      finalinstructions=masterRec.Instructions__c;
    }

    wrapperRec.memberVsApplicableAccountsMap=finalmemberIdVsApplicableAccounts;
    wrapperRec.AccountsVsChildMailers = accVsMailerRec;
    wrapperRec.emailDetails=emailwrap;
    wrapperRec.instructions=finalinstructions;
    wrapperList.add(wrapperRec);

    system.debug('Wrapper list is '+wrapperList);
    if(!wrapperList.isEmpty())
    {
      
      Database.executeBatch(new SC_PSAutomationEmailController_batch(wrapperList), 10);
      //Calling the queable apex and passing the wrapper to send emails
      //system.enqueueJob(new SC_PSAutomationSendEmailsQueueable(wrapperList));
    }

  }
}