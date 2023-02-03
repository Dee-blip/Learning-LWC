/**

Sonali Tandon - 1st Sept 2015 - SFDC-1094 : NAP User -- Fix the NAP Last Login

LastNAPLoginBatchClass stamps Last NAP Login on Partner Contact from Last Login field on corresponding Partner User.

**/

global class LastNAPLoginBatchClass extends GenericBatchClass
{

	global Map<Id,Contact> mapOfPartnerUserIdToContact = new Map<Id,Contact>();

	global LastNAPLoginBatchClass()
	{
		super();

		operationType = 'Update';
		className = 'LastNAPLoginBatchClass';
        errorAddressCustomSetting = 'LastNAPLoginBatchClass#EmailId';
		query = 'Select Id, NetAlliance_User_Active__c,Last_NAP_Login__c, Partner_User__c,Validation_Override__c from Contact where Partner_User__c!=null AND NetAlliance_User_Active__c = \'YES\'';
	}

	global override void execute(Database.BatchableContext BC, List<sObject> scope)
    {

    	List<Contact> listOfContactsQueried			= (List<Contact>)scope;
    	Map<Id,Contact> mapOfPartnerUserIdToContact = new Map<Id,Contact>();
    	List<Contact> listOfContactsToUpdate 		= new List<Contact>();

    	if(listOfContactsQueried.size()>0)
    	{

    		for(Contact contactItem : listOfContactsQueried)
    			mapOfPartnerUserIdToContact.put(contactItem.Partner_User__c,contactItem);
    		
    		for(User userItem : [Select Id, LastLoginDate from User where Id IN : mapOfPartnerUserIdToContact.keySet()])
    		{
    			mapOfPartnerUserIdToContact.get(userItem.Id).Last_NAP_Login__c = userItem.LastLoginDate;
    			mapOfPartnerUserIdToContact.get(userItem.Id).Validation_Override__c 	   = true;
    			listOfContactsToUpdate.add(mapOfPartnerUserIdToContact.get(userItem.Id));
    		}

    		if(listOfContactsToUpdate.size()>0)
    			 super.execute(BC, listOfContactsToUpdate);

    	}
    }

      global override void finish(Database.BatchableContext BC)
    {

        super.finish(BC);
    }

   
}