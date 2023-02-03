// Modified by ssawhney- CR 2505702 - Service Incident End date nomenclature should be changed to Incident Closed date
// Modified by vkrishna - CR 2070208 - SI: New search option (created by) needed in RF
// Modified by ssawhney - CR 2026918 - RF: SI Remove or redirect around leading zeros in url
public class SI_ServiceIncidentSearch extends SI_PageControllerBase {

  public SI_QueryBuilder myComponentController { get; set; }

  public string UserTImezone  { get {

    return [select TimeZoneSidKey from User where Id = :UserInfo.getUserId()][0].TimeZoneSidKey;
    }
    }
   public String IncidentId { get; set; }
   public String inciName { get; set; }
   
   public Boolean getShowDetails()
   {
        try
        {
           //Start of changes for CR 2026918 by ssawhney
           string query = '';
           list<BMCServiceDesk__Incident__c> lstIncidents;
           
           //Get the Id form the URL
           inciName= ApexPages.CurrentPage().getParameters().get('Id');
           
           if(inciName!=null)
           {
                //First search happens on the Old SI number and then on the new one
                query = 'select Id,Name from BMCServiceDesk__Incident__c where SI_SD_Dashboard_Incident__c like \'%' + inciName + '%\'';
                lstIncidents = Database.query(query);

                if(lstIncidents.size() == 0)
                {
                    query = 'select Id,Name from BMCServiceDesk__Incident__c where Name like \'%' + inciName + '%\'';
                    lstIncidents = Database.query(query);
                }
           }
           else
           {
               //SDSI will only search for the old SI number
               inciName= ApexPages.CurrentPage().getParameters().get('SDSI');
               if(inciName!=null && lstIncidents == null)
               {
                    query = 'select Id,Name from BMCServiceDesk__Incident__c where SI_SD_Dashboard_Incident__c like \'%' + inciName + '%\'';
                    lstIncidents = Database.query(query);
    
               }
               else
               {
                   //SI will only search on the new incident numbers
                   inciName= ApexPages.CurrentPage().getParameters().get('SI');
                   if(inciName!=null && lstIncidents == null)
                   {
                        query = 'select Id,Name from BMCServiceDesk__Incident__c where Name like \'%' + inciName + '%\'';
                        lstIncidents = Database.query(query);
                    }
               }
            }
            
            if(lstIncidents == null || lstIncidents.size() == 0)
            {
                return false;
            }
            else
            {
                //Navigate to the service incident if only one SI is found
                if(lstIncidents.size() == 1)
                    IncidentID = lstIncidents[0].Id;
                return true;
            }
            //End of Changes for CR 2026918 by ssawhney
        }
        catch (exception ex)
        {
            return true;
        }
        return true;
   }
   public String getGetLocation() {
       getShowDetails();
       if(IncidentID!=null)
        return '/'+IncidentID;
        else
        return '';
    }
  public string ListTitle { get { if( ListTitle==null) { ListTitle ='Open Service Incidents'; } return ListTitle;} set; }
  public string UserSalesforceId  { get {

    return UserInfo.getUserId();
    }
    }
    public List<String> getStatusRecords()
    {
        List<String> StatusValues = new List<String>();
        for(BMCServiceDesk__Status__c status:[SELECT Name,Id FROM BMCServiceDesk__Status__c where BMCServiceDesk__inactive__c = false and SI_Applies_to_Service_Incident__c = true order by Name])
        {
        if(!legacyPrefix)
        {
            StatusValues.add(status.Name);
        }
        else
        {
            if(status.Name == 'IN PROGRESS')
            {
                StatusValues.add('1a: IN PROGRESS');
            }
            else if(status.Name == 'ROOT CAUSE DETERMINED')
            {
                 StatusValues.add('1b: ROOT CAUSE DETERMINED');
            }
            else if(status.Name == 'SOLUTION IDENTIFIED')
            {
                 StatusValues.add('1c: SOLUTION IDENTIFIED');
            }
            else if(status.Name == 'IMPACT MITIGATED')
            {
                 StatusValues.add('2: IMPACT MITIGATED');
            }
            else if(status.Name == 'RESOLVED')
            {
                 StatusValues.add('3: RESOLVED');
            }
            else if(status.Name == 'CLOSED')
            {
                 StatusValues.add('CLOSED');
            }
        }

    }
    return StatusValues;
    }
//Todo:
    public String removeLegacyPrefix(String query){


            if(query.containsIgnoreCase('1a: IN PROGRESS'))
            {
               query = query.replaceFirst('(?i)1a: IN PROGRESS','IN PROGRESS');
            }
            if(query.containsIgnoreCase('1b: ROOT CAUSE DETERMINED'))
            {
               query = query.replaceFirst('(?i)1b: ROOT CAUSE DETERMINED','ROOT CAUSE DETERMINED');
            }
            if(query.containsIgnoreCase('1c: SOLUTION IDENTIFIED'))
            {

               query = query.replaceFirst('(?i)1c: SOLUTION IDENTIFIED','SOLUTION IDENTIFIED');
            }
            if(query.containsIgnoreCase('2: IMPACT MITIGATED'))
            {

               query = query.replaceFirst('(?i)2: IMPACT MITIGATED','IMPACT MITIGATED');

            }
            if(query.containsIgnoreCase('3: RESOLVED'))
            {
               query = query.replaceFirst('(?i)3: RESOLVED','RESOLVED');
            }

            return query;

    }
    public Boolean legacyPrefix {get{


     if(legacyPrefix==null) {

     try
        {
        SI_Search__c objApp = SI_Search__c.getInstance('SI_CustomSetting');

        legacyPrefix = Boolean.valueOf(objApp.SI_StatusLegacyPrefix__c);


        }
        catch(Exception e)
        {

            legacyPrefix = true;
        }

     } return legacyPrefix;} set;}

