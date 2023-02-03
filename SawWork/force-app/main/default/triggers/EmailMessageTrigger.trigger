/*******************************************************************************************************
Name         :   EmailMessageTrigger
Author       :   Vinod Kumar (Appirio Offshore)
Created Date :   June 4,2013
Task         :   T-148640
Description  :  EmailMessage trigger
********************************************************************************************************
Lisha Murthy          11/11/2013        CR 2411301 - Need to disable trigger code for Service Cloud
- By-passing the trigger code for connection user.
Himanshu              25-Jun-14           Code Optimization(Release - 3.43)
Akhila                20-Mar-15         CR 2907264 - By passing Case's RecentUPdate flag update for emails with fromaddr=Case.OwnerEmail
Aditya                17-Feb-16         CR 3307861 -IsMicrosoftAzureAccount__c added in the caseMap Query
Sumanth               30-Sep-19         ESESP-2698 - SOCC Related Changes
Vandhana              01-March-2020     ESESP-2039 : AMG Lightning Migration
Pinkesh               19-May-2020       ESESP-3043 : Adding Private Email Draft Functionality
Vamsee				  01-Dec-2020		ESESP-4520 : IRAPT - Email to Business Executives 
Sharath               01-Dec-2020       ESESP-4435 : Validation to prevent Cross Sharing Incidents  
Vandhana              23-Feb-2021       ESESP-2346 : Carrier to Tech Migration
Aravind               28-Jul-2021       ESESP-5595 : Added support for SenderId email header
Jay                   29-Dec-2021       ESESP-5526 : Added call to EmailMessageTriggerHandler.emailToCNS on after insert/update
Sheena				  07-Jan-2021		ESESP-6229 : Update Task LOE on Managed Security Case with defaulte Email Template values
Sharath               23-Fedb-2022      ESESP-6716: Added check to bypass Milestone logic for jarvis
Sheena                24-Feb-2022       ESESP-5143 : Enable 'Internal Case Survey Enabled' field on Case on Customer Email from Owner and based on Case Criteria 
*/
trigger EmailMessageTrigger on EmailMessage ( after insert, after update, before insert) {
    
    if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
    {
        
        //IRAPT : Validation for Seending Business Executive Email
        if(Trigger.isInsert && Trigger.isBefore){
            List<EmailMessage> emailMessageList = new List<EmailMessage>();
            User loggedinUser = [SELECT SC_SI_Email_Business_Exec__c FROM User WHERE id =: Userinfo.getUserId()];
            For(EmailMessage eachEM : Trigger.new){
                if(eachEM.RelatedToId != null && String.valueOf(eachEM.RelatedToId).startsWith(SC_SI_Service_Incident__c.sobjecttype.getDescribe().getKeyPrefix()) && 
                  loggedinUser.SC_SI_Email_Business_Exec__c == False){
                    emailMessageList.add(eachEM); 
                    
                }
            }
           if(emailMessageList.size() > 0)
               SC_SI_Utility.EmailBusinessExecValidation(emailMessageList);
            //ESESP-5595 - Set Created By, Last Modified By and From Name fields of EmailMessage based on SenderId header if present
            if(EmailToCaseHandler.senderIdHeader != null){
                Trigger.new[0].CreatedById = EmailToCaseHandler.senderIdHeader;
                Trigger.new[0].LastModifiedById = EmailToCaseHandler.senderIdHeader;
                Trigger.new[0].FromName = [SELECT Name FROM User WHERE Id = :EmailToCaseHandler.senderIdHeader].Name;
            }
        }
        
        if(Trigger.isInsert && Trigger.isBefore && SC_SendEmailFromAPIs.sendEmailFromMuleSoft){       	
            Trigger.new[0].CreatedById = SC_SendEmailFromAPIs.senderId;	
            Trigger.new[0].LastModifiedById = SC_SendEmailFromAPIs.senderId;	
        }
        // trigger to update the Case.Resolution Sent checkbob and case Milestone with name Initial Response = Completed.
        // Related task: T-148640, T-148455
        if(trigger.isAfter && (trigger.isInsert || trigger.isUpdate)){
            //Changes by Sharath for ESESP-4435
            Set<String> recordTypeToValidate = new Set<String>();
            Boolean shouldValidate =false;
            for (SC_Utility__mdt utilRec : [Select Value_Text__c,developername from SC_Utility__mdt where 
                                            Active__c = true and (developername like 'EmailMessage_Validation_On' or developername like 'EmailMessage_Validation_RecordTypes%')])
            {
                if(utilRec.developername == 'EmailMessage_Validation_On' && utilRec.Value_Text__c != null)
                {
                    shouldValidate = Boolean.valueOf(utilRec.Value_Text__c);
                }
                else if(utilRec.Value_Text__c != null)
                {
                    recordTypeToValidate.addAll(utilRec.Value_Text__c.split(','));
                }
                system.debug('shouldValidate: ' + shouldValidate);
                system.debug('recordTypeToValidate: ' + recordTypeToValidate);
            }
            List<EmailMessage> emailMessagesToValidate = new List<EmailMessage>();
            Set<Id> emailMessagesToValidateCases = new Set<Id>();
            //End of changes for ESESP-4435            

            List<EmailMessage> lAllValidEmailMessages = new List<EmailMessage>();
            Boolean hasValidEmails = false;
            Set<Id> caseIds = new Set<Id>();
            for(EmailMessage em : Trigger.new) {
                System.debug('-------- Emailmessage status : ' + em.Status);
                if(em.Status != '5'){
                    //Changes by Sharath for ESESP-4435
                    if(shouldValidate && em.getQuickActionName() != null && 
                       !em.Force_Send__c && !em.Incoming && em.Customer_Email__c && 
                       em.ParentId != null && String.valueOf(em.ParentId).startsWith('500'))
                    {
                        emailMessagesToValidate.add(em);
                        emailMessagesToValidateCases.add(em.ParentId);
                    }
                    //End of changes

                    lAllValidEmailMessages.add(em);
                    hasValidEmails = true;
                    if(em.ParentId != null){
                        if(String.valueOf(em.ParentId).startsWith('500')) {
                            caseIds.add(em.ParentId);
                        }
                    }
                }
            }
            
            if(hasValidEmails){
                //Changes by Sharath for ESESP-4435: Added query on EmailMessage, included AccountId,Policy_Domain__c fields
                //Changes by Sheena for ESESP- 5143: Added Do_Not_Show_In_Portal_Picklist__c, Qualtrics_Survey_Notification_Sent__c,Internal_Case_Survey_Enabled__c,Service__c,Request_Type__c,Task_LOE__c fields on query
                List<Case> lAllCases = [Select Id,Resolution_Sent__c,CreatedBy.Name,Alert_Start_Time__c, Initial_Response_SOCC__c, First_Customer_Update_SOCC__c,Initial_Response_SOCC_Date__c,Real_Engagement_Time__c,
                                        CreatedDate,Status,Origin, Last_Case_Update__c, Resolved_Date__c,Next_Action__c, Last_Case_Owner_Update__c,Last_Non_Case_Owner_Update__c,Case_Owner_Email_address__c,
                                        RecordType_Name__c,Solution_Status__c,Recent_Update__c,Owner.Email, Isclosed, AKAM_Case_ID__c,OwnerId,
                                        IsMicrosoftAzureAccount__c,Partner_Joint_Troubleshooting_Status__c, RecordType.Name,Sub_Type__c,
                                        Do_Not_Show_In_Portal_Picklist__c, Qualtrics_Survey_Notification_Sent__c,Internal_Case_Survey_Enabled__c,
                                        Service__c,Request_Type__c,Support_Level__c,Subject,Account.Account_Status__c,Task_LOE__c,
                                        (select toaddress,bccaddress,ccaddress,FromAddress from emailmessages where customer_email__c = true 
                                         and id not in :emailMessagesToValidate and Status != '5' order by lastmodifieddate desc limit 1), AccountId,Policy_Domain__c

                                        From Case Where Id IN : caseIds And RecordType.Name IN ('Technical', 'AMG','CMG', 
                                                                                                'Billing', 'GSS CSAT', 'Invalid Case', 'Professional Services', 'Revenue Recognition',
                                                                                                'Stability Engineering', 'Partner Technical Support', 'Emerging Products Engineering',
                                                                                                'BOCC','Managed Security','Encoder Qualification','SecSales','SecLaw',
                                                                                                'Order Approval-Deal Desk','Order Approval-Escalations','Order Approval-Legal',
                                                                                                'Order Approval-Order Management','Order Approval-Others','Order Approval-Sales Manager','RCA Request')];
                
                //List of record types names to prepare the corresponding case map
                Set<String> sRecordTypeNameForCaseMap = new Set<String>{'Technical', 'AMG','CMG', 
                    'Billing', 'GSS CSAT', 'Invalid Case', 'Professional Services', 'Revenue Recognition',
                    'Stability Engineering', 'Partner Technical Support', 'Emerging Products Engineering',
                    'Managed Security','Encoder Qualification','SecSales','SecLaw','RCA Request'};

                        
                Set<String> sRecordTypeNameForCaseMapOA = new Set<String>{'Order Approval-Deal Desk','Order Approval-Escalations','Order Approval-Legal',
                            'Order Approval-Order Management','Order Approval-Others','Order Approval-Sales Manager'};
                                
                Set<String> sRecordTypeNameForCaseMSAzureMap = new Set<String>{'Technical','Managed Security'};
                //Changes by Sharath for ESESP-4435
                Map<Id,Case> caseMapForValidation = new Map<Id,Case>();
                //general cases
                Map<Id, Case> caseMap = new Map<Id, Case>();
                //OA related cases
                Map<Id, Case> caseMapOA = new Map<Id, Case>();
                //MS Azure related cases
                Map<Id,Case> caseMSAzureMap = new Map<Id,Case>(); // Aditya:Adding as part of MS Azure, Including Closed Case and Managed Security Record Type 
                //RCA Request related Cases
                Set<Id> rcaCasesSet = new Set<Id>();
                
                for(Case eachCase : lAllCases){
                    //Changes by Sharath for ESESP-4435: Check for Validating 
                    // changes by Vandhana for ESESP-2346 : bypass email message validation for Tech Carrier cases
                    if(!emailMessagesToValidateCases.isEmpty() && emailMessagesToValidateCases.contains(eachCase.Id) && recordTypeToValidate.contains(eachCase.RecordType.Name))
                    {                        
                        if(eachCase.RecordType.Name == 'Technical')
                        {   if(eachCase.Sub_Type__c != 'Carrier')
                            { caseMapForValidation.put(eachCase.Id, eachCase);}
                        }
                        else
                        {   caseMapForValidation.put(eachCase.Id, eachCase);}
                    }
                    //End of changes
                
                    if(sRecordTypeNameForCaseMap.contains(eachCase.RecordType.Name) && eachCase.IsClosed == false){
                        caseMap.put(eachCase.Id, eachCase);
                    }
                    if(sRecordTypeNameForCaseMapOA.contains(eachCase.RecordType.Name)){
                        caseMapOA.put(eachCase.Id, eachCase);
                    }
                    if(sRecordTypeNameForCaseMSAzureMap.contains(eachCase.RecordType.Name) && eachCase.IsMicrosoftAzureAccount__c == true){
                        caseMSAzureMap.put(eachCase.Id, eachCase);
                    }
                    if( eachCase.RecordType.Name == 'RCA Request'){	
                        rcaCasesSet.add(eachCase.Id);	
                    }
                }
                //Changes by Sharath for ESESP-4435
                if(!emailMessagesToValidateCases.isEmpty())
                {
                    //system.debug('emailMessagesToValidateCases : ' + emailMessagesToValidateCases);
                    EmailMessageTriggerHandler.validateEmailMessageRecords(caseMapForValidation,emailMessagesToValidate);
                }
                //End of Changes
                
                List<EmailMessage> scEmails = new List<EmailMessage>();
                List<EmailMessage> oaCaseEmails = new List<EmailMessage>();//OA Changes
                Map<EmailMessage,Boolean> scEmailsforRecentUpdate = new Map<EmailMessage,Boolean>();
                Map<EmailMessage,Boolean> scOACaseEmails = new Map<EmailMessage,Boolean>();//OA Changes
                List<EmailMessage> rcaCaseEmails = new List<EmailMessage>();//RCA Changes

                for(EmailMessage em : lAllValidEmailMessages) {
                    //Aditya:Using caseMSAzureMap to sepearte create Activity and Recent Update for MS Azure Cases
                    if(!caseMap.isEmpty() && caseMap.containsKey(em.ParentId)) {
                        scEmails.add(em);
                        scEmailsforRecentUpdate.put(em,caseMap.get(em.ParentId).Owner.Email!=em.FromAddress);
                    }
                    // Vandhana : OA cases
                    if(!caseMapOA.isEmpty() && caseMapOA.containsKey(em.ParentId)) 
                    {
                        oaCaseEmails.add(em);
                        scOACaseEmails.put(em,caseMapOA.get(em.ParentId).Owner.Email != em.FromAddress);
                    }
                    //Bhavesh:RCA Cases
                    if( !rcaCasesSet.isEmpty() && rcaCasesSet.contains(em.ParentId) ){
                        rcaCaseEmails.add( em );
                    }
                    
                    //Aditya:Using caseMSAzureMap to sepearte create Activity and Recent Update for MS Azure Cases
                    //Only Managed Security Cases and Closed Case will fall into this map
                    else if(MSAzureHandler.varActivateMSAzureCode && !caseMSAzureMap.isEmpty() && caseMSAzureMap.containsKey(em.ParentId) && caseMSAzureMap.get(em.ParentId).Owner!=null){
                        scEmails.add(em);
                        scEmailsforRecentUpdate.put(em,caseMSAzureMap.get(em.ParentId).Owner.Email!=em.FromAddress);  
                    }
                } 
                if(!oaCaseEmails.isEmpty() && !scOACaseEmails.isEmpty())
                {
                    CaseTriggerClass_OA.updateOACaseStatus(scOACaseEmails, caseMapOA);
                }
                if(scEmails.size() > 0 && !caseMap.isEmpty() && !EmailMessageTriggerHandler.bypassMilestoneClosure){
                    EmailMessageTriggerHandler.UpdateCaseResolutionSent(scEmails,caseMap);
                }
                else if(MSAzureHandler.varActivateMSAzureCode){
                    EmailMessageTriggerHandler.UpdateCaseResolutionSent(scEmails,caseMSAzureMap);  
                }
                //bypassing emails for recent update when From Address = Case owner's email address
                if(scEmailsforRecentUpdate.size()>0 && !caseMap.isEmpty()){ 
                    EmailMessageTriggerHandler.setRecentUpdateOnCaseTrue(scEmailsforRecentUpdate,caseMap);
                }
                else if(MSAzureHandler.varActivateMSAzureCode){
                    EmailMessageTriggerHandler.setRecentUpdateOnCaseTrue(scEmailsforRecentUpdate,caseMSAzureMap);
                }
                
                //Code to set recent update for SOCC Cases//
                List<Case> MSCasesforRecentUpdate = new List<Case>();
                Map<Id,Case> MSCasesforRecentUpdateOutboundMap = new Map<Id,Case>();
                Map<Id,Case> msCasesforRecentUpdateInboundMap = new Map<Id,Case>(); //This list is for handling Recent Update for Inbound Emails for MS Cases
                //Changes by Vikas for Provisioning	
                Map<Id,Case> psCasesforRecentUpdateOutboundMap = new Map<Id,Case>();	
                Map<Id,Case> psCasesforRecentUpdateInboundMap = new Map<Id,Case>();	
                //End Changes by Vikas for Provisioning
                for(Case varCase:caseMap.Values())
                {
                    if(varCase.RecordType.Name=='Managed Security' && varCase.Origin=='Email' && varCase.CreatedBy.Name=='CRM Ops')
                    {
                        MSCasesforRecentUpdate.add(varCase);
                    }
                    if(varCase.RecordType.Name=='Managed Security')
                    {
                        MSCasesforRecentUpdateOutboundMap.put(varCase.Id,varCase);
                        msCasesforRecentUpdateInboundMap.put(varCase.Id,varCase);     //ESESP-2698
                    }
                    //Changes by Vikas for Provisioning	
                    if(varCase.RecordType.Name=='Professional Services')	
                    {	
                        psCasesforRecentUpdateOutboundMap.put(varCase.Id,varCase);	
                        psCasesforRecentUpdateInboundMap.put(varCase.Id,varCase);//ESESP-3663	
                    }	
                    //End of changes by Vikas for Provisioning
                }
                
                If(MSCasesforRecentUpdateOutboundMap.size()>0)
                {
                    EmailMessageTriggerHandler.handleRecentUpdateforMSCaseOutbound(scEmails,MSCasesforRecentUpdateOutboundMap,'Managed Security');
                }
                //ESESP-2698
                If(msCasesforRecentUpdateInboundMap.size()>0)
                {
                    EmailMessageTriggerHandler.handleRecentUpdateforMSCaseInBound(scEmails,msCasesforRecentUpdateInboundMap,'Managed Security');
                }
                If(MSCasesforRecentUpdate.size()>0)
                {
                    EmailMessageTriggerHandler.handleRecentUpdateforMSCase(MSCasesforRecentUpdate);
                }
                //Changes by Vikas for Provisioning	
                If(psCasesforRecentUpdateOutboundMap.size()>0)	
                {	
                    EmailMessageTriggerHandler.handleRecentUpdateforMSCaseOutbound(scEmails,psCasesforRecentUpdateOutboundMap,'Professional Services');	
                }	
                If(psCasesforRecentUpdateInboundMap.size()>0)	
                {	
                    EmailMessageTriggerHandler.handleRecentUpdateforMSCaseInBound(scEmails,psCasesforRecentUpdateInboundMap,'Professional Services');	
                }	
                //End Changes by Vikas for Provisioning
                //End of Code to set Recent update for SOCC Cases
                
                /**** Code for SOCC Metrics ****/
                
                //Collect All Managed Security Cases 
                Map<Id,Case> ManagedSecurityCasesMap = new Map<Id,Case>();
                
                //Create a Map of Eligible Emails and related MS Cases
                Map<EmailMessage,Case> ManagedSecurityemailcases = new Map<EmailMessage,Case>();
                
                Map<EmailMessage,Case> managedSecEmailMsgCaseMap = new Map<EmailMessage,Case>();
                Map<Id,Id> activityIdTemplateIdMap = new Map<Id,Id>();
                
                Map<Id,Case> amgCasesMap = new Map<Id,Case>();
                Map<EmailMessage,Case> amgEmailMsgCaseMap = new Map<EmailMessage,Case>();
                
                for(Case C:caseMap.values())
                {
                    if(C.RecordType.Name=='Managed Security')
                    {
                        ManagedSecurityCasesMap.put(C.Id, C);
                    }
                    if(C.RecordType.Name=='AMG' &&  String.valueOf(C.OwnerId).startsWith(Schema.SObjectType.User.getKeyPrefix()))
                    {
                        amgCasesMap.put(C.Id, C);
                    }
                }
                
                Boolean isOutbound = false;
                //Collect all Outgoing Emails where parentid is in ManagedSecurityCases and making sure the email in question is send to customer
                for(EmailMessage em : lAllValidEmailMessages)
                {  
                    //Code block to check if ToAddress Contains atleast one non-akamai address
                    if(em.ToAddress!=null)
                    {
                        for(String Address:em.ToAddress.split(';'))
                        {
                            if(!Address.contains('@akamai.com'))
                            {
                                isOutbound =true;
                                break;
                            }
                        }
                        if(em.Incoming==false && ManagedSecurityCasesMap.keyset().contains(em.ParentId) && isOutbound)
                        {
                            ManagedSecurityemailcases.put(em,ManagedSecurityCasesMap.get(em.ParentId));
                        }
                    }
                    
                    // Changes by Sheena for ESESP-6229 : Update Task LOE on Managed Security Case with defaulte Email Template values
                    if(ManagedSecurityCasesMap.keyset().contains(em.ParentId) && em.Incoming==false && em.EmailTemplateId != null)
                    {
                        managedSecEmailMsgCaseMap.put(em,ManagedSecurityCasesMap.get(em.ParentId));
                        activityIdTemplateIdMap.put(em.ActivityId, em.EmailTemplateId);
                    }
                    // Changes by Sheena for ESESP-5143 : Enable 'Internal Case Survey Enabled' field on Case
                    if(amgCasesMap.keyset().contains(em.ParentId) && em.FromAddress.equalsIgnoreCase(amgCasesMap.get(em.ParentId).Case_Owner_Email_address__c))
                    {
                        amgEmailMsgCaseMap.put(em, amgCasesMap.get(em.ParentId));
                    }
                }
                if(ManagedSecurityemailcases.size()>0)
                {
                    EmailMessageTriggerHandler.CalculateSOCCMetrics(ManagedSecurityemailcases);
                }
                if(!rcaCaseEmails.isEmpty()){
                    for( EmailMessage em : rcaCaseEmails ){
                        if (em.Incoming==false){
                            List<String> addresses = new List<String>();
                            addresses.addAll( em.ToAddress.split(';') );
                            if( em.CcAddress != NULL ){
                                addresses.addAll( em.CcAddress.split(';') );
                            }
                            if( em.BccAddress != NULL ){
                                addresses.addAll( em.BccAddress.split(';') );
                            }
                            for( String Address: addresses ) {
                                if(!Address.contains('@akamai.com')){
                                    em.addError('Warning: You are not authorized to send an Email to External users.');
                                } 
                            }
                            
                            
                        }
                    }
                }
                if(!managedSecEmailMsgCaseMap.isEmpty())
                {
                    EmailMessageTriggerHandler.calculateSOCCCaseLOE(managedSecEmailMsgCaseMap, activityIdTemplateIdMap);
                } 
                if(!amgEmailMsgCaseMap.isEmpty())
                {
                    EmailMessageTriggerHandler.internalAMGSurveyCheck(amgEmailMsgCaseMap, isOutbound);
                }
            }
        }
    }
    if(Trigger.isAfter && Trigger.isInsert) {
        SC_JARVIS_CustomerTouchpoints.handleJarvisEmailInserts(Trigger.new);
        EmailMessageTriggerHandler.emailToCNS(Trigger.new);
    }
    if(Trigger.isAfter && Trigger.isUpdate) {
        SC_JARVIS_CustomerTouchpoints.handleJarvisEmailUpdates(Trigger.newMap, Trigger.Old);
        EmailMessageTriggerHandler.emailToCNS(Trigger.new);
    }
}