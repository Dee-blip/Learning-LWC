@isTest(seeAllData=false)
public class L2Q_PartnerFileDownloadHelperTest {
    static testmethod void testAttachmentChanges() {
        ContentVersion conVer = L2Q_ContentDocumentUtilClass.setContentVersion('S', 'TestFile', 'TestFile', 'TestData');
        insert conVer;
        ContentVersion insertedConVer = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id];
        ApexPages.currentPage().getParameters().put('contentDocumentId', insertedConVer.ContentDocumentId);
        L2Q_PartnerFileDownloadHelper pfrofileHelper = new L2Q_PartnerFileDownloadHelper();
        String image = pfrofileHelper.image;
    }
    
    static testmethod void oaAttachmentWrapper() {
        OA_EmailBlast_AttachmentWrapper oa = new OA_EmailBlast_AttachmentWrapper();
        Attachment att = new Attachment();
        //oa = new OA_EmailBlast_AttachmentWrapper(att);
        
        Account acc2=utilTestClass.CreateAccount('Test acc__1');
        insert acc2;

        Opportunity opp = utilTestClass.CreateOpportunity('__Test_Oppty','1-Create');
        opp.CloseDate = Date.today().addMonths(4);
        opp.AccountId = acc2.Id;
        insert opp;

        Order_Approval__c oa2 = new Order_Approval__c();
        oa2.Associated_Opportunity__c = opp.Id;
        oa2.Order_Expires_Unless_Duly_Executed_By__c = Date.today().addMonths(4);
        insert oa2;
        
		ContentVersion conVer = L2Q_ContentDocumentUtilClass.setContentVersion('S', 'TestFile', 'TestFile', 'TestData');
        insert conVer;
        ContentVersion insertedConVer = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id =:conVer.Id];
		ContentDocumentLink conDocLink = L2Q_ContentDocumentUtilClass.setContentDocumentLink(insertedConVer.ContentDocumentId, oa2.Id, 'I', 'AllUsers');
        insert conDocLink;
        ContentDocumentLink insertedConDocLink = [SELECT Id, ContentDocument.LatestPublishedVersionId, ContentDocumentId, LinkedEntity.Type FROM ContentDocumentLink Where Id = :conDocLink.Id];
        oa = new OA_EmailBlast_AttachmentWrapper(insertedConDocLink);
        
        oa = new OA_EmailBlast_AttachmentWrapper(oa);
		
        Map<Id,String> userInfoMap = new Map<Id,String>();
        
        ContentDocument conDoc = [SELECT Id, ParentId, ContentModifiedDate, OwnerId, Title FROM ContentDocument WHERE Id = :insertedConVer.ContentDocumentId];
        userInfoMap.put(conDoc.OwnerId, 'Test User');
        oa = new OA_EmailBlast_AttachmentWrapper(conDoc, userInfoMap);
    }
    
}