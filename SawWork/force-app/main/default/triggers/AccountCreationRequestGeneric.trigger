/* Created By: Swati
 * Created Date: 18-Nov-2018
 * Description: Trigger on Account_Creation_Request__c.
**/

trigger AccountCreationRequestGeneric on Account_Creation_Request__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

     ApexTriggerHandlerAbstractClass.createHandler('Account_Creation_Request__c');
}