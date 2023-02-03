/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
@isTest(seeAllData=true)
private class ScheduleAutoFollowTest {

    static testMethod void myUnitTest() {
        test.startTest();
           // utilTestClass.createCustomSettings();
            Account a = new Account();
            a.Name = 'Test Account1';
            insert a;
            
            Account a1 = new Account();
            a1.Name = 'Test Account Two';
            insert a1;
            
            //SlaProcess sla = [select Id from SlaProcess where Name = 'Priority' OR 
                           //   Name = 'Premium' OR Name = 'priority' OR Name = 'premium' limit 1];
            
            
            Entitlement ent = new Entitlement();
           // ent.SlaProcessId = sla.Id;
            ent.StartDate = Date.today().addDays(-2);
            ent.EndDate = Date.today().addDays(2);
            ent.AccountId = a1.Id;
            ent.Name = 'Premium - test';
            insert ent;
            
            ScheduleAutoFollow saf = new ScheduleAutoFollow();
            
            // run the test when no team members are present for Account or Opportunity             
            saf.autoFollowRecord();
            
            AccountTeamMember atm = new AccountTeamMember();
            atm.UserId = userinfo.getUserId();
            atm.AccountId = a.Id;
            atm.TeamMemberRole = 'Services - Secondary';
            insert atm;
            
            AccountTeamMember atm1 = new AccountTeamMember();
            atm1.UserId = userinfo.getUserId();
            atm1.AccountId = a1.Id;
            atm1.TeamMemberRole = 'Services - Primary';
            insert atm1;
            
            Case cs = new Case();
            cs.AccountId = a1.Id;
            cs.Severity__c = '1';
            cs.origin = 'Others';
            insert cs;
            
            EntitySubscription e = new EntitySubscription();
            e.ParentId = a.Id;
            e.SubscriberId = userinfo.getUserId();
            insert e;
            
            // run the test when team members are added for Account and Opportunity & when a record for EntitySubscription is already present i.e. user is already following that record
            saf.autoFollowRecord();
        
        
        // Schedule the test job
        String CRON_EXP = '0 0 0 * * ?';
        String jobId = System.schedule('testBasicScheduledApex', CRON_EXP, new ScheduleAutoFollow());
        
        // Get the information from the CronTrigger API object  
        CronTrigger ct = [SELECT id, CronExpression, TimesTriggered, NextFireTime
                            FROM CronTrigger 
                            WHERE id = :jobId];
        
        // Verify the expressions are the same  
        System.assertEquals(CRON_EXP, ct.CronExpression);
    
        // Verify the job has not run  
        System.assertEquals(0, ct.TimesTriggered);
        
        test.stopTest();
        
       
                
    }
}