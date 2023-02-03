/**
 * @Cretad by - Aayushi Agrawal 
 * @Purpose - to create html body for emails in Sawyer Alerting system
 * @Created date - 25 january
 */
public  class SawyerAlertHtmlCodeGeneration {
    String htmlBodyClosure = '</table>'; 
    String htmlBodyOpeningSawyer = '<table border="1" style="border-collapse: collapse"><caption><h2>Sawyer Lawgs  : </h2></caption><tr><th>Class</th><th>Method</th><th>Line Number</th><th>Message Text</th><th>Stack Trace</th></tr>';
    String htmlBodyOpeningMuleLogs = '<table border="1" style="border-collapse: collapse"><caption><h2>Mulesoft Polling Logs :</h2> </caption><tr><th>Fingerprint</th><th>Unique Key</th><th>Full Load Status</th><th>Last Successfull Run Time</th><th>Error</th></tr>';
    String htmlBodyOpeningCalloutLogs = '<table border="1" style="border-collapse: collapse"><caption><h2>Callout Logs : </h2></caption><tr><th>Fingerprint</th><th>Response Body</th><th>Response Status</th><th>Response Status Code</th><th>Request URI</th><th>Request Method</th></tr>';
    String htmlBodySawyerLogs = '';
    String htmlBodyMuleLog = '';
    String htmlBodyCalloutLog = '';
    Map<String,String> mapBeepToSawyerlogs = new Map<String,String>();
    Map<String,String> mapBeepToMuleLogs = new Map<String,String>();
    Map<String,String> mapBeepToCalloutLogs = new Map<String,String>();
    Beep__c beepRecord ; 
    String emailAddOfRecepient;
    
    /**
     * @Method name : getEmailBodyFromSawyerRecords
     * @Purpose - to collect errors from sawyer records on a given beep
     */
    private  String getEmailBodyFromSawyerRecords(){
        Set<String> tableBodySet = new Set<String>();
        List<SawedLawg__c> sawedLogsRecords = beepRecord.SawedLawgs__r;

        for(SawedLawg__c  log : sawedLogsRecords){
            string tempHtmlBody = '';  
            String myClass = log.Class__c; if(log.Class__c == null){myClass = '[Not Provided]';}
            String method = log.Method__c; if(log.Method__c == null){method = '[Not Provided]';}
            String lineNumber = log.Line_Number__c+''; if(log.Line_Number__c == null){lineNumber = '[Not Provided]';}
            String messageText = log.Message_Text__c; if(log.Message_Text__c == null){messageText = '[Not Provided]';}
            String stackTrace = log.Stack_Trace_Text__c; if(log.Stack_Trace_Text__c == null){stackTrace = '[Not Provided]';}

            tempHtmlBody += '<td><center>' + method + '</center></td>';
            tempHtmlBody += '<td><center>' + lineNumber + '</center></td><td><center>' + messageText + '</center></td>';
            tempHtmlBody += '<td><center>' + stackTrace + '</center></td>';
            if(!tableBodySet.contains(tempHtmlBody)){
                htmlBodySawyerLogs += '<tr><td><center><a href = '+URL.getSalesforceBaseUrl().toExternalForm() + '/' + log.Id+'>' + myClass + '</a></center></td>'+tempHtmlBody+'</tr>';
            }  
            tableBodySet.add(tempHtmlBody);
            
            //close table...
            
        }
        
        return htmlBodySawyerLogs;
    }//end of method getEmailBodyFromSawyerRecords

