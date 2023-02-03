/*=====================================================================================================+

|  HISTORY  |                                                                            

|  DATE             DEVELOPER       CR          DESCRIPTION                                                       

|  ===========      =========       =======     =========== 
                                    
|  16-Jan-2016      Himanshu        3237131     - Controllor For : SC_SI_LOECreationPage 
								- Object Name = Activity Tracking
|  04-Nov-2019		Sheena Bhan		ESESP-2100	- Prepopulating "User Holding Incident" field
+=====================================================================================================*/
public class SC_SI_LOECreationFromVFPage {
    
    // Variable to store SI Id from URL
    public String serviceIncidentIdFrmLoePage {get;set;}
    
    // Variable to store SI Number from URL
    public String serviceIncidentNumber {get;set;}
    
    // Variable to get the Record from VF Page
    public Service_Incident_age_by_status__c LOERecVFPage {get;set;}
    
    // Constructor Overloading for Standard Controllor
    public SC_SI_LOECreationFromVFPage(ApexPages.StandardController stdController) {
        
        // Getting Values from Parameters
        serviceIncidentIdFrmLoePage = ApexPages.currentPage().getParameters().get('Incidentid');
        serviceIncidentNumber = ApexPages.currentPage().getParameters().get('IncidentNumber');
        
        // Get the Record from Standard Controllor
        LOERecVFPage = new Service_Incident_age_by_status__c();
        
        
         // Sheena- CR - ESESP-2100 - Prepopulating "User Holding Incident" field
         // Get the loggedin userid
        LOERecVFPage.User__c  = userinfo.getUserId();
        // CR - ESESP-2100 End
        
    }
    
    // Save Method 
    public PageReference save(){
 
 	try{
 	
        // Inserting the LOE Record
        LOERecVFPage.incident__c=serviceIncidentIdFrmLoePage;
        Insert LOERecVFPage;
        
      }catch(Exception e){
       
       	
           ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,CommonUtilClass.ExtractValidationExMsg(e) ));
           return null;
       }
        
        // Setting the Return URL
        PageReference saveURL = new PageReference('/apex/ServiceIncidentLOE?id='+serviceIncidentIdFrmLoePage);

        return saveURL;

    }
    
    // Save & New Method 
    public PageReference saveandNew(){

	try{
	
        // Inserting the LOE Record
        LOERecVFPage.incident__c=serviceIncidentIdFrmLoePage;
        Insert LOERecVFPage;
        
      }catch(Exception e){
       
           ApexPages.addmessage(new ApexPages.message(ApexPages.severity.Error,CommonUtilClass.ExtractValidationExMsg(e) ));
           return null;
       }
        
        // Resetting the values
        LOERecVFPage = new Service_Incident_age_by_status__c();
        
        // Setting the Return URL
        PageReference saveURL = new PageReference('/apex/SC_SI_LOECreationPage?Incidentid=' + serviceIncidentIdFrmLoePage + 
                                                  '&IncidentNumber=' + serviceIncidentNumber);

        return saveURL; 

    }
                                                  
    // Cancel Method 
    public PageReference cancel(){
       
        // Setting the Return URL
        PageReference retURL = new PageReference('/apex/ServiceIncidentLOE?id='+serviceIncidentIdFrmLoePage);

        return retURL;
    }
    
}