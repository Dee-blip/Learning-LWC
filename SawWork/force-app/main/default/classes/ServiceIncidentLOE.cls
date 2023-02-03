/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE             DEVELOPER       CR    		DESCRIPTION                                                       

|  ===========      =========       =======     =========== 
                                                       
|  23-Mar-2015      Jay    			2824410     LOE tracking Ability on Service Incident
												Called from Page - ServiceIncidentLOE
|	
+=====================================================================================================*/ 
public class ServiceIncidentLOE {

    // Variable to Store Incident Id from
    public String serviceIncidentId {get;set;}
    
    // List to store all the LOE to be displayed in VF Page
    public List<Service_Incident_age_by_status__c> serviceIncidentAgeList{get;set;}
    
    // Variable to Store Object Key Prefix for - Service_Incident_age_by_status__c
    public String objectKeyPrefix{get;set;}
    
    // Variable to Store Incident field Id(Metadata)
    public String IncidentfieldId{get;set;}
    
    // Variable to Store how many records to be displayed in VF Page
    Integer totalRecords ;
    
    // Constructor Overloading for Standard Controllor
    public ServiceIncidentLOE(ApexPages.StandardController stdController) {
        
        serviceIncidentId = ApexPages.currentPage().getParameters().get('id');
        objectKeyPrefix = Service_Incident_age_by_status__c.sObjectType.getDescribe().getKeyPrefix();
        SC_CustomField_Metadata__c c  = SC_CustomField_Metadata__c.getValues('Service_incident.incident__c');
        if (c != null){
            IncidentfieldId = c.CustomField_ID__c ; 
        } 
        
        String recordsParam = ApexPages.currentPage().getParameters().get('totalRecord');
        if (recordsParam == null){
            //default size is 10
            totalRecords = 5;
        }
        else {
            totalRecords = Integer.valueOf(recordsParam);
        }
        
        loadServiceIncidentLOEList();
        
    }
    
    public void loadServiceIncidentLOEList(){
        serviceIncidentAgeList = [SELECT id,
                                  		 type__c,
                                  		 comments__c,
                                  		 loe__c,
                                   		 User__c,
                                  		user__r.name,
                                  		Start_Date__c,
                                  		end_date__c
                                  FROM Service_Incident_age_by_status__c
                                  WHERE LOE__c != null
                                  AND incident__c = :serviceIncidentId
                                  order by createddate desc
                                  LIMIT :totalRecords ];
        if (serviceIncidentAgeList == null) {
            serviceIncidentAgeList = new LIst<Service_Incident_age_by_status__c>();
        }    
    }
 
}