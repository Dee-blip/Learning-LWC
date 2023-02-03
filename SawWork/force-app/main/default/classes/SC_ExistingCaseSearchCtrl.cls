/*
 * Controller for SC_ExistingCaseSearchPage
 * This controller shows the Case results
 * You can Search by Case Number or Akam Case Id
 * Name : SC_ExistingCaseSearchCtrl
 * Created By : Kunal Sharma
 */ 
public class SC_ExistingCaseSearchCtrl {
    
    public integer i = 0;    

    public static string parentCaseId15Digit = ApexPages.currentPage().getParameters().get('caseId');
    public static string existingParentCaseId15Digit = ApexPages.currentPage().getParameters().get('parentCaseId');
    public static string parentCaseId {get{ if(parentCaseId == null && parentCaseId15Digit != null && parentCaseId15Digit != '') parentCaseId = Id.valueOf(parentCaseId15Digit); return parentCaseId;} set;} //ApexPages.currentPage().getParameters().get('caseId');
    public static string existingParentCaseId{get{ if(existingParentCaseId == null && existingParentCaseId15Digit != null && existingParentCaseId15Digit != '') existingParentCaseId = Id.valueOf(existingParentCaseId15Digit); return existingParentCaseId;} set;}
    
    public string akamCaseId{get;set;}    
    public string searchBasedOn {get;set;}
    public string exceptionOccured{get{if (exceptionOccured == null) exceptionOccured = 'false'; return exceptionOccured; } set;}
	public string casesWithCircularDependancy{get{if(casesWithCircularDependancy == null) casesWithCircularDependancy = ''; return casesWithCircularDependancy;}set;}

	public List<Case> lCasesToDisplay{get;set;}
    public List<SearchCaseWrapper> lCaseWrapperToDisplay{get;set;}
    public List<SelectOption> lPickListOptions {get{if(lPickListOptions==null) lPickListOptions= new List<SelectOption>{new SelectOption('Akam Case Id','Akam Case Id'),new SelectOption('Case Number','Case Number')}; return lPickListOptions;} set;}
    
    public Map<Id,Case> mIdCaseDetail = new Map<Id,Case>();

    public SC_ExistingCaseSearchCtrl(){
        casesWithCircularDependancy = '';
    }
    
    /*
     *Search Cases based on Akam Case Id and Case Number 
     */ 
    public void searchCaseBasedOnAkamId(){
        List<String> lCasesToSearch = akamCaseId != null ? akamCaseId.replace(' ','').replace(';',',').split(',') : new List<String>();
        lCaseWrapperToDisplay = new List<SearchCaseWrapper>();
        
        if(searchBasedOn == 'Akam Case Id'){
            for(Case varCase : [SELECT Id,Account.Name, CaseNumber, Subject, Akam_Case_Id__c, Akam_Created_Date__c, ParentId, Status, AccountId, RecordType.Name, Parent.CaseNumber, Owner.Name FROM Case WHERE Akam_Case_Id__c IN :lCasesToSearch]){
                lCaseWrapperToDisplay.add(new SearchCaseWrapper(varCase));
                mIdCaseDetail.put(varCase.Id, varCase);
            }
        }
        
        else if(searchBasedOn == 'Case Number'){
            for(Case varCase : [SELECT Id,Account.Name, CaseNumber, Subject, Akam_Case_Id__c, Akam_Created_Date__c, ParentId, Status, AccountId, RecordType.Name, Parent.CaseNumber,Owner.Name FROM Case WHERE CaseNumber IN :lCasesToSearch]){
                lCaseWrapperToDisplay.add(new SearchCaseWrapper(varCase));
                mIdCaseDetail.put(varCase.Id, varCase);
            }
        }
        
        if(lCaseWrapperToDisplay.size() == 0)
        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'There are no Cases with the criteria that you have entered. Please check the Akam Case Id or Case Number that you have entered.'));
    }
    
    /*
     * Updates Parent Case lookup on all the Cases which were selected
     */ 
    public void updateParentCase(){
        List<Case> lCaseToUpdate = new List<Case>();
        for(SearchCaseWrapper objCaseToUpdate : lCaseWrapperToDisplay){
            if(objCaseToUpdate.selectedCase){
                 objCaseToUpdate.caseToDisplayWrapper.ParentId = parentCaseId;
                 objCaseToUpdate.caseToDisplayWrapper.Validation_Override__c = true;
                 lCaseToUpdate.add(objCaseToUpdate.caseToDisplayWrapper);
            }
        }
        
        List<Database.SaveResult> lException = new List<Database.SaveResult>();

            
        if(lCaseToUpdate.size()>0){
                lException = Database.update(lCaseToUpdate,false);
        }
        
        for(Database.SaveResult objErrorMessage :lException){
            if(! objErrorMessage.isSuccess()){
                for(Database.Error errorMessage : objErrorMessage.getErrors()){
                    exceptionOccured = 'true';
                    casesWithCircularDependancy += lCaseToUpdate[i].Akam_Case_Id__c + ',';
                }
            }
            i++;
        }
        
        if(casesWithCircularDependancy != ''){
            casesWithCircularDependancy = casesWithCircularDependancy.substringBeforeLast(',');
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,'Error occurred while updating following Cases ' + casesWithCircularDependancy));
        }
    }
    
    /*
     * Method for showing message on tooltip
     */ 
    public static string createTitleForColumn(Case objCase){
        System.debug('### ' + objCase.Id + ' ' + existingParentCaseId + ' ' + parentCaseId);
        if(objCase.Id == existingParentCaseId || objCase.Id == parentCaseId){
            return 'This case is parented by a case that is also its child';
        }
        
        if(objCase.ParentId != null){
            return 'This case already has a parent';
        }
        
        if(objCase.Status.containsIgnoreCase('close')){
            return 'This case is already closed';
        }
        else{
            return 'Please select this Case to update';
        }
        return '';
    }
    
    /*
     * Method for making checkbox readonly based on below condition
     */
    public static boolean isColumnReadOnly(Case objCase){
        if(objCase.Status.containsIgnoreCase('close') || objCase.ParentId != null 
           || objCase.Id == existingParentCaseId || objCase.Id == parentCaseId){
            return true;
        }
        return false;
    }
    
    /*
     * Method for showing result in the table with checkbox.
     */
    public class SearchCaseWrapper{
        public boolean selectedCase{get;set;}
        public Case caseToDisplayWrapper{get;set;}
        public string title{get;set;}
        public boolean makeColumnReadOnly{get;set;}
        
        SearchCaseWrapper(Case varCase){
            selectedCase = false;
            caseToDisplayWrapper = varCase;
            title = createTitleForColumn(varCase);
            makeColumnReadOnly = isColumnReadOnly(varCase);
        }
    }
}