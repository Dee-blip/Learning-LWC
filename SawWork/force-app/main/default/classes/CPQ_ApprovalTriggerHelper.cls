/*
*
* Object: sbaa__Approval__c
* Details : Helper class for AA Approvals object trigger handler: CPQ_ApprovalTriggerHandler.
* 
* Developer      Date      Version    Update 
* kimishra      08/06/2019    1.0      Initial version
* 
*/
public class CPQ_ApprovalTriggerHelper {
    private static CPQ_ApprovalTriggerHelper instance = null;
    private static Set<Id> quoteIds = new Set<Id>();
    private static Map<Id, SBQQ__Quote__c> quoteMap = null;
    private static sbaa__ApprovalRule__c productRuleRecord = null;
    private static sbaa__ApprovalCondition__c approvalConditionRecord = null;
    
    //constructor
    public CPQ_ApprovalTriggerHelper(Map<Id, SObject> newItems){
        CPQ_ProductApprovalTriggerHandler.TriggerDisabled = true;
        System.debug('--inside constructor1');
        //get quote id and create PA if applicable for each QL
        //only for AA of Product Approval rule type
        for(sbaa__Approval__c ap : (List<sbaa__Approval__c>) newItems.values()){
            if(ap.sbaa__Rule__c == getProductRule().Id){
                quoteIds.add(ap.Quote__c);
            }
        }
        System.debug('--quoteIds: '+quoteIds);
    }
    
    public static CPQ_ApprovalTriggerHelper getInstance(Map<Id, SObject> newItems) {
        System.debug('--inside getInstance');
        instance = new CPQ_ApprovalTriggerHelper(newItems);
        return instance;
    }
    
    //Lazy Initialization - starts
    public static Map<Id, SBQQ__Quote__c> getQuoteMap(){
        if(quoteMap == null){
            System.debug('--generating quoteMap');
            quoteMap = new Map<Id, SBQQ__Quote__c>([SELECT Id, SBQQ__Status__c,
                                                                            SBQQ__Opportunity2__c,
                                                                            SBQQ__Opportunity2__r.AKAM_Opportunity_ID__c,
                                                                            (SELECT Id,
                                                                             CPQ_Approval_Workflow__c,
                                                                             CPQ_Approval_Workflow__r.AKAM_Workflow_ID__c, 
                                                                             SBQQ__ProductCode__c,
                                                                             SBQQ__ProductName__c
                                                                             FROM SBQQ__LineItems__r)
                                                                            FROM SBQQ__Quote__c
                                                                            WHERE Id IN :quoteIds]);
        }
        return quoteMap;
    }
    
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
    
