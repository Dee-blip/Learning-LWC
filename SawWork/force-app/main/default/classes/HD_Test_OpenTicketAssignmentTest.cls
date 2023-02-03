/*
* File Name: HD_Test_OpenTicketAssignmentTest
* Description : Test class for HD_OpenTicketAssignment
* @author :
* Modification Log ===============================================================
* Date 				Author 					Modification
* Aug 08th, 2020    Aneesh Budnar           PRTORES-1810 - Code scanner fixes
* Dec 23rd, 2020    Aneesh Budnar           PRTORES-342 - Test class code coverage - 6th and Final
*/
@isTest(SeeAllData=false)
private class HD_Test_OpenTicketAssignmentTest {
    
    //category map
    static Map<String,BMCServiceDesk__Category__c> categoryMap = new Map<String,BMCServiceDesk__Category__c>();
    //urgency map
    static Map<String,BMCServiceDesk__Urgency__c> urgencyMap = new Map<String,BMCServiceDesk__Urgency__c>();
    static Map<String,BMCServiceDesk__Impact__c> impactMap = new Map<String,BMCServiceDesk__Impact__c>();
    static BMCServiceDesk__Category__c telecomCategory;
    static BMCServiceDesk__Urgency__c urgency1;
    static BMCServiceDesk__Urgency__c urgency2;
    static List<BMCServiceDesk__BMC_BaseElement__c> serviceList;
    static List<HD_Urgency_Service_Mapping__c> urgencyServiceMapping;
    static HD_Urgency_Service_Mapping__c urgencyServiceMapping1;
    static  HD_Urgency_Service_Mapping__c urgencyServiceMapping2;
    static BMCServiceDesk__BMC_BaseElement__c SampleService1;
    static BMCServiceDesk__BMC_BaseElement__c SampleService2;
    //static HD_DEFAULT_CATEGORY__c Telecom_Category;
    //static String Tel_Category;
    static Threshold__c testThreshold;
    static List<OpsResource__c> testResources = new List<OpsResource__c>();
    static OpsResource__c testResource1;
    static OpsResource__c testResource2;

    static List<BMCServiceDesk__Incident__c> testIncidents = new List<BMCServiceDesk__Incident__c>();
    static BMCServiceDesk__Incident__c  testIncident1;
    static BMCServiceDesk__Incident__c  testIncident2;
    static List<BMCServiceDesk__Incident__c> incList = new List<BMCServiceDesk__Incident__c>();

