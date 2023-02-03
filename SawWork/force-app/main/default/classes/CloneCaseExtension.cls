/******************************************************************************
Name        : CloneCaseExtension
Created By  : Noopur(Appirio Jaipur)
Description : To provide an interface for the User to clone the Case for 
              particular Accounts

1 June 2019 			Vandhana 			ESESP 1661 - single/multi case cloning
21 Aug 2019				Vandhana 			ESESP 2481 - add contact, add back accounts that the user is team member of
******************************************************************************/
public class CloneCaseExtension 
{
    public Case caseObj{get;set;}
    public String caseId {get;set;}
    public List<SelectOption> searchResults {get;set;}
    public List<SelectOption> selectedAccounts {get;set;}
    public boolean myAccounts {get;set;}
    public String searchKey {get;set;}
    public boolean caseCreated {get;set;}
    public boolean showSearchPanel {get;set;}
    public set<Id> accountIds {get;set;}
    public Case tempCon {get;set;}
    public List<Account> listAccounts {get;set;}
    
    public String single = '';
    private List<String> resultsname = new List<String>();
    private Boolean hasparams = false;
    private Boolean hasnoresults = false;
    
    public String newCaseId {get;set;}
    public String accId = '';
    public String accName = '';
    public List<SelectOption> setSO{get;set;}
    
    public String accountName{get;set;}
    public Set<Id> defAccounts;
    
    public Set<Id> selAccId;
    
    // custom lookup
    public final static Integer QUERY_LIMIT = 600;
    private String previousSortField = '';
    private String filterString = '';
    public String searchText {get;set;}
    public String listSize {get;set;}
    public Boolean isAscending {get;set;}
    public Boolean excessRowsError {get;set;}   
    public Boolean isFirstLoad {get;set;}   
    
    //Getters and Setters
    
    public Boolean getHasparams(){
        return hasparams;
    }
    
    public void clearValues(){
        hasparams = false;
    }
    
    public Boolean getHasnoresults(){
        return hasnoresults;    
    }
    
    //constructor
    public CloneCaseExtension()
    {
        previousSortField = 'Name';
        SortField = 'Name';
        isAscending = true;
        excessRowsError = false;   
        isFirstLoad = true;
        searchText = '';
        caseId = '';
        
        //Extracting search string 
        String searchString = ApexPages.CurrentPage().getParameters().get('lksrch');
        
        if(searchString != null && searchString != '') 
        {
            this.searchText = searchString;
        }
        accountIds = new set<Id>();
        
        for(Account atm : [select Id 
                           from Account where Id != :accId
                           limit 10])
        {
            accountIds.add(atm.Id);
        }
    }
    
