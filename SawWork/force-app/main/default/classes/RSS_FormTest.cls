@isTest(SeeAllData = true)
public class RSS_FormTest
{
    public static RSS_Form__c RSSForm;
    static RSS_FormController controller;
    //changes by shprasan:
    //Making Account, Opportunity, OpportunityTeamMember, User, Attachment and Note static and class variables
    static Account acct;
    static Opportunity opp;
    static OpportunityTeamMember otm;
    static User usr;
    static Attachment  a1;
    static Note n1;

    //Changes by shprasan: Commenting out the initClass method
    //public static testMethod void initClass()
    //{
    //    Test.startTest();
    //    PSA_TestUtility testUtil = new PSA_TestUtility();
    //    pse__Region__c reg = testUtil.newRegionMaster(true);
    //    Account acct = testUtil.newAccount(true);        
    //    RSSForm = new RSS_Form__c();
    //    RSSForm.Name = 'Test RSSForm';
    //    RSSForm.UniqueName__c = GuidUtil.NewGuid();
    //    RSSForm.Published__c = false;
    //    RSSForm.Locked__c = false;
    //    RSSForm.AEName__c = [select id from User limit 1][0].id;
    //    RSSFORM.DigitalProperty__c = 'www.apple.com';
    //    RSSForm.Account__c =  acct.id;
    //    insert RSSForm;
    //    RSSForm = [select id,Name,UniqueName__c,Published__c,Locked__c,AEName__c,DigitalProperty__c,Account__c,Account__r.Name,OwnerId,Owner.Name from RSS_Form__c where id =:RSSForm.id limit 1];
    //    PageReference pageRef = Page.RSSForm;
    //    pageRef.getParameters().put('id','new');
    //    Test.setCurrentPage(pageRef);
    //    controller = new RSS_FormController();
    //    controller.RSSForm.Name = 'Test RSSForm';
    //    controller.RSSForm.UniqueName__c = GuidUtil.NewGuid();
    //    controller.RSSForm.Published__c = false;
    //    controller.RSSForm.Locked__c = false;
    //    controller.RSSForm.AEName__c = [select id from User limit 1][0].id;
    //    controller.RSSFORM.DigitalProperty__c = 'www.apple.com';
    //    controller.RSSForm.Account__c =  [select id,Name from Account limit 1][0].id;
    //    controller.SaveForm();
    //    controller.chosenList = new List<selectOption>();
    //    RSSTemplateTest.initClass();
    //    List<String> templates = new List<String>();
    //    controller.chosenList.add(new SelectOption(RSSTemplateTest.RSSTemplate.id,RSSTemplateTest.RSSTemplate.Name));
    //    RSSUtility.deepCloneRSSFormWithResponses(RSSForm.id);
    //    controller.SaveForm();
    //    RSSTemplateTest.initClass();
    //    templates.add(RSSTemplateTest.RSSTemplate.id);

    //    RSSUtility.CreateRSSFromTemplate(templates,RSSForm.id);
    //    ApexPages.StandardController sc = new ApexPages.StandardController(RSSForm);
    //    controller.DownloadOfflineData();
    //    pageRef = Page.RSSForm;
    //    pageRef.getParameters().put('id',RSSForm.id);
    //    Test.setCurrentPage(pageRef);
    //    controller = new RSS_FormController();
    //    controller = new RSS_FormController(sc);        
    //    controller.UpdateForm();
    //    String RSSTemplateid = RSSUtility.deepCloneNewTemplate(RSSTemplateTest.RSSTemplate.id);
    //    Survey__c RSSTemplateCloned = [select id,name from Survey__c where id =: RSSTemplateid limit 1];
    //    controller.chosenList.add(new SelectOption(RSSTemplateCloned.id,RSSTemplateCloned.name));
    //    controller.UpdateForm();
    //    controller.chosenList.remove(1);
    //    controller.UpdateForm();
    //    string jSONGenerated =controller.getJSON();
    //    controller.publishForm();
    //    for(SurveyQuestionResponse__c r:controller.responses)
    //    {
    //        r.response__c ='abcd';
    //    }
    //    controller.publishForm();
    //    controller.CheckDisabled();
    //    //controller.ReviseRSS();
    //    controller.DownloadPDF();
        
    //    RSS_Form__c RSSForm1 = new RSS_Form__c();
    //    RSSForm1.Name = 'Test RSSForm';
    //    RSSForm1.UniqueName__c = GuidUtil.NewGuid();
    //    RSSForm1.Published__c = false;
    //    RSSForm1.Locked__c = false;
    //    RSSForm1.AEName__c = [select id from User limit 1][0].id;
    //    RSSFORM1.DigitalProperty__c = 'www.apple.com';
    //    RSSForm1.Account__c =  [select id from Account limit 1][0].id;
    //    insert RSSForm1;
    //    controller.StartSaving();
    //    controller.StopSaving();
    //    controller.AutoSave();
    //    RSSUtility.getNextVersionNumberForRSSForm(RSSForm1.UniqueName__c);
    //    //RSSUtility.deepCloneRSSForm(RSSForm1.id,templates);
    //    List<String>rssformids =  new List<String>();
    //    rssformids.add(RSSForm.id);
    //    rssformids.add(RSSForm1.id);
    //    Blob Attach = Blob.valueOf(RSSUtility.RSSFormJSONS(rssformids));
    //    controller.attachment.body = Attach;
    //    controller.upload();
    //    delete RSSForm1;        
        
