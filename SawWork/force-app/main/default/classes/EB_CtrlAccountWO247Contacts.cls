/*
############################################################################
Authors: Satish & Sharath K
Description: 1. Controller class that picks all the Accounts that do not have a 24x7 contact
             2. Class is also used to prepare data for Google charts that depict all Accounts without 24x7 conatcts based on
                 Customer Tier and Support Level
Modification Date and modifications done:
             1. 7/12/2013 - Sonia - CR 2286623 CNotify: Filter Inactive Accounts - Adding NOT Account_Status__c  LIKE '% - Inactive'
                condition in all Account queries.
#############################################################################
*/

public class EB_CtrlAccountWO247Contacts {

    

public Integer getPremiumcount() {
    return Premiumcount;
}
public Integer getPrioritycount() {
    return Prioritycount;
}
public Integer getIndirectcount() {
    return Indirectcount;
}
public Integer getOthercount() {
    return Othercount;
}

public Integer getcustomerAACount() {
    return customerAACount ;
}
public Integer getcustomerACount() {
    return customerACount ;
}
public Integer getcustomerBCount() {
    return customerBCount ; 
}
public Integer getcustomerCCount () {
    return customerCCount ;
}
public Integer getcustomerOCount() {
    return customerOCount ;
}
 Integer Premiumcount = 0;
 Integer Prioritycount =0; 
 Integer Indirectcount =0;
 Integer Othercount =0;
 Integer customerAACount =0;
 Integer customerACount =0;
 Integer customerBCount =0;
 Integer customerCCount =0;
 Integer customerOCount =0;
 Integer count1=0; 


//Vineet
//CR 1715647 CNotify: 2012 Jun-2012 List enhancement for Accounts Sans 24X7 Contacts custom report
 /*
    Author: Vineet
    CR: 1715647
    Description: THe Function returns the applied Filter
 */
Integer i=0;
public String getFilterText() {
    String temp='';
    if(AkamAccountId!='' && AkamAccountId!=null)
    {
    temp += ' Account Id = ' + AkamAccountId + ';';
    }
    if(AccountName!='' && AccountName!=null)
    {
    temp += ' Account Name = ' + AccountName + ';';
    }
    if(SupportLevel!='' && SupportLevel!=null)
    {
    temp += ' Support Level = ' + SupportLevel + ';';
    }
    if(CustomerTier!='' && CustomerTier!=null)
    {
    temp += ' Customer Tier = ' + CustomerTier + ';';
    }
    return temp;
    
}

  public String AkamAccountId {get;set;}
  public String AccountName {get;set;}
  public String SupportLevel {get;set;}
  public String CustomerTier {get;set;}
  public Boolean renderDebugBool{get;set;}
// the current sort direction. defaults to asc
  public String sortOrder {
    get  { if (sortOrder == null) {  sortOrder = 'asc'; } return sortOrder;  }
    set;
  }
 
  // the current field to sort by. defaults to last name
  public String sortField {
    get  { if (sortField == null) {sortField = 'name'; } return sortField;  }
    set;
  }
 
  // format the soql for display on the visualforce page
  public String debugSoql {
    get { return stradvsoql; }
    set;
  }
 //CR 2286623 : SQl changed by Sonia - Added condition to filter out Inactive accounts
 //private String stradvsoql ='select id, name, support_level__c, AKAM_Account_ID__c, customer_tier__c from account a where a.Account_Status__c != \'Lead\' limit 1000';
 private String stradvsoql ='select id, name, support_level__c, AKAM_Account_ID__c, customer_tier__c from account a where a.Account_Status__c != \'Lead\' AND (NOT a.Account_Status__c LIKE \'% - Inactive\') limit 1000';

 private List <Account> objAccounts;
 
 private String strLikesearch= '';
 public EB_CtrlAccountWO247Contacts()
{
    
if(EB_UtilApplication.getProperty_DebugSQL() == 'TRUE')
        renderDebugBool=true;
        else
        renderDebugBool=false;
        
        }
/*
    Author: Vineet
    CR: 
    Description: Standard Controller to Add Pagination
 */ 
public ApexPages.StandardSetController objController
{
    get{
        if(objController == null){
            try{
                
                objController = new ApexPages.StandardSetController(Database.getQueryLocator(stradvsoql));
                objController.setPageSize(Integer.valueof(EB_UtilApplication.getProperty('RowsPerPage')));
                
            }
            catch(Exception e){
                ApexPages.Message myMsg;
                myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,'No matching records for without 24/7 Contacts were found ');
                ApexPages.addMessage(myMsg);
                throw e;
            }
        }
        return objController;
    }
    set;
}

