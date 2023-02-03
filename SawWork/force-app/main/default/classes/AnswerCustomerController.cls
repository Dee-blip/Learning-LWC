/*=====================================================================================================+
    Class name          :   AnswerCustomerController 
    Authors             :   Akhila
    Created             :   10-Mar-16
    Purpose             :   Controller extension for AnswerCustomer VF page

    Modified by         :
Vandhana for CR 3596981 - added AKAM Case Id and Subject
Pinkesh     18-May-2017     ESESP-392      Display warning when auto-suggestions being offered by SF are from different accounts 

+=====================================================================================================*/
public class AnswerCustomerController {

    public String toAddresses{get;set;}
   // public String ccAddresses{get;set;}            

    
    //ESESP-392
    public string emailAddress {get; set;}
    private string accId;
    
    public AnswerCustomerController(ApexPages.StandardController stdController)
    {
//        String caseId = ApexPages.currentPage().getParameters().get('id');
        Id caseId = (Id)stdController.getRecord().Id;
        
        //ESESP-392
        accId = [Select AccountId from Case where Id = :caseId].AccountId;
        
        List<Case> lCases = [select AuthorizedContacts__c,Contact.Email,Subject,AKAM_Case_Id__c,Alternate_Contact_Email__c,Suggested_Recipients__c,Microsoft_Email_address__c from Case where id=:caseId];
        toAddresses = ''+(lCases[0].AuthorizedContacts__c==null?'':lCases[0].AuthorizedContacts__c+';')+(lCases[0].Contact.Email==null?'':lCases[0].Contact.Email+';')+(lCases[0].Alternate_Contact_Email__c==null?'':lCases[0].Alternate_Contact_Email__c+';');
        toAddresses = toAddresses+(lCases[0].Suggested_Recipients__c==null?'':lCases[0].Suggested_Recipients__c+';');
        
        if(toAddresses!='')
        {    
            //Converting into set to avoid duplication
            Set<String> setToAddresses = new Set<String>((toAddresses.replaceAll(',', ';')).split(';'));
            toAddresses = string.join(new List<String>(setToAddresses),',');
        }
        toAddresses = toAddresses+','+(lCases[0].Microsoft_Email_address__c==null?'':lCases[0].Microsoft_Email_address__c+';');
        /*/To obtain cc address = Suggested Receipients - Partner Contact marked as primary + Microsoft default address
        String suggestedRecipientWithPrimaryRemoved = (lCases[0].Suggested_Recipients__c==null?'':lCases[0].Suggested_Recipients__c);
        if(lCases[0].Contact.Email!=null)
        {
           //Removing Contact email which will be marked as primary as it will be available in To address
           suggestedRecipientWithPrimaryRemoved = suggestedRecipientWithPrimaryRemoved.remove(lCases[0].Contact.Email).removeStart(';').replace(';;',';'); 
        }   
        if(lCases[0].Alternate_Contact_Email__c!=null)
        {
           //Removing alternate Contact email which will be marked as primary as it will be available in To address            
           suggestedRecipientWithPrimaryRemoved = suggestedRecipientWithPrimaryRemoved.remove(lCases[0].Alternate_Contact_Email__c).removeStart(';').replace(';;',';');
        }            
        
        ccAddresses = ''+suggestedRecipientWithPrimaryRemoved+';'+lCases[0].Microsoft_Email_address__c;*/
    }
    
    
    //This method validates the emails in the publisher action
    public PageReference ValidateEmails(){  
        if(emailAddress.length() > 0 && accId != null)
        {
            //Get all the email ids entered in to, cc and bcc fields
            List<string> lstCaseEmails = emailAddress.split(';');
            Set<String> sCaseEmails = new Set<String>(lstCaseEmails);
            String extRegisteredEmail = '';
            String extNonRegisteredEmail = '';
            
            //find all email ids associated with Account and remove them.
            for(Contact con : [Select Id, Name, Email from Contact where Email in :sCaseEmails and AccountId = :accId]){
                sCaseEmails.remove(con.Email);
            }
            
            //find all email ids assciated with contacts other than current account id and not in akamai domain
            for(Contact con : [Select Id, Name, Email from Contact where Email in :sCaseEmails and AccountId != :accId and (NOT Email like '%akamai.com%')]){
                extRegisteredEmail += '"' + con.Name + '"&nbsp&nbsp';
                sCaseEmails.remove(con.Email);
            }

            //build string to display external non-registered email addresses
            for(String str : sCaseEmails)
                if(!str.contains('akamai.com'))
                    extNonRegisteredEmail += '"' + str + '"&nbsp&nbsp';
            
            if(extRegisteredEmail.length() > 0 || extNonRegisteredEmail.length() > 0)
            {
                string warning = '';
                if(extRegisteredEmail.length() > 0){
                    warning = 'The following external email contacts are not associated with this account:<div style="color:red; word-break: break-all;">';
                    warning += extRegisteredEmail;
                    warning += '</div>';
                }
                if(extNonRegisteredEmail.length() > 0){
                    warning += 'The following external emails are not registered Akamai contacts:<div style="color:red; word-break: break-all;">';
                    warning += extNonRegisteredEmail;
                    warning += '</div>';
                }
                warning += 'Please verify these before sending the email. Failure to do so violates Akamai\'s NDAs with our partners & customers and is a potential information security breach service incident.';
                
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING, warning));
            }
        }
        return null;
    }
}