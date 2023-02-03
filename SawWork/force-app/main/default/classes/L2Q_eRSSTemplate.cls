/**
Author : Rajesh Kumar 
JIRA # : SFDC-5934
Description : Converting classic eRSS template to lightning , class used for showing template data to User 
 */
public without sharing class L2Q_eRSSTemplate {
	public static List<String> filterView = System.label.L2Q_eRssfilterType.split('#'); // label should always have value this is mandatory condition else exception would be thrown
	public static String baseQuery = GSMSettings.getVerbose('eRsstemplateQuery');
	public static String rectype = Schema.SObjectType.Survey__c.getRecordTypeInfosByDeveloperName().get('RSS_Template').getRecordTypeId();
	@AuraEnabled
	public static string createTemplate(String templateName, String uniqueId) {
		Survey__c surv = new Survey__c();
		surv.Name = templateName;
		surv.RecordTypeId = Schema.SObjectType.Survey__c.getRecordTypeInfosByDeveloperName().get('RSS_Template').getRecordTypeId();
		surv.UniqueName__c = uniqueId; // uniqueId helps in checking published template from previous version
		surv.Submit_Response__c = 'temp';
		List<Survey__c > lSurvey = [SELECT Id FROM Survey__c WHERE Name =: templateName AND RSS_Published__c = true LIMIT 1];
		if (lSurvey.size() > 0) {
			throw new AuraHandledException('Cannot save the template. Published template already exists with same name');
		} else {
			insert surv;
		}
		return surv.id;
	}
	@AuraEnabled
	public static List<Survey__c > returnData(String pageSize, String pageNumber, String selectedView) {
		String inputQuery = null;
		Integer psize = Integer.valueOf(pageSize);
		Integer pnumber = Integer.valueOf(pageNumber) - 1;
		Integer offset = psize * pnumber;
		System.debug('rectype-->'+rectype);

		if (selectedView == filterView[0]) {
			inputQuery = baseQuery + ' where soft_delete__c=false and locked__c = false and recordtypeid = \'' + rectype + '\'' +  ' and ownerId = \'' + UserInfo.getUserId() + '\' ' + ' order by lastmodifieddate desc Limit ' + Integer.valueOf(psize) + ' OFFSET ' + offset;
		} else if (selectedView == filterView[1]) {
			inputQuery = baseQuery + ' where soft_delete__c=false and RSS_Published__c = true and recordtypeid = \'' + rectype + '\'' + ' order by lastmodifieddate desc Limit ' + Integer.valueOf(psize) + ' OFFSET ' + offset;
		} else {
			inputQuery = baseQuery + ' where soft_delete__c=false and locked__c = true and recordtypeid = \'' + rectype + '\'' + ' order by lastmodifieddate desc Limit ' + Integer.valueOf(psize) + ' OFFSET ' + offset;
		}
		System.debug('inputQuery-->'+inputQuery);
		return database.query(inputQuery);

	}
	@AuraEnabled
	public static void deleteTemplate(String recId) {
		Boolean templatehasForms = false;
			List<Survey__C > lsttoDelete = [Select id from Survey__C where Id =: recId limit 1];
			System.debug('lsttoDelete>>' +lsttoDelete);
			for (SurveyTaker__c st: [select id from SurveyTaker__c where Survey__c =: recId]) {
				templatehasForms = true;
			}
			if (!templatehasForms) {
				lsttoDelete[0].soft_delete__c = true;
				update lsttoDelete;
			} else {
				throw new AuraHandledException('Cannot Delete RSS Template which has forms associated with it.'); // real time error
			}
	}

	@AuraEnabled // method to extract table column header from metadata , provided that metadata is never blank exception would be thrown
	public static string returnmetadataString(String developerName) {
		return GSMSettings.getVerbose(developerName);
	}
	@AuraEnabled
	public static List<Survey__c > templateSearch(String searchParams, String selectedTemplates, Integer count) {
		String inputQuery = baseQuery + ' Where ';
		String whereCluase = '';
		System.debug('>>count>>' + count);
		List<convertWrapper> searchQuery = (List<convertWrapper> ) JSON.deserializeStrict(searchParams, List<convertWrapper> .class);
		if (count == 1) {
			inputQuery = (searchQuery[0].label == 'Version__c') ? inputQuery + searchQuery[0].label + ' = ' + Integer.ValueOf(searchQuery[0].value) + ' and ' : inputQuery + searchQuery[0].label + ' like ' + '\'%' + searchQuery[0].value + '%\'' + ' and ';
		} else {
			for (convertWrapper cs: searchQuery) {
				whereCluase = (cs.label == 'Version__c') ? whereCluase + cs.label + ' = ' + Integer.ValueOf(cs.value) + ' and ' : whereCluase + cs.label + ' like ' + '\'%' + cs.value + '%\'' + ' and ';
			}
		}
		inputQuery = inputQuery + whereCluase;
		if (selectedTemplates == filterView[0]) {
			inputQuery = inputQuery + '  soft_delete__c=false and locked__c = false and recordtypeid = \'' + rectype + '\''  + ' and ownerId = \'' + UserInfo.getUserId() + '\' ' + ' order by lastmodifieddate desc  Limit 2000' ;//+Integer.valueOf(rlimit);
		} else if (selectedTemplates == filterView[1]) {
			inputQuery = inputQuery + ' soft_delete__c=false and RSS_Published__c = true and recordtypeid = \'' + rectype + '\'' + ' order by lastmodifieddate desc limit 2000' ; // +Integer.valueOf(rlimit);
		} else {
			inputQuery = inputQuery + '  soft_delete__c=false and locked__c = true and recordtypeid = \'' + rectype + '\'' + ' order by lastmodifieddate desc Limit 2000'; //+Integer.valueOf(rlimit);
		}
		System.debug('selectedTemplates>>'+selectedTemplates+'>>>inputQuery>>>' + Database.query(inputQuery));
		return  Database.query(inputQuery) ;
		

	}
	@AuraEnabled
	public static boolean checkAccess(){
		return L2Q_eRSSUtility.TemplateWriteAccess(UserInfo.getUserId());

	}
	public class convertWrapper {
		public String label;
		public String value;
	}
}