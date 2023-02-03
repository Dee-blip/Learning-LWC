/*
Template: Apex Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : used as apart of requirment for SRM Console

Purpose : an implementation for SRM Console Controller
          
Usage : used as an implementation for the business logic , for SRM Console
          
Test Class Asssociated : HD_Test_Problem_Customization_tri

Controller (Boolean): true

Page Used/Asssociated (default -> NONE) : ServiceRequest

Class Associated : NONE
              
*/
public without sharing class HD_SRM_ServiceRequest_Extension {

        public String FilterId{get;set;}
        public List<BMCServiceDesk__Incident__c> srmListset{get;set;}
        public Integer srmviewssize{get;set;}
        public Integer number_of_pages{get;set;}
        public Integer remaining_records{get;set;}
        public Integer page_number{get;set;}
        public boolean pageblockdisplayflag{get;set;}
        public Map<String,String> ListviewMapping{get;set;}
        public Integer Total_records {get;set;}
        public String Search_String{get;set;}
                
        //private static String q =  'SELECT Id, Name, BMCServiceDesk__Type__c, HD_Parent_Tree__c, BMCServiceDesk__Category_ID__c, BMCServiceDesk__Priority_ID__c, BMCServiceDesk__shortDescription__c, BMCServiceDesk__clientId__c, HD_Owner_user_queue__c, BMCServiceDesk__openDateTime__c, BMCServiceDesk__Status_ID__c, BMCServiceDesk__Due_Date_Progress__c, HD_Queue_name__c  FROM BMCServiceDesk__Incident__c where BMCServiceDesk__Type__c = \'Service Request\' ORDER BY BMCServiceDesk__openDateTime__c DESC';
         private String q{get{return queryGenerator();}}
        /*
        public ApexPages.StandardSetController srmObject{
        get{ if (srmObject == null) { srmObject = new ApexPages.StandardSetController(Database.getQueryLocator(q));} return srmObject;  }
        set;}
        */
        
    public ApexPages.StandardSetController srmObject{get;set;}
        
    // The extension constructor initializes the private member
    // variable mysObject by using the getRecord method from the standard
    // controller.
    public HD_SRM_ServiceRequest_Extension() 
    {
     if(srmObject == null) { srmObject = new ApexPages.StandardSetController(Database.getQueryLocator(q));}
     //setting page size as default one
     srmObject.setPageSize(40);
     this.srmviewssize  = srmObject.getPageSize();
     page_number = 1;
     srmListset = (List<BMCServiceDesk__Incident__c>)srmObject.getRecords();
     system.debug(+srmObject.getPageSize()+'-- SRMLIST --> '+srmListset.size());
     number_of_pages = (srmObject.getResultSize()/srmObject.getPageSize());
     remaining_records = MATH.mod(srmObject.getResultSize(),srmviewssize);
     system.debug('-->'+remaining_records);
     if(remaining_records > 0 )
     {
        number_of_pages = number_of_pages +1 ;
     }
     Total_records = srmObject.getResultSize();
     system.debug('-->'+number_of_pages);
     //initializing Search String
     Search_String = '';
    }//
    
    //Dynamic Query Generator using filed set
    private String queryGenerator()
    {
    String fsetq = 'Select id,name';
    List<Schema.FieldSetMember> filesset1 = SObjectType.BMCServiceDesk__Incident__c.FieldSets.HD_Service_Request_table_column.getFields();
    for(Schema.FieldSetMember fsm : filesset1 )
    {
        System.debug('Field : '+fsm.getfieldpath());
        fsetq+=','+fsm.getfieldpath();
    }
    fsetq+=' from BMCServiceDesk__Incident__c where BMCServiceDesk__Type__c = \'Service Request\' ORDER BY BMCServiceDesk__openDateTime__c DESC LIMIT 9990';
    return fsetq;
    }//

    
    //getting SRM Records Only
    public List<BMCServiceDesk__Incident__c> getSrmList()
    {
     List<BMCServiceDesk__Incident__c> srmrecords = new List<BMCServiceDesk__Incident__c>();

    //filterId = '00BG0000006i5gYMAQ';
    
    srmObject.setFilterID(FilterId); 
    srmObject.setpageSize(srmviewssize);
    srmObject.setPageNumber(page_number);
    
    system.debug('-- Result Size -->'+srmObject.getResultSize()+' -- Page Size--> '+srmObject.getPageSize() +'-- HasNext -->'+srmObject.getHasNext()+' - PageNumber -> '+srmObject.getPageNumber());
    system.debug('--record Size--> '+srmviewssize+'-- FilterId -->'+FilterId+' -- Search string---->'+Search_String);



    for( BMCServiceDesk__Incident__c srmrecord: (List<BMCServiceDesk__Incident__c>) srmObject.getRecords() )
    {
      if( srmrecord.BMCServiceDesk__Type__c == 'Service Request')
      {
      srmrecords.add(srmrecord);
      }//if
    }//for( BMCServiceDesk__Incident__c srmrecord = List<BMCServiceDesk__Incident__c>)srmObject.getRecords() ) 
     // for general display threough Views 
     Total_records = srmObject.getResultSize();
      
   //using regex to identify the space pattern
    Pattern spacepattern = Pattern.compile('^(\\s)*$');
    Matcher spaceMatcher = spacepattern.matcher(Search_String);
    if(spaceMatcher.matches() == true)
    {
    Search_String = '';
    }
    //END of space 
  
//Logic to enable trigger search
    if( Search_String != null && Search_String.length() > 1 )
    {
    //preparing search string
    String fsetq = 'FIND \''+Search_String+'*\' IN ALL FIELDS RETURNING BMCServiceDesk__Incident__c (id,name';
    List<Schema.FieldSetMember> filesset1 = SObjectType.BMCServiceDesk__Incident__c.FieldSets.HD_Service_Request_table_column.getFields();
    for(Schema.FieldSetMember fsm : filesset1 )
    {
        System.debug('Field : '+fsm.getfieldpath());
        fsetq+=','+fsm.getfieldpath();
    }
    fsetq+=' WHERE BMCServiceDesk__Type__c = \'Service Request\')';
    List<List<BMCServiceDesk__Incident__c>> searchResultList = search.query(fsetq);
    srmrecords.clear();
    srmrecords.addAll(searchResultList[0]);
    //setting records if the search is enabled
    Total_records = srmrecords.size();
    }//if
    


//Calculating the page numbers
         if(srmrecords.size() < srmviewssize )
         {
                  number_of_pages = 0;
         }
         number_of_pages = (srmObject.getResultSize()/srmObject.getPageSize());
         remaining_records = MATH.mod(srmObject.getResultSize(),srmviewssize);
         if(remaining_records > 0 )
     {
        number_of_pages = number_of_pages +1 ;
     }
     else
     {
     number_of_pages = 1;
     }
         
     system.debug('-- SHOWING --> '+srmrecords.size()+'-- OF --> '+srmListset.size()+'-- REMAINING RECORDS --> '+remaining_records);
    
    return srmrecords;
    }//


    
//public Next button
public void nextbutton()
{
if(srmObject.getHasNext())
{
page_number = srmObject.getPageNumber() +1 ;
srmObject.setPageNumber(page_number);
}
}//public void nextbutton()

//public Previous button
public void previousbutton()
{
if(srmObject.getHasPrevious())
{
page_number = srmObject.getPageNumber() - 1 ;
srmObject.setPageNumber(page_number);
}
}//public void previousbutton()
    
  //function Use to refresh the record in the page
    public void refreshButton(){
    srmObject = new ApexPages.StandardSetController(Database.getQueryLocator(q));
    srmListset = (List<BMCServiceDesk__Incident__c>)srmObject.getRecords();
    Total_records = srmObject.getResultSize();

    }
    
     //getting ListView ids for Incident Object
    public List<SelectOption> getIncidentListViews()
    {   
        List<SelectOption> ListViews = srmObject.getListViewOptions();
        Map<String,String> ListViewMapUnsorted = new Map<String,String>();
        List<String> ListViewUnsorted = new List<String>(); 
        List<SelectOption> sortedOptions = new List<SelectOption>();

        for( SelectOption listvw : ListViews )
        {

            if(String.valueOf(listvw.getLabel()).startsWithIgnoreCase('SRM'))
            {
           //System.debug( 'LABEL -->'+listvw.getLabel()+' Value --> '+listvw.getValue() );
           ListViewMapUnsorted.put(listvw.getLabel(), listvw.getValue());
             }
        }//for( SelectOption listvw : ListViews )
         //getting all keyset values and sorting it 
         ListViewUnsorted.addAll(ListViewMapUnsorted.keySet());
         ListViewUnsorted.sort();
         for(String viewName : ListViewUnsorted )
         {
            system.debug('Sorted Order --->'+viewName);
            sortedOptions.add(new SelectOption(ListViewMapUnsorted.get(viewName),viewName));
         }
     return sortedOptions;
      
    }//public Map<String,String> getIncidentListViews()


public void searchResult()
{
    String fsetq = 'FIND \''+Search_String+'*\' IN ALL FIELDS RETURNING BMCServiceDesk__Incident__c (id,name';
    List<Schema.FieldSetMember> filesset1 = SObjectType.BMCServiceDesk__Incident__c.FieldSets.HD_Service_Request_table_column.getFields();
    for(Schema.FieldSetMember fsm : filesset1 )
    {
        System.debug('Field : '+fsm.getfieldpath());
        fsetq+=','+fsm.getfieldpath();
    }
    fsetq+=' WHERE BMCServiceDesk__Type__c = \'Service Request\' LIMIT '+srmviewssize+' )';
    List<List<BMCServiceDesk__Incident__c>> searchResultList = search.query(fsetq);
    srmObject = new ApexPages.StandardSetController(searchResultList[0]);
    srmListset = (List<BMCServiceDesk__Incident__c>)srmObject.getRecords();
    Total_records = srmObject.getResultSize();

}//

//reset the page conter for pagination
public void reset()
{
    page_number = 1;
}//

//empty search string
public void emptySearchString()
{
  Search_String = '';
}//public void emptySearchString() 


}//End OF CLASS