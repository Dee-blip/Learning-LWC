/* Template For Parsing Email:
* =========================
* For the known Normal Email:
* Error Details are present between "Error details:" and "Sample Leads"
* Count of Affected Emails are present between "Sample Leads" and "total"

* For the known Fatal Email:
* Error Details are present between "Error details:" and "What to do now?"

Marketo_Sync_Details --> Stores the Details about the Error After Parsing through The Email.
Marketo_Sync_Metadata --> Stores the Metadata about the errors.
*/

global inherited sharing class MARIT_MarketoSyncError implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
      Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        
        List<Error_Log__c> errorLogs = new List<Error_Log__c>();
        // Marketo_Sync object stores the Sync errors after parsing through the emails.
        List<Marketo_Sync_Details__c> marketoSyncList = new List<Marketo_Sync_Details__c>();
        String errorDetails;
        String affectedEmails;
        String numberOnly;
        Boolean isErrorPresent=false;
        try {
            if(string.isNotBlank(email.plainTextBody.substringAfter('Error details')))
            {
                errorDetails = email.plainTextBody.substringAfter('Error details:').normalizeSpace();
            }else{
                if(email.plainTextBody.length()>2500){
                    errorDetails = email.plainTextBody.substring(0,2000).normalizeSpace();
                }else{
                    errorDetails = email.plainTextBody.normalizeSpace();
                }
            }
            
            // fetching the metadata about the errors from Marketo_Sync_Metadata object.
            List<Marketo_Sync_Metadata__c> metaDataList = [Select Id,Name,Fatal__c,Error_Type__c,Error_Details__c From Marketo_Sync_Metadata__c LIMIT 1000]; 
            System.debug(LoggingLevel.INFO, 'list: ' + metaDataList );
            
            Marketo_Sync_Details__c marketoSyncObject = new Marketo_Sync_Details__c();
            marketoSyncObject.Name = email.subject;
            
            for(Marketo_Sync_Metadata__c mtdRec: metaDataList)
            {
                // if error is already persent
                if(errorDetails.contains(mtdRec.Name)){
                    marketoSyncObject.Type__c = mtdRec.Error_Type__c;
                    marketoSyncObject.Metadata_Type__c = mtdRec.Id;
                    // if error is non-fatal
                    if(mtdRec.Fatal__c==false){
                        affectedEmails = email.plainTextBody.substringBetween('Sample Leads:','total');
                        if (String.isNotBlank(affectedEmails)){
                             numberOnly = affectedEmails.replaceAll('[^0-9]', '');
                             marketoSyncObject.Affected_Emails_Count__c = Integer.valueOf(numberOnly);    
                        }
                        marketoSyncObject.Error_Details__c = errorDetails.substringBefore('Sample Leads:');
                    // if error is fatal 
                    }
                    if(mtdRec.Fatal__c==true){
                        marketoSyncObject.Error_Details__c = errorDetails;
                        marketoSyncObject.Fatal__c = true;
                    }
                    isErrorPresent=true;
                    marketoSyncList.add(marketoSyncObject);
                    break;  
                }
               
            }
            
            // new type of error encountered, store its detail in custom object, with fatal checked true and trigger an email
            if(!isErrorPresent)  
            {
                System.debug(LoggingLevel.INFO , 'inside the unique error found block');
                marketoSyncObject.Type__c = errorDetails.substring(0,250);
                marketoSyncObject.Error_Details__c = errorDetails;
                marketoSyncObject.Fatal__c = true; 
                marketoSyncList.add(marketoSyncObject);
            }
            
           System.debug(LoggingLevel.INFO, 'objects: ' + marketoSyncList);
           insert marketoSyncList;
        }catch(Exception e){
            
           System.debug(LoggingLevel.INFO, 'The following exception has occurred: ' + e.getMessage());
           errorLogs.add(new Error_Log__c(Name='MarketoSyncError', Class__c='MarketoSyncError', Error_Message__c=e.getMessage()));
           Database.insert(errorLogs, false);
        }
        
        return result;
    }
}