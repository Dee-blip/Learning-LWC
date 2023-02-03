trigger Current_Sales_Channel_bi_bu on Current_Sales_Channel__c( before insert, before update) 
{
    for(Current_Sales_Channel__c csc : Trigger.new)
    {
        csc.CurrentSalesChannelExternalID__c = csc.Customer_Account__c+'#'+csc.Partner_Account__c;
        csc.Direct_Contract_Copy__c = csc.Direct_Contract__c ;
    }

}