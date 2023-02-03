public class SObjectBackupAuditFieldTriggerHandler extends ApexTriggerHandlerAbstractClass
{
	public override void beforeInsertBeforeUpdateTrigger()
	{
		List<Sobject_Backup_Audit_Field__c> sbackAuditTriggerNew = (List<Sobject_Backup_Audit_Field__c>)newList;
		Id CrmIntegration = Id.valueOf(GsmUtilClass.getGSMSettingValue('CRM_Integration')); // SFDC-2705 Custom Settings Migration
	    for(Sobject_Backup_Audit_Field__c sbackaudit : sbackAuditTriggerNew)
	    {
	      //This code takes care OF AKAM fields while insert if any of these field is null or Empty
	      if(Trigger.isInsert)
	      {
	        if((UserInfo.getUserId() == CrmIntegration && (sbackaudit.AKAM_Created_By__c =='' || 
	          sbackaudit.AKAM_Created_Date__c == null ||sbackaudit.AKAM_System__c =='')) || UserInfo.getUserId() != CrmIntegration ) 
	        {
	          sbackaudit.AKAM_Created_By__c = sbackaudit.AKAM_Alias__c ;
	          sbackaudit.AKAM_Created_Date__c = system.now();
	          sbackaudit.AKAM_System__c ='FORCE';
	        }
	      }      
	    // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
	      if((UserInfo.getUserId() == CrmIntegration && (sbackaudit.AKAM_Modified_Date__c  == null|| 
	        sbackaudit.AKAM_Modified_By__c == '' || sbackaudit.AKAM_Modified_By__c == null)) || UserInfo.getUserId() != CrmIntegration )  
	      {
	        sbackaudit.AKAM_Modified_By__c = sbackaudit.AKAM_Alias__c;
	        sbackaudit.AKAM_Modified_Date__c =  system.now();  
	      }
	    }
	}

	public override void afterInsertAfterUpdateTrigger()
    {
    	System.debug('This is after insert and after update.');
    }

    public override void beforeDeleteBeforeUndeleteTrigger()
    {
        System.debug('This is before delete and before undelete.');
    }

    public override void afterDeleteAfterUndeleteTrigger()
    {
    	System.debug('This is after delete and after undelete.');
    }
}