/* ========================================================================
    Author: Sonia Sawhney
    Description: Restrict the user from deleting project products if there are any timecards associated with it
    Created Date : 10/04/2014
    ======================================================================== */
trigger PSA_ProjectProductTrigger on pse__Project_Methodology__c (before delete) {
    //Check if any timecards are associated with the Project product
    set<Id> productIds = new set<Id>();
    
    Map<Id, pse__Project_Methodology__c> mpProducts = new Map<Id,pse__Project_Methodology__c>( [Select Id, (Select Id from pse__Timecards__r) from pse__Project_Methodology__c where Id in :Trigger.oldmap.keyset()]);
    for(pse__Project_Methodology__c  psProduct: Trigger.old)
    {
         pse__Project_Methodology__c  product = mpProducts.get(psProduct.Id);
         if(product.pse__Timecards__r != null && product.pse__Timecards__r.size()>0)
            psProduct.addError('You cannot delete a project product that has timecards associated with it!');
    }
}