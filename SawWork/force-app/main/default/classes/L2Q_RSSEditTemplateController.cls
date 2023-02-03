public class L2Q_RSSEditTemplateController {
	@AuraEnabled
	public static Map<String,
		String > findQuestionType() {
			Map<String,
				String > options = new Map<String,
				String > ();
			Schema.DescribeFieldResult fieldResult = Survey_Question__c.Type__c.getDescribe();
			List<Schema.PicklistEntry > ple = fieldResult.getPicklistValues();
			Map<String,
				String > fieldOption = new Map<String,
				String > ();
			for (Schema.PicklistEntry pe: ple) {
				options.put(pe.getValue(), pe.getLabel());
			}
			return options;
		}
	@AuraEnabled
	public static string saveTemplate(String jsonString, String secId, String quesIdList, String surName, String recId) {
		// Start of Input Sanitization
		secId = String.escapeSingleQuotes(secId);
		quesIdList = String.escapeSingleQuotes(quesIdList);
		recId = String.escapeSingleQuotes(recId);
		// End of Input Sanitization
		List<L2Q_RSSQuestionGroupWrapper > questionGroupWrappers = null;
		List<Survey_Question_Group__c > RSSQuestionGroupNextVersion = null;
		List<Survey_Question__c > RSSQuestionsNextVersion = null;
		try {
			questionGroupWrappers = (List<L2Q_RSSQuestionGroupWrapper > ) JSON.deserializeStrict(jsonString, List<L2Q_RSSQuestionGroupWrapper > .class);
			RSSQuestionGroupNextVersion = new List<Survey_Question_Group__c > ();
			RSSQuestionsNextVersion = new List<Survey_Question__c > ();

			if (!String.isBlank(surName) && !String.isBlank(recId)) {
				updatetemplateName(recId, surName);
			}
			if (!String.isblank(secId)) {
				deleteQuestionandgroup(secId);
			}
			if (!String.isblank(quesIdList)) {
				deleteQuestion(quesIdList);
			}
			System.debug('questionGroupWrappers<#>Id' + questionGroupWrappers);
			for (L2Q_RSSQuestionGroupWrapper qgw: questionGroupWrappers) {
				RSSQuestionGroupNextVersion.add(qgw.questionGroup);
			}
			upsert RSSQuestionGroupNextVersion;
			for (L2Q_RSSQuestionGroupWrapper qgw: questionGroupWrappers) {
				if (qgw.surveyQuestions != null)
					for (L2Q_RSSSurveyQuestion rsq: qgw.surveyQuestions) {
						if (rsq != null) {
							rsq.question.Survey_Question_Group__c = qgw.questionGroup.Id;
							RSSQuestionsNextVersion.add(rsq.question);
						}
					}
			}
			System.debug('questionGroupWrappers<#>' + questionGroupWrappers);
			upsert RSSQuestionsNextVersion;
		} catch (Exception ex) {
			//showing error message on UI if any exception happens.
			throw new AuraHandledException('Error : ' + ex.getMessage() + ';' + ' Detail : ' + ex.getStackTraceString());
		}
		return JSON.serialize(questionGroupWrappers);

	}
	@AuraEnabled
	public static string publishTemplate(String recId) {
		intialWrapper retData = new intialWrapper();
		recId = String.escapeSingleQuotes(recId);
		List<Survey_Question__c > templList = [Select Id, Name from Survey_Question__c where Survey__c =: recId];
		if (templList.size() == 0) {
			throw new AuraHandledException('There is no content to be published,please add at least one question and click on save before publish.');
		}
		boolean WriteAccessOfUser = L2Q_eRSSUtility.TemplateWriteAccess(UserInfo.getUserId());
		Survey__c currentVersion = [Select Id, UniqueName__c, Name, Version__c from Survey__c where id =: recId Limit 1];
		List<Survey__c > lSurveyList = [SELECT Id, Name, RSS_Published__c FROM Survey__c WHERE Name =: currentVersion.name AND UniqueName__c !=: currentVersion.UniqueName__c AND RSS_Published__c = true];
		if (lSurveyList.size() > 0) {
			throw new AuraHandledException('A Template with the same name already exists.Cannot publish this Template.');
		}
		List<Survey__c > OlderVersionTemplates = [select Id, name, Locked__c, RSS_Published__c, RecordTypeId, RecordType.Name, UniqueName__c, Submit_Response__c, Version__c from Survey__c WHERE UniqueName__c =: currentVersion.UniqueName__c and Id !=: recId];
		for (Survey__c s: OlderVersionTemplates) {
			s.RSS_Published__c = false;
		}
		currentVersion.RSS_Published__c = true;
		currentVersion.Locked__c = true;
		currentVersion.Version__c = getLatestVersion(currentVersion.UniqueName__c);
		retData.versionNum = (Integer) currentVersion.Version__c;
		retData.disabled = (currentVersion.RSS_Published__c != true && currentVersion.Locked__c != true) ? false : true;
		retData.isPublished = true;
		try {
			update currentVersion;
			update OlderVersionTemplates;
		} catch (Exception ex) {
			//showing error message on UI if any exception happens.
			throw new AuraHandledException('Error : ' + ex.getMessage() + ';' + ' Detail : ' + ex.getStackTraceString());
		}
		return JSON.serialize(retData);

	}
	public static void deleteQuestionandgroup(String secId) {
		try {
			List<String> seclstoDelete = new List<String> ();
			List<String> secdata = !String.isBlank(secId) ? secId.split(',') : new List<String> ();
			System.debug('secdata<#>' + secdata);
			for (String str: secdata) {
				seclstoDelete.add(str.trim());
			}
			if (seclstoDelete.size() > 0) {
				List<Survey_Question_Group__c > deletelitSec = [Select id from Survey_Question_Group__c where Id in: seclstoDelete];
				List<Survey_Question__c > deletelistQues = [Select id from Survey_Question__c where Survey_Question_Group__c in: seclstoDelete];
				delete deletelitSec;
				delete deletelistQues;
			}
		} catch (Exception ex) {
			//showing error message on UI if any exception happens.
			throw new AuraHandledException('Error : ' + ex.getMessage() + ';' + ' Detail : ' + ex.getStackTraceString());
		}
	}

	public static void deleteQuestion(String quesIdList) {
		try {
			List<String> queslstoDelete = new List<String> ();
			List<String> quesdata = !String.isBlank(quesIdList) ? quesIdList.split(',') : new List<String> ();
			System.debug('secdata<#>' + quesdata);
			for (String str: quesdata) {
				queslstoDelete.add(str.trim());
			}
			System.debug('queslstoDelete<#>' + queslstoDelete);
			if (queslstoDelete.size() > 0) {
				List<Survey_Question__c > deletelistQues = [Select id from Survey_Question__c where id in: queslstoDelete];
				System.debug('deletelistQues<#>' + deletelistQues);
				delete deletelistQues;
			}
		} catch (Exception ex) {
			//showing error message on UI if any exception happens.
			throw new AuraHandledException('Error : ' + ex.getMessage() + ';' + ' Detail : ' + ex.getStackTraceString());

		}
	}
	@AuraEnabled
	public static string intialData(String recordId) {
		intialWrapper returnData = new intialWrapper();
		try {
			boolean WriteAccessOfUser = L2Q_eRSSUtility.TemplateWriteAccess(UserInfo.getUserId());
			Survey__c surv = [select Id, name, RSS_Published__c, Locked__c, Version__c from Survey__c where Id =: recordId Limit 1];
			if (surv.RSS_Published__c != true && surv.Locked__c != true) {
				returnData.disabled = false;
			} else {
				returnData.disabled = true;
			}
			if (!WriteAccessOfUser) {
				returnData.disabled = true;
			}
			returnData.isPublished = surv.RSS_Published__c;
			returnData.templName = surv.Name;
			returnData.versionNum = (Integer) surv.Version__c;
			returnData.writeAccess = WriteAccessOfUser;
		} catch (Exception ex) {
			//showing error message on UI if any exception happens.
			throw new AuraHandledException('Error : ' + ex.getMessage() + ';' + ' Detail : ' + ex.getStackTraceString());
		}

		return JSON.serialize(returnData);
	}
	public class intialWrapper {
		public boolean writeAccess = false;
		public boolean disabled = false;
		public String templName = null;
		public Integer versionNum = 0;
		public boolean isPublished = false;

		public intialWrapper() {

		}
	}

	@AuraEnabled
	public static boolean isPublished(String recId) {
		recId = String.escapeSingleQuotes(recId);
		boolean isPublished;
		Survey__c template = [Select Id, Locked__C, RSS_Published__c, UniqueName__c, Name, Version__c from Survey__c where id =: recId Limit 1];
		if (template.RSS_Published__c == true) {
			isPublished = true;
			return isPublished;
		}
		return isPublished;
	}

	//below method creates Intial wrapper of data and return to LC in serialized form to avoid sanitization issue
	@AuraEnabled
	public static string loadWrapper(String templaRecId) {
		templaRecId = String.escapeSingleQuotes(templaRecId);
		List<Survey_Question_Group__c > questionGroups = null;
		List<L2Q_RSSQuestionGroupWrapper > questionGroupWrappers = new List<L2Q_RSSQuestionGroupWrapper > ();
		try {
			questionGroups = [select name, Akam_Survey_Question_ID__c, Survey__c, Order_Number__c, UniqueName__c from Survey_Question_Group__c where Survey__c =: templaRecId order by Order_Number__c];
			if (questionGroups == null || questionGroups.size() == 0) {} else {
				List<Survey_Question__c > tempQuestions = [Select s.Type__c, s.QuestionDescription__c, s.Akam_Survey_Question_ID__c, s.Id, s.Survey__c, s.Required__c, s.Question__c,
					s.OrderNumber__c, s.Name, s.Choices__c, s.Survey_Question_Group__c, Category__c, UniqueName__c
					From Survey_Question__c s
					WHERE s.Survey__c =: templaRecId and s.Survey_Question_Group__c in: QuestionGroups ORDER BY s.Survey_Question_Group__r.Order_Number__c, s.OrderNumber__c
				];
				Map<Id, List<L2Q_RSSSurveyQuestion >> tempMap = new Map<Id, List<L2Q_RSSSurveyQuestion >> ();
				for (Survey_Question__c q: tempQuestions) {
					if (tempMap.get(q.Survey_Question_Group__c) == null) {
						tempMap.put(q.Survey_Question_Group__c, new List<L2Q_RSSSurveyQuestion > ());
					}
					tempMap.get(q.Survey_Question_Group__c).add(new L2Q_RSSSurveyQuestion(q));
				}
				for (Survey_Question_Group__c sqg: QuestionGroups) {
					L2Q_RSSQuestionGroupWrapper toBeAdded = new L2Q_RSSQuestionGroupWrapper(sqg);
					tobeAdded.surveyQuestions = tempMap.get(sqg.Id);
					if (tobeAdded.surveyQuestions == null) {
						tobeAdded.surveyQuestions = new List<L2Q_RSSSurveyQuestion > ();
					}
					questionGroupWrappers.add(toBeAdded);
				}
				questionGroupWrappers = cleanWrapper(questionGroupWrappers);

			}
		} catch (Exception ex) {
			throw new AuraHandledException('Error : ' + ex.getMessage() + ';' + ' Detail : ' + ex.getStackTraceString());
		}
		return JSON.serialize(questionGroupWrappers);
	}
	//below method do a deep clone of existing record send JSON data to front end
	@AuraEnabled
	public static string reviseTemplate(String existingRecordId) {
		String temprecordId = null;
		try {
			temprecordId = L2Q_eRSSUtility.deepCloneNewTemplate(String.escapeSingleQuotes(existingRecordId));
		} catch (Exception ex) {
			throw new AuraHandledException('Error : ' + ex.getMessage() + ';' + ' Detail : ' + ex.getStackTraceString());
		}
		return temprecordId;
	}
	//below method assign Unique Key in Wrapper attribute when component loads to use in Identify each section uniquely in front end for operation like edit/delete/Association to question
	public static List<L2Q_RSSQuestionGroupWrapper > cleanWrapper(List<L2Q_RSSQuestionGroupWrapper > questionGroupWrappers) {
		for (Integer i = 0; i<questionGroupWrappers.size(); i++) {
			questionGroupWrappers[i].UniqueName = questionGroupWrappers[i].questionGroup.UniqueName__c;
			if (questionGroupWrappers[i].surveyQuestions.size() > 0) {
				for (Integer k = 0; k<questionGroupWrappers[i].surveyQuestions.size(); k++) {
					questionGroupWrappers[i].surveyQuestions[k].UniqueName = questionGroupWrappers[i].surveyQuestions[k].question.UniqueName__c;
				}
			}
		}
		return questionGroupWrappers;
	}

	//below method returns latest version of template based on UniqueKey also handles null pointer if templats is null asiigns 0
	public static Integer getLatestVersion(String UniqueName) {
		List<Survey__c > surveys = [select Version__c from Survey__c where UniqueName__c =: UniqueName order by Version__c desc NULLS LAST];
		if (surveys != null && surveys.size() > 0) {
			surveys[0].Version__c = (surveys[0].Version__c == null) ? 0 : surveys[0].Version__c;
			return Integer.valueOf(surveys[0].Version__c) + 1;
		}
		return -1;
	}
	//Method to update template Name
	public static void updatetemplateName(String recId, String Name) {
		Survey__c surv = new Survey__c(Id = recId, Name = Name);
		update surv;
	}

}