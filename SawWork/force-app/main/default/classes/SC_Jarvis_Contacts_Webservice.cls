/*==========================================================================================================================================+
    Authors                   :   Sharath Prasanna
    Purpose                   :   Called from Monthly Mule Poller and One time Sync. Get the contact information for IDM permissions
    Test class                :   
+==========================================================================================================================================*/
@RestResource(urlMapping='/SC_Jarvis_Contacts_Webservice/*')
global class SC_Jarvis_Contacts_Webservice 
{
    public class PollerWrapper
    {
        List<ContactWrapper> contactWrappers;
        Map<String,String> contactLoginToId;
        String nextOffsetValue;
        public PollerWrapper(List<ContactWrapper> contactWrappers,Map<String,String> contactLoginToId)
        {
            this.contactWrappers = contactWrappers;
            this.contactLoginToId = contactLoginToId;
        }
    } 
    public class ContactWrapper
    {
        String accountId;
        List<String> contactIds;
        public ContactWrapper(String accountId,List<String> contactIds)
        {
            this.accountId = accountId;
            this.contactIds = contactIds;
        }
    }

    public class OneTimeWrapper
    {
        List<ContactWrapper> contactWrappers;
        List<SC_Jarvis_CoreSecurityController.ContactPermissionWrapper> permissionWrappers;

        public OneTimeWrapper (List<ContactWrapper> contactWrappers,
        List<SC_Jarvis_CoreSecurityController.ContactPermissionWrapper> permissionWrappers)
        {
            this.contactWrappers = contactWrappers;
            this.permissionWrappers = permissionWrappers;
        }
    }

    global SC_Jarvis_Contacts_Webservice() 
    {

    }
    @HttpPost
    global static String getContacts()
    {
        RestRequest req = RestContext.request;
        
        Map<String,String> params = (Map<String,String>)JSON.deserialize(req.requestBody.toString(), 
        Type.forName('Map<String,String>'));     
        system.debug('params: ' + params); 
        List<ContactWrapper> contactWrappers= new List<ContactWrapper>();
        Map<String,List<String>> accountToLogins = new Map<String,List<String>>();
        Boolean eligibleForPollers = !Test.isRunningTest();
        if(params.containsKey('offset') && !string.isblank(params.get('offset') ) 
        && params.containsKey('oneTimeSync') && !Boolean.valueOf(params.get('oneTimeSync')))
        {
            Map<String,String> contactLoginToIds = new Map<String,String>();
            PollerWrapper wrapper;
            system.debug('Inside: ' );
            String offsetValue = params.get('offset');
            String query = 'Select Id,Contact__r.Account.Akam_Account_Id__c, Contact__r.Login__c, Contact__r.AKAM_Account_Contact_Id__c from ' ;
            query += 'Jarvis_Contact_ACC_Permission__c where Active__c = true and isdeleted = false ';
            query += ' and Eligible_for_Pollers__c = :eligibleForPollers and Contact__r.Login__c != null and Active_Permission_Count__c < 10';
            query += ' and User__r.isactive = true and';
            query += ' (User__r.LastLoginDate < last_n_months:1 or (User__r.createddate <last_n_months:1 and User__r.LastLoginDate = null) )';
            query += offsetValue != null && offsetValue != ''? ' and Contact__r.AKAM_Account_Contact_Id__c > :offsetValue' : '';
            query += ' order by Contact__r.AKAM_Account_Contact_Id__c limit 2000';
             
            List<Jarvis_Contact_ACC_Permission__c> permissionRecords = Database.query(query);
            
            for(Jarvis_Contact_ACC_Permission__c permissionRecord: permissionRecords)
            {
                contactLoginToIds.put(permissionRecord.Contact__r.Login__c,
                permissionRecord.Id);
                if(!accountToLogins.containsKey(permissionRecord.Contact__r.Account.Akam_Account_Id__c))
                {
                    accountToLogins.put(permissionRecord.Contact__r.Account.Akam_Account_Id__c,new List<String>());
                }
                else if(accountToLogins.get(permissionRecord.Contact__r.Account.Akam_Account_Id__c).size() == 10)
                {
                    contactWrappers.add(new ContactWrapper(permissionRecord.Contact__r.Account.Akam_Account_Id__c,
                    accountToLogins.get(permissionRecord.Contact__r.Account.Akam_Account_Id__c)));
                    accountToLogins.put(permissionRecord.Contact__r.Account.Akam_Account_Id__c,new List<String>());                    
                }
                accountToLogins.get(permissionRecord.Contact__r.Account.Akam_Account_Id__c).add(permissionRecord.Contact__r.Login__c);

            }
            if(accountToLogins.size() > 0)
            {
                for(String accountId: accountToLogins.keySet())
                {
                    contactWrappers.add(new ContactWrapper(accountId,
                    accountToLogins.get(accountId)));
                }    
            }
            wrapper = new PollerWrapper(contactWrappers,contactLoginToIds);
            wrapper.nextOffsetValue = (permissionRecords != null && permissionRecords.size() > 0)? 
            permissionRecords.get(permissionRecords.size()-1).Contact__r.AKAM_Account_Contact_Id__c : '';
            return wrapper != null? JSON.serialize(wrapper) : '';
        }
        else if(params.containsKey('contacts') && !string.isblank(params.get('contacts'))  
        && params.containsKey('oneTimeSync') && Boolean.valueOf(params.get('oneTimeSync'))) 
        {

            OneTimeWrapper oneTimeWrapperRec;
            Map<String,String> contactLoginToAccount = new Map<String,String>();
            List<String> contactIds = params.get('contacts').split(','); 
            SC_Jarvis_CoreSecurityController.CreateUserWrapper createUserWrapperRec;
           
            if(contactIds != null && contactIds.size() > 0)           
            {
                System.debug('contactIds: '+contactIds);
                for(Contact contactRec: [Select account.Akam_Account_Id__c, login__c from Contact where id in :contactIds])
                {
                    contactLoginToAccount.put(contactRec.login__c,contactRec.account.Akam_Account_Id__c);
                }
                SC_Jarvis_CoreSecurityController.isOneTimeSync=true; 
                createUserWrapperRec = SC_Jarvis_CoreSecurityController.checkForUser(contactIds);
                
                if(params.containsKey('direct') && Boolean.valueOf(params.get('direct')) && createUserWrapperRec!= null 
                && createUserWrapperRec.wrappers !=null &&  createUserWrapperRec.wrappers.size() > 0)
                {
                    for(SC_Jarvis_CoreSecurityController.ContactPermissionWrapper contactWrapper: createUserWrapperRec.wrappers)
                    {
                        String currentAccounId = contactLoginToAccount.get(contactWrapper.login);
                        if(!accountToLogins.containsKey(currentAccounId))
                        {
                            accountToLogins.put(currentAccounId,new List<String>());
                        }
                        else if(accountToLogins.get(currentAccounId).size() == 10)
                        {
                            contactWrappers.add(new ContactWrapper(currentAccounId,
                            accountToLogins.get(currentAccounId)));
                            accountToLogins.put(currentAccounId,new List<String>());                    
                        }
                        accountToLogins.get(currentAccounId).add(contactWrapper.login);
                                
                    }
                    for(String accountId: accountToLogins.keySet())
                    {
                        contactWrappers.add(new ContactWrapper(accountId,
                        accountToLogins.get(accountId)));
                    }
                    oneTimeWrapperRec = new OneTimeWrapper (contactWrappers,createUserWrapperRec.wrappers);
                    return JSON.serialize(oneTimeWrapperRec);
                }
                
                else if(params.containsKey('direct') && !Boolean.valueOf(params.get('direct')) && createUserWrapperRec!= null 
                && createUserWrapperRec.wrappers !=null &&  createUserWrapperRec.wrappers.size() > 0)
                {
                    oneTimeWrapperRec = new OneTimeWrapper (new List<ContactWrapper>(),createUserWrapperRec.wrappers);
                    return JSON.serialize(oneTimeWrapperRec);
                }
            }
            
        }
        return '';
    }
    
    public static user createNewCustomerUser (Contact contactrec, User userRecord, String profileId)
    {
        user userRec = new user();
        userRec.Username = contactrec != null ?contactrec.email : userRecord.Username;
        userRec.AKAM_User_Id__c = contactrec != null ?contactrec.akam_contact_id__c : userRecord.AKAM_User_Id__c;
        userRec.FederationIdentifier = contactrec != null ?contactrec.akam_contact_id__c : userRecord.FederationIdentifier;
        userRec.contactId = contactrec != null ?contactrec.Id : userRecord.contactId;
        userRec.Phone = contactrec != null ?contactrec.phone : userRecord.Phone;
        userRec.Email = contactrec != null ?contactrec.email : userRecord.Email;
        userRec.FirstName = contactrec != null ?contactrec.firstname : userRecord.FirstName;
        userRec.LastName = contactrec != null ?contactrec.LastName : userRecord.LastName;
        userRec.Title = contactrec != null ?contactrec.title : userRecord.Title;
        userRec.CompanyName = contactrec != null ?contactrec.account.name : userRecord.CompanyName;
        String alias = '';
        if(userRec.FirstName == null) 
        {
            alias = userRec.LastName.length() > 4 ? 'CCM-' + userRec.LastName.substring(0, 3) : 'CCM-'+userRec.LastName;
        } 
        else 
        {
            alias = userRec.LastName.length() > 4 ? 'CCM-' + userRec.FirstName.charAt(0) + userRec.LastName.substring(0, 3) : 'CCM-' +  userRec.FirstName.charAt(0) + userRec.LastName ;
        }
        if(alias.length() > 8) 
        {
            alias = alias.substring(0, 7);
        }
        userRec.Alias = alias;
        
        userRec.LocaleSidKey = userRecord.LocaleSidKey;
        userRec.LanguageLocaleKey = userRecord.LanguageLocaleKey;
        userRec.TimeZoneSidKey = userRecord.TimeZoneSidKey;
        userRec.EmailEncodingKey = userRecord.EmailEncodingKey;
        userRec.ProfileId = profileId;
        
        return userRec;
    }

    public static user getLoggedInUser()
    {
        String userId = UserInfo.getUserId();
        return [SELECT LocaleSidKey, LanguageLocaleKey, TimeZoneSidKey, EmailEncodingKey FROM User WHERE Id=:userId];

    }
    
}