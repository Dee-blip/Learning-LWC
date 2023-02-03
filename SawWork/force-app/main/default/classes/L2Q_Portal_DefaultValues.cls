public class L2Q_Portal_DefaultValues {
    
    public String defaultValuesForLead {get; set;}
    public String returnValPrefix {get; set;}
    
    public pagereference RedirectCheck()
    {
        Boolean redirect = true;
        Id recordTypeId = ApexPages.currentPage().getParameters().get('RecordType');
        Set<String> profiles = new Set<String>();
        profiles.add('Partner Community Admin');
        profiles.add('Partner Community User');
        List<Profile> profileList = [Select id From Profile where name IN:profiles];
        Set<Id> profileIds = new Set<Id>();
        if (profileList != null && profileList.size() > 0) {
            for (Profile p:profileList) {
                profileIds.add(p.id);
            }
        } 
        if (profileIds.contains(UserInfo.getProfileId())) {
            redirect = false;
        }
        /*String partnerLeadRecordTypeId = [Select id From RecordType where name = 'Partner Lead'].id;
        if(redirect && !partnerLeadRecordTypeId.contains(ApexPages.currentPage().getParameters().get('RecordType'))){
            redirect = false; 
        }*/
        
        if (redirect) {
            String hostname = ApexPages.currentPage().getHeaders().get('Host');
            String optyURL2 = '/00Q/e?retURL=%2F00Q%2Fo&RecordType='+recordTypeId+'&ent=Lead&nooverride=1';
            pagereference pageref = new pagereference(optyURL2);
            pageref.setredirect(true);
            return pageref;
        }
        else
            return null;
    }
    
    public L2Q_Portal_DefaultValues(ApexPages.StandardController stdController) {
        System.DEBUG('stdController: ' + stdController.getRecord());
        defaultValuesForLead =  getDefaultValues('Lead', '');
        
        if(CurrentUser.attributes.get('Partner Account') != null &&
           CurrentUser.attributes.get('Partner Account') != '') {
               returnValPrefix = '/partners';
           } else {
               returnValPrefix = '';
           }
    }
    
    public L2Q_Portal_DefaultValues() {
        
    }

    @AuraEnabled
    public static String getDefaultValues(String sObjectName) {
        return getDefaultValues(sObjectName, '');
    }


    
    @AuraEnabled
    public static String getDefaultValues(String sObjectName, String recId) {
        if(sObjectName == 'Lead') {
            return getDefaultValuesOf_Lead(recId);
        }
        if(sObjectName == 'Case') {
            return getDefaultValuesOf_Case(recId);
        }
        if(sObjectName == 'Contact') {
            return getDefaultValuesOf_Contact(recId);
        }
        return null;
    }
    
    public static String getDefaultValuesOf_Lead(String recId) {
        GSM_GenericFormController.FieldDescriptor eachSectionFields = new GSM_GenericFormController.FieldDescriptor();
        Map<String, GSM_GenericFormController.FieldDescriptor> mappOfFieldVsDefaultValues = new Map<String, GSM_GenericFormController.FieldDescriptor>();
        
        eachSectionFields = new GSM_GenericFormController.FieldDescriptor();
        eachSectionFields.value = UserInfo.getUserId();
        eachSectionFields.fieldType = 'REFERENCE';
        eachSectionFields.isDynamicLookup = true;
        eachSectionFields.referenceFieldType = 'USER';
        eachSectionFields.fieldAPIName = 'OwnerId';
        eachSectionFields.isReadOnly = true;
        mappOfFieldVsDefaultValues.put('OwnerId', eachSectionFields);
        
        eachSectionFields = new GSM_GenericFormController.FieldDescriptor();
        Id partnerAccountId = getLoginInUserPartnerAccountId(UserInfo.getUserId());
        eachSectionFields.value = partnerAccountId;
        eachSectionFields.fieldType = 'REFERENCE';
        eachSectionFields.isDynamicLookup = true;
        eachSectionFields.referenceFieldType = 'Account';
        eachSectionFields.isReadOnly = true;
        mappOfFieldVsDefaultValues.put('Partner_Involved__c', eachSectionFields);
        
        System.DEBUG('mappOfFieldVsDefaultValues: ' + mappOfFieldVsDefaultValues);
        return JSON.serialize(mappOfFieldVsDefaultValues);
    }

    public static String getDefaultValuesOf_Case(String recId) {
        GSM_GenericFormController.FieldDescriptor eachSectionFields = new GSM_GenericFormController.FieldDescriptor();
        Map<String, GSM_GenericFormController.FieldDescriptor> mappOfFieldVsDefaultValues = new Map<String, GSM_GenericFormController.FieldDescriptor>();
        
        eachSectionFields = new GSM_GenericFormController.FieldDescriptor();
        eachSectionFields.value = UserInfo.getUserId();
        eachSectionFields.fieldType = 'REFERENCE';
        eachSectionFields.isDynamicLookup = true;
        eachSectionFields.referenceFieldType = 'USER';
        eachSectionFields.fieldAPIName = 'OwnerId';
        eachSectionFields.isReadOnly = true;
        eachSectionFields.isUpdatable = false;
        mappOfFieldVsDefaultValues.put('OwnerId', eachSectionFields);
        
        List<String> pickListValues = new List<String>();
        pickListValues.add('1 - Immediate Customer Impact');
        pickListValues.add('2 - Can\'t Perform Job');
        pickListValues.add('3 - Difficult to do Job');
        pickListValues.add('4 - Minor Problem or Question');
        eachSectionFields = new GSM_GenericFormController.FieldDescriptor();
        Id partnerAccountId = getLoginInUserPartnerAccountId(UserInfo.getUserId());
        eachSectionFields.value = '4 - Minor Problem or Question';
        eachSectionFields.fieldType = 'PICKLIST';
        eachSectionFields.isReadOnly = true;
        eachSectionFields.pickListVals = pickListValues;
        mappOfFieldVsDefaultValues.put('Severity__c', eachSectionFields);

        eachSectionFields = new GSM_GenericFormController.FieldDescriptor();
        eachSectionFields.value = 'Medium';
        eachSectionFields.fieldType = 'PICKLIST';
        eachSectionFields.isReadOnly = true;
        eachSectionFields.isUpdatable = false;
        mappOfFieldVsDefaultValues.put('Priority', eachSectionFields);

        List<String> pickListValuesForStatus = new List<String>();
        pickListValuesForStatus.add('New');
        pickListValuesForStatus.add('On Hold');
        pickListValuesForStatus.add('Closed - Duplicate');
        pickListValuesForStatus.add('Closed');
        eachSectionFields = new GSM_GenericFormController.FieldDescriptor();
        eachSectionFields.value = 'New';
        eachSectionFields.fieldType = 'PICKLIST';
        eachSectionFields.isReadOnly = true;
        eachSectionFields.pickListVals = pickListValuesForStatus;
        mappOfFieldVsDefaultValues.put('Status', eachSectionFields);
        
        System.DEBUG('mappOfFieldVsDefaultValues: ' + mappOfFieldVsDefaultValues);
        return JSON.serialize(mappOfFieldVsDefaultValues);
    }
    
    public static String getDefaultValuesOf_Contact(String recId) {
        GSM_GenericFormController.FieldDescriptor eachSectionFields = new GSM_GenericFormController.FieldDescriptor();
        Map<String, GSM_GenericFormController.FieldDescriptor> mappOfFieldVsDefaultValues = new Map<String, GSM_GenericFormController.FieldDescriptor>();
        
        eachSectionFields = new GSM_GenericFormController.FieldDescriptor();
        eachSectionFields.value = getLoginInUserPartnerAccountId(UserInfo.getUserId());
        eachSectionFields.fieldType = 'REFERENCE';
        eachSectionFields.isDynamicLookup = true;
        eachSectionFields.referenceFieldType = 'Account';
        eachSectionFields.fieldAPIName = 'OwnerId';
        eachSectionFields.isReadOnly = false;
        eachSectionFields.isUpdatable = true;
        mappOfFieldVsDefaultValues.put('AccountId', eachSectionFields);
        
        System.DEBUG('mappOfFieldVsDefaultValues: ' + mappOfFieldVsDefaultValues);
        return JSON.serialize(mappOfFieldVsDefaultValues);
    }
    
    public static string getLoginInUserPartnerAccountId(Id userId) {
        return [Select id, Contact.AccountId From User where id =:userId].Contact.AccountId;
        
    }
}