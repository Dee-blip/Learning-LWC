/*
 * Create By Mayank Bansal on 22nd Aug,19 as part of MARIT-5
 * Will be used to fetch data from Marketing Custom metadatas
 * Please write generic methods
 */
public class MarketingUtilClass {

	public static String getMarketingSettingsValue(String developerName)
    {
        List<Marketing_Settings__mdt> mdtRecord = [select Id, Value__c from Marketing_Settings__mdt where DeveloperName = :developerName];
        if(mdtRecord.size() > 0)
            return mdtRecord[0].Value__c;
        else
            return null;
    }

    public static String getMarketingSettingVerboseValue(String developerName)
    {
        List<Marketing_Setting_Verbose__mdt> mdtRecord = [select Id, Value__c from Marketing_Setting_Verbose__mdt where DeveloperName = :developerName];
        if(mdtRecord.size() > 0)
            return mdtRecord[0].Value__c;
        else
            return null;
    }
    
    //MARIT-67
    public static List<String> getMarketingSettingValuePartialMatch(String developerName)
    {
        String query = 'select Id, Value__c, DeveloperName from Marketing_Settings__mdt where DeveloperName like \'%'+developerName+'%\' order by DeveloperName';
        List<Marketing_Settings__mdt> mdtRecords = Database.query(query);
        List<String> mdtRecordList = new List<String>();
        for(Marketing_Settings__mdt mdtRecord : mdtRecords){
            mdtRecordList.add(mdtRecord.Value__c);
        }

        return mdtRecordList;
    }
    
    //MARIT-306
    public static Map<String, String> getGSMSettingValueForMultiples(List<String> developerNames)
    {  
        Map<String, String> devToValueMap = new Map<String, String>();
        for(String str: developerNames){
            devToValueMap.put(str, null);
        }
        System.debug('Mayank, getGSMSettingValueForMultiples developerName :'+ developerNames);
        List<GSM_Settings__mdt> mdtRecords = [select Id, DeveloperName, Value__c from GSM_Settings__mdt where DeveloperName in :developerNames];
        if(mdtRecords.size() > 0){
            
            for(GSM_Settings__mdt mdt: mdtRecords){
                devToValueMap.put(mdt.DeveloperName, mdt.Value__c);
            }
        }
        return devToValueMap;
    }
    
    //MARIT-306
    public static Map<String, Set<String>> getGSMSettingSetValuesForMultiples(List<String> developerNames)
    {  
        Map<String, Set<String>> devToValueMap = new Map<String, Set<String>>();
        for(String str: developerNames){
            devToValueMap.put(str, null);
        }
        System.debug('Mayank, getGSMSettingValueForMultiples developerName :'+ developerNames);
        List<GSM_Settings__mdt> mdtRecords = [select Id, DeveloperName, Value__c from GSM_Settings__mdt where DeveloperName in :developerNames];
        if(mdtRecords.size() > 0){
            
            for(GSM_Settings__mdt mdt: mdtRecords){
                Set<String> setOfStrings = new Set<String>();
                setOfStrings.addAll(mdt.Value__c.split('\\s*,\\s*'));
                devToValueMap.put(mdt.DeveloperName, setOfStrings);
            }
        }
        return devToValueMap;
    }

    //MARIT-421
    public static Integer getInt(String developerName)
    {
        return Integer.valueOf(getMarketingSettingsValue(developerName));
    }
    
    //MARIT-418
    public static Map<String, LeanData__mdt> getLeanDataValueForMultiples(List<String> developerNames)
    {  
        Map<String, LeanData__mdt> devToValueMap = new Map<String, LeanData__mdt>();
        for(String str: developerNames){
            devToValueMap.put(str, null);
        }
        List<LeanData__mdt> mdtRecords = [select Id, DeveloperName, ToBeChecked__c, Value__c, Reporting_Matched_Account_Status__c from LeanData__mdt where DeveloperName in :developerNames];
        if(mdtRecords.size() > 0){
            
            for(LeanData__mdt mdt: mdtRecords){
                devToValueMap.put(mdt.DeveloperName, mdt);
            }
        }
        return devToValueMap;
    }
    
    //MARIT-475 Will be useful once we implement caching mech.
    public static List<Sobject> fetchFromDataBase(String query){
        return Database.Query(query);
    }

    //MARIT-475 Below three methods will be required for creating filters for dynamic queires, if not using as part of this release then comment. DONOT DELETE
    public static String parseObjectsForDynamicQuery(List<Sobject> objList, String fieldName){

        String str = '(';

        for(sObject obj: objList){

            if(str == null){
                str = '\'' + obj.get(fieldName) + '\'';
            } else{
                str += ', \'' + obj.get(fieldName) + '\'';
            }

        }
        
        str += ')';
        return str;
    }

    public static String parseIdsForDynamicQuery(List<Id> idList){

        String str = null;
        
        for(Id id: idList){

            if(str == null){
                str = '(\'' + id + '\'';
            } else{
                str += ', \'' + id + '\'';
            }

        }

        str += ')';
        return str;
    }

     //MARIT-475
    public static String parseStringsForDynamicQuery(List<String> strList){

        String str = null;
        
        for(String str1: strList){

            if(str == null){
                str = '(' +'\'' + str1 + '\'';
            } else{
                str += ', \'' + str1 + '\'';
            }

        }

        str += ')';
        return str;
    }
    
