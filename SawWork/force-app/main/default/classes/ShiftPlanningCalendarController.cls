/*
    Controller classing holding shift planning calendar logic.
    @author sfdcdev11981
*/
public class ShiftPlanningCalendarController {
    
    public List<List<DayOfWeek>> days {get;set;}

    public String monthname {get;set;}
    public String selectedDayRolePopupHeaderLabel {get; private set;}
    
    public Date monthStartDate {get; private set;}
    
    public List<Selectoption> shiftOptions {get;set;}
    public String selectedShift {get;set;}
    
    public List<Selectoption> divisionOptions {get;set;}
    public String selectedDivision {get;set;}
    
    public String selectedShiftName {get; private set;}
    public String selectedDivisionName {get; private set;}
    
    public String selectedDay {get; set;}
    
    public List<DivisionRoleWrapper> divisionRoleWrapperList {get;set;}
    public boolean hasDivisionRoleWrappers { get{return divisionRoleWrapperList != null && !divisionRoleWrapperList.isEmpty(); } private set;}
    public List<MessageWrapper> pageMessages {get;set;}
    
    public String fromDateParam {get; set;}
    public String startDateParam {get; set;}
    public String endDateParam {get; set;}
    public String includeWeekendParam {get; set;}
    
    public String currentDateStr {get; private set;}
    
    //Boolean variable to show hide copy tool and make multiselect lists readonly : Pitamber Sharma(Appirio Offshore) T-159454
    public Boolean isEditable{get;set;}
    
    public ShiftPlanningCalendarController() {
        pageMessages = new List<MessageWrapper>();
        monthStartDate = system.today().toStartOfMonth();
        // Date format MM/DD/YYYY
        currentDateStr = system.today().month()+'/'+ system.today().day() +'/'+ system.today().year();
        shiftOptions = getShiftOptions();
        divisionOptions = getDivisionOptions();
        getPrintCalendar();
        
        //Set Boolean variable as per the profile names.
        for(Profile currentUserProfile : [Select Name From Profile Where Id =: UserInfo.getProfileId()]){
            for(Shift_Planning_Editor_Profile_Names__c speProfile : Shift_Planning_Editor_Profile_Names__c.getAll().values()) {
                if(currentUserProfile.Name == speProfile.Value__c){
                    isEditable = true;
                    break;
                }
            }
         }
       
    }
    public String holidayColor {get { return ShiftPlanningCalendarUtil.getHolidayColor(); } private set;}
    public String weekendColor {get { return ShiftPlanningCalendarUtil.getWeekendColor(); } private set;}
    public String currentDayColor {get { return ShiftPlanningCalendarUtil.getCurrentDayColor(); } private set;}
    
