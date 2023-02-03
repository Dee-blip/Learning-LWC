@isTest
public class CommonUtilClass_Test 
{
	// method from SC_Case_Trgr_EmlServc_Class_TC
    public static testMethod void CommonUtilClassTest()
    {   
        Test.startTest();
        try
        {
            Task TaskRec = new Task();
            TaskRec.subject = null;
            TaskRec.OwnerId = '004566666';
            insert TaskRec;
        }
        catch(Exception e)
        {
            e.setMessage('First exception on row 0; first error: FIELD_CUSTOM_VALIDATION_EXCEPTION, You must select an Organization or Contact: []');
            CommonUtilClass.ExtractValidationExMsg(e);
            CommonUtilClass.extractValidationErrorMsg(e);
            e.setMessage('STRING_TOO_LONG, sample text (max length=255)');
            CommonUtilClass.extractValidationErrorMsg(e);
        }
        Test.stopTest();   
    }

    @IsTest
    public static void test_getShiftDetails(){
        Date today = System.today();
        Datetime shiftAPJ = Datetime.newInstanceGmt(today.year(),today.month(),today.day(),2,10,0);
        Datetime shiftEMEA = shiftAPJ.addHours(6);
        Datetime shiftAmerEast = shiftAPJ.addHours(12);
        Datetime shiftAmerWest = shiftAPJ.addHours(18);
        String shift = CommonUtilClass.getShiftDetails(shiftAPJ).currentShift;
        System.assertEquals('APJ',shift);
        shift = CommonUtilClass.getShiftDetails(shiftEMEA).currentShift;
        System.assertEquals('EMEA',shift);
        shift = CommonUtilClass.getShiftDetails(shiftAmerEast).currentShift;
        System.assertEquals('AMER East',shift);
        shift = CommonUtilClass.getShiftDetails(shiftAmerWest).currentShift;
        System.assertEquals('AMER West',shift);

    }


}