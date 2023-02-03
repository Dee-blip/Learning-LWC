/**
 * Author : Vivek Baidya
 * Description : Apex Controller for L2Q_MEDDICC component.
 * JIRA # : SFDC-7349
 * @todo : 1. 
 *         2.
 */
public class L2Q_MEDDICC_Controller {
    
    public class DataWrapper {
        @AuraEnabled public list<Section> sectionList;
        @AuraEnabled public Opportunity opp;
        @AuraEnabled public string ebIdentified;
        @AuraEnabled public string championIdentified;
        @AuraEnabled public string competitorIdentified;
        @AuraEnabled public boolean showSalesCoachingReview;
        public DataWrapper(){
            sectionList=new list<Section>();
            opp=new Opportunity();
            ebIdentified='';
            championIdentified='';
            competitorIdentified='';
            showSalesCoachingReview=false;
        }
    }
    
    public class Section {
        @AuraEnabled public string sectionName;
        @AuraEnabled public integer sectionWeightage;
        @AuraEnabled public integer sectionCompletion;
        @AuraEnabled public list<SectionQuestionnaire> questionList;
        public Section(){
            sectionName='';
            sectionWeightage=0;
            sectionCompletion=0;
            questionList=new list<SectionQuestionnaire>();
        }
    }
    
    public class SectionQuestionnaire {
        @AuraEnabled public MEDDICC_Questionnaire__c question;
        @AuraEnabled public boolean response;
        @AuraEnabled public string nextSteps;
        @AuraEnabled public string details;
        @AuraEnabled public string meddiccId;
        public SectionQuestionnaire(){
            question=new MEDDICC_Questionnaire__c();
            response=false;
            nextSteps='';
            meddiccId='';
            details='';
        }
    }
    
    @AuraEnabled //get competitor__c picklist values
    public static list<string> getCompetitors(){
        list<string> compList = new list<string>();
        try {
            Schema.DescribeSObjectResult describeResult = ((SObject)(Type.forName('Schema.Opportunity').newInstance())).getSObjectType().getDescribe();
            Map<String, Schema.SObjectField> fieldMap = describeResult.fields.getMap(); 
            schema.describefieldresult dfield = fieldMap.get('Competitor__c').getDescribe();
            List<Schema.PicklistEntry> picklistEntries = dfield.getPickListValues();
            for(Schema.PicklistEntry picklistEntry: picklistEntries) {
                if(picklistEntry.isActive()) {
                    compList.add(picklistEntry.getValue());
                }
            }
        } 
        catch(Exception ex) {
            Sawyer.saw(ex);
            throw new AuraHandledException('An error occurred while fetching Competitors.');
        }
        return compList;
    }
    
