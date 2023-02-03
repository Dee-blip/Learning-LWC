@isTest
private class PLM_LaunchItemTestClass {

    private static User CreateUser(String pUsrAlias, String pProfile, String pRole)
    {
        Profile pr = [select Id from Profile where Name=:pProfile][0];
        UserRole role = [select Id, Name from UserRole where Name=:pRole][0];
        User newUser = new User(alias = pUsrAlias, email=pUsrAlias+'@akamai.com',emailencodingkey='UTF-8', lastname='NewOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username=pUsrAlias+'__new_user@akamai.com',profileid = pr.Id, UserRoleId = null );
        return newUser;     
    }
    
    
  /*  private static PACE_Concept__c CreatePACEConcept(String name, String conceptType,User productManager1, User generalUser1,Product_Line__c plc1)
  {

    //PACE_Concept__c 
    PACE_Concept__c concept = new PACE_Concept__c();

    concept.Comments__c = 'Some comment which no-body reads, but knew you would!';
    concept.Concept_Commit_Date__c = Date.today();

    concept.Concept_Type__c = conceptType;
    concept.Division__c = 'Media';
    concept.Executive_Sponsor__c = generalUser1.Id;
    concept.Planned_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    concept.Product_Line__c = plc1.Id;
    concept.Product_Manager__c = generalUser1.Id;
    concept.Program_Manager__c = generalUser1.Id;
    concept.Name = name;

    return concept;

  }*/
  
  private  static PACE_Program__c CreatePACEProgram(String name,User productManager1, User generalUser1){

    PACE_Program__c program = new PACE_Program__c();
    //program.Additional_Detail__c = 
  //  program.Concept__c = concept1.Id;
    //program.Concept_Exception_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    //program.Concept_PRB_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
  /*  program.Definition_Actual_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    program.Definition_Actual_Start_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    program.Definition_Phase_Contract_Tolerance_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    //program.Definition_Exception_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    program.Definition_Planned_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    program.Definition_Planned_Start_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    //program.Definition_PRB_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    program.Development_Actual_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    program.Development_Actual_Start_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    program.Dev_Phase_Contract_Tolerance_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    //program.Development_Exception_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    program.Development_Planned_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    program.Development_Planned_Start_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    //program.Development_PRB_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));*/
    program.Division__c = 'Media';
  /*  program.Launch_Actual_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    program.Launch_Actual_Start_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    program.Launch_Phase_Contract_Tolerance_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    //program.Launch_Exception_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    program.Launch_Planned_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    program.Launch_Planned_Start_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));*/
    program.Product_Manager__c = productManager1.Id;
    program.Program_Manager__c = productManager1.Id;
    program.Program_Type__c = 'New Product';
   // program.Target_Definition_Commit_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
   // program.Target_Development_Commit_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
   // program.Target_Launch_Commit_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    program.Version__c = '1.0';

    return program;


  }
    
    testmethod static void CreateTask_Single_PositiveTest(){

        Id pOwnerId = '00300000003T2PGAA0';
        String pSubject = 'Dummy subject';
        Id pWhatId = '00300000003T2PGQQQ';
        
        Test.startTest();
        Task tsk = PLM_LaunchItemClass.CreateTask(pOwnerId, pSubject, pWhatId, Date.today());
        
        Test.stopTest();
        
        system.assertEquals(tsk.Subject, pSubject);
        system.assertEquals(tsk.WhatId , pWhatId);
        system.assertEquals(tsk.OwnerId , pOwnerId);
            
    }
    
    
    testmethod static void CreateTask_Single_NegativeTest(){

        Id pOwnerId = '00300000003T2PGAA0';
        String pSubject = 'Dummy subject';
        Id pWhatId = '00300000003T2PGQQQ';
        
        Test.startTest();
        Task tsk = PLM_LaunchItemClass.CreateTask(pOwnerId, pSubject, pWhatId, Date.today());
        Test.stopTest();
        
        system.assertEquals(tsk.Subject, pSubject);
        system.assertEquals(tsk.WhatId , pWhatId);
        system.assertEquals(tsk.OwnerId , pOwnerId);
            
    }    
   
    testmethod static void CreateTaskList_Single_PositiveTest(){
        
        Id pUserID = '00300000003T2PGAA0'; 
        Id pLaunchItemId = '00300000003T2PGQQQ';
        
        Test.startTest();
        PLM_Task_Notification_User__c notify = PLM_LaunchItemClass.CreateTaskList(pUserID, pLaunchItemId);
        Test.stopTest();
        
        system.assertEquals(notify.Launch_Item__c , pLaunchItemId);
        system.assertEquals(notify.User__c , pUserID);

    }
    
    
    testmethod static void CreateLaunchItem_Single_Positive_TestCase(){
        
        User testUser = CreateUser('TST_USR', 'Sales Operations', 'Sales Operations');
        insert testUser;
        
        User productManager = CreateUser('pr_Mg77', 'Product Operations', 'Worldwide');
    insert productManager;
  
  /*  User generalUser = CreateUser('TS_US77', 'Sales Operations', 'Sales Operations');
    insert generalUser;*/
   
   
    
            
        Test.startTest();
        
        Product_Line__c plc = new Product_Line__c();
        plc.Name = 'Application Acceleration';
        insert plc;
        
    //    PACE_Concept__c concept = CreatePACEConcept('ipv81','New Product',productManager,generalUser,plc);
    //insert concept;
    
    PACE_Program__c ppc = CreatePACEProgram('ipv81',productManager, productManager);
    insert ppc;

        
        
        Product_Launch_RASCI_List__c plrl = new Product_Launch_RASCI_List__c();
        plrl.Product_Line__c = plc.Id;
        plrl.User__c = testUser.Id;
        insert plrl;
         
        PLM_LaunchItemClass.firstRun=true;
        PLM_LaunchItemApprovalGeneric.launchItemInsertFirstRunFlag=true;
        PLM_GlobalTeamGeneric.createGlobalTeam();
        
        
        Launch_Item__c li = new Launch_Item__c();
        li.Product_Manager__c = testUser.Id;
        li.Name = 'test_launch_item';       
        li.Product_Line_pickList__c = plc.Id;
        li.Division__c='Media';
        li.Program__c=ppc.Id;
        insert li;
        
        
        Test.stopTest();
        
      //  List<Task> taskList = [select Subject, WhatId, RecordTypeId,OwnerId from Task where WhatId = :li.Id];
      //  List<PLM_Task_Notification_User__c> notificationList = [select Launch_Item__c from PLM_Task_Notification_User__c where Launch_Item__c = :li.Id];
        
        //system.assert(taskList.size()!=0,taskList.size());
        //system.assert(notificationList.size()!=0,notificationList.size());
        
    }

    
   testmethod static void UpdateLaunchItem_Single_TestCase(){
        
        User testUser = CreateUser('TST_USR', 'Sales Operations', 'Sales Operations');
        insert testUser;
        
        PLM_GlobalTeamGeneric.createGlobalTeam();
       
       User productManager = CreateUser('pr_Mg88', 'Product Operations', 'Worldwide');
    insert productManager;
  
    User generalUser = CreateUser('TS_US88', 'Sales Operations', 'Sales Operations');
    insert generalUser;
   
    Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line');
    insert plc;
    
  //  PACE_Concept__c concept = CreatePACEConcept('ipv81','New Product',productManager,generalUser,plc);
  //  insert concept;
    
    PACE_Program__c ppc = CreatePACEProgram('ipv81',productManager, generalUser);
    insert ppc;
        
        Launch_Item__c li = new Launch_Item__c();
        li.Product_Manager__c = testUser.Id;
        li.Name = 'test_launch_item'; 
        li.Division__c='Media';   
        li.Program__c=ppc.Id;   
        insert li;
        
        PLU__c plu = new PLU__c();
        plu.Name = 'Mar-2011';
        plu.PLU_Date__c = Date.today();
        insert plu;
        
        PLM_LaunchItemClass.firstRun = true;
        Test.startTest();
        li.Phase_Status__c = 'Completed';
        //li.Archive__c = true;
        li.PLU__c = plu.Id; 
        update li;
        Test.stopTest();
        
        for(PLM_Task_Notification_User__c notificationUser: [Select p.User__c, p.SystemModstamp, p.Send_Email__c, p.Name, p.Launch_Item__c, p.LastModifiedDate, p.LastModifiedById, p.IsDeleted, p.Id, p.Group__c, p.CurrencyIsoCode, p.CreatedDate, p.CreatedById From PLM_Task_Notification_User__c p where p.Launch_Item__c = :li.Id]){
            
            system.debug(notificationUser.User__c + '\n'     +  notificationUser.SystemModstamp + '\n' +  notificationUser.Send_Email__c + '\n' +  notificationUser.Name + '\n' +  notificationUser.Launch_Item__c + '\n' +  notificationUser.LastModifiedDate + '\n' +  notificationUser.LastModifiedById + '\n' +  notificationUser.IsDeleted + '\n' +  notificationUser.Id + '\n' +  notificationUser.Group__c + '\n' +  notificationUser.CurrencyIsoCode + '\n' +  notificationUser.CreatedDate + '\n' +  notificationUser.CreatedById );           
            //system.assert(notificationUser.Send_Email__c);
            
        }
        
        
        
    } 
    
    
      testmethod static void UpdateLaunchItem_Single_Second_TestCase(){
        
        
        User testUser = CreateUser('TST_USR', 'Sales Operations', 'Sales Operations');
        insert testUser;
        
        
        PLM_LaunchItemClass.firstRun=true;
        PLM_LaunchItemApprovalGeneric.launchItemInsertFirstRunFlag=true;
        Launch_Item__c li = new Launch_Item__c();
        PLU__c plu_1 = new PLU__c();
        plu_1.Name = 'Mar-2011';
        plu_1.PLU_Date__c = Date.today();
        insert plu_1;
        
        PLM_GlobalTeamGeneric.createGlobalTeam();
        
        User productManager = CreateUser('pro123', 'Product Operations', 'Worldwide');
    insert productManager;
  
    User generalUser = CreateUser('TST_U12', 'Sales Operations', 'Sales Operations');
    insert generalUser;
   
    Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line');
    insert plc;
    
  //  PACE_Concept__c concept = CreatePACEConcept('ipv81','New Product',productManager,generalUser,plc);
  //  insert concept;
    
    PACE_Program__c ppc = CreatePACEProgram('ipv81',productManager, generalUser);
    insert ppc;
        
        li.Product_Manager__c = testUser.Id;
        li.Name = 'test_launch_item';      
        li.PLU__c = plu_1.Id; 
        li.Division__c='Media';
        li.Program__c=ppc.Id;
        insert li;
        
        li.Backend_Integration_Test_Dates__c = Date.today() + 1;
        li.Momentum_Activation_Date__c = Date.today() + 1;
        li.Launch_Readiness_Date__c = Date.today() + 1;
        li.Package_Design_Submission_Date__c = Date.today() + 1;
        
        PLU__c plu_2 = new PLU__c();
        plu_2.Name = 'Mar-2011';
        plu_2.PLU_Date__c = (Date.today() + 2);
        insert plu_2;
        
        PLM_LaunchItemClass.firstRun = true;
        Test.startTest();
        li.Phase_Status__c = 'Completed';
        //li.Archive__c = true;
        li.PLU__c = plu_2.Id; 
        li.Division__c='Media';
        update li;
        Test.stopTest();
        
        for(PLM_Task_Notification_User__c notificationUser: [Select p.User__c, p.SystemModstamp, p.Send_Email__c, p.Name, p.Launch_Item__c, p.LastModifiedDate, p.LastModifiedById, p.IsDeleted, p.Id, p.Group__c, p.CurrencyIsoCode, p.CreatedDate, p.CreatedById From PLM_Task_Notification_User__c p where p.Launch_Item__c = :li.Id]){
            
            system.debug(notificationUser.User__c + '\n'     +  notificationUser.SystemModstamp + '\n' +  notificationUser.Send_Email__c + '\n' +  notificationUser.Name + '\n' +  notificationUser.Launch_Item__c + '\n' +  notificationUser.LastModifiedDate + '\n' +  notificationUser.LastModifiedById + '\n' +  notificationUser.IsDeleted + '\n' +  notificationUser.Id + '\n' +  notificationUser.Group__c + '\n' +  notificationUser.CurrencyIsoCode + '\n' +  notificationUser.CreatedDate + '\n' +  notificationUser.CreatedById );           
            //system.assert(notificationUser.Send_Email__c);
            
        }
        
        
        
    } 
    
    
    
    testmethod static void testCreate_Task(){
        
             
        User testUser = CreateUser('TST_USR', 'Sales Operations', 'Sales Operations');
        insert testUser;
        PLM_GlobalTeamGeneric.createGlobalTeam();
        
        User productManager = CreateUser('pr_Mg99', 'Product Operations', 'Worldwide');
    insert productManager;
  
    User generalUser = CreateUser('TS_US99', 'Sales Operations', 'Sales Operations');
    insert generalUser;
   
    Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line');
    insert plc;
    
  //  PACE_Concept__c concept = CreatePACEConcept('ipv81','New Product',productManager,generalUser,plc);
  //  insert concept;
    
    PACE_Program__c ppc = CreatePACEProgram('ipv81',productManager, generalUser);
    insert ppc;
    
        Launch_Item__c li = new Launch_Item__c();
        li.Product_Manager__c = testUser.Id;
        li.Name = 'test_launch_item';
        li.Division__c='Media'; 
        li.Program__c=ppc.Id;      
        insert li;
        
        
        String url = PLM_LaunchItemClass.Create_Task(li.Id, 'PLM_Task');
        
        system.assert(url!=null);
        
        
        
        
        
        
    }
    
    testmethod static void CreateDistributionListTest(){
    
        User testUser = CreateUser('TST_USR', 'Sales Operations', 'Sales Operations');
        insert testUser;
        PLM_GlobalTeamGeneric.createGlobalTeam();
        
        User productManager = CreateUser('pr_Mg99', 'Product Operations', 'Worldwide');
        insert productManager;
  
        User generalUser = CreateUser('TS_US99', 'Sales Operations', 'Sales Operations');
        insert generalUser;
   
        Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line');
        insert plc;
    
        PACE_Program__c ppc = CreatePACEProgram('ipv81',productManager, generalUser);
        insert ppc;
    
        Launch_Item__c litest1 = new Launch_Item__c();
        litest1.Product_Manager__c = testUser.Id;
        litest1.Name = 'test_launch_item';
        litest1.Division__c='Media'; 
        litest1.Program__c=ppc.Id;      
        insert litest1;
        
        List<PLM_Task_Notification_User__c> pTNU = PLM_LaunchItemClass.CreateDistributionList(litest1.Id);
        
        
        
    }
    testmethod static void ResolveDateForTaskTest(){
        
        User testUser = CreateUser('TST_USR', 'Sales Operations', 'Sales Operations');
        insert testUser;
        PLM_GlobalTeamGeneric.createGlobalTeam();
        
        User productManager = CreateUser('pr_Mg99', 'Product Operations', 'Worldwide');
        insert productManager;
  
        User generalUser = CreateUser('TS_US99', 'Sales Operations', 'Sales Operations');
        insert generalUser;
   
        Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line');
        insert plc;
    
        PACE_Program__c ppc = CreatePACEProgram('ipv81',productManager, generalUser);
        insert ppc;
    
        Launch_Item__c litest1 = new Launch_Item__c();
        litest1.Product_Manager__c = testUser.Id;
        litest1.Name = 'test_launch_item';
        litest1.Division__c='Media'; 
        litest1.Program__c=ppc.Id;      
        insert litest1;
        
        Map<String, Date> milestoneMapTest = new Map<String, Date>();
        
        milestoneMapTest = PLM_LaunchItemClass.ResolveDateForTask(litest1.Id);
        
    }
    
    
      
    
    
    
}