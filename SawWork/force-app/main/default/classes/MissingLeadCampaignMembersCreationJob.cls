/* History:
 * =========================
 * @author  Shiva Ganesan,  24th April 2018  
 SFDC-2596 
 */
global class MissingLeadCampaignMembersCreationJob implements Database.Batchable<sObject>, Database.Stateful 
{
	
	global final string query;
    global DMLResults results;
    global List<String> leadStatusToBeIgnored;
    global List<String> leadRecordTypeNameToBeConsidered;
    global Datetime lastDateToFetchC2A;
    global Integer lastDate;
    global List<String> cmStatusToBeIgnored;
    global List<String> daysbetween;
    global integer lastC2aTobeConsideredDate;
	
	global MissingLeadCampaignMembersCreationJob() 
	{
        lastDate = Integer.valueOf(MarketingUtilClass.getMarketingSettingsValue('CampaignMemberLastDate'));
        cmStatusToBeIgnored = MarketingUtilClass.getMarketingSettingsValue('RobotCampaignMemberStatusToBeIgnored').split(',');
		leadRecordTypeNameToBeConsidered= MarketingUtilClass.getMarketingSettingsValue('LeadRecordTypeNameToBeConsidered').split(',');
        lastC2aTobeConsideredDate = integer.valueof(MarketingUtilClass.getMarketingSettingsValue('C2ADateToBeConsidered'));
        daysbetween = MarketingUtilClass.getMarketingSettingsValue('CampMemberAndC2ADaysBetween').split(',');
        
        lastDateToFetchC2A = DateTime.Now().AddDays(lastC2aTobeConsideredDate);

		leadStatusToBeIgnored = GSMUtilClass.getGSMSettingValue('LeadStatusToBeIgnoredCMCreation').split(',');
		//leadCMCreationCheckStartTime = DateTime.valueOf(GSMUtilClass.getGSMSettingValue('LeadCMCreationCheckStartTime'));//Agility go live date
		//SFDC-3052 Added Conversion_Campaign_ID__c field in query
		query = 'select Id,Associated_Contact__r.Id,CreatedDate,Conversion_Campaign_ID__c,Parent_Lead__c,Associated_Opportunity__c, Primary_Campaign__c from Lead where Primary_Campaign__c = \'\' and Status not in :leadStatusToBeIgnored and RecordType.Name in :leadRecordTypeNameToBeConsidered and CreatedDate > :lastDateToFetchC2A';
	}
	
	global Database.QueryLocator start(Database.BatchableContext BC) 
	{
		results= new DMLResults(); 
        results.storeObjectState();

		return Database.getQueryLocator(query);
	}

   	global void execute(Database.BatchableContext BC, List<sObject> scope) 
   	{
		List<Lead> leadList = (List<Lead>)scope;
		//SFDC-3052
		Map<Id,String> leadIdToCampaignAkamId = new Map<Id,String>();
		Map<Id,Id> leadIdToCampaignId = new Map<Id,Id>();
		Set<CampaignMember> cmsToBeInserted = new Set<CampaignMember>();
		List<Id> personIds = new List<Id>();
        Map<Id, Id> C2AToPersonIdCampaignMember = new Map<Id, Id>();
        Map<Id, Id> parentLeadToC2ALead = new Map<Id, Id>();
        Map<Id, Id> parentContactToC2ALead = new Map<Id, Id>();
      	Map<Id, CampaignMember> personIdToCampaignId = new Map<Id, CampaignMember>();
        Map<Id, String> akamaiLeadToLatestCampaignAkamId = new Map<Id, String>();
        Map<String, Id> LatestCampAkamIdToC2A = new Map<String, Id>();
        Map<Id,Id> C2AleadIdToCampaignId = new Map<Id,Id>();
        Map<Id,Id> AssociatedOptyToC2A = new Map<Id,Id>(); 
        Map<Opportunity,Id> optyToCampId = new Map<Opportunity,Id>();
        List<Opportunity> optys;
        List<Opportunity> opptyUpdateList = new List<Opportunity>();
        List<Lead> C2AWithPrimaryCampaignUpdateList = new List<Lead>();
        Map<Id,Id> optyIdToCampaignIdViaCampaignMember = new Map<Id,Id>();
        CampaignMember cmrec;

        // We need to check if the Parent lead associated with the C2A has a latest Campaign Akam Id. 
        // If it has then we will pick the Campaign Id from Campaign and assign it to the C2A Primary campaign id 
		for (Lead eachLead : leadList) {
			if (eachLead.Parent_Lead__c != null) {
                if (eachLead.Associated_Contact__c != null) {
                	personIds.add(eachLead.Associated_Contact__c);
                    C2AToPersonIdCampaignMember.put(eachLead.Id, eachLead.Associated_Contact__c);
                } else {
                    personIds.add(eachLead.Parent_Lead__c);
                    C2AToPersonIdCampaignMember.put(eachLead.Id, eachLead.Parent_Lead__c);
                }
				// MARIT-269
                parentLeadToC2ALead.put(eachLead.Parent_Lead__c, eachLead.Id);
            } else if (eachLead.Associated_Contact__c != null) {
                personIds.add(eachLead.Associated_Contact__c);
                C2AToPersonIdCampaignMember.put(eachLead.Id, eachLead.Associated_Contact__c);
            }
            // MARIT-319 : if there is a parent contact we should consider its latest campaign Id first
            if (eachLead.Associated_Contact__c != null) {
            	parentContactToC2ALead.put(eachLead.Associated_Contact__c, eachLead.Id);
            }

			if(eachLead.Conversion_Campaign_ID__c != null)
				leadIdToCampaignAkamId.put(eachLead.Id, eachLead.Conversion_Campaign_ID__c);
            
            // Get the asscoiated oopportunity for it to be updated with primary campaign later.
            if (eachLead.Associated_Opportunity__c != null) {
                AssociatedOptyToC2A.put(eachlead.Associated_Opportunity__c, eachlead.Id);
            }
		}
        
		//MARIT-269
        // 1.  Get the latest campaign Akam ids from parent leads for their respective C2As.
        // We will first retrieve the Parent Leads list for the respective C2As provided and then fetch their latest campaign Id if exists.
        List<Lead> parentLeads = [Select Id, Latest_Campaign_AKAM_ID__c from Lead where Latest_Campaign_AKAM_ID__c != null and Id in :parentLeadToC2ALead.keySet()];
        for (Lead l: parentLeads) {          
            LatestCampAkamIdToC2A.put(l.Latest_Campaign_AKAM_ID__c, parentLeadToC2ALead.get(l.id));         
        }
		// 1.b. Get the latest campaign ids from parent contacts for their respective C2As.
        List<Contact> parentContacts = [Select Id, Latest_Campaign_Id__c from Contact where Latest_Campaign_Id__c != null and Id in :parentContactToC2ALead.keySet()];
        for(Contact con: parentContacts) {
            C2AleadIdToCampaignId.put(parentContactToC2ALead.get(con.Id), con.Latest_Campaign_Id__c);
        }
        
        // 2. Once we have the Latest campaign Akam field, we will query the Campaign object to retrieve the corresponding campaign Id 
        // We will maintain it in the Map C2A to Campaign Id.
        // If the campaign Id is already present in the map corresponding to C2A then we will not consider it  as it is covered in 1.b step
		if (LatestCampAkamIdToC2A.size() > 0) {
			List<Campaign> campList = [Select Id, AKAM_Campaign_ID__c from Campaign where AKAM_Campaign_ID__c in :LatestCampAkamIdToC2A.keySet()];
			Id c2aId = null;
            for (Campaign camp: campList) {
                c2aId = LatestCampAkamIdToC2A.get(camp.AKAM_Campaign_ID__c);
				if (c2aId != null && !C2AleadIdToCampaignId.ContainsKey(c2aId)) {
                	C2AleadIdToCampaignId.put(LatestCampAkamIdToC2A.get(camp.AKAM_Campaign_ID__c), camp.Id);
				}
            }
        }
        
		//SFDC-3052
		if (leadIdToCampaignAkamId.size() > 0) {
			List<Campaign> campList = [Select Id, AKAM_Campaign_ID__c from Campaign where AKAM_Campaign_ID__c in :leadIdToCampaignAkamId.values()];

			for (Campaign camp: campList) {
				for (Id leadId: leadIdToCampaignAkamId.keySet()) {
					if (leadIdToCampaignAkamId.get(LeadId) == camp.AKAM_Campaign_ID__c) {
						leadIdToCampaignId.put(LeadId, camp.Id);
						leadIdToCampaignAkamId.remove(LeadId);
					}
				}
			}
		}

		if (personIds.size() > 0 ) {
            // MARIT-539
	        Datetime windowStart = DateTime.Now().AddDays(lastDate);
            String windowStartString = MarketingUtilClass.parseDateTimeForDynamicQuery(windowStart);
            string personIdsString = MarketingUtilClass.parseIdsForDynamicQuery(personIds);
            string cmStatusToBeIgnoredString = MarketingUtilClass.parseStringsForDynamicQuery(cmStatusToBeIgnored);
            string campaignMemberQuery = 'select leadid,ContactId,CampaignId,LeadOrContactId, Status, CreatedDate from CampaignMember where LeadOrContactId in '+ personIdsString + ' and status not in ' + cmStatusToBeIgnoredString + ' and CreatedDate >= ' + windowStartString + ' order by CreatedDate DESC LIMIT 10000';
			//List<CampaignMember> campaignMembers = [select leadid,ContactId,CampaignId,LeadOrContactId, Status, CreatedDate from CampaignMember where LeadOrContactId in :personIds and status not in :cmStatusToBeIgnored and CreatedDate>=:windowStart order by CreatedDate DESC];
            List<CampaignMember> campaignMembers = MarketingUtilClass.fetchFromDataBase(campaignMemberQuery);
            for (CampaignMember memb: campaignMembers) {
                if (!personIdToCampaignId.containsKey(memb.LeadOrContactId)) {
                    personIdToCampaignId.put(memb.LeadOrContactId, memb);
                }
	        }
		}
        

        // MARIT-356, For each C2A record, we will not create a campaign member rather we will directly add primary campaign to it
        for (Lead ithLead: leadList) {
            Boolean leadHasChanges=false;
        	//Id personId = (ithLead.Parent_Lead__c != null) ? ithLead.Parent_Lead__c : (ithLead.Associated_Contact__c != null ? ithLead.Associated_Contact__c : null);            
            Id personId = C2AToPersonIdCampaignMember.get(ithLead.Id);
            
            // If Parent lead has latest campaign Akam Id, populate the campaign Id using that else proceed with existing logic.
			// MARIT-269
            if (C2AleadIdToCampaignId != null && C2AleadIdToCampaignId.containsKey(ithLead.Id)) {
                ithLead.Primary_Campaign__c = C2AleadIdToCampaignId.get(ithLead.Id);
                leadHasChanges=true;
			}
        	else if (leadIdToCampaignId != null && leadIdToCampaignId.containsKey(ithLead.Id)) {
                ithLead.Primary_Campaign__c = leadIdToCampaignId.get(ithLead.Id);
                leadHasChanges=true;
			}
			else if (personId != null && personIdToCampaignId.containsKey(personId)) {
                cmrec = personIdToCampaignId.get(personId);
                Integer daysBetweenCMAndC2A = cmrec.CreatedDate.Date().daysBetween(ithLead.CreatedDate.Date());
                if (daysBetweenCMAndC2A <= Integer.valueOf(daysbetween[0]) && daysBetweenCMAndC2A >= Integer.valueOf(daysbetween[1])) {
                    ithLead.Primary_Campaign__c = cmrec.CampaignId;
                    leadHasChanges=true;
                    if (ithLead.Associated_Opportunity__c != null) {
                        optyIdToCampaignIdViaCampaignMember.put(ithLead.Associated_Opportunity__c, cmrec.CampaignId);
                    }
                }
			}
            
			if (leadHasChanges){
                ithLead.Validation_Override__c = true;
				C2AWithPrimaryCampaignUpdateList.add(ithLead);
			}
           
        }
        
        optys = [Select Id, CampaignId, StageName from Opportunity where Id in :AssociatedOptyToC2A.keySet()];

        for (Opportunity opty : optys ) {
			if (AssociatedOptyToC2A.containsKey(opty.Id)) {
                if (!optyToCampId.containsKey(opty) && C2AleadIdToCampaignId.containsKey(AssociatedOptyToC2A.get(opty.Id))) {
                    optyToCampId.put(opty, C2AleadIdToCampaignId.get(AssociatedOptyToC2A.get(opty.Id)));
                } else if (!optyToCampId.containsKey(opty) && optyIdToCampaignIdViaCampaignMember.containsKey(opty.Id)) {
                    optyToCampId.put(opty, optyIdToCampaignIdViaCampaignMember.get(opty.Id));
                }
			}
		}
        for (Opportunity oppty : optyToCampId.keySet()) {
            if (optyToCampId.get(oppty) != null) {
                oppty.CampaignId = optyToCampId.get(oppty);
                opptyUpdateList.add(oppty);
            }
        }

        if (C2AWithPrimaryCampaignUpdateList.size() > 0) {
            List<Lead> c2aLeadList = new List<Lead>();
            c2aLeadList.addAll(C2AWithPrimaryCampaignUpdateList);
			results.add(Database.update(c2aLeadList,false),c2aLeadList);
		}
        
		// MARIT-269
        if (opptyUpdateList.size() > 0) {
            List<Opportunity> optyList = new List<Opportunity>();
            optyList.addAll(opptyUpdateList);
            results.add(Database.update(optyList, false), optyList);
        }
	}
	
	global void finish(Database.BatchableContext BC) 
	{
		results.withClassName('MissingLeadCampaignMembersCreationJob').insertRecordsInErrorLog();
	}
}