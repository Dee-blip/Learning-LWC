/**

**/
public without sharing class QuestionnaireController {
    
    @AuraEnabled
    public static Chime_Product_Template__c getProductActiveTemplate(String productId) {
        
        List<Chime_Product_Template__c> chimeProductTemplateList = [Select id, 
                                                                        Active__c,
                                                                        Product__c,
                                                                        Template_Number__c
                                                                      From Chime_Product_Template__c 
                                                                      Where Product__c =:productId and Active__c = true
                                                                     ORDER BY LastModifiedDate desc]; 
        
        if (chimeProductTemplateList.size() > 0) {
            return chimeProductTemplateList[0];
        } else {
            return null;
        }
    }
    
    @AuraEnabled
    public static Map<String,List<CHIME_Product_Question__c>> getQuestionsForAdmin(String productId) {
        List<String> stagesList = new List<String>();
        stagesList.add('Gating');
        stagesList.add('Scoping');
        return getQuestions(productId,stagesList,'',false);
    }
    
    @AuraEnabled
    public static Map<String,List<CHIME_Product_Question__c>> getQuestions(String productId, String stage, String chimeid, Boolean isPOC) {
        List<String> stagesList;
        if(String.isBlank(stage))
        {
            stagesList = new List<String>{'Gating', 'Scoping'};   
        }
        else
        {
            stagesList = stage.split(',');
        }
        return getQuestions(productId,stagesList,chimeid,isPOC);
    }
    
    @AuraEnabled
    public static Map<String,List<CHIME_Product_Question__c>> getQuestions(String productId, List<String> stage, String chimeid, Boolean isPOC) {
        return QuestionnaireControllerUtil.getQuestionsBySections(productId, stage, chimeid,isPOC);
    }
    
    @AuraEnabled
    public static List<CHIME_Product_Question__c> getQuestionsForSection(String sectionName, String productId) {
        List<String> stagesList = new List<String>{'Gating','Scoping'};
        return QuestionnaireControllerUtil.getQuestionsForSection(productId, stagesList, sectionName);
    }
    
    @AuraEnabled
    public static List<CHIME_Product_Question__c> getQuestionsById(String questionId) {
        //System.debug('sctionName :'+sectionName);
        
        List<CHIME_Product_Question__c> questionsList = [Select id, 
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
                                                                Exclusion_marker__c,
                                                                CHIME_Product__c,Template__c
                                                          From CHIME_Product_Question__c
                                                          Where id =:questionId];
        
        return questionsList;
    }
    
    @AuraEnabled
    public static List<CHIME_Product_Question__c> moveQuestion(String productId, String questionId, String sectionName, Boolean moveUp) {
        CHIME_Product_Question__c lastQuestion;
        Boolean updateNext = false;
        List<CHIME_Product_Question__c> updatedQuestionsList = new List<CHIME_Product_Question__c>();
        
        List<String> stagesList = new List<String>{'Gating','Scoping'};
        List<CHIME_Product_Question__c> questionsList = QuestionnaireControllerUtil.getQuestionsForSection(productId, stagesList, sectionName);
        
        // get the max serial number
        Decimal maxSN = 1;
        for (CHIME_Product_Question__c ques:questionsList) {
            if(ques.Serial_Number__c > maxSN)
                maxSN = ques.Serial_Number__c;
        }
        for (CHIME_Product_Question__c ques:questionsList) {
            if (ques.id == questionId) {
                System.debug('Question id maches :'+questionId);
                if (moveUp) {
                    ques.Serial_Number__c = math.max(1, ques.Serial_Number__c -1 );
                    if (lastQuestion != null) {
                        lastQuestion.Serial_Number__c =math.min(maxSN, lastQuestion.Serial_Number__c + 1);
                        updatedQuestionsList.add(lastQuestion);
                    }
                } else {
                    ques.Serial_Number__c = math.min(maxSN, ques.Serial_Number__c + 1);
                    updateNext = true;
                } 
                updatedQuestionsList.add(ques);
            } else {
                lastQuestion = ques;
                if (updateNext) {
                    updateNext = !updateNext;
                    ques.Serial_Number__c = math.max(1, ques.Serial_Number__c -1 );
                    updatedQuestionsList.add(ques);
                }
            }
        }
        if (updatedQuestionsList.size() > 0) {
            update updatedQuestionsList;
        }
        return updatedQuestionsList;
    }

    @AuraEnabled
    public static List<CHIME_Product_Question__c> updateSectionAfterDelete(String sectionName, String productId) {
        System.debug('sctionName :'+sectionName);
        Integer questionSerial = 1;
        
        List<String> stagesList = new List<String>{'Gating','Scoping'};
        
        CHIME_Product_Question__c questionToDelete = null;
        List<CHIME_Product_Question__c> updatedQuestions = new List<CHIME_Product_Question__c>();

        List<CHIME_Product_Question__c> questionsList = QuestionnaireControllerUtil.getQuestionsForSection(productId, stagesList, sectionName);
        
        for (CHIME_Product_Question__c ques:questionsList) {
            ques.Serial_Number__c = questionSerial;
            questionSerial += 1;
            updatedQuestions.add(ques);
            
        }
        
        if (updatedQuestions.size() > 0) {
            update updatedQuestions;
        }
        
        return updatedQuestions;
    }
    
    @AuraEnabled
    public static List<CHIME_Product_Question__c> getDependentQuestionsForParent(String parentQuestionId, String expectionResponse, String productId) {
        System.debug('parentQuestionId :'+parentQuestionId);
        System.debug('expected response :'+expectionResponse);
        String expected = expectionResponse.replace('\r', '');
        System.debug(expected);
        
        System.debug('Product id :'+productId);
        Id templateId;
        //Map<String,List<CHIME_Product_Question__c>> sectionToQuestionsMap = new Map<String,List<CHIME_Product_Question__c>>();
        List<Chime_Product_Template__c> templateList = new List<Chime_Product_Template__c >();
            templateList = [select id,name from Chime_Product_Template__c where Product__c =:productId order by createddate desc limit 1];
        
        List<CHIME_Product_Question__c> responseList = new List<CHIME_Product_Question__c>();
        List<CHIME_Product_Question__c> questionsList = [Select id, 
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
                         Required__c,Is_Latest__c
                         From CHIME_Product_Question__c
                         Where Parent_Question__c =:parentQuestionId and Expected_Response__c =:expected and Is_Latest__c = true
                         ORDER BY Dependent_Question_Serial__c asc];
        
        
        
        string searchstring = '';
        if (templateList.size() > 0) {
            Chime_Product_Template__c template = templateList[0];
            searchstring = (String)template.id;
        }
        
        for (CHIME_Product_Question__c ques:questionsList) {
            if(ques.Template__c!= null && ques.Template__c !=''){
                if(ques.Template__c.contains(searchstring)){
                    responseList.add(ques);
                }
            } else {
                responseList.add(ques);
            }
        }
                    
    	return responseList;
    }
    
    @AuraEnabled
    public static List<CHIME_Product_Question__c> getDependentQuestionsForParentInChimeForm(String parentQuestionId, String expectionResponse, String productId, string chimeId) {
        System.debug('parentQuestionId :'+parentQuestionId);
        System.debug('expected response :'+expectionResponse);
        String expected = expectionResponse!=null ? expectionResponse.replace('\r', ''): '';
        System.debug(expected);
        
        System.debug('Product id :'+productId);
        Id templateId;
        //Map<String,List<CHIME_Product_Question__c>> sectionToQuestionsMap = new Map<String,List<CHIME_Product_Question__c>>();
        List<Chime_Product_Template__c> templateList = new List<Chime_Product_Template__c >();
            //templateList = [select id,name from Chime_Product_Template__c where Product__c =:productId and CHIME__c  =: chimeId order by createddate desc limit 1];
        
        List<Chime_Product_Association__c> listCPA = new List<Chime_Product_Association__c>();
        listCPA = [Select id, 
                   Chime_Product_Template__c  
                   from Chime_Product_Association__c 
                   where CHIME_Product__c =: productId  
                   and CHIME__c  =: chimeid];
        List<CHIME_Product_Question__c> responseList = new List<CHIME_Product_Question__c>();
        List<CHIME_Product_Question__c> questionsList = [Select id, 
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
                         Required__c,Is_Latest__c
                         From CHIME_Product_Question__c
                         Where Parent_Question__c =:parentQuestionId and Expected_Response__c =:expected
                         ORDER BY Dependent_Question_Serial__c asc];
        
        
        
        string searchstring = '';
        if (listCPA.size() > 0) {
            //Chime_Product_Template__c template = templateList[0];
            searchstring = listCPA[0].Chime_Product_Template__c;
        }
        
        for (CHIME_Product_Question__c ques:questionsList) {
            if(ques.Template__c!= null && ques.Template__c !=''){
                if(ques.Template__c.contains(searchstring)){
                    responseList.add(ques);
                }
            } else {
                responseList.add(ques);
            }
        }
                    
    	return responseList;
    }
    
    
    @AuraEnabled(cacheable=true)
    public static List<PAC_Product_Catalog__c>  getProductData(String productid){
        
        List<PAC_Product_Catalog__c> productsList = [SELECT Id, Product_Name__c, Business_Unit__c , Marketing_Product_Id__c FROM PAC_Product_Catalog__c
                                                    Where PAC_Show_On_UI__c = true and Is_Available_For_Chime__c = false];
        if (productsList != null && productsList.size() >0){
            return productsList;
        }
        return null;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<PAC_Product_Catalog__c>  getProductDataWithoutQuestionnaire(){
        
        List<PAC_Product_Catalog__c> productsList = [SELECT Id, Product_Name__c, Business_Unit__c , Marketing_Product_Id__c FROM PAC_Product_Catalog__c
                                                    Where (PAC_Show_On_UI__c = true OR Add_On__c =true)
                                                     and Is_Available_For_Chime__c = false
                                                     and IsActive__c = true];
        if (productsList != null && productsList.size() >0){
            return productsList;
        }
        return null;
    }
    
    @AuraEnabled(cacheable=true)
    public static List<PAC_Product_Catalog__c>  getProductDataWithQuestionnaire(){
        
        List<PAC_Product_Catalog__c> productsList = [SELECT Id, Product_Name__c, Business_Unit__c , Marketing_Product_Id__c FROM PAC_Product_Catalog__c
                                                    Where (PAC_Show_On_UI__c = true OR Add_On__c =true) and
                                                     Is_Available_For_Chime__c = true and
                                                    IsActive__c = true];
        if (productsList != null && productsList.size() >0){
            return productsList;
        }
        return null;
    }
    
    @AuraEnabled
    public static CHIME_Response__c getQuestionResponse(String questionId, String chimeId){
        
        List<CHIME_Response__c > responseList = [SELECT Id, CHIME_Product_Question__c , Question_Type__c  , Response__c  
                                                     FROM CHIME_Response__c 
                                                    Where CHIME_Product_Question__c =:questionId
                                                            AND CHIME__c =:chimeId];
        if (responseList != null && responseList.size() >0){
            return responseList[0];
        }
        return null;
    }
    
    @AuraEnabled
    public static List<Id> checkProductQuestionnaireRefresh(String ChimeId){
        system.debug('inside checkProductQuestionnaireRefresh');
        Id CId = (Id)ChimeId;
        List<id> ProductsonChimeSet = new List<Id>();
         List<Chime_Product_Association__c > listProductsOnChime = new List<Chime_Product_Association__c >();
        listProductsOnChime = [select id,CHIME_Product__c  from Chime_Product_Association__c where CHIME__c =:Cid];
        
        for(Chime_Product_Association__c Pas: listProductsOnChime){
            ProductsonChimeSet.add(Pas.CHIME_Product__c);
        }
        return ProductsonChimeSet;
    }

    @AuraEnabled
    public static boolean checkChimeEligibilityForRefresh(String ChimeId){
        List<Chime__c> chime = new List<Chime__c>();
        chime = [Select id,Stage__c,Opportunity__c, Opportunity__r.recordtype.developername from Chime__c where id=: ChimeId limit 1];
        Chime__c rec = chime[0];
        if((rec.Stage__c == 'Gating' ||  rec.Stage__c == 'Scoping') && rec.Opportunity__r.recordtype.developername != 'Closed_Opportunity' ){
            return true;
        }
        else{
            return false;
        }
    }
    
    @AuraEnabled
    public static void publishQuestionnaireNotify(String productId, string notes, string templateId){
        List<PAC_Product_Catalog__c> Prdct = new List<PAC_Product_Catalog__c>();
        Id PrdtId = (Id)productId;
        Prdct = [select id,Product_Name__c from PAC_Product_Catalog__c where id =:PrdtId];
        for(PAC_Product_Catalog__c pr : Prdct){
            Chime_Question__e event = new Chime_Question__e ();
            event.Product_ID__c = pr.id;
            event.Product_Name__c = pr.Product_Name__c;
            event.Publish_Notes__c = notes;
            System.debug('event'+event);
            EventBus.publish(event);
        }
        
        if(Prdct.size()>0){
            List<Chime_Product_Association__c > ChimeProductJunction = new List<Chime_Product_Association__c >();
            ChimeProductJunction = [Select id,Questionnaire_Changed__c,Chime_Product_Template__c  from Chime_Product_Association__c where CHIME_Product__c  in:Prdct and Chime_Product_Template__c =:templateid];
            system.debug('ChimeProductJunction:'+ChimeProductJunction);
            for(Chime_Product_Association__c rec : ChimeProductJunction){
                rec.Questionnaire_Changed__c = true;
                rec.Publisher_notes__c = notes;
            }
            update ChimeProductJunction;
        }
    }

    @AuraEnabled
    public static Id createTemplate( String productId){
        //create new Template
        Chime_Product_Template__c template = new Chime_Product_Template__c();
        template.Product__c= (Id)productId;
        template.Is_Latest__c= true;
        insert template;

        //Attach the new template to the open chime forms
        List<Chime_Product_Association__c> listCPA = new List<Chime_Product_Association__c>();
        listCPA = [Select id,CHIME__c,CHIME__r.Stage__c,CHIME_Product__c,CHIME__r.Opportunity__r.StageName from Chime_Product_Association__c where CHIME_Product__c =: productId  and (CHIME__r.Stage__c = 'Gating' OR CHIME__r.Stage__c = 'Scoping') and (CHIME__r.Opportunity__r.recordtype.developername != 'Closed_Opportunity')];         
        for(Chime_Product_Association__c cpa : listCPA){
            cpa.Chime_Product_Template__c = template.id;
        }
        update listCPA;

        return template.id;
    }

    @AuraEnabled
    public static List<CHIME_Response__c > changeResponseQuestionMapping(string oldQues, string newQues, string productId){
        System.debug('oldQues'+oldQues+' newQues'+newQues);
        System.debug('inside changeResponseQuestionMapping');
        List<Chime_Product_Association__c > listCPA = new List<Chime_Product_Association__c >();
        set<Id> setOpenChimeForm = new Set<Id>();
        listCPA=[Select id,CHIME__c,CHIME__r.Stage__c,CHIME_Product__c from Chime_Product_Association__c where CHIME_Product__c =: productId  and (CHIME__r.Stage__c = 'Gating' OR CHIME__r.Stage__c = 'Scoping') and (CHIME__r.Opportunity__r.recordtype.developername != 'Closed_Opportunity')];
        for(Chime_Product_Association__c cpa :listCPA){
            setOpenChimeForm.add(cpa.CHIME__c);
        }
        System.debug('setOpenChimeForm'+setOpenChimeForm);
        List<CHIME_Response__c > responseList = [SELECT Id, CHIME_Product_Question__c   
                                                     FROM CHIME_Response__c 
                                                    Where CHIME_Product_Question__c =:oldQues
                                                            AND CHIME__c in:setOpenChimeForm];
        System.debug('responseList'+responseList);
        for(CHIME_Response__c res : responseList){
            res.CHIME_Product_Question__c = (Id)newQues;
        }
        update responseList;
        return responseList;
        
    }
    
    @AuraEnabled
    public static void deleteQuestion(string quesId, string templateId){
        List<CHIME_Product_Question__c> questionsList = new List<CHIME_Product_Question__c>();
        questionsList = [Select id, template__c,CHIME_Product__c from CHIME_Product_Question__c where id=:quesId limit 1];
		CHIME_Product_Question__c ques = questionsList[0];
        	List<Chime_Product_Template__c> templateList = new List<Chime_Product_Template__c >();
        templateList = [select id,name from Chime_Product_Template__c where Product__c =:ques.CHIME_Product__c order by createddate desc limit 1];
            Chime_Product_Template__c template = templateList[0];
        
        
        List<String> tempids = ques.Template__c.split(template.id);
        String temp = '';
        for(String str : tempids){
        	temp=temp+str;
        }
        ques.Template__c=temp;
        update ques;
    }
    
    @AuraEnabled
    public static Boolean createDependentAfterPublish(String oldQuestionId, String createdQuestionId, String templateId) {
        return QuestionnaireControllerUtil.createDependentAfterPublish(oldQuestionId, createdQuestionId, templateId); 
        
    }
    
    @AuraEnabled
    public static CHIME_Product_Question__c createDependentClone(String dependentQuestion) {
        
        CHIME_Product_Question__c ques = (CHIME_Product_Question__c)Json.deserialize(dependentQuestion, CHIME_Product_Question__c.class);
        CHIME_Product_Question__c clone = new CHIME_Product_Question__c();
        clone.Question_Text__c=ques.Question_Text__c;
        clone.Help_Text__c=ques.Help_Text__c;
        clone.Possible_Response__c=ques.Possible_Response__c;
        clone.Required__c=ques.Required__c;
        clone.Form_Stage__c=ques.Form_Stage__c;
        clone.Question_Status__c='Draft';
        //clone.Chime_Product_Template__c=ques.Chime_Product_Template__c;
        clone.CHIME_Product__c=ques.CHIME_Product__c;
        clone.Section__c=ques.Section__c;
        clone.Serial_Number__c=ques.Serial_Number__c;
        clone.Section_Serial_Number__c=ques.Section_Serial_Number__c;
        clone.Parent_Question__c=ques.Parent_Question__c;
        clone.Question_Type__c=ques.Question_Type__c;
        //clone.Template__c=ques.Template__c;
        clone.Expected_Response__c=ques.Expected_Response__c;
        clone.Is_Latest__c =true;
        insert clone;
        
        CHIME_Product_Question__c q1= [Select id,Is_Latest__c from CHIME_Product_Question__c where id=:ques.Id];
        q1.Is_Latest__c = false;
        update q1;
        
        return clone;
        
    }
}