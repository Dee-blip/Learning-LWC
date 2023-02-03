/*
* File Name: HD_Test_ChangeStatusScheduler
* Description : Test class for HD_ChangeRequestScheduler
* @author :
* Modification Log ===============================================================
* Date                      Author               Modification
* Oct 13th, 2021            Aneesh Budnar        PRTORES-977 - Fix Test class failures
*/
@isTest(SeeAllData=false)
private class HD_Test_ChangeStatusScheduler {


public static List<User> SD_Stafs = [select Id,username,HD_CMR_TAG__C from User where Profile.name = 'ServiceDesk Staff' and isActive = true limit 2];
public static List<User> hdClients = [select Id,username,HD_CMR_TAG__C from User where Profile.name = 'HelpDesk Client Profile' and isActive = true limit 5];
public static User usr = [select Id,username,HD_CMR_TAG__C from User where isActive = true and HD_CMR_TAG__C = 'SPONSOR' limit 1];
static
    {
		HD_ChangeRequestTestDataFactory initObj = new HD_ChangeRequestTestDataFactory();
    }
    
    private static BMCServiceDesk__Change_Request__c getChange(DateTime Schdt, String statusName){
  
  
    
    BMCServiceDesk__Change_Request__c  change = new BMCServiceDesk__Change_Request__c();
    change.Service_Element_Impact_duration__c = '00:10';
    change.HD_Sponsor__c = usr.id;
    change.Change_Coordinator_Primary__c = hdClients[1].id;
    change.BMCServiceDesk__Scheduled_End_Date__c  =  Schdt.addMinutes(2);
    change.BMCServiceDesk__Scheduled_Start_Date__c = Schdt;
    change.HD_Change_Status__c = 'AUTHORIZED';
    change.CR_Approval_Status__c = 'AUTHORIZED';
    change.Change_Locked__c = false;
    /*
    insert change;
    
    if (statusName == 'IN PROGRESS'){
    
       change.HD_Change_Status__c  = 'IN PROGRESS';
       update change;
    }
    */
   
    return change;
  
  }
  
public static void sleep(Long milliSeconds)
{
        Long timeDiff = 0;
        DateTime firstTime = System.now();
        do
        {
            timeDiff = System.now().getTime() - firstTime.getTime();
        }
        while(timeDiff <= milliSeconds);
}




  private static String getTimeStr(DateTime dt){
  
           String Csec,Cmin,Chr,Cday,Cmonth,CYear,SchTimer;
            
            Csec=String.valueof(dt.second());
            Cmin=String.valueof(dt.minute());
            Chr=String.valueof(dt.hour());
            Cday=String.valueof(dt.day());
            Cmonth=String.valueof(dt.month());
            CYear=String.valueof(dt.Year());
            SchTimer=Csec+' '+Cmin+' '+Chr+' '+Cday+' '+Cmonth+' ? '+CYear;
            return SchTimer;
  
  }
      
   
   static testmethod void SchedularTest() {
   

   
   BMCServiceDesk__Change_Request__c  change1 = getChange(System.now().addMinutes(-20), 'AUTHORIZED');
   BMCServiceDesk__Change_Request__c  change2 = getChange(System.now().addMinutes(-18), 'IN PROGRESS');
   
   BMCServiceDesk__Change_Request__c  change3 = getChange(System.now().addMinutes(-10), 'AUTHORIZED');
   BMCServiceDesk__Change_Request__c  change4 = getChange(System.now().addMinutes(-8), 'IN PROGRESS');
   
   BMCServiceDesk__Change_Request__c  change5 = getChange(System.now().addMinutes(9), 'AUTHORIZED');
   BMCServiceDesk__Change_Request__c  change6 = getChange(System.now().addMinutes(11), 'IN PROGRESS');
   

   BMCServiceDesk__Change_Request__c  change9 = getChange(System.now().addMinutes(18), 'AUTHORIZED');
   BMCServiceDesk__Change_Request__c  change11 = getChange(System.now().addMinutes(21), 'IN PROGRESS');
   
   BMCServiceDesk__Change_Request__c  change7 = getChange(System.now().addMinutes(31), 'AUTHORIZED');
   BMCServiceDesk__Change_Request__c  change8 = getChange(System.now().addMinutes(50), 'IN PROGRESS');
   
   LIST<BMCServiceDesk__Change_Request__c> authCMRs 
   = new LIST<BMCServiceDesk__Change_Request__c>{change1,change2,change3,change4,change5,change6,change7,change8,change9,change11};

    insert authCMRs;

   LIST<BMCServiceDesk__Change_Request__c> inprCMRs 
   = new LIST<BMCServiceDesk__Change_Request__c>{change2,change4,change6,change8,change11};

   for( BMCServiceDesk__Change_Request__c ch : inprCMRs ){
    ch.HD_Change_Status__c = 'IN PROGRESS';
   }

   update inprCMRs;


      

      // Schedule the test job
                      
   Test.startTest();       
   HD_ChangeRequestScheduler ab = new HD_ChangeRequestScheduler();
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

      
   String jobId = system.schedule('Change Schedular', SchTimer, ab);
    
           
      // Get the information from the CronTrigger API object
      CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, 
         NextFireTime
         FROM CronTrigger WHERE id = :jobId];

