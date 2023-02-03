//@isTest(seeAllData = false)
/* private class NAPTests{

   
    static User dmlUser = new User(id=UserInfo.getUserId());

    @testSetUp static void insertCustomSettingsAndCreateData()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            Test.startTest();
            utilTestClass.insertCustomSettings();
            insert new PRM_Settings__c(name='NonLitePermissionSets', Value__c='Has_DealRegistration_Access__c,Has_PartnerPlans_Access__c');
            User partnerUser = (User)(SObjectFactory.createPartnerUsers(1).get(0));

            insertContentFiles();
            createNAPItems();
            Test.stopTest();

        }
    }

    private static void createNAPItems()
    {
        List<NAP_Page_Builder__c> napItems = new List<NAP_Page_Builder__c>();
        List<NAP_Page_Security__c> accesses = new List<NAP_Page_Security__c>();

        // pages
        for( Integer i=0;i<8;i++)
        {
            NAP_Page_Builder__c newPage = new NAP_Page_Builder__c(Title__c='NP'+i, Description__c='NTD'+i, Image__c ='NTI'+i, Component_Type__c='Page', Component_Order__c=i);
            napItems.add(newPage);
        }

        // carousels
        List<Document> docs = new List<Document>();
        Id folderId = [select id from folder where name='Partner Portal Folder' limit 1].Id;

        for( Integer i=0;i<2;i++)
        {
            NAP_Page_Builder__c newCarousel = new NAP_Page_Builder__c(Title__c='NC'+i, Description__c='NTD'+i, Image__c ='CIMJ'+i, Component_Type__c='Carousel', Component_Order__c=i);
            napItems.add(newCarousel);

            docs.add(new Document(Name='CIMJ'+i,FolderId=folderId));
        }

        insert docs;


        insert napItems;

        List<NAP_Page_Builder__c> menuItems = new List<NAP_Page_Builder__c>();

        // main menus
        for( Integer i=0;i<2;i++)
        {
            NAP_Page_Builder__c newMainMenu = new NAP_Page_Builder__c(Title__c='NMM'+i, Description__c='NTD'+i, Image__c ='NTI'+i, Component_Type__c='Main Menu', Component_Order__c=i);
            menuItems.add(newMainMenu);

        }

        // permanent menus
        for( Integer i=0;i<2;i++)
        {
            NAP_Page_Builder__c newPermanentMenu = new NAP_Page_Builder__c(Title__c='NPM'+i, Description__c='NTD'+i, Image__c ='NTI'+i, Component_Type__c='Permanent Menu', Component_Order__c=i);
            menuItems.add(newPermanentMenu);
        }

        insert menuItems;

        List<NAP_Page_Builder_Join__c> relations = new List<NAP_Page_Builder_Join__c>();


        Integer order=1;
        for(NAP_Page_Builder__c npb : menuItems)
        {
            relations.add(createPageBuilderJoin(napItems[0].Id, npb.Id, order));
            if(order!=2)
            {
                accesses.add(createNAPSecurity(npb.Id));
            }
            order++;
        }

        List<NAP_Page_Builder__c>  contentMenus = new List<NAP_Page_Builder__c>();
        // sub menus
        NAP_Page_Builder__c subMenu2 = new NAP_Page_Builder__c(Title__c='NSM1', Component_Type__c='Sub Menu', Content_Type__c='HTML', Raw_HTML_Content__c='Some stuff', Is_File_Browser__c=true);
        contentMenus.add(subMenu2);

        NAP_Page_Builder__c subMenu1 = new NAP_Page_Builder__c(Title__c='NSM2', Description__c='NSM2', Component_Type__c='Sub Menu');
        contentMenus.add(subMenu1);


        NAP_Page_Builder__c detailMenu1 = new NAP_Page_Builder__c(Title__c='DM1', Component_Type__c='Detail Menu', Content_Type__c='HTML with Placeholders', Raw_HTML_Content__c='Some stuff', Is_File_Browser__c=true, Has_Tag_Filters__c=true, Has_Language_Filters__c=true);
        contentMenus.add(detailMenu1);

        NAP_Page_Builder__c detailMenu2 = new NAP_Page_Builder__c(Title__c='DM2', Component_Type__c='Detail Menu', Content_Type__c='HTML', Raw_HTML_Content__c='Some stuff', Is_Nap_Search__c=true);
        contentMenus.add(detailMenu2);

        NAP_Page_Builder__c detailMenu3 = new NAP_Page_Builder__c(Title__c='DM3', Component_Type__c='Detail Menu', Content_Type__c='HTML', Raw_HTML_Content__c='Some stuff', Is_News_Filter__c=true);
        contentMenus.add(detailMenu3);

        NAP_Page_Builder__c detailMenu4 = new NAP_Page_Builder__c(Title__c='DM4', Component_Type__c='Detail Menu', Content_Type__c='HTML with Placeholders', Raw_HTML_Content__c='Some stuff #Video=External,https://www.youtube.com/embed/InjL1JqiKhw,233,233#', News_Display_Type__c='Archive');
        contentMenus.add(detailMenu4);

        NAP_Page_Builder__c detailMenu5 = new NAP_Page_Builder__c(Title__c='DM5', Component_Type__c='Detail Menu', Content_Type__c='HTML', Raw_HTML_Content__c='Some stuff', Is_News_Filter__c=true);
        contentMenus.add(detailMenu5);

        NAP_Page_Builder__c detailMenu6 = new NAP_Page_Builder__c(Title__c='DM6', Component_Type__c='Detail Menu', Content_Type__c='HTML', Raw_HTML_Content__c='Some stuff', Is_News_Filter__c=true);
        contentMenus.add(detailMenu6);

        NAP_Page_Builder__c detailMenu7 = new NAP_Page_Builder__c(Title__c='DM7', Component_Type__c='Detail Menu', Content_Type__c='HTML', Raw_HTML_Content__c='Some stuff', Is_News_Subscription__c=true);
        contentMenus.add(detailMenu7);        

        insert contentMenus;

        List<NAP_News_Filter__c> newFilterList = new List<NAP_News_Filter__c>();

        NAP_News_Filter__c newFilter1 = new NAP_News_Filter__c(NAP_Page_Builder__c=detailMenu3.id,
                                                                Attribute_Condition__c = 'AND',
                                                                Publish_Status__c = 'Live',
                                                                Attribute_Filter__c = 'News');
        newFilterList.add(newFilter1);
        NAP_News_Filter__c newFilter2 = new NAP_News_Filter__c(NAP_Page_Builder__c=detailMenu5.id,
                                                                Attribute_Condition__c = 'AND',
                                                                Publish_Status__c = 'Live',
                                                                Attribute_Filter__c = 'Event');
        newFilterList.add(newFilter2);
        NAP_News_Filter__c newFilter3 = new NAP_News_Filter__c(NAP_Page_Builder__c=detailMenu6.id,
                                                                Attribute_Condition__c = 'AND',
                                                                Publish_Status__c = 'Live',
                                                                Attribute_Filter__c = 'OTP');
        newFilterList.add(newFilter3);
        insert newFilterList;

        relations.add(createPageBuilderJoin(menuItems[0].Id, subMenu1.Id, 1));
        relations.add(createPageBuilderJoin(menuItems[0].Id, subMenu2.Id, 2));
        relations.add(createPageBuilderJoin(subMenu1.Id, detailMenu1.Id, 1));
        relations.add(createPageBuilderJoin(subMenu1.Id, detailMenu2.Id, 2));
        relations.add(createPageBuilderJoin(subMenu1.Id, detailMenu3.Id, 3));
        relations.add(createPageBuilderJoin(subMenu1.Id, detailMenu4.Id, 4));
        relations.add(createPageBuilderJoin(subMenu1.Id, detailMenu5.Id, 5));
        relations.add(createPageBuilderJoin(subMenu1.Id, detailMenu5.Id, 6));
        relations.add(createPageBuilderJoin(subMenu1.Id, detailMenu5.Id, 7));

        insert relations;

        insert accesses;

        ContentVersion cvEarliest = SObjectRepository.getContentVersion();
        Id cId = cvEarliest.Id;
    

        List<NAP_File_Filter__c> filters = new List<NAP_File_Filter__c>();

        filters.add(new NAP_File_Filter__c(Tag_Filter_Long__c='2015, 2016', Tag_Condition__c = 'AND', Tag_to_Attribute_Condition__c = 'AND', Attribute_Filters__c = 'Tier', Attribute_Condition__c = 'AND', NAP_Page_Builder__c=detailMenu1.Id, File_Display_Type__c='Tiles'));

        filters.add(new NAP_File_Filter__c(Tag_Filter_Long__c='2015, 2016', Tag_Condition__c = 'AND', Tag_to_Attribute_Condition__c = 'AND', Attribute_Filters__c = 'Partner Account', Attribute_Condition__c = 'AND', NAP_Page_Builder__c=detailMenu2.Id, File_Display_Type__c='List'));

        filters.add(new NAP_File_Filter__c(Tag_Filter_Long__c='2017, 2016', Tag_Condition__c = 'OR' , NAP_Page_Builder__c=subMenu2.Id, File_Display_Type__c='List'));

        filters.add(new NAP_File_Filter__c(File_Resource_IDs__c=cId, Attribute_Condition__c = 'AND', NAP_Page_Builder__c=detailMenu3.Id, File_Display_Type__c='Icons'));

        insert filters;

        List<NAP_News_Item__c> newsItems = new List<NAP_News_Item__c>();

        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-30), Publish_Status__c='Live',Item_Type__c='News', News_Type__c='General', Title__c='NNI1', RAW_HTML__c='test'));
        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-80), Publish_Status__c='Live',Item_Type__c='Events', News_Type__c='General', Title__c='NNI2', RAW_HTML__c='test'));
        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-600), Publish_Status__c='Archive',Item_Type__c='News', News_Type__c='General', Title__c='NNI3',RAW_HTML__c='test'));
        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-400), Publish_Status__c='Live',Item_Type__c='News',Attribute__c='User Type', Attribute_Value__c='OTP', News_Type__c='Webinar', Title__c='NNI4',RAW_HTML__c='test'));


        insert newsItems;

        insert new NAP_News_Item_Link__c(NAP_News_Item__c=newsItems[0].Id, Link__c='https://google.com', Link_Display_Text__c='Google');


    }

    
    private static NAP_Page_Builder_Join__c createPageBuilderJoin(Id parentId, Id childId, Integer pComponentOrder)
    {
        NAP_Page_Builder_Join__c newPageBuilderJoin = new NAP_Page_Builder_Join__c();
        newPageBuilderJoin.NAP_Page_Builder_Parent__c = parentId;
        newPageBuilderJoin.NAP_Page_Builder_Child__c = childId;
        newPageBuilderJoin.Order__c = pComponentOrder;
        return newPageBuilderJoin;
    }

    private static NAP_Page_Security__c createNAPSecurity(Id pageBuilder)
    {
        NAP_Page_Security__c newPageSecurity = new NAP_Page_Security__c();
        newPageSecurity.NAP_Page_Builder__c = pageBuilder;
        newPageSecurity.Security_Type_Id__c = String.valueOf(SObjectRepository.getProfileId('Partner Community Admin')).substring(0,15);
        newPageSecurity.Type__c = 'Profile';
        return newPageSecurity;
    }

    private static void insertContentFiles()
    {
        RecordType ContentRT = [select Id FROM RecordType WHERE Name='PRM'];
        ContentVersion testContent = new ContentVersion(); 
        testContent.RecordTypeId = ContentRT.Id;
        testContent.TagCsv = '2015, 2016';
        testContent.Tag__c='2015, 2016';
        testContent.Title= 'testycontent';
        testContent.Language__c = 'Korean';
        testContent.PathOnClient = 'testy';
        testContent.VersionData = blob.valueof('testng');
        //testContent.ContentURL = 'https://www.akamai.com/us/en/multimedia/documents/technical-publication/pushing-cdn-isp-collaboration-to-the-limit-technical-publication.pdf';
        ContentVersion testContent2 = new ContentVersion(); 
        testContent2.RecordTypeId = ContentRT.Id;
        testContent2.TagCsv = '2016, 2017';
        testContent2.Tag__c='2015, 2014';
        testContent2.Title= 'testycontent';
        testContent2.Language__c = 'Korean';
        testContent2.PathOnClient = 'testy';
        testContent2.VersionData = blob.valueof('testng');
        List<ContentVersion> cvList = new List<ContentVersion>();
        cvList.add(testContent);
        cvList.add(testContent2);

        insert cvList;
        testContent = [select id, ContentDocumentId from ContentVersion where id=:testContent.Id];

        testContent2 = [select id, ContentDocumentId from ContentVersion where id=:testContent2.Id];

        ContentWorkspace partnerWorkspace = [SELECT Id FROM ContentWorkspace WHERE Name='Partner Facing Documents - SHARE'];
        System.assert(partnerWorkspace.Id!=null);
        
        ContentWorkspaceDoc newWorkspaceDoc =new ContentWorkspaceDoc(); 
        newWorkspaceDoc.ContentWorkspaceId =partnerWorkspace.Id; 
        newWorkspaceDoc.ContentDocumentId = testContent.ContentDocumentId; 
        insert newWorkspaceDoc;

        ContentWorkspaceDoc newWorkspaceDoc2 =new ContentWorkspaceDoc(); 
        newWorkspaceDoc2.ContentWorkspaceId =partnerWorkspace.Id; 
        newWorkspaceDoc2.ContentDocumentId = testContent2.ContentDocumentId; 
        insert newWorkspaceDoc2;
    }

    static testmethod void testAddAttributeController()
    {

        ContentVersion testContent = (ContentVersion)SobjectRepository.get(ContentVersion.sObjectType);
        Test.setCurrentPage(Page.AddContentVersionAttributes);
        ApexPages.currentPage().getParameters().put('ContentVersionId',testContent.Id);

        AddContentVersionAttributeController controller = new AddContentVersionAttributeController();

        controller.getAttributes();
        controller.addNewAttribute();

        controller.newAttr.Attribute_Name__c='Tier';
        controller.newAttr.Attribute_Value__c='Gold';
        controller.saveAttribute();

        ApexPages.currentPage().getParameters().put('attr_id',controller.getAttributes()[0].Id);

        controller.editAttribute();

        controller.cancelCreation();
        ApexPages.currentPage().getParameters().put('attr_id',controller.getAttributes()[0].Id);
        controller.deleteAttribute();

        controller.addNewAttribute();

        Account partnerAccount = SobjectRepository.getPartnerAccount();

        controller.newAttr.Attribute_Name__c='Partner Account';
        controller.newAttr.Partner_Account__c=partnerAccount.Id;
        controller.saveAttribute();

        controller.addNewAttribute();

        controller.newAttr.Attribute_Name__c='Tier';
        controller.newAttr.Attribute_Value__c='Gold';
        controller.saveAttribute();

        User partnerUser = SobjectRepository.getPartnerUser();

        System.assert(partnerUser.ContactId!=null, 'Partner Contact Id is null');
        System.assert(partnerUser.UserRoleId!=null, 'Partner Role Id is null');
        //System.assert(partnerUser.Contact.Partner_User__c!=null, 'Partner User field is not populate on contact');
        NAP_Page_Builder__c currentMainMenu0 = [select id, name from NAP_Page_Builder__c where Component_Type__c='Main Menu' order by Component_Order__c asc limit 1];


        System.assert(currentMainMenu0.Name!=null, 'No Current Main Menu');
        Test.startTest();
        ContentVersion cv;
        System.runAs(dmlUser)
		{
            cv = L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Title', 'Title', 'Test Data');
            insert cv;
            ContentVersion cvI = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id];
            String partnerSharingLibraryId = NAPSettings.getValue('LibrariesAvailableForPartnerFileDownload');
            List<String> listOfAvailableLibraries = partnerSharingLibraryId.split(',');

            ContentWorkspaceDoc doc = L2Q_ContentDocumentUtilClass.setContentWorkspaceDoc(Id.valueOf(listOfAvailableLibraries.get(0)), cvI.ContentDocumentId);
            //insert doc;
        }
        testContent = (ContentVersion)SobjectRepository.getContentVersion();
        System.runAs(partnerUser)
        {
            

            System.assert(testContent.Id!=null, 'Content file is not accessible to partner');

            NAP_Page_Builder__c currentMainMenu = [select id, name from NAP_Page_Builder__c where Component_Type__c='Main Menu' order by Component_Order__c asc limit 1];


            System.assert(currentMainMenu.Name!=null, 'No Current Main Menu');

            List<NAP_Page_Builder_Join__c> ll = [select NAP_Page_Builder_Parent__r.Name from NAP_Page_Builder_Join__c where NAP_Page_Builder_Child__c=:currentMainMenu.Id];
            
            System.assert(ll[0].NAP_Page_Builder_Parent__r.Name!='NP1', 'Page menu is not the parent. THis is:'+ll[0].NAP_Page_Builder_Parent__r.Name);

            PageReference pageRef = Page.NAPLandingPage;
            Test.setCurrentPageReference(pageRef);
            NAPLandingPageController testController = new NAPLandingPageController();
            testController.getMenuItems();
            testController.getPermanentMenuItems();
            testController.getCarouselItems();
            testController.getBillBoardText();

            pageRef = Page.NAP;
            Test.setCurrentPageReference(pageRef);
            System.currentPageReference().getParameters().put('page_id', currentMainMenu0.Name);
            NAPRebrandedPageController tController = new NAPRebrandedPageController();
            tController.sendErrorMail();
            //NAPRebrandedPageController.search('Test');
            //subscribe to file 
            NAPRebrandedPageController.saveFileSubscriptionDetails(testContent.ContentDocumentId,true);
            //Test related to News subscription
            NAPRebrandedPageController.getNewsSettings();
            List<String> types = new List<String>();
            types.add('Product');
            // TODO - replace with the new method signature
            //NAPRebrandedPageController.saveNewsSubscriptionDetails('Daily', types, true, false, false);
            

            List<String> event = new List<String>();
            types.add('Event1');
            types.add('Event2');
            NAP_News_Subscription__c subsciption = new NAP_News_Subscription__c(Partner_User__c = partnerUser.id,
	    																		Enable_Disable__c = true,
	    																		Frequency__c = 'Weekly',
	    																		Type__c = 'Webinar');
	        insert subsciption;
            NAPRebrandedPageController.saveNewsSubscriptionDetails('Daily', types, event, true, false, false);
            NAPRebrandedPageController.NewsSubscriptionWrapper nw = NAPRebrandedPageController.getNewsSettingsObject('value');
            System.currentPageReference().getParameters().put('page_id', 'random_id');
            tController = new NAPRebrandedPageController();


            //System.assert(CurrentUser.hasFileAccess(testContent.Id), true);
            
            Boolean check = CurrentUser.hasFileAccess(cv.Id);
            // error mail
            // set libsub
            NAPUtilClass.getFileSize(2000);
            NAPUtilClass.getFileSize(2000000);
            NAPUtilClass.getFileSize(2000000000);
            //NAPUtilClass.getLatestVersion(testContent.Id);


            //Check individual news item scenario
            List<NAP_News_Item__c> newsList = [Select id,Name from NAP_News_Item__c limit 1];
            if (newsList.size() > 0) {
                NAP_News_Item__c news = newsList[0];

                PageReference pageRef2 = Page.NAPLandingPage;
                Test.setCurrentPageReference(pageRef2);
                NAPLandingPageController testController2 = new NAPLandingPageController();
                testController2.getMenuItems();
                testController2.getPermanentMenuItems();
                testController2.getCarouselItems();
                testController2.getBillBoardText();
                NAPNews.containsOTPPermissionSet(UserInfo.getUserId());

                pageRef2 = Page.NAP;
                Test.setCurrentPageReference(pageRef2);
                System.currentPageReference().getParameters().put('page_id', currentMainMenu0.Name);
                System.currentPageReference().getParameters().put('news_id', news.Name);
                NAPRebrandedPageController tController2 = new NAPRebrandedPageController();
            }

        }

        NAPRebrandedPageController.setLibrarySubscriptionDetails(false);

        Test.stopTest();
   }

	public static testmethod void testNAPSubscriptionBatchCronRun()
	{
		RecordType ContentRT = [select Id FROM RecordType WHERE Name='PRM'];

		Cron_Batch_Job__c testBatchJob = utilTestClass.createCronBatchJob('NAP File Subscription Digest','NAP File Subscription Digest');
		insert testBatchJob;
		Cron_Batch_Run__c testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
		testBatchRun.Completed__c = System.now();
		testBatchRun.Result__c = 'Success';
		insert testBatchRun;

		System.runAs(dmlUser)
		{
			ContentVersion testCV1 =new ContentVersion(); 
			testCV1.ContentURL='http://www.google.com/'; 
			testCV1.Title ='Google.com';
			testCV1.RecordTypeId = ContentRT.Id;
			insert testCV1;

			ContentVersion testCV2 =new ContentVersion(); 
            testCV2.VersionData = blob.valueof('testing');
            testCV2.PathOnClient = '/Users/eric/file2.txt';
			testCV2.Title ='Yahoo.com';
			testCV2.RecordTypeId = ContentRT.Id;
			insert testCV2;

			ContentWorkspace partnerWorkspace = [SELECT Id FROM ContentWorkspace WHERE Name='Partner Facing Documents - SHARE'];
		    System.assert(partnerWorkspace.Id!=null);

		    ContentVersion testContent = [select id, ContentDocumentId from ContentVersion where id=:testCV1.Id];
		    
		    ContentWorkspaceDoc newWorkspaceDoc =new ContentWorkspaceDoc(); 
		    newWorkspaceDoc.ContentWorkspaceId =partnerWorkspace.Id; 
		    newWorkspaceDoc.ContentDocumentId = testContent.ContentDocumentId; 
		    insert newWorkspaceDoc;

		    testContent = [select id, ContentDocumentId from ContentVersion where id=:testCV2.Id];

		    newWorkspaceDoc =new ContentWorkspaceDoc(); 
		    newWorkspaceDoc.ContentWorkspaceId =partnerWorkspace.Id; 
		    newWorkspaceDoc.ContentDocumentId = testContent.ContentDocumentId; 
		    insert newWorkspaceDoc;


            Contact partnerContact = SobjectRepository.getPartnerContact();
			partnerContact.Subscribed_to_Library__c = true;

			update partnerContact;


			Document napLogo = new Document();
			napLogo.Name = 'Generic Netalliance Logo';
			napLogo.FolderId = UserInfo.getUserId();  
			insert napLogo;
            User partnerUser = SobjectRepository.getPartnerUser();
            
            //System.assert(partnerUser.Contact.AccountId!=null, 'partner user doesnt have contact:'+partnerUser.Contact.AccountId);

			// ContentVersionAttribute__c cvAttr = new ContentVersionAttribute__c();
			// cvAttr.ContentVersionId__c = testCV2.Id;
			// cvAttr.Attribute_Name__c = 'Partner Account';
			// cvAttr.Attribute_Value__c = 'Sales';
			// cvAttr.Partner_Account__c = partnerUser.Contact.AccountId;
			// insert cvAttr;

			Test.startTest();

			CronJobTypes.insertBatchJobAndRun('NAP File Subscription Digest');
			NAPFileSubscriptionDigestBatchClass batchInstance = new NAPFileSubscriptionDigestBatchClass();
			Database.executeBatch(batchInstance);
            testCV2.VersionData = blob.valueof('tfdating');
            update testCV2;

            testCV2 = [select id, contentDocumentId from ContentVersion where id=:testCV2.Id];


			ContentVersion testCV3 =new ContentVersion(); 
			testCV3.Title ='Google.com';
            testCV3.VersionData = blob.valueof('fdajkd');
			testCV3.RecordTypeId = ContentRT.Id;
            testCV3.PathOnClient ='/users/eric/f.rxt';
            testCV3.ContentDocumentId=testCV2.ContentDocumentId;
			insert testCV3;



			Test.stopTest();
		}
	}

    public static testmethod void testScenarioForOTNews() 
    {
    	
    	System.runAs(dmlUser)
        {
            Account partnerAccount = SobjectRepository.getPartnerAccount();
            partnerAccount.NAP_Area__c='OTP';
            update partnerAccount;
            User partnerUser = SobjectRepository.getPartnerUser();
            //System.assert(partnerUser.Contact.AccountId!=null, 'partner user doesnt have contact:'+partnerUser.Contact.AccountId);

	        //Create subscription record
	        NAP_News_Subscription__c subsciption = new NAP_News_Subscription__c(Partner_User__c = partnerUser.id,
	    																		Enable_Disable__c = true,
	    																		Frequency__c = 'Weekly',
	    																		Type__c = 'Webinar');
	        insert subsciption;

	        List<PermissionSet> psList = [select Id from PermissionSet where Name = 'OTP'];

	        if (psList != null && psList.size() > 0) {
	        	PermissionSet ps = psList[0];
		        PermissionSetAssignment psa = new PermissionSetAssignment();
		        psa.AssigneeId = partnerUser.Id;
		        psa.PermissionSetId = ps.id;
		        insert psa;
	        }

	        Document napLogo = new Document();
			napLogo.Name = 'Generic Netalliance Logo';
			napLogo.FolderId = UserInfo.getUserId();  
			insert napLogo;

	    	//Create NAP news
	        List<NAP_News_Item__c> newsItems = new List<NAP_News_Item__c>();

            newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-30), Publish_Status__c='Live',Item_Type__c='News', News_Type__c='General', Title__c='NNI1', RAW_HTML__c='test'));
        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-80), Publish_Status__c='Live',Item_Type__c='Events', News_Type__c='General', Title__c='NNI2', RAW_HTML__c='test'));
        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-600), Publish_Status__c='Archive',Item_Type__c='News', News_Type__c='General', Title__c='NNI3',RAW_HTML__c='test'));
        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-400), Publish_Status__c='Live',Item_Type__c='News',Attribute__c='User Type', Attribute_Value__c='OTP', News_Type__c='Webinar', Title__c='NNI4',RAW_HTML__c='test'));


	        insert newsItems;

	        insert new NAP_News_Item_Link__c(NAP_News_Item__c=newsItems[0].Id, Link__c='https://google.com', Link_Display_Text__c='Google');

	        Test.startTest();
	        NAPNewsSubscriptionBatchClass job = new NAPNewsSubscriptionBatchClass('Weekly');
	        Database.executeBatch(job);
	        Test.stopTest();
	    }
    }

    public static testmethod void testNonOTScenarioWeekly() {
    	
    	System.runAs(dmlUser)
        {

            User partnerUser = SobjectRepository.getPartnerUser();
            //System.assert(partnerUser.Contact.AccountId!=null, 'partner user doesnt have contact:'+partnerUser.Contact.AccountId);

	        //Create subscription record
	        NAP_News_Subscription__c subsciption = new NAP_News_Subscription__c(Partner_User__c = partnerUser.id,
	    																		Enable_Disable__c = true,
	    																		Frequency__c = 'Weekly',
	    																		Type__c = 'Webinar');
	        insert subsciption;

	        Document napLogo = new Document();
			napLogo.Name = 'Generic Netalliance Logo';
			napLogo.FolderId = UserInfo.getUserId();  
			insert napLogo;

	    	//Create NAP news
	        List<NAP_News_Item__c> newsItems = new List<NAP_News_Item__c>();

	        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-30), Publish_Status__c='Live', Item_Type__c='News', News_Type__c='Product', Title__c='NNI1', RAW_HTML__c='test'));
	        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-80), Publish_Status__c='Live', Item_Type__c='News', News_Type__c='Product', Title__c='NNI2', RAW_HTML__c='test'));
	        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-600), Publish_Status__c='Archive', Item_Type__c='News', News_Type__c='Product', Title__c='NNI3',RAW_HTML__c='test'));
	        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-400), Publish_Status__c='Archive', Item_Type__c='News', News_Type__c='Webinar', Title__c='NNI4',RAW_HTML__c='test'));

	        insert newsItems;

	        insert new NAP_News_Item_Link__c(NAP_News_Item__c=newsItems[0].Id, Link__c='https://google.com', Link_Display_Text__c='Google');

	        Test.startTest();
	        NAPNewsSubscriptionBatchClass job = new NAPNewsSubscriptionBatchClass('Weekly');
	        Database.executeBatch(job);
	        Test.stopTest();
	    }
    }

    public static testmethod void testNonOTScenarioDaily() {
    	
    	System.runAs(dmlUser)
        {
            User partnerUser = SobjectRepository.getPartnerUser();
            //System.assert(partnerUser.Contact.AccountId!=null, 'partner user doesnt have contact:'+partnerUser.Contact.AccountId);


	        //Create subscription record
	        NAP_News_Subscription__c subsciption = new NAP_News_Subscription__c(Partner_User__c = partnerUser.id,
	    																		Enable_Disable__c = true,
	    																		Frequency__c = 'Daily',
	    																		Type__c = 'Webinar');
	        insert subsciption;

	        Document napLogo = new Document();
			napLogo.Name = 'Generic Netalliance Logo';
			napLogo.FolderId = UserInfo.getUserId();  
			insert napLogo;

	    	//Create NAP news
	        List<NAP_News_Item__c> newsItems = new List<NAP_News_Item__c>();

	        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-30), Publish_Status__c='Live', Item_Type__c='News', News_Type__c='Product', Title__c='NNI1', RAW_HTML__c='test'));
	        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-80), Publish_Status__c='Live', Item_Type__c='News', News_Type__c='Product', Title__c='NNI2', RAW_HTML__c='test'));
	        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-600), Publish_Status__c='Archive', Item_Type__c='News', News_Type__c='Product', Title__c='NNI3',RAW_HTML__c='test'));
	        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-400), Publish_Status__c='Archive', Item_Type__c='News', News_Type__c='Webinar', Title__c='NNI4',RAW_HTML__c='test'));

	        insert newsItems;

	        insert new NAP_News_Item_Link__c(NAP_News_Item__c=newsItems[0].Id, Link__c='https://google.com', Link_Display_Text__c='Google');

	        Test.startTest();
	        NAPNewsSubscriptionBatchClass job = new NAPNewsSubscriptionBatchClass('Daily');
	        Database.executeBatch(job);
	        Test.stopTest();
	    }
    }

	static testMethod void testNAPFileSubscribe()
    {
        System.runAs(dmlUser)
        {
            ContentVersion cv = new ContentVersion(title='foo', contentUrl='http:///www.foor.bar');
    		insert cv;
            ContentVersion cvRes = [select id, ContentDocument.id, ContentDocument.title 
                                    from ContentVersion where id= :cv.id];
            ContentDocument cd = cv.ContentDocument;
            
            NAP_File_Subscribe__c fileSubscribeRecord = new NAP_File_Subscribe__c(Active_subscription__c  = true,
                                                                                 Content_Document_Id__c = cvRes.id,
                                                                                 Subscription_Date__c = System.now(),
                                                                                 User__c  = UserInfo.getUserId());
            insert fileSubscribeRecord;
            
            ContentVersionAttribute__c  cva = new ContentVersionAttribute__c(Attribute_Name__c  = 'Tier',
                                                                             Attribute_Value__c = 'Gold',
                                                                            ContentVersionId__c = cvRes.id);
            insert cva;
            
            List<NAP_File_Subscribe__c> fileSubscribeAfterAttributes = [Select id from NAP_File_Subscribe__c where Content_Document_Id__c =:cvRes.ContentDocument.id];
            System.assertEquals(fileSubscribeAfterAttributes.size(), 0);
        }   
    }

    static testMethod void testContentVersionAttributes()
    {
        System.runAs(dmlUser)
        {
            ContentVersion cv = new ContentVersion(title='foo', contentUrl='http:///www.foor.bar');
            insert cv;
            ContentVersion cvRes = [select id, ContentDocument.id, ContentDocument.title 
                                    from ContentVersion where id= :cv.id];
            ContentDocument cd = cv.ContentDocument;

            ContentVersionAttribute__c  cva = new ContentVersionAttribute__c(Attribute_Name__c  = 'Tier',
                                                                             Attribute_Value__c = 'Gold',
                                                                            ContentVersionId__c = cvRes.id);
            insert cva;

            PageReference pageRef = Page.AddContentVersionAttributes;
            Test.setCurrentPage(pageRef);

            pageRef.getParameters().put('ContentVersionId', cvRes.id);

            AddContentVersionAttributeController controller = new AddContentVersionAttributeController();

            List<ContentVersionAttribute__c> cvaList = controller.getAttributes();
            System.assertEquals(cvaList.size(),1);

            ApexPages.currentPage().getParameters().put('attr_id', cva.id);
            controller.editAttribute();

            controller.addNewAttribute();
            
            ContentVersionAttribute__c cvaNew = controller.newAttr;
            cvaNew.Attribute_Name__c  = 'Tier';
            cvaNew.Attribute_Value__c = 'NAP1';
            cvaNew.ContentVersionId__c = cvRes.id;

            //ApexPages.currentPage().getParameters().put('newAttr', cvaNew);
            controller.saveAttribute();

            System.assertEquals(controller.getAttributes().size(),2);

            ApexPages.currentPage().getParameters().put('attr_id', cva.id);
            controller.deleteAttribute();

            System.assertEquals(controller.getAttributes().size(),1);
            
            controller.cancelCreation();
        }   
    }

    private static ContentVersion refreshFile(Id cvId)
    {
        return [select id, tagcsv, tag__c from ContentVersion where Id=:cvId];
    }

    private static List<ContentVersion> refreshFiles(String titleLike)
    {
        return [select id, tagcsv, tag__c from ContentVersion where Title like :titleLike+'%' order by CreatedDate];
    }
    
    static testMethod void updatecvTagOnInsertAndUpdateTest()
    {
        System.runAs(dmlUser)
        {
            List<ContentVersion> tFiles = new List<ContentVersion>();
            // changing number to 1 because updateAttributes method is not bulkified
            Integer numberOfTestFiles = 2;

            for(integer i=0;i<numberOfTestFiles;i++)
            {
                ContentVersion TestRec = new ContentVersion();
                TestRec.Title = '__TSTREC'+i;
                TestRec.ContentUrl = 'www.test.com';
                TestRec.TagCsv = '2015t'+i;
                tFiles.add(TestRec);
            }


            insert tFiles;

            tFiles = refreshFiles('__TSTREC');
            for(integer i=0;i<numberOfTestFiles;i++)
            {
                system.assertEquals(tFiles[i].Tag__c  ,'2015t'+i);
                tFiles[i].TagCsv = '2016t'+i;
            }

            Test.startTest();
            update tFiles;

            tFiles = refreshFiles('__TSTREC');
            for(integer i=0;i<numberOfTestFiles;i++)
            {
                system.assertEquals(tFiles[i].Tag__c  ,'2016t'+i);
                tFiles[i].TagCsv = '';
            }
            update tFiles;

            tFiles = refreshFiles('__TSTREC');
            for(integer i=0;i<numberOfTestFiles;i++)
            {
                system.assertNotEquals(tFiles[i].Tag__c  ,'');
            }
            // run the bath job and refresh and see
            ContentVersionTagCopyBatchClass cvbc = new ContentVersionTagCopyBatchClass();
            Database.executeBatch(cvbc);
            Test.stopTest();
            tFiles = refreshFiles('__TSTREC');
            for(integer i=0;i<numberOfTestFiles;i++)
            {
                system.assert(String.isBlank(tFiles[i].Tag__c));
            }

        }   
    }
     static testmethod void testContentDownLoadBlocker()
     {
         Test.startTest();
         List<Id> cIDList = new List<Id>();
         User partnerUser = SobjectRepository.getPartnerUser();

        //  System.runAs(partnerUser)
        //  {
             List<ContentVersion> files = [Select Id,ContentDocumentId,IsLatest From ContentVersion Where IsLatest =true];
             cIDList.add(files[0].Id);

             ContentDownloadBlocker cb = new ContentDownloadBlocker();
             Sfc.ContentDownloadContext c;
             Sfc.ContentDownloadHandler ch= new Sfc.ContentDownloadHandler();
             ch = cb.getContentDownloadHandler(cIDList,c);
             System.runAs(partnerUser) {
                ch = cb.getContentDownloadHandler(cIDList,c);
                cIDList.add(files[1].Id);
                ch = cb.getContentDownloadHandler(cIDList,c);
             }
             Sfc.ContentDownloadHandler ch1= new Sfc.ContentDownloadHandler();
             ch1 = cb.hasAccess();
             cb.insufficientDownloadAccess();

        //  }

         Test.stopTest();
     }

    static testmethod void testNAPVideoPlayer()
    {
        Test.startTest();
        User partnerUser = SobjectRepository.getPartnerUser();
        // System.runAs(partnerUser)
        // {
            Test.setCurrentPage(Page.NAPVideoPlayer);
            List<ContentVersion> files = [Select Id,ContentDocumentId,IsLatest From ContentVersion Where IsLatest =true];
            ApexPages.currentPage().getParameters().put('id',files[0].Id);
            NAPVideoPlayerController nvp = new NAPVideoPlayerController();
            System.assert(nvp.errorMessage==null, 'There was an error while displaying videos');

            ApexPages.currentPage().getParameters().put('id','invalidid');
            NAPVideoPlayerController nvp2 = new NAPVideoPlayerController();
            System.assert(nvp2.errorMessage!=null, 'Error display isnt working');

            NAP_Video__c nv = new NAP_Video__c(Video_Title__c='testingtitle', Video_URL__c='/testing/a.m3u8');
            insert nv;

            nv = [select id from NAP_Video__c limit 1];

            ApexPages.currentPage().getParameters().put('id', nv.Id);
            NAPVideoPlayerController nvp3 = new NAPVideoPlayerController();

            AkamaiEdgeAuthTokenGenerator.generateToken('/urlpath/abc.m3u8', 86400);

            TrainingVideoPlayerController tvp = new TrainingVideoPlayerController();

        // }

        Test.stopTest();
    }

    static testmethod void testPartnerLoginController()
    {
        System.runAs(dmlUser) 
        {
            PageReference pageRef = Page.PartnerLogin;
            Test.setCurrentPageReference(pageRef);
            ApexPages.currentPage().getParameters().put('startURL', '');
            PartnerLoginController.redirectToIdp();
        }
    }

    public static testmethod void PartnerAccessController()
    {
        Test.startTest();
        User partner = SobjectRepository.getPartnerUser();
        Contact partnerContact;
        System.runAs(dmlUser)
        {
            partner.Has_MDF_Access__c = true;
            partner.Has_DealRegistration_Access__c = true;
            partner.Has_View_Trial_Access__c=true;
            partner.Has_Start_Trial_Access__c=true;
            update partner; 
            partner=[select id,contactid,Has_Partner_Lead_View_Access__c,Has_View_Trial_Access__c, Has_Start_Trial_Access__c,View_Pricing_Details__c,Has_Partner_Lead_Access__c,Has_MDF_Access__c,Has_DealRegistration_Access__c,Has_PartnerCertification_Access__c,Has_PartnerPlans_Access__c,Can_Accept_POA__c, Has_view_content_in_portals__c, ProfileId, Profile.Name,Has_Partner_Concierge_Access__c from User where id=:partner.id ][0];
            partnerContact = [Select id,Account.AKAM_Account_Id__c,Has_Akamai_University_Access__c from Contact where id=:partner.contactid];
            partnerContact.Has_Akamai_University_Access__c=true;
            PageReference pageRef = Page.DefinePartnerAccess;
            Test.setCurrentPageReference(pageRef);
            ApexPages.currentPage().getParameters().put('id',partnerContact.id);
            PartnerAccessController pactroller  = new PartnerAccessController();
            pactroller.partnerCon = partnerContact;
            pactroller.hasAUAccess=false;
            pactroller.updateContact();
            PartnerAccessController.updateRemoveUserPermissionSet(partner,partnerContact);
            //PartnerUserController.enableDisablePOAAccess(partnerContact.Id, 'True', 'False');
            //PartnerUserController.enableDisablePOAAccess(partnerContact.Id, 'False', 'True');
            partner.Has_MDF_Access__c =false;
            partner.Has_DealRegistration_Access__c =false;
            PartnerAccessController.populateProfile(partner);
            PartnerAccessController.isLiteLicenseSufficient(partner);
            //Test.setCurrentPageReference(Page.LunaAPIConnection);
            //LunaAPIConnectionController tController = new LunaAPIConnectionController();
        }

        System.runAs(partner)
        {
            PartnerAccessController pac = new PartnerAccessController();
            pac.partnerUser =partner;
            pac.partnerCon = partnerContact;
            pac.getBUOptions();
            pac.getBUOptionsProfile();
            pac.exceptionCheck();
            pac.updateAccess();
            pac.updateContact();
            pac.edit();
            pac.cancel();
            pac.setProfiles();
            pac.BUOpt='fdsa';
            pac.BUOptProfile='fds';

        }
        Test.stopTest();

    }
    
    public static testmethod void LoginRedirectController() {
        System.runAs(utilTestClass.getTestRunUser()) {
           Test.setCurrentPageReference(Page.LoginRedirect);
           ContentVersion cvEarliest = SObjectRepository.getContentVersion();
           ApexPages.currentPage().getParameters().put('url', '/'+cvEarliest.id);
           LoginRedirectController fruc = new LoginRedirectController();
    
           fruc.RedirectPage();
       }
    }
}*/

