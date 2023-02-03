public class RedirectSurveyPageController {
    public string location {get;set;}
    public string surveyID {get;set;}
    // Redirect to respective Pages
    public RedirectSurveyPageController(ApexPages.StandardController controller) {
            try
            {
                surveyID=Apexpages.currentPage().getParameters().get('id');
                survey__c survey;
                for(survey__c s:[select Id,Record_Type_Name__c from survey__c where id = :surveyID])
                {
                    survey = s;
                }
                if(survey.Record_Type_Name__c=='RSS Template')
                {
                    location = '/apex/RSSEditTemplate?id=' +surveyID;
                }
                else
                {
                    location = '/apex/SurveyPage?id=' +surveyID;
                }
            }
            catch(Exception e)
            {
            }
    }

}