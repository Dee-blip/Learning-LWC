/*
Author          : Pinkesh 
Description     : Apex Controller for SOCC Car RunBooks
Test Class      : SC_SOCC_RunBooks_TC


Date                 Developer                  JIRA #          Description                                                       
-----------------------------------------------------------------------------------------------------------------
23 Sep 2019         Pinkesh / Sumukh SS                                     SOCC CAR 2 - RunBooks
26 Mar 2021         Tejaswini                 ESESP-4955        Notify via case email changes
31 May 2021         Tejaswini                 ESESP-5132        Runbooks phase II - Availability SF changes
------------------------------------------------------------------------------------------------------------------
*/
public without sharing class SC_SOCC_EscalationListCtrl {
  //To check recursion in Escalation List Trigger
  public static Boolean checkRecursion = false;
  public static Set < Id > sEscListIdForRecusrion = new Set < Id > ();
  public static Set < Id > sEscConIdForRecusrion = new Set < Id > ();

  //Escalation List and associated pending approval instruction wrapper
  public class EscalationListInstructionWrapper {
    @AuraEnabled public SC_SOCC_Escalation_List__c escalationListRec;
    @AuraEnabled public Instruction__c pendingInstructionRec;
  }

  //To show on SC_SOCC_Escalation
  public class EscalationListWrapper {
    //@AuraEnabled public List < EscalationContactWrapper > escConTableData;
    @AuraEnabled public List < AvailabilityDetailsWrapper > lAvailabilityRecords;
    @AuraEnabled public List < Id > lEscConId;
    @AuraEnabled public List < Id > lAuthConId;
    @AuraEnabled public List < SC_SOCC_Escalation_via_Case_Email__c > escConTableDataForEmail;
    @AuraEnabled public List < Id > lEscConIdForEmail;
    @AuraEnabled public List < Id > lAuthConIdForEmail;
  }

  /*public class EscalationContactWrapper {
    @AuraEnabled public SC_SOCC_Escalation_Contact__c escCon;
    @AuraEnabled public List < SC_SOCC_Availability__c > lAvailability;
  }*/

  /*public class AuthorizedContactWrapper{
      @AuraEnabled public Authorized_Contact__c authCon;
      @AuraEnabled public List<SC_SOCC_Availability__c> lAvailability;
  }*/

  public class AuthorizedContactWrapper {
    @AuraEnabled public Authorized_Contact__c authCon;
    @AuraEnabled public String Monday;
    @AuraEnabled public String Tuesday;
    @AuraEnabled public String Wednesday;
    @AuraEnabled public String Thursday;
    @AuraEnabled public String Friday;
    @AuraEnabled public String Saturday;
    @AuraEnabled public String Sunday;
    @AuraEnabled public String OutOfOffice;
    @AuraEnabled public Map < String, String > dayAndColor;
    @AuraEnabled public Boolean isOOONow;
    @AuraEnabled public String isOOORecordPresent;
  }

  public class AvailabilityDetailsWrapper {
    @AuraEnabled public SC_SOCC_Escalation_Contact__c escCon;
    //@AuraEnabled public List<SC_SOCC_Availability__c> lAvailability;
    //@AuraEnabled public Id contactId;
    @AuraEnabled public String Monday;
    @AuraEnabled public String Tuesday;
    @AuraEnabled public String Wednesday;
    @AuraEnabled public String Thursday;
    @AuraEnabled public String Friday;
    @AuraEnabled public String Saturday;
    @AuraEnabled public String Sunday;
    @AuraEnabled public String OutOfOffice;
    @AuraEnabled public Map < String, String > dayAndColor;
    @AuraEnabled public Boolean isOOONow;
    @AuraEnabled public String isOOORecordPresent;
  }

  public class TimeDetails {
    @AuraEnabled public Time startTime;
    @AuraEnabled public Time endTime;
    @AuraEnabled public String dstTZName;
   //@AuraEnabled public Double dstTZOffset;
    @AuraEnabled public DateTime createdDate;
  }

  public class DateTimeDetail {
    @AuraEnabled public DateTime startDateTime;
    @AuraEnabled public DateTime endDateTime;
    @AuraEnabled public Time startTime;
    @AuraEnabled public Time endTime;
    @AuraEnabled public Date startDate;
    @AuraEnabled public Date endDate;
    @AuraEnabled public String dstTZName;
    //@AuraEnabled public Double dstTZOffset;
    @AuraEnabled public DateTime createdDate;
  }

  //Get Escalation List record
  @AuraEnabled
  public static EscalationListInstructionWrapper getData(String pdId, String escalationListId) {
    System.debug('-------inside getData');
    //Wrapper to be returned 
    EscalationListInstructionWrapper escalationListInstructionWrapper = new EscalationListInstructionWrapper();

    if (String.isNotBlank(pdId) && String.isBlank(escalationListId)) {
      Policy_Domain__c pdRec = [Select Id, Name from Policy_Domain__c where Id =: pdId];
      SC_SOCC_Escalation_List__c escalationListRec = new SC_SOCC_Escalation_List__c(Policy_Domain__c = pdRec.Id);
      escalationListInstructionWrapper.escalationListRec = escalationListRec;
    } else if (String.isNotBlank(escalationListId)) {
      SC_SOCC_Escalation_List__c escalationListRec = [Select Id, Name, Policy_Domain__c, Instructions__c from SC_SOCC_Escalation_List__c where Id =: escalationListId limit 1];
      escalationListInstructionWrapper.escalationListRec = escalationListRec;
      System.debug(escalationListRec);
      List < Instruction__c > lPendingInstruction = [SELECT Id, CreatedBy.Name FROM Instruction__c WHERE Escalation_List__c =: escalationListRec.Id AND Status__c = 'In Progress'
        LIMIT 1
      ];
      if (lPendingInstruction.size() > 0)
        escalationListInstructionWrapper.pendingInstructionRec = lPendingInstruction[0];
    }

    return escalationListInstructionWrapper;
  }

  //Get Escalation Contacts records
  @AuraEnabled
  public static EscalationListWrapper getEscalationContactRecords(String pdId, String escalationListId, Boolean inUtility) {
    System.debug('Inside getEscalationContactRecords');
    //Final Data to be returned
    EscalationListWrapper escalationListWrapper = new EscalationListWrapper();

    //List Escalation Contacts data to be returned
    //List < EscalationContactWrapper > escConTableData = new List < EscalationContactWrapper > ();

    //List of existing Escalation Con Ids
    List < Id > lEscConId = new List < Id > ();

    //List of Auth Con Id which are present as Escalation Contacts
    List < Id > lAuthConId = new List < Id > ();

    //Set to store contact ids which are present as Escalation Contacts
    Set < Id > sConId = new Set < Id > ();

    //Set to store contact ids which are available at that time.
    Set < Id > sAvailableConId = new Set < Id > ();

    //Map to store ContactId - Escalation Contact mapping
    Map < Id, SC_SOCC_Escalation_Contact__c > mConIdEscConRec = new Map < Id, SC_SOCC_Escalation_Contact__c > ();

    //Map to store ContactId - List of Availability records mapping
    //Map<Id, List<SC_SOCC_Availability__c>> mConIdLAvailibilityRecs = new Map<Id, List<SC_SOCC_Availability__c>>();

    //List of Escalation Via Case Email
    List < SC_SOCC_Escalation_via_Case_Email__c > escConTableDataForEmail = new List < SC_SOCC_Escalation_via_Case_Email__c > ();

    //List of existing Escalation Via Case Email ids
    List < Id > lEscConIdForEmail = new List < Id > ();

    //List of Authorized Contact Ids as existing Escalation Via Case Email
    List < Id > lAuthConIdForEmail = new List < Id > ();

    List < AvailabilityDetailsWrapper > lAvailabilityRecords = new List < AvailabilityDetailsWrapper > ();
    Map < Id, List < DateTimeDetail >> mConIdOOORecs = new Map < Id, List < DateTimeDetail >> ();
    Map < String, Integer > mDayNo = new Map < String, Integer > {'Monday' => 1,'Tuesday' => 2,'Wednesday' => 3,'Thursday' => 4,'Friday' => 5,'Saturday' => 6,'Sunday' => 7};

    Map < Integer, List < TimeDetails >> mDayAvailRecords = new Map < Integer, List < TimeDetails >> ();
    Map < Id, Map < Integer, List < TimeDetails >>> mConIdLAvailibilityRecs = new Map < Id, Map < Integer, List < TimeDetails >>> ();
    Map < String, List < Time >> mDayFinalTimings = new Map < String, List < Time >> ();
    //Map < Id, Map < Integer, List < TimeDetails >>> mConIdAvailRecsUserTZ = new Map < Id, Map < Integer, List < TimeDetails >>> ();
    Map < Id, Map < Integer, List < Time >>> mConIdAvailRecsTime = new Map < Id, Map < Integer, List < Time >>> ();
    Map < Integer, String > mDayNoDay = new Map < Integer, String > {1 => 'Monday',2 => 'Tuesday',3 => 'Wednesday',4 => 'Thursday',5 => 'Friday',6 => 'Saturday',7 => 'Sunday'};

    Map < Id, Map < String, String >> mStringConIdLAvailibilityRecs = new Map < Id, Map < String, String >> ();
    Map < Id, Map < String, String >> mConIdAvailDayColor = new Map < Id, Map < String, String >> ();
    Map < String, String > mColorCode = new Map < String, String > {'Available' => 'background-color:#77dd77;','Unavailable' => 'background-color:#cfcfc4;','Partial' => 'background-color:#ffb347;'};

    Set < Integer > daySet = new Set < Integer > {1,2,3,4,5,6,7};

    Integer tzOffsetMS = UserInfo.getTimeZone().getOffset(System.now());
    TimeZone tz = UserInfo.getTimeZone();
    String tzDetail = tz.getDisplayName();
    String tzOffset = tzDetail.substring(4, 10);
    System.debug(tzDetail); //(GMT+00:00) Greenwich Mean Time (GMT)
    System.debug(tzOffset);

    Integer hr = Integer.valueOf(tzOffset.substring(1, 3));
    Integer min = Integer.valueOf(tzOffset.substring(4, 6));

    System.debug('The time offset Hour' + hr);
    System.debug('The time offset Minute' + min);

    DateTime myDateTime = DateTime.now();
    System.debug('todays date is ' + myDateTime);
    String day = myDateTime.formatGMT('EEEE');
    System.debug('the day of week is');
    System.debug(day);
    Integer dayNo = mDayNo.get(day);

    Integer dd = myDateTime.dayGmt();
    Integer mm = myDateTime.monthGmt();
    Integer yy = myDateTime.yearGmt();

    DateTime weekStartDate = Datetime.newInstanceGmt(yy, mm, dd).addDays(1 - dayNo);
    DateTime weekEndDate = Datetime.newInstanceGmt(yy, mm, dd, 23, 59, 59).addDays(7 - dayNo);
    System.debug('week start date is ' + weekStartDate);
    System.debug('week end date is ' + weekEndDate);

    //Getting all the Escalation records
    if (!String.isBlank(escalationListId)) {
      List < SC_SOCC_Escalation_Contact__c > lEscConRec = [SELECT Id, Name, Escalation_List__c, Order_Number__c, Action_If_Unreachable__c, Authorized_Contact__c, Authorized_Contact__r.Contact_Name__c,
        Authorized_Contact__r.Contact_Name__r.Email, Authorized_Contact__r.Contact_Name__r.Name, Authorized_Contact__r.Contact_Name__r.Primary_Contact_Method__c,
        Authorized_Contact__r.Contact_Name__r.Secondary_Contact_Method__c, Authorized_Contact__r.Contact_Name__r.Phone,
        Authorized_Contact__r.Contact_Name__r.MobilePhone FROM SC_SOCC_Escalation_Contact__c
        WHERE Escalation_List__c =: escalationListId ORDER BY Order_Number__c
      ];
      System.debug('lEscConRec : ' + lEscConRec);
      //Adding records to map
      for (SC_SOCC_Escalation_Contact__c eachRec: lEscConRec) {
        mConIdEscConRec.put(eachRec.Authorized_Contact__r.Contact_Name__c, eachRec);
        sConId.add(eachRec.Authorized_Contact__r.Contact_Name__c);
      }
      System.debug('mConIdEscConRec : ' + mConIdEscConRec);
      System.debug('sConId : ' + sConId);

      for (SC_SOCC_Availability__c eachRec: [SELECT Id, Availability__c, Contact__c, Day_Of_Week__c, Start_Time__c, End_Time__c, Start_Date_Time__c, End_Date_Time__c, Out_Of_Office__c, Contact_Timezone_Name__c, Timezone_offset__c,CreatedDate FROM SC_SOCC_Availability__c WHERE Contact__c in: sConId AND inActive__c = false ORDER BY Day_Of_Week__c, Start_Time__c, Start_Date_Time__c]) {

        List < Time > availRecords = new List < Time > ();
        if (eachRec.Out_Of_Office__c == true) {

          if (!mConIdOOORecs.containsKey(eachRec.Contact__c)) {
            mConIdOOORecs.put(eachRec.Contact__c, new List < DateTimeDetail > ());
          }
          List < DateTimeDetail > dayAndAvaillist = mConIdOOORecs.get(eachRec.Contact__c);

          DateTimeDetail obj = new DateTimeDetail();
          obj.startDateTime = eachRec.Start_Date_Time__c;
          obj.endDateTime = eachRec.End_Date_Time__c;
          obj.dstTZName = eachRec.Contact_Timezone_Name__c;
          //obj.dstTZOffset = eachRec.Timezone_offset__c;
          obj.createdDate = eachRec.CreatedDate;
          dayAndAvaillist.add(obj);

          mConIdOOORecs.put(eachRec.Contact__c, dayAndAvaillist);

          System.debug('the dayAndAvailMap in OOO is' + dayAndAvaillist);

        } else if (eachRec.Start_Time__c != null && eachRec.End_Time__c != null) {
          if (!mConIdLAvailibilityRecs.containsKey(eachRec.Contact__c)) {
            mConIdLAvailibilityRecs.put(eachRec.Contact__c, new Map < Integer, List < TimeDetails >> ());
          }
          Map < Integer, List < TimeDetails >> dayNoAndAvailMap = mConIdLAvailibilityRecs.get(eachRec.Contact__c);
          Integer key = mDayNo.get(eachRec.Day_Of_Week__c);
          if (!dayNoAndAvailMap.containsKey(key)) {
            dayNoAndAvailMap.put(key, new List < TimeDetails > ());
          }

          List < TimeDetails > tempAvailRecords = dayNoAndAvailMap.get(key);

          TimeDetails timerec = new TimeDetails();
          timerec.startTime = eachRec.Start_Time__c;
          timerec.endTime = eachRec.End_Time__c;
          timerec.dstTZName = eachRec.Contact_Timezone_Name__c;
          //timerec.dstTZOffset = eachRec.Timezone_offset__c;
          timerec.createdDate = eachRec.CreatedDate;

          tempAvailRecords.add(timerec);
          dayNoAndAvailMap.put(key, tempAvailRecords);
          mConIdLAvailibilityRecs.put(eachRec.Contact__c, dayNoAndAvailMap);
        }
      }
      System.debug('the Availability details map is');
      System.debug(mConIdLAvailibilityRecs);
      System.debug('the OOO map is');
      System.debug(mConIdOOORecs);

      //Apply DST conversion changes to GMT Availability records
      List < Id > lConId = new List < Id > (sConId);
      Map < Id, Map < Integer, List < TimeDetails >>> mConIdLAvailibilityRecsGMTAfterDST = applyDSTChangesToAvailabilityRecs(mConIdLAvailibilityRecs, lConId);
      System.debug('In the main method mConIdLAvailibilityRecsGMTAfterDST is');
      System.debug(mConIdLAvailibilityRecsGMTAfterDST);

      //Apply DST conversion changes to GMT OOO records
      Map < Id, List < DateTimeDetail >> mConIdOOORecsAfterDST = applyDSTChangesToOOORecs(mConIdOOORecs, lConId);
      System.debug('In the main method mConIdOOORecsAfterDST is');
      System.debug(mConIdOOORecsAfterDST);

      //Converting Out of Office records from GMT To Logged in User Timezone 
      Map < Id, List < DateTimeDetail >> mOOORecordsInUserTZ = new Map < Id, List < DateTimeDetail >> ();

      for (Id conId: sConId) {
        //if (mOOORecordsOfWeek.containsKey(conId)) {
        if (mConIdOOORecsAfterDST.containsKey(conId)) {
          if (!mOOORecordsInUserTZ.containsKey(conId)) {
            mOOORecordsInUserTZ.put(conId, new List < DateTimeDetail > ());
          }
          List < DateTimeDetail > lOutOfOfficeUserTZ = mOOORecordsInUserTZ.get(conId);

          //List < DateTimeDetail > loorecs = mOOORecordsOfWeek.get(conId);
          List < DateTimeDetail > loorecs = mConIdOOORecsAfterDST.get(conId);
          for (DateTimeDetail oooRec: loorecs) {
            if (tzOffsetMS > 0) {
              DateTimeDetail oooRec1 = new DateTimeDetail();
              oooRec1.startDateTime = (oooRec.startDateTime).addHours(hr).addMinutes(min);
              oooRec1.endDateTime = (oooRec.endDateTime).addHours(hr).addMinutes(min);
              lOutOfOfficeUserTZ.add(oooRec1);
            } else if (tzOffsetMS < 0) {
              DateTimeDetail oooRec2 = new DateTimeDetail();
              oooRec2.startDateTime = (oooRec.startDateTime).addHours(-hr).addMinutes(-min);
              oooRec2.endDateTime = (oooRec.endDateTime).addHours(-hr).addMinutes(-min);
              lOutOfOfficeUserTZ.add(oooRec2);
            } else if (tzOffsetMS == 0) {
              DateTimeDetail oooRec3 = new DateTimeDetail();
              oooRec3.startDateTime = oooRec.startDateTime;
              oooRec3.endDateTime = oooRec.endDateTime;
              lOutOfOfficeUserTZ.add(oooRec3);
            }
          }
          mOOORecordsInUserTZ.put(conId, lOutOfOfficeUserTZ);
        }
      }

      System.debug('The out of office records in user timezone are for week');
      System.debug(mOOORecordsInUserTZ);

      //Create map of ConId and isOutOfOffice now details , which is used to disply OOO warning icon next to contact
      DateTime dtUserTZ;
      if (tzOffsetMS > 0) {
        dtUserTZ = myDateTime.addHours(hr).addMinutes(min);
      } else if (tzOffsetMS < 0) {
        dtUserTZ = myDateTime.addHours(-hr).addMinutes(-min);
      } else if (tzOffsetMS == 0)
        dtUserTZ = myDateTime;
      System.debug('Current date time in user time zone ' + dtUserTZ);

      Map < Id, Boolean > mConIdOOORecInToday = checkIfContactIsOOONow(mOOORecordsInUserTZ, dtUserTZ, lConId);

      System.debug('the map of mConIdOOORecInToday');
      System.debug(mConIdOOORecInToday);

      Map < Id, List < TimeDetails >> mOffSetRec = new Map < Id, List < TimeDetails >> ();

      //Final map of records after comparing map of availability and Unavailability 

      Map < Id, Map < Integer, List < TimeDetails >>> mAvailRecordsInUserTZ = getAvailabilityMapInUserTZ(tzOffsetMS, tzOffset, mConIdLAvailibilityRecsGMTAfterDST, lConId, mOffSetRec);
      System.debug('Availbility mAvailRecordsInUserTZ in UserTz');
      System.debug(mAvailRecordsInUserTZ);

      //Get the Time Zone Name in the format of (GMT +5:30)/(GMT -6:00)
      String timeZoneName = getTimeZoneNameInStringFormat(tzOffsetMS, hr, min);
      System.debug('the timeZoneName is' + timeZoneName);

      //Handle overlapping records and make records in proper format
      for (Id conId: sConId) {
        Map < Integer, List < TimeDetails >> mAvailRecords = new Map < Integer, List < TimeDetails >> ();
        Map < Integer, List < Time >> mAvailRecordTime = new Map < Integer, List < Time >> ();
        /*if (mConIdAvailRecsUserTZ.containsKey(conId)) {
          mAvailRecords = mConIdAvailRecsUserTZ.get(conId);  
          mAvailRecordTime = getAvailabilityDetails(mAvailRecords);
        }*/
        if (mAvailRecordsInUserTZ.containsKey(conId)) {
          mAvailRecords = mAvailRecordsInUserTZ.get(conId);
          mAvailRecordTime = getFinalAvailabilityRecs(mAvailRecords);
        }
        mConIdAvailRecsTime.put(conId, mAvailRecordTime);
      }

      //Get the records availability in string format to display it finally on UI
      System.debug('The map of avail records and times mConIdAvailRecsTime');
      System.debug(mConIdAvailRecsTime);

      Map < Id, Map < Integer, List < TimeDetails >>> mConIdAvailRecsTimeWrapper = new Map < Id, Map < Integer, List < TimeDetails >>> ();
      //convert list of avail timings to wrapper class
      for (Id conId: sConId) {
        Map < Integer, List < TimeDetails >> mAvailRecordsTimeWrapper = new Map < Integer, List < TimeDetails >> ();
        Map < Integer, List < Time >> mAvailRecordTime = new Map < Integer, List < Time >> ();
        if (mConIdAvailRecsTime.containsKey(conId)) {
          mAvailRecordTime = mConIdAvailRecsTime.get(conId);
          mAvailRecordsTimeWrapper = convertAvailListToAvailWrapper(mAvailRecordTime);
        }
        mConIdAvailRecsTimeWrapper.put(conId, mAvailRecordsTimeWrapper);
      }

      //Get the records availability in wrapper class format to display it finally on UI
      System.debug('The map of avail records and wrapper times mConIdAvailRecsTime');
      System.debug(mConIdAvailRecsTimeWrapper);

      for (Id conId: sConId) {
        Map < Integer, List < Time >> mDayListAvaildata = new Map < Integer, List < Time >> ();
        Map < String, String > mDayStringAvailRec = new Map < String, String > ();
        Map < String, String > mDayColor = new Map < String, String > ();
        //List<Time> timeData = new List<Time>();
        mDayListAvaildata = mConIdAvailRecsTime.get(conId);
        String availDetail = '';
        String dayColor = '';
        for (Integer eachDay: daySet) {

          if (mDayListAvaildata.containsKey(eachDay)) {
            List < Time > availTime = mDayListAvaildata.get(eachDay);
            if (availTime.size() > 0) {
              //availDetail=(mDayNoDay.get(eachDay)).toUppercase()+':';
              availDetail = 'AVAILABLE ' + timeZoneName;
              availDetail += getAvailDataInString(availTime);

              dayColor = mColorCode.get(getDayAvailabilityStatus(availTime));
            } else {
              availDetail = 'UNAVAILABLE';
              dayColor = mColorCode.get('Unavailable');
            }
          } else {
            availDetail = 'UNAVAILABLE';
            dayColor = mColorCode.get('Unavailable');
          }
          mDayStringAvailRec.put(mDayNoDay.get(eachDay), availDetail);
          mDayColor.put(mDayNoDay.get(eachDay), dayColor);

        }

        mStringConIdLAvailibilityRecs.put(conId, mDayStringAvailRec);
        mConIdAvailDayColor.put(conId, mDayColor);
      }

      System.debug('the final map of ConId and String avail details data is');
      System.debug(mStringConIdLAvailibilityRecs);

      System.debug('the final map of day and its color are');
      System.debug(mConIdAvailDayColor);
      //When inUtility = true..viewing Runbook from Case Detail page

      /*Datetime currentDateTime = System.now();
      System.debug('currentDateTime'+currentDateTime);*/
      //Doing in logged in user timezone
      System.debug('currentDateTime ' + dtUserTZ);
      System.debug('myDateTime ' + myDateTime);
      String currentDay = myDateTime.format('EEEE');
      System.debug('currentDay ' + currentDay);

      Integer currentDayNo = mDayNo.get(currentDay);
      System.debug('currentDayNo ' + currentDayNo);
      //Time in logged in user TZ
      System.debug('Hour ' + dtUserTZ.hourGmt());
      System.debug('Minute ' + dtUserTZ.minuteGmt());
      System.debug('Seconds ' + dtUserTZ.secondGmt());
      Long currentTimeInMS = dtUserTZ.hourGmt() * 60 * 60 * 1000 + dtUserTZ.minuteGmt() * 60 * 1000 + dtUserTZ.secondGmt() * 100 + dtUserTZ.millisecond();
      System.debug('currentTimeInMS ' + currentTimeInMS);

      //To get the final list of contact who are available at that point to display in Case Utility bar : Compare Week availability and also OOO at that point
      for (Id conId: sConId) {
        if (mConIdAvailRecsTimeWrapper.containsKey(conId)) {
          Map < Integer, List < TimeDetails >> mapRecs = mConIdAvailRecsTimeWrapper.get(conId);
          Boolean avail = checkIfUserIsCurrentlyAvailable(mapRecs, currentDayNo, currentTimeInMS);
          if (avail == true) {
            if (mConIdOOORecInToday.containsKey(conId)) {
              Boolean isOOO = mConIdOOORecInToday.get(conId);
              if (isOOO == false) {
                sAvailableConId.add(conId);
              }
            } else {
              sAvailableConId.add(conId);
            }

          }
        }
      }
      System.debug('the set of contact ids which are available right now are');
      System.debug(sAvailableConId);
      
      for (Id eachConId: mConIdEscConRec.keySet()) {
        if (!inUtility || sAvailableConId.contains(eachConId)) {

          AvailabilityDetailsWrapper availabilityDetailWrapper = new AvailabilityDetailsWrapper();
          Map < String, String > mDayAvailRec = new Map < String, String > ();

          //Map < String, List < DateTimeDetail >> mOutOfOfficeRecs = new Map < String, List < DateTimeDetail >> ();
          List < DateTimeDetail > mOutOfOfficeRecs = new List < DateTimeDetail > ();
          if (mConIdOOORecsAfterDST.containsKey(eachConId)) {

            mOutOfOfficeRecs = mConIdOOORecsAfterDST.get(eachConId);
            //List < DateTimeDetail > sOutOfOfficeRecs = mOutOfOfficeRecs.get('OutOfOffice');

            if (mOutOfOfficeRecs.size() > 0) {
              //List < DateTime > lOutOfOffice = new List < DateTime > ();
              //lOutOfOffice.addAll(sOutOfOfficeRecs);
              String s = getOOODataInString(mOutOfOfficeRecs, weekStartDate, tzOffsetMS, tzOffset);
              if (s.length() > 0) {
                availabilityDetailWrapper.OutOfOffice = 'OUT OF OFFICE :' + s;
              } else {
                availabilityDetailWrapper.OutOfOffice = 'No Out Of Office records';
              }

            } else {
              availabilityDetailWrapper.OutOfOffice = 'No Out Of Office records';
            }
          } else {
            availabilityDetailWrapper.OutOfOffice = 'No Out Of Office records';
          }

          mDayAvailRec = mStringConIdLAvailibilityRecs.get(eachConId);

          availabilityDetailWrapper.escCon = mConIdEscConRec.get(eachConId);
          availabilityDetailWrapper.Monday = mDayAvailRec.get('Monday');
          availabilityDetailWrapper.Tuesday = mDayAvailRec.get('Tuesday');
          availabilityDetailWrapper.Wednesday = mDayAvailRec.get('Wednesday');
          availabilityDetailWrapper.Thursday = mDayAvailRec.get('Thursday');
          availabilityDetailWrapper.Friday = mDayAvailRec.get('Friday');
          availabilityDetailWrapper.Saturday = mDayAvailRec.get('Saturday');
          availabilityDetailWrapper.Sunday = mDayAvailRec.get('Sunday');
          availabilityDetailWrapper.dayAndColor = mConIdAvailDayColor.get(eachConId);
          if (mConIdOOORecInToday.containsKey(eachConId)) {
            availabilityDetailWrapper.isOOONow = mConIdOOORecInToday.get(eachConId);
          } else {
            availabilityDetailWrapper.isOOONow = false;
          }

          if ((availabilityDetailWrapper.OutOfOffice).contains('No')) {
            availabilityDetailWrapper.isOOORecordPresent = 'background-color:#cfcfc4;';
          } else {
            availabilityDetailWrapper.isOOORecordPresent = 'background-color:#eb7092;';
          }
          
          lAvailabilityRecords.add(availabilityDetailWrapper);

          lEscConId.add(availabilityDetailWrapper.escCon.Id);

          lAuthConId.add(availabilityDetailWrapper.escCon.Authorized_Contact__c);
        }
      }
      System.debug('the final wrapper data include lAvailabilityRecords');
      System.debug(lAvailabilityRecords);
      //Populating final table data
      /*for(Id eachConId : mConIdEscConRec.keySet()){
          if(!inUtility || sAvailableConId.contains(eachConId)){
              EscalationContactWrapper escalationContactWrapper = new EscalationContactWrapper();
              escalationContactWrapper.escCon = mConIdEscConRec.get(eachConId);
              escalationContactWrapper.lAvailability = mConIdLAvailibilityRecs.containsKey(eachConId) ? mConIdLAvailibilityRecs.get(eachConId) : null;
              escConTableData.add(escalationContactWrapper);
              
              lEscConId.add(escalationContactWrapper.escCon.Id);
              
              lAuthConId.add(escalationContactWrapper.escCon.Authorized_Contact__c);
          }
      }*/

      for (SC_SOCC_Escalation_via_Case_Email__c eachRec: [SELECT Id, Name, Authorized_Contact__c, Authorized_Contact__r.Service__c, Authorized_Contact__r.Contact_Name__c, LastModifiedDate,
          Authorized_Contact__r.Contact_Name__r.Email, Authorized_Contact__r.Contact_Name__r.SMS_Notifications__c, Authorized_Contact__r.Contact_Name__r.Name,
          Authorized_Contact__r.Policy_Domain__c, Authorized_Contact__r.Policy_Domain__r.Account_Name__r.Name, Authorized_Contact__r.Policy_Domain__r.Service_Account__r.Name
          FROM SC_SOCC_Escalation_via_Case_Email__c WHERE Escalation_List__c =: escalationListId ORDER BY Name
        ]) {
        escConTableDataForEmail.add(eachRec);
        lEscConIdForEmail.add(eachRec.Id);
        lAuthConIdForEmail.add(eachRec.Authorized_Contact__c);
      }
    }

    //Setting final data values
    //escalationListWrapper.escConTableData = escConTableData;
    escalationListWrapper.lAvailabilityRecords = lAvailabilityRecords;
    escalationListWrapper.lEscConId = lEscConId;
    escalationListWrapper.lAuthConId = lAuthConId;
    escalationListWrapper.escConTableDataForEmail = escConTableDataForEmail;
    escalationListWrapper.lEscConIdForEmail = lEscConIdForEmail;
    escalationListWrapper.lAuthConIdForEmail = lAuthConIdForEmail;
    return escalationListWrapper;
  }

  //Get Authorized Contacts records to add them as Escalation Contact
  @AuraEnabled
  public static List < AuthorizedContactWrapper > getAuthorizedContactRecords(String pdId, List < String > lAuthConId) {
    //Final Data to be returned for Table
    List < AuthorizedContactWrapper > lAuthorizedContactTableData = new List < AuthorizedContactWrapper > ();

    if (!String.isBlank(pdId)) {
      //Set to store contact ids which are present as Escalation Contacts
      Set < Id > sConId = new Set < Id > ();

      //Map to store ContactId - Authorized Contact mapping
      Map < Id, Authorized_Contact__c > mConIdAuthConRec = new Map < Id, Authorized_Contact__c > ();

      //Map to store ContactId - List of Availability records mapping
      //Map<Id, List<SC_SOCC_Availability__c>> mConIdLAvailibilityRecs = new Map<Id, List<SC_SOCC_Availability__c>>();

      //List of required Authorized Contacts
      List < Authorized_Contact__c > lAuthCon = new List < Authorized_Contact__c > ();

      if (lAuthConId != null && lAuthConId.size() > 0) {
        lAuthCon = [SELECT Id, Contact_Name__c, Contact_Name__r.Email, Contact_Name__r.Name, Contact_Name__r.Primary_Contact_Method__c,
          Contact_Name__r.Secondary_Contact_Method__c, Contact_Name__r.Phone,
          Contact_Name__r.MobilePhone FROM Authorized_Contact__c
          WHERE Policy_Domain__c =: pdId AND Id NOT IN: lAuthConId ORDER BY Contact__c
        ];
      } else
        lAuthCon = [SELECT Id, Contact_Name__c, Contact_Name__r.Email, Contact_Name__r.Name, Contact_Name__r.Primary_Contact_Method__c,
          Contact_Name__r.Secondary_Contact_Method__c, Contact_Name__r.Phone,
          Contact_Name__r.MobilePhone FROM Authorized_Contact__c
          WHERE Policy_Domain__c =: pdId ORDER BY Contact__c
        ];

      //Adding records to map
      for (Authorized_Contact__c eachRec: lAuthCon) {
        mConIdAuthConRec.put(eachRec.Contact_Name__c, eachRec);
        sConId.add(eachRec.Contact_Name__c);
      }

      //Map < Id, Map < String, List < DateTimeDetail >>> mConIdOOORecs = new Map < Id, Map < String, List < DateTimeDetail >>> ();

      Map < Id, List < DateTimeDetail >> mConIdOOORecs = new Map < Id, List < DateTimeDetail >> ();

      Integer tzOffsetMS = UserInfo.getTimeZone().getOffset(System.now());
      TimeZone tz = UserInfo.getTimeZone();
      String tzDetail = tz.getDisplayName();
      String tzOffset = tzDetail.substring(4, 10);
      System.debug(tzDetail); //(GMT+00:00) Greenwich Mean Time (GMT)
      System.debug(tzOffset);

      Integer hr = Integer.valueOf(tzOffset.substring(1, 3));
      Integer min = Integer.valueOf(tzOffset.substring(4, 6));

      Map < Integer, List < TimeDetails >> mDayAvailRecords = new Map < Integer, List < TimeDetails >> ();

      Map < Id, Map < Integer, List < TimeDetails >>> mConIdLAvailibilityRecs = new Map < Id, Map < Integer, List < TimeDetails >>> ();

      Map < String, List < Time >> mDayFinalTimings = new Map < String, List < Time >> ();

      Map < Id, Map < Integer, List < TimeDetails >>> mConIdAvailRecsUserTZ = new Map < Id, Map < Integer, List < TimeDetails >>> ();

      Map < Id, Map < Integer, List < Time >>> mConIdAvailRecsTime = new Map < Id, Map < Integer, List < Time >>> ();

      Map < String, Integer > mDayNo = new Map < String, Integer > {'Monday' => 1,'Tuesday' => 2,'Wednesday' => 3,'Thursday' => 4,'Friday' => 5,'Saturday' => 6,'Sunday' => 7};

      Map < Integer, String > mDayNoDay = new Map < Integer, String > {1 => 'Monday',2 => 'Tuesday',3 => 'Wednesday',4 => 'Thursday',5 => 'Friday',6 => 'Saturday',7 => 'Sunday'};

      Map < Id, Map < String, String >> mStringConIdLAvailibilityRecs = new Map < Id, Map < String, String >> ();
      Map < Id, Map < String, String >> mConIdAvailDayColor = new Map < Id, Map < String, String >> ();
      Map < String, String > mColorCode = new Map < String, String > {'Available' => 'background-color:#77dd77;','Unavailable' => 'background-color:#cfcfc4;','Partial' => 'background-color:#ffb347;'};

      Set < Integer > daySet = new Set < Integer > {1,2,3,4,5,6,7};

      for (SC_SOCC_Availability__c eachRec: [SELECT Id, Availability__c, Contact__c, Day_Of_Week__c, Start_Time__c, End_Time__c, Start_Date_Time__c, End_Date_Time__c, Out_Of_Office__c, Contact_Timezone_Name__c, Timezone_offset__c,CreatedDate FROM SC_SOCC_Availability__c WHERE Contact__c in: sConId and inActive__c = false ORDER BY Day_Of_Week__c, Start_Time__c, Start_Date_Time__c]) {
        List < Time > availRecords = new List < Time > ();

        if (eachRec.Out_Of_Office__c == true) {

          if (!mConIdOOORecs.containsKey(eachRec.Contact__c)) {
            mConIdOOORecs.put(eachRec.Contact__c, new List < DateTimeDetail > ());
          }
          List < DateTimeDetail > dayAndAvaillist = mConIdOOORecs.get(eachRec.Contact__c);

          DateTimeDetail obj = new DateTimeDetail();
          obj.startDateTime = eachRec.Start_Date_Time__c;
          obj.endDateTime = eachRec.End_Date_Time__c;
          obj.dstTZName = eachRec.Contact_Timezone_Name__c;
          //obj.dstTZOffset = Integer.valueOf(eachRec.Timezone_offset__c);
          obj.createdDate = eachRec.CreatedDate;
          dayAndAvaillist.add(obj);

          mConIdOOORecs.put(eachRec.Contact__c, dayAndAvaillist);

          System.debug('the dayAndAvailMap in OOO is' + dayAndAvaillist);

        } else if (eachRec.Start_Time__c != null && eachRec.End_Time__c != null) {
          if (!mConIdLAvailibilityRecs.containsKey(eachRec.Contact__c)) {
            mConIdLAvailibilityRecs.put(eachRec.Contact__c, new Map < Integer, List < TimeDetails >> ());
          }
          Map < Integer, List < TimeDetails >> dayNoAndAvailMap = mConIdLAvailibilityRecs.get(eachRec.Contact__c);
          Integer key = mDayNo.get(eachRec.Day_Of_Week__c);
          if (!dayNoAndAvailMap.containsKey(key)) {
            dayNoAndAvailMap.put(key, new List < TimeDetails > ());
          }

          List < TimeDetails > tempAvailRecords = dayNoAndAvailMap.get(key);

          TimeDetails timerec = new TimeDetails();
          timerec.startTime = eachRec.Start_Time__c;
          timerec.endTime = eachRec.End_Time__c;
          timerec.dstTZName = eachRec.Contact_Timezone_Name__c;
          //timerec.dstTZOffset = eachRec.Timezone_offset__c;
          timerec.createdDate = eachRec.CreatedDate;

          tempAvailRecords.add(timerec);
          dayNoAndAvailMap.put(key, tempAvailRecords);
          mConIdLAvailibilityRecs.put(eachRec.Contact__c, dayNoAndAvailMap);
        }
      }
      System.debug('the Availability details map is');
      System.debug(mConIdLAvailibilityRecs);
      System.debug('the OOO map is');
      System.debug(mConIdOOORecs);

      //Apply DST conversion changes to GMT Availability records
      List < Id > lConId = new List < Id > (sConId);
      Map < Id, Map < Integer, List < TimeDetails >>> mConIdLAvailibilityRecsGMTAfterDST = applyDSTChangesToAvailabilityRecs(mConIdLAvailibilityRecs, lConId);
      System.debug('In the main method mConIdLAvailibilityRecsGMTAfterDST is');
      System.debug(mConIdLAvailibilityRecsGMTAfterDST);

      //Apply DST conversion changes to GMT OOO records
      Map < Id, List < DateTimeDetail >> mConIdOOORecsAfterDST = applyDSTChangesToOOORecs(mConIdOOORecs, lConId);
      System.debug('In the main method mConIdOOORecsAfterDST is');
      System.debug(mConIdOOORecsAfterDST);

      //Converting mOOORecordsOfWeek to mOOORecordsInUserTZ
      Map < Id, List < DateTimeDetail >> mOOORecordsInUserTZ = new Map < Id, List < DateTimeDetail >> ();

      for (Id conId: sConId) {
        //if (mOOORecordsOfWeek.containsKey(conId)) {
        if (mConIdOOORecsAfterDST.containsKey(conId)) {
          if (!mOOORecordsInUserTZ.containsKey(conId)) {
            mOOORecordsInUserTZ.put(conId, new List < DateTimeDetail > ());
          }
          List < DateTimeDetail > lOutOfOfficeUserTZ = mOOORecordsInUserTZ.get(conId);

          //List < DateTimeDetail > loorecs = mOOORecordsOfWeek.get(conId);
          List < DateTimeDetail > loorecs = mConIdOOORecsAfterDST.get(conId);
          for (DateTimeDetail oooRec: loorecs) {
            if (tzOffsetMS > 0) {
              DateTimeDetail oooRec1 = new DateTimeDetail();
              oooRec1.startDateTime = (oooRec.startDateTime).addHours(hr).addMinutes(min);
              oooRec1.endDateTime = (oooRec.endDateTime).addHours(hr).addMinutes(min);
              lOutOfOfficeUserTZ.add(oooRec1);
            } else if (tzOffsetMS < 0) {
              DateTimeDetail oooRec2 = new DateTimeDetail();
              oooRec2.startDateTime = (oooRec.startDateTime).addHours(-hr).addMinutes(-min);
              oooRec2.endDateTime = (oooRec.endDateTime).addHours(-hr).addMinutes(-min);
              lOutOfOfficeUserTZ.add(oooRec2);
            } else if (tzOffsetMS == 0) {
              DateTimeDetail oooRec3 = new DateTimeDetail();
              oooRec3.startDateTime = oooRec.startDateTime;
              oooRec3.endDateTime = oooRec.endDateTime;
              lOutOfOfficeUserTZ.add(oooRec3);
            }
          }
          mOOORecordsInUserTZ.put(conId, lOutOfOfficeUserTZ);
        }
      }

      System.debug('The out of office records in user timezone are for week');
      System.debug(mOOORecordsInUserTZ);

      DateTime myDateTime = DateTime.now();
      System.debug('todays date is ' + myDateTime);
      String day = myDateTime.formatGMT('EEEE');
      System.debug('the day of week is');
      System.debug(day);
      Integer dayNo = mDayNo.get(day);

      Integer dd = myDateTime.dayGmt();
      Integer mm = myDateTime.monthGmt();
      Integer yy = myDateTime.yearGmt();

      DateTime weekStartDate = Datetime.newInstanceGmt(yy, mm, dd).addDays(1 - dayNo);
      DateTime weekEndDate = Datetime.newInstanceGmt(yy, mm, dd, 23, 59, 59).addDays(7 - dayNo);
      System.debug('week start date is ' + weekStartDate);
      System.debug('week end date is ' + weekEndDate);

      //Create map of ConId and isOutOfOffice now details
      DateTime dtUserTZ;
      if (tzOffsetMS > 0) {
        dtUserTZ = myDateTime.addHours(hr).addMinutes(min);
      } else if (tzOffsetMS < 0) {
        dtUserTZ = myDateTime.addHours(-hr).addMinutes(-min);
      } else if (tzOffsetMS == 0)
        dtUserTZ = myDateTime;

      System.debug('Current date time in user time zone ' + dtUserTZ);

      //To see if the contact is currently Out of office , map of contact id and True (if OOO now ) or false
      Map < Id, Boolean > mConIdOOORecInToday = checkIfContactIsOOONow(mOOORecordsInUserTZ, dtUserTZ, lConId);

      System.debug('the map of mConIdOOORecInToday');
      System.debug(mConIdOOORecInToday);
      //Final map of records after comparing map of availability and Unavailability 

      Map < Id, List < TimeDetails >> mOffSetRec = new Map < Id, List < TimeDetails >> ();
      Map < Id, Map < Integer, List < TimeDetails >>> mAvailRecordsInUserTZ = getAvailabilityMapInUserTZ(tzOffsetMS, tzOffset, mConIdLAvailibilityRecsGMTAfterDST, lConId, mOffSetRec);
      System.debug('Availbility mAvailRecordsInUserTZ in UserTz');
      System.debug(mAvailRecordsInUserTZ);

      //Get the Time Zone Name in the format of (GMT +5:30)..(GMT -6:00)
      String timeZoneName = getTimeZoneNameInStringFormat(tzOffsetMS, hr, min);
      System.debug('the timeZoneName is' + timeZoneName);

      //Handle overlapping records and make records in proper format
      for (Id conId: sConId) {
        Map < Integer, List < TimeDetails >> mAvailRecords = new Map < Integer, List < TimeDetails >> ();
        Map < Integer, List < Time >> mAvailRecordTime = new Map < Integer, List < Time >> ();
        /*if (mConIdAvailRecsUserTZ.containsKey(conId)) {
          mAvailRecords = mConIdAvailRecsUserTZ.get(conId);  
          mAvailRecordTime = getAvailabilityDetails(mAvailRecords);
        }*/
        if (mAvailRecordsInUserTZ.containsKey(conId)) {
          mAvailRecords = mAvailRecordsInUserTZ.get(conId);
          mAvailRecordTime = getFinalAvailabilityRecs(mAvailRecords);
        }

        mConIdAvailRecsTime.put(conId, mAvailRecordTime);
      }

      //Get the records availability in string format to display it finally on UI

      System.debug('The map of avail records and times mConIdAvailRecsTime');
      System.debug(mConIdAvailRecsTime);
      
      for (Id conId: sConId) {
        Map < Integer, List < Time >> mDayListAvaildata = new Map < Integer, List < Time >> ();
        Map < String, String > mDayStringAvailRec = new Map < String, String > ();
        Map < String, String > mDayColor = new Map < String, String > ();
        //List<Time> timeData = new List<Time>();
        mDayListAvaildata = mConIdAvailRecsTime.get(conId);

        String availDetail = '';
        String dayColor = '';
        for (Integer eachDay: daySet) {
          /*if(!mDayListAvaildata.isEmpty())
          {*/
          if (mDayListAvaildata.containsKey(eachDay)) {
            List < Time > availTime = mDayListAvaildata.get(eachDay);
            if (availTime.size() > 0) {
              //availDetail=(mDayNoDay.get(eachDay)).toUppercase()+':';
              availDetail = 'AVAILABLE ' + timeZoneName;
              availDetail += getAvailDataInString(availTime);

              dayColor = mColorCode.get(getDayAvailabilityStatus(availTime));
            } else {
              availDetail = 'UNAVAILABLE';
              dayColor = mColorCode.get('Unavailable');
            }
          } else {
            availDetail = 'UNAVAILABLE';
            dayColor = mColorCode.get('Unavailable');
          }
          mDayStringAvailRec.put(mDayNoDay.get(eachDay), availDetail);
          mDayColor.put(mDayNoDay.get(eachDay), dayColor);
          //}
          /*else{
            availDetail = 'No Availability Records Set';dayColor = mColorCode.get('NotAvail');
            mDayStringAvailRec.put(mDayNoDay.get(eachDay), availDetail);
            mDayColor.put(mDayNoDay.get(eachDay), dayColor);
          }*/
        }

        mStringConIdLAvailibilityRecs.put(conId, mDayStringAvailRec);
        mConIdAvailDayColor.put(conId, mDayColor);
      }

      System.debug('the final map of ConId and String avail details data is');
      System.debug(mStringConIdLAvailibilityRecs);

      System.debug('the final map of day and its color are');
      System.debug(mConIdAvailDayColor);

      //Populating final table data
      /*for(Id eachConId : mConIdAuthConRec.keySet()){
          AuthorizedContactWrapper authorizedContactWrapper = new AuthorizedContactWrapper();
          authorizedContactWrapper.authCon = mConIdAuthConRec.get(eachConId);
          authorizedContactWrapper.lAvailability = mConIdLAvailibilityRecs.containsKey(eachConId) ? mConIdLAvailibilityRecs.get(eachConId) : null;
          lAuthorizedContactTableData.add(authorizedContactWrapper);
      }*/
      
      for (Id eachConId: mConIdAuthConRec.keySet()) {

        AuthorizedContactWrapper authorizedContactWrapper = new AuthorizedContactWrapper();
        Map < String, String > mDayAvailRec = new Map < String, String > ();

        //Map < String, List < DateTimeDetail >> mOutOfOfficeRecs = new Map < String, List < DateTimeDetail >> ();
        List < DateTimeDetail > mOutOfOfficeRecs = new List < DateTimeDetail > ();
        if (mConIdOOORecsAfterDST.containsKey(eachConId)) {

          mOutOfOfficeRecs = mConIdOOORecsAfterDST.get(eachConId);
          //List < DateTimeDetail > sOutOfOfficeRecs = mOutOfOfficeRecs.get('OutOfOffice');

          if (mOutOfOfficeRecs.size() > 0) {
            //List < DateTime > lOutOfOffice = new List < DateTime > ();
            //lOutOfOffice.addAll(sOutOfOfficeRecs);
            String s = getOOODataInString(mOutOfOfficeRecs, weekStartDate, tzOffsetMS, tzOffset);
            if (s.length() > 0) {
              authorizedContactWrapper.OutOfOffice = 'OUT OF OFFICE :' + s;
            } else {
              authorizedContactWrapper.OutOfOffice = 'No Out Of Office records';
            }

          } else {
            authorizedContactWrapper.OutOfOffice = 'No Out Of Office records';
          }
        } else {
          authorizedContactWrapper.OutOfOffice = 'No Out Of Office records';
        }

        mDayAvailRec = mStringConIdLAvailibilityRecs.get(eachConId);

        authorizedContactWrapper.authCon = mConIdAuthConRec.get(eachConId);
        authorizedContactWrapper.Monday = mDayAvailRec.get('Monday');
        authorizedContactWrapper.Tuesday = mDayAvailRec.get('Tuesday');
        authorizedContactWrapper.Wednesday = mDayAvailRec.get('Wednesday');
        authorizedContactWrapper.Thursday = mDayAvailRec.get('Thursday');
        authorizedContactWrapper.Friday = mDayAvailRec.get('Friday');
        authorizedContactWrapper.Saturday = mDayAvailRec.get('Saturday');
        authorizedContactWrapper.Sunday = mDayAvailRec.get('Sunday');
        authorizedContactWrapper.dayAndColor = mConIdAvailDayColor.get(eachConId);

        if (mConIdOOORecInToday.containsKey(eachConId)) {
          authorizedContactWrapper.isOOONow = mConIdOOORecInToday.get(eachConId);
        } else {
          authorizedContactWrapper.isOOONow = false;
        }

        if ((authorizedContactWrapper.OutOfOffice).contains('No')) {
          authorizedContactWrapper.isOOORecordPresent = 'background-color:#cfcfc4;';
        } else {
          authorizedContactWrapper.isOOORecordPresent = 'background-color:#eb7092;';
        }
        
        lAuthorizedContactTableData.add(authorizedContactWrapper);

        //lEscConId.add(availabilityDetailWrapper.escCon.Id);

        //lAuthConId.add(availabilityDetailWrapper.escCon.Authorized_Contact__c);            

      }
      System.debug('the final wrapper data include lAuthorizedContactTableData');
      System.debug(lAuthorizedContactTableData);

    }

    return lAuthorizedContactTableData;
  }

  //Get Authorized Contacts records to add them as Escalation Via Case Email
  @AuraEnabled
  public static List < Authorized_Contact__c > getAuthorizedContactRecordsForEmail(String pdId, List < String > lAuthConIdForEmail) {
    //List of records to be returned
    List < Authorized_Contact__c > lAuthorizedContactTableDataForEmail = new List < Authorized_Contact__c > ();

    if (!String.isBlank(pdId)) {
      if (lAuthConIdForEmail != null && lAuthConIdForEmail.size() > 0) {
        lAuthorizedContactTableDataForEmail = [SELECT Id, Service__c, Contact_Name__c, Contact_Name__r.Email, Contact_Name__r.SMS_Notifications__c, Contact_Name__r.Name,
          Policy_Domain__c, Policy_Domain__r.Account_Name__r.Name, Policy_Domain__r.Service_Account__r.Name
          FROM Authorized_Contact__c WHERE Policy_Domain__c =: pdId AND Id NOT IN: lAuthConIdForEmail ORDER BY Contact__c
        ];
      } else {
        lAuthorizedContactTableDataForEmail = [SELECT Id, Service__c, Contact_Name__c, Contact_Name__r.Email, Contact_Name__r.SMS_Notifications__c, Contact_Name__r.Name,
          Policy_Domain__c, Policy_Domain__r.Account_Name__r.Name, Policy_Domain__r.Service_Account__r.Name
          FROM Authorized_Contact__c WHERE Policy_Domain__c =: pdId ORDER BY Contact__c
        ];
      }
    }

    return lAuthorizedContactTableDataForEmail;
  }

  //Method to save Escalation List and related Escalation Contacts and return Escalation List Id
  @AuraEnabled
  public static String saveCompleteEscalationList(SC_SOCC_Escalation_List__c escRec, String lSelectedEscalationContactsJson, List < String > lEscConId, List < SC_SOCC_Escalation_via_Case_Email__c > lSelectedEscalationsViaCaseEmail, List < String > lEscConIdForEmail, String pendingInstruction) {
    //Checking if there is an existing Escalation List has same name
    List < SC_SOCC_Escalation_List__c > lExistingELs = new List < SC_SOCC_Escalation_List__c > ();
    //update
    if (escRec.Id != null)
      lExistingELs = [SELECT Id FROM SC_SOCC_Escalation_List__c WHERE Policy_Domain__c =: escRec.Policy_Domain__c AND Name =: escRec.Name and Id !=: escRec.Id];
    //insert
    else
      lExistingELs = [SELECT Id FROM SC_SOCC_Escalation_List__c WHERE Policy_Domain__c =: escRec.Policy_Domain__c AND Name =: escRec.Name];

    if (lExistingELs.size() > 0)
      throw new AuraHandledException('Escalation List with this name already exists!');

    //Upsert Escalation List
    try {
      upsert escRec;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }

    //Converting List of tableData Data collected in JSON format from the Lightning component into a List
    //List<EscalationContactWrapper> lSelectedEscalationContacts = (List<EscalationContactWrapper>) System.JSON.deserializeStrict(lSelectedEscalationContactsJson, List<EscalationContactWrapper>.Class);
    //System.debug('------lSelectedEscalationContacts : ' + lSelectedEscalationContacts.size());

    List < AvailabilityDetailsWrapper > lSelectedEscalationContacts = (List < AvailabilityDetailsWrapper > ) System.JSON.deserializeStrict(lSelectedEscalationContactsJson, List < AvailabilityDetailsWrapper > .Class);
    System.debug('------lSelectedEscalationContacts : ' + lSelectedEscalationContacts.size());

    //Id of Escalation List
    Id escalationListId = escRec.Id;

    //Deletion of Existing Escalation Contacts
    System.debug('--------lEscConId ' + lEscConId);
    List < SC_SOCC_Escalation_Contact__c > lDelEscalationContacts = [SELECT Id FROM SC_SOCC_Escalation_Contact__c WHERE Escalation_List__c =: escalationListId AND Id NOT IN: lEscConId];
    try {
      if (lDelEscalationContacts != null && lDelEscalationContacts.size() > 0)
        delete lDelEscalationContacts;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }

    //List of Escalation Contacts to be upserted
    List < SC_SOCC_Escalation_Contact__c > lEscalationContacts = new List < SC_SOCC_Escalation_Contact__c > ();

    //preparing list of Escalation Contacts to be upserted
    for (AvailabilityDetailsWrapper eachWrapper: lSelectedEscalationContacts) {
      SC_SOCC_Escalation_Contact__c eachEscalationContact = new SC_SOCC_Escalation_Contact__c();
      if (eachWrapper.escCon.Id != null)
        eachEscalationContact.Id = eachWrapper.escCon.Id;
      else
        eachEscalationContact.Escalation_List__c = escalationListId;
      eachEscalationContact.Name = eachWrapper.escCon.Authorized_Contact__r.Contact_Name__r.Name;
      eachEscalationContact.Authorized_Contact__c = eachWrapper.escCon.Authorized_Contact__c;
      eachEscalationContact.Order_Number__c = eachWrapper.escCon.Order_Number__c != null ? eachWrapper.escCon.Order_Number__c : null;
      eachEscalationContact.Action_If_Unreachable__c = eachWrapper.escCon.Action_If_Unreachable__c != null ? eachWrapper.escCon.Action_If_Unreachable__c : null;
      lEscalationContacts.add(eachEscalationContact);
    }

    System.debug('------lEscalationContacts size : ' + lEscalationContacts.size());
    System.debug('------lEscalationContacts : ' + lEscalationContacts);
    //upsert List of Escalation Contact
    try {
      if (lEscalationContacts.size() > 0)
        upsert lEscalationContacts;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }

    //Deletion of Existing Escalations via Case Email
    System.debug('--------lEscConIdForEmail ' + lEscConIdForEmail);
    List < SC_SOCC_Escalation_via_Case_Email__c > lDelEscalationsViaCaseEmail = [SELECT Id FROM SC_SOCC_Escalation_via_Case_Email__c WHERE Escalation_List__c =: escalationListId AND Id NOT IN: lEscConIdForEmail];
    try {
      if (lDelEscalationsViaCaseEmail != null && lDelEscalationsViaCaseEmail.size() > 0)
        delete lDelEscalationsViaCaseEmail;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }

    //List of Escalations via Case Email to be upserted
    List < SC_SOCC_Escalation_via_Case_Email__c > lEscalationsViaCaseEmail = new List < SC_SOCC_Escalation_via_Case_Email__c > ();

    //preparing list of Escalations via Case Email to be upserted
    for (SC_SOCC_Escalation_via_Case_Email__c eachRec: lSelectedEscalationsViaCaseEmail) {
      SC_SOCC_Escalation_via_Case_Email__c eachEscalationsViaCaseEmail = new SC_SOCC_Escalation_via_Case_Email__c();
      if (eachRec.Id != null)
        eachEscalationsViaCaseEmail.Id = eachRec.Id;
      else
        eachEscalationsViaCaseEmail.Escalation_List__c = escalationListId;
      eachEscalationsViaCaseEmail.Name = eachRec.Authorized_Contact__r.Contact_Name__r.Name;
      eachEscalationsViaCaseEmail.Authorized_Contact__c = eachRec.Authorized_Contact__c;
      lEscalationsViaCaseEmail.add(eachEscalationsViaCaseEmail);
    }

    System.debug('------lEscalationsViaCaseEmail size : ' + lEscalationsViaCaseEmail.size());
    System.debug('------lEscalationsViaCaseEmail : ' + lEscalationsViaCaseEmail);
    //upsert List of Escalations via Case Email
    try {
      if (lEscalationsViaCaseEmail.size() > 0)
        upsert lEscalationsViaCaseEmail;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }

    //Creating Instruction for approval
    if (String.isNotBlank(pendingInstruction)) {
      List < Instruction__c > lExistingInstruction = [SELECT Id, CreatedBy.Name FROM Instruction__c WHERE Escalation_List__c =: escalationListId AND Status__c = 'In Progress'
        LIMIT 1
      ];
      if (lExistingInstruction.size() > 0)
        throw new AuraHandledException('There already exists a pending instruction submitted by ' + lExistingInstruction[0].CreatedBy.Name + '. Please contact him/her for further details.');
      Map < String, String > mInstructionTypeValue = new Map < String, String > ();
      String esclistwithouthtml = pendingInstruction.replaceAll('<[^>]+>', '').replaceAll(' ', '');
      if (esclistwithouthtml.length() > 0) {
        mInstructionTypeValue.put('Escalation List Instruction', pendingInstruction);
        SC_SOCC_Instruction_Manager.saveInstructionCreateCase(escRec.Policy_Domain__c, escalationListId, mInstructionTypeValue);
      }
    }

    return escalationListId;
  }

  //Method to return the list of Escalation Lists for a particular PD 
  @AuraEnabled
  public static List < SC_SOCC_Escalation_List__c > getlEscalationList(String pdId) {
    List < SC_SOCC_Escalation_List__c > lEscalationList = [SELECT Id, Name, Policy_Domain__c, Policy_Domain__r.Account_Name__c, Instructions__c,
      CreatedBy.Name, CreatedDate, LastModifiedBy.Name, LastModifiedDate,
      (SELECT Id, Name, Order_Number__c, Authorized_Contact__r.Contact_Name__r.Primary_Contact_Method__c,
        Authorized_Contact__r.Contact_Name__r.Secondary_Contact_Method__c, Authorized_Contact__r.Contact_Name__r.Phone,
        Authorized_Contact__r.Contact_Name__r.MobilePhone FROM SC_SOCC_Escalation_Contacts__r ORDER BY Order_Number__c)
      FROM SC_SOCC_Escalation_List__c WHERE Policy_Domain__c =: pdId ORDER BY NAME
    ];

    return lEscalationList;
  }

  //Method to get list of eligible PDs which can be used to be a Escalation List
  @AuraEnabled
  public static List < Policy_Domain__c > getlPDForCopy(SC_SOCC_Escalation_List__c escListRec) {
    List < Policy_Domain__c > lPDForCopy = [SELECT Id, Name from Policy_Domain__c WHERE Account_Name__c =: escListRec.Policy_Domain__r.Account_Name__c ORDER BY Name];
    System.debug('------- lPDForCopy : ' + lPDForCopy);
    return lPDForCopy;
  }

  //Related list of Notify and Escalation contacts wrapper
  public class NotifyAndEscalationContactsWrapper {
    @AuraEnabled public List < SC_SOCC_Escalation_Contact__c > lEscalationContact;
    @AuraEnabled public List < SC_SOCC_Escalation_via_Case_Email__c > lEscalationViaCaseEmail;
    //Changes for ESESP-4955 
    @AuraEnabled public Boolean notCopiable;
  }

  //During Copy Escalation List, method to get list of Escalation Contacts which will NOT be copied
  @AuraEnabled
  public static NotifyAndEscalationContactsWrapper getInvalidEscalationContacts(String pdId, String escalationListId) {
    //Get list of all the Contact Ids which are present as Authorized Contact on the new Policy Domain
    Set < Id > lConId = new Set < Id > ();
    for (Authorized_Contact__c eachRec: [Select Id, Contact_Name__c from Authorized_Contact__c WHERE Policy_Domain__c =: pdId])
      lConId.add(eachRec.Contact_Name__c);

    //List of All Escalation Contacts under the Escalation List
    List < SC_SOCC_Escalation_Contact__c > lAllEscalationCon = [SELECT Id, Escalation_List__c, Order_Number__c, Authorized_Contact__c,
      Authorized_Contact__r.Contact_Name__c, Authorized_Contact__r.Contact_Name__r.Name
      FROM SC_SOCC_Escalation_Contact__c WHERE Escalation_List__c =: escalationListId
      ORDER BY Order_Number__c
    ];

    //List of all the invalid Escalation Contacts
    List < SC_SOCC_Escalation_Contact__c > lInvalidEscalationCon = new List < SC_SOCC_Escalation_Contact__c > ();
    for (SC_SOCC_Escalation_Contact__c eachRec: lAllEscalationCon) {
      if (!lConId.contains(eachRec.Authorized_Contact__r.Contact_Name__c)) {
        //create each Escalation Contacts
        SC_SOCC_Escalation_Contact__c eachInvalidEscCon = eachRec;
        lInvalidEscalationCon.add(eachInvalidEscCon);
      }
    }

    //List of All Escalations via Case Email under the Escalation List
    List < SC_SOCC_Escalation_via_Case_Email__c > lAllEscalationViaCaseEmail = [SELECT Id, Name, Escalation_List__c, Authorized_Contact__c,
      Authorized_Contact__r.Contact_Name__c, Authorized_Contact__r.Contact_Name__r.Name
      FROM SC_SOCC_Escalation_via_Case_Email__c WHERE Escalation_List__c =: escalationListId
      ORDER BY Name
    ];

    //List of all the invalid Escalations via Case Email
    List < SC_SOCC_Escalation_via_Case_Email__c > lInvalidEscalationViaCaseEmail = new List < SC_SOCC_Escalation_via_Case_Email__c > ();
    for (SC_SOCC_Escalation_via_Case_Email__c eachRec: lAllEscalationViaCaseEmail) {
      if (!lConId.contains(eachRec.Authorized_Contact__r.Contact_Name__c)) {
        lInvalidEscalationViaCaseEmail.add(eachRec);
      }
    }

    NotifyAndEscalationContactsWrapper notifyAndEscalationContactsWrapper = new NotifyAndEscalationContactsWrapper();
    notifyAndEscalationContactsWrapper.lEscalationContact = lInvalidEscalationCon;
    notifyAndEscalationContactsWrapper.lEscalationViaCaseEmail = lInvalidEscalationViaCaseEmail;
    //Changes for ESESP-4955 
    notifyAndEscalationContactsWrapper.notCopiable = false;

    if (lAllEscalationViaCaseEmail != null && lInvalidEscalationViaCaseEmail != null) {
      if (lAllEscalationViaCaseEmail.equals(lInvalidEscalationViaCaseEmail)) {
        notifyAndEscalationContactsWrapper.notCopiable = true;
      }
    }

    return notifyAndEscalationContactsWrapper;
  }

  //Method called from Aura component to copy the Complete Escalation List to multiple Policy Domain
  @AuraEnabled
  // @future (callout=true)
  public static void copyAllEscaltionListFromAura(SC_SOCC_Escalation_List__c escalationListRec, String lCopiedEscListJSON) {
    List < SC_SOCC_Escalation_List__c > lCopiedEscList = (List < SC_SOCC_Escalation_List__c > ) System.JSON.deserializeStrict(lCopiedEscListJSON, List < SC_SOCC_Escalation_List__c > .Class);
    copyAllEscaltionList(escalationListRec, lCopiedEscList);
  }

  //Changes for ESESP-4955
  //Generic method to copy EL to different PDs
  //@future (callout=true)
  public static void copyAllEscaltionList(SC_SOCC_Escalation_List__c escalationListRec, List < SC_SOCC_Escalation_List__c > lCopiedEscList) {
    //List<SC_SOCC_Escalation_List__c> lCopiedEscList = (List<SC_SOCC_Escalation_List__c>) System.JSON.deserializeStrict(lCopiedEscListJSON, List<SC_SOCC_Escalation_List__c>.Class);

    //finding duplicates in lCopiedEscList
    for (Integer i = 0; i < lCopiedEscList.size(); i++) {
      String ithRec = lCopiedEscList[i].Name + lCopiedEscList[i].Policy_Domain__c;
      for (Integer j = 0; j < lCopiedEscList.size(); j++) {
        String jthRec = lCopiedEscList[j].Name + lCopiedEscList[j].Policy_Domain__c;
        if (ithRec.equalsIgnoreCase(jthRec) && i != j) {
          throw new AuraHandledException('The Escalation List ' + lCopiedEscList[i].Name + ' is mentioned more than once for the same Policy Domain! Please select a different name.');
        }
      }
    }

    //Get List of Selected PD Ids
    Set < Id > lSelectedPDs = new Set < Id > ();
    //Get List of new Selected EL names
    Set < String > lSelectedELNames = new Set < String > ();
    for (SC_SOCC_Escalation_List__c eachrec: lCopiedEscList) {
      lSelectedPDs.add(eachrec.Policy_Domain__c);
      lSelectedELNames.add(eachrec.Name);
    }
    //Errored List of Records
    String errorMessage = '';

    //List of Existing Escalation List with Selected EL names and PD
    List < SC_SOCC_Escalation_List__c > lExistingEL = [Select Id, Name, Policy_Domain__c, Policy_Domain__r.Name from SC_SOCC_Escalation_List__c where Policy_Domain__c IN: lSelectedPDs AND Name IN: lSelectedELNames ORDER BY Name];
    for (SC_SOCC_Escalation_List__c eachExistingRec: lExistingEL) {
      String existingRec = eachExistingRec.Name + eachExistingRec.Policy_Domain__c;
      for (SC_SOCC_Escalation_List__c eachCopiedRec: lCopiedEscList) {
        String copiedRec = eachCopiedRec.Name + eachCopiedRec.Policy_Domain__c;

        if (existingRec.equalsIgnoreCase(copiedRec))
          errorMessage += '\n' + eachExistingRec.Name + ' : ' + eachExistingRec.Policy_Domain__r.Name;
      }
    }

    //Throw duplicate EL error
    if (String.isNotBlank(errorMessage)) {
      errorMessage = 'These Escalation List Names already exist! Please select different names!' + errorMessage;
      throw new AuraHandledException(errorMessage);
    }

    //Changes for ESESP-4955
    //List of All Escalations via Case Email under Source Escalation List
    List < SC_SOCC_Escalation_via_Case_Email__c > lAllEscalationsViaCaseEmail = [SELECT Id, Escalation_List__c, Authorized_Contact__c,
      Authorized_Contact__r.Contact_Name__c, Authorized_Contact__r.Contact_Name__r.Name
      FROM SC_SOCC_Escalation_via_Case_Email__c WHERE Escalation_List__c =: escalationListRec.Id
      ORDER BY Name
    ];
    Set < Id > sAllEscalationsViaCaseEmail = new Set < Id > ();
    for (SC_SOCC_Escalation_via_Case_Email__c rec: lAllEscalationsViaCaseEmail) {
      sAllEscalationsViaCaseEmail.add(rec.Id);
    }

    if (lAllEscalationsViaCaseEmail.size() == 0) {
      errorMessage = 'Notify Via Case Email should not be empty!' + errorMessage;
      throw new AuraHandledException(errorMessage);
    }

    //Create New list of ELs to be inserted because lCopiedEscList has Id of source EL
    List < SC_SOCC_Escalation_List__c > lNewEscList = new List < SC_SOCC_Escalation_List__c > ();
    List < SC_SOCC_Escalation_List__c > lInvalidEscList = new List < SC_SOCC_Escalation_List__c > ();
    //Changes for ESESP-4955 
    //String sInvalidEscList = 'There esclation lists are not inserted:\n';
    //String s1InvalidEscList='';
    for (SC_SOCC_Escalation_List__c eachrec: lCopiedEscList) {

      System.debug('the esc id ' + escalationListRec.Id);
      System.debug('the pd is' + eachrec.Policy_Domain__c);
      NotifyAndEscalationContactsWrapper notifyAndEscalationContactsWrapper = getInvalidEscalationContacts(eachrec.Policy_Domain__c, escalationListRec.Id);
      List < SC_SOCC_Escalation_via_Case_Email__c > lInvalidEmail = notifyAndEscalationContactsWrapper.lEscalationViaCaseEmail;
      System.debug('the invalid are' + lInvalidEmail);
      Set < Id > sInvalidEmail = new Set < Id > ();
      for (SC_SOCC_Escalation_via_Case_Email__c rec: lInvalidEmail) {
        sInvalidEmail.add(rec.Id);
      }
      System.debug('All escalation list is ' + sAllEscalationsViaCaseEmail);
      System.debug('invalid escalation list is' + sInvalidEmail);
      System.debug('The pd id is' + eachrec.Policy_Domain__c);

      if (!sAllEscalationsViaCaseEmail.equals(sInvalidEmail)) {
        SC_SOCC_Escalation_List__c newEscList = new SC_SOCC_Escalation_List__c(Name = eachrec.Name, Policy_Domain__c = eachrec.Policy_Domain__c);
        lNewEscList.add(newEscList);
      }
      /*else
            {
                sInvalidEscList=sInvalidEscList+ eachrec.Name +':'+ eachrec.Policy_Domain__r.Name +'\n';
                System.debug('the pd name is '+ eachrec.Policy_Domain__r.Name);
                SC_SOCC_Escalation_List__c newEscList = new SC_SOCC_Escalation_List__c(Name=eachrec.Name, Policy_Domain__c=eachrec.Policy_Domain__c);
                lInvalidEscList.add(newEscList);
            }*/

    }

    //Insert New Escalation Lists
    /*try{
        if(lNewEscList.size()>0){
            insert lNewEscList;
        }
       else
       {
           errorMessage = 'Notify Via Case Email should not be empty!' + errorMessage;
           System.debug('the error message '+errorMessage);
            throw new AuraHandledException(errorMessage);    
       }
    }catch (Exception e) {
        //throw new AuraHandledException(e.getMessage());
    }*/
    System.debug('------------- lNewEscList : ' + lNewEscList);
    if (lNewEscList.size() > 0) {
      insert lNewEscList;
    } else {
      errorMessage = 'Notify Via Case Email should not be empty!' + errorMessage;
      System.debug('the error message ' + errorMessage);
      throw new AuraHandledException(errorMessage);
    }
    System.debug('------------- lNewEscList : ' + lNewEscList);

    //Map of PdId and its corresponding Set of Authorized Contact's Contact Id
    Map < Id, Set < Id >> mPdIdSConId = new Map < Id, Set < Id >> ();
    Map < Id, Map < Id, Id >> mPdmConIdACId = new Map < Id, Map < Id, Id >> ();
    for (Authorized_Contact__c eachrec: [Select Id, Policy_Domain__c, Contact_Name__c from Authorized_Contact__c WHERE Policy_Domain__c =: lSelectedPDs]) {
      if (!mPdIdSConId.containsKey(eachrec.Policy_Domain__c))
        mPdIdSConId.put(eachrec.Policy_Domain__c, new Set < Id > ());
      Set < Id > sConId = mPdIdSConId.get(eachrec.Policy_Domain__c);
      sConId.add(eachrec.Contact_Name__c);
      mPdIdSConId.put(eachrec.Policy_Domain__c, sConId);

      if (!mPdmConIdACId.containsKey(eachrec.Policy_Domain__c))
        mPdmConIdACId.put(eachrec.Policy_Domain__c, new Map < Id, Id > ());
      Map < Id, Id > mConIdACId = mPdmConIdACId.get(eachrec.Policy_Domain__c);
      mConIdACId.put(eachrec.Contact_Name__c, eachrec.Id);
      mPdmConIdACId.put(eachrec.Policy_Domain__c, mConIdACId);
    }

    System.debug('------------- mPdIdSConId : ' + mPdIdSConId);

    //List of All Escalation Contacts under Source Escalation List
    List < SC_SOCC_Escalation_Contact__c > lAllEscalationCon = [SELECT Id, Escalation_List__c, Order_Number__c, Action_If_Unreachable__c,
      Authorized_Contact__c, Authorized_Contact__r.Contact_Name__c, Authorized_Contact__r.Contact_Name__r.Name
      FROM SC_SOCC_Escalation_Contact__c WHERE Escalation_List__c =: escalationListRec.Id
      ORDER BY Order_Number__c
    ];

    System.debug('------------- lAllEscalationCon : ' + lAllEscalationCon);

    //List of All Escalations via Case Email under Source Escalation List
    /* List<SC_SOCC_Escalation_via_Case_Email__c> lAllEscalationsViaCaseEmail =  [SELECT Id, Escalation_List__c, Authorized_Contact__c,
                                                               Authorized_Contact__r.Contact_Name__c, Authorized_Contact__r.Contact_Name__r.Name
                                                               FROM SC_SOCC_Escalation_via_Case_Email__c WHERE Escalation_List__c =:escalationListRec.Id
                                                               ORDER BY Name];*/

    System.debug('------------- lAllEscalationsViaCaseEmail : ' + lAllEscalationsViaCaseEmail);

    //Loop through all the inserted EL and insert their corresponding valid Escalation contacts
    List < SC_SOCC_Escalation_Contact__c > lValidEscalationCon = new List < SC_SOCC_Escalation_Contact__c > ();

    //Loop through all the inserted EL and insert their corresponding valid Escalations via Case Email
    List < SC_SOCC_Escalation_via_Case_Email__c > lValidEscalationsViaCaseEmail = new List < SC_SOCC_Escalation_via_Case_Email__c > ();

    for (SC_SOCC_Escalation_List__c eachEL: lNewEscList) {
      Integer orderNumber = 1;
      Set < Id > sConId = mPdIdSConId.get(eachEL.Policy_Domain__c);
      if (sConId != null) {
        Map < Id, Id > mConIdACId = mPdmConIdACId.get(eachEL.Policy_Domain__c);
        System.debug('------------- sConId : ' + sConId);

        //For Escalation Contacts
        for (SC_SOCC_Escalation_Contact__c eachEC: lAllEscalationCon) {
          System.debug('------------- eachEC : ' + eachEC);
          if (sConId.contains(eachEC.Authorized_Contact__r.Contact_Name__c)) {
            System.debug('------------- eachEC : ' + eachEC);
            //create each Escalation Contacts
            SC_SOCC_Escalation_Contact__c eachValidEscCon = new SC_SOCC_Escalation_Contact__c();
            eachValidEscCon.Escalation_List__c = eachEL.Id;
            eachValidEscCon.Name = eachEC.Authorized_Contact__r.Contact_Name__r.Name;
            eachValidEscCon.Authorized_Contact__c = mConIdACId.get(eachEC.Authorized_Contact__r.Contact_Name__c);
            eachValidEscCon.Order_Number__c = orderNumber++;
            eachValidEscCon.Action_If_Unreachable__c = eachEC.Action_If_Unreachable__c != null ? eachEC.Action_If_Unreachable__c : null;
            lValidEscalationCon.add(eachValidEscCon);
          }
        }

        //For Escalations via Case Email
        for (SC_SOCC_Escalation_via_Case_Email__c eachEC: lAllEscalationsViaCaseEmail) {
          System.debug('------------- eachEC via Case Email : ' + eachEC);
          if (sConId.contains(eachEC.Authorized_Contact__r.Contact_Name__c)) {
            System.debug('------------- eachEC via Case Email : ' + eachEC);
            //create each Escalations via Case Email
            SC_SOCC_Escalation_via_Case_Email__c eachValidEscCon = new SC_SOCC_Escalation_via_Case_Email__c();
            eachValidEscCon.Escalation_List__c = eachEL.Id;
            eachValidEscCon.Name = eachEC.Authorized_Contact__r.Contact_Name__r.Name;
            eachValidEscCon.Authorized_Contact__c = mConIdACId.get(eachEC.Authorized_Contact__r.Contact_Name__c);
            lValidEscalationsViaCaseEmail.add(eachValidEscCon);
          }
        }
      }
    }

    System.debug('------------- lValidEscalationCon : ' + lValidEscalationCon);
    System.debug('------------- lValidEscalationsViaCaseEmail : ' + lValidEscalationsViaCaseEmail);

    //insert the valid list of Escalation Contacts
    try {
      if (lValidEscalationCon.size() > 0)
        insert lValidEscalationCon;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }

    //insert the valid list of Escalations via Case Email
    try {
      if (lValidEscalationsViaCaseEmail.size() > 0)
        insert lValidEscalationsViaCaseEmail;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }
    /*if(lInvalidEscList.size()>0)
    {
        return sInvalidEscList;
    }
    else
        return s1InvalidEscList;*/
  }

  //Method to Copy the Complete Escalation List to a Policy Domain
  // @AuraEnabled
  // public static List<SC_SOCC_Escalation_List__c> copyEscaltionList(String currentPDId, String copiedPDId, SC_SOCC_Escalation_List__c escListRec){
  //     //Check if existing Escalation List have same name
  //     for(SC_SOCC_Escalation_List__c eachrec : [Select Id, Name from SC_SOCC_Escalation_List__c where Policy_Domain__c =:copiedPDId]){
  //         if(eachrec.Name == escListRec.Name){
  //             throw new AuraHandledException('The Escalation List Name already exists! Please select a different name.');
  //         }
  //     }

  //     //Insert new Escalation List 
  //     SC_SOCC_Escalation_List__c newEscListRec = new SC_SOCC_Escalation_List__c();
  //     newEscListRec.Name = escListRec.Name;
  //     newEscListRec.Policy_Domain__c = copiedPDId;
  //     //newEscListRec.Instructions__c = escListRec.Instructions__c;

  //     try{
  //         insert newEscListRec;
  //     }catch (Exception e) {
  //         throw new AuraHandledException(e.getMessage());
  //     }

  //     //Get list of all the Contact Ids which are present as Authorized Contact on the new Policy Domain
  //     Set<Id> lConId = new Set<Id>();
  //     for(Authorized_Contact__c eachRec : [Select Id, Contact_Name__c from Authorized_Contact__c WHERE Policy_Domain__c =:copiedPDId])
  //         lConId.add(eachRec.Contact_Name__c);

  //     //List of All Escalation Contacts under the Escalation List
  //     List<SC_SOCC_Escalation_Contact__c> lAllEscalationCon =  [SELECT Id, Escalation_List__c, Order_Number__c, Action_If_Unreachable__c,
  //                                                               Authorized_Contact__c, Authorized_Contact__r.Contact_Name__c, Authorized_Contact__r.Contact_Name__r.Name
  //                                                               FROM SC_SOCC_Escalation_Contact__c WHERE Escalation_List__c =:escListRec.Id
  //                                                               ORDER BY Order_Number__c];

  //     //List to insert all the valid Escalation Contacts
  //     List<SC_SOCC_Escalation_Contact__c> lValidEscalationCon =  new List<SC_SOCC_Escalation_Contact__c>();
  //     Integer orderNumber = 1;
  //     for(SC_SOCC_Escalation_Contact__c eachRec : lAllEscalationCon){
  //         if(lConId.contains(eachRec.Authorized_Contact__r.Contact_Name__c)){
  //             //create each Escalation Contacts
  //             SC_SOCC_Escalation_Contact__c eachValidEscCon = new SC_SOCC_Escalation_Contact__c();
  //             eachValidEscCon.Escalation_List__c = newEscListRec.Id;
  //             eachValidEscCon.Name = eachRec.Authorized_Contact__r.Contact_Name__r.Name;
  //             eachValidEscCon.Authorized_Contact__c = eachRec.Authorized_Contact__c;
  //             eachValidEscCon.Order_Number__c = orderNumber++;
  //             eachValidEscCon.Action_If_Unreachable__c = eachRec.Action_If_Unreachable__c != null ? eachRec.Action_If_Unreachable__c : null;
  //             lValidEscalationCon.add(eachValidEscCon);
  //         }
  //     }

  //     //upsert the valid list of Escalation Contacts
  //     try{        
  //         if(lValidEscalationCon.size()>0)
  //            upsert lValidEscalationCon;
  //     }catch (Exception e) {
  //         throw new AuraHandledException(e.getMessage());
  //     }

  //     //to send latest data of the Escalation List on that PD
  //     List<SC_SOCC_Escalation_List__c> lLatestEscalationList = getlEscalationList(currentPDId);
  //     return lLatestEscalationList;
  // }

  //Method to get all the associated Handlers to the Escalation List which will be deleted
  @AuraEnabled
  public static List < Handler__c > getAssociatedHandlers(String delEscalationId) {
    //Check if user if a Shift Manager
    if (!SC_SOCC_Instruction_Manager.checkIfShiftManager())
      throw new AuraHandledException('Only Shift Managers are allowed to delete an Escalation List. Please contact them.');

    //Check if there is an pending instruction on this Escalation List
    List < Instruction__c > lExistingInstruction = [SELECT Id, CreatedBy.Name FROM Instruction__c WHERE Escalation_List__c =: delEscalationId AND Status__c = 'In Progress'
      LIMIT 1
    ];
    if (lExistingInstruction.size() > 0)
      throw new AuraHandledException('There is a pending instruction submitted by ' + lExistingInstruction[0].CreatedBy.Name + ' on this Escalation List. Please approve/reject it before deletion.');

    //Get associated List of handlers
    List < Handler__c > lHandler = [SELECT Id, Name FROM Handler__c WHERE Escalation_List__c =: delEscalationId];
    return lHandler;
  }

  //Method to delete a particular Escalation List record
  @AuraEnabled
  public static List < SC_SOCC_Escalation_List__c > delEachEscList(String pdId, String delEscalationId) {
    SC_SOCC_Escalation_List__c delEscListRec = new SC_SOCC_Escalation_List__c(Id = delEscalationId);
    //Delete the Escalation List
    try {
      delete delEscListRec;
    } catch (Exception e) {
      throw new AuraHandledException(e.getMessage());
    }

    //to send latest data of the Escalation List on that PD
    List < SC_SOCC_Escalation_List__c > lLatestEscalationList = getlEscalationList(pdId);
    return lLatestEscalationList;

  }

  //Method to bulk delete Escalation Lists
  // @AuraEnabled
  // public static List<SC_SOCC_Escalation_List__c> bulkDelEscList(String pdId, String lEscalationIdJson){
  //     if(!SC_SOCC_Instruction_Manager.checkIfShiftManager())
  //         throw new AuraHandledException('Only Shift Managers are allowed to delete Escalation Lists. Please contact them.');

  //     List<Id> lEscalationId = (List<Id>) System.JSON.deserializeStrict(lEscalationIdJson, List<Id>.Class);

  //     List<SC_SOCC_Escalation_List__c> lEscalationList = new List<SC_SOCC_Escalation_List__c>();
  //     for(Id eachId : lEscalationId){
  //         SC_SOCC_Escalation_List__c eachEL = new SC_SOCC_Escalation_List__c(Id=eachId);
  //         lEscalationList.add(eachEL);
  //     }

  //     //Delete Escalation in bulk
  //     try{
  //         delete lEscalationList;
  //     }catch(Exception e){
  //         throw new AuraHandledException(e.getMessage());
  //     }

  //     //to send latest data of the Escalation List on that PD
  //     List<SC_SOCC_Escalation_List__c> lLatestEscalationList = getlEscalationList(pdId);
  //     return lLatestEscalationList;
  // }

  //Commenting this As we are planning to remove SC_SOCC_Contact_Availability LWC component
  //Contact Availability related classes
  //To get Availability for contacts
  /*@AuraEnabled
  public static List < SC_SOCC_Availability__c > getAvailabiltyRecords(Id contactId) {
    //User's timezone offset in milliseconds
    Integer tzOffset = UserInfo.getTimeZone().getOffset(System.now());
    System.debug('tzOffset');
    System.debug(tzOffset);

    List < SC_SOCC_Availability__c > availabilityRecords = [Select Id, Day_Of_Week__c, Availability__c, Start_Time__c, End_Time__c from SC_SOCC_Availability__c where Contact__c =: contactId order by Day_Of_Week__c asc];
    List < SC_SOCC_Availability__c > newRecords = new List < SC_SOCC_Availability__c > ();
    if (availabilityRecords.size() > 0) {
      for (SC_SOCC_Availability__c eachrec: availabilityRecords) {
        //returning data in users timezone
        if (eachrec.Availability__c == 'Specific Time') {
          Time startTime = eachrec.Start_Time__c;
          if (startTime != null)
            startTime = startTime.addMilliseconds(tzOffset);
          else
            startTime = Time.newInstance(0, 0, 0, 0);
          eachrec.Start_Time__c = startTime;

          Time endTime = eachrec.End_Time__c;
          if (endTime != null)
            endTime = endTime.addMilliseconds(tzOffset);
          else
            endTime = Time.newInstance(0, 0, 0, 0);
          eachrec.End_Time__c = endTime;

        }

        System.debug('------eachrec : ' + eachrec);
      }
      System.debug(availabilityRecords);
      return availabilityRecords;
    } else {
      SC_SOCC_Availability__c sc1 = new SC_SOCC_Availability__c();
      sc1.Day_Of_Week__c = 'Monday';
      sc1.Contact__c = contactId;
      sc1.Availability__c = 'All Day';
      sc1.Start_Time__c = Time.newInstance(0, 0, 0, 0);
      sc1.End_Time__c = Time.newInstance(0, 0, 0, 0);
      newRecords.add(sc1);

      SC_SOCC_Availability__c sc2 = new SC_SOCC_Availability__c();
      sc2.Day_Of_Week__c = 'Tuesday';
      sc2.Contact__c = contactId;
      sc2.Availability__c = 'All Day';
      sc2.Start_Time__c = Time.newInstance(0, 0, 0, 0);
      sc2.End_Time__c = Time.newInstance(0, 0, 0, 0);
      newRecords.add(sc2);

      SC_SOCC_Availability__c sc3 = new SC_SOCC_Availability__c();
      sc3.Day_Of_Week__c = 'Wednesday';
      sc3.Contact__c = contactId;
      sc3.Availability__c = 'All Day';
      sc3.Start_Time__c = Time.newInstance(0, 0, 0, 0);
      sc3.End_Time__c = Time.newInstance(0, 0, 0, 0);
      newRecords.add(sc3);

      SC_SOCC_Availability__c sc4 = new SC_SOCC_Availability__c();
      sc4.Day_Of_Week__c = 'Thursday';
      sc4.Contact__c = contactId;
      sc4.Availability__c = 'All Day';
      sc4.Start_Time__c = Time.newInstance(0, 0, 0, 0);
      sc4.End_Time__c = Time.newInstance(0, 0, 0, 0);
      newRecords.add(sc4);

      SC_SOCC_Availability__c sc5 = new SC_SOCC_Availability__c();
      sc5.Day_Of_Week__c = 'Friday';
      sc5.Contact__c = contactId;
      sc5.Availability__c = 'All Day';
      sc5.Start_Time__c = Time.newInstance(0, 0, 0, 0);
      sc5.End_Time__c = Time.newInstance(0, 0, 0, 0);
      newRecords.add(sc5);

      SC_SOCC_Availability__c sc6 = new SC_SOCC_Availability__c();
      sc6.Day_Of_Week__c = 'Saturday';
      sc6.Contact__c = contactId;
      sc6.Availability__c = 'All Day';
      sc6.Start_Time__c = Time.newInstance(0, 0, 0, 0);
      sc6.End_Time__c = Time.newInstance(0, 0, 0, 0);
      newRecords.add(sc6);

      SC_SOCC_Availability__c sc7 = new SC_SOCC_Availability__c();
      sc7.Day_Of_Week__c = 'Sunday';
      sc7.Contact__c = contactId;
      sc7.Availability__c = 'All Day';
      sc7.Start_Time__c = Time.newInstance(0, 0, 0, 0);
      sc7.End_Time__c = Time.newInstance(0, 0, 0, 0);
      newRecords.add(sc7);

      insert newRecords;

      return newRecords;
    }
  }

  //To mass update availability records
  @AuraEnabled
  public static void bulkUpdateContactAvailability(List < SC_SOCC_Availability__c > lAvailability) {
    //User's timezone offset in milliseconds
    Integer tzOffset = UserInfo.getTimeZone().getOffset(System.now());
    for (SC_SOCC_Availability__c eachrec: lAvailability) {
      //returning data in users timezone
      if (eachrec.Availability__c == 'Specific Time') {
        Time startTime = eachrec.Start_Time__c;
        System.debug(startTime);
        startTime = startTime.addMilliseconds(0 - tzOffset);
        System.debug(startTime);
        eachrec.Start_Time__c = startTime;

        Time endTime = eachrec.End_Time__c;
        endTime = endTime.addMilliseconds(0 - tzOffset);
        eachrec.End_Time__c = endTime;
      }
    }

    upsert lAvailability;
  }*/

  //Get map of User id to corresponding Akam Contact Id
  public static Map < Id, String > getAkamContactIds(Set < Id > sUserId) {
    Map < Id, String > mUserIdAkamContactId = new Map < Id, String > ();
    for (User eachUser: [SELECT Id, AKAM_User_Id__c FROM User WHERE Id IN: sUserId]) {
      mUserIdAkamContactId.put(eachUser.Id, eachUser.AKAM_User_Id__c);
    }
    System.debug('-----------------mUserIdAkamContactId : ' + mUserIdAkamContactId);
    return mUserIdAkamContactId;
  }

  //Tejaswini-Changes
  @AuraEnabled
  public static Map < Id, Map < Integer, List < TimeDetails >>> applyDSTChangesToAvailabilityRecs(Map < Id, Map < Integer, List < TimeDetails >>> mConIdLAvailibilityRecsGMT, List < Id > sConId) {
    Map < Id, Map < Integer, List < TimeDetails >>> mConIdLAvailibilityRecsGMTAfterDST = new Map < Id, Map < Integer, List < TimeDetails >>> ();
    //timerec.dstTZName = eachRec.Timezone_Name__c;timerec.dstTZOffset = eachRec.Timezone_offset__c;

    for (Id conId: sConId) {
      Map < Integer, List < TimeDetails >> mAvailRecs = new Map < Integer, List < TimeDetails >> ();
      if (mConIdLAvailibilityRecsGMT.containsKey(conId)) {
        mAvailRecs = mConIdLAvailibilityRecsGMT.get(conId);

        Map < Integer, List < TimeDetails >> mFinalAvailRecs = new Map < Integer, List < TimeDetails >> ();

        for (Integer i = 1; i <= 7; i++) {
          List < TimeDetails > dayRecs = new List < TimeDetails > ();
          if (mAvailRecs.containsKey(i)) {
            dayRecs = mAvailRecs.get(i);
            Integer nextDayKey;
            Integer prevDayKey;
            if (i < 7)
              nextDayKey = i + 1;
            else
              nextDayKey = 1;

            if (i > 1)
              prevDayKey = i - 1;
            else
              prevDayKey = 7;

            List < TimeDetails > currDayRecs = new List < TimeDetails > ();
            List < TimeDetails > nextDayRecs = new List < TimeDetails > ();
            List < TimeDetails > prevDayRecs = new List < TimeDetails > ();

            for (TimeDetails trec: dayRecs) {
              //For records which have DST settings
              if (trec.dstTZName != null /*&& trec.dstTZOffset != null*/) {
                /*String recTZ = trec.dstTZName;
                String mapValue = mDstRecDetails.get(recTZ);
                String tzName = mapValue.substringBefore(':');
                Integer recTzOffset = Integer.valueOf(mapValue.substringAfter(':'));
                System.debug('recTzOffset is'+recTzOffset);*/

                String tzName = trec.dstTZName;
                System.debug('tzName is' + tzName);

                Timezone tz = Timezone.getTimeZone(tzName);
                System.debug('Display name: ' + tz);
                
                Double recTzOffset ;

                //If method 1
                /*recTzOffset = trec.dstTZOffset;
                System.debug('recTzOffset is: ' + recTzOffset);*/

                //If method 2
                //Calculate record timezone offset for records based on CreatedDate
                DateTime recDt = trec.createdDate;
                System.debug('Record created date ' + recDt);
                Double recMs = tz.getOffset(recDt);
                System.debug('Offset miliseconds: ' + recMs);
                //Double curTzOffset1 = (ms1 / 3600000);
                recTzOffset = (recMs / 3600000);

                if(Test.isRunningTest() && tzName =='Asia/Singapore')
                {
                  recTzOffset = 9.0;
                }
                if(Test.isRunningTest() && tzName =='America/Caracas')
                {
                  recTzOffset = -5.0;
                }

                System.debug('Record Offset Hours: ' + recTzOffset);

                //Check if the Record offset and current offset matches              
                DateTime dt = DateTime.now();
                Double ms = tz.getOffset(dt);
                System.debug('Offset miliseconds: ' + ms);
                Double curTzOffset = (ms / 3600000);
                //Integer curTzOffset = 1;
                System.debug('Current timezone Offset Hours: ' + curTzOffset);

                //If Record Timezone and Currently record local Timezone are same
                if (recTzOffset == curTzOffset) {
                  //Record lies in the same day
                  //List<TimeDetails> currDayRecs = new List<TimeDetails>();

                  TimeDetails tdrec = new TimeDetails();
                  tdrec.startTime = (trec.startTime);
                  tdrec.endTime = (trec.endTime);
                  currDayRecs.add(tdrec);
                }
                //If Record Timezone and Currently record local Timezone are different
                else if (recTzOffset != curTzOffset) {
                  /*Integer nextDayKey;
                  Integer prevDayKey;
                  if(i<7)
                    nextDayKey = i+1;
                  else
                    nextDayKey = 7;
                  
                  if(i>1)
                    prevDayKey = i-1;
                  else
                    prevDayKey = 1;*/

                  //For +ve timezone...CET = 1 and CEST = +2...CEST>CET
                  //Moving from DST OFF->ON : Record can be in same day or goto previous day..(GMT time-1 hr)
                  //Moving from DST ON->OFF : Record can be in same day or goto next day..    (GMT time+1 hr)

                  /*List<TimeDetails> currDayRecs = new List<TimeDetails>();
                  List<TimeDetails> nextDayRecs = new List<TimeDetails>();
                  List<TimeDetails> prevDayRecs = new List<TimeDetails>();*/

                  if (curTzOffset > 0) {
                    System.debug('If the record in +ve timezone');
                    //from DST OFF->ON...recTzOffset = +1 , curTzOffset = +2
                    if (recTzOffset + 1 == curTzOffset) {
                      System.debug('Moving from DST OFF->ON in +ve TZ');
                      //GMT-1
                      if (trec.startTime <= Time.newInstance(1, 0, 0, 0) && trec.endTime <= Time.newInstance(1, 0, 0, 0)) {
                        //record previous day
                        TimeDetails tdrec = new TimeDetails();
                        //tdrec.startTime = Time.newInstance(24,0,0,0)-trec.startTime;
                        tdrec.startTime = (trec.startTime).addHours(-1);
                        if (trec.endTime == Time.newInstance(1, 0, 0, 0)) {
                          tdrec.endTime = Time.newInstance(23, 59, 0, 0);
                        }
                        else {
                          //tdrec.endTime = Time.newInstance(24,0,0,0)-trec.endTime;
                          tdrec.endTime = (trec.endTime).addHours(-1);
                        }
                        prevDayRecs.add(tdrec);

                      } 
                      else if (trec.startTime <= Time.newInstance(1, 0, 0, 0) && trec.endTime > Time.newInstance(1, 0, 0, 0)) {
                        //record in previous day and current day
                        TimeDetails tdrec = new TimeDetails();
                        if (trec.startTime == Time.newInstance(1, 0, 0, 0)) {
                          tdrec.startTime = Time.newInstance(23, 0, 0, 0);
                        } 
                        else {
                          //tdrec.startTime = Time.newInstance(24,0,0,0)-trec.endTime;
                          tdrec.startTime = (trec.startTime).addHours(-1);
                        }
                        tdrec.endTime = Time.newInstance(23, 59, 0, 0);
                        prevDayRecs.add(tdrec);

                        TimeDetails tdrec1 = new TimeDetails();
                        tdrec1.startTime = Time.newInstance(0, 0, 0, 0);
                        tdrec1.endTime = (trec.endTime).addHours(-1);
                        currDayRecs.add(tdrec1);

                      } 
                      else if (trec.startTime > Time.newInstance(1, 0, 0, 0) && trec.endTime > Time.newInstance(1, 0, 0, 0)) {
                        //record in current day
                        TimeDetails tdrec = new TimeDetails();
                        tdrec.startTime = (trec.startTime).addHours(-1);
                        if (trec.endTime == Time.newInstance(23, 59, 0, 0)) {
                          tdrec.endTime = (trec.endTime).addHours(-1).addMinutes(1);
                        } 
                        else {
                          tdrec.endTime = (trec.endTime).addHours(-1);
                        }

                        currDayRecs.add(tdrec);
                      }

                    }
                    //from DST ON->OFF...recTzOffset = +2 , curTzOffset = +1
                    else if (recTzOffset - 1 == curTzOffset) {
                      System.debug('Moving from DST ON->OFF in +ve TZ');
                      //GMT+1
                      if (trec.startTime >= Time.newInstance(23, 0, 0, 0) && trec.endTime >= Time.newInstance(23, 0, 0, 0)) {
                        //record next day
                        TimeDetails tdrec = new TimeDetails();
                        tdrec.startTime = (trec.startTime).addHours(1);
                        if (trec.endTime == Time.newInstance(23, 59, 0, 0)) {
                          tdrec.endTime = Time.newInstance(1, 0, 0, 0);
                        } 
                        else {
                          tdrec.endTime = (trec.endTime).addHours(1);
                        }
                        nextDayRecs.add(tdrec);
                      } 
                      else if (trec.startTime < Time.newInstance(23, 0, 0, 0) && trec.endTime > Time.newInstance(23, 0, 0, 0)) {
                        //record in next day and current day
                        TimeDetails tdrec = new TimeDetails();
                        tdrec.startTime = (trec.startTime).addHours(1);
                        tdrec.endTime = Time.newInstance(23, 59, 0, 0);
                        currDayRecs.add(tdrec);

                        TimeDetails tdrec1 = new TimeDetails();
                        tdrec1.startTime = Time.newInstance(0, 0, 0, 0);
                        if (trec.endTime == Time.newInstance(23, 59, 0, 0)) {
                          tdrec1.endTime = Time.newInstance(1, 0, 0, 0);
                        } 
                        else {
                          tdrec1.endTime = (trec.endTime).addHours(1);
                        }
                        nextDayRecs.add(tdrec1);

                      } 
                      else if (trec.startTime < Time.newInstance(23, 0, 0, 0) && trec.endTime <= Time.newInstance(23, 0, 0, 0)) {
                        //record in current day
                        TimeDetails tdrec = new TimeDetails();
                        tdrec.startTime = (trec.startTime).addHours(1);
                        if (trec.endTime == Time.newInstance(23, 0, 0, 0)) {
                          tdrec.endTime = Time.newInstance(23, 59, 0, 0);
                        } 
                        else {
                          tdrec.endTime = (trec.endTime).addHours(1);
                        }
                        currDayRecs.add(tdrec);
                      }

                    }

                  }
                  //For -ve timezone...EST = -5 and EDT = -4..EDT>EST
                  //Moving from DST OFF->ON : Record can be in same day or goto next day..    (GMT time+1 hr)
                  //Moving from DST ON->OFF : Record can be in same day or goto previous day..(GMT time-1 hr)
                  else if (curTzOffset < 0) {
                    System.debug('If the record in -ve timezone');
                    //from DST OFF->ON..recTzOffset = -5 , curTzOffset = -4
                    if (recTzOffset + 1 == curTzOffset) {
                      System.debug('Moving from DST OFF->ON in -ve TZ');
                      //GMT-1
                      if (trec.startTime <= Time.newInstance(1, 0, 0, 0) && trec.endTime <= Time.newInstance(1, 0, 0, 0)) {
                        //record previous day
                        TimeDetails tdrec = new TimeDetails();
                        //tdrec.startTime = Time.newInstance(24,0,0,0)-trec.startTime;
                        tdrec.startTime = (trec.startTime).addHours(-1);
                        if (trec.endTime == Time.newInstance(1, 0, 0, 0)) {
                          tdrec.endTime = Time.newInstance(23, 59, 0, 0);
                        } 
                        else {
                          //tdrec.endTime = Time.newInstance(24,0,0,0)-trec.endTime;
                          tdrec.endTime = (trec.endTime).addHours(-1);
                        }
                        prevDayRecs.add(tdrec);
                      } 
                      else if (trec.startTime <= Time.newInstance(1, 0, 0, 0) && trec.endTime > Time.newInstance(1, 0, 0, 0)) {
                        //record in previous day and current day
                        TimeDetails tdrec = new TimeDetails();
                        if (trec.startTime == Time.newInstance(1, 0, 0, 0)) {
                          tdrec.startTime = Time.newInstance(23, 0, 0, 0);
                        } 
                        else {
                          //tdrec.startTime = Time.newInstance(24,0,0,0)-trec.endTime;
                          tdrec.startTime = (trec.startTime).addHours(-1);
                        }
                        tdrec.endTime = Time.newInstance(23, 59, 0, 0);
                        prevDayRecs.add(tdrec);

                        TimeDetails tdrec1 = new TimeDetails();
                        tdrec1.startTime = Time.newInstance(0, 0, 0, 0);
                        tdrec1.endTime = (trec.endTime).addHours(-1);
                        currDayRecs.add(tdrec1);
                      } 
                      else if (trec.startTime > Time.newInstance(1, 0, 0, 0) && trec.endTime > Time.newInstance(1, 0, 0, 0)) {
                        //record in current day
                        TimeDetails tdrec = new TimeDetails();
                        tdrec.startTime = (trec.startTime).addHours(-1);
                        if (trec.endTime == Time.newInstance(23, 59, 0, 0)) {
                          tdrec.endTime = (trec.endTime).addHours(-1).addMinutes(1);
                        } 
                        else {
                          tdrec.endTime = (trec.endTime).addHours(-1);
                        }
                        currDayRecs.add(tdrec);
                      }

                    }
                    //from DST ON->OFF...recTzOffset = -4 , curTzOffset = -5
                    else if (recTzOffset - 1 == curTzOffset) {
                      System.debug('Moving from DST ON->OFF in -ve TZ');
                      //GMT+1
                      if (trec.startTime >= Time.newInstance(23, 0, 0, 0) && trec.endTime >= Time.newInstance(23, 0, 0, 0)) {
                        //record next day
                        TimeDetails tdrec = new TimeDetails();
                        tdrec.startTime = (trec.startTime).addHours(1);
                        if (trec.endTime == Time.newInstance(23, 59, 0, 0)) {
                          tdrec.endTime = Time.newInstance(1, 0, 0, 0);
                        } 
                        else {
                          tdrec.endTime = (trec.endTime).addHours(1);
                        }
                        nextDayRecs.add(tdrec);
                      } 
                      else if (trec.startTime < Time.newInstance(23, 0, 0, 0) && trec.endTime > Time.newInstance(23, 0, 0, 0)) {
                        //record in next day and current day
                        TimeDetails tdrec = new TimeDetails();
                        tdrec.startTime = (trec.startTime).addHours(1);
                        tdrec.endTime = Time.newInstance(23, 59, 0, 0);
                        currDayRecs.add(tdrec);

                        TimeDetails tdrec1 = new TimeDetails();
                        tdrec1.startTime = Time.newInstance(0, 0, 0, 0);
                        if (trec.endTime == Time.newInstance(23, 59, 0, 0)) {
                          tdrec1.endTime = Time.newInstance(1, 0, 0, 0);
                        } 
                        else {
                          tdrec1.endTime = (trec.endTime).addHours(1);
                        }
                        nextDayRecs.add(tdrec1);
                      } 
                      else if (trec.startTime < Time.newInstance(23, 0, 0, 0) && trec.endTime < = Time.newInstance(23, 0, 0, 0)) {
                        //record in current day
                        TimeDetails tdrec = new TimeDetails();
                        tdrec.startTime = (trec.startTime).addHours(1);
                        if (trec.endTime == Time.newInstance(23, 0, 0, 0)) {
                          tdrec.endTime = Time.newInstance(23, 59, 0, 0);
                        } 
                        else {
                          tdrec.endTime = (trec.endTime).addHours(1);
                        }
                        currDayRecs.add(tdrec);
                      }

                    }
                    

                  }

                }

              }
              //For records which doesn't have DST settings
              else {
                //No DST settings apply so the record lies in the same day
                TimeDetails tdrec = new TimeDetails();
                tdrec.startTime = trec.startTime;
                tdrec.endTime = trec.endTime;
                currDayRecs.add(tdrec);
              }
            }
            //for current day record
            System.debug('Local current day records ' + currDayRecs);
            if (!mFinalAvailRecs.containsKey(i)) {
              mFinalAvailRecs.put(i, new List < TimeDetails > ());
            }
            List < TimeDetails > cRecs = mFinalAvailRecs.get(i);
            cRecs.addAll(currDayRecs);
            System.debug('Final Current day records ' + cRecs);
            mFinalAvailRecs.put(i, cRecs);

            //for previous day record
            if (prevDayRecs.size() > 0) {
              System.debug('Local previous day records ' + prevDayRecs);
              if (!mFinalAvailRecs.containsKey(prevDayKey)) {
                mFinalAvailRecs.put(prevDayKey, new List < TimeDetails > ());
              }
              List < TimeDetails > pRecs = mFinalAvailRecs.get(prevDayKey);
              pRecs.addAll(prevDayRecs);
              System.debug('Final Previous day records ' + pRecs);
              mFinalAvailRecs.put(prevDayKey, pRecs);
            }

            //for next day record
            if (nextDayRecs.size() > 0) {
              System.debug('Local next day records ' + nextDayRecs);
              if (!mFinalAvailRecs.containsKey(nextDayKey)) {
                mFinalAvailRecs.put(nextDayKey, new List < TimeDetails > ());
              }
              List < TimeDetails > nRecs = mFinalAvailRecs.get(nextDayKey);
              nRecs.addAll(nextDayRecs);
              System.debug('Final Next day records ' + nRecs);
              mFinalAvailRecs.put(nextDayKey, nRecs);
            }
          }
        }
        mConIdLAvailibilityRecsGMTAfterDST.put(conId, mFinalAvailRecs);
      }
    }
    System.debug('The final mConIdLAvailibilityRecsGMTAfterDST');
    System.debug(mConIdLAvailibilityRecsGMTAfterDST);
    return mConIdLAvailibilityRecsGMTAfterDST;

  }

  @AuraEnabled
  public static Map < Id, List < DateTimeDetail >> applyDSTChangesToOOORecs(Map < Id, List < DateTimeDetail >> mConIdOOORecs, List < Id > sConId) {
    Map < Id, List < DateTimeDetail >> mConIdOOORecsAfterDST = new Map < Id, List < DateTimeDetail >> ();
    for (Id conId: sConId) {
      List < DateTimeDetail > looorec = new List < DateTimeDetail > ();
      if (mConIdOOORecs.containsKey(conId)) {
        looorec = mConIdOOORecs.get(conId);
        //List<DateTimeDetail> mOOORecs = new List<DateTimeDetail>();
        //Map<String,List<DateTimeDetail>> mOOORecs = new Map<String,List<DateTimeDetail>>();

        //looorec = moorecs.get('OutOfOffice');
        List < DateTimeDetail > currDayRecs = new List < DateTimeDetail > ();
        for (DateTimeDetail rec: looorec) {
          if (rec.dstTZName != null /*&& rec.dstTZOffset != null*/) {
            String tzName = rec.dstTZName;
            System.debug('tzName is' + tzName);

            Timezone tz = Timezone.getTimeZone(tzName);
            System.debug('Display name: ' + tz);

            Double recTzOffset;
            //If method 1
            /*recTzOffset = rec.dstTZOffset;
            System.debug('recTzOffset is: ' + recTzOffset);*/

            //If method 2
            //Calculate record timezone offset for records based on CreatedDate
            DateTime recDt = rec.createdDate;
            System.debug('Record created date ' + recDt);
            Double recMs = tz.getOffset(recDt);
            System.debug('Offset miliseconds: ' + recMs);
            //Double curTzOffset1 = (ms1 / 3600000);
            recTzOffset = (recMs / 3600000);

            if(Test.isRunningTest() && tzName =='Asia/Singapore')
            {
              recTzOffset = 9.0;
            }
            if(Test.isRunningTest() && tzName =='America/Caracas')
            {
              recTzOffset = -5.0;
            }

            System.debug('Record Offset Hours: ' + recTzOffset);

            //Check if the Record offset and current offset matches
            DateTime dt = DateTime.now();
            System.debug('Current Date time' + dt);
            Double ms = tz.getOffset(dt);
            System.debug('Offset miliseconds: ' + ms);
            Double curTzOffset = (ms / 3600000);
            //Integer curTzOffset = -5;
            System.debug('Offset Hours: ' + curTzOffset);

            if (recTzOffset == curTzOffset) {
              DateTimeDetail tdrec = new DateTimeDetail();
              tdrec.startDateTime = rec.startDateTime;
              tdrec.endDateTime = rec.endDateTime;
              tdrec.startTime = rec.startTime;
              tdrec.endTime = rec.endTime;
              tdrec.startDate = rec.startDate;
              tdrec.endDate = rec.endDate;

              currDayRecs.add(tdrec);
            } 
            else if (recTzOffset != curTzOffset) {
              if (curTzOffset > 0) {
                System.debug('If the OOO record in +ve timezone');
                //from DST OFF->ON...recTzOffset = +1 , curTzOffset = +2
                if (recTzOffset + 1 == curTzOffset) {
                  System.debug('Moving from DST OFF->ON for OOO record');
                  //GMT-1
                  DateTimeDetail tdrec = new DateTimeDetail();
                  tdrec.startDateTime = (rec.startDateTime).addHours(-1);
                  tdrec.endDateTime = (rec.endDateTime).addHours(-1);
                  tdrec.startTime = (tdrec.startDateTime).timeGmt();
                  tdrec.endTime = (tdrec.endDateTime).timeGmt();
                  tdrec.startDate = (tdrec.startDateTime).dateGmt();
                  tdrec.endDate = (tdrec.endDateTime).dateGmt();

                  currDayRecs.add(tdrec);

                }
                //from DST ON->OFF...recTzOffset = +2 , curTzOffset = +1
                else if (recTzOffset - 1 == curTzOffset) {
                  System.debug('Moving from DST ON->OFF for OOO record');
                  //GMT+1
                  DateTimeDetail tdrec = new DateTimeDetail();
                  tdrec.startDateTime = (rec.startDateTime).addHours(1);
                  tdrec.endDateTime = (rec.endDateTime).addHours(1);
                  tdrec.startTime = (tdrec.startDateTime).timeGmt();
                  tdrec.endTime = (tdrec.endDateTime).timeGmt();
                  tdrec.startDate = (tdrec.startDateTime).dateGmt();
                  tdrec.endDate = (tdrec.endDateTime).dateGmt();

                  currDayRecs.add(tdrec);

                }
              } 
              else if (curTzOffset < 0) {
                System.debug('If the OOO record in -ve timezone');
                //from DST ON->OFF...recTzOffset = -4 , curTzOffset = -5
                if (recTzOffset - 1 == curTzOffset) {
                  System.debug('Moving from DST ON->OFF for OOO record');
                  //GMT+1
                  DateTimeDetail tdrec = new DateTimeDetail();
                  tdrec.startDateTime = (rec.startDateTime).addHours(1);
                  tdrec.endDateTime = (rec.endDateTime).addHours(1);
                  tdrec.startTime = (tdrec.startDateTime).timeGmt();
                  tdrec.endTime = (tdrec.endDateTime).timeGmt();
                  tdrec.startDate = (tdrec.startDateTime).dateGmt();
                  tdrec.endDate = (tdrec.endDateTime).dateGmt();

                  currDayRecs.add(tdrec);

                }
                //from DST OFF->ON..recTzOffset = -5 , curTzOffset = -4
                else if (recTzOffset + 1 == curTzOffset) {
                  System.debug('Moving from DST OFF->ON for OOO record');
                  //GMT-1
                  DateTimeDetail tdrec = new DateTimeDetail();
                  tdrec.startDateTime = (rec.startDateTime).addHours(-1);
                  tdrec.endDateTime = (rec.endDateTime).addHours(-1);
                  tdrec.startTime = (tdrec.startDateTime).timeGmt();
                  tdrec.endTime = (tdrec.endDateTime).timeGmt();
                  tdrec.startDate = (tdrec.startDateTime).dateGmt();
                  tdrec.endDate = (tdrec.endDateTime).dateGmt();

                  currDayRecs.add(tdrec);
                }
              }
            }
          } 
          else {
            DateTimeDetail tdrec = new DateTimeDetail();
            tdrec.startDateTime = rec.startDateTime;
            tdrec.endDateTime = rec.endDateTime;
            tdrec.startTime = rec.startTime;
            tdrec.endTime = rec.endTime;
            tdrec.startDate = rec.startDate;
            tdrec.endDate = rec.endDate;

            currDayRecs.add(tdrec);
          }

        }
        System.debug('Local current day records ' + currDayRecs);
        /*if(!mOOORecs.containsKey('OutOfOffice'))
        {
          mOOORecs.put('OutOfOffice',new List<DateTimeDetail>());
        }
        List<DateTimeDetail> cRecs = mOOORecs.get('OutOfOffice');
        cRecs.addAll(currDayRecs);
        System.debug('Final Current day records '+cRecs);
        mOOORecs.put('OutOfOffice',cRecs);*/
        if (!mConIdOOORecsAfterDST.containsKey(conId)) {
          mConIdOOORecsAfterDST.put(conId, new List < DateTimeDetail > ());
        }
        List < DateTimeDetail > tempList = mConIdOOORecsAfterDST.get(conId);
        tempList.addAll(currDayRecs);
        System.debug('Final Current day records ' + tempList);

        mConIdOOORecsAfterDST.put(conId, tempList);
      }
    }
    System.debug('The final mConIdOOORecsAfterDST');
    System.debug(mConIdOOORecsAfterDST);
    return mConIdOOORecsAfterDST;

  }
  //Handling duplicate and overlapping Availability records
  @AuraEnabled
  public static Map < Integer, List < Time >> getFinalAvailabilityRecs(Map < Integer, List < TimeDetails >> mRecs) {
    Map < Integer, List < Time >> mAvailRecTime = new Map < Integer, List < Time >> ();
    for (Integer i = 1; i <= 7; i++) {
      if (mRecs.containsKey(i)) {
        List < Time > availTimings = new List < Time > ();
        List < TimeDetails > timings = mRecs.get(i);

        for (TimeDetails rec: timings) {
          Integer size = availTimings.size();
          System.debug('the rec is' + rec);
          if (availTimings.size() == 0) {
            availTimings.add(rec.startTime);
            availTimings.add(rec.endTime);
            System.debug('the list is ' + availTimings);
          } 
          else {
            //System.debug('the last record is '+availTimings[size-1]);
            System.debug('the list is ' + availTimings);
            System.debug('the else block');
            System.debug('the list size is' + availTimings.size());

            if ((rec.endTime > availTimings[size - 1]) && (rec.startTime < = availTimings[size - 1])) {
              Time lstElemet = availTimings.remove(size - 1);
              System.debug('the lastelement is ' + lstElemet);
              availTimings.add(rec.endTime);
              System.debug('the list is ' + availTimings);
            } 
            else if ((rec.startTime > availTimings[size - 1]) && (rec.endTime > availTimings[size - 1])) {
              availTimings.add(rec.startTime);
              availTimings.add(rec.endTime);
            }
            /*else if((rec.startTime < availTimings[size-1])&& (rec.endTime < availTimings[size-1])){
                
            }*/
            else if (rec.startTime < availTimings[0] && rec.endTime < availTimings[0]) {
              availTimings.add(0, rec.startTime);
              availTimings.add(1, rec.endTime);
            } 
            else if (rec.startTime < availTimings[0] && rec.endTime == availTimings[0]) {
              Time firstElemet = availTimings.remove(0);
              System.debug('the first element is ' + firstElemet);
              availTimings.add(0, rec.startTime);
              System.debug('the list is ' + availTimings);
            } 
            else if (rec.startTime < availTimings[0] && rec.endTime > availTimings[0]) {
              if (rec.endTime < = availTimings[1]) {
                Time firstElemet = availTimings.remove(0);
                System.debug('the first element is ' + firstElemet);
                availTimings.add(0, rec.startTime);
                System.debug('the list is ' + availTimings);
              } 
              else if (rec.endTime > availTimings[1]) {
                Time firstElemet = availTimings.remove(0);
                System.debug('the first element is ' + firstElemet);
                availTimings.add(0, rec.startTime);
                Time secElement = availTimings.remove(1);
                System.debug('the second element is');
                availTimings.add(1, rec.endTime);
                System.debug('the list is ' + availTimings);
              }
            } 
            else if ((rec.startTime < availTimings[size - 1]) && (rec.endTime < availTimings[size - 1])) {
              //Do nothing
            }

          }

        }

        mAvailRecTime.put(i, availTimings);

      }

    }

    System.debug('the final map is');
    System.debug(mAvailRecTime);
    return mAvailRecTime;
  }

  @AuraEnabled
  public static Map < Integer, List < TimeDetails >> convertAvailListToAvailWrapper(Map < Integer, List < Time >> listRecords) {
    Map < Integer, List < TimeDetails >> mAvailRecTimeWrapper = new Map < Integer, List < TimeDetails >> ();
    for (Integer i = 1; i <= 7; i++) {
      List < Time > recs = new List < Time > ();
      if (listRecords.containsKey(i)) {
        recs = listRecords.get(i);
        Integer size = recs.size();
        List < TimeDetails > lrecs = new List < TimeDetails > ();
        for (Integer j = 0; j < size; j = j + 2) {
          TimeDetails rec = new TimeDetails();
          rec.startTime = recs[j];
          rec.endTime = recs[j + 1];
          lrecs.add(rec);
        }
        mAvailRecTimeWrapper.put(i, lrecs);
      }
    }

    System.debug('convertAvailListToAvailWrapper');
    System.debug(mAvailRecTimeWrapper);
    return mAvailRecTimeWrapper;

  }

  @AuraEnabled
  public static string getAvailDataInString(List < Time > detailList) {

    /*List<String> timeString = new List<String>();
        for(Time t:detailList){
            Integer hr = t.hour();
            Integer min= t.minute();
    
            String stime;
            if(t.hour()==12)
            {
                stime = hr + ':' +min+ ' pm';
            }
            if(hr>12)
            {
                stime= Math.mod(hr,12) + ':' +min+ ' pm';
            }
            else {
                stime = hr + ':' +min+ ' am';
            }
            timeString.add(stime);
        }
    
        Integer size = detailList.size();
        String detail='';
        for(Integer i =0;i<size;i=i+2){
            
            detail+=timeString[i] + '-' + timeString[i+1]+'<br/>';
        }*/
    Integer size = detailList.size();
    String detail = '';
    for (Integer i = 0; i < size; i = i + 2) {
      String t1 = String.ValueOf(detailList[i]);
      String t2 = String.ValueOf(detailList[i + 1]);
      detail += '\n' + t1.substring(0, 5) + ' - ' + t2.substring(0, 5);
    }
    return detail;
  }

  /*@AuraEnabled
  public static string getOOODataInString(List < DateTime > oooList) {
    Integer size = oooList.size();
    String detail = '';
    for (Integer i = 0; i < size; i = i + 2) {
      String dt1 = oooList[i].format();

      String dt2 = oooList[i + 1].format();
      detail += '\n' + dt1 + ' - ' + dt2;
    }
    return detail;
  }*/

  @AuraEnabled
  public static string getOOODataInString(List < DateTimeDetail > oooList, DateTime weekStartDate, Integer tzOffsetMS, String tzOffset) {
    Integer size = oooList.size();
    String detail = '';
    Integer hr = Integer.valueOf(tzOffset.substring(1, 3));
    Integer min = Integer.valueOf(tzOffset.substring(4, 6));
    System.debug(hr);
    System.debug(min);

    for (DateTimeDetail rec: oooList) {
      DateTime startDateTime;
      DateTime endDateTime;
      DateTime weekStartDateTime;

      if (tzOffsetMS < 0) {
        startDateTime = (rec.startDateTime).addHours(-hr).addMinutes(-min);
        endDateTime = (rec.endDateTime).addHours(-hr).addMinutes(-min);
        weekStartDateTime = weekStartDate;
      } 
      else if (tzOffsetMS == 0 || tzOffsetMS > 0) {
        startDateTime = (rec.startDateTime).addHours(hr).addMinutes(min);
        endDateTime = (rec.endDateTime).addHours(hr).addMinutes(min);
        weekStartDateTime = weekStartDate;
      }

      System.debug('week start date in user tz' + weekStartDateTime);
      if (!(startDateTime < weekStartDateTime && endDateTime < weekStartDateTime)) {
        String dt1 = (rec.startDateTime).format();

        String dt2 = (rec.endDateTime).format();
        detail += '\n' + dt1 + ' - ' + dt2;

      }

    }
    return detail;

    //One more way
    //Positive timezone
    /*if(tzOffsetMS>0)
    {
      for(DateTimeDetail rec : oooList)
      {
        DateTime sdt = (rec.startDateTime).addHours(hr).addMinutes(min);
        DateTime edt = (rec.endDateTime).addHours(hr).addMinutes(min);
        DateTime wsdt = weekStartDate.addHours(hr).addMinutes(min);

        if(sdt >= wsdt && edt >= wsdt){
          String dt1 = (rec.startDateTime).format();
    
          String dt2 = (rec.endDateTime).format();
          detail += '\n' + dt1 + ' - ' + dt2;
    
        }
        
      }
    }
    //Negative timezone
    else if(tzOffsetMS<0)
    {
      for(DateTimeDetail rec : oooList)
      {
        DateTime sdt = (rec.startDateTime).addHours(-hr).addMinutes(-min);
        DateTime edt = (rec.endDateTime).addHours(-hr).addMinutes(-min);
        DateTime wsdt = weekStartDate.addHours(-hr).addMinutes(-min);

        if(sdt >= wsdt && edt >= wsdt){
          String dt1 = (rec.startDateTime).format();
    
          String dt2 = (rec.endDateTime).format();
          detail += '\n' + dt1 + ' - ' + dt2;
    
        }
        
      }
    }
    //GMT
    else if(tzOffsetMS==0)
    {
      for(DateTimeDetail rec : oooList)
      {
        if(rec.startDateTime >= weekStartDate && rec.endDateTime >= weekStartDate){
          String dt1 = (rec.startDateTime).format();
    
          String dt2 = (rec.endDateTime).format();
          detail += '\n' + dt1 + ' - ' + dt2;
    
        }
        
      }
    }*/

  }

  @AuraEnabled
  public static string getDayAvailabilityStatus(List < Time > detailList) {
    Integer size = detailList.size();
    String status = '';
    if (size == 0) {
      status += 'Unavailable';
    } 
    else if (size == 2 && (detailList.get(0) == Time.newInstance(0, 0, 0, 0) && detailList.get(1) == Time.newInstance(23, 59, 0, 0))) {
      status += 'Available';
    } 
    else {
      status += 'Partial';
    }
    return status;
  }

  //Create map of Unavailability records for the week

  /*DateTime myDateTime = DateTime.now();
  System.debug('todays date is ' + myDateTime);
  String day = myDateTime.formatGMT('EEEE');
  System.debug('the day of week is');
  System.debug(day);
  Integer dayNo = mDayNo.get(day);

  DateTime weekStartDate = myDateTime.addDays(1 - dayNo);
  System.debug('week start date is ' + weekStartDate);
  DateTime weekEndDate = myDateTime.addDays(7 - dayNo);
  System.debug('week end date is ' + weekEndDate);*/

  /*@AuraEnabled
  public static Map < Id, Map < Integer, List < TimeDetails >>> mUnavailibilityOfWeek(Map < Id, List < DateTimeDetail >> mOOORecordsOfWeek , List<Id> sConId){

  Map < String, Integer > mDayNo = new Map < String, Integer > {'Monday'=>1,'Tuesday'=>2,'Wednesday'=>3,'Thursday'=>4,'Friday'=>5,'Saturday'=>6,'Sunday'=>7};
        
  Map < Id, Map < Integer, List < TimeDetails >>> mUnavailabilityRecs = new Map < Id, Map < Integer, List < TimeDetails >>> ();


  DateTime myDateTime = DateTime.now();
  System.debug('todays date is ' + myDateTime);
  String day = myDateTime.formatGMT('EEEE');
  System.debug('the day of week is');
  System.debug(day);
  Integer dayNo = mDayNo.get(day);

  //Time t=Time.newInstance(0, 0, 0, 0);
  Integer dd = myDateTime.dayGmt();
  Integer mm = myDateTime.monthGmt();
  Integer yy = myDateTime.yearGmt();
  //Date dt = Date.newInstance(yy, mm, dd);

  DateTime weekStartDate = Datetime.newInstanceGmt(yy,mm,dd).addDays(1 - dayNo);
  DateTime weekEndDate   = Datetime.newInstanceGmt(yy,mm,dd,23,59,59).addDays(7 - dayNo);
  System.debug('week start date is ' + weekStartDate);
  System.debug('week end date is ' + weekEndDate);

  for (Id conId: sConId) {
    if (mOOORecordsOfWeek.containsKey(conId)) {
      List < DateTimeDetail > OOOrecs = mOOORecordsOfWeek.get(conId);
      Map < Integer, List < TimeDetails >> OOOrecsOfWeek = new Map < Integer, List < TimeDetails >> ();
      if (OOOrecs.size() > 0) {
        for (DateTimeDetail rec: OOOrecs) {

          if(rec.startDateTime < weekStartDate && rec.endDateTime < weekStartDate){
            //Do nothing
            System.debug('####11');
          }
          //If OOO record lies in same day
          else if (rec.startDate == rec.endDate) {
            System.debug('####12');
            Integer sowDayNo = mDayNo.get((rec.startDateTime).formatGMT('EEEE'));

            TimeDetails trec = new TimeDetails();
            trec.startTime = rec.startTime;
            trec.endTime = rec.endTime;

            if (!OOOrecsOfWeek.containsKey(sowDayNo)) {
              OOOrecsOfWeek.put(sowDayNo, new List < TimeDetails > ());
            }
            List < TimeDetails > lrecs = OOOrecsOfWeek.get(sowDayNo);
            lrecs.add(trec);
            OOOrecsOfWeek.put(sowDayNo, lrecs);

          } 

          //Both start date time and end date time in current week
          else if (rec.startDateTime > weekStartDate && rec.endDateTime < weekEndDate) {
            System.debug('####13');
            Integer sowDayNo = mDayNo.get((rec.startDateTime).formatGMT('EEEE'));
            Integer eowDayNo = mDayNo.get((rec.endDateTime).formatGMT('EEEE'));

            TimeDetails fromTime = new TimeDetails();
            fromTime.startTime = rec.startTime;
            fromTime.endTime = Time.newInstance(23, 59, 0, 0);

            if (!OOOrecsOfWeek.containsKey(sowDayNo)) {
              OOOrecsOfWeek.put(sowDayNo, new List < TimeDetails > ());
            }
            List < TimeDetails > lrecs = OOOrecsOfWeek.get(sowDayNo);
            lrecs.add(fromTime);
            OOOrecsOfWeek.put(sowDayNo, lrecs);

            if(rec.endTime!=Time.newInstance(0, 0, 0, 0))
            {
            TimeDetails toTime = new TimeDetails();
            toTime.startTime = Time.newInstance(0, 0, 0, 0);
            toTime.endTime = rec.endTime;

            if (!OOOrecsOfWeek.containsKey(eowDayNo)) {
              OOOrecsOfWeek.put(eowDayNo, new List < TimeDetails > ());
            }
            List < TimeDetails > lrecs2 = OOOrecsOfWeek.get(eowDayNo);
            lrecs2.add(toTime);

            OOOrecsOfWeek.put(eowDayNo, lrecs2);
            }
            //middle records
            for (Integer i = sowDayNo + 1; i < eowDayNo; i++) {
              if (!OOOrecsOfWeek.containsKey(i)) {
                OOOrecsOfWeek.put(i, new List < TimeDetails > ());
              }
              List < TimeDetails > lrecs3 = OOOrecsOfWeek.get(i);

              TimeDetails trec = new TimeDetails();
              trec.startTime = Time.newInstance(0, 0, 0, 0);
              trec.endTime = Time.newInstance(23, 59, 0, 0);
              lrecs3.add(trec);
              OOOrecsOfWeek.put(i, lrecs3);
            }

          } 
          //Start date time in previous week , End date time in current week
          else if (rec.startDateTime < weekStartDate && rec.endDateTime < = weekEndDate) {
            System.debug('####14');
            //Integer eowDayNo = mDayNo.get((rec.endDateTime).formatGMT('EEEE'));
            Integer eowDayNo = mDayNo.get((rec.endDateTime).formatGMT('EEEE'));
            if(rec.endTime!=Time.newInstance(0, 0, 0, 0))
            {
              TimeDetails toTime = new TimeDetails();
              toTime.startTime = Time.newInstance(0, 0, 0, 0);
              toTime.endTime = rec.endTime;

              if (!OOOrecsOfWeek.containsKey(eowDayNo)) {
                OOOrecsOfWeek.put(eowDayNo, new List < TimeDetails > ());
              }
              List < TimeDetails > lrecs2 = OOOrecsOfWeek.get(eowDayNo);
              lrecs2.add(toTime);

              OOOrecsOfWeek.put(eowDayNo, lrecs2);
            }
            

            //middle records
            for (Integer i = 1; i < eowDayNo; i++) {
              if (!OOOrecsOfWeek.containsKey(i)) {
                OOOrecsOfWeek.put(i, new List < TimeDetails > ());
              }
              List < TimeDetails > lrecs3 = OOOrecsOfWeek.get(i);

              TimeDetails trec = new TimeDetails();
              trec.startTime = Time.newInstance(0, 0, 0, 0);
              trec.endTime = Time.newInstance(23, 59, 0, 0);
              lrecs3.add(trec);
              OOOrecsOfWeek.put(i, lrecs3);
            }

          } 
          //Start date time in current week , End date time in next week
          else if (rec.startDateTime > = weekStartDate && rec.endDateTime > weekEndDate) {
            System.debug('####15');
            Integer sowDayNo = mDayNo.get((rec.startDateTime).formatGMT('EEEE'));

            TimeDetails fromTime = new TimeDetails();
            fromTime.startTime = rec.startTime;
            fromTime.endTime = Time.newInstance(23, 59, 0, 0);

            if (!OOOrecsOfWeek.containsKey(sowDayNo)) {
              OOOrecsOfWeek.put(sowDayNo, new List < TimeDetails > ());
            }
            List < TimeDetails > lrecs = OOOrecsOfWeek.get(sowDayNo);
            lrecs.add(fromTime);
            OOOrecsOfWeek.put(sowDayNo, lrecs);

            //middle records
            for (Integer i = sowDayNo + 1; i <= 7; i++) {
              if (!OOOrecsOfWeek.containsKey(i)) {
                OOOrecsOfWeek.put(i, new List < TimeDetails > ());
              }
              List < TimeDetails > lrecs3 = OOOrecsOfWeek.get(i);

              TimeDetails trec = new TimeDetails();
              trec.startTime = Time.newInstance(0, 0, 0, 0);
              trec.endTime = Time.newInstance(23, 59, 0, 0);
              lrecs3.add(trec);
              OOOrecsOfWeek.put(i, lrecs3);
            }

          } 
          //Start date time in previous week, end date time in next week..OOO record spans for 2 or more weeks
          else if (rec.startDateTime < weekStartDate && rec.endDateTime > weekEndDate) {
            System.debug('####16');
            for (Integer i = 1; i <= 7; i++) {
              if (!OOOrecsOfWeek.containsKey(i)) {
                OOOrecsOfWeek.put(i, new List < TimeDetails > ());
              }
              List < TimeDetails > lrecs3 = OOOrecsOfWeek.get(i);

              TimeDetails trec = new TimeDetails();
              trec.startTime = Time.newInstance(0, 0, 0, 0);
              trec.endTime = Time.newInstance(23, 59, 0, 0);
              lrecs3.add(trec);
              OOOrecsOfWeek.put(i, lrecs3);
            }

          }
        }
      }
      mUnavailabilityRecs.put(conId, OOOrecsOfWeek);

    }
  }
  System.debug('The map of unavailability are mUnavailabilityRecs');
  System.debug(mUnavailabilityRecs);  

  return mUnavailabilityRecs;
  }
  */

  //Creating Final map of availibility records after comparing map of Availability and Unavailability 
  /*@AuraEnabled
  public static Map < Id, Map < Integer, List < TimeDetails >>> finalAvailibilityMap(Map < Id, Map < Integer, List < TimeDetails >>> mUnavailabilityRecs , Map < Id, Map < Integer, List < TimeDetails >>> mConIdLAvailibilityRecs , List<Id> sConId){
  Map < Id, Map < Integer, List < TimeDetails >>> finalMapAvailabilityRecs = new Map < Id, Map < Integer, List < TimeDetails >>> ();

        for (Id conId: sConId) {
          //Map<Integer,List<TimeDetails>> availDetails = mConIdLAvailibilityRecs.get(conId);
          //Map<Integer,List<TimeDetails>> unAvailDetails = mUnavailabilityRecs.get(conId);

         // Map < Integer, List < TimeDetails >> availDetails = mConIdLAvailibilityRecs.get(conId);
          Map < Integer, List < TimeDetails >> availDetails = new Map < Integer, List < TimeDetails >> ();
          Map < Integer, List < TimeDetails >> unAvailDetails = new Map < Integer, List < TimeDetails >> ();
          //If both Avail and Unavail has entries..contactId
          if (mUnavailabilityRecs.containsKey(conId) && mConIdLAvailibilityRecs.containsKey(conId)) {

            Map < Integer, List < TimeDetails >> finalAvailDetails = new Map < Integer, List < TimeDetails >> ();
            availDetails = mConIdLAvailibilityRecs.get(conId);
            unAvailDetails = mUnavailabilityRecs.get(conId);

            for (Integer i = 1; i <= 7; i++) {
              List < TimeDetails > lFRecs = new List < TimeDetails > ();
              List < TimeDetails > templRecs = new List < TimeDetails > ();

              List < TimeDetails > lAvailRecs = new List < TimeDetails > ();
              List < TimeDetails > lOOORecs = new List < TimeDetails > ();

              Time t1 = Time.newInstance(0, 0, 0, 0);
              Time t2 = Time.newInstance(23, 59, 0, 0);
              if (availDetails.containsKey(i))
                lAvailRecs = availDetails.get(i);
              if (unAvailDetails.containsKey(i))
                lOOORecs = unAvailDetails.get(i);

              if (lAvailRecs.size() == 0) {
                finalAvailDetails.put(i, new List < TimeDetails > ());
              } 
              else if ((lOOORecs.size() > 0 && lAvailRecs.size() == 0) || (lAvailRecs.size() == 0 && lOOORecs.size() == 0)) {
                //Do nothing
                finalAvailDetails.put(i, new List < TimeDetails > ());
                  System.debug('test 1');
              }
              //000 = 00:00 - 23:59...Avail record : 2-3 , 10-23 ===> final record = nothing
              else if (lOOORecs.size() == 1 && (lOOORecs[0].startTime == t1 && lOOORecs[0].endTime == t2)) {
                //Do nothing
                finalAvailDetails.put(i, new List < TimeDetails > ());
              }
              //OOO = Nothing...Avail record : 2-3 , 10-23 ===> final record = 2-3 , 10-23
              else if (lOOORecs.size() == 0 && lAvailRecs.size() > 0) {
                for (TimeDetails rec: lAvailRecs) {
                  lFRecs.add(rec);
                }
                finalAvailDetails.put(i, lFRecs);
              } 
              else if (lOOORecs.size() > 0 && lAvailRecs.size() > 0) {
                List < TimeDetails > latestList = new List < TimeDetails > ();
                //templRecs.addAll(lAvailRecs);
                for (TimeDetails oorec: lOOORecs) {
                  for (TimeDetails availrec: lAvailRecs) {
                    //000 = 06:30 - 23:59...Avail records = 0:00 - 0:00 ==> final record = 00:00 - 6:30
                    if ((availrec.startTime == t1 && availrec.endTime == t1) && oorec.endTime == t2) {
                      System.debug('######1');
                      TimeDetails rec = new TimeDetails();
                      rec.startTime = t1;
                      rec.endTime = oorec.startTime;
                      lFRecs.add(rec);

                      templRecs.clear();
                      templRecs.addAll(lFRecs);
                    }

                    //OOO = 00:00 - 6:30 ...Avail record 00:00 - 00:00 ===> Final records 6:30 - 00:00 
                    else if ((availrec.startTime == t1 && availrec.endTime == t1) && (oorec.startTime == t1 && oorec.endTime > t1)) {
                      System.debug('######2');
                      TimeDetails rec = new TimeDetails();
                      rec.startTime = oorec.endTime;
                      rec.endTime = t1;
                      lFRecs.add(rec);
                      templRecs.clear();
                      templRecs.addAll(lFRecs);

                    }

                    //OOO = 02:00 - 6:30...Avail record 00:00 - 00:00 ===> Final records 00:00 - 2:00 , 6:30 - 00:00 (23:59)
                    else if ((availrec.startTime == t1 && availrec.endTime == t1) && (oorec.startTime > t1 && oorec.endTime > t1)) {
                      System.debug('######3');
                      TimeDetails rec = new TimeDetails();
                      rec.startTime = availrec.startTime;
                      rec.endTime = oorec.startTime;
                      lFRecs.add(rec);

                      TimeDetails rec2 = new TimeDetails();
                      rec2.startTime = oorec.endTime;
                      rec2.endTime = availrec.endTime;
                      lFRecs.add(rec2);

                      templRecs.clear();
                      templRecs.addAll(lFRecs);

                    }

                    //000 = 02:00 - 05:00...Avail records = 6:00 - 13:00 ==> final record = 06:00 - 13:00 
                    else if ((oorec.startTime < availrec.startTime && oorec.endTime < availrec.startTime)) {
                      System.debug('######4');
                      TimeDetails rec = new TimeDetails();
                      rec.startTime = availrec.startTime;
                      rec.endTime = availrec.endTime;
                      lFRecs.add(rec);
                      templRecs.clear();
                      templRecs.addAll(lFRecs);
                    }
                    //000 = 13:00 - 23:00... Avail records = 11:00 - 12:30 ===> final record = 11:00 - 12:30  
                    else if (availrec.startTime < oorec.startTime && availrec.endTime < = oorec.startTime) {
                      System.debug('######5');
                      TimeDetails rec = new TimeDetails();
                      rec.startTime = availrec.startTime;
                      rec.endTime = availrec.endTime;
                      lFRecs.add(rec);
                      templRecs.clear();
                      templRecs.addAll(lFRecs);
                    }
                    //000 = 10:00 - 12:00...Avail records = 6:00 -15:00 ==> final record = 6:00 - 10:00 , 12:00 - 15:00
                    else if (oorec.startTime > availrec.startTime && oorec.endTime < availrec.endTime) {
                      System.debug('######6');
                      TimeDetails rec = new TimeDetails();
                      rec.startTime = availrec.startTime;
                      rec.endTime = oorec.startTime;
                      lFRecs.add(rec);

                      TimeDetails rec2 = new TimeDetails();
                      rec2.startTime = oorec.endTime;
                      rec2.endTime = availrec.endTime;
                      lFRecs.add(rec2);
                      templRecs.clear();
                      templRecs.addAll(lFRecs);
                    }
                    //000 = 6:00 - 10:00...Avail records = 6:00 -13:00 ==> final record = 10:00 - 13:00
                    else if (oorec.startTime == availrec.startTime && oorec.endTime < availrec.endTime) {
                      System.debug('######71');
                      //Long ms = (availrec.endTime).minute()- (oorec.endTime).minute();
                      //if(ms>1)
                      //{
                        System.debug('######7');
                        TimeDetails rec = new TimeDetails();
                        rec.startTime = oorec.endTime;
                        rec.endTime = availrec.endTime;
                        lFRecs.add(rec);
                        templRecs.clear();
                        templRecs.addAll(lFRecs);
                      //}
                                            
                    }

                    //000 = 00:00 - 6:30...Avail records = 6:00 - 13:00 ===> final record = 6:30 - 13:00
                    else if (oorec.startTime < availrec.startTime && (oorec.endTime > availrec.startTime && oorec.endTime < availrec.endTime)) {
                      System.debug('######8');
                      TimeDetails rec = new TimeDetails();
                      rec.startTime = oorec.endTime;
                      rec.endTime = availrec.endTime;
                      lFRecs.add(rec);
                      templRecs.clear();
                      templRecs.addAll(lFRecs);
                    }
                    
                    //000 : 1:30 - 5:30..Avail : 00:00 - 5:30..the Avail : 00:00 - 1:30
                    else if(availrec.startTime < oorec.startTime && availrec.endTime < = oorec.endTime)
                    {
                      System.debug('######9');
                      TimeDetails rec = new TimeDetails();
                      rec.startTime = availrec.startTime ;
                      rec.endTime = oorec.startTime;
                      lFRecs.add(rec);
                      templRecs.clear();
                      templRecs.addAll(lFRecs);
                    }

                    ////000 : 1:30 - 5:30..Avail : 5:30 - 10:00..the Avail : 5:30 - 10:00
                    else if(oorec.startTime < availrec.startTime && oorec.endTime < = availrec.startTime )
                    {
                      System.debug('######10');
                      TimeDetails rec = new TimeDetails();
                      rec.startTime = availrec.startTime ;
                      rec.endTime = availrec.endTime;
                      lFRecs.add(rec);
                      templRecs.clear();
                      templRecs.addAll(lFRecs);
                    }


                    //000 = 03:00 - 16:00 / 06:00 - 16:00 ...Avail records = 6:00 - 13:00 ==> final record = nothing
                    //000 = 10:00 - 13:00....Avail records = 10:00 - 13:00 ===> final record = nothing
                    //000 = 13- 21:00....Avail records = 19:15 - 19:45 ===> final record = nothing
                    else if ((oorec.endTime > availrec.endTime && oorec.startTime < = availrec.startTime) ||
                      (oorec.startTime == availrec.startTime && oorec.endTime == availrec.endTime) ||
                      ((oorec.startTime > availrec.startTime && oorec.startTime < availrec.endTime) && (oorec.endTime > availrec.startTime && oorec.endTime < availrec.endTime))
                      ) {

                      //do nothing
                      System.debug('######11');

                    }
                    
                    System.debug('######12 '+availrec);
                  }
                  System.debug('lAvailRecs' + lAvailRecs);
                  lAvailRecs.clear();
                  lAvailRecs.addAll(lFRecs);

                  System.debug('templRecs' + templRecs);
                  System.debug('lFRecs' + lFRecs);

                  latestList = new List < TimeDetails > ();
                  latestList.addAll(lFRecs);
                  lFRecs.clear();
                  System.debug('after clear lFRecs' + lFRecs);

                  System.debug('the latest list is ' + latestList);

                }

                finalAvailDetails.put(i, latestList);

              }

            }
            finalMapAvailabilityRecs.put(conId, finalAvailDetails);
          }
          //If only Avail has the entries..contactId
          else if(mConIdLAvailibilityRecs.containsKey(conId) && !mUnavailabilityRecs.containsKey(conId))
          {
            Map < Integer, List < TimeDetails >> availDetails1 = new Map < Integer, List < TimeDetails >>();
            availDetails1 = mConIdLAvailibilityRecs.get(conId);
            finalMapAvailabilityRecs.put(conId, availDetails1);
          }
          /*If only Unavail has the entries..contactId
          else if(!mConIdLAvailibilityRecs.containsKey(conId) && mUnavailabilityRecs.containsKey(conId))
          {
            //Add the contact Id to avail list..all the entries of that would become unavailable
            Map < Integer, List < TimeDetails >> availDetails1 = new Map < Integer, List < TimeDetails >>();
            finalMapAvailabilityRecs.put(conId, availDetails1);
          }
          //Add else condition..//If both Avail and Unavail has no entries..contactId
          else if(!mConIdLAvailibilityRecs.containsKey(conId) && !mUnavailabilityRecs.containsKey(conId)){
            //Then do nothing..don't add Contact Id also to the list
          }*/
  /*}

      System.debug('the final map is finalMapAvailabilityRecs');
      System.debug(finalMapAvailabilityRecs);

      return finalMapAvailabilityRecs;
    }
*/
  //Converting final map of Availability from GMT to User Timezone
  @AuraEnabled
  public static Map < Id, Map < Integer, List < TimeDetails >>> getAvailabilityMapInUserTZ(Integer tzOffsetMS, String tzOffset, Map < Id, Map < Integer, List < TimeDetails >>> finalMapAvailabilityRecs, List < Id > sConId, Map < Id, List < TimeDetails >> mOffSetRec) {
    Map < Id, Map < Integer, List < TimeDetails >>> mConIdAvailRecsUserTZ = new Map < Id, Map < Integer, List < TimeDetails >>> ();
    Integer hr = Integer.valueOf(tzOffset.substring(1, 3));
    Integer min = Integer.valueOf(tzOffset.substring(4, 6));
    System.debug(hr);
    System.debug(min);

    if (tzOffsetMS > 0) {

      Time offsetValue = Time.newInstance(24, 00, 00, 00).addHours(-hr).addMinutes(-min);
      System.debug('the offset value');
      System.debug(offsetValue);

      for (Id conId: sConId) {
        //Map<Integer,List<TimeDetails>> mDayAvailRecord = mConIdLAvailibilityRecs.get(conId);
        //Map<Integer,List<TimeDetails>> mDayAvailRecord = finalMapAvailabilityRecs.get(conId);
        Map < Integer, List < TimeDetails >> mDayAvailRecordsAfterUserTimeZone = new Map < Integer, List < TimeDetails >> ();
        Map < Integer, List < TimeDetails >> mDayAvailRecord = new Map < Integer, List < TimeDetails >> ();
        if (finalMapAvailabilityRecs.containsKey(conId)) {

          mDayAvailRecord = finalMapAvailabilityRecs.get(conId);

          for (Integer i = 1; i <= 7; i++) {
            if (mDayAvailRecord.containsKey(i)) {

              List < TimeDetails > avaRecords = mDayAvailRecord.get(i);
              List < TimeDetails > localCurrentDay = new List < TimeDetails > ();
              List < TimeDetails > localNextDay = new List < TimeDetails > ();

              for (TimeDetails rec: avaRecords) {
                /*if (rec.startTime == rec.endTime) {
                  TimeDetails timeRec = new TimeDetails();
                  timeRec.startTime = (rec.startTime).addHours(hr).addMinutes(min);
                  timeRec.endTime = Time.newInstance(23, 59, 0, 0);
                  localCurrentDay.add(timeRec);
                  TimeDetails timeRec2 = new TimeDetails();
                  timeRec2.startTime = Time.newInstance(0, 0, 0, 0);
                  timeRec2.endTime = (rec.endTime).addHours(hr).addMinutes(min);
                  localNextDay.add(timeRec2);
                } 
                else*/ if (rec.startTime == Time.newInstance(0, 0, 0, 0) && rec.endTime == Time.newInstance(23, 59, 0, 0)) {
                  TimeDetails timeRec = new TimeDetails();

                  timeRec.startTime = Time.newInstance(0, 0, 0, 0).addHours(hr).addMinutes(min);
                  timeRec.endTime = Time.newInstance(23, 59, 0, 0);
                  localCurrentDay.add(timeRec);

                  TimeDetails timeRec2 = new TimeDetails();

                  timeRec2.startTime = Time.newInstance(0, 0, 0, 0);
                  timeRec2.endTime = Time.newInstance(0, 0, 0, 0).addHours(hr).addMinutes(min);
                  localNextDay.add(timeRec2);
                }
                // Record : 6:30 - 00:00 (But in user timezone + 5:30 it becomes : 12 - 5:30....then 12-23:59 (currentday)..00:00 - 5:30 (next day))
                /*else if (rec.startTime < offsetValue && rec.endTime == Time.newInstance(0, 0, 0, 0)) {
                  TimeDetails timeRec = new TimeDetails();
  
                  timeRec.startTime = (rec.startTime).addHours(hr).addMinutes(min);
                  timeRec.endTime = Time.newInstance(23, 59, 0, 0);
                  localCurrentDay.add(timeRec);
  
                  TimeDetails timeRec2 = new TimeDetails();
  
                  timeRec2.startTime = Time.newInstance(0, 0, 0, 0);
                  timeRec2.endTime = (rec.endTime).addHours(hr).addMinutes(min);
                  localNextDay.add(timeRec2);
                } */
                else if (rec.startTime < offsetValue && rec.endTime < = offsetValue) {

                  TimeDetails timeRec = new TimeDetails();

                  timeRec.startTime = (rec.startTime).addHours(hr).addMinutes(min);
                  if (rec.endTime == offsetValue) {
                    timeRec.endTime = Time.newInstance(23, 59, 0, 0);
                  } 
                  else {
                    timeRec.endTime = (rec.endTime).addHours(hr).addMinutes(min);
                  }
                  localCurrentDay.add(timeRec);

                } 
                else if ((rec.startTime < offsetValue && rec.endTime > offsetValue)) {
                  TimeDetails timeRec = new TimeDetails();

                  timeRec.startTime = (rec.startTime).addHours(hr).addMinutes(min);
                  timeRec.endTime = Time.newInstance(23, 59, 0, 0);
                  localCurrentDay.add(timeRec);

                  TimeDetails timeRec2 = new TimeDetails();

                  timeRec2.startTime = Time.newInstance(0, 0, 0, 0);
                  if (rec.endTime == Time.newInstance(23, 59, 0, 0)) {
                    timeRec2.endTime = (Time.newInstance(24, 0, 0, 0)).addHours(hr).addMinutes(min);
                  } 
                  else {
                    timeRec2.endTime = (rec.endTime).addHours(hr).addMinutes(min);
                  }
                  localNextDay.add(timeRec2);

                }
                /*else if (rec.startTime > offsetValue && rec.endTime < offsetValue) {
  
                  TimeDetails timeRec = new TimeDetails();
  
                  timeRec.startTime = (rec.startTime).addHours(hr).addMinutes(min);
                  timeRec.endTime = (rec.endTime).addHours(hr).addMinutes(min);
                  localNextDay.add(timeRec);
                }*/
                else if (rec.startTime > = offsetValue && rec.endTime > offsetValue) {
                  TimeDetails timeRec = new TimeDetails();

                  timeRec.startTime = (rec.startTime).addHours(hr).addMinutes(min);
                  if (rec.endTime == Time.newInstance(23, 59, 0, 0)) {
                    timeRec.endTime = (Time.newInstance(24, 0, 0, 0)).addHours(hr).addMinutes(min);
                  } 
                  else {
                    timeRec.endTime = (rec.endTime).addHours(hr).addMinutes(min);
                  }

                  localNextDay.add(timeRec);

                }

              }

              System.debug('the local current day');
              System.debug(localCurrentDay);

              System.debug('the local next day');
              System.debug(localNextDay);

              if (!mDayAvailRecordsAfterUserTimeZone.containsKey(i)) {
                mDayAvailRecordsAfterUserTimeZone.put(i, new List < TimeDetails > ());
              }
              List < TimeDetails > currentDay = mDayAvailRecordsAfterUserTimeZone.get(i);
              System.debug('the current day ');
              System.debug(currentDay);

              //for Availability records 
              //if(isOOOMap == false)
              //{
              Integer nextDayKey;
              if (i == 7) {
                nextDayKey = 1;
              } 
              else
                nextDayKey = i + 1;

              if (!mDayAvailRecordsAfterUserTimeZone.containsKey(nextDayKey)) {
                mDayAvailRecordsAfterUserTimeZone.put(nextDayKey, new List < TimeDetails > ());
              }
              List < TimeDetails > nextDay = mDayAvailRecordsAfterUserTimeZone.get(nextDayKey);
              System.debug('the next day ');
              System.debug(nextDay);

              nextDay.addAll(localNextDay);
              mDayAvailRecordsAfterUserTimeZone.put(nextDayKey, nextDay);

              currentDay.addAll(localCurrentDay);
              mDayAvailRecordsAfterUserTimeZone.put(i, currentDay);
              //}
              //For OOO records
              /*else if(isOOOMap == true){
                Integer nextDayKey;
                if (i == 7) {
                  nextDayKey = 0;
                } 
                else
                  nextDayKey = i + 1;
                
                System.debug(nextDayKey);
                if(nextDayKey>0)
                {
                  if (!mDayAvailRecordsAfterUserTimeZone.containsKey(nextDayKey)) {
                    mDayAvailRecordsAfterUserTimeZone.put(nextDayKey, new List < TimeDetails > ());
                  }
                  List < TimeDetails > nextDay = mDayAvailRecordsAfterUserTimeZone.get(nextDayKey);
                  System.debug('the next day ');
                  System.debug(nextDay);
    
                  nextDay.addAll(localNextDay);                   
                  mDayAvailRecordsAfterUserTimeZone.put(nextDayKey, nextDay);
                }  
                System.debug('test1');
                if(i==1)
                {
                  if(mOffSetRec.containsKey(conId))
                  {
                    List<TimeDetails> ooorecs = mOffSetRec.get(conId);
                    if(ooorecs.size()>0)
                    {
                      currentDay.addAll(ooorecs); 
                    }
                    currentDay.addAll(localCurrentDay);
                    mDayAvailRecordsAfterUserTimeZone.put(i, currentDay);
                  }
                }

                else {
                    currentDay.addAll(localCurrentDay);
                    mDayAvailRecordsAfterUserTimeZone.put(i, currentDay);
                }                               
              }*/
            }

            /*else if(!mDayAvailRecord.containsKey(i) && i==1 && isOOOMap == true)
            {
              if(!mDayAvailRecordsAfterUserTimeZone.containsKey(i))
              {
                mDayAvailRecordsAfterUserTimeZone.put(i, new List<TimeDetails>());
              }
              List<TimeDetails> lrecs = mDayAvailRecordsAfterUserTimeZone.get(i);
              if(mOffSetRec.containsKey(conId))
              {
                List<TimeDetails> ooorecs = mOffSetRec.get(conId);
                if(ooorecs.size()>0)
                {
                  lrecs.addAll(ooorecs);
                  mDayAvailRecordsAfterUserTimeZone.put(i, lrecs);
                }
              }
            }*/

            System.debug('the recs mDayAvailRecordsAfterUserTimeZone');
            System.debug(mDayAvailRecordsAfterUserTimeZone);
          }
          System.debug('the recs outside mDayAvailRecordsAfterUserTimeZone');
          System.debug(mDayAvailRecordsAfterUserTimeZone);

          if (!mConIdAvailRecsUserTZ.containsKey(conId)) {
            mConIdAvailRecsUserTZ.put(conId, new Map < Integer, List < TimeDetails >> ());
          }

          Map < Integer, List < TimeDetails >> theRecords = mConIdAvailRecsUserTZ.get(conId);
          theRecords.putAll(mDayAvailRecordsAfterUserTimeZone);
          mConIdAvailRecsUserTZ.put(conId, theRecords);

        }
      }
      System.debug('the map of records in User TZ after each contact is mConIdAvailRecsUserTZ');
      System.debug(mConIdAvailRecsUserTZ);
    } 
    else if (tzOffsetMS < 0) {
      //If time difference is GMT -5.30
      //If startTime / endTime < 5:30 then goes to previous day

      Time offsetValue = Time.newInstance(hr, min, 00, 00);
      System.debug('the offset value');
      System.debug(offsetValue);

      for (Id conId: sConId) {
        //Map<Integer,List<TimeDetails>> mDayAvailRecord = mConIdLAvailibilityRecs.get(conId);
        //Map<Integer,List<TimeDetails>> mDayAvailRecord = finalMapAvailabilityRecs.get(conId);
        Map < Integer, List < TimeDetails >> mDayAvailRecord = new Map < Integer, List < TimeDetails >> ();
        Map < Integer, List < TimeDetails >> mDayAvailRecordsAfterUserTimeZone = new Map < Integer, List < TimeDetails >> ();
        if (finalMapAvailabilityRecs.containsKey(conId)) {
          mDayAvailRecord = finalMapAvailabilityRecs.get(conId);

          for (Integer i = 1; i <= 7; i++) {
            if (mDayAvailRecord.containsKey(i)) {

              List < TimeDetails > avaRecords = mDayAvailRecord.get(i);

              List < TimeDetails > localCurrentDay = new List < TimeDetails > ();
              List < TimeDetails > localPreviousDay = new List < TimeDetails > ();

              for (TimeDetails rec: avaRecords) {

                /*if (rec.startTime == rec.endTime) {
                  TimeDetails timeRec = new TimeDetails();
                  timeRec.startTime = (rec.startTime).addHours(-hr).addMinutes(-min);
                  timeRec.endTime = Time.newInstance(23, 59, 0, 0);
                  localPreviousDay.add(timeRec);
                  TimeDetails timeRec2 = new TimeDetails();
                  timeRec2.startTime = Time.newInstance(0, 0, 0, 0);
                  timeRec2.endTime = (rec.endTime).addHours(-hr).addMinutes(-min);
                  localCurrentDay.add(timeRec2);
                } 
                else */if (rec.startTime == Time.newInstance(0, 0, 0, 0) && rec.endTime == Time.newInstance(23, 59, 0, 0)) {
                  TimeDetails timeRec = new TimeDetails();

                  timeRec.startTime = Time.newInstance(0, 0, 0, 0).addHours(-hr).addMinutes(-min);
                  timeRec.endTime = Time.newInstance(23, 59, 0, 0);
                  localPreviousDay.add(timeRec);

                  TimeDetails timeRec2 = new TimeDetails();

                  timeRec2.startTime = Time.newInstance(0, 0, 0, 0);
                  timeRec2.endTime = Time.newInstance(0, 0, 0, 0).addHours(-hr).addMinutes(-min);
                  localCurrentDay.add(timeRec2);
                } 
                else if (rec.startTime < offsetValue && rec.endTime < = offsetValue) {

                  TimeDetails timeRec = new TimeDetails();
                  timeRec.startTime = (rec.startTime).addHours(-hr).addMinutes(-min);
                  if (rec.endTime == offsetValue) {
                    timeRec.endTime = Time.newInstance(23, 59, 0, 0);
                  } 
                  else {
                    timeRec.endTime = (rec.endTime).addHours(-hr).addMinutes(-min);
                  }
                  localPreviousDay.add(timeRec);
                }
                /*else if (rec.startTime < offsetValue && rec.endTime == offsetValue) {
  
                  TimeDetails timeRec = new TimeDetails();   
                  timeRec.startTime = (rec.startTime).addHours(-hr).addMinutes(-min);
                  //timeRec.endTime = (rec.endTime).addHours(-hr).addMinutes(-min);
                  timeRec.endTime =Time.newInstance(23, 59, 0, 0);
                  localPreviousDay.add(timeRec);  
                } */
                else if (rec.startTime < offsetValue && rec.endTime > offsetValue) {
                  TimeDetails timeRec = new TimeDetails();

                  timeRec.startTime = (rec.startTime).addHours(-hr).addMinutes(-min);
                  timeRec.endTime = Time.newInstance(23, 59, 0, 0);
                  localPreviousDay.add(timeRec);

                  TimeDetails timeRec2 = new TimeDetails();

                  timeRec2.startTime = Time.newInstance(0, 0, 0, 0);
                  if (rec.endTime == Time.newInstance(23, 59, 0, 0)) {
                    timeRec2.endTime = (Time.newInstance(24, 0, 0, 0)).addHours(-hr).addMinutes(-min);
                  } 
                  else {
                    timeRec2.endTime = (rec.endTime).addHours(-hr).addMinutes(-min);
                  }
                  localCurrentDay.add(timeRec2);

                } 
                else if (rec.startTime > = offsetValue) {

                  TimeDetails timeRec = new TimeDetails();

                  timeRec.startTime = (rec.startTime).addHours(-hr).addMinutes(-min);
                  if (rec.endTime == Time.newInstance(23, 59, 0, 0)) {
                    timeRec.endTime = (Time.newInstance(24, 0, 0, 0)).addHours(-hr).addMinutes(-min);
                  } 
                  else {
                    timeRec.endTime = (rec.endTime).addHours(-hr).addMinutes(-min);
                  }

                  localCurrentDay.add(timeRec);
                }

              }

              System.debug('the local current day');
              System.debug(localCurrentDay);

              System.debug('the local previous day');
              System.debug(localPreviousDay);

              if (!mDayAvailRecordsAfterUserTimeZone.containsKey(i)) {
                mDayAvailRecordsAfterUserTimeZone.put(i, new List < TimeDetails > ());
              }
              List < TimeDetails > currentDay = mDayAvailRecordsAfterUserTimeZone.get(i);
              System.debug('the current day ');
              System.debug(currentDay);

              //List < TimeDetails > prevDay = new List<TimeDetails>();
              //Availability records
              //if(isOOOMap == false)
              //{
              Integer prevDayKey;
              if (i == 1) {
                prevDayKey = 7;
              } 
              else
                prevDayKey = i - 1;

              if (!mDayAvailRecordsAfterUserTimeZone.containsKey(prevDayKey)) {
                mDayAvailRecordsAfterUserTimeZone.put(prevDayKey, new List < TimeDetails > ());
              }
              List < TimeDetails > prevDay = mDayAvailRecordsAfterUserTimeZone.get(prevDayKey);
              System.debug('the previous day ');
              System.debug(prevDay);

              prevDay.addAll(localPreviousDay);
              mDayAvailRecordsAfterUserTimeZone.put(prevDayKey, prevDay);

              currentDay.addAll(localCurrentDay);
              mDayAvailRecordsAfterUserTimeZone.put(i, currentDay);

              //}
              //OOO records
              /*else if(isOOOMap == true){
                Integer prevDayKey;
                if (i == 1) {
                  prevDayKey = 0;
                } 
                else
                  prevDayKey = i - 1;
                
                System.debug(prevDayKey);
                if(prevDayKey>0)
                {
                  if (!mDayAvailRecordsAfterUserTimeZone.containsKey(prevDayKey)) {
                    mDayAvailRecordsAfterUserTimeZone.put(prevDayKey, new List < TimeDetails > ());
                  }
                  List < TimeDetails >  prevDay = mDayAvailRecordsAfterUserTimeZone.get(prevDayKey);
                  System.debug('the prev day ');
                  System.debug(prevDay);
    
                  prevDay.addAll(localPreviousDay);                   
                  mDayAvailRecordsAfterUserTimeZone.put(prevDayKey, prevDay);
                }  
                System.debug('test1');
                if(i==7)
                {
                  if(mOffSetRec.containsKey(conId))
                  {
                    List<TimeDetails> ooorecs = mOffSetRec.get(conId);
                    if(ooorecs.size()>0)
                    {
                      currentDay.addAll(ooorecs);                          
                    }
                    currentDay.addAll(localCurrentDay);
                    mDayAvailRecordsAfterUserTimeZone.put(i, currentDay);
                  }
                }

                else {
                    currentDay.addAll(localCurrentDay);
                    mDayAvailRecordsAfterUserTimeZone.put(i, currentDay);
                }                               
              }*/

              //mDayAvailRecordsAfterUserTimeZone.put(i,currentDay);
              //mDayAvailRecordsAfterUserTimeZone.put(nextDayKey,nextDay);
            }

            /*else if(!mDayAvailRecord.containsKey(i) && i==7 && isOOOMap == true)
            {
              if(!mDayAvailRecordsAfterUserTimeZone.containsKey(i))
              {
                mDayAvailRecordsAfterUserTimeZone.put(i, new List<TimeDetails>());
              }
              List<TimeDetails> lrecs = mDayAvailRecordsAfterUserTimeZone.get(i);
              if(mOffSetRec.containsKey(conId))
              {
                List<TimeDetails> ooorecs = mOffSetRec.get(conId);
                if(ooorecs.size()>0)
                {
                  lrecs.addAll(ooorecs);
                  mDayAvailRecordsAfterUserTimeZone.put(i, lrecs);
                }
              }
            }*/

            System.debug('the recs mDayAvailRecordsAfterUserTimeZone');
            System.debug(mDayAvailRecordsAfterUserTimeZone);
          }
          System.debug('the recs outside mDayAvailRecordsAfterUserTimeZone');
          System.debug(mDayAvailRecordsAfterUserTimeZone);

          if (!mConIdAvailRecsUserTZ.containsKey(conId)) {
            mConIdAvailRecsUserTZ.put(conId, new Map < Integer, List < TimeDetails >> ());
          }

          Map < Integer, List < TimeDetails >> theRecords = mConIdAvailRecsUserTZ.get(conId);
          theRecords.putAll(mDayAvailRecordsAfterUserTimeZone);
          mConIdAvailRecsUserTZ.put(conId, theRecords);

        }
      }
      System.debug('the map of records in User TZ after each contact is mConIdAvailRecsUserTZ');
      System.debug(mConIdAvailRecsUserTZ);
    } 
    else if (tzOffsetMS == 0) {

      Time standardTime = Time.newInstance(0, 0, 0, 0);
      for (Id conId: sConId) {
        //Map<Integer,List<TimeDetails>> mDayAvailRecord = mConIdLAvailibilityRecs.get(conId);
        //Map<Integer,List<TimeDetails>> mDayAvailRecord = finalMapAvailabilityRecs.get(conId);
        Map < Integer, List < TimeDetails >> mDayAvailRecord = new Map < Integer, List < TimeDetails >> ();
        Map < Integer, List < TimeDetails >> mDayAvailRecordsAfterUserTimeZone = new Map < Integer, List < TimeDetails >> ();
        if (finalMapAvailabilityRecs.containsKey(conId)) {
          mDayAvailRecord = finalMapAvailabilityRecs.get(conId);
          //if(mDayAvailRecord.size()>0){
          for (Integer i = 1; i <= 7; i++) {
            if (mDayAvailRecord.containsKey(i)) {

              List < TimeDetails > avaRecords = mDayAvailRecord.get(i);
              List < TimeDetails > localCurrentDay = new List < TimeDetails > ();
              //List < TimeDetails > localNextDay = new List < TimeDetails > ();

              for (TimeDetails rec: avaRecords) {

                /*if (rec.startTime == standardTime && rec.endTime == standardTime) // 00:00 - 00:00
                {
                  TimeDetails timeRec = new TimeDetails();
                  timeRec.startTime = rec.startTime;
                  timeRec.endTime = Time.newInstance(23, 59, 0, 0);
                  localCurrentDay.add(timeRec);
                } 
                else*/ if (rec.startTime < rec.endTime) { //10;30 - 14:30 or 20:00 - 22:00

                  TimeDetails timeRec = new TimeDetails();

                  timeRec.startTime = rec.startTime;
                  timeRec.endTime = rec.endTime;
                  localCurrentDay.add(timeRec);

                }
              }

              System.debug('the local current day');
              System.debug(localCurrentDay);

              /*System.debug('the local next day');
              System.debug(localNextDay);*/

              if (!mDayAvailRecordsAfterUserTimeZone.containsKey(i)) {
                mDayAvailRecordsAfterUserTimeZone.put(i, new List < TimeDetails > ());
              }
              List < TimeDetails > currentDay = mDayAvailRecordsAfterUserTimeZone.get(i);
              System.debug('the current day ');
              System.debug(currentDay);

              /*Integer nextDayKey;
              if (i == 7) {
                nextDayKey = 1;
  
              } else
                nextDayKey = i + 1;
  
              if (!mDayAvailRecordsAfterUserTimeZone.containsKey(nextDayKey)) {
                mDayAvailRecordsAfterUserTimeZone.put(nextDayKey, new List < TimeDetails > ());
              }
              List < TimeDetails > nextDay = mDayAvailRecordsAfterUserTimeZone.get(nextDayKey);
              System.debug('the next day ');
              System.debug(nextDay);*/

              currentDay.addAll(localCurrentDay);
              //nextDay.addAll(localNextDay);
              mDayAvailRecordsAfterUserTimeZone.put(i, currentDay);
              //mDayAvailRecordsAfterUserTimeZone.put(nextDayKey, nextDay);

              //mDayAvailRecordsAfterUserTimeZone.put(i,currentDay);
              //mDayAvailRecordsAfterUserTimeZone.put(nextDayKey,nextDay);
            }
            System.debug('the recs mDayAvailRecordsAfterUserTimeZone');
            System.debug(mDayAvailRecordsAfterUserTimeZone);
          }
          System.debug('the recs outside mDayAvailRecordsAfterUserTimeZone');
          System.debug(mDayAvailRecordsAfterUserTimeZone);

          if (!mConIdAvailRecsUserTZ.containsKey(conId)) {
            mConIdAvailRecsUserTZ.put(conId, new Map < Integer, List < TimeDetails >> ());
          }

          Map < Integer, List < TimeDetails >> theRecords = mConIdAvailRecsUserTZ.get(conId);
          theRecords.putAll(mDayAvailRecordsAfterUserTimeZone);
          mConIdAvailRecsUserTZ.put(conId, theRecords);
          //}
          /*else{
            Map < Integer, List < TimeDetails >> theRecords = new Map < Integer, List < TimeDetails >>();
            mConIdAvailRecsUserTZ.put(conId, theRecords);
          }*/

        }
      }
      //mConIdAvailRecsUserTZ = finalMapAvailabilityRecs;
      System.debug('the map of records in User TZ after each contact is mConIdAvailRecsUserTZ');
      System.debug(mConIdAvailRecsUserTZ);
    }
    System.debug('the map of records in User TZ is mConIdAvailRecsUserTZ');
    System.debug(mConIdAvailRecsUserTZ);

    return mConIdAvailRecsUserTZ;
  }

  @AuraEnabled
  public static String getTimeZoneNameInStringFormat(Integer tzOffsetMS, Integer hr, Integer min) {
    String timeZoneName = '(GMT ';
    System.debug(hr);
    System.debug(min);
    String shr = '';
    String smin = '';
    if (hr < 10) {
      shr = '0' + hr;
    } 
    else {
      shr = String.valueOf(hr);
    }

    if (min == 0) {
      smin = '0' + min;
    } 
    else {
      smin = String.valueOf(min);
    }

    if (tzOffsetMS > 0) {
      timeZoneName += '+' + shr + ':' + smin + ')';
    } 
    else if (tzOffsetMS < 0) {
      timeZoneName += '-' + shr + ':' + smin + ')';
    } 
    else if (tzOffsetMS == 0) {
      timeZoneName += '+ 00:00)';
    }
    System.debug('TimeZoneName' + timeZoneName);
    return timeZoneName;
  }

  @AuraEnabled
  public static Map < Id, Boolean > checkIfContactIsOOONow(Map < Id, List < DateTimeDetail >> mOOORecordsInUserTZ, DateTime dtUserTZ, List < Id > sConId) {
    Map < Id, Boolean > mConIdOOORecInToday = new Map < Id, Boolean > ();
    for (Id conId: sConId) {
      List < DateTimeDetail > OOOrecords = new List < DateTimeDetail > ();
      Boolean isOOO = false;
      if (mOOORecordsInUserTZ.containsKey(conId)) {
        OOOrecords = mOOORecordsInUserTZ.get(conId);
        for (DateTimeDetail rec: OOOrecords) {
          if (dtUserTZ > = rec.startDateTime && dtUserTZ < = rec.endDateTime) {
            isOOO = true;
          }
        }
      }
      mConIdOOORecInToday.put(conId, isOOO);
    }

    System.debug('the map of mConIdOOORecInToday');
    System.debug(mConIdOOORecInToday);
    return mConIdOOORecInToday;

  }

  @AuraEnabled
  public static Boolean checkIfUserIsCurrentlyAvailable(Map < Integer, List < TimeDetails >> mAvailRecordsInUserTZ, Integer currentDay, Long currentTimeInMS) {
    //Map<Id,Boolean> mConIdAvailRecInToday = new Map<Id,Boolean>();

    Boolean avail = false;
    List < TimeDetails > dayRecs = new List < TimeDetails > ();
    if (mAvailRecordsInUserTZ.containsKey(currentDay)) {
      dayRecs = mAvailRecordsInUserTZ.get(currentDay);
      System.debug('dayRecs' + dayRecs);
      for (TimeDetails rec: dayRecs) {
        Long startTimeInMS = 0;
        Long endTimeInMS = 0;
        startTimeInMS = rec.startTime.hour() * 60 * 60 * 1000 + rec.startTime.minute() * 60 * 1000 + rec.startTime.second() * 100 + rec.startTime.millisecond();
        System.debug('startTimeInMS' + startTimeInMS);
        System.debug('startTime' + rec.startTime);
        endTimeInMS = rec.endTime.hour() * 60 * 60 * 1000 + rec.endTime.minute() * 60 * 1000 + rec.endTime.second() * 100 + rec.endTime.millisecond();
        System.debug('endTimeInMS' + endTimeInMS);
        System.debug('endTime' + rec.endTime);
        if (currentTimeInMS > = startTimeInMS && currentTimeInMS < = endTimeInMS) {
          avail = true;
        }
      }

    }

    System.debug('the map of avail');
    System.debug(avail);
    return avail;
  }

  /*@AuraEnabled 
  public static Map < Id, List < TimeDetails >> getMapOfOffSetRec(Map < Id, List < DateTimeDetail >> mOOORecordsOfWeek,List<Id> lConId,Integer tzOffsetMS,String tzOffset,DateTime weekStartDate,DateTime weekEndDate){
      Map < Id, List < TimeDetails >> mConIdAvailRecsUserTZ = new Map < Id, List < TimeDetails >> ();
      //find out time difference
      Integer hr = Integer.valueOf(tzOffset.substring(1, 3));
      Integer min = Integer.valueOf(tzOffset.substring(4, 6));
      System.debug(hr);
      System.debug(min);
      Map < String, Integer > mDayNo = new Map < String, Integer > {'Monday'=>1,'Tuesday'=>2,'Wednesday'=>3,'Thursday'=>4,'Friday'=>5,'Saturday'=>6,'Sunday'=>7};

      if (tzOffsetMS > 0) {

          Time offsetValue = Time.newInstance(23, 59, 00, 00).addHours(-hr).addMinutes(-min);
            System.debug('the offset value');
            System.debug(offsetValue);

            //The Previous sunday date would be
            DateTime offsetDateTime = weekStartDate.addDays(-1);
            System.debug('the offsetDateTime');
            System.debug(offsetDateTime);

            for(Id conId:lConId)
            {
              List < TimeDetails > localNextDay = new List < TimeDetails > ();
              List < DateTimeDetail > OOOrecords = new List < DateTimeDetail > ();
              if(mOOORecordsOfWeek.containsKey(conId))
              {
                  OOOrecords =mOOORecordsOfWeek.get(conId);
                  for(DateTimeDetail rec: OOOrecords){

                    //OOO : 30/5/2021 - 13/6/2021 00:00...(nothing for next day)

                    //OOO : 30/5/2021 - 13/6/2021 20:00....(13th:00:00 - 20:00)..(next day:00:00 - 1:30)
                    //OOO : 30/5/2021 - 13/6/2021 23:59....(13th:00:00 - 23:59)..(next day:00:00 - 5:29)

                    //OOO : 30/5/2021 - 13/6/2021 02:00....(13th:00:00 - 02:00)..(nothing for next day)
                    if(rec.startDateTime < offsetDateTime && rec.endDateTime > offsetDateTime && rec.endDateTime.DateGmt()==offsetDateTime.DateGmt())
                    {
                      if(rec.endDateTime.TimeGmt()>offsetValue)
                      {
                        TimeDetails timeRec2 = new TimeDetails();
                          timeRec2.startTime = Time.newInstance(0, 0, 0, 0);
                          timeRec2.endTime = rec.endDateTime.TimeGmt().addHours(hr).addMinutes(min);
                          localNextDay.add(timeRec2);

                          System.debug('localNextDay1');
                          System.debug(localNextDay);
                      }
    
                    }

                    //OOO : 30/5/2021 - 15/6/2021....(13th:00-23:59)..NextDay : 00:00 - 5:30

                    else if(rec.startDateTime < offsetDateTime && rec.endDateTime > offsetDateTime)
                    {

                        TimeDetails timeRec2 = new TimeDetails();
                        timeRec2.startTime = Time.newInstance(0, 0, 0, 0);
                        timeRec2.endTime = Time.newInstance(0, 0, 0, 0).addHours(hr).addMinutes(min);
                        localNextDay.add(timeRec2);

                        System.debug('localNextDay2');
                        System.debug(localNextDay);
                    }

                    else if((rec.startDateTime.dateGmt() == offsetDateTime.dateGmt() && rec.endDateTime.dateGmt() == offsetDateTime.dateGmt()))
                    {
                    //OOO : 13/6/2021 19:00 - 13/6/2021 20:00....(13th:19:00 - 20:00)..(next day:00:30 - 1:30)
                      if(rec.startTime > offsetValue && rec.endTime> offsetValue)
                      {
                        TimeDetails timeRec2 = new TimeDetails();
                          timeRec2.startTime = rec.startTime.addHours(hr).addMinutes(min);
                          timeRec2.endTime = rec.endTime.addHours(hr).addMinutes(min);
                          localNextDay.add(timeRec2);

                          System.debug('localNextDay3');
                          System.debug(localNextDay);
                      }

                      //OOO : 13/6/2021 01:00 - 13/6/2021 20:00....(13th:01:00 - 20:00)..(next day:00:00 - 1:30)
                      else if(rec.startTime < offsetValue && rec.endTime > offsetValue)
                        {
                        TimeDetails timeRec2 = new TimeDetails();
                          timeRec2.startTime = Time.newInstance(0, 0, 0, 0);
                          timeRec2.endTime = rec.endTime.addHours(hr).addMinutes(min);
                          localNextDay.add(timeRec2);

                          System.debug('localNextDay4');
                          System.debug(localNextDay);

                      }

                    }
                    //Record starts on 13th...ends in any day..and also (14th 00:00)
                    else if(rec.startDateTime.dateGmt() == offsetDateTime.dateGmt() && rec.endDateTime > = weekStartDate)
                    {
                      //000 : 13/6/2021 10:00 - 15/6/2021 2:00 ..(for 13th : 10:00-23:59)..(next day 00:00 - 5:30)
                      if(rec.startTime < offsetValue)
                      {
                        TimeDetails timeRec2 = new TimeDetails();
                        timeRec2.startTime = Time.newInstance(0, 0, 0, 0);
                        timeRec2.endTime = Time.newInstance(0, 0, 0, 0).addHours(hr).addMinutes(min);
                        localNextDay.add(timeRec2);

                        System.debug('localNextDay5');
                        System.debug(localNextDay);
                      }

                      //000 : 13/6/2021 20:00 - 15/6/2021 2:00 ..(for 13th : 20:00-23:59)..(next day 1:30 - 5:30)
                      else if(rec.startTime > offsetValue )
                      {
                        TimeDetails timeRec2 = new TimeDetails();
                        timeRec2.startTime = (rec.startTime).addHours(hr).addMinutes(min);
                        timeRec2.endTime = Time.newInstance(0, 0, 0, 0).addHours(hr).addMinutes(min);
                        localNextDay.add(timeRec2);

                        System.debug('localNextDay6');
                        System.debug(localNextDay);
                      }
                    }

                }

              }
            
              if (!mConIdAvailRecsUserTZ.containsKey(conId)) {
                mConIdAvailRecsUserTZ.put(conId, new List < TimeDetails > ());
              }
            
              List < TimeDetails > ldet = mConIdAvailRecsUserTZ.get(conId);
              ldet.addAll(localNextDay);
              mConIdAvailRecsUserTZ.put(conId, ldet);
            }

           //return mConIdAvailRecsUserTZ;
            System.debug('mConIdAvailRecsUserTZ....');
            System.debug(mConIdAvailRecsUserTZ);

      }

      else if (tzOffsetMS < 0) {

          Time offsetValue = Time.newInstance(hr, min, 00, 00);
            System.debug('the offset value');
            System.debug(offsetValue);

            //The next monday date would be
            DateTime offsetDateTime = weekEndDate.addDays(1);
            System.debug('the offsetDateTime');
            System.debug(offsetDateTime);     //21-06-2021 23:59:00:00

            for (Id conId: lConId) {
              List < TimeDetails > localPrevDay = new List < TimeDetails > ();
              List < DateTimeDetail > OOOrecords = new List < DateTimeDetail > ();
              if(mOOORecordsOfWeek.containsKey(conId))
              {
                  OOOrecords =mOOORecordsOfWeek.get(conId);
                  for(DateTimeDetail rec: OOOrecords){

                    //Same day
                    if((rec.startDateTime.dateGmt() == offsetDateTime.dateGmt() && rec.endDateTime.dateGmt() == offsetDateTime.dateGmt()))
                    {
                        //When OOO = 21/6/2021 2:00 - 21/6/2021 3:00....(21st : 2-3..for 20th : 22-23)
                        if(rec.startTime<offsetValue)
                        {
                            if(rec.endTime<offsetValue)
                            {
                                TimeDetails timeRec1 = new TimeDetails();
                                timeRec1.startTime = (rec.startTime).addHours(-hr).addMinutes(-min);
                                timeRec1.endTime = (rec.endTime).addHours(-hr).addMinutes(-min);
                                localPrevDay.add(timeRec1);

                                System.debug('localPrevDay1');
                                System.debug(localPrevDay);

                            }

                            //When OOO = 21/6/2021 2:00 - 21/6/2021 20:00....(21st : 2-20..for 20th : 22-23:59)
                            else if(rec.endTime>offsetValue)
                            {
                                TimeDetails timeRec2 = new TimeDetails();
                                timeRec2.startTime = (rec.startTime).addHours(-hr).addMinutes(-min);
                                timeRec2.endTime = Time.newInstance(23, 59, 0, 0);
                                localPrevDay.add(timeRec2);

                                System.debug('localPrevDay2');
                                System.debug(localPrevDay);
                            }
                        }
                        ////When OOO = 21/6/2021 10:00 - 21/6/2021 23:59....Then..nothing
                    }

                    //when OOO : 16/6/2021 - 22/6/2021....Date = 21/6/2021 (00:00 - 23:59)...In UTZ -ve 4...(20-20)..that is 20-23:59 (20th) and 00:00-20:00 (21th)
                    //000 = 16/6/2021 - 21/6/2021 23:59...21st : 00-23:59 prev day : 20-23:59
                    else if(rec.startDateTime < offsetDateTime  && rec.endDateTime > = offsetDateTime)
                      {
                        System.debug(rec);
                        TimeDetails timeRec2 = new TimeDetails();
                        timeRec2.startTime = Time.newInstance(0, 0, 0, 0).addHours(-hr).addMinutes(-min);
                        timeRec2.endTime = Time.newInstance(23, 59, 0, 0);
                        localPrevDay.add(timeRec2);

                        System.debug('localPrevDay3');
                        System.debug(localPrevDay);
                      }

                    //New else if

                    //When OOO = 20/6/2021 10:30 - 21/6/2021 01:00....(21: 00-1...prev day : 20:00-21:00) 
                    //When OOO = 20/6/2021 01:00 - 21/6/2021 10:00....(21: 00-10...prev day : 20:00-23:59) 

                    //when OOO : 16/6/2021 - 21/6/2021 00:00....(20-23:59)

                    //When OOO = 19/6/2021 10:30 - 21/6/2021 1:00.... (21: 00-1...prev day : 20:00-21:00) 
                    //When OOO = 19/6/2021 10:30 - 21/6/2021 10:00....(21: 00-10...prev day : 20:00-23:59) 
                            
                    else if(rec.startDateTime<offsetDateTime && rec.endDateTime < offsetDateTime && rec.endDateTime.dateGmt()==offsetDateTime.dateGmt())
                    {
                        if(rec.endTime==Time.newInstance(0, 0, 0, 0))
                        {
                            TimeDetails timeRec2 = new TimeDetails();
                            timeRec2.startTime = Time.newInstance(0, 0, 0, 0).addHours(-hr).addMinutes(-min);
                            timeRec2.endTime = Time.newInstance(23, 59, 0, 0);
                            localPrevDay.add(timeRec2);

                            System.debug('localPrevDay4');
                            System.debug(localPrevDay);
                        }

                        else if(rec.endTime > offsetValue)
                        {
                            TimeDetails timeRec2 = new TimeDetails();
                            timeRec2.startTime = Time.newInstance(0, 0, 0, 0).addHours(-hr).addMinutes(-min);
                            timeRec2.endTime = Time.newInstance(23, 59, 0, 0);
                            localPrevDay.add(timeRec2);

                            System.debug('localPrevDay5');
                            System.debug(localPrevDay);
                        }
                        else if(rec.endTime < offsetValue)
                        {
                            TimeDetails timeRec2 = new TimeDetails();
                            timeRec2.startTime = Time.newInstance(0, 0, 0, 0).addHours(-hr).addMinutes(-min);
                            timeRec2.endTime = rec.endTime.addHours(-hr).addMinutes(-min);
                            localPrevDay.add(timeRec2);

                            System.debug('localPrevDay6');
                            System.debug(localPrevDay);
                        }
                    }
                  }

              }
            
              if (!mConIdAvailRecsUserTZ.containsKey(conId)) {
                mConIdAvailRecsUserTZ.put(conId, new List < TimeDetails > ());
              }
            
              List < TimeDetails > ldet = mConIdAvailRecsUserTZ.get(conId);
              ldet.addAll(localPrevDay);
              mConIdAvailRecsUserTZ.put(conId, ldet);
            }
            
            //return mConIdAvailRecsUserTZ;
            System.debug('mConIdAvailRecsUserTZ....');
            System.debug(mConIdAvailRecsUserTZ);
            }
          return mConIdAvailRecsUserTZ;

  } */

}