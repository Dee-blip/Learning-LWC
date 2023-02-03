/***
    PSA_CreateProjFromTemp_Controller
    @author Liz Ichihashi
    @Description : This Class is invoked from the button Create Project from Template (Akamai) on either
                   the Account or Opportunity page.  It allows a user to select a project template
                   and use it as the basis for a new project.  It allows users to quickly
                   add project, budget, milestones and resource requests while creating
                   a new project.  The page is built to resemble the PSA Standard Create Project From Template Page
                   
                   This class supports PSA customization requirment 3.4.1 and 3.4.6 - Select Project Template, Create Project
    @History
    --Developer           --Date            --Change
    Liz Ichihashi         12/04/2010        Created the class. 
    Jaya                  24 Oct 2013       Modified the class for CR 2420508.
    Sonia                 20 May 2013       CR 2576469: Capture the project template that was used during creation of a project.
    Suhas                 29 Jan 2018       Changes by Suhas Jain as per FFPSA-316 
*/
public class PSA_CreateProjFromTemp_Controller extends PSA_ProjectContractBase_Controller {
    /* List of all template projects retrieved */
    public List<pse__Proj__c> templateList {get; set;}  
    public pse__Proj__c selectedTemplate {get; set;}
    /* new project and related objects to save */ 
    public pse__Proj__c newProject {get; set;}  
    public PSA_SelectableObject newBudget {get; set;}
    public List<PSA_SelectableObject> newResourceRequests {get; set;}
    public List<PSA_SelectableObject> oppResourceRequests {get; set;}
    public List<PSA_SelectableObject> newMilestones {get; set;}
    public List<PSA_SelectableObject> newProjectTasks {get; set;}
    
    public Contact userContact;
    /* base query without any filter */
    public static String baseSQlString ='Select Id, Name, pse__Account__c, pse__Group__c, pse__Region__c, pse__Practice__c, '+
                                        'pse__Planned_Hours__c, pse__Project_Manager__c, pse__Project_Type__c, Project_Sub_Type__c, '+
                                        'CurrencyIsoCode, pse__Start_Date__c, pse__End_Date__c, pse__Is_Active__c, '+
                                        'pse__Is_Billable__c, pse__Time_Credited__c, pse__Time_Excluded__c, Contract_Closed__c,'+
                                        'Ongoing_Project_Recurring_Planned_Hour__c, Ongoing_Project_Recurring_Budget_Amt__c ' +
                                        'from pse__Proj__c where pse__Is_Template__c = true ';
    public String projNameFilter {get; set;}
    public String retURL {get; set;}
    public List<PSA_SelectableObject> templateHolderList {get; set;}
    public boolean hasError {get; set;}

    public String conDetail {get;set;}
    public String conDetailName {get;set;}
    public String conDetailProduct {get;set;}
    

    public boolean isClassic
    {
        get
        {
            return (UserInfo.getUiThemeDisplayed() == 'Theme3');

        }
        set;
    }
    public String pageOppId
    {
        get
        {
            if(pageOppId == null)
            {
                pageOppId = ApexPages.currentPage().getParameters().get('oppId');
            }
            return pageOppId;
        }
        set;
    }   

    public String pageAccountId
    {
        get
        {
            if(pageAccountId == null)
            {
                pageAccountId = ApexPages.currentPage().getParameters().get('acctId');
            }
            return pageAccountId; 
        }
        set;
    }   

    public PSA_CreateProjFromTemp_Controller() {
        isTemplateSelected = false; 
        hasError = false;
        isComingFromProjTemplatePage = true;
        isSelectingContractLineItems = false;
    }  
    
    public boolean getHasOppRequests() {
        if (oppResourceRequests != null && oppResourceRequests.size() > 0) {
            return true;
        }
        return false;
    }
    
    public boolean getHasTemplateRequests() {
        if (newResourceRequests != null && newResourceRequests.size() > 0) {
            return true;
        }
        return false;
    }
    
    public boolean getShowTemplateList() {
        if (!isTemplateSelected && !isSelectingContractLineItems && !hasError) {
            return true;
        }
        return false;   
    }
    
    public boolean getShowSelectContractLineItems() {
        if (isSelectingContractLineItems && isTemplateSelected && !hasError) {
            return true;  
        }
        return false;   
    }
    
