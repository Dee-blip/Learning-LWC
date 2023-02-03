/***
    SC_ScrubIPCaseNotesMuleBatch_Test
    @author Sandeep Naga
    @Description : 


    @History
    --Developer           --Date            --Change
    Sandeep Naga      29th March 2019    Creation of test class
*/

@isTest(SeeAllData=false)
public class SC_ScrubIPCaseNotesMuleBatch_Test {

    //Static block to create test data
    static{

        //Create all custom settings
        utilTestClass.createCustomSettings();

        //Create other required custom settings
        Id profileId = [SELECT Id FROM Profile WHERE name = 'System Administrator'].Id;
        SC_IP_Scrub_Admin_Setting__c ipScrub = new SC_IP_Scrub_Admin_Setting__c(SetupOwnerId = profileId);
        ipScrub.Client_Id__c = '92b6aa36-ba93-4a96-9a5f-702509045bbc';
        ipScrub.Client_Certificate__c = 'EAA_KMI_Signed_Certificate';
        ipScrub.Hostname__c = 'https://qa.dash-ext.akamai.com/';
        ipScrub.Client_Secret__c = '9fbb8bd2-7e8b-479c-b628-896355b8e80f';
        ipScrub.End_Point_OAuth__c = 'oauth2/token';
        ipScrub.End_Point_IP_Scrub_Notes__c = 'casemanagement/v2/removenotesip';
        ipScrub.Scope__c = 'READ_AUTHORIZED_CONTACTS';
        insert ipScrub;
        
        
        //Create Account for the case
        Account acc = utilTestClass.CreateAccount('Test Account1');   
        acc.Support_Level__c = 'Premier';
        acc.Support_Advocate__c = true;
        insert acc;
        
        
		Id RecordType = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        //Create the case with required fields filled with appropriate data
        Case cs = new Case();
        cs.AccountId = acc.id;
        cs.Description = 'testTech Description';
        cs.RecordTypeId = RecordType;
        cs.Subject = 'testTech Subject';
        cs.Is_IP_Scrubbed__c = False;
        cs.Origin = 'Phone';
        cs.Validation_Override__c = true;
        cs.Status = 'Closed';
        
        insert cs;
        
        
        
        
        
    

        
    }



    Public static testMethod void callHttpCalloutTest()
    {
        // Set the Mock Class for the Callout class
        Test.setMock(HttpCalloutMock.class, new SC_ScrubIPCaseNotesHttpRequestMockClass(false));
        
        Test.startTest();


        DataBase.executeBatch(new SC_ScrubIPCaseNotesMuleBatch());

        Test.stopTest();
    }
    
}