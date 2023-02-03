/*****************************************************************************
 * Name             : SurveyEmailCaseHandler
 * Created By       : Pitamber Sharma
 * Created Date     : 22-May-2013
 * Purpose          : Inbound Email Handler to parse and create Cases from Survey Follow-up Emails.
 *****************************************************************************/

global class SurveyEmailCaseHandler implements Messaging.InboundEmailHandler {
    
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, 
                                                                                                                                Messaging.InboundEnvelope envelope) {
        System.debug('<<< Email Service Called');
        
        Environment_Setup__c environmentSetup = Environment_Setup__c.getInstance();
        if(environmentSetup.Active_Org__c)
        {
            Set<String> toAddresses = new Set<String>(EmailToCaseUtility.convertLowerCase(email.toAddresses));
            
            RecordType rType;
            for(RecordType rt : [Select Id, Name from RecordType Where SobjectType = 'Case' and 
                                                                                                                                 Name = 'GSS CSAT' limit 1]) {
                rType = rt;
            }   
            
            String delimiter = 'Case #';
            String emailBodyText;
            Case ca = null;
            
            if(email.plainTextBody != null) {
                emailBodyText = email.plainTextBody;
            } else if(email.htmlBody != null) {
                emailBodyText = EmailToCaseUtility.convertHtmlBodyToText(email.htmlBody);
            } else {
                emailBodyText = '';
            }
            
            if(rType != null) {
                if(toAddresses.contains('ccare@akamai.com') && email.fromAddress.equalsIgnoreCase('ccare_team@feedback.akamai.com')) {
                    createCase(email.subject, emailBodyText, rType.Id, 'Transactional CCare Survey', 'Case Closure Disagreement', '1', false, false);
                } else if(toAddresses.contains('ccare@akamai.com') && email.fromAddress.equalsIgnoreCase('ccare_dsat@feedback.akamai.com')) {
                        createCase(email.subject, emailBodyText, rType.Id, 'Transactional CCare Survey', null, '3', true, false);
                } else if(toAddresses.contains('specialist@akamai.com') && email.fromAddress.equalsIgnoreCase('service_desk@feedback.akamai.com')) {
                        createCase(email.subject, emailBodyText, rType.Id, 'Service Desk Survey', null, '3', false, true);
                }
            }
        }
          return null;
        }
        
        private static Case createCase(String subjecttext, String bodytext, Id rtId, 
                                                                        String service, String problem, String severity, Boolean toBeParsed, Boolean isRoutingApplied) {
            System.debug('<<< Create Case Called');
            
            Map<String, Id> queueMap = new Map<String, Id>();
            for(Group g : [Select Id, Name from Group Where Name IN('AMG APJ Management Queue', 'AMG EMEA Management Queue', 'AMG NA Management Queue') And Type = 'Queue']) {
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
            //ca.Problem__c = problem;
            ca.Severity__c = severity;
            
            //Search for Account Id in Transactional CCare Surveys
            String acctSearchKey = 'Account ID:';
            String accountAkamId = EmailToCaseUtility.findString(bodytext, acctSearchKey);
            
            System.debug('<<< accountAkamId = ' + accountAkamId);
            Account acct;
            if(accountAkamId != null) {
                for(Account acc : [Select Id, Geography_Formula__c from Account Where AKAM_Account_ID__c =: accountAkamId]) {
                    acct = acc; 
                    System.debug('<<< Account Id = ' + acct.Id);
                }
                if(acct != null) {
                    ca.AccountId = acct.Id;
                }
            }
            
            //Code to parse and assign owner to case
            if(toBeParsed) {
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
                if(acct.Geography_Formula__c != null) {
                    if(acct.Geography_Formula__c.containsIgnoreCase('APJ')) {
                        ca.OwnerId = queueMap.get('AMG APJ Management Queue');
                    } else if(acct.Geography_Formula__c.containsIgnoreCase('EMEA')) {
                        ca.OwnerId = queueMap.get('AMG EMEA Management Queue');
                    } else {
                        ca.OwnerId = queueMap.get('AMG NA Management Queue');
                    }
                } else {
                    ca.OwnerId = queueMap.get('AMG NA Management Queue');
                }
                */
                toBeParsed = true;                                                                          //set toBeParsed = true, so it doesn't fall in assignment rules.
            }
        
        if(!toBeParsed) {
            Database.DMLOptions dmo = new Database.DMLOptions();
            dmo.assignmentRuleHeader.useDefaultRule = true;
            ca.setOptions(dmo);
        }
        
        if(ca.Id == null) {
                insert ca;
        }
        return ca;
    }  
}