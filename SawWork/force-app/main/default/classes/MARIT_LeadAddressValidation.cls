/*
    As part of MARIT-685 and MARIT-671
    Mimicking Address Validation present on contact/account on lead
    For More details refer: AddressValidationClass.cls and SFDC-2304
*/
public class MARIT_LeadAddressValidation {
    public static Boolean leadAddressValidationPerformed = false;
    public static Map<String,Country_List__mdt> countryMap = new Map<String,Country_List__mdt>();
    public static Map<String,State_List__mdt> stateMap = new Map<String,State_List__mdt>();
    public static String allEmptyAddressError = MarketingUtilClass.getMarketingSettingsValue('Lead_Empty_Validation_Error');
    public static String countryMandatoryError = GsmUtilClass.getGSMSettingValue('Country_Error');
    public static String streetLineLimitError = GsmUtilClass.getGSMSettingValue('Street_lines_error');
    public static String validCountryError = GsmUtilClass.getGSMSettingValue('Country_Error_USA');
    public static String stateMandatoryError = GsmUtilClass.getGSMSettingValue('country_valid_error');
    public static String stateEmptyError = GsmUtilClass.getGSMSettingValue('State_Mandatory_error');
    public static String TBD = GsmUtilClass.getGSMSettingValue('TBD');
    public static String profileExceptions =  GsmUtilClass.getGSMSettingValue('Profile_Exceptions');

  /*
    countryMap holds list of countries and state validation to be done/not. [USA/India/Canada needs state validation]
    stateMap hold state to associated country info
  */
    public static void GetCountryMap(Set<String> p_Countries,Set<String> p_States){
      for(Country_List__mdt c : [Select Label, Id, Check_State__c From Country_List__mdt where Country_Name__c IN :p_Countries])
          countryMap.put(c.Label.toLowerCase(),c);

      for(State_List__mdt s : [Select Label, Id, Associated_Country__c From State_List__mdt where Label IN :p_States])
          stateMap.put(s.Label.toLowerCase()+':'+s.Associated_Country__c.toLowerCase(), s);
    }
  /*
    Address Validations on lead for fields country, state, city, street, postalcode
  */
    public static String[] ValidateAddress(String p_Country,String p_State,String p_City,String p_Street,String p_PostalCode){                 
        List<String> error_list = new List<String>();   
        // Address is empty.
        if(p_Country == null && p_City == null && p_State == null && p_Street == null && p_PostalCode==null)
        {
            error_list.add('All:EMPTY');
            return error_list;
        }                
        // Country field should not be NULL if any other field is filled. 
        // Country field is mandatory. Please review "List of valid countries and states" link under FAQ.       
        if(p_Country == null && !(p_City == null && p_State == null && p_Street == null && p_PostalCode==null)){
            error_list.add('COUNTRY:'+countryMandatoryError);
        }
        //street should have only less <= 3 lines
        //Street field can accept a maximum of 3 lines.
        if(p_Street != null)
        {
            if(p_Street.split('\r\n').size()>3){
                error_list.add('STREET:'+streetLineLimitError);
            }          
        }
        // The country should be a valid from the list of maintained countries
        // check for valid country and state
        if(p_country!=null && p_country != 'TBD')
        {
            Country_List__mdt country = countryMap.get(p_Country.toLowerCase());
            //Please enter a valid country. Please review "List of valid countries and states" link under FAQ.
            if(country == null){
                error_list.add('COUNTRY:'+validCountryError);
            }
            /* MARIT-1598
            else 
            {
                if(country.Check_State__c == true)
                {
                    // Within the selected country, if 'CheckState checkbox is checked, then a valid state should be entered.
                    if(p_State!=null)
                    {
                        State_List__mdt state = stateMap.get(p_State.toLowerCase()+':'+p_Country.toLowerCase());
                        //Please enter a valid state for the selected country. Please review "List of valid countries and states" link under FAQ.
                        if(state == null){
                            error_list.add('STATE:'+stateMandatoryError); 
                        }     
                    }
                    else{
                        //State is mandatory for the selected Country. Please review "List of valid countries and states" link under FAQ.
                        error_list.add('STATE:'+stateEmptyError);
                    } 
                }
            }*/
        }
        return error_list;          
    }
    /**
    - This method takes in a Country String and converts it to a standard Format
    - Example of the format; if country parameter is 'iNDIa'; return will be of format - 'India'
    - Exception to this rule is USA and UK and TBD
    */
    public static String formatCountry(String country)
    {
        String formattedCountry='';
        country=country.trim();
        String tempCountry = country.toUpperCase(); 
        
        if (tempCountry.indexof('USA') > -1 || tempCountry.equals('UK') || tempCountry.equals('TBD'))
            return tempCountry;
        
        List<String> countryWords = tempCountry.split('\\s');
        String firstLetter;
        String restOfTheWord;
        for (String c : countryWords)
        {       
            firstLetter = c.substring(0, 1);
            if (firstLetter.indexof('(')>-1)
            {
                firstLetter = c.substring(0,2);
                restOfTheWord = c.substring(2);                 
            }
            else
                restOfTheWord = c.substring(1);
            if (formattedCountry=='')
                formattedCountry = (firstLetter.toUpperCase() + restOfTheWord.toLowerCase());
            else
                formattedCountry += ' ' + (firstLetter.toUpperCase() + restOfTheWord.toLowerCase()); 
        }
        return formattedCountry;
    }

