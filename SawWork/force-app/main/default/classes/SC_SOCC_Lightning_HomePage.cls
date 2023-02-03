/*
Author          : Sumukh SS
Description     : Apex Controller for SOCCDash LWC
Test Class      : SC_SOCC_Case_LightningUtility_TC

Date                 Developer                  JIRA #          Description                                                       
-----------------------------------------------------------------------------------------------------------------
14 March 2020        Sumukh
23 March 2021        Tejaswini                  ESESP-5109      Geo Filter on SOCC Console Should Display Service Theatre if Present
27 OCT 2021          Jay                        ESESP-6265      Added LIMIT 50000 to unbounded SOQLs
17 Nov 2021          Jay                        ESESP-6330      Added filter to fetch US Fed Accounts
------------------------------------------------------------------------------------------------------------------
*/
public class SC_SOCC_Lightning_HomePage {
    
    Public static integer GlobalYellow=0; //slds-icon-standard-article
    Public static integer GlobalWhite=0;
    Public static integer GlobalPurple=0; //slds-icon-custom-custom88
    Public static integer GlobalOverdue=0;
    Public static integer GlobalApproval=0;
    
    //Master wrapper -- Contains all the counts for the Mini-Dashboard
    public class Main_Dash_Wrapper
    {
        @AuraEnabled public integer YellowCount=0;
        @AuraEnabled public integer WhiteCount=0;
        @AuraEnabled public integer PurpleCount=0;
        @AuraEnabled public integer OverdueCount=0;
        @AuraEnabled public integer ApprovalCount=0;
        @AuraEnabled public list<sub_Task_wrapper> FinalList;
        @AuraEnabled public integer TotalCount=0;
    }
    
    public class Sub_Task_wrapper implements Comparable{
        
        @AuraEnabled public string AkamCaseID{get;set;}
        @AuraEnabled public string AkamCaseIDURL{get;set;}
        @AuraEnabled public string AccountName{get;set;}
        @AuraEnabled public string PolicyDomain{get;set;}
        @AuraEnabled public string PolicyDomainURL{get;set;}
        @AuraEnabled public string Severity{get;set;}
        @AuraEnabled public string Geo{get;set;}
        @AuraEnabled public string Subject{get;set;}
        @AuraEnabled public string Problem{get;set;}
        @AuraEnabled public string TaskOwner{get;set;}
        @AuraEnabled public string TaskURL{get;set;}       
        @AuraEnabled public string TaskStatus{get;set;}
        @AuraEnabled public string Tasktype{get;set;}
        @AuraEnabled public string CaseColor{get;set;} // Set final case color (white/purple/dark red/red/blue/green)
        @AuraEnabled public string TaskDueDateinMinutes{get;set;}//Calculating the Task due date from now in Hrs and mins
        @AuraEnabled public string LastUpdateTimeinMinutes{get;set;} 
        @AuraEnabled public string TimeColor{get;set;}//Color based on TaskDueDateinMinutes value
        @AuraEnabled public string CaseLastUpdateBy{get;set;} 
        @AuraEnabled public string NotificationCenterType{get;set;}  //For filtering notification center in SOCCDash
        @AuraEnabled public integer Priority{get;set;}  //Custom priority calculated
        
        //Comparable interface for sorting wrapper based on calculated priority
        public Integer compareTo(Object compareTo)
        {
            sub_Task_wrapper compareToGoal = (sub_Task_wrapper)compareTo;
            
            if(Priority > compareToGoal.Priority)
                return 1;
            else if (Priority < compareToGoal.Priority)
                return -1;
            else
                return 0;
        }
        
    }
    
