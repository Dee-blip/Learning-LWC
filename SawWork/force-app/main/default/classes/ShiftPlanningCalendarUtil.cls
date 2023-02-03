/*
 Utility class holding method used by Shift planning claendar controller
 @author sfdcdev11981
*/
public class ShiftPlanningCalendarUtil {
	
	public static final String MESSAGE_TYPE_ERROR = 'Error';
	public static final String MESSAGE_TYPE_WARNING = 'Warning';
	public static final String MESSAGE_TYPE_INFO = 'Info';
	
	public static String DEFAULT_HOLIDAY_COLOR = '#50EDCD';
	public static String DEFAULT_WEEKEND_COLOR = '#BBF2B3';
	public static String DEFAULT_CURRENT_DAY_COLOR = '#FCCFCF';
	
	/*
     The method will take date as input as return day of week i.e Sunday, Monday so on.
    */
    public static String getDayOfWeekName(Date d) {
        return Datetime.newInstance(d, Time.newInstance(0, 0, 0, 0)).format('EEEEE');
    }
    
    public static boolean isWeekendDate(Date d) {
    	String weekDay = Datetime.newInstance(d, Time.newInstance(0, 0, 0, 0)).format('EEEEE');
    	return (weekDay.equalsIgnoreCase('Saturday') || weekDay.equalsIgnoreCase('Sunday'));
    }
    
    public static String getMonthName(Date d) {
    	return Datetime.newInstance(d, Time.newInstance(0, 0, 0, 0)).format('MMMMM');
    }
    
    /*
    	Method to parse date string formate MM/DD/YYYY  to date.
    */
    public static Date parseDateMMDDYYYY(String dateStr) {
    	Date dt = null;
    	if(dateStr != null) {
    		List<String> dateList = dateStr.split('/');
    		dt = Date.newInstance(Integer.valueOf(dateList.get(2)), Integer.valueOf(dateList.get(0)), Integer.valueOf(dateList.get(1)));
    	}
    	return dt;
    }
    
    public static String getHolidayColor() { 
        String holidayColor = Shift_Planning_Calendar_Setting__c.getInstance().Name != null 
                            ? (String)Shift_Planning_Calendar_Setting__c.getInstance().get('Holiday_Color__c') 
                            : DEFAULT_HOLIDAY_COLOR;
                            
        return holidayColor != null ? holidayColor : DEFAULT_HOLIDAY_COLOR;
    }
    
    public static String getWeekendColor() { 
        String weekendColor = Shift_Planning_Calendar_Setting__c.getInstance().Name != null 
                            ? (String)Shift_Planning_Calendar_Setting__c.getInstance().get('Weekend_Day_Color__c') 
                            : DEFAULT_WEEKEND_COLOR;
                            
        return weekendColor != null ? weekendColor : DEFAULT_WEEKEND_COLOR;
    }
    
    public static String getCurrentDayColor() { 
        String currentDayColor = Shift_Planning_Calendar_Setting__c.getInstance().Name != null 
                            ? (String)Shift_Planning_Calendar_Setting__c.getInstance().get('Current_Day_Color__c') 
                            : DEFAULT_CURRENT_DAY_COLOR;
                            
        return currentDayColor != null ? currentDayColor : DEFAULT_CURRENT_DAY_COLOR;
    }
    
    
    public static Map<Date, List<Shift_Role_Assignment__c>> getShiftRoleAssignmentsByDate(String selectedDivision, String selectedShift, Date startDate, Date endDate) {
    	system.debug('<<<< selectedDivision : ' + selectedDivision + ' , selectedShift : ' + selectedShift + ' , startDate : ' + startDate + ' , endDate : ' + endDate);
    	String query  = 'Select Team_Role__c, Team_Role__r.Division__c, Team_Role__r.Days_Available__c, Shift__c, Name, Id, Date__c, Assigned_User__c,Team_Role__r.Name '
    				 	+' From Shift_Role_Assignment__c ';
    	
    	set<ID> userID = new set<ID>();
    	// get all the user for the selectd devision
    	for(Shift_Membership__c sm: [Select User__c, Id, Division__c From Shift_Membership__c where Division__c =: selectedDivision]){
    		userID.add(sm.User__c);
    	}
    	
    	system.debug('USER ID : ' + userID);
    	
    	//
    	List<String> whereClauseList = new List<String>();
    	if(!String.isBlank(selectedDivision)) {
    		whereClauseList.add('Team_Role__r.Division__c =: selectedDivision');
    	}	
    	if(!String.isBlank(selectedShift)) {
    		whereClauseList.add('Shift__c =: selectedShift');
    	}
    	if(startDate != null) {
    		whereClauseList.add('Date__c >=: startDate');
    	}
    	if(endDate != null) {
    		whereClauseList.add('Date__c <=: endDate');
    	}
    	// clause to show only the selected division assinged user assignment
    	if(userID.size() > 0){
    		whereClauseList.add('Assigned_User__c in: userID');
    	}
    	
    	if(!whereClauseList.isEmpty()) {
    		query += ' Where '+ String.join(whereClauseList, ' AND ');
    	}
    	
    	system.debug('<<<< Query : ' + query);
    	List<Shift_Role_Assignment__c> shiftRoleAssigns = Database.query(query);
    	
    	Map<Date, List<Shift_Role_Assignment__c>> assignsByDateMap = new Map<Date, List<Shift_Role_Assignment__c>>();
    	for(Shift_Role_Assignment__c roleAssign : shiftRoleAssigns) {
    		
    		List<Shift_Role_Assignment__c> assigList;
    		if(assignsByDateMap.containsKey(roleAssign.Date__c)) {
    			assigList = assignsByDateMap.get(roleAssign.Date__c);
    		}  else { 
    			assigList = new List<Shift_Role_Assignment__c>();
    			assignsByDateMap.put(roleAssign.Date__c, assigList);
    		}
    		assigList.add(roleAssign);
    	}
    	system.debug('<<<< assignsByDateMap : ' + assignsByDateMap);
    	return assignsByDateMap;
    }
    
    
    public static Map<String, List<Shift_Role_Assignment__c>> getShiftRoleAssignmentsByRole(String selectedDivision, String selectedShift, Date assignDate, Set<Id> availableRoles) {
    	
    	if(String.isBlank(selectedDivision) || String.isBlank(selectedShift) || assignDate == null) {
    		return null;
    	}
    	set<ID> userID = new set<ID>();
    	// get all the user for the selectd devision
    	for(Shift_Membership__c sm: [Select User__c, Id, Division__c From Shift_Membership__c where Division__c =: selectedDivision]){
    		userID.add(sm.User__c);
    	}
    	//
    	Map<String, List<Shift_Role_Assignment__c>> assignsByRoleMap = new Map<String, List<Shift_Role_Assignment__c>>();
    	
    	if(availableRoles != null && !availableRoles.isEmpty()) {
    		
	    	List<Shift_Role_Assignment__c> shiftRoleAssigns = [Select Team_Role__c, Team_Role__r.Division__c, Team_Role__r.Days_Available__c, 
	    												Shift__c, Name, Id, Date__c, Assigned_User__c, Assigned_User__r.Name From Shift_Role_Assignment__c
	    												where Team_Role__r.Division__c =: selectedDivision and 
	    												Shift__c =: selectedShift and Date__c = : assignDate and Team_Role__c IN: availableRoles and Assigned_User__c in:userID];
	    	
	    	
	    	for(Shift_Role_Assignment__c roleAssign : shiftRoleAssigns) {
	    		
	    		List<Shift_Role_Assignment__c> assigList;
	    		if(assignsByRoleMap.containsKey(roleAssign.Team_Role__c)) {
	    			assigList = assignsByRoleMap.get(roleAssign.Team_Role__c);
	    		}  else { 
	    			assigList = new List<Shift_Role_Assignment__c>();
	    			assignsByRoleMap.put(roleAssign.Team_Role__c, assigList);
	    		}
	    		assigList.add(roleAssign);
	    	}
    	}
    	return assignsByRoleMap;
    }
    
