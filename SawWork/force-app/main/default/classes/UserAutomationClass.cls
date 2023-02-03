/***
    UserAutomationClass
    @author : Chandra Lohani <clohani@akamai.com>
    @Description : This class implements following logic to automate user inactivation process
    			 - User not logged in for last 60 days (defined in Custom settings) and atleast last password change or reset happened
    				  60 days ago
    
	@History
	--Developer		      --Date			--Change
	Chandra Lohani		13/10/2010          Created the class.
	Chandra lohani      02/11/2010          Added a method 'assignProfileAndRole' which will be called by
	                                        a trigger to assign default role and profile to Users
	Ali KM				08/12/2010			CR 870797 Change Contact.Owner to ONA when Users turn Inactive
											- For this CR we have @future method on Account_ai.Trigger
											- Inorder to avoid @future to @future exception commenting out '@future' in below method
												-> InactivateUsers()
    Chandra Lohani      30/12/2010			- logic for inactivating users commented. 
    
    Chandra Lohani      11/01/2011          - Added an overloaded assignProfileAndRole which takes four parameters 
                                              to accomodate logic for automatic User role and profile updation.
                                              Whenever a User_Role_Profile_Map__c object is inserted/updated, User_Role_Profile_Map_ai_au trigger will 
                                              which will call @future function "updateUserRoleProfile" which runs asynchronously and update all matching
                                              users role and profile.
    Chandra Lohani      17/01/2011          - Commented the code.                                               									                                         
	
*/
global class UserAutomationClass { //implements Schedulable{
	
	//private static Inactivate_User_Class_Settings__c customSettings = Inactivate_User_Class_Settings__c.getInstance('v1.0');
	//private static UserAutomationClassSettings__c customSettings = UserAutomationClassSettings__c.getInstance('v1.0'); 
	//private List<User> users= null;
	//private List<User_Role_Profile_Map__c> roleProfileMapList=null;
	//private List<Account_Reassignment_Rule__c> userRules=null;
		 
	
	/**
	 Constructor to be called for Scheduled job for inactivation of users 
	
	
	public UserAutomationClass(String flag)
	{  
	  	if(flag.equals('Inactivate'))
	  	{
		  	Date dateForPwdChange=Date.today().addDays(-1*Integer.valueOf(customSettings.No_Of_Days_For_Pwd_Reset__c));
			Date dateForLogin=Date.today().addDays(-1*Integer.valueOf(customSettings.No_Of_Days_For_Login__c));
			users=[select Id,isActive,Email 
			                         from User 
			                         where LastPasswordChangeDate < :dateForPwdChange 
			                         and LastLoginDate < :dateForLogin
			                         and isActive=true
			                         and Never_Inactivate__c = false
			                         //and profileId not in (select id from profile where Name in ('CRM Integration','System Administrator'))
			                         order  by LastLoginDate];
	  	}
	  	
	}
	
	public UserAutomationClass(List<String> Ids)
	{
	      roleProfileMapList=[select Id
	                                 ,Title__c
	                                 ,Division__c
	                                 ,Department__c
	                                 ,Cost_Center__c
	                                 ,Business_Unit__c
	                                 ,Business_Unit_Number__c
	                                 ,Default_Profile__c
	                                 ,Default_Role__c from User_Role_Profile_Map__c 
	                                 where Id IN :Ids];	                                                                
		  Set<String> userIdSet=new Set<String>();
		  Set<String> userTitleSet= new Set<String>();
	      Set<String> userDivisionSet=new Set<String>();
	      Set<String> userDeptSet=new Set<String>();
	      Set<String> userBUSet=new Set<String>();
	      Set<Double> userCCSet=new Set<Double>();
	      Set<Double> userBUNoSet=new Set<Double>();
			for(User_Role_Profile_Map__c roleProfileMap : roleProfileMapList)
		   {
			userTitleSet.add(roleProfileMap.Title__c);
			userDivisionSet.add(roleProfileMap.Division__c);
			userDeptSet.add(roleProfileMap.Department__c);
			userBUSet.add(roleProfileMap.Business_Unit__c);
			userCCSet.add(roleProfileMap.Cost_Center__c);
			userBUNoSet.add(roleProfileMap.Business_Unit_Number__c);		
		   }
		  users = [SELECT Id,FirstName,LastName, Title, Division, Department, Cost_Center__c, Business_Unit_Number__c, Business_Unit_Name__c, Manual_Change__c
	  	 	                                      FROM User WHERE Title IN :userTitleSet
	  	 	                                                AND Division IN :userDivisionSet
	  	 	                                                AND Department IN :userDeptSet
	  	 	                                                AND Cost_Center__c IN :userCCSet
	  	 	                                                AND Business_Unit_Number__c IN :userBUNoSet
	  	 	                                                AND Business_Unit_Name__c IN :userBUSet];
          for(User userId : users)
          {
          	userIdSet.add(userId.Id);
          }	  	 	                                                
          userRules=[select Id,associated_user__c from Account_Reassignment_Rule__c 
      	                                                 where associated_user__c IN :userIdset];
               	                                                 	  	 	                                                
	   	 	                                                
	}
	/**
	Constructor
	
	public UserAutomationClass()
	{
		
	}
	
	public List<User> getUsers()
	{
		return this.users;
	}
	public List<Account_Reassignment_Rule__c> getUserRules()
	{
		return this.userRules;
	}
	public List<User_Role_Profile_Map__c> getRoleProfileMapList()
	{
		return this.roleProfileMapList;
	}
	/**
	   updateUsers()
	   - This method inactivate users available for inactivation  
		
	public void updateUsers()
	{
	  	String subject='Exception Occurred while inactivating user';
        String message='';
	  	if(users!=null && users.size()>0)
	  	{
	  		for(User user : users)
	  		    {
 	  			  //user.email='a@akamai.com';
 	  			  user.isActive=false;
	  		    }
	  		Database.SaveResult[]  results=Database.update(users,false);
	  		Integer i=0;	
	  		for(Database.SaveResult sr:results)
	  		{   
	  			if(!sr.isSuccess())
	  			{   String Id=users[i].Id;
	  				message=message+sr.getErrors()[0]+' SF ID: '+Id+'\n';
	  			}
	  			i++;
	  		}
	  		if(message!=null && !message.equals(''))
	  		{	
	  		 sendEmail(subject,message);
	  		}
	  		     		    
 	  	}
	  	
	}
	
	/**
	   InactivateUsers()
	   - This method Creates an instance of Userautomation Class and calls UpdateUsers method  
	   - Runs asynchronously (@future).
	
	// AliKM commenting below line to avoid @future to @future recursive calls.
	//@future
	public static void inactivateUsers()
	{
		UserAutomationClass userAutoClass= new UserAutomationClass('Inactivate');
		userAutoClass.updateUsers();
	}
  /**
   This is the entry point for Scheduler
  	
	global void execute(SchedulableContext sc)
  {
    UserAutomationClass.inactivateUsers();
  }
  */
  /**
  This method is used for automated profile and role assignment of user
   
  public void assignProfileAndRole(List<User> usersToUpdate)
  {
    Set<String> userIdSet=new Set<String>();                             
    Set<String> userTitleSet= new Set<String>();
    Set<String> userDivisionSet=new Set<String>();
    Set<String> userDeptSet=new Set<String>();
    Set<String> userBUSet=new Set<String>();
    Set<Double> userCCSet=new Set<Double>();
    Set<Double> userBUNoSet=new Set<Double>();
    Set<String> defaultRoleNameSet=new Set<String>();
    Set<String> defaultProfileNameSet=new Set<String>();
    Map<String, User_Role_Profile_Map__c>  objectMap=new Map<String, User_Role_Profile_Map__c>();
    Map<String, Id> roleIdMap=new Map<String,Id>();
    Map<String,Id> profileIdMap=new Map<String,Id>();
 	String subject='Error while updating user Role and Profile';
    String message='';
      
     //Adding user details into set
    
    for(User user: usersToUpdate)
     {
     	userIdset.add(user.Id);
        userTitleSet.add(user.Title);
        userDivisionSet.add(user.Division);
        userDeptSet.add(user.Department);
        userBUSet.add(user.Business_Unit_Name__c);
        userCCSet.add(user.Cost_Center__c);
        userBUNoSet.add(user.Business_Unit_Number__c);
     }
     // Creating user role profile map list which exists for user details stored in Set
     List<User_Role_Profile_Map__c> roleProfileMapList=[select Id,Division__c,Department__c,Cost_Center__c,Business_Unit__c
                                                               ,Business_Unit_Number__c,Title__c,Default_Role__c,Default_Profile__c 
    	                                                From User_Role_Profile_Map__c
    	                                                where Division__c IN :userDivisionSet
    	                                                 and  Department__c IN :userDeptSet
    	                                                 and  Cost_Center__c IN :userCCSet
    	                                                 and  Business_Unit__c IN :userBUSet
    	                                                 and  Business_Unit_Number__c IN :userBUNoSet
    	                                                 and  Title__c IN :userTitleSet];
 // checking whether any Account_reassignment_rule exists for user	    	                          	                                                 
    List<Account_Reassignment_Rule__c> userRules=[select Id,associated_user__c from Account_Reassignment_Rule__c 
      	                                                 where associated_user__c IN :userIdset]; 
    assignProfileAndRole(usersToUpdate,roleProfileMapList,userRules,false);      	                                                    	                                                 
    
 }
 
 
 public void assignProfileAndRole(List<User> usersToUpdate, List<User_Role_Profile_Map__c> roleProfileMapList,List<Account_Reassignment_Rule__c> userRules, Boolean isUserToUpdate)
 {
 	Set<String> defaultRoleNameSet=new Set<String>();
    Set<String> defaultProfileNameSet=new Set<String>();
    Map<String, User_Role_Profile_Map__c>  objectMap=new Map<String, User_Role_Profile_Map__c>();
    Map<String, Id> roleIdMap=new Map<String,Id>();
    Map<String,Id> profileIdMap=new Map<String,Id>();
 	String subject='Error while updating user Role and Profile';
    String message='';
 	// Creating Map of roleProfilemapping object and unique mappingkey and also creating role and porfile name set          	                                                 
    for(User_Role_Profile_Map__c roleProfileMap: roleProfileMapList)
    {
    	String mappingKey=roleProfileMap.Division__c+'#'+roleProfileMap.Department__c+'#'+roleProfileMap.Cost_Center__c.intValue()+'#'+roleProfileMap.Business_Unit__c+'#'+roleProfileMap.Business_Unit_Number__c.intValue()+'#'+roleProfileMap.Title__c;
    	objectMap.put(mappingKey,roleProfileMap);
    	defaultRoleNameSet.add(roleProfileMap.Default_Role__c);
    	defaultProfileNameSet.add(roleProfileMap.Default_Profile__c);
    }
    
    List<UserRole> roleIds=[Select Id,Name from UserRole 
	    	                         where Name IN :defaultRoleNameSet];
    // creating role Id map 
    for(UserRole roleId :roleIds )
    {
    	roleIdMap.put(roleId.Name,roleId.Id);
    }
   
	List<Profile> profileIds=[Select Id,Name from Profile 
	    	                         where Name IN :defaultProfileNameSet] ;
     // creating profile Id map
     for(Profile profileId : profileIds)
     {
     	profileIdMap.put(profileId.Name,profileId.Id);
     }
    
    for(User u: usersToUpdate)
    {
      Integer costCenter=u.Cost_Center__c.intValue();
      Integer buNo=u.Business_Unit_Number__c.intValue();
      //creating mapping key to retrieve roleprofile map from objectmap 
      String userMappingKey=u.Division+'#'+u.Department+'#'+costCenter+'#'+u.Business_Unit_Name__c+'#'+buNo+'#'+u.Title;	
      boolean accountReassignmentRuleExists=false;
      // checking whether this user has any account reassignment rule
      if(userRules.size()>0)
      {
      	for(Account_Reassignment_Rule__c rule: userRules)
      	{
      		if(rule.Associated_User__c==u.Id)
      		   accountReassignmentRuleExists=true;
      	}	
      }
      System.debug('accountReassignmentRuleExists  : '+ accountReassignmentRuleExists+ 'Manual change Flag '+ u.Manual_Change__c);
      // checking if manual change flag is set and account reassigment rule exists
     if(!u.Manual_Change__c)
       {
    	  User_Role_Profile_Map__c roleProfileMap=objectMap.get(userMappingKey);
    	 if(roleProfileMap !=null)
	     {  Id profileId=profileIdMap.get(roleProfileMap.Default_Profile__c);
	     	Id roleId=roleIdMap.get(roleProfileMap.Default_Role__c);
	     	System.debug('profileId  : '+ profileId+ 'roleId '+ roleId);
	     	if(profileId!=null)
	           {
	           	 u.ProfileId=profileId;
	           }
	           else
	           {
	           	message=message+'For user '+u.FirstName+' '+u.LastName+' Invalid profile \''+roleProfileMap.Default_Profile__c+'\' found for following fields in lookup Object:\n'+
    	          'Division: '+ u.Division +' Department: '+u.Department+' Cost Center: '+u.Cost_Center__c+' Business Unit Name: '+ u.Business_Unit_Name__c +' Business Unit Number: '+u.Business_Unit_Number__c+' Title: '+u.Title+'\n';
    	          //sendEmail(subject,message);	
	           }
	         if(roleId!=null)
	           {
	         	 if(!accountReassignmentRuleExists) {u.UserRoleId=roleId;}
	           }
	           else
	           {
	            //subject='Invalid role found in lookup object';
    	        message=message+'For user \''+u.FirstName+' '+u.LastName+'\' Invalid role \''+roleProfileMap.Default_Role__c+'\' found for following fields in lookup Object:\n'+
    	          'Division: '+ u.Division +' Department: '+u.Department+' Cost Center: '+u.Cost_Center__c+' Business Unit Name: '+ u.Business_Unit_Name__c +' Business Unit Number: '+u.Business_Unit_Number__c+' Title: '+u.Title+'\n';
    	          //sendEmail(subject,message);
	           }
	          
    	 }
    	 else
    	 {
    	  //subject='No mapping object found for the user';
    	  message=message+'For user \''+u.FirstName+' '+u.LastName+'\' No mapping found for following fields in lookup Object:\n'+
    	          'Division: '+ u.Division +' Department: '+u.Department+' Cost Center: '+u.Cost_Center__c+' Business Unit Name: '+ u.Business_Unit_Name__c +' Business Unit Number: '+u.Business_Unit_Number__c+' Title: '+u.Title+'\n';
    	   	
    	 }
    	    	                         
        }
    	                                                                                                
    }
    if(isUserToUpdate)
    {
      update users;
    }
    if(!message.equals('') && customSettings.sendMail__c)
     {
     	sendEmail(subject,message);
     }
 }
  
 /** Method is invoked by User_Role_Profile_Map_ai_au trigger 
     It will update Users which matches matches with User_role_Profile_map object inserted or updated
    
 
 @future
 public static void updateUserRoleProfile(String[] Ids)
{
	UserAutomationClass userAutomation=new UserAutomationClass(Ids);
	userAutomation.assignProfileAndRole(userAutomation.getUsers(),userAutomation.getRoleProfileMapList(),userAutomation.getUserRules(),true);
	
}
 /**
   method will send email email id updated in Inactivate_User_Class_Settings__c
 
 
  public void sendEmail(String subject, String message)
  {
  	    String[] toAddresses = new String[] {customSettings.EmailId__c};
	  	Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
		mail.setToAddresses(toAddresses);
        mail.setSubject(subject);
        mail.setBccSender(false);
        mail.setUseSignature(false);
        mail.setPlainTextBody(message);
        Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
  }
  */
}