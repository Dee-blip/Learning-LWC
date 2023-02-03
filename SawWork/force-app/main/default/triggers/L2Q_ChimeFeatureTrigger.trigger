trigger L2Q_ChimeFeatureTrigger on Chime_Features_LoE__c (before delete) {
    L2Q_ChimeFeatureTriggerController.updateProductLOE(trigger.old);
}