    /**
     * @Method name : getEmailFromMuleSoftPollingRec
     * @Purpose - to collect errors from mulesoft records on a given beep
     */
    private  String getEmailFromMuleSoftPollingRec(){
        Set<String> tableBodySet = new Set<String>();
        List<Mulesoft_Polling__c> muleSoftRecord = beepRecord.Mulesoft_Pollings__r;
        for(Mulesoft_Polling__c  log : muleSoftRecord){
            string tempHtmlBody = '';  
            String myclass = beepRecord.Fingerprint__c; if(beepRecord.Fingerprint__c == null){myclass = '[Not Provided]';}
            String uniqueKey = log.Unique_Key__c; if(log.Unique_Key__c == null){uniqueKey = '[Not Provided]';}
            String fullLoadStatus = log.FullLoadStatus__c+''; if(log.FullLoadStatus__c == null){FullLoadStatus = '[Not Provided]';}
            String lastSuccessfulRunTime = String.valueOf(log.LastSuccessfulRunTime__c); if(log.LastSuccessfulRunTime__c == null){LastSuccessfulRunTime = '[Not Provided]';}
            String error = log.Error__c; if(log.Error__c == null){Error = '[Not Provided]';}
            
            tempHtmlBody += '<td><center>' + uniqueKey + '</center></td>';
            tempHtmlBody += '<td><center>' + FullLoadStatus + '</center></td>';
            tempHtmlBody +=  '<td><center>' + LastSuccessfulRunTime + '</center></td>'+ '<td><center>' + Error + '</center></td>';
            if(!tableBodySet.contains(tempHtmlBody)){
                htmlBodyMuleLog += '<tr><td><center><a href = '+URL.getSalesforceBaseUrl().toExternalForm() + '/' + log.Id+'>' + myClass + '</a></center></td>'+tempHtmlBody+'</tr>';
            }  
            tableBodySet.add(tempHtmlBody);
            
            //close table...
            
        }
        
         return htmlBodyMuleLog;
    }// end of method getEmailFromMuleSoftPollingRec

    /**
     * @Method name : getEmailFromCalloutRec
     * @Purpose - to collect errors from callout records on a given beep
     */
    private  String getEmailFromCalloutRec( ){
        Set<String> tableBodySet = new Set<String>();
        List<Callout_Log__c> calloutRecords  = BeepRecord.Callout_Logs__r;
        for(Callout_Log__c  log : calloutRecords){
            string tempHtmlBody = '';  
            String myclass = beepRecord.Fingerprint__c; if(beepRecord.Fingerprint__c == null){myclass = '[Not Provided]';}
            String responseBody = log.Response_Body__c; if(log.Response_Body__c == null){ResponseBody = '[Not Provided]';}
            String responseStatus = log.Response_Status__c+''; if(log.Response_Status__c == null){ResponseStatus = '[Not Provided]';}
            String responseStatusCode = String.valueOf(log.Response_Status_Code__c); if(log.Response_Status_Code__c == null){ResponseStatusCode = '[Not Provided]';}
            String requestURI = log.Request_URI__c; if(log.Request_URI__c == null){RequestURI = '[Not Provided]';}
            String requestMethod = log.Request_Method__c+''; if(log.Request_Method__c == null){RequestMethod = '[Not Provided]';}
            
            tempHtmlBody += '<td>' + ResponseBody + '</center></td>';
            tempHtmlBody += '<td><center>' + ResponseStatus + '</center></td>'+'<td><center>' + ResponseStatusCode + '</center></td>'+'<td><center>' + RequestURI + '</center></td>'+'<td><center>' + RequestMethod + '</center></td>';
            if(!tableBodySet.contains(tempHtmlBody)){
                String temp = '<tr><td><center><a href = '+URL.getSalesforceBaseUrl().toExternalForm() + '/' + log.Id+'>' + myClass + '</a></center></td>'+tempHtmlBody+'</tr>';
                htmlBodyCalloutLog += temp;
            }  
            tableBodySet.add(tempHtmlBody);
            //close table...
        }
        return htmlBodyCalloutLog;
    }//end of method getEmailFromCalloutRec


