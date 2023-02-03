public with sharing class GSM_GenericFormController {

        private Static Schema.SObjectType sobjectType;
        private Static String sobjectName;
        private Static Map<String, Schema.SObjectField> schemaFieldMap;
        public static PickListFieldWrapper mapOfFieldsVsPicklistDescribe;

        public class FieldDescriptor {
                @AuraEnabled public Boolean isRequired {get; set;}
                @AuraEnabled public Boolean isUpdatable {get; set;}
                @AuraEnabled public Boolean isReadOnly {get; set;}
                @AuraEnabled public Boolean overRidePickListVals {get; set;}
                @AuraEnabled public Boolean isDependentField {get; set;}
                @AuraEnabled public Boolean isDynamicLookup {get; set;}
                @AuraEnabled public String value {get; set;}
                @AuraEnabled public String label {get; set;}
                @AuraEnabled public String fieldType  {get; set;}
                @AuraEnabled public String placeHolder {get; set;}
                @AuraEnabled public String helpText {get; set;}
                @AuraEnabled public String fieldAPIName {get; set;}
                @AuraEnabled public String referenceFieldType {get; set;}
                @AuraEnabled public String dependedntPicklistsMap {get; set;}
                @AuraEnabled public String lookupFilterQuery {get; set;}
                @AuraEnabled public String dynamicWhereClause {get; set;}
                @AuraEnabled public String dynamicLookupDependencyOn {get; set;}

                @AuraEnabled public List<String> pickListVals {get; set;}
                @AuraEnabled public List<String> selectedPickListValues {get; set;}
                @AuraEnabled public List<String> listOfDependentFields {get; set;}

                public FieldDescriptor() {
                        pickListVals = new List<String>();
                        selectedPickListValues = new List<String>();
                }
        }

        public class SectionDescriptor {
                @AuraEnabled public Boolean editLayoutProperties {get; set;}
                @AuraEnabled public LayoutProperties layoutPropertiesDetails {get; set;}

                @AuraEnabled public String sectionName {get; set;}
                @AuraEnabled public List<FieldDescriptor> listOfSectionFields {get; set;}
                @AuraEnabled public Boolean isEmptySection {get; set;}
                @AuraEnabled public String requiredMetadataName {get; set;}

                public SectionDescriptor() {
                        listOfSectionFields = new List<FieldDescriptor>();
                        isEmptySection = false;
                }
        }

        public class LayoutProperties {
                @AuraEnabled public Boolean caseAssignmentCheckboxRequired {get; set;}
                @AuraEnabled public Boolean caseAssignmentCheckboxDefaultValue {get; set;}

                @AuraEnabled public Boolean emailNotificationCheckboxRequired {get; set;}
                @AuraEnabled public Boolean emailNotificationCheckboxDefaultValue {get; set;}
        }

        public class EachValue {
                public string label { get; set; }
                public List<Integer> validFor { get; set; }
                public string value { get; set; }
        }

        public class EachFieldValueWrapper {
                public Map<String,String> controllerValues { get; set; }
                public EachValue defaultValue { get; set; }
                public List<EachValue> values { get; set; }
        }

        public class PickListFieldWrapper {
                public Map<String, EachFieldValueWrapper> picklistFieldValues;
        }

        public static String resultSetCustom (Boolean errorOccured, String returnMessage) {

                Map<String, String> mapObject = new Map<String, String>();
                if(errorOccured != null) {
                        mapObject.put('errorOccured', String.valueOf(errorOccured));
                }
                if(returnMessage != null) {
                        mapObject.put('returnMessage', returnMessage);
                }
                return JSON.serialize(mapObject);
        }

        public static SObjectFormJSON__mdt getRequiredMetadata(List<SObjectFormJSON__mdt> listOfSObjectFormJSON, String currentRecordTypeId) {

                if(currentRecordTypeId == null || currentRecordTypeId == '') {
                        Map<Id,Schema.RecordTypeInfo> recordTypeMapById = sobjectType.getDescribe().getRecordTypeInfosById();
                        for(Id eachRecordTypeId : recordTypeMapById.keySet()) {
                                if(recordTypeMapById.get(eachRecordTypeId).isDefaultRecordTypeMapping() && recordTypeMapById.get(eachRecordTypeId).isAvailable()) {
                                        currentRecordTypeId = eachRecordTypeId;
                                        break;
                                }
                                else if(recordTypeMapById.get(eachRecordTypeId).isMaster() && recordTypeMapById.get(eachRecordTypeId).isAvailable()) {
                                        currentRecordTypeId = eachRecordTypeId;
                                }
                        }
                }
                if(currentRecordTypeId != null && currentRecordTypeId.length() > 15) {
                        currentRecordTypeId = currentRecordTypeId.subString(0, 15);
                }
                //System.DEBUG('currentRecordTypeId: ' + currentRecordTypeId);
                String userProfileId = UserInfo.getProfileId();
                if(userProfileId != null && userProfileId.length() > 15) {
                        userProfileId = userProfileId.subString(0, 15);
                }
                //System.DEBUG('userProfileId: ' + userProfileId);

                SObjectFormJSON__mdt requiredMetadata; // priority1
                SObjectFormJSON__mdt profileBasedMetaData; // priority2
                SObjectFormJSON__mdt recordTypeBasedMetaData; // priority3
                SObjectFormJSON__mdt defaultMetadata; // priority4

                /* logic-> requiredMetadata priorities :
                   if profileIds and recordTypeIds are mentioned ->  priority1
                   if only profile Ids are mentioned -> priority2
                   if only record type Ids are mentioned -> priority 3
                   if default flag checked -> priority 4
                 */
                for(SObjectFormJSON__mdt eachListOfSObjectFormJSON : listOfSObjectFormJSON) {
                    	System.debug('eachListOfSObjectFormJSON :'+eachListOfSObjectFormJSON);
                        // recordTypes are mentioned and current record type is matched
                        if(eachListOfSObjectFormJSON.recordTypeIds__c != null && currentRecordTypeId != null && eachListOfSObjectFormJSON.recordTypeIds__c.contains(currentRecordTypeId)) {
                                // if profile Ids are mentioned and current profile Id is matched then required metadata -> break;
                                if(eachListOfSObjectFormJSON.ProfileIds__c != null && eachListOfSObjectFormJSON.ProfileIds__c.contains(userProfileId)) {
                                        requiredMetadata = eachListOfSObjectFormJSON;
                                        break;
                                } // if profile Ids are not mentioned then maybe recordTpeBasedMetaData
                                else if(eachListOfSObjectFormJSON.ProfileIds__c == null) {
                                        recordTypeBasedMetaData = eachListOfSObjectFormJSON;
                                }
                        } // if record Ids are not mentioned and only profile Ids are mentioned then maybe profile based Metadata
                        else if(eachListOfSObjectFormJSON.recordTypeIds__c == null && eachListOfSObjectFormJSON.ProfileIds__c != null && eachListOfSObjectFormJSON.ProfileIds__c.contains(userProfileId)) {
                                profileBasedMetaData = eachListOfSObjectFormJSON;
                        } // if default flag is checked then defaultMetadata
                        if(eachListOfSObjectFormJSON.isDefaultMetadata__c != null && eachListOfSObjectFormJSON.isDefaultMetadata__c) {
                                defaultMetadata = eachListOfSObjectFormJSON;
                        }
                }
                if(requiredMetadata == null) {
                        if(profileBasedMetaData != null) {
                                requiredMetadata = profileBasedMetaData;
                        } else if (recordTypeBasedMetaData != null) {
                                requiredMetadata = recordTypeBasedMetaData;
                        } else if(defaultMetadata != null) {
                                requiredMetadata = defaultMetadata;
                        }
                }
                System.DEBUG('requiredMetadata: ' + requiredMetadata.MasterLabel);
                return requiredMetadata;
        }

        @AuraEnabled
        public static String getSectionValues(String sObjectName, Map<Object, Object> defaultValues, String customMetaDataObjName, String currentRecordTypeId) {
                String jsonData;

                sobjectType = Schema.getGlobalDescribe().get(sObjectName);
                schemaFieldMap = sobjectType.getDescribe().fields.getMap();
                try {
                        if(sobjectType.getDescribe().isCreateable() && sobjectType.getDescribe().isAccessible()) {
                                List<SObjectFormJSON__mdt> listOfSObjectFormJSON = [SELECT MasterLabel, JSON_String__c, ProfileIds__c, isDefaultMetadata__c, recordTypeIds__c FROM SObjectFormJSON__mdt WHERE SObjectType__c =: customMetaDataObjName];
                                try {
                                        SObjectFormJSON__mdt requiredMetadata = getRequiredMetadata(listOfSObjectFormJSON, currentRecordTypeId);
                                        if(requiredMetadata != null) {
                                                List<SectionDescriptor> listOfSectionDescriptor = (List<SectionDescriptor>)JSON.deserialize(requiredMetadata.JSON_String__c, List<SectionDescriptor>.Class);
                                            	System.debug('listOfSectionDescriptor :'+listOfSectionDescriptor);
                                                listOfSectionDescriptor = assignDefaultValues(listOfSectionDescriptor, defaultValues);
                                                for(SectionDescriptor eachSectionDescriptor : listOfSectionDescriptor) {
                                                        Map<String, String> returnObj = getFieldValues(sObjectName, eachSectionDescriptor.listOfSectionFields, currentRecordTypeId);
                                                        eachSectionDescriptor.listOfSectionFields = (List<FieldDescriptor>)JSON.deserialize(returnObj.get('listOfSectionFields'), List<FieldDescriptor>.Class);
                                                        System.DEBUG('sectionFieldCount: ' + Integer.valueOf(returnObj.get('sectionFieldCount')));
                                                        if(Integer.valueOf(returnObj.get('sectionFieldCount')) == 0) {
                                                                eachSectionDescriptor.isEmptySection = true;
                                                        } else {
                                                                eachSectionDescriptor.isEmptySection = false;
                                                        }
                                                        eachSectionDescriptor.requiredMetadataName = requiredMetadata.MasterLabel;
                                                }

                                                jsonData = JSON.serialize(listOfSectionDescriptor);
                                                return resultSetCustom(false, jsonData);
                                        }
                                        else {
                                                return resultSetCustom(true, 'No Profile related Custom Metadata available for the current user\'s profile');
                                        }

                                }
                                catch (Exception e) {
                                        return resultSetCustom(true, 'Error in JSON format of customMetaData. Or ' + String.valueOf(e));
                                }
                        } else {
                                return resultSetCustom(true, 'Error, The current user might not have required access over the object');
                        }

                }
                catch (Exception e) {
                        return resultSetCustom(true, 'Error in querying customMetaData. ' + String.valueOf(e));
                }
        }

        @AuraEnabled
        public static Map<String, String> getFieldValues(String sObjectName, List<FieldDescriptor> listOfSectionFields, String currentRecordTypeId) {
                Integer sectionFieldCount = 0;
                //Set<String> updateDependentFields = new Set<String>();
                Map<String, FieldDescriptor> updateDependentFields = new Map<String, FieldDescriptor>();
                for(FieldDescriptor eachSectionFields : listOfSectionFields) {
                    	System.debug('eachSectionFields :'+eachSectionFields);
                    	System.debug('schemaFieldMap :'+schemaFieldMap);
                    	System.debug('schemaFieldMap.get :'+schemaFieldMap.get(eachSectionFields.fieldAPIName));
                        Schema.DescribeFieldResult fieldResult = schemaFieldMap.get(eachSectionFields.fieldAPIName).getDescribe();

                        if(eachSectionFields.label == null) {
                                eachSectionFields.label = String.valueOf(fieldResult.getLabel());
                        }

                        if(eachSectionFields.fieldType !='RICHTEXT' && eachSectionFields.fieldType != 'DEPENDENTPICKLIST' && eachSectionFields.fieldType != 'RICHTEXT_LIMITED') {
                                eachSectionFields.fieldType = String.valueOf(fieldResult.getType());
                        }
                        if(eachSectionFields.isReadOnly == null) {
                                eachSectionFields.isReadOnly = false;
                        }

                        if(eachSectionFields.isUpdatable == null && fieldResult.isUpdateable()) {
                                eachSectionFields.isUpdatable = true;
                        } else if(eachSectionFields.isUpdatable == null) {
                                eachSectionFields.isUpdatable = false;
                        }

                        if(eachSectionFields.isRequired == null) {
                                if(eachSectionFields.fieldType != 'BOOLEAN') {
                                        eachSectionFields.isRequired = !fieldResult.isNillable();
                                }
                        }

                        if(eachSectionFields.helpText == null) {
                                eachSectionFields.helpText = String.valueOf(fieldResult.getInlineHelpText());
                        }

                        if(eachSectionFields.fieldType == 'REFERENCE') {
                                if(eachSectionFields.referenceFieldType == null) {
                                        for(Schema.SObjectType reference : fieldResult.getReferenceTo()) {
                                                eachSectionFields.referenceFieldType = String.valueOf(reference.getDescribe().getName());
                                                break;
                                        }
                                }
                        }

                        if(eachSectionFields.fieldType == 'PICKLIST' || eachSectionFields.fieldType == 'MULTIPICKLIST' || eachSectionFields.fieldType == 'DEPENDENTPICKLIST') {
                                List<Schema.PicklistEntry> allPickList = fieldResult.getPicklistValues();
                                if(eachSectionFields.overRidePickListVals == null || eachSectionFields.overRidePickListVals == false) {
                                        if(eachSectionFields.fieldType == 'PICKLIST' || eachSectionFields.fieldType == 'MULTIPICKLIST') {
                                                Set<String> setOfPicklistVals;
                                                if(eachSectionFields.pickListVals != null && eachSectionFields.pickListVals.size() > 0) {
                                                        setOfPicklistVals = new Set<String>(eachSectionFields.pickListVals);
                                                }
                                                else {
                                                        setOfPicklistVals = new Set<String>();
                                                        for(Schema.PicklistEntry eachPickList : allPickList) {
                                                                setOfPicklistVals.add(eachPickList.getValue());
                                                        }
                                                }
                                                eachSectionFields.pickListVals = new List<String>(setOfPicklistVals);
                                                if(eachSectionFields.fieldType == 'PICKLIST' && eachSectionFields.pickListVals != null && !eachSectionFields.pickListVals.contains('--None--')) {
                                                        eachSectionFields.pickListVals.add(0,'--None--');
                                                }
                                        } else if(eachSectionFields.fieldType == 'DEPENDENTPICKLIST') {

                                                if(mapOfFieldsVsPicklistDescribe == null || (mapOfFieldsVsPicklistDescribe != null && mapOfFieldsVsPicklistDescribe.picklistFieldValues != null && mapOfFieldsVsPicklistDescribe.picklistFieldValues.isEmpty())) {
                                                        setDependentPicklistMap(sObjectName, currentRecordTypeId);
                                                }
                                                if(eachSectionFields.pickListVals == null || (eachSectionFields.pickListVals != null && eachSectionFields.pickListVals.size() == 0)) {
                                                        System.DEBUG('inside eachSectionFields.pickListVals');
                                                        eachSectionFields.pickListVals = getRecordTypeBasedPicklistVals(eachSectionFields.fieldAPIName);
                                                        eachSectionFields.pickListVals.add(0, '--None--');
                                                }
                                                if(mapOfFieldsVsPicklistDescribe != null && mapOfFieldsVsPicklistDescribe.picklistFieldValues != null) {
                                                        eachSectionFields.dependedntPicklistsMap = JSON.serialize(getDependencyMap(eachSectionFields.fieldAPIName, eachSectionFields.listOfDependentFields));
                                                        //eachSectionFields.listOfDependentFieldsJSON = JSON.serialize(eachSectionFields.listOfDependentFields);
                                                        eachSectionFields.value = getDefaultValueOfPicklist(eachSectionFields.fieldAPIName);
                                                        if(eachSectionFields.value != null) {
                                                                for(String eachDependentField : eachSectionFields.listOfDependentFields) {
                                                                        updateDependentFields.put(eachDependentField, eachSectionFields);
                                                                }
                                                        }
                                                }
                                        }
                                }
                        }

                        if(eachSectionFields.isUpdatable || eachSectionFields.isReadOnly) {
                                sectionFieldCount++;
                        }
                }
                // enable dependent field if controlling field is defaulted.
                if(updateDependentFields.size() > 0) {
                        for(FieldDescriptor eachSectionFields : listOfSectionFields) { // find dependent field's describe
                                if(updateDependentFields.containsKey(eachSectionFields.fieldAPIName)) {
                                        eachSectionFields.isDependentField = false;
                                        if(updateDependentFields.get(eachSectionFields.fieldAPIName).dependedntPicklistsMap != null) {
                                                Map<String, Map<String, List<String>>> tempMap = (Map<String, Map<String, List<String>>>)JSON.deserialize(updateDependentFields.get(eachSectionFields.fieldAPIName).dependedntPicklistsMap, Map<String, Map<String, List<String>>>.Class);
                                                eachSectionFields.pickListVals = (tempMap.get(eachSectionFields.fieldAPIName)).get(updateDependentFields.get(eachSectionFields.fieldAPIName).value);
                                                if(eachSectionFields.pickListVals.size() > 0 && eachSectionFields.pickListVals.get(0) != '--None--') {
                                                        eachSectionFields.pickListVals.add(0, '--None--');
                                                }
                                        }
                                }
                        }
                }
                Map<String, String> mapObject = new Map<String, String>();
                mapObject.put('sectionFieldCount', String.valueOf(sectionFieldCount));
                mapObject.put('listOfSectionFields', JSON.serialize(listOfSectionFields));
                return mapObject;
        }

        private static void setDependentPicklistMap(String objectType, String recordTypeId) {
                System.DEBUG('setDependentPicklistMap: objectType: ' + objectType + 'recordTypeId: ' + recordTypeId);
                mapOfFieldsVsPicklistDescribe = new PickListFieldWrapper();
                mapOfFieldsVsPicklistDescribe = getValues(objectType, recordTypeId);
                System.DEBUG('setDependentPicklistMap: mapOfFieldsVsPicklistDescribe: ' + mapOfFieldsVsPicklistDescribe);
                //Map<String, EachFieldValueWrapper> picklistFieldValues = mapOfFieldsVsPicklistDescribe.picklistFieldValues;
        }

        private static String getDefaultValueOfPicklist(String fieldName) {
                if(mapOfFieldsVsPicklistDescribe.picklistFieldValues.containsKey(fieldName)) {
                        if(mapOfFieldsVsPicklistDescribe.picklistFieldValues.get(fieldName).defaultValue != null) {
                                return mapOfFieldsVsPicklistDescribe.picklistFieldValues.get(fieldName).defaultValue.value;
                        }
                }
                return null;
        }

        public static List<String> getRecordTypeBasedPicklistVals(String fieldAPIName) {
                List<String> listOfFieldPicklistValues = new List<String>();
                if(mapOfFieldsVsPicklistDescribe != null && mapOfFieldsVsPicklistDescribe.picklistFieldValues != null && mapOfFieldsVsPicklistDescribe.picklistFieldValues.containsKey(fieldAPIName)) {
                        EachFieldValueWrapper fieldDescribe = mapOfFieldsVsPicklistDescribe.picklistFieldValues.get(fieldAPIName);
                        for(EachValue eachVal : fieldDescribe.values) {
                                listOfFieldPicklistValues.add(eachVal.value);
                        }
                }
                return listOfFieldPicklistValues;
        }

        public static Map<String, Map<String, List<String>>> getDependencyMap(String controllingField, List<String> listOfDependentFields) {

                System.DEBUG('getDependencyMap: controllingField: ' + controllingField + 'listOfDependentFields: ' + listOfDependentFields);
                Map<String, Map<String, List<String>>> dependencyMap = new Map<String, Map<String, List<String>>>();
                Set<String> setOfControllingFieldPicklistValues = new Set<String>(getRecordTypeBasedPicklistVals(controllingField));
                if(setOfControllingFieldPicklistValues.size() > 0) {
                        System.DEBUG('setOfControllingFieldPicklistValues: ' + setOfControllingFieldPicklistValues);
                        for(String eachDependentField : listOfDependentFields) {
                                EachFieldValueWrapper dependentFieldDescribe = mapOfFieldsVsPicklistDescribe.picklistFieldValues.get(eachDependentField);
                                if(dependentFieldDescribe != null) {
                                        Map<String, List<String>> eachDependentFieldMap = new Map<String, List<String>>();
                                        for(EachValue eachVal : dependentFieldDescribe.values) {         // dependent Field Picklist Vals
                                                for(Integer eachValidFor : eachVal.validFor) {         // valid-for list
                                                        for(String eachControlerValue : dependentFieldDescribe.controllerValues.KeySet()) {
                                                                if(Integer.valueOf(dependentFieldDescribe.controllerValues.get(eachControlerValue)) == eachValidFor && setOfControllingFieldPicklistValues.contains(eachControlerValue)) {
                                                                        if(eachDependentFieldMap.containsKey(eachControlerValue)) {
                                                                                List<String> presentList = eachDependentFieldMap.get(eachControlerValue);
                                                                                presentList.add(eachVal.value);
                                                                                eachDependentFieldMap.put(eachControlerValue, presentList);
                                                                        }
                                                                        else {
                                                                                List<String> newList = new List<String>();
                                                                                newList.add(eachVal.value);
                                                                                eachDependentFieldMap.put(eachControlerValue, newList);
                                                                        }
                                                                }
                                                        }
                                                }
                                        }
                                        if(eachDependentFieldMap.size() > 0) {
                                                dependencyMap.put(eachDependentField, eachDependentFieldMap);
                                        }
                                }
                        }
                }

                System.DEBUG('getDependencyMap: dependencyMap: ' + dependencyMap);
                return dependencyMap;
        }

        public static PickListFieldWrapper getValues(String objectType, String recordTypeId) {
                //Endpoint
                String endpoint = URL.getSalesforceBaseUrl().toExternalForm();
                endpoint += '/services/data/v42.0';
                endpoint += '/ui-api/object-info/' + objectType + '/picklist-values/' + recordTypeId;

                //endpoint = String.format(endpoint, new String[] { objectType, recordTypeId, fieldName });
                EncodingUtil.urlEncode(endpoint,'UTF-8');

                //HTTP Request send
                HttpRequest req = new HttpRequest();
                req.setHeader('Authorization', 'OAuth ' + UserInfo.getSessionId());
                req.setEndpoint(endpoint);
                req.setMethod('GET');
                Http http = new Http();
                HTTPResponse res = http.send(req);

                PickListFieldWrapper pklWrap = (PickListFieldWrapper) JSON.deserialize(res.getBody(), PickListFieldWrapper.Class);
                //System.DEBUG(pklWrap);

                return pklWrap;
        }

        private static List<SectionDescriptor> assignDefaultValues(List<SectionDescriptor> listOfSectionDescriptor, Map<Object, Object> defaultValues) {
                if(defaultValues != null && defaultValues.size() > 0) {
                        for(SectionDescriptor eachSectionDescriptor : listOfSectionDescriptor) {
                                if(eachSectionDescriptor.listOfSectionFields != null) {
                                        for(FieldDescriptor eachFieldDescriptor : eachSectionDescriptor.listOfSectionFields) {
                                                if(defaultValues.containsKey(eachFieldDescriptor.fieldAPIName)) {
                                                        FieldDescriptor fd = (FieldDescriptor) JSON.deserialize(JSON.serialize(defaultValues.get(eachFieldDescriptor.fieldAPIName)), FieldDescriptor.Class);
                                                        if(fd.value != null) {
                                                                eachFieldDescriptor.value = fd.value;
                                                        }
                                                        if(fd.label != null) {
                                                                eachFieldDescriptor.label = fd.label;
                                                        }
                                                        if(fd.pickListVals != null) {
                                                                eachFieldDescriptor.pickListVals = fd.pickListVals;
                                                        }
                                                        if(fd.selectedPickListValues != null) {
                                                                eachFieldDescriptor.selectedPickListValues = fd.selectedPickListValues;
                                                        }
                                                        if(fd.isRequired != null) {
                                                                eachFieldDescriptor.isRequired = fd.isRequired;
                                                        }
                                                        if(fd.isUpdatable != null) {
                                                                eachFieldDescriptor.isUpdatable = fd.isUpdatable;
                                                        }
                                                        if(fd.overRidePickListVals != null ) {
                                                                eachFieldDescriptor.overRidePickListVals = fd.overRidePickListVals;
                                                                if(Boolean.valueOf(fd.overRidePickListVals)) {
                                                                        Map<String, Map<String, List<String>>> eachdependedntPicklistsMap = new Map<String, Map<String, List<String>>>();
                                                                        /*if(eachdependedntPicklistsMap.containsKey(UserInfo.getProfileId())) {
                                                                                Map<String, List<String>> mapOfFieldsVsPickListVals = new Map<String, List<String>>(eachdependedntPicklistsMap.get(UserInfo.getProfileId()));
                                                                                if(mapOfFieldsVsPickListVals.containsKey(eachFieldDescriptor.fieldAPIName))  {
                                                                                        eachFieldDescriptor.pickListVals = mapOfFieldsVsPickListVals.get(eachFieldDescriptor.fieldAPIName);
                                                                                }
                                                                           }*/
                                                                }
                                                        }
                                                        if(fd.fieldType != null) {
                                                                eachFieldDescriptor.fieldType = fd.fieldType;
                                                        }
                                                        if(fd.isReadOnly != null) {
                                                                eachFieldDescriptor.isReadOnly = fd.isReadOnly;
                                                        }
                                                        if(fd.placeHolder != null) {
                                                                eachFieldDescriptor.placeHolder = fd.placeHolder;
                                                        }
                                                        if(fd.helpText != null) {
                                                                eachFieldDescriptor.helpText = fd.helpText;
                                                        }
                                                        if(fd.lookupFilterQuery != null) {
                                                                eachFieldDescriptor.lookupFilterQuery = fd.lookupFilterQuery;
                                                        }
                                                }
                                        }
                                }
                                else {
                                        eachSectionDescriptor.listOfSectionFields = new List<FieldDescriptor>();
                                }

                        }
                }
            	System.debug('listOfSectionDescriptor :'+listOfSectionDescriptor);
                return listOfSectionDescriptor;
        }

        @AuraEnabled
        public static String insertObject(Map<String, Object> fieldDetails, String sObjectName, String recordTypeId, Boolean assignUsingActiveReassignmentRules, Boolean sendNotificationEmailToContact) {
                String returnVal;
                sobjectType = Schema.getGlobalDescribe().get(sObjectName);
                schemaFieldMap = sobjectType.getDescribe().fields.getMap();
                System.DEBUG('recordTypeId: ' + recordTypeId);
                System.DEBUG('assignUsingActiveReassignmentRules: ' + assignUsingActiveReassignmentRules);
                System.DEBUG('sendNotificationEmailToContact: ' + sendNotificationEmailToContact);
                try {
                        SObject sObj;
                        if(recordTypeId != null && recordTypeId != '') {
                                sObj = Schema.getGlobalDescribe().get(String.valueOf(sObjectName)).newSObject(Id.valueOf(recordTypeId), true);
                        } else {
                                sObj = Schema.getGlobalDescribe().get(String.valueOf(sObjectName)).newSObject();
                        }
                        for ( String fieldName : fieldDetails.keySet() ) {
                                Schema.DescribeFieldResult fieldResult = schemaFieldMap.get(fieldName).getDescribe();
                                String fieldType = String.valueOf(fieldResult.getType());
                                if(fieldDetails.get(fieldName) != null) {
                                        if(fieldType == 'DATE') {
                                                List<String> dateString =  String.Valueof(fieldDetails.get(fieldName)).split('-');
                                                sObj.put(fieldName, Date.newInstance(Integer.valueOf(dateString.get(0)), Integer.valueOf(dateString.get(1)), Integer.valueOf(dateString.get(2))));
                                        } else if(fieldType == 'DATETIME') {
                                                List<String> dateTimeSeparator =  String.Valueof(fieldDetails.get(fieldName)).split('T');
                                                List<String> dateString =  (dateTimeSeparator.get(0)).split('-');
                                                List<String> timeString =  (dateTimeSeparator.get(1)).split(':');
                                                sObj.put(fieldName, DateTime.newInstance(Integer.valueOf(dateString.get(0)), Integer.valueOf(dateString.get(1)), Integer.valueOf(dateString.get(2)), Integer.valueOf(timeString.get(0)), Integer.valueOf(timeString.get(1)), Integer.valueOf(timeString.get(2))));
                                        } else if(fieldType == 'DOUBLE' || fieldType == 'CURRENCY') {
                                                sObj.put(fieldName, Decimal.valueOf(String.Valueof(fieldDetails.get(fieldName))).setScale(fieldResult.getScale()));
                                        } else if(fieldType == 'INTEGER') {
                                                sObj.put(fieldName, Integer.valueOf(String.Valueof(fieldDetails.get(fieldName))));
                                        } else if(fieldType == 'BOOLEAN') {
                                                sObj.put(fieldName, Boolean.valueOf(fieldDetails.get(fieldName)));
                                        } else {
                                                sObj.put(fieldName, String.valueOf(fieldDetails.get(fieldName)));
                                        }
                                }
                        }
                        if(assignUsingActiveReassignmentRules || sendNotificationEmailToContact) {
                                Database.DMLOptions dmo = new Database.DMLOptions();
                                if(assignUsingActiveReassignmentRules) {
                                        dmo.assignmentRuleHeader.useDefaultRule = true;
                                }
                                if(sendNotificationEmailToContact) {
                                        dmo.EmailHeader.triggerAutoResponseEmail = true;
                                }
                                sObj.setOptions(dmo);
                        }

                        insert sObj;
                        returnVal = sObj.Id;
                }
                catch(Exception e) {
                        String error = String.valueOf(e);
                        if(error.contains('FIELD_CUSTOM_VALIDATION_EXCEPTION')) {
                                returnVal = 'Failure:' + error.substringAfter('FIELD_CUSTOM_VALIDATION_EXCEPTION,');
                        }
                        else if(error.contains('DUPLICATE_VALUE')) {
                                returnVal = 'Failure:' + error.substringAfter('DUPLICATE_VALUE,');
                        }
                        else {
                                returnVal = 'Failure:' + error.remove(': []');
                        }
                        //returnVal += String.valueOf(e);

                }
                return returnVal;
        }
}