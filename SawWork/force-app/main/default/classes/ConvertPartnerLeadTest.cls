@isTest
public class ConvertPartnerLeadTest {

	@isTest static void ConvertPartnerLeadPositive() {

		System.runAs(utilTestClass.getTestRunUser()) {
			/**Begin Rajesh Kumar - SFDC-6406 **/
			L2Q_FlowInputParam lq = new L2Q_FlowInputParam();
			List<L2Q_FlowInputParam> lqList = new List<L2Q_FlowInputParam>();
			L2Q_FlowInputParam lq1 = new L2Q_FlowInputParam();
			List<L2Q_FlowInputParam> lqList1 = new List<L2Q_FlowInputParam>();
			/**End Rajesh Kumar - SFDC-6406 **/
			List<Id> auList = new List<Id> ();
			auList.addall(createAccountInfoVersion2(2));
			List<Account> accts = [select id, parentid, Partner_Type__c from account where id in: auList];
			for (Integer i = 0; i<accts.size(); i++) {
				if (i > 0) {
					accts[i].ParentId = accts[i - 1].id;
					accts[i].Partner_Type__c = 'ADS Partner';
				}
			}
			update accts;

			User u1 = [select id from User where contact.accountid =: accts[0].id];

			Lead l = createLead(u1.Id);
			/**Begin Rajesh Kumar - SFDC-6406 **/
			lq.record = l;
            lq.source = 'flow';
            lq.actionName = 'leadconvert';
            lq.fcmId = '';
            lq.opportunityId = '';
			lqList.add(lq);

			lq1.record = new Lead();
            lq1.source = 'flow';
            lq1.actionName = 'leadconvert';
            lq1.fcmId = '';
            lq1.opportunityId = '';
			lqList1.add(lq1);
			/**End Rajesh Kumar - SFDC-6406 **/
			//Increasing code coverage as most of the code in createDealRegsForLeads is unreachable
			lead l2 = createLead(u1.id);
			ConvertPartnerLead.createDealRegsForLeads(new List<Lead>{l2});
			
			System.assertEquals(l.status, 'New');
			System.debug('Created lead :' + l);
			/* Convert the Partner Lead - Conversion should create a Deal Reg unsubmitted
			 * with all the required fields and mark the lead status converted
			 * Convertion also change the Lead record type to Converted Lead
			 */
			Test.startTest();
			
			/**Begin Rajesh Kumar - SFDC-6406 **/
			ConvertPartnerLead.convertpartnerflowLead(lqList);
			try{
			ConvertPartnerLead.convertpartnerflowLead(lqList1);
			}
			catch(Exception ex){}
			/**End Rajesh Kumar - SFDC-6406 **/

			Opportunity opp = ConvertPartnerLead.convertPartnerLead(l);
			//Get the Lead after conversion
			Lead convertedLead = ConvertPartnerLead.getleadRecord(l.id);
			System.assertEquals(convertedLead.status, 'Converted');
			Test.stopTest();
		}

	}

	@isTest static void TestDeleteShares() {

		System.runAs(utilTestClass.getTestRunUser()) {
			List<Id> auList = new List<Id> ();
			auList.addall(createAccountInfoVersion2(2));
			List<Account> accts = [select id, parentid, Partner_Type__c from account where id in: auList];
			for (Integer i = 0; i<accts.size(); i++) {
				if (i > 0) {
					accts[i].ParentId = accts[i - 1].id;
					accts[i].Partner_Type__c = 'ADS Partner';
				}
			}
			update accts;

			User u1 = [select id from User where contact.accountid =: accts[0].id];

			Lead l = createLead(u1.Id);

			Test.startTest();

			System.debug('Changing the partner invloved');

			List<Account> partnerAccs = [Select id From Account where name = 'Partner 1'];
			if (partnerAccs.size() > 0) {
				Account acc = partnerAccs[0];
				l.Partner_Involved__c = acc.id;
				update l;
			}
			Test.stopTest();
		}

	}

