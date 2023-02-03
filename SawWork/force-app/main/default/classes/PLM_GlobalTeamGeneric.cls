/*
Added by Hitesh Chawda
This class is a generic class added to be used by the test classes to 
generate the global team and standing delegation team.
Loop through the team size and add those many users to the team and insert the whole team*/
public  class PLM_GlobalTeamGeneric {

public static Features_Toggle__c launchItemApprovalFeature=Features_Toggle__c.getInstance('LaunchItemApproval');
    public static Profile userProfile=[select Id, Name from Profile where Name =:'Product Management'][0];
    public static UserRole userRole =[select Id,Name from UserRole where Name =: 'Worldwide'][0];
    public static Profile prodOpsProfile=[select Id from Profile where Name =: 'Product Operations'][0];
    public static User prodOpsUser=[select Id from User where ProfileId =:prodOpsProfile.Id and isActive =:true][0];
    public static Product_Line__c plc;
    public static PLU__c plu;
    public static Launch_Item__c li;
    public static User testUser; 
    
    public static List<Launch_Item_Approval__c>  createGlobalTeam()
    {
       
       List<Launch_Item__c> deleteExistingLaunchItems=[select id from Launch_item__c where Archive__c =false];
      
      if(deleteExistingLaunchItems !=null && deleteExistingLaunchItems.size()>0)
      {
      	delete deleteExistingLaunchItems;
      }
      testUser=createUser('Test11','User','Engineering','TestBusiness Unit'
    		                        ,3243,322,'testUser1@akamai.com','Test Deptt.','Test Division'
    		                        ,'t1User', 'UTF-8','en_US'
    		                        ,'en_US','America/Los_Angeles','test1User@akamai.com',userProfile.Id,userRole.Id);
    	
    	insert testUser;	
       List<Launch_Item_Approval__c> memberList=new List<Launch_Item_Approval__c>();
       List<Launch_Item_Approval__c> standingDelmemberList=new List<Launch_Item_Approval__c>();
       List<Schema.PicklistEntry> divisionPickList=Schema.Launch_Item_Approval__c.Division__c.getDescribe().getPicklistValues();
       List<Schema.PicklistEntry> functionPickList=Schema.Launch_Item_Approval__c.Function__c.getDescribe().getPicklistValues();
       
       
       
       for(Schema.PicklistEntry p: divisionPickList)
         {
          Launch_Item_Approval__c litm=new Launch_Item_Approval__c(Division__c=p.getValue());
          memberList.add(litm);
         }
       for(Schema.PicklistEntry p: functionPickList)
	     {
	      Launch_Item_Approval__c litm=new Launch_Item_Approval__c(function__c=p.getValue());
	     memberList.add(litm);
	      for(Schema.PicklistEntry q: divisionPickList)
     	  {
     	  	Launch_Item_Approval__c lia = new Launch_Item_Approval__c(Function__c = p.getValue(),Division__c = q.getValue());
     	  	standingDelmemberList.add(lia);
     	  
     	  }	
	     }
       List<User> userList =new List<User>();
       List<User> userListglobal =new List<User>();
       List<User> userListdelegation =new List<User>();
       for(Integer i=0;i<standingDelmemberList.size();i++)
    	{
    		User newUser=createUser('Test1','User1'+i,'Engineering','TestBusiness Unit'
    		                        ,3243,322,'testUser11'+ i +'@akamai.com','Test Deptt.','Test Division'
    		                        ,'tUserS'+ i, 'UTF-8','en_US'
    		                        ,'en_US','America/Los_Angeles','testUser11'+ i +'@akamai.com',userProfile.Id,userRole.Id);
    		userListdelegation.add(newUser);
    		userList.add(newUser);
    	}
       	
       for(Integer i=0;i<memberList.size();i++)
    	{
    		User newUser=createUser('Test','User'+i,'Engineering','TestBusiness Unit'
    		                        ,3243,322,'testUser'+ i +'@akamai.com','Test Deptt.','Test Division'
    		                        ,'tUser'+ i, 'UTF-8','en_US'
    		                        ,'en_US','America/Los_Angeles','testUser'+ i +'@akamai.com',userProfile.Id,userRole.Id);
    		userListglobal.add(newUser);
    		userList.add(newUser);
    	}
    	
    	insert userList;
    	for(Integer i=0;i<memberList.size();i++)
    	{
    		memberList[i].Approver__c=userListglobal[i].Id;
    	}
    	for(Integer i=0;i<standingDelmemberList.size();i++)
    	{
    		standingDelmemberList[i].Delegate_Approver__c=userListdelegation[i].Id;
    		standingDelmemberList[i].StandingDelegationCheck__c = true;
    	}
    	
    	List<Launch_Item_Approval__c> deleteExistingLaunchItemApproval=[select Id from Launch_Item_Approval__c where Global_Setting_Id__c =null     and Launch_Item__c =null];
      	if(deleteExistingLaunchItemApproval!=null && deleteExistingLaunchItemApproval.size()>0)
      	{
      		delete deleteExistingLaunchItemApproval;
      	}
      	
      	
      	
    	for(Launch_Item_Approval__c lia : standingDelmemberList)
    	memberList.add(lia);
    	insert memberList;
    	//insert standingDelmemberList;
       return memberList;
    }
    
   
	public static User createUser(String firstName,String lastName,String title, String businessUnitName
                                  ,Double businessUnitNo,Double costCenter,String email,String dept,String division
                                  ,String alias, String emailEncodingKey, String languageLocalekey
                                  ,String localSidKey,String timeZoneSidKey, String userName,String profileId, String roleId)
    {
      User newtestUser=new User();
      newtestUser.FirstName=firstName;
      newtestUser.LastName=lastName;
      newtestUser.Title=title;
      newtestUser.Business_Unit_Name__c=businessUnitName;
      newtestUser.Business_Unit_Number__c=businessUnitNo;
      newtestUser.Email=email;
      newtestUser.Cost_Center__c=costCenter;
      newtestUser.Department=dept;
      newtestUser.Division=division;
      newtestUser.Alias=alias;
      newtestUser.emailencodingkey=emailEncodingKey;
      newtestUser.languagelocalekey=languageLocalekey;
      newtestUser.localesidkey=localSidKey;
      newtestUser.timezonesidkey=timeZoneSidKey; 
      newtestUser.username=userName;
      newtestUser.ProfileId=profileId;
      newtestUser.UserRoleId=roleId;
      return newtestUser;
    }
  
}