/*
* File Name: HD_Request_Detail_Input_Lightning
* Description : Apex Controller for the Incident Input Details on the Incident Details page
* @author : 
* Modification Log ===============================================================
* Date 				Author 				Modification
* Oct 13th, 2020    Aneesh Budnar       PRTORES-1966 - HD Service Request Field Level Encryption , Team level bifurcation and data integrity
*/
public class HD_Request_Detail_Input_Lightning {

    private final BMCServiceDesk__incident__c inc;

    public static Boolean displayInSecondColumn = false;

    public class Data{
      @AuraEnabled
      public BMCServiceDesk__SRM_RequestDetail__c srInformation;
      @AuraEnabled
      public List<BMCServiceDesk__SRM_RequestDetailInputs__c> srInputDetails;
      @AuraEnabled
      public Boolean dataDisplayInSecondColumn;
      @AuraEnabled
      public Boolean isEditableSR;
    }
    
    private static Set<String> getIncidentSettings() {
        Set<String> incidentSettings = new Set<String>();
        for(HD_Incident_Settings__c setting : [SELECT Id,Name, Value__c FROM HD_Incident_Settings__c LIMIT 100]) {
            incidentSettings.add(setting.Name);
        }
        return incidentSettings;
    }

    //function to check wheter proper permission set is assigned to the logged in User
    @TestVisible private  static Boolean isAccessible(String incidentId, List<BMCServiceDesk__Incident__Share> incidentSharing){
        if(getIncidentSettings().contains('Execute_Old_Encryption_Logic')) {      
            User currentUser = [Select Id,Name,Email,HD_View_Helpdesk_Confidential_Data__c from User where Id=:userinfo.getuserId() LIMIT 1];
            List<PermissionSetAssignment> lstcurrentUserPerSet =    [   SELECT Id, PermissionSet.Name,AssigneeId
                                                                     FROM PermissionSetAssignment
                                                                     WHERE AssigneeId = :Userinfo.getUserId() ];
            System.debug(LoggingLevel.INFO,'##lstcurrentUserPerSet' + lstcurrentUserPerSet);
            Boolean userHasPermission = false;
            for ( PermissionSetAssignment psa : lstcurrentUserPerSet ) {
                System.debug(LoggingLevel.INFO,'##psa.PermissionSet.Name' + psa.PermissionSet.Name);
                if ( psa.PermissionSet.Name.equals('HD_HR_View_Encrypted_data_permission') ) {
                    if(currentUser.HD_View_Helpdesk_Confidential_Data__c == true){
                        userHasPermission = true;
                    }
                }
            }
            return userHasPermission;
        }
        else {
            User currentUser = [Select Id,Name,Email,HD_View_Helpdesk_Confidential_Data__c from User where Id=:userinfo.getuserId() LIMIT 1];
            return currentUser.HD_View_Helpdesk_Confidential_Data__c && 
                hasPermissionSetAccess(incidentId) && 
                hasAccessViaSharing(incidentId, incidentSharing);
        }
          
    }

    private static Boolean hasPermissionSetAccess(String incidentId) {
        BMCServiceDesk__Incident__c incident = [SELECT Id, BMCServiceDesk__FKCategory__r.BMCServiceDesk__categoryType_Id__c 
                                                FROM BMCServiceDesk__Incident__c 
                                                WHERE Id = :incidentId];
        Set<Id> permissionSets = new Set<Id>();
        for(PermissionSetAssignment psa :  [SELECT Id, AssigneeId, PermissionSetId, PermissionSet.Name 
                                            FROM PermissionSetAssignment 
                                            WHERE PermissionSet.Name LIKE 'HD_View_Encrypted_Data%' AND AssigneeId = :UserInfo.getUserId()]) {
            permissionSets.add(psa.PermissionSetId);
        }
        
        System.debug(LoggingLevel.DEBUG, 'Permission Sets assigned to user:'+permissionSets);
        Set<Id> customPermissionIds = new Set<Id>();
        for(SetupEntityAccess se : [SELECT SetupEntityId, SetupEntityType
                                    FROM SetupEntityAccess
                                    WHERE ParentId IN :permissionSets AND SetupEntityType = 'CustomPermission']) {
            customPermissionIds.add(se.SetupEntityId);
        }
        
        System.debug(LoggingLevel.DEBUG, 'Custom permissions assigned to user:'+customPermissionIds);
        Set<String> categories = new Set<String>();
        for(CustomPermission cp : [SELECT Id, DeveloperName,MasterLabel 
                                   FROM CustomPermission 
                                   WHERE Id IN :customPermissionIds]) {
            categories.add(cp.MasterLabel);
        }
        
        return categories.contains(incident.BMCServiceDesk__FKCategory__r.BMCServiceDesk__categoryType_Id__c);
    }
    
