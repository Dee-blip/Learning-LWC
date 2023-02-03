/*
* developer@Hemant Barapatre
* class : implements this intefrace GDRAT_CoreTriggerInterface
* Pattern used : Tigger factory
*/

    public without sharing class GDRAT_Territory_Sec_Assign_ambassador implements GDRAT_CoreTriggerInterface {

    private static List<DGRAT_Configuration__c> config = new List<DGRAT_Configuration__c>();


    //Constructor
    public GDRAT_Territory_Sec_Assign_ambassador() {
    system.debug('Trigger Execution started !!!!');
    config = [Select id,CreatedDate from DGRAT_Configuration__c WHERE Period__c = 'Running' AND Make_ReadOnly__c = true ORDER BY CreatedDate ASC LIMIT 1];
    }//

 //STARTING OF BUSINESS LOGICS HERE

 /* Logic to get if the security insert is happening between that particular dates 
 *
 */
private static void Verify_ReadOnlyModeExists(List<Territory_Security_Assignment__c> tsaList )
{
   for(Territory_Security_Assignment__c tsa: tsaList)
   {
       if(config.size() > 0)
       {
           tsa.adderror('Application is currently running on read-only mode!');
           //ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Application is currently running on read-only mode!'));
           break;
       }//if
   }//for

}//

//END OF BUSINESS LOGIC HERE

public void beforeInsert(List<SObject> so)
{
system.debug('[1]Running Before insert Process.....');
if(trigger.isInsert) {
//Here we will call after insert actions
Verify_ReadOnlyModeExists(so);
} 

}//

public void beforeUpdate(List<SObject> so, List<SObject> soOld,Map<Id,SObject> newMapObj, Map<Id,SObject> oldMapObj)
{
system.debug('[2]Running Before update Process.....');
if(trigger.isUpdate) {
//Here we will call after update actions
Verify_ReadOnlyModeExists(so);
} 
}//

/**
* beforeDelete
*
* This method is called iteratively for each record to be deleted during a BEFORE
* trigger.
*/
// public void beforeDelete(List<SObject> oldlstObj,Map<Id,SObject> oldMapObj)
// {
// if(trigger.isInsert) {
// //Here we will call after insert actions
// } else if(trigger.isUpdate) {
// //Here we will call after update actions
// } else if(trigger.isDelete) {
// //Here we will call after delete actions
// } else if(trigger.isUndelete) {
// //Here we will call after undelete actions
// }
// }//

// public void afterInsert(List<SObject> newlstObj,Map<Id,SObject> newMapObj)
// {
// if(trigger.isInsert) {
// //Here we will call after insert actions
// } else if(trigger.isUpdate) {
// //Here we will call after update actions
// } else if(trigger.isDelete) {
// //Here we will call after delete actions
// } else if(trigger.isUndelete) {
// //Here we will call after undelete actions
// }
// }//

// public void afterUpdate(List<SObject> newlstObj,List<SObject> oldlstObj,Map<Id,SObject> newMapObj, Map<Id,SObject> oldMapObj)
// {
// if(trigger.isInsert) {
// //Here we will call after insert actions
// } else if(trigger.isUpdate) {
// //Here we will call after update actions
// } else if(trigger.isDelete) {
// //Here we will call after delete actions
// } else if(trigger.isUndelete) {
// //Here we will call after undelete actions
// }
// }//

// public void afterDelete(List<SObject> oldlstObj,Map<Id,SObject> oldMapObj)
// {
// }//

/**
* andFinally
*
* This method is called once all records have been processed by the trigger. Use this
* method to accomplish any final operations such as creation or updates of other records.
*/
public void andFinally()
{
// insert any audit records

}//
 
}//END