    static{
        try
        {
        	HD_Test_Data_Factory.init();
            ManagedPkgErrorClass.isFromManagedPackage=false; 
            /*Telecom_Category =HD_DEFAULT_CATEGORY__c.getInstance('Telecom');
            Tel_Category = Telecom_Category.Category_Name__c;
            HD_TestClassCorrectionForTrigger.throwMappingError = true;
            List<BMCServiceDesk__Category__c> categoryList = [SELECT Name,ID FROM BMCServiceDesk__Category__c WHERE Name= :Tel_Category limit 1];          
            if(categoryList.size()>0){
            for(BMCServiceDesk__Category__c category : categoryList)
                categoryMap.put(category.Name,category);
            }*/
            SampleService1= new BMCServiceDesk__BMC_BaseElement__c(Name='SampleService1',BMCServiceDesk__Name__c='SampleService1');
            SampleService2= new BMCServiceDesk__BMC_BaseElement__c(Name='SampleService2',BMCServiceDesk__Name__c='SampleService2');
            insert(SampleService1);
            insert(SampleService2);
            List<BMCServiceDesk__Category__c> categoryList = new List<BMCServiceDesk__Category__c>();
            System.debug('------>'+CategoryMap.get('Telecom'));
            if (!CategoryMap.containsKey('Telecom'))
            {
               telecomCategory= new BMCServiceDesk__Category__c(Name='Telecom',BMCServiceDesk__AvailableForServiceCatalog__c = TRUE, BMCServiceDesk__AvailableForIncidents__c = TRUE);
               insert telecomCategory ;
               CategoryMap.put('Telecom',telecomCategory);
            }
            else
            { 
             BMCServiceDesk__Category__c cat = new BMCServiceDesk__Category__c();
             cat = CategoryMap.get('Telecom');
             cat.BMCServiceDesk__AvailableForIncidents__c = TRUE;
             update cat;
            }
            if(categoryList.size()>0)
            {
                insert categoryList;
            }

        //getting Urgencies
        for(BMCServiceDesk__Urgency__c urgency : [select Id,Name from BMCServiceDesk__Urgency__c limit 100])
        {
            urgencyMap.put(urgency.Name,urgency);
        }
        if(!urgencyMap.containsKey('Severity 3'))
        {
            urgency1 = new BMCServiceDesk__Urgency__c(Name='Severity 3');
            insert urgency1;
            urgencyMap.put('Severity 3',urgency1);
        }
        if(!urgencyMap.containsKey('Severity 4'))
        {
         urgency2 =new BMCServiceDesk__Urgency__c(Name='Severity 4');
         insert urgency2;
         urgencyMap.put('Severity 4',urgency2);
        }
        List<HD_Ticket_Priority__c> priority_list = new List<HD_Ticket_Priority__c>();
        HD_Ticket_Priority__c priority_setting;
        HD_Ticket_Priority__c priority_setting1;
        HD_Ticket_Priority__c priority_setting2;
        if(HD_Ticket_Priority__c.getInstance('3') == null){
            System.debug('ABCD 3');
            priority_setting = new HD_Ticket_Priority__c();
            priority_setting.Name = '3';
            priority_setting.Urgency_Id__c = urgencyMap.get('Severity 3').id;
            priority_setting.Urgency_Name__c = 'Severity 3';
            priority_list.add(priority_setting);
        }
        if(HD_Ticket_Priority__c.getInstance('4') == null){
            System.debug('ABCD 4');
            priority_setting1 = new HD_Ticket_Priority__c();
            priority_setting1.Name = '4';
            priority_setting1.Urgency_Id__c = urgencyMap.get('Severity 4').id;
            priority_setting1.Urgency_Name__c = 'Severity 4';
            priority_list.add(priority_setting1);
        }
        if(HD_Ticket_Priority__c.getInstance('default') == null){
            System.debug('ABCD D');
            priority_setting2 = new HD_Ticket_Priority__c();
            priority_setting2.Name = 'default';
            priority_setting2.Urgency_Id__c = urgencyMap.get('Severity 4').id;
            priority_setting2.Urgency_Name__c = 'Severity 4';
            priority_setting2.Priority_Name__c = '4';
            priority_list.add(priority_setting2);
        }
        insert priority_list;
        //Creating Business Service of "Unknown" type.
        serviceList  =[Select ID,Name From BMCServiceDesk__BMC_BaseElement__c Where BMCServiceDesk__Name__c='SampleService1' or BMCServiceDesk__Name__c='SampleService2' Limit 2]; 
        //system.AssertNotEquals(serviceList,Null);
        urgencyServiceMapping = new List<HD_Urgency_Service_Mapping__c>();
        //Creting mapping between Urgency and Services
        urgencyServiceMapping1 = new HD_Urgency_Service_Mapping__c();        
        urgencyServiceMapping1.HD_Urgency__c=urgencyMap.get('Severity 3').id;
        urgencyServiceMapping1.HD_Service__c=serviceList[0].id;
        urgencyServiceMapping.add(urgencyServiceMapping1);
        urgencyServiceMapping2 = new HD_Urgency_Service_Mapping__c();
        urgencyServiceMapping2.HD_Urgency__c=urgencyMap.get('Severity 4').id;
        urgencyServiceMapping2.HD_Service__c=serviceList[1].id;
        urgencyServiceMapping.add(urgencyServiceMapping2);
        insert urgencyServiceMapping;
        system.debug('--------------> '+telecomCategory);
        //Impact MApping
        for(BMCServiceDesk__Impact__c impactlow : [ select Id,Name from BMCServiceDesk__Impact__c where NAME = 'LOW' LIMIT 1 ])
        {
            impactMap.put(impactlow.Name,impactlow);
        }
            
        if(!impactMap.containsKey('LOW'))
        {
         BMCServiceDesk__Impact__c low =new BMCServiceDesk__Impact__c(Name='LOW');
         insert low;
         impactMap.put('LOW',low);
        }

            testThreshold = new Threshold__c();
            testThreshold.Description__c = 'Test Threshold';
            testThreshold.Is_Active__c  = true;
            testThreshold.Max_tickets_per_job__c = 10;
            testThreshold.Max_tickets_per_resource__c = 5;
            testThreshold.Max_tickets_per_week__c   = 20;
            testThreshold.Queue_to_use__c = 'Default Queue';
            testThreshold.Interval__c = 2;
            testThreshold.Job_Run_Time__c = '00,01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23';
            testThreshold.Team_Email__c = System.UserInfo.getUserEmail();
            insert testThreshold;
            
            testResource1 = new OpsResource__c();
            testResource1.Is_Available__c = true;
            testResource1.ResourceName__c = 'testResource1';
            testResource1.ShiftTimeCode__c = 9;
            //testResource1.ShiftTimeCode_Monday__c = 9;
            //testResource1.ShiftTimeCode_Tuesday__c = 9;
            //testResource1.ShiftTimeCode_Wednesday__c = 9;
            //testResource1.ShiftTimeCode_Thursday__c = 9;
            //testResource1.ShiftTimeCode_Friday__c = 9;
            testResource1.Team_Name__c ='Default Queue';
			User user = [SELECT Id FROM User WHERE USername like '%abudnar@akamai.com%' LIMIT 1];
            if(user != null) {
                testResource1.Assignee__c = user.Id;
            }
            testResource1.WeekTickets__c = 100;
            testResource1.Specializations__c = 'default';
            testResources.add(testResource1);
            //insert testResource1;
            System.debug('Test Resource 1: '+testResource1);          
            testResource2 = new OpsResource__c();
            testResource2.Is_Available__c = true;
            testResource2.ResourceName__c = 'testResource2';
            testResource2.ShiftTimeCode__c = 9;
            //testResource2.ShiftTimeCode_Monday__c = 9;
            //testResource2.ShiftTimeCode_Tuesday__c = 9;
            //testResource2.ShiftTimeCode_Wednesday__c = 9;
            //testResource2.ShiftTimeCode_Thursday__c = 9;
            //testResource2.ShiftTimeCode_Friday__c = 9;
            testResource2.Team_Name__c ='Default Queue';
            testResource2.Assignee__c = user.Id;
            testResource2.WeekTickets__c = 1;
            testResource2.Specializations__c = 'default';
            testResources.add(testResource2);
            System.debug('Test Resource 2: '+testResource2);
            //insert testResource2;
            insert testResources;
            System.debug('Test Resources: '+testResources);
            System.runAs(user) {
                testIncident1 = new BMCServiceDesk__Incident__c(BMCServiceDesk__FKCategory__c=CategoryMap.get('Telecom').id,BMCServiceDesk__FKUrgency__c=urgencyMap.get('Severity 4').id,BMCServiceDesk__FKClient__c = system.userInfo.getUserId(),BMCServiceDesk__incidentDescription__c = 'Test Data Description values',BMCServiceDesk__FKImpact__c=impactMap.get('LOW').Id);
                //insert testIncident1;
                testIncidents.add(testIncident1);
                System.debug('Test inc 1 owner id: '+testIncident1.OwnerId);
                testIncident2 = new BMCServiceDesk__Incident__c(BMCServiceDesk__FKCategory__c=CategoryMap.get('Telecom').id,BMCServiceDesk__FKUrgency__c=urgencyMap.get('Severity 4').id,BMCServiceDesk__FKClient__c = system.userInfo.getUserId(),BMCServiceDesk__incidentDescription__c = 'Test Data Description values',BMCServiceDesk__FKImpact__c=impactMap.get('LOW').Id);
                //insert testIncident2;
                testIncidents.add(testIncident2);
                System.debug('Test inc 1 owner id: '+testIncident1.OwnerId);
                insert testIncidents;
            /*
            List<BMCServiceDesk__Incident__c> incList = [Select OwnerId from BMCServiceDesk__Incident__c where id=:testIncident2.id LIMIT 1];
            incList.get(0).OwnerId = System.UserInfo.getUserId();
            update incList;
            
            List<BMCServiceDesk__Incident__c> incList1 = [Select OwnerId from BMCServiceDesk__Incident__c where id=:testIncident1.id LIMIT 1];
            incList1.get(0).HD_Routing_Settings__c = 'Override Routing';
            update incList1;
            Group defaultQueueId = [Select Id,Name from Group where Name ='Default Queue' and Type = 'Queue' limit 1];
            incList1.get(0).OwnerId = defaultQueueId.Id;
*/
            //List<BMCServiceDesk__Incident__c> incList = new List<BMCServiceDesk__Incident__c>();
                BMCServiceDesk__Incident__c inc2 = [Select OwnerId from BMCServiceDesk__Incident__c where id=:testIncident2.id LIMIT 1];
                inc2.OwnerId = System.UserInfo.getUserId();
                incList.add(inc2);
            //update incList;
            
                BMCServiceDesk__Incident__c inc1 = [Select OwnerId from BMCServiceDesk__Incident__c where id=:testIncident1.id LIMIT 1];
                inc1.HD_Routing_Settings__c = 'Override Routing';
                incList.add(inc1);
            }
            //Group defaultQueueId = [Select Id,Name from Group where Name ='Default Queue' and Type = 'Queue' limit 1];
            //inc1.OwnerId = defaultQueueId.Id;


        }//try
        catch(Exception e){
            System.debug('Exception occurred: '+e.getMessage());
        }
    }
    
