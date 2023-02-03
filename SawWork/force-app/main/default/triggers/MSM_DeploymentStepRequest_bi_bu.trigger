trigger MSM_DeploymentStepRequest_bi_bu on Deployment_Step_Request__c (before insert, before update) 
{
	if(Trigger.isInsert)
	{
		MSMUtil.populateInstanceURL(Trigger.new);
	}

}