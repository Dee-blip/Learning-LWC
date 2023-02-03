/*=====================================================================================================+
Class name        	:   SC_SI_EmailHandler
Author              :   Vamsee Surya
Created             :   28-Oct-2020
Purpose             :   Service Incident Email Service. 
Test Class          :   

Last Modified 	Developer   	Purpose             
============= 	==========  	=======
10-Sept-20     	Vamsee Surya  	Initial Development(Jira Ticket# ESESP-3792) 
24-Mar-21		Vamsee Surya	Fixing the Prod Exception (ESESP-5042)
+=====================================================================================================*/

global class SC_SI_EmailHandler implements Messaging.InboundEmailHandler{
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope){
        
        String incidentId;
        String oldIncidentId;
        
        //Set of Salesforce Email Bounce Addresses
        Set<String> BounceNames = new Set<String>([Select Value_Text__c from SC_Utility__mdt where MasterLabel = 'Bounce From Name' limit 1].Value_Text__c.split(','));
        
        if(email.subject <> null && (email.subject.toLowerCase().contains('out of office') || email.subject.toLowerCase().contains('out of the office'))){
            return null;
        }
        
        if(email.FromName!=null && BounceNames.contains(email.FromName)){
            return null;
        }
        
        if(email.subject <> null && email.subject.contains('[SI-')){
            incidentId = 'SI-'+ email.subject.substringAfter('[SI-').substringBefore(']');
            oldIncidentId = email.subject.substringAfter('[SI-').substringBefore(']');
            List<SC_SI_Service_Incident__c> incidentRecordList = [SELECT Id FROM SC_SI_Service_Incident__c WHERE Name =:incidentId OR Legacy_Incident_Number__c = :oldIncidentId LIMIT 1];
            If(incidentRecordList.size() > 0){
                EmailMessage newEmail = new EmailMessage();
                newEmail.FromAddress = email.fromaddress;
                newEmail.Incoming = true;
                newEmail.MessageDate = System.now();
                newEmail.Status = '1';
                newEmail.RelatedToId = incidentRecordList[0].Id;
                if(email.subject != null ){
                    newEmail.Subject = (email.Subject.length() < 255 ? email.Subject : email.Subject.substring(0,255));
                }
                if(email.fromname != null ){
                    newEmail.FromName = email.fromname;
                }
                if(email.plainTextBody!=null ){
                    newEmail.TextBody = (email.plainTextBody.length() < 32000 ? email.plainTextBody : email.plainTextBody.substring(0, 32000));
                }
                if(email.htmlbody != null ){
                    newEmail.HtmlBody = (email.htmlbody.length() < 32000 ? email.htmlbody : email.htmlbody.substring(0,32000));
                }
                
                if(email.toAddresses != null)
                    newEmail.ToAddress = EmailToCaseUtility.listToString(email.toAddresses);
                
                if(email.ccAddresses != null)
                    newEmail.ccAddress = EmailToCaseUtility.listToString(email.ccAddresses);
                
                
                
                Insert newEmail;
            }
            
        }
        
        Return null;
        
    }

}