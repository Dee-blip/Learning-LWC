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
public class PACE_LaunchItemTestClass {


    private static User CreateUser(String pUsrAlias, String pProfile, String pRole) {
        Profile pr = [select Id from Profile where Name =: pProfile][0];
        UserRole role = [select Id, Name from UserRole where Name =: pRole][0];
        User newUser = new User(alias = pUsrAlias, email = pUsrAlias + '@akamai.com', emailencodingkey = 'UTF-8', lastname = 'NewOwner', languagelocalekey = 'en_US', localesidkey = 'en_US', timezonesidkey = 'America/Los_Angeles', username = pUsrAlias + '@akamai.com', profileid = pr.Id, UserRoleId = null);
        return newUser;
    }

    /*     private static PACE_Concept__c CreatePACEConcept(String name, String conceptType,User productManager, User generalUser,Product_Line__c plc){

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
        //program.Definition_Actual_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        //program.Definition_Actual_Start_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        /*  program.Definition_Phase_Contract_Tolerance_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
          //program.Definition_Exception_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
          //program.Definition_Planned_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
          //program.Definition_Planned_Start_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
          //program.Definition_PRB_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
          //program.Development_Actual_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
          //program.Development_Actual_Start_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
          program.Dev_Phase_Contract_Tolerance_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
          //program.Development_Exception_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
          //program.Development_Planned_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
          //program.Development_Planned_Start_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
          //program.Development_PRB_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));*/
        program.Division__c = 'Media';
        //program.Launch_Actual_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        //program.Launch_Actual_Start_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        /*  program.Launch_Phase_Contract_Tolerance_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
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
        //  program.Target_Launch_Commit_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
        program.Version__c = '1.0';

        return program;


    }

    private static Product_Line__c createProductLine() {
        Product_Line__c plc = new Product_Line__c();
        plc.Name = 'Test Prouduct Line';

        return plc;
    }

    //***** Test methods ************

    testmethod static void Initialize_ProgramForCatalogUpdate_positivetest() {

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

            String url = PACE_LaunchItem.Initialize_ProgramForCatalogUpdate(productManager.Id, productManager.Name, plc.Name, plc.Id, 'Test Division', ppc.Id, ppc.Name);


            system.assert(url != null);

            Test.stopTest();

        }
    }
    //***** Test methods ************

    testmethod static void updateProgramField_positivetest() {

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

            Launch_Item__c li = new Launch_Item__c();
            li.Product_Manager__c = testUser.Id;
            li.Name = 'test_launch_item';
            li.Product_Line_pickList__c = plc.Id;
            li.Division__c = 'Media';
            li.Program__c = ppc.Id;
            insert li;

            Launch_Item__c li2 = new Launch_Item__c();
            li2.Product_Manager__c = testUser.Id;
            li2.Name = 'test_launch_item2';
            li2.Product_Line_pickList__c = plc.Id;
            li2.Division__c = 'Media';
            li2.Program__c = ppc.Id;
            insert li2;

            Test.startTest();

            List < Launch_Item__c > liList = new List < Launch_Item__c > ();
            liList.add(li);
            liList.add(li2);
            PACE_LaunchItem.updateProgramField(liList);




            Test.stopTest();

        }

    }

}