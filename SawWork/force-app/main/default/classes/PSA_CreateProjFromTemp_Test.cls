/***
    PSA_CreateProjFromTemp_Test
    @author Liz Ichihashi
    @Description : This Class contains methods to test the functionality
                   of the Create Project From Template button on Opportunity
                   in the Project Related List.
    @History
    --Developer           --Date            --Change
    Liz Ichihashi         1/04/2013     Created the class.   
    Sharath               5 Sep 2018    refactored the class 
    Sujay                 11 March 19   Adding BOCC Setup.
*/
@isTest(SeeAllData=false)  
public class PSA_CreateProjFromTemp_Test {
    

    public static PSA_TestUtility testUtil; 
    public static pse__Region__c reg; 
    public static Account acct; 
    public static User usr; 
    public static User usr2; 
    public static Contact resource;
    public static Contact resource2;
    public static Opportunity opp; 
    public static List<OpportunityLineItem> lineItems; 
    public static pse__Practice__c pract;
    public static Id practId; 
    public static pse__Proj__c templateProj;    
    public static pse__Milestone__c milestone;
    public static pse__Milestone__c milestone2;
    public static pse__Project_Methodology__c projProd;     
    public static pse__Budget__c budget; 
    public static pse__Permission_Control__c pc;
    public static Merge_Contract_Header__c contract;
    public static Merge_Contract_Detail__c contDetail;
    //public static SC_BOCC_Setup__c BoccSetup;
    
    static
    {
        // BoccSetup                                        = new SC_BOCC_Setup__c();
        // BoccSetup.Name                               = 'BOCC';
        // BoccSetup.Product_Id__c                      = 'M-LC-160620';
        // BoccSetup.Entitlement_Process_Id_Proactive__c    = '5520f000000fxY0AAI';
        // BoccSetup.Entitlement_Process_Id_Reactive__c     = '5520f000000fxY5AAI';
        // insert BoccSetup;
        createData();
    }
    public static void createData()
    {
        testUtil = new PSA_TestUtility();

        reg = testUtil.newRegionMaster(true);

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
        projProd = testUtil.newProjectProduct(true,templateProj.Id, 'testprojprod');
        
        budget = testUtil.newBudget(true,templateProj.Id,100, System.today());
        
        //testUtil.newPermissionControl(true, usr.Id, null, practId, null, null, null, true);  
        testUtil.newPermissionControl(true, usr.Id, reg.Id, null, null, null, null, true);   

    }
    public static testMethod void testSuccessShort() 
    {
        //Integer befProjCount = [select count() from pse__Proj__c limit 100];
        
        Test.StartTest(); 
            opp = testUtil.newOpportunity(false,acct.Id, '0=Plan', System.today());
            opp.pse__Region__c = reg.Id;
            opp.pse__Practice__c = practId;
            opp.StageName = '1. Identify Need';
            opp.Validation_Override__c = TRUE;
            insert opp;

            lineItems = testUtil.createOpportunityItems(opp.Id, 4);        
            System.runAs(usr) {         
                PSA_CreateProjFromTemp_Controller myCont = new PSA_CreateProjFromTemp_Controller();
                ApexPages.currentPage().getParameters().put('acctId',acct.Id);
                ApexPages.currentPage().getParameters().put('oppId',opp.Id);
                myCont.setup();
                myCont.selectProject();
                myCont.templateHolderList[0].selected = true;
                myCont.templateHolderList[0].getHasProjectProducts();
                myCont.templateHolderList[0].getHasMilestones();
                myCont.templateHolderList[0].getHasBudgets();
                myCont.selectProject();
                myCont.newProject.Name = 'test saving new from templ';
                myCont.newProject.pse__Region__c = reg.Id;
                myCont.newProject.pse__Practice__c = practId;
                myCont.newProject.pse__Is_Billable__c  = true; 
                myCont.newProject.pse__Stage__c = 'In Progress';
                myCont.newProject.pse__Is_Active__c = true;
                myCont.newProject.pse__Project_Type__c = 'Customer Project';  
                myCont.newProject.pse__Billing_Type__c = 'One-Time: Fixed Price';
                myCont.newProject.pse__Expense_Budget__c = 1000;
                myCont.newProject.pse__Start_Date__c = Date.today();
                myCont.newProject.pse__End_Date__c = Date.today().addDays(1);
                myCont.newProject.Contract_Closed__c = 'No';
                myCont.newProject.pse__Project_Manager__c = resource.Id;
                myCont.newProject.pse__Account__c = acct.Id;
                myCont.newBudget.getBudget().pse__Effective_Date__c = System.today().addDays(1);
                myCont.newBudget.getBudget().pse__Invoice_Date__c =  System.today().addDays(1);
                myCont.saveProject();
            }
        Test.StopTest();
          
        /*Integer aftProjCount = [select count() from pse__Proj__c limit 100];
        System.debug('befProjCount='+befProjCount);
        System.debug('aftProjCount='+aftProjCount);
        System.assert(aftProjCount == befProjCount + 1);  */
    } 
    
