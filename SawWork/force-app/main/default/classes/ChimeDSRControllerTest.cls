/**
 * @description       : Test Class for ChimeDSRController
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 04-01-2022
 * @last modified by  : apyati
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   11-16-2021   apyati   SFDC-8653 Initial Version
**/

@isTest(seeAllData=false)
public class  ChimeDSRControllerTest {
    //static User
    static User dmlUser = utilTestClass.getTestRunUser();
        
    @testSetup
    static void setupMethod() {
        
        utilTestClass.createCustomSettings();
        CHIME_GSS_Settings__c sett = new CHIME_GSS_Settings__c ();
        sett.Name = 'TestSetting';
        sett.Question_Admin_Email__c = 'abc@test.com';
        insert sett;
        

        //Account Creation
        Account acc = new Account();
        acc.Name = 'TestChimeAccount';
        acc.BillingCountry = 'India';
        acc.BillingState = 'DELHI';
        acc.website = 'www.testchimeaccount.com';
        insert acc;

        

        Contact con = new Contact();
        con.FirstName = 'Test';
        con.LastName ='Contact';
        con.Email ='testcon@akam.com';
        con.Phone ='+1234567878';
        con.AccountId = acc.Id;
        insert con;


        Contact partnercon = new Contact();
        partnercon.FirstName = 'Test';
        partnercon.LastName ='Contact';
        partnercon.Email ='testpartnercon@akam.com';
        partnercon.Phone ='+1234567878';
        partnercon.AccountId = acc.Id;
        insert partnercon;


        
        Opportunity oppty = utilTestClass.CreateOpportunity('__ChimeTest Oppty','1. Identify Need');
        oppty.AccountId = acc.Id;
        oppty.CloseDate = Date.today().addMonths(4);
        insert oppty;
        
        CHIME__c chimeRecord = new CHIME__c();
        chimeRecord.Account__c = acc.id;
        chimeRecord.Opportunity__c = oppty.id;
        chimeRecord.CHIME_Name__c = 'Chime Test Record';
        chimeRecord.Implementation_Type__c = 'Standard';
        chimeRecord.Reopen_Reason__c ='Missing Data';
        insert chimeRecord;
        
      
       
        Deal_Support_Request__c dsr = new Deal_Support_Request__c();
        dsr.Opportunity__c = oppty.Id;
        dsr.RecordTypeId = Schema.SObjectType.Deal_Support_Request__c.getRecordTypeInfosByDeveloperName().get('Pre_Sales_Engagement').getRecordTypeId();
        dsr.Request_Type__c = 'POC';
        dsr.POC_Status__c = 'Planned';
        dsr.Start_Date__c = System.today();
        dsr.End_Date__c = System.today() + 5;
        dsr.Contract_Type__c = 'Out Clause';
        dsr.Success_Criteria__c = 'Success';
        dsr.Product__c = 'Adaptive Media Delivery';
        dsr.SE__c = dmlUser.Id;
        dsr.Notes__c = 'Test Data';
        dsr.Validation_Override__c = true;
        insert dsr;


            
        Deal_Support_Request__c dsr1 = new Deal_Support_Request__c();
        dsr1.Opportunity__c = oppty.Id;
        dsr1.RecordTypeId = Schema.SObjectType.Deal_Support_Request__c.getRecordTypeInfosByDeveloperName().get('Pre_Sales_Request').getRecordTypeId();
        dsr1.Request_Type__c = 'STG Specialist';
        dsr1.Request_Sub_Type__c = 'Gating Review';
        dsr1.Start_Date__c = System.today();
        dsr1.End_Date__c = System.today() + 5;
        dsr1.Product__c = 'Prolexic';
        dsr1.CHIME__c = chimeRecord.Id;
        dsr1.Notes__c = 'Test Data';
        dsr1.Validation_Override__c = true;
        insert dsr1;

    }

    @isTest 
    static void getChimeProductApprovalDSRsTest(){
        Test.startTest();
        CHIME__c chimerec = [Select Id from CHIME__c limit 1];
        list<Deal_Support_Request__c> lstdsr = ChimeDSRController.getChimeProductApprovalDSRs(chimerec.Id);
        Test.stopTest();
        system.assertEquals(1, lstdsr.size());
    }


    @isTest 
    static void getPOCDSRFields(){
        Test.startTest();
        CHIME__c chimerec = [Select Id from CHIME__c limit 1];
        map<string,List<string>> layoutfields=   ChimeDSRController.getLayoutFields('Deal_Support_Request__c');
        Test.stopTest();
        system.assert( layoutfields !=null);
    }


    @isTest 
    static void associateChimeDSRTest(){

        CHIME__c chimerec = [Select Id from CHIME__c limit 1];
        Opportunity opptyRec = [Select Id from Opportunity limit 1];

        Test.startTest();

        list<Deal_Support_Request__c> lstdsr = ChimeDSRController.getUnAssociatedChimePOCDSRs(chimerec.Id,opptyRec.Id);
        system.assertEquals(1, lstdsr.size());
        String message ='';

        message = ChimeDSRController.associateChimePOCDSRs(lstdsr,chimerec.Id);
        system.assertEquals('POC DSRs associated to Chime Successfullly',message);

        list<Deal_Support_Request__c> lstdsr1 = ChimeDSRController.getAssociatedChimePOCDSRs( chimerec.Id);
        system.assertEquals(1, lstdsr1.size());

        message = ChimeDSRController.disassociateChimePOCDSRs(lstdsr1);
        system.assertEquals('POC DSRs are removed from  Chime Successfullly',message);

        Test.stopTest();
    }

}