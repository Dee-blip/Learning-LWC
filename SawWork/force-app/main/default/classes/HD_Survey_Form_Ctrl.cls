/*
* Developer @ Hemant Kumar
* This is controller for Survey Form Builder Ctrl
* Used in HD_Survey_Form Ligtning component
* Using Object Response pattern for lighting 
*/
public  without sharing class HD_Survey_Form_Ctrl {
    @AuraEnabled
    public  List<HD_Survey_Form__c> sform{get;set;}
    @AuraEnabled
    public List<BMCServiceDesk__Incident__c> inc{get;set;}
    @AuraEnabled
    public Id currentUserID {get;set;} 
    @AuraEnabled
    public String currentUserName {get;set;} 
    
    @AuraEnabled
    public Boolean surveyAlreadyTaken{get;set;}
    
    
    @AuraEnabled    
    public static HD_Survey_Form_Ctrl ClassObject(String IncidentId,String Team)
    {
        HD_Survey_Form_Ctrl obj = new HD_Survey_Form_Ctrl();
        List<HD_Survey_Form__c> formWithCategoryList = new List<HD_Survey_Form__c>();
        List<HD_Survey_Form__c> defaultFormList = new List<HD_Survey_Form__c>(); //will store the default template
        List<HD_Survey_Form__c> teamFormList = new List<HD_Survey_Form__c>(); //will store the default template
        try{
            //set the current logged in user
            obj.currentUserID = System.UserInfo.getUserId();
            obj.currentUserName = System.UserInfo.getUserName();
            obj.inc = [select id, Name, BMCServiceDesk__Category_ID__c,HD_Parent_Category__c,BMCServiceDesk__Status_ID__c,HD_Parent_Tree__c,HD_IncidentGroup__c,HD_Ticket_Priority__c,BMCServiceDesk__Type__c from BMCServiceDesk__Incident__c where id =: IncidentId limit 1];
            
            system.debug('-->'+IncidentId);
            system.debug('-->'+Team);
            
            //getting the default form data
            defaultFormList =  [select id, Name,
                                Allow_mutiple_response__c,
                                Available_for_Categories__c,
                                Days_Response_Will_Expire__c,
                                Description__c, 
                                Form_meta__c, 
                                IsActive__c, 
                                Survey_Intro__c, 
                                Survey_Title__c, 
                                Survey_Type__c,
                                Team_Tag__c from HD_Survey_Form__c where Available_for_Categories__c like :('%All%') AND IsActive__c = true limit 1 ];
            
            if(obj.inc.size() > 0) //check if incident related to form exists 
            {
                //getting the relevant form based on the incident category
                formWithCategoryList = [select id, Name,
                                        Allow_mutiple_response__c,
                                        Available_for_Categories__c,
                                        Days_Response_Will_Expire__c,
                                        Description__c, 
                                        Form_meta__c, 
                                        IsActive__c, 
                                        Survey_Intro__c, 
                                        Survey_Title__c,
                                        Survey_Type__c, 
                                        Team_Tag__c from HD_Survey_Form__c where Available_for_Categories__c like :('%'+obj.inc[0].BMCServiceDesk__Category_ID__c+'%') AND IsActive__c = true limit 1 ];
                // obj.sform = [select id, Name, Available_for_Categories__c, Description__c, Form_meta__c, IsActive__c, Survey_Intro__c, Survey_Title__c,Survey_Type__c from HD_Survey_Form__c where Available_for_Categories__c like :('%'+obj.inc[0].BMCServiceDesk__Category_ID__c+'%') limit 1 ]; 
                if(formWithCategoryList.size() > 0 ){
                    obj.sform = formWithCategoryList; //loading the form if the incident team has survey configured
                }else{
                    obj.sform = defaultFormList; //loading default form if the incident category is not configured
                }
            }else if(!String.isBlank(Team)){
                teamFormList = [select id, Name,
                                        Allow_mutiple_response__c,
                                        Available_for_Categories__c,
                                        Days_Response_Will_Expire__c,
                                        Description__c, 
                                        Form_meta__c, 
                                        IsActive__c, 
                                        Survey_Intro__c, 
                                        Survey_Title__c,
                                        Survey_Type__c, 
                                        Team_Tag__c from HD_Survey_Form__c where Available_for_Team__c =: Team limit 1 ];
                if(teamFormList.size() > 0)
                {
                    obj.sform  = teamFormList; //loading the team form
                }
                else{
                    obj.sform = defaultFormList; //loading default form if the incident category is not configured
                }
                //obj.sform = 
            }else{
                obj.sform = defaultFormList; //loading default form if the incident category is not configured
            }
            obj.surveyAlreadyTaken = getUserAlreadyTakensurveyFlag(obj.sform[0].id,obj.sform[0].Allow_mutiple_response__c, obj.inc); //check if user has already taken survey
        }catch(Exception e){ //as usual exception tracking 
            system.debug(e.getMessage());
            system.debug(e.getStackTraceString());
            throw new System.AuraHandledException(e.getMessage());
        }
        return obj;// returns Obj of reponses
    }//
    
    //utility method for Survey already taken for user
    public static boolean getUserAlreadyTakensurveyFlag(Id hdFormId,boolean allowMutlipleResponse, List<BMCServiceDesk__Incident__c> incList){
        boolean surveytakenflag = false;
        Id Current_SurveyUserId = System.UserInfo.getUserId();
        
        if(!allowMutlipleResponse){
            String query = 'Select id from HD_Survey_Response__c where HD_Survey_Form__c = :hdFormId and Response_User__c = :Current_SurveyUserId and Expired_Response__c = false';
            if(incList.size() > 0){
                Id incID = incList[0].Id;
                query = query + ' and Incident__c = :incID';
            }
            query = query + ' LIMIT 1';
            List<HD_Survey_Response__c> survey_RespList = new List<HD_Survey_Response__c>();
            survey_RespList = Database.query(query);
            if(survey_RespList.size() > 0)
            {
                surveytakenflag = true;
            } }//
        return surveytakenflag; 
    }//
    
    //method for saving the responses based on returned JSON object array.
    @AuraEnabled
    public static boolean saveSurveyResponse(List<String> surveyFormResponse, Id survey_form_id, String incident_Id, Id survey_user_Id )
    { 
        system.debug('SurveyFormResponse --> '+SurveyFormResponse );
        system.debug('Survey_form_id --> '+survey_form_id );
        HD_Survey_Form_Ctrl obj = new HD_Survey_Form_Ctrl();
        boolean responsesaveFlag = false;
        List<HD_Survey_Response__c> surveyResponseList = new List<HD_Survey_Response__c>();
        List<String> response = new List<String>();
        try{
            response = surveyFormResponse;
            for(String s : response)
            {   
                s = s.replace('title', 'title_x'); // fix for JSON.deserialize reserve word
                s = s.replace('type', 'type_x'); // fix for JSON.deserialize reserve word
                s = s.replace('value', 'value_x'); // fix for JSON.deserialize reserve word
                s = s.replace('label', 'label_x'); // fix for JSON.deserialize reserve word
                s = s.replace('options', 'options_x'); // fix for JSON.deserialize reserve word
                system.debug(s);
                HD_Survey_Form_Response_Obj  survey_form = (HD_Survey_Form_Response_Obj) JSON.deserialize(s, HD_Survey_Form_Response_Obj.class);
                System.debug(survey_form.title_x+' --> '+survey_form.type_x+' -- > '+survey_form.value_x);
                
                //process for saving the record
                HD_Survey_Response__c surveyResponse = new HD_Survey_Response__c();              
                surveyResponse.HD_Survey_Form__c = survey_form_id;
                if(!String.isBlank(incident_Id))
                {
                    surveyResponse.Incident__c = incident_Id;
                }
                surveyResponse.Question__c = survey_form.title_x;
                surveyResponse.Field_Type__c = survey_form.type_x;
                surveyResponse.Response__c = survey_form.value_x;
                surveyResponse.Response_User__c = survey_user_Id;
                
                
                //adding the record to list
                surveyResponseList.add(surveyResponse	);
                
            }//for
            if(surveyResponseList.size() > 0)
            {
                insert surveyResponseList;
                responsesaveFlag = true;
                return responsesaveFlag;
            }
            
        }//try
        catch(Exception e) //error handling as usual.
        {
            system.debug(e.getMessage());
            system.debug(e.getStackTraceString());
            throw new System.AuraHandledException(e.getMessage());
        }
        return responsesaveFlag;
    }
    
    
}