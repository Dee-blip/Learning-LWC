/* ========================================================================
    Author: Sonia Sawhney
    Description: Test Class for PSA_SendWeelyRemindersForTimecards 
    Created Date : 10/04/2014
    Changes by: shprasan for CR 3231001 to reduce the running time in production
  Changes by: shprasan setting seeAlldata to true and creating only one project and timecard
  Changes by Sharath to resolve 101 soql query error
    ======================================================================== */

// changes by shprasan: SeeAllData = false   
//@isTest(seealldata=false)
@isTest(seealldata=false)
public class PSA_SendWeeklyRemindersForTimecards_Test
{   
    //Changes by Sharath: commenting the static block
    //changes by shprasan: Adding the static block to create custom setting
    static{
    //    utilTestClass.createCustomSettings();        
          testCreateData();
    }
    static PSA_TestUtility testUtil;
    static Account acct;
    static User usr;
    static Contact resource;
    static User usr1;
    static Contact resource1;
    static pse__Region__c reg;
    static pse__Practice__c pract;
    static pse__Schedule__c sched;
    static pse__Permission_Control__c pc;
    static pse__Proj__c proj;
    static pse__Project_Methodology__c  product;
    static pse__Milestone__c milestone;
    static pse__Assignment__c assign;
    static pse__Timecard_Header__c timecard;
    
    static void testCreateData()
    {
        testUtil = new PSA_TestUtility();
        acct = testUtil.newAccount(true);
        usr = testUtil.newUserSysAdmin(true); 
        resource = testUtil.newResource(true, acct.Id, usr.Id);
        usr1 = testUtil.newUserSysAdmin(true);  
        resource1 = testUtil.newResource(true, acct.Id, usr1.Id);  
        reg = testUtil.newRegionMaster(true); 
        pract = testUtil.newPracticeMaster(true);  
        sched = testUtil.newSchedule(true, System.today(), System.today().addDays(6));    
        pc = testUtil.newPermissionControl(true, usr.Id, reg.Id); 

        proj = testUtil.newProject(false,reg.id,pract.Id,true,'One-Time: Fixed Price', resource.Id, acct.Id);
        proj.Name = proj.Name + '1' ;
        proj.pse__Is_Billable__c = true;     
        proj.pse__Project_Manager__c = resource1.id;   
        insert proj;

        product = testUtil.newProjectProduct(true,proj.Id,'Test Proj Prod 1');                
        milestone = testUtil.newMilestone(true,proj.Id,100,System.today());
    }
    static testMethod void testSendEmails() 
    {
      //PSA_TestUtility testUtil = new PSA_TestUtility();
      ////Create Account,User & Contact
      //Account acct = testUtil.newAccount(true);  
      //User usr = testUtil.newUserSysAdmin(true);   
      //Contact resource = testUtil.newResource(true, acct.Id, usr.Id);
      
      ////Changes by shprasan: Creating another user and resource
      //User usr1 = testUtil.newUserSysAdmin(true);        
      //Contact resource1 = testUtil.newResource(true, acct.Id, usr1.Id);
      
      ////Create a new region
      //pse__Region__c reg = testUtil.newRegionMaster(true);
      ////Create Practice
      //pse__Practice__c pract = testUtil.newPracticeMaster(true);
      //Id practId = pract.ID;
      
      ////Start of changes by shprasan: 
      ////creating schedule and assignment
      //pse__Schedule__c sched = testUtil.newSchedule(true, System.today(), System.today().addDays(6));
      ////pse__Schedule__c sched1 = testUtil.newSchedule(true, System.today(), System.today().addDays(6));
      
      ////creating permission control
      //pse__Permission_Control__c pc = testUtil.newPermissionControl(true, usr.Id, reg.Id);
      ////end of changes by shprasan

      //list<pse__Proj__c> lstProjects = new list<pse__Proj__c>();
      
      //Create 200 Projects
      //Changes by shprasan:changing the number of projects created to 2 and making the projects billable
      
      //for(integer i=0;i<1;i++)
      //{
      //    pse__Proj__c proj = testUtil.newProject(false,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);
      //    proj.Name = proj.Name + '' + i;
      //    proj.pse__Is_Billable__c = true;
      //    lstProjects.add(proj);
      //}
      //insert lstProjects;
      
      //Create project product and milestone for each project
      //list<pse__Project_Methodology__c> lstProjectProducts = new list<pse__Project_Methodology__c>();
      //list<pse__Milestone__c> lstMilestones = new list<pse__Milestone__c>();
      //list<ID> lstAssignments = new list<ID>();

      ////changes by shprasan: Changing the number of pse__Project_Methodology__c and milestone created to 2
      //for(integer i=0;i<1;i++)
      //{
      //    pse__Project_Methodology__c  product = testUtil.newProjectProduct(false,lstProjects[i].Id,'Test Proj Prod '+i);
      //    lstProjectProducts.add(product);
      //    pse__Milestone__c milestone = testUtil.newMilestone(false,lstProjects[i].Id,100,System.today());
      //    lstMilestones.add(milestone);
      //}
      //insert lstProjectProducts;
      //insert lstMilestones;

      //Changes by shprasan: Creating assignments for the 2 projects
      //pse__Assignment__c assign;
      Test.StartTest();
      System.runAs(usr) 
      {
           assign = testUtil.newAssignment(true, proj.Id, resource.Id, sched.Id);
           //lstAssignments.add(assign.Id);
           //assign = testUtil.newAssignment(true, lstProjects[1].Id, resource.Id, sched1.Id);
           //lstAssignments.add(assign.Id);
            timecard = testUtil.newTimecardHeader(false, resource.Id, proj.Id, assign.Id, milestone.Id, System.today(), System.today().addDays(6));   
            timecard.pse__Billable__c = true;
            timecard.pse__Status__c = 'Saved';
            timecard.pse__Project_Methodology_Object__c = product.Id;
            timecard.pse__Milestone__c = milestone.Id;
            insert timecard;
      }    


      //Create timecards
      //list<pse__Timecard_Header__c> lstTimecards = new list<pse__Timecard_Header__c>();

      //Changes by shprasan: changing the number of timecards created to 2 and setting the status to Saved and billable to true
      //for(integer i=0;i<1;i++)
      //{
      //      //Create a Timecard
      //      pse__Timecard_Header__c timecard = testUtil.newTimecardHeader(false, resource.Id, lstProjects[i].Id, lstAssignments[i], lstMilestones[i].Id, System.today(), System.today().addDays(6));   
      //      timecard.pse__Billable__c = true;
      //      timecard.pse__Status__c = 'Saved';
      //      timecard.pse__Project_Methodology_Object__c = lstProjectProducts[i].Id;
      //      lstTimecards.add(timecard);
      //}
      ////Create the timecards with another user
      //System.runAs(usr) {                    
      //  insert lstTimecards;
      //}
      
      //Changes by shprasan: updating the project managers
      //lstProjects[0].pse__Project_Manager__c = resource1.id;
      ////lstProjects[1].pse__Project_Manager__c = resource1.id;
      //update lstProjects;

      
      PSA_SendWeeklyRemindersForTimecards sendReminders= new PSA_SendWeeklyRemindersForTimecards();
       
      ID batchprocessid = Database.executeBatch(sendReminders);
      Test.StopTest();
   }
}