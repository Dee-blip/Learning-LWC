@isTest(SeeAllData=false)
public with sharing class PSA_ProjectContractSelectController_Test {
    
    Public static PSA_TestUtility testUtil;
    Public static pse__Proj__c proj1;
    Public static Merge_Contract_Header__c contract;
    Public static Merge_Contract_Detail__c contDetail;
    Public static Account acct;
    Public static User usr;
    Public static User usr2;
    Public static Contact resource;
    Public static pse__Region__c reg;
    Public static pse__Practice__c pract;
    Public static Project_Contract__c projCont;
    Public static Project_Contract_Line_Item__c projContItem;

    static {

        Environment_Setup__c esSetting = new Environment_Setup__c();
        //esSetting.SetupOwnerId = '';
        esSetting.Active_Org__c = true;
        esSetting.Connection_Name__c = 'DR';
        esSetting.ConnectionId__c = '04PG0000000PDf9MAG';
        esSetting.CName_Url__c = 'https://crm.akamai.com/apex/OpenByAKAMid?Id=';
        esSetting.Akam_Id_Start_String__c = 'F-';
        esSetting.Environment_Type__c = 'Primary';

        PSA_Products__c psaProduct = new PSA_Products__c();
        psaProduct.Product_Name__c = 'Additional EdgeComputing Professional Services';
        psaProduct.Name = '1';
        insert psaProduct;
        
        insert esSetting;

        testUtil = new PSA_TestUtility();
        reg = testUtil.newRegionMaster(true);
        pract = testUtil.newPracticeMaster(true);
        usr = testUtil.newUserSysAdmin(false); 
        usr2 = testUtil.newUserSysAdmin(true); 
        
        usr.ManagerId = usr2.id;
        usr.DelegatedApproverId = usr2.id;
        usr.Country = 'Testcountry';
        
        insert usr;
        acct = testUtil.newAccount(true);
        resource = testUtil.newResource(true, acct.Id, usr.Id);
        contract = testUtil.newContract(true, acct.Id, '123','456',null,System.today(), System.today().addDays(50));
        contDetail = testUtil.newContractDetail(true, 'Additional EdgeComputing Professional Services','test',contract.Id, System.today(), System.today().addDays(50));
        proj1 = testUtil.newProject(true,reg.id,pract.Id,true,'One-Time: Fixed Price', resource.Id, acct.Id);
        projCont = testUtil.newProjectContract(true, proj1.Id, contract.Id, acct.Id);
        projContItem = testUtil.newProjectContractLineItem(true, proj1.Id, contract.Id, contDetail.Id, projCont.Id);
        
        

    }

    @isTest 
    static void testSaveProject()
    {
        test.startTest();
        System.debug('ids 1 :' + contDetail.Id + ' 2 : ' + contract.Id  );
        String result = PSA_ProjectContractSelectController.saveProject(contDetail.Id, contract.Id , proj1.Id );
        test.stopTest();

    }

    @isTest 
    static void testgetContractWithDetails()
    {
        
        test.startTest();
        List<Merge_Contract_Detail__c> detailList = new List<Merge_Contract_Detail__c>();

        

        for (integer i=0 ; i< 5 ; i ++) {
            contDetail = testUtil.newContractDetail(false, 'Additional EdgeComputing Professional Services','test',contract.Id, System.today(), System.today().addDays(50));
            detailList.add(contDetail);
        }

        for (integer i=0 ; i< 1500 ; i ++) {
            contDetail = testUtil.newContractDetail(false, 'nonvalidProd','test',contract.Id, System.today(), System.today().addDays(50));
            detailList.add(contDetail);
        }

        for (integer i=0 ; i< 2 ; i ++) {
            contDetail = testUtil.newContractDetail(false, 'Additional EdgeComputing Professional Services','test',contract.Id, System.today(), System.today().addDays(50));
            detailList.add(contDetail);
        }

        insert detailList;


        System.debug('ids 1 :' + contDetail.Id + ' 2 : ' + contract.Id  );
        List<PSA_SelectableObject> resultSelectable = new List<PSA_SelectableObject>();

        System.debug(' chks vals : ' + proj1.pse__Account__c + ' contracts acc : ' + contract.Account_Name__c + ' acc: ' + acct.Id );
        contract.Account_Name__c = acct.Id;
        update contract;
        // System.debug(' query in test : ' + [ select Account_Name__c from Merge_Contract_Header__c where id = :contract.Id ].Account_Name__c  );
        resultSelectable = PSA_ProjectContractSelectController.getContractWithDetails(proj1.Id, 0, '' , 'Active' );
        test.stopTest();

    }
}