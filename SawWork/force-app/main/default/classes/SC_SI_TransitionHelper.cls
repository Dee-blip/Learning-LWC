/*
Author          : Sheena,Vamsee,Vishnu,Himanshu
Description     : Transition helper Class
Called From		: SC_SI_PageLayoutButton_Controllor
Test Class		: SC_SI_AllTestCases_TC

Date                Developer             JIRA #                            Description                                                       
------------------------------------------------------------------------------------------------------------------
14 Aug 2020       	Vishnu               ESESP-3795               		  Initial Version
------------------------------------------------------------------------------------------------------------------

*/
public class SC_SI_TransitionHelper {

    //Method - 1: used in transition process to get current shift value
    public static String getCurrentShiftDetails(String recordTypeName){
        
        Map<string,decimal> hourShiftMap = getRegularShiftTimes();
        DateTime currentDateTime = (DateTime) datetime.now();
        decimal currentHour = currentDateTime.hourGmt();
        currentHour = currentHour + currentDateTime.minuteGmt()/60;
        decimal differenceInHours = 10000000;
        String currentShift = null;
        
        //loop through and tell me which shift I am in now
            for(String g:hourShiftMap.keyset()){
                decimal hh = hourShiftMap.get(g);
                
                if(currentHour - hh  < differenceInHours && currentHour >= hh ){
                    differenceInHours = currentHour - hh;
                    currentShift = g;
                }
            }
        
        return currentShift;
    }
    
    //Method - 2 : Get wokeup time based on Shift
    public static DateTime getShiftDateTime(String shiftName, String recordTypeName){
        
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
        
        // Calculating minutes if applicable
        if (stringReprentationOfDecimal.indexOf('.') > -1){
            String decimalValueAfterDot = stringReprentationOfDecimal.substring(stringReprentationOfDecimal.indexOf('.'),stringReprentationOfDecimal.length());
            decimal minutsDecimal = decimal.valueof(decimalValueAfterDot)*60;
            minutes = minutsDecimal.intValue();
        }
        
        // Calculating wake up datetime    
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
    
    //Method - 3 : Get Wokeup time based on Shift selected 
    public static map<String,decimal> getRegularShiftTimes(){
        Map<string,decimal> hourShiftMap = new Map<string,decimal>{'APJ'=>1};
        boolean isUSA_DST_On = isUSADayLightSavingsOn();
        boolean isEMEA_DST_On = isEMEADayLightSavingsOn();
        Decimal result;
        
		//USA DST Check
		result = isUSA_DST_On ? hourShiftMap.put('US East',12.5) : hourShiftMap.put('US East',13.5);
		result = isUSA_DST_On ? hourShiftMap.put('US West',17) : hourShiftMap.put('US West',18);
		
		//EMEA DST Check
		result = isEMEA_DST_On ? hourShiftMap.put('EMEA',7) : hourShiftMap.put('EMEA',8);
   
        return hourShiftMap;
    }
    
    // Method - 4 : This method check whether USA DST is on
    public static boolean isUSADayLightSavingsOn(){
        TimeZone tz = TimeZone.getTimeZone('America/New_York');
        DateTime d = datetime.now();
        return tz.getOffset(d) != -18000000; //GMT -5 Hours
    } 
    
  
    
    // Method - 5 : This method check whether EMEA DST is on
    public static boolean isEMEADayLightSavingsOn(){
        TimeZone tz = TimeZone.getTimeZone('Europe/Amsterdam');
        DateTime d = datetime.now();
        return tz.getOffset(d) != 3600000; // GMT +1 Hour
    } 
    
}