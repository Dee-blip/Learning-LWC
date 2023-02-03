public with sharing class PartnerCommRelatedListButtonsController {
	
    public static Map<string,string> getAllRelatedObjects(string masterObjectName){
        
        Map<string,string> relatedObjectsMap = new map<string,string>();
        List<Schema.Childrelationship> relatedObjectsList = Schema.getGlobalDescribe().get(masterObjectName).getdescribe().getChildRelationships();
        
        for (Schema.Childrelationship  relatedObject : relatedObjectsList) {
             System.debug('Object : '+relatedObject.getChildSObject().getDescribe().getName());
             if(relatedObject.getChildSObject().getDescribe().isUpdateable()
                    && 
                    relatedObject.getChildSObject().getDescribe().getKeyPrefix()!=null
                &&
                    !relatedObject.getChildSObject().getDescribe().isCustomSetting()
                    &&
                    relatedObject.getChildSObject().getDescribe().isCreateable()
                )
                relatedObjectsMap.put(relatedObject.getChildSObject().getDescribe().getName(),relatedObject.getChildSObject().getDescribe().getLabel());
       }
        return relatedObjectsMap;
    }

    @AuraEnabled
    public static Map<String,String> getRelatedObjects(String recordId){

        Map<String,String> availableRelatedListMap = new Map<String,String>();

        /*Get the Object API name and remove __c from it, as metadata does not have that
         */
        String objectKey = (Id.valueOf(recordId).getSObjectType().getDescribe().getName()).replace('__c','');
        String objectRelatedList = 'PartnerRelated' + objectKey;
        List<PRM_Setting__mdt> mdtRecord = [select Id, Value__c from PRM_Setting__mdt where DeveloperName = :objectRelatedList];
        /*If no related list defined for the object, return null
         * this way no related buttons will load for the object
         */
        if (mdtRecord.size() == 0)
            return null;
        
        Set<String> relatedObjectsSet = new Set<String>();
        relatedObjectsSet.addAll((mdtRecord[0].Value__c).split(','));
        //Get available related list for the object based on the object schema
        Map<String,String> allRelatedListMap = getAllRelatedObjects(Id.valueOf(recordId).getSObjectType().getDescribe().getName());
        //Filter related list based on the object specified in the metadata
        for (String s:allRelatedListMap.keySet()) {
            if (relatedObjectsSet.contains(s)) {
                availableRelatedListMap.put(allRelatedListMap.get(s),s);
            }
        }
        return availableRelatedListMap;
    }

    @AuraEnabled
    public static string getButtonUrl(String objectLabel, String recordId){
        Map<String,String> objLabelToObjectAPINameMap = getRelatedObjects(recordId);
        if (objLabelToObjectAPINameMap != null && objLabelToObjectAPINameMap.size() > 0) {
            String sObjectAPIName = objLabelToObjectAPINameMap.get(objectLabel);
            return PartnerCommunityRecordsController.getButtonUrl(sObjectAPIName);
        }
        return null;
        //String sObjectAPIName = objLabelToObjectAPINameMap.get(objectLabel);
        //String sObjectAPIName = Id.valueOf(recordId).getSObjectType().getDescribe().getName();
        
    }
}