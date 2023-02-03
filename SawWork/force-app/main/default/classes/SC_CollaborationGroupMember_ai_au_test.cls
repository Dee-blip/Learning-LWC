@isTest(seeAllData = false)
public class SC_CollaborationGroupMember_ai_au_test {
    
    static testmethod void createDocument(){
        utilTestClass.createCustomSettings();
        //User u = [Select id from user where name = 'CRM Ops' Limit 1];
        //User u1 = [Select id from user where profile.Name = 'Engineering' and isActive = true Limit 1];
        
        //User u = [Select id from user where name = 'CRM Ops'];
        Profile pr = [select id from profile where name='Support - Tech Support Manager'][0];
        User usr = new User(alias = 'user',AKAM_User_ID__c = 'ABC1sd23', email='salesoptesdsdsdsasst@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner23121', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__asdasdsdusr@akamai.com',profileid = pr.Id);
        //usr.AKAM_User_ID__c = 'ABC123';
        insert usr;	
        User usr1 = new User(alias = 'user',AKAM_User_ID__c = 'ABC1sdasas23', email='saldtesdsdsdsasst@akamai.com',emailencodingkey='UTF-8', lastname='Osdcwner23121', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__asscsmmdsdusr@akamai.com',profileid = pr.Id);
        //usr.AKAM_User_ID__c = 'ABC123';
        insert usr1;	
        
        CollaborationGroup collGroup = new CollaborationGroup();
        collGroup.Description = 'Test Group xyz 12te';
        collGroup.CollaborationType = 'Public';
        collGroup.Name = 'Test Group Test Group xyz 12te ';
        insert collGroup;
        
        list<CollaborationGroupMember> collList = new List<CollaborationGroupMember>();
        
        Customer_Community_Document__c newDoc = new Customer_Community_Document__c();
        newDoc.Group_Id__c = collGroup.id;
        newDoc.Title__c = 'Test DocTest Group xyz 12te';
        newDoc.Description__c = 'Test Description';
        insert newDoc;
        
        list<Customer_Community_Document__Share> shareList = new list<Customer_Community_Document__Share>();
        Customer_Community_Document__Share cs = new Customer_Community_Document__Share();
        cs.AccessLevel = 'read';
        cs.ParentId = newDoc.Id;
        cs.UserOrGroupId = usr.Id;
		insert cs;
        shareList.add(cs);
        
        CollaborationGroupMember newGroupMem1 =  new CollaborationGroupMember();
        newGroupMem1.CollaborationGroupId = collGroup.Id;
        newGroupMem1.MemberId = usr1.Id;
        //insert newGroupMem1;
        collList.add(newGroupMem1);
        //SC_Community_Document_Trigger_Helper.errorMsg = 'Tets';
        
        CollaborationGroupMember newGroupMem =  new CollaborationGroupMember();
        newGroupMem.CollaborationGroupId = collGroup.Id;
        newGroupMem.MemberId = usr.Id;
        //insert newGroupMem;
        collList.add(newGroupMem);
        
        SC_CollaborationGroupMember_Trig_Helper.errorMsg = 'Tets';
        SC_CollaborationGroupMember_Trig_Helper.testError = 'Tets';
        
        test.startTest();
        insert collList;
        delete collList;
        SC_CollaborationGroupMember_Trig_Helper.deleteDocShareFromExitGroupUser(shareList);
        SC_CollaborationGroupMember_Trig_Helper.sendEmailOnError('Email Subject', 'Error Message On Coll Grp');
        test.stopTest();
        
    }
    
}