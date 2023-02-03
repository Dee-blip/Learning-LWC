@isTest(SeeAllData = false)
public class L2Q_eRSSEditTemplateTest{
    @testSetup static void setup() 
    {
            GSM_Custom_Settings__c gs = new GSM_Custom_Settings__c();
            gs.Name = 'CRM_Integration';
            gs.Value__c = '005A0000000NHQc';
            insert gs;
       
		Survey__c template = new Survey__c(Name = 'Unique_Template_001', RecordTypeId = Schema.SObjectType.Survey__c.getRecordTypeInfosByDeveloperName().get('RSS_Template').getRecordTypeId(), UniqueName__c = GuidUtil.NewGuid(), Submit_Response__c = ' temp ', Version__c = 0);
		insert template;
       
        Survey_Question_Group__c section =  new Survey_Question_Group__c(UniqueName__c = GuidUtil.NewGuid(),Name = 'Section_Unique',Order_Number__c = 0,Survey__c = template.Id);
        insert section;
    
        Survey_Question__c question  = new Survey_Question__c(QuestionDescription__c = 'test',Survey__c = template.Id,Question__c = 'Quest',Type__c = 'Picklist',Required__c = true,OrderNumber__c =0,UniqueName__c = GuidUtil.NewGuid(),Survey_Question_Group__c = section.Id);
        Insert question; 
    }
	public static testMethod void verifyQuestionandGroup() {
        Survey_Question_Group__c section = [Select Id,Survey__c from Survey_Question_Group__c where name = 'Section_Unique' Limit 1];
        List<Survey_Question_Group__c > questionGroups;
		questionGroups = [select name, Akam_Survey_Question_ID__c, Survey__c, Order_Number__c, UniqueName__c from Survey_Question_Group__c   order by Order_Number__c Limit 1];
		List<L2Q_RSSQuestionGroupWrapper > questionGroupWrappers = new List<L2Q_RSSQuestionGroupWrapper > ();
		if (questionGroups == null || questionGroups.size() == 0) {} else {
			List<Survey_Question__c > tempQuestions = [Select s.Type__c, s.QuestionDescription__c, s.Akam_Survey_Question_ID__c, s.Id, s.Survey__c, s.Required__c, s.Question__c,
				s.OrderNumber__c, s.Name, s.Choices__c, s.Survey_Question_Group__c, Category__c, UniqueName__c
				From Survey_Question__c s
				WHERE s.Survey__c = :section.Survey__c and s.Survey_Question_Group__c  = :section.Id ORDER BY s.Survey_Question_Group__r.Order_Number__c, s.OrderNumber__c Limit 1
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
			questionGroupWrappers = L2Q_RSSEditTemplateController.cleanWrapper(questionGroupWrappers);
            Test.startTest();
            L2Q_RSSEditTemplateController.saveTemplate(JSON.serialize(questionGroupWrappers), '', '', 'UniqueTest', section.Survey__c);
            L2Q_RSSEditTemplateController.loadWrapper(section.Survey__c);
            L2Q_RSSEditTemplateController.getLatestVersion('testData');
            L2Q_RSSEditTemplateController.updatetemplateName(section.Survey__c,'UpdatedtoUnique');
            L2Q_RSSEditTemplateController.intialData(section.Survey__c);
            Test.stopTest();

		}

		
        
	}

    public static testMethod void verifyDelete()
    {
        Survey_Question_Group__c section = [Select Id,Survey__c from Survey_Question_Group__c where name = 'Section_Unique' Limit 1];
        L2Q_RSSEditTemplateController.deleteQuestion(section.Survey__c);
        L2Q_RSSEditTemplateController.deleteQuestionandgroup(section.Id);
        
    }

    public static testMethod void verifyPublish() {
        Survey_Question_Group__c section = [Select Id,Survey__c from Survey_Question_Group__c where name = 'Section_Unique' Limit 1];
       L2Q_RSSEditTemplateController.publishTemplate(section.Survey__c);
       L2Q_RSSEditTemplateController.reviseTemplate(section.Survey__c);
       L2Q_RSSSurveyQuestion ls0 = new L2Q_RSSSurveyQuestion();
       L2Q_RSSSurveyQuestion.L2Q_SelectOptions ls = new L2Q_RSSSurveyQuestion.L2Q_SelectOptions('test','data');
    }
    
}