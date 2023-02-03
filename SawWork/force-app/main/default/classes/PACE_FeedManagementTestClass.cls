@isTest
private class PACE_FeedManagementTestClass {

    private static User CreateUser(String pUsrAlias, String pProfile, String pRole) {
        Profile pr = [select Id from Profile where Name =: pProfile][0];
        UserRole role = [select Id, Name from UserRole where Name =: pRole][0];
        User newUser = new User(alias = pUsrAlias, email = pUsrAlias + '@akamai.com', emailencodingkey = 'UTF-8', lastname = 'NewOwner', languagelocalekey = 'en_US', localesidkey = 'en_US', timezonesidkey = 'America/Los_Angeles', username = pUsrAlias + '@akamai.com', profileid = pr.Id, UserRoleId = null);
        return newUser;
    }

    /* private static PACE_Concept__c CreatePACEConcept(String name, String conceptType,User productManager, User generalUser,Product_Line__c plc){

         PACE_Concept__c concept = new PACE_Concept__c();

         concept.Comments__c = 'Some comment which no-body reads, but knew you would!';
         concept.Concept_Commit_Date__c = Date.today();

         concept.Concept_Type__c = conceptType;
         concept.Division__c = 'Media';
         concept.Executive_Sponsor__c = generalUser.Id;
         concept.Planned_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
         concept.Product_Line__c = plc.Id;
         concept.Product_Manager__c = generalUser.Id;
         concept.Program_Manager__c = generalUser.Id;
         concept.Name = name;

         return concept;

     }*/

    private static PACE_Program__c CreatePACEProgram(String name, User productManager, User generalUser) {

        PACE_Program__c program = new PACE_Program__c();
        //program.Additional_Detail__c = 
        // program.Concept__c = concept.Id;
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
        /*   program.Launch_Actual_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
           program.Launch_Actual_Start_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
           program.Launch_Phase_Contract_Tolerance_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
           //program.Launch_Exception_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
           program.Launch_Planned_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
           program.Launch_Planned_Start_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));*/
        program.Product_Manager__c = productManager.Id;
        program.Program_Manager__c = productManager.Id;
        program.Program_Type__c = 'New Product';
        program.Original_CC__c = Date.today();
        program.Planned_CC__c = Date.today();
        //  program.Target_Definition_Commit_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        //  program.Target_Development_Commit_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        //   program.Target_Launch_Commit_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        program.Version__c = '1.0';

        return program;


    }



    testmethod static void afterInsert_Single_PositiveTest() {


        User productManager = CreateUser('pm1', 'Product Operations', 'Worldwide');
        insert productManager;

        User generalUser = CreateUser('pm2', 'Sales Operations', 'Sales Operations');
        insert generalUser;


        User testUser = CreateUser('pm3', 'Sales Operations', 'Sales Operations');
        insert testUser;
        System.RunAs(testUser) {
            Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line');
            insert plc;

            // PACE_Concept__c concept = CreatePACEConcept('ipv81','New Product',productManager,generalUser,plc);
            // insert concept;

            PACE_Program__c ppc = CreatePACEProgram('ipv81', productManager, generalUser);
            insert ppc;

            Test.startTest();

            List < FeedItem > fiList = new List < FeedItem > ();


            for (PACE_Phase__c phase: [Select Id, Name From PACE_Phase__c where PACE_Program__c =: ppc.Id]) {
                FeedItem notification = new FeedItem();
                notification.type = 'TextPost';
                notification.ParentId = phase.Id;
                notification.Title = 'Some title ' + phase.Name;
                notification.Body = 'Some body';
                fiList.add(notification);

                notification = new FeedItem();
                notification.type = 'LinkPost';
                notification.ParentId = phase.Id;
                notification.Body = 'qwertyuiop';
                notification.LinkUrl = 'http://www.joy.com';
                fiList.add(notification);

            }

            insert fiList;


            Test.stopTest();
        }

    }




}