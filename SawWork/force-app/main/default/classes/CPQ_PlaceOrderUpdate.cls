/**
 * Details : Class invoked from CPQ_Place_Order_Partner Flow
 * Developer         Date            Version     Update 
 * kimishra          23-FEB-2021     1.0         Initial logic to update the records for placing an order
 * 
 */
public with sharing class CPQ_PlaceOrderUpdate {

    @InvocableMethod(label = 'Place Order Update' description = 'Update records to place an order')
    public static List<CPQ_PO_Response> createRecords(List<CPQ_PO_Request> request){

        CPQ_PO_Request singleRequest = request[0];
        System.debug(LoggingLevel.INFO, 'Request data: '+singleRequest);

        List<CPQ_PO_Response> response = new List<CPQ_PO_Response>();
        CPQ_PO_Response singleResponse = new CPQ_PO_Response();

        // List<sObject> objects = new List<sObject>();

        Savepoint sp = Database.setSavepoint();

        try{
            // update all records -- check if the latest changes are sent from the flow
            // objects.addAll((List<sObject>)(singleRequest.approvalDetails)); 
            
            if(singleRequest.approvalDetails != null) { 
                update new CPQ_UtilityClass_Flow('Approval_Details__c').cleanPickListValues(singleRequest.approvalDetails);
            }
            if(singleRequest.relatedCases != null) { 
                update new CPQ_UtilityClass_Flow('Case').cleanPickListValues(singleRequest.relatedCases);
            }
            if(singleRequest.poaDocuments != null) { 
                update new CPQ_UtilityClass_Flow('Partner_Order_Acceptance_Document__c').cleanPickListValues(singleRequest.poaDocuments);
            }
            if(singleRequest.relatedQuote != null) { 
                update new CPQ_UtilityClass_Flow('SBQQ__Quote__c').cleanPickListValues(singleRequest.relatedQuote);
            }
            if(singleRequest.relatedOpportunity != null) { 
                update new CPQ_UtilityClass_Flow('Opportunity').cleanPickListValues(singleRequest.relatedOpportunity);
            }
   
            // if(!objects.isEmpty()) { update objects; }

            singleResponse.success = 'Update successfull';
            singleResponse.error = '';
            response.add(singleResponse);
            System.debug(LoggingLevel.INFO, 'Response data: '+singleResponse);
            return response;

        } catch(Exception e){
            System.debug(LoggingLevel.INFO, 'Message: ' + e.getMessage()
                        +' || Cause: ' + e.getCause()
                        +' || Line number: ' + e.getLineNumber()
                        +' || Stack trace: ' + e.getStackTraceString());
            Database.RollBack(sp);
            singleResponse.success = '';
            singleResponse.error =  'Message: ' + e.getMessage();
            response.add(singleResponse);
            return response;
        }

    }

    public class CPQ_PO_Request {
        @InvocableVariable(label = 'List of Approval Detail records to update')
        public List<Approval_Details__c> approvalDetails;

        @InvocableVariable(label = 'List of related Case records to update')
        public List<Case> relatedCases;

        @InvocableVariable(label = 'List of Partner Order Approval Document records to update')
        public List<Partner_Order_Acceptance_Document__c> poaDocuments;

        @InvocableVariable(label = 'Quote to update')
        public SBQQ__Quote__c relatedQuote;

        @InvocableVariable(label = 'Related Opportunity to update')
        public Opportunity relatedOpportunity;

    }

    public class CPQ_PO_Response {
        @InvocableVariable(label = 'Success')
        public String success;

        @InvocableVariable(label = 'Error')
        public String error;

    }
}