    public static List<Shift_Role_Assignment__c> getShiftRoleAssignmentsByDate(Date fromDate, String selectedShift, String selectedDivision) {
    	
    	if(String.isBlank(selectedDivision) || String.isBlank(selectedShift) || fromDate == null) {
    		return null;
    	}
    	set<ID> userID = new set<ID>();
    	// get all the user for the selectd devision
    	for(Shift_Membership__c sm: [Select User__c, Id, Division__c From Shift_Membership__c where Division__c =: selectedDivision]){
    		userID.add(sm.User__c);
    	}
    	//
    	List<Shift_Role_Assignment__c> shiftRoleAssigns = [Select Team_Role__c, Team_Role__r.Division__c, Team_Role__r.Days_Available__c, 
    												Shift__c, Name, Id, Date__c, Assigned_User__c, Assigned_User__r.Name From Shift_Role_Assignment__c
    												where Team_Role__r.Division__c =: selectedDivision and 
    												Shift__c =: selectedShift and Date__c = : fromDate and Assigned_User__c in:userID];
	    	
    	return shiftRoleAssigns;
    }
    
    public static Map<Date, Holiday__c> getHolidaysByDateRange(Date startDate, Date endDate) {
    	Map<Date, Holiday__c> holidayByDateMap = new Map<Date, Holiday__c>();
    	
		List<Holiday__c> holidays = [Select Id, Date__c, Region__c, Name From Holiday__c where Date__c >= : startDate AND Date__c <= : endDate];									 
		
		if(holidays != null ) {
			for(Holiday__c holiday : holidays) {
				if(holiday.Date__c != null) {
					holidayByDateMap.put(holiday.Date__c, holiday);
				}
			}	
		}
		return holidayByDateMap;					 
    } 
    
    public static List<User> getShiftUsers(String selectedShiftId, String Division) {
    	List<Shift_User_Junction__c> shiftUserJunctionList = [Select Id, User__c from Shift_User_Junction__c where Shift__c =: selectedShiftId];
    	
    	Set<String> userIdSet = new Set<String>();
    	for(Shift_User_Junction__c suj : shiftUserJunctionList) {
    		userIdSet.add(suj.User__c);
    	}
    	
    	List<Shift_Membership__c> divisionUserJunctionList = [Select Id, User__c from Shift_Membership__c where Division__c =: Division];
    	
    	Set<String> availableUserIdSet = new Set<String>();
    	for(Shift_Membership__c duj : divisionUserJunctionList) {
    		if(userIdSet.contains(duj.User__c)) {
    			availableUserIdSet.add(duj.User__c);
    		}
    	}
    	
    	List<User> shiftAndDivisionUsers = new List<User>();
    	if(!availableUserIdSet.isEmpty()) {
    		shiftAndDivisionUsers = [Select Id, Name from User where id IN : availableUserIdSet];
    	}
    	return shiftAndDivisionUsers;
    }
}