/*--------------------------------------------------------------
Page Name               : SC_Akapedia
Class Type              : Page Controller
Test Class              : SC_KCS_TestClass
Author                  : Aditya Sonam
Created Date            : 12-July-2017
JIRA                    : ESESP-671
------------------------------------------------------------------
|   HISTORY                                                      |                                                                            
|   DATE            DEVELOPER   JIRA        DESCRIPTION                                                       
|   ===========     =========   =======     =========== 
|   22-Oct-2017     Pinkesh     ESESP-746   KCS: adding new KCS KDE value, Enhancements and Fixes for Akapedia Dashboard 
|   23-Nov-2017     Vikas       ESESP-781   KCS Enhancement : Accuracy Check Akapedia Dashboard Changes
|   23-Apr-2018     Vamsee      ESESP-1137  Change Modified fields to AKAM Modified fields
|   24-May-2018     Sumanth     ESESP-1208  Enabling KCS & Akapedia Dashboard for SOCC
|   24-Oct-2018     Vamsee      ESESP-1791  Fixing heap size error
|   15-Jan-2019     Vamsee      ESESP-1779  Lightning Knowledge Migration 
|   18-Jul-2019     Vishnu      ESESP-2104  Akapedia Dashbaord, Accuracy Check - filter invalid cases
|   31-Jul-2019     Pinkesh     ESESP-2525  Button in Akapedia for Content Quality
----------------------------------------------------------------*/
public class SC_AkapediaController {
    
    //Variable related to participants section 
    public string loggedInUserName{get;set;}
    public string Photolink{get;set;}
    public List<userKAWrapper> wrappedObjects{get;set;}
    public String userListOnSearch{get;set;}
    public list<User> allUserDetailSearch = new List<user>();
    public boolean isDescending = true;
    public string inputUserName{get;set;}
    public boolean populateTable{get;set;}
    public string inputDate{get;set;}
    public boolean hasAccess{get;set;}
    public boolean isValidUsrEntry{get;set;}
    public string coachingUserFieldId{get;set;}
    public string KBARReportId{get;set;}
    public string fixReportId{get;set;}
    public string addReportId{get;set;}
    public string avgAQIReportId{get;set;}
    public string accuracyCheckReportId{get;set;} //To store the id "AccuracyCheckReport" report for ESESP-781
    public transient string usrDateRangeForReporting{get;set;}
    public transient string usrDateRangeForReportingLightning{get;set;}
    
    public string sortColumnVal{get;set;}
    public dateTime userDateSelection;
    public integer inputdateNumber;
    public id loggedInUserId;
    public date trainingStartDate;
    public Set<User> allPartcipantSet;
    public Boolean isShowCoach{get;set;}
    public Boolean isShowUntrained{get;set;}
    public String OCQLink{get;set;}
    
    
    // Variables for Article and Flag Sections
    public List<Knowledge__kav> allArticles {get;set;}
    public List<SC_KCS_Flag__c> allFlags{get;set;}
    public String articleReport{get;set;}
    public String flagReport{get;set;}
    public String flagFilter{get;set;}
    public String closeFlagId{get;set;}
    public Id dismissArticleId{get;set;}
    public String closeComment{get;set;}
    public DateTime todayDate{get;set;}
    
    public boolean ascArticle = true;
    public boolean ascFlag = true;
    
    public String articleColumn{get;set;}
    public String flagColumn{get;set;}
    public string metaDataDevName;
    public boolean isKCSFlagRed = false;
    //Variable for ESESP-1208
    public boolean  isManagedSOC = false;
    public boolean  isAkaTech = false;
    // ESESP-2104: CONSTANT for "Invalid Record" type name
    static final String RT_INVALID = 'Invalid Case';

    public SC_AkapediaController()        
    {
        User loggedInUserDetail = [SELECT Id,Name,Email,fullPhotoUrl,smallPhotoUrl,SC_KCS_Coach__c,KCS_Level__c,Profile.Name, Alias FROM User WHERE Id =:Userinfo.getUserId() LIMIT 1];

        /****Code block for ESESP-1208**/
        List<Akapedia_Profile_settings__mdt> AkatechProfile = [Select Profile_List__c from Akapedia_Profile_settings__mdt where label='Akatech'];

        List<String> AkatechProfileNames = new List<String>();
        AkatechProfileNames = AkatechProfile[0].Profile_List__c.split(',');
        
        
        List<Akapedia_Profile_settings__mdt> MSProfile = [Select Profile_List__c from Akapedia_Profile_settings__mdt where label='SOC'];

        List<String> SOCProfileNames = new List<String>();
        SOCProfileNames = MSProfile[0].Profile_List__c.split(',');

        
        
       //Code to differentiate between MS & Akatech
        if(SOCProfileNames.contains(loggedInUserDetail.Profile.Name))
        {
              isManagedSOC = true;
        }
        if(AkatechProfileNames.contains(loggedInUserDetail.Profile.Name))
        {
              isAkaTech = true;
        }
        /***End of Code Block for ESESP-1208**/
        
        Environment_Setup__c environmentSetup = Environment_Setup__c.getInstance();
        metaDataDevName = environmentSetup.Environment_Type__c == 'Primary' ? 'AkapediaPrimary' : 'AkapediaDR';
        
        SC_AkapediaCsutomMdt__mdt akaMDT = [Select SC_AvgAQI_ReportId__c,SC_Article_Report_ID__c,SC_AddReportId__c,SC_FixReportId__c, SC_Flag_Report_ID__c,SC_KBARReportID__c,
                                            SC_AkapediaTrainingStartDate__c,SC_CoachingUserFieldId__c, SC_AccuracyCheckReportId__c  from SC_AkapediaCsutomMdt__mdt where DeveloperName = :metaDataDevName limit 1];
        
        trainingStartDate = akaMDT.SC_AkapediaTrainingStartDate__c;
        //Participants variable initialization
        loggedInUserName = loggedInUserDetail.Name;
        loggedInUserId = loggedInUserDetail.Id;
        Photolink = loggedInUserDetail.smallPhotoUrl;
        userListOnSearch = '';
        populateTable = false;
        inputdateNumber = 30;
        userDateSelection = System.now() - inputdateNumber;
        userDateSelection = userDateSelection.addHours(-userDateSelection.hourGmt());
        userDateSelection = userDateSelection.addMinutes(-userDateSelection.minuteGmt());
        usrDateRangeForReporting = userDateSelection.month()+'/'+userDateSelection.day()+'/'+userDateSelection.year();
        usrDateRangeForReportingLightning = userDateSelection.day()+'/'+userDateSelection.month()+'/'+userDateSelection.year();
        
        isShowCoach = True;
        isShowUntrained = True;
        OCQLink = getOCQLink();
        
        //Articles and Flags variable initialization
        flagFilter = 'My Participants';
        todayDate = System.now();
        articleColumn = 'Title';
        flagColumn = 'Knowledge__r.Title';
        
        articleReport = String.valueOf(akaMDT.SC_Article_Report_ID__c);
        flagReport = String.valueOf(akaMDT.SC_Flag_Report_ID__c);
        coachingUserFieldId = String.valueOf(akaMDT.SC_CoachingUserFieldId__c);
        fixReportId = String.valueOf(akaMDT.SC_FixReportId__c);
        addReportId = String.valueOf(akaMDT.SC_AddReportId__c);
        KBARReportId = String.valueOf(akaMDT.SC_KBARReportID__c);
        avgAQIReportId = String.valueOf(akaMDT.SC_AvgAQI_ReportId__c);
        accuracyCheckReportId = String.valueOf(akaMDT.SC_AccuracyCheckReportId__c);//To get the report id of "AccuracyCheckReport" report (ESESP-781)
        
        
        if(loggedInUserDetail.KCS_Level__c == 'KCS Coach' || loggedInUserDetail.KCS_Level__c == 'KCS KDE' || loggedInUserDetail.Profile.Name.contains('Support - Tech Support Manager') || loggedInUserDetail.Profile.Name.contains('Technical Relationship Engineer')){
            hasAccess = true;
            allUserDetailSearch = [SELECT id,Name,email FROM User WHERE (Profile.Name LIKE 'Support - Tech Support Manager%' or Profile.Name LIKE 'Technical Relationship Engineer' or KCS_Level__c = 'KCS Coach' or KCS_Level__c = 'KCS KDE') and IsActive = true];
            string userNameId = '';
            // loop to create json data for user search bar
            for(user u:allUserDetailSearch){
                userNameId += '\"'+ u.Name + ' ('+u.email+')'+'\"'+',';
            }
            //userNameId = userNameId + '\"'+loggedInUserDetail.Name+' ('+ loggedInUserDetail.Email+')'+'\"';
            userNameId = userNameId.removeEnd(',');
            userNameId = '['+userNameId+']';
            userListOnSearch = userNameId;
            
            //Calling method for participants data creation
            findParticipants(loggedInUserId);
        }
        else
        { hasAccess = false;}
    }
    
