/*** Test class for SCCommunityDocumentController **/

@IsTest
public class SCCommunityDocumentControllerTC
{
    static testmethod void testmethod1()
    {
        //Creating Variable
        Customer_Community_Document__c Docu = new Customer_Community_Document__c();
        
        Group testGroup = new Group();
        testGroup.Name = 'testGroup';
        testGroup.DeveloperName = 'ABC';
        INSERT testGroup;
        
        //Create a collaboration group
        CollaborationGroup cg = new CollaborationGroup(
            Name = 'New Group',
            CollaborationType = 'Private'
        );
        
        INSERT cg;
        
        System.debug(cg.Name);
        
        //Create a Customer Community Document
        Customer_Community_Document__c Doc = new Customer_Community_Document__c();
        Doc.Title__c ='Test Document';
        Doc.Description__c='Test Description';
        Doc.Group_Id__c = cg.id;
        insert Doc;
        
        system.debug(Doc.Id);
        //Call the methods of Class being Tested
        SCCommunityDocumentController.getdocuments(Doc.Id);
        SCCommunityDocumentController.getGroupName(Doc.Id);
        SCCommunityDocumentController.hasEditAccess(Doc.Id);
        SCCommunityDocumentController.hasDeltAccess(Doc.Id);
        SCCommunityDocumentController.UpdateDocument(Doc.Id,'Test Update','Test Update Description');
        SCCommunityDocumentController.DeleteDocumentApex(Doc.Id);
        SCCommunityDocumentController.fetchCommunityId();
    }
}