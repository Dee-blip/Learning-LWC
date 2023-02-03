/*
Author          : Sumukh SS
Description     : Apex Controller for Akatec Lightning HomePage and Case Detail Page(Image Banner) 
Test Class - SC_Akatec_Lightning_TC

Date                        Developer             JIRA #                      Description                                                       
------------------------------------------------------------------------------------------------------------------
08 February 2019        Sumukh SS        ESESP-1900     Akatec Case Lightning Home Page
10 April 2019           Sumukh SS        ESESP-2105     Additional Features for Escalations + SLA Calculations( Case override & Transition)
15 July 2019            Sumukh SS        ESESP-2314     Additional Features demoed to Jackson as mentioned in Jira
20 FEB 2020             Harshil          ESESP-2917     Additional Features for dynamic case and escalation geo color assignment and split AMER filter support into NORTHAM AND LATAM filters
30 MAR 2020             Sharath Prasanna ESESP-1342     BOCC Migration. Adding the BOCC EScalation record type to the All Escalation query filter
27 OCT 2021             Jay              ESESP-6265     Added LIMIT 50000 to unbounded SOQLs
------------------------------------------------------------------------------------------------------------------
*/

public class SC_Akatec_Lightning_Homepage {
    
    // Map to store Geo Name + Color Code
    public static Map<string, string> geoName_colorCode = new Map<string, string>{'NORTHAM' => 'Orange',
        'EMEA' => 'Green',
        'LATAM'=> 'Grey',
        'APJ' => 'Purple'};
    
    public class sub_Case_Wrapper{
        @AuraEnabled public  Case EachCaseRec{get;set;}
        @AuraEnabled public  String SLA{get;set;}
        @AuraEnabled public  integer SLAinminutes{get;set;}
        @AuraEnabled public  String SLA_Color{get;set;}
        @AuraEnabled public string TSE_Primary {get;set;}   
        @AuraEnabled public string LiveChatId {get;set;}
        @AuraEnabled public string GeoColor{get;set;}
        
    }
    
    //Wrapper for Escalations
    public class sub_Esc_Wrapper{
        @AuraEnabled public  Engagement_Request__c EachEscRec{get;set;}
        @AuraEnabled public  String SLAEsc{get;set;}
        @AuraEnabled public  String Type{get;set;}
        @AuraEnabled public  String SLA_Color{get;set;}
        @AuraEnabled public string GeoColor{get;set;}
    }
    
    //Method -1 : Getting user session ID for Streaming API
    @AuraEnabled
    public static String getSessionId() {
        return UserInfo.getSessionId();
    }
    
    @AuraEnabled
    public static String getprofileId() {
        return UserInfo.getprofileid();
    }
    
