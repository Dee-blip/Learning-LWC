@isTest(seeAllData=false)
public class HD_Test_Ux_Extension_Logger {
        static testMethod void testLogger(){
        Test.startTest();
        String stacktrace = 'Exception in thread "main" java.lang.NullPointerException at com.example.myproject.Book.getTitle(Book.java:16) at com.example.myproject.Author.getBookTitles(Author.java:25)';
        stacktrace = stacktrace + 'at com.example.myproject.Bootstrap.main(Bootstrap.java:14) ExceptionEmailNotifier.Stacktrace';
		String error = 'validation error';
        HD_UX_Exception_LoggerCls.logErrorRecord(error,stacktrace,null);
        Test.stopTest();
        HD_Error_Log__c log = [select id,Error_Message__c from HD_Error_Log__c limit 1];
        
       
        System.assert(log != null);
        System.assertEquals(log.Error_Message__c,'validation error');
    }
    
    static testMethod void testExceptionEmailNotifier(){
        HD_UX_Exception_LoggerCls.ExceptionEmailNotifier('Some error occured');
    }
    
    
    
    
    
    
    
    
}