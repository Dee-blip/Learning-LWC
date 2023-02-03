/* ========================================================================
    Author: Samir Jha
    Description: Controller for the Timecards Approval Page   
    Created Date : 04/01/2016
    Changed by Sharath on 21st Feb 2018: For delegated approver of timecards
    ======================================================================== */

public class PSA_BulkApproveFromEmailController 
{

    
        
    public Id currentUserId {
        get
        {
            if(currentUserId == null)
            {
                currentUserId = UserInfo.getUserId();   
            }
            return currentUserId;
        }
        set;
    }    
    public void RefreshFilterProject() {
        MyFilter1 = NULL;
        MyFilter4 = NULL;
    }
    public void RefreshFilterMilestone() {
        MyFilter4 = NULL;
        
    }
    public void resetFilters() {
        MyFilter1 = NULL;
        MyFilter2 = NULL;
        MyFilter3 = NULL;
        MyFilter4 = NULL;
        MyFilter6 = NULL;
        MyFilter7 = NULL;
        MyFilter9 = '--None--';

        //Changes by Sharath for delegated approval of timecards: clearing the filter        
        MyFilter10 = '';
    }
    public string Query{ get; set; }
    public date MyFilter6 {get;set;}
    public date MyFilter7 {get;set;}  
    public string MyFilter9{get;set;}

    //Changes by Sharath for delegated approval of timecards: Adding a filter for delegated timecards
    public string MyFilter10{get;set;}
    public string url{
        get
        {
            if(url == null)
            {
                  url = System.URL.getSalesforceBaseUrl().toExternalForm() + '/apex/PSA_BulkApproveTimecardPoller';  
            }
            return url;
        }
        set;
        }
    public string DisplayMessage {get;set;}
    public Date MyFilter8 { 
        get{
            if(MyFilter8==null && apexpages.currentpage().getparameters().get('Date')!=NULL && TypeFilter == 'Daily' )
            {
                DisplayMessage = 'Showing Timecards submitted on ' + date.parse(apexpages.currentpage().getparameters().get('Date')).format();
                return date.parse(apexpages.currentpage().getparameters().get('Date'));
            }
            else if(MyFilter8==null && apexpages.currentpage().getparameters().get('Date')!=NULL && TypeFilter == 'Weekly' )
            {
                DisplayMessage = 'Showing Timecards submitted between ' + date.parse(apexpages.currentpage().getparameters().get('Date')).format() +'-'+ (date.parse(apexpages.currentpage().getparameters().get('Date')).addDays(6)).format() ;
                return date.parse(apexpages.currentpage().getparameters().get('Date'));
            }
            else
            {
                return MyFilter8;
            }
        }
        set; 
    }
    public String TypeFilter { 
        get{
            if(TypeFilter==null)
                return apexpages.currentpage().getparameters().get('Type');
            else
                return TypeFilter;
        }
        set; 
    }
    public String QueryWhere = '';
    public String FinalQuery {get;set;}
    public String MyFilter5 { get; set; }
    public String MyFilter3 { 
        get{
            if(MyFilter3==null)
                return apexpages.currentpage().getparameters().get('ResFilter');
            else
                return MyFilter3;
        }
        set; 
    }    
    public String MyFilter2 { 
        get{
            if(MyFilter2==null)
                return apexpages.currentpage().getparameters().get('AccFilter');
            else
                return MyFilter2;
        }
        set; 
    }
    public String MyFilter4 { 
        get{
            if(MyFilter2==null||MyFilter1==null)
            {
                return NULL;
            }
            else
            {
                return MyFilter4;
            }
    
        } 
        set; 
    }
    public String Comments {get; set;}
    public String Comments1 {get; set;}   
    public String MyFilter1 { 
        get{
            if(MyFilter1==null)
                return (apexpages.currentpage().getparameters().get('projFilter'));
            else if(MyFilter2==null)
                return NULL;
            else
                return MyFilter1;
        }
        set; 
    }
    public transient String lMCaseERjson{get;set;} 
    public transient String actualApproverJson{get;set;} 
    public Date StartDate {get;set;}
    public Date EndDate {get;set;}
    public String MyFilter {get;set;}
    public integer piwSize{
        get{
            if(piw==NULL)
            return 0;
            else
            return piw.size();
        }
        set;
    }
    