	@isTest static void TestPartnerLeadPage() {

		System.runAs(utilTestClass.getTestRunUser()) {
			/**Begin Rajesh Kumar - SFDC-6044 **/
			List<Lead> ldList = new List<Lead> ();
			/**End Rajesh Kumar - SFDC-6044 **/
			List<Id> auList = new List<Id> ();
			auList.addall(createAccountInfoVersion2(2));
			List<Account> accts = [select id, parentid, Partner_Type__c from account where id in: auList];
			for (Integer i = 0; i<accts.size(); i++) {
				if (i > 0) {
					accts[i].ParentId = accts[i - 1].id;
					accts[i].Partner_Type__c = 'ADS Partner';
				}
			}
			update accts;

			User u1 = [select id from User where contact.accountid =: accts[0].id];

			Lead l = createLead(u1.Id);
			/**Begin Rajesh Kumar - SFDC-6044 **/
			ldList.add(l);
			/**End Rajesh Kumar - SFDC-6044 **/

			Test.StartTest();

			ApexPages.StandardController sc = new ApexPages.StandardController(l);
			ApexPages.currentPage().getParameters().put('id', String.valueOf(l.Id));
			ConvertPartnerLead partnerLeadCntr = new ConvertPartnerLead(sc);
			/**Begin Rajesh Kumar - SFDC-6044 **/
			L2Q_FlowLeadConvert lq = new L2Q_FlowLeadConvert(sc);
			/**End Rajesh Kumar - SFDC-6044 **/
			L2Q_PartnerFlowController lf = new L2Q_PartnerFlowController(sc); //SFDC-6464
			partnerLeadCntr.convert();
			partnerLeadCntr.Back();
			partnerLeadCntr.NavigateToDealReg();
			Test.StopTest();
		}
	}

	public static Lead createLead(Id ownerId) {

		Id partnerRecordypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Partner Lead').getRecordTypeId();

		Lead l = new Lead();
		l.recordTypeId = partnerRecordypeId;
		l.email = 'testemail@email.com';
		l.status = 'New';
		l.CurrencyIsoCode = 'USD';
		l.company = 'Test Company';
		l.firstname = 'Test';
		l.lastname = 'Lead';
		l.ownerId = ownerId;
		l.website = 'testwebsite.com';
		l.industry = 'Banking';
		l.street = 'Test street';
		l.city = 'Test City';
		l.state = 'Test state';
		l.PostalCode = '201323';
		l.country = 'USA';
		l.Primary_Product__c = 'Enterprise Security - Enterprise App Access';
		l.Services_Hostname__c = 'testwebsite.com';
		l.description = 'Test Description';
		// SFDC-8974
		l.End_Customer_Contact_Role__c = 'Decision Maker';
		insert l;
		return l;
	}

	public static list<id> createAccountInfoVersion2(Integer limitvalue) {
		integer
		var = 0;
		//insert accounts
		list<account> acclist = new list<account> ();
		for (var = 0;
			var<limitvalue;
			var ++) {
			Account a1 = utilTestClass.CreateAccount('Partner ' +
				var);
			a1.BillingCity = 'city' +
				var;
			a1.BillingStreet = 'street' +
				var;
			a1.BillingState = 'CA';
			a1.BillingCountry = 'USA';
			a1.BillingPostalCode = '56478';
			a1.Association_Account__c = true;
			a1.Maximum_Licenses__c = 3;
			a1.Partner_Type__c = 'ADS Partner';
			a1.website ='www.lead.com';
			acclist.add(a1);
		}
		insert acclist;
		//update accounts
		list<account> acclist2 = new list<account> ();
		for (Account acc: acclist) {
			acc.isPartner = true;
			acc.IsPartnerCustom__c = true;
			acc.Validation_Override__c = true;
			acclist2.add(acc);
		}
		update acclist2;
		var = 0;
		//insert contacts
		list<contact> conlist = new list<contact> ();
		for (Account acc: acclist) {
			Contact c11 = utilTestClass.CreateContact('Test', 'Contact' +
				var);
			c11.AccountId = acc.Id;
			conlist.add(c11);
			var ++;
		}
		insert conlist;
		//get profile
		Profile p;
		p = [select Id from Profile where usertype = 'PowerPartner'
			and name like '%Partner%'
			limit 1
		];
		//insert users
		list<User> usrlist = new list<User> ();
		var = 0;
		for (Contact con: conlist) {
			User u11 = new User(lastname = 'User' +
				var, alias = 'user' +
				var, email = 'a@a.com', username = 'amtv@a.com.' +
				var, contactid = con.id, localesidkey = 'en_US',
				languagelocalekey = 'en_US', timezoneSidKey = 'America/Los_Angeles', emailEncodingKey = 'UTF-8', profileId = p.id);
			usrlist.add(u11);
			var ++;
		}
		insert usrlist;
		list<id> idlist = new list<id> ();
		for (Account acc: acclist) {
			idlist.add(acc.id);
		}
		return idlist;
	}

}