    //All initial logic goes here
    public void getPrintCalendar() {
        DayOfWeek defaultDow = new DayOfWeek();
        days = new list<list<DayOfWeek>>();
        days.add(new list<DayOfWeek>{defaultDow,defaultDow,defaultDow,defaultDow,defaultDow,defaultDow,defaultDow});
        days.add(new list<DayOfWeek>{defaultDow,defaultDow,defaultDow,defaultDow,defaultDow,defaultDow,defaultDow});
        days.add(new list<DayOfWeek>{defaultDow,defaultDow,defaultDow,defaultDow,defaultDow,defaultDow,defaultDow});
        days.add(new list<DayOfWeek>{defaultDow,defaultDow,defaultDow,defaultDow,defaultDow,defaultDow,defaultDow});
        days.add(new list<DayOfWeek>{defaultDow,defaultDow,defaultDow,defaultDow,defaultDow,defaultDow,defaultDow});
        days.add(new list<DayOfWeek>{defaultDow,defaultDow,defaultDow,defaultDow,defaultDow,defaultDow,defaultDow});
        
        monthname = ShiftPlanningCalendarUtil.getMonthName(monthStartDate) + ' ' + monthStartDate.year();
        Date weekStart = monthStartDate.toStartofWeek();
        Integer dayOfWeek = weekStart.daysBetween(monthStartDate);
        integer row = 0;
        
        if(dayOfWeek == 0){
            dayOfWeek = 0;
        }else{
            dayOfWeek = dayOfWeek;
        }
        
        
        Date endOfMonth = Date.newInstance(monthStartDate.year(), monthStartDate.month()+1, 01).addDays(-1);
        set<integer> hds = new set<integer>();
       
        Map<Date, Holiday__c> holidayByDateMap = ShiftPlanningCalendarUtil.getHolidaysByDateRange(monthStartDate, endOfMonth);
        
        Map<Date, List<Shift_Role_Assignment__c>> shiftRoleAssignmentByDate = ShiftPlanningCalendarUtil.getShiftRoleAssignmentsByDate(selectedDivision, selectedShift, monthStartDate, endOfMonth);
        
        //filling dates
        for(integer i=1;i<=Date.daysInMonth(monthStartDate.year(), monthStartDate.month()); i++){
            system.debug('row ' + row + ' - col - ' + dayOfWeek);
            if(days[row][dayOfWeek].day < 0) {
                days[row][dayOfWeek] = new DayOfWeek(monthStartDate.addDays(-1 * (i - 1)), null, false);
            } else {
                Date dt = monthStartDate.addDays((i - 1));
                days[row][dayOfWeek] = new DayOfWeek(dt, shiftRoleAssignmentByDate.get(dt), holidayByDateMap.containsKey(dt));
            }
            dayOfWeek++;
            if(dayOfWeek > 6){
                row++;
                dayOfWeek = 0;
            }
        }
    } 
    
    public void previousMonth() {
        resetPageMessage();
        monthStartDate = monthStartDate.addMonths(-1);
        getPrintCalendar();
    }  
    
    public void nextMonth() {
        resetPageMessage();
        monthStartDate = monthStartDate.addMonths(1);
        getPrintCalendar();
    }
    
    public void reloadCalendar() {
        resetPageMessage();
        getPrintCalendar();
    }
    
    public List<Selectoption> getShiftOptions() {
        List<Shift__c> shifts = [Select Name, Id from Shift__c order by Name limit 1000];
        List<Selectoption> options = new List<Selectoption>();
        
        options.add(new Selectoption('', '--None--'));
        for(Shift__c s : shifts) {
            options.add(new Selectoption(s.Id, s.Name));
        }
        return options;
    }
    
