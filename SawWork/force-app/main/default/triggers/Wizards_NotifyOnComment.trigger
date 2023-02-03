/*
Author : Jayalakshmi
Description: Trigger for sending out notifications on new comment 
Created Date: 16/12/2014
Modified by Prateek Bhuwania on 10/08/2018
*/

trigger Wizards_NotifyOnComment on IdeaComment (after insert) 
{
    Wizards_ICAfterTriggerClass notifyOnComment = new Wizards_ICAfterTriggerClass();

    
    /*
    notifyOnComment.sendNotification(trigger.new, trigger.newMap);
    */
}