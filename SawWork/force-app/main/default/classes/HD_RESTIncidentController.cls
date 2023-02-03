/** 
 REST API for Incident(BMCServiceDesk__Incident__c).
 This will accept the text value for category, category tree, priority, description, cc, client id while creating Incident.
 Returns the Incident Id and the Incident Number.
**/

@RestResource(urlMapping='/v1.0/HelpdeskIncident/*')
  global with sharing class HD_RESTIncidentController {
   
    @HttpPost  
    global static string createIncident(String categoryName, String priority,String description, String clientId, String categoryTree,String cc) {

      if(String.isBlank(categoryName) || String.isBlank(description) || String.isBlank(priority) ){
      
        return 'Error: Category, Description and Priority are manadatory fields.';
      }
        
      categoryName =  categoryName.trim();
      priority     =  priority.trim();
      description  =  description.trim();
      
      if(priority == '1'){
        return 'Error: Cannot create ticket with priority 1 , It is considered as High Customer Impact issue.';
      }
      
      HD_Ticket_Priority__c ticket_priority = HD_Ticket_Priority__c.getInstance(priority);  
      if(ticket_priority ==  null ){
        return 'Error: Invalid Priority  '+priority;
      }
      
      String msg = '';
      List<BMCServiceDesk__Category__c>  catlist = new List<BMCServiceDesk__Category__c>();
       
      if(String.isNotEmpty(categoryName) && String.isEmpty(categoryTree)){
      
         catlist = [Select ID FROM BMCServiceDesk__Category__c where name = :categoryName Limit 1];
         msg = categoryName;
      }else if(String.isNotEmpty(categoryName) && String.isNotEmpty(categoryTree) ){
       
         catlist = [Select ID FROM BMCServiceDesk__Category__c where name = :categoryName and BMCServiceDesk__parentTree__c =:categoryTree.trim() Limit 1];
         msg = categoryName+' with parent tree '+categoryTree;
      }
      
      if (catlist.size() < 1){
        return  'Error:Category '+msg+' does not exists. ';
      }
  
      List<User> users = new List<User>();
      List<HD_API_Profiles__c> apiProfiles = HD_API_Profiles__c.getall().values();
      String profileId = userinfo.getProfileId();
      Boolean allowedProfile = false;
      
      for( HD_API_Profiles__c prof: apiProfiles){
      
         if(prof.Id__c == profileId){
           
           allowedProfile = true;
           break;
         }
      
      }
      

      if (String.isNotEmpty(clientId) &&  allowedProfile == true ){
        users =  [select id from User where username = :clientId.trim() Limit 1]; 
      }
      
      String userId = '';
      if (users.size() > 0){
        userId = users[0].id;
      }else{
         userId = UserInfo.getUserId();
      }
      
      BMCServiceDesk__Incident__c incident = new BMCServiceDesk__Incident__c();
      incident.BMCServiceDesk__FKCategory__c = catlist[0].id;
      incident.HD_Ticket_Priority__c = priority;
      incident.BMCServiceDesk__FKClient__c = userId;
      incident.BMCServiceDesk__incidentDescription__c = description;
      if (String.isNotBlank(cc)){
         incident.CCText__c = cc;
      }
      BMCServiceDesk__Incident__c inci_refetch = null;
      
      try{
        insert incident;
        inci_refetch = [SELECT ID,NAME,OwnerId from BMCServiceDesk__Incident__c where ID = :incident.id Limit 1][0];
         
      }catch (Exception e) {
      
        return e.getMessage();

      }
      
      return  'ID:'+incident.Id+',Incident#:'+inci_refetch.name;
    }
 }