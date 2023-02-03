/* ========================================================================
    Author: Sonia Sawhney
    Description: Test Class for WizardsUtilClass
    Created Date : 10/04/2014
    Modification History:
    1. sswhney on 01/01/2015 CR 2869635
    ======================================================================== */
@isTest
public class WizardsUtilClassTest
{    
    
    public static testMethod void testAdminMethods() {
        WizardsInitData.createCS();
        Profile p = [select Id from Profile where Name = 'Standard User'];
        
        User u1 = new User(Alias = 'standt', Email='standarduser1@akamai.com', 
        EmailEncodingKey='UTF-8', LastName='Testing', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='standarduser1@akamai.com');
        
        System.runAs(u1)
        {
            boolean isAdmin = WizardsUtilClass.isIdeaAdmin(u1.Id);
            System.assertEquals(isAdmin,false);
            list<PermissionSetAssignment> lst = WizardsUtilClass.getAdminList();
            System.assert(lst.size()>0);
        }
        
        /*Id permissionSetId = [Select Id from PermissionSet where Name = 'Wizards_Admin' limit 1].Id; 
        PermissionSetAssignment assign = new PermissionSetAssignment(AssigneeId=u1.Id, PermissionSetId = permissionSetId);
        insert assign;
        
        System.runAs(u1)
        {
            boolean isAdmin = WizardsUtilClass.isIdeaAdmin();
            System.assertEquals(isAdmin,true);
            list<PermissionSetAssignment> lst = WizardsUtilClass.getAdminList();
            System.assert(lst.size()>0);
        }*/
    }
    
    public static testMethod void testIdeaAndCommentCreation() {
        
        Idea objIdea = WizardsInitData.createIdea();
        WizardsUtilClass.Response res = WizardsUtilClass.SaveIdea(objIdea);
        System.assert(res.recordId != null);

        IdeaComment__c ideaComment = new IdeaComment__c();
        ideaComment.IdeaId__c = objIdea.Id;
        ideaComment.CommentBody__c = 'Test Idea Comment1 for objIdea';
        ideaComment.ActualCreator__c = UserInfo.getUserId();
        IdeaComment__c resultComment = WizardsUtilClass.SaveIdeaComment(ideaComment);
        System.debug(resultComment);  
        System.assert(resultComment.Id != null);  
         
        WizardsUtilClass.initializeMaps();
    }  
    
    public static testMethod void testIdeaShare()
    {
        Idea objIdea = WizardsInitData.createIdea();
        WizardsUtilClass.Response res = WizardsUtilClass.SaveIdea(objIdea);
        System.assert(res.recordId != null);
        String url = 'http://testakamai.com/idea/'+objIdea.Id;
        
        WizardsUtilClass.shareIdea('test@123.com',url);
        WizardsUtilClass.shareIdea('test@123.com,test1@123.com',url);
        WizardsUtilClass.shareIdea('test',url);
    }

    public static testMethod void sendEmailTest(){
        Test.startTest();

        IdeaEmail__c emailObj = new IdeaEmail__c();
        emailObj.Feedback_Type__c = 'Feedback';
        emailObj.Mail_Type__c = 'FeedbackMail';
        emailObj.Msg__c = '<p> test </p>';
        emailObj.SenderName__c = null;
        emailObj.Subject__c = 'test';
        emailObj.To__c = UserInfo.getUserEmail();

        WizardsUtilClass.Response res = WizardsUtilClass.SendMail(emailObj);
        System.assert(res.isSuccess == true);
    }

    public static testMethod void testCreateDeleteAttachment(){
        System.debug('result before');
        List<Attachment> attachments = new List<Attachment>();
        Idea objIdea = WizardsInitData.createIdea();
        ideaAttachment__c ideaAttachment = new ideaAttachment__c();
        ideaAttachment.Idea__c = objIdea.Id;
        insert ideaAttachment;

        Attachment  attachment = new Attachment ();
        attachment.Name = 'test_attachment';
        attachment.Body = Blob.valueOf('test attachment body');
        
        attachments.add(attachment);
        WizardsUtilClass.Response res = WizardsUtilClass.CreateAttachments(objIdea.Id, attachments);
        System.debug('result '+ res);
        System.assert(res != null);
        //System.debug('result '+ res);

        //deleting attachments
        WizardsUtilClass.Response deleteResponse = WizardsUtilClass.DeleteAttachments(new List<Id>{attachment.Id});
        System.debug('result '+ deleteResponse);
        System.assert(deleteResponse != null);
    }

    public static testMethod void testCategoryAndReviewFetchSubList(){
        List<String> categories = WizardsUtilClass.getCatSubList();
        System.assert(categories != null);

        List<String> reviewStatuses = WizardsUtilClass.getRevSubList();
        System.assert(reviewStatuses != null);

        List<String> implementationStatuses = WizardsUtilClass.getImplementationSubList();
        System.assert(implementationStatuses != null);
    }

    public static testMethod void getReviwersListTest(){
        List<PermissionSetAssignment> test = WizardsUtilClass.getReviwersList();
        System.assert(test!=null);
    }

}