    //Method - 2 : Case Transition Image Banner 
    @AuraEnabled 
    public static String getTargetShift(Id caseId) {
        Case_Transition__c ct= [SELECT Id, Name, Target_Shift__c  FROM Case_Transition__c where case__c =:caseId order by createddate desc limit 1];        
        return ct.Target_Shift__c;
    } 
    
    
    //Method - 3 : Gets Queue Cases (Dynamic Query Generation)
    @AuraEnabled
    public static List<sub_Case_Wrapper> getCases(string IsUpsert,string userID,list<String> SelectedGeoFromUser, string QueryType)
    {   
        //For upserting user selected geography
        if(IsUpsert== 'true'){
            saveSelectedFilters(userID,SelectedGeoFromUser);
        }
        
        //Map for storing AccountID + All TSE Primary names
        Map<string,string> accountId_TSEPrimNameMap=new Map<string,string>();
        
        List<sub_Case_Wrapper> sub_Case_Wrapper_List;
        string MasterQuery='';
        List<Case> CaseHome= new List<Case>();
        
        string milestoneSLA;
        //Calling method which returns the list of saved geographies for the user
        list <string> selectedGeo=getSavedGeo(userID);
        
        //Initializing the dynamic query
        string dynamicQuery=' and Support_Geography__c in (';
        if(selectedGeo.size()==1){ 
            dynamicQuery=dynamicQuery + '\''+selectedGeo[0]+'\')';
        }
        else if(selectedGeo.size()==4){
            dynamicQuery='';
        }
        else { 
            
            for(integer i=0;i<selectedGeo.size()-1;i++)
            {
                dynamicQuery=dynamicQuery + '\''+selectedGeo[i]+'\''+',';
            }
            dynamicQuery=dynamicQuery + '\''+selectedGeo[selectedGeo.size()-1]+'\''+')';
        } 
       
        dynamicQuery=dynamicQuery+' order by createddate desc LIMIT 200';
        //Query for all cases subscribed by the user
        if(QueryType=='My Queues'){
          
            string getuserid=UserInfo.getUserId();
            MasterQuery='SELECT id,Case_In_Transition_Queue__c, has_active_transition__c  ,CaseNumber,Account.Name, Account.BillingCountry , AccountId, Work_Type__c ,Severity__c ,Support_Level__c ,akam_case_id__c,Age_days__c ,subject, Case_Owner_Name__c,Support_Geography__c,(select TimeRemaininginMins,TargetDate from CaseMilestones where IsCompleted = false ),(Select id,time_remaining__c from Case_Transitions__r where approved_date__c != null) FROM Case where ownerid IN (Select GroupId from GroupMember where UserorGroupId =:getuserid and Group.Type=\'Queue\') and isClosed = False';
        }
        //Query for all technical cases
        else if(QueryType=='All Queues'){
            SC_Utility__mdt ExcludeMeta = [SELECT Value__c,Active__c,MasterLabel from SC_Utility__mdt where MasterLabel='Excluded Queue Home Dashboard'];
            List<String> ExcludeQueues = ExcludeMeta.Value__c.split(',');
            set<id> queueid= new set<id>();
            for(QueueSobject q : [Select Id, SobjectType, QueueId,Queue.DeveloperName from QueueSobject where SobjectType = 'Case' and (Queue.DeveloperName like 'ATS%' OR Queue.DeveloperName like 'CC%') and Queue.DeveloperName not in:ExcludeQueues])
            {
                queueid.add(q.QueueId);
            }
            MasterQuery='SELECT id,Case_In_Transition_Queue__c, has_active_transition__c  ,CaseNumber,Account.Name, Account.BillingCountry , AccountId, Work_Type__c ,Severity__c ,Support_Level__c ,akam_case_id__c,Age_days__c ,subject, Case_Owner_Name__c,Support_Geography__c,(select TimeRemaininginMins,TargetDate from CaseMilestones where IsCompleted = false ),(Select id,time_remaining__c from Case_Transitions__r where approved_date__c != null) FROM Case where recordtype.name=\'Technical\' and isClosed = False and ownerid IN :queueid';
        }
        
        MasterQuery=MasterQuery+dynamicQuery;
        
        // Querying with the new dynamic query constructed
        CaseHome=Database.query(MasterQuery); 
        
        //contains the tse mapping for each unique account in the case list
        accountID_TSEPrimNameMap = getAccountTeamDetails(CaseHome);
        
        sub_Case_Wrapper_List= new List<sub_Case_Wrapper>();
        sub_Case_Wrapper Each_sub_Case_Wrapper;
        
        
        for(case eachCaserec : CaseHome){
            
            
            milestoneSLA = null;
            
            // Initializing Wrapper Variable with default values
            Each_sub_Case_Wrapper = new sub_Case_Wrapper();
            Each_sub_Case_Wrapper.SLA = '';
            Each_sub_Case_Wrapper.SLA_Color = ' ';
            
            
            // Assigning Case record
            Each_sub_Case_Wrapper.EachCaseRec = eachCaserec;
            
            //Assigning Color based on Geography
            assignGeoColor(Each_sub_Case_Wrapper);
            
            // Each_sub_Case_Wrapper.CaseCreatedDate=eachCaserec.CreatedDate.format();
            
            Each_sub_Case_Wrapper.TSE_Primary = (accountID_TSEPrimNameMap.get(eachCaserec.AccountId));
            //Calculating SLA for cases which have an active transition 
            if(eachCaserec.has_active_transition__c==true && !eachCaserec.Case_Transitions__r.isempty() && eachCaserec.Case_Transitions__r[0].time_remaining__c!=null)
            {   
                string TimeRemaininginMins = string.valueOf(eachCaserec.Case_Transitions__r[0].time_remaining__c);
                integer index=TimeRemaininginMins.indexOf('.');
                integer timerem=integer.valueOf(TimeRemaininginMins.substring(0,index));
                if(timerem<0) {Each_sub_Case_Wrapper.SLA = 'Miss' ; Each_sub_Case_Wrapper.SLAinminutes=timerem; Each_sub_Case_Wrapper.SLA_Color = 'Red'; }
                else
                {Each_sub_Case_Wrapper.SLA = timerem + 'm' ; Each_sub_Case_Wrapper.SLAinminutes=timerem; Each_sub_Case_Wrapper.SLA_Color = 'Green'; }
            }
           
            // Milestone Details
            else if(eachCaserec.CaseMilestones.size() > 0 && eachCaserec.CaseMilestones != Null){
                
                milestoneSLA = eachCaserec.CaseMilestones[0].TimeRemaininginMins;string SLAValue;DateTime milestoneTargetDate;     
                
                SLAValue=milestoneSLA;milestoneTargetDate=eachCaserec.CaseMilestones[0].TargetDate; Integer getMinuteValue;
                
                if(SLAValue == '00:00'){ // Means already violated & Calculate the overdue
                    
                    getMinuteValue = integer.valueOf((milestoneTargetDate.getTime()/1000/60 - system.now().getTime()/1000/60) );
                    Each_sub_Case_Wrapper.SLAinminutes=getMinuteValue;
                    Each_sub_Case_Wrapper.SLA = '-'+ (getMinuteValue/60 * -1) + 'h ' +  Math.mod(getMinuteValue * -1,60) + 'm';
                }
                else
                {
                    getMinuteValue = integer.valueOf(SLAValue.substring(0,SLAValue.indexOf(':')));
                    Each_sub_Case_Wrapper.SLAinminutes=getMinuteValue;
                    Each_sub_Case_Wrapper.SLA = getMinuteValue/60 + 'h ' +  Math.mod(getMinuteValue,60) + 'm';
                }
                
                // For SLA Color
                if (getMinuteValue <= 10 && getMinuteValue > 0){ Each_sub_Case_Wrapper.SLA_Color = 'Orange'; // Set Orange
                                                               }
                else if (getMinuteValue <= 0) Each_sub_Case_Wrapper.SLA_Color = 'Red'; // Set Red
                else Each_sub_Case_Wrapper.SLA_Color = 'Green';
                
                
                
            }

            // Adding to Wrapper List
            sub_Case_Wrapper_List.add(Each_sub_Case_Wrapper);
        }
        
        
        return sub_Case_Wrapper_List;
    }
    
