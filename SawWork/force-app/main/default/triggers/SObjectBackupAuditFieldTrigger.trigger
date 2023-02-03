trigger SObjectBackupAuditFieldTrigger on Sobject_Backup_Audit_Field__c (before insert , before update, after insert, after update) 
{
	ApexTriggerHandlerAbstractClass.createHandler('Sobject_Backup_Audit_Field');
}