public class NAPSettings {

    public static Map<String, String> getValuesWithPrefix(String prefix)
    {
        Map<String, String> valueMap = new Map<String, String>();
        List<NAP_Settings__mdt> mdts = [select developerName, value__c from NAP_Settings__mdt where developername like :prefix+'%'];
        for(NAP_Settings__mdt mdt: mdts)
        {
            valueMap.put(mdt.developerName.substringAfter(prefix), mdt.Value__c);
        }
        return valueMap;
    }
    
    public static String getValue(String developerName) {
      NAP_Settings__mdt mdtRecord = [select Id, Value__c from NAP_Settings__mdt where DeveloperName =: developerName];
      return mdtRecord.Value__c;
    }
  
    public static Set < String > getValues(String developerName) {
      Set < String > valueSet = new Set < String > ();
      String devName = '' + developerName + '%';
      for (NAP_Settings__mdt mdt: [select id, Value__c from NAP_Settings__mdt where DeveloperName like: devName]) {
        List < String > vals = mdt.Value__c.split('\\s*,\\s*');
        valueSet.addAll(vals);
      }
  
      return valueSet;
    }
    
    //SFDC-7898 - @nadesai
    public static Map < String, String > getValues(List < String > listOfDeveloperNames) {
      Map < String, String > mapOfDeveleoperNamesToValues = new Map < String, String > ();
      for (NAP_Settings__mdt eachMetadata: [SELECT Id, Value__c, DeveloperName FROM NAP_Settings__mdt WHERE DeveloperName =: listOfDeveloperNames]) {
        mapOfDeveleoperNamesToValues.put(eachMetadata.DeveloperName, eachMetadata.Value__c);
      }
      return mapOfDeveleoperNamesToValues;
    }
  
    public static Integer getInt(String developerName) {
      return Integer.valueOf(getValue(developerName));
    }
  
    public static Set < String > getSet(String developerName) {
      Set < String > setOfStrings = new Set < String > ();
      setOfStrings.addAll(getValue(developerName).split('\\s*,\\s*'));
      return setOfStrings;
    }
  
  }