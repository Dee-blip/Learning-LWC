/***
    PSA_ProjectContractLineItemActions
    @author Liz Ichihashi
    @Description : This Class contains methods called from PSA_ProjectContractLineItem_Trigger.
                   One method (on before delete) prevents deletes when there is a related Milestone or Assignment.
                   One method (on after delete) checks to see if any childless Project Contract records can
                   be deleted.
                   
                   This class supports PSA customization requirment 4.1.2 and 4.1.3 - Add/Remove Project Contract Line Item
    @History
    --Developer             --Date            --Change
    Liz Ichihashi           7/04/2013     Created the class.     
    Samir Jha               6/27/2014    2589321: Added a new function to check for Billing effective date updates on Delete
    Vandhana Krishnamurthy  3/31/2015    2883918: Project History section and Audit trail information on Project
    Sharath Prasanna        1/4/2015     2941958: Added the doLineItemCleanUp method to delete the project contract line items from projects having more than one line item.  
    Suhas Jain              03/08/2018   FFPSA-545: Automated Notification when PS Hours reaches 70% of Units Low
    
*/
public with sharing class PSA_ProjectContractLineItemActions {

    public static void checkForMilestonesOrAssignmentsBeforeDelete(Map<Id, Project_Contract_Line_Item__c> oldMap) {
        List<Project_Contract_Line_Item__c> projContractDetails = [
                                            SELECT Id, Contract_Detail__c,
                                            (SELECT Id from Assignments__r),
                                            (SELECT Id from Milestones__r)
                                             FROM Project_Contract_Line_Item__c where Id in :oldMap.keySet()];
        
        for (Project_Contract_Line_Item__c lineRow : projContractDetails) {
            if (lineRow.Milestones__r != null && lineRow.Milestones__r.size() > 0) {
                oldMap.get(lineRow.Id).addError('This Project Contract Line Item cannot be deleted because there are Milestone(s) related to it.');
            }   
            if (lineRow.Assignments__r != null && lineRow.Assignments__r.size() > 0) {
                oldMap.get(lineRow.Id).addError('This Project Contract Line Item cannot be deleted because there are Assignments(s) related to it.');
            }   
        }
    }

    public static void checkForProjectContactsToDeleteAfterLineDelete(List<Project_Contract_Line_Item__c> lineItemList) {
        Set<Id> projIds = new Set<Id>();
        for (Project_Contract_Line_Item__c lineRow : lineItemList) {
            projIds.add(lineRow.Project__c);
        }
        List<Project_Contract__c> projContListToDelete = new List<Project_Contract__c>();
        List<Project_Contract__c> projContListToCheck = [SELECT Id,
                                                          (SELECT Id FROM Project_Contract_Line_Items__r)
                                                          FROM Project_Contract__c
                                                          WHERE Project__c in :projIds];                                      
        if (projContListToCheck != null && projContListToCheck.size() > 0) {
            for (Project_Contract__c projContRow : projContListToCheck) {
                if (projContRow.Project_Contract_Line_Items__r.size() == 0) {
                    projContRow.Valid_Delete__c = true;
                    projContListToDelete.add(projContRow);
                }   
            }   
        }
        if (projContListToDelete.size() > 0) {
            update projContListToDelete;
            delete projContListToDelete;
        }   
    }

    /* this method enforces the rule that only one project contract line item can be associated to a project.  */
    /* to turn this off, remove or comment out this method. This is called on before insert. */
    public static void checkForExistingContractLineItemOnProject(List<Project_Contract_Line_Item__c> lineItemList) {    
        Set<Id> projIds = new Set<Id>();
        for (Project_Contract_Line_Item__c lineRow : lineItemList) {
            projIds.add(lineRow.Project__c);
        }

        Map<Id, pse__Proj__c> projMap = new Map<Id, pse__Proj__c>([SELECT Id,
                                          (SELECT Id FROM Project_Contract_Line_Items__r)
                                          FROM pse__Proj__c
                                          WHERE Id in :projIds]);       
                                                                      
        for (Project_Contract_Line_Item__c lineRow : lineItemList) {
            if (projMap.get(lineRow.Project__c).Project_Contract_Line_Items__r.size() > 0) {
                lineRow.addError('There is already a Project Contract Line Item associated to this Project.  Only one is allowed.');
            }   
        }
    }
    
    /* this method is called after insert of project contract line items to set contract closed to Yes */
    public static void updateProjectContractClosed(List<Project_Contract_Line_Item__c> lineItemList) {  
        Set<Id> projIds = new Set<Id>();
        for (Project_Contract_Line_Item__c lineRow : lineItemList) {
            projIds.add(lineRow.Project__c);
        }

        Map<Id, pse__Proj__c> projMap = new Map<Id, pse__Proj__c>([SELECT Id, Contract_Closed__c
                                                                  FROM pse__Proj__c
                                                                  WHERE Id in :projIds]);       
        List<pse__Proj__c> projectsToUpdate = new List<pse__Proj__c>();                                                           
        for (Project_Contract_Line_Item__c lineRow : lineItemList) {
            if (projMap.get(lineRow.Project__c).Contract_Closed__c !=  null && 
                projMap.get(lineRow.Project__c).Contract_Closed__c == 'Yes') {
                //do nothing, this project's contract closed attribute is already set to Yes
            } else {
                projMap.get(lineRow.Project__c).Contract_Closed__c = 'Yes';
                projectsToUpdate.add(projMap.get(lineRow.Project__c));
            }   
        }
        if (projectsToUpdate.size() > 0) {
            update projectsToupdate;
        }
    }
    
    /* this method enforces the rule that project contract line items may only be created   */
    /* using the VF Page from the Project View page.. */
    public static void checkForInvalidCreate(List<Project_Contract_Line_Item__c> lineItemList) {    
        for (Project_Contract_Line_Item__c lineRow : lineItemList) {
            if (!lineRow.Valid_Create__c) {
                lineRow.addError('Project Contract Line Items may only be created from the Project view page using the "Add/Remove Project Contract Line Items" button.');
            }   
        }
    }
    
    /* this method enforces the rule that project contract line items may only be deleted   */
    /* using the VF Page from the Project View page.. */
    public static void checkForInvalidDelete(List<Project_Contract_Line_Item__c> lineItemList) {    
        for (Project_Contract_Line_Item__c lineRow : lineItemList) {
            if (!lineRow.Valid_Delete__c) {
                lineRow.addError('Project Contract Line Items may only be deleted from the Project view page using the "Add/Remove Project Contract Line Items" button.');
            }   
        }
    }
    
    /*Create a Overage Data if CLI association is changed at the project level*/
    public static void createOverageData(List<Project_Contract_Line_Item__c> lineItemList) {
        
        //load all project Ids of recently created PCLIs
        List<Id> projectIds = new List<Id>();
        //load all Timedates of Project linked in PCLIs
        List<pse__Time_Date__c> timeDatesOfProjects = new List<pse__Time_Date__c>();
        //load all timedate Ids
        List<Id> timeDateIds = new List<Id>();
        //21.1 filter timedates and store the timedate recs
        List<pse__Time_Date__c> timeDateRecords = new List<pse__Time_Date__c>();
        List<PS_Approved_Hours__c> lstApprovedHrsToUpdate = new List<PS_Approved_Hours__c>();
       Map<String,Integer> nameToNumberMapping = new Map<String,Integer>();
        
        //21.1 fetch the equivalent dilling duration term
        for (Siebel_LOV__c  durationMapping : [select  
                                                Description__c, Display_Value__c 
                                               from 
                                                Siebel_LOV__c 
                                               where 
                                                Active__c = 'Y'])
        {
            nameToNumberMapping.put(durationMapping.Display_Value__c,Integer.valueOf(durationMapping.Description__c));
        }

        
        for(Project_Contract_Line_Item__c eachPCLI: lineItemList)
        {
            if(eachPCLI.Contract_Detail__c != NULL && eachPCLI.Project__c != NULL)
            {
                projectIds.add(eachPCLI.Project__c);
            }
        }
        
        //Date lastMonth = Date.today().addMonths(-1).toStartofMonth();
        
        for(PS_Approved_Hours__c approvedHr : [SELECT 
                                                    Id, Name, Approved_Hours__c, Overage_Hours__c, Billing_Period_End_Date__c, Project__c
                                                FROM 
                                                    PS_Approved_Hours__c
                                                WHERE 
                                                    Project__c IN :projectIds
                                                AND Billing_Period_End_Date__c >= THIS_MONTH
                                                ] )
        {
            PS_Approved_Hours__c ah = new PS_Approved_Hours__c();
            ah.Id = approvedHr.Id;
            approvedHr.Approved_Hours__c = 0;
            approvedHr.Overage_Hours__c = 0;                                        
            lstApprovedHrsToUpdate.add(approvedHr);
        }
        
        try
        {
            if(!lstApprovedHrsToUpdate.isEmpty())
            {
                Database.update(lstApprovedHrsToUpdate,false);
            } 
        }
        catch(Exception e)
        {
            PSA_AutoCreateProjectUtil.sendErrorMails('createOverageData Method Exception : Failed to update some of PS Approved Hours', e.getMessage() + ' : Line : '+ e.getLineNumber());
        }

        if(!projectIds.isEmpty())
        {
            //Date oneYearBefore = Date.valueOf(Date.today().addYears(-1));
            //21.1 adding more columns to differntiate timedate record to consider re-iteration only for present and future month billing period 
            for(pse__Time_Date__c td : [SELECT 
                                            Id, CLI_Overage_Filters__c , CLI_Billing_Duration__c , CLI_Effective_End_Date__c , CLI_Effective_Start_Date__c , 
                                            CLI_Record_Type__c , CLI_Units_Low__c , CLI_Units_of_Measure__c, pse__Date__c 
                                       FROM 
                                        pse__Time_date__c 
                                       WHERE 
                                        psE__timecard__r.pse__billable__C = true 
                                       AND pse__timecard__r.pse__status__C = 'Approved' 
                                       //AND pse__date__c >= :oneYearBefore
                                       AND CLI_Record_Type__c  = 'Committed'
                                       AND psE__timecard__r.pse__Project__c = :projectIds 
                                       AND pse__Hours__c != 0])
            {
                timeDateRecords.add(td);                           
            }
            
            if(!timeDateRecords.isEmpty())
            {
                //21.1 to filter the data sent to check overage method to ensure to calculate present and future overages
                List<Date> periodDates;
                for(pse__Time_date__c eachTD: timeDateRecords)
                {
                   //metod return if billing period dates and further need to validate if it falls in >= current calender month
                   periodDates = PSA_OverageController.getBillingPeriodDates(eachTD.CLI_Effective_End_Date__c,eachTD.CLI_Effective_Start_Date__c,nameToNumberMapping.get(eachTD.CLI_Billing_Duration__c),eachTD.pse__Date__c, true);
                   if(periodDates != null && periodDates.size() == 2)
                   {
                       if((periodDates[1].month()) >= Date.today().month() && (periodDates[1].year()) >= Date.today().year() )
                       {
                           timeDateIds.add(eachTD.Id);
                       } 
                    }
                }
                if(!timeDateIds.isEmpty())
                {
                    PSA_OverageController.checkOverage(timeDateIds);
                }
            }
        }
    }    
    
    /* on after insert relate all project's assignments to this new project contract line item */
    public static void checkForAssignmentsToAssociate(List<Project_Contract_Line_Item__c> lineList) {
        Map<Id, Id> projIdToProjContractItemId = new Map<Id, Id>();
        for (Project_Contract_Line_Item__c lineRow : lineList) {
            projIdToProjContractItemId.put(lineRow.Project__c, lineRow.Id);
        }
        List<pse__Assignment__c> assignments = [Select Id, 
                                                Project_Contract_Line_Item__c, pse__Project__c 
                                                From pse__Assignment__c 
                                                Where pse__Project__c in :projIdToProjContractItemId.keySet()];
        if (assignments != null && assignments.size() > 0) {                                        
            for (pse__Assignment__c assignRow : assignments) {
                assignRow.Project_Contract_Line_Item__c = projIdToProjContractItemId.get(assignRow.pse__Project__c);
            }                                       
            update assignments;
        }                                           
    }
     /*Start of changes made by Samir: to facilitate CR : 2589321 :called on after delete of Project Contract */
  public static void checkForBillingEffectiveDateUpdateOnProjContLineItemDelete(List<Project_Contract_Line_Item__c> oldList) {        
    Set<Id> projectIds = new Set<Id>();  
    for (Project_Contract_Line_Item__c projContRow : oldList) {
      projectIds.add(projContRow.Project__c);
    }
    PSA_Contract_Detail_Actions.checkProjectContractsForEarliestBillingDate(projectIds);
  }

  // start of changes by Vandhana - CR 2883918
    // method updates Contract Line Item field on Project object with the new Project Contract Line Item */
    
    public static void updateProjectContractLineItem(List<Project_Contract_Line_Item__c> lineItemList)
    {
        Set<Id> projIds = new Set<Id>();
        Set<Id> conDetIds = new Set<Id>();
        Map<Id,String> prodList = new Map<Id,String>();
        
        for (Project_Contract_Line_Item__c lineRow : lineItemList) 
        {
            conDetIds.add(lineRow.Contract_Detail__c);
        }

        Map<Id,String> merConProdMap = new Map<Id,String>();

        for(Merge_Contract_Detail__c merConDet : [SELECT Id,Product__c from Merge_Contract_Detail__c where Id in :conDetIds])
        {
            merConProdMap.put(merConDet.Id, merConDet.Product__c);
        }

        for (Project_Contract_Line_Item__c lineRow : lineItemList) 
        {
            projIds.add(lineRow.Project__c);
            prodList.put(lineRow.Project__c,lineRow.Name+' : '+merConProdMap.get(lineRow.Contract_Detail__c));
        }
        
        List<pse__Proj__c> projCLI = new List<pse__Proj__c>();

        for(Id projId : projIds )
        {
            pse__Proj__c newProject = new pse__Proj__c();
            newProject.Id = projId;
            newProject.Contract_Line_Item__c = prodList.get(projId);
            projCLI.add(newProject);
        }
        update projCLI;
    }
    //end of changes by Vandhana

    //Start of Changes by shprasan for CR - 2941958

    public static void doLineItemCleanUp(List <Project_Contract_Line_Item__c> InsertedLineItems)
    {
        Set <Id> projIds = new Set <Id>();
        Set <ID> projContLineItemIds = new Set <Id>(); 
        for (Project_Contract_Line_Item__c lineItem : InsertedLineItems)  
        {
            System.debug('THE PROJECT ID = ' + lineItem.Project__c);
            ProjIds.add(lineItem.Project__c);
            projContLineItemIds.add(lineItem.id);
        }
        
        List <Project_Contract_Line_Item__c>   deleteLineItems  = new List <Project_Contract_Line_Item__c>([select Id, Product__c from Project_Contract_Line_Item__c Where 
                                                                                                            Id not in :projContLineItemIds and Project__c in :projIds]);
        if (deleteLineItems.size() > 0)
        {
            for (Integer i = 0;i < deleteLineItems.size(); i++)
            {
                deleteLineItems.get(i).Valid_Delete__c = true;
            }
            try
            {
                update deleteLineItems;
                delete deleteLineItems;
               
            }
            catch (Exception e)
            {
                system.debug('Failed: Some Error ' + e.getMessage());
            }            
        }        
    }
    //End of changes by shprasan

    // changes by Suhas for FFPSA-545
    public static void recalculatePSHours(Map<Id, Project_Contract_Line_Item__c> pcLineItemsMap)
    {
        List<Id> projIdList = new List<Id>();
        List<PSA_Common_Setting__mdt> products = new List<PSA_Common_Setting__mdt>([Select Value_Long__c from PSA_Common_Setting__mdt where Name__c = 'GSS Protect and Perform Products']);

        Set<String> productList = new Set<String>();

        for(PSA_Common_Setting__mdt product : products)
        {
            for(String str :product.Value_Long__c.split(',') )
            {
                productList.add(str.trim());
            }
        }
        
        for(Project_Contract_Line_Item__c pcli: [select Id, Product_Text_Area__c,Unit_of_Measure__c,Units_High__c,Project__c,Product__c, Product_Id__c from Project_Contract_Line_Item__c where Id IN :pcLineItemsMap.keySet() AND Unit_of_Measure__c = 'Hour' AND Units_High__c NOT IN (null, 0) AND Units_Low__c NOT IN (null, 0) AND Contract_Detail__r.Billing_Duration__c IN ('Quarterly', 'Annual')  ])
        {
            if(productList.contains(pcli.Product_Id__c))
                {
                    projIdList.add(pcli.Project__c);
                }
        }

        if(projIdList.size() > 0)
        {
            PSA_TimecardActions.reCalculateHoursFuture(projIdList);
        }
    }
    // End of changes by Suhas for FFPSA-545


    public static void trackCLIAssociation(Map<Id, Project_Contract_Line_Item__c> pcLineItemsMap)
    {
        System.debug('asso');
        List<PCLI_Association_History__c> pcliHistoryList = new List<PCLI_Association_History__c>();
        List<Id> cliIds = new List<Id>();

        for (Project_Contract_Line_Item__c pcli : pcLineItemsMap.values() ) {
            cliIds.add(pcli.Contract_Detail__c);
        }
        
        Map<Id, Merge_Contract_Detail__c> cliMap = new Map<Id, Merge_Contract_Detail__c>([select id, Name, Product__c, Product_Id__c , Unit_of_Measure__c from Merge_Contract_Detail__c where id IN :cliIds]);



        for (Project_Contract_Line_Item__c pcli : pcLineItemsMap.values() ) {

            System.debug('pcliss :: ' + pcli.Product__c);
            System.debug('pcliss :: ' + cliMap.get(pcli.Contract_Detail__c).Name );
            System.debug('pcliss :: ' + System.UserInfo.getUserId() );

            PCLI_Association_History__c newpcliHist = new PCLI_Association_History__c();
            newpcliHist.Product_Name__c = cliMap.get(pcli.Contract_Detail__c).Product__c ;
            newpcliHist.Contract_Detail_ID__c = cliMap.get(pcli.Contract_Detail__c).Name ;
            newpcliHist.Product_ID__c = cliMap.get(pcli.Contract_Detail__c).Product_Id__c;
            newpcliHist.Project_Association_Date__c = Datetime.now();
            newpcliHist.Unit_of_Measure__c = cliMap.get(pcli.Contract_Detail__c).Unit_of_Measure__c ;
            newpcliHist.CLI_Associated_By__c = System.UserInfo.getUserId();
            newpcliHist.Project__c = pcli.Project__c;
            pcliHistoryList.add(newpcliHist);

            System.debug(' each hist  :' +  newpcliHist );
        }
        
        if(pcliHistoryList != null && pcliHistoryList.size() > 0 )
        {
            try {
                insert pcliHistoryList;
            } catch (Exception e) {
                System.debug(' exceptions : ' + e );
            }
        }
    }

    public static void trackCLIDisAssociation(List<Project_Contract_Line_Item__c> pcLineItems)
    {
        System.debug('dis ass');
        List<PCLI_Association_History__c> pcliHistoryList = new List<PCLI_Association_History__c>();
        List<Id> cliIds = new List<Id>();
        List<Id> projIds = new List<Id>();

        for (Project_Contract_Line_Item__c pcli : pcLineItems ) {
            cliIds.add(pcli.Contract_Detail__c);
            projIds.add(pcli.Project__c);
        }

        List<PCLI_Association_History__c> pcliHistList = new List<PCLI_Association_History__c>();
        Map<Id, PCLI_Association_History__c> projtoPcliHist = new Map<Id, PCLI_Association_History__c>();
        pcliHistList = [select id ,Name, Project_Disassociation_Date__c,Project_Association_Date__c, Project__c , createddate from PCLI_Association_History__c where Project__c IN:projIds ];

        for (PCLI_Association_History__c pcliHist : pcliHistList) 
        {
            if ( !projtoPcliHist.containsKey(pcliHist.Project__c) ) {
                projtoPcliHist.put(pcliHist.Project__c , pcliHist);
            }
            //Changed the and condition from Created Date to Name comparison by Manasa for Jira FFPSA - 2058 
            else if (projtoPcliHist.containsKey(pcliHist.Project__c) && Integer.valueOf(projtoPcliHist.get(pcliHist.Project__c).Name.split('PCLIAH-')[1]) < Integer.valueOf(pcliHist.Name.split('PCLIAH-')[1]) ) {
                projtoPcliHist.put(pcliHist.Project__c , pcliHist);
            }
            
        }
        
        //Map<Id, Merge_Contract_Detail__c> cliMap = new Map<Id, Merge_Contract_Detail__c>([select id, Name, Product__c, Product_Id__c from Merge_Contract_Detail__c where id IN :cliIds]);

        System.debug('climap : ' + projtoPcliHist);


        for (Project_Contract_Line_Item__c pcli : pcLineItems ) {

            PCLI_Association_History__c newpcliHist = new PCLI_Association_History__c();

            newpcliHist = projtoPcliHist.get(pcli.Project__c);
            
            //newpcliHist.Contract_Detail_ID__c = cliMap.get(pcli.Contract_Detail__c).Name ;
            //newpcliHist.Product_ID__c = cliMap.get(pcli.Contract_Detail__c).Product_Id__c;
            //newpcliHist.Product_Name__c = cliMap.get(pcli.Contract_Detail__c).Product__c ;
            if(newpcliHist.Project_Association_Date__c != null){
            newpcliHist.Project_Disassociation_Date__c = Datetime.now();
            }
            //newpcliHist.CLI_Associated_By__c = System.UserInfo.getUserId();
            //newpcliHist.Project__c = pcli.Project__c;
            pcliHistoryList.add(newpcliHist);

            System.debug(' each hist  :' +  newpcliHist );
        }

        if(pcliHistoryList != null && pcliHistoryList.size() > 0 )
        {
            try {
                update pcliHistoryList;
            } catch (Exception e) {
                System.debug(' exceptions : ' + e );
            }
        }
    }

}