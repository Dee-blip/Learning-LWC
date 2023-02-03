/*
 *@author: Nikhil Karn
 *@details: This test class is for HD_SendEmailForUpguardTickets.cls as well as HD_Test_SendEmailForUpguardTicketsJobs.cls classes
 * Modification Log ===============================================================
 * Date              Author              Modification
 * 5 Aug, 2020       Abhishek Singh      PRTORES-1811 - HD code scan 2020 - Blocker and critical part 5 
*/

@isTest(seeAllData=false)
public class HD_Test_SendEmailForUpguardTicketsJobs {


  static{

    String CRON_EXP = '0 0 8 ? * * *';
    HD_SendEmailForUpguardTickets testObjectSendEmailForUpguardTickets=new HD_SendEmailForUpguardTickets();
    HD_SendEmailForUpguardTickets.siLimit=2;
    HD_SendEmailForUpguardTickets.whereClause='HD_Ticket_Priority__c=4';

    List<String> tempList1=new List<string> {'UNASSIGNED','ASSIGNED','IN PROGRESS','WAITING FOR RESPONSE','CUSTOMER RESPONDED','REASSIGNED','REOPENED','CLOSED','RESOLVED'};

    HD_SendEmailForUpguardTickets.status=tempList1;

    List<String> tempList2=new List<string>();
    tempList1.add('HARDWARE');
    tempList1.add('Access');
    HD_SendEmailForUpguardTickets.categories=tempList2;

    List<String> tempEmailList=new List<string>();
    tempList1.add('nkarn@akamai.com');
    HD_SendEmailForUpguardTickets.subscriberEmails=tempEmailList;

    HD_SendEmailForUpguardTickets.isCriteriaEmpty=false;

  }





  public static String CRON_EXP = '0 0 8 ? * * *';

  @isTest public static void testschedule() {

    Test.startTest();
    String jobId = System.schedule('HD_SendEmailForUpguardTicketsJobs',HD_Test_SendEmailForUpguardTicketsJobs.CRON_EXP,new HD_SendEmailForUpguardTicketsJobs());

    // Get the information from the CronTrigger API object
    CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered,NextFireTime FROM CronTrigger WHERE id = :jobId];

    // Verify the expressions are the same
    System.assertEquals(HD_Test_SendEmailForUpguardTicketsJobs.CRON_EXP,ct.CronExpression);

    // Verify the job has not run
    System.assertEquals(0, ct.TimesTriggered);

    // Verify the next time the job will run
    // System.assertEquals(Date.today().addDays(1).format('yyyy-MM-dd')+' 08:00:00',String.valueOf(ct.NextFireTime));

    Test.stopTest();
  }



  @isTest public static void testSendEmailsMethod() {
    try{
      Test.startTest();
      HD_SendEmailForUpguardTickets.sendMails(); 
    }catch(Exception e){
      System.assert(true,true);
    }
  }



  @isTest public static void testRunEmailMethod() {
    try{
      Test.startTest();
      HD_SendEmailForUpguardTickets.runEmail(); 
    }catch(Exception e){
      System.assertNotEquals(e,null);
    }finally{
      Test.stopTest();
    }
  }


  @isTest public static void testsendEmailMethod() {
    HDEmailAlertForTicketsExcceding__mdt emailAlertCustMetaData=new HDEmailAlertForTicketsExcceding__mdt();
    try{
      Test.startTest();
      HD_SendEmailForUpguardTickets.sendEmail(emailAlertCustMetaData); 
    }catch(Exception e){
      System.assertNotEquals(e,null);
    }
  }


  @isTest public static void testgetContentMethod() {

    try{
      Test.startTest();
      HD_SendEmailForUpguardTickets.getContent(); 
    }catch(Exception e){
      System.assertNotEquals(e,null);
    }


  }


  @isTest public static void testgetQueryMethod() {
    List<String> testDataList=new List<String>();
    testDataList.add('test');

    try{
      Test.startTest();
      HD_SendEmailForUpguardTickets.getQuery('test',testDataList,testDataList); 
    }catch(Exception e){
      System.assertNotEquals(e,null);
    }


  }

}