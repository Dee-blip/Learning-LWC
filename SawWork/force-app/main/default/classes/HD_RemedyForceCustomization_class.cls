/*
 * New Trigger class  Updates : streamlined Code for easy debug, onplace query calls
 * all the logic covered, we removed some redudant code
 * version : 1.0
 * date: 31-OCT-2017
 * Object: incident
 * Test class : HD_Test_Remedyforce_New_Trigger
 * trigger : HD_RemedyForceCustomization_Tri
 */
public without sharing class HD_RemedyForceCustomization_class {
//General variable declaration below
  private static List<ID> incidetManualShareIds = null;
  private static boolean isInsertFlag;
  private static List < BMCServiceDesk__Incident__c > newtriggerVersion;
  private static List < BMCServiceDesk__Incident__c > oldtriggerVersion;
//
  private static ID recordTypeIdSI = Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Service Incident').getRecordTypeId();
//stores all the status list
  private static Map < String, BMCServiceDesk__Status__c > statusListMap = null;
  private static Map < String, BMCServiceDesk__Priority__c > priority_map = null;
  private static Map < String, BMCServiceDesk__Impact__c > impactListMap = null;
  private static Map < ID, ID > urgencyServiceMap = null;
  private static Map < Id, BMCServiceDesk__SRM_RequestDefinition__c > requestDefinitions_map = null;
  private static Map < id, user > vpUserMap = null;
  private static Map < String, Group > groupNameMap = null; //new Map < String, Group > ();
  private static Map < Id, Group > groupIDMap = null;  //new Map < Id, Group > ();
  //private static Map < Id, GroupMember > GroupMemberGroupIdMap = null;
  private static Map <Id, Set<Id>> GroupMemberGroupIdMap = null;
  private static Map <Id, BMCServiceDesk__Category__c> category_map = null; // = [Select Name, id, RA_Category_Group__c, RA_Config_Value__c, RA_Secondary_Queue__c, Service_Owner__c, BMCServiceDesk__categoryType_Id__c, Valid_Days_to_Reopen__c, Follows_Restrictive_Reopen__c   FROM BMCServiceDesk__Category__c WHERE BMCServiceDesk__inactive__c = false limit 3000];
  private static Map < ID, BMCServiceDesk__Incident__c > incidentOldValueMap = null;

//
//private static String Add_Desk_Lap_Category,Tel_Category,Cor_Ser_Category,Hard_Category,New_Hire,Parent_Hire,Child1,Child2,Child3;
  private static Map < String, Account > accountListMap = null;
  private static Map < String, Id> emailToUserIDMap = null; //shashank hegade 


//implementing singleton pattern
  private static HD_RemedyForceCustomization_class instance = null;

//the private consructor for newversion of trigger and old version of trigger
// use this instance when u wanted to have prior value in the field
  private HD_RemedyForceCustomization_class(List < BMCServiceDesk__Incident__c > newtriggerInstance, List < BMCServiceDesk__Incident__c > oldtriggerInstance, boolean isInsert) {
    //setting isInsertFlag
    isInsertFlag = isInsert;
    //lets set the value for new trigger instance
    newtriggerVersion = new List < BMCServiceDesk__Incident__c > ();
    newtriggerVersion.addAll(newtriggerInstance);

    if (isInsert == false) {
      oldtriggerVersion = new List < BMCServiceDesk__Incident__c > ();
      oldtriggerVersion.addAll(oldtriggerInstance);
    } else {
      oldtriggerVersion = new List < BMCServiceDesk__Incident__c > ();
      oldtriggerVersion = null;
    }
    //GroupMemberGroupIdMap = new Map <Id, Set<Id>>();

  } //constructor

// static method that returns instance of class
// usefull for insert, and update were prior value is needed for validation and check controll
  public static HD_RemedyForceCustomization_class getInstance(List < BMCServiceDesk__Incident__c > newtriggerInstance, List < BMCServiceDesk__Incident__c > oldtriggerInstance, boolean isInsert) {

    instance = new HD_RemedyForceCustomization_class(newtriggerInstance, oldtriggerInstance, isInsert);

    return instance;

  } //


//Lazy Initialization methods start from here
  /**
      get all the status list
  **/
  private static Map < String, BMCServiceDesk__Status__c > getStatusListMap() {
    if (statusListMap == null) {
      statusListMap = new Map < String, BMCServiceDesk__Status__c > ();
      for (BMCServiceDesk__Status__c status : [select Id, Name from BMCServiceDesk__Status__c limit 1000]) {
        statusListMap.put(status.Name, status);
      }
    }
    return statusListMap;
  }



  /**
  get required requestdefinition
  **/

  private static Map < ID, BMCServiceDesk__SRM_RequestDefinition__c > getRequestDefinitions() {
    if (requestDefinitions_map == null) {
      requestDefinitions_map = new Map < ID, BMCServiceDesk__SRM_RequestDefinition__c > ();
      List< Id > ReDefIds = new List<Id>();
      for (BMCServiceDesk__Incident__c incident : newtriggerVersion) {
        if ( incident.BMCServiceDesk__Type__c == 'Service Request' || incident.HD_Test_Value__c == 'Service Request') {
          ReDefIds.add(incident.BMCServiceDesk__FKRequestDefinition__c);
          //List <BMCServiceDesk__SRM_RequestDefinition__c>
        }
      }
      requestDefinitions_map = new  Map<Id, BMCServiceDesk__SRM_RequestDefinition__c>([Select id, VP_Approver_Required__c FROM  BMCServiceDesk__SRM_RequestDefinition__c  where ID = :ReDefIds ]);
    }
    return requestDefinitions_map;
  }

  /**
  get all caegories
  **/

  private static Map < Id, BMCServiceDesk__Category__c > getCategoryMap() {
    if (category_map == null) {
      category_map = new Map < Id, BMCServiceDesk__Category__c > ();
      for (BMCServiceDesk__Category__c category : [Select Name, id, RA_Category_Group__c, RA_Config_Value__c, RA_Secondary_Queue__c, Service_Owner__c, BMCServiceDesk__categoryType_Id__c, Valid_Days_to_Reopen__c, Follows_Restrictive_Reopen__c
           FROM BMCServiceDesk__Category__c
           WHERE BMCServiceDesk__inactive__c = false limit 5000]) {
        category_map.put(category.Id, category);
      }
    }
    return category_map;
  }

  /**
      get all priorities
  **/
  private static Map < String, BMCServiceDesk__Priority__c > getPriorityMap() {
    if (priority_map == null) {
      priority_map = new Map < String, BMCServiceDesk__Priority__c > ();
      for (BMCServiceDesk__Priority__c priority : [Select id, Name, BMCServiceDesk__urgency_Id__c, BMCServiceDesk__FKUrgency__c, BMCServiceDesk__impact_Id__c, BMCServiceDesk__FKImpact__c from BMCServiceDesk__Priority__c
           where BMCServiceDesk__impact_Id__c = 'LOW' and BMCServiceDesk__urgency_Id__c in ('Severity 3', 'Severity 2', 'Severity 1', 'Severity 4', 'Severity 5')
               LIMIT 100]) {
        priority_map.put(priority.Name, priority);
      }
    }
    return priority_map;
  }

  /**
      get all urgency-Service Mapping
  **/
  private static Map < ID, ID > getUrgencyServiceMap() {
    if (urgencyServiceMap == null) {
      urgencyServiceMap = new Map < ID, ID > ();
      for (HD_Urgency_Service_Mapping__c urgencyServiceMapping : [SELECT HD_Service__c, HD_Urgency__c FROM HD_Urgency_Service_Mapping__c limit 100]) {
        urgencyServiceMap.put(urgencyServiceMapping.HD_Urgency__c, urgencyServiceMapping.HD_Service__c);
      }
    }
    return urgencyServiceMap;
  }

  /**
      getting all the users
  **/
  private static Map < id, user > getVpUserMap() {
    //vpUserMap = new Map<id,user>([Select id ,name,managerId,Title from User where IsActive=true limit 50000 ]);
    if (vpUserMap == null) {
      vpUserMap = new Map < id, user > ();
      emailToUserIDMap = new Map<string, id>(); 
      for (User usr : [Select id, name, managerId, Title, email from User where IsActive = true and username LIKE '%akamai.com%'
                       limit 50000
                      ]) {
        vpUserMap.put(usr.id, usr);
        string mailID = usr.email;
        emailToUserIDMap.put(mailID.toLowercase(), usr.id);
      }
    }
    return vpUserMap;
  }
 
  //method to get the email to user id map @shashankhegade PRTORES 1326
  public static Map < string,id  > getEmailUserMap() {
    if (emailToUserIDMap == null) {
      getVpUserMap();
    }
    return emailToUserIDMap;
  }
    

  /**
      getting a default account
  **/
  private static Map < String, Account > getAccountListMap() {
    if (accountListMap == null) {
      HD_Default_Custom_Setting__c Defaults = HD_Default_Custom_Setting__c.getInstance('DEFAULT VALUES');
      accountListMap = new Map < String, Account > ();
      for (Account acc : [Select id, Name from Account where Name = : Defaults.Default_Account__c]) {
        accountListMap.put(acc.Name, acc);
      }
    }
    return accountListMap;
  }

  /**
      getting all impact lIst
  **/
  //private static Map < String, BMCServiceDesk__Impact__c > getImpactListMap() {
  //  if (impactListMap == null) {
  //    impactListMap = new Map < String, BMCServiceDesk__Impact__c > ();
  //    for (BMCServiceDesk__Impact__c impact : [Select id, Name from BMCServiceDesk__Impact__c]) {
  //      impactListMap.put(impact.Name, impact);
  //    }
  //  }
  //  return impactListMap;
  //}

  /**
      Creating maps out of old trigger versions
  **/
  private static Map < Id, BMCServiceDesk__Incident__c > getIncidentOldValueMap() {
    if (oldtriggerVersion != null && oldtriggerVersion.size() > 0) {
      incidentOldValueMap = new Map < Id, BMCServiceDesk__Incident__c > (oldtriggerVersion);
    } else {
      incidentOldValueMap = null;
    }
    return incidentOldValueMap;
  }

  /**
    Getting Group id map
  **/
  private static Map<Id, Group> getGroupIdMap() {
    if (groupIDMap == null) {
      groupNameMap = new Map < String, Group > ();
      groupIDMap = new Map < Id, Group > ();
      for (Group grp : [Select id, name from group where name = 'VIP Users'
                        OR Type = 'Queue'
                       ]) {
        groupNameMap.put(grp.name, grp);
        groupIDMap.put(grp.Id, grp);
      }
    }
    return groupIDMap;
  }

  /**
    Getting Group name map
  **/
  private static Map<String, Group> getGroupNameMap() {
    if (groupNameMap == null) {
      groupNameMap = new Map < String, Group > ();
      groupIDMap = new Map < Id, Group > ();
      for (Group grp : [Select id, name from group where name = 'VIP Users'
                        OR Type = 'Queue'
                       ]) {
        groupNameMap.put(grp.name, grp);
        groupIDMap.put(grp.Id, grp);
      }
    }
    return groupNameMap;
  }


  /**
      Getting Group Members List and mapping the  GroupMember.GROUPID
  **/

  private static Map < Id, Set<ID> > getGroupMemberGroupIdMap() {
    //getGroupIdMap();
    if (GroupMemberGroupIdMap == null) {
      GroupMemberGroupIdMap = new Map < Id, Set<ID>>();
      for (GroupMember grpmem : [Select USERORGROUPID, GROUPID from GroupMember where GROUP.name = 'VIP Users']) {
        if (GroupMemberGroupIdMap.containsKey(grpmem.GROUPID)) {
          GroupMemberGroupIdMap.get(grpmem.GROUPID).add(grpmem.USERORGROUPID);
        } else {
          Set<Id> userGroupId = new Set<Id>();
          userGroupId.add(grpmem.USERORGROUPID);
          GroupMemberGroupIdMap.put(grpmem.GROUPID, userGroupId);
        }
      }
    }
    return GroupMemberGroupIdMap;
  }


//Lazy Initialization methods end here

//logic starts here

//Usage@ Before insert Update

//Usage@ Before insert and Update
  public void markVIPFlagOnTickets() {
        System.debug('executing method -> markVIPTickets');
        //Start Changes by Sebi for CR 2085994
        List < ID > user_ids = new List < ID > ();
        Map<Id,User> userMap = getVpUserMap();
        Map<ID, BMCServiceDesk__Incident__c> oldIncidentMap = getIncidentOldValueMap();
        Map < String, HD_VIP_Titles__c > VipTitles = HD_VIP_Titles__c.getAll();
        // New Code
        for (BMCServiceDesk__Incident__c newincident : newtriggerVersion) {
            if (newincident.RecordTypeId != recordTypeIdSI) {
                if (isInsertFlag && 
                    (newincident.BMCServiceDesk__FKClient__c == null || String.isEmpty(newincident.BMCServiceDesk__FKClient__c))) {
                        newincident.BMCServiceDesk__FKClient__c = System.UserInfo.getUserId();
                    }
                
                if(isInsertFlag ||
                   (oldIncidentMap != null && 
                    oldIncidentMap.size() > 0 &&
                    oldIncidentMap.containsKey(newincident.Id) &&
                    newincident.BMCServiceDesk__FKClient__c != oldIncidentMap.get(newincident.Id).BMCServiceDesk__FKClient__c)) {
                        //check if client belongs to the VIP USER Group and mark the flag
                        if (getGroupMemberGroupIdMap().containsKey(getGroupNameMap().get('VIP Users').id)) {
                            Boolean isAPartOfVIPGroup = getGroupMemberGroupIdMap().get(getGroupNameMap().get('VIP Users').id).contains(newincident.BMCServiceDesk__FKClient__c);
                            if(isAPartOfVIPGroup) {
                                System.debug('User :'+newincident.BMCServiceDesk__FKClient__c+' is a part of VIP group');
                                newincident.VIP_Ticket__c = true;
                            }
                        }
                        
                        for (HD_VIP_Titles__c VipTitle : VipTitles.values()) {
                            String title = userMap.get(newincident.BMCServiceDesk__FKClient__c).Title;
                            Boolean hasAVIPTile = (title != null && title.toLowercase().contains(VipTitle.Name.toLowercase())) ;
                            if(hasAVIPTile) {
                                System.debug('User :'+newincident.BMCServiceDesk__FKClient__c+' has a VIP title');
                                newincident.VIP_Ticket__c = true;
                                break;
                            }
                        }
                    }
            } 
        }
        // End of new Code
    } //public void vipTicketLogicNotAccurate()

//Usage @ before Insert
  //not required
  public void defaultAccount() {
    System.debug('executing method -> defaultAccount');
    HD_Default_Custom_Setting__c Defaults = HD_Default_Custom_Setting__c.getInstance('DEFAULT VALUES');
    for (BMCServiceDesk__Incident__c newincident : newtriggerVersion) {

      if (newincident.RecordTypeId != recordTypeIdSI && getAccountListMap().containsKey(Defaults.Default_Account__c)) {
        newincident.BMCServiceDesk__FKAccount__c = getAccountListMap().get(Defaults.Default_Account__c).Id;
      } //if(newincident.RecordTypeId != recordTypeIdSI)
    } //for( BMCServiceDesk__Incident__c newincident : newtriggerVersion )
  } //public void DefaultAccount()


//Usage @ before Insert Update
  public void newPriorityUrgencyLogic() {
    Map<ID, BMCServiceDesk__Incident__c> oldIncidentMap = getIncidentOldValueMap();
    Map < String, HD_Ticket_Priority__c > allPriorityMap = HD_Ticket_Priority__c.getAll();
    for (BMCServiceDesk__Incident__c newincident : newtriggerVersion) {
      if (newincident.RecordTypeId != recordTypeIdSI) {

        //if urgency is mentioned - get the priority from custom setting and populate it on the incident
        if (String.isNotBlank(newincident.BMCServiceDesk__FKUrgency__c) &&
          (newincident.HD_Ticket_Priority__c == null)||
          (oldIncidentMap!=null && newincident.BMCServiceDesk__FKUrgency__c != oldIncidentMap.get(newincident.id).BMCServiceDesk__FKUrgency__c)){
          for (HD_Ticket_Priority__c priority_setting : allPriorityMap.values()) {
            if (priority_setting.Urgency_Id__c == newincident.BMCServiceDesk__FKUrgency__c) {
              newincident.HD_Ticket_Priority__c = priority_setting.Name;
              break;
            }
          }
        }

        if (newincident.BMCServiceDesk__contactType__c == 'Mail Listen' && String.isBlank(newincident.BMCServiceDesk__FKUrgency__c)) {
          HD_Ticket_Priority__c ticket_priority = HD_Ticket_Priority__c.getInstance('default');
          newincident.HD_Ticket_Priority__c = ticket_priority.Priority_Name__c;
          newincident.BMCServiceDesk__FKUrgency__c = ticket_priority.Urgency_Id__c;

          if (ticket_priority.Priority_Id__c != NULL && ticket_priority.Priority_Id__c.trim() != '')
            newincident.BMCServiceDesk__FKPriority__c = ticket_priority.Priority_Id__c;

        } //if(newincident.BMCServiceDesk__contactType__c == 'Mail Listen' && String.isBlank(newincident.BMCServiceDesk__FKUrgency__c) )
        //Logic to add message when Priority is not selected


        if (String.isBlank(newincident.HD_Ticket_Priority__c)) {
          newincident.addError('Priority is mandatory. Please select a value from Priority list');
        } //if(String.isBlank(newincident.HD_Ticket_Priority__c))

        newincident.BMCServiceDesk__FKPriority__c = getPriorityMap().get(newincident.HD_Ticket_Priority__c).id;
        newincident.BMCServiceDesk__FKUrgency__c = getPriorityMap().get(newincident.HD_Ticket_Priority__c).BMCServiceDesk__FKUrgency__c;
        newincident.BMCServiceDesk__FKImpact__c = getPriorityMap().get(newincident.HD_Ticket_Priority__c).BMCServiceDesk__FKImpact__c;

      }//if closes
    }
  }


  public void priorityUrgencySyncLogic() {
    /*
    System.debug('executing method -> priorityUrgencySyncLogic');
    // Priorty-Urgency Sync  - Kartikeya- CR 2614449
    //Stamps Urgency and Priority values depends on the input contains value forPriority/Urgency
    //Throws error as priority not found if  Urgency or Priority both values not present.

    for (BMCServiceDesk__Incident__c newincident : newtriggerVersion) {
      if (newincident.RecordTypeId != recordTypeIdSI) {
        Map < String, HD_Ticket_Priority__c > allPriorityMap = HD_Ticket_Priority__c.getAll();
        //for insert operation
        if (String.isNotBlank(newincident.HD_Ticket_Priority__c)) {
          HD_Ticket_Priority__c ticket_priority = HD_Ticket_Priority__c.getInstance(newincident.HD_Ticket_Priority__c);
          newincident.BMCServiceDesk__FKUrgency__c = ticket_priority.Urgency_Id__c;

          if (ticket_priority.Priority_Id__c != NULL && ticket_priority.Priority_Id__c.trim() != '')
            newincident.BMCServiceDesk__FKPriority__c = ticket_priority.Priority_Id__c;

          //newincident.addError('debug '+newincident.BMCServiceDesk__FKPriority__c );
        } //if(String.isNotBlank(newincident.HD_Ticket_Priority__c))
        //during insert operation
        if (String.isNotBlank(newincident.BMCServiceDesk__FKUrgency__c)) {


          for (HD_Ticket_Priority__c priority_setting : allPriorityMap.values()) {
            if (priority_setting.Urgency_Id__c == newincident.BMCServiceDesk__FKUrgency__c) {
              newincident.HD_Ticket_Priority__c = priority_setting.Name;

              if (priority_setting.Priority_Id__c != NULL && priority_setting.Priority_Id__c.trim() != '')
                newincident.BMCServiceDesk__FKPriority__c = priority_setting.Priority_Id__c;


              break;
            } //if(priority_setting.Urgency_Id__c == newincident.BMCServiceDesk__FKUrgency__c )
          } //for(HD_Ticket_Priority__c priority_setting : allPriorityMap.values() )
        } //if(String.isNotBlank(incident.BMCServiceDesk__FKUrgency__c))

        //for update action
        if (isInsertFlag == false) {
          for (BMCServiceDesk__Incident__c oldincident : oldtriggerVersion) {
            if (newincident.HD_Ticket_Priority__c != oldincident.HD_Ticket_Priority__c) {
              HD_Ticket_Priority__c ticket_priority = HD_Ticket_Priority__c.getInstance(newincident.HD_Ticket_Priority__c);
              newincident.BMCServiceDesk__FKUrgency__c = ticket_priority.Urgency_Id__c;

              if (ticket_priority.Priority_Id__c != NULL && ticket_priority.Priority_Id__c.trim() != '')
                newincident.BMCServiceDesk__FKPriority__c = ticket_priority.Priority_Id__c;


            } //if(newincident.HD_Ticket_Priority__c != oldincident.HD_Ticket_Priority__c)
            //for update
            if (newincident.BMCServiceDesk__FKUrgency__c != oldincident.BMCServiceDesk__FKUrgency__c || String.isBlank(newincident.HD_Ticket_Priority__c)) {
              for (HD_Ticket_Priority__c priority_setting : allPriorityMap.values()) {
                if (priority_setting.Urgency_Id__c == newincident.BMCServiceDesk__FKUrgency__c) {
                  newincident.HD_Ticket_Priority__c = priority_setting.Name;

                  if (priority_setting.Priority_Id__c != NULL && priority_setting.Priority_Id__c.trim() != '')
                    newincident.BMCServiceDesk__FKPriority__c = priority_setting.Priority_Id__c;

                  break;
                } //if(priority_setting.Urgency_Id__c == newincident.BMCServiceDesk__FKUrgency__c )
              } //for(HD_Ticket_Priority__c priority_setting : allPriorityMap.values() )

            } //if(newincident.BMCServiceDesk__FKUrgency__c != oldincident.BMCServiceDesk__FKUrgency__c || String.isBlank(newincident.HD_Ticket_Priority__c) )
          } //for( BMCServiceDesk__Incident__c oldincident : oldtriggerVersion )
        } //if( isInsertFlag == false )

        //More insert logic during insert update
        //Logic for adding default priority when no urgency is setted
        if (newincident.BMCServiceDesk__contactType__c == 'Mail Listen' && String.isBlank(newincident.BMCServiceDesk__FKUrgency__c)) {
          HD_Ticket_Priority__c ticket_priority = HD_Ticket_Priority__c.getInstance('default');
          newincident.HD_Ticket_Priority__c = ticket_priority.Priority_Name__c;
          newincident.BMCServiceDesk__FKUrgency__c = ticket_priority.Urgency_Id__c;

          if (ticket_priority.Priority_Id__c != NULL && ticket_priority.Priority_Id__c.trim() != '')
            newincident.BMCServiceDesk__FKPriority__c = ticket_priority.Priority_Id__c;

        } //if(newincident.BMCServiceDesk__contactType__c == 'Mail Listen' && String.isBlank(newincident.BMCServiceDesk__FKUrgency__c) )
        //Logic to add message when Priority is not selected
        if (String.isBlank(newincident.HD_Ticket_Priority__c)) {
          newincident.addError('Priority is mandatory. Please select a value from Priority list');
        } //if(String.isBlank(newincident.HD_Ticket_Priority__c))
      } //if(incident.RecordTypeId != recordTypeIdSI)
    } //for( BMCServiceDesk__Incident__c newincident : newtriggerVersion )
    // End of Priorty-Urgency Sync  - Kartikeya -CR 2614449
    */
  } //public void priorityUrgencySyncLogic()


//Usage: before insert update
  public void stampImpactAndManager() {
    System.debug('executing method -> serviceOwnerLowImpactLogic');
    Schema.DescribeSObjectResult userObject1 = User.SObjectType.getDescribe(); // To get prefix of the User object.
    String userIdPrefix = userObject1.getKeyPrefix();
    // altered code by hemant for CR 2341731 - Optimizing Helpdesk TestClases

    for (BMCServiceDesk__Incident__c newincident : newtriggerVersion) {
      if (newincident.RecordTypeId != recordTypeIdSI) {

        //CR 2545230 Start - by Kartikeya
        newincident.Last_Updated_Date_Time__c = System.now();
        //CR 2545230 End

        User Ownermanager = getVpUserMap().get(newincident.ownerid);
        if (userIdPrefix == (String.valueof(newincident.ownerid).substring(0, 3))) {
          if (getVpUserMap().containsKey((newincident.ownerid))) {
            newincident.HD_owner_manager__c = Ownermanager.managerId;
          } //if(vpUserMap.containsKey((newincident.ownerid)))
        } else {
          newincident.HD_owner_manager__c = null;
          //Samir added code for CR 2012518:Changing the Status to Assigned
        } //else
      } //if(incident.RecordTypeId != recordTypeIdSI)
    } //for(BMCServiceDesk__Incident__c newincident : newtriggerVersion)
  } //public void serviceOwnerLowImpactLogic()


//Usage @ before insert update
  public void updateBusinessServiceByUrgency() {
    for (BMCServiceDesk__Incident__c newincident : newtriggerVersion) {
      if (newincident.RecordTypeId != recordTypeIdSI) {
        // Set Service if Urgency is not Null while creating or updating the incident
        if (newincident.BMCServiceDesk__FKUrgency__c != null) {
          if (getUrgencyServiceMap().containsKey(newincident.BMCServiceDesk__FKUrgency__c)) {
            if (newincident.BMCServiceDesk__Type__c != 'Service Request') {
              newincident.BMCServiceDesk__FKBusinessService__c = getUrgencyServiceMap().get(newincident.BMCServiceDesk__FKUrgency__c);
            } //if((newincident.BMCServiceDesk__Type__c != 'Service Request') &&  isInsertFlag == true )
          } // if(urgencyServiceMap.containsKey(newincident.BMCServiceDesk__FKUrgency__c))
          else {
            //Ignore the error if the error is due to a BMC test class, as the view all data would not be set
            //Throw the error only if the static variable is set. It is set only by persistent test class - janantha.
            //if (Test.isRunningTest() == false)
            if (HD_TestClassCorrectionForTrigger.throwMappingError == true) {
              newincident.addError('No Services found for the selected urgency');
            } //if(HD_TestClassCorrectionForTrigger.throwMappingError == true)
          } //else
        } //if(newincident.BMCServiceDesk__FKUrgency__c != null)
      } //if (newincident.RecordTypeId != recordTypeIdSI)
    } //for(BMCServiceDesk__Incident__c newincident:newtriggerVersion)
  } //public void urgencyValue()





  public static void cascadeParentfieldsToChilds() {
    //kartikeya - CR 2728794 - Request Mgmt - Cascading Parent fields to child
    //List < Id > incident_ids = new List < Id > ();
    //List < Id > parent_ids = new List < Id > ();
    //MAP < Id, BMCServiceDesk__Incident__c > incident_map = new MAP < Id, BMCServiceDesk__Incident__c > ();
    ////List<BMCServiceDesk__Status__c> closedStatus = [Select id from BMCServiceDesk__Status__c where name = 'Closed'];

    //MAP < Id, BMCServiceDesk__Incident__c > parentIncidentMap = new MAP < Id, BMCServiceDesk__Incident__c > ();
    //List < BMCServiceDesk__Incident__c > actionHistoryIncidents = new List < BMCServiceDesk__Incident__c > ();

    //Integer i = 0;
    //for (BMCServiceDesk__Incident__c incident : newtriggerVersion) {
    //  if (getStatusListMap().containsKey('CLOSED') && incident.BMCServiceDesk__FKStatus__c != getStatusListMap().get('CLOSED').Id) {
    //    incident_ids.add(incident.Id);
    //    incident_map.put(incident.id, incident);
    //  }

    //  //if ((incident.BMCServiceDesk__FKIncident__c != null) || ((isInsertFlag == false) && incident.BMCServiceDesk__FKIncident__c != oldtriggerVersion[i].BMCServiceDesk__FKIncident__c)) {
    //  //  parent_ids.add(incident.BMCServiceDesk__FKIncident__c);
    //  //}
    //  if ((incident.BMCServiceDesk__FKIncident__c != null) || ((isInsertFlag == false) )) {
    //    parent_ids.add(incident.BMCServiceDesk__FKIncident__c);
    //  }

    //  i++;
    //} //


    //if (incident_ids.size() > 0) {
    //  List < BMCServiceDesk__Incident__c > child_incidents;

    //  child_incidents = [select Id, BMCServiceDesk__FKStatus__c, HD_Ticket_Priority__c, BMCServiceDesk__FKIncident__c from BMCServiceDesk__Incident__c where
    //                     BMCServiceDesk__FKIncident__c IN: incident_ids and BMCServiceDesk__FKStatus__c != : getStatusListMap().get('CLOSED').Id
    //                    ];

    //  BMCServiceDesk__Incident__c parentIncident;
    //  for (BMCServiceDesk__Incident__c incident : child_incidents) {
    //    parentIncident = incident_map.get(incident.BMCServiceDesk__FKIncident__c);
    //    incident.BMCServiceDesk__FKStatus__c = parentIncident.BMCServiceDesk__FKStatus__c;
    //    incident.HD_Ticket_Priority__c = parentIncident.HD_Ticket_Priority__c;

    //  }

    //  update child_incidents;
    //  //HD_RemedyForceCustomization_class.updateIncidents(child_incidents);

    //} //if Incident_ids.size()


    //if (parent_ids.size() > 0) {

    //  List < BMCServiceDesk__IncidentHistory__c > incidentHistoryList = new List < BMCServiceDesk__IncidentHistory__c > ();
    //  MAP < Id, BMCServiceDesk__Incident__c > parent_map = new MAP < Id, BMCServiceDesk__Incident__c > ();
    //  MAP < ID, String > incidentParentNameMap = new MAP < ID, String > ();

    //  for (BMCServiceDesk__Incident__c parent : [select Id, Name FROM BMCServiceDesk__Incident__c where ID IN: parent_ids and BMCServiceDesk__FKStatus__c != : getStatusListMap().get('CLOSED').Id]) {
    //    parent_map.put(parent.id, parent);
    //  }

    //  for (BMCServiceDesk__Incident__c incident : newtriggerVersion) {
    //    if (parent_map.containsKey(incident.BMCServiceDesk__FKIncident__c) && incident.BMCServiceDesk__FKStatus__c != getStatusListMap().get('CLOSED').Id) {
    //      incidentParentNameMap.put(incident.id, parent_map.get(incident.BMCServiceDesk__FKIncident__c).Name);
    //    }

    //  }
    //  if (incidentParentNameMap.size() > 0) {

    //    HD_IncidentUtils.insertIncidentHistory(incidentParentNameMap, getStatusListMap().get('CLOSED').Id);

    //  }

    //} //if(parent_ids.size() > 0)

    //End Of CR 2728794 - Request Mgmt - Cascading Parent fields to child


  } //public void cascadeParentfieldsToChilds()



//@Usage before insert and  before update
  public void ccFunctionalityandCheck() {

    //number of HD_EmailCC fields Limit
    Integer HD_EmailCC_present_limit = 10; //increased the limit to 10 , as per CR 2480916
    //define an Sobject
    Sobject incident_Sobject = new BMCServiceDesk__Incident__c();
    //find the latest version of object
    for (BMCServiceDesk__Incident__c inci_object : newtriggerVersion) {
      Sobject ast = inci_object;
      if (ast.getSObjectType() == BMCServiceDesk__Incident__c.sObjectType) {
        incident_Sobject = (BMCServiceDesk__Incident__c) ast;

        //Updated code patch for CR 2256617 By Hemant Kumar
        //Lets try to extract the User from the ClientID field
        String hkb_Client_id = String.valueOf(incident_Sobject.get('BMCServiceDesk__FKClient__c'));
        String hkb_Client_email = String.valueOf(incident_Sobject.get('BMCServiceDesk__clientEmail__c'));
        //system.debug('Client Email ------> '+String.valueOf(incident_Sobject.get('BMCServiceDesk__clientEmail__c')));
        //first lets check weather the ast.Exclude_Client_Notifications__c field is true or not
        if ((incident_Sobject.get('Exclude_Client_Notifications__c') != true) && (incident_Sobject.get('BMCServiceDesk__FKClient__c') != null)) {
          incident_Sobject.put('Client_ID_Email__c', hkb_Client_email);
        } else {
          incident_Sobject.put('Client_ID_Email__c', '');
        } //if( ast.Exclude_Client_Notifications__c != true )
        //END Lets try to extract the User from the ClientID field
        //END of  Updated code patch for CR 2256617 By Hemant Kumar

        //nullify all the fields first before proceeding ... ! Important
        for (Integer i = 0; i < HD_EmailCC_present_limit; i++) {
          incident_Sobject.put('HD_EmailCC' + (i + 1) + '__c', '');
        }

        //logic for extracting emails from CCtext Field
        object CctextValue = incident_Sobject.get('CCText__c');
        String rawcctext = null;
        if (CctextValue != null) {
          rawcctext = String.valueOf(CctextValue).normalizeSpace();
        }

        if ( rawcctext != null  && String.isNotBlank(rawcctext) && String.isNotEmpty(rawcctext) ) {
          //Staring code update for CR 2320427- Make CC field smarter, by Hemant

          //adding ; if its not present in the CCtext String
          if (!rawcctext.endsWith(';')) {
            rawcctext = rawcctext.normalizeSpace() + ';';
          }

          //START adding logic to re-sync the pattern for best match to solve the few errors
          rawcctext = rawcctext.normalizeSpace().deleteWhitespace();
          //System.debug('Pattern Rectifier value normalizeSpace() ------------------> '+ rawcctext );
          rawcctext = rawcctext.replaceAll('\\b(.com)\\b(.com)*', '.com');
          rawcctext = rawcctext.replaceAll('(,([\\,]*[\\s]*)*)', '');
          rawcctext = rawcctext.replaceAll('.com', '.com;');
          rawcctext = rawcctext.replaceAll('(\\b.com\\b)([\\s]*[;]*[\\s]*)*', '.com;');

          //System.debug('Pattern Rectifier value with regexp substitution; ------------------> '+ rawcctext );



          // Staring code fix CR 2331057 - RF: Helpdesk BugFix for the exception that is being thrown out wrt email cc fields
          if (rawcctext.contains(';;') == true) {
            rawcctext = rawcctext.replaceAll('([;])([\\s]*[;]*[\\s]*)*', ';');
            //System.debug('Pattern Rectifier value ;; to ; ------------------> '+ rawcctext );
          }
          if (rawcctext.contains('@@') == true) {
            rawcctext = rawcctext.replaceAll('\\b(@([\\@]*[\\s]*)*)\\b', '@');
            //System.debug('Pattern Rectifier value @@*  to @ with regexp ; ------------------> '+ rawcctext );
          }

          // END code fix CR 2331057 - RF: Helpdesk BugFix for the exception that is being thrown out wrt email cc fields



          //System.debug('Pattern Rectifier value ------------------> '+ rawcctext );

          //END adding logic to re-sync the pattern for best match to solve the few errors

          //now adding the patternised value to CcText Field Again !important
          incident_Sobject.put('CCText__c', rawcctext.normalizeSpace());

          //END of code update for CR 2320427- Make CC field smarter, by Hemant

          //checking the CCtext email integrity
          if (Pattern.matches('^((\\w+([-+.\']\\w+)*@akamai\\.com*([\\s]*?[;][\\s]*))*)$', rawcctext) == true) {
            // System.debug('--------> '+rawcctext.toLowerCase().trim());

            //START --> Logic Implemented for PRTORES-2190 - Duplicate email id's are displayed in Helpdesk Console
            List < String > ccList = rawcctext.toLowerCase().trim().split(';');
            List <String> ccTextEmails = new List<String>();
             for (Integer i = 0; i < ccList.size(); i++) {
                  if(!ccTextEmails.contains(ccList.get(i))){
                      ccTextEmails.add(ccList.get(i));
                  }    
              }
            incident_Sobject.put('CCText__c', String.join(ccTextEmails, ';') + ';');
            //END --> Logic Implemented for PRTORES-2190

            if ((ccTextEmails.size() > 0) && (ccTextEmails.size() < 11)) //increased the limit to 10 , as per CR 2480916

            {
              //now set the values based on CcText field
              for (Integer i = 0; i < ccTextEmails.size(); i++) {
                object currenttext = ccTextEmails.get(i);
                incident_Sobject.put('HD_EmailCC' + (i + 1) + '__c', currenttext);
              }
              
            } //if ( ( CcTextEmails.size() > 0 ) &&  (  CcTextEmails.size() < 11 ) )
            else {
              incident_Sobject.addError('You can enter up to 10 email addresses in the cc field. If 10 email ids are not specified, please verify if the corresponding category has any have pre-filled CCs'); //change in error message as per PRTORES-2189 //increased the limit to 10 , as per CR 2480916
              inci_object.CCText__c.addError('You can enter up to 10 email addresses in the cc field. If 10 email ids are not specified, please verify if the corresponding category has any have pre-filled CCs'); //change in error message as per PRTORES-2189 //increased the limit to 10 , as per CR 2480916
            } //if ( ( CcTextEmails.size() > 0 ) &&  (  CcTextEmails.size() < 11 ) )

          } // if( Pattern.matches *
          else {
            incident_Sobject.addError('Cc Field : 1. Only akamai.com emails are accepted ! 2. Please enter (;) at the end of every email if necessary ! 3. Accepts up-to 10 emails field '); //increased the limit to 10 , as per CR 2480916
            inci_object.CCText__c.addError('CCText : email pattern is not valid !');
          } // if( Pattern.matches *

        } //if( rawcctext != null )


      } //if(ast.getSObjectType() == BMCServiceDesk__Incident__c.sObjectType )

    } //for( BMCServiceDesk__Incident__c  inci_object : newtriggerVersion )

  } //public void ccFunctionalityandCheck()


//// START of CODE Update for CR 2378280   by Sreenidhi for Customer impact or Page Support field popup issue
//@Usage: before insert,update
  public void customerImpactPageSupportpopup() {

    for (BMCServiceDesk__Incident__c incident : newtriggerVersion) {

      if (incident.RecordTypeId != recordTypeIdSI) {
        if (incident.HD_Ticket_Priority__c == '1' && incident.HD_High_Customer_Impact__c != TRUE) {
          // CR 2943110 - Kartikeya
          HD_Apex_Messages__c apexMsg = HD_Apex_Messages__c.getInstance('SEV1 WARNING');
          if (apexMsg != null) {
            incident.addError(apexMsg.messageText__c);
          } else {
            incident.addError('Is this a customer impacting issue? Please note that Priority 1 issues would page the global technician. Please select Page Support Checkbox to confirm');
          }
          // End of CR 2943110 - Kartikeya

        }
      }
    } //end of for loop

  } //public void customerImpactPageSupportpopup()


//START of CR 2960174 by Hemant Kumar for SR_Priority__c and  HD_Ticket_Priority__c sync
//@Usage : before update,insert
  public void srINPrioritySync() {

    for (BMCServiceDesk__Incident__c incident : newtriggerVersion) {

      if (incident.HD_Ticket_Priority__c == '4') {
        incident.SR_Priority__c = 'Standard';
      } else if (incident.HD_Ticket_Priority__c == '3') {
        incident.SR_Priority__c = 'High';
      }else if(incident.HD_Ticket_Priority__c == '5') {
        incident.SR_Priority__c = 'Low';
      }
    } //for(BMCServiceDesk__Incident__c incident: Trigger.new)

  } //public void srINPrioritySync()
  //END of CR 2960174 by Hemant Kumar for SR_Priority__c and  HD_Ticket_Priority__c sync

//User Assigned to a region or not
//@usage : only before update
  public void incidentAssignedtoSameRegion() {

    //getting the current user id who is going to assign the user
    Id currentUSERID_ASSIGNEE = userinfo.getUserId(); // changed as part of CR 3100581 - HD same region ticket bug fix same assignee and owner does not show same region true
    Map < Id, User > LastModifiedBYID_owner_managerdetails = new Map < Id, User > ();
    //getting new version of Incident
    for (BMCServiceDesk__Incident__c incnewversion : newtriggerVersion) {
      //System.debug('OWNER ID DEBUG ------->'+incnewversion.OwnerID+' ----> '+vpUserMap.get(currentUSERID_ASSIGNEE));
      List < User > currentUsrList = new List < User > ();
      currentUsrList.add(getVpUserMap().get(currentUSERID_ASSIGNEE));
      for (User usr : currentUsrList) { //incnewversion.LastModifiedBYID //// changed as part of CR 3100581 - HD same region ticket bug fix same assignee and owner does not show same region true
        LastModifiedBYID_owner_managerdetails.put(usr.id, usr);
      }
      //system.debug('Size --->'+LastModifiedBYID_owner_managerdetails.get(currentUSERID_ASSIGNEE).managerId);//// changed as part of CR 3100581 - HD same region ticket bug fix same assignee and owner does not show same region true
      //System.debug('Ownermanager---->'+incnewversion.HD_Owner_Manager__c);
      if (String.valueOf(incnewversion.HD_Owner_Manager__c) != null && String.valueOf(incnewversion.HD_Owner_Manager__c).startsWith('005')) {
        if (LastModifiedBYID_owner_managerdetails.get(currentUSERID_ASSIGNEE).managerId == incnewversion.HD_Owner_Manager__c) { //// changed as part of CR 3100581 - HD same region ticket bug fix same assignee and owner does not show same region true
          incnewversion.Same_Region_Ticket__c = true;
        } else {
          incnewversion.Same_Region_Ticket__c = false;
        }
      } else {
        incnewversion.Same_Region_Ticket__c = false;
      }


    } //for( BMCServiceDesk__Incident__c incnewversion : trigger.new)


  } //public void incidentAssignedtoSameRegion()
  //Kartikeya- CR 2545230 -  Action history date/time to be made available for reporting
  //@Usage before , insert and update
  public void lastUpdatedDateTime() {
    for (BMCServiceDesk__Incident__c incident : newtriggerVersion) {
      if (incident.RecordTypeId != recordTypeIdSI)
        incident.Last_Updated_Date_Time__c = System.now();
    }

  } //public void lastUpdatedDateTime()


//usage @ isUpdate & isBefore
  public void changeFreeStatusToAssigned() {
    //MAP for triggering solution enablement team selective status free change
    System.debug('executing method -> changeFreeStatusToAssigned');
    Map < String, string > freeStatusEnablementMap = new Map < String, String > (); // add specific queue name to disable status reset logic
    //pranav - commenting as a part of SET changes. Having conflict and not required
    //Jira Ticket - PRTORES-163/ PRTORES-164/ PRTORES-165
    //freeStatusEnablementMap.put('Solution Enablement Team','Solution Enablement Team'); //Solution Enablement Team
    //freeStatusEnablementMap.put('Solution Center – Cambridge','Solution Center – Cambridge'); //Solution Center – Cambridge
    //freeStatusEnablementMap.put('Solution Center – Bangalore','Solution Center – Bangalore'); //Solution Center – Bangalore
    //freeStatusEnablementMap.put('Solution Center – Reston','Solution Center – Reston'); //Solution Center – Reston
    //freeStatusEnablementMap.put('Solution Center - Ft. Lauderdale','Solution Center - Ft. Lauderdale'); //Solution Center - Ft. Lauderdale
    //freeStatusEnablementMap.put('Solution Center - San Francisco','Solution Center - San Francisco'); //Solution Center - San Francisco
    //freeStatusEnablementMap.put('Solution Center – Krakow','Solution Center – Krakow'); //Solution Center – Krakow
    //freeStatusEnablementMap.put('Solution Center - Santa Clara','Solution Center - Santa Clara'); //Solution Center - Santa Clara
    //freeStatusEnablementMap.put('Solution Center – Munich','Solution Center – Munich'); //Solution Center – Munich
    //freeStatusEnablementMap.put('Solution Center – Singapore','Solution Center – Singapore'); //Solution Center – Singapore
    //freeStatusEnablementMap.put('Solution Center – Tokyo','Solution Center – Tokyo'); //Solution Center – Tokyo
    //freeStatusEnablementMap.put('Solution Center – London','Solution Center – London'); //Solution Center – London

    /*commenting below 4 lines because they are moved to custom setting*/
    freeStatusEnablementMap.put('HR-PAYROLL-APJ', 'HR-PAYROLL-APJ'); //HR-PAYROLL-APJ
    freeStatusEnablementMap.put('HR-PAYROLL-EMEA', 'HR-PAYROLL-EMEA'); //HR-PAYROLL-EMEA
    freeStatusEnablementMap.put('HR-PAYROLL-INDIA', 'HR-PAYROLL-INDIA'); //HR-PAYROLL-INDIA
    freeStatusEnablementMap.put('HR-PAYROLL-US/AMERICAS', 'HR-PAYROLL-US/AMERICAS'); //HR-PAYROLL-US/AMERICAS

    List<HD_FreeStatusQueues__C> freeQueues = HD_FreeStatusQueues__c.getall().values();
    for (HD_FreeStatusQueues__C queue : freeQueues) {
      freeStatusEnablementMap.put(queue.name, queue.name);
    }

    Schema.DescribeSObjectResult userObject2 = User.SObjectType.getDescribe(); // To get prefix of the User object.
    String userIdPrefix = userObject2.getKeyPrefix();
    LIST < BMCServiceDesk__Incident__c > old_incidents = oldtriggerVersion;
    Integer idx = -1;

    Map<ID, BMCServiceDesk__Incident__c> oldIncidentMap = getIncidentOldValueMap();
    for (BMCServiceDesk__Incident__c incident1 : newtriggerVersion) {

      idx += 1;
      //Change Status to Assigned from On Hold Statuses (Pending for **) on change of owner.
      Set<String> holdStatuses = new Set<String> {'ON HOLD', 'PENDING CMR', 'PENDING HARDWARE', 'PENDING SOFTWARE', 'PENDING USER RESPONSE', 'PENDING OTHER TEAMS', 'PENDING APPROVAL', 'PENDING OTHERS'};

      if (userIdPrefix == (String.valueof(incident1.ownerid).substring(0, 3)) && oldIncidentMap != null && incident1.ownerid !=  oldIncidentMap.get(incident1.id).ownerid  && holdStatuses.contains(incident1.BMCServiceDesk__Status_ID__c ) ) {

        Incident1.BMCServiceDesk__FKStatus__c = getStatusListMap().get('ASSIGNED').id;
      }
      //CR 3395561 - Cancelling to be enabled for end users and staff users and mandatroy to enter the note for the reason
      //Added CANCELED in the if condition along side CLOSED as their behaviour is same
      //DEV NAME - PRANAV

      if (userIdPrefix != (String.valueof(incident1.ownerid).substring(0, 3)) && ((incident1.BMCServiceDesk__FKStatus__c != getStatusListMap().get('CLOSED').id) && (incident1.BMCServiceDesk__FKStatus__c != getStatusListMap().get('CANCELED').id))) {

        if (!freeStatusEnablementMap.containsKey(getGroupIDMap().get(incident1.ownerid).name) && Incident1.BMCServiceDesk__FKStatus__c != getStatusListMap().get('REOPENED').id) {

          if (oldIncidentMap != null && (( oldIncidentMap.get(incident1.id).OwnerId != incident1.ownerid  && (getGroupNameMap().get('Default Queue') !=null && oldIncidentMap.get(incident1.id).OwnerId != getGroupNameMap().get('Default Queue').id)) ||
              (oldIncidentMap.get(incident1.id).BMCServiceDesk__FKStatus__c == getStatusListMap().get('REASSIGNED').id))) {

            Incident1.BMCServiceDesk__FKStatus__c = getStatusListMap().get('REASSIGNED').id;
            //End Of CR3264691
          } else {
            Incident1.BMCServiceDesk__FKStatus__c = getStatusListMap().get('UNASSIGNED').id;
          }
        }

      } else {
        System.debug('userIdPrefix = ' + userIdPrefix + ' incident1.ownerid = ' + incident1.ownerid + ' oldIncidentMap = ' + oldIncidentMap);
        if ((userIdPrefix == (String.valueof(incident1.ownerid).substring(0, 3))) && (oldIncidentMap != null) && (userIdPrefix == (String.valueof((oldIncidentMap.get(incident1.id)).ownerid).substring(0, 3)))) {

          //CR: 2144287 :By Kartikeya Date: 1 Apr 2013
          // Re-assigning Status value  to 'Assigned' when a incident re-opened from closed status, having a user(not a Queue) as owner.
          //CR: 2978183 :By Kartikeya
          HD_DataLoad__c dataLoadConfig = HD_DataLoad__c.getInstance('Update Closed');
          Boolean Updaterequired = true;
          if (dataLoadConfig != null && dataLoadConfig.TextValue__c != 'true') {
            Updaterequired = false;
          }
          if (String.valueof(oldIncidentMap.get(Incident1.id).BMCServiceDesk__Status_ID__c) == 'CLOSED' && Updaterequired == true && Incident1.BMCServiceDesk__Status_ID__c != 'CLOSED') {
            Incident1.BMCServiceDesk__FKStatus__c = getStatusListMap().get('ASSIGNED').id;
          }
          //PRANAV - To Handle the status: CANCELED same as CLOSED
          //CR 3395561
          if (String.valueof(oldIncidentMap.get(Incident1.id).BMCServiceDesk__Status_ID__c) == 'CANCELED' && Updaterequired == true && Incident1.BMCServiceDesk__Status_ID__c != 'CANCELED') {
            Incident1.BMCServiceDesk__FKStatus__c = getStatusListMap().get('ASSIGNED').id;
          } // CR 3395561
          // End of CR: 2144287
          //Do Nothing as both owners are users so no need to change status.
        } else if ((Incident1.BMCServiceDesk__Status_ID__c != 'CLOSED' || Incident1.BMCServiceDesk__Status_ID__c != 'CANCELED') && (userIdPrefix == (String.valueof(incident1.ownerid).substring(0, 3))) && (oldIncidentMap != null) && (userIdPrefix != (String.valueof((oldIncidentMap.get(incident1.id)).ownerid).substring(0, 3)))) {
          //This means the new owner is a user while the last owner was a queue so change status to assigned.
          Incident1.BMCServiceDesk__FKStatus__c = getStatusListMap().get('ASSIGNED').id;
        }
      }
    }
  }

//usage @ isBefore & isInsert or isUpdate
//Bugzilla – CR 2833248-Kartikeya populating VP Approver for Service Request approvals
//Bug fix Bugzill CR 2861220 - SRM_Director approval required for Technology Refresh template
  public void stampVPApproverForSR() {

    //get request definitions map

    for (BMCServiceDesk__Incident__c incident : newtriggerVersion) {
      if (incident.BMCServiceDesk__Type__c == 'Service Request' || incident.HD_Test_Value__c == 'Service Request') {
        //List < BMCServiceDesk__SRM_RequestDefinition__c > ReqDefns = [Select VP_Approver_Required__c FROM BMCServiceDesk__SRM_RequestDefinition__c where ID = : incident.BMCServiceDesk__FKRequestDefinition__c LIMIT 1];

        if (getRequestDefinitions().size() > 0 && getRequestDefinitions().containsKey(incident.BMCServiceDesk__FKRequestDefinition__c)) {
          BMCServiceDesk__SRM_RequestDefinition__c rd = getRequestDefinitions().get(incident.BMCServiceDesk__FKRequestDefinition__c);
          if (rd != null && rd.VP_Approver_Required__c == true) {
            User c_usr = getVpUserMap().get(incident.BMCServiceDesk__FKClient__c);
            if (c_usr != null) {
              User usr = (vpUserMap.containsKey(c_usr.ManagerID)) ? vpUserMap.get(c_usr.ManagerID) : null;
              while (usr != null) {

                if ( usr.Title != Null &&  ( usr.Title.contains('Director')  || usr.Title.contains('Vice President') || usr.Title.contains('SVP') || usr.Title.contains('CIO') ) ) {
                  incident.HD_VP_Approver__c = usr.id;
                  break;
                }

                // Search manager's Title for VP.
                if (vpUserMap.containsKey(usr.ManagerID))
                  usr = vpUserMap.get(usr.ManagerID);
                else {
                  break;
                }

              }//while
            }
          }
        }

      }
    }
  }

//usage @IsUpdate & IsBefore
  public void restrictReopenBeforeChanges() {
    if (oldtriggerVersion != null && oldtriggerVersion.size() > 0) {
      HD_RestrictReopen restrictRepoen = HD_RestrictReopen.getInstance(oldtriggerVersion, newtriggerVersion, getGroupNameMap(), getVpUserMap());
      restrictRepoen.beforeUpdateChanges();
    }
  }

//usage @IsUpdate & IsBefore
  public void checkForValidReopen() {
    for (BMCServiceDesk__Incident__c incident : newtriggerVersion) {
      if (incidentOldValueMap.get(incident.id).BMCServiceDesk__Status_ID__c == 'CLOSED' && incident.BMCServiceDesk__Status_ID__c != 'CLOSED') {
        if (incident.Follows_Restrictive_Reopen__c) {
          if (incident.Valid_Days_to_Reopen__c != null && incidentOldValueMap.get(incident.id).Closed_Date__c!=null) {
            if (System.now() > incidentOldValueMap.get(incident.id).Closed_Date__c + incident.Valid_Days_to_Reopen__c) {
              incident.addError('Ticket is closed for more than ' + incident.Valid_Days_to_Reopen__c + ' days. Please raise a new ticket');
            }
          }
        }
      }
    }
  }


  //Kartikeya - SLA Bug PRTORES-520 Stamping Incident Group Field.
  // this is required if one changes category on routing set to override. WFs do'nt kick in then
  //@usage before update and insert
  public void stampIncidentGroup() {
    for (BMCServiceDesk__Incident__c incident : newtriggerVersion) {
      category_map = getCategoryMap();
      BMCServiceDesk__Category__c cat =  category_map.get(incident.BMCServiceDesk__FKCategory__c);
      if (cat != null)
        incident.HD_IncidentGroup__c = cat.BMCServiceDesk__categoryType_Id__c;
      // When staff users creates incident with Override routing ticket is assigned to user who created the incident.
      //incident.BMCServiceDesk__FKStatus__c=statusMap.get('ASSIGNED').id;
    }//END  PRTORES-520
  }

//Fix for CR 2995661- Resolution gets added to clone HD tickets- Komal
//usage @isInsert & isBefore
  public void clearResolutionForCloning() {
    for (BMCServiceDesk__Incident__c incident : newtriggerVersion) {
      if ((incident.BMCServiceDesk__UpdateCount__c <= 1) && (incident.RecordTypeId != recordTypeIdSI)) { //recordtype check
        incident.BMCServiceDesk__incidentResolution__c = '';
        incident.Effort_Estimation__c = '';
        //pranav - PRTORES-625 -- tickets cloned with routing set to override routing skip the
        //routing logic
        //fix --  setting routing to default before creation
        incident.HD_Routing_Settings__c = 'Default Routing';
        //fix issue at time of cloning --  addded by pranav
        //cases where a ticket is cloned from Remedyforce consel with Assigned Status - it goes to REASSIGNED status
        //For details see REASSIGNED logic in trigger
        
        incident.ownerId = getGroupNameMap().get('Default Queue') != null ? getGroupNameMap().get('Default Queue').ID : incident.ownerId ;
      	
      }
    }
  }

  public void aferUpdateRestrictReopen() {
    HD_RestrictReopen restrictRepoen = HD_RestrictReopen.getInstance(oldtriggerVersion, newtriggerVersion, getGroupNameMap(), getVpUserMap());
    restrictRepoen.afterUpdateChanges();
  }



  public void addReadAccess(){

      HD_IncidentRecordSharing.setReadAccess(newtriggerVersion);

  }

  public void revokeAccess(){

      	List<ID> recordIds = new List<ID>();
        for(BMCServiceDesk__Incident__c inc : newtriggerVersion){
          recordIds.add(inc.id);
        }

      HD_IncidentRecordSharing.revokeAccess(recordIds);

  }
} //END OF CLASS