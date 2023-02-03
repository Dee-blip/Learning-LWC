/*
Author : Shomil
Description: Trigger for sending out Email by Admin
Created Date: 02/01/2014
*/
trigger Wizards_SendEmailByAdmin on IdeaEmail__c (after insert) {
	Wizards_SendEmailByAdminTriggerClass.sendEmail(trigger.new);
}