public class MeddiccTriggerClass {
    public static Boolean calculateSectionCompletionFirstRunFlag = true;
    public static Boolean updateMeddicResponseFirstRunFlag = true;
    
    //calculate section completion on change of response.
    public static void calculateSectionCompletion(Set<Id> opportunityIds, Set<String> sections){
        if(calculateSectionCompletionFirstRunFlag){
            //preparing a map of unique opportunity with section to its section questionnaires.
            map<string,list<MEDDICC__c>> oppToMeddicc = new map<string,list<MEDDICC__c>>();
            for(MEDDICC__c m : [select Id,Opportunity__c,Section__c,Question_Weightage__c,MEDDICC_Questionnaire__c,MEDDICC_Questionnaire__r.Section_Weightage__c,Response__c,Section_Completion__c from MEDDICC__c where Opportunity__c IN : opportunityIds and Section__c IN : sections]){
                String key = m.Opportunity__c + '##' + m.Section__c;
                if(oppToMeddicc.containsKey(key)){
                    List<MEDDICC__c> meddiList = oppToMeddicc.get(key);
                    meddiList.add(m);
                    oppToMeddicc.put(key,meddiList);
                }
                else{
                    oppToMeddicc.put(key,new List<MEDDICC__c>{m});
                }
            }
            list<MEDDICC__c> meddicToUpdate = new list<MEDDICC__c>();
            //calculation of section completion.
            for(String key : oppToMeddicc.keySet()){
                integer totalResponseVal=0, sectionWeightage=0;
                for(MEDDICC__c m : oppToMeddicc.get(key)){
                    if(m.Response__c)
                        totalResponseVal=Integer.valueOf(totalResponseVal+m.Question_Weightage__c);
                    sectionWeightage=Integer.valueOf(sectionWeightage+m.Question_Weightage__c);
                }
                integer sectionCompletion = Integer.valueOf((totalResponseVal*100)/sectionWeightage);
                for(MEDDICC__c m : oppToMeddicc.get(key)){
                    m.Section_Completion__c = sectionCompletion;
                    meddicToUpdate.add(m);
                }
            }
            try {
                if(!meddicToUpdate.isEmpty()) database.update(meddicToUpdate,false);
            }
            catch(Exception ex) { Sawyer.saw(ex); }
            calculateSectionCompletionFirstRunFlag=false;
        }
    }
    
    public static void updateMeddicResponse(List<Opportunity> competitorChangedOpptys){
        if(updateMeddicResponseFirstRunFlag){
            //preparing a map of opportunity to its competition_identified meddicc record
            map<Id,MEDDICC__c> oppToMeddic = new map<Id,MEDDICC__c>();
            for(MEDDICC__c m : [select Id,Opportunity__c,Question_Weightage__c,MEDDICC_Questionnaire__c,MEDDICC_Questionnaire__r.Section_Weightage__c,Response__c,Section_Completion__c from MEDDICC__c where Opportunity__c IN : competitorChangedOpptys and MEDDICC_Questionnaire__r.AKAM_MEDDICC_Questionnaire_ID__c =: GsmUtilClass.getGSMSettingValue('MEDDICC_Competition_Identified')]){
                oppToMeddic.put(m.Opportunity__c,m);
            }
            list<MEDDICC__c> meddicToUpdate = new list<MEDDICC__c>();
            //validating meddicc response and setting response as per selected competitor on opportunity
            for(Opportunity op : competitorChangedOpptys){
                if(oppToMeddic.containsKey(op.Id)){
                    MEDDICC__c meddicc = oppToMeddic.get(op.Id);
                    if(String.isBlank(op.Competitor__c) && String.isBlank(op.Competitor_Secondary__c) && String.isBlank(op.Other_Competitor_Name__c)){
                        if(meddicc.Response__c==true){
                            meddicc.Response__c=false; //no competitor identified
                            meddicToUpdate.add(meddicc);
                        }
                    }
                    else{
                        if(meddicc.Response__c==false){
                            meddicc.Response__c=true; //competitor identified
                            meddicToUpdate.add(meddicc);
                        }
                    }
                }
            }
            try {
                if(!meddicToUpdate.isEmpty()) database.update(meddicToUpdate,false);
            }
            catch(Exception ex) { Sawyer.saw(ex); }
            updateMeddicResponseFirstRunFlag=false;
        }
    }
}