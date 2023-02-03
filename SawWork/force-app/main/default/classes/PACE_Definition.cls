public class PACE_Definition extends PACE_Phase {

    public static Id definitionPhaseRecordTypeId = Schema.SObjectType.PACE_Phase__c.getRecordTypeInfosByName().get('PACE_Definition').getRecordTypeId();

    public static List<PACE_Phase__c> getDefinitionList(List<PACE_Phase__c> pList)
    { 
        List<PACE_Phase__c> definitionList = new List<PACE_Phase__c>();
        for (PACE_Phase__c defRecord: pList) 
        {
            if(defRecord.RecordType.Name=='PACE_Definition')
            {
                definitionList.add(defRecord);
            }
        }
        return definitionList;
    }

    public static PACE_Phase__c initialize(PACE_Program__c program){

        PACE_Phase__c definition = new PACE_Phase__c();
        definition.Name = program.Name + ' - Definition';
        definition.PACE_Program__c = program.Id;
        definition.RecordTypeId = definitionPhaseRecordTypeId;
        /*definition.Actual_End_Date__c = program.Definition_Actual_End_Date__c;
        definition.Actual_Start_Date__c = program.Definition_Actual_Start_Date__c;
        definition.Planned_End_Date__c = program.Definition_Planned_End_Date__c;
        definition.Planned_Start_Date__c = program.Definition_Planned_Start_Date__c;
        definition.Phase_Contract_Tolerance_Date__c = program.Definition_Phase_Contract_Tolerance_Date__c;
        definition.Target_Phase_Commit_Date__c = program.Target_Definition_Commit_Date__c;
        definition.Exception_Review_Date__c = program.Definition_Exception_Review_Date__c;
        definition.PRB_Review_Date__c = program.Definition_PRB_Review_Date__c;      */
        return definition;

    }


    public static PACE_Phase__c setValuesForUpdate(Id phaseId, PACE_Program__c program){

        PACE_Phase__c definition = new PACE_Phase__c(Id = phaseId);
        /*definition.Actual_End_Date__c = program.Definition_Actual_End_Date__c;
        definition.Actual_Start_Date__c = program.Definition_Actual_Start_Date__c;
        definition.Planned_End_Date__c = program.Definition_Planned_End_Date__c;
        definition.Planned_Start_Date__c = program.Definition_Planned_Start_Date__c;
        definition.Phase_Contract_Tolerance_Date__c = program.Definition_Phase_Contract_Tolerance_Date__c;
        definition.Target_Phase_Commit_Date__c = program.Target_Definition_Commit_Date__c;
        definition.Exception_Review_Date__c = program.Definition_Exception_Review_Date__c;
        definition.PRB_Review_Date__c = program.Definition_PRB_Review_Date__c;      */
        return definition;

    }


    public static List<PACE_Step__c> initializeDefinitionSteps(PACE_Phase__c self){

        Integer  counter = 0;
        List<PACE_StepDefinition__c> refList = [SELECT Name, Position__c from PACE_StepDefinition__c where Phase_Name__c = 'Definition' order by Position__c];
        List<PACE_Step__c> definitionSteps = new List<PACE_Step__c>();
    
        for (PACE_StepDefinition__c defnStep: refList) {
            counter++;
            definitionSteps.add(PACE_Step.initialize(self, '2.'+counter+' '+defnStep.Name, Integer.valueOf(defnStep.Position__c)));
        }

        return definitionSteps;     

    }

    public static List<PACE_Step__c> initializeDefinitionSteps(PACE_Phase__c self,List<PACE_StepDefinition__c> refList){
        Integer  counter = 0;
        List<PACE_Step__c> definitionSteps = new List<PACE_Step__c>();
        for (PACE_StepDefinition__c defnStep: refList) {
            counter++;
            definitionSteps.add(PACE_Step.initialize(self, '2.'+counter+' '+defnStep.Name, Integer.valueOf(defnStep.Position__c)));
        }
        
        return definitionSteps;     

    }


}