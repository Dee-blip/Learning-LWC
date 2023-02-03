@IsTest
public Class SC_CommunityGroupDocumentListContTest
{
    static testmethod void Test1()
    {
        SC_CommunityGroupDocumentListCont SC = new SC_CommunityGroupDocumentListCont();
        Profile pr = [select id from profile where name='System Administrator'][0];
        
        //Create User
        User u1 = [Select id from user where profile.Name = 'Engineering' and isActive = true Limit 1];

        List<User> lUsers = new List<User>();
        User usr2 = new User(alias = 'user', email='testUser@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner2', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__usr2@akamai.com',profileid = pr.Id);
        usr2.AKAM_User_ID__c = 'ABC1234';
        lUsers.add(usr2);
        
        User usr3 = new User(alias = 'user', email='testUser3@akamai.com',emailencodingkey='UTF-8', lastname='OldOwner32', languagelocalekey='en_US',localesidkey='en_US', timezonesidkey='America/Los_Angeles', username='__u3sr2@akamai.com',profileid = pr.Id);
        usr3.AKAM_User_ID__c = 'ABC12334';
        lUsers.add(usr3);
        
        insert lUsers;
        
        //Creating CollaborationGroup
        List<CollaborationGroup> lGroups = new List<CollaborationGroup>();
        //Colloboration Group and Id
        CollaborationGroup myGroup = new CollaborationGroup();
        myGroup.Name='Random XZYABC';
        myGroup.CollaborationType='Public'; //can be 'Public' or 'Private'                   
        lGroups.add(myGroup);
        
        CollaborationGroup myGroup2 = new CollaborationGroup();
        myGroup2.Name='My Group in Testing';
        myGroup2.CollaborationType='Public'; //can be 'Public' or 'Private'                   
        lGroups.add(myGroup2);
        
        CollaborationGroup myGroup3 = new CollaborationGroup();
        myGroup3.Name='My Group in Testing2';
        myGroup3.CollaborationType='Public'; //can be 'Public' or 'Private'                   
        lGroups.add(myGroup3);
        
        insert lGroups;
        
        //creating CollaborationGroupMember
        List<CollaborationGroupMember> lGroupMembers = new List<CollaborationGroupMember>();
        CollaborationGroupMember groupMember = new CollaborationGroupMember();
        groupMember.memberid = usr2.id; //id of User you wish to add
        groupMember.CollaborationGroupId = myGroup.Id; //Id of group created above
        lGroupMembers.add(groupMember);
        
        CollaborationGroupMember newGroupMem2 =  new CollaborationGroupMember();
        newGroupMem2.CollaborationGroupId = myGroup2.Id;
        newGroupMem2.MemberId = u1.Id;
        lGroupMembers.add(newGroupMem2);
        
        CollaborationGroupMember newGroupMem3 =  new CollaborationGroupMember();
        newGroupMem3.CollaborationGroupId = myGroup3.Id;
        newGroupMem3.MemberId = u1.Id;
        lGroupMembers.add(newGroupMem3);
        
        insert lGroupMembers;
        
        //Create Document
        List<Customer_Community_Document__c> lDocuments = new List<Customer_Community_Document__c>();
        Customer_Community_Document__c Cd = new Customer_Community_Document__c();
        Cd.Title__c ='Test Doc';
        Cd.Description__c ='Test Doc';
        Cd.Make_Public__c = true;
        Cd.Group_Id__c=myGroup2.Id;
        lDocuments.add(Cd);
        
        Customer_Community_Document__c Cd2 = new Customer_Community_Document__c();
        Cd2.Title__c ='Test Doc1';
        Cd2.Description__c ='Test Doc1';
        Cd2.Make_Public__c = true;
        Cd2.Group_Id__c=myGroup3.Id;
        lDocuments.add(Cd2);
        
        insert lDocuments;
        
        //creating Document Share
        Customer_Community_Document__share Cdshare = new Customer_Community_Document__share();
        Cdshare.ParentId=Cd2.id;
        Cdshare.UserOrGroupId=usr3.Id;
        Cdshare.AccessLevel='Read';
        Cdshare.RowCause=Schema.Customer_Community_Document__share.RowCause.Manual;
        insert Cdshare;
        
        String DataCategoryID = myGroup3.id;
        
        System.runAs(usr2){
            SC_CommunityGroupDocumentListCont.fetchCommunityDocuments('Test Doc',DataCategoryID,'','5');
        }
        SC_CommunityGroupDocumentListCont.fetchCommunityDocuments('abc','','','5');
        SC_CommunityGroupDocumentListCont.fetchCommunityDocuments('',DataCategoryID,'2','5');
        SC_CommunityGroupDocumentListCont.fetchCommunityDocuments('abc',DataCategoryID,'1','5');
        
        
        SC_CommunityGroupDocumentListCont.checkAccess(DataCategoryID);
        SC_CommunityGroupDocumentListCont.fetchDocumentEditAccess(DataCategoryID);
        SC_CommunityGroupDocumentListCont.fetchDocument(CD.id);
        SC_CommunityGroupDocumentListCont.saveDoc(Cd);
        
        SC_CommunityGroupDocumentListCont.createDocRecord(Cd,DataCategoryID);
        SC_CommunityGroupDocumentListCont.getPageCountInfo('1',DataCategoryID,'abc','2','5');
        SC_CommunityGroupDocumentListCont.getPageCountInfo('1',DataCategoryID,'','2','5');
        
        SC_CommunityGroupDocumentListCont.getPageCountChange('2','3','5');
        SC_CommunityGroupDocumentListCont.getPageCountChange('1','3','5');
        SC_CommunityGroupDocumentListCont.getPageCountChange('2','5','4');
        SC_CommunityGroupDocumentListCont.getPageCountChange('2','6','7');
        SC_CommunityGroupDocumentListCont.getPageCountChange('7','1','2');
        SC_CommunityGroupDocumentListCont.delDoc(Cd.id);
        SC_CommunityGroupDocumentListCont.fetchCommunityId();
    }
}