/*=====================================================================================================+
Author              :   Aravind Perichiappan
Created             :   Sep-2021
Purpose             :   Controller for scSeclawTransitionForm lightning web component
Jira issue          :   ESESP-4522
+=====================================================================================================*/
public with sharing class SC_SecLawTransitionFormController {

    @AuraEnabled
    public static String transitionToSecLaw(String caseId, String subtype, String severity, String akamaiSpecificDetails) {
        Case c = [SELECT Id, Description, Do_Not_Show_In_Portal_Picklist__c, RecordTypeId,
                  RecordType.DeveloperName, Severity__c, Sub_Type__c, Validation_Override__c
                  FROM Case WHERE Id = :caseId];
        if(c.RecordType.DeveloperName != 'Technical') {
            return 'not technical';
        }
        Database.DMLOptions dmo = new Database.DMLOptions();
        dmo.assignmentRuleHeader.useDefaultRule = true;
        c.setOptions(dmo);
        c.RecordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'SecLaw' AND SobjectType = 'Case'].Id;
        //c.Do_Not_Show_In_Portal_Picklist__c = 'Internal Only';
        if(subtype != '') {
            c.Sub_Type__c = subtype;
        }
        if(severity == '1') {
            c.Severity__c = '1';
        }
        if(!String.isBlank(akamaiSpecificDetails)) {
            c.Description += '\n\nURL(s)/IP address(es) and the connected CP code:\n' + akamaiSpecificDetails;
        }
        c.Validation_Override__c = true;
        update c;
        return 'success';
    }

    @AuraEnabled
    public static SecLaw_Transition_Form__c getSavedFormOnCase(String caseId) {
        List<SecLaw_Transition_Form__c> form = [SELECT Id, General_Information__c, Content_on_Akamai__c,
                                                Akamai_related__c, Request_Type__c, Enough_information__c
                                                FROM SecLaw_Transition_Form__c
                                                WHERE Case__c = :caseId AND Form_Status__c = 'Incomplete' LIMIT 1];
        if(form.size() > 0) {
            return form[0];
        }
        return null;
    }

    @AuraEnabled
    public static SecLaw_Transition_Form__c getForm(String formId) {
        return [SELECT Id, Case__c, Form_Status__c, General_Information__c, Content_on_Akamai__c,
                Akamai_related__c, Request_Type__c, Enough_information__c
                FROM SecLaw_Transition_Form__c
                WHERE Id = :formId];
    }
}