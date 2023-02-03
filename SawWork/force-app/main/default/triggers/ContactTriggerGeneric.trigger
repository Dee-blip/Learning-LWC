trigger ContactTriggerGeneric on Contact (after delete, after insert, after undelete, after update, before delete, before insert, before update) {

    //SFDC-8128 Do not call Trigger logic for Copystorm profile
    if(userinfo.getProfileId() == GsmUtilClass.getGSMSettingValue('ValidContactIntegrationProfile')){
        return;
    }
    
	if(Trigger.isUpdate && userinfo.getProfileId() == GsmUtilClass.getGSMSettingValue('SystemAdminProfileId')){
       //when Updated_Date_For_CDP__c is changed in all records with admin profile, no need to execute contact generic trigger code
        boolean isCDPFieldUpdated = true;
        for(Contact con: Trigger.new){
            if(con.Updated_Date_For_CDP__c == Trigger.oldMap.get(con.Id).Updated_Date_For_CDP__c){
                isCDPFieldUpdated = false;
                break;
            }
        }
        System.debug('isCDPFieldUpdated = ' + isCDPFieldUpdated);
        if(isCDPFieldUpdated){
            System.debug('Only Updated_Date_For_CDP__c is changed. Contact generic Trigger code is returned');
            return;
        }  
	}
	ApexTriggerHandlerAbstractClass.createHandler('Contact');
}