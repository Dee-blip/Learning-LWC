@isTest
private class PLM_SendTaskNotificationTriggerTestClass {

    private static User CreateUser(String pUsrAlias, String pProfile, String pRole)
    {
        Profile pr = [select Id from Profile where Name=:pProfile][0];
        UserRole role = [select Id, Name from UserRole where Name=:pRole][0];
        User newUser = new User(alias = pUsrAlias, email=pUsrAlias+'@akamai.com',emailencodingkey='UTF-8', lastname='NewOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username=pUsrAlias+'__new_user@akamai.com',profileid = pr.Id, UserRoleId = role.Id );
        return newUser;     
    }
    
  /*      private static PACE_Concept__c CreatePACEConcept(String name, String conceptType,User productManager1, User generalUser1,Product_Line__c plc1)
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
    //program.Concept__c = concept1.Id;
    //program.Concept_Exception_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    //program.Concept_PRB_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
   /* program.Definition_Actual_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
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
   /* program.Launch_Actual_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    program.Launch_Actual_Start_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    program.Launch_Phase_Contract_Tolerance_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    //program.Launch_Exception_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    program.Launch_Planned_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    program.Launch_Planned_Start_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));*/
    program.Product_Manager__c = productManager1.Id;
    program.Program_Manager__c = productManager1.Id;
    program.Program_Type__c = 'New Product';
  //  program.Target_Definition_Commit_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
  //  program.Target_Development_Commit_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
  //  program.Target_Launch_Commit_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    program.Version__c = '1.0';

    return program;


  }

    private static PLM_EmailBodyBean createEmailObject(String[] toAddress, String[] ccAddresses){
        
        PLM_EmailBodyBean emailContent = new PLM_EmailBodyBean();

        emailContent.assignee = null;
        emailContent.launchItemName = 'DSL express';
        emailContent.launchItemLink = 'http://akamai.com/plmdev';
        emailContent.taskName =  'Upload design documents';
        emailContent.createDate = Datetime.now();
        emailContent.dueByDate = Date.today();
        emailContent.assignedFrom = 'Bala';
        emailContent.link = 'http://akamai.com';
        emailContent.toAddress = toAddress;
        emailContent.ccAddresses = ccAddresses;
         
        return emailContent;           
    }

 /*
    testmethod static void sendEmail_Single_PositiveTest(){
        
        String[] toAddress = new String[]{'testmail111@akamai.com'};
        String[] ccAddress = new String[]{'testmail111@akamai.com'};
        String subject = 'Test Mail';
        String messageBody = '<p>Simple mail</p>';
        
        
        Test.startTest();
        PLM_SendTaskNotificationTriggerClass.sendEmail(createEmailObject(toAddress, ccAddress), subject, messageBody);
        Test.stopTest();
        
        system.assert(true);
    }
  */    
    testmethod static void prepareEmailForNotifyingTaskAssignmentDate_Single_PositiveTest(){
        
        String[] toAddress = new String[]{'testmail111@akamai.com'};
        String[] ccAddress = new String[]{'testmail111@akamai.com'};
        String subject = 'Test Mail';
        String messageBody = '<p>Simple mail</p>';
        
        PLM_SendTaskNotificationTriggerClass.prepareEmailForNotifyingTaskAssignmentDate(createEmailObject(toAddress, ccAddress),false);
        
        
    }
    
    testmethod static void prepareEmailForSendingReminderBeforeDueDate_Single_PositiveTest(){
        
        String[] toAddress = new String[]{'testmail111@akamai.com'};
        String[] ccAddress = new String[]{'testmail111@akamai.com'};
        String subject = 'Test Mail';
        String messageBody = '<p>Simple mail</p>';
        
        PLM_SendTaskNotificationTriggerClass.prepareEmailForSendingReminderBeforeDueDate(createEmailObject(toAddress, ccAddress));
        
    }
    
    testmethod static void prepareEmailForSendingOverdueReminder_Single_PositiveTest(){
        
        
        String[] toAddress = new String[]{'testmail111@akamai.com'};
        String[] ccAddress = new String[]{'testmail111@akamai.com'};
        String subject = 'Test Mail';
        String messageBody = '<p>Simple mail</p>';
        
        PLM_SendTaskNotificationTriggerClass.prepareEmailForSendingOverdueReminder(createEmailObject(toAddress, ccAddress));
        
    }
    
