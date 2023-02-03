/*******************************************************************************************************
 Name         :   CaseFeedDetailPageController
 Author       :   Vinod Kumar (Appirio Offshore)
 Created Date :   June 6,2013
 Task         :   T-149229
 Description  :   controller class for the page CaseFeedDetailPage
*******************************************************************************************************/
public with sharing class CaseFeedDetailPageController {
    public string strKnowledgeBaseSearchText{get;set;}
    public string strServiceIncidentsText{get;set;}
    public list<BMCServiceDesk__Incident__c > lstIncidents{get;set;}
    public string selectedIncident { get; set; }
    public case currentCase; 
    List<String> status;
    set<id> IncidentIds; 
    public list<SelectOption> suggestedServiceIncidents{get;set;}
    public CaseFeedDetailPageController(ApexPages.StandardController controller){
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
        //
        getAllIncidentIDs();
        SearchedIncident();
        //
        addSuggestedServiceIncidents();
    }
    void addSuggestedServiceIncidents(){
        suggestedServiceIncidents = new List<SelectOption>();
        suggestedServiceIncidents.add(new SelectOption('https://control.akamai.com','Luna'));
        suggestedServiceIncidents.add(new SelectOption('https://monarch.akamai.com','Monarch'));
        suggestedServiceIncidents.add(new SelectOption('https://kb.akamai.com','KB'));
        suggestedServiceIncidents.add(new SelectOption('https://agora.akamai.com/wiki/Products_Page','Product Documentation'));
        suggestedServiceIncidents.add(new SelectOption('https://tools.gss.akamai.com/portal/)','Tools Portal'));
        suggestedServiceIncidents.add(new SelectOption('https://act.akamai.com/act2/static/act/advancedsearch.html?type=configs&field=byName&keyword=1-855Q5 (Where 1-855Q5 is the Siebel Account ID [AKAM Account ID] ) ','ACT'));
        suggestedServiceIncidents.add(new SelectOption('https://agora.akamai.com/wiki/CCare_ACD_Status_-_Technical_Support_team','ACD status page'));
        suggestedServiceIncidents.add(new SelectOption('https://serviceincidents.akamai.com/','Service Incidents'));    
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
            if(strServiceIncidentsText !=''){
                lstIncidents =[Select Id, BMCServiceDesk__FKAccount__c, Name 
                                From BMCServiceDesk__Incident__c 
                                where ID in: IncidentIds and BMCServiceDesk__FKStatus__r.Name in :status];
            }
            else{
                lstIncidents =[Select Id, BMCServiceDesk__FKAccount__c, Name 
                                From BMCServiceDesk__Incident__c 
                                where ID in: IncidentIds and BMCServiceDesk__FKStatus__r.Name in :status
                                            and Name like :strServiceIncidentsText];
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
            }
            catch(exception ex){
                 ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR,ex.getMessage()));                
            }
        }
    }

}