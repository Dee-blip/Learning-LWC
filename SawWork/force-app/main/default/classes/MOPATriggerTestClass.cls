@isTest(seeAllData=true)
public class MOPATriggerTestClass {
    static testMethod void MOPA_test1() {
        Momentum_Order_Product_Approval__c momProdApp = new Momentum_Order_Product_Approval__c();
        momProdApp.workflow_id__c = 'abcdef';
        momProdApp.opportunity_id__c = 'ghijklm';
        momProdApp.momentum_order_id__c = 'nopqr';
        momProdApp.created_by_alias__c = 'abcdefgh';
        momProdApp.Order_Type__c = 'Direct';
        
		Test.startTest();  
        insert momProdApp;
        Test.stopTest();  
        System.assertNotEquals(null, momProdApp.Id);
        momProdApp = refreshMOPA(momProdApp.Id);
        System.assertNotEquals(null, momProdApp.ErrorLog__c);
    }
    
    static testMethod void MOPA_test2() {
        Opportunity oppty = new Opportunity();
        oppty = [Select Id, AKAM_Opportunity_ID__c, Deal_Type__c  from Opportunity where Deal_Type__c = 'Direct' AND StageName NOT IN ('Closed Won', 'Closed/Lost', 'Closed Duplicate', 'Closed Contract Ended') limit 1];
		//Approval_Workflow__c aw  = [select AKAM_Workflow_ID__c, isDraftable__c, isLockable__c from Approval_Workflow__c limit 1 ];
        Momentum_Order_Product_Approval__c momProdApp = new Momentum_Order_Product_Approval__c();
        momProdApp.workflow_id__c = 'F-PA-2173';
        momProdApp.opportunity_id__c = oppty.Id;
        momProdApp.momentum_order_id__c = '999999';
        momProdApp.created_by_alias__c = 'MUSER';
        momProdApp.Order_Type__c = 'Beta Service Order';
		Test.startTest();  
        insert momProdApp;
        Test.stopTest(); 
        System.assertNotEquals(null, momProdApp.Id);
        momProdApp = refreshMOPA(momProdApp.Id);
    }

    public static Momentum_Order_Product_Approval__c refreshMOPA(Id mopaID)
    {
    	return [Select Id, workflow_id__c, opportunity_id__c, momentum_order_id__c, created_by_alias__c, Order_Type__c, Product_Approval__c, ErrorLog__c from Momentum_Order_Product_Approval__c where Id = : mopaID];
    }
}