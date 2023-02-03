@isTest(seeAllData=false)
public class SF1_Controller_ListViewObjSelectTest {
    
    static testmethod void accessAllowedToCurrentUserProfileTest()
    {

      Profile pf=[select id from profile where name ='Sales - Partner Account Executive'][0];
  
      User paeUser = new User(Alias = 'standt', Email='standarduser@akamai.com', 
      EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
      LocaleSidKey='en_US', ProfileId = pf.id, 
      TimeZoneSidKey='America/Los_Angeles', UserName='standarduser@akamai.com');

      /*System.runAs(paeUser) {       
      List<String> testResult = SF1_Controller_ListViewObjectSelection.getEnabledObjectsForListView();  
      } */

      System.runAs(paeUser) {    
      SF1_Enabled_ListViews__c enlist=new SF1_Enabled_ListViews__c();
      enlist.Enabled_Objects__c ='Account,Activity';
      enlist.Name='sample';
      insert enlist;   
      List<String> testResult = SF1_Controller_ListViewObjectSelection.getEnabledObjectsForListView();  
      } 
    }

}