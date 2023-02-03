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
public class PLM_PLUCalendarUpdateRuleTestClass {


    private static User CreateUser(String pUsrAlias, String pProfile, String pRole)
    {
        Profile pr = [select Id from Profile where Name=:pProfile][0];
        UserRole role = [select Id, Name from UserRole where Name=:pRole][0];
        User newUser = new User(alias = pUsrAlias, email=pUsrAlias+'@akamai.com',emailencodingkey='UTF-8', lastname='NewOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles',  username=pUsrAlias+'__new_user@akamai.com',profileid = pr.Id, UserRoleId = null );
        return newUser;     
    }
    
    
    
 /* private static PACE_Concept__c CreatePACEConcept(String name, String conceptType,User productManager1, User generalUser1,Product_Line__c plc1){

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
    //program.Development_PRB_Review_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100)); */
    program.Division__c = 'Media';
 /*   program.Launch_Actual_End_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
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
    //program.Target_Launch_Commit_Date__c = Date.today().addDays(Integer.valueOf(Math.random()*100));
    program.Version__c = '1.0';

    return program;


  }
  
   
    testmethod static void testPLUUpdateTestPositive(){
        
        PLU__c plu = new PLU__c();
        
        plu.Name = 'Mar - 2021';
        plu.System_Integration_Review_Date__c = Date.newinstance(2021,2,12); 
        plu.Backend_Integration_Test__c = Date.newinstance(2021,2,11); 
        plu.Package_Design_Submission_Date__c = Date.newinstance(2021,2,10);
        plu.Product_Launch_Update__c = Date.newinstance(2021,2,9);
        plu.Momentum_Activation__c = Date.newinstance(2021,2,8);
        plu.Launch_Readiness__c = Date.newinstance(2021,2,7);
        plu.PLU_Date__c = Date.newinstance(2021,2,6);
        
        
        insert plu;
        
        
        User testUser = CreateUser('TST89', 'Sales Operations', 'Sales Operations');
        insert testUser;
        PLM_GlobalTeamGeneric.createGlobalTeam();
        
        User productManager = CreateUser('pr_Mg11', 'Product Operations', 'Worldwide');
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
        li.PLU__c = plu.Id; 
        li.Division__c='Media'; 
        li.Program__c=ppc.Id;     
        insert li;
        
        for(Task task: [select t.ActivityDate,t.Subject from Task t where t.WhatId =:li.Id]){
            
            
            if( task.Subject.equals('Upload Scope Document') || task.Subject.equals('Upload Product Design Documents') ||
            task.Subject.equals('Upload Package Design Documents') || task.Subject.equals('Upload Go-To-Market Design Documents'))
            {
                System.assertEquals(task.ActivityDate, plu.Package_Design_Submission_Date__c);
                system.debug(task.ActivityDate );
                system.debug(plu.Package_Design_Submission_Date__c);
            }
            else if((task.Subject.equals('Setup Package Design Review Date')) || task.Subject.equals('Assign Readiness Date') ||
            task.Subject.equals('Post Prototype Order Forms') || task.Subject.equals('Setup System Integration Review Date') ||
            task.Subject.equals('Update Product Catalog Structure') || task.Subject.equals('Post Test Order Forms and Invoice Item Designs') ||
            task.Subject.equals('Complete Portal Provisioning'))
            {
                System.assertEquals(task.ActivityDate, plu.System_Integration_Review_Date__c);
            }
            else if(task.Subject.equals('Assign Backend Integration Completion Date'))
            {
                System.assertEquals(task.ActivityDate, plu.Backend_Integration_Test__c);
            }
            else if(task.Subject.equals('Upload Launch Checklist') || task.Subject.equals('Upload PLU Presentation'))
            {
                System.assertEquals(task.ActivityDate, plu.Product_Launch_Update__c);
            }
        }
        
        Test.startTest();
        PLM_CastIronClass.firstRun = true;
        
        plu.System_Integration_Review_Date__c = Date.newinstance(2021,3,12);
        plu.Backend_Integration_Test__c = Date.newinstance(2021,12,13); 
        plu.Package_Design_Submission_Date__c = Date.newinstance(2021,12,14);
        plu.Product_Launch_Update__c = Date.newinstance(2021,12,15);
        plu.Momentum_Activation__c = Date.newinstance(2021,12,16);
        plu.Launch_Readiness__c = Date.newinstance(2021,12,17);
        plu.PLU_Date__c = Date.newinstance(2021,12,18);
        
    
        update plu;
        
        for(Task task: [select t.ActivityDate,t.Subject from Task t where t.WhatId =:li.Id]){
            
            
            if( task.Subject.equals('Upload Scope Document') || task.Subject.equals('Upload Product Design Documents') ||
            task.Subject.equals('Upload Package Design Documents') || task.Subject.equals('Upload Go-To-Market Design Documents'))
            {
                //System.assertEquals(task.ActivityDate, plu.Package_Design_Submission_Date__c);
            }
            else if((task.Subject.equals('Setup Package Design Review Date')) || task.Subject.equals('Assign Readiness Date') ||
            task.Subject.equals('Post Prototype Order Forms') || task.Subject.equals('Setup System Integration Review Date') ||
            task.Subject.equals('Update Product Catalog Structure') || task.Subject.equals('Post Test Order Forms and Invoice Item Designs') ||
            task.Subject.equals('Complete Portal Provisioning'))
            {
               // System.assertEquals(task.ActivityDate, plu.System_Integration_Review_Date__c);
            }
            else if(task.Subject.equals('Assign Backend Integration Completion Date'))
            {
              //  System.assertEquals(task.ActivityDate, plu.Backend_Integration_Test__c);
            }
            else if(task.Subject.equals('Upload Launch Checklist') || task.Subject.equals('Upload PLU Presentation'))
            {
             //   System.assertEquals(task.ActivityDate, plu.Product_Launch_Update__c);
            }
        }       
        
        
        Test.stopTest();
        
    }
    
    

}