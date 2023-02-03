/***
    PACE_UserSpecificHomepageBaseClass
    @version 1.0
    @author Hitesh Chawda <hchawda@akamai.com> 
    @Description : This base Class is used from controller PACE_UserSpecificHomepageController for returning the Object List based on the Object Name and filter condition
    @History
    --Developer           --Date            --Change
    Hitesh Chawda          09-12-2012       1978984
    
*/
public with sharing class PACE_UserSpecificHomepageBaseClass {
    
    public String userId  ;
    public String profileName ;
    
    
    public PACE_UserSpecificHomepageBaseClass() {
        userId = UserInfo.getUserId() ;
        //getUserProfile();
        
    }
    
    
    public  List<sObject> getObjectList(string objName,String filter,String sortByField) {

        String fieldnames = '';
        List<sObject> objList;
        try {
            Map < String, Schema.SObjectType > m = Schema.getGlobalDescribe();
            Schema.SObjectType s = m.get(objName);
            Schema.DescribeSObjectResult r = s.getDescribe();

            //get fields
            Map < String, Schema.SObjectField > fields = r.fields.getMap();
            for (string field: fields.keySet()) {
                if (fieldnames == '') {
                    fieldnames = field;
                } else {
                    fieldnames += ',' + field;
                }
            }
            
            //create SQL
            String sql = 'SELECT ' + fieldnames + ' FROM ' + objName ;
            //Add any addtional filter criteria to query string if it was defined in component
                if(filter != ''){
                    sql +=  '  Where ' + filter;                
                }
                
                //Add order by field to query if defined in component
                //If sortByField != null then user has clicked a header and sort by this field
                if(sortByField != ''){
                    sql += '  order by ' + sortByField;
                }
            objList = database.query(sql);
            

        } catch (Exception e) {
            System.debug('get Fields Error' + e.getMessage());
            ApexPages.addMessages(e);
            return new List<sObject>();
        }
        
        return objList;
    }
    
}

/*
public   List<PACE_Program__c> getProgramListMethod()
    {
            List<PACE_Program__c> programList = [Select  Id,Name, Program_Manager__c,Product_Manager__c,Product_Line__c,Division__c from PACE_Program__c ] ;
            return  programList;
        
    }
    public  void getUserProfile()
        {
            
            for(Profile profname : [select Name from Profile where Id = : UserInfo.getProfileId()] )
                {
                    profileName = profname.Name ;
                }
            
        }
    */