/*=====================================================================================================+
Class name        	:   SC_Jarvis_Case_Widget_Controller
Author              :   Vamsee Surya
Created             :   01-Aug-2021
Purpose             :   Controller class for Case Widget Component
Test Class          :   SC_Jarvis_TestClass

Last Modified 	Developer   	Purpose             
============= 	==========  	=======
01-Aug-21     	Vamsee Surya  	Initial Development(Jira Ticket# ESESP-5674) 
23-Feb-21       Vishnu Vardhan  ESESP-6660: Updated query to include PTS Cases
+=====================================================================================================*/

public with sharing class SC_Jarvis_Case_Widget_Controller {
    
    public SC_Jarvis_Case_Widget_Controller() {

    }

    //Wrapper Class
    Public Class CaseCountWrapper{

        @AuraEnabled Public Integer myOpenCaseCount{get; set;}
        @AuraEnabled Public Integer updatedCaseCount{get; set;}
        @AuraEnabled Public Integer closedCaseCount{get; set;}
        @AuraEnabled Public Boolean displayWidget{get; set;}
        @AuraEnabled Public Boolean displayNewCaseButton{get; set;}

        Public CaseCountWrapper( Integer myOpenCaseCountValue, Integer updatedCaseCountValue, Integer closedCaseCountValue, Boolean displayWidgetValue, Boolean displayNewCaseButtonValue){
            myOpenCaseCount = myOpenCaseCountValue;
            updatedCaseCount = updatedCaseCountValue;
            closedCaseCount = closedCaseCountValue;
            displayWidget = displayWidgetValue;
            displayNewCaseButton = displayNewCaseButtonValue;
        }


    }
    @AuraEnabled
    public Static CaseCountWrapper getCaseCountData(){
        
        Integer myOpenCaseCount = 0, updatedCaseCount = 0, closedCaseCount = 0;
        Boolean displayWidget = True, displayNewCaseButton = False;
        
        Datetime considerationTime = system.now().addDays(-10);
        //List of cases where Logged in user is Contact on the case
        List<Case> caseList = new List<Case>();
        User loggedInUser = [SELECT Id, ContactId, AKAM_User_Id__c, Profile.Name FROM User WHERE Id =: UserInfo.getUserId()];
        Id contactId;
        if(loggedInUser.contactId != null){
            contactId = loggedInUser.contactId;
        }
        else{
            Contact contactRec = [SELECT Id,AccountId FROM Contact WHERE AKAM_Contact_Id__c = :loggedInUser.AKAM_User_Id__c 
            AND active_portal_login__c = true LIMIT 1];
            contactId = contactRec.Id;
        }


        if(contactId != null){

            List<Account> entitledAccounts = SC_Jarvis_utility.getAccountRecords(contactId, 'ReadMode');
            
            List<String> ptsSubTypeList = [Select Value__c from SC_CommunityUtility__mdt where DeveloperName = 'Partner_Technical_Support_Sub_Type'].Value__c.split(',');

            caseList = 	[SELECT Id FROM Case WHERE ContactId = :contactId 
                            AND Isclosed = False AND AccountID IN :entitledAccounts AND Do_not_show_in_portal__c = False
                            AND ( Recordtype.Name in ('Technical', 'Emerging Products Engineering', 'Managed Security', 'Professional Services', 'AMG', 'Billing') 
                                OR (recordtype.name = 'Partner Technical Support' and Sub_Type__c IN :ptsSubTypeList)) LIMIT 10000];

            List<Case> closedCaseList = [SELECT Id FROM Case WHERE ContactId = :contactId 
                            AND Isclosed = True AND AccountID IN :entitledAccounts AND Do_not_show_in_portal__c = False AND AKAM_Closed_Date__c > :considerationTime
                            AND ( Recordtype.Name in ('Technical', 'Emerging Products Engineering', 'Managed Security', 'Professional Services', 'AMG', 'Billing')
                            OR (recordtype.name = 'Partner Technical Support' and Sub_Type__c IN :ptsSubTypeList))];
            
            If(caseList.size() > 0){
                myOpenCaseCount = caseList.size();
                Set<Id> caseIdset = new Set<Id>();
                Set<String> customFields = new Set<String>();
            	Set<String> standardFields = new Set<String>();
                
                for(SC_Utility__mdt metadataRec : [SELECT Value__c, Value_Text__c FROM SC_Utility__mdt WHERE Active__c = True 
            										AND DeveloperName LIKE 'JarvisCaseHistory%']) {

                    for(String field : metadataRec.Value__c.split(',')){
                        if(metadataRec.Value_Text__c.contains('Standard')){
                            standardFields.add(field.split(':').get(0));    
                        }
                        else{
                            customFields.add(field.split(':').get(0)); 
                        }
                    }
            	}
                
                for(CaseHistory eachHistory : [SELECT caseId FROM CaseHistory WHERE field in :standardFields and CaseId = :caseList AND createddate > :considerationTime ]){
                    caseIdset.add(eachHistory.caseId);
                }
                
                for(Case_History_Custom__c eachHistory : [SELECT Case__c FROM Case_History_Custom__c WHERE Field__c in :customFields and Case__c = :caseList AND createddate > :considerationTime ]){
                    caseIdset.add(eachHistory.Case__c);
                }
               
            	updatedCaseCount = caseIdset.size();
                
            }
            closedCaseCount = closedCaseList.size();
            

        displayNewCaseButton = SC_Jarvis_utility.hasCreateAccess(contactId);


        }
        
        return new CaseCountWrapper(myOpenCaseCount,updatedCaseCount,closedCaseCount,displayWidget, displayNewCaseButton);
    }
    
    
}