    //Method to find all partipants and its respective KCS_Level__c,SC_KCS_Coach__c,ManagerId
    public void findParticipants(id loggedInUsrId){
        
        //KCS_1_1_Session_Configuration__c to check the Last One On One Session condition
        Map<String, Integer> mKCSLevelDays = new Map<String, Integer>();
        for(KCS_1_1_Session_Configuration__c eachrec: [Select id, KCS_Level__c, Days__c from KCS_1_1_Session_Configuration__c]){
            mKCSLevelDays.put(eachrec.KCS_Level__c, (Integer)eachrec.Days__c);
        }
        Id rcaArticleId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByName().get('RCA Document').getRecordTypeId();
        //wrapper class object
        wrappedObjects = new list<userKAWrapper>();
        
        //to refresh each table row
        populateTable = true;
        
        //unique set of participants
        allPartcipantSet = new set<user>();
        
        //participant details Map
        Map<Id,User> allParticipantDetailsMap = new Map<Id,User>();
        
        //List of participantIds
        List<Id> participantsIdList = new List<Id>();
        
        //User time frame selection 
        userDateSelection = System.now() - inputdateNumber;
        userDateSelection = userDateSelection.addHours(-userDateSelection.hourGmt());
        userDateSelection = userDateSelection.addMinutes(-userDateSelection.minuteGmt());
        usrDateRangeForReporting = userDateSelection.month()+'/'+userDateSelection.day()+'/'+userDateSelection.year();
        usrDateRangeForReportingLightning = userDateSelection.day()+'/'+userDateSelection.month()+'/'+userDateSelection.year();
        
        //fetching participants whose manager is logged in user
        List<User> usersUnderManager = new List<User>([SELECT id,Name,smallPhotoUrl,KCS_Level__c,SC_KCS_Coach__c,SC_KCS_Coach__r.Name,ManagerId, Alias from user where ManagerId =:loggedInUsrId and isActive = true]);
        
        //fetching participants whose coach is logged in user
        List<User> usersUnderCoach = new List<User>([SELECT id,Name,smallPhotoUrl,KCS_Level__c,SC_KCS_Coach__c,SC_KCS_Coach__r.Name,ManagerId, Alias from user where SC_KCS_Coach__c =:loggedInUsrId and isActive = true]);
        
        //Adding the list of particpant to set to remove duplicates
        if(usersUnderManager.size()>0) allPartcipantSet.addAll(usersUnderManager);
        if(usersUnderCoach.size()>0) allPartcipantSet.addAll(usersUnderCoach);       
        if(allPartcipantSet.size() > 0){
            
            for(user u :allPartcipantSet){
                allParticipantDetailsMap.put(u.id, u);
                participantsIdList.add(u.id);
            }
            
            usersUnderManager.clear();
            usersUnderCoach.clear();
            //Map for article id and caseAssociationCount
            Map<Id,Integer> articleIdCaseAssoMap = new Map<Id,Integer>();
            
            //fetching Knowledge Article with participants and time frame condition
            
            list<KnowledgeArticle> kaArticleList = new List<KnowledgeArticle>([select id,createddate,lastModifieddate,caseAssociationCount from KnowledgeArticle where (lastModifiedById IN :allPartcipantSet OR createdById IN : allPartcipantSet) and lastModifieddate >:userDateSelection]);
            list<id> articleId = new list<id>();
            for(KnowledgeArticle eachArticle :kaArticleList){
                articleIdCaseAssoMap.put(eachArticle.id,eachArticle.caseAssociationCount);
                articleId.add(eachArticle.id);
            }
            kaArticleList.clear();
            // Fetching version details from knowledge Article kaArticleList
            List<Knowledge__kav> kbArticle = new List<Knowledge__kav>([Select id,ownerid,IsLatestVersion,LastModifiedDate,createdBy.Name,ArticleNumber,Owner.Name,Summary,title,VersionNumber,KnowledgeArticleId,Createddate,FirstPublishedDate,LastModifiedById,PublishStatus from Knowledge__kav where PublishStatus = 'Online' and KnowledgeArticleId IN :articleId and language='en_US' AND RecordTypeId != :rcaArticleId]);
            
            //Map to store userid and its article
            Map<id,list<Knowledge__kav>> userKAMap = new Map<id,list<Knowledge__kav>>();
            Map<id,list<Knowledge__kav>> userKAMapWhoModifiedArticle = new Map<id,list<Knowledge__kav>>();
            
            //Creating map of user Id and and article created by the user.
            for(Knowledge__kav kaV : kbArticle){
                if(userKAMap.containsKey(kaV.ownerid)){
                    list<Knowledge__kav> kavList = userKAMap.get(kaV.ownerid);
                    kavList.add(kaV);
                    userKAMap.put(kaV.ownerid, kavList);
                }
                else{
                    userKAMap.put(kaV.ownerid, new list<Knowledge__kav> {kaV});
                }
            }
            kbArticle.clear();
            
            //list<knowledgeArticleVersion> kaVerisonForFixList = new list<knowledgeArticleVersion>([Select id,ownerid,IsLatestVersion,LastModifiedDate,createdBy.Name,ArticleType,ArticleNumber,Owner.Name,Summary,title,VersionNumber,KnowledgeArticleId,Createddate,FirstPublishedDate,LastModifiedById,PublishStatus from KnowledgeArticleVersion where PublishStatus = 'Online' and lastmodifiedbyId IN :participantsIdList and language='en_US']);
            
            List<Knowledge__kav> kaVerisonForFixList = new List<Knowledge__kav>([Select id,ownerid,IsLatestVersion,AKAM_Modified_Date__c,createdBy.Name,ArticleNumber,Owner.Name,Summary,title,VersionNumber,KnowledgeArticleId,Createddate,FirstPublishedDate,AKAM_Modified_By__c,PublishStatus, AKAM_Modified_By_Id__c  from Knowledge__kav where PublishStatus = 'Online' and AKAM_Modified_By_Id__c  IN :participantsIdList and language='en_US' And RecordTypeId != :rcaArticleId]);
            //kaVerisonForFixList.addAll((List<sObject>) [Select id,ownerid,IsLatestVersion,AKAM_Modified_Date__c,createdBy.Name,ArticleType,ArticleNumber,Owner.Name,Summary,title,VersionNumber,KnowledgeArticleId,Createddate,FirstPublishedDate,AKAM_Modified_By__c,PublishStatus, AKAM_Modified_By_Id__c from How_To__kav where PublishStatus = 'Online' and AKAM_Modified_By_Id__c IN :participantsIdList and language='en_US']);
            //kaVerisonForFixList.addAll((List<sObject>) [Select id,ownerid,IsLatestVersion,AKAM_Modified_Date__c,createdBy.Name,ArticleType,ArticleNumber,Owner.Name,Summary,title,VersionNumber,KnowledgeArticleId,Createddate,FirstPublishedDate,AKAM_Modified_By__c,PublishStatus, AKAM_Modified_By_Id__c from Question_Answer__kav where PublishStatus = 'Online' and AKAM_Modified_By_Id__c IN :participantsIdList and language='en_US']);
            //kaVerisonForFixList.addAll((List<sObject>) [Select id,ownerid,IsLatestVersion,AKAM_Modified_Date__c,createdBy.Name,ArticleType,ArticleNumber,Owner.Name,Summary,title,VersionNumber,KnowledgeArticleId,Createddate,FirstPublishedDate,AKAM_Modified_By__c,PublishStatus, AKAM_Modified_By_Id__c from Release_Notes__kav where PublishStatus = 'Online' and AKAM_Modified_By_Id__c IN :participantsIdList and language='en_US']);
            //kaVerisonForFixList.addAll((List<sObject>) [Select id,ownerid,IsLatestVersion,AKAM_Modified_Date__c,createdBy.Name,ArticleType,ArticleNumber,Owner.Name,Summary,title,VersionNumber,KnowledgeArticleId,Createddate,FirstPublishedDate,AKAM_Modified_By__c,PublishStatus, AKAM_Modified_By_Id__c from Glossary_Definition__kav where PublishStatus = 'Online' and AKAM_Modified_By_Id__c IN :participantsIdList and language='en_US']);
            //kaVerisonForFixList.addAll((List<sObject>) [Select id,ownerid,IsLatestVersion,AKAM_Modified_Date__c,createdBy.Name,ArticleType,ArticleNumber,Owner.Name,Summary,title,VersionNumber,KnowledgeArticleId,Createddate,FirstPublishedDate,AKAM_Modified_By__c,PublishStatus, AKAM_Modified_By_Id__c from Troubleshooting_Procedure__kav where PublishStatus = 'Online' and AKAM_Modified_By_Id__c IN :participantsIdList and language='en_US']);

            
            for(Knowledge__kav eachFixVersion :kaVerisonForFixList){
                if(userKAMapWhoModifiedArticle.containsKey(eachFixVersion.AKAM_Modified_By_Id__c) && userKAMapWhoModifiedArticle.get(eachFixVersion.AKAM_Modified_By_Id__c) != Null){
                    list<Knowledge__kav> kavArticleModifiedList = userKAMapWhoModifiedArticle.get(eachFixVersion.AKAM_Modified_By_Id__c);
                    kavArticleModifiedList.add(eachFixVersion);
                    userKAMapWhoModifiedArticle.put(eachFixVersion.AKAM_Modified_By_Id__c, kavArticleModifiedList);
                }
                else{
                    userKAMapWhoModifiedArticle.put(eachFixVersion.AKAM_Modified_By_Id__c, new list<Knowledge__kav> {eachFixVersion});
                }  
            }
            
            
            
            kaVerisonForFixList.clear();
            
            //Creating map of user Id and and article created by the user.
            List<KnowledgeArticleViewStat> viewCountList = new List<KnowledgeArticleViewStat>([SELECT Id, NormalizedScore, Parent.Id, ViewCount, Parent.createdbyid,Parent.FirstPublishedDate FROM KnowledgeArticleViewStat WHERE Parent.createdbyid IN :allPartcipantSet and channel ='AllChannels']);
            Map<Id,List<Integer>> viewCountMap = new Map<Id,List<Integer>>();
            
            for(KnowledgeArticleViewStat eachViewCount : viewCountList){
                if(eachViewCount.Parent.FirstPublishedDate > trainingStartDate){
                    if(viewCountMap.containsKey(eachViewCount.Parent.createdbyid)){
                        list<Integer> viewList = viewCountMap.get(eachViewCount.Parent.createdbyid);
                        viewList.add(eachViewCount.ViewCount);
                        viewCountMap.put(eachViewCount.Parent.createdbyid, viewList);
                    }
                    
                    else{
                        viewCountMap.put(eachViewCount.Parent.createdbyid, new list<integer> {eachViewCount.ViewCount});
                    }
                }  
            }
            viewCountList.clear();            
            //Map for participants and last session 
            Map<Id,DateTime> lastSessionMap = new Map<Id,DateTime>();
            for(SC_KCS_Coaching_Record__c  eachSession: [Select KCS_User__c,createddate from SC_KCS_Coaching_Record__c where KCS_User__c IN : allPartcipantSet]){
                if(lastSessionMap.containsKey(eachSession.KCS_User__c)){
                    DateTime sessionDate = lastSessionMap.get(eachSession.KCS_User__c);
                    if(eachSession.createddate >= sessionDate){
                        sessionDate = eachSession.createddate;
                        lastSessionMap.put(eachSession.KCS_User__c, sessionDate);
                    }
                }
                else{
                    lastSessionMap.put(eachSession.KCS_User__c, eachSession.createddate);
                }             
            }
            
            //Map for participants scorecard against each article
            Map<Id,List<SC_KCS_Scorecard__c>> avgArticleTotalScoreMap = new Map<ID,list<SC_KCS_Scorecard__c>>();
            //for(SC_KCS_Scorecard__c  eachScore : [Select Article_Created_By__c, Total_Score__c, Article_SF_Id__c,createddate from SC_KCS_Scorecard__c where Article_Created_By__c IN : allPartcipantSet]){ 
            for(SC_KCS_Scorecard__c  eachScore : [Select Knowledge__r.ArticleCreatedById, Total_Score__c, Knowledge__c, createddate from SC_KCS_Scorecard__c where Knowledge__r.ArticleCreatedById IN : allPartcipantSet]){ 
                if(avgArticleTotalScoreMap.containsKey(eachScore.Knowledge__r.ArticleCreatedById)){
                    list<SC_KCS_Scorecard__c> scoreList = avgArticleTotalScoreMap.get(eachScore.Knowledge__r.ArticleCreatedById);
                    scoreList.add(eachScore);
                    avgArticleTotalScoreMap.put(eachScore.Knowledge__r.ArticleCreatedById,scoreList);
                }     
                else{
                    avgArticleTotalScoreMap.put(eachScore.Knowledge__r.ArticleCreatedById, new list<SC_KCS_Scorecard__c> {eachScore});
                }
            }
            
            //Map for Caseid and Article associated with it
            Map<Id,List<Case>> avgArticleCaseAssoMap = new Map<ID,list<Case>>();
            list<Id> allArticle = new list<Id>();
            for(id eachKAId :userKAMap.keySet()){
                for(Knowledge__kav eachArticleV :userKAMap.get(eachKAId)){
                    if(eachArticleV.createddate > userDateSelection)
                        allArticle.add(eachArticleV.KnowledgeArticleId);
                }
            }
            
            Map<Id,List<Case>> caseOwnerArticleIdMap = new Map<Id,List<Case>>();
            //Removed the check of AKAM Closed date, instead passing the userSelectedDate to the wrapper class (ESESP-781)
             //Include RecordType.Name in Query for ESESP-1208
            // ESESP-2104 - added condition to exclude invalid cases - recordtype.name = invalid
			//ESESP-4391 - Added Date Filters (Vamsee)
            list<case> allCaseList = [Select id,ownerid,Has_Article_Linked__c,Accurate_Attach__c,RecordType.Name,Non_Attach_Indicator__c,Accuracy_Check_Created_Date__c, AKAM_Closed_Date__c,Has_Attach_Accuracy_Check__c 
                                      from Case where ownerid IN :allPartcipantSet AND RecordType.Name != :RT_INVALID
                                      and Origin != 'Proactive' AND (AKAM_Closed_Date__c > :userDateSelection OR Accuracy_Check_Created_Date__c > :userDateSelection)
                                      and Sub_Type__c != 'CMP Alerts' and Sub_Type__c != 'Service & Support Packages' and Sub_Type__c != 'NIE/NOCC Request' and Work_Type__c !='Proactive' and Status ='Closed'
                                      and (NOT Account.Name LIKE '%Akamai%') LIMIT 50000];
            System.debug('--userDateSelection--'+userDateSelection);
            for(case linkedCaseList : allCaseList)
            {
                if(caseOwnerArticleIdMap.containsKey(linkedCaseList.ownerid)){
                    list<case> userCaseList = caseOwnerArticleIdMap.get(linkedCaseList.ownerid);
                    userCaseList.add(linkedCaseList);
                    caseOwnerArticleIdMap.put(linkedCaseList.ownerid, userCaseList);
                }
                else{
                    caseOwnerArticleIdMap.put(linkedCaseList.ownerid, new list<case>{linkedCaseList});
                }                           
            }
            
            allCaseList.clear();
            //for each participants calling wrapper class to create table data
            for(User eachParticpants :allPartcipantSet){
                list<Knowledge__kav> kAVersionList = new List<Knowledge__kav>();        
                if(userKAMap.containsKey(eachParticpants.id)){
                    kAVersionList = userKAMap.get(eachParticpants.id);
                    
                }
                userKAWrapper wrappedObject = new userKAWrapper(eachParticpants.id,kAVersionList,userDateSelection,articleIdCaseAssoMap,
                                                                allParticipantDetailsMap,viewCountMap,lastSessionMap,userKAMapWhoModifiedArticle,
                                                                trainingStartDate,avgArticleTotalScoreMap,caseOwnerArticleIdMap,userDateSelection,isManagedSOC,isAkatech);//passing "userDateSelection" to calculate KBAR & Accuracy (ESESP-781)
                
                if(!((!isShowCoach && (wrappedObject.KCSLevel=='KCS Coach'||wrappedObject.KCSLevel=='KCS KDE')) || (!isShowUntrained && wrappedObject.KCSLevel=='-')))
                    wrappedObjects.add(wrappedObject);   
            }
            
            populateArticlesTable();
            populateFlagsTable();
            
            if(!wrappedObjects.isEmpty()){
                for(userKAWrapper eachWrapperObj :wrappedObjects){
                    if(eachWrapperObj.noOfDaysLastSession > mKCSLevelDays.get(eachWrapperObj.KCSLevel) && mKCSLevelDays.get(eachWrapperObj.KCSLevel)!=null && mKCSLevelDays.get(eachWrapperObj.KCSLevel)!=0){
                        isKCSFlagRed = true;
                        eachWrapperObj.isSessionElementRed = true;
                    }
                    else{
                        eachWrapperObj.isSessionElementRed = false;
                    }
                }
            }
        }
    }
    
