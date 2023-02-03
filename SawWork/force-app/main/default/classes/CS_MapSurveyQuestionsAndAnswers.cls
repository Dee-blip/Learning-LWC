//CR 935416: Read the salesforce name value pair custom object to process the survey results & update contact's survey results summary fields
public class CS_MapSurveyQuestionsAndAnswers {

/*
CR 963120 - NPS Icon next to the NPS Score in Survey Details Visualforce page
Description: the function getIcon() send the image URL over to the VF page
Author - Sharath
Modified - 02/15/2011
Modified: Sharath 03/20/2011 
Modified: Janantha 06/16/2011
CR 1021287 CSAT: Use IsDeleted in all of the SQLs while accessing Survey Custom Objects
Sharath 05/19/2011
CR 1112835 CSAT: Contacts Update Apex Job to directly update Survey Contacts 
    - creating new fileds at Contact level that reference fields at Survey Contact object. Hence changes are needed here.
CR 1159273 - Fetch the Survey Contact details to display the history information.
CR 1623766 CSAT: Q22012 Updates to Survey Details page - adding product area and product score to the Page, hence need to be added in SOQL

*/   
    //Start of changes by Janantha for CR 1159273
    public String getIconForSurveyContact() {
        String var1;
        // retrieve the Organization Id, which is required to display the image placed in the Documents folder
        String var2 = [select Id from Organization limit 1 ][0].Id;
        CS_ImagesForCSAT__c orgValues = CS_ImagesForCSAT__c.getOrgDefaults();
        // based on NPSResponseText , retrieve the appropriate image/icon
        if(surveyContactDetail.CS_Classification__c == 'Promoter'){
         var1 = orgValues.CS_PromoterIdSmall__c;
        }
        else if(surveyContactDetail.CS_Classification__c == 'Detractor'){
         var1 = orgValues.CS_DetractorIdSmall__c;
        }
        else if(surveyContactDetail.CS_Classification__c == 'Passive'){
         var1 = orgValues.CS_PassiveIdSmall__c;
        }
        else if(surveyContactDetail.CS_Classification__c == 'None'){
         var1 = orgValues.CS_NotRespondedIdSmall__c;
        }
        // url to be returned, which will be rendered on Page
        String retVal = '/servlet/servlet.ImageServer?id=' + var1 + '&oid=' + var2;
            return retVal ;
    }
    //End of changes by Janantha for CR 1159273

    //Start of changes by Janantha for CR 1159273
    public CS_SurveyContacts__c getSurveyContact() {
        return surveyContactDetail;
    }
    //End of changes by Janantha for CR 1159273

    List<String> fields =new List<String>();
    Map<String,String> nvFieldQuestionMap= new Map<String,String>();
    List<CS_TempMapClass> questionAndAnswerList=new List<CS_TempMapClass>();
    List< CS_SurveyResponseNameValue__c> surveyNameValueRows= new List<CS_SurveyResponseNameValue__c>();
    Map<String,String> nvFieldquestionNumberMap = new Map<String,String>();
    Map<Integer,String> qNumberNVFieldmap = new Map<Integer,String>();
    //Start of changes by Janantha for CR 1159273
    CS_SurveyContacts__c surveyContactDetail = new CS_SurveyContacts__c();
    //End of changes by Janantha for CR 1159273
    String akamContactId;
    String contactName;
    //Start of changes by Janantha for CR 1159273
    String surveyContactId;
    //End of changes by Janantha for CR 1159273
    String surveyRecordId;
    String latestSurveyResponse;
    
