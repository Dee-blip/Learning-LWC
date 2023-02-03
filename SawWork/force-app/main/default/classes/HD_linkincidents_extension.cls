public with sharing class HD_linkincidents_extension 
{
   
    private ApexPages.StandardSetController ssc;
    private List<BMCServiceDesk__incident__c> IncidentSet = new List<BMCServiceDesk__incident__c>();
    public String includeSelectListvalue{get;set;}
    public String globalOrder{get;set;}
    public String globalorderCss{get;set;}
    public String columnName{get;set;}
    public Boolean linkButtonVisiblility{get;set;}
    
    //starting pagination logic
    public Integer Incidentviewssize{get;set;}
    public Integer page_number{get;set;}
    public Integer number_of_pages{get;set;}
    public Integer remaining_records{get;set;}
    public Integer Total_records {get;set;}
    public String Search_String{get;set;}
    
    public HD_linkincidents_extension() 
    {
     columnName = 'Name';
     globalOrder = 'DESC';
     globalorderCss = 'glyphicon glyphicon-arrow-down';
     linkButtonVisiblility = parentIncidentLinkageValidation();

     page_number = 1;
     List<BMCServiceDesk__Incident__c> allIncidentsList = Database.query(queryGenerator(columnName,globalOrder));
     if(ssc == null) { ssc = new ApexPages.StandardSetController(allIncidentsList);}
     
     //setting page size as default one
     ssc.setPageSize(30);
     this.Incidentviewssize  = ssc.getPageSize();
     page_number = 1;
     IncidentSet = (List<BMCServiceDesk__Incident__c>)ssc.getRecords();
     system.debug(+ssc.getPageSize()+'-- INCI LIST --> '+IncidentSet.size());
     number_of_pages = (ssc.getResultSize()/Incidentviewssize);
     remaining_records = MATH.mod(ssc.getResultSize(),Incidentviewssize);
     system.debug('-->'+remaining_records);
     if(remaining_records > 0 )
     {
        number_of_pages = number_of_pages +1 ;
     }
     Total_records = ssc.getResultSize();
     system.debug('-->'+number_of_pages);
     number_of_pages = number_of_pages;
     //initializing Search String
     Search_String = '';

     if( linkButtonVisiblility == false)
     {
        ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.WARNING,' This Incident is already a child incident of another incident or service request');
        ApexPages.addMessage(myMsg);
     }

     
    }//
    
    
    public List<BMCServiceDesk__incident__c> getIncidenttoLink()
    {
     List<BMCServiceDesk__Incident__c> srmrecords = new List<BMCServiceDesk__Incident__c>();
              
     //setting up required page parameter
     ssc.setpageSize(Incidentviewssize);
     ssc.setPageNumber(page_number);
     this.Incidentviewssize = ssc.getPageSize();     
    system.debug('-- Result Size -->'+ssc.getResultSize()+' -- Page Size--> '+ssc.getPageSize()+'--Number of pages--->' +number_of_pages+'-- HasNext -->'+ssc.getHasNext()+' - PageNumber -> '+ssc.getPageNumber());
    system.debug('--record Size--> '+Incidentviewssize+' -- Search string---->'+Search_String);
     for( BMCServiceDesk__Incident__c Increcord: (List<BMCServiceDesk__Incident__c>) ssc.getRecords() )
    {
    if(includeSelectListvalue == 'CLOSED')
    { 
       if( Increcord.BMCServiceDesk__Status_ID__c == 'CLOSED')
       {
                 srmrecords.add(Increcord);
       }
    }
    else
    {
          srmrecords.add(Increcord);
    }


    }//for( BMCServiceDesk__Incident__c srmrecord = List<BMCServiceDesk__Incident__c>)srmObject.getRecords() ) 
    
    if(globalOrder =='ASC'){srmrecords.sort();}
    
     // for general display threough Views 
     Total_records = ssc.getResultSize();
     
     //pagination
     Total_records = ssc.getResultSize();
     number_of_pages = (ssc.getResultSize()/Incidentviewssize);
     remaining_records = MATH.mod(ssc.getResultSize(),Incidentviewssize);
     system.debug('-->'+remaining_records);
     if(remaining_records > 0 )
     {
        number_of_pages = number_of_pages +1 ;
     }
     number_of_pages = number_of_pages;
     Total_records = ssc.getResultSize();
     
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
    fsetq+=' WHERE BMCServiceDesk__Type__c = \'Incident\'';
    if(!String.isEmpty(includeSelectListvalue))
    {
    fsetq+=' AND BMCServiceDesk__Status_ID__c =\''+includeSelectListvalue+'\'';
    }
    fsetq+=' ) LIMIT '+Incidentviewssize;    
    List<List<BMCServiceDesk__Incident__c>> searchResultList = search.query(fsetq);
    srmrecords.clear();
    srmrecords.addAll(searchResultList[0]);
    //setting records if the search is enabled
    Total_records = srmrecords.size();
    }//if
    


