/***
    PSA_ResourceRequestActions
    @author Liz Ichihashi
    @Description : This Class contains method called from PSA_ResourceRequest_Trigger on
                   before insert.  This code sets the group on the Resource Request
                   to be the Group from the logged on user.
    @History
    --Developer           --Date            --Change
    Liz Ichihashi         7/04/2013     Created the class.       
*/
public without sharing class PSA_ResourceRequestActions {
	
	public class ResourceRequestException extends Exception {}  

	public static void setResourceRequestGroup(List<pse__Resource_Request__c>  newList) {
		Contact userResource;
		try {
			userResource = [Select Id, pse__Group__c from Contact where pse__Salesforce_User__c = :UserInfo.getUserId() limit 1];		
		} catch (Exception e) {
			throw new ResourceRequestException('No Contact found for logged on User.  Please contact your system administrator for assistance');
		}	
		if (userResource != null) {
			for (pse__Resource_Request__c newRow : newList) {
				newRow.pse__Group__c = userResource.pse__Group__c;
			}	
		}	
	}
}