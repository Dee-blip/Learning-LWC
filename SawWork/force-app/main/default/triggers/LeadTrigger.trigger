trigger LeadTrigger on Lead(after delete, after insert, after undelete, after update, before delete, before insert, before update) 
{
	if(ByPassAndLimitUtils.isDisabled('LeadTrigger')){
        //set akam field 
        if(Trigger.isBefore)
            ByPassAndLimitUtils.setAkamField(Trigger.isInsert, Trigger.isUpdate, Trigger.New);
        return;
    }
    if(Trigger.isUpdate && userinfo.getProfileId() == GsmUtilClass.getGSMSettingValue('SystemAdminProfileId')){
         //when Updated_Date_For_CDP__c is changed in all marketo lead records with admin profile, no need to execute lead trigger code
        boolean isCDPFieldUpdated = true;
        for(Lead l: Trigger.new){
            if(l.Lead_Record_Type__c != 'Marketo Lead' || l.Updated_Date_For_CDP__c == Trigger.oldMap.get(l.Id).Updated_Date_For_CDP__c){
                isCDPFieldUpdated = false;
                break;
            }
        }
        System.debug('isCDPFieldUpdated = ' + isCDPFieldUpdated);
        if(isCDPFieldUpdated){
            System.debug('Only Updated_Date_For_CDP__c is changed. Lead Trigger code is returned');
            return;
        }  
    }
	ApexTriggerHandlerAbstractClass.createHandler('Lead');
}