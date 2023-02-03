/** Author:Rajesh Kumar 
JIRA#: SFDC - 5779
Descr : This Class Covers Fund Request Trigger Class Approve and Cancel Scenario 
*/

/*** Begin Rajesh Kumar JIRA# SFDC - 5779 */
@isTest(seeAllData = false)
private class FundRequestTriggerClassTest {
 static User dmlUser = new User(id = UserInfo.getUserId());
 @TestSetup
 static void intializeData() {
  System.runAs(utilTestClass.getTestRunUser()) {
   SObjectFactory.createPartnerUsers(1);
   // User partnerUser = SobjectRepository.getPartnerUser();

  }
 }

 static testmethod void testfundRequest() {
  User partnerUser = SobjectRepository.getPartnerUser();

  System.runAs(partnerUser) {
   Test.startTest();
   //Creating BU Plan
   SFDC_Channel_Account_Plan__c cap = new SFDC_Channel_Account_Plan__c(Partner_Account__c = partnerUser.Contact.AccountId, Name = '__Test__Partner__Plan');
   Insert cap;
   // Creating MDF Plan
   Partner_Marketing_Plan__c pmp = new Partner_Marketing_Plan__c(Business_Plan__c = cap.Id, Partner__c = partnerUser.Contact.AccountId, Name = '__Test_Partner__MDF__Plan');
   Insert pmp;
   // Creating PMA
   Partner_Marketing_Activity__c pma = new Partner_Marketing_Activity__c(Activity_Status__c = 'Approved', Forecast_DR__c = 0, Forecast_Leads__c = 0, Activity_Cost__c = 400, Partner_Marketing_Plan__c = pmp.id, Name = '__Test_MDF_Activity__', Validation_Override__c = true, Activity_Country__c = 'USA', Activity_Description__c = 'Test');
   Insert pma;
   // Changing MDF Plan Status
   pmp.Plan_Status__c = 'Approved';
   update pmp;
   // Creating Fund Budget
   SFDC_Budget__c fb = utilTestClass.CreateFundBudget(200);
   fb.account__c = partnerUser.Contact.AccountId;
   fb.Start_Earned_Date__c = system.today();
   fb.End_Earned_Date__c = system.today();
   fb.Amount__c = 200;
   fb.Partner_Marketing_Plan__c = pmp.id;
   insert fb;
   //Creating FUnd request
   SFDC_MDF__c fr = utilTestClass.CreateFundRequest('__Test__FR__Name', 200);
   fr.Activity_Date__c = System.today();
   fr.Program_End_Date__c = System.today();
   fr.Account__c = partnerUser.Contact.AccountId;
   fr.Program_Type__c = 'Advertising';
   fr.Partner_Marketing_Activity__c = pma.Id;
   fr.Program_Description__c = 'Test';
   insert fr;
   fr.status__c = 'Approved';
   update fr;
   // Cancelling Fund Request
   fr.Cancelled__c = true;
   update fr;
   Test.stopTest();

  }


 }
}
/*** End Rajesh Kumar JIRA# SFDC - 5779 */