    //Method - 4: Getting TSE details for each account
    @AuraEnabled
    public static Map<string,string> getAccountTeamDetails(List<Case> allCaseList){
        
        // Map to store Account Id + TSE PRimary Team Member Name
        Map<string,string> accountID_TSEPrimNameMap = new Map<string,string>();
        
        // set to store all Unique Account Ids
        set<Id> uniqueAccountIds = new set<Id>();
        
        // String for Map Key & Value
        string mapKey;
        string mapValue;
        
        // Loop for all the Cases
        for(case eachCaseRec : allCaseList){
            
            uniqueAccountIds.add(eachCaseRec.AccountId);
        }
        
        // If Size > 0, then Query
        if(uniqueAccountIds.size() > 0){
            
            // Query On Account Team Member
            for(AccountTeamMember eachMember : [select AccountId,TeamMemberRole,User.Name from AccountTeamMember where 
                                                TeamMemberRole IN ('Technical Support - Primary') and AccountId IN :uniqueAccountIds ] ){
                                                    
                                                    mapKey = eachMember.AccountId ;
                                                    
                                                    if(accountID_TSEPrimNameMap.get(mapKey) == null){
                                                        
                                                        mapValue = eachMember.User.Name;    
                                                    }
                                                    else
                                                    {
                                                        mapValue = accountID_TSEPrimNameMap.get(mapKey) + ',' + eachMember.User.Name;
                                                    }
                                                    
                                                    accountID_TSEPrimNameMap.put(mapKey, mapValue);                     
                                                }
        }
        uniqueAccountIds.clear();
        
        return accountID_TSEPrimNameMap;
    }
    
