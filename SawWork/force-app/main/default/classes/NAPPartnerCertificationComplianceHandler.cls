/**
   History
      
      --Developer       --Date         --Description
      Ruchika sharma    08/06/2020     Created this Class - SFDC-6405
    
*/
public with sharing class NAPPartnerCertificationComplianceHandler  extends ApexTriggerHandlerAbstractClass{
    public NAPPartnerCertificationComplianceHandler() {

    }
public override void beforeInsertBeforeUpdateTrigger()
    {
    
        List<NAP_Partner_Certification_Compliance__c> pccTriggerNew = (List<NAP_Partner_Certification_Compliance__c>)newList;
        List<NAP_Partner_Certification_Compliance__c> pccTriggerOld = (List<NAP_Partner_Certification_Compliance__c>)oldList;
        Map<Id,NAP_Partner_Certification_Compliance__c> pccTriggerNewMap = (Map<Id,NAP_Partner_Certification_Compliance__c>)newMap;
        Map<Id,NAP_Partner_Certification_Compliance__c> pccTriggerOldMap = (Map<Id,NAP_Partner_Certification_Compliance__c>)oldMap;

        ByPassAndLimitUtils.setAkamField(Trigger.isInsert,Trigger.isUpdate,pccTriggerNew);
        
    }

    public override void beforeDeleteBeforeUndeleteTrigger(){

    }

    public override void afterInsertAfterUpdateTrigger(){

    }

    public override void afterDeleteAfterUndeleteTrigger(){

    }
}