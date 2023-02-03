/** Controller of QuickActivityEntryPage

Page to create tasks quickly. Triggered from Quick Activity Entry button on Opportunity, Lead, Account and related list on Activity.
User selects category, category dependant type, related to(whatId) and Name (whoId).
User can either save -> Task is inserted with record type = Sales Rep Activity 
or 
Save & Follow -> Task is inserted with record type = Sales Rep Activity  & redirected to create a follow up task.

Developer       Date                CR 
Sonali Tandon - 28th March 2015     SFDC-866 and SFDC-712

**/

public class QuickActivityEntryPageController {

    public Task taskObj{get;set;}
    Id redirectId{get;set;}
    String fromWhere;
    Id accId;
    Id contactId;
    Id opptyId;
    Map<String,List<String>> mapOfCategoryToType;
    public String selectedCategory {get; set;}
    public List<SelectOption> listOfTypeOptions {get;set;}
    public String selectedType
    {
            get{
                    if(String.isBlank(selectedType))
                    {
                        selectedType='--None--';
                    }
                    return selectedType;
                }
                set;
    }
      
    public QuickActivityEntryPageController(ApexPages.StandardController controller) 
    {
        taskObj = (Task)controller.getRecord();
         if(ApexPages.currentPage().getParameters().get('retUrl')!='')
            redirectId = ApexPages.currentPage().getParameters().get('retUrl');
        if(ApexPages.currentPage().getParameters().get('accId')!='')
            accId = ApexPages.currentPage().getParameters().get('accId');
        if(ApexPages.currentPage().getParameters().get('contactId')!='')
            contactId = ApexPages.currentPage().getParameters().get('contactId');
        if(ApexPages.currentPage().getParameters().get('opptyId')!='')
            opptyId = ApexPages.currentPage().getParameters().get('opptyId');
        if(ApexPages.currentPage().getParameters().get('fromWhere')!='')
            fromWhere = ApexPages.currentPage().getParameters().get('fromWhere');

        if(fromWhere.contains('Account') && accId!=null)
            taskObj.whatId = accId;

        if(fromWhere.contains('Opportunity') && opptyId!=null)
            taskObj.whatId = opptyId;

        if(fromWhere.contains('Contact') && contactId!= null && accId!=null)
        {
            taskObj.whoId = contactId;
            taskObj.whatId = accId;
        }

        if(fromWhere.equals('relatedlist'))
        {
            if(accId!=null)
            {
                taskObj.whatId = accId;
                redirectId = accId;
            }
            if(opptyId!=null)
            {
                taskObj.whatId = opptyId;
                redirectId = opptyId;
            }
            if(contactId!=null)
            {
                taskObj.whoId = contactId;
                redirectId = contactId;
            }
        }

    // default type and category to '--None--'
     mapOfCategoryToType = new Map<String,List<String>>();
     mapOfCategoryToType.put('--None--', new List<String>{'--None--'});
     selectedCategory = '--None--';
    // get picklist values for Quick Action Category and Quick Action Type

    getPickListValues();
    taskObj.ActivityDate = Date.today();
    selectedType = '--None--';
    listOfTypeOptions = new List<SelectOption>{new SelectOption('--None--', '--None--')};

    }

    // create drop down for VF page 
    public List<SelectOption> setPickListValues(Set<String> setOfPicklistValues) 
    {
        List<SelectOption> listOfSelectOptions = new List<SelectOption>();
        for(String picklist : setOfPicklistValues)
        {
            listOfSelectOptions.add(new SelectOption(picklist,picklist));
        }
        return listOfSelectOptions;
    }

    // get picklist values for Quick Action Category 
    public List<SelectOption> getCategoryValues()
    {
        List<SelectOption> listOfCategoryOptions = new List<SelectOption>();
        listOfCategoryOptions = setPickListValues(mapOfCategoryToType.keySet());

        return listOfCategoryOptions;
    }


    public PageReference populateType()
    {
        Set<String> setOfTypeValues = new Set<String>();
        
        setOfTypeValues.addAll(mapOfCategoryToType.get(selectedCategory));
        listOfTypeOptions = setPickListValues(setOfTypeValues);
        return null;
    }


