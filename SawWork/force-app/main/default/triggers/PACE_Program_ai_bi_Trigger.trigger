trigger PACE_Program_ai_bi_Trigger on PACE_Program__c (after insert, before insert, after update, before update) {
    if (Trigger.isInsert && Trigger.isBefore) {
        List<PACE_Program__c> changedOwnerList = new List<PACE_Program__c>();
        List<Profile> currentProfile = [SELECT Id, Name FROM Profile WHERE Id = :userinfo.getProfileId() LIMIT 1];
        String profileName = currentProfile[0].Name;

        if ((profileName != 'Product Operations') && (profileName != 'System Administrator')) {
            for (PACE_Program__c pc : Trigger.New) {
                //       PACE_Program__c oldOp = Trigger.oldMap.get(pc.Id);
                if (pc.Program_Phase__c != 'Concept') {
                    // pc.Program_Phase__c='Concept';//should this be done for all profiles?
                    pc.addError('Please select Current Program Phase as Concept');
                    return;
                }
            }
            //checking dates
            PACE_Program.validateDates(Trigger.New);
        }
    }

    if (Trigger.isInsert && Trigger.isAfter) {
        System.Debug('Program After Insert has been Called');
        PACE_Program.afterInsert(Trigger.New);
    }
    //Before Update
    if (Trigger.isUpdate && Trigger.isBefore) {
        List<PACE_Program__c> changedOwnerList = new List<PACE_Program__c>();
        List<Profile> currentProfile = [SELECT Id, Name FROM Profile WHERE Id = :userinfo.getProfileId() LIMIT 1];
        String profileName = currentProfile[0].Name;

        PACEProgramTriggerClass triggerClassObj = new PACEProgramTriggerClass();
        triggerClassObj.validateConceptToDefinitionMovement(Trigger.new, Trigger.oldMap);
        triggerClassObj.validateDefinitionToDevelopmentMovement(Trigger.new, Trigger.oldMap);
        triggerClassObj.validateDevelopmentToLaunchMovement(Trigger.new, Trigger.oldMap);
        triggerClassObj.validateDates(Trigger.new);


        for (PACE_Program__c pc : Trigger.New) {
            PACE_Program__c oldOp = Trigger.oldMap.get(pc.Id);
            if ((oldOp.Skipped_CC__c != pc.Skipped_CC__c) && pc.Skipped_CC__c == true) {
                pc.Original_CC__c = null;
                pc.Planned_CC__c = null;
            }
        }

        if ((profileName != 'Product Operations') && (profileName != 'System Administrator')) {

            for (PACE_Program__c ppc : Trigger.New) {
                if (Trigger.oldMap.get(ppc.Id).Status__c == 'Completed') {
                    ppc.addError('Program you are trying to update is Completed, Please contact product ops team for any changes');
                }
                //No matter what user profile is, if skipped cc is checked original dates can't be updated
                PACE_Program__c oldOpp = Trigger.oldMap.get(ppc.Id);
                if (ppc.Skipped_CC__c == True) {
                    if (oldOpp.Original_CC__c != ppc.Original_CC__c || oldOpp.Planned_CC__c != ppc.Planned_CC__c) {
                        ppc.addError('CC dates cannot be updated');
                        return;
                    }
                }
                //For making the current program phase field non editable

                if (oldOpp.Program_Phase__c == 'Definition') {
                    if (oldOpp.Original_CC__c != ppc.Original_CC__c || oldOpp.Planned_CC__c != ppc.Planned_CC__c) {
                        ppc.addError('CC dates cannot be updated');
                        return;
                    }
                }
                if (oldOpp.Program_Phase__c == 'Development') {
                    if (oldOpp.Original_CC__c != ppc.Original_CC__c || oldOpp.Planned_CC__c != ppc.Planned_CC__c || oldOpp.Original_EC__c != ppc.Original_EC__c || oldOpp.Planned_EC__c != ppc.Planned_EC__c) {
                        ppc.addError('CC/EC dates cannot be updated');
                        return;
                    }
                    if (oldOpp.Original_LC__c != ppc.Original_LC__c || oldOpp.Original_BETA__c  != ppc.Original_BETA__c  || oldOpp.Original_LA__c != ppc.Original_LA__c || oldOpp.Original_GA__c != ppc.Original_GA__c) {
                        if (ppc.BatchDate__c < Date.today()) { //after 14days locking
                            ppc.addError('Original LC,Beta,LA,GA dates cannot be updated');
                            return;
                        }
                    }

                }
                if (oldOpp.Program_Phase__c == 'Launch') {
                    if (oldOpp.Original_CC__c != ppc.Original_CC__c || oldOpp.Planned_CC__c != ppc.Planned_CC__c || oldOpp.Original_EC__c != ppc.Original_EC__c || oldOpp.Planned_EC__c != ppc.Planned_EC__c || oldOpp.Original_LC__c != ppc.Original_LC__c || oldOpp.Planned_LC__c != ppc.Planned_LC__c || oldOpp.Original_SC__c != ppc.Original_SC__c || oldOpp.Planned_BETA__c != ppc.Planned_BETA__c || oldOpp.Original_BETA__c != ppc.Original_BETA__c || oldOpp.Planned_Actual_SC__c != ppc.Planned_Actual_SC__c ) {
                        ppc.addError('Only Planned/Actual LA and GA can be updated');
                        return;
                    }
                }

                //if cpp is concept move to next phase only if the move to next phase button is clicked
                // if (oldOpp.Program_Phase__c=='Concept')
                // {

                if (checkRecursive.isFirstRun()) {
                    if (oldOpp.Program_Phase__c != ppc.Program_Phase__c && ppc.Validation_Override__c == False) {

                        ppc.addError('Please click on Move to Next Phase button to change Current Program Phase');
                        return;
                    } 
                    ppc.Validation_Override__c = false;
                }
            }   

            //validate dates
            PACE_Program.validateDates(Trigger.New);
        }
    }
    if (Trigger.isUpdate  && Trigger.isAfter) {
        Map<Id, List<PACE_Phase__c>> programToPhaseMap = new Map<Id, List<PACE_Phase__c>>();
        //Map<Id,PACE_Phase__c> programToPhaseMap = new Map<Id,PACE_Phase__c>();
        List<PACE_Program__c> pList = new List<PACE_Program__c>();
        List<PACE_Phase__c> phaseList = new List<PACE_Phase__c>();
        List<PACE_Phase__c> phaseList2 = new List<PACE_Phase__c>();
        //List<PACE_Phase__c> phase_con = new List<PACE_Phase__c>();
        Id definitionPhaseRecordTypeId = Schema.SObjectType.PACE_Phase__c.getRecordTypeInfosByName().get('PACE_Definition').getRecordTypeId();
        Id launchPhaseRecordTypeId = Schema.SObjectType.PACE_Phase__c.getRecordTypeInfosByName().get('PACE_Launch').getRecordTypeId();
        Id developmentPhaseRecordTypeId = Schema.SObjectType.PACE_Phase__c.getRecordTypeInfosByName().get('PACE_Development').getRecordTypeId();
        Id conceptPhaseRecordTypeId = Schema.SObjectType.PACE_Phase__c.getRecordTypeInfosByName().get('PACE Concept').getRecordTypeId();
        for (PACE_Program__c ppc : Trigger.New) {
            if (ppc.Name != Trigger.oldMap.get(ppc.Id).Name) {
                pList.add(ppc);
            }
        }
        if (pList.size() > 0) {
            for (PACE_Phase__c phaseRec : [Select Id, Name, PACE_Program__c, RecordTypeId From PACE_Phase__c Where PACE_Program__c IN :pList]) {
                phaseList2.add(phaseRec);
            }

            if (phaseList2.size() > 0) {
                for (PACE_Program__c pgm : pList) {
                    List<PACE_Phase__c> phaseL = new List<PACE_Phase__c>();
                    for (PACE_Phase__c phs : phaseList2) {
                        if (phs.PACE_Program__c == pgm.Id) {
                            phaseL.add(phs);
                        }
                    }
                    programToPhaseMap.put(pgm.Id, phaseL);
                }
            }
            for (PACE_Program__c pRec : pList) {
                List<PACE_Phase__c> phaseRec1 = programToPhaseMap.get(pRec.Id);
                for (PACE_Phase__c phaseRec : phaseRec1) {
                    if (phaseRec.RecordTypeId == definitionPhaseRecordTypeId) {
                        phaseRec.Name = pRec.Name + '- ' + 'Definition' ;
                        phaseList.add(phaseRec);
                    } else if (phaseRec.RecordTypeId == developmentPhaseRecordTypeId) {
                        phaseRec.Name = pRec.Name + '- ' + 'Development' ;
                        phaseList.add(phaseRec);
                    } else if (phaseRec.RecordTypeId == launchPhaseRecordTypeId) {
                        phaseRec.Name = pRec.Name + '- ' + 'Launch' ;
                        phaseList.add(phaseRec);
                    } else if (phaseRec.RecordTypeId == conceptPhaseRecordTypeId) {
                        phaseRec.Name = pRec.Name + '- ' + 'Concept' ;
                        phaseList.add(phaseRec);
                    }
                }
            }
        }
        if (phaseList.size() > 0) {
            update phaseList;
        }
    }

}