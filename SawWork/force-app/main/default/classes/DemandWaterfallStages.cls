public without sharing  class DemandWaterfallStages
{
    public static Boolean updateLeadDemandWaterfallStageHasRun= false;
    public static Boolean createDemandWaterfallStagesHasRun = false;

    //SFDC-1102 - Called from opportu ity Trigger for all the Stage changes dependent on Opportunity Fields
    public static void updateLeadDemandWaterfallStage(Map<Id,String> leadToStageNameMap)
    {
        if(updateLeadDemandWaterfallStageHasRun)
            return;

        //Get Lead records associated with Opptys for which condition is true
        List<Lead> leadListFromOppty = [Select Id,Demand_Waterfall_Stage__c from Lead Where id IN :leadToStageNameMap.keySet() AND Status = 'Converted'];
        system.debug('List from oppty '+leadListFromOppty);

        List<Lead> leadListToUpdate = new List<Lead>();
        DMLResults res = new DMLResults(true);

        //Based on the condition being true, create list of Leads according to it's Demand Waterfall Stage Name

        if(leadListFromOppty.size() > 0)
        {
            for(Lead ldRec: leadListFromOppty)
            {
                ldRec.Demand_Waterfall_Stage__c = leadToStageNameMap.get(ldRec.Id);
                ldRec.Lead_Stage_Create_Update_Time__c = datetime.now();
                ldRec.Validation_Override__c = True;
                leadListToUpdate.add(ldRec);
            }
        }



        if(leadListToUpdate.size()>0)
        {
            res.add(Database.update(leadListToUpdate, false), leadListToUpdate);
            res.withClassName('DemandWaterfallStages').insertRecordsInErrorLog();
        }

        createDemandWaterfallStages(leadToStageNameMap);

        updateLeadDemandWaterfallStageHasRun= true;

    }

    public static void createDemandWaterfallStages(Map<Id, String> leadIdToDWS)
    {
        if(createDemandWaterfallStagesHasRun)
            return;

        List<Demand_Waterfall_Stage_History__c> dwshList = new List<Demand_Waterfall_Stage_History__c>();
        Datetime nuv = datetime.now();

        for(Demand_Waterfall_Stage_History__c dws : [Select id From Demand_Waterfall_Stage_History__c Where Lead__c In :leadIdToDWS.keySet() AND End_Date__c = null])
        {
            dws.End_Date__c = nuv;
            dwshList.add(dws);
        }

        String stageSRL = GSMUtilClass.getGSMSettingValue('DWLSStageSRL');
        String stageLB = GSMUtilClass.getGSMSettingValue('DWLSStageLB');
        String stageTRL = GSMUtilClass.getGSMSettingValue('DWLSStageTRL');
        DMLResults results= new DMLResults(true);

        for(Id eyeDee : leadIdToDWS.keySet())
        {
            Demand_Waterfall_Stage_History__c dwsNew = new Demand_Waterfall_Stage_History__c();
            dwsNew.Lead__c = eyeDee;
            String dwStage = leadIdToDWS.get(eyeDee);
            dwsNew.Stage_Name2__c = dwStage;
            dwsNew.Start_Date__c = nuv;


            if(dwStage == stageSRL || dwStage== stageTRL || dwStage== stageLB)
                dwsNew.End_Date__c = nuv;

            system.debug(' dwsh '+dwsNew);
            dwshList.add(dwsNew);

        }

        if(dwshList.size()>0)
        {
            results.add(Database.upsert(dwshList, false), dwshList);
            results.withClassName('DemandWaterfallStages').insertRecordsInErrorLog();
        }

        createDemandWaterfallStagesHasRun=true;

    }

}