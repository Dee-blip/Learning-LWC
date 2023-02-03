/**
 */
@isTest
private class ShiftPlanningCalendarControllerTest {
    static Division__c div1;
    static Shift__c shift1, shift2;
    static Date CURRENT_DATE = Date.Today(); // Day Friday
    
    static User getMockedUser() {
        Profile p = [SELECT Id FROM Profile WHERE Name='Standard User']; 
        User user = new User(Alias = 'standt', Email='standarduser@testorg.com', 
        EmailEncodingKey='UTF-8', LastName='Testing171', LanguageLocaleKey='en_US', 
        LocaleSidKey='en_US', ProfileId = p.Id, 
        TimeZoneSidKey='America/Los_Angeles', UserName='sfdc11981user@gmail.com');
        return user;
    }
    
    static void testData() {
        
        //div1 = new Division__c(Name = 'Test devision101', User__c = Userinfo.getUserId());
        div1 = new Division__c(Name = 'Test devision101');
        insert div1;
        
        
        shift1 = new Shift__c(Name = 'Test Morning Shift', Start_Time__c = '10:00 AM', End_Time__c = '12:30 PM');
        shift2 = new Shift__c(Name = 'Test Evening Shift', Start_Time__c = '02:00 PM', End_Time__c = '05:00 PM');
        insert new List<Shift__c> {shift1, shift2};
        
        Division_Role__c divisionRole1 = new Division_Role__c(Name = 'Division Role 01', Days_Available__c = 'Monday; Tuesday; Wednesday; Thursday; Friday', Division__c = div1.Id);
        Division_Role__c divisionRole2 = new Division_Role__c(Name = 'Division Role 02', Days_Available__c = 'Monday; Tuesday; Wednesday;', Division__c = div1.Id);
        Division_Role__c divisionRole3 = new Division_Role__c(Name = 'Division Role 03', Days_Available__c = 'Saturday; Sunday; Monday;', Division__c = div1.Id);
        insert new List<Division_Role__c>{divisionRole1, divisionRole2, divisionRole3};
        
        Shift_Role_Assignment__c assign1 = new Shift_Role_Assignment__c(Name = 'Test Shift Assign1', Shift__c = shift1.Id, Date__c = CURRENT_DATE,
             Assigned_User__c = Userinfo.getUserId(), Team_Role__c = divisionRole1.Id);
        Shift_Role_Assignment__c assign2 = new Shift_Role_Assignment__c(Name = 'Test Shift Assign1', Shift__c = shift1.Id, Date__c = CURRENT_DATE,
             Assigned_User__c = Userinfo.getUserId(), Team_Role__c = divisionRole1.Id);
        Shift_Role_Assignment__c assign3 = new Shift_Role_Assignment__c(Name = 'Test Shift Assign1', Shift__c = shift2.Id, Date__c = CURRENT_DATE,
             Assigned_User__c = Userinfo.getUserId(), Team_Role__c = divisionRole2.Id);
        Shift_Role_Assignment__c assign4 = new Shift_Role_Assignment__c(Name = 'Test Shift Assign1', Shift__c = shift1.Id, Date__c = CURRENT_DATE,
             Assigned_User__c = Userinfo.getUserId(), Team_Role__c = divisionRole3.Id);
        
        insert new List<Shift_Role_Assignment__c>{assign1, assign2, assign3, assign4};
        
        Holiday__c holiday1 = new Holiday__c(Date__c = CURRENT_DATE.addDays(-1), Region__c = 'test Holiday region', Name = 'Test holiday1');
        Holiday__c holiday2 = new Holiday__c(Date__c = CURRENT_DATE.addDays(2), Region__c = 'test Holiday region', Name = 'Test holiday1');
        insert new List<Holiday__c> {holiday1, holiday2};
        
        User user = getMockedUser();
        
        Shift_User_Junction__c junction1 = new Shift_User_Junction__c(Shift__c = shift1.Id, User__c = Userinfo.getUserId() );
        Shift_User_Junction__c junction2 = new Shift_User_Junction__c(Shift__c = shift2.Id, User__c = Userinfo.getUserId() );
        Shift_User_Junction__c junction3 = new Shift_User_Junction__c(Shift__c = shift1.Id, User__c = user.Id);
        insert new List<Shift_User_Junction__c> {junction1, junction2, junction3};
    }
    
    
    /*
        Main test class
    */
    static testMethod void ShiftPlanningCalendarMainTest() {
        
        
        Test.startTest();
        testData();
        Test.setCurrentPage(Page.ShiftPlanningCalendar);
        
        ShiftPlanningCalendarController controller = new ShiftPlanningCalendarController();
        
        system.assert(controller.pageMessages != null);
        String expectedDateStr = CURRENT_DATE.month()+'/'+ CURRENT_DATE.day() +'/'+ CURRENT_DATE.year();
        system.assertEquals(expectedDateStr, controller.currentDateStr);
        
        String expectedMonthLabel = ShiftPlanningCalendarUtil.getMonthName(CURRENT_DATE) + ' ' + CURRENT_DATE.year();
        system.assertEquals(expectedMonthLabel, controller.monthname);
        
        system.assertEquals(3, controller.shiftOptions.size());
        system.assertEquals(2, controller.divisionOptions.size());
        
        List<List<ShiftPlanningCalendarController.DayOfWeek>> days  = controller.days;
        system.assert(!days.isEmpty());
       
        for(List<ShiftPlanningCalendarController.DayOfWeek> daysOfWeek : days) {
            for(ShiftPlanningCalendarController.DayOfWeek dayOfWeek : daysOfWeek) {
                if(dayOfWeek.day == CURRENT_DATE.day()) {
                    system.assertEquals('currentDay', dayOfWeek.getStyleClass());
                    
                    system.assertEquals(true, dayOfWeek.getShowData());
                    
                    system.assertEquals(4, dayOfWeek.shiftRoleAssigns.size());
                }
            }
        }
     
        Test.stopTest();       
    }
    
