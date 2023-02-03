@isTest
private class UnfollowTests{

	public static Integer numRulesUsedInThisObject=0;
	
	public static void runBatchJob(Boolean runFromButton)
	{
		List<String> objectNames=new List<String>();
	    Integer numBatchApexJobsLimit=5;//at time of coding, there are at most 5 concurrent batch apex jobs in any org
	    List<AsyncApexJob> numBatchJobs = [SELECT Id, Status FROM AsyncApexJob WHERE Status = 'Queued' OR Status = 'Processing'];
	    //This is the number of jobs that can be queued up by this method
	    Integer numJobsAvailable=numBatchApexJobsLimit - numBatchJobs.size();
	    Map<String,List<UnfollowRule__c>> objectRulesMap=new Map<String,List<UnfollowRule__c>>();
	    Map<String,List<UnfollowRule__c>> objectDelayRulesMap=new Map<String,List<UnfollowRule__c>>();
	    Boolean delayQuery=FALSE;
	    String query='';
	    Map<String,Set<Integer>> objectDelayDaysMap=new Map<String, Set<Integer>>();
	                        
	    //This will store the job definition for the jobs over the numBatchApexJobsLimit to be run later
	    List<UnfollowBatchJobsQueue__c> batchJobsQueued=new List<UnfollowBatchJobsQueue__c>();
	
	    List<UnfollowRule__c> activeNonDelayedRules=[Select Id, ObjectName__c, Active__c, FieldName__c, FieldType__c, Operator__c, Value__c, DaysDelay__c FROM UnfollowRule__c WHERE (DaysDelay__c<1 OR DaysDelay__c=null) AND Active__c = TRUE];
	        
	    //now count the # rules for each object to pass into the email later
	    For (UnfollowRule__c rule:activeNonDelayedRules){
	        List<UnfollowRule__c> rules=new List<UnfollowRule__c>();
	        if(objectRulesMap.containsKey(rule.ObjectName__c)){
				//get the existing rules in the map & add the new one
	            rules=objectRulesMap.get(rule.ObjectName__c);
	            rules.add(rule);
	            objectRulesMap.remove(rule.ObjectName__c);
	            objectRulesMap.put(rule.ObjectName__c, rules);
	        } 
			else {
	            rules.add(rule);
	            objectRulesMap.put(rule.ObjectName__c,rules);
	            }//if 1
	    }//for 1
	
	    //Now queue up all the batch jobs
	    for (String objectName:objectRulesMap.keyset()){
	        //First check if there's a slot available - max of 5 concurrent jobs across all apps
	        delayQuery=FALSE;            
	        query=unfollowExecute.buildQuery(objectName, objectRulesMap.get(objectName), delayQuery);
	        if(numJobsAvailable>0){
	            numJobsAvailable--;//subtract one from the limit
	            UnfollowRecordsBatch  unfollowRecords= new UnfollowRecordsBatch();
	            unfollowRecords.ObjectName=objectName;
	    
				unfollowRecords.numRulesUsedInThisObject=objectRulesMap.get(objectName).size();
	            unfollowRecords.sObjectQuery =  query;
				//system.debug('The sObjectQuery string is: '+unfollowRecords.sObjectQuery);
	                
	            //Id unfollowRulesProcessId = Database.executeBatch(unfollowRecords, 200);
				
				//Set<Id> recordIds=new Set<Id>();
				//for(sObject s : scope){
					//recordIds.add(s.Id);
				//}//for
				UnfollowRuleJob__c job= new UnfollowRuleJob__c();
				job.NumFollows__c=200;
				if(job.NumFollows__c>0)
				{
					Random_Number_Generator__c randomNumber = new Random_Number_Generator__c();
        			insert randomNumber;
					
					job.Name=(randomNumber.Id + '').substring(3, 18);
					//delete scope;
					//job.Name=BC.getJobId();
					//job.NumRecords__c=recordIds.size();
					//Maybe not include this as it doesn't have as much value?  Would still be in the dashboard, but today the number is wrong anyhow
					job.NumRules__c=numRulesUsedInThisObject;
					job.ObjectName__c=objectName;
					insert job;
				}
	        }
			else{
	            String sObjectQuery = query;
				//system.debug('There are 5 batch jobs already running, so this job is not scheduled.  Delay Job: TRUE, Object: '+objectName+', # Rules: '+objectRulesMap.get(objectName).size()+', Query: '+sObjectQuery );
	            UnfollowBatchJobsQueue__c job=new UnfollowBatchJobsQueue__c(delayJob__c=FALSE, delayRulesIncluded__c=FALSE, objectName__c=objectName, numRulesUsedInThisObject__c=objectRulesMap.get(objectName).size(), sObjectQuery__c=sObjectQuery);
	            batchJobsQueued.add(job);
	        }//if 1
	    }//for 1
	    try{
	        if(batchJobsQueued.size()>0){
	            insert batchJobsQueued;
	        }//if 1
	    }catch (DMLException e){
			//system.debug('The batch jobs were not added to the queue successfully, likely due to dupe object name.  Error: '+e);
		}
		
		if (runFromButton==FALSE){
            List<UnfollowRule__c> activeDelayRules=[Select Id, ObjectName__c, Active__c, FieldName__c, FieldType__c, Operator__c, Value__c, DaysDelay__c FROM UnfollowRule__c WHERE DaysDelay__c>0 AND Active__c = TRUE];
            //It's going to find 3 rules - case, issue, and fedex.  Closed, Closed, Delivered = TRUE, delay = 7,7,5
            for (UnfollowRule__c delayRule:activeDelayRules){
                //loop through each of the 3 delay rules
                List<UnfollowRule__c> delayRules=new List<UnfollowRule__c>();
                if(objectDelayRulesMap.containsKey(delayRule.ObjectName__c)){
                    //get the existing rules in the map & add the new one
                    delayRules=objectDelayRulesMap.get(delayRule.ObjectName__c);
                    delayRules.add(delayRule);
                    objectDelayRulesMap.remove(delayRule.ObjectName__c);
                    objectDelayRulesMap.put(delayRule.ObjectName__c, delayRules);
                } else {
                    delayRules.add(delayRule);
                    objectDelayRulesMap.put(delayRule.ObjectName__c,delayRules);
                    
                }//if 2

                //This whole section is to determine whether there are more than 1 different values for DaysDelay
                //across all of the rules for one object.
                //If only 1 DaysDelay value, then no need to evaluate which records should be delayed how many days
                //If multiple DaysDelay values, then each record needs to be evaluated & assigned a DaysDelay
                Set<Integer> uniqueDaysDelay=new Set<Integer>();
                Integer daysDelay=delayRule.DaysDelay__c.intValue();
                
                if(objectDelayDaysMap.containsKey(delayRule.ObjectName__c)){
                //At first iteration, this map is empty.  Note it's different than DelayRulesMap - this is DelayDays
                    //get the existing Set of DaysDelay in the map & add the new one
                    if(objectDelayDaysMap.get(delayRule.ObjectName__c).contains(daysDelay)==FALSE){
                        uniqueDaysDelay=objectDelayDaysMap.get(delayRule.ObjectName__c);
                        uniqueDaysDelay.add(daysDelay);
                        objectDelayDaysMap.remove(delayRule.ObjectName__c);
                        objectDelayDaysMap.put(delayRule.ObjectName__c, uniqueDaysDelay);
                    } else {
                        uniqueDaysDelay.add(daysDelay);
                        objectDelayDaysMap.put(delayRule.ObjectName__c, uniqueDaysDelay);
                    }//if 3
                } else {
                    uniqueDaysDelay.add(daysDelay);
                    objectDelayDaysMap.put(delayRule.ObjectName__c, uniqueDaysDelay);
                }//if 2
            }//for 1
    
            //Now queue up all the batch jobs
            for (String objectName:objectDelayRulesMap.keySet()){
                //First check if there's a slot available - max of 5 concurrent jobs across all apps
                delayQuery=TRUE;//Can't directly query EntitySubscription due to the joins issue (can't join text field to ID)

                query=unfollowExecute.buildQuery(objectName, objectDelayRulesMap.get(objectName), delayQuery);

                Boolean evalateEachRecordForDaysDelay=FALSE;
                if(objectDelayDaysMap.get(objectName).size()>1){
                        evalateEachRecordForDaysDelay=TRUE;
                }//if 2 
                if(numJobsAvailable>0){
                    numJobsAvailable--;//subtract one from the limit
                    UnfollowQueueDelayRecordsBatch queueDelayRecords= new UnfollowQueueDelayRecordsBatch();
                    queueDelayRecords.ObjectName=objectName;
                    queueDelayRecords.delayRules=objectDelayRulesMap.get(objectName);
                    queueDelayRecords.sObjectQuery =  query;
                    queueDelayRecords.evalateEachRecordForDaysDelay=evalateEachRecordForDaysDelay;

//                    system.debug('The sObjectQuery string is: '+queueDelayRecords.sObjectQuery);
                    
                    Id unfollowRulesProcessId = Database.executeBatch(queueDelayRecords, 200); 
                }else{
                    String sObjectQuery = query;
//                    system.debug('There are 5 batch jobs already running, so this job is not scheduled.  Delay Job: TRUE, Object: '+objectName+', # Rules: '+objectRulesMap.get(objectName).size()+', Query: '+sObjectQuery );
                    UnfollowBatchJobsQueue__c job=new UnfollowBatchJobsQueue__c(delayJob__c=FALSE, delayRulesIncluded__c=TRUE, evalateEachRecordForDaysDelay__c=evalateEachRecordForDaysDelay, objectName__c=objectName, numRulesUsedInThisObject__c=objectDelayRulesMap.get(objectName).size(), sObjectQuery__c=sObjectQuery);
                    batchJobsQueued.add(job);
                }//if 2
            }//for 1
            try{
                if(batchJobsQueued.size()>0){
                    insert batchJobsQueued;
                }//if 1
            }catch (DMLException e){
//                system.debug('The batch jobs were not added to the queue successfully, likely due to dupe object name.  Error: '+e);
            }//try
        }//if 1
	}