    @AuraEnabled
    public static DataWrapper getInitialData(string opportunityId){
        DataWrapper wrap = new DataWrapper();
        list<Section> sectionList = new list<Section>();
        try {
            //preparing a map of section to its questionnaires
            map<string,list<MEDDICC_Questionnaire__c>> sectionToQuestions = new map<string,list<MEDDICC_Questionnaire__c>>();
            for(MEDDICC_Questionnaire__c question : [select Id,AKAM_MEDDICC_Questionnaire_ID__c,Question__c,Section__c,Question_Weightage__c,Section_Weightage__c from MEDDICC_Questionnaire__c order by Sequence__c asc LIMIT 50000]){
                if(sectionToQuestions.containsKey(question.Section__c)){
                    list<MEDDICC_Questionnaire__c> questions = sectionToQuestions.get(question.Section__c);
                    questions.add(question);
                    sectionToQuestions.put(question.Section__c,questions);
                }
                else
                    sectionToQuestions.put(question.Section__c,new list<MEDDICC_Questionnaire__c>{question});
            }
            
            string gsmSettingDeveloperNames = 'MEDDICC_Champion_Identified,MEDDICC_EB_Identified,MEDDICC_Competition_Identified,MEDDICC_EconomicBuyerRole,MEDDICC_ChampionRole,MEDDICC_SalesCoachingReviewProfiles';
            Map<string,string> gsmMetadata = GsmUtilClass.getKeyValueMetadata('GSM_Settings__mdt','Value__c',gsmSettingDeveloperNames,false);
            List<String> ocrRoles = new List<String>{gsmMetadata.get('MEDDICC_EconomicBuyerRole'),gsmMetadata.get('MEDDICC_ChampionRole')};
                
            boolean salesCoachingReview = (gsmMetadata.get('MEDDICC_SalesCoachingReviewProfiles').contains(UserInfo.getProfileId()))?true:false;
                
            //fetching opportunity with its meddicc and opportunitycontactroles
            Opportunity op;
            if(salesCoachingReview)
            	op = [select Id,IsClosed,Competitor__c,Competitor_Secondary__c,Other_Competitor_Name__c,Sales_Coaching_Deal_Review__c, (select Id,MEDDICC_Questionnaire__c,Next_Steps__c,Details__c,Response__c from MEDDICC__r), (Select Id, Role, ContactId, Contact.Name from OpportunityContactRoles where Role IN : ocrRoles) from Opportunity where Id=:opportunityId];
            else
                op = [select Id,IsClosed,Competitor__c,Competitor_Secondary__c,Other_Competitor_Name__c, (select Id,MEDDICC_Questionnaire__c,Next_Steps__c,Details__c,Response__c from MEDDICC__r), (Select Id, Role, ContactId, Contact.Name from OpportunityContactRoles where Role IN : ocrRoles) from Opportunity where Id=:opportunityId]; 
            
            //preparing a map of question to already created meddicc records
            map<string,MEDDICC__c> questionIdToMeddicc = new map<string,MEDDICC__c>();
            for(MEDDICC__c meddi : op.MEDDICC__r){
                questionIdToMeddicc.put(meddi.MEDDICC_Questionnaire__c, meddi);
            }
            
            //check whether economic buyer and champion role present
            boolean hasEB=false,hasChamp=false;
            for(OpportunityContactRole ocr : op.OpportunityContactRoles){
                if(ocr.Role==gsmMetadata.get('MEDDICC_EconomicBuyerRole')) hasEB=true;
                else if(ocr.Role==gsmMetadata.get('MEDDICC_ChampionRole')) hasChamp=true;
                if(hasEB && hasChamp) break;
            }
            
            //wrapper preparation of section details
            for(string section : sectionToQuestions.keySet()){
                Section sec = new Section();
                sec.sectionName=section;
                list<SectionQuestionnaire> sectionQuestionList = new list<SectionQuestionnaire>();
                integer completed=0;
                for(MEDDICC_Questionnaire__c question : sectionToQuestions.get(section)){
                    SectionQuestionnaire sQ = new SectionQuestionnaire();
                    sQ.question=question;
                    sQ.response=(questionIdToMeddicc.containsKey(question.Id))?questionIdToMeddicc.get(question.Id).Response__c:false;
                    sQ.nextSteps=(questionIdToMeddicc.containsKey(question.Id))?questionIdToMeddicc.get(question.Id).Next_Steps__c:'';
                    sQ.details=(questionIdToMeddicc.containsKey(question.Id))?questionIdToMeddicc.get(question.Id).Details__c:'';
                    sQ.meddiccId=(questionIdToMeddicc.containsKey(question.Id))?questionIdToMeddicc.get(question.Id).Id:null;
                    
                    //set response to true if economic buyer, champion, competitors already identified
                    if(question.AKAM_MEDDICC_Questionnaire_ID__c==gsmMetadata.get('MEDDICC_EB_Identified'))
                        sQ.response=(hasEB)?true:false;
                    if(question.AKAM_MEDDICC_Questionnaire_ID__c==gsmMetadata.get('MEDDICC_Champion_Identified'))
                        sQ.response=(hasChamp)?true:false;
                    if(question.AKAM_MEDDICC_Questionnaire_ID__c==gsmMetadata.get('MEDDICC_Competition_Identified'))
                        sQ.response=(!String.isBlank(op.Competitor__c) || !String.isBlank(op.Competitor_Secondary__c) || !String.isBlank(op.Other_Competitor_Name__c))?true:false;
                    
                    sectionQuestionList.add(sQ);
                    sec.sectionWeightage=Integer.valueOf(question.Section_Weightage__c);
                    if(sQ.response)
                        completed=completed+Integer.valueOf(question.Question_Weightage__c);
                }
                sec.questionList=sectionQuestionList;
                sec.sectionCompletion=Integer.valueOf((completed*100)/sec.sectionWeightage);
                sectionList.add(sec);
            }
            wrap.ebIdentified=gsmMetadata.get('MEDDICC_EB_Identified');
            wrap.championIdentified=gsmMetadata.get('MEDDICC_Champion_Identified');
            wrap.competitorIdentified=gsmMetadata.get('MEDDICC_Competition_Identified');
            wrap.showSalesCoachingReview=salesCoachingReview;
            wrap.opp=op;
            wrap.sectionList=sectionList;
        } 
        catch(Exception ex) {
            Sawyer.saw(ex);
            throw new AuraHandledException('An error occurred while loading initial data.');
        }
        return wrap;
    }
    
