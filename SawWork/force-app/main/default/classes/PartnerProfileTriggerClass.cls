public without sharing class PartnerProfileTriggerClass 
{
    public static Boolean hasSubmissionCriteriaBeenValidated = false;
    public static Boolean hasCreatedNonEnglishProfiles= false;
    public static Boolean hasPopulatedProductFamily = false;
    public static Boolean hasPopulatedIsoCode = false;
    public static Boolean hasValidatedPartnerAccount= false;
    public static Boolean hasMarkedChildrenReady = false;
    //SFDC-6778
    public static Boolean hasRunPerformFastTrackOperations = false;
    //End Of SFDC-6778
    
	// if approval status = approved; update approval status = inactive for other partner profile records with same master account.
	public static void deactivateOlderProfilesAndMarkChildrenReadyForTranslate(List<Partner_Profile__c> ppApprovedList, Set<Id> ppNewlyApprovedAccountSet)
    {
        List<Partner_Profile__c> ppToDeactivateList = new List<Partner_Profile__c>(); 
        DMLResults updateResults= new DMLResults();
        Id draftRecordTypeId= Schema.SObjectType.Partner_Profile__c.getRecordTypeInfosByName().get('Partner Information Draft or Resubmit').getRecordTypeId();

        for (Partner_Profile__c pp : [Select Id
                ,Parent_English_Profile__c 
                from Partner_Profile__c 
                where 
                Partner_Account_Name__c IN :ppNewlyApprovedAccountSet 
                AND Id NOT IN :ppApprovedList 
                AND ((Approval_Status__c='Approved' AND RecordType.name='Partner Information Approved') 
                    OR (RecordType.Name='Non-English Profile' AND Translation_Status__c='Draft'))])
        {
            if(pp.Parent_English_Profile__c==null)
            {
                // old english profiles
                pp.Approval_Status__c = 'Inactive';
                pp.RecordTypeId =draftRecordTypeId;
            }
            else
            {
                // new child non-english profiles
                pp.Translation_Status__c='Ready for Translate';
            }
            pp.Validation_Override__c=true;
            ppToDeactivateList.add(pp);
        }

        updateResults.dmlUpdate(ppToDeactivateList);
        updateResults.withClassName('PartnerProfileTriggerClass').insertRecordsInErrorLog();
    }	

    public static List<String> getSupportedLanguages()
    {
        Schema.DescribeFieldResult fieldResult =
            Partner_Profile__c.Language__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();


        List<String> supportedLanguages = new List<String>();
        for( Schema.PicklistEntry f : ple)
        {
            if(!f.getValue().containsIgnoreCase('english'))
                supportedLanguages.add(f.getValue());
        }
        return supportedLanguages;
    }


    public static void createOrResetNonEnglishProfiles(List<Partner_Profile__c> partnerPPs)
    {
        if(hasCreatedNonEnglishProfiles)
            return;

        Set<Id> ppIds = new Set<Id>();
        Map<Id, Datetime> ppIdToLastSubmittedDate = new Map<Id, DateTime>();
        Datetime earliestSubmitted=DateTime.now();

        for(Partner_Profile__c pp : partnerPPs)
        {
            ppIds.add(pp.Id);

            if(pp.Previous_Submission_DateTime__c!=null)
            {
                ppIdToLastSubmittedDate.put(pp.Id, pp.Previous_Submission_DateTime__c);

                if(earliestSubmitted>pp.Previous_Submission_DateTime__c)
                    earliestSubmitted=pp.Previous_Submission_DateTime__c;
            }
        }

        Set<String> fieldsToBeTranslated = NAPSettings.getValues('PartnerProfileFieldsToBeTranslated');
        Map<Id, List<String>> profileIdToFieldsChanged = new Map<Id, List<String>>();

        for(Partner_Profile__History pph: [select CreatedDate
            , Field
            , ParentId 
            from Partner_Profile__History 
            where ParentId in :ppIds 
            and CreatedDate>=:earliestSubmitted
            and field in :fieldsToBeTranslated])
        {
            if(ppIdToLastSubmittedDate.containsKey(pph.ParentId) 
                    && pph.CreatedDate >= ppIdToLastSubmittedDate.get(pph.ParentId))
            {
                if(!profileIdToFieldsChanged.containsKey(ppH.ParentId))
                {
                    profileIdToFieldsChanged.put(pph.ParentId, new List<String>());
                }

                profileIdToFieldsChanged.get(pph.ParentId).add(pph.Field);
            }
        }

        Set<String> existingChildProfiles = new Set<String>();
        for(Partner_Profile__c existingPP : [select id, Language__c,Parent_Id_with_Language__c from Partner_Profile__c where Parent_English_Profile__c in :ppIds])
        {
            existingChildProfiles.add(existingPP.Parent_Id_with_Language__c);
        }



        List<String> supportedLanguages = getSupportedLanguages();

        List<Partner_Profile__c> nonEnglishRecords = new List<Partner_Profile__c>();
        Id nonEnglishRTId= Schema.SObjectType.Partner_Profile__c.getRecordTypeInfosByName().get('Non-English Profile').getRecordTypeId();
        for(Partner_Profile__c pp : partnerPPs)
        {

            for(String lang: supportedLanguages)
            {
                if(!existingChildProfiles.contains(pp.Name+'#'+lang))
                {
                    // create
                    //clone(Boolean preserveId, Boolean isDeepClone, Boolean preserveReadonlyTimestamps, Boolean preserveAutonumber)
                    System.Debug(LoggingLevel.Error, 'AGH_D pp:'+pp.Partner_Account_Name__c);
                    
                    Partner_Profile__c nonEnglishPP= pp.clone(false,true,false,false);
                    nonEnglishPP.Parent_English_Profile__c = pp.Id;
                    nonEnglishPP.Translation_Status__c='Draft';
                    nonEnglishPP.RecordTypeId=nonEnglishRTId;
                    nonEnglishPP.Language__c = lang;
                    nonEnglishPP.AKAM_Partner_Profile_Id__c =null;
                    nonEnglishPP.Parent_Id_with_Language__c = pp.Name + '#'+ lang;
                    if(nonEnglishPP.Fast_Track__c) { //SFDC-6778
                        nonEnglishPP.Fast_Track__c = false;
                    }
                    System.Debug(LoggingLevel.Error, 'AGH_D nonenglish:'+nonEnglishPP);
                    nonEnglishRecords.add(nonEnglishPP);
                }
                else
                {
                    //update
                    List<String> changedFields = profileIdToFieldsChanged.get(pp.Id);
                    if(changedFields!=null && changedFields.size()>0)
                    {
                        Partner_Profile__c nonEnglishPP= new Partner_Profile__c();
                        nonEnglishPP.Translation_Status__c='Draft';
                        nonEnglishPP.Parent_Id_with_Language__c = pp.Name + '#'+ lang;
                        for(String changedField: changedFields)
                        {
                            nonEnglishPP.put(changedField, pp.get(changedField));
                        }
                        nonEnglishRecords.add(nonEnglishPP);
                    }
                }
            }
        }

        // TODO - dml results?
        if(nonEnglishRecords.size()>0)
            upsert nonEnglishRecords Parent_Id_with_Language__c;

        hasCreatedNonEnglishProfiles=true;
    }

    public static void validatePartnerAccount(List<Partner_Profile__c> partnerPPs)
    {
        if(hasValidatedPartnerAccount)
            return;

        Set<Id> allowedAccountIds= new set<Id>();
        List<Account> accountsInHierarchy = GsmUtilClass.getAccCompleteHierarchy(CurrentUser.attributes.get('Partner Account'),'Down');

        for(Account acc : accountsInHierarchy)
        {
            allowedAccountIds.add(acc.Id);
        }

        for(Partner_Profile__c pp : partnerPPs)
        {
            if(!allowedAccountIds.contains(pp.Partner_Account_Name__c ))
            {
                pp.addError('You can only create Partner Profiles for your account and your child accounts.');
            }
        }


        hasValidatedPartnerAccount=true;
    }

    public static void populateProductFamily(List<Partner_Profile__c> pps)
    {
        if(hasPopulatedProductFamily)
            return;

        Map<String, String> productToFamily = new Map<String, String>();
        for(NAP_Settings__mdt row : [select DeveloperName, Label, Value__c from NAP_Settings__mdt where Developername like 'PPProductFamily_%'])
        {
            String familyName = row.DeveloperName.substringAfter('PPProductFamily_').replaceAll('_', ' ');
            List<String> prods = row.Value__c.split(',');
            for(String prod: prods)
            {
                productToFamily.put(prod, familyName);
            }
        }

        for(Partner_Profile__c pp: pps)
        {
            if(String.isBlank(pp.Partner_Accreditation__c))
            {
                pp.Akamai_Solutions__c='';
            }
            else
            {
                List<String> accreditedProducts = pp.Partner_Accreditation__c.split(';');
                Set<String> families = new Set<String>();
                for(String prod : accreditedProducts)
                {
                    if(productToFamily.containsKey(prod))
                        families.add(productToFamily.get(prod));
                }
                List<String> familyList = new List<String>();
                familyList.addAll(families);
                pp.Akamai_Solutions__c = String.join(familyList, ';');
            }
        }


        hasPopulatedProductFamily = true;

    }

    public static void populateCountryISOCode(List<Partner_Profile__c> pps)
    {
        if(hasPopulatedIsoCode)
            return;

        List<String> cntries = new List<String>();

        for(Partner_Profile__c pp : pps)
        {
            if(pp.Partner_Address_Country1__c!=null)
                cntries.add(pp.Partner_Address_Country1__c);
        }

        Map<String, String> cntryToISo = new Map<String, String>();

        if(cntries.size()>0)
        {
            for(CoutryISOList__mdt cntry : [select Country_ISO2__c, MasterLabel from CoutryISOList__mdt where MasterLabel in :cntries])
            {
                cntryToISo.put(cntry.MasterLabel.toLowerCase(), cntry.Country_ISO2__c);
            }
        }

        for(Partner_Profile__c pp : pps)
        {
            if(!String.isBlank(pp.Partner_Address_Country1__c) && cntryToISo.containsKey(pp.Partner_Address_Country1__c.toLowerCase()))
                pp.Partner_Country_ISO_Code__c =  cntryToISo.get(pp.Partner_Address_Country1__c.toLowerCase());
            else
                pp.Partner_Country_ISO_Code__c = '';
        }

        hasPopulatedIsoCode = true;
    }

    //SFDC-9146
    /*public static void validateSubmissionCriteria(List<Partner_Profile__c> submittedPPs)
    {

        if(hasSubmissionCriteriaBeenValidated)
            return;

        //Set<Id> partnerAccountIds = new Set<Id>();
        Set<Id> ppIds = new Set<Id>();
        for(Partner_Profile__c pp: submittedPPs)
        {
            //partnerAccountIds.add(pp.Partner_Account_Name__c);
            ppIds.add(pp.Id);
        }

        /* SFDC-7072 Map<Id, Id> partnerAccountIdToApproverId= new Map<Id, Id>(); // https://akamai--l2qmay.my.salesforce.com/00XG0000001OIRc?setupid=CommunicationTemplatesEmail

        for(Channel_Mapping__c cm: [SELECT Id,
                                            MDF_Approver__c,
                                            Partner_Name__c 
                                            from Channel_Mapping__c 
                                            WHERE MDF_Approver__c!= null 
                                            AND VAR_Manager_Status__c = 'Active' 
                                            AND Master_Channel_Mapping__c=true
                                            AND Active__c=true 
                                            AND Temp_PAE__c=null 
                                            AND MDF_Approver__r.IsActive=true
                                            AND Partner_Name__c in :partnerAccountIds])
        {
            partnerAccountIdToApproverId.put(cm.Partner_Name__c, cm.MDF_Approver__c);
        }


        for(Partner_Profile__c pp: submittedPPs)
        {
            if(partnerAccountIdToApproverId.containsKey(pp.Partner_Account_Name__c))
            {
                pp.Partner_FR_Approver__c =partnerAccountIdToApproverId.get(pp.Partner_Account_Name__c);
            }
            else
            {
                pp.addError(NAPSettings.getValue('PartnerProfileNoCMsErrorMessage')); //TODO Should we get rid of metadata?
            }
        } /


        Set<Id> ppsWithLogos = new Set<Id>();
        for(Attachment aa :[select BodyLength,ContentType, Id,ParentId from Attachment where ParentId in :ppIds and ContentType like 'image%'])
        {
            ppsWithLogos.add(aa.ParentId);
        }


        for(ContentDocumentLink cdl: [SELECT LinkedEntityId from ContentDocumentLink where LinkedEntityId in :ppIds and ContentDocument.LatestPublishedVersion.FileExtension in ('svg','png','jpeg','jpg')])
        {
            ppsWithLogos.add(cdl.LinkedEntityId);
        }


        for(Partner_Profile__c pp: submittedPPs)
        {
            if(!ppsWithLogos.contains(pp.Id))
            {
                pp.addError(NAPSettings.getValue('PartnerProfileNoLogoErrorMessage'));
            }
        }

        hasSubmissionCriteriaBeenValidated = true;

    }*/

    //SFDC-6778
    public static void cascadeApprovalStatusToNonEnglishProfiles(List<Partner_Profile__c> ppsWithChangedApprovalStatusToCascade) {
        List<Partner_Profile__c> listOfNonEnglishProfiles = [SELECT Id, Approval_Status__c, Parent_English_Profile__c, Translation_Status__c FROM Partner_Profile__c WHERE Parent_English_Profile__c IN :ppsWithChangedApprovalStatusToCascade];
        Map<Id, List<Partner_Profile__c>> mapOfParentProfileIdVsNonEnglishProfiles = new Map<Id, List<Partner_Profile__c>>();
        for(Partner_Profile__c eachProfile : listOfNonEnglishProfiles) {
            List<Partner_Profile__c> nonEnglishProfiles = new List<Partner_Profile__c>();
            if(mapOfParentProfileIdVsNonEnglishProfiles.containsKey(eachProfile.Parent_English_Profile__c)) {
                nonEnglishProfiles = mapOfParentProfileIdVsNonEnglishProfiles.get(eachProfile.Parent_English_Profile__c);
            }
            nonEnglishProfiles.add(eachProfile);
            mapOfParentProfileIdVsNonEnglishProfiles.put(eachProfile.Parent_English_Profile__c, nonEnglishProfiles);
        }

        Set<Partner_Profile__c> listOfProfilesToUpdate = new Set<Partner_Profile__c>();
        for(Partner_Profile__c eachMasterProfile : ppsWithChangedApprovalStatusToCascade) {
            if(mapOfParentProfileIdVsNonEnglishProfiles.containsKey(eachMasterProfile.Id)) {
                List<Partner_Profile__c> nonEnglishProfiles = mapOfParentProfileIdVsNonEnglishProfiles.get(eachMasterProfile.Id);
                for(Partner_Profile__c eachNonEnglishProfile : nonEnglishProfiles) {
                    eachNonEnglishProfile.Approval_Status__c = eachMasterProfile.Approval_Status__c;
                    if('Re-Opened'.equals(eachMasterProfile.Approval_Status__c)) {
                        eachNonEnglishProfile.Translation_Status__c = 'Draft';
                    }
                    else if('Approved'.equals(eachMasterProfile.Approval_Status__c)) {
                        eachNonEnglishProfile.Translation_Status__c = 'Ready for Translate';
                    }
                    listOfProfilesToUpdate.add(eachNonEnglishProfile);
                }
            }
        }
        if(listOfProfilesToUpdate.size() > 0) {
            //System.DEBUG(listOfProfilesToUpdate.get(0).Fast_Track__c);
            update new List<Partner_Profile__c>(listOfProfilesToUpdate);
            //remove try catch, and let the errors bubble up to user, TODO - Peer Review
        }

    }

    //SFDC-6778
    public static void performFastTrackOperations(List<Partner_Profile__c> ppsForFastTrack) {
        if(hasRunPerformFastTrackOperations) {
            return;
        }
        hasRunPerformFastTrackOperations = true;

        List<Partner_Profile__c> listOfProfilesToUpdate = new List<Partner_Profile__c>();
        for(Partner_Profile__c eachNonEnglishProfile : [SELECT Id, Approval_Status__c, Parent_English_Profile__c FROM Partner_Profile__c WHERE Parent_English_Profile__c IN :ppsForFastTrack]) {
            eachNonEnglishProfile.Translation_Status__c = 'Translation Completed';
            listOfProfilesToUpdate.add(eachNonEnglishProfile);
        }

        if(listOfProfilesToUpdate.size() > 0) {
            update listOfProfilesToUpdate;
            //remove try catch, and let the errors bubble up to user, TODO - Peer Review
        }

    }    

}