    /*
        Testing previousMonth method.
    */
    static testMethod void previousMonthTest() {
        
        
        Date previousMonthDate = CURRENT_DATE.addMonths(-1);
        
        Test.startTest();
        testData();
        Test.setCurrentPage(Page.ShiftPlanningCalendar);
        
        ShiftPlanningCalendarController controller = new ShiftPlanningCalendarController();
        
        system.assert(controller.pageMessages != null);
        String expectedDateStr = CURRENT_DATE.month()+'/'+ CURRENT_DATE.day() +'/'+ CURRENT_DATE.year();
        system.assertEquals(expectedDateStr, controller.currentDateStr);
        
        String expectedMonthLabel = ShiftPlanningCalendarUtil.getMonthName(CURRENT_DATE) + ' ' + CURRENT_DATE.year();
        system.assertEquals(expectedMonthLabel, controller.monthname);
        
        system.assertEquals(3, controller.shiftOptions.size());
        system.assertEquals(2, controller.divisionOptions.size());
        
        List<List<ShiftPlanningCalendarController.DayOfWeek>> days  = controller.days;
        system.assert(!days.isEmpty());
        
        controller.previousMonth();
        
        expectedMonthLabel = ShiftPlanningCalendarUtil.getMonthName(previousMonthDate) + ' ' + previousMonthDate.year();
        system.assertEquals(expectedMonthLabel, controller.monthname);
        
        system.assertEquals(3, controller.shiftOptions.size());
        system.assertEquals(2, controller.divisionOptions.size());
       
        Test.stopTest();       
    }
    
    /*
        Testing nextMonth method.
    */
    static testMethod void nextMonthTest() {
        
        
        Date nextMonthDate = CURRENT_DATE.addMonths(1);
        
        Test.startTest();
        testData();
        Test.setCurrentPage(Page.ShiftPlanningCalendar);
        
        ShiftPlanningCalendarController controller = new ShiftPlanningCalendarController();
        
        system.assert(controller.pageMessages != null);
        String expectedDateStr = CURRENT_DATE.month()+'/'+ CURRENT_DATE.day() +'/'+ CURRENT_DATE.year();
        system.assertEquals(expectedDateStr, controller.currentDateStr);
        
        String expectedMonthLabel = ShiftPlanningCalendarUtil.getMonthName(CURRENT_DATE) + ' ' + CURRENT_DATE.year();
        system.assertEquals(expectedMonthLabel, controller.monthname);
        
        system.assertEquals(3, controller.shiftOptions.size());
        system.assertEquals(2, controller.divisionOptions.size());
        
        List<List<ShiftPlanningCalendarController.DayOfWeek>> days  = controller.days;
        system.assert(!days.isEmpty());
        
        controller.nextMonth();
        
        expectedMonthLabel = ShiftPlanningCalendarUtil.getMonthName(nextMonthDate) + ' ' + nextMonthDate.year();
        system.assertEquals(expectedMonthLabel, controller.monthname);
        
        system.assertEquals(3, controller.shiftOptions.size());
        system.assertEquals(2, controller.divisionOptions.size());
       
        Test.stopTest();       
    }
    
