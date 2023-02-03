/**
* Sets the Claim count on the on the Fund Request.
**/ 
trigger updateFundRequestWithClaimcount on SFDC_MDF_Claim__c bulk (after insert, after delete) {   
PRMTriggerClass.FCUpdateFundRequestWithClaimcountTriggerMethod(Trigger.new, Trigger.oldMap, Trigger.newMap, Trigger.old);

/*    List <SFDC_MDF__c> FRlist = new List<SFDC_MDF__c>();
    Decimal count;
    Decimal fundingAmt;
    Set<Id> frIds = new Set<Id>();
    if (Trigger.isInsert){  
        for(SFDC_MDF_Claim__c fundClaim : Trigger.new){
            frIds.add(fundClaim.Fund_Request__c);
        }       
        
        for(SFDC_MDF__c fr : [Select NumClaims__c, Funding_Approved__c From SFDC_MDF__c where Id in :frIds]){
            count = 1;
            if (fr.NumClaims__c != null){
                count = fr.NumClaims__c + 1;
            }
            fundingAmt = fr.Funding_Approved__c == null ? 0 : fr.Funding_Approved__c;
            FRlist.add(new SFDC_MDF__c(Id = fr.Id, NumClaims__c = count, Funding_Approved__c = fundingAmt));          
        }    
    } else {
        for(SFDC_MDF_Claim__c fundClaim : Trigger.old){
            frIds.add(fundClaim.Fund_Request__c);
        }
        
        for(SFDC_MDF__c fr : [Select NumClaims__c, Funding_Approved__c From SFDC_MDF__c where Id in :frIds]){
            count = 0;
            if (fr.NumClaims__c != null){
                count = fr.NumClaims__c - 1;
            }
            fundingAmt = fr.Funding_Approved__c == null ? 0 : fr.Funding_Approved__c;
            FRlist.add(new SFDC_MDF__c(Id = fr.Id, NumClaims__c = count, Funding_Approved__c = fundingAmt));          
        }   
    }
    if(!FRlist.isEmpty()){
        update FRlist;
    }
    */
}