@RestResource(urlMapping='/Akanova/v1/Reviewer/*')
global with sharing class AkanovaReviewerService {
    global class FeedBackDetails{
        global Concept_Team__c ct;
        global String ldap;
    }
    @HttpGet
    global static void doGet() {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        try{
            List<String> urlParam = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1).split(';');
            String conceptId = urlParam.size() >= 1 ? urlParam[0] : '';
            String ldap = urlParam.size() >= 2 ? urlParam[1] : '';
            String id = urlParam.size() >= 3 ? urlParam[2] : '';
            System.debug(urlParam);
            System.debug(ldap+' '+conceptId);
            List<Concept_Team__c> feedbacks = new List<Concept_Team__c>();
            if(conceptId != null && !ldap.equalsIgnoreCase('all')){
                feedbacks = [Select Id, Concept_AkaNova__c, Implementation_Feasibility__c, Solves_Problem__c, Submit_Implementation_Plan__c, Implementation_Plan__c, Implementation_Tools__c, Additional_Comments__c, Feedback_Given__c from Concept_Team__c where Concept_AkaNova__c=:conceptId and user__r.alias = :ldap and User_Type__c = 'Reviewer'];
            }  else if(conceptId != null && !String.isBlank(id) && id != 'undefined'){
                feedbacks = [Select Id, Concept_AkaNova__c, Implementation_Feasibility__c, Solves_Problem__c, Submit_Implementation_Plan__c, Implementation_Plan__c, Implementation_Tools__c, Additional_Comments__c, Feedback_Given__c from Concept_Team__c where Concept_AkaNova__c=:conceptId and Id = :id and User_Type__c = 'Reviewer'];
            }  else {
                feedbacks = [Select Id, Concept_AkaNova__c, Feedback_Given__c, Feedback_Submitted_Datetime__c, username__c from Concept_Team__c where Concept_AkaNova__c=:conceptId and User_Type__c = 'Reviewer'];
            }
            res.statusCode = 200;
            res.responseBody = blob.valueOf(JSON.serialize(feedbacks));
        }
        catch (Exception e) {
            res.responseBody = Blob.valueOf('{"response": {"status": "Failure", "message": ' + e.getMessage() + '"}}');
            res.statusCode = 500;
        }
        
    }
    
    @HttpPut
    global static void doPut() {
        Map<String,String> response;
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        try{
            String endpoint = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
            FeedBackDetails fd = (FeedBackDetails)JSON.deserialize(req.requestBody.toString(), FeedBackDetails.class);
            Concept_Team__c ct = (Concept_Team__c)fd.ct;
            if(endpoint == 'Adhoc'){
                //response = addAdhocReviewer(ct, ldap);
            }
            else if(endpoint == 'feedback'){
                response = updateFeedback(ct, fd.ldap);
            }
            res.statusCode = Integer.valueOf(response.get('code'));
            res.responseBody = Blob.valueOf('{"message": ' + response.get('description') + '"}');
            return ;
        }
        catch (Exception e) {
            res.responseBody = Blob.valueOf('{"response": {"status": "Failure", "message": ' + e.getMessage() + '"}}');
            res.statusCode = 500;
        }
    }
    /*private static Map<String,String> addAdhocReviewer(Concept_Team__c ct){
        Map<String,String> response = new Map<String,String>();
        List<User> userList = [Select Id,IsActive from User where CommunityNickname =:ldap];
        User user = userList.isEmpty()?null:userList.get(0);
        if(user == null){
            response.put('code','404');
            response.put('description','Reviewer isn\'t part of the organization');
            //return #404, Reviewer isn't part of the organization
        }
        else if(!user.IsActive){
            //return #400, Reviewer has left organization
            response.put('code','400');
            response.put('description','Reviewer has left organization');
        }
        else{
            Concept_Team__c conceptTeamReviewer = new Concept_Team__c();
            conceptTeamReviewer.Name = ldap;
            conceptTeamReviewer.User__c = user.Id;
            conceptTeamReviewer.User_Type__c = 'Reviewer';
            conceptTeamReviewer.Concept_AkaNova__c = conceptId; //need conceptId, how are sending from Angular?
            insert conceptTeamReviewer;
            response.put('code','200');
            response.put('description','Adhoc reviewer' + ldap+ 'added successfully to concept '+ conceptId);
        }
        return response;
    }*/
    private static Map<String,String> updateFeedback(Concept_Team__c ct, string ldap){
        Map<String,String> response = new Map<String,String>();
        List<User> u = [Select Id from user where alias = :ldap and isActive = true limit 1];
        if(u.isEmpty()){
            response.put('code','404');
            response.put('description',ldap+' Reviewer isn\'t part of the organization');  
        }
        else{
            List<Concept_Team__c> reviewer = [select Id from Concept_Team__c where user__c =:u[0].Id and Concept_AkaNova__c =:ct.Concept_AkaNova__c and User_Type__c = 'Reviewer' LIMIT 1];
            if(reviewer.isEmpty()){
                response.put('code','400');
                response.put('description',ldap+' is not a reviewer for concept '+ ct.Concept_AkaNova__c);  
            }
            else{
                ct.Id = reviewer.get(0).Id;
                ct.Feedback_Given__c = true;
                ct.Feedback_Submitted_Datetime__c = Datetime.now();
                update ct;
                response.put('code','200');
                response.put('description','Feedback successfully updated for concept '+ ct.Concept_AkaNova__c + ' by '+ ldap);
            }
        }
        return response;
    }
}