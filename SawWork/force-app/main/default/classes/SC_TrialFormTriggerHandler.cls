/****************************************************************************
* Class name          :   SC_TrialFormTriggerHandler.cls
* Author              :   Vishnu Vardhan
* Created             :   20-August-2020
* Purpose             :   TRF Trigger Handler
* Test Class          :   
-------------------------------------------------------------------------------
* MethodName          : Purpose
-------------------------------------------------------------------------------
* +handleBeforeUpdateTrigger    :  Before Insert Handler for TRF trigger

* -accessCheck                  :  Validation: if Current User has access to update TRF
*****************************************************************************

DATE             DEVELOPER        CR              DESCRIPTION
===========      =========        =======         ===========
Aug 20, 2020     Vishnu Vardhan   ESESP-2826      Only Case Creator or PST Queue members can edit TRF
*****************************************************************************/

public with sharing class SC_TrialFormTriggerHandler extends SC_TriggerHandlerAbstract{

    static final String INSUFF_ACCESS = 'Only Case Creator or PST Queue Member can edit Trial Request Form';

    // PST Queues
    static Set<String> pstQueues {
        get {
            if(pstQueues == null) {
                pstQueues = new Set<String>();
                for( SC_PST_Metadata__mdt mInfo: [select id, key1__c, value1__c from SC_PST_Metadata__mdt where scope__c = 'PstQueues']) {
                    pstQueues.add(mInfo.key1__c);
                }
            }
            return pstQueues;
        }
        set;
    }

    //handleBeforeUpdateTrigger    :  Before Insert Handler for TRF trigger
    public override void handleBeforeUpdate() {
        List<SC_Trial_Request_Form__c> newList = Trigger.new;
        accessCheck(newList);
    }

    //accessCheck                  :  Validation: Only Case Creator/ PST Queue Members can edit Trial Request Form
    static void accessCheck(List<SC_Trial_Request_Form__c> newList) {

        Id currentUserId = System.UserInfo.getUserId();
        List<GroupMember> queueMembership = [select id from GroupMember where 
                                                group.DeveloperName in :pstQueues and 
                                                group.type = 'Queue' and 
                                                UserOrGroupId = :currentUserId];
        Boolean noAccess = queueMembership.isEmpty(); 
        Map<Id, SC_Trial_Request_Form__c> queriedTrfMap = new Map<Id, SC_Trial_Request_Form__c>(
                                                    [select id, CreatedById, (select id, createdbyid from cases__r) from SC_Trial_Request_Form__c where id in :newList]);
        
        for(SC_Trial_Request_Form__c trf: newList) {
            List<Case> trfCases = queriedTrfMap.get(trf.id).cases__r;
            Boolean isCaseCreator = trfCases.size() == 0 || trfCases[0].CreatedById == currentUserId;
            if(!isCaseCreator && noAccess) {
                trf.addError(INSUFF_ACCESS);
            }
        }
    }
    
}