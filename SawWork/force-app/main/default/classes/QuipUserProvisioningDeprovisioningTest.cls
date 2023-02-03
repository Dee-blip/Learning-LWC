@isTest(seeAllData=false)
public class QuipUserProvisioningDeprovisioningTest {
    static User dmlUser = utilTestClass.getTestRunUser();
    
    @testSetup
    static void setupMethod() {
        string namedCredential = GsmUtilClass.getGSMSettingValue('Quip_Named_Credential');
        API_Connector_Object__c a = new API_Connector_Object__c();
        a.Name = namedCredential;
        a.Endpoint__c = '/1/';
        a.Named_Credential__c = 'callout:'+namedCredential;
        a.Timeout__c = 120000;
        insert a;
    }
    
    @isTest static void testQuipUserProvisioningDeprovisioningPositive(){
        Test.startTest();
        list<User> userList = [select id,firstname,lastname,email,isactive,Quip_Access__c,Quip_User_Id__c from User where Profile.Name='Sales - Media' and isactive=true order by createddate desc limit 1];
        Test.setMock(HttpCalloutMock.class, new MockQuipHttpResponseGenerator());
        QuipUserProvisioningDeprovisioning q = new QuipUserProvisioningDeprovisioning(userList,'');
        system.enqueueJob(q);
        Test.stopTest();
    }
    
    @isTest static void testQuipUserProvisioningDeprovisioningNegative(){
        Id salesRepProfileId = [select id from profile where name='Sales - Media'][0].Id;
        String roleName = GsmUtilClass.getGSMSettingValue('User_Role');
        Id roleId = [select Id from UserRole where name=:roleName][0].Id;
        User salesUser = new User(alias='jcjcv',Quip_Access__c=true,email='salesop@akamai.com',emailencodingkey='UTF-8',lastname='OldOwner',languagelocalekey='en_US',localesidkey='en_US',timezonesidkey='America/Los_Angeles',username='__old_owner@akamai.com',profileid=salesRepProfileId,UserRoleId =roleId);
        System.runAs(dmlUser) {
            insert salesUser;
        }
        Test.startTest();
        list<User> userList = [select id,firstname,lastname,email,isactive,Quip_Access__c,Quip_User_Id__c from User where Profile.Name='Sales - Media' and isactive=true order by createddate desc limit 1];
        Test.setMock(HttpCalloutMock.class, new MockQuipHttpResponseGenerator());
        QuipUserProvisioningDeprovisioning q = new QuipUserProvisioningDeprovisioning(userList,'');
        system.enqueueJob(q);
        Test.stopTest();
    }
}