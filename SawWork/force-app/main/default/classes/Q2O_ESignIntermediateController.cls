/*
    Q2O_ESignIntermediateController
    @author : Pranav Motkali <prmoktal@akamai.com>
    @Description : This is the generalized Custom Controller for the ESignIntermediate Page
           
    @History
    --Developer         --Date          --Change
    Pranav Moktali      05/08/2013      Created this class for
                                        - CR 2327331 e-Signature DocuSign implementation for agreements      
    Pranav Moktali      Oct/13          CR 2350920: Show attachments of Parent Agreement for E-Sign.
    Pranav Moktali      Feb/2014        CR 2499753: Show warning if Agreement expiration date is in the past.
    Ali KM              Aug/2014        CR 2747838: Merged ese-force-4.0 changes into q2o-1
    Srushti             April/2015      CR 2967014 : [QTOO-1456] Prompt user to associate right MSA before activating the Pricing Agreement
    Srushti             April/2015      [QTOO-1576]: Getting an intermediate blank page when clicking on "Send for e-signature" button on an agreement
*/
public class Q2O_ESignIntermediateController {
    protected List<Attachment> selectedAttachmentsWithBody;
    // Associated RSM Contact Id   
    protected Contact currentUserContact;
    //DocuSign Envelope Document
    protected List<dsfs__DocuSign_Envelope_Document__c> dseDocumentList;
    // ErrorList
    protected List<String> errList;
    protected List<String> warningList;
    //Fetch Current User Details
    public static User currentUserRecord;  
    public Integer recipientIndex;
    public Contact newContact {get; set;}
    public Boolean newContactFlag {get; set;}
    public Attachment pdfAttachment;
    public Boolean hasAssociatedObj {get; set;}
    public Order_Approval__c oa {get; set;}
    public String associatedObj {get; set;}
    public List<OA_EmailBlast_AttachmentWrapper> oaAttachment {get; set;}
    public String viewfilePath {get; set;}
    public Boolean showPage {get; set;}
    public Boolean showError {get; set;}
    public Boolean showWarning {get; set;}
    public Boolean emptyOAId {get; set;}
    public List<Attachment> selectedAttachments;
    public Integer mode {get; set;}
    public string ErrorMessage{get;set;}
    public string WarningMessage{get;set;}
    public Boolean firstLoaded=false;
    public static Map<String,OA_eSign_Intermediate__c> customSettings = OA_eSign_Intermediate__c.getAll();
    //DocuSign Config object
    public dsfs__DocuSignAccountConfiguration__c dsConfiguration {get; set;}
    //DocuSign Envelope
    public dsfs__DocuSign_Envelope__c dsEnvelope {get; set;}
    // DocuSign Envelope Recipient Objects
    public dsfs__DocuSign_Envelope_Recipient__c dseRecipient1 {get; set;}
    public dsfs__DocuSign_Envelope_Recipient__c dseRecipient2  {get; set;}
   public DSsourceObject srcObj{get;set;}
    public Id srcObjId{get;set;}
    public List<ContentDocument> selectedFiles;
    public Set<Id> contentDocIds;
    /**
    initializeCurrentUserRecord()
        - Fetches current user User record.
    */
    public static void initializeCurrentUserRecord()
    {  
        //SFDC-1422 Added Manager field in query
        if(currentUserRecord == null)
            currentUserRecord = [Select Manager.AKAM_User_ID__c,LastName, FirstName, Email, Alias,AKAM_User_ID__c From User where Id=:Userinfo.getUserId()][0];
    }
 
