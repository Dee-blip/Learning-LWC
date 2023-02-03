@isTest
public class Sales_ERSS_FormControllerTest {
    
    public Sales_ERSS_FormControllerTest() {
        
    }
    
    
    @testSetup static void setup() 
    {
            /*GSM_Custom_Settings__c gs = new GSM_Custom_Settings__c();
            gs.Name = 'CRM_Integration';
            gs.Value__c = '005A0000000NHQc';
            insert gs;
       
        Survey__c template = new Survey__c(Name = 'Unique_Template_001', RecordTypeId = Schema.SObjectType.Survey__c.getRecordTypeInfosByDeveloperName().get('RSS_Template').getRecordTypeId(), UniqueName__c = GuidUtil.NewGuid(), Submit_Response__c = ' temp ', Version__c = 0);
        insert template;
       
        Survey_Question_Group__c section =  new Survey_Question_Group__c(UniqueName__c = GuidUtil.NewGuid(),Name = 'Section_Unique',Order_Number__c = 0,Survey__c = template.Id);
        insert section;
    
        Survey_Question__c question  = new Survey_Question__c(QuestionDescription__c = 'test',Survey__c = template.Id,Question__c = 'Quest',Type__c = 'Picklist',Required__c = true,OrderNumber__c =0,UniqueName__c = GuidUtil.NewGuid(),Survey_Question_Group__c = section.Id);
        Insert question; */
    }
    
    static testmethod void addProductsToRSSFormTest(){
        
        // Create Account, Opportunity
         PSA_TestUtility testUtil = new PSA_TestUtility();
       // Account acct = testUtil.newAccount(true);  
       //Added to avoid duplicate rule and validation error
       Account acct = new Account();
       acct.name='Erssacc';
       acct.website='www.erss.com';
       insert acct;
        User usr = testUtil.newUserSysAdmin(true);
        usr.ERSS_Super_User__c = true;
        update usr;
        
        User newOwner = testUtil.newUserSysAdmin(true);
        Opportunity opp = new Opportunity();
        opp.Name = 'TestOpp';
        opp.AccountId = acct.id;
        opp.StageName = 'stageName';
        opp.CloseDate = Date.today();
        opp.CurrencyIsoCode = 'USD';
        opp.Validation_Override__c = TRUE;
        opp.Carrier_Application__c='Retail CDN services';
        insert opp;        
        
        //Creating a team member with role as TSP
        OpportunityTeamMember otm = new OpportunityTeamMember();
        otm.OpportunityId = opp.id;
        otm.UserId = usr.id;
        otm.TeamMemberRole = 'Technical Sales - Primary';
        //otm.OpportunityAccessLevel = 'Read Only';
        insert otm;
        
        
        AccountTeamMember atmn = new AccountTeamMember();
            atmn.AccountId = acct.Id;
            atmn.UserId  = newOwner.Id;
            atmn.TeamMemberRole = 'Sales - Primary';
            insert atmn;
       
        
        //Create new Template
        Survey__c rSSTemplate = new Survey__c();
        rSSTemplate.Name ='Apple';
        rSSTemplate.RecordTypeId = [select id from RecordType where name = 'RSS Template' limit 1][0].id; //Need to have a record Type RSS Template
        rSSTemplate.UniqueName__c = GuidUtil.NewGuid();
        rSSTemplate.Submit_Response__c = ' temp ';
        rSSTemplate.Version__c = 1;
        rSSTemplate.RSS_Published__c = true ;
        insert rSSTemplate;
        GSM_Custom_Settings__c gs = new GSM_Custom_Settings__c();
            gs.Name = 'CRM_Integration';
            gs.Value__c = '005A0000000NHQc';
            insert gs;
        Survey_Question_Group__c section =  new Survey_Question_Group__c(UniqueName__c = GuidUtil.NewGuid(),
                                                                         Name = 'Section_Unique',
                                                                         Order_Number__c = 0,
                                                                         Survey__c = rSSTemplate.Id);
        insert section;
    
        Survey_Question__c question  = new Survey_Question__c(QuestionDescription__c = 'test',
                                                              Survey__c = rSSTemplate.Id,
                                                              Question__c = 'Quest',
                                                              Type__c = 'Picklist',
                                                              Required__c = true,
                                                              OrderNumber__c =0,
                                                              UniqueName__c = GuidUtil.NewGuid(),
                                                              Survey_Question_Group__c = section.Id);
        insert question;
        
        Test.startTest();
        
        // Create new form
            eRSS__c erss = new eRSS__c();
            erss.name = 'eRSS';
            erss.From_Address__c = 'test@akamai.com.invalid';
            
            insert erss;
        
        RSS_Form__c form = new RSS_Form__c();
        form.name = 'test';
        form.Opportunity__c = opp.Id;
        insert form;
        // Get Products to add
        List<Survey__c> products = Sales_ERSS_FormController.getProductList();
        System.assertNotEquals(products.size(), 0);
        List<String> productListId = new List<String>();
        productListId.add(products[0].Id);
       
        Sales_ERSS_FormController.addProductsToRSSForm( form.Id, productListId);
        Sales_ERSS_FormController.getSelectedProductList(form.Id);
        // Save the form
        
        
        //Publish the form
        Sales_ERSS_FormController.publishNewForm(form.Id, 'Publishing once');
        String revisedFormId = Sales_ERSS_FormController.createRevisedForm(form.Id);
        Sales_ERSS_FormController.publishNewForm(revisedFormId, 'Publishing twice');
        System.assertEquals(Sales_ERSS_FormController.getPreviousVersionsOfRSSForm(form.Id).size(),1);
        
        // Check RSS Questions
        //Sales_ERSS_FormController.getRSSQuestionaire( form.Id);
        Sales_ERSS_FormController.getOpportunityFields(opp.Id);
        Sales_ERSS_FormController.getOpportunityFieldsFromForm(form.Id);
        Sales_ERSS_FormController.getFormWriteAccess(form.Id);
        Sales_ERSS_FormController.updateProductTemplates(form.Id);
        Sales_ERSS_FormController.changeOwnerOfRSSForm(form.Id,  newOwner.Id,'Ownership change');
        Sales_ERSS_FormController.updateContactJson(form.Id, '{}');
        Sales_ERSS_FormController.getPublishedFormsUnderOpportunity(opp.Id);
        
        
        Test.stopTest();    
            
    }
        

}