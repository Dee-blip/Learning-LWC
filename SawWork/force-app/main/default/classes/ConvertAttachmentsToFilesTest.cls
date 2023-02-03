@isTest
public with sharing class ConvertAttachmentsToFilesTest 
{
	public ConvertAttachmentsToFilesTest() 
	{
     
	}

	static testmethod void oneTestToTestThemALL() 
	{
		Account acc = new Account();
        acc.Name = 'TestABC';
        acc.Vertical__c = 'Gaming';
        acc.Sub_Vertical__c = 'Console Mfs';
        insert acc;
        String b64 = EncodingUtil.base64Encode(Blob.valueof('this is so much fun.. hahaha'));
        Attachment a = new Attachment(parentId = acc.Id, name = 'tada', body = Blob.valueOf(b64));
        Attachment b = new Attachment(parentId = acc.Id, name = 'tada123', body = Blob.valueOf(b64));
        /* insert the attachment */
        insert (new List<Attachment>{a,b});
        List<ContentDocumentLink> condDocIds = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId = :acc.Id];
        delete condDocIds;

        Test.startTest();

        ConvertAttachmentsToFiles obj = new ConvertAttachmentsToFiles(new List<Id>{a.Id,b.Id});
        ConvertAttachmentsToFiles oneObjectTest = new ConvertAttachmentsToFiles(2019,'Account');
        ConvertAttachmentsToFiles yearTest = new ConvertAttachmentsToFiles(0,2019);
        ConvertAttachmentsToFiles fileIdTest = new ConvertAttachmentsToFiles('dummyfileid');
        DataBase.executeBatch(obj);
             

        Test.stopTest();

	}
}