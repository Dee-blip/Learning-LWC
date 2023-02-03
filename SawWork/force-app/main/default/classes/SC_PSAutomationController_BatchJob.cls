/*---------------------------------------------------------------------------------
    Class name          :   SC_PSAutomationController_BatchJob
    Test Class          :   
    Author              :   Vishnu Sharma
    Created             :   24-Jan-2022
    JIRA                :   ESESP-5612
    Purpose             :   Batch class to create Child Customer Mailer records / Notify Account Owners for missing SSP Team members.
             
    Last Modified         Developer                           Purpose            
    ============= ========================                ==========
    24-Jan-2022     Vishnu Sharma                             Initial Version
  Test Class : SC_PS_AutomationTest
* --------------------------------------------------------------------------------*/
public class SC_PSAutomationController_BatchJob implements Database.Batchable < SC_PSAutomationController.targetAccountWrapperClass >, Database.Stateful{

  // Class level variables
  public Id masterRecId = Null;
  public String emailDetailStr = Null;
  public String accountsList = Null;
  public SC_PSAutomationController.EmailWrapper emailDetail;
  //public List < Attachment > filesToUpload;
  public List<ContentDocumentLink> filesToUpload;
  public String audienceType = Null;
  public String instructions = Null; 
  public String mailerName = Null;
  public Id securityBulletinRecTypeId;
  public Boolean isPublish = false;
  public Boolean isMissingSSPNotifyScenario = false;
  // below Added by Ashin
  Map<String, List<SC_PSAutomationController.targetAccountWrapperClass>>  memberIdVsApplicableAccounts = new Map<String, List<SC_PSAutomationController.targetAccountWrapperClass>>();
  String finalBody = '';
  String subject = '';
  Map < String, list<PS_Customer_Mailers__c> > accVsMailerRec = new Map < String, list<PS_Customer_Mailers__c> > ();
  // Above Added by Ashin
 



  //Method-1 : Constructor of Batch Class for Child Mailer records creation.
  public SC_PSAutomationController_BatchJob(Id masterRecId, String emailDetailStr, String accountsList, String audienceType, String instructions, String mailerName, String files, Boolean isPublish) {

    this.masterRecId = masterRecId;
    SC_PSAutomationController.EmailWrapper emailDetails = (SC_PSAutomationController.EmailWrapper) JSON.deserialize(emailDetailStr, SC_PSAutomationController.EmailWrapper.class);
    this.emailDetail = emailDetails;
    this.accountsList = accountsList;
    this.audienceType = audienceType;
    this.instructions = instructions;
    this.mailerName = mailerName;
    this.securityBulletinRecTypeId = Schema.SObjectType.PS_Customer_Mailers__c.getRecordTypeInfosByName().get('Security Bulletin').getRecordTypeId();
    //  List<SC_PSAutomationController.fileClass> filesToUpload = (List<SC_PSAutomationController.fileClass> ) JSON.deserialize(files, SC_PSAutomationController.fileClass[].class);
   // this.filesToUpload = [Select Id, Name, Body from Attachment where ParentId =: masterRecId];
    this.filesToUpload = [Select Id,ContentDocumentId from ContentDocumentLink where LinkedEntityId =:masterRecId];
    
    this.isPublish = isPublish;

  }

  //Method-2 : Constructor of Batch Class for notifying Account Owners for missing SSP Team Mambers.
  public SC_PSAutomationController_BatchJob(String accountsList, Boolean isMissingSSPNotifyScenario) {
    this.accountsList = accountsList;
    this.isMissingSSPNotifyScenario = isMissingSSPNotifyScenario;
  }  

