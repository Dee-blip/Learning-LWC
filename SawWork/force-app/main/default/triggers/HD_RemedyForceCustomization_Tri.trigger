/*
* New Trigger Updates : streamlined Code for easy debug, onplace query calls
* all the logic covered, we removed some redudant code
* version : 1.0
* date: 31-OCT-2017
* Object: incident
* Test class : HD_Test_RemedyforceCustomizationTest
* class associated : HD_RemedyForceCustomization_class
*/
trigger HD_RemedyForceCustomization_Tri on BMCServiceDesk__Incident__c
( before insert, after insert,
  before update, after update) {
  
//any intialization parameter
  public static Boolean throwMappingError = false;
  public static boolean runTrigger = false;


  public static Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
  if (gd.containsKey('HD_RF_TRIGGER_FLAG__c')) { 
     HD_RF_TRIGGER_FLAG__c HD_RemedyForceCustomization_Tri_run_flag = HD_RF_TRIGGER_FLAG__c.getInstance('HD_RemedyForceCustomizations');
     if (HD_RemedyForceCustomization_Tri_run_flag != null && HD_RemedyForceCustomization_Tri_run_flag.Enable__c == true) {
      System.debug('new trigger is suppressed');
         return;
    } else {
      System.debug('running new trigger');
    }
  }
  else {
    System.debug('Running new trigger');
    
  }

  //specific testrunning and Managed package error skip check
  if (Test.isRunningTest() && ManagedPkgErrorClass.isFromManagedPackage || HD_RestrictedAccess.SKIP_TRIGGER == true) {
    return ;

  }

  if (Trigger.isInsert) {
    System.debug('------> Running HD_RemedyForceCustomization_Tri Insert Procedures');
    HD_RemedyForceCustomization_class hdremedyclass = HD_RemedyForceCustomization_class.getInstance(Trigger.new, Trigger.old, true);
    if (Trigger.isBefore) {
      //
      //
      hdremedyclass.markVIPFlagOnTickets();  //kartikeya
      hdremedyclass.defaultAccount();             //hemant
      //hdremedyclass.priorityUrgencySyncLogic();   //kartikeya
      hdremedyclass.newPriorityUrgencyLogic();
      hdremedyclass.stampImpactAndManager(); //kartikeya
      hdremedyclass.updateBusinessServiceByUrgency();               //Hemant
      hdremedyclass.ccFunctionalityandCheck();    //Hemant
      hdremedyclass.customerImpactPageSupportpopup(); //Hemant
      hdremedyclass.srINPrioritySync();           //Hemant
      hdremedyclass.lastUpdatedDateTime();        //Kartikeya
      hdremedyclass.clearResolutionForCloning();    //komal
      hdremedyclass.stampVPApproverForSR();  //Kartiekya
      //hdremedyclass.changeFreeStatusToAssigned(); //Pranav
      hdremedyclass.stampIncidentGroup();
      //hdremedyclass.addReadAccess();
      
      if (!(system.isBatch() || system.isFuture())) {
        
        //hdremedyclass.addReadAccess();
      }
    }//if(Trigger.isBefore)
    else if (Trigger.isAfter) {
      //future method accept only prmitive data as an argument.
      //incIds get all the ticket id in current transaction
      List<Id> incIds = new List<ID>();
      for (BMCServiceDesk__Incident__c inc : Trigger.new) {
        incIds.add(inc.id);
      }
      
      //futrue method cannot be called under future context.
      //this checks the trigger from being recursively.
      if (!(system.isBatch() || system.isFuture())) {
        //HD_RemedyForceCustomization_class.cascadeParentfieldsToChildsTest(incIds);
      }

      //added by jay for CR 2627751 and CR  2824410
      ServiceIncidentAgeCalculator.startCapturingStatusAge(trigger.newmap);

    }//else if(Trigger.isAfter)
    System.debug('1. Number of Queries used in this Apex code so far: ' + Limits.getQueries());
  }//if(Trigger.isInsert)
  else if (Trigger.isUpdate) {
    System.debug('------> Running HD_RemedyForceCustomization_Tri Update Procedures');
    HD_RemedyForceCustomization_class hdremedyclass = HD_RemedyForceCustomization_class.getInstance(Trigger.new, Trigger.old, false);
    if (Trigger.isBefore) {



      hdremedyclass.markVIPFlagOnTickets();
      hdremedyclass.checkForValidReopen();
      //hdremedyclass.priorityUrgencySyncLogic();   //kartikeya
      hdremedyclass.newPriorityUrgencyLogic();
      hdremedyclass.stampImpactAndManager();
      hdremedyclass.updateBusinessServiceByUrgency();
      hdremedyclass.ccFunctionalityandCheck();
      hdremedyclass.customerImpactPageSupportpopup();
      hdremedyclass.srINPrioritySync();
      hdremedyclass.lastUpdatedDateTime();
      hdremedyclass.stampIncidentGroup();
      //hdremedyclass.trackUpdates();
      //hdremedyclass.restrictReopen();     //Bhaskar - Tested
      //only update action on below method
      //hdremedyclass.changeTicketToAssignedWhenReopened();
      /*
      Author: Samir Jha
      Release: 3.44 (25/7/2014)
      Purpose: Service Incidents CR: 2026963 : SI: Notify incident managers of items assigned to them
      */
      SI_UpdateSIOwnerAndLastOwner.SI_UpdateSIOwnerAndLastOwner(Trigger.New, Trigger.OldMap);

      //Start of CR 3066261 - Need a flag to identify if an incident is assigned within region or not
      hdremedyclass.incidentAssignedtoSameRegion();  //Hemant
      hdremedyclass.restrictReopenBeforeChanges();
      //hdremedyclass.checkEffortEstimate(); //Bhaskar
      hdremedyclass.changeFreeStatusToAssigned();    //Pranav
      hdremedyclass.stampVPApproverForSR();  //Kartikeya
      
      if (!(system.isBatch() || system.isFuture())) {
        hdremedyclass.addReadAccess();
      }
      
    }//if(Trigger.isBefore)
    else if (Trigger.isAfter) {
      // hdremedyclass = HD_RemedyForceCustomization_class.getInstance(Trigger.new,Trigger.old,false);
      //hdremedyclass.cascadeParentfieldsToChilds();
      //hdremedyclass.newHireOnboarding();

      hdremedyclass.aferUpdateRestrictReopen();

      //future method accept only prmitive data as an argument.
      //incIds get all the ticket id in current transaction
      List<Id> incIds = new List<ID>();
      for (BMCServiceDesk__Incident__c inc : Trigger.new) {
        incIds.add(inc.id);
      }
      

      //futrue method cannot be called under future context.
      //this checks the trigger from being recursively.
      if (!(system.isBatch() || system.isFuture()) && HD_CheckRecursive.revokeOnce()) {
        hdremedyclass.revokeAccess();
        //HD_RemedyForceCustomization_class.cascadeParentfieldsToChildsTest(incIds);
      }

      //Service Incident Logic
      if (si_triggerclass.statusChangedTracked == false) {
        //added by jay for CR 2627751 and CR  2824410
        ServiceIncidentAgeCalculator.calculateServiceIncidentAge(trigger.oldmap, trigger.newmap);

        //recurrence check.
        si_triggerclass.statusChangedTracked = true;
      }//if(si_triggerclass.statusChangedTracked == false)
        
    }//else if(Trigger.isAfter)

  }//else if(Trigger.isUpdate)
  System.debug('2. Number of Queries used in this Apex code so far: ' + Limits.getQueries());
  System.debug('------> Stopped Running HD_RemedyForceCustomization_Tri New Trigger');
}//trigger END