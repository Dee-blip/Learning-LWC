@isTest
private class OA_EmailBlast_TestClass 
{
    private static Map<String, GSM_Settings__mdt> testcaseCustomSettings = GsmUtilClass.getGSMSettingValue();
        
    static User usr;
    static Account acc;
    static Opportunity opp;
    static Order_Approval__c oa;

    private static Boolean initFlag = false;
        
    /**
        CreateUser()
        - Return a new User with selected Alias, Profile and Role
    */
    private static User CreateUser(String pUsrAlias, String pProfile, String pRole)
    {
        Profile pr = [select Id from Profile where Name=:pProfile][0];
        UserRole role = [select Id, Name from UserRole where Name=:pRole][0];
        User newUser = new User(alias = pUsrAlias, 
                                email=pUsrAlias+'@akamai.com',
                                emailencodingkey='UTF-8', 
                                lastname=pUsrAlias, 
                                languagelocalekey='en_US',
                                localesidkey='en_US', 
                                timezonesidkey='America/Los_Angeles', 
                                username=pUsrAlias+'@akamai.com.tclass',
                                profileid = pr.Id, 
                                UserRoleId = role.Id );
        return newUser;     
    }
    /**
        CreateAccount()
    */
    private static Account CreateAccount(String pAccName, Id pOwnerId)
    {
        Account newAccount = new Account();
        newAccount.Name = pAccName;
        newAccount.OwnerId = pOwnerId;
        newAccount.BillingCountry = 'India';
        newAccount.BillingState = 'Delhi';
        return newAccount;
    }
    /**
        CreateOpportunity()
    */
    private static Opportunity CreateOpportunity(String pOppName, Id pAccId)
    {
        Opportunity newOpp = new Opportunity();
        newOpp.Name = pOppName;
        newOpp.AccountId = pAccId;
        newOpp.StageName = '1-Create';
        newOpp.CloseDate = Date.today().addMonths(4);       
        return newOpp;
    }   
    /**
        CreateOrderApproval()
    */      
    private static Order_Approval__c CreateOrderApproval(Opportunity pOpp)
    {
        String returnMsg = OrderApprovalClass.Create_OrderApproval(pOpp.Id, pOpp.RecordTypeId+'',pOpp.StageName);
        return [select  Id, 
                    Approvals_Required__c, 
                    Associated_Opportunity__c
                from Order_Approval__c 
                where Associated_Opportunity__c=:pOpp.Id][0];
    }
    /**
		createAccountReassignmentRule()
			- generates a new AccountReassignmentRule based on parameters
			- returns Account_Reassignment_Rule__c		
	*/
	public static Account_Reassignment_Rule__c  createAccountReassignmentRule(User user)
	{
		Account_Reassignment_Rule__c  tempRule = new Account_Reassignment_Rule__c();
		temprule.Name = user.Name + '_Rule';
		temprule.Associated_User__c = user.Id;
			temprule.User_Role__c = testcaseCustomSettings.get('User_Role').Value__c;
		return tempRule;
	}
    /**
        RefreshOppty(Opportunity[] pOppList)
        - Refresh a list of Opportunities
    */
    private static Opportunity[] RefreshOppty(Opportunity[] pOppList)
    {
        return [select Id,
                       Name,
                       StageName,
                       RecordTypeId
                from Opportunity
                where Id IN :pOppList];
    }
    /**
        RefreshOppty(Opportunity pOpp)
        - Refresh a single Opportunity
    */  
    private static Opportunity RefreshOppty(Opportunity pOpp)
    {
        return RefreshOppty(new Opportunity[]{pOpp})[0];
    }   
    /**
        CreateAttachment(Id parentId)
    */
    private static Attachment CreateAttachment(String pName, Id pParentId)
    {
        Attachment att = new Attachment(); 
        att.ParentId = pParentId;
        att.Name = pName;
        
        //Blob bodyBlob = Blob.valueOf('Unit Test Attachment Body');
        att.body = Blob.valueOf('Unit Test Attachment Body');
        
        return att;
    }
    /**
        Init()
    */
    private static void Init()
    {
    	/*
        if(initFlag)
            return;
                   
        usr = CreateUser('TST_USR', 'Sales - Rep', testcaseCustomSettings.get('User_Role').Value__c);
        insert usr;

		Account_Reassignment_Rule__c rule = createAccountReassignmentRule(usr);
		System.runAs(usr){insert rule;}
        
        acc = CreateAccount('__OA_Eblas_Test_Account', usr.Id);
        System.runAs(usr){insert acc;}
        opp = CreateOpportunity('__OA_Eblas_Test_Opp', acc.Id);
        System.runAs(usr){insert opp;}
        opp = RefreshOppty(opp);
        System.runAs(usr){oa = CreateOrderApproval(opp);}
        Attachment att1 = CreateAttachment('_TEST_EB_ATT_OPP', opp.Id);
        Attachment att2 = CreateAttachment('_TEST_EB_ATT_OA', oa.Id);
        System.runAs(usr){insert new Attachment[]{att1, att2};}
        
        initFlag = true;
        */
    }
    static testMethod void myUnitTest() 
    {
    	/*
        Init();
        
        PageReference pageRef = Page.OA_EmailBlast;
        pageRef.getParameters().put('id', oa.id);
        Test.setCurrentPageReference(pageRef);
        OA_EmailBlast_Controller controller = new OA_EmailBlast_Controller();
        controller.sendEmail();
        */     
    }
}