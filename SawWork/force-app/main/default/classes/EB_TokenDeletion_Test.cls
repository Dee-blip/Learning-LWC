/***
Author: Sharath
Created: 9/21/2010
Description: Test class to cover the scheduling of the Apex job to delete the tokens of the past week
CR 796377: Tokenizing Selection of Accounts in the Mailer Wizard process 
*/
@istest
class EB_TokenDeletion_Test {
static testmethod void test() {
ManagedPkgErrorClass.isFromManagedPackage=false;
Test.startTest();
		// Schedule the test job
		String scheduleExpression = '0 0 1-23 * * ?';
		String jobId = System.schedule('test', scheduleExpression, new EB_TokenDeletion());
Test.stopTest();
CronTrigger ct = [SELECT id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE id = :jobId];
// Verify the expressions are the same  
System.assertEquals(scheduleExpression, ct.CronExpression);

}
}