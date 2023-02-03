/*---------------------------------------------------------------------------------
* Test Class Name      : SC_KCS_TestClass
* Developer Name       : Vamsee Surya
* Date                 : 25th May,2017
* JIRA                 : ESESP-550 
* Classes              : SC_KCSFlag_CreationCtrl, SC_KCSScorecard_CreationCtrl,SC_QualityCheckRelatedListController
* --------------------------------------------------------------------------------
* Modified by          
* Vandhana Krishnamurthy
* Vamsee S (ESESP-1773 : AKATEC Lightning Knowledge Migration)
* Pinkesh  (ESESP-1602 : AKATEC Lightning Knowledge Migration)
* Supreeth R (ESESP-1779: AKATEC Lightning Knowledge Migration)
* Vishnu (ESESP-2104: Akapedia Dashbaord, Accuracy Check - filter invalid cases)
* Pinkesh (ESESP-2316: Quality Coaching)
* Vishnu Sharma (ESESP-3106 : Quality Coaching)
---------------------------------------------------------------------------------*/ 
@isTest(seeAllData=false)
public class SC_KCS_TestClass 
{
    
    Static User techManager;
    Static User techAgent;
    Static KnowledgeArticleVersion ka; 
    
    @testSetup static void setupDataForAkapedia(){
        utilTestClass.createCustomSettings();  
    }
    
    static void createTestData(){
        techManager = [SELECT Id,KCS_Level__c FROM User WHERE Isactive = TRUE AND Profile.Name = 'Support - Tech Support Manager' LIMIT 1];
        techAgent = [SELECT Id,KCS_Level__c,SC_KCS_Coach__c,ManagerId,Manager.KCS_Level__c FROM User WHERE Isactive = TRUE AND Profile.Name = 'Support - Tech Support Agent' AND ManagerId != Null AND Manager.Profile.Name = 'Support - Tech Support Manager' LIMIT 1];
        
        User sysAdmin = [SELECT Id FROM User WHERE Isactive = TRUE AND Profile.Name = 'System Administrator' LIMIT 1];
        
        List<User> usrList = new List<User>();
        List<SC_KCS_Flag__c> flagList = new List<SC_KCS_Flag__c>();
        List<SC_KCS_Scorecard__c> scorecardList = new List<SC_KCS_Scorecard__c>();
        
        List<KnowledgeArticleVersion> kaVersionList;
        List<KnowledgeArticleVersion> kavPublish = new List<KnowledgeArticleVersion>();
        ka = new KnowledgeArticleVersion();
        
        Account acc = utilTestClass.CreateAccount('Account1');
            insert acc;
            Id techRecTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical').getRecordTypeId();
            
            List<Case> techCaseL = new List<Case>();
            Case techCase = new Case();
            techCase.RecordTypeId = techRecTypeId;
            techCase.AccountId = acc.Id;
            techCase.Origin = 'Email';
            techCase.Sub_Type__c = 'Product Support';
            techCase.Work_Type__c = 'Reactive';
            techCase.Has_Article_Linked__c = true;//ESESP-781
            techCase.Accuracy_Check_Created_Date__c = system.now();//ESESP-781
            techCase.Accurate_Attach__c = 'Yes';//ESESP-781
            techCaseL.add(techCase);
            
            techCase = new Case();
            techCase.RecordTypeId = techRecTypeId;
            techCase.AccountId = acc.Id;
            techCase.Origin = 'Email';
            techCase.Sub_Type__c = 'Product Support';
            techCase.Work_Type__c = 'Reactive';
            techCaseL.add(techCase);
            
            insert techCaseL;
            
            techCaseL[0].Status = 'Closed';
            techCaseL[0].Validation_Override__c = true;
            techCaseL[1].Status = 'Closed';
            techCaseL[1].Validation_Override__c = true;
            update techCaseL;
        
        System.runAs(sysAdmin)
        {
            techManager.KCS_Level__c = 'KCS Coach';
            usrList.add(techManager);
            techAgent.SC_KCS_Coach__c = techManager.Id;
            techAgent.KCS_Level__c = 'Level I';
            usrList.add(techAgent);
            update usrList;
        }
        
        System.runAs(techAgent)
        {
            List<sObject> soList = new List<sObject>();
            List<Id> articleRecordTypeId = new List<Id>();
            
            for(Integer i=0;i<6;i++)
            {
                if(Math.mod(i,2) == 0)
                {
                    //Knowledge__kav qaKAV = new Knowledge__kav(Title='Q&A kav'+i,Summary='Q&A summary'+i,Question_Answer_Question__c ='Test Question'+i,Question_Answer_Answer__c='Test Answer',UrlName='TestQ'+i);
                    //soList.add(qaKAV);
                }   
                else
                {
                    Knowledge__kav htKAV = new Knowledge__kav(Title='Random Unique Title12121'+i,Summary='How To summary'+i,UrlName='RandomUniqueTitle12121'+i);
                    soList.add(htKAV);
                }    
            }
            insert soList;
            
            kaVersionList = [Select Id,KnowledgeArticleId,Title,ArticleNumber,OwnerId,VersionNumber from KnowledgeArticleVersion where Language='en_US' AND PublishStatus = 'Draft'];
            
            for(KnowledgeArticleVersion kavEach : kaVersionList)
            {
                KbManagement.PublishingService.publishArticle(kavEach.KnowledgeArticleId,true);
            }   
            
            kavPublish = [Select Id,KnowledgeArticleId,Title,ArticleNumber,OwnerId,VersionNumber from KnowledgeArticleVersion where Language='en_US' AND PublishStatus = 'Online'];
            if(kavPublish.size() > 0)
            {
                for(KnowledgeArticleVersion kAV : kavPublish)
                {
                    SC_KCS_Flag__c flag = new SC_KCS_Flag__c();
                    flag.Status__c = 'Open';
                    flag.Knowledge__c = kAV.Id;
                    flagList.add(flag);
                    
                    SC_KCS_Scorecard__c scorecard = new SC_KCS_Scorecard__c();
                    scorecard.Knowledge__c= kAV.Id;
                    scorecard.Notes__c='abcd1234';
                    scorecardList.add(scorecard);
                    
                }
                insert flagList; 
                insert scorecardList;
                ka = kavPublish[0];
            } 
            
            
        }
    }
    
