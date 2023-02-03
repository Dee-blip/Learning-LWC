trigger PA_Product_Approval_bu on Product_Approvals__c (before Update) {
         for(Product_Approvals__c pac:Trigger.New){
           if(pac.Approval_Step__c!=Trigger.oldMap.get(pac.Id).Approval_Step__c)
             {
             pac.Escalation_Status__c='NEW';
            } 
         
         }
       
}