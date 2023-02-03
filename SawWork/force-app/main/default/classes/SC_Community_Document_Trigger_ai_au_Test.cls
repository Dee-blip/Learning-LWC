@isTest
public class SC_Community_Document_Trigger_ai_au_Test {
   
    static testmethod void createDocument(){
        
        //User u = [Select id from user where name = 'CRM Ops'];
        Profile pr = [select id from profile where name='Support - Tech Support Manager'][0];
        User usr = new User(alias = 'user', email='salesoptesdsdsdsasst@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner23121', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__asdasdsdusr@akamai.com',profileid = pr.Id);
        //usr.AKAM_User_ID__c = 'ABC123';
        insert usr;	

        CollaborationGroup collGroup = new CollaborationGroup();
        collGroup.Description = 'Test Group xyz 12te';
        collGroup.CollaborationType = 'Public';
        collGroup.Name = 'Test Group Test Group xyz 12te ';
		insert collGroup;
        
        CollaborationGroupMember newGroupMem =  new CollaborationGroupMember();
        newGroupMem.CollaborationGroupId = collGroup.Id;
        newGroupMem.MemberId = usr.Id;
        insert newGroupMem;
        
       
        Customer_Community_Document__c newDoc = new Customer_Community_Document__c();
        newDoc.Group_Id__c = collGroup.id;
        newDoc.Title__c = 'Test DocTest Group xyz 12te';
        newDoc.Description__c = 'Test Description';
        test.startTest();
        insert newDoc;
        test.stopTest();
        
    }
    static testmethod void createDocumentFail(){
        
        Profile pr = [select id from profile where name='Support - Tech Support Manager'][0];
        User usr = new User(alias = 'user', email='salesodsasst@akamai.com',emailencodingkey='UTF-8', lastname='OldOwnedsr23121', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__assdsdusr@akamai.com',profileid = pr.Id);
        //usr.AKAM_User_ID__c = 'ABC123';
        insert usr;	
        test.startTest();
        CollaborationGroup collGroup = new CollaborationGroup();
        collGroup.Description = 'Test Group xyz 12te';
        collGroup.CollaborationType = 'Public';
        collGroup.Name = 'Test Group Test Group xyz 12te ';
		insert collGroup;
        
        CollaborationGroupMember newGroupMem =  new CollaborationGroupMember();
        newGroupMem.CollaborationGroupId = collGroup.Id;
        newGroupMem.MemberId = usr.Id;
        insert newGroupMem;
        
        SC_Community_Document_Trigger_Helper.errorMsg = 'Tets';
        SC_Community_Document_Trigger_Helper.testError = 'Tets';
        Customer_Community_Document__c newDoc = new Customer_Community_Document__c();
        newDoc.Group_Id__c = collGroup.Id;
        newDoc.Title__c = 'Test DocTest Group xyz 12te';
        newDoc.Description__c = 'Test Description';
        insert newDoc;
        test.stopTest();
        
    }
    static testmethod void updateDocument(){
        
        Profile pr = [select id from profile where name='Support - Tech Support Manager'][0];
        User usr = new User(alias = 'user', email='salesodsasst@akamai.com',emailencodingkey='UTF-8', lastname='OldOwnedsr23121', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__assdsdusr@akamai.com',profileid = pr.Id);
        //usr.AKAM_User_ID__c = 'ABC123';
        insert usr;	
        test.startTest();
        CollaborationGroup collGroup = new CollaborationGroup();
        collGroup.Description = 'Test Group xyz 12te';
        collGroup.CollaborationType = 'Public';
        collGroup.Name = 'Test Group Test Group xyz 12te ';
		insert collGroup;
        
        CollaborationGroupMember newGroupMem =  new CollaborationGroupMember();
        newGroupMem.CollaborationGroupId = collGroup.Id;
        newGroupMem.MemberId = usr.Id;
        insert newGroupMem;
        
        SC_Community_Document_Trigger_Helper.errorMsg = 'Tets';
        SC_Community_Document_Trigger_Helper.testError = 'Tets';
        Customer_Community_Document__c newDoc = new Customer_Community_Document__c();
        newDoc.Group_Id__c = collGroup.Id;
        newDoc.Title__c = 'Test DocTest Group xyz 12te';
        newDoc.Description__c = 'Test Description';
        insert newDoc;
        Customer_Community_Document__c updateDoc = [select Title__c from Customer_Community_Document__c where id =:newDoc.id];
        updateDoc.Title__c = 'Test DocTest Group xyz 12te 123';
        update updateDoc;
        delete[select id from Customer_Community_Document__c where id=:updateDoc.id];
        test.stopTest();
        
    }

}