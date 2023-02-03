@isTest(seeAllData=false)
public class ChimeContactTest {
    
	static User dmlUser = utilTestClass.getTestRunUser();
    //System.debug('Hello:'+dmlUser);
    
    @testSetup
    static void setupMethod(){
        
        User accOwnerUser = [select id from User where Profile.Name = 'Sales Operations' and IsActive = True limit 1][0];
        
        List<Account> acclist = new List<Account>();
        Account acc = new Account();
        acc.Name = '__Chime Account';
        acc.OwnerId = accOwnerUser.Id;
        acc.BillingCountry = 'India';
        acc.BillingState = 'Delhi';
        insert acc;
        
        Opportunity oppty = utilTestClass.CreateOpportunity('__ChimeTest Oppty','1. Identify Need');
        oppty.AccountId = acc.Id;
        oppty.CloseDate = Date.today().addMonths(4);
        insert oppty;
        
        CHIME__c chimeRecord = new CHIME__c();
        chimeRecord.Account__c = acc.id;
        chimeRecord.Opportunity__c = oppty.id;
        chimeRecord.CHIME_Name__c = 'Chime Test Record';
        chimeRecord.Implementation_Type__c = 'Standard';
        insert chimeRecord;
        
        List<Contact> conList = new List<Contact>();
        Contact cont = utilTestClass.CreateContact('jimi', 'hendrix');
        cont.AccountId = acc.Id;
        conList.add(cont);
        
        Contact cont1 = utilTestClass.CreateContact('bob', 'marley');
        cont1.AccountId = acc.Id;
        conList.add(cont1);
        
        insert conList;        
    }
    
    public static testmethod void associateContactToChime(){
        test.startTest();
        Contact cont = [Select id from contact where FirstName = 'jimi'][0];
        CHIME__c chimeRecord = [Select id from CHIME__c where CHIME_Name__c = 'Chime Test Record'][0];
        
        CHIME_Contact__c chimeContact = new CHIME_Contact__c();
        chimeContact.CHIME__c = chimeRecord.Id;
        chimeContact.Contact__c = cont.id;
        chimeContact.Chime_access__c = true;
        insert chimeContact;
        
        chimeContact.Chime_access__c = false;
        update chimeContact;
        //associatecontactWithCommunityAccess();
        test.stopTest();
    }

    public static testmethod void associatecontactWithCommunityAccess(){
        Contact cont = [Select id from contact where FirstName = 'bob'][0];
        Profile pr = [select Id from profile where name = 'SFCommunityGuests'][0];
        
        
        User communityUser = new User();
        communityUser.alias = 'cUser';
        communityUser.Email = 'smore1@akamai.com';
        communityUser.username = 'smore1@akamai.com';
        communityUser.LastName = 'testLastName';
        communityUser.profileId = pr.id;
        communityUser.emailencodingkey = 'UTF-8';
        communityUser.languagelocalekey = 'en_US';
        communityUser.localesidkey = 'en_US';
        communityUser.timezonesidkey = 'America/Los_Angeles';
        communityUser.contactId = cont.Id;
        insert communityUser;
        
        createChimeContact(cont.Id);
    }
  
    public static void createChimeContact(Id contactid){
        System.RunAs(dmlUser){
            CHIME__c chimeRecord = [Select id from CHIME__c where CHIME_Name__c = 'Chime Test Record'][0];
        
            CHIME_Contact__c chimeContact = new CHIME_Contact__c();
            chimeContact.CHIME__c = chimeRecord.Id;
            chimeContact.Contact__c = contactid;
            chimeContact.Chime_access__c = true;
            insert chimeContact;
        }
    }
    
}