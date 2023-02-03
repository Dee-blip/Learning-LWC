// New class PACE_Concept
public class PACE_Concept extends PACE_Phase {


    public static Id conceptPhaseRecordTypeId = Schema.SObjectType.PACE_Phase__c.getRecordTypeInfosByName().get('PACE Concept').getRecordTypeId();

    public static List<PACE_Phase__c> getConceptList(List<PACE_Phase__c> pList)
    { 
        List<PACE_Phase__c> definitionList = new List<PACE_Phase__c>();
        for (PACE_Phase__c defRecord: pList) 
        {
            if(defRecord.RecordType.Name=='PACE_Concept')
            {
                definitionList.add(defRecord);
            }
        }
        return definitionList;
    }

    public static PACE_Phase__c initialize(PACE_Program__c program){

        PACE_Phase__c definition = new PACE_Phase__c();
        definition.Name = program.Name + ' - Concept';
        definition.PACE_Program__c = program.Id;
        definition.RecordTypeId = conceptPhaseRecordTypeId; 
        return definition;

    }


    public static PACE_Phase__c setValuesForUpdate(Id phaseId, PACE_Program__c program){

        PACE_Phase__c definition = new PACE_Phase__c(Id = phaseId);   
        return definition;

    }


  
    
    public static List<PACE_Step__c> initializeConceptSteps(PACE_Phase__c self){

        List<PACE_StepDefinition__c> refList = [SELECT Name, Position__c from PACE_StepDefinition__c where Phase_Name__c = 'Concept' order by Position__c];
        List<PACE_Step__c> conceptSteps = new List<PACE_Step__c>();
        for (PACE_StepDefinition__c conceptStep: refList) {
            conceptSteps.add(PACE_Step.initialize(self,  '1.1 ' + conceptStep.Name, Integer.valueOf(conceptStep.Position__c)));
        }
        return conceptSteps;    
    }

 

            public static List<EntitySubscription> followChatter(PACE_Concept__c concept){
                List<EntitySubscription> follow = new List<EntitySubscription>();

                follow.add(new EntitySubscription (parentId = concept.Id,subscriberid = concept.Product_Manager__c));
                follow.add(new EntitySubscription (parentId = concept.Id,subscriberid = concept.Program_Manager__c));

                return follow;      
            }

        }