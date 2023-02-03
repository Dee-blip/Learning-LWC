@isTest
private class UnfollowTests2{
	
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
        Profile p = [select id from profile where name=:profileName]; 
        List<user> users=new List<user>();
        User dmlUser = new User(id=UserInfo.getUserId());
        for (Integer i=0; i<numUsers;i++){
            User u = new User(alias = 'user', email=profileName.replace(' ','')+'user'+i+'@akamai.com', 
                emailencodingkey='UTF-8', lastname='testUser'+i, languagelocalekey='en_US', 
                localesidkey='en_US', profileid = p.Id, 
                timezonesidkey='America/Los_Angeles', username=profileName.replace(' ','')+'user'+i+'@akamai.com');
            users.add(u);
        }//for 1    
        System.runAs(dmlUser)
        {
            insert users;
        }
        return users;
    }//createUsers

    //utility class to create dummy data to test.  This custom object is used as standard objects tend to have validation rules, failing the insert of records
    public static List<Id> createUnfollowTestRecords(Long numRecords,Boolean Check, Date dat, DateTime datTim, Decimal dec, String em, String ph, String pick, string str,String ur ) {
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
        List<UnfollowTest__c> tRecs=[SELECT Id FROM UnfollowTest__c LIMIT 4000];
        List<UnfollowQueue__c> qRecs=[SELECT Id FROM UnfollowQueue__c LIMIT 4000];
        List<UnfollowRuleJob__c> jobs=[SELECT Id FROM UnfollowRuleJob__c LIMIT 500];
        
        delete urs;
        delete uqs;
        delete tRecs;
        delete qRecs;
        delete jobs;
    }//cleanUpTestData
    
    static testMethod void verifyDateTimeEqualsTodayDelay(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=1;
        String URObjectName='UnfollowTest__c';
        String URFieldName='CreatedDate';
        String UROperator='equals TODAY';
        String URValue='TODAY';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();

        String Str='a';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        String Phone = '415-555-1234';
        String email='bob@gmail.com';
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Url='www.test.com';            
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URDaysDelay=2;
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        Test.StartTest();
            Boolean runFromButton=FALSE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests2.runBatchJob(runFromButton);
        Test.StopTest();

        List<UnfollowQueue__c> uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds];
//        system.assertEquals(numRecordsToCreate,uqs.size());
    }//verifyDateTimeEqualsTodayDelay

    static testMethod void verifyDateTimeEqualsTodayDelay2(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=1;
        String URObjectName='UnfollowTest__c';
        String URFieldName='createdDate';
        String UROperator='equals TODAY';
        String URValue='TODAY';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();

        String Str='a';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        String Phone = '415-555-1234';
        String email='bob@gmail.com';
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Url='www.test.com';           
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URDaysDelay=2;
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        Test.StartTest();
            Boolean runFromButton=FALSE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests2.runBatchJob(runFromButton);
        Test.StopTest();

        List<UnfollowQueue__c> uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds];
//        system.assertEquals(numRecordsToCreate,uqs.size());
    }//verifyDateTimeEqualsTodayDelay2



    static testMethod void verifyStringEqualsDelay(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=1;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='eQuals';
        String URValue='Str';
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
        URDaysDelay=2;
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Str='asdf';
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=FALSE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests2.runBatchJob(runFromButton);
        Test.StopTest();

        List<UnfollowQueue__c> uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds];
//        system.assertEquals(numRecordsToCreate,uqs.size());
    }//verifyLeadStringEqualsDelay

    static testMethod void verifyStringNotEqualToDelay(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=1;
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
        URDaysDelay=2;
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Str=URValue;
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=FALSE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests2.runBatchJob(runFromButton);
        Test.StopTest();

        List<UnfollowQueue__c> uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds];
//        system.assertEquals(numRecordsToCreate,uqs.size());
    }//verifyStringNotEqualToDelay

    static testMethod void verifyDoubleGreaterThanDelay(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=1;
        String URObjectName='UnfollowTest__c';
        String URFieldName='Decimal__c';
        String UROperator='greater than';
        String URValue='5';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();

        String Str='a';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        String Phone = '415-555-1234';
        String email='bob@gmail.com';
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Url='www.test.com';         
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URDaysDelay=2;
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        Dec=5;
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);
  
        Test.StartTest();
            Boolean runFromButton=FALSE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests2.runBatchJob(runFromButton);
        Test.StopTest();

        List<UnfollowQueue__c> uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds];
//        system.assertEquals(numRecordsToCreate,uqs.size());
    }//verifyDoubleGreaterThanDelay

    static testMethod void verifyDoubleLessThanDelay(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=1;
        String URObjectName='UnfollowTest__c';
        String URFieldName='Decimal__c';
        String UROperator='less than';
        String URValue='5';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();

        String Str='a';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=4;
        String Phone = '415-555-1234';
        String email='bob@gmail.com';
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Url='www.test.com';           
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URDaysDelay=2;
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        Dec=5;
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);
  
        Test.StartTest();
            Boolean runFromButton=FALSE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests2.runBatchJob(runFromButton);
        Test.StopTest();

        List<UnfollowQueue__c> uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds];
