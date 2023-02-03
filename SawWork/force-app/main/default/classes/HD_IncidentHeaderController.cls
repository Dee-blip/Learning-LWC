public without sharing class HD_IncidentHeaderController {

    
    //@AuraEnabled
    public class Data{
        @AuraEnabled
        public  String incidentNumber;
        @AuraEnabled
        public  String category;
        @AuraEnabled
        public  String categoryTree;
        @AuraEnabled
        public  String priority;
        @AuraEnabled
        public  String SRPriority;
        @AuraEnabled
        public  String status;
        @AuraEnabled
        public  String owner;
        @AuraEnabled
        public  Boolean isVipUser;
        @AuraEnabled
        public  String incType;
        @AuraEnabled
        public  String totalEffort;
        @AuraEnabled
        public Boolean hasCR;
        @AuraEnabled
        public Boolean hasTask;
        @AuraEnabled
        public Integer TaskCount;
        @AuraEnabled
        public Integer openTaskCount;
        @AuraEnabled
        public Integer crCount;
        @AuraEnabled
        public Boolean hasProb;
        @AuraEnabled
        public Integer probCount;
        @AuraEnabled
        public Boolean isChild;
        @AuraEnabled
        public Boolean isParent;
        @AuraEnabled
        public Integer parentCount;
	    @AuraEnabled
        public List<String> ccInfo;
        @AuraEnabled
        public  Boolean isAPITicket;
        @AuraEnabled
        public Boolean hasAttachments;
        @AuraEnabled
        public Boolean isSubmittedForApproval;
        @AuraEnabled
        public Integer attachCount;
        @AuraEnabled
        public Id parentId;
        @AuraEnabled
        Public String parentName;
        @AuraEnabled
        Public Map<Id,String> childIncidents;
        @AuraEnabled
        Public String ownerId;
        


        Data(){
            //this.keysOrder = {'incidentNumber','category','categoryTree','priority','status','isVipUser'};
            this.crCount = 0;
            this.parentCount = 0;
            this.probCount = 0;
            this.attachCount = 0;
            this.openTaskCount = 0;
            this.incidentNumber = '';
            this.category='';
            this.categoryTree='';
            this.priority='';
            this.status='';
            this.owner='';
            this.ownerId='';
            this.isVipUser = false;
            this.incType = 'Incident';
            this.totalEffort = '';
            this.isChild = false;
            this.hasCR = false;

            this.hasProb = false;
            this.isParent = false;
            this.isAPITicket = false;
            this.ccInfo=new List<String>();
            this.hasAttachments = false;
            
            this.parentName = '';
            this.parentId = null;
			this.childIncidents = new Map<Id,String>();

        }
    }

    @AuraEnabled(cacheable=true)
    public static Data getIncidentDetailsFormatedData(Id recordId){
        System.debug('getIncidentDetails');
        String incPrefix = 'INC';
        String srPrefix = 'SR';
        BMCServiceDesk__Incident__c inc = [Select Id,BMCServiceDesk__clientId__c,Name,BMCServiceDesk__Type__c,HD_Ticket_Priority__c,SR_Priority__c,
                                           BMCServiceDesk__FKIncident__r.name,BMCServiceDesk__FKIncident__r.Id, CCText__c,
                                           VIP_Ticket__c,BMCServiceDesk__Category_ID__c,BMCServiceDesk__Status_ID__c, BMCServiceDesk__contactType__c,
                                           HD_Parent_Tree__c,HD_Owner_user_queue__c, HD_Total_Effort_Spent_minutes__c,
                                           HD_Parent_Category__c, Owner.Id
                                           from BMCServiceDesk__Incident__c where Id = :recordId][0];
        Data incInfo = new Data();
        incInfo.incidentNumber = inc.Name;
        incInfo.category = inc.BMCServiceDesk__Category_ID__c;
        incInfo.categoryTree = inc.HD_Parent_Tree__c;
        incInfo.status = inc.BMCServiceDesk__Status_ID__c;
        incInfo.owner = inc.HD_Owner_user_queue__c;
        incInfo.ownerId = inc.Owner.Id;
        incInfo.isVipUser = inc.VIP_Ticket__c;
        incInfo.incType = inc.BMCServiceDesk__Type__c;
        incInfo.priority = (inc.BMCServiceDesk__Type__c=='Incident')?'P'+inc.HD_Ticket_Priority__c:inc.SR_Priority__c;

        //the code used to check the weather the record is locked or not while approval
        List<ProcessInstance> ProcessInstanceList = [ SELECT Id, TargetObjectId FROM ProcessInstance WHERE TargetObjectId =: recordId and STATUS = 'Pending' LIMIT 1];
        incInfo.isSubmittedForApproval =  ProcessInstanceList?.size() > 0;

        if(inc.BMCServiceDesk__FKIncident__r.name != null){
            //implies fkincident is parent of tickett// hasChild
            incInfo.isChild = true;
            incInfo.parentId = inc.BMCServiceDesk__FKIncident__r.Id;
            incInfo.parentName = inc.BMCServiceDesk__FKIncident__r.name;
        }

        //check for tasks on Incident
        List<BMCServiceDesk__Task__c> incidentTasks = new List<BMCServiceDesk__Task__c>();
        incidentTasks  = [select id, BMCServiceDesk__state__c from BMCServiceDesk__Task__c where BMCServiceDesk__FKIncident__c  = :recordId];
        if(incidentTasks.size()>0){
        	incInfo.hasTask  = true;
            incInfo.TaskCount = incidentTasks.size();
            for(BMCServiceDesk__Task__c task : incidentTasks) {
                if(task.BMCServiceDesk__state__c) {
	                incInfo.openTaskCount++;
                }
            }
        }

        //check for ticket being parent
        List<BMCServiceDesk__Incident__c> incParentCheck = new List<BMCServiceDesk__Incident__c>();
        incParentCheck=[Select Id, Name from BMCServiceDesk__Incident__c where BMCServiceDesk__FKIncident__c = :recordId];
        if(incParentCheck.size() > 0){
            incInfo.isParent = true;
            incInfo.parentCount = incParentCheck.size();
            for(BMCServiceDesk__Incident__c child : incParentCheck) {
                incInfo.childIncidents.put(child.Id, child.Name);
            }
        }

        //check for changeRequest
        List<BMCServiceDesk__Change_Request__c> clist = [select id,Parent_Incident__c from  BMCServiceDesk__Change_Request__c where Parent_Incident__c = :recordId];
        if(clist.size() > 0){
            //incInfo.CRInfo.put(true, clist.size());
            incInfo.crCount = clist.size();
            incInfo.hasCR = true;
        }

        //check for attachment
        List<Attachment> attachList = [select id,parentId from Attachment where parentId = :recordId];
        List<ContentDocumentLink> files = [SELECT ContentDocumentId, LinkedEntityId  FROM ContentDocumentLink where LinkedEntityId = :recordId and LinkedEntity.Type='BMCServiceDesk__Incident__c'];
        Integer attachCount = 0;
        if(attachList.size() > 0){
            attachCount+=attachList.size();
            incInfo.hasAttachments = true;
        }
        if(files.size() > 0){
            attachCount+=files.size();
            incInfo.hasAttachments = true;
        }
        incInfo.attachCount = attachCount;
        //check for API ticket
        //
        try{
            Set<String> apiCatSet;
            Set<String> apiParentCatSet;
            HD_Category_Settings_Two_Step_Closure__c cs = HD_Category_Settings_Two_Step_Closure__c.getOrgDefaults();

            if(cs.Categories__c !=null){
                apiCatSet = new Set<String>(cs.Categories__c.split('\n'));
            }
            if(cs.Parent_Categories__c != null){
                apiParentCatSet = new Set<String>(cs.Parent_Categories__c.split('\n'));
            }

            if(apiCatSet?.contains(inc.BMCServiceDesk__Category_ID__c ) ||
              apiParentCatSet?.contains(inc.HD_Parent_Category__c) ||
              inc?.BMCServiceDesk__contactType__c == 'API' ){
                incInfo.isAPITicket = true;
            }
            
        }catch(Exception e){
            System.debug('custom setting issue');
        }

		//contains
        // check for problem
        // select id from BMCServiceDesk__Incident_Problem_Link__c where BMCServiceDesk__FKIncident__c
        List<BMCServiceDesk__Incident_Problem_Link__c> plist = new List<BMCServiceDesk__Incident_Problem_Link__c>();
        plist = [select id from BMCServiceDesk__Incident_Problem_Link__c where BMCServiceDesk__FKIncident__c =:recordId];
        if(plist.size()> 0){
            //incInfo.ProbInfo.put(true, plist.size());
            incInfo.probCount = plist.size();
            incInfo.hasProb = true;
        }

        //getting cc users
        //incInfo.ccInfo
        if(inc.CCText__c != null){

            incInfo.ccInfo = inc.CCText__c.replace(',',';').split(';');
        }

        if(inc.HD_Total_Effort_Spent_minutes__c<60){
            incInfo.totalEffort = inc.HD_Total_Effort_Spent_minutes__c+' minutes';
        }
        else if(inc.HD_Total_Effort_Spent_minutes__c == 60){
            incInfo.totalEffort = '1 hour';
        }
        else{
            Integer effort = (Integer)inc.HD_Total_Effort_Spent_minutes__c;
            Integer hours = effort/60;
            Integer minutes = Math.mod(effort, 60);
            if(minutes == 0){
                incInfo.totalEffort = hours+' hours';
            }
            else{
                if(hours == 1){
                    incInfo.totalEffort = hours+' hour '+minutes+' minutes';
                }
                else{
                    incInfo.totalEffort = hours+' hours '+minutes+' minutes';
                }
            }
                //incInfo.totalEffort = inc.HD_Total_Effort_Spent_minutes__c/60 +' hours '+Math.mod((Integer)inc.HD_Total_Effort_Spent_minutes__c, 60)+' minutes';
        }
        return incInfo;
    }

    @AuraEnabled
    public static BMCServiceDesk__Incident__c getIncident(Id incidentId){
        BMCServiceDesk__Incident__c incident = [select Id,Name,BMCServiceDesk__FKStatus__c,BMCServiceDesk__FKStatus__r.BMCServiceDesk__Stage__c,BMCServiceDesk__Status_ID__c from BMCServiceDesk__Incident__c where Id=:incidentId LIMIT 1];
        return incident;
    }
    
    @AuraEnabled(cacheable=true)
    public static String getAllStatuses(Id incidentId){
        return JSON.serialize([SELECT Field,NewValue,OldValue FROM BMCServiceDesk__Incident__History WHERE ParentId = :incidentId AND Field = 'BMCServiceDesk__FKStatus__c' ORDER BY CreatedDate]);
    }

    @AuraEnabled
    public static BMCServiceDesk__Incident__c changeStatusToInProgress(String recordId)
    {
        try
        {

		BMCServiceDesk__Incident__c inc = new BMCServiceDesk__Incident__c();
        inc.id = recordId;
        inc.BMCServiceDesk__FKStatus__c = [select Id from BMCServiceDesk__Status__c where Name='IN PROGRESS' limit 1].Id;
        update inc;
        System.debug(inc);
        return inc;
        }
        catch(Exception e)
        {
            throw new AuraHandledException(e.getMessage());
        }
    }

    /*@AuraEnabled
    public static List<String> getIncidentStatusList(Id incidentId){
        BMCServiceDesk__Incident__c incident = [Select Id, Name, HD_Status_List__c  from BMCServiceDesk__Incident__c where Id = :incidentId LIMIT 1];
        List<String> statusList = new List<String>();
        for(String status : incident.HD_Status_List__c.split(','))
        {
            statusList.add(status);
        }
        return statusList;
    }*/

    /*@AuraEnabled
    public static List<BMCServiceDesk__Incident__c> getTicketList(String type){
        List<String> ticketList = new List<String>();
        List<BMCServiceDesk__Incident__c> incList = new List<BMCServiceDesk__Incident__c>();
        if(type == 'All'){
            incList = [Select Id, Name from BMCServiceDesk__Incident__c LIMIT 20];
        }
        else{
            incList = [Select Id, Name from BMCServiceDesk__Incident__c where BMCServiceDesk__Type__c =:type LIMIT 20];
        }
        for(BMCServiceDesk__Incident__c inc: incList){
            ticketList.add(inc.Name);
        }
        return incList;
    }*/
}