    private static Boolean hasAccessViaSharing(String incidentId, List<BMCServiceDesk__Incident__Share> incidentSharing) {
        Set<Id> roleRelatedRuleIds = new Set<Id>();
        List<BMCServiceDesk__Incident__Share> incidentSharingLocal = [SELECT Id, ParentId,UserOrGroupId, AccessLevel, RowCause 
                                                                      FROM BMCServiceDesk__Incident__Share 
                                                                      WHERE ParentId= :incidentId AND AccessLevel IN ('Edit') AND RowCause = 'Rule'];
        if(incidentSharing!= null) {
            incidentSharingLocal.addAll(incidentSharing);
        }
        for (BMCServiceDesk__Incident__Share incshare: incidentSharingLocal) {
            roleRelatedRuleIds.add(incshare.UserOrGroupId);
        }
        
        Set<Id> roleIdsWithAccess = new Set<Id>();
        Set<Id> groupsWithAccess = new Set<Id>();
        for (Group grp : [SELECT Id, DeveloperName, RelatedId, Type 
                           FROM Group 
                           WHERE Id IN :roleRelatedRuleIds AND Type IN ('Role','Regular')]){
        	if(grp.Type == 'Role') {
        		roleIdsWithAccess.add(grp.RelatedId);
            }
            else {
                groupsWithAccess.add(grp.Id);
            }
        }
        
        Set<Id> userIdsOfGroupUsers = new Set<Id>();
        for(GroupMember grpMem : [SELECT Id, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId IN :groupsWithAccess]) {
            userIdsOfGroupUsers.add(grpMem.UserOrGroupId);
        }
        
        return roleIdsWithAccess.contains(UserInfo.getUserRoleId()) || userIdsOfGroupUsers.contains(UserInfo.getUserId());
    }
    
    @AuraEnabled
    public static BMCServiceDesk__SRM_RequestDetail__c getRequestDetailIformation(String incidentID){
      Id recordId = (ID)incidentID;
        try{
            return [select id,BMCServiceDesk__FKRequestDefinition__r.BMCServiceDesk__serviceRequestTitle__c ,
                    Name,BMCServiceDesk__FKClient__c,BMCServiceDesk__FKClient__r.name,
                    BMCServiceDesk__FKClient__r.Department,BMCServiceDesk__FKClient__r.Division,
                    BMCServiceDesk__FKClient__r.EmployeeNumber,BMCServiceDesk__FKClient__r.Email,
                    BMCServiceDesk__FKClient__r.Phone,BMCServiceDesk__DateExpected__c,BMCServiceDesk__DateRequired__c,
                    BMCServiceDesk__Quantity__c,BMCServiceDesk__FKIncident__c,BMCServiceDesk__FKRequestDefinition__c,
                    Owner.Name, BMCServiceDesk__TotalPrice__c,BMCServiceDesk__CustomerPrice__c
                    from BMCServiceDesk__SRM_RequestDetail__c
                    where id in (select BMCServiceDesk__FKRequestDetail__c  from BMCServiceDesk__Incident__c where id= :recordId) limit 1];
        }Catch(Exception e){
            return null;
        }
    }


    @AuraEnabled
    public static List<BMCServiceDesk__SRM_RequestDetailInputs__c> getRequestDetailInputs(String incidentID){
      Id recordId = (ID)incidentID;
      BMCServiceDesk__SRM_RequestDetail__c requestDeatil =  [select id from BMCServiceDesk__SRM_RequestDetail__c where id in (select BMCServiceDesk__FKRequestDetail__c  from BMCServiceDesk__Incident__c where id= :recordId)  limit 1];
      System.debug('Start method:getRequestDetailInputs');
      return getrequestinputdetailsStatic( (String)requestDeatil.id, incidentID );
    }

    @AuraEnabled(cacheable=true)
    public static Data getDetails(String incidentID){
      Data result = new Data();
      result.srInformation = getRequestDetailIformation(incidentID);// not required
      result.srInputDetails = getRequestDetailInputs(incidentID);
      result.dataDisplayInSecondColumn = displayInSecondColumn;
      result.isEditableSR =   iseditableSR(incidentID);
      return result;
    }

