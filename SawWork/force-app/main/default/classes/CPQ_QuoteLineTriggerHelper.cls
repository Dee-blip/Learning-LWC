/*
* Object: SBQQ__QuoteLine__c
* Details : Helper class for CPQ Quote Line object trigger handler: CPQ_QuoteLineTriggerHandler
* 
* Developer			Date			Version		Update 
* kimishra			08/09/2019		1.0			Initial version
* 
*/
public class CPQ_QuoteLineTriggerHelper {
    
    //update the Approval Workflow lookup
    public static void upadteApprovalWorkflow(List<SBQQ__QuoteLine__c> newItems){
        Set<String> prodNames = new Set<String>();
        Map<String, Id> awMap = new Map<String, Id>();
        
        //logic: query the approval workflow and get the one with same product name as QL
        //
        //get the product names of the QLs
        for(SBQQ__QuoteLine__c ql : newItems){
            System.debug('--ql product: '+ql.SBQQ__ProductName__c);
            prodNames.add(ql.SBQQ__ProductName__c);
        }
        System.debug('--prodNames: '+prodNames);
        
        if(!prodNames.isEmpty()){
            //query the approval workflow with the prod name
            List<Approval_Workflow__c> awList = new List<Approval_Workflow__c>([SELECT Id, Name
                                                                                From Approval_Workflow__c
                                                                                WHERE Name IN :prodNames]);
            System.debug('--awList: '+awList);
            if(!awList.isEmpty()){
                //put in name and id map
                for(Approval_Workflow__c aw : awList){
                    awMap.put(aw.Name, aw.Id);
                }
                System.debug('--awMap: '+awMap);
                
                //update the QL field
                if(!awMap.isEmpty()){
                    for(SBQQ__QuoteLine__c ql : newItems){
                        if(awMap.containsKey(ql.SBQQ__ProductName__c)){
                            ql.CPQ_Approval_Workflow__c = awMap.get(ql.SBQQ__ProductName__c);
                        }
                    }
                }
            }
        }
        System.debug('--updated qls: '+newItems);
    }
}