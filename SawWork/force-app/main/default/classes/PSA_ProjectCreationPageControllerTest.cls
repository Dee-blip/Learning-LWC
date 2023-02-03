@isTest(SeeAllData=false)  
public class PSA_ProjectCreationPageControllerTest {
    

    public static PSA_TestUtility testUtil; 
    public static pse__Region__c reg; 
    public static Account acct; 
    public static User usr; 
    public static User usr2; 
    public static Contact resource;
    public static Opportunity opp; 
    public static pse__Practice__c pract;
    public static Id practId; 
    public static pse__Proj__c templateProj; 
    public static list<pse__Milestone__c> milestoneList;   
    public static pse__Milestone__c milestone;
    public static pse__Milestone__c milestone2;
    public static pse__Milestone__c milestone3;
    public static pse__Project_Methodology__c projProd;     
    public static pse__Budget__c budget; 
    public static pse__Permission_Control__c pc;
    public static Merge_Contract_Header__c contract;
    public static Merge_Contract_Detail__c contDetail;
    
    static
    {
        createData();
    }
    public static void createData()
    {
        testUtil = new PSA_TestUtility();

        reg = testUtil.newRegionMaster(false);
        reg.Name = 'Comm Central (Territory)';
        insert reg;

        acct = testUtil.newAccount(false);
        acct.TERR_HIER_5__c ='Comm Central';   
        insert acct;  

        usr = testUtil.newUserSysAdmin(true);        

        resource = testUtil.newResource(true, acct.Id, usr.Id);

        pract = testUtil.newPracticeMaster(true);
        practId = pract.ID;
        
        templateProj = testUtil.newProject(false,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);   
        templateProj.pse__Is_Template__c = true;
        insert templateProj;
        
        milestone = testUtil.newMilestone(true,templateProj.Id,100,System.today());
        milestone2 = testUtil.newMilestone(false,templateProj.Id,100,System.today());
        milestone3 = testUtil.newMilestone(false,templateProj.Id,100,System.today());
        milestoneList = new list<pse__Milestone__c>();
        milestoneList.add(milestone2);
        milestoneList.add(milestone3);
        insert milestoneList;

        projProd = testUtil.newProjectProduct(true,templateProj.Id, 'testprojprod');       
        budget = testUtil.newBudget(true,templateProj.Id,100, System.today());
        pse__Project_Task__c projTaskRec = new pse__Project_Task__c();
        projTaskRec.pse__Project__c = templateProj.Id;
        projTaskRec.pse__Milestone__c = milestoneList[0].Id;
        projTaskRec.Name = 'test task';
        insert projTaskRec;
        
        //testUtil.newPermissionControl(true, usr.Id, null, practId, null, null, null, true);  
        testUtil.newPermissionControl(true, usr.Id, reg.Id, null, null, null, null, true);   

    }

    public static testMethod void TestMethod1() 
    {        
        opp = testUtil.newOpportunity(false,acct.Id, '0=Plan', System.today());
        opp.pse__Region__c = reg.Id;
        opp.pse__Practice__c = practId;
        opp.StageName = '1. Identify Need';
        opp.Validation_Override__c = TRUE;
        insert opp;

        Test.StartTest();      
            System.runAs(usr) {        
                PSA_ProjectCreationPageController.getProjectTemplates('');
                PSA_ProjectCreationPageController.getProjectinfo(templateProj.Id, acct.Id);
            }
        Test.StopTest();

    } 

    public static testMethod void TestMethod2()
    {   
        list<pse__Milestone__c> mileClones = new list<pse__Milestone__c>();
        list<pse__Project_Task__c> projTaskList = new list<pse__Project_Task__c>();
        pse__Project_Task__c projTask = new pse__Project_Task__c();
        List<pse__Project_Task__c> taskList = new list<pse__Project_Task__c>();
        List<pse__Resource_Request__c> resreq = new List<pse__Resource_Request__c>();
        
        contract = testUtil.newContract(true, acct.Id, '123','456',null,System.today(), System.today().addDays(50));
        contDetail = testUtil.newContractDetail(true, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        templateProj.Contract_Closed__c = 'No';
        update templateProj;
        pse__Proj__c projClone = templateProj.clone(false,false,false,false);
        pse__Budget__c budgetClone = budget.clone(false,false,false,false);
        for( pse__Milestone__c mile:milestoneList){
            mileClones.add(mile.clone(false,false,false,false));
        }

        projTask.pse__Project__c = templateProj.Id;
        projTask.pse__Milestone__c = milestoneList[0].Id;
        projTask.Name = 'test proj task';
        insert projTask;

        projTaskList.add(projTask.clone(false,false,false,false));

        string proj = JSON.Serialize(projClone);
        string budgetrec = JSON.Serialize(budgetClone);
        string milestonelst = JSON.Serialize(mileClones);
        string tasks = JSON.Serialize(projTaskList);
        string resreqList = JSON.Serialize(resreq);

        Test.StartTest();
            System.runAs(usr) {    
                PSA_ProjectCreationPageController.saveProject(proj,budgetrec,milestonelst,tasks,contDetail.Id,resreqList);
            }
        Test.StopTest();
    }
}