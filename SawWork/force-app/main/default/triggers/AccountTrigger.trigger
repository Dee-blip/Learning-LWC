/**
 * By setting this field, you can use ownerIDAlt__c in 
 * a formula field to get the owner name. 
 *
 * History:
 * =========================
 * Developer		Date		Description
 * --------------------------------------------------------------------------------------------------
 * Dan Pejanovic	12/2009		Created Class
 * Karteek Kumar M	03/2010		Temporary fix for data issues on roll-up summary. 
 * Karteek Kumar M	15/2010		Moved temp fix to Account_Trigger_bi_bu
 *
 **/
trigger AccountTrigger on Account (after insert, after update, before insert, before update,after delete) {
}