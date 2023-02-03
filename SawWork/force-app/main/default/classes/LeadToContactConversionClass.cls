public without sharing class LeadToContactConversionClass
{
    public static Boolean convertLeadsToContactsFirstRunFlag=true;
    public static Boolean migrateTasksFirstRunFlag = true;
    public static Boolean updatePersonContactOrLeadFromC2ALeadFirstRunFlag= true;
    public static Boolean updateC2ALeadFromPersonContactOrLeadFirstRunFlag=true;
    public static Boolean updateOpptysAndLeadsFirstRunFlag=true;
    //SFDC-4546
    public static Boolean populatePersonFieldsFRFlag = true;
    public static Boolean addErrorOnLeadFlag = true;
    public static String ONAPoolOpsIdList = GsmUtilClass.getGSMSettingValue('ONAPoolOpsIdList');
    public static String wwwAccountId = GsmUtilClass.getGSMSettingValue('WWWLeadGenAccountIdMarketo');

    //MARIT-502
    public static Boolean leadConversionAsynModeFlag = false; //set from script 
    public static Boolean isLeadConversionAsynModeSet = MarketingIT_Custom_Settings__c.getValues('LeadAsyncConversionFlagStatus') != null?Boolean.valueOf(MarketingIT_Custom_Settings__c.getValues('LeadAsyncConversionFlagStatus').Flag_Status__c):true; //set from custom settings

    //migrateTask works for both marketo lead and person contact marit-773
    public static void migrateTasks(Map<Id, Id> convertedLeadIdsWithContactIdMap)
    {
        if(!migrateTasksFirstRunFlag)
            return;

        Set<Id> keySet = new Set<Id>();
        keySet = convertedLeadIdsWithContactIdMap.keySet();
        List<Task> tasks = [select id, whoId from task where whoId in :keySet];

        for(Task task : tasks)
        {
            task.whoID = convertedLeadIdsWithContactIdMap.get(task.whoID);
        }

        update tasks;

        migrateTasksFirstRunFlag=false;
    }

    public static void updatePersonContactOrLeadFromC2ALead(List<Lead> c2aLeads, Map<Id, Lead> oldLeadMap)
    {
         if(!updatePersonContactOrLeadFromC2ALeadFirstRunFlag)
             return;

        Set<Id> dmlIds = new Set<Id>();
        List<Contact> updateContactList = new List<Contact>();
        List<Lead> updateMarketoLeadList = new List<Lead>();
        for(Lead l: c2aLeads)
        {
            Lead oldL = oldLeadMap.get(l.Id);
            if(l.Associated_contact__c != null)
            {
                Contact con = new Contact(id=l.Associated_contact__c);
                con = LeadUtilClass.copyBPPStatusFields(l,oldL, con);
                con = LeadUtilClass.copyBPPSLAFields(l,oldL, con);
                con = LeadUtilClass.c2aToPersonSync(l,oldL,con);
                if(!dmlIds.contains(con.Id))
                {
                    dmlIds.add(con.Id);
                    updateContactList.add(con);
                }
            }
            else if(l.Parent_Lead__c != null)
            {
                Lead marketoLead = new Lead(id = l.Parent_Lead__c);
                marketoLead = LeadUtilClass.copyBPPStatusFields(l,oldL, marketoLead);
                marketoLead = LeadUtilClass.copyBPPSLAFields(l,oldL, marketoLead);
                marketoLead = LeadUtilClass.c2aToPersonSync(l, oldL, marketoLead);
                if(!dmlIds.contains(marketoLead.Id))
                {
                    dmlIds.add(marketoLead.Id);
                    updateMarketoLeadList.add(marketoLead); 
                }
            }
        }
        if(updateMarketoLeadList != null && !updateMarketoLeadList.isEmpty())
            update updateMarketoLeadList;

        if(updateContactList != null && !updateContactList.isEmpty())
            update updateContactList;

        updatePersonContactOrLeadFromC2ALeadFirstRunFlag=false;
    }

    //MARIT-487 : Changed Return type to Map<String,Lead>
    public static Map<String,Lead> updateC2ALeadFromPersonContactOrLead(List<Contact> conList,List<Lead> leadList, Map<String,Lead> leadMap)
    {
        if(!updateC2ALeadFromPersonContactOrLeadFirstRunFlag)
            return leadMap;

        Map<Id, Lead> leadOrContactIdToParentLead=new Map<Id,Lead>();

        if((leadList != null && !leadList.isEmpty()) || (conList != null && !conList.isEmpty()))
        { //PDG 2.0 updated query
            for(Lead l :[Select id,
                    Parent_Lead__c,
                    Associated_Contact__c,
                    Lead_Qualification_Stage__c,
                    Lead_Qualification_Status__c
                    from Lead 
                    where (Parent_Lead__c in :leadList 
                    OR Associated_Contact__c in :conList) and (Status = 'New' OR Status = 'In Process')]) //MARIT-228
            {
                if(l.Parent_Lead__c!=null)
                    leadOrContactIdToParentLead.put(l.Parent_Lead__c, l);

                if(l.Associated_contact__c!=null)
                    leadOrContactIdToParentLead.put(l.Associated_contact__c, l);
            }
        }

        List<Lead> updateLeadList = new List<Lead>();
        if(leadList != null && !leadList.isEmpty())
        {
            for(Lead ithLead:leadList)
            {
                //MARIT-529, this code was doing ithLead.Parent_Lead__c check inside if condition. It should be ithLead.Id ideally as here ithLead is Marketo lead only.
                if(leadOrContactIdToParentLead.containsKey(ithLead.Id))
                {
                    Lead akamaiLead = leadOrContactIdToParentLead.get(ithLead.Id);
                    akamaiLead = LeadUtilClass.copyBPPStageFields(ithLead, akamaiLead);
                    akamaiLead = LeadUtilClass.copyBPPStatusFields(ithLead, akamaiLead);
                    updateLeadList.add(akamaiLead);
                }
            }
        }

        if(conList != null && !conList.isEmpty())
        {
            for(Contact ithContact:conList)
            {
                if(leadOrContactIdToParentLead.containsKey(ithContact.Id))
                {
                    Lead parentLead = leadOrContactIdToParentLead.get(ithContact.Id);
                    parentLead= LeadUtilClass.copyBPPStageFields(ithContact, parentLead);
                    parentLead= LeadUtilClass.copyBPPStatusFields(ithContact, parentLead);
                    updateLeadList.add(parentLead);
                }

            }
        }

        //if(updateLeadList.size() > 0)
        //    update updateLeadList;

        // MARIT-487 Call the Merge Updates function from the Marketing Util Class
        // The size check is not required because ulimately if empty list is added to the update list, there won't be any impact
        leadMap = (Map<String,Lead>)MarketingUtilClass.mergeUpdates(leadMap, updateLeadList);
        updateC2ALeadFromPersonContactOrLeadFirstRunFlag=false;
        return leadMap;
    }


    public static List<Lead> ProjectSDRForONALeads(List<Lead> leadList)
    {

        Map<String,Id> recordTypeNameIdMap = new Map<String,Id>();
        Map<String,Schema.RecordTypeInfo> recordTypeInfo = Schema.getGlobalDescribe().get('Lead').getDescribe().getRecordTypeInfosByName();
        for(String recordName: recordTypeInfo.keySet()){
            Schema.RecordTypeInfo recInfo = recordTypeInfo.get(recordName);
            if(recInfo.isAvailable()){
                recordTypeNameIdMap.put(recordName,recInfo.getRecordTypeId());
            }
        }

        Set<Id> accountIds = new Set<Id>();
        for(Lead l : leadList){
            if(l.Associated_Account__c != null){
                accountIds.add(l.Associated_Account__c);
            }
        }
        String query = 'SELECT Id,Projected_Sales_Owner__c,adg_Projected_Account_Owner__c,Projected_SDR__c from Account WHERE Id in :accountIds';
        Map<Id,Account> accountsMap = new Map<Id,Account>((List<Account>)Database.query(query));
        for(Lead l : leadList){
            if(l != null && l.Associated_Account__c != null){
                Account acc = accountsMap.get(l.Associated_Account__c);
                if(acc != null){
                    l.adg_Projected_Account_Owner__c = acc.adg_Projected_Account_Owner__c;
                    if(l.RecordTypeId==recordTypeNameIdMap.get('Marketo Lead')){
                        l.Projected_SDR__c = acc.Projected_SDR__c; // // To populate Projected SDR from account to Marketo Lead
                    }
                }
            }
        }
        System.debug('No of records with populated/updated PSO in ProjectSDR function:'+leadList.size());
        return leadList;
    }



    public static void updateOpptysAndLeads(List<Contact> contactList)
    {
        if(!updateOpptysAndLeadsFirstRunFlag)
            return;

        List<Opportunity> oppList = new List<Opportunity>();
        List<Contact> contactsForLeadCreation= new List<Contact>();
        List<Contact> akamaiLeadCreateList= new List<Contact>();
        List<String> openOppStageList = GSMSettings.getValue('Open_Opportunity_Stage_Name').split(',');
        Map<Id, Id> contactIdToOppIdMap = new Map<Id,Id>();
        //MARIT-714
        List<Error_Log__c> contactsWithOpenOpptToAudit = new List<Error_Log__c>();//MARIT-714
        //SFDC-4547-12 Update where clause for opp stage
        for( OpportunityContactRole ocr : [Select id,
                opportunityid, 
                contactid
                from opportunitycontactrole 
                where contactid in :contactList 
                and opportunity.StageName in :openOppStageList 
                order by opportunity.Last_Stage_Change_Date__c desc])
        {
            contactIdtoOppIdMap.put(ocr.contactid, ocr.opportunityid);
        }
        for(Contact con: contactList)
        {
            if(contactIdtoOppIdMap.containsKey(con.id))
            {
                String str = LeadUtilClass.getBuyerPainPoint(con);
                if(str != null)
                {
                    //Open Opp exist, update it.
                    Opportunity opp1 = new Opportunity();
                    opp1.id = contactIdtoOppIdMap.get(con.Id);
                    opp1.Validation_Override__c=true;
                    opp1.adg_Buyer_Pain_Point__c = str;
                    oppList.add(opp1);
                    Error_Log__c leadAuditLog = new Error_Log__c(Name=con.Id, Class__c='LeadToContactConversionClass.updateOpptysAndLeads', Error_Message__c='C2A not created because of Open Oppt:'+opp1.id);
                    contactsWithOpenOpptToAudit.add(leadAuditLog); //add log of why c2a was not created even when BPP stage has crossed threshold
                }
            }
            else
            {
                //Open Opp doesn't exist and need to work on Akamai Lead
                contactsForLeadCreation.add(con);
            }
        }
        if(oppList != null && !oppList.isEmpty())
            update oppList;

        if(contactList != null && !contactList.isEmpty())
            createOrUpdateAkamaiLeads(contactsForLeadCreation);

        if(!contactsWithOpenOpptToAudit.isEmpty()){
            insert contactsWithOpenOpptToAudit;
        }

        updateOpptysAndLeadsFirstRunFlag=false;
    }

/**
    * This method is responsible for converting lead to contact and later create akamai leads for the same.
    *
    * @param    leadIdToAssociatedAccountId     lead to associated account map
    * @param    skipAlreadyConvertedLeads       Bool to ignore already converted leads
    * @param    marketoLeadIDToOppCreationCheck lead to Opportunity creation check map
    */ 

    public static String convertLeadsToContacts(Map<Id, Id> leadIdToAssociatedAccountId, Boolean skipAlreadyConvertedLeads, Map<Id, Boolean> marketoLeadIDToOppCreationCheck)
    {
        //commenting due to MARIT-804
        //if (!convertLeadsToContactsFirstRunFlag){
        //    return null;
        //} 

        Set<Id> mLeads = new Set<Id>();
        //leadIdToAssociatedAccountId.keySet() = marketo lead ids
        if(skipAlreadyConvertedLeads)
        {
            for(Lead ithLead: [select id,
                    ConvertedContactId,
                    IsConverted
                    from Lead where id in :leadIdToAssociatedAccountId.keySet()
                    and IsConverted=true
                    and ConvertedContactId!=null])
            {
                leadIdToAssociatedAccountId.remove(ithLead.Id); //remove already converted leads
                if(marketoLeadIDToOppCreationCheck.get(ithLead.Id) == true) //MARIT-609
                    mLeads.add(ithLead.Id); //add already converted leads to this list
            }
        }
        System.debug(LoggingLevel.Error,'converting the lead start');

        Database.LeadConvert templc;
        List<Database.LeadConvert> leadconvertlist = new List<Database.LeadConvert>();
        List<Database.LeadConvertResult> lcrList=new List<Database.LeadConvertResult>();
        //SFDC-4547
        //create contact from marketo lead
        for(Id lId : leadIdToAssociatedAccountId.keySet())
        {
            if(leadIdToAssociatedAccountId.get(lId) != wwwAccountId) //MARIT-933 : Avoid marketo lead to contact conversion if account is www lead gen
            {
                templc = new Database.LeadConvert();
                templc.setLeadId(lid);
                //templc.setConvertedStatus(convertStatus.MasterLabel);
                templc.setConvertedStatus('Converted');
                //CR 3033569 - commented this line based on SF team suggestion from case #11965877
                // CR 3162831 --Uncommenting this line again to avoid duplicate account creation during Lead to Contact Conversion
                templc.setAccountId(leadIdToAssociatedAccountId.get(lId));
                templc.setDoNotCreateOpportunity(true);
                leadconvertlist.add(templc);
            } else {
                if(marketoLeadIDToOppCreationCheck.get(lId) == true)
                    mLeads.add(lId);
            }
        }
        if(leadconvertlist != null && !leadconvertlist.isEmpty())
        {
            try
            {
                System.debug(LoggingLevel.Error,'converting the lead##');
                lcrList = Database.convertLead(leadconvertlist);
            }
            catch(Exception ex)
            {
                String error = 'Exception while converting the lead:' + ex.getMessage()+',Cause:'+ex.getCause()+',Stack Trace:'+ex.getStackTraceString()+',Line No:'+ex.getLineNumber();
                System.debug(LoggingLevel.Error,error);
                List<Id> marketoLeadIds = new List<Id>(leadIdToAssociatedAccountId.keySet());
                Error_Log__c el = new Error_Log__c(Name='Contact Creation Failed', Class__c='LeadToContactConversionClass.convertLeadsToContacts', Error_Message__c=error, Object_State__c='The user is: ' + UserInfo.getUserId() + ', RecordIds='+String.join(marketoLeadIds,','), RecordId__c=marketoLeadIds.get(0));
                Database.insert(el, false);
                if(leadConversionAsynModeFlag && isLeadConversionAsynModeSet){
                    String subject = 'Error Creating Contact:'+System.URL.getSalesforceBaseUrl().toExternalForm();
                    MarketingUtilClass.sendEmails(subject, ex, leadIdToAssociatedAccountId.keySet()); //send emails for async contact creation
                    Throw new CustomException('Try Creating Contact Again'); //throw error again for executing fail over solution written in caller function class 
                }
                else{
                    //return the actual error and set user friendly error for synchronous contact creation
                    return MARIT_LeadTriggerClass.getCustomizedErrors(ex.getMessage(),error); 
                }
            }
        }

        // CR 3033569 - optimized below code
        if(lcrList != null && !lcrList.isEmpty())
        {
            System.debug(LoggingLevel.Error,'convert checkpoint 1');
            //SFDC-4547
            for(Database.LeadConvertResult lcr : lcrList)
            {
                //if lead conversion was successful
                if(lcr.isSuccess())
                {
                    System.debug(LoggingLevel.Error,'convert checkpoint 2');
                    //get the ID of the contact converted from lead
                    if(lcr.getContactId() != null && (marketoLeadIDToOppCreationCheck.get(lcr.getLeadId()) == true)){
                       mLeads.add(lcr.getLeadId());
                    }

                }
            }

        }

        // Create or update akamai Lead when flag is set to false
        // Note: When we pass akamai leads to this function we ensure that the flag is set to false.
        // Only when marketo lead with marketo convert to contact flag is true the below logic is ignored.π
        
        if(mLeads != null && !mLeads.isEmpty())
            createOrUpdateAkamaiLeads(mLeads, false, null, null);
                    
        //convertLeadsToContactsFirstRunFlag=false;
        return null;
    }

    public static void createOrUpdateAkamaiLeads(Set<Id> leadIdSet, Boolean copyBPPStageAndStatusFields, Map<Id, sObject> newMap, Map<Id, sObject> oldMap)
    {
        System.Debug(LoggingLevel.Error, 'AGH_D createOrUpdateAkamaiLeads checkpoint 1');
        Map<ID, Lead> marketoLeadIDMap = new Map<ID, Lead>();
        List<Lead> leadCreateList = new List<Lead>();
        List<Lead> leadUpsertList = new List<Lead>();
        Map<Id, List<Lead>> mLeadToALeads = new Map<Id, List<Lead>>();
        
        //MARIT-5
        String leadIds = null;
        for(Id id: leadIdSet){
            if(leadIds == null){
                leadIds = '\'' + id + '\'';
            } else{
                leadIds = leadIds + ',\'' + id + '\'';
            }
        }
        //PDG 2.0 added Buyer_Pain_Points__c field in soql query
        //MARIT-689 added datafix flag Person_Bulk_Update__c in soql query to prevent cta creation when flag is true
        String soql = 'Select id,Buyer_Pain_Points__c, Person_Bulk_Update__c, AKAM_Created_By__c, Latest_Campaign_AKAM_ID__c, Associated_Contact__c, Parent_Lead__c, Primary_Campaign__c, ConvertedContactId';
        String bppStageStr = GSMUtilClass.getGSMSettingValue('BPPStageFieldsForLead').replaceAll(' ', '');
        if(bppStageStr != null){
            soql = soql + ',' +bppStageStr;
        }
        String bppStatusStr = GSMUtilClass.getGSMSettingValue('BPPStatusFieldsForLead').replaceAll(' ', '');
        if(bppStatusStr != null){
            soql = soql + ',' +bppStatusStr;
        }
        //MARIT-554
        List<String> localAddrFields = new List<String>();
        for (String metadataValue: MarketingUtilClass.getMarketingSettingValuePartialMatch('AkamaiLeadCreationFromMarketoLead')){
             localAddrFields.addall(metadataValue.replaceAll(' ','').split(','));
        }
        string localStr = string.join(localAddrFields,',');
        if(localStr != null){
            soql = soql + ',' +localStr;
        }
        soql = soql + ' from Lead where id in (' + leadIds + ') or Parent_Lead__c in (' + leadIds + ')';
        List<Lead> queriedList = Database.query(soql);
        // List<Lead> queriedList = MARIT_DataClass.getQueryResult(soql, null, true, false);
        //id in leadIds - fetch marketo lead
        //parent_lead__c in leadIds - fetch Akamai leads
        for(Lead l: queriedList)
                    {
                        if(l.Parent_Lead__c != null)
                        {
                            //it is a akamai lead
                            if(!mLeadToALeads.containsKey(l.Parent_Lead__c))
                                mLeadToALeads.put(l.Parent_Lead__c, new List<Lead>());

                            mLeadToALeads.get(l.Parent_Lead__c).add(l); //marketo lead to its list of akamai leads
                        }
                        else if(leadIdSet.contains(l.id))
                        {
                            System.debug(LoggingLevel.Error,'AGH_D convert checkpoint 3b adding');
                            marketoLeadIDMap.put(l.id, l);
                        }
                    }
        for(Id leadId: leadIdSet)
        {
            List<Lead> lList = mLeadToALeads.get(leadid); //get all akamai leads
            Lead mLead = marketoLeadIDMap.get(leadId); //get marketo lead
            if(mLead==null)
                continue;

            boolean check = false;
            if(lList != null && !lList.isEmpty())
            {
                //iterate all akamai leads for that marketo lead
                for(Lead lead: lList)
                {
                    if(mLead!=null && (lead.Status == 'New' || lead.Status == 'In Process' || (isLeadConversionAsynModeSet && leadConversionAsynModeFlag && lead.Status == 'Converted')))
                    {
                        System.debug(LoggingLevel.Error,'AGH_D convert checkpoint 6'+lead.Parent_Lead__c);
                        lead.Associated_Contact__c = mLead.ConvertedContactId;
                        if(lead.Parent_Lead__c != null)
                        {
                            System.debug(LoggingLevel.Error,'AGH_D convert checkpoint 7');
                            if(copyBPPStageAndStatusFields)
                            {
                                lead =LeadUtilClass.copyBPPStageFields(mLead, lead);
                                lead =LeadUtilClass.copyBPPStatusFields(mLead, lead);
                                lead.Buyer_Pain_Points__c = mLead.Buyer_Pain_Points__c; //PDG 2.0
                            }
                            //MARIT-735
                            if(newMap != null && !newMap.isEmpty()){
                                Lead newLead =(Lead) newMap.get(leadid);
                                Lead oldLead =(Lead) oldMap.get(leadid);
                               lead = LeadUtilClass.copyCommonLeadFields(newLead, oldLead, lead);
                            }
                            lead =LeadUtilClass.copyContactAndConvertLeadFields(mLead, lead); //set Associated_Contact__c and Convert_to_Opportunity__c for akamai lead
                        }
                        System.debug(LoggingLevel.Error,'AGH_D convert checkpoint 8');
                        check = true;
                        leadUpsertList.add(lead);
                        break;
                    }
                }
            }
            if(check == false && mLead.Person_Bulk_Update__c == false)
            {
                //if no new / in progress akamai leads for that marketo lead, create new akamai lead
                System.debug(LoggingLevel.Error,'AGH_D convert checkpoint 8b');
                Lead akamaiLead = LeadUtilClass.createAkamaiLeadFromMarketoLead(mLead);
                leadCreateList.add(akamaiLead);
            }
        }

        if(leadCreateList != null && !leadCreateList.isEmpty())
        {
            System.debug(LoggingLevel.Error,'AGH_D convert checkpoint ');
            leadCreateList= ProjectSDRForONALeads(leadCreateList);//SFDC-4547-12
            leadCreateList = PopulatePrimaryCampaign(leadCreateList, marketoLeadIDMap, null);
            leadUpsertList.addAll(leadCreateList);
        }
        System.debug(LoggingLevel.Error,'AGH_D convert checkpoint 9 before upsert'+leadUpsertList.size());
        try
        {
            if(leadUpsertList != null && !leadUpsertList.isEmpty()){
                upsert leadUpsertList;
            }
        }
        catch(Exception ex)
        {
            String error = 'Exception while inserting/updating c2a:' + ex.getMessage()+',Cause:'+ex.getCause()+',Stack Trace:'+ex.getStackTraceString()+',Line No:'+ex.getLineNumber();
            List<Id> marketoLeadIds = new List<Id>(leadIdSet);
            Error_Log__c el = new Error_Log__c(Name='ErrorUpsertC2A', Class__c='LeadToContactConversionClass.createOrUpdateAkamaiLeads', Error_Message__c=error, Object_State__c='The user is: ' + UserInfo.getUserId() + ', RecordIds='+String.join(marketoLeadIds,','), RecordId__c=marketoLeadIds.get(0));
            System.debug(LoggingLevel.Error,error);
            Database.insert(el, false);
            if(leadConversionAsynModeFlag && isLeadConversionAsynModeSet){
                String subject = 'Eror insert/update c2a:'+System.URL.getSalesforceBaseUrl().toExternalForm();
                MarketingUtilClass.sendEmails(subject, ex, leadIdSet); //send emails for async c2a update/creation
            }
            else{
                //Set UI with below Error for synchronous C2A creation/update
                Throw new CustomException('Error while inserting/updating C2A:'+ error);
            }
        }
    }

    // MARIT-269
    public static List<Lead> PopulatePrimaryCampaign(List<Lead> leadsToBeCreated, Map<ID, Lead> marketoLeadIDMap, List<Contact> contactList) {
        Map<Id, Lead> marketoLeadToC2Alead = new Map<Id,Lead>();
        Map<Lead, String> C2ALeadToLatestCampAkamId = new Map<Lead,String>();
        Map<Id, Lead> contactToC2ALead = new Map<Id,Lead>();
        Map<Lead, Id> C2AToCampaignId = new Map<Lead,Id>();
        List<Lead> leadWithLatestCampaignAkamId = new List<Lead>();
        
        //1. For Akamai Lead we will check if it has a parent lead or an associated contact.
        // If Parent lead exists and it has latest campaign akam id, populate primary campaign of akamai lead using it
        // If associated contact exists, populate primary campaign of akamai lead using contact's Latest Campaign Id
        for(Lead ithLead: leadsToBeCreated)
        {
            if (ithLead.Primary_Campaign__c == null) {
                if(ithLead.Parent_Lead__c!=null)
                {
                    marketoLeadToC2Alead.put(ithLead.Parent_Lead__c, ithLead);
                } else if(ithLead.Associated_Contact__c!=null)
                {
                    contactToC2ALead.put(ithLead.Associated_Contact__c, ithLead);
                }
            }
        }
        
        //2. Get all marketo lead obtained from step 1 if they have Latest Campaign Akam Id.
        if (marketoLeadIDMap != null) {
            for (Lead mLead: marketoLeadIDMap.values()){
                if(marketoLeadToC2Alead.containsKey(mLead.Id) && mLead.Latest_Campaign_AKAM_ID__c != null) {
                    leadWithLatestCampaignAkamId.add(mLead);
                }
            }
        }

        //3. Get all Contacts obtained from step 1 if they have Latest Campaign Id.
        if (contactList != null) {
            for (Contact con: contactList) {
                if (contactToC2ALead.containsKey(con.Id) && con.Latest_Campaign_ID__c != null) {
                    C2AToCampaignId.put(contactToC2ALead.get(con.Id) ,con.Latest_Campaign_ID__c);
                }
            }
        }
        
        for (Lead l : leadWithLatestCampaignAkamId) {
            if (marketoLeadToC2Alead.get(l.Id) != null) {
                C2ALeadToLatestCampAkamId.put(marketoLeadToC2Alead.get(l.Id), l.Latest_Campaign_AKAM_ID__c);
            }
        }
        // 4. Once we have the Latest campaign Akam field, we will query the Campaign object to retrieve the corresponding campaign Id 
        // We will maintain it in the Map C2A to Campaign Id.
        if (C2ALeadToLatestCampAkamId != null && !C2ALeadToLatestCampAkamId.isEmpty()) {
            List<Campaign> campList = [Select Id, AKAM_Campaign_ID__c  from Campaign where AKAM_Campaign_ID__c in :C2ALeadToLatestCampAkamId.values()];
            
            //5. Maintain a map for C2A to corresponding Campaign Id.
            for (Campaign c : campList) {
                for (Lead l : C2ALeadToLatestCampAkamId.keySet()) {
                    if (C2ALeadToLatestCampAkamId.get(l) == c.AKAM_Campaign_ID__c) {
                        C2AToCampaignId.put(l, c.Id);
                    }
                }
            }
        }
        
        //6. Update akamai lead primary campaign with primary campaign Id
        for(Lead ithLead: leadsToBeCreated) {
            if (C2AToCampaignId.containsKey(ithLead)) {
                ithLead.Primary_Campaign__c = C2AToCampaignId.get(ithLead);
            }
        }
        return leadsToBeCreated;
    }

    public static void createOrUpdateAkamaiLeads(List<Contact> contactList)
    {
        List<Lead> updateAkamaiLeadList = new List<Lead>();

        List<Lead> leadUpsertList = new List<Lead>();
        List<Lead> leadCreateList = new List<Lead>();
        Map<Id, Contact> idToContactMap = new Map<Id, Contact>();

        Map<Id, List<Lead>> akamaiLeadMap = new Map<Id, List<Lead>>();
        for(Contact con: contactList)
        {
            idToContactMap.put(con.Id, con);
            if(!akamaiLeadMap.containsKey(con.Id))
                akamaiLeadMap.put(con.Id, new List<Lead>());
        }

        for(Lead l1:[Select id, 
                Status, 
                Parent_Lead__c, 
                Associated_Contact__c 
                from Lead 
                where Associated_Contact__c in :contactList])
        {
            akamaiLeadMap.get(l1.Associated_Contact__c).add(l1);
        }

        for(Id conId:akamaiLeadMap.keySet())
        {
            List<Lead> idList =akamaiLeadMap.get(conId);
            Contact ithContact = idToContactMap.get(conId);
            if(ithContact==null)
                continue;

            boolean check = false;
            for(Lead lead: idList)
            {
                if(lead.Status == 'New' || lead.Status == 'In Process')
                {
                    lead =LeadUtilClass.copyBPPStageFields(ithContact, lead);
                    lead=LeadUtilClass.copyBPPStatusFields(ithContact, lead);
                    lead.Buyer_Pain_Points__c = ithContact.Buyer_Pain_Points__c; //PDG 2.0
                    if(ithContact.Convert_to_Opportunity__c == true)
                    {
                        lead.Convert_to_Opportunity__c = true;
                        lead.Validation_Override__c = true;
                    }
                    check = true;
                    leadUpsertList.add(lead);
                    break;
                }
            }
            //MARIT-689 added check for the datafix flag Person_Bulk_Update__c will prevent cta creation when flag is true
            if(check == false && ithContact.Person_Bulk_Update__c == false)
            {
                // Create a new Lead for Person's record
                Lead akamaiLead = LeadUtilClass.createAkamaiLeadFromContact(ithContact);
                leadCreateList.add(akamaiLead);
            }
        }

        if(leadCreateList != null && !leadCreateList.isEmpty())
        {
            leadCreateList= ProjectSDRForONALeads(leadCreateList);//SFDC-4547-12
            leadCreateList = PopulatePrimaryCampaign(leadCreateList, null, contactList);
            leadUpsertList.addAll(leadCreateList);
        }
        if(leadUpsertList != null && !leadUpsertList.isEmpty()) {
            upsert leadUpsertList;
        }
    }

    public static void addErrorOnLead(List<Lead> addErrorForMissingValue, Map<Id, sObject> newLeadMap)
    {
        if(!addErrorOnLeadFlag)
            return;

        addErrorForMissingValue = [select id,
                                Associated_Contact__r.Email,
                                Parent_Lead__r.Email,
                                Associated_Contact__r.Phone,
                                Parent_Lead__r.Phone,
                                Associated_Contact__c,
                                Parent_Lead__c 
                                    from lead 
                                    where id in :addErrorForMissingValue];
        for(Lead l : addErrorForMissingValue)
        {
            if((l.Associated_Contact__c==null && l.Parent_Lead__c==null) 
                    || (String.isBlank(l.Associated_Contact__r.Email) 
                        && String.isBlank(l.Parent_Lead__r.Email) 
                        && l.Associated_Contact__r.Phone==null 
                        && l.Parent_Lead__r.Phone==null))
            {
                newLeadMap.get(l.id).addError('Both Phone and Email is blank for Associated Person. Please provide a value.');
            }
        }
        addErrorOnLeadFlag = false;
    }

    //SFDC-4546
    public static void populatePersonFields(List<Lead> leadList,List<Id> parentCons,List<Id> parentLeads, Boolean isInsertTrigger, Boolean isFieldUpdateOnly)
    {
        //if(!populatePersonFieldsFRFlag)
        //    return;
        Map<Id, Lead> parentLeadMap;
        Map<Id, Contact> parentConMap;
        //Check for empty list before querying, in order to avoid multiple queries.
        if (!parentLeads.isEmpty()) {
        	parentLeadMap = new Map<Id, Lead>([select id,Email,Phone,MobilePhone,Title,Name,country,State,City,Associated_Account__r.LBI__NumberOfOpenInProgressRecommendations__c From Lead where id in :parentLeads]);
        }
        if (!parentCons.isEmpty()) {
        	parentConMap = new Map<Id, Contact>([select id,Email,Phone,MobilePhone,Title,Name,MailingCountry,MailingState,MailingCity,Account.LBI__NumberOfOpenInProgressRecommendations__c,
                                                 Account.Name,
                                                 Account.Website,
                                                 Salutation,
                                                 FirstName,
                                                 LastName,
                                                 AccountId,         
                                                 LeadSource,
                                                 Qualifying_Question_1__c,
                                                 Qualifying_Question_2__c,
                                                 Qualifying_Question_3__c,
                                                 Qualifying_Question_4__c,
                                                 Qualifying_Answer_1__c,
                                                 Qualifying_Answer_2__c,
                                                 Qualifying_Answer_3__c,
                                                 Qualifying_Answer_4__c From Contact where id in :parentCons]);
        }

        system.debug(LoggingLevel.ERROR,'leadToPopulatePersonFields: leadList before: '+leadList);
        for(Lead l: leadList){
            String url = '<a href="'+ System.URL.getSalesforceBaseUrl().toExternalForm() + '/' ;
           if(l.Associated_Contact__c!=null && parentConMap != null){
                url+=l.Associated_Contact__c+'"'+'target="_self" >' + parentConMap.get(l.Associated_Contact__c).name + '</a>';
                l.Person_Email__c = parentConMap.get(l.Associated_Contact__c).Email;
                l.Person_Mobile__c = parentConMap.get(l.Associated_Contact__c).MobilePhone;
                l.Person_Phone__c = parentConMap.get(l.Associated_Contact__c).Phone;
                l.Person_Title__c = parentConMap.get(l.Associated_Contact__c).Title;
                l.Person_City__c = parentConMap.get(l.Associated_Contact__c).MailingCity;
                l.Person_Country__c = parentConMap.get(l.Associated_Contact__c).MailingCountry;
                l.Person_State_Province__c = parentConMap.get(l.Associated_Contact__c).MailingState;
                if (isInsertTrigger && parentConMap.get(l.Associated_Contact__c).Account.LBI__NumberOfOpenInProgressRecommendations__c > 0) {
                    l.Has_BIS__c = true;
                }
                /**
                * MARIT-1277
                * During insert : If lead values are null then only update
                * During Update : Directly update the values from contact
                * Only perform this operation when parent changes and not when cta field update happen.
               */
               if (!isFieldUpdateOnly) {
                        l.Company = (isInsertTrigger && l.Company != null) ? l.Company: parentConMap.get(l.Associated_Contact__c).Account.Name;
                        l.Website = (isInsertTrigger && l.Website != null) ? l.Website: parentConMap.get(l.Associated_Contact__c).Account.Website;
                        l.Salutation = (isInsertTrigger && l.Salutation != null) ? l.Salutation: parentConMap.get(l.Associated_Contact__c).Salutation;
                        l.FirstName = (isInsertTrigger && l.FirstName != null) ? l.FirstName: parentConMap.get(l.Associated_Contact__c).FirstName;
                        l.LastName = (isInsertTrigger && l.LastName != null) ? l.LastName: parentConMap.get(l.Associated_Contact__c).LastName;
                        l.Email = (isInsertTrigger && l.Email != null) ? l.Email: parentConMap.get(l.Associated_Contact__c).Email;
                        l.Associated_Account__c = (isInsertTrigger && l.Associated_Account__c != null) ? l.Associated_Account__c: parentConMap.get(l.Associated_Contact__c).AccountId;
                        l.Title = (isInsertTrigger && l.Title != null) ? l.Title: parentConMap.get(l.Associated_Contact__c).Title;
                        l.Phone = (isInsertTrigger && l.Phone != null) ? l.Phone: parentConMap.get(l.Associated_Contact__c).Phone;
                        l.MobilePhone = (isInsertTrigger && l.MobilePhone != null) ? l.MobilePhone: parentConMap.get(l.Associated_Contact__c).MobilePhone;
                        l.LeadSource = (isInsertTrigger && l.LeadSource != null) ? l.LeadSource: parentConMap.get(l.Associated_Contact__c).LeadSource;
                        l.Contact_Qualifying_Question_1__c = (isInsertTrigger && l.Contact_Qualifying_Question_1__c != null) ? l.Contact_Qualifying_Question_1__c: parentConMap.get(l.Associated_Contact__c).Qualifying_Question_1__c;
                        l.Contact_Qualifying_Question_2__c = (isInsertTrigger && l.Contact_Qualifying_Question_2__c != null) ? l.Contact_Qualifying_Question_2__c: parentConMap.get(l.Associated_Contact__c).Qualifying_Question_2__c;
                        l.Contact_Qualifying_Question_3__c = (isInsertTrigger && l.Contact_Qualifying_Question_3__c != null) ? l.Contact_Qualifying_Question_3__c: parentConMap.get(l.Associated_Contact__c).Qualifying_Question_3__c;
                        l.Contact_Qualifying_Question_4__c = (isInsertTrigger && l.Contact_Qualifying_Question_4__c != null) ? l.Contact_Qualifying_Question_4__c: parentConMap.get(l.Associated_Contact__c).Qualifying_Question_4__c;               
                        l.Contact_Qualifying_Answer_1__c = (isInsertTrigger && l.Contact_Qualifying_Answer_1__c != null) ? l.Contact_Qualifying_Answer_1__c: parentConMap.get(l.Associated_Contact__c).Qualifying_Answer_1__c;
                        l.Contact_Qualifying_Answer_2__c = (isInsertTrigger && l.Contact_Qualifying_Answer_2__c != null) ? l.Contact_Qualifying_Answer_2__c: parentConMap.get(l.Associated_Contact__c).Qualifying_Answer_2__c;
                        l.Contact_Qualifying_Answer_3__c = (isInsertTrigger && l.Contact_Qualifying_Answer_3__c != null) ? l.Contact_Qualifying_Answer_3__c: parentConMap.get(l.Associated_Contact__c).Qualifying_Answer_3__c;
                        l.Contact_Qualifying_Answer_4__c = (isInsertTrigger && l.Contact_Qualifying_Answer_4__c != null) ? l.Contact_Qualifying_Answer_4__c: parentConMap.get(l.Associated_Contact__c).Qualifying_Answer_4__c;  
                    }
                } else  if(l.Parent_Lead__c!=null && parentLeadMap != null){
                url+=l.Parent_Lead__c+'"'+'target="_self" >' + parentLeadMap.get(l.Parent_Lead__c).name + '</a>';
                l.Person_Email__c = parentLeadMap.get(l.Parent_Lead__c).Email;
                l.Person_Mobile__c = parentLeadMap.get(l.Parent_Lead__c).MobilePhone;
                l.Person_Phone__c = parentLeadMap.get(l.Parent_Lead__c).Phone;
                l.Person_Title__c = parentLeadMap.get(l.Parent_Lead__c).Title;
                l.Person_City__c = parentLeadMap.get(l.Parent_Lead__c).City;
                l.Person_Country__c = parentLeadMap.get(l.Parent_Lead__c).country;
                l.Person_State_Province__c = parentLeadMap.get(l.Parent_Lead__c).State;
                if (isInsertTrigger && parentLeadMap.get(l.Parent_Lead__c).Associated_Account__r.LBI__NumberOfOpenInProgressRecommendations__c > 0) {
                    l.Has_BIS__c = true;
                }
            }
            l.Person_Record__c = url;
            if(!l.Validation_Override__c && !l.Is_Partner_Lead__c && !GsmUtilClass.getGSMSettingValue('SystemAdminProfileId').contains(UserInfo.getProfileId()) && String.isBlank(l.Person_Email__c) && l.Person_Phone__c==null)
                l.addError('Both Phone and Email is blank for Associated Person. Please provide a value.');

        }
        system.debug(LoggingLevel.ERROR,'leadToPopulatePersonFields: leadList: '+leadList);
        //populatePersonFieldsFRFlag = false;
    }

    //Created by Nagaraj G, MARIT-214, revamped as aprt of MARIT-448
    // MARIT-487 Adding Map Code for Optimization
    public static Map<String,Lead> updateC2ALeadFromMarketoLead(Set<Id> updatedMarketoLeads,Map<Id,Lead> oldLeadMap,Map<Id,Lead> newLeadMap, Map<String,Lead> leadMap){	
        List<Lead> leadsToUpdate = new List<Lead>();
        Boolean toUpdate = false;
        
        List<String> marketoC2ASyncFields = MarketingUtilClass.getMarketingSettingValuePartialMatch('marketoC2ASyncFields');
        marketoC2ASyncFields = String.join(marketoC2ASyncFields,',').split('\\s*,\\s*');
        
        String query = 'SELECT Id,Parent_Lead__c,' + String.join(marketoC2ASyncFields,',') + ' FROM Lead WHERE Parent_Lead__c in :updatedMarketoLeads';
        List<Lead> CTAList = Database.query(query);
        
        for(Lead l1: CTAList){
            //Copy over data
            for(String leadField : marketoC2ASyncFields){
                if(l1.get(leadField) != newLeadMap.get(l1.Parent_Lead__c).get(leadField) &&
                  	newLeadMap.get(l1.Parent_Lead__c).get(leadField) != oldLeadMap.get(l1.Parent_Lead__c).get(leadField)){
                    l1.put(leadField,newLeadMap.get(l1.Parent_Lead__c).get(leadField));
                    toUpdate = true;
                }
            }
            if(toUpdate){
                leadsToUpdate.add(l1);
                toUpdate = false;
            }
        }

        if(leadsToUpdate != null && !leadsToUpdate.isEmpty()){
            //update leadsToUpdate;
            leadMap = (Map<String,Lead>)MarketingUtilClass.mergeUpdates(leadMap,leadsToUpdate);
        }
        return leadMap;
    }

/*
    If acct_country is 'USA'
    BillingCountry  BillingState    Vertical__c     Sub_Vertical__c     Projected_Sales_Owner__c
    USA             md              Video Media     asdf

    Country__c  Region_or_State__c  Vertical__c     Sub_Vertical__c     SDR_Name__c
    USA         <All>               <All>           <All>               AAAAAA
    USA         md                  Video Media     asdf                XXXXXX
    USA         md                  <All>           <All>               YYYYYY
    USA         la                  <All>           <All>               ZZZZZZ

    Here, account should be matched to
    USA         <All>               <All>           <All>               AAAAAA
    and not
    USA         md                  Video Media     asdf                XXXXXX
*/
    public static List<Account> populateProjectedSalesOwner(List<Account> accList)
    {
        List<String> vertical = new List<String>();
        List<String> subVertical = new List<String>();
        List<String> verticalexcl = new List<String>();
        List<String> subVerticalexcl = new List<String>();
        List<String> countries = new List<String>();
        List<String> countriesexcl = new List<String>();
        List<String> state = new List<String>();
        List<String> stateCode = new List<String>();
        List<String> accOwnerList = new List<String>(); //MARIT-427
        List<String> accOwnerListexcl = new List<String>();
        Map<String, Account> ownerToAccMap = new Map<String, Account>();//MARIT-427
        List<Account> accList1 = new List<Account>();
        List<Account> accListexcl = new List<Account>();
        
        List<String> countriesForStateInclusion = MarketingUtilClass.getMarketingSettingsValue('DRACountriesForState').split(',');
        List<Account> finalAccountSet = new List<Account>();
        for(Account acc: accList)
        {   
            String str = null;
            if (countriesForStateInclusion.contains(acc.BillingCountry)){
                vertical.add(acc.Vertical__c);
                subVertical.add(acc.Sub_Vertical__c);
                countries.add(acc.BillingCountry);
                state.add(acc.BillingState);
                accOwnerList.add(acc.OwnerId); //MARIT-427
                ownerToAccMap.put(acc.OwnerId, acc);
                accList1.add(acc);
            } else {
                verticalexcl.add(acc.Vertical__c);
                subVerticalexcl.add(acc.Sub_Vertical__c);
                countriesexcl.add(acc.BillingCountry);
                accOwnerListexcl.add(acc.OwnerId);
                accListexcl.add(acc);
            }
        }
        String draSubprocessconfigLastModifiedDate = MarketingUtilClass.getMarketingSettingsValue('draSubprocessconfigLastModifiedDate');
        if(accOwnerList.size()>0) {
            String initialQuery = 'Select Country__c, Region_or_State__c, SDR_Name__c, SDR_Name__r.isActive, Projected_SDR__c, Sub_Vertical__c, Vertical__c, Exclude_from_Projected_Sales_Mapping__c from DRASubprocessConfig__c where (Vertical__c in :vertical and Country__c in :countries and Sub_Vertical__c in :subVertical and SDR_Name__c!=null and SDR_Name__r.isActive=true and Region_or_State__c in :state and Exclude_from_Projected_Sales_Mapping__c=false ';
            finalAccountSet.addAll(updatePSO(initialQuery,accList1,vertical,subVertical,countries,state,accOwnerList,draSubprocessconfigLastModifiedDate, true));
        }
        if(accOwnerListexcl.size() > 0) {
            String initialQuery = 'Select Country__c, SDR_Name__c, SDR_Name__r.isActive, Projected_SDR__c, Sub_Vertical__c, Vertical__c, Exclude_from_Projected_Sales_Mapping__c from DRASubprocessConfig__c where (Vertical__c in :vertical and Country__c in :countries and Sub_Vertical__c in :subVertical and SDR_Name__c!=null and SDR_Name__r.isActive=true and Exclude_from_Projected_Sales_Mapping__c=false ';
        	finalAccountSet.addAll(updatePSO(initialQuery,accListexcl,verticalexcl,subVerticalexcl,countriesexcl,null,accOwnerListexcl,draSubprocessconfigLastModifiedDate, false));
        }
        return finalAccountSet;
    }
    public static List<Account> updatePSO(String initialQuery,List<Account> accList,List<String> vertical,List<String> subVertical,List<String> countries, List<String> state, List<String> accOwnerList, String draSubprocessconfigLastModifiedDate, boolean includeState){
        vertical.add('<All>');
        subVertical.add('<All>');
        if(includeState) {
        	state.add('<All>');
        }
        DateTime draLastModifiedDate = DateTime.valueOf(draSubprocessconfigLastModifiedDate);
		String draSubProcessConfigQuery = getDRAQuery(initialQuery, draSubprocessconfigLastModifiedDate, draLastModifiedDate);
       
        List<DRASubprocessConfig__c> configList = Database.query(draSubProcessConfigQuery);
        List<Account> accListToBeUpdate = new List<Account>();

        if(configList != null && !configList.isEmpty())
        {  
            for(Account acc: accList)
            {
                for(DRASubprocessConfig__c config: configList)
                {
                    if(config.SDR_Name__c==acc.OwnerId && config.Exclude_from_Projected_Sales_Mapping__c){//ownerToAccMap.containsKey(config.SDR_Name__c)
                        Account a = updatePSO_ProjectedSDR(acc,config);
                        accListToBeUpdate.add(a);
                        break;
                    }
                    else if(!config.Exclude_from_Projected_Sales_Mapping__c){
                        if(acc.BillingCountry == config.Country__c){
                            if(includeState && config.Region_or_State__c=='<All>'){
                                Account a = updatePSO_ProjectedSDR(acc,config);
                                accListToBeUpdate.add(a);
                                break;
                            }
                            else if(!includeState || (acc.BillingState == null || ((acc.BillingState != null) && acc.BillingState == config.Region_or_State__c))){
                                if(config.Vertical__c=='<All>'){  
                                    Account a = updatePSO_ProjectedSDR(acc,config);
                                    accListToBeUpdate.add(a);
                                    break;
                                }
                                else if(acc.Vertical__c == config.Vertical__c){
                                    if(config.Sub_Vertical__c=='<All>'){
                                        Account a = updatePSO_ProjectedSDR(acc,config);
                                        accListToBeUpdate.add(a);
                                        break;
                                    }
                                    else if(acc.Sub_Vertical__c == config.Sub_Vertical__c){
                                    	Account a = updatePSO_ProjectedSDR(acc,config);
                                        accListToBeUpdate.add(a);
                                        break;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        return accListToBeUpdate;
    }
    public static Account updatePSO_ProjectedSDR(Account acc, DRASubprocessConfig__c config){
        if(acc.Projected_Sales_Owner__c != config.SDR_Name__c && ONAPoolOpsIdList.contains(acc.OwnerId))
            acc.Projected_Sales_Owner__c = config.SDR_Name__c;
        if(acc.Projected_SDR__c != config.Projected_SDR__c)
            acc.Projected_SDR__c = config.Projected_SDR__c;
        return acc;
    }
    
    public static String getDRAQuery(String initialQuery, String draSubprocessconfigLastModifiedDate, DateTime draLastModifiedDate) {
         if(draSubprocessconfigLastModifiedDate != null){
            initialQuery += ' and LastModifiedDate > :draLastModifiedDate';
        }
        initialQuery += ') OR (SDR_Name__c in :accOwnerList and Exclude_from_Projected_Sales_Mapping__c=true ';
        if(draSubprocessconfigLastModifiedDate != null){
            initialQuery += ' and LastModifiedDate > :draLastModifiedDate';
        }
        initialQuery += ')';
        initialQuery += ' order by LastModifiedDate DESC';
        return initialQuery;
    }
    //MARIT-681, 1013 added value for Lead qualification status field value
    public static Map<String,Lead> closeCTAWithOpenOppt(Set<Id> openOpptContactIds,Map<String,Lead> leadMap){
        List<Lead> leadsToUpdate = new List<Lead>();
        String soql;
        if(!openOpptContactIds.isEmpty()){
            soql = 'Select Id,Name,Status,Associated_Contact__c from Lead where Associated_Contact__c in ';
            soql+=MarketingUtilClass.parseIdsForDynamicQuery(new List<Id>(openOpptContactIds));
            soql+=' and (Status = \'New\' OR Status = \'In Process\') and (recordtype.name = \'Akamai Lead\')';
            System.debug('SOQL='+soql);
            for(Lead l : (List <Lead>)MarketingUtilClass.fetchFromDataBase(soql)){
                l.Reason_For_Closure__c = 'Closed because Person has Open Opportunity';
                l.Status = 'Closed';  //close CTA whose associated contact has open oppt
                l.Lead_Qualification_Status__c = 'Person Added to Opportunity';
                leadsToUpdate.add(l);
            }
        }
        if(!leadsToUpdate.isEmpty()){
            leadMap = (Map<String,Lead>)MarketingUtilClass.mergeUpdates(leadMap,leadsToUpdate);     
        }
        return leadMap;
    }

    //MARIT-875
    public static void updateProspectCtaStageStatus(Map<Id,Lead> parentContact,Map<Id,Lead> parentLead){
        String soqlc,soqll;
        if(parentContact != null && !parentContact.isEmpty()){
            soqlc='Select Id,Lead_Qualification_Stage__c,Lead_Qualification_Status__c from Contact where Id in ';
            soqlc+=MarketingUtilClass.parseIdsForDynamicQuery(new List<Id>(parentContact.keySet()));
            system.debug('query result: '+ soqlc);
            for(Contact c :(List <Contact>)MarketingUtilClass.fetchFromDataBase(soqlc))
            {
                Lead l = parentContact.get(c.Id);
                l.Lead_Qualification_Stage__c = c.Lead_Qualification_Stage__c;
                l.Lead_Qualification_Status__c = c.Lead_Qualification_Status__c;
            }
        }
        if(parentLead != null && !parentLead.isEmpty()){
            soqll = 'Select Id, Lead_Qualification_Stage__c, Lead_Qualification_Status__c from Lead where Id in ';
            soqll+=MarketingUtilClass.parseIdsForDynamicQuery(new List<Id>(parentLead.keySet()));
            soqll+=' and (Status = \'New\' OR Status = \'In Process\')';
            System.debug('query result lead: '+ soqll);
            for(Lead ml:(List <Lead>)MarketingUtilClass.fetchFromDataBase(soqll))
            {
                Lead l = parentLead.get(ml.Id);
                l.Lead_Qualification_Stage__c = ml.Lead_Qualification_Stage__c;
                l.Lead_Qualification_Status__c = ml.Lead_Qualification_Status__c;
            }
        }
    }

    //MARIT-773
    public static void playbooksFieldsCopyOverWhenLeadIsConverted(List<Lead> ctaToBeConvertedOrClosed){
        List<Contact> updateContactList = new List<Contact>();
        List<Lead> updateMarketoLeadList = new List<Lead>();
        for(Lead l: ctaToBeConvertedOrClosed){
                        if(l.Associated_Contact__c != null){
                            Contact con = new Contact(id=l.Associated_Contact__c);
                            con.Playbooks_Step_Number__c = l.Playbooks_Step_Number__c;
                            updateContactList.add(con);
                        }
                        else if(l.Parent_Lead__c != null){
                            Lead parentLead = new Lead(id=l.Parent_Lead__c);
                            parentLead.Playbooks_Step_Number__c = l.Playbooks_Step_Number__c;
                            updateMarketoLeadList.add(parentLead);
                        }
                    }
        if(Schema.sObjectType.Contact.fields.Playbooks_Step_Number__c.isUpdateable() && (updateContactList != null && !updateContactList.isEmpty()))
        {
            update updateContactList;
        }
        if(Schema.sObjectType.Lead.fields.Playbooks_Step_Number__c.isUpdateable() && (updateMarketoLeadList != null && !updateMarketoLeadList.isEmpty()))
        {
            update updateMarketoLeadList;
        }
    }
    //MARIT-566 upsert on Leads should run in system context
    public static void upsertLeads(List<Lead> leadList){
        upsert leadList;
    }

    //MARIT-566 update on Leads should run in system context
    public static void updateLeads(List<Lead> leadList){
        update leadList;
    }
}