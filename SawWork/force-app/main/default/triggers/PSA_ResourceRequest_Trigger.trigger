/***
    PSA_ResourceRequest_Trigger
    @author Liz Ichihashi
    @Description : This trigger calls a method on the action class to set the group on a resource request upon insertion.
    @History
    --Developer           --Date            --Change
    Liz Ichihashi         7/04/2013     Created the class.       
*/
trigger PSA_ResourceRequest_Trigger on pse__Resource_Request__c (before insert) {
	PSA_ResourceRequestActions.setResourceRequestGroup(trigger.new);
}