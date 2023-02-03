//Created by Mayank Bansal as part of MARIT-655
//This class implements transactional and non-transactional caching
public class MARIT_DataClass{
    
    public static Map<String, List<Sobject>> queryToRecordsMap = new Map<String, List<Sobject>>();
    
    public MARIT_DataClass(){
    }
    
    //Method to fetch transactional data from either database layer or L1 cache
    /*params: query: literal string which will be used to query to DB as well as Key to the L1 Cache
              checkCacheFirst: takes boolean value which will let method know whether it has to Cache the data or not
              classAndMethodName: from which Class and method below method has been called
    */
    public static List<Sobject> getTransactionalData(String query, Boolean checkCacheFirst, String classAndMethodName){

        List<Sobject> sobjectList = new List<Sobject>();
        System.debug('Mayank, classAndMethodName: '+classAndMethodName + ':' +query);
        
        if(queryToRecordsMap.containsKey(query) && checkCacheFirst){
            System.debug('Mayank, fetching from L1 Cache: '+ query);
            return queryToRecordsMap.get(query);
        } else {
            System.debug('Mayank, Querying DB: '+ query);
            sobjectList = Database.query(query);
            
            if(checkCacheFirst){
                queryToRecordsMap.put(query, sobjectList);
            }
            return sobjectList;
        }
    }
    
    //Method to fetch non-transactional data from either database layer or Salesforce platform cache
    /*params: query: literal string which will be used to query to DB as well as Key to the platform Cache
              cacheKeyName: key name to be used while saving into platform cache
              checkCacheFirst: takes boolean value which will let method know whether it has to Cache the data or not
              classAndMethodName: from which Class and method below method has been called
    */
    public static List<Sobject> getNonTransactionalData(String query, String cacheKeyName, Boolean checkCacheFirst, String classAndMethodName){

        List<Sobject> sobjectList = new List<Sobject>();
		cacheKeyName = 'local.Org.' + cacheKeyName;
        System.debug('Mayank, classAndMethodName: '+classAndMethodName + ':' +query);
        
        if(Cache.Org.contains(cacheKeyName) && checkCacheFirst){
            System.debug('Mayank, fetching from Org Cache: '+ query);
            return (List<Sobject>)Cache.Org.get(cacheKeyName);
        }else{
            System.debug('Mayank, Querying DB: '+ query);
            sobjectList = Database.query(query);
            
            if(checkCacheFirst && cacheKeyName != null){
                Cache.Org.put(cacheKeyName, sobjectList);
            }
            return sobjectList;
        }
    }
    
    //Method to fetch clear cache
    /*params: query: literal string which will be used to clear data from L1 Cache
              cacheKeyName: key name to be used while clearing platform cache
              classAndMethodName: from which Class and method below method has been called
    */
    public static void clearCache(String query, String cacheKeyName, String classAndMethodName){
        
        cacheKeyName = 'local.Org.' + cacheKeyName;
        System.debug('Mayank, classAndMethodName: '+classAndMethodName + ':' +query+ ',' + cacheKeyName);
        
        if(query != null && queryToRecordsMap.containsKey(query)){
            queryToRecordsMap.remove(query);
        }

        if(cacheKeyName != null && Cache.Org.contains(cacheKeyName)){
            Cache.Org.remove(cacheKeyName);
        }
    }
}