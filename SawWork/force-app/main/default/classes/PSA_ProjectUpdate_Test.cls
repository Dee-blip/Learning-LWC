/***
    PSA_ProjectUpdate_Test
    @author Liz Ichihashi
    @Description : This Class contains methods to test the PSA_ProjectUpdate_Controller
                   and PSA_ProjectUpdate_Page.
                   
    --Developer           --Date            --Change
    Liz Ichihashi         7/04/2013     Created the class.     
*/
@isTest(SeeAllData=false)
public class PSA_ProjectUpdate_Test {
    
    
    public static testMethod void testSuccessfulUpdate() {
        PSA_TestUtility testUtil = new PSA_TestUtility();
        pse__Region__c reg = testUtil.newRegionMaster(true);
        Account acct = testUtil.newAccount(false);
        //acct.TERR_HIER_5__c = [select Id, Territory__c from pse__Region__c  where Territory__c <> null  limit 1].Id;   
        insert acct;
        User usr = testUtil.newUserSysAdmin(true);        
        pse__Work_Calendar__c cal = testUtil.newWorkCalender(true);
        Contact resource = testUtil.newResource(true, acct.Id, usr.Id, reg.Id, cal.Id);
        User usr2 = testUtil.newUserSysAdmin(true);        
        Contact resource2 = testUtil.newResource(true, acct.Id, usr2.Id);
        Opportunity opp = testUtil.newOpportunity(true,acct.Id, '0=Plan', System.today());
        List<OpportunityLineItem> lineItems = testUtil.createOpportunityItems(opp.Id, 4);
       pse__Practice__c pract = testUtil.newPracticeMaster(true);
       Id practId = pract.ID;
       
        test.starttest();
        pse__Proj__c proj = testUtil.newProject(true,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);     
        //pse__Proj__c proj2 = testUtil.newProject(true,reg.id,practId,true,'One-Time: Fixed Price', resource2.Id, acct.Id);        
        pse__Permission_Control__c pc = testUtil.newPermissionControl(true, usr2.Id, reg.Id);         
        pse__Resource_Request__c oppResReq;
        pse__Resource_Request__c projResReq;       
         
        System.runAs(usr2) {   
            oppResReq = testUtil.newResourceRequest(true, acct.Id, resource.id, System.today(), System.today().addDays(5), null, opp.Id,reg.Id);
            projResReq = testUtil.newResourceRequest(true, acct.Id, resource.id, System.today(), System.today().addDays(15), proj.Id, null,reg.Id);   
        }        
        
        pse__Milestone__c milestone = testUtil.newMilestone(true,proj.Id,100,System.today());
        //pse__Milestone__c milestone2 = testUtil.newMilestone(true,proj.Id,200,System.today());      
        pse__Budget__c budget = testUtil.newBudget(true,proj.Id,100, System.today());  
        pse__Project_Methodology__c projProduct = testUtil.newProjectProduct(true, proj.Id, 'test');
        
        PSA_ProjectUpdate_Controller cont = new PSA_ProjectUpdate_Controller();
        ApexPages.currentPage().getParameters().put('projId',proj.Id);
        cont.setup();  
        //cont.filter();  
        cont.clear();
        cont.filter();      
        cont.save();
        test.stoptest();
    }   
    