    //Test Case 1: Normal case
    static TestMethod void testAssignOpenTickets(){
        System.debug('In testAssignOpenTickets');
        Test.startTest();
        update incList;
        BMCServiceDesk__Incident__c inc1 = [Select OwnerId from BMCServiceDesk__Incident__c where id=:testIncident1.id LIMIT 1];
        System.debug('Initial owner: '+inc1.OwnerId);
         Group defaultQueueId = [Select Id,Name from Group where Name ='EAE Ops' and Type = 'Queue' limit 1];
         inc1.OwnerId = defaultQueueId.Id;
        //update inc1;
         BMCServiceDesk__Incident__c changedInc1 = [Select OwnerId from BMCServiceDesk__Incident__c where id=:testIncident1.id LIMIT 1];
        System.debug('Changed owner: '+changedInc1.OwnerId);
        //BMCServiceDesk__Incident__c inc1 = [Select OwnerId from BMCServiceDesk__Incident__c where id=:testIncident1.id LIMIT 1];
        //System.debug(inc1.OwnerId);
        Integer result=HD_OpenTicketAssignment.assignOpenTickets();
        Test.stopTest();
        System.assert(result!=3);
    }
    
    //Test Case 2: No Unassigned Tickets present
    static TestMethod void testGetOpenIncidents(){
        List<String> qNames=new List<String>();
        qNames.add('Test Queue1');
        qNames.add('Test Queue2');
        Test.startTest();
        List<BMCServiceDesk__Incident__c> unassignedIncidents=HD_OpenTicketAssignment.getOpenIncidents(qNames);
        Test.stopTest();
        System.assert(unassignedIncidents.size()==0);
    }
    
    
    //Test Case 3: Test for mails
    static TestMethod void testSendMail(){
        Test.startTest();
        HD_OpenTicketAssignment.sendMail('Test');
        Test.stopTest();
    }
    
