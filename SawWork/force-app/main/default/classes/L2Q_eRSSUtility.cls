public class L2Q_eRSSUtility {
	public static String deepCloneNewTemplate(String TemplateId) {
		Survey__c NewTemplate;
		List<Survey_Question_Group__c > questionGroups;
		List<Survey_Question__c > questions;
		Survey_Question__c tempQuestion;
		Survey_Question_Group__c tempQuestionGroup;
		String rectype;
		Boolean Published;
		NewTemplate = new Survey__c();
		for (Survey__c s: [select name, RSS_Published__c, RecordTypeId, RecordType.developerName, UniqueName__c, Submit_Response__c, Version__c from Survey__c where Id =: TemplateId]) {
			NewTemplate.name = s.name;
			NewTemplate.RecordTypeId = s.RecordTypeId;
			NewTemplate.UniqueName__c = s.UniqueName__c;
			NewTemplate.Submit_Response__c = s.Submit_Response__c;
			NewTemplate.Version__c = 0;
			Published = s.RSS_Published__c;
			rectype = s.RecordType.developerName;
		}
		if (rectype != 'RSS_Template') {
			throw new AuraHandledException('Revision is only allowed for RSS Templates');
		}
		insert NewTemplate;
		system.debug('____Created new Template' + NewTemplate);
		questionGroups = new List<Survey_Question_Group__c > ();
		Map<Id, Survey_Question_Group__c > tempMap = new Map<Id, Survey_Question_Group__c > ();
		for (Survey_Question_Group__c sqg: [select name, UniqueName__c, Akam_Survey_Question_ID__c, Survey__c, Order_Number__c from Survey_Question_Group__c where Survey__c =: TemplateId order by Order_Number__c]) {
			tempQuestionGroup = new Survey_Question_Group__c();
			tempQuestionGroup.UniqueName__c = sqg.UniqueName__c;
			tempQuestionGroup.name = sqg.Name;
			tempQuestionGroup.Survey__c = NewTemplate.Id;
			tempQuestionGroup.Order_Number__c = sqg.Order_Number__c;
			questionGroups.add(tempQuestionGroup);
			tempMap.put(sqg.Id, tempQuestionGroup);
		}
		system.debug('____questionGroups' + questionGroups);

		insert questionGroups;
		questions = new List<Survey_Question__c > ();
		for (Survey_Question__c q: [Select s.Type__c, s.Required__c, s.Question__c,
				s.OrderNumber__c, s.QuestionDescription__c, s.Name, s.UniqueName__c, s.Choices__c, s.Survey_Question_Group__c, s.Category__c
				From Survey_Question__c s
				WHERE s.Survey__c =: TemplateId and s.Survey_Question_Group__c in: tempMap.keySet() ORDER BY s.Survey_Question_Group__r.Order_Number__c, s.OrderNumber__c
			]) {
			tempQuestion = new Survey_Question__c();
			tempQuestion.Type__c = q.Type__c;
			tempQuestion.Name = q.Name;
			tempQuestion.Question__c = q.Question__c;
			tempQuestion.OrderNumber__c = q.OrderNumber__c;
			tempQuestion.Choices__c = q.Choices__c;
			tempQuestion.Survey_Question_Group__c = tempMap.get(q.Survey_Question_Group__c).Id;
			tempQuestion.Survey__c = NewTemplate.Id;
			tempQuestion.UniqueName__c = q.UniqueName__c;
			tempQuestion.Required__c = q.Required__c;
			tempQuestion.QuestionDescription__c = q.QuestionDescription__c;
			tempQuestion.Category__c = q.Category__c;
			questions.add(tempQuestion);
		}
		insert questions;
		system.debug('____questions' + questions);
		return NewTemplate.Id;
	}
	public static Boolean TemplateWriteAccess(string userId) {
		Set<string> Psets = new Set<String> ();
		try {
			eRSS__c objApp = eRSS__c.getInstance('eRSS');
			List<String> tempList = String.valueOf(objApp.Permission_Set_Template__c).split(',', 0);
			for (String a: tempList) {
				Psets.add(a.trim());
			}
		} catch (Exception e) {

			return false;
		}

		for (PermissionSetAssignment pas: [SELECT PermissionSet.label FROM PermissionSetAssignment where AssigneeId =: userId]) {
			if (Psets.contains(pas.PermissionSet.label)) {
				return true;
			}
		}
		string userIdCheck = Userinfo.getUserId();
		for (User objUser: [SELECT Profile.Name, ERSS_Service_Architect__c, ERSS_Super_User__c FROM User WHERE Id =: userIdCheck]) {
			if (Psets.contains(objUser.Profile.Name) || objUser.ERSS_Service_Architect__c || objUser.ERSS_Super_User__c) {
				return true;
			}
		}
		return false;
	}


}