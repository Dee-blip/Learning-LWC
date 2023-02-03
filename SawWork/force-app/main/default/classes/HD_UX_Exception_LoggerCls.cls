//@Hemant barapatre
// Basic Exception handling utility for Staff Ux project
//
//
//
public class HD_UX_Exception_LoggerCls {

   //this method can be used to send execption email to respective individual or team	
   //
   @AuraEnabled
   public static void ExceptionEmailNotifier(String ErrorMsg)
   {
     try
     {
     Messaging.SingleEmailMessage mail=new Messaging.SingleEmailMessage();
     String[] toAddresses = new String[] {'hd-itsm-dev@akamai.com'};
     mail.setToAddresses(toAddresses);
     mail.setReplyTo('hbarapat@akamai.com');
     mail.setSenderDisplayName('Apex error message');
     mail.setSubject('Error from Org : ' + UserInfo.getOrganizationName());
     mail.setPlainTextBody(ErrorMsg);
     Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
      }
    catch(System.EmailException see)
    {
        system.debug('Exception[Class|HD_UX_Exception_LoggerCls:Method|ExceptionEmailNotifier] - '+see.getMessage());
        system.debug('StackTrace[Class|HD_UX_Exception_LoggerCls:Method|ExceptionEmailNotifier] - '+see.getStackTraceString());
    }
    catch(LimitException le)
    {
        system.debug('Exception[Class|HD_UX_Exception_LoggerCls:Method|ExceptionEmailNotifier] - '+le.getMessage());
        system.debug('StackTrace[Class|HD_UX_Exception_LoggerCls:Method|ExceptionEmailNotifier] - '+le.getStackTraceString());
    }
    catch(Exception e)
    {
     
        system.debug('Exception[Class|HD_UX_Exception_LoggerCls:Method|ExceptionEmailNotifier] - '+e.getMessage());
        system.debug('StackTrace[Class|HD_UX_Exception_LoggerCls:Method|ExceptionEmailNotifier] - '+e.getStackTraceString());
    }
       
   }//
    
@AuraEnabled
public static void logErrorRecord(string ErrorMsg,String Stacktrace,String IncidentId)
   {
     try
      {
        HD_Error_Log__c newErrorlog = new HD_Error_Log__c();
        newErrorlog.Error_Message__c = ErrorMsg;
        newErrorlog.Stack_trace__c = Stacktrace;
        newErrorlog.User__c = UserInfo.getUserId();
        newErrorlog.Error_Date__c = System.now();
        newErrorlog.Incident__c = IncidentId;
        system.debug('>>Before log insert');
        List<HD_Error_Log__c> newErrorlogList = new List<HD_Error_Log__c>();
        newErrorlogList.add(newErrorlog);
          Database.SaveResult[] sr = Database.insert(newErrorlogList,false);
        
        system.debug('>>'+sr[0].isSuccess()+' >>'+ sr[0].getId()); 
      }
       catch(DmlException de)
       {
        system.debug('Exception[Class|HD_UX_Exception_LoggerCls:Method|logErrorRecord] - '+de.getMessage());
        system.debug('StackTrace[Class|HD_UX_Exception_LoggerCls:Method|logErrorRecord] - '+de.getStackTraceString());
       }
       catch(Exception e)
       {
        system.debug('Exception[Class|HD_UX_Exception_LoggerCls:Method|logErrorRecord] - '+e.getMessage());
        system.debug('StackTrace[Class|HD_UX_Exception_LoggerCls:Method|logErrorRecord] - '+e.getStackTraceString());
       }
   }//

    
    
}//END