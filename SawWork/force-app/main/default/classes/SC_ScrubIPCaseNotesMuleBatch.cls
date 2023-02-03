/*-------------------------------------------------------------------------------------------------------------
 * Class Name           : SC_ScrubIPCaseNotesMuleBatch
 * Developer Name       : Kunal Sharma
 * Date                 : 22 March 2018
 * JIRA                 : FFPSA-988
 * Description          : Batch class to update Notes records using Mule API.
 -------------------------------------------------------------------------------------------------------------*/ 

global class SC_ScrubIPCaseNotesMuleBatch implements Database.Batchable<sObject>, Database.stateful, Database.AllowsCallouts{
	//This will store the Error Message from support class
    Public string errorMessage = '' ;
    
    //Access Token from Mule
    Public String accessToken = '';
    
    //Record type ID
    Id recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        
    //This will store the Query for the batch class
    Public string caseQuery;
    
    //This will store the Query for the test class 
    Public string caseQuery_Test;
    
    public SC_ScrubIPCaseNotesMuleBatch(){
        caseQuery_Test =    'SELECT Subject, Description, Issue_Summary__c, Troubleshooting_to_Date__c, Data_Collected__c,' + 
                            'Customer_Expectations__c, Next_Action_Recommendation__c, Solution_Summary__c, Root_Cause__c  ' +
                            'FROM Case WHERE RecordTypeId=\''+ recTypeId + '\' AND Isclosed = True AND Is_IP_Scrubbed__c = False ' +
                            'ORDER BY CreatedDate desc Limit 10';
    
        //Get the settings for scrubbing of IP Address
        SC_Scrub_IP_Addresses_Setting__mdt scrubIPSettings = [SELECT Implementation_Date__c,Is_Active__c ,No_of_days__c FROM SC_Scrub_IP_Addresses_Setting__mdt WHERE DeveloperName = 'Technical'];
        
        //If Scrubbing Process is active
        if(scrubIPSettings.Is_Active__c == true){
            
            //Get the Effective Start Date
            DateTime implementationDate = scrubIPSettings.Implementation_Date__c;
                
            //Consider the cases for scrubbing 7 days after the case closure
            DateTime considerationDate = (DateTime.now() - Integer.valueOf(scrubIPSettings.No_of_days__c)).dateGMT();
                
            //Closed date should be greater that implemention date and closed date should lesser than or equal to consideration date
            //(Lesser than is required because to pick the cases for the failed batch job)
            caseQuery =     'SELECT Id, Subject, Description, Issue_Summary__c, Troubleshooting_to_Date__c, Data_Collected__c,' + 
                            'Customer_Expectations__c, Next_Action_Recommendation__c, Solution_Summary__c, Root_Cause__c  ' +
                            'FROM Case WHERE RecordTypeId=\''+ recTypeId + '\' AND Isclosed = True AND Account.SC_IP_Scrubbing__c = true AND Is_IP_Scrubbed_On_Notes__c = false' + 
                            ' AND ClosedDate >= '+ implementationDate.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'') +
                            ' AND ClosedDate <= ' + considerationDate.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        }
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        //Check whether its a test class execution or normal execution
        string batchQuery = (System.Test.isRunningTest()) ? caseQuery_Test : caseQuery;
        System.debug('### batchQuery ## ' + batchQuery);
        if(batchQuery != null)
            return Database.getQueryLocator(batchQuery);
        else
            return null;
    }
    
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        Id profileId = [SELECT Id FROM Profile WHERE name = 'System Administrator'].Id;
        SC_IP_Scrub_Admin_Setting__c ipScrub = SC_IP_Scrub_Admin_Setting__c.getInstance(profileId);
        Map<String,Object> mPayloadBody = new Map<String,Object>();
        List<Case> lCasesToUpdate = ( List<Case> ) scope;
        String caseIdsForMule = '';
        setAccessToken(ipScrub);
        for(Case varCase :lCasesToUpdate){
            if(caseIdsForMule == ''){
                //caseIdsForMule = '"';
            }
            
            caseIdsForMule += varCase.Id + ',';
            
        }
        caseIdsForMule = caseIdsForMule.removeEndIgnoreCase(',');
        mPayloadBody.put('caseId', caseIdsForMule);
        //caseIdsForMule += '"';
        
        System.debug('### ### ' + mPayloadBody);
        callIPRemovalAPI(ipScrub, mPayloadBody);
    }
    
    public void callIPRemovalAPI (SC_IP_Scrub_Admin_Setting__c ipScrub, Map<String,Object> mPayloadBody){        
        Http http = new Http();
        HttpRequest request = new HttpRequest();            
        System.debug('### ipScrub ' + ipScrub);
        //System.debug('### JSON.serialize(mPayloadBody) ' + JSON.serialize(mPayloadBody));
        request.setEndpoint(ipScrub.Hostname__c + ipScrub.End_Point_IP_Scrub_Notes__c);
        request.setMethod('POST');        
        request.setBody(JSON.serialize(mPayloadBody));
        request.setHeader('access_token', accessToken);
        request.setHeader('Content-Type','application/json');
        request.setClientCertificateName(ipScrub.Client_Certificate__c);       
        System.debug('## request '+ request + ' $$$$$ ' + request.getBody());
        HttpResponse response = http.send(request);
        if (response.getStatusCode() == 200) {    
        	//Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());    
            //accessToken = (String) results.get('access_token');   
            System.debug('## results '+ response.getBody());
       }
    }
    
    public void setAccessToken(SC_IP_Scrub_Admin_Setting__c ipScrub){        
        if(accessToken == ''){
            Http http = new Http();
            HttpRequest request = new HttpRequest();            
            System.debug('### ipScrub ' + ipScrub);
            request.setEndpoint(ipScrub.Hostname__c + ipScrub.End_Point_OAuth__c );
            request.setMethod('GET');
            request.setHeader('client_id', ipScrub.Client_Id__c);
            request.setHeader('client_secret',ipScrub.Client_Secret__c);
            request.setHeader('content-type','application/x-www-form-urlencoded');
            request.setHeader('grant_type','client_credentials');
            request.setHeader('scope',ipScrub.Scope__c );
            request.setClientCertificateName(ipScrub.Client_Certificate__c);
            HttpResponse response = http.send(request);
            if (response.getStatusCode() == 200) {    
                Map<String, Object> results = (Map<String, Object>) JSON.deserializeUntyped(response.getBody());    
                accessToken = (String) results.get('access_token');   
                System.debug('## access_token '+ accessToken);
            }
        }               
    }
    
     global void finish(Database.BatchableContext BC){
            //if error message is not empty then send email to support email address
            if(errorMessage.length() > 5){
                SC_ScrubAndRemoveIPAddresses.sendEmailforException(errorMessage);
            } 
        
    }
}