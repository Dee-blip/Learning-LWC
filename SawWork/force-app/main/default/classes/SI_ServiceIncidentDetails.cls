/*
CR - 2049598, Author Vineet,  We need to suppress validation rules for select fields for the historical service Incidents
Changed by janantha on 15/01/2013 for CR 2018683
Changed by ssawhney on 28/08/2013 for CR 2308403 - default Incident start time to SI record creation time
Modified by ssawhney on 25/03/2013 for CR 2053414 - Root cause and Incident caused by should be mandatory at the time of Phase 3
Modified by ssawhney on 20/06/2013 for CR 2031706 - SI: Add a section for customer facing notification/advisory
Modified by Himanshu on 22-Sep-14  for CR 2375247 - Add Hour Field on the Query
Modified by Aditya on 19-11-2014 for CR 2628246 - SI : Add a picklist field How_was_the_Issue_Detected__c
Modified by Himanshu on 26-Nov-14  for CR 2856324 - Modified Splitstring which displays Incident History Note field
Modified By Jay on 19-feb-2015 for CR 2627751 and CR  2824410 , added logic to calculate time spent on incident by owner and total time
Modified By Aditya on 14-Aug-15 for CR 3110191 to get Tier Count on SI Page
Modified by Vamsee on 30-Nov-15 for CR 3150211 & 3222671- Adding Business Unit Category and Etherpad link on SI Page
Modified by Vamsee on 30-Aug-16 for CR 3469801 - Adding Executive Summary
Modified by Pinkesh on 22-Oct-2018 for ESESP-780 - Made Etherpad field editable
Modified by Pinkesh on 22-Oct-2018 for ESESP-410 - Changed Type Of Customer Impact to multi Select picklist
Modified by Pinkesh on 22-Oct-2018 for ESESP-505 - Auto populate Incident Start Time while creation if Status = IN PROGRESS
Modified by Himanshu on 07-Aug-2019 for ESESP-2528 - Changed User Query in SendMail method
Modified by Sheena on 01-march-2020 for ESESP-1767 - Added Pre-incident Status Value for Users with Cost Center 10470 and Incident Declared Date/Time field
*/
public class SI_ServiceIncidentDetails {
    /*Start of changes by janantha for Email integration*/
    public boolean displayPopup {get; set;}
    public List<Wrapper> wrappers{get;set;}
    public Wrapper wrapper{get;set;} 
    /*End of changes by janantha for Email integration*/
    
    public String messageColor{ get{ if ( messageColor== null) {  messageColor ='red'; } return messageColor; } set;}
    public string newLocation { get; set; }
    public string UserTImezone  { get {
        return [select TimeZoneSidKey from User where Id = :UserInfo.getUserId()][0].TimeZoneSidKey;
    }
                                }
    public string UserSalesforceId  { get {
        return UserInfo.getUserId();
    }
                                    }
    private String siCat ;
    public String Category { get { return siCat;} set;}
    private String siSta;
    public String Status { get { return siSta;} set;}
    private String siImp;
    public String Impact { get { return siImp;}set;}
    private String siUrg;
    public String Urgency { get { return siUrg;}set;}
    