//Calculating the page numbers
         if(srmrecords.size() < Incidentviewssize )
         {
                  number_of_pages = 0;
         }
         number_of_pages = (ssc.getResultSize()/Incidentviewssize);
         remaining_records = MATH.mod(ssc.getResultSize(),Incidentviewssize);
         if(remaining_records > 0 )
     {
        number_of_pages = number_of_pages +1 ;
     }
    /* else
     {
     number_of_pages = 1;
     }*/
         
     system.debug('-- SHOWING --> '+srmrecords.size()+'-- OF --> '+IncidentSet.size()+'-- REMAINING RECORDS --> '+remaining_records);
     
        
    return srmrecords;      
    }//public List<BMCServiceDesk__incident__c> getIncidenttoLink()
    
    
    
    
    private String queryGenerator(String orderby,String order)
    {
     String query = 'Select ';
            query+= 'Id ';
            query+= ',Name';
            query+= ',BMCServiceDesk__Status_ID__c';
            query+= ',BMCServiceDesk__FKIncident__c';
            query+= ',BMCServiceDesk__Type__c';            
            
            
            
            query+= ' FROM BMCServiceDesk__Incident__c ';
            query+= ' Where BMCServiceDesk__FKIncident__c <> \''+ApexPages.currentPage().getParameters().get('id')+'\'';
            query+= ' AND BMCServiceDesk__FKIncident__c = \'\'';
            query+= ' AND Id <> \''+ApexPages.currentPage().getParameters().get('id')+'\'';
            if(!String.isEmpty(includeSelectListvalue))
            {
             query+= ' AND BMCServiceDesk__Status_ID__c =\''+includeSelectListvalue+'\'';
            }
            query+= ' ORDER BY '+orderby+' '+order;
            query+= ' LIMIT 10000';
            
            system.debug('Query --->'+query);
    
      return query;
    }
    
    public List<SelectOption> getIncludes() {
            List<SelectOption> options = new List<SelectOption>();
            options.add(new SelectOption('','Open Item'));
            options.add(new SelectOption('CLOSED','Closed Item'));
            return options;
        }
        
   public void columnOrder()
   {
   if( globalOrder == 'ASC')
   {   
   globalOrder = 'DESC';
   globalorderCss = 'glyphicon glyphicon-arrow-down';
   }
   else
   {
       globalOrder = 'ASC';
       globalorderCss = 'glyphicon glyphicon-arrow-up';
   }
   }// 
   
   //public Next button
   public void nextbutton()
  {
   if(ssc.getHasNext())
    {
     page_number = ssc.getPageNumber() +1 ;
     ssc.setPageNumber(page_number);
    }
  }//public void nextbutton()
  
  //public Previous button
  public void previousbutton()
   {
    if(ssc.getHasPrevious())
    {
    page_number = ssc.getPageNumber() - 1 ;
    ssc.setPageNumber(page_number);
    }
   }//public void previousbutton()     
   
  public void searchResult()
   {
    String fsetq = 'FIND \''+Search_String+'*\' IN ALL FIELDS RETURNING BMCServiceDesk__Incident__c (id,name';
    List<Schema.FieldSetMember> filesset1 = SObjectType.BMCServiceDesk__Incident__c.FieldSets.HD_Service_Request_table_column.getFields();
    /*
    for(Schema.FieldSetMember fsm : filesset1 )
    {
        System.debug('Field : '+fsm.getfieldpath());
        fsetq+=','+fsm.getfieldpath();
    }
    */
    fsetq+=' WHERE BMCServiceDesk__Type__c = \'Incident\' ) LIMIT '+Incidentviewssize;
    List<List<BMCServiceDesk__Incident__c>> searchResultList = search.query(fsetq);
    ssc = new ApexPages.StandardSetController(searchResultList[0]);
    IncidentSet = (List<BMCServiceDesk__Incident__c>)ssc.getRecords();
    Total_records = ssc.getResultSize();

    }// 
    
    //empty search string
   public void emptySearchString()
   {
     Search_String = '';
   }//public void emptySearchString()   

   //THis function is used for validating single level hierarchy of linkage
   public Boolean parentIncidentLinkageValidation()
   {
    Boolean enabledLinkButton = true;
    //creating 
     for ( BMCServiceDesk__Incident__c inc : [Select Id,Name,BMCServiceDesk__FKIncident__c from BMCServiceDesk__Incident__c Where id =: ApexPages.currentPage().getParameters().get('id') LIMIT 1] )
     {
        if( inc.BMCServiceDesk__FKIncident__c != null)
        {
            enabledLinkButton = false;

        }

     }

    return enabledLinkButton;
   }   

}//END of Class