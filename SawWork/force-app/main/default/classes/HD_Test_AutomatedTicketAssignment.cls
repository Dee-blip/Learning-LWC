/*
* File Name: HD_Test_AutomatedTicketAssignment
* Description : Test class for HD_AutomatedTicketAssignment
* @author :
* Modification Log ===============================================================
* Date 				 Author 			  Modification
* Aug 08th, 2020     Aneesh Budnar        PRTORES-1810 - Code scanner fixes
*/
@isTest(SeeAllData = false)
public class HD_Test_AutomatedTicketAssignment {
    static List<Threshold__c> testThresholds = new List<Threshold__c>();
    static List<OpsResource__c> testResources = new List<OpsResource__c>();
    Static List<HD_ShiftSchedule__c> testShifts = new List<HD_ShiftSchedule__c>();
    Static List<OpsResource_Shift_Junction__c> testShiftMap = new List<OpsResource_Shift_Junction__c>();
    Static BMCServiceDesk__Incident__c testIncident = new BMCServiceDesk__Incident__c();



    static{
        try{

            //create custom setting
			User contextUser = [SELECT Id FROM User WHERE USername like '%abudnar@akamai.com%' LIMIT 1];
            List<HD_Round_Robin_setting__c> testSettings = new List<HD_Round_Robin_setting__c>{
                new HD_Round_Robin_setting__c(Name = 'resetTime',HD_Value__c = '06'),
                new HD_Round_Robin_setting__c(Name = 'resetDay', HD_Value__c = 'Monday')
            };
            //create test threshold
            Threshold__c testThreshold1 = new Threshold__c();
            Threshold__c testThreshold2 = new Threshold__c();
            
            testThreshold1.Name = 'EAE Ops';
            testThreshold1.Interval__c = 0;
            testThreshold1.Cutoff__c = 0;
            testThreshold1.Job_frequency__c = 0;
            testThreshold1.Job_Run_Time__c = '00,01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23';
            testThreshold1.Max_tickets_per_job__c = 20;
            testThreshold1.Max_tickets_per_resource__c = 1;
            testThreshold1.Queue_to_use__c = 'EAE Ops';
            testThreshold1.Max_tickets_per_week__c = 200;
            testThreshold1.Is_Active__c = true;
            testThreshold1.Team_Email__c = System.UserInfo.getUserEmail();
            
            testThresholds.add(testThreshold1);

			testThreshold2.Name = 'DBA';
            testThreshold2.Interval__c = 0;
            testThreshold2.Cutoff__c = 0;
            testThreshold2.Job_frequency__c = 0;
            testThreshold2.Job_Run_Time__c = '00,01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23';
            testThreshold2.Max_tickets_per_job__c = 20;
            testThreshold2.Max_tickets_per_resource__c = 1;
            testThreshold2.Queue_to_use__c = 'DBA';
            testThreshold2.Max_tickets_per_week__c = 200;
            testThreshold2.Is_Active__c = True;
            testThreshold2.Team_Email__c = System.UserInfo.getUserEmail(); 
            
           	testThresholds.add(testThreshold2);
            
            insert testThresholds;
            
            //initializing the test resources
            OpsResource__c testResource1 = new OpsResource__c();
            OpsResource__c testResource2 = new OpsResource__c();
            OpsResource__c testResource3 = new OpsResource__c();
            OpsResource__c testResource4 = new OpsResource__c();
            
            testResource1.Is_Available__c = true;
            testResource1.ResourceName__c = 'testResource1';
            testResource1.ShiftTimeCode__c = 9;
            testResource1.ShiftTimeCode_Monday__c = 9;
            testResource1.ShiftTimeCode_Tuesday__c = 9;
            testResource1.ShiftTimeCode_Wednesday__c = 9;
            testResource1.ShiftTimeCode_Thursday__c = 9;
            testResource1.ShiftTimeCode_Friday__c = 9;
            testResource1.Team_Name__c ='EAE Ops';
            testResource1.Assignee__c = System.UserInfo.getUserId();
            testResource1.WeekTickets__c = 100;
            testResource1.Specializations__c = 'default';
            testResource1.Out_of_office_Date__c = '00';
            
            testResources.add(testResource1);
            
            testResource2.Is_Available__c = true;
            testResource2.ResourceName__c = 'testResource2';
            testResource2.ShiftTimeCode__c = 9;
            testResource2.ShiftTimeCode_Monday__c = 9;
            testResource2.ShiftTimeCode_Tuesday__c = 9;
            testResource2.ShiftTimeCode_Wednesday__c = 9;
            testResource2.ShiftTimeCode_Thursday__c = 9;
            testResource2.ShiftTimeCode_Friday__c = 9;
            testResource2.Team_Name__c ='EAE Ops';
            testResource2.Assignee__c = System.UserInfo.getUserId();
            testResource2.WeekTickets__c = 100;
            testResource2.Specializations__c = 'default';
            testResource2.Out_of_office_Date__c = '00';
            
            testResources.add(testResource2);
            
            testResource3.Is_Available__c = true;
            testResource3.ResourceName__c = 'testResource3';
            testResource3.ShiftTimeCode__c = 9;
            testResource3.ShiftTimeCode_Monday__c = 9;
            testResource3.ShiftTimeCode_Tuesday__c = 9;
            testResource3.ShiftTimeCode_Wednesday__c = 9;
            testResource3.ShiftTimeCode_Thursday__c = 9;
            testResource3.ShiftTimeCode_Friday__c = 9;
            testResource3.Team_Name__c ='EAE Ops';
            testResource3.Assignee__c = System.UserInfo.getUserId();
            testResource3.WeekTickets__c = 100;
            testResource3.Specializations__c = 'default';
            testResource3.Out_of_office_Date__c = '00';
            
            testResources.add(testResource3);
            
            testResource4.Is_Available__c = false;
            testResource4.ResourceName__c = 'testResource4';
            testResource4.ShiftTimeCode__c = 9;
            testResource4.ShiftTimeCode_Monday__c = 9;
            testResource4.ShiftTimeCode_Tuesday__c = 9;
            testResource4.ShiftTimeCode_Wednesday__c = 9;
            testResource4.ShiftTimeCode_Thursday__c = 9;
            testResource4.ShiftTimeCode_Friday__c = 9;
            testResource4.Team_Name__c ='DBA';
            testResource4.Assignee__c = contextUser.Id;
            testResource4.WeekTickets__c = 100;
            testResource4.Specializations__c = 'default';
            testResource4.Out_of_office_Date__c = '00';
            testResource4.Assign_Always__c = true;
            
            testResources.add(testResource4);
            
            insert testResources;

            //initializing the shifts
            HD_ShiftSchedule__c testShift1 = new HD_ShiftSchedule__c();
            HD_ShiftSchedule__c testShift2 = new HD_ShiftSchedule__c();
            
            testShift1.Name = 'test Shift 1';
            testShift1.Week_Number__c = '1,2,3,4,5';
            testShift1.Days__c = 'Monday,Tuesday,Wednesday,Thursday,Friday,Saturday,Sunday';
            testShift1.Assignment_time__c = '00,01,02,03,04,05,06,07,08,09,10,11,12,13,14,15,16,17,18,19,20,21,22,23';
            testShift1.Is_Available__c = true;
            
            testShifts.add(testShift1);
            
            testShift2.Name = 'test Shift 2';
            testShift2.Week_Number__c = '5';
            testShift2.Days__c = 'Friday';
            testShift2.Assignment_time__c = '00';
            testShift2.Is_Available__c = true;
           
            testShifts.add(testShift2);
            
            insert testshifts;
            
            OpsResource_Shift_Junction__c shiftMap1 = new OpsResource_Shift_Junction__c();
            OpsResource_Shift_Junction__c shiftMap2 = new OpsResource_Shift_Junction__c();
 
            ShiftMap1.OpsResource__c = testResources[0].id;
            ShiftMap1.ShiftSchedule__c = testShifts[0].id;
            
            testShiftMap.add(shiftMap1);
            
            ShiftMap2.OpsResource__c = testResources[2].id;
            ShiftMap2.ShiftSchedule__c = testShifts[1].id;
            
            testShiftMap.add(shiftMap2);
            
            insert testShiftMap;
            HD_IncidentTestDataFactory testinc1 = new HD_IncidentTestDataFactory();
            BMCServiceDesk__Incident__c inc1 = testinc1.getIncidentTestData(null);
            HD_IncidentTestDataFactory testinc2 = new HD_IncidentTestDataFactory();
            BMCServiceDesk__Incident__c inc2 = testinc2.getIncidentTestData(null);
            
            
        }
        catch(Exception e){
            system.debug(e.getMessage());
        }
    }
    
