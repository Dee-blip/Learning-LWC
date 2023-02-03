/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
 @isTest 
 public with sharing class PACE_ContingencyEditExtensionTestClass{
 
 static testMethod void validate() {
 
    PACE_Review_Calendar__c testCalendar = new PACE_Review_Calendar__c(Name = 'September', Review_Date__c = System.now().date()+1500);
    insert testCalendar;
    
   Apexpages.StandardController stdController = new Apexpages.StandardController(testCalendar);
   PACE_ContingencyEditExtension calendarObject = new PACE_ContingencyEditExtension(stdController); 
    
        String URL1 = System.URL.getSalesforceBaseUrl().toExternalForm();
        String id=testCalendar.Id;
        String URL2 = URL1 + id;
        PageReference pageRef;
       // save 
        String url='/apex/PACE_NewContingency?retURL='+URL2;
        pageRef=new PageReference(url);
           
        test.setCurrentPageReference(pageref);
        
        calendarObject.save();
       
       // save and new 
        string s = URL1+'/apex/newcontingency?retURL='+URL2;
        pageRef=new PageReference(s);
             
        test.setCurrentPageReference(pageref);
        
        calendarObject.saveandnew();
        
       // cancel 
        pageRef=new PageReference(url);
           
        test.setCurrentPageReference(pageref);
        
        calendarObject.cancel();
 }

 }