    /*public static testmethod void FlagTest(){
        //Create Knowledge Article
        Troubleshooting_Procedure__kav  procedureKAV = new Troubleshooting_Procedure__kav (Summary = 'Test Procedure 1',Title = 'Test Procedure 1',UrlName='TestProcedureOne',language= 'en_US');
        insert procedureKAV;
        
        //Publish the article
        KnowledgeArticleVersion kb = [SELECT Id, KnowledgeArticleId from KnowledgeArticleVersion where Language ='en_US' and Id =:procedureKAV.Id Limit 1];
        KbManagement.PublishingService.publishArticle(kb.KnowledgeArticleId, true);
        
        User techManager = [SELECT Id FROM User WHERE Isactive = TRUE AND Profile.Name = 'Support - Tech Support Manager' LIMIT 1];
        System.runAs(techManager){
        test.startTest();
        PageReference flagCreationPage = Page.SC_KCSFlag_CreationPage;
        Test.setCurrentPage(flagCreationPage);
        ApexPages.currentPage().getParameters().put('Id',kb.KnowledgeArticleId);
        SC_KCSFlag_CreationCtrl flagCreationClass = new SC_KCSFlag_CreationCtrl();
        flagCreationClass.CreateFlag();
        //Update Call
        flagCreationClass.CreateFlag();
        test.stopTest();
        
        }  
        }
        
        public static testmethod void ScorecardTest(){
        //Create Knowledge Article
        Troubleshooting_Procedure__kav  procedureKAV = new Troubleshooting_Procedure__kav (Summary = 'Test Procedure 2',Title = 'Test Procedure 2',UrlName='TestProcedureTwo',language= 'en_US');
        insert procedureKAV;
        
        //Publish the article
        KnowledgeArticleVersion kb = [SELECT Id, KnowledgeArticleId from KnowledgeArticleVersion where Language ='en_US' and Id =:procedureKAV.Id Limit 1];
        KbManagement.PublishingService.publishArticle(kb.KnowledgeArticleId, true);
        
        User techManager = [SELECT Id FROM User WHERE Isactive = TRUE AND Profile.Name = 'Support - Tech Support Manager' LIMIT 1];
        User techAgent = [SELECT Id FROM User WHERE Isactive = TRUE AND Profile.Name = 'Support - Tech Support Agent' LIMIT 1];
        Id scorecardId;
        test.startTest();
        System.runAs(techManager){
        PageReference scorecardCreationPage = Page.SC_KCSScorecard_CreationPage;
        Test.setCurrentPage(scorecardCreationPage);
        ApexPages.currentPage().getParameters().put('Id',kb.KnowledgeArticleId);
        SC_KCSScorecard_CreationCtrl scorecardCreationClass = new SC_KCSScorecard_CreationCtrl();
        scorecardCreationClass.CreateScorecard();
        
        //Update Scorecard
        scorecardCreationClass.CreateScorecard();
        
        PageReference scorecardEditPage = Page.SC_KCSScorecard_EditPage;
        Test.setCurrentPage(scorecardEditPage);
        ApexPages.Standardcontroller sc1 = new ApexPages.Standardcontroller(new SC_KCS_Scorecard__c());
        scorecardId = scorecardCreationClass.scorecardObject.Id;
        ApexPages.currentPage().getParameters().put('Id',scorecardId);
        SC_KCSScorecard_CreationCtrl scorecardEditClass = new SC_KCSScorecard_CreationCtrl(sc1);
        scorecardEditClass.UpdateScorecard();
        }
        
        System.runAs(techAgent){
        PageReference scorecardCreationPage2 = Page.SC_KCSScorecard_CreationPage;
        Test.setCurrentPage(scorecardCreationPage2);
        ApexPages.currentPage().getParameters().put('Id',kb.KnowledgeArticleId);
        SC_KCSScorecard_CreationCtrl scorecardCreationClass2 = new SC_KCSScorecard_CreationCtrl();
        
        PageReference scorecardEditPage2 = Page.SC_KCSScorecard_EditPage;
        Test.setCurrentPage(scorecardEditPage2);
        ApexPages.Standardcontroller sc2 = new ApexPages.Standardcontroller(new SC_KCS_Scorecard__c());
        ApexPages.currentPage().getParameters().put('Id',scorecardId);
        SC_KCSScorecard_CreationCtrl scorecardEditClass2 = new SC_KCSScorecard_CreationCtrl(sc2);
        }
        test.stopTest();
        }*/
            