    public static testMethod void testSuccess() 
    {
        
        //Integer befProjCount = [select count() from pse__Proj__c limit 100];
        
        Test.StartTest();  
            System.runAs(usr) {    
                PSA_CreateProjFromTemp_Controller myCont = new PSA_CreateProjFromTemp_Controller();
                ApexPages.currentPage().getParameters().put('acctId',acct.Id);
                //ApexPages.currentPage().getParameters().put('oppId',opp.Id);
                myCont.setup();
                myCont.getHasOppRequests();  
                myCont.getHasTemplateRequests();
                myCont.templateHolderList[0].selected = true;
                myCont.selectProject();
                myCont.templateHolderList[0].getBudget();
                myCont.templateHolderList[0].getProject();
                myCont.templateHolderList[0].getMilestone();
                myCont.templateHolderList[0].getHasBudgets();
                myCont.templateHolderList[0].getHasMilestones();    
                myCont.templateHolderList[0].getProject();
                myCont.newProject.Name = 'test saving new from templ';
                myCont.newProject.pse__Region__c = reg.Id;
                myCont.newProject.pse__Practice__c = practId;
                myCont.newProject.pse__Is_Billable__c  = true; 
                myCont.newProject.pse__Stage__c = 'In Progress';
                myCont.newProject.pse__Is_Active__c = true;
                myCont.newProject.pse__Project_Type__c = 'Customer Project';
                myCont.newProject.pse__Billing_Type__c = 'One-Time: Fixed Price';
                myCont.newProject.pse__Expense_Budget__c = 1000;
                myCont.newProject.pse__Start_Date__c = Date.today();
                myCont.newProject.pse__End_Date__c = Date.today().addDays(1);
                myCont.newProject.Contract_Closed__c = 'Yes';
                myCont.newProject.pse__Project_Manager__c = resource.Id;
                myCont.newProject.pse__Account__c = acct.Id;
                myCont.newBudget.getBudget().pse__Effective_Date__c = System.today().addDays(1);
                myCont.saveProject();
            }        
        Test.StopTest();
        
        //Integer aftProjCount = [select count() from pse__Proj__c limit 100];
    }  
    