    /*
        Testing showRoleData method.
    */
    static testMethod void showRoleDataTest() {
        
        
        Test.startTest();
        testData();
        Test.setCurrentPage(Page.ShiftPlanningCalendar);
        
        ShiftPlanningCalendarController controller = new ShiftPlanningCalendarController();
        
        system.assert(controller.pageMessages != null);
        String expectedDateStr = CURRENT_DATE.month()+'/'+ CURRENT_DATE.day() +'/'+ CURRENT_DATE.year();
        system.assertEquals(expectedDateStr, controller.currentDateStr);
        
        String expectedMonthLabel = ShiftPlanningCalendarUtil.getMonthName(CURRENT_DATE) + ' ' + CURRENT_DATE.year();
        system.assertEquals(expectedMonthLabel, controller.monthname);
        
        system.assertEquals(3, controller.shiftOptions.size());
        system.assertEquals(2, controller.divisionOptions.size());
        
        List<List<ShiftPlanningCalendarController.DayOfWeek>> days  = controller.days;
        system.assert(!days.isEmpty());
        
        controller.selectedDivision = div1.Id;
        controller.selectedShift = shift1.Id;
        controller.selectedDay = ''+CURRENT_DATE.day();
        
        controller.showRoleData();
        
        system.assert(!controller.divisionRoleWrapperList.isEmpty());
        
        
        String currentDayOfWeek = System.now().format('EEEE');
        if(currentDayOfWeek == 'Monday'){
            system.assertEquals(3, controller.divisionRoleWrapperList.size());
        }else if(currentDayOfWeek == 'Tuesday'){
            system.assertEquals(2, controller.divisionRoleWrapperList.size());
        }else if(currentDayOfWeek == 'Wednesday'){
            system.assertEquals(2, controller.divisionRoleWrapperList.size());
        }else if(currentDayOfWeek == 'Thursday'){
            system.assertEquals(1, controller.divisionRoleWrapperList.size());
        }else if(currentDayOfWeek == 'Friday'){
            system.assertEquals(1, controller.divisionRoleWrapperList.size());
        }else if(currentDayOfWeek == 'Saturday'){
            system.assertEquals(1, controller.divisionRoleWrapperList.size());
        }else{
            system.assertEquals(1, controller.divisionRoleWrapperList.size());
        }
        //system.assertEquals(2, controller.divisionRoleWrapperList.get(0).roleAssignments.size());
        //system.assertEquals(0, controller.divisionRoleWrapperList.get(0).availableShiftUserOptions.size()); 
        
        //system.assertEquals(2, controller.divisionRoleWrapperList.get(0).roleAssignmentsOptions.size());
        
        system.assert(controller.pageMessages.isEmpty());

        Test.stopTest();       
    }
    
    /*
        Testing showCopyTool method. 
    */
    static testMethod void showCopyToolTest1() {
        
        
        Test.startTest();
        testData();
        Test.setCurrentPage(Page.ShiftPlanningCalendar);
        
        ShiftPlanningCalendarController controller = new ShiftPlanningCalendarController();
        
        system.assert(controller.pageMessages != null);
        String expectedDateStr = CURRENT_DATE.month()+'/'+ CURRENT_DATE.day() +'/'+ CURRENT_DATE.year();
        system.assertEquals(expectedDateStr, controller.currentDateStr);
        
        String expectedMonthLabel = ShiftPlanningCalendarUtil.getMonthName(CURRENT_DATE) + ' ' + CURRENT_DATE.year();
        system.assertEquals(expectedMonthLabel, controller.monthname);
        
        system.assertEquals(3, controller.shiftOptions.size());
        system.assertEquals(2, controller.divisionOptions.size());
        
        List<List<ShiftPlanningCalendarController.DayOfWeek>> days  = controller.days;
        system.assert(!days.isEmpty());
        
        controller.selectedDivision = div1.Id;
        controller.selectedShift = shift1.Id;
        
        controller.showCopyTool();
        
        system.assertEquals('Test Morning Shift', controller.selectedShiftName);
        system.assertEquals('Test devision101', controller.selectedDivisionName);
        
        system.assert(controller.pageMessages.isEmpty());
        
        Test.stopTest();
    }
    
