@isTest(seeAllData=false)
public class QuestionnaireControllerTest{
 
    @testSetup
    static void setupMethod(){
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
        q1.Serial_Number__c = 1;
        q1.Section_Serial_Number__c = 1;
        q1.Expected_Response__c = 'q1';
        qList.add(q1);
        
        CHIME_Product_Question__c q10 = new CHIME_Product_Question__c ();
        q10.CHIME_Product__c =pacProduct.Id;
        q10.Chime_Product_Template__c =template.Id;
        q10.template__c=template.Id;
        q10.Required__c =true;
        q10.Question_Text__c='q1';
        q10.Possible_Response__c='Yes';
        q10.Form_Stage__c ='Gating';
        q10.Help_Text__c='help';
        q10.Language__c='English';
        q10.Serial_Number__c = 1;
        q10.Section_Serial_Number__c = 1;
        q10.Expected_Response__c = 'q10';
        q10.Section__c = 'Section2';
        q10.Question_Type__c='Text';
        q10.Question_Status__c = 'Published';
        q10.Restricted__c =false;
        //q1.Chime_Product_Template__c = template.Id;
        q10.Dependent_Question_Serial__c = 1;
        qList.add(q10);
        
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
    }
    
    
    public static testmethod void testQuestionnaireController(){
        Chime__c chime = [Select id from Chime__c limit 1];
        
        CHIME_Product_Question__c q10 =[Select id,CHIME_Product__c,Chime_Product_Template__c,template__c,Required__c,Question_Text__c,Possible_Response__c,
                                       Form_Stage__c,Help_Text__c,Language__c,Serial_Number__c,Section_Serial_Number__c,Expected_Response__c,Section__c,
                                       Question_Type__c,Question_Status__c,Restricted__c,Dependent_Question_Serial__c  from CHIME_Product_Question__c where Language__c='English'][0];
        CHIME_Product_Question__c q1 =[Select id,Form_Stage__c from CHIME_Product_Question__c where Form_Stage__c ='Gating' and Expected_Response__c='q1'][0];
        CHIME_Product_Question__c q2 =[Select id from CHIME_Product_Question__c where Form_Stage__c ='Scoping' and Expected_Response__c='q2'][0];
        CHIME_Product_Question__c q4 =[Select id from CHIME_Product_Question__c where Form_Stage__c ='Gating' and Expected_Response__c='q4'][0];
        CHIME_Product_Question__c q5 =[Select id from CHIME_Product_Question__c where Form_Stage__c ='Scoping' and Expected_Response__c='q5'][0];
        //CHIME_Product_Question__c q10 =[Select id from CHIME_Product_Question__c where Language__c='English'][0];
        
        PAC_Product_Catalog__c pacProduct = [Select id from PAC_Product_Catalog__c where Product_Name__c = 'Test Product'][0];
        Chime_Product_Template__c template = [Select id From Chime_Product_Template__c];
        
        test.startTest();
        //Test product related methods
        List<PAC_Product_Catalog__c> productDataWithQuestions = QuestionnaireController.getProductData(pacProduct.id);
        List<PAC_Product_Catalog__c> productsWithoutQuestions = QuestionnaireController.getProductDataWithoutQuestionnaire();
        List<PAC_Product_Catalog__c> productsWithQuestions = QuestionnaireController.getProductDataWithQuestionnaire();
        
        //Get question calls
        Map<String,List<CHIME_Product_Question__c>> chimeProductQuestionMap = QuestionnaireController.getQuestionsForAdmin(pacProduct.id);
        Map<String,List<CHIME_Product_Question__c>> questionsMap = QuestionnaireController.getQuestions(pacProduct.id, '', chime.id,true);
        Map<String,List<CHIME_Product_Question__c>> questionsMap2 = QuestionnaireController.getQuestions(pacProduct.id, '', chime.id,false);
        System.assertEquals(q1.Form_Stage__c, 'Gating');
        List<CHIME_Product_Question__c> quesList = QuestionnaireController.getQuestionsForSection('Section1', pacProduct.id);
        List<CHIME_Product_Question__c> questionByIdList = QuestionnaireController.getQuestionsById(q1.id);
        //Depdentdent Question
        List<CHIME_Product_Question__c> depdendentQuesList = QuestionnaireController.getDependentQuestionsForParent(q2.id,
                                                                                                                    'q2', 
                                                                                                                    pacProduct.id);
            
        List<CHIME_Product_Question__c> depdendentQuesList2 = QuestionnaireController.getDependentQuestionsForParentInChimeForm(q2.id,
                                                                                                                    'q2', 
                                                                                                                    pacProduct.id, chime.id);
        Chime_Product_Template__c chimeProductTemplate = QuestionnaireController.getProductActiveTemplate(pacProduct.id);
        
        List<CHIME_Product_Question__c> chimeProductQuestion = QuestionnaireController.moveQuestion(pacProduct.id, q2.id, 'Section1', true);
        QuestionnaireController.updateSectionAfterDelete('Section2', pacProduct.id);
        List<PAC_Product_Catalog__c> productData = QuestionnaireController.getProductData(pacProduct.id);
        
        CHIME_Response__c chimeresponse = QuestionnaireController.getQuestionResponse(q2.Id ,chime.id);
        List<Id> idList = QuestionnaireController.checkProductQuestionnaireRefresh(chime.id);
        
        QuestionnaireController.publishQuestionnaireNotify( pacProduct.Id, 'notes',template.id);
        QuestionnaireController.checkChimeEligibilityForRefresh(chime.id);
        Id newTemplateId = QuestionnaireController.createTemplate(pacProduct.id);
        QuestionnaireController.createDependentAfterPublish(q1.id,q5.id,newTemplateId);
        QuestionnaireController.changeResponseQuestionMapping(q1.id,q5.id,pacProduct.id);

        
        QuestionnaireController.createDependentClone(JSON.serialize(q5));
        CHIME_Product_Question__c newQ = new CHIME_Product_Question__c();
        insert newQ;
        QuestionnaireControllerUtil.cloneQuestion(q10,newQ.Id,newTemplateId);
        
        //deletion of questions
        QuestionnaireController.deleteQuestion(q1.id, template.id);
        test.stopTest();
    }
}