        testmethod static void testPrepareNotificationList_Single_Positive(){
            
                    User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        
        System.runAs ( thisUser ) {
         User user = CreateUser('TST_USR0', 'Sales Operations', 'Sales Operations');
            insert user;  
            PLM_GlobalTeamGeneric.createGlobalTeam();                  
              
               User productManager = CreateUser('pr_Mg11', 'Product Operations', 'Worldwide');
        insert productManager;
    
        User generalUser = CreateUser('TS_US11', 'Sales Operations', 'Sales Operations');
        insert generalUser;
        
        Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line');
        insert plc;
    
     //   PACE_Concept__c concept = CreatePACEConcept('ipv81','New Product',productManager,generalUser,plc);
       // insert concept;
    
        PACE_Program__c ppc = CreatePACEProgram('ipv81',productManager, generalUser);
        insert ppc;
        
              
                    Launch_Item__c lic = new Launch_Item__c();
                    lic.Name = 'Launch item';
                    lic.OwnerId = user.Id;
                    lic.Product_Manager__c = user.Id;
                    lic.Division__c='Media';
                    lic.Program__c=ppc.Id;
                    insert lic;
                    
                    lic.Name = 'Launch item new';
                    update lic;

                    PLM_Task_Notification_User__c ptnu = new PLM_Task_Notification_User__c();
                    ptnu.User__c = user.Id;
                    ptnu.Launch_Item__c = lic.Id;
                    insert ptnu;
        
                    
                    Task t = new Task();
                    t.OwnerId = user.Id;
                    t.whatId = lic.Id;
                    insert t;
                    
                    //String[] ccAddresses = PLM_SendTaskNotificationTriggerClass.prepareNotificationList(t); 
                    
                    }
    }

    
    
        testmethod static void prepareEmailForSendingTaskCompletion_Single_PositiveTest(){
        
        String[] toAddress = new String[]{'testmail111@akamai.com'};
        String[] ccAddress = new String[]{'testmail111@akamai.com'};
        String subject = 'Test Mail';
        String messageBody = '<p>Simple mail</p>';
        
        PLM_SendTaskNotificationTriggerClass.prepareEmailForSendingTaskCompletion(createEmailObject(toAddress, ccAddress),'');
        
    }
    
    
    testmethod static void updateTaskDueDate_SinglePositiveTest(){
        
        User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        
        System.runAs ( thisUser ) {
         User user = CreateUser('TST_USR1', 'Sales Operations', 'Sales Operations');
            insert user;
            PLM_GlobalTeamGeneric.createGlobalTeam();
            
             User productManager = CreateUser('pr_Mg22', 'Product Operations', 'Worldwide');
        insert productManager;
    
        User generalUser = CreateUser('TS_US22', 'Sales Operations', 'Sales Operations');
        insert generalUser;
        
        Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line');
    insert plc;
    
   //     PACE_Concept__c concept = CreatePACEConcept('ipv81','New Product',productManager,generalUser,plc);
    //    insert concept;
    
        PACE_Program__c ppc = CreatePACEProgram('ipv81',productManager, generalUser);
        insert ppc;
        
                    Launch_Item__c lic = new Launch_Item__c();
                    lic.Name = 'Launch item';
                    lic.OwnerId = user.Id;
                    lic.Product_Manager__c = user.Id;
                    lic.Division__c='Media';
                    lic.Program__c=ppc.Id;
                    insert lic;
        
        Task t = PLM_LaunchItemClass.CreateTask(user.Id, 'Test task', lic.Id, Date.today());
        insert t;
        


        
        PLM_CastIronClass.firstRun = true;
        update t;
            }
    }
    
    
        
    testmethod static void sendReminderPriorToDueDate_SinglePositiveTest(){
        
                User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        
        System.runAs ( thisUser ) {
         User user = CreateUser('TST_USR3', 'Sales Operations', 'Sales Operations');
            insert user;
            PLM_GlobalTeamGeneric.createGlobalTeam();
            
             User productManager = CreateUser('pr_Mg33', 'Product Operations', 'Worldwide');
        insert productManager;
    
        User generalUser = CreateUser('TS_US33', 'Sales Operations', 'Sales Operations');
        insert generalUser;
        
        Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line');
    insert plc;
    
      //  PACE_Concept__c concept = CreatePACEConcept('ipv81','New Product',productManager,generalUser,plc);
       // insert concept;
    
        PACE_Program__c ppc = CreatePACEProgram('ipv81',productManager, generalUser);
        insert ppc;
        
        
                    Launch_Item__c lic = new Launch_Item__c();
                    lic.Name = 'Launch item';
                    lic.OwnerId = user.Id;
                    lic.Product_Manager__c = user.Id;
                    lic.Division__c='Media';
                    lic.Program__c=ppc.Id;
                    insert lic;
        
        Task t = PLM_LaunchItemClass.CreateTask(user.Id, 'Test task', lic.Id, (Date.today()+2));
        insert t;

        t.Associated_AKAM_Campaign_ID__c = 'CLEAN';
        PLM_CastIronClass.firstRun = true;
        update t;
        }
            
    }
    
    
            
