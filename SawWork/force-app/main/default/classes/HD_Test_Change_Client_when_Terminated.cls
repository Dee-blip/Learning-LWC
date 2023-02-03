/*
* File Name: HD_Test_Change_Client_when_Terminated
* @author : Amogh M P
* Classes associated : HD_Change_Client_when_Terminated, HD_Change_Client_Terminated_Scheduler, UserTestHelper
*/

@isTest(SeeAllData = false)
public class HD_Test_Change_Client_when_Terminated {
	
    public static testMethod void testschedule() {

        Boolean cf = FALSE;
        User managerBuild = new UserTestHelper.UserBuilder()
            .withFirstName('Test')
            .withLastName('User1')
            .withUserName('test.user1@akamai.com')
            .withEmail('test.user1@akamai.com')
            .withAlias('man')
            .withConfidentialDataFlag(cf)
            .build();
        
        User manager = new UserTestHelper.UserBuilder(managerBuild)
            .buildAndSave();
        
        User normalUser = new UserTestHelper.UserBuilder()
            .withFirstName('Test')
            .withLastName('User2')
            .withUserName('test.user2@akamai.com')
            .withEmail('test.user2@akamai.com')
            .withAlias('cli')
            .withManager(manager.Id)
            .withConfidentialDataFlag(cf)
            .buildAndSave();
        
        User terminator = new UserTestHelper.UserBuilder()
            .withFirstName('Test')
            .withLastName('User3')
            .withUserName('test.user3@akamai.com')
            .withEmail('test.user3@akamai.com')
            .withAlias('ter')
            .withConfidentialDataFlag(cf)
            .buildAndSave();
        
        HD_IncidentTestDataFactory testinc1 = new HD_IncidentTestDataFactory();
        BMCServiceDesk__Incident__c inc1 = new BMCServiceDesk__Incident__c();
        BMCServiceDesk__Incident__c incTest = new BMCServiceDesk__Incident__c();
        System.runAs(normalUser){
        	inc1 = testinc1.getIncidentTestData(HD_IncidentTestDataFactory.Team.CORPIT);
            incTest = [Select Id, BMCServiceDesk__FKClient__c, BMCServiceDesk__FKCategory__c, HD_IncidentGroup__c, HD_Parent_Tree__c from BMCServiceDesk__Incident__c where Id = :inc1.Id LIMIT 1];
            incTest.HD_IncidentGroup__c = 'Q_HELPDESK_HARDWARE';
            update(incTest);
        }
        
        PSA_Settings__c workItemLimit;
        if(PSA_Settings__c.getInstance('Work Item Limit') == null)
        {
            workItemLimit = new PSA_Settings__c();
            workItemLimit.Name = 'Work Item Limit';
            workItemLimit.Value__c = '10';
        }
        insert workItemLimit;

        //User updatedUser = new User();
        System.runAs(terminator){
        	normalUser = new UserTestHelper.UserBuilder()
            	.inactivateUser(normalUser);
        }

        Test.startTest();
        HD_Change_Client_Terminated_Scheduler ccts = new HD_Change_Client_Terminated_Scheduler();
        String sch = '0 0 23 * * ?'; 
        System.schedule('HD Change Client', sch, ccts);
        Test.stopTest();
        
        BMCServiceDesk__Incident__c inc2 = new BMCServiceDesk__Incident__c();
        inc2 = [Select Id, BMCServiceDesk__FKClient__c from BMCServiceDesk__Incident__c where Id = :inc1.Id LIMIT 1];

        System.assertEquals(manager.Id, inc2.BMCServiceDesk__FKClient__c, 'Failed');
        
    }
}