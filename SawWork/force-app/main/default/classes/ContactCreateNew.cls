/**

 *
 * History:
 * =========================
 * Developer		Date		Description
 * --------------------------------------------------------------------------------------------------
   Sonali Tandon 	4/8/2015	 CR 3103581 : NAP -- Default Contact Account on Creation
   											  When a Partner Community Admin creates Contact in NAP Portal, populate admin's account by default.
 
   
 **/
public class ContactCreateNew {
       
public ContactCreateNew(){}

public ContactCreateNew(ApexPages.StandardController controller){}

public PageReference pageRedirect(){

	String prefix = Schema.SObjectType.Contact.getKeyPrefix();
	System.debug('Prefix: ' + prefix);
	Id currentUserId = UserInfo.getUserId();
	System.debug('User id: ' + currentUserId + 'User profile: ' + UserInfo.getProfileId());
	PageReference returnURL = new PageReference('/' + prefix + '/e?');

    //String partnerAdminId = PRM_Settings__c.getInstance('Partner Admin Id').value__c; //SFDC-2573
    //String accountFieldId = PRM_Settings__c.getInstance('ContactCreateNew#AccountFieldId').value__c; //SFDC-2573
    
    String partnerAdminId = GsmUtilClass.getPRMSettingValue('Partner_Admin_Id'); //SFDC-2573
    String accountFieldId = GsmUtilClass.getPRMSettingValue('ContactCreateNew_AccountFieldId'); //SFDC-2573
    
    for(String key: ApexPages.currentPage().getParameters().keySet())
			returnURL.getParameters().put(key, ApexPages.currentPage().getParameters().get(key));

	// Populate Account with Partner Admin's account
	if((UserInfo.getProfileId().contains(partnerAdminId)) && (currentUserId!=null))
	{
		
           User userObj = [Select Id,Name,ContactId from User where Id =:currentUserId];
           System.debug('User details' + userObj); 
           Contact con = [Select Id, Account.Name, AccountId from Contact where Id =: userObj.ContactId];
           System.debug('Contact details ' + con);
        
		if(con.AccountId!= null)	
			returnURL.getParameters().put(accountFieldId, con.Account.Name);	
	}
    
	returnURL.getParameters().remove('save_new');
	returnURL.getParameters().put('nooverride', '1');
    returnURL.setRedirect(true);
	return returnURL;
}

}