    // Method - 5 : Gets the saved geography in the user filters. If not available, sets it to a default value
    @AuraEnabled
    public static list <string> getSavedGeo(string userID)
    {
        List<SC_QM_User_Filter__c> selectedgeo = new List<SC_QM_User_Filter__c>();
        selectedgeo=[select User_Id__c,Supported_Geography__c from SC_QM_User_Filter__c WHERE User_Id__c=:userID limit 1];
        //If no records then upsert with all geographies and userID
        if(selectedgeo.size() <1){
            SC_QM_User_Filter__c newrow= new SC_QM_User_Filter__c(Supported_Geography__c = 'EMEA;APJ;NORTHAM;LATAM',User_Id__c=userID);
            selectedgeo.add(newrow);
            upsert selectedgeo;
        }
        //If record exists but geography is null then just fill the geographies
        else if(selectedgeo[0].Supported_Geography__c==null)
        {
            selectedgeo[0].Supported_Geography__c='EMEA;APJ;NORTHAM;LATAM';
            upsert selectedgeo;
        }
        //Converting picklist values to string
        List<String> returnAllGeos = new List<String>();
        returnAllGeos.addAll(selectedgeo[0].Supported_Geography__c.split(';'));
        return returnAllGeos;
        
    }
    
    
    //Method - 6 : Saves the user selected Geographies in SC_QM_User_Filter__c object
    public static void saveSelectedFilters(string userID,list<String> SelectedGeoFromUser)
        
    {
        
        SC_QM_User_Filter__c upsertUserData = new SC_QM_User_Filter__c(User_Id__c=userID, Supported_Geography__c = String.join(SelectedGeoFromUser,';'));
        upsert upsertUserData User_Id__c;
    }
    
    //Method -7 : Assigns the case to the current user
    @AuraEnabled
    public static string assignCaseToUser(string userID, string CaseID)
    {
        
        try{
            case updateowner = new case(id=CaseID,ownerid=userID);
            update updateowner;
            return 'true';
        }
        catch (exception e)
        {
            return e.getMessage();
        }
        
    }
    
