//Created this class as part of SFDC-6469 
//author : Nagaraj Desai (nadesai)
//Related Test Class : L2Q_CreateMultipleAccountTasksTest

public class L2Q_CreateMultipleAccountTasksController {
    public List<Id> listOfSelectedAccountIds {get; set;}
    private String taskSubject;

    //The request for Account Plan Task Creation can be :
    //from related list Buttons Request_New_Account_Plan, Request_New_Account_Plan_Refresh on account : Single account, Single Task
    //from list view Button Request_New_Account_Plan : This button is used for creating bulk Account Plan Request tasks for selected accounts from Account list view
    public L2Q_CreateMultipleAccountTasksController(ApexPages.StandardSetController accountStandardContr) {
        listOfSelectedAccountIds = new List<Id>();
        String fromButton = ApexPages.currentPage().getParameters().get('fromButton');
        Boolean isMultipleAPTRequest = false;
        if(fromButton == null) { //The request is from list view Button Request_New_Account_Plan 
            isMultipleAPTRequest = true;
            List<Account> listOfSelectedAccounts = accountStandardContr.getSelected();
            for(Account eachAccount : listOfSelectedAccounts) {
                listOfSelectedAccountIds.add(eachAccount.Id);
            }
        }
        else { //The request is from related list Buttons Request_New_Account_Plan OR Request_New_Account_Plan_Refresh on account
            String objectId = ApexPages.currentPage().getParameters().get('accountId');
            if(objectId != null && objectId != '') {
                Id idValOfObjectId = Id.valueOf(objectId);
                if(Schema.Account.SObjectType == idValOfObjectId.getSobjectType()) {
                    listOfSelectedAccountIds.add(idValOfObjectId);
                }
            }
        }
        setTaskSubject(isMultipleAPTRequest, fromButton);
    }

    //This function determines the subject of thask/s that is/are going to be created
    private void setTaskSubject(Boolean isMultipleAPTRequest, String fromButton) {
        List<String> taskSubjectsList = GsmUtilClass.getGSMSettingValue('taskSubjectMapForAccountPlanRequest').split(',');
        if(isMultipleAPTRequest || fromButton == 'singleACPRequest') {
            taskSubject = taskSubjectsList.get(0);
        } else if(fromButton == 'singleACPRequest_Refresh') {
            taskSubject = taskSubjectsList.get(1);
        }
    }
    
    private String getRequiredMessage(String initialMessage) {
        return initialMessage.replaceAll('#TaskSubject#', taskSubject);
    }
    //Create Task/s only if there is no open task of the same kind on repective account/s
    public PageReference createTaskForSelectedAccounts() {
        //SFDC-7354
        String requestNewAccountPlanAccess = GsmUtilClass.getGSMSettingValue('RequestNewAccountPlanAccess');
        if(!requestNewAccountPlanAccess.contains(UserInfo.getProfileId())){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.WARNING,GsmUtilClass.getGSMSettingValue('RequestNewAccountPlanWarningMsg')));
            return null;
        }
        if(listOfSelectedAccountIds.size() > 0) {
            Map<Id, Account> mapOfSelectedAccounts = new Map<Id, Account>([SELECT Id, OwnerId FROM Account WHERE Id =:listOfSelectedAccountIds]);
            
            for(Task eachExistingTask : [SELECT Id, WhatId FROM Task WHERE WhatId =:listOfSelectedAccountIds AND Subject LIKE :taskSubject AND IsClosed = false]) {
                if(mapOfSelectedAccounts.containsKey(eachExistingTask.WhatId)) {
                    mapOfSelectedAccounts.remove(eachExistingTask.WhatId);
                }
            }
            
            List<Task> listOfTasksToCreate = new List<Task>();
            
            for(Account eachAccount : mapOfSelectedAccounts.values()) {
                Task eachTask = new Task();
                eachTask.Priority = 'Normal';
                eachTask.Subject = taskSubject;
                eachTask.ActivityDate = Date.today().addDays(7);//metadata?
                eachTask.WhatId = eachAccount.Id;
                eachTask.OwnerId = eachAccount.OwnerId;
                listOfTasksToCreate.add(eachTask);
            }
            
            if(listOfTasksToCreate.size() > 0) {
                    List<Database.SaveResult> listOfDbResult = DataBase.insert(listOfTasksToCreate, false);
                    List<Error_Log__c> listOfErrorLogs = new List<Error_Log__c>();
                    String errorMessage = '';
                    for(Database.SaveResult eachDbResult : listOfDbResult) {
                        if(!eachDbResult.isSuccess()) {
                            for(Database.Error eachError : eachDbResult.getErrors()) {
                                Error_Log__c el = new Error_Log__c(Name = 'createTaskForSelectedAccounts', Class__c = 'L2Q_CreateMultipleAccountTasksController', Error_Message__c = eachError.getMessage());
                                errorMessage += eachError.getMessage() + '\n';
                                listOfErrorLogs.add(el);
                            }
                        }
                    }
                    if(listOfErrorLogs.size() == 0) {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.CONFIRM, getRequiredMessage(GsmUtilClass.getGSMSettingValue('BulkAccountPlanCreation_SuccessMessage'))));
                    }
                    else {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, errorMessage));
                        insert listOfErrorLogs;
                    }
            }
            else {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, getRequiredMessage(GsmUtilClass.getGSMSettingValue('BulkAccountPlanCreation_ErrorMessage1'))));
            }
            
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, getRequiredMessage(GsmUtilClass.getGSMSettingValue('BulkAccountPlanCreation_ErrorMessage2'))));
        }
        return null;
    }
    
}