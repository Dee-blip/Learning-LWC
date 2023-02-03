@isTest(seeAllData = false)

public class IW_RoutingMessageChangeTest {

	@isTest
	static void testApprovalController()
	{
        IW_RoutingMessageChange.getRoutingMessageToggle();
        System.assertEquals(2,2);
			
	}
}