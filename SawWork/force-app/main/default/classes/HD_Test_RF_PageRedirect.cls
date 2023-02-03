/*
Template: Apex Test Class

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date :

Base Line : Uses as part of Client/Staff redirection

Purpose : used as global redirector for Client/Staff

Usage :  Does Unit testing for HD_RF_PageRedirect

Class/Trigger Asssociated : HD_RF_PageRedirect

Controller (Boolean): false

Page Used/Asssociated (default -> NONE) : HDRFRedirect.page

Other Component Used : HD_REDIRECT_CONTROL_URL_SETTING (Custom Settings)
 * Modification Log ===============================================================
 * Date               Author            Modification
 * Oct 18th, 2021     Aneesh Budnar     PRTORES-977 - Fix Test class failures
*/
@isTest(SeeAllData = false)
public with sharing class HD_Test_RF_PageRedirect {

    static {
        List<HD_REDIRECT_CONTROL_URL_SETTING__c> urlSetting =  new List<HD_REDIRECT_CONTROL_URL_SETTING__c>();
        urlSetting.add(new HD_REDIRECT_CONTROL_URL_SETTING__c(name = 'HD_INCIDENT_CONSOLE', value__c = '/servlet/servlet.Integration?lid=01rG0000000X4WA&ic=1'));
        urlSetting.add(new HD_REDIRECT_CONTROL_URL_SETTING__c(name = 'HD_RF_HOME', value__c = '/servlet/servlet.Integration?lid=01rG0000000VHuY&ic=1'));
        urlSetting.add(new HD_REDIRECT_CONTROL_URL_SETTING__c(name = 'HD_INCIDENT_CONSOLE_REDIRECT', value__c = 'TRUE'));
        urlSetting.add(new HD_REDIRECT_CONTROL_URL_SETTING__c(name = 'HD_staff_profile', value__c = 'ServiceDesk Staff'));
        insert urlSetting;
    }


//Creating RunAs Method for user substitution
    public static User runAsUser(String profileName, boolean IsStaffUser ) {
        User u = null;
        if ( profileName == '' || profileName == null ) {
            profileName = 'System Administrator';
        }
        System.debug('Current Profile Name: ' + profileName);
        // Setup test data
        // This code runs as the system user
        Profile p = [ SELECT Id FROM Profile WHERE Name = : profileName limit 1 ];
        if ( p == null ) {
            p = [ SELECT Id FROM Profile WHERE Name = 'System Administrator' limit 1 ];
        }
        try {
            u = [ SELECT Id, FirstName, LastName, Email, BMCServiceDesk__IsStaffUser__c from User WHERE ProfileId = : p.Id AND IsActive = true AND BMCServiceDesk__IsStaffUser__c = : IsStaffUser limit 1];
            System.debug('USER Details ---> ' + u);
        }//try
        catch ( Exception e ) {
            System.debug('[]Exception: ' + e.getMessage());
            System.debug('#### Heman' + p.Id + ' ' + IsStaffUser);
            u = [ SELECT Id, FirstName, LastName, Email, BMCServiceDesk__IsStaffUser__c from User WHERE ProfileId = : p.Id AND IsActive = true AND BMCServiceDesk__IsStaffUser__c = : IsStaffUser limit 1];
            System.debug('Exception clause USER Details ---> ' + u);
        }//catch()
        return u;

    } //public static User runAsUser()

    //Custom setting Creation
    public static void CustomSettingCreate() {

        List <HD_REDIRECT_CONTROL_URL_SETTING__c> settingList = new List<HD_REDIRECT_CONTROL_URL_SETTING__c>();
        HD_REDIRECT_CONTROL_URL_SETTING__c Setting1 = new HD_REDIRECT_CONTROL_URL_SETTING__c();
        setting1.Name = 'HD_INCIDENT_CONSOLE_REDIRECT';
        setting1.Value__c = 'TRUE';
        settingList.add(Setting1);

        HD_REDIRECT_CONTROL_URL_SETTING__c Setting2 = new HD_REDIRECT_CONTROL_URL_SETTING__c();
        Setting2.Name = 'HD_staff_profile';
        Setting2.Value__c = 'ServiceDesk Staff';
        settingList.add(Setting2);

        HD_REDIRECT_CONTROL_URL_SETTING__c Setting3 = new HD_REDIRECT_CONTROL_URL_SETTING__c();
        Setting3.Name = 'HD_INCIDENT_CONSOLE';
        Setting3.Value__c = '/servlet/servlet.Integration?lid=01rG0000000ViFd&ic=1';
        settingList.add(Setting3);

        HD_REDIRECT_CONTROL_URL_SETTING__c Setting4 = new HD_REDIRECT_CONTROL_URL_SETTING__c();
        Setting4.Name = 'HD_RF_HOME';
        Setting4.Value__c = '/servlet/servlet.Integration?lid=01rG0000000VHua&ic=1';
        SettingList.add(Setting4);

        Insert settingList;
    }

    //This method will create the page and set it for use with the Test Class
    public static String PageCreatorAndRedirector() {
        //decalring variable for positive test case
        Pagereference pr1 = page.HDRFRedirect;
        Test.setCurrentPage(pr1);
        //added the assert in the utility method
        system.assert(pr1 != null);
        //Lets Call Controller which does redirection
        HD_RF_PageRedirect hdrf  = new HD_RF_PageRedirect();
        String targetPage = hdrf.Redirect().getUrl();
        System.debug('TAGET PAGE WILL REDIRECT TO  -----> ' + targetPage);
        return targetPage;
    }

    public static TestMethod void runPositiveTestCase() {
        //this will run as ServiceDesk Staff
        System.runAs( runAsUser('ServiceDesk Staff', true)) {
            //CustomSettingCreate();
            PageCreatorAndRedirector();
        }

        //this will run as system administrators
        System.runAs( runAsUser('', true)) {
            //CustomSettingCreate();
            PageCreatorAndRedirector();
        }//


        //this will run as ServiceDesk Staff
        System.runAs( runAsUser('ServiceDesk Staff', true)) {
            //CustomSettingCreate();
            PageCreatorAndRedirector();
        }

        System.runAs( runAsUser('Helpdesk Client Profile', false)) {
            //CustomSettingCreate();
            PageCreatorAndRedirector();
        }



    }//public static TestMethod void runPositiveTestCase()


}