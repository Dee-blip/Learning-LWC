@isTest(seeAllData = false)
public class AkanovaConceptTeamServiceTest {
    @testSetup static void setup() {
        Concept__c c1 = new Concept__c();
        c1.Name = 'Test';
        c1.Concept_Description__c = 'Test framework';
        c1.Problem__c = 'Building testing framework';
        c1.implementationPlan__c = 'yet to figure out';
        c1.SuccessDetails__c = 'lol';
        c1.Resources__c = 'server';
        c1.Challenges__c = 'everything is';
        c1.Timelines_for_implementation__c = '3-6 Months';
        c1.Owner_Name__c = 'ssanji';
        insert c1;
        
        User u1 = [Select Id,Name from User where alias = 'ssanji' limit 1];
        
        Volunteer__c v1 = new Volunteer__c();
        v1.Name = 'Test';
        v1.Team_Name__c = 'CIo';
        v1.Skills__c = 'xyz';
        v1.Success_Criteria__c = 'test';
        v1.Time__c = '1';
        v1.Is_Active_for_Volunteering__c = true;
        v1.User__c = u1.Id;
        v1.Name = u1.Name;
        insert v1;
    }
    
    @isTest static void VolunteerRequest(){
        //volunteer request
        List<Concept__c> concepts = [Select Id, name from Concept__c];
        Id conceptId = concepts.get(0).Id;
        List<Volunteer__c> volunteers = [Select Id, name from Volunteer__c];
        Id volunteerId = volunteers.get(0).Id;

        RestRequest request = new RestRequest();
        request.requestUri = 'https://localhost:8080/services/apexrest/Akanova/v1/conceptTeam/request';
        request.httpMethod = 'POST';
        String body = '{"conceptId":"' + conceptId +'","volunteerId":"' + volunteerId +'","ldap":"ssanji"}';
        request.addHeader('Content-Type', 'application/json');
        request.addHeader('charset', 'utf-8');
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;
        RestContext.response = new RestResponse();
        AkanovaConceptTeamService.doPost();
        System.AssertEquals(RestContext.response.statusCode, 200);
        
        //get team
        request = new RestRequest();
        request.httpMethod = 'GET';
        request.requestUri = 'https://localhost:8080/services/apexrest/Akanova/v1/Reviewer/' + conceptId + ';ssanji';
        RestContext.request = request;
        AkanovaConceptTeamService.doGet();
        System.AssertEquals(RestContext.response.statusCode, 200);
        
        // approve request
        Concept_Team__c team = [Select Id from Concept_Team__c where User_Type__c = 'Volunteer' limit 1];
        request = new RestRequest();
        request.requestUri = 'https://localhost:8080/services/apexrest/Akanova/v1/conceptTeam/request';
        request.httpMethod = 'PUT';
        body = '{"Id":"' + team.Id +'","Status":"Approved"}';
        request.addHeader('Content-Type', 'application/json');
        request.addHeader('charset', 'utf-8');
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;
        RestContext.response = new RestResponse();
        AkanovaConceptTeamService.doPut();
        System.AssertEquals(RestContext.response.statusCode, 200);        
    }

}