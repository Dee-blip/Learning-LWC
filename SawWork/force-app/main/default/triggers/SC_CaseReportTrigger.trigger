trigger SC_CaseReportTrigger on SC_Case_Report__c (before update, before insert) {
    SC_TriggerHandlerAbstract caseReportHandler = new SC_CaseReportTriggerHandler(); 
    caseReportHandler.process();
}