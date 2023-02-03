/**
 * Created by kusharma on 10/04/17.
 * 
 * CR: FF Upgrade 19.1
 * Developer: Sandeep Naga 
 * Changes: Merging custom metadata from Financial_Force_Custom_Metadata__mdt to PSA_Common_Setting__mdt
 * Date: 28th Novemeber 2018
 * 
 */
//Adding a line to Prod push
 

public with sharing class GSSSurveyFormCtrl {
    public Boolean testCheckbox{get;set;}
    public String typeOfApproval {get;set;}
    public String testForParam {get;set;}
    public GSSSurvey_Survey_Form__c surveyDetailsToDisplay { get {if (surveyDetailsToDisplay == null) surveyDetailsToDisplay = new GSSSurvey_Survey_Form__c(); return surveyDetailsToDisplay;} set; }
    public String responseQuestionOne;
    public String responseQuestionThree;
    public String responseQuestionFour{get;set;}
    public List<GridQuestionResponseWrapper> lHeaderDetails;
    public List<GridQuestionResponseWrapper> lHeaderDetailsCtrl = new List<GridQuestionResponseWrapper>();
    public List<GridQuestionResponseWrapper> lQuesOptionFour;
    public List<GridQuestionResponseWrapper> lQuesFiveDetails;
    public List<GridQuestionResponseWrapper> lQuesSixDetails;
    public Boolean displayButton{get;set;}
    GSSSurvey_Survey_Form__c surveyAlreadySubmitted = new GSSSurvey_Survey_Form__c ();
    String accountId;
    String projectId;
    String surveyId;
    String userId;
    String source;
    String leadershipEmailIds;
    String orgWideEmailId;


    Integer count = 0;

    public GSSSurveyFormCtrl(ApexPages.StandardController controller){
        this();
    }

    public PageReference incrementCounter() {
        count++;
        return null;
    }

    public Integer getCount() {
        return count;
    }
    public List<SelectOption> getQuestionOneChoices() {
        List<SelectOption> options = new List<SelectOption>();
        for(String varChoice : surveyDetailsToDisplay.Choice_Question_One__c.split(';')){
            options.add(new SelectOption(varChoice,varChoice));
        }
        return options;
    }

    public List<GridQuestionResponseWrapper> getLQuesSixDetails(){
        List<GridQuestionResponseWrapper> lHeaderDetails = new List<GridQuestionResponseWrapper>();
        List<String> lChoiceQuestionSix = surveyDetailsToDisplay.Choice_Question_Six__c.split('::')[0].split(';');
        Map<String, String> mQuesSixResponses = new Map<String,String>();
        if (surveyDetailsToDisplay.Response_Six__c != '' && surveyDetailsToDisplay.Response_Six__c != null) {
            for (String varQuesAndResponseString : surveyDetailsToDisplay.Response_Six__c.split('\n')) {
                mQuesSixResponses.put(varQuesAndResponseString.split('::')[0].trim(), varQuesAndResponseString.split('::')[1].trim());
            }
        }

        for (String question : lChoiceQuestionSix) {
            List<SelectOption> options = new List<SelectOption>();
            if (mQuesSixResponses.keySet().isEmpty()) {
                lHeaderDetails.add(new GridQuestionResponseWrapper(question,false,false,false,false,false,false));
            }
            else{
                if (mQuesSixResponses.get(question.trim()).equalsIgnoreCase('Integration/ Provisioning')) {
                    lHeaderDetails.add(new GridQuestionResponseWrapper(question,true,false,false,false,false,false));
                }
                if (mQuesSixResponses.get(question.trim()).equalsIgnoreCase('Ongoing Service Management')) {
                    lHeaderDetails.add(new GridQuestionResponseWrapper(question,false,true,false,false,false,false));
                }
                if (mQuesSixResponses.get(question.trim()).equalsIgnoreCase('Custom Effort')) {
                    lHeaderDetails.add(new GridQuestionResponseWrapper(question,false,false,true,false,false,false));
                }
                if (mQuesSixResponses.get(question.trim()).equalsIgnoreCase('Attack Monitoring/ Mitigation')) {
                    lHeaderDetails.add(new GridQuestionResponseWrapper(question,false,false,false,true,false,false));
                }
                if (mQuesSixResponses.get(question.trim()).equalsIgnoreCase('N/A')) {
                    lHeaderDetails.add(new GridQuestionResponseWrapper(question,false,false,false,false,true,false));
                }
            }


        }
        lQuesSixDetails = lHeaderDetails;
        return lQuesSixDetails;
    }

    public List<GridQuestionResponseWrapper> getLQuesFiveDetails(){
        List<GridQuestionResponseWrapper> lHeaderDetails = new List<GridQuestionResponseWrapper>();
        List<String> lChoiceQuestionFive = surveyDetailsToDisplay.Choice_Question_Five__c.split('::')[0].split(';');
        Map<String, String> mQuesFiveResponses = new Map<String,String>();
        if (surveyDetailsToDisplay.Response_Five__c != '' && surveyDetailsToDisplay.Response_Five__c != null) {
            for (String varQuesAndResponseString : surveyDetailsToDisplay.Response_Five__c.split('\n')) {
                mQuesFiveResponses.put(varQuesAndResponseString.split('::')[0].trim(), varQuesAndResponseString.split('::')[1].trim());
            }
        }

        for (String question : lChoiceQuestionFive) {
            if(mQuesFiveResponses.keySet().isEmpty()) {
                List<SelectOption> options = new List<SelectOption>();
                lHeaderDetails.add(new GridQuestionResponseWrapper(question, false, false, false, false, false, false));
            }
            else{
                if (mQuesFiveResponses.get(question.trim()).equalsIgnoreCase('Exceeded Expectations')) {
                    lHeaderDetails.add(new GridQuestionResponseWrapper(question,true,false,false,false,false,false));
                }
                if (mQuesFiveResponses.get(question.trim()).equalsIgnoreCase('Meet Expectations')) {
                    lHeaderDetails.add(new GridQuestionResponseWrapper(question,false,true,false,false,false,false));
                }
                if (mQuesFiveResponses.get(question.trim()).equalsIgnoreCase('Needs Improvement')) {
                    lHeaderDetails.add(new GridQuestionResponseWrapper(question,false,false,true,false,false,false));
                }

                if (mQuesFiveResponses.get(question.trim()).equalsIgnoreCase('N/A')) {
                    lHeaderDetails.add(new GridQuestionResponseWrapper(question,false,false,false,true,false,false));
                }
            }

        }
        lQuesFiveDetails = lHeaderDetails;
        return lQuesFiveDetails;
    }

    public List<GridQuestionResponseWrapper> getLQuesOptionFour(){
        List<GridQuestionResponseWrapper> lHeaderDetails = new List<GridQuestionResponseWrapper>();
        List<String> lChoiceQuestionFour = surveyDetailsToDisplay.Choice_Question_Four__c.split('::')[0].split(';');

        Map<String, String> mQuesFourResponses = new Map<String,String>();
        if (surveyDetailsToDisplay.Response_Four__c != '' && surveyDetailsToDisplay.Response_Four__c != null) {
            for (String varQuesAndResponseString : surveyDetailsToDisplay.Response_Four__c.split('\n')) {
                mQuesFourResponses.put(varQuesAndResponseString.split('::')[0].trim(), varQuesAndResponseString.split('::')[1].trim());
            }
        }

        for (String question : lChoiceQuestionFour) {
            if(mQuesFourResponses.keySet().isEmpty()) {
                List<SelectOption> options = new List<SelectOption>();
                lHeaderDetails.add(new GridQuestionResponseWrapper(question, false, false, false, false, false, false));
            }
            else{
                if (mQuesFourResponses.get(question.trim()).equalsIgnoreCase('Exceeded Expectations')) {
                    lHeaderDetails.add(new GridQuestionResponseWrapper(question,true,false,false,false,false,false));
                }
                if (mQuesFourResponses.get(question.trim()).equalsIgnoreCase('Meet Expectations')) {
                    lHeaderDetails.add(new GridQuestionResponseWrapper(question,false,true,false,false,false,false));
                }
                if (mQuesFourResponses.get(question.trim()).equalsIgnoreCase('Needs Improvement')) {
                    lHeaderDetails.add(new GridQuestionResponseWrapper(question,false,false,true,false,false,false));
                }

                if (mQuesFourResponses.get(question.trim()).equalsIgnoreCase('N/A')) {
                    lHeaderDetails.add(new GridQuestionResponseWrapper(question,false,false,false,true,false,false));
                }
            }

        }
        lQuesOptionFour = lHeaderDetails;
        return lQuesOptionFour;
    }

    public List<GridQuestionResponseWrapper> getLHeaderDetails(){
        List<GridQuestionResponseWrapper> lHeaderDetails = new List<GridQuestionResponseWrapper>();
        List<String> lChoiceQuestionFour = surveyDetailsToDisplay.Choice_Question_Four__c.split('::')[1].split(';');
        lHeaderDetails.add(new GridQuestionResponseWrapper(lChoiceQuestionFour[0],lChoiceQuestionFour[1],lChoiceQuestionFour[2],lChoiceQuestionFour[3],lChoiceQuestionFour[0],lChoiceQuestionFour[0]));
        List<String> lChoiceQuestionFive = surveyDetailsToDisplay.Choice_Question_Five__c.split('::')[1].split(';');
        lHeaderDetails.add(new GridQuestionResponseWrapper(lChoiceQuestionFive[0],lChoiceQuestionFive[1],lChoiceQuestionFive[2],lChoiceQuestionFive[3],lChoiceQuestionFive[0],lChoiceQuestionFive[0]));
        List<String> lChoiceQuestionSix = surveyDetailsToDisplay.Choice_Question_Six__c.split('::')[1].split(';');
        lHeaderDetails.add(new GridQuestionResponseWrapper(lChoiceQuestionSix[0],lChoiceQuestionSix[1],lChoiceQuestionSix[2],lChoiceQuestionSix[3],lChoiceQuestionSix[4],lChoiceQuestionSix[0]));
        lHeaderDetailsCtrl = lHeaderDetails;
        return lHeaderDetails;
    }

    public String getResponseQuestionOne() {
        if(surveyDetailsToDisplay.Response_One__c != ''){
            responseQuestionOne = surveyDetailsToDisplay.Response_One__c;
        }
        return responseQuestionOne;
    }
    public void setResponseQuestionOne(String responseQuestionOne) {
        this.responseQuestionOne = responseQuestionOne;
    }

    public List<SelectOption> getQuestionThreeChoices() {
        List<SelectOption> options = new List<SelectOption>();
        for(String varChoice : surveyDetailsToDisplay.Choice_Question_Three__c.split(';')){
            options.add(new SelectOption(varChoice,varChoice));
        }
        return options;
    }
    public String getResponseQuestionThree() {
        return responseQuestionThree;
    }
    public void setResponseQuestionThree(String responseQuestionOne) {
        this.responseQuestionThree = responseQuestionOne;
    }

    public GSSSurveyFormCtrl(){
        accountId = ApexPages.currentPage().getParameters().get('accountId');
        projectId = ApexPages.currentPage().getParameters().get('projectId');
        surveyId = ApexPages.currentPage().getParameters().get('surveyId');
        if (surveyId == '' || surveyId==null) {
            surveyId = ApexPages.currentPage().getParameters().get('id');
        }
        userId = UserInfo.getUserId();
        source = ApexPages.currentPage().getParameters().get('source');
        displayButton = true;
        
        //Changes made by sandeep Naga for merging Custom metadata
        /*List<Financial_Force_Custom_Metadata__mdt> lFFCustomMetadata = [SELECT Value__c, Label,DeveloperName FROM Financial_Force_Custom_Metadata__mdt
                                                                        WHERE DeveloperName IN ('IAT_Security_leadership_Email_Id', 'IAT_Org_Wide_Email_Id')];*/
        
        List<PSA_Common_Setting__mdt> lFFCustomMetadata = [SELECT Value__c, Label,DeveloperName FROM PSA_Common_Setting__mdt
                                                                        WHERE DeveloperName IN ('IAT_Security_leadership_Email_Id', 'IAT_Org_Wide_Email_Id') and type__c = 'Financial_Force_Custom_Metadata__mdt'];
        
        
        //for(Financial_Force_Custom_Metadata__mdt varCustomMetadata :lFFCustomMetadata){
        for(PSA_Common_Setting__mdt varCustomMetadata :lFFCustomMetadata){
            if(varCustomMetadata.DeveloperName == 'IAT_Security_leadership_Email_Id'){
                leadershipEmailIds = varCustomMetadata.value__c;
            }
            if(varCustomMetadata.DeveloperName == 'IAT_Org_Wide_Email_Id'){
                orgWideEmailId = varCustomMetadata.value__c;
            }

        }
    }



    public void getSurveyDetailsForUser(){
        List<GSSSurvey_Survey_Form__c> lSurveyForUser = [SELECT Id, OwnerId, IsDeleted, Name, Question_Two__c, Question_Four__c, Account__r.Name,
                Question_Five__c, Question_Six__c, Question_Seven__c, Question_Eight__c, Question_Nine__c, Question_Ten__c,Account__c, Account__r.Division__c,
                Question_Eleven__c, Question_One__c, Question_Three__c, Choice_Question_One__c, Choice_Question_Three__c, Choice_Question_Four__c,
                Choice_Question_Five__c, Choice_Question_Six__c, Response_One__c, Response_Two__c, Response_Three__c, Response_Four__c,Security_Product_Name__c,
                Response_Five__c, Response_Six__c, Response_Seven__c, Response_Eight__c, Response_Nine__c, Response_Ten__c, Response_Eleven__c,
                Project__c, User_Responded__c, User__c FROM GSSSurvey_Survey_Form__c WHERE Id =: surveyId]; // (Account__c = :projectId AND User__c =:userId AND User_Responded__c = false) OR
        System.debug('## lSurveyForUser '  + lSurveyForUser);
        GSSSurvey_Survey_Form__c activeSurveyForm;
        if (!lSurveyForUser.isEmpty() && lSurveyForUser[0].User_Responded__c && source == 'email') {
            GSSSurvey_Survey_Form__c newSurveyFormToCreate = new GSSSurvey_Survey_Form__c();
            newSurveyFormToCreate.User__c = UserInfo.getUserId();
            //newSurveyFormToCreate.Name = 'Security Services Feedback';
            newSurveyFormToCreate.Project__c = lSurveyForUser[0].Project__c;
            newSurveyFormToCreate.Reminder_Date__c = System.now().addDays(7);
            newSurveyFormToCreate.Account__c = lSurveyForUser[0].Account__c;
            newSurveyFormToCreate.Security_Product_Name__c =  lSurveyForUser[0].Security_Product_Name__c;
            insert newSurveyFormToCreate;

            activeSurveyForm = newSurveyFormToCreate;
        }
        else if (!lSurveyForUser.isEmpty()){
            activeSurveyForm = lSurveyForUser[0];
        }
        else{
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'The Survey is invalid'));
        }

        if (activeSurveyForm != null) {
            displaySurveyDetails(activeSurveyForm);
        }


    }

    private void displaySurveyDetails(GSSSurvey_Survey_Form__c activeSurveyForm){
        surveyDetailsToDisplay = [SELECT Id, OwnerId, IsDeleted, Name, Question_Two__c, Question_Four__c,Account__c,User__r.Name,
                Question_Five__c, Question_Six__c, Question_Seven__c, Question_Eight__c, Question_Nine__c, Question_Ten__c, Account__r.Division__c,
                Question_Eleven__c, Question_One__c, Question_Three__c, Choice_Question_One__c, Choice_Question_Three__c, Choice_Question_Four__c,
                Choice_Question_Five__c, Choice_Question_Six__c, Response_One__c, Response_Two__c, Response_Three__c, Response_Four__c,
                Response_Five__c, Response_Six__c, Response_Seven__c, Response_Eight__c, Response_Nine__c, Response_Ten__c, Response_Eleven__c,
                Project__c, User_Responded__c, User__c,Response_Four_1__c,Response_Four_2__c,Response_Four_3__c,Response_Four_4__c,Response_Four_5__c,
                Response_Five_1__c,Response_Five_2__c,Response_Five_3__c,Response_Five_4__c,Response_Five_5__c,Security_Product_Name__c,
                Response_Six_1__c,Response_Six_2__c,Response_Six_3__c,Response_Six_4__c,Response_Six_5__c,Account__r.Name
                FROM GSSSurvey_Survey_Form__c WHERE Id = :activeSurveyForm.Id LIMIT 1];
    }

    public void printResults(){
        String responseForQues4 = '';
        String responseForQues5 = '';
        String responseForQues6 = '';
        /*System.debug('#### Printing lHeaderDetailsCtrl ' + lHeaderDetailsCtrl);
        System.debug('#### Printing lHeaderDetails ' + lHeaderDetails + ' @!@! ' + lQuesFiveDetails);*/
        for(GridQuestionResponseWrapper varResponseQFour: lQuesOptionFour){

            if(varResponseQFour.choiceOneSelected){
                responseForQues4 += varResponseQFour.question + '::' + lHeaderDetailsCtrl[0].headerOne + '\n';
                if (varResponseQFour.question.trim() == 'SA') {
                    surveyDetailsToDisplay.Response_Four_1__c = lHeaderDetailsCtrl[0].headerOne;
                }
                if (varResponseQFour.question.trim() == 'TPM') {
                    surveyDetailsToDisplay.Response_Four_2__c = lHeaderDetailsCtrl[0].headerOne;
                }
                if (varResponseQFour.question.trim() == 'SSP') {
                    surveyDetailsToDisplay.Response_Four_3__c = lHeaderDetailsCtrl[0].headerOne;
                }
                if (varResponseQFour.question.trim() == 'SOC') {
                    surveyDetailsToDisplay.Response_Four_4__c = lHeaderDetailsCtrl[0].headerOne;
                }
                if (varResponseQFour.question.trim() == 'Other') {
                    surveyDetailsToDisplay.Response_Four_5__c = lHeaderDetailsCtrl[0].headerOne;
                }
            }
            if(varResponseQFour.choiceTwoSelected){
                responseForQues4 += varResponseQFour.question + '::' + lHeaderDetailsCtrl[0].headerTwo + '\n';
                if (varResponseQFour.question.trim() == 'SA') {
                    surveyDetailsToDisplay.Response_Four_1__c = lHeaderDetailsCtrl[0].headerTwo;
                }
                if (varResponseQFour.question.trim() == 'TPM') {
                    surveyDetailsToDisplay.Response_Four_2__c = lHeaderDetailsCtrl[0].headerTwo;
                }
                if (varResponseQFour.question.trim() == 'SSP') {
                    surveyDetailsToDisplay.Response_Four_3__c = lHeaderDetailsCtrl[0].headerTwo;
                }
                if (varResponseQFour.question.trim() == 'SOC') {
                    surveyDetailsToDisplay.Response_Four_4__c = lHeaderDetailsCtrl[0].headerTwo;
                }
                if (varResponseQFour.question.trim() == 'Other') {
                    surveyDetailsToDisplay.Response_Four_5__c = lHeaderDetailsCtrl[0].headerTwo;
                }
            }
            if(varResponseQFour.choiceThreeSelected){
                responseForQues4 += varResponseQFour.question + '::' + lHeaderDetailsCtrl[0].headerThree + '\n';
                if (varResponseQFour.question.trim() == 'SA') {
                    surveyDetailsToDisplay.Response_Four_1__c = lHeaderDetailsCtrl[0].headerThree;
                }
                if (varResponseQFour.question.trim() == 'TPM') {
                    surveyDetailsToDisplay.Response_Four_2__c = lHeaderDetailsCtrl[0].headerThree;
                }
                if (varResponseQFour.question.trim() == 'SSP') {
                    surveyDetailsToDisplay.Response_Four_3__c = lHeaderDetailsCtrl[0].headerThree;
                }
                if (varResponseQFour.question.trim() == 'SOC') {
                    surveyDetailsToDisplay.Response_Four_4__c = lHeaderDetailsCtrl[0].headerThree;
                }
                if (varResponseQFour.question.trim() == 'Other') {
                    surveyDetailsToDisplay.Response_Four_5__c = lHeaderDetailsCtrl[0].headerThree;
                }
            }
            if(varResponseQFour.choiceFourSelected){
                responseForQues4 += varResponseQFour.question + '::' + lHeaderDetailsCtrl[0].headerFour + '\n';
                if (varResponseQFour.question.trim() == 'SA') {
                    surveyDetailsToDisplay.Response_Four_1__c = lHeaderDetailsCtrl[0].headerFour;
                }
                if (varResponseQFour.question.trim() == 'TPM') {
                    surveyDetailsToDisplay.Response_Four_2__c = lHeaderDetailsCtrl[0].headerFour;
                }
                if (varResponseQFour.question.trim() == 'SSP') {
                    surveyDetailsToDisplay.Response_Four_3__c = lHeaderDetailsCtrl[0].headerFour;
                }
                if (varResponseQFour.question.trim() == 'SOC') {
                    surveyDetailsToDisplay.Response_Four_4__c = lHeaderDetailsCtrl[0].headerFour;
                }
                if (varResponseQFour.question.trim() == 'Other') {
                    surveyDetailsToDisplay.Response_Four_5__c = lHeaderDetailsCtrl[0].headerFour;
                }
            }
        }

        for(GridQuestionResponseWrapper varResponseQFive: lQuesFiveDetails){
            if(varResponseQFive.choiceOneSelected){
                responseForQues5 += varResponseQFive.question + '::' + lHeaderDetailsCtrl[1].headerOne + '\n';
                if (varResponseQFive.question.trim() == 'SA') {
                    surveyDetailsToDisplay.Response_Five_1__c = lHeaderDetailsCtrl[1].headerOne;
                }
                if (varResponseQFive.question.trim() == 'TPM') {
                    surveyDetailsToDisplay.Response_Five_2__c = lHeaderDetailsCtrl[1].headerOne;
                }
                if (varResponseQFive.question.trim() == 'SSP') {
                    surveyDetailsToDisplay.Response_Five_3__c = lHeaderDetailsCtrl[1].headerOne;
                }
                if (varResponseQFive.question.trim() == 'SOC') {
                    surveyDetailsToDisplay.Response_Five_4__c = lHeaderDetailsCtrl[1].headerOne;
                }
                if (varResponseQFive.question.trim() == 'Other') {
                    surveyDetailsToDisplay.Response_Five_5__c = lHeaderDetailsCtrl[1].headerOne;
                }
            }
            if(varResponseQFive.choiceTwoSelected){
                responseForQues5 += varResponseQFive.question + '::' + lHeaderDetailsCtrl[1].headerTwo + '\n';
                if (varResponseQFive.question.trim() == 'SA') {
                    surveyDetailsToDisplay.Response_Five_1__c = lHeaderDetailsCtrl[1].headerTwo;
                }
                if (varResponseQFive.question.trim() == 'TPM') {
                    surveyDetailsToDisplay.Response_Five_2__c = lHeaderDetailsCtrl[1].headerTwo;
                }
                if (varResponseQFive.question.trim() == 'SSP') {
                    surveyDetailsToDisplay.Response_Five_3__c = lHeaderDetailsCtrl[1].headerTwo;
                }
                if (varResponseQFive.question.trim() == 'SOC') {
                    surveyDetailsToDisplay.Response_Five_4__c = lHeaderDetailsCtrl[1].headerTwo;
                }
                if (varResponseQFive.question.trim() == 'Other') {
                    surveyDetailsToDisplay.Response_Five_5__c = lHeaderDetailsCtrl[1].headerTwo;
                }
            }
            if(varResponseQFive.choiceThreeSelected){
                responseForQues5 += varResponseQFive.question + '::' + lHeaderDetailsCtrl[1].headerThree + '\n';
                if (varResponseQFive.question.trim() == 'SA') {
                    surveyDetailsToDisplay.Response_Five_1__c = lHeaderDetailsCtrl[1].headerThree;
                }
                if (varResponseQFive.question.trim() == 'TPM') {
                    surveyDetailsToDisplay.Response_Five_2__c = lHeaderDetailsCtrl[1].headerThree;
                }
                if (varResponseQFive.question.trim() == 'SSP') {
                    surveyDetailsToDisplay.Response_Five_3__c = lHeaderDetailsCtrl[1].headerThree;
                }
                if (varResponseQFive.question.trim() == 'SOC') {
                    surveyDetailsToDisplay.Response_Five_4__c = lHeaderDetailsCtrl[1].headerThree;
                }
                if (varResponseQFive.question.trim() == 'Other') {
                    surveyDetailsToDisplay.Response_Five_5__c = lHeaderDetailsCtrl[1].headerThree;
                }
            }
            if(varResponseQFive.choiceFourSelected){
                responseForQues5 += varResponseQFive.question + '::' + lHeaderDetailsCtrl[1].headerFour + '\n';
                if (varResponseQFive.question.trim() == 'SA') {
                    surveyDetailsToDisplay.Response_Five_1__c = lHeaderDetailsCtrl[1].headerFour;
                }
                if (varResponseQFive.question.trim() == 'TPM') {
                    surveyDetailsToDisplay.Response_Five_2__c = lHeaderDetailsCtrl[1].headerFour;
                }
                if (varResponseQFive.question.trim() == 'SSP') {
                    surveyDetailsToDisplay.Response_Five_3__c = lHeaderDetailsCtrl[1].headerFour;
                }
                if (varResponseQFive.question.trim() == 'SOC') {
                    surveyDetailsToDisplay.Response_Five_4__c = lHeaderDetailsCtrl[1].headerFour;
                }
                if (varResponseQFive.question.trim() == 'Other') {
                    surveyDetailsToDisplay.Response_Five_5__c = lHeaderDetailsCtrl[1].headerFour;
                }
            }
        }

        for(GridQuestionResponseWrapper varResponseQSix: lQuesSixDetails){
            if(varResponseQSix.choiceOneSelected){
                responseForQues6 += varResponseQSix.question + '::' + lHeaderDetailsCtrl[2].headerOne + '\n';
                if (varResponseQSix.question.trim() == 'Prolexic Family') {
                    surveyDetailsToDisplay.Response_Six_1__c = lHeaderDetailsCtrl[2].headerOne;
                }
                if (varResponseQSix.question.trim() == 'Kona Family') {
                    surveyDetailsToDisplay.Response_Six_2__c = lHeaderDetailsCtrl[2].headerOne;
                }
                if (varResponseQSix.question.trim() == 'Bot Manager') {
                    surveyDetailsToDisplay.Response_Six_3__c = lHeaderDetailsCtrl[2].headerOne;
                }
                if (varResponseQSix.question.trim() == 'Client Reputation') {
                    surveyDetailsToDisplay.Response_Six_4__c = lHeaderDetailsCtrl[2].headerOne;
                }
                if (varResponseQSix.question.trim() == 'Other') {
                    surveyDetailsToDisplay.Response_Six_5__c = lHeaderDetailsCtrl[2].headerOne;
                }
            }
            if(varResponseQSix.choiceTwoSelected){
                responseForQues6 += varResponseQSix.question + '::' + lHeaderDetailsCtrl[2].headerTwo + '\n';
                if (varResponseQSix.question.trim() == 'Prolexic Family') {
                    surveyDetailsToDisplay.Response_Six_1__c = lHeaderDetailsCtrl[2].headerTwo;
                }
                if (varResponseQSix.question.trim() == 'Kona Family') {
                    surveyDetailsToDisplay.Response_Six_2__c = lHeaderDetailsCtrl[2].headerTwo;
                }
                if (varResponseQSix.question.trim() == 'Bot Manager') {
                    surveyDetailsToDisplay.Response_Six_3__c = lHeaderDetailsCtrl[2].headerTwo;
                }
                if (varResponseQSix.question.trim() == 'Client Reputation') {
                    surveyDetailsToDisplay.Response_Six_4__c = lHeaderDetailsCtrl[2].headerTwo;
                }
                if (varResponseQSix.question.trim() == 'Other') {
                    surveyDetailsToDisplay.Response_Six_5__c = lHeaderDetailsCtrl[2].headerTwo;
                }
            }
            if(varResponseQSix.choiceThreeSelected){
                responseForQues6 += varResponseQSix.question + '::' + lHeaderDetailsCtrl[2].headerThree + '\n';
                if (varResponseQSix.question.trim() == 'Prolexic Family') {
                    surveyDetailsToDisplay.Response_Six_1__c = lHeaderDetailsCtrl[2].headerThree;
                }
                if (varResponseQSix.question.trim() == 'Kona Family') {
                    surveyDetailsToDisplay.Response_Six_2__c = lHeaderDetailsCtrl[2].headerThree;
                }
                if (varResponseQSix.question.trim() == 'Bot Manager') {
                    surveyDetailsToDisplay.Response_Six_3__c = lHeaderDetailsCtrl[2].headerThree;
                }
                if (varResponseQSix.question.trim() == 'Client Reputation') {
                    surveyDetailsToDisplay.Response_Six_4__c = lHeaderDetailsCtrl[2].headerThree;
                }
                if (varResponseQSix.question.trim() == 'Other') {
                    surveyDetailsToDisplay.Response_Six_5__c = lHeaderDetailsCtrl[2].headerThree;
                }
            }
            if(varResponseQSix.choiceFourSelected){
                responseForQues6 += varResponseQSix.question + '::' + lHeaderDetailsCtrl[2].headerFour + '\n';
                if (varResponseQSix.question.trim() == 'Prolexic Family') {
                    surveyDetailsToDisplay.Response_Six_1__c = lHeaderDetailsCtrl[2].headerFour;
                }
                if (varResponseQSix.question.trim() == 'Kona Family') {
                    surveyDetailsToDisplay.Response_Six_2__c = lHeaderDetailsCtrl[2].headerFour;
                }
                if (varResponseQSix.question.trim() == 'Bot Manager') {
                    surveyDetailsToDisplay.Response_Six_3__c = lHeaderDetailsCtrl[2].headerFour;
                }
                if (varResponseQSix.question.trim() == 'Client Reputation') {
                    surveyDetailsToDisplay.Response_Six_4__c = lHeaderDetailsCtrl[2].headerFour;
                }
                if (varResponseQSix.question.trim() == 'Other') {
                    surveyDetailsToDisplay.Response_Six_5__c = lHeaderDetailsCtrl[2].headerFour;
                }
            }
            if(varResponseQSix.choiceFiveSelected){
                responseForQues6 += varResponseQSix.question + '::' + lHeaderDetailsCtrl[2].headerFive + '\n';
                if (varResponseQSix.question.trim() == 'Prolexic Family') {
                    surveyDetailsToDisplay.Response_Six_1__c = lHeaderDetailsCtrl[2].headerFive;
                }
                if (varResponseQSix.question.trim() == 'Kona Family') {
                    surveyDetailsToDisplay.Response_Six_2__c = lHeaderDetailsCtrl[2].headerFive;
                }
                if (varResponseQSix.question.trim() == 'Bot Manager') {
                    surveyDetailsToDisplay.Response_Six_3__c = lHeaderDetailsCtrl[2].headerFive;
                }
                if (varResponseQSix.question.trim() == 'Client Reputation') {
                    surveyDetailsToDisplay.Response_Six_4__c = lHeaderDetailsCtrl[2].headerFive;
                }
                if (varResponseQSix.question.trim() == 'Other') {
                    surveyDetailsToDisplay.Response_Six_5__c = lHeaderDetailsCtrl[2].headerFive;
                }
            }
        }

        surveyDetailsToDisplay.Response_Four__c = responseForQues4;
        surveyDetailsToDisplay.Response_Five__c = responseForQues5;
        surveyDetailsToDisplay.Response_Six__c = responseForQues6;
        surveyDetailsToDisplay.User_Responded__c = true;
        displayButton = false;
        update surveyDetailsToDisplay;
        sendConfirmationEmail();
        System.debug('@@@@ response all ' + surveyDetailsToDisplay);
    }

    private void sendConfirmationEmail(){
        Messaging.SingleEmailMessage singleEmailMessage = new Messaging.SingleEmailMessage();
        singleEmailMessage.setSubject(surveyDetailsToDisplay.Account__r.Name + ' - ' + surveyDetailsToDisplay.Security_Product_Name__c + ' - ' + 'Security Services Survey Response Received' );
        singleEmailMessage.setPlainTextBody('A survey response has been received and can be found below \n' + URL.getSalesforceBaseUrl().toExternalForm()+ '/apex/GSSSurveyForm?surveyId=' + surveyDetailsToDisplay.Id + '&source=viewURL' +'\n\n Thank you, \n Global Security Services' );
        singleEmailMessage.setToAddresses(leadershipEmailIds.split(';'));
        singleEmailMessage.setOrgWideEmailAddressId(orgWideEmailId);
        singleEmailMessage.setSaveAsActivity(false);
        Messaging.sendEmail(new List<Messaging.Singleemailmessage> {singleEmailMessage});
    }

    public Class GridQuestionResponseWrapper{
        public String optionOne {get; set;}
        public String optionTwo {get; set;}
        public String optionThree {get; set;}
        public String optionFour {get; set;}
        public String optionFive {get; set;}
        public String optionSix {get; set;}
        public String optionSeven {get; set;}
        public Boolean choiceOneSelected {get; set;}
        public Boolean choiceTwoSelected {get; set;}
        public Boolean choiceThreeSelected {get; set;}
        public Boolean choiceFourSelected {get; set;}
        public Boolean choiceFiveSelected {get; set;}
        public Boolean choiceSixSelected {get; set;}
        public String question {get; set;}
        public String questionOne {get; set;}
        public String questionTwo {get; set;}
        public String questionThree {get; set;}
        public String questionFour {get; set;}
        public String questionFive {get; set;}
        public String questionSix {get; set;}
        public String headerOne {get; set;}
        public String headerTwo {get; set;}
        public String headerThree {get; set;}
        public String headerFour {get; set;}
        public String headerFive {get; set;}
        public String headerSix {get; set;}
        public List<SelectOption> lSelectOptions{get;set;}

        public GridQuestionResponseWrapper(String question, Boolean choiceOneSelected, Boolean choiceTwoSelected, Boolean choiceThreeSelected, Boolean choiceFourSelected, Boolean choiceFiveSelected, Boolean choiceSixSelected){
            this.question = question;
            this.choiceOneSelected = choiceOneSelected;
            this.choiceTwoSelected = choiceTwoSelected;
            this.choiceThreeSelected = choiceThreeSelected;
            this.choiceFourSelected = choiceFourSelected;
            this.choiceFiveSelected = choiceFiveSelected;
            this.choiceSixSelected = false;

        }

        public GridQuestionResponseWrapper(String headerOne, String headerTwo, String headerThree, String headerFour, String headerFive, String headerSix){
            this.headerOne = headerOne;
            this.headerTwo = headerTwo;
            this.headerThree = headerThree;
            this.headerFour = headerFour;
            this.headerFive = headerFive;
            this.headerSix = headerSix;

        }

        public GridQuestionResponseWrapper (String question , List<SelectOption> lSelectOptions){
            this.question = question;
            this.lSelectOptions = lSelectOptions;
        }


    }
}