public with sharing class L2Q_MDF_DefaultValues {

        public String defaultValuesForFundRequest {get; set;}
        public String defaultValuesForFundClaim {get; set;}
        public String returnValPrefix {get; set;}
        public L2Q_MDF_DefaultValues(ApexPages.StandardController stdController) {
                System.DEBUG('stdController: ' + stdController.getRecord());
                if(ApexPages.currentPage().getParameters().get('CF00NA0000007i3NP_lkid') != null && ApexPages.currentPage().getParameters().get('CF00NA0000007i3NP_lkid') != '') {
                        // SFDC-5895 - Added By Prabhanjan
                        String urlParam = String.valueOf(ApexPages.currentPage().getParameters().get('CF00NA0000007i3NP_lkid'));
                        if(urlParam != null && urlParam != '') {
                                urlParam = String.escapeSingleQuotes(urlParam.escapeHtml4());
                        }
                        defaultValuesForFundRequest =  getDefaultValues('SFDC_MDF__c', urlParam);
                }
                else if(ApexPages.currentPage().getParameters().get('CF00NA0000007i3NE_lkid') != null && ApexPages.currentPage().getParameters().get('CF00NA0000007i3NE_lkid') != '') {
                        // SFDC-5895 - Added By Prabhanjan
                        String urlParam = String.valueOf(ApexPages.currentPage().getParameters().get('CF00NA0000007i3NE_lkid'));
                        if(urlParam != null && urlParam != '') {
                                urlParam = String.escapeSingleQuotes(urlParam.escapeHtml4());
                        }
                        defaultValuesForFundClaim = getDefaultValues('SFDC_MDF_Claim__c', urlParam);
                }
                else if(ApexPages.currentPage().getParameters().get('CF00NA0000007i3N2_lkid') != null && ApexPages.currentPage().getParameters().get('CF00NA0000007i3N2_lkid') != '') {
                        // SFDC-5895 - Added By Prabhanjan
                        String urlParam = String.valueOf(ApexPages.currentPage().getParameters().get('CF00NA0000007i3N2_lkid'));
                        if(urlParam != null && urlParam != '') {
                                urlParam = String.escapeSingleQuotes(urlParam.escapeHtml4());
                        }
                        defaultValuesForFundClaim = getDefaultValues('SFDC_MDF_Claim__c',urlParam);
                } //SFDC-3285
                else if(ApexPages.currentPage().getParameters().get(GsmUtilClass.getGSMSettingValue('FR_PM_Relationship_Id')) != null && ApexPages.currentPage().getParameters().get(GsmUtilClass.getGSMSettingValue('FR_PM_Relationship_Id')) != ''){
                        //System.debug(LoggingLevel.ERROR,'pages:: '+ApexPages.currentPage().getParameters().get('CF00N0f00000FSPFY_lkid'));
                        // SFDC-5895 - Added By Prabhanjan
                        String urlParam = String.valueOf(ApexPages.currentPage().getParameters().get(GsmUtilClass.getGSMSettingValue('FR_PM_Relationship_Id')));
                        if(urlParam != null && urlParam != '') {
                                urlParam = String.escapeSingleQuotes(urlParam.escapeHtml4());
                        }
                        defaultValuesForFundRequest = getPartnerMarketingValuesOf_SFDC_MDF(urlParam);
                        //defaultValuesForFundRequest +=  getDefaultValues('SFDC_MDF__c', '');
                    }
                else if(stdController.getRecord()!= null && String.valueOf(stdController.getRecord()).contains('SFDC_MDF__c')) {
                        defaultValuesForFundRequest =  getDefaultValues('SFDC_MDF__c', '');
                }
                else if(stdController.getRecord()!= null && String.valueOf(stdController.getRecord()).contains('SFDC_MDF_Claim__c')) {
                        defaultValuesForFundClaim = getDefaultValues('SFDC_MDF_Claim__c', '');
                }
                else {
                        defaultValuesForFundRequest = '';
                        defaultValuesForFundClaim = '';
                }

                if(CurrentUser.attributes.get('Partner Account') != null &&
                   CurrentUser.attributes.get('Partner Account') != '') {
                        returnValPrefix = '/partners';
                } else {
                        returnValPrefix = '';
                }
        }

        public L2Q_MDF_DefaultValues() {

        }

        @AuraEnabled
        public static String getDefaultValues(String sObjectName, String recId) {
                if(sObjectName == 'SFDC_MDF__c') {
                        return getDefaultValuesOf_SFDC_MDF(recId);
                }
                else if(sObjectName == 'SFDC_MDF_Claim__c') {
                        return getDefaultValuesOf_SFDC_MDF_Claim(recId);
                }
                return null;
        }

        public static String getDefaultValuesOf_SFDC_MDF(String recId) {
                GSM_GenericFormController.FieldDescriptor eachSectionFields = new GSM_GenericFormController.FieldDescriptor();
                Map<String, GSM_GenericFormController.FieldDescriptor> mappOfFieldVsDefaultValues = new Map<String, GSM_GenericFormController.FieldDescriptor>();
                //Account__c
                eachSectionFields = new GSM_GenericFormController.FieldDescriptor();
                if(CurrentUser.attributes.get('Partner Account') != null &&
                   CurrentUser.attributes.get('Partner Account') != '') {
                        eachSectionFields.value = CurrentUser.attributes.get('Partner Account');
                } else if(recId!= null && recId!= '') {
                        eachSectionFields.value = recId;
                }
                mappOfFieldVsDefaultValues.put('Account__c', eachSectionFields);

                //CurrencyIsoCode
                eachSectionFields = new GSM_GenericFormController.FieldDescriptor();
                String recordId = null;
                if(recId != null && recId!= '') {
                        recordId = recId;
                } else if(CurrentUser.attributes.get('Partner Account') != null &&
                          CurrentUser.attributes.get('Partner Account') != '') {
                        recordId = CurrentUser.attributes.get('Partner Account');
                }
                if(recordId != null && recordId!= '') {
                        account acc = [Select Default_MDF_Currency__c from Account where Id = :recordId];
                        if(acc != null && acc.Default_MDF_Currency__c != null) {
                                eachSectionFields.pickListVals.add(acc.Default_MDF_Currency__c);
                                eachSectionFields.value = acc.Default_MDF_Currency__c;
                        }
                }
                mappOfFieldVsDefaultValues.put('CurrencyIsoCode', eachSectionFields);

                System.DEBUG('mappOfFieldVsDefaultValues: ' + mappOfFieldVsDefaultValues);
                return JSON.serialize(mappOfFieldVsDefaultValues);
        }

        public static String getDefaultValuesOf_SFDC_MDF_Claim(String recId) {
                GSM_GenericFormController.FieldDescriptor eachSectionFields = new GSM_GenericFormController.FieldDescriptor();
                Map<String, GSM_GenericFormController.FieldDescriptor> mappOfFieldVsDefaultValues = new Map<String, GSM_GenericFormController.FieldDescriptor>();
                //Account__c
                eachSectionFields = new GSM_GenericFormController.FieldDescriptor();
                if(CurrentUser.attributes.get('Partner Account') != null &&
                   CurrentUser.attributes.get('Partner Account') != '') {
                        eachSectionFields.value = CurrentUser.attributes.get('Partner Account');
                }//SFDC-4261 a25
                else if(recId!= null && recId!= '' && Id.valueOf(recId).getSObjectType() == Schema.SFDC_MDF__c.SObjectType){
                    SFDC_MDF__c fundReq = [select Account__c from SFDC_MDF__c where id=:recId];
                    eachSectionFields.value = fundReq.Account__c;
                }
                if(recId != '' && recId != null && Id.valueOf(recId).getSObjectType() == Schema.Account.SObjectType) {
                        eachSectionFields.value = recId;
                }
                mappOfFieldVsDefaultValues.put('Account__c', eachSectionFields);

                // Fund_Request__c
                eachSectionFields = new GSM_GenericFormController.FieldDescriptor();
                if(recId!= null && recId!= '' && Id.valueOf(recId).getSObjectType() == Schema.SFDC_MDF__c.SObjectType) {
                        eachSectionFields.value = recId;
                }
                mappOfFieldVsDefaultValues.put('Fund_Request__c', eachSectionFields);

                //CurrencyIsoCode
                eachSectionFields = new GSM_GenericFormController.FieldDescriptor();
                if(recId != null && recId!= '' && (Id.valueOf(recId).getSObjectType() == Schema.SFDC_MDF__c.SObjectType)) {
                        SFDC_MDF__c fundReq = [Select CurrencyIsoCode from SFDC_MDF__c
                                               where Id = :recId];
                        if(fundReq != null && fundReq.CurrencyIsoCode != null) {
                                eachSectionFields.pickListVals.add(fundReq.CurrencyIsoCode);
                                eachSectionFields.value = fundReq.CurrencyIsoCode;
                        }
                }
                if((CurrentUser.attributes.get('Partner Account') != null &&
                    CurrentUser.attributes.get('Partner Account') != '')) {
                        String partnerAccId = CurrentUser.attributes.get('Partner Account');
                        Account partAcc = [Select Default_MDF_Currency__c from Account where Id = :partnerAccId];
                        if(partAcc != null && partAcc.Default_MDF_Currency__c != null) {
                                eachSectionFields.value = partAcc.Default_MDF_Currency__c;
                        }
                }
                if(recId != '' && recId != null && Id.valueOf(recId).getSObjectType() == Schema.Account.SObjectType) {
                        Account acc = [SELECT Default_MDF_Currency__c FROM Account WHERE Id = :recId];
                        if(acc != null && acc.Default_MDF_Currency__c != null) {
                                eachSectionFields.value = acc.Default_MDF_Currency__c;
                        }
                }
                mappOfFieldVsDefaultValues.put('CurrencyIsoCode', eachSectionFields);

                //System.DEBUG('mappOfFieldVsDefaultValues: ' + mappOfFieldVsDefaultValues);
                return JSON.serialize(mappOfFieldVsDefaultValues);
        }
         //SFDC-3285
    public static String getPartnerMarketingValuesOf_SFDC_MDF(String recId) {
        if(String.isBlank(recId))
            return '';

        Partner_Marketing_Activity__c pma = [select Id, Indirect_Campaign__c, Partner__c,Partner__r.Default_MDF_Currency__c from Partner_Marketing_Activity__c where id=:recId];
        Map<String, GSM_GenericFormController.FieldDescriptor> mappOfFieldVsDefaultValues = new Map<String, GSM_GenericFormController.FieldDescriptor>();
        GSM_GenericFormController.FieldDescriptor eachSectionFields = new GSM_GenericFormController.FieldDescriptor();
        String mappOfFieldVsDefaultValue = getDefaultValues('SFDC_MDF__c', '');
        mappOfFieldVsDefaultValues = (Map<String, GSM_GenericFormController.FieldDescriptor>)System.JSON.deserialize(mappOfFieldVsDefaultValue, Map<String, GSM_GenericFormController.FieldDescriptor>.class);
        System.debug(LoggingLevel.ERROR,'mappOfFieldVsDefaultValues:: '+mappOfFieldVsDefaultValues);
        //SFDC-4460
        if(pma.Id != null) {
            eachSectionFields.value = pma.Id;
            mappOfFieldVsDefaultValues.put('Partner_Marketing_Activity__c', eachSectionFields);
        }
        if(pma.Indirect_Campaign__c!=null){
            eachSectionFields = new GSM_GenericFormController.FieldDescriptor();
            eachSectionFields.value=pma.Indirect_Campaign__c;
            mappOfFieldVsDefaultValues.put('Fund_Request_Campaign__c', eachSectionFields);
        }
        if(pma.Partner__c!=null){
            eachSectionFields = new GSM_GenericFormController.FieldDescriptor();
            eachSectionFields.value=pma.Partner__c;
            mappOfFieldVsDefaultValues.put('Account__c', eachSectionFields);
        }
        if(pma.Partner__r.Default_MDF_Currency__c!=null){
            eachSectionFields = new GSM_GenericFormController.FieldDescriptor();
            eachSectionFields.value=pma.Partner__r.Default_MDF_Currency__c;
            eachSectionFields.pickListVals.add(pma.Partner__r.Default_MDF_Currency__c);
            mappOfFieldVsDefaultValues.put('CurrencyIsoCode', eachSectionFields);   
        }
        System.debug(LoggingLevel.ERROR,'mappOfFieldVsDefaultValues again:: '+mappOfFieldVsDefaultValues);
        return JSON.serialize(mappOfFieldVsDefaultValues);
    }
}