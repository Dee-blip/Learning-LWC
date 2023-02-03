/*
As part of MARIT-543,987
This Class handles below functionalities. These are done in async mode (CDC events) as part of lead manual conversion process
1. Marketo Lead To Contact Conversion
2. Update Akamai Leads (BPP stage, BPP status, Lead Conversion Fields)
3. Creates OCR
4. Updates Oppty fields on Contact
*/
public without sharing class MARIT_LeadCDCEventHandler {
    public static void marketoLeadConversion(Set<String> convertedAkamaiLeadIds){
        Boolean skipAlreadyConvertedLeads = true;
        Map<Id,Id> marketoLeadIdToAssociatedAccId = new Map<Id,Id>();
        List<OpportunityContactRole> ocrToInsert =  new List<OpportunityContactRole>();
        List<Contact> contactsToUpdate = new List<Contact>();
        System.debug(logginglevel.DEBUG,'In marketoLeadConversion::akamConvertedIds: '+convertedAkamaiLeadIds);
        Map<Id, Boolean> marketoLeadIDToOppCreationCheck = new Map<Id, Boolean>(); //MARIT-609
        String soql = null;
        List<Lead> leads;
        //map marketolead to associated account id
        soql = 'select Id,Parent_lead__c,Associated_Account__c,Status,Associated_Opportunity__c,Associated_Contact__c from Lead where Id in ';
        soql+=MarketingUtilClass.parseStringsForDynamicQuery(new List<String>(convertedAkamaiLeadIds));
        soql+='  and Parent_lead__c != null';
        leads = (List<Lead>)MarketingUtilClass.fetchFromDataBase(soql);
        for(Lead l : leads){
            marketoLeadIdToAssociatedAccId.put(l.Parent_lead__c,l.Associated_Account__c);
            marketoLeadIDToOppCreationCheck.put(l.Parent_lead__c, true);
        }
        //create contact
        LeadToContactConversionClass.leadConversionAsynModeFlag = true;
        try{
            LeadToContactConversionClass.convertLeadsToContacts(marketoLeadIdToAssociatedAccId,skipAlreadyConvertedLeads,marketoLeadIDToOppCreationCheck);
        }
        Catch(Exception ex){
            //fail over solution
            AddressValidationClass.CallValidateAddressFirstRunFlag_Account = false; //remove validation on account
            AddressValidationClass.CallValidateAddressFirstRunFlag_ContactMailing = false; //remove validation on contact
            AddressValidationClass.CallValidateAddressFirstRunFlag_ContactOther = false; //remove validation on contact
            ContactTriggerClass.checkDuplicatesFirstRunFlag = false; //remove email duplication check
            //convert again
            LeadToContactConversionClass.convertLeadsToContacts(marketoLeadIdToAssociatedAccId,skipAlreadyConvertedLeads,marketoLeadIDToOppCreationCheck);
        }
        LeadToContactConversionClass.leadConversionAsynModeFlag = false;
        System.debug(logginglevel.DEBUG,'Successfully created Contacts:'+marketoLeadIdToAssociatedAccId.size());
        //create OCR - doing repeated query because post contact creation, the contact id is updated on lead
        soql = 'select Id,Parent_lead__c,Associated_Account__c,Status,Associated_Opportunity__c,Associated_Contact__c from Lead where Id in ';
        soql+=MarketingUtilClass.parseStringsForDynamicQuery(new List<String>(convertedAkamaiLeadIds));
        leads = (List<Lead>)MarketingUtilClass.fetchFromDataBase(soql);
        for(Lead l : leads){
            if(l.Associated_Opportunity__c != null && l.Associated_Contact__c != null){
                OpportunityContactRole ocr = new OpportunityContactRole();
                ocr.Role = 'Lead';
                ocr.opportunityId = l.Associated_Opportunity__c; 
                ocr.contactId = l.Associated_Contact__c;
                ocrToInsert.add(ocr);
                //update contact with associated opportunity
                contactsToUpdate.add(new Contact(Id = l.Associated_Contact__c, Associated_Opportunity__c = l.Associated_Opportunity__c));
            }
        }
        //insert OCR
        if(ocrToInsert.size() > 0){
            try{
                insert ocrToInsert;
            }
            catch(Exception ex)
            {
                MarketingUtilClass.sendEmails('OCR Creation Failed '+System.URL.getSalesforceBaseUrl().toExternalForm(), ex, marketoLeadIdToAssociatedAccId.keySet());
                insertErrorLogs(ex,'OCR Creation Failed','MARIT_LeadAsyncConversion.marketoLeadConversion',new List<String>(convertedAkamaiLeadIds));
                System.debug(logginglevel.DEBUG,'Failed OCR Creation:');
            }
            System.debug(logginglevel.DEBUG,'Successfully created OCR:'+ocrToInsert.size());
        }
        //update contact with oppt detail
        if(contactsToUpdate.size() > 0){
            try{
                update contactsToUpdate;
            }
            catch(Exception ex)
            {
                MarketingUtilClass.sendEmails('Associated Opportunity update on Contact failed '+System.URL.getSalesforceBaseUrl().toExternalForm(), ex, marketoLeadIdToAssociatedAccId.keySet());
                insertErrorLogs(ex,'Associated Opportunity update on Contact failed','MARIT_LeadAsyncConversion.marketoLeadConversion',new List<String>(convertedAkamaiLeadIds));
                System.debug(logginglevel.DEBUG,'Failed Contact Updation:');
            }
            System.debug(logginglevel.DEBUG,'Successfully updated Contacts:'+contactsToUpdate.size());
        }
        System.debug(logginglevel.DEBUG,'Async CPU time:'+Limits.getCpuTime());
        System.debug(logginglevel.DEBUG,'Async Query Count:'+Limits.getQueries());
    }

    public static void insertErrorLogs(Exception ex,String errorName,String className,List<String> failedConvertedAkamaiLeadIds){
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        String userRecordInfo = 'The user is: ' + UserInfo.getUserId() + ', RecordIds='+String.join(failedConvertedAkamaiLeadIds,',');
        String error = 'Expection:'+ex.getMessage()+',Cause:'+ex.getCause()+',Stack Trace:'+ex.getStackTraceString()+',Line No:'+ex.getLineNumber();
        System.debug(logginglevel.DEBUG,error);
        errorLogs.add(new Error_Log__c(Name=errorName, Class__c=className, Error_Message__c=error, Object_State__c=userRecordInfo, RecordId__c=failedConvertedAkamaiLeadIds.get(0)));
        Database.insert(errorLogs, false);
    }
}