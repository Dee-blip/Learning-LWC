// MARIT-204 Added by Himanshu Verma on 17th December 2019
// This class handles various scenarios for custom contact creation

public class CreateCustomContactController {
    public class ContactInfo { 
        String id;
        String message;
    }
    
    
	@AuraEnabled
	public static String CheckOrCreateNewContact(Contact newCon, String recordId)
	{
        ContactInfo conInfo = new Contactinfo();
			try {
                Contact con;
                List<Contact> contactObjList = GetContactsWithProvidedEmail(newCon.Email);
                if (contactObjList.size() > 0) {
                    con = contactObjList[0];
                }
                if(con == null) {
                    Lead l;
                    List<lead> leadObjList = GetLeadsWithProvidedEmail(newCon.Email);
                    if (leadObjList.size() > 0) {
                        l = leadObjList[0];
                    }
                    if (l == null) {
                        newCon.recordTypeId = recordId;
                        insert newCon;
                        conInfo.id = newCon.id;
                        conInfo.message = 'Contact created successfully';
                    }
                    else
                    {
                        conInfo.id = l.id;
                        conInfo.message = 'Lead Exists';
                    }
                }
                else {
                    conInfo.id = con.id;
                    conInfo.message = 'Contact Exists';
                }
                return JSON.serialize(conInfo);
			} catch(Exception e) {
                conInfo.id = 'Creation failed';
                Error_Log__c el = new Error_Log__c(Name='CheckOrCreateNewContact', Class__c='CreateCustomContactController', Error_Message__c=e.getMessage());
                insert el;
                conInfo.message = e.getMessage();
                return JSON.serialize(conInfo);
			}
	}
    
     @AuraEnabled
    public static String IgnoreAndCreateNewContact(Contact newContact, String recordId) {
        newContact.recordTypeId = recordId;
        ContactInfo conInfo = new Contactinfo();
        try {
        	insert newContact;
            conInfo.id = newContact.id;
            conInfo.message = 'Creation Success';
        } catch (Exception e) {
            Error_Log__c el = new Error_Log__c(Name='IgnoreAndCreateNewContact', Class__c='CreateCustomContactController', Error_Message__c=e.getMessage(), RecordId__c= recordId);
            insert el;
            conInfo.message = 'Creation failed';
            conInfo.id = e.getMessage();
            return JSON.serialize(conInfo);
        }
        return JSON.serialize(conInfo);
    }
    
    @AuraEnabled
    public static String ConvertExistingLeadToContact(String existingEmail) {
        List<lead> leadObjList = GetLeadsWithProvidedEmail(existingEmail);
        if (leadObjList.size() > 0) {
            return ConvertExistingLeadToContactHelper(leadObjList[0]);
        }
        ContactInfo conInfo = new Contactinfo();
        conInfo.message = 'Lead not found';
        conInfo.id = 'Lead object does not exists';
        return JSON.serialize(conInfo);
    }
    
    //MARIT-1201
    @AuraEnabled
    public static Boolean checkProfileForFirstName () {

        Boolean ifProfileIdMatches = false;
        List<String> profileIds = MarketingUtilClass.getMarketingSettingValuePartialMatch('ProfilesForContactFirstName');
        profileIds = String.join(profileIds,',').split('\\s*,\\s*');
        String userProfileId = userinfo.getProfileId();
        
        if(userProfileId.length() != 15){
            userProfileId = userProfileId.substring(0,15);
        }
        //Can't use contains method of List as need to iterate through each record and convert it in 15 char ID
        for(String str : profileIds){
            if(str.length() != 15){
                str = str.substring(0,15);
            }
            if(userProfileId == str){
                ifProfileIdMatches = true;
            }
        }
        return ifProfileIdMatches;
    }
    
