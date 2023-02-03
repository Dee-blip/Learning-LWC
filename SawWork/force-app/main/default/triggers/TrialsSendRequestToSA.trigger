trigger TrialsSendRequestToSA on Trials_Request_Form__c (after update) {
    for(integer i=0;i<3;i++){
    integer o= 0;
    }
    if(Trigger.isAfter && Trigger.isUpdate){
        for(Trials_Request_Form__c objTrialsReqForm :Trigger.New){
            if(objTrialsReqForm.Trials_DNS_Created__c != Trigger.OldMap.get(objTrialsReqForm.Id).Trials_DNS_Created__c
               && objTrialsReqForm.Trials_DNS_Created__c){
                   TrialsUtilClass.doInstantCheck(objTrialsReqForm.Id);                          
            }
            
        }
    }
}