    // test method for Akapedia Dashboard
    public static testmethod void akapediaTestMethod()
    {
        createTestData();
        System.runAs(techManager)
        {   
            /*PageReference scorecardCreationPage = Page.SC_KCSScorecard_CreationPage;
            Test.setCurrentPage(scorecardCreationPage);
            ApexPages.currentPage().getParameters().put('Id',ka.KnowledgeArticleId);
            SC_KCSScorecard_CreationCtrl scorecardCreationClass = new SC_KCSScorecard_CreationCtrl();
            scorecardCreationClass.CreateScorecard();*/
            
            List<SC_KCS_Coaching_Record__c> lCR = new List<SC_KCS_Coaching_Record__c>();
            SC_KCS_Coaching_Record__c cr1 = new SC_KCS_Coaching_Record__c(KCS_User__c=techAgent.Id);
            cr1.Coach_Session_Duration_Minutes__c =10; 
            cr1.Kudos__c = 'Test Kudos'; 
            cr1.Opportunities__c = 'Test Opp';
            lCR.add(cr1);
            SC_KCS_Coaching_Record__c cr2 = new SC_KCS_Coaching_Record__c(KCS_User__c=techAgent.Id);
            cr2.Coach_Session_Duration_Minutes__c =10; 
            cr2.Kudos__c = 'Test Kudos'; 
            cr2.Opportunities__c = 'Test Opp';
            lCR.add(cr2);
            insert lCR;
            
            Test.startTest();
            PageReference akapediaPage = Page.SC_Akapedia;
            Test.setCurrentPage(akapediaPage);
            SC_AkapediaController scAkapedia = new SC_AkapediaController();
            System.debug('Part Set : ' + scAkapedia.allPartcipantSet);
            scAkapedia.inputDate = 'Past 30 Days';
            scAkapedia.updateDateRange();
            scAkapedia.inputDate = 'Past 90 Days';
            scAkapedia.updateDateRange();
            scAkapedia.inputDate = 'Past 7 Days';
            scAkapedia.updateDateRange();
            scAkapedia.updateUserName();
            scAkapedia.sortColumnVal = 'KCSLevel';
            scAkapedia.sortTable();
            scAkapedia.sortColumnVal = 'useKBAR';
            scAkapedia.sortTable();
            
            Test.stopTest();
        }
    }
    
