public without sharing class CurrentUser{

    public static Map<String, String> attributes;
    public static boolean isSubscribedToFileLibrary;
    public static boolean hasStartTrialPermissions=false;
    public static boolean hasViewTrialPermissions=false;
    public static boolean isPartner=false;
    //SFDC- 1673 - Changing name to make it more generic
    //public static Set<String> profilePermSetNAPArea;
    public static Set<String> profileAndPermissionSets;

    // Initialization code. Runs even before constructror - https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_static.htm

    static
    {
        attributes = new Map<String, String>();
        // These default initializations are needed because even internal users have been given access to the page
        attributes.put('Partner Account', '');
        attributes.put('NAP Partner Reach', '');
        attributes.put('Tier', '');
        attributes.put('NAP Partner Type', '');
        attributes.put('Custom Price List','False');
        attributes.put('User Type', 'Internal');
        
        attributes.put('NAP Area','');
        
        profileAndPermissionSets = new Set<String>();
        profileAndPermissionSets.add(String.valueOf(UserInfo.getProfileId()).substring(0,15));      
            
        // AGH - please dont add any more string properties to this map. the above key value pairs 
        // were created so that they match the picklist values in file filters
        // if you need a boolean, create a separate boolean member, dont add to this map
        // this is ugly 
        // ST - ^ There were no comments explaining why this piece of code was being used. Next time please add comments to avoid ugliness. 
        //attributes.put('Subscribed To File Library', 'false');

        isSubscribedToFileLibrary=false;
        isPartner=false;

        for(User u:[select ContactId,NAP_Area__c,Contact.Subscribed_to_Library__c,Contact.AccountId, Contact.Account.Partner_Tier__c, Contact.Account.Partner_Reach__c, Contact.Account.NAP_Partner_Type__c, Contact.Account.Partner_Custom_Pricing__c,Has_View_Trial_Access__c,Has_Start_Trial_Access__c from User where Id = :UserInfo.getUserId() and ContactId!=null and isActive=true])
        {
            isPartner=true;
            attributes.put('User Type', 'Partner');
            attributes.put('Partner Account', u.Contact.AccountId);
            attributes.put('NAP Partner Reach', u.Contact.Account.Partner_Reach__c);
            attributes.put('Tier', u.Contact.Account.Partner_Tier__c);
            attributes.put('NAP Partner Type', u.Contact.Account.NAP_Partner_Type__c);

            if(u.Contact.Subscribed_to_Library__c!=null && u.Contact.Subscribed_to_Library__c==true)
                isSubscribedToFileLibrary=true;

            attributes.put('Contact Id',u.ContactId);

            if(u.Contact.Account.Partner_Custom_Pricing__c)
            {
                attributes.put('Custom Price List', 'True');
            }

            hasStartTrialPermissions=u.Has_Start_Trial_Access__c;
            hasViewTrialPermissions=u.Has_View_Trial_Access__c;
            //SFDC-1673 - Added the new attribute 
            if(u.NAP_Area__c != '')
            {
                
                attributes.put('NAP Area',u.NAP_Area__c);

            } 

        }
        for(PermissionSetAssignment permission : [SELECT PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId =:UserInfo.getUserId()])
            {
                profileAndPermissionSets.add(String.valueOf(permission.PermissionSetId).substring(0,15));
            }

    }

    public static Boolean hasFileAccess(Id cvId)
    {
        List<ContentVersionAttribute__c> cvAttributes = [select Id, Name, Attribute_Value__c, Attribute_Name__c, Partner_Account__c, Partner_Account__r.ParentId from ContentVersionAttribute__c where ContentVersionId__c=:cvId];
        //SFDC-6265
        if(cvAttributes==null || cvAttributes.size()==0) {
            if(!GsmUtilClass.isFeatureToggleEnabledCustomMetadata('PartnerFileAccessByContentDeliveries')) {
                return true;
            }
            try {
                ContentVersion contentVersionRecord = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cvId];
                String partnerSharingLibraryId = NAPSettings.getValue('LibrariesAvailableForPartnerFileDownload');
                if(partnerSharingLibraryId != null && partnerSharingLibraryId != '') {
                    List<String> listOfAvailableLibraries = partnerSharingLibraryId.split(',');
                    List<ContentWorkspaceDoc>   workspaceDocs = [SELECT Id, ContentDocumentId FROM ContentWorkspaceDoc WHERE ContentDocumentId = :contentVersionRecord.ContentDocumentId AND ContentWorkspaceId IN :listOfAvailableLibraries];
                    if(workspaceDocs.size() > 0) {
                        return true;
                    } 
                }
            } 
            catch (Exception e) {
                String errorMessage = 'Error : ' + e.getMessage() + '\n' + 'Stack trace : ' + e.getStackTraceString();
                Error_Log__c el = new Error_Log__c(Name = 'hasFileAccess-queryerror', Class__c = 'CurrentUser', Error_Message__c = errorMessage);
                insert el;
            }
            return false;
        }

        for(ContentVersionAttribute__c cva : cvAttributes)
        {
            System.Debug(LoggingLevel.Error, 'AGH_D cva'+cva);
            if((cva.Attribute_Value__c!=null && attributes.containsKey(cva.Attribute_Name__c) && !attributes.get(cva.Attribute_Name__c).equals(cva.Attribute_Value__c))
            || (cva.Attribute_Name__c=='Partner Account' && !attributes.get('Partner Account').equals(cva.Partner_Account__c) && cva.Partner_Account__r.ParentId != null && !attributes.get('Partner Account').equals(cva.Partner_Account__r.ParentId)))
            {
                return false;
            }
        }

        return true;
    }
  
}