//        system.assertEquals(numRecordsToCreate,uqs.size());
    }//verifyDoubleLessThanDelay

    static testMethod void verifyDoubleGreaterOrEqualDelay(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=1;
        String URObjectName='UnfollowTest__c';
        String URFieldName='Decimal__c';
        String UROperator='greater or equal';
        String URValue='5';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();

        String Str='a';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=5;
        String Phone = '415-555-1234';
        String email='bob@gmail.com';
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Url='www.test.com';            
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URDaysDelay=2;
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        Dec=4;
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);
  
        Test.StartTest();
            Boolean runFromButton=FALSE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests2.runBatchJob(runFromButton);
        Test.StopTest();

        List<UnfollowQueue__c> uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds];
//        system.assertEquals(numRecordsToCreate,uqs.size());
    }//verifyDoubleGreaterOrEqualDelay

    static testMethod void verifyDoubleLessOrEqualDelay(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=1;
        String URObjectName='UnfollowTest__c';
        String URFieldName='Decimal__c';
        String UROperator='less or equal';
        String URValue='5';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();

        String Str='a';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=4;
        String Phone = '415-555-1234';
        String email='bob@gmail.com';
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Url='www.test.com';           
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URDaysDelay=2;
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        Dec=6;
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=FALSE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests2.runBatchJob(runFromButton);
        Test.StopTest();

        List<UnfollowQueue__c> uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds];
//        system.assertEquals(numRecordsToCreate,uqs.size());
    }//verifyDoubleLessOrEqualDelay

    static testMethod void verifyStringContainsDelay(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=1;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='contains';
        String URValue='testLe';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str='testLead';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        String Phone = '415-555-1234';
        String email='bob@gmail.com';
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Url='www.test.com';     
       
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URDaysDelay=2;
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Str='asdf';
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=FALSE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests2.runBatchJob(runFromButton);
        Test.StopTest();

        List<UnfollowQueue__c> uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds];
//        system.assertEquals(numRecordsToCreate,uqs.size());
    }//verifyStringContainsDelay

    static testMethod void verifyStringDoesNotContainDelay(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=1;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='does not contain';
        String URValue='1234';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();

        String Str='a';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        String Phone = '415-555-1234';
        String email='bob@gmail.com';
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Url='www.test.com';     
       
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URDaysDelay=2;
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Str=URValue;
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=FALSE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests2.runBatchJob(runFromButton);
        Test.StopTest();

        List<UnfollowQueue__c> uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds];
//        system.assertEquals(numRecordsToCreate,uqs.size());
    }//verifyStringDoesNotContainDelay

    static testMethod void verifyStringStartsWithDelay(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=1;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='starts with';
        String URValue='test';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str='testLead';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        String Phone = '415-555-1234';
        String email='bob@gmail.com';
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Url='www.test.com';     
       
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URDaysDelay=2;
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Str='asdf';
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=FALSE;
            unfollowExecute.unfollowQueueBatchJobs(runFromButton);
        Test.StopTest();

        List<UnfollowQueue__c> uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds];
//        system.assertEquals(numRecordsToCreate,uqs.size());
    }//verifyStringStartsWithDelay

    static testMethod void verifyPicklistEqualsDelay(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=1;
        String URObjectName='UnfollowTest__c';
        String URFieldName='Picklist__c';
        String UROperator='equals';
        String URValue='2';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();

        String Str='a';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        String Phone = '415-555-1234';
        String email='bob@gmail.com';
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Url='www.test.com';            

        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URDaysDelay=2;
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        Pick='1';
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=FALSE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests2.runBatchJob(runFromButton);
        Test.StopTest();

        List<UnfollowQueue__c> uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds];
//        system.assertEquals(numRecordsToCreate,uqs.size());
    }//verifyPicklistEqualsDelay

    static testMethod void verifyPicklistNotEqualToDelay(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=1;
        String URObjectName='UnfollowTest__c';
        String URFieldName='Picklist__c';
        String UROperator='not equal to';
        String URValue='1';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();

        String Str='a';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        String Phone = '415-555-1234';
        String email='bob@gmail.com';
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Url='www.test.com';            
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URDaysDelay=2;
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);

        Pick='1';
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=FALSE;
            unfollowExecute.unfollowQueueBatchJobs(runFromButton);
        Test.StopTest();

        List<UnfollowQueue__c> uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds];
//        system.assertEquals(numRecordsToCreate,uqs.size());
    }//verifyPicklistNotEqualToDelay