    /*
        Testing showCopyTool method. Called without division and shift selected.
    */
    static testMethod void showCopyToolTest2() {
        
        
        Test.startTest();
        testData();
        Test.setCurrentPage(Page.ShiftPlanningCalendar);
        
        ShiftPlanningCalendarController controller = new ShiftPlanningCalendarController();
        
        system.assert(controller.pageMessages != null);
        String expectedDateStr = CURRENT_DATE.month()+'/'+ CURRENT_DATE.day() +'/'+ CURRENT_DATE.year();
        system.assertEquals(expectedDateStr, controller.currentDateStr);
        
        String expectedMonthLabel = ShiftPlanningCalendarUtil.getMonthName(CURRENT_DATE) + ' ' + CURRENT_DATE.year();
        system.assertEquals(expectedMonthLabel, controller.monthname);
        
        system.assertEquals(3, controller.shiftOptions.size());
        system.assertEquals(2, controller.divisionOptions.size());
        
        List<List<ShiftPlanningCalendarController.DayOfWeek>> days  = controller.days;
        system.assert(!days.isEmpty());
        
        //controller.selectedDivision = div1.Id;
        //controller.selectedShift = shift1.Id;
        
        controller.showCopyTool();
        
        system.assert(!controller.pageMessages.isEmpty());
        system.assertEquals(1, controller.pageMessages.size());
        system.assertEquals('Select a valid shift and division and try again.', controller.pageMessages.get(0).message);
        
        system.assert(controller.selectedShiftName == null);
        system.assert(controller.selectedDivisionName == null);
        
        Test.stopTest();
    }
    
    /*
        Testing saveShiftRoleAssignmentChanges method. 
    */
    static testMethod void saveShiftRoleAssignmentChangesTest() {
        
        
        Test.startTest();
        testData();
        Test.setCurrentPage(Page.ShiftPlanningCalendar);
        
        ShiftPlanningCalendarController controller = new ShiftPlanningCalendarController();
        
        system.assert(controller.pageMessages != null);
        String expectedDateStr = CURRENT_DATE.month()+'/'+ CURRENT_DATE.day() +'/'+ CURRENT_DATE.year();
        system.assertEquals(expectedDateStr, controller.currentDateStr);
        
        String expectedMonthLabel = ShiftPlanningCalendarUtil.getMonthName(CURRENT_DATE) + ' ' + CURRENT_DATE.year();
        system.assertEquals(expectedMonthLabel, controller.monthname);
        
        system.assertEquals(3, controller.shiftOptions.size());
        system.assertEquals(2, controller.divisionOptions.size());
        
        List<List<ShiftPlanningCalendarController.DayOfWeek>> days  = controller.days;
        system.assert(!days.isEmpty());
        
        controller.selectedDivision = div1.Id;
        controller.selectedShift = shift1.Id;
        controller.selectedDay = ''+CURRENT_DATE.day();
        
        controller.showRoleData();
        
        system.assert(!controller.divisionRoleWrapperList.isEmpty());
        String currentDayOfWeek = System.now().format('EEEE');
        if(currentDayOfWeek == 'Monday'){
            system.assertEquals(3, controller.divisionRoleWrapperList.size());
        }else if(currentDayOfWeek == 'Tuesday'){
            system.assertEquals(2, controller.divisionRoleWrapperList.size());
        }else if(currentDayOfWeek == 'Wednesday'){
            system.assertEquals(2, controller.divisionRoleWrapperList.size());
        }else if(currentDayOfWeek == 'Thursday'){
            system.assertEquals(1, controller.divisionRoleWrapperList.size());
        }else if(currentDayOfWeek == 'Friday'){
            system.assertEquals(1, controller.divisionRoleWrapperList.size());
        }else if(currentDayOfWeek == 'Saturday'){
            system.assertEquals(1, controller.divisionRoleWrapperList.size());
        }else{
            system.assertEquals(1, controller.divisionRoleWrapperList.size());
        }
        
        //system.assertEquals(2, controller.divisionRoleWrapperList.get(0).roleAssignments.size());
        //system.assertEquals(0, controller.divisionRoleWrapperList.get(0).availableShiftUserOptions.size());
        
        //system.assertEquals(2, controller.divisionRoleWrapperList.get(0).roleAssignmentsOptions.size());
        
        system.assert(controller.pageMessages.isEmpty());
        
        //controller.divisionRoleWrapperList.get(0).availableShiftUserOptions.add(controller.divisionRoleWrapperList.get(0).roleAssignmentsOptions.get(1));
        
        //controller.divisionRoleWrapperList.get(0).roleAssignmentsOptions.remove(1);
        
        controller.saveShiftRoleAssignmentChanges();
        
        Test.stopTest();
    }
    
