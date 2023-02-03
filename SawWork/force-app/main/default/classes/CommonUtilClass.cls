/*************************************************************************************************************

Created By: ssawhney
Created On: 4/4/4014
Description: This class will be used to add all the utility methods that can be reused by the teams

  --Developer           --Date       --JIRA             --Change
  Jay                   09/28/2021    ESESP-3945         Added utility method to get the current shift details

************************************************************************************************************
*/
public class CommonUtilClass
{
    //Util Method to extract the validation exception message from exceptions for Visualforce pages
    public static string ExtractValidationExMsg(Exception e)
    {
        string substr = 'FIELD_CUSTOM_VALIDATION_EXCEPTION, ';
        integer index = e.getMessage().lastindexof(substr);

        string error = '';
        if(index > -1)
        {
            error = e.getMessage().substring(index + substr.length());
            index = error.lastindexof(': []');
            if(index > -1)
            {
                error = error.substring(0, index);
            }
        }
        else
        {
            return e.getMessage();
        }
        return error;
    }

    public static string extractValidationErrorMsg(Exception e)
    {
        String substr = 'FIELD_CUSTOM_VALIDATION_EXCEPTION, ';
        String subStrTooLong = 'STRING_TOO_LONG, ';

        Integer index;
        String error = '';

        if(e.getMessage().lastindexof(substr) > -1)
        {
            error = e.getMessage().substring(e.getMessage().lastindexof(substr) + substr.length());
            index = error.lastindexof(': [');
            if(index > -1)
            { 	error = error.substring(0, index);}
        }
        else if(e.getMessage().lastindexof(subStrTooLong) > -1)
        {
            error = e.getMessage().substring(e.getMessage().lastindexof(substr) + subStrTooLong.length());
            index = error.lastindexof('(max length=');
            if(index > -1)
            {	error = 'Crossed Timecard Notes limit of 255 characters, please shorten the answer for "What work was done?"';	}
        }
        else {	return e.getMessage();	}
        return error;
    }

    public class ShiftDetails {
        public String currentShift;
        public String previousShift;
        public Datetime startDate;
        public Datetime endDate;
    }

    public static ShiftDetails getShiftDetails(Datetime cTime) {
        final List<String> shifts = new List<String>{
                'APJ', 'EMEA', 'AMER East', 'AMER West'
        };
        Integer currentHour = cTime.hourGmt();
        Integer shiftIndex,startHour,endHour;
        if (currentHour >= 2 && currentHour < 8) {
            shiftIndex = 0;
            startHour = 2;
            endHour = 8;
        } else if (currentHour >= 8 && currentHour < 14) {
            shiftIndex = 1;
            startHour = 8;
            endHour = 14;
        } else if (currentHour >= 14 && currentHour < 20) {
            shiftIndex = 2;
            startHour = 14;
            endHour = 20;
        } else if (currentHour >= 20 && currentHour < 24) {
            shiftIndex = 3;
            startHour = 20;
            endHour = 26;
        } else if (currentHour >= 0 && currentHour < 2) {
            shiftIndex = 3;
            startHour = -4;
            endHour = 2;
        }

        ShiftDetails temp = new ShiftDetails();
        temp.currentShift = shifts[shiftIndex];
        temp.previousShift = shifts[shiftIndex == 0 ? shifts.size() - 1: shiftIndex - 1];
        temp.startDate = Datetime.newInstanceGmt(cTime.yearGmt(),cTime.monthGmt(),cTime.dayGmt(),startHour,0,0);
        temp.endDate = Datetime.newInstanceGmt(cTime.yearGmt(),cTime.monthGmt(),cTime.dayGmt(),endHour,0,0);
        return temp;
    }

}