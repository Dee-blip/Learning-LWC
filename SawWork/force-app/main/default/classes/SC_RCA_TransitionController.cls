/*---------------------------------------------------------------------------------
Class name          :   SC_RCA_TransitionController
Test Class          :   SC_RCA_AllUseCase_TC
Author              :   Bhavesh
Created             :   05-Dec-21
JIRA                :   ESESP-3590

Last Modified         Developer                           Purpose            
============= ========================         			  ==========
5-Dec-20201             Bhavesh                         Initial Version
* --------------------------------------------------------------------------------*/
public with sharing class SC_RCA_TransitionController {
    public SC_RCA_TransitionController() {

    }
    // Method for getting Current Shift
    @AuraEnabled(cacheable=true)
    public static transitionWrapper getCurrentShiftDetails(String caseId){
        String currentShift =  SC_SI_TransitionHelper.getCurrentShiftDetails('Incident Management');
        Case cs = [Select Id, Status, OwnerId FROM Case WHERE Id =: caseId];
        User usr = [Select Id, SC_SI_IRAPT_User__c FROM User WHERE Id =: UserInfo.getUserId()];
        transitionWrapper wrpr = new transitionWrapper (currentShift, cs.Status, usr.SC_SI_IRAPT_User__c, cs.OwnerId);
        return wrpr;
    }
    public class transitionWrapper {
        @AuraEnabled
        public String currentShift;
        @AuraEnabled
        public String caseStatus;
        @AuraEnabled
        public Boolean isIrapt;
        @AuraEnabled
        public Id caseOwner;
        transitionWrapper (String currentShift, String caseStatus, Boolean isIrapt, Id caseOwner) {
            this.currentShift = currentShift;
            this.caseStatus = caseStatus;
            this.isIrapt = isIrapt;
            this.caseOwner = caseOwner;
        }
    }


    // Method to get wakeuptime based on target shift opted
    @AuraEnabled(cacheable=true)
    public static String wakeUpTimeMethod(String targetShiftTime)
    {
        String wakeUpTime = '';
        wakeUpTime = (targetShiftTime.equalsIgnoreCase('transition now')) ? String.valueOf(System.now().format()) : 
        String.ValueOf(getShiftDateTime(targetShiftTime).format()) ;
        
        return wakeUpTime;
        
    }

    @AuraEnabled
    public static void createTransitionRecord (String caseId, String nextShift, String wakeupTime, String caseOwner, String notes) {
        try{

            Id targetQueueId = (nextShift == 'Transition Now') ?
                                             [select Id from Group where Name = 'SERVICE_INCIDENTS_QUEUE' and Type = 'Queue'].Id : 
                                         [select Id from Group where Name = 'ATS_IRAPT_TRANSITION_QUEUE' and Type = 'Queue'].Id;
            Id rcaRT = Schema.SObjectType.Case_Transition__c.getRecordTypeInfosByName().get('RCA').getRecordTypeId();
            Case_Transition__c ct = new Case_Transition__c();
            ct.RecordTypeId = rcaRT;
            ct.Case__c = caseId;
            ct.Previous_Owner__c = caseOwner;
            ct.Future_Trigger_Time__c = Datetime.parse(wakeupTime);
            ct.Target_Shift__c = nextShift;
            ct.Notes__c = notes;
            /*ct.New_Owner__c = (nextShift == 'Transition Now') ?
                                             [select Id from Group where Name = 'SERVICE_INCIDENTS_QUEUE' and Type = 'Queue'].Id : 
                                         [select Id from Group where Name = 'ATS_IRAPT_TRANSITION_QUEUE' and Type = 'Queue'].Id;*/
            

            Case cs = new Case (Id = caseId, OwnerId = targetQueueId, Status = 'Unassigned');
            if (nextShift == 'Transition Now'){
                cs.Case_Assignment_Using_Active_Rules__c = false;
                cs.has_active_transition__c = true;
                cs.Transitioned__c = true;

                ct.Start_Date__c = system.now();
                ct.Future_Trigger_Time__c = system.now();
                ct.completed__c = true;
                ct.completed_Date__c = Date.Today();
            } else {
                cs.Case_Assignment_Using_Active_Rules__c = false;
                cs.has_active_transition__c = false;
                cs.Transitioned__c = true;
                cs.Case_In_Transition_Queue__c = true;
                ct.Start_Date__c = system.now();
                ct.completed__c = false;
                ct.completed_Date__c = null;
            }
            insert ct;
            update cs;
            
        }
        catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }

    }

    public static DateTime getShiftDateTime(String shiftName){
        boolean isUSA_DST_On = isUSADayLightSavingsOn();
        Decimal result;
        
        Map<string,decimal> hourShiftMap = new Map<string,decimal>();
        hourShiftMap = getRegularShiftTimes();
        hourShiftMap.put('WKND',13);

        DateTime currentDateTime = (DateTime) datetime.now();
        decimal currentHour = currentDateTime.hourGmt();
        currentHour = currentHour + currentDateTime.minuteGmt()/60;
        String dayOfWeek = currentDateTime.formatGmt('EEEE');
        decimal shiftTime = hourShiftMap.get(shiftName);
        Integer minutes = 0;
        String stringReprentationOfDecimal= String.valueOf(shiftTime);
        Datetime myDate;
        if (stringReprentationOfDecimal != NULL && stringReprentationOfDecimal.indexOf('.') > -1){
            String decimalValueAfterDot = stringReprentationOfDecimal.substring(stringReprentationOfDecimal.indexOf('.'),stringReprentationOfDecimal.length());
            decimal minutsDecimal = decimal.valueof(decimalValueAfterDot)*60;
            minutes = minutsDecimal.intValue();
        }
            
            if (shiftTime > currentHour){
                //target date is greater than current date. return todays date only
                Datetime d =  datetime.now();
                //shift time might have minutes. so set minutes also
                myDate = Datetime.newInstanceGMT(d.yearGMT(), d.monthGMT(), d.dayGMT(), shiftTime.intValue(), minutes, 0);
                //return myDate;
                
            }
            else {
                //looks like shift was over. tomo shift details
                Datetime d =  datetime.now();
                d = d.addDays(1);
                myDate = Datetime.newInstanceGMT(d.yearGMT(), d.monthGMT(), d.dayGMT(), shiftTime.intValue(), minutes, 0);
                //return myDate;
            }
            //Changes done by Vamsee - This is to skip the week ends
            String targetDay = myDate.formatGmt('EEEE');
            if(targetDay == 'Saturday'){
                myDate = myDate.addDays(2);
            }
            else if(targetDay == 'Sunday'){
                myDate = myDate.addDays(1);
            }
            
      
    return myDate;
        
    }

    // Method  : This method check whether USA DST is on
    public static boolean isUSADayLightSavingsOn(){
        TimeZone tz = TimeZone.getTimeZone('America/New_York');
        DateTime d = datetime.now();
        return tz.getOffset(d) != -18000000; //GMT -5 Hours
    } 
    
  
    
    // Method  : This method check whether EMEA DST is on
    public static boolean isEMEADayLightSavingsOn(){
        TimeZone tz = TimeZone.getTimeZone('Europe/Amsterdam');
        DateTime d = datetime.now();
        return tz.getOffset(d) != 3600000; // GMT +1 Hour
    }  

    public static map<String,decimal> getRegularShiftTimes(){
        Map<string,decimal> hourShiftMap = new Map<string,decimal>{'APJ'=>1.5};
        boolean isUSA_DST_On = isUSADayLightSavingsOn();
        boolean isEMEA_DST_On = isEMEADayLightSavingsOn();
        Decimal result;
        
        result = isUSA_DST_On ? hourShiftMap.put('US EAST',12.5) : hourShiftMap.put('US EAST',13.5);
		result = isUSA_DST_On ? hourShiftMap.put('US WEST',17) : hourShiftMap.put('US WEST',18);
		
		//EMEA DST Check
		result = isEMEA_DST_On ? hourShiftMap.put('EMEA',7) : hourShiftMap.put('EMEA',8);
        return hourShiftMap;
    }
}