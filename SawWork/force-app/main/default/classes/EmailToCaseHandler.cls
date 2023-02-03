/******************************************************************************
 * Name             : EmailToCaseHandler
 * Created By       : Pitamber Sharma
 * Created Date     : 07-May-2013
 * Purpose          : Inbound Email Handler to create/update 
                      Technical/Business/Billing Support Cases.
Last Modified BY       Last Modified Date  Purpose
 ----------------      ------------------  ---------
 Himanshu               27-March-14         Added condition to handle Contact Account Validation
 Vijetha Vijayendran    23-Apr-14           Added condition to handle Billing Experience Survey cases
 Himanshu               28-APR-14           Added condition for Portal Check. If Portal is Unchecked, then make Html Attachment
                                           as Private.
 Kunal Sharma           05/21/2014          Removed extra SOQLs, moved the record type in custom setting,Added new fuctionality for
                                           EPE record type.                                           
 Kunal Sharma           06/27/2014          Added new functionality for Prolexic.                                                                  
 Akhila Vidapanapati    06/27/2014          Added exception handlings on String too long,out of bounds   
 Himanshu               22-AUG-14           CR# 2485821 - Uncheck "Do Not Show in Portal for Non Akamai Address    
 Kunal Sharma           01/29/2015          CR 2871264: Changes for reopening Managed Security Cases.                                                                       
 Akhila                 20-Mar-15           CR 2907264 - By passing Case's RecentUPdate flag update for emails with fromaddr=Case.OwnerEmail
 Himanshu               13-Jul-2015         CR# 3064461 - Trim Email Subject if it is exceeding 255 character
 Akhila                 30-Jul-15           CR 3077901 - To fix duplicate case creation - Changed String.Contains to Set.Contains
Jay                     24-Aug-2015         Cr:3127251 - when emails comes from akamai address , dont move from transition queue
Vamsee                  21-Sep-2015         CR- 3132621- Adding 911@prolexic.com as supported email address for managed security.
Deepak Saxena           05-Jan-2015         CR - 3210681 & 3159401, To avoid any validation error at the time of Managed Security Case creation
Aditya                  17-Feb-2016         CR 3307861 Added MS Azure Visibility Changes 
Akhila                  20-Jan-16           Added calls to methods : isPartnerActivity
Himanshu                18-Sep-2016         CR#3514321 - Truncating Email Header to 32000 char before Inserting EmailMessage
Vamsee                  19-Sep-2016         CR 3156751 - Detect CMP Alerts and set CMP Alerts Sub Type
Vamsee          `       24-Oct-2016         CR 3503271 - Email to Case for Encoder Qualification Record type.
Pinkesh                 09-Jan-2016         CR 3528581 -  Update CCare queue label prefixes from CC to ATS (Akamai Technical Support)
Vamsee                  09-Jan-2016         CR 3614171 - Avoid Missing target address Exception 
Vandhana Krishnamurthy  27-Jan-2017         CR 3628251 - Cases create via email should to default to Sev 3 not Sev 2
Vandhana Krishnamurthy  1-Feb-2017          CR 3630471 - Closed tickets (linked to an SI) getting re-opened when SI is moved between phases
Vandhana Krishnamurthy  20-Feb-2017         CR 3662693 - SOC : Remove obsolete email addresses for Managed Security email-to-case
Pinkesh Rathore         23-Mar-2017         CR 3681272 - Trimmed Description for Managed Security Cases till 3000 chars and attached the email transcript to the Case.
Pinkesh Rathore         21-Jun-2017         ESESP-598 - Added legacy_type__c field for SOASTA
Vandhana Krishnamurthy  21-Feb-2018         ESESP-852 - Nominum Service Cloud Integration
Vamsee                  23-Feb-2018         ESESP-1011: Pause/Resume the SLA Clock for Nominum
Aditya                  18-Jan-2019         ESESP-1402: Creation of a queue for AMP
Aditya                  23-Mar-2019         ESESP-1703 : InfoSec-SecLaw
Pinkesh                 23-Apr-2019         ESESP-1542 : For AMG, for customer updates send email to case owner
Sumanth                 29-Apr-2019         ESESP-2256 & ESESP-2205
Sumanth                 27-May-2019         ESESP-2313
Vandhana            20-Feb-2019       ESESP-1989 : Order Approval - approve/reject Approve Detail records via Email
Vishnu                  14-Aug-2019         ESESP-2362  CMG Team Case Management System from E-mails
Vandhana          26-Sept-2019        ESESP-2036  Autoresponse to emails with support@akamai.com in the CC: list
Vandhana                30-Sept-2019        ESESP-689   AMG emails sent internally to create new cases
Pinkesh                 21-Oct-2019         ESESP-2777   AMG Break Fix: Contact ID shared in the email body is not getting set on the AMG case
Pinkesh                 22-Oct-2019         ESESP-2476   Setting correct Content-Type on the attachments
Vandhana        18-May-2020     ESESP-2533  Email To Case for S2ET
Vandhana    19-Feb-2021   ESESP-2346  Carrier Migration to Technical Cases
Sharath       July 26 2021                  ESESP-4356: Jarvis
Aravind                 28-Jul-2021         ESESP-5595 : Added support for SenderId email header
Sujay           07-Sep-2021     ESESP-5678 : Adding new entry for email to Case.
Sujay           12-OCT-2021     ESESP-5981 : Email sent to S2et are queued to 24PS queue.
Aravind                 21-Oct-2021         ESESP-4714 : Added CMG case creation acknowledgement
Jay                     29-Dec-2021         ESESP-5526   Added call to SC_CNSUtility.emailToCNSAsync to send income email message to CNS subscribers
*****************************************************************************/

