/* Developer            Date                          Changes
____________________________________________________________________________________
1. Vandhana         15 February 2017        CR 3550011 - Tweaks to CPS email notification triggers
2. Vandhana     17 July 2018      ESESP-1446 : Enhancements to existing service cloud CPS email notifications
3. Aditi Singh     21 January 2021      ESESP-4697 : Updates to CPS Notifications and new alerts and autoCase creation
4. Aditi Singh     29 April 2021      ESESP-5022 : removed the technical failures : 201, Unable to Lock Row, Null pointer exception and 5 days cases not getting created
*/
 
public class SC_CPSNotifications
{ 
    public static boolean cpsRecCheck = false;
   
    @future
    public static void sendEmailForCPS(List<String> lCaseId, boolean isCertRequesterRequired,
                                String emailTemplateName, Boolean bccManagers)
    {
       
        List<EmailTemplate> lCPSEmailTemplates = [SELECT Id,Name,DeveloperName
                                                  FROM EmailTemplate
                                                  WHERE Folder.Name = 'CPS Templates'];
        // changes for ESESP-1446 and for ESESP-4697
        // Updated below query to get the metadata for EmailMessage - ESESP-5239 - Queried new developer names and also quering one more field Value_Text__c
        List<SC_Utility__mdt> mdtList = [SELECT Value__c,DeveloperName,Active__c,Value_Text__c 
                                         FROM SC_Utility__mdt
                                         WHERE Active__c = TRUE
                                         AND DeveloperName in ('CPS_Include_Sales_Primary_Template',
                                                               'CPS_Include_Sales_Primary_Roles',
                                                              'CPS_Include_PS_Primary_Secondary_Roles',
                                                               'CPS_Include_PS_Primary_SecondaryTemplate',
                                                              'CPS_AutoGenCaseDescriptionFor5DaysExpiry',
                                                              'CPSContactIdEmail',
                                                              'CPSIntegration_Address',
                                                              'CPSIntegration_DisplayName')
                                        ];
        
        Map<String,Set<String>> mdtMap = new Map<String,Set<String>>();
        Map<String, String> mapOfEmailMessageConstants = new Map<String, String>();//added for ESESP-5239 - Aditi
        for(SC_Utility__mdt eachMDT : mdtList)
        {
            if(eachMDT.DeveloperName != 'CPSContactIdEmail' && eachMDT.DeveloperName != 'CPSIntegration_Address' && eachMDT.DeveloperName != 'CPSIntegration_DisplayName'){
         		mdtMap.put(eachMDT.DeveloperName, eachMDT.DeveloperName != 'CPS_AutoGenCaseDescriptionFor5DaysExpiry'?new Set<String>(eachMDT.Value__c.split(',')):new Set<String>{eachMDT.Value__c});
            }
            else{
                mapOfEmailMessageConstants.put(eachMDT.DeveloperName, eachMDT.Value_Text__c);//added for ESESP-5239 - Aditi
            }
        }
        system.debug('mapOfEmailMessageConstants :: '+mapOfEmailMessageConstants);
        
        Set<String> rolesSet = new Set<String>{'Services - Primary','Services - Secondary','Security Services - Primary'};//Aditi - Added Security Services - Primary for ESESP-4697
        rolesSet.addAll(mdtMap.get('CPS_Include_Sales_Primary_Roles'));
        rolesSet.addAll(mdtMap.get('CPS_Include_PS_Primary_Secondary_Roles'));//Added by aditi for ESESP-4697
        
        List<String> lAccountIds = new List<String>();
       
        List<String> lAccountIdsForPartners = new List<String>();
        //List<Case> lCaseForUpdate = new List<Case>();
       
        Map<String,List<String>> mCaseAndAdditionalEmail = new Map<String,List<String>>();
        Map<String,List<String>> mAccountAndTeamMemberDetails = new Map<String,List<String>>();
        Map<String,List<String>> mAccountAndContactDetails = new Map<String,List<String>>();
        Map<String, String> mEmailTemplateDetails = new Map<String,String>();
        
        //Aditi - ESESP-4697 and ESESP-4878
        Map<String,Set<String>> accountIdToSetOfManagerIds = new Map<String,Set<String>>();
        Map<String,Boolean> mapOfAccountWithServicesSecondary = new Map<String,Boolean>();
        Set<Id> accIdfor321Days = new Set<Id>();
        Set<String> daysVal = new Set<String>{'1', '2', '3'};

        String caseDesc = mdtMap.containsKey('CPS_AutoGenCaseDescriptionFor5DaysExpiry') && mdtMap.get('CPS_AutoGenCaseDescriptionFor5DaysExpiry') != null? new List<String>(mdtMap.get('CPS_AutoGenCaseDescriptionFor5DaysExpiry')).get(0):null;
       system.debug('caseDesc :: '+caseDesc);
        for(EmailTemplate varEmailTemplate :lCPSEmailTemplates)
        {
            mEmailTemplateDetails.put(varEmailTemplate.DeveloperName,varEmailTemplate.Id);
        }
       
        List<Case> lCaseToSendEmail = [SELECT Id, Status, Cert_Admin_Contact_Email__c, Service__c,Request_Type__c,
                                       CertRequestorEmail__c, CertTechnicalContactEmail__c,
                                       AccountId, IR_Original_Contract_Id__c, IR_Original_Contract_Id__r.Contract_Type__c,
                                       IR_Original_Contract_Id__r.Account_Name__c, IR_Original_Contract_Id__r.Parent_Contract__c,
                                       IR_Original_Contract_Id__r.Parent_Account_Name__c,
                                       IR_Original_Contract_Id__r.Parent_Contract__r.Contract_Type__c,CPSExpiration5Days__c,CPSExpiration15Days__c,
                                       Account.Mailing_List_for_Technical_Case_auto_cc__c,Account.Name,CPSDaysBeforeExpiry__c,Slot__c,CertificateCN__c,Expiration_Date__c,CertificateAuthority__c,Account.AKAM_Account_ID__c,CPSErrorWarning__c 
                                       FROM Case
                                       WHERE Id IN :lCaseId];
       
       for(Case varCase :lCaseToSendEmail)
       {
           lAccountIds.add(varCase.AccountId);
           //Aditi - block to separate alerts for 3,2,1 days from 30,7,12 days - ESESP-4878
            if(varCase.CPSDaysBeforeExpiry__c != null && daysVal.contains(varCase.CPSDaysBeforeExpiry__c) && varCase.AccountId != null){
                accIdfor321Days.add(varCase.AccountId);
            }

           List<String> lAdditionalEmailAddress = new List<String>();
           // added for ESESP-1446
           if(varCase.AccountId != null && String.isNotBlank(varCase.Account.Mailing_List_for_Technical_Case_auto_cc__c))
           {
               for(String eachID :varCase.Account.Mailing_List_for_Technical_Case_auto_cc__c.replace(';',',').split(','))
               {
                   lAdditionalEmailAddress.add(eachID);
               }
           }
           if(emailTemplateName != 'CPSEmailNotification3_2_1_12_7_30days'){//Aditi - Excluding the internal teams from the new alerts as per ESESP-4697
               if(String.isNotBlank(varCase.Cert_Admin_Contact_Email__c))
               {
                   for(String varCertAdminEmail :varCase.Cert_Admin_Contact_Email__c.replace(';',',').split(','))
                   {
                       lAdditionalEmailAddress.add(varCertAdminEmail);
                   }
               }
               
               if(String.isNotBlank(varCase.CertTechnicalContactEmail__c))
               {
                   for(String varCertTechContactEmail :varCase.CertTechnicalContactEmail__c.replace(';',',').split(','))
                   {
                       lAdditionalEmailAddress.add(varCertTechContactEmail);
                   }
               }
               
               if(String.isNotBlank(varCase.CertRequestorEmail__c) && isCertRequesterRequired)
               {
                   for(String varCertRequester :varCase.CertRequestorEmail__c.replace(';',',').split(','))
                   {
                       lAdditionalEmailAddress.add(varCertRequester);
                   }
               }
               if(varCase.IR_Original_Contract_Id__c != null && varCase.IR_Original_Contract_Id__r.Contract_Type__c != null
                  && (varCase.IR_Original_Contract_Id__r.Contract_Type__c == 'Tier 1 Reseller'
                      || varCase.IR_Original_Contract_Id__r.Contract_Type__c=='Value Added Reseller'))
               {   
                   lAccountIdsForPartners.add(varCase.IR_Original_Contract_Id__r.Account_Name__c);
               }
               
               if(varCase.IR_Original_Contract_Id__c != null && varCase.IR_Original_Contract_Id__r.Parent_Contract__c != null && varCase.IR_Original_Contract_Id__r.Parent_Contract__r.Contract_Type__c !=null
                  && (varCase.IR_Original_Contract_Id__r.Parent_Contract__r.Contract_Type__c == 'Tier 1 Reseller'
                      || varCase.IR_Original_Contract_Id__r.Parent_Contract__r.Contract_Type__c == 'Value Added Reseller'))
               {
                   lAccountIdsForPartners.add(varCase.IR_Original_Contract_Id__r.Parent_Account_Name__c);   
               }
            }//End of if(emailTemplateName != 'CPSEmailNotification3_2_1_12_7_30days')
            //Moved the below if block here from top for ESESP-4852	- Aditi, otherwise the email was not getting added in the mail
            if(!mCaseAndAdditionalEmail.containsKey(varCase.Id))
            {
                mCaseAndAdditionalEmail.put(varCase.Id, lAdditionalEmailAddress);
            }
       }
        
        //Adding Account Team Member Service Primary and Service Secondary Email Address to the list
        //Aditi - updated the query here to order the results so that Services Secondary comes before Services Primary for each account - ESESP-4697
        List<AccountTeamMember> lAccountTeamMember = [SELECT Id, AccountId, UserId,
                                                      User.Akam_User_Id__c, User.Email,TeamMemberRole,User.ManagerId,User.Manager.Email,Account.Name
                                                      FROM AccountTeamMember
                                                      WHERE AccountId IN :lAccountIds
                                                      AND TeamMemberRole IN :rolesSet
                                                     ORDER BY Account.Name ASC, TeamMemberRole DESC];
        
        for(AccountTeamMember varAccountTeamMember :lAccountTeamMember)
        {
            if(!mAccountAndTeamMemberDetails.containsKey(varAccountTeamMember.AccountId))
            {
                mAccountAndTeamMemberDetails.put(varAccountTeamMember.AccountId, new List<String>());
            }
            
            if(mdtMap.get('CPS_Include_Sales_Primary_Roles').contains(varAccountTeamMember.TeamMemberRole))
            { 
                if(mdtMap.get('CPS_Include_Sales_Primary_Template').contains(emailTemplateName) && varAccountTeamMember.UserId != null && String.isNotBlank(varAccountTeamMember.User.Email))
                    mAccountAndTeamMemberDetails.get(varAccountTeamMember.AccountId).add(varAccountTeamMember.User.Email);
            }
            else if(mdtMap.get('CPS_Include_PS_Primary_Secondary_Roles').contains(varAccountTeamMember.TeamMemberRole)){ //Aditi - added this part to include PS Primary and Secondary roles for mails - ESESP-4697
                //The template list for adding PS Primary and PS Secondary are there in 2 metadata, done to make the metadata reusabale
                if((mdtMap.get('CPS_Include_PS_Primary_SecondaryTemplate').contains(emailTemplateName) || mdtMap.get('CPS_Include_Sales_Primary_Template').contains(emailTemplateName)) 
                   && varAccountTeamMember.UserId != null && String.isNotBlank(varAccountTeamMember.User.Email))
                    mAccountAndTeamMemberDetails.get(varAccountTeamMember.AccountId).add(varAccountTeamMember.User.Email);
            }
            else if(varAccountTeamMember.TeamMemberRole == 'Security Services - Primary'){//Aditi - added this part to include Security Services - Primary roles for mails - ESESP-4697
                //Aditi - below added the time based alert templates to include the Security Services - Primary when sending email - ESESP-4878
                if((mdtMap.get('CPS_Include_PS_Primary_SecondaryTemplate').contains(emailTemplateName) || mdtMap.get('CPS_Include_Sales_Primary_Template').contains(emailTemplateName))
                   && varAccountTeamMember.UserId != null && String.isNotBlank(varAccountTeamMember.User.Email))
                    mAccountAndTeamMemberDetails.get(varAccountTeamMember.AccountId).add(varAccountTeamMember.User.Email);
            }
            else{
                if(varAccountTeamMember.UserId != null && String.isNotBlank(varAccountTeamMember.User.Email)){
            		mAccountAndTeamMemberDetails.get(varAccountTeamMember.AccountId).add(varAccountTeamMember.User.Email);
                }
            }
            
            //Aditi - block to add manager for all expiration alerts - Add either Services-Secondary manager or Services-Primary manager - ESESP-4697
            //Updated by aditi - added check for accountId it should only for 5,3,2,1 days alerts - ESESP-4878
            if(bccManagers &&  (emailTemplateName == 'CPSEmailNotification5days' || (emailTemplateName == 'CPSEmailNotification3_2_1_12_7_30days' && varAccountTeamMember.AccountId != null && accIdfor321Days.contains(varAccountTeamMember.AccountId)))){
                if(varAccountTeamMember.TeamMemberRole == 'Services - Secondary'){
                    if(varAccountTeamMember.UserId != null && varAccountTeamMember.User.ManagerId != null && String.isNotBlank(varAccountTeamMember.User.Manager.Email)){
                        if(accountIdToSetOfManagerIds.containsKey(varAccountTeamMember.AccountId)){
                            accountIdToSetOfManagerIds.get(varAccountTeamMember.AccountId).add(varAccountTeamMember.User.Manager.Email);
                        }
                        else{//Aditi - added else block for ESESP-4851
                            accountIdToSetOfManagerIds.put(varAccountTeamMember.AccountId,new Set<String>{varAccountTeamMember.User.Manager.Email});
                        }
                        mapOfAccountWithServicesSecondary.put(varAccountTeamMember.AccountId,true);//Aditi - Boolean map to maintain that only Services Secondary managers are added to bcc
                    }
                }
                else if(varAccountTeamMember.TeamMemberRole == 'Services - Primary' && varAccountTeamMember.UserId != null && varAccountTeamMember.User.ManagerId != null && String.isNotBlank(varAccountTeamMember.User.Manager.Email) && !mapOfAccountWithServicesSecondary.containsKey(varAccountTeamMember.AccountId)){
                    //Will go inside if no records for Secondary were found and also the Primary team member has a manager
                    if(accountIdToSetOfManagerIds.containsKey(varAccountTeamMember.AccountId)){
                        accountIdToSetOfManagerIds.get(varAccountTeamMember.AccountId).add(varAccountTeamMember.User.Manager.Email);
                    }
                    else{//Aditi - added else block for ESESP-4851
                        accountIdToSetOfManagerIds.put(varAccountTeamMember.AccountId, new Set<String>{varAccountTeamMember.User.Manager.Email});
                    }
                }
            }//Aditi - changes end here
        }
        
        //Adding Contact Service Primary and Service Other Email Address to the list
        for(Contact varContact :[SELECT Id,Email,AccountId
                                 FROM Contact
                                 WHERE AccountId IN :lAccountIdsForPartners AND
                                 Partner_Contact_Type__c INCLUDES ('Services Other','Services Primary')])
        {
            if(!mAccountAndContactDetails.containsKey(varContact.AccountId))
            {
                mAccountAndContactDetails.put(varContact.AccountId, new List<String>());
            }
            if(String.isNotBlank(varContact.Email)){
            	mAccountAndContactDetails.get(varContact.AccountId).add(varContact.Email);
            }
        }
        
        List<Messaging.SingleEmailMessage> lMailsToSend = new List<Messaging.SingleEmailMessage>();
        List<Case> casesExpiringIn5Days = new List<Case>();//Added by aditi - ESESP-4697
        List<EmailMessage> emailMessageLst = new List<EmailMessage>();//Added by aditi - ESESP-5239

        //Aditi - block to get the running user's signature if there is one in order to add that to the EmailMessage body as it is being sent in the email body of the actual inbox email
        String userSignature = '';
        User currUser = [Select Id,Signature from User where Id=:userinfo.getuserId()];
        if(currUser.Signature != null){
            userSignature = currUser.Signature.escapeHtml4();
        }
        /*if (String.isNotBlank(userSignature)) {
                userSignature = userSignature.replace('\n','<br>');
        }*/
        
        for(Case varCase :lCaseToSendEmail)
        {
            List<String> lAllEmailAddresses = new List<String>();
            Messaging.SingleEmailMessage singleEmail = new Messaging.SingleEmailMessage();
            singleEmail.setTemplateId(mEmailTemplateDetails.get(emailTemplateName));
            
            if(varCase.Id != null
               && mCaseAndAdditionalEmail.containsKey(varCase.Id))
                lAllEmailAddresses.addAll(mCaseAndAdditionalEmail.get(varCase.Id));
            
            if(varCase.AccountId != null
               &&mAccountAndTeamMemberDetails.containsKey(varCase.AccountId))
                lAllEmailAddresses.addAll(mAccountAndTeamMemberDetails.get(varCase.AccountId));
            
            if(varCase.IR_Original_Contract_Id__c != null && varCase.IR_Original_Contract_Id__r.Account_Name__c != null
               && mAccountAndContactDetails.containsKey(varCase.IR_Original_Contract_Id__r.Account_Name__c))
                lAllEmailAddresses.addAll(mAccountAndContactDetails.get(varCase.IR_Original_Contract_Id__r.Account_Name__c));
            
            if(varCase.IR_Original_Contract_Id__c != null && varCase.IR_Original_Contract_Id__r.Parent_Account_Name__c != null
               && mAccountAndContactDetails.containsKey(varCase.IR_Original_Contract_Id__r.Parent_Account_Name__c))
                lAllEmailAddresses.addAll(mAccountAndContactDetails.get(varCase.IR_Original_Contract_Id__r.Parent_Account_Name__c));
            
            singleEmail.setToAddresses(lAllEmailAddresses);
            singleEmail.setWhatId(varCase.Id);
            singleEmail.setTargetObjectId(SCUserIdCustomSetting__c.getValues('CPSContactId').UserId__c);
            singleEmail.setOrgWideEmailAddressId(SC_FromEmailAddress__c.getValues('CPSIntegration').OrgAddressId__c);
            singleEmail.setSaveAsActivity(false); //Aditi - added this to avoid 201 exception when sending mails - this is going to stop creating an activity for email sent - ESESP-5239
            
            //Aditi - added below block for adding BCC for managers - ESESP-4697
            List<String> bccAddresses = new List<String>();
            if(varCase.AccountId != null && accountIdToSetOfManagerIds.containsKey(varCase.AccountId)){
                bccAddresses.addAll(accountIdToSetOfManagerIds.get(varCase.AccountId));
                singleEmail.setBccAddresses(bccAddresses);
            }
            
            lMailsToSend.add(singleEmail);
            //Making a list of cases going to expire in 5 days so that we can create a ticket - ESESP-4697
            if(emailTemplateName == 'CPSEmailNotification5days'){
                casesExpiringIn5Days.add(varCase);
            }
            System.debug('emails address :: '+lAllEmailAddresses+' bcc address :: '+accountIdToSetOfManagerIds.get(varCase.AccountId));
            
            //Email Message creation - ESESP-5239
            emailMessageLst.add(formEmailMessageRecord(emailTemplateName , varCase , lAllEmailAddresses , bccAddresses , mapOfEmailMessageConstants, userSignature));
        }
        System.debug('emailMessageLst :: '+emailMessageLst);
        
        //Aditi - added below block for creating new cases - ESESP-4697
        //Aditi - taken this code outside of the try catch, as it has its own try catch and also even if the email fails the case will get created.
        if(!casesExpiringIn5Days.isEmpty()){
            createCaseFor5DaysExpiry(casesExpiringIn5Days,caseDesc);
        }
        try{
            if(lMailsToSend.size()>0 && !Test.isRunningTest()){
                System.debug('lMailsToSend :: '+lMailsToSend);
                System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
                Messaging.sendEmail(lMailsToSend);
                System.debug('Number of Queries used in this apex code so far: ' + Limits.getQueries());
                
                //Aditi - logic to create Email message for emails sent and attach to the case - ESESP-5239
                if(emailMessageLst.size()>0){
                    insert emailMessageLst;
                }
            }
        }
        catch(Exception e){
            string setEmailSub = 'Exception: In sending mails for the CPS cases.';
            string errorMessage =  	'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
                      				'Batch Class Name = SC_CPSNotifications\n' + 
                                	'Support Class Name = SC_Autogen_COB_Support\n' +
                                	'Method Name = sendEmailForCPS\n';
            errorMessage += e.getCause()+'..'+e.getLineNumber()+'..'+e.getMessage()+'..'+e.getTypeName()+'..'+e.getStackTraceString();
            SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support(); 
          	sc_COBSupportCls.senEmailForError(setEmailSub, errorMessage);
        } 
    }
    
