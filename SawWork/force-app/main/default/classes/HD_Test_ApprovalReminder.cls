/*
* File Name: HD_Test_ApprovalReminder
* Description : Test class for HD_Incident_Pending_Approval_Reminder
* @author :
* Modification Log ===============================================================
* Date					Author				Modification
* Aug 08th, 2020     Aneesh Budnar     PRTORES-1810 - Code scanner fixes
* Oct 13th, 2021     Aneesh Budnar     PRTORES-977 - Fix Test class failures
*/
@isTest(seeAllData = false)
public class HD_Test_ApprovalReminder {

  static testMethod void testApprovalReminder() {        
      HD_Test_Data_Factory.init();
      BMCServiceDesk__Incident__c incident;
      System.runAs(new UserTestHelper.UserBuilder().buildAndSave()) {
          Id userId = System.UserInfo.getUserId();
          
          incident = new BMCServiceDesk__Incident__c();
          
          incident.Approver__c = userId;
          incident.BMCServiceDesk__FKClient__c = userId;
          incident.HD_Ticket_Priority__c = '4';
          incident.RecordTypeId  = Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Helpdesk').getRecordTypeId();
          incident.BMCServiceDesk__incidentDescription__c = ' Test Descri';
          incident.BMCServiceDesk__FKImpact__c = HD_Test_Data_Factory.impactMap.get('LOW');
          incident.BMCServiceDesk__FKStatus__c  = HD_Test_Data_Factory.statusMap.get('ASSIGNED');
          incident.BMCServiceDesk__FKUrgency__c = HD_Test_Data_Factory.urgencyMap.get('Severity 4');
          incident.BMCServiceDesk__FKCategory__c = Id.valueOf(HD_Test_Data_Factory.categoryMap.get('Access'));
          insert incident;
          
          Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
          req.setComments('Approve.');
          req.setNextApproverIds(new Id[] {UserInfo.getUserId()});
          req.setObjectId(incident.id);
          
          //Submit the approval request
          Approval.ProcessResult result = Approval.process(req);
      }
      HD_Incident_Pending_Approval_Reminder.runPendingApprovalWrapper();
      
      BMCServiceDesk__Incident__c inc = [SELECT HD_IncidentGroup__c,ID,Name,BMCServiceDesk__Category_ID__c from BMCServiceDesk__Incident__c where ID = :incident.id ];
      
      String cndn = '[{"Incident_Condition__c":"HD_IncidentGroup__c#~#'+inc.HD_IncidentGroup__c+'&OR&BMCServiceDesk__Category_ID__c#=#'+inc.BMCServiceDesk__Category_ID__c+'","ElapsedTime__c":"0","Recurring_Pattern__c":"1"}' ;
        cndn += ',{"Incident_Condition__c":"HD_IncidentGroup__c#!~#ZZZ&AND&BMCServiceDesk__Category_ID__c#!=#XYZ","ElapsedTime__c":"0","Recurring_Pattern__c":"1", "Exclude_Weekend__c":"true"}]' ;
      
      List<Approval_Reminder_Setting__mdt> remndSets  = (List<Approval_Reminder_Setting__mdt>) JSON.deserialize( cndn, List<Approval_Reminder_Setting__mdt>.class );
      
      Test.startTest(); 
      HD_Incident_Pending_Approval_Reminder.pendingApprovals(remndSets);
      HD_Incident_Pending_Approval_Reminder.sendEmail('Error Message');
      Map<Id,Set<sObject>> usrInc = HD_Incident_Pending_Approval_Reminder.userIncidents;
      Integer  sz = usrInc.size() ;
      System.assertNotEquals(sz, 0);

      Test.stopTest();

      
  }
  
  
  static testMethod void testReminderSchedule() {
    Test.startTest();       
       HD_ApprovalReminder_Scheduler reminderScheduler = new HD_ApprovalReminder_Scheduler();
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
       String jobId = system.schedule('Approval Reminder Schedular', SchTimer, reminderScheduler);
        
    Test.stopTest();
    // Get the information from the CronTrigger API object
       CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
                         NextFireTime
       FROM CronTrigger WHERE id = :jobId];

    // Verify the expressions are the same
    System.assertEquals(SchTimer, ct.CronExpression);
  }

   /*
   static testMethod void testEmailMapper() {


   Test.startTest(); 
    Group g = new Group(Type='Queue', Name='Queue name', Email='test@test.com');
    insert g;

    Group g2 = new Group(Type='Queue', Name='Queue name2');
    insert g2;



    List<user>  testusers = [select id,Email from User where Isactive = true and Profile.Name like '%System Administrator%' limit 5];

    GroupMember member = new GroupMember();
    member.UserOrGroupId = testusers[0].id;
    member.GroupId = g.Id;

    insert member;

    GroupMember member2 = new GroupMember();
    member2.UserOrGroupId = testusers[1].id;
    member2.GroupId = g2.Id;

    insert member2;

    GroupMember member3 = new GroupMember();
    member3.UserOrGroupId = testusers[2].id;
    member3.GroupId = g2.Id;
    insert member3;


    BMCServiceDesk__Incident__c incident = new BMCServiceDesk__Incident__c();
          Id userId = System.UserInfo.getUserId();
       BMCServiceDesk__SRM_RequestDefinition__c rd =  [SELECT ID,BMCServiceDesk__FKCategory__c from BMCServiceDesk__SRM_RequestDefinition__c WHERE Name = 'Database - Apply Patches' Limit 1];
      
      incident.BMCServiceDesk__FKClient__c =  userId;
      incident.HD_Ticket_Priority__c = '4';
      incident.BMCServiceDesk__incidentDescription__c = ' Test Descri';
      incident.BMCServiceDesk__FKImpact__c = [SELECT ID from BMCServiceDesk__Impact__c  WHERE Name = 'Low' limit 1].id;
      incident.BMCServiceDesk__FKUrgency__c = [SELECT ID from BMCServiceDesk__Urgency__c WHERE Name = 'Severity 4' Limit 1].id;
       
      incident.BMCServiceDesk__FKCategory__c = rd.BMCServiceDesk__FKCategory__c;      
     // insert incident;
      //sObject inci = [SELECT id,NAME,HD_Ticket_Priority__c from  BMCServiceDesk__Incident__c where id = :incident.id limit 1];
      Set<sObject> incilist =  new Set<sObject>();
      incilist.add(incident);

      HD_Incident_Pending_Approval_Reminder.userIncidents.put(g.Id,incilist);
      HD_Incident_Pending_Approval_Reminder.userIncidents.put(g2.Id,incilist);
      HD_Incident_Pending_Approval_Reminder.userIncidents.put(testusers[4].Id,incilist);

      HD_Incident_Pending_Approval_Reminder.populateEmailAddressMap();

      MAP<Id,List<String>> emailMap = HD_Incident_Pending_Approval_Reminder.ApproverEmailList;

      List<String> emails1 = emailMap.get(g.id);
      Test.stopTest();
      System.assertEquals(emails1[0],'test@test.com');


   }
   */
 
}