global class EmailToCaseHandler implements Messaging.InboundEmailHandler 
{
    public static Id senderIdHeader;

    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) 
    {
        // boolean to Check Out Of Office
        boolean isOutOfOffice = false;
        
        System.debug('From Name '+email.FromName);
        //ESESP-2313 From Name Salesforce Bounces
        Set<String> BounceNames = new Set<String>([Select Value_Text__c from SC_Utility__mdt where MasterLabel = 'Bounce From Name' limit 1].Value_Text__c.split(','));
        
        
        //Boolean flag to filter 'Salesforce Bounce Forwarder' emails
        Boolean bounceforwarder = false;
        //String that stores Case Id obtained from Attachments for Salesforce Bounce forwarder Scenario
        String CasebounceId;
        
        if(email.binaryAttachments != Null && email.binaryAttachments.size() > 0 && email.FromName!=null && BounceNames.contains(email.FromName))
        {
          for(integer i = 0 ; i < email.binaryAttachments.size() ; i++)
          {
        
             //system.debug('Attachment Name  '+ i + email.binaryAttachments[i].filename);
             system.debug('Attachment Name  '+ i + email.binaryAttachments[i].filename);
             //system.debug('Attachment Body  ' + i + email.binaryAttachments[i].body.toString());
              system.debug('Encoded body'+EncodingUtil.base64Encode(email.binaryAttachments[i].body));
              system.debug('Content type of email'+email.binaryAttachments[i].headers);
              
              Boolean imageFlag1=false;
              //Boolean imageFlag2=false;
              
              for(Messaging.InboundEmail.Header CT:email.binaryAttachments[i].headers)
              {
                  System.debug(CT.Name);
                  System.debug(CT.Value);
                  if(CT.Name=='Content-Type' && CT.Value!=null && (CT.Value.contains('image')||CT.Value.contains('application/pdf')))
                  {                         
                      imageFlag1=true;
                  }
                  
                  if(imageFlag1)
                  {
                      break;
                  }
              }
              
               if(imageFlag1)
               {
                 continue;
                         
               }
               
               if(!imageFlag1)
               {
               
                   system.debug('Attachment Body  ' + i + email.binaryAttachments[i].body.toString());
               
               }
              
             if(email.binaryAttachments[i].body.toString().contains('AKAM-CASE #'))
             {
                  CasebounceId = email.binaryAttachments[i].body.toString().substringAfter('[AKAM-CASE #').substringBefore(']');
                  bounceforwarder = true;
                  System.debug('CasebounceId '+CasebounceId);
                  break;
                  
                 
             }
             else if(email.binaryAttachments[i].body.toString().contains('CASE #'))
             {
                  CasebounceId = email.binaryAttachments[i].body.toString().substringAfter('CASE #').substringBefore(':');
                  bounceforwarder = true;
                  System.debug('CasebounceId '+CasebounceId);
                  break;
                  
             }
             else if(email.binaryAttachments[i].body.toString().contains('{'))
             {
                  CasebounceId = email.binaryAttachments[i].body.toString().substringAfter('{').substringBefore('}');
                  bounceforwarder = true;
                  System.debug('CasebounceId '+CasebounceId);
                  break;
                  
             }
          }
        }
                
        // Condition for Checking Out Of Office Reply
        try
        {
            // Condition for out of Office
            if(email.subject <> null && (email.subject.toLowerCase().contains('out of office') || 
                email.subject.toLowerCase().contains('out of the office')))
            {
                isOutOfOffice = true;
            }
        } 
        catch(exception e){}
        
        Environment_Setup__c environmentSetup = Environment_Setup__c.getInstance();
        if(environmentSetup.Active_Org__c && isOutOfOffice == false)
        {
            map<string, Schema.RecordTypeInfo> mCaseRecordType = Case.sObjectType.getDescribe().getRecordTypeInfosByName();
            list<string> lRecordTypeName = SCRecordTypeCustomSetting__c.getValues('EmailToCaseRT').RecordTypeName__c == null ? new list<string>() : SCRecordTypeCustomSetting__c.getValues('EmailToCaseRT').RecordTypeName__c.split(',');
            set<string> sReopenCaseRecordType = new set<string>(); 

            sReopenCaseRecordType.addAll(SCRecordTypeCustomSetting__c.getValues('ReopenRT').RecordTypeDeveloperName__c == null ? new list<string>() : SCRecordTypeCustomSetting__c.getValues('ReopenRT').RecordTypeDeveloperName__c.split(','));

            Map<String,Id> rTypeMap = new Map<String,ID>();
            for(string varRecordTypeName :lRecordTypeName)
            {
                if( mCaseRecordType.containsKey(varRecordTypeName.trim()))
                {
                    rTypeMap.put( varRecordTypeName.trim(), mCaseRecordType.get(varRecordTypeName.trim()).getRecordTypeId());
                }
            }
            
            String toAddresses = EmailToCaseUtility.listToString(email.toAddresses);
            Set<String> toAddressesSet = new Set<String>(toAddresses.split(';'));
            String ccAddresses = EmailToCaseUtility.listToString(email.ccAddresses);
            Set<String> ccAddressesSet = new Set<String>(ccAddresses.split(';'));

            // changes by Vandhana - added BCC email functionality for Managed Security for CR 3605091
            //String bccAddresses = EmailToCaseUtility.listToString(email.bccAddresses);
            //Set<String> bccAddressesSet = new Set<String>(bccAddresses.split(';'));
            
            String emailBodyText;
            String emailSubjectText = email.subject;
            System.debug('VK - EMAIL SUBJECT : ' + emailSubjectText);
            String caseNumber;

            //string emailAddressForProlexic = SC_FromEmailAddress__c.getValues('ProlexicFromEmailAddress').FromAddress__c.trim() ;

            //Integer index;
            String taskBodyText;
            Contact con;
            Contact amgCon;
            Case ca = null;
            Boolean CasefoundFlag = false;
            Boolean NoContactFoundFlag = true;
            integer noOfNonAkamContact = 0;
        
            if(email.plainTextBody != null) 
            {
                emailBodyText = email.plainTextBody;
            }
            else if(email.htmlBody != null) 
            {
                emailBodyText = email.htmlBody.stripHtmlTags();//EmailToCaseUtility.convertHtmlBodyToText(email.htmlBody);
            }
            else
            {
                emailBodyText = '';
            }
            
            //Check incoming email if is survey follow up email, handle it differently
            if(email.fromAddress.containsIgnoreCase('@feedback.akamai.com'))
            {
                List<String> surveyEmails = new List<String>();
                for(SurveyEmailHandler_CS__c cs : SurveyEmailHandler_CS__c.getAll().values()) {
                    surveyEmails.add(cs.Email_Address__c);
                }
                
                handleSurveyEmails(toAddressesSet, email, emailBodyText, rTypeMap, surveyEmails);
                return null;
            }
            
            Map<String, List<String>> emailRecordTypeMap = new Map<String, List<String>>();
            for(EmailHandler_CS__c eCS : EmailHandler_CS__c.getAll().values())
            {
                //[Select Record_Type__c, Email_Address__c From EmailHandler_CS__c]) {
                if(!emailRecordTypeMap.containsKey(eCS.Record_Type__c))
                {
                    emailRecordTypeMap.put(eCS.Record_Type__c, new List<String>());
                }
                emailRecordTypeMap.get(eCS.Record_Type__c).add(eCS.Email_Address__c);
            }
            System.debug('!!! Email Rec Type Map : ' + emailRecordTypeMap.get('Technical'));
            
            // a list of possible delimiter
            List<String> delimiters  = new List<String>{'[AKAM-CASE #','{','Case #'};
                String delimiter,endDelimiter;
            
            system.debug('Before for loop');
            for(String strDelimiter : delimiters)
            {
                System.debug('Inside delimiter for loop');
                System.debug('VK! Inside delimiter - ' + emailSubjectText);
                if(emailSubjectText.indexOfIgnoreCase(strDelimiter)!=-1)
                {
                    System.debug('VK! - index of ' + strDelimiter);
                    if(strDelimiter == '[AKAM-CASE #')
                    {
                        endDelimiter = ']';  
                    }
                    else if(strDelimiter == '{')
                    {
                        endDelimiter = '}';
                    }
                    else if(strDelimiter == 'Case #')
                    {
                        endDelimiter = ':';
                    }
                    delimiter = strDelimiter;
                    break;
                }   
            }
        
            try
            {
                 system.debug('Inside try block');
                 system.debug('delimiter ' + delimiter);
                if(delimiter != null) 
                {
                  system.debug('Inside if in try block');
                    CasefoundFlag = true;
                    String CasenumberforQuery;
                    caseNumber = EmailToCaseUtility.getCaseNumber(emailSubjectText,delimiter,endDelimiter);
                   
                    system.debug('caseNumber '+caseNumber);
                    //IsMicrosoftAzureAccount__c,Partner_Joint_Troubleshooting_Status__c added in the query as part of MS Azure
                    for (Case cas : [Select Id,IsMicrosoftAzureAccount__c,Partner_Joint_Troubleshooting_Status__c,Do_Not_Show_in_Portal__c,Owner.Email,
                                     RecordType.DeveloperName,Status,OwnerId,Owner.Name,Owner.Type,AKAM_Case_ID__c, RecordType.Name, AKAM_Created_Date__c, Contact.Name, Subject, Sub_Type__c,
                                     (Select Id,Name,Approval_Status__c from Approval_Details__r) 
                                     from Case where AKAM_Case_ID__c = : caseNumber ]) 
                    {
                        ca = cas;
                    }
                    if(ca == null) 
                    {
                        CasefoundFlag = false;
                    }    
                }
                else if(bounceforwarder)
                {
                     system.debug('Inside else');
                     CasefoundFlag = true;
                     for (Case cas : [Select Id,IsMicrosoftAzureAccount__c,Partner_Joint_Troubleshooting_Status__c,Do_Not_Show_in_Portal__c,Owner.Email,RecordType.DeveloperName,
                                      Status,OwnerId,Owner.Name,Owner.Type,AKAM_Case_ID__c, Sub_Type__c,
                                      (Select Id,Name,Approval_Status__c from Approval_Details__r), 
                                      RecordType.Name, AKAM_Created_Date__c, Contact.Name, Subject from Case where AKAM_Case_ID__c = :CasebounceId ]) 
                    {
                        ca = cas;
                    }
                    
                    if(ca == null) 
                    {
                        CasefoundFlag = false;
                    }   
                }
            }

            catch(StringException e)
            {
               system.debug('Inside catch block');
                if(email.FromAddress.contains('akamai.com'))
                {
                    String[] emailRecipient = new String[]{email.FromAddress};
                    Id noReply = SC_FromEmailAddress__c.getValues('Noreply').OrgAddressId__c;
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    String MailBodyText = 'Dear Akamai user,\n'+'Your recent email to a Case has a malformed subject line:\n\n'+
                        email.Subject+
                        '\n\nand the Case ID could not be detected.  To properly attach to the case, please correct the Subject line and resend your message with the AKAM Case ID in the correct format.'+
                        'Examples of the correct format are:\n'+'- [AKAM-CASE #F-CS-123456]\n- {F-CS-123456}\n- Case #F-CS-123456:'+ 
                        '\n\nThanks,\nThe Akamai Service Cloud team'+'\n======';
                    mail.setPlainTextBody(MailBodyText);
                    mail.setToAddresses(emailRecipient);
                    mail.setOrgWideEmailAddressId(noReply);
                    mail.setSubject('Please resend your message - Malformed Case ID tag in Subject line');
                    Messaging.sendEmail(new Messaging.SingleEmailmessage[] {mail});
                    return null;
                }
                else
                CasefoundFlag=false;
            }

            System.debug('!!! CASE FOUND : ' + CasefoundFlag);
                
            if(!CasefoundFlag && emailBodyText.contains('ref:') && emailBodyText.contains(':ref'))
            { 
                String caseRefId = emailBodyText.subString(emailBodyText.indexOf('ref:')+4, emailBodyText.indexOf(':ref'));
            
                try
                {
                    Id csId = Cases.getCaseIdFromEmailThreadId(caseRefId);
                    if(csId != null) 
                    {
                        // Added by Himanshu - 3.41 Release
                        //IsMicrosoftAzureAccount__c,Partner_Joint_Troubleshooting_Status__c added in the query as part of MS Azure
                        for(Case cas : [Select Id,IsMicrosoftAzureAccount__c,Partner_Joint_Troubleshooting_Status__c,Do_Not_Show_in_Portal__c,Owner.Email,
                                        RecordType.DeveloperName,Status,OwnerId,Owner.Name,Owner.Type,AKAM_Case_ID__c, 
                                        RecordType.Name, AKAM_Created_Date__c, Contact.Name, Subject, Sub_Type__c,
                                        (Select Id,Name,Approval_Status__c from Approval_Details__r)  
                                        from Case   
                                        where Id = :csId ]) 
                        {
                            ca = cas;
                        }
                        
                        if(ca != NULL)
                        CasefoundFlag = true;
                    }
                }

                catch(Exception e){}
            }
          

            if(CasefoundFlag && ca!= NULL && sReopenCaseRecordType.contains(ca.RecordType.DeveloperName) && ca.Status.contains('Close'))
            {
                // changes by Vandhana for CR 3628251
                // modified re-open logic to exclude email-case triggered on update on SI
                if(!emailSubjectText.contains(' Update on Service Incident #'))
                {
                    ca.Status = 'Reopened';
                    ca.Reopened__c = true;
                    try
                    {
                        update ca;
                    }
                    catch(Exception e){}
                }
            }

            /* Changes by Vamsee for ESESP-1011
             * Update the case status to Work in Progress when we receive response from customer
             * Unpause the SLA Clock */
            // changes by Vandhana for ESESP-2346 (Carrier Migration to Technical)
            
            //if(CasefoundFlag && ca!= NULL && ca.RecordType.DeveloperName == 'Carrier_Products' && (!email.fromAddress.containsIgnoreCase('@akamai.com')))
            if(CasefoundFlag && ca!= NULL && ca.RecordType.DeveloperName == 'Technical' && ca.Sub_Type__c == 'Carrier' && (!email.fromAddress.containsIgnoreCase('@akamai.com')))
            {
                ca.IsStopped = false;
                ca.Status = (ca.Status != 'Unassigned') ? 'Work in Progress' : ca.Status;
                try
                {
                    update ca;
                }
                catch(Exception e){}
            }
            
            /* Changes by Pinkesh for ESESP-1542
      * Send email to Case Owner if case owner's email is not present in To or CC address for AMG Cases 
      */
            if(CasefoundFlag && ca!=NULL && ca.RecordType.DeveloperName == 'AMG' && ca.Owner.Type == 'User' 
               && !(toAddressesSet.contains(ca.Owner.Email.toLowerCase()) 
                    || ccAddressesSet.contains(ca.Owner.Email.toLowerCase())) 
               && !(email.fromAddress.equalsIgnoreCase(ca.Owner.Email)))
            {
                sendEmailToOwner(ca);
            }
            
            for(Contact c : [select Id, accountId,email from Contact where email = :email.fromAddress and Login__c != null]) 
            {
                con = c;
                // Count No Of Non Akamai Contact exist for From Address
                if(!c.email.contains('@akamai.com'))
                {
                    noOfNonAkamContact++;
                }
            }

            /* ORDER APPROVAL CHANGES */  
            System.debug('BEFORE OA');  
            if(CasefoundFlag && ca!= NULL   
               && (ca.RecordType.DeveloperName == 'Order_Approval_Others'   
                   || ca.RecordType.DeveloperName == 'Order_Approval_Escalations' 
                  || ca.RecordType.DeveloperName == 'Order_Approval_Sales_Manager') 
              ) 
            { 
                System.debug('Entered OA block');
                
                String body = emailBodyText;
                if(body.contains('\"Approved\" or \"Rejected\"') ){
                  body = body.remove('\"Approved\" or \"Rejected\"');                 
                }
                Map<String,String> subjStat = new Map<String,String>(); 
                  
                List<SC_Order_Approval__mdt > subjValue = [SELECT Value__c,MasterLabel  
                                                   FROM SC_Order_Approval__mdt    
                                                   WHERE MasterLabel IN ('OA Email2Case Approve', 'OA Email2Case Reject')   
                                                   AND Active__c = TRUE]; 
                for(SC_Order_Approval__mdt mdt : subjValue) 
                { 
                    if(mdt.MasterLabel == 'OA Email2Case Approve')  
                        subjStat.put('Approve',mdt.Value__c); 
                    else  
                        subjStat.put('Reject',mdt.Value__c);  
                } 
                  
                  
                Pattern app = Pattern.compile('(^(?i)('+ subjStat.get('Approve') +')$)'+  
                                                  '|(^(?i)('+ subjStat.get('Approve') +')[\\p{Blank}\\p{Punct}]+)'+ 
                                                  '|([\\p{Blank}\\p{Punct}]+(?i)('+ subjStat.get('Approve') +')[\\p{Blank}\\p{Punct}]+)'+ 
                                                  '|([\\p{Blank}\\p{Punct}]+(?i)('+ subjStat.get('Approve') +')$)');  
                  
                Pattern rej = Pattern.compile('(^(?i)('+ subjStat.get('Reject') +')$)'+ 
                                                  '|(^(?i)('+ subjStat.get('Reject') +')[\\p{Blank}\\p{Punct}]+)'+  
                                                  '|([\\p{Blank}\\p{Punct}]+(?i)('+ subjStat.get('Reject') +')[\\p{Blank}\\p{Punct}]+)'+  
                                                  '|([\\p{Blank}\\p{Punct}]+(?i)('+ subjStat.get('Reject') +')$)'); 
                  
                Matcher appMatch = app.matcher(emailSubjectText); 
                Matcher rejMatch = rej.matcher(emailSubjectText); 
                
                Matcher appBodyMatch = app.matcher(body); 
                Matcher rejBodyMatch = rej.matcher(body);
                  
                List<Approval_Details__c> appDetList = new List<Approval_Details__c>(); 
                List<Approval_Details__c> appDetSetUpdate = new List<Approval_Details__c>();  
                
                Boolean isApprove = False;
                Boolean isReject = false;
                  
                for(String keyword : subjStat.get('Approve').split('\\|')){
                    if(body.toLowerCase().contains(keyword.toLowerCase()) ){
                        isApprove = true;
                        break;
                    }
                }
                for(String keyword : subjStat.get('Reject').split('\\|')){
                    if(body.toLowerCase().contains(keyword.toLowerCase()) ){
                        isReject = true;
                        break;
                    }
                }
                if(appMatch.find() || appBodyMatch.find() || isApprove )  
                { 
                    for(Approval_Details__c aD : ca.Approval_Details__r)  
                    { 
                        if( emailSubjectText.contains(ad.Name) || ca.RecordType.DeveloperName == 'Order_Approval_Escalations')  
                        { 
                            aD.Approval_Status__c = 'Approved'; 
                            aD.Validation_Override__c = true; 
                            appDetSetUpdate.add(aD);  
                            if( ca.RecordType.DeveloperName == 'Order_Approval_Sales_Manager'){
                                ca.Status = 'Closed-Approved';
                                ca.Validation_Override__c = true;
                                CaseTriggerClass_OA.skipCloseCaseEmailLogic = true;
                            }
                        } 
                    } 
                } 
            else  
                if(rejMatch.find() || rejBodyMatch.find() || isReject ) 
                { 
                    for(Approval_Details__c aD : ca.Approval_Details__r)  
                    { 
                        if( emailSubjectText.contains(ad.Name) || ca.RecordType.DeveloperName == 'Order_Approval_Escalations')  
                        { 
                            aD.Approval_Status__c = 'Rejected'; 
                            aD.Validation_Override__c = true; 
                            appDetSetUpdate.add(aD);  
                            if( ca.RecordType.DeveloperName == 'Order_Approval_Sales_Manager' ){
                                ca.Status = 'Closed-Approval Not Needed';
                                ca.Validation_Override__c = true; 
                                CaseTriggerClass_OA.skipCloseCaseEmailLogic = true;
                            }
                        } 
                    } 
                } 
                try 
                { 
                    update appDetSetUpdate; 
                    ca.Validation_Override__c = true;
                    update ca;  
                } 
                catch(Exception e)  
                { 
                    System.debug('EXCEPTION : ' + e);
                } 
            } 
            /* ORDER APPROVAL CHANGES END */
            
            emailBodyText = emailBodyText.length() > 32000 ? emailBodyText.substring(0, 32000) : emailBodyText;
            
            Boolean isExit = false;
            
            /*
            changes by Vandhana
            adding onlyBCC flag for ManagedSecurity, create Managed Security case when managedsecurity@akamai.com present in BCC and NO OTHER email-to-case email IDs is in To/CC list
            */
            Boolean onlyBCC = true;
            Boolean emailIdfound = false;
            for(String rType : emailRecordTypeMap.keySet()) 
            {
                for(String emailAdd : emailRecordTypeMap.get(rType)) 
                {
                    if(toAddressesSet.contains(emailAdd.toLowerCase()) || ccAddressesSet.contains(emailAdd.toLowerCase()))
                    {
                        emailIdfound = true; break;
                    }
                }
                if(emailIdfound)
                {
                    onlyBCC = false; break;
                }
            } 
            
            // changes by Vandhana for ESESP-2036 : Autoresponse to emails with Support email IDs in CC.
            
            List<String> techCCEmailIDLst = [SELECT Value_Text__c FROM SC_Utility__mdt 
                                             WHERE Active__c = TRUE 
                                             AND MasterLabel ='TechCC ReplyCustomer'].Value_Text__c.split(';');
            
            Boolean techOnlyInCC = true;Boolean techInCC = false;
            
            if(!CasefoundFlag)
            {
                for(String eachTechCCEmailId : techCCEmailIDLst)
                {
                    if(toAddressesSet.contains(eachTechCCEmailId))
                    {
                        techOnlyInCC = false;break;
                    }
                }
                if(techOnlyInCC)
                {
                    for(String eachTechCCEmailId : techCCEmailIDLst)
                    {
                        if(ccAddressesSet.contains(eachTechCCEmailId))
                        {
                            techInCC = true;break;
                        }
                    }
                    if(techInCC)
                    {
                        List<String> responseToAddress = new List<String>(); 
                        responseToAddress.add(email.fromAddress);
                        
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setSubject('WARNING: Akamai Support Case NOT Created');
                        String emailContent = 'Dear Customer,\n\n'
                            + 'Thank you for contacting Akamai Technical Support. It is very important that we let you know that your email has NOT been forwarded to the technical support team.' 
                            + ' To ensure you receive prompt support, you need to do one of the following:' 
                            + '\n\n1. Open a case via the Akamai Control Center, control.akamai.com'
                            + '\n\n2. Call support at 1-877-4AKATEC' 
                            + '\n\nThere is a third option of adding support@akamai.com/ ccare@akamai.com in the email TO: field, but we strongly recommend you use options #1 or #2 as emailed escalations have a 48-hour initial response SLA.'
                            + '\n\nRegards,\nAkamai Tech Support';
                        mail.setPlainTextBody(emailContent);
                        mail.setToAddresses(responseToAddress);
                        mail.setOrgWideEmailAddressId(SC_FromEmailAddress__c.getValues('Noreply').OrgAddressId__c);
                        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
                    }
                }
            }
      // end of changes by Vandhana

            if(!CasefoundFlag) 
            {
                for(String rType : emailRecordTypeMap.keySet()) 
                {
                    for(String emailAdd : emailRecordTypeMap.get(rType)) 
                    {
                        if(toAddressesSet.contains(emailAdd.toLowerCase())
                           || 
                           (emailAdd == EmailHandler_CS__c.getValues('ManagedSecurity').Email_Address__c && 
                            ( (ccAddressesSet.contains(emailAdd.toLowerCase() )) || 
                             //emailSubjectText.containsIgnoreCase(emailAdd.substringBefore('@')) 
                             (emailSubjectText.containsIgnoreCase('[' + emailAdd.substringBefore('@') + ']') && onlyBCC) 
                            )
                           )
                           ||
                           ( emailAdd == EmailHandler_CS__c.getValues('SecSales').Email_Address__c
                             && ccAddressesSet.contains(emailAdd.toLowerCase())
                           )
                           /* ESESP-2786 : Reverting changes when special email is in CC.
                           ||
                           (
                               emailAdd == EmailHandler_CS__c.getValues('specialist').Email_Address__c &&
                               ccAddressesSet.contains(emailAdd.toLowerCase())
                           )
                           */
                           // start of changes by Vandhana
                           
                           // commenting out code as part of CR 3662693
                           //  911prolexic and prolexic are no longer used as part of email-to-case functionality
                           
                           /*
                                    || 
                                    (
                                    emailAdd == EmailHandler_CS__c.getValues('911prolexic').Email_Address__c && 
                                    ( 
                                    (ccAddressesSet.contains(emailAdd.toLowerCase() )) || emailSubjectText.containsIgnoreCase(emailAdd.substringBefore('@')) 
                                    )
                                    )
                                    || 
                                    (
                                    emailAdd == EmailHandler_CS__c.getValues('prolexic').Email_Address__c && 
                                    ( 
                                    (ccAddressesSet.contains(emailAdd.toLowerCase() )) || emailSubjectText.containsIgnoreCase(emailAdd.substringBefore('@')) 
                                    )
                                    )
                */
                           
                           // end of changes by Vandhana
                          ) 
                        {
                            if(rType.equalsIgnoreCase('Technical')) 
                            {
                                System.debug('in Technical');
                                ca = createCase(email.subject, emailBodyText, toAddresses, email.fromAddress, rTypeMap.get('Technical'), con, 'Technical',noOfNonAkamContact,email);
                            } 
                            
                            else if(rType.equalsIgnoreCase('AMG')) 
                            {
                                System.debug('ENTERED AMG');
                                ca = createCase(email.subject, emailBodyText, toAddresses, email.fromAddress, rTypeMap.get('AMG'), con, 'AMG',noOfNonAkamContact,email);
                            } 
                            
                            else if(rType.equalsIgnoreCase('Billing')) 
                            {
                                ca = createCase(email.subject, emailBodyText, toAddresses, email.fromAddress, rTypeMap.get('Billing'), con, 'Billing',noOfNonAkamContact,email);
                            }
                            
                            else if(rType.equalsIgnoreCase('Emerging Products Engineering'))
                            {
                                System.debug('ENTERED EPE');
                                ca = createCase(email.subject, emailBodyText, toAddresses, email.fromAddress, rTypeMap.get('Emerging Products Engineering'), con, 'Emerging Products Engineering',noOfNonAkamContact,email);
                            }
                            
                            else if(rType.equalsIgnoreCase('Managed Security')) 
                                //&& (email.fromAddress == emailAddressForProlexic || emailAddressForProlexic == 'all@all.com'))
                            {
                                ca = createCase(email.subject, emailBodyText, toAddresses, email.fromAddress, rTypeMap.get('Managed Security'), con, 'Managed Security',noOfNonAkamContact,email);
                            }
                            
                            else if(rType.equalsIgnoreCase('Carrier Products'))
                            {
                                ca = createCase(email.subject, emailBodyText, toAddresses, email.fromAddress, rTypeMap.get('Carrier Products'), con, 'Carrier Products',noOfNonAkamContact,email);
                            }
                            
                            else if(rType.equalsIgnoreCase('Encoder Qualification'))
                            {
                                ca = createCase(email.subject, emailBodyText, toAddresses, email.fromAddress, rTypeMap.get('Encoder Qualification'), con, 'Encoder Qualification',noOfNonAkamContact,email);
                            }
                            else if(rType.equalsIgnoreCase('SecLaw'))
                            {
                                ca = createCase(email.subject, emailBodyText, toAddresses, email.fromAddress, rTypeMap.get('SecLaw'), con, 'SecLaw',noOfNonAkamContact,email);
                            }
                            else if(rType.equalsIgnoreCase('SecSales'))
                            {
                                ca = createCase(email.subject, emailBodyText, toAddresses, email.fromAddress, rTypeMap.get('SecSales'), con, 'SecSales',noOfNonAkamContact,email);
                            }
                            //ESESP-2362  CMG Team Case Management System from E-mails
                            else if(rType.equalsIgnoreCase('CMG'))
                            {
                                ca = createCase(email.subject, emailBodyText, toAddresses, email.fromAddress, rTypeMap.get('CMG'), con, 'CMG',noOfNonAkamContact,email);
                            }
                            //ESESP-2362  CMG Team Case Management System from E-mails
                            else if(rType.equalsIgnoreCase('Professional Services'))
                            {
                                ca = createCase(email.subject, emailBodyText, toAddresses, email.fromAddress, rTypeMap.get('Professional Services'), con, 'Professional Services',noOfNonAkamContact,email);
                            }
                            
                            isExit = true;
                            break;
                        }
                        
                        if(isExit) 
                        {
                            break;
                        }
                    }
                }
            } 
            
            if(ca != null) 
            {
                // Flag to set Attachment IsPrivate value. If do not show in Portal = False,then IsPrivate=true
                boolean isAttachmentPrivate = (ca.Do_Not_Show_in_Portal__c == False) ? True : False;

                if(email.fromaddress != null &&(!email.fromaddress.containsIgnoreCase('@akamai.com')))
                {
                    //move case from transition queue here.
                    if (ca.owner.name == 'ATS_Transition_Queue')
                    {
                        List<Case_transition__c> transitionList = [select id from case_transition__c where case__c = :ca.id and approved_date__c != null and completed__c = false order by createddate desc];
                        if(transitionList != null && transitionList.size() > 0)
                        {
                            for(Case_transition__c ct:transitionList)
                            {
                                ct.shift_tracker__c = false;
                            }
                            update transitionList;
                        }
                    }
                }  
                
                String cText;
                EmailMessage[] newEmail = new EmailMessage[0];
                newEmail.add(new EmailMessage(FromAddress = email.fromaddress,
                                              Incoming        = true,
                                              MessageDate = System.now(), 
                                              Status          = '1',   
                                              ParentId        = ca.Id));
                
                if(email.subject != null )
                {
                    newEmail[0].Subject = (emailSubjectText.length() < 255 ? emailSubjectText : emailSubjectText.substring(0,255));
                }
                if(email.fromname != null )
                {
                    newEmail[0].FromName = email.fromname;
                }
                if(email.plainTextBody!=null )
                {
                    newEmail[0].TextBody = (email.plainTextBody.length() < 32000 ? email.plainTextBody : email.plainTextBody.substring(0, 32000));
                }
                if(email.htmlbody != null )
                {
                    newEmail[0].HtmlBody = (email.htmlbody.length() < 32000 ? email.htmlbody : email.htmlbody.substring(0,32000));
                }
                
                //Handling for string too long exception - Akhila
                
                String strTempAddresses = '';
                if(toAddresses.length()>4000)
                {
                    strTempAddresses = toAddresses.substring(0,4000);
                    strTempAddresses = strTempAddresses.substring(0,strTempAddresses.lastIndexOf(';'));
                }    
                else
                    strTempAddresses = toAddresses;
                Set<String> sTempAddresses = new Set<String>(strTempAddresses.split(';'));
                Integer LengthOfEmail = 4000 - (sTempAddresses.size());  
                
                if(toAddresses.length() > LengthOfEmail)
                {
                    if(toAddresses.Substring(LengthOfEmail,LengthOfEmail+1) == ';')
                        newEmail[0].ToAddress = toAddresses.substring(0,LengthOfEmail);
                    else if(toAddresses.lastIndexOf(';') != -1)
                    {
                        newEmail[0].ToAddress = toAddresses.substring(0,LengthOfEmail);
                        newEmail[0].ToAddress = (newEmail[0].ToAddress).substring(0,(newEmail[0].ToAddress).lastIndexOf(';'));
                    }
                }
                else
                    newEmail[0].ToAddress = toAddresses;
                
                
                strTempAddresses = '';
                if(ccAddresses.length()>4000)
                {
                    strTempAddresses = ccAddresses.substring(0,4000);
                    strTempAddresses = strTempAddresses.substring(0,strTempAddresses.lastIndexOf(';'));
                }    
                else
                    strTempAddresses = ccAddresses;
                sTempAddresses.clear();
                sTempAddresses.addAll(strTempAddresses.split(';'));
                LengthOfEmail = 4000 - (sTempAddresses.size());
                if(ccAddresses.length() > LengthOfEmail)
                {
                    if(ccAddresses.Substring(LengthOfEmail,LengthOfEmail+1) == ';')
                        newEmail[0].CcAddress = CcAddresses.substring(0,LengthOfEmail);
                    else if(ccAddresses.lastIndexOf(';') != -1)
                    {
                        newEmail[0].CcAddress = CcAddresses.substring(0,LengthOfEmail);
                        newEmail[0].CcAddress = (newEmail[0].CcAddress).substring(0,(newEmail[0].CcAddress).lastIndexOf(';'));
                    }
                }
                else
                    newEmail[0].CcAddress = ccAddresses;
                
                if(email.headers != null && email.headers.size() > 0)
                {
                    cText = '';
                    for (Integer i = 0 ; i < email.headers.size() ; i++)
                    {
                        cText = cText + email.headers[i].name + ' = ' + email.headers[i].value;
                        //ESESP-5595 - Store SenderId header if present
                        if(email.headers[i].name.equals('SenderId'))
                        {
                            try
                            {
                              senderIdHeader = Id.valueOf(email.headers[i].value);
                            }
                            catch(StringException e)
                            {
                                System.debug('senderIdHeader contains invalid Id');
                            }
                        }
                    }
                    
                    // Truncating Header to 32000 char if it exceeds
                    newEmail[0].headers = (cText.length() > 32000) ? cText.substring(0,31995) : cText;
                }

                //ESESP-5595 : Create task only if email was not sent from mulesoft api with managedsecurity From Address
                if(senderIdHeader == null || newEmail[0].FromAddress != [SELECT Value_Text__c FROM SC_Utility__mdt
                                                                         WHERE DeveloperName = 'EmailMessage_ManagedSecurityEmailAddress'
                                                                         AND Active__c = true].Value_Text__c)
                {
                    Boolean isInternal = EmailToCaseUtility.isInternalActivity(email.fromAddress, toAddresses, ccAddresses);

                    // Added as part of MS Azure Visibility new field.
                    String setVisibility = '';
                    if(isInternal)
                    {
                        setVisibility = 'Internal Only';
                    }
                    else if(ca.IsMicrosoftAzureAccount__c && ca.Partner_Joint_Troubleshooting_Status__c == 'Open' && EmailToCaseUtility.isPartnerActivity(email.fromAddress, toAddresses, ccAddresses))
                    {
                        setVisibility = 'Partner Only';             
                    }
                    else
                    {
                        setVisibility = 'Customer';      
                    }
                    //ESESP-2362  - Only Internal cases are created through email for CMG
                    if(Case.SObjectType.getDescribe().getRecordTypeInfosById().get(ca.RecordTypeId).getName() == 'CMG') {
                        setVisibility = 'Internal Only';  
                    }

                    //To bypass RecentUpdate flag update, ca.Owner.Email will be null on Case creation and isCreatedByUser will be set to false
                    Boolean isCreatedByUser = (email.fromAddress==ca.Owner.Email?true:false);
                    
                    //Add Email Activity to the Case
                    //Visibility added as part of MS Azure
                    Task ta = EmailToCaseUtility.createTask(ca.Id, email.subject, emailBodyText, isInternal,isCreatedByUser,setVisibility);
                    if(ta != null)
                    {
                        newEmail[0].activityId = ta.Id;
                    }
                }
                
                insert newEmail;
                
                List<Attachment> attList = new List<Attachment>();
                //CR 3681272
                //To get recordtype name of current case
                String caRecordTypeName = Case.SObjectType.getDescribe().getRecordTypeInfosById().get(ca.RecordTypeId).getName();
                
                //if length of body is greater than 32000 , make it as an attachment.
                String bodyText = email.htmlbody != null ? email.htmlbody : '';
                if(bodyText.length() >= 32000 || (caRecordTypeName == 'Managed Security' && bodyText.length() >= 3000))
                {
                    Attachment att = createAttach(ca.Id, blob.valueOf(bodyText), 'Email contents.html',isAttachmentPrivate,'text/html');
                    attList.add(att);
                }
                
                // For Binary Attachments
                if (email.binaryAttachments != null && email.binaryAttachments.size() > 0) 
                {
                    for(Integer i = 0; i < email.binaryAttachments.size(); i++) 
                    {
                        if(email.binaryAttachments[i].filename == null || email.binaryAttachments[i].filename == '') {
                            email.binaryAttachments[i].filename = 'AttachMessage' + i + '.txt';
                        }
                        if(email.binaryAttachments[i].body == null || email.binaryAttachments[i].body == blob.valueOf('')) {
                            email.binaryAttachments[i].body = blob.valueOf('AttachBody' + i);
                        }

                        //ESESP-2476
                        String contentType = '';
                        for(Messaging.InboundEmail.Header eachHeader : email.binaryAttachments[i].headers){
                            if(eachHeader.Name == 'Content-Type'){
                                contentType = eachHeader.Value.substringBefore(';');
                                break;
                            }
                        }
                        
                        Attachment att = createAttach(newEmail[0].Id, email.binaryAttachments[i].body, email.binaryAttachments[i].filename,false,contentType);
                        attList.add(att);
                    }
                }
                
                // For Text Attachments
                if (email.textAttachments != null && email.textAttachments.size() > 0)
                {
                    for(Integer i = 0; i < email.textAttachments.size(); i++) 
                    {
                        if(email.textAttachments[i].filename == null || email.textAttachments[i].filename == '')
                        {
                            email.textAttachments[i].filename = 'AttachMessage' + i + '.txt';
                        }
                        if(email.textAttachments[i].body == null || email.textAttachments[i].body == '')
                        {
                            email.textAttachments[i].body = 'AttachBody' + i;
                        }
                        
                        Attachment att = createAttach(newEmail[0].Id, blob.valueOf(email.textAttachments[i].body), email.textAttachments[i].filename,false,'text/html');
                        attList.add(att);
                    }
                }
                
                if(attList.size() > 0) 
                {
                    insert attList;
                }

                //ESESP-5526 Added by Jay
                String sfdcCategory = 'x-sfdc-emailcategory';
                Boolean sentByAkamai = email.fromAddress.endsWithIgnoreCase('@akamai.com');
                Map<String,String> headers = new Map<String, String>();
                if(email.headers != null){
                    for (Messaging.InboundEmail.Header header : email.headers){
                        headers.put(header.name.toLowerCase(),header.value);
                    }
                }
                Boolean sentFromQuickAction = headers.containsKey(sfdcCategory) && headers.get(sfdcCategory).contains('quickActionEmail');
                if (sentByAkamai) {
                    if(!sentFromQuickAction) SC_CNSUtility.emailToCNSAsync(new List<Id>{newEmail[0].Id});
                }else{
                    SC_CNSUtility.emailToCNSAsync(new List<Id>{newEmail[0].Id});
                }
            }
        }
        return null;
    }
    
    //ESESP-2476
    public static Attachment createAttach(String parentid, blob attachbody, String filename, boolean isAttachmentPrivate, String contentType) {
        Attachment att = new Attachment();
        att.ParentId = parentid;
        //att.OwnerId = ownerid;
        att.Body = attachbody;
        //att.ContentType = 'text/html; charset=UTF-8';  
        if(filename.length() >= 80)
            att.Name = filename.substring(0,40)+'....'+filename.substring(filename.length()-30, filename.length());
        else
            att.Name = filename;
            
        //att.ContentType='ContentPost';
        //ESESP-2476
        att.ContentType = String.isBlank(contentType) ? 'ContentPost' : contentType;
        System.debug('---------- Attach ContentType ' + contentType);
        att.isPrivate = isAttachmentPrivate;
        return att;
    }
    
    private static Case createCase(String subjecttext, String bodytext, String toAddresses,
                                   String fromemail, Id rtId, Contact con, String rtName, integer noOfNonAkamContact,
                                   Messaging.InboundEmail email) 
    {
        String searchKey = 'Account ID:';
        String routingOpt = '';
        
        Case ca = new Case();
        // CR - 3210681 & 3159401, To avoid any validation error at the time of Case creation. Added in 16.1 Release By Deepak Saxena
        ca.Validation_Override__c = True;
        //ESESP-5981
        ca.Origin_Email__c = (toAddresses.length() > 254) ? toAddresses.substring(0, 254) :  toAddresses;
        
        String accountAkamId = EmailToCaseUtility.findString(subjecttext, searchKey);
        if(accountAkamId == null) 
        {
            if(rtName == 'AMG' || rtName == 'Technical')
            {
                if(bodytext.containsIgnoreCase('Account ID:'))
                    accountAkamId = EmailToCaseUtility.findStringAMG(bodytext, 'Account ID:');
                else if(bodytext.containsIgnoreCase('Account ID :'))
                    accountAkamId = EmailToCaseUtility.findStringAMG(bodytext, 'Account ID :');
            }
            else
                accountAkamId = EmailToCaseUtility.findString(bodytext, searchKey);
        }
        Id accountId;
        System.debug('###Akam account id: ' + accountAkamId);
        if(accountAkamId != null) 
        {
            accountAkamId = accountAkamId.replace('?','');
            for(Account acc : [Select Id from Account Where AKAM_Account_ID__c = :accountAkamId]) 
            {
                accountId = acc.Id; 
            }
            if(accountId != null) 
            {
                ca.AccountId = accountId;
                System.debug('####Account Id: ' + accountId);
            }
        }
        
        // Validation for Email Subject : If subject is exceeding 255 Character then trim it to 255 Character
        subjecttext = (subjecttext <> null && subjecttext.length() > 255) ? subjecttext.substring(0,251) + '...' : subjecttext;
        
        ca.Subject = subjecttext;
        //CR 3681272
        ca.Description = (rtName == 'Managed Security' && bodytext.length() > 3000) ? bodytext.subString(0,3000) : bodytext;
        ca.Email_to_case__c = true;
        ca.Origin = 'Email';
        ca.RecordTypeId = rtId;
        ca.Do_Not_Show_in_Portal__c = true;
        
        // lastly changing RT of Carrier to Technical RT and Carrier Sub Type
        if (rtName.equals('Carrier Products')) 
        {
            ca.RecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
            rtName = 'Technical';
            ca.Sub_Type__c = 'Carrier';
        }
        
        // Setting Do_Not_Show_in_Portal__c = False for below conditions
        if(noOfNonAkamContact == 1 && (rtName == 'Emerging Products Engineering' || rtName == 'AMG' || rtName == 'Billing' || rtName == 'Technical' // || rtName == 'Carrier Products'
                                      ) )
        {
            ca.Do_Not_Show_in_Portal__c = false;
        }
        
        if(rtName == 'SecLaw')
        {
            ca.Do_Not_Show_In_Portal_Picklist__c  = 'Internal Only';
        }
        
        // ESESP-1402 Setting Service Category for AMP
        if(rtName == 'Technical')
        {
            if((toAddresses.containsIgnoreCase(EmailHandler_CS__c.getValues('AMP').Email_Address__c)))
            {
                ca.Sub_Type__c = 'Product Support';
                ca.Service_Category__c = 'Media-AMP';
            }
        }
        //End of change ESESP-1402   
        
        if(con != null)
        {
            //By Himanshu Release 3.40 . Added condition for Contact Validation
            ca.ContactId = (ca.AccountId <> null && con.AccountId <> ca.AccountId) ? Null : con.Id;
            ca.AccountId = ca.AccountId == null ? con.AccountId : ca.AccountId;
        }
        
        // changes by Vandhana for ESESP-689
        if(rtName.equals('AMG') && fromemail.containsIgnoreCase('@akamai.com'))
        {
            String contactEmail = '';
            Contact contactAMG = new Contact();
            List<Contact> conList = new List<Contact>();
            if(bodytext.containsIgnoreCase('[Contact:'))
                contactEmail = EmailToCaseUtility.getCaseNumber(bodytext,'[Contact:',']');
            else if(bodytext.containsIgnoreCase('[Contact :'))
                contactEmail = EmailToCaseUtility.getCaseNumber(bodytext,'[Contact :',']');
            
            if(contactEmail.containsIgnoreCase('<') || contactEmail.containsIgnoreCase('mailto'))
                contactEmail = contactEmail.substringBefore('<');
            System.debug('contactEmail : ' + contactEmail);
            
            if(String.isNotBlank(contactEmail))
            {
                contactEmail = contactEmail.replace('?','');
                conList = [SELECT Id,AccountId FROM Contact WHERE email = :contactEmail and Login__c != NULL limit 1];
                if(!conList.isEmpty())
                {
                    contactAMG = conList[0];
                }
                System.debug(contactAMG);
                if(contactAMG.Id != NULL){
                    ca.ContactId = (accountId <> NULL && contactAMG.AccountId <> accountId) ? NULL : contactAMG.Id;
                    ca.AccountId = accountId == null ? contactAMG.AccountId : accountId;
                }
            }
        }
        
        
        // changes by Vandhana - S2ET
        // ESESP-5678 : Adding 24 PS Email to case creation
        Boolean isS2ETCase = FALSE;
        if(rtName == 'Professional Services' && (toAddresses.containsIgnoreCase(EmailHandler_CS__c.getValues('s2et').Email_Address__c) || toAddresses.containsIgnoreCase(EmailHandler_CS__c.getValues('24ps').Email_Address__c) ) ) 
        {
            Id s2etQId = [SELECT Value_Text__c FROM SC_Utility__mdt WHERE DeveloperName = 'S2ET_Queue_Id' LIMIT 1].Value_Text__c;
            Id PS24QId = [SELECT Value_Text__c FROM SC_Utility__mdt WHERE DeveloperName = 'PS24_Queue_Id' LIMIT 1].Value_Text__c;
            //ca.OwnerId = toAddresses.containsIgnoreCase(EmailHandler_CS__c.getValues('s2et').Email_Address__c) ? s2etQId : PS24QId;
            //ESESP-5981 : Assigning all cases to 24PS Queue
            ca.OwnerId =  PS24QId;
            isS2ETCase = TRUE;
            ca.Do_Not_Show_in_Portal__c = toAddresses.containsIgnoreCase(EmailHandler_CS__c.getValues('24ps').Email_Address__c) ? false :  ca.Do_Not_Show_in_Portal__c;
            ca.Severity__c = '3';
        }
        
        //Detect CMP Alerts and set CMP Alerts Sub Type 
        string emailAddressForCMP = SC_FromEmailAddress__c.getValues('CMPFromEmailAddress').FromAddress__c.trim();
        string emailAddressForPortalWM = SC_FromEmailAddress__c.getValues('PortalWMFromEmailAddress').FromAddress__c.trim();
        
        system.debug('FROM EMAIL ADDRESS : '+emailAddressForPortalWM);
        
        If(rtName.equals('Technical') && fromEmail.equalsIgnoreCase(emailAddressForCMP)
           && (EmailToCaseUtility.findString(bodytext,'CATEGORY:     ')=='CMP'))
        {
            ca.Severity__c = EmailToCaseUtility.findString(bodytext,'Case Severity:') == null ? '3' : EmailToCaseUtility.findString(bodytext,'Case Severity:');
            ca.Origin = 'Akamai';
            ca.Sub_Type__c = 'CMP Alerts';
            ca.Work_Type__c = 'Proactive';
        }
        else if(rtName.equals('Technical') && fromEmail.equalsIgnoreCase(emailAddressForPortalWM) && subjecttext.equalsIgnoreCase('[portal-feedback] PORTAL FEEDBACK FORM FROM CUSTOMER')) 
        {
            if(ca.AccountId != null) 
            {
                //ca.Case_Product__c = getCaseProduct('Luna Control Center', ca.AccountId);
                if(getCaseProduct('Luna Control Center', ca.AccountId) != null)
                  ca.Case_Product__c = getCaseProduct('Luna Control Center', ca.AccountId);
                else if(getCaseProduct('Control Center', ca.AccountId) != null)
                  ca.Case_Product__c = getCaseProduct('Control Center', ca.AccountId);
            } 
            ca.Severity__c = '3';
        } 
        
        else if(rtName.equals('Technical') && fromEmail.equalsIgnoreCase('webforms@akamai.com')
                && subjecttext.equalsIgnoreCase('[client-endusersupport] Download Manager Feedback')) 
        {
            if(ca.AccountId != null) 
            {
                ca.Case_Product__c = getCaseProduct('HTTP Downloads', ca.AccountId);
            } 
            ca.Module__c = 'NetSession';
            ca.Severity__c = '3';
        } 
        
        // start of changes by Vandhana for ESESP-689::AMG Case Mgmt Improvement
        if(rtName.equals('AMG')) 
        {
            String cpReqEmail = '';
            if(subjecttext.indexOfIgnoreCase('[ROUTE') != -1)
                routingOpt = EmailToCaseUtility.getCaseNumber(subjecttext,'[ROUTE',']');
            User u = NULL;
            if(String.isNotBlank(routingOpt) && (routingOpt.containsIgnoreCase('OFF') || routingOpt.containsIgnoreCase('NO')))
            {
                u = [SELECT Id FROM User WHERE Email = :email.fromAddress AND isActive = TRUE limit 1];
                ca.OwnerId = u.Id;
                ca.Case_Assignment_Using_Active_Rules__c = false;
            }
                
            List<SC_Utility__mdt> amgUtil = [SELECT Value_Text__c,DeveloperName 
                                             FROM SC_Utility__mdt
                                             WHERE DeveloperName in ('AMG_amsalert','AMG_manualinvoicereview','AMG_smane')];
            
            Map<String,String> amgUtilMap = new Map<String,String>();
            for(SC_Utility__mdt eachUtilRec : amgUtil)
                amgUtilMap.put(eachUtilRec.DeveloperName,eachUtilRec.Value_Text__c);
            
            if(fromEmail.equalsIgnoreCase(amgUtilMap.get('AMG_manualinvoicereview')))
            {
                System.debug('AMG_manualinvoicereview');
                ca.Post_processing_origin__c = 'Autogen'; 
                if(subjecttext.containsIgnoreCase('[specialist] MANUAL IR:') || subjecttext.containsIgnoreCase('MANUAL IR:'))
                {
                    ca.Service__c = 'Billing Related';
                    ca.Request_Type__c = 'Manual Invoice Review';
                }
            }
            else if(fromEmail.equalsIgnoreCase(amgUtilMap.get('AMG_smane')))
            {
                System.debug('AMG_smane');
                ca.Post_processing_origin__c = 'Autogen';
                if(subjecttext.containsIgnoreCase('[specialist] Action Required: SiteShield Map') || subjecttext.containsIgnoreCase('Action Required: SiteShield Map') || subjecttext.containsIgnoreCase('[specialist] Critical Action Required: SiteShield Map') || subjecttext.containsIgnoreCase('Critical Action Required: SiteShield Map'))
                {
                    ca.Service__c = 'Escalation Management';
                    ca.Request_Type__c = 'SiteShield Map Degradation';
                }
            }
            else if(fromEmail.equalsIgnoreCase(amgUtilMap.get('AMG_amsalert')))
            {
                ca.Post_processing_origin__c = 'Autogen';
                if(subjecttext.containsIgnoreCase('Origin Cert Expiring'))
                {
                    ca.Service__c = 'SSL/TLS Certificate Management';
                    ca.Request_Type__c = 'Origin Certificate';
                }
            }    
            else
            if(!fromEmail.containsIgnoreCase('@akamai.com'))
               ca.Post_processing_origin__c = 'Customer';
        }
        
        else if (rtName.equals('Billing'))
        {
            ca.Severity__c = '3';
        } 
        
        else if (rtName.equals('Managed Security')) 
        {
            // changes by Vandhana for CR 3628251 - severity of Managed Security case should be 3
            //ca.Severity__c = '2';
            ca.Severity__c = '3';
            
            ca.Do_Not_Show_in_Portal__c = false;
            
            if(con == null)
            {
                ca.AlternateContactEmailManagedSecurity__c = fromemail;
                ca.Alternate_Contact_Email__c  = fromemail;
            }
        }                                                                
        
        // start of changes by Vandhana for ESESP-852 Nominum Service Cloud Migration
        // changes by Vandhana for ESESP-2346 : Carrier to Tech migration
        else if (rtName.equals('Technical') && ca.Sub_Type__c == 'Carrier') 
        {
            ca.Severity__c = '3';
            
            // metadata that stores possible values in Inbound Email Subject for which a Sev1/sev2 case should be created
            List<SC_Utility__mdt> subjValue = [SELECT MasterLabel,Value_Text__c  
                                         FROM SC_Utility__mdt 
                                               WHERE MasterLabel IN ('Nominum Email2Case Sev1 subject values','Nominum Email2Case Sev2 subject values')];
            Map<String,String> mapSevSubj = new Map<String,String>();
            
            for(SC_Utility__mdt subjVal : subjValue)
            {
                mapSevSubj.put(subjVal.MasterLabel, subjVal.Value_Text__c);
            }
            
            List<String> sev1text = mapSevSubj.get('Nominum Email2Case Sev1 subject values').split(',');
            String sev2text = mapSevSubj.get('Nominum Email2Case Sev2 subject values');
            
            Map<String,String> mapTextSev = new Map<String,String>();
            for(String eachSev : sev1text)
            {
                mapTextSev.put(eachSev,'1');
            }
            mapTextSev.put(sev2text,'2');
            
            for(String eachSubjVal : mapTextSev.keyset())
            {
                if(subjecttext.containsIgnoreCase(eachSubjVal))
                {
                    ca.Severity__c = mapTextSev.get(eachSubjVal);
                    break;
                }
            }
            
            /*
            String sev1text = mapSevSubj.get('Nominum Email2Case Sev1 subject values');
            String sev2text = mapSevSubj.get('Nominum Email2Case Sev2 subject values');
            
            // regex to match subject values for sev1
            Pattern sevMatch = Pattern.compile('(^(?i)('+ sev1text +')$)'+
                                           '|(^(?i)('+ sev1text +')[\\p{Blank}\\p{Punct}]+)'+
                                           '|([\\p{Blank}\\p{Punct}]+(?i)('+ sev1text +')[\\p{Blank}\\p{Punct}]+)'+
                                           '|([\\p{Blank}\\p{Punct}]+(?i)('+ sev1text +')$)');
            
            Matcher matcherVal = sevMatch.matcher(subjecttext);
            
            if(matcherVal.find())  
            {
                ca.Severity__c = '1';
            }
            else
            {
                sevMatch = Pattern.compile('(^(?i)('+ sev2text +')$)'+
                                           '|(^(?i)('+ sev2text +')[\\p{Blank}\\p{Punct}]+)'+
                                           '|([\\p{Blank}\\p{Punct}]+(?i)('+ sev2text +')[\\p{Blank}\\p{Punct}]+)'+
                                           '|([\\p{Blank}\\p{Punct}]+(?i)('+ sev2text +')$)');
                
                matcherVal = sevMatch.matcher(subjecttext);
                
                if(matcherVal.find())  
                { ca.Severity__c = '2'; }
            }
      */
            
            if(toAddresses.containsIgnoreCase(EmailHandler_CS__c.getValues('Nominum').Email_Address__c))
                ca.Legacy_Type__c = 'Nominum';
        } 
        else if (rtName.equals('Encoder Qualification')) 
        {
            ca.Severity__c = '3';
            ca.Do_Not_Show_in_Portal__c = true;
            ca.Service__c = 'Encoder Qualification';
            ca.Request_type__c = 'Qualification';
            ca.Origin = 'Email';
            if(con == null)
                ca.Alternate_Contact_Email__c = fromemail;
        } 
        //ESESP-2362  Set CMG case fields
        else if (rtName.equals('CMG')) 
        {
            Group cmgQueue = [SELECT Id, Name, type FROM Group where type = 'Queue' and name = 'CMG Queue'];
            ca.Severity__c = '3';
            ca.Do_Not_Show_in_Portal__c = true;
            ca.Origin = 'Email';
            ca.OwnerId = cmgQueue.Id;
            if(con == null)
                ca.Alternate_Contact_Email__c = fromemail;
        }
        
        if (rtName.equals('Technical') && fromEmail.equalsIgnoreCase('alerts@exceda.com'))
        {
            System.debug('In condition');
            ca.Do_Not_Show_in_Portal__c = true;
            ca.Sub_Type__c = 'Exceda Monitoring';
            ca.Work_Type__c = 'Proactive';
        }
        
        //ESESP-598 SOASTA onboarding
        if(rtName.equals('Technical') && toAddresses.containsIgnoreCase(EmailHandler_CS__c.getValues('soasta').Email_Address__c))
            ca.Legacy_type__c = 'SOASTA';
        
        Database.DMLOptions dmo = new Database.DMLOptions();
        if(rtName.equals('AMG') && (routingOpt.equalsIgnoreCase('NO') || routingOpt.equalsIgnoreCase('OFF'))
          || isS2ETCase
          )
            dmo.assignmentRuleHeader.useDefaultRule = false;
        else
            dmo.assignmentRuleHeader.useDefaultRule = true;
        dmo.EmailHeader.triggerUserEmail = true;
        ca.setOptions(dmo); 
        
        insert ca;
        //Changes for JARVIS
        try
        {
            if(SC_Jarvis_CoreSecurityController.caseRecordTypesJarvis.contains(rtName) && !ca.Do_Not_Show_in_Portal__c 
            &&ca.ContactId != null)
            {
                SC_Jarvis_User_Permission_Queue permissionQueue = new SC_Jarvis_User_Permission_Queue();
                permissionQueue.contactIds = new List<String>{ca.ContactId};
                system.enqueueJob(permissionQueue);
            }
    
        }
        catch(Exception e)
        {

        }
        
        
        // changes by Vandhana for ESESP-852 Nominum
        // added custom email acknowledgement for case creation for Carrier Product cases
        try
        {
            if(rtName.equals('Technical') || rtName.equals('Encoder Qualification') || rtName.equals('CMG') //|| rtName.equals('Carrier Products')
              )
            {
                sendEmailToCustomer(email,ca);
            }
            //ESESP-2587: SecSales Enhancements
            if(rtName.equals('SecSales')) 
            {
                Case reFetchedCase = [select id, AKAM_Case_ID__c, Contact.FirstName, Subject from case where id = :ca.Id];
                String ContactFirstName = reFetchedCase.ContactId != null ? reFetchedCase.Contact.FirstName : email.fromName;
                
                Map<String, String> fieldsToReplace = new Map<String, String>{
                    '{!Case.AKAM_Case_ID__c}' => reFetchedCase.AKAM_Case_ID__c,
                        '{!Case.Subject}' => reFetchedCase.Subject,
                        '{!Case.Link}'=> System.Url.getSalesforceBaseURL().toExternalForm() + '/' + reFetchedCase.Id,
                        '{!Case.Contact}' => ContactFirstName};
                            System.debug('fieldsToReplace --> ' + fieldsToReplace);
                sendTemplateEmail('SecSales_Acknowledgement', fieldsToReplace, email, reFetchedCase);
            }
        } 
        catch(Exception e)
        {
            string errorMessage =   'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
                'Class Name = EmailToCaseHandler\n' + 
                'Method Name = sendEmailToCustomer\n';
            
            errorMessage += e.getCause()+'..'+e.getLineNumber()+'..'+e.getMessage()+'..'+e.getTypeName()+'..'+e.getStackTraceString();
            SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support(); 
            sc_COBSupportCls.senEmailForError('Exception in Email Service', errorMessage);
        }
        
        return ca;
    }
    
    // ESESP-2587: SecSales Enhancements, Send Email with Custom Template
    public static void sendTemplateEmail(String templtName, Map<String, String> fieldsToReplace,
                                         Messaging.InboundEmail email, Case ca ) 
    {
        EmailTemplate et = [SELECT Id,Subject, Body, HtmlValue FROM EmailTemplate WHERE DeveloperName = :templtName];
        List<string> toAddress = new List<string>();
        List<string> ccAddress = new List<string>();
        toAddress.add(email.fromAddress);
        if(email.ccAddresses != null) {
          ccAddress.addAll(email.ccAddresses);                 
        }
        if(email.toAddresses != null) {
          ccAddress.addAll(email.toAddresses);
        }
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setTemplateId(et.Id);
        mail.setToAddresses(toAddress);
        
        String subject = et.subject;
        String htmlBody = et.HtmlValue;
        for(String fld: fieldsToReplace.keySet()) {
            subject = subject.replace(fld, fieldsToReplace.get(fld));
            htmlBody = htmlBody.replace(fld, fieldsToReplace.get(fld));
        }
        
        htmlBody = htmlBody + '<hr/>'
            + '<b> From: </b> ' + email.fromAddress + '<br/>'
            + '<b> Date: </b> ' + System.now() + '<br/>'
            + '<b> To: </b> ' + String.join(email.toAddresses, '; ') + '<br/>';

        if(email.ccAddresses != null) {
            htmlBody = htmlBody + '<b> Cc: </b> ' + String.join(email.ccAddresses, '; ') + '<br/>';
        }
        htmlBody = htmlBody +   email.htmlBody + '<br/> <br/>';
        mail.setCcAddresses(ccAddress);                              
        mail.setSubject(subject);
        mail.setHTMLBody(htmlBody);
        mail.setWhatId(ca.Id);
        mail.setSaveAsActivity(false);
        mail.setUseSignature(false);
        List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
        allmsg.add(mail);
        
        Messaging.sendEmail(allmsg,false);
    }
    
    private static void handleSurveyEmails(Set<String> toAddressesSet, Messaging.InboundEmail email, String emailBodyText, 
                                           Map<String, Id>  rTypeMap, List<String> surveyEmails) 
    {
        for(String sEmail : surveyEmails) {
            if(toAddressesSet.contains(sEmail.toLowerCase())) 
            {
                if(email.fromAddress.equalsIgnoreCase('ccare_team@feedback.akamai.com')) 
                {
                    createSurveyCase(email.subject, emailBodyText, rTypeMap.get('GSS CSAT'), 'Transactional CCare Survey', 'Case Closure Disagreement', '1', false, false);
                } else if (email.fromAddress.equalsIgnoreCase('ccare_dsat@feedback.akamai.com')) 
                {
                    createSurveyCase(email.subject, emailBodyText, rTypeMap.get('GSS CSAT'), 'Transactional CCare Survey', null, '3', true, false);
                } else if(email.fromAddress.equalsIgnoreCase('service_desk@feedback.akamai.com')) 
                {
                    createSurveyCase(email.subject, emailBodyText, rTypeMap.get('GSS CSAT'), 'Service Desk Survey', null, '3', false, true);        
                } else if(email.fromAddress.equalsIgnoreCase('akamai_billing@feedback.akamai.com')) 
                {
                    createSurveyCase(email.subject, emailBodyText, rTypeMap.get('GSS CSAT'), 'Transactional Survey Billing', null, '3', false, false);        
                }
            }
        }
        
    }
    
    private static Case createSurveyCase(String subjecttext, String bodytext, Id rtId, 
                                         String service, String problem, String severity, Boolean toBeParsed, Boolean isRoutingApplied) 
    {
        
        Map<String, Id> queueMap = new Map<String, Id>();
        for(Group g : [Select Id, Name from Group Where Name IN('AMG APJ Management Queue', 'AMG EMEA Management Queue', 'AMG NA Management Queue', 'Billing CSAT Queue') And Type = 'Queue']) {
            queueMap.put(g.Name, g.Id);
        }
        
        bodytext = bodytext.length() > 32000 ? bodytext.substring(0, 32000) : bodytext;
        Case ca = new Case();
        ca.Subject = subjecttext;
        ca.Description = bodytext;
        ca.Email_to_case__c = true;
        ca.Origin = 'Email';
        ca.RecordTypeId = rtId;
        ca.Service__c = service;
        ca.Severity__c = severity;
        
        //Search for Account Id in Transactional CCare Surveys
        String acctSearchKey = 'Account ID:';
        String accountAkamId = EmailToCaseUtility.findString(bodytext, acctSearchKey);
        
        Account acct;
        if(accountAkamId != null) 
        {
            for(Account acc : [Select Id, Geography_Formula__c from Account Where AKAM_Account_ID__c =: accountAkamId]) 
            {
                acct = acc; 
            }
            if(acct != null) 
            {
                ca.AccountId = acct.Id;
            }
        }
        
        //Code to parse and assign owner to case
        if(toBeParsed) 
        {
            User usr;
            String searchKey = 'Manager:';
            String managerAlias = EmailToCaseUtility.findString(bodytext, searchKey);
            
            if(managerAlias != null) {
                for(User u : [Select Id from User Where Alias =: managerAlias]) {
                    usr = u;
                }
                if(usr != null) {
                    ca.OwnerId = usr.Id;
                    try {
                        insert ca;
                    } catch (Exception e) {
                        ca.OwnerId = null;
                        toBeParsed = false;
                    }
                } else {
                    toBeParsed = false;
                }
            } else {
                toBeParsed = false;
            }
        }
        
        if(isRoutingApplied && acct != null) 
        {
            /*
            if(acct.Geography_Formula__c != null) 
            {
            if(acct.Geography_Formula__c.containsIgnoreCase('APJ')) {
            ca.OwnerId = queueMap.get('AMG APJ Management Queue');
            } else if(acct.Geography_Formula__c.containsIgnoreCase('EMEA')) {
            ca.OwnerId = queueMap.get('AMG EMEA Management Queue');
            } else {
            ca.OwnerId = queueMap.get('AMG NA Management Queue');
            }
            } 
            else {
            ca.OwnerId = queueMap.get('AMG NA Management Queue');
            }
      */
            toBeParsed = true;                  //set toBeParsed = true, so it doesn't fall in assignment rules.
        }
        
        if(!toBeParsed) 
        {
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.assignmentRuleHeader.useDefaultRule = true;
            ca.setOptions(dmo);
        }
        
        if(ca.Id == null) 
        {
            insert ca;
        }
        return ca;
    }  
    
    public static Id getCaseProduct(String cpName, Id actId) 
    {
        Id cpId = null;
        for(EB_AccountProductMap__c c : [Select Id from EB_AccountProductMap__c Where Name =: cpName AND EB_Account__c =: actId AND EB_MarkedForDeletion__c = false]) {
            cpId = c.Id;
        }
        return cpId;
    }
    
    // changes by Vandhana for ESESP-852 Nominum Service Cloud Migration
    // added logic for case creation acknowledgement for Carrier Product Cases to case contact AND all CCd on incoming email
    public static void sendEmailToCustomer(Messaging.InboundEmail email, Case incomingCase)
    {
        // Get Case Details
        Case newCase = [Select Id,AKAM_Case_ID__c,subject,Contact.Name,Severity__c,Description,RecordType.name,Sub_Type__c, Apply_Jarvis_Logic__c 
                        from case where Id= :incomingCase.Id limit 1];
        
        if(newCase.Apply_Jarvis_Logic__c == False){
            // List to store all To Add
            Set<String> toAddressesSet = new Set<String>(); 
            toAddressesSet.add(email.fromAddress); // Adding From Add to ToAdd
            toAddressesSet.addAll(email.toAddresses);
            
            // List to store all CC Add
            Set<String> ccAddressesSet = new Set<String>();
            if(email.ccAddresses != null)
                ccAddressesSet.addAll(email.ccAddresses);
            
            // Variable to store ACK Email Subject
            String emailSubject = 'Akamai Support Case Received [AKAM-CASE #' + newCase.AKAM_Case_ID__c + '] - '+ newCase.subject;
            
            // Variable to store ACK Email Body
            string emailBody;
            if(newCase.RecordType.name == 'Encoder Qualification')
            {
                emailBody = 'Thank you for contacting the Akamai Encoder Qualification Team.'+
                    ' We have received your request and will get back to you shortly. \n\n'+
                    'Akamai Case #: '+ newCase.AKAM_Case_ID__c +
                    '\n\nPlease include [AKAM-CASE #' + newCase.AKAM_Case_ID__c + '] in the Subject' + 
                    ' line when inquiring about this case via email.'+
                    '\n\nThank you,\n'+ 'Akamai Encoder Qualification Team';
            }
            // start of changes by Vandhana for Nominum ESESP-852
            else
                if(newCase.RecordType.Name == 'Technical' && newCase.Sub_Type__c == 'Carrier')
            {
                emailBody = 'Dear ' + (newCase.Contact.Name != null ? newCase.Contact.Name : 'Customer') + ',\n\n' + 
                    'Your request for assistance from Akamai Support has been received and is being reviewed. ' + 
                    'An Akamai representative will contact you shortly if more information is needed.\n\n' +
                    'You may track the progress of this case online in Control Center by following this link: ' +
                    'https://control.akamai.com/apps/case-management/#/cases/' + newCase.AKAM_Case_ID__c + '/view.\n\n' + 
                    'Your Case ID is ' + newCase.AKAM_Case_ID__c + '. ' + 
                    'Please include [AKAM-CASE #' + newCase.AKAM_Case_ID__c + '] in the Subject line when inquiring about this case via email.\n\n' +
                    'Thank you,\nAkamai Support \n -------------------\n' + 
                    'Case Severity: ' + newCase.Severity__c + '\nCase Description: ' + newCase.Description;
                
                // modify Email Subject/Body for Severity 1/2 cases
                if(newCase.Severity__c == '1' || newCase.Severity__c == '2')
                {
                    emailSubject = emailSubject.replace('Akamai Support Case Received [AKAM', 'Akamai Support Critical Case Received [AKAM');
                    emailBody = emailBody.replace('Your request for assistance from Akamai Support has been','Your Severity ' + newCase.Severity__c + ' request for assistance from Akamai Support has been');
                    emailBody = emailBody.replace('You may track the progress of this case online in Control Center',
                                                  'Please ensure you have provided us with a telephone number where you can be reached. You may track the progress of this case online in Control Center');
                }
            }
            else if(newCase.RecordType.Name == 'CMG') {
                //ESESP-4714: CMG case creation acknowledgement
                emailSubject = emailSubject.replace('Akamai Support Case Received [AKAM', 'CMG Case Received [AKAM');
                String recipientName = newCase.Contact.Name != null ? newCase.Contact.Name : (
                    email.fromName.contains(', ') ? (email.fromName.substringAfter(', ') + ' ' + email.fromName.substringBefore(', ')) : email.fromName
                    );
                emailBody = '<div style="font-family: Verdana, sans-serif;font-size: 10pt;">' +
                    'Dear ' + recipientName + ',<br/><br/>' +
                    'Thank you for reaching out to Contract Management Group. ' +
                    'We have received your e-mail inquiry and one of our CMG Specialists will respond to you within the next 24 hours.<br/><br/>' +
                    'Your Case ID is ' + newCase.AKAM_Case_ID__c + ' and it was opened with Severity ' + newCase.Severity__c + '. ' +
                    'Please include [AKAM-CASE #' + newCase.AKAM_Case_ID__c + '] in the Subject line when inquiring about this case via email.<br/><br/>' +
                    'Thank you,<br/>Contract Management Group<br/><br/><hr/>' +
                    '<b>From:</b> ' + email.fromAddress + '<br/>' +
                    '<b>Date:</b> ' + Datetime.now().formatGmt('EEEE, MMMM d, yyyy \'at\' hh:mm a z') + '<br/>' +
                    (email.toAddresses != null ? ('<b>To:</b> ' + String.join(email.toAddresses, ', ') + '<br/>') : '') +
                    (email.ccAddresses != null ? ('<b>Cc:</b> ' + String.join(email.ccAddresses, ', ') + '<br/>') : '') +
                    '<b>Subject:</b> ' + email.subject + '</div><br/>' +
                    email.htmlBody;
            }
            else
            {
                emailBody = 'Dear ' + (newCase.Contact.Name != null ? newCase.Contact.Name : 'Customer') + ',\n\n' + 
                    'Your request for assistance from Akamai Support has been received and is being reviewed. ' + 
                    'An Akamai representative will contact you shortly if more information is needed.\n\n' +
                    'If you have access to Control Center, you may track the progress of this case online by following this link: ' +
                    'https://control.akamai.com/apps/case-management/#/cases/' + newCase.AKAM_Case_ID__c + '/view.\n\n' + 
                    'Your Case ID is ' + newCase.AKAM_Case_ID__c + ' and it was opened with Severity ' + newCase.Severity__c + '. ' + 
                    'If this does not match the impact or urgency of your request, please call Support at 1-877-4-AKATEC to modify' + 
                    ' the Severity level.  Also, please include [AKAM-CASE #' + newCase.AKAM_Case_ID__c + '] in the Subject' + 
                    ' line when inquiring about this case via email.\n\n' +
                    'Thank you,\nAkamai Support \n -------------------\n' + 
                    'Case Severity: ' + newCase.Severity__c + '\nCase Description: ' + newCase.Description;
            }
            Boolean result = false;
            
            // Loop for All all the Akamai Mailing Address to remove those from ToAdd or CCAdd
            for(EmailHandler_CS__c eCS : EmailHandler_CS__c.getAll().values())
            {    
                result = toAddressesSet.remove(eCS.Email_Address__c);
                result = ccAddressesSet.remove(eCS.Email_Address__c);
            }
            
            List<string> finalToAdd = new List<string>();
            finalToAdd.addAll(toAddressesSet);
            if(finalToAdd.size()>100)
            {
                for(Integer index=100; finalToAdd.size()>100; )
                    finalToAdd.remove(index);
            }
            
            List<string> finalCCAdd = new List<string>();
            finalCCAdd.addAll(ccAddressesSet);
            if(finalCCAdd.size()>25)
            {
                for(Integer index=25; finalCCAdd.size()>25; )
                    finalCCAdd.remove(index);
            }
            
            //To avoid Missing target address Exception
            if(finalToAdd.size() > 0 || finalCCAdd.size() > 0)
            { 
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setToAddresses(finalToAdd);
                mail.setCcAddresses(finalCCAdd);
                mail.subject = emailSubject;
                if(newCase.RecordType.Name == 'CMG') {
                    mail.setReferences(email.messageId);
                    mail.setInReplyTo(email.messageId);
                    mail.setHtmlBody(emailBody);
                    mail.setOrgWideEmailAddressId(SC_FromEmailAddress__c.getValues('CMG').OrgAddressId__c);
                }
                else {
                    mail.plainTextBody = emailBody;
                    mail.setOrgWideEmailAddressId(SC_FromEmailAddress__c.getValues('auto-reply').OrgAddressId__c);
                }
                Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail}); 
            }  
        }
    }
    
    //ESESP-1542: Send email to Case Owner
    public static void sendEmailToOwner(Case ca)
    {
        String mailBody = 'A new email has been received on the case:' +
            '\n\nCase #: ' + ca.AKAM_Case_ID__c + 
            '\nType: ' + ca.RecordType.Name + 
            '\nOpened Date: ' + ca.AKAM_Created_Date__c +
            '\nCase Contact: '+ ((String.isBlank(ca.Contact.Name))? ' ' : ca.Contact.Name) +
            '\nSubject: ' + ca.Subject +
            '\n\nFor the latest status, go to: ' + Environment_Setup__c.getinstance().CName_Url__c + ca.AKAM_Case_ID__c;
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setOrgWideEmailAddressId(SC_FromEmailAddress__c.getValues('Noreply').OrgAddressId__c);
        if( Test.isRunningTest() ){
            mail.setToAddresses(new List<String> {'test@test.com'});
        } else 
          mail.setToAddresses(new List<String> {ca.Owner.Email});
        mail.setWhatId(ca.Id);
        mail.setSubject('You have a new email on [AKAM-CASE #' + ca.AKAM_Case_ID__c + ']');
        mail.setPlainTextBody(mailBody);
        mail.setSaveAsActivity(false);
        List<Messaging.SendEmailResult> emailResults = Messaging.sendEmail(new List<Messaging.Email> {mail});
    }
    
}