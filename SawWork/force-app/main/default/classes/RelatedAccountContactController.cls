/*=====================================================================================================+
    Class name          :   RelatedAccountContactController 
    Author              :   Aditya Sonam
    Created             :   19-May-2016
    Purpose             :   This is a controller class for page RelatedAccountContact to fetch BOCC contact
							associated with BOCC Case

    Last Modified    Developer   	 CR	 	   Purpose            
    =============    =========     =======	  =========

+=====================================================================================================*/

Public class RelatedAccountContactController {

    //public list<Contact> contactList{get;set;}
    public String contactType{get;set;}
    public String caseAccountId;
    
    //Pagination Varibles
    public Integer totalAccountContact;
    public Integer totalNumberOfPages{get{if(totalNumberOfPages == null) totalNumberOfPages =totalPages(); return totalNumberOfPages;}set;}
    public Integer currentPageNumber{get{if(currentPageNumber == null) currentPageNumber =1; return currentPageNumber ;}set;}
    public Integer pageSize = 5;

	//Invoking Constructor to fetch CaseId and get Total Record Count  
    public RelatedAccountContactController(ApexPages.StandardController controller){    
        caseAccountId = [SELECT Id, AccountId FROM Case WHERE Id = :ApexPages.currentPage().getParameters().get('id') limit 1][0].AccountId;   
        caseContact = new List<contact>(); 
        totalAccountContact = [SELECT count() FROM Contact WHERE AccountId = :caseAccountId and Contact_Type__c INCLUDES('BOCC/BMS')];
    }
  
    //Passing Records fetched from Std Controller to Table 
    public List<Contact> caseContact{
      get{
            caseContact.clear();
          	caseContact.addAll((List<contact>) objCon.getRecords());
            contactType = 'BOCC/BMS';
            return caseContact;
        }
        set;
    }

     //Setting the Standard set controller for displaying all the records in different pages.
    public ApexPages.StandardSetController objCon{
        get{
                if(objCon== null){
                objCon= new ApexPages.StandardSetController(Database.getQueryLocator([SELECT Id,Name,Email,Phone,Contact_Type__c,AccountId 
                                                                                      FROM Contact WHERE AccountId = :caseAccountId and Contact_Type__c INCLUDES('BOCC/BMS')]));
                objCon.setPageSize(pageSize);
            }
            return objCon;
        }
        set;
     }
    
    //Boolean to check if Standard set controller contains next batch of records.
    public Boolean hasNext{
        get {
                return objCon.getHasNext();
        }
        set;
    }
 
        //Boolean to check if Standard set controller contains previous batch of records.
    public Boolean hasPrevious{
        get{
                return objCon.getHasPrevious();
        }
        set;
    }
        
        //This method returns the first page of standard set controller
    public void first(){
        // returns the first page of records
        if(objCon!= null){
                currentPageNumber = 1;
                objCon.first();
        }
    }
     
     //This method navigates user to the last batch of records.
     public void last(){
        // returns the last page of records
        if(objCon!= null){
                currentPageNumber = totalPages();
                objCon.last();
        }
    }
    
    //Returns previous page of record. 
    public void previous(){
        // returns the previous page of records
        if(objCon!= null){
           currentPageNumber = --currentPageNumber;
           objCon.previous();
        }
    }
    
    //Returns the next batch of recs to be displayed to the users. 
    public void next(){
        // returns the next page of records  
        if(objCon!= null){
            currentPageNumber = ++currentPageNumber;
            objCon.next();
        }
    }
    
    //Returns total number of pages for a Account.
    public Integer totalPages(){
       return (Integer)Math.ceil((Double)totalAccountContact/pageSize);        
    }
}