/*
 * Created as part of MARIT-1079
 * Will be used for contact cleanup/governance use cases to be handled.
 */
public without sharing class MARIT_ContactHandler {
    
    // MARIT-1079 : Method going to be invoked by other applications before creating a contact
    public static Contact convertExisitingLead(String email) {
        if(!String.isBlank(email)) {
            List<lead> leads = getLeadsWithEmail(email);
            if(!leads.isEmpty()){
                string result = convertMarketoLeadToContact(leads[0]);
                Map<String,Object> contactInfo = (Map<String,Object>) JSON.deserializeUntyped (result);
                if(String.valueOf(contactInfo.get('status')) == 'Success') {
                    Contact c = new Contact();
                    c.Id = String.valueOf(contactInfo.get('Id'));
                    c.akam_contact_id__c = String.valueOf(contactInfo.get('akam_contact_id__c'));
                    c.email = email;
                    return c;
                } else {
                    return null;
                }
            } else {
                return null;
            }
        } else {
            return null;
        }
    }

    // method to update c2a record with Associated_Contact__c post conversion
    @future
    public static void copyContactToC2ALead(string leadId, string contactId) {
        List<lead> allC2ALeads = [Select id,Associated_Contact__c  from Lead where Parent_Lead__c = :leadId];
        if(!allC2ALeads.isEmpty()) {
            try {
                for(Integer i=0; i<allC2ALeads.size(); i++ ){
                	allC2ALeads[i].Associated_Contact__c = contactId;
                }
                update allC2ALeads;
            } catch(Exception ex) {
                System.debug(LoggingLevel.ERROR,'Exception while updating c2a : ' + ex.getMessage());
                Error_Log__c el = new Error_Log__c(Name='copyContactToC2ALead', Class__c='MARIT_ContactHandler', Error_Message__c=ex.getMessage(), RecordId__c= allC2ALeads[0].id);
                insert el;
            }
        }
    }
    
    // MARIT-1079 : Method which checks if a Marketo lead exits in New/In Process status
    public static List<lead> getLeadsWithEmail(String email) {
        List<lead> leadObjList = [Select id, Email, Associated_Account__c, Associated_AKAM_Account_Id__c  from Lead where email = :email and status in ('New', 'In Process') and recordType.Name = 'Marketo Lead'];
        return leadObjList;
    }
    
    // MARIT-1079 : Method which converts Marketo Lead to Contact
    public static string convertMarketoLeadToContact(Lead lead) {
    
        lead.Associated_AKAM_Account_ID_dup__c = lead.Associated_AKAM_Account_Id__c;
        update lead;

        Database.LeadConvert templc = new Database.LeadConvert();
        templc.setLeadId(lead.id);
        templc.setConvertedStatus('Converted');
        templc.setAccountId(lead.Associated_Account__c);
        templc.setDoNotCreateOpportunity(true);
        
        try {
            System.debug(LoggingLevel.ERROR,'converting the lead##');
        	Database.LeadConvertResult lcr = Database.convertLead(templc);
            if(lcr!=null)
            {
                System.debug(LoggingLevel.ERROR,'lcr is not null but not success');
                if(lcr.isSuccess() && lcr.getContactId() != null)
                {
                    //get the ID of the contact converted from lead 
                    System.debug(LoggingLevel.ERROR,'lcr is success '+ lcr.getContactId());
                    string contactId = lcr.getContactId();
                    Contact cont = [SELECT id, akam_contact_id__c FROM Contact WHERE id =:ContactId limit 1];
                    Map<String,String> contactInfo = new Map<String,String>();
                    contactInfo.put('status','Success');
                    contactInfo.put('Id',contactId);
                    contactInfo.put('akam_contact_id__c',cont.akam_contact_id__c);
                    copyContactToC2ALead(lead.Id,contactId);
                    return JSON.serialize(contactInfo);
                }
            }
        } catch(Exception ex) {
            System.debug(LoggingLevel.ERROR,'Exception while converting : ' + ex.getMessage());
         	Error_Log__c el = new Error_Log__c(Name='convertLead', Class__c='MARIT_ContactHandler', Error_Message__c=ex.getMessage(), RecordId__c= lead.id);
            insert el; 
            return '{"status": "Failure", "message": "Lead conversion failed: ' + ex + '"}';
        }
        return null;
    }

}