    //    RSS_FormController.RSSResponse rrr = new RSS_FormController.RSSResponse();
    //    RSS_FormController.RSSQuestionGroup rrqg = new RSS_FormController.RSSQuestionGroup('Name',1,new List<RSS_FormController.RSSResponse>());
    //    RSS_FormController.ProductForm rpf = new RSS_FormController.ProductForm('name','sadasdadasdasd','asdasdasdasdad',new List<RSS_FormController.RSSQuestionGroup>());
    //    RSS_FormController.RSSFormC rrf = new RSS_FormController.RSSFormC('name','id','uniqueName','AEName','DigitalProperty',1,'a','apple',new List<RSS_FormController.ProductForm>(),'asdasd');
    //    RSS_FormController.ListRSSForm ltf = new RSS_FormController.ListRSSForm(new List<RSS_FormController.RSSFormC>());
    //    Test.stopTest();
    //}

    //Changes by shprasan:
    //Creates data for the test methods
    public static void createData()
    {

        PSA_TestUtility testUtil = new PSA_TestUtility();
        acct = testUtil.newAccount(true);  
        //Creating a system admin user
        
        usr = testUtil.newUserSysAdmin(true);
        //Creating an opportunity
        
        opp = new Opportunity();
        opp.Name = 'TestOpp';
        opp.AccountId = acct.id;
        opp.StageName = 'stageName';
        opp.CloseDate = Date.today();
        opp.CurrencyIsoCode = 'USD';
        opp.Validation_Override__c = TRUE;
        opp.Carrier_Application__c='Retail CDN services';
        insert opp;        
        
        //Creating a team member with role as TSP
        otm = new OpportunityTeamMember();
        otm.OpportunityId = opp.id;
        otm.UserId = usr.id;
        otm.TeamMemberRole = 'Technical Sales - Primary';
        //otm.OpportunityAccessLevel = 'Read Only';
        insert otm;
       
        //creating a form with all the required fields
        RSSForm = new RSS_Form__c();
        RSSForm.Name = 'Test RSSForm';
        RSSForm.UniqueName__c = GuidUtil.NewGuid();
        RSSForm.Published__c = false;
        RSSForm.Locked__c = false;
        RSSForm.AEName__c = usr.id;
        RSSForm.DigitalProperty__c = 'www.apple.com';
        RSSForm.Account__c =  acct.id;
        RSSForm.Opportunity__c =  opp.id;        
        RSSForm.Customer_Technical_Contact_Name__c = 'test';
        RSSForm.Customer_Technical_Contact_Details__c = 'test';
        RSSForm.Commitment_Type__c = 'Standard';
        RSSForm.Type_of_Integration__c = 'Emergency';
        RSSForm.Customer_agreed_Success_Criteria__c = 'test';
        insert RSSForm;

        //creating an attachment for the form
        a1 = new attachment();
        Blob Attach = Blob.valueOf('a.Body');
        a1.Body =  Attach;
        a1.IsPrivate = false;
        a1.Name = 'a.Name';
        a1.OwnerId =  UserInfo.getUserId();
        a1.ParentId=RSSForm.Id;
        insert a1;

        //creating a note for the form
        n1 = new Note();
        n1.Body = 'Attach' ;
        n1.IsPrivate = false;
        n1.Title = 'a.Body';
        n1.OwnerId = UserInfo.getUserId() ;
        n1.ParentId=RSSForm.Id;
        insert n1;

        //Adding a template to the form
        RSSTemplateTest.initClass();
        List<String> templates = new List<String>();
        templates.add(RSSTemplateTest.RSSTemplate.id);
        RSSUtility.CreateRSSFromTemplate(templates,RSSForm.id);
    }

    //changes by shprasan:Function to check the submit functionality
    public static testMethod void SubmitFunctionality()
    {

        RSS_FormTest.createData();
        Test.startTest();

        //create a pagereference for RSSForm and set the parameter ID to the form ID
        ApexPages.StandardController sc = new ApexPages.StandardController(new RSS_Form__c());                               
        PageReference pageRef = Page.RSSForm;
        pageRef.getParameters().put('id',RSSForm.id);
        Test.setCurrentPage(pageRef);
        //Create a controller for the page with pagereference pageRef
        controller = new RSS_FormController(sc);
        controller.RSSForm = RSSForm;                
        controller.chosenList = new List<selectOption>();
        List<String> templates = new List<String>();
        controller.chosenList.add(new SelectOption(RSSTemplateTest.RSSTemplate.id,RSSTemplateTest.RSSTemplate.Name));
        //setting PreSales to true
        controller.PreSales = true;
        //Set all responses to abcd        
        for(SurveyQuestionResponse__c r:controller.responses)
        {
            r.response__c ='abcd';
        }

        //Submit the form by calling the publishForm function
        controller.publishForm();        
        //Revise the submitted form and change the page reference to the new record
        pageRef = controller.ReviseRSS();
        Test.setCurrentPage(pageRef);
        controller = new RSS_FormController(sc);
        //Change the responses to 1234
        for(SurveyQuestionResponse__c r:controller.responses)
        {
            r.response__c ='1234';
        }  
        //change the value of Customer_Technical_Contact_Name__c and Customer_Technical_Contact_Details__c
        controller.RSSForm.Customer_Technical_Contact_Name__c = 'test123';
        controller.RSSForm.Customer_Technical_Contact_Details__c = 'test123';
        //Re-submit the form
        controller.publishForm();
        //covering the CloneNewRSSForm function
        //pageRef = controller.CloneNewRSSForm();
        //covering the WrapperForCheckForInvalidScenarios function
        controller.WrapperForCheckForInvalidScenarios();
        //controller.UpdateProductForms();
        Test.stopTest();
    }

