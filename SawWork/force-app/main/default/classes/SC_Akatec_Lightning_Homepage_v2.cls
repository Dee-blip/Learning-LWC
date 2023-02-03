/*
Author          : Sumukh SS
Description     : Apex Controller for Akatec Lightning HomePage 
Test Class - SC_Akatec_Lightning_TC

Date                        Developer             JIRA #                      Description                                                       
--------------------------------------------------------------------------------------------------------------------------------
18 June 2020                Sumukh SS           ESESP-3937          Akatec Home rebuild into LWC
20 Nov 2020                 Sheena Bhan         ESESP-3767          Display new Service Incident records on Akatec Home page
15 Jun 2021             Vandhana Krishnamurthy  ESESP-5494          Support Differentiation for AkaTec (Saturn)
24 Dec 2021                 Aditi Singh         ESESP-5717          Saturn: Support Delivery Type Exceptions for APJ
---------------------------------------------------------------------------------------------------------------------------------
*/

public without sharing class SC_Akatec_Lightning_Homepage_v2 {
    
    // Map to store Geo Name + Color Code
    public static Map<string, string> geoName_colorCode = new Map<string, string>{'NORTHAM' => 'Orange',
        'EMEA' => 'Green',
        'LATAM'=> 'Grey',
        'APJ' => 'Purple'};
    public static id techRecordTypeId= Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();            
            public class flat_Case_Wrapper{
                
                @AuraEnabled public string akamcaseid{get;set;}
                @AuraEnabled public string AkamCaseIDURL{get;set;}
                @AuraEnabled public String AccountName{get;set;}
                @AuraEnabled public String akamacctid{get;set;}
                @AuraEnabled public string Subject {get;set;}
                @AuraEnabled public string caseProd {get;set;} //added by Aditi
                @AuraEnabled public string Geography {get;set;}
                @AuraEnabled public string GeographyColor {get;set;}
                @AuraEnabled public string Country {get;set;}
                @AuraEnabled public string WorkType {get;set;}
                @AuraEnabled public decimal Age {get;set;}
                @AuraEnabled public string Severity {get;set;}
                @AuraEnabled public string SupportLevel {get;set;}
                @AuraEnabled public string CaseOwner{get;set;}
                @AuraEnabled public string SLA{get;set;}
                @AuraEnabled public integer SLAinminutes{get;set;}
                @AuraEnabled public String SLA_Color{get;set;}
                @AuraEnabled public string TSE_Primary {get;set;}  
                @AuraEnabled public string LiveChatId {get;set;}
                @AuraEnabled public string RecentUpdateColor {get;set;}
                @AuraEnabled public string NextAction {get;set;}
                @AuraEnabled public decimal LOE {get;set;}  
                @AuraEnabled public string casestatus {get;set;}         
                @AuraEnabled public string contname {get;set;}   
                @AuraEnabled public string description {get;set;}         
                @AuraEnabled public string altcontem {get;set;}         
                @AuraEnabled public string altconph {get;set;}         
                @AuraEnabled public string contemail {get;set;}         
                @AuraEnabled public string contph {get;set;}         
                @AuraEnabled public string contportlogin {get;set;}         
                @AuraEnabled public string altcontcomp {get;set;} 
                @AuraEnabled public DateTime akamModifiedDateVal {get;set;} 
                @AuraEnabled public String akamModifiedDate {get;set;} 

                // changes by Vandhana for ESESP-5494 Saturn
                @AuraEnabled public string Industry {get;set;}
                @AuraEnabled public string Region {get;set;}
                @AuraEnabled public string Territory {get;set;}
            }
    
    public class Geography_ProfileName_Wrapper{
        @AuraEnabled public list<string> savedGeo {get;set;}
        @AuraEnabled public list<string> savedQueues {get;set;}
        @AuraEnabled public list<string> savedSev {get;set;}
        @AuraEnabled public list<string> savedSuppDelType {get;set;}
        
        @AuraEnabled public boolean IsManager{get;set;}
        @AuraEnabled public list<sub_Queue_Mapping> akatecqueue_List;
        
    }
    
    public class sub_Queue_Mapping{
        
        @AuraEnabled public string queueName {get;set;}
        @AuraEnabled public string queueId {get;set;}
        @AuraEnabled public integer queueCount {get;set;}
        
    }    
    
    // Method - 3 : Gets the saved geography / manager / Akachat agent. If not available, sets it to a default value
    @AuraEnabled
    public static Geography_ProfileName_Wrapper getSavedGeo()
    {
        Geography_ProfileName_Wrapper sub_geo_profile = new Geography_ProfileName_Wrapper();
        
        List<sc_user_filter__c> selectedFilters = new List<sc_user_filter__c>();
        string rectypeid= Schema.SObjectType.sc_user_filter__c.getRecordTypeInfosByName().get('Akatec').getRecordTypeId();
        string userid=userinfo.getUserId()+'-'+rectypeid;
        
        selectedFilters=[select Unique_ID__c,filter_values__c from sc_user_filter__c WHERE Unique_ID__c=:userid limit 1];
        
        
        if(selectedFilters.size()>0)
        {
            map<string,object> masterfiltervalues = (Map<String, object>) JSON.deserializeUntyped (selectedFilters[0].filter_values__c);
            if(masterfiltervalues.containsKey('CaseFilters'))
            {
                
                list<string> SavedQueues= new list<string>();
                list<string> SavedGeos= new list<string>();
                list<string> savedSev= new list<string>();
                list<string> savedSuppDelType= new list<string>();
                
                string Filters = string.valueof(masterfiltervalues.get('CaseFilters'));
                List<String> filterString = Filters.split('&&');
                
                SavedQueues.addall(filterString[0].split(':')[1].split(','));
                SavedGeos.addall(filterString[1].split(':')[1].split(','));
                savedSev.addall(filterString[2].split(':')[1].split(','));
                if(filterString.size() >= 4)
                {
                    savedSuppDelType.addall(filterString[3].split(':')[1].split(','));
                }
                
                sub_geo_profile.savedGeo = SavedGeos;
                sub_geo_profile.savedQueues = SavedQueues;
                sub_geo_profile.savedSev = savedSev;
                sub_geo_profile.savedSuppDelType = savedSuppDelType;
            }
        }
        
        sub_geo_profile.IsManager=isManager();
        
        list<string> allakatecQueueIDs = new list<string>();
        
        map<string, string> QueueName_QueueIDMap = new map<string, string>();
        for(QueueSobject q :[Select QueueId,Queue.Name from QueueSobject where SobjectType = 'Case' and (Queue.DeveloperName like 'ATS%' OR Queue.DeveloperName like 'CC%' OR Queue.DeveloperName like 'CPD%' OR Queue.DeveloperName = 'Orphan_Queue') order by queue.name])
        {
            QueueName_QueueIDMap.put(q.Queue.Name,q.QueueId);
            allakatecQueueIDs.add(q.QueueId);
        }
        
        List<sub_Queue_Mapping> sub_Queue_Mapping_List=new list<sub_Queue_Mapping>();
        sub_Queue_Mapping Each_sub_Queue_Mapping; 
        ID gettechnicalRecordtypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        
        AggregateResult[] groupedResults =[select count(id), owner.name from case where ownerid IN :allakatecQueueIDs and recordtypeid=:gettechnicalRecordtypeId and isclosed=false group by owner.name];
        
        for(AggregateResult ar : groupedResults)
        {   
            Each_sub_Queue_Mapping = new sub_Queue_Mapping();
            Each_sub_Queue_Mapping.queueName = (string.valueOf(ar.get('Name')));
            Each_sub_Queue_Mapping.queueId= QueueName_QueueIDMap.get(Each_sub_Queue_Mapping.queueName);
            Each_sub_Queue_Mapping.queueCount = (Integer.valueOf(ar.get('expr0')));
            QueueName_QueueIDMap.remove(Each_sub_Queue_Mapping.queueName);
            
            sub_Queue_Mapping_List.add(Each_sub_Queue_Mapping);
        }
        //Adding those queues which have a count = 0
        if(!QueueName_QueueIDMap.isEmpty())
        {
            for (String QueueName : QueueName_QueueIDMap.keySet()){
                Each_sub_Queue_Mapping = new sub_Queue_Mapping();
                Each_sub_Queue_Mapping.queueName = QueueName;
                Each_sub_Queue_Mapping.queueId= QueueName_QueueIDMap.get(Each_sub_Queue_Mapping.queueName);
                Each_sub_Queue_Mapping.queueCount = 0;
                sub_Queue_Mapping_List.add(Each_sub_Queue_Mapping);
                
            }
        }
        
        sub_geo_profile.akatecqueue_List=sub_Queue_Mapping_List;   
        return sub_geo_profile;
    }
    
    @auraenabled(cacheable=true)
    public static boolean isManager()
    {
        string profilename=[select name from profile where id=:userinfo.getProfileId()].name;
        if(profilename=='Support - Tech Support Manager'||profilename=='Support - Tech Support Manager with Customer Notification')
            return true;
        else
            return false;
    }
    
    public class onLoadMyOpenCasesWrapper{
        
        @AuraEnabled public boolean isManager {get;set;}
        @AuraEnabled public list<string> tasktypevalues {get;set;}
        @AuraEnabled public string techrectypeid {get;set;}
        
    }    
    
    @AuraEnabled
    public static onLoadMyOpenCasesWrapper getMyOpenCasesOnloadvalues()
    {
        onLoadMyOpenCasesWrapper subonLoadMyOpenCasesWrapper = new onLoadMyOpenCasesWrapper();
        subonLoadMyOpenCasesWrapper.isManager=isManager();
        
        string tasktypevalues = [Select Value_Text__c from SC_Utility__mdt where DeveloperName = 'AkatecHome_Task_Type_Values'].Value_Text__c; 
        
        List<String> taskpickListValuesList= new List<String>();
        taskpickListValuesList.addall(tasktypevalues.split(','));
        
        subonLoadMyOpenCasesWrapper.tasktypevalues=taskpickListValuesList;
        
        subonLoadMyOpenCasesWrapper.techrectypeid= Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
        
        return subonLoadMyOpenCasesWrapper;
    }
    
    // Method - 4 : Saves the selected filters
    @AuraEnabled
    public static void saveSelectedFilters(list<String> SelectedGeoFromUser, list<String> SelectedQueuesFromUser, list<String> selectedSev, list<String> selectedSuppDelType)
    {    
        string rectypeid= Schema.SObjectType.sc_user_filter__c.getRecordTypeInfosByName().get('Akatec').getRecordTypeId();
        string userid=userinfo.getUserId()+'-'+rectypeid;
        
        list<sc_user_filter__c> selectedFilters=[select filter_values__c from sc_user_filter__c WHERE Unique_ID__c=:userid limit 1];
        string fullFilter = 'Queue:'+string.join(SelectedQueuesFromUser,',')+'&&Geo:'+string.join(SelectedGeoFromUser,',')+'&&Sev:'+string.join(selectedSev,',')+'&&SuppDelType:'+string.join(selectedSuppDelType,',');
        
        if(selectedFilters.size() <1){
            map<String,String> userfiltermap = new map<String,String>();
            userfiltermap.put('CaseFilters',fullFilter);
            fullFilter = JSON.serialize(userfiltermap);
            
        }
        else
        {
            map<string,object> userfiltermap = (Map<String, object>) JSON.deserializeUntyped (selectedFilters[0].filter_values__c);
            userfiltermap.put('CaseFilters',fullFilter);
            fullFilter = JSON.serialize(userfiltermap);
            
        }
        
        string query=generateDynamicQuery(SelectedGeoFromUser,SelectedQueuesFromUser,selectedSev,selectedSuppDelType);
        
        sc_user_filter__c upsertUserData = new sc_user_filter__c(
            Unique_ID__c=userid, 
            query_string__c=query,
            recordtypeid=rectypeid,
            filter_values__c =fullFilter
        );
        
        upsert upsertUserData Unique_ID__c;
    }
    
    @AuraEnabled
    public static string generateDynamicQuery(list<String> SelectedGeoFromUser, list<string> SelectedQueuesFromUser, list<string> selectedSev,List<String> selectedSuppDelType)
    {
        //-------------------------------------------Constructing Query to be saved----------------------------------
       //string query='SELECT id, has_active_transition__c ,Case_Account_Name__c,  Contact.Name, ContactEmail, Contact_Phone__c, Contact_Portal_Login__c, Alternate_Contact_Email__c, Alternate_Contact_Phone__c, Alternate_Contact_Company__c, Description, Account.BillingCountry, Work_Type__c ,Severity__c ,Support_Level__c ,akam_case_id__c,Age_days__c ,subject, Case_Owner_Name__c,Support_Geography__c,(select TimeRemaininginMins,TargetDate from CaseMilestones where IsCompleted = false ),(Select id,time_remaining__c from Case_Transitions__r where approved_date__c != null) FROM Case where recordtype.name=\'Technical\' and isClosed = False and ownerid IN (';

        string query='WHERE recordtypeid=:techRecordTypeId and isClosed = False and ownerid IN (';   
        for(integer i=0;i<SelectedQueuesFromUser.size()-1;i++)
        {
            query=query + '\''+SelectedQueuesFromUser[i]+'\''+',';
        }
        query=query + '\''+SelectedQueuesFromUser[SelectedQueuesFromUser.size()-1]+'\''+')';
        
        if(SelectedGeoFromUser.size()<5)
        {
            query=query + ' and Support_Geography__c IN (';
            for(integer i=0;i<SelectedGeoFromUser.size()-1;i++)
            {
                query=query + '\''+SelectedGeoFromUser[i]+'\''+',';
            }
            query=query + '\''+SelectedGeoFromUser[SelectedGeoFromUser.size()-1]+'\''+')';
        }
        
        if(selectedSev.size()<3)
        {
            query=query + ' and Severity__c IN (';
            for(integer i=0;i<selectedSev.size()-1;i++)
            {
                query=query + '\''+selectedSev[i]+'\''+',';
            }
            query=query + '\''+selectedSev[selectedSev.size()-1]+'\''+')';
        }

        if(selectedSuppDelType.size() < 2)
        {
            query=query + ' and Support_Delivery_Type__c IN (';
            for(integer i=0;i<selectedSuppDelType.size()-1;i++)
            {
                query=query + '\''+selectedSuppDelType[i]+'\''+',';
            }
            query=query + '\''+selectedSuppDelType[selectedSuppDelType.size()-1]+'\''+')';
        }
        
        query=query+' order by createddate desc LIMIT 200';
        
        return query; 
    }
    
    public class directreporteeWrapper{
        
        @AuraEnabled public string userID {get;set;}
        @AuraEnabled public string userName {get;set;}
        @AuraEnabled public integer openCaseCount {get;set;}
        
    }    
    
    // Method - 5 : Gets the direct reportee case count on assigning case if the person is a manager
    @AuraEnabled
    public static list<directreporteeWrapper> getDirectReporteeCount(){
        
        
        list<string> uniqueUserIds=new list<string>();
        map<string, string> userName_userIDMap = new map<string, string>();
        for(user u:[select id,name from user where managerid=:UserInfo.getUserId() and isactive=true order by name])
        {   
            userName_userIDMap.put(u.Name,u.Id);
            uniqueUserIds.add(u.Id);
        }
        
        uniqueUserIds.add(userinfo.getuserid());
        userName_userIDMap.put(userinfo.getName(),userinfo.getuserid());
        
        List<directreporteeWrapper> subdirectreporteeWrapper=new list<directreporteeWrapper>();
        directreporteeWrapper EachdirectreporteeWrapper; 
        
        AggregateResult[] groupedResults =[SELECT owner.name,count(Id) FROM Case where ownerid IN :uniqueUserIds and isClosed=false and Sub_Type__c!='CMP Alerts' GROUP BY owner.name];
        for(AggregateResult ar : groupedResults)
        {   
            EachdirectreporteeWrapper = new directreporteeWrapper();
            EachdirectreporteeWrapper.userName = (string.valueOf(ar.get('Name')));
            EachdirectreporteeWrapper.userID= userName_userIDMap.get(EachdirectreporteeWrapper.userName);
            EachdirectreporteeWrapper.openCaseCount = (Integer.valueOf(ar.get('expr0')));
            userName_userIDMap.remove(EachdirectreporteeWrapper.userName);
            
            subdirectreporteeWrapper.add(EachdirectreporteeWrapper);
        }
        
        //Adding those USers who have a count = 0
        if(!userName_userIDMap.isEmpty())
        {
            for (String userName : userName_userIDMap.keySet()){
                EachdirectreporteeWrapper = new directreporteeWrapper();
                EachdirectreporteeWrapper.userName = userName;
                EachdirectreporteeWrapper.userID= userName_userIDMap.get(userName);
                EachdirectreporteeWrapper.openCaseCount = 0;
                subdirectreporteeWrapper.add(EachdirectreporteeWrapper);
                
            }
        }
        
        return subdirectreporteeWrapper;
    }
    
    //Method - 6 : Gets Queue Cases (Dynamic Query Generation)
    @AuraEnabled
    public static List<flat_Case_Wrapper> getCases()
    {   
        
        //Map for storing AccountID + All TSE Primary names
        //Map<string,string> accountId_TSEPrimNameMap=new Map<string,string>();
        
        List<Case> CaseHome= new List<Case>();
        string milestoneSLA;
        
        string userid=userinfo.getUserId()+'-'+Schema.SObjectType.sc_user_filter__c.getRecordTypeInfosByName().get('Akatec').getRecordTypeId();
        
        List<SC_User_Filter__c> userrow = [select query_string__c from SC_User_Filter__c WHERE Unique_ID__c=:userid limit 1];
        
        if(userrow.size()>0)
        {
            //Aditi - added to query Case_Product__r.Name below
            string baseQuery = 'SELECT id, has_active_transition__c ,Case_Account_Name__c, Contact.Name, ContactEmail, Contact_Phone__c, Contact_Portal_Login__c, Alternate_Contact_Email__c, Alternate_Contact_Phone__c, Alternate_Contact_Company__c, Description,Account.BillingCountry, Work_Type__c ,Severity__c ,Support_Level__c,akam_case_id__c,Age_days__c ,subject, Case_Product__r.Name, Case_Owner_Name__c,Support_Geography__c,(select TimeRemaininginMins,TargetDate from CaseMilestones where IsCompleted = false ),(Select id,time_remaining__c from Case_Transitions__r where approved_date__c != null),Account.Industry__c,Account.TERR_HIER_2__c,Account.TERR_HIER_5__c FROM Case ';
            string dynamicQuery = userrow[0].query_string__c;
            baseQuery = baseQuery + dynamicQuery;
            CaseHome=Database.query(baseQuery); 
        }
        
        //contains the tse mapping for each unique account in the case list
        //accountID_TSEPrimNameMap = getAccountTeamDetails(CaseHome);
        
        List<flat_Case_Wrapper> sub_Case_Wrapper_List= new List<flat_Case_Wrapper>();
        flat_Case_Wrapper Each_sub_Case_Wrapper;
        
        for(case eachCaserec : CaseHome){
            
            milestoneSLA = null;
            // Initializing Wrapper Variable with default values
            Each_sub_Case_Wrapper = new flat_Case_Wrapper();
            Each_sub_Case_Wrapper.SLA = '';
            Each_sub_Case_Wrapper.SLA_Color = ' ';
            
            // Assigning Case record
            if(eachCaserec.has_active_transition__c)
                Each_sub_Case_Wrapper.akamcaseid = eachCaserec.akam_case_id__c+' ⛳'; 
            else
                Each_sub_Case_Wrapper.akamcaseid = eachCaserec.akam_case_id__c;
            Each_sub_Case_Wrapper.AkamCaseIDURL='/'+eachCaserec.Id;
            Each_sub_Case_Wrapper.AccountName = eachCaserec.Case_Account_Name__c;
            Each_sub_Case_Wrapper.Subject = eachCaserec.Subject;
            Each_sub_Case_Wrapper.caseProd = eachCaserec.Case_Product__r.Name;//added by aditi
            Each_sub_Case_Wrapper.Geography = eachCaserec.Support_Geography__c;
            Each_sub_Case_Wrapper.Country = eachCaserec.Account.BillingCountry;            
            Each_sub_Case_Wrapper.WorkType=eachCaserec.Work_Type__c;
            Each_sub_Case_Wrapper.Age=eachCaserec.Age_days__c;
            Each_sub_Case_Wrapper.Severity=eachCaserec.Severity__c;
            Each_sub_Case_Wrapper.SupportLevel=eachCaserec.Support_Level__c;
            Each_sub_Case_Wrapper.CaseOwner=eachCaserec.Case_Owner_Name__c;

            Each_sub_Case_Wrapper.Industry = eachCaserec.Account.Industry__c;
            Each_sub_Case_Wrapper.Region = eachCaserec.Account.TERR_HIER_2__c;
            Each_sub_Case_Wrapper.Territory = eachCaserec.Account.TERR_HIER_5__c;            
            
            Each_sub_Case_Wrapper.contname=eachCaserec.Contact.Name;
            Each_sub_Case_Wrapper.contemail=eachCaserec.ContactEmail;
            Each_sub_Case_Wrapper.contph=eachCaserec.Contact_Phone__c;
            Each_sub_Case_Wrapper.contportlogin=eachCaserec.Contact_Portal_Login__c;
            Each_sub_Case_Wrapper.altcontem=eachCaserec.Alternate_Contact_Email__c;
            Each_sub_Case_Wrapper.altconph=eachCaserec.Alternate_Contact_Phone__c;
            Each_sub_Case_Wrapper.altcontcomp=eachCaserec.Alternate_Contact_Company__c;
            Each_sub_Case_Wrapper.description=eachCaserec.Description;
            //            Each_sub_Case_Wrapper.transitionCase = eachCaserec;
            
            //Assigning Color based on Geography
            Each_sub_Case_Wrapper.GeographyColor = geoName_colorCode.get(eachCaserec.Support_Geography__c) !=null ?
                geoName_colorCode.get(eachCaserec.Support_Geography__c) : 'Black';
            
            //Each_sub_Case_Wrapper.TSE_Primary = (accountID_TSEPrimNameMap.get(eachCaserec.AccountId));
            //Calculating SLA for cases which have an active transition 
            if(eachCaserec.has_active_transition__c==true && !eachCaserec.Case_Transitions__r.isempty() && eachCaserec.Case_Transitions__r[0].time_remaining__c!=null)
            {   
                string TimeRemaininginMins = string.valueOf(eachCaserec.Case_Transitions__r[0].time_remaining__c);
                integer index=TimeRemaininginMins.indexOf('.');
                integer timerem=integer.valueOf(TimeRemaininginMins.substring(0,index));
                Each_sub_Case_Wrapper.SLAinminutes=timerem;
                if(timerem<0) {Each_sub_Case_Wrapper.SLA = 'Miss' ; 
                               Each_sub_Case_Wrapper.SLA_Color = 'slds-text-color_error'; }
                else
                {Each_sub_Case_Wrapper.SLA = timerem + 'm' ; 
                 Each_sub_Case_Wrapper.SLA_Color = 'slds-text-color_success'; }
            }
            
            // Milestone Details
            else if(eachCaserec.CaseMilestones.size() > 0 && eachCaserec.CaseMilestones != Null){
                
                string SLAValue = eachCaserec.CaseMilestones[0].TimeRemaininginMins; DateTime milestoneTargetDate;     
                
                milestoneTargetDate=eachCaserec.CaseMilestones[0].TargetDate; Integer getMinuteValue;
                
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
                else if (getMinuteValue <= 0) Each_sub_Case_Wrapper.SLA_Color = 'slds-text-color_error'; // Set Red
                else Each_sub_Case_Wrapper.SLA_Color = 'slds-text-color_success';
            }
            else //For SLA sorting
            {
                Each_sub_Case_Wrapper.SLAinminutes=-9999999;
            }
            
            sub_Case_Wrapper_List.add(Each_sub_Case_Wrapper);
        }
        return sub_Case_Wrapper_List;
    }
    
    //Method - 7: Getting TSE details for each account
    @AuraEnabled(cacheable=true)
    public static Map<string,string> getAccountTeamDetails(string caseid){
        
        // Map to store Account Id + TSE PRimary Team Member Name
        Map<string,string> accountIdTeamRole_NameMap = new Map<string,string>();        
        
        string acctid = [select accountid from case where id=:caseid].accountid;
        // String for Map Key & Value
        string mapKey;
        string mapValue;
        
        
        for(AccountTeamMember eachMember : [select AccountId,TeamMemberRole,User.Name from AccountTeamMember where 
                                            TeamMemberRole IN ('Technical Support - Primary', 'Technical Support - Secondary',
                                                               'Technical Support - Other') and AccountId = :acctid ] ){
                                                                   
                                                                   mapKey = eachMember.TeamMemberRole;
                                                                   
                                                                   if(accountIdTeamRole_NameMap.get(mapKey) == null){
                                                                       
                                                                       mapValue = eachMember.User.Name; 
                                                                   }
                                                                   else
                                                                   {
                                                                       mapValue = accountIdTeamRole_NameMap.get(mapKey) + ', ' + eachMember.User.Name;
                                                                   }
                                                                   
                                                                   accountIdTeamRole_NameMap.put(mapKey, mapValue);                     
                                                               }
        
        return accountIdTeamRole_NameMap;
    }
    
    //Method -8 : Assigns the case to the current user
    @AuraEnabled
    public static string assignCaseToUser(string userid,string CaseID)
    {
        try{
            if(userid!=null)
            {   
                case updateowner = new case(id=CaseID,ownerid=userid); 
                update updateowner;
                return 'success';
            }
            else
            { 
                case updateowner = new case(id=CaseID,ownerid=userinfo.getUserId()); 
                update updateowner;
                return 'success';                
            }
        }
        catch (exception e)
        {
            return e.getMessage();
        }
    }
    
    //Method - 9 : Method for getting open cases in for the user + Team Open Cases if the Manager is viewing
    @AuraEnabled 
    public static List <flat_Case_Wrapper> getMyopenCases(string QueryType, list<string> worktype, list<string> sev, list<string> statusval)
    {           
        List<flat_Case_Wrapper> sub_Case_Wrapper_List = new List<flat_Case_Wrapper>();
        
        Map<string,string> CaseIdAkaChatTranscript_Map;
        List<Case> CaseHome= new List<Case>();
        string milestoneSLA;
        
        string yellowcolor = [Select DeveloperName ,Value_Text__c from SC_Utility__mdt where DeveloperName = 'Yellow'].Value_Text__c; 
        
        string userid=userinfo.getUserId();
        string dynamicquery='';
        if(worktype.size()<2) {dynamicquery+=' and Work_Type__c IN :worktype';}
        
        if(sev.size()<3){dynamicquery+=' and Severity__c IN :sev';}
        
        if(statusval.size()<3) {dynamicquery+=' and status IN :statusval';}
        
        dynamicquery+=' order by createddate desc limit 250';
        
        if(QueryType=='MyOpenCases')
        {
            string masterquery = 'SELECT id,Account.Name,account.akam_account_id__c, Account.BillingCountry, Age_days__c, Override_Next_Case_Update__c,Next_Action__c,Work_Type__c ,Task_LOE__c ,Severity__c ,Support_Level__c,AKAM_Modified_Date__c,akam_case_id__c,status,subject,Recent_Update__c,Support_Geography__c,(select id,TimeRemaininginMins,TargetDate from CaseMilestones where IsCompleted = false order by TimeRemaininginMins desc) FROM Case where recordtype.name=\'Technical\' and ownerid=:userid and isClosed=false'; 
            masterquery=masterquery+dynamicquery;
            CaseHome=Database.query(masterquery);
            CaseIdAkaChatTranscript_Map = getAkaChatID(CaseHome);
            
        }
        else if(QueryType=='MyTeamCases')
        {
            string masterquery = 'SELECT id,Account.Name,account.akam_account_id__c, Account.BillingCountry,Age_days__c ,Override_Next_Case_Update__c,Next_Action__c,Work_Type__c ,Task_LOE__c ,Severity__c ,Support_Level__c,AKAM_Modified_Date__c,akam_case_id__c,status,subject,Recent_Update__c,Support_Geography__c, Case_Owner_Name__c ,(select id,TimeRemaininginMins,TargetDate from CaseMilestones where IsCompleted = false order by TimeRemaininginMins desc) FROM Case where recordtype.name=\'Technical\' and ownerid IN (select id from user where managerid=:userid and isactive=true) and isClosed=false and Sub_Type__c!=\'CMP Alerts\''; 
            masterquery=masterquery+dynamicquery;
            CaseHome=Database.query(masterquery);
        }
        
        flat_Case_Wrapper Each_sub_Case_Wrapper;
        
        for(case eachCaserec : CaseHome){
            
            milestoneSLA = null;
            
            // Initializing Wrapper Variable with default values
            Each_sub_Case_Wrapper = new flat_Case_Wrapper();
            Each_sub_Case_Wrapper.SLA = '';
            Each_sub_Case_Wrapper.SLA_Color = ' ';
            
            if(QueryType=='MyOpenCases'){
                Each_sub_Case_Wrapper.LiveChatId = CaseIdAkaChatTranscript_Map.get(eachCaserec.id);
                if(Each_sub_Case_Wrapper.LiveChatId!=null)
                    Each_sub_Case_Wrapper.akamcaseid = eachCaserec.akam_case_id__c + ' 💬'; 
                else
                    Each_sub_Case_Wrapper.akamcaseid = eachCaserec.akam_case_id__c;
            }
            else
            {
                Each_sub_Case_Wrapper.akamcaseid=eachCaserec.akam_case_id__c;
                Each_sub_Case_Wrapper.CaseOwner=eachCaserec.Case_Owner_Name__c;
            }
            Each_sub_Case_Wrapper.AkamCaseIDURL='/'+eachCaserec.Id;
            Each_sub_Case_Wrapper.AccountName = eachCaserec.Account.Name;
            Each_sub_Case_Wrapper.akamacctid=eachCaserec.Account.akam_account_id__c;
            Each_sub_Case_Wrapper.Subject = eachCaserec.Subject;
            Each_sub_Case_Wrapper.Geography = eachCaserec.Support_Geography__c;
            Each_sub_Case_Wrapper.Country = eachCaserec.Account.BillingCountry;            
            Each_sub_Case_Wrapper.WorkType=eachCaserec.Work_Type__c;
            Each_sub_Case_Wrapper.Severity=eachCaserec.Severity__c;
            Each_sub_Case_Wrapper.SupportLevel=eachCaserec.Support_Level__c;
            Each_sub_Case_Wrapper.NextAction=eachCaserec.Next_Action__c;
            Each_sub_Case_Wrapper.LOE=eachCaserec.Task_LOE__c;
            Each_sub_Case_Wrapper.casestatus=eachCaserec.status;
            Each_sub_Case_Wrapper.Age=eachCaserec.Age_days__c;
            if(eachCaserec.recent_update__c==true)
                Each_sub_Case_Wrapper.RecentUpdateColor=yellowcolor;
            
            Each_sub_Case_Wrapper.akamModifiedDate = eachCaserec.AKAM_Modified_Date__c.format();
            Each_sub_Case_Wrapper.akamModifiedDateVal = eachCaserec.AKAM_Modified_Date__c;
            
            //Assigning Color based on Geography
            Each_sub_Case_Wrapper.GeographyColor = geoName_colorCode.get(eachCaserec.Support_Geography__c) !=null ?
                geoName_colorCode.get(eachCaserec.Support_Geography__c) : 'Black';
            
            // Milestone Details
            if(eachCaserec.CaseMilestones.size() > 0 && eachCaserec.CaseMilestones != Null)
            {
                string SLAValue;
                SLAValue = eachCaserec.CaseMilestones[0].TimeRemaininginMins;  DateTime milestoneTargetDate;     
                milestoneTargetDate=eachCaserec.CaseMilestones[0].TargetDate; Integer getMinuteValue;
                
                //Checking if the case has been overriden 
                if(eachCaserec.Override_Next_Case_Update__c>=system.now())
                {       //If the SLA has already been missed, then the new SLA is calculated based on the case override date
                    if(SLAValue == '00:00'){    
                        getMinuteValue = integer.valueOf(eachCaserec.Override_Next_Case_Update__c.getTime()/1000/60 - system.now().getTime()/1000/60);
                        Each_sub_Case_Wrapper.SLAinminutes=getMinuteValue;
                        Each_sub_Case_Wrapper.SLA = getMinuteValue/60 + 'h ' +  Math.mod(getMinuteValue,60) + 'm'; 
                        Each_sub_Case_Wrapper.SLA_Color='slds-text-color_success';
                    }
                    else //If SLA has not been missed then add the case override time to the SLA
                    {
                        string TimeRemaininginMins = eachCaserec.CaseMilestones[0].TimeRemaininginMins; integer index=TimeRemaininginMins.indexOf(':');integer timerem=integer.valueOf(TimeRemaininginMins.substring(0,index));
                        getMinuteValue = integer.valueOf(eachCaserec.Override_Next_Case_Update__c.getTime()/1000/60 - system.now().getTime()/1000/60 + timerem );
                        Each_sub_Case_Wrapper.SLAinminutes=getMinuteValue;
                        Each_sub_Case_Wrapper.SLA = getMinuteValue/60 + 'h ' +  Math.mod(getMinuteValue,60) + 'm';
                        Each_sub_Case_Wrapper.SLA_Color='slds-text-color_success';
                    }
                }
                else
                {
                    if(SLAValue == '00:00')
                    { // Means already violated & Calculate the overdue
                        
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
                    if (getMinuteValue <= 10 && getMinuteValue > 0)
                    {
                        Each_sub_Case_Wrapper.SLA_Color = 'Orange'; // Set Orange 
                    }
                    else if (getMinuteValue <= 0)
                        Each_sub_Case_Wrapper.SLA_Color = 'slds-text-color_error'; 
                    else 
                        Each_sub_Case_Wrapper.SLA_Color='slds-text-color_success';
                }
            }
            else
            {
                Each_sub_Case_Wrapper.SLAinminutes=-9999999;
            }
            
            // Adding to Wrapper List
            sub_Case_Wrapper_List.add(Each_sub_Case_Wrapper);
        }
        return sub_Case_Wrapper_List;
        
    } 
    
    //Method - 10 : Method for mapping the Cases in the Users Cases to the Akachat associated to that case
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
        
        return CaseIdAkaChatTranscript_Map;
        
    }
    
    //Method - 11 : Method for getting the akachat transcript clicked by the user
    @AuraEnabled (cacheable=true)
    public static list <livechattranscript>getAkaChatTranscript(string AkachatID)
    {
        return [select body, ChatDuration, location ,owner.name, Name, SupervisorTranscriptBody from livechattranscript where id=:AkachatID limit 1];
    }
    
    
    //Method - 12 : Method for supressing the case update field when the user opens the case
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
    
    //Method - 12 : Method for supressing the case update field when the user opens the case
    @AuraEnabled
    public static string createTaskLOE(string CaseID,string tasktype, string tasksubject, decimal loe, string visibility)
    {
        try{
            task createtask = new task();
            createtask.whatid = CaseID;
            createtask.type__c=tasktype;
            createtask.subject=tasksubject;
            createtask.LOE_hours__c=loe;
            createtask.Visibility__c=visibility;
            createtask.recordTypeId= Schema.SObjectType.Task.getRecordTypeInfosByName().get('Service Activity').getRecordTypeId();
            createtask.Priority='Normal';
            createtask.Status='Completed';
            createtask.ActivityDate=date.today();
            createtask.ownerid=userinfo.getuserid();
            
            insert createtask;
            return 'success';
        } 
        catch(Exception e){ return e.getMessage();   }
    }
    
    @AuraEnabled
    public static string changeHomeView(string viewname)
    {
        try{
            user userpref = new user(id=userinfo.getUserId());
            userpref.Akatec_Home_Page_Lightning_View__c  = viewname;
            update userpref;
            return 'true';
        } 
        catch(Exception e){ return e.getMessage();  }
    }
    
    //Wrapper for Escalations
    public class case_summary_dashboard{
        @AuraEnabled public string ir_compliance{get;set;}
        @AuraEnabled public string caseupdate_compliance{get;set;}
        @AuraEnabled public string res_sum_compliance{get;set;}
        @AuraEnabled public string loe_today{get;set;}
        @AuraEnabled public string akatecHomeView{get;set;}
    }
    
    @AuraEnabled
    public static case_summary_dashboard getUserSummaryDashboardDetails()
    {   
        
        case_summary_dashboard sub_Dash_Wrapper = new case_summary_dashboard();
        string akatecHomeView= [select Akatec_Home_Page_Lightning_View__c from user where id=:userinfo.getuserid()].Akatec_Home_Page_Lightning_View__c;
        if(akatecHomeView==null)
        {
            akatecHomeView='Show Cases on Home';
        }
        
        if(akatecHomeView!='Show Escalations on Home')
        {
            decimal IR=0;
            Decimal IRCnt=0;
            String irMilestoneId =[SELECT Id FROM MilestoneType WHERE Name = 'Initial Response' limit 1].Id;
            Id recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical').getRecordTypeId();
            //Initial Response Complicant
            integer totalIRCnt = Integer.ValueOf(Database.query('Select COUNT_DISTINCT(CaseId) c from CaseMilestone where Case.OwnerId=\''+UserInfo.getUserId()+'\' and Case.Sub_Type__c IN (\'Product Support\',\'BOCC\',\'Carrier\') and Case.RecordTypeId=\''+ recTypeId + '\''+
                                                                ' and Case.isClosed = true and Case.Resolved_Date__c >=LAST_N_DAYS:30 and MilestoneTypeId=\''+ irMilestoneId+ '\'')[0].get('c'));
            if(totalIRCnt!=0) {
                IRCnt = Integer.ValueOf(Database.query('Select COUNT_DISTINCT(CaseId) c from CaseMilestone where Case.OwnerId=\''+UserInfo.getUserId()+'\' and Case.RecordTypeId=\''+ recTypeId + '\' and Case.Sub_Type__c IN (\'Product Support\',\'BOCC\',\'Carrier\') and IsViolated=true'+
                                                       ' and Case.isClosed = true and Case.Resolved_Date__c >=LAST_N_DAYS:30 and MilestoneTypeId=\''+ irMilestoneId + '\'')[0].get('c'));        
                
                IR = ((1-IRCnt/totalIRCnt)*100).round();        
            }
            /* else
{
sub_Dash_Wrapper.ir_compliance='NA'; 
}*/
            
            
            //Resolution Summary
            integer resSumCnt=0;
            integer totalResCnt = Database.Countquery('Select count() from Case where OwnerId=\''+UserInfo.getUserId()+'\' and RecordType.name=\'Technical\' and Sub_Type__c IN (\'Product Support\',\'BOCC\',\'Carrier\') and isClosed = true and Do_Not_Show_in_Portal__c = False and Work_Type__c = \'Reactive\' and Resolved_Date__c >=LAST_N_DAYS:30') ;
            if(totalResCnt!=0) {
                resSumCnt = Database.Countquery('Select count() from Case where OwnerId=\''+UserInfo.getUserId()+'\' and RecordType.name=\'Technical\' and Resolution_Sent__c = true and Sub_Type__c IN (\'Product Support\',\'BOCC\',\'Carrier\') and Do_Not_Show_in_Portal__c = False and '+
                                                'isClosed = True and Work_Type__c = \'Reactive\' and Resolved_Date__c>=LAST_N_DAYS:30');
            } 
            decimal ResSum=0;
            if(totalResCnt!=0) 
            {
                ResSum =  (resSumCnt/totalResCnt*100);        
            }
            /* else
{
sub_Dash_Wrapper.res_sum_compliance='NA'; 
}*/
            
            
            //My Today LOE
            DateTime todaysDate = System.today();
            DateTime before12hrs = todaysDate.addHours(-12);
            Decimal totalLOE = (Decimal)([Select sum(LOE_hours__c) totalloe from Task where OwnerId=:UserInfo.getUserId() and LOE_hours__c!=null and Akam_Created_Date__c >=:before12hrs][0].get('totalloe'));
            if(totalLOE==null)
            {
                totalLOE=0;
                sub_Dash_Wrapper.loe_today=string.valueof(totalLOE)+' Hrs';   
            }
            else if(totalLOE<1)
            { totalLOE=totalLOE*60; 
             sub_Dash_Wrapper.loe_today=string.valueof(totalLOE)+' Mins';
            }
            else
            {
                sub_Dash_Wrapper.loe_today=string.valueof(totalLOE)+' Hrs';
            }
            
            //Case Update compliance
            
            String cuMilestoneId =[SELECT Id FROM MilestoneType WHERE Name = 'Case Update' limit 1].Id;
            
            integer totalCnt = Integer.ValueOf(Database.query('Select COUNT_DISTINCT(CaseId) c from CaseMilestone where Case.OwnerId=\''+UserInfo.getUserId()+'\' and Case.Sub_Type__c =\'Product Support\' and Case.RecordTypeId=\''+ recTypeId + '\''+
                                                              ' and Case.isClosed = true and Case.Resolved_Date__c >=LAST_N_DAYS:30 and MilestoneTypeId=\''+ cuMilestoneId+ '\'')[0].get('c'));
            
            if(totalCnt!=0) {
                integer sameDayCnt = Integer.ValueOf(Database.query('Select COUNT_DISTINCT(CaseId) c from CaseMilestone where Case.OwnerId=\''+UserInfo.getUserId()+'\' and Case.RecordTypeId=\''+ recTypeId + '\' and Case.Sub_Type__c IN (\'Product Support\',\'BOCC\',\'Carrier\') and IsViolated=true'+
                                                                    ' and Case.isClosed = true and Case.Resolved_Date__c >=LAST_N_DAYS:30 and MilestoneTypeId=\''+ cuMilestoneId + '\'')[0].get('c'));     
                
                decimal caseudtcompl = (sameDayCnt/totalCnt*100);
                sub_Dash_Wrapper.caseupdate_compliance=string.valueOf(caseudtcompl)+'%';
            }
            else
            {
                sub_Dash_Wrapper.caseupdate_compliance='0%';
            }
            
            sub_Dash_Wrapper.ir_compliance=string.valueOf(IR)+'%';
            sub_Dash_Wrapper.res_sum_compliance=string.valueOf(ResSum)+'%';
            
            
        }
        
        sub_Dash_Wrapper.akatecHomeView=akatecHomeView;
        
        return sub_Dash_Wrapper;
    }
    
    //---------------------------------Escalation Related Functionality -------------------------------
    
    //Wrapper for Escalations
    public class flat_Esc_Wrapper{
        @AuraEnabled public string akam_esc_id{get;set;}
        @AuraEnabled public string escURL{get;set;}
        @AuraEnabled public string caseURL{get;set;}       
        @AuraEnabled public string account{get;set;}
        @AuraEnabled public string description{get;set;}
        @AuraEnabled public string status{get;set;}
        @AuraEnabled public string support_level{get;set;}
        @AuraEnabled public string geography{get;set;}
        @AuraEnabled public string GeographyColor{get;set;}
        @AuraEnabled public string sev{get;set;}
        @AuraEnabled public decimal age{get;set;}
        @AuraEnabled public string akam_case_id{get;set;}
        @AuraEnabled public string case_owner{get;set;}
        @AuraEnabled public string case_status{get;set;}
        @AuraEnabled public string area{get;set;}
        @AuraEnabled public string targetshift{get;set;}
        @AuraEnabled public string esc_owner{get;set;}
        @AuraEnabled public string product{get;set;}
        @AuraEnabled public string SLAEsc{get;set;}
        @AuraEnabled public string SLA_Color{get;set;}
        @AuraEnabled public integer SLA_inmins{get;set;}
    }
    
    
    public class escalation_onLoad_Wrapper{
        @AuraEnabled public list<string> savedQueues {get;set;}
        @AuraEnabled public list<sub_EscQueue_Mapping> escqueue_List;
        
    }
    
    public class sub_EscQueue_Mapping{
        
        @AuraEnabled public string queueName {get;set;}
        @AuraEnabled public string queueId {get;set;}
        @AuraEnabled public integer queueCount {get;set;}
        
    }    
    
    @AuraEnabled
    public static escalation_onLoad_Wrapper getSavedQueues()
    {
        escalation_onLoad_Wrapper sub_esc_wrapper = new escalation_onLoad_Wrapper();
        
        List<sc_user_filter__c> selectedFilters = new List<sc_user_filter__c>();
        string rectypeid= Schema.SObjectType.sc_user_filter__c.getRecordTypeInfosByName().get('Akatec').getRecordTypeId();
        string userid=userinfo.getUserId()+'-'+rectypeid;
        
        selectedFilters=[select Unique_ID__c,filter_values__c from sc_user_filter__c WHERE Unique_ID__c=:userid limit 1];
        
        if(selectedFilters.size() <1){
            sub_esc_wrapper.savedQueues=null;
        }
        else
        {
            map<string,object> masterfiltervalues = (Map<String, object>) JSON.deserializeUntyped (selectedFilters[0].filter_values__c);
            if(masterfiltervalues.containsKey('EscalationFilters'))
            {
                list<string> SavedQueues= new list<string>();
                string Filters = string.valueof(masterfiltervalues.get('EscalationFilters'));
                SavedQueues.addall(Filters.split(':')[1].split(','));
                sub_esc_wrapper.savedQueues=SavedQueues;
                
            }
        }
        
        list<string> allerQueueIDs = new list<string>();
        map<string, string> QueueName_QueueIDMap = new map<string, string>();
        for(QueueSobject q :[Select QueueId,Queue.Name from QueueSobject where SobjectType = 'Engagement_Request__c' and (Queue.DeveloperName like 'ATS_%' or Queue.DeveloperName like 'CC%' or Queue.DeveloperName like 'CPD%') order by Queue.DeveloperName])
        {
            QueueName_QueueIDMap.put(q.Queue.Name,q.QueueId);
            allerQueueIDs.add(q.QueueId);
        }
        
        List<sub_EscQueue_Mapping> sub_Queue_Mapping_List=new list<sub_EscQueue_Mapping>();
        sub_EscQueue_Mapping Each_sub_Queue_Mapping; 
        
        AggregateResult[] groupedResults =[select count(id), owner.name from Engagement_Request__c where ownerid IN :allerQueueIDs and recordtype.name!='External Team' and Request_Status__c NOT IN ('Rejected','Cancelled','Closed') group by owner.name];
        for(AggregateResult ar : groupedResults)
        {   
            Each_sub_Queue_Mapping = new sub_EscQueue_Mapping();
            Each_sub_Queue_Mapping.queueName = (string.valueOf(ar.get('Name')));
            Each_sub_Queue_Mapping.queueId= QueueName_QueueIDMap.get(Each_sub_Queue_Mapping.queueName);
            Each_sub_Queue_Mapping.queueCount = (Integer.valueOf(ar.get('expr0')));
            QueueName_QueueIDMap.remove(Each_sub_Queue_Mapping.queueName);
            
            sub_Queue_Mapping_List.add(Each_sub_Queue_Mapping);
        }
        //Adding those queues which have a count = 0
        if(!QueueName_QueueIDMap.isEmpty())
        {
            for (String QueueName : QueueName_QueueIDMap.keySet()){
                Each_sub_Queue_Mapping = new sub_EscQueue_Mapping();
                Each_sub_Queue_Mapping.queueName = QueueName;
                Each_sub_Queue_Mapping.queueId= QueueName_QueueIDMap.get(Each_sub_Queue_Mapping.queueName);
                Each_sub_Queue_Mapping.queueCount = 0;
                sub_Queue_Mapping_List.add(Each_sub_Queue_Mapping);
                
            }
        }
        
        sub_esc_wrapper.escqueue_List=sub_Queue_Mapping_List;   
        return sub_esc_wrapper;
    }
    
    @AuraEnabled
    public static void saveEscFilters(list<string> SelectedQueuesFromUser){
        
        List<sc_user_filter__c> selectedFilters = new List<sc_user_filter__c>();
        string rectypeid= Schema.SObjectType.sc_user_filter__c.getRecordTypeInfosByName().get('Akatec').getRecordTypeId();
        string userid=userinfo.getUserId()+'-'+rectypeid;
        
        selectedFilters=[select filter_values__c from sc_user_filter__c WHERE Unique_ID__c=:userid limit 1];
        string fullFilter = 'Queue:'+string.join(SelectedQueuesFromUser,',');
        
        if(selectedFilters.size() <1){
            map<string,string> userfiltermap = new map<string,string>();
            userfiltermap.put('EscalationFilters',fullFilter);
            fullFilter = JSON.serialize(userfiltermap);
            
        }
        else
        {
            map<string,object> userfiltermap = (Map<String, object>) JSON.deserializeUntyped (selectedFilters[0].filter_values__c);
            userfiltermap.put('EscalationFilters',fullFilter);
            fullFilter = JSON.serialize(userfiltermap);
            
        }
        
        
        sc_user_filter__c upsertUserData = new sc_user_filter__c(
            Unique_ID__c=userid, 
            recordtypeid=rectypeid,
            filter_values__c =fullFilter
        );
        
        upsert upsertUserData Unique_ID__c;
    }
    
    public static void processLogic(flat_Esc_Wrapper Each_flat_Esc_Wrapper,Engagement_Request__c eachEscRec)
    {
        Each_flat_Esc_Wrapper.akam_esc_id = eachEscRec.Name;
        Each_flat_Esc_Wrapper.escURL = '/'+eachEscRec.id;
        Each_flat_Esc_Wrapper.caseURL='/'+eachEscRec.case__r.Id;
        Each_flat_Esc_Wrapper.account = eachEscRec.Case_Account_Name__c;
        Each_flat_Esc_Wrapper.description = eachEscRec.Description__c;
        Each_flat_Esc_Wrapper.status = eachEscRec.Request_Status__c;
        Each_flat_Esc_Wrapper.support_level = eachEscRec.case__r.Support_Level__c;
        Each_flat_Esc_Wrapper.geography = eachEscRec.Case__r.Support_Geography__c;
        Each_flat_Esc_Wrapper.sev = eachEscRec.ER_Severity__c;
        Each_flat_Esc_Wrapper.age = eachEscRec.Age__c;
        Each_flat_Esc_Wrapper.akam_case_id = eachEscRec.Case_AKAM_Case_ID__c;
        Each_flat_Esc_Wrapper.case_owner = eachEscRec.case__r.Case_Owner_Name__c;
        Each_flat_Esc_Wrapper.case_status = eachEscRec.case__r.status;
        Each_flat_Esc_Wrapper.area = eachEscRec.Area__c;
        
        Each_flat_Esc_Wrapper.GeographyColor = geoName_colorCode.get(eachEscRec.Case__r.Support_Geography__c) !=null ?
            geoName_colorCode.get(eachEscRec.Case__r.Support_Geography__c) : 'Black';
    }
    
    //Method - 13 : Method for my open escalations
    @AuraEnabled
    public static list <flat_Esc_Wrapper>getMyFilteredEscalations(list<string> SelSeverity, list<string> selGeos, list<string> selStatus)
    {   
        List<Engagement_Request__c> FilteredEsc= new List<Engagement_Request__c>();
        List<flat_Esc_Wrapper> flat_Esc_Wrapper_List= new List<flat_Esc_Wrapper>();
        string userid=userinfo.getUserId();
        string MasterQuery='SELECT id, Name, Case_Account_Name__c, Description__c ,case__r.Support_Level__c, case__r.Id, case__r.Support_Geography__c, Request_Status__c, ER_Severity__c, Area__c, Case_AKAM_Case_ID__c, Case__c, case__r.Case_Owner_Name__c, case__r.status, Age__c from Engagement_Request__c where ownerid=:userid and Request_Status__c NOT IN (\'Rejected\',\'Cancelled\',\'Closed\')';
        string dynamicQuery='';
        if(SelSeverity.size()<3)
        {   
            dynamicQuery=dynamicQuery+' and ER_Severity__c IN :SelSeverity'; 
        }
        if(selGeos.size()<4)
        {
            dynamicQuery=dynamicQuery+' and case__r.Support_Geography__c IN :selGeos'; 
        }
        if(selStatus.size()<3)
        {
            dynamicQuery=dynamicQuery+' and Request_Status__c IN :selStatus'; 
        }
        
        MasterQuery=MasterQuery+dynamicQuery+' Order by CreatedDate desc';
        FilteredEsc=Database.query(MasterQuery); 
        If(Test.isRunningTest()){
            FilteredEsc =  [SELECT id, Name, Case_Account_Name__c, Description__c ,case__r.Support_Level__c, case__r.Id, case__r.Support_Geography__c, Request_Status__c, ER_Severity__c, Area__c, Case_AKAM_Case_ID__c, Case__c, case__r.Case_Owner_Name__c, case__r.status, Age__c from Engagement_Request__c LIMIT 50000];
        }
        flat_Esc_Wrapper Each_flat_Esc_Wrapper;
        
        for(Engagement_Request__c eachEscRec: FilteredEsc)
        {
            Each_flat_Esc_Wrapper = new flat_Esc_Wrapper();
            processLogic(Each_flat_Esc_Wrapper,eachEscRec);
            
            flat_Esc_Wrapper_List.add(Each_flat_Esc_Wrapper);
        }
        return flat_Esc_Wrapper_List;
        
    }
    
    //Method - 14 : Method for getting Escalations choosen by the user
    @AuraEnabled 
    public static list <flat_Esc_Wrapper>getAllEscalations()
    {
        
        list<id> lMyQueueIds = new list<id>();
        list<Engagement_Request__c> MyEscalations = new list<Engagement_Request__c>();
        List<flat_Esc_Wrapper> flat_Esc_Wrapper_List= new List<flat_Esc_Wrapper>();
        
        If(Test.isRunningTest()){
            MyEscalations =  [SELECT id, Name, Case_Account_Name__c,Accept_Target_Date__c ,Description__c , case__r.Id, Accept_Target_Mins__c , Accept_Violation__c ,Request_Status__c, Accept_Completed__c ,ER_Severity__c, Area__c ,Case_AKAM_Case_ID__c, Case__c , case__r.Support_Level__c, Case__r.Support_Geography__c, Age__c, Target_Shift__c, Case_Product__c, Case_Owner__c ,  owner.name from Engagement_Request__c order by createddate desc LIMIT 50000];
        }
        
        List<sc_user_filter__c> selectedFilters = new List<sc_user_filter__c>();
        string rectypeid= Schema.SObjectType.sc_user_filter__c.getRecordTypeInfosByName().get('Akatec').getRecordTypeId();
        string userid=userinfo.getUserId()+'-'+rectypeid;
        
        selectedFilters=[select filter_values__c from sc_user_filter__c WHERE Unique_ID__c=:userid limit 1];
        map<string,object> escfiltervalues = (Map<String, object>) JSON.deserializeUntyped (selectedFilters[0].filter_values__c);
        
        list<string> SavedQueues= new list<string>();
        string Filters = string.valueof(escfiltervalues.get('EscalationFilters'));
        SavedQueues.addall(Filters.split(':')[1].split(','));
        
        MyEscalations =  [SELECT id, Name, Case_Account_Name__c,Accept_Target_Date__c ,Description__c , Accept_Target_Mins__c , case__r.Id, Accept_Violation__c ,Request_Status__c, Accept_Completed__c ,ER_Severity__c, Area__c ,Case_AKAM_Case_ID__c, Case__c , case__r.Support_Level__c, Age__c, Case__r.Support_Geography__c, Target_Shift__c, Case_Product__c, Case_Owner__c ,  owner.name from Engagement_Request__c where ownerid in :SavedQueues and recordtype.name != 'External Team' and Request_Status__c NOT IN ('Rejected','Cancelled','Closed') order by createddate desc];    
        
        If(Test.isRunningTest()){
            MyEscalations =  [SELECT id, Name, Case_Account_Name__c,Accept_Target_Date__c ,Description__c , Accept_Target_Mins__c , case__r.Id, Accept_Violation__c ,Request_Status__c, Accept_Completed__c ,ER_Severity__c, Area__c ,Case_AKAM_Case_ID__c, Case__c , case__r.Support_Level__c, Age__c, Case__r.Support_Geography__c, Target_Shift__c, Case_Product__c, Case_Owner__c ,  owner.name from Engagement_Request__c LIMIT 50000];
        }
        
        flat_Esc_Wrapper Each_flat_Esc_Wrapper;
        
        
        for(Engagement_Request__c eachEscrec : MyEscalations){
            Each_flat_Esc_Wrapper = new flat_Esc_Wrapper();
            
            Each_flat_Esc_Wrapper.SLAEsc = '';
            
            // Assigning Escalation record
            Each_flat_Esc_Wrapper.akam_esc_id = eachEscRec.Name;
            Each_flat_Esc_Wrapper.escURL = '/'+eachEscRec.id;
            Each_flat_Esc_Wrapper.account = eachEscRec.Case_Account_Name__c;
            Each_flat_Esc_Wrapper.description = eachEscRec.Description__c;
            Each_flat_Esc_Wrapper.status = eachEscRec.Request_Status__c;
            Each_flat_Esc_Wrapper.support_level = eachEscRec.case__r.Support_Level__c;
            Each_flat_Esc_Wrapper.geography = eachEscRec.Case__r.Support_Geography__c;
            Each_flat_Esc_Wrapper.sev = eachEscRec.ER_Severity__c;
            Each_flat_Esc_Wrapper.age = eachEscRec.Age__c;
            Each_flat_Esc_Wrapper.akam_case_id = eachEscRec.Case_AKAM_Case_ID__c;
            if(eachEscRec.Case_AKAM_Case_ID__c!=null){
                Each_flat_Esc_Wrapper.caseURL='/'+eachEscRec.case__r.Id;
            }
            Each_flat_Esc_Wrapper.case_owner = eachEscRec.Case_Owner__c;
            Each_flat_Esc_Wrapper.esc_owner = eachEscRec.Owner.Name;
            Each_flat_Esc_Wrapper.product = eachEscRec.Case_Product__c; 
            Each_flat_Esc_Wrapper.targetshift=eachEscRec.Target_Shift__c;
            
            //Assigning Color based on Geography
            Each_flat_Esc_Wrapper.GeographyColor = geoName_colorCode.get(eachEscRec.Case__r.Support_Geography__c) !=null ?
                geoName_colorCode.get(eachEscRec.Case__r.Support_Geography__c) : 'Black';
            
            if(eachEscrec.Accept_Target_Mins__c ==null){
                Each_flat_Esc_Wrapper.SLAEsc='';
            }
            else if(eachEscrec.Accept_Completed__c == true && eachEscrec.Accept_Violation__c == false){
                Each_flat_Esc_Wrapper.SLAEsc = '👍';
            }
            else
            {   
                
                Integer sla=(integer.valueOf((eachEscrec.Accept_Target_Date__c.getTime() - DateTime.Now().getTime())/60000));
                Each_flat_Esc_Wrapper.SLA_inmins=sla;
                
                if(sla<0)
                {
                    Each_flat_Esc_Wrapper.SLAEsc='Miss';
                    Each_flat_Esc_Wrapper.SLA_Color='slds-text-color_error';                        
                }
                else if(sla<=15) 
                {
                    Each_flat_Esc_Wrapper.SLAEsc=sla+'m';
                    Each_flat_Esc_Wrapper.SLA_Color='slds-text-color_error';
                }
                else if(sla<45) {
                    Each_flat_Esc_Wrapper.SLAEsc= sla+'m';
                    Each_flat_Esc_Wrapper.SLA_Color='Orange';
                    
                }
                else if(sla<60) {
                    Each_flat_Esc_Wrapper.SLAEsc= sla+'m';
                    Each_flat_Esc_Wrapper.SLA_Color='slds-text-color_success';
                    
                }
                
                else {
                    Each_flat_Esc_Wrapper.SLAEsc = sla/60 + 'h ' +  Math.mod(sla,60) + 'm';
                    Each_flat_Esc_Wrapper.SLA_Color='slds-text-color_success';
                } 
                
            }
            flat_Esc_Wrapper_List.add(Each_flat_Esc_Wrapper);
        }
        return flat_Esc_Wrapper_List;
        
    }   
    
    
    //Method - 15 : Assigns/Accepts the escalation to the current user
    @AuraEnabled
    public static string assignEscalationToUser(string techID)
    {       try{
        Engagement_Request__c updateowner = new Engagement_Request__c(id=techID,Assigned_To__c=userinfo.getUserId(),OwnerId = userinfo.getUserId(),Request_Status__c = 'Accepted');
        update updateowner;
        return 'success';
    }
     catch (exception e)
     {
         return e.getMessage();
     }
     
    }
    
    //---------------------------------Service Incident Related Functionality -------------------------------
    
    public class flatSIWrapper{
        @AuraEnabled public string name{get;set;}
        @AuraEnabled public string siURL{get;set;}
        @AuraEnabled public string siCategoryID{get;set;}
        @AuraEnabled public string servicereqtitle{get;set;}
        @AuraEnabled public string fkimpact{get;set;}
        @AuraEnabled public string fkstatus{get;set;}
        @AuraEnabled public string gssmanager{get;set;}
        @AuraEnabled public string outagestartdate{get;set;}
        
    }
    
    @AuraEnabled
    public static list<flatSIWrapper> getAllServiceIncidents(){
        
        List<flatSIWrapper> flat_si_Wrapper_List= new List<flatSIWrapper>();
        List<SC_SI_Service_Incident__c > IncidentList = new List<SC_SI_Service_Incident__c >();
        
        IncidentList = [select Id,Name, Category__c, Title__c ,Severity__c,
                        Status__c ,BIL__c ,Impact_Started__c 
                        from SC_SI_Service_Incident__c  
                        where Status__c = '1: In Progress' and 
                        SI_Incident_Requested_Date__c = LAST_N_DAYS:7
                        order by Impact_Started__c];
        
        flatSIWrapper Each_flat_SI_Wrapper;
        
        for(SC_SI_Service_Incident__c  eachSIRec : IncidentList){
            Each_flat_SI_Wrapper = new flatSIWrapper();
            
            Each_flat_SI_Wrapper.name=eachSIRec.name;
            Each_flat_SI_Wrapper.siURL='/'+eachSIRec.Id;
            Each_flat_SI_Wrapper.servicereqtitle= eachSIRec.Title__c;
            Each_flat_SI_Wrapper.siCategoryID=eachSIRec.Category__c;
            Each_flat_SI_Wrapper.fkimpact = eachSIRec.Severity__c;  
            Each_flat_SI_Wrapper.fkstatus = eachSIRec.Status__c;
            Each_flat_SI_Wrapper.gssmanager=eachSIRec.BIL__c;
            if(eachSIRec.Impact_Started__c!=null)
                Each_flat_SI_Wrapper.outagestartdate=eachSIRec.Impact_Started__c.format();
            
            flat_si_Wrapper_List.add(Each_flat_SI_Wrapper);
        }
        return flat_si_Wrapper_List;
        
    }
    
}