    static TestMethod void testAssignment(){
        Test.startTest();
        string status;
        status = HD_AutomatedTicketAssignment.assignOpenTickets();
        system.assertEquals('success', status);
        Test.stopTest();
    }
    
    static TestMethod void testNoQueue(){
        Test.startTest();
        testThresholds[0].Is_Active__c = false;
        testThresholds[1].Is_Active__c = false;
        update testThresholds;
        string status;
        status = HD_AutomatedTicketAssignment.assignOpenTickets();
        system.assertEquals('failure', status);
        //testThresholds[0].Is_Active__c = True;
        //update testThresholds[0];
        Test.stopTest();
        
    }
    
    static TestMethod void testNoResource(){
        Test.startTest();
        testResources[0].Is_Available__c = false;
        update testResources[0];
        string status;
        status = HD_AutomatedTicketAssignment.assignOpenTickets();
        system.assertEquals('failure', status);
       	//testResources[0].Is_Available__c = True;
        //update testResources[0];
        Test.stopTest();
        
    }
    
    static TestMethod void testNoOpenIncidents(){
        Test.startTest();
        testThresholds[0].Is_Active__c = false;
        update testThresholds[0];
        string status;
        status = HD_AutomatedTicketAssignment.assignOpenTickets();
        system.assertEquals('failure', status);
        //testThresholds[0].Is_Active__c = True;
        //update testThresholds[0];
        Test.stopTest();
    }
    
