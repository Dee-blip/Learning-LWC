public without sharing class UpdatedUser{
    Id userId;
    Id oldProfileId;
    Id newProfileId;
    Id oldContactId;
    Id newContactId;
    Id oldAccountId;
    Id newAccountId;
    String liteProfileId;
    String newProfileName;
    Boolean oldStatus=false;
    Boolean newStatus=false;
    Boolean isNewUser=false;

    public UpdatedUser(User oldUser, User newUser) {
        isNewUser = false;
        this.userId = newUser.Id;
        this.oldProfileId = oldUser.ProfileId;
        this.newProfileId = newUser.ProfileId;
        this.oldContactId = oldUser.contactId;
        this.newContactId = newUser.contactId;
        this.oldAccountId = oldUser.AccountId;
        this.newAccountId = newUser.AccountId;
        this.oldStatus = oldUser.isActive;
        if(oldStatus==false)
        {
            isNewUser=true;
        }
        this.newStatus = newUser.isActive;
        this.liteProfileId = NAPSettings.getValue('PartnerCommunityLiteProfileId');
    }
   
    public UpdatedUser(User newUser) {
        this.isNewUser = true;
        this.userId = newUser.Id;
        this.newProfileId = newUser.ProfileId;
        this.newContactId = newUser.contactId;
        this.newAccountId = newUser.AccountId;
        this.newStatus = newUser.isActive;
        this.liteProfileId = NAPSettings.getValue('PartnerCommunityLiteProfileId');
    }

    public UpdatedUser(Id oldAccId, Id newAccId, String newProfileName)
    {
        this.newAccountId = newAccId;
        this.oldAccountId = oldAccId;
        this.newProfileName = newProfileName;
        this.newStatus = true;
        isNewUser =false;
    }

    public Boolean wasLiteProfile(){
        return !isNewUser && liteProfileId.containsIgnoreCase(oldProfileId);
    }

    public Boolean wasNonLiteProfile(){
        return !isNewUser && !liteProfileId.containsIgnoreCase(oldProfileId);
    }

    public Boolean isLiteProfile(){
        if(String.isBlank(newProfileName))
            return liteProfileId.containsIgnoreCase(newProfileId);

        if('Partner Community Lite'.equalsIgnoreCase(newProfileName))
            return true;

        return false;
    }

    public Boolean isNonLiteProfile(){
        return !isLiteProfile();
    }

    public Boolean isChangingFromLiteToNonLite(){
        return wasLiteProfile() && isNonLiteProfile();
    }

    public Boolean isChangingFromNonLiteAToNonLiteB(){
        return !isNewUser && oldProfileId!=newProfileId && wasNonLiteProfile() && isNonLiteProfile();
    }

    public Boolean isChangingFromNonLiteToLite(){
        return wasNonLiteProfile() && isLiteProfile();
    }

    public Boolean isGettingDeactivated(){
        return (oldStatus==true && newStatus==false);
    }

    public Boolean isGettingActivated(){
        return (oldStatus==false && newStatus==true);
    }

    public Boolean contactNeedsUpdate(){
        return isNewUser || isGettingActivated() || isGettingDeactivated();
    }

    public Id getAccountId(){
        return this.newAccountId;
    }

    public Id getOldAccountId(){
        return this.oldAccountId;
    }

    public Boolean hasChangedAccount(){
        return !String.isBlank(oldAccountId) && oldAccountId!=newAccountId;
    }


    public Contact getContact(){
        if(newStatus==true){
            return new Contact(Id=this.newContactId, Validation_Override__c=true, Partner_User__c=this.userId, Active_Partner__c=true);
        }
        else{
            return new Contact(Id=this.newContactId, Validation_Override__c=true, Partner_User__c=null, Active_Partner__c=false);
        }

    }

    public Boolean isActive(){
        return newStatus;
    }

    public Boolean wasActive(){
        return oldStatus;
    }

    
}