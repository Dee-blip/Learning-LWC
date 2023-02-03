/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE           DEVELOPER   CR          DESCRIPTION                                                       

|  ===========    =========   =======     =========== 
                                                       
|   27-Jul-2015     Akhila    CR 2948861    Controller Class for SC_EPE_HomePage
|   27-May-2016     Vamsee    CR 3125711    Removed filter for My team cases section
|   01-Sep-2016     Pinkesh   CR 3264651    Displaying products based on record types
|   26-Jun-2018     Vandhana  ESESP-319     OLA for Escalations (Renamed Engagament Request to Escalation)
+=====================================================================================================*/
public without sharing class SC_EPE_HomePageCtrl {

    public String passRecId{get;set;}

    public transient String lQCaseERjson{get;set;}
    public transient String lMCaseERjson{get;set;} 
    public transient String lMTeamCaseERjson{get;set;} 
    public Integer cLimit;
    public String defaultClause; 
    public String pickFlag{get;set;}       
    //public String MyTeamFilter {get;set;}      
    public String MyFilter {get;set;}      
    public String QFilter {get;set;}                
    
    //Constructor
    public SC_EPE_HomePageCtrl(){
        pickFlag='false';

        cLimit = Agent_Home_Collection_Limit__c.getValues('HomeScreenLimit').Collection_Limit__c.intValue();
        defaultClause=' Order by CreatedDate desc Limit '+cLimit;
        //MyTeamFilter='My Work';
        MyFilter='My Work';
        QFilter='My Queues';

    }    
    
    public void pickCaseER(){
        pickFlag='false';
        if(passRecId.startswith('500'))
        {
            Case c = [Select Id,Owner.Type from Case where Id=:passRecId limit 1];
            if(c!=null && c.Owner.Type!='User')
            {
                c.OwnerId = UserInfo.getUserId();
                Database.DMLOptions dlo = new Database.DMLOptions();
                dlo.EmailHeader.triggerUserEmail = true;
                c.setOptions(dlo);
                try{
                    update c;
                    pickFlag='true';
                }
                catch(Exception e)
                {
                    pickFlag='false';
                }
            }
        }
        else
        {
            Engagement_Request__c e = [Select Id,Owner.Type from Engagement_Request__c where Id=:passRecId limit 1];
            if(e!=null && e.Owner.Type!='User')
            {
                e.OwnerId = UserInfo.getUserId();
                e.Assigned_To__c = UserInfo.getUserId();
                try{
                    update e;
                    pickFlag='true';
                }
                catch(Exception ex)
                {
                    pickFlag='false';        
                }
            }
        }
        populateQTable();
    }
    
    public void populateMyTeamTable()
    {
        List<CaseERWrapperClass_MyTeamTable> lMyCaseERwraps = new List<CaseERWrapperClass_MyTeamTable>();
        List<Case> lMyCase = new List<Case>();
        //List<Engagement_Request__c> lMyER=new List<Engagement_Request__c>();
        Map<Id,CaseMilestone> mMyCaseMile = new Map<Id,CaseMilestone>();
        //String CaseClause='';
        //String ERClause='';
        /*
        if(MyTeamFilter=='My Work')
        {
            CaseClause=' OwnerId =\''+UserInfo.getUserId()+'\' and isClosed = False';
            //ERClause=' OwnerId =\''+UserInfo.getUserId()+'\' ';
        }
        else if(MyTeamFilter=='Hide Pending')
        {
            CaseClause=' OwnerId =\''+UserInfo.getUserId()+'\' and isClosed = False and Status !=\'Mitigated / Solution Provided\'';
            //ERClause=' OwnerId =\''+UserInfo.getUserId()+'\' and Request_Status__c !=\'Pending\'';    
        }
        else 
        {
            List<Id> lCaseFollowIds = new List<Id>();
            //List<Id> lERFollowIds = new List<Id>();
            for(EntitySubscription en: [SELECT Id,ParentId,Parent.Type FROM EntitySubscription WHERE SubscriberId =:UserInfo.getUserId() and Parent.Type='Case'])
            {
                lCaseFollowIds.add(en.ParentId);                    
            }
            CaseClause=' isClosed = False  and Id IN :lCaseFollowIds';
            //ERClause=' Id IN :lERFollowIds';    
        }
        */
        lMyCase =  Database.query('Select Id,CaseNumber,AKAM_Case_ID__c,AccountId,Account.Name,Subject, Support_Level__c, Severity__c, AKAM_Created_Date__c,OwnerId,Owner.Name,Age_days__c,Status,Resolution_Sent__c,Recent_Update__c,Task_LOE__c, Incident_Name__c, Incident__c, EPE24x7__c, Critical_Customer__c from Case where RecordType.DeveloperName=\'Emerging_Products_Engineering\' and' +
        ' (Severity__c =\'1\' or EPE24x7__c = True or Critical_Customer__c = True or Incident__c !=null ) and isClosed = False'+defaultClause);        
         
        /*lMyER =  Database.query('Select Id,Name, ER_Severity__c,Case__c,Case__r.AKAM_Case_ID__c,Case__r.AccountId,Case__r.Account.Name,Case__r.CaseNumber, Description__c, Case__r.Support_Level__c,AKAM_Created_Date__c,Case__r.ProductPL__c,Case__r.Resolution_Sent__c,OwnerId,Owner.Name,Request_Status__c,Case__r.Task_LOE__c,Age__c,Case__r.Incident_Name__c, Case__r.Incident__c, Case__r.EPE24x7__c, Case__r.Critical_Customer__c from Engagement_Request__c where '+ERClause+' and RecordType.DeveloperName=\'Emerging_Products_Engineering\' and Request_Status__c NOT IN (\'Rejected\',\'Cancelled\',\'Closed\') '+defaultClause);   */ 
        
        for(CaseMilestone cm: [Select Id,CaseId,TargetResponseInMins,StartDate,isviolated,IsCompleted from caseMilestone where CaseId IN:lMyCase and milestonetype.Name='Initial Response'])
        {
            mMyCaseMile.put(cm.CaseId,cm);
        }
            
        //My work section
        CaseERWrapperClass_MyTeamTable cWrap;
        //CaseERWrapperClass_MyTeamTable eWrap;
        for(Case c:lMyCase)
        {
            cWrap = new CaseERWrapperClass_MyTeamTable(c,mMyCaseMile.ContainsKey(c.Id)?mMyCaseMile.get(c.Id):null);
            lMyCaseERwraps.add(cWrap);
        }
        
        /*for(Engagement_Request__c e:lMyER)
        {
            eWrap = new CaseERWrapperClass_MyTeamTable(e,mMyCaseMile.ContainsKey(e.Case__c)?mMyCaseMile.get(e.Case__c):null);
            lMyCaseERwraps.add(eWrap);
        }*/

        lMTeamCaseERjson = JSON.serialize(lMyCaseERwraps);
        lMyCaseERwraps.clear();
        lMyCase.clear();
        //lMyER.clear();
        mMyCaseMile.clear();
    }

    public void populateMyTable()
    {
        List<CaseERWrapperClass_MyTable> lMyCaseERwraps = new List<CaseERWrapperClass_MyTable>();
        List<Case> lMyCase = new List<Case>();
        List<Engagement_Request__c> lMyER=new List<Engagement_Request__c>();
        Map<Id,CaseMilestone> mMyCaseMile = new Map<Id,CaseMilestone>();
        String CaseClause='';
        String ERClause='';
    
        if(MyFilter=='My Work')
        {
            CaseClause=' OwnerId =\''+UserInfo.getUserId()+'\' and isClosed = False';
            ERClause=' OwnerId =\''+UserInfo.getUserId()+'\' ';
        }
        else if(MyFilter=='Hide Pending')
        {
            CaseClause=' OwnerId =\''+UserInfo.getUserId()+'\' and isClosed = False and Status !=\'Mitigated / Solution Provided\'';
            ERClause=' OwnerId =\''+UserInfo.getUserId()+'\' and Request_Status__c !=\'Pending\'';    
        }
        else 
        {
            List<Id> lCaseFollowIds = new List<Id>();
            List<Id> lERFollowIds = new List<Id>();
            for(EntitySubscription en: [SELECT Id,ParentId,Parent.Type FROM EntitySubscription WHERE SubscriberId =:UserInfo.getUserId() and (Parent.Type='Case' or Parent.Type='Engagement_Request__c' )])
            {
                if(en.Parent.Type=='Case')
                    lCaseFollowIds.add(en.ParentId);    
                else
                    lERFollowIds.add(en.ParentId);        
            }
            CaseClause=' isClosed = False  and Id IN :lCaseFollowIds';
            ERClause=' Id IN :lERFollowIds';    
        }
        lMyCase =  Database.query('Select Id,CaseNumber,AKAM_Case_ID__c,AccountId,Account.Name,Subject, Support_Level__c, Severity__c, AKAM_Created_Date__c,OwnerId,Owner.Name,Age_days__c,Status,Resolution_Sent__c,Recent_Update__c,Task_LOE__c from Case where'+CaseClause+defaultClause);        
        
        lMyER =  Database.query('Select Id,Name, ER_Severity__c,Case__c,Case__r.AKAM_Case_ID__c,Case__r.AccountId,Case__r.Account.Name,Case__r.CaseNumber, Description__c, Case__r.Support_Level__c,AKAM_Created_Date__c, Case__r.Resolution_Sent__c,OwnerId,Owner.Name,Request_Status__c,Case__r.Task_LOE__c,Age__c from Engagement_Request__c where '+ERClause+' and Request_Status__c NOT IN (\'Rejected\',\'Cancelled\',\'Closed\') '+defaultClause);    
        
        for(CaseMilestone cm: [Select Id,CaseId,TargetResponseInMins,StartDate,isviolated,IsCompleted from caseMilestone where CaseId IN:lMyCase and milestonetype.Name='Initial Response'])
        {
            mMyCaseMile.put(cm.CaseId,cm);
        }
        
        //My work section
        CaseERWrapperClass_MyTable cWrap;
        CaseERWrapperClass_MyTable eWrap;
        for(Case c:lMyCase)
        {
            cWrap = new CaseERWrapperClass_MyTable(c,mMyCaseMile.ContainsKey(c.Id)?mMyCaseMile.get(c.Id):null);
            lMyCaseERwraps.add(cWrap);
        }
        
        for(Engagement_Request__c e:lMyER)
        {
            eWrap = new CaseERWrapperClass_MyTable(e,mMyCaseMile.ContainsKey(e.Case__c)?mMyCaseMile.get(e.Case__c):null);
            lMyCaseERwraps.add(eWrap);
        }
        lMCaseERjson = JSON.serialize(lMyCaseERwraps);
        lMyCaseERwraps.clear();
        lMyCase.clear();
        lMyER.clear();
        mMyCaseMile.clear();
    }
    
    
    public void populateQTable()
    {
        List<Id> lMyQueueIds = new List<Id>();    
        List<CaseERWrapperClass_QueueTable> lCaseERwraps = new List<CaseERWrapperClass_QueueTable>();
        Map<Id,CaseMilestone> mQCaseMile = new Map<Id,CaseMilestone>();
        List<Id> lAccId = new List<Id>();
        Map<Id,String> mAccTeam = new Map<Id,String>();
        List<Engagement_Request__c> lER=new List<Engagement_Request__c>();
        List<Case> lCase = new List<Case>();
        
        //Set of CCare Queue Ids for ER and Case and initializing based on Filter
        if(QFilter=='My Queues')
        {
            for(GroupMember g: [Select Group.Name,Group.Id,Group.DeveloperName from GroupMember where UserorGroupId =:UserInfo.getUserId() and Group.Type='Queue'])
            {
                lMyQueueIds.add(g.Group.Id);
            }
        }
        else 
        {
            for(QueueSobject q : [Select Id, SobjectType, QueueId,Queue.DeveloperName from QueueSobject where (SobjectType = 'Engagement_Request__c' OR SobjectType = 'Case') and Queue.DeveloperName like 'CC%'])
             {
                if(QFilter=='All CCare Queues - Escalations')
                {
                    if(q.SobjectType == 'Engagement_Request__c')
                        lMyQueueIds.add(q.QueueId);
                }
                else if(QFilter=='All CCare Queues - Cases')
                {
                    if(q.SobjectType == 'Case')
                        lMyQueueIds.add(q.QueueId);
                }
             }
        }
        lCase = [Select Id,CaseNumber,AKAM_Case_ID__c,AccountId,Account.Name,Subject, Support_Level__c, Severity__c, AKAM_Created_Date__c, ProductPL__c, Case_Prod_Name__c, OwnerId,Owner.Name,Age_days__c,Status,Recent_Update__c,Task_LOE__c, RecordType.DeveloperName, (Select isViolated, TimeRemainingInMins from CaseMilestones limit 1) from Case where OwnerId IN :lMyQueueIds and isClosed = False order by CreatedDate desc limit :cLimit];
        
        lER = [Select Id,Name, ER_Severity__c,Case__r.AKAM_Case_ID__c,Case__r.AccountId,Case__r.Account.Name,Case__r.CaseNumber, Description__c, Case__r.Support_Level__c,AKAM_Created_Date__c,Case__r.ProductPL__c, Case__r.Case_Prod_Name__c, Case__r.RecordType.DeveloperName, OwnerId,Owner.Name,Case__r.Recent_Update__c,Request_Status__c,Case__r.Task_LOE__c,Age__c from Engagement_Request__c where OwnerId IN :lMyQueueIds and Request_Status__c NOT IN ('Closed','Cancelled','Rejected') order by CreatedDate desc limit :cLimit];             
        
        for(CaseMilestone cm: [Select Id,CaseId,TargetResponseInMins,StartDate,isviolated,IsCompleted from caseMilestone where CaseId IN:lCase and milestonetype.Name='Initial Response'])
        {
            mQCaseMile.put(cm.CaseId,cm);
        }
          
        CaseERWrapperClass_QueueTable cWrap;
        CaseERWrapperClass_QueueTable eWrap;
        //Queue Section
        for(Case c:lCase)
        {
            cWrap = new CaseERWrapperClass_QueueTable(c,mQCaseMile.ContainsKey(c.Id)?mQCaseMile.get(c.Id):null);
            lCaseERwraps.add(cWrap);
        }
        for(Engagement_Request__c e:lER)
        {
            eWrap = new CaseERWrapperClass_QueueTable(e,mQCaseMile.ContainsKey(e.Case__c)?mQCaseMile.get(e.Case__c):null);
            lCaseERwraps.add(eWrap);
        }
        lQCaseERjson = JSON.serialize(lCaseERwraps); 
        lMyQueueIds.clear();
        lCaseERwraps.clear();
        mQCaseMile.clear();
        lER.clear();
        lCase.clear();
    }
        

    //To populate data for first table    
    public  Class CaseERWrapperClass_MyTeamTable extends CaseERWrapperClass_MyTable{           
        
        //Adding extra variables specific to EPE - MyTeam Table
        public String is24x7{get;set;}
        public String CriticalCustomer{get;set;}
        public String IncidentNumber{get;set;}
        public String IncidentId{get;set;}
        public String OwnerName{get;set;}
        public String OwnerId{get;set;}

        //For Case Object
        public CaseERWrapperClass_MyTeamTable(Case c,CaseMilestone CaseMile)
        {
            super(c,CaseMile);
            is24x7 = c.EPE24x7__c ? '1':'2';
            CriticalCustomer = c.Critical_Customer__c ? '1':'2';
            OwnerName = c.Owner.Name;
            OwnerId =  c.OwnerId;
            if(c.Incident__c != null)
            {
                IncidentNumber = c.Incident_Name__c;
                IncidentId = c.Incident__c;
            }
        }
        
        //For ER Object
        /*public CaseERWrapperClass_MyTeamTable(Engagement_Request__c e,CaseMilestone CaseMile)
        {
            super(e,CaseMile);
            is24x7 = e.Case__r.EPE24x7__c ? '2':'1';
            CriticalCustomer = e.Case__r.Critical_Customer__c ? '1':'2';
            if(e.Case__r.Incident__c != null)
            {
                IncidentNumber = e.Case__r.Incident_Name__c;
                IncidentId = e.Case__r.Incident__c;
            }
        } */           
    }    

    //To populate data for second table    
    public virtual Class CaseERWrapperClass_MyTable extends SC_UtilClass_HomePage_Tables{       
    
        //Adding extra variables specific to My Table
        public String Status{get;set;}
        public String Age{get;set;}
        public String Alert{get;set;}
        public String ResolutionSent{get;set;}        
        
        //For Case Object
        public CaseERWrapperClass_MyTable(Case c,CaseMilestone CaseMile)
        {
            super(c,CaseMile);

            Status = c.Status==null?'':c.Status;
            Age = String.valueOf(c.Age_days__c);
            Alert = c.Recent_Update__c==true?'1':'2';
            ResolutionSent = (c.Resolution_Sent__c==true?'t':'z');            
        }
       
        //For ER Object
        public CaseERWrapperClass_MyTable(Engagement_Request__c e,CaseMilestone CaseMile)
        {         
            super(e,CaseMile);

            Status = e.Request_Status__c==null?'':e.Request_Status__c;
            Age = String.ValueOf(e.Age__c);
            Alert = '2';
            ResolutionSent = e.Case__r.Resolution_Sent__c==true?'t':'z';
        }
    }

    //To populate data for third table    
    public without sharing Class CaseERWrapperClass_QueueTable extends SC_UtilClass_HomePage_Tables{       
        
        //Adding extra variables specific to Queue Table
        public String AkamCreatedDate{get;set;}
        public String CaseProduct{get;set;}
        public String OwnerName{get;set;}
        public String OwnerId{get;set;}
        public String formattedDate{get;set;}
            
        //For Case Object
        public CaseERWrapperClass_QueueTable(Case c,CaseMilestone CaseMile)
        {
            super(c,CaseMile);

            AkamCreatedDate=c.AKAM_Created_Date__c==null?'':String.ValueOf(c.AKAM_Created_Date__c);
            if(c.RecordType.DeveloperName == 'Emerging_Products_Engineering')
                caseProduct=c.ProductPL__c==null?'':c.ProductPL__c;
            else
                CaseProduct=c.Case_Prod_Name__c==null?'':c.Case_Prod_Name__c;
            OwnerName = c.Owner.Name;
            OwnerId = c.OwnerId;
            formattedDate = c.AKAM_Created_Date__c==null?'':String.ValueOf(c.AKAM_Created_Date__c.format());            
        }
       
        //For ER Object
        public CaseERWrapperClass_QueueTable(Engagement_Request__c e,CaseMilestone CaseMile)
        { 
            super(e,CaseMile);
            
            AkamCreatedDate = e.AKAM_Created_Date__c==null?'':String.ValueOf(e.AKAM_Created_Date__c);
            if(e.Case__r.RecordType.DeveloperName == 'Emerging_Products_Engineering')
                CaseProduct = e.Case__r.ProductPL__c==null?'':e.Case__r.ProductPL__c;
            else
                CaseProduct = e.Case__r.Case_Prod_Name__c==null?'':e.Case__r.Case_Prod_Name__c;
            OwnerName = e.Owner.Name;
            OwnerId = e.OwnerId;
            formattedDate = e.AKAM_Created_Date__c==null?'':String.ValueOf(e.AKAM_Created_Date__c.format());     
        }  
    }
}