@isTest
private class  HD_Test_Intro_Starter_Config_Puller
{
	@isTest
	static void itShould()
	{
      List<HD_Intro_Starter_Config__c> ls = HD_Intro_Starter_Config_Puller.getIntroConfig();
        if( ls.size() > 0)
        {
            system.assert(ls.size() > 0, 'Has Record to access');
        }else
        {
            system.assert(ls.size() <=  0, 'Has no Record to access');
        }
        HD_Intro_Starter_Config_Puller.getIntroStartedFlag();
	}
}