    //wrapper class definition
    public class userKAWrapper {
        
        //variables to be used on page table 
        public String userId{get;set;}
        public String Alias{get;set;}
        public String photolink{get;set;}
        public String name{get;set;}
        public String KCSLevel{get;set;}
        public String coach{get;set;}
        public Integer avgAQI{get;set;}
        public Integer useKBAR{get;set;}
        public Integer useAccuracy{get;set;}//To show % of Use Accuracy in Akapedia Dashboard for ESESP-781
        public Integer fixEdit{get; set;}
        public Integer addCreated{get;set;}
        public Integer impactReuse{get;set;}
        public Integer impactView{get;set;}
        public String lastOneOnOneSession{get;set;}
        public Integer articleScored{get;set;}
        public Integer totalAccuracyCheckedCase{get;set;}//To show the total number of cases whose accuracy has been checked for ESESP-781
        public Integer noOfDaysLastSession{get;set;}
        public Integer noOfDayLSForSorting{get;set;}
        public Boolean isSessionElementRed{get;set;}
        
        //constructor
        public userKAWrapper(){}
        
        //constructor for wrapper with parameters
        //Added two boolean parameters for ESESP-1208 for Constructor
        public userKAWrapper(id partcipantId,list<Knowledge__kav> kAVersionList,dateTime timeFrame, Map<Id,Integer> articleIdCaseAssoMap,
                             Map<Id,User> allParticipantDetailsMap,Map<Id,List<Integer>> viewCountMap,Map<id,datetime> lastSessionMap,Map<Id,List<sObject>> userKAMapWhoModifiedArticle,
                             date trainingStartDate,Map<Id,List<SC_KCS_Scorecard__c>> avgArticleTotalScoreMap,Map<Id,List<Case>> caseOwnerArticleIdMap,DateTime userDateSelection,Boolean isManagedSOC,Boolean isAkatech) {
                                 userId = '';
                                 Alias = '';
                                 photolink = '';
                                 name = '';
                                 KCSLevel = '-';
                                 coach = '-';
                                 avgAQI = 0;
                                 useKBAR = 0;
                                 useAccuracy = 0; //ESESP-781                    
                                 fixEdit = 0;
                                 addCreated = 0;
                                 impactReuse = 0;
                                 impactView = 0;
                                 lastOneOnOneSession = '-';
                                 articleScored = 0;
                                 totalAccuracyCheckedCase = 0; //To store the number of cases whose accuracy has been checked (ESESP-781)
                                 integer totalCase = 0;
                                 integer totalLinkedCase = 0; 
                                 integer totalMSCase = 0;        //As part of ESESP-1208
                                 integer totalLinkedMSCase=0;   //As part of ESESP-1208
                                 integer totalAkaTechCase = 0;  //As part of ESESP-1208
                                 integer totalLinkedAkaTechCase=0;  //As part of ESESP-1208
                                 integer accurateCases = 0; //To store the number of accurate cases (ESESP-781)
                                 noOfDayLSForSorting = 0;
                                 set<id> articleCreatedSet = new set<id>(); 
                                 
                                 // Condition to check if participants is owner of atleast one article                     
                                 if(kAVersionList.size() > 0){
                                     
                                     for(Knowledge__kav eachParticipant : kAVersionList){
                                         if(eachParticipant.FirstPublishedDate > timeFrame && eachParticipant.IsLatestVersion && eachParticipant.VersionNumber > 0){
                                             articleCreatedSet.add(eachParticipant.Id);
                                         }
                                         if(articleIdCaseAssoMap.containsKey(eachParticipant.KnowledgeArticleId) && articleIdCaseAssoMap.get(eachParticipant.KnowledgeArticleId) != Null){
                                             impactReuse += articleIdCaseAssoMap.get(eachParticipant.KnowledgeArticleId);
                                         }                                         
                                         KCSLevel = allParticipantDetailsMap.get(eachParticipant.OwnerId).KCS_Level__c != Null ? allParticipantDetailsMap.get(eachParticipant.OwnerId).KCS_Level__c : '-';
                                         coach = allParticipantDetailsMap.containsKey(eachParticipant.OwnerId) && allParticipantDetailsMap.get(eachParticipant.OwnerId).SC_KCS_Coach__r.Name != Null ? allParticipantDetailsMap.get(eachParticipant.OwnerId).SC_KCS_Coach__r.Name : '-';
                                         userId = allParticipantDetailsMap.get(eachParticipant.OwnerId).Id;
                                         Name = allParticipantDetailsMap.get(eachParticipant.OwnerId).Name;
                                         photolink = allParticipantDetailsMap.get(eachParticipant.OwnerId).smallPhotoUrl;
                                         Alias = allParticipantDetailsMap.get(eachParticipant.OwnerId).Alias;
                                
                                     }
                                     
                                     if(userKAMapWhoModifiedArticle.containsKey(partcipantId)){
                                         for(sObject eachFixVer : userKAMapWhoModifiedArticle.get(partcipantId)){
                                             if(((Integer)eachFixVer.get('VersionNumber')) > 1 && ((DateTime)eachFixVer.get('AKAM_Modified_Date__c')) > timeFrame && ((Id)eachFixVer.get('AKAM_Modified_By_Id__c')) == partcipantId){
                                                 fixEdit += 1;
                                             }
                                         }
                                     }
                                     
                                     addCreated = articleCreatedSet.size();
                                     
                                     if(viewCountMap.containsKey(partcipantId) && viewCountMap.get(partcipantId) != Null){
                                         for(Integer eachViewCount : viewCountMap.get(partcipantId)){
                                             impactView += eachViewCount;
                                         }
                                     }
                                 }
                                 else{ 
                                     KCSLevel = allParticipantDetailsMap.containsKey(partcipantId) && allParticipantDetailsMap.get(partcipantId).KCS_Level__c != Null ? allParticipantDetailsMap.get(partcipantId).KCS_Level__c : '-';
                                     coach = allParticipantDetailsMap.containsKey(partcipantId) && allParticipantDetailsMap.get(partcipantId).SC_KCS_Coach__r.Name != Null ? allParticipantDetailsMap.get(partcipantId).SC_KCS_Coach__r.Name : '-';
                                     userId = allParticipantDetailsMap.get(partcipantId).Id;
                                     Name = allParticipantDetailsMap.get(partcipantId).Name;
                                     photolink = allParticipantDetailsMap.get(partcipantId).smallPhotoUrl;
                                     Alias = allParticipantDetailsMap.get(partcipantId).Alias;
                                     

                                     if(userKAMapWhoModifiedArticle.containsKey(userId)){
                                         for(sObject eachFixVer : userKAMapWhoModifiedArticle.get(userId)){
                                             if(((Integer)eachFixVer.get('VersionNumber')) > 1 && ((DateTime)eachFixVer.get('AKAM_Modified_Date__c')) > timeFrame && ((Id)eachFixVer.get('AKAM_Modified_By_Id__c')) == userId){
                                                 fixEdit += 1;
                                             }
                                         }
                                     } 
                                 }
                                 
                                 if(caseOwnerArticleIdMap.containsKey(partcipantId) && caseOwnerArticleIdMap.get(partcipantId) != null){
                                     for(case eachClosedCase : caseOwnerArticleIdMap.get(partcipantId)){
                                         //Checking if the AKAM Closed date is greater than user selected date for KBAR calculation
                                         if(eachClosedCase.AKAM_Closed_Date__c != null 
                                            && eachClosedCase.AKAM_Closed_Date__c >= userDateSelection)
                                         {
                                             //Use KBAR Calculation modified for ESESP-1208
                                             if(eachClosedCase.RecordType.Name=='Managed Security')
                                             {
                                                
                                                   totalMSCase+=1;
                                                   if(eachClosedCase.Has_Article_Linked__c)
                                                      totalLinkedMSCase += 1;
                                             }
                                             
                                             if(eachClosedCase.RecordType.Name=='Technical')
                                             {
                                                
                                                   totalAkaTechCase+=1;
                                                   if(eachClosedCase.Has_Article_Linked__c)
                                                      totalLinkedAkaTechCase += 1;
                                             }
                                         }
                                         //Checking if the Accuracy Check Created Date is greater than user selected date for KBAR calculation as per ESESP-781
                                         if((eachClosedCase.Accuracy_Check_Created_Date__c != null && eachClosedCase.Accuracy_Check_Created_Date__c > userDateSelection) && 
                                            (!String.isEmpty(eachClosedCase.Accurate_Attach__c))){
                                                totalAccuracyCheckedCase += 1;
                                                if(eachClosedCase.Accurate_Attach__c == 'Yes')
                                                    accurateCases += 1;
                                            }
                                     }
                                     //To calculate the "Use(Accuracy)" percentage as per ESESP-781
                                     if(totalAccuracyCheckedCase > 0)
                                         useAccuracy = (accurateCases*100)/totalAccuracyCheckedCase;
                                     
                                     //To calculate the "KBAR" percentage
                                     if(isManagedSOC)
                                      {
                                          if(totalMSCase>0)
                                          useKBAR = (totalLinkedMSCase*100)/totalMSCase;
                                      }
                                      
                                      if(isAkaTech)
                                      {
                                          if(totalAkaTechCase>0)
                                          useKBAR = (totalLinkedAkaTechCase*100)/totalAkaTechCase;
                                      }
                                 }
                                 
                                 if(avgArticleTotalScoreMap != Null && avgArticleTotalScoreMap.containsKey(partcipantId)){
                                     integer totalScore = 0;
                                     integer articleWithScorecard = 0;
                                     for(SC_KCS_Scorecard__c eachScoreCard :avgArticleTotalScoreMap.get(partcipantId)){
                                         if(eachScoreCard.createddate > timeFrame){
                                             totalScore += Integer.valueOf(eachScoreCard.Total_Score__c);
                                             articleScored += 1; 
                                         }
                                     }
                                     
                                     articleWithScorecard = articleScored >0 ? (totalScore/articleScored) : 0;
                                     avgAQI = articleWithScorecard;
                                 }
                                 
                                 if(lastSessionMap.containsKey(userId) && lastSessionMap.get(userId) != Null){
                                     DateTime dT = lastSessionMap.get(userId);
                                     if(dT != Null){
                                         Date startDate = date.newinstance(dT.year(), dT.month(), dT.day());
                                         noOfDaysLastSession = (System.today().daysBetween(startDate));
                                         noOfDaysLastSession = noOfDaysLastSession < 0 ? noOfDaysLastSession*(-1) : noOfDaysLastSession;
                                         noOfDayLSForSorting = noOfDaysLastSession;
                                         if(noOfDaysLastSession > 1)
                                             lastOneOnOneSession = noOfDaysLastSession + ' days';
                                         else if(noOfDaysLastSession == 0)
                                             lastOneOnOneSession = '0 day';
                                         else
                                             lastOneOnOneSession = noOfDaysLastSession + ' day';
                                     }
                                 }
                                 else{
                                     noOfDayLSForSorting = -1;
                                 }
                             }
    }
    
    
    //Method to sort KBAR
    public void sortTable(){
        List<sortWrapper> memberWrapperList = new List<sortWrapper>();
        for(userKAWrapper mem : wrappedObjects){
            memberWrapperList.add(new sortWrapper(mem,isDescending,sortColumnVal));
        }
        
        memberWrapperList.sort();
        wrappedObjects.clear();
        
        for(sortWrapper MW : memberWrapperList){
            wrappedObjects.add(MW.sortMember);
        }
        isDescending = isDescending ? false : true;
    }
    
    
    //Wrapper class for sorting KBAR
    public class sortWrapper implements Comparable {
        