    //Test Case 4: Test for limits when upper limit is greater than 23
    static TestMethod void testSetLimits1(){
        HD_OpenTicketAssignment.job_time=21;
        HD_OpenTicketAssignment.job_day='Tuesday';
        HD_OpenTicketAssignment.setLimits(24);
    }
    
    static TestMethod void testSetLimits2(){
        HD_OpenTicketAssignment.job_time=1;
        HD_OpenTicketAssignment.job_day='Tuesday';
        HD_OpenTicketAssignment.setLimits(23);
    }
    
    static TestMethod void testDequeueResource(){
        OpsResource__c opsRes = new OpsResource__c();
        System.assert(opsRes == HD_OpenTicketAssignment.dequeueResource('',new List<OpsResource__c>{opsRes}));
    }
    
    //Test Case 5: Test for limits when job_time is less than interval, day= Tuesday
    /*static TestMethod void testSetLimitsTue1(){
        HD_OpenTicketAssignment.job_time=3;
        HD_OpenTicketAssignment.job_day='Tuesday';
        HD_OpenTicketAssignment.setLimits(15);
        List<String> qNames=new List<String>();
        qNames.add('Default Queue');
        HD_OpenTicketAssignment.getAvaiableResources(qNames);
    }
    
    //Test Case 6: Test for limits when job_time is less than interval, day = Wednesday
    static TestMethod void testSetLimitsWed1(){
        HD_OpenTicketAssignment.job_time=3;
        HD_OpenTicketAssignment.job_day='Wednesday';
        HD_OpenTicketAssignment.setLimits();
        List<String> qNames=new List<String>();
        qNames.add('Default Queue');
        HD_OpenTicketAssignment.getAvaiableResources(qNames);
    }
    
    //Test Case 7: Test for limits when job_time is less than interval, day= Thursday
    static TestMethod void testSetLimitsThurs1(){
        HD_OpenTicketAssignment.job_time=3;
        HD_OpenTicketAssignment.job_day='Thursday';
        HD_OpenTicketAssignment.setLimits();
        List<String> qNames=new List<String>();
        qNames.add('Default Queue');
        HD_OpenTicketAssignment.getAvaiableResources(qNames);
    }
    
    //Test Case 8: Test for limits when job_time is less than interval
    static TestMethod void testSetLimitsFri1(){
        HD_OpenTicketAssignment.job_time=3;
        HD_OpenTicketAssignment.job_day='Friday';
        HD_OpenTicketAssignment.setLimits();
        List<String> qNames=new List<String>();
        qNames.add('Default Queue');
        HD_OpenTicketAssignment.getAvaiableResources(qNames);
    }
    
    //Test Case 9: Test for limits when job_time is less than interval
    static TestMethod void testSetLimitsMon1(){
        HD_OpenTicketAssignment.job_time=3;
        HD_OpenTicketAssignment.job_day='Monday';
        HD_OpenTicketAssignment.setLimits();
        List<String> qNames=new List<String>();
        qNames.add('Default Queue');
        HD_OpenTicketAssignment.getAvaiableResources(qNames);
    }
    
   static TestMethod void testSetLimitsMon2(){
        HD_OpenTicketAssignment.job_time=22;
        HD_OpenTicketAssignment.job_day='Monday';
        HD_OpenTicketAssignment.setLimits();
        List<String> qNames=new List<String>();
        qNames.add('Default Queue');
        HD_OpenTicketAssignment.getAvaiableResources(qNames);
    }
    
    static TestMethod void testSetLimitsTue2(){
        HD_OpenTicketAssignment.job_time=22;
        HD_OpenTicketAssignment.job_day='Tuesday';
        HD_OpenTicketAssignment.setLimits();
        List<String> qNames=new List<String>();
        qNames.add('Default Queue');
        HD_OpenTicketAssignment.getAvaiableResources(qNames);
    }
    
    static TestMethod void testSetLimitsWed2(){
        HD_OpenTicketAssignment.job_time=22;
        HD_OpenTicketAssignment.job_day='Wednesday';
        HD_OpenTicketAssignment.setLimits();
        List<String> qNames=new List<String>();
        qNames.add('Default Queue');
        HD_OpenTicketAssignment.getAvaiableResources(qNames);
    }
    
    static TestMethod void testSetLimitsThu2(){
        HD_OpenTicketAssignment.job_time=22;
        HD_OpenTicketAssignment.job_day='Thursday';
        HD_OpenTicketAssignment.setLimits();
        List<String> qNames=new List<String>();
        qNames.add('Default Queue');
        HD_OpenTicketAssignment.getAvaiableResources(qNames);
    }
    
    static TestMethod void testSetLimitsFri2(){
        HD_OpenTicketAssignment.job_time=22;
        HD_OpenTicketAssignment.job_day='Friday';
        HD_OpenTicketAssignment.setLimits();
        List<String> qNames=new List<String>();
        qNames.add('Default Queue');
        HD_OpenTicketAssignment.getAvaiableResources(qNames);
    }*/
    
    
    static TestMethod void testSendMailBatchable(){
        Map<String,String> testEmailMap = new Map<String,String>();
        String sendAddress = System.UserInfo.getUserEmail();
        String content = 'Test Content';
        testEmailMap.put(sendAddress,content);
        Test.startTest();
        HD_BatchableOpenTicketAssignment batchObj=new HD_BatchableOpenTicketAssignment('','',null,null,'Test incidentId','Test updatedIncident','Test usedResource',testEmailMap);
        batchObj.sendMail();
        Test.stopTest();
    }
    
