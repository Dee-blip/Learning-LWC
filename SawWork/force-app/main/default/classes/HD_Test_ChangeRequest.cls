@isTest(SeeAllData = false)

private class HD_Test_ChangeRequest {

  public static List<User> SD_Stafs = [select Id, username from User where Profile.name = 'ServiceDesk Staff' and isActive = true limit 5];
  public static List<User> HD_Clients = [select Id, username from User where Profile.name = 'Helpdesk Client Profile' and isActive = true limit 5];
	static
    {
		HD_ChangeRequestTestDataFactory initObj = new HD_ChangeRequestTestDataFactory();
    }
    

  @isTest
  static void ChangeCMRLockTest() {

    test.startTest();
    
    
    String lock_msg = 'CMR is auto locked. Contact CMR CAB Managers to update the CMR' ;
    //HD_CMR_SETTINGS__c SETTING_LOCK_MESSAGE  =   HD_CMR_SETTINGS__c.getInstance('Lock_Error_Message');

    //if (SETTING_LOCK_MESSAGE != NULL && SETTING_LOCK_MESSAGE.Value__c != '')
     // lock_msg = SETTING_LOCK_MESSAGE.Value__c;



    BMCServiceDesk__Change_Request__c change = HD_ChangeRequestTestDataFactory.getchange();
    change.HD_Resources__c = 'abc@akamai.com';
    change.Change_Summary__c = 'Test Test';
    change.HD_Change_Status__c = 'OPENED';
    change.Status_Change_Notification__c = 'abcde@akamai.com';
    insert change;
    List<Change_Coordinator__c> chcordlist = new List<Change_Coordinator__c>();



    //Testing CMR Lock
    BMCServiceDesk__Change_Request__c change1 = HD_ChangeRequestTestDataFactory.getchange();
    change1.HD_Resources__c = 'abc@akamai.com';
    change1.Change_Summary__c = 'Test Test';

    change1.Status_Change_Notification__c = 'abcde@akamai.com';

    change1.HD_Change_Status__c = 'AUTHORIZED';
    change1.CR_Approval_Status__c = 'AUTHORIZED';
    insert change1;



    try {

      System.debug('ABCDEF3 -- ' + change1.Change_Locked__c );

      BMCServiceDesk__Change_Request__c change2 = [SELECT ID, HD_Change_Status__c FROM BMCServiceDesk__Change_Request__c WHERE ID = :Change1.ID][0];
      change2.HD_Change_Status__c = 'IN PROGRESS';
      change2.Change_Locked__c = true;
      update change2;

      System.assertEquals(change1.Status_Change_Notification__c,'abcde@akamai.com');

    } catch (Exception e) {
      System.debug('ABCDEF --');
      System.debug(lock_msg);
      System.debug(e.getMessage());

      
    }


    test.stopTest();

  }


  @isTest
  static void  SponsorAccessTest() {

    BMCServiceDesk__Change_Request__c change = HD_ChangeRequestTestDataFactory.getchange();


    insert change;
	test.startTest();
    List <BMCServiceDesk__Change_Request__Share> slist = [Select Id from BMCServiceDesk__Change_Request__Share where RowCause = 'Sponsor__c' and UserOrGroupId = :change.HD_Sponsor__c and ParentId = :change.id];
    System.assertNotEquals(0, slist.size());



    //List<BMCServiceDesk__Change_Request__c> changes = [Select id, name, HD_Sponsor__c, BMCServiceDesk__FKUrgency__c, BMCServiceDesk__FKImpact__c, BMCServiceDesk__FKPriority__c FROM BMCServiceDesk__Change_Request__c where id = :change.id Limit 1];
    //change = changes[0];
    change.HD_Sponsor__c = [select Id, username from User where Profile.name = 'ServiceDesk Staff' and HD_CMR_TAG__C = 'SPONSOR' and isActive = true and Id != :change.HD_Sponsor__c limit 1].Id;


    Update change;



    slist = [Select Id from BMCServiceDesk__Change_Request__Share where RowCause = 'Sponsor__c' and UserOrGroupId = :change.HD_Sponsor__c and ParentId = :change.id];

    System.assertNotEquals(0,slist.size());

    slist = [Select Id from BMCServiceDesk__Change_Request__Share where RowCause = 'Sponsor__c' and UserOrGroupId = :HD_Clients[0].id and ParentId = :change.id];

    System.assertEquals(0,slist.size());
	test.StopTest();

  }


  //Primary Coordinator Test

