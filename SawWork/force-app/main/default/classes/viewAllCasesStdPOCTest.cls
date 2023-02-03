/***************************************************************************************************
* @author       Ashin Louis
* @date         7/FEB/2022
* @Class name   viewAllCasesStdPOCTest
* @JIRA         ESESP-6647
* @description  This class is used as test class for 'viewAllCasesStdPOC' Apex class
* @team         GSS
* Ver     Date           Author      Modification
* 1.0   09-20-2021     Ashin Louis   Created new test class for 'viewAllCasesStdPOC' Apex class
*****************************************************************************************************/

@isTest(seeAllData=false)
public class viewAllCasesStdPOCTest 
{
/***************************************************************************************************
* @author       Ashin Louis
* @date         7/FEB/2022
* @methodname   viewAllstdPOCCases
* @description  This methods is used to test the viewAllCasesStdPOC.getCases method
* @return       void
*****************************************************************************************************/
    @testSetup static void setupviewAllstdPOCCases()
    {

        utilTestClass.createCustomSettings();
        CHIME_GSS_Settings__c sett = new CHIME_GSS_Settings__c ();
        sett.Name = 'TestSetting';
        sett.Question_Admin_Email__c = 'abc@test.com';
        insert sett;
        
        //Account Creation
        Account acc = new Account();
        acc.Name = 'TestChimeAccount4';
        acc.BillingCountry = 'India4';
        acc.BillingState = 'DELHI4';
        acc.website = 'www.testchimeaccount4.com';
        insert acc;

        Contact con = new Contact();
        con.FirstName = 'Test1';
        con.LastName ='Contact1';
        con.Email ='testcon@akam1.com';
        con.Phone ='+12345678781';
        con.AccountId = acc.Id;
        insert con;

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
        chimeRecord.POC_Type__c='Standard-POC';
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
        qList.add(q1);
        
        CHIME_Product_Question__c q2 = new CHIME_Product_Question__c ();
        q2.CHIME_Product__c =pacProduct.Id;
        q2.Chime_Product_Template__c =template.Id;
        q2.template__c=template.Id;
        q2.Required__c =true;
        q2.Question_Text__c='q2';
        q2.Possible_Response__c='Yes';
        q2.Form_Stage__c ='Scoping';
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
         insert q4;
        
        Id pstRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('PST').getRecordTypeId();
        Id dsrRecordTypeId = Schema.SObjectType.Deal_Support_Request__c.getRecordTypeInfosByName().get('Pre-Sales Activity').getRecordTypeId();
        
        Deal_Support_Request__c newDsr = new Deal_Support_Request__c();
        newDsr.Request_Type__c='POC';
        newDsr.Account__c=acc.id;
        newDsr.Opportunity__c = oppty.id;
        newDsr.CHIME__c=chimeRecord.Id;
        newDsr.POC_Status__c='Planned';
        newDsr.SE__c=UserInfo.getUserId();
        newDsr.RVP__c=UserInfo.getUserId();
        newDsr.Start_Date__c = system.today();
        newDsr.Product__c='Cloudlets';
        newDsr.Success_Criteria__c='demo';
        newDsr.Approval_Status__c='Approved';

        insert newDsr;
        
        case newCase = new case();
        newCase.AccountId = acc.id;
        newCase.Description = 'demo description';
        newCase.Subject ='demo subject' ;
        newCase.Opportunity__c = oppty.id;
        newCase.Severity__c = '3';
        newCase.PST_Case_Product__c = 'Cloudlets';
        newCase.RecordTypeId = pstRecordTypeId;
        newCase.Service__c = 'Trial / PoC';
        newCase.Deal_Support_Request__c = newDsr.id;
        newCase.Request_Type__c = 'PoC(PST)';
        newCase.Chime_Form__c = chimeRecord.Id;
        newCase.Origin = 'Autogen';
        newCase.Chime_Case_Type__c = 'Chime PST Case';
        insert newCase;
    }
        
        @isTest static void viewAllstdPOCCases(){
        test.startTest();
            chime__c chimeRecord = [Select id from chime__c where CHIME_Name__c = 'Chime Test Record' LIMIT 1];
        List<Case> lstCases = viewAllCasesStdPOC.getCases(chimeRecord.Id);
        system.assertEquals(1, lstCases.size());
        test.stopTest();
        }
         
    
    

}