    //Method - 8 : Method for getting open cases in for the user + Team Open Cases if the Manager is viewing
    @AuraEnabled 
    public static List <sub_Case_Wrapper> getMyopenCases(string userID,string QueryType)
    {           
        List<sub_Case_Wrapper> sub_Case_Wrapper_List;
        Map<string,string> CaseIdAkaChatTranscript_Map;
        List<Case> CaseHome= new List<Case>();
        string milestoneSLA;
        if(QueryType=='MyOpenCases'){
            CaseHome = [SELECT id,CaseNumber,Account.Name , Account.BillingCountry, Age_days__c ,Override_Next_Case_Update__c,Next_Action__c,Work_Type__c ,Task_LOE__c ,Severity__c ,Support_Level__c ,akam_case_id__c,status,subject,Recent_Update__c,Support_Geography__c, 
                        (select id,TimeRemaininginMins,TargetDate from CaseMilestones where IsCompleted = false order by TimeRemaininginMins desc) 
                        FROM Case where ownerid=:userID and isClosed=false order by createddate desc limit 200]; 
        }
        else if(QueryType=='MyTeamCases')
        {
            CaseHome = [SELECT id,CaseNumber,Account.Name , Account.BillingCountry, Override_Next_Case_Update__c,Next_Action__c,Work_Type__c ,Task_LOE__c ,Severity__c ,Support_Level__c ,akam_case_id__c,status,subject,Recent_Update__c,Support_Geography__c, Case_Owner_Name__c ,
                        (select id,TimeRemaininginMins,TargetDate from CaseMilestones where IsCompleted = false order by TimeRemaininginMins desc) 
                        FROM Case where ownerid IN (select id from user where managerid=:UserInfo.getUserId() and isactive=true) and isClosed=false and Sub_Type__c!='CMP Alerts' order by createddate desc limit 200]; 
        }
        
        if(QueryType=='MyOpenCases'){
            
            CaseIdAkaChatTranscript_Map = getAkaChatID(CaseHome);
            
        }
        sub_Case_Wrapper_List= new List<sub_Case_Wrapper>();
        sub_Case_Wrapper Each_sub_Case_Wrapper;
        
        
        
        for(case eachCaserec : CaseHome){
            
            milestoneSLA = null;
            
            // Initializing Wrapper Variable with default values
            Each_sub_Case_Wrapper = new sub_Case_Wrapper();
            Each_sub_Case_Wrapper.SLA = '';
            Each_sub_Case_Wrapper.SLA_Color = ' ';            
            
            // Assigning Case record
            Each_sub_Case_Wrapper.EachCaseRec = eachCaserec;
            
            //Assigning Color based on Geography
            assignGeoColor(Each_sub_Case_Wrapper);
            
            if(QueryType=='MyOpenCases'){
                
                Each_sub_Case_Wrapper.LiveChatId = CaseIdAkaChatTranscript_Map.get(eachCaserec.id);}
            
            
            // Milestone Details
            if(eachCaserec.CaseMilestones.size() > 0 && eachCaserec.CaseMilestones != Null){
                
                milestoneSLA = eachCaserec.CaseMilestones[0].TimeRemaininginMins; string SLAValue; DateTime milestoneTargetDate;     
                
                SLAValue=milestoneSLA;  milestoneTargetDate=eachCaserec.CaseMilestones[0].TargetDate; Integer getMinuteValue;
                
                //Checking if the case has been overriden 
                if(eachCaserec.Override_Next_Case_Update__c>=system.now())
                {       //If the SLA has already been missed, then the new SLA is calculated based on the case override date
                    if(SLAValue == '00:00'){    
                        getMinuteValue = integer.valueOf(eachCaserec.Override_Next_Case_Update__c.getTime()/1000/60 - system.now().getTime()/1000/60);
                        Each_sub_Case_Wrapper.SLAinminutes=getMinuteValue;
                        Each_sub_Case_Wrapper.SLA = getMinuteValue/60 + 'h ' +  Math.mod(getMinuteValue,60) + 'm'; Each_sub_Case_Wrapper.SLA_Color='green';
                    }
                    else //If SLA has not been missed then add the case override time to the SLA
                    {
                        
                        string TimeRemaininginMins = eachCaserec.CaseMilestones[0].TimeRemaininginMins; integer index=TimeRemaininginMins.indexOf(':');integer timerem=integer.valueOf(TimeRemaininginMins.substring(0,index));
                        getMinuteValue = integer.valueOf(eachCaserec.Override_Next_Case_Update__c.getTime()/1000/60 - system.now().getTime()/1000/60 + timerem );
                        Each_sub_Case_Wrapper.SLAinminutes=getMinuteValue;
                        Each_sub_Case_Wrapper.SLA = getMinuteValue/60 + 'h ' +  Math.mod(getMinuteValue,60) + 'm';Each_sub_Case_Wrapper.SLA_Color='green';
                        
                    }
                    
                }
                else
                {
                    if(SLAValue == '00:00'){ // Means already violated & Calculate the overdue
                        
                        getMinuteValue = integer.valueOf((milestoneTargetDate.getTime()/1000/60 - system.now().getTime()/1000/60) );
                        Each_sub_Case_Wrapper.SLAinminutes=getMinuteValue;
                        Each_sub_Case_Wrapper.SLA = '-'+ (getMinuteValue/60 * -1) + 'h ' +  Math.mod(getMinuteValue * -1,60) + 'm';
                    }
                    else
                    {
                        getMinuteValue = integer.valueOf(SLAValue.substring(0,SLAValue.indexOf(':')));
                        Each_sub_Case_Wrapper.SLAinminutes=getMinuteValue;
                        Each_sub_Case_Wrapper.SLA = getMinuteValue/60 + 'h ' +  Math.mod(getMinuteValue,60) + 'm';
                    }
                    
                    // For SLA Color
                    if (getMinuteValue <= 10 && getMinuteValue > 0){ Each_sub_Case_Wrapper.SLA_Color = 'Orange'; // Set Orange 
                                                                   }
                    else if (getMinuteValue <= 0)Each_sub_Case_Wrapper.SLA_Color = 'Red'; else Each_sub_Case_Wrapper.SLA_Color='Green';
                }
            }
            

            // Adding to Wrapper List
            sub_Case_Wrapper_List.add(Each_sub_Case_Wrapper);
        }
        return sub_Case_Wrapper_List;
        
    } 
    
    //Method - 9 : Method for mapping the Cases in the Users Cases to the Akachat associated to that case
    @AuraEnabled
    public static Map<string,string> getAkaChatID(List<Case> allCaseList){
        
        // Map to store CAse id + AkaChat Id
        Map<string,string> CaseIdAkaChatTranscript_Map = new Map<string,string>();
        
        // set to store all Unique Case Ids
        set<Id> uniqueCaseIds = new set<Id>();
      
        // Query On LiveChatTranscript to check if there is a transcript for a caseID
            for(livechattranscript eachMember : [select id ,caseid from livechattranscript where caseid IN :allCaseList order by createddate asc] ){
               
                CaseIdAkaChatTranscript_Map.put(eachMember.caseid, eachMember.id);                      
            }
        
        //uniqueCaseIds.clear();
        
        return CaseIdAkaChatTranscript_Map;
        
        
    }
    