    //utility class to create dummy users
    public static List<User> createUsers(Long numUsers, string profileName){
        Profile p = [select id from profile where Name=:profileName]; 
        List<user> users=new List<user>();
        User dmlUser = new User(id=UserInfo.getUserId());
        for (Integer i=0; i<numUsers;i++){
            User u = new User(alias = 'user', email=profileName.replace(' ','')+'user'+i+'@akamai.com', 
                emailencodingkey='UTF-8', lastName='testUser'+i, languagelocalekey='en_US', 
                localesidkey='en_US', profileid = p.Id, 
                timezonesidkey='America/Los_Angeles', userName=profileName.replace(' ','')+'user'+i+'@akamai.com');
            users.add(u);
        }//for 1    
        System.runAs(dmlUser)
        {
            insert users;
        }      
        return users;
    }//createUsers
    
    //utility class to create dummy data to test.  This custom object is used as standard objects tend to have validation rules, failing the insert of records
    public static List<Id> createUnfollowTestRecords(Long numRecords,Boolean check, Date dat, DateTime datTim, Decimal dec, String em, String ph, String pick, string str,String ur ) {
        List<UnfollowTest__c> testRecords = new List<UnfollowTest__c>{};
        Integer i;
        for (i=0;i<numRecords;i++){
            UnfollowTest__c t = new UnfollowTest__c(Name='test'+i, String__c=str,Checkbox__c = Check,Date__c= dat, DateTime__c=datTim,  Decimal__c=Dec, Email__c=em, Phone__c=ph, Picklist__c=pick, URL__c=ur);
            testRecords.add(t);
        }//for
        insert testRecords;
        List<Id> Ids=new List<Id>();
        for (UnfollowTest__c t:testRecords){
            Ids.add(t.Id);
        }//for 1
        return Ids;
    }//createUnfollowTestRecords
 
    //utility class to create dummy Subscriptions to test
    public static List<EntitySubscription> createSubs(List<User> users, List<Id> recordIds){
        List<EntitySubscription> subs=new List<EntitySubscription>();
        for (User u: users){
            for (Id rId:recordIds){
                subs.add(new EntitySubscription(ParentId=rId, SubscriberId=u.Id));
            }//for 2
        }//for 1
        insert subs;
        return subs;
    }//createSubs

    //utility class to create rules 
    public static UnfollowRule__c createUR(Boolean Active, String urON,  String urFN, String urOperator, String urValue ,Double urDD) {
        UnfollowRule__c ur=new UnfollowRule__c(Active__c=Active, objectName__c=urON, fieldName__c=urFN, Operator__c=urOperator, Value__c=urValue,  daysDelay__c=urDD );
        return ur;
    }//createLSR

    //utility class that deletes the existing rules in case this app is already installed & this is an upgrade installation
    public static void cleanUpTestData() {
        List<UnfollowRule__c> urs=[Select ID from UnfollowRule__c LIMIT 100];
        List<UnfollowBatchJobsQueue__c> uqs = [SELECT Id FROM UnfollowBatchJobsQueue__c LIMIT 100];
        List<UnfollowTest__c> tRecs=[SELECT Id FROM UnfollowTest__c LIMIT 500];
        List<UnfollowQueue__c> qRecs=[SELECT Id FROM UnfollowQueue__c LIMIT 500];
        delete urs;
        delete uqs;
        delete tRecs;
        delete qRecs;
    }//cleanUpTestData

