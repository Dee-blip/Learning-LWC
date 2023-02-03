public without sharing class HD_DetailControllerUtils {
	
    
   
    @AuraEnabled
    public static HD_IncidentDetailController.Data getTicketDetails(String recordId){
      	//List<Map<String,String>> incDetailsMap = new List<Map<String,String>>();
        Id incId = (ID)recordId;
        HD_IncidentDetailController.Data result = new HD_IncidentDetailController.Data();

        result.summary = 'dasdas';
        bmcservicedesk__incident__c incDetails = [select owner.name, BMCServiceDesk__FKClient__r.username, BMCServiceDesk__incidentDescription__c,BMCServiceDesk__Type__c,Name, BMCServiceDesk__incidentResolution__c, BMCServiceDesk__FKRequestDefinition__r.BMCServiceDesk__serviceRequestTitle__c, BMCServiceDesk__shortDescription__c from bmcservicedesk__incident__c where id = :incId];
        result.username = (String)incDetails.BMCServiceDesk__FKClient__r.username;
        result.summary= (String)incDetails.BMCServiceDesk__incidentDescription__c;
        result.resolution = (String)incDetails.BMCServiceDesk__incidentResolution__c;
        result.owner = (String)incDetails.owner.name;
        result.type = (String)incDetails.BMCServiceDesk__Type__c;
        result.name = (String)incDetails.Name;
        result.requestTitle = (String)incDetails.BMCServiceDesk__FKRequestDefinition__r.BMCServiceDesk__serviceRequestTitle__c;
        result.shortDescription = (String)incDetails.BMCServiceDesk__shortDescription__c;
        return result;
    }
    
    @AuraEnabled
    public static Map<String,String> getClientInfo(String recordId) {
		List<Schema.FieldSetMember> fsList = SObjectType.BMCServiceDesk__Incident__c.FieldSets.Client_Information.getFields();
        Map<String,String> clientInfo = new Map<String,String>();
        
        Id incId = (ID)recordId;
        String query = 'SELECT '; 
        for(Schema.FieldSetMember f : fsList) {
             //System.debug(f.getLabel());
             //System.debug(f.getFieldPath());
             query += f.getFieldPath() + ', ';
            
        }
        query += 'Id, Name FROM BMCServiceDesk__Incident__c where Id =:recordId'; // cs-fix PRTORES-1581 shegade
		System.debug(Database.query(query));
        BMCServiceDesk__Incident__c inci = Database.query(query);
        for(Schema.FieldSetMember f : fsList) {
             System.debug((String)inci.get(f.getFieldPath()));
            
             clientInfo.put((String)f.getLabel(),(String)inci.get(f.getFieldPath()));
        }
        System.debug(clientInfo);
        System.debug(clientInfo.get('Client Name'));
       
        return clientInfo;
    }

    @AuraEnabled(cacheable=true)
    public static BMCServiceDesk__Incident__c getClientIncidentData(String recordId){
        return [Select Id, Name, BMCServiceDesk__Type__c, BMCServiceDesk__FKClient__c, BMCServiceDesk__FKClient__r.username,BMCServiceDesk__incidentResolution__c, HD_Client_title__c, BMCServiceDesk__Client_Name__c from BMCServiceDesk__Incident__c where id = :recordId Limit 1];
    }
    
     @AuraEnabled
    public static Boolean getPageSupport(Id incidentId){
        BMCServiceDesk__Incident__c inc = [Select Id,Name,HD_High_Customer_Impact__c from BMCServiceDesk__Incident__c where Id = :incidentId];
        return inc.HD_High_Customer_Impact__c;
    }
    
    @AuraEnabled
    public static String getIncType(Id incId){
        System.debug('In getIncType');
        BMCServiceDesk__Incident__c inc = [Select Id,BMCServiceDesk__Type__c from BMCServiceDesk__Incident__c where Id =:incId LIMIT 1];
        System.debug('Incident object: '+inc);
        System.debug('Type in controller: '+inc.BMCServiceDesk__Type__c);
        return inc.BMCServiceDesk__Type__c;
    }
    @AuraEnabled
    public static BMCServiceDesk__Incident__c getCurrentApprover(ID incidentId){
        BMCServiceDesk__Incident__c  approver = [select id, Approver__r.name, approver__c from  bmcservicedesk__incident__C where id =:incidentId limit 1];
    	return approver;
    }
    
    @AuraEnabled
    public static BMCServiceDesk__Incident__c getIncident(String incidentId){
       BMCServiceDesk__Incident__c inc = [Select Id, Name, CCText__c, BMCServiceDesk__IncidentType__c ,OwnerId,Owner.Name,BMCServiceDesk__FKCategory__r.BMCServiceDesk__FKCategoryType__r.Name, HD_Ticket_Priority__c ,BMCServiceDesk__Category_ID__c,HD_High_Customer_Impact__c,BMCServiceDesk__FKStatus__r.BMCServiceDesk__Stage__c,BMCServiceDesk__Status_ID__c, BMCServiceDesk__clientEmail__c, BMCServiceDesk__Type__c, HD_WhiteHat_Incident__c,Notify_dl_sysadmin_on_status_change__c, Exclude_Client_Notifications__c,Notify_dl_sysadmin_on_creation__c,HD_Notify_DL_EIS_on_Notes_Update__c,HD_System_Admin_Incident__c,HD_Parent_Tree__c From BMCServiceDesk__Incident__c where ID = :incidentId][0];

       return inc;
    }
    
    @AuraEnabled
    public static HD_IncidentDetailController.IncidentAndOptions getIncidentWithPriority(String incidentId){
       BMCServiceDesk__Incident__c inc = [Select Id, Name, CCText__c, BMCServiceDesk__IncidentType__c ,OwnerId,Owner.Name,BMCServiceDesk__FKCategory__r.BMCServiceDesk__FKCategoryType__r.Name, HD_Ticket_Priority__c ,BMCServiceDesk__Category_ID__c,HD_High_Customer_Impact__c,BMCServiceDesk__FKStatus__r.BMCServiceDesk__Stage__c,BMCServiceDesk__Status_ID__c, BMCServiceDesk__clientEmail__c, BMCServiceDesk__Type__c, HD_WhiteHat_Incident__c,Notify_dl_sysadmin_on_status_change__c, Exclude_Client_Notifications__c,Notify_dl_sysadmin_on_creation__c,HD_Notify_DL_EIS_on_Notes_Update__c,HD_System_Admin_Incident__c,HD_Parent_Tree__c From BMCServiceDesk__Incident__c where ID = :incidentId][0];
       HD_IncidentDetailController.IncidentAndOptions incoption =  new HD_IncidentDetailController.IncidentAndOptions();
        incoption.incident = inc;
        if(inc.BMCServiceDesk__Type__c == 'Service Request'){
            List<BMCServiceDesk__SRM_RequestDetailInputs__c> rdInputs = [select Id,Name,BMCServiceDesk__Input__c,BMCServiceDesk__Response__c,
                                                                        BMCServiceDesk__StoredValue__c,HD_Secure_Response__c,HD_Aes_Key__c ,
                                                                        BMCServiceDesk__FKFulfillmentInputs__r.HD_Secure_Field__c, HD_Ffi_Secure_Flag__c,
                                                                        BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__InputValues__c,
                                                                        BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__DisplayInSecondColumn__c,
                                                                        BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__AdditionalInfo__c from
                                                                        BMCServiceDesk__SRM_RequestDetailInputs__c where  BMCServiceDesk__History__c != true and
                                                                        BMCServiceDesk__FKRequestDetail__r.BMCServiceDesk__FKIncident__c  = :inc.Id ];
            String[] inputvalues_splits;
           
            for(BMCServiceDesk__SRM_RequestDetailInputs__c  rdi  : rdInputs){
                if (rdi.BMCServiceDesk__Input__c == 'Priority' ){
                    inputvalues_splits = rdi.BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__InputValues__c.split('П');
                    for(String ivs : inputvalues_splits ){
                        String[] eachOption  = ivs.split('ф');
                        incoption.OptionValues.put(eachOption[0],eachOption[1]);
                        if(eachOption[0] == rdi.BMCServiceDesk__Response__c ){
                            incoption.selectedOpt = eachOption[0];
                        }
                    }
                }
            }
            
        }
       return incoption;
    }
    
    public static BMCServiceDesk__Incident__c getIncidentDeatilsForPrint(Id incidentId){
        BMCServiceDesk__Incident__c incident = [Select Id,Name,BMCServiceDesk__Type__c,HD_Ticket_Priority__c,VIP_Ticket__c,BMCServiceDesk__Category_ID__c,BMCServiceDesk__Status_ID__c, HD_Parent_Tree__c,HD_Owner_user_queue__c, BMCServiceDesk__incidentDescription__c, BMCServiceDesk__incidentResolution__c,BMCServiceDesk__FKClient__r.Name,BMCServiceDesk__FKClient__r.username,BMCServiceDesk__FKClient__r.Phone,BMCServiceDesk__FKClient__r.HD_Region__c,HD_Client_City__c,Client_ID_Email__c,BMCServiceDesk__Client_Name__c,BMCServiceDesk__Client_Phone__c,HD_Total_Effort_Spent_minutes__c from BMCServiceDesk__Incident__c where Id=:incidentId LIMIT 1];
        return incident;
    }
    
    @AuraEnabled
    public static Boolean isAccessableRecord(Id incidentId){
         
      return HD_ActionMenu_Provider.isAccessibleRecord(incidentId);
    }
    
    @AuraEnabled 
    public static boolean isPendingStatus(Id incidentId){
        BMCServiceDesk__Incident__c incident = [Select BMCServiceDesk__FKStatus__r.Name from BMCServiceDesk__Incident__c where Id=:incidentId limit 1];
        String status = incident.BMCServiceDesk__FKStatus__r.Name;
        if(status.equalsIgnoreCase('ON HOLD')||status.equalsIgnoreCase('PENDING CMR')||status.equalsIgnoreCase('PENDING HARDWARE')||status.equalsIgnoreCase('PENDING SOFTWARE')||status.equalsIgnoreCase('PENDING USER RESPONSE')||status.equalsIgnoreCase('PENDING OTHER TEAMS')||status.equalsIgnoreCase('PENDING APPROVAL')||status.equalsIgnoreCase('PENDING OTHERS')||status.equalsIgnoreCase('PENDING THIRD PARTY'))
            return true;
        return false;
    } 
    @AuraEnabled 
    public static List<BMCServiceDesk__Incident__c>  getIncidentRecords(Id IncId,String ticketNumber){
        System.debug('ticketNumber '+ticketNumber);
        if(ticketNumber!=null && ticketNumber!='')
        {
        	List<BMCServiceDesk__Incident__c> inc = [select Id,Name,BMCServiceDesk__Category_ID__c,BMCServiceDesk__Client_Name__c,BMCServiceDesk__Status_ID__c from BMCServiceDesk__Incident__c where Name=:ticketNumber];
        	System.debug('inc:'+inc);
            return inc;
        }
        else
        {
            Id catId = [select BMCServiceDesk__FKCategory__c  from BMCServiceDesk__Incident__c where Id =:IncId].BMCServiceDesk__FKCategory__c;
            System.debug('catId:'+catId);
            List<BMCServiceDesk__Incident__c> inc = [select Id,Name,BMCServiceDesk__Category_ID__c,BMCServiceDesk__Client_Name__c,BMCServiceDesk__Status_ID__c from BMCServiceDesk__Incident__c where BMCServiceDesk__Status_ID__c  !='CLOSED' and BMCServiceDesk__Status_ID__c  !='RESOLVED' and BMCServiceDesk__Status_ID__c  !='CANCELED' and BMCServiceDesk__FKCategory__c = :catId  and id != :IncId and BMCServiceDesk__FKIncident__c = null ORDER BY SystemModstamp DESC limit 40];
            System.debug('inc:'+inc);
            return inc;
                
        }
    }
        
    public static Map<Id,List<String>> getOrgWideAddressSettingFromSysProps() {
        List<BMCServiceDesk__SYSProperties__c> sysProps = [SELECT Id, BMCServiceDesk__property__c, BMCServiceDesk__value__c 
                                                           FROM BMCServiceDesk__SYSProperties__c 
                                                           WHERE BMCServiceDesk__property__c = 'multipleEmailFromAddprop'];
        Map<Id,List<String>> orgWideEmailAccessList = new Map<Id, List<String>>();
        if(sysProps != null && sysProps.size() > 0) {
            List<String> emailConversionSetting = sysProps[0].BMCServiceDesk__value__c.split('П');
            if(emailConversionSetting != null && emailConversionSetting.size() > 0) {
                for(String setting : emailConversionSetting) {
                	List<String> settingEntry = setting.split(':');
                    orgWideEmailAccessList.put(settingEntry[0], new List<String>());
                    if(settingEntry[1].contains(',')) {
                        orgWideEmailAccessList.put(settingEntry[0], settingEntry[1].split(','));
                    }
                    else {
                        orgWideEmailAccessList.put(settingEntry[0], new List<String>{settingEntry[1]});
                    }
                }
            }
        }
        
        return orgWideEmailAccessList;
    }
}