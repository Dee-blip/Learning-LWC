@isTest
public class L2Q_LeadandOpptyFlowControllerTest {
	@isTest
	static void testleadandOppty() {
		ApexPages.StandardController sc = new ApexPages.StandardController(Schema.getGlobalDescribe().get('Lead').newSObject());
		L2Q_PartnerFlowController lp = new L2Q_PartnerFlowController(sc);
		L2Q_FlowLeadConvert lf = new L2Q_FlowLeadConvert(sc);

	}
	@isTest
	static void testDeletefile() {
		L2Q_PartnerFlowController.getuserDetails();
		L2Q_PartnerFlowController.insertErrorlog('test','test','test');
		Test.startTest();
		ContentNote cn = new ContentNote();
		cn.Content = Blob.valueof('Hello there, How you doing?');
		cn.title = 'Joey';
		insert cn;
		try {
			L2Q_CustomExceptionData lc =  new L2Q_CustomExceptionData('testError','testMessage',00000,'apexcustomerror','User Message','TestClass');
			L2Q_PartnerFlowController.deleteuserFile(cn.Id);
			L2Q_PartnerFlowController.deleteuserFile('0692f000001G0ix');
		} catch (Exception ex) {}
		Test.stopTest();
	}
	@isTest
	static void testfindRecordsloadMore() {
		try {
			L2Q_PartnerFlowController.getuserDetails();
			L2Q_PartnerFlowController.getColumnheader('L2Q_FlowTablesDR0');
			L2Q_PartnerFlowController.loadMore('Account', ' Name ', 0, 10, '',' order by createddate desc ');
		} catch (Exception ex) {

		}

	}
}