    void init(){   
    //Start of changes by Janantha for CR 1159273
    // retrive Survey Contact Id from URL
    surveyContactId=ApexPages.currentPage().getParameters().get('id');
    //End of changes by Janantha for CR 1159273
    // CR 1112835 - Changing the fields in SOQL - new fields at Contact reference survey Contact object fields   
    //Start of changes by Janantha for CR 1159273
    // 12/4/2012 - CR 1623766  - querying product area and product score additionally
    surveyContactDetail=[select CS_Contact__r.Account.Name,CS_FeedbackPeriod__c,CS_OverallSatisfaction__c,CS_ProductArea__c,CS_ProductScore__c,CS_NPS__c,CS_ProductSatisfaction__c,CS_ImplementationProcessSatisfaction__c,CS_BusinessSupportSatisfaction__c,CS_LikelihoodToRecommend__c,CS_EdgeControlSatisfaction__c,CS_SalesProcessSatisfaction__c,CS_FeedbackReceivedDate__c,CS_CustomerCareSatisfaction__c,CS_BillingOperationsSatisfaction__c,CS_Contact__r.AKAM_Contact_ID__c,CS_Contact__r.Name,CS_SurveyResponseSyncId__c,CS_Classification__c from CS_SurveyContacts__c where Id=:surveyContactId][0];
    
    //End of changes by Janantha for CR 1159273
    
    
    //Start of changes by Janantha for CR 1159273
    akamContactId = surveyContactDetail.CS_Contact__r.AKAM_Contact_ID__c;
    contactName = surveyContactDetail.CS_Contact__r.Name;
    latestSurveyResponse = surveyContactDetail.CS_SurveyResponseSyncId__c;
    //End of changes by Janantha for CR 1159273
    
    // retrieve the survey Id 
    String surveyId = [select CS_Survey__c from CS_SurveyResponse__c where Id = :latestSurveyResponse and (CS_IsDeleted__c = false)][0].CS_Survey__c;
    // retrieve all questions from questionnaire for a particular survey and create a map of (FieldToBeMappedTo, Question)
    List<CS_SurveyQuestion__c> questionsList= [select CS_Question__c,CS_MaptoField__c,CS_QuestionNumber__c from CS_SurveyQuestion__c where CS_IsDeleted__c = false AND (CS_QuestionSet__r.CS_QuestionnareNumber__r.CS_SurveyId__c = :surveyId) order by CS_QuestionNumber__c asc];
    for(CS_SurveyQuestion__c question:questionsList){
    fields.add(question.CS_MaptoField__c);
        nvFieldQuestionMap.put(question.CS_MaptoField__c,question.CS_Question__c);
        nvFieldquestionNumberMap.put(question.CS_MaptoField__c,question.CS_QuestionNumber__c.format());
        qNumberNVFieldmap.put(question.CS_QuestionNumber__c.intValue(),question.CS_MaptoField__c);
        }
    }
    
    class CS_TempMapClass{
        private String question;
        private String answer;
        private String questionNumber;
        
        public String getAnswer()
        {
            return answer;
        }
        public String getQuestion(){
            return question;
        }
        public String getQuestionNumber(){
            return questionNumber;
        }
        
    }
    
    public List<CS_TempMapClass> getMapping(){
        try{
            init();
            // select the record Id for the contact from Name-Value pair table
            surveyRecordId=[select CS_RecordId__c from CS_SurveyResponseNameValue__c where CS_Value__c= :akamContactId and (CS_SurveyResponse__c = :latestSurveyResponse) AND (CS_IsDeleted__c = false)][0].CS_RecordId__c;
            // retrive all the name value pairs fot the particular contact. The names should match with FieldToBeMappedTo 
            surveyNameValueRows = [select CS_Name__c, CS_Value__c from  CS_SurveyResponseNameValue__c where CS_RecordId__c=:surveyRecordId and (CS_Name__c in :fields) and (CS_SurveyResponse__c = :latestSurveyResponse) AND (CS_IsDeleted__c = false)];
            Map<String,String> nvResults = new Map<String,String>();
            for(CS_SurveyResponseNameValue__c nvRow : surveyNameValueRows){
                nvResults.put(nvRow.CS_Name__c , nvRow.CS_Value__c);
                }
            /*
            Map the Question to respective answers and add them to a list in Sequence
            Adding keySet, qNumberNVFieldmap  to get the results in sorted order - order by question number
            */
            Set<Integer> keys = qNumberNVFieldmap.keySet();
            List<Integer> keySet = new List<Integer>();
            keySet.addAll(keys);
            keySet.sort();
            for(Integer i =0; i< keySet.size(); i++){
            CS_TempMapClass tempMap = new CS_TempMapClass();
            Integer key = keySet[i];
            tempMap.question= nvFieldQuestionMap.get(qNumberNVFieldmap.get(key));
            tempMap.questionNumber = nvFieldquestionNumberMap.get(qNumberNVFieldmap.get(key));
            tempMap.answer= nvResults.get(qNumberNVFieldmap.get(key));
            if(tempMap.question != null && (tempMap.answer != null && tempMap.answer != '' && tempMap.answer != '.')){
                questionAndAnswerList.add(tempMap);
                }
            }
        }
        catch(ListException e){
            ApexPages.Message myMsg;
            if(e.getMessage()=='List index out of bounds: 0'){
            // Modified - 2/16/2011 (Sharath) - changed error message to be more generic , also changed ApexPages.Severity.ERROR to ApexPages.Severity.INFO
                myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Sorry, details for the contact couldn\'t be retrieved ');
            }
            else{
                 myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'Some error seems to have occured ');
            }
            ApexPages.addMessage(myMsg);
        }
        if(questionAndAnswerList.size()>0){
        return questionAndAnswerList;
        }
        else{
            return null;
        }
    } 
}