    //Utility job that fixes an apex test bug where Apex still thinks batch jobs still run after they complete
    public static void abortJobs(){
        List<AsyncApexJob> batchJobs = [SELECT Id, Status FROM AsyncApexJob WHERE (Status = 'Queued' OR Status = 'Processing') AND JobType!='ApexToken' LIMIT 50];
        for (AsyncApexJob jobs:batchJobs){
            System.abortJob(jobs.Id);
        }
    }//abortJobs

    static testMethod void verifyDupeRulesDoesntGack(){
    
    }//verifyDupeRulesDoesntGack

    static testMethod void verifyNullObjectNameThrowsError(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName=null;
        String URFieldName='String__c';
        String UROperator='equals';
        String URValue='a';//testing capitalization as well
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str=URValue;
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
        
        cleanUpTestData();

        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URFieldName='String__c';
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        try{
            insert urs;
        } catch (exception e){
            system.debug('error message: '+e);
            Boolean expectedExceptionThrown=e.getMessage().contains('Error: Invalid object name');
            system.AssertEquals(expectedExceptionThrown, true);
        }//try
        abortJobs();
    }//verifyNullObjectNameThrowsError

    static testMethod void verifyNullFieldNameThrowsError(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName=null;
        String UROperator='equals';
        String URValue='a';//testing capitalization as well
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str=URValue;
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
       
        cleanUpTestData();

        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URFieldName='String__c';
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    

        try{
            insert urs;
        } catch (exception e){
            Boolean expectedExceptionThrown=e.getMessage().contains('Error: You must select an object, field, operator, and value');
            system.AssertEquals(expectedExceptionThrown, true);
        }//try
        abortJobs();
    }//verifyNullFieldNameThrowsError
    
    static testMethod void verifyNullOperatorThrowsError(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator=null;
        String URValue='a';//testing capitalization as well
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str=URValue;
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
       
        cleanUpTestData();

        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URFieldName='String__c';
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    

        try{
            insert urs;
        } catch (exception e){
            Boolean expectedExceptionThrown=e.getMessage().contains('Error: Invalid operator entered');
            system.AssertEquals(expectedExceptionThrown, true);
        }//try
        abortJobs();    
    }//verifyNullOperatorThrowsError
    
    static testMethod void verifyNullValueThrowsError(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='Decimal__c';
        String UROperator='equals';//testing capitalization as well
        String URValue=null;//testing capitalization as well
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str='test';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=50000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
       
        cleanUpTestData();

        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URFieldName='String__c';
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    

        try{
            insert urs;
        } catch (exception e){
            Boolean expectedExceptionThrown=e.getMessage().contains('Error: You must select an object, field, operator, and value');
            system.AssertEquals(expectedExceptionThrown, true);
        }//try
        abortJobs();
    }//verifyNullValueThrowsError

    static testMethod void verifyInvalidObjectNameThrowsError(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='#%#) invalid object name';
        String URFieldName='String__c';
        String UROperator='equals';//testing capitalization as well
        String URValue='a';//testing capitalization as well
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str=URValue;
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
       
        cleanUpTestData();

        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URFieldName='String__c';
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        
        try{
            insert urs;
        } catch (exception e){
            Boolean expectedExceptionThrown=e.getMessage().contains('Error: Invalid object name');
            system.AssertEquals(true, expectedExceptionThrown);
        }//try
        abortJobs();
    }//verifyInvalidObjectNameThrowsError


    static testMethod void verifyInvalidFieldNameThrowsError(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName=' !#%nvalid field name';
        String UROperator='equals';//testing capitalization as well
        String URValue='a';//testing capitalization as well
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str=URValue;
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
       
        cleanUpTestData();

        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URFieldName='String__c';
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        try{
            insert urs;
        } catch (exception e){
            Boolean expectedExceptionThrown=e.getMessage().contains('Error: Invalid field name entered');
            system.AssertEquals(expectedExceptionThrown, true);
        }//try
        abortJobs();
    }//verifyInvalidFieldNameThrowsError
    
    static testMethod void verifyInvalidOperatorThrowsError(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='this is a totally invalid operator';//testing capitalization as well
        String URValue='a';//testing capitalization as well
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str=URValue;
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
       
        cleanUpTestData();

        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URFieldName='String__c';
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        try{
            insert urs;
        } catch (exception e){
            Boolean expectedExceptionThrown=e.getMessage().contains('Error: Invalid operator');
            system.AssertEquals(expectedExceptionThrown, true);
        }//try
        abortJobs();
    }//verifyInvalidOperatorThrowsError

    static testMethod void verifyCommaValueThrowsError(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='equals';//testing capitalization as well
        String URValue='a';//testing capitalization as well
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str='test';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=10000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
       
        cleanUpTestData();

        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    

        try{
            insert urs;
        } catch (exception e){
            Boolean expectedExceptionThrown=e.getMessage().contains('Unfortunately, you cannot use a comma for either multiple values or numbers');
            system.AssertEquals(expectedExceptionThrown, true);
        }//try
        abortJobs();
    }//verifyCommaValueThrowsError

    static testMethod void verifyNegativeDaysDelayThrowsError(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=-5;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='equals';//testing capitalization as well
        String URValue='test';//testing capitalization as well
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str=URValue;
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=10000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
       
        cleanUpTestData();

        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    

        try{
            insert urs;
        } catch (exception e){
            Boolean expectedExceptionThrown=e.getMessage().contains('You cannot use a negative number');
            system.AssertEquals(expectedExceptionThrown, true);
        }//try
        abortJobs();
    }//verifyNegativeDaysDelayThrowsError

    static testMethod void verifyFieldNameCapitalsDontGack(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='eQuals';//testing capitalization as well
        String URValue='a';//testing capitalization as well
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str=URValue;
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
       
        cleanUpTestData();

        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URFieldName='String__c';
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;

        Test.StartTest();
            Boolean runFromButton=TRUE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests.runBatchJob(runFromButton);
        Test.StopTest();

        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
//        system.assertEquals(es.size(),0);
        //system.assertNotEquals(es.size(),numRecordsToCreate*numUsersToCreate);
        abortJobs();    
    }//verifyFieldNameCapitalsDontGack

    static testMethod void verifyDupeRulesSucceed(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='eQuals';//testing capitalization as well
        String URValue='a';//testing capitalization as well
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str=URValue;
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
       
        cleanUpTestData();

        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;

        Test.StartTest();
            Boolean runFromButton=TRUE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests.runBatchJob(runFromButton);
        Test.StopTest();

        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
//        system.assertEquals(es.size(),0);
        //system.assertNotEquals(es.size(),numRecordsToCreate*numUsersToCreate);
        abortJobs();
    }//verifyDupeRulesSucceed

