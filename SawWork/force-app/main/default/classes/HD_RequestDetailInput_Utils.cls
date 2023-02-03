//this class is a utils class for Request Detail Inputs
public class HD_RequestDetailInput_Utils {
    
    private static Map<ID,String> fidRvalue = new Map<Id,String>();
	private static Map<Id,String> fidObjeMap = new Map<Id,String>();
	private static Map<String,Set<String>> objectMeta = new Map<String,Set<String>>(); 
    public static Boolean firstRun = true;
    //Result0 -> objectApi: Result1(list)
    //Result1 -> Result2[i] (map)
    //Result2[i] -> map<name, sobject> //map
    public static Map<String,Map<String,Sobject>> dataStore = new  Map<String,Map<String,Sobject>>();
    
    //look for lookups
    public static void initializeLookups(List<BMCServiceDesk__SRM_RequestDetailInputs__c> records) {
        for(BMCServiceDesk__SRM_RequestDetailInputs__c input : records){
           if(input.HD_Input_Prompt_Type__c == 'Lookup' && input.HD_Object_Fields__c != null){
               //initialize the data-store
               HD_RequestDetailInput_Utils.initDataStore(input.HD_Object_Api__c , input.HD_Object_Fields__c );
               
               //create a map of fID to its request detail value
               fidRvalue.put(input.BMCServiceDesk__FKFulfillmentInputs__c , input.BMCServiceDesk__Response__c);
               fidObjeMap.put(input.BMCServiceDesk__FKFulfillmentInputs__c, input.HD_Object_Api__c);
           }
       }
    }
    
    public static void manipulateSeekers(List<BMCServiceDesk__SRM_RequestDetailInputs__c> records){
        for(BMCServiceDesk__SRM_RequestDetailInputs__c input : records){
           if(input.HD_Field_Seeker__c  != null && input.HD_Field_Seeker__c != ''){
               if(fidObjeMap.get(input.HD_Parent_Input__c)!=null && 
                  input.HD_Field_Seeker__c!=null && 
                  input.HD_Parent_Input__c!=null &&
                  fidRvalue.get(input.HD_Parent_Input__c)!=null
                 )
               	input.BMCServiceDesk__Response__c = HD_RequestDetailInput_Utils.getInfo(fidObjeMap.get(input.HD_Parent_Input__c) , input.HD_Field_Seeker__c, fidRvalue.get(input.HD_Parent_Input__c) );
           }
       }
    } 
    
    public static void initDataStore(String objectApi, String fieldApis ){
        if(firstRun != true || dataStore.containsKey(objectApi)){  
            return;
        }
        
        //constructing the query
        String query = 'Select '+ String.escapeSingleQuotes(fieldApis) + ' from ' + String.escapeSingleQuotes(objectApi); //cs fix - PRTORES-1581 - shegade
        
        //sobjList contains the list of records
        List<sObject> sobjList = Database.query(query);
        
        
        //create a map of these records 
        Map<String, sObject> objectNameMap = new Map<String, sObject>();
        for(sObject x : sobjList){
            objectNameMap.put((String)x.get('Name'), x);
        }
        
        //update the data store
      	dataStore.put(objectApi,objectNameMap); 
      
    }
    
	
    
    //getting specific data from the dataStore
    public static String getInfo(String objectApi, String field, String name){
        
        

        Map<String, Sobject> recordsListMap = new Map<String, Sobject>();
        
            recordsListMap = dataStore.get(objectApi);
        
            Sobject rec = recordsListMap.get(name);
                
            String  value = (String)rec.get(field);
        	return value;
        
    }
    
    
   

    
    
}