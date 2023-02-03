/*
 * Created By Mayank Bansal on 19th Sept,19 as part of MARIT-67
 */
public with sharing class MARIT_ContactTriggerHandler extends ApexTriggerHandlerAbstractClass {
    
    public override void beforeInsertBeforeUpdateTrigger() {
        List<Contact> contactsTriggerNew = (List<Contact>)newList;
        List<Contact> contactsTriggerOld = (List<Contact>)oldList;
        Map<Id,Contact> contactsTriggerNewMap = (Map<Id,Contact>)newMap;
        Map<Id,Contact> contactsTriggerOldMap = (Map<Id,Contact>)oldMap;
        Map<String,Id> recordTypeNameIdMap = new Map<String,Id>();
        List<Contact> personContactForProjectedOwnerUpdate = new List<contact>();//MARIT-215
        //MARIT-946 acd
        List<Contact> removePhoneValuesFromContact = new List<contact>();
        List<Contact> syncNewFromOldPhoneFields = new List<Contact>();
        List<Contact> syncOldFromNewPhoneFields = new List<Contact>();
        //MARIT-1681 e164
        List<Contact> updatePhoneValuesToE164 = new List<Contact>();
        String phoneEditValidationProfiles = MarketingUtilClass.getMarketingSettingsValue('PhoneEditValidationProfiles');
        //MARIT-16 : Annuitas: Highest Lead Qualification Stage
        Set<String> stageFieldsQL = GSMSettings.getSetOfStrings('BPPStageFieldsForLead');
        List<String> strList = MarketingUtilClass.getMarketingSettingValuePartialMatch('HighestToLowestLeadQualificationStage');
        Set<String> bppFields = new Set<String>(MarketingUtilClass.getMarketingSettingsValue('BPP_Field_List').replaceAll(' ', '').split(','));
        //MARIT-1071
        Map<String,List<SObject>> acquistionProgramToContactMap = new Map<String,List<SObject>>();  
        Set<String> acquistionProgramNames = new Set<String>();
        Set<String> acquistionProgramAkamIds = new Set<String>();
        Set<Id> DriftProfileId = new Set<Id>();
        List<Id> DriftProfileIds = MarketingUtilClass.getMarketingSettingsValue('DriftProfileId').split(',');
        DriftProfileId.addAll(DriftProfileIds);
        String marketoIntegrationProfileId = GSMSettings.getValue('MarketoIntegrationProfileId');
        
        String high_to_low = null;
        for(String str: strList){
            if(high_to_low == null){
                high_to_low = str;
            } else{
                high_to_low += ',' + str;
            }
        }
        List<String> highest_lowest_QL_Stage = high_to_low.split(',');
        Map<String,Schema.RecordTypeInfo> recordTypeInfo = Schema.getGlobalDescribe().get('Contact').getDescribe().getRecordTypeInfosByName();
        for(String recordName: recordTypeInfo.keySet())
        {
            Schema.RecordTypeInfo recInfo = recordTypeInfo.get(recordName);
            if(recInfo.isAvailable())
                recordTypeNameIdMap.put(recordName,recInfo.getRecordTypeId());
        }
        for(SObject so: newList)
        {
            Contact con = (Contact)so;
            Contact oldCon;

            if(Trigger.isUpdate)
                oldCon = (Contact)oldMap.get(con.Id);
            
            if(Trigger.isInsert  || (Trigger.isUpdate && con.City_Local__c == 'TBD' && con.mailingCity != 'TBD' && Util.hasChanges('mailingCity',oldCon, con) )){
                //MARIT_ContactTriggerClass.copyAddrFieldsToLocalFields(con);
            }
            if(Trigger.IsInsert || (Trigger.IsUpdate && Util.hasChanges(bppFields,oldCon,con))){
                con.Buyer_Pain_Points__c = MARIT_LeadTriggerClass.getEnabledBPPs(bppFields, con);//MARIT-873
            }
            //MARIT-16
            //Annuitas: Highest Lead Qualification Stage
            Contact oldContact;
            if(Trigger.isUpdate)
                oldContact = contactsTriggerOldMap.get(con.Id);
            if(( Trigger.isInsert || (Trigger.isUpdate && Util.hasChanges(stageFieldsQL,oldContact,con))))
            {
                con.Highest_Lead_Qualification_Stage__c= LeadUtilClass.updateHighestLeadQualificationStage(stageFieldsQL,con,highest_lowest_QL_Stage);
                System.debug(con.Highest_Lead_Qualification_Stage__c);
            }
            
            if((Trigger.isInsert || (Trigger.isUpdate && (DriftProfileId.contains(userinfo.getProfileId()) || Test.isRunningTest()) && !Util.hasChanges('Lead_Qualification_Stage__c',oldContact,con) && con.Lead_Qualification_Stage__c != 'Qualified Lead - Hot' && con.Lead_Qualification_Stage__c != 'Qualified Lead - Warm')) && con.CQL_Score__c == 3){
                con.Lead_Qualification_Stage__c = 'Qualified Lead - Hot';
                con.Lead_Qualification_Status__c = 'New';
            }   

            if(marketoIntegrationProfileId.contains(UserInfo.getProfileId()) && con.CQL_Score__c ==3 && Util.hasChanges('Lead_Qualification_Stage__c',oldContact,con) && con.Lead_Qualification_Stage__c != 'Qualified Lead - Hot'){
                        con.CQL_Score__c = null;
                }

            
            //MARIT-946 acd
            //sync new phone fields with oob phone fields on insert and update of lead and when do not call flag value is true -> false
            if(!Test.isRunningTest() && (con.Phone != null || con.MobilePhone != null || con.Assistant_Phone__c != null )&& (Util.hasChanges('Phone',oldCon,con) || Util.hasChanges('MobilePhone',oldCon,con) || Util.hasChanges('Assistant_Phone__c',oldCon,con) || Util.hasChanges('DoNotCall',oldCon,con)) && !con.DoNotCall){
                syncNewFromOldPhoneFields.add(con);
            }
            //MARIT-1681 : update E.164 phone fields on insert and update of lead and when do not call flag value is true -> false
            if((Util.hasChanges('Phone_Custom__c',oldCon,con) || Util.hasChanges('MobilePhone_Custom__c',oldCon,con) || Util.hasChanges('Phone',oldCon,con) || Util.hasChanges('MobilePhone',oldCon,con) || Util.hasChanges('DoNotCall',oldCon,con) || Util.hasChanges('MailingCountry',oldCon,con)) && !con.DoNotCall) {
                updatePhoneValuesToE164.add(con);
            }
            //sync old fields with new phone fields on insert and update of lead and when do not call flag value is false
            if(((Util.hasChanges('Phone_Custom__c',oldCon,con) && con.Phone_Custom__c!= null) || (Util.hasChanges('MobilePhone_Custom__c',oldCon,con) && con.MobilePhone_Custom__c!= null)
                || (Util.hasChanges('Assistant_Phone_Custom__c',oldCon,con) && con.Assistant_Phone_Custom__c!= null)) && !con.DoNotCall){
                    syncOldFromNewPhoneFields.add(con);
                }
            //When the Do not call flag is set to true below if piece is triggered to blank out custom phone field values
            if(con != null && con.DoNotCall && (con.Phone_Custom__c != null || con.MobilePhone_Custom__c != null || con.Assistant_Phone_Custom__c != null || con.E164_Phone__c != null || con.E164_MobilePhone__c != null)){
                removePhoneValuesFromContact.add(con);
            }
            //Validation rule which triggers when the do not call flag is checked and sdr* profiles tries to update the phone field
            if(((con.Phone_Custom__c != null && Util.hasChanges('Phone_Custom__c',oldCon,con)) || (con.MobilePhone_Custom__c != null && Util.hasChanges('MobilePhone_Custom__c',oldCon,con)) || (con.Assistant_Phone_Custom__c != null && Util.hasChanges('Assistant_Phone_Custom__c',oldCon,con))) && con.DoNotCall){
                String error = MarketingUtilClass.phoneEditValidationErrorWhenDNCIsChecked();
                if(error != null){
                  con.addError(error);  
                }
            }

            //MARIT-215
            if(Trigger.isInsert && con.AccountId != null)
            {
                personContactForProjectedOwnerUpdate.add(con);
            }
            
            //MARIT-215
            if(Trigger.isUpdate && con.AccountId != null && Util.hasChanges('AccountId' ,oldContact, con))
            {
                personContactForProjectedOwnerUpdate.add(con);
            }

            if(Trigger.isInsert && con.mkto71_Acquisition_Program__c != null && con.mkto71_Acquisition_Program_Id__c != null){
                String acquisitionCampaign = con.mkto71_Acquisition_Program__c + String.valueOf(con.mkto71_Acquisition_Program_Id__c);
                List<SObject> acquisitionContacts;
                if(acquistionProgramToContactMap.get(acquisitionCampaign) == null){
                    acquisitionContacts = new List<SObject>();
                }
                else{
                    acquisitionContacts = acquistionProgramToContactMap.get(acquisitionCampaign);
                }
                acquisitionContacts.add((SObject)con);
                acquistionProgramToContactMap.put(acquisitionCampaign,acquisitionContacts); //MARIT-1071
                acquistionProgramNames.add(con.mkto71_Acquisition_Program__c);
                acquistionProgramAkamIds.add('%'+String.valueOf(con.mkto71_Acquisition_Program_Id__c)+'%');
            }
        }
        if(personContactForProjectedOwnerUpdate.size()>0){
            personContactForProjectedOwnerUpdate = MARIT_ContactTriggerClass.ProjectSDRForPersonContact(personContactForProjectedOwnerUpdate);
            System.debug('No of person contacts with PSO updated/populated:'+personContactForProjectedOwnerUpdate.size());
        }
        //MARIT-946 acd
        if(removePhoneValuesFromContact != null && !removePhoneValuesFromContact.isEmpty()){
            MARIT_LeadTriggerClass.removePhoneValueWhenDNCFlagIsCheckedLead(new List<Lead>(),removePhoneValuesFromContact);
        }
        if(syncNewFromOldPhoneFields != null && !syncNewFromOldPhoneFields.isEmpty()){
            MarketingUtilClass.syncNewPhoneFieldsWithOld(new List<Lead>(),syncNewFromOldPhoneFields);
        }
        if(syncOldFromNewPhoneFields != null && !syncOldFromNewPhoneFields.isEmpty()){
            MarketingUtilClass.syncOldPhoneFieldsWithNew(new List<Lead>(),syncOldFromNewPhoneFields);
        }
        //MARIT-1681 e164
        if(updatePhoneValuesToE164 != null && !updatePhoneValuesToE164.isEmpty()){
            MARIT_LeadContactUtils.e164PhoneNumberformatting(updatePhoneValuesToE164,'MailingCountry');
        }
        if(!acquistionProgramToContactMap.isEmpty()){
            MARIT_LeadContactUtils.personAcquistionCampaign(acquistionProgramToContactMap,acquistionProgramNames,acquistionProgramAkamIds);
        }
    
    }
    public override void beforeDeleteBeforeUndeleteTrigger() {
        List<Contact> contactsTriggerOld = (List<Contact>)oldList;
            
        if(Trigger.isDelete) {
            String contactDeletionRestrictionProfiles = MarketingUtilClass.getMarketingSettingsValue('ContactDeletionRestrictionProfiles');
            if(contactDeletionRestrictionProfiles != null && contactDeletionRestrictionProfiles.contains(userInfo.getProfileId())) {
                for(Contact con: contactsTriggerOld) {
                    con.AddError('Insufficient Access to delete Contact');
                }  
            }

            //MARIT-1751 : Can't delete a person record which has an open CTA
            Set<String> ids = new Set<String>();
            Set<String> parentIdswithOpenCTA = new Set<String>();
            for(Contact con: contactsTriggerOld) {
                ids.add(con.Id);
            }
            List<lead> openC2ALeads = [Select id,Associated_Contact__c  from Lead where Associated_Contact__c  in :ids and status in ('New', 'In Process')];
            for(lead l: openC2ALeads) {
                parentIdswithOpenCTA.add(l.Associated_Contact__c );
            }
            for(Contact con: contactsTriggerOld) {
                if(parentIdswithOpenCTA.contains(con.Id)) {
                    con.addError('Please action the open CTA before performing a delete/merge operation on the Person Contact');
                }
            }
        }
    }
    public override void afterInsertAfterUpdateTrigger() {
        List<Contact> contactsTriggerNew = (List<Contact>)newList;
        List<Contact> contactsTriggerOld = (List<Contact>)oldList;
        Map<Id,Contact> contactsTriggerNewMap = (Map<Id,Contact>)newMap;
        Map<Id,Contact> contactsTriggerOldMap = (Map<Id,Contact>)oldMap;
        Contact oldContact;
        List<Contact> contactList = new List<Contact>();
        Map<Id,Contact> personConList = new Map<Id,Contact>();
        //SFDC-4547-3
        List<Lead> createAkamaiLeadList = new List<Lead>();
        Set<String> stageAndStatusFields = GSMSettings.getSetOfStrings('BPPStatusFieldsForLead');
        stageAndStatusFields.addAll(GSMSettings.getSetOfStrings('BPPStageFieldsForLead'));
        //MARIT-214
        Set<Id> updatedPersonContacts = new Set<ID>();
        Map<Id,contact> oldPersonContactMap = new Map<Id,contact>();
        Map<Id,contact> newPersonContactMap = new Map<Id,contact>();
        List<String> personContactC2ASyncFields = MarketingUtilClass.getMarketingSettingValuePartialMatch('personContactC2ASyncFields');
        personContactC2ASyncFields = String.join(personContactC2ASyncFields,',').split('\\s*,\\s*');
        Set<String> personContactC2ASyncFieldsSet = new Set<String>(personContactC2ASyncFields);

        //MARIT-487
        Map<String,Lead> leadMap = new Map<String,Lead>();
        List<Lead> toUpdate = new List<Lead>();
        List<Id> contactIdsSetToConverted = new List<Id>(); //MARIT-681

        for(Contact con : contactsTriggerNew) {
        //SFDC-4547 HC: Sync Stage/Status from Contact to C2A Lead
            if(Trigger.isUpdate)
                oldContact = contactsTriggerOldMap.get(con.Id);
            //MARIT-359 Optimizing the code
            if(Trigger.isUpdate && LeadUtilClass.hasPassedBPPStageThreshold(con, oldContact)){
                contactList.add(con);
            } else if(Trigger.isUpdate  &&  Util.hasChanges(stageAndStatusFields,oldContact,con)){
                if(LeadUtilClass.isBPPStatusConverted(con, oldContact)){
                    contactIdsSetToConverted.add(con.Id); //check for open oppt only when status is set to converted
                }
                personConList.put(con.Id,con);
            }
            
            //MARIT-214
            if(Trigger.isUpdate && Trigger.isAfter)
            {
                if(Util.hasChanges(personContactC2ASyncFieldsSet,(Contact)oldMap.get(con.Id),(Contact)newMap.get(con.Id))){
                    updatedPersonContacts.add(con.Id);
                    oldPersonContactMap.put(con.Id,(Contact)oldMap.get(con.Id));
                    newPersonContactMap.put(con.Id,(Contact)newMap.get(con.Id));
                    System.debug('Person contact is updated. Id = ' +con.Id);
                }

            }   
        }
        
           
        //MARIT-214
        if(updatedPersonContacts.size() > 0){
            System.debug('Updating C2A Lead');
            MARIT_ContactTriggerClass.updateC2ALeadFromPersonContact(updatedPersonContacts,oldPersonContactMap,newPersonContactMap);
            updatedPersonContacts.clear();
            oldPersonContactMap.clear();
            newPersonContactMap.clear();
        }

        //SFDC-4547
        if(contactList.size() > 0)
            LeadToContactConversionClass.updateOpptysAndLeads(contactList);

        if(!contactIdsSetToConverted.isEmpty()){
            //get contacts having open oppt
            Set<Id> openOpptContactIds = MARIT_ContactUtilClass.checkContactOpenOppt(contactIdsSetToConverted, 'Opportunity_Stages'); //MARIT-1513
            /*remove those contacts from updating any open C2A, since C2A will be closed and we don't want that C2A to go for
            conversion when marketo sets to converted in person contact*/
            for(Id contactId : openOpptContactIds){
                personConList.remove(contactId);
            }
            System.debug('Open Oppt Contact Ids='+openOpptContactIds);
            //close open cta
            leadMap = LeadToContactConversionClass.closeCTAWithOpenOppt(openOpptContactIds,leadMap);
        }

        //SFDC-4547 HC: Sync Stage/Status from Contact to C2A Lead
        if(personConList.size() > 0){
            //LeadToContactConversionClass.updateC2ALeadFromPersonContactOrLead(personConList,new List<Lead>());
            
            // MARIT-487 
            // Add the Leads to the update list and update at the end.
            //LeadToContactConversionClass.updateC2ALeadFromPersonContactOrLead(personConList,new List<Lead>());
            leadMap = LeadToContactConversionClass.updateC2ALeadFromPersonContactOrLead(personConList.values(),new List<Lead>(),leadMap);
        }

        //MARIT-487 Final Update statement for all leads
        toUpdate = leadMap.values();
        if (toUpdate.size() > 0)
        {
            LeadToContactConversionClass.upsertLeads(toUpdate);
        }
    }
    
    public override void afterDeleteAfterUndeleteTrigger(){
    }

}