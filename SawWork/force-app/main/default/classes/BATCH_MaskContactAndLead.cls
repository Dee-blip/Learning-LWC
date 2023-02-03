/*
    Batch Job for the Post Refresh activity
    Mask the conatct email address with the prefix .qa,.SfdcMarch etc
    */
    global class BATCH_MaskContactAndLead implements Database.Batchable<sObject> ,DataBase.Stateful {
       
        global integer ProcessedRecords=0;
        global integer FailedRecords=0;
        global String errorString;
        global String maskingParam;
        
        /*Paramaterized Constructor for passing the masking Variable in the Sandbox*/
         global BATCH_MaskContactAndLead(String maskingParam){
            this.maskingParam = maskingParam;
        }
        
        global Database.QueryLocator start(Database.BatchableContext bc ){
            String query ='Select Id, Email, Validation_Override__c from Contact Where Email !=' +'\''+'\''+'AND CreatedDate > 2000-01-01T00:00:00Z';
            return Database.getQueryLocator(query);
        } 
        
        global void execute(Database.BatchableContext bc , List<Contact> scope){
            List<Contact> conUpdateList = new List<Contact>() ;
            List<Error_Log__c> errorList = new  List<Error_Log__c>(); 
           // String maskingParam = GsmUtilClass.GetCustomSettingValue('PostRefreshMaskingParam');
            for(Contact con: Scope){
               // if(con.Email.contains(maskingParam) ){
                    List<String> strList = con.Email.split('@');
                    if(!strList.isEmpty()){    
                      con.Email = strList[0] + maskingParam +'@'+ strList[1];
                    }    
                    con.Validation_Override__c = true;
                    conUpdateList.add(con);
               // }    
            } 
            if(!conUpdateList.isEmpty()){
                Database.SaveResult[] result = database.update(conUpdateList,false);
                
                for(Integer i =0; conUpdateList.size() > i;i++ ){
                    if(result[i].isSuccess()){
                     //getting the no of passed record in the salesforce.
                        ProcessedRecords++;
                    }else{
                     // generating the string for CSV creation
                    // errorString += '"'+conUpdateList.get(i).Id+'","'+result.get(i).getErrors().get(0)+'"\n';
                       // System.debug('errorString'+errorString);
                        // Add the records here.
                     //get the no of the failed record
                     FailedRecords ++;
                     Error_Log__c err = new Error_Log__c();
                     err.name =  'BATCH_MaskContactAndLead';  
                     err.Class__c ='BATCH_MaskContactAndLead';
                        for(Database.Error errs : result.get(i).getErrors()){ 
                            if( err.Error_Message__c == ''){
                            err.Error_Message__c = errs.getmessage();
                            }else{
                              err.Error_Message__c += errs.getmessage(); 
                            }   
                        }    
                     err.RecordId__c =  conUpdateList.get(i).Id;   
                     errorList.add(err);   
                    }
                }
            }    
            Database.insert(errorList, false);
        }
        
        global void finish(Database.BatchableContext bc ){
            Messaging.SingleEmailMessage email =new Messaging.SingleEmailMessage();
            String[] toAddresses = new list<string> {'eaeblrops@akamai.com'};
                System.debug('FailedRecords'+FailedRecords);
            System.debug('ProcessedRecords'+ ProcessedRecords);
            if(FailedRecords > 0 ){
                /* Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
                 String FinalStr = 'Record Id, Error Detail \n' + errorString;
                    //blob csvBlob = ;
                 string csvname= 'Error.csv';
                 csvAttc.setFileName(csvname);
                 csvAttc.setBody(Blob.valueOf(finalstr));   */
                 String subject ='Failed Record'+FailedRecords + 'And Processed Record'+ProcessedRecords;
                 email.setSubject(subject);
                 email.setPlainTextBody('Email Alert for exception');
              //  email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
            } else{
                String subject ='Successfully masked the Record'+ ProcessedRecords;
                email.setSubject(subject);
                email.setPlainTextBody('Email Alert for exception');
            }
            email.setToAddresses( toAddresses );
            Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
         }
    }