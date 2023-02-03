@isTest(seeAllData=false)

public class DocuSign_EsignIntermediateCntrlTest1{
    static User dmlUser = utilTestClass.getTestRunUser();
    static ApexPages.StandardController stdController;
          
   private static testmethod void onlyForCodeCoverage_1(){
    
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    Test.loadData(globalDescribe.get('GSM_Custom_Settings__c'), 'CS_GSM_Custom_Settings');
    OA_eSign_Intermediate__c e8 = new OA_eSign_Intermediate__c();
            e8.Name = 'SendEmailReminder';
            e8.Value__c = 'true';
            insert e8;
    
        Account acc2=utilTestClass.CreateAccount('Test acc__1');
        insert acc2;

        Opportunity opp = utilTestClass.CreateOpportunity('__Test_Oppty','1. Identify Need'); 
        opp.CloseDate = Date.today().addMonths(4);
        opp.CurrencyISOCode = 'USD';
        opp.AccountId = acc2.Id;
        insert opp;
        
        system.runas(dmlUser){
        Order_Approval__c oa = new Order_Approval__c();
        oa.Associated_Opportunity__c = opp.Id;
        oa.Order_Expires_Unless_Duly_Executed_By__c = Date.today().addMonths(8);
        insert oa;
        
        ApexPages.currentPage().getParameters().put('id',oa.Id);
        stdController=new ApexPages.StandardController(oa);
        
        DocuSign_ESignIntermediateController docEsign=new DocuSign_ESignIntermediateController();
        docEsign.validate();
        docEsign.cancel();
        docEsign.canceltoOppty();
        
        // insert docusign envelop
         dsfs__DocuSign_Envelope__c dsEnvelope = new dsfs__DocuSign_Envelope__c();
         dsEnvelope.dsfs__Source_Object__c =oa.Id;
         insert dsEnvelope;
    }

    // test class for ChangeOpportunityCurrencyController
    Test.startTest();
    ApexPages.StandardController stdCtrl = new ApexPages.StandardController(opp);

            ChangeOpportunityCurrencyController cocc = new ChangeOpportunityCurrencyController(stdCtrl);

            List<SelectOption> options = cocc.getCurrencies();

            Test.setCurrentPage(Page.SelectCurrencyPage);

            opp.CurrencyISOCode = 'INR';
            update opp;
            Test.stopTest();
            PageReference pageRef = cocc.convertCurrency();
         
    }
    
   /* public static testmethod void testConvertCurrency()
        {

            Test.startTest();
            Opportunity testOppty = SobjectRepository.getOpportunity();
    system.debug('swati'+testOppty);
            ApexPages.StandardController stdCtrl = new ApexPages.StandardController(testOppty);

            ChangeOpportunityCurrencyController cocc = new ChangeOpportunityCurrencyController(stdCtrl);

            List<SelectOption> options = cocc.getCurrencies();

            Test.setCurrentPage(Page.SelectCurrencyPage);

            testOppty.CurrencyISOCode = 'INR';
            Test.stopTest();
            PageReference pageRef = cocc.convertCurrency();

        }*/

}