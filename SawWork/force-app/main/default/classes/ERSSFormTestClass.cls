@isTest(SeeAllData=false)
public class ERSSFormTestClass {
	private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    static User dmlUser = utilTestClass.getTestRunUser();


    // Setup method to create test data.
    @testSetup
    static void setupMethod() {
    	System.runAs(dmlUser) {  
    		ManagedPkgErrorClass.isFromManagedPackage = false;
            /* Start Of Custom Setting Insertion */
            Test.loadData(globalDescribe.get('Communities_Settings__c'), 'CS_Communities_Settings');
             //SFDC-2572
            //Test.loadData(globalDescribe.get('PRM_Settings__c'), 'CS_PRM_Settings');
            Test.loadData(globalDescribe.get('Environment_Setup__c'), 'CS_Environment_Setup');

            List<User> userList = new List<User>();
            List<Account> accountRecs = new List<Account>();
            String user_role = GsmUtilClass.getGSMSettingValue('User_Role');
            User accOwnerUser = utilTestClass.CreateUser('newUser', user_role, 'Sales Operations');
            userList.add(accOwnerUser);
            User usrSysAdmin = utilTestClass.CreateUser('SysAdmin', 'Worldwide', 'System Administrator');
            userList.add(usrSysAdmin);
            insert userList; 

    		List<Account> acclist = new List<Account>();
            Account acc = new Account();
            acc.Name = '__Test Account';
            acc.OwnerId = accOwnerUser.Id;
            acc.BillingCountry = 'India';
            acc.BillingState = 'Delhi';
            acclist.add(acc);
            insert acclist;

            List<Opportunity> oppList = new List<Opportunity>();
            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty ERSS','1. Identify Need');
            oppty.AccountId = acc.Id;
            oppty.CloseDate = Date.today().addMonths(4);
            oppList.add(oppty);
            insert oppList;

            RSS_Form__c r = new RSS_Form__c();
			r.Name = 'Test Form Test';
			r.Opportunity__c = oppty.Id;
			r.published__c = true;
			insert r;
    	}
    }

    static testmethod void erssFormFunctionality() {
    	Opportunity opp = [Select Id,Name from Opportunity where Name = '__Test Oppty ERSS'];
    	PageReference pageRef = Page.eRSSFormNavigate;
        pageRef.getParameters().put('oppId',opp.Id);

        Test.setCurrentPage(pageRef);
        ERSSFormClass err = new ERSSFormClass();
        
        //CFA_SendEmailController fruc1 = new CFA_SendEmailController();
        //CFA_SendEmailController.createConfirmSendTestMethod();
        CFA_ConfirmAttachmentController fruc = new CFA_ConfirmAttachmentController();
        //CFA_ConfirmAttachmentController.createConfirmAttTestMethod();
    }
    
        static testmethod void erssFormFunctionality2() {
                Opportunity opp = [Select Id,Name, AccountId from Opportunity where Name = '__Test Oppty ERSS'];
                Partner_Order_Acceptance_Document__c poad = new Partner_Order_Acceptance_Document__c();
                poad.opportunity__c = opp.Id;
                poad.Validation_Override__c = true;
                insert poad;

                ContentVersion conVer = L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Name', 'Name', 'Test Data');
                insert conVer;

                ContentVersion conVerdata = [Select Id, ContentDocumentId From ContentVersion Where Id = :conVer.Id];

                ContentDocumentLink conDocLink = L2Q_ContentDocumentUtilClass.setContentDocumentLink(conVerdata.ContentDocumentId, poad.Id, 'I', 'AllUsers');
                insert conDocLink;

                poad.Attachment__c = conVerdata.Id;
                update poad;

                ContentVersionAttribute__c conAttb = L2Q_ContentDocumentUtilClass.setContentVersionAttribute(conVer.Id, 'Partner Account', opp.AccountId);
                L2Q_POADBatchFixer poadClass = new L2Q_POADBatchFixer();
                Database.executeBatch(poadClass);
                
                ContentDocument conDocument = [SELECT Id, Title, OwnerId, ContentModifiedDate, ParentId FROM ContentDocument WHERE Id =:conVerdata.ContentDocumentId];
                OA_EmailBlast_AttachmentWrapper oa = new OA_EmailBlast_AttachmentWrapper();
                OA_EmailBlast_AttachmentWrapper qa2 = new OA_EmailBlast_AttachmentWrapper(oa);
                OA_EmailBlast_AttachmentWrapper oa3 = new OA_EmailBlast_AttachmentWrapper(conDocLink);
                String str = OA_EmailBlast_AttachmentWrapper.getObjType('Obj');
                Map<Id,String> userInfoMap = new Map<Id,String>();
                userInfoMap.put(conVerdata.ContentDocumentId, UserInfo.getUserId());
                OA_EmailBlast_AttachmentWrapper oa4 = new OA_EmailBlast_AttachmentWrapper(conDocument, userInfoMap);
                String strrrr = OA_EmailBlast_AttachmentWrapper.getObjType(conDocument.Id);
        }

}