    public EB_FilterObject getsearchFields()
    {
      List<String> StatusValues = getStatusRecords();
      List<String> ImpactValues = new List<String>();
      List<String> CategoryValues = new List<String>();
      List<String> UrgencyValues = new List<String>();

    for(BMCServiceDesk__Impact__c impact:[SELECT Name,Id FROM BMCServiceDesk__Impact__c where SI_Applies_to_Service_Incident__c = true order by Name])
    {
        ImpactValues.add(impact.Name);
    }
    for(BMCServiceDesk__Category__c category:[SELECT Name,Id FROM BMCServiceDesk__Category__c where  SI_Applies_to_Service_Incident__c = true order by Name])
    {
        CategoryValues.add(category.Name);
    }
    for(BMCServiceDesk__Urgency__c urgency:[SELECT Name,Id FROM BMCServiceDesk__Urgency__c where SI_Applies_to_Service_Incident__c = true order by Name])
    {
        UrgencyValues.add(urgency.Name);
    }

  EB_FilterObject searchFields = new EB_FilterObject();
  searchFields.AddField('string','Incident#','Name','True');
  searchFields.AddField('string','Category','BMCServiceDesk__FKCategory__r.Name','False',CategoryValues);
  searchFields.AddField('string','Status (Phase)','BMCServiceDesk__FKStatus__r.Name','True',StatusValues);
  searchFields.AddField('string','Impact (Customer Severity)','BMCServiceDesk__FKImpact__r.Name','True',ImpactValues);
  searchFields.AddField('string','Urgency (Aggregate Severity)','BMCServiceDesk__FKUrgency__r.Name','True',UrgencyValues);
  searchFields.AddField('string','Title','BMCServiceDesk__Service_Request_Title__c','False');
  searchFields.AddField('string','Owner (Technical Incident Manager)','Owner.Name','True');

 // Added by vkrishna for CR 2070208 SI: New search option (created by) needed in RF 
  searchFields.AddField('string','Created By','CreatedBy.Name','True');

  searchFields.AddField('string','GSS Incident Manager / Business Information Lead','SI_GSS_Inc_Manager_BIL__r.Name','True');
  searchFields.AddField('other','Description','BMCServiceDesk__incidentDescription__c','False');
  searchFields.AddField('DateTime','Created Date','CreatedDate','False');
  searchFields.AddField('DateTime','Incident Start','SI_OutageStart__c','False');
  // Modified by ssawhney- CR 2505702 - Service Incident End date nomenclature should be changed to Incident Closed date
  searchFields.AddField('DateTime','Incident Closed','SI_OutageEnd__c','False');
 // searchFields.AddCustomBooleanField('Historical Incidents','( SI_SD_Dashboard_Incident__c=null or SI_SD_Dashboard_Incident__c!=null) ','SI_SD_Dashboard_Incident__c=null ');
  searchFields.AddField('string','SDSI #','SI_SD_Dashboard_Incident__c','True');

 
  return searchFields;
  }

