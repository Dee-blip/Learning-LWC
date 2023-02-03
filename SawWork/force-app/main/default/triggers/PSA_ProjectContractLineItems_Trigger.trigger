/***
    PSA_ProjectContractLineItems_Trigger
    @author Liz Ichihashi
    @Description : This trigger calls methods in the Action class 
  @History
  --Developer          --Date       --Change
  Liz Ichihashi        7/04/2013    Created the class.    
  Liz Ichihashi        9/09/2013    Changes for enforcing one project contract line item per project.       
  Samir Jha            6/27/2014    Commented the Code to facilitate the CR 2589321
  Sharath Prasanna    31/03/2015    Changed the trigger to call a function in after insert block  
  Sujay         06 Dec 2019   Adding changes for PS Overages phase1 to create a fresh Overage Record when CLI association is changed.
  */
trigger PSA_ProjectContractLineItems_Trigger on Project_Contract_Line_Item__c (before insert, after insert, before delete, after delete)
 {
  if (trigger.isBefore) 
  {
    if (trigger.IsInsert) 
    {
      //PCLI can be Added using "Add/Remove Project Contract Line Items" from the Project View page.
      PSA_ProjectContractLineItemActions.checkForInvalidCreate(trigger.new);
    }
    else if (trigger.IsDelete) 
    {
      //PSA_ProjectContractLineItemActions.checkForMilestonesOrAssignmentsBeforeDelete(trigger.oldMap);
      //PCLI can be deleted using "Add/Remove Project Contract Line Items" from the Project View page.
      PSA_ProjectContractLineItemActions.checkForInvalidDelete(trigger.old);
    }
  } 
  else 
  {
   //Samir Jha -- Date: 6/27/2014 -- Commented the Code to facilitate the CR 2589321
    if (trigger.IsDelete) 
    { 
    //Trigger Operation : after delete -> Query the PC and PCLI and check the Valid Delte Flag -> update and delete.
      PSA_ProjectContractLineItemActions.checkForProjectContactsToDeleteAfterLineDelete(trigger.old);
    //Trigger Operation : after delete -> Query all Project with Its PCLI and set the Project's BillingEffectiveDate with CLI Start Date if there is a Diff/ set BED to null if there is no PCLI.
      PSA_ProjectContractLineItemActions.checkForBillingEffectiveDateUpdateOnProjContLineItemDelete(trigger.old);
      if (Trigger.isAfter && Trigger.isDelete) {
        PSA_ProjectContractLineItemActions.trackCLIDisAssociation(Trigger.old);
      }
    } 
    else if (trigger.IsInsert)
    {
      PSA_ProjectContractLineItemActions.checkForAssignmentsToAssociate(trigger.new);
      
      // start of changes by Vandhana for CR
      PSA_ProjectContractLineItemActions.updateProjectContractLineItem(trigger.new);
      // end of changes by Vandhana
      
      PSA_ProjectContractLineItemActions.updateProjectContractClosed(trigger.new);
      
      // Start of changes by shprasan for CR - 2941958
      // Fetch all the CLIs that are assoiated before this new PCLI Insertion and delete the older PCLIs
      PSA_ProjectContractLineItemActions.doLineItemCleanUp(trigger.new);
      //End of changes by shprasan for CR - 2941958

      if(!system.isBatch() && !system.isFuture() && !system.isScheduled())
      {
          PSA_ProjectContractLineItemActions.recalculatePSHours(trigger.newMap); 
          // Changes by Suhas for FFPSA-545  
      }
      
      if(Trigger.isAfter && Trigger.isInsert)
      {
          PSA_ProjectContractLineItemActions.createOverageData(Trigger.new);
          PSA_ProjectContractLineItemActions.trackCLIAssociation(Trigger.newMap);
      }
    }//end of Trigger Insert
      
  }//end of else
     
}//end of Trigger