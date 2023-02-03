/* History:
 * =========================
 * @author  Himanshu Verma,  15th June 2020  
 MARIT-539
 */
public class MARIT_CreateOrLinkToLiveChatController {
    public class PersonInfo {
        String Id;
        String Name;
        String Email;
        String Type;
    }
    public class PersonInfoAfterLinking {
        String Id;
        String Name;
        String Email;
        Address Address;
        string Title;
        string Phone;
        string Company;
    }
    
    /*
     * Gets the list of objects based on the searchText. It searches across the contacts as well as the leads.
*/
    @AuraEnabled
    public static List<String> searchForIds(String searchText) {
        PersonInfo info = new PersonInfo();
        List<List<SObject>> results = [FIND :searchText IN ALL FIELDS  RETURNING Contact(Id, Name, Email, recordType.Name where recordType.Name = 'Business Contact'),
                                       Lead(Id, Name, Email, recordType.Name where recordType.Name = 'Marketo Lead' and ConvertedContactId = null) Limit 10];
        List<String> ids = new List<String>();
        String newID;
        Lead lObj;
        Contact cObj;
        for (List<SObject> sobjs : results) {
            for (SObject sobj : sobjs) {
                 newID = '' + sobj.Id;
                if (newId.startsWith('00Q')) {
                    lObj = (Lead)sobj;
                    info.Id = lObj.Id;
                    info.Name = lobj.Name;
                    info.Email = lobj.Email != null ? lobj.Email : '-';
                    info.Type = lobj.recordType.Name;
                    ids.add(JSON.serialize(info));
                } else if (newId.startsWith('003')) {
                    cObj = (Contact)sobj;
                    info.Id = cObj.Id;
                    info.Name = cObj.Name;
                    info.Email = cObj.Email != null ? cObj.Email : '-';
                    info.Type = cObj.recordType.Name;
                    ids.add(JSON.serialize(info));
                }
            }
        }
        return ids;
    }
    
    /*
    Links the Lead/Contact to live chat
    */
    @AuraEnabled
    public static String LinkPersonToLiveChat(string LiveChatId, string personId) {
        LiveChatTranscript lcrecord = [select Id, LeadId, ContactId, AccountId from LiveChatTranscript where id = :LiveChatId];
        PersonInfoAfterLinking personToBeLinked = new PersonInfoAfterLinking();
        if (personId.startsWith('00Q')) {
            Lead l = [select Id, Name, Email, Phone, Title, Address, Company, Associated_Account__c from Lead where Id = :personId];
            personToBeLinked.Id = l.Id;
            personToBeLinked.Name = l.Name;
            personToBeLinked.Email = l.Email;
            personToBeLinked.Phone = l.Phone;
            personToBeLinked.Title = l.Title;
            personToBeLinked.Address = l.Address;
            personToBeLinked.Company = l.Company;
            lcrecord.LeadId = l.Id;
            lcrecord.ContactId = null;
            lcRecord.AccountId = l.Associated_Account__c;
        } else if (personId.startsWith('003')) {
            Contact con = [select Id, Name, Email, Phone, Title, MailingAddress, Company__c, AccountId from Contact where Id = :personId];
            personToBeLinked.Id = con.Id;
            personToBeLinked.Name = con.Name;
            personToBeLinked.Email = con.Email;
            personToBeLinked.Phone = con.Phone;
            personToBeLinked.Title = con.Title;
            personToBeLinked.Address = con.MailingAddress;
            personToBeLinked.Company = con.Company__c;
            lcrecord.ContactId = con.Id;
            lcrecord.LeadId = null;
            lcRecord.AccountId = con.AccountId;
        }
        try {
            update lcrecord;
            return Json.serialize(personToBeLinked);
        } catch (Exception ex) {
            personToBeLinked.Id = ex.getMessage();
            return Json.serialize(personToBeLinked);
        }
    }
    
