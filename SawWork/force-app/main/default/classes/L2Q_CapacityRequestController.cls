/**
 * Author : Rajesh Kumar
 * Description : Apex Controller to handle Capacity Request
 * JIRA # : SFDC-6906
 * @todo : 1. Access based on record type , picklist values based on record type , handle lookup field.
 *         2. Another Metadata to handle current recordId and convert into objecttype and check for corresponding metadata configuration .
 */
public without sharing class L2Q_CapacityRequestController {
	public static List < L2Q_GridRecordList > origRecords;
	public static List < L2Q_CprUtil.CPRrequestapprovewrapper > origRequest = new List < L2Q_CprUtil.CPRrequestapprovewrapper > (); // Rajesh SFDC-7368
	public static List < L2Q_CprUtil.CPRrequestapprovewrapper > origApprove = new List < L2Q_CprUtil.CPRrequestapprovewrapper > (); // Rajesh SFDC-7368

    // This method is for redirection only from account and CPR objects
    @AuraEnabled
    public static Sobject redirectHandler(String recId) { // Refactored for CPR Detail page : SFDC-7607
        String objName  = String.valueOf(Id.valueOf(recId).getSobjectType()).toLowerCase();
        String queryString = (objName == 'account') ? 'SELECT name, AKAM_Account_ID__c FROM Account WHERE id = :recId LIMIT 1' : 'Select Id,Name,Account__r.Name,Account__r.AKAM_Account_ID__c,Account__r.id from Capacity_Request__c where id = :recId  limit 1';
        System.debug('queryString:::'+queryString);
        try {
            return Database.Query(queryString);
        } catch(Exception ex) {
            Sawyer.saw(ex);
        }
        return null;
    }

	//method checks access and form field level schema for cloning and adding records based on field type on UI
	@AuraEnabled
	public static L2Q_CprUtil.SchemaWrapper checkAcessandbuildschema(
	String parentId) {
		L2Q_CprUtil.SchemaWrapper sc = new L2Q_CprUtil.SchemaWrapper();
		if (String.isBlank(parentId)) {
			throw new AuraHandledException('Parent record cannot be blank.');
		}
		boolean profileCheck = userpermandProfilecheck(); //SFDC-7069
		if (! (userAccesscheck(parentId) || profileCheck)) {
			// Modifier Rajesh Kumar SFDC-7069 -|- seprated individual method for profile and ps check for capacity request
			throw new AuraHandledException('You don’t have sufficient privileges to perform this operation.');
		}
		try {
			L2Q_MdtWrapper lgr = (L2Q_MdtWrapper) System.JSON.deserialize(
			GSMSettings.getVerbose('L2Q_Capacity_Request_Field_Schema'), L2Q_MdtWrapper.class); // convert metadata into wrapper format
			Schema.DescribeSObjectResult describeResult = ((SObject)(Type.forName('Schema.' + lgr.objectName).newInstance())).getSObjectType().getDescribe();
			List < L2Q_CprUtil.DataformationWrapper > fieldMetadata = new List < L2Q_CprUtil.DataformationWrapper > ();
			String queryFields = '';
			Map < String,Schema.SObjectField > fieldMap = describeResult.fields.getMap(); // get field map for capacity request object and get the detail from metadata configurations
			for (L2Q_MdtWrapper.FieldSet fs: lgr.fieldSet) {
				L2Q_CprUtil.DataformationWrapper fieldsData = new L2Q_CprUtil.DataformationWrapper();
				if (fieldMap.containsKey(fs.fieldApiname)) {
					queryFields = queryFields + ',' + fs.fieldApiname;
					schema.describefieldresult dfield = fieldMap.get(fs.fieldApiname).getDescribe();
					String recfieldType = String.valueOf(dfield.getType()).toLowerCase() ; // CPR Phase 2 avoid PMD COmplexity Rules 
					fieldsData.fieldapiName = fs.fieldApiname;
					fieldsData.fieldType = String.valueOf(dfield.getType());
					fieldsData.fieldLabel = String.valueOf(dfield.getLabel());
					fieldsData.helptext = dfield.getInlineHelpText();
		            fieldsData.picklistValues = (recfieldType == 'picklist') ? L2Q_CprUtil.getPicklistvalues(dfield, 'picklist') : (recfieldType=='multipicklist'? L2Q_CprUtil.getPicklistvalues(dfield, 'multipicklist'):null) ; //  PMD Rules 
					fieldsData.refrencedTo = (recfieldType == 'reference') ? String.valueOf(dfield.getReferenceTo()) : null;
					fieldsData.isrequired = fs.required;
					fieldsData.fieldWidth = fs.fieldWidth;
				}
				fieldsData.readonly = false;
				fieldMetadata.add(fieldsData);
			}
			if (fieldMetadata.isEmpty() || String.isBlank(queryFields.replaceFirst(',', '')) || String.isBlank(lgr.objectName)) {
				throw new AuraHandledException('Metadata is not configured<not clinet message>');
			}
			sc.schemaData = fieldMetadata;sc.fieldSet = queryFields.replaceFirst(',', '');
			sc.objName = lgr.objectName;
			sc.uomfd = lgr.uomfd;
			sc.recordLimit = lgr.recordLimit;
			sc.orderby = lgr.orderby;
			sc.filter = lgr.filter;
			sc.readonlyStatuscondition = lgr.readonlyStatuscondition;
			sc.timeZone = UserInfo.getTimeZone().getDisplayName();
			sc.cpheader = lgr.cpheader;
			sc.approvedFieldenabled = profileCheck; // Modifier Rajesh Kumar SFDC-7069 -|- used in ui to check for pdg/bu/so and other user
			sc.fieldlabelMapping = GSMSettings.getVerbose('L2Q_CPR_Label_Mapping'); // Rajesh SFDC-7368 // seprated the metadat for field mapping to avoid complexity
			sc.nullclonefield = lgr.nullclonefield; // Rajesh SFDC-7368
			sc.countrysplitreadStatus = lgr.countrysplitreadStatus;  // Rajesh SFDC-7368
		} catch(Exception ex) {
			Sawyer.saw(ex);
			throw new AuraHandledException('An error encountered while fetching the schema details,please contact system admin for more details.');
		}
		return sc;
	}
	// get CPR request data 
	@AuraEnabled 
	public static List < Sobject > getData(String objName, String fieldSet, String WhereClause, Integer recordLimit, String orderby) {
		String query = ''; // not handling null pointer since the parameter must have the value , also in case of any issue it will be logged to error table
		try {
			query = 'select Id, ' + fieldSet + ' From ' + objName + ' Where Id != null ' + WhereClause + ' order by ' + orderby + ' limit ' + Integer.valueOf(recordLimit);
		} catch(Exception ex) {
			Sawyer.saw(ex);
			throw new AuraHandledException('An error encountered while fetching the records,please contact system admin for more details.');
		}
		return Database.query(query);
	}

  //this method is reserved for future use in case if we need to have delete record functionality
	@AuraEnabled 
	public static void deleteRecord(String recordId) {
		try {
			database.delete(Id.valueOf(recordId));
		} catch(Exception ex) {
			Sawyer.saw(ex);
			throw new AuraHandledException('There is issue deleting records,please contact system admin for more details.');
		}
	}

	// Method to handle CPR Save 
	@AuraEnabled 
	public static void saveRecords(String jsonData, String objName, String parentId) {
		try {
			SObjectType sobjectType = ((SObject)(Type.forName('Schema.' + objName).newInstance())).getSObjectType();
			Map < String,Schema.SObjectField > schemaFieldMap = sobjectType.getDescribe().fields.getMap();
			List < Capacity_Request__c > ls = new List < Capacity_Request__c > ();
			List < L2Q_GridRecordList > listData = (List < L2Q_GridRecordList > ) System.JSON.deserialize(jsonData, List < L2Q_GridRecordList > .class);
			origRecords = listData;
			for (L2Q_GridRecordList js: listData) {
				Capacity_Request__c sobj = new Capacity_Request__c();
				if (String.isNotEmpty(js.recordId)) {
					sobj.put('Id', js.recordId);
				} else {
					sobj.put('Account__c', parentId); // this will be changed while making it generic
				}
                //Begin Rajesh SFDC-7368 -|- CPR Phase 2 Country Split 
				sobj.put('uniqueid__c', js.uniqueKey); // unique used for child record
				if (String.isnotBlank(js.requestedcapacity)) { // prepare child request : Note Approval and request will not be made in same transaction - pre-requisite for changes 
					origRequest.addAll((List < L2Q_CprUtil.CPRrequestapprovewrapper > ) System.JSON.deserialize(js.requestedcapacity, List < L2Q_CprUtil.CPRrequestapprovewrapper > .class)); // add original request first to determine index
				} 
				if (String.isnotBlank(js.approvedcapacity)) { // prepare child approval 
					origApprove.addAll((List < L2Q_CprUtil.CPRrequestapprovewrapper > ) System.JSON.deserialize(js.approvedcapacity, List < L2Q_CprUtil.CPRrequestapprovewrapper > .class)); // add original request first to determine index
				} 
				//End Rajesh SFDC-7368 -|- CPR Phase 2 Country Split 
				
				for (L2Q_GridRecordList.FieldArray fr: js.fieldArray) {
					//checking field type on save.
					String fieldType = String.valueOf(schemaFieldMap.get(fr.fieldApiname).getDescribe().getType());
					switch on fieldType { // Switch Vs If Else : https://www.geeksforgeeks.org/switch-vs-else/
						when 'DATE' {
							sObj.put(fr.fieldApiname, String.isEmpty(fr.fieldapiValue) ? null : DATE.valueOf(fr.fieldapiValue));
						}
						when 'DOUBLE' {
							sObj.put(fr.fieldApiname, String.isEmpty(fr.fieldapiValue) ? null : DECIMAL.valueOf(fr.fieldapiValue));
						}
						when 'DATETIME' {
							sObj.put(fr.fieldApiname, String.isEmpty(fr.fieldapiValue) ? null : Datetime.valueOfGmt(fr.fieldapiValue.replace('T', ' ').replace('Z', '')));
						}
						when 'BOOLEAN' {
							sObj.put(fr.fieldApiname, String.isEmpty(fr.fieldapiValue) ? false : BOOLEAN.valueOf(fr.fieldapiValue));
						}
						when else {
							sObj.put(fr.fieldApiname, String.isEmpty(fr.fieldapiValue) ? null : fr.fieldapiValue);
						}
			
					}
				}
				ls.add(sObj);
			}
			upsert ls;
		} catch(DmlException dex) {
			Sawyer.saw(dex); // log the error using new error framework
			for (Integer i = 0; i < dex.getNumDml(); i++) {
				String erroMessage = dex.getDmlMessage(i);throw new AuraHandledException('CPR_ERROR_UNIQUEID:' + origRecords[dex.getDmlIndex(i)].uniqueKey + '>>>##>>>' + erroMessage);
			}
		} catch(Exception ex) {
			Sawyer.saw(ex);throw new AuraHandledException('An error encountered while performing the operation,please contact system admin for more detail.');
    }
	      upsertCPRallocations(origRequest,origApprove); // Rajesh - SFDC-7368 | Handle CPR Child Allocations 
	}

	//Modifier :- Rajesh Kumar SFDC-7069 -|- seprated individual method for checking user access based on team association and profile/ps
	public static boolean userAccesscheck(String parentId) {
		boolean hasuserAccess = false;
		List < AccountTeamMember > acMember = [SELECT Id, AccountId FROM AccountTeamMember	WHERE userId = :UserInfo.getUserId() AND AccountId = :parentId];
		hasuserAccess = (acMember.isEmpty()) ? false: true;
		return hasuserAccess;
	}

	//Modifier:- Rajesh Kumar SFDC-7069 -|- seprated individual method for profile and ps check for capacity request
	public static boolean userpermandProfilecheck() {
		boolean haspsetorProfileaccess = false;
		List < String > psetprofileList = GSMSettings.getVerbose('L2Q_CPR_PR_PS_Access').split(','); // Metadata will always have the value , however client method needs to handle exception
		List < PermissionSetAssignment > pdgAccess = [ SELECT Id, PermissionSetId, PermissionSet.ProfileId FROM PermissionSetAssignment 	WHERE AssigneeId = :UserInfo.getUserId() AND(PermissionSetId IN: psetprofileList OR PermissionSet.ProfileId IN: psetprofileList)];
		haspsetorProfileaccess = (!pdgAccess.isEmpty()) ? true: false;
		System.debug('SD_PSPF_Check-' + haspsetorProfileaccess);
		return haspsetorProfileaccess;
	}



  //Begin Rajesh SFDC-7368 -|- CPR Phase 2 Country Split 
  //This Method handles UI request for capacity allocation based on Parent CPR 
	@AuraEnabled
	public static List < L2Q_CprUtil.CPRallocationwrapper > getallocatedCapacity(String parentId, List < String > region) {
		List < L2Q_CprUtil.CPRallocationwrapper > cpa = new List < L2Q_CprUtil.CPRallocationwrapper > ();
		for (Capacity_Allocation__c ca: [SELECT id, Requested_Capacity__c, Country__c, Region__c, Associated_CPR__c, Approved_Capacity__c FROM Capacity_Allocation__c WHERE Associated_CPR__c = :parentId AND region__c IN: region LIMIT 50000]) {
			L2Q_CprUtil.CPRallocationwrapper ct = new L2Q_CprUtil.CPRallocationwrapper();
			ct.recordid = ca.id;
			ct.country = ca.country__c;
			ct.allocatedcapacity = ca.Requested_Capacity__c;
			ct.region = ca.region__c;
			ct.approvedcapacity = (String.isBlank(
			String.valueOf(ca.Approved_Capacity__c))) ? 0 : ca.Approved_Capacity__c;
			ct.cprid = ca.Associated_CPR__c;
			cpa.add(ct);
		}
		return cpa;
  }

  // private method to handle upsert of CPR Allocations 
  private static void upsertCPRallocations(List < L2Q_CprUtil.CPRrequestapprovewrapper > lorigRequest,List < L2Q_CprUtil.CPRrequestapprovewrapper > lorigApprove  ){
	List < Capacity_Allocation__c > cpAllocation = new List < Capacity_Allocation__c > (); // CPR Phase 2
	List < Capacity_Allocation__c > cpApproval = new List < Capacity_Allocation__c > (); // CPR Phase 2 different list for approval just to avoid exception
	   if (!lorigRequest.isEmpty()) {
		cpAllocation = L2Q_CprUtil.preparerequestapproveList(lorigRequest, 'request');
		try {
			upsert cpAllocation;
		} catch(DmlException dex) {
			Sawyer.saw(dex);
			for (Integer i = 0; i < dex.getNumDml(); i++) {
				String erroMessage = dex.getDmlMessage(i);throw new AuraHandledException('CPR_ERROR_REQUEST_ALLOCATION_UNIQUEID:' + lorigRequest[dex.getDmlIndex(i)].parentunqid + '>>>##>>>' + erroMessage);
			}
		} catch(Exception ex) {
			Sawyer.saw(ex); throw new AuraHandledException('An error encountered while performing the operation,please contact system admin for more detail.');
		}
	}
	if (!lorigApprove.isEmpty()) {
		cpApproval = L2Q_CprUtil.preparerequestapproveList(origApprove, 'approval');
		try {
			upsert cpApproval;
		} catch(DmlException dex) {
			Sawyer.saw(dex); 
			for (Integer i = 0; i < dex.getNumDml(); i++) {
				String erroMessage = dex.getDmlMessage(i);throw new AuraHandledException('CPR_ERROR_APPROVE_ALLOCATION_UNIQUEID:' + lorigApprove[dex.getDmlIndex(i)].parentunqid + '>>>##>>>' + erroMessage);
			}
		} catch(Exception ex) {
			Sawyer.saw(ex); throw new AuraHandledException('An error encountered while performing the operation,please contact system admin for more detail.');
		}
}
 // End Rajesh Kumar -  SFDC-7368
  }
}