global class SC_Jarvis_CaseUpdate_Batch2 implements Database.Batchable<sObject>, Database.stateful{

    String caseQuery;
    String caseQuery_Test;
    Public string errorMessage = '' ;
    String batchType;
    public SC_Jarvis_CaseUpdate_Batch2(String batchTypeName, String AccountIdString){
        String accountFilter;
        if(AccountIdString == null || AccountIdString == '')
            accountFilter = ' Account.Type LIKE \'%- Active%\' AND Created_By_Account__c = null ';
        else
                accountFilter = ' Created_By_Account__c = null AND Account.AKAM_Account_Id__c in ('+AccountIdString+') ';


        //For Managed Security Cases -> Cases Created after Jan 1st 2021
        if(batchTypeName == 'Managed Security'){
            batchType = 'Managed Security';
            DateTime considerationDate = Datetime.newInstanceGmt(2021, 01, 01, 00, 00, 00);
            caseQuery = 'SELECT Id, AccountId, Community_Sharing_Set_Account_Lookup__c, Contact.Account.Name, Created_By_Account__c, Indirect_Customer__c, Policy_Domain__c, Account.AKAM_Account_Id__c, RecordType.Name, IsClosed, ContactId, Contact.AccountID FROM Case '+
                    ' WHERE RecordType.Name in (\'Managed Security\')'+
                    ' AND Do_Not_Show_in_Portal__c = False AND '+
                    accountFilter + ' AND CreatedDate >='+considerationDate.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');

        }
        //This will not be used in Prod
        else if(batchTypeName== 'Direct Customers'){
            batchType = 'Direct Customers';
            caseQuery = 'SELECT Id, AccountId, Community_Sharing_Set_Account_Lookup__c, Created_By_Account__c, Indirect_Customer__c, Policy_Domain__c, Account.AKAM_Account_Id__c, RecordType.Name, IsClosed, ContactId, Contact.AccountID, Contact.Account.AKAM_Account_Id__c, Indirect_Customer__r.AKAM_Account_Id__c FROM Case '+
                    ' WHERE Indirect_Customer__c = null AND RecordType.Name in (\'Technical\', \'Professional Services\', \'Billing\', \'AMG\', \'Emerging Products Engineering\' )'+
                    ' AND Do_Not_Show_in_Portal__c = False AND '+ accountFilter;
        }
        //This is for ATT Cases
        else if(batchTypeName == 'ATT'){
            batchType = 'ATT';
            caseQuery = 'SELECT Id, AccountId, Community_Sharing_Set_Account_Lookup__c, Created_By_Account__c, Indirect_Customer__c, Account.AKAM_Account_Id__c, ContactId, Contact.AccountID, Contact.Account.AKAM_Account_Id__c, Indirect_Customer__r.AKAM_Account_Id__c, Contact.Account.Name FROM Case '+
                    ' WHERE RecordType.Name in (\'Partner Technical Support\') AND Do_Not_Show_in_Portal__c = False AND ATT_RecordType__c != \'Managed Security\' AND ATT_RecordType__c != \'\' AND '+ accountFilter;

        }
        //This is for all the Cases except Managed Security Cases
        else{
            batchType = 'Others';
            caseQuery = 'SELECT Id, AccountId, Community_Sharing_Set_Account_Lookup__c, Created_By_Account__c, Indirect_Customer__c, Policy_Domain__c, Account.AKAM_Account_Id__c, RecordType.Name, IsClosed, ContactId, Contact.AccountID, Contact.Account.AKAM_Account_Id__c, Indirect_Customer__r.AKAM_Account_Id__c,Contact.Account.Name FROM Case '+
                    ' WHERE RecordType.Name in (\'Technical\', \'Professional Services\', \'Billing\', \'AMG\', \'Emerging Products Engineering\' )'+
                    ' AND Do_Not_Show_in_Portal__c = False AND '+ accountFilter;
        }
        caseQuery_Test = 'SELECT Id, AccountId, Community_Sharing_Set_Account_Lookup__c, Created_By_Account__c, Indirect_Customer__c, Policy_Domain__c, Account.AKAM_Account_Id__c, RecordType.Name, IsClosed, ContactId, Contact.AccountID, Contact.Account.AKAM_Account_Id__c, Indirect_Customer__r.AKAM_Account_Id__c  FROM Case LIMIT 10';

        System.debug('--caseQuery--'+caseQuery);
        sendEmailforException(caseQuery);
    }

    //Start Method
    global Database.QueryLocator start(Database.BatchableContext BC){
        //Check whether its a test class execution or normal execution
        string batchQuery = (System.Test.isRunningTest()) ? caseQuery_Test : caseQuery;

        //Deactive Case Notification Subscription
        SCRecordTypeCustomSetting__c customSetting = [SELECT Id, RecordTypeName__c FROM SCRecordTypeCustomSetting__c WHERE Name = 'NotificationTeam' LIMIT 1];
        customSetting.RecordTypeName__c = '';
        Update customSetting;

        if(batchQuery != null)
            return Database.getQueryLocator(batchQuery);
        else
                return null;
    }

    global void execute(Database.BatchableContext BC, List<sObject> scope){
        //Convert Sobject list to Case List
        List<Case> qualifiedcaseList = (Case[]) scope;

        //Call helper class to identify and remove the IP Addresses
        if(qualifiedcaseList.size() > 0){
            if(batchType == 'Managed Security'){
                errorMessage +=  populateAccountFieldsSOCC(qualifiedcaseList);
            }
            else if(batchType == 'Direct Customers'){
                errorMessage +=  populateAccountFieldsDirect(qualifiedcaseList);
            }
            else{
                errorMessage +=  populateAccountFields(qualifiedcaseList);
            }
        }


    }
    global void finish(Database.BatchableContext BC){
        //Active Case Notification Subscription
        SCRecordTypeCustomSetting__c customSetting = [SELECT Id, RecordTypeName__c FROM SCRecordTypeCustomSetting__c WHERE Name = 'NotificationTeam' LIMIT 1];
        customSetting.RecordTypeName__c = 'Professional Services&&AMG&&Technical&&Managed Security&&Carrier Products&&Emerging Products Engineering&&BOCC';
        Update customSetting;

        if(errorMessage.length() > 5){
            sendEmailforException(errorMessage);
        }
    }

    //This method will not be used in Production
    public static string populateAccountFieldsDirect(List<Case> caseList){
        String errormsg = '';
        List<Case> caseListForUpdate = new List<Case>();
        //Set<Id> caseIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Map<Id, Id> caseIdAccountIdMap = new Map<Id, Id>();
        Map<Id, String> caseIdGroupNameMap_WRITE = new Map<Id, String>();
        String groupNameWRITE;
        //Creating Savepoint
        Savepoint sp = Database.setSavepoint();
        Try{

            For(Case eachCase : caseList){
                eachCase.Validation_Override__c = True;
                if((eachCase.ContactId != null && eachCase.Contact.AccountId == eachCase.AccountId) || eachCase.ContactId == null){
                    //Read Access
                    eachCase.Community_Sharing_Set_Account_Lookup__c = eachCase.AccountId;
                    eachCase.Created_By_Account__c = eachCase.AccountId;

                    //CaseShare
                    groupNameWRITE = SC_Jarvis_CaseUpdate_Batch2.prepareGroupName('JARVIS_ACCOUNT' +eachCase.Account.AKAM_Account_Id__c);
                    caseIdGroupNameMap_WRITE.put(eachCase.Id, groupNameWRITE);

                    //Community Comments Share
                    caseIdAccountIdMap.put(eachCase.Id, eachCase.Community_Sharing_Set_Account_Lookup__c);
                    caseListForUpdate.add(eachCase);
                }
            }

            if(caseIdAccountIdMap.size() > 0){

                Update caseListForUpdate;

                List<CaseShare> caseShareInsertList = new List<CaseShare>();
                List<Community_Comments__Share> commentShareList = new List<Community_Comments__Share>();

                DateTime considerationDate = (System.Test.isRunningTest()) ? system.now().addDays(1) : Datetime.newInstanceGmt(2021, 09, 28, 01, 15, 00);
                list<task> taskCommentsList = [SELECT Id, Whoid, Whatid, Description, Createddate FROM Task WHERE Type__c='Web Update' AND Createddate < :considerationDate AND Whatid in :caseIdAccountIdMap.keySet()];
                Map<id,id> contactidUseridmap = new map<id,id>();

                for(task eachtask : taskCommentsList){
                    contactIds.add(eachtask.Whoid);
                }

                for(User eachUser : [SELECT Id,Contactid FROM User WHERE contactid IN :contactids]){
                    contactidUseridmap.put(eachUser.contactid, eachUser.id);
                }
                List<Community_Comments__c> communityCommentsList = new List<Community_Comments__c>();
                Community_Comments__c newcomment;

                for(task eachTask : taskCommentsList){
                    newcomment = new Community_Comments__c();
                    newcomment.Parent_ID__c=eachtask.Whatid;
                    newcomment.Contact__c=eachTask.Whoid;
                    newcomment.Visibility__c='Public';
                    newcomment.Commented_By__c='Customer';
                    newcomment.Comment__c=eachtask.Description;
                    newcomment.Application__c ='JARVIS';
                    newcomment.Related_Object__c='Case';
                    newcomment.AKAM_Created_Date__c=eachTask.createddate;
                    newcomment.AKAM_Modified_Date__c=eachTask.createddate;
                    newcomment.Account_ID_for_Community_Share__c = caseIdAccountIdMap.get(eachtask.Whatid);
                    newcomment.Skip_Email_Notification__c = True;

                    if(contactidUseridmap.containsKey(eachTask.Whoid)){
                        newcomment.AKAM_Created_By__c=contactidUseridmap.get(eachTask.Whoid);
                    }
                    else
                            newcomment.AKAM_Created_By__c=userinfo.getUserId();

                    communityCommentslist.add(newcomment);
                }
                if(communityCommentslist.size() > 0)
                    Insert communityCommentslist;

                Map<String, Id> groupNameIdMap = new Map<String, Id>();
                For(Group eachGroup : [SELECT Id, Name FROM Group WHERE Name In :caseIdGroupNameMap_WRITE.values()]){
                    groupNameIdMap.put(eachGroup.Name, eachGroup.Id);
                }

                CaseShare caseShareRec;
                For(Id eachCaseId : caseIdGroupNameMap_WRITE.keySet()){
                    caseShareRec = new CaseShare();
                    caseShareRec.CaseId = eachCaseId;
                    caseShareRec.RowCause = 'Manual';
                    caseShareRec.CaseAccessLevel = 'Edit';
                    caseShareRec.UserOrGroupId = groupNameIdMap.get(caseIdGroupNameMap_WRITE.get(eachCaseId));
                    caseShareInsertList.add(caseShareRec);
                }


                if(caseShareInsertList.size() > 0)
                    Insert caseShareInsertList;


            }
        }
        Catch(Exception ex){
            errormsg = ex.getMessage() + '\n';
            Database.rollback(sp);
        }
        system.debug('--Vam--Error Message--'+ errormsg);

        return errormsg;

    }

    //This method will be called for All customers
    public static string populateAccountFields(List<Case> caseList){

        String errormsg = '';
        List<Case> caseListForUpdate = new List<Case>();
        Set<Id> caseIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Map<Id, Id> caseIdAccountIdMap = new Map<Id, Id>();
        Map<Id, String> caseIdGroupNameMap_READ = new Map<Id, String>();
        Map<Id, String> caseIdGroupNameMap_WRITE = new Map<Id, String>();
        String groupNameREAD;
        String groupNameWRITE;

        //Creating Savepoint
        Savepoint sp = Database.setSavepoint();
        Try{

            String childAccount, parentAccount;

            For(Case eachCase : caseList){

                eachCase.Validation_Override__c = True;

                //List of Cases to Quert Tasks of type Web Update
                caseIds.add(eachCase.Id);

                //Cases where Contact is from Akamai
                if(eachCase.ContactID != null && eachCase.Contact.AccountID != null && eachCase.Contact.Account.Name.containsIgnoreCase('Akamai')){

                    //When Indirect Customer is populated
                    if(eachCase.Indirect_Customer__c != null && eachCase.AccountId != eachCase.Indirect_Customer__c){
                        eachCase.Community_Sharing_Set_Account_Lookup__c = null;
                        eachCase.Created_By_Account__c = eachCase.AccountId;

                        childAccount = String.valueOf(eachCase.Indirect_Customer__c).substring(0, 15);
                        parentAccount = String.valueOf(eachCase.AccountId).substring(0, 15);

                        //CaseShare -> Share the case for Reseller
                        groupNameREAD = SC_Jarvis_CaseUpdate_Batch2.prepareGroupName('JA_' +childAccount + '_'+ parentAccount + '_R');
                        groupNameWRITE = SC_Jarvis_CaseUpdate_Batch2.prepareGroupName('JA_' +childAccount + '_'+ parentAccount + '_W');
                        caseIdGroupNameMap_READ.put(eachCase.Id, groupNameREAD);
                        caseIdGroupNameMap_WRITE.put(eachCase.Id, groupNameWRITE);
                    }
                    //Consider everything else as Direct Case
                    else {
                        //Read Access
                        eachCase.Community_Sharing_Set_Account_Lookup__c = eachCase.AccountId;
                        eachCase.Created_By_Account__c = eachCase.AccountId;

                        //CaseShare -> Share the Case as Direct Customer Case
                        groupNameWRITE = SC_Jarvis_CaseUpdate_Batch2.prepareGroupName('JARVIS_ACCOUNT' +eachCase.Account.AKAM_Account_Id__c);
                        caseIdGroupNameMap_WRITE.put(eachCase.Id, groupNameWRITE);

                        //Community Comments Share
                        caseIdAccountIdMap.put(eachCase.Id, eachCase.Community_Sharing_Set_Account_Lookup__c);

                    }

                }
                //When a reseller creates the case for its child account through ACC
                else if(eachCase.Indirect_Customer__c != null && eachCase.AccountId != eachCase.Indirect_Customer__c){
                    eachCase.Community_Sharing_Set_Account_Lookup__c = null;
                    eachCase.Created_By_Account__c = eachCase.AccountId;

                    childAccount = String.valueOf(eachCase.Indirect_Customer__c).substring(0, 15);
                    parentAccount = String.valueOf(eachCase.AccountId).substring(0, 15);

                    //CaseShare -> Share the case for Reseller
                    groupNameREAD = SC_Jarvis_CaseUpdate_Batch2.prepareGroupName('JA_' +childAccount + '_'+ parentAccount + '_R');
                    groupNameWRITE = SC_Jarvis_CaseUpdate_Batch2.prepareGroupName('JA_' +childAccount + '_'+ parentAccount + '_W');
                    caseIdGroupNameMap_READ.put(eachCase.Id, groupNameREAD);
                    caseIdGroupNameMap_WRITE.put(eachCase.Id, groupNameWRITE);

                }
                else if(eachCase.Indirect_Customer__c == null && eachCase.ContactId != null && eachCase.Contact.AccountId != eachCase.AccountId){
                    eachCase.Community_Sharing_Set_Account_Lookup__c = null;
                    eachCase.Created_By_Account__c = eachCase.Contact.AccountId;

                    //CaseShare
                    childAccount = String.valueOf(eachCase.AccountId).substring(0, 15);
                    parentAccount = String.valueOf(eachCase.Contact.AccountId).substring(0, 15);

                    //CaseShare -> Share the case for Reseller
                    groupNameREAD = SC_Jarvis_CaseUpdate_Batch2.prepareGroupName('JA_' +childAccount + '_'+ parentAccount + '_R');
                    groupNameWRITE = SC_Jarvis_CaseUpdate_Batch2.prepareGroupName('JA_' +childAccount + '_'+ parentAccount + '_W');
                    caseIdGroupNameMap_READ.put(eachCase.Id, groupNameREAD);
                    caseIdGroupNameMap_WRITE.put(eachCase.Id, groupNameWRITE);


                }
                else {
                    //All the Direct Customer Cases will be proceesed here
                    //Read Access
                    eachCase.Community_Sharing_Set_Account_Lookup__c = eachCase.AccountId;
                    eachCase.Created_By_Account__c = eachCase.AccountId;

                    //CaseShare
                    groupNameWRITE = SC_Jarvis_CaseUpdate_Batch2.prepareGroupName('JARVIS_ACCOUNT' +eachCase.Account.AKAM_Account_Id__c);
                    caseIdGroupNameMap_WRITE.put(eachCase.Id, groupNameWRITE);

                    //Community Comments Share
                    caseIdAccountIdMap.put(eachCase.Id, eachCase.Community_Sharing_Set_Account_Lookup__c);

                }

                caseListForUpdate.add(eachCase);
            }

            Update caseListForUpdate;


            if(caseIds.size() > 0){
                List<CaseShare> caseShareInsertList = new List<CaseShare>();
                List<Community_Comments__Share> commentShareList = new List<Community_Comments__Share>();
                // Tasks which are created before Limited Beta Go Live date
                DateTime considerationDate = (System.Test.isRunningTest()) ? system.now().addDays(1) : Datetime.newInstanceGmt(2021, 09, 28, 01, 15, 00);

                list<task> taskCommentsList = [SELECT Id, Whoid, Whatid, Description, Createddate FROM Task WHERE Type__c='Web Update' AND Createddate < :considerationDate AND Whatid in :caseIds];
                Map<id,id> contactidUseridmap = new map<id,id>();

                for(task eachtask : taskCommentsList){
                    contactIds.add(eachtask.Whoid);
                }
                //To Populate Created By User
                for(User eachUser : [SELECT Id,Contactid FROM User WHERE contactid IN :contactids]){
                    contactidUseridmap.put(eachUser.contactid, eachUser.id);
                }
                List<Community_Comments__c> communityCommentsList = new List<Community_Comments__c>();
                Community_Comments__c newcomment;

                for(task eachTask : taskCommentsList){
                    newcomment = new Community_Comments__c();
                    newcomment.Parent_ID__c=eachtask.Whatid;
                    newcomment.Contact__c=eachTask.Whoid;
                    newcomment.Visibility__c='Public';
                    newcomment.Commented_By__c='Customer';
                    newcomment.Comment__c=eachtask.Description;
                    newcomment.Application__c ='JARVIS';
                    newcomment.Related_Object__c='Case';
                    newcomment.AKAM_Created_Date__c=eachTask.createddate;
                    newcomment.AKAM_Modified_Date__c=eachTask.createddate;

                    //Share the Comment only if the case is from Direct Customer
                    if(caseIdAccountIdMap.containsKey(eachtask.Whatid))
                        newcomment.Account_ID_for_Community_Share__c = caseIdAccountIdMap.get(eachtask.Whatid);

                    newcomment.Skip_Email_Notification__c = True;

                    if(contactidUseridmap.containsKey(eachTask.Whoid)){
                        newcomment.AKAM_Created_By__c=contactidUseridmap.get(eachTask.Whoid);
                    }
                    else
                            newcomment.AKAM_Created_By__c=userinfo.getUserId();

                    communityCommentslist.add(newcomment);
                }
                if(communityCommentslist.size() > 0)
                    Insert communityCommentslist;

                Map<String, Id> groupNameIdMap = new Map<String, Id>();
                For(Group eachGroup : [SELECT Id, Name FROM Group WHERE (Name In :caseIdGroupNameMap_READ.values()) OR (Name In :caseIdGroupNameMap_WRITE.values())]){
                    groupNameIdMap.put(eachGroup.Name, eachGroup.Id);
                }

                CaseShare caseShareRec;
                For(Id eachCaseId : caseIdGroupNameMap_WRITE.keySet()){
                    if(groupNameIdMap.containsKey(caseIdGroupNameMap_WRITE.get(eachCaseId))){
                        caseShareRec = new CaseShare();
                        caseShareRec.CaseId = eachCaseId;
                        caseShareRec.RowCause = 'Manual';
                        caseShareRec.CaseAccessLevel = 'Edit';
                        caseShareRec.UserOrGroupId = groupNameIdMap.get(caseIdGroupNameMap_WRITE.get(eachCaseId));
                        caseShareInsertList.add(caseShareRec);
                    }
                }

                For(Id eachCaseId : caseIdGroupNameMap_READ.keySet()){
                    if(groupNameIdMap.containsKey(caseIdGroupNameMap_READ.get(eachCaseId))){
                        caseShareRec = new CaseShare();
                        caseShareRec.CaseId = eachCaseId;
                        caseShareRec.RowCause = 'Manual';
                        caseShareRec.CaseAccessLevel = 'Read';
                        caseShareRec.UserOrGroupId = groupNameIdMap.get(caseIdGroupNameMap_READ.get(eachCaseId));
                        caseShareInsertList.add(caseShareRec);
                    }
                }

                Insert caseShareInsertList;

                /*Community_Comments__Share commentShare;
                Community_Comments__Share commentShare2;
                for(Community_Comments__c eachComment :communityCommentslist){
                    if(caseIdGroupNameMap_READ.containsKey(eachComment.Parent_ID__c) && groupNameIdMap.containsKey(caseIdGroupNameMap_READ.get(eachComment.Parent_ID__c))){
                        commentShare = new Community_Comments__Share();
                        commentShare.ParentId = eachComment.Id;
                        commentShare.RowCause = 'Manual';
                    	commentShare.AccessLevel  = 'Read';
                    	commentShare.UserOrGroupId = groupNameIdMap.get(caseIdGroupNameMap_READ.get(eachComment.Parent_ID__c));
                        commentShareList.add(commentShare);
                    }
                    if(caseIdGroupNameMap_WRITE.containsKey(eachComment.Parent_ID__c) && groupNameIdMap.containsKey(caseIdGroupNameMap_WRITE.get(eachComment.Parent_ID__c))){
                        commentShare2 = new Community_Comments__Share();
                        commentShare2.ParentId = eachComment.Id;
                        commentShare2.RowCause = 'Manual';
                    	commentShare2.AccessLevel  = 'Read';
                    	commentShare2.UserOrGroupId = groupNameIdMap.get(caseIdGroupNameMap_WRITE.get(eachComment.Parent_ID__c));
                        commentShareList.add(commentShare2);
                    }

                }*/

                /*if(commentShareList.size() > 0)
                    Insert commentShareList;*/


            }
        }
        Catch(Exception ex){
            errormsg = ex.getMessage() + '\n';
            Database.rollback(sp);
        }
        system.debug('--Vam--Error Message--'+ errormsg);

        return errormsg;
    }

    public static string populateAccountFieldsSOCC(List<Case> caseList){
        String errormsg = '';
        List<Case> caseListForUpdate = new List<Case>();
        Set<Id> contactIds = new Set<Id>();
        Set<Id> caseIds = new Set<Id>();
        Map<Id, Id> caseIdAccountIdMap = new Map<Id, Id>();
        Map<Id, String> caseIdGroupNameMap = new Map<Id, String>();

        Savepoint sp = Database.setSavepoint();
        try{
            For(Case eachCase : caseList){
                caseIdGroupNameMap.put(eachCase.Id, 'JARVIS_PD' + SC_Jarvis_CaseUpdate_Batch.convertToEighteen(eachCase.Policy_Domain__c));
                //If Akamai Contact Creates the CAse for customer
                if(eachCase.ContactID != null && eachCase.Contact.AccountID != null && eachCase.Contact.Account.Name.containsIgnoreCase('Akamai')){
                    eachCase.Created_By_Account__c = eachCase.AccountId;
                }
                //If  Contact's Account is different Case Account
                else if(eachCase.ContactID != null && eachCase.Contact.AccountID != null){
                    eachCase.Created_By_Account__c = eachCase.Contact.AccountId;
                }
                else
                        eachCase.Created_By_Account__c = eachCase.AccountId;
                caseIds.add(eachCase.Id);
                eachCase.Validation_Override__c = True;
                caseListForUpdate.add(eachCase);
            }

            Update caseListForUpdate;

            if(caseIds.size() > 0){
                List<CaseShare> caseShareInsertList = new List<CaseShare>();
                List<Community_Comments__share> commentShareInsertList =  new List<Community_Comments__share>();
                //No need of Date filter because Web Updates are not synced for SOCC Cases in Case trigger
                //DateTime considerationDate = (System.Test.isRunningTest()) ? system.now().addDays(1) : Datetime.newInstanceGmt(2021, 09, 28, 01, 15, 00);
                //list<task> taskCommentsList = [SELECT Id, Whoid, Whatid, Description, Createddate FROM Task WHERE Type__c='Web Update' AND Createddate < :considerationDate AND Whatid in :caseIds];
                list<task> taskCommentsList = [SELECT Id, Whoid, Whatid, Description, Createddate FROM Task WHERE Type__c='Web Update' AND Whatid in :caseIds];
                Map<id,id> contactidUseridmap = new map<id,id>();

                for(task eachtask : taskCommentsList){
                    contactIds.add(eachtask.Whoid);
                }

                for(User eachUser : [SELECT Id,Contactid FROM User WHERE contactid IN :contactids]){
                    contactidUseridmap.put(eachUser.contactid, eachUser.id);
                }
                List<Community_Comments__c> communityCommentsList = new List<Community_Comments__c>();
                Community_Comments__c newcomment;

                for(task eachTask : taskCommentsList){
                    newcomment = new Community_Comments__c();
                    newcomment.Parent_ID__c=eachtask.Whatid;
                    newcomment.Contact__c=eachTask.Whoid;
                    newcomment.Visibility__c='Public';
                    newcomment.Commented_By__c='Customer';
                    newcomment.Comment__c=eachtask.Description;
                    newcomment.Application__c ='JARVIS';
                    newcomment.Related_Object__c='Case';
                    newcomment.AKAM_Created_Date__c=eachTask.createddate;
                    newcomment.AKAM_Modified_Date__c=eachTask.createddate;
                    newcomment.Skip_Email_Notification__c = True;
                    //newcomment.Account_ID_for_Community_Share__c = caseIdAccountIdMap.get(eachtask.Whatid);

                    if(contactidUseridmap.containsKey(eachTask.Whoid)){
                        newcomment.AKAM_Created_By__c=contactidUseridmap.get(eachTask.Whoid);
                    }
                    else
                            newcomment.AKAM_Created_By__c=userinfo.getUserId();

                    communityCommentslist.add(newcomment);
                }
                if(communityCommentslist.size() > 0)
                    Insert communityCommentslist;

                Map<String, Id> groupNameIdMap = new Map<String, Id>();
                For(Group eachGroup : [SELECT Id, Name FROM Group WHERE Name In :caseIdGroupNameMap.values()]){
                    groupNameIdMap.put(eachGroup.Name, eachGroup.Id);
                }

                CaseShare caseShareRec;
                For(Case eachCase : caseListForUpdate){
                    if(caseIdGroupNameMap.containsKey(eachCase.Id) && groupNameIdMap.containsKey(caseIdGroupNameMap.get(eachCase.Id))){
                        caseShareRec = new CaseShare();
                        caseShareRec.CaseId = eachCase.Id;
                        caseShareRec.RowCause = 'Manual';
                        caseShareRec.CaseAccessLevel = 'Edit';
                        caseShareRec.UserOrGroupId = groupNameIdMap.get(caseIdGroupNameMap.get(eachCase.Id));
                        caseShareInsertList.add(caseShareRec);
                    }
                }

                Insert caseShareInsertList;

                /*Community_Comments__share commentsShareRec;
                for(Community_Comments__c eachComment : communityCommentslist){
                    if(caseIdGroupNameMap.containsKey(eachComment.Parent_ID__c) && groupNameIdMap.containsKey(caseIdGroupNameMap.get(eachComment.Parent_ID__c))){
                        commentsShareRec = new Community_Comments__share();
                        commentsShareRec.ParentId = eachComment.Id;
                        commentsShareRec.RowCause = 'Manual';
                        commentsShareRec.AccessLevel = 'Read';
                        commentsShareRec.UserOrGroupId = groupNameIdMap.get(caseIdGroupNameMap.get(eachComment.Parent_ID__c));
                        commentShareInsertList.add(commentsShareRec);
                    }
                }

                Insert commentShareInsertList;*/
            }
        }
        Catch(Exception ex){
            errormsg = ex.getMessage() + '\n';
            Database.rollback(sp);
        }
        system.debug('--Vam--Error Message--'+ errormsg);
        return errormsg;



    }







    public static String prepareGroupName(String groupName)
    {
        return groupName != null && groupName.contains('-')? groupName.replaceAll('-','_') : groupName;
    }

    public static String convertToEighteen(String recordId)
    {
        String idStr = recordId;   // 15 character id
        Id idval = idStr;                   // assign to ID variable
        idStr = idval;                      // back to string to prove the point
        return idStr;
    }

    public void sendEmailforException(String ErrorMsg){
        String errorMessage = 	'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '\n' +
                'Batch Class Name = SC_Jarvis_CaseUpdate_Batch2\n' +
                'Error Message =' + ErrorMsg;

        String[] toAdd = new String[] {};

        toAdd.add('vs@akamai.com');
        toAdd.add('shprasan@akamai.com');
        toAdd.add('jrathod@akamai.com');

        // Sending Email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAdd);
        mail.subject = 'Exception: In Batch Job - SC_Jarvis_CaseUpdate_Batch2';
        mail.plainTextBody = errorMessage;
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
    }

}