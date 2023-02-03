/*---------------------------------------------------------------------------------
* Test Class Name      : SC_AttachAccuracyController_TestClass
* Developer Name       : Vikas 
* Date                 : 29th Nov,2017
* JIRA                 : ESESP-781 
* Classes              : SC_AttachAccuracyCheckController
---------------------------------------------------------------------------------*/ 
@isTest(seeAllData=false)
public class SC_AttachAccuracyController_TestClass {
    @testSetup static void setupTestData()
    {
        utilTestClass.createCustomSettings();  
    }
    public static testmethod void accuracyCheck(){
        User techManager = [SELECT Id,KCS_Level__c FROM User WHERE Isactive = TRUE AND Profile.Name = 'Support - Tech Support Manager' LIMIT 1];
        
        if(techManager.KCS_Level__c == Null){
        	techManager.KCS_Level__c = 'KCS Coach';
        	update techManager;
        }
        
        System.runAs(techManager)
        {
            Id techRecTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
            
            List<Case> techCaseL = new List<Case>();
            Case techCase = new Case();
            techCase.RecordTypeId = techRecTypeId;
            techCase.Origin = 'Email';
            techCase.Sub_Type__c = 'Product Support';
            techCase.Work_Type__c = 'Reactive';
            techCase.Article_Number_s__c = '12345,56789';
            techCase.Has_Article_Linked__c = true;
            techCaseL.add(techCase);
            
            insert techCaseL;
      
            Test.startTest();
            ApexPages.Standardcontroller caseCtrl = new ApexPages.Standardcontroller(techCase);
            SC_AttachAccuracyCheckController accuracyController = new SC_AttachAccuracyCheckController(caseCtrl);
            accuracyController.first();
            accuracyController.last();
            accuracyController.eachCaseID = techCase.id;
            accuracyController.saveAccuracyCheck();
            accuracyController.refreshPage();
            accuracyController.next();
            accuracyController.previous();
            Boolean b = accuracyController.hasNext;
            b = accuracyController.hasPrev; 
            Integer i = accuracyController.getPageNumber;
            i = accuracyController.getTotalPageNumber;
            Test.stopTest();
        }
    }
    public static testmethod void accuracyCheckDB(){
        User techManager = [SELECT Id,Name,KCS_Level__c FROM User WHERE Isactive = TRUE AND Profile.Name = 'Support - Tech Support Manager' LIMIT 1];
       
    	if(techManager.KCS_Level__c == Null){
        	techManager.KCS_Level__c = 'KCS Coach';
        	update techManager;
        }
        
        System.runAs(techManager)
        {
            Id techRecTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
            ApexPages.currentPage().getParameters().put('UN',techManager.Name);
            ApexPages.currentPage().getParameters().put('dateRange','7');
            List<Case> techCaseL = new List<Case>();
            Case techCase = new Case();
            techCase.RecordTypeId = techRecTypeId;
            techCase.Origin = 'Email';
            techCase.Sub_Type__c = 'Product Support';
            techCase.Work_Type__c = 'Reactive';
            techCase.Article_Number_s__c = '12345,56789';
            techCase.AKAM_Closed_Date__c = (system.now()).addDays(-2);
            techCase.OwnerId = techManager.id;
            techCase.Validation_Override__c = true;
            techCase.Status = 'Closed';
            techCaseL.add(techCase);
            
            insert techCaseL;
            
            Test.startTest();
            ApexPages.Standardcontroller caseCtrl = new ApexPages.Standardcontroller(techCase);
            SC_AttachAccuracyCheckController accuracyController = new SC_AttachAccuracyCheckController(caseCtrl);
            Test.stopTest();
        }
    }
}