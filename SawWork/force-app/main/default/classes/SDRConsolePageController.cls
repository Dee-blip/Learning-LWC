public class SDRConsolePageController 
{
	public String dashboardURL {get; set;}
	public SDRConsolePageController() 
	{
		dashboardURL = System.URL.getSalesforceBaseURL().toExternalForm()+'/'+GsmUtilClass.getGSMSettingValue('SDRConsoleDashboardId');
	}
}