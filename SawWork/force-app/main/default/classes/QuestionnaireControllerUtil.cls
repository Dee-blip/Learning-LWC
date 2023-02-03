public class QuestionnaireControllerUtil {
	
    public static List<CHIME_Product_Question__c> getQuestionsForSection(String productId, List<String> stage, String sectionName) {
        List<CHIME_Product_Question__c> questionsList = new List<CHIME_Product_Question__c>();
        List<CHIME_Product_Question__c> questionsListExcludingMarkedForDelete = new List<CHIME_Product_Question__c>();
        Map<String,List<CHIME_Product_Question__c>> questionsBySections = getQuestionsRelatedToAdmin(productId,stage,false);
        if (questionsBySections.size() > 0 && questionsBySections.containsKey(sectionName)) {
            questionsList =  questionsBySections.get(sectionName);
            for (CHIME_Product_Question__c q:questionsList) {
                if (!q.Exclusion_marker__c) {
                    questionsListExcludingMarkedForDelete.add(q);
                }
            }
        }
        return questionsListExcludingMarkedForDelete;
    }
    
    public static Map<String,List<CHIME_Product_Question__c>> getQuestionsBySections(String productId, List<String> stage, String chimeid, Boolean isPOC) {
    	Map<String,List<CHIME_Product_Question__c>> sectionToQuestionsMap = new Map<String,List<CHIME_Product_Question__c>>();
        if(chimeid !='' && chimeid !=null ) {
            return getQuestionsRelatedToChime(productId,stage,chimeid,isPOC);
        }
        else{
        	return getQuestionsRelatedToAdmin(productId,stage,true);
        }
    }
    
    public static Map<String,List<CHIME_Product_Question__c>> getQuestionsRelatedToChime(String productId, List<String> stage, String chimeid, Boolean isPOC) {
        
        Id templateId;
        Map<String,List<CHIME_Product_Question__c>> sectionToQuestionsMap = new Map<String,List<CHIME_Product_Question__c>>();
        
        List<Chime_Product_Association__c> listCPA = new List<Chime_Product_Association__c>();
        listCPA = [Select id, 
                   Chime_Product_Template__c  
                   from Chime_Product_Association__c 
                   where CHIME_Product__c =: productId  
                   and CHIME__c  =: chimeid];
        
        if(listCPA[0].Chime_Product_Template__c != null || listCPA[0].Chime_Product_Template__c != ''){
            templateId = listCPA[0].Chime_Product_Template__c;
        }else{
            List<Chime_Product_Template__c> templateList = new List<Chime_Product_Template__c >();
            templateList = [select id,name from Chime_Product_Template__c where Product__c =:productId order by createddate desc limit 1];
            templateId = templateList[0].id;
        }
	
        	System.debug('stages : '+stage);
        	System.debug('productId : '+productId);
        	System.debug('chime id : '+chimeid);
             List<CHIME_Product_Question__c> chimeQuestions = new List<CHIME_Product_Question__c>();

            if(!isPOC){
                Boolean isFullIntegrationQues =true;
                chimeQuestions = [Select id, Section__c, Expected_Response__c, Form_Stage__c,
                                                            Help_Text__c, 
                                                            Language__c , Parent_Question__c ,
                                                            Possible_Response__c , 
                                                            Question_Text__c , 
                                                            Question_Type__c ,
                                                            Restricted__c ,
                                                            Section_Serial_Number__c ,
                                                            Serial_Number__c,Required__c,
                                                            CHIME_Product__c,Template__c,
                                                            POC_question__c,
                                                            Full_Integration_Question__c
                                                            From CHIME_Product_Question__c 
                                                            Where 
                                                            CHIME_Product__c =:productId and (Form_Stage__c IN:stage OR Form_Stage__c = '') and Parent_Question__c = null
                                                            and Full_Integration_Question__c =:isFullIntegrationQues 
                                                            ORDER BY Form_Stage__c asc, Section_Serial_Number__c asc, Serial_Number__c asc]; 
            }else{
                chimeQuestions = [Select id, Section__c, Expected_Response__c, Form_Stage__c,
                                                            Help_Text__c, 
                                                            Language__c , Parent_Question__c ,
                                                            Possible_Response__c , 
                                                            Question_Text__c , 
                                                            Question_Type__c ,
                                                            Restricted__c ,
                                                            Section_Serial_Number__c ,
                                                            Serial_Number__c,Required__c,
                                                            CHIME_Product__c,Template__c,
                                                            POC_question__c,
                                                            Full_Integration_Question__c
                                                            From CHIME_Product_Question__c 
                                                            Where 
                                                            CHIME_Product__c =:productId and (Form_Stage__c IN:stage OR Form_Stage__c = '') and Parent_Question__c = null
                                                            and POC_question__c =:isPOC 
                                                            ORDER BY Form_Stage__c asc, Section_Serial_Number__c asc, Serial_Number__c asc]; 
            }

            system.debug('chimeQuestions'+chimeQuestions);
            for (CHIME_Product_Question__c ques:chimeQuestions) {
                if(ques.Template__c!= null && ques.Template__c !=''){
                    if(ques.Template__c.contains(templateId)){
                        List<CHIME_Product_Question__c> questionsList;
                        if (sectionToQuestionsMap.keySet().contains(ques.Section__c)) {
                            questionsList = sectionToQuestionsMap.get(ques.Section__c);
                        } else {
                            questionsList = new List<CHIME_Product_Question__c>();
                        }
                        questionsList.add(ques);
                        sectionToQuestionsMap.put(ques.Section__c, questionsList);
                    }
                }
            }
        System.debug('sectionToQuestionsMap :'+sectionToQuestionsMap);
        return sectionToQuestionsMap;

    }
    
    public static Map<String,List<CHIME_Product_Question__c>> getQuestionsRelatedToAdmin(String productId, List<String> stage, Boolean resetExclusion) {
        System.debug('Product id :'+productId);
        System.debug('Sage::'+stage);
        Id templateId;
        Map<String,List<CHIME_Product_Question__c>> sectionToQuestionsMap = new Map<String,List<CHIME_Product_Question__c>>();
        List<Chime_Product_Template__c> templateList = new List<Chime_Product_Template__c >();
            templateList = [select id,name from Chime_Product_Template__c where Product__c =:productId order by createddate desc limit 1];
            
            
            List<CHIME_Product_Question__c> chimeQuestions = [Select id, 
                                                                Section__c,
                                                                Expected_Response__c,
                                                                Form_Stage__c,
                                                                Help_Text__c ,
                                                                Language__c ,
                                                                Parent_Question__c ,
                                                                Possible_Response__c ,
                                                                Question_Text__c ,
                                                                Question_Type__c ,
                                                              	Question_Status__c ,
                                                                Restricted__c ,Required__c,
                                                                Section_Serial_Number__c ,
                                                                Serial_Number__c,
                                                              	Exclusion_marker__c ,
                                                                CHIME_Product__c,Template__c,
                                                                POC_question__c,
                                                                Full_Integration_Question__c
                                                              From CHIME_Product_Question__c 
                                                              Where 
                                                              CHIME_Product__c =:productId and (Form_Stage__c IN:stage OR Form_Stage__c = '') and Parent_Question__c = null
                                                             ORDER BY Section_Serial_Number__c asc, Serial_Number__c asc]; 
            
                System.Debug(LoggingLevel.Error, 'AGH_D'+chimeQuestions);
            
                if (chimeQuestions.size() == 0 && templateList.size() <= 0) {
                    //returning empty list
                    return sectionToQuestionsMap;
                }

                string searchstring = '';
                if (templateList.size() > 0) {
                    Chime_Product_Template__c template = templateList[0];
                    searchstring = (String)template.id;
                }
        		
                if (resetExclusion) {
                    for (CHIME_Product_Question__c ques:chimeQuestions) {
                            ques.Exclusion_marker__c = false;
                        }
                        update chimeQuestions;
                }

                for (CHIME_Product_Question__c ques:chimeQuestions) {
                    if(ques.Template__c!= null && ques.Template__c !=''){
                        if(ques.Template__c.contains(searchstring)){
                            List<CHIME_Product_Question__c> questionsList;
                            if (sectionToQuestionsMap.keySet().contains(ques.Section__c)) {
                                questionsList = sectionToQuestionsMap.get(ques.Section__c);
                            } else {
                                questionsList = new List<CHIME_Product_Question__c>();
                            }
                            questionsList.add(ques);
                            sectionToQuestionsMap.put(ques.Section__c, questionsList);
                        }
                    } else {
                        List<CHIME_Product_Question__c> questionsList;
                        if (sectionToQuestionsMap.keySet().contains(ques.Section__c)) {
                            questionsList = sectionToQuestionsMap.get(ques.Section__c);
                        } else {
                            questionsList = new List<CHIME_Product_Question__c>();
                        }
                        questionsList.add(ques);
                        sectionToQuestionsMap.put(ques.Section__c, questionsList);
                    }
                }
        return sectionToQuestionsMap;
    }
    
    public static Boolean createDependentAfterPublish(String oldParentQuestionId, String newParentQuestionId, String templateId) {
        
        Boolean result = true;
        List<CHIME_Product_Question__c> newDependentQuestions = new List<CHIME_Product_Question__c>();
        try {
            if (oldParentQuestionId != null) {
            List<CHIME_Product_Question__c> dependentQuestions = [Select id, 
                                                                     Section__c,
                                                                     Expected_Response__c,
                                                                     Form_Stage__c,
                                                                     Help_Text__c ,
                                                                     Language__c ,
                                                                     Parent_Question__c ,
                                                                     Possible_Response__c ,
                                                                     Question_Text__c ,
                                                                     Question_Type__c ,
                                                                     Restricted__c ,
                                                                     Question_Status__c,
                                                                     Section_Serial_Number__c ,
                                                                     Serial_Number__c,
                                                                     CHIME_Product__c,
                                                                     Dependent_Question_Serial__c,
                                                                     Chime_Product_Template__c,
                                                                     Exclusion_marker__c,
                                                                     Template__c,
                                                                     Required__c
                                                                     From CHIME_Product_Question__c
                                                                     Where Parent_Question__c =:oldParentQuestionId];
            
                List<Chime_Product_Template__c> templateList = new List<Chime_Product_Template__c >();
                templateList = [select id,name from Chime_Product_Template__c where Product__c =:dependentQuestions[0].CHIME_Product__c order by createddate desc limit 1];
                Chime_Product_Template__c template = templateList[0];
                
                List<CHIME_Product_Question__c> relevantDependents = new List<CHIME_Product_Question__c>();
                for (CHIME_Product_Question__c ques:dependentQuestions) {
                    if(ques.Template__c!= null && ques.Template__c !=''){
                        if(ques.Template__c.contains((String)template.id)){
                            relevantDependents.add(ques);
                        }
                    }
                }
                
                if (relevantDependents.size() > 0) {
                    for (CHIME_Product_Question__c dq:relevantDependents) {
                        newDependentQuestions.add(cloneQuestion(dq,newParentQuestionId,templateId));
                    }
                }
            }
        } catch(Exception e) {
            System.debug('Exception occured ::'+e.getMessage());
            return false;
        }
        return result;
    }
    
    public static CHIME_Product_Question__c cloneQuestion(CHIME_Product_Question__c questionToClone, String newQuestionId, String templateId) {
        
        CHIME_Product_Question__c clonedQuestion = null;
        if (questionToClone != null && (newQuestionId != null && newQuestionId != '') && (templateId != null && templateId != '')) {
            clonedQuestion = new CHIME_Product_Question__c();
            if(questionToClone.Section__c !=null)
            clonedQuestion.Section__c = questionToClone.Section__c;
            if(questionToClone.Expected_Response__c !=null)
            clonedQuestion.Expected_Response__c = questionToClone.Expected_Response__c;
            if(questionToClone.Form_Stage__c !=null)
            clonedQuestion.Form_Stage__c = questionToClone.Form_Stage__c;
            if(questionToClone.Help_Text__c !=null)
            clonedQuestion.Help_Text__c  = questionToClone.Help_Text__c;
            if(questionToClone.Language__c !=null)
            clonedQuestion.Language__c  = questionToClone.Language__c;
            if(newQuestionId !=null)
            clonedQuestion.Parent_Question__c = newQuestionId;
            if(questionToClone.Possible_Response__c !=null)
            clonedQuestion.Possible_Response__c = questionToClone.Possible_Response__c;
            if(questionToClone.Question_Text__c !=null)
            clonedQuestion.Question_Text__c = questionToClone.Question_Text__c;
            if(questionToClone.Question_Type__c !=null)
            clonedQuestion.Question_Type__c = questionToClone.Question_Type__c;
            if(questionToClone.Question_Status__c !=null)
            clonedQuestion.Question_Status__c = questionToClone.Question_Status__c;
            if(questionToClone.Restricted__c !=null)
            clonedQuestion.Restricted__c = questionToClone.Restricted__c;
            if(questionToClone.Required__c !=null)
            clonedQuestion.Required__c = questionToClone.Required__c;
            if(questionToClone.Section_Serial_Number__c !=null)
            clonedQuestion.Section_Serial_Number__c = questionToClone.Section_Serial_Number__c;
            if(questionToClone.Serial_Number__c !=null)
            clonedQuestion.Serial_Number__c = questionToClone.Serial_Number__c;
            if(questionToClone.CHIME_Product__c !=null)
            clonedQuestion.CHIME_Product__c = questionToClone.CHIME_Product__c;
            if(templateId !=null)
            clonedQuestion.Template__c = templateId;
            if(questionToClone.Dependent_Question_Serial__c !=null)
            clonedQuestion.Dependent_Question_Serial__c = questionToClone.Dependent_Question_Serial__c;
            if(templateId !=null)
            clonedQuestion.Chime_Product_Template__c = templateId;
            
            insert clonedQuestion;
            QuestionnaireController.changeResponseQuestionMapping(questionToClone.id, clonedQuestion.id, questionToClone.CHIME_Product__c);
        }
        return clonedQuestion;
    }
}