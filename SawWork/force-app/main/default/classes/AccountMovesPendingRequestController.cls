public class AccountMovesPendingRequestController {



        ApexPages.standardController stdController= null;
        public AccountMovesPendingRequestController(ApexPages.StandardController controller) {
                stdController=controller;
        }
        public List<Account_Reassignment__c> accReassignmentList {get; set;}
        private Set<ID> accReassinmentIds=new Set<ID>();

        public list<item_to_approve_wrapper> my_items_to_approve { get; set; }
        public list<item_to_approve_wrapper> del_items_to_approve { get; set; }

        public Set<Id> massApproveRejectIdSet {get; set;}
        public Set<Id> massReassignIdSet {get; set;}
        public Boolean showButtonsManageAll {get; set;}
//public Boolean hidePopup{get; set;}

        public List<User> userRecordList {get; set;} // search results
        public string searchString {get; set;} // search keyword

//public String userName { get; set; }
//public Id userId { get; set; }

        public Boolean selectCheckbox {get; set;}
        public Integer limitCount;
        public Boolean showReAssignSection {get; set;}
        public Boolean showUserSearch {get; set;}
        public List<reAssign_approver_wrapper> userList {get; set;}
        public Id userID;
//public Map<Id,List<ProcessInstanceWorkItem>> pIIdToWIListMap;
        public Map<Id,String> pIIdToPINMap;
        public Map<Id,Id> WiIdToPIIdMap;

        public Integer rowNum {get; set;}
        public integer messageCount;
        public boolean showApproveRejectMsg {get; set;}
        public boolean showReassignMsg {get; set;}
        private String pageID;
        private Boolean isTheme4d = false; // MOB-337 Changes @Nagaraj Desai

//Wrapper class to show all the table columns including Account Reassignment and Approval Request fields
        public class item_to_approve_wrapper {
                public item_to_approve_wrapper(String requestName,Id requestId,String submittedDate,String accountName,Id accountId,String accountStatus,String targetCategory,String accountOwner,Id accountOwnerId,String assignToUser,Id assignToUserId,String originalActor,Id originalActorId,String changeLevel,String reasonCode,String reasonForChange,Id approvalid ) {
                        this.requestName = requestName;
                        this.requestId = requestId;
                        this.submittedDate = submittedDate;
                        this.accountName = accountName;
                        this.accountId =accountId;
                        this.targetCategory = targetCategory;
                        this.accountOwner = accountOwner;
                        this.accountOwnerId =accountOwnerId;
                        this.assignToUser =assignToUser;
                        this.assignToUserId = assignToUserId;
                        this.originalActor =originalActor;
                        this.originalActorId = originalActorId;
                        this.changeLevel = changeLevel;
                        this.reasonCode = reasonCode;
                        this.reasonForChange = reasonForChange;
                        this.approvalid =approvalid;
                        this.accountStatus = accountStatus;
                }
                public String requestName {get; set;}
                public Id requestId {get; set;}
                public String submittedDate { get; set; }
                public String accountName {get; set;}
                public Id accountId {get; set;}
                public String targetCategory {get; set;}
                public String accountOwner {get; set;}
                public String accountOwnerId {get; set;}
                public String assignToUser {get; set;}
                public Id assignToUserId {get; set;}
                public String changeLevel {get; set;}
                public String reasonCode {get; set;}
                public String reasonForChange {get; set;}
                public Id approvalid {get; set;}
                public Boolean CheckBox {get; set;}
                public String accountStatus {get; set;}
                public String originalActor {get; set;}
                public Id originalActorId {get; set;}

        }
        //Wrapper class to show the search User records and selected User for the Mass Reassign feature
        public class reAssign_approver_wrapper {
                public reAssign_approver_wrapper(String userName,Id userId)
                {
                        this.userId = userId;
                        this.userName = userName;
                }

                public Id userId {get; set;}
                public String userName {get; set;}
                public Boolean selectCheckBox {get; set;}
        }

        private void accountMovesPendingRequestInit() { // MOB-337 Changes:(by Nagaraj Desai) refactored the code from constructer to this function
                System.DEBUG('Enter: ');
                my_items_to_approve = new list<item_to_approve_wrapper>();
                del_items_to_approve = new list<item_to_approve_wrapper>();
                selectCheckbox = false;
                showButtonsManageAll = true;
                showApproveRejectMsg = false;
                showReassignMsg = false;

                System.DEBUG('pageId: ' + pageID);

                //limitCount = Integer.valueOf(GsmUtilClass.getAccountReassignSettingValue('AccountMovesLimitCount1'));
                limitCount = Integer.valueOf(GsmUtilClass.getAccountReassignSettingValue('AccountMovesLimitCount1'));

                massApproveRejectIdSet = new set<Id>();
                showReAssignSection = false;
                //pIIdToWIListMap = new Map<Id,List<ProcessInstanceWorkItem>>();
                pIIdToPINMap = new Map<Id,String>();
                WiIdToPIIdMap = new Map<Id,Id>();
                rowNum = 5;

                //To redirect to the Detail page from homepage based on parameter
                if(!String.isEmpty(pageID))
                {
                        if(pageID.contains('detailPage'))
                        {
                                selectCheckbox = true;
                                showButtonsManageAll = false;
                        }
                        //limitCount = Integer.valueOf(GsmUtilClass.getAccountReassignSettingValue('AccountMovesLimitCount2'));
                        rowNum = Integer.valueOf(GsmUtilClass.getAccountReassignSettingValue('AccountMovesLimitCount2'));
                }
                system.debug('Limit Count '+limitCount);
                List<User> deleagtedUserList  = [Select Id From User Where DelegatedApproverId  = :Userinfo.getUserId()];
                Set<Id> delegatedUserIds = new Set<Id>();
                Set<Id> userIDset = new Set<Id>();

                if(deleagtedUserList.size() > 0)
                {
                        for(User usr: deleagtedUserList)
                        {
                                userIDset.add(usr.Id);
                                delegatedUserIds.add(usr.Id);
                        }
                }

                //Adding the current user too
                userIDset.add(Userinfo.getUserId());


                List<ProcessInstanceWorkItem> piwiList = new List<ProcessInstanceWorkItem>();
                Map<Id,ProcessInstanceWorkItem> objectIdToPIWIMap = new Map<Id,ProcessInstanceWorkItem>();

                //Get all Pending Approval Requests where Actor or Orginal Actor is logged in User and Request belongs to Account Reassignment Object
                //List<ProcessInstanceWorkItem> PIWIList = [select ActorId,Actor.Name,OriginalActorId,ProcessInstance.TargetObjectId,CreatedDate ,ProcessInstance.TargetObject.Name,ProcessInstance.TargetObject.type from ProcessInstanceWorkItem where ActorId IN :userIDset AND ProcessInstance.TargetObject.Type = 'Account_Reassignment__c' AND ProcessInstance.Status= 'Pending' Order by CreatedDate Desc Limit :limitCount];
                List<ProcessInstance> PIList =  [Select (Select Id,ActorId,Actor.Name,OriginalActorId,ProcessInstance.TargetObjectId,CreatedDate,ProcessInstance.TargetObject.Name,ProcessInstance.TargetObject.type From Workitems Where ActorId IN :userIDset ORDER BY CreatedDate DESC),(Select Id, IsDeleted, LastActorId, NodeStatus, ProcessInstanceId, ProcessNodeId, ProcessNodeName From Nodes Where NodeStatus='Pending' ORDER BY CreatedDate DESC) From ProcessInstance p WHERE TargetObject.Type = 'Account_Reassignment__c' AND Status= 'Pending' Order by CreatedDate Desc Limit :limitCount];

                system.debug('List size '+PIList.size());


                for(ProcessInstance pi :PIList)
                {
                        if(pi.Workitems.size() > 0)
                        {
                                for(ProcessInstanceWorkItem piWI : pi.Workitems)
                                {
                                        WiIdToPIIdMap.put(piWI.Id,pi.Id);
                                        piwiList.add(piWI);

                                }
                                //pIIdToWIListMap.put(pi.Id,pi.Workitems);

                        }


                        for(ProcessInstanceNode pin: pi.Nodes) {
                                if(pin.NodeStatus == 'Pending')
                                        pIIdToPINMap.put(pi.Id,pin.ProcessNodeName);
                        }
                }
                //List<ProcessInstanceWorkItem> PIWIList = new List<ProcessInstanceWorkitem>();

                /*if(!WiIdToPIIdMap.isEmpty()){
                   for(List<ProcessInstanceWorkItem> piRecList : WiIdToPIIdMap.values()){
                    PIWIList.addAll(piRecList);
                   }
                   }*/
                //Map of Target Object Id to the Request associated

                if(!WiIdToPIIdMap.isEmpty()) {
                        for(ProcessInstanceWorkItem item: piwiList) {

                                accReassinmentIds.add(item.processinstance.targetobjectid);

                                if(!objectIdToPIWIMap.containsKey(item.processinstance.targetobjectid)) {
                                        objectIdToPIWIMap.put(item.processinstance.targetobjectid,item);
                                }
                        }
                }

                Map<Id,Account_Reassignment__c> accReassIdToRecordMap = new Map<Id,Account_Reassignment__c>();

                //Get all the Account Reassignemtn records for the pending requests to define the wrapper class
                if(accReassinmentIds.size()>0) {
                        accReassignmentList = [select id,Name,LastModifiedDate,Account__c,Account__r.Name,Account_Status__c,Target_Category__c,Account_Owner__c,Account_Owner__r.Name,Assign_To_User__c,Assign_To_User__r.Name,Change_Level__c,Reason_Code__c,Reason_for_Change__c from Account_Reassignment__c where id in : accReassinmentIds];
                        if(!accReassignmentList.isEmpty()) {
                                for(Account_Reassignment__c accRea:accReassignmentList) {
                                        accReassIdToRecordMap.put(accRea.id,accRea);
                                }
                        }
                }

                //Build the wrapper items for all pending requests with the parent object details
                if(!objectIdToPIWIMap.isEmpty()) {
                        for(ProcessInstanceWorkItem item: objectIdToPIWIMap.values())
                        {
                                system.debug('Inside the for loop '+item.OriginalActorId +' User Id  '+UserInfo.getUserId());
                                //For the orginal requests
                                if(item.ActorId == UserInfo.getUserId())
                                {

                                        DateTime dTTime = accReassIdToRecordMap.get(item.processinstance.targetobjectid).LastModifiedDate;


                                        my_items_to_approve.add(new item_to_approve_wrapper(
                                                                        accReassIdToRecordMap.get(item.processinstance.targetobjectid).Name,
                                                                        accReassIdToRecordMap.get(item.processinstance.targetobjectid).Id,

                                                                        dTTime.format(),
                                                                        accReassIdToRecordMap.get(item.processinstance.targetobjectid).Account__r.Name,
                                                                        accReassIdToRecordMap.get(item.processinstance.targetobjectid).Account__c,
                                                                        accReassIdToRecordMap.get(item.processinstance.targetobjectid).Account_Status__c,
                                                                        accReassIdToRecordMap.get(item.processinstance.targetobjectid).Target_Category__c,
                                                                        accReassIdToRecordMap.get(item.processinstance.targetobjectid).Account_Owner__r.Name,

                                                                        accReassIdToRecordMap.get(item.processinstance.targetobjectid).Account_Owner__c,
                                                                        accReassIdToRecordMap.get(item.processinstance.targetobjectid).Assign_To_User__r.Name,

                                                                        accReassIdToRecordMap.get(item.processinstance.targetobjectid).Assign_To_User__c,
                                                                        item.Actor.Name,
                                                                        item.ActorId,

                                                                        accReassIdToRecordMap.get(item.processinstance.targetobjectid).Change_Level__c,
                                                                        accReassIdToRecordMap.get(item.processinstance.targetobjectid).Reason_Code__c,
                                                                        accReassIdToRecordMap.get(item.processinstance.targetobjectid).Reason_for_Change__c,
                                                                        item.id ));
                                }

                                //For the delegated requests
                                //else if(item.ActorId == UserInfo.getUserId() && item.OriginalActorId != item.ActorId)
                                else if(delegatedUserIds.size() > 0 && delegatedUserIds.contains(item.ActorId))
                                {
                                        DateTime dTTimeD = accReassIdToRecordMap.get(item.processinstance.targetobjectid).LastModifiedDate;

                                        del_items_to_approve.add(new item_to_approve_wrapper(
                                                                         accReassIdToRecordMap.get(item.processinstance.targetobjectid).Name,
                                                                         accReassIdToRecordMap.get(item.processinstance.targetobjectid).Id,
                                                                         dTTimeD.format(),
                                                                         accReassIdToRecordMap.get(item.processinstance.targetobjectid).Account__r.Name,
                                                                         accReassIdToRecordMap.get(item.processinstance.targetobjectid).Account__c,
                                                                         accReassIdToRecordMap.get(item.processinstance.targetobjectid).Account_Status__c,
                                                                         accReassIdToRecordMap.get(item.processinstance.targetobjectid).Target_Category__c,
                                                                         accReassIdToRecordMap.get(item.processinstance.targetobjectid).Account_Owner__r.Name,

                                                                         accReassIdToRecordMap.get(item.processinstance.targetobjectid).Account_Owner__c,
                                                                         accReassIdToRecordMap.get(item.processinstance.targetobjectid).Assign_To_User__r.Name,
                                                                         accReassIdToRecordMap.get(item.processinstance.targetobjectid).Assign_To_User__c,
                                                                         item.Actor.Name,
                                                                         item.ActorId,

                                                                         accReassIdToRecordMap.get(item.processinstance.targetobjectid).Change_Level__c,
                                                                         accReassIdToRecordMap.get(item.processinstance.targetobjectid).Reason_Code__c,
                                                                         accReassIdToRecordMap.get(item.processinstance.targetobjectid).Reason_for_Change__c,
                                                                         item.id ));
                                }

                        }
                }

        }

        public AccountMovesPendingRequestController(String fromWhere) { // MOB-337 Changes:(by Nagaraj Desai) added this constructor
                if(fromWhere == 'Theme4d') {
                  isTheme4d = true;
                }
                accountMovesPendingRequestInit();
        }

        public AccountMovesPendingRequestController() { // MOB-337 Changes:(by Nagaraj Desai) changed this constructor added accountMovesPendingRequestInit function
                pageID = ApexPages.currentPage().getParameters().get('pageId');
                accountMovesPendingRequestInit();

                System.debug('Wrapper record list size 1'+my_items_to_approve.size());

                String message = '' + ApexPages.CurrentPage().GetParameters().Get('message');
                String pageHeaderReferer = ApexPages.currentPage().getHeaders().get('Referer');

                // Use the referrer parameter to only show the message when coming from Page 1
                if(pageHeaderReferer != null && pageHeaderReferer.containsIgnoreCase('AccountMovesPendingRequest') && message != 'null')
                {
                        ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, message));
                }
                pageHeaderReferer ='';
                message ='';

        }
        //Method for individual request Approve Reject

        public static String ApproveRejectnavigation() {
                String url='';
                string myParam = apexpages.currentpage().getparameters().get('myParam');
                url='https://'+ System.URL.getSalesforceBaseUrl().getHost() +
                     '/p/process/ProcessInstanceWorkitemWizardStageManager?id=' + myParam;

                return url;

        }
        //Method for individual request Reassign
        public static String REASSIGNnavigation() {
                String url='';
                string myParam = apexpages.currentpage().getparameters().get('myParam');
                url='https://'+ System.URL.getSalesforceBaseUrl().getHost()+'/'+ myParam +'/e?et=REASSIGN';
                return url;

        }

        //Method to capture the ids selected for mass Approve/Reject/Reassign
        public PageReference  inputCheckForSelectRequest()
        {

                massApproveRejectIdSet = new Set<Id>();

                for(item_to_approve_wrapper mItem: my_items_to_approve)
                {
                        if(mItem.Checkbox == True)
                        {
                                massApproveRejectIdSet.add(mItem.approvalid);
                        }
                }

                for(item_to_approve_wrapper dItem: del_items_to_approve)
                {
                        if(dItem.Checkbox == True)
                        {
                                massApproveRejectIdSet.add(dItem.approvalid);
                        }
                }




                System.debug(LoggingLevel.ERROR, 'set of to be aprroved/reject Ids' + massApproveRejectIdSet);
                return null;

        }
        //MEthod to identify selected User
        public PageReference inputCheckForSelectUser()
        {

                system.debug('HC all values User Id '+userID +'Size '+massApproveRejectIdSet +'User List '+userList);

                for(reAssign_approver_wrapper raw:userList)
                {
                        if(raw.selectCheckBox == True)
                                userID = raw.userId;
                }

                system.debug('HC all values User Id '+userID +'Size '+massApproveRejectIdSet);

                return null;
        }

        public void redirectToNewPage()
        {

                showUserSearch =true;
        }

        public boolean displayPopup {get; set;}
        public String approveRejectComment {get; set;}

        //public String reassignComment {get; set;}

        public void closePopup() {
                displayPopup = false;
                system.debug('Show Popup '+displayPopup);

                //pagereference p = apexpages.Currentpage();
                //p.getParameters().put('pageId','detailPage');

                //apexpages.Message msg = new Apexpages.Message(ApexPages.Severity.Info,'Total Number of reloads: ');
                //apexpages.addmessage(msg);
                //return p;
/*PageReference pr = new PageReference('/apex/AccountMovesPendingRequest?pageId=detailPage');

            pr.getParameters().put('message', 'Approval Requests are being processed,please refresh the page in sometime to see the latest changes.You will be recieving an email in case of any failures.');
            pr.getParameters().put('pageId','detailPage');


      pr.setRedirect(true);

      system.debug('Return URL '+pr);

      return pr;*/
                //showApproveRejectMsg = true;
                showReAssignSection = false;


        }
        public void showPopup() {

                inputCheckForSelectRequest();

                if(massApproveRejectIdSet.size()<1)
                        ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select atleast one row.'));
                /*else if(massApproveRejectIdSet.size()>5)
                     ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a maximum of 5 accounts for approval at a time.'));
                 */
                else
                        displayPopup = true;
                system.debug('Show Popup '+displayPopup);
        }


        public void showReassignSectionMethod() {

                inputCheckForSelectRequest();

                if(massApproveRejectIdSet.size()<1)
                {

                        showReAssignSection = false;
                        ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select atleast one row.'));
                }
                /*else if(massApproveRejectIdSet.size()>5)
                     ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a maximum of 5 accounts for approval at a time.'));
                 */
                else
                        showReAssignSection = true;
        }

        //Method to mass approve selected requests
        public PageReference approveSelected(){

                displayPopup = false;

                Map<String,Set<Id>> stepNameToIDMap = new Map<String,Set<Id>>();

                system.debug(' List of Ids to approve '+massApproveRejectIdSet +' Display '+displayPopup + 'Comment '+approveRejectComment);
                if(massApproveRejectIdSet.size() > 0)
                {
                        for ( Id piwiId :massApproveRejectIdSet)
                        {
                                if(WiIdToPIIdMap.containsKey(piwiId)) {

                                        if(pIIdToPINMap.containsKey(WiIdToPIIdMap.get(piwiId)))
                                        {


                                                String stepName = 'Approve'+'_'+pIIdToPINMap.get(WiIdToPIIdMap.get(piwiId))+'_'+approveRejectComment;
                                                if(stepNameToIDMap.containsKey(stepName))
                                                {
                                                        set<Id> tempIdSet = stepNameToIDMap.get(stepName);
                                                        tempIdSet.add(piwiId);
                                                        stepNameToIDMap.put(stepName,tempIdSet);


                                                }

                                                else
                                                {
                                                        set<Id> tempIdSet = new Set<Id>();
                                                        tempIdSet.add(piwiId);
                                                        stepNameToIDMap.put(stepName,tempIdSet);
                                                }
                                        }
                                }



                        }
                }
                Promise callOutVar;
                integer counter = 1;
                integer stepSize;
                system.debug('Map '+stepNameToIDMap);
                if(!stepNameToIDMap.isEmpty())
                {
                        stepSize = stepNameToIDMap.size();
                        for(String stepNames : stepNameToIDMap.keySet())
                        {
                                if(counter == 1 && stepNameToIDMap.size() == 1)
                                {
                                        system.debug('Inisde 1 size'+stepNameToIDMap);
                                        callOutVar = new Promise(new AccountMovesCallout());
                                        callOutVar.execute(stepNameToIDMap);
                                }


                                else if(counter == 1 && stepNameToIDMap.size() > 1)
                                {
                                        system.debug('Still more to go');
                                        callOutVar = new Promise(new AccountMovesCallout());

                                }
                                else
                                {
                                        if(counter != stepSize)
                                        {
                                                system.debug('Still not step size');
                                                callOutVar.then(new AccountMovesCallout() );
                                        }

                                        else
                                        {
                                                system.debug('Reached step size ');
                                                callOutVar.then(new AccountMovesCallout());
                                                callOutVar.execute(stepNameToIDMap);
                                        }


                                }
                                counter++;





                        }
                }







                PageReference pr = new PageReference('/apex/AccountMovesPendingRequest?pageId=detailPage');

                pr.getParameters().put('message', 'Approval Requests are being processed,please refresh the page in sometime to see the latest changes.You will be recieving an email in case of any failures.');



                pr.setRedirect(true);

                system.debug('Return URL '+pr);

                return pr;

                //ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, 'Approval Requests are being processed,please refresh the page in sometime to see the latest changes.You will be recieving an email in case of any failures.'));


        }
        //Method to mass reject the requests
        public PageReference rejectSelected(){

                displayPopup = false;

                Map<String,Set<Id>> stepNameToIDMap = new Map<String,Set<Id>>();

                system.debug(' List of Ids to approve '+massApproveRejectIdSet +' Display '+displayPopup + 'Comment '+approveRejectComment);
                if(massApproveRejectIdSet.size() > 0)
                {
                        for ( Id piwiId :massApproveRejectIdSet)
                        {
                                if(WiIdToPIIdMap.containsKey(piwiId)) {

                                        if(pIIdToPINMap.containsKey(WiIdToPIIdMap.get(piwiId)))
                                        {


                                                String stepName = 'Reject'+'_'+pIIdToPINMap.get(WiIdToPIIdMap.get(piwiId))+'_'+approveRejectComment;
                                                if(stepNameToIDMap.containsKey(stepName))
                                                {
                                                        set<Id> tempIdSet = stepNameToIDMap.get(stepName);
                                                        tempIdSet.add(piwiId);
                                                        stepNameToIDMap.put(stepName,tempIdSet);


                                                }

                                                else
                                                {
                                                        set<Id> tempIdSet = new Set<Id>();
                                                        tempIdSet.add(piwiId);
                                                        stepNameToIDMap.put(stepName,tempIdSet);
                                                }
                                        }
                                }



                        }
                }
                Promise callOutVar;
                integer counter = 1;
                integer stepSize;

                if(!stepNameToIDMap.isEmpty())
                {
                        stepSize = stepNameToIDMap.size();
                        for(String stepNames : stepNameToIDMap.keySet())
                        {
                                if(counter == 1 && stepNameToIDMap.size() == 1)
                                {
                                        system.debug('Inisde 1 size'+stepNameToIDMap);
                                        callOutVar = new Promise(new AccountMovesCallout());
                                        callOutVar.execute(stepNameToIDMap);
                                }


                                else if(counter == 1 && stepNameToIDMap.size() > 1)
                                {
                                        system.debug('Still more to go');
                                        callOutVar = new Promise(new AccountMovesCallout());

                                }
                                else
                                {
                                        if(counter != stepSize)
                                        {
                                                system.debug('Still not step size');
                                                callOutVar.then(new AccountMovesCallout() );
                                        }

                                        else
                                        {
                                                system.debug('Reached step size ');
                                                callOutVar.then(new AccountMovesCallout());
                                                callOutVar.execute(stepNameToIDMap);
                                        }


                                }
                                counter++;





                        }
                }


                if(!isTheme4d) { // MOB-337 changes : set Apex page message only if called from  Classic
                        ApexPages.AddMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM,'Approval Requests are being processed,please refresh the page in sometime to see the latest changes.You will be recieving an email in case of any failures.'));
                }




                PageReference pr = new PageReference('/apex/AccountMovesPendingRequest?pageId=detailPage');

                pr.getParameters().put('message', 'Approval Requests are being processed,please refresh the page in sometime to see the latest changes.You will be recieving an email in case of any failures.');


                pr.setRedirect(true);

                system.debug('Return URL '+pr);

                return pr;

        }

        //Method to mass reassign the requests
        public PageReference massReassignRequests(){

                system.debug('HC all values User Id '+userID +'Size '+massApproveRejectIdSet);
                List<ProcessInstanceWorkitem>  listWorkitemTemp = new List<ProcessInstanceWorkItem>();
                if(massApproveRejectIdSet.size() > 0)
                {
                        //Get all the process steps for selected requests to change the approver
                        List<ProcessInstanceWorkitem>  listWorkitem = new List<ProcessInstanceWorkitem>([select Id, ActorId, OriginalActorId, ProcessInstanceId from ProcessInstanceWorkitem where Id In:massApproveRejectIdSet]);
                        if(userID != null && listWorkitem.size() > 0 )
                        {
                                for(ProcessInstanceWorkitem pwi :listWorkitem)
                                {
                                        pwi.ActorId = userID;

                                        listWorkitemTemp.add(pwi);
                                }
                        }
                }

                try {
                        if(listWorkitemTemp.size() > 0)
                                update listWorkitemTemp;
                }
                catch(DmlException e) {

                        System.debug('The following exception has occurred: ' + e.getMessage());

                }


                PageReference pr = new PageReference('/apex/AccountMovesPendingRequest?pageId=detailPage');
                pr.setRedirect(true);

                return pr;

        }


        // performs the user search based on input search string
        public PageReference search() {
                userRecordList = performSearch(searchString);

                if(userRecordList.size() > 0)
                {
                        userList = new list<reAssign_approver_wrapper>();

                        for(User usr:userRecordList)
                        {
                                userList.add(new reAssign_approver_wrapper(
                                                     usr.Name,
                                                     usr.Id));
                        }

                }
                return null;
        }



        // run the query and return the records found.
        private List<User> performSearch(string searchString) {

                String soql = 'select id, name from user';
                if(searchString != '' && searchString != null)
                        soql = soql +  ' where name LIKE \'%' + searchString +'%\'';
                soql = soql + ' limit 25';
                System.debug(soql);
                return database.query(soql);


        }

}