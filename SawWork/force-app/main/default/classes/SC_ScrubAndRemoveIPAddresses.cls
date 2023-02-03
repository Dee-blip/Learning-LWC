/*---------------------------------------------------------------------------------
 * Class Name 			: SC_ScrubAndRemoveIPAddresses
 * Class Type 			: Support
 * Parent Class Name 	: SC_Scrub_IP_Batch 
 * Developer Name 		: Aditya Sonam
 * Date 				: 25th April,2017
 * JIRA 				: ESESP-561,ESESP-607
 ---------------------------------------------------------------------------------*/ 

public class SC_ScrubAndRemoveIPAddresses {
    
    //variable to store JSON record after masking all IPs
    public string afterMaskingJSON;
    //Variable to store all IPs for a record which were masked
    public string maskedIpAddresses;
    //variable to store record original JSON
    public string beforeMaskingJSON;
    //string to store Error Message
    public string errorMsg = '';
    //list to store scrubbed case details
    list<SC_Scrubbed_IPs__c> scrubIPObjList = new list<SC_Scrubbed_IPs__c>();
    //list of case id with IP masked
    list<Id> caseIdListForDelAtt = new list<Id>();
 
    //Method to fetch relevant fields from Objects for which IP needs to be masked
    public string scrubIPAddresses(list<Case> caseListForMasking){

        list<Case_Transition__c> caseTransitionList;
        list<Engagement_Request__c> erList;
        list<task> taskList;
        list<EmailMessage> emailMsgList;
        list<FeedItem> caseFeedList;
        list<Attachment> caseAttachment;
        list<Id> caseIdList = new list<Id>();
        
        
        //creating list of case Id
        for(case c:caseListForMasking){
            caseIdList.add(c.Id);
        }
        
        //Getting FeedItem Filter from Custom Metadata
        list<String> feedItemFilterList = new List<String>(([Select FeedItem_Filters__c from SC_Scrub_IP_Addresses_Setting__mdt where developerName = 'Technical' limit 1].FeedItem_Filters__c).split(','));
        //Query to get records 
        if(caseListForMasking != Null && !caseListForMasking.isEmpty()){        
            caseTransitionList 	= new list<Case_Transition__c>([SELECT id,Case__c,Issue_Summary__c,Troubleshooting_to_Date__c,Data_Collected__c,Customer_Expectations__c,Next_Action_Recommendation__c FROM Case_Transition__c  WHERE Case__c IN :caseIdList]);        
            erList 				= new list<Engagement_Request__c>([SELECT id,Case__c,ER_Resolution_Notes__c,Description__c,Steps_to_Reproduce__c, Sample_URLs__c,Additional_Data__c FROM Engagement_Request__c WHERE Case__c IN :caseIdList]);
            taskList 			= new list<task>([SELECT id,WhatId,Subject,Description from task where WhatId IN :caseIdList]);
            caseFeedList 		= new list<FeedItem>([SELECT Id,Body,ParentId,type FROM FeedItem where ParentId IN :caseIdList and type NOT IN :feedItemFilterList]);
        }
                
        // Initailaized list for update
        list<Case> caseListForUpdate						 	= new list<Case>();
        list<Engagement_Request__c> erListForUpdate 			= new list<Engagement_Request__c>();
        list<Case_Transition__c> caseTransitionListForUpdate 	= new list<Case_Transition__c>();
        list<task> taskListForUpdate 							= new list<task>();
        list<FeedItem> caseFeedListForUpdate 					= new list<FeedItem>();
        
        //Creating Savepoint
        Savepoint sp = Database.setSavepoint();
        
        try{
            // Masking and Updating Each Case 
            if(caseListForMasking != Null && !caseListForMasking.isEmpty()){
                for(case eachCase : caseListForMasking){
                    maskedIpAddresses = '';
                    eachCase.Subject = !String.isBlank(eachCase.Subject) ? searchAndReplaceIP(eachCase.Subject) : eachCase.Subject ;
                    eachCase.Description = !String.isBlank(eachCase.Description) ? searchAndReplaceIP(eachCase.Description) : eachCase.Description;
                    eachCase.Issue_Summary__c = !String.isBlank(eachCase.Issue_Summary__c) ? searchAndReplaceIP(eachCase.Issue_Summary__c) : eachCase.Issue_Summary__c;
                    eachCase.Troubleshooting_to_Date__c = !String.isBlank(eachCase.Troubleshooting_to_Date__c) ? searchAndReplaceIP(eachCase.Troubleshooting_to_Date__c) : eachCase.Troubleshooting_to_Date__c;
                    eachCase.Data_Collected__c = !String.isBlank(eachCase.Data_Collected__c) ? searchAndReplaceIP(eachCase.Data_Collected__c) : eachCase.Data_Collected__c;
                    eachCase.Customer_Expectations__c = !String.isBlank(eachCase.Customer_Expectations__c) ? searchAndReplaceIP(eachCase.Customer_Expectations__c) : eachCase.Customer_Expectations__c;
                    eachCase.Next_Action_Recommendation__c = !String.isBlank(eachCase.Next_Action_Recommendation__c) ? searchAndReplaceIP(eachCase.Next_Action_Recommendation__c) : eachCase.Next_Action_Recommendation__c;
                    eachCase.Solution_Summary__c = !String.isBlank(eachCase.Solution_Summary__c) ? searchAndReplaceIP(eachCase.Solution_Summary__c) : eachCase.Solution_Summary__c;
                    eachCase.Root_Cause__c = !String.isBlank(eachCase.Root_Cause__c) ? searchAndReplaceIP(eachCase.Root_Cause__c) : eachCase.Root_Cause__c;
                    caseListForUpdate.add(eachCase);
                    createReportingData(eachCase.Id,'Case');
                    
                }
            }
            
            // Masking and Updating Each Case Transition
            if(caseTransitionList != Null && !caseTransitionList.isEmpty()){
                for(Case_Transition__c eachCaseTrans : caseTransitionList){ 
                    maskedIpAddresses = '';
                    eachCaseTrans.Issue_Summary__c = !String.isBlank(eachCaseTrans.Issue_Summary__c) ? searchAndReplaceIP(eachCaseTrans.Issue_Summary__c) : eachCaseTrans.Issue_Summary__c;
                    eachCaseTrans.Troubleshooting_to_Date__c = !String.isBlank(eachCaseTrans.Troubleshooting_to_Date__c) ? searchAndReplaceIP(eachCaseTrans.Troubleshooting_to_Date__c) : eachCaseTrans.Troubleshooting_to_Date__c;
                    eachCaseTrans.Data_Collected__c = !String.isBlank(eachCaseTrans.Data_Collected__c) ? searchAndReplaceIP(eachCaseTrans.Data_Collected__c) : eachCaseTrans.Data_Collected__c;
                    eachCaseTrans.Customer_Expectations__c = !String.isBlank(eachCaseTrans.Customer_Expectations__c) ? searchAndReplaceIP(eachCaseTrans.Customer_Expectations__c) : eachCaseTrans.Customer_Expectations__c;
                    eachCaseTrans.Next_Action_Recommendation__c = !String.isBlank(eachCaseTrans.Next_Action_Recommendation__c) ? searchAndReplaceIP(eachCaseTrans.Next_Action_Recommendation__c) : eachCaseTrans.Next_Action_Recommendation__c;
                    caseTransitionListForUpdate.add(eachCaseTrans);
                    createReportingData(eachCaseTrans.case__c,'Case Transition');
                }
            }
            
            // Masking and Updating Each Engagement Request
            if(erList != Null && !erList.isEmpty()){
                for(Engagement_Request__c eachER : erList){
                    maskedIpAddresses = '';
                    eachER.Description__c = !String.isBlank(eachER.Description__c) ? searchAndReplaceIP(eachER.Description__c) : eachER.Description__c;
                    eachER.Steps_to_Reproduce__c = !String.isBlank(eachER.Steps_to_Reproduce__c) ? searchAndReplaceIP(eachER.Steps_to_Reproduce__c) : eachER.Steps_to_Reproduce__c;
                    eachER.Sample_URLs__c = !String.isBlank(eachER.Sample_URLs__c) ? searchAndReplaceIP(eachER.Sample_URLs__c) : eachER.Sample_URLs__c;
                    eachER.Additional_Data__c = !String.isBlank(eachER.Additional_Data__c) ? searchAndReplaceIP(eachER.Additional_Data__c) : eachER.Additional_Data__c;
                    eachER.ER_Resolution_Notes__c = !String.isBlank(eachER.ER_Resolution_Notes__c) ? searchAndReplaceIP(eachER.ER_Resolution_Notes__c) : eachER.ER_Resolution_Notes__c;
                    erListForUpdate.add(eachER);
				    createReportingData(eachER.case__c,'Engagement Request');               
                }
            }
            
            // Masking and Updating Each Case Task        
            if(taskList != Null && !taskList.isEmpty()){
                for(task eachTask : taskList){
                    maskedIpAddresses = '';
                    eachTask.Subject = !String.isBlank(eachTask.Subject) ? searchAndReplaceIP(eachTask.Subject) : eachTask.Subject;
                    eachTask.Description = !String.isBlank(eachTask.Description) ? searchAndReplaceIP(eachTask.Description) : eachTask.Description;
                    taskListForUpdate.add(eachTask);
                    createReportingData(eachTask.WhatId,'Case Activity');

                }
            }
            
            
            // Masking and Updating Each Case Feed
            if(caseFeedList != Null && !caseFeedList.isEmpty()){
                for(FeedItem eachCaseFeed : caseFeedList){  
                    maskedIpAddresses = '';
                    eachCaseFeed.Body = !String.isBlank(eachCaseFeed.Body) ? searchAndReplaceIP(eachCaseFeed.Body) : eachCaseFeed.Body;
                    caseFeedListForUpdate.add(eachCaseFeed);
                    createReportingData(eachCaseFeed.ParentId,'Chatter Item');
                }
            }

            //Delete all case related Attachment
            caseAttachment = new list<Attachment>([SELECT Id from Attachment where parentId IN :caseIdListForDelAtt]);
            if(!caseAttachment.isEmpty()){
            	delete caseAttachment;
            }
            //Inserting all masked record into Reporting Object SC_Scrubbed_IPs__c
            if(!scrubIPObjList.isEmpty()){
            	insert scrubIPObjList;
            }
            
            //updating Case Feed
            if(caseFeedListForUpdate.size() > 0){
                for(FeedItem eachFeed : caseFeedListForUpdate){
               		eachFeed.Body = !String.isBlank(eachFeed.Body) && eachFeed.Body.length() > 10000 ? eachFeed.Body.substring(0,10000) : eachFeed.Body;
                }
              update caseFeedListForUpdate; 
            }
            
            //Updating Task
            if(taskListForUpdate.size() > 0){
            	for(task forEachtask :taskListForUpdate){
                    forEachtask.Subject = !String.isBlank(forEachtask.Subject) && forEachtask.Subject.length() > 255 ? forEachtask.Subject.substring(0,255) : forEachtask.Subject;
                    forEachtask.Description = !String.isBlank(forEachtask.Description) && forEachtask.Description.length() > 32000 ? forEachtask.Description.substring(0,32000) : forEachtask.Description;
                    forEachtask.Task_Validation_Override__c = true;
                }
                update taskListForUpdate;
            }
            
            //updating Case Transition 
            if(caseTransitionListForUpdate.size() > 0){
            	for(Case_Transition__c forEachCaseTransList :caseTransitionListForUpdate){
                    forEachCaseTransList.Issue_Summary__c = !String.isBlank(forEachCaseTransList.Issue_Summary__c) && forEachCaseTransList.Issue_Summary__c.length() > 32000 ? forEachCaseTransList.Issue_Summary__c.substring(0,32000) : forEachCaseTransList.Issue_Summary__c;
                    forEachCaseTransList.Troubleshooting_to_Date__c = !String.isBlank(forEachCaseTransList.Troubleshooting_to_Date__c) && forEachCaseTransList.Troubleshooting_to_Date__c.length() > 32000 ? forEachCaseTransList.Troubleshooting_to_Date__c.substring(0,32000) : forEachCaseTransList.Troubleshooting_to_Date__c;
                    forEachCaseTransList.Data_Collected__c = !String.isBlank(forEachCaseTransList.Data_Collected__c) && forEachCaseTransList.Data_Collected__c.length() > 32000 ? forEachCaseTransList.Data_Collected__c.substring(0,32000) : forEachCaseTransList.Data_Collected__c;
                    forEachCaseTransList.Customer_Expectations__c = !String.isBlank(forEachCaseTransList.Customer_Expectations__c) && forEachCaseTransList.Customer_Expectations__c.length() > 32000 ? forEachCaseTransList.Customer_Expectations__c.substring(0,32000) : forEachCaseTransList.Customer_Expectations__c;
                    forEachCaseTransList.Next_Action_Recommendation__c = !String.isBlank(forEachCaseTransList.Next_Action_Recommendation__c) && forEachCaseTransList.Next_Action_Recommendation__c.length() > 32000 ? forEachCaseTransList.Next_Action_Recommendation__c.substring(0,32000) : forEachCaseTransList.Next_Action_Recommendation__c;
                    forEachCaseTransList.Validation_Override__c = true;
                }
                update caseTransitionListForUpdate;
            }
            
            //updating Engagement Request
            if(erListForUpdate.size() > 0){
            	for(Engagement_Request__c forEachERList :erListForUpdate){
                    forEachERList.Description__c = !String.isBlank(forEachERList.Description__c) && forEachERList.Description__c.length() > 32000 ? forEachERList.Description__c.substring(0,32000) : forEachERList.Description__c;
                    forEachERList.Steps_to_Reproduce__c = !String.isBlank(forEachERList.Steps_to_Reproduce__c) && forEachERList.Steps_to_Reproduce__c.length() > 32000 ? forEachERList.Steps_to_Reproduce__c.substring(0,32000) : forEachERList.Steps_to_Reproduce__c;
                    forEachERList.Sample_URLs__c = !String.isBlank(forEachERList.Sample_URLs__c) && forEachERList.Sample_URLs__c.length() > 32000 ? forEachERList.Sample_URLs__c.substring(0,32000) : forEachERList.Sample_URLs__c;
                    forEachERList.Additional_Data__c = !String.isBlank(forEachERList.Additional_Data__c) && forEachERList.Additional_Data__c.length() > 32000 ? forEachERList.Additional_Data__c.substring(0,32000) : forEachERList.Additional_Data__c;
                    forEachERList.ER_Resolution_Notes__c = !String.isBlank(forEachERList.ER_Resolution_Notes__c) && forEachERList.ER_Resolution_Notes__c.length() > 32000 ? forEachERList.ER_Resolution_Notes__c.substring(0,32000) : forEachERList.ER_Resolution_Notes__c;
                    forEachERList.Validation_Override__c = true;
                }
                update erListForUpdate;
            }
            
        
        	//Updating all cases 

            if(caseIdList.size() > 0){
                
                for(case forEachCaseL :caseListForUpdate){
                    forEachCaseL.Validation_Override__c = true;
                    forEachCaseL.Is_IP_Scrubbed__c = true;
                    forEachCaseL.Subject = !String.isBlank(forEachCaseL.Subject) && forEachCaseL.Subject.length() > 255 ? forEachCaseL.Subject.substring(0,255) : forEachCaseL.Subject;
                    forEachCaseL.Description = !String.isBlank(forEachCaseL.Description) && forEachCaseL.Description.length() > 32000 ? forEachCaseL.Description.substring(0,32000) : forEachCaseL.Description;
                    forEachCaseL.Issue_Summary__c = !String.isBlank(forEachCaseL.Issue_Summary__c) && forEachCaseL.Issue_Summary__c.length() > 32000 ? forEachCaseL.Issue_Summary__c.substring(0,32000) : forEachCaseL.Issue_Summary__c;
                    forEachCaseL.Troubleshooting_to_Date__c = !String.isBlank(forEachCaseL.Troubleshooting_to_Date__c) && forEachCaseL.Troubleshooting_to_Date__c.length() > 32000 ? forEachCaseL.Troubleshooting_to_Date__c.substring(0,32000) : forEachCaseL.Troubleshooting_to_Date__c;
                    forEachCaseL.Data_Collected__c = !String.isBlank(forEachCaseL.Data_Collected__c) && forEachCaseL.Data_Collected__c.length() > 32000 ? forEachCaseL.Data_Collected__c.substring(0,32000) : forEachCaseL.Data_Collected__c;
                    forEachCaseL.Customer_Expectations__c = !String.isBlank(forEachCaseL.Customer_Expectations__c) && forEachCaseL.Customer_Expectations__c.length() > 32000 ? forEachCaseL.Customer_Expectations__c.substring(0,32000) : forEachCaseL.Customer_Expectations__c;
                    forEachCaseL.Next_Action_Recommendation__c = !String.isBlank(forEachCaseL.Next_Action_Recommendation__c) && forEachCaseL.Next_Action_Recommendation__c.length() > 32000 ? forEachCaseL.Next_Action_Recommendation__c.substring(0,32000) : forEachCaseL.Next_Action_Recommendation__c;
                    forEachCaseL.Solution_Summary__c = !String.isBlank(forEachCaseL.Solution_Summary__c) && forEachCaseL.Solution_Summary__c.length() > 32000 ? forEachCaseL.Solution_Summary__c.substring(0,32000) : forEachCaseL.Solution_Summary__c;
                    forEachCaseL.Root_Cause__c = !String.isBlank(forEachCaseL.Root_Cause__c) && forEachCaseL.Root_Cause__c.length() > 32000 ? forEachCaseL.Root_Cause__c.substring(0,32000) : forEachCaseL.Root_Cause__c;
                }
                update caseListForUpdate;
    		}
        }
        catch(Exception ex){
            errorMsg = ex.getMessage();
            Database.rollback(sp);
        }
        return errorMsg;
    }
    
