/***
    PSA_ProjectContractBase_Controller
    @author Liz Ichihashi
    @Description : This Class is a superclass for two controllers, PSA_CreateProjFromTemp_Controller and PSA_ProjectContractSelect_Controller
                   It contains most of the logic to add contract line items.  Selecting contract line items can be
                   reached from within the create project template page, or directly from the project. 
                   
                   This class supports PSA customization requirment 3.4.1 and 3.4.6 - Select Project Template, Create Project
    @History
    --Developer           --Date            --Change
    Liz Ichihashi         1/04/2013      Created the class.    
    Liz Ichihashi         9/8/2013       Made changes to accomodate new rule where only one contract line item is allowed per project.
    Samir Jha             6/27/2014      Changes to pull Billing effective date from the Effective start date of Contract Line item
    Sharath Prasanna      1/04/2015      Changed the class for the CR - 2941958 and 3080071  
    Akhila Vidapanapati   25-Oct-2016    Changed the contract filter option - CR 3524681 - SF UI too limiting on CLI end dates
    Sharath Ravishanakar  21-12-2016     Changed the contractFilter CR 3599741 - Bug: Change CLI Page UI during Project Creation
	Sandeep Naga		  29-07-2020	 Changed PSA_Products Custom setting from contains to equals for FFPSA-1242 bug.
*/
public virtual with sharing class PSA_ProjectContractBase_Controller {
   
    /* boolean below is used in test class only */
    public boolean throwException {get; set;}
    /* page is reached via Account or Oppty.  This variables used to hold relevant object to link new project to */
    /* acct field is on the superclass */
    public Opportunity opp  {get; set;}
    /* boolean to control whether template select page block should be shown or not */
    public boolean isTemplateSelected {get; set;}
    /* boolean to control whether the select contract item page block should be shown or not */
    public boolean isSelectingContractLineItems {get; set;}
    /* boolean used to indicate on existing projects whether there are existing timecards */
    public boolean timecardsExist = false;
    public Account acct {get; set;}
    public String projId {get; set;}   
    public pse__Proj__c proj {get; set;}
    public List<PSA_SelectableObject> contractList {get; set;}
    /* filter:  use a dummy Project object for the date filters.  This will provide the handy date picker for free using inputField */
    public pse__Proj__c filter {get; set;}
    //Associated to the contract filter picklist 
    public String contractFilter {get;set;} 
    public List<SelectOption> contractFilterQueryList {get;set;}
    public transient Map<Id, Project_Contract__c> associatedContractIds = new Map<Id, Project_Contract__c>();
    public transient Map<Id, Project_Contract_Line_Item__c> associatedContractDetailIds = new Map<Id, Project_Contract_Line_Item__c>();
    public class PSA_ProjectContractSelectException extends Exception {}            
    public boolean isComingFromProjTemplatePage {get; set;}     
    public List<Project_Contract__c> projContHeaderList = new List<Project_Contract__c>();
    public List<Project_Contract_Line_Item__c> projContItemList = new List<Project_Contract_Line_Item__c>();
    public List<Project_Contract_Line_Item__c> projContItemListToDelete = new List<Project_Contract_Line_Item__c>();
    public Merge_Contract_Detail__c selectedContractDetailItem {get; set;}
/*START OF CHANGES BY SAMIR: ADDED A LIST TO STORE THE LIST OF PS PROJECTS BASED ON WHICH CONTRACT LINE ITEMS ARE FILTERED.*/
    public list<PSA_Products__c> PSAProductNames= new list<PSA_Products__c>();
    //public list<String> ProductList=new list<String>() ;
    public Set<String> productSet=new Set<String>() ;
    public Boolean ProdContainsFilteredProd {get; set;}
    
    public String returnValue{get;set;}
    //Controller
    public PSA_ProjectContractBase_Controller()
    {
        //Creating Selectlist options for filter and associated query          
        contractFilterQueryList = new List<SelectOption>();
        contractFilterQueryList.add(new SelectOption('Effective_End_Date__c >= TODAY','Active Contracts'));
        contractFilterQueryList.add(new SelectOption('Effective_End_Date__c = LAST_N_DAYS:90 AND Effective_End_Date__c < TODAY','Expired Contracts (up to 90 Days)'));
        //Changed the Effective_End_Date__c from 365 to 455
        contractFilterQueryList.add(new SelectOption('Effective_End_Date__c < LAST_N_DAYS:90 AND Effective_End_Date__c = LAST_N_DAYS:455 AND Effective_End_Date__c < TODAY','Expired Contracts (90 days - 1 year)'));
        contractFilter='Effective_End_Date__c >= TODAY';

    }
    
    /*END OF CHANGES BY SAMIR: ADDED A LIST TO STORE THE LIST OF PS PROJECTS BASED ON WHICH CONTRACT LINE ITEMS ARE FILTERED.*/
/*  Method called from the action attribute of PSA_ProjectContractSelect_Page.  Do page setup and retrieve list of Contracts for this Account */
    public virtual PageReference setup() {
        throwException = false;
               
        if (projId == null) {
            projId = ApexPages.currentPage().getParameters().get('projId');
        } 
        if (projId == null || projId.length() == 0) {   
            throw new PSA_ProjectContractSelectException('Missing ProjID parameter. Incorrect usage of PSA_ProjectContractSelect_Page');
        } else {
            proj = [SELECT Id, pse__Account__c, Contract_Closed__c, (select Id from pse__Timecards__r) from pse__Proj__c where Id = :projId];
            if (proj.pse__Timecards__r != null && proj.pse__Timecards__r.size() > 0) {
                timecardsExist = true;
            }
        }
        
        /* instantiate the filter object */
        filter = new pse__Proj__c();
        getData();
        return null;
    }
    
    /*  Method called from the Filter button.  Re-query with date filters in place */
    public void filter() {
        contractList = null;
        getData();
    }

    /*  Method called from the Clear button.  Clear filters and re-query */
    public void clear() {
        /*filter.pse__End_Date__c = null;
        filter.pse__Start_Date__c = null;*/
        contractFilter='Effective_End_Date__c >= TODAY';
        filter.Customer_PO__c = null;
        contractList = null;
        getData();
    }
    
    /*  Method called from the Save To Project button.  Need to loop through records and for any line items */
    /*  that are selected and weren't already selected.  Also need to see which records are not selected */
    /*  that previously were selected.  So, either insert a Project Contract Line Item or delete one, or */
    /*  do nothing.  Also need to create Project Contract rows for any line items selected.  Only */
    /*  create one project contract record for each contract - even if multiple line items for the contract */
    /*  are selected.  Trigger code on before and after delete will prevent users from deleting line items */
    /*  that have milestones or assignments related.  Also, will delete orphaned Project Contract records */
    /*  after contract line items are removed. */
    public PageReference save() {
        
        if (throwException)  { 
            throw new PSA_ProjectContractSelectException('test');
        }
        Project_Contract__c projContHeader;
        Project_Contract_Line_Item__c projContItem;     
        associatedContractIds = new Map<Id, Project_Contract__c>();
        associatedContractDetailIds = new Map<Id, Project_Contract_Line_Item__c>();
        
        if (!validateOneContractLineSelected()) {
            return null;
        }
        Savepoint dbSave = Database.setSavepoint();
        try {
            /* get map of existing Project Contracts.  We only want to have one row for each */
            /* Contract, even if multiple Contract Line Items are added to the Project */
            List<Project_Contract__c> projContracts = [
                                                SELECT Id, Original_Contract_Id__c
                                                 FROM Project_Contract__c 
                                                 WHERE Project__c = :proj.Id];
            for (Project_Contract__c contRow : projContracts) {
                associatedContractIds.put(contRow.Original_Contract_Id__c, contRow);
            }
            /* get map of existing Project Contract Line Items.  We neeed to know */
            /* if it exists already so that if it is unselected, we know the */
            /* record should be deleted. */
            List<Project_Contract_Line_Item__c> projContractDetails = [
                                            SELECT Id, Contract_Detail__c
                                             FROM Project_Contract_Line_Item__c 
                                             WHERE Project__c = :proj.Id];
            for (Project_Contract_Line_Item__c lineRow : projContractDetails) {
                associatedContractDetailIds.put(lineRow.Contract_Detail__c, lineRow);
            }  
        
            Map<Id, Id> contractIdToProjIdMap = new Map<Id, Id>();
            for (PSA_SelectableObject contRow : contractList) {
                for (PSA_SelectableObject lineRow : contRow.childObjects) {
                    if (lineRow.selected) {  
                        /* only create a new Project Contract record if one does not already exist. */
                        if (!associatedContractIds.containsKey(contRow.getContract().Id)) {
                            /* check to see if we have already saved a project contract row for this contract during this execution */
                            /* if we have, do not add another one */
                            if (!contractIdToProjIdMap.containsKey(contRow.getContract().Id)) {
                                projContHeader = new Project_Contract__c();
                                projContHeader.Account__c = proj.pse__Account__c;
                                projContHeader.Original_Contract_Id__c = contRow.getContract().Id;
                                projContHeader.Project__c = proj.Id;
                                projContHeaderList.add(projContHeader);
                                contractIdToProjIdMap.put(contRow.getContract().Id, proj.Id);
                            }   
                        } 
                    } 
                }  
            }
            /* insert project contract rows so that there will be Ids for child records */
            if (projContHeaderList != null && projContHeaderList.size() > 0) {
                insert projContHeaderList;
            }   
            
            /* get latest data and update associated Contract Id Map */
            associatedContractIds = new Map<Id, Project_Contract__c>();
            projContracts = [SELECT Id, Name, Original_Contract_Id__c
                             FROM Project_Contract__c 
                             WHERE Project__c = :proj.Id];
            if (projContracts != null) {                 
                for (Project_Contract__c contRow : projContracts) {             
                    associatedContractIds.put(contRow.Original_Contract_Id__c, contRow);
                }
            }   
            for (PSA_SelectableObject contRow : contractList) {
                for (PSA_SelectableObject lineRow : contRow.childObjects) {
                    /* if row is selected, see if we need to create a row for it or if it was already there */
                    if (lineRow.selected) {
                        
                        /* only create a new Project Contract record if one does not already exist.   */
                        if (!associatedContractDetailIds.containsKey(lineRow.getContractDetail().Id)) {
                            projContItem = new Project_Contract_Line_Item__c();
                            projContItem.Contract_Detail__c = lineRow.getContractDetail().Id;
                            projContItem.Original_Contract_Id__c = contRow.getContract().Id; 
                            if (associatedContractIds.containsKey(contRow.getContract().Id)) {
                                Project_Contract__c projCont = associatedContractIds.get(contRow.getContract().Id);
                                projContItem.Project_Contract__c = projCont.Id;
                            } 
                            projContItem.Project__c = proj.Id;
                            projContItem.Valid_Create__c = true;
                            projContItemList.add(projContItem); 
                        }    
                    } else {
                        /* row is unselected */
                        if (associatedContractDetailIds.containsKey(lineRow.getContractDetail().Id)) {
                            /* this Project Contract Line Item record needs to be deleted. */
                            Project_Contract_Line_Item__c projContItemToDelete = associatedContractDetailIds.get(lineRow.getContractDetail().Id);
                            projContItemToDelete.Valid_Delete__c = true;
                            projContItemListToDelete.add(projContItemToDelete);
                        }   
                    } 
                }
            }     
            
            System.debug('projContItemListToDelete='+projContItemListToDelete);
            System.debug('projContItemList='+projContItemList);
            
            if (projContItemList != null && projContItemList.size() > 0) {
                insert projContItemList;
            }   
            if (projContItemListToDelete != null && projContItemListToDelete.size() > 0) {
                /* update record with Valid_Delete = true */
                //Start of changes for CR - 2941958: Deletion occurs in the trigger after insert 
                // update projContItemListToDelete;
                // delete projContItemListToDelete;
                //End of changes for CR - 2941958
            }   
             /* Start of changes by Samir for CR 2589321: make sure that the project's billing effective date is set to the earliest contract Line item's Effective Start Date */
            Set<Id> projectIds = new Set<Id>();
            projectIds.add(proj.Id);
            PSA_Contract_Detail_Actions.checkProjectContractsForEarliestBillingDate(projectIds);
        } catch (Exception e) {
            List<ApexPages.Message> messList = ApexPages.getMessages();  
            if (messList == null || messList.size() == 0) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, e.getMessage()));
            }   
            Database.rollback(dbSave);
            returnValue = 'failed';
            return null;
        }   
        String pageUrl = '/'+proj.Id ;

        //pageRef.setRedirect(true);
        if(UserInfo.getUiThemeDisplayed() == 'Theme3')
        {
            return new PageReference(pageUrl);  
        }
        returnValue = pageUrl;
        return null; 
    }   
    
    
    /*  Method to retrieve data using any date filters selected.  Display an informative message if  no Contracts exist for this Project's Account */
    /*  Also, retrieve current list of Project Contract Line Items so that we can mark those rows as selected */
    protected void getData() {
        //Start of changes by shprasan: creating the date variables
        Date todayDate = Date.today();
        Date lastFourMonths = todayDate.addMonths(-4);
        //end of changes by shprasan

        /* if list of data is already loaded, do not re-load it (within the context of one session) */
        if (contractList != null && contractList.size() > 0) {
            return;
        }
        Id acctToQuery;
        if (proj != null) {
            acctToQuery = proj.pse__Account__c;
        } else {
            acctToQuery = acct.Id;
        }
        System.debug('acctToQuery='+acctToQuery);
        //first get all Contracts with Details for this Account
        // WHERE Effective_End_Date__c >= TODAY 
        //Changes by shprasan: adding a check on the effective end date on the contract line items
        String baseQuery = 'SELECT Id, Name, Account_Name__c, Opportunity_Name__c, Effective_Start_Date__c, Effective_End_Date__c, '+
                           'Original_Contract_Id__c, Active__c, Parent_Contract__c, Revision_Contract_Id__c, Revision_Effective_Start_Date__c, ' +
                           '(SELECT Id, Name, Effective_Start_Date__c, Effective_End_Date__c, Original_Contract_Id__c, Product__c, '+
                           'Unit_Price__c, Units_High__c, Units_Low__c, Record_Type__c, Unit_of_Measure__c, Product_Id__c ' +
                           'FROM Merge_Contract_Details__r WHERE ID != NULL';                 
        String endQuery =  ' ORDER BY Name) FROM Merge_Contract_Header__c WHERE Account_Name__c = \'' + acctToQuery + '\'';
          
        //Based on the contract filter
        baseQuery += ' AND '+ contractFilter; 
        System.debug('###contractFilter: '+contractFilter);
        System.debug('###endQuery: '+endQuery);
        System.debug(baseQuery);
        //check date range filters
        /*if (filter.pse__Start_Date__c != null) {
            baseQuery += ' AND Effective_Start_Date__c >= ' + String.valueOf(filter.pse__Start_Date__c);
        }   
        if (filter.pse__End_Date__c != null) {  
            baseQuery += ' AND Effective_End_Date__c <= ' + String.valueOf(filter.pse__End_Date__c);  
        }*/                       

        //start of changes by shprasan: selecting the contracts whose expected end date is greater than 4 months from now
        //endQuery += ' AND Effective_End_Date__c > :lastFourMonths ';  
        //end of changes by shprasan
        

        /* populate the full query from the parts */
        String fullQuery = baseQuery + endQuery + ' ORDER BY Effective_End_Date__c desc';       
        System.debug('fullQuery='+fullQuery);    
        List<Merge_Contract_Header__c> contList = new List<Merge_Contract_Header__c>();

        if(!Test.isRunningTest()) {
            contList = Database.query(fullQuery);
        }
        else{
            contList = [SELECT Id, Name, Account_Name__c, Opportunity_Name__c, Effective_Start_Date__c, Effective_End_Date__c, Original_Contract_Id__c, Active__c, Parent_Contract__c, Revision_Contract_Id__c, Revision_Effective_Start_Date__c, (SELECT Id, Name, Effective_Start_Date__c, Effective_End_Date__c, Original_Contract_Id__c, Product__c, Unit_Price__c, Units_High__c, Units_Low__c, Record_Type__c, Unit_of_Measure__c, Product_Id__c  FROM Merge_Contract_Details__r limit 1)  FROM Merge_Contract_Header__c limit 1];
        }
        
        
        System.debug('###contList: '+contList);
        
        /* next get all Contracts Details for this Account that are already associated with the project.  */
        /* These will be read-only on this page if they already have an assignment or milestone. */
        if (proj != null) {
            associatedContractDetailIds = new Map<Id, Project_Contract_Line_Item__c>();
            List<Project_Contract_Line_Item__c> projContractDetails = [
                                                SELECT Id, Contract_Detail__c,
                                                (SELECT Id from Assignments__r),
                                                (SELECT Id from Milestones__r)
                                                 FROM Project_Contract_Line_Item__c 
                                                 WHERE Project__c = :proj.Id];
            for (Project_Contract_Line_Item__c lineRow : projContractDetails) {
                associatedContractDetailIds.put(lineRow.Contract_Detail__c, lineRow);
            }
        }   
        
        /* create selectable rows of display data */
        if (contList != null && contList.size() > 0) {  
            createDisplayData(contList);
        } else {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.INFO, 'Your search returned 0 results.  No Contract Line Items found for this Account and filter(s)'));
        }   
    }
    
    /* check to see if one contract line is selected */
    protected boolean validateOneContractLineSelected() {
        boolean oneSelected = false;
        System.debug('proj='+proj);
        System.debug('timecardsExist='+timecardsExist);
        boolean required = true;
        if (proj.Contract_Closed__c == 'Yes' || timecardsExist) {
            /* continue on to validate that one selected and set selected contract line item */
        } else {
            /* set required to false and continue on to validate that one selected and set selected contract line item */
            required = false;
        }
        
        System.debug('contractList='+contractList);  
        if (contractList != null) {
            for (PSA_SelectableObject contRow : contractList) {
                for (PSA_SelectableObject lineRow : contRow.childObjects) {
                    /* if row is selected, see if we need to create a row for it or if it was already there */
                    if (lineRow.selected) {
                        selectedContractDetailItem = lineRow.getContractDetail();
                        oneSelected = true;
                        break;
                    } 
                }
            }    
        }   
        if (!oneSelected && required) {
            if (proj.Contract_Closed__c == 'Yes') {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Because Contract Closed = "Yes", you are required to select a Contract Detail Line to associate with your Project.'));
            } else if (timecardsExist) {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.severity.ERROR, 'Because Timecards exist, you are required to select a Contract Detail Line to associate with your Project.'));
            }       
        } 
        System.debug('oneSelected='+oneSelected);
        System.debug('required='+required);
        if (!oneSelected && !required) {
            return true;
        }
        return oneSelected;
    }
    
    /*  Method to create expandable and selectable display objects on the page. These objects contain a reference to the object, as */
    /*  well as a boolean for disabled and one for selected (also used for expanding/collapsing) */
    private void createDisplayData(List<Merge_Contract_Header__c> contList) {
         boolean disableCheckboxes = false;
         contractList = new List<PSA_SelectableObject>();
         List<PSA_SelectableObject> childDisplayObjList;
         PSA_SelectableObject displayObj;
         PSA_SelectableObject childDisplayObj;
         /*START OF CHANGES BY SAMIR: Added the filter for associated Project products */
        PSAProductNames=[select Id,Name,Product_Name__c from PSA_Products__c];
        for(PSA_Products__c psa_productNameIterator:PSAProductNames)
         {
			//Changes by Sandeep for FFPSA-1242, removing list and changing to set implementation
            //ProductList.add(psa_productNameIterator.Product_Name__c);
            productSet.add(psa_productNameIterator.Product_Name__c);
         }
         
        /*END OF CHANGES BY SAMIR: Added the filter for associated Project products */  
         for (Merge_Contract_Header__c contRow : contList) {
            //If there are no contract line items
            if(contRow.Merge_Contract_Details__r.size() == 0)
            {
                continue;
            }
            childDisplayObjList = new List<PSA_SelectableObject>();  
            displayObj = new PSA_SelectableObject();
            displayObj.obj = contRow;
            for (Merge_Contract_Detail__c detailRow : contRow.Merge_Contract_Details__r) {
            //Start of changes by Samir
            ProdContainsFilteredProd = FALSE;
            //END of changes by Samir
                if (filter.Customer_PO__c != null) {
                    /* product filter has been entered by user.  Must filter here in the result set */
                    /* because product__c is a textarea field and cannot be in the where clause of a SOQL query */
                    if (detailRow.Product__c != null) {
                        if (!detailRow.Product__c.containsIgnoreCase(filter.Customer_PO__c)) {
                            continue;
                        }
                    }   
                }
                
                //Changes by Sandeep for FFPSA-1242, removing list and changing to set implementation
                /*
                //Start of changes by Samir
                for (String ProdIter:ProductList)
                {
                    if(detailRow.Product__c.containsIgnoreCase(ProdIter))
                    {
                        ProdContainsFilteredProd = TRUE;
                    
                    }
                }*/
                if(productSet.contains(detailRow.Product__c)){
                    ProdContainsFilteredProd = TRUE;
                }
                //End of changes by Sandeep
                if(ProdContainsFilteredProd==FALSE)
                {
                continue;
                }
                //END of changes by Samir
                childDisplayObj = new PSA_SelectableObject();
                childDisplayObj.obj = detailRow;
                if (associatedContractDetailIds != null && associatedContractDetailIds.containsKey(detailRow.Id)) {
                    Project_Contract_Line_Item__c projLineItem = associatedContractDetailIds.get(detailRow.Id);
                    childDisplayObj.selected = true;
                    /*
                    if ((projLineItem.Assignments__r != null && projLineItem.Assignments__r.size() > 0) || 
                        (projLineItem.Milestones__r != null && projLineItem.Milestones__r.size() > 0)) {
                        childDisplayObj.disabled = true;
                        disableCheckboxes = true;
                    } else {
                        childDisplayObj.disabled = false;
                    }
                    */  
                }   
                childDisplayObjList.add(childDisplayObj);
            }
            /* if the selected line item has milestones or assignments, disallow selecting any line items. */
            /*
            if (disableCheckboxes && childDisplayObjList != null) {
                for (PSA_SelectableObject dispRow : childDisplayObjList) {
                    dispRow.disabled = true;
                }
            }
            */
            displayObj.childObjects = childDisplayObjList;
            if(childDisplayObjList.size()>0)
            {    
                contractList.add(displayObj);   
            }    
         }
    }
}