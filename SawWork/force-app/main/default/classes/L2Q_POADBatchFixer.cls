global class L2Q_POADBatchFixer implements Database.Batchable<sObject>, Database.Stateful {

        global String query;
        Id contentWorkspaceId;
        global L2Q_POADBatchFixer() {
                query = 'SELECT Id, ContenDocumentId__c, Attachment__c FROM Partner_Order_Acceptance_Document__c WHERE Attachment__c <> null AND ContenDocumentId__c = null ORDER BY LastModifiedDate';
                System.DEBUG('contentWorkspaceId: ' + contentWorkspaceId);
        }

        global Database.QueryLocator start(Database.BatchableContext BC) {
                return Database.getQueryLocator(query);
        }

        global void execute(Database.BatchableContext BC, List<sObject> scope) {

                if (scope.size() > 0) {
                        List<Id> listOfPoadId = new List<Id>();
                        List<Partner_Order_Acceptance_Document__c> listOfPoad = (List<Partner_Order_Acceptance_Document__c>)scope;
                        for(Partner_Order_Acceptance_Document__c eachPoad : listOfPoad) {
                                listOfPoadId.add(eachPoad.Id);
                        }
                        Map<Id, ContentVersion> mapOfCV = new Map<Id, ContentVersion>([SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :listOfPoadId]);

                        List<Partner_Order_Acceptance_Document__c> updatePoad = new List<Partner_Order_Acceptance_Document__c>();
                        for(Partner_Order_Acceptance_Document__c eachPoad : listOfPoad) {
                                if(mapOfCV.containsKey(eachPoad.Attachment__c)) {
                                        eachPoad.ContenDocumentId__c = mapOfCV.get(eachPoad.Attachment__c).ContentDocumentId;
                                        eachPoad.Validation_Override__c = true;
                                        updatePoad.add(eachPoad);
                                }
                        }
                        try {
                                update updatePoad;
                        }
                        catch(Exception e) {
                                System.DEBUG(String.valueOf(e));
                        }
                }
        }

        global void finish(Database.BatchableContext BC) {
                System.DEBUG('Done: \n');
        }
}