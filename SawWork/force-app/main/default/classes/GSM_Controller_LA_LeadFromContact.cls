/**
 *  GSM_Controller_LA_LeadFromContact
 *  Test : GSM_Controller_LA_LeadFromContactTest
 *
   --Developer         --Date          --Description
   Sausharm           03/09/2018       Initial version of Controller for LeadCreation Widget on Live Agent
                                       Chat Record.
 **/

public with sharing class GSM_Controller_LA_LeadFromContact 
{
    // Method called before Lead creation to validate if contact exists and is eligible
    @AuraEnabled
    public static String validateTranscriptRecord(String liveChatTranscriptId) 
    {
        try
        { 
            LiveChatTranscript lcRecord = getLiveChatTranscriptRecord(liveChatTranscriptId);
            if(lcRecord.Contact.Id == null && lcRecord.LeadId == null)
            {
               return 'Error: No Contact/Lead linked to chat record. Please link a valid contact/lead and try again.';
            }
             if(lcRecord.C2A_Lead_Id__c != null && !(lcRecord.C2A_Lead_Id__r.Status == 'Closed' || lcRecord.C2A_Lead_Id__r.Status== 'Converted'))
            {
                return 'Error: A C2A Lead is already Linked to chat record.';
            }
            return 'Success:';        
        }
        catch(Exception e)
        {
            return 'Error:'+e.getMessage();
        
        }
    }
    
    @AuraEnabled
    public static String ShowC2AOnLoad(String liveChatTranscriptId) {
        try
        { 
            LiveChatTranscript lcRecord = getLiveChatTranscriptRecord(liveChatTranscriptId);
            if (lcRecord.C2A_Lead_Id__c != null) {
                return lcRecord.C2A_Lead_Id__c;
            }
            return null;        
        }
        catch(Exception e)
        {
            return 'Error:'+e.getMessage();
        
        }
    }
    
    @AuraEnabled
    public static String isLeadPresent(String liveChatTranscriptId)
    {
        LiveChatTranscript lcRecord = getLiveChatTranscriptRecord(liveChatTranscriptId);
        Id genericId;
        if (lcRecord.Contact.Id != null) {
            genericId = lcRecord.Contact.Id;
        } else {
            genericId = lcRecord.Lead.Id;
        }
        String returnValue = GSM_CallToAction_CreateLeadController.callToActionLeadExists(genericId, false);
       
        if(returnValue != null && returnValue.split(':')!= null && returnValue.split(':').size()>0)
        {
            if(returnValue.split(':')[0] == '0')
            {
                return 'No Lead Present';
            } else if ( (returnValue.split(':')[0] == '1' || returnValue.split(':')[0] == '2') && returnValue.split(':')[1].startswith('00Q')) {
                return returnValue.split(':')[1];
            } else {
                return null;
            }
        }
        return null;
    }

    // Creates Lead from Contact linked to Chat record
    @AuraEnabled
    public static String createLeadFromContact(String liveChatTranscriptId) 
    {
        try
        {
            LiveChatTranscript lcRecord = getLiveChatTranscriptRecord(liveChatTranscriptId);
            Lead l = new Lead();
             if (lcRecord.Contact.Id != null) {
                //MARIT-714 - check for contact having open oppt. If present don't allow C2A creation
                if(MARIT_ContactUtilClass.checkContactOpenOppt(new List<Id>{lcRecord.Contact.Id}, 'Open_Opportunity_Stage_Name').contains(lcRecord.Contact.Id)){ //MARIT-1513
                    return 'New CTA cannot be created because Person has Open Opportunity';
                }
                l.Associated_Contact__c = lcRecord.Contact.Id;
                l.Associated_Account__c = lcRecord.Contact.AccountId;
                l.Country = lcRecord.Contact.MailingCountry;
                l.State = lcRecord.Contact.MailingState;
                l.City = lcRecord.Contact.MailingCity;
                l.Street = lcRecord.Contact.MailingStreet;
                l.PostalCode = lcRecord.Contact.MailingPostalCode;
                l.Solution_Set_Inferred__c = lcRecord.Contact.Solution_Set_Inferred__c;//MARIT-2032
                l = LeadUtilClass.setLeadQualFieldsFromParent(lcRecord.Contact, l, 'Inbound Chat');//MARIT-787
            } else if (lcRecord.Lead.Id != null) {
                l.Parent_Lead__c = lcRecord.Lead.Id;
                l.Associated_Account__c = lcRecord.Lead.Associated_Account__c;
                l.Company = lcRecord.Lead.Company;
                l.LastName = lcRecord.Lead.LastName;
                l.FirstName = lcRecord.Lead.FirstName;
                l.Email = lcRecord.Lead.Email;
                l.Phone = lcRecord.Lead.Phone;
                l.Title = lcRecord.Lead.Title;
                l.Country = lcRecord.Lead.Country;
                l.State = lcRecord.Lead.State;
                l.City = lcRecord.Lead.City;
                l.Street = lcRecord.Lead.Street;
                l.PostalCode = lcRecord.Lead.PostalCode;
                l.Solution_Set_Inferred__c = lcRecord.Lead.Solution_Set_Inferred__c; //MARIT-2032 
                l = LeadUtilClass.setLeadQualFieldsFromParent(lcRecord.Lead, l, 'Inbound Chat');//MARIT-787
            }
           
            if(lcRecord.Contact.DoNotCall && lcRecord.Contact.HasOptedOutOfEmail){
                return 'Error: Cannot create C2A when "Do Not Call" and "Email Opt Out" is checked';
            }
            //String liveAgentCampaignId = GsmUtilClass.getGSMSettingValue('Live_Agent_CampaignId');
            //MARIT-688, adding status to campaign member
            GSM_Settings__mdt campaignMetadata = Database.query('select Id,Value__c,Status__c from GSM_Settings__mdt where DeveloperName = \'Live_Agent_CampaignId\' LIMIT 1');
            if(campaignMetadata != null && campaignMetadata.Value__c != null && campaignMetadata.Value__c != '')
            {
                l.Primary_Campaign__c = campaignMetadata.Value__c;//'7013C00000064TyQAI';
            }
            l.adg_Self_Generated_Lead_Type__c = 'Inbound Chat';
            if(ProfileUtils.isSDR())
            {
                l.Lead_Owner__c = UserInfo.getUserId();
                l.OwnerId = UserInfo.getUserId();
                l.isC2ABySDR__c = true;
            }
            insert l;
            
            //MARIT-787
            if (lcRecord.Contact.Id != null) {
                Contact con = new Contact();
                con.id = lcRecord.Contact.Id;
                con.Lead_Qualification_Stage__c = l.Lead_Qualification_Stage__c;
                con.Lead_Qualification_Status__c = l.Lead_Qualification_Status__c;
                update con;
            } else if (lcRecord.Lead.Id != null) {
                Lead l1 = new Lead();
                l1.id = lcRecord.Lead.Id;
                l1.Lead_Qualification_Stage__c = l.Lead_Qualification_Stage__c;
                l1.Lead_Qualification_Status__c = l.Lead_Qualification_Status__c;
                update l1;
            }

            Id personId;
            if (lcRecord.Contact.Id != null) {
               personId = lcRecord.Contact.Id;
            } else if (lcRecord.Lead.Id != null) {
                personId = lcRecord.Lead.Id;
            }
            List<CampaignMember> cmpgnMbrList = [Select ContactId, LeadId from CampaignMember where LeadId =:personId or ContactId =:personId];
            if (cmpgnMbrList.isEmpty() && personId != null) {
                CampaignMember cmpgnMbrContact;
                if (lcRecord.Contact.Id != null) {
                    cmpgnMbrContact = new CampaignMember(CampaignId = campaignMetadata.Value__c, ContactId  = lcRecord.Contact.Id, Status = campaignMetadata.Status__c);
                } else if (lcRecord.Lead.Id != null) {
                    cmpgnMbrContact = new CampaignMember(CampaignId = campaignMetadata.Value__c, LeadId  = lcRecord.Lead.Id, Status = campaignMetadata.Status__c);
                }
                
                insert cmpgnMbrContact;
            }

            lcRecord.C2A_Lead_Id__c = l.Id;
            update lcRecord;
            
            return String.valueof(l.Id);
        }
        catch(Exception e)
        {
            return 'Error:'+e.getMessage();
        }
    }
    
    @AuraEnabled
    public static String linkC2AToLiveChat (String liveChatTranscriptId, Id c2aId) {
        try {
            LiveChatTranscript lcRecord = getLiveChatTranscriptRecord(liveChatTranscriptId);
            lcRecord.C2A_Lead_Id__c = c2aId;
            update lcRecord;
            return lcRecord.C2A_Lead_Id__c;
        } catch(Exception e) {
            return 'Error:'+e.getMessage();
        }
    }

    
    private static LiveChatTranscript getLiveChatTranscriptRecord(String liveChatTranscriptId)
    {
        //MARIT-2032 -- Added Contact.Solution_Set_Inferred__c and Lead.Solution_Set_Inferred__c in below query.
        return [select Id, Contact.Id,Contact.DoNotCall,Contact.HasOptedOutOfEmail,Contact.MailingCountry,Contact.MailingState,Contact.MailingCity,Contact.MailingStreet,Contact.MailingPostalCode,LeadId,Lead.Name,Contact.AccountId,Contact.Solution_Set_Inferred__c, C2A_Lead_Id__c, C2A_Lead_Id__r.Status, Lead.Associated_Account__c, Lead.Company, Lead.LastName, Lead.FirstName, Lead.Email, Lead.Phone, Lead.Title, Lead.Lead_Owner__c,Lead.Country,Lead.State,Lead.City,Lead.Street,Lead.PostalCode,Lead.Solution_Set_Inferred__c from LiveChatTranscript where Id=:liveChatTranscriptId];
    }
}