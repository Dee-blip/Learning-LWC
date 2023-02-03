/**
   @author: Nagaraj Desai
   SFDC-2587 : Formalize Partner Order Cancellation
 * History:
 * =========================
 * Developer        Date        Description

   Nagaraj Desai    15/Apr/18        Added this class for SFDC-2587.
   =========================
   Related Test Class: PartnerOrderCancellationTriggerTestClass
 **/
public with sharing class PartnerOrderCancellation_TriggerHandler extends ApexTriggerHandlerAbstractClass {
        public PartnerOrderCancellation_TriggerHandler() {
        }

        public override void beforeInsertBeforeUpdateTrigger() {
                List<Partner_Order_Cancellation_Details__c> listOfPOCD = new List<Partner_Order_Cancellation_Details__c>();

                for(SObject eachSObject : newList) {
                        if(Trigger.isInsert) {
                                Partner_Order_Cancellation_Details__c newPOCD = (Partner_Order_Cancellation_Details__c) eachSObject;
                                listOfPOCD.add(newPOCD);
                        }
                }
                if(listOfPOCD.size() > 0) {
                        PartnerOrderCancellation_TriggerClass.addAdditionalData(listOfPOCD);
                }
        }
        public override void beforeDeleteBeforeUndeleteTrigger() {
        }

        public override void afterInsertAfterUpdateTrigger() {
                List<Partner_Order_Cancellation_Details__c> listOfPOCD = new List<Partner_Order_Cancellation_Details__c>();

                for(SObject eachSObject : newList) {
                        if(Trigger.isInsert) {
                                Partner_Order_Cancellation_Details__c newPOCD = (Partner_Order_Cancellation_Details__c) eachSObject;
                                listOfPOCD.add(newPOCD);
                        }
                }
                if(listOfPOCD.size() > 0) {
                        PartnerOrderCancellation_TriggerClass.handleEmailFunctionality(listOfPOCD);
                }
        }
        public override void afterDeleteAfterUndeleteTrigger() {
        }

}