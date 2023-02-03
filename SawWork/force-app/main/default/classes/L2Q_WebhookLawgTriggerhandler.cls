public without sharing class L2Q_WebhookLawgTriggerhandler extends ApexTriggerHandlerAbstractClass {
    public override void beforeInsertBeforeUpdateTrigger(){
        List<WebhookLawg__c> newHookList = (List<WebhookLawg__c>) newList;
        List<WebhookLawg__c> oldHookList = (List<WebhookLawg__c>) oldList;

        Map<Id, WebhookLawg__c> newHookMap = (Map<Id, WebhookLawg__c>)newMap;
        Map<Id, WebhookLawg__c> oldHookMap = (Map<Id, WebhookLawg__c>)oldMap;

        if(Trigger.isInsert) {
            if(newHookList.size() > 0) {
                L2Q_WebhookLawgTriggerClass.extractDocuSignEnvelopFromLawgs(newHookList);
            }
        }

    }
    public override void beforeDeleteBeforeUndeleteTrigger(){}
    public override void afterInsertAfterUpdateTrigger(){}
    public override void afterDeleteAfterUndeleteTrigger(){}
}