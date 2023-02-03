/*   Developer        Date          CR         Description
     Ruchika Sharma   16-03-2015    2954603    Ability to Track OEM Pipeline without affecting Akamai Pipeline
     
     Controller for OEMContactCustomContactLookupPage. 
     This class takes parameter from page url to get OEM Account Id to filter contacts

     Sonali Tandon    16 November 2015  Commenting out code as part of CR 3205251. Added filter on Contact Look up instead. 
*/
public with sharing class OEMContactCustomContactLookupController {

  
  /*public List<Contact> results{get;set;} // search results
  public string searchString{get;set;} // search keyword
  public string accountIdSearch{get;set;} // account Id to be put in query

  public OEMContactCustomContactLookupController() {
   
    // get the current search string
    searchString = System.currentPageReference().getParameters().get('lksrch');
    accountIdSearch = System.currentPageReference().getParameters().get('accountId');
    runSearch();  
  }

  // performs the keyword search
  public PageReference search() {
    runSearch();
    return null;
  }

  // prepare the query and issue the search command
  private void runSearch() {
    // TODO check query to prevent injections
    results = performSearch(searchString, accountIdSearch);               
  } 

  // run the search and return the records found. 
  private List<Contact> performSearch(string searchString, String accountIdSearch) {
    System.debug('searchString: '+searchString+' accountIdSearch: '+accountIdSearch);
    String soql = 'select id, name from contact';
    if(accountIdSearch != '' && accountIdSearch != null){
        soql = soql +  ' where accountId=:accountIdSearch';
        if(searchString != '' && searchString != null)
            soql = soql +  ' and name LIKE \'%' + searchString +'%\'';
      }
    else if(searchString != '' && searchString != null)
        soql = soql +  ' where name LIKE \'%' + searchString +'%\'';
      
      System.debug(soql);
      return database.query(soql); 

  }


  // used by the visualforce page to send the link to the right dom element
  public string getFormTag() {
    return System.currentPageReference().getParameters().get('frm');
  }

  // used by the visualforce page to send the link to the right dom element for the text box
  public string getTextBox() {
    return System.currentPageReference().getParameters().get('txt');
  }*/

}