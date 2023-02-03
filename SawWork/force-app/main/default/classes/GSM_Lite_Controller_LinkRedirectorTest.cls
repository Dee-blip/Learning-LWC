@isTest(seeAllData=false)
public class GSM_Lite_Controller_LinkRedirectorTest 
{
	static testMethod void testRedirectToURL() 
    {
    	Account newAccount = new Account();
        newAccount.Name = 'pAccName';
       
        insert newAccount;
    	Opportunity obj = new Opportunity();
    	obj.AccountId = newAccount.Id;
    	obj.Name='test'; 
    	obj.StageName = '1. Identify Need';
    	obj.CloseDate = system.today().adddays(7);
    	insert obj;
        
        GSM_LITE_SETTING__c gsm = new GSM_LITE_SETTING__c();
        gsm.name= 'Contracts';
        gsm.ClassicLink__c = '/a04?rlid=00NA0000003fwIt&id=[ID]';
        gsm.LightningLink__c = '/one/one.app?source=aloha#/sObject/[ID]/rlName/Merge_Contracts__r/view';
        insert gsm;
        
    	ApexPages.StandardController sc = new ApexPages.StandardController(obj);

    	GSM_Lite_Controller_LinkRedirector gs = new GSM_Lite_Controller_LinkRedirector(sc);

    	System.assertnotEquals(null,gs.redirectToURL());
        System.assertnotEquals(null,gs.addPartnerContact());
    }
}