/*******************************************************************************************************
 Name         :   ExternalDependencyTrigger
 Author       :   Pinkesh Rathore
 Created Date :   Jan 30,2017
 CR           :   3612751
 Description  :   External_Dependency__c object trigger
 

Last Modified     Developer   Purpose            
 =============     =========   =======
  
*******************************************************************************************************/


trigger ExternalDependencyTrigger on External_Dependency__c (before insert, after insert, before update, after update) {
    if(Trigger.IsUpdate && Trigger.IsAfter && !UserInfo.getName().equalsIgnoreCase('Connection User')){
        ExternalDependencyTriggerHandler.ChangeCaseExternalDependencies(Trigger.IsUpdate, Trigger.new, Trigger.oldMap);
    }
}