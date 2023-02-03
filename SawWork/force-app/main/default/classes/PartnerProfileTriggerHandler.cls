public class PartnerProfileTriggerHandler extends ApexTriggerHandlerAbstractClass
{
    public PartnerProfileTriggerHandler(){}

    public override void beforeInsertBeforeUpdateTrigger()
    {
        List<Partner_Profile__c> ppUpdateFRApproverList = new List<Partner_Profile__c>();
        List<Partner_Profile__c> ppCheckLogoList = new List<Partner_Profile__c>();
        List<Partner_Profile__c> submittedPPs = new List<Partner_Profile__c>();
        List<Partner_Profile__c> ppsWithChangedCountries = new List<Partner_Profile__c>();
        List<Partner_Profile__c> ppsWithChangedAccreditation = new List<Partner_Profile__c>();
        
        //Id CrmIntegration = Id.valueOf(GsmUtilClass.getGSMSettingValue('CRM_Integration'));
        Id MulesoftIntegrationProfileId = Id.valueOf(GsmUtilClass.getGSMSettingValue('ProfileIdMulesoftIntegration'));
        Id approvedRecordTypeId = Schema.SObjectType.Partner_Profile__c.getRecordTypeInfosByName().get('Partner Information Approved').getRecordTypeId();
        List<Partner_Profile__c> partnerPPs = new List<Partner_Profile__c>();

        // restrict partners from working on other partner accounts
        for(SObject so: newList)
        {
            Partner_Profile__c pp = (Partner_Profile__c)so;

            if(UserInfo.getUserType().containsIgnoreCase('PowerPartner'))
            {
                partnerPPs.add(pp);
            }
            if(String.isEmpty(pp.Language__c))
                pp.Language__c='English';


        }

        if(partnerPPs.size()>0)
            PartnerProfileTriggerClass.validatePartnerAccount(partnerPPs);

        for(SObject so: newList)
        {
            Partner_Profile__c pp = (Partner_Profile__c)so;
            Partner_Profile__c oldPp;
            if(Trigger.isInsert) {
                pp.PartnerProfileUniqueIdentifier__c = pp.Partner_Account_Name__c + pp.Language__c;
            }
            if(Trigger.isUpdate)
                oldPp  = (Partner_Profile__c)oldMap.get(pp.Id);

            if(Trigger.isUpdate && oldPp.Submission_DateTime__c!=pp.Submission_DateTime__c)
                pp.Previous_Submission_DateTime__c=oldPp.Submission_DateTime__c;



            /*
            if((pp.Partner_About__c!=null && NAPUtilClass.containsUnsanitaryInputForWWW(pp.Partner_About__c)) || (pp.Partner_Solutions_RTF__c!=null && NAPUtilClass.containsUnsanitaryInputForWWW(pp.Partner_Solutions_RTF__c)))
            {
                pp.addError('Please do not use images or alignment features in Partner About or Partner Solutions fields');
            }
            */


            if((!String.isBlank(pp.Language__c) && 'english'.containsIgnoreCase(pp.Language__c)) && 'Pending'.contains(pp.Approval_Status__c) && ((Trigger.isUpdate && pp.Approval_Status__c!=oldpp.Approval_Status__c) || Trigger.isInsert))
                submittedPPs.add(pp);

            if((!String.isBlank(pp.Language__c) && 'english'.containsIgnoreCase(pp.Language__c)) && (Trigger.isInsert && pp.Partner_Accreditation__c!=null) || (Trigger.isUpdate && pp.Partner_Accreditation__c!=oldpp.Partner_Accreditation__c))
                ppsWithChangedAccreditation.add(pp);

            if((!String.isBlank(pp.Language__c) && 'english'.containsIgnoreCase(pp.Language__c)) && (Trigger.isInsert && pp.Partner_Address_Country1__c!=null) || (Trigger.isUpdate && pp.Partner_Address_Country1__c!=oldpp.Partner_Address_Country1__c))
                ppsWithChangedCountries.add(pp);
            //  Code By Rahul : AKAM field updation Through The code

            if(Trigger.isInsert && Trigger.isBefore)
            {
                if((UserInfo.getProfileId() == MulesoftIntegrationProfileId && (pp.AKAM_Created_By__c =='' || 
                                pp.AKAM_Created_Date__c == null ||pp.AKAM_System__c =='')) || UserInfo.getProfileId() != MulesoftIntegrationProfileId ) 
                {
                    pp.AKAM_Created_By__c = pp.AKAM_Alias__c ;
                    pp.AKAM_Created_Date__c = system.now();
                    pp.AKAM_System__c ='FORCE';
                }
            }
            // This code bassically checks if any value of Akam modified is null for Insert or Updates it populates the default value
            if((UserInfo.getProfileId() == MulesoftIntegrationProfileId && (pp.AKAM_Modified_Date__c  == null|| 
                            pp.AKAM_Modified_By__c == '' || pp.AKAM_Modified_By__c == null)) || UserInfo.getProfileId() != MulesoftIntegrationProfileId )  
            {
                pp.AKAM_Modified_By__c = pp.AKAM_Alias__c;
                pp.AKAM_Modified_Date__c =  system.now();  
            }

            if(Trigger.isUpdate && pp.Approval_Status__c!=oldPp.Approval_Status__c)
            {
                if('Approved'.equals(pp.Approval_Status__c))
                {
                    pp.RecordTypeId = approvedRecordTypeId;
                    pp.Approved_Date_Time__c = DateTime.now();
                }
            }
        }


        //SFDC-9146
        /*if(submittedPPs.size()>0)
            PartnerProfileTriggerClass.validateSubmissionCriteria(submittedPPs);*/

        if(ppsWithChangedAccreditation.size()>0)
            PartnerProfileTriggerClass.populateProductFamily(ppsWithChangedAccreditation);

        if(ppsWithChangedCountries.size()>0)
            PartnerProfileTriggerClass.populateCountryISOCode(ppsWithChangedCountries);

    }

    public override void afterInsertAfterUpdateTrigger()
    {
        List<Partner_Profile__c> ppApprovedList = new List<Partner_Profile__c>();
        Set<Id> ppNewlyApprovedAccountSet = new Set<Id>();
        List<Partner_Profile__c> submittedPPs = new List<Partner_Profile__c>();
        //SFDC-6778
        List<Partner_Profile__c> ppsWithChangedApprovalStatusToCascade = new List<Partner_Profile__c>();
        List<Partner_Profile__c> ppsForFastTrack = new List<Partner_Profile__c>();
        //End Of SFDC-6778
        for(SObject so: newList)
        {
            Partner_Profile__c pp = (Partner_Profile__c)so;
            Partner_Profile__c oldPp;

            if(Trigger.isUpdate)
                oldPp  = (Partner_Profile__c)oldMap.get(pp.Id);

            if(pp.Language__c=='English')
            {
                if('Pending'.contains(pp.Approval_Status__c) && ((Trigger.isUpdate && pp.Approval_Status__c!=oldpp.Approval_Status__c) || Trigger.isInsert))
                    submittedPPs.add(pp);

                // Check if Approval Status is changed
                if (('Approved'.equals(pp.Approval_Status__c)
                            && (Trigger.isInsert || (!Trigger.isInsert && pp.Approval_Status__c != oldPp.Approval_Status__c))))
                {
                    ppApprovedList.add(pp);
                    ppNewlyApprovedAccountSet.add(pp.Partner_Account_Name__c);
                }
            }
            
            //SFDC-6778            
            if(Trigger.isUpdate && pp.Approval_Status__c != oldPp.Approval_Status__c) {
                ppsWithChangedApprovalStatusToCascade.add(pp);
            }
            if(pp.Master_English_Profile__c && pp.Fast_Track__c && 'Approved'.equals(pp.Approval_Status__c) && (Trigger.isInsert || 
            (Trigger.isUpdate && pp.Approval_Status__c != oldPp.Approval_Status__c))) {
                ppsForFastTrack.add(pp);
            }
            //End Of SFDC-6778
        }

        if(submittedPPs.size()>0)
            PartnerProfileTriggerClass.createOrResetNonEnglishProfiles(submittedPPs);

        //update ready to translate

        // if Approval Status is changed do this
        if (ppApprovedList.size()>0)
            PartnerProfileTriggerClass.deactivateOlderProfilesAndMarkChildrenReadyForTranslate(ppApprovedList, ppNewlyApprovedAccountSet);

        //SFDC-6778 
        if(ppsWithChangedApprovalStatusToCascade.size() > 0) {
            PartnerProfileTriggerClass.cascadeApprovalStatusToNonEnglishProfiles(ppsWithChangedApprovalStatusToCascade);
        }
        if(ppsForFastTrack.size() > 0) {
            PartnerProfileTriggerClass.performFastTrackOperations(ppsForFastTrack);
        }
        //End Of SFDC-6778  

    }

    public override void beforeDeleteBeforeUndeleteTrigger()
    {
        System.debug('This is before delete and before undelete.');
    }

    public override void afterDeleteAfterUndeleteTrigger()
    {
        System.debug('This is after delete and after undelete.');
    }

}