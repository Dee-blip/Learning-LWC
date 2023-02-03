/**
 * @description       : 
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 04-01-2022
 * @last modified by  : apyati
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   12-08-2021   apyati   Initial Version
**/
@isTest
public class L2Q_CHIME_AuditTrailTest {

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
        
        PAC_Product_Catalog__c pacProduct = new PAC_Product_Catalog__c();
        pacProduct.Product_Name__c = 'Test Product';
        pacProduct.Is_Available_For_Chime__c = true;
        pacProduct.Phase__c = 'Beta';
        insert pacProduct;
        
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
        chimeRecord.Stage__c = 'Integration';
		chimeRecord.Status__c = 'Reopened';
        insert chimeRecord;
        
        //Template
        Chime_Product_Template__c template = new Chime_Product_Template__c();
        template.Product__c= pacProduct.Id;
        template.Is_Latest__c= true;
        insert template;
        
        //CPA
        Chime_Product_Association__c newCPA = new Chime_Product_Association__c(CHIME_Product__c=pacProduct.Id,CHIME__c=chimeRecord.Id, Chime_Product_Template__c=template.id);
        insert newCPA;
        
        List<CHIME_Product_Question__c> qList = new List<CHIME_Product_Question__c>();
        CHIME_Product_Question__c q1 = new CHIME_Product_Question__c ();
        q1.CHIME_Product__c =pacProduct.Id;
        q1.Chime_Product_Template__c =template.Id;
        q1.template__c=template.Id;
        q1.Required__c =true;
        q1.Question_Text__c='q1';
        q1.Possible_Response__c='Yes';
        q1.Form_Stage__c ='Gating';
        q1.Serial_Number__c = 1;
        q1.Section_Serial_Number__c = 1;
        q1.Expected_Response__c = 'q1';
        qList.add(q1);
        
        CHIME_Product_Question__c q2 = new CHIME_Product_Question__c ();
        q2.CHIME_Product__c =pacProduct.Id;
        q2.Chime_Product_Template__c =template.Id;
        q2.template__c=template.Id;
        q2.Required__c =true;
        q2.Question_Text__c='q2';
        q2.Possible_Response__c='Yes';
        q2.Form_Stage__c ='Scoping';
        q2.Serial_Number__c = 2;
        q2.Section_Serial_Number__c = 1;
        q2.Expected_Response__c = 'q2';
        qList.add(q2);
        insert qList;

        CHIME_Product_Question__c q3 = new CHIME_Product_Question__c ();
        q3.CHIME_Product__c =pacProduct.Id;
        q3.Chime_Product_Template__c =template.Id;
        q3.template__c=template.Id;
        q3.Question_Text__c='q3';
        q3.Required__c =true;
        q3.Possible_Response__c='Yes';
        q3.Form_Stage__c ='Scoping';
        q3.parent_question__c = q2.id;
        q3.Expected_Response__c = 'Yes';
        q3.Serial_Number__c = 3;
        q3.Section_Serial_Number__c = 1;
        q3.Expected_Response__c = 'q3';
        insert q3;

        CHIME_Product_Question__c q4 = new CHIME_Product_Question__c ();
        q4.CHIME_Product__c =pacProduct.Id;
        q4.Chime_Product_Template__c =template.Id;
        q4.template__c=template.Id;
        q4.Required__c =false;
        q4.Question_Text__c='q4';
        q4.Possible_Response__c='Yes';
        q4.Form_Stage__c ='Gating';
        q4.parent_question__c = q1.id;
        q4.Expected_Response__c = 'Yes';
        q4.Serial_Number__c = 4;
        q4.Section_Serial_Number__c = 1;
        q4.Expected_Response__c = 'q4';
        insert q4;
        
        CHIME_Product_Question__c q5 = new CHIME_Product_Question__c ();
        q5.CHIME_Product__c =pacProduct.Id;
        q5.Chime_Product_Template__c =template.Id;
        q5.template__c=template.Id;
        q5.Required__c =true;
        q5.Question_Text__c='q3';
        q5.Possible_Response__c='Yes';
        q5.Form_Stage__c ='Scoping';
        q5.Section__c = 'Section2';
        q5.Parent_Question__c = q2.id;
        q5.Expected_Response__c = 'q5';
        q5.Serial_Number__c = 5;
        q5.Section_Serial_Number__c = 1;
        insert q5;
        
        Case c = new Case();
        c.AccountId = acc.Id;
        c.Chime_Form__c = chimeRecord.Id;
        c.Chime_Case_Type__c = 'Integration Case';
        insert c;
        
    }
    @isTest static void testProductSpecificFormAuditTrails() {
        
        Test.startTest();
        Chime__c chime = [Select id from Chime__c limit 1];
        Chime_Product_Association__c  chimeprod =[Select id,Product_Implementation_Mode__c from Chime_Product_Association__c limit 1];
        

        CHIME_Product_Question__c q1 =[Select id from CHIME_Product_Question__c where Form_Stage__c ='Gating' and Expected_Response__c='q1'];
        CHIME_Product_Question__c q2 =[Select id from CHIME_Product_Question__c where Form_Stage__c ='Scoping' and Expected_Response__c='q2'];
        
        chime.Stage__c='Integration';
        chime.Status__c  = 'Reopened';
        chime.Reopen_Reason__c='Properties Addition';
        update chime;

        chimeprod.Product_Implementation_Mode__c = 'Standard';
        update chimeprod;
        
        List<CHIME_Response__c> rList = new List<CHIME_Response__c>();
        CHIME_Response__c r1 = new CHIME_Response__c ();
        r1.CHIME__c =chime.Id;
        r1.CHIME_Product_Question__c =q1.Id;
        r1.Response__c ='Yes';
        rList.add(r1);
        
        CHIME_Response__c r2 = new CHIME_Response__c ();
        r2.CHIME__c =chime.Id;
        r2.CHIME_Product_Question__c =q2.Id;
        r2.Response__c ='Yes';
        rList.add(r2);
        Insert rList;

        Map<String, List<CHIME_Audit_Trail__c>> trails = L2Q_CHIME_AuditTrail.getProductSpecificFormAuditTrails(chime.id);
        System.assert(trails.size()>0);
        List<CHIME_Audit_Trail__c> trailsRes = L2Q_CHIME_AuditTrail.getAuditTrails(r2.id);
        System.assert(trailsRes.size()>0);
        delete rList;
        Test.stopTest();
    }
}