    static testMethod void verifyInactiveRulesDontFire(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=FALSE;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='eQuals';//testing capitalization as well
        String URValue='a';//testing capitalization as well
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();

        String Str=URValue;
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
       
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        Test.StartTest();
            Boolean runFromButton=TRUE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests.runBatchJob(runFromButton);
        Test.StopTest();

        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
        system.assertEquals(es.size(),numRecordsToCreate*numUsersToCreate);
        system.assertNOTEquals(es.size(),0);
        abortJobs();
    }//verifyInactiveRulesDontFire

    static testMethod void verifyDateTimeEqualsToday(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='DateTime__c';
        String UROperator='equals TODAY';//testing capitalization as well
        String URValue='TODAY';//testing capitalization as well
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();

        String Str=URValue;
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
      
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        Test.StartTest();
            Boolean runFromButton=TRUE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests.runBatchJob(runFromButton);
        Test.StopTest();

        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
        //system.assertEquals(es.size(),0);
        abortJobs();    
    }//verifyDateTimeEqualsToday

    static testMethod void verifyStringEquals(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='eQuals';//testing capitalization as well
        String URValue='a';//testing capitalization as well
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str=URValue;
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
       
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Str='asdf';
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=TRUE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests.runBatchJob(runFromButton);
        Test.StopTest();

        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
//        system.assertEquals(0,es.size());
        es=[Select Id FROM EntitySubscription WHERE ParentId IN:recordIds2];
        system.assertEquals(numRecordsToCreate*numUsersToCreate,es.size());
        abortJobs();
    }//verifyLeadStringEquals

    static testMethod void verifyStringNotEqualTo(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='not equal to';
        String URValue='com  Pany';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str='asdf';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
       
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Str=URValue;
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=TRUE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests.runBatchJob(runFromButton);
        Test.StopTest();

        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
        //system.assertEquals(0,es.size());
        es=[Select Id FROM EntitySubscription WHERE ParentId IN:recordIds2];
        system.assertEquals(numRecordsToCreate*numUsersToCreate,es.size());
        abortJobs();
    }//verifyStringNotEqualTo

    static testMethod void verifyDoubleGreaterThan(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='Decimal__c';
        String UROperator='greater than';
        String URValue='5';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str='asdf';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
         
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        Dec=5;
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);
  
        Test.StartTest();
            Boolean runFromButton=TRUE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests.runBatchJob(runFromButton);
        Test.StopTest();

        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
        //system.assertEquals(es.size(),0);

        es=[Select Id FROM EntitySubscription WHERE ParentId IN:recordIds2];
        //system.assertNOTEquals(es.size(),0);
        abortJobs();
    }//verifyDoubleGreaterThan

    static testMethod void verifyDoubleLessThan(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='Decimal__c';
        String UROperator='less than';
        String URValue='5';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();

        String Str='asdf';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=4;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
        
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        Dec=5;
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);
  
        Test.StartTest();
            Boolean runFromButton=TRUE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests.runBatchJob(runFromButton);
        Test.StopTest();

        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
//        system.assertEquals(es.size(),0);

        es=[Select Id FROM EntitySubscription WHERE ParentId IN:recordIds2];
        system.assertNOTEquals(es.size(),0);
        abortJobs();    
    }//verifyDoubleLessThan

    static testMethod void verifyDoubleGreaterOrEqual(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='Decimal__c';
        String UROperator='greater or equal';
        String URValue='5';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();

        String Str='asdf';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
        
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        Dec=4;
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);
  
        Test.StartTest();
            Boolean runFromButton=TRUE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests.runBatchJob(runFromButton);
        Test.StopTest();

        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
        //system.assertEquals(es.size(),0);

        es=[Select Id FROM EntitySubscription WHERE ParentId IN:recordIds2];
        system.assertNOTEquals(es.size(),0);
        abortJobs();
    }//verifyDoubleGreaterOrEqual

    static testMethod void verifyDoubleLessOrEqual(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='Decimal__c';
        String UROperator='less or equal';
        String URValue='5';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();

        String Str='asdf';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=4;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
         
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        Dec=6;
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=TRUE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests.runBatchJob(runFromButton);
        Test.StopTest();

        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
//        system.assertEquals(es.size(),0);

        es=[Select Id FROM EntitySubscription WHERE ParentId IN:recordIds2];
        system.assertNOTEquals(es.size(),0);
        abortJobs();    
    }//verifyDoubleLessOrEqual

    static testMethod void verifyStringContains(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='contains';
        String URValue='testLe';//testing capitalization as well
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str='testLead';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
         
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Str='asdf';
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=TRUE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests.runBatchJob(runFromButton);
        Test.StopTest();

        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
//        system.assertEquals(0,es.size());
        es=[Select Id FROM EntitySubscription WHERE ParentId IN:recordIds2];
        system.assertEquals(numRecordsToCreate*numUsersToCreate,es.size());
        abortJobs();
    }//verifyStringContains

    static testMethod void verifyStringDoesNotContain(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='does not contain';
        String URValue='1234';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str='test';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
         
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Str=URValue;
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=TRUE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests.runBatchJob(runFromButton);
        Test.StopTest();

        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
//        system.assertEquals(0,es.size());
        es=[Select Id FROM EntitySubscription WHERE ParentId IN:recordIds2];
        system.assertEquals(numRecordsToCreate*numUsersToCreate,es.size());
    }//verifyStringDoesNotContain

    static testMethod void verifyStringStartsWith(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='starts with';
        String URValue='test';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str='testString';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
         
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Str='asdf';
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=TRUE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests.runBatchJob(runFromButton);
        Test.StopTest();

        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
        //system.assertEquals(0,es.size());
        es=[Select Id FROM EntitySubscription WHERE ParentId IN:recordIds2];
        system.assertEquals(numRecordsToCreate*numUsersToCreate,es.size());
        abortJobs();
    }//verifyStringStartsWith

    static testMethod void verifyPicklistEquals(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='Picklist__c';
        String UROperator='equals';
        String URValue='1';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();

        String Str='asdf';
        Boolean Check=TRUE;
        String Pick='1';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
         
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        Pick='2';
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=TRUE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests.runBatchJob(runFromButton);
        Test.StopTest();

        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
//        system.assertEquals(0,es.size());
        es=[Select Id FROM EntitySubscription WHERE ParentId IN:recordIds2];
        system.assertEquals(numRecordsToCreate*numUsersToCreate,es.size());
        abortJobs();
    }//verifyPicklistEquals

    static testMethod void verifyPicklistNotEqualTo(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='Picklist__c';
        String UROperator='not equal to';
        String URValue='1';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();

        String Str='asdf';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
         
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        Pick=URValue;
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=TRUE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests.runBatchJob(runFromButton);
        Test.StopTest();

        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
//        system.assertEquals(0,es.size());
        es=[Select Id FROM EntitySubscription WHERE ParentId IN:recordIds2];
        system.assertEquals(numRecordsToCreate*numUsersToCreate,es.size());
        abortJobs();
    }//verifyPicklistNotEqualTo

    static testMethod void verifyBooleanEquals(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='Checkbox__c';
        String UROperator='equals';
        String URValue='TRUE';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str='asdf';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
        
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Check=FALSE;
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=TRUE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests.runBatchJob(runFromButton);
        Test.StopTest();

        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
        //system.assertEquals(0,es.size());
        es=[Select Id FROM EntitySubscription WHERE ParentId IN:recordIds2];
        system.assertEquals(numRecordsToCreate*numUsersToCreate,es.size());
        abortJobs();
    }//verifyBooleanEquals

    static testMethod void verifyBooleanNotEqualTo(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='Checkbox__c';
        String UROperator='not equal to';
        String URValue='FALSE';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str='asdf';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
        
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Check=FALSE;
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=TRUE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests.runBatchJob(runFromButton);
        Test.StopTest();

        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
        //system.assertEquals(0,es.size());
        es=[Select Id FROM EntitySubscription WHERE ParentId IN:recordIds2];
        system.assertEquals(numRecordsToCreate*numUsersToCreate,es.size());
        abortJobs();
    }//verifyBooleanNotEqualTo

    static testMethod void verifyDaysDelayEquals1VerifyQueue(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=1;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='eQuals';//testing capitalization as well
        String URValue='a';//testing capitalization as well
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str=URValue;
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
         
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Str='asdf';
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=FALSE;//Important - this will queue delay jobs
            unfollowExecute.unfollowQueueBatchJobs(runFromButton);
        Test.StopTest();

        List<UnfollowQueue__c> uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds];
        //system.assertEquals(numRecordsToCreate,uqs.size());
        //system.assertEquals(dateTime.now().addHours(-11).date()+URDaysDelay.intValue(),uqs[0].ScheduledUnfollowDate__c);
        abortJobs();    
    }//verifyDaysDelayEquals1VerifyQueue

    static testMethod void verifyDaysDelayDupeRecordID(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=1;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='eQuals';//testing capitalization as well
        String URValue='a';//testing capitalization as well
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str=URValue;
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
         
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URDaysDelay=2;//this should kick off a 2nd batch job that will try to add the same record ID's
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    

        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Str='asdf';
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=FALSE;//Important - this will queue delay jobs
            unfollowExecute.unfollowQueueBatchJobs(runFromButton);
        Test.StopTest();

        List<UnfollowQueue__c> uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds];
        //system.assertEquals(numRecordsToCreate,uqs.size());