    public static testMethod void testSuccessAgain() 
    {
        Test.StartTest();
        /*pse__Proj__c templateProj2 = testUtil.newProject(false,reg.id,practId,true,'One-Time: Fixed Price', resource2.Id, acct.Id); 
        templateProj2.pse__Is_Template__c = true;
        insert templateProj2;  */
        
        pse__Resource_Request__c oppResReq;
        pse__Resource_Request__c projResReq;   
        //pse__Resource_Request__c projResReq2;    
        
        
        /*janantha - commenting out this query to avoid limits */        
        //projResReq = [select pse__Project__c from pse__Resource_Request__c where id = :projResReq.Id];
        System.debug('projResReq='+projResReq);
        //System.debug('projResReq2='+projResReq2);
        //pse__Milestone__c milestone2 = testUtil.newMilestone(true,templateProj.Id,200,System.today());      
        
            System.runAs(usr) {
                //oppResReq = testUtil.newResourceRequest(true, acct.Id, resource.id, System.today(), System.today().addDays(5), null, opp.Id,reg.Id);
                projResReq = testUtil.newResourceRequest(true, acct.Id, resource.id, System.today(), System.today().addDays(15), templateProj.Id, null,reg.Id);   

                //execute these methods on the selectable object for coverage
                //normally, these methods are called by the page in render attributes.
                //these are all improper usage of the selectable object
                /*PSA_SelectableObject temp = new PSA_SelectableObject();
                temp.getBudget();
                temp.getProject();
                temp.getMilestone();
                temp.getHasBudgets();
                temp.getProject();
                temp.getHasProjectProducts();
                temp.getHasBudgets();
                temp.getHasMilestones();
                temp.getContract();
                temp.getContractDetail();*/
                PSA_CreateProjFromTemp_Controller myCont = new PSA_CreateProjFromTemp_Controller();
                ApexPages.currentPage().getParameters().put('acctId',acct.Id);
                //ApexPages.currentPage().getParameters().put('oppId',opp.Id);
                myCont.setup();
                myCont.templateHolderList[0].selected = true;
                myCont.selectProject();
                myCont.getHasOppRequests();  
                myCont.getHasTemplateRequests();
                myCont.getRegion();
                myCont.projNameFilter = 'test';
                myCont.filterProjects();
                myCont.clearFilter();
                myCont.templateHolderList[0].selected = true;
                myCont.selectProject();
                myCont.newProject.Name = 'test';
                myCont.newProject.Contract_Closed__c = 'Yes';
                myCont.newProject.pse__Billing_Type__c = 'One-Time: Fixed Price';
                myCont.newProject.pse__End_Date__c = System.today().addDays(60);
                myCont.templateHolderList[0].getHasBudgets();
                myCont.templateHolderList[0].getHasMilestones();
                myCont.templateHolderList[0].getHasProjectProducts();
                myCont.newResourceRequests[0].selected = true;
                //myCont.oppResourceRequests[0].selected = true;
                myCont.saveProject();
            }        
        Test.StopTest();    
    }
    
    public static testMethod void testSuccessSelectResourceRequests() 
    {
        
        pse__Resource_Request__c oppResReq;
        pse__Resource_Request__c projResReq;   
        
        
    
        Test.StartTest();
            opp = testUtil.newOpportunity(false,acct.Id, '0=Plan', System.today());
            opp.pse__Region__c = reg.Id;
            opp.pse__Practice__c = practId;
            opp.StageName = '1. Identify Need';
            opp.Validation_Override__c = TRUE;
            insert opp;

            System.runAs(usr) {       
                oppResReq = testUtil.newResourceRequest(true, acct.Id, resource.id, System.today(), System.today().addDays(5), null, opp.Id,reg.Id);
                projResReq = testUtil.newResourceRequest(true, acct.Id, resource.id, System.today(), System.today().addDays(15), templateProj.Id, null,reg.Id);   
            }           

            System.runAs(usr) {  
                PSA_CreateProjFromTemp_Controller myCont = new PSA_CreateProjFromTemp_Controller();
                ApexPages.currentPage().getParameters().put('acctId',acct.Id);
                ApexPages.currentPage().getParameters().put('oppId',opp.Id);
                myCont.setup();          
                myCont.getHasOppRequests();  
                myCont.getHasTemplateRequests();
                myCont.templateHolderList[0].selected = true;
                myCont.selectProject();
                myCont.newProject.Name = 'test';
                myCont.newProject.Contract_Closed__c = 'Yes';
                myCont.newProject.pse__Billing_Type__c = 'One-Time: Fixed Price';
                myCont.newProject.pse__End_Date__c = System.today().addDays(60);
                myCont.newBudget.getBudget().pse__Effective_Date__c = System.today();
                System.debug('myCont.newResourceRequests='+myCont.newResourceRequests);
                System.debug('myCont.oppResourceRequests='+myCont.oppResourceRequests);
                myCont.newResourceRequests[0].selected = true;
                myCont.newResourceRequests[0].getResourceRequest().pse__Region__c = reg.Id;
                myCont.newResourceRequests[0].getResourceRequest().pse__Resource__c = resource.Id;
                myCont.oppResourceRequests[0].selected = true;
                myCont.oppResourceRequests[0].getResourceRequest().pse__Region__c = reg.Id;
                myCont.oppResourceRequests[0].getResourceRequest().pse__Resource__c = resource.Id;
                myCont.saveProject();
            }        
        Test.StopTest();    
    }
      