    //Aditi - Method added to create Email Message records in bulk when emails are sent for alerts - to avoid 201 error - ESESP-5239
    public static EmailMessage formEmailMessageRecord(String emailTemplateName , Case varCase , List<String> toAddressesToAdd , List<String> bccAddressesToAdd, Map<String, String> mapOfEmailMessageConstants, String userSignature){
        
        system.debug('emailTemplateName ::'+emailTemplateName);
        //Aditi - Block for creating email message for each case
        EmailMessage emailMsg = new EmailMessage();
        emailMsg.toAddress = string.join(toAddressesToAdd,',');
        if(mapOfEmailMessageConstants.containsKey('CPSContactIdEmail') && mapOfEmailMessageConstants.get('CPSContactIdEmail') != null){
            emailMsg.toAddress = emailMsg.toAddress + ','+mapOfEmailMessageConstants.get('CPSContactIdEmail');
        }
        emailMsg.ParentId = varCase.Id; //Attach with the case
        emailMsg.MessageDate = system.now(); 
        emailMsg.status  = '3'; //Status 0 corresponds to New email
        
        emailMsg.FromAddress = mapOfEmailMessageConstants.containsKey('CPSIntegration_Address') && mapOfEmailMessageConstants.get('CPSIntegration_Address') != null?
            mapOfEmailMessageConstants.get('CPSIntegration_Address'):'sf-no-reply@akamai.com';//sfnoreply@akamai.com
        emailMsg.FromName = mapOfEmailMessageConstants.containsKey('CPSIntegration_DisplayName') && mapOfEmailMessageConstants.get('CPSIntegration_DisplayName') != null?
            mapOfEmailMessageConstants.get('CPSIntegration_DisplayName'):'sf-no-reply';
        
        
        emailMsg.BccAddress = string.join(bccAddressesToAdd,',');
        
        String emailbodyStr = 'Hello,\n\nThe certificate, {0}, on slot {1}'+
            	' , is expiring in {2} days and the renewal is not complete.\n\nTo find the latest status on the renewal, '+
                'please login to the Control Center, select the Configure menu and then Certificate Provisioning System (CPS).\n\n'+
            	'{4} seven days before the active certificate expires, '+
                'the new certificate will automatically be deployed to the Production network to avoid leaving you with an expired certificate on the network. {3}\n\n'+
            'If this certificate is no longer needed, please login to Control Center and delete the {5}.';
        
        String emailbodyStr8Days = 'Hello,\n\nThe certificate, {0}, on slot {1}'+
            	' , is expiring in 8 days and the new certificate is ready on Staging.\n\nSeven days before the active certificate expires, '+
                'the new certificate will automatically be deployed to the Production network unless there is a Deployment Date & Time set.\n\n'+
            	'If you’re not ready for this certificate to deploy, please login to the Control Center, select the Configure menu and then '+
                'select the Certificate Provisioning System (CPS). Review the certificate and set a deployment date.';
        
        String emailbodyStr1DayAfter = 'Hello,\n\nThe certificate {0}, on slot {1}'+
            	' , is now expired. Users attempting to connect to secure properties using this certificate will receive errors in their browsers or client software.\n\n'+
                'Per Akamai policy, the certificate will be deleted 30 days after the expiration date.\n\n'+
            	'To find the latest status on the renewal, please login to the Control Center, select the Configure menu and then Certificate Provisioning System (CPS).\n\n'+
                'If this certificate is no longer needed, please login to Control Center and delete the certificate.';
        
        String subjectStr = 'Certificate Notification for {0}: {1} days until expiration and renewal is not complete';
        
        String subjectStr8Days = 'Certificate Notification for {0}: 8 days until expiration and auto deploy is tomorrow';
        
        String subjectStr1DayAfter = 'Certificate Notification for {0}: Certificate Expired';
        
        //Template strings for insert cases
        String renewalStartedStr = 'Hello,\n\nThe status of your certificate, {0}, on slot {1}, has changed. The renewal process for {5} certificate has begun.\n\n'+
            	'{3}';
        
        String renewalStartedSubjectStr = 'Certificate Notification for {0}: {1}';
        
        String newCertificateStr = 'Hello,\n\nThe status of your certificate, {0}, has changed. A new order for the certificate has begun.\n\n'+
            	'{3}';
        
        String newCertificateSubjectStr = 'Certificate Notification for {0}: New order started';
        
        //Template strings for status update emails
        
        String preVerificationFailedStr = 'Hello,\n\nThe status of your recent certificate order, {0}, on slot {1}, has changed.'+
            ' The certificate information has the following warnings or errors:\n{3}\n\n'+
            'Please login to the Control Center and from the Configure menu, select Certificate Provisioning System (CPS). Find the certificate and make the appropriate modifications.\n\n'+
            'If you have any questions, review the in-context help in the Control Center Certificate Provision System.';
        
        String preVerificationFailedSubjectStr = 'Certificate Notification for {0}: {1}';
        
        String postVerificationWarningStr = 'Hello,\n\nThe status of your certificate, {0}, on slot {1}, has changed.'+
            ' The certificate has the following warnings:\n{3}\n\n'+
            'Please login to the Control Center, select the Configure menu, then select Certificate Provisioning System (CPS) to review these warnings. If you want to proceed with the certificate deployment, acknowledge the warnings in the Control Center.'+
            ' If you did not expect these warnings, please make changes to your certificate request.';
        
        String postVerificationErrorStr = 'Hello,\n\nThe status of your certificate, {0}, on slot {1}, has changed.'+
            ' There is an issue with your certificate and it has the following warnings or errors:\n{3}\n\n'+
            'Please login to the Control Center, choose the Configure menu and select Certificate Provisioning System (CPS). From there, find your certificate on the In Progress tab and review any errors.';
        
        String waitingOnChangeManagementStr = 'Hello,\n\nThe status of your certificate, {0}, on slot {1}, has changed. The certificate is now available for review and testing on the staging network.\n\n'+
            'Once you finish testing the certificate on Staging, log in to the Control Center, from the Configure menu select the Certificate Provisioning System (CPS) and from there you can deploy it to Production.\n\n'+
            'WARNING: Seven days before the active certificate expires, the new certificate will automatically be deployed to production to avoid leaving you with an expired certificate on the network.'+
            ' If you need to deploy the certificate inside of the seven-day window, please set a specific Deployment Date & Time.\n\n'+
            'If you need more information on how to access staging or about certificates in general, see the online help in the Certificate Provisioning System.';
        
        String certificateDeployedStr = 'Hello,\n\nCongratulations! Certificate {0}, on Slot {1}, has successfully deployed to the network and is now ready to use.\n\n'+
            'If you have any questions, contact your account representative or review the online help in the Certificate Provisioning System (CPS).';
        
        String errorInOrderAtCAStr = 'Hello,\n\nThe status of your certificate, {0}, on slot {1}, has changed. The certificate has an error due to an event at the certificate authority.\n\n'+
            'Please login to the Control Center, select the Configure menu, then select Certificate Provisioning System (CPS) to review these errors.';
        
        
        //starting with insert emails first
        if(emailTemplateName == 'Renewal_Started'){
            renewalStartedStr = varCase.CertificateCN__c != null?renewalStartedStr.replace('{0}', varCase.CertificateCN__c):renewalStartedStr.replace('{0}', '');
            renewalStartedStr = varCase.Slot__c != null?renewalStartedStr.replace('{1}', varCase.Slot__c):renewalStartedStr.replace('{1}', '');
            renewalStartedStr = renewalStartedStr.replace('{5}', 'your Akamai Managed');
            
            renewalStartedStr = renewalStartedStr.replace('{3}', '{4} may contact you via email or phone call to verify the contents of the certificate request.\n\n'+
                'You can check the latest status of the certificate by logging into the Control Center and from the Configure menu selecting the Certificate Provisioning System (CPS).');
            
            renewalStartedStr = varCase.CertificateAuthority__c != null?renewalStartedStr.replace('{4}', varCase.CertificateAuthority__c):renewalStartedStr.replace('{4}', '');
            
            renewalStartedSubjectStr = varCase.CertificateCN__c != null?renewalStartedSubjectStr.replace('{0}', varCase.CertificateCN__c):renewalStartedSubjectStr.replace('{0}', '');
            renewalStartedSubjectStr = renewalStartedSubjectStr.replace('{1}', 'Renewal started');
            
            emailMsg.subject = renewalStartedSubjectStr;
            emailMsg.textbody  = renewalStartedStr;
        }
        else if(emailTemplateName == 'Renewal_Started_for_Third_Party'){
            renewalStartedStr = varCase.CertificateCN__c != null?renewalStartedStr.replace('{0}', varCase.CertificateCN__c):renewalStartedStr.replace('{0}', '');
            renewalStartedStr = varCase.Slot__c != null?renewalStartedStr.replace('{1}', varCase.Slot__c):renewalStartedStr.replace('{1}', '');
            renewalStartedStr = renewalStartedStr.replace('{5}', 'your third party');
            
            renewalStartedStr = renewalStartedStr.replace('{3}', 'Please login to the Control Center and from the Configure menu, select Certificate Provisioning System (CPS). From there, you can download the CSR to submit to your certificate authority.');
            
            renewalStartedSubjectStr = varCase.CertificateCN__c != null?renewalStartedSubjectStr.replace('{0}', varCase.CertificateCN__c):renewalStartedSubjectStr.replace('{0}', '');
            renewalStartedSubjectStr = renewalStartedSubjectStr.replace('{1}', 'Third party renewal started');
            
            emailMsg.subject = renewalStartedSubjectStr;
            emailMsg.textbody  = renewalStartedStr;
        }
        else if(emailTemplateName == 'Renewal_Started_With_LetsEncrypt'){
            renewalStartedStr = varCase.CertificateCN__c != null?renewalStartedStr.replace('{0}', varCase.CertificateCN__c):renewalStartedStr.replace('{0}', '');
            renewalStartedStr = varCase.Slot__c != null?renewalStartedStr.replace('{1}', varCase.Slot__c):renewalStartedStr.replace('{1}', '');
            renewalStartedStr = renewalStartedStr.replace('{5}', 'the');
            
            renewalStartedStr = renewalStartedStr.replace('{3}', '{4} will automatically validate all properly CNAME’d domains within 24 hours. Check the Control Center if a certificate deployed email is not received within 24 hours.\n\n'+
                'You can check the latest status of the certificate by logging into the Control Center and from the Configure menu selecting the Certificate Provisioning System (CPS).');
            
            renewalStartedStr = varCase.CertificateAuthority__c != null?renewalStartedStr.replace('{4}', varCase.CertificateAuthority__c):renewalStartedStr.replace('{4}', '');
            
            renewalStartedSubjectStr = varCase.CertificateCN__c != null?renewalStartedSubjectStr.replace('{0}', varCase.CertificateCN__c):renewalStartedSubjectStr.replace('{0}', '');
            renewalStartedSubjectStr = renewalStartedSubjectStr.replace('{1}', 'Renewal started');
            
            emailMsg.subject = renewalStartedSubjectStr;
            emailMsg.textbody  = renewalStartedStr;
        }
        else if(emailTemplateName == 'New_Certificate_Requested'){
            newCertificateStr = varCase.CertificateCN__c != null?newCertificateStr.replace('{0}', varCase.CertificateCN__c):newCertificateStr.replace('{0}', '');
            
            newCertificateStr = newCertificateStr.replace('{3}', '{4} may contact you via email or phone call to verify the contents of the certificate request.'+
                                                          'You must respond to these validation requests from {4} for the certificate to be issued.\n\n'+
                                                         'You can check the latest status of the certificate by logging into the Control Center and from the Configure menu selecting Certificate Provisioning System (CPS).');
            
            newCertificateStr = varCase.CertificateAuthority__c != null?newCertificateStr.replace('{4}', varCase.CertificateAuthority__c):newCertificateStr.replace('{4}', '');
            
            newCertificateSubjectStr = varCase.CertificateCN__c != null?newCertificateSubjectStr.replace('{0}', varCase.CertificateCN__c):newCertificateSubjectStr.replace('{0}', '');
            
            emailMsg.subject = newCertificateSubjectStr;
            emailMsg.textbody  = newCertificateStr;
        }
        else if(emailTemplateName == 'New_Certificate_Requested_With_LetsEncrypt'){
            newCertificateStr = varCase.CertificateCN__c != null?newCertificateStr.replace('{0}', varCase.CertificateCN__c):newCertificateStr.replace('{0}', '');
            
            newCertificateStr = newCertificateStr.replace('{3}', 'To obtain the {4} domain validation tokens, log into the Control Center and from the Configure menu, select Certificate Provisioning System (CPS). '+
                                                          'Find your certificate and review any “To-Do” items or select “View Validation Instructions” from the Action menu.');
            
            newCertificateStr = varCase.CertificateAuthority__c != null?newCertificateStr.replace('{4}', varCase.CertificateAuthority__c):newCertificateStr.replace('{4}', '');
            
            newCertificateSubjectStr = varCase.CertificateCN__c != null?newCertificateSubjectStr.replace('{0}', varCase.CertificateCN__c):newCertificateSubjectStr.replace('{0}', '');
            
            emailMsg.subject = newCertificateSubjectStr;
            emailMsg.textbody  = newCertificateStr;
        }
        
        
        else if(emailTemplateName == 'Pre_verification_Failed'){
            preVerificationFailedStr = varCase.CertificateCN__c != null?preVerificationFailedStr.replace('{0}', varCase.CertificateCN__c):preVerificationFailedStr.replace('{0}', '');
            preVerificationFailedStr = varCase.Slot__c != null?preVerificationFailedStr.replace('{1}', varCase.Slot__c):preVerificationFailedStr.replace('{1}', '');
            preVerificationFailedStr = varCase.CPSErrorWarning__c != null?preVerificationFailedStr.replace('{3}', varCase.CPSErrorWarning__c):preVerificationFailedStr.replace('{3}', '');
            
            preVerificationFailedSubjectStr = varCase.CertificateCN__c != null?preVerificationFailedSubjectStr.replace('{0}', varCase.CertificateCN__c):preVerificationFailedSubjectStr.replace('{0}', '');
            preVerificationFailedSubjectStr = preVerificationFailedSubjectStr.replace('{1}', 'Issue with certificate information');
            
            emailMsg.subject = preVerificationFailedSubjectStr;
            emailMsg.textbody  = preVerificationFailedStr;
        }
        else if(emailTemplateName == 'Post_verification_Warning_For_CPS_Automated'){
            postVerificationWarningStr = varCase.CertificateCN__c != null?postVerificationWarningStr.replace('{0}', varCase.CertificateCN__c):postVerificationWarningStr.replace('{0}', '');
            postVerificationWarningStr = varCase.Slot__c != null?postVerificationWarningStr.replace('{1}', varCase.Slot__c):postVerificationWarningStr.replace('{1}', '');
            postVerificationWarningStr = varCase.CPSErrorWarning__c != null?postVerificationWarningStr.replace('{3}', varCase.CPSErrorWarning__c):postVerificationWarningStr.replace('{3}', '');
            
            preVerificationFailedSubjectStr = varCase.CertificateCN__c != null?preVerificationFailedSubjectStr.replace('{0}', varCase.CertificateCN__c):preVerificationFailedSubjectStr.replace('{0}', '');
            preVerificationFailedSubjectStr = preVerificationFailedSubjectStr.replace('{1}', 'Warning messages for your certificate');
            
            emailMsg.subject = preVerificationFailedSubjectStr;
            emailMsg.textbody  = postVerificationWarningStr;
        }
        else if(emailTemplateName == 'Post_verification_Error_For_CPS_Automated'){
            postVerificationErrorStr = varCase.CertificateCN__c != null?postVerificationErrorStr.replace('{0}', varCase.CertificateCN__c):postVerificationErrorStr.replace('{0}', '');
            postVerificationErrorStr = varCase.Slot__c != null?postVerificationErrorStr.replace('{1}', varCase.Slot__c):postVerificationErrorStr.replace('{1}', '');
            postVerificationErrorStr = varCase.CPSErrorWarning__c != null?postVerificationErrorStr.replace('{3}', varCase.CPSErrorWarning__c):postVerificationErrorStr.replace('{3}', '');
            
            preVerificationFailedSubjectStr = varCase.CertificateCN__c != null?preVerificationFailedSubjectStr.replace('{0}', varCase.CertificateCN__c):preVerificationFailedSubjectStr.replace('{0}', '');
            preVerificationFailedSubjectStr = preVerificationFailedSubjectStr.replace('{1}', 'Issue with certificate');
            
            emailMsg.subject = preVerificationFailedSubjectStr;
            emailMsg.textbody  = postVerificationErrorStr;
        }
        else if(emailTemplateName == 'Waiting_on_Change_Management'){
            waitingOnChangeManagementStr = varCase.CertificateCN__c != null?waitingOnChangeManagementStr.replace('{0}', varCase.CertificateCN__c):waitingOnChangeManagementStr.replace('{0}', '');
            waitingOnChangeManagementStr = varCase.Slot__c != null?waitingOnChangeManagementStr.replace('{1}', varCase.Slot__c):waitingOnChangeManagementStr.replace('{1}', '');
            
            preVerificationFailedSubjectStr = varCase.CertificateCN__c != null?preVerificationFailedSubjectStr.replace('{0}', varCase.CertificateCN__c):preVerificationFailedSubjectStr.replace('{0}', '');
            preVerificationFailedSubjectStr = preVerificationFailedSubjectStr.replace('{1}', 'Waiting for you to review certificate');
            
            emailMsg.subject = preVerificationFailedSubjectStr;
            emailMsg.textbody  = waitingOnChangeManagementStr;
        }
        else if(emailTemplateName == 'Certificate_Deployed'){
            certificateDeployedStr = varCase.CertificateCN__c != null?certificateDeployedStr.replace('{0}', varCase.CertificateCN__c):certificateDeployedStr.replace('{0}', '');
            certificateDeployedStr = varCase.Slot__c != null?certificateDeployedStr.replace('{1}', varCase.Slot__c):certificateDeployedStr.replace('{1}', '');
            
            preVerificationFailedSubjectStr = varCase.CertificateCN__c != null?preVerificationFailedSubjectStr.replace('{0}', varCase.CertificateCN__c):preVerificationFailedSubjectStr.replace('{0}', '');
            preVerificationFailedSubjectStr = preVerificationFailedSubjectStr.replace('{1}', 'Successfully deployed!');
            
            emailMsg.subject = preVerificationFailedSubjectStr;
            emailMsg.textbody  = certificateDeployedStr;
        }
        else if(emailTemplateName == 'Error_in_Order_at_CA'){
            errorInOrderAtCAStr = varCase.CertificateCN__c != null?errorInOrderAtCAStr.replace('{0}', varCase.CertificateCN__c):errorInOrderAtCAStr.replace('{0}', '');
            errorInOrderAtCAStr = varCase.Slot__c != null?errorInOrderAtCAStr.replace('{1}', varCase.Slot__c):errorInOrderAtCAStr.replace('{1}', '');
            
            preVerificationFailedSubjectStr = varCase.CertificateCN__c != null?preVerificationFailedSubjectStr.replace('{0}', varCase.CertificateCN__c):preVerificationFailedSubjectStr.replace('{0}', '');
            preVerificationFailedSubjectStr = preVerificationFailedSubjectStr.replace('{1}', 'Error at certificate authority');
            
            emailMsg.subject = preVerificationFailedSubjectStr;
            emailMsg.textbody  = errorInOrderAtCAStr;
        }
        
        
        
        else if(emailTemplateName == 'CPSEmailNotification5days'){
            emailbodyStr = varCase.CertificateCN__c != null?emailbodyStr.replace('{0}', varCase.CertificateCN__c):emailbodyStr.replace('{0}', '');
            emailbodyStr = varCase.Slot__c != null?emailbodyStr.replace('{1}', varCase.Slot__c):emailbodyStr.replace('{1}', '');
            emailbodyStr = emailbodyStr.replace('{2}', '5');
            emailbodyStr = emailbodyStr.replace('{4}', 'Even with “Always Test on Staging” enabled, inside of');
            emailbodyStr = emailbodyStr.replace('{3}', 'If you need to deploy the certificate inside of the seven-day window, please set a specific Deployment Date & Time.');
            emailbodyStr = emailbodyStr.replace('{5}', 'enrollment');
            
            subjectStr = varCase.CertificateCN__c != null?subjectStr.replace('{0}', varCase.CertificateCN__c):subjectStr.replace('{0}', '');
            subjectStr = subjectStr.replace('{1}', '5');
            
            emailMsg.subject = subjectStr;
            emailMsg.textbody  = emailbodyStr;
        }
        else if(emailTemplateName == 'CPSEmailNotification3_2_1_12_7_30days'){
            emailbodyStr = varCase.CertificateCN__c != null?emailbodyStr.replace('{0}', varCase.CertificateCN__c):emailbodyStr.replace('{0}', '');
            emailbodyStr = varCase.Slot__c != null?emailbodyStr.replace('{1}', varCase.Slot__c):emailbodyStr.replace('{1}', '');
            emailbodyStr = varCase.CPSDaysBeforeExpiry__c != null?emailbodyStr.replace('{2}', varCase.CPSDaysBeforeExpiry__c):emailbodyStr.replace('{2}', '');
            emailbodyStr = emailbodyStr.replace('{4}', 'Even with “Always Test on Staging” enabled, inside of');
            emailbodyStr = emailbodyStr.replace('{3}', '');
            emailbodyStr = emailbodyStr.replace('{5}', 'enrollment');
            
            subjectStr = varCase.CertificateCN__c != null?subjectStr.replace('{0}', varCase.CertificateCN__c):subjectStr.replace('{0}', '');
            subjectStr = varCase.CPSDaysBeforeExpiry__c != null?subjectStr.replace('{1}', varCase.CPSDaysBeforeExpiry__c):subjectStr.replace('{1}', '');
            
            emailMsg.subject = subjectStr;
            emailMsg.textbody  = emailbodyStr;
        }
        else if(emailTemplateName == 'CPSEmailNotification15days'){
            emailbodyStr = varCase.CertificateCN__c != null?emailbodyStr.replace('{0}', varCase.CertificateCN__c):emailbodyStr.replace('{0}', '');
            emailbodyStr = varCase.Slot__c != null?emailbodyStr.replace('{1}', varCase.Slot__c):emailbodyStr.replace('{1}', '');
            emailbodyStr = emailbodyStr.replace('{2}', '15');
            emailbodyStr = emailbodyStr.replace('{4}', 'If the renewed certificate is waiting on Staging,');
            emailbodyStr = emailbodyStr.replace('{3}', 'If you need to deploy the certificate inside of the seven-day window, please set a specific Deployment Date & Time.');
            emailbodyStr = emailbodyStr.replace('{5}', 'certificate');
            
            subjectStr = varCase.CertificateCN__c != null?subjectStr.replace('{0}', varCase.CertificateCN__c):subjectStr.replace('{0}', '');
            subjectStr = subjectStr.replace('{1}', '15');
            
            emailMsg.subject = subjectStr;
            emailMsg.textbody  = emailbodyStr;
        }
        else if(emailTemplateName == 'CPSEmailNotification8days'){
            emailbodyStr8Days = varCase.CertificateCN__c != null?emailbodyStr8Days.replace('{0}', varCase.CertificateCN__c):emailbodyStr8Days.replace('{0}', '');
            emailbodyStr8Days = varCase.Slot__c != null?emailbodyStr8Days.replace('{1}', varCase.Slot__c):emailbodyStr8Days.replace('{1}', '');
            
            subjectStr8Days = varCase.CertificateCN__c != null?subjectStr8Days.replace('{0}', varCase.CertificateCN__c):subjectStr8Days.replace('{0}', '');
            
            emailMsg.subject = subjectStr8Days;
            emailMsg.textbody  = emailbodyStr8Days;
        }
        else if(emailTemplateName == 'CPSEmailNotification1dayAfter'){
            emailbodyStr1DayAfter = varCase.CertificateCN__c != null?emailbodyStr1DayAfter.replace('{0}', varCase.CertificateCN__c):emailbodyStr1DayAfter.replace('{0}', '');
            emailbodyStr1DayAfter = varCase.Slot__c != null?emailbodyStr1DayAfter.replace('{1}', varCase.Slot__c):emailbodyStr1DayAfter.replace('{1}', '');
            
            subjectStr1DayAfter = varCase.CertificateCN__c != null?subjectStr1DayAfter.replace('{0}', varCase.CertificateCN__c):subjectStr1DayAfter.replace('{0}', '');
            
            emailMsg.subject = subjectStr1DayAfter;
            emailMsg.textbody  = emailbodyStr1DayAfter;
        }
        if (String.isNotBlank(userSignature)) {
            emailMsg.textbody  = emailMsg.textbody+'\n\n'+userSignature.unescapeHtml4();
        }

        return emailMsg;
    }
 
