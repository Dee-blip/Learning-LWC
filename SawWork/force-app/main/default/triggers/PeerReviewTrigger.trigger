/*---------------------------------------------------------------------------------
    Class name          :   PeerReviewTrigger
    Test Class          :   
    Author              :   Bhavesh
    Created             :   
    JIRA                :   ESESP-3590
    Purpose             :   Trigger for Peer_Reviewer__c object.
             
    Last Modified         Developer                 Purpose            
    ============= ========================         ==========

* --------------------------------------------------------------------------------*/
trigger PeerReviewTrigger on Peer_Reviewer__c (before insert, before update) {
    List<Id> caseIds = new List<Id>();
    List<Id> peerReviewerList = new List<Id>();

    if( (Trigger.isInsert || Trigger.isUpdate) && Trigger.isBefore ){
        for( Peer_Reviewer__c pr : Trigger.New ){
            caseIds.add(pr.Case__c);
            peerReviewerList.add(pr.Reviewer_Name__c);
        }
        if(caseIds.size()>0){
            SC_CaseTriggerHelperClass3.checkRcaIraptReviewerCondition(caseIds, peerReviewerList, Trigger.New);
        }
    }

    

}