public virtual class PACE_Phase{


    public static boolean firstRun = true; 
    public static boolean programDateUpdate = false; 

    public static Id conceptPhaseRecordTypeId = Schema.SObjectType.PACE_Phase__c.getRecordTypeInfosByName().get('PACE Concept').getRecordTypeId();
    public static Id definitionPhaseRecordTypeId = Schema.SObjectType.PACE_Phase__c.getRecordTypeInfosByName().get('PACE_Definition').getRecordTypeId();
    public static Id launchPhaseRecordTypeId = Schema.SObjectType.PACE_Phase__c.getRecordTypeInfosByName().get('PACE_Launch').getRecordTypeId();
    public static Id developmentPhaseRecordTypeId = Schema.SObjectType.PACE_Phase__c.getRecordTypeInfosByName().get('PACE_Development').getRecordTypeId();

    public static List<PACE_StepDefinition__c> defRefList = [SELECT Name, Position__c from PACE_StepDefinition__c where Phase_Name__c = 'Definition' order by Position__c];
    public static List<PACE_StepDefinition__c> devRefList = [SELECT Name, Position__c from PACE_StepDefinition__c where Phase_Name__c = 'Development' order by Position__c];
    public static List<PACE_StepDefinition__c> launchRefList = [SELECT Name, Position__c from PACE_StepDefinition__c where Phase_Name__c = 'Launch' order by Position__c];

    public static void afterInsert(PACE_Phase__c [] phaseList) {

        if(PACE_Phase.firstRun){

            List<PACE_Step__c> stepRecordList = new List<PACE_Step__c> ();
            List<EntitySubscription> followList = new List<EntitySubscription>();

            for (PACE_Phase__c phase: phaseList){

                if(phase.RecordTypeId == definitionPhaseRecordTypeId){
                    stepRecordList.addAll(PACE_Definition.initializeDefinitionSteps(phase,defRefList));
                }
                else if(phase.RecordTypeId == developmentPhaseRecordTypeId){
                    //  // throw new CustomException('Dev Step List Size '+devRefList.size());
                    stepRecordList.addAll(PACE_Development.initializeDevelopmentSteps(phase,devRefList));
                }
                else if(phase.RecordTypeId == launchPhaseRecordTypeId){
                    stepRecordList.addAll(PACE_Launch.initializeLaunchSteps(phase,launchRefList));
                }
                else if(phase.RecordTypeId == conceptPhaseRecordTypeId){
                    stepRecordList.addAll(PACE_Concept.initializeConceptSteps(phase));
                }               
                followList.addAll(PACE_Phase.followChatter(phase));
            }

            if (stepRecordList.size() > 0) {
                //if so create       
                try {
                    insert stepRecordList;
                }
                //error handling depends on  use case...
                //and debug log will say why insert of stepRecordList failed
                catch (Exception Ex) {
                    system.debug (ex);
                }
            }

            if (followList.size() > 0) {
                try {
                    insert followList;
                }
                catch (Exception Ex) {
                    system.debug (ex);
                }
            }


            PACE_Phase.firstRun = false;


        }

    }

    // 
    // public static void afterUpdate(PACE_Phase__c [] phaseList,map<id,PACE_Phase__c> TriggeroldMap) {
        // 
        // 
        //  if(PACE_Phase.firstRun){
            // 
            // 
            //      Set<String> triggeringDates = new Set<String>{'Actual_End_Date__c', 'Actual_Start_Date__c','Planned_End_Date__c','Planned_Start_Date__c','PRB_Review_Date__c','Exception_Review_Date__c','Phase_Commit_Date__c','Phase_Contract_Tolerance_Date__c'};
            //      List<Id> requiredProgramIds = new List<Id>();
            //      Map<Id,PACE_Program__c> programMap = new Map<Id,PACE_Program__c>();
            // 
            //      for (PACE_Phase__c phase: phaseList){
                //          requiredProgramIds.add(phase.PACE_Program__c);
                //      }
                // 
                //      for (PACE_Program__c prg  : [Select p.Version__c, p.Target_Launch_Commit_Date__c, p.Target_Development_Commit_Date__c, 
                //          p.Target_Definition_Commit_Date__c, p.SystemModstamp, p.Schedule_Status__c, p.Schedule_Reason__c, p.Resource_Status__c, p.Resource_Reason__c, 
                //          p.Program_Type__c, p.Program_Phase__c, p.Program_Manager__c, p.Product_Manager__c, p.Product_Line__c, p.OwnerId, p.Next_Major_Milestone__c, 
                //          p.Name, p.Launch_Planned_Start_Date__c, p.Launch_Planned_End_Date__c, p.Launch_Phase_Contract_Tolerance_Date__c, p.Launch_PRB_Review_Date__c, 
                //          p.Launch_Exception_Review_Date__c, p.Launch_Actual_Start_Date__c, p.Launch_Actual_End_Date__c, p.LastModifiedDate, p.LastModifiedById, 
                //          p.LastActivityDate, p.IsDeleted, p.Id, p.Division__c, p.Development_Planned_Start_Date__c, p.Development_Planned_End_Date__c, 
                //          p.Development_PRB_Review_Date__c, p.Development_Exception_Review_Date__c, p.Development_Actual_Start_Date__c, 
                //          p.Development_Actual_End_Date__c, p.Dev_Phase_Contract_Tolerance_Date__c, p.Definition_Planned_Start_Date__c, 
                //          p.Definition_Planned_End_Date__c, p.Definition_Phase_Contract_Tolerance_Date__c, p.Definition_PRB_Review_Date__c, 
                //          p.Definition_Exception_Review_Date__c, p.Definition_Actual_Start_Date__c, p.Definition_Actual_End_Date__c, p.CurrencyIsoCode, 
                //          p.CreatedDate, p.CreatedById, p.Concept__c, p.Concept_PRB_Review_Date__c, p.Concept_Exception_Review_Date__c, 
                //          p.Additional_Detail__c From PACE_Program__c p where p.Id in :requiredProgramIds])
                //      {
                    //          programMap.put(prg.Id,prg);
                    //      }
                    // 
                    // 
                    // 
                    //      for (PACE_Phase__c phase: phaseList){
                        // 
                        //          if(Util.hasChanges(triggeringDates, TriggeroldMap.get(phase.Id), phase)){
                            // 
                            //              if(phase.RecordTypeId == developmentPhaseRecordTypeId){
                                //                  PACE_Program__c program = programMap.get(phase.PACE_Program__c);
                                //                  program.Development_Actual_End_Date__c = phase.Actual_End_Date__c;
                                //                  program.Development_Actual_Start_Date__c = phase.Actual_Start_Date__c;
                                //                  program.Development_Planned_End_Date__c = phase.Planned_End_Date__c;
                                //                  program.Development_Planned_Start_Date__c = phase.Planned_Start_Date__c;
                                //                  program.Dev_Phase_Contract_Tolerance_Date__c = phase.Phase_Contract_Tolerance_Date__c;
                                //                  program.Development_Exception_Review_Date__c = phase.Exception_Review_Date__c ;
                                //                  program.Development_PRB_Review_Date__c = phase.PRB_Review_Date__c ;
                                //              }
                                //              else if(phase.RecordTypeId == definitionPhaseRecordTypeId){
                                    //                  PACE_Program__c program = programMap.get(phase.PACE_Program__c);
                                    //                  program.Definition_Actual_End_Date__c = phase.Actual_End_Date__c;
                                    //                  program.Definition_Actual_Start_Date__c = phase.Actual_Start_Date__c;
                                    //                  program.Definition_Planned_End_Date__c = phase.Planned_End_Date__c;
                                    //                  program.Definition_Planned_Start_Date__c = phase.Planned_Start_Date__c;
                                    //                  program.Definition_Phase_Contract_Tolerance_Date__c = phase.Phase_Contract_Tolerance_Date__c;
                                    //                  program.Definition_Exception_Review_Date__c = phase.Exception_Review_Date__c ;
                                    //                  program.Definition_PRB_Review_Date__c = phase.PRB_Review_Date__c ;
                                    //              }
                                    //              else if(phase.RecordTypeId == launchPhaseRecordTypeId){
                                        //                  PACE_Program__c program = programMap.get(phase.PACE_Program__c);
                                        //                  program.Launch_Actual_End_Date__c = phase.Actual_End_Date__c;
                                        //                  program.Launch_Actual_Start_Date__c = phase.Actual_Start_Date__c;
                                        //                  program.Launch_Planned_End_Date__c = phase.Planned_End_Date__c;
                                        //                  program.Launch_Planned_Start_Date__c = phase.Planned_Start_Date__c;
                                        //                  program.Launch_Phase_Contract_Tolerance_Date__c = phase.Phase_Contract_Tolerance_Date__c;
                                        //                  program.Launch_Exception_Review_Date__c = phase.Exception_Review_Date__c ;
                                        //                  program.Launch_PRB_Review_Date__c = phase.PRB_Review_Date__c ; 
                                        //              }  
                                        //          }
                                        //      }
                                        // 
                                        //      programDateUpdate = true;
                                        //      PACE_Phase.firstRun = false;
                                        //      update programMap.values();
                                        // 
                                        // 
                                        //  }
                                        // }


                                        public static void updateTabName(PACE_Phase__c [] phaseList) {


                                            if(PACE_Phase.firstRun){
                                                List<Id> requiredProgramIds = new List<Id>();
                                                Map<Id,PACE_Program__c> programMap = new Map<Id,PACE_Program__c>();

                                                for (PACE_Phase__c phase: phaseList){
                                                    requiredProgramIds.add(phase.PACE_Program__c);
                                                }

                                                for (PACE_Program__c prg  : [Select p.Last_Saved_Tab__c, p.Id From PACE_Program__c p where p.Id in :requiredProgramIds])
                                                {
                                                    programMap.put(prg.Id,prg);
                                                }

                                                for (PACE_Phase__c phase: phaseList){


                                                    if(phase.RecordTypeId == developmentPhaseRecordTypeId){
                                                        PACE_Program__c program = programMap.get(phase.PACE_Program__c);
                                                        program.Last_Saved_Tab__c = 'development';
                                                    }
                                                    else if(phase.RecordTypeId == definitionPhaseRecordTypeId){
                                                        PACE_Program__c program = programMap.get(phase.PACE_Program__c);
                                                        program.Last_Saved_Tab__c = 'definition';
                                                    }
                                                    else if(phase.RecordTypeId == launchPhaseRecordTypeId){
                                                        PACE_Program__c program = programMap.get(phase.PACE_Program__c);
                                                        program.Last_Saved_Tab__c = 'launch';
                                                    }
                                                    else if(phase.RecordTypeId == conceptPhaseRecordTypeId){
                                                        PACE_Program__c program = programMap.get(phase.PACE_Program__c);
                                                        program.Last_Saved_Tab__c = 'concept';
                                                    }  
                                                }

                                                programDateUpdate = true;
                                                PACE_Phase.firstRun = false;
                                                update programMap.values();


                                            }
                                        }


                                        public static List<EntitySubscription> followChatter(PACE_Phase__c phase){
                                            List<EntitySubscription> follow = new List<EntitySubscription>();

                                            follow.add(new EntitySubscription (parentId = phase.Id,subscriberid = phase.PACE_Program__r.Product_Manager__c));
                                            follow.add(new EntitySubscription (parentId = phase.Id,subscriberid = phase.PACE_Program__r.Program_Manager__c));


                                            return follow;      
                                        }


                                    }