    //changes by shprasan:Function to check the publish functionality
    public static TestMethod void PublishFunctionality()
    {
        RSS_FormTest.createData();
        Test.startTest();

        //create a pagereference for RSSForm and set the parameter ID to the form ID

        ApexPages.StandardController sc = new ApexPages.StandardController(new RSS_Form__c());                               
        PageReference pageRef = Page.RSSForm;
        pageRef.getParameters().put('id',RSSForm.id);
        //Create a controller for the page with pagereference pageRef
        Test.setCurrentPage(pageRef);
        controller = new RSS_FormController(sc);
        controller.RSSForm = RSSForm;                
        controller.chosenList = new List<selectOption>();
        List<String> templates = new List<String>();
        controller.chosenList.add(new SelectOption(RSSTemplateTest.RSSTemplate.id,RSSTemplateTest.RSSTemplate.Name));
        //setting PreSales to true
        controller.PreSales = true;
        //controller.PostSales = true;
        //Set all responses to abcd        
        for(SurveyQuestionResponse__c r:controller.responses)
        {
            r.response__c ='abcd';
        }
        controller.CloneNewRSSForm();

        //Submit the form
        controller.publishForm();  
        //Set PostSales to true and PreSales to false
        controller.PreSales = false;
        controller.PostSales = true;     
        //publish the form 
        controller.publishForm();                
        //Test.setCurrentPage(pageRef);
        //controller = new RSS_FormController(sc);
        ////Revise the published form
        //pageRef = controller.ReviseRSS();
        //Test.setCurrentPage(pageRef);
        //controller = new RSS_FormController(sc);
        ////change the responses to 1234
        //for(SurveyQuestionResponse__c r:controller.responses)
        //{
        //    r.response__c ='1234';
        //}        
        //Re-publish the form
        //controller.publishForm();

        Test.stopTest();

    }
    //changes by shprasan:Function to check the save and update functionality
    public static TestMethod void SaveAndUpdateFunctionality()
    {
        createData();

        //create a pagereference for RSSForm and set the parameter ID to new
        ApexPages.StandardController sc = new ApexPages.StandardController(new RSS_Form__c());                               
        PageReference pageRef = Page.RSSForm;
        pageRef.getParameters().put('id','new');
        
        Test.startTest();
        Test.setCurrentPage(pageRef);
        controller = new RSS_FormController();
        controller = new RSS_FormController(sc);                

        //Assign values to the new form's fields
        controller.RSSForm.Name = 'Test RSSForm';
        controller.RSSForm.UniqueName__c = RSSForm.UniqueName__c;
        controller.RSSForm.Published__c = false;
        controller.RSSForm.Locked__c = false;
        controller.RSSForm.AEName__c = usr.id;
        controller.RSSFORM.DigitalProperty__c = 'www.apple.com';
        controller.RSSForm.Account__c =  acct.id;
        controller.RSSForm.Opportunity__c =  opp.id;        
        controller.RSSForm.Customer_Technical_Contact_Name__c = 'test';
        controller.RSSForm.Customer_Technical_Contact_Details__c = 'test';
        controller.RSSForm.Commitment_Type__c = 'Standard';
        controller.RSSForm.Type_of_Integration__c = 'Emergency';
        controller.RSSForm.Customer_agreed_Success_Criteria__c = 'test';
        controller.chosenList = new List<selectOption>();        
        List <string> templates = new List<String>();
        controller.chosenList.add(new SelectOption(RSSTemplateTest.RSSTemplate.id,RSSTemplateTest.RSSTemplate.Name));

        //insert the record by calling the saveForm function
        controller.SaveForm();        
        //cover the DownloadOfflineData function
        controller.DownloadOfflineData();

        //create a pagereference for RSSForm and set the parameter ID to the form ID
        sc = new ApexPages.StandardController(controller.RSSForm);                       
        pageRef = Page.RSSForm;
        pageRef.getParameters().put('id',controller.RSSForm.id);
        Test.setCurrentPage(pageRef);
        controller = new RSS_FormController(sc);        

        //save the form: call the UpdateForm function
        controller.UpdateForm();                

        Test.stopTest();

    }
    //changes by shprasan:Function to cover checks on publish and RSSUtility functions
    public static TestMethod void testFunction()
    {
        //Create a RSSForm. The mandatory fields are not populated
        RSSForm = new RSS_Form__c();
        RSSForm.Name = 'Test RSSForm';
        RSSForm.UniqueName__c = GuidUtil.NewGuid();
        RSSForm.Published__c = false;
        RSSForm.Locked__c = false;
        RSSForm.DigitalProperty__c = 'www.apple.com';
        RSSForm.Customer_Technical_Contact_Name__c = 'test';
        RSSForm.Customer_Technical_Contact_Details__c = 'test';
        insert RSSForm;
        RSSTemplateTest.initClass();
        List<String> templates = new List<String>();
        templates.add(RSSTemplateTest.RSSTemplate.id);
        RSSUtility.CreateRSSFromTemplate(templates,RSSForm.id);
        
        Test.startTest();

        //create a pagereference for RSSForm and set the parameter ID to new
        ApexPages.StandardController sc = new ApexPages.StandardController(new RSS_Form__c());        
        PageReference pageRef = Page.RSSForm;
        pageRef.getParameters().put('id',RSSForm.id);
        Test.setCurrentPage(pageRef);
        //controller = new RSS_FormController(sc);
        //Cover the default constructor
        controller = new RSS_FormController();
        controller = new RSS_FormController(sc);        
        //Save the form
        controller.UpdateForm();
        //Cover the DownloadOfflineData function 
        controller.DownloadOfflineData();        
        RSSTemplateTest.initClass();
        //Cover the deepCloneNewTemplate function of RSSUtility
        String RSSTemplateid = RSSUtility.deepCloneNewTemplate(RSSTemplateTest.RSSTemplate.id);
        Survey__c RSSTemplateCloned = [select id,name from Survey__c where id =: RSSTemplateid limit 1];
        controller.chosenList.add(new SelectOption(RSSTemplateCloned.id,RSSTemplateCloned.name));
        controller.chosenList.add(new SelectOption(RSSTemplateTest.RSSTemplate.id,RSSTemplateTest.RSSTemplate.Name));
        //save the form after removing a product from the selected list
        controller.UpdateForm();
        controller.chosenList.remove(1);
        controller.UpdateForm();

        //call the getJSON method
        string jSONGenerated =controller.getJSON();
        //try to Publish the form: The mandatory fields are not populated
        controller.publishForm();        
        for(SurveyQuestionResponse__c r:controller.responses)
        {            
            r.response__c ='abcd';
        }
        //Call the UpdateProductForms and CheckDisabled functions
        controller.UpdateProductForms();
        controller.publishForm();

        controller.CheckDisabled();
        //controller.ReviseRSS();
        //controller.DownloadPDF();
        Test.stopTest();
    }
    //changes by shprasan:Function to cover checks on publish and RSSUtility functions
    public static TestMethod void testFunction2()
    {
        createData();
        Test.startTest();

        //Create another form record
        RSS_Form__c RSSForm1 = new RSS_Form__c();
        RSSForm1.Name = 'Test RSSForm';
        RSSForm1.UniqueName__c = GuidUtil.NewGuid();
        RSSForm1.Published__c = false;
        RSSForm1.Locked__c = false;
        RSSForm1.AEName__c = [select id from User limit 1][0].id;
        RSSFORM1.DigitalProperty__c = 'www.apple.com';
        RSSForm1.Account__c =  [select id from Account limit 1][0].id;
        insert RSSForm1;
        ApexPages.StandardController sc = new ApexPages.StandardController(new RSS_Form__c());
        PageReference pageRef = Page.RSSForm;
        pageRef.getParameters().put('id',RSSForm.id);
        Test.setCurrentPage(pageRef);        
        controller = new RSS_FormController(sc);
        //Call the StartSaving, StopSaving, AutoSave, uploadAttachment, attachmentListUpdate and DownloadPDF functions
        controller.StartSaving();
        controller.StopSaving();
        controller.AutoSave();
        controller.uploadAttachment();
        controller.attachmentListUpdate();
        controller.DownloadPDF();
        //Call the getNextVersionNumberForRSSForm method of RSSUtility
        RSSUtility.getNextVersionNumberForRSSForm(RSSForm1.UniqueName__c);
        List <String> templates = new List<String>();
        templates.add(RSSTemplateTest.RSSTemplate.id);
        //clone the RSSForm1 record using the deepCloneRSSForm function
        RSSUtility.deepCloneRSSForm(RSSForm1.id,templates);
        //Clone the RSSForm record including the responses to template questions
        RSSUtility.deepCloneRSSFormWithResponses(RSSForm.id);
        List<String>rssformids =  new List<String>();
        rssformids.add(RSSForm.id);
        rssformids.add(RSSForm1.id);
        Blob Attach = Blob.valueOf(RSSUtility.RSSFormJSONS(rssformids));
        controller.attachment.body = Attach;
        controller.upload();
        delete RSSForm1;        
        
        RSS_FormController.RSSResponse rrr = new RSS_FormController.RSSResponse();
        RSS_FormController.RSSQuestionGroup rrqg = new RSS_FormController.RSSQuestionGroup('Name',1,new List<RSS_FormController.RSSResponse>());
        RSS_FormController.ProductForm rpf = new RSS_FormController.ProductForm('name','sadasdadasdasd','asdasdasdasdad',new List<RSS_FormController.RSSQuestionGroup>());
        RSS_FormController.RSSFormC rrf = new RSS_FormController.RSSFormC('name','id','uniqueName','AEName','DigitalProperty',1,'a','apple',new List<RSS_FormController.ProductForm>(),'asdasd');
        RSS_FormController.ListRSSForm ltf = new RSS_FormController.ListRSSForm(new List<RSS_FormController.RSSFormC>());
        Test.stopTest();
    }

