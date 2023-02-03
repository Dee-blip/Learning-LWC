/*==========================================================================================================================================+
    Authors                   :   Sharath Prasanna, Aravind Perichiappan
    Purpose                   :   Validate if email recipients are authorized contacts for case (used by sendEmail endpoint in socc-car-api)
    Test class                :   SC_ValidAddress_Case_WS_Test
+==========================================================================================================================================*/

@RestResource(urlMapping='/SC_ValidAddress_Case_WS/*')

global class SC_ValidAddress_Case_WS
{
    @HttpPost
    global static String validateAddress() 
    {
        RestRequest req = RestContext.request;
        Map<String,String> params = (Map<String,String>)JSON.deserialize(req.requestBody.toString(), Type.forName('Map<String,String>'));      
        String caseId = params.get('caseId');
        List<String> emailAddresses = new List<String>();
        List<String> unauthorizedAddresses = new List<String>();
        String toAddress = params.get('to');
        String ccAddress = params.get('cc');
        String bccAddress = params.get('bcc');
        
        if(!String.isBlank(toAddress))
        {
            emailAddresses.addAll(toAddress.split(','));
        }
        if(!String.isBlank(ccAddress))
        {
            emailAddresses.addAll(ccAddress.split(','));
        }
        if(!String.isBlank(bccAddress))
        {
            emailAddresses.addAll(bccAddress.split(','));
        }
        
	    Case caseRec = [SELECT AuthorizedContacts__c, Contact.Email,
                        Case_Situation_Handler__r.Handler__r.Escalation_List__c,Policy_Domain__c,
                        Case_Situation_Handler__c,Do_Not_Show_in_Portal__c FROM Case WHERE Akam_Case_id__c = :caseId];
        if(caseRec.Do_Not_Show_in_Portal__c)
        {
            return 'case is not customer-facing';
        }
	    Id escalationId;
        if(caseRec.Case_Situation_Handler__c != null && caseRec.Policy_Domain__c != null && caseRec.Case_Situation_Handler__r.Handler__r.Escalation_List__c != null)
        {
               escalationId = caseRec.Case_Situation_Handler__r.Handler__r.Escalation_List__c;
        }
    	Set<String> validEmails = new Set<String>();
        for(SC_SOCC_Escalation_via_Case_Email__c emailRec: [Select Authorized_Contact__r.Contact_Name__r.Email,Escalation_List__c from 
                                                            SC_SOCC_Escalation_via_Case_Email__c where Escalation_List__c = :escalationId and Authorized_Contact__r.Contact_Name__r.Email != null])
        {
            validEmails.add(emailRec.Authorized_Contact__r.Contact_Name__r.Email.trim());
        }
        if(caseRec.AuthorizedContacts__c != null)
        {
            List<String> authContacts = caseRec.AuthorizedContacts__c.replace(';',',').replaceAll('\r\n|\n',',').split(',');
            for(String eachEmail : authContacts)
            {
                if(String.isNotBlank(eachEmail))
                {
                    validEmails.add(eachEmail.trim());
                }
            }
        }
        validEmails.add(caseRec.Contact.Email);
        for(String address : emailAddresses) 
        {
            if (!String.isBlank(address) && address != 'null' && 
                !validEmails.contains(address) && !address.containsIgnoreCase('@akamai.com')) 
            {
                unauthorizedAddresses.add(address);
            }
        }
        if(unauthorizedAddresses.size() > 0)
        {
            return 'unauthorized - ' + String.join(unauthorizedAddresses, ', ');
        }
        return 'authorized';
    }
}