/*
 * Created By Mayank Bansal on 22nd Aug,19 as part of MARIT-5
 */
public without sharing class MARIT_LeadTriggerClass {

    public static Boolean checkDuplicatesFirstRunFlag = true;
    public static Boolean setAssociatedAccountOnLead = true;
    public static Boolean setSLAsFRFlag = true;
	
    //MARIT-1744: Adding a null check before copying values to local field
    public static void copyAddrFieldsToLocalFields(Lead l){
        if(String.isBlank(l.City_Local__c)) {
            l.City_Local__c = l.City;
        }    
        if(String.isBlank(l.Company_Self_entered_Local__c)) {
            l.Company_Self_entered_Local__c = l.Company_Self_Entered__c;
        }   
        if(String.isBlank(l.Country_Local__c)) {
            l.Country_Local__c = l.Country;
        }
        if(String.isBlank(l.First_Name_Local__c)) {
            l.First_Name_Local__c = l.FirstName;
        }    
        if(String.isBlank(l.Last_Name_Local__c)) {
            l.Last_Name_Local__c = l.LastName;
        }    
        if(String.isBlank(l.State_Province_Local__c)) {
            l.State_Province_Local__c = l.State;
        }
        if(String.isBlank(l.Title_Local__c)) {        
            l.Title_Local__c = l.Title;
        }
        if(String.isBlank(l.Street_Local__c)) { 
            l.Street_Local__c = l.Street;
        }
        if(String.isBlank(l.Zip_Postal_Code_Local__c)) { 
            l.Zip_Postal_Code_Local__c = l.PostalCode;
        }
    }
    
    //MARIT-873
    public static String getEnabledBPPs(Set<String> bppFieldSet, Sobject sobj){
        String bppStr = null;
        
        for(String str: bppFieldSet){
            if(sobj.get(str) == true){
                if(bppStr == null){
                    bppStr = getBPPPicklistBasedOnBPPField(str);
                } else{
                    bppStr = bppStr + ';' + getBPPPicklistBasedOnBPPField(str);
                }
            }
        }
        return bppStr;
    }
    
    //MARIT-873
    public static String getBPPPicklistBasedOnBPPField(String str){
        if(str.contains('Growth')){
            return 'Growth';
        } else if(str.contains('Monetization')){
            return 'Monetization and Cost';
        } else if(str.contains('Performance')){
            return 'Performance';
        } else if(str.contains('Security')){
            return 'Security';
        } else if(str.contains('UX')){
            return 'UX';
        }
        return null;
    }

    //SFDC-4547 check what to do in Marketo and Akamai Lead
    public static void CheckDuplicates(Lead[] triggerNew){
        if(!checkDuplicatesFirstRunFlag)
            return;
        Map<String, Lead> newLeadMap = new Map<String, Lead>();
        Id marketoRecordType = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Marketo Lead').getRecordTypeId();
        for(Lead lead: triggerNew){
            if(lead.recordTypeId == marketoRecordType){
                if(lead.Validation_Override__c != true){
                    if(newLeadMap.get(lead.Email)!=null && lead.recordTypeId == marketoRecordType){
                        lead.Email.AddError('A Lead with email '+lead.email+' already exists in the same list.');
                    }
                    else{
                        newLeadMap.put(lead.email,lead);
                    }
                }
            }
        }
        if(newLeadMap != null && !newLeadMap.isEmpty())
        {
            for(Lead existingLead: [select id,
                    Email 
                    from Lead 
                    where Email IN :newLeadMap.keySet() 
                    and Id NOT IN :triggerNew 
                    and recordTypeId = :marketoRecordType
                    and Status NOT IN ('Converted','Closed')]){
                Lead tempNewLead = null;
                if(newLeadMap.get(existingLead.Email)!=null)
                {
                    tempNewLead = newLeadMap.get(existingLead.Email);
                    String errorMessage = 'A Lead with email '+existingLead.Email+' already exists in the system. Please use Salesforce Global Search to find the record with this email.';
                    tempNewLead.Email.addError(errorMessage);
                    newLeadMap.remove(existingLead.Email);
                }
            }
        }
        //MARIT-874,marketo lead's email exists in contact throw error
        if(newLeadMap != null && !newLeadMap.isEmpty())
        {
            for(Contact existingContact: [select id,Email from contact where Email IN :newLeadMap.keySet()]){
                Lead tempNewLead = null;
                if(newLeadMap.get(existingContact.Email) != null){
                    tempNewLead = newLeadMap.get(existingContact.Email);
                    String errorMessage = 'A Contact with email '+existingContact.Email+' already exists in the system. Please use Salesforce Global Search to find the record with this email.';
                    tempNewLead.Email.addError(errorMessage);
                    newLeadMap.remove(existingContact.Email);
                }
            }
        }
        checkDuplicatesFirstRunFlag = false;
    }

    //SFDC-4384
    public static void setAssociatedAccountOnLead(List<Lead> leadListHavingMarketoAkamAccountId, List<String> marketoAkamAccountIdList){
        if(!setAssociatedAccountOnLead)
            return;

        Map<String,Id> AkamIdToSfId = new Map<String,Id>();
        for(Account a : [Select Id, AKAM_Account_ID__c from Account where AKAM_Account_ID__c IN : marketoAkamAccountIdList]){
            AkamIdToSfId.put(a.AKAM_Account_ID__c,a.Id);
        }
        for(Lead l : leadListHavingMarketoAkamAccountId){
            l.Associated_Account__c = AkamIdToSfId.get(l.Marketo_AKAM_Account_ID__c);
        }

        setAssociatedAccountOnLead = false;
    }

    public static void setInitialSLAs(List<Lead> leadList){
        if(!setSLAsFRFlag)
            return;
        String slaTimes = GSMUtilClass.getGSMSettingValue('Annuitas_SLAs_Times_to_be_added');
        List<String> slaTimeList = slaTimes.split(',');
        List<Integer> slaTimeListNumber = new List<Integer>();
        for(String slaTime: slaTimeList)
            slaTimeListNumber.add(Integer.valueOf(slaTime));
        for(Lead ld: leadList){
            String hotOrWarm = LeadUtilClass.isBPPStageWarmOrHot(ld);
            system.debug(LoggingLevel.ERROR,'hotOrWarm:: '+hotOrWarm+' ld.First_SLA__c: '+ld.First_SLA__c);
            system.debug(LoggingLevel.ERROR,'ld.adg_Self_Generated_Lead_Type__c:: '+ld.adg_Self_Generated_Lead_Type__c);
            if(hotOrWarm.CONTAINS('Hot')){
                ld.First_SLA_DT__c = ld.First_Assignment_Date__c.addHours(slaTimeListNumber[0]);
                ld.Last_SLA_DT__c = ld.First_Assignment_Date__c.addDays(slaTimeListNumber[1]);
            } else {
                ld.First_SLA_DT__c = ld.First_Assignment_Date__c.addDays(slaTimeListNumber[2]);
                ld.Last_SLA_DT__c = ld.First_Assignment_Date__c.addDays(slaTimeListNumber[3]);
            }
        }
        setSLAsFRFlag = false;
    }

    //SFDC-4546
    public static void setSLAs(List<Lead> leadList, Boolean isUpdate){
        system.debug(LoggingLevel.ERROR,'setSLAsFRFlag: '+setSLAsFRFlag);

        String leadStatus = GSMUtilClass.getGSMSettingValue('DemandGen_LeadStatusForSla');
        String firstTouchCompliance = GSMUtilClass.getGSMSettingValue('Annuitas_First_Touch_Compliance_Values');
        List<String> firstTouchComplianceList = firstTouchCompliance.split(',');
        String dispositionCompliance = GSMUtilClass.getGSMSettingValue('Annuitas_Disposition_Compliance_Values');
        List<String> dispositionComplianceList = dispositionCompliance.split(',');

        Datetime today = Datetime.now();
        for(Lead ld: leadList){
            String hotOrWarm = LeadUtilClass.isBPPStageWarmOrHot(ld);
            system.debug(LoggingLevel.ERROR,'hotOrWarm:: '+hotOrWarm+' leadStatus: '+leadStatus+' ld.Status: '+ld.Status+' today: '+today+' ld.First_SLA__c: '+ld.First_SLA__c);

            if(leadStatus.contains(ld.Status) || LeadUtilClass.isBPPStatusConverted(ld, null) || LeadUtilClass.isBPPStatusClosed(ld, null)){
                //Change to push
                if(hotOrWarm.CONTAINS('Hot')){
                    if(ld.adg_Dispensation_SLA__c != dispositionComplianceList[1] && today > ld.First_SLA_DT__c){
                        ld.adg_Dispensation_SLA__c = dispositionComplianceList[2];
                        system.debug(LoggingLevel.ERROR,'ld.adg_Dispensation_SLA__c in if '+ld.adg_Dispensation_SLA__c);
                    }
                    else
                        ld.adg_Dispensation_SLA__c = dispositionComplianceList[1];
                    if(today > ld.Last_SLA_DT__c)
                        ld.adg_Conversion_SLA__c = dispositionComplianceList[2];
                    else
                        ld.adg_Conversion_SLA__c = dispositionComplianceList[1];

                }
                else if(hotOrWarm.CONTAINS('Warm')){
                    if(ld.adg_Dispensation_SLA__c != firstTouchComplianceList[1] && today > ld.First_SLA_DT__c){
                        ld.adg_Dispensation_SLA__c = firstTouchComplianceList[2];
                        system.debug(LoggingLevel.ERROR,'ld.adg_Dispensation_SLA__c in if '+ld.adg_Dispensation_SLA__c);
                    }
                    else
                        ld.adg_Dispensation_SLA__c = firstTouchComplianceList[1];
                    if(today > ld.Last_SLA_DT__c)
                        ld.adg_Conversion_SLA__c = firstTouchComplianceList[2];
                    else
                        ld.adg_Conversion_SLA__c = firstTouchComplianceList[1];

                }
            }
            else if(hotOrWarm.CONTAINS('Warm')){
                if(today < ld.First_SLA_DT__c)
                    ld.adg_Dispensation_SLA__c = firstTouchComplianceList[0];
                if(today < ld.Last_SLA_DT__c)
                    ld.adg_Conversion_SLA__c = firstTouchComplianceList[0];

                if(ld.Status.contains('In Process')){
                    if(ld.adg_Dispensation_SLA__c != firstTouchComplianceList[1] && today > ld.First_SLA_DT__c){
                        ld.adg_Dispensation_SLA__c = firstTouchComplianceList[2];
                        system.debug(LoggingLevel.ERROR,'ld.adg_Dispensation_SLA__c in if '+ld.adg_Dispensation_SLA__c);
                    }
                    else
                        ld.adg_Dispensation_SLA__c = firstTouchComplianceList[1];
                }
                system.debug(LoggingLevel.ERROR,'ld.adg_Dispensation_SLA__c in if warm'+ld.adg_Dispensation_SLA__c);
            }
            else if(hotOrWarm.CONTAINS('Hot')){
                if(today < ld.First_SLA_DT__c)
                    ld.adg_Dispensation_SLA__c = dispositionComplianceList[0];
                if(today < ld.Last_SLA_DT__c)
                    ld.adg_Conversion_SLA__c = dispositionComplianceList[0];
                if(ld.Status.contains('In Process')){

                    if(ld.adg_Dispensation_SLA__c != dispositionComplianceList[1] && today > ld.First_SLA_DT__c){
                        ld.adg_Dispensation_SLA__c = dispositionComplianceList[2];
                        system.debug(LoggingLevel.ERROR,'ld.adg_Dispensation_SLA__c in if '+ld.adg_Dispensation_SLA__c);
                    }
                    else
                        ld.adg_Dispensation_SLA__c = dispositionComplianceList[1];

                }
                system.debug(LoggingLevel.ERROR,'ld.adg_Dispensation_SLA__c in if Hot'+ld.adg_Dispensation_SLA__c);
            }
            system.debug(LoggingLevel.ERROR,'ld.adg_Dispensation_SLA__c:: '+ld.adg_Dispensation_SLA__c+' ld.adg_Conversion_SLA__c: '+ld.adg_Conversion_SLA__c);
        }
    }

    // MARIT-142
    public static void postChatterOnLeadOwner(List<Lead> leadList) {
        List<Feeditem> itemList = new List<FeedItem>();
        for(Lead l: leadList) {
            FeedItem item = MARIT_ChatterUtilClass.createChatterInstance(UserInfo.getUserId(),
                                                  l.OwnerId,
                                                  '<b>' + l.Owner__c + ' </b>,  a CTA for ' +l.FirstName + ' ' + l.LastName + ' has been assigned to you.',
                                                  true);
            itemList.add(item);
        }
        if(itemList.size() > 0){
           MARIT_ChatterUtilClass.insertChatters(itemList);
        }
    }

    // MARIT-211 
    // If Latest Campaign Id field is populated in marketo lead, fetch that campaign's akam id and populate it in latest camp akam id of lead
    public static void UpdateLatestCampAkamIdFromLatestCampId(Map<Lead, Id> leadToCampaignIdMap) {
        List<Campaign> campaignLists = [Select Id, AKAM_Campaign_ID__c from Campaign where id in :leadToCampaignIdMap.values()];
        Map<Id, string> campIdToCampAkamId = new Map<Id, string>();
        for(Campaign camp: campaignLists) {
            campIdToCampAkamId.put(camp.Id, camp.AKAM_Campaign_ID__c);
        }
        for(Lead l: leadToCampaignIdMap.keyset()) {
            if (campIdToCampAkamId.containsKey(leadToCampaignIdMap.get(l))) {
                l.Latest_Campaign_AKAM_ID__c = campIdToCampAkamId.get(leadToCampaignIdMap.get(l));
            }
        }
    }

    /**
     * MARIT-684: Check for network contact validation rule expection and return user friendly error message
     * If no error matches, completeError is returned without any customization
     */
    public static String getCustomizedErrors(String error, String completeError){
        error = error.toLowerCase();
        System.debug('In getCustomizedErrors():'+error);
        String errorMsg = null;
        Pattern networkContactRegex = Pattern.compile('.*network\\s*contact.*');
        if(networkContactRegex.matcher(error).matches()){
            System.debug('In Network Contact Error::');
            errorMsg = 'Leads belonging to Network Accounts cannot be converted';
        }
        return errorMsg == null?completeError:errorMsg;
    }
    /**
     * MARIT-684: Add user friendly errors on lead record
     * Use the below method when DML operation is performed and not Database methods with partial success true
     * In DML, error on one record, fails all the records in transaction and all records receive same error
     */
    public static void addErrorOnLead(List<Lead> leads, String errorMsg){
        System.debug('In addErrorOnLead()');
        for(Lead l : leads){
            l.addError(errorMsg);
        }
    }
    
    //MARIT-687 moving workflow code to trigger to update prospect_customer__c field
    public static void updateProspectCustomerField(List<Lead> triggerNew){
        for(Lead l: triggerNew)
        {  
            if(l.Associated_Account_Name__c != null && !(l.Associated_Account_Name__c.contains('WWW Lead Gen') || l.Associated_Account_Name__c.contains('WWW Bad Data'))
               && (l.Prospect_Customer__c != 'Customer') && (l.Associated_Account_Status__c != null) 
               && (l.Associated_Account_Status__c.contains('Lead') || l.Associated_Account_Status__c.contains('Inacti'))){
                   l.Prospect_Customer__c = 'Prospect';
            } 
            else if(l.Associated_Account_Name__c != null && !(l.Associated_Account_Name__c.contains('WWW Lead Gen') || l.Associated_Account_Name__c.contains('WWW Bad Data'))
                         && (l.Prospect_Customer__c != 'Prospect') && (l.Associated_Account_Status__c != null)
                         && l.Associated_Account_Status__c.contains('Active')){
                             l.Prospect_Customer__c = 'Customer';
            } 
            else if(l.Associated_Account_Name__c != null && (l.Associated_Account_Name__c.contains('WWW Lead Gen') || l.Associated_Account_Name__c.contains('WWW Bad Data'))){
                             l.Prospect_Customer__c = 'Unknown';
            }
        }
    }

    //MARIT-946 acd 
    public static void removePhoneValueWhenDNCFlagIsCheckedLead(List<Lead> removePhoneValueLeads,List<Contact> removePhoneValueContacts){
        for(Lead l: removePhoneValueLeads){
            l.Phone_Custom__c = null;
            l.MobilePhone_Custom__c = null;
            //MARIT-1681 e164
            l.E164_Phone__c = null;
            l.E164_MobilePhone__c = null;
            l.Phone_Extension__c = null;
            l.MobilePhone_Extension__c = null;
        }
        
        for(Contact c : removePhoneValueContacts){
            c.Phone_Custom__c = null;
            c.MobilePhone_Custom__c = null;
            c.Assistant_Phone_Custom__c = null;
            //MARIT-1681 e164
            c.E164_Phone__c = null;
            c.E164_MobilePhone__c = null;
            c.Phone_Extension__c = null;
            c.MobilePhone_Extension__c = null;
        }
    }

    //MARIT-1014
    public static void checkIfCTAAlreadyExistsGeneric(Map<Id,Lead> ctaWithPersonLead, Map<Id,Lead> ctaWithPersonCon){
        String soql = 'Select Id, Associated_Contact__c, Parent_Lead__c from Lead where ( ';
        if(!ctaWithPersonCon.keySet().isEmpty()){
            soql+= 'Associated_Contact__c in ';
            soql+=MarketingUtilClass.parseIdsForDynamicQuery(new List<Id>(ctaWithPersonCon.keySet())); 
        }
        if((!ctaWithPersonCon.keySet().isEmpty()) && (!ctaWithPersonLead.keySet().isEmpty())){
            soql+= ' OR';
        }
        if(!ctaWithPersonLead.keySet().isEmpty()){
            soql+=' Parent_Lead__c in ';
            soql+=MarketingUtilClass.parseIdsForDynamicQuery(new List<Id>(ctaWithPersonLead.keySet()));
        }
        soql+=') and RecordType.Name = \'Akamai Lead\' and (Status = \'New\' OR Status = \'In Process\')';
        System.debug('priyanka soql query '+ soql);
        for(Lead lead : (List <Lead>)MarketingUtilClass.fetchFromDataBase(soql)){
            
            if(lead.Associated_Contact__c != null){
                Lead l = ctaWithPersonCon.get(lead.Associated_Contact__c);
                l.AddError('Open CTA exists on the Person');
            }
            else if(lead.Parent_Lead__c != null){
                Lead l = ctaWithPersonLead.get(lead.Parent_Lead__c);
                l.AddError('Open CTA exists on the Person');
            }
        }
        
    }
    //MARIT-987
    public static void checkContactExists(Map<String,Lead> leadsToCheckEmails){
        System.debug(logginglevel.DEBUG,'In Email Validation for Converted leads'); //MARIT-987
        for(Contact existingContact: [select id,Email from contact where Email IN :leadsToCheckEmails.keySet()]){
            if(leadsToCheckEmails.get(existingContact.Email) != null){
                Lead lead = leadsToCheckEmails.get(existingContact.Email);
                String errorMessage = 'Lead cannot be converted. A Contact with email '+existingContact.Email+' already exists in the system. Please use Salesforce Global Search to find the record with this email.';
                lead.Email.addError(errorMessage);
            }
        } 
    }

    public static void assignTaskToOpenCTA(Map<Id,Id> personRecordWithOpenCTA){
        Set<Id> parentIds = new Set<Id>();
        parentIds = personRecordWithOpenCTA.keySet();
        try{
            List<Task> tasks = [select id, WhoId, WhatId from Task where WhoId in :parentIds and subject = 'Conversation in Drift' and CreatedDate > :Datetime.now().addMinutes(-10)];
            for(task t : tasks){
                t.WhatId = null; //setting null if earlier task was assigned to contact it would error out since lead can't have what id
                t.WhoId = personRecordWithOpenCTA.get(t.WhoId);
            }

            if(tasks != null && !tasks.isEmpty()){
                update tasks;
            }
        }
        catch(Exception e){
            Error_Log__c el = new Error_Log__c(Name='assignTaskToOpenCTA', Class__c='MARIT_LeadTriggerClass', Error_Message__c=e.getMessage());
            insert el;
        }
    }
}