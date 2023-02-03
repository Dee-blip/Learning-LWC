public without sharing class OppSalesPlayAssociationTriggerHandler extends ApexTriggerHandlerAbstractClass{
    
    public OppSalesPlayAssociationTriggerHandler(){
        
    }
    
    public override void beforeInsertBeforeUpdateTrigger(){
        List<Opportunity_Sales_Play_Association__c> dsrTriggerNew = (List<Opportunity_Sales_Play_Association__c>)newList;
        system.debug('Akam Creation');
        ByPassAndLimitUtils.setAkamField(Trigger.isInsert, Trigger.isUpdate, dsrTriggerNew);
        List<Opportunity_Sales_Play_Association__c> newOppSalesPlayListManual = new List<Opportunity_Sales_Play_Association__c>();
        for(Opportunity_Sales_Play_Association__c oppSalesPlay : dsrTriggerNew)
        {
            if(oppSalesPlay.Account__c == null)
            {
                newOppSalesPlayListManual.add(oppSalesPlay);
            }
        }
        if(newOppSalesPlayListManual.size()>0)
        {
            setAccountId(newOppSalesPlayListManual);
        }
        
    }
    
    public override void afterInsertAfterUpdateTrigger() {
    }
    
    public override void beforeDeleteBeforeUndeleteTrigger() {
    }
    
    public override void afterDeleteAfterUndeleteTrigger() {
        
    }
 // set and check Account Id for Manual Sales play association  
private void setAccountId(List<Opportunity_Sales_Play_Association__c> newOppSalesPlayList)
    {
        Map<Id, Id> oppToAccountMap = new Map<Id, Id>();
        Set<Id> oppIds = new Set<Id>();
        Set<Id> salesPlayIds = new Set<Id>();
        Map<Id,Id> accToSPId = new Map<Id,Id>();
        Set<Id> addedAccounts = new Set<Id>();
        for(Opportunity_Sales_Play_Association__c oppSalesPlay : newOppSalesPlayList)
        {
            oppIds.add(oppSalesPlay.Opportunity__c );
            salesPlayIds.add(oppSalesPlay.Sales_Play__c);
        }
        if(oppIds.size()>0)
        {
            
            for(Opportunity opp : [select id, accountId from Opportunity where id in :oppIds])
            {

                oppToAccountMap.put(opp.id, opp.accountId);
            }
        }
        

       for(Account_Sales_Play_Association__c accSP : [select id, Sales_Play__c ,Account__c from Account_Sales_Play_Association__c where Sales_Play__c in :salesPlayIds and account__c in :oppToAccountMap.values()])
            {
                addedAccounts.add(accSP.Account__c);
                accToSPId.put(accSP.Account__c, accSP.Sales_Play__c);
            }

            for(Opportunity_Sales_Play_Association__c oppSalesPlay : newOppSalesPlayList)
        {
            oppSalesPlay.Account__c = oppToAccountMap.get(oppSalesPlay.Opportunity__c);
            if(!addedAccounts.contains(oppSalesPlay.Account__c) || accToSPId.get (oppSalesPlay.Account__c) != oppSalesPlay.Sales_Play__c)
            {
                oppSalesPlay.addError('Opportunity Account is not added to the Sales play. Please add the account and try again.');
            }
                
        }
            
    }

}