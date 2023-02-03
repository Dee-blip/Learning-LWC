/***************************************************************************
 * Name             : ACD2_PageLayoutClass_Test
 * Created By       : Sharath Prasanna
 * Created Date     : 28-Sep-2020
 * Purpose          : Test Class for ACD 2.0
 * List of Classes	: BucherSuter_ACD_PageLayoutClass
 ****************************************************************************/
@isTest(SeeAllData=false)
public class ACD2_PageLayoutClass_Test 
{
    public ACD2_PageLayoutClass_Test() 
    {

    }
    @isTest static void testGetFieldWrapper()
    {
        Test.startTest();
            //BucherSuter_ACD_PageLayoutClass.getFieldWrapper(objectName, recordType, lob, defaultValues );
            BucherSuter_ACD_PageLayoutClass wrapper = new BucherSuter_ACD_PageLayoutClass();
            String defaultVal = 'Subject=test';
            BucherSuter_ACD_PageLayoutClass.getFieldWrapper('Case', 'Billing', 'Billing',  defaultVal);
        Test.stopTest();
    }
}