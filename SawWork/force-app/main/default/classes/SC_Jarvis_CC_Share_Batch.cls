global class SC_Jarvis_CC_Share_Batch implements Database.Batchable<SObject>, Database.Stateful{

    String ccQuery;
    String ccQuery_Test;
    String errorMessage = '';

    public SC_Jarvis_CC_Share_Batch(){
        ccQuery = 'SELECT Id, Account_ID_for_Community_Share__c, Validation_Override__c, Skip_Email_Notification__c, Parent_ID__c FROM Community_Comments__c '+
                'WHERE Application__c = \'JARVIS\' and Parent_ID__c != null AND Parent_ID__c like \'500%\'';
        ccQuery_Test = ccQuery + ' LIMIT 10';
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
        //Check whether its a test class execution or normal execution
        String batchQuery = (System.Test.isRunningTest()) ? ccQuery_Test : ccQuery;
        if (batchQuery != null) {
            return Database.getQueryLocator(batchQuery);
        } else {
            return null;
        }
    }



    global void execute(Database.BatchableContext BC, List<SObject> scope){
        List<Community_Comments__c> qualifiedCCList = (Community_Comments__c[]) scope;
        errorMessage += ShareCCRecords(qualifiedCCList);
    }

    global void finish(Database.BatchableContext BC){
        if(errorMessage.length() > 5){
            sendEmailforException(errorMessage);
        }
    }


    public String ShareCCRecords(List<Community_Comments__c> commentList){
        String errormsg = '';
        Map<Id, List<Id>> caseIdGroupMap = new Map<Id, List<Id>>();
        Map<Id, Id> caseIdAccountSharingId = new Map<Id, Id>();

        for(Community_Comments__c eachComment : commentList){
            if(!caseIdGroupMap.containsKey(eachComment.Parent_ID__c)){
                caseIdGroupMap.put(eachComment.Parent_ID__c, new List<Id>());
            }
        }

        for(Case eachCase : [SELECT Id, Community_Sharing_Set_Account_Lookup__c FROM Case WHERE Id IN :caseIdGroupMap.keySet() AND Community_Sharing_Set_Account_Lookup__c != NULL]){
            caseIdAccountSharingId.put(eachCase.Id, eachCase.Community_Sharing_Set_Account_Lookup__c);
        }

        for(CaseShare eachCaseShare : [SELECT CaseId, UserOrGroupId FROM CaseShare WHERE CaseId IN :caseIdGroupMap.keySet() AND RowCause = 'Manual' AND UserOrGroup.Name LIKE 'JA%' ]){
            caseIdGroupMap.get(eachCaseShare.CaseId).add(eachCaseShare.UserOrGroupId);
        }

        List<Community_Comments__Share> shareListToInsert = new List<Community_Comments__Share>();
        List<Community_Comments__c> ccListToUpdate = new List<Community_Comments__c>();

        //Creating Savepoint
        Savepoint sp = Database.setSavepoint();
        try{

            for(Community_Comments__c eachComment : commentList){
                //If Community Sharing Set Account is Different
                Id accountID = caseIdAccountSharingId.get(eachComment.Parent_ID__c);
                if(eachComment.Account_ID_for_Community_Share__c != accountID){
                    eachComment.Account_ID_for_Community_Share__c = accountID;
                    eachComment.Validation_Override__c = true;
                    eachComment.Skip_Email_Notification__c = true;
                    ccListToUpdate.add(eachComment);
                }

                Community_Comments__Share shareRecord;
                for(Id eachgroupId : caseIdGroupMap.get(eachComment.Parent_ID__c)){
                    shareRecord = new Community_Comments__Share();
                    shareRecord.ParentId = eachComment.Id;
                    shareRecord.UserOrGroupId = eachgroupId;
                    shareRecord.RowCause = 'Manual';
                    shareRecord.AccessLevel = 'Read';
                    shareListToInsert.add(shareRecord);
                }
            }

            if(ccListToUpdate.size() > 0){
                update ccListToUpdate;
            }

            if (shareListToInsert.size() > 0) {
                insert shareListToInsert;
            }
        }
        catch(Exception ex){
            errormsg = ex.getMessage() + '\n';
            Database.rollback(sp);
        }
        System.debug('--Vam--Error Message--'+ errormsg);

        return errormsg;

    }

    public void sendEmailforException(String ErrorMsg){
        String errorMessage = 	'Instance = ' + Url.getSalesforceBaseUrl().toExternalForm() + '\n' +
                'Batch Class Name = SC_Jarvis_CC_Share_Batch\n' +
                'Error Message =' + ErrorMsg;

        String[] toAdd = new String[] {};

//        toAdd.add('vs@akamai.com');
//        toAdd.add('shprasan@akamai.com');
        toAdd.add('jrathod@akamai.com');

        // Sending Email
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setToAddresses(toAdd);
        mail.subject = 'Exception: In Batch Job - SC_Jarvis_CC_Share_Batch';
        mail.plainTextBody = errorMessage;
        Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
    }

}