@isTest(seeAllData = false)
public class AkaNovaCommentServiceTest {
    public static testmethod void Comment_GetAll() 
    {
        Concept__c c1 = new Concept__c();
        c1.Name = 'Test';
        c1.Problem__c = 'Building testing framework';
        c1.implementationPlan__c = 'yet to figure out';
        c1.SuccessDetails__c = 'lol';
        c1.Resources__c = 'server';
        c1.Challenges__c = 'everything is';
        c1.Timelines_for_implementation__c = '3-6 Months';
        c1.Owner_Name__c = 'ssanji';
        insert c1;
        List<Akanova_Comment__c> commentList = new List<Akanova_Comment__c>();
        Akanova_Comment__c comment1 = new Akanova_Comment__c();
        comment1.Name = c1.Id;
        comment1.Comment_Body__c = 'Test Comment';
        comment1.Concept__c = c1.Id;
        comment1.Comment_Owner__c = 'hverma';
        commentList.add(comment1);
        insert commentList;
        RestRequest request = new RestRequest();
        request = new RestRequest();
        string conceptId = c1.Id;
        request.httpMethod = 'GET';
        request.requestUri = 'https://localhost:8080/services/apexrest/Akanova/v1/Comments/' + conceptId;
        RestContext.request = request;
        List<Akanova_Comment__c> cmntList = AkaNovaCommentService.doGet();
        System.AssertEquals(cmntList.isEmpty(), false);
        request = new RestRequest();
        conceptId = null;
        request.httpMethod = 'GET';
        request.requestUri = 'https://localhost:8080/services/apexrest/Akanova/v1/Comments/' + conceptId;
        RestContext.request = request;
        cmntList = AkaNovaCommentService.doGet();
        System.AssertEquals(cmntList.isEmpty(), true);
    }
    
     public static testmethod void Comment_Save_Passed() 
    {
        List<User> usrList = [Select Id, Alias from User where isActive = true and Profile.Name = 'Sales Development Representative' limit 1 ];
        Concept__c c1 = new Concept__c();
        c1.Name = 'Test2';
        c1.Problem__c = 'Building testing framework2';
        c1.implementationPlan__c = 'yet to figure out2';
        c1.SuccessDetails__c = 'lol2';
        c1.Resources__c = 'server2';
        c1.Challenges__c = 'everything is2';
        c1.Timelines_for_implementation__c = '3-6 Months';
        c1.Owner_Name__c = usrList[0].Alias;
        c1.Concept_Owner__c = usrList[0].Id;
        insert c1;
        RestRequest request = new RestRequest();
        request.requestUri = 'https://localhost:8080/services/apexrest/Akanova/v1/Comments/';
        request.httpMethod = 'POST';
        String body = '{"attributes":{"type":"Akanova_Comment__c"},"Comment_Owner__c":"ssanji","Name":"'+c1.Id+'","Comment_Body__c":"Test cmment","Concept__c":"'+c1.Id+'"}';
        request.addHeader('Content-Type', 'application/json');
        request.addHeader('charset', 'utf-8');
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;
        RestContext.response = new RestResponse();
        AkaNovaCommentService.SaveComment();
        List<Akanova_Comment__c> comntList= [select id, Concept__r.Concept_Owner__r.Email from Akanova_Comment__c where name = :c1.Id];
        System.AssertEquals(comntList.isEmpty(), false);
    }
    public static testmethod void Comment_Save_failed() 
    {
        Concept__c c1 = new Concept__c();
        c1.Name = 'Test2';
        c1.Problem__c = 'Building testing framework2';
        c1.implementationPlan__c = 'yet to figure out2';
        c1.SuccessDetails__c = 'lol2';
        c1.Resources__c = 'server2';
        c1.Challenges__c = 'everything is2';
        c1.Timelines_for_implementation__c = '3-6 Months';
        c1.Owner_Name__c = 'ssanji';
        insert c1;
        RestRequest request = new RestRequest();
        request.requestUri = 'https://localhost:8080/services/apexrest/Akanova/v1/Comments/';
        request.httpMethod = 'POST';
       
        String body = '{"attributes":{"type":"Akanova_Comment__c"},"Comment_Owner__c":"hverma","Name":"'+c1.Id+'","Comment_Body__c":"Test cmment","Concept__c":"'+c1.Id+'"}';
        request.addHeader('Content-Type', 'application/json');
        request.addHeader('charset', 'utf-8');
        request.requestBody = Blob.valueOf(body);
        RestContext.request = request;
        // fail by not setting the response object
        //RestContext.response = new RestResponse();
        AkaNovaCommentService.SaveComment();
        List<Akanova_Comment__c> comntList= [select id from Akanova_Comment__c where name = :c1.Id];
        System.AssertEquals(comntList.isEmpty(), true);
    }
}