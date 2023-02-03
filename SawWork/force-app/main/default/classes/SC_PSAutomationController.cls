/*---------------------------------------------------------------------------------
    Class name          :   SC_PSAutomationController
    Test Class          :   
    Author              :   Vishnu Sharma
    Created             :   14-Jan-2022
    JIRA                :   ESESP-5612
    Purpose             :   PS Automation Workflow
             
    Last Modified         Developer                           Purpose            
    ============= ========================         			  ==========
    14-Jan-2022     Vishnu Sharma                             Initial Version
	Test Class : SC_PS_AutomationTest
* --------------------------------------------------------------------------------*/
public class SC_PSAutomationController {

    //Method 1 : Common method to get recipient email ids for DL incase of Internal and emails in case of External mailer.
    @AuraEnabled
    public static List<String> getDLList(String type,Id recId){
        List<String> dls = new List<String>();
        PS_Customer_Mailers__c mailerRec = new PS_Customer_Mailers__c();
        PS_Automation_Admin_DL__c dlRec = new PS_Automation_Admin_DL__c();
        String dlEmails;
        // Validating if request to fetch External / Internal email id recipients.
        if(type == 'External'){
            mailerRec = [Select Id,Account__c from PS_Customer_Mailers__c where Id=:recId];
            dlRec = [Select Id,DL_Email_Address__c from PS_Automation_Admin_DL__c where recordType.Name = 'External' AND Account__c =:mailerRec.Account__c limit 1];
        }else{
            dlRec = [Select Id,DL_Email_Address__c from PS_Automation_Admin_DL__c where recordType.Name = 'Internal' limit 1];
        } 
        // Spliting email string with ',' to get list of emails.      
        if(dlRec != null){
            dlEmails = dlRec.DL_Email_Address__c;
            if(dlEmails.contains(',')){
                dls = dlEmails.split(',');
            }else{
                dls.add(dlEmails);
            }
            
        }    
            return dls;
    }    

