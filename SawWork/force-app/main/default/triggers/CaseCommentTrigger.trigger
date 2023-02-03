/*****************************************************************************
 * Name             : CaseCommentTrigger
 * Created By       : Pitamber Sharma
 * Created Date    	: 27-May-2013
 * Purpose          : Trigger on Case Comment Object
 *****************************************************************************/
trigger CaseCommentTrigger on CaseComment (after insert) {
	if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
	{
		CaseCommentTriggerHandler handler = new CaseCommentTriggerHandler();
		
		if(Trigger.isAfter) {
			if(Trigger.isInsert) {
				handler.onAfterInsert(Trigger.new);
			}
		}
	}
}