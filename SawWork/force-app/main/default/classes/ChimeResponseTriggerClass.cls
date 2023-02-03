/**

**/
public class ChimeResponseTriggerClass {
    //SFDC-7844 : @nadesai -Start

    private static CHIME_Audit_Trail__c createTrailForResponse(CHIME_Response__c eachResponse, CHIME_Response__c oldResponse) {
        CHIME_Audit_Trail__c eachTrail = new CHIME_Audit_Trail__c();
        eachTrail.CHIME_Response__c = eachResponse.Id;
        eachTrail.CurrentValue__c = eachResponse.Response__c;
        if(eachResponse.Chime_Form_Status__c == 'Reopened'){
            eachTrail.Modified_after_Reopen__c=true;
        }
        eachTrail.CHIME__c = eachResponse.CHIME__c;
        eachTrail.Source__c = 'CHIME Response';
        if((Network.getNetworkId() != null && GSMSettings.getValue('communitiesForChimeAuditTrail').contains(String.valueOf(Network.getNetworkId())))) {
            eachTrail.isCustomerUpdated__c = true;
        }
        //old response can be null during insert
        if(oldResponse != null) {
            eachTrail.PreviousValue__c = oldResponse.Response__c;
        }
        else {
            eachTrail.PreviousValue__c = '';
        }
        return eachTrail;
    }

    public static void createAuditTrails(List<CHIME_Response__c> newResponses, Map<Id,CHIME_Response__c> chimeResponseTriggerOldMap) {
        List<CHIME_Audit_Trail__c> auditTrails = new List<CHIME_Audit_Trail__c>();
        for(CHIME_Response__c eachResponse : newResponses) {
            //old response can be null during insert
            CHIME_Response__c oldResponse = (chimeResponseTriggerOldMap != null && chimeResponseTriggerOldMap.containsKey(eachResponse.Id)) ? chimeResponseTriggerOldMap.get(eachResponse.Id) : null;
            auditTrails.add(createTrailForResponse(eachResponse, oldResponse));
        }
        if(auditTrails.size() > 0) {
            try {
                insert auditTrails;
            }
            catch(Exception e) {
                Sawyer.saw(e);
            }
        }
    }
    //SFDC-7844 : @nadesai -End

    public static void processAuditTrails(List<CHIME_Response__c> chimeResponseTriggerNew, Map<Id,CHIME_Response__c> chimeResponseTriggerOldMap){
        List<CHIME_Response__c> allResponses = new List<CHIME_Response__c>();
        for(CHIME_Response__c eachResponse : chimeResponseTriggerNew) {
            
            // SFDC-7761 Save Audit trail for (a) Customer Responses (b) Integration - Reopened Forms
            // Do not save audit trails if response hasn't changed or only changed in styling
            if((eachResponse.Response_by_Customer__c || (eachResponse.Chime_Form_Stage__c == 'Integration' && eachResponse.Chime_Form_Status__c == 'Reopened'))
            && (chimeResponseTriggerOldMap == null || (chimeResponseTriggerOldMap.get(eachResponse.Id).Response__c == null && eachResponse.Response__c != null) || (chimeResponseTriggerOldMap.get(eachResponse.Id).Response__c != null && eachResponse.Response__c == null) || (chimeResponseTriggerOldMap.get(eachResponse.Id).Response__c != null && eachResponse.Response__c != null && chimeResponseTriggerOldMap.get(eachResponse.Id).Response__c.stripHtmlTags() != eachResponse.Response__c.stripHtmlTags()))) {
                allResponses.add(eachResponse);
            }
        }
        if(allResponses.size() > 0) {
            ChimeResponseTriggerClass.createAuditTrails(allResponses, chimeResponseTriggerOldMap);
        }
    }
}