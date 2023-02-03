/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE           DEVELOPER   CR          DESCRIPTION                                                       

|  ===========    =========   =======     =========== 
                                                       
|  24-Nov-2014    Akhila    CR 2650602 -  Controller Class for SC_HomePage
   20-Mar-2015    Akhila    CR 2907264 -  New Homescreen Phase 2 changes                                                  
   29-oct-2015    Vamsee    CR 3104351 -  Automatically clear all Case Updates 
   04-Dec-2015    Sonia     CR 3242401 -  Home Screen Changes for First Update   
   25-Jan-2016    Deepak    CR 3249741 -  Changes for CCare Life Cycle part 2 
   02-Feb-2016    Vamsee    CR 3035271 -  Changes for Engagement Request SLA 
   11-May-2016    Vamsee    CR 3172971 -  Changes for Case Transition
   27-Jun-2016    Vamsee    CR 3396571 -  Changes for Support Geography
   25-Jul-2016    vamsee    CR 3473811 -  Ability to save Support Geography preference
   09-Jan-2016    Pinkesh   CR 3528581 -  Update CCare queue label prefixes from CC to ATS (Akamai Technical Support)
   27-Apr-2017    Pinkesh   ESESP-542  -  Added case transition feature for BOCC
   30-Jun-2017    Aditya    ESESP-534  -  Added SLA claculation for BOCC Milestones
   02-Aug-2017    Aditya    ESESP-671  -  Akapedia- Home 2.0 KSC icon color change implementation
   22-Nov-2017    Pinkesh   ESESP-746  -  KCS: Enhancements and Fixes for Akapedia Dashboard   
   12-Apr-2018    Sumanth   ESESP-445  -  Adjust IR Calculation in Mini Dashboard 
   25-Jun-2018    Vandhana  ESESP-319  -  OLA for Escalations (Renamed Engagement Requests to Escalations)
   24-Jul-2018    Sumanth   ESESP-1524 -  Hide ATS_External_Team_Queue escalations from Home_2.0 preset filter views
   24-Aug-2018    Vamsee    ESESP-1570 -  Removed Query Inside Loop
   26-FEB-2020    Harshil   ESESP-2917 -  Changed AMER Geo value to assign as NORTHAM for Exceda Migration
   24-APR-2020    Harshil   ESESP-3386 -  Added LATAM Geo filter
   22-May-2020	  Vamsee	ESESP-3567 -  Removed BOCC Transition Queue Reference
   09-Nov-2020	  Vamsee	ESESP-3015 -  Service Incident Lightning Migration
