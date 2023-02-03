@RestResource(urlMapping='/Akanova/v1/conceptTeam/*')
global with sharing class AkanovaConceptTeamService {
    @HttpGet
    global static void doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        try{
            String conceptId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
            List<Concept_Team__c> members = new List<Concept_Team__c>();
            if(conceptId != null){
                members = [Select Id,User__r.name,User__r.alias,User_Type__c,volunteer_status__c,Volunteer_AkaNova__c,Concept_AkaNova__c,Concept_AkaNova__r.Name,Concept_AkaNova__r.Concept_Owner__r.Name  from Concept_Team__c  where (Concept_AkaNova__c =:conceptId or Volunteer_AkaNova__c = :conceptId or User__r.alias = :conceptId) and User_Type__c in ('Volunteer','Concept Owner') order by User_Type__c desc, volunteer_status__c asc];
            } else {
                members = null;
            }
            res.statusCode = 200;
            res.responseBody = blob.valueOf(JSON.serialize(members));
        }
        catch (Exception e) {
            res.responseBody = Blob.valueOf('{"response": {"status": "Failure", "message": ' + e.getMessage() + '"}}');
            res.statusCode = 500;
        }
    }
    
    @HttpPost
    global static void doPost() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        try{
            Map<String, Object> teamMember = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
            String ldap = (String) teamMember.get('ldap');
            List<User> userList = [Select Id, Name from User where alias =:ldap LIMIT 1];
            User user = userList.isEmpty() ? null : userList.get(0);
            if(user != null) {
                Concept_Team__c ct = new Concept_Team__c();
                ct.Concept_AkaNova__c = (String) teamMember.get('conceptId');
                ct.User_Type__c = 'Volunteer';
                ct.volunteer_status__c  = 'Pending';
                ct.Volunteer_AkaNova__c = (String) teamMember.get('volunteerId');
                ct.User__c = user.Id;
                System.debug(ct);
                insert ct;
                res.statusCode = 200;
                res.responseBody = blob.valueOf(ct.Id);
            } else {
                res.responseBody = Blob.valueOf('{"response": {"status": "Failure", "message": "Could not find user."}}');
                res.statusCode = 404;
            }    
        }
        catch (Exception e) {
            res.responseBody = Blob.valueOf('{"response": {"status": "Failure", "message": ' + e.getMessage() + '"}}');
            res.statusCode = 500;
        }
    }
    
    @HttpPut
    global static void doPut() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        try{
            Map<String, Object> teamMember = (Map<String, Object>) JSON.deserializeUntyped(req.requestBody.toString());
            Concept_Team__c ct = new Concept_Team__c();
            ct.Id = (String) teamMember.get('Id');
            ct.volunteer_status__c  = (String) teamMember.get('Status');
            System.debug(ct);
            update ct;
            res.statusCode = 200;
            res.responseBody = blob.valueOf(ct.Id);  
        }
        catch (Exception e) {
            res.responseBody = Blob.valueOf('{"response": {"status": "Failure", "message": ' + e.getMessage() + '"}}');
            res.statusCode = 500;
        }
    }

}