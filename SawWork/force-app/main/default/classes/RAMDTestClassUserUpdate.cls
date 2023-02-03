/**
 * Created by kusharma on 05/01/18.
 */

@isTest
private class RAMDTestClassUserUpdate {
    static User dmlUser = new User(id = UserInfo.getUserId());

    @testSetup static void insertCustomSettings() {
        System.runAs(dmlUser) {
            utilTestClass.insertCustomSettings();
        }

    }

    static testMethod void userCitizenEditor() {
        System.runAs(dmlUser) {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            Set<Id> setOfUserIds = new Set<Id>();
            User userRecToUpdate = utilTestClass.CreateUserWithProfileId('fdaijoi' + 1, 'Worldwide', GsmUtilClass.GetCustomSettingValue('UserTriggerClass', 'ChannelUsersProfiles').substring(0, GsmUtilClass.GetCustomSettingValue('UserTriggerClass', 'ChannelUsersProfiles').indexOf(',', 0)));
            userRecToUpdate.Citizen_Support__c = 'USA';
            userRecToUpdate.FirstName = 'RAMDTestUser';
            insert userRecToUpdate;
            System.debug('!!@@## ' + userRecToUpdate);
            List<Id> lFixedSearchResults = new List<Id>();
            lFixedSearchResults.add(userRecToUpdate.Id);
            Test.setFixedSearchResults(lFixedSearchResults);

            Test.startTest();
            Test.setCurrentPageReference(new PageReference('Page.RAMDCitizenshipEditor'));
            RAMDCitizenshipEditorCtrl citizenshipEditorCtrl = new RAMDCitizenshipEditorCtrl();
            List<SelectOption> lCitizenSupportOptions = citizenshipEditorCtrl.lCitizenSupportOptions;
            citizenshipEditorCtrl.queryString = 'RAMDTestUser';
            citizenshipEditorCtrl.searchUserRecs();
            citizenshipEditorCtrl.lSearchedUserRecsWrapped.add(new RAMDCitizenshipEditorCtrl.UserWrapper(true, userRecToUpdate));
            citizenshipEditorCtrl.saveUserRec();
            citizenshipEditorCtrl.userIdToRemove = userRecToUpdate.Id;
            citizenshipEditorCtrl.removeCitizenSupport();
            Test.stopTest();

        }
    }

    static testMethod void userCountryChangeTest() {
        System.runAs(dmlUser) {
            ManagedPkgErrorClass.isFromManagedPackage = false;
            Set<Id> setOfUserIds = new Set<Id>();
            User userRecToUpdate = utilTestClass.CreateUserWithProfileId('fdaijoi' + 1, 'Worldwide', GsmUtilClass.GetCustomSettingValue('UserTriggerClass', 'ChannelUsersProfiles').substring(0, GsmUtilClass.GetCustomSettingValue('UserTriggerClass', 'ChannelUsersProfiles').indexOf(',', 0)));
            insert userRecToUpdate;



            Test.startTest();
            Account accountRAMD = utilTestClass.CreateAccount('__Test RAMD Account');
            accountRAMD.Type = 'Direct Customer - Active';
            insert accountRAMD;

            RAMD_Processor__c ramdProcessor2 = new RAMD_Processor__c();
            ramdProcessor2.Account__c = accountRAMD.Id;
            ramdProcessor2.Event_Type__c = 'Account Country Change';
            ramdProcessor2.Sales_Primary__c = userRecToUpdate.Id;
            ramdProcessor2.Account_Country__c = 'China';
            ramdProcessor2.Sales_Primary_Country__c = 'India';
            ramdProcessor2.Processing_Status__c = 'Pending';
            insert ramdProcessor2;
            Test.stopTest();

            userRecToUpdate.Country = 'USA';
            update userRecToUpdate;


        }
    }

}