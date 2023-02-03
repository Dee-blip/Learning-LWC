@istest
public class l2q_chimeNotificationBatchTest {

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
        
    }
    @isTest
    static void batchTest(){
        
        Chime__c chime = [Select id from Chime__c limit 1];
        CHIME_Product_Question__c q1 =[Select id from CHIME_Product_Question__c where Form_Stage__c ='Gating'];
        CHIME_Product_Question__c q2 =[Select id from CHIME_Product_Question__c where Form_Stage__c ='Scoping'];
        
        List<CHIME_Response__c> rList = new List<CHIME_Response__c>();
        CHIME_Response__c r1 = new CHIME_Response__c ();
        r1.CHIME__c =chime.Id;
        r1.CHIME_Product_Question__c =q1.Id;
        r1.Response__c ='Yes';
        r1.Response_by_Customer__c = true;
        r1.notified_SE__c= false; 
        rList.add(r1);
        
        CHIME_Response__c r2 = new CHIME_Response__c ();
        r2.CHIME__c =chime.Id;
        r2.CHIME_Product_Question__c =q2.Id;
        r2.Response__c ='Yes';
        r2.Response_by_Customer__c = true;
        r2.notified_SE__c= false; 
        rList.add(r2);
        Insert rList;
        Test.startTest();
        l2q_chimeNotificationBatch bat = new l2q_chimeNotificationBatch();
        Id batchId = Database.executeBatch(bat);
        
        Test.stopTest();
    }
}