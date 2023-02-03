@RestResource(urlMapping='/SupportTeamRest/*')
global with sharing class SupportTeamRestApi {

    @HttpGet
    global static TS_Support_Team__c doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        String teamId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        System.debug('Team Id:'+teamId);
        TS_Support_Team__c result = [SELECT Id, Name,Team_Name__c,Team_Type__c, VDN__c FROM TS_Support_Team__c WHERE Id = :teamId];
        return result;
    }
    
     @HttpPut
     global static String doPut() {
         // see if a username was part of the uri
         RestRequest req = RestContext.request;
         RestResponse res = RestContext.response;
         String teamId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
         if (teamId != null) {
             return updateTeam(teamId, req);
         } else {
             return 'Invalid operation';
         }
     }
      
     private static String updateTeam(String teamId, RestRequest req) {
         Map<String, Schema.SObjectField> sObjectFieldsMap = Schema.SObjectType.TS_Support_Team__c.fields.getMap();           
         // don't let them update the following fields -- use all lowercase for comparison
         Set<String> noUpdateFields = new Set<String>{'team_name__c'};
         TS_Support_Team__c t;
         try {
             // fetch the member by username if it exists
             t = [select id from TS_Support_Team__c where id = :teamId];
             // populate the object's fields
             for (String key : req.params.keySet()) {
             // only add params if they are valid field on the object and not on the no-update list
             if (sObjectFieldsMap.containsKey(key) && !noUpdateFields.contains(key.toLowerCase()))
                 t.put(key,req.params.get(key)); 
             }
             update t;
         } 
         catch (QueryException e) {
             return 'Team not found for: ' + teamId;         
         }
         catch (DMLException e1) {
             return e1.getDmlMessage(0);   
         }
         catch (Exception e2) {
             return e2.getMessage();
         }  
         return t.id;
     }
  
}