        public userKAWrapper sortMember = new userKAWrapper();
        public boolean descendingOrder;
        public string sortColumn;
        
        // Constructor
        public sortWrapper(userKAWrapper memberRecord, boolean isDescending,string sortColumnVal) {
            sortMember = memberRecord;
            descendingOrder = isDescending;
            sortColumn = sortColumnVal.trim();
        }
        
        // Compare data based on the KBAR.
        public Integer compareTo(Object compareTo) {
            
            // Cast argument to sortWrapper
            sortWrapper compareTomember = (sortWrapper)compareTo;
            
            // The return value of 0 indicates that both elements are equal.
            Integer returnValue = 0;
            
            //Creating map of sortMember
            String jsonInstanceSortMember = Json.serialize(sortMember);
            Map<String, Object> untypedInstanceSortMember;
            untypedInstanceSortMember= (Map<String, Object>)JSON.deserializeUntyped(jsonInstanceSortMember);
            
            //Creating map of compareTomember
            String jsonInstancecompareTomember = Json.serialize(compareTomember);
            Map<String, Object> untypedInstancecompareTomember;
            untypedInstancecompareTomember= (Map<String,Object>)JSON.deserializeUntyped(jsonInstancecompareTomember);
            String jsonInstanceCompareSortMember = Json.serialize(untypedInstancecompareTomember.get('sortMember'));
            Map<String, Object> untypedInstanceCompareToSort;
            untypedInstanceCompareToSort= (Map<String,Object>)JSON.deserializeUntyped(jsonInstanceCompareSortMember);
            
            if(!sortColumn.contains('name') && !sortColumn.contains('KCSLevel') && !sortColumn.contains('coach')){ 
                sortColumn = sortColumn.contains('lastOneOnOneSession') ? 'noOfDayLSForSorting' : sortColumn;
                // Set return value to a positive value.
                if ((Integer)untypedInstanceSortMember.get(sortColumn) > (Integer)untypedInstanceCompareToSort.get(sortColumn))
                    returnValue = descendingOrder ? 1 : -1;
                // Set return value to a negative value.
                else if ((Integer)untypedInstanceSortMember.get(sortColumn) < (Integer)untypedInstanceCompareToSort.get(sortColumn)) 
                    returnValue = descendingOrder ? -1 : 1;
                
            }
            else{
                // Set return value to a positive value.
                if ((String)untypedInstanceSortMember.get(sortColumn) > (String)untypedInstanceCompareToSort.get(sortColumn))
                    returnValue = descendingOrder ? 1 : -1;
                // Set return value to a negative value.
                else if ((String)untypedInstanceSortMember.get(sortColumn) < (String)untypedInstanceCompareToSort.get(sortColumn)) 
                    returnValue = descendingOrder ? -1 : 1;
            }
            
            return returnValue;       
        }
    }
    