@isTest(seeAllData = false)
 private class NAPTests{

   
    static User dmlUser = new User(id=UserInfo.getUserId());

    @testSetUp static void insertCustomSettingsAndCreateData()
    {
        System.runAs(utilTestClass.getTestRunUser())
        {
            Test.startTest();
            utilTestClass.insertCustomSettings();
            insert new PRM_Settings__c(name='NonLitePermissionSets', Value__c='Has_DealRegistration_Access__c,Has_PartnerPlans_Access__c');
            User partnerUser = (User)(SObjectFactory.createPartnerUsers(1).get(0));

            insertContentFiles();
            createNAPItems();
            Test.stopTest();

        }
    }

    private static void createNAPItems()
    {
        List<NAP_Page_Builder__c> napItems = new List<NAP_Page_Builder__c>();
        List<NAP_Page_Security__c> accesses = new List<NAP_Page_Security__c>();

        // pages
        for( Integer i=0;i<8;i++)
        {
            NAP_Page_Builder__c newPage = new NAP_Page_Builder__c(Title__c='NP'+i, Description__c='NTD'+i, Image__c ='NTI'+i, Component_Type__c='Page', Component_Order__c=i);
            napItems.add(newPage);
        }

        // carousels
        List<Document> docs = new List<Document>();
        Id folderId = [select id from folder where name='Partner Portal Folder' limit 1].Id;

        for( Integer i=0;i<2;i++)
        {
            NAP_Page_Builder__c newCarousel = new NAP_Page_Builder__c(Title__c='NC'+i, Description__c='NTD'+i, Image__c ='CIMJ'+i, Component_Type__c='Carousel', Component_Order__c=i);
            napItems.add(newCarousel);

            docs.add(new Document(Name='CIMJ'+i,FolderId=folderId));
        }

        insert docs;


        insert napItems;

        List<NAP_Page_Builder__c> menuItems = new List<NAP_Page_Builder__c>();

        // main menus
        for( Integer i=0;i<2;i++)
        {
            NAP_Page_Builder__c newMainMenu = new NAP_Page_Builder__c(Title__c='NMM'+i, Description__c='NTD'+i, Image__c ='NTI'+i, Component_Type__c='Main Menu', Component_Order__c=i);
            menuItems.add(newMainMenu);

        }

        // permanent menus
        for( Integer i=0;i<2;i++)
        {
            NAP_Page_Builder__c newPermanentMenu = new NAP_Page_Builder__c(Title__c='NPM'+i, Description__c='NTD'+i, Image__c ='NTI'+i, Component_Type__c='Permanent Menu', Component_Order__c=i);
            menuItems.add(newPermanentMenu);
        }

        insert menuItems;

        List<NAP_Page_Builder_Join__c> relations = new List<NAP_Page_Builder_Join__c>();


        Integer order=1;
        for(NAP_Page_Builder__c npb : menuItems)
        {
            relations.add(createPageBuilderJoin(napItems[0].Id, npb.Id, order));
            if(order!=2)
            {
                accesses.add(createNAPSecurity(npb.Id));
            }
            order++;
        }

        List<NAP_Page_Builder__c>  contentMenus = new List<NAP_Page_Builder__c>();
        // sub menus
        NAP_Page_Builder__c subMenu2 = new NAP_Page_Builder__c(Title__c='NSM1', Component_Type__c='Sub Menu', Content_Type__c='HTML', Raw_HTML_Content__c='Some stuff', Is_File_Browser__c=true);
        contentMenus.add(subMenu2);

        NAP_Page_Builder__c subMenu1 = new NAP_Page_Builder__c(Title__c='NSM2', Description__c='NSM2', Component_Type__c='Sub Menu');
        contentMenus.add(subMenu1);


        NAP_Page_Builder__c detailMenu1 = new NAP_Page_Builder__c(Title__c='DM1', Component_Type__c='Detail Menu', Content_Type__c='HTML with Placeholders', Raw_HTML_Content__c='Some stuff', Is_File_Browser__c=true, Has_Tag_Filters__c=true, Has_Language_Filters__c=true);
        contentMenus.add(detailMenu1);

        NAP_Page_Builder__c detailMenu2 = new NAP_Page_Builder__c(Title__c='DM2', Component_Type__c='Detail Menu', Content_Type__c='HTML', Raw_HTML_Content__c='Some stuff', Is_Nap_Search__c=true);
        contentMenus.add(detailMenu2);

        NAP_Page_Builder__c detailMenu3 = new NAP_Page_Builder__c(Title__c='DM3', Component_Type__c='Detail Menu', Content_Type__c='HTML', Raw_HTML_Content__c='Some stuff', Is_News_Filter__c=true);
        contentMenus.add(detailMenu3);

        NAP_Page_Builder__c detailMenu4 = new NAP_Page_Builder__c(Title__c='DM4', Component_Type__c='Detail Menu', Content_Type__c='HTML with Placeholders', Raw_HTML_Content__c='Some stuff #Video=External,https://www.youtube.com/embed/InjL1JqiKhw,233,233#', News_Display_Type__c='Archive');
        contentMenus.add(detailMenu4);

        NAP_Page_Builder__c detailMenu5 = new NAP_Page_Builder__c(Title__c='DM5', Component_Type__c='Detail Menu', Content_Type__c='HTML', Raw_HTML_Content__c='Some stuff', Is_News_Filter__c=true);
        contentMenus.add(detailMenu5);

        NAP_Page_Builder__c detailMenu6 = new NAP_Page_Builder__c(Title__c='DM6', Component_Type__c='Detail Menu', Content_Type__c='HTML', Raw_HTML_Content__c='Some stuff', Is_News_Filter__c=true);
        contentMenus.add(detailMenu6);

        NAP_Page_Builder__c detailMenu7 = new NAP_Page_Builder__c(Title__c='DM7', Component_Type__c='Detail Menu', Content_Type__c='HTML', Raw_HTML_Content__c='Some stuff', Is_News_Subscription__c=true);
        contentMenus.add(detailMenu7);        

        insert contentMenus;

        List<NAP_News_Filter__c> newFilterList = new List<NAP_News_Filter__c>();

        NAP_News_Filter__c newFilter1 = new NAP_News_Filter__c(NAP_Page_Builder__c=detailMenu3.id,
                                                                Attribute_Condition__c = 'AND',
                                                                Publish_Status__c = 'Live',
                                                                Attribute_Filter__c = 'News');
        newFilterList.add(newFilter1);
        NAP_News_Filter__c newFilter2 = new NAP_News_Filter__c(NAP_Page_Builder__c=detailMenu5.id,
                                                                Attribute_Condition__c = 'AND',
                                                                Publish_Status__c = 'Live',
                                                                Attribute_Filter__c = 'Event');
        newFilterList.add(newFilter2);
        NAP_News_Filter__c newFilter3 = new NAP_News_Filter__c(NAP_Page_Builder__c=detailMenu6.id,
                                                                Attribute_Condition__c = 'AND',
                                                                Publish_Status__c = 'Live',
                                                                Attribute_Filter__c = 'OTP');
        newFilterList.add(newFilter3);
        insert newFilterList;

        relations.add(createPageBuilderJoin(menuItems[0].Id, subMenu1.Id, 1));
        relations.add(createPageBuilderJoin(menuItems[0].Id, subMenu2.Id, 2));
        relations.add(createPageBuilderJoin(subMenu1.Id, detailMenu1.Id, 1));
        relations.add(createPageBuilderJoin(subMenu1.Id, detailMenu2.Id, 2));
        relations.add(createPageBuilderJoin(subMenu1.Id, detailMenu3.Id, 3));
        relations.add(createPageBuilderJoin(subMenu1.Id, detailMenu4.Id, 4));
        relations.add(createPageBuilderJoin(subMenu1.Id, detailMenu5.Id, 5));
        relations.add(createPageBuilderJoin(subMenu1.Id, detailMenu5.Id, 6));
        relations.add(createPageBuilderJoin(subMenu1.Id, detailMenu5.Id, 7));

        insert relations;

        insert accesses;

        ContentVersion cvEarliest = SObjectRepository.getContentVersion();
        Id cId = cvEarliest.Id;
    

        List<NAP_File_Filter__c> filters = new List<NAP_File_Filter__c>();

        filters.add(new NAP_File_Filter__c(Tag_Filter_Long__c='2015, 2016', Tag_Condition__c = 'AND', Tag_to_Attribute_Condition__c = 'AND', Attribute_Filters__c = 'Tier', Attribute_Condition__c = 'AND', NAP_Page_Builder__c=detailMenu1.Id, File_Display_Type__c='Tiles'));

        filters.add(new NAP_File_Filter__c(Tag_Filter_Long__c='2015, 2016', Tag_Condition__c = 'AND', Tag_to_Attribute_Condition__c = 'AND', Attribute_Filters__c = 'Partner Account', Attribute_Condition__c = 'AND', NAP_Page_Builder__c=detailMenu2.Id, File_Display_Type__c='List'));

        filters.add(new NAP_File_Filter__c(Tag_Filter_Long__c='2017, 2016', Tag_Condition__c = 'OR' , NAP_Page_Builder__c=subMenu2.Id, File_Display_Type__c='List'));

        filters.add(new NAP_File_Filter__c(File_Resource_IDs__c=cId, Attribute_Condition__c = 'AND', NAP_Page_Builder__c=detailMenu3.Id, File_Display_Type__c='Icons'));

        insert filters;

        List<NAP_News_Item__c> newsItems = new List<NAP_News_Item__c>();

        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-30), Publish_Status__c='Live',Item_Type__c='News', News_Type__c='General', Title__c='NNI1', RAW_HTML__c='test'));
        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-80), Publish_Status__c='Live',Item_Type__c='Events', News_Type__c='General', Title__c='NNI2', RAW_HTML__c='test'));
        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-600), Publish_Status__c='Archive',Item_Type__c='News', News_Type__c='General', Title__c='NNI3',RAW_HTML__c='test'));
        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-400), Publish_Status__c='Live',Item_Type__c='News',Attribute__c='User Type', Attribute_Value__c='OTP', News_Type__c='Webinar', Title__c='NNI4',RAW_HTML__c='test'));


        insert newsItems;

        insert new NAP_News_Item_Link__c(NAP_News_Item__c=newsItems[0].Id, Link__c='https://google.com', Link_Display_Text__c='Google');


    }

    
    private static NAP_Page_Builder_Join__c createPageBuilderJoin(Id parentId, Id childId, Integer pComponentOrder)
    {
        NAP_Page_Builder_Join__c newPageBuilderJoin = new NAP_Page_Builder_Join__c();
        newPageBuilderJoin.NAP_Page_Builder_Parent__c = parentId;
        newPageBuilderJoin.NAP_Page_Builder_Child__c = childId;
        newPageBuilderJoin.Order__c = pComponentOrder;
        return newPageBuilderJoin;
    }

    private static NAP_Page_Security__c createNAPSecurity(Id pageBuilder)
    {
        NAP_Page_Security__c newPageSecurity = new NAP_Page_Security__c();
        newPageSecurity.NAP_Page_Builder__c = pageBuilder;
        newPageSecurity.Security_Type_Id__c = String.valueOf(SObjectRepository.getProfileId('Partner Community Admin')).substring(0,15);
        newPageSecurity.Type__c = 'Profile';
        return newPageSecurity;
    }

    private static void insertContentFiles()
    {
        RecordType ContentRT = [select Id FROM RecordType WHERE Name='PRM'];
        ContentVersion testContent = new ContentVersion(); 
        testContent.RecordTypeId = ContentRT.Id;
        testContent.TagCsv = '2015, 2016';
        testContent.Tag__c='2015, 2016';
        testContent.Title= 'testycontent';
        testContent.Language__c = 'Korean';
        testContent.PathOnClient = 'testy';
        testContent.VersionData = blob.valueof('testng');
        //testContent.ContentURL = 'https://www.akamai.com/us/en/multimedia/documents/technical-publication/pushing-cdn-isp-collaboration-to-the-limit-technical-publication.pdf';
        ContentVersion testContent2 = new ContentVersion(); 
        testContent2.RecordTypeId = ContentRT.Id;
        testContent2.TagCsv = '2016, 2017';
        testContent2.Tag__c='2015, 2014';
        testContent2.Title= 'testycontent';
        testContent2.Language__c = 'Korean';
        testContent2.PathOnClient = 'testy';
        testContent2.VersionData = blob.valueof('testng');
        List<ContentVersion> cvList = new List<ContentVersion>();
        cvList.add(testContent);
        cvList.add(testContent2);

        insert cvList;
        testContent = [select id, ContentDocumentId from ContentVersion where id=:testContent.Id];

        testContent2 = [select id, ContentDocumentId from ContentVersion where id=:testContent2.Id];

        ContentWorkspace partnerWorkspace = [SELECT Id FROM ContentWorkspace WHERE Name='Partner Facing Documents - SHARE'];
        System.assert(partnerWorkspace.Id!=null);
        
        ContentWorkspaceDoc newWorkspaceDoc =new ContentWorkspaceDoc(); 
        newWorkspaceDoc.ContentWorkspaceId =partnerWorkspace.Id; 
        newWorkspaceDoc.ContentDocumentId = testContent.ContentDocumentId; 
        insert newWorkspaceDoc;

        ContentWorkspaceDoc newWorkspaceDoc2 =new ContentWorkspaceDoc(); 
        newWorkspaceDoc2.ContentWorkspaceId =partnerWorkspace.Id; 
        newWorkspaceDoc2.ContentDocumentId = testContent2.ContentDocumentId; 
        insert newWorkspaceDoc2;
    }

    static testmethod void testAddAttributeController()
    {

        ContentVersion testContent = (ContentVersion)SobjectRepository.get(ContentVersion.sObjectType);
        Test.setCurrentPage(Page.AddContentVersionAttributes);
        ApexPages.currentPage().getParameters().put('ContentVersionId',testContent.Id);

        AddContentVersionAttributeController controller = new AddContentVersionAttributeController();

        controller.getAttributes();
        controller.addNewAttribute();

        controller.newAttr.Attribute_Name__c='Tier';
        controller.newAttr.Attribute_Value__c='Gold';
        controller.saveAttribute();

        ApexPages.currentPage().getParameters().put('attr_id',controller.getAttributes()[0].Id);

        controller.editAttribute();

        controller.cancelCreation();
        ApexPages.currentPage().getParameters().put('attr_id',controller.getAttributes()[0].Id);
        controller.deleteAttribute();

        controller.addNewAttribute();

        Account partnerAccount = SobjectRepository.getPartnerAccount();

        controller.newAttr.Attribute_Name__c='Partner Account';
        controller.newAttr.Partner_Account__c=partnerAccount.Id;
        controller.saveAttribute();

        controller.addNewAttribute();

        controller.newAttr.Attribute_Name__c='Tier';
        controller.newAttr.Attribute_Value__c='Gold';
        controller.saveAttribute();

        User partnerUser = SobjectRepository.getPartnerUser();

        System.assert(partnerUser.ContactId!=null, 'Partner Contact Id is null');
        System.assert(partnerUser.UserRoleId!=null, 'Partner Role Id is null');
        //System.assert(partnerUser.Contact.Partner_User__c!=null, 'Partner User field is not populate on contact');
        NAP_Page_Builder__c currentMainMenu0 = [select id, name from NAP_Page_Builder__c where Component_Type__c='Main Menu' order by Component_Order__c asc limit 1];


        System.assert(currentMainMenu0.Name!=null, 'No Current Main Menu');
        Test.startTest();
        ContentVersion cv;
        System.runAs(dmlUser)
		{
            cv = L2Q_ContentDocumentUtilClass.setContentVersion('S', 'Title', 'Title', 'Test Data');
            insert cv;
            ContentVersion cvI = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cv.Id];
            String partnerSharingLibraryId = NAPSettings.getValue('LibrariesAvailableForPartnerFileDownload');
            List<String> listOfAvailableLibraries = partnerSharingLibraryId.split(',');

            ContentWorkspaceDoc doc = L2Q_ContentDocumentUtilClass.setContentWorkspaceDoc(Id.valueOf(listOfAvailableLibraries.get(0)), cvI.ContentDocumentId);
            //insert doc;
        }
        testContent = (ContentVersion)SobjectRepository.getContentVersion();
        System.runAs(partnerUser)
        {
            

            System.assert(testContent.Id!=null, 'Content file is not accessible to partner');

            NAP_Page_Builder__c currentMainMenu = [select id, name from NAP_Page_Builder__c where Component_Type__c='Main Menu' order by Component_Order__c asc limit 1];


            System.assert(currentMainMenu.Name!=null, 'No Current Main Menu');

            List<NAP_Page_Builder_Join__c> ll = [select NAP_Page_Builder_Parent__r.Name from NAP_Page_Builder_Join__c where NAP_Page_Builder_Child__c=:currentMainMenu.Id];
            
            System.assert(ll[0].NAP_Page_Builder_Parent__r.Name!='NP1', 'Page menu is not the parent. THis is:'+ll[0].NAP_Page_Builder_Parent__r.Name);

            PageReference pageRef = Page.NAPLandingPage;
            Test.setCurrentPageReference(pageRef);
            NAPLandingPageController testController = new NAPLandingPageController();
            testController.getMenuItems();
            testController.getPermanentMenuItems();
            testController.getCarouselItems();
            testController.getBillBoardText();

            pageRef = Page.NAP;
            Test.setCurrentPageReference(pageRef);
            System.currentPageReference().getParameters().put('page_id', currentMainMenu0.Name);
            NAPRebrandedPageController tController = new NAPRebrandedPageController();
            tController.sendErrorMail();
            //NAPRebrandedPageController.search('Test');
            //subscribe to file 
            NAPRebrandedPageController.saveFileSubscriptionDetails(testContent.ContentDocumentId,true);
            //Test related to News subscription
            NAPRebrandedPageController.getNewsSettings();
            List<String> types = new List<String>();
            types.add('Product');
            // TODO - replace with the new method signature
            //NAPRebrandedPageController.saveNewsSubscriptionDetails('Daily', types, true, false, false);
            

            List<String> event = new List<String>();
            types.add('Event1');
            types.add('Event2');
            NAP_News_Subscription__c subsciption = new NAP_News_Subscription__c(Partner_User__c = partnerUser.id,
	    																		Enable_Disable__c = true,
	    																		Frequency__c = 'Weekly',
	    																		Type__c = 'Webinar');
	        insert subsciption;
            NAPRebrandedPageController.saveNewsSubscriptionDetails('Daily', types, event, true, false, false);
            NAPRebrandedPageController.NewsSubscriptionWrapper nw = NAPRebrandedPageController.getNewsSettingsObject('value');
            System.currentPageReference().getParameters().put('page_id', 'random_id');
            tController = new NAPRebrandedPageController();


            //System.assert(CurrentUser.hasFileAccess(testContent.Id), true);
            
            Boolean check = CurrentUser.hasFileAccess(cv.Id);
            // error mail
            // set libsub
            NAPUtilClass.getFileSize(2000);
            NAPUtilClass.getFileSize(2000000);
            NAPUtilClass.getFileSize(2000000000);
            //NAPUtilClass.getLatestVersion(testContent.Id);


            //Check individual news item scenario
            List<NAP_News_Item__c> newsList = [Select id,Name from NAP_News_Item__c limit 1];
            if (newsList.size() > 0) {
                NAP_News_Item__c news = newsList[0];

                PageReference pageRef2 = Page.NAPLandingPage;
                Test.setCurrentPageReference(pageRef2);
                NAPLandingPageController testController2 = new NAPLandingPageController();
                testController2.getMenuItems();
                testController2.getPermanentMenuItems();
                testController2.getCarouselItems();
                testController2.getBillBoardText();
                NAPNews.containsOTPPermissionSet(UserInfo.getUserId());

                pageRef2 = Page.NAP;
                Test.setCurrentPageReference(pageRef2);
                System.currentPageReference().getParameters().put('page_id', currentMainMenu0.Name);
                System.currentPageReference().getParameters().put('news_id', news.Name);
                NAPRebrandedPageController tController2 = new NAPRebrandedPageController();
            }

        }

        NAPRebrandedPageController.setLibrarySubscriptionDetails(false);

        Test.stopTest();
   }

	public static testmethod void testNAPSubscriptionBatchCronRun()
	{
		RecordType ContentRT = [select Id FROM RecordType WHERE Name='PRM'];

		Cron_Batch_Job__c testBatchJob = utilTestClass.createCronBatchJob('NAP File Subscription Digest','NAP File Subscription Digest');
		insert testBatchJob;
		Cron_Batch_Run__c testBatchRun = utilTestClass.createCronBatchRun(testBatchJob.Id);
		testBatchRun.Completed__c = System.now();
		testBatchRun.Result__c = 'Success';
		insert testBatchRun;

		System.runAs(dmlUser)
		{
			ContentVersion testCV1 =new ContentVersion(); 
			testCV1.ContentURL='http://www.google.com/'; 
			testCV1.Title ='Google.com';
			testCV1.RecordTypeId = ContentRT.Id;
			insert testCV1;

			ContentVersion testCV2 =new ContentVersion(); 
            testCV2.VersionData = blob.valueof('testing');
            testCV2.PathOnClient = '/Users/eric/file2.txt';
			testCV2.Title ='Yahoo.com';
			testCV2.RecordTypeId = ContentRT.Id;
			insert testCV2;

			ContentWorkspace partnerWorkspace = [SELECT Id FROM ContentWorkspace WHERE Name='Partner Facing Documents - SHARE'];
		    System.assert(partnerWorkspace.Id!=null);

		    ContentVersion testContent = [select id, ContentDocumentId from ContentVersion where id=:testCV1.Id];
		    
		    ContentWorkspaceDoc newWorkspaceDoc =new ContentWorkspaceDoc(); 
		    newWorkspaceDoc.ContentWorkspaceId =partnerWorkspace.Id; 
		    newWorkspaceDoc.ContentDocumentId = testContent.ContentDocumentId; 
		    insert newWorkspaceDoc;

		    testContent = [select id, ContentDocumentId from ContentVersion where id=:testCV2.Id];

		    newWorkspaceDoc =new ContentWorkspaceDoc(); 
		    newWorkspaceDoc.ContentWorkspaceId =partnerWorkspace.Id; 
		    newWorkspaceDoc.ContentDocumentId = testContent.ContentDocumentId; 
		    insert newWorkspaceDoc;


            Contact partnerContact = SobjectRepository.getPartnerContact();
			partnerContact.Subscribed_to_Library__c = true;

			update partnerContact;


			Document napLogo = new Document();
			napLogo.Name = 'Generic Netalliance Logo';
			napLogo.FolderId = UserInfo.getUserId();  
			insert napLogo;
            User partnerUser = SobjectRepository.getPartnerUser();
            
            //System.assert(partnerUser.Contact.AccountId!=null, 'partner user doesnt have contact:'+partnerUser.Contact.AccountId);

			// ContentVersionAttribute__c cvAttr = new ContentVersionAttribute__c();
			// cvAttr.ContentVersionId__c = testCV2.Id;
			// cvAttr.Attribute_Name__c = 'Partner Account';
			// cvAttr.Attribute_Value__c = 'Sales';
			// cvAttr.Partner_Account__c = partnerUser.Contact.AccountId;
			// insert cvAttr;

			Test.startTest();

			CronJobTypes.insertBatchJobAndRun('NAP File Subscription Digest');
			NAPFileSubscriptionDigestBatchClass batchInstance = new NAPFileSubscriptionDigestBatchClass();
			Database.executeBatch(batchInstance);
            testCV2.VersionData = blob.valueof('tfdating');
            update testCV2;

            testCV2 = [select id, contentDocumentId from ContentVersion where id=:testCV2.Id];


			ContentVersion testCV3 =new ContentVersion(); 
			testCV3.Title ='Google.com';
            testCV3.VersionData = blob.valueof('fdajkd');
			testCV3.RecordTypeId = ContentRT.Id;
            testCV3.PathOnClient ='/users/eric/f.rxt';
            testCV3.ContentDocumentId=testCV2.ContentDocumentId;
			insert testCV3;



			Test.stopTest();
		}
	}

    public static testmethod void testScenarioForOTNews() 
    {
    	
    	System.runAs(dmlUser)
        {
            Account partnerAccount = SobjectRepository.getPartnerAccount();
            partnerAccount.NAP_Area__c='OTP';
            update partnerAccount;
            User partnerUser = SobjectRepository.getPartnerUser();
            //System.assert(partnerUser.Contact.AccountId!=null, 'partner user doesnt have contact:'+partnerUser.Contact.AccountId);

	        //Create subscription record
	        NAP_News_Subscription__c subsciption = new NAP_News_Subscription__c(Partner_User__c = partnerUser.id,
	    																		Enable_Disable__c = true,
	    																		Frequency__c = 'Weekly',
	    																		Type__c = 'Webinar');
	        insert subsciption;

	        List<PermissionSet> psList = [select Id from PermissionSet where Name = 'OTP'];

	        if (psList != null && psList.size() > 0) {
	        	PermissionSet ps = psList[0];
		        PermissionSetAssignment psa = new PermissionSetAssignment();
		        psa.AssigneeId = partnerUser.Id;
		        psa.PermissionSetId = ps.id;
		        insert psa;
	        }

	        Document napLogo = new Document();
			napLogo.Name = 'Generic Netalliance Logo';
			napLogo.FolderId = UserInfo.getUserId();  
			insert napLogo;

	    	//Create NAP news
	        List<NAP_News_Item__c> newsItems = new List<NAP_News_Item__c>();

            newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-30), Publish_Status__c='Live',Item_Type__c='News', News_Type__c='General', Title__c='NNI1', RAW_HTML__c='test'));
        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-80), Publish_Status__c='Live',Item_Type__c='Events', News_Type__c='General', Title__c='NNI2', RAW_HTML__c='test'));
        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-600), Publish_Status__c='Archive',Item_Type__c='News', News_Type__c='General', Title__c='NNI3',RAW_HTML__c='test'));
        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-400), Publish_Status__c='Live',Item_Type__c='News',Attribute__c='User Type', Attribute_Value__c='OTP', News_Type__c='Webinar', Title__c='NNI4',RAW_HTML__c='test'));


	        insert newsItems;

	        insert new NAP_News_Item_Link__c(NAP_News_Item__c=newsItems[0].Id, Link__c='https://google.com', Link_Display_Text__c='Google');

	        Test.startTest();
	        NAPNewsSubscriptionBatchClass job = new NAPNewsSubscriptionBatchClass('Weekly');
	        Database.executeBatch(job);
	        Test.stopTest();
	    }
    }

    public static testmethod void testNonOTScenarioWeekly() {
    	
    	System.runAs(dmlUser)
        {

            User partnerUser = SobjectRepository.getPartnerUser();
            //System.assert(partnerUser.Contact.AccountId!=null, 'partner user doesnt have contact:'+partnerUser.Contact.AccountId);

	        //Create subscription record
	        NAP_News_Subscription__c subsciption = new NAP_News_Subscription__c(Partner_User__c = partnerUser.id,
	    																		Enable_Disable__c = true,
	    																		Frequency__c = 'Weekly',
	    																		Type__c = 'Webinar');
	        insert subsciption;

	        Document napLogo = new Document();
			napLogo.Name = 'Generic Netalliance Logo';
			napLogo.FolderId = UserInfo.getUserId();  
			insert napLogo;

	    	//Create NAP news
	        List<NAP_News_Item__c> newsItems = new List<NAP_News_Item__c>();

	        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-30), Publish_Status__c='Live', Item_Type__c='News', News_Type__c='Product', Title__c='NNI1', RAW_HTML__c='test'));
	        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-80), Publish_Status__c='Live', Item_Type__c='News', News_Type__c='Product', Title__c='NNI2', RAW_HTML__c='test'));
	        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-600), Publish_Status__c='Archive', Item_Type__c='News', News_Type__c='Product', Title__c='NNI3',RAW_HTML__c='test'));
	        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-400), Publish_Status__c='Archive', Item_Type__c='News', News_Type__c='Webinar', Title__c='NNI4',RAW_HTML__c='test'));

	        insert newsItems;

	        insert new NAP_News_Item_Link__c(NAP_News_Item__c=newsItems[0].Id, Link__c='https://google.com', Link_Display_Text__c='Google');

	        Test.startTest();
	        NAPNewsSubscriptionBatchClass job = new NAPNewsSubscriptionBatchClass('Weekly');
	        Database.executeBatch(job);
	        Test.stopTest();
	    }
    }

    public static testmethod void testNonOTScenarioDaily() {
    	
    	System.runAs(dmlUser)
        {
            User partnerUser = SobjectRepository.getPartnerUser();
            //System.assert(partnerUser.Contact.AccountId!=null, 'partner user doesnt have contact:'+partnerUser.Contact.AccountId);


	        //Create subscription record
	        NAP_News_Subscription__c subsciption = new NAP_News_Subscription__c(Partner_User__c = partnerUser.id,
	    																		Enable_Disable__c = true,
	    																		Frequency__c = 'Daily',
	    																		Type__c = 'Webinar');
	        insert subsciption;

	        Document napLogo = new Document();
			napLogo.Name = 'Generic Netalliance Logo';
			napLogo.FolderId = UserInfo.getUserId();  
			insert napLogo;

	    	//Create NAP news
	        List<NAP_News_Item__c> newsItems = new List<NAP_News_Item__c>();

	        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-30), Publish_Status__c='Live', Item_Type__c='News', News_Type__c='Product', Title__c='NNI1', RAW_HTML__c='test'));
	        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-80), Publish_Status__c='Live', Item_Type__c='News', News_Type__c='Product', Title__c='NNI2', RAW_HTML__c='test'));
	        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-600), Publish_Status__c='Archive', Item_Type__c='News', News_Type__c='Product', Title__c='NNI3',RAW_HTML__c='test'));
	        newsItems.add(new NAP_News_Item__c(Published_On__c=Date.today().addDays(-400), Publish_Status__c='Archive', Item_Type__c='News', News_Type__c='Webinar', Title__c='NNI4',RAW_HTML__c='test'));

	        insert newsItems;

	        insert new NAP_News_Item_Link__c(NAP_News_Item__c=newsItems[0].Id, Link__c='https://google.com', Link_Display_Text__c='Google');

	        Test.startTest();
	        NAPNewsSubscriptionBatchClass job = new NAPNewsSubscriptionBatchClass('Daily');
	        Database.executeBatch(job);
	        Test.stopTest();
	    }
    }

	static testMethod void testNAPFileSubscribe()
    {
        System.runAs(dmlUser)
        {
            ContentVersion cv = new ContentVersion(title='foo', contentUrl='http:///www.foor.bar');
    		insert cv;
            ContentVersion cvRes = [select id, ContentDocument.id, ContentDocument.title 
                                    from ContentVersion where id= :cv.id];
            ContentDocument cd = cv.ContentDocument;
            
            NAP_File_Subscribe__c fileSubscribeRecord = new NAP_File_Subscribe__c(Active_subscription__c  = true,
                                                                                 Content_Document_Id__c = cvRes.id,
                                                                                 Subscription_Date__c = System.now(),
                                                                                 User__c  = UserInfo.getUserId());
            insert fileSubscribeRecord;
            
            ContentVersionAttribute__c  cva = new ContentVersionAttribute__c(Attribute_Name__c  = 'Tier',
                                                                             Attribute_Value__c = 'Gold',
                                                                            ContentVersionId__c = cvRes.id);
            insert cva;
            
            List<NAP_File_Subscribe__c> fileSubscribeAfterAttributes = [Select id from NAP_File_Subscribe__c where Content_Document_Id__c =:cvRes.ContentDocument.id];
            System.assertEquals(fileSubscribeAfterAttributes.size(), 0);
        }   
    }

    static testMethod void testContentVersionAttributes()
    {
        System.runAs(dmlUser)
        {
            ContentVersion cv = new ContentVersion(title='foo', contentUrl='http:///www.foor.bar');
            insert cv;
            ContentVersion cvRes = [select id, ContentDocument.id, ContentDocument.title 
                                    from ContentVersion where id= :cv.id];
            ContentDocument cd = cv.ContentDocument;

            ContentVersionAttribute__c  cva = new ContentVersionAttribute__c(Attribute_Name__c  = 'Tier',
                                                                             Attribute_Value__c = 'Gold',
                                                                            ContentVersionId__c = cvRes.id);
            insert cva;

            PageReference pageRef = Page.AddContentVersionAttributes;
            Test.setCurrentPage(pageRef);

            pageRef.getParameters().put('ContentVersionId', cvRes.id);

            AddContentVersionAttributeController controller = new AddContentVersionAttributeController();

            List<ContentVersionAttribute__c> cvaList = controller.getAttributes();
            System.assertEquals(cvaList.size(),1);

            ApexPages.currentPage().getParameters().put('attr_id', cva.id);
            controller.editAttribute();

            controller.addNewAttribute();
            
            ContentVersionAttribute__c cvaNew = controller.newAttr;
            cvaNew.Attribute_Name__c  = 'Tier';
            cvaNew.Attribute_Value__c = 'NAP1';
            cvaNew.ContentVersionId__c = cvRes.id;

            //ApexPages.currentPage().getParameters().put('newAttr', cvaNew);
            controller.saveAttribute();

            System.assertEquals(controller.getAttributes().size(),2);

            ApexPages.currentPage().getParameters().put('attr_id', cva.id);
            controller.deleteAttribute();

            System.assertEquals(controller.getAttributes().size(),1);
            
            controller.cancelCreation();
        }   
    }

    private static ContentVersion refreshFile(Id cvId)
    {
        return [select id, tagcsv, tag__c from ContentVersion where Id=:cvId];
    }

    private static List<ContentVersion> refreshFiles(String titleLike)
    {
        return [select id, tagcsv, tag__c from ContentVersion where Title like :titleLike+'%' order by CreatedDate];
    }
    
    static testMethod void updatecvTagOnInsertAndUpdateTest()
    {
        System.runAs(dmlUser)
        {
            List<ContentVersion> tFiles = new List<ContentVersion>();
            // changing number to 1 because updateAttributes method is not bulkified
            Integer numberOfTestFiles = 2;

            for(integer i=0;i<numberOfTestFiles;i++)
            {
                ContentVersion TestRec = new ContentVersion();
                TestRec.Title = '__TSTREC'+i;
                TestRec.ContentUrl = 'www.test.com';
                TestRec.TagCsv = '2015t'+i;
                tFiles.add(TestRec);
            }


            insert tFiles;

            tFiles = refreshFiles('__TSTREC');
            for(integer i=0;i<numberOfTestFiles;i++)
            {
                system.assertEquals(tFiles[i].Tag__c  ,'2015t'+i);
                tFiles[i].TagCsv = '2016t'+i;
            }

            Test.startTest();
            update tFiles;

            tFiles = refreshFiles('__TSTREC');
            for(integer i=0;i<numberOfTestFiles;i++)
            {
                system.assertEquals(tFiles[i].Tag__c  ,'2016t'+i);
                tFiles[i].TagCsv = '';
            }
            update tFiles;

            tFiles = refreshFiles('__TSTREC');
            for(integer i=0;i<numberOfTestFiles;i++)
            {
                system.assertNotEquals(tFiles[i].Tag__c  ,'');
            }
            // run the bath job and refresh and see
            ContentVersionTagCopyBatchClass cvbc = new ContentVersionTagCopyBatchClass();
            Database.executeBatch(cvbc);
            Test.stopTest();
            tFiles = refreshFiles('__TSTREC');
            for(integer i=0;i<numberOfTestFiles;i++)
            {
                system.assert(String.isBlank(tFiles[i].Tag__c));
            }

        }   
    }
     static testmethod void testContentDownLoadBlocker()
     {
         Test.startTest();
         List<Id> cIDList = new List<Id>();
         User partnerUser = SobjectRepository.getPartnerUser();

        //  System.runAs(partnerUser)
        //  {
             List<ContentVersion> files = [Select Id,ContentDocumentId,IsLatest From ContentVersion Where IsLatest =true];
             cIDList.add(files[0].Id);

             ContentDownloadBlocker cb = new ContentDownloadBlocker();
             Sfc.ContentDownloadContext c;
             Sfc.ContentDownloadHandler ch= new Sfc.ContentDownloadHandler();
             ch = cb.getContentDownloadHandler(cIDList,c);
             System.runAs(partnerUser) {
                ch = cb.getContentDownloadHandler(cIDList,c);
                cIDList.add(files[1].Id);
                ch = cb.getContentDownloadHandler(cIDList,c);
             }
             Sfc.ContentDownloadHandler ch1= new Sfc.ContentDownloadHandler();
             ch1 = cb.hasAccess();
             cb.insufficientDownloadAccess();

        //  }

         Test.stopTest();
     }

    static testmethod void testNAPVideoPlayer()
    {
        Test.startTest();
        User partnerUser = SobjectRepository.getPartnerUser();
        // System.runAs(partnerUser)
        // {
            Test.setCurrentPage(Page.NAPVideoPlayer);
            List<ContentVersion> files = [Select Id,ContentDocumentId,IsLatest From ContentVersion Where IsLatest =true];
            ApexPages.currentPage().getParameters().put('id',files[0].Id);
            NAPVideoPlayerController nvp = new NAPVideoPlayerController();
            System.assert(nvp.errorMessage==null, 'There was an error while displaying videos');

            ApexPages.currentPage().getParameters().put('id','invalidid');
            NAPVideoPlayerController nvp2 = new NAPVideoPlayerController();
            System.assert(nvp2.errorMessage!=null, 'Error display isnt working');

            NAP_Video__c nv = new NAP_Video__c(Video_Title__c='testingtitle', Video_URL__c='/testing/a.m3u8');
            insert nv;

            nv = [select id from NAP_Video__c limit 1];

            ApexPages.currentPage().getParameters().put('id', nv.Id);
            NAPVideoPlayerController nvp3 = new NAPVideoPlayerController();

            AkamaiEdgeAuthTokenGenerator.generateToken('/urlpath/abc.m3u8', 86400);

            TrainingVideoPlayerController tvp = new TrainingVideoPlayerController();

        // }

        Test.stopTest();
    }

    static testmethod void testPartnerLoginController()
    {
        System.runAs(dmlUser) 
        {
            PageReference pageRef = Page.PartnerLogin;
            Test.setCurrentPageReference(pageRef);
            ApexPages.currentPage().getParameters().put('startURL', '');
            PartnerLoginController.redirectToIdp();
        }
    }

    public static testmethod void PartnerAccessController()
    {
        Test.startTest();
        User partner = SobjectRepository.getPartnerUser();
        Contact partnerContact;
        System.runAs(dmlUser)
        {
            partner.Has_MDF_Access__c = true;
            partner.Has_DealRegistration_Access__c = true;
            partner.Has_View_Trial_Access__c=true;
            partner.Has_Start_Trial_Access__c=true;
            update partner; 
            partner=[select id,contactid,Has_Partner_Lead_View_Access__c,Has_View_Trial_Access__c, Has_Start_Trial_Access__c,View_Pricing_Details__c,Has_Partner_Lead_Access__c,Has_MDF_Access__c,Has_DealRegistration_Access__c,Has_PartnerCertification_Access__c,Has_PartnerPlans_Access__c,Can_Accept_POA__c, Has_view_content_in_portals__c, ProfileId, Profile.Name,Has_Partner_Concierge_Access__c from User where id=:partner.id ][0];
            partnerContact = [Select id,Account.AKAM_Account_Id__c,Has_Akamai_University_Access__c from Contact where id=:partner.contactid];
            partnerContact.Has_Akamai_University_Access__c=true;
            PageReference pageRef = Page.DefinePartnerAccess;
            Test.setCurrentPageReference(pageRef);
            ApexPages.currentPage().getParameters().put('id',partnerContact.id);
            PartnerAccessController pactroller  = new PartnerAccessController();
            pactroller.partnerCon = partnerContact;
            pactroller.hasAUAccess=false;
            pactroller.updateContact();
            PartnerAccessController.updateRemoveUserPermissionSet(partner,partnerContact);
            //PartnerUserController.enableDisablePOAAccess(partnerContact.Id, 'True', 'False');
            //PartnerUserController.enableDisablePOAAccess(partnerContact.Id, 'False', 'True');
            partner.Has_MDF_Access__c =false;
            partner.Has_DealRegistration_Access__c =false;
            PartnerAccessController.populateProfile(partner);
            PartnerAccessController.isLiteLicenseSufficient(partner);
            //Test.setCurrentPageReference(Page.LunaAPIConnection);
            //LunaAPIConnectionController tController = new LunaAPIConnectionController();
        }

        System.runAs(partner)
        {
            PartnerAccessController pac = new PartnerAccessController();
            pac.partnerUser =partner;
            pac.partnerCon = partnerContact;
            pac.getBUOptions();
            pac.getBUOptionsProfile();
            pac.exceptionCheck();
            pac.updateAccess();
            pac.updateContact();
            pac.edit();
            pac.cancel();
            pac.setProfiles();
            pac.BUOpt='fdsa';
            pac.BUOptProfile='fds';

        }
        Test.stopTest();

    }
    
    public static testmethod void LoginRedirectController() {
        System.runAs(utilTestClass.getTestRunUser()) {
           Test.setCurrentPageReference(Page.LoginRedirect);
           ContentVersion cvEarliest = SObjectRepository.getContentVersion();
           ApexPages.currentPage().getParameters().put('url', '/'+cvEarliest.id);
           LoginRedirectController fruc = new LoginRedirectController();
    
           fruc.RedirectPage();
       }
    }
}