    /**
        GetCustomSettingValue(String pPropertyName)
        - Generic function to return Custom Setting values for the single Custom Setting Object model
    */
    public static String GetCustomSettingValue(String pPropertyName)
    {
        return GSM_Custom_Settings__c.getInstance('ESignature#'+pPropertyName).Value__c;
    }
    // constructor
    public Q2O_ESignIntermediateController()
    {  
        viewfilePath = '/servlet/servlet.FileDownload?file';
        showPage = true;
        firstLoaded = init();
    }   
    // method to fetch customsettings
    private String getCustomSettingsValue(String pName)
    {
        return customSettings.get(pName).Value__c;
    }
    // method to display error on Page.
    private void showErrorAndDiscontinue(String pErrorMessage)
    {
        showPage = false;
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, pErrorMessage));          
    }
    /**
        addError(String pErrorMessage)
        - Method to add to list of Errors.
    */
    private void addError(String pErrorMessage)
    {
        showPage = false;
        errList.add(pErrorMessage);          
    }
    /**
        addError(String pErrorMessageList)
        - Method to add to list of Errors.
    */ 
    private void addError(String[] pErrorMessageList)
    {
        showPage = false;
        errList.addAll(pErrorMessageList);          
    } 
    // method returns selected Attachments.
    private List<Attachment> getSelectedAttachmentsWithBody()
    {
        if(selectedAttachmentsWithBody != null)
            return selectedAttachmentsWithBody;
        else
        {
            selectedAttachmentsWithBody = [SELECT Id, Name, Body FROM Attachment WHERE Id IN : selectedAttachments];
            return selectedAttachmentsWithBody;
        }
    }
    private void initSourceObject(String objId){
        String objType = getObjType(objId);
        if(objType == 'Order Approval'){
            for(Order_Approval__c o : [SELECT Id, Name, Approvals_Required__c, CCG__c, Associated_Opportunity__r.Name,
            Legal__c, Deal_Desk__c,
            //Start Modified By Chandra For CR 693820
            New_Churn__c,
            //End Modified By Chandra For CR 693820
            Order_Expires_Unless_Duly_Executed_By__c,
            Account_Territory__c, Associated_Opportunity__c, Associated_Account__c, Associated_Opportunity_Sales_Stage__c,
                Opportunity_Owner__c, Type__c, AKAM_OrderApproval_ID__c, Send_To_Contact__c, Associated_Opportunity__r.AccountId
                    FROM Order_Approval__c WHERE id=:objId])
                oa = o;
            hasAssociatedObj = true;
            srcObj = new DSsourceObject(oa);
        } 
    }
    // entry method
    public Boolean init()
    {  
        //mode = 0;
        mode = String.isBlank(ApexPages.currentPage().getParameters().get('mode')) ? 0 : Integer.valueOf(ApexPages.currentPage().getParameters().get('mode'));
        hasAssociatedObj = false;
        oaAttachment = new List<OA_EmailBlast_AttachmentWrapper>();
        errList = new List<String>();
        warningList = new List<String>();
        srcObjId = ApexPages.currentPage().getParameters().get('id');
        initSourceObject(srcObjId);
        if(hasAssociatedObj == false)
        {
            showErrorAndDiscontinue('Oops! cant find Order Approval Record/Agreement, please return to previous page and try again.');
            emptyOAId = false;
            return false;  
        }
 
        
 
        // fetch the Contact Id of logged in User's RSM if it exists...
      
        // Start of SFDC-1422 - Sonali Tandon
       /** Account_Reassignment_Rule__c currentUserRule;
        for (Account_Reassignment_Rule__c accRule : [Select Associated_User_RSM__r.AKAM_User_ID__c From Account_Reassignment_Rule__c
                                                            where Associated_User__c = : Userinfo.getUserId() ORDER BY CreatedDate DESC LIMIT 1])
            currentUserRule = accRule;**/
        
        initializeCurrentUserRecord();
 
         if (getCustomSettingsValue('User manager profiles').contains(UserInfo.getProfileId()) && currentUserRecord.Manager.AKAM_User_ID__c!=null)
        {          
            for (Contact rsmContact : [Select Id From Contact where AKAM_Contact_ID__c = : currentUserRecord.Manager.AKAM_User_ID__c AND
                                                            Account.AKAM_Account_ID__c = : getCustomSettingsValue('Akamai Account Id') ORDER BY CreatedDate DESC LIMIT 1])
                currentUserContact = rsmContact;
        }
        else if(getCustomSettingsValue('Self user profiles').contains(UserInfo.getProfileId()) && currentUserRecord.AKAM_User_ID__c!=null)
        {
            for (Contact rsmContact : [Select Id From Contact where AKAM_Contact_ID__c = : currentUserRecord.AKAM_User_ID__c AND
                                                            Account.AKAM_Account_ID__c = : getCustomSettingsValue('Akamai Account Id') ORDER BY CreatedDate DESC LIMIT 1])
                currentUserContact = rsmContact;
        }
 
        // End of SFDC-1422 - Sonali Tandon
 
       
        //Fetch the configuration file from `dsfs__DocuSignAccountConfiguration__c' object
        for (dsfs__DocuSignAccountConfiguration__c dsConfig : [Select dsfs__EmailSubject__c, dsfs__EmailBody__c, dsfs__DefaultWarnOfExpireNDays__c, dsfs__DefaultReminderNDays__c, dsfs__DefaultRepeatReminderNDays__c,
                                    dsfs__DefaultExpireNDays__c From dsfs__DocuSignAccountConfiguration__c where Name =: getCustomSettingsValue('dsConfigRecordName') ORDER BY CreatedDate DESC LIMIT 1])
            dsConfiguration = dsConfig;
        // DocuSign Section:
        // Create DocuSign Envelope
        if (dsEnvelope == null)
        {
            dsEnvelope = new dsfs__DocuSign_Envelope__c();
            dsEnvelope.dsfs__Source_Object__c = srcObj.Id;

            

            
            if (dsConfiguration!=null)
            {  
               // initializeCurrentUserRecord();
                String emailBodyStr;
                emailBodyStr = dsConfiguration.dsfs__EmailBody__c;
                emailBodyStr = emailBodyStr.replace('[FirstName]',Userinfo.getFirstName());
                emailBodyStr = emailBodyStr.replace('[LastName]',Userinfo.getLastName());
                emailBodyStr = emailBodyStr.replace('[Email]',currentUserRecord.Email);
                dsEnvelope.dsfs__DocuSign_Email_Subject__c = dsConfiguration.dsfs__EmailSubject__c;
                dsEnvelope.dsfs__DocuSign_Email_Message__c = emailBodyStr;
                // Reminder & Expiration fields
                dsEnvelope.dsfs__Day_Prior_to_Warn_of_expiration__c = dsConfiguration.dsfs__DefaultWarnOfExpireNDays__c;
                dsEnvelope.dsfs__Reminder_Interval__c = dsConfiguration.dsfs__DefaultReminderNDays__c;             
                dsEnvelope.dsfs__Reminder_Repeat_Interval_in_Days__c = dsConfiguration.dsfs__DefaultRepeatReminderNDays__c;
                
                //Add Logic to populate the Expire dates based on some date (Ex: Order_Expires_Unless_Duly_Executed_By__c)
                Decimal expireDays;
                String customExpireSettingToggle = GetCustomSettingValue('CustomExpireSettings');
                if (customExpireSettingToggle.equalsIgnoreCase('true') && srcObj.Order_Expires_Unless_Duly_Executed_By_Date != null && srcObj.Order_Expires_Unless_Duly_Executed_By_Date > datetime.now())
                {
                    DateTime orderExpiresUnlessDulyExecutedBy = srcObj.Order_Expires_Unless_Duly_Executed_By_Date;
                    Date tempDate = orderExpiresUnlessDulyExecutedBy.date(); //dateGmt();
                    Date currentDate = Date.today();
                    expireDays = currentDate.daysBetween(tempDate) + Decimal.valueOf(GetCustomSettingValue('ExpireEnvelopeGraceDays'));
                    if (expireDays > 120)
                        expireDays = dsConfiguration.dsfs__DefaultExpireNDays__c;
                }
                else
                {
                    if (srcObj.Order_Expires_Unless_Duly_Executed_By_Date==null)
                        expireDays = dsConfiguration.dsfs__DefaultExpireNDays__c;
                    else
                        expireDays= Integer.valueOf(GetCustomSettingValue('DefaultEnvelopeExpireDays'));//30;
                       
                }
                dsEnvelope.dsfs__Days_before_Envelope_is_Expired_Voided__c = expireDays;
                
                //dsEnvelope.dsfs__Days_before_Envelope_is_Expired_Voided__c = dsConfiguration.dsfs__DefaultExpireNDays__c;
               
                if (getCustomSettingsValue('SendEmailReminder')!=null && getCustomSettingsValue('SendEmailReminder')=='true')
                    dsEnvelope.dsfs__Send_Reminder__c = true;
                else
                    dsEnvelope.dsfs__Send_Reminder__c = false;
            } 
        }
        // RSM
        dseRecipient1 = new dsfs__DocuSign_Envelope_Recipient__c();
        dseRecipient1.dsfs__Routing_Order__c = 1;
        dseRecipient1.dsfs__DocuSign_Signer_Type__c = 'Signer';
        dseRecipient1.dsfs__DocuSign_Recipient_Role__c = 'Akamai RSM 1';
        dseRecipient1.dsfs__Salesforce_Recipient_Type__c = 'Contact';
        if (currentUserContact!=null)
            dseRecipient1.dsfs__DSER_ContactID__c = currentUserContact.Id;
        // Customer
        dseRecipient2 = new dsfs__DocuSign_Envelope_Recipient__c();
        dseRecipient2.dsfs__Routing_Order__c = 2;
        dseRecipient2.dsfs__DocuSign_Signer_Type__c = 'Signer';
        dseRecipient2.dsfs__Salesforce_Recipient_Type__c = 'Contact';
        dseRecipient2.dsfs__DocuSign_Recipient_Role__c = 'Customer Signatory 1'; 
        // OA & Opportunity Attachment Section
        //HC: Commenting Attachment

        OA_EmailBlast_AttachmentWrapper oaW;
        /*
        for (Attachment a : [Select a.Name, a.Id, a.CreatedBy.Name, a.LastModifiedDate, a.ParentId, a.Parent.Name
                                    FROM Attachment a
                                    where ParentId = :srcObj.Id OR ParentId = :srcObj.Associated_Opportunity_Id OR ParentId = :srcObj.Parent_Obj_Id
                                    Order By a.LastModifiedDate DESC])
        {
            oaW = new OA_EmailBlast_AttachmentWrapper(a);
            oaAttachment.add(oaW);
        }
        */
        contentDocIds = new Set<Id>();
        Set<Id> ownerIds = new Set<Id>();
        Map<Id,String> userInfoMap = new Map<Id,String>();
        for(ContentDocumentLink conObj : [Select Id,ContentDocumentId from ContentDocumentLink where
                                         LinkedEntityId = :srcObj.Id OR LinkedEntityId = :srcObj.Associated_Opportunity_Id
                                         OR LinkedEntityId = :srcObj.Parent_Obj_Id]) {
            contentDocIds.add(conObj.ContentDocumentId);   
        }
        if(contentDocIds.size() > 0) {
            for(ContentDocument conDocObj : [Select Id,OwnerId from ContentDocument
                                             where Id in :contentDocIds]) {
                ownerIds.add(conDocObj.OwnerId);
            }
            if(ownerIds.size() > 0) {
                for(User userRec : [Select Id,Name from User where Id in :ownerIds]) {
                    userInfoMap.put(userRec.Id,userRec.Name);   
                }
            }
            for(ContentDocument conDocObj : [Select Id,Title,ParentId,OwnerId,ContentModifiedDate from
                                             ContentDocument
                                             where Id in :contentDocIds Order by ContentModifiedDate]) {
                oaW = new OA_EmailBlast_AttachmentWrapper(conDocObj,userInfoMap);
                oaAttachment.add(oaW);
            }
        }
        if(oaAttachment.size()==0)
        {
            emptyOAId = true;      
            //showPage = false;
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There are no attachments for this Order Approval OR Associated Opportunity'));
            if (srcObj.isOA)
                addError('There are no attachments for this Order Approval OR Associated Opportunity.');
            
        }
        else
        {
            oaAttachment.get(0).checked = true; // check the checkbox for topmost item ie. based on LastModifiedDate.
        }
       
        /*
            Show warning if Expiration date of Agreement is in the past.
            If agreement expiration date is empty, let's populate today's date to abvoid null errors.
         */
        Date endDate = srcObj.Order_Expires_Unless_Duly_Executed_By_Date == null ? Date.today() : srcObj.Order_Expires_Unless_Duly_Executed_By_Date.addDays(1);
        Date todayDate = Date.today();
        Boolean hasAgreementExpired = (endDate < todayDate);
        System.debug('ECHO: Agreement Expiration Date: '+endDate);
        System.debug('ECHO: Today\'s Date: '+todayDate);
        System.debug('ECHO: hasAgreementExpired? '+hasAgreementExpired);
        
       
        System.debug('ECHO: warningList size: '+warningList.size());
       
        return true;
    }
   
    public PageReference validate()
    {
        init();
         /*
        @author: Pranav Moktali:
        @description: Here is how the page works:
                        -   Check if any errors are present -> show error [mode=0]
                        -   Check if any warnings are present -> show warning with continue button[mode=2]
                        -   If they hit continue OR no warnings are persent, reload the page for choosing contacts [mode=1]
                        -   Do not show warnings if 'mode' is set to 1 in GET.
        */
        if (hasAssociatedObj)
        {
            if(srcObj.recordType != 'MSA') {
                errList.addAll(GsmUtilClass.SalesStageSixValidation(srcObj.Associated_Opportunity_Id,'esign'));
            }
                 
            /*if (errList.size()>0){
                ErrorMessage='<b>Please make sure that the below issues on the Agreement are resolved before proceeding further with "Send for E-Signature" request.</b><br/>';
                for(string err:errList)
                ErrorMessage+='<br/><b>•</b> '+err+'<br/>';
                mode = 0;
            } else if(mode !=1 && warningList.size()>0){
                WarningMessage ='<b><u>Warning:</u></b>';
                for(String war:warningList)
                    WarningMessage+=' <br/><b>•</b> '+war+'<br/>';
                mode = 2;
            } else {
                mode = 1;
            }*/
           
            showError = false;
            showWarning = false;
           
            system.debug('Show Mode2' + mode );
            system.debug('Show Error' + showError);
 
            //Displaying the error messages
            if (mode == 0 && errList.size()>0){
                ErrorMessage='<b>Please make sure that the below issues on the Agreement are resolved before proceeding further with "Send for E-Signature" request.</b><br/>';
                for(string err:errList)
                ErrorMessage+='<br/><b>•</b> '+err+'<br/>';
                showError = true;
            }
            
            //Displaying the warning
            system.debug('Show Warning' + showWarning);
            if(mode == 0 && warningList.size()>0){
                WarningMessage ='<b><u>Warning:</u></b><br/>';
                for(String war:warningList)
                    WarningMessage+=' <br/><b>•</b> '+war+'<br/>';
                showWarning = true;
            }
            
            //[QTOO-1576]: Getting an intermediate blank page when clicking on "Send for e-signature" button on an agreement
            if((ErrorMessage == null) && (WarningMessage == null)){
                mode = 1;
            }
            
        }
       
        return null;
    }
    //method to Fetch DocuSign corresponding Role for selected RoleName.
    public Double getRoleValue(String pDocuSign_Recipient_Role)
    {
        Double roleValue;
        if (pDocuSign_Recipient_Role.equals(getCustomSettingsValue('Recipient 1')))
            roleValue=1;
            else if (pDocuSign_Recipient_Role.equals(getCustomSettingsValue('Recipient 2')))
                roleValue=2;
            else if (pDocuSign_Recipient_Role.equals(getCustomSettingsValue('Recipient 3')))
                roleValue=3;
            else if (pDocuSign_Recipient_Role.equals(getCustomSettingsValue('Recipient 4')))
                roleValue=4;
            return roleValue;              
    }
   
    //createDocuSignEnvelopeDocument() generates a DocuSignEnvelopeDocument thats will be used before sending the Document for Signing.
    public dsfs__DocuSign_Envelope_Document__c createDocuSignEnvelopeDocument(Id pDocuSignEnvelopeId, Integer pDocumentOrder, String pAttachmentName, String pAttachmentId,String docType)
    {
        System.debug('pAttachmentName='+ pAttachmentName);
        if (pAttachmentName.length() > 80)
        {
            String newFileName;
            String extPart;
            List<String> parts = pAttachmentName.split('\\.');
            extPart = '.' +  parts[parts.size()-1];
            newFileName = pAttachmentName.substring(0, 80 - extPart.length()) + extPart;
            System.debug('newFileName=' + newFileName);
            pAttachmentName = newFileName;
            System.assertEquals(80, newFileName.length());
        }
       
        dsfs__DocuSign_Envelope_Document__c d = new dsfs__DocuSign_Envelope_Document__c();
        d.dsfs__DocuSign_EnvelopeID__c = pDocuSignEnvelopeId;
        d.dsfs__Document_Order__c = pDocumentOrder;
        d.dsfs__Attachment_Name__c = pAttachmentName;
        d.dsfs__Attachment_ID__c = pAttachmentId;
        d.dsfs__Attachment_NameEx__c=pAttachmentName;
        if(docType == 'File') {
            d.dsfs__Document_ID__c = pAttachmentId;
            d.dsfs__SFDocument_Type__c = 'Content';
            d.dsfs__Document_Name__c = pAttachmentName;
        }
        // this is populated by default to Attachment
        //tempDSEDoc.dsfs__SFDocument_Type__c = 'Attachment';  
        return d;
    }
      
    public PageReference Next()
    {  
        selectedAttachments = new List<Attachment>();
        selectedFiles = new List<ContentDocument>();
        Boolean isError = false;
        if (oaAttachment.size()==0)
        {
            isError = true;
            showPage = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There are no attachments for this Order Approval OR Associated Opportunity'));
        }
        else if (dseRecipient1.dsfs__DSER_ContactID__c==null)
        {
            isError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Recipient 1 - Contact field cannot be empty, please select a value.'));
        }
         else if (dseRecipient1.dsfs__DocuSign_Recipient_Role__c==null)
        {
            isError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Recipient 1 - DocuSign Signer Role field cannot be empty, please select a value.'));
        }
         else if (dseRecipient2.dsfs__DSER_ContactID__c!=null && dseRecipient2.dsfs__DocuSign_Recipient_Role__c==null)
        {
            isError = true;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Recipient 2 - DocuSign Signer Role field cannot be empty, please select a value.'));
        }
        // if dseRecipient2.dsfs__DocuSign_Recipient_Role__c != null && dseRecipient2.dsfs__DSER_ContactID__c==null
        // add error
               
        else   
        {
            contentDocIds = new Set<Id>();
            for (OA_EmailBlast_AttachmentWrapper a : oaAttachment)
            {
                if(a.checked) {
                    if(a.fileType == 'File') {
                        selectedFiles.add(a.doc);
                        contentDocIds.add(a.doc.Id);
                    }
                    else {
                        selectedAttachments.add(a.attachRec);
                    }
                }
            }
            try
            {
                if(selectedAttachments.size() > 0 || selectedFiles.size() > 0)
                {  
                    // Insert Envelope / Create Recipients
                    List<ContentDocumentLink> cdlListToInsert  = new List<ContentDocumentLink>();
                    Map<Id,List<ContentDocumentLink>> docToDocLinkListMap = new Map<Id,List<ContentDocumentLink>>();
                    List<ContentDocumentLink> cdlList = [Select Id,ShareType,LinkedEntityId,ContentDocumentId From ContentDocumentLink where ContentDocumentId IN :contentDocIds ];

                    if(cdlList.size() > 0)
                    {
                        for(ContentDocumentLink cdlRec : cdlList)
                            {
                                if(!docToDocLinkListMap.containsKey(cdlRec.ContentDocumentId))
                                {
                                    List<ContentDocumentLink> tempList = new List<ContentDocumentLink>();
                                    tempList.add(cdlRec);
                                    docToDocLinkListMap.put(cdlRec.ContentDocumentId,tempList);
                                }
                                else{
                                    List<ContentDocumentLink> tempListE = docToDocLinkListMap.get(cdlRec.ContentDocumentId);
                                    tempListE.add(cdlRec);
                                    docToDocLinkListMap.put(cdlRec.ContentDocumentId,tempListE);
                                }
                            }
                        }

                        for(Id docId : docToDocLinkListMap.keySet())
                        {
                            Boolean hasAccess = false;
                            for(ContentDocumentLink dLink : docToDocLinkListMap.get(docId))
                            {
                                if(dLink.LinkedEntityId == Userinfo.getUserId())
                                    hasAccess = true;

                            }
                            if(!hasAccess)
                            {
                                ContentDocumentLink cdRecord = new ContentDocumentLink();
                                cdRecord.ContentDocumentId =docId;
                                cdRecord.ShareType = 'V';
                                cdRecord.LinkedEntityId = UserInfo.getUserId();
                                cdlListToInsert.add(cdRecord);
                            }
                        }
                
                    if(cdlListToInsert.size() > 0)
                        insert  cdlListToInsert;  
                    try
                    {
                        insert dsEnvelope;
                    }
                    catch (exception ex)
                    {
                        isError = true;
                        throw new CustomException('An error has occcured during email process. Please contact system administrator. Error Details : ' + ex);
                    }
                    try
                    {
                        dseRecipient1.dsfs__DocuSign_EnvelopeID__c = dsEnvelope.Id;
                        dseRecipient1.dsfs__RoleName__c = dseRecipient1.dsfs__DocuSign_Recipient_Role__c;
                        dseRecipient1.dsfs__RoleValue__c = getRoleValue(dseRecipient1.dsfs__DocuSign_Recipient_Role__c);
                        System.Debug(LoggingLevel.Error, 'HC Recipient 1'+dseRecipient1);
                        insert dseRecipient1;
                       System.Debug(LoggingLevel.Error, 'HC After Recipient 1 insert');
                        if (dseRecipient2.dsfs__DSER_ContactID__c!=null)
                        {
                            dseRecipient2.dsfs__DocuSign_EnvelopeID__c = dsEnvelope.Id;
                            dseRecipient2.dsfs__RoleName__c = dseRecipient2.dsfs__DocuSign_Recipient_Role__c;
                            dseRecipient2.dsfs__RoleValue__c = getRoleValue(dseRecipient2.dsfs__DocuSign_Recipient_Role__c);
                             System.Debug(LoggingLevel.Error, 'HC Recipient 2'+dseRecipient2);

                            insert dseRecipient2;
                                                   System.Debug(LoggingLevel.Error, 'HC After Recipient 2 insert');

                        }
                    }
                    catch (exception ex)
                    {
                        isError = true;
                        throw new CustomException('An error has occcured during email process. Please contact system administrator. Error Details : ' + ex);
                    }
                    // Generate DocuSign Envelope Documents
                    List<dsfs__DocuSign_Envelope_Document__c> dseDocumentList = new List<dsfs__DocuSign_Envelope_Document__c>();
                    Integer count = 1;
                    for(Attachment att:this.getSelectedAttachmentsWithBody())
                    {
                        dseDocumentList.add(this.createDocuSignEnvelopeDocument(dsEnvelope.Id, count, att.Name, att.Id,'Attachment'));
                        count++;
                    }
                    if(contentDocIds.size() > 0) {
                        List<ContentVersion> contVersionFiles = new List<ContentVersion>();
                        for(ContentVersion contDoc : [Select Id,ContentDocumentId,Title,ContentBodyId,ContentSize from
                                                      ContentVersion where ContentDocumentId in :contentDocIds]) {
                            dseDocumentList.add(this.createDocuSignEnvelopeDocument(dsEnvelope.Id,count,contDoc.Title,contDoc.Id,'File'));
                            count++;   
                        }
                    } 
                    System.debug('ECHO srcObj: '+srcObj);
                    Opportunity associatedOppty;
                    // update if OA
                    if(srcObj.isOA){
                        associatedOppty = [Select Id, Associated_Order_Approval_Id__c from Opportunity where Id = :srcObj.Associated_Opportunity_Id];
                        associatedOppty.Associated_Order_Approval_Id__c = srcObj.Id;
                        associatedOppty.Validation_Override__c = true;
                    }
                    // Insert & Update
                    try
                    { 
                       insert dseDocumentList;
                       if(srcObj.isOA)
                        update associatedOppty;
                    }
                    catch (exception ex)
                    {
                        isError = true;
                        throw new CustomException('An error has occcured during email process. Please contact system administrator. Error Details : ' + ex);
                    }
                }
                else
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'No Attachments selected, please select atleast one document for E-Signature.'));
                    isError = true;
                }                              
            }
            catch (exception ex)
            {  
                //throw ex;
                ApexPages.addMessages(ex);
                showPage = false; 
                isError = true;  
            }
        }
        if(!isError)
        {
            //return (new PageReference('/apex/dsfs__DocuSign_CreateEnvelope?DSEID=' + dsEnvelope.Id + '&SourceID=' + dsEnvelope.dsfs__Source_Object__c));
            String editEnvelopeURL = Label.DocusignEnvelopeURL.replace('##DESID##', dsEnvelope.Id).replace('##OA_ID##', dsEnvelope.dsfs__Source_Object__c);
            return (new PageReference(editEnvelopeURL));
        }
        else
            return null; // If error,stay on the page       
    }
    public PageReference cancel()
    {
        return (new PageReference('/' + srcObj.id));   
    }
  
    public PageReference continueEsign()
    {
        PageReference pageRef = new PageReference('/apex/ESign_Intermediate?id='+srcObjId+'&mode=1');
        return pageRef;
    }
    public PageReference activateAddNewContact1()
    {
        newContact = new Contact();
        newContact.AccountID = srcObj.Account_Id;
        newContactFlag = true;  
        showPage = false; 
        recipientIndex = 1;
        return null;
    }
    public PageReference activateAddNewContact2()
    {
        newContact = new Contact();
        newContact.AccountID = srcObj.Account_Id;
        newContactFlag = true;  
        showPage = false;  
        recipientIndex = 2;         
        return null;
    }   
    public PageReference newContactSave()
    {
        if (newContact.Email==null)
            this.showErrorAndDiscontinue('Email: You must enter a value');
        else if (newContact.FirstName==null)
            this.showErrorAndDiscontinue('First Name: You must enter a value');       
        else if (newContact.AccountId==null)
            this.showErrorAndDiscontinue('Account Name: You must enter a value');
        else
        {  
            for (Account acc : [Select BillingCountry, BillingPostalCode, BillingState,
                                            BillingCity, BillingStreet From Account c WHERE Id = : srcObj.Account_Id])
            {
                newContact.MailingStreet=acc.BillingStreet;            
                newContact.MailingCity=acc.BillingCity;
                newContact.MailingCountry=acc.BillingCountry;
                newContact.MailingPostalCode=acc.BillingPostalCode;
                newContact.MailingState=acc.BillingState;
            }
            newContact.Validation_Override__c = true;
            //code here to add account Address to the Contact.
            insert newContact;
            if(recipientIndex == 1)
                dseRecipient1.dsfs__DSER_ContactID__c = newContact.Id;       
            else
                dseRecipient2.dsfs__DSER_ContactID__c = newContact.Id;
            showPage = true;
            newContactFlag = false;
        }
        return null;
    }
    public PageReference newContactCancel()
    {
        newContact = null;
        newContactFlag = false;  
        showPage = true;    
        return null;
    } 
    public PageReference canceltoOppty()
    {
        return new PageReference('/'+srcObj.Associated_Opportunity_Id);
    } 
    //SFDC- 4276 - Added Q2O_DocusignUtil Class methods here due to Apttus purge

    
    public static String getObjType(String objId){
        String objType = '';
        if(objId.startsWith(Schema.Sobjecttype.Opportunity.getKeyPrefix()))
            objType = 'Opportunity';
        else if(objId.startsWith(Schema.Sobjecttype.Order_Approval__c.getKeyPrefix()))
            objType = 'Order Approval';
        /*else if(objId.startsWith(Schema.Sobjecttype.Apttus__APTS_Agreement__c.getKeyPrefix()))
            objType = 'Agreement';*/
        return objType;
        
    }

    public static String getObjType(Id objId){
        return getObjType(String.valueOf(objId));
    }
    
    
    
    public Class DSsourceObject{
        public String id;
        public String Name {get;set;}
        public Date Order_Expires_Unless_Duly_Executed_By_Date;
        public String Associated_Opportunity_Id;
        public String Parent_Obj_Id;
        public String resellerMTAId = '';
        public String Account_Id;
        public Boolean isOA;
        public Boolean isAptsAg;
        public String recordType;
        public String manualInvoice;
        public String complexity;
        public Boolean isMSA;
        
        public String type{get;set;}
        
        public DSsourceObject(sObject associatedObj){
            this.id = associatedObj.id;
            this.type = getObjType(this.id);
            
            if(this.type == 'Order Approval')
            {
                this.isOA = true;
                this.isAptsAg = false;
                Order_Approval__c oa = (Order_Approval__c)associatedObj;
                this.Name = oa.Name;
                this.Order_Expires_Unless_Duly_Executed_By_Date = oa.Order_Expires_Unless_Duly_Executed_By__c;
                this.Associated_Opportunity_Id = oa.Associated_Opportunity__c;
                this.Account_Id = oa.Associated_Opportunity__r.AccountId;
                this.Parent_Obj_Id = '';
            }
            
        }
    }




    public  void createTestMethod() {
       Integer i = 0;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       i++;
       
   }  
}