public class EB_SendSingleMailBatchJobStatusCtrl {

    public String mailerId = ApexPages.currentPage().getParameters().get('mailerId');
    public EB_AkaMailer__c akamMailer{get;set;}
    public String mailerIdForPage{get{return ApexPages.currentPage().getParameters().get('mailerId');}set;}

    public boolean isBatchSubmitted{get;set;}
    public boolean isBatchQueued{get;set;}
    public boolean isBatchInProgress{get;set;}
    public boolean isBatchCompleted{get;set;}
    public boolean isBatchFailed{get;set;}
    public boolean isJobTakingTooMuchTime{get;set;}
    public boolean isBatchPreparing{get;set;}
    public static boolean isRetry{get;set;}
    public boolean isRetryFail{get;set;}
    public boolean isSubmitAttemptFailed{get;set;}
    public boolean isConstructorCall = false;

    public Integer batchSubmitTryCount{get;set;}
    public Integer refreshPageOnceAfterCompletion{get;set;}
    public Integer totalNumberOfAttempts{get;set;}
    public Integer pageRefreshCount = 0;
    //public static String mailerIdToSend = ApexPages.currentPage().getParameters().get('mailerId');
    
    public Integer retryCount = Integer.valueOf(EBCS_Application__c.getInstance('SingleMailBatchClassRetryCount').Value__c);
    public Integer totalRetryCount{get;set;}
   
    public integer totalContactsProccessed{get;set;}


    public PageReference fetchMailerDetails(){
        isBatchSubmitted = false;
        isBatchQueued = false;
        isBatchPreparing = false;
        isBatchInProgress = false;
        isBatchCompleted = false;
        isBatchFailed =false;
        isRetryFail = false;
        isSubmitAttemptFailed = false;
        pageRefreshCount++;

        if(mailerId != NULL){

            akamMailer = [SELECT Id,EB_SendSingleMailBatchSubmitted__c,EB_SingleMailBatchJobId__c,
                          Name, EB_SendSingleMailBatchComplete__c, EB_CountToAddresses__c, CreatedBy.Name,
                          EB_TotalAccounts__c, EB_FailedCountFormula__c, EB_ProcessedCountFormula__c,
                          EB_DoNotScheduleAgain__c
                          FROM EB_AkaMailer__c WHERE Id = :mailerId];

            if(akamMailer.EB_SingleMailBatchJobId__c == '' || akamMailer.EB_SingleMailBatchJobId__c == null){
                isBatchSubmitted = false;
                isBatchQueued = false;
                isBatchPreparing = false;
                isBatchInProgress = false;
                isBatchCompleted = false;
                isBatchFailed =false;
                
                if(!isBatchInProgress && !isBatchPreparing && !isApexQueueEmpty()){
                    isRetryFail = false;
                    isSubmitAttemptFailed = true;
                    isBatchSubmitted = false;
                }
            }

            if(akamMailer.EB_SingleMailBatchJobId__c != '' && akamMailer.EB_SingleMailBatchJobId__c != null){
                AsyncApexJob objApexJobDetails = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed,
                                                  TotalJobItems, CreatedBy.Email
                                                  FROM AsyncApexJob WHERE Id = :akamMailer.EB_SingleMailBatchJobId__c];

                if(objApexJobDetails != null){
                    isBatchSubmitted = true;
                    if(objApexJobDetails.Status == 'Failed' || objApexJobDetails.Status == 'Aborted'){
                        isBatchSubmitted  = true;
                        isBatchQueued     = false;
                        isBatchPreparing  = false;
                        isBatchInProgress = false;
                        isBatchCompleted  = false;
                        isBatchFailed     = true;
                    }
                    
                    if(objApexJobDetails.Status == 'Preparing' || objApexJobDetails.Status == 'Queued'){
                        isBatchSubmitted  = true;
                        isBatchQueued     = true;
                        isBatchPreparing  = true;
                        isBatchInProgress = false;
                        isBatchCompleted  = false;
                        isBatchFailed     = false;

                    }
                    
                    if(objApexJobDetails.Status == 'Processing'){
                        isBatchSubmitted  = true;
                        isBatchQueued     = true;
                        isBatchPreparing  = true;
                        isBatchInProgress = true;
                        isBatchCompleted  = false;
                        isBatchFailed     = false;

                    }

                    if(objApexJobDetails.Status == 'Completed'){
                        
                        isBatchSubmitted  = true;
                        isBatchQueued     = true;
                        isBatchPreparing  = true;
                        isBatchInProgress = true;
                        isBatchCompleted  = true;
                        isBatchFailed     = false;


                        refreshPageOnceAfterCompletion++;
                        if(refreshPageOnceAfterCompletion==2){
                            PageReference pageRef = new PageReference('/'+ mailerId);
                            return pageRef;
                        }
                    }
                }                
            }

            else{
                if(!isRetryFail && !isSubmitAttemptFailed && !isConstructorCall)
                    isBatchSubmitted = true;
                isConstructorCall = false;
                
            }
        }

        return null;
    }

    public EB_SendSingleMailBatchJobStatusCtrl(){
       isRetry = false;
       isRetryFail = false;
       refreshPageOnceAfterCompletion = 0;
       totalRetryCount = 0;
       batchSubmitTryCount = 1;
       totalNumberOfAttempts = 0;
       isJobTakingTooMuchTime = false;
       isRetryFail = false;
       isSubmitAttemptFailed = false;
       isBatchInProgress = false;
       isBatchPreparing = false;
       isConstructorCall = true; 
       fetchMailerDetails();        
    }
    
    public void retrySubmitingJob(){
       akamMailer = [SELECT Id,EB_SendSingleMailBatchSubmitted__c,EB_SingleMailBatchJobId__c,
                          Name, EB_SendSingleMailBatchComplete__c, EB_CountToAddresses__c, CreatedBy.Name,
                          EB_TotalAccounts__c, EB_FailedCountFormula__c, EB_ProcessedCountFormula__c,
                          EB_DoNotScheduleAgain__c
                          FROM EB_AkaMailer__c WHERE Id = :mailerId];
        if(akamMailer.EB_SingleMailBatchJobId__c != '' && akamMailer.EB_SingleMailBatchJobId__c !=null){
            fetchMailerDetails();
        }
        
        else if(!isBatchInProgress && !isBatchPreparing && !isApexQueueEmpty()){
            isRetryFail = true;
            isSubmitAttemptFailed = false;
            isBatchSubmitted = false;
            totalRetryCount++;
            isRetry = true;
        }
        
        else if(!isBatchInProgress && !isBatchPreparing && isApexQueueEmpty()){
            EB_SingleMailBatchUtilClass.submitBatchJob(mailerId,true);
        }        
        
    }
    
    public boolean isApexQueueEmpty(){
    
        if ([SELECT count() FROM AsyncApexJob WHERE JobType='BatchApex' AND
            (Status = 'Processing' OR Status = 'Preparing') ] < 5){
            return true;
        }    
        isBatchSubmitted = false;
        return false;
    }
}