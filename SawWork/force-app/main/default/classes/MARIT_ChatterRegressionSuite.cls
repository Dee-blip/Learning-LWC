@isTest(seeAllData = false)
private class MARIT_ChatterRegressionSuite {
    private static User dmlUser = new User(id=UserInfo.getUserId());
    
    @testSetUp static void createTestData(){
        System.runAs(dmlUser) {
            Account testAccount = utilTestClass.CreateAccount('Test Account2');
            insert testAccount;
        }   
    }
    public static testmethod void ctaWithOwnerPopulated_ReassignOwner_ChatterFeedCreated() {
            Account testAccount = [select Id, name from Account where Name = 'Test Account2'];
            Integer conCount = 1;
            List<Contact> conList = createContacts(conCount, testAccount.Id);
            insert conList;
            Id akamaiRecordTypeId= Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Akamai Lead').getRecordTypeId();
            List<Lead> akamaiLeads = createLeads(conCount, testAccount, akamaiRecordTypeId);
            Integer i = 0;
            for(Lead akamaiLead : akamaiLeads) {
                akamaiLead.Associated_Contact__c = conList[i].Id;
                akamaiLead.Country = 'USA';
                akamaiLead.State = 'TX';
                i++;
            }
            insert akamaiLeads;
            List<Lead> akamaiLeadList = new List<Lead>();
            List<User> marketingOpsUsers = [select id from user where profile.name='Marketing Operations' and isactive=true limit 1];
            i = 0;
            for(Lead akamaiLead : akamaiLeads) {
                akamaiLead.Validation_Override__c = true;
                akamaiLead.OwnerId = marketingOpsUsers[i].Id;
                i++;
                akamaiLeadList.add(akamaiLead);
            }
            update akamaiLeadList;
            
            List<FeedItem> feedItems = [Select Id, parentId, CreatedById, body from FeedItem limit 1];
            System.assertEquals(akamaiLeadList[0].OwnerId, feedItems[0].CreatedById, 'Owner Id must match the createdById');
            System.assertEquals(1, feedItems.size(), 'Feedback item should contain an entry');
    }
    
    private static List<Contact> createContacts(Integer conCount, Id accId) {
        List<Contact> conList = new List<Contact>();
        Contact con = null;
        for(Integer i = 0; i<conCount ; i++) {
            con = utilTestClass.CreateContact('Test','Contact2' + i);
            con.AccountId = accId;
            conList.add(con);
        }
        return conList;
    }
    private static List<Lead> createLeads(Integer leadCount, Account testAccount,Id recordTypeId ) {
        List<Lead> leadList = new List<Lead>();
        for(integer i =0 ; i< leadCount ; i++) {
            Lead lObj = new Lead();
            lObj.RecordTypeId = recordTypeId;
            lObj.FirstName = 'Test';
            lObj.LastName = 'ML00' + (i+1);
            lObj.Email = lObj.FirstName + lObj.LastName + '@akamai.com';
            lObj.Associated_Account__c = testAccount.Id;
            lObj.Company = 'Test Company';
            leadList.add(lObj);
        }
        return leadList;
    }
}