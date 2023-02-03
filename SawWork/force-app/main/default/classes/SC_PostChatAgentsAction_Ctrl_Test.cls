/*=====================================================================================================+
Class name          :   SC_PostChatAgentsAction_Ctrl_Test 
Author              :   Pinkesh
Created             :   25-Sep-18
Purpose             :   This test class is used to cover code for classes and trigger
1. SC_PostChatAgentsAction_Ctrl (Class)
2. SC_LiveChatTranscript (Trigger)                   
=========================================================================================================*/
@isTest(seeAllData = False)
public class SC_PostChatAgentsAction_Ctrl_Test {
    static Account accRec;
    static List<Case> lCaseRec;
    static LiveChatVisitor visitor;
    static void createTestData(){
        utilTestClass.createCustomSettings();
        accRec = utilTestClass.CreateAccount('Test Account PostChat');
        insert accRec;
        
        Id amgRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('AMG').getRecordTypeId();
        lCaseRec = new List<Case>();
        for(Integer i = 0; i<4; i++){
            Case caseRec = new Case(Accountid = accRec.Id, Origin = 'AkaChat Luna', Subject = 'Test Chat', Description = 'Test Chat', RecordTypeId = amgRecordTypeId, Validation_Override__c = True);
            lCaseRec.add(caseRec);
        }
        insert lCaseRec;
        
        visitor = new LiveChatVisitor();
        insert visitor;
    }
    
    static testMethod void testmethod1(){
        createTestData();

        Test.startTest();
        List<LiveChatTranscript> lLiveChatTranscript = new List<LiveChatTranscript>();
        for(Integer i=0; i<4; i++){
            LiveChatTranscript liveChatTranscript = new LiveChatTranscript(CaseId = lCaseRec[i].id, LiveChatVisitorId = visitor.Id, StartTime = System.now(), EndTime = System.now().addSeconds(100));
            lLiveChatTranscript.add(liveChatTranscript);
        }
        insert lLiveChatTranscript;
        

        ApexPages.StandardController sc1 = new ApexPages.StandardController(new Case());
        ApexPages.currentPage().getParameters().put('Id',lCaseRec[0].Id);
        SC_PostChatAgentsAction_Ctrl sc_PostChatAgentsAction_Ctrl1 = new SC_PostChatAgentsAction_Ctrl(sc1);
        sc_PostChatAgentsAction_Ctrl1.techincalCaseResolved();
        sc_PostChatAgentsAction_Ctrl1.techincalCaseResolved();
        List<SelectOption> testResolutionValues = sc_PostChatAgentsAction_Ctrl1.resolutionValues;
        List<SelectOption> testSeverityValues = sc_PostChatAgentsAction_Ctrl1.severityValues;
        List<SelectOption> testReasonsWhyNotResolved = sc_PostChatAgentsAction_Ctrl1.reasonsWhyNotResolved;
        Boolean testHasError = sc_PostChatAgentsAction_Ctrl1.hasError;
        
        ApexPages.StandardController sc2 = new ApexPages.StandardController(new Case());
        ApexPages.currentPage().getParameters().put('Id',lCaseRec[1].Id);
        SC_PostChatAgentsAction_Ctrl sc_PostChatAgentsAction_Ctrl2 = new SC_PostChatAgentsAction_Ctrl(sc2);
        sc_PostChatAgentsAction_Ctrl2.amgCaseResolved();
        sc_PostChatAgentsAction_Ctrl2.amgCaseResolved();
        
        
        ApexPages.StandardController sc3 = new ApexPages.StandardController(new Case());
        ApexPages.currentPage().getParameters().put('Id',lCaseRec[2].Id);
        SC_PostChatAgentsAction_Ctrl sc_PostChatAgentsAction_Ctrl3 = new SC_PostChatAgentsAction_Ctrl(sc3);
        sc_PostChatAgentsAction_Ctrl3.techincalCaseNotResolved();
        sc_PostChatAgentsAction_Ctrl3.techincalCaseNotResolved();
        
        
        ApexPages.StandardController sc4 = new ApexPages.StandardController(new Case());
        ApexPages.currentPage().getParameters().put('Id',lCaseRec[3].Id);
        SC_PostChatAgentsAction_Ctrl sc_PostChatAgentsAction_Ctrl4 = new SC_PostChatAgentsAction_Ctrl(sc4);
        sc_PostChatAgentsAction_Ctrl4.amgCaseNotResolved();
        sc_PostChatAgentsAction_Ctrl4.amgCaseNotResolved();
        
        Test.stopTest();
        
    }
}