    //MARIT-539
    public static String parseDateTimeForDynamicQuery(Datetime dateValue){
        String str = dateValue.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSXXX');
        return str;
    }

    // MARIT-487
    // Function to Compare incoming object with list of updates already present for given object.
    // Use this method to add to an update Map and call a single update statement. 
    // Reduce the number of DML statement usage across functions.
    public static Map<String,sObject> mergeUpdates(Map<String,sObject> m, List<sObject> objects)
    {
        // If there are no objects to update, return the existing map
        if ( objects == null || objects.size() == 0)
        {
            return m;
        }
        for( sObject obj : objects)
        {
            // If the incoming update lead is present in the map
            if ( m.containsKey(obj.Id) )
            {
                // Merge the incoming Update with the existing object
                m.put(obj.Id,mergeObjects(m.get(obj.id), obj));
            }
            // If the incoming update lead is new, add it to the map
            else {
                // IF it is a new lead, there will not be ID. Use Last name as key then
                if (obj.get('Id') == null) {
                    m.put(obj.get('lastname').toString(),obj);
                }
                // ELSE when Id is present, use ID
                else {
	                m.put(obj.Id, obj);
                }
            }
        }
        return m;
    }

    // MARIT-487
    // Convention : Add the delta fields to Target and return the Target object
    private static sObject mergeObjects(sObject source, sObject target)
    {
        // If source and target is null , throw error? or return null
        if ( source == null && target == null)
            return null;
        // If source is null return target and if target is null , return source
        else if ( source == null ) return target;
        else if ( target == null ) return source;

        //Get the type of Object eg: Lead, Contact
        sObjectType sourceObjectType = source.getSObjectType();
        sObjectType targetObjectType = target.getSObjectType();

        // Check if both Objects are of same type. If Not , throw error? or return null
        if ( sourceObjectType != targetObjectType )
        {
            return null;
        }

        // Get the Populated fields for the source and Target Objects
        Map<String,Object> sourceObjectFields = source.getPopulatedFieldsAsMap();
        Map<String,Object> targetObjectFields = target.getPopulatedFieldsAsMap();
		
        // Get the list of Populated Field Keys
        Set<String> sourceObjectKeySet = sourceObjectFields.keySet();
		Set<String> targetObjectKeySet = targetObjectFields.keyset();
        
        // Loop through the fields in the Source Object.
        for ( String field : sourceObjectKeySet )
        {
            // If the field from source object is not present in target object, add it to the taget object
            if ( !targetObjectKeySet.contains(field) )
            {
                target.put(field, source.get(field));
            }
        }

        // Returned the modified Target value with the delta fields that were present in source
        return target;
    }
    //MARIT-543, sending emails during errors
    public static void sendEmails(String subject, Exception ex, Set<Id> recordsIds){
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        String body = 'The user is: ' + UserInfo.getUserEmail();
        body+='\nRecordIds='+String.join(new List<Id>(recordsIds),',');
        body+='\n\nExpection:'+ex.getMessage()+',Cause:'+ex.getCause()+',Stack Trace:'+ex.getStackTraceString()+',Line No:'+ex.getLineNumber();
        String[] toAddress = MarketingUtilClass.getMarketingSettingsValue('ErrorsEmailSendList').split(';');
        mail.setToAddresses(toAddress);
        mail.setSubject(subject);
        mail.setPlainTextBody(body);
        Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
    
    //MARIT-787
    public static Boolean checkStringInList(List<String> strList, String str){
        for(String strToCheck: strList){
            if(str.equals(strToCheck)){
                return true;
            }
        }
        return false;
    }

    //MARIT-946 acd sync new phone fields from old fields for lead and contact
    public static void syncNewPhoneFieldsWithOld(List<Lead> leadsToUpdate,List<Contact> contactsToUpdate){
        for(Lead l :  leadsToUpdate){
            l.Phone_Custom__c = l.Phone;
            l.MobilePhone_Custom__c = l.MobilePhone;
        }
        for(Contact c :  contactsToUpdate){
            c.Phone_Custom__c = c.Phone;
            c.MobilePhone_Custom__c = c.MobilePhone;
            c.Assistant_Phone_Custom__c = c.Assistant_Phone__c;
        }
    }
    //MARIT-946 acd sync old phone fields from new fields for lead and contact
    public static void syncOldPhoneFieldsWithNew(List<Lead> leadsToUpdate,List<Contact> contactsToUpdate){
        for(Lead l :  leadsToUpdate){
            l.Phone = l.Phone_Custom__c;
            l.MobilePhone = l.MobilePhone_Custom__c;
        }
        for(Contact c :  contactsToUpdate){
            c.Phone = c.Phone_Custom__c;
            c.MobilePhone = c.MobilePhone_Custom__c;
            c.Assistant_Phone__c = c.Assistant_Phone_Custom__c;    
        }
    }
    //MARIT-946 acd return error message string if the profile is sdr
    public static String phoneEditValidationErrorWhenDNCIsChecked(){
        String phoneEditValidationProfiles = getMarketingSettingsValue('PhoneEditValidationProfiles');
        if(phoneEditValidationProfiles.contains(userInfo.getProfileId())){
            return 'Update to the field cannot be made as the Do Not Call Flag is checked';
        }
        return null;
    }
}