    //logic starts
    //
    //
    //create product approval rules for the related Quote
    //checks related Opp's existing product approvals and then accordingly create PA records
    //public static void createCustomProductApprovals(Map<Id, SObject> newItems){
    public void createCustomProductApprovals(){
        System.debug('--inside createCustomProductApprovals');
        Set<Id> oppIds = new Set<Id>();
        List<String> prodNames = new List<String>();
        Map<String, String> prodNameAppWorkflowMap = new Map<String, String>();
        //Map<Id, SBQQ__QuoteLine__c> quoteQLmap = new Map<Id, SBQQ__QuoteLine__c>();
        
        if(!quoteIds.isEmpty()){
            //System.debug('--quoteMap: '+quoteMap);
            //query quote and Qls
            for(SBQQ__Quote__c qt : getQuoteMap().values()){
                oppIds.add(qt.SBQQ__Opportunity2__c);
            }
            System.debug('--oppIds: '+oppIds);
            
            //check if the qls have corresponding Akamai PA workflow
            for(SBQQ__Quote__c qt : getQuoteMap().values())
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
            
            //check if QLs need product approval to be triggered
            //get the existing prod approval record of the opportunity
            Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([SELECT Id, 
                                                                    (SELECT Id, Name, Approval_Workflow__r.Name
                                                                     FROM Product_Approvals__r)
                                                                    FROM Opportunity
                                                                    WHERE Id IN :oppIds]);
            
            //below map contains Op id and list of existing approval prod names
            Map<Id, List<String>> oppExistingPA = new Map<Id, List<String>>();
            for(Opportunity op : oppMap.values()){
                if(!op.Product_Approvals__r.isEmpty()){
                    for(Product_Approvals__c pa : op.Product_Approvals__r){
                        List<String> tempList = new List<String>();
                        if(oppExistingPA.containsKey(op.Id)){
                            tempList = oppExistingPA.get(op.Id);
                        }
                        tempList.add(pa.Approval_Workflow__r.Name);
                        oppExistingPA.put(op.Id, tempList);
                    }
                }
            }
            System.debug('--oppExistingPA: '+oppExistingPA);
            
            for(SBQQ__Quote__c qt : getQuoteMap().values()){
                for(SBQQ__QuoteLine__c ql : qt.SBQQ__LineItems__r){
                    //call the product approval creation api, if not already existing in the Opp
                    //
                    //if qls have corresponding Akamai PA workflow
                    //then, if opp has no existing product approvals
                    if(prodNameAppWorkflowMap.containsKey(ql.SBQQ__ProductName__c)){
                        System.debug('--QL prod has an Approval Workflow in system. So moving ahead.');
                        if(oppExistingPA != null && !oppExistingPA.containsKey(qt.SBQQ__Opportunity2__c)){
                            System.debug('--Opp has no existing PA.');
                            ProductApprovalHandler.initiateApproval(ql.CPQ_Approval_Workflow__r.AKAM_Workflow_ID__c,qt.SBQQ__Opportunity2__r.AKAM_Opportunity_ID__c);
                        }
                        //if there are existing prod approvals check if this prod exists
                        else if(!oppExistingPA.get(qt.SBQQ__Opportunity2__c).contains(ql.SBQQ__ProductName__c)){
                            System.debug('--Opp has some existing PA but not for this product: '+ql.SBQQ__ProductName__c);
                            ProductApprovalHandler.initiateApproval(ql.CPQ_Approval_Workflow__r.AKAM_Workflow_ID__c,qt.SBQQ__Opportunity2__r.AKAM_Opportunity_ID__c);
                        }
                    }
                }
            }
        }
    }
    
