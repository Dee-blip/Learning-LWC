/*<!--Customer Community Component-->*/
//This class provides logic for inbound just-in-time provisioning of single sign-on users in your Salesforce organization.
global class CustomerCommunityJITHandler implements Auth.SamlJitHandler {
    
    private class JitException extends Exception{}
    
    private void handleUser(boolean create, User u, Map<String, String> attributes,String federationIdentifier, boolean isStandard,Id CommunityProfileId,Id permissionSetId,String UserType,String akamContactId, boolean activeLunaLogin) {
        if(create && attributes.containsKey('email')) {
            u.Username = attributes.get('email');
        }
        if(create){
            if(attributes.containsKey('federationIdentifier') || federationIdentifier != Null) {
                u.FederationIdentifier = attributes.get('federationIdentifier') == Null ? federationIdentifier : attributes.get('federationIdentifier');
                //u.AKAM_User_Id__c = akamContactId;
            } else {
                u.FederationIdentifier = akamContactId;
            }
        }
        if(create && (u.AKAM_User_Id__c == Null || u.AKAM_User_Id__c == '') && akamContactId != Null){
            u.AKAM_User_Id__c = akamContactId;
        }
        if(create){
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
            if(create && attributes.containsKey('email')) {
                u.Email = attributes.get('email');
            }
            if(create && attributes.containsKey('First')) {
                u.FirstName = attributes.get('First');
            }
            if(create && attributes.containsKey('Last')) {
                u.LastName = attributes.get('Last');
            }
            if(attributes.containsKey('User.Title')) {
                u.Title = attributes.get('User.Title');
            }
            if(create && attributes.containsKey('Company')) {
                u.CompanyName = attributes.get('Company');
            }   
        }
        
        String uid = UserInfo.getUserId();
        
        User currentUser = [SELECT LocaleSidKey, LanguageLocaleKey, TimeZoneSidKey, EmailEncodingKey FROM User WHERE Id=:uid];

        if(create) {
            u.LocaleSidKey = currentUser.LocaleSidKey;
        }
        if(create) {
            u.LanguageLocaleKey = currentUser.LanguageLocaleKey;
        }
        if(create) {
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
        }
        if(create) {
            u.TimeZoneSidKey = currentUser.TimeZoneSidKey;
        }
        if(create) {
            u.EmailEncodingKey = currentUser.EmailEncodingKey;
        }
        
        /*
* If you are updating Contact or Account object fields, you cannot update the following User fields at the same time.
* If your identity provider sends these User fields as attributes along with Contact 
* or Account fields, you must modify the logic in this class to update either these 
* User fields or the Contact and Account fields.
*/

        if((UserType == 'Customer' || UserType == 'Partner') && create) {
            u.ProfileId = CommunityProfileId;
            try{
                insert u;
            }
            Catch(Exception ex){
                throw new JitException('Cannot insert user  :'+UserType+'::'+ex);
            }
        }
        // if(UserType == 'Partner' && create){
        //     u.ProfileId = CommunityProfileId;
        //     try{
        //         insert u;
        //     }
        //     Catch(Exception ex){
        //         SC_Jarvis_utility.sendErrorMails('Jarvis JIT handler user create exception','Exception: ' , ex.getMessage());
        //         throw new JitException('Cannot insert user  :'+UserType+'::'+ex);
        //     }
        //     List<PermissionSetAssignment> userPermissionList =  new List<PermissionSetAssignment>([SELECT Assignee.Id, PermissionSet.Id,PermissionSet.Name, PermissionSet.isOwnedByProfile FROM PermissionSetAssignment WHERE (PermissionSetId =: permissionSetId) and AssigneeId =: u.Id LIMIT 1]);
        //     if(userPermissionList.size() == 0){
        //         PermissionSetAssignment ps = new PermissionSetAssignment ();
        //         ps.PermissionSetId = permissionSetId;
        //         ps.AssigneeId = u.id;
        //         try{
        //             insert ps;
        //         }
        //         Catch(Exception e){
        //             SC_Jarvis_utility.sendErrorMails('Jarvis JIT handler permission set assignment','Exception: ' , e.getMessage());
        //             throw new JitException('Cannot update Permission Set :'+UserType+'::'+e);
        //         }
        //     }
        // }
        if(UserType == 'Partner' && !create){
         system.debug('----Partner Permisison Update----');
            List<PermissionSetAssignment> userPermissionList =  new List<PermissionSetAssignment>([SELECT Assignee.Id, PermissionSet.Id,PermissionSet.Name, PermissionSet.isOwnedByProfile FROM PermissionSetAssignment WHERE (PermissionSetId =: permissionSetId) and AssigneeId =: u.Id LIMIT 1]);
            if(userPermissionList.size() == 0){
                PermissionSetAssignment ps = new PermissionSetAssignment ();
                ps.PermissionSetId = permissionSetId;
                ps.AssigneeId = u.id;
                try{
                    insert ps;
                     system.debug('----partner ps----'+ps.id);
                }
                Catch(Exception e){
                    SC_Jarvis_utility.sendErrorMails('Jarvis JIT handler permission set assignment','Exception: ' , e.getMessage());
                    throw new JitException('Cannot update Permission Set :'+UserType+'::'+e);
                }
            }
        }
        if(UserType == 'Employee' &&  !create){
             system.debug('----Employee Permisison Update----');
            List<PermissionSetAssignment> userEmpPermissionList =  new List<PermissionSetAssignment>([SELECT Assignee.Id, PermissionSet.Id,PermissionSet.Name, PermissionSet.isOwnedByProfile FROM PermissionSetAssignment WHERE (PermissionSetId =: permissionSetId) and AssigneeId =: u.Id LIMIT 1]);
            if(userEmpPermissionList.size() == 0){
                PermissionSetAssignment ps = new PermissionSetAssignment ();
                ps.PermissionSetId = permissionSetId;
                ps.AssigneeId = u.id;
                try{
                    insert ps;
                    system.debug('----Employee ps----'+ps.id);
                }
                Catch(Exception e){
                    SC_Jarvis_utility.sendErrorMails('Jarvis JIT handler permission set assignment','Exception: ' , e.getMessage());
                    throw new JitException('Cannot update Permission Set :'+UserType+'::'+e);
                }
            }
        }
        if(create){
            try{
                //insert u;
            }
            Catch(Exception ex){
                //throw new JitException('Cannot insert user  :'+UserType+'::'+ex);
            }
        }
        
        if(!create) {
            try{
                //update u;
            }
            Catch(Exception ex){
                //throw new JitException('Cannot update user  :'+UserType+'::'+ex);
            }
        }
    }
    
    private void handleJit(boolean create, User u, Id samlSsoProviderId, Id communityId, Id portalId,String federationIdentifier, Map<String, String> attributes, String assertion) {
        
        SFCommunity_NQLB_Topics__mdt  communityMdt = [SELECT ActivatePartnerCreation__c ,PartnerProfileId__c, PartnerCommunityProfileId__c, CustomerProfileId__c,PartnerPermissionSet__c,EmployeePermissionSet__c,ModeratorPermissionSetId__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        
        if(federationIdentifier != null) {
            if(attributes.containsKey('federationIdentifier') || federationIdentifier != Null) {
                String contact = attributes.get('federationIdentifier') == Null ? federationIdentifier : attributes.get('federationIdentifier');
                Contact c = [SELECT Id, AccountId,Account.IsPartner,Email,Account.Name,AKAM_Contact_Id__c,Active_Portal_Login__c FROM Contact WHERE AKAM_Contact_Id__c =:contact];
                
                Id ProfileId;
                Id permissionSetId;
                String UserType = '';
                string akamContactId = c.AKAM_Contact_Id__c;
                boolean activeLunaLogin = c.Active_Portal_Login__c;
                string sfEmailAtt = attributes.get('sfemail');
                sfEmailAtt = sfEmailAtt.right(6);
                system.debug('--sfEmailAtt--'+sfEmailAtt);
                //Partners: Checking if user is partner and doesn't have Customer Community Profile and SF Community Partner Permission Set
                // If true assignig permission set
                
                system.debug('----C----'+c);
                system.debug('----attributes.get(UserType)----'+attributes.get('UserType'));
                if(c != Null){
                    // if(attributes.get('UserType') != Null && attributes.get('UserType') == 'Partner'){
                        
                    //     ProfileId = communityMdt.PartnerProfileId__c;
                    //     permissionSetId = communityMdt.PartnerPermissionSet__c;
                    //     UserType = 'Partner';
                        
                    //     List<PermissionSetAssignment> userPermission =  new List<PermissionSetAssignment>([SELECT Assignee.Id, PermissionSet.Id,PermissionSet.Name, PermissionSet.isOwnedByProfile FROM PermissionSetAssignment WHERE (PermissionSetId =: permissionSetId or PermissionSetId =: communityMdt.ModeratorPermissionSetId__c) and AssigneeId =: u.Id LIMIT 1]);
                    //    system.debug('----userPermission----'+userPermission);
                    //     if(userPermission.size() == 0 && u.ProfileId != ProfileId) {
                    //         system.debug('----userPermission----'+userPermission);
                    //         if(communityMdt.ActivatePartnerCreation__c && create && (communityMdt.PartnerCommunityProfileId__c != Null || communityMdt.PartnerCommunityProfileId__c != '')){
                    //             ProfileId = communityMdt.PartnerCommunityProfileId__c;
                    //             handleUser(create, u, attributes, federationIdentifier, false,ProfileId,permissionSetId,UserType,akamContactId,activeLunaLogin);
                    //             system.debug('----ProfileId----'+ProfileId);
                    //         }
                    //         else if(create && communityMdt.ActivatePartnerCreation__c){
                    //             handleUser(create, u, attributes, federationIdentifier, false,ProfileId,permissionSetId,UserType,akamContactId,activeLunaLogin);
                    //             system.debug('---- Comm Partner ProfileId----'+ProfileId);
                    //         }
                    //         else{
                    //             system.debug('----Perm Update----');
                    //              handleUser(false, u, attributes, federationIdentifier, false,ProfileId,permissionSetId,UserType,akamContactId,activeLunaLogin);
                    //         }
                    //     }
                    // }
                    
                    //Employees: Checking if user is employee and doesn't have Salesforce Profile and SF Community Employee Permission Set
                    // If true assignig permission set                
                    if(attributes.get('UserType') != Null && attributes.get('UserType') == 'Employee' && c.Email.contains('@akamai.com') && c.Account.Name.contains('Akamai Technologies - Assets')){
                        permissionSetId = communityMdt.EmployeePermissionSet__c;
                        UserType = 'Employee';
                        List<PermissionSetAssignment> userPermission =  new List<PermissionSetAssignment>([SELECT Assignee.Id, PermissionSet.Id,PermissionSet.Name, PermissionSet.isOwnedByProfile FROM PermissionSetAssignment WHERE (PermissionSetId =: permissionSetId or PermissionSetId =: communityMdt.ModeratorPermissionSetId__c) and AssigneeId =: u.Id LIMIT 1]);
                        // userPermission = [SELECT Assignee.Id, PermissionSet.Id,PermissionSet.Name, PermissionSet.isOwnedByProfile FROM PermissionSetAssignment WHERE (PermissionSetId =: permissionSetId or PermissionSetId =: communityMdt.ModeratorPermissionSetId__c) and AssigneeId =: u.Id];
                        system.debug('----Employee Update----');
                        if(userPermission.size() == 0 && u.Profile.UserLicense.Name != 'Salesforce') {
                            system.debug('----Employee u.Profile.UserLicense.Name----'+u.Profile.UserLicense.Name);
                            permissionSetId = communityMdt.PartnerPermissionSet__c;
                            handleUser(create, u, attributes, federationIdentifier, false,ProfileId,permissionSetId,UserType,akamContactId,activeLunaLogin);
                        }
                        else if(userPermission.size() == 0 && u.Profile.UserLicense.Name == 'Salesforce'){
                            system.debug('----Employee u.Profile.UserLicense.Name----'+u.Profile.UserLicense.Name);
                            handleUser(create, u, attributes, federationIdentifier, false,ProfileId,permissionSetId,UserType,akamContactId,activeLunaLogin);
                        }
                    }   
                    else if(attributes.get('UserType') != Null && (attributes.get('UserType') == 'Customer' || attributes.get('UserType') == 'Partner')){
                        system.debug('----Customer u.Profile.UserLicense.Name----'+attributes.get('UserType'));
                        ProfileId = communityMdt.CustomerProfileId__c;
                        UserType = 'Customer';
                        handleUser(create, u, attributes, federationIdentifier, false,ProfileId,permissionSetId,UserType,akamContactId,activeLunaLogin);
                    }
                }
                
                //String account = handleAccount(create, u, attributes);
                //handleContact(create, account, u, attributes);
            } 
        }
        else {
            //handleUser(create, u, attributes, federationIdentifier, true,ProfileId,permissionSetId,UserType);
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
            
            // if(attributes.containsKey('federationIdentifier'))
            // {
            //     usr = new List<User>([Select id,contact.login__c,contact.Jarvis_Login__c,contactId,email,AKAM_User_Id__c,Profile.Name,ProfileId,Contact.AKAM_Contact_Id__c,Profile.UserLicense.Name,isActive from User where (AKAM_User_Id__c = :attributes.get('federationIdentifier') OR Contact.AKAM_Contact_Id__c =:attributes.get('federationIdentifier')) limit 1]);
            // }
            // else{
            //     usr = new List<User>([Select id,contact.login__c,contact.Jarvis_Login__c,contactId,email,AKAM_User_Id__c,Profile.Name,ProfileId,Contact.AKAM_Contact_Id__c,Profile.UserLicense.Name,isActive from User where (Contact.AKAM_Contact_Id__c = :federationIdentifier OR AKAM_User_Id__c = :federationIdentifier) limit 1]);
            // }
            
            system.debug('---Inside Insert usr---'+usr);
            
            if(usr.size() == 0){
                newUsr = new user();
                handleJit(true, newUsr, samlSsoProviderId, communityId, portalId,federationIdentifier, attributes, assertion);
                try 
                {
                    getPermissionFromIdmFuture(newUsr.Id);    
                } 
                catch (Exception e) 
                {
                    SC_Jarvis_utility.sendErrorMails('Jarvis JIT handler IDM API call Exception','Exception: ' , e.getMessage());
                }                
                return newUsr;
            }
            else if(usr.size() > 0 && !usr[0].isActive && (usr[0].Profile.UserLicense.Name == 'Customer Community Plus Login' || usr[0].Profile.UserLicense.Name == 'Partner Community')){
                User activateUser =  new User();
                activateUser.isActive = true;
                activateUser.Id = usr[0].Id;
                try{
                    update activateUser;
                    getPermissionFromIdmFuture(newUsr.Id);   
                    return activateUser;
                }
                Catch(Exception ex){
                    SC_Jarvis_utility.sendErrorMails('Jarvis JIT handler user Activation Exception','Exception: ' , ex.getMessage());
                    throw new JitException('Cannot Activate User  :'+attributes.get('UserType')+'::'+ex);
                }
                
            }
            else if(usr.size() > 0 && usr[0].isActive)
            {
                newUsr = usr[0];
                try 
                {
                    if(newUsr.contactId != null)
                    {
                        getPermissionFromIdm(newUsr);    
                        SFCommunity_NQLB_Topics__mdt  communityMdt = [SELECT CustomerProfileId__c,GuestProfileId__c FROM 
                        SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];                            
                        if(newUsr.profileId == communityMdt.GuestProfileId__c || 
                        String.ValueOf(newUsr.profileId).contains(communityMdt.GuestProfileId__c) ||
                          newUsr.Profile.Name =='SFWelinaGuests')
                        {
                            newUsr.profileId = communityMdt.CustomerProfileId__c;
                            update newUsr;
                        }
                    }
                        
                } 
                catch (Exception e) 
                {
                    SC_Jarvis_utility.sendErrorMails('Jarvis JIT handler user profile Update','Exception: ' , e.getMessage());
                    system.debug('Inside Create: Exception: ' + e.getMessage());
                }
                return newUsr;
                  // handleJit(false, usr[0], samlSsoProviderId, communityId, portalId,federationIdentifier, attributes, assertion);
            }
        }
        return null;
    }
    
    global void updateUser(Id userId, Id samlSsoProviderId, Id communityId, Id portalId,String federationIdentifier, Map<String, String> attributes, String assertion) { 
        //User u = [SELECT Id, FirstName, ContactId FROM User WHERE Id=:userId];
        List<User> usr;
        system.debug('---Inside Update---');
        system.debug('---Inside Update attributes---'+attributes);
        SFCommunity_NQLB_Topics__mdt  communityMdt = [SELECT CustomerProfileId__c,GuestProfileId__c,PartnerPermissionSet__c FROM 
        SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];                            

        if(attributes.containsKey('federationIdentifier') || federationIdentifier != Null)
        {
            system.debug('---Inside Update federationIdentifier---'+federationIdentifier);

            String federationIdentifierString = attributes.containsKey('federationIdentifier') ? 
            attributes.get('federationIdentifier'): federationIdentifier;
            
            usr = new List<User>([Select id,contact.Login__c,contactId,email,AKAM_User_Id__c,
            Profile.Name,ProfileId,Contact.AKAM_Contact_Id__c,Profile.UserLicense.Name,isActive,contact.Account.Akam_Account_Id__c from User 
            where (federationIdentifier = :federationIdentifierString OR 
            federationIdentifier = :federationIdentifierString) limit 1]);

            // if(attributes.containsKey('federationIdentifier')){
            //     usr = new List<User>([Select id,contact.login__c,contact.Jarvis_Login__c,contactId,email,AKAM_User_Id__c,Profile.Name,ProfileId,Contact.AKAM_Contact_Id__c,Profile.UserLicense.Name,isActive from User where (federationIdentifier = :attributes.get('federationIdentifier') OR federationIdentifier = :attributes.get('federationIdentifier')) limit 1]);
            // }
            // else{
            //     usr = new List<User>([Select id,contact.login__c,contact.Jarvis_Login__c,contactId,email,AKAM_User_Id__c,Profile.Name,ProfileId,Contact.AKAM_Contact_Id__c,Profile.UserLicense.Name,isActive from User where (federationIdentifier = :federationIdentifier OR federationIdentifier = :federationIdentifier) limit 1]);
            // }

            if(usr.size() > 0 && (usr[0].Profile.UserLicense.Name == 'Customer Community Plus Login' 
            || usr[0].Profile.UserLicense.Name == 'Partner Community'))
            {
                User activateUser;
                PermissionSetAssignment ps;
                if(!usr[0].isActive)
                {
                    activateUser =  new User();
                    activateUser.isActive = true;
                    activateUser.Id = usr[0].Id;
                }
                if(usr[0].profileId == communityMdt.GuestProfileId__c
                ||String.ValueOf(usr[0].profileId).contains(communityMdt.GuestProfileId__c) ||
                  usr[0].Profile.Name =='SFWelinaGuests')
                {
                    if(activateUser == null)
                    {
                        activateUser =  new User();
                        activateUser.isActive = true;
                        activateUser.Id = usr[0].Id;    
                    }
                    activateUser.profileId = communityMdt.CustomerProfileId__c;
                }
                if(activateUser != null)
                {
                    try 
                    {
                        update activateUser;    
                    } 
                    Catch(Exception ex)
                    {
                        SC_Jarvis_utility.sendErrorMails('Jarvis JIT handler UpdateUser method Error ','Exception: ' , ex.getMessage());
                        throw new JitException('Cannot Activate User  :'+attributes.get('UserType')+'::'+ex);
                    }
                    
                }
                if(usr[0].Profile.UserLicense.Name == 'Partner Community')
                {
                    List<PermissionSetAssignment> userPermissionList =  new List<PermissionSetAssignment>([SELECT Assignee.Id, PermissionSet.Id,PermissionSet.Name, PermissionSet.isOwnedByProfile FROM 
                    PermissionSetAssignment WHERE (PermissionSetId =: communityMdt.PartnerPermissionSet__c) and AssigneeId =: usr[0].Id LIMIT 1]);
                    if(userPermissionList.size() == 0)
                    {
                        ps = new PermissionSetAssignment ();
                        ps.PermissionSetId = communityMdt.PartnerPermissionSet__c;
                        ps.AssigneeId = usr[0].id;
                        try
                        {
                            insert ps;
                        }
                        Catch(Exception e)
                        {
                            SC_Jarvis_utility.sendErrorMails('Jarvis JIT handler permission set assignment','Exception: ' , e.getMessage());
                            throw new JitException('Cannot update Permission Set :'+'::'+e.getMessage());
                        }
                    }

                }
                try 
                {
                    if(ps != null || activateUser != null)
                    {
                        getPermissionFromIdmFuture(usr[0].id);
                    }
                    else 
                    {
                        getPermissionFromIdm(usr[0]);                        
                    }
                } 
                catch (Exception e) 
                {
                    SC_Jarvis_utility.sendErrorMails('Jarvis JIT handler IDM API call Error','Exception: ' , e.getMessage());
                }
            }
            else if(usr.size() > 0 && usr[0].isActive)
            {
                handleJit(false, usr[0], samlSsoProviderId, communityId, portalId,federationIdentifier, attributes, assertion);
                //return usr[0];
                  // handleJit(false, usr[0], samlSsoProviderId, communityId, portalId,federationIdentifier, attributes, assertion);
            }
        } 
    }
    //handleJit(false, u, samlSsoProviderId, communityId, portalId,federationIdentifier, attributes, assertion);
    @future(callout=true)
    public static void getPermissionFromIdmFuture(Id userId)
    {
        user userRec = [Select Id, contactId,Contact.AKAM_Contact_Id__c,contact.Login__c,contact.Account.Akam_Account_Id__c from User where Id = :userId];
        getPermissionFromIdm(userRec);
    }
    public static void getPermissionFromIdm(user currentUser)
    {
        system.debug('BEFORE IDM SYNC!');
        Set<String> limitedBetaAccountIds;                                               
        
        for(SC_Utility__mdt eachRec : [SELECT DeveloperName,Value_Text__c from SC_Utility__mdt
        where DeveloperName IN ('JarvisLimitedBetaAccount')])
        {
            if(eachRec.Value_Text__c != null && eachRec.Value_Text__c != 'ALL')
            {                    
                if(limitedBetaAccountIds == null)
                {
                    limitedBetaAccountIds = new Set<String>();
                }
                limitedBetaAccountIds.addAll(eachRec.Value_Text__c.split(','));
            }
        }
    
        if(limitedBetaAccountIds == null || limitedBetaAccountIds.size() == 0 
	        || (currentUser.contact.Account.Akam_Account_Id__c != null && 
        limitedBetaAccountIds.contains(currentUser.contact.Account.Akam_Account_Id__c)))
        {
            Datetime startTime = system.now();
            List<SC_Jarvis_CoreSecurityController.ContactPermissionWrapper> wrappers = new List<SC_Jarvis_CoreSecurityController.ContactPermissionWrapper>();
            if(currentUser.contactId != null)
            {
                wrappers.add(new SC_Jarvis_CoreSecurityController.ContactPermissionWrapper(currentUser.contactId,currentUser.Contact.AKAM_Contact_Id__c,currentUser.Id,currentUser.contact.Login__c));
                SC_Jarvis_CoreSecurityController.getIdmPermission(wrappers);    
            }
            Datetime endTime = system.now();
            system.debug('Total time: ' + ((endTime.getTime() - startTime.getTime())/1000));                
    
        }

    }

}