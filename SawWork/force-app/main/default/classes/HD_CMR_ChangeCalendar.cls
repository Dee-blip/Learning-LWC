/* 
* File Name: HD_CMR_ChangeCalendar
* Description : 
* @author : 
* Modification Log ===============================================================
* Date              Author          Modification
* Aug 08th, 2020    Aneesh Budnar   PRTORES-1810 - Code scanner fixes
* Oct 29th, 2021    Aneesh Budnar   PRTORES-2335 - HD redesign the CMR approval progress indicator using LWC
* Jan 20th, 2022    Aneesh Budnar   PRTORES-2413 - HD CMR switch between the old & new UI based on pilot users
*/
global class HD_CMR_ChangeCalendar {

    public static LIST<BMCServiceDesk__Change_Request__c> rc = new LIST<BMCServiceDesk__Change_Request__c>();
    public static LIST<BMCServiceDesk__Change_Request__c> rc_1 = new LIST<BMCServiceDesk__Change_Request__c>();
    public static BMCServiceDesk__Change_Request__c change = new BMCServiceDesk__Change_Request__c();
    //public static List<List<String>> AppSteps {get;set;}
    //public static List<List<String>> SpAppSteps {get;set;}

    public static final String ROLE_OWNER = 'Owner';
    public static final String ROLE_COORDINATOR = 'Coordinator';
    public static final String ROLE_SPONSOR = 'Sponsor';
    public static final String ROLE_APPROVER = 'Approver';
    public static final String ROLE_INITIATOR = 'Initiator';
    public static final String ROLE_CAB_MANAGER = 'CAB Manager';
    public static final String ROLE_SYSTEM_ADMIN = 'System Administrator';
    public static final String changeManagementQuery='';
    public static Map<String,ActionConfigDetails> cmrActionMap;

    /*
     *@author: Nikhil Karn
     *
     *
     */
    global class ApprovalStatus{
        @AuraEnabled
        public String displayName { get; set; }
        @AuraEnabled
        public String processWorkItemId { get; set; }
        @AuraEnabled
        public String status{ get; set; }
        @AuraEnabled
        public Boolean enableApproveForCurrentUser{ get; set; }
        @AuraEnabled
        public Boolean startFlag{ get; set; }
        @AuraEnabled
        public List<String> utilityList{ get; set; }
        @AuraEnabled
        public Datetime sysModDate { get; set; }
        @AuraEnabled
        public String approverName { get; set; }

        ApprovalStatus (String displayName,String status,Boolean enableApproveForCurrentUser,Boolean startFlag,List<String> utilityList, String approverName){
            this.displayName=displayName;
            this.status=status;
            this.enableApproveForCurrentUser=enableApproveForCurrentUser;
            this.startFlag=startFlag;
            this.utilityList=utilityList;
            this.approverName = approverName;
        }
    }


    public class ActionConfigDetails{
        @AuraEnabled
        public Map<String,String> cmrActionMap{ get; set; }
    }

    @AuraEnabled
    public static void createCmrActionsData(){
        //Setting up Actions Data
        cmrActionMap=new Map<String,ActionConfigDetails>();
        HD_Instance__mdt actionsMdt = [SELECT  ChangePicklistColorSettings__c from HD_Instance__mdt where Label = 'HD CMR Actions' limit 1];

        String actions = actionsMdt.ChangePicklistColorSettings__c;

        System.debug('actions:'+actions);
        List<String> temp1=actions.split('#');

        for(String actionConfigTemp:temp1){
            System.debug('actionConfigTemp:'+actionConfigTemp);
            List<String> temp2=actionConfigTemp.split(':');//seprating action name and its config
            ActionConfigDetails actionConfig=new ActionConfigDetails();
            String statusName=temp2[0];
            String tempConfig=temp2[1];
            List<String> actionsList=tempConfig.split('&');//seprating each user config
            Map<String,String> tempMap=new Map<String,String>();

            for(String tempVar1:actionsList){
                List<String> tempList1=tempVar1.split('~');
                String value='';
                if(tempList1[1]=='-'){
                    value=null;

                }else{
                    value=tempList1[1];
                }
                tempMap.put(tempList1[0], value);
            }

            actionConfig.cmrActionMap=tempMap;
            cmrActionMap.put(statusName,actionConfig);
            System.debug('cmrActionMap:'+cmrActionMap);
        }
    }

    public class CMRData{

        @AuraEnabled
        public List<BMCServiceDesk__Change_Request__c> changeRecords = new LIST<BMCServiceDesk__Change_Request__c>();
        @AuraEnabled
        public Map<String, Object> colorSettings = new Map<String, Object>();
        @AuraEnabled
        public Integer changeCategoryRange;
        @AuraEnabled
        public List<BMCServiceDesk__Projected_Service_Outage__c> serviceOutages = new List<BMCServiceDesk__Projected_Service_Outage__c>(); 
    }   


    @AuraEnabled(cacheable=true)
    public static List<String> getUserType(){
        List<String> usertypes = new List<String>() ;
        String currentUserId=UserInfo.getUserId();
        HD_CMR_SETTINGS__c SETTING_CABQueueId = HD_CMR_SETTINGS__c.getInstance('CAB_Queue_Id');
        List<GroupMember> groups =  [select Id from GroupMember where Group.Type = 'Queue' and GroupId = :SETTING_CABQueueId.Value__c and UserOrGroupId = :UserInfo.getUserId() Limit 5];
        if(groups.size() > 0){
            usertypes.add('CAB');
        }
        return usertypes;
    }

    @AuraEnabled
    public static Boolean hasFeatureAccess(String customPermission){
        HD_Instance__mdt hdCMRNewUI = HD_Instance__mdt.getInstance('HD_New_UI_List');
        Boolean hasAccess = FeatureManagement.checkPermission(customPermission);
        if(!hasAccess && hdCMRNewUI != null) {
            return hdCMRNewUI.SettingValue__c.split(';').contains('CMR');
        }
        else {
            return hasAccess;
        }
    }

    @AuraEnabled
    public static List<BMCServiceDesk__Change_Request__c> getListViewRecords (String filterId){

        //
        Integer count = 0;
        
        Integer pageNum =1;
        String q = 'SELECT id FROM BMCServiceDesk__Change_Request__c LIMIT 1';
        List<BMCServiceDesk__Change_Request__c> qr = [SELECT id FROM BMCServiceDesk__Change_Request__c LIMIT 1];
        ApexPages.StandardSetController srmObject = new ApexPages.StandardSetController(Database.getQueryLocator(q));
        srmObject.setPageSize(2000);
        srmObject.setPageNumber(pageNum);
        srmObject.setFilterID(filterId);
        List<Id> incIds = new List<Id>();
        
        for(SObject inc: srmObject.getRecords())
        {
            System.debug('test');
            incIds.add(inc.Id);
            count++;
        }
        
        while(srmObject.getHasNext())
        {
            srmObject.next();
            for(SObject inc: srmObject.getRecords()){
                
                
                incIds.add(inc.Id);
                count++;
            }
            
        }
        
        ///
        ListView listview   = [SELECT Id, Name  FROM ListView WHERE SobjectType = 'BMCServiceDesk__Change_Request__c' and ID = :filterId Limit 1][0]; 
        String soql_str = 'SELECT ID,OwnerId,Name,Change_Summary__c,HD_Sponsor__r.Name,HD_Sponsor__r.Alias,HD_Owner_Name__c,';
        soql_str += 'BMCServiceDesk__Actual_Start_Date__c,BMCServiceDesk__Actual_End_Date__c,BMCServiceDesk__Change_Category__c,HD_Service_Impacted__c,';
        soql_str += 'HD_Sub_services_Impacted__c, HD_Change_Status__c,';
        soql_str += 'BMCServiceDesk__Scheduled_Start_Date__c,BMCServiceDesk__Scheduled_End_Date__c,change_plan__c,';
        soql_str += 'BMCServiceDesk__FKInitiator__r.Name,BMCServiceDesk__FKInitiator__r.Alias,Change_Coordinator_Primary__r.Name,';
        soql_str += 'HD_Facility_Location__c,Service_Element_Impact_duration__c , HD_Sponsor_Name__c from BMCServiceDesk__Change_Request__c WHERE ID IN :incIds  Limit 10000';
       
       LIST<BMCServiceDesk__Change_Request__c> lstRecords = [ SELECT ID,OwnerId,Name,Change_Summary__c,HD_Sponsor__r.Name,HD_Sponsor__r.Alias,HD_Owner_Name__c,
        BMCServiceDesk__Actual_Start_Date__c,BMCServiceDesk__Actual_End_Date__c,BMCServiceDesk__Change_Category__c,HD_Service_Impacted__c,
        HD_Sub_services_Impacted__c, HD_Change_Status__c,
        BMCServiceDesk__Scheduled_Start_Date__c,BMCServiceDesk__Scheduled_End_Date__c,change_plan__c,
        BMCServiceDesk__FKInitiator__r.Name,BMCServiceDesk__FKInitiator__r.Alias,Change_Coordinator_Primary__r.Name,
        HD_Facility_Location__c,Service_Element_Impact_duration__c , HD_Sponsor_Name__c from BMCServiceDesk__Change_Request__c WHERE ID IN :incIds  Limit 9000];
       
        
        /*ApexPages.StandardSetController  stdctr = new ApexPages.StandardSetController(Database.getQueryLocator(soql_str));
        stdctr.setPageSize(2000);
        stdctr.setFilterId(listview.id);
        stdctr.setPageNumber(1);*/
        //LIST<BMCServiceDesk__Change_Request__c> lstRecords = stdctr.getRecords();
        return lstRecords;
    }


    @AuraEnabled(cacheable=true)
    public static CMRData getCalCMR(String sDate , String eDate){

        DateTime startDate = Date.valueOf(sDate);
        DateTime endDate =   Date.valueOf(edate);
        CMRData cmr = new CMRData();
        cmr.changeRecords  = [SELECT ID,OwnerId,Name,Change_Summary__c,HD_Sponsor__r.Name,HD_Sponsor__r.Alias,HD_Owner_Name__c,BMCServiceDesk__Status__c,
                              BMCServiceDesk__Actual_Start_Date__c,BMCServiceDesk__Actual_End_Date__c,BMCServiceDesk__Change_Category__c,HD_Service_Impacted__c,
                              HD_Sub_services_Impacted__c, HD_Change_Status__c,Change_Priority__c,
                              BMCServiceDesk__Scheduled_Start_Date__c,BMCServiceDesk__Scheduled_End_Date__c,change_plan__c,
                              BMCServiceDesk__FKInitiator__r.Name,BMCServiceDesk__FKInitiator__r.Alias,Change_Coordinator_Primary__r.Name,
                              HD_Facility_Location__c,Service_Element_Impact_duration__c , HD_Sponsor_Name__c from BMCServiceDesk__Change_Request__c   WHERE  
                              (BMCServiceDesk__Scheduled_Start_Date__c <  :endDate AND BMCServiceDesk__Scheduled_End_Date__c > :startDate ) OR
                              (BMCServiceDesk__Scheduled_Start_Date__c > :startDate AND BMCServiceDesk__Scheduled_End_Date__c > :endDate)
                              ORDER BY Name DESC ];

        cmr.serviceOutages = [SELECT Name,Id,BMCServiceDesk__End_Date__c,BMCServiceDesk__Start_Date__c,Service_Outage_Type__c,  Services_Affected__c, 
                              Sub_Services_Affected__c, Outage_Condition__c,BMCServiceDesk__Blackout__c FROM BMCServiceDesk__Projected_Service_Outage__c WHERE
                              BMCServiceDesk__Inactive__c != true];

        HD_Instance__mdt color = [SELECT  ChangePicklistColorSettings__c,ChangeCategory__c from HD_Instance__mdt where Label = 'settings' limit 1];

        String jsonInput = color.ChangePicklistColorSettings__c;
        cmr.colorSettings =
                (Map<String, Object>)
                JSON.deserializeUntyped(jsonInput);

        cmr.changeCategoryRange = Integer.valueOf(color.ChangeCategory__c);

        return cmr;

    }



    @AuraEnabled(cacheable=true)
    public static  BMCServiceDesk__Change_Request__c getChange(String Id){
        BMCServiceDesk__Change_Request__c cr  = [SELECT ID,OwnerId,Name,Change_Summary__c,Change_Priority__c,
                                                 HD_Owner_Name__c,BMCServiceDesk__Actual_Start_Date__c,BMCServiceDesk__Actual_End_Date__c,
                                                 BMCServiceDesk__Change_Category__c,HD_Service_Impacted__c,HD_Sub_services_Impacted__c,
                                                 CR_Approval_Status__c, HD_Change_Status__c,BMCServiceDesk__Scheduled_Start_Date__c,
                                                 BMCServiceDesk__Scheduled_End_Date__c,change_plan__c,BMCServiceDesk__FKInitiator__r.Name,
                                                 BMCServiceDesk__FKInitiator__r.Email,Change_Coordinator_Primary__r.Name,HD_Facility_Location__c,
                                                 Service_Element_Impact_duration__c , HD_Sponsor_Name__c
                                                 from BMCServiceDesk__Change_Request__c WHERE id =:Id];
        return cr;
    }



    /*
     *@author: Nikhil Karn
     *
     *
     */
    @AuraEnabled(cacheable=true)
    public static  Map<String,approvalStatus> getApprovalHistory(ID  currentCMRId){

        String cmrId=currentCMRId;
        BMCServiceDesk__Change_Request__c changeRequest;
        String sponsorApprovalProcessInsId;

        //run the query and get the data from objcet
        try{
            List<String> currentUsersGroup = new List<String>();

            ApprovalStatus approvalStatus;//String displayName,String status,Boolean enableApproveForCurrentUser,Boolean startFlag

            Boolean startFlag=false;
            Integer counter=0;
            Map<String,approvalStatus> result=new Map<String,approvalStatus>();

            String query='SELECT ID,OwnerId,Name,Change_Summary__c,HD_Sponsor__c,Second_Level_Approver__c,Change_Priority__c,Change_Coordinator__c,HD_Owner_Name__c,HD_Sponsor__r.Name,HD_Sponsor__r.Alias,BMCServiceDesk__Actual_Start_Date__c,BMCServiceDesk__Actual_End_Date__c,BMCServiceDesk__Change_Category__c,HD_Service_Impacted__c,HD_Sub_services_Impacted__c,CR_Approval_Status__c, HD_Change_Status__c,BMCServiceDesk__Scheduled_Start_Date__c,BMCServiceDesk__Scheduled_End_Date__c,change_plan__c,BMCServiceDesk__FKInitiator__r.Name,BMCServiceDesk__FKInitiator__r.Alias,BMCServiceDesk__FKInitiator__r.Email,Change_Coordinator_Primary__r.Name,HD_Facility_Location__c,Service_Element_Impact_duration__c , HD_Sponsor_Name__c, (Select TargetObjectId, SystemModstamp, StepStatus, RemindersSent, ProcessInstanceId, OriginalActor.Name,OriginalActor.Id, OriginalActor.Type, IsPending,IsDeleted, Id, CreatedDate, CreatedById, Comments, Actor.Name From ProcessSteps order by ProcessInstanceId DESC,SystemModstamp  ) from BMCServiceDesk__Change_Request__c WHERE id =:cmrId Limit 1';        
            changeRequest  = Database.query(query);

            String currentCmrStatus = changeRequest.HD_Change_Status__c.toUpperCase();
            String approvalStatusFieldValue=changeRequest.CR_Approval_Status__c;





            String currentUserId=UserInfo.getUserId();
            Id profileId=UserInfo.getProfileId();
            Profile profileOfCurrentUser = [Select Name from Profile where Id =: profileId LIMIT 1][0];
            String profileName=profileOfCurrentUser.Name;

            List<GroupMember> groupMemberList=Database.query('SELECT Id, group.id, group.name, group.type FROM GroupMember where UserOrGroupId = :currentUserId');
            System.debug(groupMemberList);
            for(GroupMember groupMember:groupMemberList){
                currentUsersGroup.add(groupMember.group.Id);
            }

            Map<String,String> usersAndQueueMap = new Map<String,String>();

           if(!(currentCmrStatus.equalsIgnoreCase('Pending Approval')&& (approvalStatusFieldValue!=null && approvalStatusFieldValue.equalsIgnoreCase('Recalled')))){

                approvalStatus=new ApprovalStatus('Submitted','Submitted',false,startFlag,null,'');
                result.put('submitted', approvalStatus);


                String latestProcessInstanceId;
                try{
                    latestProcessInstanceId =changeRequest.ProcessSteps[0].ProcessInstanceId;
                }catch(Exception e){
                    result.clear();
                }

                for(ProcessInstanceHistory processInstance:changeRequest.ProcessSteps){
                    System.debug('processInstance.StepStatus:'+processInstance.StepStatus);
                    if(processInstance==null){
                        result.clear();
                    }

                    if(latestProcessInstanceId!=null && processInstance.ProcessInstanceId!=latestProcessInstanceId){
                        continue;
                    }

                    if(processInstance.StepStatus.toUpperCase()=='PENDING'&&startFlag==false&&counter==0){
                        startFlag=true;
                        counter=1;
                    }else if(processInstance.StepStatus.toUpperCase()=='PENDING'||processInstance.StepStatus.toUpperCase()=='APPROVED'||processInstance.StepStatus.toUpperCase()=='REJECTED'&&startFlag==true){
                        startFlag=false;
                    }

                    String id = processInstance.OriginalActor.Id;
                    Boolean tempFlag=false;

                    String  name = processInstance.OriginalActor.Name;
                    try{
                        name=name.replace('Approvers','');
                        name=name.replace('Approver','');
                    }catch(Exception e){
                        System.debug('Exception Occurrered in method getApprovalHistory. Exception:'+e.getMessage()+'. Line Number:'+e.getLineNumber());
                    }

                    List<String> status=new List<String>();
                    status.add('Approved');
                    status.add('Pending');
                    status.add('Rejected');



                    for(String tempStatus:status){
                        //if sponsor and second level approval are same then escape second time;
                        if(result.containsKey(sponsorApprovalProcessInsId)){
                            break;
                        }
                        if(changeRequest.HD_Sponsor__c==id&&processInstance.StepStatus.toUpperCase()==tempStatus.toUpperCase()){
                            Boolean acivateapprovalButton=false;
                            if(currentUserId==changeRequest.HD_Sponsor__c || profileName.equalsIgnoreCase(ROLE_SYSTEM_ADMIN)){
                                acivateapprovalButton=true;
                            }
                            approvalStatus=new ApprovalStatus('Sponsor Approval',processInstance.StepStatus,acivateapprovalButton,startFlag,null,processInstance.Actor.Name);
                            approvalStatus.sysModDate=processInstance.SystemModstamp ;
                            approvalStatus.processWorkItemId=processInstance.Id;
                            result.put(processInstance.Id, approvalStatus);
                            sponsorApprovalProcessInsId=processInstance.Id;
                            tempFlag=true;
                            break;
                        }
                    }

                    if(tempFlag)
                        continue;

                    for(String tempStatus:status){
                        if(changeRequest.Second_Level_Approver__c==id&&processInstance.StepStatus.toUpperCase()==tempStatus.toUpperCase()){
                            Boolean acivateapprovalButton=false;

                            if(currentUserId==changeRequest.Second_Level_Approver__c || profileName.equalsIgnoreCase(ROLE_SYSTEM_ADMIN)){
                                acivateapprovalButton=true;
                            }
                            approvalStatus=new ApprovalStatus('Second Level Approval',processInstance.StepStatus,acivateapprovalButton,startFlag,null,processInstance.Actor.Name);
                            approvalStatus.sysModDate=processInstance.SystemModstamp ;
                            approvalStatus.processWorkItemId=processInstance.Id;
                            result.put(processInstance.Id, approvalStatus);
                            tempFlag=true;
                            break;
                        }
                    }

                    if(tempFlag)
                        continue;

                    for(String tempStatus:status){
                        if(processInstance.StepStatus.toUpperCase()==tempStatus.toUpperCase()){
                            Boolean acivateapprovalButton=false;
                            System.debug('currentUserId:'+currentUserId+'       ----currentUsersGroup'+currentUsersGroup);
                            if(currentUsersGroup.contains(processInstance.OriginalActor.Id) || profileName.equalsIgnoreCase(ROLE_SYSTEM_ADMIN)){
                                acivateapprovalButton=true;
                            }
                            approvalStatus=new ApprovalStatus(name,processInstance.StepStatus,acivateapprovalButton,startFlag,null,processInstance.Actor.Name);
                            approvalStatus.sysModDate=processInstance.SystemModstamp ;
                            approvalStatus.processWorkItemId=processInstance.Id;
                            result.put(processInstance.Id, approvalStatus);
                            tempFlag=true;
                            break;
                        }
                    }
                }

            }

            /////////////////////////////////////////////////Integrated CODE with komal's method///////////////////////////////////////////
            try{
                List<String> listOFActionsWhichCurrentUserCanPerform=getListOfActionsWhichUserCanPerform(changeRequest,currentUserId,groupMemberList);
                approvalStatus=new ApprovalStatus(null,'listOFActionsWhichCurrentUserCanPerform',null,null,listOFActionsWhichCurrentUserCanPerform,'');
                result.put('listOFActionsWhichCurrentUserCanPerform', approvalStatus);
            }catch(Exception e){
                System.debug('Exception Occurrered in method getListOfActionsWhichUserCanPerform. Exception:'+e.getMessage()+'. Line Number:'+e.getLineNumber());
            }
            //////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
            System.debug('result:'+result);
            return result;
        }catch(Exception e){
            System.debug('Exception Occurrered in method getApprovalHistory. Exception:'+e.getMessage()+'. Line Number:'+e.getLineNumber());
            return new Map<String,approvalStatus>();
        }
    }

    /*@author: Komal Narsinghani
     *
     *
     */

    @AuraEnabled
    public static  List<String> getListOfActionsWhichUserCanPerform(BMCServiceDesk__Change_Request__c  currentCMR,String currentUserId,List<GroupMember> userGroupList){
        //intializing the data
        createCmrActionsData();

        //get the current status
        String currentCmrStatus = currentCMR.HD_Change_Status__c.toUpperCase();

        //customMetadata 
        //commenting this logic as custom metadata limit has crossed
        //HD_CMR_Action_Map__mdt cmrActionMap = [Select Id,CAB_Managers__c,CMR_Status__c,Current_Approvers__c,Others__c,Owner_Sponsor_First_Coordinator__c from HD_CMR_Action_Map__mdt where CMR_Status__c=:currentCmrStatus][0];
        //check if no rows are returned

        ActionConfigDetails cmrActionMapTemp=cmrActionMap.get(currentCmrStatus);

        if(cmrActionMapTemp==null){
            return new List<String>();
        }
        //String listOfStatus;//fetch from customMetaData

        List<String> userRoles = getUserRolesForChange(currentCMR,currentUserId,userGroupList);
        Set<String> actions = new Set<String>();
        if(userRoles.contains(ROLE_SYSTEM_ADMIN)){
            try{
                List<String> roleActions = cmrActionMapTemp.cmrActionMap.get('SYSTEM_ADMINS').split(',');
                System.debug('roleActions:'+roleActions);
                actions.addAll(roleActions);
            }catch(Exception e){

            }
        }
        if(userRoles.contains(ROLE_OWNER)||userRoles.contains(ROLE_SPONSOR)||userRoles.contains(ROLE_COORDINATOR)){
            try{
                List<String> roleActions = cmrActionMapTemp.cmrActionMap.get('Owner_Sponsor_First_Coordinator').split(',');
                actions.addAll(roleActions);
            }catch(Exception e){

            }
        }  
        if(userRoles.contains(ROLE_APPROVER)){
            try{
                List<String> roleActions = cmrActionMapTemp.cmrActionMap.get('Current_Approvers').split(',');
                actions.addAll(roleActions);
            }catch(Exception e){

            }
        }   
        if(userRoles.contains(ROLE_CAB_MANAGER)){
            try{
                List<String> roleActions = cmrActionMapTemp.cmrActionMap.get('CAB_Managers').split(',');
                actions.addAll(roleActions);
            }catch(Exception e){

            }
        }  

        if(actions.isEmpty()){
            try{
                List<String> roleActions = cmrActionMapTemp.cmrActionMap.get('Others').split(',');
                actions.addAll(roleActions);
            }catch(Exception e){

            }
        }


        //logic to find and  
        //create list of group from which current user belongs to like "Owner/Sponsor/ First Coordinator/Current Approvers/CAB Managers/Others"
        List<String> usersGroup;

        //if 
        List<String> finalListOfActionWhichUserCanPerform = new List<String>();
        finalListOfActionWhichUserCanPerform.addAll(actions);

        //as per current status of ticket
        System.debug('finalListOfActionWhichUserCanPerform:'+finalListOfActionWhichUserCanPerform);

        String approvalStatus=currentCMR.CR_Approval_Status__c;

        if(currentCmrStatus.equalsIgnoreCase('Pending Approval')&& !(approvalStatus!=null && (approvalStatus.equalsIgnoreCase('Rejected') || approvalStatus.equalsIgnoreCase('Recalled')))){
            for(Integer j = 0; j < finalListOfActionWhichUserCanPerform.size(); j++){
                if(finalListOfActionWhichUserCanPerform.get(j).equalsIgnoreCase('Submit for Approval')){
                    finalListOfActionWhichUserCanPerform.remove(j);
                }
            }
        }

        if(currentCmrStatus.equalsIgnoreCase('Pending Approval')&& (approvalStatus!=null && approvalStatus.equalsIgnoreCase('Rejected'))){
            for(Integer j = 0; j < finalListOfActionWhichUserCanPerform.size(); j++){
                if(finalListOfActionWhichUserCanPerform.get(j).equalsIgnoreCase('Recall')){
                    finalListOfActionWhichUserCanPerform.remove(j);
                }
            }
        }
        
        if(currentCmrStatus.equalsIgnoreCase('Pending Approval')&& (approvalStatus!=null && approvalStatus.equalsIgnoreCase('Recalled'))){
            for(Integer j = 0; j < finalListOfActionWhichUserCanPerform.size(); j++){
                if(finalListOfActionWhichUserCanPerform.get(j).equalsIgnoreCase('Recall')){
                    finalListOfActionWhichUserCanPerform.remove(j);
                }
            }
        }

        return finalListOfActionWhichUserCanPerform;


    }
    /*@author: Komal Narsinghani
     *
     *
     */
    public static List<String> getUserRolesForChange(BMCServiceDesk__Change_Request__c cmr, Id userId,List<GroupMember> userGroupList){
        List<String> userRoles = new List<String>();
        List<Id> userGroupIds = new List<Id>();


        for(GroupMember userGroup:userGroupList){
            userGroupIds.add(userGroup.group.Id);
        }
        //HD_CMR_SETTINGS__c cmrSetting = [Select Id,CAB_Queue_Id__c from HD_CMR_SETTINGS__c][0];
        //Check for system admin role and providing list of actions
        Id profileId=UserInfo.getProfileId();
        Profile profileOfCurrentUser = [Select Name from Profile where Id =: profileId LIMIT 1][0];
        String profileName=profileOfCurrentUser.Name;
        if(profileName.equalsIgnoreCase(ROLE_SYSTEM_ADMIN)){
            userRoles.add(ROLE_SYSTEM_ADMIN);
        }
        HD_CMR_SETTINGS__c cmrSettings=HD_CMR_SETTINGS__c.getValues('CAB_Queue_Id');
        if(userGroupIds.contains(cmrSettings.Value__c)){
            userRoles.add(ROLE_CAB_MANAGER);
        }
        if(cmr.OwnerId == userId){
            userRoles.add(ROLE_OWNER);
        }
        /*if(cmr.HD_Sponsor__c == userId){
            userRoles.add(ROLE_SPONSOR);
        }*/
        if(cmr.Change_Coordinator_Primary__c == userId || cmr.Change_Coordinator__c == userId){
            userRoles.add(ROLE_COORDINATOR);
        }
        if(cmr.BMCServiceDesk__FKInitiator__c == userId){
            userRoles.add(ROLE_INITIATOR);
        }
        if(cmr.Second_Level_Approver__c == userId){
            userRoles.add(ROLE_APPROVER);
        }
        //check 7 queues approver
        return userRoles;    
    }
    /*
     *@author: Nikhil Karn
     *
     *
     */
    @AuraEnabled
    public static BMCServiceDesk__Change_Request__c approveOrRejectCMR(String workingItemId, String comments, String actionToBePerformed,BMCServiceDesk__Change_Request__c  currentCMR){


        System.debug('Inside approveOrRejectCMR with CURRENT CMR ID:'+currentCMR);
        if(actionToBePerformed=='Recall'){
            ProcessInstanceWorkitem[] workItems = [SELECT Id FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId = :currentCMR.Id 
                    AND ProcessInstance.Status = 'Pending'];
            if(workItems.size() == 0){
                throw new AuraHandledException('No Approvals to Recall');
            }
            actionToBePerformed='Removed';
            Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
            pwr.setAction(actionToBePerformed);
            pwr.setWorkItemId(workItems[0].id);
            Approval.ProcessResult result = Approval.process(pwr);
            if(result.success){
                return getCMR(currentCMR.Id);
            }else{
                return null;
            }
        }else{
            // Approve the submitted request
            // Instantiate the new ProcessWorkitemRequest object and populate it
            Approval.ProcessWorkitemRequest processWorkItemReq = new Approval.ProcessWorkitemRequest();
            processWorkItemReq.setComments(comments);
            processWorkItemReq.setAction(actionToBePerformed);
            processWorkItemReq.setNextApproverIds(new Id[] {UserInfo.getUserId()});

            // Use the ID from the newly created item to specify the item to be worked
            processWorkItemReq.setWorkitemId(workingItemId);

            // Submit the request for approval
            Approval.ProcessResult result2;

            result2=  Approval.process(processWorkItemReq);

            if(result2.isSuccess()){
				System.OrgLimit platformUsageLimit = OrgLimits.getMap().get('HourlyPublishedPlatformEvents');
                if(platformUsageLimit.getValue() < platformUsageLimit.getLimit()) {
                    List<CMR_Approval_Status_Event__e > approvalEvents = new List<CMR_Approval_Status_Event__e >();
                    approvalEvents.add(new CMR_Approval_Status_Event__e (
                        ActedBy__c =UserInfo.getUserId(), 
                        Action__c = actionToBePerformed, 
                        Record_ID__c = currentCMR.Id,
                        ProcessWorkItemId__c =workingItemId));
                    
                    // Call method to publish events
                    List<Database.SaveResult> results = EventBus.publish(approvalEvents);
                }
                System.debug('CURRENT CMR ID:'+currentCMR.Id);
                return getCMR(currentCMR.Id);
            }else{
                return null;
            }

        }
    }

    @AuraEnabled(cacheable=true)
    public static List<ListView> getAllListViews(){
        return HD_CMR_IndexPageRecords.getAllListViews();
    }

    @AuraEnabled
    public static BMCServiceDesk__Change_Request__c getCMR(String currentCMRId){
        String query='SELECT ID,BMCServiceDesk__FKInitiator__r.Alias,HD_Sponsor__r.Alias,BMCServiceDesk__FKInitiator__r.Name,HD_Sponsor__r.Name';
        List<String> cmrFields=new List<String>();
        List<Schema.FieldSetMember> filesset1 = SObjectType.BMCServiceDesk__Change_Request__c.FieldSets.HD_CMR_ViewFields.getFields();
        for (Schema.FieldSetMember fsm : filesset1) {
            cmrFields.add((String) fsm.getFieldPath());
            query=query+', '+ string.escapeSingleQuotes(fsm.getFieldPath());  //cs-fix PRTORES-1581 shegade
        }

        query=query+' from BMCServiceDesk__Change_Request__c where Id=:currentCMRId LIMIT 1';
        BMCServiceDesk__Change_Request__c currentCMR=Database.query(query);

        System.debug('INSIDE getCMR method and returning change:'+currentCMR);

        return currentCMR;

    }

}