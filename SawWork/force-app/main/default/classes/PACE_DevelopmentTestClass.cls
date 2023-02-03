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
@isTest
private class PACE_DevelopmentTestClass {

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
        /*program.Definition_Actual_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
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
        /*program.Launch_Actual_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
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
        /*program.Target_Definition_Commit_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        program.Target_Development_Commit_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        program.Target_Launch_Commit_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));*/
        program.Version__c = '1.0';

        return program;


    }

    private static PACE_Phase__c CreatePACEPhase(PACE_Program__c program) {
        PACE_Phase__c phase = new PACE_Phase__c();

        //phase.Actual_Start_Date__c=Date.today().addDays(Integer.valueOf(Math.random()*100));
        //phase.Actual_End_Date__c=Date.today().addDays(Integer.valueOf(Math.random()*100));
        // phase.Phase_Name__c='New Phase';
        phase.PACE_Program__c = program.Id;
        phase.Phase_Commit_Date__c = Date.today().addDays(Integer.valueOf(Math.random() * 100));
        phase.Phase_Contract_Tolerance_Date__c = Date.today().addDays(Integer.valueOf(Math.random() * 100));
        //phase.Planned_Start_Date__c=Date.today().addDays(Integer.valueOf(Math.random()*100));
        //phase.Planned_End_Date__c=Date.today().addDays(Integer.valueOf(Math.random()*100));
        phase.Target_Phase_Commit_Date__c = Date.today().addDays(Integer.valueOf(Math.random() * 100));


        return phase;
    }


    testmethod static void getDevelopmentList_Single_PositiveTest() {

        User productManager = CreateUser('pm1', 'Product Operations', 'Worldwide');
        insert productManager;

        User generalUser = CreateUser('pm2', 'Sales Operations', 'Sales Operations');
        insert generalUser;

        User testUser = CreateUser('pm3', 'Sales Operations', 'Sales Operations');
        insert testUser;

        System.RunAs(testUser) {
            Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line');
            insert plc;
            //  PACE_Concept__c concept = CreatePACEConcept('ipv81','New Product',productManager,generalUser,plc);
            //  insert concept;
            PACE_Program__c ppc = CreatePACEProgram('ipv81', productManager, generalUser);
            insert ppc;
            PACE_Phase__c p1 = CreatePACEPhase(ppc);
            List < PACE_Phase__c > phases = new List < PACE_Phase__c > {};
            phases.add(p1);
            Test.startTest();
            List < PACE_Phase__c > phase = PACE_Development.getDevelopmentList(phases);
            for (PACE_Phase__c pphase: phase) {

                Boolean result = 'PACE_Development'.equals(pphase.RecordType.Name);
                System.assertEquals(result, true);

            }

            Test.stopTest();
        }

    }

    testmethod static void initialize_Single_PositiveTest() {

        User productManager = CreateUser('pm4', 'Product Operations', 'Worldwide');
        insert productManager;

        User generalUser = CreateUser('pm5', 'Sales Operations', 'Sales Operations');
        insert generalUser;

        User testUser = CreateUser('pm6', 'Sales Operations', 'Sales Operations');
        insert testUser;

        System.RunAs(testUser) {
            Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line');
            insert plc;
            // PACE_Concept__c concept = CreatePACEConcept('ipv81','New Product',productManager,generalUser,plc);
            // insert concept;
            PACE_Program__c ppc = CreatePACEProgram('ipv81', productManager, generalUser);
            insert ppc;
            //PACE_Phase__c phase=CreatePACEPhase(ppc);
            Test.startTest();
            PACE_Phase__c pphase = PACE_Development.initialize(ppc);
            //System.AssertEquals(pphase.Actual_End_Date__c,ppc.Development_Actual_End_Date__c);
            System.AssertEquals(pphase.PACE_Program__c, ppc.Id);

            Test.stopTest();
        }
    }

    testmethod static void initialize_Multiple_PositiveTest() {


        User productManager = CreateUser('pm7', 'Product Operations', 'Worldwide');
        insert productManager;

        User generalUser = CreateUser('pm8', 'Sales Operations', 'Sales Operations');
        insert generalUser;

        User testUser = CreateUser('pm9', 'Sales Operations', 'Sales Operations');
        insert testUser;
        System.RunAs(testUser) {
            Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line');
            insert plc;
            //PACE_Concept__c concept = CreatePACEConcept('ipv81','New Product',productManager,generalUser,plc);
            //insert concept;
            List < PACE_Program__c > programs = new List < PACE_Program__c > {};
            for (Integer i = 0; i < 100; i++) {

                PACE_Program__c ppc = CreatePACEProgram('ipv81' + i, productManager, generalUser);
                programs.add(ppc);

            }
            Test.startTest();

            for (PACE_Program__c ppc: programs) {
                PACE_Phase__c pphase = PACE_Development.initialize(ppc);

                //System.AssertEquals(pphase.Actual_End_Date__c,ppc.Development_Actual_End_Date__c);
                System.AssertEquals(pphase.PACE_Program__c, ppc.Id);

            }
            Test.stopTest();
        }
    }

    testmethod static void setValuesForUpdate_Single_PositiveTest() {

        User productManager = CreateUser('pm10', 'Product Operations', 'Worldwide');
        insert productManager;

        User generalUser = CreateUser('pm11', 'Sales Operations', 'Sales Operations');
        insert generalUser;

        User testUser = CreateUser('pm12', 'Sales Operations', 'Sales Operations');
        insert testUser;
        System.RunAs(testUser) {
            Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line');
            insert plc;
            // PACE_Concept__c concept = CreatePACEConcept('ipv81','New Product',productManager,generalUser,plc);
            // insert concept;
            PACE_Program__c ppc = CreatePACEProgram('ipv81', productManager, generalUser);
            insert ppc;

            Test.startTest();
            PACE_Phase__c pphase = CreatePACEPhase(ppc);
            PACE_Phase__c updated_phase = PACE_Development.setValuesForUpdate(pphase.Id, ppc);
            System.AssertEquals(pphase.Id, updated_phase.Id);
            //System.AssertEquals(updated_phase.Actual_End_Date__c,ppc.Development_Actual_End_Date__c);
            Test.stopTest();
        }
    }

    testmethod static void setValuesForUpdate_Multiple_PositiveTest() {

        User productManager = CreateUser('pm13', 'Product Operations', 'Worldwide');
        insert productManager;

        User generalUser = CreateUser('pm14', 'Sales Operations', 'Sales Operations');
        insert generalUser;
        User testUser = CreateUser('pm15', 'Sales Operations', 'Sales Operations');
        insert testUser;
        System.RunAs(testUser) {
            Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line');
            insert plc;
            // PACE_Concept__c concept = CreatePACEConcept('ipv81','New Product',productManager,generalUser,plc);
            // insert concept;
            PACE_Program__c ppc = CreatePACEProgram('ipv81', productManager, generalUser);
            insert ppc;
            List < PACE_Phase__c > phases = new List < PACE_Phase__c > {};
            for (Integer i = 0; i < 100; i++) {

                PACE_Phase__c Phase = CreatePACEPhase(ppc);
                phases.add(phase);

            }
            Test.startTest();

            for (PACE_Phase__c pphase: phases) {
                PACE_Phase__c updated_phase = PACE_Development.setValuesForUpdate(pphase.Id, ppc);
                System.AssertEquals(pphase.Id, updated_phase.Id);
                //System.AssertEquals(updated_phase.Actual_End_Date__c,ppc.Development_Actual_End_Date__c);

            }
            Test.stopTest();
        }
    }

    testmethod static void initializeDefinitionSteps_Single_PositiveTest() {

        User productManager = CreateUser('pm16', 'Product Operations', 'Worldwide');
        insert productManager;

        User generalUser = CreateUser('pm17', 'Sales Operations', 'Sales Operations');
        insert generalUser;

        User testUser = CreateUser('pm18', 'Sales Operations', 'Sales Operations');
        insert testUser;
        System.RunAs(testUser) {
            Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line');
            insert plc;
            // PACE_Concept__c concept = CreatePACEConcept('ipv81','New Product',productManager,generalUser,plc);
            // insert concept;
            PACE_Program__c ppc = CreatePACEProgram('ipv81', productManager, generalUser);
            insert ppc;
            PACE_Phase__c phase = CreatePACEPhase(ppc);


            List < PACE_StepDefinition__c > refList = [SELECT Name, Position__c from PACE_StepDefinition__c where Phase_Name__c = 'Development'
                order by Position__c
            ];
            Test.startTest();
            List < PACE_Step__c > definitionSteps = PACE_Development.initializeDevelopmentSteps(phase);
            System.AssertEquals(definitionSteps.size(), refList.size());

            //PACE_StepDefinition__c psdc= refList.get(0);
            //PACE_Step__c psc=definitionSteps.get(0);
            // System.AssertEquals(psc.Name,'3.1 '+psdc.Name);


            Test.stopTest();
        }
    }

    testmethod static void initializeDefinitionStepsOverrided_Single_PositiveTest() {

        User productManager = CreateUser('pm19', 'Product Operations', 'Worldwide');
        insert productManager;

        User generalUser = CreateUser('pm20', 'Sales Operations', 'Sales Operations');
        insert generalUser;

        User testUser = CreateUser('pm21', 'Sales Operations', 'Sales Operations');
        insert testUser;
        System.RunAs(testUser) {
            Product_Line__c plc = new Product_Line__c(Name = 'Test Product Line');
            insert plc;
            //  PACE_Concept__c concept = CreatePACEConcept('ipv81','New Product',productManager,generalUser,plc);
            //  insert concept;
            PACE_Program__c ppc = CreatePACEProgram('ipv81', productManager, generalUser);
            insert ppc;
            PACE_Phase__c phase = CreatePACEPhase(ppc);
            List < PACE_StepDefinition__c > stepdef = new List < PACE_StepDefinition__c > {};
            PACE_StepDefinition__c psd = new PACE_StepDefinition__c();
            psd.Phase_Name__c = 'First';
            stepdef.add(psd);
            psd.Position__c = 2;

            Test.startTest();
            List < PACE_Step__c > definitionSteps = PACE_Development.initializeDevelopmentSteps(phase, stepdef);

            System.AssertEquals(definitionSteps.size(), stepdef.size());
            PACE_Step__c test_step = definitionSteps.get(0);
            System.AssertEquals(test_step.Position__c, 2);

            Test.stopTest();
        }
    }
}