    public static void populateAccountIdBasedOnContractId(List<String> lContractIds, List<Case> lCPSCases)
    {
        Map<String,String> mContractIdAndAccountId = new Map<String,String>();
        for(Merge_Contract_Header__c varContract :[SELECT Id, Account_Name__c,Original_Contract_Id__c
                                                   FROM Merge_Contract_Header__c
                                                   WHERE Id IN :lContractIds]){
                                                       mContractIdAndAccountId.put(varContract.Id, varContract.Account_Name__c);
                                                   }
        
        for(Case varCase :lCPSCases){
            if(mContractIdAndAccountId.containsKey(varCase.IR_Original_Contract_Id__c)){
                varCase.AccountId = mContractIdAndAccountId.get(varCase.IR_Original_Contract_Id__c);
                
            }
        }
    }
   
    // Called from trigger CaseTrigger_ai for CPS Notification
    public void triggerInputHandler(boolean isInsert, boolean isUpdate,
                                    Map<Id,Case> mNewTrigger, Map<Id,Case> mOldTrigger,
                                    Map<Id, String> mRecordTypes)
    {
        cpsRecCheck = true;

        System.debug('mNewTrigger :: '+mNewTrigger);
        System.debug('mOldTrigger :: '+mOldTrigger);
 
        List<String> lCaseIdsToSendNotification = new List<String>();
        List<String> lCaseIdsToSendRenewalMail = new List<String>();
        List<String> lCaseIdsToSendRenewalTPMail = new List<String>();
        List<String> lCaseIdsToSendDeployedMail = new List<String>();
        List<String> lCaseIdsToSendPVWarningMail = new List<String>();
        List<String> lCaseIdsToSendPVErrorMail = new List<String>();
        List<String> lCaseIdsToSendPVFailedMail = new List<String>();
        List<String> lCaseIdsToSendWaitingMail = new List<String>();
        List<String> lCaseIdsToSendOrderCertErrorMail = new List<String>();
        List<String> lCaseIdsToSendNewCertRequested = new List<String>();  
        List<String> lCaseIdsToSendCertRequestedWithLetsEncrypt = new List<String>();  
        List<String> lCaseIdsToSendRenewalStarted = new List<String>();  
        List<String> CaseIdsToSendEmailNotification5Days= new List<String>();
        List<String> CaseIdsToSendEmailNotification15Days= new List<String>();         
        // changes by Vandhana
        List<String> CaseIdsToSendEmailNotification8Days= new List<String>();
    	List<String> CaseIdsToSendEmailNotification1DayAfter= new List<String>();
        //Added by aditi for ESESP-4697
        List<String> CaseIdsToSendEmailNotification3_2_1_7_12_30Days = new List<String>();
        Set<String> daysValForRetry = new Set<String>{'1', '2', '3', '7', '12', '30'};
        // Insert                          
        if(isInsert)
        {
            for(Case varCase :mNewTrigger.values())
            {
                if(mRecordTypes.get(varCase.RecordTypeId).equals('Web Experience'))
                {
                    if(varCase.Status == 'Renewal Started' &&
                       varCase.Request_Sub_Type__c == 'CPS-Automated' &&
                       varCase.Service__c == 'TLS/SSL Certificate Provisioning' &&
                       varCase.Request_Type__c == 'Renew Certificate' &&
                       varCase.CertificateAuthority__c !=  'Let\'s Encrypt')
                    {
                        lCaseIdsToSendRenewalMail.add(varCase.Id);
                    }
                    else if(varCase.Status == 'Renewal Started' &&
                            varCase.Service__c == 'TLS/SSL Certificate Provisioning' &&
                            varCase.Request_Type__c == 'Renew Certificate' &&
                            varCase.Request_Sub_Type__c == 'Third-Party')
                    {
                        lCaseIdsToSendRenewalTPMail.add(varCase.Id);       
                    }
                    
                    else if(varCase.Status == 'Renewal Started' &&
                            varCase.Request_Sub_Type__c == 'CPS-Automated' &&
                            varCase.CertificateAuthority__c ==  'Let\'s Encrypt')
                    {
                        lCaseIdsToSendRenewalStarted.add(varCase.Id);
                    }
                    
                    else if(varCase.Status == 'New Certificate Requested' &&
                            varCase.Request_Sub_Type__c == 'CPS-Automated' &&
                            varCase.CertificateAuthority__c !=  'Let\'s Encrypt')
                    {
                        System.debug('New Cert NO LE');
                        System.debug('CertAuth NO LE: ' + varCase.CertificateAuthority__c);
                        lCaseIdsToSendNewCertRequested.add(varCase.Id);
                    }
                    
                    else if(varCase.Status == 'New Certificate Requested' &&
                            varCase.Request_Sub_Type__c == 'CPS-Automated' &&
                            varCase.CertificateAuthority__c ==  'Let\'s Encrypt')
                    {
                        System.debug('New Cert LE');
                        System.debug('CertAuth LE: ' + varCase.CertificateAuthority__c);
                        lCaseIdsToSendCertRequestedWithLetsEncrypt.add(varCase.Id);
                    }
                }
            }
           
            if(lCaseIdsToSendRenewalMail.size() >0)
            {
                sendEmailForCPS(lCaseIdsToSendRenewalMail, false, 'Renewal_Started', false);       
            }
            if(lCaseIdsToSendRenewalTPMail.size()>0)
            {
                sendEmailForCPS(lCaseIdsToSendRenewalTPMail, false, 'Renewal_Started_for_Third_Party', false);
            }
            if(lCaseIdsToSendRenewalStarted.size()>0)
            {
                sendEmailForCPS(lCaseIdsToSendRenewalStarted, true, 'Renewal_Started_With_LetsEncrypt', false);
            }
            if(lCaseIdsToSendNewCertRequested.size()>0)
            {
                System.debug('New Cert NO LE');
                sendEmailForCPS(lCaseIdsToSendNewCertRequested, true, 'New_Certificate_Requested', false);
            }
            if(lCaseIdsToSendCertRequestedWithLetsEncrypt.size()>0)
            {
                System.debug('New Cert LE');
                sendEmailForCPS(lCaseIdsToSendCertRequestedWithLetsEncrypt, true, 'New_Certificate_Requested_With_LetsEncrypt', false);
            }          
        }
 
        // Update
        else if(isUpdate)
        {
            for(Case varCase :mNewTrigger.values())
            {
                if(mRecordTypes.get(varCase.RecordTypeId).equals('Web Experience')
                   && varCase.Status != mOldTrigger.get(varCase.Id).Status)
                {
                    if(varCase.Status == 'Renewal Started'
                       && varCase.Request_Sub_Type__c == 'CPS-Automated'
                       && varCase.CertificateAuthority__c !=  'Let\'s Encrypt')
                    {
                        lCaseIdsToSendRenewalMail.add(varCase.Id);
                    }
                    
                    if(varCase.Status == 'Renewal Started'
                       && varCase.Request_Sub_Type__c == 'Third-Party')
                    {
                        lCaseIdsToSendRenewalTPMail.add(varCase.Id);
                    }
                    
                    if(varCase.Status == 'Pre-verification Failed')
                    {
                        lCaseIdsToSendPVFailedMail.add(varCase.Id);
                    }
                   
                    // changes by Vandhana for CR 3550011
                    // removed checks for Case Request Type and Request Sub-type
                    if(varCase.Status == 'Post-verification Warning'
                       //&& varCase.Request_Sub_Type__c == 'CPS-Automated'
                       && varCase.Service__c == 'TLS/SSL Certificate Provisioning'
                       //&& varCase.Request_Type__c == 'Renew Certificate' 
                       )
                    {
                        lCaseIdsToSendPVWarningMail.add(varCase.Id);
                    }
                    
                    if(varCase.Status == 'Post-verification Error'
                       //&& varCase.Request_Sub_Type__c == 'CPS-Automated'
                       && varCase.Service__c == 'TLS/SSL Certificate Provisioning'
                       //&& varCase.Request_Type__c == 'Renew Certificate' 
                       )
                    {
                        lCaseIdsToSendPVErrorMail.add(varCase.Id);
                    }
                    
                    if(varCase.Status == 'Waiting on Change Management')
                    {
                        lCaseIdsToSendWaitingMail.add(varCase.Id);
                    }
                    
                    if(varCase.Status == 'Certificate Deployed')
                    {
                        lCaseIdsToSendDeployedMail.add(varCase.Id);
                    }
                    
                    if(varCase.Status == 'Error in Order at CA')
                    {
                        lCaseIdsToSendOrderCertErrorMail.add(varCase.Id);
                    }  
                }

				//Modified by Aditya to add logic to retry sending email for failed CPS cases
                if(((varCase.CPSExpiration5Days__c != mOldTrigger.get(varCase.Id).CPSExpiration5Days__c 
                   && varCase.CPSExpiration5Days__c) || (varCase.CPS_RetryEmailNotification5Days__c && varCase.CPS_RetryEmailNotification5Days__c != mOldTrigger.get(varCase.Id).CPS_RetryEmailNotification5Days__c))
                   && mRecordTypes.get(varCase.RecordTypeId).equals('Web Experience')) 
                {
                    CaseIdsToSendEmailNotification5Days.add(varCase.Id);
                }
                if(((varCase.CPSExpiration15Days__c != mOldTrigger.get(varCase.Id).CPSExpiration15Days__c 
                   && varCase.CPSExpiration15Days__c) || (varCase.CPS_RetryEmailNotification15Days__c && varCase.CPS_RetryEmailNotification15Days__c != mOldTrigger.get(varCase.Id).CPS_RetryEmailNotification15Days__c))
                   && mRecordTypes.get(varCase.RecordTypeId).equals('Web Experience'))
                {
                    CaseIdsToSendEmailNotification15Days.add(varCase.Id);
                }
                
                // changes by Vandhana
                if(((varCase.CPSExpiration8Days__c != mOldTrigger.get(varCase.Id).CPSExpiration8Days__c && varCase.CPSExpiration8Days__c) ||
                    (varCase.CPS_RetryNotificationforFailureDays__c != mOldTrigger.get(varCase.Id).CPS_RetryNotificationforFailureDays__c && varCase.CPS_RetryNotificationforFailureDays__c == '8'))
                   && mRecordTypes.get(varCase.RecordTypeId).equals('Web Experience'))
                {
                    CaseIdsToSendEmailNotification8Days.add(varCase.Id);
                }
                
                // changes by Vandhana
                if(((varCase.CPSExpiration1DayAfter__c != mOldTrigger.get(varCase.Id).CPSExpiration1DayAfter__c && varCase.CPSExpiration1DayAfter__c) || 
                    (varCase.CPS_RetryNotificationforFailureDays__c != mOldTrigger.get(varCase.Id).CPS_RetryNotificationforFailureDays__c && varCase.CPS_RetryNotificationforFailureDays__c == '1 Day After Expiry'))
                   && mRecordTypes.get(varCase.RecordTypeId).equals('Web Experience'))
                {
                    CaseIdsToSendEmailNotification1DayAfter.add(varCase.Id);
                }
                //Aditi - changes for ESESP-4697
                if(((varCase.CPSDaysBeforeExpiry__c != mOldTrigger.get(varCase.Id).CPSDaysBeforeExpiry__c && varCase.CPSDaysBeforeExpiry__c != null) ||
                (varCase.CPS_RetryNotificationforFailureDays__c != mOldTrigger.get(varCase.Id).CPS_RetryNotificationforFailureDays__c && daysValForRetry.contains(varCase.CPS_RetryNotificationforFailureDays__c)))
                && mRecordTypes.get(varCase.RecordTypeId).equals('Web Experience'))
                {
                    CaseIdsToSendEmailNotification3_2_1_7_12_30Days.add(varCase.Id);
                }
                System.debug('CaseIdsToSendEmailNotification5Days :: '+CaseIdsToSendEmailNotification5Days);
                System.debug('CaseIdsToSendEmailNotification15Days :: '+CaseIdsToSendEmailNotification15Days);
                System.debug('CaseIdsToSendEmailNotification8Days :: '+CaseIdsToSendEmailNotification8Days);
                System.debug('CaseIdsToSendEmailNotification1DayAfter :: '+CaseIdsToSendEmailNotification1DayAfter);
                System.debug('CaseIdsToSendEmailNotification3_2_1_7_12_30Days :: '+CaseIdsToSendEmailNotification3_2_1_7_12_30Days);
                
            }
            if(lCaseIdsToSendRenewalMail.size() >0)
            {
                sendEmailForCPS(lCaseIdsToSendRenewalMail, false, 'Renewal_Started', false);
            }
            if(lCaseIdsToSendRenewalTPMail.size()>0)
            {
                sendEmailForCPS(lCaseIdsToSendRenewalTPMail, false, 'Renewal_Started_for_Third_Party', false);
            }
            if(lCaseIdsToSendPVFailedMail.size() >0)
            {
                sendEmailForCPS(lCaseIdsToSendPVFailedMail, true, 'Pre_verification_Failed', false);
            }
            if(lCaseIdsToSendPVWarningMail.size()>0)
            {
                sendEmailForCPS(lCaseIdsToSendPVWarningMail, true, 'Post_verification_Warning_For_CPS_Automated', false);
            }
            if(lCaseIdsToSendPVErrorMail.size() >0)
            {
                sendEmailForCPS(lCaseIdsToSendPVErrorMail, true, 'Post_verification_Error_For_CPS_Automated', false);
            }
            if(lCaseIdsToSendWaitingMail.size()>0)
            {
                sendEmailForCPS(lCaseIdsToSendWaitingMail, true, 'Waiting_on_Change_Management', false);
            }
            if(lCaseIdsToSendDeployedMail.size()>0)
            {
                sendEmailForCPS(lCaseIdsToSendDeployedMail, true, 'Certificate_Deployed', false);
            }
            if(lCaseIdsToSendOrderCertErrorMail.size()>0)
            {
                sendEmailForCPS(lCaseIdsToSendOrderCertErrorMail, true, 'Error_in_Order_at_CA', false);
            } 
            if(CaseIdsToSendEmailNotification5Days.size()>0)
            {
                sendEmailForCPS(CaseIdsToSendEmailNotification5Days, true, 'CPSEmailNotification5days', true);
            }
            if(CaseIdsToSendEmailNotification15Days.size()>0)
            {
                sendEmailForCPS(CaseIdsToSendEmailNotification15Days, true, 'CPSEmailNotification15days', false);
            }
            // changes for ESESP-1446
            if(CaseIdsToSendEmailNotification8Days.size()>0)
            {
                sendEmailForCPS(CaseIdsToSendEmailNotification8Days, true, 'CPSEmailNotification8days', false);
            }
            if(CaseIdsToSendEmailNotification1DayAfter.size()>0)
            {
                sendEmailForCPS(CaseIdsToSendEmailNotification1DayAfter, true, 'CPSEmailNotification1dayAfter', false);
            }
            //Below blocks added by Aditi for ESESP-4697
            if(CaseIdsToSendEmailNotification3_2_1_7_12_30Days.size()>0)
            {
                sendEmailForCPS(CaseIdsToSendEmailNotification3_2_1_7_12_30Days, true, 'CPSEmailNotification3_2_1_12_7_30days', true);
            }
        }   
    }
    
