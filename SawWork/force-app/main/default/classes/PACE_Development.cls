public class PACE_Development extends PACE_Phase {

    public static Id developmentPhaseRecordTypeId = Schema.SObjectType.PACE_Phase__c.getRecordTypeInfosByName().get('PACE_Development').getRecordTypeId();

    public static List<PACE_Phase__c> getDevelopmentList(List<PACE_Phase__c> pList)
    { 
        List<PACE_Phase__c> developmentList = new List<PACE_Phase__c>();
        for (PACE_Phase__c devRecord: pList) 
        {
            if(devRecord.RecordType.Name=='PACE_Development')
            {
                developmentList.add(devRecord);
            }
        }
        return developmentList;
    }

    public static PACE_Phase__c initialize(PACE_Program__c program){

        PACE_Phase__c development = new PACE_Phase__c();
        development.Name = program.Name + ' - Development';
        development.PACE_Program__c = program.Id;
        development.RecordTypeId = developmentPhaseRecordTypeId;
        /*development.Actual_End_Date__c = program.Development_Actual_End_Date__c;
        development.Actual_Start_Date__c = program.Development_Actual_Start_Date__c;
        development.Planned_End_Date__c = program.Development_Planned_End_Date__c;
        development.Planned_Start_Date__c = program.Development_Planned_Start_Date__c;
        development.Phase_Contract_Tolerance_Date__c = program.Dev_Phase_Contract_Tolerance_Date__c;
        development.Exception_Review_Date__c = program.Development_Exception_Review_Date__c;
        development.PRB_Review_Date__c = program.Development_PRB_Review_Date__c;*/
        return development;

    }
    
    public static PACE_Phase__c setValuesForUpdate(Id phaseId, PACE_Program__c program){

        PACE_Phase__c development = new PACE_Phase__c(Id = phaseId);
        /*development.Actual_End_Date__c = program.Development_Actual_End_Date__c;
        development.Actual_Start_Date__c = program.Development_Actual_Start_Date__c;
        development.Planned_End_Date__c = program.Development_Planned_End_Date__c;
        development.Planned_Start_Date__c = program.Development_Planned_Start_Date__c;
        development.Phase_Contract_Tolerance_Date__c = program.Dev_Phase_Contract_Tolerance_Date__c;
        development.Exception_Review_Date__c = program.Development_Exception_Review_Date__c;
        development.PRB_Review_Date__c = program.Development_PRB_Review_Date__c;        */
        return development;


    }
    

    public static List<PACE_Step__c> initializeDevelopmentSteps(PACE_Phase__c self){
        Integer  counter = 0;
        List<PACE_StepDefinition__c> refList = [SELECT Name, Position__c from PACE_StepDefinition__c where Phase_Name__c = 'Development' order by Position__c];
        List<PACE_Step__c> developmentSteps = new List<PACE_Step__c>();
        for (PACE_StepDefinition__c defnStep: refList) {
            counter++;
            developmentSteps.add(PACE_Step.initialize(self,'3.'+counter+' '+defnStep.Name, Integer.valueOf(defnStep.Position__c)));
        }
        return developmentSteps;        
    }

    public static List<PACE_Step__c> initializeDevelopmentSteps(PACE_Phase__c self,List<PACE_StepDefinition__c> refList){
        Integer  counter = 0;
        List<PACE_Step__c> developmentSteps = new List<PACE_Step__c>();
        for (PACE_StepDefinition__c defnStep: refList) {
            counter++;
            developmentSteps.add(PACE_Step.initialize(self,'3.'+counter+' '+defnStep.Name, Integer.valueOf(defnStep.Position__c)));
        }
        //throw new CustomException('developmentSteps Size '+developmentSteps.size());
        return developmentSteps;        

    }




}