    // Method - 1: Return saved Geo 
    @AuraEnabled
    public static Map<String,List<String>> getSavedGeo()
    {
        List<SC_QM_User_Filter__c> selectedgeo = new List<SC_QM_User_Filter__c>();
        selectedgeo=[select User_Id__c,Supported_Geography__c,AccountTypesToShow__c from SC_QM_User_Filter__c WHERE User_Id__c=:userinfo.getUserId() limit 1];
        List<String> returnAllGeos = new List<String>{'EMEA','AP','Americas','Japan','Others'};
            
        //Scenario - 1 : If no records then upsert with all geographies and userID
        if(selectedgeo.size()==0){
            SC_QM_User_Filter__c newrow= new SC_QM_User_Filter__c(Supported_Geography__c = 'EMEA;AP;Americas;Japan;Others',User_Id__c=userinfo.getUserId());
            upsert newrow;
        }
        //Scenario - 2 :If record exists but geography is null then just fill the geographies
        else if(selectedgeo[0].Supported_Geography__c==null)
        {
            selectedgeo[0].Supported_Geography__c='EMEA;AP;Americas;Japan;Others'; upsert selectedgeo;
        }
        //Scenario - 3 : else Get the geo and return
        else
        {
            //Converting picklist values to string
            returnAllGeos.clear();
            returnAllGeos.addAll(selectedgeo[0].Supported_Geography__c.split(';'));
        }

        //each_initial_Load_Wrapper.JSHeapLimit = [Select Value_Text__c from SC_Utility__mdt where DeveloperName='SOCCDashjsHeapSizeLimit'].Value_Text__c;
        //return each_initial_Load_Wrapper;
        String accountTypesStr = !selectedgeo.isEmpty() ? selectedgeo[0].AccountTypesToShow__c : null;
        List<String> accountTypes = new List<String>();
        if (!String.isBlank(accountTypesStr)) {
             accountTypes.addAll(accountTypesStr.split(','));
        }
        return new Map<String,List<String>>{
                'geographies' => returnAllGeos,
                'accountTypes' => accountTypes
        };

    }
    
    // Method - 2 : Save User Selected Geo from Filter
    @AuraEnabled
    public static void saveSelectedFilters(list<String> SelectedGeoFromUser, string SOCCDashUserLog, String accountTypesToShow){
        
        SC_QM_User_Filter__c upsertUserData = new SC_QM_User_Filter__c(
            User_Id__c=userinfo.getuserID(), 
            Status__c =SOCCDashUserLog,
            Supported_Geography__c = String.join(SelectedGeoFromUser,';'),
            AccountTypesToShow__c = accountTypesToShow);
        upsert upsertUserData User_Id__c;
    }
    
    
    // Method - 3 : Generating dynamic query based on the saved geographies and selected filters
    public static string GenerateDynamicQuery(string PriorityFilter,string CaseOwnerFilter, string premiumFilter,list<string> SeverityFilter, string searchvalue,string searchtype)
    {
        Map<String,List<String>> savedFilters = getSavedGeo();
        List<String> selectedGeo = savedFilters.get('geographies');
        List<String> accTypes = savedFilters.get('accountTypes');
        
        string dynamicQuery='';
        
        // .........For Geo Condition...............
        //For choosing one geography
        //Changes for  ESESP-5109 
        if(selectedGeo.size() < 5){
            
            dynamicQuery+=' and ((Policy_Domain__r.Service_Theatre__c!=null AND Policy_Domain__r.Service_Theatre__c in (';
            for(integer i=0;i<selectedGeo.size()-1;i++)
            {
                dynamicQuery=dynamicQuery + '\''+selectedGeo[i]+'\''+',';
            }
            dynamicQuery=dynamicQuery + '\''+selectedGeo[selectedGeo.size()-1]+'\''+')';           
            
            dynamicQuery = dynamicQuery+ ' ) OR (Policy_Domain__r.Service_Theatre__c = null AND Geography__c in (';
            for(integer i=0;i<selectedGeo.size()-1;i++)
            {
                dynamicQuery=dynamicQuery + '\''+selectedGeo[i]+'\''+',';
            }
            dynamicQuery=dynamicQuery + '\''+selectedGeo[selectedGeo.size()-1]+'\''+')';         
            
            dynamicQuery = dynamicQuery +'))';
        }
        if (accTypes.contains('excludeUSFed')) {
            dynamicQuery += ' AND AccountId NOT IN (SELECT Id FROM Account WHERE Sub_Vertical__c =\'Federal/Central\' AND Country_Group__c =\'USA\')';
        }
        
        //.........For Premium Condition...............Checking for socc premium customer from account  
        if(premiumFilter == 'true')
            dynamicQuery += ' and account.Is_SOCC_Premium_Customer__c=True';
        else if(premiumFilter == 'false')
            dynamicQuery += ' and account.Is_SOCC_Premium_Customer__c=false';
        
        //.........For Case Owner Condition...............Checking for Case Owner filter   
        dynamicQuery = (CaseOwnerFilter!='All') ? dynamicQuery+ ' and owner.name = '+'\''+CaseOwnerFilter+'\'' :
        dynamicQuery;
        
        //.........For priority Condition...............Checking for case priority type filter 
        dynamicQuery = (PriorityFilter!='All') ? dynamicQuery+' and Priority_Type__c = '+'\''+PriorityFilter+'\'' : 
        dynamicQuery;
        
        //.........For severity Condition...............Checking for severity filter 
        if(SeverityFilter.size() < 3){
            
            dynamicQuery = (SeverityFilter.size() < 2) ? 
                dynamicQuery + ' and Severity__c ='+'\''+SeverityFilter[0]+'\'' : dynamicQuery + ' and Severity__c IN('+'\''+SeverityFilter[0]+'\''+','+'\''+SeverityFilter[1]+'\''+')';
        }
        if(searchvalue!=null)
        {
            dynamicQuery = dynamicQuery + ' and '+searchtype+' like \'%'+searchvalue+'%\'';
        }
        system.debug('dynamic' + dynamicQuery);
        return dynamicQuery;
    }
    
    
    // Method - 4 : Method for getting Rank order from Custom Metadata
    public static Map<string,decimal> getRankFromMetadata(){
        
        //Map containing Mapping for severity + premium customer + priority - rank
        Map<string,decimal> Metadatafields_RankMap = new Map<string,decimal>();
        string mapkey;
        
        // Loop for all Data
        for(SOCCDash_Custom_Priority__mdt eachmetadatavalue : [Select Rank__c ,Case_Severity__c ,SOCC_Premium_Customer__c , Priority_Case__c from SOCCDash_Custom_Priority__mdt LIMIT 50000])
        {
            mapkey=eachmetadatavalue.Case_Severity__c+'-'+eachmetadatavalue.SOCC_Premium_Customer__c+'-'+eachmetadatavalue.Priority_Case__c;
            Metadatafields_RankMap.put(mapkey,eachmetadatavalue.Rank__c);
        }
        
        return Metadatafields_RankMap;
    }
    
