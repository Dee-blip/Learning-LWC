/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE           DEVELOPER         CR          DESCRIPTION                                                       

|  ===========    =========         =======     =========== 
                                                       
|  12-Oct-2015    Deepak Saxena     2596476     Controller Class for SC_BillingSupportConsole
+=====================================================================================================*/
public without sharing class SC_BillingSupportConsoleController {

    public Id recTypeId;
    public Id SIrecTypeId;
    public String BillingListViewId {get; set;}
    public String MyOpenCaseListViewId {get; set;}
    public String MyClosedCaseListViewId {get; set;}
    public String passRecId{get;set;}
    public String passMyRecId{get;set;}
    public List<String> sumLOE{get;set;}
    public transient Integer extListSize{get;set;}
    public transient String lQCaseERjson{get;set;}
    public transient String lMCaseERjson{get;set;} 
    public transient String lMCaseExtjson{get;set;} 
    public Integer cLimit;
    public Integer SILimit;
    public String defaultClause; 
    public String pickFlag{get;set;}
    public String reportId{get;set;}
    public Integer totalUnassigned{get;set;}
    public Integer totalUnassigned2{get;set;}
    public Integer allOpenMyCases{get;set;}
    public Integer allClosedMyCases{get;set;}
    public Integer allCaseswithIRViolated{get;set;}
    public Integer allCaseswithResViolated{get;set;}
    public String DashboardFilter{get;set;}
    public String DashboardFilter2{get;set;}    
    public String MyFilter {get;set;}      
    public String QFilter {get;set;} 
    public Integer section3Limit {get;set;} 
    public Integer section4Limit {get;set;}  
    public Integer section5Limit {get;set;}  
    public String hiddenCaseId{get;set;}        
    
    //Constructor
    public SC_BillingSupportConsoleController(){
        section3Limit = SC_Billing_Support_Home_Console_Limits__c.getValues('External Dependency Section 3').Limit__c.intValue();
        section4Limit = SC_Billing_Support_Home_Console_Limits__c.getValues('My Cases Section 4').Limit__c.intValue();
        section5Limit = SC_Billing_Support_Home_Console_Limits__c.getValues('Billing Support Queue Section 5').Limit__c.intValue();
        pickFlag='false';
        reportId='';    
        cLimit = Agent_Home_Collection_Limit__c.getValues('HomeScreenLimit').Collection_Limit__c.intValue();
        reportId= SCUserIdCustomSetting__c.getValues('HomeScreenReportId').UserId__c;
        SILimit = cLimit*2;
        defaultClause=' Order by CreatedDate desc Limit '+cLimit;
        recTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Billing').getRecordTypeId();
        DashboardFilter='This Month';
        DashboardFilter2='This Month';
        updateDashboard();
        updateDashboard2();
        String q = 'SELECT Id FROM Case LIMIT 1';
        ApexPages.StandardSetController c = new ApexPages.StandardSetController(Database.getQueryLocator(q));
        List<SelectOption> ListViews = c.getListViewOptions();
        for(SelectOption w : ListViews ){
            if(w.getLabel()=='Billing Queue'){
                BillingListViewId = w.getValue().left(15);
                System.debug('????BillingList ViewId '+BillingListViewId);
            }
            if(w.getLabel()=='My Open Cases'){
                MyOpenCaseListViewId = w.getValue().left(15);
                System.debug('????MyOpenCases ViewId '+MyOpenCaseListViewId);
            }
            if(w.getLabel()=='My Closed Cases'){
                MyClosedCaseListViewId = w.getValue().left(15);
                System.debug('????MyCLosedCases ViewId '+MyClosedCaseListViewId);
            }
        }

    }    
    
    public void pickCaseER(){
        pickFlag='false';
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
        
        populateQTable();
    }

    
    public void updateDashboard(){
        totalUnassigned=0;
        totalUnassigned2=0;
        
        String Filter= '';
        if(DashboardFilter=='This Month') {
            Filter=' And CreatedDate = THIS_MONTH';
        }
        else if(DashboardFilter=='This Quarter') {
            Filter=' And CreatedDate = THIS_QUARTER';
        }
        else {
            Filter=' And CreatedDate = THIS_YEAR';
        }  
        
        System.debug('/////'+Filter);
        List<Id> lMyQueueIds = new List<Id>();
        List<group> BillingSupportQueue = [SELECT id, name FROM GROUP WHERE type = 'queue' AND name = 'Billing Queue'];
                    if (BillingSupportQueue != null && BillingSupportQueue.size() > 0 ){
                        lMyQueueIds.add(BillingSupportQueue.get(0).id);
                    }        
        DateTime endDate = System.now().addDays(-1);    
        totalUnassigned = Database.Countquery('Select count() from Case where OwnerId=\''+lMyQueueIds[0]+'\' AND isClosed = false AND RecordTypeId = \'' + recTypeId + '\'' + Filter) ;
        System.debug('???'+'Select count() from Case where OwnerId=\''+lMyQueueIds[0]+'\' AND isClosed = false AND CreatedDate < \'' + endDate + '\'' + Filter);
        totalUnassigned2 = Database.Countquery('Select count() from Case where OwnerId=\''+lMyQueueIds[0]+'\' AND isClosed = false AND CreatedDate < :endDate AND RecordTypeId = \'' + recTypeId + '\'' + Filter) ;
                
    }
    
    public void updateDashboard2(){
        allOpenMyCases=0;
        allClosedMyCases=0;
        allCaseswithIRViolated=0;
        allCaseswithResViolated=0;
        String Filter= '';
        if(DashboardFilter2=='This Month') {
            Filter=' And CreatedDate = THIS_MONTH';
        }
        else if(DashboardFilter2=='This Quarter') {
            Filter=' And CreatedDate = THIS_QUARTER';
        }
        else {
            Filter=' And CreatedDate = THIS_YEAR';
        }  
        
        List<Case> caseList = Database.query('Select Id from Case where OwnerId=\''+UserInfo.getUserId()+'\' AND isClosed = false AND RecordTypeId = \'' + recTypeId + '\'' + Filter) ;
        
        allOpenMyCases = caseList.size();
        
        allClosedMyCases = Database.Countquery('Select count() from Case where OwnerId=\''+UserInfo.getUserId()+'\' AND isClosed = True AND RecordTypeId = \'' + recTypeId + '\'' + Filter) ;
        
        //Number of Cases with IR SLA Violated
        
        Set<Id> casewithIRViolated = new Set<Id>();
        
        for(CaseMilestone cm: [Select Id,CaseId,TargetResponseInMins,StartDate,isviolated,IsCompleted from caseMilestone where CaseId IN :caseList and milestonetype.Name='Initial Response' AND isviolated=True]) {
                casewithIRviolated.add(cm.CaseId);
        }
        
        allCaseswithIRViolated = casewithIRviolated.size();
        
        //Number of Cases with Res SLA Violated
        
        Set<Id> casewithResViolated = new Set<Id>();
        
        
        for(CaseMilestone cm: [Select Id,CaseId,TargetResponseInMins,StartDate,isviolated,IsCompleted from caseMilestone where CaseId IN :caseList and milestonetype.Name='Resolution' AND isviolated=True]) {
                casewithResViolated.add(cm.CaseId);
        }
        
        allCaseswithResViolated = casewithResViolated.size();
                
    }
    
    public void populateExternalDependencyTable() {
        List<CaseERWrapperClass> lMyCaseERwraps = new List<CaseERWrapperClass>();
        List<Case> caseList = new List<Case>();
        Map<Id,String> caseIdextDependencyTypeMap = new Map<Id,String>();
        Map<Id,CaseMilestone> mAllCaseResMile = new Map<Id,CaseMilestone>();
        
        String Filter=' Limit '+ section3Limit;        
        
        caseList = [Select Id,CaseNumber,AKAM_Case_ID__c, AccountId, Account.Name, AKAM_Created_Date__c from Case where OwnerId = :UserInfo.getUserId() and isClosed = false AND RecordTypeId = :recTypeId Limit 1000] ;
        
        for(External_Dependency__c ed: [Select Id, Type__c, Case__c From External_Dependency__c Where Case__c IN :caseList Limit :section3Limit]){
                
                if(caseIdextDependencyTypeMap.containsKey(ed.Case__c)){
                    String str = caseIdextDependencyTypeMap.get(ed.Case__c) + ',' + ed.Type__c;
                    caseIdextDependencyTypeMap.put(ed.Case__c, str);
                }
                else{
                    caseIdextDependencyTypeMap.put(ed.Case__c,ed.Type__c);
                }
        }
        
        extListSize = caseIdextDependencyTypeMap.Values().size();
        System.debug('/???/?'+extListSize);
        for(CaseMilestone cm: [Select Id, CaseId, TargetResponseInMins, StartDate, isviolated, IsCompleted, milestonetype.Name from caseMilestone where CaseId IN :caseList and milestonetype.Name = 'Resolution']){
                    mAllCaseResMile.put(cm.CaseId,cm);
        }
        
        CaseERWrapperClass cWrap;
        
        for(Case c : caseList) {
            if(caseIdextDependencyTypeMap.containsKey(c.Id)){
                cWrap = new CaseERWrapperClass(c, null, mAllCaseResMile, caseIdextDependencyTypeMap.get(c.Id), 'extTable');
                lMyCaseERwraps.add(cWrap);
            }
        }
        System.debug('/???/?Final COunt'+lMyCaseERwraps.size());
        lMCaseExtjson = JSON.serialize(lMyCaseERwraps);
        lMyCaseERwraps.clear();
        caseList.clear();
        mAllCaseResMile.clear();
    }
    
    public void populateMyTable() {
        List<CaseERWrapperClass> lMyCaseERwraps = new List<CaseERWrapperClass>();
        List<Case> lMyCase = new List<Case>();
        Map<Id,CaseMilestone> mMyCaseIniMile = new Map<Id,CaseMilestone>();
        Map<Id,CaseMilestone> mMyCaseResMile = new Map<Id,CaseMilestone>();
        Map<Id,String> caseIdextDependencyTypeMap = new Map<Id,String>();
                
        lMyCase =  [Select Id, CreatedDate, Contact.Name,CaseNumber,AKAM_Case_ID__c, Origin, AccountId, Account.Name,Subject, AKAM_Created_Date__c,OwnerId,Owner.Name,Age_days__c,Status,Resolution_Sent__c,Recent_Update__c,Task_LOE__c,has_active_transition__c from Case where OwnerId = :UserInfo.getUserId() and isClosed = False Limit :section4Limit];        
    
        for(CaseMilestone cm: [Select Id, CaseId, TargetResponseInMins, StartDate, isviolated, IsCompleted, milestonetype.Name from caseMilestone where CaseId IN:lMyCase and milestonetype.Name IN ('Initial Response', 'Resolution')]){
                if(cm.milestonetype.Name == 'Initial Response')
                    mMyCaseIniMile.put(cm.CaseId,cm);
                if(cm.milestonetype.Name == 'Resolution')
                    mMyCaseResMile.put(cm.CaseId,cm);
        }
        
        for(External_Dependency__c ed: [Select Id, Type__c, Case__c From External_Dependency__c Where Case__c IN :lMyCase]){
                
                if(caseIdextDependencyTypeMap.containsKey(ed.Case__c)){
                    String str = caseIdextDependencyTypeMap.get(ed.Case__c) + ',' + ed.Type__c;
                    caseIdextDependencyTypeMap.put(ed.Case__c, str);
                }
                else
                    caseIdextDependencyTypeMap.put(ed.Case__c,ed.Type__c);
        }
        
        //My work section
        CaseERWrapperClass cWrap;
        for(Case c:lMyCase) {
            cWrap = new CaseERWrapperClass(c, mMyCaseIniMile, mMyCaseResMile, caseIdextDependencyTypeMap.get(c.Id), 'mywork');
            lMyCaseERwraps.add(cWrap);
        }
        lMCaseERjson = JSON.serialize(lMyCaseERwraps);
        lMyCaseERwraps.clear();
        lMyCase.clear();
        mMyCaseIniMile.clear();
        mMyCaseResMile.clear();
    }
    
    
    public void populateQTable() {
        List<Id> lMyQueueIds = new List<Id>();    
        List<CaseERWrapperClass> lCaseERwraps = new List<CaseERWrapperClass>();
        Map<Id,CaseMilestone> mQCaseMile = new Map<Id,CaseMilestone>();
        List<Case> lCase = new List<Case>();
        
        System.debug(QFilter);
        
        //Set of CCare Queue Ids for ER and Case and initializing based on Filter
         List<group> BillingSupportQueue = [SELECT id, name FROM GROUP WHERE type = 'queue' AND name = 'Billing Queue'];
                    if (BillingSupportQueue != null && BillingSupportQueue.size() > 0 ){
                        lMyQueueIds.add(BillingSupportQueue.get(0).id);
                    }        
        System.debug('????'+BillingSupportQueue);
        lCase = [Select Id,CaseNumber,AKAM_Case_ID__c,AccountId,Account.Name, Contact.Name, CreatedDate, Subject, Support_Level__c, Severity__c, AKAM_Created_Date__c, Age_days__c,Status,Recent_Update__c,Task_LOE__c from Case where OwnerId IN :lMyQueueIds and isClosed = False order by CreatedDate desc limit :section5Limit];
        System.debug('????'+lCase.size());
        for(CaseMilestone cm: [Select Id,CaseId,TargetResponseInMins,StartDate,isviolated,IsCompleted from caseMilestone where CaseId IN:lCase and milestonetype.Name='Initial Response']) {
                mQCaseMile.put(cm.CaseId,cm);
        }
        CaseERWrapperClass cWrap;
        //Queue Section
        for(Case c:lCase) {
            cWrap = new CaseERWrapperClass(c, mQCaseMile, null, null, 'queue');
            lCaseERwraps.add(cWrap);
        }
        lQCaseERjson = JSON.serialize(lCaseERwraps); 
        lMyQueueIds.clear();
        lCaseERwraps.clear();
        mQCaseMile.clear();
        lCase.clear();
    }
        
    
    public without sharing Class CaseERWrapperClass{       
        public String qicon{get;set;}
        public List<String> qList{get;set;}
        public String qSLA{get;set;}
        
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
    
        public CaseERWrapperClass(Case c, Map<Id,CaseMilestone> mapCaseIniMile, Map<Id,CaseMilestone> mapCaseResMile, String extDepType, String TableType) {
                qList=new List<String>();
                String a='';
            
            if(TableType=='extTable'){
                //0- AKam CAse Id
                qList.add(c.AKAM_Case_ID__c);
                //1-Case SFDC Id  
                qList.add(c.Id);
                //2-Account Name
                qList.add(c.Account.Name==null?'':c.Account.Name);
                //3-Account Id
                qList.add(c.AccountId==null?'':c.AccountId); 
                
                //4-External Dependency extDepType
                qList.add(extDepType==null?'':extDepType);
                
                //5-Resolution SLA
                Long t2 =-1;
                String resSLA = '';
                if(mapCaseResMile.ContainsKey(c.Id)) {
                    
                        t2 = mapCaseResMile.get(c.Id).TargetResponseInMins - (DateTime.Now().getTime() - mapCaseResMile.get(c.Id).StartDate.getTime())/60000;
                        /*if(t2 > 0){
                            resSLA = String.valueOf((Integer)Math.floor(t2/1440)) + ' : ';
                            Integer t3 = (Integer)Math.mod(t2,1440);
                            resSLA = resSLA + String.valueOf((Integer)Math.floor(t3/60)) + ' : ';
                            resSLA = resSLA + String.valueOf((Integer)Math.mod(t3,60));
                        }
                        else{
                            resSLA = 'Missed';
                    
                        } */
                    
                }
                if(!mapCaseResMile.ContainsKey(c.Id)) {
                    qList.add('z');
                }
                else if(mapCaseResMile.get(c.Id).IsCompleted) {
                    qList.add('y');
                }
                else {
                    qList.add(String.valueOf(t2));
                }     
                //6-Akam Created Date
                qList.add(c.AKAM_Created_Date__c==null?'':String.ValueOf(c.AKAM_Created_Date__c));                          
                
            }
            
            else if (TableType=='queue'){
            //0- AKam CAse Id
            qList.add(c.AKAM_Case_ID__c);
            //1-Case SFDC Id  
            qList.add(c.Id);
            //2-Account Name
            qList.add(c.Account.Name==null?'':c.Account.Name);
            //3-Account Id
            qList.add(c.AccountId==null?'':c.AccountId);      
            //4-Subject
            qList.add(c.Subject==null?'':c.Subject); 
            //5-Contact Name
            qList.add(c.Contact.Name==null?'':c.Contact.Name);            
            //6-Initial Response SLA
            Long t =-1;
            if(mapCaseIniMile.ContainsKey(c.Id)) {
                t = (mapCaseIniMile.get(c.Id).TargetResponseInMins - (DateTime.Now().getTime() - mapCaseIniMile.get(c.Id).StartDate.getTime())/60000)/60;
            }
            if(!mapCaseIniMile.ContainsKey(c.Id)) {
                qList.add('z');
            }
            else if(mapCaseIniMile.get(c.Id).IsCompleted) {
                qList.add('y');
            }
            else {
                qList.add(String.valueOf(t));
            }
             
            //7 - Object Type, Case/ER
            qList.add('case');
            
            //8-Age
                Long t2 = (DateTime.Now().getTime() - c.CreatedDate.getTime())/60000;
                /* Integer t3 = (Integer)Math.Floor(t2/1440);
                Integer t4 = Math.MOD((Integer)t2,1440);
                Integer t5 = Math.MOD(t4,60);
                String age = String.valueOf(t3) + ' : ' + String.valueOf((Integer)Math.Floor((Integer)t4/60)) + ' : ' + String.valueOf(t5); */
                qList.add(String.valueOf(t2));
                
            //9-Akam Created Date
                qList.add(c.AKAM_Created_Date__c==null?'':String.ValueOf(c.AKAM_Created_Date__c));
                
                //10-formatted date
                qList.add(c.AKAM_Created_Date__c==null?'':String.ValueOf(c.AKAM_Created_Date__c.format()));
            
            }
            else {    
                //0- AKam CAse Id
            qList.add(c.AKAM_Case_ID__c);
            //1-Case SFDC Id  
            qList.add(c.Id);
            //2-Account Name
            qList.add(c.Account.Name==null?'':c.Account.Name);
            //3-Account Id
            qList.add(c.AccountId==null?'':c.AccountId);      
            //4-Subject
            qList.add(c.Subject==null?'':c.Subject); 
            //5-Contact Name
            qList.add(c.Contact.Name==null?'':c.Contact.Name);            
            //6-Initial Response SLA
            Long t =-1;
                //String resSLA = '';
                if(mapCaseIniMile.ContainsKey(c.Id)) {
                    
                    t = (mapCaseIniMile.get(c.Id).TargetResponseInMins - (DateTime.Now().getTime() - mapCaseIniMile.get(c.Id).StartDate.getTime())/60000);
                    /* if(t > 0){
                        resSLA = String.valueOf((Integer)Math.floor(t/1440)) + ' : ';
                        Integer t4 = (Integer)Math.mod(t,1440);
                        resSLA = resSLA + String.valueOf((Integer)Math.floor(t4/60)) + ' : ';
                        resSLA = resSLA + String.valueOf((Integer)Math.mod(t4,60));
                    }
                    else{
                        resSLA = 'Missed';
                    
                    } */
                }
            if(!mapCaseIniMile.ContainsKey(c.Id)) {
                qList.add('z');
            }
            else if(mapCaseIniMile.get(c.Id).IsCompleted) {
                qList.add('y');
            }
            else {
                qList.add(String.valueOf(t));
            }
             
            //7 - Object Type, Case/ER
            qList.add('case');
            
            //8-Age
                Long t6 = (DateTime.Now().getTime() - c.CreatedDate.getTime())/60000;
                /* Integer t7 = (Integer)Math.Floor(t6/1440);
                Integer t8 = Math.MOD((Integer)t6,1440);
                Integer t9 = Math.MOD(t8,60);
                String age = String.valueOf(t7) + ' : ' + String.valueOf((Integer)Math.Floor((Integer)t8/60)) + ' : ' + String.valueOf(t9); */
                qList.add(String.valueOf(t6));
                
                //9-Status
                qList.add(c.Status==null?'':c.Status);
                //10-Origin
                qList.add(c.Origin==null?'':c.Origin);
                //11-Alert
                qList.add(c.Recent_Update__c==true?'1':'2');
                //12-Resolution SLA
                Long t2 =-1;
                //String resSLA2 = '';
                if(mapCaseResMile.ContainsKey(c.Id)) {
                    
                    t2 = mapCaseResMile.get(c.Id).TargetResponseInMins - (DateTime.Now().getTime() - mapCaseResMile.get(c.Id).StartDate.getTime())/60000;
                    /* if(t2 > 0){
                        resSLA2 = String.valueOf((Integer)Math.floor(t2/1440)) + ' : ';
                        Integer t3 = (Integer)Math.mod(t2,1440);
                        resSLA2 = resSLA2 + String.valueOf((Integer)Math.floor(t3/60)) + ' : ';
                        resSLA2 = resSLA2 + String.valueOf((Integer)Math.mod(t3,60));
                    }
                    else{
                        resSLA2 = 'Missed';
                    
                    } */
                }
                if(!mapCaseResMile.ContainsKey(c.Id)) {
                    qList.add('z');
                }
                else if(mapCaseResMile.get(c.Id).IsCompleted) {
                    qList.add('y');
                }
                else {
                    qList.add(String.valueOf(t2));
                }                               
                //13-LOE
                qList.add(String.ValueOf(c.Task_LOE__c==null?0:c.Task_LOE__c));
                //14-External Dependency extDepType
                qList.add(extDepType==null?'':extDepType);
                

            }
            
        }
        
    } 
    public void suppressCaseUpdate(){
        try{
            case c = new Case(id= hiddenCaseId);
            c.recent_update__c = false;
            update c;
        } 
        catch(Exception e){
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL,e.getMessage()));
        }
    }

    
}