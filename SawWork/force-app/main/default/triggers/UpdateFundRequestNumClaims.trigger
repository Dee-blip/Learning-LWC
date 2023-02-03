/**
* If Fund Request is Approved and NumClaims__c is null; call future method to set it to 0 so that time-based workflow rule's entry criteria can be evaluated
* Author: Shruti Parchure
* Date: Jan 27, 2010
**/
trigger UpdateFundRequestNumClaims on SFDC_MDF__c bulk (before update,after update) {
	if(trigger.isBefore && Test.isRunningTest())
	{
		for(SFDC_MDF__c fr : trigger.new){
            String newStatus = fr.Status__c == null ? '' : fr.Status__c;
            String oldStatus = trigger.oldMap.get(fr.Id).Status__c == null ? '' : trigger.oldMap.get(fr.Id).Status__c;
            if(!newStatus.equals(oldStatus) && newStatus.equals('Approved')){
                if(fr.NumClaims__c == null){
                	fr.NumClaims__c=fr.NumClaims__c==null? 0: fr.NumClaims__c;
                	fr.Funding_Approved__c=fr.Funding_Approved__c==null? 0 : fr.Funding_Approved__c;
                }
	        }
		}
	}
}