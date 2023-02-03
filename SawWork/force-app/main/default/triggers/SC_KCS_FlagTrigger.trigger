/*=======================================================================================+
    Trigger name        :   SC_KCS_FlagTrigger
    Author              :   Vamsee S
    Created             :   15 Jan 2019
    Purpose             :   ESESP-1779 : Lightning Knowledge Migration
    Test Class          :   SC_KCS_TestClass
------------------------------------------------------------------------------------------*/
trigger SC_KCS_FlagTrigger on SC_KCS_Flag__c (before Update) {
    if(Trigger.IsUpdate){
        for(SC_KCS_Flag__c eachRec: Trigger.New){
                if(eachRec.Status__c !=Trigger.OldMap.get(eachRec.id).Status__c && eachRec.Status__c == 'Closed'){
                    eachRec.Closed_By__c = userinfo.getUserId();
                }
            }
    }
}