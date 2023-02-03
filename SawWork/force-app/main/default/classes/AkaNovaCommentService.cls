@RestResource(urlMapping='/Akanova/v1/Comments/*')
global with sharing class AkaNovaCommentService {
    @HttpGet
    global static List<Akanova_Comment__c> doGet() {
        RestRequest req = RestContext.request;
        String conceptId = req.requestURI.substring(req.requestURI.lastIndexOf('/')+1);
        List<Akanova_Comment__c > allComments = new List<Akanova_Comment__c >();
        if(conceptId != null){
            allComments = [Select Id,Comment_Body__c,Comment_Created_Date__c,Comment_Owner__c,CommentOwner__r.Name  from Akanova_Comment__c where Concept__c =:conceptId and Deleted__c = false order by Comment_Created_Date__c desc];
        } else {
            allComments = null;
        }
        return allComments;
    }
    
     @HttpPost
     global static Response SaveComment()
    {   
        try {
            RestRequest req = RestContext.request;
            RestResponse res = RestContext.response;
            res.addHeader('Content-Type', 'application/json');
            System.debug('Request : ' + req.requestBody.toString());
            String jsonResponse = '';
            Akanova_Comment__c comm = (Akanova_Comment__c)JSON.deserialize(req.requestBody.toString(), sObject.class);
            System.debug('com1 :: ' + comm);
            comm.CommentOwner__c = getUserId(comm.Comment_Owner__c);
            comm.Comment_Created_Date__c = System.Datetime.now();
            
            Database.UpsertResult result = Database.Upsert(comm, Schema.Akanova_Comment__c.Id, false);
            Response resobj = new Response();
            resobj.isSuccess = result.isSuccess();
            resobj.recordId = result.getId();
            if(!result.isSuccess())
            {
                resobj.errormessage = result.getErrors()[0].getMessage();
            }
            System.debug('Here :: ' + resobj);
            return resobj;
        } catch (Exception ex) {
            Error_Log__c auditConceptError = new Error_Log__c(Name='Comment saving', Class__c='AkaNovaCommentService.SaveComment', Error_Message__c='comment Details error' + ex.getMessage());
            insert auditConceptError;
            Response resobj1 = new Response();
            resobj1.errormessage = ex.getMessage();
            System.debug('error :' + ex.getMessage());
            return resobj1;
        }
    }
     public static Id getUserId(String ldap) {
        List<User> usrList = [Select id from User where Alias = :ldap];
        if(usrList!=null && !usrList.isEmpty()) {
            return usrList[0].Id;
        }
        return null;
    }
    global class Response
    {
        webService boolean isSuccess;
        webService Id recordId;
        webService string errormessage;
    }
}