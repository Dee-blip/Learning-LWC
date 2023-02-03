/* ========================================================================
   *Template           : Apex Class
   *Version            : 1.0
   *@author            : Pranav Prashant @ Akamai Technologies Ltd.
   *Created Date       : 11th May, 2018
   *Purpose            : Provides actions to grant and revoke access to incident records.
                         This class is meant to be called from trigger where 
                         the user looses its read access in case of ticket transfer and 
                         the visualforce email alerts fail because of this.
                           
   *Dependent Classes  : No Dependencies

======================================================================== */

public without sharing class HD_IncidentRecordSharing {
    
    
    public static String recordTypeIdSI;

    //this mehtod adds read access for the records with sharing lable as Helpdesk Custom (old functionality wrappped in new method - @shashank hegade PRTORES 1326)
    public static List<BMCServiceDesk__Incident__share> giveTemporaryReadAccess(List<BMCServiceDesk__Incident__c> newtriggerVersion){

        recordTypeIdSI = Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Service Incident').getRecordTypeId();

        List<BMCServiceDesk__Incident__share> incShrList = new List<BMCServiceDesk__Incident__share>();
        for(BMCServiceDesk__Incident__c inc : newtriggerVersion){
            if(inc.id!=null && inc.RecordTypeId != recordTypeIdSI){  
                BMCServiceDesk__Incident__share incShr = new BMCServiceDesk__Incident__share();
                incShr.ParentId = inc.id;
                incShr.UserOrGroupId = System.UserInfo.getUserId();
                incShr.AccessLevel = 'read';
                incShr.RowCause = BMCServiceDesk__Incident__share.RowCause.Helpdesk_Custom__c;
                incShrList.add(incShr);
                System.debug('sharing set  ' + inc.id);
            }

    }
    return incShrList;
}
    
    
    //this mehtod is modifed to call both temporary read access and read access to cc users @shasahnk hegade PRTORES 1326
    public static void setReadAccess(List<BMCServiceDesk__Incident__c> newtriggerVersion){
        
        
        List<BMCServiceDesk__Incident__share> incShrList = new List<BMCServiceDesk__Incident__share>();
        incShrList.addAll(giveTemporaryReadAccess(newtriggerVersion));
        Map < String, Id> emailToUserIDMap = HD_RemedyForceCustomization_class.getEmailUserMap();
        incShrList.addAll(giveReadonlyAccessToCCUser(newtriggerVersion,emailToUserIDMap));

        try{
           if(incShrList.size()>0){
                Database.SaveResult[] srList = Database.insert(incShrList, false);

            } 
        }catch(Exception e){
            System.debug('EXCEPTION occured while adding sharing rule');
        }
  
        
    }
    
    //this method revokes read access for the records with sharing lable with Helpdesk Custom
    @future
    public static void revokeAccess(List<ID> recordIds){
        
        if(recordIds!=null && recordIds.size()>0){
            List<BMCServiceDesk__Incident__Share> sharing = new  List<BMCServiceDesk__Incident__Share>();
            sharing = [select id, parentId from 
                        BMCServiceDesk__Incident__Share where 
                        RowCause = 'Helpdesk_Custom__c' and
                        parentId = :recordIds];
            
            try{
               if(sharing.size()>0){
                    delete sharing;
                } 
            }catch(Exception e){
                System.debug('EXCEPTION occured while deleting sharing rule');
            }
        }
        
    }

    //This fuction gives read only access to the user CCed in the CC field @shashank hegade PRTORES 1326
    public static List<BMCServiceDesk__Incident__share> giveReadonlyAccessToCCUser(List<BMCServiceDesk__Incident__c> newtriggerVersion, map<string, id> emailToUserIDMap){

        recordTypeIdSI = Schema.SObjectType.BMCServiceDesk__Incident__c.getRecordTypeInfosByName().get('Service Incident').getRecordTypeId();
        
        List<BMCServiceDesk__Incident__share> incShrList = new List<BMCServiceDesk__Incident__share>();
        for(BMCServiceDesk__Incident__c inc : newtriggerVersion){
            if(inc.id!=null && inc.RecordTypeId != recordTypeIdSI){
                Sobject incident_Sobject = new BMCServiceDesk__Incident__c();
                incident_Sobject = inc;
                for (Integer i = 0; i < 10 ; i++){
                    
                    string mailID = (string)incident_Sobject.get('HD_EmailCC' + (i + 1) + '__c');
                    mailID = mailID.toLowercase();
                    if(incident_Sobject.get('HD_EmailCC' + (i + 1) + '__c') != null && incident_Sobject.get('HD_EmailCC' + (i + 1) + '__c') != '' && emailToUserIDMap.get(mailID) != null){
    
                        BMCServiceDesk__Incident__share incShr = new BMCServiceDesk__Incident__share();
                        incShr.ParentId = inc.id;
                        incShr.UserOrGroupId = emailToUserIDMap.get(mailID);
                        incShr.AccessLevel = 'read';
                        incShr.RowCause = BMCServiceDesk__Incident__share.RowCause.Helpdesk_ReadOnly_Access_to_CC_users__c;
                        incShrList.add(incShr);
                        System.debug('giveReadonlyAccessToCCUser ' + inc.id);
                }
            }
            }  
        }
                return incShrList;
    }
    
}