    //Method for searching and replacing all IPv4 and IPv6 addresses
    public string searchAndReplaceIP(String dataForScrubbing){

            afterMaskingJSON = '';
            //maskedIpAddresses = '';
            beforeMaskingJSON = '';
            beforeMaskingJSON = dataForScrubbing;        
			List<String> splitStringList = new List<String>();
           // if(dataForScrubbing.length() > 0){
            	splitStringList = dataForScrubbing.split('[\n]');
            //}
       		if(splitStringList.size() > 0){
                for(string eachString : splitStringList){
                    String regExIPv4Andv6 = '(\\s*(([0-9]|[1-9][0-9]|1[0-9]{2}|2[0-4][0-9]|25[0-5])\\.){3}(25[0-5]|2[0-4][0-9]|1[0-9]{2}|[1-9][0-9]|[0-9])\\s*)|(\\s*([\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:[\\dA-Fa-f]{1,4})|(:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:[\\dA-Fa-f]{1,4})|([\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:[\\dA-Fa-f]{1,4})|([\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4})|([\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f][\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4})|([\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4})|([\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f])|([\\dA-Fa-f]{1,4}:{2}[\\dA-Fa-f]{1,4}:{1,2}[\\dA-Fa-f]{1,4})\\s*)';
                    Pattern regexPattern = Pattern.compile(regExIPv4Andv6);
                    Matcher regexMatcher = regexPattern.matcher(eachString);  
                
                    if(regexMatcher.find()){
                        afterMaskingJSON = afterMaskingJSON + eachString.replaceAll(regExIPv4Andv6,' [IP Removed for Data Privacy] ');
                        maskedIpAddresses = maskedIpAddresses + regexMatcher.group()+',';
                    }
                    else{
                        afterMaskingJSON = afterMaskingJSON + eachString;
                    }
                    While(regexMatcher.find()){
                         maskedIpAddresses = maskedIpAddresses + regexMatcher.group()+',';
                    }
                    afterMaskingJSON = afterMaskingJSON + '<--br-->';
                }
            }
        	afterMaskingJSON = afterMaskingJSON.removeEnd('<--br-->');
        	afterMaskingJSON = afterMaskingJSON.replaceAll('<--br-->','\n');
            return afterMaskingJSON;
    }
    