    //Method to test the product component controller
    public  static TestMethod void testMultiSelectCOntroller()
    {
        
        MultiSelectComponentController ComponentController = new MultiSelectComponentController();
        Test.startTest();
        ComponentController.options = new List<SelectOption>();
        ComponentController.options.add(new SelectOption('a','a'));
        ComponentController.options.add(new SelectOption('b','b'));
        ComponentController.options.add(new SelectOption('c','c'));
        ComponentController.options.add(new SelectOption('d','d'));
        ComponentController.selectedOptions = new List<SelectOption>();
        ComponentController.selectedOptions.add(new SelectOption('e','e'));
        ComponentController.selectedOptions.add(new SelectOption('f','f'));
        ComponentController.selectedOptions.add(new SelectOption('g','g'));
        ComponentController.selectedOptions.add(new SelectOption('h','h'));
        ComponentController.selected = new List<String>{ 'a','b'};
        ComponentController.deselected = new List<String>{ 'e','f'};
        ComponentController.selecting();
        ComponentController.deselecting();
        Test.stopTest();
    }
    //changes by shprasan: This function covers RSSCloneController, RSSUtility functions and the Wrapper classes
     static testmethod void unitTestClone()
    {
        Test.startTest();
        createData();
        //Create  RSSFormWrapper, RSSResponseGroupWrapper and RSSQuestionGroupWrapper objects
        RSSFormWrapper formWrapper = new RSSFormWrapper();
        RSSResponseGroupWrapper groupWrapper = new RSSResponseGroupWrapper();        
        Survey_Question_Group__c sqg = [Select ID from Survey_Question_Group__c where Survey__c = :RSSTemplateTest.RSSTemplate.id][0];
        RSSQuestionGroupWrapper qGroupWrapper = new RSSQuestionGroupWrapper(sqg);
        Integer qc = qGroupWrapper.QuestionCount;
        //Call the createJSONForOfflineUse method of the RSSUtility class 
        RSSUtility.createJSONForOfflineUse();

        PageReference pageRef = Page.RSSForm;
        pageRef.getParameters().put('id',RSS_FormTest.RSSForm.id);
        Test.setCurrentPage(pageRef);
        //Clone the RSSForm record
        RSSCloneController controller1 = new RSSCloneController();
        controller1.CloneRSSForm();
        //controller1.CloneNewRSSForm();
        controller1.chosenList = null;
        List<SelectOption> testSelect = controller1.chosenList;
        Test.stopTest();

    }
    
