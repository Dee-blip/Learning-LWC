/*******************************************************************************************************
 Name         :   SuggestedServiceIncidentsController
 Author       :   Vinod Kumar (Appirio Offshore)
 Created Date :   June 28,2013
 Task         :   T-157245
 Description  :   controller class for the page SuggestedServiceIncidents
*******************************************************************************************************/
public with sharing class SuggestedServiceIncidentsController {
	public string strKnowledgeBaseSearchText{get;set;}
    public string strServiceIncidentsText{get;set;}
    public list<BMCServiceDesk__Incident__c > lstIncidents{get;set;}
    public string selectedIncident { get; set; }
    public case currentCase; 
    List<String> status;
    set<id> IncidentIds; 
    public boolean isIncidentAssociated{get;set;}
	public SuggestedServiceIncidentsController(ApexPages.StandardController controller){
		 //
        IncidentIds = new set<ID>();
        //
        status = new String[5];
        status[0] = 'IN PROGRESS';
        status[1] = 'ROOT CAUSE DETERMINED';
        status[2] = 'SOLUTION IDENTIFIED';
        status[3] = 'IMPACT MITIGATED';
        status[4] = 'RESOLVED';
        currentCase =  (case)controller.getRecord();
        currentCase = [Select Incident__c, Id, AccountId From Case c where id= : currentCase.ID];     
        //currentCase = [Select Incident__c, Id, AccountId From Case c where CaseNumber ='00229524'];  
        if(currentCase.Incident__c != null){
        	isIncidentAssociated = true;
        }
        
        getAllIncidentIDs();
        SearchedIncident();        
	}
	void getAllIncidentIDs(){
        // check  Case Account- Compare to field "Impacted Account > Account Name" that identifies Accounts Impacted by the Inciden
        for(SI_ServiceIncidentImpactedCustomers__c sImpCustomer :[Select SI_Service_Incident__c, SI_AccountName__c, Id 
                                                                From SI_ServiceIncidentImpactedCustomers__c
                                                                where SI_AccountName__c =:currentCase.AccountId]){
            IncidentIds.add(sImpCustomer.SI_Service_Incident__c);
        }
        
        // check -- Case Product- Compare to "Impacted Products > Product" that identifies the products impacted by the Incident
        for(SI_ServiceIncidentImpactedProducts__c sImpCustomer: [Select SI_ServiceIncident__c, SI_ProductName__c, Id From SI_ServiceIncidentImpactedProducts__c]){
            IncidentIds.add(sImpCustomer.SI_ServiceIncident__c);
        }
    }
    public void SearchedIncident(){
        lstIncidents = new list<BMCServiceDesk__Incident__c>();
        if(IncidentIds.size() > 0){
            if(strServiceIncidentsText ==''){
                lstIncidents =[Select Id, BMCServiceDesk__FKAccount__c, Name,BMCServiceDesk__incidentDescription__c 
                                From BMCServiceDesk__Incident__c 
                                where ID in: IncidentIds and BMCServiceDesk__FKStatus__r.Name in :status];
                                
            }
            else{
                lstIncidents =[Select Id, BMCServiceDesk__FKAccount__c, Name,BMCServiceDesk__incidentDescription__c 
                                From BMCServiceDesk__Incident__c 
                                where ID in: IncidentIds and BMCServiceDesk__FKStatus__r.Name in :status and Name like :strServiceIncidentsText];
                                
                                            
            }
        }
        
    }
    public void PopulateCaseIncident(){
        system.debug('selectedIncident::::::'+selectedIncident);
        if(selectedIncident != null && selectedIncident !=''){
            // update the current case Case.Incident__c
            try{
                currentCase.Incident__c = selectedIncident;
                update currentCase;
                isIncidentAssociated = true;
            }
            catch(exception ex){
                 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()));                
            }
        }
    }

}