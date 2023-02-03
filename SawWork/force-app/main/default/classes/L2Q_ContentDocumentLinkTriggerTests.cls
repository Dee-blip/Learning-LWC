@isTest(seeAllData = false)
private class L2Q_ContentDocumentLinkTriggerTests {
    @testSetUp static void createData() {
        Test.startTest();
        utilTestClass.createCustomSettings();
        System.runAs(utilTestClass.getTestRunUser()) {
            Account acc =  (Account)new SobjectBuilder(Account.sObjectType)
                .eagerPopulate()
                .put(Account.Type, 'Lead')
                .create()
                .getRecord();
            
            List<User> partnerUsers = SObjectFactory.createPartnerUsers(1);
            Account partAccount = SobjectRepository.getPartnerAccount();
            
            Channel_Mapping__c channelMapping = SObjectFactory.createChannelMapping(partAccount.Id);
            Opportunity oppty = (Opportunity)new SobjectBuilder(Opportunity.sObjectType)
                .eagerPopulate()
                .put(Opportunity.AccountId, acc.Id)
                .put(Opportunity.Deal_Type__c, 'Indirect')
                .put(Opportunity.Partner_Involved__c, partAccount.Id)
                .put(Opportunity.Channel_Manager__c, channelMapping.Id)
                .create()
                .getRecord();
            
            Integer numberOfFundBudgets = 3;
            new SObjectBuilder(SFDC_Budget__c.sObjectType)
                .eagerPopulate()
                .put(SFDC_Budget__c.Account__c, partAccount.Id)
                .count(numberOfFundBudgets)
                .create();
            PRMTriggerClass.InitializeFlagVariables();
        }
        Test.stopTest();
    }
    
