/***
    PSA_ProjectContractSelect_Test
    @author Liz Ichihashi
    @Description : This Class contains methods to test PSA_ProjectContractSelect_Controller
                   and PSA_ProjectContractSelect_Page.  This page is called from a button on the
                   Project page layout.  It provides a UI for Users to find and add and remove many Contract
                   Details to a project.  They can view Contract info as well as child Contract
                   Details for all or many of an Account's active Contracts.
                   
    @History
    --Developer           --Date            --Change
    Liz Ichihashi         7/04/2013     Created the class.     
*/
@isTest(SeeAllData=false)
public with sharing class PSA_ProjectContractSelect_Test {
    
    public static PSA_TestUtility testUtil;
    public static Account acct;
    public static pse__Region__c reg;
    public static User usr;
    public static Contact resource;
    public static Merge_Contract_Header__c contract;
    public static Merge_Contract_Detail__c contDetail;
    public static Merge_Contract_Detail__c contDetail2;
    public static List<PSA_Products__c> productList;
    public static pse__Practice__c pract;
    public static pse__Proj__c proj;
    public static Project_Contract__c pc;
    public static Project_Contract_Line_Item__c pcli;
    //public static List<Merge_Contract_Detail__c> pcliList;
        
    static{
        testUtil = new PSA_TestUtility();
        acct = testUtil.newAccount(true);
        reg = testUtil.newRegionMaster(true);
        usr = testUtil.newUserSysAdmin(true);        
        resource = testUtil.newResource(true, acct.Id, usr.Id);
        contract = testUtil.newContract(true, acct.Id, '123','456',null,System.today(), System.today().addDays(50));
        //pcliList = new List<Merge_Contract_Detail__c>();
        contDetail = testUtil.newContractDetail(true, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        contDetail2 = testUtil.newContractDetail(false, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        //pcliList.add(contDetail);
        //pcliList.add(contDetail2);
        //insert pcliList;

        //Add PSA_Products__c
        PSA_Products__c psaProduct = new PSA_Products__c();
        psaProduct.Product_Name__c = 'Additional EdgeComputing Professional Services';
        psaProduct.Name = '1';
        insert psaProduct;

        productList = PSA_Products__c.getall().values();
        contDetail.Product__c = productList[0].Product_Name__c;
        update contDetail;
        pract = testUtil.newPracticeMaster(true);
        //Id practId = [select Id from pse__Practice__c where name = 'Security Services'].Id;
        proj = testUtil.newProject(true,reg.id,pract.Id,true,'One-Time: Fixed Price', resource.Id, acct.Id);
        
        pc = new Project_Contract__c();
        pc.Project__c = proj.Id;
        pc.Original_Contract_Id__c = contract.id;
        pc.Account__c = proj.pse__Account__c;
        //insert pc;
        
        pcli = new Project_Contract_Line_Item__c();
        pcli.Project__c = proj.Id;
        
        pcli.Contract_Detail__c = contDetail.Id;        
        pcli.Valid_Create__c = true;
        //insert pcli;
        
        
        
    }
    
    public static testMethod void testSelectOneLineSuccess() {
            
        Test.startTest();
        PSA_ProjectContractSelect_Controller cont = new PSA_ProjectContractSelect_Controller();
        ApexPages.currentPage().getParameters().put('projId',proj.Id);
        cont.setup();
        cont.filter.pse__Start_Date__c = System.today().addDays(-1);
        cont.filter();
        cont.save();
        //System.assert(cont.contractList.size() > 0);
        if(cont.contractList!=null)
        {
            if(cont.contractList[0].childObjects!=null && cont.contractList[0].childObjects.size()>0)
            {
                cont.contractList[0].childObjects[0].selected = true;
            }
        }
        cont.save();
        Test.stopTest();
       // List<Project_Contract__c> projContracts = [select Id from Project_Contract__c where Project__c = :proj.Id];
       // System.assert(projContracts != null && projContracts.size() == 1);
       // List<Project_Contract_Line_Item__c> projContractLineItems = [select Id from Project_Contract_Line_Item__c where Project__c = :proj.Id];
       // System.assert(projContractLineItems != null && projContractLineItems.size() == 1);  
    }
    
    public static testMethod void testException() {    
        
        Test.startTest();
        PSA_ProjectContractSelect_Controller cont = new PSA_ProjectContractSelect_Controller();
        ApexPages.currentPage().getParameters().put('projId',proj.Id);
        cont.setup();
        cont.throwException = true;  
        boolean excCaught = false;
        try {
            cont.save();
        } catch (Exception e) {
            excCaught = true;
        }   
        System.assert(excCaught);
        Test.StopTest();
    }
    public static testMethod void testClear() {
            
        Test.startTest();
        PSA_ProjectContractSelect_Controller cont = new PSA_ProjectContractSelect_Controller();
        ApexPages.currentPage().getParameters().put('projId',proj.Id);
        cont.setup();
        cont.clear();
        cont.setup();
        cont.save();
        Test.StopTest();
    }
    
    public static testMethod void testFilter() {
          
        Test.startTest();
        PSA_ProjectContractSelect_Controller cont = new PSA_ProjectContractSelect_Controller();
        ApexPages.currentPage().getParameters().put('projId',proj.Id);
        cont.setup();
        cont.filter.pse__End_Date__c = System.today().addDays(60);
        cont.filter.pse__Start_Date__c = System.today().addDays(-60);
        cont.filter.Customer_PO__c = 'x';
        cont.filter();
        Test.StopTest();
        
    }
    
    public static testMethod void testNoData() {
           
        Test.startTest();
        PSA_ProjectContractSelect_Controller cont = new PSA_ProjectContractSelect_Controller();
        ApexPages.currentPage().getParameters().put('projId',proj.Id);
        cont.setup();
        Test.StopTest();
    }
    
    public static testMethod void testBadSave() {
            
        Test.startTest();
        PSA_ProjectContractSelect_Controller cont = new PSA_ProjectContractSelect_Controller();
        ApexPages.currentPage().getParameters().put('projId',proj.Id);
        cont.setup();
        cont.filter.pse__Start_Date__c = System.today().addDays(-1);
        cont.filter();
        cont.save();
        System.assert(cont.contractList.size() > 0);
        cont.save();
        Test.StopTest();
    }
    
    public static testMethod void testSelectOneLineSuccessSwitchPCLI() {           
        
        insert contDetail2;
        insert pc;
        pcli.Project_Contract__c = pc.Id;  
        pcli.Original_Contract_Id__c = pc.Original_Contract_Id__c;
        insert pcli;
        Test.startTest();
        PSA_ProjectContractSelect_Controller cont = new PSA_ProjectContractSelect_Controller();
        ApexPages.currentPage().getParameters().put('projId',proj.Id);
        if(cont.contractList!=null)
        {
            if(cont.contractList[0].childObjects!=null && cont.contractList[0].childObjects.size()>0)
            {
                cont.setup();       
                cont.contractList[0].childObjects[0].selected = false;
                cont.contractList[0].childObjects[1].selected = true;
                cont.save();
            }
        }  
        Test.StopTest();
    }
        
    public static testMethod void testSelectSuccessStdCont() {
            
        
        insert pc;
        pcli.Project_Contract__c = pc.Id;  
        pcli.Original_Contract_Id__c = pc.Original_Contract_Id__c;
        insert pcli;
        Test.startTest();
        ApexPages.Standardcontroller stdCont = new ApexPages.Standardcontroller(pcli);
        PSA_ProjectContractSelect_Controller cont = new PSA_ProjectContractSelect_Controller(stdCont);
        cont.setup();
        cont.filter.pse__End_Date__c = System.today().addDays(-60);
        cont.filter();
        cont.returnToProject();
        //Boolean isClassic = cont.isClassic;
        Test.StopTest();
    }
    
    public static testMethod void testImproperUsage() {
        
        boolean excCaught = false;
        Test.StartTest();
        PSA_ProjectContractSelect_Controller cont = new PSA_ProjectContractSelect_Controller();
        
            try {   
                cont.setup();
            } catch (Exception e) {
                excCaught = true;
            }
        Test.StopTest();      
        System.assert(excCaught);   
    }
}