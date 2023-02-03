/*
Template: Apex Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : used as apart of requirment for Problem Managment

Purpose : an Implemetation for popup for tasks in problems
          
Usage : Used as an implementation for the business logic , for Problem_Task related List
          
Test Class Asssociated : HD_Test_ProblemTaskPage_ctrl

Controller (Boolean): true

Page Used/Asssociated (default -> NONE) : HDProblemTaskPage.page

Trigger Associated : NONE
              
*/

public with sharing class HD_ProblemTaskPage_Ctrl {
        
//      

public String probId{get;set;}
public BMCServiceDesk__Task__c tsk1{get;set;}
public List<BMCServiceDesk__Problem__c> pr = new List<BMCServiceDesk__Problem__c>();

//Constructor
public HD_ProblemTaskPage_Ctrl( Apexpages.Standardcontroller stdController )
{       
            String currentURL= Apexpages.currentPage().getUrl();
        system.debug('Current URL' +currentURL);
        if(currentURL.contains('probid='))
        {

        probId = ApexPages.currentPage().getParameters().get('probid');
        
        
        if( String.valueOf(probId).length() > 0 )
        {
                BMCServiceDesk__Task__c tsk = new BMCServiceDesk__Task__c();
                pr = [Select Id, Name, ownerId, Parent_Incident__c, BMCServiceDesk__Problem_Description__c, BMCServiceDesk__FKStatus__c, BMCServiceDesk__FKUrgency__c, BMCServiceDesk__FKPriority__c, BMCServiceDesk__FKImpact__c, BMCServiceDesk__FKCategory__c from  BMCServiceDesk__Problem__c WHERE Id =: probId LIMIT 1];
                
                if(pr.size() > 0 )
                {
                for(BMCServiceDesk__Problem__c prob : pr)
                        {
                        tsk.BMCServiceDesk__taskDescription__c = prob.BMCServiceDesk__Problem_Description__c;
                        tsk.BMCServiceDesk__FKUrgency__c = prob.BMCServiceDesk__FKUrgency__c;
                        tsk.BMCServiceDesk__FKPriority__c = prob.BMCServiceDesk__FKPriority__c;
                        tsk.BMCServiceDesk__FKProblem__c = prob.Id;
                        tsk.BMCServiceDesk__FKClient__c = prob.ownerId;
                        tsk.BMCServiceDesk__FKImpact__c = prob.BMCServiceDesk__FKImpact__c;
                        tsk.RecordTypeId = Schema.SObjectType.BMCServiceDesk__Task__c.getRecordTypeInfosByName().get('Problems Task').getRecordTypeId();
                        //setting created date
                        tsk.BMCServiceDesk__createdOn__c = Datetime.now();
                        } 
                
                tsk1 = tsk;
                }//if(pr.size() > 0 )
                }//if( String.valueOf(probId).length() > 0 )
        }//if(currentURL.contains('^https:[\\D\\w\\d]*(.salesforce.com)[\\D]*(HDProblemTaskPage)[?](probid=)'))
        else
        {
                        tsk1 = new BMCServiceDesk__Task__c();
        }//else
        

}//Constructor

public Pagereference saveIt()
{
        try{
        insert tsk1;
            }
        catch (exception e)
        {
                 
        tsk1.addError( e.getMessage() );
        pr[0].AddError('Error saving');
                
        }
        return new Pagereference('');
}//saveIt()


}