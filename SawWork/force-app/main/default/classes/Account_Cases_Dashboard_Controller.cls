global class Account_Cases_Dashboard_Controller 
{
	public static Links__c accountCasesTop {get;set;}
	public static Links__c accountCasesHistory {get;set;}
	public Account_Cases_Dashboard_Controller(ApexPages.StandardController stdController)
	{
		accountCasesTop = Links__c.getInstance('Account Cases Top 10');
		accountCasesHistory = Links__c.getInstance('Account Cases History');
	}

}