    // Method - 5 : Custom Merge Sorting for SOCC Due Date
    public static List<task> SortOptionList(List<task> ListToSort)
    {   
        if(ListToSort == null || ListToSort.size() <= 1)
            return ListToSort;
        
        List<task> Less = new List<task>();
        List<task> Greater = new List<task>();
        integer pivot = 0;
        
        // save the pivot and remove it from the list
        task pivotValue = ListToSort[pivot];
        ListToSort.remove(pivot);
        
        for(task x : ListToSort)
        {
            if(x.DueDateProlexic__c <= pivotValue.DueDateProlexic__c)
                Less.add(x);
            else if(x.DueDateProlexic__c > pivotValue.DueDateProlexic__c) Greater.add(x);   
        }
        List<task> returnList = new List<task> ();
        returnList.addAll(SortOptionList(Less));
        returnList.add(pivotValue);
        returnList.addAll(SortOptionList(Greater));
        
        
        return returnList;
    }
    
    // Method - 6 : Assigning Case data to each wrapper field
    public static void processLogic(sub_Task_wrapper Each_sub_Task_wrapper,case eachcaseRec)
    {
        if(eachcaseRec.Priority_Type__c!=null)
        { if(eachcaseRec.Priority_Type__c=='High Alert Customer')  Each_sub_Task_wrapper.AkamCaseID='❗'+eachcaseRec.AKAM_Case_ID__c;
         else if(eachcaseRec.Priority_Type__c=='Hot Customer')  Each_sub_Task_wrapper.AkamCaseID='🔥'+eachcaseRec.AKAM_Case_ID__c;
         else if(eachcaseRec.Priority_Type__c=='White Glove Treatment')  Each_sub_Task_wrapper.AkamCaseID='✋🏻'+eachcaseRec.AKAM_Case_ID__c;
        }
        else
            Each_sub_Task_wrapper.AkamCaseID=eachcaseRec.AKAM_Case_ID__c;
        Each_sub_Task_wrapper.AkamCaseIDURL='/'+eachcaseRec.Id;
        //Changes for ESESP-5109 
        if(eachcaseRec.Policy_Domain__r.Service_Theatre__c!=null)
        {
            Each_sub_Task_wrapper.Geo=eachcaseRec.Policy_Domain__r.Service_Theatre__c;
        }
        else{
            Each_sub_Task_wrapper.Geo=eachcaseRec.Geography__c;
        }
        if(eachcaseRec.Account.Name!=null)
        {
            if(eachcaseRec.Account.Is_SOCC_Premium_Customer__c==true && eachcaseRec.Account.Service_Country_Affinity__c==true)
                Each_sub_Task_wrapper.AccountName='⭐'+'⛳'+eachcaseRec.Account.Name;
            else if(eachcaseRec.Account.Is_SOCC_Premium_Customer__c==true)
                Each_sub_Task_wrapper.AccountName='⭐'+eachcaseRec.Account.Name;
            else if(eachcaseRec.Account.Service_Country_Affinity__c==true)
                Each_sub_Task_wrapper.AccountName='⛳'+eachcaseRec.Account.Name;
            else
                Each_sub_Task_wrapper.AccountName=eachcaseRec.Account.Name;    
        }
        if(eachcaseRec.Policy_Domain__r.Name!=null)
        {
            Each_sub_Task_wrapper.PolicyDomain=eachcaseRec.Policy_Domain__r.Name;
            Each_sub_Task_wrapper.PolicyDomainURL='/'+eachcaseRec.Policy_Domain__r.Id;
        }
        Each_sub_Task_wrapper.Severity=eachcaserec.Severity__c;
        Each_sub_Task_wrapper.Subject=eachcaserec.Subject;
        Each_sub_Task_wrapper.Problem=eachcaserec.Problem__c;
        
        //----------------------------Calculating the Case Modified Time-------------------------------
        Integer getCaseMinuteValue = integer.valueOf((EachCaseRec.lastmodifieddate.getTime()/1000/60 - system.now().getTime()/1000/60) );
        Each_sub_Task_wrapper.LastUpdateTimeinMinutes = (getCaseMinuteValue/60 * -1) + 'h ' +  Math.mod(getCaseMinuteValue * -1,60) + 'm ago';
        //----------------------------Calculating LastUpdateBy value----------------------------
        Each_sub_Task_wrapper.CaseLastUpdateBy = (EachCaseRec.Last_Update_By__c=='Customer') ?
            'Customer' : EachCaseRec.AKAM_Modified_By__c; 
        
    }
    