    public static testMethod void testSuccessfulUpdte2() {
        PSA_TestUtility testUtil = new PSA_TestUtility();
        pse__Region__c reg = testUtil.newRegionMaster(true);
        Account acct = testUtil.newAccount(false);
        acct.TERR_HIER_5__c = [select Id, Territory__c from pse__Region__c  where Territory__c <> null limit 1].Id;   
        insert acct;
        User usr = testUtil.newUserSysAdmin(true);        
        pse__Work_Calendar__c cal = testUtil.newWorkCalender(true);
        Contact resource = testUtil.newResource(true, acct.Id, usr.Id, reg.Id, cal.Id);
        User usr2 = testUtil.newUserSysAdmin(true);        
        Contact resource2 = testUtil.newResource(true, acct.Id, usr2.Id);
        Opportunity opp = testUtil.newOpportunity(true,acct.Id, '0=Plan', System.today());
        List<OpportunityLineItem> lineItems = testUtil.createOpportunityItems(opp.Id, 4);
        pse__Practice__c pract = testUtil.newPracticeMaster(true);
        Id practId = pract.ID;
        test.starttest();
        pse__Proj__c proj = testUtil.newProject(true,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);     
        pse__Proj__c proj2 = testUtil.newProject(true,reg.id,practId,true,'One-Time: Fixed Price', resource2.Id, acct.Id);     
        pse__Permission_Control__c pc = testUtil.newPermissionControl(true, usr2.Id, reg.Id);         
        pse__Resource_Request__c oppResReq;
        pse__Resource_Request__c projResReq;       
         
        System.runAs(usr2) {   
            oppResReq = testUtil.newResourceRequest(true, acct.Id, resource.id, System.today(), System.today().addDays(5), null, opp.Id,reg.Id);
            projResReq = testUtil.newResourceRequest(true, acct.Id, resource.id, System.today(), System.today().addDays(15), proj.Id, null,reg.Id);   
        }       
        pse__Milestone__c milestone = testUtil.newMilestone(true,proj.Id,100,System.today());
        pse__Milestone__c milestone2 = testUtil.newMilestone(true,proj.Id,200,System.today());      
        pse__Budget__c budget = testUtil.newBudget(true,proj.Id,100, System.today());  
        pse__Project_Methodology__c projProduct = testUtil.newProjectProduct(true, proj.Id, 'test');
        
        PSA_ProjectUpdate_Controller cont = new PSA_ProjectUpdate_Controller();
        ApexPages.currentPage().getParameters().put('projId',proj.Id);
        cont.setup();  
        cont.selectedFilter = 'Project';
        cont.filterProjObj.pse__Start_Date__c = System.today().addDays(-30);
        cont.filterProjObj.pse__End_Date__c = System.today().addDays(60);
        cont.filter();
        cont.selectedFilter = 'Milestone';
        cont.filterProjObj.pse__Start_Date__c = System.today().addDays(-30);
        cont.filterProjObj.pse__End_Date__c = System.today().addDays(60);
        cont.filter();
        cont.selectedFilter = 'Account';
        cont.filterProjObj.pse__Project_Status__c = 'Test';
        cont.filter();
        test.stoptest();
    }   
    
    public static testMethod void testAdditionalConditions() {
        PSA_TestUtility testUtil = new PSA_TestUtility();
        pse__Region__c reg = testUtil.newRegionMaster(true);
        Account acct = testUtil.newAccount(false);
        acct.TERR_HIER_5__c = [select Id, Territory__c from pse__Region__c  where Territory__c <> null  limit 1].Id;   
        insert acct;
        User usr = testUtil.newUserSysAdmin(true);        
        pse__Work_Calendar__c cal = testUtil.newWorkCalender(true);
        Contact resource = testUtil.newResource(true, acct.Id, usr.Id, reg.Id, cal.Id);
        User usr2 = testUtil.newUserSysAdmin(true);        
        Contact resource2 = testUtil.newResource(true, acct.Id, usr2.Id);
        Opportunity opp = testUtil.newOpportunity(true,acct.Id, '0=Plan', System.today());
        List<OpportunityLineItem> lineItems = testUtil.createOpportunityItems(opp.Id, 4);
        pse__Practice__c pract = testUtil.newPracticeMaster(true);
        Id practId = pract.ID;
        test.starttest();
        pse__Proj__c proj = testUtil.newProject(true,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);     
        pse__Proj__c proj2 = testUtil.newProject(true,reg.id,practId,true,'One-Time: Fixed Price', resource2.Id, acct.Id);        
        pse__Permission_Control__c pc = testUtil.newPermissionControl(true, usr2.Id, reg.Id);         
        pse__Resource_Request__c oppResReq;
        pse__Resource_Request__c projResReq;       
         
        System.runAs(usr2) {   
            oppResReq = testUtil.newResourceRequest(true, acct.Id, resource.id, System.today(), System.today().addDays(5), null, opp.Id,reg.Id);
            projResReq = testUtil.newResourceRequest(true, acct.Id, resource.id, System.today(), System.today().addDays(15), proj.Id, null,reg.Id);   
        }        
        
        pse__Milestone__c milestone = testUtil.newMilestone(true,proj.Id,100,System.today());
        pse__Milestone__c milestone2 = testUtil.newMilestone(true,proj.Id,200,System.today());      
        pse__Budget__c budget = testUtil.newBudget(true,proj.Id,100, System.today());  
        pse__Project_Methodology__c projProduct = testUtil.newProjectProduct(true, proj.Id, 'test');
        
        PSA_ProjectUpdate_Controller cont = new PSA_ProjectUpdate_Controller();
        ApexPages.currentPage().getParameters().put('projId',proj.Id);
        cont.setup();
        cont.selectedFilterType = 'Milestone';
        cont.selectedFilter = 'test';
        cont.filter();
        cont.selectedFilterType = 'Project';
        cont.selectedFilter = 'test';
        cont.filter();
        cont.selectedFilterType = 'Account';
        cont.selectedFilter = 'test';
        cont.filter();
        cont.selectedFilterType = 'Account';
        cont.selectedFilter = 'blasphemy';
        cont.filter();
        cont.cancel();
        test.stoptest();
    }   
}