    testmethod static void sendReminderAfterToDueDate_SinglePositiveTest(){
        
                User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        
        System.runAs ( thisUser ) {
         User user = CreateUser('TST_USR5', 'Sales Operations', 'Sales Operations');
            insert user; 
            PLM_GlobalTeamGeneric.createGlobalTeam();       
            
             User productManager = CreateUser('pr_Mg44', 'Product Operations', 'Worldwide');
        insert productManager;
    
        User generalUser = CreateUser('TS_US44', 'Sales Operations', 'Sales Operations');
        insert generalUser;
        
        Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line');
    insert plc;
    
    //    PACE_Concept__c concept = CreatePACEConcept('ipv81','New Product',productManager,generalUser,plc);
    //    insert concept;
    
        PACE_Program__c ppc = CreatePACEProgram('ipv81',productManager, generalUser);
        insert ppc;
                    Launch_Item__c lic = new Launch_Item__c();
                    lic.Name = 'Launch item';
                    lic.OwnerId = user.Id;
                    lic.Product_Manager__c = user.Id;
                    lic.Division__c='Media';
                    lic.Program__c=ppc.Id;
                    insert lic;
        
        Task t = PLM_LaunchItemClass.CreateTask(user.Id, 'Test task', lic.Id, Date.today());
        insert t;
        

        t.Associated_AKAM_Contact_ID__c = 'CLEAN';
        PLM_CastIronClass.firstRun = true;
        update t;
        
        }
        
    }
    
                
    testmethod static void sendNotificationOnTaskCompletion_SinglePositiveTest(){
        
                User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        
        System.runAs ( thisUser ) {
         User user = CreateUser('TST_USR7', 'Sales Operations', 'Sales Operations');
            insert user; 
            PLM_GlobalTeamGeneric.createGlobalTeam();   
            
             User productManager = CreateUser('pr_Mg55', 'Product Operations', 'Worldwide');
        insert productManager;
    
        User generalUser = CreateUser('TS_US55', 'Sales Operations', 'Sales Operations');
        insert generalUser;
        
        Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line');
    insert plc;
    
     //   PACE_Concept__c concept = CreatePACEConcept('ipv81','New Product',productManager,generalUser,plc);
      //  insert concept;
    
        PACE_Program__c ppc = CreatePACEProgram('ipv81',productManager, generalUser);
        insert ppc;
        
                    Launch_Item__c lic = new Launch_Item__c();
                    lic.Name = 'Launch item';
                    lic.OwnerId = user.Id;
                    lic.Product_Manager__c = user.Id;
                    lic.Division__c='Media';
                    lic.Program__c=ppc.Id;
                    insert lic;
        
        /*Task t = PLM_LaunchItemClass.CreateTask(user.Id, 'Test task', lic.Id, Date.today());
        insert t;
        
            
    
        t.Status = 'Completed';
        PLM_CastIronClass.firstRun = true;
        update t;
        
        t.ActivityDate = system.today();
        PLM_CastIronClass.firstRun = true;
        update t;*/
        
        }
    }
    
    static void sendNotificationOnTaskCompletion_BulkPositiveTest(){
        
                User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        
        System.runAs ( thisUser ) {
        User user = CreateUser('TST_USR9', 'Sales Operations', 'Sales Operations');
            insert user;   
            PLM_GlobalTeamGeneric.createGlobalTeam(); 
            
             User productManager = CreateUser('pr_Mg66', 'Product Operations', 'Worldwide');
        insert productManager;
    
        User generalUser = CreateUser('TS_US66', 'Sales Operations', 'Sales Operations');
        insert generalUser;
        
        Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line');
    insert plc;
    
     //   PACE_Concept__c concept = CreatePACEConcept('ipv81','New Product',productManager,generalUser,plc);
      //  insert concept;
    
        PACE_Program__c ppc = CreatePACEProgram('ipv81',productManager, generalUser);
        insert ppc;
                
        List<Task> taskList = new List<Task>();
        
        Launch_Item__c lic = new Launch_Item__c();
        lic.Name = 'Launch item';
                    lic.OwnerId = user.Id;
                    lic.Product_Manager__c = user.Id;
                    lic.Division__c='Media';
                    lic.Program__c=ppc.Id;
                    insert lic;
        
        for(Integer i = 0; i < 100; i++){
            taskList.add(PLM_LaunchItemClass.CreateTask(user.Id, 'Test task '+ i, lic.Id, Date.today()));
        }
        
        insert taskList;
        
     
 
        
        Test.startTest();
        PLM_CastIronClass.firstRun = true;
        for(Task t:taskList){
            t.Status = 'Completed';
        }

        update taskList;
        Test.stopTest();
        }
        
    }
    
    testmethod static void sendNotificationForNonPLMTask(){
        
                User thisUser = [ select Id from User where Id = :UserInfo.getUserId() ];
        
        System.runAs ( thisUser ) {
         User user = CreateUser('TUSR11', 'Sales Operations', 'Sales Operations');
            insert user;    
        List<Task> taskList = new List<Task>();
        
    
        for(Integer i = 0; i < 100; i++){
            
            Task tsk = new Task();
            tsk.Subject = 'Test task '+ i;
            tsk.OwnerId = user.Id;
            taskList.add(tsk);
        }
        
        insert taskList;
        

        
        Test.startTest();
        for(Task t:taskList){
            t.Status = 'Completed';
        }
        PLM_CastIronClass.firstRun = true;
        update taskList;
        Test.stopTest();
        }
        
        
        
    }
    
    
}