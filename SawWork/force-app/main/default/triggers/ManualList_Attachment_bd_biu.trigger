/***
    ManualList_Attachment_bd_biu
    @version 1.0
    @author Chakradhar kasturi <ckasturi@akamai.com>
    @Description : This trigger is called on 'before delete' events on the Attachments object.
                   It takes care of the following :
                   - Attachment is Manual list type and user is sysadmin to delete the attachment
				   - Insertion or updation of a Attachment on manual list is only for CMG Users

    @History
    --Developer           --Date            --Change
    ckasturi            11-Jul-16       CR 3098791 - allow attachments to manual lists in SFDC
*/
trigger ManualList_Attachment_bd_biu on Attachment (before insert,before update,before delete) {
    //Query for the SysAdminId
    if(Trigger.isDelete){
      for(Attachment a:Trigger.old){
         if(Schema.Merge_Contract_Manual_List__c.SObjectType == a.ParentId.getSobjectType()) {
          String adminProfileId = GsmUtilClass.GetCustomSettingValue('ApprovalHistory#SysAdminId');	
          if(!UserInfo.getProfileId().contains(adminProfileId))
          {
             // If CMG user tries to delete display error message
             a.addError('You are not authorized to delete the attachment.Contact System Administrator.');
          }
        }
      }
    }

    //When NON-CMG users try to insert or update the attachments
    if(Trigger.isInsert || Trigger.isUpdate){
      for(Attachment a:Trigger.New){
          //only sysadmin and cmg profile can edit the attachment on manual list
          if(Schema.Merge_Contract_Manual_List__c.SObjectType == a.ParentId.getSobjectType())
          {
          	  String cmgProfileId = GsmUtilClass.GetCustomSettingValue('CMGProfileId');
      		  String adminProfileId = GsmUtilClass.GetCustomSettingValue('ApprovalHistory#SysAdminId');
	          if(UserInfo.getProfileId().substring(0,15) != cmgProfileId && UserInfo.getProfileId().substring(0,15) != adminProfileId)
	          {
	             // If CMG user tries to delete display error message
	             a.addError('You are not authorized to insert/update the attachment.Contact System Administrator.');
	          }
          }
      }
    }
}