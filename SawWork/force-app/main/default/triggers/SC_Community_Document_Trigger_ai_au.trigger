trigger SC_Community_Document_Trigger_ai_au on Customer_Community_Document__c (before update, before delete, after insert, after update) {
    if(!UserInfo.getName().equalsIgnoreCase('Connection User')){
        // get the id for the group for everyone in the org
        List<Id> groupId;
        List<Id> allGroupId = new List<Id>();  
        Map<Id,List<Id>> shareRecordGroupIdMap = new Map<Id,List<Id>>(); 
        List<Id> allDocumentId = new List<Id>();
        List<Id> userWithAccess = new List<Id>();
        List<Id> groupIds = new List<Id>();
        Map<Id,String> groupRoleMap = new Map<Id,String>();
        String errorMsg = '';
        Boolean isModeratorOrSpaceAdmin = false;
        Id adminId = [Select id from Profile where Name = 'System Administrator'].id;
        SFCommunity_NQLB_Topics__mdt  communityMetaDataVal = [SELECT EnableDocumentTrigger__c,UserGroupWith10KMembers__c ,Case_Priority__c , Question_Hours_for_Case_Creation__c, Question_Community_Topic__c,CommunityNetworkId__c, Case_Visibility__c , Case_Severity__c ,DefaultAccountIdForNewContact__c,TopicName__c, DayRange__c,ExcludeGroupForDocumentShare__c,PermissionSetToEditGrpDoc__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
        if(communityMetaDataVal.EnableDocumentTrigger__c){
            if(Trigger.isBefore){
                for(PermissionSetAssignment permissionSet : [SELECT Id,AssigneeId, PermissionSetId FROM PermissionSetAssignment WHERE AssigneeId =:userinfo.getUserId()]){
                    if(communityMetaDataVal.PermissionSetToEditGrpDoc__c.contains(String.valueOf(permissionSet.PermissionSetId)))
                        isModeratorOrSpaceAdmin = true;
                }
                if(Trigger.isUpdate){
                    for (Customer_Community_Document__c eachDoc : Trigger.new) {
                        groupIds.add(Id.valueOf(eachDoc.Group_Id__c));
                    }
                    for(CollaborationGroupMember groupMeber: [Select CollaborationGroupId, CollaborationRole from CollaborationGroupMember where MemberId =: userinfo.getUserId() AND CollaborationGroupId IN:(groupIds)]){
                        groupRoleMap.put(groupMeber.CollaborationGroupId,groupMeber.CollaborationRole);
                    }
                    for (Customer_Community_Document__c eachDoc : Trigger.new) {
                        if(communityMetaDataVal.ExcludeGroupForDocumentShare__c != null && !String.isEmpty(communityMetaDataVal.ExcludeGroupForDocumentShare__c)){
                            if(communityMetaDataVal.ExcludeGroupForDocumentShare__c.contains(eachDoc.Group_Id__c) && eachDoc.OwnerId != userinfo.getUserId() && eachDoc.CreatedById != userinfo.getUserId() && 
                               (!isModeratorOrSpaceAdmin && groupRoleMap.get(eachDoc.Group_Id__c) != 'Admin' && userinfo.getProfileId() != adminId))
                                eachDoc.addError('You do not have sufficient access to edit this document in this group');
                        }
                    }
                }
                if(Trigger.isDelete){
                    for (Customer_Community_Document__c eachDoc : Trigger.old) {
                        groupIds.add(Id.valueOf(eachDoc.Group_Id__c));
                    }
                    for(CollaborationGroupMember groupMeber: [Select CollaborationGroupId, CollaborationRole from CollaborationGroupMember where MemberId =: userinfo.getUserId() AND CollaborationGroupId IN:(groupIds)]){
                        groupRoleMap.put(groupMeber.CollaborationGroupId,groupMeber.CollaborationRole);
                    }
                    for (Customer_Community_Document__c eachDoc : Trigger.old) {
                        if(communityMetaDataVal.ExcludeGroupForDocumentShare__c != null && !String.isEmpty(communityMetaDataVal.ExcludeGroupForDocumentShare__c)){
                            if(communityMetaDataVal.ExcludeGroupForDocumentShare__c.contains(eachDoc.Group_Id__c) && eachDoc.OwnerId != userinfo.getUserId() && eachDoc.CreatedById != userinfo.getUserId() &&
                               (!isModeratorOrSpaceAdmin && groupRoleMap.get(eachDoc.Group_Id__c) != 'Admin' && userinfo.getProfileId() != adminId))
                                eachDoc.addError('You do not have sufficient access to delete this document in this group');
                        }
                    }
                }
            }
        }
        if(communityMetaDataVal.EnableDocumentTrigger__c){
            // inserting new records
            if (Trigger.isInsert || Trigger.isUpdate) {
                //Document Share list
                List<Customer_Community_Document__Share> sharesToCreate = new List<Customer_Community_Document__Share>();
                
                //Populating Map of Document and Group Id it is associated with
                for (Customer_Community_Document__c eachDoc : Trigger.new) {
                    allDocumentId.add(eachDoc.Id);
                    if(eachDoc.Group_Id__c != Null && !communityMetaDataVal.UserGroupWith10KMembers__c.contains(eachDoc.Group_Id__c)){
                        if(shareRecordGroupIdMap.containsKey(eachDoc.Id)){
                            List<Id> groupIdList = shareRecordGroupIdMap.get(eachDoc.Id);
                            groupIdList.add(eachDoc.Group_Id__c);
                            shareRecordGroupIdMap.put(eachDoc.Id,groupIdList);
                        }
                        
                        else{
                            shareRecordGroupIdMap.put(eachDoc.Id, new List<Id> { eachDoc.Group_Id__c });
                        }
                    }
                    system.debug('shareRecordGroupIdMap : '+shareRecordGroupIdMap);
                    /*groupId = new List<Id>();

//Ignore documents which are shared with group with 10k members
if(eachDoc.Group_Id__c != Null && !communityMetaDataVal.UserGroupWith10KMembers__c.contains(eachDoc.Group_Id__c))
groupId.add(eachDoc.Group_Id__c);
if(groupId.size() >0 )
shareRecordGroupIdMap.put(eachDoc.Id, groupId);*/
                }
                
                //Populating list of all group Ids
                if(!shareRecordGroupIdMap.isEmpty()){
                    for(Id eachId :shareRecordGroupIdMap.keySet()){
                        allGroupId.addAll(shareRecordGroupIdMap.get(eachId));
                    }
                }
                
                
                //Populating Group and its Members
                Map<Id,Set<Id>> colGroupMemberMap = new Map<Id,Set<id>>();
                if(!shareRecordGroupIdMap.isEmpty()){ 
                    for(CollaborationGroupMember cgroup : [Select Id,CollaborationGroupId,MemberId from CollaborationGroupMember where CollaborationGroupId IN :allGroupId]){
                        if(colGroupMemberMap.containsKey(cgroup.CollaborationGroupId)) {
                            Set<Id> membersId = colGroupMemberMap.get(cgroup.CollaborationGroupId);
                            membersId.add(cgroup.MemberId);
                            colGroupMemberMap.put(cgroup.CollaborationGroupId, membersId);
                        } 
                        else {
                            colGroupMemberMap.put(cgroup.CollaborationGroupId, new Set<Id> { cgroup.MemberId });
                        }  
                    } 
                }
                system.debug('colGroupMemberMap : '+colGroupMemberMap);
                if(allDocumentId.size() > 0){
                    for(Customer_Community_Document__Share eachMemberWithAccess :[Select AccessLevel,UserOrGroupId,ParentId from Customer_Community_Document__Share where ParentId IN :allDocumentId and (AccessLevel = 'Read' or  AccessLevel = 'All' or AccessLevel = 'Edit')]){
                        userWithAccess.add(eachMemberWithAccess.UserOrGroupId);
                    }           
                    
                }
                system.debug('userWithAccess : '+userWithAccess);
                if (!colGroupMemberMap.isEmpty()) {
                    SC_Community_Document_Trigger_Helper.createDocumentShare(colGroupMemberMap,Trigger.new,userWithAccess,shareRecordGroupIdMap);
                }
                /*Sharing record to each member of the group
if (!colGroupMemberMap.isEmpty()) {
for(Customer_Community_Document__c eachRecord : Trigger.new){  
for(id eachGroup : shareRecordGroupIdMap.get(eachRecord.Id)){
if(colGroupMemberMap.containsKey(eachGroup)){
for(id eachMember :colGroupMemberMap.get(eachGroup)){
if(!userWithAccess.contains(eachMember)){
Customer_Community_Document__Share cs = new Customer_Community_Document__Share();
cs.AccessLevel = 'read';
cs.ParentId = eachRecord.Id;
cs.UserOrGroupId = eachMember;
sharesToCreate.add(cs);
}
}
}
}
}
}
// do the DML to create shares
if (!sharesToCreate.isEmpty()){
//insert sharesToCreate;
database.SaveResult[] resultShare =  database.Insert(sharesToCreate,false);
// Iterate through each returned result
List<Id> successCaseList = new List<Id>();

for (Database.SaveResult sr : resultShare) {
if (sr.isSuccess()) {
// Operation was successful, so get the ID of the record that was processed
System.debug('Successfully inserted Document Share. Document Share ID: ' + sr.getId());
successCaseList.add(sr.getId());
}
else {
// Operation failed, so get all errors 
List<String> allCaseExceptionList = new List<String>();
String allCaseExceptionString = '';
String errorMessage = '';
for(Database.Error err : sr.getErrors()) {
errorMessage = err.getMessage();
allCaseExceptionString = 'The following error has occurred on Document Share insertion. \n' +
'Error: ' + errorMessage + '\n';
allCaseExceptionList.add(allCaseExceptionString);

}
for(string errStr : allCaseExceptionList){
errorMsg += errStr + '\n';
} 
}
}
}
If(errorMsg != ''){
SFCommunity_NQLB_Topics__mdt  communityExceptionEmail = [SELECT ExceptionEmailToAddress__c FROM SFCommunity_NQLB_Topics__mdt  WHERE DeveloperName = 'CommunityNQLB' limit 1];
// Setting To Address
String[] toAdd = new String[] {};
toAdd.add(communityExceptionEmail.ExceptionEmailToAddress__c);

// Sending Email
Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
mail.setToAddresses(toAdd);
mail.subject = 'Error: Community Document Share';
mail.plainTextBody = errorMsg;
Messaging.SendEmailResult [] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail}); 

}*/
            }
        }
    }
}