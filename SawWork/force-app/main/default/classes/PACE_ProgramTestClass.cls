@isTest 
public class PACE_ProgramTestClass {

    private static User CreateUser(String pUsrAlias, String pProfile, String pRole)
    {
        Profile pr = [select Id from Profile where Name=:pProfile][0];
        UserRole role = [select Id, Name from UserRole where Name=:pRole][0];
        User newUser = new User(alias = pUsrAlias, email=pUsrAlias+'@akamai.com',emailencodingkey='UTF-8', lastname='NewOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username= pUsrAlias + '@akamai.com',profileid = pr.Id, UserRoleId = null );
        return newUser;     
    }


    private static PACE_Program__c CreatePACEProgram(String name,User productManager, User generalUser){

        PACE_Program__c program = new PACE_Program__c();
      
        program.Division__c = 'Media';
    
        program.Product_Manager__c = productManager.Id;
        program.Program_Manager__c = productManager.Id;
        program.Program_Type__c = 'New Product';
        program.Original_CC__c = Date.today();
        program.Planned_CC__c = Date.today();
    
        program.Version__c = '1.0';

        return program;


    }

    //*************************************************************************************
    // Positive tests
    //*************************************************************************************
    
    testmethod static void afterInsert_Single_PositiveTest(){

        Integer requiredPhases = 4;

        User productManager = CreateUser('prodMgr', 'Product Operations', 'Worldwide');
        insert productManager;
    
        User generalUser = CreateUser('TST_USR', 'Sales Operations', 'Sales Operations');
        insert generalUser;

User testUser = CreateUser('TST_1234', 'Sales Operations', 'Sales Operations');
        insert testUser;
        System.RunAs(testUser){
        Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line');
        insert plc;
      //  PACE_Concept__c concept = CreatePACEConcept('ipv81','New Product',productManager,generalUser,plc);
      //  insert concept;

        Test.startTest();

        PACE_Program__c ppc = CreatePACEProgram('ipv81',productManager, generalUser);
        insert ppc;

        Integer phaseCount = [Select count() From PACE_Phase__c  where PACE_Program__c = :ppc.Id];          
        System.assertEquals(phaseCount,requiredPhases) ;
    
        Test.stopTest();
        }
    
    }



 


    testmethod static void afterInsert_Single_NegativeTest(){

        Integer requiredPhases = 6;

        User productManager = CreateUser('prodMgr', 'Product Operations', 'Worldwide');
        insert productManager;
    
        User generalUser = CreateUser('TST_USR', 'Sales Operations', 'Sales Operations');
        insert generalUser;

        User testUser = CreateUser('TST_1235', 'Sales Operations', 'Sales Operations');
        insert testUser;
        System.RunAs(testUser){
        Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line');
        insert plc;
        
    
        PACE_Program__c ppcTest1 = CreatePACEProgram('ipv81',productManager, generalUser);
        insert ppcTest1;

        Test.startTest();

    

    
        Integer phaseCount = [Select count() From PACE_Phase__c  where PACE_Program__c = :ppcTest1.Id];          
        System.assertNotEquals(phaseCount,requiredPhases) ;
    
        Test.stopTest();
        }
    
    }


    testmethod static void afterUpdate_Single_PositiveTest(){

        Integer requiredPhases = 3;

        User productManager = CreateUser('prodMgr', 'Product Operations', 'Worldwide');
        insert productManager;
    
        User generalUser = CreateUser('TST_USR', 'Sales Operations', 'Sales Operations');
        insert generalUser;
        

        User testUser = CreateUser('TST_1236', 'Sales Operations', 'Sales Operations');
        insert testUser;
        System.RunAs(testUser){
        Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line');
        insert plc;
       // PACE_Concept__c concept = CreatePACEConcept('ipv81','New Product',productManager,generalUser,plc);
       // insert concept;

        Test.startTest();

        PACE_Program__c ppc = CreatePACEProgram('ipv81',productManager, generalUser);
        insert ppc;
        
        PACE_Phase.programDateUpdate = false;
        PACE_Program.firstRun = true;
        
        ppc.Name = 'Some new name';
        update ppc;
        //String test=PACE_Program.Create_Program();
        System.assertNotEquals(NULL,PACE_Program.Create_Program());
        Test.stopTest();
        }
    
    }



}