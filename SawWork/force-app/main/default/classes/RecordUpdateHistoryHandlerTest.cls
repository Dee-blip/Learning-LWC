@isTest
public class RecordUpdateHistoryHandlerTest {

	static testmethod void testRecordUpdateHistory(){

		Account acc = utilTestClass.CreateAccount('__Test Account123');
		acc.Type = 'Lead';
		acc.Website = 'www.test.com';
		insert acc;

		acc.Website = 'www.akamai.com';
		update acc;

	}

}