    //method to check if all reqd product approvals status is approved then make AA prod approval record approved
    public static void updatePAStepStatus(Map<Id, SObject> newItems){
        System.debug('--inside updatePAStepStatus');
        Set<Id> quoteIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        List<String> prodNames = new List<String>();
        Map<String, String> prodNameAppWorkflowMap = new Map<String, String>();
        Map<String, Product_Approvals__c> paDetailMap = new Map<String, Product_Approvals__c>();
        List<Id> qtIdsToApprove = new List<Id>();
        List<sbaa__ApprovalSnapshot__c> apsn = new List<sbaa__ApprovalSnapshot__c>();
        
        //get quote id and create PA if applicable for each QL
        
        for(sbaa__Approval__c ap : (List<sbaa__Approval__c>) newItems.values()){
            if(ap.sbaa__Rule__c == getProductRule().Id){
                quoteIds.add(ap.Quote__c);
            }
        }
        System.debug('--quoteIds: '+quoteIds);
        
        if(!quoteIds.isEmpty()){
            //query quote and Qls
            Map<Id, SBQQ__Quote__c> quoteMap = new Map<Id, SBQQ__Quote__c>([SELECT Id, SBQQ__Status__c,
                                                                            SBQQ__Opportunity2__c,
                                                                            SBQQ__Opportunity2__r.AKAM_Opportunity_ID__c,
                                                                            SBQQ__Opportunity2__r.Name,
                                                                            (SELECT Id,
                                                                             CPQ_Approval_Workflow__c,
                                                                             SBQQ__ProductCode__c,
                                                                             SBQQ__ProductName__c
                                                                             FROM SBQQ__LineItems__r)
                                                                            FROM SBQQ__Quote__c
                                                                            WHERE Id IN :quoteIds]);
            for(SBQQ__Quote__c qt : quoteMap.values()){
                oppIds.add(qt.SBQQ__Opportunity2__c);
            }
            System.debug('--oppIds: '+oppIds);
            
            //check if the qls have corresponding Akamai PA workflow
            for(SBQQ__Quote__c qt : quoteMap.values())
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
            
            //get related opp existing product approval records
            for(Product_Approvals__c epa : [SELECT Id, Name, Opportunity__c, Opportunity__r.Name, Status__c, Opportunity__r.AKAM_Opportunity_ID__c, Workflow_ID__c FROM Product_Approvals__c WHERE Opportunity__c IN :oppIds]){
                //paDetailMap.put(epa.Name, epa);
                paDetailMap.put(epa.Workflow_ID__c+'-'+epa.Opportunity__r.AKAM_Opportunity_ID__c, epa); //AW id and opp id creates a unique key to identify the PA - kimishra 10/16/2019
            }
            System.debug('--paDetailMap: '+paDetailMap);
            
            ///check each quote for the product approvals under it - find the ones which have all PA's approved
            for(SBQQ__Quote__c qt : quoteMap.values()){
                Boolean addQuoteToApprovalList = true;
                for(SBQQ__QuoteLine__c ql : qt.SBQQ__LineItems__r){
                    //if Approval Workflow exists for the prod
                    if(prodNameAppWorkflowMap.containsKey(ql.SBQQ__ProductName__c)){
                        System.debug('--ql with product: '+ql.SBQQ__ProductName__c+' has an AW.');
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
                    System.debug('--all QLs with PA are approved for: '+qt.Id);
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
    
    //method to prevent user to reassign outside public group
    public static void reassignCustomFilter(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        //conditions - if approval has a public group assigned and no user
        
        Map<Id, sbaa__Approval__c> newItemsMap = (Map<Id, sbaa__Approval__c>) newItems;
        Map<Id, sbaa__Approval__c> oldItemsMap = (Map<Id, sbaa__Approval__c>) oldItems;
        Set<Id> approverIds = new Set<Id>();
        Set<Id> groupIds = new Set<Id>();
        
        for(sbaa__Approval__c ap : newItemsMap.values()){
            //check only for Approvals where sbaa__AssignedTo__c field has been changed
            if(ap.sbaa__AssignedTo__c != oldItemsMap.get(ap.Id).sbaa__AssignedTo__c){
                approverIds.add(ap.sbaa__Approver__c);
            }
        }
        System.debug('--approverIds: '+approverIds);
        
        //approver ids of approval recs where assignedTo has changed
        if(!approverIds.isEmpty()){
            //check if approver is a group or user - validate only group ones
            Map<Id, sbaa__Approver__c> approverMap = new Map<Id, sbaa__Approver__c>([SELECT Id, sbaa__GroupId__c
                                                                                     FROM sbaa__Approver__c
                                                                                     WHERE sbaa__GroupId__c != null
                                                                                     AND Id IN :approverIds]);
            for(sbaa__Approver__c apr : approverMap.values()){
                groupIds.add(apr.sbaa__GroupId__c);
            }
            
            Map<Id, List<Id>> groupGrpMemberMap = new Map<Id, List<Id>>();
            for(Group grp : [SELECT Id, DeveloperName,
                             (SELECT Id, UserOrGroupId FROM GroupMembers)
                             FROM Group
                             WHERE Id IN :groupIds]){
                                 List<Id> tempList = new List<Id>();
                                 if(!grp.GroupMembers.isEmpty()){
                                     for(GroupMember grpMem : grp.GroupMembers){
                                         tempList.add(grpMem.UserOrGroupId);
                                     }
                                     groupGrpMemberMap.put(grp.Id, tempList);
                                 }
                             }
            System.debug('--groupGrpMemberMap: '+groupGrpMemberMap);
            
            if(!groupIds.isEmpty()){
                //SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId='00G2f000000SD9b'
                //check that the user given in Assigned To is a part of the respective group
                for(sbaa__Approval__c ap : newItemsMap.values()){
                    Id tempGroupId = approverMap.get(ap.sbaa__Approver__c).sbaa__GroupId__c;
                    System.debug('--tempGroupId: '+tempGroupId+' -- '+ap.sbaa__AssignedTo__c);
                    if(approverIds.contains(ap.sbaa__Approver__c) && !groupGrpMemberMap.get(tempGroupId).contains(ap.sbaa__AssignedTo__c)){
                        ap.addError('You cannnot assign the approval outside the Approver group.');
                    }
                }
            }
        }
    }
    //logic ends
}