    // get records needed to populate category-type from Quick_Activity_Setting__mdt
    private void getPickListValues()
    {
        String inputQuery;
        String source = 'OpportunityVFPage';
        List<Quick_Activity_Setting__mdt> listOfActivityData    = new List<Quick_Activity_Setting__mdt>();
        
        inputQuery                  = CreateQuickActivitiesClass.generateQuery(source);
        listOfActivityData          = Database.query(inputQuery);

        for(Quick_Activity_Setting__mdt qeSettingObj : listOfActivityData)
        {
            if(!mapOfCategoryToType.containsKey(qeSettingObj.Category__c))
                mapOfCategoryToType.put(qeSettingObj.Category__c, new List<String>{'--None--', qeSettingObj.Type__c});
            else
                mapOfCategoryToType.get(qeSettingObj.Category__c).add(qeSettingObj.Type__c);
        }

        System.Debug(LoggingLevel.Error, 'AGH_DEBUG ' +mapOfCategoryToType);


    }


    public void saveOperation()
    {
        String accountPrefix =  Schema.SobjectType.Account.getKeyPrefix();
        String opptyPrefix =  Schema.SobjectType.Opportunity.getKeyPrefix();
        String whatIdString = String.valueOf(taskObj.whatId).substring(0,3);
        Id accountId;
        
        System.debug('accountPrefix'+ accountPrefix + 'opptyPrefix' + opptyPrefix + 'whatIdString' + whatIdString+ 'taskObj.whatId' + taskObj.whatId);

        if(taskObj.whatId!=null)
        {
            // check if whatId is an account id
            if(accountPrefix.equals(whatIdString))
                accountId = taskObj.whatId;
            // if whatId is opportunity id, get account id of the opportunity 
            else if(opptyPrefix.equals(whatIdString))
            {
                Opportunity opp = [Select AccountId from Opportunity where Id=: taskObj.whatId];
                accountId = opp.AccountId;
                System.debug('opp.AccountId' + opp.AccountId);
            }
        }
        
        //create 
        taskObj.Type__c = selectedType;
        taskObj.QuickActionType__c=selectedType;
        taskObj.QuickActionType__c = selectedType;
        taskObj.Quick_Action_Category__c=selectedCategory;

        taskObj.RecordTypeId = Schema.SobjectType.Task.getRecordTypeInfosByName().get('Sales Rep Activity').getRecordTypeId();
        taskObj.Priority='Normal';
        taskObj.Status='Completed';

        insert taskObj;


    }
        
    public PageReference Save()
    {   
        if(!validationsRanSuccessfully())
        {
            return null;
        }
        try
        {
            saveOperation();
        }
        catch(Exception exc)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while Saving the task:'+exc.getMessage(), ''));
            return null;
        }

        PageReference pageRef = new PageReference('/' + redirectId);  
        pageRef.setRedirect(true);

        return pageRef;
    }

    public PageReference SaveandFollowup()
    {
        if(!validationsRanSuccessfully())
        {
            return null;
        }
        try
        {
            saveOperation();
        }
        catch(Exception exc)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Error while Saving the task:'+exc.getMessage(), ''));
            return null;
        }


        String prefix =  Schema.SobjectType.Task.getKeyPrefix();
        PageReference pageRef = new PageReference('/' + prefix + '/e');
        pageRef.setRedirect(true);

        return pageRef;
    }

    public Boolean validationsRanSuccessfully()
    {
        ApexPages.Message errorMessage;
       
        if(selectedCategory == '--None--')
        {
            System.debug('Category is none');
            errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR,'Please pick a valid value for Quick Action Category');
            ApexPages.addMessage(errorMessage);
            return false;
        }
        if (selectedType == '--None--')
        {
            System.debug('Type is none');
            errorMessage = new ApexPages.Message(ApexPages.Severity.ERROR,'Please pick a valid value for Quick Action Type');
            ApexPages.addMessage(errorMessage);
            return false;
        }
        // if Category and Type are correctly populated, create a task 
        if(taskObj.ActivityDate>Date.today())
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'A Quick Entry Activity cannot be saved with a future date.'));
            return false;
        }
        return true;
    }


    public PageReference Cancel()
    {
        PageReference pageRef = new PageReference('/' + redirectId);
        pageRef.setRedirect(true);

        return pageRef;
    }    

    public PageReference populateSubject()
    {
        //String queryId = String.valueOf(taskObj.WhatId).startsWith('001') ? taskObj.WhatId : accId;
        String accName = 'Placeholder';
        if(!String.isBlank(taskObj.WhatId))
        {
            if(String.valueOf(taskObj.WhatId).startsWith('001'))
            {
                accName = [select name from account where id= :taskObj.WhatId][0].Name;
            }
            else if(String.valueOf(taskObj.WhatId).startsWith('006'))
            {
                accName = [select Account.Name from Opportunity where id=:taskObj.WhatId][0].Account.Name;
            }
        }
        if(!String.isBlank(selectedType))
        {
            taskObj.Subject = selectedType + ' : ' +accName;
        }


        return null;
    }

}