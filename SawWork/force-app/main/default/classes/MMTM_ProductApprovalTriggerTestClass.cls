/* Owner - Shiv Gautam (Momentum)
   */

@isTest(seeAllData=true)
public class MMTM_ProductApprovalTriggerTestClass {
   
    static testmethod void getOpportunityTest(){
     
        	Profile p = [SELECT Id FROM Profile WHERE Name like '%System Admin%'][0];
            User u = new User(alias = 'someUser', email='salesop@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__old_owner@akamai.com',profileid =p.Id);
            u.isActive=true;
            insert u;
            Account acc = utilTestClass.CreateAccount('__Test Account');
            acc.OwnerId =u.Id;       
            insert acc;                      
            Opportunity oppty = utilTestClass.CreateOpportunity('__Test Oppty','1-Lead Identification');
            oppty.AccountId =acc.Id;
            oppty.OwnerId = u.Id;
            oppty.CloseDate = Date.today().addMonths(4);           
            insert oppty;
        	Opportunity opp=[Select Id,AKAM_Opportunity_ID__c From Opportunity where Id=:oppty.Id];
        	Order_Approval__c oa = new Order_Approval__c();
            oa.Associated_Opportunity__c = oppty.Id;
            insert oa;
			Approval_Workflow__c aw= new Approval_Workflow__c();
        	aw.AKAM_Workflow_ID__c='test';
        	insert aw;
			Product_Approvals__c pa= new Product_Approvals__c();
        	pa.Status__c='New';
        	pa.Opportunity__c=oppty.Id;
        	pa.Order_Approval__c=oa.Id;
        	pa.Approval_Workflow__c=aw.Id;
        	pa.Order_Id__c='1234';
        	insert pa;
        
        	Momentum_Order_Product_Approval__c mpa = new Momentum_Order_Product_Approval__c();
        	mpa.Product_Approval__c=pa.Id;
        	mpa.workflow_id__c='test';
        	mpa.momentum_order_id__c='1234';
        	insert mpa;
        	
        	//Product_Approvals__c pap = [Select Id,Status__c from Product_Approvals__c where Id = :pa.Id];
        	//
        	mpa.Product_Approval__c = pa.Id;
        	update mpa;
        	pa.Status__c='APPROVED';
        	update pa;
        	
        	pa.Status__c='REJECTED';
        	update pa;
        	
	        Momentum_Order_Product_Approval__c updatedmpa =[Select Id,approval_status__c from Momentum_Order_Product_Approval__c where Id=:mpa.Id];
			//System.assertEquals(updatedmpa.approval_status__c, 'APPROVED');        	
       	
    }
}