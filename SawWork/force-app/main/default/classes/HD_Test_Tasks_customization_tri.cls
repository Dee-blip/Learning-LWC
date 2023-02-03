/*
Template: Apex Test Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : used as a apart of requirment for Problem Managment, Unit Test

Purpose : an Unit Test for trigger HD_Tasks_customization_tri.trigger
          
Usage : used as an test for the business logic , for trigger HD_Tasks_customization_tri.trigger
          
Test Class Asssociated : NONE

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Trigger Associated : HD_Tasks_customization_tri.trigger
Class Associated : HD_Tasks_customization_tri_class.cls
              
*/
/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest(SeeAllData=false)
private class HD_Test_Tasks_customization_tri {


    //public static Map<String, String> statusMap;
    //public static BMCServiceDesk__Incident__c testIncident;
    //public static String serviceID;
    static HD_ProblemTestDataFactory problemFactory;
    static List<BMCServiceDesk__Problem__c> problemList;
    //static List<BMCServiceDesk__Problem__c> problemListWithIncident;

    
    static {
        //List<BMCServiceDesk__Incident__c> incList =  new List<BMCServiceDesk__Incident__c>();
        //HD_IncidentTestDataFactory rfFactory = new HD_IncidentTestDataFactory();
        //testIncident = rfFactory.getIncidentTestData(HD_IncidentTestDataFactory.Team.GENERIC);

        //insert test incident in list
        //incList.add(testIncident);
        //serviceID = HD_Test_Data_Factory.categoryMap.get('Access');
        //statusMap = HD_Test_Data_Factory.statusMap;
        problemFactory = new HD_ProblemTestDataFactory();
        problemList = problemFactory.getProblemTestdata(1);
        //problemListWithIncident = problemFactory.getProblemWithIncidentTest(incList, 1);
    }

//Creating RunAs Method for user substitution 
private static User runAsUser(String profileName, boolean IsStaffUser ) 
  {
    User u = null;
    if( profileName == '' || profileName == null )
    {
      profileName = 'System Administrator';
    }
    System.debug('Current Profile Name: '+profileName);
    // Setup test data
    // This code runs as the system user
    Profile p = [ SELECT Id FROM Profile WHERE Name=: profileName limit 1 ];
    if( p == null )
    {
      p = [ SELECT Id FROM Profile WHERE Name='System Administrator' limit 1 ];
    }
    try
    {
      /* u = new User(Alias = 'test12', Email='test1234@akamai.com', 
      EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
      LocaleSidKey='en_US', ProfileId = p.Id, 
      TimeZoneSidKey='America/Los_Angeles', UserName='test1234@akamai.com');
      */
      u = [ SELECT Id,FirstName,LastName,Email,BMCServiceDesk__IsStaffUser__c from User WHERE ProfileId =: p.Id AND IsActive=true AND BMCServiceDesk__IsStaffUser__c =: IsStaffUser limit 1]; 
      System.debug('USER Details ---> '+ u);
    }//try
    catch( Exception e )
    {
    System.debug('[]Exception: '+e.getMessage()); 
    u = [ SELECT Id,FirstName,LastName,Email,BMCServiceDesk__IsStaffUser__c from User WHERE ProfileId =: p.Id AND IsActive=true AND BMCServiceDesk__IsStaffUser__c =: IsStaffUser limit 1];
      
    }//catch()
     return u;
    
  } //public static User runAsUser()
  
  //commented for seeAllData=false
  /*
  
    //Use this method to get the Category ID since service is nothing but the category 
  private static String serviceId(String ServiceName)
  {
    String Id = null;
    List<BMCServiceDesk__Category__c> cat = new List<BMCServiceDesk__Category__c>();
    cat = [Select Id From BMCServiceDesk__Category__c  WHERE Name =:ServiceName AND BMCServiceDesk__inactive__c = false LIMIT 1 ];
    System.assertEquals(1, cat.size());
    if( cat.size() > 0 )
    {
      Id = cat[0].Id;
    }
    
    return Id;
  }//
  
     //Creating Test Problem
     private static List<BMCServiceDesk__Problem__c> ProblemTestdata(integer countProblem)
  {
     List<BMCServiceDesk__Problem__c> problemList = new List<BMCServiceDesk__Problem__c>();
     String serId = HD_Test_Tasks_customization_tri.serviceId('P2R Team');//UNIX
    for ( integer i = 1 ; i <= countProblem ; i++  )
    {
      BMCServiceDesk__Problem__c problem = new BMCServiceDesk__Problem__c();
      problem.Title_Summary__c = 'Problem Managment Title '+i;
      problem.Category_alias__c = serId;
      problem.BMCServiceDesk__Problem_Source__c = 'Event Trigger';   
      problem.BMCServiceDesk__shortDescription__c = 'Test Data Description values '+i;
      problem.Urgency_picklist__c = 'Severity 4';
      
      //Adding it to the collection
      problemList.add( problem );
    }
    
    
    return problemList;
  }// 
  */
  //Creating a Task 
  private static List<BMCServiceDesk__Task__c> TaskTestData(List<BMCServiceDesk__Problem__c> prob,Integer TaskCount)
  {
    List<BMCServiceDesk__Task__c> taskList = new List<BMCServiceDesk__Task__c>();
    for(Integer i=1;i<=TaskCount;i++)
    {
      BMCServiceDesk__Task__c task = new BMCServiceDesk__Task__c();
      for(BMCServiceDesk__Problem__c pr : prob)
      {
      task.BMCServiceDesk__FKProblem__c = pr.Id;
      }
      
      //Adding it to List
      taskList.add(task);
    }//
    
    return taskList;
  }//
  
private static testmethod  void singleInsert()
{
  
    System.runAs(runAsUser('ServiceDesk Staff',true))
        {
          test.startTest();
          //inserting Problem First
          //List<BMCServiceDesk__Problem__c> prob = ProblemTestdata(1);
          //insert prob;

          //Inserting Smes
          List<BMCServiceDesk__Task__c> taskIns = TaskTestData(problemList,1);
          insert taskIns;
          
          //testing some values
          System.assertEquals(problemList[0].Title_Summary__c, 'Problem Managment Title 1');
                    
          
          test.stopTest();
          }
  
  
}//
    
    static TestMethod void testDataCopyProblemToTask(){
        Test.startTest();
        //List<BMCServiceDesk__Problem__c> prob = ProblemTestdata(1);
        //insert prob;
    List<BMCServiceDesk__Task__c> taskIns = TaskTestData(problemList,1);
        insert taskIns;
        HD_Tasks_customization_tri_class taskObj = HD_Tasks_customization_tri_class.getInstance(taskIns);
        taskObj.dataCopyproblemtoTask();
        Test.stopTest();
    }

}//End Of Test Class