  @isTest
  static void  CoordinatorAccessTest() {

    BMCServiceDesk__Change_Request__c change = HD_ChangeRequestTestDataFactory.getchange();
    test.startTest();
    insert change;
    List <BMCServiceDesk__Change_Request__Share> slist = [Select Id from BMCServiceDesk__Change_Request__Share where RowCause = 'Coordinator__c' and UserOrGroupId = :change.Change_Coordinator_Primary__c and ParentId = :change.id];
    System.assertNotEquals(0, slist.size());

    change.Change_Coordinator_Primary__c = SD_Stafs[4].id;

    Update change;


    slist = [Select Id from BMCServiceDesk__Change_Request__Share where RowCause = 'Coordinator__c' and UserOrGroupId = :SD_Stafs[4].id and ParentId = :change.id];

    System.assertNotEquals(0,slist.size());

    slist = [Select Id from BMCServiceDesk__Change_Request__Share where RowCause = 'Coordinator__c' and UserOrGroupId = :SD_Stafs[3].id and ParentId = :change.id];

    System.assertEquals(0,slist.size());




    // Related List Coordinator Test

    Change_Coordinator__c chcord = new  Change_Coordinator__c(User__c =  HD_Clients[1].id, Change_Request__c = change.id);
    insert chcord;

    //slist = [Select Id from BMCServiceDesk__Change_Request__Share where RowCause = 'Coordinator__c' and UserOrGroupId = :HD_Clients[1].id and ParentId = :change.id];
    // System.assertNotEquals(0,slist.size());

    chcord.User__c = SD_Stafs[1].id;
    update chcord;

    slist = [Select Id from BMCServiceDesk__Change_Request__Share where RowCause = 'Coordinator__c' and UserOrGroupId = :SD_Stafs[1].id and ParentId = :change.id];

    System.assertNotEquals(0, slist.size());


    test.StopTest();


  }


  @isTest
  static void  StatusChangeTest() {
    BMCServiceDesk__Change_Request__c change1 = HD_ChangeRequestTestDataFactory.getchange();
    change1.HD_Resources__c = 'kahegde@akamai.com';
    change1.Change_Summary__c = 'Test Test';
    change1.HD_Change_Status__c = 'OPENED';
    change1.Status_Change_Notification__c = 'vmata@akamai.com';


    BMCServiceDesk__Change_Request__c change2 = HD_ChangeRequestTestDataFactory.getchange();
    change2.HD_Resources__c = 'kahegde@akamai.com,mytest@akamai.com';
    change2.Change_Summary__c = 'Test Test';
    change2.HD_Change_Status__c = 'PENDING APPROVAL';
    change2.Status_Change_Notification__c = 'vmata@akamai.com';

    List<BMCServiceDesk__Change_Request__c> chlist1 = new List<BMCServiceDesk__Change_Request__c>();
    List<BMCServiceDesk__Change_Request__c> chlist2 = new List<BMCServiceDesk__Change_Request__c>();
    List<BMCServiceDesk__Change_Request__c> chlistold = new List<BMCServiceDesk__Change_Request__c>();
    List<BMCServiceDesk__Change_Request__c> chlistnew = new List<BMCServiceDesk__Change_Request__c>();
    //List<BMCServiceDesk__Change_Request__c> clist = new List<BMCServiceDesk__Change_Request__c>();
    // clist.add(change1);
    // insert clist;
    chlistold.add(change1);
    chlistnew.add(change2);

    test.startTest();

    //here we are  passing the state directly to execute the functionality: reason being trigger is a singleton class and its value is not changed for multiple insert/update operation
    HD_ChangeReqMgmt_class ins = HD_ChangeReqMgmt_class.getInstance(chlistold, chlistnew);
    ins.sendNotification();




    insert change1;
    insert change2;

    chlist1.add(change1);
    chlist2.add(change2);


    HD_ChangeReqMgmt_class changereqMgmt  = HD_ChangeReqMgmt_class.getInstance(chlist1, chlist2 );
    HD_CMR_SETTINGS__c hdcmr =  new HD_CMR_SETTINGS__c();
    hdcmr.Name = 'No_Email_Resources';
    hdcmr.Value__c = 'mytest@akamai.com';
    insert hdcmr;
    changereqMgmt.sendNotification();
    changereqMgmt.PicklistToLookup('HD_Change_Status__c', 'BMCServiceDesk__FKStatus__c', 'BMCServiceDesk__Status__c', 'Status');

    change1.HD_Change_Status__c = 'PENDING APPROVAL';
    update change1;

    LIST< BMCServiceDesk__Change_Request__c> changes = [Select id, name, HD_Change_Status__c FROM BMCServiceDesk__Change_Request__c where id = :change1.id Limit 1];
    change1 = changes[0];

    System.assertEquals('PENDING APPROVAL', change1.HD_Change_Status__c);

    test.stopTest();
  }


