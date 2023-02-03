@isTest
public class DeleteRecordsBatchJobTest {

	static testmethod void testDeleteRecordsBatch(){

		Account acc1 = utilTestClass.CreateAccount('__Test Account123');
		acc1.Type = 'Lead';
		acc1.Website = 'www.test.com';
		insert acc1;

		String query = 'select Id from Account';
		DeleteRecordsBatchJob d = new DeleteRecordsBatchJob(query);
		Database.executeBatch(d,2000);
}

}