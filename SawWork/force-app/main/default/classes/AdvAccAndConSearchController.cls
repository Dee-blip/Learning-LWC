/* 
    Sharing class for the Advance Account Search functionality.
    Search the data from the Account and the data.com both 
*/

    public class AdvAccAndConSearchController {

    //getter setter for getting the name String from UI
    public String AccName{get;set;}
    //getting and setting the selected country in UI
    public String selectedCountry{get;set;}
    // standard controller for pagination for Internal Revord
    public ApexPages.StandardSetController con{get; set;}
    //List to show the search Account record in the page
    public List<Account> SortedAcclst = new  List<Account>();
     //List to show the search Account record in the page
    public List<Account> SortedAcclstFull = new List<Account>();
    //Flag to render and rerender the pageblockTable to show  the internal account data in table
    public boolean AccountData{get;Set;}
    //Flag to render and rerender the pageblockTable to show  the Data.com account data in table
    public boolean AccountDatacom{get;Set;}
    public boolean SearchresultFlag;
   //flag to show the error msg , When no record found in internal data
    public boolean nodataFlag{get;set;}
    
    //flg for the exact Search
    public boolean exactSearch{get;set;}  
    
    //fields for the confirmed page
    public boolean confirmedFlag{get;set;}
     
    public Map<String,List<Account>> sortedSalesforceAccMap = new Map<String,List<Account>>();
    
    //offset Pagination Fields
    private integer counter=0;  //keeps track of the offset
    private integer list_size=10; //sets the page size or number of rows
    public integer total_size; //used to show user the total size of the list
    public integer CurrentPageNumber;
  //  PUBLIC integer SFDCTotalPages;

    //Salesforce Pagination Fields
    private integer counterSalesforce=0;  //keeps track of the offset
    private integer list_sizeSalesforce=10; //sets the page size or number of rows
    public integer total_sizeSalesforce; //used to show user the total size of the list
    public integer CurrentPageNumberSalesforce;
    
    //CONSTRUCTOR
    public AdvAccAndConSearchController(ApexPages.StandardController controller) {
        //set the total size in the constructor
   
    }
 
     public boolean getSearchresultFlag(){
        return  SearchresultFlag;
     }
   
    
    //Search account from the Internal database
    public void searchAccount(){

   // datacloudCompanyList.clear(); swati
    counter =0; 
    counterSalesforce =0;    
        
        try{
         
           SearchresultFlag = true;
           AccountData = false;
          
           String Initialquery= 'SELECT name, Id,OwnerId,Owner.name, Account_Status__c, Website, Vertical__c,BillingStreet, BillingCity, BillingState, BillingPostalCode,BillingCountry, Sub_Vertical__c,AKAM_Account_ID__c ,Parent.Name  FROM Account '; //Order By Account_Status__c';
              String query = generateDynamicQuery(Initialquery,AccName,selectedCountry,false);
                if(query != null && query !=''){
                //DataFlag = true;
                  query += ' Order By Account_Status__c ,Name';
                  INTEGER lim = Integer.valueOf(AdvanceSearchDataCom__c.getInstance('AdvanceAccSearch#SfLimit').value__c);
                  query += ' Limit '+ lim;
                  List<Account> accountList =  Database.query(query);
                  if(accountList != null && !accountList.isEmpty()){
                       AccountData = true;
                      total_sizesalesforce = accountList.size();
                      //Sorting Account 
                      sortMapGenerator(accountList);
                  }
                 
                }
              }Catch(Exception e){
               ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,e.getMessage()));
           }     
     }


 
  public void sortMapGenerator(List<Account> acclist){
      try{
          //top level sort
    //create the value for each top shorts .. higher at no 1
    //store the index and value at that place in list
    sortedSalesforceAccMap.clear();
   // sortedAccountCountMap.clear();
    For(Account acc : accList) {
      String key ;
       //Check the first level of sort
      /* IF(acc.OwnerId == UserInfo.getUserId() && acc.Owner.name !='Owner Not Assigned'){
         key = 'a';
       }ELSE IF(acc.Owner.name !='Owner Not Assigned'){
        key ='b';
       }
       ELSE{
       key ='c';          
       }  */       
       //Check the  Accname and AccWebsite 
       IF(!exactSearch) { 
          // case for the  exact Search
          IF(acc.name.equalsIgnoreCase(AccName) && acc.Website != null && acc.Website.containsIgnoreCase(AccName)){
            key = 'a';
            // Add account
          }
          ELSE IF(acc.name.containsIgnoreCase(AccName) && acc.Website != null && acc.Website.containsIgnoreCase(AccName)){
            key = 'b';
            // Add account
          }
           
          ELSE IF(acc.name.equalsIgnoreCase(AccName)){
              //Add account
            key = 'c';
          }
           
          ELSE IF(acc.name.containsIgnoreCase(AccName)){
              //Add account
            key = 'd';
          }
          ELSE IF(acc.Website != null && acc.Website.containsIgnoreCase(AccName)){
              //Add account
            key = 'e';
          }
          ELSE{
            key = 'f';
          }
          
        }
       ELSE{
        key = 'a';
       } 
       //Check for the Parent Account
      IF(acc.ParentId == null ){
        key += 'a';
      }
      ELSE{
        key +='b';
      }
      //Check the lead status 
      String ActivStatus = AdvanceSearchDataCom__c.getInstance('AdvanceAccSearch#Status1').value__c;
       ActivStatus += AdvanceSearchDataCom__c.getInstance('AdvanceAccSearch#Status2').value__c; 
       ActivStatus += AdvanceSearchDataCom__c.getInstance('AdvanceAccSearch#Status3').value__c; 
     // String ActiveStatus = '- Active,Agency - Active,Akamai Internal - Active,Alliance Partner - Active,Brand – Active,Conference Reseller - Active,Conferencing Reseller - Active,Direct Customer - Active,Field Technician - Active,Indirect Customer - Active,SP - Active,Multiple Contracts - Active,Multiple w ISP - Active,Multiple wo ISP - Active,OEM Reseller - Active,Partner - Active,Referral Partner - Active,Tier 1 Reseller - Active,Value Added Reseller - Active,VAR Customer - Active,Vendor – Active,Parent Customer - Active';
      String NonActivStatus = AdvanceSearchDataCom__c.getInstance('AdvanceAccSearch#InActiveStatus1').value__c;
       NonActivStatus += AdvanceSearchDataCom__c.getInstance('AdvanceAccSearch#InActiveStatus2').value__c; 
       NonActivStatus += AdvanceSearchDataCom__c.getInstance('AdvanceAccSearch#InActiveStatus3').value__c;
       NonActivStatus += AdvanceSearchDataCom__c.getInstance('AdvanceAccSearch#InActiveStatus4').value__c;
        // String NonActiveStatus ='Agency – Inactive,Akamai Internal – Inactive,Alliance Partner – Inactive,ASPP – Inactive,Brand - Inactive,Conference Reseller – Inactive,Conferencing Reseller – Inacti,Direct Customer – Inactive,Conferencing Reseller – Inactive,Direct Customer – Inactive,Field Technician – Inactive,- Inactive,Indirect Customer – Inactive,ISP – Inactive,Multiple Contracts – Inactive,Multiple w ISP – Inactive,Multiple wo ISP - Inactive,OEM Reseller – Inactive,Partner – Inactive,Portal Partner – Inactive,Referral Partner – Inactive,Streaming Reseller – Inactive,Strategic – Inactive,Streaming Reseller – Inactive,Tier 1 Reseller – Inactive,Value Added Reseller – Inactive,VAR Customer – Inactive,Vendor - Inactive';
     IF(acc.Account_Status__c != null && ActivStatus.trim().containsIgnoreCase(acc.Account_Status__c)){
        Key += 'a';
      }
      ELSE IF(acc.Account_Status__c != null &&  NonActivStatus.trim().containsIgnoreCase(acc.Account_Status__c)){
        Key +='b';
      }
      ELSE IF(acc.Account_Status__c != null && acc.Account_Status__c =='Lead'){
        Key +='c';
      }
      ELSE{
        Key += 'd';
      }
        
        
      // To store the value in the map with the increment 
      IF(!sortedSalesforceAccMap.containsKey(key)){
        List<Account> mapaccList = new List<Account>();
        mapaccList.add(acc);
        SortedSalesforceAccMap.put(key,mapaccList);
      }else{
       List<Account> tempAcclist = sortedSalesforceAccMap.get(key);
       tempAccList.add(acc);
       SortedSalesforceAccMap.put(key,tempAccList);

      }
      
    }
      if(!SortedSalesforceAccMap.isEmpty()){
     SortAccount();
      }     
    //bottom level sort(1st criteria)
      }
      catch(Exception e){
          
      }
  }

  public void SortAccount( ){
    SortedAcclstFull.clear();
    List<String> sortList =  new List<String>(SortedSalesforceAccMap.keyset());  
    IF(SortedSalesforceAccMap != null && !SortedSalesforceAccMap.isEmpty()){
     sortList.sort(); 
     
      FOR(String uniquekey :sortList){
        SortedAcclstFull.addAll(SortedSalesforceAccMap.get(uniquekey));
      }
       
         System.debug('SortedAcclstFull'+ SortedAcclstFull.size());
    }
  }

  public List<Account> getSortedAcclst(){
    SortedAcclst.clear();
     //SortedAcclst = new List<Account>(); 
    INTEGER initialStart = counterSalesforce;
    Integer endrecord = counterSalesforce + list_sizeSalesforce;
    //Integer mainListLength =
    FOR( Integer i= initialStart ; endrecord >= i; i++ ){
      if(i < total_sizesalesforce){
         SortedAcclst.add(SortedAcclstFull[i]);
        //counter++;
      }
    }
      return SortedAcclst;
  }

  
    
    //Dynamic Query generator for datacom and Salesforce
    public String generateDynamicQuery(String initialquery, String Param1, String Param2,Boolean Data){
        String query = initialquery;
           if((Param1 != null && Param1.length() >= 3 ) ) {
               query += ' Where ' ; 
              // Integer i =0;
              // if the search is not exact search
              If(!exactSearch){
                      
                            query += '(Website Like' +'\''+'%'+Param1+'%'+'\'' + ' OR ';
                                query += 'Name Like' +'\''+'%'+Param1+'%'+'\')' ;
                              System.debug('Query ='+query); 
                        
                      }      
                    else {
                        if(Param1 != null && Param1 !=''){
                          
                            query += '( Website =' +'\''+Param1+'\''+ ' OR ';
                             query += 'Name =' +'\''+Param1+'\')'; 
                                                            
                   }    
               }
               
               //Check for the  param 2 field and create the query
               if(Param2 != null && Param2 != ''){
                  query +=  ' AND '; 
                      query += ' BillingCountry = ' + '\'' +Param2  + '\'' ;
               }
                System.debug('Query ='+query); 
               return query; 
           }
           else{
             ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.Error,'Please use minimum 3 letter to search in AccountName/Website'));   
             return '';
          } 
           
      }
   
   //Code for the Add new button 
    public PageReference AddNewAccount(){
      String Prefix =  Schema.Sobjecttype.Account.getKeyPrefix();
      PageReference returnURL = new Pagereference ('/'+ Prefix+ '/e?');
      returnURL.getParameters().put('nooverride', '1');
      returnURL.getParameters().remove('save_new');
      returnURL.setRedirect(true);     
      return returnURL;

    
    }
    
    
    //List to create the pickList from the Country_List__mdt 
    public List<SelectOption> getcountryList() {
         List<SelectOption> countryList  = new List<SelectOption>();
         countryList.add(new SelectOption('','--None--'));
         /*List<String> SortedList = new List<String>();
         SortedList.addAll(Countries__c.getAll().keySet());
         SortedList.sort();
         for( String country : SortedList) {
           countryList.add(new SelectOption(country,country));
         }*/  //SFDC-2304
        
        //start of SFDC-2304
        List<Country_List__mdt> SortedList = new List<Country_List__mdt>();
        SortedList = [select Label from Country_List__mdt limit 50000];
        SortedList.sort();
        for(Country_List__mdt country : SortedList) {
            countryList.add(new SelectOption(country.Label,country.Label));
        }
        //end of SFDC-2304
        return countryList;
     }
    
    
 
    //offset pagination
    
   public PageReference Beginning() { //user clicked beginning
      counter = 0;
      return null;
   }

   public PageReference offPrevious() { //user clicked previous button
      counter -= list_size;
      return null;
   }

   public PageReference offNext() { //user clicked next button
      counter += list_size;
      return null;
   }

   public PageReference End() { //user clicked end
      System.debug('Size'+ total_size);
       if(math.mod(total_size, list_size) != 0){
        counter = total_size - math.mod(total_size, list_size);
       }Else{
           counter = total_size - 10;
       }
       System.debug('counter'+ counter);
           
      return null;
   }

   public Boolean getDisablePrevious() { 
      //this will disable the previous and beginning buttons
      if (counter>0) return false; else return true;
   }

   public Boolean getDisableNext() { //this will disable the next and end buttons
      if (counter + list_size < total_size)
       return false; 
       else return true;
   }

   public Integer getTotal_size() {
      return total_size;
   }

   public Integer getCurrentPageNumber() {
      integer size = counter/list_size + 1;
       System.debug('counter'+ size);
      return counter/list_size + 1;
     
   }

   public Integer getTotalPages() {
      if (math.mod(total_size, list_size) > 0) {
         return total_size/list_size + 1;
      } else {
         return (total_size/list_size);
      }
   
   }   ///test class Data
      
     // pagination For the salesforce.com
    
   public PageReference BeginningSfdc() { //user clicked beginning
      counterSalesforce = 0;
      return null;
   }

   public PageReference offPreviousSfdc() { //user clicked previous button
      counterSalesforce -= list_sizeSalesforce;
      return null;
   }

   public PageReference offNextSfdc() { //user clicked next button
      counterSalesforce += list_sizeSalesforce;
      return null;
   }

   public PageReference EndSfdc() { //user clicked end
      counterSalesforce = total_sizeSalesforce - math.mod(total_sizeSalesforce, list_sizeSalesforce);
      return null;
   }

   public Boolean getDisablePreviousSfdc() { 
      //this will disable the previous and beginning buttons
      if (counterSalesforce >0) return false; else return true;
   }

   public Boolean getDisableNextSfdc() { //this will disable the next and end buttons
      if (counterSalesforce + list_sizeSalesforce < total_sizeSalesforce)
       return false; 
       else return true;
   }

   public Integer getTotal_sizeSfdc() {
      return total_sizeSalesforce;
   }

   public Integer getCurrentPageNumberSfdc() {
      integer size = counterSalesforce/list_sizeSalesforce + 1;
       System.debug('counterSalesforce'+ size);
      return counterSalesforce/list_sizeSalesforce + 1;
     
   }

   public Integer getTotalPagesSfdc() {
      if (math.mod(total_sizeSalesforce, list_sizeSalesforce) > 0) {
         return total_sizeSalesforce/list_sizeSalesforce + 1;
      } else {
         return (total_sizeSalesforce/list_sizeSalesforce);
      }
   
   }   ///test class Data
            
 }