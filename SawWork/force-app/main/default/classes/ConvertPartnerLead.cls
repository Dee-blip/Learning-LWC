public class ConvertPartnerLead {
	/**Begin Rajesh Kumar JIRA # SFDC-6406 */
	private static string sourceName = null;
	private static final Id partnerConvertRecordypeId = Schema.SObjectType.Lead.getRecordTypeInfosByDeveloperName().get('Converted_Lead').getRecordTypeId();
	private static final Integer fieldLength = Error_Log__C.Error_Message__c.getDescribe().getLength();
	/**End Rajesh Kumar JIRA # SFDC-6406 */
	/**Begin Rajesh Kumar JIRA #SFDC-6464 */
	public String leadrecordId {get;set;}
	/**End Rajesh Kumar JIRA #SFDC-6464 */
	private final Lead l;
	public ConvertPartnerLead(ApexPages.StandardController stdController) {
		this.l = (Lead) stdController.getRecord();
		/**Begin Rajesh Kumar JIRA #SFDC-6464 */
		leadrecordId = l.Id;
		/**End Rajesh Kumar JIRA #SFDC-6464 */
	}
	public PageReference Back() {
		PageReference pageRef = new PageReference('/' + l.id);
		return pageRef;
	}
	public PageReference NavigateToDealReg() {
		Lead leadRec = getleadRecord(l.id);
		PageReference pageRef = new PageReference('/' + leadRec.Associated_Opportunity__c);
		return pageRef;
	}
	public PageReference convert() {
		String leadId = ApexPages.currentPage().getParameters().get('id');
		Lead l = getLeadRecord(leadId);
		if (l.status == 'Converted') {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, GSMUtilClass.getNAPSettingValue('PartnerLeadAlreadyConvertedError')));
			return null;
		}
		if (l.Primary_Product__c == null || l.End_Customer_Contact_Role__c == null || l.Services_Hostname__c == null || l.LeadSource == null) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, GSMUtilClass.getNAPSettingValue('PartnerLeadConvertValidationMessage')));
			return null;
		}
		/* Only Users with Deal Reg permissions can convert a lead.
		 * Check if the logged in user has Deal Reg permission set assigned
		 * If not, throw validation to the user
		 */
		Boolean hasDealRegPermission = checkDealRegPermission();
		if (!hasDealRegPermission) {
			ApexPages.addmessage(new ApexPages.message(ApexPages.severity.ERROR, GSMUtilClass.getNAPSettingValue('PartnerLeadNoDealRegPermission')));
			return null;
		}
		Opportunity opp = convertPartnerLead(l);
		PageReference pageRef = new PageReference('/' + opp.id);
		pageRef.setRedirect(true);
		return pageRef;

	}
	public static Opportunity convertPartnerLead(Lead l) {
		List<Lead> leadList = new List<Lead> ();
		leadList.add(l);
		List<Opportunity> dealRegList = convertPartnerLead(leadList);
		return dealRegList[0];
	}
	public static List<Opportunity> convertPartnerLead(List<Lead> leadsToConvertList) {
		List<Opportunity> dealRegCreated = new List<Opportunity> ();
		List<Lead> partnerLeadsToConvert = new List<Lead> ();
		Id partnerRecordypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Partner Lead').getRecordTypeId();
		System.debug('Partner record type id:' + partnerRecordypeId);
		if (leadsToConvertList != null && leadsToConvertList.size() > 0) {
			for (lead l: leadsToConvertList) {
				if (l.recordTypeId == partnerRecordypeId) {
					partnerLeadsToConvert.add(l);
				}
			}
		}
		if (partnerLeadsToConvert.size() > 0) {
			dealRegCreated = createDealRegsForLeads(partnerLeadsToConvert);
		}
		return dealRegCreated;
	}

	public static List<Opportunity> createDealRegsForLeads(List<Lead> partnerLeads) {
		Boolean insertError = false;
		Id dealRegUnsubmittedReqId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Deal Reg Unsubmitted').getRecordTypeId();
		//Id partnerConvertRecordypeId = Schema.SObjectType.Lead.getRecordTypeInfosByName().get('Converted Lead').getRecordTypeId(); //commented by rajesh SFDC-6406
		List<Opportunity> createdDealRegs = new List<Opportunity> ();
		Id userId = UserInfo.getUserId();
		User user = [Select id, Contact.AccountId From User where id =: userId];
		List<Lead> leadsToUpdate = new List<Lead> ();
		for (Lead l: partnerLeads) {
			Opportunity o = new Opportunity();
			o.OwnerId = UserInfo.getUserId();
			o.Name = l.name + ' ' + l.Company;
			o.Partner_Involved__c = user.Contact.AccountId;
			o.StageName = GSMUtilClass.getNAPSettingValue('PartnerLeadCreationStage');
			o.CloseDate = System.today().addDays(30);
			o.CurrencyIsoCode = l.CurrencyIsoCode;
			o.Customer_Contact_First_Name__c = l.FirstName;
			o.End_Customer_Contact_Last_Name__c = l.LastName;
			o.Contact_Title__c = l.Title;
			o.End_Customer_Website__c = l.Website;
			o.Customer_Company_Name__c = l.Company;
			o.End_Customer_Street_Address__c = l.Street;
			o.End_Customer_City__c = l.City;
			o.End_Customer_State__c = l.State;
			o.End_Customer_Zip_Code__c = l.PostalCode;
			o.End_Customer_Country_Picklist__c = l.Country;
			o.Deal_Reg_Lead_Source__c = 'Partner Developed';
			o.Deal_Reg_Deal_Confirmation__c = 'Yes';
			o.DR_Campaign__c = 'NA';
			o.Primary_Product__c = l.Primary_Product__c;
			o.Services_Hostname__c = l.Services_Hostname__c;
			o.Associated_Partner_Lead__c = l.id;
			o.Deal_Reg_Contact_Role__c = l.End_Customer_Contact_Role__c;
			o.Partner_Marketing_Activity__c = l.Partner_Marketing_Activity__c;
			createdDealRegs.add(o);
		}
		/**Begin Rajesh Kumar JIRA # SFDC-6406 */
		if (sourceName == 'flow') {
			return createdDealRegs;
		}
		/**End Rajesh Kumar JIRA # SFDC-6406 */
		List<Id> successfulDealRegs = new List<Id> ();
		List<Error_log__c > errorList = new List<Error_log__c > ();
		List<Lead> successfulLeads = new List<Lead> ();
		Database.SaveResult[] srList = Database.insert(createdDealRegs, false);
		// Iterate through each returned result
		for (Database.SaveResult sr: srList) {
			if (sr.isSuccess()) {
				Id oppId = sr.getId();
				successfulDealRegs.add(oppId);
			} else {
				String error = '';
				for (Database.Error err: sr.getErrors()) {
					error += err;
				}
				/**Begin Rajesh Kumar JIRA # SFDC-6406 */ //commented below code and modified below list to have common error instance both for flow and page lead convert
				// Error_log__c errorLog = new Error_log__c();
				// errorLog.Class__c = 'ConvertPartnerLead';
				// errorLog.Error_Message__c = error;
				/**End Rajesh Kumar JIRA # SFDC-6406 */
				errorList.add(errorInstance('LeadConvertError', 'ConvertPartnerLead', error));
			}
		}
		insert errorList;
		for (Opportunity o: [Select id, Associated_Partner_Lead__c From Opportunity
				Where id IN: successfulDealRegs
			]) {
			/**Begin Rajesh Kumar JIRA # SFDC-6406 */ // Commented below code to have common method for lead update both by flow and page
			// lead l = new lead(id = o.Associated_Lead__c,
			// 	status = 'Converted',
			// 	Is_Partner_Lead__c = true,
			// 	validation_override__c = true,
			// 	recordTypeId = partnerConvertRecordypeId,
			// 	Disposition__c = 'Sent To MAE',
			// 	Associated_Opportunity__c = o.id);
			successfulLeads.add(returLeadInstance(o.Associated_Partner_Lead__c, 'Converted', true, true, partnerConvertRecordypeId, 'Sent To MAE', o.id));
			/**End Rajesh Kumar JIRA # SFDC-6406 */
		}
		System.debug(successfulLeads);

		if (successfulLeads.size() > 0) {
			DMLResults upsertResults = new DMLResults();
			upsertResults.add(Database.upsert(successfulLeads, false), successfulLeads);
			upsertResults.withClassName('ConvertPartnerLead').insertRecordsInErrorLog();
		}
		return createdDealRegs;
	}
	public static Lead getleadRecord(Id leadId) {
		return [Select OwnerId,
			Status,
			Name,
			CurrencyIsoCode,
			RecordTypeId,
			FirstName,
			LastName,
			Title,
			Website,
			Company,
			Street,
			City,
			State,
			PostalCode,
			Country,
			LeadSource,
			Primary_Product__c,
			Primary_Campaign__c,
			Services_Hostname__c,
			Partner_Marketing_Activity__c,
			Associated_Opportunity__c,
			End_Customer_Contact_Role__c
			From Lead
			Where id =: leadId
		];
	}
	public static boolean checkDealRegPermission() {
		Set<String> psSet = new Set<String> ();
		psSet.add('Community_Deal_Registration_Only_Access');
		/* SFDC-5908 Only user with Deal Reg access can convert Partner Lead
		psSet.add('Partner_Leads_Only_Access');
		*/
		List<PermissionSetAssignment> psaList = [SELECT PermissionSetId
			FROM PermissionSetAssignment
			WHERE AssigneeId =: UserInfo.getUserId()
			AND PermissionSet.Name IN: psSet
		];
		if (psaList.size() > 0)
			return true;
		else
			return false;
	}
	/**Begin Rajesh Kumar JIRA # SFDC-6406 */ //Added below method to convert lead/FCM Update from DR flow
	@InvocableMethod(label = 'DR Lead Convert/FCM update'
		description = 'Invocable Method used for Lead Convert/FCM Update')
	public static List<Opportunity> convertpartnerflowLead(List<L2Q_FlowInputParam > request) {
		List<Opportunity> returnResult = new List<Opportunity> ();
		List<Lead> dealregLead = new List<Lead> ();
		try {
			System.debug('request>>' + request);
			sourceName = request[0].source;
			if (request[0].actionName == 'fcmupdate') {
				updateopptyFcm(request[0].opportunityId, request[0].fcmId);
				return returnResult;
			}
			dealregLead.add(getleadRecord(request[0].record.Id));
			returnResult = createDealRegsForLeads(dealregLead);
			insert returnResult;
			update returLeadInstance(returnResult[0].Associated_Partner_Lead__c, 'Converted', true, true, partnerConvertRecordypeId, 'Sent To MAE', returnResult[0].id);
		} catch (Exception ex) {
			String error = ex.getMessage() + '#;' + ex.getStackTraceString();
			error = (error.length() > fieldLength) ? error.substring(1, fieldLength) : error;
			insert errorInstance('Flow Lead Convert Error/FCM Update Error', 'ConvertPartnerLead', error);
			throw ex;
		}
		return returnResult;
	}
	public static Error_log__c errorInstance(String errorName, String errorClass, String errorMessage) {
		return (new Error_log__c(Name = errorName, Class__c = errorClass, Error_Message__c = errorMessage));
	}
	public static Lead returLeadInstance(String associatedLead, String status, Boolean isPartnerlead, Boolean validationOverride, String recordTypeId, String description, String associatedOpportunity) {
		return (new Lead(id = associatedLead, status = status, Is_Partner_Lead__c = isPartnerlead, validation_override__c = validationOverride, recordTypeId = recordTypeId, Disposition__c = description, Associated_Opportunity__c = associatedOpportunity));
	}
	public static void updateopptyFcm(String opptyId, String fcmId) {
		update(new Opportunity(Id = opptyId, FCM__c = fcmId));
	}
	/**End Rajesh Kumar JIRA # SFDC-6406 */
}