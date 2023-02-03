/*
Template: Apex Class/Trigger Template 

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : Used as apart of lookup Class

Purpose : an implementation for Custom Component
          
Usage : used as an implementation for Custom user lookup.
          
Test Class Asssociated : NONE

Controller (Boolean): True

Page Used/Asssociated (default -> NONE) : hduserlookup

component Associated : [  ]
Class used : 
              
*/
public with sharing class HD_Custom_User_Lookup_controller 
{
public static User user {get;set;}
public static List<User> results{get;set;}
public String searchString{get;set;}


//constructor
public HD_Custom_User_Lookup_controller()
{
user = new User();
// get the current search string
searchString = System.currentPageReference().getParameters().get('lksrch');
runSearch();


}//Constructor END

// performs the keyword search
public PageReference search() {
runSearch();
return null;
}//public PageReference search() 

  // prepare the query and issue the search command
  private void runSearch() {
    // TODO prepare query string for complex serarches & prevent injections
    results = performSearch(searchString);               
  }//  private void runSearch()
  
  // run the search and return the records found. 
  private List<User> performSearch(string searchString) {

    String soql = 'select id, name, alias,email,username from User';
    if(searchString != '' && searchString != null)
      soql = soql +  ' where isActive = true and name LIKE \'%' + searchString +'%\'';
    soql = soql + ' limit 25';
    System.debug(soql);
    return database.query(soql); 

  }//   private List<Account> performSearch(string searchString)   
  
    // used by the visualforce page to send the link to the right dom element
  public string getFormTag() {
    return System.currentPageReference().getParameters().get('frm');
  }//  public string getFormTag() 
    
  // used by the visualforce page to send the link to the right dom element for the text box
  public string getTextBox() {
    return System.currentPageReference().getParameters().get('txt');
  }//  public string getTextBox() 

}//END OF CLASS