  private Id RecordId {
  get
  {
      if(RecordId==null) {
      try
      {
        RecordId = [SELECT id FROM RecordType where Name ='Service Incident'][0].id;
      }
      catch(Exception e)
      {
          RecordId = '012Z0000000CnI4IAK';
      }
      }
   return RecordId;
  }
  set;
  }
  Public String InputQuery {
    get{

        // Modified by vkrishna - CR 2070208 - SI: New search option (created by) needed in RF - Added CreatedBy.Name field in query
        //added SI_GSS_Inc_Manager_BIL__r.Name field to the query
        return 'select Id,CreatedDate,name,SI_Incident_Link__c, BMCServiceDesk__FKCategory__c, BMCServiceDesk__FKCategory__r.Name, BMCServiceDesk__Service_Request_Title__c, BMCServiceDesk__FKUrgency__c, BMCServiceDesk__FKUrgency__r.Name, BMCServiceDesk__FKImpact__c, BMCServiceDesk__FKImpact__r.Name, BMCServiceDesk__FKStatus__c, BMCServiceDesk__FKStatus__r.Name, SI_OutageStart__c, SI_OutageEnd__c, BMCServiceDesk__incidentDescription__c,Owner.Name, CreatedBy.Name,SI_GSS_Inc_Manager_BIL__r.Name from BMCServiceDesk__Incident__c where RecordTypeID = \'' + RecordId + '\' and BMCServiceDesk__FKStatus__r.Name != \'Closed\'';
     // return 'select Id,CreatedDate,name,SI_Incident_Link__c, BMCServiceDesk__FKCategory__c, BMCServiceDesk__FKCategory__r.Name, BMCServiceDesk__Service_Request_Title__c, BMCServiceDesk__FKUrgency__c, BMCServiceDesk__FKUrgency__r.Name, BMCServiceDesk__FKImpact__c, BMCServiceDesk__FKImpact__r.Name, BMCServiceDesk__FKStatus__c, BMCServiceDesk__FKStatus__r.Name, SI_OutageStart__c, SI_OutageEnd__c, BMCServiceDesk__incidentDescription__c,Owner.Name, SI_GSS_Incident_Manager__c from BMCServiceDesk__Incident__c where RecordTypeID = \'' + RecordId + '\'' ;
    }
 }
 private String DefaultQuery ='select Id,CreatedDate,name,SI_Incident_Link__c, BMCServiceDesk__FKCategory__c, BMCServiceDesk__FKCategory__r.Name, BMCServiceDesk__Service_Request_Title__c, BMCServiceDesk__FKUrgency__c, BMCServiceDesk__FKUrgency__r.Name, BMCServiceDesk__FKImpact__c, BMCServiceDesk__FKImpact__r.Name, BMCServiceDesk__FKStatus__c, BMCServiceDesk__FKStatus__r.Name, SI_OutageStart__c, SI_OutageEnd__c, BMCServiceDesk__incidentDescription__c,Owner.Name,SI_GSS_Inc_Manager_BIL__r.Name from BMCServiceDesk__Incident__c where RecordTypeID = \'' + RecordId + '\' and BMCServiceDesk__FKStatus__r.Name != \'Closed\'';
  public override void setComponentController(SI_ComponentControllerBase compController) {
    myComponentController = (SI_QueryBuilder)compController;
  }

  public override SI_ComponentControllerBase getMyComponentController() {
    return myComponentController;
  }


    public void toggleSortOrder()
  {

        myComponentController.toggleSortOrder();
  }

  // the current field to sort by. defaults to last name
  public String sortField {
    get  { if (sortField == null) {sortField = 'name'; } return sortField;  }
    set
    {

        myComponentController.setSortField(value);
        sortField = value;

    }
  }
  private List <BMCServiceDesk__Incident__c> serviceIncidents;