    //Method to display participants based on user search 
    public void updateUserName(){
        isValidUsrEntry = false;
        if(inputUserName != Null || inputUserName != ''){
            for(user allValidUser :allUserDetailSearch){
                if(allValidUser.email == inputUserName){
                    isValidUsrEntry = true;
                    break;
                }
            } 
            if(isValidUsrEntry){
                User inputUser = [Select id,Name from User where email =:inputUserName limit 1];
                wrappedObjects.clear();
                loggedInUserId = inputUser.id;
                findParticipants(inputUser.id);
            }
        }
    }
    
    //Method to update date range as per user input
    public void updateDateRange(){
        if(inputdate.indexOf('7') != -1){
            inputdateNumber = 7;
        }
        else if(inputdate.indexOf('30') != -1){
            inputdateNumber = 30;
        }
        else if(inputdate.indexOf('60') != -1){
            inputdateNumber = 60;
        }
        else {
            inputdateNumber = 90;
        }
        findParticipants(loggedInUserId);
    }
    
    // START OF CHANGES BY VANDHANA
    
    //Score and Flag Calculation
    
    // populate list of all Articles within given Date Range and Created By given Participants
    public void populateArticlesTable()
    {
        Id communityBlogId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByName().get('Community Blog').getRecordTypeId();
        Id rcaArticleId = Schema.SObjectType.Knowledge__kav.getRecordTypeInfosByName().get('RCA Document').getRecordTypeId();
        
        Set<Id> articleIdExcludeSet = new Set<Id>();

        Set<Id> knowledgeArticleIdExcludeSet = new Set<Id>();
        /*for(SC_KCS_Scorecard__c eachScorecard : [SELECT Knowledge__c from SC_KCS_Scorecard__c LIMIT 50000]){
            articleIdExcludeSet.add(eachScorecard.Knowledge__c);
        }*/
        for(SC_KCS_Scorecard__c eachScorecard : [SELECT Knowledge__c,Knowledge__r.KnowledgeArticleId from SC_KCS_Scorecard__c LIMIT 50000]){
            knowledgeArticleIdExcludeSet.add(eachScorecard.Knowledge__r.KnowledgeArticleId);
        }
        for(SC_Dismiss_KB_Article__c eachDismissKB : [SELECT Knowledge__c from SC_Dismiss_KB_Article__c where Dismissed__c = true LIMIT 50000]){
            articleIdExcludeSet.add(eachDismissKB.Knowledge__c);
        }
        
        /*allArticles =   [SELECT Id, CreatedBy.Name,ArticleNumber,Title,FirstPublishedDate,CreatedDate,Owner.Name
                        FROM Knowledge__kav WHERE RecordTypeId != :communityBlogId 
                                            AND PublishStatus = 'Online'
                                            AND Language = 'en_US'
                                            AND Visibility__c !='Work In Progress'
                                            AND Version_Number__c = 1
                                            AND CreatedById in :allPartcipantSet
                                            AND FirstPublishedDate > :userDateSelection
                                            AND Id NOT In :articleIdExcludeSet
                                            ORDER BY CreatedDate limit 50000];*/

        allArticles =   [SELECT Id, CreatedBy.Name,ArticleNumber,KnowledgeArticleId,Title,FirstPublishedDate,CreatedDate,Owner.Name
                                FROM Knowledge__kav WHERE RecordTypeId Not IN (:communityBlogId ,:rcaArticleId)
                                AND PublishStatus = 'Online'
                                AND Language = 'en_US'
                                AND Visibility__c !='Work In Progress'
                                AND KnowledgeArticleId NOT In : knowledgeArticleIdExcludeSet
                                AND CreatedById in :allPartcipantSet
                                AND FirstPublishedDate > :userDateSelection
                                AND Id NOT In :articleIdExcludeSet
                                ORDER BY CreatedDate limit 50000];                                                                            
        
        articleIdExcludeSet.clear();
        //Flag for KCS Color on Home 2.0 Screen
        if(allArticles.size() > 0){
            isKCSFlagRed = true;
        }
    } 
    
