@isTest(seeAllData=false)
public class ApexExceptonHandlerTest 
{

	public ApexExceptonHandlerTest() 
	{
		
	}

	static testmethod void testHandleError()
    {
    	try
    	{
    		Integer i = 0;
    		Integer j= 1;
    		Integer k = j/i;
    	}
    	catch(Exception e)
    	{
    		ApexExceptionHandlerClass o = new ApexExceptionHandlerClass();
            o.handleError(e);
    	}
    }
}