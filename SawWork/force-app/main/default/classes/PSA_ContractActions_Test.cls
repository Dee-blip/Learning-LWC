/***
    PSA_ContractActions_Test
    @author Liz Ichihashi
    @Description : This Class contains methods to test the PSA_ContractActions class which has methods 
                   that are called by PSA_Contract_Trigger
    @History
    --Developer           --Date            --Change
    Liz Ichihashi         7/04/2013     Created the class.     
    Sharath               6 Sep 2018    refactored the class  
*/
@isTest(SeeAllData=false)
public class PSA_ContractActions_Test 
{

    public static PSA_TestUtility testUtil ;
    public static pse__Region__c reg ;
    public static Account acct ;
    public static User usr ;
    public static Contact resource ;
    public static Opportunity opp ;
    public static List<OpportunityLineItem> lineItems ;
    public static pse__Practice__c pract ;
    public static Id practId ;
    public static pse__Proj__c proj ;
    public static Merge_Contract_Header__c contract ;
    public static Merge_Contract_Header__c contractEarlier ;
    public static Merge_Contract_Detail__c contDetail ;
    public static Merge_Contract_Detail__c contEarlierDetail ;
    public static Project_Contract__c projContract ;
    public static Project_Contract_Line_Item__c projContractLineItem ;

    static
    {
        // SC_BOCC_Setup__c scSetting = new SC_BOCC_Setup__c();
        // scSetting.Name = 'BOCC';
        // scSetting.Entitlement_Process_Id_Proactive__c = '5520f000000fxY0AAI';
        // scSetting.Entitlement_Process_Id_Reactive__c = '5520f000000fxY5AAI';
        // scSetting.Product_Id__c = 'M-LC-160618';
        // insert scSetting;

        createdata();
    }
    public static void createdata()
    {
        testUtil = new PSA_TestUtility();
        reg = testUtil.newRegionMaster(true);
        acct = testUtil.newAccount(true);        
        usr = testUtil.newUserSysAdmin(true);        
        resource = testUtil.newResource(true, acct.Id, usr.Id);
        pract = testUtil.newPracticeMaster(true);
        practId = pract.ID;
        proj = testUtil.newProject(true,reg.id,practId,true,'One-Time: Fixed Price', resource.Id, acct.Id);    
        contract = testUtil.newContract(true, acct.Id, '123','456',null,System.today(), System.today().addDays(50));
        contractEarlier = testUtil.newContract(true, acct.Id, '123','456',null,System.today(), System.today().addDays(40));
        contDetail = testUtil.newContractDetail(true, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        contEarlierDetail = testUtil.newContractDetail(true, 'test','test',contractEarlier.Id, System.today(), System.today().addDays(40));
        projContract = testUtil.newProjectContract(true, proj.Id, contract.Id, acct.Id);
        projContractLineItem = testUtil.newProjectContractLineItem(true, proj.Id, contract.Id, contDetail.Id, projContract.Id);


    }
    public static testMethod void testUpdateEffectiveDate() {

        Test.StartTest();
            //contract.Revision_Effective_Start_Date__c = System.today().addMonths(-4);
            contDetail.Effective_Start_Date__c = System.today().addMonths(-4);
            update contDetail;
            proj = [select Id, Billing_Effective_Date__c from pse__Proj__c where id = :proj.Id];
            System.assert(proj.Billing_Effective_Date__c == contDetail.Effective_Start_Date__c);

        Test.StopTest();
        
    }
    
    public static testMethod void testUpdateEffectiveDateOnContractSelect() {

        Test.StartTest();
            contDetail.Effective_Start_Date__c = System.today().addMonths(-4);
            update contDetail;
            proj = [select Id, Billing_Effective_Date__c from pse__Proj__c where id = :proj.Id];
            System.assert(proj.Billing_Effective_Date__c == contDetail.Effective_Start_Date__c);
        Test.StopTest();
        
    }

}