  // Method 3: Reusable method for creating messaging instance
  public messaging.SingleEmailMessage mailerInstanceCreationMethod(String toAddress, String Subject, String body, String whatId, List < Attachment > attachList,Boolean setName) {
    messaging.SingleEmailMessage mail = new messaging.SingleEmailMessage();
  // mail.setToAddresses(toAddress);
    mail.setTargetObjectId(Id.valueOf(toAddress));
   
    // Not Setting display name for missing team member mails 
   if(setName){
   mail.setSenderDisplayName(UserInfo.getFirstName()+' '+UserInfo.getLastName());
   }
    mail.setSubject(Subject);
    mail.setHtmlBody(body);
    mail.setSaveAsActivity(false); //Added by Ashin on May 27
    if (whatId != '' && whatId != null) {
      mail.setWhatId(whatId);
      //mail.setSaveAsActivity(true); // Commented by Ashin on May 27
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

  }

  // Method 4: Start method of Batch class returning wrapper class instances
  public Iterable < SC_PSAutomationController.targetAccountWrapperClass > start(Database.BatchableContext BC) {
    List < SC_PSAutomationController.targetAccountWrapperClass > targetAccountWrapperRecs = (List < SC_PSAutomationController.targetAccountWrapperClass > ) JSON.deserialize(accountsList, SC_PSAutomationController.targetAccountWrapperClass[].class);
    return targetAccountWrapperRecs;
  }

  // Method 5: Execute method
  public void execute(Database.BatchableContext batchableContext, List < SC_PSAutomationController.targetAccountWrapperClass > scope) {
    
    // Method level variables
    List < PS_Customer_Mailers__c > childRecs = new List < PS_Customer_Mailers__c > ();
    PS_Customer_Mailers__c childRecInstance;
    String allAccountsName = '';
    List < Id > accountIdList = new List < Id > ();
    Map < Id, String > accIdvsManagersId = new Map < Id, String > ();
    Map < Id, String > accIdvsTeamMembersId = new Map < Id, String > ();
    List < Account > accList = new List < Account > ();
    List < messaging.SingleEmailMessage > finalMailerList = new List < messaging.SingleEmailMessage > ();
    messaging.SingleEmailMessage mailerInstance;
    List < Attachment > attachmentsToUpload = new List < Attachment > ();
    ContentDocumentLink conDocLink = new ContentDocumentLink();
    List<ContentDocumentLink> conDocLinkList = new List<ContentDocumentLink>();
    Set<String> prodCategory = new Set<String>(); 
    String prod;

    try{
    // Checking if scenario is for creating child recs or sending missing team member email
    if(isMissingSSPNotifyScenario){
      for(SC_PSAutomationController.targetAccountWrapperClass iteratedAccountDetail : scope){
        
        // Checking if no team member available and notifying
        if(iteratedAccountDetail.TeamMember == '' || iteratedAccountDetail.TeamMember == null){
            mailerInstance = mailerInstanceCreationMethod(iteratedAccountDetail.ownerId,'Security Services Primary team member not available','Hi , <br/> <br/>Security services primary team member is not available for Account : '+iteratedAccountDetail.Name+'.<br/>Please configure team member with role as "Security Services Primary" at <a href="'+System.URL.getSalesforceBaseUrl().toExternalForm()+'/'+iteratedAccountDetail.Id+'">Account Link</a>.<br/><br/>Thanks,<br/>PS Automation Team',null,null,false);
            finalMailerList.add(mailerInstance);
            
        }
      }
      if(finalMailerList.size() > 0){
          Messaging.sendEmail(finalMailerList);
      }

    }else{
          // Else Scenario for creating Child mailer records
          for (SC_PSAutomationController.targetAccountWrapperClass iteratedAccountRecs: scope) {
      
            accountIdList.add(iteratedAccountRecs.Id);
          }
          
          // Storing all team members and their managers in map.
          if (accountIdList.size() > 0) {
            accList = [Select Id, (Select Id, UserId, User.ManagerId from AccountTeamMembers where TeamMemberRole = 'Security Services - Primary') from Account where Id IN: accountIdList];
            for (Account iteratedAcc: accList) {
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
                } else {
                  accIdvsTeamMembersId.put(iteratedAcc.Id, iteratedMember.UserId);
                }
              }
            }
          }

          // Iterating over wrapper list records to create child mailer records
          for (SC_PSAutomationController.targetAccountWrapperClass iteratedAccountRecs: scope) {
            childRecInstance = new PS_Customer_Mailers__c();
            childRecInstance.Account__c = iteratedAccountRecs.Id;
            childRecInstance.Audience_Type__c = 'Internal';

            childRecInstance.Instructions__c = instructions;
            
            if (isPublish) {
              childRecInstance.Publish_Date__c = Datetime.now();
            }

            if (accIdvsManagersId.containsKey(iteratedAccountRecs.Id)) {
              childRecInstance.Manager_Id__c = accIdvsManagersId.get(iteratedAccountRecs.Id);
            }
            if (accIdvsTeamMembersId.containsKey(iteratedAccountRecs.Id)) {
              childRecInstance.Team_Member_Id__c = accIdvsTeamMembersId.get(iteratedAccountRecs.Id);
            }
            List<String> applicableProds = iteratedAccountRecs.Product.split(';');
            String finalProdString = '';

            // logic to save product value just once if multile products of same category found
            for(String itrProd : applicableProds){
              
              if(itrProd.contains('Prolexic')){
                prodCategory.add('PLX');
                
              }else if (itrProd.contains('Managed Security Service')) {
                prodCategory.add('MSS');
                
              } else if (itrProd.contains('Managed Kona')) {
                prodCategory.add('Managed Kona');
              
              }
            }
            childRecInstance.Product_Name__c = '';

            
            for(String itrProdCategory : prodCategory){
              childRecInstance.Product_Name__c = childRecInstance.Product_Name__c+itrProdCategory+';';
            }
           
            childRecInstance.PS_Customer_Mailer_Name__c = mailerName;
            childRecInstance.Subject__c = emailDetail.subject;
            childRecInstance.Content__c = emailDetail.body;
            childRecInstance.Parent_PS_Customer_Mailer__c = masterRecId;
            childRecInstance.RecordTypeId = securityBulletinRecTypeId;
            childRecs.add(childRecInstance);
      
          }

          // Inserting child mailer records
          if (childRecs != null && childRecs.size() > 0) {
            Insert childRecs;
          }

          // Saving ids of mailer records created for each account and loading files on created child mailers.
          for (PS_Customer_Mailers__c itrRec: childRecs) 
          {
            //Below lines from 221 to 231 added by Ashin
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
            //Above lines from 221 to 231 added by Ashin
          }
            
            for (ContentDocumentLink att: filesToUpload) {
              
              conDocLink  = new ContentDocumentLink();
              conDocLink.LinkedEntityId = itrRec.Id; // Specify RECORD ID here i.e Any Object ID (Standard Object/Custom Object)
              conDocLink.ContentDocumentId = att.ContentDocumentId;  //ContentDocumentId Id from ContentVersion
              conDocLink.shareType = 'V';
              conDocLinkList.add(conDocLink);
            }
      
          }
          // Content document links insert
          if (conDocLinkList.size() > 0) {
            insert conDocLinkList;
          }
      
          // Sending mails to SCs for Mailer records
          if (isPublish) 
          {
            //For each account mail
            for (SC_PSAutomationController.targetAccountWrapperClass iteratedTargetAccount: scope) 
            {
              if (iteratedTargetAccount.TeamMemberMap != null && iteratedTargetAccount.TeamMemberMap.values().size() > 0) 
              {
                //Below lines 257-268 Added by Ashin as per ESESP - 6983 2.a
                //TeamMemberMap is member name Vs email -----> This should be chnaged to name vs ID
                for(AccountTeamMember s: iteratedTargetAccount.TeamMemberMap.Values())
                {
                    if(memberIdVsApplicableAccounts.containsKey(s.UserId))
                    {
                        //NOTE :-  TeamMemberMap will be removed by vishnu, need to iterate over new variable to get memberId and Applicable accounts
                      //Currently memberIdVsApplicableAccounts is a map of member Email vs all Applicable accounts.  We need to store id Vs accounts
                      memberIdVsApplicableAccounts.get(s.UserId).add(iteratedTargetAccount);
                    }
                    else 
                    {
                      memberIdVsApplicableAccounts.put(s.UserId, new List<SC_PSAutomationController.targetAccountWrapperClass>{iteratedTargetAccount});
                    }
                }
              }
            }  
          }
        }
        
    }
    catch(Exception e)
    {
        System.debug('Exception occured  :: ' + e.getMessage());
        string setEmailSub          = 'Exception: In execute method of SC_PSAutomationController_BatchJob.';
        string errorMessage         = 'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' + 'Class Name = SC_PSAutomationController_BatchJob\n' +'Method Name = execute\n';
        errorMessage               += e.getCause()+' .. '+e.getLineNumber()+' .. '+e.getMessage()+' .. '+e.getTypeName()+' .. '+e.getStackTraceString();
        SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support();
        sc_COBSupportCls.senEmailForError(setEmailSub, errorMessage);  
    } 

  }

  //Method 6: finish method of batch class
  public void finish(Database.BatchableContext batchableContext) 
  {

    string finalinstructions='';
    system.debug('Batch_Job Account vs mailers are:- '+accVsMailerRec);
    system.debug('Batch_Job Account vs mailers size is +++ :- '+accVsMailerRec.size());
    system.debug('Batch_Job Member vs applicable accounts are :- '+memberIdVsApplicableAccounts);
    system.debug('Batch_Job Member vs applicable accounts size is +++ :- '+memberIdVsApplicableAccounts.size());
    system.debug('Batch_Job Common email details are:- ===== '+ emailDetail);
    system.debug('Batch_Job Instructions are ----- '+ instructions);

    //If incase user doesnt enter any instructions in UI, then we are storing instructions as 'N/A'
    if(instructions == null || instructions=='')
    {
      finalinstructions='N/A';
    }
    else {
      finalinstructions=instructions;
    }

    List < SC_PSAutomationController.itemsForSendingEmailsWrapper> wrapperList =   new List < SC_PSAutomationController.itemsForSendingEmailsWrapper>();
    SC_PSAutomationController.itemsForSendingEmailsWrapper wrapperRec = new SC_PSAutomationController.itemsForSendingEmailsWrapper();
    wrapperRec.memberVsApplicableAccountsMap=memberIdVsApplicableAccounts;
    wrapperRec.AccountsVsChildMailers = accVsMailerRec;
    wrapperRec.emailDetails=emailDetail;
    wrapperRec.instructions=finalinstructions;
    wrapperList.add(wrapperRec);

   
    system.debug('Batch_Job Wrapper list is '+wrapperList);
    if(!wrapperList.isEmpty())
    {
        //NOTE :- uncomment line 324, once vishnu makes changes
      Database.executeBatch(new SC_PSAutomationEmailController_batch(wrapperList), 10);
      //Calling child batch apex and passing wrapper data to it to send emails
    }
      
  }


}