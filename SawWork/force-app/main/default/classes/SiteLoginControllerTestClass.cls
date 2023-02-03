@isTest(seeAllData=false)
public class SiteLoginControllerTestClass
{
    static User dmlUser = new User(id=UserInfo.getUserId());
    @testSetup static void insertPRMSettings() 
    {
        List<PRM_Settings__c> prmSettingsList = new List<PRM_Settings__c>();
        PRM_Settings__c tempCustomSetting = new PRM_Settings__c(Name='AkamaiNetallianceBrandingEnabled', Value__c='TRUE');
        prmSettingsList.add(tempCustomSetting);
        tempCustomSetting = new PRM_Settings__c(Name='SSOStartURL', Value__c='/apex/partners/Partner_Welcome_Page');
        prmSettingsList.add(tempCustomSetting);
        tempCustomSetting = new PRM_Settings__c(Name='BrandedPartnerSiteURL', Value__c='https://netalliance.akamai.com');
        prmSettingsList.add(tempCustomSetting);
        insert prmSettingsList;
        utilTestClass.insertCustomSettings(new List<String>{'LunaControlCenterSettings'});
        GSM_Custom_Settings__c tempGSMSetting = new GSM_Custom_Settings__c(Name='CronBatchJob#EmailDestro', Value__c='ahegde@akamai.com');
        insert tempGSMSetting;
    }


    static testmethod void testSiteLoginController()
    {
        System.runAs(dmlUser) 
        {
            PageReference pageRef = Page.SiteLogin;
            Test.setCurrentPageReference(pageRef);
            ApexPages.currentPage().getParameters().put('startURL', '');
            SiteLoginController slcInstance = new SiteLoginController();
            slcInstance.redirect();
            slcInstance.login();
            SiteLoginController.exceptionNotification(pageRef, new CustomException('Some error occurred'));
        }
    }
}