    static TestMethod void testpopulateAvailabilityAndShift(){
        HD_ShiftSchedule__c  schedule = new HD_ShiftSchedule__c (); 
        schedule.Assignment_time__c = '15,15';
        schedule.Days__c = '5'; 
        schedule.Is_Available__c = true; 
        schedule.Login_time__c = '9 AM';
        schedule.Logout_Time__c = '5 PM'; 
        schedule.Week_Number__c = '5';
        insert schedule;
        OpsResource_Shift_Junction__c resourceShift = new OpsResource_Shift_Junction__c();
        resourceShift.ShiftSchedule__c = schedule.Id;
        resourceShift.OpsResource__c = testResource1.Id;
        insert resourceShift;
        HD_ShiftSchedule__c  schedule1 = new HD_ShiftSchedule__c (); 
        schedule1.Assignment_time__c = '15,15';
        schedule1.Days__c = '5'; 
        schedule1.Is_Available__c = true; 
        schedule1.Login_time__c = '9 PM';
        schedule1.Logout_Time__c = '5 AM'; 
        schedule1.Week_Number__c = '5';
        insert schedule1;
        OpsResource_Shift_Junction__c resourceShift1 = new OpsResource_Shift_Junction__c();
        resourceShift1.ShiftSchedule__c = schedule1.Id;
        resourceShift1.OpsResource__c = testResource2.Id;
        insert resourceShift1;
        HD_OpenTicketAssignment.weekDay = '5';
        HD_OpenTicketAssignment.weekNumber = '5';
        Test.startTest();
        List<OpsResource__c> availability = HD_OpenTicketAssignment.populateAvailabilityAndShift(testResources);
        Test.stopTest();
        System.assertEquals(2, availability.size());
    }
    
