public class RSSQuestionGroupWrapper
{
public Survey_Question_Group__c questionGroup {get;set;}
public List<RSSSurveyQuestion> surveyQuestions {get;set;}
Public static Integer AutoNumber =0;
public Integer UniqueNumber {get;set;}
public String UniqueName {get;set;}
public Integer QuestionCount {get
    {
        Integer Count =0;
        if(surveyQuestions!=null)
        for(RSSSurveyQuestion rsq:surveyQuestions)
        {
            Count++;
        }
        return count;
    }
}
public RSSQuestionGroupWrapper()
{
surveyQuestions = new List<RSSSurveyQuestion>();
questionGroup  = new Survey_Question_Group__c();
AutoNumber++;
UniqueNumber = AutoNumber;
UniqueName = GuidUtil.NewGuid();
}
public RSSQuestionGroupWrapper(Survey_Question_Group__c sqg)
{
    questionGroup = sqg;
    surveyQuestions = new List<RSSSurveyQuestion>();
    AutoNumber++;
    UniqueNumber = AutoNumber;
    UniqueName = GuidUtil.NewGuid();
}

}