    // populate list of all Open KCS Flags within given Date Range and Created By given Participants
    public void populateFlagsTable()
    {
        String flagQuery = 'Select CreatedBy.Name,Knowledge__r.Title,Age_days__c from SC_KCS_Flag__c ' + 
            'where Status__c = \'Open\'';
        
        flagQuery = flagQuery + ' AND CreatedDate > :userDateSelection';
        if(flagFilter == 'My Participants')
            flagQuery = flagQuery + ' AND CreatedBy.Id IN :allPartcipantSet';
        flagQuery = flagQuery + ' ORDER BY CreatedDate limit 50000';
        allFlags = Database.query(flagQuery);
        
        //Flag for KCS Color on Home 2.0 Screen
        if(allFlags.size() > 0){
            isKCSFlagRed = true;
        }
    }  
    
    // close KCS Flag with Close Comments
    public void dismissFlag()
    {
        SC_KCS_Flag__c flag = [Select Status__c from SC_KCS_Flag__c where Id = :closeFlagId limit 1];
        if(flag != NULL)
        {
            flag.Status__c = 'Closed';
            flag.Close_Comments__c  = closeComment;
            update flag;
        }
        populateFlagsTable();
    }     
    
    public void dismissArticle()
    {
        
        SC_Dismiss_KB_Article__c newKBDismiss = new SC_Dismiss_KB_Article__c(Knowledge__c = dismissArticleId,Dismissed__c = true);
        
        try
        {
            insert newKBDismiss;
        }
        
        catch(Exception e)
        {
            SC_Autogen_COB_Support sc_COBSupportCls = new SC_Autogen_COB_Support(); 
            String mssg = e.getCause()+'\nLine : '+e.getLineNumber()+'\nMessage : '+e.getMessage()+'\nError Type : '+e.getTypeName()+'\nStack Trace : '+e.getStackTraceString();
            sc_COBSupportCls.senEmailForError('Error while inserting SC_Dismiss_Article record', mssg); 
        }
        populateArticlesTable();
    }
    
