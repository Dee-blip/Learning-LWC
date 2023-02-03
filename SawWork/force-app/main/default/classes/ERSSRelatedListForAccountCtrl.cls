public class ERSSRelatedListForAccountCtrl{

    public String accountId{get;set;}
    
    public Integer totalERSSRec;
    public Integer totalNumberOfPages{get{if(totalNumberOfPages == null) totalNumberOfPages =totalPages(); return totalNumberOfPages;}set;}
    public Integer currentPageNumber{get{if(currentPageNumber == null) currentPageNumber =1; return currentPageNumber ;}set;}
    public Integer pageSize = 10;
    
    public Account accRec;
    
    //List for eRSS forms to be displayed
    public List<RSS_Form__c> lRSSFormsToDisplay{
        get{
                lRSSFormsToDisplay.clear();
                
                for(RSS_Form__c objRSSForm: (List<RSS_Form__c>) objCon.getRecords()){  
                        lRSSFormsToDisplay.add(objRSSForm);
                }
                return lRSSFormsToDisplay;
        }
        set;
    }
    
    //Constructor for counting total number of records. 
    public ERSSRelatedListForAccountCtrl(ApexPages.StandardController controller){
        lRSSFormsToDisplay = new List<RSS_Form__c>();
        accRec = (Account) controller.getRecord();
        totalERSSRec = [SELECT count() FROM RSS_Form__c WHERE (Published__c = true OR Submitted__c = true) AND Account__c =: accRec.Id];
    }
    
    //Setting the Standard set controller for displaying all the records in different pages.
    public ApexPages.StandardSetController objCon{
        get{
                if(objCon== null){
                objCon= new ApexPages.StandardSetController(Database.getQueryLocator([SELECT Id, Name,AEName__c ,Version__c,Opportunity__c,Products__c,OwnerId,Submittal_Date__c, Published_Date__c  FROM RSS_Form__c WHERE (Published__c = true OR Submitted__c = true) AND Account__c =: accRec.Id ORDER BY Name]));
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
       return (Integer)Math.ceil((Double)totalERSSRec/pageSize);
    }
}