    public static testmethod void akapediaTestMethod2(){
        
        createTestData();
        System.runAs(techManager)
        {   
            /*PageReference scorecardCreationPage = Page.SC_KCSScorecard_CreationPage;
            Test.setCurrentPage(scorecardCreationPage);
            ApexPages.currentPage().getParameters().put('Id',ka.KnowledgeArticleId);
            SC_KCSScorecard_CreationCtrl scorecardCreationClass = new SC_KCSScorecard_CreationCtrl();
            scorecardCreationClass.CreateScorecard();*/
            
            List<SC_KCS_Coaching_Record__c> lCR = new List<SC_KCS_Coaching_Record__c>();
            SC_KCS_Coaching_Record__c cr1 = new SC_KCS_Coaching_Record__c(KCS_User__c=techAgent.Id);
            cr1.Coach_Session_Duration_Minutes__c =10; 
            cr1.Kudos__c = 'Test Kudos'; 
            cr1.Opportunities__c = 'Test Opp';
            lCR.add(cr1);
            SC_KCS_Coaching_Record__c cr2 = new SC_KCS_Coaching_Record__c(KCS_User__c=techAgent.Id);
            cr2.Coach_Session_Duration_Minutes__c =10; 
            cr2.Kudos__c = 'Test Kudos'; 
            cr2.Opportunities__c = 'Test Opp';
            lCR.add(cr2);
            insert lCR;
            List<KnowledgeArticleVersion> kaVersionList = [Select Id,KnowledgeArticleId,Title,ArticleNumber,OwnerId,VersionNumber from KnowledgeArticleVersion where Language='en_US'];
            Test.startTest();
            SC_QualityCheckRelatedListController.fetchRecords(kaVersionList[0].Id);
            PageReference akapediaPage = Page.SC_Akapedia;
            Test.setCurrentPage(akapediaPage);
            SC_AkapediaController scAkapedia = new SC_AkapediaController();
            System.debug('Part Set : ' + scAkapedia.allPartcipantSet);
            scAkapedia.inputDate = 'Past 30 Days';
            scAkapedia.updateDateRange();
            
            scAkapedia.dismissArticleId = ka.Id;
            scAkapedia.dismissArticle();
            SC_KCS_Flag__c oneFlag = [Select Id from SC_KCS_Flag__c where Status__c = 'Open' limit 1];
            scAkapedia.closeFlagId = oneFlag.Id;
            scAkapedia.dismissFlag(); 
            
            scAkapedia.sortArticles();
            scAkapedia.articleColumn = 'CreatedBy.Name';
            scAkapedia.sortArticles();
            scAkapedia.articleColumn = 'FirstPublishedDate';
            scAkapedia.sortArticles();
            
            scAkapedia.sortFlags();
            scAkapedia.flagColumn = 'CreatedBy.Name';
            scAkapedia.sortFlags();
            scAkapedia.flagColumn = 'Age_days__c';
            scAkapedia.sortFlags();
            
            PageReference newPage = scAkapedia.refreshPage();
            
            Test.stopTest();
        }
    }
    
