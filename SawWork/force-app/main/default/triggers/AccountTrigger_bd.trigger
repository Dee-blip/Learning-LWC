/**
   AccountTrigger_bd
   @version 1.0
   @author Karteek Mekala <kmekala@akamai.com>
   @Description : This trigger is called on 'before delete' event on Account.
   				  It takes care of the following
   				  - Prevent user from deleteing an Account unless his profile is 'System Administrator' or 'CRM Integraion'
   History
		
		--Developer			--Date			--Description
		Ali					18/Jun/2012		CR 1753213 Remove Bus Ops exception for deleting accounts	
											-> Commenting out account delete exception code as we are moving it to AccountTrigger_ad.trigger to ensure Bizz Ops can delete 
											accounts only on merge.			  
   
*/
trigger AccountTrigger_bd on Account (before delete) 
{
	/*
	Set<Id> allowedProfileIds = new Set<Id>();
	for(Profile pr:[select Id from Profile where Name='System Administrator' or Name='CRM Integration' or Name='Business Operations'])
		allowedProfileIds.add(pr.Id);
	for(Account acc: Trigger.old)
	{
		if(!allowedProfileIds.contains(UserInfo.getProfileId()))
			acc.addError('Insufficient access. Please contact System Administrator for Account deletion.');
	} 
	*/
}