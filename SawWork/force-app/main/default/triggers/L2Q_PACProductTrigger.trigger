/*
Author          : Himanshu, Vishnu, Sujay
Description     : Trigger for PAC Product
Called From     : 
Test Class      : L2Q_LOE_Utility_TC

Date                Developer              JIRA #                 Description                                                       
------------------------------------------------------------------------------------------------------------------
12 Jun 2020         Himanshu/Vishnu        ESESP-5155            Initial Version
------------------------------------------------------------------------------------------------------------------*/

trigger L2Q_PACProductTrigger on PAC_Product_Catalog__c (After Insert,before insert,before update, after Update) {

    // List to Store All Active Product on Insert
    set<ID> allActiveProd_frmInsert = new set<ID>();
    
    // After Insert Event
    if(Trigger.isAfter && Trigger.isInsert){
    
        // Loop for All the Products
        for(PAC_Product_Catalog__c eachProd : Trigger.New){
        
            // Use Case - 1: If Product is Active, then Send Email to Questionare Admin Team
            if(eachProd.IsActive__c){
                allActiveProd_frmInsert.add(eachProd.ID);
            }
        }
        
        // Call to Helper Method to send Email
        if(allActiveProd_frmInsert.size() > 0)
            L2Q_PAC_Prod_FeatureTriggerController.sendEmailtoQunAdmin(allActiveProd_frmInsert);
    }
   
    // Before Update Event
    if(Trigger.isBefore && Trigger.isUpdate){
       
       L2Q_PAC_Prod_FeatureTriggerController.beforeUpdateLogic(Trigger.oldMap,Trigger.new);
    }
    

    psa_Common_Setting__mdt addOnIntegration = [select Id, value__c from psa_Common_Setting__mdt where type__c = 'PAC - SFDC'];

    if(addOnIntegration.value__c == 'yes')
    {
        // After Insert / After Update
        // Sujay : changes for Add-on Integration
        if(Trigger.isBefore && (Trigger.isInsert || Trigger.isUpdate))
        {
            //if changes is flown from MuleProfile or Sysadmin Profile only
            if(UserInfo.getProfileId() == '00e4R000001IzaiQAC' || UserInfo.getProfileId() == '00eA0000000VTG1IAO')
            {
                L2Q_PAC_Prod_FeatureTriggerController.syncAdditionalAttributesforAddOns(Trigger.new, Trigger.oldMap, Trigger.isInsert);
            }
        } 
        
        
        // Sujay : changes for Add-on Integration, during this chnage it will create/update the Juntion object
        if(Trigger.isAfter && Trigger.isUpdate)
        {
            //if changes is flown from MuleProfile or Sysadmin Profile only
            if(UserInfo.getProfileId() == '00e4R000001IzaiQAC' || UserInfo.getProfileId() == '00eA0000000VTG1IAO')
            {
                L2Q_PAC_Prod_FeatureTriggerController.addorModifyJunctionObject(Trigger.new, Trigger.oldMap);
            }
        
        }  

    }
    
      
    
}