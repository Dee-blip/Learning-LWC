/**
 PLM_LaunchItemApprovalTrigger
 @author : Chandra Lohani(clohani@akamai.com)
 @Description : This trigger is used to capture following events:
                - A new Launch Approval is created : Before Insert it will check whether notifications ahs been sent already for Launch Item 
                  and update the approval accordingly 
                - A new Launch Approval is created: After Insert it will check if approval is visible it will send mail notifications to new approver.
                
                - Update to launch Approval : after Update it will check for following :-
                   1. Is approver changed ->send mail to new approver
                   2. is delegate approver changed -> send mail to new delegate approver
                   3. if status changes on Divisional launch approval -> updates launch Item status to PLU-Approved.
                                    
 
 @History : 
 
 Developer Name             Date             Description
 Chandra Lohani	          26-12-2012       Create this class for CR 1419337
 Chandra Lohani	          02-02-2012       Moved all logic to 'processLaunchItemApprovals' method of 'PLM_LaunchItemApprovalGeneric' class. 
*/
trigger PLM_LaunchItemApprovalTrigger on Launch_Item_Approval__c (before insert,after insert , after update) 
{
	PLM_LaunchItemApprovalGeneric plmClass=new PLM_LaunchItemApprovalGeneric('LaunchItemApprovalTrigger');
    Boolean islaunchItemApprovalEnabled=plmClass.dataClass.getIsLaunchItemApprovalEnabled();
	if(islaunchItemApprovalEnabled)
	{
		plmClass.processLaunchItemApprovals(Trigger.New, Trigger.oldMap, Trigger.isInsert, Trigger.isUpdate, Trigger.isBefore, Trigger.isAfter);
	}
}