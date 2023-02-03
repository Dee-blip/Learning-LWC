/**
 * Created by kusharma on 07/06/17.
 */

public with sharing class ExternalSurveyCtrl {

    String surveyTakenId = ApexPages.currentPage().getParameters().get('id');
    String securityToken = ApexPages.currentPage().getParameters().get('securityToken');
    public Boolean customerResponded {get;set;}
    public Boolean invalidForm {get; set;}
    External_Survey_Taken__c surveyTakenToDisplay;
    List<External_Survey_Taken__c> lExternalSurveyTakenToDisplay {get{ if (lExternalSurveyTakenToDisplay==null) lExternalSurveyTakenToDisplay = new List<External_Survey_Taken__c> (); return lExternalSurveyTakenToDisplay;} set;}
    public List<DataWrapperInnerClass> lDataToDisplayOnPage {get { if (lDataToDisplayOnPage==null) lDataToDisplayOnPage = new List<DataWrapperInnerClass> (); return lDataToDisplayOnPage;} set;}

    public ExternalSurveyCtrl(){
        lExternalSurveyTakenToDisplay = [SELECT Id, Name, Customer_Responded__c,Contact__r.Name,
                                                               External_Survey_Form__r.Name,
                                                               (SELECT Id,Name,Response__c,External_Survey_Question__r.Question__c,External_Survey_Question__r.Question_Options__c,
                                                                       External_Survey_Question__r.Question_Type__c, External_Survey_Question__r.Required_Question__c,
                                                                       External_Survey_Question__r.Question_Sequence__c
                                                                FROM External_Survey_Responses__r
                                                               ORDER BY External_Survey_Question__r.Question_Sequence__c ASC)
                                                               FROM External_Survey_Taken__c
                                                               WHERE Id =:surveyTakenId
                                                               AND Unique_Token__c =:securityToken];

        if( !lExternalSurveyTakenToDisplay.isEmpty()) {
            invalidForm = false;
            for (External_Survey_Taken__c varExtSurvey :lExternalSurveyTakenToDisplay) {
                customerResponded = varExtSurvey.Customer_Responded__c;
                for (External_Survey_Response__c varExtSurveyResponse : varExtSurvey.External_Survey_Responses__r){
                    lDataToDisplayOnPage.add(new DataWrapperInnerClass(varExtSurvey.External_Survey_Form__r.Name,varExtSurveyResponse.External_Survey_Question__r.Question__c, varExtSurveyResponse.External_Survey_Question__r.Question_Type__c,
                            varExtSurveyResponse.External_Survey_Question__r.Question_Options__c, varExtSurveyResponse.Response__c,
                            varExtSurveyResponse.External_Survey_Question__r.Required_Question__c, String.valueOf(varExtSurveyResponse.External_Survey_Question__r.Question_Sequence__c),
                            varExtSurveyResponse.Id,varExtSurvey.Id));
                }
            }
        }
        else{
            invalidForm = true;
        }

        System.debug('### Recs ' + lDataToDisplayOnPage);

    }

    public void submitResponses(){
        System.debug('### inside submitResponses');
        List<External_Survey_Response__c> lSurveyResponseToUpdate = new List<External_Survey_Response__c>();
        for (DataWrapperInnerClass varSurveyResponseToUpdate : lDataToDisplayOnPage) {
            External_Survey_Response__c surveyResponse = new External_Survey_Response__c();
            surveyResponse.Id = varSurveyResponseToUpdate.surveyResponseId;
            surveyResponse.Response__c = varSurveyResponseToUpdate.response;
            surveyResponse.External_Survey_Taken__c = varSurveyResponseToUpdate.surveyTakenId;
            lSurveyResponseToUpdate.add(surveyResponse);
        }
        System.debug('###Object To Update ' + lSurveyResponseToUpdate);
        update lSurveyResponseToUpdate;
        if (!lSurveyResponseToUpdate.isEmpty()) {
            updateSurveyTaken(lSurveyResponseToUpdate);
        }

    }

    private void updateSurveyTaken(List<External_Survey_Response__c> lSurveyResponseToUpdate){
        Set<External_Survey_Taken__c> sExternalSurveyTakenToUpdate = new Set<External_Survey_Taken__c>();
        List<External_Survey_Taken__c> lExternalSurveyTakenToUpdate = new List<External_Survey_Taken__c>();
        for (External_Survey_Response__c varExtSurveyResponse: lSurveyResponseToUpdate) {
            External_Survey_Taken__c varExternalSurveyTaken = new External_Survey_Taken__c();
            varExternalSurveyTaken.Id = varExtSurveyResponse.External_Survey_Taken__c;
            varExternalSurveyTaken.Customer_Responded__c = true;
            sExternalSurveyTakenToUpdate.add(varExternalSurveyTaken);
        }
        lExternalSurveyTakenToUpdate.addAll(sExternalSurveyTakenToUpdate);
        update lExternalSurveyTakenToUpdate;
    }

    public class DataWrapperInnerClass{
        public String surveyFormName{get;set;}
        public List<SelectOption> choices {
            get{
                if(choices == null)
                    choices = new List<SelectOption>();
                return choices;
            }
            set;
        }
        public String question {get;set;}
        public String typeOfQuestion {get;set;}
        public String response{
            get{
                if(response==null)
                    response = '';
                return response;
            }

            set;
        }
        public Boolean requiredQuestion {get;set;}
        public String selectedValue {get; set;}
        public String questionSequence {get;set;}
        public String surveyResponseId {get;set;}
        public List<String> lCheckboxResponses {get{lCheckboxResponses=response.split('\n'); return lCheckboxResponses;}
            set{lCheckboxResponses = value; response= String.join(lCheckboxResponses,'\n');}
        }
        public String surveyTakenId{get;set;}
        public DataWrapperInnerClass(String surveyFormName, String question, String typeOfQuestion,
                                     String choicesString, String response, Boolean requiredQuestion,
                                     String questionSequence, String surveyResponseId, String surveyTakenId){
            this.surveyFormName = surveyFormName;
            this.question = question;
            this.typeOfQuestion = typeOfQuestion;
            this.response = response;
            this.requiredQuestion = requiredQuestion;
            this.questionSequence = questionSequence;
            this.surveyResponseId = surveyResponseId;
            this.surveyTakenId = surveyTakenId;
            if (choicesString != null && choicesString != '') {
                if (typeOfQuestion=='Picklist') {
                    this.choices.add(new SelectOption('None','None'));
                }
                for (String varChoice : choicesString.split('\n')) {
                    this.choices.add(new SelectOption(varChoice.trim(),varChoice.trim()));
                }
            }
        }

    }

}