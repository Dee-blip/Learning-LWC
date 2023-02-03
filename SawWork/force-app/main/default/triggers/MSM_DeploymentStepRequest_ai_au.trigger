trigger MSM_DeploymentStepRequest_ai_au on Deployment_Step_Request__c (after insert, after update) 
{
	if(Trigger.isUpdate)
	{
		MSMUtil.updateDeployedDSFields(Trigger.new, Trigger.oldMap);
	}

}