public Boolean hasNext {
    get {
    // indicates whether there are more records after the current page set.
        if(objController != null){
            return objController.getHasNext();
        }
        else 
            return null;
    }
    set;
}
 
 
public Boolean hasPrevious {
    get {
       // indicates whether there are more records before the current page set.
       if(objController != null){
            return objController.getHasPrevious();
       }
       else
            return null;
    }
    set;
}

public void first() {
// returns the first page of records
if(objController != null){
    objController.first();
    }
}
 
 public void last() {
    // returns the last page of records
 if(objController != null){
       objController.last();
 }
}
 
public void previous() {
    // returns the previous page of records
 if(objController != null){
       objController.previous();
    }
}
 
public void next() {
    // returns the next page of records  
 if(objController != null){
        objController.next();
    }
} 
  /*
    Author: Vineet
    CR: 1715647
    Description: Generates the List of Accounts For the Print Page(doesnt use any pagination)
 */  
 public List <Account> getAccountsSans24X7ContactsPrint() {
         
        String fields='';
        Integer x;
        List<String> filterFields = new List<String>();
        for (EBCS_CustomReportFilter1__c filter : EBCS_CustomReportFilter1__c.getAll().values()){
            filterFields.add(filter.Filter__c);
        }
             
        for( x=0;x<( filterFields.size()-1);x++){
             fields= fields + '\'' + filterFields.get(x) + '\'' + ' , ';
        }
    fields= fields + '\'' + filterFields.get(x) + '\'' + ' ';  
    //24-Aug-2010 Adding another Filter on Accounts - to remove all Accounts having Status- "Lead"
    //CR 2286623 : SQl changed by Sonia - Added condition to filter out Inactive accounts
    // String soql =  'select id, name, support_level__c, AKAM_Account_ID__c, customer_tier__c from account a where a.Account_Status__c != \'Lead\' AND a.Support_Level__c NOT IN (' + fields + ',\'\'' +  ')  AND a.id in (select accountid from contact where contact_type__c excludes(\'Technical Primary - 24X7\' ,\'Tech Secondary - 24X7\') and accountid !=\'\' ) ' + 
    String soql =  'select id, name, support_level__c, AKAM_Account_ID__c, customer_tier__c from account a where a.Account_Status__c != \'Lead\' AND (NOT a.Account_Status__c LIKE \'% - Inactive\') AND a.Support_Level__c NOT IN (' + fields + ',\'\'' +  ')  AND a.id in (select accountid from contact where contact_type__c excludes(\'Technical Primary - 24X7\' ,\'Tech Secondary - 24X7\') and accountid !=\'\' ) ' + 
     ' AND a.id not in (select accountid from contact where contact_type__c includes(\'Technical Primary - 24X7\', \'Tech Secondary - 24X7\') and accountid != \'\') ' ;
    //System.assertEquals(stradvsoql, 'abc');
    stradvsoql = soql + ' ' + strLikesearch + ' order by ' + sortField + ' ' + sortOrder + ' ' + 'limit 1000'  ;
    objAccounts = new List<Account>();
       try{
                
        for(Account a : Database.query(stradvsoql)){
            objAccounts.add(a);
        } 
         
        }
        catch(QueryException q){
           
        }
        catch(Exception e){
           
        }
   
   
    return objAccounts;
}
    
    public List <Account> getAccountsSans24X7Contacts() {
            String fields='';
            Integer x;
            String soql;
            List<String> filterFields = new List<String>();  
            objController=null;          
        try{
            for (EBCS_CustomReportFilter1__c filter : EBCS_CustomReportFilter1__c.getAll().values()){
                filterFields.add(filter.Filter__c);
            }
                 
            for( x=0;x<( filterFields.size()-1);x++){
                 fields= fields + '\'' + filterFields.get(x) + '\'' + ' , ';
            }
        fields= fields + '\'' + filterFields.get(x) + '\'' + ' ';  
        //24-Aug-2010 Adding another Filter on Accounts - to remove all Accounts having Status- "Lead"
        //CR 2286623 : SQl changed by Sonia - Added condition to filter out Inactive accounts
        //soql =  'select id, name, support_level__c, AKAM_Account_ID__c, customer_tier__c from account a where a.Account_Status__c != \'Lead\' AND a.Support_Level__c NOT IN (' + fields + ',\'\'' +  ')  AND a.id in (select accountid from contact where contact_type__c excludes(\'Technical Primary - 24X7\' ,\'Tech Secondary - 24X7\') and accountid !=\'\' ) ' + 
        soql =  'select id, name, support_level__c, AKAM_Account_ID__c, customer_tier__c from account a where a.Account_Status__c != \'Lead\' AND (NOT a.Account_Status__c LIKE \'% - Inactive\') AND a.Support_Level__c NOT IN (' + fields + ',\'\'' +  ')  AND a.id in (select accountid from contact where contact_type__c excludes(\'Technical Primary - 24X7\' ,\'Tech Secondary - 24X7\') and accountid !=\'\' ) ' + 
         ' AND a.id not in (select accountid from contact where contact_type__c includes(\'Technical Primary - 24X7\', \'Tech Secondary - 24X7\') and accountid != \'\') ' ;
        
        stradvsoql = soql + ' ' + strLikesearch + ' order by ' + sortField + ' ' + sortOrder + ' ' + 'limit 1000'  ;
        //System.assertEquals(stradvsoql,null);
        objAccounts = new List<Account>();
           try{
                    
            for(Account a : (List<Account>)objController.getRecords()){
                objAccounts.add(a);
            } 
             
            }
            catch(QueryException q){
               
            }
            catch(Exception e){
               
            }
       
        for(Account a :objAccounts){
            if (a.support_level__c== 'Premium'){
                Premiumcount++ ;
                continue;
            }
            else if (a.support_level__c== 'Priority'){
                Prioritycount++;
                continue;
            }
            else if (a.support_level__c== 'Indirect_Customer'){
                Indirectcount++;
                continue;
            }
            else{
                Othercount++;
                continue;
            }
        }
        for(Account b :objAccounts){
            if(b.customer_tier__c == 'A+'){
                customerAACount++;
                continue;
            }
            else if(b.customer_tier__c == 'A'){
                customerACount++;
                continue;            
            }      
            if(b.customer_tier__c == 'B'){
                customerBCount++;
                continue;            
            }      
            if(b.customer_tier__c == 'C'){
                customerCCount++;
                continue;
            }      
            else{
                customerOCount++;
                continue;
            }
        }
        
        return objAccounts;
    }
    catch(Exception e){
                ApexPages.Message myMsg;
                myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,e.getMessage());
                ApexPages.addMessage(myMsg);
                throw e;
                return null;
  }

  }
  public String getRedirect()
{
return ('https://' + ApexPages.currentPage().getHeaders().get('Host') + '/apex/EB_VfpAccountWO247Contacts');
}


