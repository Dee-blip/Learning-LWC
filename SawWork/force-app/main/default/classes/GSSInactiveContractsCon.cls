/*=====================================================================================================+
    Class name          :   GSSInactiveContractsCon 
    Author              :   Akhila Vidapanapati
    Created             :   6-Nov-13
    Purpose             :   This is the Controller extension for GSSInactiveContracts Visualforce Page
    Last Modified       :   15-Nov-13
    Purpose             :   Initial Development
 
+=====================================================================================================*/
public with sharing class GSSInactiveContractsCon {
 
    List<Merge_Contract_Header__c> cntract {get;set;}
    
    private Account acnt;            
    private Integer total_size;      //Total no of records
    private Integer list_size = 5;   //No. of records per page 
    
    //constructor
    public  GSSInactiveContractsCon(ApexPages.StandardController controller) {
        this.acnt= (Account)controller.getRecord();
        this.total_size = [select count() from Merge_Contract_Header__c where Account_Name__c = : acnt.id and Active__c=false and Effective_Start_Date__c <: System.today()];
    }
    
    
    // instantiate the StandardSetController from a query locator
    public ApexPages.StandardSetController con {
        get {
            if(con == null) {
                con = new ApexPages.StandardSetController(Database.getQueryLocator([Select id, Name,Contract_Type__c,Solution_Set__c,Revision_Effective_Start_Date__c,Effective_Start_Date__c,Effective_End_Date__c,Parent_Account_Name__c,Contract_Transferred_To__c,Account_Name__c from Merge_Contract_Header__c where Account_Name__c = :acnt.id and Active__c=false and Effective_Start_Date__c <: System.today() ORDER BY Name]));
                // sets the number of records in each page set
                con.setPageSize(list_size);
            }
            return con;
        }
        set;
    }
 
    // returns a list of Merge_Contract_Header__c objects for the sObjects in the current page set
    public List<Merge_Contract_Header__c> getcntract() {
        cntract = new List<Merge_Contract_Header__c >();
        for (Merge_Contract_Header__c c : (List<Merge_Contract_Header__c >)con.getRecords())
            cntract.add(c);
 
        return cntract;
    }
 
  
 
    // indicates whether there are more records after the current page set.
    public Boolean hasNext {
        get {
            return con.getHasNext();
        }
        set;
    }
 
    // indicates whether there are more records before the current page set.
    public Boolean hasPrevious {
        get {
            return con.getHasPrevious();
        }
        set;
    }
 
    // returns the page number of the current page set
    public Integer pageNumber {
        get {
            return con.getPageNumber();
        }
        set;
    }
 
    // returns total no of pages
    public Integer TotalPages {      
        get{  
           if (math.mod(total_size, list_size) > 0) {
           return total_size/list_size + 1;
           }
           else {
           return (total_size/list_size);
           }
        }
        set;
    }
   
   
    // returns the first page of records
    public void Beginning() {
        con.first();
    }
 
    // returns the last page of records
    public void Last() {
        con.last();
    }
 
    // returns the previous page of records
    public void Previous() {
        con.previous();
    }
 
    // returns the next page of records
    public void Next() {
        con.next();
    }
     
}