    //Method 2 : Method runs on init of mailer creation for and every time product selected changes to get applicable account details. 
    @AuraEnabled
    public static String getMappedAccounts(List<String> products){
        //Method level variables
        Map<Account,String> finalAccountMap = new Map<Account,String>();
        AccountListWrapper singleAccountListWrapperRec ;
        List<AccountListWrapper> accountListWrapper = new List<AccountListWrapper>();
        Map<Id,String> accIdVsProduct = new Map<Id,String>();
        Map<Id,Id> achdVsAcc = new Map<Id,Id>();
        Integer count = 0;
        List<Id> accountIds = new List<Id>();
        Map<Id,Account> accountMap = new Map<Id,Account>();
        Map<Id,Set<String>> accVsProductList = new Map<Id,Set<String>>();
        //Map<Id,String> accVsProducts = new Map<Id,String>();
        Map<Id,Autogen_Contract_Header_Detail__c> autogenHeaderMap = new Map<Id, Autogen_Contract_Header_Detail__c>();
        String productName = '';
        String finalProductString = '';
        List<Autogen_Contract_Header_Detail__c> autogenHeaderList = new List<Autogen_Contract_Header_Detail__c>();
        try{
        // Defining base query
        String baseQuery = 'Select count(Id), Parent_Contract_Header__r.Account_Name__c accName, Marketing_Product_Name__c,	Original_Detail_ID__c from Autogen_Contract_Header_Detail__c  where (';//recordtype.name = \'Line\' and Effective_End_Date__c >= today and (';
        //Creating dynamic query
        for(String iteratedProduct : products){
            if(iteratedProduct == 'Managed Kona'){  
                productName = 'Managed Kona';
            }else if(iteratedProduct == 'MSS'){
                productName = 'Managed Security Service';
            }else if(iteratedProduct == 'PLX'){
                productName = 'Prolexic';
            }
            count = count +1;
            baseQuery = baseQuery + ' Marketing_Product_Name__c Like \'%'+productName+'%\'';
            if(count != products.size()){
                baseQuery = baseQuery + 'OR ';
            }else{
                baseQuery = baseQuery + ') and Effective_End_Date__c >= today and Original_Detail_ID__c != \'\' and recordtype.name = \'Line\' and Parent_Contract_Header__r.Account_Name__c != \'\' and Parent_Contract_Header__r.Account_Name__r.Type like \'%- Active%\' and (NOT Parent_Contract_Header__r.Account_Name__r.Vertical__c like \'Akamai Internal\') GROUP BY Parent_Contract_Header__r.Account_Name__c,Marketing_Product_Name__c,Original_Detail_ID__c';
             // baseQuery = baseQuery + ') and recordtype.name = \'Line\' and Parent_Contract_Header__r.Account_Name__c != \'\' GROUP BY Parent_Contract_Header__r.Account_Name__c,Marketing_Product_Name__c';
            }
            
        }
        System.debug('Query**'+baseQuery);
        List<String> originalDetailIdSet = new List<String>();

        // Querying data
        List<AggregateResult> lstachd = database.query(baseQuery);
        for (AggregateResult ar : lstachd) {
            originalDetailIdSet.add(String.valueOf(ar.get('Original_Detail_ID__c')));
        } 
        System.debug('***originalDetailIdSet'+originalDetailIdSet);
        
        
        Map<String,Id> ocdVsMCD = new Map<String,Id>();
        for(Merge_Contract_Detail__c itrMCD: [select id,name,Original_Detail_Id__c  from Merge_Contract_Detail__c where Original_Detail_Id__c IN:originalDetailIdSet]){
            ocdVsMCD.put(itrMCD.Original_Detail_Id__c,itrMCD.Id);
        }
        // Creating map of account vs product string 
       for (AggregateResult ar : lstachd) {
        if(ocdVsMCD.containsKey(String.valueOf(ar.get('Original_Detail_ID__c')))){
            System.debug(String.valueOf(ar.get('accName')));
            if(accVsProductList.containsKey(Id.valueOf(String.valueOf(ar.get('accName'))))){
                accVsProductList.get(Id.valueOf(String.valueOf(ar.get('accName')))).add(String.valueOf(ar.get('Marketing_Product_Name__c')));
                //accVsProducts.put(Id.valueOf(String.valueOf(ar.get('accName'))), accVsProducts.get(Id.valueOf(String.valueOf(ar.get('accName'))))+';'+String.valueOf(ar.get('Marketing_Product_Name__c')));
               
            }else{
                accVsProductList.put(Id.valueOf(String.valueOf(ar.get('accName'))),new Set<String>{String.valueOf(ar.get('Marketing_Product_Name__c'))});
                //accVsProducts.put(Id.valueOf(String.valueOf(ar.get('accName'))),String.valueOf(ar.get('Marketing_Product_Name__c')));
            }
        }    
      
        }
        if(accVsProductList.keySet().size()>0){
            accountMap = new Map<ID, Account>([Select Id,Name,TERR_HIER_1__c,Owner.email,OwnerId,(Select Id,UserId,User.Name,User.email,TeamMemberRole from AccountTeamMembers where TeamMemberRole ='Security Services - Primary') from Account where Id IN:accVsProductList.keySet()]);
            // Creating wrapper data list
            for(Id iteratedAcc:accVsProductList.keySet()){
                finalProductString = '';
                for(String itrProd : accVsProductList.get(iteratedAcc)){
                    if(finalProductString != '')
                    finalProductString = finalProductString + ';' +itrProd;
                    else
                    finalProductString = itrProd;
                }
                singleAccountListWrapperRec = new AccountListWrapper();
                singleAccountListWrapperRec.accountRec = accountMap.get(iteratedAcc);
                singleAccountListWrapperRec.ownerId =accountMap.get(iteratedAcc).OwnerId;
                singleAccountListWrapperRec.memberVsEmail = new Map<String,AccountTeamMember>();
                if(accountMap.get(iteratedAcc).AccountTeamMembers.size() > 0){
                    for(AccountTeamMember iteratedMember : accountMap.get(iteratedAcc).AccountTeamMembers){
                        singleAccountListWrapperRec.memberVsEmail.put(iteratedMember.User.Name,iteratedMember);
                    }
                  
                }
                System.debug(String.valueOf(accVsProductList.get(iteratedAcc)));
                singleAccountListWrapperRec.product = finalProductString;
                //singleAccountListWrapperRec.product = accVsProducts.get(iteratedAcc);//accIdVsProduct.get(iteratedACHDId);
                accountListWrapper.add(singleAccountListWrapperRec);
                
            }
          
        }
        }catch(Exception e)
        {
            System.debug('Exception occured  :: ' + e.getMessage());
            string setEmailSub          = 'Exception: In execute method of SC_PSAutomationController.';
            string errorMessage         = 'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' + 'Class Name = SC_PSAutomationController\n' +'Method Name = getMappedAccounts\n';
            errorMessage               += e.getCause()+' .. '+e.getLineNumber()+' .. '+e.getMessage()+' .. '+e.getTypeName()+' .. '+e.getStackTraceString();
            SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support();
            sc_COBSupportCls.senEmailForError(setEmailSub, errorMessage);  
        } 
     
        
        System.debug('accountListWrapper**'+accountListWrapper);
        return JSON.serialize(accountListWrapper);
    }

 
    // Method 3 : Method to create Customer mailer records
    @AuraEnabled
    public static String createRecords (String emailDetailStr,String mailerName,String instructions,String accountsList,String audienceType,List<String> products,String files,Boolean isPublish){
        //Method level variables
        PS_Customer_Mailers__c parentRec = new PS_Customer_Mailers__c();
        List<PS_Customer_Mailers__c> childRecs = new List<PS_Customer_Mailers__c>();
        PS_Customer_Mailers__c childRecInstance;
        String allAccountsName = '';
        String allProductsName = '';
        List<Attachment> attachmentsToUpload = new List<Attachment>();
        List<ContentVersion> cvToUpload = new List<ContentVersion>();
        List<Id> contentVersionIdList = new List<Id>();
        List<Id> contentDocIdList = new List<Id>();
        ContentVersion cv = new ContentVersion();
        ContentDocumentLink conDocLink = new ContentDocumentLink();
        List<ContentDocumentLink> conDocLinkList = new List<ContentDocumentLink>();
        List<Account> accList = new List<Account>();
        returnWrapperClass returnWrapperClassInstance = new returnWrapperClass();
        returnWrapperClassInstance.accVsMailerRecMap = new Map<String,String>();
        EmailWrapper emailDetails = (EmailWrapper) JSON.deserialize(emailDetailStr, EmailWrapper.class);
        List<fileClass> filesToUpload = new List<fileClass> ();
        if(files != null){
            filesToUpload = (List<fileClass> ) JSON.deserialize(files, fileClass[].class);
        }
        
        List<targetAccountWrapperClass> targetAccountWrapperRecs = (List<SC_PSAutomationController.targetAccountWrapperClass> )JSON.deserialize(accountsList, SC_PSAutomationController.targetAccountWrapperClass[].class);
        List<String> finalCCAddress = new List<String>();
        String finalBody = '';
        String subject = '';
        messaging.SingleEmailMessage mailerInstance;

        //Concatenating all account names
        for(targetAccountWrapperClass iteratedAccountRecs : targetAccountWrapperRecs){
            allAccountsName = allAccountsName + iteratedAccountRecs.Name+','; 
          
        }
        //Concatenating all product names
        for(String iteratedProd : products){
            allProductsName = allProductsName + iteratedProd+';'; 
        }
        System.debug('products**'+products);
        //Parent customer mailer record
        parentRec.Account_List__c = allAccountsName;
        parentRec.Audience_Type__c = audienceType;
        parentRec.Is_Master_Record__c = true;
        parentRec.Instructions__c = instructions;
        parentRec.Product_Name__c = allProductsName;
        parentRec.PS_Customer_Mailer_Name__c = mailerName;
        parentRec.Subject__c = emailDetails.subject;
        parentRec.Content__c = emailDetails.body;
        if(isPublish){
            parentRec.Publish_Date__c = Datetime.now();
        }
        parentRec.RecordTypeId = Schema.SObjectType.PS_Customer_Mailers__c.getRecordTypeInfosByName().get('Security Bulletin').getRecordTypeId();
        Insert parentRec;
        //File insert
        if(filesToUpload != null && filesToUpload.size() > 0){
            for(fileClass itrFileToUpload : filesToUpload){
           
            cv = new ContentVersion();
            cv.ContentLocation = 'S';
          
            cv.VersionData = EncodingUtil.base64Decode(itrFileToUpload.base64);
            cv.PathOnClient = itrFileToUpload.fileName;
            cv.title = itrFileToUpload.fileName;
            cvToUpload.add(cv);
            }
        }
        if(cvToUpload.size() > 0){
            insert cvToUpload;
            for(ContentVersion itrcv : cvToUpload){
                contentVersionIdList.add(itrcv.Id);
            }

            List<ContentVersion> conDoc = [SELECT ContentDocumentId FROM ContentVersion WHERE Id IN:contentVersionIdList];
            for(ContentVersion itrcv1 : conDoc){
                
                //create ContentDocumentLink  record 
                conDocLink = New ContentDocumentLink();
                conDocLink.LinkedEntityId = parentRec.Id; // Specify RECORD ID here i.e Any Object ID (Standard Object/Custom Object)
                conDocLink.ContentDocumentId = itrcv1.ContentDocumentId;  //ContentDocumentId Id from ContentVersion
                conDocLink.shareType = 'V';
                conDocLinkList.add(conDocLink);
            }
            if(conDocLinkList.size() > 0){
                insert conDocLinkList;
            }
        }

        //If publish scenario , sending mail for master mailer and creating child mailer records.
        if(isPublish){
            //Master rec mail
            if(emailDetails.ccAddress.size() > 0 || emailDetails.dlList.size() > 0 ){
                if(emailDetails.ccAddress.size() > 0)
                finalCCAddress.addAll(emailDetails.ccAddress);
                if(emailDetails.dlList.size() > 0)
                finalCCAddress.addAll(emailDetails.dlList);

                finalBody = '';
                finalBody = 'Hi,<br/><br/>Please have a look at Master Customer mailer record created at <a href="'+System.URL.getSalesforceBaseUrl().toExternalForm()+'/'+parentRec.Id+'">Link</a>.<br/><br/><b><u>Instructions :</u></b><br/><b>'+emailDetails.Instruction+'</b><br/><br/><b><u>Content :</u></b><br/>'+emailDetails.body+'<br/><br/>Thanks,<br/>PS Automation Team.';
                //finalBody = 'Hi,<br/><br/>Please have a look at Master Customer mailer record created at <a href="'+System.URL.getSalesforceBaseUrl().toExternalForm()+'/'+parentRec.Id+'">Link</a>.<br/><br/><b><u>Content :</u></b><br/>'+emailDetails.body+'<br/><br/><b><u>Instructions :</u></b><br/><b>'+emailDetails.Instruction+'</b><br/><br/>Thanks,<br/>PS Automation Team.';
                subject = 'New Security Bulletin Record Created by '+UserInfo.getFirstName()+' '+UserInfo.getLastName()+'-'+emailDetails.subject;
                mailerInstance = mailerInstanceCreationMethod(finalCCAddress,subject,finalBody,parentRec.Id,null);
                Messaging.sendEmail(new List<messaging.SingleEmailMessage>{mailerInstance});
            }
            SC_PSAutomationController_BatchJob asyncJob= new SC_PSAutomationController_BatchJob(parentRec.Id,emailDetailStr,accountsList,audienceType,instructions,mailerName,files,isPublish);
            Database.executeBatch(asyncJob,10);
        }    
        
        return parentRec.Id;
    }

   
    
