/*
 * CR: FFPSA-722
 * Developer: Sharath Prasanna
 * Enhancement: OVER-RIDING PROJECT NEW BUTTON
 * Date: 13th September 2018
 * 
*/ 
public class PSA_CreateProjectTempController 
{
	
	public PSA_CreateProjectTempController() 
	{
		
	}
	public PSA_CreateProjectTempController(ApexPages.StandardController controller)
	{

	}
	public PageReference navigateToCreatePage ()
	{
		String parentId;
		if(UserInfo.getUiThemeDisplayed() == 'Theme3')
		{
			parentId = ApexPages.currentPage().getParameters().get('retURL');
			if(parentId != null && parentId.startsWith('/'))
			{
				parentId = parentId.substring(1);		
			}
		}
		else
		{
			parentId = ApexPages.currentPage().getParameters().get('CF00NG0000009zdnl_lkid');	
			if(parentId ==null)
			{
				parentId = ApexPages.currentPage().getParameters().get('CF00NG0000009zdoi_lkid');	
			}
		} 
		//system.debug(Apexpages.currentPage().getUrl());
		PageReference pg = null;
		try
		{
			if(parentId != null)
			{
				system.debug('Before split: parentId: ' + parentId);
				String oppId;
				String acctId;
				parentId = (parentId.split('\\?'))[0];
				system.debug('after split parentId: ' + parentId);
				if(parentId.startsWith('001'))
				{
					acctId = parentId;
					pg = new PageReference('/apex/PSA_CreateProjectFromTemplate_Page?oppId='+ '&acctId=' + acctId);
				}
				else if(parentId.startsWith('006'))
				{
					oppId = parentId;
					Opportunity opp = [Select Id, AccountId from Opportunity where id = :oppId limit 1];
					acctId = opp.AccountId;
					pg = new PageReference('/apex/PSA_CreateProjectFromTemplate_Page?oppId='+oppId+ '&acctId=' + acctId);

				}
			}
			else
			{
				ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'New projects must be created from an account or opportunity'));
				pg = new PageReference('/apex/PSANewProjectReminder');
			}				

		}
		catch(Exception e)
		{
			ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, e.getMessage()));
		}
		return pg;
	}
	@AuraEnabled
	public static String getAccount(Id oppId)
	{
			String returnMessage;			
			try
			{
				Opportunity opp = [Select Id, AccountId from Opportunity where id = :oppId limit 1];
				String acctId = opp.AccountId;			
				returnMessage = 'SUCCESS:'+acctId;

			}
			catch(Exception e)
			{
				returnMessage = 'ERROR: '+e.getMessage();
			}
			return returnMessage;
	}	
}