    @AuraEnabled (cacheable=true)
    public static Map<string,Integer> getDirectReporteeCount(){
        List<user> DirectRep= new List<user>();
        DirectRep=[select id,name from user where managerid=:UserInfo.getUserId() and isactive=true order by name];
        
        Map<string,Integer> caseOwner_CountMap = new Map<string,Integer>();
        
        // set to store all Unique User Ids
        set<string> uniqueUserIds = new set<string>();
                       
        // Loop for all the Cases, store the unique case IDs and set map value to 0 in case no case is assigned to user
        for(user eachUserRec : DirectRep){
            
            uniqueUserIds.add(eachUserRec.Name);
            caseOwner_CountMap.put(eachUserRec.Name ,0);
        }
        // If Size > 0, then Query
        if(DirectRep.size() > 0){
            
            
            AggregateResult[] groupedResults = [SELECT owner.name,count(Id) FROM Case where owner.name IN :uniqueUserIds and isClosed=false and Sub_Type__c!='CMP Alerts' GROUP BY owner.name];
            
            for (AggregateResult ar : groupedResults) { caseOwner_CountMap.put(string.valueOf(ar.get('Name')), Integer.valueOf(ar.get('expr0')));
            }
        }
        uniqueUserIds.clear();
        return caseOwner_CountMap;
        
        
    }
    
    //Method - 10 : Method for getting the akachat transcript clicked by the user
    @AuraEnabled (cacheable=true)
    public static list <livechattranscript>getAkaChatTranscript(string AkachatID)
    {
        
       return [select body, ChatDuration, location ,owner.name, Name, SupervisorTranscriptBody from livechattranscript where id=:AkachatID limit 1];
    }
    
    //Method - 11 : Assigns/Accepts the escalation to the current user
    @AuraEnabled
    public static string assignEscalationToUser(string userID, string techID)
    {
        try{
            Engagement_Request__c updateowner = new Engagement_Request__c(id=techID,Assigned_To__c=userID,OwnerId = userID,Request_Status__c = 'Accepted');
            update updateowner;
            return 'true';
        }
        catch (exception e)
        {return e.getMessage(); }        
    }
    
    //Method -12 : Method for getting Open Escalations of the User
    @AuraEnabled
    public static list <sub_Esc_Wrapper>getMyOpenEscalations(string userID)
    {
        List<Engagement_Request__c> MyOpenEscalations = new List<Engagement_Request__c>();
        List<sub_Esc_Wrapper> sub_Esc_Wrapper_List;
        
        sub_Esc_Wrapper_List = new List<sub_Esc_Wrapper>();
        sub_Esc_Wrapper Each_sub_Esc_Wrapper;
        
        MyOpenEscalations = [SELECT id, Name, Case_Account_Name__c,Case_AKAM_Case_ID__c, Description__c ,case__r.Support_Level__c, Case__r.Support_Geography__c,Request_Status__c, ER_Severity__c, 
                                                 Area__c, Case__c, case__r.Case_Owner_Name__c, case__r.status,Age__c from Engagement_Request__c where ownerid=:userID and Request_Status__c 
                                                 NOT IN ('Rejected','Cancelled','Closed') Order by CreatedDate desc];
        
        for(Engagement_Request__c eachEscRec: MyOpenEscalations){
            Each_sub_Esc_Wrapper = new sub_Esc_Wrapper();
            Each_sub_Esc_Wrapper.EachEscRec = eachEscRec;
            
            //Assigning Color based on Geography
            assignGeoColor(Each_sub_Esc_Wrapper);
            
            sub_Esc_Wrapper_List.add(Each_sub_Esc_Wrapper);
        }
        
        return sub_Esc_Wrapper_List;
        
    }   
    
