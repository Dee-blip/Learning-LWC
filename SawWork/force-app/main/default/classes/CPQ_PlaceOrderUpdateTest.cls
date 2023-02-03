@IsTest
public class CPQ_PlaceOrderUpdateTest {
    
    @TestSetup
    static void setup() {

        CPQ_TestDataFactory.createCustomSettings();
        CPQ_TestDataFactory.createLegalEntities();
        CPQ_TestQuoteSetupMethods.simpleAutonomyQuoteSetup();
        //gsm team data setup
        utilTestClass.createCustomSettings();

        SBQQ__Quote__c testQuote = [SELECT Id, SBQQ__Opportunity2__c FROM SBQQ__Quote__c LIMIT 1];

        Opportunity testOpp = [SELECT Id, AccountId FROM Opportunity LIMIT 1];

        Order_Approval__c testOA = [SELECT Id FROM Order_Approval__c 
                                    WHERE Associated_Opportunity__c =: testQuote.SBQQ__Opportunity2__c LIMIT 1];

        //create an OM Case and associated AD similar to the CPQ Place Order - Partner flow.
        Case testCase = new CPQ_TestDataFactory.CpqOMCaseBuilder(testOpp, testOA, 'Order_Approval_Order_Management')
                                                                .withOrderType('New Service Order')
                                                                .withOrigin('Autogen')
                                                                .withStatus('In Progress')
                                                                .withValidationOverride(TRUE).saveRecord();
        
        Approval_Details__c testAD = new CPQ_TestDataFactory.CpqApprovalDetailBuilder(testOA, testCase)
                                                                                    .withRequestType('OM Order Approval')
                                                                                    .withDescription('Created by Autonomy system for New Service Order.')
                                                                                    .withStatus('Auto-approved')
                                                                                    .withApproverNotes('New Service Order - Auto-approved.')
                                                                                    .withValidationOverride(TRUE).saveRecord();
        System.debug(LoggingLevel.INFO, '--testAD: '+testAD);

    }

    @IsTest
    public static void testPlaceOrderPositive() {

        Test.startTest();

        List<CPQ_PlaceOrderUpdate.CPQ_PO_Request> testPORequestList = new List<CPQ_PlaceOrderUpdate.CPQ_PO_Request>();
        List<CPQ_PlaceOrderUpdate.CPQ_PO_Response> testPOResponseList = new List<CPQ_PlaceOrderUpdate.CPQ_PO_Response>();

        CPQ_PlaceOrderUpdate.CPQ_PO_Request testPORequest = createPORequest(FALSE);
        testPORequestList.add(testPORequest);

        testPOResponseList = CPQ_PlaceOrderUpdate.createRecords(testPORequestList);
        System.debug(LoggingLevel.INFO, '--testPOResponseList: '+testPOResponseList[0]);

        System.assertNotEquals(null, testPOResponseList, 'The response should not be null.');
        System.assertEquals('Update successfull', testPOResponseList[0].success, 'The update should be successfull.');

        Test.stopTest();
    }
    
    @IsTest
    public static void testPlaceOrderNegative() {

        Test.startTest();

        List<CPQ_PlaceOrderUpdate.CPQ_PO_Request> testPORequestList = new List<CPQ_PlaceOrderUpdate.CPQ_PO_Request>();
        List<CPQ_PlaceOrderUpdate.CPQ_PO_Response> testPOResponseList = new List<CPQ_PlaceOrderUpdate.CPQ_PO_Response>();

        CPQ_PlaceOrderUpdate.CPQ_PO_Request testPORequest = createPORequest(TRUE);
        testPORequestList.add(testPORequest);

        testPOResponseList = CPQ_PlaceOrderUpdate.createRecords(testPORequestList);
        System.debug(LoggingLevel.INFO, '--testPOResponse: '+testPOResponseList[0]);

        System.assertNotEquals(null, testPOResponseList, 'The response should not be null.');
        System.assertNotEquals(null, testPOResponseList[0].error, 'The response should not have error variable as null.');
        System.assertEquals('', testPOResponseList[0].success, 'The update should not be successfull.');

        Test.stopTest();
    }

    private static SBQQ__Quote__c getQuote(){
        return [SELECT Id, SBQQ__Opportunity2__c, SBQQ__Account__c FROM SBQQ__Quote__c LIMIT 1];
    }

    private static Opportunity getOpportunity(){
        return [SELECT Id FROM Opportunity LIMIT 1];
    }

    private static Order_Approval__c getOrderApproval(SBQQ__Quote__c testQuote){
        return [SELECT Id, Associated_Opportunity__c FROM Order_Approval__c 
                WHERE Associated_Opportunity__c =: testQuote.SBQQ__Opportunity2__c LIMIT 1];
    }

    private static Case getCase(){
        return [SELECT Id FROM Case LIMIT 1];
    }

    private static Approval_Details__c getApprovalDetails(Case testCase){
        return [SELECT Id FROM Approval_Details__c WHERE Related_To__c = :testCase.Id LIMIT 1];
    }

    private static CPQ_PlaceOrderUpdate.CPQ_PO_Request createPORequest(Boolean createError){

        SBQQ__Quote__c testQuote = getQuote();
        Opportunity testOpp = getOpportunity();
        // Order_Approval__c testOA = getOrderApproval(testQuote);
        Case testCase = getCase();
        Approval_Details__c testAD = getApprovalDetails(testCase);

        if(createError) {
            //update case status to Closed to create error
            testCase.Status = 'Closed-Auto Approved';
        }

        CPQ_PlaceOrderUpdate.CPQ_PO_Request testPORequest = new CPQ_PlaceOrderUpdate.CPQ_PO_Request();
        testPORequest.approvalDetails = new List<Approval_Details__c>{testAD};
        testPORequest.relatedCases = new List<Case>{testCase};
        testPORequest.poaDocuments = new List<Partner_Order_Acceptance_Document__c>();
        testPORequest.relatedQuote = testQuote;
        testPORequest.relatedOpportunity = testOpp;
        
        return testPORequest;
    }
}