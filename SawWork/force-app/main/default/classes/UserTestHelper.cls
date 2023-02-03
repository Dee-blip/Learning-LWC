public class UserTestHelper {
    /*
    * Builder class that build the 'User' object.
    * Modification ==============================
    * Addition of functions -> withAlias, withManager and inactivateUser
    * By Amogh M P
    */
    public class UserBuilder{
        private User record;
        
        public UserBuilder() {
            Profile adminProfile = [SELECT Id FROM Profile WHERE Name= 'System Administrator' LIMIT 100];
            record = new User(
                Alias = 'tUser', 
                Email='abudnar@akamai.com',
                EmailEncodingKey='UTF-8', 
                LastName='User', 
                FirstName = 'Test',
                LanguageLocaleKey='en_US',
                LocaleSidKey='en_US', 
                ProfileId = adminProfile.Id,
                TimeZoneSidKey='America/Los_Angeles', 
                UserName= 'test.user@akamai.com');
        }
        
        public UserBuilder(User user) {
            record = user.clone();
        }
        
        public UserBuilder withFirstName(String firstName) {
            record.FirstName = firstName;
            return this;
        }
        
        public UserBuilder withLastName(String lastName) {
            record.LastName = lastName;
            return this;
        }
        
        public UserBuilder withUserName(String userName) {
            record.UserName = userName;
            return this;
        }
        
        public UserBuilder withEmail(String email) {
            record.Email = email;
            return this;
        }
        
        public UserBuilder withProfile(Id profileId) {
            record.ProfileId = profileId;
            return this;
        }
        
        public UserBuilder withTitle(String title) {
            record.Title = title;
            return this;
        }
        
        public UserBuilder withRole(Id roleId) {
            record.UserRoleId = roleId;
            return this;
        }
        
        public UserBuilder withConfidentialDataFlag(Boolean flagStatus) {
            record.HD_View_Helpdesk_Confidential_Data__c = flagStatus;
            return this;
        }
        
        public UserBuilder withAlias(String alias) {
            record.Alias = alias;
            return this;
        }
        
        public UserBuilder withManager(Id id) {
            record.ManagerId = id;
            return this;
        }
        
        public User inactivateUser(User normalUser){
            normalUser.IsActive = False;
            update normalUser;
            return normalUser;
        }
        
        public User build() {
            return record;
        }
        
        public User buildAndSave() {
            insert record;
            return record;
        }
    }
}