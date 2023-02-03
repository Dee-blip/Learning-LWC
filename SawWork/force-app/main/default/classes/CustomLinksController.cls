/*******************************************************************************************************
 Name         :   CustomLinksController
 Author       :   Vinod Kumar (Appirio Offshore)
 Created Date :   June 27,2013
 Task         :   T-157245
 Description  :   controller class for the page Custom Links
*******************************************************************************************************/
public with sharing class CustomLinksController {
	 public list<SelectOption> selectCustomLinks{get;set;}
	 public string strSelectedLiks{get;set;}
	 public CustomLinksController(ApexPages.StandardController controller){
	  	addSelectCustomLinks();
	 }
	 void addSelectCustomLinks(){
        selectCustomLinks = new List<SelectOption>();
        selectCustomLinks.add(new SelectOption('https://control.akamai.com','Luna'));
        selectCustomLinks.add(new SelectOption('https://monarch.akamai.com','Monarch'));
        selectCustomLinks.add(new SelectOption('https://kb.akamai.com','KB'));
        selectCustomLinks.add(new SelectOption('https://agora.akamai.com/wiki/Products_Page','Product Documentation'));
        selectCustomLinks.add(new SelectOption('https://tools.gss.akamai.com/portal/)','Tools Portal'));
        selectCustomLinks.add(new SelectOption('https://act.akamai.com/act2/static/act/advancedsearch.html?type=configs&field=byName&keyword=1-855Q5 (Where 1-855Q5 is the Siebel Account ID [AKAM Account ID] ) ','ACT'));
        selectCustomLinks.add(new SelectOption('https://agora.akamai.com/wiki/CCare_ACD_Status_-_Technical_Support_team','ACD status page'));
        selectCustomLinks.add(new SelectOption('https://serviceincidents.akamai.com/','Service Incidents'));    
    }

}