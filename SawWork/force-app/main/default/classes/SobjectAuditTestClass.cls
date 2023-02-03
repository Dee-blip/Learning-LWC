/**SobjectAuditTestClass
 * @description    This class contains unit tests for validating the behavior/functionality of SobjectAuditClass
 * @author         Chandra Mohan Lohani
 * 
   @Histroy 
   
     Date             Developer                 Description
   03/16/2011    Chandra Mohan Lohani       Created the test class and added following methods
                                            sobjectAuditClass_ScheduledJob_SingleTest_Positive
                                            sobjectAuditClass_CancelDeployment_SingleTest_Positive
                                            sobjectAuditClass_CancelDeployment_BulkTest_Positive
                                            sobjectAuditClass_DeploymentComplete_SingleTest_Positive
                                            sobjectAuditClass_DeploymentComplete_BulkTest_Positive
 */
@isTest
private class SobjectAuditTestClass {

    static testMethod void sobjectAuditClass_ScheduledJob_SingleTest_Positive() {
        // TO DO: implement unit test
        
        //Map<String, Schema.SObjectType> allObjectsMap = Schema.getGlobalDescribe();
        //Set<String> objectNames=allObjectsMap.keySet();
        //Integer objectCount=objectNames.size();
        //test.startTest();
        //SobjectAuditClass sobjectAudit=new SobjectAuditClass();
        //sobjectAudit.createAuditRecord();
        //Boolean emailSent=sobjectAudit.sendEmailNotifications();
        //test.stopTest();
        //List<Sobject_Backup_Audit__c> sobjectBackupList=[select Object_Name__c from Sobject_Backup_Audit__c where Object_Name__c IN :objectNames];
        //Integer backupObjectRecordCount=sobjectBackupList.size();
        //System.assertEquals(objectCount, backupObjectRecordCount);
        //System.assertEquals(emailSent,true);
    }
    
