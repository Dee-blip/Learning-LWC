@isTest
public class MockQuipHttpResponseGenerator implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) 
    {   
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type','application/json');
        if(req.getEndpoint().contains('cursor/create')){
            res.setBody('{"next_cursor":"eyJjdXJzb3JfdmVyc2lvbiI"}');
        }
        else if(req.getEndpoint().contains('admin/threads')){
            res.setBody('{"GDGAAA6IlPa":{"thread":{"created_usec": 1392021829698995,"updated_usec": 1394315318673846,"id": "GDGAAA6IlPa","title": "Expense Reports","link": "https://quip.com/e4V7AeaKCVmq"}}}');
        }
        else if(req.getEndpoint().contains('users/?ids=')){
            res.setBody('{"bAUAEADkFcz": {"affinity": 0,"id": "bAUAEADkFcz","name": "Bret Taylor","emails": ["eae-ops@akamai.com"]}}');
        }
        else if(req.getEndpoint().contains('scim.quip.com/2/Users')){
            res.setBody('{"id":"bAUAEADkFcz"}');
            res.setStatusCode(201);
            return res;
        }
        else if(req.getEndpoint().contains('scim.quip.com/2/Users/')){
            res.setBody('{}');
        }
        else{
            res.setBody('{"events":[{"time_usec":1584447573551674,"ip":"93.159.154.34","session_id":"GOYAMAV0EYs","user_agent":"Mozilla","device": "web","quip_version": "","message_id": "WNHADAg9GiZ","user_id": "GOYAEAQgqEv","document_id": "WNHABAcmlUj","company_id": "ZARAcAiFeXi","annotation_id": "","id": "","object": "message","action": "create","child_object": "","event":"open-thread"}],"more_to_read":false,"next_cursor":""}');
        }
        res.setStatusCode(200);
        return res;
    }
}