    //Method to sort Articles
    public void sortArticles()
    {
        allArticles = (List<Knowledge__kav>) sortFunction(allArticles,articleColumn,ascArticle);
        ascArticle = !ascArticle;
    }
    
    //Method to sort Flags
    public void sortFlags()
    {
        allFlags = (List<SC_KCS_Flag__c>) sortFunction(allFlags,flagColumn,ascFlag);
        ascFlag = !ascFlag;
    }
    
    
    // MAIN SORTING METHOD
    
    public List<sObject> sortFunction(List<sObject> soList,String fieldName, boolean sortOrder)
    {
        List<sortWrapperClass> memberWrapperList = new List<sortWrapperClass>();
        for(sObject eachRec : soList){
            memberWrapperList.add(new sortWrapperClass(eachRec,fieldName,sortOrder));
        }
        
        memberWrapperList.sort();
        soList.clear();
        
        for(sortWrapperClass sWrap : memberWrapperList){
            soList.add(sWrap.sortMember);
        }
        return soList; 
    }
    
    //Wrapper class for sorting KBAR
    public class sortWrapperClass implements Comparable 
    {
        public sObject sortMember;
        public String field;
        public boolean ascend;
        
        // Constructor
        public sortWrapperClass(sObject memberRecord,String fieldName,boolean sortOrd)
        {
            sortMember = memberRecord;
            field = fieldName;
            ascend = sortOrd;
        }
        