  private String strLikesearch= '';
  public Boolean DefaultSearch =true;
  private string DescriptionValue ='';
  public string FinalQuery {get{if(FinalQuery==null) { FinalQuery='';} return FinalQuery;}set;}
  private Integer count =0;
  public ApexPages.StandardSetController objController
{
    get{
        if(objController == null){
           try{
                ListTitle ='Service Incidents';
                String Outputquery =myComponentController.OutputQuery;
                system.debug('________________' + OutputQuery);
                Map<String,String> LongTextAreaFields = myComponentController.LongTextAreaFields;
                Boolean SearhAcrossLTA;
                List<String> SplitStringByOrderBy ;
                String temp='( ';
                if(LongTextAreaFields.size()>0)
                {
                    SearhAcrossLTA=true;
                }
                else
                {
                    SearhAcrossLTA = false;
                }
                system.debug('________________' + SearhAcrossLTA);
                system.debug( '________________1' + LongTextAreaFields.keySet());
                if(SearhAcrossLTA)
                {
                    for(BMCServiceDesk__Incident__c a : Database.query(Outputquery)){

                    for(string s: LongTextAreaFields.keySet())
                    {
                        String ltafield =(string)(a.get(s));
                        if(ltafield!=null && ltafield!='')
                        {
                        system.debug( '___looping' + ltafield);
                        string searchString= LongTextAreaFields.get(s);

                        if(searchString!=null||searchString!='')
                        {
                            searchString = searchString.remove('*');
                            system.debug( '___looping' + searchString);
                            if(ltafield.containsIgnoreCase(searchString))
                            {
                            temp = temp + '\'' + a.Id +'\' , ';
                            }
                        }
                        }

                    }

                    }
                    if(temp!='( ')
                    {
                    temp = temp.removeEnd(', ');
                    temp = temp + ' )';
                    system.debug('________________Inside ForLoop'+ temp);
                    SplitStringByOrderBy = Outputquery.split('Order by',0);
                    Outputquery = SplitStringByOrderBy[0] + ' and Id in '+ temp +' Order by ' + SplitStringByOrderBy[1];
                    system.debug('________________Inside ForLoop'+ OutputQuery);
                    }
                    else
                    {
                    SplitStringByOrderBy = Outputquery.split('Order by',0);
                    Outputquery = SplitStringByOrderBy[0] + ' and Id =\'\' Order by ' + SplitStringByOrderBy[1];
                    system.debug('________________Didnt Find any'+ OutputQuery);
                    }
                }
                if(legacyPrefix)
                {
                    FinalQuery =  ProcessQuery(removeLegacyPrefix(Outputquery ));
                    objController = new ApexPages.StandardSetController(Database.getQueryLocator(FinalQuery ));
                }
                else
                {
                    FinalQuery = ProcessQuery(Outputquery );
                    objController = new ApexPages.StandardSetController(Database.getQueryLocator(FinalQuery ));
                }


                SI_Search__c objApp = SI_Search__c.getInstance('SI_CustomSetting');

                Integer rowSize = Integer.valueOf(objApp.Rows_Per_Page__c);

                if(rowSize!=null && rowSize!=0)
                objController.setPageSize(rowSize);
                else
                objController.setPageSize(25);
           }
           catch(Exception e){

                                   system.debug('________________Inside Exception'+ e);
           }
        }
        return objController;
    }
    set;
}

private string ProcessQuery(String query)
{

if(DefaultSearch)
{
return query;
}
return query.remove('and BMCServiceDesk__FKStatus__r.Name != \'Closed\'');
}

public Boolean hasNext {

    get {
    // indicates whether there are more records after the current page set.
        try{
        if(objController != null){
            return objController.getHasNext();
        }
        else
            return null;
           }
        catch(Exception e)
        {
        return null;
        }
    }
    set;
}


public Boolean hasPrevious {
    get {
       // indicates whether there are more records before the current page set.
       try{
       if(objController != null){
            return objController.getHasPrevious();
       }
       else
            return null;
        }
        catch(Exception e)
        {
        return null;
        }
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


    public List <BMCServiceDesk__Incident__c> getServiceIncidents() {

        serviceIncidents= new List<BMCServiceDesk__Incident__c>();
           try{


            for(BMCServiceDesk__Incident__c a : (List<BMCServiceDesk__Incident__c>)objController.getRecords()){

                serviceIncidents.add(a);
            }
            }
            catch(QueryException q){

            }
            catch(Exception e){
            }


        return serviceIncidents;
    }
    public PageReference redirectToNewPage()
    {
     String Prefix =  Schema.Sobjecttype.BMCServiceDesk__Incident__c.getKeyPrefix();

        //PageReference returnURL = new Pagereference ('/'+ Prefix+ '/e?' + 'RecordType='+ '012Z0000000CnI4');
          PageReference returnURL = new Pagereference ('/apex/SI_ServiceIncidentEdit?Incident=New');
       //   PageReference returnURL = new Pagereference('https://akamai--remedydev.cs11.my.salesforce.com/setup/ui/recordtypeselect.jsp?ent=01IG0000001okVe&retURL=%2Fa5U%2Fo&save_new_url=%2Fa5U%2Fe%3FretURL%3D%252Fa5U%252Fo');
     return returnURL ;
    }
    public override void SetObjControllerNull()
    {


    objController=null;
    }
    public override void PostProcessApplySearch()
    {
    objController=null;
    DefaultSearch=false;
    }
    public override void clearSearch()
    {
     objController=null;
     DefaultSearch=true;
    }
    public Boolean getDebugRender()
    {
        try
        {
        SI_Search__c objApp = SI_Search__c.getInstance('SI_CustomSetting');

        Boolean renderRow = Boolean.valueOf(objApp.SI_DebugRender__c);

        return renderRow;
        }
        catch(Exception e)
        {

            return false;
        }
    }


}