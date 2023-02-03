@isTest(seeAllData = false)
public class AkanovaConceptUtilClassTest {
    public static testmethod void Concept_Save_Passed() 
    {
        RestRequest request = new RestRequest();
        request.requestUri = 'https://localhost:8080/services/apexrest/Akanova/v1/Concepts/';
        request.httpMethod = 'POST';
        String body = '{"attributes":{"type":"Concept__c"},"Owner_Name__c":"SSANJI","Name":"Test Concept 001","Concept_Description__c":"Test Desc","Problem__c":"Test Problem","implementationPlan__c":"Test Implementation","SuccessDetails__c":"Test Success","Resources__c":"Test Resources","Challenges__c":"Test Challenge","Timelines_for_implementation__c":"1 Year"}';
        request.addHeader('Content-Type', 'application/json');
        request.addHeader('charset', 'utf-8');
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;
        RestContext.response = new RestResponse();
        ConceptUtilClass.SaveConcept();
        List<Concept__c> conceptList= [select id from Concept__c where name = 'Test Concept 001'];
        System.AssertEquals(conceptList.isEmpty(), false);
    }
    
    public static testmethod void Concept_Save_Failed() 
    {
        RestRequest request = new RestRequest();
        request.requestUri = 'https://localhost:8080/services/apexrest/Akanova/v1/Concepts/';
        request.httpMethod = 'POST';
        String body = '{"attributes":{"type":"Concept__c"},"Owner_Name__c":"SSANJI","Name":"Test Concept 001","Concept_Description__c":"Test Desc","Problem__c":"Test Problem","implementationPlan__c":"Test Implementation","SuccessDetails__c":"Test Success","Resources__c":"Test Resources","Challenges__c":"Test Challenge","Timelines_for_implementation__c":"1 Year"}';
        request.addHeader('Content-Type', 'application/json');
        request.addHeader('charset', 'utf-8');
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;
        // fail by not setting the response object
        //RestContext.response = new RestResponse();
        ConceptUtilClass.SaveConcept();
        List<Concept__c> conceptList= [select id from Concept__c where name = 'Test Concept 001'];
        System.AssertEquals(conceptList.isEmpty(), true);
    }
    
     public static testmethod void Concept_GetAll() 
    {
        List<Concept__c> cncptList = new List<Concept__c>();
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
        cncptList.add(c1);
        Concept__c c2 = new Concept__c();
        c2.Name = 'Test 002';
        c1.Concept_Description__c = 'Test framework';
        c2.Problem__c = 'Building testing framework 002';
        c2.implementationPlan__c = 'yet to figure out 002';
        c2.SuccessDetails__c = 'Success 002';
        c2.Resources__c = 'server 002';
        c2.Challenges__c = 'everything is 002';
        c2.Timelines_for_implementation__c = '3-6 Months';
        c2.Owner_Name__c = 'hverma';
        cncptList.add(c2);
        insert cncptList;
        RestRequest request = new RestRequest();
         request = new RestRequest();
        string conceptId = 'all';
        request.httpMethod = 'GET';
        request.requestUri = 'https://localhost:8080/services/apexrest/Akanova/v1/Concepts/' +conceptId+'/10/0';
        RestContext.request = request;
        List<Concept__c> conceptList = ConceptUtilClass.doGet();
        System.AssertEquals(conceptList.isEmpty(), false);
        request = new RestRequest();
        conceptId = c1.Id;
        request.httpMethod = 'GET';
        request.requestUri = 'https://localhost:8080/services/apexrest/Akanova/v1/Concepts/' + conceptId+'/1/0';
        RestContext.request = request;
        conceptList = ConceptUtilClass.doGet();
        System.AssertEquals(conceptList.isEmpty(), false);
    }
}