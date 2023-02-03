@isTest
private class EB_UtilApplication_Test
{
    /*
    Authors: satish
    Description: fetches the custom setting values
    
    Created Date :
    Modification Date and modifications done:
    1. 06/29/2010    included a test method to test new overloaded method to fetch value from EBCS_ApplicationTextArea, 
                     which stores texts with line breaks
                     removed unused custom setting values 
    2. 10/04/2010 included test method for retrieving values of new custom settings CR# 794802. 
    */  
    static testMethod void Init(){ 
	ManagedPkgErrorClass.isFromManagedPackage=false;	
    EBCS_Application__c aConfig = EBCS_Application__c.getInstance('LimitSQL');     
    aConfig.Value__c = '1000';    
    update aConfig;
    
    EBCS_Application__c aConfig1 = EBCS_Application__c.getInstance('DebugSQL');     
    aConfig1.Value__c = 'TRUE';
    update aConfig1;


    EBCS_Application__c aConfig5 = EBCS_Application__c.getInstance('EnvironmentURL');     
    aConfig5.Value__c = 'https://cs1.salesforce.com/';    
    update aConfig5;

    EBCS_Application__c aConfig6 = EBCS_Application__c.getInstance('RowsPerPage');     
    aConfig6.Value__c = '3';    
    update aConfig6;
    
  }
    static testmethod void test_getProperty()
    {
        Init();
        System.assertEquals(EB_UtilApplication.getProperty('DebugSQL'), 'TRUE');
        System.assertEquals(EB_UtilApplication.getProperty('RowsPerPage'), '3');
        System.assertEquals(EB_UtilApplication.getProperty('LimitSQL'), '1000');
        System.assertEquals(EB_UtilApplication.getProperty('EnvironmentURL'), 'https://cs1.salesforce.com/');
               
        //System.assertEquals(EB_UtilApplication.getProperty('DefaultFollowUpTaskComments', true), 'This is a follow up notification reminder, you need to reach out to the customer with the follow up notification for the associated Mailer record. Please ensure that you pick a Follow Up Notification Email Template prior sending mails.');
    }
    
    static testmethod void test_getProperty_RowsPerPage()
    {
        Init();
        System.assertEquals(EB_UtilApplication.getProperty_RowsPerPage(), '3');
    }

    static testmethod void test_getProperty_DebugSQL(){
        Init();
        System.assertEquals(EB_UtilApplication.getProperty_DebugSQL(), 'TRUE');
    }
    
    static testmethod void test_getProperty_EnvironmentURL(){
        Init();
        System.assertEquals(EB_UtilApplication.getProperty_EnvironmentURL(), 'https://cs1.salesforce.com/');
    }

    static testmethod void test_getProperty_LimitSQL(){
        Init();
        System.assertEquals(EB_UtilApplication.getProperty_LimitSQL(), '1000');
    }


    // added as part of 1.12 release. Test cases for 2 new cutom application fields
    /*
	 Author : Jayalakshmi A
	 Description: This method is a test case for retrieving values of new custom settings CR# 794802.
	 Created On: 10/04/2010
	*/
    static testmethod void test_getPropertyFromJS(){
    	EBCS_Application__c config = EBCS_Application__c.getInstance('SingleMailsBatchSize');     
    	config.Value__c = '1000';    
    	update config;
		Integer val= EB_UtilApplication.getPropertyFromJS('SingleMailsBatchSize');
		system.assertEquals(val,1000);
		
		EBCS_Application__c config1 = EBCS_Application__c.getInstance('UpdateTemplateBatchSize');     
    	config1.Value__c = '100';    
    	update config1;
		Integer val1= EB_UtilApplication.getPropertyFromJS('UpdateTemplateBatchSize');
		system.assertEquals(val1,100);
    }
    
}