    @TestVisible private static List<BMCServiceDesk__SRM_RequestDetailInputs__c> getrequestinputdetailsStatic( String reqdetId, String incidentId){
        //User currentUser = [Select Id,Name,Email,HD_View_Helpdesk_Confidential_Data__c from User where Id=:userinfo.getuserId() LIMIT 1];
        List<BMCServiceDesk__SRM_RequestDetailInputs__c> reqDetinput = [select Id,Name,BMCServiceDesk__Input__c,BMCServiceDesk__Response__c,
                                                                        BMCServiceDesk__StoredValue__c,HD_Secure_Response__c,HD_Aes_Key__c ,
                                                                        BMCServiceDesk__FKFulfillmentInputs__r.HD_Secure_Field__c, HD_Ffi_Secure_Flag__c,
                                                                        HD_Ffi_Response_Type__c,
                                                                        BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__DisplayInSecondColumn__c,
                                                                        BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Tooltip__c,
                                                                        BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__AdditionalInfo__c from
                                                                        BMCServiceDesk__SRM_RequestDetailInputs__c where  BMCServiceDesk__History__c != true and
                                                                        BMCServiceDesk__FKRequestDetail__c =: reqdetId and BMCServiceDesk__FKFulfillmentInputs__c !=null  AND BMCServiceDesk__FKFulfillmentInputs__r.HD_Staff_Console_Hidden__c != true order by BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Order__c asc  limit 100 ];
		Boolean isAccessible = isAccessible(incidentId, null);
        for(BMCServiceDesk__SRM_RequestDetailInputs__c drmreqinp : reqDetinput){
            String responseType = drmreqinp.HD_Ffi_Response_Type__c;
            Boolean secureFlag = drmreqinp.HD_Ffi_Secure_Flag__c;
            if(responseType != 'Text Area' && secureFlag) {
                drmreqinp.BMCServiceDesk__Response__c = (isAccessible) ? drmreqinp.HD_Secure_Response__c: drmreqinp.BMCServiceDesk__StoredValue__c;
            }
            
            if(responseType == 'Text Area' && secureFlag == true){
                if(isAccessible  && drmreqinp.HD_Aes_Key__c != null ) {
                  String resp = drmreqinp.BMCServiceDesk__Response__c;
                  String Actualdata = decryptTextAreaDataStatic(drmreqinp.BMCServiceDesk__StoredValue__c,drmreqinp.HD_Aes_Key__c).toString();
                  drmreqinp.BMCServiceDesk__Response__c = Actualdata ;
                }
                else if(!isAccessible) {
                	drmreqinp.BMCServiceDesk__Response__c = 'Data is encrypted' ;
                }
            }
            
            if(drmreqinp.BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__DisplayInSecondColumn__c==true){
                displayInSecondColumn = true;
            }
        }
        return reqDetinput;
   }//
    
   @TestVisible private static blob decryptTextAreaDataStatic( String encryptedStringData,String aesStringKey){
        blob decryptedblobResponse = null;
        try{
            blob decodedencryptedResponseblob = EncodingUtil.base64Decode(encryptedStringData);
            blob decodedAeskeyblob = EncodingUtil.base64Decode(aesStringKey);

            //decrypted blob
            decryptedblobResponse = Crypto.decryptWithManagedIV('AES128', decodedAeskeyblob, decodedencryptedResponseblob);
        }
        catch(exception e){
            System.debug('[Exception]: '+e.getMessage());
        }
        return decryptedblobResponse;
   }

    @AuraEnabled(cacheable=true)
    public static Boolean iseditableSR(String incidentID){
        Profile profile = [Select Name from Profile where Id =: userinfo.getProfileid()];
        BMCServiceDesk__Incident__c incident = [Select BMCServiceDesk__Service_Request_Title__c from BMCServiceDesk__Incident__c WHERE id = :incidentID Limit 1];
        String pname = profile.name;
        String[] accessors;
        Boolean rvalue = false;
        for (HD_Access__mdt acces : [select Accessor__c, Accessor_Type__c, Access_Type__c, Entity_Type__c FROM HD_Access__mdt WHERE Entity_Type__c = 'Service Request']){
            if (acces.Accessor_Type__c == 'Profile'){
                if(acces.Accessor__c != null && acces.Accessor__c.trim() != ''){
                    for ( String acc : acces.Accessor__c.split(',')){
                        if (acc == pname){
                            rvalue = true;
                            break;
                        }
                    }
                }
            }

            if (acces.Accessor_Type__c == 'ServiceRequestTitle'){
                if(acces.Accessor__c != null && acces.Accessor__c.trim() != ''){
                    for ( String acc : acces.Accessor__c.split(',')){
                        if (acc == incident.BMCServiceDesk__Service_Request_Title__c){
                            rvalue = true;
                            break;
                        }
                    }
                }
            }
        }
      return rvalue;
    }
}