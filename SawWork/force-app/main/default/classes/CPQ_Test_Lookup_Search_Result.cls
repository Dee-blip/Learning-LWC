/*
 * Test class for - CPQ_Custom_LookUp_Controller - search
 * Test class for - CPQ_Lookup_Search_Result 
*/
@isTest(seeAllData=false)
public with sharing class CPQ_Test_Lookup_Search_Result {
    //compareTo_should_work_with_two_null_titles
    @isTest
    static void checkTwoNulls() {
        CPQ_Lookup_Search_Result r1 = getSearchResult(null);
        CPQ_Lookup_Search_Result r2 = getSearchResult(null);
        
        Integer compareResult = r1.compareTo(r2);
        
        System.assertEquals(0, compareResult,'success');
    }
    //compareTo_should_work_with_this_null_title
    @isTest
    static void compareOneNull() {
        CPQ_Lookup_Search_Result r1 = getSearchResult(null);
        CPQ_Lookup_Search_Result r2 = getSearchResult('a');
        
        Integer compareResult = r1.compareTo(r2);
        
        System.assertEquals(1, compareResult,'success');
    }
    //compareTo_should_work_with_other_null_title
    @isTest
    static void compareAnotherNull() {
        CPQ_Lookup_Search_Result r1 = getSearchResult('a');
        CPQ_Lookup_Search_Result r2 = getSearchResult(null);
        
        Integer compareResult = r1.compareTo(r2);
        
        System.assertEquals(-1, compareResult,'success');
    }
    //compareTo_should_work_with_non_null_titles
    @isTest
    static void compareTwoNonNull() {
        CPQ_Lookup_Search_Result r1 = getSearchResult('a');
        CPQ_Lookup_Search_Result r2 = getSearchResult('b');
        
        Integer compareResult = r1.compareTo(r2);
        
        System.assertEquals(-1, compareResult,'success');
    }
    
    @isTest
    static void testGetter() {
        CPQ_ProductLaunchSetting__c testlaunchSetting = createLaunchSetting('CPQ_ProductLaunchSetting__c');
        CPQ_Lookup_Search_Result r = new CPQ_Lookup_Search_Result(testlaunchSetting.id, 'type', 'icon', 'title', 'subtitle');
        
        System.assertEquals(testlaunchSetting.id, r.getId(),'success');
        System.assertEquals('type', r.getSObjectType(),'success');
        System.assertEquals('icon', r.getIcon(),'success');
        System.assertEquals('title', r.getTitle(),'success');
        System.assertEquals('subtitle', r.getSubtitle(),'success');
    }
    
    private static CPQ_Lookup_Search_Result getSearchResult(String title) {
        return new CPQ_Lookup_Search_Result(null, null, null, title, null);
    }
    @isTest
    static void returnObjectRecords(){
        Test.startTest();
        datetime today = datetime.now();
        DateTime newDateTime = today.addMonths(1);
        PLU__c newLaunch = new PLU__c(Name= 'SEP-2020' , PLU_Date__c = newDateTime.date(),Status__c = 'Pending' );
        insert newLaunch;
        List<PLU__c> launchlist =  CPQ_Custom_LookUp_Controller.search('SEP-2020','PLU__c');
        List<PLU__c> invalidlaunchlist =  CPQ_Custom_LookUp_Controller.search('OCT-2020','PLU__c');
        Test.stopTest();
        System.assertEquals(!launchlist.isEmpty(),true,'success');
        System.assertEquals(newLaunch.name,'SEP-2020','success');
        System.assertEquals(invalidlaunchlist.isEmpty(),true,'failure');
        
    }
    private static CPQ_ProductLaunchSetting__c createLaunchSetting(String name) {
        CPQ_ProductLaunchSetting__c testlaunchSetting = new CPQ_ProductLaunchSetting__c(Name = name,Product_Mkt_Code__c='M-LC-107281');
        insert testlaunchSetting;
        return testlaunchSetting;
    }
}