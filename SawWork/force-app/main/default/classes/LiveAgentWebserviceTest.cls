@isTest
public class LiveAgentWebserviceTest {

    @isTest public static void InvalidSkill() {
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.requestURI = '/liveagent';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        LiveAgentWebservice.Response results = LiveAgentWebservice.getLiveAgentCode();
        System.assertEquals(results.errorCode , 'EMPTY_SKILLSET');
    }
    
    @isTest public static void IncorrectSkill() {
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.addParameter('skillset', 'Live Agent Dummy');
        req.requestURI = '/liveagent';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        String errorMessage = LiveAgentWebservice.getLiveErrorMessage();
        LiveAgentWebservice.Response results = LiveAgentWebservice.getLiveAgentCode();
        System.assertEquals(results.errorCode , 'INCORRECT_SKILLSET');
    }
    
    @isTest public static void PositiveScenario() {
        
        RestRequest req = new RestRequest(); 
        RestResponse res = new RestResponse();
        req.addParameter('skillset', 'Live Agent English');
        req.requestURI = '/liveagent';
        req.httpMethod = 'GET';
        RestContext.request = req;
        RestContext.response = res;
        LiveAgentWebservice.Response results = LiveAgentWebservice.getLiveAgentCode();
       // System.assertEquals(results.status , 'SUCCESS');
    }
    
    

}