        public Integer compareTo(Object compareTo) 
        {    
            sortWrapperClass compareTomember = (sortWrapperClass)compareTo;
            Integer returnValue = 0;
            String sObj = ''; String subField = '';
            Boolean lookup = false;
            
            if(field.contains('.'))
            {
                sObj = field.substringBefore('.');
                subField = field.substringAfter('.');
                lookup = true;
            }
            
            if(lookup)
            {
                if ((String)sortMember.getsObject(sObj).get(subField) > (String) compareTomember.sortMember.getsObject(sObj).get(subField))
                {
                    returnValue = ascend ? -1 : 1;
                } 
                else if ((String)sortMember.getsObject(sObj).get(subField) < (String) compareTomember.sortMember.getsObject(sObj).get(subField))
                {
                    returnValue = ascend ? 1 : -1;
                }
            }
            else
            {
                if(field.containsIgnoreCase('date'))
                {
                    if ((DateTime)sortMember.get(field) > (DateTime) compareTomember.sortMember.get(field))
                    {
                        returnValue = ascend ? -1 : 1;
                    } 
                    else if ((DateTime)sortMember.get(field) < (DateTime) compareTomember.sortMember.get(field))
                    {
                        returnValue = ascend ? 1 : -1;
                    }
                }
                else
                    if(field.containsIgnoreCase('age'))
                {
                    if ((Decimal)sortMember.get(field) > (Decimal) compareTomember.sortMember.get(field))
                    {
                        returnValue = ascend ? -1 : 1;
                    } 
                    else if ((Decimal)sortMember.get(field) < (Decimal) compareTomember.sortMember.get(field))
                    {
                        returnValue = ascend ? 1 : -1;
                    }
                }
                else
                {
                    if ((String)sortMember.get(field) > (String) compareTomember.sortMember.get(field))
                    {
                        returnValue = ascend ? -1 : 1;
                    } 
                    else if ((String)sortMember.get(field) < (String) compareTomember.sortMember.get(field))
                    {
                        returnValue = ascend ? 1 : -1;
                    }
                }
            }
            
            return returnValue;       
        }
    }
    
    public PageReference refreshPage() {
        inputdateNumber = 30;
        findParticipants(Userinfo.getUserId());
        return null;
    }

    //ESESP-2525 changes starts
    @AuraEnabled
    public static String getOCQLink(){
        String OCQLink = [Select id, DeveloperName, Value_Text__c from SC_Utility__mdt where DeveloperName = 'OCQ_Link' and Active__c = true limit 1].Value_Text__c;
        return OCQLink;
    }
    
}