global class PACE_Program {


    public static boolean firstRun = true; 


    public static Id programCreateRecordType = Schema.SObjectType.PACE_Program__c.getRecordTypeInfosByName().get('PACE Program Record Type').getRecordTypeId();
    // 1.Method which is invoked on afterInsert trigger of PACE_Program__c object to cauto create 3 phases 

    public static void afterInsert(PACE_Program__c [] pdiList) {
        System.Debug('after insert enter');
        if(PACE_Program.firstRun){
            System.Debug('after inser enter 2');
            //Put all new records in a list so we only execute one DML statement
            List<PACE_Phase__c> phaseRecordList = new List<PACE_Phase__c> ();
            List<EntitySubscription> followList = new List<EntitySubscription>();

            for (PACE_Program__c pdi: pdiList){
                // Initialize and create phase objects
                phaseRecordList.add(PACE_Concept.initialize(pdi));
                phaseRecordList.add(PACE_Definition.initialize(pdi));
                phaseRecordList.add(PACE_Development.initialize(pdi));
                phaseRecordList.add(PACE_Launch.initialize(pdi));
                followList.addAll(PACE_Program.followChatter(pdi));
            }
            //once loop is finished, check if any new records were requried
            if (phaseRecordList.size() > 0) {
                //if so create       
                try {
                    System.Debug('phaselist'+ phaseRecordList.size());
                    insert phaseRecordList;
                    System.Debug('insert of phases successful');
                }
                //error handling depends on  use case...
                //and debug log will say why insert of phaseRecordList failed
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

            PACE_Program.firstRun = false;
        }

    } //end after insert

    public static void validateDates(List<PACE_Program__c> newTrigger){

        List<String> programError = new List<String>();
        
        for(PACE_Program__c program: newTrigger){

            programError.clear();

            //Dates need to be validated only for NON EOL/EOS programs
            if(program.Program_Type__c == 'EOL/EOS'){
                continue;
            }

            //if original date is filled, corresponding planned date cannot be blank and vice versa
            //if ( ((program.Original_CC__c == null && program.Planned_CC__c !=null) || (program.Original_CC__c != null && program.Planned_CC__c ==null)) && program.Skipped_CC__c == false){
            //    programError.add('Make sure both Original and Planned CC dates are filled.');
            //}

            if ( (program.Original_EC__c == null && program.Planned_EC__c !=null) || (program.Original_EC__c != null && program.Planned_EC__c ==null) ) {
                programError.add('Make sure both Original and Planned EC dates are filled.');
            }

            if ( (program.Original_LC__c == null && program.Planned_LC__c !=null) || (program.Original_LC__c != null && program.Planned_LC__c ==null) ) {
                programError.add('Make sure both Original and Planned LC dates are filled.');
            }

            if ( (program.Original_SC__c == null && program.Planned_Actual_SC__c !=null) || (program.Original_SC__c != null && program.Planned_Actual_SC__c ==null) ) {
                programError.add('Make sure both Original and Planned SC dates are filled.');
            }

            if ( (program.Original_LA__c == null && program.Planned_LA__c !=null) || (program.Original_LA__c != null && program.Planned_LA__c ==null) ) {
                programError.add('Make sure both Original and Planned LA dates are filled.');
            }

            if ( (program.Original_GA__c == null && program.Planned_GA__c !=null) || (program.Original_GA__c != null && program.Planned_GA__c ==null) ) {
                programError.add('Make sure both Original and Planned GA dates are filled.');
            }   

            //CONCEPT 
            //At concept, if Original CC is filled in, Planned/Actual CC cannot be blank. And vice-versa.
            //if(program.Program_Phase__c == 'Concept'){
            //    if ( ((program.Original_CC__c == null && program.Planned_CC__c ==null) || (program.Original_CC__c != null && program.Planned_CC__c ==null)) && program.Skipped_CC__c == false){
            //        programError.add('Make sure both Original and Planned CC dates are filled.');
            //    }
            //}

            //DEFINITION
            //Original and Planned/Actual CC cannot be blank (unless skip cc is checked)
            //Original and Planned/Actual EC cannot be blank
            //Resource and Schedule status cannot be blank.
            //If status is Yellow or Red (Other than Green), reason cannot be blank.
            if(program.Program_Phase__c == 'Definition'){

                if(!program.Skipped_CC__c){
                    if(program.Original_CC__c == null && program.Planned_CC__c == null){
                        programError.add('Make sure both Original and Planned CC dates are filled.'); 
                    }
                }

                if(program.Original_EC__c == null && program.Planned_EC__c == null){
                    programError.add('Make sure both Original and Planned EC dates are filled.');
                }

                if(program.Resource_Status__c == null){
                    programError.add('Resource Status cannot be blank.');
                }

                if(program.Schedule_Status__c == null){
                    programError.add('Schedule Status cannot be blank.');
                }

                if( (program.Schedule_Status__c == 'At Risk' || program.Schedule_Status__c == 'Off Track') && program.Schedule_Reason__c == null) { 
                    programError.add('Schedule Reason cannot be blank.');
                }

                if( (program.Resource_Status__c == 'At Risk' || program.Resource_Status__c == 'Off Track') && program.Resource_Reason__c == null) {
                    programError.add('Resource Reason cannot be blank.');
                }
            }

            //DEVELOPMENT AND LAUNCH
            //Original and Planned/Actual CC cannot be blank (unless skip cc is checked)
            //Original and Planned/Actual EC cannot be blank
            //Original and Planned/Actual LC cannot be blank
            //Both Original LA and Original GA cannot be blank (One can be blank)
            //Both Planned/Actual LA and Planned/Actual GA dates cannot be blank (One can be blank)
            //Resource and Schedule status cannot be blank.
            //If status is Yellow or Red (Other than Green), reason cannot be blank.
            if(program.Program_Phase__c == 'Development' || program.Program_Phase__c == 'Launch'){

                if(!program.Skipped_CC__c){
                    if(program.Original_CC__c == null && program.Planned_CC__c == null){
                        programError.add('Make sure both Original and Planned CC dates are filled.');
                    }
                }

                if(program.Original_EC__c == null && program.Planned_EC__c == null){
                    programError.add('Make sure both Original and Planned EC dates are filled.');
                }

                //if(program.Original_LC__c == null && program.Planned_LC__c == null){
                //    programError.add('Make sure both Original and Planned LC dates are filled.');
                //}

                if(program.Original_LA__c == null && program.Original_GA__c == null){
                    programError.add('Both Original LA and GA dates cannot be blank. One can be blank at a time.');   
                }

                if(program.Planned_LA__c == null && program.Planned_GA__C == null){
                    programError.add('Both Planned LA and GA dates cannot be blank. One can be blank at a time.');   
                }

                if(program.Resource_Status__c == null){
                    programError.add('Resource Status cannot be blank.');
                }

                if(program.Schedule_Status__c == null){
                    programError.add('Schedule Status cannot be blank.');
                }

                if( (program.Schedule_Status__c == 'At Risk' || program.Schedule_Status__c == 'Off Track') && program.Schedule_Reason__c == null) { 
                    programError.add('Schedule Reason cannot be blank.');
                }

                if( (program.Resource_Status__c == 'At Risk' || program.Resource_Status__c == 'Off Track') && program.Resource_Reason__c == null) {
                    programError.add('Resource Reason cannot be blank.');
                }

            }

            if(programError.size() > 0){
                program.addError(String.join(programError, '<br/>'), false);
            }
            //program.addError(String.valueOf(programError.size()));

        }
    }

    //Method also populates few fields from the associated Concept
    //end before insert
    /*
    public static void beforeInsert(PACE_Program__c [] pdiList) {

        Set<Id> conceptIdSet = new Set<Id>();
        Map<Id,PACE_Program__c> programIdToObjectMap = new  Map<Id,PACE_Program__c>();
        Map<Id,PACE_Concept__c> conceptIdToObjectMap = new  Map<Id,PACE_Concept__c>();

        for (PACE_Program__c pdi: pdiList){
            programIdToObjectMap.put(pdi.Id,pdi);
            conceptIdSet.add(pdi.Concept__c);
        }
        //Adding the populated Concept fileds into the Program
        for (PACE_Concept__c concept  : [Select  Id, Program_Manager__c,Product_Manager__c,Product_Line__c,Division__c,Program__c from PACE_Concept__c where Id IN :conceptIdSet])
        {
            conceptIdToObjectMap.put(concept.Id,concept);
        }

        for(String programId:programIdToObjectMap.keySet()){
            PACE_Program__c temp = programIdToObjectMap.get(programId);
            PACE_Concept__c concept = conceptIdToObjectMap.get(temp.Concept__c);
            temp.Product_Manager__c = concept.Product_Manager__c;
        }

    }*/

    // 
    // // Method which is invoked on afterUpdate trigger of PACE_Program__c object
    // public static void afterUpdate(PACE_Program__c [] pdiList,map<id,PACE_Program__c> TriggeroldMap) {
    // 
    // 
    //  if(PACE_Program.firstRun && !PACE_Phase.programDateUpdate){
    // 
    //      List<PACE_Phase__c> phaseRecordList = new List<PACE_Phase__c> ();
    // 
    //      Map<Id,PACE_Program__c> defPhaseObjectMap = new Map<Id,PACE_Program__c>();
    //      Map<Id,PACE_Program__c> devPhaseObjectMap = new Map<Id,PACE_Program__c>();
    //      Map<Id,PACE_Program__c> launchPhaseObjectMap = new Map<Id,PACE_Program__c>();
    //                  List<EntitySubscription> followList = new List<EntitySubscription>();
    //      
    // 
    //      Set<String> defDates = new Set<String>{'Definition_Actual_End_Date__c', 'Definition_Actual_Start_Date__c','Definition_Planned_End_Date__c','Definition_Planned_Start_Date__c','Definition_Phase_Contract_Tolerance_Date__c','Definition_Exception_Review_Date__c','Definition_PRB_Review_Date__c'};
    //      Set<String> devDates = new Set<String>{'Development_Actual_End_Date__c', 'Development_Actual_Start_Date__c','Development_Planned_End_Date__c','Development_Planned_Start_Date__c','Dev_Phase_Contract_Tolerance_Date__c','Development_Exception_Review_Date__c','Development_PRB_Review_Date__c'};
    //      Set<String> launchDates = new Set<String>{'Launch_Actual_End_Date__c', 'Launch_Actual_Start_Date__c','Launch_Planned_End_Date__c','Launch_Planned_Start_Date__c','Launch_Phase_Contract_Tolerance_Date__c','Launch_Exception_Review_Date__c','Launch_PRB_Review_Date__c'};
    // 
    //      for (PACE_Program__c pdi: pdiList){
    // 
    //          if(Util.hasChanges(defDates, TriggeroldMap.get(pdi.Id), pdi)){
    //              defPhaseObjectMap.put(pdi.Id,pdi);
    //          }
    //          else if(Util.hasChanges(devDates, TriggeroldMap.get(pdi.Id), pdi)){
    //              devPhaseObjectMap.put(pdi.Id,pdi);
    //          }
    //          else if(Util.hasChanges(launchDates, TriggeroldMap.get(pdi.Id), pdi)){
    //              launchPhaseObjectMap.put(pdi.Id,pdi);
    //          }
    //          
    //          
    //          followList.addAll(PACE_Program.followChatter(pdi));
    //          
    //      }
    // 
    // 
    //      for(PACE_Phase__c defPhase : [Select Id,PACE_Program__c From PACE_Phase__c where PACE_Program__c in :defPhaseObjectMap.values()]){
    //          phaseRecordList.add(PACE_Definition.setValuesForUpdate(defPhase.Id,defPhaseObjectMap.get(defPhase.PACE_Program__c)));
    //      }
    //      for(PACE_Phase__c devPhase : [Select Id,PACE_Program__c From PACE_Phase__c where PACE_Program__c in :devPhaseObjectMap.values()]){
    //          phaseRecordList.add(PACE_Development.setValuesForUpdate(devPhase.Id,devPhaseObjectMap.get(devPhase.PACE_Program__c)));
    //      }       
    //      for(PACE_Phase__c launchPhase : [Select Id,PACE_Program__c From PACE_Phase__c where PACE_Program__c in :launchPhaseObjectMap.values()]){
    //          phaseRecordList.add(PACE_Launch.setValuesForUpdate(launchPhase.Id,launchPhaseObjectMap.get(launchPhase.PACE_Program__c)));
    //      }       
    // 
    //      //once loop is finished, check if any new records were requried
    //      if (phaseRecordList.size() > 0) {
    //          //if so create       
    //          try {
    //              update phaseRecordList;
    //          }
    //          //error handling depends on  use case...
    //          //and debug log will say why insert of phaseRecordList failed
    //          catch (Exception Ex) {
    //              system.debug (ex);
    //          }
    //      }
    //      
    //      
    //      //once loop is finished, check if any new records were requried
    //      if (followList.size() > 0) {
    //          //if so create       
    //          try {
    //              insert followList;
    //          }
    //          //error handling depends on  use case...
    //          //and debug log will say why insert of phaseRecordList failed
    //          catch (Exception Ex) {
    //              system.debug('============== Error while adding feed list ==============');
    //              system.debug (ex);
    //              
    //          }
    //      }
    //      PACE_Program.firstRun = false;
    //  }
    //  else{
    //      PACE_Phase.programDateUpdate = false;
    //  }
    // 
    // } //end after insert
    
    
    // Method which is invoked on afterUpdate trigger of PACE_Program__c object
   /* public static void beforeUpdate(PACE_Program__c [] pdiList,map<id,PACE_Program__c> TriggeroldMap) {
    
        if(PACE_Program.firstRun && !PACE_Phase.programDateUpdate){
    
            for (PACE_Program__c pdi: pdiList){
                
                if(!Util.hasChanges('Last_Saved_Tab__c', TriggeroldMap.get(pdi.Id), pdi)){
                pdi.Last_Saved_Tab__c = 'program';
                }
            }
            PACE_Program.firstRun = false;
            }
        
    } *///end after insert

    // This is for prepopulating the program page
    /*
    Webservice static String Initialize_Program(Id p_programManagerId,String p_programManagerName,Id p_productManagerId, 
        String p_productManagerName, String p_productLineName, Id p_productLineId,String p_division, 
        Id p_concept,String p_conceptName)
    {

        // Initialize static variables
        String prefix = '/' + PACE_Program__c.sObjectType.getDescribe().getKeyPrefix() + '/e?';
        String conceptPrefix = '/' + p_concept;
        
        PageReference returnURL = new Pagereference (prefix);   

        PACE_Field_Keys__c mc = PACE_Field_Keys__c.getValues('PACE');

        // Set the "Record Type" to "PLM Task"  
        returnURL.getParameters().put(mc.Product_Manager_Id__c, p_productManagerId);        
        returnURL.getParameters().put(mc.Product_Manager_Name__c, p_productManagerName);        
        returnURL.getParameters().put(mc.Program_Manager_Name__c, p_programManagerName);        
        returnURL.getParameters().put(mc.Program_Manager_Id__c, p_programManagerId);        
        returnURL.getParameters().put(mc.Product_Line__c, p_productLineName);       
        returnURL.getParameters().put(mc.Product_Line_Id__c , p_productLineId);     
        returnURL.getParameters().put(mc.Division__c, p_division);  
        returnURL.getParameters().put('Division', p_division);  
        returnURL.getParameters().put(mc.Concept_Id__c, p_concept); 
        returnURL.getParameters().put(mc.Concept_Name__c, p_conceptName);   
        returnURL.getParameters().put('retURL', conceptPrefix); 

        // Set the navigation parameters for the URL
        returnURL.setRedirect(true);
        return  returnURL.getUrl(); 
    }
    */
        // This is for prepopulating teh program page
        /*
    Webservice static Integer checkProgramCount(Id p_concept)
    {
         Integer cntProgram = [Select count() From PACE_Program__c p where p.Concept__c = :p_concept];
         return cntProgram;
    }
    */
    public static List<EntitySubscription> followChatter(PACE_Program__c program){
        List<EntitySubscription> follow = new List<EntitySubscription>();

        follow.add(new EntitySubscription (parentId = program.Id,subscriberid = program.Product_Manager__c));
        follow.add(new EntitySubscription (parentId = program.Id,subscriberid = program.Program_Manager__c));
        return follow;      
    }

    // This is for prepopulating teh program page
    Webservice static String Create_Program()
    {

        // Initialize static variables
        String prefix = '/' + PACE_Program__c.sObjectType.getDescribe().getKeyPrefix() + '/e?';
        PageReference returnURL = new Pagereference (prefix);   

        returnURL.getParameters().put('RecordType', programCreateRecordType);       
        // Set the navigation parameters for the URL
        returnURL.setRedirect(true);
        return  returnURL.getUrl(); 
    }

}