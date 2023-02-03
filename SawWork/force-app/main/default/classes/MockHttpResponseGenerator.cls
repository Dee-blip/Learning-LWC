/***
    MockHttpResponseGenerator
    
    @Author: Pranav Moktali <prmoktal@akamai.com>
    
    @Description: 
        Generates mock responses for HttpCallouts for LunaUserClass, LunaAcountClass and LunaCalloutClass.

*/
@isTest
global class MockHttpResponseGenerator{
    global class GetUserPositive implements HttpCalloutMock{
        global HTTPResponse respond(HTTPRequest req) {
            
                ManagedPkgErrorClass.isFromManagedPackage = false;
                
                String endPoint = req.getEndpoint();
                String httpMethod = req.getMethod();
                HttpResponse res = new HttpResponse();
                System.runAs(utilTestClass.getTestRunUser())
        		{
                System.assertEquals('GET', httpMethod);
                res.setBody('{"contactId":"B-3-10ID257","firstName":"sf","lastName":"int","username":"sf_int","email":"eae-ops@akamai.com","roleAssignments":[{"roleId":14,"roleName":"NAP SSO only","roleDescription":"This role provides the maximum access to users. An Administrator can perform admin tasks such as creating users and groups; configuration-related tasks such as creating and editing configurations; publishing tasks","groupId":18385,"groupName":"Akamai Technologies - Assets-1-3CV382"}],"phone":"111111111","timezone":"GMT","accountId":"1-599K"}');
                res.setStatusCode(200);
                }
                return res;
            }
           
        }
    
    
    global class GetUserNegative implements HttpCalloutMock{
        global HTTPResponse respond(HTTPRequest req) {
            
            ManagedPkgErrorClass.isFromManagedPackage = false;
            
            String endPoint = req.getEndpoint();
            String httpMethod = req.getMethod();
            HttpResponse res = new HttpResponse();
            System.runAs(utilTestClass.getTestRunUser())
        	{
            System.assertEquals('GET', httpMethod);
            res.setBody('<div>Not Authorized</div>');
            res.setStatusCode(401);
        	}
            return res;
        }
        
    }
    
    global class SearchUserPositve implements HttpCalloutMock{
        global HTTPResponse respond(HTTPRequest req) {
            
            ManagedPkgErrorClass.isFromManagedPackage = false;
            
            String endPoint = req.getEndpoint();
            String httpMethod = req.getMethod();
            HttpResponse res = new HttpResponse();
            System.runAs(utilTestClass.getTestRunUser())
        	{
            System.assertEquals('GET', httpMethod);
            res.setBody('{"users":[{"name":"Richard Hamson[WS] asos@akamai.com","id":"B-3-7POAVT.538","type":"user"}],"roles":[{"name":"Akamai Internal - Chat Testing","id":"75411","type":"role"},{"name":"Akamai Internal - Chat Testing 2","id":"75412","type":"role"},{"name":"Akamai Product Manager","id":"75610","type":"role"}],"properties":[{"name":"akamai1.lifeguide.guides.swissre.com","id":"189171","type":"APPLICATION"},{"name":"auth-client-akamai-com","id":"164979","type":"FILE_DOWNLOAD"},{"name":"djr.ovt.http.akamai-trials.com","id":"164990","type":"SITE"},{"name":"edgetoken.akamai.com","id":"164981","type":"APPLICATION"},{"name":"egraham.akamai-testing.cy","id":"164954","type":"SITE"}],"groups":[{"name":"Akamai Technologies - Assets-1-3CV382","id":"18385","type":"group","parentPathStr":"18385","parentPathList":[18385]},{"name":"Akamai Test","id":"18407","type":"group","parentPathStr":"18407/18385","parentPathList":[18407,18385]},{"name":"Test Akamai","id":"18405","type":"group","parentPathStr":"18405/18385","parentPathList":[18405,18385]}]}');
            res.setStatusCode(200);
            }
            return res;
            }
        }
    
    
    global class SearchUserNegative implements HttpCalloutMock{
        global HTTPResponse respond(HTTPRequest req) {
            
            ManagedPkgErrorClass.isFromManagedPackage = false;
            
            String endPoint = req.getEndpoint();
            String httpMethod = req.getMethod();
            HttpResponse res = new HttpResponse();
            System.runAs(utilTestClass.getTestRunUser())
        	{
            System.assertEquals('GET', httpMethod);
            res.setBody('{"users":[],"roles":[],"properties":[],"groups":[]}');
            res.setStatusCode(200);
            }
            return res;
        }
        
    }
    
    global class CreateUserPositive implements HttpCalloutMock{
        global HTTPResponse respond(HTTPRequest req) {
            
            ManagedPkgErrorClass.isFromManagedPackage = false;
            
            String endPoint = req.getEndpoint();
            String httpMethod = req.getMethod();
            HttpResponse res = new HttpResponse();
            System.runAs(utilTestClass.getTestRunUser())
        {
            System.assertEquals('POST', httpMethod);
            res.setBody('{"contactId":"B-3-EUDA8V","firstName":"James","lastName":"T Kirk","username":"jkirk@akamai.com.akamai","email":"jkirk@akamai.com","accountId":"1-599K","phone":"1112223335","timezone":"GMT","roleAssignments":[{"roleId":13,"groupId":18385,"roleDescription":"This role allows for \'read only\' views of the portal and is assigned to enable users to review and monitor reports","roleName":"NAP SSO only","groupName":"Akamai Technologies - Assets-1-3CV382"}]}');
            res.setStatusCode(200);
        }
            return res;
        }
        
    }
    
    global class CreateUserNegative implements HttpCalloutMock{
        global HTTPResponse respond(HTTPRequest req) {
            
            ManagedPkgErrorClass.isFromManagedPackage = false;
            
            String endPoint = req.getEndpoint();
            String httpMethod = req.getMethod();
            HttpResponse res = new HttpResponse();
            System.runAs(utilTestClass.getTestRunUser())
        {
            System.assertEquals('POST', httpMethod);
            res.setBody('{"localizedMessage":"Phone is empty or invalid.","detail":"An invalid request was made.","title":"Bad Request","httpStatus":400,"appError":"Invalid request data"}');
            res.setStatusCode(400);
        }
            return res;
        }
        
    }
    
    global class resetPasswordPositive implements HttpCalloutMock{
        global HTTPResponse respond(HTTPRequest req) {
            
            ManagedPkgErrorClass.isFromManagedPackage = false;
            
            String endPoint = req.getEndpoint();
            String httpMethod = req.getMethod();
            HttpResponse res = new HttpResponse();
            
            System.runAs(utilTestClass.getTestRunUser())
        {
            System.assertEquals('PUT', httpMethod);
            res.setBody('{"localizedMessage":"The temporary password for user ABC was reset to c3GVDq."}');
            res.setStatusCode(200);
        }
            return res;
        }
        
    }
    
    global class resetPasswordNegative implements HttpCalloutMock{
        global HTTPResponse respond(HTTPRequest req) {
            
            ManagedPkgErrorClass.isFromManagedPackage = false;
            
            String endPoint = req.getEndpoint();
            String httpMethod = req.getMethod();
            HttpResponse res = new HttpResponse();
            System.runAs(utilTestClass.getTestRunUser())
        {
            System.assertEquals('PUT', httpMethod);
            res.setBody('{"localizedMessage":"No user found with matching contact id.","detail":"An invalid request was made.","title":"Not Found","httpStatus":404,"appError":"User was not found"}');
            res.setStatusCode(404);
        }
            return res;
        }
        
    }
    
    global class GetRoleDetailsPositive implements HttpCalloutMock{
        global HTTPResponse respond(HTTPRequest req) {
            
            ManagedPkgErrorClass.isFromManagedPackage = false;
            
            String endPoint = req.getEndpoint();
            String httpMethod = req.getMethod();
            HttpResponse res = new HttpResponse();
            System.runAs(utilTestClass.getTestRunUser())
        {
            System.assertEquals('GET', httpMethod);
            res.setBody('[{"roleId":13,"roleName":"NAP SSO only","roleDescription":"This role allows for \'read only\' views of the portal and is assigned to enable users to review and monitor reports","contractTypeId":"1-8BYUX","type":"standard","createdDate":null,"createdBy":"Akamai","modifiedDate":null,"modifiedBy":"Akamai","numUsers":8,"users":[{"contactId":"B-C-B366TV","firstName":"Event","lastName":"Center","accountId":"1-599K"},{"contactId":"B-3-XE0XEH","firstName":"Contract","lastName":"Usage","accountId":"1-599K"},{"contactId":"B-C-C7YIMD","firstName":"CNAMETest","lastName":"Nandha","accountId":"1-599K"},{"contactId":"B-C-C59J8D","firstName":"Joe","lastName":"Adam","accountId":"1-599K"},{"contactId":"B-C-DAXCM1","firstName":"CondeNast","lastName":"PS User","accountId":"1-599K"},{"contactId":"B-3-PFNDF","firstName":"Michael","lastName":"Szydlo","accountId":"1-599K"},{"contactId":"B-C-FPHGVH","firstName":"Reeti","lastName":"Verma","accountId":"1-599K"},{"contactId":"B-3-XNY5H9","firstName":"Stephane","lastName":"Durand","accountId":"1-599K"},{"roleId":14,"roleName":"NAP SSO only","roleDescription":"This role provides the maximum access to users. An Administrator can perform admin tasks such as creating users and groups; configuration-related tasks such as creating and editing configurations; publishing tasks","contractTypeId":"1-8BYUX","type":"standard","createdDate":null,"createdBy":"Akamai","modifiedDate":null,"modifiedBy":"Akamai","numUsers":48,"users":[{"contactId":"B-C-7YFNPR","firstName":"Akadroid","lastName":"Two","accountId":"1-599K"},{"contactId":"B-3-3VW0NR","firstName":"Aruna","lastName":"Johny","accountId":"1-599K"},{"contactId":"B-3-8RU7PT","firstName":"Gregory","lastName":"Smith","accountId":"1-599K"},{"contactId":"B-3-S5NIQL","firstName":"Wil","lastName":"Lo","accountId":"1-599K"},{"contactId":"B-3-YZPFR","firstName":"Jaydeep","lastName":"Nargund","accountId":"1-599K"},{"contactId":"1-U8FOD","firstName":"Patrick","lastName":"Larkin","accountId":"1-599K"},{"contactId":"B-C-3BJW6P","firstName":"Ankit","lastName":"Bhatnagar","accountId":"1-599K"},{"contactId":"1-2GQWZ5","firstName":"Javier","lastName":"Garza","accountId":"1-599K"},{"contactId":"B-3-3YU2WP","firstName":"Anas","lastName":"Mohammed","accountId":"1-599K"},{"contactId":"1-2FHHEL","firstName":"James","lastName":"Kretchmar","accountId":"1-599K"},{"contactId":"1-59QV","firstName":"Sean","lastName":"McDermott","accountId":"1-599K"},{"contactId":"B-3-EUDA8V","firstName":"Orhan","lastName":"Aglagul","accountId":"1-599K"},{"contactId":"B-3-4LQEUL","firstName":"Tejinder","lastName":"Singh","accountId":"1-599K"},{"contactId":"B-3-UKWQGR","firstName":"XYZ","lastName":"ABC","accountId":"1-599K"},{"contactId":"1-N74E","firstName":"Dane","lastName":"Walther","accountId":"1-599K"},{"contactId":"1-59EP","firstName":"Rizwan","lastName":"Dhanidina","accountId":"1-599K"},{"contactId":"B-3-1XBOAR.1951","firstName":"Anushree","lastName":"Krishnan","accountId":"1-599K"},{"contactId":"1-3M5GMD","firstName":"John","lastName":"Devasia","accountId":"1-599K"},{"contactId":"B-3-55TJLR","firstName":"Pradeep","lastName":"Parmar","accountId":"1-599K"},{"contactId":"B-3-1XBOAR.1830","firstName":"Anushree","lastName":"Krishnan","accountId":"1-599K"},{"contactId":"B-C-63P8YZ","firstName":"Mark","lastName":"Van Horn","accountId":"1-599K"},{"contactId":"B-3-7L8C67","firstName":"Poonam","lastName":"Sharma","accountId":"1-599K"},{"contactId":"1-BXP0B","firstName":"Jennifer","lastName":"Breen","accountId":"1-599K"},{"contactId":"B-3-1DTKZN","firstName":"Magnus","lastName":"Schoen","accountId":"1-599K"},{"contactId":"B-3-3YU2W5","firstName":"Ankush","lastName":"Garg","accountId":"1-599K"},{"contactId":"1-ZUCX","firstName":"Kristen","lastName":"McCullough","accountId":"1-599K"},{"contactId":"B-3-EPMOB","firstName":"Troy","lastName":"Snyder","accountId":"1-599K"},{"contactId":"B-3-6J2OAP","firstName":"Mohamed","lastName":"Anas","accountId":"1-599K"},{"contactId":"1-D8R5","firstName":"John","lastName":"Dilley","accountId":"1-599K"},{"contactId":"B-C-GMVER1","firstName":"Gabor","lastName":"Varga","accountId":"1-599K"},{"contactId":"B-3-1XBOAR","firstName":"Anushree","lastName":"Krishnan","accountId":"1-599K"},{"contactId":"B-3-FRN3SP.1656","firstName":"Joachim","lastName":"Hengge","accountId":"1-599K"},{"contactId":"B-3-10ID257","firstName":"sf","lastName":"int","accountId":"1-599K"},{"contactId":"B-3-BTUGP","firstName":"Scot","lastName":"Templeton","accountId":"1-599K"},{"contactId":"B-3-FRN3SP","firstName":"Joachim","lastName":"Hengge","accountId":"1-599K"},{"contactId":"B-3-PFTCZ.406","firstName":"Gemi","lastName":"Kulangara[WS] gkulanga_webservice","accountId":"1-599K"},{"contactId":"B-3-MPSWT","firstName":"Adam","lastName":"Riley","accountId":"1-599K"},{"contactId":"B-3-UKWA2H","firstName":"Hello","lastName":"Hello","accountId":"1-599K"},{"contactId":"1-31MAU","firstName":"Venkat","lastName":"Gottipati","accountId":"1-599K"},{"contactId":"B-2-257Q1.1261","firstName":"James","lastName":"Wiley","accountId":"1-599K"},{"contactId":"B-C-2G46CL","firstName":"Rachita","lastName":"Ahanthem","accountId":"1-599K"},{"contactId":"B-3-Y8TSH","firstName":"Kapil","lastName":"Chhabra","accountId":"1-599K"},{"contactId":"B-C-JDVKX","firstName":"Pablo","lastName":"Onnias","accountId":"1-599K"},{"contactId":"B-4-1I7B1D","firstName":"Avinash","lastName":"Najat","accountId":"1-599K"},{"contactId":"1-1Y770","firstName":"Jonathan","lastName":"Landis","accountId":"1-599K"},{"contactId":"B-3-1XBL7D","firstName":"Geetha","lastName":"Chandran","accountId":"1-599K"},{"contactId":"B-3-1AWSSR","firstName":"Joshua","lastName":"Buresh-Oppenheim","accountId":"1-599K"},{"contactId":"B-3-ASEZG3","firstName":"Mahalakshmi","lastName":"Yuvaraj","accountId":"1-599K"}]}]}]');
            res.setStatusCode(200);
        }
            return res;
        }
        
    }
    
    global class GetRoleDetailsNegative implements HttpCalloutMock{
        global HTTPResponse respond(HTTPRequest req) {
            
            ManagedPkgErrorClass.isFromManagedPackage = false;
            
            String endPoint = req.getEndpoint();
            String httpMethod = req.getMethod();
            HttpResponse res = new HttpResponse();
            System.runAs(utilTestClass.getTestRunUser())
        {
            System.assertEquals('GET', httpMethod);
            res.setBody('<div>500 - Application Error!</div>');
            res.setStatusCode(500);
        }
            return res;
        }
        
    }
    
    global class ValidatePhonePositive implements HttpCalloutMock{
        global HTTPResponse respond(HTTPRequest req) {
            
            ManagedPkgErrorClass.isFromManagedPackage = false;
            
            String endPoint = req.getEndpoint();
            String httpMethod = req.getMethod();
            HttpResponse res = new HttpResponse();
            System.runAs(utilTestClass.getTestRunUser())
        {
            System.assertEquals('GET', httpMethod);
            res.setBody('{"phoneNo":"1234567890","valid":"true","formattedPhoneNo":"(123) 456-7890"}');
            res.setStatusCode(200);
        }
            return res;
        }
        
    }
    
    global class ValidatePhoneNegative implements HttpCalloutMock{
        global HTTPResponse respond(HTTPRequest req) {
            
            ManagedPkgErrorClass.isFromManagedPackage = false;
            
            String endPoint = req.getEndpoint();
            String httpMethod = req.getMethod();
            HttpResponse res = new HttpResponse();
            System.runAs(utilTestClass.getTestRunUser())
        {
            System.assertEquals('GET', httpMethod);
            res.setBody('{"phoneNo":"123456","valid":"false","formattedPhoneNo":null}');
            res.setStatusCode(200);
        }
            return res;
        }
        
    }
    
    /*
        @Author: Pranav
        @Description: Let's have a map of request types and responses. Eg ->
            'getUser_Positive':{
                'StatusCode':'200',
                'HttpMethod':'GET',
                'Body': '{"phoneNo":"123456","valid":"false","formattedPhoneNo":null}'
            }
    
    */
    global static Object getResponseMap(HTTPRequest req, Boolean positiveTest){
        
        Object respObj = new Map<String, Object>();
        //TODO: Need Logic to differentiate.
        System.runAs(utilTestClass.getTestRunUser())
        {
        if(req.getMethod() == 'GET'){
            if(positiveTest){
                if(req.getEndpoint().indexOf('/admin/ws/v1/users/') >0){
                    respObj = GetUser_Positive();
                } else if(req.getEndpoint().indexOf('/admin/ws/{version}/search?keyword=') >0){
                    //respObj = SearchUser_Positve();
                } else if(req.getEndpoint().indexOf('/roles') >0){
                    //respObj = SearchUser_Positve();
                }
                
            } else {
                
            }
            
        } else if(req.getMethod() == 'PUT'){
            
        } else if(req.getMethod() == 'POST'){
            
        }
        }
        return respObj;
        
        
    }
    
    global static Object GetUser_Positive(){
        
        Map<String, Object> responseMap = new Map<String, Object>();
        System.runAs(utilTestClass.getTestRunUser())
        {
        responseMap.put('StatusCode',200);
        responseMap.put('HttpMethod','GET');
        responseMap.put('Body','{"contactId":"B-3-10ID257","firstName":"test","lastName":"test","username":"test","email":"test@akamai.com","roleAssignments":[{"roleId":14,"roleName":"NAP SSO only","roleDescription":"This role provides the maximum access to users. An Administrator can perform admin tasks such as creating users and groups; configuration-related tasks such as creating and editing configurations; publishing tasks","groupId":18385,"groupName":"Akamai Technologies - Assets-1-3CV382"}],"phone":"111111111","timezone":"GMT","accountId":"1-599K"}');
        
        }
        return (Object)responseMap;
        
    }
    
    
    global class generateResponse_Positive implements HttpCalloutMock{
        global HTTPResponse respond(HTTPRequest req) {
            
            ManagedPkgErrorClass.isFromManagedPackage = false;
            
            String endPoint = req.getEndpoint();
            String httpMethod = req.getMethod();
            HttpResponse res = new HttpResponse();
            Map<String, Object> responseMap  = (Map<String, Object>)getResponseMap(req,true);
            System.runAs(utilTestClass.getTestRunUser())
        {
            System.assertEquals(httpMethod,(String)responseMap.get('HttpMethod'));
            
            res.setBody((String)responseMap.get('Body'));
            res.setStatusCode((Integer)responseMap.get('StatusCode'));
        }
            return res;
        }
        
    }
    
    global class generateResponse_Negative implements HttpCalloutMock{
        global HTTPResponse respond(HTTPRequest req) {
            
            ManagedPkgErrorClass.isFromManagedPackage = false;
            
            String endPoint = req.getEndpoint();
            String httpMethod = req.getMethod();
            HttpResponse res = new HttpResponse();
            Map<String, Object> responseMap  = (Map<String, Object>)getResponseMap(req,false);
            System.runAs(utilTestClass.getTestRunUser())
        {
            System.assertEquals(httpMethod,(String)responseMap.get('HttpMethod'));
            res.setBody((String)responseMap.get('Body'));
            res.setStatusCode((Integer)responseMap.get('StatusCode'));
        }
            return res;
        }
        
    }
    
    /*
    global class CreateUserAndResetPasswordPositive implements HttpCalloutMock{
        global Map<String, HttpCalloutMock> requests;
        
        
        private String selectCorrectMockType(String requestEndpoint){
            /*  
                -   Create a Map request and response
                -   select the correct response by grep'ing the request.
            requests = new Map<String, HttpCalloutMock>();
            
            requests.put('getUser',new MockHttpResponseGenerator.GetUserPositive());
            
            return requests.get('getUser');
            
        }
        /*
        global CreateUserAndResetPasswordPositive(){
            // Create {'request_type'=>'{"response":"json"}'} Maps
            
            HttpCalloutMock createUser = new MockHttpResponseGenerator.CreateUserPositive();
            this.requests.put('create_user',createUser);
        }
        
        global void addRequestMock(String url, HttpCalloutMock mock) {
            this.requests.put(url, mock);
        }
        
        global HTTPResponse respond(HTTPRequest req) {
            String mockType = selectCorrectMockType(req.getEndpoint());
            HttpCalloutMock mock = requests.get(mockType);
            if (mock != null) {
                return mock.respond(req);
            } else {
                //throw 'HTTP callout not supported for test methods';
            }
        }
    }
    
    */
}