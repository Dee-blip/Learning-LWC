/*
Template: Apex Test Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : used as a apart of requirment for Problem Managment, Unit Test

Purpose : an Unit Test for trigger HD_NotesAttachment_notes_tri.trigger
          
Usage : used as an test for the business logic , for trigger HD_NotesAttachment_notes_tri.trigger
          
Test Class Asssociated : NONE

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Trigger Associated : HD_NotesAttachment_notes_tri.trigger
Class Associated : HD_NotesAttachment_notes_tri_class.cls
              
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
private class HD_Test_NotesAttachment_notes_tri {

  static BMCServiceDesk__Incident__c testIncident;

  static{
    ManagedPkgErrorClass.isFromManagedPackage = false;
    /*
    List<HD_RF_TRIGGER_FLAG__c> roleSettings = [select name, Role_Id__c, Run_New_Trigger__c from HD_RF_TRIGGER_FLAG__c];
    if(roleSettings.size()>0){ delete roleSettings; }
    HD_RF_TRIGGER_FLAG__c adminRole = new HD_RF_TRIGGER_FLAG__c();
    adminRole.name = 'Role: System Administartor';
    adminRole.Role_Id__c = System.UserInfo.getUserRoleId();
    adminRole.Run_New_Trigger__c = true;
    insert adminRole;
    */

    HD_IncidentTestDataFactory rfFactory = new HD_IncidentTestDataFactory();
    testIncident = rfFactory.getNewIncident(HD_IncidentTestDataFactory.Team.CORPIT);
  }

//Creating RunAs Method for user substitution 
private static User runAsUser(String profileName, boolean IsStaffUser ){

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
  private static List<BMCServiceDesk__Problem__c> problemTestdata(integer countProblem)
  {

    List<BMCServiceDesk__Problem__c> problemList = new List<BMCServiceDesk__Problem__c>();
    String serId = HD_Test_NotesAttachment_notes_tri.serviceId('Corporate IT');//UNIX
    for ( integer i = 1 ; i <= countProblem ; i++  )
    {
        BMCServiceDesk__Problem__c problem = new BMCServiceDesk__Problem__c();
        problem.Title_Summary__c = 'Problem Managment Title '+i;
        problem.Category_alias__c = serId;
        problem.BMCServiceDesk__Problem_Source__c = 'Event Trigger';   
        problem.BMCServiceDesk__shortDescription__c = 'Test Data Description values '+i;
        problem.Urgency_picklist__c = 'Severity 4';
        problem.CC__c = 'hbarapat@akamai.com hbarapat@akamai.com hbarapat@akamai.com hbarapat@akamai.com hbarapat@akamai.com hbarapat@akamai.com';
        //Adding it to the collection
        problemList.add( problem );
    }

    return problemList;
  
  }//
  
  
    //creating Subject Matter Expert
private static List< Subject_Matter_Expert__c >  smeTestData( List<BMCServiceDesk__Problem__c> ProblemList , Integer smeCount)
{
    List<Subject_Matter_Expert__c> smeList = new List<Subject_Matter_Expert__c>();
    List<User> usr = new List<User>();
    Profile p = [ SELECT Id FROM Profile WHERE Name='ServiceDesk Staff' limit 1 ];
    usr =  [ SELECT Id,FirstName,LastName,Email,BMCServiceDesk__IsStaffUser__c from User WHERE ProfileId =: p.Id AND IsActive=true AND BMCServiceDesk__IsStaffUser__c =true limit 30 ];
    for(BMCServiceDesk__Problem__c pr : ProblemList)
    {
      for(integer i = 1; i<= smeCount ; i++)
      {
        Subject_Matter_Expert__c sme = new Subject_Matter_Expert__c();
        sme.User__c = usr[i].Id;
        sme.Problem__c = pr.Id;
        
        //Adding it to List
        smeList.add(sme);
      }//
    }//
    
    return smeList;
}// 
  
 // Creating a Note for Problem 
 private static List<Note> noteTestData(List<BMCServiceDesk__Problem__c> prob,integer NoteCount)
 {
    List<Note> noteList =new  List<Note>();
    for(integer i=1;i<=NoteCount;i++)
    {
      Note nt = new Note();
      nt.Title = 'New Note '+i;
      nt.IsPrivate = false;
      for(BMCServiceDesk__Problem__c pr : prob)
      {
        nt.ParentId  = pr.Id;
      }//for
      nt.Body = 'Body Content '+i;
      noteList.add(nt);
    }//for(integer i=1;i<=NoteCount;i++)
    return noteList;
 }//
 
 //creating the Test Class for insertion
 @isTest
 private static void testSingleInsert()
 {

    System.runAs(runAsUser('ServiceDesk Staff',true))
    {

      test.startTest();
      //inserting Problem First
      List<BMCServiceDesk__Problem__c> prob = problemTestdata(1);
      insert prob;
            
      //Inserting Smes
      List<Subject_Matter_Expert__c> smeIns = smeTestData(prob,1);
      insert smeIns;
      System.debug('SME Inserted :------->'+smeIns);
            
      //Inserting Smes
      List<Note> ntIns = noteTestData(prob,1);
      insert ntIns;
      System.debug('Inserted Notes :------->'+ntIns);
      //testing some values
      System.assertEquals(prob[0].Title_Summary__c, 'Problem Managment Title 1');
      test.stopTest();
    }
  }//

  @isTest
  static void testDLEISNotes(){

    testIncident.HD_Notify_DL_EIS_on_Notes_Update__c = true;
    insert testIncident;
    Note nt = new Note();
    nt.Title = 'New Note ';
    nt.IsPrivate = false;
    nt.ParentId  = testIncident.Id;
    nt.Body = 'Notes Body Content ';
    insert nt;
  }

}//End of test Class