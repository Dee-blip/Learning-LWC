/*=====================================================================================================+
Class name          :   SC_Escalation_LightningUtility_TC 
Author              :   Pinkesh Rathore
Created             :   14-Feb-19
Purpose             :   This is the Test class for SC Escalation Lightning Components
Test Class for      :   SC_Escalation_LightningUtility

Last Modified Developer                 Purpose            
============= ========================  =======
11-FEB-19     Pinkesh                   ESESP-1602
+=====================================================================================================*/

@isTest
public class SC_Escalation_LightningUtility_TC {
    @testSetup 
    static void datasetup(){
        
        utilTestClass.createCustomSettings();
        
        Account accRec = new Account(Name='Test Account IP Address',AKAM_Account_ID__c='Test-ABC-1234IPAddr',Type='Brand - Active');
        insert accRec; 
        
        Case newCase = new Case();
        newCase.Subject = 'TestCase';
        newCase.Description = 'TestDescription';
        newCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        newCase.validation_override__c = true;
        newCase.AccountId = accRec.Id;
        newCase.origin='Email';
        newCase.recent_update__c=true;
        insert newCase;
        
        //Creating CCare Escalation
        Engagement_Request__c newEscalation = new Engagement_Request__c();
        newEscalation.Subject__c = 'testescalation';
        newEscalation.Area__c = 'API';
        newEscalation.RecordTypeId = Schema.SObjectType.Engagement_Request__c.getRecordTypeInfosByName().get('CCare Technical Escalation').getRecordTypeId();
        newEscalation.Description__c = 'test';
        newEscalation.case__c = newCase.Id;
        insert newEscalation; 
        
    }
    
    @isTest
    static void Test_Lightning(){
        Engagement_Request__c esc = [Select id, case__c from Engagement_Request__c limit 1];
        test.startTest();
        
        SC_Escalation_LightningUtility.acceptCase(esc.id);
        SC_Escalation_LightningUtility.rejectEscalation(esc.id, 'Test');
        SC_Escalation_LightningUtility.acceptCase(esc.id);
        SC_Escalation_LightningUtility.getParentCaseId(esc.id);
        SC_Escalation_LightningUtility.getEscDetails(esc.id);
        SC_Escalation_LightningUtility.getDefaultEscRecType();
        SC_Escalation_LightningUtility.getEscRecordTypeName(Schema.SObjectType.Engagement_Request__c.getRecordTypeInfosByName().get('External Team').getRecordTypeId());
        test.stopTest();
    }
}