    static TestMethod void getQueueIdException(){
        Test.startTest();
        HD_OpenTicketAssignment.getQueueIds(null);
        Test.stopTest();
    }
    
    static TestMethod void getQueueIdMapException(){
        Test.startTest();
        HD_OpenTicketAssignment.getQueueIdMap(null);
        Test.stopTest();
    }
    
    static TestMethod void assignTicketsToResourcesException(){
        Test.startTest();
        HD_OpenTicketAssignment.assignTicketsToResources(null, null, null, null);
        Test.stopTest();
    }
    
    static TestMethod void updateTicketsAssignedException(){
        Test.startTest();
        HD_OpenTicketAssignment.updateTicketsAssigned(null);
        Test.stopTest();
    }
    
        static TestMethod void testScheduledJob(){
        test.startTest();
        HD_Schedulable_OpenTicketAssignment scheduler = new HD_Schedulable_OpenTicketAssignment();
        String Csec,Cmin,Chr1,Cday,Cmonth,CYear;

        Datetime  dt1 = System.now();
        Datetime  dt =  dt1.addDays(2);
        Cmin=String.valueof(dt.minute());
        Chr1=String.valueof(dt.hour());
        Cday=String.valueof(dt.day());
        Cmonth=String.valueof(dt.month());
        CYear=String.valueof(dt.Year());
        Csec=String.valueof(dt.addSeconds(8).second());
        String SchTimer=Csec+' '+Cmin+' '+Chr1+' '+Cday+' '+Cmonth+' ? '+CYear;
        

        //need to be fixed as test class are faulin
        String jobId = system.schedule('Automated Allocation Test Class', SchTimer, scheduler);
    
           
      // Get the information from the CronTrigger API object
      CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];

      // Verify the expressions are the same
      System.assertEquals(SchTimer, ct.CronExpression);

      // Verify the job has not run
     // System.assertEquals(0, ct.TimesTriggered);
        test.stopTest();
    }
 }