    //Method to delete a form
    static testMethod void ERSSDeleteSurveyTakerTest()
    {
        //Test.startTest();
        createData();
        Test.startTest();
        delete RSSForm;
        Test.stopTest();
    }

    static testMethod void testLeapForm()
    {
        createData();
        PSA_TestUtility testUtil = new PSA_TestUtility();
        Test.startTest();
            
            List<Contact> contacts = new List<Contact>();
            Contact resource1 = testUtil.newResource(false, acct.Id, usr.Id);
            resource1.Phone = '9945565353';
            resource1.FirstName = 'Sharath';
            resource1.LastName = 'Prasanna';
            resource1.email = '9945565353@akamai.com';
            contacts.add(resource1);

            user usr2 = testUtil.newUserSysAdmin(true); 
            Contact resource2 = testUtil.newResource(false, acct.Id, usr2.Id);
            resource2.Phone = '9945565353';
            resource2.FirstName = 'Sujay';
            resource2.LastName = 's';
            resource2.email = '99455653532@akamai.com';
            contacts.add(resource2);
            
            insert contacts;
            
            RSSForm.Leap_Form__c = true;
            RSSForm.Admin_Contact_Details__c = '99455653532@akamai.com\nSujay\nS\n9945565353';
            RSSForm.Technical_Contact_Details__c = '9945565353@akamai.com\nSharath\nPrasanna\n9945565353';
            RSSForm.Admin_Contact__c = null;
            RSSForm.Technical_Contact__c = null; 
            update RSSForm;
            ApexPages.StandardController sc = new ApexPages.StandardController(new RSS_Form__c());                               
            PageReference pageRef = Page.RSSForm;
            pageRef.getParameters().put('id',RSSForm.id);
            pageRef.getParameters().put('OppId',opp.id);
            pageRef.getParameters().put('ContactType','admin');

            Test.setCurrentPage(pageRef);
            controller = new RSS_FormController(sc);
            controller.RSSForm = RSSForm;   
            controller.CustomConstructor();
            controller.SaveForm();   

            controller.RSSForm.Admin_Contact__c = null;
            controller.RSSForm.Technical_Contact__c = null; 
            update controller.RSSForm;
            controller.CustomConstructor();

            controller.chosenList.add(new SelectOption(RSSTemplateTest.RSSTemplate.id,RSSTemplateTest.RSSTemplate.Name));
            for(SurveyQuestionResponse__c r:controller.responses)
            {            
                if(r.Survey_Question__r.Category__c == 'List of secure hostname')
                {
                    r.response__c ='https://www.google.com';
                }
                else
                {
                    r.response__c ='abcd';    
                }
                
            }

            //controller.UpdateForm();      
            controller.RetrieveContact();
            pageRef.getParameters().put('ContactType','tech');            
            Test.setCurrentPage(pageRef);
            controller.RetrieveContact();

            Map<String,String> tSPNameToEmail = controller.TSPNameToEmail;
            String savedURl = controller.SavedURl;
            Boolean keepSaving = controller.KeepSaving;
            String OfflineFileName = controller.OfflineFileName;
            opportunity opp  =  controller.FromOpportunity;

        Test.stopTest();

    }

