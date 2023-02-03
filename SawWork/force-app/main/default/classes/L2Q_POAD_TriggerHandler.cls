/*
@nadesai adding this class as part of SFDC-7665 : Prevent duplicate POAs getting created, add a toggle if additional functionalities are getting added
Moved the existing code in partnerorderAcceptance_bi_bu to this class
*/
public with sharing class L2Q_POAD_TriggerHandler extends ApexTriggerHandlerAbstractClass{
    public override void beforeInsertBeforeUpdateTrigger(){
        List<Partner_Order_Acceptance_Document__c> poadListNew = (List<Partner_Order_Acceptance_Document__c>)newList;
        List<Partner_Order_Acceptance_Document__c> poadListOld = (List<Partner_Order_Acceptance_Document__c>)oldList;
        Map<Id, Partner_Order_Acceptance_Document__c> poadNewMap = (Map<Id, Partner_Order_Acceptance_Document__c>)newMap;
        Map<Id, Partner_Order_Acceptance_Document__c> poadOldMap = (Map<Id, Partner_Order_Acceptance_Document__c>)oldMap;


        //  Code By Rahul : AKAM field updation Through The code
        Id CrmIntegration = Id.valueOf(GsmUtilClass.getGSMSettingValue('CRM_Integration'));

        Set<String> setOfDistinctPoads = new Set<String>(); //SFDC-7653 - nadesai
        Boolean evadePOADuplicatesFlag = GsmUtilClass.isFeatureToggleEnabledCustomMetadata('evadePOADuplicates');

        for(Partner_Order_Acceptance_Document__c poad : poadListNew) {
        //This code takes care OF AKAM fields while insert if any of these field is null or Empty
            if(Trigger.isInsert){
                if((UserInfo.getUserId() == CrmIntegration && (poad.AKAM_Created_By__c =='' || 
                poad.AKAM_Created_Date__c == null ||poad.AKAM_System__c =='')) || UserInfo.getUserId() != CrmIntegration ) {
                    poad.AKAM_Created_By__c = poad.AKAM_Alias__c ;
                    poad.AKAM_Created_Date__c = system.now();
                    poad.AKAM_System__c ='FORCE';
                }
                // SFDC-7653 - nadesai Start
                if(evadePOADuplicatesFlag ) {
                    if(poad.ContenDocumentId__c != null && setOfDistinctPoads.contains(String.valueOf(poad.ContenDocumentId__c))) {
                        poad.Order_Acceptance_Status__c = 'Voided';
                    }
                    setOfDistinctPoads.add(String.valueOf(poad.ContenDocumentId__c));
                }
                // SFDC-7653 - nadesai End
            }      
            // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
            if((UserInfo.getUserId() == CrmIntegration && (poad.AKAM_Modified_Date__c  == null|| 
                poad.AKAM_Modified_By__c == '' || poad.AKAM_Modified_By__c == null)) || UserInfo.getUserId() != CrmIntegration )  {
                    poad.AKAM_Modified_By__c = poad.AKAM_Alias__c;
                    poad.AKAM_Modified_Date__c =  system.now();  
            }
        }
    }
    public override void beforeDeleteBeforeUndeleteTrigger(){
    }
    public override void afterInsertAfterUpdateTrigger(){
        List<Partner_Order_Acceptance_Document__c> poadListNew = (List<Partner_Order_Acceptance_Document__c>)newList;
        List<Partner_Order_Acceptance_Document__c> poadListOld = (List<Partner_Order_Acceptance_Document__c>)oldList;
        Map<Id, Partner_Order_Acceptance_Document__c> poadNewMap = (Map<Id, Partner_Order_Acceptance_Document__c>)newMap;
        Map<Id, Partner_Order_Acceptance_Document__c> poadOldMap = (Map<Id, Partner_Order_Acceptance_Document__c>)oldMap;
        //SFDC - 1440
        if(Trigger.isUpdate) {
            List<Partner_Order_Acceptance_Document__c> caseCreationForPoad = new List<Partner_Order_Acceptance_Document__c>();
            for(Partner_Order_Acceptance_Document__c poad : poadListNew) {
                if(poadOldMap.get(poad.Id).Order_Acceptance_Status__c != poadNewMap.get(poad.Id).Order_Acceptance_Status__c && poadNewMap.get(poad.Id).Order_Acceptance_Status__c == 'Accepted') {
                //Need to write logic to create case and update PBT field for these Order Acceptance Documents
                    caseCreationForPoad.add(poad);
                }
            }
            
            if(caseCreationForPoad.size() > 0) {
                PartnerOrderAcceptanceClass.createCaseForPoad(caseCreationForPoad);
            }
        }    
        //End of SFDC-1440
    }
    public override void afterDeleteAfterUndeleteTrigger(){
    }
}