    private void convertSawyerLogs(){
        //code for Sawyerlawgs conversion
        if(beepRecord.SawedLawgs__r.size() > 0){
            htmlBodySawyerLogs = ''; 
            //this part of code is where we check if already a email content exist for this email address.. if yes then it is merged
            if(mapBeepToSawyerlogs.containsKey(emailAddOfRecepient)){
                htmlBodySawyerLogs =  mapBeepToSawyerlogs.get(emailAddOfRecepient); 
            } 
            htmlBodySawyerLogs = getEmailBodyFromSawyerRecords();
            mapBeepToSawyerlogs.put(emailAddOfRecepient , htmlBodySawyerLogs);
            }// end of code for Sawyerlawgs conversion
    }// end of method convertSawyerLogs


    private  void convertMulesoftLogs(){
        //code for Sawyerlawgs conversion
        if(beepRecord.Mulesoft_Pollings__r.size() > 0){
            htmlBodyMuleLog = '';
            if(mapBeepToMuleLogs.containsKey(emailAddOfRecepient)){
                htmlBodyMuleLog =  mapBeepToMuleLogs.get(emailAddOfRecepient); 
            } 
            htmlBodyMuleLog = getEmailFromMuleSoftPollingRec();
            mapBeepToMuleLogs.put(emailAddOfRecepient , htmlBodyMuleLog);
        }// end of code for Sawyerlawgs conversion
    }// end of method convertMulesoftLogs

    private  void convertCalloutLogs(){
        //code for Sawyerlawgs conversion
        if(beepRecord.Callout_Logs__r.size() > 0){
            htmlBodyCalloutLog = '';
            if(mapBeepToCalloutLogs.containsKey(emailAddOfRecepient)){
                htmlBodyCalloutLog =  mapBeepToCalloutLogs.get(emailAddOfRecepient); 
            } 
            htmlBodyCalloutLog = getEmailFromCalloutRec();
            mapBeepToCalloutLogs.put(emailAddOfRecepient , htmlBodyCalloutLog);
            
        }// end of code for Sawyerlawgs conversion
    }//end of method convertCalloutLogs

    public   String mergeEmailLogs(String email){
        //Merging all three different email body in a single one
        
            String body = '';
            if(mapBeepToSawyerlogs.containsKey(email)){
                body = htmlBodyOpeningSawyer + mapBeepToSawyerlogs.get(email) + htmlBodyClosure;
            }
            if(mapBeepToMuleLogs.containsKey(email)){
                body += '</br></br>'+htmlBodyOpeningMuleLogs + mapBeepToMuleLogs.get(email) + htmlBodyClosure;
            }
            if(mapBeepToCalloutLogs.containsKey(email)){
                body += '</br></br>'+htmlBodyOpeningCalloutLogs + mapBeepToCalloutLogs.get(email) + htmlBodyClosure;
            }
            return body;
       
    }

    public  Messaging.SingleEmailMessage convertEmailBodyToSingleMessage(String emailAdd){
        String emailBody = mergeEmailLogs(emailAdd);
        List<String> sendTo = new List<String>{emailAdd};
        Messaging.SingleEmailMessage message1 = new Messaging.SingleEmailMessage();
        message1.setSaveAsActivity(false);
        message1.setSubject('Sawyer Alert failures : ');
        message1.setHtmlBody(emailBody );
        message1.setToAddresses(sendTo);
        return message1;
        
    }

    public Messaging.SingleEmailMessage getSingleEmailMessageFromListOfBeeps(List<Beep__c> beepList , String emailAddress){
        mapBeepToCalloutLogs = new Map<String,String>();
        mapBeepToMuleLogs = new Map<String,String>();
        mapBeepToSawyerlogs = new Map<String,String>();
        for(Beep__c tempBeep : beepList){
            beepRecord = tempBeep;
            emailAddOfRecepient = emailAddress;
            convertSawyerLogs();
            convertMuleSoftLogs();
            convertCalloutLogs();
        }
        return convertEmailBodyToSingleMessage(emailAddress);

    }
}//end of SawyerAlertHTmlCode