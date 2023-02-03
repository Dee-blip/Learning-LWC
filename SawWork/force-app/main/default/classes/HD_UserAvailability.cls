/** Requirement : After creating the ticket if it is assigned to a person in other timezone, an alert messsage should be given 
about the fact that the other person is in another timezone and will be not in office for another X hours.
Functionality : This Class will check for the Business Hours of the user. If the user is not available in the office, 
then display a warning message with difference between next available. **/



Global class HD_UserAvailability{

    public BusinessHours userBusinessHours;
    String timeZoneSidKey;
    Set<Integer> holidays ;
    public Integer dayOfTheWeek;
    Final Static Time time247= Time.newInstance(0,0,0,0);
    Final Static Time midNightTime= Time.newInstance(23,59,59,0);
    Final Static Date baseDate = Date.newInstance(1900,1,7);
    Map<Integer,Time> OfficeStartTimeMap;
    Map<String,BusinessHours> businessHoursMap;
    String staffName;

    Map<Id,User> userMap;
    
    BMCServiceDesk__Incident__c incident;
    List<Integer> waitList = new List<Integer>();
       
    Global HD_UserAvailability(){
        businessHoursMap = new Map<String,BusinessHours>();
        holidays = new Set<Integer>();
        OfficeStartTimeMap = new Map<Integer,Time>();
        for(Integer day=0;day<7;day++)
            OfficeStartTimeMap.put(day,time247);
        
        // To Query only users with 'Salesforce and Salesforce Platform' Licenses.
        userMap =new Map<ID,User>([SELECT name,TimeZoneSidKey FROM User Where UserType='Standard' AND IsActive=True]);//profileId!=:ProfileId]);
        
        // Populate a map with TimezonesIdKey and associated BusinessHours.
        for(BusinessHours businessHours : [SELECT TimeZoneSidKey,SundayStartTime,SundayEndTime,MondayStartTime,MondayEndTime,TuesdayStartTime,TuesdayEndTime,WednesdayStartTime,WednesdayEndTime,ThursdayStartTime,ThursdayEndTime,FridayStartTime,FridayEndTime,SaturdayStartTime,SaturdayEndTime FROM BusinessHours WHERE isActive=True])
            businessHoursMap.put(businessHours.TimeZoneSidKey,businessHours);
    }
    
    /** This method will check the User Availability. Takes argument as Id of the Owner of the Incident and Incident for 
    which Alert message is to be displayed. **/   
    
    global void findUserAvailability(Id user, BMCServiceDesk__Incident__c inci){              
        
        incident=inci;
        if(userMap.size()!=Null && userMap.containsKey(user)){
            timeZoneSidKey=userMap.get(user).TimeZoneSidKey;
            staffName=userMap.get(user).Name;
        } 
        
        // If a businessHours is available for the Owner of the Incident.
        if(businessHoursMap.containsKey(timeZoneSidKey)){
            
            userBusinessHours=businessHoursMap.get(timeZoneSidKey);
            findWeekendsFromUserBusinessHours(userBusinessHours);
            
            // Convert GMT time in the User Local time, when the Incident is assigend to staff Person.
            
            Datetime GMTDate = datetime.now();
            String strConvertedDate = GMTDate.format('yyyy-MM-dd HH:mm:ss a',TimeZoneSidKey );
            
            String dateString = strConvertedDate.substring((strConvertedDate.indexOf('-')-4),(strConvertedDate.indexOf('-')+6));
            String[] dateValues= dateString.split('-');
            Date userLocaleDate = date.newInstance(Integer.valueOf(dateValues[0]),Integer.valueOf(dateValues[1]),Integer.valueOf(dateValues[2]));

            String TimeString = strConvertedDate.substring((strConvertedDate.indexOf(':')-2),(strConvertedDate.indexOf(':')+3));
            String [] timeValues= timestring.split(':');
            Time userLocaleTime = time.newInstance(Integer.valueOf(timeValues[0]),Integer.valueOf(timeValues[1]),0,0);   
            
            // To find out day of the week. 0 represents to Sunday and so on.
            if(!Test.isRunningTest())
            {
              dayOfTheWeek=Math.mod(baseDate.daysBetween(userLocaleDate),7);
            }
      
            if(dayOfTheWeek==0){
                generateAlert(staffName,0,userBusinessHours.SundayStartTime,userBusinessHours.SundayEndTime,userLocaleTime);
            }
            else if(dayOfTheWeek==1){     
                generateAlert(staffName,1,userBusinessHours.MondayStartTime,userBusinessHours.MondayEndTime,userLocaleTime);
            }
            else if(dayOfTheWeek==2){   
                generateAlert(staffName,2,userBusinessHours.TuesdayStartTime,userBusinessHours.TuesdayEndTime,userLocaleTime);
            }               
            else if(dayOfTheWeek==3){
                generateAlert(staffName,3,userBusinessHours.WednesdayStartTime,userBusinessHours.WednesdayEndTime,userLocaleTime);
            }    
            else if(dayOfTheWeek==4){
                generateAlert(staffName,4,userBusinessHours.ThursdayStartTime,userBusinessHours.ThursdayEndTime,userLocaleTime);
            }
            else if(dayOfTheWeek==5){
                generateAlert(staffName,5,userBusinessHours.FridayStartTime,userBusinessHours.FridayEndTime,userLocaleTime);
            }
            else if(dayOfTheWeek==6){
                generateAlert(staffName,6,userBusinessHours.SaturdayStartTime,userBusinessHours.SaturdayEndTime,userLocaleTime);
            }
        }
        else
            incident.addError('No Business Hours found for '+ timeZoneSidKey +' Timezone');
    }
    
    /** FindUserAvailability Method calls this method to generate alert if the user is not available in the Office. **/
    
    public void generateAlert(String staffName,Integer dayOfTheWeek,Time startTime, Time endTime,Time userLocaleTime){
        Integer hoursBetweenNextOffice=0;
        if(!(startTime==endTime && endTime==time247)){
            if(endTime==time247)
                endTime=midNightTime;
            
            // If StartTime for the day is NULL, it is a weekend at user place.
            if(startTime==NULL){
                   hoursBetweenNextOffice=timeBetweenNextOffice(dayOfTheWeek,userLocaleTime);
                   incident.addError('It is a weekend at '+StaffName +' place and will not be in office for next ' + waitList.get(0) + ' Hours ' + waitList.get(1) +' Minutes');
            }
            else{
                if(userLocaleTime<startTime){
                    exactTimeInMinutesAndHours(-24,userLocaleTime,startTime);
                    incident.addError('Office Hours are closed,'+StaffName +' will be in office after ' + waitList.get(0) + ' Hours ' + waitList.get(1) +' Minutes'); 
                } 
                else if((userLocaleTime>endTime)){
                    hoursBetweenNextOffice=timeBetweenNextOffice(dayOfTheWeek,userLocaleTime);
                    incident.addError('Office Hours are closed,'+StaffName +' will be in office after ' + waitList.get(0) + ' Hours ' + waitList.get(1) +' Minutes');    
                }
            }
        }
    }
    
    
    // This method finds time between current Time and next Available time.
       
    public Integer timeBetweenNextOffice(Integer dayOfTheWeek,Time userLocaleTime){
        Time officeStartTime;
        Integer nextWorkingDay;
        Integer offsetHours=0;
        Integer minutes;
        Integer hours;
        waitList.clear();
        Integer iterationOverDays=dayOfTheWeek+1;
        While(True){
            nextWorkingDay=math.mod(iterationOverDays,7);
            if(holidays.contains(nextWorkingDay))
                offsetHours+=24;
            else{
                officeStartTime= OfficeStartTimeMap.get(nextWorkingDay);
                exactTimeInMinutesAndHours(offsetHours,userLocaleTime,officeStartTime);           
                return 1;
            }                   
            iterationOverDays++;
        }
        return 0;
    }  
    
    // This method finds exact time difference in Minutes and Hours for the next availability.
    public void exactTimeInMinutesAndHours(Integer offsetHours,Time userLocaleTime,Time startTime){
        Integer hours;
        Integer minutes;               
        hours=(offsetHours+24-(userLocaleTime.Hour()-startTime.Hour()));
        minutes=60-((userLocaleTime.Minute()-startTime.Minute()));
                   
        if(minutes<60)
            hours--;
        else
            minutes=minutes-60;   
        waitList.add(hours);
        waitList.add(minutes); 
    }          
    
    
    // This methods finds weekday and weekends from the Business Hour and captures start time for each weekday.   
    Public void findWeekendsFromUserBusinessHours(BusinessHours userBusinessHours){
        holidays.clear(); 
        OfficeStartTimeMap.clear();
        if(userBusinessHours!=Null){
            if(userBusinessHours.SundayStartTime==NULL)
                holidays.add(0);
            else
                OfficeStartTimeMap.put(0,userBusinessHours.SundayStartTime);
              
            if(userBusinessHours.MondayStartTime==NULL)
                holidays.add(1);
            else
                OfficeStartTimeMap.put(1,userBusinessHours.MondayStartTime);
              
            if(userBusinessHours.TuesdayStartTime==NULL)
                holidays.add(2);
            else
                OfficeStartTimeMap.put(2,userBusinessHours.TuesdayStartTime);
              
            if(userBusinessHours.WednesdayStartTime==NULL)
                holidays.add(3);
            else
                OfficeStartTimeMap.put(3,userBusinessHours.WednesdayStartTime);
              
            if(userBusinessHours.ThursdayStartTime==NULL)
                holidays.add(4);
            else
                OfficeStartTimeMap.put(4,userBusinessHours.ThursdayStartTime);
              
            if(userBusinessHours.FridayStartTime==NULL)
                holidays.add(5);
            else
                OfficeStartTimeMap.put(5,userBusinessHours.FridayStartTime);
              
            if(userBusinessHours.SaturdayStartTime==NULL)
                holidays.add(6);
            else
                OfficeStartTimeMap.put(6,userBusinessHours.SaturdayStartTime);    
        }
        else
             System.debug('NO TIMEZONE FOUND');  
    }
}