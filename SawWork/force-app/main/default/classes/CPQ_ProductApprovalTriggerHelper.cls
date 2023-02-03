/*
*
* Object: Product_Approvals__c
* Details : Helper class for Product Approval object trigger handler: CPQ_ProductApprovalTriggerHandler.
* 
* Developer      Date      Version    Update 
* kimishra      08/13/2019    1.0      Initial version
* 
*/
public class CPQ_ProductApprovalTriggerHelper {
    private static sbaa__ApprovalRule__c productRuleRecord = null;
    private static sbaa__ApprovalCondition__c approvalConditionRecord = null;
    
    //Lazy Initialization - starts
    public static sbaa__ApprovalRule__c getProductRule(){
        if(productRuleRecord == null){
            List<sbaa__ApprovalRule__c> prodRule = new List<sbaa__ApprovalRule__c>([SELECT Id, Name
                                                                                    FROM sbaa__ApprovalRule__c
                                                                                    WHERE Name = 'Product Approval Rule']);
            
            productRuleRecord = prodRule[0];
            System.debug('--prodRule: '+productRuleRecord);
        }
        return productRuleRecord;
    }
    
    public static sbaa__ApprovalCondition__c getApprovalCondition(){
        if(approvalConditionRecord == null){
            Id prodRule = getProductRule().Id;
            List<sbaa__ApprovalCondition__c> approvalCondition = new List<sbaa__ApprovalCondition__c>([SELECT Id, sbaa__TestedField__c,
                                                                                                       sbaa__ApprovalRule__c
                                                                                                       FROM sbaa__ApprovalCondition__c
                                                                                                       WHERE sbaa__ApprovalRule__c = :prodRule
                                                                                                       AND sbaa__TestedField__c = 'CPQ_Approval_Quote_Lines__c']);
            
            approvalConditionRecord = approvalCondition[0];
            System.debug('--appCondition: '+approvalConditionRecord);
        }
        return approvalConditionRecord;
    }
    //Lazy Initialization - ends
    
    //check the Opp's open quotes and update the related AA product approval record status if applicable
    public static void updateAAStatus(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Set<Id> oppIds = new Set<Id>();
        List<String> prodNames = new List<String>();
        Map<String, String> prodNameAppWorkflowMap = new Map<String, String>();
        Map<String, Product_Approvals__c> paDetailMap = new Map<String, Product_Approvals__c>();
        List<Id> qtIdsToApprove = new List<Id>();
        List<sbaa__ApprovalSnapshot__c> apsn = new List<sbaa__ApprovalSnapshot__c>();
        Map<Id, Product_Approvals__c> oldItemsMap = (Map<Id, Product_Approvals__c>) oldItems;
        
        //only if status is updated and its value is set to Approved
        for(Product_Approvals__c pa : (List<Product_Approvals__c>) newItems.values()){
            if(oldItemsMap.get(pa.Id).Status__c != pa.Status__c && pa.Status__c == 'APPROVED'){
                oppIds.add(pa.Opportunity__c);
            }
        }
        System.debug('--oppIds: '+oppIds);
        
        if(!oppIds.isEmpty()){
            //get related opp existing product approval records
            for(Product_Approvals__c epa : [SELECT Id, Name, Opportunity__c, Opportunity__r.Name, Status__c, Opportunity__r.AKAM_Opportunity_ID__c, Workflow_ID__c FROM Product_Approvals__c WHERE Opportunity__c IN :oppIds]){
                //paDetailMap.put(epa.Name, epa);
                paDetailMap.put(epa.Workflow_ID__c+'-'+epa.Opportunity__r.AKAM_Opportunity_ID__c, epa); //AW id and opp id creates a unique key to identify the PA
            }
            System.debug('--paDetailMap: '+paDetailMap);
            
            //query the related opp -> quote -> product approval
            // only open quotes
            Map<Id, SBQQ__Quote__c> openQuotes = new Map<Id, SBQQ__Quote__c>([SELECT Id, SBQQ__NetAmount__c, SBQQ__Opportunity2__c, SBQQ__Opportunity2__r.Name, SBQQ__Opportunity2__r.AKAM_Opportunity_ID__c,
                                                                              (SELECT Id, SBQQ__Product__c, SBQQ__ProductName__c
                                                                               FROM SBQQ__LineItems__r)
                                                                              FROM SBQQ__Quote__c
                                                                              WHERE SBQQ__Opportunity2__c IN :oppIds
                                                                              AND SBQQ__Status__c IN ('In Review')
                                                                              AND ApprovalStatus__c = 'Pending']);
            System.debug('--openQuotes: '+openQuotes);
            
            //check if the qls have corresponding Akamai PA
            for(SBQQ__Quote__c qt : openQuotes.values())
            {
                for(SBQQ__QuoteLine__c ql : qt.SBQQ__LineItems__r){
                    prodNames.add(ql.SBQQ__ProductName__c);
                }
            }
            
            System.debug('--prodNames: '+prodNames);
            
            //get approval workflow ids and create a prodName and workflow id map
            for(Approval_Workflow__c aw : [SELECT Id, Name, AKAM_Workflow_ID__c FROM Approval_Workflow__c WHERE Name IN: prodNames]){
                prodNameAppWorkflowMap.put(aw.Name, aw.AKAM_Workflow_ID__c);
            }
            System.debug('--prodNameAppWorkflowMap: '+prodNameAppWorkflowMap);
            
            //check each quote for the product approvals under it - find the ones which have all PA's approved
            for(SBQQ__Quote__c qt : openQuotes.values()){
                Boolean addQuoteToApprovalList = true;
                for(SBQQ__QuoteLine__c ql : qt.SBQQ__LineItems__r){
                    //if Approval Workflow exists for the prod
                    if(prodNameAppWorkflowMap.containsKey(ql.SBQQ__ProductName__c)){
                        //if related Opp's PA is approved -- {ApprovalWorkflowName for OppName}
                        String paUniqueKey = prodNameAppWorkflowMap.get(ql.SBQQ__ProductName__c) + '-' + qt.SBQQ__Opportunity2__r.AKAM_Opportunity_ID__c;
                        if(paDetailMap.containsKey(paUniqueKey)){
                            System.debug('--pa status: '+paDetailMap.get(paUniqueKey).Status__c);
                            if (paDetailMap.get(paUniqueKey).Status__c != 'APPROVED') {
                                addQuoteToApprovalList = false;
                                break;
                            }
                        }
                    }
                }
                if (addQuoteToApprovalList) {
                    qtIdsToApprove.add(qt.Id);
                }
            }
            System.debug('--qtIdsToApprove: '+qtIdsToApprove);
            
            //query related aa prod approval records
            //create approval snapshot for each approval updated
            List<sbaa__Approval__c> apList = [SELECT Id, sbaa__Status__c, Quote__r.CPQ_Approval_Quote_Lines__c
                                              FROM sbaa__Approval__c
                                              WHERE Quote__c IN :qtIdsToApprove
                                              AND sbaa__Rule__c = :getProductRule().Id];
            for(sbaa__Approval__c ap: apList){
                ap.sbaa__Status__c = 'Approved';
                apsn.add(new sbaa__ApprovalSnapshot__c(sbaa__Approval__c = ap.Id,
                                                       sbaa__ApprovalCondition__c = getApprovalCondition().Id,
                                                       sbaa__ApprovedValueNumeric__c = ap.Quote__r.CPQ_Approval_Quote_Lines__c));
            }
            System.debug('--apList: '+apList);
            System.debug('--apsn: '+apsn);
            update apList;
            insert apsn;
        }
    }
}