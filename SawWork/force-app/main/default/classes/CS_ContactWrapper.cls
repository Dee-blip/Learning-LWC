/*
CR 1636447 CSAT: Q22012 Eligible Contact List Management Functionality
Created :April-2012
Created By: Sharath
Description:This class is used to wrap the Contact object with a checkbox

*/
public with sharing class CS_ContactWrapper {
	
	public Contact con{get; set;}
	public CS_SurveyContacts__c surveyContact {get;set;}
	public String surveyName {get;set;}
    public Boolean selected {get; set;}
    
    public CS_ContactWrapper(Contact c)
    {
        con = c;
        selected = false;
    }

}