    //Method - 13 : Method for getting subscribed Escalation by the user
    @AuraEnabled 
    public static list <sub_Esc_Wrapper>getMyEscalations(string QueryType)
    {
        
        list<id> lMyQueueIds = new list<id>();
                list<Engagement_Request__c> MyEscalations = new list<Engagement_Request__c>();
        List<sub_Esc_Wrapper> sub_Esc_Wrapper_List;

        if( QueryType=='My Queues'){
            for(GroupMember g: [Select Group.Name,Group.Id,Group.DeveloperName from GroupMember where UserorGroupId =:UserInfo.getUserId() and Group.Type='Queue' ]) {
                
                lMyQueueIds.add(g.Group.Id);
            }
            
            MyEscalations =  [SELECT id, Name, Case_Account_Name__c,Accept_Target_Date__c ,Description__c , Accept_Target_Mins__c , Accept_Violation__c ,Request_Status__c, Accept_Completed__c ,ER_Severity__c, Area__c ,Case_AKAM_Case_ID__c, Case__c , case__r.Support_Level__c, Age__c, Case__r.Support_Geography__c, Target_Shift__c, Case_Product__c, Case_Owner__c ,  owner.name from Engagement_Request__c where ownerid in :lMyQueueIds and Request_Status__c NOT IN ('Rejected','Cancelled','Closed') order by createddate desc];    
        }
                
        //Changes by Sharath Prasanna for ESESP-1342 BOCC Migration. Adding the BOCC Consultancy record type to the query filter  
        else if(QueryType=='All Queues')
        {
            MyEscalations =  [SELECT id, Name, Case_Account_Name__c,Accept_Target_Date__c ,Description__c , Accept_Target_Mins__c , Accept_Violation__c ,Request_Status__c, Accept_Completed__c ,ER_Severity__c, Area__c ,Case_AKAM_Case_ID__c, Case__c , case__r.Support_Level__c, Age__c, Case__r.Support_Geography__c, Target_Shift__c, Case_Product__c, Case_Owner__c ,  owner.name from Engagement_Request__c where recordtype.name in ('CCare Technical Escalation','BOCC Consultancy') and Request_Status__c='Unassigned' and owner.name like 'ATS_ER%' order by createddate desc];
        }
        
         If(Test.isRunningTest()){
                    MyEscalations =  [SELECT id, Name, Case_Account_Name__c,Accept_Target_Date__c ,Description__c , Accept_Target_Mins__c , Accept_Violation__c ,Request_Status__c, Accept_Completed__c ,ER_Severity__c, Area__c ,Case_AKAM_Case_ID__c, Case__c , case__r.Support_Level__c, Case__r.Support_Geography__c, Age__c, Target_Shift__c, Case_Product__c, Case_Owner__c ,  owner.name from Engagement_Request__c order by createddate desc LIMIT 50000];
        }
        
        sub_Esc_Wrapper_List= new List<sub_Esc_Wrapper>();
        sub_Esc_Wrapper Each_sub_Esc_Wrapper;
        
        
        for(Engagement_Request__c eachEscrec : MyEscalations){
            Each_sub_Esc_Wrapper = new sub_Esc_Wrapper();
            Each_sub_Esc_Wrapper.SLAEsc = '';
            Each_sub_Esc_Wrapper.Type= '';
            
            // Assigning Escalation record
            Each_sub_Esc_Wrapper.EachEscRec = eachEscrec;
            
            //Assigning Color based on Geography
            assignGeoColor(Each_sub_Esc_Wrapper);

            
            
            if(eachEscrec.Accept_Target_Mins__c ==null){
                Each_sub_Esc_Wrapper.SLAEsc='';
            }
            else if(eachEscrec.Accept_Completed__c == true && eachEscrec.Accept_Violation__c == false){
                Each_sub_Esc_Wrapper.Type = 'Y';
            }
            else
            {   
                
                Integer sla;
                sla=(integer.valueOf((eachEscrec.Accept_Target_Date__c.getTime() - DateTime.Now().getTime())/60000));
                if(sla<0)
                {
                    Each_sub_Esc_Wrapper.Type='Miss';
                }
                else if(sla<=15) 
                {
                    Each_sub_Esc_Wrapper.Type='Num'; Each_sub_Esc_Wrapper.SLAEsc=sla+'m';
                    Each_sub_Esc_Wrapper.SLA_Color='#CC3333';
                }
                else if(sla<45) {
                    Each_sub_Esc_Wrapper.Type='Num'; Each_sub_Esc_Wrapper.SLAEsc= sla+'m';
                    Each_sub_Esc_Wrapper.SLA_Color='orange';
                    
                }
                else if(sla<60) {
                    Each_sub_Esc_Wrapper.Type='Num';  Each_sub_Esc_Wrapper.SLAEsc= sla+'m';
                    Each_sub_Esc_Wrapper.SLA_Color='green';
                    
                }
                
                else {
                    Each_sub_Esc_Wrapper.Type='Num';
                    Each_sub_Esc_Wrapper.SLAEsc = sla/60 + 'h ' +  Math.mod(sla,60) + 'm';
                    Each_sub_Esc_Wrapper.SLA_Color='green';
                    
                } 
                
                
            }
            
            sub_Esc_Wrapper_List.add(Each_sub_Esc_Wrapper);
            
        }
        return sub_Esc_Wrapper_List;
        
    }   
    