    public static testMethod void testFailValidate() 
    {
        
        //Integer befProjCount = [select count() from pse__Proj__c limit 100];
        
        Test.StartTest();      
            System.runAs(usr) {
                PSA_CreateProjFromTemp_Controller myCont = new PSA_CreateProjFromTemp_Controller();
                ApexPages.currentPage().getParameters().put('acctId',acct.Id);
                //ApexPages.currentPage().getParameters().put('oppId',opp.Id);
                myCont.setup();
                myCont.templateHolderList[0].selected = true;
                myCont.selectProject();
                myCont.newBudget.selected = true;
                myCont.saveProject();
            }        
        Test.StopTest();  
    } 
    
     public static testMethod void testCancelWithAcctId() 
     {
        //Integer befProjCount = [select count() from pse__Proj__c limit 100];
        
        Test.StartTest();      
            PSA_CreateProjFromTemp_Controller myCont = new PSA_CreateProjFromTemp_Controller();
            ApexPages.currentPage().getParameters().put('acctId',acct.Id);
            myCont.setup();
            myCont.cancel();
        Test.StopTest();
   
    } 
    
     public static testMethod void testSelectContractLineItem() 
     {
       // Integer befProjCount = [select count() from pse__Proj__c limit 100];
        
        Test.StartTest();  
            contract = testUtil.newContract(true, acct.Id, '123','456',null,System.today(), System.today().addDays(50));
            contDetail = testUtil.newContractDetail(true, 'test','test',contract.Id, System.today(), System.today().addDays(50));

            PSA_CreateProjFromTemp_Controller myCont = new PSA_CreateProjFromTemp_Controller();  
            ApexPages.currentPage().getParameters().put('acctId',acct.Id);
            myCont.productSet.add('test');
            myCont.setup();
            myCont.templateHolderList[0].selected = true;
            myCont.selectProject();
            myCont.addProjectContractLineItem();
            for (PSA_SelectableObject contRow : myCont.contractList) {
                for (PSA_SelectableObject lineRow : contRow.childObjects) {
                    lineRow.Selected = true;
                }
            }       
            myCont.saveProjContractData();
            myCont.cancelReturnToTemplate();
            myCont.updateBudgetEffectiveDate();
            String url = myCont.retURL;
            Boolean isClassic =  myCont.isClassic;
            myCont.getShowTemplateList();
            myCont.getShowSelectContractLineItems();
            myCont.getShowProjectDetails();
        Test.StopTest();
    } 
    
    public static testMethod void testInvalidSelectableObject() 
    {
        
        Test.StartTest();      
           PSA_SelectableObject selectable = new PSA_SelectableObject();
           selectable.obj = acct;
           selectable.getBudget();
           selectable.getMilestone();
           selectable.getProject();
           selectable.getContract();
           selectable.getContractDetail();
           selectable.getResourceRequest();
        Test.StopTest();
    }
    
    public static testMethod void testsaveProject2() 
    {
        Test.StartTest();      
            System.runAs(usr) {
                PSA_CreateProjFromTemp_Controller myCont = new PSA_CreateProjFromTemp_Controller();
                ApexPages.currentPage().getParameters().put('acctId',acct.Id);
                //ApexPages.currentPage().getParameters().put('oppId',opp.Id);
                myCont.setup();
                myCont.templateHolderList[0].selected = true;
                myCont.selectProject();
                myCont.newBudget.selected = true;
                
                contract = testUtil.newContract(true, acct.Id, '123','456',null,System.today(), System.today().addDays(50));
                contDetail = testUtil.newContractDetail(true, 'test','test',contract.Id, System.today(), System.today().addDays(50));

                Boolean isClassic = false;
                myCont.conDetail = contDetail.Id;

                myCont.saveProject();
            }        
        Test.StopTest();  
        
    }
}