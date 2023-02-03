/*
Created by Sausharm on 26/02/2018 Added Test class for GSM_Lite_Controller_Attachment

*/

@isTest(seeAllData=false)
public class GSM_Lite_Controller_AttachmentTest 
{

	static testMethod void testGetInitValues() 
	{
		        Account acc = new Account();
                acc.Name = 'TestABC';
                acc.Vertical__c = 'Gaming';
                acc.Sub_Vertical__c = 'Console Mfs';
                insert acc;
                Map<String,List<String>> returnMap1 = GSM_Lite_Controller_Attachment.getInitValues(acc.Id);
                System.assertEquals(returnMap1.get('Account')[1],'TestABC');

                Opportunity opp = new Opportunity();
                opp.Account = acc;
                opp.AccountId = acc.Id;
                opp.Name = 'OppName';
                opp.Deal_Type__c = 'Direct';
                opp.StageName = '0-Plan';
                opp.CloseDate = Date.today();
                opp.CurrencyIsoCode = 'BRL';
                insert opp;
                Map<String,List<String>> returnMap2 = GSM_Lite_Controller_Attachment.getInitValues(opp.Id);
                System.assertEquals(returnMap2.get('Account')[1],'TestABC');

                Order_Approval__c oa = new Order_Approval__c();
                oa.Associated_Opportunity__c = opp.Id;
                insert oa;
                Map<String,List<String>> returnMap3 = GSM_Lite_Controller_Attachment.getInitValues(oa.Id);
                System.assertEquals(returnMap3.get('Account')[1],'TestABC');
	}

	static testMethod void testInsertDocumentRepoRecord() 
	{
		Account acc = new Account();
        acc.Name = 'TestABC';
        acc.Vertical__c = 'Gaming';
        acc.Sub_Vertical__c = 'Console Mfs';
        insert acc;
		String  idReturn = GSM_Lite_Controller_Attachment.insertDocumentRepoRecord('test', acc.Id, String.valueof(System.today()),  String.valueof(System.today()), 'Akamai Standard', 'Reseller / NAP & Amendments', null, null, acc.Id );
		System.assert(!idReturn.contains('Error'));
		System.assertNotEquals(null,idReturn);

	}

	static testMethod void testAddAttachmenttoRecord() 
	{
		Account acc = new Account();
        acc.Name = 'TestABC';
        acc.Vertical__c = 'Gaming';
        acc.Sub_Vertical__c = 'Console Mfs';
        insert acc;
		String body1 = 'AAAAAA BBBBBBBBB CCCCCCC DDDDDDD EEEEEEE FFFFFFFF';
		Blob b = Blob.valueOf(body1);
		String base64Data = EncodingUtil.base64Encode(b);


		Id fileId = GSM_Lite_Controller_Attachment.uploadFiles(acc.Id, 'Test Attachment for Parent',base64Data, 'text/plain', '');
		 
		

		GSM_Lite_Controller_Attachment.addAttachmenttoRecord(acc.Id, fileId);
	}
	
}