    // Method 4 : Method to send emails to account owners for missing SSP team members. 
    @AuraEnabled
    public static void sendEmailForMissingTeamMember(String accountList){
      
        SC_PSAutomationController_BatchJob asyncJob= new SC_PSAutomationController_BatchJob(accountList,true);
        Database.executeBatch(asyncJob,10);
        
      
    }


    // Method 4 : Method for sending test email. 
    @AuraEnabled
    public static void sendEmailControllerForMailer(String emailDetailStr,Id parentRecId,Map<String,String> accMailerMap,String accountList) {
        EmailWrapper emailDetails = (EmailWrapper) JSON.deserialize(emailDetailStr, EmailWrapper.class);
        Messaging.reserveSingleEmailCapacity(1);
        String body = emailDetails.body;
        String subject = '';
        String finalBody = '';
        List<String> finalCCAddress = new List<String>();
        List<messaging.SingleEmailMessage> finalMailerList = new List<messaging.SingleEmailMessage>();
        messaging.SingleEmailMessage mailerInstance;
        try {
           
            List<Attachment> attachList = new List<Attachment>();
           /* if(parentRecId != null){
                attachList =  [Select Id,Name,Body from Attachment where ParentId=:parentRecId limit 1]; 
            }*/
            List<targetAccountWrapperClass> targetAccountWrapperRecs = (List<SC_PSAutomationController.targetAccountWrapperClass> )JSON.deserialize(accountList, SC_PSAutomationController.targetAccountWrapperClass[].class);
            
                subject = 'Customer Mailer Record Created for Account: <Sample Account Name>'+emailDetails.subject; 
                finalBody = '<b style="color:red"><i>This is a test email.</i></b><br/><br/>Hi,<br/><br/>Please have a look at Customer mailer record created for Account :  <a href="">Sample Link</a>.<br/><br/><b><u>Instructions :</u></b><br/><b>'+emailDetails.Instruction+'</b><br/><br/><b><u>Content :</u></b><br/>'+body+'<br/><br/>Thanks,<br/>PS Automation Team.';
                //finalBody = '<b style="color:red"><i>This is a test email.</i></b><br/><br/>Hi,<br/><br/>Please have a look at Customer mailer record created for Account : <b><i><Sample Account Name><i></b> at <a href="">Sample Link</a>.<br/><br/><b><u>Instructions :</u></b><br/><b>'+emailDetails.Instruction+'</b><br/><br/><b><u>Content :</u></b><br/>'+body+'<br/><br/>Thanks,<br/>PS Automation Team.';
                //finalBody = '<b style="color:red"><i>This is a test email.</i></b><br/><br/>Hi,<br/><br/>Please have a look at Customer mailer record created for Account : <b><i><Sample Account Name><i></b> at <a href="">Sample Link</a>.<br/><br/><b><u>Content :</u></b><br/>'+body+'<br/><br/><b><u>Instructions :</u></b><br/><b>'+emailDetails.Instruction+'</b><br/><br/>Thanks,<br/>PS Automation Team.';
                mailerInstance = mailerInstanceCreationMethod(new List<String>{UserInfo.getUserEmail()},subject,finalBody,null,null);
                finalMailerList.add(mailerInstance);
               
            if(finalMailerList.size() > 0){
                Messaging.sendEmail(finalMailerList);
            }
           
        } catch (exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    // Method 5 : Reusable method to create mailer instance. 
    public static messaging.SingleEmailMessage mailerInstanceCreationMethod(List<String> toAddress , String Subject ,String body,String whatId,List<Attachment> attachList ){
        messaging.SingleEmailMessage mail = new messaging.SingleEmailMessage();
        mail.setToAddresses(toAddress);
       // mail.setSenderDisplayName('Fathima Tehzeeb <frs@akamai.com>');
       mail.setSenderDisplayName(UserInfo.getFirstName()+' '+UserInfo.getLastName());
        mail.setSubject(Subject);
        mail.setHtmlBody(body);
        if(whatId != '' && whatId != null){
        mail.setWhatId(whatId);
        mail.setSaveAsActivity(true);
        }
        
        if(attachList != null && attachList.size() > 0){
            List<Messaging.EmailFileAttachment> attachmemnts = new List<Messaging.EmailFileAttachment>();
        Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
        efa.setFileName(attachList[0].Name);
        efa.setBody(attachList[0].body);
        attachmemnts.add(efa);
        mail.setFileAttachments(attachmemnts);
        }
        
        return mail;

    }


    //Below Added by Ashin on Apr26 2022
    Public Class itemsForSendingEmailsWrapper {
        
        public map<String, List<targetAccountWrapperClass>> memberVsApplicableAccountsMap;
        public Map < String, list<PS_Customer_Mailers__c>> AccountsVsChildMailers ;
        public EmailWrapper emailDetails;
        public string instructions;
        public list<messaging.SingleEmailMessage> mailerList;
        public string mailerListStr;
        public string masterRecContent;

    }
    //Above added by Ashin

    //Below Added by Ashin on Apr29 2022
    Public Class itemsForSendingRemindersWrapper {
        
        public map<Id,PS_Customer_Mailers__c> AccountVsMailerToProcessForSC;
        public string ChildMailerId;
        public PS_Customer_Mailers__c childMailers;
        public List<string> ToUserId;

    }
    //Above added by Ashin

    //Below Added by Ashin on Apr29
    public class memberVsChildmailerWrapper
    {
        public string MemberId;
        public List<PS_Customer_Mailers__c> childMailers;
    }
    //Above Added by Ashin on Apr29
    
    //Below added by Ashin
    public class itemsForReminderManagerEmails
    {
       public Map<String, list<String>> ManagerVsTeammemberName;
       public map<String, list<PS_Customer_Mailers__c>> managerVsMailers;
       public Map < Id, User > userMap;  
    }
    //Above added by Ashin

  
    //Email wrapper class
    Public Class EmailWrapper {
        public List<String> toAddress;
        public List<String> ccAddress;
        public List<String> dlList;
        public String subject;
        public String body;
        public List<String> files;
        public String Instruction;

    }

    //Init wrapper class to store applicable account details.
    Class AccountListWrapper {
        public Account accountRec;
        public Map<String,AccountTeamMember> memberVsEmail;
        public String ownerId;
        public String product;
       
       
    }

    //Wrapper class to process for creating Customer mailer records.
    Public Class targetAccountWrapperClass {
        public String Id;
        public String Name;
        public String Geography;
        public String Product;
        public String TeamMember;
        public Map<String,AccountTeamMember> TeamMemberMap;
        public String ownerId;
        public String colour;
       
    }

    //Batch class wrapper for iterable
    Public Class publishBatchClassWrapper {
        public String Id;
        public String products;
        //public String accountName; //Added by Ashin as per ESESP - 6983 2.a
    }

    class returnWrapperClass{
        public String masterRecId;
        public Map<String,String> accVsMailerRecMap;
    }

    //Files wrapper class
    Public class fileClass{
        public String fileName;
        public Long fileSize;
        public String base64;
    }


    //Method 6 : Method to validate if Master Mailer record can be published after created as draft.
    @AuraEnabled
    public static String validateToPublishMasterMailer(String recId){
        publishWrapper publishWrapperRec = new publishWrapper();
        PS_Customer_Mailers__c recDetail = [Select Id,Is_Master_Record__c,Publish_Date__c from PS_Customer_Mailers__c where Id =:recId limit 1];
        // Checking only master mailer records can be published
        if(recDetail.Is_Master_Record__c){
            publishWrapperRec.isMasterRecord = true;
        }else{
            publishWrapperRec.isMasterRecord = false;
        }
        //Checking if record is already published.
        if(recDetail.Publish_Date__c != null){
            publishWrapperRec.isPublished = true;
        }else{
            publishWrapperRec.isPublished = false;
        }
        //Checking if current user has required access.
        List<PermissionSetAssignment> psas = [ select Id from PermissionSetAssignment where PermissionSetId IN ( select Id from PermissionSet where Name = 'PSCustomerMailerCreatePermission') and AssigneeId =: UserInfo.getUserId() ];
        if(psas != null && psas.size() > 0){
            publishWrapperRec.validUserToPublish = true;
        }else{
            publishWrapperRec.validUserToPublish = false;
        }
        return JSON.serialize(publishWrapperRec);
    }

    //Method 7: Method runs on Publish buttin click on Master Customer Mailer record. 
    @AuraEnabled
    public static void publishMasterMailer(Id recId){
        //Method level variables
        List<String> toAddress = new List<String>();
        String finalBody = '';
        String subject = '';
        messaging.SingleEmailMessage mailerInstance = new messaging.SingleEmailMessage ();
        
        PS_Customer_Mailers__c masterRec = [Select Id,Publish_Date__c,Subject__c,Content__c,Instructions__c from PS_Customer_Mailers__c where Id=:recId limit 1];
       
        // Sending Email to Internal Admin DL for Master mailer publish
        PS_Automation_Admin_DL__c internalDLRec = [Select Id,DL_Email_Address__c from PS_Automation_Admin_DL__c where recordType.Name = 'Internal' limit 1];
                toAddress = internalDLRec.DL_Email_Address__c.split(',');
                finalBody = 'Hi,<br/><br/>Please have a look at Master Customer mailer record created at <a href="'+System.URL.getSalesforceBaseUrl().toExternalForm()+'/'+recId+'">Link</a>.<br/><br/><b><u>Instructions :</u></b><br/><b>'+masterRec.Instructions__c+'</b><br/><br/><b><u>Content :</u></b><br/>'+masterRec.Content__c+'<br/><br/>Thanks,<br/>PS Automation Team.';
                //finalBody = 'Hi,<br/><br/>Please have a look at Master Customer mailer record created at <a href="'+System.URL.getSalesforceBaseUrl().toExternalForm()+'/'+recId+'">Link</a>.<br/><br/><b><u>Content :</u></b><br/>'+masterRec.Content__c+'<br/><br/><b><u>Instructions :</u></b><br/><b>'+masterRec.Instructions__c+'</b><br/><br/>Thanks,<br/>PS Automation Team.';
                subject = 'New Security Bulletin Record Created by '+UserInfo.getFirstName()+' '+UserInfo.getLastName()+'-'+masterRec.Subject__c;
                mailerInstance = mailerInstanceCreationMethod(toAddress,subject,finalBody,recId,null);
                Messaging.sendEmail(new List<messaging.SingleEmailMessage>{mailerInstance});

        // Updating Publish date on master mailer record 
       
        masterRec.Publish_Date__c = Datetime.now();
        update masterRec;
        
        //Running batch class to create child customer mailer recs and notify SSP team members.
        SC_PSAutomationController_PublishBatch asyncJob= new SC_PSAutomationController_PublishBatch(recId);
        Database.executeBatch(asyncJob,10);
    }    



    Public class publishWrapper{
        public Boolean isMasterRecord;
        public Boolean isPublished;
        public Boolean validUserToPublish;
    }


   


}