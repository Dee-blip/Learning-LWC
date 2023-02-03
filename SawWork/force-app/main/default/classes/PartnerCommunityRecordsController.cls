public with sharing class PartnerCommunityRecordsController {

    @AuraEnabled
    public static String getButtonUrl(String objectName) {

        try {
            Map<String,String> response = new Map<String,String>();
        	
            if (objectName == null || objectName == '') {
                response.put('ERROR','INVALID');
                return JSON.serialize(response);
            }

            List<Schema.DescribeSObjectResult> describeSobjectsResult = Schema.describeSObjects(new List<String>{objectName}); // this can accept list of strings, we describe only one object here
            String objectLabel = describeSobjectsResult[0].getLabel();

            //Schema.DescribeSObjectResult accountDescribe = Lead.sObjectType.getDescribe();
            System.debug('accessible:' + describeSobjectsResult[0].isCreateable());
            if (!describeSobjectsResult[0].isCreateable()) {
                response.put('ERROR','NO_ACCESS');
                return JSON.serialize(response);
            }
            
            /*
             * Add object API name to the response, this will be used in New is non overridden
             */
            response.put('objectAPIName',objectName); 

            /*
             * Remove __c from object name to get the metadata(as metadata name can't have __c)
             */
            if (objectName.contains('__c'))
                objectName = objectName.substring(0, objectName.length()-3);
            
            String settingName = 'PCNew' + objectName.capitalize();
            String url = GsmUtilClass.getPRMSettingValue(settingName);
            response.put('URL',url);
            response.put('Label',objectLabel);
            Map<String,String> paramters = getParamatersFromURL(url);
            response.put('type',paramters.get('type'));
            return JSON.serialize(response);
        } catch(Exception e) {
            //response.put('URL','INVALID');
            //return JSON.serialize(response);
            PartnerCommunityExceptionData error = new PartnerCommunityExceptionData();
            throw new AuraHandledException(JSON.serialize(error));
        }
    }
    
    class GenericFormWrapper {
        String sObjectName;
        String objectLabel;
        String customMetaDataObjName;
        String currentRecordTypeId;
        String defaultValues;
        String returnValPrefix;
    }
    
    @AuraEnabled
    public static String getDefaultValues(String url) {

        Map<String,String> parameters = getParamatersFromURL(url);
        
        GenericFormWrapper wrapper = new GenericFormWrapper();
        String sObjectName = parameters.get('sObjectName');
        wrapper.sObjectName = sObjectName.capitalize();
        wrapper.objectLabel = 'Create new ' + String.valueOf(Schema.getGlobalDescribe().get(sObjectName).getDescribe().getLabel()).capitalize(); //SFDC-6849
        wrapper.customMetaDataObjName = sObjectName.capitalize();
        wrapper.currentRecordTypeId = parameters.get('recordTypeId');
        wrapper.defaultValues = L2Q_Portal_DefaultValues.getDefaultValues(sObjectName);
        wrapper.returnValPrefix = '/partners/s/detail';
        return JSON.serialize(wrapper);
    }

    @AuraEnabled
    public static String getPartnerInvolved() {
		String partnerInvolved = [Select Id, Name, profileId, UserType, Contact.AccountId from user where id =: UserInfo.getUserId() limit 1].Contact.AccountId;
        return partnerInvolved;
	}

    @AuraEnabled
    public static string getFlowDetails(String url){

        Map<String,String> response = new Map<String,String>();

        Map<String,String> parametersValues = getParamatersFromURL(url);
        response.put('sObjectName',parametersValues.get('sObjectName'));
        response.put('flowName',parametersValues.get('flowName'));
        if (parametersValues.get('parentId') != null)
            response.put('parentId',parametersValues.get('parentId'));

        String partnerInvolved = [Select Id, Name, profileId, UserType, Contact.AccountId from user where id =: UserInfo.getUserId() limit 1].Contact.AccountId;
        if (partnerInvolved != null && partnerInvolved != '')
            response.put('partnerInvolved',partnerInvolved);
        return JSON.serialize(response); 
        
    }

    @AuraEnabled
    public static String getRecordAPIName(String recordId){
        return Id.valueOf(recordId).getSObjectType().getDescribe().getName();
    }

    public static Map<String,String> getParamatersFromURL(String url) {
        Map<String,String> parameters = new Map<String,String>();
        System.debug('SH : url server :'+url);
        //partners/s/new-record?sObjectName=Lead&recordTypeId=0120f000001IslP
        String parametersString = url.split('\\?')[1];
        List<String> parametersList = parametersString.split('&');
        for (String s:parametersList) {
            String[] values = s.split('=');
            parameters.put(values[0],values[1]);
        }
        System.debug('SH : parameters server :'+parameters);
        return parameters;
    }
    
    
}