    private static String ConvertExistingLeadToContactHelper(lead leadObj) {
        ContactInfo conInfo = new Contactinfo();
        Database.LeadConvert templc;
        Database.LeadConvertResult lcr=null;
        String ContactId;
        templc = new Database.LeadConvert();
        templc.setLeadId(leadObj.id);
        templc.setConvertedStatus('Converted');
        templc.setAccountId(leadObj.Associated_Account__c);
        System.debug('not setting account'+leadObj.Associated_Account__c);
        templc.setDoNotCreateOpportunity(true);
        
        try {
            System.debug('converting the lead##');
            lcr = Database.convertLead(templc);
        } catch(Exception ex) {      
            System.debug('Exception while converting : ' + ex.getMessage());
         	Error_Log__c el = new Error_Log__c(Name='ConvertExistingLeadToContact', Class__c='CreateCustomContactController', Error_Message__c=ex.getMessage(), RecordId__c= leadObj.id);
            insert el; 
            conInfo.message = 'Conversion failed';
            conInfo.id = ex.getMessage() + ' Please reach out to Marketing operations, Business operation or EAE ops in case a contact needs to be created.';
            return JSON.serialize(conInfo);
        }
        if(lcr!=null)
        {
            System.debug('lcr is not null but not success');
            if(lcr.isSuccess())
            {
                System.debug('lcr is success');
                System.debug(' ' + lcr.getContactId());
                //get the ID of the contact converted from lead
                if(lcr.getContactId() != null)
                { 
                    ContactId = lcr.getContactId();
                    System.debug(LoggingLevel.ERROR, 'ML Email : ' + leadObj.Email);
                    List<Lead> ctaLeads = [Select Id, Associated_Contact__c from Lead where Email = :leadObj.Email and status in ('New', 'In Process') and recordType.Name = 'Akamai Lead' limit 1];
                    if (!ctaLeads.isEmpty() && ctaLeads[0].Associated_Contact__c == null) {
                        System.debug(LoggingLevel.ERROR, 'ctaLead retrieved : ' + ctaLeads[0]);
                        ctaLeads[0].Associated_Contact__c = ContactId;
                        update ctaLeads[0];
                    }
                }
            }
        }
        conInfo.message = 'Conversion successful';
        conInfo.id = ContactId;
        return JSON.serialize(conInfo);
    }
    
    @AuraEnabled
    public static RecordType FetchRecordBasedOnId (String recordId) {
        List<String> recordTypeIds = new List<String>();
        if(recordId == '' || recordId == null){
            Schema.DescribeSObjectResult R = Contact.SObjectType.getDescribe();
            List<Schema.RecordTypeInfo> RT = R.getRecordTypeInfos();  
            for( Schema.RecordTypeInfo recordType : RT )
            {
                if(recordType.isAvailable())
                { 
                    if(recordType.Name!='Master') {
                        recordTypeIds.add(recordType.RecordTypeId);
                    }
                }
            }
        }
        RecordType rec;        
        if(recordTypeIds.size()>0) {
			recordId = recordTypeIds[0];
        }
        rec = [select BusinessProcessId, CreatedById, CreatedDate, Description, 
               DeveloperName, Id, IsActive, LastModifiedById, LastModifiedDate, Name, 
               NamespacePrefix, SobjectType, SystemModstamp from RecordType where id = :recordId];
        return rec;
    }
    
    //MARIT-1280
    @AuraEnabled
    public static Boolean checkProfileToShowIgnoreAndCreateButton () {

        String profilesForContactCreation = MarketingUtilClass.getMarketingSettingsValue('ProfilesForContactCreation');
        if(profilesForContactCreation != null && profilesForContactCreation.contains(userInfo.getProfileId())) {
            return true;
        }
        return false;
    }

    private static List<lead> GetLeadsWithProvidedEmail(String existingEmail) {
        List<lead> leadObjList = [Select id, Email, Associated_Account__c  from Lead where Email = :existingEmail 
                        and Status in ('New', 'In Process') and recordType.Name = 'Marketo Lead'];
        return leadObjList;
    }
    
    private static List<Contact> GetContactsWithProvidedEmail(String existingEmail) {
        List<Contact> contactObjList = [Select Id, Email from Contact where Email = :existingEmail];
        return contactObjList;
    }
}