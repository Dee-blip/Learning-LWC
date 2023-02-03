/* ------------------------------------------------------------------------------------ 

    Test class name     :   SC_KCS_Entitlement_Test 
    Author              :   Vandhana Krishnamurhty
    Created             :   01-Dec-16
    Purpose             :   Test Class for SC_KCS_Entitlement trigger
---------------------------------------------------------------------------------------
26-Aug-2018		Vamsee S		Changed Test Class to Seealldata False & 
								Increased Code Coverage (ESESP-1624)
------------------------------------------------------------------------------------ */

@isTest(seeAllData=false)
public class SC_KCS_Entitlement_Test 
{
	public static testMethod void test_KCS_Entitlement()
	{
		List<String> kcsLevels = new List<String>{'Level I','Level II','Level III'};
	    List<User> userList = new List<User>();
	    for(Integer i=0;i<6;i++)
	    {
	    	User usr = utilTestClass.CreateUser('NewUser'+i, 'Worldwide', 'Support - Tech Support Manager');
	    	userList.add(usr);
	    }
	    
	    User currentUser = new User(Id = Userinfo.getUserId());
	    User techSuppMgr = utilTestClass.CreateUser('TSM', 'Worldwide', 'Support - Tech Support Manager');
	    
	    System.runAs(currentUser)
		{
	    	insert userList;
		}

		Test.startTest();

	    System.runAs(techSuppMgr)
		{
			List<KCS_Entitlement__c> lstKCSE = new List<KCS_Entitlement__c>();

			for(Integer i=0;i<6;i++)
			{
				KCS_Entitlement__c eachKCSE = new KCS_Entitlement__c(User__c = userList[i].Id, KCS_Level__c = kcsLevels[Math.mod(i,3)]);
				lstKCSE.add(eachKCSE);
			}

			insert lstKCSE;
			KCS_Entitlement__c newKCSE = new KCS_Entitlement__c(User__c = userList[userList.size()-1].Id, KCS_Level__c = 'Level I');
			try
			{
                insert newKCSE;
                
			}
			catch(Exception e) {
            }
            
            try{
                lstKCSE[0].User__c = userList[1].Id;
                Update lstKCSE[0];
            }
			catch(Exception e) {
            }
            
			delete lstKCSE;
		}
		Test.stopTest();
	}
}