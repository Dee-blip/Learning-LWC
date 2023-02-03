/*
Template: Apex Class/Trigger Template

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : used as apart of requirment for Problem Managment

Purpose : an implementation for trigger HD_Problem_Customization.trigger
          
Usage : used as an implementation for the business logic , for trigger HD_Problem_Customization.trigger
          
Test Class Asssociated : HD_Test_Problem_Customization_tri

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Class Associated : HD_RF_Cust_tri_code.cls
              
*/

trigger HD_Problem_Customization on BMCServiceDesk__Problem__c (after insert, after update, before insert,before update) {

//GLOBAL VARIABLES
public static HD_RF_Cust_tri_code triClass = null;



//defining the full block for context variable ,insert & update block combination actions
if(trigger.isInsert || trigger.isUpdate)
{
    // getting Current version of object
triClass = HD_RF_Cust_tri_code.getInstance(trigger.new);
if(trigger.isBefore)
{

System.debug('--------> Executing Before Insert/update');
// Calling HD_RF_Cust_tri_code.cls method
triClass.dataRectifiaction_beforeInsert();

HD_RF_Cust_tri_code.parentIncidentLinkageValidation(trigger.new, trigger.old);
HD_RF_Cust_tri_code.updateStatusToKnowError(trigger.new, trigger.old);

//Starting Code for Incident to Problem
HD_RF_Cust_tri_code.updateProblemOnParentIncidentLink(trigger.new,trigger.old);

//Here exclusivly looking at update contex variable 
if(trigger.isUpdate)
{
    HD_RF_Cust_tri_code.priorValuesetter( trigger.old );
}//

//setting status on root cause Update
HD_RF_Cust_tri_code.UpdateStatusOnRootCauseAdd(trigger.new, trigger.old);
/*
*purpose@ This method is used in status picklist value logic in Problem Managment
*addresses@  CR 2610408 - Problem Mgmt - Change field type for Status & Service 
*@Developer Hemant Kumar
*@Date: 15-jul-2014
*@usage : Use it before Insert and update
*/
    if( HD_CheckRecursive.runOnce() ) 
    {
HD_RF_Cust_tri_code.statusPickListLogic(trigger.new, trigger.old);
    }//
}//if(trigger.isBefore)


}//if(trigger.isInsert || trigger.isUpdate)

if(trigger.isAfter)
{
if( trigger.isUpdate )
{
    //START of Changed as a part of CR 2610705 - Problem Mgmt - Email templates should be consistents
    for( BMCServiceDesk__Problem__c newIns : trigger.new)
    {
    if( newIns.BMCServiceDesk__Status__c != 'CLOSED' )
    {
    HD_RF_Cust_tri_code.smeEmailSender(trigger.new);
    }//if( newIns.BMCServiceDesk__Status__c != 'CLOSED' )
    }//for( BMCServiceDesk__Problem__c newIns : trigger.new)
    //END of Changed as a part of CR 2610705 - Problem Mgmt - Email templates should be consistents
    
}//if( trigger.isUpdate )

/*
*purpose@ This method is used problem Incident link in Problem Managment
*addresses@  CR 2656731 - Problem Mgmt - Parent Incident not showing linked problems 
*Developer@ Hemant Kumar
*usage@ Use it After Insert , can be used before and after update
*Date: 10-jul-2014 
*/
if(trigger.isInsert || trigger.isUpdate)
{
    System.debug(' Recursive check ----->'+HD_CheckRecursive.runOnce());
    if( HD_CheckRecursive.runOnce() )
    {
    HD_RF_Cust_tri_code.insertIncidentProblemLink();
    }
    else
    {
    HD_RF_Cust_tri_code.insertIncidentProblemLink();
    }
}//if(trigger.isInsert || trigger.isUpdate)

}//if(trigger.isAfter)
}//trigger ENDs