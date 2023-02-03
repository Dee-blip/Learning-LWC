/**
* Test class for the method CPQ_LogException, CPQ_CustomException
* @author  Shashank Hegade
* @version 1.0
* @since   2020-05-21
*/

@isTest(seeAllData=false)
public class CPQ_Test_ExceptionLogger {
    @TestSetup
    static void makeData(){
        
        new CPQ_TestDataFactory.CpqGenericCustomSettingBuilder('errorEmailsTo')
        .withValue('shegade@akamai.com')
        .saveRecord();

        new CPQ_TestDataFactory.CpqGenericCustomSettingBuilder('targetUserAlias')
        .withValue('CPQUSER')
        .saveRecord();
       
    }

    @IsTest
    static void testLogExcpetion(){
        
        Test.startTest();
        AsyncException e = new AsyncException('test error message 1');
        CPQ_LogException error = new CPQ_LogException('test error message 2',e);
        CPQ_Error_Log__c newError = error.createErrorRecord(true)
                                    .sendEmailtoDev()
                                    .getErrorRecord();
        Test.stopTest();
        
        CPQ_Error_Log__c[] testError = [SELECT id FROM CPQ_Error_Log__c WHERE id =:newError.id];

        System.assert(testError.size() > 0, 'could not create error record');
    }

    @IsTest
    static void testStaticExceptionLogger(){

        Test.startTest();
        CPQ_CustomException e = new CPQ_CustomException('test error message 1', CPQ_CustomException.StatusCode.PAC_ERROR);
        CPQ_LogException.add(new CPQ_LogException(e, e.getStatusCode())
                                    .setShortMessage('CPQ_Test_ExceptionLogger:testing the exception logger')
                                    .insertRecord()
                                    .getErrorRecord());
        CPQ_LogException.flush();
        List<CPQ_Error_Log__c> testList = CPQ_LogException.get();
        CPQ_LogException.clear();
        Test.stopTest();

        CPQ_Error_Log__c[] testError = [SELECT id FROM CPQ_Error_Log__c];
        System.assert(testError.size() > 0, 'could not create error record');

    }
}