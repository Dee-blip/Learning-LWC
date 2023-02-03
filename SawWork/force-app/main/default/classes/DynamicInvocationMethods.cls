/*
* File Name: DynamicInvocationMethods
* Description : Dynamic method invocation class for handling the Self-Service dynamic redirection
* @author : Aneesh Budnar
* Modification Log ===============================================================
* Date 				 Author 			  Modification
* Mar 23rd, 2022     Aneesh Budnar        PRTORES-2483 - HD Lightning UI page redirect for controlling the SelfService URL for aloha
*/
public class DynamicInvocationMethods implements Callable {
	// Actual method
    Boolean checkCurrentUserAccess(List<SObject> records) {
        Set<Id> allowedUsers = new Set<Id>();
        for(SObject record : records) {
            allowedUsers.add((Id)record.get('Id'));
        }
        return allowedUsers.contains(UserInfo.getUserId());
    }
    
    Boolean checkCurrentProfileAccess(List<SObject> records) {
        Set<Id> allowedProfiles = new Set<Id>();
        for(SObject record : records) {
            allowedProfiles.add((Id)record.get('Id'));
        }
        return allowedProfiles.contains(UserInfo.getProfileId());
    }
    
    Boolean checkCurrentRoleAccess(List<SObject> records) {
        Set<Id> allowedRoles = new Set<Id>();
        for(SObject record : records) {
            allowedRoles.add((Id)record.get('Id'));
        }
        return allowedRoles.contains(UserInfo.getUserRoleId());
    }
    
    Boolean checkPermissionSetAccess(List<SObject> records) {
        Set<Id> allowedPSes = new Set<Id>();
        for(SObject record : records) {
            allowedPSes.add((Id)record.get('AssigneeId'));
        }
        return allowedPSes.contains(UserInfo.getUserId());
    }
    
    Boolean checkGroupAccess(List<SObject> records) {
        Set<Id> allowedGroupMembers = new Set<Id>();
        for(SObject record : records) {
            allowedGroupMembers.add((Id)record.get('UserOrGroupId'));
        }
        return allowedGroupMembers.contains(UserInfo.getUserId());
    }
    

   // Dispatch actual methods
   public Object call(String action, Map<String, Object> args) {
     switch on action {
       when 'checkCurrentUserAccess' {
         return this.checkCurrentUserAccess((List<SObject>)args.get('records'));
       }
       when 'checkCurrentProfileAccess' {
         return this.checkCurrentProfileAccess((List<SObject>)args.get('records'));
       }
       when 'checkCurrentRoleAccess' {
         return this.checkCurrentRoleAccess((List<SObject>)args.get('records'));
       }
       when 'checkPermissionSetAccess' {
         return this.checkPermissionSetAccess((List<SObject>)args.get('records'));
       }
       when 'checkGroupAccess' {
         return this.checkGroupAccess((List<SObject>)args.get('records'));
       }
       when else {
        throw new ExtensionMalformedCallException('Method not implemented');
       }
     }
   }

   public class ExtensionMalformedCallException extends Exception {}
}