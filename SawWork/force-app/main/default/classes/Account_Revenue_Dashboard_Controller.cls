global class Account_Revenue_Dashboard_Controller 
{
	public static Links__c dashboardLink {get;set;}
	public static Links__c dashboardLink2 {get;set;}
	public Account_Revenue_Dashboard_Controller(ApexPages.StandardController stdController)
	{
		dashboardLink = Links__c.getInstance('Monthly Account Revenue');
		dashboardLink2 = Links__c.getInstance('Monthly Account Revenue Part 2');
	}

}