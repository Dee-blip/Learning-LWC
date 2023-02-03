trigger CaseTrigger_bd_ad on Case (after delete, before delete) {
		
	//Set<Id> allowedProfileIds = new Set<Id>();
	//for(Profile pr:[select Id from Profile where Name='System Administrator' or Name='CRM Integration' or Name='Business Operations'])
	//	allowedProfileIds.add(pr.Id);
	String profilesWithDeleteAccess = GsmUtilClass.GetCustomSettingValue('IR_System_ProfileIDs');	
	for(Case cs: Trigger.old)
	{
		if(!profilesWithDeleteAccess.contains(UserInfo.getProfileId()))
			cs.addError('Insufficient access. Please contact System Administrator for Case deletion.');
	}
}