    @AuraEnabled
    public static DataWrapper saveMeddicc(string sectionList,opportunity opp,boolean needLoadingOfData){
        list<Section> secList = (list<Section>) System.JSON.deserialize(sectionList, List<Section> .class);
        list<MEDDICC__c> meddiccListToUpsert = new list<MEDDICC__c>();
        string secNextSteps,secDetails;
        integer index;
        for(Section s : secList){
            secNextSteps='';
            secDetails='';
            index=0;
            for(SectionQuestionnaire sQ : s.questionList){
                if(index==0){
                    secNextSteps=sQ.nextSteps;
                    secDetails=sQ.details;
                }
                MEDDICC__c meddicc = new MEDDICC__c();
                if(!String.isBlank(sQ.meddiccId)) meddicc.Id = sQ.meddiccId;
                else meddicc.Opportunity__c = opp.Id;
                meddicc.MEDDICC_Questionnaire__c = sQ.question.Id;
                meddicc.Next_Steps__c = secNextSteps;
                meddicc.Details__c = secDetails;
                meddicc.Response__c = sQ.response;
                meddicc.Question_Weightage__c = sQ.question.Question_Weightage__c;
                meddicc.Section_Completion__c = s.sectionCompletion;
                meddiccListToUpsert.add(meddicc);
                index++;
            }
        }
        
        try {
            if(!meddiccListToUpsert.isEmpty()){
                ByPassAndLimitUtils.disable('MeddiccTriggerFramework');
                ByPassAndLimitUtils.disable('OpportunityTriggerGeneric');
                database.upsert(meddiccListToUpsert,false);
            }
            Opportunity oldOppty = [select Id,Competitor__c,Competitor_Secondary__c,Other_Competitor_Name__c,Sales_Coaching_Deal_Review__c from Opportunity where Id=:opp.Id];
            if(opp.Competitor__c=='null') opp.Competitor__c=null;
            if(opp.Competitor_Secondary__c=='null') opp.Competitor_Secondary__c=null;
            
            if(oldOppty.Sales_Coaching_Deal_Review__c!=opp.Sales_Coaching_Deal_Review__c || oldOppty.Competitor__c!=opp.Competitor__c || oldOppty.Competitor_Secondary__c!=opp.Competitor_Secondary__c || oldOppty.Other_Competitor_Name__c!=opp.Other_Competitor_Name__c){
                //opp.Validation_Override__c=true;
                ByPassAndLimitUtils.disable('OpportunityTriggerGeneric');
                update opp;
            }
        }
        catch(Exception ex) {
            Sawyer.saw(ex);
            throw new AuraHandledException(ex.getMessage());
        }
        
        if(needLoadingOfData) return getInitialData(opp.Id);
        else return null; 
    }
}