    public List<Selectoption> getDivisionOptions() {
        List<Division__c> divisions = [Select Name, Id from Division__c order by Name limit 1000];
        List<Selectoption> options = new List<Selectoption>();
        
        options.add(new Selectoption('', '--None--'));
        for(Division__c div : divisions) {
            options.add(new Selectoption(div.Id, div.Name));
        }
        return options;
    }
    
    
    public void showRoleData() {
        resetPageMessage();
        
        if(String.isBlank(selectedDivision) || String.isBlank(selectedShift)  ) {
            pageMessages.add(new MessageWrapper(ShiftPlanningCalendarUtil.MESSAGE_TYPE_ERROR, 'Select a valid shift and division and try again.'));
            return;
        }
        
        if(selectedDay == null ) {
            pageMessages.add(new MessageWrapper(ShiftPlanningCalendarUtil.MESSAGE_TYPE_ERROR, 'Please select/click on a day for editing.'));
            return;
        }
        
        Integer intDay = Integer.valueOf(selectedDay);
        Date selectedDate = Date.newInstance(monthStartDate.year(), monthStartDate.month(), intDay);
        
        String selectedWeekDay = ShiftPlanningCalendarUtil.getDayOfWeekName(selectedDate);
        
        selectedDayRolePopupHeaderLabel = ShiftPlanningCalendarUtil.getMonthName(selectedDate) + ' '+  intDay +', ' + selectedDate.year() +' - '+ selectedWeekDay;
        
        List<Holiday__c> holidays = [Select Id, Date__c, Region__c, Name From Holiday__c where Date__c = : selectedDate];
        if(!holidays.isEmpty()) {
            if(divisionRoleWrapperList == null) {
                divisionRoleWrapperList = new List<DivisionRoleWrapper>();
            }
            divisionRoleWrapperList.clear();
            pageMessages.add(new MessageWrapper(ShiftPlanningCalendarUtil.MESSAGE_TYPE_INFO, 'It is holiday for selected date:'+ selectedDate.format()));
            pageMessages.add(new MessageWrapper(ShiftPlanningCalendarUtil.MESSAGE_TYPE_INFO, 'Holiday: '+ holidays.get(0).Name +'   Region: '+ holidays.get(0).Region__c));
            return;
        }
        
        Map<Id, Division_Role__c> availableRolesMap = new Map<Id, Division_Role__c>([Select Name, Id, Division__c, Days_Available__c from Division_Role__c where Division__c =: selectedDivision and 
                            Days_Available__c includes (:selectedWeekDay) order by Name limit 1000]);
        
        Map<String, List<Shift_Role_Assignment__c>> assignsByRoleMap = ShiftPlanningCalendarUtil.getShiftRoleAssignmentsByRole(selectedDivision, selectedShift, selectedDate, availableRolesMap.keySet());
        
        List<User> shiftUsers = ShiftPlanningCalendarUtil.getShiftUsers(selectedShift, selectedDivision);
        
        divisionRoleWrapperList = new List<DivisionRoleWrapper>();
        for(Division_Role__c divRole : availableRolesMap.values()) {
            divisionRoleWrapperList.add( new DivisionRoleWrapper(divRole, assignsByRoleMap.get(divRole.Id), shiftUsers));
        }
        
        if(divisionRoleWrapperList.isEmpty()) {
            pageMessages.add(new MessageWrapper(ShiftPlanningCalendarUtil.MESSAGE_TYPE_INFO, 'No division role available for selected day.'));
        }                   
                                
    }
    
    public void showCopyTool() {
        resetPageMessage();
        
        selectedDivisionName = null;
        selectedShiftName= null;
        
        if(String.isBlank(selectedDivision) || String.isBlank(selectedShift)  ) {
            pageMessages.add(new MessageWrapper(ShiftPlanningCalendarUtil.MESSAGE_TYPE_ERROR, 'Select a valid shift and division and try again.'));
            return;
        }
        
        List<Shift__c> shifts = [Select Name from Shift__c where id=: selectedShift];
        if(!shifts.isEmpty()) selectedShiftName = shifts.get(0).Name;
        
        List<Division__c> divisions = [Select Name from Division__c where id=: selectedDivision];
        if(!divisions.isEmpty()) selectedDivisionName = divisions.get(0).Name;
    }
    
