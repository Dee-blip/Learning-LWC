public class RSSResponseGroupWrapper
{
public Survey_Question_Group__c questionGroup {get;set;}
public List<RSSQuestionResponse> surveyResponses {get;set;}
public SurveyTaker__c ProductForm {get;set;}
public String ProductFormId {get;set;}
Public static Integer AutoNumber =0;
public Integer UniqueNumber {get;set;}

public RSSResponseGroupWrapper()
{
surveyResponses = new List<RSSQuestionResponse>();
questionGroup  = new Survey_Question_Group__c();
AutoNumber++;
UniqueNumber=AutoNumber;
}
public RSSResponseGroupWrapper(Survey_Question_Group__c sqg)
{
    questionGroup = sqg;
    surveyResponses = new List<RSSQuestionResponse>();
    AutoNumber++;
    UniqueNumber=AutoNumber;
}

}