  @isTest
  static void  CLoseReminderTest() {

    BMCServiceDesk__Change_Request__c change = HD_ChangeRequestTestDataFactory.getchange();
    change.BMCServiceDesk__Scheduled_End_Date__c  = System.now().addDays(-13);
    change.BMCServiceDesk__Scheduled_Start_Date__c = System.now().addDays(-14);
    change.HD_Change_Status__c = 'AUTHORIZED';
    change.CR_Approval_Status__c = 'AUTHORIZED';

    insert change;

    BMCServiceDesk__Change_Request__c change11 = [select HD_Change_Status__c, ID from BMCServiceDesk__Change_Request__c where ID = :change.Id ][0];
    change11.HD_Change_Status__c = 'IN PROGRESS';
    update change11;

    change.HD_Change_Status__c = 'COMPLETED';
    update change;

    BMCServiceDesk__Change_Request__c change0 = HD_ChangeRequestTestDataFactory.getchange();
    change0.BMCServiceDesk__Scheduled_End_Date__c  = System.now().addDays(-7);
    change0.BMCServiceDesk__Scheduled_Start_Date__c = System.now().addDays(-8);
    change0.HD_Change_Status__c = 'AUTHORIZED';
    change0.CR_Approval_Status__c = 'AUTHORIZED';

    insert change0;
    change0 = [select HD_Change_Status__c, ID from BMCServiceDesk__Change_Request__c where ID = :change0.Id ][0];
    change0.HD_Change_Status__c = 'IN PROGRESS';
    update change0;

    change0.HD_Change_Status__c = 'COMPLETED';
    update change0;



    BMCServiceDesk__Change_Request__c change1 = HD_ChangeRequestTestDataFactory.getchange();
    change1.BMCServiceDesk__Scheduled_End_Date__c  = System.now().addDays(-9);
    change1.BMCServiceDesk__Scheduled_Start_Date__c = System.now().addDays(-10);
    change1.HD_Change_Status__c = 'AUTHORIZED';
    change1.CR_Approval_Status__c = 'AUTHORIZED';
    insert change1;
    change1 = [select HD_Change_Status__c, ID from BMCServiceDesk__Change_Request__c where ID = :change1.Id ][0];
    change1.HD_Change_Status__c = 'IN PROGRESS';
    update change1;

    change1.HD_Change_Status__c = 'COMPLETED';
    update change1;

    HD_ChangeReqMgmt_class.remindUnclosed();

  }

  @isTest
  static void  autoCloseTest() {
   
    BMCServiceDesk__Change_Request__c change = HD_ChangeRequestTestDataFactory.getchange();
    System.debug('Change in autoCloseTest: ' + change.Id + '-->' + change);
    change.BMCServiceDesk__Scheduled_End_Date__c  = System.now().addDays(-16);
    change.BMCServiceDesk__Scheduled_Start_Date__c = System.now().addDays(-17);

    change.HD_Change_Status__c = 'AUTHORIZED';
    change.CR_Approval_Status__c = 'AUTHORIZED';


    insert change;

    BMCServiceDesk__Change_Request__c change1 = [select HD_Change_Status__c, Change_Locked__c, ID from BMCServiceDesk__Change_Request__c where ID = :change.Id ][0];
    change1.HD_Change_Status__c = 'AUTO FAILED';
    change1.Change_Locked__c = true;


    update change1;


    BMCServiceDesk__Change_Request__c change2 = HD_ChangeRequestTestDataFactory.getchange();
    System.debug('Change2 in autoCloseTest: ' + change2.Id + '-->' + change2);
    change2.BMCServiceDesk__Scheduled_End_Date__c  = System.now().addDays(-17);
    change2.BMCServiceDesk__Scheduled_Start_Date__c = System.now().addDays(-17);
    change2.BMCServiceDesk__Review_Date__c = change2.BMCServiceDesk__Scheduled_End_Date__c.addDays(15);
    change2.HD_Change_Status__c = 'AUTHORIZED';
    change2.CR_Approval_Status__c = 'AUTHORIZED';


    insert change2;

    BMCServiceDesk__Change_Request__c change12 = [select HD_Change_Status__c, ID, Change_Locked__c from BMCServiceDesk__Change_Request__c where ID = :change2.Id ][0];
    change12.HD_Change_Status__c = 'AUTO FAILED';
    change12.Change_Locked__c = true;
    update change12;


    HD_ChangeReqMgmt_class.autoCLose();


    LIST<BMCServiceDesk__Change_Request__c> changelist = [select HD_Change_Status__c, Auto_Closed__c, ID from BMCServiceDesk__Change_Request__c where ID = :change1.Id  OR ID = :change12.Id];
    System.assertEquals(changelist[0].HD_Change_Status__c , 'CLOSED');
    System.assertEquals(changelist[0].Auto_Closed__c   , TRUE);
    System.assertEquals(changelist[1].HD_Change_Status__c , 'CLOSED');
    System.assertEquals(changelist[1].Auto_Closed__c   , TRUE);



  }