    /*
        Testing copyAssignments method with includeWeekendParam = true;
    */
    static testMethod void copyAssignmentsTest1() {
        
        
        Test.startTest();
        testData();
        Test.setCurrentPage(Page.ShiftPlanningCalendar);
        
        ShiftPlanningCalendarController controller = new ShiftPlanningCalendarController();
        
        system.assert(controller.pageMessages != null);
        String expectedDateStr = CURRENT_DATE.month()+'/'+ CURRENT_DATE.day() +'/'+ CURRENT_DATE.year();
        system.assertEquals(expectedDateStr, controller.currentDateStr);
        
        String expectedMonthLabel = ShiftPlanningCalendarUtil.getMonthName(CURRENT_DATE) + ' ' + CURRENT_DATE.year();
        system.assertEquals(expectedMonthLabel, controller.monthname);
        
        system.assertEquals(3, controller.shiftOptions.size());
        system.assertEquals(2, controller.divisionOptions.size());
        
        List<List<ShiftPlanningCalendarController.DayOfWeek>> days  = controller.days;
        system.assert(!days.isEmpty());
        
        controller.selectedDivision = div1.Id;
        controller.selectedShift = shift1.Id;
        
        controller.fromDateParam = '06/07/2013';
        controller.startDateParam = '06/16/2013';
        controller.endDateParam = '06/17/2013';
        controller.includeWeekendParam = 'true';
        
        controller.copyAssignments();
        
        List<Shift_Role_Assignment__c> shiftRoleAssigns = [Select id From Shift_Role_Assignment__c where Team_Role__r.Division__c =: div1.Id and 
                                                        Shift__c =: shift1.Id and Date__c = : Date.newInstance(2013, 06, 16) ];
        
        
        //system.assert(!shiftRoleAssigns.isEmpty());
        //system.assertEquals(3, shiftRoleAssigns.size());
        
        shiftRoleAssigns = [Select id From Shift_Role_Assignment__c where Team_Role__r.Division__c =: div1.Id and 
                                                        Shift__c =: shift1.Id and Date__c = : Date.newInstance(2013, 06, 17) ];
        
        
        //system.assert(!shiftRoleAssigns.isEmpty());
        //system.assertEquals(3, shiftRoleAssigns.size());
        
        Test.stopTest();
    }
    
    /*
        Testing copyAssignments method with includeWeekendParam = false;
    */
    static testMethod void copyAssignmentsTest2() {
        
        
        Test.startTest();
        testData();
        Test.setCurrentPage(Page.ShiftPlanningCalendar);
        
        ShiftPlanningCalendarController controller = new ShiftPlanningCalendarController();
        
        system.assert(controller.pageMessages != null);
        String expectedDateStr = CURRENT_DATE.month()+'/'+ CURRENT_DATE.day() +'/'+ CURRENT_DATE.year();
        system.assertEquals(expectedDateStr, controller.currentDateStr);
        
        String expectedMonthLabel = ShiftPlanningCalendarUtil.getMonthName(CURRENT_DATE) + ' ' + CURRENT_DATE.year();
        system.assertEquals(expectedMonthLabel, controller.monthname);
        
        system.assertEquals(3, controller.shiftOptions.size());
        system.assertEquals(2, controller.divisionOptions.size());
        
        List<List<ShiftPlanningCalendarController.DayOfWeek>> days  = controller.days;
        system.assert(!days.isEmpty());
        
        controller.selectedDivision = div1.Id;
        controller.selectedShift = shift1.Id;
        
        controller.fromDateParam = '06/07/2013';
        controller.startDateParam = '06/16/2013'; // sunday i.e weekend 
        controller.endDateParam = '06/17/2013';
        controller.includeWeekendParam = 'false';
        
        controller.copyAssignments();
        
        List<Shift_Role_Assignment__c> shiftRoleAssigns = [Select id From Shift_Role_Assignment__c where Team_Role__r.Division__c =: div1.Id and 
                                                        Shift__c =: shift1.Id and Date__c = : Date.newInstance(2013, 06, 16) ];
        
        
        system.assert(shiftRoleAssigns.isEmpty());
        
        shiftRoleAssigns = [Select id From Shift_Role_Assignment__c where Team_Role__r.Division__c =: div1.Id and 
                                                        Shift__c =: shift1.Id and Date__c = : Date.newInstance(2013, 06, 17) ];
        
        
        //system.assert(!shiftRoleAssigns.isEmpty());
        //system.assertEquals(3, shiftRoleAssigns.size());
        
        Test.stopTest();
    }
   /* 
    static testMethod void handleDivisionBeforeUpdateTest() {
        testData();
        
        User user = getMockedUser();
        try {
            Division__c div2 = new Division__c(Name = 'Test devision101', User__c = user.id);
            insert div2;
        
            div2.User__c = Userinfo.getUserId();
            update div2;
        } catch(Exception e) {
            system.assert(true);
        }
        
    }
    */
}