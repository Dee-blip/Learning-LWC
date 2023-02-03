/*
Author          : Tejaswini/Vikas
Description     : Controller for View Open Cases component

Date                    Developer                   JIRA #                      Description                                                       
-------------------------------------------------------------------------------------------------------------------------------------
28 Oct 2021             Tejaswini/Vikas            ESESP-6008                   Initial Development, Controller for ScBpShowCaseModal
--------------------------------------------------------------------------------------------------------------------------------------
*/
public with sharing class SC_BigPanda_Case_Modal_Ctrl {
    
    public class CaseWrapper{   
        @AuraEnabled public Id Id;
        @AuraEnabled public String akamCaseId;
        @AuraEnabled public String caseUrl;
        @AuraEnabled public String policyDomain;
        @AuraEnabled public String pdUrl;
        @AuraEnabled public String subject;
        @AuraEnabled public String problem;
        @AuraEnabled public String severity;
        @AuraEnabled public String accountName;       
        @AuraEnabled public String accountUrl;
        @AuraEnabled public String lastUpdated;
        @AuraEnabled public String lastUpdatedBy;
    }

    //Update Bipanda Incident tags
    /*[
    {
      "incidentid":"61801fe7a5856577316698e6",
      "requestBody":[
         {
            "tag_value":"SA",
			"tag_id":"socc_queue",
            "incident_id":"61801fe7a5856577316698e6"
            
         }
      ]
    },
    {
      "incidentid":"618020083daca6767646a592",
      "requestBody":[
         {
            "tag_value":"SA",
			"tag_id":"socc_queue",
            "incident_id":"618020083daca6767646a592"
            
         }
      ]
    }
    ]*/

    //For Incident Tags
    public class IncidentTagRequestBodyWrapper
    {
        public String tag_value;
        public String incident_id;
        public String tag_id;
        public IncidentTagRequestBodyWrapper(String tag_value,String incident_id,String tag_id)
        {
            this.tag_value = tag_value;
            this.incident_id = incident_id;
            this.tag_id = tag_id;
        }
    }
    public class IncidentTagWrapper
    {
        public String incidentid;
        public List<IncidentTagRequestBodyWrapper> requestBody;
        public IncidentTagWrapper(String incidentid,List<IncidentTagRequestBodyWrapper> incidentTagRequestBodyWrapper)
        {
            this.incidentid = incidentid;
            this.requestBody = incidentTagRequestBodyWrapper;
        }
    }

    /*Request body format : [   
    {
        "incident_id":"6188fefdfe11552e545f08c4",
        "postbody":{
            "comments ":"test1"
        }
    },
    {
        "incident_id":"6188f8275c1aa33de19a0abe",
        "postbody":{
            "resolved ":true
        }
    }
    
    ] */

    public class ResolveIncidentRequestBodyWrapper
    {
        public Boolean resolved;
        public String comments;
        public ResolveIncidentRequestBodyWrapper(Boolean resolved,String comments)
        {
            this.resolved = resolved;
            this.comments = comments;
        }
    }
    public class ResolveIncidentWrapper
    {
        public String incident_id;
        //public List<ResolveIncidentRequestBodyWrapper> postbody;
        public ResolveIncidentRequestBodyWrapper postbody;
        //public ResolveIncidentWrapper(String incident_id,List<ResolveIncidentRequestBodyWrapper> resolveIncidentRequestBodyWrapper)
        public ResolveIncidentWrapper(String incident_id,ResolveIncidentRequestBodyWrapper resolveIncidentRequestBodyWrapper)
        {
            this.incident_id = incident_id;
            this.postbody = resolveIncidentRequestBodyWrapper;
        }
    }
    
    public class CommentIncidentRequestBodyWrapper
    {
        public String comments;
        
        public CommentIncidentRequestBodyWrapper(String comments)
        {
            this.comments = comments;
        }
    }
    public class CommentIncidentWrapper
    {
        public String incident_id;
        //public List<CommentIncidentRequestBodyWrapper> postbody;
        public CommentIncidentRequestBodyWrapper postbody;
        //public CommentIncidentWrapper(String incident_id,List<CommentIncidentRequestBodyWrapper> commentIncidentRequestBodyWrapper)
        public CommentIncidentWrapper(String incident_id,CommentIncidentRequestBodyWrapper commentIncidentRequestBodyWrapper)
        {
            this.incident_id = incident_id;
            this.postbody = commentIncidentRequestBodyWrapper;
        }
    }

    
    /*public static String getAccessToken(){

        SC_Utility__mdt  mdt = SC_Utility__mdt.getInstance('BigPanda_Client_Scope');
        String  scope = mdt.Value__c;
        System.debug('the scope is: '+scope);
        Http http = new Http();
        HttpRequest request = new HttpRequest();         
        HttpResponse response = new HttpResponse();           
        //create the Http Request
       	request.setEndpoint('callout:Mule_Access_Token' + '/oauth2/token');
        request.setMethod('GET');
        request.setHeader('client_id', '{!$Credential.UserName}');
        request.setHeader('client_secret', '{!$Credential.Password}');
        request.setHeader('Content-Type','application/json');
        request.setHeader('grant_type', 'client_credentials');
        request.setHeader('scope', scope);        
        system.debug('request : '+request);   
        //Get the response
        response = http.send(request);  
        system.debug('response : '+response);    
        Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());  
        System.debug('the results are: '+results);
        String accessToken = (String) results.get('access_token');   
        system.debug('accessToken : '+accessToken);

        return accessToken;
    }*/

    @AuraEnabled
    public static List<CaseWrapper> getAllCaseRecs(String akamAccountId,String caseSeverity, String caseProblem)
    {
        String sevQuery = '';
        String problemQuery = '';

        System.debug('akamAccountId');
        System.debug(akamAccountId);
        String caseQuery = 'Select Id,AKAM_Case_ID__c,Policy_Domain__r.Name,Policy_Domain__r.Id,Subject,Problem__c,Severity__c,Account.Name,Account.Id,AKAM_Modified_Date__c,AKAM_Modified_By__c from Case where Account.AKAM_Account_ID__c =:akamAccountId AND Status!=\'closed\' AND RecordType.Name=\'Managed Security\'';
        System.debug('caseSeverity: '+caseSeverity);

        if(!caseSeverity.equalsIgnoreCase('1,2,3,4')) 
        {
            List<String> sevVals = caseSeverity.split(',');
            sevQuery = ' AND Severity__c IN :sevVals';
        }
        
        if(!caseProblem.equalsIgnoreCase('all')) 
        {
            List<String> problemVals = caseProblem.split(',');
            problemQuery = ' AND Problem__c IN :problemVals';
        }
        caseQuery += sevQuery + problemQuery;
        System.debug('the query is: '+caseQuery);
        List<Case> lCase = new List<Case>();
        lCase = Database.query(caseQuery);

        //List<Case> lCase=[Select Id,AKAM_Case_ID__c,Policy_Domain__r.Name,Policy_Domain__r.Id,Subject,Problem__c,Severity__c,Account.Name,Account.Id,AKAM_Modified_Date__c,AKAM_Modified_By__c from Case where Account.AKAM_Account_ID__c =:akamAccountId AND Status !='closed' AND RecordType.Name='Managed Security' ];
        List<CaseWrapper> lCaseWrapper = new List<CaseWrapper>();
        for(Case c:lCase)
        {
            CaseWrapper cw = new CaseWrapper();
            cw.Id=c.Id;
            cw.caseUrl='/lightning/r/Case/'+c.Id+'/view';
            cw.akamCaseId = c.AKAM_Case_ID__c;
            cw.subject=c.subject;
            cw.problem=c.Problem__c;
            cw.severity = c.Severity__c;
            cw.lastUpdated = (c.AKAM_Modified_Date__c).format();
            cw.lastUpdatedBy = c.AKAM_Modified_By__c;


            System.debug('the case account name is');
            System.debug(c.Account.Name);
            cw.accountName=c.Account.Name;

            System.debug('the case AccountId is');
            System.debug(c.Account.Id);
            cw.accountUrl='/lightning/r/Account/'+c.Account.Id+'/view';

            if(c.Policy_Domain__r.Id!=null)
            {
                cw.policyDomain = c.Policy_Domain__r.Name;
                cw.pdUrl='/lightning/r/Policy_Domain__c/'+c.Policy_Domain__r.Id+'/view';
            }

            lCaseWrapper.add(cw);

        }

        System.debug('The case details are');
        System.debug(lCaseWrapper);
        return lCaseWrapper;
    }

    @AuraEnabled
    public static List<Id> createLogObjectRec(String incidentId,String operation,String caseId){
        System.debug('The api operations is: '+operation);
        Id sfbpLogId;
        Id sfbpLogId1;
        List<Id> lLogRecId = new List<Id>();

        Id recordTypeId = Schema.SObjectType.Salesforce_BigPanda_Log__c.getRecordTypeInfosByName().get('Outbound Request').getRecordTypeId();
    
        //String accessToken /*= SC_BigPanda_Connector.getAccessToken()*/;
        String bpEndPoint;
        String incidentBpEndPoint;
        String method;

        String requestBody;
        String commentBody;

        String accName;
        String problem;
        Id cId;

        if(operation.equalsIgnoreCase('Get Incident'))
        {
            SC_Utility__mdt  mdt1 = SC_Utility__mdt.getInstance('BigPanda_Get_Incident_URL');
            bpEndPoint = mdt1.Value__c + incidentId;
            System.debug('the bpEndPoint is: '+bpEndPoint);
            //bpEndPoint ='https://qa.fabric.dash-ext.akadevqa.com/socc-aim-api/v1/incidents/'+incidentId;
            method='GET';
        }
        else if(operation.equalsIgnoreCase('Update Incident Tags'))
        {
            List<Case> lc=[Select Id,Account.Name,Problem__c from Case where Akam_Case_Id__c=:caseId Limit 1];
            System.debug('the list of case is: '+lc);
            
            for(Case c:lc)
            {
                accName = c.Account.Name;
                problem=c.Problem__c;
                cId=c.Id;
            } 

            SC_Utility__mdt  mdt2 = SC_Utility__mdt.getInstance('BigPanda_Post_Incident_Tags_URL');
            bpEndPoint = mdt2.Value__c ;
            System.debug('the bpEndPoint is: '+bpEndPoint);
            //bpEndPoint ='https://qa.fabric.dash-ext.akadevqa.com/socc-aim-api/v1/incidentTags';
            method='POST';

            List<IncidentTagWrapper> incidentTagWrapperList = new List<IncidentTagWrapper>();

            List<IncidentTagRequestBodyWrapper> incidentTagRequestBodyWrapperList = new List<IncidentTagRequestBodyWrapper>();
            IncidentTagRequestBodyWrapper incidentTagRequestBodyCaseId = new IncidentTagRequestBodyWrapper(caseId,incidentId,'case_id');
            incidentTagRequestBodyWrapperList.add(incidentTagRequestBodyCaseId);

            //String caseUrl='https://akamai--gssdevaug.lightning.force.com/lightning/r/Case/'+cId+'/view';   
            String caseUrl= URL.getSalesforceBaseUrl().toExternalForm()+'/lightning/r/Case/'+cId+'/view';      
            IncidentTagRequestBodyWrapper incidentTagRequestBodyCaseUrl = new IncidentTagRequestBodyWrapper(caseUrl,incidentId,'case_url');    
            incidentTagRequestBodyWrapperList.add(incidentTagRequestBodyCaseUrl);

            if(problem=='Specialist')
            {
                IncidentTagRequestBodyWrapper incidentTagRequestBodySoccQueue = new IncidentTagRequestBodyWrapper('SA',incidentId,'socc_queue');    
                incidentTagRequestBodyWrapperList.add(incidentTagRequestBodySoccQueue);

                List<CommentIncidentWrapper> commentIncidentWrapperList = new List<CommentIncidentWrapper>();
                CommentIncidentRequestBodyWrapper commentIncidentRequestBody = new CommentIncidentRequestBodyWrapper('The case is escalated in Salesforce');
                CommentIncidentWrapper commentIncidentWrapper = new CommentIncidentWrapper(incidentId,commentIncidentRequestBody);
                commentIncidentWrapperList.add(commentIncidentWrapper);

                commentBody = JSON.serialize(commentIncidentWrapperList);

                SC_Utility__mdt  mdt3 = SC_Utility__mdt.getInstance('BigPanda_Post_Incident_URL');
                incidentBpEndPoint = mdt3.Value__c;
                System.debug('the bpEndPoint is: '+incidentBpEndPoint);
                //incidentBpEndPoint ='https://qa.fabric.dash-ext.akadevqa.com/socc-aim-api/v1/incidents';

            }
        
            IncidentTagWrapper incidentTagWrapper = new IncidentTagWrapper(incidentId,incidentTagRequestBodyWrapperList);

            incidentTagWrapperList.add(incidentTagWrapper);

            requestBody = JSON.serialize(incidentTagWrapperList);
        }
        System.debug('the bpEndPoint is: '+bpEndPoint);       
        
        List<Salesforce_BigPanda_Log__c> lSfbpLog = new  List<Salesforce_BigPanda_Log__c>();
        Salesforce_BigPanda_Log__c sfbpLog = new Salesforce_BigPanda_Log__c();
        sfbpLog.RecordTypeId = recordTypeId;
        sfbpLog.Incident_Id__c = incidentId;
        sfbpLog.Request_Endpoint__c = bpEndPoint;
        sfbpLog.Request_Method__c = method;
        sfbpLog.Request_Body__c = requestBody;
       
        if(operation.equalsIgnoreCase('Get Incident'))
        {
            sfbpLog.Do_Not_Retry__c = true;
            sfbpLog.Flow_Name__c = 'get_incidentsSub_Flow';
            sfbpLog.Action__c = operation ;
        }
        else{
            sfbpLog.Do_Not_Retry__c = false;
            sfbpLog.Flow_Name__c = 'post_incidentTagsSub_Flow';
            sfbpLog.Action__c = 'Case Association';
        }
        sfbpLog.Number_of_Tries__c = 1;

        lSfbpLog.add(sfbpLog);

        Salesforce_BigPanda_Log__c sfbpLog1 = new Salesforce_BigPanda_Log__c();

        if(operation.equalsIgnoreCase('Update Incident Tags') && problem=='Specialist')
        {
            
            sfbpLog1.RecordTypeId = recordTypeId;
            sfbpLog1.Incident_Id__c = incidentId;
            sfbpLog1.Request_Endpoint__c = incidentBpEndPoint;
            sfbpLog1.Request_Method__c = method;
            sfbpLog1.Request_Body__c = commentBody;
            sfbpLog1.Do_Not_Retry__c = false;
            sfbpLog1.Number_of_Tries__c = 1;
            sfbpLog1.Action__c = 'Case Association';
            sfbpLog1.Flow_Name__c = 'post_incidentsSub_Flow';
            lSfbpLog.add(sfbpLog1);
        }
        try{
            //insert sfbpLog;
            insert lSfbpLog;
            System.debug('the id of 1st Salesforce_BigPanda_Log__c record is: '+lSfbpLog[0].Id);
            sfbpLogId = lSfbpLog[0].Id;
            lLogRecId.add(sfbpLogId);
            //sendEmailLogRecId(bpEndPoint,sfbpLogId);
            if(lSfbpLog.size()>1)
            {
                System.debug('the id of 2nd Salesforce_BigPanda_Log__c record is: '+lSfbpLog[1].Id);            
                sfbpLogId1 = lSfbpLog[1].Id;
                lLogRecId.add(sfbpLogId1);
                //sendEmailLogRecId(incidentBpEndPoint,sfbpLogId1);
            }
            
        }catch(Exception e)
        {
            System.debug('The following exception has occurred: ' + e.getMessage());
        }
        
        if(sfbpLogId!=null && !Test.isRunningTest())
        {
            System.enqueueJob(new SC_BigPandaAPI(bpEndPoint, method,requestBody, sfbpLog));
        }
        if(sfbpLogId1!=null && !Test.isRunningTest())
        {
            System.enqueueJob(new SC_BigPandaAPI(incidentBpEndPoint, method,commentBody, sfbpLog1));
        }

        return lLogRecId;
        
    }

    @AuraEnabled
    public static string getAccountIdFromLogObject(List<Id> recordId){

        String accountId;
        //String accountId;
        Salesforce_BigPanda_Log__c lLogRecs = [Select Id,Response_Status_Code__c,Response_Body__c,Status__c,Number_of_Tries__c from Salesforce_BigPanda_Log__c where Id in :recordId limit 1];
        if(lLogRecs.Response_Status_Code__c == 200 && lLogRecs.Status__c=='Success')
        {
            String body= lLogRecs.Response_Body__c;
            Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(body);
            accountId = (String)results.get('message');
        }
       else if(lLogRecs.Response_Status_Code__c != 200 ){
            accountId ='SOMETHING WENT WRONG, PLEASE RETRY THE REQUEST';
       }
       
        System.debug('the account id is: '+accountId);
        return accountId;
       
    }

    @AuraEnabled
    public static string getStatusOfLogRecord(List<Id> recordId){
        Id rec1;
        Id rec2;
        
        System.debug('the 1st log record id is');
        System.debug(recordId[0]);
        rec1 = recordId[0];
        if(recordId.size()>1)
        {
            System.debug('the 2nd log record id is');
            System.debug(recordId[1]);
            rec2 = recordId[1];
        }
        String successCodes = [SELECT Value_Text__c FROM SC_Utility__mdt WHERE MasterLabel = 'BigPanda_Success_Code' LIMIT 1].Value_Text__c;

        String status;
        Salesforce_BigPanda_Log__c lLogRecs1 = [Select Id,Response_Status_Code__c,Response_Body__c,Status__c,Number_of_Tries__c from Salesforce_BigPanda_Log__c where Id=:rec1 limit 1];
        Salesforce_BigPanda_Log__c lLogRecs2;
        if(rec2!=null)
        {
            lLogRecs2 = [Select Id,Response_Status_Code__c,Response_Body__c,Status__c,Number_of_Tries__c from Salesforce_BigPanda_Log__c where Id=:rec2 limit 1];
        }
        
        Boolean gotStatusCode=false;
        if(rec2==null && lLogRecs1.Response_Status_Code__c!=null)
        {
            gotStatusCode = true;
        }
        else if(rec2!=null)
        {
            if(lLogRecs1.Response_Status_Code__c!=null && lLogRecs2.Response_Status_Code__c!=null)
            {
                gotStatusCode = true;
            }
        }

        String checkSuccessCode;
        if(rec2==null && successCodes.contains(String.valueOf(lLogRecs1.Response_Status_Code__c)))
        {
            checkSuccessCode='success';
        }
        else if(rec2!=null)
        {
            if(successCodes.contains(String.valueOf(lLogRecs1.Response_Status_Code__c)) || successCodes.contains(String.valueOf(lLogRecs2.Response_Status_Code__c))){
                checkSuccessCode='success';
            }
        }

        System.debug('the value of gotStatusCode is: '+gotStatusCode);
        System.debug('the value of checkSuccessCode is: '+checkSuccessCode);
        
        if(gotStatusCode)
        {
            if(checkSuccessCode.equalsIgnoreCase('Success'))
            {
                status='Success';           
            }
            else
            {
                status='Failed';
            }            
        }
        
        return status;
    }

    //Form the postString to update Incident on Bigpanda
    public static String getIncidentWrapper(List<BP_Incident__c> lBPIncident,String operation)
    {
        //List<BP_Incident__c> lBPIncident = [Select Incident_Id__c,Case__r.AKAM_Case_ID__c from BP_Incident__c where Case__c=:caseId];
        String postString;
        if(lBPIncident.size()>0)
        {	
            if(operation.equalsIgnoreCase('Case Escalation')){
                
                List<CommentIncidentWrapper> commentIncidentWrapperList = new List<CommentIncidentWrapper>();
                for(BP_Incident__c bpincident:lBPIncident)
                {  
                    //List<CommentIncidentRequestBodyWrapper> commentIncidentRequestBodyWrapperList = new List<CommentIncidentRequestBodyWrapper>();
                    //String comment = 'The case '+bpincident.Case__r.AKAM_Case_ID__c+' is escalated in Salesforce' ;
                    CommentIncidentRequestBodyWrapper commentIncidentRequestBody = new CommentIncidentRequestBodyWrapper('The case is escalated in Salesforce');
                    CommentIncidentWrapper commentIncidentWrapper = new CommentIncidentWrapper(bpincident.Incident_Id__c,commentIncidentRequestBody);
                    commentIncidentWrapperList.add(commentIncidentWrapper);
                }
                postString = JSON.serialize(commentIncidentWrapperList);
            }    
        
            else if(operation.equalsIgnoreCase('Case Close')){
            
                List<ResolveIncidentWrapper> resolveIncidentWrapperList = new List<ResolveIncidentWrapper>();
                for(BP_Incident__c bpincident:lBPIncident)
                {                
                    //List<ResolveIncidentRequestBodyWrapper> resolveIncidentRequestBodyWrapperList = new List<ResolveIncidentRequestBodyWrapper>();
                    ResolveIncidentRequestBodyWrapper resolveIncidentRequestBody = new ResolveIncidentRequestBodyWrapper(true,'The case is closed in Salesforce');
                    ResolveIncidentWrapper resolveIncidentWrapper = new ResolveIncidentWrapper(bpincident.Incident_Id__c,resolveIncidentRequestBody);
                    resolveIncidentWrapperList.add(resolveIncidentWrapper);
                }
                postString = JSON.serialize(resolveIncidentWrapperList);
            }
        }
        System.debug('PostString is: '+postString);

        return postString;
    }

    public static String getIncidentTagWrapper(List<BP_Incident__c> lBPIncident)
    {
        String postString;
        if(lBPIncident.size()>0)
        {
            List<IncidentTagWrapper> incidentTagWrapperList = new List<IncidentTagWrapper>();
        
            for(BP_Incident__c bpincident:lBPIncident)
            {
                List<IncidentTagRequestBodyWrapper> incidentTagRequestBodyWrapperList = new List<IncidentTagRequestBodyWrapper>();
                IncidentTagRequestBodyWrapper incidentTagRequestBody = new IncidentTagRequestBodyWrapper('SA',bpincident.Incident_Id__c,'socc_queue');
                incidentTagRequestBodyWrapperList.add(incidentTagRequestBody);
                IncidentTagWrapper incidentTagWrapper = new IncidentTagWrapper(bpincident.Incident_Id__c,incidentTagRequestBodyWrapperList);
                incidentTagWrapperList.add(incidentTagWrapper);                
            }
            postString = JSON.serialize(incidentTagWrapperList);

            System.debug('the final request body for incident tags update is:  '+postString);
        }
        return postString;
    }
    
    
    @AuraEnabled
    public static string getLogStatus(String uniqueIdentifierText){
        String status = null;
        try{
            system.debug('uniqueIdentifierText : '+uniqueIdentifierText);
            String uniqueText = '%'+uniqueIdentifierText+'%';
            system.debug('uniqueText : '+uniqueText);
            Salesforce_BigPanda_Log__c logRec;
            //5001h0000067TtFAAU-Case Escalation
            String caseId = uniqueIdentifierText.substringBefore('-');
            String actionName = uniqueIdentifierText.substringAfter('-');
            logRec = [Select Id,Response_Status_Code__c,Response_Body__c,Status__c,Number_of_Tries__c from Salesforce_BigPanda_Log__c where do_not_retry__c = false AND Case_Id__c = :caseId AND Action__c = :actionName/*Unique_Identifier__c like: uniqueText*/ order by createddate desc limit 1];
            if(logRec != null && String.isNotBlank(logRec.Status__c )){
                status = logRec.Status__c;
            }
            system.debug('logRec.Status__c : '+logRec.Status__c);
            return status; 
        }
        catch(exception e){
            return status;
        }
    }
    
}