    //Method - 14 : Method for Filtering my open escalations
    @AuraEnabled
    public static list <sub_Esc_Wrapper>getMyFilteredEscalations(string userID, list<string> SelSeverity, string SelStatus)
    {   
        List<Engagement_Request__c> FilteredEsc= new List<Engagement_Request__c>();
        List<sub_Esc_Wrapper> sub_Esc_Wrapper_List;
        
        string MasterQuery='SELECT id, Name, Case_Account_Name__c, Description__c ,case__r.Support_Level__c, case__r.Support_Geography__c, Request_Status__c, ER_Severity__c, Area__c, Case_AKAM_Case_ID__c, Case__c, case__r.Case_Owner_Name__c, case__r.status, Age__c from Engagement_Request__c where ownerid=:userID and Request_Status__c NOT IN (\'Rejected\',\'Cancelled\',\'Closed\')';
        string dynamicQuery;
        Integer size = SelSeverity.size();
        if(size==3)
        {
            if(SelStatus=='All') {dynamicQuery=''; }
            else{
                dynamicQuery= ' and Request_Status__c = :SelStatus Order by CreatedDate desc';}
            
        }
        else
        {   
            if(SelStatus=='All') {dynamicQuery=' and ER_Severity__c IN :SelSeverity Order by CreatedDate desc'; }
            
            else
                dynamicQuery=' and Request_Status__c = :SelStatus and ER_Severity__c IN :SelSeverity Order by CreatedDate desc';
            
        }
        MasterQuery=MasterQuery+dynamicQuery;
        System.debug('###### ' + MasterQuery);
        FilteredEsc=Database.query(MasterQuery); 

        sub_Esc_Wrapper_List = new List<sub_Esc_Wrapper>();
        sub_Esc_Wrapper Each_sub_Esc_Wrapper;
        for(Engagement_Request__c eachEscRec: FilteredEsc){
            Each_sub_Esc_Wrapper = new sub_Esc_Wrapper();
            Each_sub_Esc_Wrapper.EachEscRec = eachEscRec;

            assignGeoColor(Each_sub_Esc_Wrapper);
            sub_Esc_Wrapper_List.add(Each_sub_Esc_Wrapper);
        }
        return sub_Esc_Wrapper_List;
        
    }
    
    //Method - 15 : Method for supressing the case update field when the user opens the case
    @AuraEnabled
    public static string suppressCaseUpdate(string CaseID)
    {
        try{
            case c = new Case(id=CaseID);
            c.recent_update__c = false;
            c.Validation_Override__c=true;
            update c;
            return 'true';
        } 
        catch(Exception e){ return e.getMessage();  }
    }
    
    
     //Method - 16: This method is used for assigning the case to direct reportee by the manager. Gets the userID from name and calls the assign method
    @AuraEnabled
    public static void getReporteeDetailsandAssign(string username, string CaseID)
    {
     string userid=[select id from user where name=:username limit 1].id;
        assignCaseToUser(userid,CaseID);
    }
    
    //Method - 17: Method for assigning color based on Geography for Escalation
    @Auraenabled
    public static void assignGeoColor(sub_Esc_Wrapper Each_sub_Esc_Wrapper){
        Each_sub_Esc_Wrapper.GeoColor = geoName_colorCode.get(Each_sub_Esc_Wrapper.EachEscRec.Case__r.Support_Geography__c) !=null ?
            geoName_colorCode.get(Each_sub_Esc_Wrapper.EachEscRec.Case__r.Support_Geography__c) : 'Black';
    }
    
    //Method - 18: Overloaded Method - 17 for assigning color based on Geography for Case
    @Auraenabled
    public static void assignGeoColor(sub_Case_Wrapper Each_sub_Case_Wrapper){
        Each_sub_Case_Wrapper.GeoColor = geoName_colorCode.get(Each_sub_Case_Wrapper.EachCaseRec.Support_Geography__c) !=null ?
            geoName_colorCode.get(Each_sub_Case_Wrapper.EachCaseRec.Support_Geography__c) : 'Black';
    }
    
}