    // Method - 7 : Main method for returning wrapper values to SOCDash
    @AuraEnabled
    public static Main_Dash_Wrapper getSocHomeTask(string PriorityFilter, string CaseOwnerFilter, string premiumFilter, list<string> SeverityFilter, string searchvalue, string searchtype){
        
        // List for Final Wrapper set of Wrapper Rec
        main_Dash_Wrapper each_main_Dash_Wrapper = new main_Dash_Wrapper();
        List<sub_Task_wrapper> sub_Task_wrapper_List=new list<sub_Task_wrapper>();
        sub_Task_wrapper Each_sub_Task_wrapper; // Each Wrapper Rec
        list<case> masterCaseList = new list<case>();
        
        // Metadata Related Variables
        Map<string,decimal> Metadatafields_RankMap = new Map<string,decimal>();
        string caseparameters; // Used to pass the case parameters to Metadatafields_RankMap. Map returns the case rank
        decimal caserank;
        
        map<id, case> Caseid_CaseDetails_Map = new map<id,case>();
        list<task> allRelatedTasks = new list<task>(); // Used for Custom sorting
        
        // Step - 1 : Get Rank from Metadata   
        Metadatafields_RankMap = getRankFromMetadata(); 
        
        map<string,string> color_SLDSColorclass_Map = new map<string,string>();
        
        // Loop for Coloring metaData
        for(SC_Utility__mdt  eachmetadatavalue : [Select DeveloperName ,Value_Text__c from SC_Utility__mdt where DeveloperName IN ('Blue','DarkRed','Green','LightRed','Orange','Purple','Yellow')]) 
        { color_SLDSColorclass_Map.put(eachmetadatavalue.DeveloperName ,eachmetadatavalue.Value_Text__c); }
        
        // Step - 2 : Query to Get All Cases + Tasks        
        string masterQuery='select id,AKAM_Case_ID__c,status,account.Service_Country_Affinity__c,Priority_Type__c,recent_update__c,Policy_Domain__r.Name,Policy_Domain__r.id,Policy_Domain__r.Service_Theatre__c,Last_Update_By__c ,AKAM_Modified_By__c,Is_SOCC_Priority__c ,Problem__c,account.Is_SOCC_Premium_Customer__c ,geography__c, Account.Name, lastmodifieddate, Severity__c,subject,Sub_Type__c,(select DueDateProlexic__c, owner.alias, Type__c, Status,whatid from tasks where DueDateProlexic__c != null and status NOT IN (\'Completed\', \'Completed Important\', \'Closed Duplicate\', \'Not Applicable\')) from case where recordtype.name=\'Managed Security\' and isclosed=false';
        MasterQuery += GenerateDynamicQuery(PriorityFilter,CaseOwnerFilter,premiumFilter,SeverityFilter,searchvalue,searchtype);
        MasterQuery += ' order by lastmodifieddate asc'; 
        masterCaseList=database.query(masterQuery);
        
        system.debug('master = '+MasterQuery);
        
        // Step - 3 : Loop for each Case
        for(case eachcaseRec : masterCaseList)
        {
            Each_sub_Task_wrapper=new sub_Task_wrapper();
            
            //.........White Case Logic.............
            if(EachCaseRec.status=='Unassigned')
            {
                processLogic(Each_sub_Task_wrapper,eachcaseRec);
                
                // Calculating Priority & Color    
                caseparameters = EachCaseRec.Severity__c+'-'+EachCaseRec.Account.Is_SOCC_Premium_Customer__c+'-'+EachCaseRec.Is_SOCC_Priority__c;
                decimal indivisualtaskrank = Metadatafields_RankMap.get(caseparameters);
            
                    Each_sub_Task_wrapper.Priority =Integer.valueOf(indivisualtaskrank);   
                    Each_sub_Task_wrapper.CaseColor = 'white';
                    if(EachCaseRec.Sub_Type__c!='Runbook Review') 
                    {GlobalWhite++;Each_sub_Task_wrapper.NotificationCenterType='white';}
                    else {GlobalApproval++; Each_sub_Task_wrapper.NotificationCenterType='runbook';}
                    
                
                // Adding to Final Wrapper
                sub_Task_wrapper_List.add(Each_sub_Task_wrapper);
            }
            
            //Purple Case Check
            else if(EachCaseRec.status!='Unassigned' && eachcaseRec.tasks.size() == 0)
            {   
                processLogic(Each_sub_Task_wrapper,eachcaseRec);
                
                // Calculating Priority & Color
                caseparameters = EachCaseRec.Severity__c+'-'+EachCaseRec.Account.Is_SOCC_Premium_Customer__c+'-'+EachCaseRec.Is_SOCC_Priority__c;
                decimal indivisualtaskrank = Metadatafields_RankMap.get(caseparameters);
                Each_sub_Task_wrapper.Priority = (EachCaseRec.recent_update__c==true) ? 
                    Integer.valueOf(indivisualtaskrank)+12 : Integer.valueOf(indivisualtaskrank) + 24;
                
                if(EachCaseRec.recent_update__c==true)
                {
                    Each_sub_Task_wrapper.CaseColor =color_SLDSColorclass_Map.get('Yellow');  GlobalYellow++;
                    Each_sub_Task_wrapper.NotificationCenterType='yellow';
                }
                else { Each_sub_Task_wrapper.CaseColor =color_SLDSColorclass_Map.get('Purple');   GlobalPurple++;
                      Each_sub_Task_wrapper.NotificationCenterType='purple';
                     }
                
                // Adding to Final Wrapper
                sub_Task_wrapper_List.add(Each_sub_Task_wrapper);
            }          
            
            // For Rest of the Cases
            else if(EachCaseRec.status!='Unassigned' && eachcaseRec.tasks.size() > 0)
            {
                Caseid_CaseDetails_Map.put(EachCaseRec.id, EachCaseRec);
                allRelatedTasks.addAll(eachcaseRec.tasks);
            }
        }
        
        // Deallocating Memory
        masterCaseList.clear();
        
        // Step - 4 : Call to Custom Sort Method for Due Date
        List<task> tempTask = SortOptionList(allRelatedTasks);
        
        // Step - 5 : Loop for all Sorted Task
        for(task eachsortedtask : tempTask)
        {           
            Each_sub_Task_wrapper=new sub_Task_wrapper();            
            case EachCaseRec=Caseid_CaseDetails_Map.get(eachsortedtask.whatid);
            
            processLogic(Each_sub_Task_wrapper,eachcaseRec);
            
            Each_sub_Task_wrapper.TaskOwner=eachsortedtask.owner.alias;
            Each_sub_Task_wrapper.Tasktype=eachsortedtask.Type__c;
            Each_sub_Task_wrapper.TaskURL='/'+eachsortedtask.id;
            Each_sub_Task_wrapper.taskStatus=eachsortedtask.status;
            
            
            // Calculate Time Color & Task Due Date
            Integer getMinuteValue = integer.valueOf((eachsortedtask.DueDateProlexic__c.getTime()/1000/60 - system.now().getTime()/1000/60) );
            Each_sub_Task_wrapper.TimeColor = (getMinuteValue < 0) ? 'slds-text-color_error' : 'slds-text-color_success';
            Each_sub_Task_wrapper.TaskDueDateinMinutes = (getMinuteValue < 0) ? 
                '-'+ (getMinuteValue/60 * -1) + 'h ' +  Math.mod(getMinuteValue * -1,60) + 'm' : getMinuteValue/60 + 'h ' +  Math.mod(getMinuteValue,60) + 'm';
            
            
            //-------------------------------------Assigning custom priority and color coding to cases------------------------------------------------------------
            //Managed Security Case on which a customer response has been received. This case may/may not have tasks.
            
            caseparameters = EachCaseRec.Severity__c+'-'+EachCaseRec.Account.Is_SOCC_Premium_Customer__c+'-'+EachCaseRec.Is_SOCC_Priority__c;
            decimal indivisualtaskrank = Metadatafields_RankMap.get(caseparameters);
            
            if(EachCaseRec.recent_update__c==true)
            {
                Each_sub_Task_wrapper.Priority=Integer.valueOf(indivisualtaskrank)+12;
                Each_sub_Task_wrapper.CaseColor=color_SLDSColorclass_Map.get('Yellow');
                Each_sub_Task_wrapper.NotificationCenterType='yellow';
                GlobalYellow++;
            }
            
            //Managed Security Case with over due 'Attack' Task -- Dark red
            else if(eachsortedtask.Type__c=='Attack' && Each_sub_Task_wrapper.TimeColor=='slds-text-color_error')
            {
                Each_sub_Task_wrapper.Priority=Integer.valueOf(indivisualtaskrank)+36;
                Each_sub_Task_wrapper.CaseColor=color_SLDSColorclass_Map.get('DarkRed');
                Each_sub_Task_wrapper.NotificationCenterType='overdue';
                GlobalOverdue++;
            }
            //Managed Security Case with over due Tasks other than 'Attack' task. -- cyan
            else if(eachsortedtask.Type__c!='Attack' && Each_sub_Task_wrapper.TimeColor=='slds-text-color_error')
            {
                Each_sub_Task_wrapper.Priority=Integer.valueOf(indivisualtaskrank)+48;
                Each_sub_Task_wrapper.CaseColor=color_SLDSColorclass_Map.get('LightRed');
                Each_sub_Task_wrapper.NotificationCenterType='overdue';
                GlobalOverdue++;
            }
            //Managed Security Case with Tasks due between 0-6 hours.--orange
            else if(getMinuteValue>=0 && getMinuteValue<=360)
            {
                Each_sub_Task_wrapper.Priority=Integer.valueOf(indivisualtaskrank)+60;
                Each_sub_Task_wrapper.CaseColor=color_SLDSColorclass_Map.get('Orange');
            }
            //Managed Security Case with Tasks due between 6- 12 hours.
            else if(getMinuteValue>360 && getMinuteValue<=720)
            {
                Each_sub_Task_wrapper.Priority=Integer.valueOf(indivisualtaskrank)+72;
                Each_sub_Task_wrapper.CaseColor=color_SLDSColorclass_Map.get('Blue'); 
            }
            else if(getMinuteValue>720)
            {
                Each_sub_Task_wrapper.Priority=Integer.valueOf(indivisualtaskrank)+84;
                Each_sub_Task_wrapper.CaseColor=color_SLDSColorclass_Map.get('Green');   
            }
            sub_Task_wrapper_List.add(Each_sub_Task_wrapper);
            
        }
        
        // Step - 6 :Final Sorting based on Priority
        
        sub_Task_wrapper_List.sort();
        
        each_main_Dash_Wrapper.FinalList=sub_Task_wrapper_List;
        each_main_Dash_Wrapper.TotalCount=sub_Task_wrapper_List.size();
        each_main_Dash_Wrapper.YellowCount=GlobalYellow;
        each_main_Dash_Wrapper.WhiteCount=GlobalWhite;
        each_main_Dash_Wrapper.PurpleCount=GlobalPurple;
        each_main_Dash_Wrapper.OverdueCount=GlobalOverdue;
        each_main_Dash_Wrapper.ApprovalCount=GlobalApproval;
        
        // Deallocating Memory - 2
        
        Metadatafields_RankMap.clear();
        Caseid_CaseDetails_Map.clear();
        allRelatedTasks.clear();
        tempTask.clear();
        
        return each_main_Dash_Wrapper;
        
    } 
    
     @AuraEnabled
    public static string getRecordTypeID()
    {
        string devRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Managed Security').getRecordTypeId();
		return devRecordTypeId;
    }
}