    //Changes by Sharath for Delegated approval of timecards. Selecting all the users for who the logged-in user is a delegated user and querying all the timecards pending with them as well.
    public list<ProcessInstanceWorkitem> piw {
        get
        {
            //Changes by Sharath for the delegation approval of timecards. 
            Map<Id,Date> actorIds = new Map<Id,Date>();
            if(MyFilter10!= NULL && MyFilter10 != '')
            {
                if(MyFilter10 == 'True')
                {
                    for(User delegatedUser: [select id,Delegation_EndTime__c from user where DelegatedApproverid = :UserInfo.getUserId()])
                    {
                        Date delegationStartDate = delegatedUser.Delegation_EndTime__c != null? delegatedUser.Delegation_EndTime__c : null;
                        actorIds.put(delegatedUser.id,delegationStartDate);
                    }

                }
                else if(MyFilter10 == 'False')
                {
                    actorIds.put(UserInfo.getUserId(),null);  
                }
            }
            else
            {
                actorIds.put(UserInfo.getUserId(),null);  
                for(User delegatedUser: [select id,Delegation_EndTime__c from user where DelegatedApproverid = :UserInfo.getUserId()])
                {
                    Date delegationStartDate = delegatedUser.Delegation_EndTime__c != null? delegatedUser.Delegation_EndTime__c : null;
                    actorIds.put(delegatedUser.id,delegationStartDate);
                }

            }        

            //Changing the query: actors in the actorIds list
            if(TypeFilter == 'Daily')
            {                
                //return [Select id,ActorId,ProcessInstance.TargetObjectId,ProcessInstance.Status from ProcessInstanceWorkitem where ActorId=:UserInfo.getUserId() and ProcessInstance.Status = 'Pending' and CreatedDate>=:MyFilter8 and CreatedDate<:MyFilter8.addDays(1)];
                return [Select id,ActorId,Actor.Name,ProcessInstance.TargetObjectId,ProcessInstance.Status from ProcessInstanceWorkitem where ActorId in :actorIds.keySet() and ProcessInstance.Status = 'Pending' and CreatedDate>=:MyFilter8 and CreatedDate<:MyFilter8.addDays(1)];
            }
            else if(TypeFilter == 'Weekly')
            {
                //return [Select id,ActorId,ProcessInstance.TargetObjectId,ProcessInstance.Status from ProcessInstanceWorkitem where ActorId=:UserInfo.getUserId() and ProcessInstance.Status = 'Pending' and CreatedDate>=:MyFilter8 and CreatedDate<:MyFilter8.addDays(7)];
                return [Select id,ActorId,Actor.Name,ProcessInstance.TargetObjectId,ProcessInstance.Status from ProcessInstanceWorkitem where ActorId in :actorIds.keySet() and ProcessInstance.Status = 'Pending' and CreatedDate>=:MyFilter8 and CreatedDate<:MyFilter8.addDays(7)];
            }
            //return [Select id,ActorId,ProcessInstance.TargetObjectId,ProcessInstance.Status from ProcessInstanceWorkitem where ActorId=:UserInfo.getUserId() and ProcessInstance.Status = 'Pending'];
            Integer recordLimit = PSA_Settings__c.getInstance('MultiApprovalWorkItemLimit') == null ? 1000: Integer.valueOf(PSA_Settings__c.getInstance('MultiApprovalWorkItemLimit').Value__c);            

            return [Select id,ActorId,Actor.Name,ProcessInstance.TargetObjectId,ProcessInstance.Status from ProcessInstanceWorkitem where ActorId in :actorIds.keySet() and ProcessInstance.Status = 'Pending' limit :recordLimit];
        }
        set;
    } 
    public list<String> TC2ApproveBYUser = new list<String>();
    public list<String> TC2ApproveBYUserIds = new list<String>();
    public list<pse__Timecard_Header__c> TC2ApproveBYUserFilters {
        get
        {

            Integer recordLimit = PSA_Settings__c.getInstance('MultiApprovalTimecardRecordLimit') == null ? 1000: Integer.valueOf(PSA_Settings__c.getInstance('MultiApprovalTimecardRecordLimit').Value__c);            
            
            for(ProcessInstanceWorkitem piwItem2:piw)
            {
                TC2ApproveBYUserIds.add(piwItem2.ProcessInstance.TargetObjectId);
            }
            //Changes by Sharath for Delegated approval of timecards: order by Delegated_Approver__c,pse__Approver__c. Added limit. Default value is 1000
            //Changed the query: pse__Approver__r.Name,pse__Approver__c,pse__Approver__r.ManagerId,pse__Approver__r.Manager.Name,Delegated_Approver__c
            return [SELECT Id,pse__Approver__r.Name,pse__Approver__c,pse__Approver__r.ManagerId,pse__Approver__r.Manager.Name,Delegated_Approver__c,pse__Billable__c,Name,pse__Milestone__c,pse__Project_Methodology_Object__c,pse__Resource__r.Name,pse__Resource__r.pse__Salesforce_User__c,pse__Resource__c,pse__Status__c, pse__Friday_Hours__c , pse__Monday_Hours__c , pse__Saturday_Hours__c , pse__Sunday_Hours__c , pse__Thursday_Hours__c , pse__Tuesday_Hours__c , pse__Wednesday_Hours__c , pse__Friday_Notes__c , pse__Monday_Notes__c , pse__Saturday_Notes__c , pse__Sunday_Notes__c , pse__Thursday_Notes__c , pse__Tuesday_Notes__c , pse__Wednesday_Notes__c ,pse__Additional_Notes__c,pse__Project__c,pse__Project__r.Name,pse__Project__r.pse__Account__c,pse__Total_Hours__c,pse__Start_Date__c, Weekly_User_Timecards_Key__c from pse__Timecard_Header__c where pse__Status__c!='Approved' and pse__Status__c!='Saved' and Id in:TC2ApproveBYUserIds order by Delegated_Approver__c  limit :recordLimit];
        }
        set;
    }     
    public list<pse__Timecard_Header__c> getTimecards2Approve() {
        return NULL; 
    }
    public pse__Proj__c proj {get;set;}
    public list<pse__Timecard_Header__c> TC = new list<pse__Timecard_Header__c>();
    public void refreshMyFilters() {
            
    }
    //Changes by Sharath for Delegated approver of timecards. Modifying the query to fetch the required fields and delegated timecards
    public void populateMyTable() {
        Map<Id, List<String>> timecardToApprover = new Map<Id, List<String>>();
        //Fetch all the users who have made the logged in user as their delegated user.
        Integer timecardRecordLimit = PSA_Settings__c.getInstance('MultiApprovalTimecardRecordLimit') == null ? 1000: Integer.valueOf(PSA_Settings__c.getInstance('MultiApprovalTimecardRecordLimit').Value__c);            

        Integer workitemLimit = PSA_Settings__c.getInstance('MultiApprovalWorkItemLimit') == null ? 1000: Integer.valueOf(PSA_Settings__c.getInstance('MultiApprovalWorkItemLimit').Value__c);            

        Map<Id,Date> actorIds = new Map<Id,Date>();

        //Check if the delegated filter is selected
        //If yes, then get all the delegated timecards; otherwise get all the actual timecards pending with the current approver
        if(MyFilter10!= NULL && MyFilter10 != '')
        {
            if(MyFilter10 == 'True')
            {
                for(User delegatedUser: [select id,Delegation_EndTime__c from user where DelegatedApproverid = :UserInfo.getUserId()])
                {
                    Date delegationStartDate = delegatedUser.Delegation_EndTime__c != null? delegatedUser.Delegation_EndTime__c : null;                    
                    actorIds.put(delegatedUser.id,delegationStartDate);
                }

            }
            else if(MyFilter10 == 'False')
            {
                actorIds.put(UserInfo.getUserId(),null);  
            }
        }
        else
        {
            actorIds.put(UserInfo.getUserId(),null);  
            for(User delegatedUser: [select id,Delegation_EndTime__c from user where DelegatedApproverid = :UserInfo.getUserId()])
            {
                Date delegationStartDate = delegatedUser.Delegation_EndTime__c != null? delegatedUser.Delegation_EndTime__c : null;
                actorIds.put(delegatedUser.id,delegationStartDate);
            }

        }        
        if(TypeFilter == 'Daily')
        {
            //piw = [Select id,ActorId,ProcessInstance.TargetObjectId,ProcessInstance.Status from ProcessInstanceWorkitem where ActorId=:UserInfo.getUserId() and ProcessInstance.Status = 'Pending' and CreatedDate>=:MyFilter8 and CreatedDate<:MyFilter8.addDays(1)];
            piw = [Select id,ActorId,Actor.Name,ProcessInstance.TargetObjectId,ProcessInstance.Status from ProcessInstanceWorkitem where ActorId in :actorIds.keySet() and ProcessInstance.Status = 'Pending' and CreatedDate>=:MyFilter8 and CreatedDate<:MyFilter8.addDays(1)];
        }
        else if(TypeFilter == 'Weekly')
        {
            //piw = [Select id,ActorId,ProcessInstance.TargetObjectId,ProcessInstance.Status from ProcessInstanceWorkitem where ActorId=:UserInfo.getUserId() and ProcessInstance.Status = 'Pending' and CreatedDate>=:MyFilter8 and CreatedDate<:MyFilter8.addDays(7)];
            piw = [Select id,ActorId,Actor.Name,ProcessInstance.TargetObjectId,ProcessInstance.Status from ProcessInstanceWorkitem where ActorId in :actorIds.keySet() and ProcessInstance.Status = 'Pending' and CreatedDate>=:MyFilter8 and CreatedDate<:MyFilter8.addDays(7)];
        }
        else 
        {
            //piw = [Select id,ActorId,ProcessInstance.TargetObjectId,ProcessInstance.Status from ProcessInstanceWorkitem where ActorId=:UserInfo.getUserId() and ProcessInstance.Status = 'Pending'];

            piw = [Select id,ActorId,Actor.Name,ProcessInstance.TargetObjectId,ProcessInstance.Status from ProcessInstanceWorkitem where ActorId in :actorIds.keySet() and ProcessInstance.Status = 'Pending' limit :workitemLimit];            
        }
        //Changes by Sharath: Clearing the list
        TC2ApproveBYUser.clear();
        for(ProcessInstanceWorkitem piwItem:piw)
        {
            timecardToApprover.put(piwItem.ProcessInstance.TargetObjectId,new List<String>());
            timecardToApprover.get(piwItem.ProcessInstance.TargetObjectId).add(piwItem.actorid);
            timecardToApprover.get(piwItem.ProcessInstance.TargetObjectId).add(piwItem.actor.name);
            TC2ApproveBYUser.add(piwItem.ProcessInstance.TargetObjectId);
        }
        Query = 'SELECT Id,pse__Approver__r.Name,pse__Approver__c,pse__Approver__r.ManagerId,pse__Approver__r.Manager.Name,Delegated_Approver__c,pse__Billable__c,Name,pse__Resource__r.Name,pse__Resource__r.pse__Salesforce_User__c,pse__Resource__c,pse__Status__c, pse__End_Date__c , pse__Friday_Hours__c , pse__Monday_Hours__c , pse__Saturday_Hours__c , pse__Sunday_Hours__c , pse__Thursday_Hours__c , pse__Tuesday_Hours__c , pse__Wednesday_Hours__c , pse__Friday_Notes__c , pse__Monday_Notes__c , pse__Saturday_Notes__c , pse__Sunday_Notes__c , pse__Thursday_Notes__c , pse__Tuesday_Notes__c , pse__Wednesday_Notes__c ,pse__Additional_Notes__c,pse__Project__c,pse__Project_Methodology_Object__r.Name,pse__Project__r.Name,pse__Project__r.pse__Account__c,pse__Project__r.pse__Account__r.Name,pse__Milestone__c,pse__Milestone__r.Name,pse__Total_Hours__c,pse__Start_Date__c,Weekly_User_Timecards_Key__c from pse__Timecard_Header__c where pse__Status__c!=\'Approved\' and pse__Status__c!=\'Saved\' and Id in:TC2ApproveBYUser ';
        
        if(MyFilter1!=NULL)
        {
            QueryWhere+= ' and pse__Project__c =:MyFilter1';
            
        }
        if(MyFilter2!=NULL)
        {
            
            QueryWhere+= ' and pse__Project__r.pse__Account__c = :MyFilter2';
            
        }
        if(MyFilter3!=NULL)
        {
            
            QueryWhere += ' and pse__Resource__c = :MyFilter3';  
            
        }
        if(MyFilter4!=NULL)
        {
            
            QueryWhere += ' and pse__Milestone__c = :MyFilter4';  
            
        }
        /*if(MyFilter5!=NULL)
        {
            
            QueryWhere += ' and pse__Project_Methodology_Object__c = :MyFilter5';  
            
        }*/
        if(MyFilter6!=NULL)
        {
            
            QueryWhere += ' and pse__Start_Date__c = :MyFilter6';  
            
        }
        if(MyFilter7!=NULL)
        {
            
            QueryWhere += ' and pse__End_Date__c = :MyFilter7';  
            
        }
        if(MyFilter9!=NULL)
        {
            if(MyFilter9=='True')
                QueryWhere += ' and pse__Billable__c = TRUE';  
            else if(MyFilter9=='False')
                QueryWhere += ' and pse__Billable__c = FALSE';  
        }
        //Setting the query limit and ordering by Delegated_Approver__c
        String queryLimit = ' order by Delegated_Approver__c  limit :timecardRecordLimit';

        FinalQuery = QueryWhere==NULL||QueryWhere.length()==0?Query:Query + QueryWhere + queryLimit;
        TC = Database.query(FinalQuery);
        //Loop throught the records: remove the timecards not queried from the workitem map
        for(pse__Timecard_Header__c timecardRecord : TC)
        {
            if(!timecardToApprover.containsKey(timecardRecord.Id))
            {
                timecardToApprover.remove(timecardRecord.Id);   
            }
        }
        
        
        lMCaseERjson = JSON.serialize(TC);    
        JSONGenerator gen = JSON.createGenerator(true);
            
        gen.writeStartObject();        
            gen.writeObjectField('approver', timecardToApprover);        
            gen.writeObjectField('delegationStart', actorIds);        
        gen.writeEndObject();

        actualApproverJson = gen.getAsString();

        FinalQuery='';
        QueryWhere='';
        Comments = '';
        Comments1 = '';
    } 
    public Pagereference ApproveMyRecords() {
        Integer TCApproved = 0;
        String ApprovalComments;
        If(Comments=='') ApprovalComments = Comments1;
        else ApprovalComments = Comments;
        List<Id> TCH2ApproveIds = new List<Id>();
        List<pse__Timecard_Header__c> tc2bulkApprove = ((List<pse__Timecard_Header__c>)(JSON.deserialize(lMCaseERjson,List<pse__Timecard_Header__c>.class)));
        for(pse__Timecard_Header__c tch4:tc2bulkApprove)
        {
            TCH2ApproveIds.add(tch4.Id);
        }
        List<ProcessInstanceWorkitem> piwItem = [Select Id,ProcessInstance.TargetObjectId from ProcessInstanceWorkitem where ProcessInstance.TargetObjectId in:TCH2ApproveIds];
        Approval.ProcessWorkitemRequest req2;
        List<Approval.ProcessWorkitemRequest> listReq = new List<Approval.ProcessWorkitemRequest>();
        List<Approval.ProcessResult> result2 = new List<Approval.ProcessResult>();
        for(ProcessInstanceWorkitem piw1:piwItem)
        {
            req2 = new Approval.ProcessWorkitemRequest();
            req2.setComments(ApprovalComments);
            req2.setAction('Approve');
            req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
            req2.setWorkitemId(piw1.Id);
            listReq.add(req2);
            
        }
        lMCaseERjson = NULL;
        populateMyTable();
        result2 =  Approval.process(listReq,False);
        for(Approval.ProcessResult result1:result2)
        {
            if(!result1.isSuccess())
            {
                //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.FATAL, + result1.getEntityId() + result1.getErrors()[0].getMessage()));
            }
            if(result1.isSuccess())
            {
                TCApproved++;
            }
        }
        
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Confirm, + TCApproved + ' Timecards Approved' ));
        
        return NULL;
    }
    public list<SelectOption> projectsOwned1{ 
        get      
        {
            list<String> AccFilterIds = new list<string>(); 
            list<String> ProjFilterIds = new list<string>();
            if(projectsOwned1==null) 
            { 
                projectsOwned1 = new list<SelectOption>(); 
            }
            else
            {
                projectsOwned1.clear();
            }
            projectsOwned1.add(new SelectOption('','--None--'));
            for(pse__Timecard_Header__c tch4:TC2ApproveBYUserFilters)
            {
                ProjFilterIds.add(tch4.pse__Project__c);
                AccFilterIds.add(tch4.pse__Project__r.pse__Account__c);
            }
            for(pse__proj__c p1: [select id,name from pse__proj__c where Id in:ProjFilterIds and pse__Account__c =:MyFilter2])
            {
                
                projectsOwned1.add(new SelectOption(p1.Id,p1.Name));
                
            }
            
            
            return projectsOwned1; 
    
        } 
        set;
    }  
    public List<SelectOption> AccountsOwned { 
        get
        {
        
            list<String> AccFilterIds = new list<string>(); 
            if(AccountsOwned==null) 
            { AccountsOwned = new List<SelectOption>(); }
            else{
            
            AccountsOwned.clear();
            }
            AccountsOwned.add(new SelectOption('','--None--'));
            for(pse__Timecard_Header__c tch4:TC2ApproveBYUserFilters)
            {
                AccFilterIds.add(tch4.pse__Project__r.pse__Account__c);
            }
            for(Account a1: [select id,name from Account where Id in:AccFilterIds])
            {
                
                AccountsOwned.add(new SelectOption(a1.Id,a1.Name));
                
            }
            
            return AccountsOwned; 
        }
        set; 
    }  
    public List<SelectOption> ResourcesFilter{ 
        get
        {
            list<String> ResFilterIds = new list<string>(); 
            if(ResourcesFilter==null) 
            { ResourcesFilter = new List<SelectOption>(); }
            else
            {
                ResourcesFilter.clear();
            }
            ResourcesFilter.add(new SelectOption('','--None--'));
            for(pse__Timecard_Header__c tch4:TC2ApproveBYUserFilters)
            {
                ResFilterIds.add(tch4.pse__Resource__c);
            }
            for(Contact a1: [select id,name from Contact where Id in:ResFilterIds])
            {
                
                ResourcesFilter.add(new SelectOption(a1.Id,a1.Name));
                
            }
            
            return ResourcesFilter; 
        } 
        set; 
    }
    public List<SelectOption> MilestoneFilter{ 
        get
        {
            list<String> MilestoneFilterIds = new list<string>(); 
            if(MilestoneFilter==null) 
            { MilestoneFilter = new List<SelectOption>(); }
            else
            {MilestoneFilter.clear();}
            MilestoneFilter.add(new SelectOption('','--None--'));
            for(pse__Timecard_Header__c tch4:TC2ApproveBYUserFilters)
            {
                MilestoneFilterIds.add(tch4.pse__Milestone__c);
          
            }
            for(pse__Milestone__c a1: [select id,name from pse__Milestone__c where Id in:MilestoneFilterIds and pse__Project__c =:MyFilter1])
            {
                
                MilestoneFilter.add(new SelectOption(a1.Id,a1.Name));
                
            }
            
            return MilestoneFilter; 
        } 
        set; 
    }    
    public List<SelectOption> ProductFilter{ 
        get
        {
        list<String> ProductFilterIds = new list<string>(); 
        if(ProductFilter==null) 
        { ProductFilter = new List<SelectOption>(); }
        else
        {ProductFilter.clear();}
        ProductFilter.add(new SelectOption('','--None--'));
        for(pse__Timecard_Header__c tch4:TC2ApproveBYUserFilters)
        {
            ProductFilterIds.add(tch4.pse__Project_Methodology_Object__c);
        }
        for(pse__Project_Methodology__c a1: [select id,name from pse__Project_Methodology__c where Id in:ProductFilterIds and pse__Project__c =:MyFilter1])
        {
            
            ProductFilter.add(new SelectOption(a1.Id,a1.Name));
            
        }
        
        return ProductFilter; 
    } 
        set; 
    }  
    public List<SelectOption> BillableOptions{
        get{
            if(BillableOptions==null)
            {
                BillableOptions = new List<SelectOption>();
            }
            else{
                BillableOptions.clear();
                
            }
            BillableOptions.add(new SelectOption('','--None--'));
            BillableOptions.add(new SelectOption('True','Yes'));
            BillableOptions.add(new SelectOption('False','No'));
            
            return BillableOptions;
            
            
        }
        set;
    }
    
    //Changes by Sharath for delegation approver of timecards: Setting up the delegation filter
    public List<SelectOption> DelegatedTimecardOptions {
        get
        {
            if(DelegatedTimecardOptions==null)
            {
                DelegatedTimecardOptions = new List<SelectOption>();
            }
            else
            {
                DelegatedTimecardOptions.clear();
                
            }
            DelegatedTimecardOptions.add(new SelectOption('','--None--'));
            DelegatedTimecardOptions.add(new SelectOption('True','Yes'));
            DelegatedTimecardOptions.add(new SelectOption('False','No'));
            
            return DelegatedTimecardOptions;
         
         
        }
        set;
    }
    public string userPreferenceNewRecord{
        get{
            //userPreferenceNewRecord = PSA_Settings__c.getInstance('Preference Object New Record').Value__c;
            //return userPreferenceNewRecord;
            
            userPreferenceNewRecord = [select Value_Long__c from PSA_Common_Setting__mdt where Name__c = 'Preference Object New Record' limit 1].Value_Long__c;
            return userPreferenceNewRecord;
        }
        set;
     }
    public string Userpreference{
         get{
               list<PSA_Approval_Notification_Preference__c> up = [Select Id from PSA_Approval_Notification_Preference__c where User__c = :userinfo.getuserid() limit 1];
               if(up==NULL || (up.size() == 0))
               return userPreferenceNewRecord;
               else return up[0].Id;
             }
         set;
     }
     
    @remoteAction
    public static String ApproveSelectedTC(String action,String SelectedTC,String Comments) {
            //System.assert(false, 'hello2');
            //List<String> SelectedTCIDs = SelectedTC.split(',');
            PSE_Timecard_Approval_Object__c approvalObject = new PSE_Timecard_Approval_Object__c();
            approvalObject.Timecard_IDs__c = SelectedTC;
            approvalObject.Comments__c = Comments;
            approvalObject.Action__c = action;
            insert approvalObject;

            //PageReference pg = new PageReference('/apex/PSA_BulkApproveTimecardPoller?ApprovalObjectID='+approvalObject.id);
            //pg.setRedirect(true);
            return approvalObject.Id;
    }
    public PageReference pageMessageUpdate() {
        ApexPages.getMessages().clear();
        ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Info, 'The selected timecards are being processed. A notification will be sent on completion.' ));
        return NULL;
    }
    
    //Wrapper class of timecard
    class PSA_TimecardWrapper {
        Id tcId;
        String key;
        Decimal totalHours;
        
    }
        
    //Method to fetch message after checking if total aggregated approved hours > Max threshold
    @RemoteAction
    public static String getThresholdDataMessage(String timecardObjects,String SelectedTC){
        Boolean flag = false;
        String message='You are trying to approve hours in excess of the locally permitted standard working hours. \nPlease review the following entries before approving.';
        //List of timecard Ids selected in the multi approval timcard page
        List<String> selectedTimecardIdsList = new List<String>();
        selectedTimecardIdsList.addAll(SelectedTC.split(','));
        System.debug('###SelectedTC: '+SelectedTC);
        
        //Deserialize and fetch the timecard details
        List<PSA_TimecardWrapper> results = (List<PSA_TimecardWrapper>) JSON.deserialize(timecardObjects, List<PSA_TimecardWrapper>.class);
        
        //Map of user week Key to the timecard wrapper PSA_TimecardWrapper
        Map<String,PSA_TimecardWrapper> keyToWrapperMap = new Map<String,PSA_TimecardWrapper>();
        
        PSA_TimecardWrapper tempWrapper = new PSA_TimecardWrapper();
        
        for(PSA_TimecardWrapper eachWrapper : results){
            System.debug('###eachWrapper.tcId: '+String.valueOf(eachWrapper.tcId));
            if(selectedTimecardIdsList.contains(String.valueOf(eachWrapper.tcId))){
                if(keyToWrapperMap.containsKey(eachWrapper.key)){
                    System.debug('###keyToWrapperMap.get(eachWrapper.key).totalHours: '+keyToWrapperMap.get(eachWrapper.key).totalHours);
                    
                    //Aggregated approved hours of the selected timecards.
                    eachWrapper.totalHours = eachWrapper.totalHours + keyToWrapperMap.get(eachWrapper.key).totalHours;
                }
                System.debug('###eachWrapper.totalHours: '+eachWrapper.totalHours);
                keyToWrapperMap.put(eachWrapper.key,eachWrapper);
            } 
            System.debug('###');
        }

        
        //Query the existing juntion object to fetch approved hours from the user weeks
        for(PSA_Weekly_User_Timecard_Hours__c weeklyUserTimecardHour : [
            SELECT Id, Resource__c, Resource_Name__c , Weekly_Start_Date__c , Weekly_End_Date__c , Maximum_Hours_Threshold__c, Legal_Hours_Threshold__c, Total_Approved_Hours__c ,Total_Hours__c , Weekly_User_Timecards_Key__c
            FROM PSA_Weekly_User_Timecard_Hours__c
            WHERE Weekly_User_Timecards_Key__c in :keyToWrapperMap.keySet()
        ]){
            System.debug('### weeklyUserTimecardHour.Total_Approved_Hours__c + keyToWrapperMap.get(weeklyUserTimecardHour.Weekly_User_Timecards_Key__c).totalHours: '+(weeklyUserTimecardHour.Total_Approved_Hours__c + keyToWrapperMap.get(weeklyUserTimecardHour.Weekly_User_Timecards_Key__c).totalHours));
            System.debug('### weeklyUserTimecardHour.Maximum_Hours_Threshold__c: '+weeklyUserTimecardHour.Maximum_Hours_Threshold__c);
            //Calculate timcard hours + aggregate hours and check it with Maximum_Hours_Threshold__c
            if(weeklyUserTimecardHour.Total_Approved_Hours__c + keyToWrapperMap.get(weeklyUserTimecardHour.Weekly_User_Timecards_Key__c).totalHours >= weeklyUserTimecardHour.Maximum_Hours_Threshold__c){
                //Generate message if Maximum threshold is reached

                sObject obj = weeklyUserTimecardHour;
                String label = System.Label.PSA_Maximum_Threshold_Approval_Popup_Message ;
                //System.assert(false,'@@@label: '+label);
                message = message + '\n\n' + PSA_AutoCreateProjectUtil.getCustomizedLabelMessage('PSA_Weekly_User_Timecard_Hours__c',label,obj,null);
                
                message = message + keyToWrapperMap.get(weeklyUserTimecardHour.Weekly_User_Timecards_Key__c).totalHours;
                
                System.debug('@@@Message: '+PSA_AutoCreateProjectUtil.getCustomizedLabelMessage('PSA_Weekly_User_Timecard_Hours__c',label,obj,null));
                flag = true;
                /*
                message = message + '\n\nResource: '+weeklyUserTimecardHour.Resource__r.Name;
                message = message + '\nWeek Start Date: '+((Datetime)(weeklyUserTimecardHour.Weekly_Start_Date__c)).format('yyyy-MM-dd');
                message = message + '\nApproved Hours: '+weeklyUserTimecardHour.Total_Approved_Hours__c;
                message = message + '\nSelected Hours: '+keyToWrapperMap.get(weeklyUserTimecardHour.Weekly_User_Timecards_Key__c).totalHours;
                message = message + '\nMaximum Threshold: '+weeklyUserTimecardHour.Maximum_Hours_Threshold__c;
                */
            }
        }   
        if(flag == true){
            message = message.replaceAll(' [0-9][0-9]:[0-9][0-9]:[0-9][0-9]','');
            return message;
        }
        return '';
        

    }
    
}