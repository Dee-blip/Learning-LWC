/*
Created as part of MARIT-1071
Add general functions here for contact and lead object that can be called from lead and contact trigger classes
*/
public without sharing class MARIT_LeadContactUtils {

    public static Map<string, Country_List__mdt> countryToCodeMapping = new Map<string, Country_List__mdt>();
    public static Map<String, Object> phoneFields = new Map<String, Object>();
    public static Set <String> phoneFieldSet = new Set<String>();

    public static void personAcquistionCampaign(Map<String,List<SObject>> acquistionProgramToPersonMap, Set<String> acquistionProgramNames, Set<String> acquistionProgramAkamIds){
        //MARIT-1081, map person record to campaign based on Acquistion Program Name
        List<SObject> persons = null;
        System.debug(logginglevel.DEBUG,'Acquisition Program='+acquistionProgramToPersonMap.keySet());
        for(Campaign record: [select Id,Name,Akam_Campaign_Id__c from Campaign where Name in :acquistionProgramNames and Akam_Campaign_Id__c like :acquistionProgramAkamIds]){
            persons = (List<SObject>)acquistionProgramToPersonMap.get(record.Name + record.Akam_Campaign_Id__c.replaceAll('[^0-9]', ''));
            if(persons != null){
                for(SObject person : persons){
                    person.put('Acquisition_Campaign_Id__c',record.Id);
                }
            }
        }
    }

    // validate the phone number
    public static void validatePhoneNumber(String phoneNumber,String countryCode,Integer snc,Integer maxSnc, List<String> phoneNumberList,Map<Boolean, String> invalidReason) {
        //E.164 phone numbers length is not greater than 15
        if(phoneNumber != null && phoneNumber.length() > 15 || phoneNumber.length() == 0) {
            invalidReason.put(false,'Invalid phone number : Length > 15 or 0');
            return;
        }
         
        //Invalid phone numbers with single recurring digits
        Set<String> setChars = new Set<String>();
        for(String str : phoneNumber.split('')) {
            setChars.add(str);
        }
        if(setChars.size() == 1) {
            invalidReason.put(false,'Invalid phone number : Single recurring digit');
            return;
        }
         
        //Validate the phone number based on subscriber number count
        String subscriberNumber = phoneNumber;
        if(phoneNumber.startsWith(countryCode)) {
            System.debug(logginglevel.DEBUG,'starts with country code: '+phoneNumber);
            subscriberNumber = phoneNumber.substring(countryCode.length());
        } 
        //the subscriber number count of phone number should be >=snc <=max_snc if  max_snc is null it should be equal to snc
        if(!((maxSnc == null && subscriberNumber != null && subscriberNumber.length() == snc) || (maxSnc != null && subscriberNumber != null && subscriberNumber.length() >= snc && subscriberNumber.length() <= maxSnc))) {
            //the subscriber number count can start with country code if country code is part of the subscriber number we need to append country code
            if(!(phoneNumber.startsWith(countryCode) && ((maxSnc == null && phoneNumber != null && phoneNumber.length() == snc) || (maxSnc != null && phoneNumber != null && phoneNumber.length() >= snc && phoneNumber.length() <= maxSnc)))) {
                invalidReason.put(false,'Doesnt meet number count requirement or Country code doesnt match with assigned country.');
                return;
            } else {
                phoneNumberList[0] = countryCode + phoneNumber;
                System.debug(logginglevel.DEBUG,'Phone number if with country code matches snc count :' +phoneNumberList[0]);
            }
        } 
        invalidReason.put(true,'');
        return;
    }

    //E.164 phone starts with a + , followed by country code and then the valid phone number
    public static string phoneformatting(string phoneNumber, String countryCode) {  
         if(!phoneNumber.startsWith(countryCode)) {
             phoneNumber = countryCode + phoneNumber;
         }
         phoneNumber = '+' + phoneNumber;
         return phoneNumber;
    }

    //keep only numeric characters in extension
    public static string extensionformatting(List<String> numbers) {  
         for(Integer i=0; i < numbers.size(); i++) {
             numbers[i] = numbers[i].replaceAll('[a-z.]','');
         }
         return String.join(numbers, ',' );
    } 

    //currently this method is invoked for both lead and contact
    public static void e164PhoneNumberformatting(List<SObject> objects, String countryFieldName) {
        String phone;
        String country;
        String countryCode;
        String extension;
        String phoneNumber;
        String formattingError;
        String intlFieldName;
        String intlFieldExtension;
        Country_List__mdt countryList;
        Integer snc;
        Integer maxSnc;
        List<String> numbers;
        Boolean hasExtension;
        Map<Boolean, String> invalidReason = new Map<Boolean, String>();
        List<String> phoneNumberList = new List<String>();
        Map<String, Object> phoneFieldMapping;

                
        try {
            countryToCodeMapping = new Map<String, Country_List__mdt>();
            //create a map of country and country metadata(country code/subscriber number count/subscriber number max count)
            for(Country_List__mdt cl: [Select Id,Country_Name__c,country_code__c,subscriber_number_count__c,subscriber_number_max_count__c  From Country_List__mdt where Country_Name__c != 'TBD']) {
                countryToCodeMapping.put(cl.Country_Name__c.toLowerCase(),cl);
            }

            //A map of phone field and corresponding e164 phone /ext field
            phoneFields = (Map<String, Object>)JSON.deserializeUntyped(MarketingUtilClass.getMarketingSettingVerboseValue('E164_Phone'));
            //Phonelist which needs to be converted to E.164
            phoneFieldSet = phoneFields.keySet();
        
            for(SObject obj:objects) {
                country = ((String) obj.get(countryFieldName)).toLowerCase();
                countryList = (String.isBlank(country) || country == 'TBD') ? null : countryToCodeMapping.get(country);
                formattingError = '';
                try {
                    for(String phoneFieldName:phoneFieldSet) {
                        phoneNumberList.clear();
                        invalidReason.clear();
                        phone = (String) obj.get(phoneFieldName);
                        System.debug(logginglevel.DEBUG,phoneFieldName+' value:' + phone);
                        //Getting the corresponding phone and extension field mapping
                        phoneFieldMapping = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(phoneFields.get(phoneFieldName)));
                        intlFieldName = (String) phoneFieldMapping.get('field');
                        intlFieldExtension = (String) phoneFieldMapping.get('extension');
                        System.debug(logginglevel.DEBUG,'Field being updated :' + intlFieldName + ' ' + intlFieldExtension);

                        if(intlFieldName == null || intlFieldExtension == null) {
                            return;
                        }

                        //Phone is null need to remove the e164 values
                        if(String.isBlank(phone)) {
                            obj.put(intlFieldName,null);
                            obj.put(intlFieldExtension,null);
                            continue;
                        }
                        
                        //If country is TBD or blank remove the e164 values
                        if(String.isBlank(country) || country == 'TBD') {
                            obj.put(intlFieldName,null);
                            obj.put(intlFieldExtension,null);
                            formattingError = country == 'TBD' ?'Country is TBD':'Country is blank';
                            continue;
                        }
                        
                        //If country is not present in the metadata ignore
                        if(countryList == null) {
                            obj.put(intlFieldName,null);
                            obj.put(intlFieldExtension,null);
                            formattingError = 'Not a valid Country';
                            continue;
                        }
                        
                        countryCode = String.valueOf(Integer.valueOf(countryList.country_code__c));
                        snc = Integer.valueOf(countryList.subscriber_number_count__c);
                        maxSnc = Integer.valueOf(countryList.subscriber_number_max_count__c);
                        
                        //If country is has no country code or subscriber number count ignore
                        if(String.isBlank(countryCode) || snc == null) {
                            obj.put(intlFieldName,null);
                            obj.put(intlFieldExtension,null);
                            formattingError = snc == null ? 'Country doesnt have a subcriber number count updated' :  'Country doesnt have a country code updated';
                            continue;
                        }
                        
                        numbers = phone.toLowercase().split('x');
                        if(numbers.size() == 0) {
                            obj.put(intlFieldName,null);
                            obj.put(intlFieldExtension,null);
                            formattingError = 'Not a valid Phone number';
                            continue;
                        }
                        //Remove the first number i.e phone number and leading 0 and non numeric characters from it
                        phoneNumber = numbers.remove(0).replaceAll('[^0-9]','').replaceFirst('^0+', '');
                        System.debug(logginglevel.DEBUG,'Numeric phone number : ' + phoneNumber);
                        phoneNumberList.add(phoneNumber);
                        //validate the phone number
                        validatePhoneNumber(phoneNumber,countryCode,snc,maxSnc,phoneNumberList,invalidReason);
                        phoneNumber = phoneNumberList[0];
                        System.debug(logginglevel.DEBUG,'Phone number post validation:' +phoneNumber);
                        System.debug(logginglevel.DEBUG,'invalidReason:' +invalidReason.get(false));
                        System.debug(logginglevel.DEBUG,'not invalid:' +invalidReason.get(true));
                        //If invalid remove the e164 phone and update the error on record
                        if(invalidReason.get(false) != null) {
                            obj.put(intlFieldName,null);
                            obj.put(intlFieldExtension,null);
                            formattingError += ' ' + phoneFieldName + ' : ' + invalidReason.get(false);
                        } else {
                            phoneNumber = phoneformatting(phoneNumber,countryCode);
                            System.debug(logginglevel.DEBUG,'Phone number post formatting:' +phoneNumber);
                            obj.put(intlFieldName,phoneNumber);
                            hasExtension =  numbers.isEmpty() ? false : true;
                            if(hasExtension) {
                                extension = extensionformatting(numbers);
                                obj.put(intlFieldExtension,extension);
                            } else {
                                obj.put(intlFieldExtension,null);
                            }
                        }
                    }
                    if(!String.isBlank(formattingError)) {
                        obj.put('Phone_Formatting_error__c',formattingError);
                    } else {
                        obj.put('Phone_Formatting_error__c',null);
                    }
                } catch(Exception ex) {
                    System.debug(LoggingLevel.ERROR,'Exception while phone formatting : ' + ex.getMessage());
                    Error_Log__c el = new Error_Log__c(Name='e164PhoneNumberformatting', Class__c='MARIT_LeadContactUtils', Error_Message__c=ex.getMessage(), RecordId__c= (string) obj.get('Id'));
                    insert el; 
                }    
            }     
        } catch(Exception ex) {
            System.debug(LoggingLevel.ERROR,'Exception while phone formatting : ' + ex.getMessage());
            Error_Log__c el = new Error_Log__c(Name='e164PhoneNumberformatting', Class__c='MARIT_LeadContactUtils', Error_Message__c=ex.getMessage(), RecordId__c= (string) objects[0].get('Id'));
            insert el; 
        }  
    }
}