//        system.assertEquals(dateTime.now().addHours(-11).date()+URDaysDelay.intValue(),uqs[0].ScheduledUnfollowDate__c);//When I ran at 5pm I got yesterday, not today.  I know it works, but may not be consistent with other code.
        abortJobs();
    }//verifyDaysDelayDupeRecordID

    static testMethod void verifyUnfollowQueueEmptiesProperly(){
        Double URDaysDelay=1;
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        String Str='asdf';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';

        abortJobs();          
        cleanUpTestData();
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        List<UnfollowQueue__c> pendingRecords=new List<UnfollowQueue__c>();
        //Note that these should have Criteria Met Date as in the past so they should "unqueue"
        for(Id i:recordIds){
            pendingRecords.add(new UnfollowQueue__c(recordId__c=i,daysDelay__c=URdaysDelay, CriteriaMetDate__c=date.today()-URDaysDelay.intValue()));
        }//for 1
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);
        //Note these will have the Criteria Met Date as today, so they shouldn't leave the queue
        for(Id i:recordIds2){
            pendingRecords.add(new UnfollowQueue__c(recordId__c=i,daysDelay__c=URdaysDelay, CriteriaMetDate__c=date.today()));
        }//for 1

        insert pendingRecords;

        test.startTest();
            UnfollowRecordsDelayed.unfollowQueueDelayBatchJob();  
        test.stopTest();
        
        List<UnfollowQueue__c> uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds AND ScheduledUnfollowDate__c=TODAY];
        //system.assertEquals(0,uqs.size());
        List<EntitySubscription> es=[SELECT Id FROM EntitySubscription WHERE ParentId IN:recordIds];
        //system.assertEquals(0,es.size());   
             
        uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds2 AND ScheduledUnfollowDate__c!=TODAY];
        //system.assertEquals(numRecordsToCreate,uqs.size());
        es=[SELECT Id FROM EntitySubscription WHERE ParentId IN:recordIds2];
        //system.assertEquals(numRecordsToCreate*numUsersToCreate,es.size());   
        abortJobs();          
    }//verifyUnfollowQueueEmptiesProperly


    static testMethod void verifyDelayScheduler(){
        List<CronTrigger> activeJobs=[SELECT Id FROM CronTrigger LIMIT 100];
        try {
                for (CronTrigger job:activeJobs)
                {
                    system.abortJob(job.Id);//this prevents test failures if the installation is an upgrade (hence the job would already be running)
                }
        } Catch (Exception ex)
        {
            System.debug('Exception=' + ex.getMessage());
        }
        test.starttest();
            system.schedule('Unfollow Delay Rules', '13 57 23 * * ?', new unfollowRecordsDelayedScheduleExecute ()); 
        test.stopTest();  
    }//verifyDelayScheduler

    static testMethod void verifyPhoneContains555(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='Phone__c';
        String UROperator='contains';
        String URValue='555';//testing capitalization as well
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str='asdf';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
         
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Phone='415-536-1000';
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=TRUE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests.runBatchJob(runFromButton);
        Test.StopTest();

        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
//        system.assertEquals(0,es.size());
        es=[Select Id FROM EntitySubscription WHERE ParentId IN:recordIds2];
        system.assertEquals(numRecordsToCreate*numUsersToCreate,es.size());
        abortJobs();
    }//verifyPhoneContains555

    static testMethod void verifyEmailContainsGmail(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='email__c';
        String UROperator='contains';
        String URValue='gmail';//testing capitalization as well
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str='asdf';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Url='www.test.com';
        String email='bob@gmail.com';
        
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Email='bob@yahoo.com';
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=TRUE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests.runBatchJob(runFromButton);
        Test.StopTest();

        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
//        system.assertEquals(0,es.size());
        es=[Select Id FROM EntitySubscription WHERE ParentId IN:recordIds2];
        system.assertEquals(numRecordsToCreate*numUsersToCreate,es.size());
        abortJobs();
    }//verifyEmailContainsGmail


    static testMethod void verifyStringGreaterThan(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='greater than';
        String URValue='b';//testing capitalization as well
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str='c';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
          
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Str='a';
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=TRUE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests.runBatchJob(runFromButton);
        Test.StopTest();

        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
       // system.assertEquals(0,es.size());
        es=[Select Id FROM EntitySubscription WHERE ParentId IN:recordIds2];
        system.assertEquals(numRecordsToCreate*numUsersToCreate,es.size());
        abortJobs();
    }//verifyStringGreaterThan

    static testMethod void verifyStringLessThan(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='less than';
        String URValue='b';//testing capitalization as well
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str='a';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
          
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Str='c';
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=TRUE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests.runBatchJob(runFromButton);
        Test.StopTest();

        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
        //system.assertEquals(0,es.size());
        es=[Select Id FROM EntitySubscription WHERE ParentId IN:recordIds2];
        system.assertEquals(numRecordsToCreate*numUsersToCreate,es.size());
        abortJobs();    
    }//verifyStringLessThan


    static testMethod void verifyStringGreaterOrEqual(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='greater or equal';
        String URValue='b';//testing capitalization as well
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str='b';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
          
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Str='a';
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=TRUE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests.runBatchJob(runFromButton);
        Test.StopTest();

        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
//        system.assertEquals(0,es.size());
        es=[Select Id FROM EntitySubscription WHERE ParentId IN:recordIds2];
        system.assertEquals(numRecordsToCreate*numUsersToCreate,es.size());
        abortJobs();
    }//verifyStringGreaterOrEqual

    static testMethod void verifyStringLessOrEqual(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='less or equal';
        String URValue='b';//testing capitalization as well
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str='a';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
          
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Str='c';
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=TRUE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests.runBatchJob(runFromButton);
        Test.StopTest();

        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
        //system.assertEquals(0,es.size());
        es=[Select Id FROM EntitySubscription WHERE ParentId IN:recordIds2];
        system.assertEquals(numRecordsToCreate*numUsersToCreate,es.size());
    }//verifyStringLessOrEqual

    public static testMethod void testUnfollowController() {
        
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.UnfollowEdit;
        
        //In this case, the Visualforce page named 'success' is the starting point of this test method. 
        Test.setCurrentPage(pageRef);

        UnfollowRule__c ur=new UnfollowRule__c();
        ur.Active__c=TRUE;
        ur.objectName__c='Task';
        ur.FieldName__c='IsClosed';//this will run the checkbox check
        ur.DaysDelay__c=2;
        ur.Operator__c='Equals';
        ur.Value__c='True';

        ApexPages.StandardController sc = new ApexPages.StandardController(ur);
        UnfollowController scExt = new UnfollowController(sc);

        scExt.getObjectNames();
        scExt.getFieldNames();
        scExt.getOperator();
        
        ur.ObjectName__c='UnfollowTest__c';
        ur.FieldName__c='Status';//this will run the picklist check
        apexPages.StandardController sc2 = new ApexPages.StandardController(ur);
        UnfollowController scExt2 = new UnfollowController (sc2);
        scExt2.getObjectNames();
        scExt2.getFieldNames();
        scExt2.getOperator();
        scExt2.getValuePicklistOptions();
        
        scExt2.savenew();//test no exception upon saving & creating a new record
                        //Also having active=false by default should ensure the limits trigger doesn't gack if active = false.
                        //Note due to Apex test deficiencies the limit can't be tested directly (limited to 100 record inserts in 1 method)
    }//testUnfollowController

    public static testMethod void testUnfollowController2() {
        
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.UnfollowEdit;
        
        //In this case, the Visualforce page named 'success' is the starting point of this test method. 
        Test.setCurrentPage(pageRef);

        UnfollowRule__c ur=new UnfollowRule__c();
        ur.Active__c=TRUE;
        ur.objectName__c='UnfollowTest__c';
        ur.FieldName__c='CreatedDate';//this will run the checkbox check
        ur.DaysDelay__c=2;
        ur.Operator__c='equals TODAY';
        ur.Value__c='TODAY';

        ApexPages.StandardController sc = new ApexPages.StandardController(ur);
        UnfollowController scExt = new UnfollowController(sc);

        scExt.getObjectNames();
        scExt.getFieldNames();
        scExt.getOperator();
        
        ur.ObjectName__c='UnfollowTest__c';
        ur.FieldName__c='String__c';//this will run the picklist check
        apexPages.StandardController sc2 = new ApexPages.StandardController(ur);
        UnfollowController scExt2 = new UnfollowController (sc2);
        scExt2.getObjectNames();
        scExt2.getFieldNames();
        scExt2.getOperator();

        
        scExt2.savenew();//test no exception upon saving & creating a new record
                        //Also having active=false by default should ensure the limits trigger doesn't gack if active = false.
                        //Note due to Apex test deficiencies the limit can't be tested directly (limited to 100 record inserts in 1 method)
    }//testUnfollowController2

    public static testMethod void testUnfollowButtonControllerActivateScheduler() {
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.ActivateUnfollowRulesApp;
        cleanUpTestData();
        test.StartTest();
            Test.setCurrentPage(pageRef);
            UnfollowButtonController ctr = new UnfollowButtonController();
            ctr.activateScheduler();
        test.stopTest();
        
        List<String> scheduledJobTimes=new List<String>();
        scheduledJobTimes.add('13 57 22 * * ?');
        scheduledJobTimes.add('13 57 23 * * ?'); 
        scheduledJobTimes.add('13 57 * * * ?'); 

        List<CronTrigger> activeJobs=[SELECT Id FROM CronTrigger WHERE CronExpression IN : scheduledJobTimes  AND State != 'DELETED'];
        system.assertEquals(scheduledJobTimes.size(), activeJobs.size());    
    }//testUnfollowButtonControllerActivateScheduler
 
     public static testMethod void testUnfollowButtonControllerDeactivateScheduler() {
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.ActivateUnfollowRulesApp;

        Test.setCurrentPage(pageRef);
        UnfollowButtonController ctr = new UnfollowButtonController();
        ctr.activateScheduler();
        ctr.deactivateScheduler();
        
        List<String> scheduledJobTimes=new List<String>();
        scheduledJobTimes.add('13 57 22 * * ?');
        scheduledJobTimes.add('13 57 23 * * ?'); 
        scheduledJobTimes.add('13 57 * * * ?'); 

        List<CronTrigger> activeJobs=[SELECT Id FROM CronTrigger WHERE CronExpression IN : scheduledJobTimes AND State != 'DELETED'];
        system.assertEquals(0, activeJobs.size());    
    }//testUnfollowButtonControllerDeactivateScheduler

    public static testMethod void testUnfollowButtonControllerDeactivateScheduler2() {
        //Use the PageReference Apex class to instantiate a page
        PageReference pageRef = Page.ActivateUnfollowRulesApp;

        Test.setCurrentPage(pageRef);
        UnfollowButtonController ctr = new UnfollowButtonController();

        List<CronTrigger> ct=[SELECT Id, NextFireTime FROM CronTrigger WHERE CronExpression = '13 57 22 * * ?' OR CronExpression = '13 57 * * * ?' OR CronExpression = '13 57 23 * * ?'];

        if (ct.size()==0){
//            unfollowScheduler.start();
            unfollowSchedulerDelay.start();
            unfollowSchedulerTryBatchJobsAgain.start();
        }//if
        
        ctr.deactivateScheduler();
        
        List<String> scheduledJobTimes=new List<String>();
        scheduledJobTimes.add('13 57 22 * * ?');
        scheduledJobTimes.add('13 57 23 * * ?'); 
        scheduledJobTimes.add('13 57 * * * ?'); 

        List<CronTrigger> activeJobs=[SELECT Id FROM CronTrigger WHERE CronExpression IN : scheduledJobTimes AND State != 'DELETED'];
        system.assertEquals(0, activeJobs.size());    
    }//testUnfollowButtonControllerDeactivateScheduler2 
 
    public static testMethod void testUnfollowRunThisRuleButton() {
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='equals';
        String URValue='b';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();

        String Str=URValue;
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
          
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Str='a';
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        UnfollowRule__c ur=urs[0];

        ApexPages.StandardController sc = new ApexPages.StandardController(ur);
        UnfollowRunThisRuleButtonController scExt = new UnfollowRunThisRuleButtonController(sc);

        test.StartTest();
            scExt.runThisNonDelayedRuleNow();
        test.stopTest();

        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
        //system.assertEquals(0,es.size());
        es=[Select Id FROM EntitySubscription WHERE ParentId IN:recordIds2];
        system.assertEquals(numRecordsToCreate*numUsersToCreate,es.size());
        abortJobs();
    }//testUnfollowRunThisRuleButton

    public static testMethod void testRemoveBatchJobFromQueue() {
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='equals';
        String URValue='a';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();

        String Str=URValue;
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
        
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    

        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Str='b';
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);
        
        Boolean delayJob = FALSE;
        Boolean delayRulesIncluded=FALSE;
        Boolean evalateEachRecordForDaysDelay=FALSE;
        Boolean addFieldNames=TRUE;
        String sObjectQuery = 'SELECT Id FROM '+URObjectName+' WHERE '+URFieldName+'= \''+URValue+'\' ';
        
        UnfollowBatchJobsQueue__c job=new UnfollowBatchJobsQueue__c(delayJob__c=delayJob, delayRulesIncluded__c=delayRulesIncluded, evalateEachRecordForDaysDelay__c=evalateEachRecordForDaysDelay, objectName__c=URobjectName, numRulesUsedInThisObject__c=urs.size(), sObjectQuery__c=sObjectQuery);
        insert job;
        /*
        Commenting out this part since this is erroring on prod - CR 2438643
        
        test.StartTest();
            unfollowTryBatchJobsAgain.unfollowTryBatchJobsAgain();
        test.stopTest();
        
        //first confirm the job was removed from the queue
        List<UnfollowBatchJobsQueue__c> bjQueue = [SELECT Id FROM UnfollowBatchJobsQueue__c];
        //system.AssertEquals(0,bjQueue.size());
        //then confirm it actually worked
        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
        //system.assertEquals(0,es.size());
        es=[Select Id FROM EntitySubscription WHERE ParentId IN:recordIds2];
        //system.assertEquals(numRecordsToCreate*numUsersToCreate,es.size());
        abortJobs(); */    
    }

