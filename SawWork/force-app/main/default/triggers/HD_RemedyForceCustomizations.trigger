/** Requirements :
    1.  Display Alert when an Incident is assigned to a staff who is in different timezone than the current assignee.
        Alert message includes "the staff is in another timezone and will be not in office for another X hours".
        EVENT: BEFORE INSERT, BEFORE UPDATE

    2.  Update 'Service' in Incident corresponding to the Urgency selected.
        EVENT: BEFORE INSERT; BEFORE UPDATE

    3.  In an Incident if category = 'Additional Desktop/Laptop',
        3a. Update Approver info in HD_VP_Approver__c field of Incident ON EVENT BEFORE INSERT, BEFORE UPDATE
        3b. Send incident record for approval to VP of the Client ON EVENT AFTER INSERT, AFTER UPDATE

    4.  Update template name in Incident whenever a template is applied on an incident.
        EVENT: BEFORE INSERT, BEFORE UPDATEstat

    5.  Account to be set default for every Incident.
        EVENT: BEFORE INSERT,
        Impact to be set default for every incident.
        EVENT: BEFORE INSERT, BEFORE UPDATE

    6.  New Hire/Termination Request: Create 3 child Incidents for Incident created with 'hardware' category.
        EVENT : AFTER INSERT

//CR 2146240 - parent incident can be closed independently of child incidents and parent will not be auto closed when child incidents are all closed
    7. Close New Hire/Termination Request:
        - Parent incident should not be allowed to closed unless and untill all child incidents are closed.
        - Auto-close incident when all child incidents are closed.
        EVENT: AFTER UPDATE
//CR 2146240
//
//CR 2627751 and CR  2824410  - SI metric capture , change of status and change of owner tracked.  (jay)
//

**/

