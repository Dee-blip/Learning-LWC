/*
Author          : Harshil Soni
Description     : Main Controller Class for Support Team Management
Test Class		: SC_STM_Controller_TC

Date				Developer			JIRA #			Description                                                       
------------------------------------------------------------------------------------------------------------------
24-Nov-20			Harshil Soni		ACD-61			Support Team Management Lightning Homepage
------------------------------------------------------------------------------------------------------------------
*/
public without sharing class SC_STM_HomePageController {
    /*public SC_STM_HomePageController() {

    }*/


   /* @auraEnabled
    public static List<supportTeamByEmployeeWrapper> getSupportTeamByEmployeeList(String ManagerId){
        List<supportTeamByEmployeeWrapper> wrapperList = new List<supportTeamByEmployeeWrapper>();
        Map<String,SC_STM_SupportEmployee> userMap = new Map<String,SC_STM_SupportEmployee>(); 
        List<TS_TeamMember__c> userDetailsList = new List<TS_TeamMember__c>();
        List<User> userList = new List<User>();
        
        System.Debug('Parameter: ' + ManagerId);
        if(String.isNotEmpty(ManagerId)){
            System.Debug('with Manager');
            userDetailsList = [SELECT Team_Member__r.Id, TS_Support_team__c, Role__c,Team_Member__r.Username,Team_Member__r.Alias,Team_Member__r.FirstName, Team_Member__r.LastName, Team_Member__r.Email, Team_Member__r.Manager.Name,Team_Member__r.Office_Location__c,Team_Member__r.Shift__c,Team_Member__r.ACD2_Support_Team_Skill__c from TS_TeamMember__c WHERE Team_Member__r.ManagerId = :ManagerId AND Team_Member__r.Owner_Support_Department__c = 'Technical Support' order by Team_Member__r.FirstName];
        }
        else{
            System.Debug('without Manager');
            //userDetailsList = [SELECT Team_Member__r.Id, TS_Support_team__c, Role__c,Team_Member__r.Username,Team_Member__r.Alias,Team_Member__r.FirstName, Team_Member__r.LastName, Team_Member__r.Email, Team_Member__r.Manager.Name from TS_TeamMember__c where Team_Member__r.Support_Department__c='Technical Support' order by Team_Member__r.FirstName]; 
            userDetailsList = [SELECT Team_Member__r.Id, TS_Support_team__c, Role__c,Team_Member__r.Username,Team_Member__r.Alias,Team_Member__r.FirstName, Team_Member__r.LastName, Team_Member__r.Email, Team_Member__r.Manager.Name,Team_Member__r.Office_Location__c,Team_Member__r.Shift__c,Team_Member__r.ACD2_Support_Team_Skill__c from TS_TeamMember__c WHERE Team_Member__r.Owner_Support_Department__c = 'Technical Support' order by Team_Member__r.FirstName]; 
        }
         
        AggregateResult[] grpResults = [SELECT TS_Support_Team__c, COUNT(Team_Account__c) accCount from TS_TeamAccount__c group by TS_Support_Team__c];
        Map<String, integer> supportTeamAccMap = new Map<String, integer>();
         
         for(AggregateResult result : grpResults){ 
             supportTeamAccMap.put((String)result.get('TS_Support_Team__c'),(integer)result.get('accCount'));
         }
         System.Debug('size: ' + userDetailsList.size());
        for(integer i=0;i<userDetailsList.size();i++){
            String userId = userDetailsList.get(i).Team_Member__r.Id;  
            String roleType = userDetailsList.get(i).Role__c;
            String supportTeamId = userDetailsList.get(i).TS_Support_team__c;
            SC_STM_SupportEmployee supportEmployee = new SC_STM_SupportEmployee();
            integer supportPrimary = 0; integer supportSecondary = 0; integer supportOthers = 0;
            String supportPrimryId = ''; String supportScndryId=''; String supportOtherId='';
            
            if(roleType.equals('Technical Support - Primary')){
               supportPrimary = supportPrimary+1; 
               supportPrimryId = supportTeamId;
             }       
            else if(roleType.equals('Technical Support - Secondary')){
                supportSecondary = supportSecondary+1;
                supportScndryId = supportTeamId;
               
            }        
            else if(roleType.equals('Technical Support - Other')){
                supportOthers = supportOthers+1;
                supportOtherId = supportTeamId;
               
            }      
            if(userMap.get(userId)!=null){
                 supportEmployee = userMap.get(userId);
                 supportEmployee.setPrimarySupport(supportEmployee.getPrimarySupport()+supportPrimary);   
                 supportEmployee.setSecondarySupport(supportEmployee.getSecondarySupport()+supportSecondary);   
                 supportEmployee.setOtherSupport(supportEmployee.getOtherSupport()+supportOthers); 
                 if(!supportPrimryId.equals('')){
                   Set<String> prmrySupport = supportEmployee.getPrimarySupportIds();
                   prmrySupport.add(supportPrimryId);
                   supportEmployee.setPrimarySupportIds(prmrySupport);
                }  
                
                 if(!supportScndryId.equals('')){
                    //System.debug('Secondary not null');
                    Set<String> secdrySupport = supportEmployee.getSecondarySupportIds();
                    secdrySupport.add(supportScndryId);
                    supportEmployee.setSecondarySupportIds(secdrySupport);
               }
                
               if(!supportOtherId.equals('')){        
                   Set<String> othersSupport = supportEmployee.getOtherSupportIds();
                   othersSupport.add(supportOtherId);
                   supportEmployee.setOtherSupportIds(othersSupport);
                } 
                // supportEmployee.setSecondarySupportIds(supportEmployee.getSecondarySupportIds().add(supportScndryId));
                userMap.put(userId,supportEmployee);
            }
            else{
                    
                    supportEmployee = new SC_STM_SupportEmployee();
                    supportEmployee.setPrimarySupport(supportPrimary);   
                    supportEmployee.setSecondarySupport(supportSecondary);   
                    supportEmployee.setOtherSupport(supportOthers);   
                
                   if(!supportPrimryId.equals('')){                                  
                       Set<String> prmrySupport = new Set<String>();
                       prmrySupport.add(supportPrimryId);
                       supportEmployee.setPrimarySupportIds(prmrySupport);
                   }      
                
                    if(!supportScndryId.equals('')){                  
                        Set<String> secdrySupport = new Set<String>();
                        secdrySupport.add(supportScndryId);
                        supportEmployee.setSecondarySupportIds(secdrySupport);
                   }
                
                
                   if(!supportOtherId.equals('')){
                    //System.debug('Others not null');
                       Set<String> othersSupport = new Set<String>();
                       othersSupport.add(supportOtherId);
                       supportEmployee.setOtherSupportIds(othersSupport);
                       }
                    User user = new User();
                    user.Id = userDetailsList.get(i).Team_Member__r.Id;
                    user.Username = userDetailsList.get(i).Team_Member__r.Username;
                    user.FirstName = userDetailsList.get(i).Team_Member__r.FirstName;
                    user.LastName = userDetailsList.get(i).Team_Member__r.LastName;
                    user.Email = userDetailsList.get(i).Team_Member__r.Email;
                    user.Alias = userDetailsList.get(i).Team_Member__r.Alias;
                    user.Manager = userDetailsList.get(i).Team_Member__r.Manager;
                    user.Office_Location__c = userDetailsList.get(i).Team_Member__r.Office_Location__c;
                    user.Shift__c = userDetailsList.get(i).Team_Member__r.Shift__c;
                    user.ACD2_Support_Team_Skill__c = userDetailsList.get(i).Team_Member__r.ACD2_Support_Team_Skill__c;
                    
                    supportEmployee.setUser(user);
                    
                    userMap.put(userId,supportEmployee);
           
            }
         }
   
        for(String id : userMap.keySet()){
             
           SC_STM_SupportEmployee supportEmployee = userMap.get(id);
           integer noOfAccPrimary = 0; integer noOfAccSecondary = 0; integer noOfAccOthers = 0;  
             
             if(supportEmployee.getPrimarySupportIds()!=null && supportEmployee.getPrimarySupportIds().size()>0)   {
                 for(String primarySupportId : supportEmployee.getPrimarySupportIds()){
                     if(supportTeamAccMap.get(primarySupportId)!=null){                  
                       noOfAccPrimary = noOfAccPrimary+supportTeamAccMap.get(primarySupportId);
                    }
                 }
             }     
             
             if(supportEmployee.getSecondarySupportIds() !=null && supportEmployee.getSecondarySupportIds().size()>0)   {
                 for(String secondarySupportId : supportEmployee.getSecondarySupportIds()){
                     if(supportTeamAccMap.get(secondarySupportId)!=null){
                       noOfAccSecondary = noOfAccSecondary+supportTeamAccMap.get(secondarySupportId);
                    }
                 }
             }  
             
             if(supportEmployee.getOtherSupportIds() !=null && supportEmployee.getOtherSupportIds().size()>0)   {
                 for(String otherSupportId : supportEmployee.getSecondarySupportIds()){
                     if(supportTeamAccMap.get(otherSupportId)!=null){
                       noOfAccOthers = noOfAccSecondary+supportTeamAccMap.get(otherSupportId);
                    }
                 }
             }  
             supportEmployee.setPrimaryAccCount(noOfAccPrimary);
             supportEmployee.setSecondaryAccCount(noOfAccSecondary);
             supportEmployee.setOtherAccCount(noOfAccOthers);
             userMap.put(id, supportEmployee);
             
         }
         if(String.isNotEmpty(ManagerId)){
            userList = [SELECT Id, Username, FirstName, LastName, Email, Alias, Manager.Name,Office_Location__c,Shift__c,ACD2_Support_Team_Skill__c from User  where Owner_Support_Department__c = 'Technical Support' and Id not in :userMap.keySet() and ManagerId = :ManagerId];
         }else{  
            userList = [SELECT Id, Username, FirstName, LastName, Email, Alias, Manager.Name,Office_Location__c,Shift__c,ACD2_Support_Team_Skill__c from User  where Owner_Support_Department__c = 'Technical Support' and Id not in :userMap.keySet()];
         }   
         for(User user : userList){
           SC_STM_SupportEmployee supportEmployee = new SC_STM_SupportEmployee();
           supportEmployee.setPrimarySupport(0); supportEmployee.setSecondarySupport(0);
           supportEmployee.setOtherSupport(0); supportEmployee.setPrimaryAccCount(0);
           supportEmployee.setSecondaryAccCount(0); supportEmployee.setOtherAccCount(0);
           supportEmployee.setUser(user);
           userMap.put(user.Id, supportEmployee);
         }
   
        // SC_STM_SupportEmployee supportEmployee = userMap.get('005A0000000MuunIAC');

         if(userMap.keySet().size() > 0){
             for(String iteratedKey : userMap.keySet()){
                supportTeamByEmployeeWrapper sampleWrapperRec = new supportTeamByEmployeeWrapper();
                SC_STM_SupportEmployee se = userMap.get(iteratedKey);
                sampleWrapperRec.keyVal = iteratedKey;
                
                
                sampleWrapperRec.alias = se.user.Alias;
                sampleWrapperRec.firstName = se.user.FirstName;
                sampleWrapperRec.lastName = se.user.LastName;
                
                sampleWrapperRec.email = se.user.Email;
                sampleWrapperRec.officeLocation = se.user.Office_Location__c;
                sampleWrapperRec.ownerShift = se.user.Shift__c;
                sampleWrapperRec.managerName = se.user.Manager.Name;
                sampleWrapperRec.primarySupport = se.primarySupport;
                sampleWrapperRec.secondarySupport = se.secondarySupport;
                sampleWrapperRec.otherSupport = se.otherSupport;
                sampleWrapperRec.primaryAccCount = se.primaryAccCount;
                sampleWrapperRec.secondaryAccCount = se.secondaryAccCount;
                sampleWrapperRec.employeeId = '/'+iteratedKey;
                sampleWrapperRec.supportTeamSkill = se.user.ACD2_Support_Team_Skill__c;
                
                wrapperList.add(sampleWrapperRec);
             }
         }
         System.Debug(wrapperList);
         return wrapperList;
        
         
     }*/
     
    //................Functionality for Support Team By Employee Tab...........................

    //Method - 1 : Method to get data for Support Teams by Employee Tab
    //Called in LWC - scSTMEmpBubbles
    @auraEnabled
    public static string getSupportTeamByEmployeeList(){
    
        supportTeamByEmployeeWrapper returnWrapperList = new supportTeamByEmployeeWrapper();
        returnWrapperList.isManager = checkIsManager();

        
    	// Initializing Return Wrapper
    	List<employeeWrapper> employeeWrapperList = new List<employeeWrapper>();
    	employeeWrapper eachWrapperRec;
    	
    	// List to store All Account Team Role for Calculation
    	List<string> allAccountTeamRole = new List<string>{'Technical Support - Primary','Technical Support - Secondary'};
		string mapKey;
		
		// Map to store UserId - Support Team Role + Count 
		Map<string,integer> supportTeam_RoleCountMap = new Map<string,integer>();
		
		// Map to store UserId - Account Team Role + Count 
		Map<string,integer> accountTeam_RoleCountMap = new Map<string,integer>();
		
		// Step - 1 : Get List of Akatec Users
		List<User> getAllAkatecUserList = [SELECT Id, Username, FirstName, LastName, Email, Alias, ManagerId, Manager.Name,Office_Location__c,
									Shift__c,ACD2_Support_Team_Skill__c 
									from User  
									//where Owner_Support_Department__c = 'Technical Support' order by Alias];
									where Department Like '%AkaTec%' AND ManagerId != '' AND isActive = true order by Alias];
    
    	// Step - 2 : 2-Level Aggregate Query for Support Team Count
		for (AggregateResult ar : [select Team_Member__c STM,Role__c RoleType, count(id) 
									from TS_TeamMember__c 
									where Team_Member__c IN :getAllAkatecUserList and Role__c != null 
									group by Team_Member__c, Role__c
									order by Team_Member__c,Role__c])  {
	
			mapKey = string.valueOf(ar.get('STM')) + '-' + string.valueOf(ar.get('RoleType'));
			supportTeam_RoleCountMap.put(mapKey, Integer.valueOf(ar.get('expr0')));
	
	
		}
		
		// Step - 3 :  2-Level Aggregate Query for Account Team Count
		for (AggregateResult ar : [select Userid STM,TeamMemberRole RoleType, count(id) 
									from AccountTeamMember 
									where Userid IN :getAllAkatecUserList and TeamMemberRole != null and
									TeamMemberRole IN :allAccountTeamRole 
									group by Userid, TeamMemberRole
									order by Userid, TeamMemberRole])  {
	
			mapKey = string.valueOf(ar.get('STM')) + '-' + string.valueOf(ar.get('RoleType'));
			accountTeam_RoleCountMap.put(mapKey, Integer.valueOf(ar.get('expr0')));
	
	
		}
		
		// Step - 4 :  Loop to Iterate the for all Users
		for(User eachUserRec : getAllAkatecUserList) {
		
			eachWrapperRec = new employeeWrapper();
            eachWrapperRec.UserID = eachUserRec.Id;
            eachWrapperRec.UserUrl = '/' + eachUserRec.Id;
			eachWrapperRec.alias = eachUserRec.Alias;
			eachWrapperRec.firstName = eachUserRec.FirstName;
			eachWrapperRec.lastName = eachUserRec.LastName;
			eachWrapperRec.email = eachUserRec.Email;
            eachWrapperRec.ManagerId = eachUserRec.ManagerId;
			eachWrapperRec.managerName = eachUserRec.Manager.Name;
			eachWrapperRec.officeLocation = eachUserRec.Office_Location__c;
			eachWrapperRec.ownerShift = eachUserRec.Shift__c;
			eachWrapperRec.supportTeamSkill = eachUserRec.ACD2_Support_Team_Skill__c;
			
		
			eachWrapperRec.supportTeam_PrimaryCount = supportTeam_RoleCountMap.get(eachUserRec.Id + '-'+ 'Technical Support - Primary') != null ?
											supportTeam_RoleCountMap.get(eachUserRec.Id + '-'+ 'Technical Support - Primary') : 0;
			eachWrapperRec.supportTeam_SecondaryCount =supportTeam_RoleCountMap.get(eachUserRec.Id + '-'+ 'Technical Support - Secondary') != null ?
											supportTeam_RoleCountMap.get(eachUserRec.Id + '-'+ 'Technical Support - Secondary') : 0;
			eachWrapperRec.supportTeam_OtherCount = supportTeam_RoleCountMap.get(eachUserRec.Id + '-'+ 'Technical Support - Other') != null ?
											supportTeam_RoleCountMap.get(eachUserRec.Id + '-'+ 'Technical Support - Other') : 0;
			eachWrapperRec.accountTeam_PrimaryCount = accountTeam_RoleCountMap.get(eachUserRec.Id + '-'+ 'Technical Support - Primary') != null ?
											accountTeam_RoleCountMap.get(eachUserRec.Id + '-'+ 'Technical Support - Primary') : 0;
			eachWrapperRec.accountTeam_SecondaryCount = accountTeam_RoleCountMap.get(eachUserRec.Id + '-'+ 'Technical Support - Secondary') != null ?
											accountTeam_RoleCountMap.get(eachUserRec.Id + '-'+ 'Technical Support - Secondary') : 0;
											
			employeeWrapperList.add(eachWrapperRec);
		}

        returnWrapperList.employees = employeeWrapperList;
		
		return JSON.serialize(returnWrapperList);
    }

    //Method - 2 : Method to get support teams for an employee
    //Called in LWC - scSTMEmpBubbles
     @auraEnabled(cacheable=true)
     public static String getSupportTeams(Id userId){
        return JSON.serialize([select TS_Support_Team__c,Support_Team_Name__c,Support_Team_Type__c,Role__c 
        		from TS_TeamMember__c where Team_Member__c=:userId order by Support_Team_Name__c]);
    }

    //Method - 3 : Method to get associated accounts for a support team
    //Called in LWC - scSTMEmpBubbles
    @auraEnabled(cacheable=true)
    public static String getAssociatedAccounts(Id teamId){
       return JSON.serialize([SELECT Team_Account_Name__c, Team_Account_ERC__c, Team_Account_URL__c 
                              from TS_TeamAccount__c 
                              where TS_Support_Team__c=:teamId order by Team_Account_Name__C]);
   }

    //Method - 4 : Method to save support team skill
    //Called in LWC - scSTMEmpBubbles
    @auraEnabled
    public static String saveSupportTeamSkill(Id UserId, String skills ){
        try{
            User updateUser = new User(Id=UserId, ACD2_Support_Team_Skill__c = skills);
            Update updateUser;
            return 'success';
        }
        catch(Exception e){
            return e.getMessage();
        }

    }

    //Method - 5 : Method to check if logged in user is Manager
    //Called in LWC - scSTMEmpBubbles
    @AuraEnabled
    public static Boolean checkIsManager(){
        User u = [SELECT Id, Profile.Name FROM User WHERE Id = :Userinfo.getUserId()];
        return (u.Profile.Name == 'Support - Tech Support Manager' || u.Profile.Name == 'Support - Tech Support Manager with Customer Notification' ? true : false);
    }



    //................Functionality for Support Team Tab............................



    //Method - 6 : Method to get data for Support Teams tab
    //Called in LWC - scSTMSupportTeams
    @AuraEnabled
    public static string getSupportTeamsHome(){
        
        // Map to store Support Team Name + No of Accounts Associated
        Map<String, Integer> supportTeam_noOfAccMap = new Map<String, Integer>();
        
        // Return Wrapper
        supportTeamsWrapper returnWrapperList = new supportTeamsWrapper();
        returnWrapperList.isManager = checkIsManager();

        List<teamsWrapper> teamsWrapperList = new List<teamsWrapper>(); 
        teamsWrapper eachTeamWrapper;      
        
		// Aggregate Query to set the supportTeam_noOfAccMap
        for(AggregateResult agg : [SELECT TS_Support_Team__c, COUNT(Team_Account__c) noAccount FROM TS_TeamAccount__c GROUP BY TS_Support_Team__c]){
            supportTeam_noOfAccMap.put((String)agg.get('TS_Support_Team__c'),(Integer)agg.get('noAccount'));
        }
		
		// Loop for all the Support Team
        for(TS_Support_Team__c team : [SELECT Id, Team_Name__c, Team_Type__c, No_of_Accounts__c FROM TS_Support_Team__c order by Team_Name__c]){
            
            eachTeamWrapper = new teamsWrapper();
            eachTeamWrapper.Id = team.Id;
            eachTeamWrapper.teamName = team.Team_Name__c;
            eachTeamWrapper.teamType = team.Team_Type__c;
            eachTeamWrapper.noAccounts = (supportTeam_noOfAccMap.get(team.Id) != null ) ? supportTeam_noOfAccMap.get(team.Id) : 0;
            teamsWrapperList.add(eachTeamWrapper);
        }
        
        returnWrapperList.teams = teamsWrapperList;

        return JSON.serialize(returnWrapperList);
    }

    //Method - 7 : Method to get accounts and members for a support team
    //Called in LWC - scSTMSupportTeams
    @AuraEnabled
    public static String getSupportTeamAccountsAndMembersHome(Id teamId){
        /*List<supportTeamAccountWrapper> accountsWrapperList = new List<supportTeamAccountWrapper>();
        List<TS_TeamAccount__c> accountsList = [SELECT Id, Team_Account__r.Name, Team_Account__r.ERC_Numeric__c, Team_Account__r.AKAM_Account_ID__c, Team_Account__r.Support_Level__c, Team_Account__r.Customer_Tier__c, Team_Account__r.Geography_Formula__c FROM TS_TeamAccount__c WHERE TS_Support_Team__c = :teamId];
        if(accountsList.size() > 0){
            for(TS_TeamAccount__c account : accountsList){
                supportTeamAccountWrapper eachAccountWrapper = new supportTeamAccountWrapper();
                eachAccountWrapper.Id = account.Id;
                eachAccountWrapper.teamAccountUrl = '/' + account.Id;
                eachAccountWrapper.accountName = account.Team_Account__r.Name;
                eachAccountWrapper.erc = account.Team_Account__r.ERC_Numeric__c;
                eachAccountWrapper.akamAccountId = account.Team_Account__r.AKAM_Account_ID__c;
                eachAccountWrapper.supportLevel = account.Team_Account__r.Support_Level__c;
                eachAccountWrapper.customerTier = account.Team_Account__r.Customer_Tier__c;
                eachAccountWrapper.geo = account.Team_Account__r.Geography_Formula__c;
                accountsWrapperList.add(eachAccountWrapper);
            }
        }*/

        //Return Wrapper
        supportTeamDetailsWrapper returnWrapperList = new supportTeamDetailsWrapper();

        //Get all accounts for team
        List<TS_TeamAccount__c> accountsList = [SELECT Id, Team_Account_URL__c, Team_Account_Name__c, Team_Account_ERC__c, Team_AKAM_Account_ID__c, Team_Account_Support_Level__c, Team_Account_Customer_Tier__c, Team_Account_Geography__c FROM TS_TeamAccount__c WHERE TS_Support_Team__c = :teamId];
        
        //Get all members for team
        List<TS_TeamMember__c> membersList = [SELECT Id, Team_Member_URL__c, Team_Member_Alias__c, Team_Member_Name__c, Role__c, SC_STM_Support_Team_Skill__c FROM TS_TeamMember__c WHERE TS_Support_Team__c = :teamId];

        returnWrapperList.accounts = accountsList;
        returnWrapperList.members = membersList;

        return JSON.serialize(returnWrapperList);
    }

    //Method - 8 : Method to get members for a support team
    //Called in LWC - scSTMSupportTeams
    // @AuraEnabled
    // public static List<supportTeamMemberWrapper> getSupportTeamMembersHome(Id teamId){
    //     List<supportTeamMemberWrapper> membersWrapperList = new List<supportTeamMemberWrapper>();
    //     List<TS_TeamMember__c> membersList = [SELECT Id, Team_Member__c, Team_Member__r.Alias, Team_Member__r.Name, Role__c, Team_Member__r.ACD2_Support_Team_Skill__c FROM TS_TeamMember__c WHERE TS_Support_Team__c = :teamId];
    //     if(membersList.size() > 0){
    //         for(TS_TeamMember__c member : membersList){
    //             supportTeamMemberWrapper eachMemberWrapper = new supportTeamMemberWrapper();
    //             eachMemberWrapper.Id = member.Id;
    //             eachMemberWrapper.userUrl = '/' + member.Team_Member__c;
    //             eachMemberWrapper.alias = member.Team_Member__r.Alias;
    //             eachMemberWrapper.memberName = member.Team_Member__r.Name;
    //             eachMemberWrapper.role = member.Role__c;
    //             eachMemberWrapper.supportTeamSkill = member.Team_Member__r.ACD2_Support_Team_Skill__c;
    //             membersWrapperList.add(eachMemberWrapper);
    //         }
    //     }
    //     return membersWrapperList;
    // }

    //Method - 8 : Method to delete selected support team/account/member
    //Called in LWC - scSTMSupportTeams
    @AuraEnabled
    public static string deleteSelectedRecord(Id recordId){

        try{
			sObject sObj = recordId.getSobjectType().newSobject(recordId);
			delete sObj;
            return 'success';
        } 
        catch (Exception error){
            if(error.getMessage().containsIgnoreCase('support team members') || error.getMessage().containsIgnoreCase('support team accounts'))
                return 'This Support Team cannot be deleted because it is associated with one OR more Support Team Accounts/Members!';
            return error.getMessage();
        }
        
    }

    //Method - 9 : Method for getting dynamic modal layout from metadata
    //Called in LWC - scSTMSupportTeams
    @AuraEnabled
    public static String getModalDetails(String objName){

        //Return Wrapper
        List<layoutWrapper> returnWrapperList = new List<layoutWrapper>();

        //wrapper for each field in layout
        layoutWrapper eachLayoutWrapper;
        // Integer sectionOrder;
        // Map<Integer,layoutWrapper> sectionsMap  = new Map<Integer,layoutWrapper>();
        //List<STM_Custom_Modal_Layout__mdt> modalMetadata = [SELECT Field__c, Field_Order__c, Team_Default_Value__c, Required__c, Section__c, Section_Order__c FROM STM_Custom_Modal_Layout__mdt WHERE Object__c = :objName ORDER BY Field_Order__c];
        
        //Loop for all fields
        for(STM_Custom_Modal_Layout__mdt metadata : [SELECT Field__c, Field_Order__c, Team_Default_Value__c FROM STM_Custom_Modal_Layout__mdt WHERE Object__c = :objName ORDER BY Field_Order__c]){
            /*sectionOrder = Integer.valueOf(metadata.Section_Order__c);
            if(!sectionsMap.containsKey(sectionOrder)){
                eachSectionWrapper = new layoutWrapper(metadata.Section__c,sectionOrder);
                // eachSectionWrapper.sectionName = metadata.Section__c;
                // eachSectionWrapper.sectionOrder = sectionOrder;
                sectionsMap.put(sectionOrder, eachSectionWrapper);
            }

            eachSectionWrapper = sectionsMap.get(sectionOrder);*/
            eachLayoutWrapper = new layoutWrapper();
            eachLayoutWrapper.fieldName = metadata.Field__c;
            eachLayoutWrapper.fieldOrder = Integer.valueOf(metadata.Field_Order__c);
            eachLayoutWrapper.teamDefaultValue = metadata.Team_Default_Value__c;
            returnWrapperList.add(eachLayoutWrapper);
            /*eachSectionWrapper.fields.add(eachFieldWrapper);
            sectionsMap.put(sectionOrder, eachSectionWrapper);*/
        }

        return JSON.serialize(returnWrapperList);
    }

    //................Functionality for Search by ERC tab............................

    //Method - 10 : Method for getting all details for an ERC
    //Called in LWC : scSTMSearchByERC
    @AuraEnabled
    public static String getDetailsFromERC(String ERC){

        ercWrapper returnWrapperList = new ercWrapper();
        List<teamsWrapper> supportTeam = new List<teamsWrapper>();
        List<TS_TeamAccount__c> teamAccounts = [SELECT Id, Team_Account_Name__c, Team_Account_URL__c, Team_AKAM_Account_ID__c, Support_Team_Name__c, Support_Team_Type__c, TS_Support_Team__c FROM TS_TeamAccount__c WHERE Team_Account_ERC__c = :ERC];
        if(teamAccounts.size() > 0){
            List<TS_TeamMember__c> teamMembers = [SELECT Id, Team_Member_Name__c, Team_Member_URL__c, Role__c, SC_STM_Support_Team_Skill__c FROM TS_TeamMember__c WHERE TS_Support_Team__c = :teamAccounts[0].TS_Support_Team__c];
            teamsWrapper eachSupportTeam = new teamsWrapper();
            
            
            eachSupportTeam.teamName = teamAccounts[0].Support_Team_Name__c;
            eachSupportTeam.teamType = teamAccounts[0].Support_Team_Type__c;
            eachSupportTeam.noAccounts = teamAccounts.size();
            supportTeam.add(eachSupportTeam);
            returnWrapperList.teamAccounts = teamAccounts;
            returnWrapperList.teamMembers = teamMembers;
            returnWrapperList.supportTeam = supportTeam;
        }
        return JSON.serialize(returnWrapperList);
        
    }



    // public class layoutWrapper {
    //     @AuraEnabled
    //     public String sectionName;

    //     @AuraEnabled
    //     public Integer sectionOrder;

    //     @AuraEnabled
    //     public List<fieldWrapper> fields;

    //     public layoutWrapper(String name, Integer order) {
    //         sectionName = name;
    //         sectionOrder = order;
    //         fields = new List<FieldWrapper>();
    //     }
    // }

    public class ercWrapper {
        @AuraEnabled
        public List<teamsWrapper> supportTeam;

        public List<TS_TeamAccount__c> teamAccounts;

        public List<TS_TeamMember__c> teamMembers;
    }

    public class layoutWrapper {
        @AuraEnabled
        public String fieldName;

        @AuraEnabled
        public Integer fieldOrder;

        @AuraEnabled
        public Boolean teamDefaultValue;

    }

    public class supportTeamByEmployeeWrapper{
        @AuraEnabled
        public Boolean isManager;

        public List<employeeWrapper> employees;
            
    }
     public class employeeWrapper{
         
         @AuraEnabled public String UserID;
         @AuraEnabled
         public String UserUrl;
         @AuraEnabled
         public String alias;
         @AuraEnabled
         public String firstName;
         @AuraEnabled
         public String lastName;
         @AuraEnabled
         public String email;
         @AuraEnabled
         public String managerName;
         @AuraEnabled
         public Integer supportTeam_PrimaryCount;
         @AuraEnabled
         public Integer supportTeam_SecondaryCount;
         @AuraEnabled
         public Integer supportTeam_OtherCount;
         @AuraEnabled
         public Integer accountTeam_PrimaryCount;
         @AuraEnabled
         public Integer accountTeam_SecondaryCount;
         
         
         @AuraEnabled
         public String officeLocation;
         @AuraEnabled
         public String ownerShift;
         @AuraEnabled
         public String supportTeamSkill;

         @AuraEnabled
         public String ManagerId;


             
    }


    public class supportTeamsWrapper{
        @AuraEnabled
        public Boolean isManager;

        public List<teamsWrapper> teams;


    }

    public class teamsWrapper{

        @AuraEnabled
        public String Id;
        @AuraEnabled
        public String teamName;

        @AuraEnabled
        public String teamType;

        @AuraEnabled
        public Integer noAccounts;

    }

    public class supportTeamDetailsWrapper{
        public List<TS_TeamMember__c> members;
        
        public List<TS_TeamAccount__c> accounts;
            
        
    }
     
}