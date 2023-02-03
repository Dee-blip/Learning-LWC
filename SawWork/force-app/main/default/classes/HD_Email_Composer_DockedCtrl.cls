/*
* Coder @ Hemant Barapatre  
* this is email composer for sending the emails
* 
*/

public class HD_Email_Composer_DockedCtrl {
    
    @AuraEnabled
    public static String sendEmailmethod(String[] toAddresses, String[] ccAddresses, String subject, String body){
        try
        {
            
            Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
            Messaging.Singleemailmessage objEmail; 
            objEmail = new Messaging.Singleemailmessage();            
            objEmail.setSubject(subject);
            objEmail.setPlainTextBody(body);
            objEmail.setHtmlBody(body);
            
            Boolean isSandbox = [SELECT IsSandbox FROM Organization LIMIT 1].IsSandBox;
            OrgWideEmailAddress[] owea = [select Id,Address,DisplayName from OrgWideEmailAddress where DisplayName = 'Akamai Ticketing'];
            
            String address;
            if(isSandbox)
            {
                // address = 'bmcsd_emailconversationlistener@l-1jbyudbld6hpy2o1gecjn2uj6iw0465a72m7jrvvi3r9d2ww42.5b-scyuam.cs52.apex.sandbox.salesforce.com';
                address = 'akamaihd-tixdev@akamai.com';
                
            }
            else
            {
                address = 'akamaihd-tix@akamai.com';
            }
            ccAddresses.add(address);
            
            objEmail.setToAddresses(toAddresses);
            objEmail.setccAddresses(ccAddresses);
            
            if( owea.size() > 0 )
            {
                objEmail.setOrgWideEmailAddressId(owea.get(0).Id);      
            } 
            system.debug('TO address ---> '+ toAddresses );
            
            mailsToBeSent.add(objEmail);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(mailsToBeSent,false);
            if (results[0].success) {
                System.debug('The email was sent successfully.');
                return 'The email was sent successfully';
            } else {
                System.debug('The email failed to send: '
                             + results[0].errors[0].message);
                return String.valueOf(results) ;
            }
                        
        }
        catch(Exception e)
        {
            throw new AuraHandledException(e.getMessage());
        }
        
        
    } //   

    @AuraEnabled(cacheable=true)
    public static Boolean switchToNewUI(String customMetadataRecName, String settingValue){
        HD_Instance__mdt hdNewEmailUI = HD_Instance__mdt.getInstance(customMetadataRecName);
        if(hdNewEmailUI != null) {
            return hdNewEmailUI.SettingValue__c.split(';').contains(settingValue);
        }else {
            return false;
        }
    }
    
}//END