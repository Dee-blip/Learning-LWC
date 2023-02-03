/*
Template: Apex Test Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : used as a apart of requirment for Incident 30 min Batch apex Process , Unit Test

Purpose : an Unit Test for batch job class HD_TicketStatusAlert_batchapex.cls
          
Usage : used as an test for the business logic , for batch job class HD_TicketStatusAlert_batchapex.cls
          
Test Class Asssociated : NONE

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Trigger Associated : 
Class Associated : HD_TicketStatusAlert_batchapex.cls,HD_TicketStatusAlert.cls
              
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
 * File Name: HD_Test_TicketStatusAlert
 * Description : Test class for Ticket status alert
 * @author : 
 * Modification Log ===============================================================
 * Date             Author              Modification
 * 5 Aug 2020       Abhishek Singh      PRTORES-1811 - HD code scan 2020 - Blocker and critical part 5
*/

 @isTest(SeeAllData=false)
 public with sharing class HD_Test_TicketStatusAlert {

 static BMCServiceDesk__Incident__c testIncident;

 static{

    HD_IncidentTestDataFactory rfFactory = new HD_IncidentTestDataFactory();
    testIncident = rfFactory.getIncidentTestData(HD_IncidentTestDataFactory.Team.CORPIT);
 }

//Helper method to create the custom settings
private static void insertCustomSettings()
{
   HD_BATCH_JOB__c hdbj  = new  HD_BATCH_JOB__c();
   //if( hdbj.HD_TicketStatusAlert_batchapex__c  != null || hdbj.HD_TicketStatusAlert_batchapex__c  != null )
   //{
   hdbj.HD_TicketStatusAlert_batchapex__c = '{"batch_params":[{"distributionlistemail":"hbarapat@akamai.com,kahegde@akamai.com","recordlink":"/apex/BMCServiceDesk__RemedyforceConsole?objectName=Incident__c&record_id=","queryorclause":""}]}';
   insert hdbj;
   //}

   //populating custom setting used for new old trigger
    Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
   System.debug('decribe ---'+gd.containsKey('HD_RF_TRIGGER_FLAG__c'));
   if(gd.containsKey('HD_RF_TRIGGER_FLAG__c'))
   {
     List<HD_RF_TRIGGER_FLAG__c> rfCustomeSettingRecord = [Select id,Name from HD_RF_TRIGGER_FLAG__c LIMIT 2];
     if( rfCustomeSettingRecord.size() == 0 )
     {
     List<HD_RF_TRIGGER_FLAG__c>  rfList =  new List<HD_RF_TRIGGER_FLAG__c>();
     HD_RF_TRIGGER_FLAG__c  HD_RemedyForceCustomizations = new HD_RF_TRIGGER_FLAG__c(Name='HD_RemedyForceCustomizations',Enable__c=true,Information__c='This is Old trigger');
     rfList.add(HD_RemedyForceCustomizations);
     HD_RF_TRIGGER_FLAG__c  HD_RemedyForceCustomization_Tri = new HD_RF_TRIGGER_FLAG__c(Name='HD_RemedyForceCustomization_Tri',Enable__c=false,Information__c='This is new trigger');
     rfList.add(HD_RemedyForceCustomization_Tri);
     //Inserting 
      insert rfList; 
     }//if( rfCustomeSettingRecord.size() == 0 )

   }//if(gd.containsKey('HD_RF_TRIGGER_FLAG__c'))
  //adding dataload custom setting added by Bhaskar verma 
   Group gp = new Group();
   gp.Name = 'Triage_Team';
   insert gp;
   //adding dataload custom setting added by Bhaskar verma 
   HD_DataLoad__c dl = new HD_DataLoad__c();
   dl.name = 'Triage_Team';
   dl.TextValue__c = gp.Id;
   insert dl;
   //if(HdDataLoadCustomSettings.size() == 0)

}//private static void InsertCustomeSettings()

 //Use this method to get the Severity four ID 
 private static String getSeverityfour()
 {
  String Id = null;
    List<BMCServiceDesk__Urgency__c> urgency4 = [select Id from BMCServiceDesk__Urgency__c where NAME = 'Severity 4' limit 1];
        if(urgency4.size() > 0)
         {
          Id = urgency4[0].Id;
        }
        else
        {
         BMCServiceDesk__Urgency__c urgency4_ins = new BMCServiceDesk__Urgency__c(Name='Severity 4');
         insert urgency4_ins; 
         Id = urgency4_ins.Id;
         }
         return Id;
 }//
  
 //Use this method to get the Impact LOW ID
 private static String getImpactlow(){
  String Id = null;
     //Populating Impact Value for LOW
         List<BMCServiceDesk__Impact__c> impactlow =  [ select Id from BMCServiceDesk__Impact__c where NAME = 'LOW' LIMIT 1 ];
         if (impactlow.size() >  0)
         {
          Id = impactlow[0].Id;
         }
         else
         {
           BMCServiceDesk__Impact__c impactlow_ins = new BMCServiceDesk__Impact__c(Name='LOW');
           insert impactlow_ins;
           Id = impactlow_ins.Id;
         }
         return Id;
  }//
  
  //Use this method to get the Category ID since service is nothing but the category 
  private static String serviceId()
  {
    String Id = null;
    List<BMCServiceDesk__Category__c> cat = new List<BMCServiceDesk__Category__c>();
    cat = [Select Name, Id,BMCServiceDesk__AvailableForIncidents__c,BMCServiceDesk__Display_In_SelfService__c From BMCServiceDesk__Category__c  WHERE  BMCServiceDesk__inactive__c = false AND BMCServiceDesk__AvailableForIncidents__c = true AND BMCServiceDesk__Display_In_SelfService__c = true LIMIT 1 ];
    
    if( cat.size() > 0 )
    {
       System.assertEquals(1, cat.size());
        Id = cat[0].Id;
    }

    return Id;
  }//
  
  //Use this method to get the status ID since  
  private static String StatusId(String StatusName)
  {
    String Id = null;
    List<BMCserviceDesk__status__c> status  = new List<BMCserviceDesk__status__c>();
    status = [ select Id,Name from BMCserviceDesk__status__c WHERE BMCServiceDesk__appliesToProblem__c = true AND Name =:StatusName LIMIT 1 ];
    
    if( status.size() > 0)
    {
      System.assertEquals(1, status.size());
        Id = status[0].Id;
    }
    /*
    else if(status.size() == 0)
    {
       BMCserviceDesk__status__c status_insert = new BMCserviceDesk__status__c(Name='UNASSIGNED',BMCServiceDesk__appliesToIncident__c=true,BMCServiceDesk__defaultStatus__c=true,BMCServiceDesk__state__c=true);
       insert status_insert;
      Id = status_insert.id;
    }
    */
    return Id;
  }//

//Creating test Incident Data
  private static List<BMCServiceDesk__Incident__c> IncTestdata(integer countProblem)
  {
     List<BMCServiceDesk__Incident__c> Inclist = new List<BMCServiceDesk__Incident__c>();
     String serId = serviceId();
    for ( integer i = 1 ; i <= countProblem ; i++  )
    {
        BMCServiceDesk__Incident__c inc = new BMCServiceDesk__Incident__c();
        inc.BMCServiceDesk__FKCategory__c = serId;
        inc.HD_Ticket_Priority__c = '4';
        inc.BMCServiceDesk__incidentDescription__c = 'Event Trigger';   
        inc.BMCServiceDesk__shortDescription__c = 'Test Data Description values '+i;

        //getting required field that y added 
        inc.BMCServiceDesk__FKUrgency__c = getSeverityfour();
        inc.BMCServiceDesk__FKImpact__c = getImpactlow();
               
        //Adding it to the collection
        Inclist.add( inc );
    }
    
    
    return Inclist;
  }//private static List<BMCServiceDesk__Problem__c> ProblemTestdata(integer countProblem)

/*
*@Usage will test the Batch Apex class
*
*/
/*
 static testMethod void runAbatchTest() 
    {
        //creating a Incident test data
      InsertCustomeSettings();
      StatusId('UNASSIGNED');
        //creating a incident test data
        List<BMCServiceDesk__Incident__c> incdata = IncTestdata(1);
        insert incdata;
        
        Test.startTest();
        //positive work
         HD_TicketStatusAlert_batchapex hd = new HD_TicketStatusAlert_batchapex(false);
       String cronID = Database.executeBatch(hd);
        Test.stopTest();
        
    }// 
    */


    /*
    *@Usage will test the Schedulabel Apex class
    *
    */

     static testMethod void runSchedulerforHD_TicketStatusAlert_batchapex()
     {
        //creating a Incident test data
      insertCustomSettings();
      //StatusId('UNASSIGNED');
        //List<BMCServiceDesk__Incident__c> incdata = IncTestdata(1);
        //insert incdata;
        
        Test.startTest();
        HD_TicketStatusAlert m = new HD_TicketStatusAlert();
        String sch = '0 30 * * * ?'; //every 30 min
        String jobID = system.schedule('HD Ticket Status', sch, m);  
        // Get the information from the CronTrigger API object
         CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered,NextFireTime  FROM CronTrigger WHERE id = :jobId];
           // Verify the expressions are the same
        System.assertEquals(sch,ct.CronExpression);
        Test.stopTest();

     }//
}