    //Lead Address Validation and lead email address duplication check on contact
    public static void validateLeadAddressFields(Set<Lead> leads,Map<Id,Boolean> relatedRecordAddressCheck){
        if(leadAddressValidationPerformed)
            return;
        
        // List of Profiles that override Address validation
        Boolean profileOverride = false;
        String currentProfile = Userinfo.getProfileId();    
        // Take only the first 15 chars of the Profile Id
        currentProfile = currentProfile.substring(0, 15);
        System.debug('Profile ID = '+currentProfile);
        if(profileExceptions.contains(currentProfile))
            return;
        
        Set<String> countriesSet = new Set<String>();
        Set<String> statesSet = new Set<String>();
        Set<Id> leadsIdsForRelatedAddressCheck = new Set<Id>();
        Map<Id,Lead> leadsWithRelatedRecordAddress = new Map<Id,Lead>();
        Map<String,Lead> leadsToCheckEmails = new Map<String,Lead>();//MARIT-987
        for(Id leadId : relatedRecordAddressCheck.keySet()){
            if(relatedRecordAddressCheck.get(leadId)){
                leadsIdsForRelatedAddressCheck.add(leadId);
            }
        }
        //get marketo lead address and its associated account during conversion process
        if(!leadsIdsForRelatedAddressCheck.isEmpty()){
            String soql = 'SELECT Id,Parent_Lead__c,Parent_Lead__r.Email,Parent_lead__r.Address_Check_Status__c,Parent_lead__r.Address,Parent_lead__r.Country,Parent_lead__r.State,Parent_lead__r.City,Parent_lead__r.Street,Parent_lead__r.PostalCode,Associated_Account__r.BillingCountry,Associated_Account__r.BillingState,Associated_Account__r.BillingCity,Associated_Account__r.BillingStreet,Associated_Account__r.BillingPostalCode from lead where Id in ';
            soql+=MarketingUtilClass.parseIdsForDynamicQuery(new List<Id>(leadsIdsForRelatedAddressCheck));
            soql+=' and Parent_lead__r.ConvertedContactId = null'; //check for only non converted marketo leads 
            leadsWithRelatedRecordAddress = new Map<Id,Lead>((List<Lead>)MarketingUtilClass.fetchFromDataBase(soql));
        }
        
        //getting country and state mappings
        for(Lead l : leads)
        {              
            if(!l.Validation_Override__c){
                //During non conversion, this will be executed
                if(!relatedRecordAddressCheck.get(l.Id)){
                    if(l.Country != null){
                        if(l.Country == 'United States' || l.Country == 'United States of America') {
                            l.Country = 'USA';
                        }
                        l.Country = formatCountry(l.Country);
                        countriesSet.add(l.Country.toUpperCase());
                    } 
                    if(l.State != null)
                        statesSet.add(l.State.toUpperCase());
                }
                else{
                    //during conversion check on marketo leads address if not empty. If empty check on account address fields
                    //SFDC OOB connversion will check first marketo lead address fields, if not present it copies from account to contact
                    Lead akamaiLead = leadsWithRelatedRecordAddress.get(l.Id);
                    if(akamaiLead != null && akamaiLead.Parent_lead__r.Address != null && !akamaiLead.Parent_lead__r.Address_Check_Status__c){
                        if(akamaiLead.Parent_lead__r.Country != null){
                            countriesSet.add(akamaiLead.Parent_lead__r.Country);
                        }
                        if(akamaiLead.Parent_lead__r.State != null){
                            statesSet.add(akamaiLead.Parent_lead__r.State);
                        }   
                    }
                    else if(akamaiLead != null && akamaiLead.Parent_lead__r.Address == null){
                        if(akamaiLead.Associated_Account__r.BillingCountry != null){
                            countriesSet.add(akamaiLead.Associated_Account__r.BillingCountry);
                        }
                        if(akamaiLead.Associated_Account__r.BillingState != null){
                            statesSet.add(akamaiLead.Associated_Account__r.BillingState);
                        }
                    }  
                }
            }    
        }
        GetCountryMap(countriesSet,statesSet);   
        for(Lead l : leads)
        {   
            if(l.Validation_Override__c == true){
                continue;
            }
            List<String> error_list = new List<String>();
            //Lead Address field check
            //During non conversion, this will be executed
            if(!relatedRecordAddressCheck.get(l.Id)){
                l.Street = l.Street == null?TBD:l.Street;
                l.City = l.City == null?TBD:l.City;
                System.debug('Address C2A Lead='+l.Country+' '+l.State+' '+l.City+' '+l.Street+' '+l.PostalCode);
                error_list = ValidateAddress(l.Country,l.State,l.City,l.Street,l.PostalCode);
                l.Address_Check_Status__c = error_list.isEmpty();
            }
            else{
                //during conversion check on marketo leads address if not empty. If empty check on account address fields
                //SFDC OOB connversion will check first marketo lead address fields, if not present it copies from account to contact
                //Address_Check_Status__c will hold whether that lead address was previously validated or not. Its sent to validation only when its false
                Lead akamaiLead = leadsWithRelatedRecordAddress.get(l.Id);
                if(akamaiLead != null){
                    if(akamaiLead.Parent_lead__r.Address != null && !akamaiLead.Parent_lead__r.Address_Check_Status__c){
                        System.debug(logginglevel.DEBUG,'Address Marketo Lead='+akamaiLead.Parent_lead__r.Country+' '+akamaiLead.Parent_lead__r.State+' '+akamaiLead.Parent_lead__r.City+' '+akamaiLead.Parent_lead__r.Street+' '+akamaiLead.Parent_lead__r.PostalCode);
                        error_list = ValidateAddress(akamaiLead.Parent_lead__r.Country,akamaiLead.Parent_lead__r.State,akamaiLead.Parent_lead__r.City,akamaiLead.Parent_lead__r.Street,akamaiLead.Parent_lead__r.PostalCode);
                    }
                    else if(akamaiLead.Parent_lead__r.Address == null){
                        System.debug(logginglevel.DEBUG,'Address Account='+akamaiLead.Associated_Account__r.BillingCountry+' '+akamaiLead.Associated_Account__r.BillingState+' '+akamaiLead.Associated_Account__r.BillingCity+' '+akamaiLead.Associated_Account__r.BillingStreet+' '+akamaiLead.Associated_Account__r.BillingPostalCode);
                        error_list = ValidateAddress(akamaiLead.Associated_Account__r.BillingCountry,akamaiLead.Associated_Account__r.BillingState,akamaiLead.Associated_Account__r.BillingCity,akamaiLead.Associated_Account__r.BillingStreet,akamaiLead.Associated_Account__r.BillingPostalCode);
                    }

                    if(akamaiLead.Parent_Lead__c != null && akamaiLead.Parent_Lead__r.Email != null){
                        leadsToCheckEmails.put(akamaiLead.Parent_Lead__r.Email,l);
                    }
                }
            }
            String[] field_error = new String[2];
            for(String error:error_list)
            {
                field_error = error.split(':');
                //Country is required for Lead Address. Please review "List of valid countries and states" link under FAQ.
                if(field_error[0]=='ALL'){
                    l.addError(allEmptyAddressError);
                }               
                else
                {
                    if(field_error[0]=='STREET')
                        l.Street.addError(field_error[1]);
                    if(field_error[0]=='STATE')
                        l.State.addError(field_error[1]);          
                    if(field_error[0]=='COUNTRY')
                        l.Country.addError(field_error[1]);
                }
            }             
        }    
        leadAddressValidationPerformed = true;
        //check no existing contact has marketo lead address
        if(leadsToCheckEmails != null && !leadsToCheckEmails.isEmpty()){
            MARIT_LeadTriggerClass.checkContactExists(leadsToCheckEmails);
        }  
    }
}