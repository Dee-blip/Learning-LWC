/*
* Name : MTVSetupController
* Date : 7/10/10
* Author ; Rohit Mehta (Apprivo)
* Usage : Controller for the MTV App Setup. initially setup is for object associations & account
* hierarchy
*/
public with sharing class MTVSetupController {

    public Configuration config {get; private set;}
    public List<ObjectAssociationSettings__c> associationSettings {get; private set;}
    
    public MTVSetupController() {
        config = new Configuration();
        associationSettings = config.getAssociationSettings();
        if (associationSettings.isEmpty()) {
            associationSettings.add(new ObjectAssociationSettings__c(Name = Configuration.ACCOUNT, Access_Level__c = Configuration.ACCESS_READ));
            associationSettings.add(new ObjectAssociationSettings__c(Name = Configuration.LEAD, Access_Level__c = Configuration.ACCESS_READ));
            associationSettings.add(new ObjectAssociationSettings__c(Name = Configuration.OPPORTUNITY, Access_Level__c = Configuration.ACCESS_READ));
        }
    }
    
    public PageReference onSave() {
        upsert associationSettings;
        upsert config.orgSetting;
        return new PageReference('/0A3');
    }
    
    public PageReference onCancel() {
        return new PageReference('/0A3');
    }
    
    public List<SelectOption> getAvailableAccessLevels() {
        List<SelectOption> availableAccessLevels = new List<SelectOption>();
        //availableAccessLevels.add(new SelectOption('None', 'None'));
        availableAccessLevels.add(new SelectOption(Configuration.ACCESS_READ, 'Read'));
        availableAccessLevels.add(new SelectOption(Configuration.ACCESS_EDIT, 'Read / Write'));
        return availableAccessLevels;
    }
    
    public List<SelectOption> getAvailablePortalRoles() {
        List<SelectOption> availablePortalRoles = new List<SelectOption>();
        availablePortalRoles.add(new SelectOption('Partner', 'Partner'));
        //availableAccessLevels.add(new SelectOption('Customer', 'Customer'));
        return availablePortalRoles;
    }
}