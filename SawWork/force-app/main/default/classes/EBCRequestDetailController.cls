/*
Created the EBCRequestDetailController for the EBCDetailCustomNewPage 
Its create the mapping of the Opportunity and the EBC_Request__c.
*/
public class EBCRequestDetailController {
    
    public EBC_Request_Detail__c ebcReq;
    //Id to store the current EBC Request
    public Id EbcRequestid;
    public List< EBC_Request_Detail__c > ebcDetailList{get;set;}
    public Set<Id> EbclinkedOppty = new Set<Id>();
    public List<OpportunityWrapper> opptyWrapperList;
    public List<OpportunityWrapper> SelectedWrapperList = new List<OpportunityWrapper>();
    
    //Wrapper class to store the opportunity and Checkbox
    public class OpportunityWrapper{
        public Opportunity opp{get; set;}
        public Boolean CheckBox{get; set;}
    }
   
    
    // instantiate the StandardSetController from a query locator
    public ApexPages.StandardSetController con {
        get {
            if(con == null) {
                con = new ApexPages.StandardSetController(Database.getQueryLocator([Select Id, name, StageName, CloseDate, MRR__c From opportunity Where AccountId In  (Select Associated_Account__c from EBC_Request__c Where Id =: EbcRequestid)]));
                // sets the number of records in each page set
                con.setPageSize(100);
            }
            
            return con;
        }
        set;
    }
   
   //returns the Opportunities associated with the Account to the page.
    public List<OpportunityWrapper> getOpptyWrapperList(){
    opptyWrapperList = new List<OpportunityWrapper>();
    If(EbcRequestid != null){
      ebcDetailList = [Select Opportunity__c , EBC_Request__c, Id From EBC_Request_Detail__c Where EBC_Request__c =: EbcRequestid];
        if(ebcDetailList != null && !ebcDetailList.isEmpty()){
            for(EBC_Request_Detail__c ebc : ebcDetailList){
                EbclinkedOppty.add(ebc.Opportunity__c);
             }
         }
     }      
     List<Opportunity> OppList = (List<opportunity>)con.getRecords();
     Set<Opportunity> OppSet = new Set<Opportunity>(OppList);
        for(Opportunity opp:  OppSet){
           if(EbclinkedOppty != null && !EbclinkedOppty.isEmpty()){
              if(EbclinkedOppty.contains(opp.id)){
                 OppSet.remove(opp);
                 continue;
               }
          }    
          //  System.debug('oppList---->'+ oppList);
          OpportunityWrapper oppwrapper = new OpportunityWrapper();
          oppwrapper.opp = opp;
          oppwrapper.CheckBox = false;
          opptyWrapperList.add(oppwrapper);
         } 
         if(opptyWrapperList.isEmpty()){
         
           ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.INFO,'NO opportunities found for the associated Account with the EBC Request');
           ApexPages.addMessage(myMsg);
          }
      return opptyWrapperList;
    }     
    
    //Standard controller used to get the id of the Ebc Request 
    public EBCRequestDetailController(ApexPages.StandardController stdcontroller) {
        this.ebcReq = (EBC_Request_Detail__c)stdController.getRecord();
        if (ebcReq != null)
            EbcRequestid = ebcReq.EBC_Request__c;
          
    }
    
    
    // Attaches the Oppty with the EBC request Detail 
    public PageReference SaveOppty(){
    List<EBC_Request_Detail__c> ebcDetailList = new  List<EBC_Request_Detail__c>();
    Pagereference ref = null;
    if(!opptyWrapperList.isEmpty()){
       for(OpportunityWrapper owrapper: opptyWrapperList){
            if(owrapper.checkbox == true){
                EBC_Request_Detail__c ebcd = new EBC_Request_Detail__c();
                ebcd.EBC_Request__c = EbcRequestid;
                ebcd.Opportunity__c =  owrapper.Opp.Id;  
                ebcDetailList.add(ebcd);
            }
        }  
       try{
           if(!ebcDetailList.isEmpty()){
              insert ebcDetailList;
              ref = new PageReference('/'+ EbcRequestid); 
              }
           else{
               ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Error,'Add the opportunity  First and then click the button');
               ApexPages.addMessage(myMsg);
               }
           }   
       catch(Exception e){
           ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.Error,e.getmessage());
           ApexPages.addMessage(myMsg);
           }
        }
   return ref;
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

    // returns the first page of records
     public void first() {
         con.first();
     }

     // returns the last page of records
     public void last() {
         con.last();
     }

     // returns the previous page of records
     public void previous() {
         con.previous();
     }

     // returns the next page of records
     public void next() {
         con.next();
     }

     // returns the PageReference of the original page, if known, or the home page.
     public void cancel() {
         con.cancel();
     }
}