    /*** Aditi - created this method to create a case for all the certificates expiring in next 5 days - ESESP-4697 **/
    public static void createCaseFor5DaysExpiry(List<Case> relatedCases, String caseDesc){
        
        Case eachCaserec;
        // List to store for Newly Created Case
        List<Case> newCaseList = new List<Case>();
        
        //Fetching Assignment Rule
        AssignmentRule assgnRule = [Select id,name from AssignmentRule where SobjectType ='Case' and Active=True limit 1];
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.AssignmentRuleHeader.assignmentRuleId = assgnrule.id;
        dmo.EmailHeader.TriggerUserEmail = true;
        
        //Storing the record type Ids
        Id setRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        
        // Loop for creating each Case
        for(Case cs : relatedCases)
        { 
            String setDescription;
            String formattedExpiryDate = cs.Expiration_Date__c != null?cs.Expiration_Date__c.format():null;
             
            setDescription = 'The below certificate is expiring is expiring in 5 days and the renewal is not complete.'
            +'\n\n AKAM Account Id : '+cs.Account.AKAM_Account_ID__c
            +'\n Account Name : '+cs.Account.Name
            +'\n Slot : '+cs.Slot__c
            +'\n CN : '+cs.CertificateCN__c
            +'\n Expiry Date : '+formattedExpiryDate
            +'\n CA : '+cs.CertificateAuthority__c;
            
            
            eachCaserec = new Case();
            eachCaserec.setOptions(dmo);
            eachCaserec.RecordTypeId            = setRecordTypeId;
            eachCaserec.AccountId               = cs.AccountId;
            eachCaserec.Service__c              = 'TLS/SSL Certificate Provisioning';
            eachCaserec.Request_Type__c         = 'Renew Existing Certificate';
            eachCaserec.Request_Sub_Type__c 	= 'N/A - Not Applicable';
            eachCaserec.Origin                  = 'Akamai';
            eachCaserec.Priority__c				= 'Standard';
            eachCaserec.Severity__c				= '3';
            eachCaserec.Status 					= 'Unassigned';
            eachCaserec.Subject                 = 'Certificate expiring in 5 days.';
            eachCaserec.Description             = setDescription+(caseDesc != null?'\n\n'+caseDesc:'');
            eachCaserec.Do_Not_Show_in_Portal__c= true;
            
            System.debug('eachCaserec :: '+eachCaserec);
            
            // Add the case record to List
            newCaseList.add(eachCaserec);
        }
        // Insert all Cases
        try{
            if(!newCaseList.isEmpty()){
                 insert newCaseList;
            }
        }
        catch(Exception ex){
            string setEmailSub = 'Exception: In creating new cases for certificates having 5 days before expiring.';
            string errorMessage =  	'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
                      				'Batch Class Name = SC_CPSNotifications\n' + 
                                	'Support Class Name = SC_Autogen_COB_Support\n' +
                                	'Method Name = createCaseFor5DaysExpiry\n';
            errorMessage += ex.getCause()+'..'+ex.getLineNumber()+'..'+ex.getMessage()+'..'+ex.getTypeName()+'..'+ex.getStackTraceString();
            SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support(); 
          	sc_COBSupportCls.senEmailForError(setEmailSub, errorMessage);
        } 
    }
}