+=====================================================================================================*/
public without sharing class SC_HomePageCtrlV2 {

   
    public Id recTypeId;
    public Id SIrecTypeId;
    public String passRecId{get;set;}
    public String passMyRecId{get;set;}
    public Long sameDay{get;set;}
    public Long sameWeek{get;set;}
    public Long IR{get;set;}
    public Long ResSum{get;set;}
    public Long kb{get;set;}

    // added KCS Level for User
    public String kcsLevel{get;set;}
    public String kbarReportId{get;set;}
    public String kbarReportName{get;set;}
    public string metaDataDevName;

    public List<String> sumLOE{get;set;}
    public transient List<SC_SI_Service_Incident__c> lSI{get;set;}
    public transient String lQCaseERjson{get;set;}
    public transient String lMCaseERjson{get;set;} 
    public Integer cLimit;
    public Integer SILimit;
    public String defaultClause; 
    public String pickFlag{get;set;}
    public String reportId{get;set;}
    public String loeReportId{get;set;}
    public Integer totalCnt{get;set;}
    public Integer totalIRCnt{get;set;}
    public Integer totalResCnt{get;set;}
    public String DashboardFilter{get;set;}    
    public String SIFilter{get;set;}        
    public String MyFilter {get;set;}      
    public String QFilter {get;set;}
    //Field for EMEA Checkbox
    public boolean EMEACheckBox {get;set;}
    //Field for APJ Checkbox
    public boolean APJCheckBox {get;set;}
    //Field for NORTHAM Checkbox
    public boolean NORTHAMCheckBox {get;set;}
    //ESESP-3386:
    //Field for LATAM Checkbox
    public boolean LATAMCheckbox {get;set;}
    public String hiddenCaseId{get;set;}
    //List to Store the supported geography of the user.
    public List<User> UserPreference;
    //Flag for KCS Icon color
    public boolean kcsFlagRed{get;set;}
    
    public Boolean getenableLOEPolling() {
        if(SC_Streaming_Settings__c.getInstance('Enable LOE Streaming')!=null && 
           SC_Streaming_Settings__c.getInstance('Enable LOE Streaming').keyvalue__c == 'true') {
            return false;
        }
        else 
            return true;
    }
    
    public Boolean getenableSIPolling() {
        if(SC_Streaming_Settings__c.getInstance('Enable SI Streaming')!=null && 
           SC_Streaming_Settings__c.getInstance('Enable SI Streaming').keyvalue__c == 'true') {
            return false;
        }
        else 
            return true;
    }
    
    //Constructor
    public SC_HomePageCtrlV2(){
        pickFlag='false';
        reportId='';
        loeReportId='';
        UserPreference = new List<User>();
         UserPreference = Database.query('select supported_geography__c from user where id=\''+UserInfo.getUserId()+'\' Limit 1');
       //By default all the geos should be displayed If user doesnot set any preference 
        if(UserPreference[0].supported_geography__c == null){
            EMEACheckBox = true;
            NORTHAMCheckBox = true;
            //ESESP-3386:
            LATAMCheckBox = true;
            APJCheckBox = true;
        }
        //if user set preferences
        else{
            EMEACheckBox = UserPreference[0].supported_geography__c.contains('EMEA');
            NORTHAMCheckBox = UserPreference[0].supported_geography__c.contains('NORTHAM');
            //ESESP-3386:
            LATAMCheckBox = UserPreference[0].supported_geography__c.contains('LATAM');
            APJCheckBox = UserPreference[0].supported_geography__c.contains('APJ');
        }
        cLimit = Agent_Home_Collection_Limit__c.getValues('HomeScreenLimit').Collection_Limit__c.intValue();
        reportId= SCUserIdCustomSetting__c.getValues('HomeScreenReportId').UserId__c;
        loeReportId= SCUserIdCustomSetting__c.getValues('HomeScreenLOEReportId').UserId__c;
        SILimit = cLimit*2;
        defaultClause=' Order by CreatedDate desc Limit '+cLimit;
        //Invalid Case Record Type Id
        recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        //SI Rec Type Id
        SIrecTypeId = Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Service Incident').getRecordTypeId();
       
        DashboardFilter='This Month';
        SIFilter='24 Hours';
        MyFilter='My Work';
        QFilter='My Queues';
        updateDashboard();
        updateLOE();
        
        Environment_Setup__c environmentSetup = Environment_Setup__c.getInstance();
        metaDataDevName = environmentSetup.Environment_Type__c == 'Primary' ? 'AkapediaPrimary' : 'AkapediaDR';
        
        SC_AkapediaCsutomMdt__mdt akaMDT = [Select SC_KBAR_by_Month__c, SC_KBAR_by_Month_Name__c from SC_AkapediaCsutomMdt__mdt where DeveloperName = :metaDataDevName limit 1];
        kbarReportId = akaMDT.SC_KBAR_by_Month__c;
        kbarReportName = akaMDT.SC_KBAR_by_Month_Name__c;
    }    
    
    //Function to update the user geography preference
    public void updateUserPreference(){
        UserPreference[0].supported_geography__c = '';
        if(EMEACheckBox){
            UserPreference[0].supported_geography__c = 'EMEA';
        }
        if(APJCheckBox){
            UserPreference[0].supported_geography__c = UserPreference[0].supported_geography__c + ';APJ';
        }
        if(NORTHAMCheckBox){
            UserPreference[0].supported_geography__c = UserPreference[0].supported_geography__c + ';NORTHAM';
        }
        //ESESP-3386:
        if(LATAMCheckBox){
            UserPreference[0].supported_geography__c = UserPreference[0].supported_geography__c + ';LATAM';
        }
        try{
            update UserPreference[0];
        }
        catch(Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,e.getMessage()));
        } 
    }
    
    public void pickCaseER(){
        pickFlag='false';
        if(passRecId.startswith('500')){
                Case c = [Select Id,Owner.Type from Case where Id=:passRecId limit 1];
                if(c!=null && c.Owner.Type!='User') {
                c.OwnerId = UserInfo.getUserId();
                Database.DMLOptions dlo = new Database.DMLOptions();
                dlo.EmailHeader.triggerUserEmail = true;
                c.setOptions(dlo);
                try {
                    update c;
                    pickFlag='true';
                }
                catch(Exception e) {
                    pickFlag='false';
                }
                }
        }
        else{
                Engagement_Request__c e = [Select Id,Owner.Type from Engagement_Request__c where Id=:passRecId limit 1];
            if(e!=null && e.Owner.Type!='User') {
                e.OwnerId = UserInfo.getUserId();
                e.Assigned_To__c = UserInfo.getUserId();
                try {
                        update e;
                        pickFlag='true';
                }
                catch(Exception ex) {
                        pickFlag='false';        
                }
            }
        }
        populateQTable();
    }
    
    public void updateDashboard()
    {
        sameDay=sameWeek=IR=ResSum=kb=0;
        totalCnt=0;
        totalIRCnt=0;
        totalResCnt=0;
        Decimal sameDayCnt=0;
        Decimal sameWeekCnt=0;
        Decimal IRCnt=0;
        Decimal kbCount=0;
        Decimal resSumCnt=0;
        String Filter= '';
        String cMFilter='';

        //Code added as part of ESESP -445
        //Get the IR milestone type id
        String irMilestoneId =[SELECT Id,Name FROM MilestoneType WHERE Name = 'Initial Response' limit 1].Id;

        // KCS Level replaces KBAR
        Id currentUserId = UserInfo.getUserId();
        User currentUsr = [Select KCS_Level__c from User where Id = :currentUserId Limit 1];
        kcsLevel = currentUsr.KCS_Level__c;

        if(DashboardFilter=='This Month') {
            Filter=' and Resolved_Date__c = THIS_MONTH';
            cMFilter=' and Case.Resolved_Date__c = THIS_MONTH';
        }
        else if(DashboardFilter=='Quarter') {
            Filter=' and Resolved_Date__c = THIS_QUARTER';
            cMFilter=' and Case.Resolved_Date__c = THIS_QUARTER';                
        }
        else {
            Filter=' and Resolved_Date__c = THIS_YEAR';
            cMFilter=' and Case.Resolved_Date__c = THIS_YEAR';                
        }  
        totalCnt = Database.Countquery('Select count() from Case where OwnerId=\''+UserInfo.getUserId()+'\' and RecordTypeId=\''+ recTypeId + '\' and Sub_Type__c IN (\'Product Support\',\'Security Event\') and (NOT Account.Name like \'%Akamai%\') and '+ 'isClosed = true and Work_Type__c != \'Proactive\' '+Filter) ;
        
        totalResCnt = Database.Countquery('Select count() from Case where OwnerId=\''+UserInfo.getUserId()+'\' and RecordTypeId=\''+ recTypeId + '\' and Sub_Type__c IN (\'Product Support\',\'Security Event\') and (NOT Account.Name like \'%Akamai%\') and '+ 'isClosed = true and Do_Not_Show_in_Portal__c = False and Work_Type__c != \'Proactive\' '+Filter) ;
        
        totalIRCnt = Integer.ValueOf(Database.query('Select COUNT_DISTINCT(CaseId) c from CaseMilestone where Case.OwnerId=\''+UserInfo.getUserId()+'\' and Case.Sub_Type__c IN (\'Product Support\',\'Security Event\') and Case.RecordTypeId=\''+ recTypeId + '\''+
                                                    ' and Case.isClosed = true and MilestoneTypeId=\''+ irMilestoneId + '\'' + ' and Case.Do_Not_Show_in_Portal__c = False and (NOT Case.Account.Name like \'%Akamai%\') and Case.Work_Type__c != \'Proactive\' '+cMFilter)[0].get('c'));
                               
        if(totalCnt!=0) {
            sameDayCnt = Database.Countquery('Select count() from Case where OwnerId=\''+UserInfo.getUserId()+'\' and TTR__c <= 1 and TTR__c!=null and RecordTypeId=\''+ recTypeId + '\' and '+ 'isClosed = true and Sub_Type__c IN (\'Product Support\',\'Security Event\') and (NOT Account.Name like \'%Akamai%\') and Work_Type__c != \'Proactive\' '+Filter);
            
            sameWeekCnt = Database.Countquery('Select count() from Case where OwnerId=\''+UserInfo.getUserId()+'\' and TTR__c <= 7 and TTR__c!=null and RecordTypeId=\''+ recTypeId + '\' and Sub_Type__c IN (\'Product Support\',\'Security Event\') and '+
                                              'isClosed = true and (NOT Account.Name like \'%Akamai%\') and Work_Type__c != \'Proactive\' '+Filter);
            
            kbCount =  Database.Countquery('Select count() from Case where OwnerId=\''+UserInfo.getUserId()+'\' and Has_Article_Linked__c= True and RecordTypeId=\''+ recTypeId + '\' and Sub_Type__c IN (\'Product Support\',\'Security Event\') and '+
                                           'isClosed = true and (NOT Account.Name like \'%Akamai%\') and Work_Type__c != \'Proactive\' '+Filter);                                  
        }

        if(totalResCnt!=0) {
            resSumCnt = Database.Countquery('Select count() from Case where OwnerId=\''+UserInfo.getUserId()+'\' and RecordTypeId=\''+ recTypeId + '\' and Resolution_Sent__c = true and Sub_Type__c IN (\'Product Support\',\'Security Event\') and Do_Not_Show_in_Portal__c = False and '+
                                            'isClosed = True and (NOT Account.Name like \'%Akamai%\') and Work_Type__c != \'Proactive\' '+Filter);
        }  
            
        if(totalIRCnt!=0) {
            IRCnt = Integer.ValueOf(Database.query('Select COUNT_DISTINCT(CaseId) c from CaseMilestone where Case.OwnerId=\''+UserInfo.getUserId()+'\' and Case.RecordTypeId=\''+ recTypeId + '\' and Case.Sub_Type__c IN (\'Product Support\',\'Security Event\') and IsViolated=true'+
                                                   ' and Case.isClosed = true and MilestoneTypeId=\''+ irMilestoneId + '\'' + ' and Case.Do_Not_Show_in_Portal__c = False and (NOT Case.Account.Name like \'%Akamai%\') and Case.Work_Type__c != \'Proactive\' '+cMFilter)[0].get('c'));        
 }
        
        if(totalCnt!=0) {
            sameDay = (sameDayCnt/totalCnt*100).round();
            sameWeek = (sameWeekCnt/totalCnt*100).round();
            
            // KCS Level replaces KBAR
            kb = (kbCount/totalCnt*100).round();
            
        }

        if(totalResCnt!=0) {
            ResSum =  (resSumCnt/totalResCnt*100).round();        
        }
        
        if(totalIRCnt!=0) {
            IR = ((1-IRCnt/totalIRCnt)*100).round();        
        }
    }
    
    public void updateLOE() {
        sumLOE=new List<String>();
        Decimal totalLOE = (Decimal)([Select sum(LOE_hours__c) s from Task where OwnerId=:UserInfo.getUserId() and LOE_hours__c!=null and Akam_Created_Date__c >: dateTime.now()-0.5][0].get('s'));
        Decimal weeklyLOE = (Decimal)([Select sum(LOE_hours__c) s from Task where OwnerId=:UserInfo.getUserId() and LOE_hours__c!=null and Akam_Created_Date__c = THIS_WEEK][0].get('s'));
        if(totalLOE==null || totalLOE <1 ) {
                if(totalLOE==null)
                        sumLOE.add('0 Mins');
                else
                        sumLOE.add(Integer.ValueOf(totalLOE*60)+' Mins');
                        sumLOE.add('a');
        }
        else if(totalLOE<3){
                sumLOE.add(totalLOE+' Hours');
                sumLOE.add('b');
        }
        else if(totalLOE<5){
                sumLOE.add(totalLOE+' Hours');
                sumLOE.add('c');
        }
        else if(totalLOE<6){
            sumLOE.add(totalLOE+' Hours');
            sumLOE.add('d');
        }
        else{
            sumLOE.add(totalLOE+' Hours');
            sumLOE.add('e');
        }
        
        //Weekly LOE
        if(weeklyLOE==null || weeklyLOE <1 ) {
                if(weeklyLOE==null)
                        sumLOE.add('0 Mins');
                else
                        sumLOE.add(Integer.ValueOf(weeklyLOE*60)+' Mins');
        }
        else if(weeklyLOE<3){
                sumLOE.add(weeklyLOE+' Hours');
        }
        else if(weeklyLOE<5){
                sumLOE.add(weeklyLOE+' Hours');
        }
        else if(weeklyLOE<6){
                sumLOE.add(weeklyLOE+' Hours');
        }
        else{
                sumLOE.add(weeklyLOE+' Hours');
        }
    }
    
    public void suppressCaseUpdate_homectrl(){
        try{
            case c = new Case(id= hiddenCaseId);
            c.recent_update__c = false;
            update c;
        } 
        catch(Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,e.getMessage()));
        }
    }
    
    public void populateSITable() {
        lSI = new List<SC_SI_Service_Incident__c>();
        String SIwhereClause='';   
        if(SIFilter=='24 Hours') {
                SIwhereClause=' SI_Incident_Requested_Date__c>='+(DateTime.now()-1).formatGMT('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        }
        else if(SIFilter=='7 Days') {
                SIwhereClause=' SI_Incident_Requested_Date__c>='+(DateTime.now()-7).formatGMT('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        }
        else if(SIFilter=='Unmitigated') {
                SIwhereClause=' Status__c IN (\'Incident Request\',\'1: In Progress\')';
        }   
        else
                SIwhereClause=' Status__c NOT IN (\'Closed\',\'Canceled\',\'Rejected\')';
        lSI = Database.query('SELECT Id,Name,Title__c, Status__c, Impact_Started__c, Severity__c, SI_Incident_Requested_Date__c  FROM SC_SI_Service_Incident__c  WHERE '+SIwhereClause+' Order by SI_Incident_Requested_Date__c desc Limit '+SILimit);
    }
    
    public void populateMyTable() {
        List<CaseERWrapperClass> lMyCaseERwraps = new List<CaseERWrapperClass>();
        List<Case> lMyCase = new List<Case>();
        List<Engagement_Request__c> lMyER=new List<Engagement_Request__c>();
        Map<Id,CaseMilestone> mMyCaseMile = new Map<Id,CaseMilestone>();
        Map<Id,CaseMilestone> mMyFirstUpCaseMile = new Map<Id,CaseMilestone>();
        Map<Id,CaseMilestone> mMyCaseUpCaseMile = new Map<Id,CaseMilestone>();
        Map<Id,case_transition__c> caseIdTransitionMap = new Map<Id,case_transition__c>();
        String CaseClause='';
        String ERClause='';
    
        if(MyFilter=='My Work') {
            CaseClause=' OwnerId =\''+UserInfo.getUserId()+'\' and isClosed = False';
            ERClause=' OwnerId =\''+UserInfo.getUserId()+'\' ';
        }
        else if(MyFilter=='Hide Pending') {
            CaseClause=' OwnerId =\''+UserInfo.getUserId()+'\' and isClosed = False and Status !=\'Mitigated / Solution Provided\'';
            ERClause=' OwnerId =\''+UserInfo.getUserId()+'\' and Request_Status__c !=\'Pending\'';    
        }
        else {
                List<Id> lCaseFollowIds = new List<Id>();
                List<Id> lERFollowIds = new List<Id>();
                for(EntitySubscription en: [SELECT Id,ParentId,Parent.Type FROM EntitySubscription WHERE SubscriberId =:UserInfo.getUserId()]) {
                        if(en.Parent.Type=='Case')
                                lCaseFollowIds.add(en.ParentId);    
                        else
                                lERFollowIds.add(en.ParentId);        
                }
            CaseClause=' isClosed = False  and Id IN :lCaseFollowIds';
            ERClause=' Id IN :lERFollowIds';    
        }
        
        //CR 3242401: Modified query to add first update milestone details
        lMyCase =  Database.query('Select Id,CaseNumber,Override_Next_Case_Update__c ,AKAM_Case_ID__c,AccountId,Account.Name,Subject, Support_Level__c, Severity__c, AKAM_Created_Date__c, Case_Prod_Name__c,OwnerId,Owner.Name,Age_days__c,Status,Resolution_Sent__c,Recent_Update__c,Task_LOE__c,Support_Geography__c,has_active_transition__c, (Select Id,TargetResponseInMins,StartDate,isviolated,IsCompleted from CaseMilestones where milestonetype.Name IN (\'Initial Response\',\'First Update\', \'Case Update\',\'Time to Respond\')) from Case where'+CaseClause+defaultClause);        
        lMyER =  Database.query('Select Id,Name,Accept_Target_Mins__c,Accept_Completed__c,Accept_Violation__c,Accept_Target_Date__c, ER_Severity__c,Case__c,Case__r.AKAM_Case_ID__c,Case__r.AccountId,Case__r.Account.Name,Case__r.CaseNumber, Description__c, Case__r.Support_Level__c,AKAM_Created_Date__c,Case__r.Case_Prod_Name__c,Case__r.Resolution_Sent__c,OwnerId,Owner.Name,Request_Status__c,Case__r.Task_LOE__c,Age__c,Case__r.has_active_transition__c from Engagement_Request__c where '+ERClause+' and Request_Status__c NOT IN (\'Rejected\',\'Cancelled\',\'Closed\') '+defaultClause);    
    
        for(CaseMilestone cm: [Select Id,CaseId,TargetDate,milestonetype.Name,TargetResponseInMins,StartDate,isviolated,IsCompleted from caseMilestone where CaseId IN:lMyCase and milestonetype.Name IN ('Initial Response', 'First Update', 'Case Update','Time to Respond')]){
            if(cm.milestonetype.Name == 'Initial Response')
                mMyCaseMile.put(cm.CaseId,cm);
            else if(cm.milestonetype.Name == 'First Update' && cm.isCompleted == False)
                mMyFirstUpCaseMile.put(cm.CaseId,cm);
            else if(cm.milestonetype.Name == 'Case Update' && cm.isCompleted == False)
                mMyCaseUpCaseMile.put(cm.CaseId,cm);
            else if(cm.milestonetype.Name == 'Time to Respond')
                mMyCaseMile.put(cm.CaseId,cm);
            
        }
        for(Case_transition__c ct:[Select id,case__c,completed__C,time_remaining__c, violation_check__c, Start_Date__c,Shift_Tracker__c, Target_Shift__c,TargetDate__c  from case_transition__c where approved_date__c != null and case__C in :lMyCase order by createddate desc]) {
            //load only first record. order by createddate is trick here
            if (caseIdTransitionMap.get(ct.case__c) == null)  {  
                caseIdTransitionMap.put(ct.case__c,ct);
            }    
        }    
        
        //My work section
        CaseERWrapperClass cWrap;
        CaseERWrapperClass eWrap;
        for(Case c:lMyCase) {
            cWrap = new CaseERWrapperClass(c,mMyCaseMile,caseIdTransitionMap,new Map<Id,String>(),'mywork', mMyFirstUpCaseMile, mMyCaseUpCaseMile);
            lMyCaseERwraps.add(cWrap);
        }
    
        for(Engagement_Request__c e:lMyER) {
            eWrap = new CaseERWrapperClass(e,mMyCaseMile,caseIdTransitionMap,new Map<Id,String>(),'mywork');
            lMyCaseERwraps.add(eWrap);
        }
        lMCaseERjson = JSON.serialize(lMyCaseERwraps);
        lMyCaseERwraps.clear();
        lMyCase.clear();
        lMyER.clear();
        mMyCaseMile.clear();
    }

    public void populateQTable() {
        List<Id> lMyQueueIds = new List<Id>();    
        List<CaseERWrapperClass> lCaseERwraps = new List<CaseERWrapperClass>();
        Map<Id,CaseMilestone> mQCaseMile = new Map<Id,CaseMilestone>();
        List<Id> lAccId = new List<Id>();
        Map<Id,String> mAccTeam = new Map<Id,String>();
        List<Engagement_Request__c> lER=new List<Engagement_Request__c>();
        List<Case> lCase = new List<Case>();
        Map<Id,case_transition__c> caseIdTransitionMap = new Map<Id,case_transition__c>();
        System.debug(QFilter);
        
        
        //Custom setting to Exclude Queues
        SC_Utility__mdt ExcludeMeta = [SELECT Value__c,Active__c,MasterLabel from SC_Utility__mdt where MasterLabel='Excluded Queue Home Dashboard'];
        List<String> ExcludeQueues = ExcludeMeta.Value__c.split(',');
        
        
        //List used to add the geographies based on user selection
        List<String> Geo = new List<String>();
        if(EMEACheckBox){
            Geo.add('EMEA');
        }
        if(APJCheckBox){
            Geo.add('APJ');
        }
        if(NORTHAMCheckBox){
            // Changes by Harshil:
            //Changed AMER to NORTHAM as a part of Exceda SC Migration - ESESP-2917
            Geo.add('NORTHAM');
        }
        //ESESP-3386:
        if(LATAMCheckBox){
            Geo.add('LATAM');
        }
        //Set of CCare Queue Ids for ER and Case and initializing based on Filter
        if(QFilter=='My Queues') {
                for(GroupMember g: [Select Group.Name,Group.Id,Group.DeveloperName from GroupMember where UserorGroupId =:UserInfo.getUserId() and Group.Type='Queue']) {
                    lMyQueueIds.add(g.Group.Id);
            }
        }
        //Query Trabsition Queue Details if the filter is Transition Queue
        else if(QFilter=='ATS_Transition_Queue'){
            lMyQueueIds = new List<Id>();
            List<group> transitionQueueList = [SELECT Id, Name, Email FROM GROUP
                                               WHERE type = 'queue' AND Name = 'ATS_Transition_Queue'];
                if (transitionQueueList != null && transitionQueueList.size() > 0 ){
                    lMyQueueIds.add(transitionQueueList.get(0).Id);
                }
            transitionQueueList.clear();
        }
        else{
                for(QueueSobject q : [Select Id, SobjectType, QueueId,Queue.DeveloperName from QueueSobject where (SobjectType = 'Engagement_Request__c' OR SobjectType = 'Case') and (Queue.DeveloperName like 'CC%' or Queue.DeveloperName like 'ATS%')and Queue.DeveloperName not in:ExcludeQueues]){
                    if(QFilter=='All CCare Queues - Escalations') {
                        if(q.SobjectType == 'Engagement_Request__c')
                            lMyQueueIds.add(q.QueueId);
                    }
                    else if(QFilter=='All CCare Queues - Cases') {
                        if(q.SobjectType == 'Case')
                            lMyQueueIds.add(q.QueueId);
                    }
                    else {
                        lMyQueueIds.add(q.QueueId);
                    }         
                }
            }

        
        lCase = [Select Id,CaseNumber,AKAM_Case_ID__c,AccountId,Account.Name,Subject, Support_Level__c, Severity__c, AKAM_Created_Date__c, Case_Prod_Name__c,OwnerId,Owner.Name,Age_days__c,Status,Recent_Update__c,Task_LOE__c,Support_Geography__c,has_active_transition__c,(Select isViolated, TimeRemainingInMins from CaseMilestones limit 1) from Case where OwnerId IN :lMyQueueIds and isClosed = False and support_geography__c IN :Geo order by CreatedDate desc limit :cLimit];
        lER = [Select Id,Name,Accept_Target_Mins__c,Accept_Completed__c,Accept_Violation__c,Accept_Target_Date__c, ER_Severity__c,Case__r.AKAM_Case_ID__c,Case__r.AccountId,Case__r.Account.Name,Case__r.CaseNumber, Description__c, Case__r.Support_Level__c,AKAM_Created_Date__c,Case__r.Case_Prod_Name__c,OwnerId,Owner.Name,Case__r.Recent_Update__c,Request_Status__c,Case__r.Task_LOE__c,Age__c,case__r.has_active_transition__c from Engagement_Request__c where OwnerId IN :lMyQueueIds and Request_Status__c NOT IN ('Closed','Cancelled','Rejected') order by CreatedDate desc limit :cLimit];             
        
        for(CaseMilestone cm: [Select Id,CaseId,TargetResponseInMins,StartDate,isviolated,IsCompleted from caseMilestone where CaseId IN:lCase and milestonetype.Name='Initial Response']) {
                mQCaseMile.put(cm.CaseId,cm);
        }
        for(Case_transition__c ct:[Select id,case__c,completed__C,time_remaining__c, violation_check__c, Start_Date__c,Shift_Tracker__c, Target_Shift__c,TargetDate__c   from case_transition__c where approved_date__c != null and case__c in :lCase order by createddate desc]) {
            //load only first record. order by createddate is trick here
            if (caseIdTransitionMap.get(ct.case__c) == null)  {  
                caseIdTransitionMap.put(ct.case__c,ct);
                }    
        }    
        if(lCase.size()>0) {
                for(Case c: lCase) {
                lAccId.add(c.AccountId);
            }
        }
        if(lAccId.size()>0) {
                for(AccountTeamMember at: [Select Id,AccountId, TeamMemberRole,User.Name from AccountTeamMember where AccountId IN:lAccId and TeamMemberRole = 'Technical Support - Primary']) {
                if(mAccTeam.containskey(at.AccountId))
                        mAccTeam.put(at.AccountId,'112');
                else
                        mAccTeam.put(at.AccountId,at.User.Name);
            }
        }   
        CaseERWrapperClass cWrap;
        CaseERWrapperClass eWrap;
        //Queue Section
        for(Case c:lCase) {
            cWrap = new CaseERWrapperClass(c,mQCaseMile,caseIdTransitionMap,mAccTeam,'queue',null,null);
            lCaseERwraps.add(cWrap);
        }
        
        for(Engagement_Request__c e:lER) {
            eWrap = new CaseERWrapperClass(e,mQCaseMile,caseIdTransitionMap,mAccTeam,'queue');
            lCaseERwraps.add(eWrap);
        }
        lQCaseERjson = JSON.serialize(lCaseERwraps); 
        lMyQueueIds.clear();
        lCaseERwraps.clear();
        mQCaseMile.clear();
        lAccId.clear();
        mAccTeam.clear();
        lER.clear();
        lCase.clear();
    }
        
    public without sharing Class CaseERWrapperClass{       
        public String qicon{get;set;}
        public List<String> qList{get;set;}
        public String qSLA{get;set;}
        public boolean hasActiveTransition{get;set;}
        public case_transition__c caseTransitionDetails{get;set;}
        //Variable to store the case transition ID
        public String ctObjectId{get;set;}
        
        public String minsToDay(Long tm) {
            String D= string.valueOf(tm/1440)+'d';
            if(math.mod(tm,1440)!=0)
            return (D+' '+minsToHrs(math.mod(tm,1440)));
            else
            return D;
        }
    
        public String minsToHrs(Long tm) {
            String H = string.valueof(tm/60)+'h';
            String m = math.mod(tm,60)+'m';
                if(math.mod(tm,60)==0)
                        return H;
                else if(tm/60==0)
                        return m;
                else
                        return (H+' '+m);
        }
    
        public CaseERWrapperClass(Case c,Map<Id,CaseMilestone> mapCaseMile,Map<Id,case_transition__c> transitionMap,Map<Id,String> mAccTeam,String TableType, Map<Id,CaseMilestone> mapCaseFirstUpMile, Map<Id,CaseMilestone> mapCaseUpMile) {
                qList=new List<String>();
                String a='';
                case_transition__c ctObject = transitionMap.get(c.id);
            //0- AKam CAse Id
            qList.add(c.AKAM_Case_ID__c);
            //1-Case SFDC Id  
            //This if condition will add the case transition ID
            if((c.has_active_transition__c == true || c.owner.name == 'ATS_Transition_Queue') && ctObject!= null){
               this.ctObjectId = ctObject.id;
            }
                qList.add(c.Id);
            
            //2-Account Name
            qList.add(c.Account.Name==null?'':c.Account.Name);
            //3-Account Id
            qList.add(c.AccountId==null?'':c.AccountId);      
            //4-Subject
            qList.add(c.Subject==null?'':c.Subject);
            //5-Support Level
            qList.add(c.Support_Level__c==null?'':c.Support_Level__c);
            //6-Severity
            qList.add(c.Severity__c==null?'':c.Severity__c);
            //7-SLA
            Long t =-1;
            
            if(mapCaseMile.ContainsKey(c.Id)) {
                t = mapCaseMile.get(c.Id).TargetResponseInMins - (DateTime.Now().getTime() - mapCaseMile.get(c.Id).StartDate.getTime())/60000;
            }
            if(!mapCaseMile.ContainsKey(c.Id)) {
                qList.add('z');
            }
            else if(mapCaseMile.get(c.Id).IsCompleted) {
                qList.add('y');
            } 
            else {
                qList.add(String.valueOf(t));
            }
            //8- Related - blank for Case
            //Target shift should be displayed For Cases with Transition
            if(ctObject!=null){
                if(ctObject.Shift_Tracker__c && ctObject.Target_Shift__c!=null){
                    qList.add(ctObject.Target_Shift__c);
                }
                else
                    qList.add('');  
            }
            else{
                qList.add('');  
            }
              
            //9 - Object Type, Case/ER
            qList.add('case');
            if(TableType=='queue') {
                //10-Account TeamMember
                if(!mAccTeam.containsKey(c.AccountId)) {
                    qList.add('z');
                }
                else if(mAccTeam.get(c.AccountId)!='112') {
                    qList.add(mAccTeam.get(c.AccountId));
                }
                else {
                    qList.add('multiple');
                }
                //11-Akam Created Date
                qList.add(c.AKAM_Created_Date__c==null?'':String.ValueOf(c.AKAM_Created_Date__c));
                //12-Case Product
                qList.add(c.Case_Prod_Name__c==null?'':c.Case_Prod_Name__c);
                //13-Queue
                qList.add(c.Owner.Name);
                qList.add(c.OwnerId);
                //15-formatted date
                //Start Date should be displayed For Cases with Transition
                if(ctObject!=null){
                    qList.add(ctObject.Start_Date__c==null?'':String.ValueOf(ctObject.Start_Date__c.format()));
                }
                else{
                    qList.add(c.AKAM_Created_Date__c==null?'':String.ValueOf(c.AKAM_Created_Date__c.format()));
                }
             }
            else {    
                //10-Status
                qList.add(c.Status==null?'':c.Status);
                //11-Age
                qList.add(String.valueOf(c.Age_days__c));
                //12-Alert
                qList.add(c.Recent_Update__c==true?'1':'2');
                //13-LOE
                qList.add(String.ValueOf(c.Task_LOE__c==null?0:c.Task_LOE__c)); 
                //14-Resolution Sent
                qList.add(c.Resolution_Sent__c==true?'t':'z');
                //start of changes for CR 3242401
                //15-Update 
                Long updateTime =-1;
                if(c.CaseMilestones != null && c.CaseMilestones.size()>0) {
                    if(mapCaseFirstUpMile != null && mapCaseFirstUpMile.get(c.Id) != null )
                        updateTime = (mapCaseFirstUpMile.get(c.Id).TargetDate.getTime() - DateTime.Now().getTime())/60000;
                    else if(c.Override_Next_Case_Update__c != null)
                        updateTime = (c.Override_Next_Case_Update__c.getTime() - DateTime.Now().getTime())/60000;
                    else if(mapCaseUpMile != null && mapCaseUpMile.get(c.Id) != null)
                        updateTime = (mapCaseUpMile.get(c.Id).TargetDate.getTime() - DateTime.Now().getTime())/60000;
                }
                if(updateTime != -1){
                   qList.add(String.valueOf(updateTime));
                }
                else{
                    qList.add('z');
                }
                //end of changes for CR 3242401
                
            }
            //16-Geo
                qList.add(c.Support_Geography__c);
            this.hasActiveTransition = c.has_active_transition__c;
            this.caseTransitionDetails = transitionMap.get(c.id);
     }
   
     public CaseERWrapperClass(Engagement_Request__c e,Map<Id,CaseMilestone> mapCaseMile,Map<Id,case_transition__c> transitionMap,Map<Id,String> mAccTeam,String TableType) { 
         qList=new List<String>();
         String a='';
         //0- ER Name
         qList.add(e.Name);
         //1-ER SFDC Id  
         qList.add(e.Id);
         //2-Account Name
         qList.add(e.Case__r.Account.Name==null?'':e.Case__r.Account.Name);
         //3-Account Id
         qList.add(e.Case__r.AccountId==null?'':e.Case__r.AccountId);      
         //4-Subject
         qList.add(e.Description__c==null?'':e.Description__c);
         //5-Support Level
         qList.add(e.Case__r.Support_Level__c==null?'':e.Case__r.Support_Level__c);
         //6-Severity
         qList.add(e.ER_Severity__c==null?'':e.ER_Severity__c);
         //7-SLA
         // Changes done by vamsee CR - 3035271
         if(e.Accept_Target_Mins__c ==null){
              qList.add('z');
             
             
         }
         else if(e.Accept_Completed__c== true && e.Accept_Violation__c == false){
              qList.add('y');
         }
         else{
              qList.add(String.valueOf((e.Accept_Target_Date__c.getTime() - DateTime.Now().getTime())/60000));
         }
         /*
         Long t =-1;
         if(mapCaseMile.ContainsKey(e.Case__c)) {
             t = mapCaseMile.get(e.Case__c).TargetResponseInMins - (DateTime.Now().getTime() - mapCaseMile.get(e.Case__c).StartDate.getTime())/60000;
         }
         if(!mapCaseMile.ContainsKey(e.Case__c)) {
             qList.add('z');
         }       
         else if(mapCaseMile.get(e.Case__c).IsCompleted) {
             qList.add('y');
         }
         else {
             qList.add(String.valueOf(t));
         }*/
         //Vamsee changes end here
         //8- Related - blank for Case
         qList.add(e.Case__r.Akam_Case_Id__c==null?'':e.Case__r.Akam_Case_Id__c);    
         //9 - Object Type, Case/ER
         qList.add('er');
         if(TableType=='queue') {
         //10-Account TeamMember
                if(!mAccTeam.containsKey(e.Case__r.AccountId)) {
                    qList.add('z');
                }
                else if(mAccTeam.get(e.Case__r.AccountId)!='112') {
                    qList.add(mAccTeam.get(e.Case__r.AccountId));
                }
                else {
                    qList.add('multiple');
                }
                 //11-Akam Created Date
                 qList.add(e.AKAM_Created_Date__c==null?'':String.ValueOf(e.AKAM_Created_Date__c));
                 //12-Case Product
                 qList.add(e.Case__r.Case_Prod_Name__c==null?'':e.Case__r.Case_Prod_Name__c);
                 //13-Queue
                 qList.add(e.Owner.Name);
                 qList.add(e.OwnerId);         
                 //15-Formatted Date
                 qList.add(e.AKAM_Created_Date__c==null?'':String.ValueOf(e.AKAM_Created_Date__c.format()));
                 //16-Case Id
                 qList.add(e.Case__c);
         }
         else {    
             //10-Status
             qList.add(e.Request_Status__c==null?'':e.Request_Status__c);
             //11-Age
             qList.add(String.ValueOf(e.Age__c));
             //12-Alert
             qList.add('2');
             //13-LOE
             qList.add(String.ValueOf(e.Case__r.Task_LOE__c==null?0:e.Case__r.Task_LOE__c));      
             //14-Resolution Sent
             qList.add(e.Case__r.Resolution_Sent__c==true?'t':'z');
             //start of changes for CR 3242401
             //15-Update 
             qList.add('z');
             //16-Case Id
             qList.add(e.Case__c);
             //end of changes for CR 3242401
         }
         this.hasActiveTransition = e.case__r.has_active_transition__c;
         this.caseTransitionDetails = transitionMap.get(e.case__c);
       }          
    }
    
    public void isKCSLevelRed(){
        SC_AkapediaController sc_akapedia = new SC_AkapediaController();
        kcsFlagRed = sc_akapedia.isKCSFlagRed;
    }
}