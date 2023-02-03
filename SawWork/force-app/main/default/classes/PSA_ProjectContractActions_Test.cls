@isTest(SeeAllData=false)
/***
    PSA_ProjectContractActions_Test
    @author Liz Ichihashi
    @Description : This Class contains methods to test the PSA_ProjectContractActions class which has methods 
                   that are called by PSA_ProjectContract_Trigger
    @History
    --Developer           --Date            --Change
    Liz Ichihashi         7/04/2013     Created the class.   
    Sharath Prasanna      2/04/2015     Modified the class for CR 2941958    
*/
private class PSA_ProjectContractActions_Test {
    
    public static testMethod void testDeleteProjectContractUpdatesBillEffDate() {

        // SC_BOCC_Setup__c scSetting = new SC_BOCC_Setup__c();
        // scSetting.Name = 'BOCC';
        // scSetting.Entitlement_Process_Id_Proactive__c = '5520f000000fxY0AAI';
        // scSetting.Entitlement_Process_Id_Reactive__c = '5520f000000fxY5AAI';
        // scSetting.Product_Id__c = 'M-LC-160618';
        // insert scSetting;
        
        PSA_TestUtility testUtil = new PSA_TestUtility();
        Account acct = testUtil.newAccount(true);
        pse__Region__c reg = testUtil.newRegionMaster(true);
        User usr = testUtil.newUserSysAdmin(true);        
        Contact resource = testUtil.newResource(true, acct.Id, usr.Id);
        Merge_Contract_Header__c contract = testUtil.newContract(true, acct.Id, '123','456',null,System.today(), System.today().addDays(50));
        Merge_Contract_Detail__c contDetail = testUtil.newContractDetail(true, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        Merge_Contract_Header__c contract2 = testUtil.newContract(true, acct.Id, '123','456',null,System.today().addDays(50), System.today().addDays(150));
        Merge_Contract_Detail__c contDetail2 = testUtil.newContractDetail(true, 'test','test',contract2.Id, System.today(), System.today().addDays(50));
        Merge_Contract_Header__c contract3 = testUtil.newContract(true, acct.Id, '123','456',null,System.today().addDays(40), System.today().addDays(150));
        Merge_Contract_Header__c contract4 = testUtil.newContract(true, acct.Id, '123','456',null,System.today().addDays(40), System.today().addDays(150));
        Merge_Contract_Detail__c contDetail3 = testUtil.newContractDetail(true, 'test','test',contract3.Id, System.today(), System.today().addDays(50));
        Merge_Contract_Detail__c contDetail4 = testUtil.newContractDetail(true, 'test','test',contract4.Id, System.today(), System.today().addDays(50));
        pse__Practice__c pract = testUtil.newPracticeMaster(true);
        Id practId = pract.ID;

        //start of changes by shprasan 
        pse__Proj__c proj = testUtil.newProject(true,reg.id,practId, true, 'One-Time: Fixed Price', resource.Id, acct.Id);  
        Project_Contract__c projContract;
        Project_Contract_Line_Item__c projContractLineItem;
        Project_Contract__c projContract2; 
        Project_Contract_Line_Item__c projContractLineItem2; 
        Project_Contract__c projContract3; 
        Project_Contract_Line_Item__c projContractLineItem3;
        Project_Contract__c projContract4;
        Project_Contract_Line_Item__c projContractLineItem4;
        //Project_Contract_Line_Item__c projContractLineItem4;

        //delete this project contract line item.  Since this is the only line item for that contract, the project contract will be deleted also.
        //subsequently, the project's bill effective date will be updated to be the earliest related contract rev. eff date (which is contract3).
        Test.StartTest();
                 projContract = testUtil.newProjectContract(true, proj.Id, contract.Id, acct.Id);
                 projContractLineItem = testUtil.newProjectContractLineItem(true, proj.Id, contract.Id, contDetail.Id, projContract.Id);
                 projContract2 = testUtil.newProjectContract(true, proj.Id, contract2.Id, acct.Id);
                 projContractLineItem2 = testUtil.newProjectContractLineItem(true, proj.Id, contract2.Id, contDetail2.Id, projContract2.Id);
                 projContract3 = testUtil.newProjectContract(true, proj.Id, contract3.Id, acct.Id);
                 projContractLineItem3 = testUtil.newProjectContractLineItem(true, proj.Id, contract3.Id, contDetail3.Id, projContract3.Id);
                 projContract4 = testUtil.newProjectContract(false, proj.Id, contract4.Id, acct.Id);
                 
                 projContract4.Valid_Delete__c = false;
                 insert projContract4;

                 projContractLineItem4 = testUtil.newProjectContractLineItem(true, proj.Id, contract4.Id, contDetail4.Id, projContract4.Id);

                 try {
                    delete projContract4;
                 }
                 catch ( Exception e ) {
                    System.debug(' add error msg on invalid delete');
                 }
        Test.StopTest();
        
        // Since projContractLineItem2 and projContractLineItem are the only line item for their contracts, the project contracts associated with them will also be deleted.
        // subsequently, the project's bill effective date will be updated to be the earliest related contract rev. eff date (which is contract3).
        
        proj = [select Billing_Effective_Date__c from pse__Proj__c where id = :proj.Id];
        System.debug('The proj Biling Effective date is: ' + proj.Billing_Effective_Date__c);
        System.debug('The Cont Detail Effective date is: ' + contDetail3.Effective_Start_Date__c);        
        System.assert(proj.Billing_Effective_Date__c == contDetail3.Effective_Start_Date__c);

        List<Project_Contract__c> projContracts = [select Id from Project_Contract__c where Project__c = :proj.Id];
        //make sure that project contracts = 1 because 2 proj contracts should have been deleted.
        System.assert(projContracts != null && projContracts.size() == 1);

        // proj = [select Billing_Effective_Date__c from pse__Proj__c where id = :proj.Id];
        // System.debug('contract3.Revision_Effective_Start_Date__c='+contract3.Revision_Effective_Start_Date__c);
        // System.debug('proj.Billing_Effective_Date__c='+proj.Billing_Effective_Date__c);
        // make sure that the project billing effective date got updated to be the earlier proj contract date.
        // System.assert(proj.Billing_Effective_Date__c == contDetail3.Effective_Start_Date__c);
        
        //End of changes by shprasan
    } 
    
}