    public String errorMessage { get { if(errorMessage==null) { errorMessage=''; } return errorMessage;  } set; }
    public String ProcessingMessage { get { if(ProcessingMessage==null) { ProcessingMessage='Processing'; } return ProcessingMessage;  } set; }
    private String PageParameterIncident='';
    public void setPageParameter(String parameter)
    {
        PageParameterIncident = parameter;
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
    //Variable to store rendered value for Total Tier Count field
    public Boolean TierRender { get; set; }
    public Boolean NewPageRenders { get; set; }
    public Boolean HistoricalIncident { get { if( HistoricalIncident == null ) { HistoricalIncident = false; } return HistoricalIncident;} set; }
    private BMCServiceDesk__Incident__c standardObj;
    public Boolean OwnerRender { get { if(OwnerRender==null) { OwnerRender = false;} return OwnerRender;} set;}
    private ApexPages.StandardController controller {get; set;}
    public BMCServiceDesk__Incident__c ServiceIncident{get;set;}
    public Map<String,List<SI_ServiceIncidentContacts__c>> ServiceContacts { get{ if( ServiceContacts == null ) { ServiceContacts = new Map<String,List<SI_ServiceIncidentContacts__c>>(); } return ServiceContacts; } set; }
    public List<SI_RootCause__c> rootCauses {get { if(rootCauses == null) {rootCauses = new List<SI_RootCause__c>(); } return rootCauses; } set; }
    public List<SI_ServiceIncidentImpactedCustomers__c> AssociatedAccounts {get { if(AssociatedAccounts == null) {AssociatedAccounts = new List<SI_ServiceIncidentImpactedCustomers__c>(); } return AssociatedAccounts; } set; }
    public List<SI_ServiceIncidentImpactedProducts__c> AssociatedProducts {get { if(AssociatedProducts == null) {AssociatedProducts = new List<SI_ServiceIncidentImpactedProducts__c>(); } return AssociatedProducts; } set; }
    //public List<BMCServiceDesk__Status__c> StatusValues { get { if(StatusValues==null) { StatusValues = new List<BMCServiceDesk__Status__c>(); } return StatusValues; } set; }
    public List<SelectOption> UrgencyValues { get { if(UrgencyValues==null) { UrgencyValues = new List<SelectOption>(); } return UrgencyValues; } set;}
    public List<SelectOption> StatusValues { get { if(StatusValues==null) { StatusValues = new List<SelectOption>(); } return StatusValues; } set;}
    public List<SelectOption> ImpactValues { get { if(ImpactValues==null) { ImpactValues = new List<SelectOption>(); } return ImpactValues; } set;}
    public List<SelectOption> CategoryValues { get { if(CategoryValues==null) { CategoryValues = new List<SelectOption>(); } return CategoryValues; } set;}
    public List<SelectOption> IncidentOriginOptions { get ; set;}
    public List<SI_ServiceIncidentContacts__c> ServiceContactList { get { if(ServiceContactList==null) { ServiceContactList = new List<SI_ServiceIncidentContacts__c>(); } return ServiceContactList;} set; }
    public String PageURL='';
    private id StatusInProgressId;
    public string totalTimeSpent{get;set;}
    public SI_ServiceIncidentDetails(ApexPages.StandardController controller) {
        //displayPopup = false;
        this.controller = controller;
        standardObj = (BMCServiceDesk__Incident__c)controller.getRecord();
        init();
    }
    /*Aditya CR 2628246 : Assigning Picklist Values to field How was the Issue Detected */
    Public List<SelectOption> getIncidentOrigin(){
        IncidentOriginOptions = new List<SelectOption>();
        IncidentOriginOptions.add(new SelectOption('', ' '));
        
        //Fetching picklist values from field "How was the Issue Detected
        List<Schema.PicklistEntry> IssueDetectedPicklist = BMCServiceDesk__Incident__c.How_was_the_Issue_Detected__c.getDescribe().getPicklistValues();
        
        for(Schema.PicklistEntry IssueDetectedValues : IssueDetectedPicklist){
            
            //adding the picklist values to the VF Page
            IncidentOriginOptions.add(new SelectOption(IssueDetectedValues.getLabel(), IssueDetectedValues.getValue()));
        }
        
        return IncidentOriginOptions;
    }
    public static List<SelectOption> sortOptionList(List<SelectOption> ListToSort)  {
        
        if(ListToSort == null || ListToSort.size() <= 1) {
            return ListToSort;                
        }
        
        List<SelectOption> Less = new List<SelectOption>();   
        List<SelectOption> Greater = new List<SelectOption>();
        
        integer pivot = 0;            
        // save the pivot and remove it from the list     
        SelectOption pivotValue = ListToSort[pivot];  
        ListToSort.remove(pivot);
        for(SelectOption x : ListToSort) {        
            if(x.getLabel().compareTo(pivotValue.getLabel()) <= 0) {
                Less.add(x);
            } else if(x.getLabel().compareTo(pivotValue.getLabel()) > 0) {
                Greater.add(x);
            } 
        }     
        List<SelectOption> returnList = new List<SelectOption> ();    
        returnList.addAll(SortOptionList(Less));
        returnList.add(pivotValue);
        returnList.addAll(SortOptionList(Greater));
        
        return returnList;
    }
    public List<SelectOption> getStatusRecords()
    {
       User currentUser = [Select id, Cost_Center__c from User where id =: userinfo.getuserId()];
        StatusValues = new List<SelectOption>();
       List<SelectOption> finalStatusValues = new List<SelectOption>();
        
       // StatusValues.add(new SelectOption('',' '));
        for(BMCServiceDesk__Status__c status:[SELECT Name,Id FROM BMCServiceDesk__Status__c where BMCServiceDesk__inactive__c = false and SI_Applies_to_Service_Incident__c = true order by Name])
        {
            if(!legacyPrefix)
            {
                StatusValues.add(new SelectOption(status.Id,status.Name));
            }
            else
            {
                // Changes for ESESP-1767 : Added Pre-incident Status Value for Users with Cost Center 10470
                if(status.Name == 'PRE-INCIDENT' && currentUser.Cost_Center__c == 10470)
                {
                    finalStatusValues.add(new SelectOption(status.Id,'PRE-INCIDENT'));          
                }
                // Changes End
               else if(status.Name == 'IN PROGRESS')
                {
                    StatusValues.add(new SelectOption(status.Id,'1a: IN PROGRESS'));          
                }
                else if(status.Name == 'ROOT CAUSE DETERMINED')
                {
                    StatusValues.add(new SelectOption(status.Id,'1b: ROOT CAUSE DETERMINED'));          
                }
                else if(status.Name == 'SOLUTION IDENTIFIED')
                {
                    StatusValues.add(new SelectOption(status.Id,'1c: SOLUTION IDENTIFIED'));          
                }
                else if(status.Name == 'IMPACT MITIGATED')
                {
                    StatusValues.add(new SelectOption(status.Id,'2: IMPACT MITIGATED'));             
                }
                else if(status.Name == 'RESOLVED')
                {
                    StatusValues.add(new SelectOption(status.Id,'3: RESOLVED'));          
                }
               
                else if(status.Name == 'CLOSED')
                {
                    StatusValues.add(new SelectOption(status.Id,'CLOSED'));          
                }
                else if(status.Name == 'CANCELED')
                {
                    StatusValues.add(new SelectOption(status.Id,'CANCELED'));           
                }
                
            }
            
        }  
        // Changes for ESESP-1767 : Added Pre-incident Status Value for Users with Cost Center 10470
        finalStatusValues.addAll(sortOptionList(StatusValues));

        return finalStatusValues;
        // Changes End

    }
    //Todo:
    public String LegacyStatusName{
        get
        {
            if(legacyPrefix)
            {
                if(ServiceIncident!=null)
                {
                    if(ServiceIncident.BMCServiceDesk__FKStatus__r.Name == 'PRE-INCIDENT')
                    {
                        return 'PRE-INCIDENT';          
                    }
                    else if(ServiceIncident.BMCServiceDesk__FKStatus__r.Name == 'IN PROGRESS')
                    {
                        return '1a: IN PROGRESS';          
                    }
                    else if(ServiceIncident.BMCServiceDesk__FKStatus__r.Name == 'ROOT CAUSE DETERMINED')
                    {
                        return '1b: ROOT CAUSE DETERMINED';          
                    }
                    else if(ServiceIncident.BMCServiceDesk__FKStatus__r.Name == 'SOLUTION IDENTIFIED')
                    {
                        return '1c: SOLUTION IDENTIFIED';           
                    }
                    else if(ServiceIncident.BMCServiceDesk__FKStatus__r.Name == 'IMPACT MITIGATED')
                    {
                        return '2: IMPACT MITIGATED';             
                    }
                    else if(ServiceIncident.BMCServiceDesk__FKStatus__r.Name == 'RESOLVED')
                    {
                        return '3: RESOLVED';          
                    }
                    
                    else if(ServiceIncident.BMCServiceDesk__FKStatus__r.Name == 'CLOSED')
                    {
                        return 'CLOSED';          
                    }
                    else if(ServiceIncident.BMCServiceDesk__FKStatus__r.Name == 'CANCELED')
                    {
                        return 'CANCELED';          
                    }
                    else
                    {
                        return '';
                    }
                }
                else
                {
                    return ' '; 
                }
                
                
            }
            else
            {
                return ServiceIncident.BMCServiceDesk__FKStatus__r.Name;
            }
        }
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
            
        } return legacyPrefix;
    } set;}
    
    
    public void init()
    {
        
        
        ImpactValues = new List<SelectOption>();
        CategoryValues = new List<SelectOption>();
        UrgencyValues = new List<SelectOption>();
        
        StatusValues = getStatusRecords();
        

        ImpactValues.add(new SelectOption('',' '));
        for(BMCServiceDesk__Impact__c impact:[SELECT Name,Id FROM BMCServiceDesk__Impact__c where BMCServiceDesk__inactive__c = false and SI_Applies_to_Service_Incident__c = true order by Name])
        {
            ImpactValues.add(new SelectOption(impact.Id,impact.Name));
        }  
        UrgencyValues.add(new SelectOption('',' '));
        for(BMCServiceDesk__Urgency__c urgency:[SELECT Name,Id FROM BMCServiceDesk__Urgency__c where BMCServiceDesk__inactive__c = false and SI_Applies_to_Service_Incident__c = true order by Name])
        {
            UrgencyValues.add(new SelectOption(urgency.Id,urgency.Name));
        }
        for(BMCServiceDesk__Status__c status:[SELECT Name,Id FROM BMCServiceDesk__Status__c where BMCServiceDesk__inactive__c = false and SI_Applies_to_Service_Incident__c = true and name = 'IN PROGRESS' order by Name])
        {
            StatusInProgressId = status.id;
        }
        
        if(ApexPages.CurrentPage()!=null)
        {
            PageParameterIncident= ApexPages.CurrentPage().getParameters().get('Incident');
            PageUrl=ApexPages.CurrentPage().getURL();
            
        }
        if(PageParameterIncident==null || PageParameterIncident=='' && standardObj!=null )
        {
            try{          
                BMCServiceDesk__Incident__c currentReferencedRecord  = [ select Name,ownerid,id from BMCServiceDesk__Incident__c where Id = :standardObj.Id limit 1 ];
                PageParameterIncident = currentReferencedRecord.name ;
                //select sum(activeduration__C) from Service_Incident_age_by_status__c where incident__C = :standardObj.Id
                AggregateResult[] groupedResults = [select sum(activeduration__C) aver from Service_Incident_age_by_status__c where incident__C = :currentReferencedRecord.Id];
                double dec = double.valueOf(groupedResults[0].get('aver'));
                totalTimeSpent = convertMS(dec);
            }
            catch (Exception ex)
            {
                
            }
        }
        if(PageParameterIncident=='new')
        {
            ServiceIncident = new BMCServiceDesk__Incident__c();
            ServiceIncident.RecordTypeId = RecordId ;
            try
            {
                // Changes for ESESP-1767 : Added deafault PRE-INCIDENT Status Value for Users with Cost Center 10470
                ServiceIncident.BMCServiceDesk__FKStatus__c= [select Id from BMCServiceDesk__Status__c where Name ='PRE-INCIDENT'][0].Id;
                // Changes End
            }
            catch(Exception ex)
            {
            }
        }
        else
        {
            ServiceIncident = getIncident();
            if(ServiceIncident !=null)
            {
                if(String.isBlank(ServiceIncident.SI_SD_Dashboard_Incident__c))
                    HistoricalIncident = false;          
                else
                    HistoricalIncident = true;
            }
            else
                HistoricalIncident = false;                     
        }
        
        CategoryValues.add(new SelectOption('',' '));
        for(BMCServiceDesk__Category__c category:[SELECT Name,Id FROM BMCServiceDesk__Category__c where BMCServiceDesk__inactive__c = false and SI_Applies_to_Service_Incident__c = true order by Name])
        {
            if(HistoricalIncident)
            {
                if(!(category.Name == 'Unknown' || category.Name == 'Logs/Billing'))
                {
                    CategoryValues.add(new SelectOption(category.Id,category.Name));  
                }
            }
            else
                CategoryValues.add(new SelectOption(category.Id,category.Name));
        }
        
        if(PageParameterIncident=='New')
        {
            NewPageRenders = false;
        }
        else
        {
            NewPageRenders = true;
        }
        if(ServiceIncident!=null)
        {
            siSta = ServiceIncident.BMCServiceDesk__FKStatus__c;
            siCat = ServiceIncident.BMCServiceDesk__FKCategory__c;
            siImp = ServiceIncident.BMCServiceDesk__FKImpact__c;
            siUrg = ServiceIncident.BMCServiceDesk__FKUrgency__c;
        }
        
        //Calling method TierCountMethod() to get the count of Impacted Account;
        TierCountMethod();
        
    }
    //    CR - 2049598 - Start Adding the extra parameter Historical
    public String ErrorMessageMissingFields(Boolean Historical)
    {
        String errorMessage = '';
        if(ServiceIncident!=null)
        {
            If(ServiceIncident.BMCServiceDesk__FKCategory__c == null && Historical == false)
            {
                errorMessage+= 'Category , ';
            }
            If(ServiceIncident.BMCServiceDesk__Service_Request_Title__c == null)
            {
                errorMessage+= 'Title, ';
            }
            If(ServiceIncident.BMCServiceDesk__FKImpact__c == null)
            {
                errorMessage+= 'Impact, ';
            }
            If( ServiceIncident.OwnerId == null )
            {
                errorMessage+= 'Owner, ';
            }
            If(ServiceIncident.SI_StatusChangeDate__c == null && Historical == false)
            {
                errorMessage+= 'Status Change Date, ';
            }
            If( ServiceIncident.BMCServiceDesk__incidentDescription__c == null && Historical == false )
            {
                errorMessage+= 'Description, ';
            }
            If(ServiceIncident.BMCServiceDesk__FKUrgency__c == null)
            {
                errorMessage+= 'Urgency, ';
            }
            If(ServiceIncident.BMCServiceDesk__FKStatus__c == null && Historical == false )
            {
                errorMessage+= 'Status, ';
            }
        }
        
        return errorMessage.removeEnd(', ');
    }
    public boolean CheckRequiredFields(Boolean Historical)
    {
        if(Historical)
        {
            if( ServiceIncident.BMCServiceDesk__Service_Request_Title__c == null || ServiceIncident.OwnerId == null
               || ServiceIncident.BMCServiceDesk__FKImpact__c == null || ServiceIncident.BMCServiceDesk__FKUrgency__c == null
              )
            {
                return true;    
            }
            else
            {
                return false;
            }      
        }
        else if( ServiceIncident.BMCServiceDesk__FKCategory__c == null || ServiceIncident.BMCServiceDesk__Service_Request_Title__c == null || ServiceIncident.BMCServiceDesk__FKImpact__c == null
                || ServiceIncident.OwnerId == null || ServiceIncident.SI_StatusChangeDate__c == null || ServiceIncident.BMCServiceDesk__incidentDescription__c == null
                || ServiceIncident.BMCServiceDesk__FKUrgency__c == null ||ServiceIncident.BMCServiceDesk__FKStatus__c == null)
        {
            return true;    
        }
        else
            return false;
    }
    //CR - 2049598 End
    
    //Changed by ssawhney on 28/08/2013 for CR 2308403 - default Incident start time to SI record creation time
    public PageReference save1() {
        
        try
        {
            
            
            if(PageParameterIncident == 'new')
            {        
                if( CheckRequiredFields(false) )
                {
                    if(ServiceIncident.BMCServiceDesk__FKStatus__c != StatusInProgressId && ServiceIncident.SI_OutageStart__c == null )
                    {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter values in the required fields (  '+ErrorMessageMissingFields(false)+', Incident Start Date ) highlighted in red.'));
                    }
                    else
                    {
                        ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter values in the required fields ( '+ErrorMessageMissingFields(false)+' ) highlighted in red. '));
                    }
                }        
                else
                {
                    ServiceIncident.RecordTypeId = RecordId;
                    //Pinkesh- ESESP-505 - default Incident Start Time to Status Change Date on create.
                    //start of changes by ssawhney on 28/08/2013 for CR 2308403 - default Incident start time to SI record creation time
                    if(ServiceIncident.BMCServiceDesk__FKStatus__c == StatusInProgressId)
                    {
                        ServiceIncident.SI_OutageStart__c = ServiceIncident.SI_StatusChangeDate__c;
                    }
                    //end of changes by ssawhney on 28/08/2013 for CR 2308403
                    if(ServiceIncident.BMCServiceDesk__FKStatus__r.Name != 'IN PROGRESS')
                    {
                        ServiceIncident.SI_Field_Update_Done_Send_Email_Now__c = true;
                    }
                    insert ServiceIncident;
                    //newLocation = '/'+[select Id from BMCServiceDesk__Incident__c where BMCServiceDesk__Service_Request_Title__c = :ServiceIncident.BMCServiceDesk__Service_Request_Title__c and BMCServiceDesk__FKImpact__c = :ServiceIncident.BMCServiceDesk__FKImpact__c  and BMCServiceDesk__FKCategory__c= :ServiceIncident.BMCServiceDesk__FKCategory__c order by CreatedDate desc ][0].Id ;
                    PageReference pageRef = new PageReference('/'+[select Id from BMCServiceDesk__Incident__c where BMCServiceDesk__Service_Request_Title__c = :ServiceIncident.BMCServiceDesk__Service_Request_Title__c and BMCServiceDesk__FKImpact__c = :ServiceIncident.BMCServiceDesk__FKImpact__c  and BMCServiceDesk__FKCategory__c= :ServiceIncident.BMCServiceDesk__FKCategory__c order by CreatedDate desc ][0].Id );
                    
                    pageRef.setRedirect(true);
                    
                    return pageRef;
                }
            }
            else if(PageURL.Contains('SI_ServiceIncidentEdit'))
            {
                if(ServiceIncident.SI_Executive_Summary__c == null)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter Executive Summary highlighted in red.'));
                }
                else if(CheckRequiredFields(HistoricalIncident))
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter values in the required fields ('+ErrorMessageMissingFields(HistoricalIncident)+' ) highlighted in red.'));
                }
                else
                {
                    
                    update ServiceIncident;
                    
                    PageReference pageRef = new PageReference('/'+ServiceIncident.Id);
                    newLocation = '/'+ServiceIncident.Id;
                    pageRef.setRedirect(true);
                    return pageRef;
                }
            }
            else
            {
                if(ServiceIncident.SI_Executive_Summary__c == null)
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter Executive Summary'));
                }
                else if( CheckRequiredFields(HistoricalIncident) )
                {
                    ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please enter values in the required fields : '+ErrorMessageMissingFields(HistoricalIncident)));
                }
                else
                {
                    update ServiceIncident;
                    errorMessage='';
                    ServiceIncident = getIncident();   
                    newLocation = '/'+ServiceIncident.Id;
                }
                
            }
            
        }
        catch(Exception e)
        {
            
            if(e.getMessage().contains('Status Change Date'))
            {
                messageColor='Red';
                errorMessage='StatusDateChange';
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR, 'Please select a new date/time in Status Change Date for the newly selected Status prior to saving the record.');
                ApexPages.addMessage(myMsg);
                
            }
            else if(e.getMessage().contains('Owner ID'))
            {
                errorMessage='Owner';
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR, 'Please Change the Owner Field.');
                ApexPages.addMessage(myMsg);
            }
            else if (e.getMessage().contains('TRANSFER_REQUIRES_READ'))
            {
                messageColor='Red';
                errorMessage='Other';
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR, 'The Owner Must have Read permission the Record. Please select another Owner');
                ApexPages.addMessage(myMsg);
            }
            //Start of changes by ssawhney for CR 2053414 - Root cause and Incident caused by should be mandatory at the time of Phase 3
            else if(e.getMessage().contains('FIELD_CUSTOM_VALIDATION_EXCEPTION'))
            {
                messageColor='Red';
                errorMessage='Other';
                
                string error = CommonUtilClass.ExtractValidationExMsg(e);
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR, error);
                ApexPages.addMessage(myMsg);
            }
            //End of changes by ssawhney for CR 2053414
            else
            {
                messageColor='Red';
                errorMessage='Other';
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR, 'Incident Not Saved due to ' + e);
                ApexPages.addMessage(myMsg);
            }
        }finally
        {
            
            
        }
        
        return null;
    }
    private BMCServiceDesk__Incident__c getIncident()
    {
        BMCServiceDesk__Incident__c inc;
        //Start of changes by janantha for CR 2030086
        //Start of changes by ssawhney for CR 2031706
        // Changes for ESESP-1767 : Added Incident Declared Date/Time field in the query.
        for(BMCServiceDesk__Incident__c incident : [ select Total_Tier_Count__c,How_was_the_Issue_Detected__c,SI_Business_Unit_Category__c,SI_Etherpad_Link__c,Etherpad_Link__c,SI_GSS_Inc_Manager_BIL__c, SI_GSS_Inc_Manager_BIL__r.Name,Name,Id,Hours__c,RecordType.Name,Days_Open__c,SI_SD_Dashboard_Incident__c, Customer_Advisory__c, SI_StatusChangeDate__c, BMCServiceDesk__Service_Request_Title__c, BMCServiceDesk__FKStatus__c, BMCServiceDesk__FKStatus__r.Name, CreatedDate, OwnerId, Owner.Name, SI_OutageStart__c, SI_OutageEnd__c, BMCServiceDesk__FKImpact__c, BMCServiceDesk__FKImpact__r.Name, BMCServiceDesk__incidentDescription__c, BMCServiceDesk__FKCategory__c, BMCServiceDesk__FKCategory__r.Name, CreatedById, SI_Customer_Dos__c, SI_Type_of_customer_impact__c, SI_Network__c, SI_Technical_Notes__c, SI_Diagnosis__c, SI_Impacted_CP_Codes_Domains__c, BMCServiceDesk__incidentResolution__c, SI_Incident_Caused_By__c, BMCServiceDesk__FKUrgency__c, BMCServiceDesk__FKUrgency__r.Name, SI_Incident_Sensitivity__c, SI_Incident_Review_Status__c, SI_Incident_Review_Present_Date__c, SI_Platform_Review_Date__c,BMCServiceDesk__FKClient__c, CreatedBy.Name,SI_Executive_Summary__c,Incident_Declared_Date_Time__c  from BMCServiceDesk__Incident__c where Name = :PageParameterIncident])
            // End of Changes for ESESP-1767
            //Start of changes by ssawhney for CR 2031706
            //End of changes by janantha for CR 2030086
        {
            inc= incident;
            
        }
        
        return inc;
    }
    
    
    
    public PageReference edit1()
    {
        
        if(ServiceIncident!=null)
            newLocation = '/apex/SI_ServiceIncidentEdit?Incident='+ServiceIncident.Name;
        
        return null;
    }
    
    public void TierCountMethod(){
        
        List<SI_ServiceIncidentImpactedCustomers__c> impactedCustList = [select id from SI_ServiceIncidentImpactedCustomers__c where SI_Service_Incident__r.Name = : PageParameterIncident];
        if(impactedCustList.size() >= 1){
            TierRender = true;
        }
        else{
            TierRender = false;
        }
    }
    
    
    
    public void createNewIncidentForTest()
    {
        ServiceIncident = new BMCServiceDesk__Incident__c();
        ServiceIncident.RecordTypeId = RecordId ;
    }
    public PageReference Revert()
    {
        init();
        ProcessingMessage = 'Reverting';
        return null; 
    }
    
    /*Aditya- CR :CR 2628246,How was the issue detected field disable for older records*/
    public boolean getdisableIssueDetected()
    {
        
        // Try to fetch created date from Service Incident , if new record, Null value will be passed and will be handled in Catch all Block
        try{
            
            // Fetching Created Date and storing it in the format of yyyy-mm-dd
            Date SICreationTime = Date.valueOf(ServiceIncident.createddate.formatGMT('yyyy-MM-dd'));
            
            //validating if created date of record is less than the date mention in custom setting
            if(SICreationTime < SC_IssueDetected_Required_CS__c.getValues('SC_IssueDetected_Required_Date').SI_Issue_Detected_Req_date__c && SICreationTime != Null){
                
                return true;
            }
            
        }catch(exception e){}      
        
        return false; 
    }
    
    
    /* End of Change CR 2628246  */
    /*public String getIncidentNumberForReport()
{

try
{
String abiLink = '';

SI_Search__c objApp = SI_Search__c.getInstance('SI_CustomSetting');

//Added for ABI Reports for historical data - janantha

if(ServiceIncident.SI_SD_Dashboard_Incident__c != null && ServiceIncident.SI_SD_Dashboard_Incident__c != '')
{
abiLink = objApp.ABI_Report__c + String.valueOf(Integer.valueOf(ServiceIncident.SI_SD_Dashboard_Incident__c));             
}
else
abiLink = objApp.ABI_Report__c + String.valueOf(Integer.valueOf(ServiceIncident.Name));

return abiLink;
}
catch(Exception e)
{
return ' ';
}

}*/
    
    public static String tempNotesHolder{get;set;}
    public PageReference sendMail()
    {       
        String toAddress = '';
        String orgWideEmailId = '';
        //String ccAddress = 'serviceincidents@akamai.com';     
        String ccAddress = '';
        List<String> toAddresses = new List<String>();
        List<String> ccAddresses = new List<String>();
        SIMailingLists__c mailingLists = SIMailingLists__c.getInstance('SIEmailIds');
        String fromAddress = mailingLists.SI_FromAddress__c; 
        try
        {
            if( (ServiceIncident.BMCServiceDesk__FKImpact__r.Name == 'Severity 1') )
            {
                toAddress = mailingLists.SI_Severity1MailingList__c;
            }
            else if( (ServiceIncident.BMCServiceDesk__FKImpact__r.Name == 'Severity 2') )
            {
                toAddress = mailingLists.SI_Severity2MailingList__c;
            }
            else if( (ServiceIncident.BMCServiceDesk__FKImpact__r.Name == 'Severity 3') )
            {
                toAddress = mailingLists.SI_Severity3MailingList__c;
            }
            else if( (ServiceIncident.BMCServiceDesk__FKImpact__r.Name == 'Severity 4') )
            {
                toAddress = mailingLists.SI_Severity4MailingList__c;
            }
            /*Start of changes by janantha for CR 2030086*/
            else if( (ServiceIncident.BMCServiceDesk__FKImpact__r.Name == 'None') )
            {
                toAddress = mailingLists.SI_SeverityNoneMailingList__c;
            }   
            orgWideEmailId = [select Id from OrgWideEmailAddress where Address = :mailingLists.SI_FromAddress__c limit 1].Id;         
            
            // Modified the Query to search based on User Id instead of Name
            if(ServiceIncident.CreatedBy!= null){
                
                for(User usrRec : [select Email from User where ID = :ServiceIncident.CreatedById and isActive = true limit 1]){
                    ccAddress = usrRec.Email;
                }
            }
            
            /*End of changes by janantha for CR 2030086*/
            toAddresses.add(toAddress);
            if(ccAddress!='' && ccAddress!=null)
                ccAddresses.add(ccAddress);
            ccAddresses.add(fromAddress);
            /*TO BE COMMENTED OUT*/
            //ccAddresses.add('bmcsd_emailconversationlistener@29edf1lteuczdscmrg91rt6g9gxmv4r4ijjn1chbn2yzkaybv3.z-p2t6mai.z.apex.sandbox.salesforce.com');
            String whatId = ServiceIncident.Id;
            String targetObjectId = '';
            targetObjectId = [select Id from Contact where Name = 'SI Test Contact' and Contact.Account.Name = 'Akamai Internal' limit 1].Id;
            
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            String templateId = [select Id from EmailTemplate where Name = 'SI Email Template Send Mail Text'].Id;
            mail.setToAddresses(toAddresses);
            mail.setTemplateId(templateId);
            mail.setTargetObjectId(targetObjectId);
            mail.setOrgWideEmailAddressId(orgWideEmailId);
            mail.setWhatId(whatId);      
            mail.setCcAddresses(ccAddresses);
            mail.setSaveAsActivity(true);
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });                   
        }
        catch(Exception e)
        {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR, 'Send Email Failed: ' + e.getMessage());
            ApexPages.addMessage(myMsg);
        }
        return null;
    }
    
    
    public ApexPages.StandardSetController con {
        get {
            if(con == null) {
                con = new ApexPages.StandardSetController(Database.getQueryLocator([select Id, BMCServiceDesk__date__c, BMCServiceDesk__FKUser__c, BMCServiceDesk__description__c, BMCServiceDesk__duration__c, BMCServiceDesk__note__c from BMCServiceDesk__IncidentHistory__c where BMCServiceDesk__FKIncident__r.Id = :ServiceIncident.Id order by BMCServiceDesk__date__c DESC]));
                // sets the number of records in each page set
                con.setPageSize(5);
            }
            return con;
        }
        set;
    }
    
    /*Start of changes by janantha for CR 2018683*/           
    public List<Wrapper> getIncidentHistory()
    {
        try
        {
            wrappers = new List<Wrapper>();
            
            //List<BMCServiceDesk__IncidentHistory__c> incidentHistory1 = new List<BMCServiceDesk__IncidentHistory__c>();
            //incidentHistory1 = [select Id, BMCServiceDesk__date__c, BMCServiceDesk__FKUser__c, BMCServiceDesk__description__c, BMCServiceDesk__duration__c, BMCServiceDesk__note__c from BMCServiceDesk__IncidentHistory__c where BMCServiceDesk__FKIncident__r.Id = :ServiceIncident.Id order by BMCServiceDesk__date__c DESC];      
            
            /* for(BMCServiceDesk__IncidentHistory__c incidentH:incidentHistory1)
{         
wrapper = new Wrapper(incidentH);
wrappers.add(wrapper);                    
}             
return wrappers;*/
            
            for (BMCServiceDesk__IncidentHistory__c incidentH : (List<BMCServiceDesk__IncidentHistory__c>)con.getRecords())
            {
                wrapper = new Wrapper(incidentH);
                wrappers.add(wrapper);
            }
            
            return wrappers;
        }
        catch(Exception e)
        {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR, 'Incident History Not Recorded: ' + e.getMessage());
            ApexPages.addMessage(myMsg);
            return null;
        }
    }
    /*ADDED FOR PAGINATION*/
    
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
    
    public boolean getrenderPaginationIncidentHis()
    {
        if(con.getRecords().size()>0)
            return true;
        else
            return false;     
    }
    
    public String completeNotesWithLineBreaks1{get;set;}
    public String getSI_EmailPreview()
    {
        try
        {
            String incidentHistoryId = ApexPages.currentPage().getParameters().get('Notes');
            List<BMCServiceDesk__IncidentHistory__c> incidentHistory1 = new List<BMCServiceDesk__IncidentHistory__c>();
            incidentHistory1 = [select Id, BMCServiceDesk__date__c, BMCServiceDesk__FKUser__c, BMCServiceDesk__description__c, BMCServiceDesk__duration__c, BMCServiceDesk__note__c from BMCServiceDesk__IncidentHistory__c where Id = :incidentHistoryId];     
            Integer lengthOfString = incidentHistory1[0].BMCServiceDesk__note__c.length();
            if(lengthOfString>0)
                completeNotesWithLineBreaks1 = incidentHistory1[0].BMCServiceDesk__note__c.replace('\n','<br/>');
            return 'Sent: '+incidentHistory1[0].BMCServiceDesk__date__c+'<br/>'+completeNotesWithLineBreaks1;
        }
        catch(Exception e)
        {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR, 'Incident History Cannot Be Displayed: ' + e.getMessage());
            ApexPages.addMessage(myMsg);
            return null;
        }
    }
    
    public String notes{get;set;}   
    
    
    public class Wrapper
    {
        public BMCServiceDesk__IncidentHistory__c incidentHistory{get;set;}
        public String truncatedNote{get;set;}
        public String[] splitString{get;set;}
        Integer lengthOfString;
        Integer result = 0;
        
        public wrapper(BMCServiceDesk__IncidentHistory__c incidentHis)
        {
            try
            {
                incidentHistory = new BMCServiceDesk__IncidentHistory__c();
                incidentHistory = incidentHis;
                splitString = new List<String>();
                if(incidentHistory!=null)
                {
                    
                    if(incidentHistory.BMCServiceDesk__note__c!=null && incidentHistory.BMCServiceDesk__note__c!='')
                    {
                        lengthOfString = incidentHistory.BMCServiceDesk__note__c.length();
                        
                        
                        if(incidentHistory.BMCServiceDesk__note__c.length()>300){
                            truncatedNote = incidentHistory.BMCServiceDesk__note__c.substring(0,300);
                            result = truncatedNote.indexOf('Subject');
                            
                            if(result != -1){
                                splitString.add(truncatedNote.substring(0,result));
                                splitString.add(truncatedNote.substring(result,300));
                            }
                            else
                            {
                                splitString.add(truncatedNote.substring(0,299));
                                splitString.add('.');
                            }
                        }
                        
                        else
                        {
                            splitString.add(incidentHistory.BMCServiceDesk__note__c);
                            splitString.add('.');
                        }
                        
                    }
                    // For displaying Incident records with Incident History without Notes.
                    else{
                        splitString.add('');
                        splitString.add('');
                    }
                }
                
            }
            catch(Exception e)
            {
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.severity.ERROR, 'Incident History Cannot Be Displayed(Wrapper): ' + e.getMessage());
                ApexPages.addMessage(myMsg);
            }                        
        }
    }
    /*End of changes by janantha for CR 2018683*/
    
    
    public PageReference cancel1()
    {
        if(PageParameterIncident!=null && PageParameterIncident!='')
        {
            
            if(PageParameterIncident=='new')
            {
                PageReference pageRef = new PageReference('/apex/SI_ServiceIncidentSearch');
                //newLocation = '/apex/SI_ServiceIncidentSearch';
                pageRef.setRedirect(true);
                return pageRef;
            }
            else if(PageURL.Contains('SI_ServiceIncidentEdit'))
            {
                
                PageReference pageRef = new PageReference('/'+ServiceIncident.Id);
                //newLocation = '/apex/SI_ServiceIncidentSearch';
                pageRef.setRedirect(true);
                return pageRef;
            }
            else
            {
                //   PageReference pageRef = new PageReference('/apex/SI_ServiceIncidentSearch');
                
                newLocation = '/apex/SI_ServiceIncidentSearch';
                // pageRef.setRedirect(true);
                // return pageRef;
            }
        }
        return null;
    }
    public SI_ServiceIncidentDetails()
    {
        init();
        //displayPopup = false;
        //getIncidentHistory();
    }
    private String convertMS(decimal ms) {
        decimal d, h,s,m;
        String numberToDays = '';
        s = Math.floor(ms / 1000);
        m = Math.floor(s / 60);
        s = Math.mod(s.intValue(),60);
        h = Math.floor(m / 60);
        m = math.mod(m.intValue(),60);
        d = Math.floor(h / 24);
        h = math.mod(h.intValue(),24);
        if (d > 0) {
            numberToDays = d + ' Days, ';   
        }
        if (h > 0){
            numberToDays += h + ' hours, ';
        }
        if (m > 0){
            numberToDays += m + ' minutes, ';
        }
        if (s > 0){
            numberToDays += s + ' seconds ';
        }
        return  numberToDays ;
    }
}