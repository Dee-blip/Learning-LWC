/**
 * @description       : 
 * @author            : Vishnu Vardhan
 * @group             : 
 * @last modified on  : 01-23-2022
 * @last modified by  : Vishnu Vardhan
 * Modifications Log
 * Ver   Date         Author           Modification
 * 1.0   01-23-2022   Vishnu Vardhan   Initial Version
**/
@isTest
public class ScJarvisLiveChatHandlerTest {
    

    static Account crateAccount() {
        Account accRec = new Account(Name='Test Account Jarvis',AKAM_Account_ID__c='Test-ABC-123Jarvis',Type='Brand - Active');
            //Account accRec2 = new Account(Name='Test Account Jarvis 2',AKAM_Account_ID__c='Test-ABC-12Jarvis',Type='Brand - Active');
        insert accRec;
        return accRec;
    }

    static Contact createContact(Id accountId) {
        //Contact Setup
        Contact conRec = new Contact(AccountId = accountId, Login__c = 'Test_xyz2',Akam_Contact_id__c ='test-222', Email = 'test222@test.com' ,No_Longer_with_Company__c = false, LastName = 'Test Contact2', Contact_Type__c ='Technical Primary - 24x7', Active_Portal_Login__c = True);
        conRec.Primary_Contact_Method__c = 'Phone';
        insert conRec;
        return conRec;
    }

    static User createCustomerUser(Id contactId) {
    
        User newUser = new User(
                profileId = '00e0f000000cOem', 
                username = 'test@example.com.akamai123', 
                email = 'test@example.com', 
                emailencodingkey = 'UTF-8', 
                localesidkey = 'en_US', 
                languagelocalekey = 'en_US', 
                timezonesidkey = 'America/Los_Angeles', 
                alias='nuser', 
                lastname='lastname', 
                FederationIdentifier = 'test' + contactId,
                contactId = contactId
            );
        insert newUser;   
        return newUser;
    }

    @IsTest
    static void testJarvisChat(){
        Account acc = crateAccount();
        Contact cnt = createContact(acc.Id);
        
        SC_Case_Issue_Sync_Admin_Setting__c adminRec =  new SC_Case_Issue_Sync_Admin_Setting__c();
        adminRec.Access_Token_Issues_API__c = '';
        adminRec.Client_Certificate__c = 'EAA_KMI_Signed_Certificate';
        adminRec.Client_Id_Issues_API__c = '90f8e0f1-696b-46f9-a504-3811b8ce00fc';
        adminRec.Client_Secret_Issues_API__c = 'b8a4f2c9-24e5-4d5e-a794-6b98730b6915';
        adminRec.Hostname_Issues_API__c = 'https://qa.dash-ext.akamai.com/';
        adminRec.Oauth_Endpoint_Issues_API__c = 'oauth2/token';
        adminRec.Scope_Issues_API__c = 'network-services/issues/v1/issues/';
        //adminRec.Jarvis_IDM_Scope__c = 'network-services/issues/v1/issues/';
        insert adminRec;
        
        Map<String, Schema.RecordTypeInfo> caseRtInfo = Case.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName();


        User sysAdmin = [select id from User where profile.name = 'System Administrator' and isactive = true limit 1];

        Test.startTest();
        User custUser;

        System.runAs(sysAdmin){
            custUser = createCustomerUser(cnt.Id);
        }

        System.runAs(custUser) {

            LiveChatVisitor lcv = new LiveChatVisitor();
            insert lcv;

            Id techRt = caseRtInfo.get('Technical').getRecordTypeId();

            LiveChatTranscript liveChat = new LiveChatTranscript(
                AccountId = acc.Id,
                ContactId = cnt.Id,
                LiveChatVisitorId = lcv.Id,
                Case_Origin__c = 'Akachat Community',
                Case_Subject__c = 'Test Subject',
                Case_Description__c = 'Test Description',
                Case_Record_Type__c = techRt
            );
            
            insert liveChat;
            
            update liveChat;
            
        }
        Test.stopTest();
        
    }

}