    // constructor for standard controller
    public CloneCaseExtension(Apexpages.Standardcontroller std)
    {
        caseId = std.getRecord().Id; 
        
        searchKey = ''; 
        caseCreated = false;
        showSearchPanel = false;
        searchResults = new List<SelectOption>();
        selectedAccounts = new List<SelectOption>();
        tempCon = new Case();
        accountIds = new set<Id>();
        String queryString = 'Select ';
		
		accountName = '';
        selAccId = new Set<Id>();
        
        defAccounts = new Set<Id>();
        
        setSO = new List<SelectOption>();
        
        // Query the case record
        if(caseId != null && caseId != '')
        {
            showSearchPanel = true;
            Map<String, Schema.Sobjectfield> CaseFieldMap = Case.sObjectType.getDescribe().fields.getMap();
            for(String str : CaseFieldMap.keySet()){
                Schema.DescribeFieldResult caseField = CaseFieldMap.get(str).getDescribe();
                if(caseField.isUpdateable()){
                    queryString += str + ',';
                }
            }
            queryString = queryString.substring(0, queryString.length()-1);
            if(!queryString.containsIgnoreCase('AKAM_Case_ID__c')) 
            {
                queryString += ',AKAM_Case_ID__c';
            }
            queryString += ',CaseNumber,Account.Name,Contact.AccountId From Case Where Id = :caseId';
            caseObj = Database.query(queryString);
            accId = caseObj.AccountId;
            defAccounts.add(accId);
            
            accName = caseObj.Account.Name;
            /*
            for(Account atm : [select Id 
                               from Account
                               limit 10])
            {
                accountIds.add(atm.Id);
            }*/
            
            SearchAccounts();
        }
        else
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'There is no Case selected to clone.'));
        }
    }
    
    
    // Method to clone single case
    public PageReference cloneSingleCase()
    {
        /*
        Case cs = caseObj.clone(false,true);
        cs.AccountId = accId;
        //cs.Contact = null;
        //cs.ContactId = null;
        cs.AKAM_Case_ID__c = null;
        cs.Status = 'Assigned';
        cs.Contract__c = NULL;
        cs.OwnerId = UserInfo.getUserId();
        cs.AKAM_Closed_Date__c = NULL;
        cs.Resolved_Date__c = NULL;
        cs.Last_Case_Update__c = NULL;
        insert cs;
        return (new PageReference('/'+cs.Id+'/e?retURL=%2F' + cs.Id));
		*/
        return (new PageReference('/'+caseObj.Id+'/e?clone=1&id=' + caseObj.Id + '&nooverride=1'));
    }
    
    /*
	Method to search Accounts according to the name entered by the user
	*/
    public pagereference SearchAccounts()
    {
        searchResults = new List<SelectOption>();
        selectedAccounts = new List<SelectOption>();
        Id userId = UserInfo.getUserId();
        List<AccountTeamMember> actQuery = [SELECT Id,Account.Name,AccountId 
                                            FROM AccountTeamMember 
                                            WHERE UserId = :userId and AccountId != :accId ORDER BY Account.Name];
        //List<Account> lstAcc = new List<Account>();
        for(AccountTeamMember accTeamMem: actQuery)
        {
            SelectOption opt = new SelectOption(accTeamMem.AccountId,accTeamMem.Account.Name);
            searchResults.add(opt);
            defAccounts.add(accTeamMem.AccountId);
        }
        
        /*
        if(String.isNotBlank(searchText))
        {
            String qry = 'SELECT Id,Name FROM Account WHERE Account_Status__c like \'%- Active\' And Name like \'%'+searchText+'%\' order by Name limit 100';
            listAccounts = new List<Account>();
            for(Account acc: Database.query(qry))
            {
                listAccounts.add(acc);
            }
            for(Account acc: listAccounts)
            {
                selectOption opt = new selectOption(acc.Id,acc.Name);
                searchResults.add(opt);
            }
        }*/
        if(searchResults.size() != 0)
            searchResults.add(0,new selectOption(accId,accName));
        else
            searchResults.add(new selectOption(accId,accName));
        
        return null;
    }
    
    /*
	Method to clone the case for the selected Accounts
	*/
    public pagereference CloneCaseForAccounts()
    {
        try 
        {
            List<Case> caseList = new List<Case>();
            if(selectedAccounts.size() > 0)
            {
                for(SelectOption opt: selectedAccounts)
                {
                    Case cs = caseObj.clone(false,true);
                    cs.AccountId = opt.getValue();
                    if(cs.AccountId != accId)
                        cs.ContactId = null;
                    cs.AKAM_Case_ID__c = null;
                    cs.Status = 'Assigned';
                    cs.Contract__c = NULL;
                    cs.OwnerId = UserInfo.getUserId();
                    cs.AKAM_Closed_Date__c = NULL;
                    cs.Resolved_Date__c = NULL;
                    cs.Last_Case_Update__c = NULL;
                    caseList.add(cs);
                }
                
                if(!caseList.isEmpty())
                {
                    insert caseList;
                    Schema.DescribeSObjectResult result = Case.SObjectType.getDescribe(); 
                    return(new PageReference('/500?fcf=00BG0000008yvdP')); 
                }
                caseCreated = true;
                showSearchPanel = false;
            }
            else
            {
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select one or more Accounts to clone Case'));
            }
        }
        catch(Exception ex)
        {
            caseCreated = false;
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, ex.getMessage()));
        }
        return null;
    }
    
    /*
	Method for autocomplete functionality
	*/
    public PageReference searchSuggestions() 
    {    
        //Initalize variables, hasparams just indicates that a search has started
        resultsname.clear();   
        hasparams = true;
        hasnoresults = false;
        
        //Obtain current parameters
        String sobjectname = System.currentPageReference().getParameters().get('objectname');
        String stext = System.currentPageReference().getParameters().get('aname');
        
        //Limit Suggestions to 10 Results
        Integer iLimit = 30;
        
        //Validate if there's an input and get results
        
        if(String.isNotBlank(stext) && stext.length() > 2)
        {    
            try
            {    
                String sql = 'select id,name from Account where Name like \'%'+stext+'%\' limit '+ iLimit;
                
                for(sobject x : Database.query(sql))
                {    
                    String s  = (String)(x.get('name'));
                    resultsname.add(s); 
                }
            }
            
            catch(Exception e)
            {
                resultsname.add('Unexpected Error, please contact support.');    
            }
        }
        return null;
    }
    
    /*
	Method to add the searched account into the mutiselect picklist's selected column
	*/
    public pagereference CopyToSelectedAccounts()
    {
        integer i = 0;
        boolean isSel = false;
        
        for(Selectoption opt: searchResults)
        {
            if(opt.getValue() == tempCon.AccountId)
            {
                isSel = true;
                selectedAccounts.add(opt);
                break;
            }
            else if(opt.getLabel() == searchKey)
            {
                isSel = true;
                selectedAccounts.add(opt);
                break;
            }
            i++;
        }
        if(isSel)
            searchResults.remove(i);
        return null;
    }
    
    public PageReference CopyToSelectedAccounts1()
    {
        Set<Id> accSet = new Set<Id>();
        
        for(SelectOption so : selectedAccounts)
            accSet.add(so.getValue());
        
        if(searchResults.size() == 0 && tempCon.AccountId == accId)
            return NULL;
        
        if(!selAccId.contains(tempCon.AccountId) && !accSet.contains(tempCon.AccountId))
            selectedAccounts.add(new SelectOption(tempCon.AccountId,accountName));
        
        selAccId.add(tempCon.AccountId);
        
        if(tempCon.AccountId == accId)
            searchResults.clear();  
        
        System.debug('selectedAccounts : ' + selectedAccounts);
        
        return null;
    }
    
    public void avoidRefresh()
    {}
    
    public List<String> getResultsname()
    {
        //Make sure to clear past values
        clearValues();
        if(resultsname.isEmpty()){
            hasnoresults = true;
            resultsname.add('No Results');
        }
        return resultsname;
    }
    
    public string sortField 
    {
        get;
        set {     
            this.previousSortField = sortField;
            this.sortField = value;
            if(previousSortField == sortField) {
                isAscending = !isAscending;
                return;
            }
            this.isAscending = true;  
        }
    }
    
    //----------------------------------------------------------------//
    //Action methods for sorting
    //---------------------------------------------------------------//
    
    public PageReference DoSort()
    {     
        QueryData();
        return null;    
    }
    
    public PageReference search() 
    {
		if(String.isNotBlank(searchText) && searchText.length() <= 2)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter 3 or more characters for search.'));
            return NULL;
        }
            
        try 
        {
            SortField = 'Name';
            isAscending = true;
            QueryData(); 
        } 
        catch(Exception e) 
        {
            system.debug(e);
        }
        return null;
    }
    
    private void QueryData()
    {
        if(String.isNotBlank(searchText))
        {
            String qry = 'SELECT Id,Name FROM Account WHERE Account_Status__c like \'%- Active\' And Name LIKE \'%'+searchText+'%\' order by Name limit 100';
            listAccounts = new List<Account>();
            for(Account acc: Database.query(qry))
            {
                listAccounts.add(acc);
            }
        }
    }
    
}