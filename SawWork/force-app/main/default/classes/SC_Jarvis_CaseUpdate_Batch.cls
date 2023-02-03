/*
 * Limited Beta Customers
 * SC_Jarvis_CaseUpdate_Batch sc = new SC_Jarvis_CaseUpdate_Batch('\'AMG\',\'Technical\',\'Billing\',\'Professional Services\'','\'1-5QD3T\',\'F-AC-1756945\',\'EP-2LU\',\'AANA-5KM3QQ\',\'15Q-MPF\',\'1-6NDR1\',\'1-36NFAF\''); 
 * SC_Jarvis_CaseUpdate_Batch sc = new SC_Jarvis_CaseUpdate_Batch('\'Managed Security\'','\'1-5QD3T\',\'F-AC-1756945\',\'EP-2LU\',\'AANA-5KM3QQ\',\'15Q-MPF\',\'1-6NDR1\',\'1-36NFAF\'');

*/

Global class SC_Jarvis_CaseUpdate_Batch implements Database.Batchable<sObject>, Database.stateful{

	String caseQuery;
    
    Public string errorMessage = '' ;
    
    String caseQuery_Test;
    String recordType;
    Boolean isPartnerBatch = False;
    public SC_Jarvis_CaseUpdate_Batch(String recordTypeName, String AccountIdString, Boolean isPartner){
        String accountFilter;
        if(AccountIdString == null || AccountIdString == '')
            accountFilter = ' Account.Type LIKE \'%- Active%\' AND Created_By_Account__c = null ';
        else
            accountFilter = ' Created_By_Account__c = null AND Account.AKAM_Account_Id__c in ('+AccountIdString+') ';
        
        if(recordTypeName == 'Limited Beta'){
            recordType = 'Limited Beta';
            caseQuery = 'SELECT Id, AccountId, Contract_ID__c, Community_Sharing_Set_Account_Lookup__c, Case_Product__c, Created_By_Account__c, Contact.Accountid, Contact.Account.Name, Contact.Account.Akam_account_id__c, Indirect_Customer__c, Policy_Domain__c, Account.AKAM_Account_Id__c, RecordType.Name, IsClosed, Apply_Jarvis_Logic__c FROM Case '+
                'WHERE Do_Not_Show_in_Portal__c = False AND RecordType.Name in (\'Emerging Products Engineering\',\'Billing\',\'Technical\',\'AMG\',\'Professional Services\') AND Account.AKAM_Account_Id__c in ('+AccountIdString+') ';
        }
		/*else if(recordTypeName == 'Managed Security'){
            recordType = 'Managed Security';
            DateTime considerationDate = System.now().addYears(-1);
			caseQuery = 'SELECT Id, AccountId, Community_Sharing_Set_Account_Lookup__c, Created_By_Account__c, Indirect_Customer__c, Policy_Domain__c, Account.AKAM_Account_Id__c, RecordType.Name, IsClosed FROM Case '+ 
                		' WHERE RecordType.Name in (\'Managed Security\')'+ 
            			' AND Do_Not_Show_in_Portal__c = False AND '+
            			 accountFilter + ' AND CreatedDate >='+considerationDate.format('yyyy-MM-dd\'T\'hh:mm:ss\'Z\'');
        }
        else{
            recordType = 'Others';
            caseQuery = 'SELECT Id, AccountId, Community_Sharing_Set_Account_Lookup__c, Created_By_Account__c, Indirect_Customer__c, Policy_Domain__c, Account.AKAM_Account_Id__c, RecordType.Name, IsClosed FROM Case WHERE RecordType.Name in ('+recordTypeName+')'+ 
            ' AND Do_Not_Show_in_Portal__c = False AND '+ accountFilter;
        }
        
        if(isPartner == True){
            isPartnerBatch = True;
           caseQuery = 'SELECT Id, AccountId, Community_Sharing_Set_Account_Lookup__c, Created_By_Account__c, Contact.Accountid, Contact.Account.Akam_account_id__c, Indirect_Customer__c, Policy_Domain__c, Account.AKAM_Account_Id__c, RecordType.Name, IsClosed, Apply_Jarvis_Logic__c FROM Case WHERE RecordType.Name in ('+recordTypeName+')'+ 
            ' AND Do_Not_Show_in_Portal__c = False AND Contact.Account.Akam_account_id__c = '+ AccountIdString + ' AND Account.Akam_account_id__c != '+ AccountIdString + ' AND Created_By_Account__c = null';
        }*/
        
        
       caseQuery_Test = 'SELECT Id, AccountId, Community_Sharing_Set_Account_Lookup__c, Created_By_Account__c, Indirect_Customer__c, Policy_Domain__c, Account.AKAM_Account_Id__c, RecordType.Name, IsClosed,Contract_ID__c,Case_Product__c,Contact.Accountid, Contact.Account.Name,Contact.Account.Akam_account_id__c,Apply_Jarvis_Logic__c FROM Case LIMIT 10';

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
            if(recordType == 'Limited Beta'){
                errorMessage += ProcessLimitedBetaAccountCases(qualifiedcaseList);
            }
            /*else if(recordType == 'Managed Security'){
                errorMessage +=  populateAccountFieldsSOCC(qualifiedcaseList, isPartnerBatch);
            }
            else{
            	errorMessage +=  populateAccountFields(qualifiedcaseList, isPartnerBatch);
                
            }*/
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
    
 
    
    /*public static string populateAccountFieldsSOCC(List<Case> caseList, Boolean isPartner){
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
                eachCase.Created_By_Account__c = eachCase.AccountId;
                caseIds.add(eachCase.Id);
                eachCase.Validation_Override__c = True;
                caseListForUpdate.add(eachCase);
            }
            
            Update caseListForUpdate;
            
            if(caseIds.size() > 0){
            List<CaseShare> caseShareInsertList = new List<CaseShare>();
            List<Community_Comments__share> commentShareInsertList =  new List<Community_Comments__share>();
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
            	caseShareRec = new CaseShare();
				caseShareRec.CaseId = eachCase.Id;
				caseShareRec.RowCause = 'Manual';
				caseShareRec.CaseAccessLevel = 'Edit';
				caseShareRec.UserOrGroupId = groupNameIdMap.get(caseIdGroupNameMap.get(eachCase.Id));
				caseShareInsertList.add(caseShareRec);
            }
            
            Insert caseShareInsertList;
            
            Community_Comments__share commentsShareRec;
            for(Community_Comments__c eachComment : communityCommentslist){
                commentsShareRec = new Community_Comments__share();
                commentsShareRec.ParentId = eachComment.Id;
                commentsShareRec.RowCause = 'Manual';
                commentsShareRec.AccessLevel = 'Read';
                commentsShareRec.UserOrGroupId = groupNameIdMap.get(caseIdGroupNameMap.get(eachComment.Parent_ID__c));
                commentShareInsertList.add(commentsShareRec);
            }
            
            Insert commentShareInsertList;
        }
        }
        Catch(Exception ex){
            errormsg = ex.getMessage() + '\n';
            Database.rollback(sp);
        }
        system.debug('--Vam--Error Message--'+ errormsg);
        return errormsg;
        
        
        
    }
    
    public static string populateAccountFields(List<Case> caseList, Boolean isPartner){
        
        String errormsg = '';
        List<Case> caseListForUpdate = new List<Case>();
        //Set<Id> caseIds = new Set<Id>();
        Set<Id> contactIds = new Set<Id>();
        Map<Id, Id> caseIdAccountIdMap = new Map<Id, Id>();
        Map<Id, String> caseIdGroupNameMap = new Map<Id, String>();
        
        //Creating Savepoint
        Savepoint sp = Database.setSavepoint();
        Try{
            For(Case eachCase : caseList){
                
                if(isPartner == False){
                    //For Read Access
                    eachCase.Community_Sharing_Set_Account_Lookup__c = eachCase.Indirect_Customer__c != null ? eachCase.Indirect_Customer__c : eachCase.AccountId;
                    
                    //For Edit Acccess
                    caseIdGroupNameMap.put(eachCase.Id, SC_Jarvis_CaseUpdate_Batch.prepareGroupName('JARVIS_ACCOUNT' + eachCase.Account.AKAM_Account_Id__c));
                    
                    caseIdAccountIdMap.put(eachCase.Id, eachCase.Community_Sharing_Set_Account_Lookup__c);
                    eachCase.Created_By_Account__c = eachCase.AccountId;
                }
                else {
                    eachCase.Community_Sharing_Set_Account_Lookup__c = eachCase.Contact.Accountid;
                    
                    caseIdGroupNameMap.put(eachCase.Id, SC_Jarvis_CaseUpdate_Batch.prepareGroupName('JARVIS_ACCOUNT' + eachCase.Contact.Account.AKAM_Account_Id__c));
                    caseIdAccountIdMap.put(eachCase.Id, eachCase.Community_Sharing_Set_Account_Lookup__c);
                    
                    eachCase.Created_By_Account__c = eachCase.Contact.Accountid;
                    
                    if(eachCase.IsClosed == False)
                        eachCase.Apply_Jarvis_Logic__c = True;
                    
                }
                eachCase.Validation_Override__c = True;
                
                caseListForUpdate.add(eachCase);
            }
            
            Update caseListForUpdate;
            
            
            if(caseIdAccountIdMap.size() > 0){
                List<CaseShare> caseShareInsertList = new List<CaseShare>();
                list<task> taskCommentsList = [SELECT Id, Whoid, Whatid, Description, Createddate FROM Task WHERE Type__c='Web Update' AND Whatid in :caseIdAccountIdMap.keySet()];
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
                For(Group eachGroup : [SELECT Id, Name FROM Group WHERE Name In :caseIdGroupNameMap.values()]){
                    groupNameIdMap.put(eachGroup.Name, eachGroup.Id);
                }
                
                CaseShare caseShareRec;
                For(Case eachCase : caseListForUpdate){
                    caseShareRec = new CaseShare();
                    caseShareRec.CaseId = eachCase.Id;
                    caseShareRec.RowCause = 'Manual';
                    caseShareRec.CaseAccessLevel = 'Edit';
                    caseShareRec.UserOrGroupId = groupNameIdMap.get(caseIdGroupNameMap.get(eachCase.Id));
                    caseShareInsertList.add(caseShareRec);
                }
                
                Insert caseShareInsertList;
            }
        }
        Catch(Exception ex){
            errormsg = ex.getMessage() + '\n';
            Database.rollback(sp);
        }
        system.debug('--Vam--Error Message--'+ errormsg);
        
        return errormsg;
    }*/
    
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
       						'Batch Class Name = SC_Jarvis_CaseUpdate_Batch\n' + 
                            'Error Message =' + ErrorMsg;
        
        String[] toAdd = new String[] {};
          
		toAdd.add('vs@akamai.com');
//        toAdd.add('shprasan@akamai.com');
        toAdd.add('jrathod@akamai.com');
            
	  	// Sending Email
   		Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setToAddresses(toAdd);
		mail.subject = 'Exception: In Batch Job - SC_Jarvis_CaseUpdate_Batch';
		mail.plainTextBody = errorMessage;
		Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail}); 
    }


    public static string ProcessLimitedBetaAccountCases(List<Case> caseList) {
        List<case> caseListToUpdate = new List<case>();
        List<CaseShare> CaseShareList = new List<CaseShare>();
        List<Id> caseIdList = new List<Id>();
        String childAccount, parentAccount, groupNameREAD, groupNameWRITE;
        Map<Id, Set<String>> caseIdGroupNamesMap = new Map<Id, Set<String>>();
        String errormsg = '';

        //Creating Savepoint
        Savepoint sp = Database.setSavepoint();
        Try {
            For (Case eachCase : caseList) {
                // Apply_Jarvis_Logic__c = False -> Cases Which are created Before Limited Beta Go Live
                // Apply_Jarvis_Logic__c = True -> If Record type is (AMG or Billing) or (Case_Product__c is Null)
                // Share the Case at the account level
                if (eachCase.Apply_Jarvis_Logic__c == False ||
                        (eachCase.Apply_Jarvis_Logic__c == True && (eachCase.RecordType.Name == 'AMG' || eachCase.RecordType.Name == 'Billing' || (eachCase.Case_Product__c == Null)))) {

                    caseIdGroupNamesMap.put(eachCase.Id, new Set<String>());


                    // If Indirect Customer field is populated Then its a reseller usecase
                    if (eachCase.Indirect_Customer__c != null && eachCase.AccountId != eachCase.Indirect_Customer__c) {
                        eachCase.Community_Sharing_Set_Account_Lookup__c = null;
                        eachCase.Created_By_Account__c = eachCase.AccountId;

                        childAccount = String.valueOf(eachCase.Indirect_Customer__c).substring(0, 15);
                        parentAccount = String.valueOf(eachCase.AccountId).substring(0, 15);

                        //CaseShare
                        groupNameREAD = SC_Jarvis_CaseUpdate_Batch.prepareGroupName('JA_' + childAccount + '_' + parentAccount + '_R');
                        groupNameWRITE = SC_Jarvis_CaseUpdate_Batch.prepareGroupName('JA_' + childAccount + '_' + parentAccount + '_W');

                        caseIdGroupNamesMap.get(eachCase.Id).add(groupNameREAD);
                        caseIdGroupNamesMap.get(eachCase.Id).add(groupNameWRITE);


                    }
                    //IF Contacts Account is Not same as Case Account -> Reseller User Case
                    //If Contacts Account contains Akamai -> Direct Customer Use Case
                    else if (eachCase.Indirect_Customer__c == null && eachCase.ContactId != null && eachCase.Contact.AccountId != eachCase.AccountId && (!eachCase.Contact.Account.Name.containsIgnoreCase('Akamai'))) {
                        eachCase.Community_Sharing_Set_Account_Lookup__c = null;
                        eachCase.Created_By_Account__c = eachCase.Contact.AccountId;
 
                        //CaseShare
                        childAccount = String.valueOf(eachCase.AccountId).substring(0, 15);
                        parentAccount = String.valueOf(eachCase.Contact.AccountId).substring(0, 15);

                        groupNameREAD = SC_Jarvis_CaseUpdate_Batch.prepareGroupName('JA_' + childAccount + '_' + parentAccount + '_R');
                        groupNameWRITE = SC_Jarvis_CaseUpdate_Batch.prepareGroupName('JA_' + childAccount + '_' + parentAccount + '_W');

                        caseIdGroupNamesMap.get(eachCase.Id).add(groupNameREAD);
                        caseIdGroupNamesMap.get(eachCase.Id).add(groupNameWRITE);

                    } else {
                        //Read Access
                        eachCase.Community_Sharing_Set_Account_Lookup__c = eachCase.AccountId;
                        eachCase.Created_By_Account__c = eachCase.AccountId;

                        //CaseShare
                        groupNameWRITE = SC_Jarvis_CaseUpdate_Batch.prepareGroupName('JARVIS_ACCOUNT' + eachCase.Account.AKAM_Account_Id__c);
                        caseIdGroupNamesMap.get(eachCase.Id).add(groupNameWRITE);
                    }

                }

                else {
                    eachCase.Community_Sharing_Set_Account_Lookup__c = null;
                    eachCase.Created_By_Account__c = eachCase.AccountId;
                    if (eachCase.Contract_ID__c != null) {
                        caseIdGroupNamesMap.put(eachCase.Id, new Set<String>());
                        For (String contractId : eachCase.Contract_ID__c.Split(',')) {
                            caseIdGroupNamesMap.get(eachCase.Id).add(SC_Jarvis_CaseUpdate_Batch.prepareGroupName('JARVIS_CONTRACT' + contractId + '_READ'));
                            caseIdGroupNamesMap.get(eachCase.Id).add(SC_Jarvis_CaseUpdate_Batch.prepareGroupName('JARVIS_CONTRACT' + contractId + '_WRITE'));
                        }

                    }

                }
                eachCase.Validation_Override__c = True;
                caseIdList.add(eachCase.Id);
                caseListToUpdate.add(eachCase);
            }
            Update caseListToUpdate;

            List<CaseShare> caseShareToDelete = new List<CaseShare>();
            For (CaseShare eachCaseShare : [SELECT CaseAccessLevel, CaseId, Id, RowCause, UserOrGroup.Name FROM CaseShare WHERE RowCause = 'Manual' AND CaseId in :caseIdList]) {
                if ((caseIdGroupNamesMap.containsKey(eachCaseShare.CaseId) && !caseIdGroupNamesMap.get(eachCaseShare.CaseId).contains(eachCaseShare.UserOrGroup.Name)) ||
                        !caseIdGroupNamesMap.containsKey(eachCaseShare.CaseId)) {

                    caseShareToDelete.add(eachCaseShare);
                }
            }

            Set<String> groupNames = new Set<String>();

            For (Id eachCaseID : caseIdGroupNamesMap.keySet()) {
                if (caseIdGroupNamesMap.get(eachCaseID).size() > 0) {
                    groupNames.addAll(caseIdGroupNamesMap.get(eachCaseID));
                }
            }

            Map<String, Id> groupNameToIdMap = new Map<String, Id>();
            For (Group groupRec : [Select Id, Name from Group where name in :groupNames]) {
                groupNameToIdMap.put(groupRec.Name, groupRec.Id);
            }

            List<CaseShare> caseShareToInsert = new List<CaseShare>();
            For (Id caseId : caseIdGroupNamesMap.keySet()) {
                For (String groupName : caseIdGroupNamesMap.get(caseId)) {
                    if (groupNameToIdMap.get(groupName) != null) {
                        caseShareToInsert.add(SC_Jarvis_utility.createCaseShare(caseId, groupNameToIdMap.get(groupName), groupName));
                    }
                }
            }

            if (caseShareToInsert.size() > 0){
                Insert caseShareToInsert;
            }
            if (caseShareToDelete.size() > 0){
                Delete caseShareToDelete;
            }

        } Catch (Exception ex) {
            errormsg = ex.getMessage() + '\n';
            Database.rollback(sp);
        }

        return errormsg;


    }
}