global class SC_AddCommunityUserToGroupBatch implements Database.Batchable<sObject>, Database.stateful {
    
    //This will store the Error Message from support class
    Public string errorMessage = '' ;
    
    //This will store the Query for the batch class
    Public string userQuery;
    
    //This will store the Query for the test class 
    Public string userQuery_Test;
    
    public list<CollaborationGroupMember> returnUserList;
    public List<Id> communityUserIdList = new List<Id>();
    public List<Id> filteredCommunityUserIdList = new List<Id>();
    public List<Id> profileIdList = new List<Id>();
    
    public SC_AddCommunityUserToGroupBatch(){
        
        //Get the Topic for which case needs to be created
        
        SFCommunity_NQLB_Topics__mdt  communityMdt = [SELECT PartnerPermissionSet__c,EmployeePermissionSet__c,ModeratorPermissionSetId__c,EmployeePublicGroupId__c,AddUserToGroupDayCount__c,EnableAutoAddUserToGroupTrigger__c,CustomerPublicGroupId__c,PartnerPublicGroupId__c,GuestPublicGroupId__c,AllRegisteredCollabGroupId__c, AllRegExceptGuestCollabGroupId__c, PartnerProfileId__c,CustomerProfileId__c, Guest_Profile__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];

        
        dateTime settime  = system.now().addDays(-Integer.valueOf((communityMdt.AddUserToGroupDayCount__c)));
        String valuesettimefrom = String.valueOfGmt(settime);
        valuesettimefrom = valuesettimefrom.substring(0,10)+'T'+valuesettimefrom.substring(11,17)+'00z';
        
        List<string> dateList = (valuesettimefrom.split('T'))[0].split('-');
        List<string> timeList = (valuesettimefrom.split('T'))[1].split(':');
        DateTime convertedValuesettimefrom = DateTime.newInstanceGMT(Integer.valueOf(dateList[0]), Integer.valueOf(dateList[1]), Integer.valueOf(dateList[2]), Integer.valueOf(timeList[0]), Integer.valueOf(timeList[1]), Integer.valueOf((timeList[2].replace('z',''))));
        
        profileIdList.add(Id.valueOf(communityMdt.PartnerProfileId__c));
        profileIdList.add(Id.valueOf(communityMdt.CustomerProfileId__c));
        
        List<Id> psaIdList = new List<Id>();
        psaIdList.add(Id.valueOf(communityMdt.PartnerPermissionSet__c));
        psaIdList.add(Id.valueOf(communityMdt.EmployeePermissionSet__c));
        psaIdList.add(Id.valueOf(communityMdt.ModeratorPermissionSetId__c));
        
        String permissionSetQuery = 'select Assigneeid,SystemModstamp from PermissionSetAssignment where PermissionSetId in:psaIdList';
        
        for(PermissionSetAssignment psa: Database.query(permissionSetQuery)){
            communityUserIdList.add(psa.Assigneeid);
            if(psa.SystemModstamp > convertedValuesettimefrom)
            	filteredCommunityUserIdList.add(psa.Assigneeid);
        }
        
        userQuery_Test = 'Select id,createddate,companyName,email,contactId,Contact.Account.isPartner,Contact.Account.Name,Profile.Name,Name,Profile.UserLicense.Name,UserName,Alias,IsActive from User where isActive = true and createddate > '+valuesettimefrom+' Limit 10';
        
        //userQuery =  'Select id,createddate,companyName,email,contactId,Contact.Account.isPartner,Contact.Account.Name,Profile.Name,Name,Profile.UserLicense.Name,UserName,Alias,IsActive from User where isActive = true and createddate > '+valuesettimefrom ;
        userQuery =  'Select id,createddate,companyName,email,contactId,Contact.Account.isPartner,Contact.Account.Name,Profile.Name,Name,Profile.UserLicense.Name,UserName,Alias,IsActive from User where (isActive = true and createddate > '+valuesettimefrom+ ' and id in:communityUserIdList) or (isActive = true and id in:filteredCommunityUserIdList) or (isActive = true and createddate > '+valuesettimefrom+ ' and profileid in:profileIdList)';
    }
    
    //Start Method
    global Database.QueryLocator start(Database.BatchableContext BC)
    {
        returnUserList = new List<CollaborationGroupMember>();
        //Check whether its a test class execution or normal execution
        string batchQuery = (System.Test.isRunningTest()) ? userQuery_Test : userQuery;
        if(batchQuery != null)
            return Database.getQueryLocator(batchQuery);
        else
            return null;
    }
    
    //Execute Method
    global void execute(Database.BatchableContext BC, List<sObject> scope){
        
        //Convert Sobject list to feedItem List
        List<User> userList = (User[]) scope;
        //Call helper class to identify and create NQLB Questions
        if(userList.size() > 0){
            SC_AddCommunityUserToGroupController addCommUserToGrp = new SC_AddCommunityUserToGroupController();
            returnUserList = addCommUserToGrp.addUserToGroup(userList);
        }
    }
    
    //Finish Method
    global void finish(Database.BatchableContext BC){   
        if(returnUserList.size() > 0){
            ID jobID = System.enqueueJob(new SC_AddUserToGroupQueableInterface(returnUserList));
            // Moving the Job to position 1. If exception is there, nothing to do as Job is already in process
            try{
                Boolean isSuccess = FlexQueue.moveJobToFront(jobID);
            }catch(Exception e){}  
        } 
    }
    
}