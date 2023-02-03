/*=====================================================================================================+
    Class name          :   AnswerCutomerPSController 
    Authors             :   Aditya
    Created             :   31-Oct-17
    Purpose             :   Controller extension for AnswerCustomerPS VF page
	Test Class			:	AnswerCustomerPS_Test
+=====================================================================================================*/
public class AnswerCutomerPSController {
    
    public String toAddresses{get;set;}
    public String fromAddresses{get;set;}
    private string accId;
    
    public AnswerCutomerPSController(ApexPages.StandardController stdController)
    {
        Id caseId = (Id)stdController.getRecord().Id;
        accId = [Select AccountId from Case where Id = :caseId].AccountId;
        fromAddresses = SC_AnswerCustomerPS__c.getValues('ProfessionalServices').From_Email_Addresses__c;
        List<Case> lCases = [select Contact.Email,Subject,AKAM_Case_Id__c,Alternate_Contact_Email__c,Suggested_Recipients__c from Case where id=:caseId];
        toAddresses = ''+(lCases[0].Contact.Email == null ? '' : lCases[0].Contact.Email+';')+(lCases[0].Alternate_Contact_Email__c==null?'':lCases[0].Alternate_Contact_Email__c+';');
        //toAddresses = toAddresses+(lCases[0].Suggested_Recipients__c==null?'':lCases[0].Suggested_Recipients__c+';');
        
        if(toAddresses != '')
        {    
            //Converting into set to avoid duplication
            Set<String> setToAddresses = new Set<String>((toAddresses.replaceAll(',', ';')).split(';'));
            toAddresses = string.join(new List<String>(setToAddresses),',');
        }

    }
}