/*<!--Welina JIT Component-->*/
//This class provides logic for inbound just-in-time provisioning of single sign-on users in your Salesforce organization.
global class WelinaPlaygroundJITHandler implements Auth.SamlJitHandler {
    
    private class JitException extends Exception{}
    
    private void handleUser(boolean create, User u, Map<String, String> attributes,String federationIdentifier, boolean isStandard,Id CommunityProfileId,String UserType,String akamContactId, boolean activeLunaLogin) {
       if(create){
            if(attributes.containsKey('email')) {
                u.Username = attributes.get('email');
            }
            if(attributes.containsKey('federationIdentifier') || federationIdentifier != Null) {
                u.FederationIdentifier = attributes.get('federationIdentifier') == Null ? federationIdentifier : attributes.get('federationIdentifier');
            } else {
                u.FederationIdentifier = akamContactId;
            }
            if((u.AKAM_User_Id__c == Null || u.AKAM_User_Id__c == '') && akamContactId != Null){
                u.AKAM_User_Id__c = akamContactId;
            }
            if(akamContactId != '' || federationIdentifier != Null){
                string akamContId = akamContactId != '' ? akamContactId : federationIdentifier;
                Contact c = [Select id from contact where AKAM_Contact_Id__c =:akamContactId limit 1];
                if(c != Null){
                    u.contactId = c.Id;
                }
            }
            if(attributes.containsKey('User.Phone')) {
                u.Phone = attributes.get('User.Phone');
            }
            if(attributes.containsKey('email')) {
                u.Email = attributes.get('email');
            }
            if(attributes.containsKey('First')) {
                u.FirstName = attributes.get('First');
            }
            if(attributes.containsKey('Last')) {
                u.LastName = attributes.get('Last');
            }
            if(attributes.containsKey('User.Title')) {
                u.Title = attributes.get('User.Title');
            }
            if(attributes.containsKey('Company')) {
                u.CompanyName = attributes.get('Company');
            }   
        }
        
        String uid = UserInfo.getUserId();
        
        User currentUser = [SELECT LocaleSidKey, LanguageLocaleKey, TimeZoneSidKey, EmailEncodingKey FROM User WHERE Id=:uid];
        
        if(create) {
            u.LocaleSidKey = currentUser.LocaleSidKey;
            u.LanguageLocaleKey = currentUser.LanguageLocaleKey;
            String alias = '';
            if(u.FirstName == null) {
                alias = u.LastName.length() > 4 ? 'CCM-' + u.LastName.substring(0, 3) : 'CCM-'+u.LastName;
            } else {
                alias = u.LastName.length() > 4 ? 'CCM-' + u.FirstName.charAt(0) + u.LastName.substring(0, 3) : 'CCM-' +  u.FirstName.charAt(0) + u.LastName ;
            }
            if(alias.length() > 8) {
                alias = alias.substring(0, 7);
            }
            u.Alias = alias;
            u.TimeZoneSidKey = currentUser.TimeZoneSidKey;
            u.EmailEncodingKey = currentUser.EmailEncodingKey;
        }
        if((UserType == 'Customer' || UserType == 'Partner') && create) {
            u.ProfileId = CommunityProfileId;// assign welina profile here
            try{
                insert u;
            }
            Catch(Exception ex){
                throw new JitException('Cannot insert user  :'+UserType+'::'+ex);
            }
        }
    }
    private void handleJit(boolean create, User u, Id samlSsoProviderId, Id communityId, Id portalId,String federationIdentifier, Map<String, String> attributes, String assertion) {
        
        SFCommunity_NQLB_Topics__mdt  communityMdt = [SELECT CustomerProfileId__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'WelinaNQLB' limit 1];
        
        if(federationIdentifier != null) {
            if(attributes.containsKey('federationIdentifier') || federationIdentifier != Null) {
                String contact = attributes.get('federationIdentifier') == Null ? federationIdentifier : attributes.get('federationIdentifier');
                Contact c = [SELECT Id, AccountId,Account.IsPartner,Email,Account.Name,AKAM_Contact_Id__c,Active_Portal_Login__c FROM Contact WHERE AKAM_Contact_Id__c =:contact];
                
                Id ProfileId;
                Id permissionSetId;
                String UserType = '';
                string akamContactId = c.AKAM_Contact_Id__c;
                boolean activeLunaLogin = c.Active_Portal_Login__c;
                system.debug('----C----'+c);
                system.debug('----attributes.get(UserType)----'+attributes.get('UserType'));
                if(c != Null){            
                    if(attributes.get('UserType') != Null && attributes.get('UserType') == 'Employee' && c.Email.contains('@akamai.com') && c.Account.Name.contains('Akamai Technologies - Assets')){
                        UserType = 'Employee';
                        system.debug('----Employee Update----'+attributes.get('UserType'));
                        Error_Log__c employeeCreateError = new Error_Log__c(Name='Cannot create Employee type User. Exception', Class__c='WelinaIJIT.handleJit', Error_Message__c='User not allowed, Error. federationIdentifier : ' + federationIdentifier + ' akamContactId : ' + akamContactId);
                        insert employeeCreateError;
                        throw new JitException('Cannot Insert UserType: Employee');
                    }   
                    if(attributes.get('UserType') != Null && (attributes.get('UserType') == 'Customer')){
                        system.debug('----Customer----'+attributes.get('UserType'));
                        UserType = 'Customer';
                    }else if(attributes.get('UserType') != Null && (attributes.get('UserType') == 'Partner')){
                        system.debug('----Partner----'+attributes.get('UserType'));
                        UserType = 'Partner';
                    }
                    ProfileId = communityMdt.CustomerProfileId__c;
                    handleUser(create, u, attributes, federationIdentifier, false,ProfileId,UserType,akamContactId,activeLunaLogin);
                }
            } 
        }
    }
    
    global User createUser(Id samlSsoProviderId, Id communityId, Id portalId,String federationIdentifier, Map<String, String> attributes, String assertion) {
        List<User> usr;
        user newUsr;
        system.debug('---Inside Insert---');
        system.debug('---Inside Insert attributes---'+attributes);
        if(attributes.containsKey('federationIdentifier') || federationIdentifier != Null){
            system.debug('---Inside Insert federationIdentifier---'+federationIdentifier);
            
            String federationIdentifierString = attributes.containsKey('federationIdentifier') ? 
                attributes.get('federationIdentifier'): federationIdentifier;
            
            usr = new List<User>([Select id,contact.Login__c,contactId,email,AKAM_User_Id__c,
                                  Profile.Name,ProfileId,Contact.AKAM_Contact_Id__c,Profile.UserLicense.Name,isActive,contact.Account.Akam_Account_Id__c from User where 
                                  (AKAM_User_Id__c = :federationIdentifierString OR Contact.AKAM_Contact_Id__c =:federationIdentifierString) limit 1]);
            
            system.debug('---Inside Insert usr---'+usr);
            
            if(usr.size() == 0){
                newUsr = new user();
                handleJit(true, newUsr, samlSsoProviderId, communityId, portalId,federationIdentifier, attributes, assertion);               
                return newUsr;
            } else if(usr.size() > 0 && !usr[0].isActive){
                User activateUser =  new User();
                activateUser.isActive = true;
                activateUser.Id = usr[0].Id;
                try{
                    update activateUser;
                    return activateUser;
                } catch(Exception ex){
                    Error_Log__c auditLog2 = new Error_Log__c(Name='No user permission already exists', Class__c='WelinaIJIT.CreateUserPermission', Error_Message__c='User not allowed, Error : ' + ex.getMessage());
                    insert auditLog2;
                    throw new JitException('Cannot Activate User. Exception : '+ attributes.get('UserType')+'::'+ex);
                }
            }
        }
        return null;
    }
    
    global void updateUser(Id userId, Id samlSsoProviderId, Id communityId, Id portalId,String federationIdentifier, Map<String, String> attributes, String assertion) { 
        //User u = [SELECT Id, FirstName, ContactId FROM User WHERE Id=:userId];
        List<User> usr;
        system.debug('---Inside Update---');
        system.debug('---Inside Update attributes---'+attributes);
        if(attributes.containsKey('federationIdentifier') || federationIdentifier != Null)
        {
            system.debug('---Inside Update federationIdentifier---'+federationIdentifier);
            
            String federationIdentifierString = attributes.containsKey('federationIdentifier') ? 
                attributes.get('federationIdentifier'): federationIdentifier;
            
            usr = new List<User>([Select id,contact.Login__c,contactId,email,AKAM_User_Id__c,
                                  Profile.Name,ProfileId,Contact.AKAM_Contact_Id__c,Profile.UserLicense.Name,isActive,contact.Account.Akam_Account_Id__c from User 
                                  where federationIdentifier = :federationIdentifierString limit 1]);
            
            if(usr.size() > 0)
            {
                User activateUser;
                if(!usr[0].isActive)
                {
                    activateUser =  new User();
                    activateUser.isActive = true;
                    activateUser.Id = usr[0].Id;
                }
                
                if(activateUser != null)
                {
                    try 
                    {
                        update activateUser;    
                    } 
                    Catch(Exception ex)
                    {
                        Error_Log__c leadAuditLog4  = new Error_Log__c(Name='Cannot Activate User', Class__c='WelinaIJIT.UpdateUser', Error_Message__c='Cannot Activate User, Error : ' + ex.getMessage());
                        insert leadAuditLog4;
                        throw new JitException('Cannot Activate update User  :'+attributes.get('UserType')+'::'+ex);
                    }
                }
            }
        } 
    }
}