@RestResource(urlMapping='/Akanova/v1/Concepts/*')
global with sharing class ConceptUtilClass {
    @HttpGet
    global static List<Concept__c> doGet() {
        RestRequest req = RestContext.request;
        List<String> reqURIArr = req.requestURI.split('/');
		String conceptId = reqURIArr[reqURIArr.size()-3];
        Integer limitvar = integer.valueof(reqURIArr[reqURIArr.size()-2]);
        Integer offsetvar = integer.valueof(reqURIArr[reqURIArr.size()-1]);
        List<Concept__c> allConcepts = new List<Concept__c>();
        if(conceptId != null && !conceptId.equalsIgnoreCase('all')){
            allConcepts = [Select Id, Concept_Owner__r.Name, Owner_Name__c, Name, Concept_Status__c,Concept_Description__c,  Problem__c, implementationPlan__c, SuccessDetails__c, Resources__c, Challenges__c, Timelines_for_implementation__c, Total_Dislikes__c, Total_Likes__c, Project_Details__c, CreatedDate from Concept__c  where Id =:conceptId];
        } else if(conceptId.equalsIgnoreCase('all')) {
            allConcepts = [Select Concept_Owner__c,Concept_Owner__r.Name, Owner_Name__c,Concept_Status__c,Concept_Description__c, Name,Problem__c, Total_Dislikes__c , Total_likes__c  ,Team_Members__c, createdDate, Project_Status__c from Concept__c order by CreatedDate desc limit :limitVar Offset:offsetVar	];
        } else {
            allConcepts = null;
        }
        return allConcepts;
    }
    @HttpPost
     global static Response SaveConcept()
    {   
        try {
        RestRequest req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');
        String jsonResponse = '';
       	Concept__c con1 = (Concept__c)JSON.deserialize(req.requestBody.toString(), sObject.class);
        System.debug('con1 :: ' + con1);
        if (con1.Id == null) {
            con1.Concept_Owner__c = getUserId(con1.Owner_Name__c);
        }
        //con1.Concept_Owner__c = getUserId(con1.Owner_Name__c);
        
        Database.UpsertResult result = Database.Upsert(con1, Schema.Concept__c.Id, false);
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
             Error_Log__c auditConceptError = new Error_Log__c(Name='Concept saving', Class__c='ConceptUtilClass.SaveConcept', Error_Message__c='concept Details errpr' + ex.getMessage());
            insert auditConceptError;
            Response resobj1 = new Response();
            resobj1.errormessage = ex.getMessage();
            return resobj1;
        }
    }
    global class Response
    {
        webService boolean isSuccess;
        webService Id recordId;
        webService string errormessage;
    }
    public static Id getUserId(String ldap) {
        List<User> usrList = [Select id from User where Alias = :ldap];
        if(usrList!=null && !usrList.isEmpty()) {
            return usrList[0].Id;
        }
        return null;
    }
}