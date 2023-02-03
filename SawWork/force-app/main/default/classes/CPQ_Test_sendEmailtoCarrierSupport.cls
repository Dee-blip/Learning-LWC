/**
* This is the test class for the class for 
* CPQ_sendEmailtoCarrierSupport, CPQ_sendEmailtoCarrierSupportScheduler
* @author  Shashank Hegade
* @version 1.0
* @since   2020-05-18
*/

@isTest(seeAllData=false)
public class CPQ_Test_sendEmailtoCarrierSupport {
    @TestSetup
    static void makeData(){

        CPQ_TestDataFactory.createCustomSettings();
        
        new CPQ_TestDataFactory.CpqGenericCustomSettingBuilder('CarrierSupportEmail')
        .withValue('shegade@akamai.com')
        .withActive(true)
        .saveRecord();

        new CPQ_TestDataFactory.CpqGenericCustomSettingBuilder('EmailTemplateName')
        .withValue('CPQ stage 6 opportunity')
        .saveRecord();

        new CPQ_TestDataFactory.CpqGenericCustomSettingBuilder('addBCCaddress')
        .withActive(true)
        .saveRecord();

        new CPQ_TestDataFactory.CpqGenericCustomSettingBuilder('addCCaddress')
        .withValue('kimishra@akamai.com')
        .withActive(true)
        .saveRecord();

        //opportunityStageName
        new CPQ_TestDataFactory.CpqGenericCustomSettingBuilder('opportunityStageName')
        .withValue('6. Signed')
        .saveRecord();

        //SendAttachment
        new CPQ_TestDataFactory.CpqGenericCustomSettingBuilder('SendAttachment')
        .withActive(true)
        .saveRecord();

        //targetUserAlias
        new CPQ_TestDataFactory.CpqGenericCustomSettingBuilder('targetUserAlias')
        .withValue('CPQUSER')
        .saveRecord();

        new CPQ_TestDataFactory.CpqGenericCustomSettingBuilder('errorEmailsTo')
        .withValue('shegade@akamai.com')
        .saveRecord();
        
    }

    @IsTest
    static void testEmailNotification(){

        Opportunity oppObj = CPQ_TestDataFactory.createOpportunity(true);
        Order_Approval__c orderApprovalObj = CPQ_TestDataFactory.createOrderApproval(true, oppObj);
        SBQQ__Quote__c sampleQuote = CPQ_TestDataFactory.createQuote(false, oppObj);
        sampleQuote.CPQ_Primary__c = true;
        insert sampleQuote;
        
        sampleQuote.SBQQ__Status__c = 'Approved';
        sampleQuote.CPQ_Opportunity_Stage_name__c = '6. Signed';

        user testUser = [SELECT id FROM User where Alias  = 'SHEGADE'];
        sampleQuote.SBQQ__SalesRep__c = testUser.id;
        update sampleQuote;
 
        Test.startTest();
        CPQ_sendEmailtoCarrierSupport testCall = new CPQ_sendEmailtoCarrierSupport();
        Id jobid = System.enqueueJob(testCall);
        AsyncApexJob[] queueableCalls = [SELECT Id,JobType,MethodName FROM AsyncApexJob WHERE id =:jobid];
        Test.stopTest();

        SBQQ__Quote__c testQuote = [SELECT id,CPQ_Carrier_Support_Email_sent__c FROM SBQQ__Quote__c WHERE id =: sampleQuote.Id];

        System.assert(testQuote.CPQ_Carrier_Support_Email_sent__c == true, '-->Job can not be queued');
    
    }

    @isTest
    static void testScheduler(){

        Test.startTest();
        CPQ_sendEmailtoCarrierSupportScheduler m = new CPQ_sendEmailtoCarrierSupportScheduler();
        String sch = '0 30 * ? * *';
        String jobID = system.schedule('CPQ test job', sch, m);
        CronTrigger[] scheduledjobs = [SELECT Id, CronJobDetail.Id, CronJobDetail.Name, CronJobDetail.JobType FROM CronTrigger WHERE Id =:jobID];
        Test.stopTest();

        System.assert(scheduledjobs.size() == 1, '-->Job can not be scheduled');

    }

    @IsTest
    static void testException(){

        CPQ_Error_Log__c[] initialErrorCount = [SELECT Id, Type_Name__c FROM CPQ_Error_Log__c];
        //update the user alias to random value to create exception.
        CPQ_Generic_Settings__c userAlias = CPQ_Generic_Settings__c.getValues('targetUserAlias');
        userAlias.CPQ_Value__c = 'ZXCVBNM';
        update userAlias;
        
        Test.startTest();
        CPQ_sendEmailtoCarrierSupport testCall = new CPQ_sendEmailtoCarrierSupport();
        Id jobid = System.enqueueJob(testCall);
        Test.stopTest();

        CPQ_Error_Log__c[] finalErrorCount = [SELECT Id, Type_Name__c FROM CPQ_Error_Log__c];

        System.assert(finalErrorCount.size() > initialErrorCount.size(),'Error has been successfully logged');
        
    }

    @IsTest
    static void testDMLErrors(){

        SBQQ__Quote__c[] sampleQuotes = new List<SBQQ__Quote__c>();
        Opportunity[] sampleOppty = new List<Opportunity>();
        Order_Approval__c[] sampleOrderApp = new List<Order_Approval__c>();

        CPQ_Error_Log__c[] initialErrorCount = [SELECT Id, Type_Name__c FROM CPQ_Error_Log__c];

        sampleOppty.add(CPQ_TestDataFactory.createOpportunity(true));
        sampleOrderApp.add(CPQ_TestDataFactory.createOrderApproval(true, sampleOppty[0]));
        sampleQuotes.add(CPQ_TestDataFactory.createQuote(false, sampleOppty[0]));

        sampleOppty.add(CPQ_TestDataFactory.createOpportunity(true, sampleOppty[0].AccountID));
        sampleOrderApp.add(CPQ_TestDataFactory.createOrderApproval(true, sampleOppty[1]));
        sampleQuotes.add(CPQ_TestDataFactory.createQuote(false, sampleOppty[1]));

        insert sampleQuotes;

        user testUser = [SELECT id FROM User where Alias  = 'SHEGADE'];

        for(SBQQ__Quote__c sampleQuote: sampleQuotes){
            sampleQuote.SBQQ__Status__c = 'Approved';
            sampleQuote.CPQ_Opportunity_Stage_name__c = '6. Signed';
            sampleQuote.SBQQ__SalesRep__c = testUser.id;
        }

        update sampleQuotes;
        
        Test.startTest();
        CPQ_sendEmailtoCarrierSupport testCall = new CPQ_sendEmailtoCarrierSupport();
        Id jobid = System.enqueueJob(testCall);
        Test.stopTest();

        CPQ_Error_Log__c[] finalErrorCount = [SELECT Id, Type_Name__c FROM CPQ_Error_Log__c];
        System.assert(finalErrorCount.size() > initialErrorCount.size(),'Error has been successfully logged');

        
    }

}