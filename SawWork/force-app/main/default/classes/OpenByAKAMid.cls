public with sharing class OpenByAKAMid 
{
	public string AKAMid {get; set;}
	
	public OpenByAKAMid()
	{
		AKAMid = ApexPages.currentPage().getParameters().get('id');
	}

	public OpenByAKAMid (String pAKAMiD)
	{
		AKAMid = pAKAMiD;
	}
		
    public PageReference AutoRun()
    {
    	// Generate the dynamic SOSL query using Custom Settings
		String soslSearchString = 'find \'' + AKAMid + '\' IN ALL FIELDS returning';
		for(OpenByAkamId_Settings__c cs : [Select Name, AKAM_ID_field_name__c  From OpenByAkamId_Settings__c])
			soslSearchString = soslSearchString + ' ' + cs.Name + ' (Id  WHERE ' + cs.AKAM_ID_field_name__c + '= \'' +  AKAMid + '\'),';
		// Remove the last extra ,
		soslSearchString = soslSearchString.substring(0, soslSearchString.length() - 1);

		if (AKAMid != null && AKAMid.length()>1)
		{
			List<List<SObject>> searchList = search.query(soslSearchString);
			
			for (integer i=0; i < searchList.size(); i++)
			{				
				if (searchList[i].size()>0)
				{
					SObject[] sobj= ((List<SObject>) searchList[i]); 
					string sObjId = ''+sobj[0].id;
    				PageReference rPage = new PageReference('/'+ sObjId);
					rPage.setRedirect(true);
					return rPage;
				}
			}
		}
		return null;
   }
   
    //CR 2770464 - rsharma: Moving test methods defined in this non test class to MiscTestClass
   //public static testMethod void testAutoRun() 
   //{
 
 		////create acct and search for it using this controller
 		///*Account a = new Account();
   //     a.name    = '__ TEST';*/
        
   //     Account a = utilTestClass.CreateAccount('__ TEST');
   //     a.BillingStreet = 'Maple Ave';
   //     a.BillingState = 'NY';
   //     a.BillingPostalCode = '10514';
   //     a.BillingCountry = 'USA';
   //     a.BillingCity = 'Chappaqua';
   //     insert a;
        
   //     // Refresh Account
   //     a = [select Id, AKAM_Account_ID__c from Account where Id=:a.Id][0];
        
   //     Test.startTest();
   //     OpenByAKAMid controller = new OpenByAKAMid(a.AKAM_Account_ID__c);
        
   //     system.assertEquals(controller.AKAMid, a.AKAM_Account_ID__c);
        
   //     PageReference returnPage = controller.AutoRun();
   //     Test.stopTest();
        
   //     //system.assertEquals(returnPage.getUrl(), '/' + a.Id);
   // }
}