  @isTest
  static void  remindScheduledDateTest() {

    BMCServiceDesk__Change_Request__c change = HD_ChangeRequestTestDataFactory.getchange();
    change.BMCServiceDesk__Scheduled_End_Date__c  = System.now().addMinutes(17);
    change.BMCServiceDesk__Scheduled_Start_Date__c = System.now().addMinutes(16);

    change.HD_Change_Status__c = 'AUTHORIZED';
    change.CR_Approval_Status__c = 'AUTHORIZED';



    insert change;

    BMCServiceDesk__Change_Request__c change1 = [select HD_Change_Status__c, ID from BMCServiceDesk__Change_Request__c where ID = :change.Id ][0];
    change1.HD_Change_Status__c = 'AUTO FAILED';
    update change1;


    BMCServiceDesk__Change_Request__c change2 = HD_ChangeRequestTestDataFactory.getchange();
    change2.BMCServiceDesk__Scheduled_End_Date__c  = System.now().addDays(11);
    change2.BMCServiceDesk__Scheduled_Start_Date__c = System.now().addDays(10);

    change2.HD_Change_Status__c = 'AUTHORIZED';
    change2.CR_Approval_Status__c = 'AUTHORIZED';



    insert change2;

    BMCServiceDesk__Change_Request__c change12 = [select HD_Change_Status__c, ID from BMCServiceDesk__Change_Request__c where ID = :change2.Id ][0];
    change12.HD_Change_Status__c = 'AUTO FAILED';

   // update change12;

   

    HD_ChangeReqMgmt_class.remindScheduledDate();
   System.AssertEquals(change2.HD_Change_Status__c , 'AUTHORIZED');
  }


  @isTest
  static void  remindUnclosedTest() {

    BMCServiceDesk__Change_Request__c change = HD_ChangeRequestTestDataFactory.getchange();
    DateTime  dt1 = System.now().addDays(3);
    change.BMCServiceDesk__Scheduled_End_Date__c  = dt1.addHours(8);
    change.BMCServiceDesk__Scheduled_Start_Date__c = dt1.addHours(2);

    change.HD_Change_Status__c = 'AUTHORIZED';
    change.CR_Approval_Status__c = 'AUTHORIZED';



    insert change;

    change.HD_Change_Status__c = 'IN PROGRESS';
    update change;


    HD_ChangeReqMgmt_class.remindUnclosed();
    System.AssertEquals(change.HD_Change_Status__c , 'IN PROGRESS');

  }


  @isTest
  static void SponsorApprvalTest() {
    BMCServiceDesk__Change_Request__c change = HD_ChangeRequestTestDataFactory.getchange();
    change.BMCServiceDesk__Scheduled_End_Date__c  = System.now().addMinutes(-1);
    change.BMCServiceDesk__Scheduled_Start_Date__c = System.now().addMinutes(-2);


    change.HD_Change_Status__c = 'OPENED';

    insert change;

    BMCServiceDesk__Change_Request__c change1 = [select HD_Change_Status__c, ID from BMCServiceDesk__Change_Request__c where ID = :change.Id ][0];
    change1.CR_Approval_Status__c = 'SPONSOR APPROVED';
    try {
      update change1;
    } catch (Exception e) {
      Boolean ismsg =  (e.getMessage().contains('Sponsor should approve the Change Request')) ? true : false;
      System.AssertEquals(ismsg, true);
    }

  }

  //added by pranav
  @isTest
  static void validateSchedulestartDateSponsorApprTest() {
    BMCServiceDesk__Change_Request__c change = HD_ChangeRequestTestDataFactory.getchange();
    change.BMCServiceDesk__Scheduled_End_Date__c  = System.now().addMinutes(-1);
    change.BMCServiceDesk__Scheduled_Start_Date__c = System.now().addMinutes(-2);

    HD_CMR_SETTINGS__c SETTING_TESTMODE = HD_CMR_SETTINGS__c.getInstance('Test_Mode');
    SETTING_TESTMODE.value__C = 'FALSE';
    update SETTING_TESTMODE;

    change.HD_Change_Status__c = 'OPENED';
    change.CR_Approval_Status__c = 'Approval Requested';
    insert change;
    System.debug('SPONSOR APPROVED ' + change.CR_Approval_Status__c);
    BMCServiceDesk__Change_Request__c change1 = [select HD_Change_Status__c, ID, CR_Approval_Status__c from BMCServiceDesk__Change_Request__c where ID = :change.Id ][0];
    change1.CR_Approval_Status__c = 'SPONSOR APPROVED';
    try {

      update change1;
      System.debug('SPONSOR APPROVED ' + change1.CR_Approval_Status__c);

    } catch (Exception e) {
      Boolean ismsg =  (e.getMessage().contains('Sponsor should approve the Change Request')) ? true : false;
      System.AssertEquals(ismsg, true);
    }

  }



}