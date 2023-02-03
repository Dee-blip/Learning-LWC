@isTest(seeAllData=false)

public class DocuSign_EsignIntermediateControllerTest {


   //private static Apttus__APTS_Agreement__c agreement;
   static ApexPages.StandardController stdController;
   //private static Apttus_Proposal__Proposal__c proposal;
   private static Contact con;
   //static User
    static User dmlUser = utilTestClass.getTestRunUser();

   @testSetup
    static void setupMethod() {
        System.runAs(dmlUser) {
            Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
            Test.loadData(globalDescribe.get('Environment_Setup__c'), 'CS_Environment_Setup');
            Test.loadData(globalDescribe.get('Q2O_Custom_Settings__c'), 'Q2O_Custom_Settings');
            Test.loadData(globalDescribe.get('GSM_Custom_Settings__c'), 'CS_GSM_Custom_Settings');
            List<OA_eSign_Intermediate__c> eSignList = new List<OA_eSign_Intermediate__c>();
            OA_eSign_Intermediate__c e1 = new OA_eSign_Intermediate__c();
            e1.Name = 'Akamai Account Id';
            e1.Value__c = '1-599K';
            eSignList.add(e1);
            OA_eSign_Intermediate__c e2 = new OA_eSign_Intermediate__c();
            e2.Name = 'dsConfigRecordName';
            e2.Value__c = 'DSX-147';
            eSignList.add(e2);
            OA_eSign_Intermediate__c e3 = new OA_eSign_Intermediate__c();
            e3.Name = 'Recipient 1';
            e3.Value__c = 'Customer Signatory 1';
            eSignList.add(e3);
            OA_eSign_Intermediate__c e4 = new OA_eSign_Intermediate__c();
            e4.Name = 'Recipient 2';
            e4.Value__c = 'Customer Signatory 2';
            eSignList.add(e4);
            OA_eSign_Intermediate__c e5 = new OA_eSign_Intermediate__c();
            e5.Name = 'Recipient 3';
            e5.Value__c = 'Akamai RSM 1';
            eSignList.add(e5);
            OA_eSign_Intermediate__c e6 = new OA_eSign_Intermediate__c();
            e6.Name = 'Recipient 4';
            e6.Value__c = 'Akamai RSM 2';
            eSignList.add(e6);
            OA_eSign_Intermediate__c e7 = new OA_eSign_Intermediate__c();
            e7.Name = 'Self user profiles';
            e7.Value__c = '00eA0000000QkL2IAK';
            eSignList.add(e7);
            OA_eSign_Intermediate__c e8 = new OA_eSign_Intermediate__c();
            e8.Name = 'SendEmailReminder';
            e8.Value__c = 'true';
            eSignList.add(e8);
            OA_eSign_Intermediate__c e9 = new OA_eSign_Intermediate__c();
            e9.Name = 'User manager profiles';
            e9.Value__c = '00eA0000000dmONIAY';
            eSignList.add(e9);
            insert eSignList;

            List<Q2O_Custom_Settings__c> q2List = new List<Q2O_Custom_Settings__c>();
            Q2O_Custom_Settings__c q1 = new Q2O_Custom_Settings__c();
            q1.Name = 'TrialOnly';
            q1.value__c = 'Trial Only';
            q2List.add(q1);
            Q2O_Custom_Settings__c q2 = new Q2O_Custom_Settings__c();
            q2.Name = 'FullService';
            q2.value__c = 'Full Service';
            q2List.add(q2);
            Q2O_Custom_Settings__c q3 = new Q2O_Custom_Settings__c();
            q3.Name = 'FullServicePlusTrial';
            q3.value__c = 'Full Service + Trial';
            q2List.add(q3);
            insert q2List;

        }
    }

  
   private static testmethod void onlyForCodeCoverage_2(){
        Account acc2=utilTestClass.CreateAccount('Test acc__1');
        insert acc2;

        Opportunity opp = utilTestClass.CreateOpportunity('__Test_Oppty','1-Create'); 
        opp.CloseDate = Date.today().addMonths(4);
        opp.AccountId = acc2.Id;
        insert opp;

        Order_Approval__c oa = new Order_Approval__c();
        oa.Associated_Opportunity__c = opp.Id;
        oa.Order_Expires_Unless_Duly_Executed_By__c = Date.today().addMonths(8);
        insert oa;

        con=utilTestClass.CreateContact('abc','xyz');
        con.AccountId=acc2.Id;
        insert con;

        Test.startTest();
        dsfs__DocuSignAccountConfiguration__c config = new dsfs__DocuSignAccountConfiguration__c();
        config.dsfs__EmailBody__c = 'Test';
        insert config;

        ApexPages.currentPage().getParameters().put('id',oa.Id);
        stdController=new ApexPages.StandardController(oa);

        Contact con1=utilTestClass.CreateContact('test','test');
        con1.AccountId=acc2.Id;

        dsfs__DocuSign_Envelope_Recipient__c der = new dsfs__DocuSign_Envelope_Recipient__c();
        der.dsfs__DSER_ContactID__c =  con.Id;
        List<Attachment> attList = new List<Attachment>();
        Attachment att1 = new Attachment(); 
        att1.ParentId = oa.Id;
        att1.Name = 'Test Attch1';
        
        //Blob bodyBlob = Blob.valueOf('Unit Test Attachment Body');
        att1.body = Blob.valueOf('Unit Test Attachment Body 1');
        attList.add(att1);
        Attachment att2 = new Attachment(); 
        att2.ParentId = opp.Id;
        att2.Name = 'Test Attch2';
        
        //Blob bodyBlob = Blob.valueOf('Unit Test Attachment Body');
        att2.body = Blob.valueOf('Unit Test Attachment Body 2');        
        attList.add(att2);

        insert attList;

        Q2O_ESignIntermediateController classObj = new Q2O_ESignIntermediateController();
        classObj.newContact = con1;
        classObj.dseRecipient2 = null;
        classObj.dseRecipient1 = der;
        Q2O_ESignIntermediateController.DSsourceObject dsSRC2 = new Q2O_ESignIntermediateController.DSsourceObject(oa);
        classObj.srcObj =  dsSRC2;
        //classObj.srcObj = new DSsourceObject(oa);

        //Added extra
        classObj.canceltoOppty();
        //classObj.newContactSave();
        classObj.activateAddNewContact1();
        classObj.activateAddNewContact2();
        classObj.continueEsign();
        classObj.cancel();
        

        
        

        classObj.hasAssociatedObj = true;
        classObj.showError = true;
        classObj.showWarning = true;
        classObj.ErrorMessage = 'test';
        classObj.WarningMessage = 'test';
        classObj.associatedObj = 'test';
        classObj.selectedAttachments = attList;

        PageReference pg = classObj.validate();
        //List<Attachment> attListAtt = classObj.getSelectedAttachmentsWithBody();
        OA_EmailBlast_AttachmentWrapper emailBlast = new OA_EmailBlast_AttachmentWrapper();
        emailBlast.checked = true;
        emailBlast.attach = new ContentDocumentLink();
        emailBlast.parentType = null;
        list<OA_EmailBlast_AttachmentWrapper> blastList = new list<OA_EmailBlast_AttachmentWrapper>();
        blastList.add(emailBlast);
        classObj.oaAttachment = blastList;
        dsfs__DocuSign_Envelope_Recipient__c der1 = new dsfs__DocuSign_Envelope_Recipient__c();
        classObj.dseRecipient2 = der1;
        der.dsfs__DocuSign_Recipient_Role__c = 'test';
        classObj.dseRecipient1 = der;
        classObj.Next();

        



        classObj.hasAssociatedObj = true; 
        classObj.dsEnvelope = null;
        classObj.dsConfiguration = config;
        //srcObj = new DSsourceObject(oa);
        Q2O_ESignIntermediateController.DSsourceObject dsSRC3 = new Q2O_ESignIntermediateController.DSsourceObject(oa);
        classObj.srcObj =  dsSRC3;

        //classObj.srcObj = new DSsourceObject(oa);

        ContentVersion testContent = new ContentVersion(); 
        
        testContent.Title= 'testycontent';
        testContent.PathOnClient = 'testy';
        testContent.VersionData = blob.valueof('testng');
        insert testContent;
        testContent = [select id, ContentDocumentId from ContentVersion where id=:testContent.Id];


        
       ContentDocumentLink cdRecord = new ContentDocumentLink();
                                cdRecord.ContentDocumentId =testContent.ContentDocumentId;
                                cdRecord.ShareType = 'I';
                                cdRecord.LinkedEntityId = classObj.srcObj.Associated_Opportunity_Id;
                                cdRecord.Visibility = 'AllUsers';

        insert  cdRecord;
        Set<Id> ownerIds = new Set<Id>();
        Map<Id,String> userInfoMap = new Map<Id,String>();
        /*for(ContentDocumentLink conObj : [Select Id,ContentDocumentId from ContentDocumentLink where
                                         LinkedEntityId = :srcObj.Id OR LinkedEntityId = :srcObj.Associated_Opportunity_Id
                                         OR LinkedEntityId = :srcObj.Parent_Obj_Id]) {
            .add(conObj.ContentDocumentId);   
        }*/
        for(ContentDocument conDocObj : [Select Id,OwnerId from ContentDocument]){
                                             
                ownerIds.add(conDocObj.OwnerId);
            }
        if(ownerIds.size() > 0) {
                for(User userRec : [Select Id,Name from User where Id in :ownerIds]) {
                    userInfoMap.put(userRec.Id,userRec.Name);
                    }
                    }   
                
        OA_EmailBlast_AttachmentWrapper oaW;
        for(ContentDocument conDocObj : [Select Id,Title,ParentId,OwnerId,ContentModifiedDate from
                                             ContentDocument
                                             where Id in :classObj.contentDocIds Order by ContentModifiedDate]) {
                oaW = new OA_EmailBlast_AttachmentWrapper(conDocObj,userInfoMap);
                classObj.oaAttachment.add(oaW);
            }
        //Added extra
        string str = 'testtesttet.esttestt.etestt. esttetest. testtetesttestt.etestte. sttetesttes. ttetesttesttet.';
        classObj.createDocuSignEnvelopeDocument(null,1,str,testContent.Id,'File');

        classObj.getRoleValue('test');
        classObj.newContactCancel();


        classObj.init();
        classObj.newContact = con1;
        classObj.newContactSave();
        classObj.createTestMethod();
        Test.stopTest();
   }

    private static testmethod void testIfParentMSAIsSuperseded()
    {
        Account acc2=utilTestClass.CreateAccount('Test acc__1');
        insert acc2;

        Opportunity opp = utilTestClass.CreateOpportunity('__Test_Oppty','1-Create');
        opp.CloseDate = Date.today().addMonths(4);
        opp.AccountId = acc2.Id;
        insert opp;

        Order_Approval__c oa = new Order_Approval__c();
        oa.Associated_Opportunity__c = opp.Id;
        insert oa;

                    
    } 
    
    private static testmethod void testIfParentMSAIsAmended()
    {
        Account acc2=utilTestClass.CreateAccount('Test acc__1');
        insert acc2;

        Opportunity opp = utilTestClass.CreateOpportunity('__Test_Oppty','1-Create');
        opp.CloseDate = Date.today().addMonths(4);
        opp.AccountId = acc2.Id;
        insert opp;

        Order_Approval__c oa = new Order_Approval__c();
        oa.Associated_Opportunity__c = opp.Id;
        insert oa;

               
    }
}