trigger HD_RemedyForceCustomizations on BMCServiceDesk__Incident__c (Before Insert, after insert, Before Update, after update) {
    if(Trigger.isBefore)
    {
        if(Trigger.isInsert)
        {
            System.debug('Testing old trigger');
        }
    }
    
//   public static Boolean throwMappingError = false;
//   public static String recordTypeIdSI;

//   public static Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
//   if (gd.containsKey('HD_RF_TRIGGER_FLAG__c')) { 
//      System.debug('inside old trigger logic');
//      HD_RF_TRIGGER_FLAG__c HD_RemedyForceCustomization_Tri_run_flag = HD_RF_TRIGGER_FLAG__c.getInstance('HD_RemedyForceCustomizations');
//      if (HD_RemedyForceCustomization_Tri_run_flag != null && HD_RemedyForceCustomization_Tri_run_flag.Enable__c == true) {
//       System.debug('running old trigger');
         
//     } else {
//       System.debug('old trigger is suppressed');
//       return;
//     }
//   }
//   else {
//     System.debug('old trigger is suppressed');
//     return;
//   }

// /*
//   Boolean isRoleConfigured = false;
//   Boolean runNewTrigger = false;

//   public static Boolean isValidId(String Idparam) {
//     String id = String.escapeSingleQuotes(Idparam);
//     if ((id.length() == 15 || id.length() == 18) && Pattern.matches('^[a-zA-Z0-9]*$', id)) {
//       return true;
//     }
//     return false;
//   }

//   Id currentUserRoleId = System.UserInfo.getUserRoleId();
//   //List<HD_RF_TRIGGER_FLAG__c> roleSettings = [select name, Role_Id__c, Run_New_Trigger__c from HD_RF_TRIGGER_FLAG__c];
//   List<HD_RF_TRIGGER_FLAG__c> roleSettings = HD_RF_TRIGGER_FLAG__c.getAll().values();
//   for (HD_RF_TRIGGER_FLAG__c role : roleSettings) {
//     if (role.Role_Id__c != null && isValidId(role.Role_Id__c) && currentUserRoleId == (Id)role.Role_Id__c) {
//       isRoleConfigured = true;
//       runNewTrigger = role.Run_New_Trigger__c;
//       break;
//     }
//   }


//   System.debug('Old -- isRoleConfigured ' + isRoleConfigured);
//   System.debug('Old -- runNewTrigger ' + runNewTrigger);
//   if (isRoleConfigured && runNewTrigger ) {
//     return;
//   } else {
//     System.debug('------> Running HD_RemedyForceCustomizations Old Trigger');
//     System.debug('run old trigger');
//   }*/


//   private static Map<ID, BMCServiceDesk__Incident__c>  incidentOldValueMap = new Map<ID, BMCServiceDesk__Incident__c>();
//   private static Map<ID, BMCServiceDesk__Incident__c>  incidentNewValueMap = new Map<ID, BMCServiceDesk__Incident__c>();

//   private static Map<String, BMCServiceDesk__Status__c> statusMap = new Map<String, BMCServiceDesk__Status__c>();
//   private static Map<String, BMCServiceDesk__Category__c> categoryMap = new Map<String, BMCServiceDesk__Category__c>();
//   private static Map<Id, BMCServiceDesk__Category__c> categoryIDMap = new Map<Id, BMCServiceDesk__Category__c>();

//   private static Map<String, Group> groupNameMap  = new Map<String, Group>();
//   private static Map<Id, Group> groupIDMap  = new Map<Id, Group>();
//   private static Map<id, user> vpUserMap = new Map<id, user>();

//   private static Map<String, BMCServiceDesk__Priority__c> priority_map = new Map<String, BMCServiceDesk__Priority__c>();


//   if (Test.isRunningTest() && ManagedPkgErrorClass.isFromManagedPackage || HD_RestrictedAccess.SKIP_TRIGGER == true) {
//     return ;

//   }



//   recordTypeIdSI = Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Service Incident').getRecordTypeId();



//   private static List<BMCServiceDesk__Category__c> categoryList = [Select Name, id, RA_Category_Group__c, RA_Config_Value__c, RA_Secondary_Queue__c, Service_Owner__c, BMCServiceDesk__categoryType_Id__c, Valid_Days_to_Reopen__c, Follows_Restrictive_Reopen__c   FROM BMCServiceDesk__Category__c WHERE BMCServiceDesk__inactive__c = false limit 3000];

//   //Fetch Closed status applicable for Incident
//   for ( BMCServiceDesk__Status__c status : [select Id, Name from BMCServiceDesk__Status__c where BMCServiceDesk__appliesToIncident__c = true]) {
//     statusMap.put(status.Name, status );
//   }
//   //GEtting group  List
//   for ( Group grp : [Select id, name from group where name = 'VIP Users' OR Type = 'Queue' LIMIT 5000]) {
//     groupNameMap.put(grp.name, grp);
//     groupIDMap.put(grp.id, grp);
//   }

//   //START of Code Update for CR 2960174 by Hemant for priority not working for due date

//   private static List<BMCServiceDesk__Priority__c> priority_List = [Select id , Name, BMCServiceDesk__urgency_Id__c , BMCServiceDesk__FKUrgency__c, BMCServiceDesk__impact_Id__c, BMCServiceDesk__FKImpact__c from BMCServiceDesk__Priority__c LIMIT 100];
//   if (priority_List.size() > 0 ) {
//     for (BMCServiceDesk__Priority__c prio : priority_List) {
//       priority_map.put(prio.Name, prio);
//     }//for(BMCServiceDesk__Priority__c prio : priority_List)
//   }// if(priority_List.size()> 0 )
//   //END of Code Update for CR 2960174 by Hemant for priority not working for due date


//   //Prepare Category Map with Key as category Name
//   if (categoryList.size() > 0) {
//     for (BMCServiceDesk__Category__c category : categoryList) {
//       categoryMap.put(category.Name, category);
//       categoryIDMap.put(category.id, category);
//     }

//   }//if(categoryList.size()>0)

//   If(trigger.IsUpdate) {
//     //****5. Parent not allowed to close if at-least 1 child is in Open State
//     incidentOldValueMap = Trigger.oldMap;
//     //statusList = [select Id from BMCServiceDesk__Status__c where BMCServiceDesk__appliesToIncident__c = true AND BMCServiceDesk__defaultStatus__c = true AND BMCServiceDesk__state__c = false];
//   }// End IsUpdate



//   If(trigger.IsBefore) {

//     List<ID> ReDefIds = new List<Id>();
//     Map<ID, BMCServiceDesk__SRM_RequestDefinition__c> ReqDefns = new Map<ID, BMCServiceDesk__SRM_RequestDefinition__c>();
//     for (BMCServiceDesk__Incident__c incident : Trigger.new) {
//       if ( incident.BMCServiceDesk__Type__c == 'Service Request' || incident.HD_Test_Value__c == 'Service Request') {
//         ReDefIds.add(incident.BMCServiceDesk__FKRequestDefinition__c);
//         //List <BMCServiceDesk__SRM_RequestDefinition__c>
//       }
//     }
//     ReqDefns = new  Map<Id, BMCServiceDesk__SRM_RequestDefinition__c>([Select id, VP_Approver_Required__c FROM  BMCServiceDesk__SRM_RequestDefinition__c  where ID = :ReDefIds ]);


//     List<Account> AccountList;//move to isBefore // need to be dicussed
//     List<BMCServiceDesk__Impact__c> ImpactList;  //move to isBefore

//     /*
//     Author: Samir Jha
//     Release: 3.44 (25/7/2014)
//     Purpose: Service Incidents CR: 2026963 : SI: Notify incident managers of items assigned to them
//     */
//     If(trigger.IsUpdate) { // recordType for SI
//       SI_UpdateSIOwnerAndLastOwner.SI_UpdateSIOwnerAndLastOwner(Trigger.New, Trigger.OldMap);
//     }


//     //***2 Urgency-Service mapping
//     Map<ID, ID> urgencyServiceMap = new Map<ID, ID>();

//     //   Create Urgency Service Map
//     for (HD_Urgency_Service_Mapping__c urgencyServiceMapping : [SELECT HD_Service__c, HD_Urgency__c FROM HD_Urgency_Service_Mapping__c ]) {
//       urgencyServiceMap.put(urgencyServiceMapping.HD_Urgency__c, urgencyServiceMapping.HD_Service__c);
//     }




//     //Adding if statement as a solution to 50001 error encountered in QA testing in Sept '16
//     if (HD_CheckRecursive.runOnce()) {
//       System.debug('runOnce is true');
//       // Fetch all the user
//       vpUserMap = new Map<id, user>([Select id, name, managerId, Title from User where IsActive = true and username LIKE '%akamai.com%'
//                        limit 50000]); // move before and null and empty check
//     }//if

//     //Start of changes by Samir
//     // Map<id,user> ManagerUserMap = new Map<id,user>([Select id ,name,managerID from User where IsActive=true]);
//     //Fetch Account 'Akamai Helpdesk'
//     //fetch Impact 'LOW'
//     //Start of changes by Samir for CR 1899370
//     If(trigger.IsInsert) {
//       HD_Default_Custom_Setting__c Defaults = HD_Default_Custom_Setting__c.getInstance('DEFAULT VALUES'); // define top most line 193
//       String Default_account_RF;
//       //Default_account_RF=Defaults.Default_Account__c;
//       Default_account_RF = 'Akamai Helpdesk';
//       AccountList = [Select id from Account where Name = :Default_account_RF];    // need to be dicussed


//       //Kartikeya - SLA Bug PRTORES-520 Stamping Incident Group Field.
//       for (BMCServiceDesk__Incident__c incident : Trigger.new) {
//         if (incident.HD_Routing_Settings__c == 'Override Routing') {

//           BMCServiceDesk__Category__c cat =  categoryIDMap.get(incident.BMCServiceDesk__FKCategory__c);
//           if (cat != null)
//             incident.HD_IncidentGroup__c = cat.BMCServiceDesk__categoryType_Id__c;

//           // When staff users creates incident with Override routing ticket is assigned to user who created the incident.
//           //incident.BMCServiceDesk__FKStatus__c=statusMap.get('ASSIGNED').id;

//         }
//       }//END  PRTORES-520


//     }// End IsInsert
//     If(trigger.IsInsert || trigger.IsUpdate) {
//       HD_Default_Custom_Setting__c Defaults = HD_Default_Custom_Setting__c.getInstance('DEFAULT VALUES'); // define top most line 184
//       String Default_impact_RF;
//       //Default_impact_RF=Defaults.Default_Impact__c;
//       Default_impact_RF = 'LOW';
//       ImpactList = [Select id from BMCServiceDesk__Impact__c where Name =  :Default_impact_RF]; // need to minimize
//     }
//     //End of change of code by Samir for CR 2012518:Changing the Status to Assigned
//     //End of changes by Samir for CR 1899370

//     //Start Changes by Sebi for CR 2085994
//     List<GroupMember> VIPUserList;
//     List<ID> user_ids = new List<ID>();

//     for (BMCServiceDesk__Incident__c incident : Trigger.new) {
//       if (Trigger.IsInsert || (Trigger.isUpdate && incident.BMCServiceDesk__FKClient__c != incidentOldValueMap.get(incident.id).BMCServiceDesk__FKClient__c) ) {
//         String VIP_Group_id ; //outside loop
//         //VIP_Group_id = [Select id from group where name = 'VIP Users'].id ;
//         VIP_Group_id = groupNameMap.get('VIP Users').id; //outside loop
//         VIPUserList = [Select USERORGROUPID from GroupMember where GroupMember.GROUPID = :VIP_Group_id] ; //wrong query in side loop
//         if (VIPUserList.size() > 0) {
//           for (GroupMember gm : VIPUserList) {
//             if (gm.USERORGROUPID == incident.BMCServiceDesk__FKClient__c) {
//               incident.VIP_Ticket__c = true ;
//             }
//           }
//         }
//         System.debug('incident.VIP_Ticket__c -->' + incident.VIP_Ticket__c);
//         //Kartikeya - CR 2673795 - VIP ticket logic not accurate
//         user_ids.add(incident.BMCServiceDesk__FKClient__c);
//         System.debug('user_ids-->' + user_ids);

//       }
//     }//for
//     // End Changes by Sebi for CR 2085994



//     //Kartikeya - CR 2673795 - VIP ticket logic not accurate
//     if (user_ids.size() > 0) {

//       Map<id, String> userTitleMap = new Map<id, String>();
//       Map<String, HD_VIP_Titles__c> VipTitles = HD_VIP_Titles__c.getAll();

//       for (User usr :  [Select Title, Id from user where ID In :user_ids]) { // useless query use map above vpUsermaps
//         userTitleMap.put(usr.id, usr.Title);
//       }

//       for (BMCServiceDesk__Incident__c incident : Trigger.new) {

//         String title =  userTitleMap.get(incident.BMCServiceDesk__FKClient__c);

//         for (HD_VIP_Titles__c VipTitle : VipTitles.values()) {
//           if (incident.RecordTypeId != recordTypeIdSI && title != null) {
//             if ( title.toLowercase().contains(VipTitle.Name.toLowercase()) ) {
//               incident.VIP_Ticket__c = true ;
//               break;
//             }
//           }
//         }
//       }
//     }//if user_ids.size()

//     //end Kartikeya - CR 2673795 - VIP ticket logic not accurate





//     Integer i = 0;
//     // BMCServiceDesk__Category__c[] cat = [Select Id,Service_Owner__c from BMCServiceDesk__Category__c where service_owner__c != null and BMCServiceDesk__inactive__c != true];

//     for (BMCServiceDesk__Incident__c incident : Trigger.new) {
//       if (incident.RecordTypeId != recordTypeIdSI) {
//         if (Trigger.isInsert) {

//           //Set Account to 'Akamai Helpdesk'
//           if (AccountList != null && AccountList.size() > 0) { // need to be dicussed
//             incident.BMCServiceDesk__FKAccount__c = AccountList[0].id; // need to be dicussed
//           }//if(AccountList != null && AccountList.size() > 0)



//         }//if(Trigger.isInsert)
//         // Close incident if Recject checkbox is checked i.e. Approval has been rejected


//         // Priorty-Urgency Sync  - Kartikeya- CR 2614449
//         //Stamps Urgency and Priority values depends on the input contains value for Priority/Urgency
//         //Throws error as priority not found if  Urgency or Priority both values not present.
//         String old_urgency = incident.BMCServiceDesk__FKUrgency__c;
//         String old_priority = incident.HD_Ticket_Priority__c;
//         if ( Trigger.isUpdate) {

//           old_urgency =  Trigger.old[i].BMCServiceDesk__FKUrgency__c;
//           old_priority = Trigger.old[i].HD_Ticket_Priority__c;
//           i++;

//         }



//         if ( ( Trigger.isInsert && String.isNotBlank(incident.HD_Ticket_Priority__c) ) || ( Trigger.isUpdate && incident.HD_Ticket_Priority__c != old_priority) ) {

//           HD_Ticket_Priority__c ticket_priority = HD_Ticket_Priority__c.getInstance(incident.HD_Ticket_Priority__c);
//           incident.BMCServiceDesk__FKUrgency__c = ticket_priority.Urgency_Id__c;

//           if (ticket_priority.Priority_Id__c != NULL && ticket_priority.Priority_Id__c.trim() != '')
//             incident.BMCServiceDesk__FKPriority__c = ticket_priority.Priority_Id__c;

//         } else if (( Trigger.isInsert && String.isNotBlank(incident.BMCServiceDesk__FKUrgency__c)) ||  (Trigger.isUpdate && (incident.BMCServiceDesk__FKUrgency__c != old_urgency || String.isBlank(incident.HD_Ticket_Priority__c) ))) {

//           Map<String, HD_Ticket_Priority__c> allPriorityMap = HD_Ticket_Priority__c.getAll() ;
//           for (HD_Ticket_Priority__c priority_setting : allPriorityMap.values() ) {

//             if (priority_setting.Urgency_Id__c == incident.BMCServiceDesk__FKUrgency__c ) {
//               incident.HD_Ticket_Priority__c  = priority_setting.Name;

//               if (priority_setting.Priority_Id__c != NULL && priority_setting.Priority_Id__c.trim() != '')
//                 incident.BMCServiceDesk__FKPriority__c = priority_setting.Priority_Id__c;

//               break;
//             }



//           }

//         }

//         if (incident.BMCServiceDesk__contactType__c == 'Mail Listen' && String.isBlank(incident.BMCServiceDesk__FKUrgency__c) ) {

//           HD_Ticket_Priority__c ticket_priority = HD_Ticket_Priority__c.getInstance('default');
//           incident.HD_Ticket_Priority__c = ticket_priority.Priority_Name__c;
//           incident.BMCServiceDesk__FKUrgency__c  = ticket_priority.Urgency_Id__c;

//           if (ticket_priority.Priority_Id__c != NULL && ticket_priority.Priority_Id__c.trim() != '')
//             incident.BMCServiceDesk__FKPriority__c = ticket_priority.Priority_Id__c;


//         }

//         if (String.isBlank(incident.HD_Ticket_Priority__c)) {

//           incident.addError('Priority is mandatory. Please select a value from Priority list');

//         }

//         // End of Priorty-Urgency Sync  - Kartikeya -CR 2614449


//         //start of changes by SAMIR:CR 1903861
//         if (Trigger.isInsert || Trigger.isUpdate) {


//           //Set Impact to 'LOW'
//           if (ImpactList != null && ImpactList.size() > 0) {
//             if (incident.BMCServiceDesk__FKImpact__c == null) {
//               incident.BMCServiceDesk__FKImpact__c = ImpactList[0].id;
//             }
//           } //can be replaced in one place for populating impact

//           Schema.DescribeSObjectResult userObject1 = User.SObjectType.getDescribe(); // To get prefix of the User object.
//           String prefix1 = userObject1.getKeyPrefix();

//           // altered code by hemant for CR 2341731 - Optimizing Helpdesk TestClases
//           // BMCServiceDesk__Category__c[] cat = [Select Id,Service_Owner__c from BMCServiceDesk__Category__c where service_owner__c != null and BMCServiceDesk__inactive__c != true];


//           for (BMCServiceDesk__Incident__c incident1 : Trigger.new) {

//             //CR 2545230 Start - by Kartikeya

//             Incident1.Last_Updated_Date_Time__c = System.now();


//             //CR 2545230 End

//             // Added code for CR 2127376: Kartikey
//             // Stamping Service owner of Category to the incident service owner.
//             //  with the excluding condition where incident created without a category (bug fix CR 2158121 Date:28 march 2013.
//             if (Incident1.BMCServiceDesk__FKCategory__c != null) {
//               // Incident1.Category_Service_Owner__c =[Select Id,Service_Owner__c from BMCServiceDesk__Category__c where Id=:Incident1.BMCServiceDesk__FKCategory__c].Service_Owner__c;
//               /*
//               for( BMCServiceDesk__Category__c c1 : cat)
//               {
//                if(c1.id == incident1.BMCServiceDesk__FKCategory__c)
//                {
//                 Incident1.Category_Service_Owner__c = c1.Service_Owner__c;
//                 break; // added by Hemant kumar to remove unnecessary iteration
//                }
//                }
//                */
//               //updating the logic for Service Owner stamping
//               if ( categoryIDMap.containsKey(incident1.BMCServiceDesk__FKCategory__c) ) {
//                 Incident1.Category_Service_Owner__c = categoryIDMap.get(incident1.BMCServiceDesk__FKCategory__c).Service_Owner__c;
//               }



//             }
//             //End of CR 2127376






//             User owner_incident = vpUserMap.get((incident1).ownerid);
//             User Ownermanager = vpUserMap.get((incident1).ownerid); //need to remove from the code
//             if (prefix1 == (String.valueof(incident1.ownerid).substring(0, 3))) {
//               if (vpUserMap.containsKey((incident1.ownerid))) {
//                 Incident1.HD_owner_manager__c = owner_incident.ManagerId;

//               }
//             } else {
//               Incident1.HD_owner_manager__c = null;
//               //Samir added code for CR 2012518:Changing the Status to Assigned

//             }
//           }
//         }//if (Trigger.isInsert || Trigger.isUpdate)




//         //Samir added code for CR 2012518:Changing the Status to Assigned
//         If(trigger.IsUpdate) {
//           //MAP for triggering solution enablement team selective status free change
//           Map<String, string> freeStatusEnablementMap = new Map<String, String>(); // add specific queue name to disable status reset logic
//           //pranav - commenting as a part of SET changes. Having conflict and not required
//           //Jira Ticket - PRTORES-163/ PRTORES-164/ PRTORES-165
//           //freeStatusEnablementMap.put('Solution Enablement Team','Solution Enablement Team'); //Solution Enablement Team
//           //freeStatusEnablementMap.put('Solution Center – Cambridge','Solution Center – Cambridge'); //Solution Center – Cambridge
//           //freeStatusEnablementMap.put('Solution Center – Bangalore','Solution Center – Bangalore'); //Solution Center – Bangalore
//           //freeStatusEnablementMap.put('Solution Center – Reston','Solution Center – Reston'); //Solution Center – Reston
//           //freeStatusEnablementMap.put('Solution Center - Ft. Lauderdale','Solution Center - Ft. Lauderdale'); //Solution Center - Ft. Lauderdale
//           //freeStatusEnablementMap.put('Solution Center - San Francisco','Solution Center - San Francisco'); //Solution Center - San Francisco
//           //freeStatusEnablementMap.put('Solution Center – Krakow','Solution Center – Krakow'); //Solution Center – Krakow
//           //freeStatusEnablementMap.put('Solution Center - Santa Clara','Solution Center - Santa Clara'); //Solution Center - Santa Clara
//           //freeStatusEnablementMap.put('Solution Center – Munich','Solution Center – Munich'); //Solution Center – Munich
//           //freeStatusEnablementMap.put('Solution Center – Singapore','Solution Center – Singapore'); //Solution Center – Singapore
//           //freeStatusEnablementMap.put('Solution Center – Tokyo','Solution Center – Tokyo'); //Solution Center – Tokyo
//           //freeStatusEnablementMap.put('Solution Center – London','Solution Center – London'); //Solution Center – London

//           freeStatusEnablementMap.put('HR-PAYROLL-APJ', 'HR-PAYROLL-APJ'); //HR-PAYROLL-APJ
//           freeStatusEnablementMap.put('HR-PAYROLL-EMEA', 'HR-PAYROLL-EMEA'); //HR-PAYROLL-EMEA
//           freeStatusEnablementMap.put('HR-PAYROLL-INDIA', 'HR-PAYROLL-INDIA'); //HR-PAYROLL-INDIA
//           freeStatusEnablementMap.put('HR-PAYROLL-US/AMERICAS', 'HR-PAYROLL-US/AMERICAS'); //HR-PAYROLL-US/AMERICAS




//           Schema.DescribeSObjectResult userObject2 = User.SObjectType.getDescribe(); // To get prefix of the User object.
//           String prefix1 = userObject2.getKeyPrefix();
//           LIST<BMCServiceDesk__Incident__c> old_incidents = Trigger.old;
//           Integer idx = -1;

//           for (BMCServiceDesk__Incident__c incident1 : Trigger.new) {

//             idx += 1;

//             Set<String> holdStatuses = new Set<String> {'ON HOLD', 'PENDING CMR', 'PENDING HARDWARE', 'PENDING SOFTWARE', 'PENDING USER RESPONSE', 'PENDING OTHER TEAMS', 'PENDING APPROVAL', 'PENDING OTHERS'};

//             //Change Status to Assigned from On Hold Statuses (Pending for **) on change of owner.

//             if (prefix1 == (String.valueof(incident1.ownerid).substring(0, 3)) && old_incidents!= null && old_incidents[idx].ownerId!=null && incident1.ownerid !=  old_incidents[idx].ownerId && holdStatuses.contains(incident1.BMCServiceDesk__Status_ID__c ) ) {

//               Incident1.BMCServiceDesk__FKStatus__c = statusMap.get('ASSIGNED').id;
//             }

//             //CR 3395561 - Cancelling to be enabled for end users and staff users and mandatroy to enter the note for the reason
//             //Added CANCELED in the if condition along side CLOSED as their behaviour is same
//             //DEV NAME - PRANAV
//             //Incident1.BMCServiceDesk__UpdateCount__cSystem.debug('sla -- BMCServiceDesk__UpdateCount__c

//             if ( prefix1 != (String.valueof(incident1.ownerid).substring(0, 3)) && ((incident1.BMCServiceDesk__FKStatus__c != statusMap.get('CLOSED').id) && (incident1.BMCServiceDesk__FKStatus__c != statusMap.get('CANCELED').id))) {

//               if ( !freeStatusEnablementMap.containsKey(groupIDMap.get(incident1.ownerid).name) && Incident1.BMCServiceDesk__FKStatus__c != statusMap.get('REOPENED').id) {

//                 if (old_incidents != null && (( old_incidents[idx].OwnerId != incident1.ownerid  && (groupNameMap.get('Default Queue') !=null && old_incidents[idx].OwnerId != groupNameMap.get('Default Queue').id)) ||
//                     ( old_incidents[idx].BMCServiceDesk__FKStatus__c == statusMap.get('REASSIGNED').id ))) {

//                   Incident1.BMCServiceDesk__FKStatus__c = statusMap.get('REASSIGNED').id;
//                   //End Of CR3264691
//                 } else {

//                   Incident1.BMCServiceDesk__FKStatus__c = statusMap.get('UNASSIGNED').id;
//                 }
//               }

//             } else {
//               if ((prefix1 == (String.valueof(incident1.ownerid).substring(0, 3))) && (prefix1 == (String.valueof((incidentOldValueMap.get(incident1.id)).ownerid).substring(0, 3)))) {

//                 //CR: 2144287 :By Kartikeya Date: 1 Apr 2013
//                 // Re-assigning Status value  to 'Assigned' when a incident re-opened from closed status, having a user(not a Queue) as owner.
//                 //CR: 2978183 :By Kartikeya
//                 HD_DataLoad__c  dataLoadConfig = HD_DataLoad__c.getInstance('Update Closed');
//                 Boolean Updaterequired = true;
//                 if (dataLoadConfig != null  && dataLoadConfig.TextValue__c != 'true') {
//                   Updaterequired = false;
//                 }
//                 if ( String.valueof( incidentOldValueMap.get(Incident1.id).BMCServiceDesk__Status_ID__c ) == 'CLOSED' && Updaterequired == true && Incident1.BMCServiceDesk__Status_ID__c != 'CLOSED' ) {
//                   Incident1.BMCServiceDesk__FKStatus__c = statusMap.get('ASSIGNED').id;
//                 }
//                 //PRANAV - To Handle the status: CANCELED same as CLOSED
//                 //CR 3395561
//                 if ( String.valueof( incidentOldValueMap.get(Incident1.id).BMCServiceDesk__Status_ID__c ) == 'CANCELED' && Updaterequired == true && Incident1.BMCServiceDesk__Status_ID__c != 'CANCELED' ) {
//                   Incident1.BMCServiceDesk__FKStatus__c = statusMap.get('ASSIGNED').id;
//                 }// CR 3395561
//                 // End of CR: 2144287
//                 //Do Nothing as both owners are users so no need to change status.
//               } else if (  (Incident1.BMCServiceDesk__Status_ID__c != 'CLOSED' || Incident1.BMCServiceDesk__Status_ID__c != 'CANCELED' ) && (prefix1 == (String.valueof(incident1.ownerid).substring(0, 3))) && (prefix1 != (String.valueof((incidentOldValueMap.get(incident1.id)).ownerid).substring(0, 3)))) {
//                 //This means the new owner is a user while the last owner was a queue so change status to assigned.
//                 Incident1.BMCServiceDesk__FKStatus__c = statusMap.get('ASSIGNED').id;
//               }

//             }

//           }


//         }//If(trigger.IsUpdate)

//         //Close of changes by Samir Jha for CR 1903861.
//         /*
//         //Added the condition to check if statusList has atleast one element - janantha
//         if(Trigger.isUpdate && categoryMap.containsKey(Add_Desk_Lap_Category) && incident.BMCServiceDesk__FKCategory__c==categoryMap.get(Add_Desk_Lap_Category).ID && incident.HD_Additional_Hardware_Rejected__c && statusMap.containsKey('CLOSED')){//remove
//             incident.BMCServiceDesk__FKStatus__c=statusMap.get('CLOSED').id; //remove
//         }//remove
//         //Samir added code for CR 2012518:Changing the Status to Assigned
//         */

//         // Set Service if Urgency is not Null while creating the incident or Urgency value is changed while updating the incident
//         if (incident.BMCServiceDesk__FKUrgency__c != null) {
//           if (urgencyServiceMap.containsKey(incident.BMCServiceDesk__FKUrgency__c)) {

//             if (incident.BMCServiceDesk__Type__c != 'Service Request' &&  (Trigger.isInsert || (Trigger.isUpdate &&    (incident.BMCServiceDesk__FKUrgency__c != incidentOldValueMap.get(incident.id).BMCServiceDesk__FKUrgency__c))) ) {
//               incident.BMCServiceDesk__FKBusinessService__c = urgencyServiceMap.get(incident.BMCServiceDesk__FKUrgency__c);
//             }
//           } else {
//             //Ignore the error if the error is due to a BMC test class, as the view all data would not be set
//             //Throw the error only if the static variable is set. It is set only by persistent test class - janantha.
//             //if (Test.isRunningTest() == false){
//             if (HD_TestClassCorrectionForTrigger.throwMappingError == true) {
//               incident.addError('No Services found for the selected urgency');
//             }
//           }
//         }//if

//         /*
//         // Update Template Name of the Template applied for the incident.
//         if(incident.BMCServiceDesk__FKTemplate__c != Null && (Trigger.isInsert ||
//           (Trigger.isUpdate && incidentOldValueMap.get(incident.id).BMCServiceDesk__FKTemplate__c != incident.BMCServiceDesk__FKTemplate__c)))//remove
//         {
//             incident.BMCServiceDesk__TemplateName__c = templateMap.get(incident.BMCServiceDesk__FKTemplate__c).Name;//remove
//         }//remove
//         */

//         //Bugzilla – CR 2833248-Kartikeya populating VP Approver for Service Request approvals
//         //Bug fix Bugzill CR 2861220 - SRM_Director approval required for Technology Refresh template

//         if ( incident.BMCServiceDesk__Type__c == 'Service Request' || incident.HD_Test_Value__c == 'Service Request') {
//           //List <BMCServiceDesk__SRM_RequestDefinition__c> ReqDefns =  [Select VP_Approver_Required__c FROM  BMCServiceDesk__SRM_RequestDefinition__c  where ID = :incident.BMCServiceDesk__FKRequestDefinition__c LIMIT 1];

//           if (ReqDefns.size() > 0 && ReqDefns.containsKey(incident.BMCServiceDesk__FKRequestDefinition__c)) {
//             BMCServiceDesk__SRM_RequestDefinition__c rd = ReqDefns.get(incident.BMCServiceDesk__FKRequestDefinition__c);

//             if (rd != null && rd.VP_Approver_Required__c == true) {

//               User c_usr = vpUserMap.get(incident.BMCServiceDesk__FKClient__c);
//               if(c_usr != null){
//                 User usr = (vpUserMap.containsKey(c_usr.ManagerID))?vpUserMap.get(c_usr.ManagerID):null;
//                 while (usr != null) {

//                   if ( usr.Title != Null &&  ( usr.Title.contains('Director')  || usr.Title.contains('Vice President') || usr.Title.contains('SVP') || usr.Title.contains('CIO') ) ) {
//                     incident.HD_VP_Approver__c = usr.id;
//                     break;
//                   }

//                   // Search manager's Title for VP.
//                   if (vpUserMap.containsKey(usr.ManagerID))
//                     usr = vpUserMap.get(usr.ManagerID);
//                   else {
//                     break;
//                   }

//                 }//while
//               }


//             }
//           }

//         }//if( incident.BMCServiceDesk__Type__c == 'Service Request' || incident.HD_Test_Value__c == 'Service Request')
//         /*
//          //CR 2861220 - SRM_Director approval required for Technology Refresh template
//         //Bugzilla – CR 2833248
//         // If Category of the Incident is 'Additional Desktop/Laptop'
//         if(incident.BMCServiceDesk__Category_ID__c==Add_Desk_Lap_Category  )//remove full clause
//         {

//             User client=vpUserMap.get(incident.BMCServiceDesk__FKClient__c);
//             if(client!= Null)
//             {
//             // Iterate while the VP is not identified
//             while(True){
//                 if(client!=Null)//Change by Samir Jha for CR 2058139:RF Rel: 3.20 Apex Code Production Exception
//                 {

//                     // If the title contains "Vice President" or "SVP" or "CIO", then identify them as VP Approver
//                     if(client.Title!=Null && (client.Title.contains('Vice President')||client.Title.contains('SVP')||client.Title.contains('CIO')))
//                         {
//                             incident.HD_VP_Approver__c=client.id;
//                             Break;
//                         }
//                     else{
//                             // Search manager's Title for VP.
//                             if(vpUserMap.containsKey(client.ManagerID))
//                                 client=vpUserMap.get(client.ManagerID);
//                             else
//                             {

//                                 break;
//                             }
//                         }
//                 }
//                 else
//                 {
//                    // if(HD_TestClassCorrectionForTrigger.throwMappingError == true)
//                     {
//                     incident.addError('The client chosen for the incident is inactive');
//                     break;
//                     }

//                 }

//             }

//         }
//         else
//         {

//                 {
//                     incident.addError('The client chosen for the incident is inactive');
//                 }

//         }

//         }//if(incident.BMCServiceDesk__Category_ID__c==Add_Desk_Lap_Category  ) //remove
//         */

//       }
//     }
//   }// End IsBefore



//   if (Trigger.isAfter) {

//     If(trigger.Isinsert) {
//       //added by jay for CR 2627751 and CR  2824410
//       ServiceIncidentAgeCalculator.startCapturingStatusAge(trigger.newmap);
//     }

//     if (trigger.isupdate && si_triggerclass.statusChangedTracked == false) {
//       //added by jay for CR 2627751 and CR  2824410
//       ServiceIncidentAgeCalculator.calculateServiceIncidentAge(trigger.oldmap, trigger.newmap);
//       //recurrence check.
//       si_triggerclass.statusChangedTracked = true;
//     }

//     //kartikeya - CR 2728794 - Request Mgmt - Cascading Parent fields to child
//     List<Id> incident_ids = new List<Id>();
//     List<Id> parent_ids = new  List<Id>();

//     MAP<Id, BMCServiceDesk__Incident__c> incident_map = new MAP<Id, BMCServiceDesk__Incident__c>();
//     MAP<Id, BMCServiceDesk__Incident__c> parentIncidentMap = new MAP<Id, BMCServiceDesk__Incident__c>();
//     List<BMCServiceDesk__Incident__c> actionHistoryIncidents = new List<BMCServiceDesk__Incident__c>();

//     MAP<Id, BMCServiceDesk__Incident__c> parent_map = new MAP<Id, BMCServiceDesk__Incident__c>();

//     Integer i = 0;

//     //for(BMCServiceDesk__Incident__c incident: Trigger.new)
//     //{

//     //  if( statusMap.containsKey('CLOSED') && incident.BMCServiceDesk__FKStatus__c != statusMap.get('CLOSED').id){
//     //    incident_ids.add(incident.Id);
//     //    incident_map.put(incident.id,incident);
//     //  }

//     //  if( (Trigger.isInsert && incident.BMCServiceDesk__FKIncident__c != null)  ||
//     //       (Trigger.isUpdate && incident.BMCServiceDesk__FKIncident__c != Trigger.old[i].BMCServiceDesk__FKIncident__c)){
//     //     parent_ids.add(incident.BMCServiceDesk__FKIncident__c);
//     //     parent_map.put(incident.id,incident);
//     //   }

//     // i++;
//     //}//for(BMCServiceDesk__Incident__c incident: Trigger.new)

//     //logic for updating child incident
//     //if(incident_ids.size() > 0)
//     //{
//     //  if(System.isBatch() == false && System.isFuture() == false)
//     //  {
//     //    system.debug('---> Running updatechildIncident');
//     //  HD_IncidentUtils.updatechildIncident( incident_ids, statusMap.get('CLOSED').id );
//     //  //moved the logic to HD_IncidentUtils.cls class , method: updatechildIncident
//     //  //empty the List
//     //  incident_ids.clear();
//     //  }//if(HD_IncidentUtils.SKIP_TRIGEER == false)
//     //} //if Incident_ids.size()


//     // if(parent_ids.size() > 0)
//     // {
//     //  MAP<ID,String> incidentParentNameMap = new  MAP<ID,String>();
//     //  for(BMCServiceDesk__Incident__c incident: Trigger.new)
//     //     {
//     //        if(parent_map.containsKey(incident.BMCServiceDesk__FKIncident__c) && incident.BMCServiceDesk__FKStatus__c != statusMap.get('CLOSED').id){
//     //            incidentParentNameMap.put(incident.id,parent_map.get(incident.BMCServiceDesk__FKIncident__c).Name);
//     //      }

//     //     }
//     //     if(incidentParentNameMap.size() > 0)
//     //     {

//     //       HD_IncidentUtils.insertIncidentHistory(incidentParentNameMap,statusMap.get('CLOSED').id);

//     //     }

//     //}//if(parent_ids.size() > 0)

//     //End Of CR 2728794 - Request Mgmt - Cascading Parent fields to child


//     List<BMCServiceDesk__Incident__c> createIncidentList = new List<BMCServiceDesk__Incident__c>();
//     Map<ID, Integer> parentIncidentFlagMap = new Map<ID, Integer>();

//     //    if(Trigger.isUpdate)
//     //    {

//     //        List<Id> parentIncidentsList = new List<Id>();

//     //        for(BMCServiceDesk__Incident__c newincident: Trigger.new)
//     //        {
//     //        system.debug('Parent incisdent List-----> '+ parentIncidentsList);
//     //          if(newincident.RecordTypeId != recordTypeIdSI)
//     //          {
//     //                // Do we need to check whether Status is updated or already closed
//     //                //Added the condition to check if statusList has atleast one element - janantha
//     //          //  if(statusMap.containsKey('CLOSED'))
//     //          //  {
//     //          //      if(newincident.BMCServiceDesk__FKStatus__c == statusMap.get('CLOSED').id)
//     //          //      {
//     //                    if(newincident.BMCServiceDesk__FKIncident__c != null)
//     //                    {
//     //                        parentIncidentsList.add(newincident.BMCServiceDesk__FKIncident__c);
//     //                    }//if
//     //                else {
//     //                       parentIncidentsList.add(newincident.id);
//     //                      }//else
//     //            //    }//if
//     //           // }//if(statusMap.containsKey('CLOSED'))
//     //          }//if(incident.RecordTypeId != recordTypeIdSI)
//     //        }//for

//     //        system.debug('Parent incisdent List-----> '+ parentIncidentsList);
//     //        if(parentIncidentsList.size() > 0 )
//     //        {
//     //        // Creating a MAP for all the parents incidents, where 1 represents TO ALLOW TO CLOSE INCIDENT and 0 represents TO DISPLAY AN ERROR
//     //        for(BMCServiceDesk__Incident__c childincident : [SELECT RecordTypeId,BMCServiceDesk__FKIncident__c,BMCServiceDesk__FKIncident__r.BMCServiceDesk__FKIncident__c,BMCServiceDesk__FKStatus__c FROM BMCServiceDesk__Incident__c WHERE BMCServiceDesk__FKIncident__c  IN : parentIncidentsList])
//     //        {
//     //          if(childincident.RecordTypeId != recordTypeIdSI)
//     //          {
//     //              system.debug('>>>>>>>>>>'+ childincident.BMCServiceDesk__FKIncident__r.BMCServiceDesk__FKIncident__c );
//     //            //adding a logic for CR CR 3321051 - Error 50001_occurred on link on multiple incidents
//     //            if( childincident.BMCServiceDesk__FKIncident__r.BMCServiceDesk__FKIncident__c != null )
//     //            {
//     //              trigger.new[0].addError('This incident is already a child of another incident, If you still want to link please remove the parent incident reference ');
//     //             }//if( incident.BMCServiceDesk__FKIncident__r.BMCServiceDesk__FKIncident__c != '')

//     //            /*
//     //            //Added the condition to check if statusList has atleast one element - janantha
//     //            if(statusMap.containsKey('CLOSED'))
//     //            {
//     //              if(incident.BMCServiceDesk__FKStatus__c == statusMap.get('CLOSED').id){
//     //                if(!parentIncidentFlagMap.containsKey(incident.BMCServiceDesk__FKIncident__c)){
//     //                          parentIncidentFlagMap.put(incident.BMCServiceDesk__FKIncident__c,1);
//     //                }
//     //              }
//     //              else
//     //              {
//     //                if(!parentIncidentFlagMap.containsKey(incident.BMCServiceDesk__FKIncident__c))
//     //                          parentIncidentFlagMap.put(incident.BMCServiceDesk__FKIncident__c,0);
//     //                else{
//     //                      if(parentIncidentFlagMap.get(incident.BMCServiceDesk__FKIncident__c)==1)
//     //                      {
//     //                              parentIncidentFlagMap.remove(incident.BMCServiceDesk__FKIncident__c);
//     //                              parentIncidentFlagMap.put(incident.BMCServiceDesk__FKIncident__c,0);
//     //                      }
//     //                }
//     //              }
//     //            }//if(statusMap.containsKey('CLOSED'))
//     //           */

//     //          }//end of recordTypeId
//     //        }//for
//     //        }//if(parentIncidentsList.size() > 0 )

//     //} //if(Trigger.isUpdate)

//     List<Approval.ProcessSubmitRequest> approvalRequest = new List<Approval.ProcessSubmitRequest>();
//     // displaying an error for the Incidents for which Child incidents are still open
//     for (BMCServiceDesk__Incident__c incident : Trigger.new) {
//       if (incident.RecordTypeId != recordTypeIdSI) {
//         /*
//         if(Trigger.isUpdate && parentIncidentFlagMap.containsKey(incident.id))
//         {
//             //SHARDUL CR:2037547 added check to exclude for new hire category.
//             if(parentIncidentFlagMap.get(incident.id)== 0 && incident.BMCServiceDesk__Category_ID__c != 'New hire laptop and Cubicle' )
//             {
//                 incident.addError('Incident cannot be closed, it has open child Incidents.');
//             }

//         }//if(Trigger.isUpdate && parentIncidentFlagMap.containsKey(incident.id))
//         */
//         /*
//          //Additional hardware request. Automatically submit for approval after the recrod has been saved with category "Additiona Desktop/Laptop"
//          // Check if Category is changed in case of update
//         if((categoryMap.containsKey(Add_Desk_Lap_Category) && incident.BMCServiceDesk__FKCategory__c == categoryMap.get(Add_Desk_Lap_Category).ID)
//            && (Trigger.IsInsert || (Trigger.isUpdate && incident.BMCServiceDesk__FKCategory__c!=incidentOldValueMap.get(incident.id).BMCServiceDesk__FKCategory__c)))
//         {
//             if(incident.HD_VP_Approver__c!=Null){
//                 Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
//                 app.setObjectId(incident.id);
//                 approvalRequest.add(app);
//             }
//         }
//         */
//       } //if(incident.RecordTypeId != recordTypeIdSI)
//     }//for(BMCServiceDesk__Incident__c incident : Trigger.new)
//     // Insert child Incidents for New Hire Request
//     /*
//     if(createIncidentList.size()>0)
//     {
//         insert createIncidentList;
//     }
//      */
//     /*
//     // Submit incidents for approval for 'Additonal Hardware Request'
//     if(!approvalRequest.isEmpty())
//     {
//        try{
//            Approval.process(approvalRequest);
//        }
//        catch(Exception e)
//        {
//            system.debug('ERROR  : '+e);
//        }
//     }// if(!approvalRequest.isEmpty())
//     */
//   }

// //Staring code update for CR 2255654 by Hemant

//   if ( Trigger.isBefore) {
//     //Restrictive reopen
//     if (Trigger.isUpdate) {

//       for (BMCServiceDesk__Incident__c incident : Trigger.new) {

//         if (incidentOldValueMap.get(incident.id).BMCServiceDesk__Status_ID__c == 'CLOSED' && incident.BMCServiceDesk__Status_ID__c != 'CLOSED') {

//           if (incident.Follows_Restrictive_Reopen__c) {

//             if (incident.Valid_Days_to_Reopen__c != null) {

//               if (System.now() > incidentOldValueMap.get(incident.id).Closed_Date__c + incident.Valid_Days_to_Reopen__c) {

//                 incident.addError('Ticket is closed for more than ' + incident.Valid_Days_to_Reopen__c + ' days. Please raise a new ticket ');
//               }
//             }
//           }
//         }
//       }
//     }
//     if (Trigger.isInsert || Trigger.isUpdate) {

// //number of HD_EmailCC fields Limit
//       Integer HD_EmailCC_present_limit = 10;   //increased the limit to 10 , as per CR 2480916
// //define an Sobject
//       Sobject incident_Sobject = new BMCServiceDesk__Incident__c();
// //find the latest version of object
//       for ( BMCServiceDesk__Incident__c  inci_object : Trigger.new ) {
//         Sobject ast = inci_object;
//         if (ast.getSObjectType() == BMCServiceDesk__Incident__c.sObjectType ) {
//           incident_Sobject = (BMCServiceDesk__Incident__c)ast;

//           //Updated code patch for CR 2256617 By Hemant Kumar
//           //Lets try to extract the User from the ClientID field
//           //System.debug('CLIENT iD'+ast.BMCServiceDesk__FKClient__c);
//           String hkb_Client_id = String.valueOf(incident_Sobject.get('BMCServiceDesk__FKClient__c'));
//           String hkb_Client_email = String.valueOf(incident_Sobject.get('BMCServiceDesk__clientEmail__c'));
//           system.debug('Client Email ------> ' + String.valueOf(incident_Sobject.get('BMCServiceDesk__clientEmail__c')));
//           //first lets check weather the ast.Exclude_Client_Notifications__c field is true or not
//           if ( ( incident_Sobject.get('Exclude_Client_Notifications__c') != true ) && ( incident_Sobject.get('BMCServiceDesk__FKClient__c') != null )  ) {
//             incident_Sobject.put('Client_ID_Email__c', hkb_Client_email);
//           } else {
//             incident_Sobject.put('Client_ID_Email__c', '');
//           }//if( ast.Exclude_Client_Notifications__c != true )
//           //END Lets try to extract the User from the ClientID field
//           //END of  Updated code patch for CR 2256617 By Hemant Kumar

//           //nullify all the fields first before proceeding ... ! Important
//           for (Integer i = 0 ; i < HD_EmailCC_present_limit ; i++ ) {
//             incident_Sobject.put('HD_EmailCC' + (i + 1) + '__c', '');
//           }

//           //logic for extracting emails from CCtext Field
//           object CctextValue = incident_Sobject.get('CCText__c');
//           String rawcctext = null;
//           if ( CctextValue != null ) {
//             rawcctext = String.valueOf(CctextValue).normalizeSpace();
//           }

//           if ( rawcctext != null  && String.isNotBlank(rawcctext) && String.isNotEmpty(rawcctext) ) {
//             //Staring code update for CR 2320427- Make CC field smarter, by Hemant

//             //adding ; if its not present in the CCtext String
//             if ( ! rawcctext.endsWith(';') ) {
//               rawcctext  = rawcctext.normalizeSpace() + ';';
//             }

//             //START adding logic to re-sync the pattern for best match to solve the few errors
//             rawcctext  = rawcctext.normalizeSpace().deleteWhitespace();
//             System.debug('Pattern Rectifier value normalizeSpace() ------------------> ' + rawcctext );
//             rawcctext = rawcctext.replaceAll('\\b(.com)\\b(.com)*', '.com');
//             rawcctext = rawcctext.replaceAll('(,([\\,]*[\\s]*)*)', '');
//             rawcctext = rawcctext.replaceAll('.com', '.com;');
//             rawcctext = rawcctext.replaceAll('(\\b.com\\b)([\\s]*[;]*[\\s]*)*', '.com;');

//             System.debug('Pattern Rectifier value with regexp substitution; ------------------> ' + rawcctext );



//             // Staring code fix CR 2331057 - RF: Helpdesk BugFix for the exception that is being thrown out wrt email cc fields
//             if (rawcctext.contains(';;') == true) {
//               rawcctext = rawcctext.replaceAll('([;])([\\s]*[;]*[\\s]*)*', ';');
//               System.debug('Pattern Rectifier value ;; to ; ------------------> ' + rawcctext );
//             }
//             if (rawcctext.contains('@@') == true) {
//               rawcctext = rawcctext.replaceAll('\\b(@([\\@]*[\\s]*)*)\\b', '@');
//               System.debug('Pattern Rectifier value @@*  to @ with regexp ; ------------------> ' + rawcctext );
//             }

//             // END code fix CR 2331057 - RF: Helpdesk BugFix for the exception that is being thrown out wrt email cc fields



//             System.debug('Pattern Rectifier value ------------------> ' + rawcctext );

//             //END adding logic to re-sync the pattern for best match to solve the few errors

//             //now adding the patternised value to CcText Field Again !important
//             incident_Sobject.put('CCText__c', rawcctext.normalizeSpace());

//             //END of code update for CR 2320427- Make CC field smarter, by Hemant

//             //checking the CCtext email integrity
//             if ( Pattern.matches('^((\\w+([-+.\']\\w+)*@akamai\\.com*([\\s]*?[;][\\s]*))*)$' , rawcctext) == true  ) {
//               System.debug('--------> ' + rawcctext.toLowerCase().trim());
//               List<String> CcTextEmails = rawcctext.toLowerCase().trim().split(';');
//               if ( ( CcTextEmails.size() > 0 ) &&  (  CcTextEmails.size() < 11 ) ) //increased the limit to 10 , as per CR 2480916

//               {


//                 //now set the values based on CcText field
//                 for (Integer i = 0 ; i < cCTextemails.size() ; i++ ) {

//                   object currenttext = CcTextEmails.get(i);
//                   incident_Sobject.put('HD_EmailCC' + (i + 1) + '__c', currenttext );
//                 }

//               }//if ( ( CcTextEmails.size() > 0 ) &&  (  CcTextEmails.size() < 11 ) )
//               else {
//                 incident_Sobject.addError('minimum 1 and maximum of 10 Cc emails are acceptable !'); //increased the limit to 10 , as per CR 2480916
//                 inci_object.CCText__c.addError('minimum 1 and maximum of 10 Cc emails are acceptable !'); //increased the limit to 10 , as per CR 2480916
//               }//if ( ( CcTextEmails.size() > 0 ) &&  (  CcTextEmails.size() < 11 ) )

//             }// if( Pattern.matches *
//             else {
//               incident_Sobject.addError('Cc Field : 1. Only akamai.com emails are accepted ! 2. Please enter (;) at the end of every email if necessary ! 3. Accepts up-to 10 emails field '); //increased the limit to 10 , as per CR 2480916
//               inci_object.CCText__c.addError('CCText : email pattern is not valid !');
//             }// if( Pattern.matches *

//           } //if ( incident_Sobject.get('CCText__c') != null )


//         }//if(ast.getSObjectType() == BMCServiceDesk__Incident__c.sObjectType )

//       }//for( Sobject ast : Trigger.new )

// // START of CODE Update for CR 2378280   by Sreenidhi for Customer impact field popup issue
//       for (BMCServiceDesk__Incident__c incident : Trigger.new) {

//         if (incident.RecordTypeId != recordTypeIdSI) {
//           if ( incident.HD_Ticket_Priority__c == '1' && incident.HD_High_Customer_Impact__c != TRUE  ) {
//             // CR 2943110 - Kartikeya
//             HD_Apex_Messages__c apexMsg = HD_Apex_Messages__c.getInstance('SEV1 WARNING');
//             if (apexMsg != null) {
//               incident.addError(apexMsg.messageText__c);
//             } else {
//               incident.addError('Is this a customer impacting issue? Please note that Priority 1 issues would page the global technician. Please select Page Support Checkbox to confirm');
//             }
//             // End of CR 2943110 - Kartikeya

//           }
//         }
//       }//end of for loop
//       //END of CODE Update for CR 2378280   by Sreenidhi for Customer impact field popup issue


//       //START of CR 2960174 by Hemant Kumar for SR_Priority__c and  HD_Ticket_Priority__c sync
//       for (BMCServiceDesk__Incident__c incident : Trigger.new) {


//         //Adding a logic for priority update
//         if (priority_map.containsKey(incident.HD_Ticket_Priority__c)) {
//           incident.BMCServiceDesk__FKPriority__c = priority_map.get(incident.HD_Ticket_Priority__c).id;
//         }//if (priority_map.containsKey(incident.HD_Ticket_Priority__c))


//         system.debug('---->Priority sync statment HD priority---->' + incident.HD_Ticket_Priority__c);
//         system.debug('---->Priority sync statment SR priority---->' + incident.SR_Priority__c);
//         if ( incident.HD_Ticket_Priority__c == '4' ) {
//           incident.SR_Priority__c = 'Standard';
//         } else if ( incident.HD_Ticket_Priority__c == '3' ) {
//           incident.SR_Priority__c = 'High';
//         }else if(incident.HD_Ticket_Priority__c == '5') {
//            incident.SR_Priority__c = 'Low';
//         }
//       }//for(BMCServiceDesk__Incident__c incident: Trigger.new)
//       //END of CR 2960174 by Hemant Kumar for SR_Priority__c and  HD_Ticket_Priority__c sync

// //Start of CR 3066261 - Need a flag to identify if an incident is assigned within region or not
//       if (Trigger.isUpdate) {
//         //getting the current user id who is going to assign the user
//         Id currentUSERID_ASSIGNEE = userinfo.getUserId(); // changed as part of CR 3100581 - HD same region ticket bug fix same assignee and owner does not show same region true
//         Map<Id, User> LastModifiedBYID_owner_managerdetails = new Map<Id, User>();
//         for (User usr : [Select id, name, managerId from User where Id = : currentUSERID_ASSIGNEE ]) { //incnewversion.LastModifiedBYID //// changed as part of CR 3100581 - HD same region ticket bug fix same assignee and owner does not show same region true
//           LastModifiedBYID_owner_managerdetails.put(usr.id, usr);
//         }

//         //getting new version of Incident
//         for ( BMCServiceDesk__Incident__c incnewversion : trigger.new) {
//           System.debug('OWNER ID DEBUG ------->' + incnewversion.OwnerID);
//           system.debug('Size --->' + LastModifiedBYID_owner_managerdetails.get(currentUSERID_ASSIGNEE).managerId); //// changed as part of CR 3100581 - HD same region ticket bug fix same assignee and owner does not show same region true
//           System.debug('Ownermanager---->' + incnewversion.HD_Owner_Manager__c); //remove this line
//           if ( String.valueOf(incnewversion.HD_Owner_Manager__c) != null && String.valueOf(incnewversion.HD_Owner_Manager__c).startsWith('005') ) {
//             if ( LastModifiedBYID_owner_managerdetails.get(currentUSERID_ASSIGNEE).managerId == incnewversion.HD_Owner_Manager__c ) { //// changed as part of CR 3100581 - HD same region ticket bug fix same assignee and owner does not show same region true
//               incnewversion.Same_Region_Ticket__c = true;
//             } else {  incnewversion.Same_Region_Ticket__c = false; }
//           } else {
//             incnewversion.Same_Region_Ticket__c = false;
//           }


//         }//for( BMCServiceDesk__Incident__c incnewversion : trigger.new)
//       }//if(Trigger.isUpdate)

//       //END CR 3066261 - Need a flag to identify if an incident is assigned within region or not


//     }//if(Trigger.isInsert || Trigger.isUpdate)
//   }//if(Trigger.isBefore)

// //END of Code Update for CR 2255654 by Hemant


// //Restricted Area Access CR-950421     by Kartikeya


//   if (Trigger.isInsert && Trigger.isAfter) {
//     System.debug('category map ID size = ' + categoryIDMap.size());
//     HD_RestrictedAccess restrictedAccess = HD_RestrictedAccess.getInstance(Trigger.new, categoryIDMap);
//     restrictedAccess.afterInsert();

//   }


//   if (Trigger.isUpdate) {

//     HD_RestrictedAccess restrictedAccess =  HD_RestrictedAccess.getInstance(Trigger.new, Trigger.old, categoryIDMap);

//     if (Trigger.isBefore) {

//       restrictedAccess.beforeUpdateChanges();
//     }

//     if (Trigger.isAfter) {

//       restrictedAccess.afterUpdateChanges();
//       HD_RestrictReopen restrictRepoen = HD_RestrictReopen.getInstance(Trigger.old, Trigger.new, groupNameMap, vpUserMap);
//       restrictRepoen.afterUpdateChanges();
//     }

//   }

//   //End of CR 950421

//   //Kartikeya- CR 2545230 -  Action history date/time to be made available for reporting
//   if (trigger.isBefore && (Trigger.isUpdate || Trigger.isInsert )) {

//     for (BMCServiceDesk__Incident__c incident : Trigger.new) {
//       if (incident.RecordTypeId != recordTypeIdSI)
//         incident.Last_Updated_Date_Time__c = System.now();
//     }

//   }
//   // End of Kartikeya- CR 2545230

//   //Bhaskar- CR 3074561 - Reopened ticket should not be assigned to inactive employees
//   if (Trigger.isUpdate && Trigger.isBefore) {
//     HD_RestrictReopen restrictRepoen = HD_RestrictReopen.getInstance(Trigger.old, Trigger.new, groupNameMap, vpUserMap);
//     restrictRepoen.beforeUpdateChanges();
//   }
//   //End of CR 3074561

//   //Fix for CR 2995661- Resolution gets added to clone HD tickets- Komal
//   if (Trigger.isInsert && Trigger.isBefore) {
//     for (BMCServiceDesk__Incident__c incident : Trigger.new) {
//       if ((incident.BMCServiceDesk__UpdateCount__c <= 1) && (incident.RecordTypeId != recordTypeIdSI)) {
//         //recordtype check
//         incident.BMCServiceDesk__incidentResolution__c = '';
//         incident.Effort_Estimation__c = '';
//         //pranav - PRTORES-625 -- tickets cloned with routing set to override routing skip the
//         //routing logic
//         //fix --  setting routing to default before creation
//         incident.HD_Routing_Settings__c = 'Default Routing';
//         //fix issue at time of cloning --  addded by pranav
//         //cases where a ticket is cloned from Remedyforce consel with Assigned Status - it goes to REASSIGNED status
//         //For details see REASSIGNED logic in trigger
//         incident.ownerId = groupNameMap.get('Default Queue') != null ? groupNameMap.get('Default Queue').ID : incident.ownerId ;
//       }
//     }
//   }

//   //Provision made for email flow - visualforce email template - owner transfer
//   //HD_IncidentRecordSharing functionality is not required for batch jobs as,
//   //batch jobs will always be running in system admin context
//   //this exception is made because HD_IncidentRecordSharing.revokeAccess(recordIds); is a future method
//   //and we have many batch jobs, processing tickets

//   if (Trigger.isUpdate && Trigger.isBefore) {
//     if (!(system.isBatch() || system.isFuture())) {
//         HD_IncidentRecordSharing.setReadAccess(Trigger.new);
//         system.debug('callsed setReadAccess for recprds : '+ Trigger.new.size());
//     }


//   }

//   if(Trigger.isUpdate && Trigger.isAfter){

//     List<ID> recordIds = new List<ID>();
//     for(BMCServiceDesk__Incident__c inc : Trigger.new){
//       recordIds.add(inc.id);
//     }
//     if (!(system.isBatch() || system.isFuture()) && HD_CheckRecursive.revokeOnce()) {
//         HD_IncidentRecordSharing.revokeAccess(recordIds);
//         system.debug('called revokeAccess for recprds : '+ recordIds.size());
//     }

//   }

//   //End of fix for CR 2995661

//   system.debug('----> Number of rows Used ----> ' + Limits.getQueryRows());
//   system.debug('----> Limit of rows left ----> ' + (Integer.valueOf(Limits.getLimitQueryRows()) - Integer.valueOf(Limits.getQueryRows())));
//   system.debug('----> Number of SOQL used ----> ' + Limits.getSoslQueries());
//   system.debug('----> Limit of SOQL left----> ' + (Integer.valueOf(Limits.getLimitSoslQueries()) - Integer.valueOf(Limits.getSoslQueries())));
// 
}//END of trigger