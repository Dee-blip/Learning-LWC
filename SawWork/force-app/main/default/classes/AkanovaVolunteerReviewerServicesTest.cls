@isTest(seeAllData = false)
public class AkanovaVolunteerReviewerServicesTest {
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
    }
    @isTest static void testVolunteerService(){
        //create volunteer
        RestRequest request = new RestRequest();
        RestContext.response = new RestResponse();
        request.requestUri = 'https://localhost:8080/services/apexrest/Akanova/v1/Vounteer/';
        request.httpMethod = 'PUT';
        String body = '{"v":{"attributes":{"type":"Volunteer__c"},"Team_Name__c":"ESP","Skills__c":"React","Time__c":"1","Success_Criteria__c":"By impact"},"ldap":"ssanji"}';
        request.addHeader('Content-Type', 'application/json');
        request.addHeader('charset', 'utf-8');
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;
        AkanovaVolunteerService.doPut();
        List<Volunteer__c> volunteers = [Select Id, Name from Volunteer__c];
        System.AssertEquals(volunteers.isEmpty(), false);
        //get volunteer
        request = new RestRequest();
        request.httpMethod = 'GET';
        RestContext.request = request;
        for(Volunteer__c v : volunteers){
            request.requestUri = 'https://localhost:8080/services/apexrest/Akanova/v1/Vounteer/' + v.Id;
            AkanovaVolunteerService.doGet();
            System.AssertEquals(RestContext.response.statusCode, 200);
        }
        request.requestUri = 'https://localhost:8080/services/apexrest/Akanova/v1/Vounteer/all';
        AkanovaVolunteerService.doGet();
        System.AssertEquals(RestContext.response.statusCode, 200);
        request.requestUri = 'https://localhost:8080/services/apexrest/Akanova/v1/Vounteer/ldap:ssanji';
        AkanovaVolunteerService.doGet();
        System.AssertEquals(RestContext.response.statusCode, 200);
        //duplicates volunteer addition
        request.requestUri = 'https://localhost:8080/services/apexrest/Akanova/v1/Vounteer/';
        request.httpMethod = 'PUT';
        request.addHeader('Content-Type', 'application/json');
        request.addHeader('charset', 'utf-8');
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;
        RestContext.response = new RestResponse();
        AkanovaVolunteerService.doPut();
        System.AssertEquals(RestContext.response.statusCode, 400);
    }
    @isTest static void testReviewerService(){
        //provide feedback
              List<Concept__c> concepts = [Select Id, name from Concept__c];
        Id conceptId = concepts.get(0).Id;
        List<AkaNova_Settings__mdt> reviewersList = [SELECT Id, ReviewerId__c FROM AkaNova_Settings__mdt WHERE DeveloperName = 'ReviewersList' LIMIT 1];
        Id userId = reviewersList[0].ReviewerId__c.split(',')[0];
        User u = [Select Alias from User where Id = :userId limit 1];
        RestRequest request = new RestRequest();
        request.requestUri = 'https://localhost:8080/services/apexrest/Akanova/v1/Reviewer/feedback';
        request.httpMethod = 'PUT';
        String body = '{"ct":{"attributes":{"type":"Concept_Team__c"},"Concept_AkaNova__c":"' + conceptId +'","Implementation_Feasibility__c":"Yes","Solves_Problem__c":"Yes","Submit_Implementation_Plan__c":"true","Implementation_Plan__c":"plan","Implementation_Tools__c":"tools","Additional_Comments__c":"no"},"ldap":"'+u.Alias+'"}';
        request.addHeader('Content-Type', 'application/json');
        request.addHeader('charset', 'utf-8');
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;
        RestContext.response = new RestResponse();
        AkanovaReviewerService.doPut();
        //get feedback
        request = new RestRequest();
        request.httpMethod = 'GET';
        request.requestUri = 'https://localhost:8080/services/apexrest/Akanova/v1/Reviewer/' + conceptId + ';'+u.Alias;
        RestContext.request = request;
        AkanovaReviewerService.doGet();
        System.AssertEquals(RestContext.response.statusCode, 200);
    }
}