    @isTest
    static void KCS_Scorecard_Dashboard_Test_Lightning()
    {   
        createTestData();
         User techManager = [SELECT Id FROM User WHERE Isactive = TRUE AND Profile.Name = 'Support - Tech Support Manager' LIMIT 1];
         System.runAs(techManager)
         {
        SC_KCS_Scorecard_Dashboard.KCS_Wrapper wrapper_instance= new SC_KCS_Scorecard_Dashboard.KCS_Wrapper();
        String Knowledge_Record_Id=ka.Id;
      
        SC_KCS_Scorecard__c  Scorecard_instance=[SELECT ID,Notes__c FROM SC_KCS_Scorecard__c LIMIT 1][0];
        
        String Scorecard_Record_Id=Scorecard_instance.Id;
        
        String Criteria_Data='[{"Criteria_Name__c":"Article is not a duplicate","Criteria_Number__c":1,"Points__c":20,"Response__c":"Good","Fixed__c":true},{"Criteria_Name__c":"Solution/Answer is complete","Criteria_Number__c":2,"Points__c":20,"Response__c":"Good","Fixed__c":true},{"Criteria_Name__c":"The correct template was selected","Criteria_Number__c":3,"Points__c":20,"Response__c":"Good","Fixed__c":true},{"Criteria_Name__c":"Issue is in customers language/context","Criteria_Number__c":4,"Points__c":15,"Response__c":"Good","Fixed__c":true},{"Criteria_Name__c":"Summary is filled in correctly","Criteria_Number__c":5,"Points__c":15,"Response__c":"Good","Fixed__c":true},{"Criteria_Name__c":"The correct audience is set","Criteria_Number__c":6,"Points__c":5,"Response__c":"Need Fix","Fixed__c":true},{"Criteria_Name__c":"Product and Topic Categories are correct","Criteria_Number__c":7,"Points__c":5,"Response__c":"Need Fix","Fixed__c":true}]';
        
        String Notes=Scorecard_instance.Notes__c;
          
        Test.startTest(); 
        
        // Insert 
        wrapper_instance= SC_KCS_Scorecard_Dashboard.Calc_SC_KCS_Scorecard_Details(Knowledge_Record_Id, 'Knowledge', 'Knowledge');
        SC_KCS_Scorecard_Dashboard.Update_KCS_Scorecard_Details(Criteria_Data,Notes,Knowledge_Record_Id, 'Knowledge', 'Knowledge'); 
        //Update
        wrapper_instance= SC_KCS_Scorecard_Dashboard.Calc_SC_KCS_Scorecard_Details(Knowledge_Record_Id, 'Knowledge', 'Knowledge');
        SC_KCS_Scorecard_Dashboard.Update_KCS_Scorecard_Details(Criteria_Data,Notes,Knowledge_Record_Id, 'Knowledge', 'Knowledge'); 
        
        SC_KCS_Scorecard_Dashboard.Update_KCS_Scorecard_Details(Criteria_Data,Notes,Scorecard_Record_Id, 'Quality Coaching', 'Quality Coaching'); 
        SC_KCS_Scorecard_Dashboard.getParentType(Scorecard_instance.Id);
        
        Test.stopTest(); 
        }
    }
    
    
     @isTest
    static void My_Akapedia_Image_Banner_Test()
    {   
        SC_KCS_Level_ImageBannerCtrl.Get_User_Details();
    }
    
    static testmethod void knowledgeTrigger(){
        createTestData();
        Case c = [Select Id from Case limit 1];
        
        Test.startTest();
        List<Knowledge__kav> lKAV = new List<Knowledge__kav>();
        
        Knowledge__kav rec1 = new Knowledge__kav();
		rec1.title = '-RandomUniqueTitle323232323-';
		rec1.Description__c = 'Test Descreption';
        rec1.UrlName='RandomUniqueTitle323232323';
        rec1.RecordTypeId = Knowledge__kav.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Troubleshooting_Procedure').getRecordTypeId();
        rec1.Source_Case__c = c.Id;
        rec1.Created_from_Publisher_Action__c = True;
        lKAV.add(rec1);
        
        Knowledge__kav rec2 = new Knowledge__kav();
		rec2.title = '-RandomUniqueTitle34343434?';
        rec2.Description__c = 'Test Descreption';
        rec2.UrlName='RandomUniqueTitle34343434';
        rec2.RecordTypeId = Knowledge__kav.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('How_To').getRecordTypeId();
        rec2.Source_Case__c = c.Id;
        rec2.Created_from_Publisher_Action__c = True;
        lKAV.add(rec2);
        
        Knowledge__kav rec3 = new Knowledge__kav();
        rec3.title = 'RandomUniqueTitle4545454545';
        rec3.Description__c = 'Test Descreption';
        rec3.UrlName='RandomUniqueTitle4545454545';
        rec3.RecordTypeId = Knowledge__kav.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Question_Answer').getRecordTypeId();
        rec3.Source_Case__c = c.Id;
        rec3.Created_from_Publisher_Action__c = True;
        lKAV.add(rec3);
        
        insert lKAV;
        
        Test.stopTest();
        
    }
    
    
}