    static testMethod void sobjectAuditClass_CancelDeployment_SingleTest_Positive()
    {
        User defaultUser=[select Id from User where alias ='NARKUMAR'][0];
        String CRON_EXP = '0 0 0 * * ?';
        Sobject_Backup_Audit__c sobjectBackup=new Sobject_Backup_Audit__c();
        sobjectBackup.Object_Name__c='TestRecord#1';
        sobjectBackup.Status__c='Pending Review';
        sobjectBackup.Responsible__c=defaultUser.Id;
        sobjectBackup.Approver__c=defaultUser.Id;
        insert sobjectBackup;
        
        sobjectBackup.Status__c='Pending Approval';
        sobjectBackup.Reason__c='Review Complete';
        
        upsert sobjectBackup;
        
        sobjectBackup.status__c='Pending Deployment';
        sobjectBackup.Reason__c='Review Complete Approval complete';
        sobjectBackup.Backup__c=true;
        sobjectBackup.Change_Request__c='http:\\bugzilla.akamai.com';
        
        upsert sobjectbackup;
        
        sobjectBackup=[select Id from Sobject_Backup_Audit__c where Object_Name__c='TestRecord#1'][0];
        test.startTest();
        //Sonali -increasing code coverage
        System.schedule('test', CRON_EXP, new SobjectAuditClass());
        SobjectAuditClass.cancelDeployment(sobjectBackup.Id);
        test.stopTest();
        //refresh
        sobjectBackup=[Select Id,Status__c from Sobject_Backup_Audit__c where Object_Name__c ='TestRecord#1'][0];
        
        System.assertEquals(sobjectBackup.Status__c, 'Pending Review');
    }
    static testMethod void sobjectAuditClass_CancelDeployment_BulkTest_Positive()
    {
        User defaultUser=[select Id from User where alias ='NARKUMAR'][0];
        List<Sobject_Backup_Audit__c> sobjectBackupList=new List<Sobject_Backup_Audit__c>();
        Integer i=null;
        Set<String> objectNames=new Set<String>();
        for(i=0;i<2;i++)
        {
            Sobject_Backup_Audit__c sobjectBackup=new Sobject_Backup_Audit__c();
            sobjectBackup.Object_Name__c='TestRecord#'+i;
            sobjectBackup.Status__c='Pending Review';
            sobjectBackup.Responsible__c=defaultUser.Id;
            sobjectBackup.Approver__c=defaultUser.Id;
            sobjectBackupList.add(sobjectBackup);
            objectNames.add(sobjectBackup.Object_Name__c);
        }
        insert sobjectBackupList;
        for(i=0;i<2;i++)
        {
            sobjectBackupList[i].Status__c='Pending Approval';
            sobjectBackupList[i].Reason__c='Review Complete';
        }
        
        upsert sobjectBackupList;
        for(i=0;i<2;i++)
        {
            sobjectBackupList[i].status__c='Pending Deployment';
            sobjectBackupList[i].Reason__c='Review Complete Approval complete';
            sobjectBackupList[i].Backup__c=true;
            sobjectBackupList[i].Change_Request__c='http:\\bugzilla.akamai.com';
        }
        upsert sobjectBackupList;
        
        sobjectBackupList=[select Id from Sobject_Backup_Audit__c where Object_Name__c IN :objectNames];
        test.startTest();
        for(i=0;i<2;i++)
        {
            SobjectAuditClass.cancelDeployment(sobjectBackupList[i].Id);
        }
        test.stopTest();
        //refresh
        sobjectBackupList=[Select Id,Status__c from Sobject_Backup_Audit__c where Object_Name__c IN :objectNames];
        for(i=0;i<2;i++)
        {
            System.assertEquals(sobjectBackupList[i].Status__c, 'Pending Review');
        }
        
    }
    static testMethod void sobjectAuditClass_DeploymentComplete_SingleTest_Positive()
    {
        User defaultUser=[select Id from User where alias ='NARKUMAR'][0];
        Sobject_Backup_Audit__c sobjectBackup=new Sobject_Backup_Audit__c();
        sobjectBackup.Object_Name__c='TestRecord#1';
        sobjectBackup.Status__c='Pending Review';
        sobjectBackup.Responsible__c=defaultUser.Id;
        sobjectBackup.Approver__c=defaultUser.Id;
        insert sobjectBackup;
        
        sobjectBackup.Status__c='Pending Approval';
        sobjectBackup.Reason__c='Review Complete';
        
        upsert sobjectBackup;
        
        sobjectBackup.status__c='Pending Deployment';
        sobjectBackup.Reason__c='Review Complete Approval complete';
        sobjectBackup.Backup__c=true;
        sobjectBackup.Change_Request__c='http:\\bugzilla.akamai.com';
        
        upsert sobjectbackup;
        
        sobjectBackup=[select Id from Sobject_Backup_Audit__c where Object_Name__c='TestRecord#1'][0];
        test.startTest();
        
        SobjectAuditClass.deploymentComplete(sobjectBackup.Id);
        test.stopTest();
        //refresh
        sobjectBackup=[Select Id,Status__c from Sobject_Backup_Audit__c where Object_Name__c ='TestRecord#1'][0];
        
        System.assertEquals(sobjectBackup.Status__c, 'Approved');
    }
    static testMethod void sobjectAuditClass_DeploymentComplete_BulkTest_Positive()
    {
        User defaultUser=[select Id from User where alias ='NARKUMAR'][0];
        List<Sobject_Backup_Audit__c> sobjectBackupList=new List<Sobject_Backup_Audit__c>();
        Integer i=null;
        Set<String> objectNames=new Set<String>();
        for(i=0;i<2;i++)
        {
            Sobject_Backup_Audit__c sobjectBackup=new Sobject_Backup_Audit__c();
            sobjectBackup.Object_Name__c='TestRecord#'+i;
            sobjectBackup.Status__c='Pending Review';
            sobjectBackup.Responsible__c=defaultUser.Id;
            sobjectBackup.Approver__c=defaultUser.Id;
            sobjectBackupList.add(sobjectBackup);
            objectNames.add(sobjectBackup.Object_Name__c);
        }
        insert sobjectBackupList;
        for(i=0;i<2;i++)
        {
            sobjectBackupList[i].Status__c='Pending Approval';
            sobjectBackupList[i].Reason__c='Review Complete';
        }
        
        upsert sobjectBackupList;
        for(i=0;i<2;i++)
        {
            sobjectBackupList[i].status__c='Pending Deployment';
            sobjectBackupList[i].Reason__c='Review Complete Approval complete';
            sobjectBackupList[i].Backup__c=true;
            sobjectBackupList[i].Change_Request__c='http:\\bugzilla.akamai.com';
        }
        upsert sobjectBackupList;
        
        sobjectBackupList=[select Id from Sobject_Backup_Audit__c where Object_Name__c IN :objectNames];
        test.startTest();
        for(i=0;i<2;i++)
        {
            SobjectAuditClass.deploymentComplete(sobjectBackupList[i].Id);
        }
        test.stopTest();
        //refresh
        sobjectBackupList=[Select Id,Status__c from Sobject_Backup_Audit__c where Object_Name__c IN :objectNames];
        for(i=0;i<2;i++)
        {
            System.assertEquals(sobjectBackupList[i].Status__c, 'Approved');
        }
        
    }

    static testMethod void testBatchJobs()
    {
        Sobject_Backup_Audit_Field__c newSobjectAudit=new Sobject_Backup_Audit_Field__c();
        newSobjectAudit.Object_Name__c='Opportunity';
        newSobjectAudit.Field_Name__c='StageName';
        insert newSobjectAudit;

        delete newSobjectAudit;
        
        //String result = SObjectAuditClass.invokeSObjectAuditBackupRecordJob('CreateSobjectBackupAuditRecordJob-CreateAuditRecord');
        //result = SObjectAuditClass.invokeSObjectAuditBackupRecordJob('CreateSobjectBackupAuditRecordJob-SendEmailNotifications');
        //SObjectAuditClass.invokeSObjectAuditBackupFieldJob('CreateSobjectBackupAuditFieldJob-CreateAuditRecord');
        //SObjectAuditClass.fieldReportCreation();
    }
}