public without sharing class EditFundClaimLightningController {

    @AuraEnabled
    public static void updateFundSpender(String FDId, String FCSpender){
        
        try{
            System.debug('Calling controller :'+FDId + '----- Fc Spender :'+FCSpender);
            SFDC_MDF_Claim__c fundClaim = [Select id,
                                                Fund_Claim_Activity_Spender__c  
                                           from SFDC_MDF_Claim__c 
                                           where id=:FDId];
            System.debug('Fund claim :'+fundClaim);
            if(fundClaim != null){
                fundClaim.Fund_Claim_Activity_Spender__c = FCSpender;
                update fundClaim;
            }
            
        } catch (Exception ex){
            //Create a record for error log
            Error_log__c errorLog = new Error_log__c(Class__c = 'EditFundClaimLightningController',Error_Message__c = ex.getMessage(),RecordId__c = FDId);
            insert errorLog;
            throw ex;
        } 
        
    }    
}