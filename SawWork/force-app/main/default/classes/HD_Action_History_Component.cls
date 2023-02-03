/*
Template: Apex Test Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : OCT 28 2014

Base Line : used as a apart of requirment for SRM detail page component, Unit Test

Purpose : component for action history
          
Usage : used as an component for ServiceRequestDetail page
          
Test Class Asssociated : HD_Test_Action_History_Component

Controller (Boolean): false

Page Used/Asssociated (default -> NONE) : ServiceRequestdetail

Trigger Associated : NONE
Class Associated : [ ]
              
*/
public with sharing class HD_Action_History_Component 
{
	public ID TargetObjectIdvalue{get;set;}
    public Boolean success {get;set;}
	//Constructor
	public HD_Action_History_Component() 
	{
		success=null;
	}//

	public List<BMCServiceDesk__IncidentHistory__c> getActionHistory()
	{
		List<BMCServiceDesk__IncidentHistory__c> incidenthistories = new List<BMCServiceDesk__IncidentHistory__c>();
		for( BMCServiceDesk__IncidentHistory__c inHist : [Select Id,Name,BMCServiceDesk__FKAction__c,
																	BMCServiceDesk__actionId__c,
																	BMCServiceDesk__Action_Duration__c,
																	BMCServiceDesk__Client_Contact__c,
																	BMCServiceDesk__Client_User__c,
																	BMCServiceDesk__date__c,
																	BMCServiceDesk__description__c,
																	BMCServiceDesk__duration__c,
																	BMCServiceDesk__EmailConversationData__c, 
																	HD_Incident_ID__c,
																	BMCServiceDesk__inactive__c,
																	BMCServiceDesk__FKIncident__c,
																	BMCServiceDesk__incidentId__c,
																	BMCServiceDesk__note__c,
																	BMCServiceDesk__Reply__c,
																	BMCServiceDesk__Reply_Console__c,
																	BMCServiceDesk__RichTextNote__c,
																	BMCServiceDesk__FKUser__c,
																	BMCServiceDesk__userId__c,
																	BMCServiceDesk__system__c 
from BMCServiceDesk__IncidentHistory__c Where BMCServiceDesk__FKIncident__c =:TargetObjectIdvalue ORDER BY CreatedDate DESC  Limit 15])
		{ 
			BMCServiceDesk__IncidentHistory__c hist = new BMCServiceDesk__IncidentHistory__c();
			hist = inHist;
			system.debug('---->'+hist.BMCServiceDesk__note__c);
			incidenthistories.add(hist);
		}
      
      return incidenthistories;
	}//

    public PageReference addNote()
    {
        System.debug('TargetObjectIdvalue: '+TargetObjectIdvalue);
        List<BMCServiceDesk__Incident__c> incidentList=[Select Id, Name, BMCServiceDesk__state__c from BMCServiceDesk__Incident__c where Id =:TargetObjectIdvalue ];
        BMCServiceDesk__Incident__c inc = incidentList.get(0);
        System.debug('Incident: '+inc.Id);
        System.debug('Incident Name: '+inc.Name);
        if(inc.BMCServiceDesk__state__c){
            System.debug('Incident Name: '+inc.Name+' is open');
            PageReference pg = new pageReference('/apex/c__HD_AddNote');
            pg.getParameters().put('incidentID',inc.Id);
            System.debug('ApexPages.CurrentPage().getUrl() in ActionHistoryComponent: '+ApexPages.CurrentPage().getUrl());
            pg.getParameters().put('source',ApexPages.CurrentPage().getUrl());
        	//pg.setRedirect(true);
            success=true;
            return pg;
		}
        else{
            System.debug('Incident Name: '+inc.Name+' is closed');
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'This Incident is Closed. Reopen the Incident to use the feature'));
            return null;
        }
        //if(currInc state!=false){ 
        //code to open page
        //}
        //else{
            //error that incident is closed
        //}
    }
	
}//END