/*
Author          : Himanshu, Vishnu
Description     : Trigger for PAC Product Feature
Called From     : 
Test Class      : L2Q_LOE_Utility_TC

Date                Developer              JIRA #                 Description                                                       
------------------------------------------------------------------------------------------------------------------
12 Jun 2020         Himanshu/Vishnu        ESESP-5155            Initial Version
------------------------------------------------------------------------------------------------------------------*/

trigger L2Q_PACFeatureTrigger on PAC_Product_Features__c (before insert, After Insert, before update, After Update) {
    
    // Before Insert Logic
    if(Trigger.isBefore && Trigger.isInsert){
       
     //   L2Q_PAC_Prod_FeatureTriggerController.updateUniqueIdValue(Trigger.new);
        L2Q_PAC_Prod_FeatureTriggerController.stampActivatedOnValue(null,Trigger.new,'Insert');
    }
    
    // Before Update Logic
    else if(Trigger.isBefore && Trigger.isUpdate){
       
        L2Q_PAC_Prod_FeatureTriggerController.stampActivatedOnValue(Trigger.oldMap,Trigger.new,'Update');
        L2Q_PAC_Prod_FeatureTriggerController.updateProductReviewRequired(Trigger.oldMap,Trigger.new);
       // L2Q_PAC_Prod_FeatureTriggerController.stampDeActivatedOnValue(Trigger.oldMap,Trigger.new);
        
    }
    
    // After Insert Logic
    else if(Trigger.isAfter && Trigger.isInsert){
        
        L2Q_PAC_Prod_FeatureTriggerController.calcOnFeatureInsert(Trigger.new);
        
    }
    
    
}