/* Notify assigned staff whenever client replies to the mail received via �Email Conversation� feature.    
- The status of the associated Incident should change to �Customer responded�.
*/

/* 
Last Modified as a part of CR 2688114 - Fixing Test Classes for Validation Rule- Description should not be
Developer@ Hemant Kumar
Comment : Whole Test class Modification , Wrong test method logic was written
* Modification Log ===============================================================
* Date 				   Author 					Modification
* Sept 15th, 2021    Aneesh Budnar        PRTORES-2275 - Added tests for handling OOO changes
*/

@isTest(seealldata=false)
Public class HD_Test_UpdateStatusToCustomerResponded
{
 
/*
//creating a test data 
static BMCServiceDesk__Urgency__c urgency;
public static List<BMCServiceDesk__Status__c> status;
public static  BMCServiceDesk__Impact__c impactlow;

public static  BMCServiceDesk__Category__c cat;
*/
public static id newActionID;
public static id actionIDEmailSent;
public static List<BMCServiceDesk__Action__c> actList;
public static List<BMCServiceDesk__Action__c> actList2;
public static BMCServiceDesk__Incident__c testIncident;

static{
  HD_IncidentTestDataFactory rfFactory = new HD_IncidentTestDataFactory();
  testIncident = rfFactory.getIncidentTestData(HD_IncidentTestDataFactory.Team.GENERIC);
}


//creating a function to inert Custom Settings
private static void UtilFunc()
{    
     List<HD_EIS_INCIDENT_GROUP__c> groupList = HD_EIS_INCIDENT_GROUP__c.getall().values();
     
     
     if( groupList==null|| groupList.size() == 0 )
     {
        HD_EIS_INCIDENT_GROUP__c IncidentGroup = new HD_EIS_INCIDENT_GROUP__c();
        HD_EIS_INCIDENT_GROUP__c IncidentGroup1 = new HD_EIS_INCIDENT_GROUP__c();
        HD_EIS_INCIDENT_GROUP__c IncidentGroup2 = new HD_EIS_INCIDENT_GROUP__c();
        HD_EIS_INCIDENT_GROUP__c IncidentGroup3 = new HD_EIS_INCIDENT_GROUP__c();
        HD_EIS_INCIDENT_GROUP__c IncidentGroup4 = new HD_EIS_INCIDENT_GROUP__c();
        
        IncidentGroup.NAME = 'HELPDESK_HARDWARE';
        IncidentGroup.IncidentGroup__c = 'Q_HELPDESK_HARDWARE';
        groupList.add(IncidentGroup);
        
        
        IncidentGroup1.NAME = 'HELPDESK_MALWARE';
        IncidentGroup1.IncidentGroup__c = 'Q_HELPDESK_MALWARE';
        groupList.add(IncidentGroup1);
        
        
        IncidentGroup2.NAME = 'HELPDESK_TRIAGE';
        IncidentGroup2.IncidentGroup__c = 'Q_HELPDESK_TRIAGE';
        groupList.add(IncidentGroup2);
        
        
        IncidentGroup3.NAME = 'ITOC';
        IncidentGroup3.IncidentGroup__c = 'Q_ITOC';
        groupList.add(IncidentGroup3);
        
        
        IncidentGroup4.NAME = 'ITOC_Alerts';
        IncidentGroup4.IncidentGroup__c = 'Q_ITOC_Alerts';
        groupList.add(IncidentGroup4);
        
        Insert groupList;
               
        
        
     }//if( groupList==null|| groupList.size() == 0 )
     System.debug('GroupList CustomSetting------>'+groupList);
     
}//private static void UtilFunc()

//initializing this as main function
private static void init()
{
//Calling Util Function 
 UtilFunc();
 ManagedPkgErrorClass.isFromManagedPackage=false;
 /*
 //Status Query
 status = [Select id from BMCServiceDesk__Status__c where BMCServiceDesk__Status__c.Name='Customer Responded' Limit 1];
 System.debug('Status ------>'+status);
 
 //Urgency setup . . . . . . . .
 urgency = [select Id from BMCServiceDesk__Urgency__c where NAME = 'Severity 4'];
 if(urgency == null)
  {
   urgency =new BMCServiceDesk__Urgency__c(Name='Severity 4');
   insert urgency;
  }//  
 System.debug('urgency ------>'+urgency);
 
 
  //Creating  impact . . . . .  . .
  impactlow =  [ select Id from BMCServiceDesk__Impact__c where NAME = 'LOW' LIMIT 1 ];
  if (impactlow == null)
  {
   impactlow = new BMCServiceDesk__Impact__c(Name='LOW');
   insert impactlow;
  }//
  System.debug('impactlow ------>'+impactlow);
  
  ////Creating Priority Custom Settings
  List<HD_Ticket_Priority__c> priority_list = new List<HD_Ticket_Priority__c>();         
           HD_Ticket_Priority__c priority_setting;
           HD_Ticket_Priority__c priority_setting1;
           
            if(HD_Ticket_Priority__c.getInstance('3') == null){
            
                priority_setting = new HD_Ticket_Priority__c();
                priority_setting.Name = '3';
                priority_setting.Urgency_Id__c = urgency.Id;
                priority_setting.Urgency_Name__c = 'Severity 3';
                priority_list.add(priority_setting);
            }
            
            if(HD_Ticket_Priority__c.getInstance('4') == null){

                priority_setting1 = new HD_Ticket_Priority__c();
                priority_setting1.Name = '4';
                priority_setting1.Urgency_Id__c = urgency.Id;
                priority_setting1.Urgency_Name__c = 'Severity 4';
                priority_list.add(priority_setting1);
            }       
            
            insert priority_list;
            System.debug('priority_list ------>'+priority_list);
            
 //Create a new sample category
   //cat = [select Id from BMCServiceDesk__Category__c where NAME = 'Additional Desktop/Laptop'];
   //          if(cat == null)
   //          {
   //              cat = new BMCServiceDesk__Category__c (NAME='Additional Desktop/Laptop');
   //              insert cat;
   //              system.AssertNotEquals(cat,Null);
   //          }//if(cat == null)
   
   // System.debug('Category ------>'+cat);   
   cat = new BMCServiceDesk__Category__c (NAME='New Test Category');
   cat.BMCServiceDesk__inactive__c = false;
   cat.BMCServiceDesk__AvailableForIncidents__c =true;
   BMCServiceDesk__CategoryTypes__c rctype = null;
   //query the queue type
   List<BMCServiceDesk__CategoryTypes__c>  cd_types = [select id from  BMCServiceDesk__CategoryTypes__c where name = 'Q_ITOC' limit 1];

    if (cd_types.size() <= 0){
       BMCServiceDesk__CategoryTypes__c ctype = new BMCServiceDesk__CategoryTypes__c(Name ='Q_ITOC' );       
       insert ctype;
       rctype = ctype;
     }else{
       rctype = cd_types[0];
     }
     cat.BMCServiceDesk__FKCategoryType__c = rctype.id;
     insert cat;
   system.AssertNotEquals(cat,Null);
   */
            //Action: Stores the Action ID
             actList  = [select id from BMCServiceDesk__Action__c where BMCServiceDesk__Action__c.Name='Email Received'];
             System.debug('size:'+actList.size());
             System.debug(actList[0]);
             newActionID = actList[0].Id;

             //commented now
                /*        
             if(actList.size() == 0)
             {
              System.debug('actList.size() = 0');
             BMCServiceDesk__Action__c ac = new BMCServiceDesk__Action__c(Name='Email Received');
             actList.add(ac);
             insert actList;
             for(BMCServiceDesk__Action__c acObj:actList)
             {
                newActionID = acObj.id;
                System.debug('newActionId in if: '+newActionID);
             }//for(Action acObj:actList)
             }
             else
             {
              System.debug('In action else');
              for(BMCServiceDesk__Action__c acObj:actList)
             {
                newActionID = acObj.id;
                System.debug('newActionId in else: '+newActionID);
             }//for(Action acObj:actList)
             }//else
             */
             //commented till here
             System.debug('newActionID email received ------>'+newActionID);  

             //fetching action ID for email Sent
             actList2  = [select id from BMCServiceDesk__Action__c where BMCServiceDesk__Action__c.Name='Email Sent'];
             System.debug('size:'+actList2.size());
             System.debug(actList2[0]);
             actionIDEmailSent = actList2[0].Id;
             
             /*            
             if(actList2.size() < 0)
             {
             BMCServiceDesk__Action__c ac1 = new BMCServiceDesk__Action__c(Name='Email Received');
             actList2.add(ac1);
             insert actList2;
             for(BMCServiceDesk__Action__c acObj:actList2)
             {
                actionIDEmailSent = acObj.id;
             }//for(Action acObj:actList2)
             }
             else
             {
              for(BMCServiceDesk__Action__c acObj:actList2)
             {
                actionIDEmailSent = acObj.id;
             }//for(Action acObj:actList2)
             }//else
             */
             System.debug('actionIDEmailSent ------>'+actionIDEmailSent);

             //insert custom setting
             List<HD_Incident_Settings__c> custom_settings1 = new List<HD_Incident_Settings__c>();
             custom_settings1.add(new HD_Incident_Settings__c(name = 'Missing_Actions_Update', value__c = 'Email Sent'));
             custom_settings1.add(new HD_Incident_Settings__c(name = 'OOO_Subject_Pattern_English', value__c = 'Subject: [Akamaihd-tix] Automatic reply:'));
             insert custom_settings1;
    
}//private static void init()

static testMethod void UpdateStatusToCustomerResponded() 
{
    //Calling init method
    init();
    
            //Creating a new Incident         
             //BMCServiceDesk__Incident__c newIncident = new BMCServiceDesk__Incident__c(BMCServiceDesk__FKCategory__c=cat.id,BMCServiceDesk__FKClient__c = system.userInfo.getUserId(),BMCServiceDesk__FKUrgency__c=urgency.id,BMCServiceDesk__FKImpact__c = impactlow.Id,BMCServiceDesk__incidentDescription__c = 'Test Data Description values ' );
             //insert newIncident;
             //system.AssertNotEquals(newIncident,Null);
             BMCServiceDesk__Incident__c newIncident = testIncident;
             
    test.startTest();
    // Creating a new Incident History record
             BMCServiceDesk__IncidentHistory__c newHistory = new BMCServiceDesk__IncidentHistory__c(BMCServiceDesk__FKIncident__c=newIncident.id,BMCServiceDesk__FKAction__c=newActionID);
             newHistory.BMCServiceDesk__note__c = 'From: '+UserInfo.getUserEmail()+'Sent: Fri, Feb 12, 2016 14:01 PMTo: eis-tools-dev@akamai.com; Cc: Subject: Re: [Eis-tools-dev] Sandbox: Akamai Ticketing Incident ticket #(Ref:IN:00252480) has been created and assigned to EAE OpsTest isFrom: Akamai ticketing testDate: Friday, February 12, 2016 at 1:59 PMTo: Pranav PrashantCc: Akamai ticketing testSubject: Sandbox: Akamai Ticketing Incident ticket #(Ref:IN:00252480) has been created and assigned to EAE OpsIncident # 00252480 has been assigned to EAE Ops. This incident has the following details:      Incident Short Description: dasd      Incident Description: dasd      Resolution:      Client Name: Pranav Prashant      Client Title : Software Engineer..      Client Manager : Sachin Siddaveerappa      Category: Crm.akamai.com      Category Tree: Enterprise Application      Open Date: 2/12/2016 8:29 AM      Priority: 2      View ticket 00252480<https://urldefense.proofpoint.com/v2/url?u=https-3A__akamai-2D-2DP2RDev.cs43.my.salesforce.com_-3FstartURL-3D_apex_bmcservicedesk-5F-5Fssredirect-3Finc-3Da5U6300000000hl&d=CwMCaQ&c=96ZbZZcaMF4w0F4jpN6LZg&r=BCTH9VJ0q72k9lrtcBvW1h7TJhSrF-FbWhlgBfSoTb0&m=XHt8uPe5u_nUeHjL6sLjjeYuce4iwO5z8yiiihtOS0Q&s=EOmCOv0wSTeSiNtE0fvIrg1iSLwAkqecnYG3PCb-oQY&e=>';
             insert newHistory;
             BMCServiceDesk__IncidentHistory__c newHistory1 = new BMCServiceDesk__IncidentHistory__c(BMCServiceDesk__FKIncident__c=newIncident.id,BMCServiceDesk__FKAction__c=actionIDEmailSent);
             insert newHistory1;
    test.stopTest();         
    
    
}//static testMethod void UpdateStatusToCustomerResponded() 
    
    static testMethod void doNotUpdateStatusToCustomerResponded() 
    {
        //Calling init method
        init();
        
        BMCServiceDesk__Incident__c newIncident = testIncident;
        
        test.startTest();
        // Creating a new Incident History record
        BMCServiceDesk__IncidentHistory__c newHistory = new BMCServiceDesk__IncidentHistory__c(BMCServiceDesk__FKIncident__c=newIncident.id,BMCServiceDesk__FKAction__c=newActionID);
        newHistory.BMCServiceDesk__note__c = 'From: '+UserInfo.getUserEmail()+'Sent: Fri, Feb 12, 2016 14:01 PMTo: eis-tools-dev@akamai.com; Cc: Subject: [Akamaihd-tix] Automatic reply: Re: [Eis-tools-dev] Sandbox: Akamai Ticketing Incident ticket #(Ref:IN:00252480) has been created and assigned to EAE OpsTest isFrom: Akamai ticketing testDate: Friday, February 12, 2016 at 1:59 PMTo: Pranav PrashantCc: Akamai ticketing testSubject: Sandbox: Akamai Ticketing Incident ticket #(Ref:IN:00252480) has been created and assigned to EAE OpsIncident # 00252480 has been assigned to EAE Ops. This incident has the following details:      Incident Short Description: dasd      Incident Description: dasd      Resolution:      Client Name: Pranav Prashant      Client Title : Software Engineer..      Client Manager : Sachin Siddaveerappa      Category: Crm.akamai.com      Category Tree: Enterprise Application      Open Date: 2/12/2016 8:29 AM      Priority: 2      View ticket 00252480<https://urldefense.proofpoint.com/v2/url?u=https-3A__akamai-2D-2DP2RDev.cs43.my.salesforce.com_-3FstartURL-3D_apex_bmcservicedesk-5F-5Fssredirect-3Finc-3Da5U6300000000hl&d=CwMCaQ&c=96ZbZZcaMF4w0F4jpN6LZg&r=BCTH9VJ0q72k9lrtcBvW1h7TJhSrF-FbWhlgBfSoTb0&m=XHt8uPe5u_nUeHjL6sLjjeYuce4iwO5z8yiiihtOS0Q&s=EOmCOv0wSTeSiNtE0fvIrg1iSLwAkqecnYG3PCb-oQY&e=>';
        insert newHistory;
        BMCServiceDesk__IncidentHistory__c newHistory1 = new BMCServiceDesk__IncidentHistory__c(BMCServiceDesk__FKIncident__c=newIncident.id,BMCServiceDesk__FKAction__c=actionIDEmailSent);
        insert newHistory1;
        test.stopTest();         
        System.assertNotEquals('CUSTOMER RESPONDED', newIncident.BMCServiceDesk__Status_ID__c,'Expected value not similar to the actual value');
        
    }//static testMethod void doNotUpdateStatusToCustomerResponded()


  static testMethod void dleisNotes(){
    init();
    LIST<BMCServiceDesk__Action__c> actList1  = [select id from BMCServiceDesk__Action__c where BMCServiceDesk__Action__c.Name='Notes'];
     ID actionid;                  
             if(actList1.size() < 1)
             {
                 BMCServiceDesk__Action__c ac = new BMCServiceDesk__Action__c(Name='Notes');
                 insert ac;
                 actionID = ac.id;
                
             }
             else
             {
                 
                    actionID = actList1[0].id;
                 
             }//else
             

             //BMCServiceDesk__Incident__c newIncident = new BMCServiceDesk__Incident__c(BMCServiceDesk__FKCategory__c=cat.id,BMCServiceDesk__FKClient__c = system.userInfo.getUserId(),BMCServiceDesk__FKUrgency__c=urgency.id,BMCServiceDesk__FKImpact__c = impactlow.Id,BMCServiceDesk__incidentDescription__c = 'Test Data Description values ', HD_Notify_DL_EIS_on_Notes_Update__c =true);
             //insert newIncident;
             BMCServiceDesk__Incident__c newIncident =  testIncident;
             test.startTest();
             BMCServiceDesk__IncidentHistory__c newHistory = new BMCServiceDesk__IncidentHistory__c(BMCServiceDesk__FKIncident__c=newIncident.id,BMCServiceDesk__FKAction__c=actionID, BMCServiceDesk__note__c='Test Action Note');
             insert newHistory;
             test.stopTest();
             
             
  
  }


}//Test Class Ends