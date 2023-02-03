/***
    PSA_ProjectContractLineItemActions_Test
    @author Liz Ichihashi
    @Description : This Class contains methods to test PSA_ProjectContractLineItemActions
                   which contains methods called from PSA_ProjectContractLineItem_Trigger.
                   One method (on before delete) prevents deletes when there is a related Milestone or Assignment.
                   One method (on after delete) checks to see if any childless Project Contract records can
                   be deleted.

    @History
    --Developer           --Date            --Change
    Liz Ichihashi         7/04/2013     Created the class.
    Sharath Prasanna      2/04/2015     Changed the function testSuccessfulDeleteOfOneLine, commented delete.
*/
@isTest(SeeAllData=false)
public with sharing class PSA_ProjectContractLineItemActions_Test {

    static
    {
        // if( SC_BOCC_Setup__c.getValues('BOCC') == null)
        // {
        //     SC_BOCC_Setup__c scSetting = new SC_BOCC_Setup__c();
        //     scSetting.Name = 'BOCC';
        //     scSetting.Entitlement_Process_Id_Proactive__c = '5520f000000fxY0AAI';
        //     scSetting.Entitlement_Process_Id_Reactive__c = '5520f000000fxY5AAI';
        //     scSetting.Product_Id__c = 'M-LC-160618';
        //     insert scSetting;
        // }
    }
    /* this rule was added after the logic was already setup to handle multiple... */
    public static testMethod void testAttemptToSaveMultipleContractLineItemsToProject() {

    }

    public static testMethod void testSuccessfulDelete() {
        PSA_TestUtility testUtil = new PSA_TestUtility();
        Account acct = testUtil.newAccount(true);
        pse__Region__c reg = testUtil.newRegionMaster(true);
        User usr = testUtil.newUserSysAdmin(true);
        Contact resource = testUtil.newResource(true, acct.Id, usr.Id);
        Merge_Contract_Header__c contract = testUtil.newContract(true, acct.Id, '123','456',null,System.today(), System.today().addDays(50));
        Merge_Contract_Detail__c contDetail = testUtil.newContractDetail(true, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        pse__Practice__c pract = testUtil.newPracticeMaster(true);
        //Id practId = [select Id from pse__Practice__c where name = 'Security Services'].Id;
        pse__Proj__c proj = testUtil.newProject(true,reg.id,pract.Id, true, 'One-Time: Fixed Price', resource.Id, acct.Id);
        Project_Contract__c projContract = testUtil.newProjectContract(true, proj.Id, contract.Id, acct.Id);
        Project_Contract_Line_Item__c projContractLineItem = testUtil.newProjectContractLineItem(true, proj.Id, contract.Id, contDetail.Id, projContract.Id);
        projContractLineItem.Valid_Delete__c = true;
        delete projContractLineItem;

        List<Project_Contract__c> projContracts = [select Id from Project_Contract__c where Project__c = :proj.Id];
        System.assert(projContracts != null && projContracts.size() == 0);
        List<Project_Contract_Line_Item__c> projContractLineItems = [select Id from Project_Contract_Line_Item__c where Project__c = :proj.Id];
        System.assert(projContractLineItems != null && projContractLineItems.size() == 0);
    }

    public static testMethod void testSuccessfulDeleteOfOneLine() {
        // PSA_TestUtility testUtil = new PSA_TestUtility();
        // Account acct = testUtil.newAccount(true);
        // pse__Region__c reg = testUtil.newRegionMaster(true);
        // User usr = testUtil.newUserSysAdmin(true);
        // Contact resource = testUtil.newResource(true, acct.Id, usr.Id);
        // Merge_Contract_Header__c contract = testUtil.newContract(true, acct.Id, '123','456',null,System.today(), System.today().addDays(50));
        // Merge_Contract_Detail__c contDetail = testUtil.newContractDetail(true, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        // Merge_Contract_Detail__c contDetail2 = testUtil.newContractDetail(true, 'test2','test2',contract.Id, System.today(), System.today().addDays(50));
        // pse__Practice__c pract = testUtil.newPracticeMaster(true);
        // //Id practId = [select Id from pse__Practice__c where name = 'Security Services'].Id;
        // pse__Proj__c proj = testUtil.newProject(true,reg.id,pract.Id,true, 'One-Time: Fixed Price', resource.Id, acct.Id);
        // Project_Contract__c projContract = testUtil.newProjectContract(true, proj.Id, contract.Id, acct.Id);
        // Project_Contract_Line_Item__c projContractLineItem = testUtil.newProjectContractLineItem(true, proj.Id, contract.Id, contDetail.Id, projContract.Id);
        // Project_Contract_Line_Item__c projContractLineItem2 = testUtil.newProjectContractLineItem(true, proj.Id, contract.Id, contDetail2.Id, projContract.Id);
        // Start of Changes by shprasan : commented the delete: This is taken care of in the trigger
        //delete projContractLineItem;
        // End of changes by shprasan
        //make sure that project contract record is not deleted because there is still a contract detail line associated to project for that contract id.
        // List<Project_Contract__c> projContracts = [select Id from Project_Contract__c where Project__c = :proj.Id];
        // System.assert(projContracts != null && projContracts.size() == 1);
        // List<Project_Contract_Line_Item__c> projContractLineItems = [select Id from Project_Contract_Line_Item__c where Project__c = :proj.Id];
        // System.assert(projContractLineItems != null && projContractLineItems.size() == 1);
    }

    public static testMethod void testDeleteFailWithMilestone() {
        PSA_TestUtility testUtil = new PSA_TestUtility();
        Account acct = testUtil.newAccount(true);
        pse__Region__c reg = testUtil.newRegionMaster(true);
        User usr = testUtil.newUserSysAdmin(true);
        Contact resource = testUtil.newResource(true, acct.Id, usr.Id);
        Merge_Contract_Header__c contract = testUtil.newContract(true, acct.Id, '123','456',null,System.today(), System.today().addDays(50));
        Merge_Contract_Detail__c contDetail = testUtil.newContractDetail(true, 'Professional Services','Professional Services',contract.Id, System.today(), System.today().addDays(50));
        pse__Practice__c pract = testUtil.newPracticeMaster(true);
        //Id practId = [select Id from pse__Practice__c where name = 'Security Services'].Id;
        pse__Proj__c proj = testUtil.newProject(true,reg.id,pract.Id,true, 'One-Time: Fixed Price', resource.Id, acct.Id);
        Project_Contract__c projContract = testUtil.newProjectContract(true, proj.Id, contract.Id, acct.Id);
        Project_Contract_Line_Item__c projContractLineItem = testUtil.newProjectContractLineItem(true, proj.Id, contract.Id, contDetail.Id, projContract.Id);
        pse__Milestone__c milestone = testUtil.newMilestone(false, proj.Id,  100, System.today());
        milestone.Project_Contract_Line_Item__c = projContractLineItem.Id;
        insert milestone;
        //Sujay : 22.2.1 coverage for PSA_ProjectContractLineItemActions : checkForMilestonesOrAssignmentsBeforeDelete
        Map<Id, Project_Contract_Line_Item__c> oldMap= new Map<Id, Project_Contract_Line_Item__c>();
        oldMap.put(projContractLineItem.Id, projContractLineItem);
        PSA_ProjectContractLineItemActions.checkForMilestonesOrAssignmentsBeforeDelete(oldMap);
        List<Project_Contract_Line_Item__c> lineItemList = new List<Project_Contract_Line_Item__c>();
        lineItemList.add(projContractLineItem);
        PSA_ProjectContractLineItemActions.checkForExistingContractLineItemOnProject(lineItemList); 
        boolean excCaught = false;
        try {
            delete projContractLineItem;
        } catch (Exception e) {
            excCaught = true;
        }
        System.assert(excCaught);
        List<Project_Contract__c> projContracts = [select Id from Project_Contract__c where Project__c = :proj.Id];
        System.assert(projContracts != null && projContracts.size() == 1);
        List<Project_Contract_Line_Item__c> projContractLineItems = [select Id from Project_Contract_Line_Item__c where Project__c = :proj.Id];
        System.assert(projContractLineItems != null && projContractLineItems.size() == 1);

    }
}