    //Method to create records in object SC_Scrubbed_IPs__c for reporting
    public void createReportingData(Id caseId, String objectName){
        maskedIpAddresses = maskedIpAddresses.removeEnd(',');
        set<String> ipSet = new set<String>();
        if(maskedIpAddresses != null && maskedIpAddresses.trim() != ''){
        	for(String eachRec : maskedIpAddresses.split(',')){
            	ipSet.add(eachRec.trim());
            }
        }

        if(!ipSet.isEmpty()){
            for(String eachIp : ipSet){
                SC_Scrubbed_IPs__c scrubCase = new SC_Scrubbed_IPs__c();
                scrubCase.Case__c = caseId;
                scrubCase.IP_Address__c = eachIp;
                scrubCase.Time_Stamp_of_Scrubbing__c = system.now();
                scrubCase.Object__c = objectName;
                scrubCase.Department__c	= 'Akamai Technical Support';
                //scrubCase.OrignalRecordJSON__c = beforeMaskingJSON;
                scrubIPObjList.add(scrubCase);
                caseIdListForDelAtt.add(caseId);
            }
        }
    }
    
    //Method to send email when exception occurs
    public static void sendEmailforException(String body){
        String errorMessage = 	'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
       						'Batch Class Name = SC_ScrubIPAddresses_Batch\n' + 
                            'Support Class Name = SC_ScrubAndRemoveIPAddresses\n' +
                            'Method Name = scrubIPAddresses\n' +
                			'Error Message =' + body;
        
        //Get the two address
        SC_Scrub_IP_Addresses_Setting__mdt scrubIPSettings = [SELECT Support_Email_Address__c FROM  SC_Scrub_IP_Addresses_Setting__mdt WHERE DeveloperName = 'Technical'];
        String[] toAdd = new String[] {};
        toAdd.add(scrubIPSettings.Support_Email_Address__c);
            
	  	// Sending Email
   		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setToAddresses(toAdd);
		mail.subject = 'Exception: In Batch Job - SC_ScrubIPAddresses_Batch';
		mail.plainTextBody = errorMessage;
		Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail}); 
        
    }
}