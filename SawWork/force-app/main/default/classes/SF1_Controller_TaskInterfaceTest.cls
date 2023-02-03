@isTest(seeAllData=false) 
public  class SF1_Controller_TaskInterfaceTest 
{
    public static User dmlUser = utilTestClass.getTestRunUser();
    static TestMethod void testGetTaskDetails()
    {        
        System.runAs(dmlUser) {
            new SobjectBuilder(Environment_Setup__c.sObjectType)
            .put(Environment_Setup__c.Environment_Type__c, 'Primary')
            .put(Environment_Setup__c.Active_Org__c, true)
            .put(Environment_Setup__c.Akam_Id_Start_String__c, 'F-')
            .create();
            
            List<SCUserIdCustomSetting__c> lSCUserIds = new List<SCUserIdCustomSetting__c>();
            SCUserIdCustomSetting__c lunaUserID = new SCUserIdCustomSetting__c();
            lunaUserID.Name = 'LunaCaseMgmtUserID';
            lunaUserID.UserId__c = '005G0000003dnrRIAQ';
            lSCUserIds.add(lunaUserID);
        
            SCUserIdCustomSetting__c pulsarUserID = new SCUserIdCustomSetting__c();
            pulsarUserID.Name = 'PulsarCaseMgmtUserID';
            pulsarUserID.UserId__c = '005m0000002HWFa';
            lSCUserIds.add(pulsarUserID);            
            Insert lSCUserIds;
        }
        
        Task tsk = new Task();
        tsk.Subject = 'Test-Task1234';
        tsk.Visibility__c = 'Customer';
        tsk.Type = 'Call';
        tsk.WhatId = '5000f00001BsM5qAAF';
        tsk.Is_Case_Related__c = true;
        
        tsk.Partner_Receipt_Status__c = 'Success Receipt Received';
        
        insert tsk;
        Task t  = [select Id,Description,WhatId from Task where OwnerId != null Limit 1];
        Test.startTest();
        String jsonText = SF1_Controller_TaskInterfaceClass.getTaskDetails(t.Id);
        System.assertEquals(jsonText.contains(t.WhatId), TRUE);
        
        Test.stopTest();
    }

    static TestMethod void testSubmitCommentbyUser()
    {
        User User1 = utilTestClass.CreateUser('FRAPPVR1', 'Sales Operations', 'Sales Operations'); 
        insert User1;
        System.runAs(dmlUser) {
        new SobjectBuilder(Environment_Setup__c.sObjectType)
        .put(Environment_Setup__c.Environment_Type__c, 'Primary')
        .put(Environment_Setup__c.Active_Org__c, true)
        .put(Environment_Setup__c.Akam_Id_Start_String__c, 'F-')
        .create();
        }
        
        Task tsk = new Task();
        tsk.Subject = 'Test-Task1234';
        tsk.Visibility__c = 'Customer';
        tsk.Type = 'Call';
        tsk.OwnerId = User1.id;
        tsk.Partner_Receipt_Status__c = 'Success Receipt Received';       
        insert tsk;
        Task t  = [select Id,Description,OwnerId from Task where OwnerId != null Limit 1];
        Test.startTest();
        User u = [Select id from User where IsActive = true limit 1];
        String jsonString ='[{"attributes":{"type":"User"},"Id":"'+u.Id+'"}]';
        SF1_Controller_TaskInterfaceClass.submitCommentbyUser(t.Id, t.OwnerId, 'new comment', jsonString);
       
        
        Test.stopTest();
    }
    
}