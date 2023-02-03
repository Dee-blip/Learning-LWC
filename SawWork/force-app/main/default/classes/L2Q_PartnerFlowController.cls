/**Author : Rajesh Kumar
 * Description : This class mainly contains logic for Flow LWC component and VF Page
 * @todo : Remove error logging and utilize new error handling framework designed by Anand-GSM Team
 *  */
// SFDC-6548 :  Changed lookup Id (Rajesh Kumar -GSM Team)
// SFDC-6777 :  Added logic for Flow File Upload Component
// SFDC-6776 :  Added logic for flow table component

public without sharing class L2Q_PartnerFlowController {
	private static final Integer MAX_LIMIT = 1900;
	private static final Integer DEFAULT_LIMIT = 20;
	private static final Integer DEFAULT_OFFSET = 0;
	public Boolean isPartneruser {
		get;
		set;
	}
	public String recordId {
		get;
		set;
	}
	public L2Q_PartnerFlowController(ApexPages.StandardController stdController) {
		//Begin SFDC-6548
		String relationshipId = ApexPages.currentPage().getParameters().get(GsmUtilClass.getGSMSettingValue('Lead_PMRA_RelationShip_Id'));
		recordId = (String.isNotBlank(relationshipId)) ? relationshipId : '';
		//End SFDC-6548
		isPartneruser = (UserInfo.getUserType().toLowerCase().contains('partner')) ? true : false;
	}
	/*Begin Rajesh Kumar -GSM Team , JIRA# SFDC-6777 */
	@AuraEnabled
	public static DataResponse getuserDetails() {
		DataResponse response = new DataResponse();
		response.uiThemedisplayed = Userinfo.getUiThemeDisplayed().toLowerCase();
		response.usertype = UserInfo.getUserType().toLowerCase();
		return response;
	}
	@AuraEnabled
	public static void deleteuserFile(String documentId) {
		System.debug('documentId-->' + documentId);
		if (String.isempty(documentId) || String.valueOf(Id.valueOf(documentId).getSobjectType()).toLowerCase() != 'contentdocument') {
			throw new AuraHandledException('An error occurred as the File doesn\'t exist OR file id is not valid.');
		}
		List<contentdocument> cdList = [select id from contentdocument where id =: documentId];
		if (!cdList.isEmpty()) {
			try {
				delete cdList;
			} catch (Exception ex) {
				L2Q_CustomExceptionData err = new L2Q_CustomExceptionData('deleteuserFile', ex.getMessage() + '. { Code Stack : ' + ex.getStackTraceString() + ' } ', 0000, 'apexcustomerror', 'An error occurred, while deleting the file; please try again.', 'L2Q_PartnerFlowController');
				throw new AuraHandledException(JSON.serialize(err));
			}
		} else {
			throw new AuraHandledException('An error occurred as the File doesn\'t exist');
		}

	}
	/*End Rajesh Kumar -GSM Team , JIRA# SFDC-6777 */

	/*Begin Rajesh Kumar -GSM Team , JIRA# SFDC-6776 */
	@AuraEnabled
	public static DataResponse getColumnheader(String headerMetadata) {
		//  not expecting any exception here
		DataResponse response = new DataResponse();
		response.coulmnHeader = GSMSettings.getVerbose(headerMetadata);
		response.uiThemedisplayed = Userinfo.getUiThemeDisplayed().toLowerCase();
		response.usertype = UserInfo.getUserType().toLowerCase();
		return response;
	}
	//method to find intial records also assign/checks for intial default values
	@AuraEnabled
	public static DataResponse findRecords(String objectName, String fieldset, Integer recordOffset, Integer recordLimit, String whereClause,String orderBy) {
		DataResponse response = new DataResponse();
		System.debug('whereClause>>>>' + whereClause);
		recordLimit = (String.isBlank(String.valueOf(recordLimit))) ? DEFAULT_LIMIT : ((recordLimit > MAX_LIMIT) ? MAX_LIMIT : recordLimit);
		recordOffset = (String.isBlank(String.valueOf(recordOffset))) ? DEFAULT_OFFSET : recordOffset;
		whereClause = (String.isEmpty(whereClause)) ? '' : whereClause;
		orderBy = (String.isEmpty(orderBy)) ? '' :orderBy;
		if (string.isBlank(objectName) || String.isblank(fieldset)) {
			throw new AuraHandledException('An Internal error occurred as the required information for the selection, is not available');
		}
		try {
			String query = 'Select Id ' + fieldset + ' From ' + objectName + ' Where id != null ' + ' ' + whereClause + ' ' + orderBy + ' ' + ' Limit  ' + recordLimit + ' offset ' + recordOffset;
			System.debug('query>>>>' + query);
			response.records = Database.query(query);
			List<Sobject> ls = Database.query('select id from ' + objectName + ' where id != null ' + whereClause);
			response.recordCount = ls.size();
		} catch (Exception ex) {
			L2Q_CustomExceptionData err = new L2Q_CustomExceptionData('findRecords', ex.getMessage() + '. { Code Stack : ' + ex.getStackTraceString() + ' } ', 0000, 'apexcustomerror', 'An Internal error occurred while fetching the required information, for the selection', 'L2Q_PartnerFlowController');
			throw new AuraHandledException(JSON.serialize(err));
		}
		return response;
	}
	//method to load more data
	@AuraEnabled
	public static DataResponse loadMore(String objectName, String fieldset, Integer recordOffset, Integer recordLimit, String whereClause,String orderBy) {
		DataResponse response = new DataResponse();
		response = findRecords(objectName, fieldset, recordOffset, recordLimit, whereClause,orderBy);
		return response;
	}
	public class DataResponse {
		@AuraEnabled
		public List<Sobject> records;
		@AuraEnabled
		public Integer recordCount;
		@AuraEnabled
		public String uiThemedisplayed;
		@AuraEnabled
		public String coulmnHeader;
		@AuraEnabled
		public string usertype;

	}

	@AuraEnabled
	public static void insertErrorlog(String logname, String logclass, String logmessage) {
		insert(new Error_Log__c(name = logname, Class__c = logclass, Error_Message__c = logmessage));
	}

	/*End Rajesh Kumar -GSM Team , JIRA# SFDC-6776 */
}
//End SFDC-6464