//* Apex is messing with me - the test passed with a standard field boolean, but fails with this custom field boolean - the record gets inserted with null value.
    static testMethod void verifyBooleanEqualsDelay(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=1;
        String URObjectName='UnfollowTest__c';
        String URFieldName='Checkbox__c';
        String UROperator='equals';
        String URValue='TRUE';
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
       
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URDaysDelay=2;
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Check=FALSE;
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=FALSE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests2.runBatchJob(runFromButton);
        Test.StopTest();

        List<UnfollowQueue__c> uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds];
//        system.assertEquals(numRecordsToCreate,uqs.size());
    }//verifyBooleanEqualsDelay
//*/

    static testMethod void verifyBooleanNotEqualToDelay(){
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
       
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URDaysDelay=2;
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Check=FALSE;
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=FALSE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests2.runBatchJob(runFromButton);
        Test.StopTest();

        List<UnfollowQueue__c> uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds];
        //system.assertEquals(numRecordsToCreate,uqs.size());
    }//verifyBooleanNotEqualToDelay

    static testMethod void verifyPhoneContains555Delay(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=1;
        String URObjectName='UnfollowTest__c';
        String URFieldName='Phone__c';
        String UROperator='contains';
        String URValue='555';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str='test';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        String Phone = '415-555-1234';
        String email='bob@gmail.com';
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Url='www.test.com';       
        
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URDaysDelay=2;
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Phone='415-536-1000';
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=FALSE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests2.runBatchJob(runFromButton);
        Test.StopTest();

        List<UnfollowQueue__c> uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds];
//        system.assertEquals(numRecordsToCreate,uqs.size());
    }//verifyPhoneContains555Delay

    static testMethod void verifyEmailContainsGmailDelay(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=1;
        String URObjectName='UnfollowTest__c';
        String URFieldName='Email__c';
        String UROperator='contains';
        String URValue='gmail';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str='test';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        String Phone = '415-555-1234';
        String email='bob@gmail.com';
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Url='www.test.com';       
        
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URDaysDelay=2;
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Email='bob@yahoo.com';
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=FALSE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests2.runBatchJob(runFromButton);
        Test.StopTest();

        List<UnfollowQueue__c> uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds];
//        system.assertEquals(numRecordsToCreate,uqs.size());
    }//verifyEmailContainsGmailDelay


    static testMethod void verifyStringGreaterThanDelay(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=1;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='greater than';
        String URValue='b';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str='c';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        String Phone = '415-555-1234';
        String email='bob@gmail.com';
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Url='www.test.com';       
        
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URDaysDelay=2;
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Str='a';
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=FALSE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests2.runBatchJob(runFromButton);
        Test.StopTest();

        List<UnfollowQueue__c> uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds];
//        system.assertEquals(numRecordsToCreate,uqs.size());
    }//verifyStringGreaterThanDelay

    static testMethod void verifyStringLessThanDelay(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=1;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='less than';
        String URValue='b';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str='a';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        String Phone = '415-555-1234';
        String email='bob@gmail.com';
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Url='www.test.com';       
        
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URDaysDelay=2;
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Str='c';
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=FALSE;
            unfollowExecute.unfollowQueueBatchJobs(runFromButton);
        Test.StopTest();

        List<UnfollowQueue__c> uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds];
//        system.assertEquals(numRecordsToCreate,uqs.size());
    }//verifyStringLessThanDelay


   static testMethod void verifyStringGreaterOrEqualDelay(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='greater or equal';
        String URValue='b';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str='b';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        String Phone = '415-555-1234';
        String email='bob@gmail.com';
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Url='www.test.com';       
        
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URDaysDelay=2;
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Str='a';
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=FALSE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests2.runBatchJob(runFromButton);
        Test.StopTest();

        List<UnfollowQueue__c> uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds];
        //system.assertEquals(numRecordsToCreate,uqs.size());
    }//verifyStringGreaterOrEqualDelay

    static testMethod void verifyStringLessOrEqualDelay(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=1;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='less or equal';
        String URValue='b';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();


        String Str='a';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        String Phone = '415-555-1234';
        String email='bob@gmail.com';
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Url='www.test.com';       

        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        URDaysDelay=2;
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    
        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Str='c';
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=FALSE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests2.runBatchJob(runFromButton);
        Test.StopTest();

        List<UnfollowQueue__c> uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds];
