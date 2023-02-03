/**
 * @description       : 
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 02-17-2022
 * @last modified by  : apyati
 * Modifications Log
 * Ver   Date         Author   Modification                          TAG
 * 1.0   09-07-2021   apyati   SFDC-8655 Added new methods to        <T01>
 *                             handle contacts  in lwc 
 *                             component 'l2qChimeViewEditContacts'
 * 1.0   09-01-2022   apyati   	SFDC-9245 Added additional check for  <T02>
 *                              empty responses
**/
  
public without sharing class ChimeTriggerClass {

    @AuraEnabled
    public static string hideChimeForm(String chimeId, Boolean isArchive){
        try {
            CHIME__c c = [Select id,Account__c,Account1__c,Opportunity__c,Opportunity1__c,Archive_Hidden__c from CHIME__c where id=:chimeId];
            if (isArchive) {
                c.Opportunity1__c = c.Opportunity__c;
                c.Account1__c = c.Account__c;
                c.Account__c = null;
                c.Opportunity__c = null;
                c.Archive_Hidden__c = isArchive;
            }
            else{
                c.Opportunity__c = c.Opportunity1__c;
                c.Account__c = c.Account1__c;
                c.Account1__c = null;
                c.Opportunity1__c = null;
                c.Archive_Hidden__c = isArchive;
            }
            update c;
            return 'Chime Form Updated Successfully';
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    @AuraEnabled
    public static Boolean checkCaseAssociateWithChime(String chimeId){
        try {
            List<Case> cases = [Select id from Case where Chime_Form__c =:chimeId];
            if(cases.size()>0){
                return true;
            }
            return false;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static list<PAC_Product_Catalog__c> getAllProducts(Boolean poc){
        if(poc){
            return [select Id,Name,Product_Name__c,Default_LOE_Managed__c,Default_LOE_Managed_Integration_hours__c,
                        Default_LOE_Standard__c,Default_LOE_Standard_Integration_hours__c,Scope_of_work_Managed__c,
                        Scope_of_work_Standard__c 
                    from PAC_Product_Catalog__c 
                    where IsActive__c=true AND 
                        Is_Available_For_Chime__c = true /*and POC_questions_available__c = true*/
                    Order By Name ASC];
        }
        else{
            return [select Id,Name,Product_Name__c,Default_LOE_Managed__c,Default_LOE_Managed_Integration_hours__c,
                        Default_LOE_Standard__c,Default_LOE_Standard_Integration_hours__c,Scope_of_work_Managed__c,
                        Scope_of_work_Standard__c 
                    from PAC_Product_Catalog__c 
                    where IsActive__c=true AND 
                        Is_Available_For_Chime__c = true 
                    Order By Name ASC];
        }
    }
    
    @AuraEnabled (cacheable=true)
    public static Map<String,String> getAssignedChimeForm(){
        Map<String,String> chimeIdToProducts = new Map<String,String>();
        User u = [select Id, ContactId from User where Id =: UserInfo.getUserId()];
        List<String> chimeIds = new List<String>();
        if(u.ContactId != null){
            for(CHIME_Contact__c cc : [select Id, CHIME__c  from CHIME_Contact__c where Contact__c =: u.ContactId and Chime_access__c=true]){
                chimeIds.add(cc.CHIME__c);
            }
            for(CHIME__c c : [select Id, CHIME_Name__c from CHIME__c where Id IN : chimeIds]){
                chimeIdToProducts.put(c.Id,c.CHIME_Name__c);
            }
        }
        return chimeIdToProducts;
    }

    @AuraEnabled
    public static boolean validateChimeAccess(String chimeId){
        User u = [select Id, ContactId from User where Id =: UserInfo.getUserId()];
        if(u.ContactId != null){
            List<CHIME_Contact__c> chimeContact = [select Id, Chime_access__c from CHIME_Contact__c where CHIME__c =: chimeId and Contact__c =: u.ContactId order by LastModifiedDate Desc LIMIT 1];
            if(chimeContact.size() > 0)
                return chimeContact[0].Chime_access__c;
            else
               return false; 
        }
        return false;
    }

    @AuraEnabled
    public static string getInvalidTextResponses(){
        string invalidRes = GsmUtilClass.getGSMSettingValue('CHIME_InvalidTextResponse');
        invalidRes = invalidRes.toLowerCase();
        return invalidRes;
    }
    
    @AuraEnabled
    public static List<L2Q_CprUtil.PicklistWrapperClass> getSuccCri(){
        Schema.DescribeFieldResult fieldResult = CHIME__C.Business_Goals__c.getDescribe();
        return L2Q_CprUtil.getPicklistvalues(fieldResult, 'multipicklist');
    }
    
    @AuraEnabled
    public static list<Chime_Product_Association__c> getSelectedProducts(string chimeId){
        return [select Id,CHIME_Product__c,CHIME_Product__r.Product_Name__c, CHIME_Product__r.Approval_Required__c,
        Review_Required__c, Questionnaire_Changed__c,Publisher_notes__c,Total_LoE__c from Chime_Product_Association__c where CHIME__c =: chimeId];
    }

    @AuraEnabled
    public static list<Chime_Product_Association__c> getSelectedProductsForChime(string chimeId){
        return [select Id,CHIME_Product__r.Name,CHIME_Product__r.Product_Name__c,
                       CHIME_Product__r.Default_LOE_Standard__c,
                       CHIME_Product__r.Default_LOE_Managed__c,
                       CHIME_Product__r.Scope_of_work_Managed__c,
                       CHIME_Product__r.Scope_of_work_Standard__c 
                from Chime_Product_Association__c 
                where CHIME__c =: chimeId];
    }
    
    @AuraEnabled
    public static Chime_Product_Association__c createChimeProductAssociation(string chimeId, string productId){
        List<Chime_Product_Template__c> cpa = new List<Chime_Product_Template__c>();
        cpa = [Select id from Chime_Product_Template__c where Product__c =:productId order by createddate desc limit 1];

        Chime_Product_Association__c newCPA = new Chime_Product_Association__c(CHIME_Product__c=productId,CHIME__c=chimeId, Chime_Product_Template__c=cpa[0].id);
        insert newCPA;

        Chime__c chime = [select Id,Is_All_Qun_Ans_Complete__c from Chime__c where Id =: chimeId];
        if(chime.Is_All_Qun_Ans_Complete__c){
            chime.Is_All_Qun_Ans_Complete__c=false;
            update chime;
        }
        
        return [select Id,CHIME_Product__c,CHIME_Product__r.Product_Name__c,CHIME_Product__r.Approval_Required__c,Chime_Product_Template__c,Total_LoE__c,Review_Required__c from Chime_Product_Association__c where Id =: newCPA.Id];
    }
    
    @AuraEnabled
    public static void deleteChimeProductAssociation(string associationId){
        Chime_Product_Association__c chimeAssociation = [select Id,chime__c,chime__r.stage__c from Chime_Product_Association__c where Id =: associationId];
        Id chimeId = chimeAssociation.chime__c; String stage = chimeAssociation.chime__r.stage__c;
        delete chimeAssociation;
        //ChimeTriggerClass.StageTransitionCheck(chimeId,stage);
        Chime__c chimeform = [Select id,Is_All_Qun_Ans_Complete__c from Chime__c where id=:chimeAssociation.chime__c];
        List<Chime_Product_Association__c> listCPAonChime = [Select id,Required_answer_on_product__c  from Chime_Product_Association__c where CHIME__c =:chimeAssociation.chime__c];
        Boolean result = true;
        for(Chime_Product_Association__c rec : listCPAonChime ){
            result = result && rec.Required_answer_on_product__c;
        }
        if(!result){
            if(chimeform.Is_All_Qun_Ans_Complete__c == true){
                chimeform.Is_All_Qun_Ans_Complete__c = false;
                update chimeform;
            }
        }else{
            chimeform.Is_All_Qun_Ans_Complete__c = true;
            update chimeform;
        }
    }
    
    @AuraEnabled
    public static CHIME__C getChimeDetails(string chimeId){
            return [select Id, Stage__c, CHIME_Name__c, Reopen_Reason__c,Notes__c, CreatedById, CreatedBy.Name, Account__c, Account__r.Name, Account__r.Type, Account__r.Owner.Name, Opportunity__c, Opportunity__r.Name,
            Account1__c, Account1__r.Name, Account1__r.Type, Account1__r.Owner.Name, Opportunity1__c, Opportunity1__r.Name, 
        Partner_Involved__c, Partner_Involved__r.Name,Implementation_Type__c, Is_Emergency__c,Status__c,LOE_Id__c,Total_LoE__c,Is_Case_Button_Enabled__c,Case_ID__c,Case_Description_UI__c,Integration_Case_ID__c,
        LOE_Review_Status__c,	Review_Case_Id__c, Sign_Off__c,Is_POC_Demo__c,Product_Approval_Status__c,Prolexic_Products__c,POC_Type__c, All_Enterprise_Products__c, Is_All_Qun_Ans_Complete__c,Is_Work_At_Risk_Investment_Work__c,Archive_Hidden__c from CHIME__c where Id =: chimeId];
   }
    
    @AuraEnabled
    public static Opportunity getOpportunityDetails(String opportunityId){
        return [select id, name, accountid, account.name from Opportunity where id =: opportunityId];
    }
    
    @AuraEnabled
    public static ObjectRecordWrapper getObjectDetails(String recId){
        Id record = (Id)recId;
        String sObjName = record.getSObjectType().getDescribe().getName();
        ObjectRecordWrapper wrap = new ObjectRecordWrapper();
        wrap.ObjectRecordWrap = new Map<String,Sobject>();
        if(sObjName =='Deal_Support_Request__c'){
            
           Sobject rec =  [Select id,name, Opportunity__c,Opportunity__r.Name,Account__c,Account__r.name,Request_Type__c,recordtype.developername,Product__c  from Deal_Support_Request__c where id =: recId];
           wrap.ObjectRecordWrap.put('Deal Support Request',rec);

        }

        else if(recId.startsWith('001')){
            Sobject rec =   [select id, name from Account where id =: recId];
            wrap.ObjectRecordWrap.put('Account',rec);
        }
        else if(recId.startsWith('006')){
            Sobject rec =   [select id, name, accountid, account.name, Partner_Involved__c, Partner_Involved__r.Name from Opportunity where id =: recId];
            wrap.ObjectRecordWrap.put('Opportunity',rec);
        }
            return wrap;
    }
    public class ObjectRecordWrapper
    {
        @AuraEnabled
        public Map<String,Sobject> ObjectRecordWrap{get;set;}
    }
    
    @AuraEnabled
    public static string createChime(String chimeId, String opportunityId,String partneraccountId,String accountId, String impType, boolean isEmer, String chimeName, list<PAC_Product_Catalog__c> selectedProdIds, Boolean isPOC, String pocType, Boolean isWorkAt){
        chimeId = (chimeId=='')?null:chimeId;

        // Update action if Emergency is changed on edit
        list<Chime_Product_Association__c> cpaListToUpdateReview = new list<Chime_Product_Association__c>();
        if(chimeId != null){
            CHIME__c oldRec = [select Id,Is_Emergency__c,Is_Work_At_Risk_Investment_Work__c from CHIME__c where Id=: chimeId];
            if(oldRec.Is_Emergency__c != isEmer || oldRec.Is_Work_At_Risk_Investment_Work__c != isWorkAt){
                if(isEmer || isWorkAt){
                   cpaListToUpdateReview = [Select Id,Review_Required__c from Chime_Product_Association__c where CHIME__c =: chimeId];
                   for(Chime_Product_Association__c iteratedCPA : cpaListToUpdateReview){
                    iteratedCPA.Review_Required__c = true;
                   }
                }else{
                    cpaListToUpdateReview = [Select Id,Review_Required__c,	CHIME_Product__r.Review_Required__c from Chime_Product_Association__c where CHIME__c =: chimeId];
                    for(Chime_Product_Association__c iteratedCPA : cpaListToUpdateReview){
                        if(iteratedCPA.CHIME_Product__r.Review_Required__c){
                            iteratedCPA.Review_Required__c = true;
                        }else{
                            iteratedCPA.Review_Required__c = false;
                        }
                    }    
                }
            }
            update cpaListToUpdateReview;
        }


        CHIME__c c = new CHIME__c(Id=chimeId,Account__c=accountId,CHIME_Name__c=chimeName,Implementation_Type__c=impType,Is_Emergency__c=isEmer, Is_POC_Demo__c=isPOC,POC_Type__c=pocType,Is_Work_At_Risk_Investment_Work__c = isWorkAt,Archive_Hidden__c = false);
        c.Opportunity__c= !String.isBlank(opportunityId)?opportunityId: null;
        c.Partner_Involved__c= !String.isBlank(partneraccountId) ?partneraccountId: null;
        
        if(String.isBlank(chimeId)){
            c.Stage__c='Gating';
        }
        try{
            upsert c;
        }
        catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }

        //SFDC-8413 Do not add products in Edit chime process
        if(chimeId == null){
            Map<Id,Id> mapProductTemplate = new Map<Id,Id>();
            List<Chime_Product_Template__c> templateList = new List<Chime_Product_Template__c >();
            templateList = [select id,name,Product__c from Chime_Product_Template__c where Product__c in:selectedProdIds order by createddate desc ];
            for(Chime_Product_Template__c temp : templateList){
                if(!(mapProductTemplate.keySet().contains(temp.Product__c))){
                    mapProductTemplate.put(temp.Product__c,temp.id);
                }
            }
            System.debug('mapProductTemplate:'+mapProductTemplate);
            list<Chime_Product_Association__c> cpaList = new list<Chime_Product_Association__c>();
            for(PAC_Product_Catalog__c prod : selectedProdIds){
                Id tempId = mapProductTemplate.get(prod.id);
                Chime_Product_Association__c newCPA = new Chime_Product_Association__c(CHIME_Product__c=prod.Id,CHIME__c=c.Id,Chime_Product_Template__c =tempId );
                cpaList.add(newCPA);
            }
            if(cpaList.size()>0){
        	   insert cpaList;
            }
        }
        return c.Id;
    }
    
    @AuraEnabled
    public static string checkPermissionToAcceptChime(String operation){
        set<String> ProfserviceProfileList = new set<String>{'GSS Professional Services',
            'GSS Professional Services Contractor',
            'GSS Professional Services Manager',
			'GSS Professional Services With KB',
			'GSS Operations',
			'GSS Professional Services - Restricted Country',
			'Managed Security – SOC',
			'Carrier PS',
            'System Administrator'};
        set<String> PreSalesProfilesList = new set<String>{'Solutions Engineer',
			'Solutions Engineer - Manager',
			'Solutions Engineer - Restricted Country',
            'System Administrator'};
        string response = 'false';
     	id userId = UserInfo.getUserId();
        Id userProfileId = userinfo.getProfileId();
        List<Profile> listProfile = [select id,name from Profile where id =: userProfileId ];
        System.debug('listProfile'+listProfile);
        if(operation == 'Reopen'){
            if(ProfserviceProfileList.contains(listProfile[0].name) || PreSalesProfilesList.contains(listProfile[0].name)){
                response = 'true';
            }else{
                response = 'false';
            }
        }
        else if(operation == 'Accept'){
            if(ProfserviceProfileList.contains(listProfile[0].name)){
                response= 'true';
            }
            else if(PreSalesProfilesList.contains(listProfile[0].name)){
                response = 'ShowReopenForSE';
            }
            else{
                response= 'false';
            }
        }
        return response;
    }
    
    @AuraEnabled
    public static void clearFlag(String cpas){
        List<Chime_Product_Association__c> listCPA = new List<Chime_Product_Association__c>();
        
            List<String> listst = (List<String>)Json.deserialize(CPAs, String[].class);
        set<id> CPAids = new Set<id>();
        for(String str : listst){
            CPAids.add((Id)str);
        }
        listCPA = [select id,Questionnaire_Changed__c from Chime_Product_Association__c where id in: CPAids];
        for(Chime_Product_Association__c cpa : listCPA){
            cpa.Questionnaire_Changed__c = false;
        }
        update listCPA;
    }
    @AuraEnabled
    public static void clearFlag2(String chimeId, string prdtId ){
        system.debug('inside clearFlag2');
        List<Chime_Product_Association__c> listCPA = new List<Chime_Product_Association__c>();
        
        Id Cid = (Id)chimeId;
        Id ProductId = (Id)prdtId;
        listCPA = [select id,Questionnaire_Changed__c from Chime_Product_Association__c where CHIME__c =: Cid and CHIME_Product__c  =: ProductId];
        for(Chime_Product_Association__c cpa : listCPA){
            cpa.Questionnaire_Changed__c = false;
        }
        update listCPA;
    }
    
    
    @AuraEnabled
    public static string StageTransitionCheck(String chimeId, String currentStage){
        //This is to check for automatic Transition of stages once all the questions are answered.
        //Manual will be taken care on the LWC.
        Id CId = (ID)chimeId;
        System.debug('Cid'+CId);
        Set<Id> productIds = new Set<Id>();
        Map<Id,Id> mapProductTemplate = new Map<Id,Id>();
        List<Chime_Product_Association__c > chimePrdctJunc = [Select id,CHIME_Product__c, CHIME__c,Chime_Product_Template__c from Chime_Product_Association__c where CHIME__c =:CId ];
            if(chimePrdctJunc.size()>0){
                for(Chime_Product_Association__c prdt : chimePrdctJunc) {
                    productIds.add(prdt.CHIME_Product__c);
                    mapProductTemplate.put(prdt.CHIME_Product__c,prdt.Chime_Product_Template__c);
                }
            }
        system.debug('productIds'+productIds);
        responseWrapper resWrap = new responseWrapper();
        if(currentStage == 'Gating'){
            resWrap = ChimeTriggerClass.GatingStageCheck(CId,mapProductTemplate,productIds,currentStage);
        }
        if(currentStage == 'Scoping'){
            resWrap = ChimeTriggerClass.ScopingStageCheck(CId,mapProductTemplate,productIds);
        }
        system.debug('resWrap'+resWrap);
        return JSON.serialize(resWrap);
    }
    
    
    //Method to check if exit criteria is met for Gating Stage
    
    public static responseWrapper GatingStageCheck(Id ChimeId, Map<Id,Id> mapProductTemplate, Set<Id> productIds,String currentStage){
        
        responseWrapper resWrap = new responseWrapper();
        List<CHIME_Product_Question__c> prdttempQues = new List<CHIME_Product_Question__c>();
            
            List<CHIME_Product_Question__c > prodQuestions = [Select id, CHIME_Product__c,template__c  from CHIME_Product_Question__c where parent_question__c = null and Form_Stage__c =: currentStage and  CHIME_Product__c in:productIds];
            for(CHIME_Product_Question__c ques: prodQuestions){
                if(ques.template__c != null && ques.template__c !=''){
                    if(ques.template__c.contains(mapProductTemplate.get(ques.CHIME_Product__c))){
                        prdttempQues.add(ques);
                    }
                }
            }
            System.debug('prdttempQues:'+prdttempQues.size());
            List<CHIME_Response__c> questionResponses = [Select id,CHIME_Product_Question__c,Response__c from CHIME_Response__c where CHIME_Product_Question__c in:prdttempQues and CHIME__c =:ChimeId];
            //Create map of Question and Response
            Map<Id,String> mapQuesResponse = new Map<Id,String>();
            for(CHIME_Response__c res: questionResponses){
                mapQuesResponse.put(res.CHIME_Product_Question__c,res.Response__c);
            }
        	
        
            if(prdttempQues.size() != questionResponses.size()){
                //return false;
                resWrap.moveToNextStage = false;
            }else{
                //Logic to check if Dependent questions will come into play.
                //get dependent questions
               	List<CHIME_Product_Question__c> dependentQuestions = new List<CHIME_Product_Question__c>();
                List<CHIME_Product_Question__c > dependentprodQuestions = [Select id, CHIME_Product__c,template__c, Expected_Response__c,parent_question__c   from CHIME_Product_Question__c where parent_question__c in:prdttempQues and  CHIME_Product__c in:productIds];
                if(dependentprodQuestions.size()>0){
                    for(CHIME_Product_Question__c ques: dependentprodQuestions){
                        if(ques.template__c != null && ques.template__c !=''){
                            if(ques.template__c.contains(mapProductTemplate.get(ques.CHIME_Product__c))){
                                dependentQuestions.add(ques);
                            }
                        }
                    }
                }
                
                //Create set of dependent Question who are expected to be filled
                Set<Id> setDependentQues = new Set<Id>();
                //check if Parent's question Response is same as expected of dependent question.
                for(CHIME_Product_Question__c dques: dependentQuestions){
                    if(mapQuesResponse!= null && dques.parent_question__c != null){
                        if(mapQuesResponse.get(dques.parent_question__c)!= null){
                            if(mapQuesResponse.get(dques.parent_question__c) == dques.Expected_Response__c){
                                setDependentQues.add(dques.id);
                            }
                        }
                    }
                }
                system.debug('setDependentQues'+setDependentQues);
                system.debug('setDependentQues size'+setDependentQues.size());
                //get Responses of dependent Questions
                List<CHIME_Response__c> depenedentquestionResponses = [Select id,CHIME_Product_Question__c,Response__c from CHIME_Response__c where CHIME_Product_Question__c in:setDependentQues and CHIME__c =:ChimeId];
                system.debug('depenedentquestionResponses size'+depenedentquestionResponses.size());              
                if(setDependentQues.size() == 0){
                    //when there is no dependent question to be considered.
                    Chime__c chimeform = new Chime__c();
                        chimeform.id=ChimeId;
                        chimeform.Stage__c='Scoping';
                        update chimeform;
                        //return true;
                        resWrap.moveToNextStage = true;
                } else if(depenedentquestionResponses.size()>0){
                    if(depenedentquestionResponses.size() == setDependentQues.size()){
                        //change the stage value to Scoping.
                        Chime__c chimeform = new Chime__c();
                        chimeform.id=ChimeId;
                        chimeform.Stage__c='Scoping';
                        update chimeform;
                        //return true;
                        resWrap.moveToNextStage = true;
                    }else{
                        resWrap.moveToNextStage = false;
                    }
                }else{
                    //when there is no dependent question answered
                    resWrap.moveToNextStage = false;
                }
                
                
            }
            return resWrap;
    }
    
    //Method to check if exit criteria is met for Scoping Stage
    
    public static responseWrapper ScopingStageCheck(Id ChimeId, Map<Id,Id> mapProductTemplate, Set<Id> productIds){
        responseWrapper resWrap = new responseWrapper();
        List<CHIME_Product_Question__c> prdttempQues = new List<CHIME_Product_Question__c>();
            
        //Get all the product questions for template on CPA.
            List<CHIME_Product_Question__c > prodQuestions = [Select id, CHIME_Product__c,template__c  from CHIME_Product_Question__c where parent_question__c = null and (Form_Stage__c = 'Gating' OR Form_Stage__c = 'Scoping' ) and CHIME_Product__c in:productIds];
            if(prodQuestions.size()>0){
                for(CHIME_Product_Question__c ques: prodQuestions){
                    if(ques.template__c != null && ques.template__c !=''){
                        if(ques.template__c.contains(mapProductTemplate.get(ques.CHIME_Product__c))){
                            prdttempQues.add(ques);
                        }
                    }
                }
                
            }
        	//Get Responses for all the questions
            List<CHIME_Response__c> questionResponses = [Select id,CHIME_Product_Question__c,Response__c from CHIME_Response__c where CHIME_Product_Question__c in:prdttempQues and CHIME__c =:ChimeId];
            //Create map of Question and Response
            Map<Id,String> mapQuesResponse = new Map<Id,String>();
            for(CHIME_Response__c res: questionResponses){
                mapQuesResponse.put(res.CHIME_Product_Question__c,res.Response__c);
            }
        	
        	//list of required questions
        	List<CHIME_Product_Question__c> reqProductQuestions = [Select id, CHIME_Product__c,template__c  from CHIME_Product_Question__c where Required__c= true and id in:prdttempQues];
        	//list of required Responses
        	List<CHIME_Response__c> reqquestionResponses = [Select id,CHIME_Product_Question__c,Response__c from CHIME_Response__c where CHIME_Product_Question__c in:reqProductQuestions and CHIME__c =:ChimeId];
        
            
            Chime__c chimeform = [Select id, Is_Emergency__c ,Opportunity__c ,Opportunity_Stage__c, Is_All_Qun_Ans_Complete__c,Is_Work_At_Risk_Investment_Work__c from Chime__c where id=:ChimeId];
                
            if(reqProductQuestions.size() != reqquestionResponses.size()){
                //return false;
                //resWrap.moveToNextStage = false;
                resWrap.hasAnsweredReqQues = false;
                if(chimeform.Is_All_Qun_Ans_Complete__c == true){
                	chimeform.Is_All_Qun_Ans_Complete__c = false;
                	update chimeform;
                }
            }
            else{
                //get the dependent Questions
                List<CHIME_Product_Question__c> dependentQuestions = new List<CHIME_Product_Question__c>();
                List<CHIME_Product_Question__c > dependentprodQuestions = [Select id, CHIME_Product__c,template__c, Expected_Response__c,parent_question__c   from CHIME_Product_Question__c where parent_question__c in:prdttempQues and  Required__c= true and  CHIME_Product__c in:productIds];
                if(dependentprodQuestions.size()>0){
                    for(CHIME_Product_Question__c ques: dependentprodQuestions){
                        if(ques.template__c != null && ques.template__c !=''){
                            if(ques.template__c.contains(mapProductTemplate.get(ques.CHIME_Product__c))){
                                dependentQuestions.add(ques);
                            }
                        }
                    }
                }
                
                //Create set of dependent Question who are expected to be filled
                Set<Id> setDependentQues = new Set<Id>();
                //check if Parent's question Response is same as expected of dependent question.
                for(CHIME_Product_Question__c dques: dependentQuestions){
                    if(mapQuesResponse!= null && dques.parent_question__c != null){
                        if(mapQuesResponse.get(dques.parent_question__c)!= null){
                            if(mapQuesResponse.get(dques.parent_question__c) == dques.Expected_Response__c){
                                setDependentQues.add(dques.id);
                            }
                        }
                    }
                }
                
                //get Responses of dependent Questions
                List<CHIME_Response__c> depenedentquestionResponses = [Select id,CHIME_Product_Question__c,Response__c from CHIME_Response__c where CHIME_Product_Question__c in:setDependentQues and CHIME__c =:ChimeId];
                
                //Compare the dependentQues and the responses size
                if(setDependentQues.size() == 0){
                    //when there is no dependent question to be considered.
                    resWrap.canOpenCase= true;
                    chimeform.Is_All_Qun_Ans_Complete__c = true;
                    update chimeform;
                } else
                if(depenedentquestionResponses.size()>0){
                    if(depenedentquestionResponses.size() == setDependentQues.size()){
                            resWrap.canOpenCase= true;
                        	chimeform.Is_All_Qun_Ans_Complete__c = true;
                			update chimeform;
                        }
                    }else{
                        resWrap.hasAnsweredReqQues = false;
                        if(chimeform.Is_All_Qun_Ans_Complete__c == true){
                            chimeform.Is_All_Qun_Ans_Complete__c = false;
                            update chimeform;
                        }
                    }
                }   
            
        
        return resWrap;
    }
    
    public class responseWrapper{
        @AuraEnabled
        public Boolean moveToNextStage{get;set;}
        @AuraEnabled
        public Boolean hasAnsweredReqQues{get;set;}
        @AuraEnabled
        public Boolean canOpenCase{get;set;}
    }
    
    @AuraEnabled
    public static void notifyOppTeam(string chimeId, string operation){
        Chime__c cform = [Select id,CHIME_Name__c ,Account__c,Opportunity__c,Opportunity__r.name,Opportunity__r.Account.name,createdbyid, Reopen_Reason__c,Notes__c  from chime__c where id =: chimeId limit 1][0];
        Set<Id> userIds = new Set<Id>();
        String PrimarySE ='';
        
        Set<String> setTeamRoles = new Set<String>();
        //Map<String,L2Q_Notify_Chime_form_Team_Role__mdt> mapEd = L2Q_Notify_Chime_form_Team_Role__mdt.getAll();
		//System.debug('mapEd:'+mapEd);
        
		List<GSM_Settings_Verbose__mdt> listTeamRolesMdt = [SELECT Id,MasterLabel,Value__c from GSM_Settings_Verbose__mdt where MasterLabel = 'Chime form Team Roles' limit 1];
        
        for(GSM_Settings_Verbose__mdt mdt: listTeamRolesMdt){
            setTeamRoles.addAll(mdt.Value__c.split(';'));
            break;
        }
        System.debug('setTeamRoles:'+setTeamRoles);
        
        List<AccountTeamMember> accTeam = [select id,userid,TeamMemberRole,user.name from AccountTeamMember where AccountId =:cform.Account__c ];
        for(AccountTeamMember otm : accTeam){
            if(setTeamRoles.contains(otm.TeamMemberRole)){
                userIds.add(otm.userid);
            }
            if(otm.TeamMemberRole == 'Technical Sales - Primary'){
                PrimarySE = otm.user.name;
            }
        }
        List<Case> cases = [Select id,CaseNumber,Owner.name from Case where Chime_Form__c =:cform.id and Chime_Case_Type__c = 'Integration Case' limit 1];
        //add chimeform created as well
        userIds.add(cform.createdbyid);
        
        //add the case owner to email list if Person Accepting the Chime form != Case owner
        if(operation!='Reopened' && 'User'==cases[0].OwnerId.getSObjectType().getDescribe().getName()){
            if(UserInfo.getUserId() != cases[0].OwnerId){
                userIds.add(cases[0].OwnerId);
            }
        }

        String baseUrl = System.URL.getSalesforceBaseUrl().toExternalForm();
        String msg='';

            if(operation=='Reopened'){
                msg= 'Hi'+',' +'<br/>' +'<br/>' + 'The CHIME form for Account: '+cform.Opportunity__r.Account.name+' has been reopened by '+UserInfo.getFirstName()+ ' '+ UserInfo.getLastName() +'. Please review the details given below and take necessary actions at the earliest:'+'<br/>'+'<br/>';
            }else{
                msg= 'Hi'+',' +'<br/>' +'<br/>' + 'The CHIME form for Account: '+cform.Opportunity__r.Account.name+' has been accepted by '+UserInfo.getFirstName()+ ' '+ UserInfo.getLastName() +'. Please review the details given below and take necessary actions at the earliest:'+'<br/>'+'<br/>';
            }
            msg += 'Opportunity: <html><a href="'+baseUrl+'/'+cform.Opportunity__c+'">' + cform.Opportunity__r.name + '</a><br/></html>' ; 
            if(operation=='Reopened'){
            	msg += 'Reopen Reason: '+ cform.Reopen_Reason__c.replace(';',',') + '<br/>' ;
            }
            msg += 'Primary SE: ' + PrimarySE + '<br/>' ; 
            if(cases.size()>0){
            msg += 'Case Owner: ' + cases[0].Owner.name + '<br/>' ;
            msg += 'Case: <html><a href="'+baseUrl+'/'+cases[0].id+'">'+cases[0].CaseNumber+'</a><br/></html>';
            }else{
                msg += 'Case Owner: '+ '<br/>' ; 
                msg += 'Case: '+'<br/>';
            }
            
            msg += 'CHIME Form: <html><a href="'+baseUrl+'/'+cform.id+'">' + cform.CHIME_Name__c + '</a><br/></html>' ;
         if(operation=='Reopened'){
            if(cform.Notes__c!=null)
            msg= msg +  'Notes: '+cform.Notes__c+'<br/>'+'<br/>';
            else
            msg= msg + 'Notes: '+'<br/>'+'<br/>';

        }
        msg = msg + '<br/>' +'Thank you';
        
        if(userIds.size()>0){
            //send email to users for Chime form
            List<User> userList = [Select id,email from user where id in:userIds];
            Messaging.SingleEmailMessage[] messages =   new List<Messaging.SingleEmailMessage>();
            for(User us: userList){
                //code to send email
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.toAddresses = new String[] {us.email};
                if(operation=='Reopened'){    
                    mail.setSubject(cform.CHIME_Name__c +' for '+ cform.Opportunity__r.name + ' has been Reopened!');
                }else{
                    mail.setSubject(cform.CHIME_Name__c +' for '+ cform.Opportunity__r.name + ' has been Accepted for Integration!');
                }
                mail.setHtmlBody(msg);
                messages.add(mail);
            }
            Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        }  
    }
    
    @AuraEnabled( cacheable = true )  
    public static List < sObject > fetchChimeContacts( String listValues ) {  
        
        system.debug( 'values are ' + listValues );  
        List < String > strList = listValues.split( '-' );  
        system.debug( 'values are ' + strList );   
        String strObject = strList.get( 0 );
        String strFields = strList.get( 1 );
        String strRelatedField = strList.get( 2 );
        String strAccountId;
        if ( strList.size() == 4)
            strAccountId = strList.get( 3 );
        List < sObject > listRecs = new List < sObject >();
        String strSOQL = 'SELECT Id, ' + strFields + ' FROM ' + strObject;

        if ( String.isNotBlank( strAccountId ) )
            strSOQL  += ' WHERE ' + strRelatedField+ ' = \'' + strAccountId + '\'';
        
        strSOQL += ' LIMIT 25';
        system.debug( 'SOQL is ' + strSOQL );
        listRecs = Database.query( strSOQL );
        return listRecs;
          
    }


    //-----------------------------------------------------------------<T01>

    
    /**
    * @description : SFDC-8655 Get all conatcts associated to chime form
    * @author apyati | 09-07-2021 
    * @param String chimeId 
    * @return List<CHIME_Contact__c> 
    **/
    @AuraEnabled
    public static List <CHIME_Contact__c> getChimeContacts( String chimeId) {  
        List<CHIME_Contact__c> lstContacts = new List<CHIME_Contact__c>();
        try{
            lstContacts= [ SELECT Id,Name__c, Email__c, Chime_access__c,Contact_Phone__c, Contact__c FROM CHIME_Contact__c WHERE CHIME__c = :chimeId];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return lstContacts;
    }


    /**
    * @description: SFDC-8655 Get all contacts from the account and chime's partner involved account but not already added to chime 
    * @author apyati | 09-07-2021 
    * @param String accId 
    * @param String chimeId 
    * @return List<Contact> 
    **/
    @AuraEnabled
    public static List <Contact> getContacts( String accId , String chimeId) {  
        List<Contact> lstContacts = new List<Contact>();
        Set<Id> setPartnerAccountIds= new Set<Id>();
        try{
            for( CHIME__c chime : [SELECT Partner_Involved__c,Partner_Involved__r.ParentId, Partner_Involved__r.Parent.ParentId FROM CHIME__c WHERE Id = :chimeId AND Partner_Involved__c != null]){
                setPartnerAccountIds.add(chime.Partner_Involved__c);
                if(chime.Partner_Involved__r?.ParentId != null){
                    setPartnerAccountIds.add(chime.Partner_Involved__r?.ParentId);
                    if(chime.Partner_Involved__r?.Parent?.ParentId != null){
                        setPartnerAccountIds.add(chime.Partner_Involved__r?.Parent?.ParentId);
                    }
                }
            }
            lstContacts= [SELECT Id, Name, Email, Phone, AccountId, Account.Name, Account.AccountType__c ,Account.Type 
                FROM Contact 
                    WHERE (AccountId = : accId OR AccountId IN :setPartnerAccountIds)
                     AND Id NOT IN ( SELECT Contact__c FROM CHIME_Contact__c WHERE CHIME__c = :chimeId) ORDER BY Name, AccountId];
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return lstContacts;
    }

    /**
    * @description : SFDC-8655 Create Chime Contact records for Selected Contacts 
    * @author apyati | 09-07-2021 
    * @param List<Contact> selectedContacts 
    * @param String chimeId 
    * @return string 
    **/
    @AuraEnabled
    public static string addChimeContacts( List<Contact> selectedContacts, String chimeId){
        try {
            List<CHIME_Contact__c> lstInsertChimeContacts = new List<CHIME_Contact__c>();
            for(Contact con :selectedContacts){
                CHIME_Contact__c chimecon = new CHIME_Contact__c();
                chimecon.Contact__c = con.Id;
                chimecon.Chime__c = chimeId;
                chimecon.Chime_Access__c = con.Has_Chime_Access__c;
                lstInsertChimeContacts.add(chimecon);
            }
            if(lstInsertChimeContacts.size()>0){
                insert lstInsertChimeContacts;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    
        return 'Chime Contacts Added Successfullly';
    }

    /**
    * @description :SFDC-8655 delete slected chime contacts
    * @author apyati | 09-07-2021 
    * @param List<CHIME_Contact__c> chimeContacts 
    * @return string 
    **/
    @AuraEnabled
    public static string removeChimeContacts( List<CHIME_Contact__c> chimeContacts){
        try {
            
            if(chimeContacts!= null &&chimeContacts.size()>0){
                delete chimeContacts;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    
        return 'Chime Contacts Removed Successfullly';
    }

    /**
    * @description :SFDC-8655 update chime acce4ss on  chime contacts
    * @author apyati | 09-07-2021 
    * @param List<CHIME_Contact__c> chimeContacts 
    * @return string 
    **/
    @AuraEnabled
    public static string updateChimeContacts( List<CHIME_Contact__c> chimeContacts){
        try {
            
            if(chimeContacts!= null &&chimeContacts.size()>0){
                update chimeContacts;
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    
        return 'Chime Contacts Updated Successfullly';
    }

    //-----------------------------------------------------------------</T01>


    public class successCriteriaWrapper{  
        @AuraEnabled public Map<String, String> allSuccessCriteria {get; set;}  
        @AuraEnabled public String selectedSuccessCriteria {get; set;}
        @AuraEnabled public String chimeStatus {get; set;}
    }  

    @AuraEnabled//cacheable=true)
    public static successCriteriaWrapper getAllSuccessCriteria(Id chimeId){
        List<String> successCriteria = new List<String>();
        Map<String, String> returnSuccessCriteriaToHelpText = new Map<String, String>();

        String successCriteriaHelpText = GSMSettings.getVerbose('Success_Criteria_Mapping');
        Map<String, String> successCriteriaToHelpText = (Map<String,String>) JSON.deserialize(successCriteriaHelpText, Map<String,String>.class);

        Schema.DescribeFieldResult fieldResult = CHIME__c.Business_Goals__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            System.debug(pickListVal.getLabel() +' '+pickListVal.getValue());
            if(successCriteriaToHelpText.containsKey(pickListVal.getValue())){
                returnSuccessCriteriaToHelpText.put(pickListVal.getValue(), successCriteriaToHelpText.get(pickListVal.getValue()));
            }
        }

        CHIME__c cform = [Select id, Stage__c, Business_Goals__c from CHIME__c where Id =:chimeId][0];

        successCriteriaWrapper scw = new successCriteriaWrapper();
        scw.chimeStatus = cform.Stage__c;
        scw.allSuccessCriteria = new Map<String, String>(returnSuccessCriteriaToHelpText);
        scw.selectedSuccessCriteria = cform.Business_Goals__c;

        System.debug('returnSuccessCriteriaToHelpText:'+returnSuccessCriteriaToHelpText);
        return scw; 
    }
    
    @AuraEnabled
    public static string StageTransitionChecknew(String chimeId, String currentStage, String quesList){
        //This is to check for automatic Transition of stages once all the questions are answered.
        //Manual will be taken care on the LWC.
        Id CId = (ID)chimeId;
        System.debug('Cid'+CId);
        List<String> listQues = (List<String>)Json.deserialize(quesList, String[].class);
        System.debug('listQues'+listQues);
        
        
        responseWrapper resWrap = new responseWrapper();
        if(currentStage == 'Gating'){
            resWrap = ChimeTriggerClass.GatingStageChecknew(CId,listQues,currentStage);
        }
        if(currentStage == 'Scoping'){
            resWrap = ChimeTriggerClass.ScopingStageChecknew(CId,listQues);
        }
        system.debug('resWrap'+resWrap);
        return JSON.serialize(resWrap);
    }
    public static responseWrapper GatingStageChecknew(Id ChimeId, List<Id> QuesIds,String currentStage){
        responseWrapper resWrap = new responseWrapper();
        
        List<CHIME_Product_Question__c > prodQuestions = [Select id, CHIME_Product__c,template__c  from CHIME_Product_Question__c where Form_Stage__c =: currentStage and  id in:QuesIds];
        List<CHIME_Response__c> questionResponses = [Select id,CHIME_Product_Question__c,Response__c from CHIME_Response__c where CHIME_Product_Question__c in:prodQuestions and CHIME__c =:ChimeId];
            
        if(prodQuestions.size() != questionResponses.size()){
                //return false;
                resWrap.moveToNextStage = false;
        }else{
            Chime__c chimeform = new Chime__c();
            chimeform.id=ChimeId;
            chimeform.Stage__c='Scoping';
            update chimeform;
            //return true;
            resWrap.moveToNextStage = true;
        }    
        return resWrap;
    }
    
    public static responseWrapper ScopingStageChecknew(Id ChimeId, List<Id> quesIds){
        responseWrapper resWrap = new responseWrapper();
        List<CHIME_Product_Question__c > prodQuestions = [Select id, CHIME_Product__c,template__c  from CHIME_Product_Question__c where  (Form_Stage__c = 'Gating' OR Form_Stage__c = 'Scoping' ) and id in:quesIds and Required__c= true];
        List<CHIME_Response__c> questionResponses = [Select id,CHIME_Product_Question__c,Response__c from CHIME_Response__c where CHIME_Product_Question__c in:prodQuestions and CHIME__c =:ChimeId];
        Id productId;
        Chime_Product_Association__c cpa = new Chime_Product_Association__c();
        if(prodQuestions.size()==0){
            List<CHIME_Product_Question__c > prodQuestionsWhenNoReqQues = [Select id, CHIME_Product__c,template__c  from CHIME_Product_Question__c where  (Form_Stage__c = 'Gating' OR Form_Stage__c = 'Scoping' ) and id in:quesIds ];
            if(prodQuestionsWhenNoReqQues.size()>0){
                productId = prodQuestionsWhenNoReqQues[0].CHIME_Product__c;
                //Set the flag as true on CPA if there is no mandatory questions.
                cpa =[Select id,Required_answer_on_product__c  from Chime_Product_Association__c where CHIME__c =:ChimeId and CHIME_Product__c =:productId];
                cpa.Required_answer_on_product__c = true;
            	update cpa;

                //Check the condition and set the Is_All_Qun_Ans_Complete__c flag.
                Chime__c chimeform = [Select id, Is_Emergency__c ,Opportunity__c ,Opportunity_Stage__c, Is_All_Qun_Ans_Complete__c,Is_Work_At_Risk_Investment_Work__c from Chime__c where id=:ChimeId];
                List<Chime_Product_Association__c> listCPAonChime = [Select id,Required_answer_on_product__c  from Chime_Product_Association__c where CHIME__c =:ChimeId];
         		Boolean result = true;
                for(Chime_Product_Association__c rec : listCPAonChime ){
                    result = result && rec.Required_answer_on_product__c;
                }
                if(!result){
                    resWrap.hasAnsweredReqQues = false;
                    if(chimeform.Is_All_Qun_Ans_Complete__c == true){
                        chimeform.Is_All_Qun_Ans_Complete__c = false;
                        update chimeform;
                    }
                }else{
                    resWrap.canOpenCase= true;
                    chimeform.Is_All_Qun_Ans_Complete__c = true;
                    update chimeform;
                }
            }
        }else
        if(prodQuestions.size()>0){
            productId = prodQuestions[0].CHIME_Product__c;
            //<T02>
            List<CHIME_Response__c> questionResponsesNotEmpty = new List<CHIME_Response__c>();
            for(CHIME_Response__c response : questionResponses){
                if(response.Response__c !=null && response.Response__c != '' && response.Response__c.stripHtmlTags() !=''){
                    questionResponsesNotEmpty.add(response);
                }
            }
            //</T02>
            cpa =[Select id,Required_answer_on_product__c  from Chime_Product_Association__c where CHIME__c =:ChimeId and CHIME_Product__c =:productId];
            if(prodQuestions.size() != questionResponses.size()){
                if(cpa.Required_answer_on_product__c == true){
                	cpa.Required_answer_on_product__c = false;
                	update cpa;
                }
            }
            //<T02>
            else if(prodQuestions.size() != questionResponsesNotEmpty.size()){
                if(cpa.Required_answer_on_product__c == true){
                	cpa.Required_answer_on_product__c = false;
                	update cpa;
                }
            }
            //</T02>
            else{
                cpa.Required_answer_on_product__c = true;
            	update cpa;
            }
            
            if(prodQuestions.size() == questionResponses.size()){
                Chime__c chimeform = [Select id, Is_Emergency__c ,Opportunity__c ,Opportunity_Stage__c, Is_All_Qun_Ans_Complete__c,Is_Work_At_Risk_Investment_Work__c from Chime__c where id=:ChimeId];
                List<Chime_Product_Association__c> listCPAonChime = [Select id,Required_answer_on_product__c  from Chime_Product_Association__c where CHIME__c =:ChimeId];
         		Boolean result = true;
                for(Chime_Product_Association__c rec : listCPAonChime ){
                    result = result && rec.Required_answer_on_product__c;
                }
                if(!result){
                    resWrap.hasAnsweredReqQues = false;
                    if(chimeform.Is_All_Qun_Ans_Complete__c == true){
                        chimeform.Is_All_Qun_Ans_Complete__c = false;
                        update chimeform;
                    }
                }else{
                    resWrap.canOpenCase= true;
                    chimeform.Is_All_Qun_Ans_Complete__c = true;
                    update chimeform;
                }
            }
        }
        
        return resWrap;
    }
    
    @AuraEnabled
    public static string checkForReadOnly(){
        String result='';
        Schema.DescribeSObjectResult chimeDescribe = Chime__c.sObjectType.getDescribe();
        if(chimeDescribe.Updateable){
            return 'Edit';
        }
        else if(chimeDescribe.accessible){
            return 'ReadOnly';
        }
        else{
            return '';
        }                
    }

    @AuraEnabled
    public static sObject getProductIdByName(string productName){
        List < sObject > listRecs;
        String soql = 'select Id,Product_Name__c from PAC_Product_Catalog__c where Product_Name__c like \''+ productName+ '\' and Is_Available_For_Chime__c = true limit 1';
        listRecs= Database.query(soql);
        return listRecs[0];
    } 

    @AuraEnabled
    public static List<Chime_Product_Association__c> getAllProlexicProductsForChime(string chimeId){
   
        return [SELECT Id,CHIME_Product__r.Name,CHIME_Product__r.Product_Name__c, Required_answer_on_product__c
        FROM Chime_Product_Association__c 
        WHERE CHIME__c =: chimeId AND CHIME_Product__r.Approval_Required__c =true];

        
    }


    @AuraEnabled
    public static string getProlexicProductsForChime(string chimeId){
        string products='';

        For(Chime_Product_Association__c cpa:  [SELECT Id,CHIME_Product__r.Name,CHIME_Product__r.Product_Name__c
                FROM Chime_Product_Association__c 
                WHERE CHIME__c =: chimeId AND CHIME_Product__r.Approval_Required__c =true]){
                    if(products ==''){
                        products = cpa.CHIME_Product__r.Product_Name__c;
                    }else{
                        products += ';'+cpa.CHIME_Product__r.Product_Name__c ;
                    }
                }
        return products;
    }


    @AuraEnabled
    public static List<Deal_Support_Request__c> getChimeDSRs(string chimeId){

        List<Deal_Support_Request__c> lstDSRs = new List<Deal_Support_Request__c>();
        try {

            lstDSRs = [SELECT Id, Name, Account__c, Account__r.Name, Opportunity__c, Opportunity__r.Name, CHIME__c, CHIME__r.Name, Request_Type__c, Approval_Status__c ,Notes__c
                        FROM Deal_Support_Request__c  where CHIME__c = : chimeId];

            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return lstDSRs;
    }

    public static void checkChimeContactAccess(List<Id> chimeIdList, String ObjectName){
        Set<Id> contactIdSet = new Set<Id>();
        List<String> opptyClosedLostStages = GSMSettings.getValue('Closed_Opportunity_Stages').split(',');
        List<Contact> ContactListToUpdate = new List<Contact>();

        for(CHIME_Contact__c chimeContact : [Select id, Contact__c, chime__c, CHIME__r.Stage__c from CHIME_Contact__c where CHIME__c IN :chimeIdList]){
            contactIdSet.add(chimeContact.Contact__c);
        }
        
        //if(ObjectName == 'Chime'){
            for(CHIME_Contact__c chimeContact : [Select id, Contact__c, CHIME__c from CHIME_Contact__c where Contact__c IN :contactIdSet and CHIME__r.Stage__c != 'Closed' and chime__c NOT IN :chimeIdList and CHIME__r.Opportunity__r.StageName NOT IN :opptyClosedLostStages]){
                contactIdSet.remove(chimeContact.Contact__c); //Removing contact having active chime form
            }
        //}
        /*
        else if(ObjectName == 'Opportunity'){
            for(CHIME_Contact__c chimeContact : [Select id, Contact__c from CHIME_Contact__c where Contact__c IN :contactIdSet and CHIME__r.Opportunity__r.StageName NOT IN :opptyClosedLostStages and chime__c NOT IN :chimeIdList]){
                contactIdSet.remove(chimeContact.Contact__c); //Removing contact having active chime form
            }
        }*/
        
        for(Id conId : contactIdSet){
            Contact con = new Contact(Id = conId);
            con.Remove_Chime_Access_TimeStamp__c = datetime.now();
            ContactListToUpdate.add(con);
        }

        if(ContactListToUpdate.size() > 0){
            GSMUtilClass.doDatabaseUpdate(ContactListToUpdate, 'ChimeTriggerClass', 'checkChimeContactAccess');
        }
    }
    
    @AuraEnabled
    public static Boolean setEnterpriseProductFlagOnChime(Id chimeId){
        List<Chime_Product_Association__c> listCPAonChime = [Select id,Enterprise_Security_Product__c  from Chime_Product_Association__c where CHIME__c =:chimeId];
         		Boolean result = true;
                for(Chime_Product_Association__c rec : listCPAonChime ){
                    result = result && rec.Enterprise_Security_Product__c;
                }
        Chime__c chimeRec = new Chime__c();
        chimeRec.id = chimeId;
        //chimeRec.All_Enterprise_Products__c  = result;
        //update chimeRec;
        return result;
    }
    

    @AuraEnabled
    public static string  getEnterpriseProductsOnChime(Id chimeId, boolean isUpdate){
        //List<Chime_Product_Association__c> listCPAonChime = [Select id,Enterprise_Security_Product__c  from Chime_Product_Association__c where CHIME__c =:chimeId];
                String result='None';
                Boolean AllEnterprise = true;
                Boolean AtleaseOneEnterprise = false;
             
                for(Chime_Product_Association__c rec : [Select id,Enterprise_Security_Product__c  from Chime_Product_Association__c where CHIME__c =:chimeId]){
                    AtleaseOneEnterprise = AtleaseOneEnterprise || rec.Enterprise_Security_Product__c;
                    AllEnterprise = AllEnterprise && rec.Enterprise_Security_Product__c;
                }

                if(AllEnterprise){
                    result= 'All';
                }else if (AtleaseOneEnterprise){
                    result= 'Mix';
                }
                else{
                    result='None';
                }
        if(isUpdate){
            Chime__c chimeRec = new Chime__c();
            chimeRec.id = chimeId;
            chimeRec.All_Enterprise_Products__c  = result;
            update chimeRec;
        }
        return result;
    }


    @AuraEnabled
    public static Boolean checkPreSalesUser(){
        try {
            set<String> PreSalesProfilesList = new set<String>();
            List<GSM_Settings_Verbose__mdt> listPreSalesMdt = [SELECT Id,MasterLabel,Value__c from GSM_Settings_Verbose__mdt where MasterLabel = 'CHIME Pre Sales Profile Names' limit 1];
            System.debug('listPreSalesMdt'+listPreSalesMdt);
            for(GSM_Settings_Verbose__mdt mdt: listPreSalesMdt){
                PreSalesProfilesList.addAll(mdt.Value__c.split(';'));
                break;
            }
            /*set<String> PreSalesProfilesList = new set<String>{'Solutions Engineer',
			'Solutions Engineer - Manager',
			'Solutions Engineer - Restricted Country',
            'System Administrator'};*/
            Boolean response = false;
            Id userProfileId = userinfo.getProfileId();
            List<Profile> listProfile = [select id,name from Profile where id =: userProfileId ];
            System.debug('listProfile'+listProfile);
                if(PreSalesProfilesList.contains(listProfile[0].name)){
                    response = true;
                }else{
                    response = false;
                }
            
            return response;
            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    
    @AuraEnabled
    public static Boolean CaseCreationFlagCheck(String chimeId, String currentStage, Boolean isPOC){
        //This is to check for automatic Transition of stages once all the questions are answered.
        //Manual will be taken care on the LWC.
        Id CId = (ID)chimeId;
        System.debug('Cid'+CId);
        
        if(currentStage != 'Scoping'){
            return null;
        }
        else{
            Boolean result = true;
            List<CHIME_Product_Question__c> chimeProductQuestions = new List<CHIME_Product_Question__c>();
            Set<Id> productIds = new Set<Id>();
            Map<Id,Id> mapProductTemplate = new Map<Id,Id>();
            List<Chime_Product_Association__c > chimePrdctJunc = [Select id,CHIME_Product__c, CHIME__c,Chime_Product_Template__c from Chime_Product_Association__c where CHIME__c =:CId ];
            if(chimePrdctJunc.size()>0){
                for(Chime_Product_Association__c prdt : chimePrdctJunc) {
                    productIds.add(prdt.CHIME_Product__c);
                    mapProductTemplate.put(prdt.CHIME_Product__c,prdt.Chime_Product_Template__c);
                }
            }
            system.debug('productIds'+productIds);
            //Get all the product questions for template on CPA.
            List<CHIME_Product_Question__c > prodQuestions = new List<CHIME_Product_Question__c >();
            prodQuestions = [Select id, CHIME_Product__c,template__c,Required__c,Expected_Response__c,parent_question__c,Question_Type__c  from CHIME_Product_Question__c where  CHIME_Product__c in:productIds];
            
            if(prodQuestions.size()>0){
                for(CHIME_Product_Question__c ques: prodQuestions){
                    if(ques.template__c != null && ques.template__c !=''){
                        if(ques.template__c.contains(mapProductTemplate.get(ques.CHIME_Product__c))){
                            chimeProductQuestions.add(ques);
                            //System.debug('Question:'+ques.Id +'-:-'+ques);
                        }
                    }
                }
                
            }
            System.debug('chimeProductQuestions:'+chimeProductQuestions);
            System.debug('chimeProductQuestions.sze:'+chimeProductQuestions.size());
        	//Get Responses for all the questions
            List<CHIME_Response__c> questionResponses = [Select id,CHIME_Product_Question__c,Response__c from CHIME_Response__c where CHIME_Product_Question__c in:chimeProductQuestions and CHIME__c =:ChimeId];
            //Create map of Question and Response
            Map<Id,String> mapQuesResponse = new Map<Id,String>();
            for(CHIME_Response__c res: questionResponses){
                mapQuesResponse.put(res.CHIME_Product_Question__c,res.Response__c);
            }
            System.debug('mapQuesResponse:'+JSON.serializePretty(mapQuesResponse));
            
            //map of question and questiontype
            Map<Id,String> mapQuestionType = new Map<Id,String>();
            for(CHIME_Product_Question__c ques : chimeProductQuestions){
                mapQuestionType.put(ques.Id,ques.Question_Type__c);
            }
        	
        	//list of required questions
        	List<CHIME_Product_Question__c> reqParentQuestions = new List<CHIME_Product_Question__c>();
        	if(isPOC){
        		reqParentQuestions = [Select id, CHIME_Product__c,template__c  from CHIME_Product_Question__c where Required__c= true and id in:chimeProductQuestions and parent_question__c= null and POC_question__c=true];
            }else{
                reqParentQuestions = [Select id, CHIME_Product__c,template__c  from CHIME_Product_Question__c where Required__c= true and id in:chimeProductQuestions and parent_question__c= null and Full_Integration_Question__c=true];
            }
            System.debug('reqParentQuestions:'+reqParentQuestions.size());
        	//list of required Responses
        	List<AggregateResult> reqParentQuestionsResponses = [Select count(id) from CHIME_Response__c where CHIME_Product_Question__c in:reqParentQuestions and CHIME__c =:ChimeId group by CHIME_Product_Question__c];
            System.debug('reqParentQuestionsResponses:'+reqParentQuestionsResponses.size());
            //check if size of Mandatory Parent questions matches with size off responses or not.
            if(reqParentQuestions.size() != reqParentQuestionsResponses.size()){
                result = false;
                return result;
            }

            //Create map of parent-Dependent Questions.
            Map<Id,List<CHIME_Product_Question__c>> mapParentDependent = new Map<Id,List<CHIME_Product_Question__c>>();
            for(CHIME_Product_Question__c ques : chimeProductQuestions){
                if(ques.parent_question__c!=null){
                    if(mapParentDependent.containsKey(ques.parent_question__c)){
                        mapParentDependent.get(ques.parent_question__c).add(ques);
                    }else{
                        mapParentDependent.put(ques.parent_question__c,new List<CHIME_Product_Question__c>{ques} );
                    }

                }
            }
            System.debug('keys'+mapParentDependent.keySet());
            System.debug('mapPD'+JSON.serializePretty(mapParentDependent));

            //check if valid questions got answered or not?
            for(Id pques : mapParentDependent.keySet()){
                System.debug('pques'+pques);
                for(CHIME_Product_Question__c dques : mapParentDependent.get(pques)){
                    if(dques.Required__c){
                        Boolean responseMatch = false;
                        if(mapQuestionType.get(pques) == 'Multipicklist'){
                            System.debug('result:::'+mapQuesResponse.get(pques));
                            List<String> listResponseforMultiselect = (List<String>)Json.deserialize(mapQuesResponse.get(pques), String[].class);
                            if(listResponseforMultiselect.contains(dques.Expected_Response__c)){
                                responseMatch = true;
                            }
                        }else if(dques.Expected_Response__c == mapQuesResponse.get(pques)){
                            responseMatch = true;
                        }
                        if(responseMatch){
            			//System.debug('mapPD ERM'+JSON.serializePretty(mapParentDependent));
                            //needs to be considered.
                            if(mapQuesResponse.containsKey(dques.Id)){
                                //looksGood
                            }else{
                                result = false;
                                return result;
                            }
                        }
                    }
                }
            }

            if(result){
                Chime__c chimeForm = new Chime__c();
                chimeForm.Id = CId;
                chimeForm.Is_All_Qun_Ans_Complete__c = true;
                update chimeForm;
            }

            return result;
        }  
    }


}