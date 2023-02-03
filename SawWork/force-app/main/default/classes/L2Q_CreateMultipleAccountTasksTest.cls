@isTest(seeAllData = false)
private class L2Q_CreateMultipleAccountTasksTest{
    static User dmlUser = new User(id=UserInfo.getUserId());

    static testmethod void SingleTaskCreation() {
        Test.startTest();
        List<Account> accList = new List<Account>();
        Account acc =  (Account)new SobjectBuilder(Account.sObjectType)
                        .eagerPopulate()
                        .put(Account.Type, 'Lead')
                        .create()
                        .getRecord();
        
        PageReference pageRef = Page.L2Q_CreateSingleAccountPlanTask;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('accountId', acc.Id);
        ApexPages.currentPage().getParameters().put('fromButton', 'singleACPRequest');
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(accList);
        L2Q_CreateMultipleAccountTasksController controllerObj = new L2Q_CreateMultipleAccountTasksController(stdSetController);
        PageReference returnRef = controllerObj.createTaskForSelectedAccounts();
        Test.stopTest();
    }

    static testmethod void BulkTaskCreation() {
        Test.startTest();
        List<Account> accList =  (List<Account>)new SobjectBuilder(Account.sObjectType)
                        .eagerPopulate()
                        .put(Account.Type, 'Lead')
                        .count(2)
                        .create()
                        .getRecords();
        
        PageReference pageRef = Page.L2Q_CreateSingleAccountPlanTask;
        Test.setCurrentPage(pageRef);
        List<Account> accList2 = new List<Account>();
        ApexPages.StandardSetController stdSetController = new ApexPages.StandardSetController(accList2);
        L2Q_CreateMultipleAccountTasksController controllerObj = new L2Q_CreateMultipleAccountTasksController(stdSetController);
        List<Id> listOfSelectedAccountIds = new List<Id>();
        listOfSelectedAccountIds.add(accList.get(0).Id);
        listOfSelectedAccountIds.add(accList.get(1).Id);
        controllerObj.listOfSelectedAccountIds = listOfSelectedAccountIds;
        PageReference returnRef = controllerObj.createTaskForSelectedAccounts();
        Test.stopTest();
    }
}