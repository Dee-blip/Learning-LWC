public  class L2Q_RSSQuestionGroupWrapper {
public Survey_Question_Group__c questionGroup {get;set;}
public List<L2Q_RSSSurveyQuestion> surveyQuestions {get;set;}
Public static Integer AutoNumber =0;
public Integer UniqueNumber {get;set;}
public String UniqueName {get;set;}
public Integer QuestionCount {get
    {
        Integer Count =0;
        if(surveyQuestions!=null)
        for(L2Q_RSSSurveyQuestion rsq:surveyQuestions)
        {
            Count++;
        }
        return count;
    }
}
public L2Q_RSSQuestionGroupWrapper()
{
surveyQuestions = new List<L2Q_RSSSurveyQuestion>();
questionGroup  = new Survey_Question_Group__c();
UniqueNumber = null;
UniqueName = null;
}
public L2Q_RSSQuestionGroupWrapper(Survey_Question_Group__c sqg)
{
    questionGroup = sqg;
    surveyQuestions = new List<L2Q_RSSSurveyQuestion>();
    UniqueNumber = null;
    UniqueName = null;
}

}