      // Verify the expressions are the same
      System.assertEquals(SchTimer, ct.CronExpression);

      // Verify the job has not run
     // System.assertEquals(0, ct.TimesTriggered);


     
      LIST<ID> changeids = new LIST<ID>{change1.id,change2.id,change3.id,change4.id,change5.id,change6.id,change6.id,change9.id,change11.id};
      
          LIST  <BMCServiceDesk__Change_Request__c> change_list = [SELECT ID,NAME,HD_Change_Status__c,Change_Locked__c ,Scheduled_Job_Lock__c
              FROM BMCServiceDesk__Change_Request__c WHERE ID IN :changeids ]; 

         System.debug('ALL DEBUG');
         for(BMCServiceDesk__Change_Request__c chr :change_list){
         
          System.debug('CMR - '+chr.name+' status - '+chr.HD_Change_Status__c+' Lock '+chr.Change_Locked__c+' JOb - '+chr.Scheduled_Job_Lock__c);
          //System.assertEquals(true, chr.change_Locked__c);
            
         }

        

       
         Test.stopTest();

   }
   
 
 static testmethod void StatusUpdaterTest() {
   

  BMCServiceDesk__Change_Request__c  change11 = getChange(System.now().addMinutes(-30), 'AUTHORIZED');
  BMCServiceDesk__Change_Request__c  change12 = getChange(System.now().addMinutes(-20), 'IN PROGRESS');
  BMCServiceDesk__Change_Request__c  change13 = getChange(System.now().addMinutes(-30), 'AUTHORIZED');
  BMCServiceDesk__Change_Request__c  change14 = getChange(System.now().addMinutes(-20), 'IN PROGRESS');
  BMCServiceDesk__Change_Request__c  change15 = getChange(System.now().addMinutes(-30), 'AUTHORIZED');
  BMCServiceDesk__Change_Request__c  change16 = getChange(System.now().addMinutes(-20), 'IN PROGRESS');
  BMCServiceDesk__Change_Request__c  change17 = getChange(System.now().addMinutes(-30), 'AUTHORIZED');
  BMCServiceDesk__Change_Request__c  change18 = getChange(System.now().addMinutes(-20), 'IN PROGRESS');
  BMCServiceDesk__Change_Request__c  change19 = getChange(System.now().addMinutes(-30), 'AUTHORIZED');
  BMCServiceDesk__Change_Request__c  change20 = getChange(System.now().addMinutes(-20), 'IN PROGRESS');
     

   LIST<BMCServiceDesk__Change_Request__c> authCMRs 
   = new LIST<BMCServiceDesk__Change_Request__c>{change11,change12,change13,change14,change15,change16,change17,change18,change19,change20};

    insert authCMRs;


     LIST<BMCServiceDesk__Change_Request__c> inprCMRs 
   = new LIST<BMCServiceDesk__Change_Request__c>{change12,change14,change16,change18,change20};

   for( BMCServiceDesk__Change_Request__c ch : inprCMRs ){
    ch.HD_Change_Status__c = 'IN PROGRESS';
   }

   update inprCMRs;
    


    System.debug('CHREQ - '+change14.ID+' -- '+change15.ID+ ' SCHDate '+change14.BMCServiceDesk__Scheduled_End_Date__c+' -- '+change14.HD_Change_Status__c)    ; 
    String Csec,Cmin,Chr1,Cday,Cmonth,CYear;

   Datetime  dt1 = System.now();
   Datetime  dt =  dt1.addDays(2);
  
   Cmin=String.valueof(dt.minute());
   Chr1=String.valueof(dt.hour());
   Cday=String.valueof(dt.day());
   Cmonth=String.valueof(dt.month());
   CYear=String.valueof(dt.Year());
   Csec=String.valueof(dt.addSeconds(9).second());
   String SchTimer1=Csec+' '+Cmin+' '+Chr1+' '+Cday+' '+Cmonth+' ? '+CYear;
   System.debug('CHREQ2 - '+System.now()+' --- '+SchTimer1)    ; 
   
     Test.startTest();
        
     HD_ChangeRequestStatusUpdater crs1  = new HD_ChangeRequestStatusUpdater();
     system.schedule('Change StatusUpdater SA '+System.now().format(), SchTimer1, crs1);
     //sleep(6000);

     Test.stopTest();
     change15 =  [SELECT ID,NAME,HD_Change_Status__c,Change_Locked__c ,Scheduled_Job_Lock__c, Flag_For_CAB_Review__c 
              FROM BMCServiceDesk__Change_Request__c WHERE ID = :change15.ID ][0];
      System.assertEquals(true, change15.Flag_For_CAB_Review__c);       

  }

  static testmethod void bulkifyTest() {
      Test.startTest();

      BMCServiceDesk__Change_Request__c  change11 = getChange(System.now().addMinutes(-30), 'AUTHORIZED');
      BMCServiceDesk__Change_Request__c  change12 = getChange(System.now().addMinutes(-20), 'IN PROGRESS');
      BMCServiceDesk__Change_Request__c  change13 = getChange(System.now().addMinutes(-30), 'AUTHORIZED');
      BMCServiceDesk__Change_Request__c  change14 = getChange(System.now().addMinutes(-20), 'IN PROGRESS');
      BMCServiceDesk__Change_Request__c  change15 = getChange(System.now().addMinutes(-30), 'AUTHORIZED');
      BMCServiceDesk__Change_Request__c  change16 = getChange(System.now().addMinutes(-20), 'IN PROGRESS');
      BMCServiceDesk__Change_Request__c  change17 = getChange(System.now().addMinutes(-30), 'AUTHORIZED');
      BMCServiceDesk__Change_Request__c  change18 = getChange(System.now().addMinutes(-20), 'IN PROGRESS');
      BMCServiceDesk__Change_Request__c  change19 = getChange(System.now().addMinutes(-30), 'AUTHORIZED');
      BMCServiceDesk__Change_Request__c  change20 = getChange(System.now().addMinutes(-20), 'IN PROGRESS');
         
       LIST<BMCServiceDesk__Change_Request__c> authCMRs 
       = new LIST<BMCServiceDesk__Change_Request__c>{change11,change12,change13,change14,change15,change16,change17,change18,change19,change20};

        insert authCMRs;


         LIST<BMCServiceDesk__Change_Request__c> inprCMRs 
       = new LIST<BMCServiceDesk__Change_Request__c>{change12,change14,change16,change18,change20};

       for( BMCServiceDesk__Change_Request__c ch : inprCMRs ){
        ch.HD_Change_Status__c = 'IN PROGRESS';
       }

       update inprCMRs;
       Test.stopTest();
    }
}