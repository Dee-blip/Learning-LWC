// SFDC-6609
public with sharing class PartnerCommCommonController {

    @AuraEnabled
    public static void handleUnlockRecord(String recordId){
        try{
            String returnstring = '';
            if(Id.valueOf(recordId).getSObjectType().getDescribe().getName()=='Partner_Profile__c' || Id.valueOf(recordId).getSObjectType().getDescribe().getName()=='Partner_Marketing_Plan__c'){
                genericButtonPageController gbpcObj = new genericButtonPageController();
                gbpcobj.recordId = recordId;
                gbpcObj.unlockRecord();
                system.debug(LoggingLevel.ERROR,gbpcObj.message+' ::message in gbpcObj.message handleUnlockRecord');
                if(!String.isBlank(gbpcObj.message)){
                    returnstring = gbpcObj.message;
                }
                else {
                    returnstring = 'SUCCESS';
                }
            }
            if(returnstring != 'SUCCESS') {
                PartnerCommunityExceptionData data = new PartnerCommunityExceptionData('handleUnlockRecord',returnstring,500,returnstring,false);
                throw new AuraHandledException(JSON.serialize(data));
            }
        }
        catch(DMLException e)
        {
            if(e.getDmlType(0)==StatusCode.FIELD_CUSTOM_VALIDATION_EXCEPTION ) {
                PartnerCommunityExceptionData data = new PartnerCommunityExceptionData('handleUnlockRecord',e.getDmlMessage(0),500,e.getDMLMessage(0),false);
                throw new AuraHandledException(JSON.serialize(data));
            }
        }
    }

    @AuraEnabled
    public static String getUnlockRecordText(){
        String message = GsmUtilClass.getGSMSettingValue('partnerConfirmationMessage');
        return message;
    }
}