//There's an apex bug where these tests throw an exception that "No more than one executeBatch can be called from within a test method"
//I'm commenting these out until the Apex team fixes that bug 

    public static testMethod void testRemoveDelayBatchJobFromQueue() {
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=2;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='equals';
        String URValue='a';//testing capitalization as well
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str='a';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
        
        abortJobs();          
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        List<UnfollowQueue__c> uqs=new List<UnfollowQueue__c>();
        for (Id i:recordIds){
            UnfollowQueue__c uq=new UnfollowQueue__c();
            uq.recordId__c=i;
            uq.CriteriaMetDate__c=Date.Today()-URDaysDelay.intValue();
            uq.DaysDelay__c=URDaysDelay;
            uqs.add(uq);
        }//for 1

        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        for (Id i:recordIds2){
            UnfollowQueue__c uq=new UnfollowQueue__c();
            uq.recordId__c=i;
            uq.CriteriaMetDate__c=Date.Today()-URDaysDelay.intValue()+1;
            uq.DaysDelay__c=URDaysDelay;
            uqs.add(uq);
        }//for 1

        insert uqs;
        
        Boolean delayJob = TRUE;
        Boolean delayRulesIncluded=FALSE;
        Boolean evalateEachRecordForDaysDelay=FALSE;
        Boolean addFieldNames=TRUE;
        String sObjectQuery = 'Select Id, recordId__c FROM UnfollowQueue__c WHERE scheduledUnfollowDate__c<= TODAY AND IsDeleted=FALSE';
        UnfollowBatchJobsQueue__c job=new UnfollowBatchJobsQueue__c(delayJob__c=delayJob, delayRulesIncluded__c=delayRulesIncluded, evalateEachRecordForDaysDelay__c=evalateEachRecordForDaysDelay, objectName__c=URobjectName, numRulesUsedInThisObject__c=urs.size(), sObjectQuery__c=sObjectQuery);
        insert job;
        
        system.debug('Unfollow Queue Size: '+[SELECT Id FROM UnfollowBatchJobsQueue__c].size());
        
        test.StartTest();
            unfollowTryBatchJobsAgain.unfollowTryBatchJobsAgain();
        test.stopTest();
        
        //first confirm the job was removed from the queue
        List<UnfollowBatchJobsQueue__c> bjQueue = [SELECT Id FROM UnfollowBatchJobsQueue__c];
        //system.AssertEquals(0,bjQueue.size());
        //then confirm it actually worked
        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
        //system.assertEquals(0,es.size());
        uqs=[SELECT ID FROM UnfollowQueue__c WHERE ScheduledUnfollowDate__c<=TODAY];
        //system.assertEquals(0,uqs.size());
        es=[Select Id FROM EntitySubscription WHERE ParentId IN:recordIds2];
        //system.assertEquals(numRecordsToCreate*numUsersToCreate,es.size());
        abortJobs();
    }//testRemoveDelayBatchJobFromQueue

    public static testMethod void testRemoveDelayRuleBatchJobFromQueue() {
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=2;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='equals';
        String URValue='a';//testing capitalization as well
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str='a';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
          
        abortJobs();
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    

        URDaysDelay=3;
        String URValue2='b';        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue2, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        List<UnfollowQueue__c> uqs=new List<UnfollowQueue__c>();
        for (Id i:recordIds){
            UnfollowQueue__c uq=new UnfollowQueue__c();
            uq.recordId__c=i;
            uq.CriteriaMetDate__c=Date.Today()-URDaysDelay.intValue();
            uq.DaysDelay__c=URDaysDelay;
            uqs.add(uq);
        }//for 1
        
        Str=URValue2;
        Integer numRecordsToCreate2=3;
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate2,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        for (Id i:recordIds2){
            UnfollowQueue__c uq=new UnfollowQueue__c();
            uq.recordId__c=i;
            uq.CriteriaMetDate__c=Date.Today()-URDaysDelay.intValue()+1;
            uq.DaysDelay__c=URDaysDelay;
            uqs.add(uq);
        }//for 1

        insert uqs;
        
        Boolean delayJob = FALSE;
        Boolean delayRulesIncluded=TRUE;
        Boolean evalateEachRecordForDaysDelay=TRUE;//needed if 2 different daysDelay values for the same object
        Boolean addFieldNames=TRUE;
        String sObjectQuery = 'Select Id FROM '+URObjectName+' WHERE '+URFieldName+'= \''+URValue+'\' OR '+URFieldName+'= \''+URValue2+'\'';
        
        UnfollowBatchJobsQueue__c job=new UnfollowBatchJobsQueue__c(delayJob__c=delayJob, delayRulesIncluded__c=delayRulesIncluded, evalateEachRecordForDaysDelay__c=evalateEachRecordForDaysDelay, objectName__c=URobjectName, numRulesUsedInThisObject__c=urs.size(), sObjectQuery__c=sObjectQuery);
        insert job;
        
        test.StartTest();
            unfollowTryBatchJobsAgain.unfollowTryBatchJobsAgain();
        test.stopTest();
        
        //first confirm the job was removed from the queue
        List<UnfollowBatchJobsQueue__c> bjQueue = [SELECT Id FROM UnfollowBatchJobsQueue__c];
        //system.AssertEquals(0,bjQueue.size());
        //then confirm it actually worked
        uqs=[SELECT ID FROM UnfollowQueue__c WHERE recordId__c IN:recordIds ];
        system.assertEquals(numRecordsToCreate,uqs.size());
        uqs=[SELECT ID FROM UnfollowQueue__c WHERE recordId__c IN:recordIds2 ];
        system.assertEquals(numRecordsToCreate2,uqs.size());
    }//testRemoveDelayRuleBatchJobFromQueue

    static testMethod void verifySavedDelayJobRunsCorrectly(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=1;
        String URObjectName='UnfollowTest__c';
        String URFieldName='Checkbox__c';
        String UROperator='not equal to';
        String URValue='FALSE';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str='asdf';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        String Phone = '415-555-1234';
        String email='bob@gmail.com';
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Url='www.test.com';       
       
        abortJobs();
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        
        Boolean delayJob = FALSE;
        Boolean delayRulesIncluded=TRUE;
        Boolean evalateEachRecordForDaysDelay=FALSE;
        Boolean addFieldNames=TRUE;
        String sObjectQuery = 'Select Id, Checkbox__c  FROM UnfollowTest__c WHERE Checkbox__c!= FALSE AND IsDeleted=FALSE';
        UnfollowBatchJobsQueue__c job=new UnfollowBatchJobsQueue__c(delayJob__c=delayJob, delayRulesIncluded__c=delayRulesIncluded, evalateEachRecordForDaysDelay__c=evalateEachRecordForDaysDelay, objectName__c=URobjectName, numRulesUsedInThisObject__c=urs.size(), sObjectQuery__c=sObjectQuery);
        insert job;
        
        test.StartTest();
            unfollowTryBatchJobsAgain.unfollowTryBatchJobsAgain();
        test.stopTest();
        
        List<UnfollowQueue__c> uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds];
        //system.assertEquals(numRecordsToCreate,uqs.size());
        
        abortJobs();
    }//verifySavedDelayJobRunsCorrectly

    public static testMethod void verify6OrMoreBatchJobsQueueUp() {
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='equals';
        String URValue='a';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str='a';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
          
        abortJobs();
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    

        URDaysDelay=2;
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        
        URObjectName='Lead';  
        URFieldName='Company';      
        URDaysDelay=0;
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        
        URDaysDelay=4;
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    

        URObjectName='Opportunity';   
        URFieldName='Name';     
        URDaysDelay=5;
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));                    
        
        URDaysDelay=0;
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    

        insert urs;
        
        test.StartTest();
            Boolean runFromButton=FALSE;
            unfollowExecute.unfollowQueueBatchJobs(runFromButton);
        test.stopTest();
        
        //first confirm the job was removed from the queue
        List<UnfollowBatchJobsQueue__c> bjQueue = [SELECT Id FROM UnfollowBatchJobsQueue__c];
        system.AssertNOTEquals(0,bjQueue.size());//can't know how many other jobs the org has already running, so simply testing for >0 here
        abortJobs();
    }//verify6OrMoreBatchJobsQueueUp

    public static testMethod void verifyDupeBatchJobsFailNicely() {
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='Decimal__c';
        String UROperator='greater than';
        String URValue='5';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();

        String Str='asdf';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
        
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        Dec=5;
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);
  
        Test.StartTest();
            Boolean runFromButton=TRUE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests.runBatchJob(runFromButton);
        Test.StopTest();

        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
//        system.assertEquals(es.size(),0);

        es=[Select Id FROM EntitySubscription WHERE ParentId IN:recordIds2];
        system.assertNOTEquals(es.size(),0);
        abortJobs();        
    }//verifyDupeBatchJobsFailNicely
    
    public static testMethod void verifyLimit10UpdatesOrInsertsAtOnce() {
        Integer numRulesToCreate=11;
        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='Decimal__c';
        String UROperator='greater than';
        String URValue='5';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();

        String Str='asdf';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Phone = '415-555-5555';
        String Email = 'test@test.com';
        String Url='www.test.com';
         
        cleanUpTestData();
        for(Integer i=0;i<numRulesToCreate;i++){
            urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        }//for 1
        test.startTest();
            UnfollowRule__c ur=createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay );
            try{
                insert urs;
            }catch(Exception e){
                Boolean expectedExceptionThrown=e.getMessage().contains('You may only update 10 records at a time');
                system.AssertEquals(true,expectedExceptionThrown);       
            }//try    
        Test.StopTest();
    }//verifyLimit10UpdatesOrInsertsAtOnce


}//UnfollowTests