/*
    Author: Vineet
    CR: 1715647
    Description: Toggling the Sort of Any Field
 */

  public void toggleSortOrder() {
    // simply toggle the direction
    sortOrder = sortOrder.equals('asc') ? 'desc' : 'asc';
    // run the query again
    runQuery();
  }
 /*
    Author: Vineet
    CR: 1715647
    Description: The Funtion which runs the query
 */
    public void runQuery() {
 
    try {
        //Reload the Object Controller
        objController=null;
        getAccountsSans24X7Contacts();
     
    } catch (Exception e) {
      ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, e.getMessage()));
    }
 
  }
 /*
    Author: Vineet
    CR: 1715647
    Description: THis Function is called on CLick of the Apply Filter Button. it builds the Flitler Like CLause
 */
 
  public PageReference applyFilter() {
 
   
    strLikesearch = '';
    if (!AkamAccountId.equals(''))
      strLikesearch += ' and AKAM_Account_ID__c LIKE \''+String.escapeSingleQuotes(AkamAccountId)+'%\'';
    if (!AccountName.equals(''))
      strLikesearch += ' and name LIKE \''+String.escapeSingleQuotes(AccountName)+'%\'';
    if (!SupportLevel.equals(''))
      strLikesearch += ' and Support_Level__c LIKE \''+String.escapeSingleQuotes(SupportLevel)+'%\'';  
    if (!CustomerTier.equals(''))
      strLikesearch += ' and Customer_Tier__c LIKE \''+String.escapeSingleQuotes(CustomerTier)+'%\'';  
 
    // run the query again
    runQuery();
 
    return null;
  }
  /*
    Author: Vineet
    CR: 1715647
    Description: Clear the Filter
 */
 
   public PageReference clearFilter() 
  {
     AkamAccountId=AccountName=SupportLevel=CustomerTier='';
     
     sortField='name';
     sortOrder='asc';
    
     
     applyFilter();
     return null;
  
  }
  /*
    Author: Vineet
    CR: 1715647
    Description: Open The Print Popup
 */
 
    public PageReference printPoupup() {
        return Page.EB_VfpAccountWO247ContactsPopup;
    }
    //End of CR - 1715647
}