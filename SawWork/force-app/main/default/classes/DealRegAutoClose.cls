/**
  * Initial Version:  Class is used by the cron Job which automatically changes the sales process to close Admin 
  *                  After a certain period of time and notify the PAE if the dateis  passed by 14 days for the 
  *                  Deal reg Submitted Record Type

**/
public class DealRegAutoClose{

    public List<String> errorString ;
    
    public String DealClose(String recordType, Integer noOfDays , Boolean EmailFlag){
        
        String res ='0:';
        List<opportunity> UpdateopptyList = new   List<opportunity>();
        Messaging.SingleEmailMessage[] sendEmailList = new List<Messaging.SingleEmailMessage>();
        Messaging.SendEmailResult[] sendEmailResultList = new List<Messaging.SendEmailResult>();
        errorString = new List<String>();

        try{
            date PastDate = system.today().addDays(-(noOfDays));
            date PastEndDate = PastDate -30; 
            Boolean errorExists = false;
            Integer errorCount = 0;
            Integer successCount = 0;
            String opportunityURL;
            String baseUrl;
            Integer count;


            //Added the Close Date between clause to avoid the Query index error
            List<String> oppStage = new List<String>{'Closed Lost',
                                                      'Closed Admin', 
                                                      'Closed Duplicate',
                                                      'Closed Contract Ended',
                                                      'Closed Lost'};

            //Adding RecordTypeID to replace recordType name with ID to avoid Query index error- CR 3081351
            Id recordTypeID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get(recordType).getRecordTypeId();
            List<Opportunity> listOfOpportunities = [Select Id,Name ,closeDate, StageName ,Channel_Manager__r.PAE_ID__c, Validation_Override__c From opportunity Where RecordTypeId =: recordTypeID And Closedate <= :PastDate AND CloseDate >= :PastEndDate AND StageName NOT IN :oppStage];
            
            for( opportunity oppty :listOfOpportunities) {
                System.Debug('AGH_DEBUG: picked up');
                
                if (EmailFlag != true ) {
                  oppty.StageName = 'Closed Admin';
                  oppty.Validation_Override__c = true;
                  UpdateopptyList.add(oppty);
                } else {
                  if(oppty.closeDate == PastDate )
                    sendEmailList.add(createSingleEmail(oppty.id , oppty.Channel_Manager__r.PAE_ID__c));
                }
            } 

            if(UpdateopptyList != null && !UpdateopptyList.isEmpty() ){
               
               List<Database.SaveResult> saveList = Database.update(UpdateopptyList , False);
               
               if(saveList != null && !saveList.isEmpty()){
                   res = '';
                   count = 0;
                   
                   for(Database.SaveResult sr : saveList) {
                       if (!sr.isSuccess()) {
                           errorCount += 1;
                           errorExists = true;
                           res = res + '\n' + UpdateopptyList[count].Id + ' . The error was : ';
                           for(Database.error err: sr.getErrors() ){
                               res =  res +err.getMessage();
                           }

                         for(Database.Error err : sr.getErrors()) 
                          {      
                              //links for Opportunity and Opportunity Line Item
                              baseUrl = URL.getSalesforceBaseUrl().toExternalForm() + '/';
                              opportunityURL = '<a href="'+ baseUrl+ listOfOpportunities[count].ID +'">' + listOfOpportunities[count].Name + '</a>';           
                              errorString.add('<tr>' + '<td>'+ listOfOpportunities[count].ID +'</td>'+'<td>'+ opportunityURL +'</td>'+'<td>'+ err.getMessage() +'</td>' + '<td>' + err.getFields() +'</td>' + '</tr>');
                          }

                       } else{
                           successCount += 1;
                       }
                       count = count + 1;
                   }
               }
           } 


          String emailMessage = 'Your cron job for ' + recordType  + ' has finished.  It processed  ' + count + ' records.  Of which, '+ successCount + ' processed without any exceptions '+ 'thrown and '+ errorCount + ' records threw unhandled exceptions.';
          
          String tableBegin = '<table border="1" style="border-collapse:collapse;"cellpadding="10" cellspacing ="5"><tr><th>Opportunity ID</th><th>Opportunity Name</th><th>Error</th><th>Error Field</th></tr>';

          emailMessage = emailMessage + '<br/>' +tableBegin;

          if(errorExists)
          {
            for( String str : errorString)
            {
               emailMessage = emailMessage +  str;
            }
            emailMessage = emailMessage + '</table>';
            sendMail(emailMessage);
          }

          if ( sendEmailList != null && !sendEmailList.isEmpty() ){

              sendEmailResultList = Messaging.sendEmail(sendEmailList, false);
              
              for(Messaging.SendEmailResult sr:sendEmailResultList){
                  if(!sr.isSuccess())
                  {
                      errorExists = true;
                      res += '\n Failed to send email for oppty : '+ sr.getErrors()[0].getTargetObjectId() + ' because of this error - '+ sr.getErrors()[0].getMessage();
                  }
              }
          }
          if(!errorExists) {
              res = '1: Job ran successfully. '+ successCount + ' opptys updated.';
          } else {
              res = '1: \n\n Number of successful oppty updates - ' + successCount + '\n Number of failed oppty updates - ' + errorCount + '\n\n The following errors occurred - \n \n' + res;
          }
          return res;

       } catch(Exception e) {
            res= '0:exception Found : '+e.getMessage() + '\n' + e.getCause()+'..'+e.getLineNumber()+'..'+e.getTypeName()+'..'+e.getStackTraceString() ;
        }
        return res;
    }
    
 
    public static Messaging.SingleEmailMessage createSingleEmail(Id oppid, Id UserId)
    {
        String templateId = GsmUtilClass.getGSMSettingValue('DealRegAutoClose_emailTemplate');
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setWhatId(oppid);
        mail.setTargetObjectId(UserId);        
        mail.setTemplateId(templateId);
        mail.setSaveAsActivity(false);
        return mail;
    }

    public static void sendMail(String message) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
         String emailAddresses = GsmUtilClass.getGSMSettingValue('DealRegAutoClose_ErrorMailId');
         System.debug('custom'+emailAddresses);
         String[] toAddresses = emailAddresses.split(',');
         System.debug('toaddresses'+toAddresses);
         mail.setToAddresses(toAddresses);
         mail.setReplyTo('noreply@salesforce.com');
         mail.setSenderDisplayName('Batch Job Summary');
         mail.setSubject('Deal Reg Auto Close job completed');
         mail.setPlainTextBody(message);
         mail.setHtmlBody(message);
         Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
    }
}