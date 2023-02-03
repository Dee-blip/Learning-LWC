/* ========================================================================
Author: Sonia Sawhney
Description: CR 2056249: Remedyforce allows multiple entries for the same account under Impacted Accounts section
Created Date : 05/06/2014
======================================================================== */
trigger SIImpactedAccountsTrigger on SI_ServiceIncidentImpactedCustomers__c (before insert, before update) {

    map<string, SI_ServiceIncidentImpactedCustomers__c> SIkeyMap= new map<string, SI_ServiceIncidentImpactedCustomers__c>();
    set<Id> existingRecordIds = new set<Id>();
    for(SI_ServiceIncidentImpactedCustomers__c customer: Trigger.New)
    {
        String key = String.valueOf(customer.SI_Service_Incident__c) + String.valueOf(customer.SI_AccountName__c);
        if(SIkeyMap.containsKey(key)){
            customer.SI_AccountName__c.AddError('You cannot add multiple entries for the same account!');
        }else{
            SIkeyMap.put(key,customer);
        }
        if(Trigger.isUpdate)
        {
            existingRecordIds.add(customer.Id);
        }
    }  

    for(SI_ServiceIncidentImpactedCustomers__c existingCustomer : [select UniqueId__c from SI_ServiceIncidentImpactedCustomers__c where UniqueId__c IN :SIkeyMap.keySet() and Id NOT IN :existingRecordIds])
    {
        SI_ServiceIncidentImpactedCustomers__c  tempCustomer = SIkeyMap.get(existingCustomer.UniqueId__c);
        if (tempCustomer !=null){
             tempCustomer.SI_AccountName__c.AddError('You cannot add multiple entries for the same account!');           
        }
    } 
}