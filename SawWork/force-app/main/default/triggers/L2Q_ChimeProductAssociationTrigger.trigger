/**
 * @description       : 
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 12-21-2021
 * @last modified by  : apyati 
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   11-29-2021   apyati   SFDC-8654 Added method call to create audit trails
**/
trigger L2Q_ChimeProductAssociationTrigger on Chime_Product_Association__c (after insert,before insert,before Update , after delete) {

    if(Trigger.isBefore && Trigger.isInsert){
       
        L2Q_ChimeProductAssociationController.updateChimeProductReviewRequired(trigger.new);
        //CHIME P2 to mark the Enterprise Security Product.
        L2Q_ChimeProductAssociationController.checkForEnterpriseSecurityProduct(trigger.new);
        
    }

    if(Trigger.isAfter && Trigger.isInsert){
        L2Q_ChimeProductAssociationController.createChimeFeatureLOERecords(trigger.new);
        L2Q_ChimeProductAssociationController.processAuditTrails(trigger.new,null);
    
        
    }

    if(Trigger.isBefore && Trigger.isInsert){
        L2Q_ChimeProductAssociationController.updateImplementationMode(trigger.new);
        L2Q_ChimeProductAssociationController.updateProductImplementationMode(trigger.new);
        L2Q_ChimeProductAssociationController.updateReviewRequiredField(trigger.new);

    }

   if(Trigger.isBefore && Trigger.isUpdate){
        System.debug('hereee ? ');
        L2Q_ChimeProductAssociationController.updateTotalLoEOnModeChange(trigger.new,Trigger.oldMap);
        L2Q_ChimeProductAssociationController.updateTotalLoEforCustomPOC(trigger.new,Trigger.oldMap);
        L2Q_ChimeProductAssociationController.processAuditTrails(trigger.new,trigger.oldMap);
       
    }
    if(Trigger.isAfter && Trigger.isDelete){
        // System.debug('hereee');
             L2Q_ChimeProductAssociationController.updateChimeLOEReviewStatus(trigger.old);

         }
    

}