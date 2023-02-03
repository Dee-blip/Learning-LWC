/**
 * @description       : 
 * @author            : manish
 * @team              : GSM
 * @last modified on  : 10-22-2021
 * @last modified by  : manish
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   01-04-2022   manish   Initial version
**/
@isTest(seeAllData=false)
public class l2qChimeCloneClassTest {
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
        
        CHIME_Contact__c chimeCon = new CHIME_Contact__c();
        chimeCon.Contact__c = con.Id;
        chimeCon.CHIME__c = chimeRecord.Id;
        insert chimeCon;
        
    }
    
    @isTest 
    static void getProductsForChimeTest(){
        Test.startTest();
        Chime__c chime = [Select id from Chime__c limit 1];
        l2qChimeCloneClass.getProductsForChime(chime.Id);
        Test.stopTest();
        
    }
    @isTest 
    static void clonePOCToFullIntegrationFormTest(){
        Test.startTest();
        Chime__c chime = [Select id,Opportunity__c from Chime__c limit 1];
        PAC_Product_Catalog__c pacProduct = [Select id from PAC_Product_Catalog__c limit 1];
        String productId = '["'+pacProduct.Id+'"]';
        List<CHIME_Product_Question__c> q1list =[Select id,Question_Text__c from CHIME_Product_Question__c where Form_Stage__c ='Gating'];
        CHIME_Product_Question__c q1 = q1list[0];
        List<CHIME_Product_Question__c> q2List =[Select id,Question_Text__c from CHIME_Product_Question__c where Form_Stage__c ='Scoping'];
        CHIME_Product_Question__c q2 = q2List[0];
        
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
        l2qChimeCloneClass.clonePOCToFullIntegrationForm(chime.Id,chime.Opportunity__c,productId,'Standard',true,'chime form name',false);
        Test.stopTest();
        
    }
    
    @isTest 
    static void clonePOCToPOCFormTest(){
        Test.startTest();
        Chime__c chime = [Select id,Opportunity__c from Chime__c limit 1];
        PAC_Product_Catalog__c pacProduct = [Select id from PAC_Product_Catalog__c limit 1];
        String productId = '["'+pacProduct.Id+'"]';
        List<CHIME_Product_Question__c> q1list =[Select id,Question_Text__c from CHIME_Product_Question__c where Form_Stage__c ='Gating'];
        CHIME_Product_Question__c q1 = q1list[0];
        List<CHIME_Product_Question__c> q2List =[Select id,Question_Text__c from CHIME_Product_Question__c where Form_Stage__c ='Scoping'];
        CHIME_Product_Question__c q2 = q2List[0];
        
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
        l2qChimeCloneClass.clonePOCToPOCForm(chime.Id,chime.Opportunity__c,'chime form name');
        Test.stopTest();
        
    }

}