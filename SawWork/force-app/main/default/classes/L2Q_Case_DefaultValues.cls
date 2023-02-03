public with sharing class L2Q_Case_DefaultValues {
        public String defaultValuesForCase {get; set;}
        public String defaultRecordTypeMap {get; set;}
        public L2Q_Case_DefaultValues(ApexPages.StandardSetController stdSetCtrl) {
                RecordTypeJSON__mdt record = [SELECT MasterLabel, value__c FROM RecordTypeJSON__mdt WHERE MasterLabel = 'Case_DefaultRecordTypeMappJSON'];
                defaultRecordTypeMap = record.value__c;

                Map<String, GSM_GenericFormController.FieldDescriptor> mappOfFieldVsDefaultValues = new Map<String, GSM_GenericFormController.FieldDescriptor>();
                GSM_GenericFormController.FieldDescriptor eachSectionFields;

                if(ApexPages.currentPage().getParameters().get('OpportunityId') != null) {
                        eachSectionFields = new GSM_GenericFormController.FieldDescriptor();
                        eachSectionFields.value = ApexPages.currentPage().getParameters().get('OpportunityId');
                        mappOfFieldVsDefaultValues.put('Opportunity__c', eachSectionFields);
                }

                if(ApexPages.currentPage().getParameters().get('AccountId') != null) {
                        eachSectionFields = new GSM_GenericFormController.FieldDescriptor();
                        eachSectionFields.value = ApexPages.currentPage().getParameters().get('AccountId');
                        mappOfFieldVsDefaultValues.put('AccountId', eachSectionFields);
                }
                if(mappOfFieldVsDefaultValues.size() > 0) {
                        defaultValuesForCase = JSON.serialize(mappOfFieldVsDefaultValues);
                } else {
                        defaultValuesForCase = '';
                }
                System.DEBUG('defaultValuesForCase' + defaultValuesForCase);
        }
}