    static testMethod void testLeapForm2()
    {
        createData();
        PSA_TestUtility testUtil = new PSA_TestUtility();
        Test.startTest();

            Contact resource1 = testUtil.newResource(false, acct.Id, usr.Id);
            resource1.Phone = '9945565353';
            resource1.FirstName = 'Sharath';
            resource1.LastName = 'Prasanna';
            resource1.email = '9945565353@akamai.com';
            insert resource1;

            user usr2 = testUtil.newUserSysAdmin(true); 
            Contact resource2 = testUtil.newResource(false, acct.Id, usr2.Id);
            resource2.Phone = '9945565353';
            resource2.FirstName = 'Sujay';
            resource2.LastName = 's';
            resource2.email = '99455653532@akamai.com';
            insert resource2;

            RSSForm.Leap_Form__c = true;
            RSSForm.Admin_Contact_Details__c = '99455653532@akamai.com\nSujay\nS\n9945565353';
            RSSForm.Technical_Contact_Details__c = '9945565353@akamai.com\nSharath\nPrasanna\n9945565353';
            RSSForm.Admin_Contact__c = resource1.id;
            RSSForm.Technical_Contact__c = resource2.id; 
            update RSSForm;
            
            ApexPages.StandardController sc = new ApexPages.StandardController(new RSS_Form__c());                               
            PageReference pageRef = Page.RSSForm;
            pageRef.getParameters().put('id','new');
            pageRef.getParameters().put('OppId',opp.id);

            Test.setCurrentPage(pageRef);
            controller = new RSS_FormController(sc);
            controller.RSSForm = RSSForm;   
            controller.CustomConstructor();      
            Map<String,String> tSPNameToEmail = controller.TSPNameToEmail;
            String savedURl = controller.SavedURl;
            Boolean keepSaving = controller.KeepSaving;
            String OfflineFileName = controller.OfflineFileName;
            opportunity opp  =  controller.FromOpportunity;

            controller.AEmail = null; 
            controller.TEmail = '99455653532@akamai.com';
            controller.validateSaveContact();
            controller.TEmail = null;
            controller.AEmail = '9945565353@akamai.com';
            controller.validateSaveContact();
            controller.NavigateToAcceptanceForm();
        Test.stopTest();

    }

