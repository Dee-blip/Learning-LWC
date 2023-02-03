@RestResource(urlMapping='/Akanova/v1/Vounteer/*')
global with sharing class AkanovaVolunteerService {
    global class VolunteerDetails{
        global Volunteer__c v;
        global String ldap;
    }
    @HttpGet
    global static void doGet() {
        //todiscuss: Volunteer data in pagination? if more than 10k volunteer in future?
        //show only user part of org
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        try{
            String volunteerId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
            List<Volunteer__c> allVolunteers = new List<Volunteer__c>();
            if(volunteerId != null && !volunteerId.equalsIgnoreCase('all')){
                if(volunteerId.containsIgnoreCase('ldap')){
                    allVolunteers = [Select Id,Name,Volunteer_Role__c,Team_Name__c,Skills__c,Time__c,Success_Criteria__c from Volunteer__c where User__r.alias =:volunteerId.split(':')[1]];
                }
                else{
                    allVolunteers = [Select Id,Name,Volunteer_Role__c,Team_Name__c,Skills__c,Time__c,Success_Criteria__c from Volunteer__c where Id=:volunteerId];
                } 
            }
            else{
                allVolunteers = [Select Id,Name,Volunteer_Role__c,Team_Name__c,Skills__c,Time__c,Success_Criteria__c from Volunteer__c where Is_Active_for_Volunteering__c = true order by CreatedDate desc];
            }
            res.statusCode = 200;
            res.responseBody = blob.valueOf(JSON.serialize(allVolunteers));
        }
        catch (Exception e) {
            res.responseBody = Blob.valueOf('{"response": {"status": "Failure", "message": ' + e.getMessage() + '"}}');
            res.statusCode = 500;
        }
    }
    @HttpPut
    global static void doPut() {
        //is Nickname the ldap in user object? what all values are passed when adding volunteer
        //userid - instead of ldap
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        try{
            VolunteerDetails vd = (VolunteerDetails)JSON.deserialize(req.requestBody.toString(), VolunteerDetails.class);
            Volunteer__c v = (Volunteer__c)vd.v;
            string ldap = vd.ldap;
            System.debug('ldap='+ldap);
            System.debug('volunterr='+v);
            List<User> userList = [Select Id, Name from User where alias =:ldap LIMIT 1];
            User user = userList.isEmpty()?null:userList.get(0);
            string responseMsg = '';
            if(user == null){
                //return #404, #Volunteer isn't part of org
                res.statusCode = 404;
                res.responseBody = blob.valueOf('Volunteer isn\'t part of org');
            }
            else{
                List<Volunteer__c> volunteerList = [Select Id,User__c,Name,Volunteer_Role__c,Is_Active_for_Volunteering__c from Volunteer__c where User__c =:user.Id];
                Volunteer__c volunteer = volunteerList.isEmpty()?null:volunteerList.get(0);
                if(volunteer == null){
                    //Volunteer doesn't exist, add volunteer
                    v.Is_Active_for_Volunteering__c = true;
                    v.Name = user.Name;
                    v.User__c = user.Id;
                    insert v;
                    res.statusCode = 200;
                    res.responseBody = blob.valueOf(ldap+ ' added as a volunteer successfully with volunteer Id: '+v.Id);
                }
                else{
                    if(volunteer.Is_Active_for_Volunteering__c == true){
                        //Volunteer exist
                        //return #400, #volunteer already exist
                        res.statusCode = 400;
                        res.responseBody = blob.valueOf(ldap + ' is already a volunteer');
                    }
                    else{
                        //Update inactive volunteer
                        update volunteer;
                        res.statusCode = 200;
                        res.responseBody = blob.valueOf(ldap+ ' added as a volunteer successfully with volunteer Id: '+volunteer.Id);
                    }
                }
            }
        }
        catch (Exception e) {
            res.responseBody = Blob.valueOf('{"response": {"status": "Failure", "message": ' + e.getMessage() + '"}}');
            res.statusCode = 500;
        }
    }
    // @HttpDelete
    // global static String doDelete() {
    //     RestRequest req = RestContext.request;
    //     string responseMsg = '';
    //     String ldap = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
    //     List<User> userList = [Select Id from User where CommunityNickname =:ldap];
    //     User user = userList.isEmpty()?null:userList.get(0);
    //     if(user == null){
    //         //return #404, #Volunteer isn't part of org
    //         RestContext.response.statusCode = 404;
    //         responseMsg = ldap + ' isn\'t part of Akamai';
    //     }
    //     else{
    //         List<Volunteer__c> volunteerList = [Select Id,User__c,Is_Active_for_Volunteering__c from Volunteer__c where User__c =:user.Id];
    //         Volunteer__c volunteer = volunteerList.isEmpty()?null:volunteerList.get(0);
    //         if(volunteer == null){
    //             //return #400, user isn't a volunteer yet
    //             RestContext.response.statusCode = 400;
    //             responseMsg = ldap + ' isn\'t a volunteer yet';
    //         }
    //         else{
    //             //is it a soft or hard delete?
    //             volunteer.Is_Active_for_Volunteering__c = false;
    //             update volunteer;
    //             responseMsg = 'Volunteer '+ ldap +' deleted Successfully';
    //         }
    //     }
    //     return responseMsg;
    // }
}