    static TestMethod void testNoIncidentForQueue(){
        Test.startTest();
        testResources[3].Is_Available__c = True;
        update testResources[3];
        string status;
        status = HD_AutomatedTicketAssignment.assignOpenTickets();
        system.assertEquals('success', status);
        Test.stopTest();  
    }
    
    static TestMethod void testOutOfOfficeResource(){
        Test.startTest();
        testResources[2].Out_of_office_Date__c = string.valueOf(date.today().day()).length() == 1? '0'+ string.valueOf(date.today().day()):string.valueOf(date.today().day());
        system.debug(testResources[0].Out_of_office_Date__c);
        update testResources[2];
        string status;
        status = HD_AutomatedTicketAssignment.assignOpenTickets();
        system.assertEquals('success', status);
        Test.stopTest();  
    }
    
    static TestMethod void testResourceSpecialization(){
        Test.startTest();
        testResources[0].Specializations__c = 'Access';
        update testResources[0];
        string status;
        status = HD_AutomatedTicketAssignment.assignOpenTickets();
        system.assertEquals('success', status);
        Test.stopTest();  
    }
    static TestMethod void testScheduler(){
        Test.startTest();
        string sch = '0 30 * ? * MON-FRI';
        string jobID = System.schedule('Automated Allocation QA', sch, new HD_Schedulable_AutomatedTicketAssignment());
        CronTrigger testCT = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];

        system.assertEquals(sch,testCT.CronExpression);
        Test.stopTest();
    }
}