    static testmethod void coverageForCurrentUserAndNapUtilClass() {
        List<ContentVersion> listOfContentVersion = new List<ContentVersion>();
        listOfContentVersion.add(L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Title', 'Title', 'Test Data'));
        listOfContentVersion.add(L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Title2', 'Title2', 'Test Data2'));
        insert listOfContentVersion;
        Test.startTest();
        User partnerUser = SobjectRepository.getPartnerUser();
        System.runAs(partnerUser) {
            Boolean returnVal = CurrentUser.hasFileAccess(listOfContentVersion.get(0).Id);
        }
        NAPUtilClass.getFileSize(2000);
        NAPUtilClass.getFileSize(2000000);
        NAPUtilClass.getFileSize(2000000000);
        Boolean boolVal = NAPUtilClass.containsUnsanitaryInputForWWW('2000000');
        String zip = NAPUtilClass.getFontAwesomeClassName('zip');
        NAPUtilClass.getLatestVersion(listOfContentVersion.get(0).Id);
        Test.stopTest();
    }
    
    static testmethod void multipleContentDocumentLinksInsert() {
        Opportunity opp = [Select Id,Partner_Involved__c from Opportunity where Deal_Type__c = 'Indirect' Limit 1][0];
        SFDC_Budget__c fundBudget = SobjectRepository.getFundBudget();
        List<SFDC_MDF__c> fundRequests = (List<SFDC_MDF__c>)
            new SobjectBuilder(SFDC_MDF__c.sObjectType)
            .eagerPopulate()
            .put(SFDC_MDF__c.Account__c, opp.Partner_Involved__c)
            .count(1)
            .create()
            .getRecords();

        Task taskObject = new Task();
        taskObject.WhatId = opp.Id;
        taskObject.Subject = '__Test Subject';
        TaskTriggerClass.regularIdsMapFirstRunFlag = true;
        insert taskObject;
        
        List<ContentVersion> listOfContentVersion = new List<ContentVersion>();
        listOfContentVersion.add(L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Title', 'Title', 'Test Data'));
        listOfContentVersion.add(L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Title2', 'Title2', 'Test Data2'));
        listOfContentVersion.add(L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Title3', 'Title3', 'Test Data3'));
        insert listOfContentVersion;
        Test.startTest();
        List<ContentDocumentLink> listOfContentDocumentLink = new List<ContentDocumentLink>();
        List<ContentVersion> insertedConVer = [SELECT Id, ContentDocumentId, contentLocation, PathOnClient, Title, VersionData FROM ContentVersion WHERE Id = :listOfContentVersion];
        listOfContentDocumentLink.add(L2Q_ContentDocumentUtilClass.setContentDocumentLink(insertedConVer.get(0).ContentDocumentId, opp.Id, 'I', 'AllUsers'));
        listOfContentDocumentLink.add(L2Q_ContentDocumentUtilClass.setContentDocumentLink(insertedConVer.get(1).ContentDocumentId, taskObject.Id, 'I', 'InternalUsers'));
        listOfContentDocumentLink.add(L2Q_ContentDocumentUtilClass.setContentDocumentLink(insertedConVer.get(0).ContentDocumentId, fundBudget.Id, 'I', 'AllUsers'));
        listOfContentDocumentLink.add(L2Q_ContentDocumentUtilClass.setContentDocumentLink(insertedConVer.get(0).ContentDocumentId, fundRequests[0].Id, 'I', 'AllUsers'));
        insert listOfContentDocumentLink;
        String L2Q_ObjectsForAccountFileSyncBatchJSON = GSMSettings.getVerbose('L2Q_AccountFileSyncObjectToField');
        List<L2Q_ContentDocumentLinkTriggerHandler.AccountObjectCustom> listOfAccountObjects = (List<L2Q_ContentDocumentLinkTriggerHandler.AccountObjectCustom>)JSON.deserialize(L2Q_ObjectsForAccountFileSyncBatchJSON, List<L2Q_ContentDocumentLinkTriggerHandler.AccountObjectCustom>.Class);
        Map<String,String> accountSyncMapOfValidObjects = new Map<String, String>();
        List<ContentDocumentLink> accountListOfContentDocumentLink = new List<ContentDocumentLink>();
        Map<Id,Id> accountMapOfTaskIdVsWhatId = new Map<Id,Id>();
        accountMapOfTaskIdVsWhatId.put(taskObject.Id, opp.Id);
        for(L2Q_ContentDocumentLinkTriggerHandler.AccountObjectCustom eachObject : listOfAccountObjects) {
            accountSyncMapOfValidObjects.put(eachObject.ObjectName,eachObject.FieldAPI);
        }
        L2Q_ContentDocumentLinkTriggerClass.addAccountVisibiltyForRelatedFilesHasRun = false;
        List<ContentDocumentLink> cdl = new List<ContentDocumentLink>();
        cdl.add(listOfContentDocumentLink.get(1));
        cdl.add(listOfContentDocumentLink.get(0));
        L2Q_ContentDocumentLinkTriggerClass.addAccountVisibiltyForRelatedFiles(cdl, accountSyncMapOfValidObjects, accountMapOfTaskIdVsWhatId);
        listOfContentDocumentLink.remove(listOfContentDocumentLink.size()-1);
        delete listOfContentDocumentLink;
        L2Q_ContentDocumentLinkTriggerHandler.ObjectCustom temp = new L2Q_ContentDocumentLinkTriggerHandler.ObjectCustom();
        
        User partnerUser = SobjectRepository.getPartnerUser();
        PageReference pageRef = Page.L2Q_PartnerFileSharingViewLinkPage;
        Test.setCurrentPageReference(pageRef);
        Account partAccount = SobjectRepository.getPartnerAccount();
        ContentVersionAttribute__c cva = L2Q_ContentDocumentUtilClass.setContentVersionAttribute(insertedConVer.get(2).Id, 'Partner Account', partAccount.Id);
        insert cva;
        System.runAs(partnerUser) {
            L2Q_PartnerFileSharingClass var = new L2Q_PartnerFileSharingClass();
            Map<String, String> retVals = L2Q_PartnerFileSharingClass.getDownloadURL(insertedConVer.get(2).Id);
            Boolean retVal = L2Q_PartnerFileSharingClass.deleteDuplicateContentDocument(insertedConVer.get(2).ContentDocumentId);
        }
        Map<String, String> retVals = new Map<String, String>();
        Network partnerCommunity = [SELECT id, Name,OptionsReputationEnabled FROM Network where name = 'Partners'];
        System.runAs(partnerUser) {
            ContentVersion cv = L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Title', 'Title', 'Test Data4');
            try {
                insert cv;
            }
            catch(Exception e) {
                L2Q_PartnerFileSharingClass.logErrors(e, 'TestClass');
            }
            //cv.NetworkId = '0DB4R000000kA9C';
            cv.NetworkId = partnerCommunity.id;
            insert cv;
            retVals = L2Q_PartnerFileSharingClass.generateContentDownloadUrl(cv, retVals);
        }
        Test.stopTest();
    }
    
    static testmethod void batchClassTestMethod() {
        Opportunity opp = SobjectRepository.getOpportunity();
        
        Test.startTest();
        List<ContentVersion> listOfContentVersion = new List<ContentVersion>();
        listOfContentVersion.add(L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Title', 'Title', 'Test Data'));
        insert listOfContentVersion;
        
        List<ContentDocumentLink> listOfContentDocumentLink = new List<ContentDocumentLink>();
        List<ContentVersion> insertedConVer = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :listOfContentVersion];
        listOfContentDocumentLink.add(L2Q_ContentDocumentUtilClass.setContentDocumentLink(insertedConVer.get(0).ContentDocumentId, opp.Id, 'I', 'AllUsers'));
        insert listOfContentDocumentLink;
        
        String libId = GSMSettings.getValue('PartnerFacingFilesLibraryId');
        L2Q_MakeFiles_PartnerCompatible testObj = new L2Q_MakeFiles_PartnerCompatible(1, 2019, '', false, libId);
        Database.executeBatch(testObj, 200);
        
        Test.stopTest();
        L2Q_MakeFiles_PartnerCompatible.ObjectCustom temp = new L2Q_MakeFiles_PartnerCompatible.ObjectCustom();
        L2Q_MakeFiles_PartnerCompatible testObj2 = new L2Q_MakeFiles_PartnerCompatible(1, 2019, 'Select Id, Partner_Involved__c From Opportunity LIMIT 50000', false, libId);
        Database.executeBatch(testObj2, 200);
    }

    static testmethod void CreateCustomNote(){

        Account account1 = utilTestClass.CreateAccount('Test Account');
        insert account1;
        Account account2 = SobjectRepository.getAccount();
        Opportunity opp = SobjectRepository.getOpportunity();

        Test.startTest();
        ContentNote cn = new ContentNote();
        cn.Content = Blob.valueof('Hello there, How you doing?');
        cn.title = 'Joey';
        insert cn;

        ContentDocumentLink cdl = new ContentDocumentLink();
        cdl.LinkedEntityId = opp.Id;
        cdl.ContentDocumentId = cn.Id;
        cdl.ShareType = 'v';
        insert cdl;

        
        opp.AccountId = account2.id;
        opp.Validation_Override__c = true;
        update opp;

        

        cn.Content = Blob.valueof('Hello there, How you doing?!!!!!!');
        update cn;

        Delete cn;
        
        Test.stopTest();
    }

    static testmethod void notesAndAttachmentVfCompCntrlTestMethod(){
        
        Test.startTest();
        User dmlUser = utilTestClass.getTestRunUser();
        System.runAs(dmlUser) {
            Opportunity opp = SobjectRepository.getOpportunity();
            Blob b = Blob.valueOf('Test Data');
            
            NotesAndAttachmentVfCompCntrl obj = new NotesAndAttachmentVfCompCntrl();
            obj.parentId = opp.Id;
            obj.AttchBody = b;
            obj.AttchName = 'TestFile';
            obj.fileList = new List<ContentDocumentLink>();
            obj.onFileChange();
            obj.getFileList();

            List<ContentDocumentLink> cdl = NotesAndAttachmentVfCompCntrl.getTheAttachedFileList(opp.Id);
            Boolean flag = NotesAndAttachmentVfCompCntrl.getShowComponentOnLayout(opp.Id);
            flag = NotesAndAttachmentVfCompCntrl.getShowComponentOnLayout('');
        }
        Test.stopTest();

    } 

    static testmethod void contentDocumentDeleteOverrideTests(){

        User dmlUser = utilTestClass.getTestRunUser();
        Opportunity opp = [Select Id,Partner_Involved__c from Opportunity where Deal_Type__c = 'Indirect' Limit 1][0];
        SFDC_Budget__c fundBudget = SobjectRepository.getFundBudget();
        List<SFDC_MDF__c> fundRequests = (List<SFDC_MDF__c>)
            new SobjectBuilder(SFDC_MDF__c.sObjectType)
            .eagerPopulate()
            .put(SFDC_MDF__c.Account__c, opp.Partner_Involved__c)
            .count(1)
            .create()
            .getRecords();

        System.runAs(dmlUser) {

            List<ContentVersion> listOfContentVersion = new List<ContentVersion>();
            for(Integer iCount = 0; iCount < 10; iCount++) {
                listOfContentVersion.add(L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Title' + iCount, 'Title' + iCount, 'Test Data' + iCount));
            }
            insert listOfContentVersion;
            List<ContentVersion> cvList = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id IN :listOfContentVersion];
            List<Id> cdIdList = new List<Id>();
            List<ContentDocumentLink> listOfContentDocumentLink = new List<ContentDocumentLink>();
            Integer count = 0;
            for(ContentVersion eachCV : cvList) {
                listOfContentDocumentLink.add(L2Q_ContentDocumentUtilClass.setContentDocumentLink(cvList.get(count++).ContentDocumentId, fundRequests.get(0).Id, 'I', 'AllUsers'));
                cdIdList.add(eachCV.ContentDocumentId);
            }
            insert listOfContentDocumentLink;
            Test.startTest();

            List<ContentDocument> cdList = [SELECT Id FROM ContentDocument WHERE Id IN :cdIdList];
            delete cdList;
            Test.stopTest();
        }
        
    }
        
}