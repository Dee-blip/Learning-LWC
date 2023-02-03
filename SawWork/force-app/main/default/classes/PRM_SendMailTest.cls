@isTest(seeAllData=false)
public class PRM_SendMailTest 
{
	private static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    static User dmlUser = new User(id=UserInfo.getUserId());
    
    // Setup method to create test data.
    @testSetup
    static void setupMethod() 
    {
        System.runAs(dmlUser) 
        {
            /* Start Of Custom Setting Insertion */
            Test.loadData(globalDescribe.get('Communities_Settings__c'), 'CS_Communities_Settings');
            Test.loadData(globalDescribe.get('PRM_Settings__c'), 'CS_PRM_Settings');
            Test.loadData(globalDescribe.get('Environment_Setup__c'), 'CS_Environment_Setup');
            Test.loadData(globalDescribe.get('LunaControlCenterSettings__c'), 'CS_LunaControlCenterSettings');
            /* End Of Custom Setting Insertion */
        }
    }

	static testmethod void testAllMethods() 
	{
		System.runAs(dmlUser)
		{
			List<User> testPartnerUsers = utilTestClass.createPartnerUsers(2,null);

			List<Id> userIDs = new List<Id>();

			for(User eachUser : testPartnerUsers)
			{
				userIDs.add(eachUser.Id);
			}

			List<User> partnerUsers = [select Id,Name,Username,Alias,Email,FirstName,LastName,ProfileId,LanguageLocaleKey,LocaleSidKey,EmailEncodingKey,TimeZoneSidKey,ContactId,Can_Accept_POA__c,Profile.Name from User where Id in :userIDs];

			List<Contact> partnerContacts = [select Id,Account.Id,Account.Name,Login__c,Name,Email from Contact where Active_Partner__c = true];

			partnerContacts[0].Login__c = 'def';
			partnerContacts[1].Login__c = 'xyz';

			update partnerContacts;

			Channel_Mapping__c testCM = utilTestClass.CreateChannelMapping('Test CM',partnerContacts[0].Account.Id,UserInfo.getUserId(),UserInfo.getUserId());
			testCM.Active__c = true;
			insert testCM;

			String ccList = PRM_SendMail.populateEmailCCList(partnerContacts[0]);
			ccList += PRM_SendMail.populateEmailCCList(partnerContacts[1]);

			List<User> portalAdminList = PRM_SendMail.getPortalAdminsList(partnerContacts[0]);
			portalAdminList.addAll(PRM_SendMail.getPortalAdminsList(partnerContacts[1]));

			String portalAdminString = PRM_SendMail.generatePortalAdminString(portalAdminList);

			PRM_SendMail.sendPartnerWelcomeMails_Luna('ABC',partnerContacts[1],partnerUsers[0]);

			PRM_SendMail.sendPartnerWelcomeMails_AU('ABC',partnerContacts[0]);

			PRM_SendMail.sendPartnerWelcomeMails_OneTime('ABC',partnerContacts[0],false);
			PRM_SendMail.sendPartnerWelcomeMails_OneTime('ABC',partnerContacts[1],true);

			String result = PRM_SendMail.resetAndSendMails_SF(partnerUsers[0],partnerContacts[0]);
			String result1 = PRM_SendMail.resetAndSendMails_SF(partnerUsers[1],partnerContacts[0]);

			Map<String,String> resetPasswordOptionsMap = new Map<String,String>();

			resetPasswordOptionsMap.put('tempPassword','ABC');
            resetPasswordOptionsMap.put('email',partnerUsers[0].Email);
            resetPasswordOptionsMap.put('name',partnerUsers[0].Name);
            resetPasswordOptionsMap.put('userType','AU');
            resetPasswordOptionsMap.put('loginUnderscoreUnderscoreC' , partnerContacts[0].Login__c);

			PRM_SendMail.sendPasswordResetMail(resetPasswordOptionsMap);
		}
	}	
}