    public boolean getShowProjectDetails() {
        if (isTemplateSelected && !isSelectingContractLineItems && !hasError) {
            return true;
        }
        return false;   
    }
    
    /* setup methodd is called in action attribute on VF page */    
    public override PageReference setup() {  
        throwException = false;
        isComingFromProjTemplatePage = true;
        /* setup page with all templates displayed by default */
        try {
            projNameFilter = '';
            /* this page may be reached from the Account page or the Opportunity page.  */
            /* Check to see which of the parameters is present (oppId or acctId) */
            /* New project will be related to either the Account or Opportunity, so get needed data to link to */
            /* Use base query to retrieve all project templates */
            String oppId = ApexPages.currentPage().getParameters().get('oppId');
            System.debug('oppId='+oppId);
            if (oppId != null && oppId.length() > 0) {
                opp = [Select Id, Name, pse__Region__c, pse__Practice__c, AccountId from Opportunity where Id = :oppId];
            }
            String acctId = ApexPages.currentPage().getParameters().get('acctId');
            if ((acctId == null || acctId.length() == 0) && opp != null) {
                acctId = opp.AccountId;
            }
            System.debug('acctId='+acctId);
            if (acctId != null && acctId.length() > 0) {
                acct = [Select Id, Name, TERR_HIER_5__c, Contract_Currency__c from Account where id = :acctId];
            } 
            System.debug('acct='+acct);
            /* perform validation to ensure there is an Account Invoice Currency */
            if (checkForAccountCurrency()) {
                queryForData(baseSQLString);
            }
        } catch (Exception e) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, e.getMessage()));
        }   
            
        return null;
    }
    /* called from Filter button on page.   Check project name filter and re-query db */
    public PageReference filterProjects() {
        String currSQLString = baseSQLString;
        if (projNameFilter != null && projNameFilter.length() > 0) {
            currSQLString += ' and Name like \'%' + projNameFilter + '%\'';
        } 
        queryForData(currSQLString);
        
        return null;
    }
    
    /* get data from db that meets filter criteria  */
    private boolean queryForData(String queryString) {
        boolean hasData = true;
        String newQueryString;
        Id profileId=userinfo.getProfileId();
		String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        
        if (Test.isRunningTest()) {
            newQueryString = queryString + ' order by CreatedDate desc';
        } else {
            if(profileName == 'GSS Operations'){
            	newQueryString = queryString + ' order by Name';
            }
            else{
                newQueryString = queryString + ' and Name != \'Internal/Internal - Project Template\' AND Name != \'Internal/Pre-Sales - Project Template\' order by Name';
            }
        }       
        templateList = Database.query(newQueryString);
        if (templateList != null && templateList.size() > 0) {
            makeTemplateHolderList(templateList);
        } else {
            hasData = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'No Project Templates found for the filter entered.  Please try again or clear filter to see all Templates.'));
        }
        return hasData; 
    }
    
    /*  Prepare the list of holder objects from project objects. These display on page */
    private void makeTemplateHolderList(List<pse__Proj__c> tempList) {
        templateHolderList = new List<PSA_SelectableObject>();
        for (pse__Proj__c tempRow : tempList) {
            PSA_SelectableObject selectable = new PSA_SelectableObject();
            selectable.obj = tempRow;
            templateHolderList.add(selectable);
        }  
    }
    
    /* Get the region associated with the Area on the Account */ 
    public String getRegion() {
        String retVal;
        pse__Region__c reg;
        if (acct != null && acct.TERR_HIER_5__c != null && acct.TERR_HIER_5__c.length() > 0) {
            try {
                reg = [select Id, Name from pse__Region__c where Territory__c = :acct.TERR_HIER_5__c limit 1];
            } catch (Exception e) {
                System.debug('no region found for acct.TERR_HIER_5__c ='+acct.TERR_HIER_5__c);
                //do nothing except return null;
            }   
            if (reg != null) {
                return reg.Id;
            }   
        }   
        return retVal;
    } 
      
    /* Called from clear button on page.  Call setup method which will get all templates again */  
    public PageReference clearFilter() {
        return setup();  
    }
    
    /* Called from select button on page.  Only one is allowed to be selected (via javascript) */
    public PageReference selectProject() {  
        
        boolean oneSelected = false;
        for (PSA_SelectableObject tempRow : templateHolderList) {
            if (tempRow.Selected) {
                selectedTemplate = tempRow.getProject();
                oneSelected = true;
            }
        }
        /* if  nothing has been selected, present error to user */
        if (!oneSelected) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'A Project Template must be selected.'));
            selectedTemplate = null;
        }
    
    
        /* Get the Contact Id for the logged on User.  That will be used to set the default Project Manager on Project */           
        try {
            userContact = [select Id from Contact where pse__Salesforce_User__c = :UserInfo.getUserId()];   
        } catch (Exception e) {
            //no row found for this user, do nothing
        }   
        
        List<String> projTemplateAkamIds = new List<String>();
        projTemplateAkamIds.addAll([select Value_Long__c from PSA_Common_Setting__mdt where DeveloperName = 'Project_template_for_Tasks'].Value_Long__c.split(','));
        
        if (selectedTemplate != null) {
            isTemplateSelected = true;
            /* Get all project template data including related budgets, milestones, resource requests and project products. */
            pse__Proj__c templateProj = [Select Id, Name, pse__Opportunity__c, pse__Account__c, pse__Group__c, pse__Region__c, pse__Planned_Hours__c,       
                                        pse__Practice__c, pse__Project_Manager__c, pse__Project_Type__c, Project_Sub_Type__c, CurrencyIsoCode, Contract_Closed__c,
                                        pse__Start_Date__c, pse__End_Date__c, pse__Is_Active__c, pse__Is_Billable__c, pse__Time_Credited__c, pse__Time_Excluded__c, 
                                (Select Id, Name, pse__Status__c, pse__Type__c, pse__Effective_Date__c,pse__Description__c, pse__Amount__c from pse__Budgets__r),
                                (Select Id, Name, RecordTypeId, pse__Target_Date__c, pse__Milestone_Amount__c, pse__Planned_Hours__c, pse__Actual_Date__c, Start_Date__c, Billable__c, Task_Milestone_Name__c, Milestone_Type_List__c, Internal_Time_Only__c  from pse__Milestones__r),
                                (Select Id, Name, Display_Name__c, pse__Request_Priority__c, pse__Notes__c, pse__SOW_Hours__c, pse__Status__c, pse__Resource__r.Name, pse__Staffer_Resource__r.Name, pse__Start_Date__c, pse__End_Date__c,Originating_Account__c, Resource_Request_Sub_Type__c from pse__Resource_Requests__r),
                                (select Id, Name, Billable__c,pse__Milestone__c , pse__Milestone__r.Name , pse__Status__c , pse__Start_Date_Time__c , pse__End_Date_Time__c from pse__Project_Tasks__r where pse__Project__r.AKAM_Project_ID__c IN :projTemplateAkamIds )
                                From pse__Proj__c where id = :selectedTemplate.Id]; 
                                
            if (opp !=  null) {
                /* get resource requests related to the opp.  Add these to the list of res requests to add to new project */
                /* only get requests that haven't already been assigned to another project */
                List<pse__Resource_Request__c> tempOppResourceRequests = [Select Id, Name, pse__Request_Priority__c, pse__Notes__c, pse__SOW_Hours__c, pse__Status__c, pse__Resource__r.Name, pse__Staffer_Resource__r.Name, pse__Start_Date__c, pse__End_Date__c 
                                      from pse__Resource_Request__c 
                                      where pse__Opportunity__c = :opp.Id
                                      and pse__Status__c <> 'Assigned'
                                      and pse__Status__c <> 'Cancelled'
                                      and pse__Project__c = null];      
                if (tempOppResourceRequests != null && tempOppResourceRequests.size() > 0) {
                    oppResourceRequests = new List<PSA_SelectableObject>();
                    for (pse__Resource_Request__c reqRow : tempOppResourceRequests) {
                        PSA_SelectableObject selectable = new PSA_SelectableObject();
                        selectable.obj = reqRow;
                        selectable.selected = true;
                        oppResourceRequests.add(selectable);                      
                    }
                }                                   
            }
            
            /* Clone the selected template project, retaining none of the IDs */
            /* Set remaining fields to default values as required */
            newProject = templateProj.clone(false, false, false, false);   
            //start of changes by ssawhney for CR 2576469
            newProject.Project_Template__c =  templateProj.Id;
            //end of changes by ssawhney for CR 2576469
            newProject.Name = '';
            newProject.pse__Daily_Timecard_Notes_Required__c = true;
            newProject.pse__Is_Template__c = false;     
            newProject.pse__Is_Active__c = true;
            newProject.pse__Region__c = getRegion();
            newProject.pse__Start_Date__c = System.today();
            newProject.CurrencyIsoCode = acct.Contract_Currency__c;
            if (userContact != null) {
                newProject.pse__Project_Manager__c = userContact.Id;
            } else {
                newProject.pse__Project_Manager__c = null;
            }
            newProject.pse__End_Date__c = null;
            if (opp != null) {
                newProject.pse__Account__c = opp.AccountId;
                newProject.pse__Opportunity__c = opp.Id;
            }   
            if (acct != null) {
                newProject.pse__Account__c = acct.Id;
            }
            /* set proj attribute on super class for use in common validation method. */
            proj = newProject;
            pse__Budget__c tempBudget;
            for (pse__Budget__c budgRow : templateProj.pse__Budgets__r) {
                tempBudget = budgRow.clone(false, false, false, false); 
                break;
            }
            if (tempBudget == null) {
                tempBudget = new pse__Budget__c();  
            }
            
            tempBudget.pse__Effective_Date__c = null;  
            tempBudget.pse__Status__c = 'Approved';
            tempBudget.pse__Type__c = 'Customer Purchase Order';
            //start of changes by janantha for CR 2420508
            tempBudget.pse__Invoice_Date__c = newProject.pse__Start_Date__c;
            //End of changes by janantha for CR 2420508
            newBudget = new PSA_SelectableObject();
            newBudget.obj = tempBudget;
            newBudget.selected = true;
        
            newMilestones = new List<PSA_SelectableObject>();
            newResourceRequests = new List<PSA_SelectableObject>();
            PSA_SelectableObject selectable;
            for (pse__Resource_Request__c req : templateProj.pse__Resource_Requests__r) {
                selectable = new PSA_SelectableObject();
                req.Display_Name__c = req.Name;
                selectable.obj = req.clone(false, false, false, false);
                selectable.selected = true;
                newResourceRequests.add(selectable);
            }   
            for (pse__Milestone__c mile : templateProj.pse__Milestones__r) {
                System.debug('mile.Internal_Time_Only__c='+mile.Internal_Time_Only__c);
                selectable = new PSA_SelectableObject();
                pse__Milestone__c newMile = mile.clone(false, false, false, false);
                newMile.Start_Date__c = System.today();
                newMile.pse__Target_Date__c = System.today().addDays(90);
                selectable.obj = newMile;
                selectable.selected = true;
                newMilestones.add(selectable);
            }   
            newProjectTasks = new List<PSA_SelectableObject>();
            if (templateProj.pse__Project_Tasks__r != null && templateProj.pse__Project_Tasks__r.size()> 0 ) {
                for (pse__Project_Task__c projTask : templateProj.pse__Project_Tasks__r) {
                    selectable = new PSA_SelectableObject();
                    pse__Project_Task__c prjTask = projTask.clone(false , false , false , false);
                    System.debug(' logging L: ' + projTask + ' next : ' + projTask.pse__Milestone__c + ' nxt : ' + prjTask.pse__Milestone__r.Name );
                    selectable.obj = prjTask;
                    //selectable.selected = true;
                    newProjectTasks.add(selectable);
                }   
            }
               
                                
        }   
        return null;
    }
    
    /* called from save button on page */  
    /* save project and all selected related data to the db */
    public PageReference saveProject() {
        
        System.debug(' next :: ' + isClassic  );



        if( (! isClassic && String.isNotEmpty(conDetail) && String.isNotBlank(conDetail)) ||  (Test.isRunningTest() && String.isNotEmpty(conDetail) && String.isNotBlank(conDetail) )  )
        {
            List<Merge_Contract_Header__c> headerList = new List<Merge_Contract_Header__c>();
            PSA_SelectableObject headerWrap ;
            contractList = new List<PSA_SelectableObject>(); 
            if(conDetail != null)
            {
                headerList = [SELECT Id, Name, Account_Name__c, Opportunity_Name__c, Effective_Start_Date__c, Effective_End_Date__c, 
                Original_Contract_Id__c, Active__c, Parent_Contract__c, Revision_Contract_Id__c, Revision_Effective_Start_Date__c, 
                (SELECT Id, Name, Effective_Start_Date__c, Effective_End_Date__c, Original_Contract_Id__c, Product__c, 
                Unit_Price__c, Units_High__c, Units_Low__c, Record_Type__c, Unit_of_Measure__c, Product_Id__c 
                FROM Merge_Contract_Details__r WHERE ID = :conDetail ) FROM Merge_Contract_Header__c WHERE id IN (select Original_Contract_Id__c from Merge_Contract_Detail__c where ID = :conDetail ) ];

            }

            for(Merge_Contract_Header__c mergeheader : headerList)
            {
                headerWrap = new PSA_SelectableObject();
                headerWrap.obj = mergeheader;
                List<PSA_SelectableObject> detailListWrap = new List<PSA_SelectableObject>();
                for(Merge_Contract_Detail__c mergedetail: mergeheader.Merge_Contract_Details__r )
                {
                    PSA_SelectableObject detailWrap = new PSA_SelectableObject();
                    detailWrap.obj = mergedetail;
                    detailWrap.selected = true;
                    detailListWrap.add(detailWrap);
                }
                headerWrap.childObjects = detailListWrap;
            } 

            contractList.add(headerWrap);
        }

        

        Savepoint dbSave = Database.setSavepoint();
        /* need to save the objects exactly as the user entered them.  That is because if their is a failure while saving any of the records, the 
           transaction will rollback from the database, but any objects that were already saved before the exception  happened will still 
           be populated with an ID field.  These saved copies will be used to revert the data to this state after an exception is caught.
           Then when the User re-tries and is successful, all records are ready for new IDS. */
        List<PSA_SelectableObject> saveMilestones = new List<PSA_SelectableObject>();
        List<PSA_SelectableObject> saveResourceRequests = new List<PSA_SelectableObject>();
        List<PSA_SelectableObject> saveOppResourceRequests = new List<PSA_SelectableObject>();
        PSA_SelectableObject saveBudget;
        pse__Proj__c saveProject = newProject.clone(false, false, false, false);
        if (newBudget != null && newBudget.selected) {
            pse__Budget__c saveBudg = newBudget.getBudget().clone(false, false, false, false);
            saveBudget = new PSA_SelectableObject();
            saveBudget.obj = saveBudg;
            saveBudget.selected = newBudget.selected;
        }   
        if (newMilestones != null && newMilestones.size() > 0) {
            for (PSA_SelectableObject mileRow : newMilestones) {
                pse__Milestone__c mile = mileRow.getMilestone().clone(false, false, false, false);
                mileRow.obj = mile;
                saveMilestones.add(mileRow);    
            }   
        }  
        if (newResourceRequests != null && newResourceRequests.size() > 0) {
            for (PSA_SelectableObject resRow : newResourceRequests) {
                pse__Resource_Request__c req = resRow.getResourceRequest().clone(false, false, false, false);
                resRow.obj = req;
                saveResourceRequests.add(resRow);     
            }   
        }
        if (oppResourceRequests != null && oppResourceRequests.size() > 0) {    
                for (PSA_SelectableObject resRow : oppResourceRequests) {
                pse__Resource_Request__c req = resRow.getResourceRequest();
                resRow.obj = req;
                saveOppResourceRequests.add(resRow);    
            }   
        } 
        List<pse__Resource_Request__c> oppRequestsToUpdate = new List<pse__Resource_Request__c> ();
        
        try {
            // Changes by Suhas Jain as per FFPSA-316 
            proj = newProject;   
            if (validate()) {


                newProject.pse__Is_Active__c = true;
                newProject.pse__Time_Credited__c = false;
                newProject.pse__Time_Excluded__c = false;
                if (newProject.pse__Project_Type__c == 'Internal') {    
                    newProject.pse__Is_Billable__c = false; 
                } else {
                    newProject.pse__Is_Billable__c = true;
                }
                insert newProject;
                if (newBudget != null && newBudget.selected && newBudget.getBudget() != null) {
                    newBudget.getBudget().pse__Project__c = newProject.Id;
                    newBudget.getBudget().pse__Account__c = newProject.pse__Account__c;
                    /* invoice date is on the page so that i can do my own required validation. */
                    /* this is needed so that i can submit form with immediate=false and */
                    /* the user can still leave the page temporarily go enter contract line item */
                    newBudget.getBudget().pse__Effective_Date__c = newBudget.getBudget().pse__Invoice_Date__c;                    
                    newBudget.getBudget().pse__Invoice_Date__c = null;                   
                    insert newBudget.getBudget();
                } 
                List<pse__Milestone__c> selectedMilestones = new List<pse__Milestone__c>();
                for (PSA_SelectableObject mileRow : newMilestones) {
                    if (mileRow.Selected) {
                        mileRow.getMilestone().pse__Project__c = newProject.Id;
                        mileRow.getMilestone().From_Template__c = true;
                        selectedMilestones.add(mileRow.getMilestone());
                    }
                }
                if (selectedMilestones.size() > 0) {
                    insert selectedMilestones;
                }
                Map<String, Id> milestoneNametoIdMap = new Map<String, Id>();                

                for (pse__Milestone__c mile : selectedMilestones) {
                    milestoneNametoIdMap.put(mile.Name , mile.Id);
                }

                List<pse__Project_Task__c> projectTaskInsert = new List<pse__Project_Task__c>();


                if(newProjectTasks != null && newProjectTasks.size() >0 )
                {
                    for (PSA_SelectableObject projTask : newProjectTasks) {
                        projTask.getProjectTask().pse__Milestone__c = milestoneNametoIdMap.get(projTask.getProjectTask().pse__Milestone__r.Name);
                        projTask.getProjectTask().pse__Project__c = newProject.Id;
                        projectTaskInsert.add(projTask.getProjectTask());
                    }
                    System.debug('before proj ins : ' + projectTaskInsert);
                    insert projectTaskInsert;
                }
                
                List<pse__Resource_Request__c> selectedResourceRequests = new List<pse__Resource_Request__c>();
                for (PSA_SelectableObject resRow : newResourceRequests) {
                    if (resRow.Selected) {
                        resRow.getResourceRequest().pse__Project__c = newProject.Id;
                        resRow.getResourceRequest().pse__Group__c = newProject.pse__Group__c;
                        resRow.getResourceRequest().pse__Region__c = newProject.pse__Region__c;
                        resRow.getResourceRequest().pse__Practice__c = newProject.pse__Practice__c;                               
                        selectedResourceRequests.add(resRow.getResourceRequest());
                    }
                }   
                if (selectedResourceRequests.size() > 0) {
                    insert selectedResourceRequests;
                }   
                if (oppResourceRequests != null && oppResourceRequests.size() > 0) {
                    for (PSA_SelectableObject resRow : oppResourceRequests) {
                        if (resRow.Selected) {
                            resRow.getResourceRequest().pse__Project__c = newProject.Id;    
                            resRow.getResourceRequest().pse__Region__c = newProject.pse__Region__c;
                            resRow.getResourceRequest().pse__Practice__c = newProject.pse__Practice__c;
                            resRow.getResourceRequest().pse__Group__c = newProject.pse__Group__c;
                            oppRequestsToUpdate.add(resRow.getResourceRequest());
                        } 
                    }   
                    if (oppRequestsToUpdate.size() > 0) {
                        update oppRequestsToUpdate;
                    }
                }   
                /* set variables on super class to set attributes */
                /* call method on the superclass to save */ 

                // Changes by Suhas Jain as per FFPSA-316          
                //proj = newProject;               
                projId = newProject.Id;
                save();
                return new PageReference('/'+newProject.Id); 
            }     
        } catch (Exception e) {
            List<ApexPages.Message> messList = ApexPages.getMessages();  
            if (messList == null || messList.size() == 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, e.getMessage()));
            }   
            Database.rollback(dbSave);
            newProject = saveProject;
            newBudget = saveBudget;
            newMilestones = saveMilestones;
            newResourceRequests = saveResourceRequests;
        }   
        return null;
    }

    public PageReference updatecli()
    {
        System.debug(' chec in if ? bef');
        System.debug(' chec in if ? ' + conDetail );
        //selectedContractDetailItem.Id = ' hello';
        //String testName = conDetail ;
        //System.debug(' test name  ' + testName );
        selectedContractDetailItem = new Merge_Contract_Detail__c();
        selectedContractDetailItem.Name = conDetailName;
        selectedContractDetailItem.Product__c = conDetailProduct ;
        return null;

    }
    
    public PageReference addProjectContractLineItem() {
        
        /*show the contract select page block */
        isSelectingContractLineItems = true;  
        filter = new pse__Proj__c();
        getData();
        return null;
    }  
    
    /* called from add to project button on select contract page block*/  
    /* make sure that one line item is selected (if it needs to be) and set flag to false so that page display will change */
    public PageReference saveProjContractData() {   
        if (!validateOneContractLineSelected()) {
            return null;
        } else {
            isSelectingContractLineItems = false;
            /* need to check to see whether a row is selected.  its possible it wasn't required so the validate */
            /* method above still returned true. If row was selected, set Contract Closed to Yes.  This would */
            /* happen when the record is saved because there is a trigger in place.  However, setting it now */
            /* also shows the user that it has been changed */
            boolean oneSelected = false;
            if (contractList != null) {
                for (PSA_SelectableObject contRow : contractList) {
                    for (PSA_SelectableObject lineRow : contRow.childObjects) {
                        /* if row is selected, see if we need to create a row for it or if it was already there */
                        if (lineRow.selected) {
                            oneSelected = true;
                            break;
                        } 
                    }
                    if (oneSelected) {
                        break;
                    }
                }    
            } 
            if (oneSelected) {
                newProject.Contract_Closed__c = 'Yes';
            }   
        }
          
        return null;
    }

    /* this method checks for a currency for the Account.  This currency will be the currency on the project created */
    /* If the currency is not set on the Account, an error message displays, disallowing the project creation */    
    private boolean checkForAccountCurrency() {
        boolean retVal = true;
        if (acct.Contract_Currency__c == null || acct.Contract_Currency__c.length() == 0 || acct.Contract_Currency__c.length() != 3) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'The Account Contract Currency is invalid or empty.  The currency code (ie. USD,EUR) must be populated in order to save new Project for this Account.'));
            retVal = false;
            hasError = true;
        }  
        return retVal;
    }
    
    /* called when the user chooses to save a new project */
    /* validate that if project is active, budget must be create also */
    /* Also validate that new project name is present */
    private boolean validate() {  
        boolean retVal = true;
        
        if (!validateOneContractLineSelected()) {
            //ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'When Contract Closed is Yes, Project Contract Line Item must be selected in order to save new Project.'));
            retVal = false;
        }  
          
        if (newBudget != null && newBudget.selected && newBudget.getBudget().pse__Invoice_Date__c == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Budget Effective Date: You must enter a value.'));
            retVal = false;
        }  
        
        /*
        if (newBudget != null && newBudget.selected && !newProject.pse__Is_Active__c) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Project must be marked as Active when a Budget is being created.'));
            retVal = false;
        }*/  
        
        if (newProject.Name == null || newProject.Name.length() == 0) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Project Name:  You must enter a value.'));
            retVal = false;
        }
        
        /*Start of changes by janantha to add an error message if the Name > 80*/      
        if((newProject.Name.length()+16)>80)
        {            
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR,'Length of the Project Name with the Account Name appended will be '+(newProject.Name.length()+16)+' Characters. Please delete '+ (newProject.Name.length()+16-80)+' characters from the Project Name.'));
            retVal = false;
        } 
        /*End of changes by janantha to add an error message if the Name > 80*/           
        if (newProject.pse__Project_Type__c != 'Internal' && userContact == null) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'You must have a PSA Resource contact record to be set as the Project Manager on a project. Please contact your system administrator.'));
            retVal = false;
        }   
          
        if (newProject.pse__Project_Type__c != 'Internal' && (newProject.Contract_Closed__c == null ||newProject.Contract_Closed__c.length() == 0)) {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Contract Closed is required for non-internal projects.'));
            retVal = false;
        }
        System.debug('retVal='+retVal);
        return retVal;
    }
    
    /* called from cancel button on create project template page.  Will return to either the opp or account page that the user came from */
    public PageReference cancel() {
        if (opp != null) {
            return new PageReference('/'+opp.Id);
        } else if (acct != null ){
            return new PageReference('/'+acct.Id);
        } else {
            return null;
        }
    }
    
    /* cancel button clicked on the select contract line item page block... return to project template page */
    public PageReference cancelReturnToTemplate() {
        isSelectingContractLineItems = false;  
        return null;
    }
    
    //Start of changes by janantha for CR 2420508
    public PageReference updateBudgetEffectiveDate()
    {    
        newBudget.getBudget().pse__Invoice_Date__c = newProject.pse__Start_Date__c;
        return null;
    }
    //End of changes by janantha for CR 2420508
      
}