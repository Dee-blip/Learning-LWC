public class PartnerCommSubmitForApprovalController {

    @AuraEnabled
    public static Opportunity getOppty(String recordId){
        
        List<Opportunity> opptyList = [select id,isRebateTCToShow__c,FCM__c,Partner_Owner__r.AccountId,Registration_Status__c 
                                        from Opportunity 
                                        where id=:recordId];
        if (opptyList.size() > 0) {
            return opptyList[0];
        } else {
            return null;
        }
    }

    @AuraEnabled
    public static void handleApproval(String recordId){

        try{
            String returnstring = '';
            String objName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();
            system.debug('Id.valueOf(recordId).getSObjectType().getDescribe().getName(): '+objName);
            // SFDC-6609
            if(objName=='Opportunity')
                returnstring = submitForApproval(recordId, true);
            else if(objName=='Partner_Profile__c' || objName=='Partner_Marketing_Plan__c'){
                genericButtonPageController gbpcObj = new genericButtonPageController();
                gbpcobj.recordId = recordId;
                gbpcObj.submitRecordForApproval();
                system.debug(LoggingLevel.ERROR,gbpcObj.message+' ::message in gbpcObj.message');
                if(!String.isBlank(gbpcObj.message)){
                    returnstring = gbpcObj.message;
                }
                else {
                    returnstring = 'SUCCESS';
                }
            }
            else if(objName=='SFDC_MDF__c' ){
                system.debug(' ::message in frBPcObj.message');
                FundRequestButtonPageController frBPcObj = new FundRequestButtonPageController();
                system.debug('setting record id ');
                FundRequestButtonPageController.recordId = recordId;
                frBPcObj.submitForApproval();
                system.debug(frBPcObj.message+' ::message in frBPcObj.message');
                if(!String.isBlank(frBPcObj.message)){
                    returnstring = frBPcObj.message;
                }
                else {
                    returnstring = 'SUCCESS';
                }
            }
            else if(objName=='SFDC_MDF_Claim__c' ){
                system.debug(' ::message in frBPcObj.message');
                FundClaimButtonPageController fcBPcObj = new FundClaimButtonPageController();
                system.debug('setting record id ');
                SFDC_MDF_Claim__c fcClaimObj = [select id, Status__c from SFDC_MDF_Claim__c where id=:recordId];
                system.debug('fcClaimObj:: '+fcClaimObj.Status__c);
                FundClaimButtonPageController.recordId = recordId;
                FundClaimButtonPageController.status = fcClaimObj.Status__c;
                fcBPcObj.submitForApproval();
                system.debug(fcBPcObj.message+' ::message in frBPcObj.message');
                if(!String.isBlank(fcBPcObj.message)){
                    returnstring = fcBPcObj.message;
                }
                else {
                    returnstring = 'SUCCESS';
                }
            }
            if(returnstring != 'SUCCESS') {
                PartnerCommunityExceptionData data = new PartnerCommunityExceptionData('Submit for approval',returnstring,500,returnstring,false);
                throw new AuraHandledException(JSON.serialize(data));
            }
        }
        catch(DMLException e)
        {
            if(e.getDmlType(0)==StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION && e.getDMLMessage(0).contains(GsmUtilClass.getGSMSettingValue('OpportunityTrg_RebateTCError'))) {
                PartnerCommunityExceptionData data = new PartnerCommunityExceptionData('Submit for approval',e.getDmlMessage(0),500,e.getDMLMessage(0),false);
                throw new AuraHandledException(JSON.serialize(data));
            }
        }
    }

    public static string submitForApproval(Id p_OppId, Boolean isOppty)
    {
        
        Approval.ProcessSubmitRequest req = new Approval.ProcessSubmitRequest();
        req.setComments('Submitted for approval. Please approve.');
        req.setObjectId(p_OppId);
        String customSettingsExceptionCheck = GsmUtilClass.getGSMSettingValue('DealRegSubmit_ProfileException');
        String userProfileId = userinfo.getProfileId();
        Opportunity oppty;
        if(isOppty)
        {
            oppty = [Select CloseDate from Opportunity where Id=:p_OppId][0];
        }
        if(!isOppty || customSettingsExceptionCheck.contains(userProfileId) || (isOppty && oppty.CloseDate!=null && oppty.CloseDate>=Date.today()))
        {
            // submit the approval request for processing
            String error;
            try {
                Approval.ProcessResult result = Approval.process(req);
                return 'SUCCESS';
            }
            catch(DmlException e) {
                for (Integer i = 0; i < e.getNumDml(); i++)
                { 
                    if(e.getDmlType(i) == Statuscode.ALREADY_IN_PROCESS)
                        error = errorMessage('3');
                    else if(e.getMessage().containsIgnoreCase('MANAGER_NOT_DEFINED'))
                        error = errorMessage('8');
                    else
                        error = e.getMessage();
                }
            }
            catch(Exception e)
            {
                error = e.getMessage();
            }
            return error;
        }
        else
        {   
            return errorMessage('7');
        }
    }

    public static String errorMessage(String metadataName){
    	String error ='';
        
           if(metadataName != null){
              if(metadataName.contains(' ')){
                  metadataName = metadataName.replaceAll(' ', '_');
              }
              if(metadataName.isNumeric()){
                  metadataName = 'X'+metadataName;
              }
              error =  GsmUtilClass.getErrorPageSettingValue(metadataName);
           }
           return error;
       }
       
}