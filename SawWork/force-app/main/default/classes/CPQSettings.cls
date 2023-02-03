/**
* This class is used to fetch and parse cpq custom settings and cpq custom metadata into diffrent data structures
* @author  Kirti Mishra
* @version 1.0
* @since   2020-11-04
*/

public class CPQSettings {
    
    @AuraEnabled(cacheable=true)
    public static String getValue(String settingName)
    {
        CPQ_Generic_Settings__c settingRecord = [SELECT Id, CPQ_Value__c,CPQ_Active__c
                                                 FROM CPQ_Generic_Settings__c
                                                 WHERE Name = :settingName LIMIT 1];
        if (settingRecord.CPQ_Active__c) {
            return settingRecord.CPQ_Value__c;
        }
        
        return null;
    }
    
    public static Set<String> getValues(String settingName)
    {
        Set<String> valueSet = new Set<String>();
        String devName = ''+settingName+'%';
        for(CPQ_Generic_Settings__c cs : [SELECT Id, CPQ_Value__c
                                          FROM CPQ_Generic_Settings__c
                                          WHERE Name LIKE :devName])
        {
            List<String> vals = cs.CPQ_Value__c.split('\\s*,\\s*');
            valueSet.addAll(vals);
        }
        
        return valueSet;
    }
    
    public static Integer getInt(String developerName)
    {
        return Integer.valueOf(getValue(developerName));
    }
    
    public static boolean getBoolean(String developerName)
    {
        return Boolean.valueOf(getValue(developerName));
    }
    
    public static Boolean contains(String developerName, String strToMatch)
    {
        if(String.isBlank(strToMatch))
            return false;
        
        Set<String> sset = getSet(developerName);
        return sset.contains(strToMatch);
        
    }
    
    public static Set<String> getSet(String developerName)
    {
        Set<String> setOfStrings = new Set<String>();
        setOfStrings.addAll(getValue(developerName).split('\\s*,\\s*'));
        return setOfStrings;
    }

    public static Map<String, Object> getValueMap(String settingName)
    {
        Map<String, Object> valueMap = new Map<String, Object>();
        CPQ_Generic_Settings__c settingRecord = [SELECT Id, CPQ_Value__c,CPQ_Active__c
                                                 FROM CPQ_Generic_Settings__c
                                                 WHERE Name = :settingName LIMIT 1];
        if (settingRecord.CPQ_Active__c) {
            valueMap = (Map<String, Object>)JSON.deserializeUntyped(settingRecord.CPQ_Value__c);
            return valueMap;
        }
        
        return null;
    }

    public static String getMetadataValue(String settingName)
    {
        CPQ_Setting__mdt settingRecord = [SELECT Id, CPQ_Value__c,
                                                 CPQ_Active__c
                                                 FROM CPQ_Setting__mdt
                                                 WHERE MasterLabel = :settingName LIMIT 1];
        if (settingRecord.CPQ_Active__c) {
            return settingRecord.CPQ_Value__c;
        }
        
        return null;
    }

    public static Map<String, Object> getMetadataValueMap(String settingName)
    {
        Map<String, Object> valueMap = new Map<String, Object>();
        CPQ_Setting__mdt settingRecord = [SELECT Id, CPQ_Value__c
                                                 FROM CPQ_Setting__mdt
                                                 WHERE MasterLabel = :settingName 
                                                 AND CPQ_Active__c =  TRUE LIMIT 1];
        if (settingRecord != null) {
            valueMap = (Map<String, Object>)JSON.deserializeUntyped(settingRecord.CPQ_Value__c);
            return valueMap;
        }
        
        return null;
    }

    public static Set<String> getMetadataValues(String settingName)
    {
        Set<String> valueSet = new Set<String>();
        String devName = ''+settingName+'%';
        for(CPQ_Setting__mdt md : [SELECT Id, CPQ_Value__c, CPQ_Active__c
                                          FROM CPQ_Setting__mdt
                                          WHERE MasterLabel LIKE :devName AND CPQ_Active__c = true])
        {
            List<String> vals = md.CPQ_Value__c.split('\\s*,\\s*');
            valueSet.addAll(vals);
        }
        
        return valueSet;
    }
    public static Boolean getBooleanValue(String settingName)
    {
        CPQ_Setting__mdt settingRecord = [SELECT Id, CPQ_Value__c,
                                                 CPQ_Active__c
                                                 FROM CPQ_Setting__mdt
                                                 WHERE MasterLabel = :settingName LIMIT 1];
        if (settingRecord.CPQ_Active__c) {
            return settingRecord.CPQ_Active__c;
        }
        
        return false;
    }
}