    /*
        Method for handling inserting and deletion of shift role assignments as per selection done 
        by user on UI. 
    */
    public void saveShiftRoleAssignmentChanges() {
        resetPageMessage();
        try {
            if(!divisionRoleWrapperList.isEmpty()) {
                Integer intDay = Integer.valueOf(selectedDay);
                Date selectedDate = Date.newInstance(monthStartDate.year(), monthStartDate.month(), intDay);
                
                List<Shift_Role_Assignment__c> shiftRoleAssignmentToInsert = new List<Shift_Role_Assignment__c>();
                for(DivisionRoleWrapper drWrapper : divisionRoleWrapperList) {
                    for(Selectoption option : drWrapper.roleAssignmentsOptions) {
                        // If there is no '-' separation available in the option value than that 
                        // option will be consider as new user assign entry and option value denotes 
                        // user id. 
                        String val = option.getValue();
                        if(val != null && val.indexOf('-') == -1) {
                            shiftRoleAssignmentToInsert.add(new Shift_Role_Assignment__c(Name = option.getLabel() +' - Assignment', Team_Role__c = drWrapper.divisionRole.Id, 
                                    Shift__c = selectedShift, Date__c = selectedDate, Assigned_User__c = val.trim()));
                        }
                    }
                }
                
                List<String> shiftRoleAssignmentToDeleteIds = new List<String>();
                for(DivisionRoleWrapper drWrapper : divisionRoleWrapperList) {
                    for(Selectoption option : drWrapper.availableShiftUserOptions) {
                        // If there is '-' separation available in the above option value than that 
                        // option will be consider unassigned shift role assignment user entry to be deleted.
                        // Option value contains both user id and shift assignment id separated by '-' 
                        // Format : UserId-ShiftAssignmentId 
                        String val = option.getValue();
                        if(val != null && val.indexOf('-') != -1) {
                            system.debug('@@@ Val : ' + val);
                            List<String> IdList = val.split('-');
                            // zero index will be user id and 1 index will be shift assignment id.
                            shiftRoleAssignmentToDeleteIds.add(IdList.get(1));
                        }
                    }
                }
                
                if(!shiftRoleAssignmentToInsert.isEmpty()) {
                    system.debug('@@@ shiftRoleAssignmentToInsert' + shiftRoleAssignmentToInsert);
                    insert shiftRoleAssignmentToInsert;
                    system.debug('<<<< shiftRoleAssignmentToInsert' + shiftRoleAssignmentToInsert);
                }
                
                if(!shiftRoleAssignmentToDeleteIds.isEmpty()) {
                    delete [select id from Shift_Role_Assignment__c where id IN: shiftRoleAssignmentToDeleteIds];
                }
                getPrintCalendar();
            }
        } catch(Exception e) {
            pageMessages.add(new MessageWrapper(ShiftPlanningCalendarUtil.MESSAGE_TYPE_ERROR, 'Exception while editing shift role assignments. Error: '+ e.getMessage()));
            System.debug('Exception while editing shift role assignments. Error: '+ e.getMessage());
        }
    }
    
    /*
        Method for copyed the Shift role assignments from the selected from date and copying to the 
        selected date range. 
    */
    public void copyAssignments() {
        resetPageMessage();
        try {
            Date fromDate = ShiftPlanningCalendarUtil.parseDateMMDDYYYY(fromDateParam);
            Date startDate = ShiftPlanningCalendarUtil.parseDateMMDDYYYY(startDateParam);
            Date endDate = ShiftPlanningCalendarUtil.parseDateMMDDYYYY(endDateParam);
            boolean incudeWeekend = includeWeekendParam != null ? (includeWeekendParam.equalsIgnoreCase('true') ? true : false)  : false;
            //public String includeWeekendParam {get; set;}
            
            if(startDate > endDate) {
                pageMessages.add(new MessageWrapper(ShiftPlanningCalendarUtil.MESSAGE_TYPE_ERROR, 'The start date must be before the end date.'+ startDate));
                return;
            }
            
            List<Shift_Role_Assignment__c> shiftRoleAssigns = ShiftPlanningCalendarUtil.getShiftRoleAssignmentsByDate(fromDate, selectedShift, selectedDivision);
            
            Date tempDate = startDate;
            List<Shift_Role_Assignment__c> clonedAssignmentToInsert = new List<Shift_Role_Assignment__c>();
            while(tempDate <= endDate) {
                // If incudeWeekend false and temp date day is week end then escape and process next date.
                if(!incudeWeekend && ShiftPlanningCalendarUtil.isWeekendDate(tempDate)) {
                    tempDate = tempDate.addDays(1);
                    continue;
                }
                
                for(Shift_Role_Assignment__c assign : shiftRoleAssigns) {
                    Shift_Role_Assignment__c cloneAssign = assign.clone(false,true);
                    cloneAssign.date__c = tempDate;
                    clonedAssignmentToInsert.add(cloneAssign);
                }
                tempDate = tempDate.addDays(1);
            }
            insert clonedAssignmentToInsert;
            getPrintCalendar();
        } catch(Exception e) {
            pageMessages.add(new MessageWrapper(ShiftPlanningCalendarUtil.MESSAGE_TYPE_ERROR, 'Exception while copying shift role assignments over selected date range. Error: '+ e.getMessage()));
            System.debug('Exception while editing shift role assignments. Error: '+ e.getMessage());
        }
    }

