@isTest(seeAllData=false)
public with sharing class L2Q_ContentVersionBatchDeleteTest {

    @TestSetup
    static void setup() {

        //Creating and inserting account to link content document to
        Account acc = new Account(Name='TestAccountTS1');
        Insert acc;


        ContentVersion cv = new ContentVersion();
        cv.Title = 'Test Document';
        cv.PathOnClient = 'test_document_1';
        cv.VersionData = Blob.valueOf('Test Content');
        cv.IsMajorVersion = true;
        cv.isDuplicate__c = true;
        Insert cv;
        
        Id conDocId = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id].ContentDocumentId;
		System.debug(conDocId);
    
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = acc.Id;
        cdl.ContentDocumentId = conDocId;
        cdl.shareType = 'I';
       	Insert cdl;       
        
    }


    static testmethod void test() {        
        Test.startTest();
        L2Q_ContentVersionBatchDelete cvbd = new L2Q_ContentVersionBatchDelete();
        Id batchId = Database.executeBatch(cvbd);
        Test.stopTest();
        // after the testing stops, assert records were deleted properly
        System.assertEquals(0, [select count() from ContentVersion where isDuplicate__c = true]);

    
       
        
    }
    
}