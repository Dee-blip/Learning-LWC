/*
 * Created By Mayank Bansal on 19th Sept,19 as part of MARIT-67
 */
public without sharing class MARIT_ContactTriggerClass {
   
    /* commenting this code as this fucntion is not called from anywhere to improve the code coverage of 20.5 release
    public static void copyAddrFieldsToLocalFields(Contact con){
        con.City_Local__c = con.mailingCity;
        con.Company_Self_entered_Local__c = con.Company__c;
        con.Country_Local__c = con.mailingCountry;
        con.First_Name_Local__c = con.FirstName;
        con.Last_Name_Local__c = con.LastName;
        con.State_Province_Local__c = con.mailingState;
        con.Title_Local__c = con.Title;
        con.Street_Local__c = con.mailingStreet;
        con.Zip_Postal_Code_Local__c = con.mailingpostalCode;
    }*/
    
    //MARIT-214 //Revamped as part of MARIT-448
    public static void updateC2ALeadFromPersonContact(Set<Id> updatedPersonContacts,Map<Id,Contact> oldPersonContactMap,Map<Id,Contact> newPersonContactMap){
        
        List<Lead> CTAsToUpdate = new List<Lead>();
        Boolean toUpdate = false;
        
        List<String> personContactC2ASyncFields = MarketingUtilClass.getMarketingSettingValuePartialMatch('personContactC2ASyncFields');
        personContactC2ASyncFields = String.join(personContactC2ASyncFields,',').split('\\s*,\\s*');
        
        List<String> marketoC2ASyncFields = MarketingUtilClass.getMarketingSettingValuePartialMatch('marketoC2ASyncFields');
        marketoC2ASyncFields = String.join(marketoC2ASyncFields,',').split('\\s*,\\s*');
        
        String query = 'SELECT Id,Associated_Contact__c,' + String.join(marketoC2ASyncFields,',') + ' FROM Lead WHERE Associated_Contact__c in ';
        query+=MarketingUtilClass.parseIdsForDynamicQuery(new List<Id>(updatedPersonContacts));
        query+=' and status in (\'New\', \'In Process\')';
        List<Lead> CTAList = (List<Lead>)MarketingUtilClass.fetchFromDataBase(query);
        
        for(Lead l1 : CTAList){
            for(String field : personContactC2ASyncFields){
                
                String conField = field;
                String leadField = field;
                
                //MARIT-553 added else if conditions for address fields copyover from cta to contact             
                if(leadField == 'AccountId'){
                    leadField = 'Associated_Account__c';
                } else if(leadField == 'Mailingcity'){
                    leadField = 'city';
                } else if(leadField == 'Mailingstreet'){
                    leadField = 'street';
                } else if(leadField == 'Mailingstate'){
                    leadField = 'state';
                } else if(leadField == 'Mailingcountry'){
                    leadField ='country';
                } else if(leadField == 'MailingpostalCode'){
                    leadField ='postalCode';
                }
                if(oldPersonContactMap.get(l1.Associated_Contact__c).get(conField) != newPersonContactMap.get(l1.Associated_Contact__c).get(conField) && 
                  	l1.get(leadField) != newPersonContactMap.get(l1.Associated_Contact__c).get(conField)){
                    	l1.put(leadField, newPersonContactMap.get(l1.Associated_Contact__c).get(conField));
                    	toUpdate =true;
                }
            }
            if(toUpdate){
                CTAsToUpdate.add(l1);
                toUpdate = false;
            }
        }
        if(CTAsToUpdate.size() > 0){ 
            LeadToContactConversionClass.updateLeads(CTAsToUpdate);
        }
    }
    
    //MARIT-215
    public static List<Contact> ProjectSDRForPersonContact(List<Contact> contacts){
        Set<Id> accountIds = new Set<Id>();
        for(Contact c : contacts){
            if(c.AccountId != null){
                accountIds.add(c.AccountId);
            }
        }
        String query = 'SELECT Id,Projected_Sales_Owner__c,adg_Projected_Account_Owner__c,Projected_SDR__c from Account WHERE Id in ';
        query+=MarketingUtilClass.parseIdsForDynamicQuery(new List<Id>(accountIds));
        Map<Id,Account> accountsMap = new Map<Id,Account>((List<Account>)MarketingUtilClass.fetchFromDataBase(query));
        for(Contact c : contacts){
            if(c != null && c.AccountId != null){
                Account acc = accountsMap.get(c.AccountId);
                if(acc != null){
                    c.adg_Projected_Account_Owner__c = acc.adg_Projected_Account_Owner__c;
                    c.Projected_SDR__c = acc.Projected_SDR__c; // To populate Projected SDR from account to contact
                }
            }
        }
        System.debug('No of records with populated/updated PSO for person contact:'+contacts.size());
        return contacts;
    }

    //MARIT-1014
    public static void checkIfOpenOppExistsWhileInsertingCTA(Map<Id,Lead> ctaWithC){
        if(ctaWithC != null && !ctaWithC.isEmpty()){
            Set<Id> contactIdsWithOpenOpp = MARIT_ContactUtilClass.checkContactOpenOppt(new List<Id>(ctaWithC.keySet()), 'Open_Opportunity_Stage_Name'); //MARIT-1513
            for(Id id : contactIdsWithOpenOpp){
                Lead l = ctaWithC.get(id);
                l.AddError('Open Opportunity exists on the Person');
            }
        }
    }
    
}