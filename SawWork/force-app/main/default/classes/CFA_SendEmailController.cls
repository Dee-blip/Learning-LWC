/**
   CFA_SendEmailController
    @author : Vinayendra T N <vintara@akamai.com>
    @Description : This is the controller class for the CFA_SendEmail
    This class is used by PAE to send the CAF attachment.
    @History
    --Developer           --Date            --Change
    Vinayendra T N       3/2011             CR 1135360 Implement Partner Order Acceptance
                                            - Created VF for PAE to send the CAf attachment
    Vinayendra T N               7/2011                         CR 1225381 Discard the old document under POA section on Oppty
                                                                                - When a new document is sent the old document status as rejected.
        Vinayendra T N           11/2011                        CR 1360082 PRM: POA - Add partner contact to sales team
                                                                                        - Add partner to sales team with Edit permission
        Ali KM                            24/08/2012            CR 1864342 - Exception - POA Document attachment Name too long.
                                                                                        -> trimming attachment name to 80 chars.
        Nagaraj Desai            14 Feb 2018                    MOB-350 -> refactor code to be compatible with SF1

        Nagaraj Desai             14 December 2018               SFDC-3953 -> Attachment Migration to Files

        Ambica                    2 sept 2021                    SFDC-8819  -> Replace MRR__c <0 with MRR Type as LMRR for ProjectWinvalidation

        Harsh Pandey             24 Feb 2022                     SFDC-8568  -> Replaced error logging method with new method to capture record Id as well.
 */
public class CFA_SendEmailController {
        public string viewfilePath {get; set;}
        public string PartnerEmail {get; set;}
        public string PartnerCcEmail {get; set;}
        public string EmailSubject {get; set;}
        public string EmailBody {get; set;}
        public boolean showPage {get; set;}
        public Boolean firstLoaded=false;
        public List<OA_EmailBlast_AttachmentWrapper> oaAttachment {get; set;}
        public List<OA_EmailBlast_AttachmentWrapper> TNCDocs {get; set;}
        public Order_Approval__c oa {get; set;}
        public Integer mode {get; set;}
        public Opportunity opp {get; set;}
        public string BodyOfEmail;
        public string htmlBodyOfEmail {get; set;}
        public string ErrorMessage {get; set;}
        public string topErrorMessage {get; set;}
        public String contactName {get; set;}
        public Set<String> POA_Email_list=new Set<String>();
        public list<id> POA_id=new list<id>();
        private PageReference pageRef;
        private String orderApprovalId;// MOB-350 changes: added orderApprovalId
        public String userTheme; // MOB-350 changes: store user Theme
        public String returnMessageJSON_ForSF1;// MOB-350 changes: store Error & Success Messages
        public transient List<Messaging.EmailFileAttachment> fileAttachments; // List of attachments to be send for POA
        //private User usr;
        //private string SfURL =GSM_Custom_Settings__c.getInstance('CFA_SendEmailController#SfUrl').Value__c;// 'https://akamai--GSM.cs9.my.salesforce.com/secur/login_portal.jsp?orgId=00DK00000004Xnj&portalId=060A0000000HX9f'+'&startURL=';
        private string SfURL='';
        public static L2Q_ZOFF_Feature__mdt  zoffmdtValue = ZoffUtilClass.getZOFFmdtsetting('ZOFF');  //Rajesh - SFDC-7061
    
        private List<ContentDocumentLink> cdlList;
        //SFDC-7239 - start
        public Boolean isAutonomyNotificationApproved {get; set;}
        public Boolean showAutonomyApprovalButton {get; set;}
    
        //SFDC-7398
        transient private Savepoint savePoint_Main;
    
        public void AutonomyNotificationApproved() {
            isAutonomyNotificationApproved = true;
            showAutonomyApprovalButton = false;
            showPage = true;
            PageReference pg = validate();
        }
    
