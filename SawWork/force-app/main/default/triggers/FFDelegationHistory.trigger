/*
 * CR: FFPSA-142
 * Developer: Sujay
 * Enhancement: This trigegr captures all FF_Delegation_History__c which will send email alerts when Delegated approver is set/ removed in Custom page
 * Date: 26th Feb 2018
 
 * 
*/ 
trigger FFDelegationHistory on FF_Delegation_History__c (after insert, after update) {
    
  if (Trigger.IsAfter && (Trigger.isInsert || Trigger.isUpdate)) 
    {

      PSA_FFDelegationHistoryHandler delegationHistory = new PSA_FFDelegationHistoryHandler();
      delegationHistory.sendEmailAlertOnInsertOrUpdate(trigger.newMap, trigger.oldMap, Trigger.isInsert);
        
        if(! Trigger.isInsert){
            
            PSA_FFDelegationHistoryHandler delHistory = new PSA_FFDelegationHistoryHandler();
            System.debug('Sending Before Update Records');
            delHistory.validateHistoryStampPendingTcs(trigger.oldMap, trigger.newMap);
            
        }
        
    }

}