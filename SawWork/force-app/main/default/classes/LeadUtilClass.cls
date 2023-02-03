public class LeadUtilClass
{
    public static List<String> statusFieldList= GSMUtilClass.getGSMSettingValue('BPPStatusFieldsForLead')
        .replaceAll(' ', '')
        .split(',');
    public static List<String> stageFieldList= GSMUtilClass.getGSMSettingValue('BPPStageFieldsForLead')
        .replaceAll(' ', '')
        .split(',');
    public static List<String> slaFieldList= GSMUtilClass.getGSMSettingValue('BPPSLAs')
        .replaceAll(' ', '')
        .split(',');
    //MARIT-553
    public static List<String> C2APersonLeadSyncField = MarketingUtilClass.getMarketingSettingsValue('C2APersonLeadSyncFields')
        .replaceAll(' ', '')
        .split(',');
   //MARIT-735
    public static List<String> commonLeadFields= String.join(MarketingUtilClass.getMarketingSettingValuePartialMatch('marketoC2ASyncFields'),',')
        .replaceAll(' ', '')
        .split(',');
   //MARIT-787
    public static List<String> bppStageListForSelfGen = MarketingUtilClass.getMarketingSettingsValue('BPPStageListForSelfGen')
        .replaceAll(', ', ',')
        .split(',');

    public static Map<String, String> stageFieldToLabel= (Map <String, String>) JSON.deserialize(
            GSMSettings.getVerbose('BPPStageAPIToLabelMapping'), Map<String, String>.class);

    public static Map<String, String> stageToStatus= (Map <String,String>) JSON.deserialize(
            GSMSettings.getVerbose('BPPStageToStatusMapping'), Map<String,String>.class);

    public static List<String> isBPPStatusClosedConvertedOrTurnBack(Lead lead, Lead oldLead){
        List<String> statuses = new List<String>{'Closed', 'Converted', 'Turnback'};
        List<String> returnStatuses = new List<String>();

        for(String status : statuses){
            Boolean fieldMatched=false;
            for(String field: statusFieldList){
                String fieldValue = (String) lead.get(field);
                if(fieldValue!=null && fieldValue.contains(status) && Util.hasChanges(field, oldLead, lead)){
                    returnStatuses.add(fieldValue);
                }
            }
        }
        return returnStatuses;
    }

    //MARIT-553
    public static Boolean checkDeltaChanges(Lead lead, Lead oldLead, String field){
        Boolean changedField = false;
        if(Util.hasChanges(field, oldLead, lead)){
               changedField = true;
           }
        return changedField;
    }

    public static void updateBPPStatusBasedOnStage(Lead targetLead, String statusToCopyOver){
        Boolean warmStagesExistWhichAreNotTurnedBack=false;

        for(String field: stageFieldList){
            String fieldValue = (String) targetLead.get(field);
            if(fieldValue!=null && (fieldValue == 'Qualified Lead - Warm' 
                        || fieldValue == 'Qualified Lead - Hot')){
                if(statusToCopyOver.containsIgnoreCase('Turnback')){
                    String currValue= (String)targetLead.get(stageToStatus.get(field));
                    if(currValue!=null){
                        if(!currValue.containsIgnoreCase('turnback')){
                            warmStagesExistWhichAreNotTurnedBack=true;
                        }
                    }
                    else{
                        warmStagesExistWhichAreNotTurnedBack=true;
                    }
                }
                else{
                    targetLead.put(stageToStatus.get(field),statusToCopyOver);
                }
            }
        }
        if(statusToCopyOver.containsIgnoreCase('turnback') && !warmStagesExistWhichAreNotTurnedBack){
            targetLead.put('Status', 'Closed');
        }
        if(statusToCopyOver.containsIgnoreCase('Closed')){
            targetLead.put('Status', 'Closed');
        }
    }

    public static Boolean hasPassedBPPStageThreshold(Sobject currObj, Sobject oldObj){
        for(String field: stageFieldList){
            if(Util.hasChanges(field, oldObj, currObj)
                    && currObj.get(field) != null && 
                    (currObj.get(field) == 'Qualified Lead - Warm' ||
                     currObj.get(field) == 'Qualified Lead - Hot')){
                return true;
            }
        }
        return false;
    }

    public static Boolean hasPassedBPPStageThreshold(Sobject currObj){
        return hasPassedBPPStageThreshold(currObj, null);
    }

    public static Boolean isBPPStatusClosed(Lead lead, Lead oldLead){

        for(String field: statusFieldList){
            String fieldValue = (String) lead.get(field);
            if(Util.hasChanges(field, oldLead, lead) 
                    && lead.get(field) != null 
                    && fieldValue.contains('Closed')){
                return true;
            }
        }
        return false;
    }

    public static Boolean isBPPStatusConverted(SObject newRecord,SObject oldRecord){
        for(String field : statusFieldList){
            String fieldValue = (String) newRecord.get(field);
            if(Util.hasChanges(field, oldRecord, newRecord) 
                    && newRecord.get(field) != null 
                    && fieldValue.contains('Converted')){
                System.Debug(LoggingLevel.error, 'AGH_D field was'+field+'  nadd'+fieldValue);
                return true;
            }
        }
        return false;
    }
    //SFDC-4546
    public static String isBPPStageWarmOrHot(Lead lead){
        for(String field: stageFieldList){
            if(lead.get(field) != null && lead.get(field) == 'Qualified Lead - Hot'){
                return 'Hot';
            }
        }
        return 'Warm';
    }
    //MARIT-0000, PDG2.0
    public static String getBuyerPainPoint(Sobject sourceObj){
        List<String> labels = new List<String>();
        if(sourceObj.get('Buyer_Pain_Points__c') != null){
               return sourceObj.get('Buyer_Pain_Points__c').toString();
        }
        return null;
    }
    public static Contact copyBPPStatusFields(Lead sourceLead, Contact targetContact){
        for(String field: statusFieldList){
            targetContact.put(field, sourceLead.get(field));
        }
        return targetContact;
    }
    public static Lead copyBPPStatusFields(Lead sourceLead, Lead targetLead){
        for(String field: statusFieldList){
            targetLead.put(field, sourceLead.get(field));
        }
        return targetLead;
    }
    public static Lead copyBPPStatusFields(Contact sourceContact, Lead targetLead){
        for(String field: statusFieldList){
            targetLead.put(field, sourceContact.get(field));
        }
        return targetLead;
    }
    public static Contact copyBPPSLAFields(Lead sourceLead, Contact targetContact){
        for(String field: slaFieldList){
            targetContact.put(field, sourceLead.get(field));
        }
        return targetContact;
    }
    public static Lead copyBPPSLAFields(Lead sourceLead, Lead targetLead){
        for(String field: slaFieldList){
            targetLead.put(field, sourceLead.get(field));
        }
        return targetLead;
    }
    public static Lead copyBPPSLAFields(Contact sourceContact, Lead targetLead){
        for(String field: slaFieldList){
            targetLead.put(field, sourceContact.get(field));
        }
        return targetLead;
    }

    public static Lead copyBPPStageFields(Contact sourceContact, Lead targetLead){
        for(String field: stageFieldList){
            targetLead.put(field, sourceContact.get(field));
        }
        return targetLead;
    }
    public static Lead copyBPPStageFields(Lead sourceLead, Lead targetLead){
        for(String field: stageFieldList){
            targetLead.put(field, sourceLead.get(field));
        }
        return targetLead;
    }
    //MARIT-553
    public static Lead c2aToPersonSync(Lead sourceNewLead, Lead sourceOldLead, Lead targetLead){
        for (String field: C2APersonLeadSyncField){
            Boolean deltaField = checkDeltaChanges(sourceNewLead, sourceOldLead, field);
            if(deltaField)
                targetLead.put(field,sourceNewLead.get(field));
        }
        return targetLead;
    }
    public static Contact c2aToPersonSync(Lead sourceNewLead, Lead sourceOldLead, Contact targetContact){
        for (String field: C2APersonLeadSyncField){
            Boolean deltaField = checkDeltaChanges(sourceNewLead, sourceOldLead, field);
            if(deltaField){
                if(field == 'city'){
                    targetContact.Mailingcity = sourceNewLead.city;
                } else if(field == 'street'){
                    targetContact.Mailingstreet = sourceNewLead.street;
                } else if(field == 'state'){
                    targetContact.Mailingstate = sourceNewLead.state;
                } else if(field == 'country'){
                    targetContact.Mailingcountry = sourceNewLead.country;
                } else if(field == 'postalCode'){
                    targetContact.MailingpostalCode = sourceNewLead.postalCode;
                } else {
                    targetContact.put(field,sourceNewLead.get(field));
                }
            }
        }
        return targetContact;
    }
    public static Contact copyBPPSLAFields(Lead sourceNewLead, Lead sourceOldLead, Contact targetContact){
        for(String field: slaFieldList){
            Boolean deltaField = checkDeltaChanges(sourceNewLead, sourceOldLead, field);
            if(deltaField)
                targetContact.put(field, sourceNewLead.get(field));
        }
        return targetContact;
    }
    public static Lead copyBPPSLAFields(Lead sourceNewLead, Lead sourceOldLead, Lead targetLead){
        for(String field: slaFieldList){
            Boolean deltaField = checkDeltaChanges(sourceNewLead, sourceOldLead, field);
            if(deltaField)
                targetLead.put(field, sourceNewLead.get(field));
        }
        return targetLead;
    }
    public static Contact copyBPPStatusFields(Lead sourceNewLead, Lead sourceOldLead, Contact targetContact){
        if(sourceNewLead.get('Reason_For_Closure__c') == null){
            for(String field: statusFieldList){
                Boolean deltaField = checkDeltaChanges(sourceNewLead, sourceOldLead, field);  
                if(deltaField)
                    targetContact.put(field, sourceNewLead.get(field));
            }
        }
        return targetContact;
    }
    public static Lead copyBPPStatusFields(Lead sourceNewLead, Lead sourceOldLead, Lead targetLead){
        for(String field: statusFieldList){
            Boolean deltaField = checkDeltaChanges(sourceNewLead, sourceOldLead, field); 
            if(deltaField)
                targetLead.put(field, sourceNewLead.get(field));
        }
        return targetLead;
    }
    //MARIT-735
    public static Lead copyCommonLeadFields(Lead sourceNewLead, Lead sourceOldLead, Lead targetLead){
        for(String field: commonLeadFields){
            Boolean deltaField = checkDeltaChanges(sourceNewLead, sourceOldLead, field); 
            if(deltaField)
                targetLead.put(field, sourceNewLead.get(field));
        }
        return targetLead;
    }
    //SFDC-4547-12
    public static Lead copyContactAndConvertLeadFields(Lead sourceLead, Lead targetLead){
        if(sourceLead.Associated_Contact__c != null)
            targetLead.Associated_Contact__c = sourceLead.Associated_Contact__c;
        else if(sourceLead.ConvertedContactId != null)
            targetLead.Associated_Contact__c = sourceLead.ConvertedContactId;

        if(sourceLead.Convert_to_Opportunity__c == true){
            targetLead.Convert_to_Opportunity__c = true;
        }
        return targetLead;
    }

    public static Lead createAkamaiLeadFromMarketoLead(Lead sourceLead){
        Lead targetLead = new Lead();
        targetLead.Parent_Lead__c = sourceLead.id;
        List<String> akamaiLeadFields = new List<String>();
        //MARIT-5
        List<String> localAddrFields = new List<String>();
        for(String metadataValue: MarketingUtilClass.getMarketingSettingValuePartialMatch('AkamaiLeadCreationFromMarketoLead')){
            localAddrFields.addall(metadataValue.replaceAll(' ','').split(','));
        }
        akamaiLeadFields.addAll(localAddrFields);
        Set<String> fieldList = new Set<String>();
        fieldList.addAll(akamaiLeadFields);
        for(String field: fieldList){
            if(field.equalsIgnoreCase('Status')){
                targetLead.Status = 'New';
            } else{
                targetLead.put(field, sourceLead.get(field));
            }
        }
        targetLead.recordTypeId = GSMUtilClass.getGSMSettingValue('AkamaiLeadRecordTypeId');
        targetLead = copyBPPStageFields(sourceLead, targetLead);
        targetLead = copyBPPStatusFields(sourceLead, targetLead);
        targetLead = copyContactAndConvertLeadFields(sourceLead, targetLead);
        targetLead.Associated_Contact__c = sourceLead.ConvertedContactId;
        targetLead.Buyer_Pain_Points__c = sourceLead.Buyer_Pain_Points__c; //PDG 2.0
        System.debug(LoggingLevel.Error,'AGH_D createAkamaiLeadFromMarketoLead m1'+targetLead.Status);
        return targetLead;
    }

    public static Lead createAkamaiLeadFromContact(Contact sourceCon){
        Lead targetLead = new Lead();
        targetLead.Associated_Contact__c = sourceCon.id;

        // MARIT-5, MARIT-12
        List<String> akamaiLeadFields = new List<String>();
        for(String metadataValue: MarketingUtilClass.getMarketingSettingValuePartialMatch('AkamaiLeadCreationFromContact')){
            akamaiLeadFields.addall(metadataValue.replaceAll(' ','').split(','));
        }
        for(String field: akamaiLeadFields){
            if(field == 'Mailingcity'){
                targetLead.City = sourceCon.MailingCity;
            } else if(field == 'Mailingstreet'){
                targetLead.Street = sourcecon.MailingStreet;
            } else if(field == 'Mailingstate'){
                targetLead.State = sourceCon.MailingState;
            } else if(field == 'Mailingcountry'){
                targetLead.Country = sourceCon.MailingCountry;
            } else if(field == 'MailingpostalCode'){
                targetLead.PostalCode = sourceCon.MailingPostalCode;
            }else{
                targetLead.put(field, sourceCon.get(field));
            }
        }
        targetLead.Company = sourceCon.LastName;
        targetLead.FirstName = sourceCon.FirstName;
        targetLead.Validation_Override__c = true;
        targetLead.Status = 'New';
        targetLead.recordTypeId = GSMUtilClass.getGSMSettingValue('AkamaiLeadRecordTypeId');
        targetLead.Associated_Account__c = sourceCon.AccountId;
        targetLead.Buyer_Pain_Points__c = sourceCon.Buyer_Pain_Points__c; //PDG 2.0
        targetLead = copyBPPStageFields(sourceCon, targetLead);
        targetLead = copyBPPStatusFields(sourceCon, targetLead);
        return targetLead;
    }
    
    //MARIT-1822: create a self gen CTA for a Marketo lead or contact, tie it to the requested campaignID
    public static Map<string,Map<SObject,string>> createCTAforPerson(Map<Id, Id> personTocampaignMap, Map<Id, Id> contactTocampaignMap, string selfGenleadType, string productline) {
        
        Map<string,Map<SObject,string>> result = new Map<string,Map<SObject,string>>();
        List<Id> leadIds = new List<Id>();
        if(personTocampaignMap != null) {
            leadIds.addAll(personTocampaignMap.keySet());
        }    
        List<Id> contactIds = new List<Id>();
        if(contactTocampaignMap != null) {
            contactIds.addAll(contactTocampaignMap.keySet());
        } 
        List<Lead> ctas = new List<Lead>();
        String akamaiLeadRecordTypeId = GSMUtilClass.getGSMSettingValue('AkamaiLeadRecordTypeId');
        List<String> ctafromContactOrLeadCommonFields = new List<String>();
        try {
            for(String fieldList:MarketingUtilClass.getMarketingSettingValuePartialMatch('C2ACreationFromContactOrLeadCommonField') ){
                ctafromContactOrLeadCommonFields.addall(fieldList.replaceAll(' ','').split(','));
            }
            String commonFieldsList = String.join(ctafromContactOrLeadCommonFields, ',');  
            
            Map<SObject,string> ctaNotcreated = new Map<SObject,string>();
            Map<SObject,string> ctacreated = new Map<SObject,string>();

            //check if open CTA exists
            List<Lead> akamaiLeads = [Select Id,parent_lead__c,Associated_Contact__c,FirstName,LastName From Lead where (Associated_Contact__c =:contactIds OR parent_lead__c in :leadIds) AND Status IN ('In Process','New') AND RecordTypeId =:akamaiLeadRecordTypeId Order By CreatedDate DESC];
            if(akamaiLeads != null && !akamaiLeads.isEmpty()) {
                for(Lead l :akamaiLeads) {
                    if(l.parent_lead__c != null) {
                        personTocampaignMap.remove(l.parent_lead__c);
                        ctaNotcreated.put(l,'This person has an Open CTA.');
                    }    
                    else if(l.Associated_Contact__c != null) {
                        contactTocampaignMap.remove(l.Associated_Contact__c);
                        ctaNotcreated.put(l,'This person has an Open CTA.');
                    }     
                }
            }
            leadIds.clear();
            leadIds.addAll(personTocampaignMap.keySet());
            
            contactIds.clear();
            contactIds.addAll(contactTocampaignMap.keySet());
            
            if(contactIds != null && !contactIds.isEmpty()) {
                //Ignore person leads which have donot call and email optout set
                String contactQuery = 'Select id,'+commonFieldsList+',MailingCountry,MailingStreet,MailingState,MailingCity, MailingPostalCode ,AccountId,Account.Name,Account.OwnerId,Account.Vertical__c,Account.Sub_Vertical__c From Contact Where Id in (\'' + String.join(contactIds,'\',\'') + '\')';
                List<Contact> contactRecords = Database.query(contactQuery);
                
                //create CTA
                if(contactRecords != null && !contactRecords.isEmpty()) {
                    Set<Id> contactsWithOpenOppty = MARIT_ContactUtilClass.checkContactOpenOppt(contactIds, 'Open_Opportunity_Stage_Name');
                    for(Contact con :contactRecords) {
                        //MARIT-714 - check for contact having open oppt or donotcall flag or email opt out flag is checked. If present don't create CTA
                        if(con.DoNotCall == true && con.HasOptedOutOfEmail == true) {
                            ctaNotcreated.put(con,'This person is both Email Opt Out and Do Not Call.');
                        } else if(contactsWithOpenOppty.contains(con.id)) { 
                            ctaNotcreated.put(con,'This person has an Open Opportunity.');
                        } else {
                            Lead cta = new Lead();  
                            for(String field:ctafromContactOrLeadCommonFields){
                                if(field == 'Lead_Qualification_Stage__c'){
                                    cta = LeadUtilClass.setLeadQualFieldsFromParent(con, cta, selfGenleadType);
                                } else if(field == 'Lead_Qualification_Status__c'){
                                    continue;
                                }else{
                                    cta.put(field,con.get(field));
                                }
                            }
                            cta.Associated_Contact__c = con.id;
                            cta.Primary_Campaign__c = contactTocampaignMap.get(con.id);
                            cta.adg_Self_Generated_Lead_Type__c = selfGenleadType;
                            cta.Associated_Account__c  = con.AccountId;
                            cta.Product_Line__c = productline;
                            cta.Company = con.Account.Name;
                            cta.Country = con.MailingCountry;
                            cta.Street = con.MailingStreet;
                            cta.State = con.MailingState;
                            cta.City = con.MailingCity;
                            cta.PostalCode = con.MailingPostalCode;
                            cta = setCTAfields(cta);
                            ctas.add(cta);
                        }    
                    }    
                }    
            }    
            
            if(leadIds != null && !leadIds.isEmpty()) {
                //Ignore person leads which have donot call and email optout set
                String leadQuery = 'Select id,'+commonFieldsList+',Country,State,Street,City, PostalCode ,Company,Associated_Account__c,Associated_Account__r.OwnerId From Lead Where Id in (\'' + String.join(leadIds,'\',\'') + '\')';
                List<Lead> leadRecords = Database.query(leadQuery);
                
                //create CTA
                if(leadRecords != null && !leadRecords.isEmpty()) {
                    for(Lead l :leadRecords) {
                        if(l.DoNotCall == true && l.HasOptedOutOfEmail == true) {
                            ctaNotcreated.put(l,'This person is both Email Opt Out and Do Not Call.');
                        } else  {
                            Lead cta = new Lead();
                            for(String field:ctafromContactOrLeadCommonFields){
                                if(field == 'Lead_Qualification_Stage__c'){
                                    cta = LeadUtilClass.setLeadQualFieldsFromParent(l, cta, selfGenleadType);
                                } else if(field == 'Lead_Qualification_Status__c'){
                                    continue;
                                } else{
                                    cta.put(field,l.get(field));
                                }
                            }
                            cta.Parent_Lead__c = l.id;
                            cta.Primary_Campaign__c = personTocampaignMap.get(l.id);
                            cta.adg_Self_Generated_Lead_Type__c = selfGenleadType;
                            cta.Associated_Account__c  = l.Associated_Account__c;
                            cta.Product_Line__c = productline;
                            cta.Company = l.Company;
                            cta.Country = l.Country;
                            cta.Street = l.Street;
                            cta.State = l.State;
                            cta.City = l.City;
                            cta.PostalCode = l.PostalCode;
                            cta = setCTAfields(cta);
                            ctas.add(cta);
                        }
                    }
                }
            }
            
                        
            if(ctas != null && !ctas.isEmpty()) {
                ctas = LeadToContactConversionClass.ProjectSDRForONALeads(ctas);
                Database.SaveResult[] results = Database.insert(ctas);
                for(Lead cta:ctas) {
                    ctacreated.put(cta,'CTA created');
                }    
            }
            result.put('success',ctacreated);
            result.put('error',ctaNotcreated);
        } catch(Exception ex) {
            String ids = String.join(contactIds,'\',\'')+','+String.join(leadIds,'\',\'');
            if(ids.length() > 50) {
                ids = ids.substring(0, 49);
            }
            Error_Log__c el = new Error_Log__c(Name='createCTAforPerson', Class__c='LeadUtilClass', Error_Message__c=ex.getMessage(), RecordId__c= ids);
            insert el; 
        }
        return result;
    }
    
    public static Lead setCTAfields(Lead cta) {
        cta.Status = 'New';
        cta.RecordTypeId =  GSMUtilClass.getGSMSettingValue('AkamaiLeadRecordTypeId');
        cta.Disposition__c = GSMUtilClass.getGSMSettingValue('ContactConversionLeadDisposition');
        if(ProfileUtils.isSDR()) {
            cta.Lead_Owner__c = UserInfo.getUserId();
            cta.OwnerId = UserInfo.getUserId();
            cta.isC2ABySDR__c = true;
        }
        if(String.isBlank(cta.Lead_Qualification_Status__c)) {
            cta.Lead_Qualification_Status__c = 'Prospect';
        }
        if(String.isBlank(cta.Lead_Qualification_Stage__c)) {
            cta.Lead_Qualification_Stage__c = 'Prospect';
        }
        return cta;
    }

    public static String updateHighestLeadQualificationStage(Set<String> stageFieldsQL, Sobject currObj, List<String> highest_lowest_QL_Stage){
        Boolean flag = false;
        String HQLValue = '';
        for (String stage : highest_lowest_QL_Stage) {
            for (String field : stageFieldsQL) {
                if(currObj.get(field) == stage){
                    flag=true;
                    HQLValue=stage;
                    break;
                }
            }
            if(flag) break;
        }
        //currObj.Highest_Lead_Qualification_Stage__c=HQLValue;
        return HQLValue;
    }
    
    //MARIT-787
    public static Lead setLeadQualFieldsFromParent(Sobject parentRecord, Lead childRecord, String LeadType){
         if(LeadType!=null && (LeadType.contains('Inbound Call') || LeadType.contains('Inbound Email') || LeadType.contains('Inbound Chat'))){
            for(String field: stageFieldList){
                childRecord.put(field, 'Qualified Lead - Hot');
                for(String statusField: statusFieldList){
                    childRecord.put(statusField, 'New');
                }
            }
        } else{
            for(String field: stageFieldList){
                String stageFieldValue = parentRecord.get(field) != NULL? parentRecord.get(field).toString():NULL;
                if(stageFieldValue == NULL){
                    childRecord.put(field, 'Prospect');
                    for(String statusField: statusFieldList){
                        childRecord.put(statusField, 'New');
                    }
                } else if(MarketingUtilClass.checkStringInList(bppStageListForSelfGen, stageFieldValue)){
                    childRecord.put(field, stageFieldValue);
                    for(String statusField: statusFieldList){
                        childRecord.put(statusField, parentRecord.get(statusField));
                    }
                } else{
                    childRecord.put(field, 'Turnback');
                    for(String statusField: statusFieldList){
                        childRecord.put(statusField, 'Turnback Future Opportunity');
                    }
                }
            }

        }
    return childRecord;
    }

}