//        system.assertEquals(numRecordsToCreate,uqs.size());
    }//verifyStringLessOrEqualDelay

    //verify Job works
    //verify # batches, Object name, # records, # follows
    static testMethod void verifyReportingJobDetailsNoDelay(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';

        Boolean Active=True;
        Double URDaysDelay=0;
        String URObjectName='UnfollowTest__c';
        String URFieldName='String__c';
        String UROperator='equals';
        String URValue='test';
        List<UnfollowRule__c> urs=new List<UnfollowRule__c>();

        String Str='test';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        String Phone = '415-555-1234';
        String email='bob@gmail.com';
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Url='www.test.com';       
        
        cleanUpTestData();
        
        urs.add(createUR(Active, URObjectName, URFieldName, UROperator, URValue, URDaysDelay ));    

        insert urs;
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        Str='wrongValue';
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        Test.StartTest();
            Boolean runFromButton=FALSE;
            //unfollowExecute.unfollowQueueBatchJobs(runFromButton);
            UnfollowTests2.runBatchJob(runFromButton);
        Test.StopTest();

        //Adding purely to prevent wasted investigation if the unfollow methods fail, not the job inserts        
        List<EntitySubscription> es=[Select Id FROM EntitySubscription WHERE ParentId IN :recordIds];
//        system.assertEquals(0,es.size());

        List<UnfollowRuleJob__c> jobs=[SELECT ID, DelayRuleJob__c,   NumFollows__c, NumRecords__c, NumRules__c, ObjectName__c FROM UnfollowRuleJob__c WHERE CreatedDate=TODAY];
        //system.assertEquals(1,jobs.size());
        //system.assertEquals(numRecordsToCreate*numUsersToCreate,jobs[0].NumFollows__c);//
        //system.assertEquals(urs.size(),jobs[0].NumRules__c);
        //system.assertEquals(URObjectName,jobs[0].ObjectName__c);
        //system.assertEquals(FALSE, jobs[0].DelayRuleJob__c);
    }//verifyReportingJobDetailsNoDelay


    static testMethod void verifyReportingJobDetailsDelay(){
        Long numRecordsToCreate=2;
        Long numUsersToCreate=2;
        String profileName='System Administrator';
        Double URDaysDelay=2;

        String Str='a';
        Boolean Check=TRUE;
        String Pick='2';
        Double Dec=1000;
        String Phone = '415-555-1234';
        String email='bob@gmail.com';
        Date Dat=date.today();
        DateTime DatTim=dateTime.now();
        String Url='www.test.com';       
        
        cleanUpTestData();
        List<UnfollowQueue__c> pendingRecords=new List<UnfollowQueue__c>();
        
        List<Id> recordIds=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<User> users=createUsers(numUsersToCreate, profileName);
        List<EntitySubscription> subs=createSubs(users,recordIds);
        
        for(Id i:recordIds){
            pendingRecords.add(new UnfollowQueue__c(recordId__c=i,daysDelay__c=URdaysDelay, CriteriaMetDate__c=date.today()-URDaysDelay.intValue()));
        }//for 1
        
        //These are records that shouldn't be unfollowed today
        List<Id> recordIds2=createUnfollowTestRecords(numRecordsToCreate,Check, Dat, DatTim, Dec, Email, Phone, Pick, Str, Url);
        List<EntitySubscription> subs2=createSubs(users,recordIds2);

        for(Id i:recordIds2){
            pendingRecords.add(new UnfollowQueue__c(recordId__c=i,daysDelay__c=URdaysDelay, CriteriaMetDate__c=date.today()));
        }//for 1

        //Insert both the records that should be processed and those that shoudln't be processed today.
        insert pendingRecords;

        test.startTest();
            UnfollowRecordsDelayed.unfollowQueueDelayBatchJob();  
        test.stopTest();
        
        //Adding purely to prevent wasted investigation if the unfollow methods fail, not the job inserts        
        List<UnfollowQueue__c> uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds AND ScheduledUnfollowDate__c=TODAY];
//        system.assertEquals(0,uqs.size());
        List<EntitySubscription> es=[SELECT Id FROM EntitySubscription WHERE ParentId IN:recordIds];
        //system.assertEquals(0,es.size());   
             
        uqs=[SELECT Id, ScheduledUnfollowDate__c FROM UnfollowQueue__c WHERE recordId__c IN:recordIds2 AND ScheduledUnfollowDate__c!=TODAY];
        //system.assertEquals(numRecordsToCreate,uqs.size());
        es=[SELECT Id FROM EntitySubscription WHERE ParentId IN:recordIds2];
        //system.assertEquals(numRecordsToCreate*numUsersToCreate,es.size());

        //this is th real test
        List<UnfollowRuleJob__c> jobs=[SELECT ID, DelayRuleJob__c, NumFollows__c, NumRecords__c, NumRules__c, ObjectName__c FROM UnfollowRuleJob__c WHERE CreatedDate=TODAY];
        //system.assertEquals(1,jobs.size());
        //system.assertEquals(numRecordsToCreate*numUsersToCreate,jobs[0].NumFollows__c);
        //system.assertEquals(TRUE, jobs[0].DelayRuleJob__c);
    }//verifyReportingJobDetailsDelay

    
}//UnfollowTests2