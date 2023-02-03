/*
Author : Samir Jha
Release : 4.0
CR: 2541504
Need to clone:
1. Project Detail
2. Customer Contacts
3. Project Contracts
4. Project Products
5. Milestones
6. Budgets
7. Assignments
 @History
    --Developer           --Date            --Change
    Sujay          10 Aug 2017:       Modified for CR - FFPSA-289. commented line 89 as new project stage should be in In Progress
    Sharath         21 June 2018      Modified for FFPSA-607. Removed insert and Query from for loops

*/
global class PSA_Project_Clone
{

    @AuraEnabled
    public static String callClone(String projId)
    {
        return CloneProjectAndChildRecords((Id)projId);    
    }

    
    webservice static string CloneProjectAndChildRecords(Id proj2Clone)
    {
        Savepoint sp = Database.setSavepoint();
        try
        {
        pse__proj__c proj2CloneRecord = [Select Name,Id,RecordTypeId,Update_Milestone_Target_Date__c,pse_Migration_Batch_Number__c,pse__Stage__c,pse__Allow_Self_Staffing__c,Customer_Live__c,Contract_Closed__c,pse__Parent_Project__c,Project_Closed_Date__c,Project_Locked__c,pse__Opportunity__c,Ongoing_Project_Recurring_Budget_Amt__c,Ongoing_Project_Recurring_Planned_Hour__c,Implementation_Complete__c,pse__Daily_Timecard_Notes_Required__c,pse__Current_Time_Period__c,Customer_Acceptance_Requested__c,pse__Closed_for_Time_Entry__c,Basic_Implementation_Complete__c,pse__Planned_Hours__c,pse__Region__c,pse__Is_Billable__c,pse__Is_Active__c,pse__Project_Type__c,Project_Sub_Type__c,pse__Start_Date__c,pse__end_Date__c,pse__account__c,CurrencyIsoCode,pse__project_Manager__c,pse__practice__c ,Project_Manager_Email_Prior__c,pse__Project_Phase__c,pse__Project_Status__c,pse__Project_Status_Notes__c,Project_Template__c,pse__Is_Template__c,pse__Time_Credited__c,pse__Time_Excluded__c,pse__Billing_Type__c from pse__proj__c where Id = :proj2Clone limit 1][0];
        if(proj2CloneRecord.pse_Migration_Batch_Number__c != NULL)
        {
            return 'Sorry! Migrated Projects cannot be cloned! We are working to get this feature on for you!';
        }
        pse__proj__c Pcloned = proj2CloneRecord.clone(false,true,false,false);
        Pcloned.Name = proj2CloneRecord.Name;
        if(proj2CloneRecord.Contract_Closed__c == 'Yes')
        Pcloned.Contract_Closed__c = 'No';
        else Pcloned.Contract_Closed__c = proj2CloneRecord.Contract_Closed__c;
        if(proj2CloneRecord.Update_Milestone_Target_Date__c == TRUE)
        {
            Pcloned.Update_Milestone_Target_Date__c = FALSE;
        }
        Pcloned.pse__Billing_Type__c = proj2CloneRecord.pse__Billing_Type__c;
        Pcloned.CurrencyIsoCode = proj2CloneRecord.CurrencyIsoCode;
        Pcloned.pse__practice__c = proj2CloneRecord.pse__practice__c ;
        Pcloned.pse__project_Manager__c = proj2CloneRecord.pse__project_Manager__c;
        Pcloned.pse__Stage__c='In Progress';
        Pcloned.Cloned_Project__c = TRUE;
        insert Pcloned;
        //Result = Result + 'Project';
        //Insert Customer Contacts
        List<Customer_Contact__c> lCustomeContactsToCopy = [select Id,Account__c,Contact__c from Customer_Contact__c where Project__c = :proj2Clone];
        List<Customer_Contact__c> lCustomeContactsToInsert = new list<Customer_Contact__c>();
        for(Customer_Contact__c c : lCustomeContactsToCopy )
        {
            Customer_Contact__c c1 = c.clone(false,true,false,false);
            c1.Project__c = Pcloned.Id;
            lCustomeContactsToInsert.add(c1);
        
        }
        insert lCustomeContactsToInsert;
        
        //Result =Result  + 'Customer Contact';
        //Insert Project Contracts
        //Changes by Sharath for FFPSA-607: removing the for loop
        //A project should have only one CLI. So, just associating that CLI to the cloned project
        List<Project_Contract__c> lProjectContract = [select Id,Original_Contract_Id__c,Account__c from Project_Contract__c where Project__c = :proj2Clone order by CreatedDate desc limit 1];
        if(lProjectContract != null && !lProjectContract.isEmpty())
        {
                Project_Contract__c pc = lProjectContract.get(0);
                Project_Contract__c pc1 = pc.clone(false,true,false,false);
                pc1.project__c = Pcloned.Id;
                insert pc1; 
                List<Project_Contract_Line_Item__c> lProjectContractLine = [select Id,Original_Contract_Id__c,Contract_Detail__c,Product_Text_Area__c,Product__c,Project_Contract__c from Project_Contract_Line_Item__c where Project__c = :proj2Clone and Project_Contract__c = :pc.Id order by CreatedDate desc limit 1];

                if(lProjectContractLine != null && !lProjectContractLine.isEmpty())
                {
                      Project_Contract_Line_Item__c pcli =  lProjectContractLine.get(0);
                      Project_Contract_Line_Item__c pcli1 = pcli.clone(false,true,false,false);
                      pcli1.project__c = Pcloned.Id;
                      pcli1.Project_Contract__c = pc1.Id;
                      pcli1.Valid_Create__c = TRUE;
                      insert pcli1;
                      Pcloned.Contract_Closed__c = proj2CloneRecord.Contract_Closed__c;
                }

        }
        //for(Project_Contract__c pc:lProjectContract)
        //{
        //  Project_Contract__c pc1 = pc.clone(false,true,false,false);
        //  pc1.project__c = Pcloned.Id;
        //  insert pc1; 
        //  ProjContId = pc1.Id;         
        //}
        //Result = Result + 'Project Contract';

        //List<Project_Contract_Line_Item__c> lProjectContractLine = [select Id,Original_Contract_Id__c,Contract_Detail__c,Product_Text_Area__c,Product__c,Project_Contract__c from Project_Contract_Line_Item__c where Project__c = :proj2Clone order by CreatedDate limit 1];
        //Id PCLId;
        //for(Project_Contract_Line_Item__c pc:lProjectContractLine )
        //{
        //  Project_Contract_Line_Item__c pc1 = pc.clone(false,true,false,false);
        //  pc1.project__c = Pcloned.Id;
        //  pc1.Project_Contract__c = ProjContId;
        //  pc1.Valid_Create__c = TRUE;
        //  insert pc1;
        //  PCLId = pc1.Id;         
        //}
        ////Result = Result + 'Project Contract Line Item';
        //if(lProjectContractLine.size()!=0)
        //{
        //Pcloned.Contract_Closed__c = proj2CloneRecord.Contract_Closed__c;
        //}
        
        //Changes by Sujay for CR - FFPSA-289. commented below as new project should be In Progress
        //Pcloned.pse__Stage__c = proj2CloneRecord.pse__Stage__c;
        if(proj2CloneRecord.Update_Milestone_Target_Date__c == TRUE)
        {
        Pcloned.Update_Milestone_Target_Date__c = TRUE;
        }
        update(Pcloned);
        list<pse__Milestone__c> lmilestone = [select Id,RecordtypeId,pse__Actual_Date__c,pse__Apply_Default_Bill_Rate_to_Timecard__c,pse__Approved__c,pse__Approved_for_Billing__c,pse__Approver__c,pse__Audit_Notes__c,Billable__c,pse__Billed__c,pse__Closed_for_Time_Entry__c,pse__Default_Bill_Rate__c,pse__Default_Bill_Rate_is_Daily_Rate__c,pse__Description__c,From_Template__c,pse__Exclude_from_Billing__c,pse__Include_In_Financials__c,Internal_Time_Only__c,pse__Milestone_Amount__c,pse__Milestone_Cost__c,Milestone_Type_List__c,Milestone_Type_Value__c,pse__Planned_Hours__c,pse__Requires_Customer_Sign_off__c,Start_Date__c,pse__Status__c,pse__Target_Date__c,Task_Milestone_Name__c,Units_High__c from pse__Milestone__c where pse__Project__c = :proj2Clone];
        list<pse__Milestone__c> lmilestoneToInsert = new list<pse__Milestone__c>();
        for(pse__Milestone__c Milestone:lmilestone)
        {
          pse__Milestone__c ms1 = Milestone.clone(false,true,false,false);
          ms1.pse__Project__c= Pcloned.Id;
          //Changes by Sharath for FFPSA-607: Adding the external ID to the milestone record:
          ms1.external_id__c = String.valueOf(Milestone.Id) + String.valueOf(Pcloned.Id);
          //ms1.Project_Contract_Line_Item__c= PCLId;
          lmilestoneToInsert.add(ms1);          
        }
        insert lmilestoneToInsert;
        Map <String, Id> externalIDtoId = new Map <String, Id>();
        for(pse__Milestone__c insertedMilestone :lmilestoneToInsert)
        {
            externalIDtoId.put(insertedMilestone.external_id__c,insertedMilestone.id);   
        }
        list<pse__Project_Methodology__c> lPProduct = [select Id,Basic_Implementation_Complete__c,pse__Description__c,pse__End_Date__c,Go_Live_Date__c,Product__c,pse__Project__c,pse__Start_Date__c from pse__Project_Methodology__c where pse__Project__c =:proj2Clone];
        list<pse__Project_Methodology__c> lPProductToInsert = new list<pse__Project_Methodology__c>();
        for(pse__Project_Methodology__c PProd:lPProduct)
        {
           pse__Project_Methodology__c pp1 = PProd.clone(false,true,false,false);
           pp1.pse__Project__c= Pcloned.Id;
           lPProductToInsert.add(pp1);
        }
        insert lPProductToInsert;
        list<pse__Budget__c> lBudget = [select Id,pse__Admin_Global_Edit__c,pse__Approved__c,pse__Approved_for_Billing__c,pse__Approver__c,pse__Audit_Notes__c,pse__Billable__c,pse__Bill_Date__c,pse__Billed__c,pse__Account__c,pse__Description__c,pse__Effective_Date__c,pse__Exclude_from_Billing__c,pse__Include_In_Financials__c,pse__Opportunity__c,pse__Project__c,pse__Status__c,pse__Type__c,pse__Amount__c from pse__Budget__c where pse__Project__c = :proj2Clone];
        list<pse__Budget__c> lBudget2Insert = new list<pse__Budget__c>();
        for(pse__Budget__c Budget :lBudget)
        {
            pse__Budget__c budget1 = Budget.clone(false,true,false,false);
            budget1.pse__Project__c= Pcloned.Id;
            lBudget2Insert.add(budget1) ;
        }
        insert lBudget2Insert;
        //Code to copy schedules and assignments
        List<pse__Assignment__c> lAssgnmnt = [select Id,pse__milestone__r.Task_Milestone_Name__c,pse__Nick_Name__c,pse__Schedule__r.Id,pse__schedule__r.pse__End_Date__c,pse__schedule__r.pse__Friday_Hours__c,pse__schedule__r.pse__Monday_Hours__c,pse__schedule__r.pse__Saturday_Hours__c,pse__schedule__r.pse__Scheduled_Days__c,pse__schedule__r.pse__Scheduled_Hours__c,pse__schedule__r.pse__Start_Date__c,pse__schedule__r.pse__Sunday_Hours__c,pse__schedule__r.pse__Thursday_Hours__c,pse__schedule__r.pse__Tuesday_Hours__c,pse__schedule__r.pse__Wednesday_Hours__c,pse__Resource__c,pse__Is_Billable__c,pse__Bill_Rate__c,pse__Assignment_Daily_Notes__c,pse__Status__c,pse__Role__c,pse__Use_Project_Currency_For_Resource_Cost__c,pse__Use_Resource_Currency_For_Resource_Cost__c,pse__Use_Resource_Default_Cost_Rate__c,pse__Use_Resource_Default_Cost_Rate_as_Daily__c,pse__Closed_for_Time_Entry__c,pse__Daily_Timecard_Notes_Required__c,pse__Description__c,pse__End_Date__c,pse__Exclude_from_Billing__c,pse__Milestone__c,pse__Planned_Hours__c,pse__Project__c,pse__Start_Date__c,pse__Time_Excluded__c,pse__Time_Credited__c from pse__Assignment__c where pse__Project__c=:proj2Clone and Non_Clonable__c = false];
        List<pse__Assignment__c> lAssgnmnt2Insert = new List<pse__Assignment__c>();
        List<pse__Schedule__c> lSchedule2insert = new list<pse__Schedule__c>();
        Map<pse__Assignment__c,pse__Schedule__c> Ass2ScheduleMap = new Map<pse__Assignment__c,pse__Schedule__c>();
        Map<String,Id> milestoneNametoID = new Map<String,Id>();
        for(pse__Assignment__c ass:lAssgnmnt)
        {
            
            pse__Schedule__c schd = new pse__Schedule__c();
            schd.pse__End_Date__c = ass.pse__Schedule__r.pse__End_Date__c;
            schd.pse__Scheduled_Hours__c = ass.pse__Schedule__r.pse__Scheduled_Hours__c;
            schd.pse__Scheduled_Days__c = ass.pse__Schedule__r.pse__Scheduled_Days__c;
            schd.pse__Start_Date__c = ass.pse__Schedule__r.pse__Start_Date__c;
            schd.pse__Friday_Hours__c = ass.pse__schedule__r.pse__Friday_Hours__c;
            schd.pse__Monday_Hours__c=ass.pse__schedule__r.pse__Monday_Hours__c;
            schd.pse__Tuesday_Hours__c=ass.pse__schedule__r.pse__Tuesday_Hours__c;
            schd.pse__Wednesday_Hours__c=ass.pse__schedule__r.pse__Wednesday_Hours__c;
            schd.pse__Thursday_Hours__c=ass.pse__schedule__r.pse__Thursday_Hours__c;
            schd.pse__Saturday_Hours__c=ass.pse__schedule__r.pse__Saturday_Hours__c;
            schd.pse__Sunday_Hours__c=ass.pse__schedule__r.pse__Sunday_Hours__c;
            //System.assertEquals(schd.Id, 'actual');
            Ass2ScheduleMap.put(ass,schd);
            lSchedule2insert.add(schd);
        }
        insert(lSchedule2insert);

        For(pse__Assignment__c ass2insert:Ass2ScheduleMap.keySet())
        {
            pse__Assignment__c Ass1 = ass2insert.clone(false,true,false,false);
            Ass1.pse__Project__c = Pcloned.Id;
            try
            {
                if(ass2insert.pse__Milestone__c != NULL)
                {
                    //Changes by Sharath for FFPSA-607: Check if the milestone is linked to the original assignment. If yes, link the cloned one as well.
                    String currentExternalId = String.valueOf(ass2insert.pse__Milestone__c) + String.valueOf(Pcloned.Id);
                    Ass1.pse__Milestone__c = externalIDtoId.containsKey(currentExternalId)?externalIDtoId.get(currentExternalId): null; 

                }
            }
            catch(exception e)
            {
                String ResultException = 'Sorry! We are currently unable to process this request. Please contact PSA IT team for resolution.';
                Database.rollback(sp);
                return ResultException;
            }
            Ass1.pse__Schedule__c = (Ass2ScheduleMap.get(ass2insert)).Id;
            lAssgnmnt2Insert.add(Ass1);
        }
        insert lAssgnmnt2Insert;
        //list<pse__Budget__c> lBudgetHeader2Insert = list<pse__Budget_Header__c>();
        return Pcloned.Id;
    }
        catch(Exception e)
        {
            String ResultException = e.getMessage().right(e.getMessage().length() - e.getMessage().lastIndexOf('_EXCEPTION,')-11);
            Database.rollback(sp);
            return ResultException;
        }
    }
    
}