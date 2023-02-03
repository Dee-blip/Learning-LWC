/***************************************************************************
 * Name             : ACD2_UtilClass
 * Created By       : Himanshu,Vamsee,Sharath
 * Created Date     : 07-Jul-2020
 * Purpose          : Util Class for all ACD Webservices
 * Test Class		: ACD2_Webservices_Test
 
 Last Modified BY   		Last Modified Date  Purpose
 ----------------   		------------------  ---------
 Himanshu,Vamsee,Sharath		07-Jul-2020			Initial Development
 Sharath                        22 Feb 2021        ACD user automation
Sharath							27 May 2021			Automation from SR
 ****************************************************************************/

public without sharing class ACD2_UtilClass {

    /* Method - 1 : For getting Account Geo. If Geo of all the accounts are same then return the geo value
     * Otherwise null */
    public Static String getAkaTecGeo(List<Account> accountList){
        Set<String> allGeos = new Set<String>();
        for(Account eachAccount: accountList){
            allGeos.add(eachAccount.Akatec_Geography__c);
        }
        if(allGeos.size() == 1)
            return accountList[0].Akatec_Geography__c;
        return null;
    }
    
    // Method - 2 : Getting VIP users
    public static Map <String,Boolean> checkForVIPUser(List<User> Users){
    		// return Map
        	Map <String,Boolean> userToVIPMap = new Map <String,Boolean>();
            
        	// Set to Store all VIP Users from - Public Group
            Set<String> vipUserIds = new Set<String>();
        
        	// Step - 1 : Set to Store all VIP Users from - custom setting HD_VIP_Titles__c    
            Set<String> vipTitles = HD_VIP_Titles__c.getAll().keySet();
            
            // Step - 2 : Getting All VIP Users from group
            for(GroupMember  groupMemberRec : [SELECT UserOrGroupid FROM GroupMember 
                                                WHERE groupid = '00GG0000002h8GS' AND UserOrGroupid in :Users]){
                   vipUserIds.add(groupMemberRec.UserOrGroupid);
            }
        	
        	// Step - 3 : Loop for all Incoming Users
        	Boolean isVIP = false;

        	for(User userRec: Users){
                isVIP = false;
                //User Title check. Check if the User title contains one of the Custom setting values
                if(userRec.Title != null){
                    for(String vipTitle : vipTitles){
                        if(userRec.Title.containsIgnoreCase(vipTitle)){
                            isVIP = true;
                            break;
                        }
                    }
                }
                else if(vipUserIds.contains(userRec.Id)){
                    isVIP = true;
                }
                
                userToVIPMap.put(userRec.Id,isVIP);
            }
        	return userToVIPMap;
    }
    
    // Method - 3 : Getting Premium Account details
    public static string isPremiumAccountCheck(List<Id> AccountIdList){
    
    	string supportTeamType;
    	
        // Get the Support Team Type to Check the Premium or not
    	for(TS_TeamAccount__c eachSupportAccount : [SELECT TS_Support_Team__r.Team_Type__c FROM TS_TeamAccount__c 
    												WHERE Team_Account__c IN :AccountIdList]){
    		supportTeamType = eachSupportAccount.TS_Support_Team__r.Team_Type__c;
            if(supportTeamType != null && supportTeamType.containsIgnoreCase('geo-p')){
                return 'true';
            }
    	}
    	
    	return 'false';
    }
    
    // Method - 4 : Getting all Products for an Account
    public static List<string> getAllProducts (List<Id> AccountIdList){
    
    	set<string> allProducts = new set<string>();
    	
    	
    	// Step - 1 : Get Support Team Member
    	for(TS_TeamMember__c eachMember : [SELECT Team_Member__r.ACD2_Support_Team_Skill__c FROM TS_TeamMember__c 
    										WHERE TS_Support_Team__c IN (SELECT TS_Support_Team__c FROM TS_TeamAccount__c WHERE Team_Account__c IN :AccountIdList)
                                            AND Team_Member__r.isActive = True AND Team_Member__r.ACD2_Support_Team_Skill__c != null AND 
                                          	Role__c IN ('Technical Support - Primary','Technical Support - Secondary')]){
    										
    			if(eachMember.Team_Member__r.ACD2_Support_Team_Skill__c.containsIgnoreCase('Media'))
    				allProducts.add('Media');    			
    			if(eachMember.Team_Member__r.ACD2_Support_Team_Skill__c.containsIgnoreCase('Enterprise'))
    				allProducts.add('Enterprise');
    			if(eachMember.Team_Member__r.ACD2_Support_Team_Skill__c.containsIgnoreCase('Web Experience'))
    				allProducts.add('Web Experience');
                                                
    	}
    	system.debug('--allProducts--'+allProducts);
    	return new List<String>(allProducts);
    }
    
    // Method - 5 : Get the Geography corresponding to the country code
    public static string getCountryCodeGeo (String aniString)
    {
        string geography;
        //query the ACD util metadata and get all the country code records
        List<ACD_Utility__mdt> utilities = [SELECT Id, Name__c, Num_Value__c, Value__c FROM ACD_Utility__mdt 
         								   WHERE DeveloperName  LIKE 'Country_Code%' and Name__c != null and 
                                           Num_Value__c != null ORDER BY Num_Value__c DESC];
        system.debug('utilities: ' + utilities.size());
        for(ACD_Utility__mdt utilityRec : utilities){
        //for(ACD_Utility__mdt utilityRec : [SELECT Id, Name__c, Num_Value__c, Value__c FROM ACD_Utility__mdt 
        // 								   WHERE DeveloperName  LIKE 'Country_Code%' and Name__c != null and 
        //                                              Num_Value__c != null ]){
            //system.debug('Id : ' + utilityRec.Id + 'utilityRec.name: ' + utilityRec.Name__c + ' utilityRec.Num_Value__c ' + utilityRec.Num_Value__c);
             if(aniString.startsWith(utilityRec.Name__c.trim()) || aniString.startsWith(String.valueOf(Integer.valueOf(utilityRec.Num_Value__c)).trim())){
             //if(aniString.startsWith(utilityRec.Name__c.trim()) ){
                geography = utilityRec.Value__c;
                break;
            }
        }
        //if the country code mapping is not found, return unknown
        geography = geography == null ?'Others':geography;
        return geography;
    }
    
    //Method - 6: List of Top 10 Technical Primary / Secondary / Others tagged to the account
    public static List<String> getTechnicalSupportTeam(String accountId){
        
        List<String> supportTeamIdList = new List<String>();
        for(TS_TeamMember__c eachTeamMember :[SELECT Team_Member__r.Alias FROM TS_TeamMember__c WHERE TS_Support_Team__c IN 
                                             	(SELECT TS_Support_Team__c FROM TS_TeamAccount__c WHERE Team_Account__c = :accountId) 
                                             	ORDER BY ACD2_Support_Order__c LIMIT 10]){
       		supportTeamIdList.add(eachTeamMember.Team_Member__r.Alias);
		}
        return supportTeamIdList;
    }
    
    //Method - 7: This will send the error mails out to the Dev team
    public static void sendErrorMail(String input, String errorMessage,String stackTrace, String subject)
    {
        if(errorMessage == '')
        {
          	return;
        }
        List<ACD_Utility__mdt> utilities = [SELECT Value__c FROM ACD_Utility__mdt 
        WHERE DeveloperName = 'ACD_Dev_Email' and Value__c != null limit 1];

        String emailAddress = utilities != null && utilities.size() == 1? utilities.get(0).Value__c : 'services-engg@akamai.com';
        List<String> toAddresses = new List<String>{emailAddress};
        String Body = 'Hi Team'+ ',<br/><br/> An Exception occured in ACD 2.0 Web Services.<br/><br/>';
        Body += 'Instance = ' + URL.getSalesforceBaseUrl().toExternalForm() + '<br/>';
        Body += 'Input Parameter(s): ' + input + '<br/>';
        Body += 'ErrorMessage: ' + errorMessage + '<br/><br/>';
        Body += 'StackTrace: ' + stackTrace;
        Messaging.SingleEmailMessage[] mailsToBeSent = new List<Messaging.SingleEmailMessage>();
        Messaging.Singleemailmessage objEmail;
        objEmail = new Messaging.Singleemailmessage();
        objEmail.setReplyTo('noreply@akamai.com');
        objEmail.setToAddresses(toAddresses);            
        objEmail.setSubject(subject);
        objEmail.setHTMLBody( Body );
        mailsToBeSent.add(objEmail);
        Messaging.sendEmail(mailsToBeSent,false);        
    }
    
    // Method - 8 : Create ACD log
    public static void createLog(String callGUID, String webserviceName, String inputString,String response, String status, DateTime requestReceivedTime)
    {
        Integer responseTime = math.abs(Datetime.now().millisecond() - requestReceivedTime.millisecond());  
		ACD2_Logs__c logRecord = new ACD2_Logs__c(Call_GUID__c = callGUID, 
                                                  Input_String__c= inputString, 
                                                  Response__c= response, 
                                                  Webservice_Name__c = webserviceName, 
                                                  Status__c = status,
                                                  Response_Time_Millisecond__c = responseTime);
		Insert logRecord;
    }
     
    public static String prepareANI (String ANI)
    {
        String inputANI = ANI;
        List<ACD_Utility__mdt> utilities = [SELECT Value__c FROM ACD_Utility__mdt 
         								   WHERE DeveloperName  LIKE 'ANI_Patterns%' 
                                            and Value__c != null];
        for(ACD_Utility__mdt utilityRec : utilities)
        {
            for (String pattern : utilityRec.Value__c.split(','))
            {
                if(inputANI.startsWith(pattern) || inputANI.startsWith('+' + pattern))
                {
                    inputANI = inputANI.replaceFirst(pattern, '');
                    break;
                }
            }
        }        
        return inputANI;
    }
    //Changes for ACD User Automation
    // @future
    // public static void createIndiaConfig(Set<String> userIdsToConsider)
    // {
    //     if(userIdsToConsider.isEmpty())
    //     {
    //         return;
    //     }
    //     Set<String> userIdSet = new Set<String>();
    //     userIdSet.addAll(userIdsToConsider);


    //     //get the india config Id
    //     Id indiaConfig = [select Id from cnx__Connects_Configuration__c where name = 'India Configuration'].Id;
    //     //Check for existing assignments
    //     for(cnx__Connects_Configuration_Assignment__c assignment: [select cnx__Assigned_User__c from cnx__Connects_Configuration_Assignment__c where cnx__Assigned_User__c in :userIdsToConsider 
    //                                                                 and cnx__Assigned_Connects_Configuration__c = :indiaConfig])
    //     {
    //         userIdSet.remove(assignment.cnx__Assigned_User__c);
    //     }
    //     //For the new users, create the assignment
    //     if(!userIdSet.isempty())
    //     {
    //         List<cnx__Connects_Configuration_Assignment__c> assignments = new List<cnx__Connects_Configuration_Assignment__c>();
    //         cnx__Connects_Configuration_Assignment__c assigmentRecord;
    //         for(Id userId: userIdSet)
    //         {
    //             assigmentRecord = new cnx__Connects_Configuration_Assignment__c();
    //             assigmentRecord.cnx__Assigned_Connects_Configuration__c = indiaConfig;
    //             assigmentRecord.cnx__Assigned_User__c = userId;
    //             assignments.add(assigmentRecord);
    //         }
    //         try
    //         {
    //             insert assignments;		
    //         }
    //         catch(Exception e)
    //         {
    //             ACD2_UtilClass.sendErrorMail(userIdSet.toString(),  e.getMessage(), e.getStackTraceString(),  'Error Assigning India Config' );
    //         }
    //     }
            

    // }
     
    // public static void setupACDUser(List<String> userIds)
    // {
	// 	//Get the User Info
    //     List<User> currentUsers = [Select id,Name, callcenterid,country from user where id in :userIds and isactive = true]; 
    //     //User Id set
    //     Set<Id> userIdSet = new Set<Id>();

    //     List<User> usersToUpdate = new List<User>();

    //     //Temporary set
    //     Set<String> userIdsToConsider = new Set<String>();
        
    //     //fetch the call center Id from the custom metadata
    //     List<ACD_Utility__mdt> utilities = [SELECT Value__c FROM ACD_Utility__mdt WHERE DeveloperName = 'CallCenterId' limit 1];
    //     Id callCenterId = utilities != null && utilities.size() == 1 ? utilities.get(0).Value__c : null;

    //     //loop through the user records. If the country is india, consider for India config assignment
    //     //If the callcenter is not set, set and add to list for udpate
    //     for(User currentUser : currentUsers)
    //     {
    //         userIdSet.add(currentUser.Id);
    //         if(currentUser.country == 'India')
    //         {
    //             userIdsToConsider.add(currentUser.Id);
    //         }
    //         if(currentUser.callcenterid != callCenterId)
    //         {
    //             currentUser.callcenterid = callcenterid;
    //             usersToUpdate.add(currentUser);
    //         }
    //     }
        
        
    //     //Get the package license id
    //     Id packageLicenseId = [select Id from PackageLicense where NamespacePrefix = 'cnx' limit 1].Id;

    //     system.debug('PL: ' + packageLicenseId);
    //     //eliminate users who are assigned the license
    //     for(UserPackageLicense uPackageLicense : [select UserId from UserPackageLicense where PackageLicenseId = :packageLicenseId and UserId in :userIds])
    //     {
    //         userIdSet.remove(uPackageLicense.UserId);
    //     }
    //     //For the new users, assign the licenses
    //     if(!userIdSet.isEmpty())
    //     {
    //         List<UserPackageLicense> userPackageLicensesToInsert = new List<UserPackageLicense>();
    //         UserPackageLicense uPL;
    //         for(String userId : userIdSet)
    //         {
    //             uPL = new UserPackageLicense();
    //             uPL.UserId = userId;
    //             uPL.PackageLicenseId = packageLicenseId;	
    //             userPackageLicensesToInsert.add(uPL);
    //         }
    //         if(!userPackageLicensesToInsert.isEmpty())
    //         {
    //             try
    //             {
    //                 insert userPackageLicensesToInsert;                
    //             }
    //             catch(Exception e)
    //             {
    //                 ACD2_UtilClass.sendErrorMail(userIdSet.toString(),  e.getMessage(), e.getStackTraceString(),  'Error Assigning B+S License');
    //             }
    
    //         }
    //     }
    //     //Update user call centers        
    //     if(!usersToUpdate.isEmpty())
    //     {
    //         try
    //         {
	//             update usersToUpdate;	
    //         }
    //         catch(Exception e)
    //         {
    //             ACD2_UtilClass.sendErrorMail(usersToUpdate.toString(),  e.getMessage(), e.getStackTraceString(),  'Error Assigning Call Center' );
    //         }
    //     }

    //     if(!userIdsToConsider.isEmpty())
    //     {
    //         createIndiaConfig(userIdsToConsider);
    //     }

    // }  
    
    @InvocableMethod
    public static void createIndiaConfigFlow(List<String> idsToCreate)
    {
		callNonSetupFlowFuture(idsToCreate);
    }

    @future 
    public static void callNonSetupFlowFuture(List<String> idsToCreate)    
    {
            callNonSetupFlow(idsToCreate.get(0));    
    }

    @future 
    public static void callSetupFlowFuture(String userId)    
    {
            String result = callSetupFlow(userId);
            if(!result.containsIgnoreCase('success'))
            {
                ACD2_SetupAutomation.createIncidentRecord(userId);
            }
    }

    public static String callNonSetupFlow(String userId)    
    {
        Flow.Interview.ACD_User_Automation_non_Setup  myFlow = new Flow.Interview.ACD_User_Automation_non_Setup(new Map<String, Object>{'userId'=>userId});     
        myFlow.start();

        String result= (String) myFlow.getVariableValue('Result');
        String message= (String) myFlow.getVariableValue('Message');
        if(!result.containsIgnoreCase('success'))
        {
        	sendErrorMail(userId,result ,message,'ACD User Setup Automation');    
        }        
        return result;        

    }
    public static String callSetupFlow(String userId)    
    {
        Flow.Interview.ACD_User_Setup_Automation  myFlow = new Flow.Interview.ACD_User_Setup_Automation(new Map<String, Object>{'userId'=>userId,'indiaCheckNeeded'=>false});     
        myFlow.start();

        String result= (String) myFlow.getVariableValue('resultString');
        String message= (String) myFlow.getVariableValue('message');
        if(!result.containsIgnoreCase('success'))
        {
        	sendErrorMail(userId,result ,message,'ACD User Setup Automation');    
        }        
        return result;
        
    }

    public static Boolean recursion = false;
    public static String setupUserForACD(String userId)
    {
        String result = '';
        if(!recursion)
        {
            result = callNonSetupFlow(userId);
            callSetupFlowFuture(userId);    
            recursion = true;
        }
        return result;
    }
    
}