    @AuraEnabled
    public static String CheckIfLCAlreadyLinked(string LiveChatId) {
        if (LiveChatId == null || LiveChatId == '') {
            return null;
        }
        LiveChatTranscript lcrecord = [select Id, LeadId, ContactId, Lead.Name, Lead.ConvertedContactId, Contact.Name, Lead.Associated_Account__c from LiveChatTranscript where id = :LiveChatId];
        PersonInfo info = new PersonInfo();
        if (lcrecord.ContactId != null) {
            info.Id = lcrecord.ContactId;
            info.Name = lcrecord.Contact.Name;
            return Json.serialize(info);
        } else if (lcrecord.Lead.ConvertedContactId != null && lcrecord.LeadId != null) {
            info.Id = lcrecord.Lead.ConvertedContactId;
            info.Name = lcrecord.Lead.Name;
            lcrecord.ContactId = lcrecord.Lead.ConvertedContactId;
            lcrecord.LeadId = null;
            lcRecord.AccountId = lcrecord.Lead.Associated_Account__c;
            update lcRecord;
            System.debug('Converted updated lcRecord : ' + lcRecord);
            return Json.serialize(info);
        } else if (lcrecord.LeadId != null) {
            info.Id = lcrecord.LeadId;
            info.Name = lcrecord.Lead.Name;
            info.Email = '';
            info.Type = '';
            return Json.serialize(info);
        } 
        return null;
    }
    
    // Lead creation component
    @AuraEnabled
    public static String SaveMarketoLeadAndLinkToChat(Lead newLead, Id liveChatId) {
        PersonInfo info = new PersonInfo();
        Id marketoLeadRecordTypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        Id marketoSyncUserId = GsmUtilClass.getGSMSettingValue('MarketoSyncUserId');
        newlead.RecordTypeId = marketoLeadRecordTypeId;
        newLead.Person_Lead_Source__c = 'Inbound Chat';
        newLead.OwnerId = marketoSyncUserId;
        newLead.Company_Self_Entered__c = newLead.Company;
        try {
            if (newLead.Associated_Account__c == null) {
                newLead.Associated_Account__c = GsmUtilClass.getGSMSettingValue('WWWLeadGenAccountIdMarketo'); 
            }
            insert newLead;
            
            //MARIT-1151
            InnerMARIT_CreateOrLinkToLiveChatController imc = new InnerMARIT_CreateOrLinkToLiveChatController();
            imc.updateLCRRecord(liveChatId, newLead);
            
            info.Id = newLead.Id;
            info.Name = newLead.FirstName + ' ' + newLead.LastName;
        } catch (Exception ex) {
            System.debug('Error inserting Saving :' + ex.getMessage());
            info.Id = ex.getMessage();
            return Json.serialize(info);
        }
        return Json.serialize(info);
    }
    
    @AuraEnabled
    public static LiveChatTranscript getLiveChat(Id LiveChatId) {
        LiveChatTranscript lcRec = [Select Id, LeadId, ContactId from LiveChatTranscript where id =:LiveChatId];
        return lcrec;
    }
    
    @AuraEnabled
    public static string IsC2ALinkedToLiveChat(Id LiveChatId) {
        LiveChatTranscript lcRec = [Select Id, LeadId, ContactId, C2A_Lead_Id__c from LiveChatTranscript where id =:LiveChatId];
        if (lcRec.C2A_Lead_Id__c != null) {
            return 'C2A Exists';
        }
        try {
            lcRec.LeadId = null;
            lcRec.ContactId = null;
            lcRec.AccountId = null;
            update lcRec;
            return 'Successful';
        } catch (Exception ex) {
            return ex.getMessage();
        }
    }
    
    //MARIT-1151
    public without sharing class InnerMARIT_CreateOrLinkToLiveChatController{
        public void updateLCRRecord(Id liveChatId, Lead newLead){
            LiveChatTranscript lcrecord = [select Id, LeadId from LiveChatTranscript where id = :liveChatId];
            lcrecord.LeadId = newLead.Id;
            lcrecord.AccountId = newLead.Associated_Account__c;
            update lcRecord;
        }
    }
}