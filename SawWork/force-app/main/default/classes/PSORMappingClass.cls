/**
   History
      
      --Developer       --Date         --Description
      Ruchika sharma    20/11/2017     Created this Class
    
*/
public class PSORMappingClass {
    
     public String contractField, accField,contractAccsField;
    public PSORMappingClass(String conField, String acField,String conAccsField) {
        contractField = conField;
        accField = acField;
        contractAccsField =  conAccsField;
    }
     public static List<PSORMappingClass> parse(String jsonString) {
        Map<String, Object> jsonMap = (Map<String, Object>)JSON.deserializeUntyped(jsonString);
        List<PSORMappingClass> psorList = new List<PSORMappingClass>();
        for(String conField : jsonMap.keySet()){
            String acField = (String)jsonMap.get(conField);
            PSORMappingClass psorMapping = new PSORMappingClass(conField,acField,'Account_Name__r.'+acField);
            psorList.add(psorMapping);
        }
        return psorList;
    }

    public static String allFieldsToQuery(List<PSORMappingClass> psorList){
        String query='';
        for(PSORMappingClass psor: psorList){
            query+=psor.contractField+','+psor.contractAccsField+',';
        }
        system.debug(LoggingLevel.ERROR,'query in PSORMappingClass: '+query);
        return query;
    }

    public static String contractFieldsToQuery(List<PSORMappingClass> psorList){
        String query='';
        for(PSORMappingClass psor: psorList){
            query+=psor.contractField+',';
        }
        system.debug(LoggingLevel.ERROR,'query in PSORMappingClass: '+query);
        return query;
    }

}