/* ========================================================================
    Author: Sonia Sawhney
    Description: Test Class for PSA_ProjectProductTrigger
    Created Date : 10/04/2014
    ======================================================================== */
@isTest(seealldata=false)
public class PSA_ProjectProductTrigger_Test
{
    public static testMethod void testProjectProductDelete() {
        PSA_TestUtility testUtil = new PSA_TestUtility();
        //Create Account,User & Contact
        Account acct = testUtil.newAccount(true);
        User usr = testUtil.newUserSysAdmin(true);
        Contact resource = testUtil.newResource(true, acct.Id, usr.Id);
        //Create a new region
        pse__Region__c reg = testUtil.newRegionMaster(true);
        //Create Practice
        pse__Practice__c pract = testUtil.newPracticeMaster(true);
        Id practId = pract.ID;
        //Create Project & Project Product
        pse__Proj__c proj = testUtil.newProject(false,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);
        insert proj;
        pse__Project_Methodology__c  product = testUtil.newProjectProduct(true,proj.Id,'Test Proj Prod');

        //Create Milestone
        pse__Milestone__c milestone = testUtil.newMilestone(true,proj.Id,100,System.today());

        //Create a Timecard
        pse__Timecard_Header__c timecard = testUtil.newTimecardHeader(false, resource.Id, proj.Id, null, milestone.Id, System.today(), System.today().addDays(6));
        timecard.pse__Billable__c = false;
        timecard.pse__Project_Methodology_Object__c = product.Id;
        //Create the timecard with another user
        System.runAs(usr) {
            insert timecard;
        }

        //Delete the product that has timecards
        try
        {
            delete product;
        }
        catch (Exception e)
        {
            System.assert(e.getMessage().contains('You cannot delete a project product that has timecards associated with it!'));
        }
    }
}