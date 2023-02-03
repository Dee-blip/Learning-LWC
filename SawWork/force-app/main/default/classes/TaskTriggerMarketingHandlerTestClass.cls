@isTest 
public class TaskTriggerMarketingHandlerTestClass {
    static User dmlUser = new User(id=UserInfo.getUserId());
    
    @testSetup static void setupData(){
        utilTestClass.insertCustomSettings();
        Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
        Test.loadData(globalDescribe.get('Q2O_Custom_Settings__c'), 'Q2O_Custom_Settings');
        Account acc = utilTestClass.CreateAccount('__Test Account');
        acc.Vertical__c = 'Gaming';
        acc.Sub_Vertical__c = 'Console Mfs';            
        insert acc;

        Contact con = utilTestClass.CreateContact('__Test Contact FirstName','__Test Contact LastName');
        con.AccountId = acc.Id; 
        con.Email = 'generictesting@generictester.com';
        System.runAs(dmlUser){
            insert con;
        }   
        Lead lead = utilTestClass.CreateLead();
        lead.Disposition__c = 'Existing Customer';
        lead.Associated_Contact__c = con.Id;
        lead.Product_line__c='Aura';    
        insert lead;
        System.debug('@@@@Lead'+lead);
    }
    static testMethod void taskInsertByISDC(){ 
        User ISDCUser = [Select Id,name from User where Name='ISDC Integration' limit 1][0];
        Lead l=[Select id from Lead limit 1];
        Test.startTest();
            system.runAs(ISDCUser){
                Task task = new Task();
                task.Subject='Skipped';
                task.Status = 'Completed';
                task.Task_Type__C = 'OM';
                task.Order_Approval_Type__c = 'CDN';
                task.Task_Validation_Override__c = true;
                insert task;
            }
           List<Task> t1=[Select Id, Status from Task limit 10];
            //System.assertNotEquals(t1, null);
        
            delete t1;
        Test.stopTest();
    }
}