    static testMethod void testLeapForm3()
    {
        createData();
        PSA_TestUtility testUtil = new PSA_TestUtility();
        Test.startTest();

            Contact resource1 = testUtil.newResource(false, acct.Id, usr.Id);
            resource1.Phone = '9945565353';
            resource1.FirstName = 'Sharath';
            resource1.LastName = 'Prasanna';
            resource1.email = '9945565353@akamai.com';
            insert resource1;

            user usr2 = testUtil.newUserSysAdmin(true); 
            Contact resource2 = testUtil.newResource(false, acct.Id, usr2.Id);
            resource2.Phone = '9945565353';
            resource2.FirstName = 'Sujay';
            resource2.LastName = 's';
            resource2.email = '99455653532@akamai.com';
            insert resource2;

            RSSForm.Leap_Form__c = true;
            RSSForm.Admin_Contact_Details__c = '99455653532@akamai.com\nSujay\nS\n9945565353';
            RSSForm.Technical_Contact_Details__c = '9945565353@akamai.com\nSharath\nPrasanna\n9945565353';
            RSSForm.Admin_Contact__c = resource1.id;
            RSSForm.Technical_Contact__c = resource2.id; 
            RSSForm.Opportunity__c = opp.Id;
            RSSForm.Submitted__c = true;
            RSSForm.Submit_Locked__c = true;                                
            RSSForm.Submit_Version__c = 1;
            RSSForm.Submitted_By__c = UserInfo.getUserId();
            RSSForm.Submittal_Date__c = Date.today();
            RSSForm.Published__c = true;
            RSSForm.Locked__c = true;   
            RSSForm.Version__c = 1;

            update RSSForm;
            
            ApexPages.StandardController sc = new ApexPages.StandardController(new RSS_Form__c());                               
            PageReference pageRef = Page.RSSForm;
            pageRef.getParameters().put('id',RSSForm.Id);
            pageRef.getParameters().put('OppId',opp.id);

            Test.setCurrentPage(pageRef);
            controller = new RSS_FormController(sc);
            controller.RSSForm = RSSForm;   
            //controller.CustomConstructor();    
            //controller.ValidateOpportunity();
            controller.chosenList.add(new SelectOption(RSSTemplateTest.RSSTemplate.id,RSSTemplateTest.RSSTemplate.Name));
            for(SurveyQuestionResponse__c r:controller.responses)
            {            
                if(r.Survey_Question__r.Category__c == 'List of secure hostname')
                {
                    r.response__c ='https://www.google.com';
                }
                else
                {
                    r.response__c ='abcd';    
                }
                
            }
            controller.AEmail = resource1.email;
            controller.TEmail = resource2.email;
            //controller.publishForm();

            //pageRef = controller.ReviseRSS();
            RSS_Form__c aNewForm = RSSForm.clone();
            insert aNewForm;

            Test.setCurrentPage(new PageReference('/apex/RSSForm?id='+aNewForm.Id));

            controller = new RSS_FormController(sc);
            //change the responses to 1234
            for(SurveyQuestionResponse__c r:controller.responses)
            {            
                if(r.Survey_Question__r.Category__c == 'List of secure hostname')
                {
                    r.response__c ='https://www.yahoo.com';
                }
                else
                {
                    r.response__c ='123456';    
                }
                
            }
            //Re-publish the form
            //controller.publishForm();
            controller.sendMailToTSP();
            controller.PhoneValidation('9945565454');
            Boolean CallRetrieveContact = controller.CallRetrieveContact;
            Boolean EnableOpportunity = controller.EnableOpportunity;
            List<selectOption> chosenList = controller.chosenList;
            String AFirstName = controller.AFirstName;
            String ALastName = controller.ALastName;
            String APhone= controller.APhone;
            String TFirstName = controller.TFirstName;
            String TLastName = controller.TLastName;
            String TPhone = controller.TPhone;
            list<Attachment> attachmentList = controller.attachmentList;
            test.StopTest();

    }
    static testMethod void testLeapForm4()
    {
        createData();
        PSA_TestUtility testUtil = new PSA_TestUtility();
        Test.startTest();
              
            Contact resource1 = testUtil.newResource(false, acct.Id, usr.Id);
            resource1.Phone = '9945565353';
            resource1.FirstName = 'Sharath';
            resource1.LastName = 'Prasanna';
            resource1.email = '9945565353@akamai.com';
            insert resource1;

            user usr2 = testUtil.newUserSysAdmin(true); 
            Contact resource2 = testUtil.newResource(false, acct.Id, usr2.Id);
            resource2.Phone = '9945565353';
            resource2.FirstName = 'Sujay';
            resource2.LastName = 's';
            resource2.email = '99455653532@akamai.com';
            insert resource2;
            
            RSSForm.Leap_Form__c = true;
            RSSForm.Admin_Contact_Details__c = '99455653532@akamai.com\nSujay\nS\n9945565353';
            RSSForm.Technical_Contact_Details__c = '9945565353@akamai.com\nSharath\nPrasanna\n9945565353';
            RSSForm.Admin_Contact__c = null;
            RSSForm.Technical_Contact__c = null; 
            update RSSForm;
            ApexPages.StandardController sc = new ApexPages.StandardController(new RSS_Form__c());                               
            PageReference pageRef = Page.RSSForm;
            pageRef.getParameters().put('id',RSSForm.id);
            pageRef.getParameters().put('OppId',opp.id);
            pageRef.getParameters().put('ContactType','admin');

            Test.setCurrentPage(pageRef);
            controller = new RSS_FormController(sc);
            controller.RSSForm = RSSForm;   
            controller.chosenList.add(new SelectOption(RSSTemplateTest.RSSTemplate.id,RSSTemplateTest.RSSTemplate.Name));
            for(SurveyQuestionResponse__c r:controller.responses)
            {            
                if(r.Survey_Question__r.Category__c == 'List of secure hostname')
                {
                    r.response__c ='https://www.google.com';
                }
                else
                {
                    r.response__c ='abcd';    
                }
                
            }

            controller.publishForm();

            Map<String,String> tSPNameToEmail = controller.TSPNameToEmail;
            String savedURl = controller.SavedURl;
            Boolean keepSaving = controller.KeepSaving;
            String OfflineFileName = controller.OfflineFileName;
            opportunity opp  =  controller.FromOpportunity;

        Test.stopTest();

    }
    static testMethod void testLeapForm5()
    {
        createData();
        PSA_TestUtility testUtil = new PSA_TestUtility();
        Test.startTest();
              
            Contact resource1 = testUtil.newResource(false, acct.Id, usr.Id);
            resource1.Phone = '9945565353';
            resource1.FirstName = 'Sharath';
            resource1.LastName = 'Prasanna';
            resource1.email = '9945565353@akamai.com';
            insert resource1;

            user usr2 = testUtil.newUserSysAdmin(true); 
            Contact resource2 = testUtil.newResource(false, acct.Id, usr2.Id);
            resource2.Phone = '9945565353';
            resource2.FirstName = 'Sujay';
            resource2.LastName = 's';
            resource2.email = '99455653532@akamai.com';
            insert resource2;
            
            RSSForm.Leap_Form__c = true;
            RSSForm.Admin_Contact_Details__c = '99455653532@akamai.com\nSujay\nS\n9945565353';
            RSSForm.Technical_Contact_Details__c = '9945565353@akamai.com\nSharath\nPrasanna\n9945565353';
            RSSForm.Admin_Contact__c = resource1.iD;
            RSSForm.Technical_Contact__c = resource2.Id; 
            RSSForm.Opportunity__c =  null;        
            update RSSForm;
            ApexPages.StandardController sc = new ApexPages.StandardController(new RSS_Form__c());                               
            PageReference pageRef = Page.RSSForm;
            pageRef.getParameters().put('id',RSSForm.id);
            pageRef.getParameters().put('OppId',opp.id);
            pageRef.getParameters().put('ContactType','admin');

            Test.setCurrentPage(pageRef);
            controller = new RSS_FormController(sc);
            controller.RSSForm = RSSForm;   
            controller.chosenList.add(new SelectOption(RSSTemplateTest.RSSTemplate.id,RSSTemplateTest.RSSTemplate.Name));
            for(SurveyQuestionResponse__c r:controller.responses)
            {            
                if(r.Survey_Question__r.Category__c == 'List of secure hostname')
                {
                    r.response__c ='https://www.google.com';
                }
                else
                {
                    r.response__c ='abcd';    
                }
                
            }

            controller.publishForm();

            Map<String,String> tSPNameToEmail = controller.TSPNameToEmail;
            String savedURl = controller.SavedURl;
            Boolean keepSaving = controller.KeepSaving;
            String OfflineFileName = controller.OfflineFileName;
            opportunity opp  =  controller.FromOpportunity;

        Test.stopTest();

    }
    static testMethod void testLeapForm6()
    {
        createData();
        PSA_TestUtility testUtil = new PSA_TestUtility();
        Test.startTest();
              
        Merge_Contract_Header__c contract = testUtil.newContract(false, acct.Id, '123','456',null,System.today(), System.today().addDays(50));
        contract.Locked__c = TRUE;
        contract.Cancellation_Date__c = null;
        contract.Contract_Transferred_To__c = null;
        contract.Active__c = true;
        contract.Currency__c = 'USD';
        contract.Original_Contract_Id__c = GuidUtil.NewGuid();
        contract.Contract_Id__c = GuidUtil.NewGuid();
        insert contract;

        Merge_Contract_Detail__c contDetail3 = testUtil.newContractDetail(false, 'test','test',contract.Id, System.today(), System.today().addDays(50));
        contDetail3.Product_Id__c= 'M-LC-159904';
        contDetail3.Record_Type__c = 'Committed';
        contDetail3.Unit_of_Measure__c = 'Per Month';
        contDetail3.Units_Low__c = 12;
        contDetail3.Unit_Price__c = 12;
        contDetail3.Original_Contract_Id__c = contract.id;
        contDetail3.Product__c = 'SMP';
        contDetail3.Units_High__c = 12;
        contDetail3.Original_Detail_Id__c = 'd3' + contract.id;
        insert contDetail3;  
          
         opp.Contract_ID__c = contract.Contract_Id__c;
         opp.Validation_override__c= true;
         update opp;


            ApexPages.StandardController sc = new ApexPages.StandardController(new RSS_Form__c());                               
            PageReference pageRef = Page.RSSForm;
            pageRef.getParameters().put('id',RSSForm.id);
            pageRef.getParameters().put('OppId',opp.id);
            pageRef.getParameters().put('ContactType','admin');

            Test.setCurrentPage(pageRef);
            controller = new RSS_FormController(sc);
            controller.RSSForm = RSSForm;  
            controller.PostSales = true;
            controller.NewForm = true;
            controller.chosenList.add(new SelectOption(RSSTemplateTest.RSSTemplate.id,RSSTemplateTest.RSSTemplate.Name));
            for(SurveyQuestionResponse__c r:controller.responses)
            {            
                if(r.Survey_Question__r.Category__c == 'List of secure hostname')
                {
                    r.response__c ='https://www.google.com';
                }
                else
                {
                    r.response__c ='abcd';    
                }
                
            }

            controller.publishForm();

            Map<String,String> tSPNameToEmail = controller.TSPNameToEmail;
            String savedURl = controller.SavedURl;
            Boolean keepSaving = controller.KeepSaving;
            String OfflineFileName = controller.OfflineFileName;
            opportunity opp  =  controller.FromOpportunity;

        Test.stopTest();

    }
    static testMethod void testLeapForm7()
    {
        createData();
        PSA_TestUtility testUtil = new PSA_TestUtility();
        Test.startTest();                            
            ApexPages.StandardController sc = new ApexPages.StandardController(new RSS_Form__c());                               
            PageReference pageRef = Page.RSSForm;
            pageRef.getParameters().put('id',RSSForm.id);
            pageRef.getParameters().put('OppId',opp.id);
            pageRef.getParameters().put('ContactType','admin');

            Test.setCurrentPage(pageRef);
            controller = new RSS_FormController(sc);
            controller.RSSForm = RSSForm;  
            controller.PostSales = true;
            controller.NewForm = true;
            controller.chosenList.add(new SelectOption(RSSTemplateTest.RSSTemplate.id,RSSTemplateTest.RSSTemplate.Name));
            for(SurveyQuestionResponse__c r:controller.responses)
            {            
                if(r.Survey_Question__r.Category__c == 'List of secure hostname')
                {
                    r.response__c ='https://www.google.com';
                }
                else
                {
                    r.response__c ='abcd';    
                }
                
            }

            controller.publishForm();

            Map<String,String> tSPNameToEmail = controller.TSPNameToEmail;
            String savedURl = controller.SavedURl;
            Boolean keepSaving = controller.KeepSaving;
            String OfflineFileName = controller.OfflineFileName;
            opportunity opp  =  controller.FromOpportunity;

        Test.stopTest();

    }


}