    /*
        Method for resetting the page message instance
        to clear any existing messages.
    */
    public void resetPageMessage() {
        pageMessages = new List<MessageWrapper>();
    }
    
    /*
        Inner class for wrapping division role and related assignment details.
    */
    public class DivisionRoleWrapper {
        public Division_Role__c divisionRole {get;set;} 
        public List<Shift_Role_Assignment__c> roleAssignments {get;set;} 
        
        public List<Selectoption> roleAssignmentsOptions {get;set;}
        public List<Selectoption> availableShiftUserOptions {get;set;}
        
        private List<User> shiftUsers;
        
        public DivisionRoleWrapper(Division_Role__c divRole, List<Shift_Role_Assignment__c> roleAssignments, List<User> shiftUsers) {
            this.divisionRole = divRole;
            this.roleAssignments = roleAssignments == null ? new List<Shift_Role_Assignment__c>() : roleAssignments;
            this.shiftUsers = shiftUsers;
            
            prepareRoleAssignmentsOptions();
            prepareAvailableShiftUserOptions();
        }
        
        public void prepareRoleAssignmentsOptions() {
            roleAssignmentsOptions = new List<Selectoption>();
            for(Shift_Role_Assignment__c assign : roleAssignments) {
                roleAssignmentsOptions.add(new Selectoption(assign.Assigned_User__c +'-'+ assign.Id, assign.Assigned_User__r.Name));
            }
        }
        
        public void prepareAvailableShiftUserOptions() {
            availableShiftUserOptions = new List<Selectoption>();
            for(User u : shiftUsers) {
                boolean found = false;
                for(Shift_Role_Assignment__c sra : roleAssignments) {
                    if(u.id == sra.Assigned_User__c) {
                        found = true;
                    }
                }
                if(!found) availableShiftUserOptions.add(new Selectoption(u.id, u.Name));
            }
        }
    }
    
    /*
        Wrapper classing for holding message details and showing on UI 
    */
    public class MessageWrapper {
        public String message {get;set;}
        //public String messageType {get;set;}
        public boolean isError {get; private set;}
        public boolean isWarning {get; private set;}
        public boolean isInfo {get; private set;}
        
        public MessageWrapper(String msgType, String msg) {
            //his.messageType = msgType;
            this.message = msg;
            this.isError = (msgType != null && ShiftPlanningCalendarUtil.MESSAGE_TYPE_ERROR == msgType) ? true : false;
            this.isWarning = (msgType != null && ShiftPlanningCalendarUtil.MESSAGE_TYPE_WARNING == msgType) ? true : false;
            this.isInfo = (msgType != null && ShiftPlanningCalendarUtil.MESSAGE_TYPE_INFO == msgType) ? true : false;
        }
    }
    
    /*
        Inner wrapper class for wrapping day details.
    */
    public class DayOfWeek {
        public Integer day {get; set;}
        private Date dayDate;
        
        public boolean isCurrentDay {get; private set;}
        public List<Shift_Role_Assignment__c> shiftRoleAssigns {get;set;}
        public List<Shift_Role_Assignment__c> limitedShiftRoleAssigns {get;set;}
        public boolean isHoliday {get; private set;}
        public Integer showMoreCount {get; private set;}
        public boolean hasMore {get; private set;}
        
