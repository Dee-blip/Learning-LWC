@isTest
public class SearchAkamaiCommunityResultPageCtrlTest {
    private static User testUser;

    private static void init()
    {
        String uniqueUserName = 'standarduser' + DateTime.now().getTime() + '@testorg.com';
        Profile p = [SELECT Id FROM Profile WHERE Name='Customer Community Profile'];
        testUser = new User(Alias = 'standt', Email='standarduser@testorg.com', EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', LocaleSidKey='en_US', ProfileId = p.Id, TimeZoneSidKey='America/Los_Angeles', UserName=uniqueUserName);
    }

    @isTest
    static void customSearch() {
        init();
        System.runAs(testUser) {

            Customer_Community_Search_Config__c muleConfig = new Customer_Community_Search_Config__c();
            muleConfig.Name = 'MuleAccessTokenEndpoint';
            muleConfig.Base_URL__c = 'https://fabric.dash-ext.akamai.com/oauth2/token';
            muleConfig.Cert_Name__c = 'EAA_KMI_Signed_Certificate';
            muleConfig.Method__c = 'GET';
            muleConfig.Query_Params__c = 'grant_type;scope';
            muleConfig.Query_Param_Values__c = 'CLIENT_CREDENTIALS;READ_COMMUNITY_SEARCHAKAMAI';
            muleConfig.Resource_Path__c = 'oauth2/token';
            insert muleConfig;

            Customer_Community_Search_Config__c searchConfig = new Customer_Community_Search_Config__c();
            searchConfig.Name = 'SearchQueryEndpoint';
            searchConfig.Base_URL__c = 'https://fabric.dash-ext.akamai.com/communities-search-api/v1/';
            searchConfig.Cert_Name__c = 'EAA_KMI_Signed_Certificate';
            searchConfig.Method__c = 'POST';
            searchConfig.Query_Params__c = 'id';
            searchConfig.Query_Param_Values__c = '';
            searchConfig.Resource_Path__c = 'search/results';
            insert searchConfig;
            
            Test.setMock(HttpCalloutMock.class, new ExampleCalloutMock());
            
            Test.startTest();
            String getThisUser = SearchAkamaiCommunityResultPageCtrl.getUser();
            System.assert(getThisUser != '','User details found.');
            String getResult = SearchAkamaiCommunityResultPageCtrl.getSearchResponse('testFilterBody','results');
            System.assert(getResult != '','Results response found');
            Test.stopTest();
        }
    }
}