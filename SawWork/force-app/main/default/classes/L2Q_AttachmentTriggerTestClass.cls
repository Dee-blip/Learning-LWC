@isTest(seeAllData=false)
public class L2Q_AttachmentTriggerTestClass
{
	static
	{
		utilTestClass.insertCustomSettings();
	}

	static testmethod void testAttachmentChanges()
	{
		Account testAccount = utilTestClass.CreateAccount('Test Account');
		insert testAccount;

		String b64 = EncodingUtil.base64Encode(Blob.valueof('this is so much fun.. hahaha'));
		Attachment a = new Attachment(parentId = testAccount.Id, name = 'tada', body = Blob.valueOf(b64));
		insert a;

		List<SObject> lst = new List<SObject>();
		lst.add(a);

		try {
			L2Q_AttachmentTriggerClass.updateDraftInvoiceForDeletedAttachment(lst);
		} catch (Exception e){

		}


	}
}