        //
        public map<id,string> mapRoleWithAssignedMember{get; set;}
        
        public DayOfWeek(Date d, List<Shift_Role_Assignment__c> assignments, boolean isHoliday) {
            this.day = d.day();
            this.dayDate = d;
            this.isHoliday = isHoliday;
            this.shiftRoleAssigns = assignments == null ? new List<Shift_Role_Assignment__c>() : assignments;
            this.isCurrentDay = (system.today() == dayDate);
            this.hasMore = false;
            handleShiftAssignment();
            
            this.mapRoleWithAssignedMember = new map<id,string> ();
             CountMemberOfTheRol();
        }
        public void CountMemberOfTheRol(){
            map<id,integer> mapRoleWithAssignedMemberValue = new map<id,integer> ();
            integer memberCount = 0;
            map<ID, string> mapRoleIDWithName = new map<ID,string>();
            system.debug('::shiftRoleAssigns::'+shiftRoleAssigns);
            for(Shift_Role_Assignment__c sAssignemnt : shiftRoleAssigns){
                system.debug(':: sAssignemnt.Team_Role__c::'+sAssignemnt.Team_Role__c);
                if(mapRoleWithAssignedMemberValue.containsKey(sAssignemnt.Team_Role__c)){
                    memberCount = mapRoleWithAssignedMemberValue.get(sAssignemnt.Team_Role__c)+1;
                    mapRoleWithAssignedMemberValue.put(sAssignemnt.Team_Role__c,memberCount);
                }else{
                    mapRoleWithAssignedMemberValue.put(sAssignemnt.Team_Role__c,1);
                }
                system.debug('roleID::::'+sAssignemnt.ID+'::::sAssignemnt.Team_Role__r.Name:::::'+sAssignemnt.Team_Role__r.Name);
                mapRoleIDWithName.put(sAssignemnt.Team_Role__c,sAssignemnt.Team_Role__r.Name);
            }
            system.debug(':: mapRoleWithAssignedMemberValue.keySet() ::'+mapRoleWithAssignedMemberValue.keySet());
            for(ID roleID:mapRoleWithAssignedMemberValue.keySet()){
                string strRoleName = mapRoleIDWithName.get(roleID);
                system.debug('roleID::::'+roleID+':::sAssignemnt.Team_Role__r.Name:::::'+strRoleName);
                strRoleName += ' :'+ string.valueOf(mapRoleWithAssignedMemberValue.get(roleID));
                mapRoleWithAssignedMember.put(roleID,strRoleName);
            }
        }
        
        public void handleShiftAssignment() {
            limitedShiftRoleAssigns = new List<Shift_Role_Assignment__c>();
            if(shiftRoleAssigns.size() > 3 ) {
                showMoreCount = shiftRoleAssigns.size() - 3;
                hasMore = true;
                limitedShiftRoleAssigns.add(shiftRoleAssigns.get(0));
                limitedShiftRoleAssigns.add(shiftRoleAssigns.get(1));
                limitedShiftRoleAssigns.add(shiftRoleAssigns.get(2));
            } else {
                limitedShiftRoleAssigns = shiftRoleAssigns;
            }
        }
        
        public DayOfWeek() {
            this.day = 0;
            this.isHoliday = false;
            this.isCurrentDay = (system.today() == dayDate);
            this.hasMore = false;
        }
        
        public String getStyleClass() {
            String styleClass = '';
            
            if(this.day == 0) {
                styleClass = 'showGray';
            } 
            if(this.isHoliday) {
                styleClass = 'holiday';
            }
            
            if(dayDate != null && ShiftPlanningCalendarUtil.isWeekendDate(dayDate)) {
                styleClass = 'weekend';
            }
            
            if(isCurrentDay) {
                styleClass = 'currentDay';
            }
            return styleClass;
        }
        
        public boolean getShowData() {
            return day == 0 ? false : true;
        }
    }
}