        public void showNotificationAndDiscontinue(String message) 
        {
                showAutonomyApprovalButton = true;
                if(userTheme != null && userTheme == 'fromSF1') {
                        this.returnMessageJSON_ForSF1 = resultSetCustom(true, message);
                        return;
                }
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.INFO, message));
        }
    
        
        public PageReference selectTNCDoc()
        {
            
            Id fileId = ApexPages.currentPage().getParameters().get('fileId');
            System.debug(LoggingLevel.Error, 'AGH_D Entered tnc doc selection block'+fileId);
            for(OA_EmailBlast_AttachmentWrapper oa: TNCDocs)
            {
                oa.checked=(oa.fileId.equalsIgnoreCase(fileId));
            }
            return null;
        }
        //SFDC-7239 - end
    
        public CFA_SendEmailController()
        {
                isAutonomyNotificationApproved = false;
                showAutonomyApprovalButton = false;
                viewfilePath = '/servlet/servlet.FileDownload?file';
                showPage = true;
                this.orderApprovalId = ApexPages.currentPage().getParameters().get('id'); // MOB-350 changes: added orderApprovalId instead of ApexPages.currentPage().getParameters().get('id') to reuse from SF1 and lightning
                firstLoaded=init();
        }
    
        public static String resultSetCustom(Boolean errorOccured, String returnMessage) { // MOB-350 changes: added a method to construct a JSON Returnable for SF1
    
                Map<String,String> mapObject = new Map<String,String>();
                if(errorOccured != null) {
                        mapObject.put('errorOccured', String.valueOf(errorOccured));
                }
                if(returnMessage != null) {
                        mapObject.put('returnMessage', returnMessage);
                }
    
                return JSON.serialize(mapObject);
        }
    
        public CFA_SendEmailController(Id orderApprovalId, String userTheme) { // MOB-350 changes: added CFA_SendEmailController(Id orderApprovalId) for constructing an object from SF1_SendForOrderAcceptance
                isAutonomyNotificationApproved = false;
                showAutonomyApprovalButton = false;
                this.userTheme = userTheme;
                this.orderApprovalId = orderApprovalId;
                this.returnMessageJSON_ForSF1 = resultSetCustom(false, 'None');
                firstLoaded = init();
        }
    
        private void showErrorAndDiscontinue(String pErrorMessage) // MOB-350 changes: changed the function to handle ApexPage.addMessage() errors when called from SF1
        {
                if(userTheme != null && userTheme == 'fromSF1') {
                        this.returnMessageJSON_ForSF1 = resultSetCustom(true, pErrorMessage);
                        return;
                }
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, pErrorMessage));
        }
        public boolean init()
        {
     
                mode=0;
                PartnerCcEmail='';
                topErrorMessage=Label.CFA_SendEmailController_Top_Error_Message;
                List<String> zoffvalidapprType = zoffmdtValue.Opportunity_Type_Appr__c.split(',');
                List<String> webVerticalForZOFF = GsmUtilClass.getGSMSettingValue('Web_Vertical_For_ZOFF').split(',');
                List<String> webSubVerticalForZOFF = GsmUtilClass.getGSMSettingValue('Zoff_Sub_Vetical_For_Web_HighTech').split(',');
                if(SfURL=='')
                {
                        SfURL=[select Fax from Organization limit 1][0].Fax;
                        if (Test.isRunningTest()) {
                                SfURL= GsmUtilClass.getGSMSettingValue('CFA_SendEmailController_SfUrl');
                        }
                }
                //usr = [select Name from User where id=:Userinfo.getUserId()][0];
                oaAttachment = new List<OA_EmailBlast_AttachmentWrapper>();
                // Get the order approval record
                for(Order_Approval__c o : [SELECT Id, Name,Associated_Opportunity__c,Associated_Opportunity__r.Account.Name, Associated_Opportunity__r.Deal_Type__c,Associated_Opportunity__r.Partner_Involved__c,Associated_Opportunity__r.Partner_Involved__r.Name,Associated_Opportunity__r.Partner_Involved__r.POA_Email_List__c,Associated_Opportunity__r.Partner_Involved__r.ParentId, Associated_Opportunity__r.Owner.Email,Associated_Opportunity__r.IsClosed , Associated_Opportunity__r.ZOFF_Approval__C ,Associated_Opportunity__r.Opt_Out_Reason__c ,Associated_Opportunity__r.ZOFF_Enabled__c ,Associated_Opportunity__r.ZOFF_Status__c,Associated_Opportunity__r.Account_Division__c, Associated_Opportunity__r.Associated_Account_Vertical__c, Associated_Opportunity__r.Associated_Account_Sub_Vertical__c, Associated_Opportunity__r.Opportunity_Type__C,Associated_Opportunity__r.RecordType.DeveloperName, Associated_Opportunity__r.Autonomy_Status__c,Associated_Opportunity__r.Source__C,
                                           Associated_Opportunity__r.MRR__c,Associated_Opportunity__r.Account_MRR_Type__c,Associated_Opportunity__r.oc_source__c,Associated_Opportunity__r.Opportunity_Category__c,Associated_Opportunity__r.Loss_Reason__c, Associated_Opportunity__r.Competitor__c , Associated_Opportunity__r.Partner_Involved__r.Partner_Type__c, Associated_Opportunity__r.Account.T_Cs_Signed__c,
                                            Associated_Opportunity__r.Account.ECUSTOMS__RPS_Status__c,Associated_Opportunity__r.Account.Override_Visual_Compliance__c
                                            FROM Order_Approval__c WHERE id =: orderApprovalId]) //Rajesh SFDC-7061 Added ZOFF related field// MOB-350 changes: added orderApprovalId instead of ApexPages.currentPage().getParameters().get('id') to reuse from SF1 and lightning
                        oa = o;
                //SFDC-6741
                User currentUserRecord = [SELECT Id, UserPermissionsSFContentUser, Isactive,Profile.Name FROM User Where Id = :UserInfo.getUserId()];
                if(!currentUserRecord.UserPermissionsSFContentUser) {
                        showErrorAndDiscontinue(GSMSettings.getValue('CFA_SendEmailNoCRMContentPermissionError'));
                        showPage = false;
                        return false;
                }
                //End of SFDC-6741
                if(oa == null)
                {
                        showErrorAndDiscontinue('Oops! cant find the Order Approval record, please return to previous page and try again.');
                        showPage = false;
                        return false;
                }
                //SFDC-6364 - VC Validations
                else if(('Akamai_Opportunity'.equalsIgnoreCase(oa.Associated_Opportunity__r.RecordType.DeveloperName)) && GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Status_Red').split(',').contains(oa.Associated_Opportunity__r.Account.ECUSTOMS__RPS_Status__c) && !oa.Associated_Opportunity__r.Account.Override_Visual_Compliance__c )
                        {
                            showErrorAndDiscontinue('<br/><b>•</b> &nbsp;&nbsp;' + GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Check_Red') + '<br/>');
                            showPage = false;
                            return false;
                        }
                else if(('Akamai_Opportunity'.equalsIgnoreCase(oa.Associated_Opportunity__r.RecordType.DeveloperName)) && GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Status_Pending').split(',').contains(oa.Associated_Opportunity__r.Account.ECUSTOMS__RPS_Status__c) && !oa.Associated_Opportunity__r.Account.Override_Visual_Compliance__c)
                        {
                            showErrorAndDiscontinue('<br/><b>•</b> &nbsp;&nbsp;' + GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Check_Pending') + '<br/>');
                            showPage = false;
                            return false;
                        }
                else if(('Akamai_Opportunity'.equalsIgnoreCase(oa.Associated_Opportunity__r.RecordType.DeveloperName)) && GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Status_DS_Alert').split(',').contains(oa.Associated_Opportunity__r.Account.ECUSTOMS__RPS_Status__c) )
                        {
                            showErrorAndDiscontinue('<br/><b>•</b> &nbsp;&nbsp;' + GsmUtilClass.getGSMSettingValue('Visual_Compliance_Field_Check_DS_Alert') + '<br/>');
                            showPage = false;
                            return false;
                        }
                // Begin Rajesh SFDC-7061 // Throw error for web account when account division is web and not approved
                // System.debug('oa.Associated_Opportunity__r.Deal_Type__c=='+oa.Associated_Opportunity__r.Deal_Type__c + '==='+oa.Associated_Opportunity__r.Partner_Involved__r.Name);// to remove 
                else if( oa.Associated_Opportunity__r.Source__C != 'Azure Marketplace'  &&   'Akamai_Opportunity'.equalsIgnoreCase(oa.Associated_Opportunity__r.RecordType.DeveloperName) &&  zoffmdtValue.Feature_Enabled__c && zoffmdtValue.Toggle6SignedValidation__c &&  ZoffUtilClass.listcontainsIgnorcase(zoffvalidapprType,oa.Associated_Opportunity__r.Opportunity_Type__C) && (webVerticalForZOFF.contains(oa.Associated_Opportunity__r.Associated_Account_Vertical__c) || (oa.Associated_Opportunity__r.Associated_Account_Vertical__c == 'High Technology' && webSubVerticalForZOFF.contains(oa.Associated_Opportunity__r.Associated_Account_Sub_Vertical__c))) && !oa.Associated_Opportunity__r.IsClosed && oa.Associated_Opportunity__r.ZOFF_Enabled__c && ((String.isEmpty(oa.Associated_Opportunity__r.ZOFF_Status__c )) || ('No'.equalsIgnorecase(oa.Associated_Opportunity__r.ZOFF_Status__c) && !('Approved'.equalsIgnorecase(oa.Associated_Opportunity__r.ZOFF_Approval__c) ||  'Approval Overridden'.equalsIgnorecase(oa.Associated_Opportunity__r.ZOFF_Approval__c) ) )) )
                {
                    showErrorAndDiscontinue('Associated opportunity should either have ZOFF status Yes OR ZOFF approved when ZOFF status is NO.');
                    showPage = false;
                    return false;
                }
               // End Rajesh SFDC-7061
                else if(oa.Associated_Opportunity__r.Partner_Involved__r.Name==null)
                {
                        showErrorAndDiscontinue('Oops! Partner Involved is blank for the related opportunity.');
                        showPage = false;
                        return false;
                }
    
                else if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('IsChannelsPassthroughEnabled') && oa.Associated_Opportunity__r.Partner_Involved__r.Partner_Type__c.equalsIgnoreCase('Associate Partner') && !oa.Associated_Opportunity__r.Account.T_Cs_Signed__c)
                {
                        cdlList = [SELECT Id, ContentDocumentId, ContentDocument.LatestPublishedVersionId, ContentDocument.LatestPublishedVersion.Title, ContentDocument.LatestPublishedVersion.FileExtension, ContentDocument.LastModifiedDate, ContentDocument.CreatedBy.Name, LinkedEntityId, LinkedEntity.Type FROM ContentDocumentLink WHERE LinkedEntityId = :oa.Id AND ContentDocumentLink.ContentDocument.LatestPublishedVersion.Tag__c LIKE :GSMSettings.getValue('Passthrough_TC')];
                        if(cdlList.isEmpty()) {
                                showErrorAndDiscontinue('Please upload the T&C Document using ‘Upload T&C’ button, as it’s mandatory for an Associate Partner, while sending the Order form.');
                                showPage = false;
                                return false;
                        }
                        TNCDocs = new List<OA_EmailBlast_AttachmentWrapper>();
                        Integer count=1;
                        for(ContentDocumentLink eachCDL : cdlList) {
                                OA_EmailBlast_AttachmentWrapper oaw = new OA_EmailBlast_AttachmentWrapper(eachCDL);
                                oaw.checked=(count==cdlList.size());
                                count++;
                                System.Debug(LoggingLevel.Error, 'AGH_D is it checked'+oaw.checked);
                                TNCDocs.add(oaw);        
                        }

                }
    
                else if(oa.Associated_Opportunity__r.Deal_Type__c != 'Indirect'){
                        showErrorAndDiscontinue('The Account is not a Partner Account');
                        showPage = false;
                        return false;
                }
    
                //SFDC-7239 - start
                else if(oa.Associated_Opportunity__r.Autonomy_Status__c != null && oa.Associated_Opportunity__r.Autonomy_Status__c == 'Ordered'){
                    showErrorAndDiscontinue(GSMSettings.getValue('POA_AutonomyStatusInOrderedError'));
                    showPage = false;
                    return false;
                }
                else if(!isAutonomyNotificationApproved && oa.Associated_Opportunity__r.Autonomy_Status__c != null && oa.Associated_Opportunity__r.Autonomy_Status__c == 'In-Progress') {
                    showNotificationAndDiscontinue(GSMSettings.getValue('POA_AutonomyStatusInProgressError'));
                    showPage = false;
                    return false;
                }
                //SFDC-7239 - end
                //SFDC-8273 -Project Win Competitor and Loss Reason Validation

                else if((oa.Associated_Opportunity__r.Opportunity_Category__c == null || oa.Associated_Opportunity__r.Loss_Reason__c == null) &&  ('LMRR'.equalsIgnoreCase(oa.Associated_Opportunity__r.Account_MRR_Type__c))&& ('Akamai_Opportunity'.equalsIgnoreCase(oa.Associated_Opportunity__r.RecordType.DeveloperName)) && oa.Associated_Opportunity__r.oc_source__c !='Marketplace' && oa.Associated_Opportunity__r.Opportunity_Type__c !='Auto-Renewal'){
                    showErrorAndDiscontinue(GsmUtilClass.getGSMSettingValue('ProjectWinValidationError'));
                    showPage = false;
                    return false;
                    }
                else if(oa.Associated_Opportunity__r.Competitor__c  == null && ('Akamai_Opportunity'.equalsIgnoreCase(oa.Associated_Opportunity__r.RecordType.DeveloperName)) && oa.Associated_Opportunity__r.oc_source__c !='Azure Marketplace' && oa.Associated_Opportunity__r.Opportunity_Type__c !='Auto-Renewal' && oa.Associated_Opportunity__r.Opportunity_Type__c !='Contract Change' &&  oa.Associated_Opportunity__r.Source__c != 'Marketplace' &&
                        currentUserRecord.Profile.Name !='Business Operations' &&
                        currentUserRecord.Profile.Name !='CRM Integration' &&
                        currentUserRecord.Profile.Name !='CRM Integration 2.0' &&
                        currentUserRecord.Profile.Name !='Mulesoft Integration' &&
                        currentUserRecord.Profile.Name !='Mulesoft Integration v1'){
                    showErrorAndDiscontinue(GsmUtilClass.getGSMSettingValue('ProjectWinValidationCompetitiveError'));
                    showPage = false;
                    return false;
                    }
                //SFDC-7398 - do not allow to create POA if logged in user doesn't have write access on Order Approval
                else if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('POA_OA_EditPermissionErrorToggle') && !GsmUtilClass.isFeatureToggleEnabledCustomMetadata('useDuplicateFilesFOrPOA') && !Order_Approval__c.SObjectType.getDescribe().isUpdateable()) {
                    showErrorAndDiscontinue(GsmUtilClass.getGSMSettingValue('POA_NoWitePermissionFor_OA_Error'));
                    showPage = false;
                    return false;
                }
                //SFDC-7398 - End
    
                // get body and subject from email template
                EmailTemplate em=[select Body,Subject from EmailTemplate where DeveloperName=:GsmUtilClass.getGSMSettingValue('CFA_SendEmailController_EmailPartner')][0];//'CAF_Email_to_partner'][0];
                //Since template is a text template, replace \n with <br/> to make it html
                emailSubject=em.Subject;
                emailBody=em.Body.replace('\n','<br/>');
                emailSubject=emailSubject.replaceAll('#PartnerInvolved#',oa.Associated_Opportunity__r.Partner_Involved__r.Name );
                emailSubject=emailSubject.replaceAll('#Oppty_Acc#',oa.Associated_Opportunity__r.Account.Name );
                emailBody=emailBody.replaceAll('#PAE#',Userinfo.getName() );
                opp= new Opportunity(id=oa.Associated_Opportunity__c);
                //Find all partner who are in the oppty sales team.
                list<OpportunityTeamMember> oppteammems = new list<OpportunityTeamMember>();
                for(OpportunityTeamMember otmmem:[select id,User.Email,User.Name,User.contactId,User.Contact.Name from OpportunityTeamMember where OpportunityId=:oa.Associated_Opportunity__c and TeamMemberRole='Partner' and User.Email!=null])
                        oppteammems.add(otmmem);
                //PartnerEmail+=otmmem.User.Email+',';
                // If more than 1 parnter are present in sales team, add them to CC.
                if(oppteammems.size()>1 || Test.isRunningTest())
                {
                        integer count=1;
                        for(OpportunityTeamMember otmmem:oppteammems)
                        {
                                if(count==1)
                                {
                                        opp.CFA_To__c=otmmem.User.contactid;
                                        contactName=otmmem.User.Contact.Name;
                                }
                                else
                                        PartnerCcEmail+=otmmem.User.Email+',';
                                POA_Email_list.add(otmmem.User.Name);
                                count++;
                        }
                        if(PartnerCcEmail!='')
                                PartnerCcEmail=PartnerCcEmail.substring(0,PartnerCcEmail.length()-1);
                }
                if(oppteammems.size()==1)
                {
                        opp.CFA_To__c=oppteammems[0].User.contactid;
                        contactName=oppteammems[0].User.Contact.Name;
                }
                //if(PartnerEmail!='')
                //PartnerEmail=PartnerEmail.substring(0,PartnerEmail.length()-1);
                //SFDC-3953
                List<ContentDocumentLink> listOfContentDocumentLink = [SELECT ContentDocumentId, ContentDocument.LatestPublishedVersionId, ContentDocument.LatestPublishedVersion.Title, ContentDocument.LatestPublishedVersion.FileExtension, ContentDocument.LastModifiedDate, ContentDocument.CreatedBy.Name, LinkedEntityId, LinkedEntity.Type FROM ContentDocumentLink WHERE (LinkedEntityId = :oa.Id OR LinkedEntityId = :oa.Associated_Opportunity__c) AND (NOT ContentDocumentLink.ContentDocument.LatestPublishedVersion.Tag__c LIKE :GSMSettings.getValue('Passthrough_TC'))];
                //SFDC-3953
                for(ContentDocumentLink eachcontentDocumentLink : listOfContentDocumentLink) {
                        oaAttachment.add(new OA_EmailBlast_AttachmentWrapper(eachcontentDocumentLink));
                }
    
                if(oaAttachment.size()==0)
                {
                        showPage = false;
                        showErrorAndDiscontinue('There are no attached files for this Order Approval');
                        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'There are no attachments for this Order Approval'));
                }
                else
                        oaAttachment[0].checked=true;
                return null;
        }
        public PageReference validate()
        {
                init();
                if(showpage==false)
                        return null;
    
                list<string> ErrorList=GsmUtilClass.SalesStageSixValidation(oa.Associated_Opportunity__c);
    
                if(ErrorList.size()>0)
                {
                        ErrorMessage='<b>'+Label.CFA_SendEmailController_Top_Error_Message+'</b><br/>';
                        for(string err:ErrorList)
                                ErrorMessage+='<br/><b>•</b> '+err+'<br/>';
    
                        //ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, err));
                        return null;
                }
                /*Savepoint SPss6 = Database.setSavepoint();
                   opp.StageName='6-Signed';
                   try{
                        update opp;
                   }
                   catch(System.DmlException e)
                   {
                        for (Integer i = 0; i < e.getNumDml(); i++)
                             {
                                 if(e.getDmlType(i) == Statuscode.FIELD_CUSTOM_VALIDATION_EXCEPTION ||e.getDmlType(i) == Statuscode.FIELD_INTEGRITY_EXCEPTION)
                                 {
                                     ApexPages.Message errMsg = new ApexPages.Message(ApexPages.Severity.ERROR, e.getDmlMessage(i));
                                     ApexPages.addMessage(errMsg);
    
                                 }
                                 else
                                {
                                    throw e;
                                }
                             }
                             return null;
                   }
                   catch(Exception e)
                   {
                    pageRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
                   }
                   Database.rollback(SPss6);*/
    
                mode=1;
                return null;
        }
        public boolean Preview()
        {
                //throw new CustomException ('CFA_To : '+opp.CFA_To__c+' Name: '+contactName);
                mode=2;
                BodyOfEmail=EmailBody;
    
                Integer count=0;
                string link = GsmUtilClass.getGSMSettingValue('CFA_SendEmailController_EmailLinkTop');//'<br/>Click on the link(s) below to accept: <br/>';
                for (OA_EmailBlast_AttachmentWrapper a : oaAttachment)
                {
    
                        if(a.checked)
                        {
                                count++;
                                link += '<br/><a href="'+SfURL+'/apex/CFA_ConfirmAttachment?id=">'+SfURL+'/apex/CFA_ConfirmAttachment?id=</a><br/>';
                        }
                }
                if(count==0)
                {
                        showErrorAndDiscontinue('Please select atleast one attachment.');
                        mode=1;
                        return null;
                }
                if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('IsChannelsPassthroughEnabled') && oa.Associated_Opportunity__r.Partner_Involved__r.Partner_Type__c.equalsIgnoreCase('Associate Partner') && !oa.Associated_Opportunity__r.Account.T_Cs_Signed__c)
                {
                    count = 0;
                    for (OA_EmailBlast_AttachmentWrapper a : TNCDocs)
                    {

                        if(a.checked)
                        {
                            count++;
                            //link += '<br/><a href="'+SfURL+'/apex/CFA_ConfirmAttachment?id=">'+SfURL+'/apex/CFA_ConfirmAttachment?id=</a><br/>';
                        }
                    }
                    if(count==0)
                    {
                        showErrorAndDiscontinue('Please select a T&C Document, which is required for an Associate Partner, while sending the Order Form.');
                        mode=1;
                        return null;
                    }
                }
                if(opp.CFA_To__c==null)
                {
                        showErrorAndDiscontinue('Please select a Partner User in "To" field.'); mode=1; return null;
                }
                Contact con= null;
                for(Contact c:[select id,Active_Partner__c,Can_Accept_POA__c,Accountid, Name from Contact where id=:opp.CFA_To__c])
                {
                        //throw new CustomException ('CFA_To : '+opp.CFA_To__c+' Can_Accept_POA__c: '+c.Can_Accept_POA__c+' Active_Partner__c:'+ c.Active_Partner__c);
                        if(c.Active_Partner__c==true && (c.Accountid==oa.Associated_Opportunity__r.Partner_Involved__c || c.Accountid==oa.Associated_Opportunity__r.Partner_Involved__r.ParentId)
                           && c.Can_Accept_POA__c =='Yes') {
                                POA_Email_list.add(c.Name);
                                con=c;
                        }
                }
                if(con==null)
                {
                        showErrorAndDiscontinue(GsmUtilClass.getGSMSettingValue('PartnerProfile_InvalidConToError'));
                        mode=1;
                        return null;
                }
                System.debug('Mailing list: '+POA_Email_list);
                BodyOfEmail+=link;
                String emailHeader=GsmUtilClass.getGSMSettingValue('CFA_SendEmailController_EmailHeader');
                String emailfooter=GsmUtilClass.getGSMSettingValue('CFA_SendEmailController_Emailfooter');
                htmlBodyOfEmail=emailHeader+BodyOfEmail+emailfooter;
                //htmlBodyOfEmail='<table border="0" width="600"><tr><td><img src="http://wwwns.akamai.com/images/net_alliance_logo_white.jpg" alt="Company Logo" border="0"/><br/>'+BodyOfEmail+'<br/><img src="http://wwwns.akamai.com/images/akamai_footer.jpg" alt="Company Footer" width="100%"  border="0"/></td></tr></table>';
                return null;
        }
        public Boolean BeforeSend() {
            //SFDC-7398
            savePoint_Main = Database.setSavepoint(); //revert back all the transactions if an exception occurs
    
            BodyOfEmail = EmailBody;
            // Get all the old documents
            list<Partner_Order_Acceptance_Document__c> poadInactivate = new list<Partner_Order_Acceptance_Document__c>();
            for(Partner_Order_Acceptance_Document__c poa : [select id,Order_Acceptance_Status__c from Partner_Order_Acceptance_Document__c where Opportunity__c=:oa.Associated_Opportunity__c and Order_Acceptance_Status__c = 'Pending Acceptance']) {
                    poa.Order_Acceptance_Status__c = 'Voided'; poa.Validation_Override__c = true; poadInactivate.add(poa);
                    //POA_id.add(poa.id);
            }
            //System.debug(POA_id);
            System.debug('poadInactivate   '+poadInactivate);
            Set<String> attachmentId = new Set<String>();
            //SFDC-3953
            list<ContentDocument> attBeforeSend = new list<ContentDocument>();
            string link = GsmUtilClass.getGSMSettingValue('CFA_SendEmailController_EmailLinkTop');//'<br/>Click on the link(s) below to accept: <br/>';
            for (OA_EmailBlast_AttachmentWrapper a : oaAttachment) {
                    if(a.checked) {
                            attachmentId.add(a.Attach.ContentDocumentId);
                    }
            }
            //SFDC-3953
            for (ContentDocument eachContentDocument : [SELECT LatestPublishedVersionId, LatestPublishedVersion.Title, LatestPublishedVersion.PathOnClient, LatestPublishedVersion.FileExtension, LatestPublishedVersion.VersionData, LastModifiedDate FROM ContentDocument WHERE Id IN :attachmentId]) {
                    attBeforeSend.add(eachContentDocument);
            }
            list<Partner_Order_Acceptance_Document__c> insertPOAD = new list<Partner_Order_Acceptance_Document__c>();
    
            //SFDC-7398
            if(!GsmUtilClass.isFeatureToggleEnabledCustomMetadata('useDuplicateFilesFOrPOA')) {
                    fileAttachments = new List<Messaging.EmailFileAttachment>();
            }
            
            Set<String> setOfDistinctPoads = new Set<String>();//SFDC-7665
            //SFDC-3953
            for(ContentDocument at: attBeforeSend ) {
                    Partner_Order_Acceptance_Document__c poad= new Partner_Order_Acceptance_Document__c();
                    //SFDC-5408
                    String fileName = at.LatestPublishedVersion.Title;
                    if(fileName.contains('.') && fileName.substringAfterLast('.') != at.LatestPublishedVersion.FileExtension){
                        fileName += '.' + at.LatestPublishedVersion.FileExtension; 
                    } else if(!fileName.contains('.')){
                        fileName += '.' + at.LatestPublishedVersion.FileExtension;
                    }
                    poad.Name = trimName(fileName);
                    //poad.Name=trimName(at.LatestPublishedVersion.Title);
                    poad.Opportunity__c = oa.Associated_Opportunity__c;
                    poad.Order_Acceptance_Status__c = 'Pending Acceptance';
                    poad.Validation_Override__c = true;
    
                    //SFDC-7398
                    if(!GsmUtilClass.isFeatureToggleEnabledCustomMetadata('useDuplicateFilesFOrPOA')) {
                            poad.Attachment__c = at.LatestPublishedVersionId;
                            poad.ContenDocumentId__c = at.Id;
    
                            link += '<br/><a href="' + SfURL + '/apex/CFA_ConfirmAttachment?id=' + at.LatestPublishedVersionId + '">' + SfURL + '/apex/CFA_ConfirmAttachment?id=' + at.LatestPublishedVersionId + '</a><br/>';
                            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                            attach.setFileName(at.LatestPublishedVersion.PathOnClient);
                            attach.setInline(false);
                            attach.Body = at.LatestPublishedVersion.Versiondata;
                            system.debug('Attachment:' + attach);
                            fileAttachments.add(attach);
    
                    }
    
                    //SFDC-7665
                    if(poad.ContenDocumentId__c != null && !setOfDistinctPoads.contains(String.valueOf(poad.ContenDocumentId__c))) {
                            insertPOAD.add(poad);
                            setOfDistinctPoads.add(poad.ContenDocumentId__c);
                    }
            }
    
            try {
                    //SFDC-7665
                    if(insertPOAD.size() > 0) {
                        insert insertPOAD;
                        //SFDC-7862 Start
                        String listOfPoadId = '';
                        for(Partner_Order_Acceptance_Document__c eachPoad : insertPOAD) {
                                listOfPoadId += eachPoad.Id + ',';
                        }
                        String InsertMessage = 'POAD Ids inserted : ' + listOfPoadId + ' Created By : ' + UserInfo.getUserId();
                        Error_log__c captureInsertLogs = new Error_log__c(Name = 'CFA_SendEmailController POAD Insert Logs', Class__c = 'CFA_SendEmailController', Error_Message__c = InsertMessage);
                        insert captureInsertLogs;
                        //SFDC-7862 End
                    }
                    //SFDC-7398
                    if(!GsmUtilClass.isFeatureToggleEnabledCustomMetadata('useDuplicateFilesFOrPOA')) {
                            List<ContentDocumentLink> listOfCDLs = new List<ContentDocumentLink>();
                            List<ContentVersionAttribute__c> listOfContentVersionAttributes = new List<ContentVersionAttribute__c>();
                            Integer counter = 0;
                            for(Partner_Order_Acceptance_Document__c eachPOA : insertPOAD) {
                                listOfCDLs.add(L2Q_ContentDocumentUtilClass.setContentDocumentLink(attBeforeSend.get(counter).Id, eachPOA.Id, 'I', 'AllUsers'));
                                listOfContentVersionAttributes.add(L2Q_ContentDocumentUtilClass.setContentVersionAttribute(attBeforeSend.get(counter).LatestPublishedVersionId, 'Partner Account', oa.Associated_Opportunity__r.Partner_Involved__c));

                                if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('IsChannelsPassthroughEnabled') && oa.Associated_Opportunity__r.Partner_Involved__r.Partner_Type__c.equalsIgnoreCase('Associate Partner') && !oa.Associated_Opportunity__r.Account.T_Cs_Signed__c){ 
                                    for (OA_EmailBlast_AttachmentWrapper a : TNCDocs) {
                                        if(a.checked) {
                                            listOfCDLs.add(L2Q_ContentDocumentUtilClass.setContentDocumentLink(a.attach.ContentDocumentId, eachPOA.Id, 'I', 'AllUsers'));   
                                            listOfContentVersionAttributes.add(L2Q_ContentDocumentUtilClass.setContentVersionAttribute(a.attach.ContentDocument.LatestPublishedVersionId, 'Partner Account', oa.Associated_Opportunity__r.Partner_Involved__c));
                                        }
                                    }
                                }
                                counter++;
                            }
                            if(listOfCDLs.size() > 0) {
                                    insert listOfCDLs;
                            }
                            if(listOfContentVersionAttributes.size() > 0) {
                                    insert listOfContentVersionAttributes;
                            }
                    }
            }
            catch(Exception e) {
                    System.DEBUG(LoggingLevel.ERROR, 'ND_D Debug 1 : ' + String.valueOf(e));
    
                    if(userTheme != null && userTheme == 'fromSF1') { // MOB-350 changes: display errors according to user Theme
                            returnMessageJSON_ForSF1 = resultSetCustom(true, String.valueOf(e));
                    }
                    else {
                            //pageRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
                            pageRef = Page.Exception;
                    }
                    //SFDC-7398 - add check for duplicate CVA
                    if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('useRevertSavePointFOrPOA')) {
                            Database.rollback(savePoint_Main);
                    }
                    //SFDC - 8568 New error logging method
                    Sawyer.saw(e,oa.Id,emailListString(POA_Email_list)); return false;
            }
            Integer count = 0;
            //SFDC-7398
            if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('useDuplicateFilesFOrPOA') || Test.isRunningTest()) {
                //SFDC-3953
                list<ContentVersion> listOfContentVersions = new list<ContentVersion>();
                for(Partner_Order_Acceptance_Document__c PoadId : insertPOAD) {
                        POA_id.add(PoadId.id);
                        //SFDC-3953
                        String title = trimName(attBeforeSend.get(count).LatestPublishedVersion.Title);
                        if(attBeforeSend.get(count).LatestPublishedVersion.FileExtension != null && attBeforeSend.get(count).LatestPublishedVersion.FileExtension != '') {
                                title += '.' + attBeforeSend.get(count).LatestPublishedVersion.FileExtension;
                        }
                        ContentVersion newContentVersion = L2Q_ContentDocumentUtilClass.setContentVersion('S', title, trimName(attBeforeSend.get(count).LatestPublishedVersion.Title), attBeforeSend.get(count).LatestPublishedVersion.VersionData);
                        listOfContentVersions.add(newContentVersion);
                        count++;
                }
                //SFDC-3953
                Map<Id, ContentVersion> mapOfIdVsInsertedListOfContentVersions;
                count = 0;
                try {
                        insert listOfContentVersions;
                        mapOfIdVsInsertedListOfContentVersions = new Map<Id, ContentVersion>([SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =: listOfContentVersions]);
                        List<ContentDocumentLink> listOfContentDocumentLinks = new List<ContentDocumentLink>();
                        List<ContentWorkspaceDoc> listOfContentWorkspaceDoc = new List<ContentWorkspaceDoc>();
                        List<ContentVersionAttribute__c> listOfContentVersionAttributes = new List<ContentVersionAttribute__c>();
                        Id contentWorkspaceId = Id.valueOf(GSMSettings.getValue('PartnerFacingFilesLibraryId'));
                        for(ContentVersion eachContentVersion : listOfContentVersions) {
                                listOfContentDocumentLinks.add(L2Q_ContentDocumentUtilClass.setContentDocumentLink(mapOfIdVsInsertedListOfContentVersions.get(eachContentVersion.Id).ContentDocumentId, POA_id.get(count++), 'I', 'AllUsers'));
                                listOfContentWorkspaceDoc.add(L2Q_ContentDocumentUtilClass.setContentWorkspaceDoc(contentWorkspaceId, mapOfIdVsInsertedListOfContentVersions.get(eachContentVersion.Id).ContentDocumentId));
                                listOfContentVersionAttributes.add(L2Q_ContentDocumentUtilClass.setContentVersionAttribute(eachContentVersion.Id, 'Partner Account', oa.Associated_Opportunity__r.Partner_Involved__c));
                        }
                        insert listOfContentDocumentLinks;
                        insert listOfContentVersionAttributes;
                        //SFDC-6265
                        if(!GsmUtilClass.isFeatureToggleEnabledCustomMetadata('PartnerFileAccessByContentDeliveries')) {
                            insert listOfContentWorkspaceDoc;
                        }
                }
                catch(Exception e)
                {
                        if(userTheme != null && userTheme == 'fromSF1') { // MOB-350 changes: display errors according to user Theme
                                returnMessageJSON_ForSF1 = resultSetCustom(true, String.valueOf(e));
                        }
                        else {
                            //pageRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
                            pageRef = Page.Exception;
                        }
                        //SFDC-7398
                        if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('useRevertSavePointFOrPOA')) {
                            Database.rollback(savePoint_Main);
                        }
                        //SFDC - 8568
                        Sawyer.saw(e,oa.Id,emailListString(POA_Email_list)); return false;
                }
                count = 0;
                fileAttachments = new List<Messaging.EmailFileAttachment>();
                //SFDC-3953
                for(ContentVersion eachContentVersion: listOfContentVersions) {
                        insertPOAD.get(count).Attachment__c = eachContentVersion.Id;
                        insertPOAD.get(count).ContenDocumentId__c = mapOfIdVsInsertedListOfContentVersions.get(eachContentVersion.Id).ContentDocumentId;//SFDC-7295
                        insertPOAD.get(count).Validation_Override__c = true;
                        count++;
                        link += '<br/><a href="'+SfURL + '/apex/CFA_ConfirmAttachment?id=' + eachContentVersion.Id + '">' + SfURL + '/apex/CFA_ConfirmAttachment?id=' + eachContentVersion.Id + '</a><br/>';
                        //SFDC-5989
                        Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                        attach.setFileName(eachContentVersion.PathOnClient);
                        attach.setInline(false);
                        attach.Body = eachContentVersion.Versiondata;
                        system.debug('Attachment:'+attach);
                        fileAttachments.add(attach);
                }
                try {
                        update insertPOAD;
                }
                catch(Exception e)
                {
                        if(userTheme != null && userTheme == 'fromSF1') { // MOB-350 changes: display errors according to user Theme
                                returnMessageJSON_ForSF1 = resultSetCustom(true, String.valueOf(e));
                        }
                        else {
                            //pageRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
                            pageRef = Page.Exception;
                        }
                        //SFDC-7398
                        if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('useRevertSavePointFOrPOA')) {
                            Database.rollback(savePoint_Main);
                        }
                        //SFDC - 8568
                        Sawyer.saw(e,oa.Id,emailListString(POA_Email_list)); return false;
                }
            }
    
    
            System.debug('fileAttachments:' + fileAttachments);
            // Make all the old document status as rejected
            if(poadInactivate.size() > 0) {
                    try {
                            update poadInactivate;
                    }
                    catch(Exception e) {
                            System.Debug('Errored during POAD Inactivation');
    
                            if(userTheme != null && userTheme == 'fromSF1') { // MOB-350 changes: display errors according to user Theme
                                    returnMessageJSON_ForSF1 = resultSetCustom(true, String.valueOf(e));
                            }
                            else {
                                    //pageRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
                                    pageRef = Page.Exception;
                            }
                            //SFDC-7398
                            if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('useRevertSavePointFOrPOA')) {
                                    Database.rollback(savePoint_Main);
                            }
                            //SFDC - 8568
                            Sawyer.saw(e,oa.Id,emailListString(POA_Email_list)); return false;
                    }
            }
    
            BodyOfEmail += link;
            String emailHeader = GsmUtilClass.getGSMSettingValue('CFA_SendEmailController_EmailHeader');
            String emailfooter = GsmUtilClass.getGSMSettingValue('CFA_SendEmailController_Emailfooter');
            String opptyString = GsmUtilClass.getGSMSettingValue('Opportunity_Text');
            //String opptyUrl = URL.getSalesforceBaseUrl().toExternalForm()+'/'+opp.id;
            String opptyUrl = SfURL+'/partners/'+opp.id;
            htmlBodyOfEmail = emailHeader + BodyOfEmail + '<br/><br/>' + opptyString + '<br/>' + opptyUrl + '<br/>' + emailfooter;
            //htmlBodyOfEmail='<table border="0" width="600"><tr><td><img src="http://wwwns.akamai.com/images/net_alliance_logo_white.jpg" alt="Company Logo" border="0"/><br/>'+BodyOfEmail+'<br/><img src="http://wwwns.akamai.com/images/akamai_footer.jpg" alt="Company Footer" width="100%"  border="0"/></td></tr></table>';
            return true;
    }
    
    public Pagereference SendEmail() {
        //SFDC-7398 Send Email only if there weren't any errors while creating POA
        if(BeforeSend()) {
                //create otm and tasks before sending email
                list<OpportunityTeamMember> PartnerInTeam = new list<OpportunityTeamMember>();
                //check the partner is in the sales team
                for(OpportunityTeamMember otmmem:[select id,User.Email,User.Name,User.contactId from OpportunityTeamMember where OpportunityId=:oa.Associated_Opportunity__c and TeamMemberRole='Partner' and User.contactId=:opp.CFA_To__c])
                        PartnerInTeam.add(otmmem);
                //if partner is not in the sales add the partner to sales team.
                User partnerContact=[select id from User where contactid=:opp.CFA_To__c and Isactive=true][0];
                // if not in sales team.. add them to sales team.
                if(PartnerInTeam.size()==0 || Test.isRunningTest())
                {
                        OpportunityTeamMember otmNew=new OpportunityTeamMember();
                        otmNew.OpportunityId=oa.Associated_Opportunity__c;
                        otmNew.TeamMemberRole='Partner';
                        otmNew.UserId=partnerContact.id;
                        //otmNew.Validation_Override__c = true;
                        try {
                                insert otmNew;
                        }
                        catch(Exception e)
                        {
                                if(userTheme != null && userTheme == 'fromSF1') { // MOB-350 changes: display errors according to user Theme
                                        returnMessageJSON_ForSF1 = resultSetCustom(true, String.valueOf(e));
                                }
                                else {
                                        //pageRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
                                        pageRef = Page.Exception;
                                        showErrorAndDiscontinue(e.getMessage());
                                }
                                //SFDC-7398
                                if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('useRevertSavePointFOrPOA')) {
                                        Database.rollback(savePoint_Main);
                                }
                                //SFDC - 8568
                                Sawyer.saw(e,oa.Id,emailListString(POA_Email_list));
                                return null;
                        }
                }
                //Give Edit access to the partner
                OpportunityShare osNew=new OpportunityShare();
                osNew.OpportunityAccessLevel='Edit';
                osNew.OpportunityId=oa.Associated_Opportunity__c;
                osNew.UserOrGroupId=partnerContact.id;
    
                try {
                        insert osNew;
                }
                catch(Exception e) {
                        if(userTheme != null && userTheme == 'fromSF1') { // MOB-350 changes: display errors according to user Theme
                                returnMessageJSON_ForSF1 = resultSetCustom(true, String.valueOf(e));
                        }
                        else {
                                //pageRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
                                pageRef = Page.Exception; showErrorAndDiscontinue(e.getMessage());
                        }
                        //SFDC-7398
                        if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('useRevertSavePointFOrPOA')) {
                                Database.rollback(savePoint_Main);
                        }
                        //SFDC - 8568
                        Sawyer.saw(e,oa.Id,emailListString(POA_Email_list)); return null;
                }
    
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                //String[] toAddresses = new String[] {'vinatara@akamai.com,mohkhan@akamai.com'};
                String[] ccAddresses= new String[] {};
                if(PartnerCcEmail!='' || PartnerCcEmail.length()>0)
                        ccAddresses.addAll(PartnerCcEmail.split(','));
                //throw new CustomException('here'+oa.Associated_Opportunity__r.Partner_Involved__r.POA_Email_List__c);
                //throw new CustomException('here'+oa.Associated_Opportunity__r.Partner_Involved__r.POA_Email_List__c);
                if(oa.Associated_Opportunity__r.Partner_Involved__r.POA_Email_List__c!=null) {
                        string PartnerInvolvedCC=oa.Associated_Opportunity__r.Partner_Involved__r.POA_Email_List__c;
                        //throw new CustomException('test'+ccAddresses.size());
                        //if(ccAddresses.size()>0)
                        ccAddresses.addAll(PartnerInvolvedCC.replace(' ','').split(','));
                        //else
                        //ccAddresses=PartnerInvolvedCC.split(',');
                }
                //SFDC-5907-start
                if(oa.Associated_Opportunity__r.Owner.Email != null && oa.Associated_Opportunity__r.Owner.Email != '') {
                        ccAddresses.add(oa.Associated_Opportunity__r.Owner.Email);
                }
                //SFDC-5907-end
                //throw new CustomException('here'+ccAddresses);
                mail.setWhatId(oa.Id);
                //mail.setToAddresses(toAddresses);
                mail.setTargetObjectId(opp.CFA_To__c);
                String ccAddressString= '';
                Integer addressCount = 1;
                for(String ccadd:ccAddresses) {
                        ccAddressString = ccAddressString + ccadd;
                        if(addressCount!=ccAddresses.size())
                                ccAddressString = ccAddressString + '; ';
                        addressCount = addressCount + 1;
                }
                if(ccAddresses.size()>0)
                        mail.setCcAddresses(ccAddresses);
                mail.setSubject(EmailSubject);
                mail.setBccSender(false);
                mail.setUseSignature(false);
                mail.setPlainTextBody(BodyOfEmail);
                mail.setHtmlBody(htmlBodyOfEmail);
                if(!fileAttachments.isEmpty())
                mail.setFileAttachments(fileAttachments);
                // Loggin activity manually
                mail.setSaveAsActivity(true);
                System.DEBUG('BodyOfEmail: ' + BodyOfEmail);
                System.DEBUG('htmlBodyOfEmail:' + htmlBodyOfEmail);
                if(GsmUtilClass.getPRMSettingValue('CFA_AttachBcc')=='TRUE' || Test.isRunningTest()) {
                        list<string> bccAddresseslist=new list<string>();
                        bccAddresseslist.add(GsmUtilClass.getPRMSettingValue('CFA_AttachBccEmail'));
                        mail.setBccAddresses(bccAddresseslist);
                }
                try {
                        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                        List<Partner_Order_Acceptance_Document__c> poaUpdateList = new List<Partner_Order_Acceptance_Document__c>();
                        list<Partner_Order_Acceptance_Document__c>  poadRecord=[select id, POA_Email_List__c from Partner_Order_Acceptance_Document__c where Opportunity__c = :opp.Id AND Order_Acceptance_Status__c = 'Pending Acceptance'];
                        System.debug('poad content  '+poadRecord);
                        //SFDC-8762
                        List<Task> listOfTask = new List<Task>();
                        for(Partner_Order_Acceptance_Document__c POA:poadRecord) {
                                String email_list='';
                                for (String s : POA_Email_list) {
                                        email_list=email_list+', '+s;
                                        System.debug(s);
                                }
                                POA.POA_Email_List__c=email_list.substring(1,email_list.length());
                                System.debug(email_list);
                                POA.Validation_Override__c=true;
                                poaUpdateList.add(POA);
                                //update POA;

                                //SFDC-8762
                                Task orderAcceptanceTask = new Task();
                                orderAcceptanceTask.OwnerId = Userinfo.getuserid();
                                orderAcceptanceTask.WhatId = POA.Id;
                                orderAcceptanceTask.Subject = emailSubject;
                                orderAcceptanceTask.Type__c = 'Email';
                                orderAcceptanceTask.Description = BodyOfEmail;
                                orderAcceptanceTask.Status = 'Completed';

                                listOfTask.add(orderAcceptanceTask);

                        }
                        update poaUpdateList;
                        insert listOfTask;
                }
                catch(exception e) {
                        if(e.getMessage().Contains('INVALID_EMAIL_ADDRESS')) {
                                showErrorAndDiscontinue('Invalid Email Address'); return null;
                                //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Invalid Email Address'));
                        }
                        if(e.getMessage().Contains('LIMIT_EXCEEDED, Too many cc addresses')) {
                                showErrorAndDiscontinue('' + Label.CFA_SendEmail_Too_many_cc + ccAddressString); return null;
                                //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, '' + Label.CFA_SendEmail_Too_many_cc + ccAddressString));
                        }
                        else {
                                if(userTheme != null && userTheme == 'fromSF1') { // MOB-350 changes: display errors according to user Theme
                                        returnMessageJSON_ForSF1 = resultSetCustom(true, String.valueOf(e));
                                }
                                else {
                                        //pageRef = SiteLoginController.exceptionNotification(ApexPages.currentPage(),e);
                                        pageRef = Page.Exception; showErrorAndDiscontinue(e.getMessage());
                                }
                        }
                        //SFDC-7398
                        if(GsmUtilClass.isFeatureToggleEnabledCustomMetadata('useRevertSavePointFOrPOA')) {
                                Database.rollback(savePoint_Main);
                        }
                        //SFDC - 8568
                        Sawyer.saw(e,oa.Id,emailListString(POA_Email_list)); return null;
                }
                if(this.userTheme != null && this.userTheme == 'fromSF1') { // MOB-350 changes: display messages according to user Theme
                        returnMessageJSON_ForSF1 = resultSetCustom(false, 'Email Sent Succesfully');
                }
                else {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Email Sent Succesfully'));
                }
                showPage = false;
        }
        return null;  
    }
        public PageReference cancel()
        {
                return new PageReference('/'+oa.id);
        }
        public PageReference canceltoOppty()
        {
                return new PageReference('/'+oa.Associated_Opportunity__c);
        }
        public PageReference back()
        {
                mode=1;
                return null;
        }
    
        //SFDC-5658
        public static String trimName(String originalName) {
                String returnFileName = originalName;
                if(originalName.length() > 80) {
                        List<String> disembledParts = originalName.split('\\.');
                        if(disembledParts.size() > 1) {
                                String currentFileExtension = '.' + disembledParts.get(disembledParts.size()-1);
                                Integer maxLengthOfFileExtention = Integer.valueOf(GSMSettings.getValue('maxLengthOfFileExtention'));
                                if(currentFileExtension.length() > maxLengthOfFileExtention) {
                                        returnFileName = originalName.subString(0, 80);
                                }
                                else {
                                        returnFileName = originalName.subString(0, 80 - currentFileExtension.length()) + currentFileExtension;
                                }
                        }
                        else {
                                returnFileName = originalName.subString(0, 80);
                        }
                }
                return returnFileName;
        }
    
    //Begin SFDC-8568 - Harsh Pandey
    public static String emailListString(Set<String> POA_Email_List){
        String email_list='';
        if(!POA_Email_List.isEmpty()){
            for (String s : POA_Email_List){
                if(email_list == '')
                    email_list=s;
                else  
                    email_list=email_list+','+s;
            }       
        }       
        return email_list;        
    	    } 
    //End SFDC-8568 - Harsh Pandey
     	            
    }