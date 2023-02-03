/*Created By: Vivek Baidya
* Created Date: 18-May-2018
* Description: Trigger handler for DealSupportRequest Trigger. 
*/
public without sharing class DealSupportRequestTriggerHandler extends ApexTriggerHandlerAbstractClass {

    public static Boolean objectToFieldMapFirstRunFlag = true;
    public static Map <String, Object> objectToFieldMap = new Map <String, Object>();

    public override void beforeInsertBeforeUpdateTrigger(){
        List<Deal_Support_Request__c> dsrTriggerNew = (List<Deal_Support_Request__c>)newList;
        Map<Id,Deal_Support_Request__c> dsrTriggerOldMap = (Map<Id,Deal_Support_Request__c>)oldMap;
        List<Deal_Support_Request__c> dsrsToPopulatePEOnStatusChange = new List<Deal_Support_Request__c>();
        List<Deal_Support_Request__c> dsrRequestTypeChange = new List<Deal_Support_Request__c>();  
        Map<Deal_Support_Request__c, Id> DSR_OppId = new Map<Deal_Support_Request__c, Id>();
        List<Deal_Support_Request__c> newDsrList = new List<Deal_Support_Request__c>();
        List<Deal_Support_Request__c> changeStatustoInprogressOnSEChange = new List<Deal_Support_Request__c>();
        Map<Id,Deal_Support_Request__c> dsrToProcessApprovals = new Map<Id,Deal_Support_Request__c>();

        String requestTypeForPreSalesRequestRT = GsmUtilClass.getGSMSettingValue('Request_Type_For_DSR_PreSales_Request_RT');

        String preSalesReqRecTypeId = Schema.SObjectType.Deal_Support_Request__c.getRecordTypeInfosByDeveloperName().get('Pre_Sales_Request').getRecordTypeId();
        String ownerNotAssignedUserId = GsmUtilClass.getGSMSettingValue('Owner_Not_Assigned_User_Id');

        for(Deal_Support_Request__c dsr : dsrTriggerNew){
            Deal_Support_Request__c dsrRecOld = null;

            if(Trigger.isInsert && dsr.recordtypeid == preSalesReqRecTypeId){
                if( dsr.Request_Sub_Type__c =='Gating Review' ||  dsr.Request_Sub_Type__c =='Integration Review'){   	
                    dsr.POC_Status__c = 'In Progress';  	
                }   	
                else{   	
                    dsr.POC_Status__c = 'New';  	
                }
                newDsrList.add(dsr);
            }

            if(Trigger.isUpdate)
                dsrRecOld=dsrTriggerOldMap.get(dsr.Id);

            if(dsr.Account__c == NULL && (dsr.Request_Type__c != 'CBR' || dsr.Request_Type__c != 'Workshop') && dsr.Opportunity__c != NULL){
                DSR_OppId.put(dsr, dsr.Opportunity__c);                
            }

            if((Trigger.isInsert  || (Trigger.isUpdate && Util.hasChanges('POC_Status__c', dsrRecOld, dsr))) && dsr.POC_Status__c == 'Completed' && dsr.Request_Type__c == 'CBR' && dsr.End_Date__c == NULL){
                dsr.End_Date__c = Date.Today();
            }
            if(Trigger.isUpdate && dsr.recordtypeid == preSalesReqRecTypeId && Util.hasChanges('POC_Status__c', dsrRecOld, dsr)){
                dsrsToPopulatePEOnStatusChange.add(dsr);
            }

            if(Trigger.isUpdate && dsr.recordtypeid == preSalesReqRecTypeId && Util.hasChanges('SE__c', dsrRecOld, dsr) && String.valueOf(dsrRecOld.SE__c).contains(ownerNotAssignedUserId) && !Util.hasChanges('POC_Status__c', dsrRecOld, dsr) && dsrRecOld.POC_Status__c == 'New'){
                changeStatustoInprogressOnSEChange.add(dsr);
            }

            /*
            if(Trigger.isUpdate && Util.hasChanges('Request_Type__c', dsrRecOld, dsr) && (dsr.Request_Type__c  == 'Web VSE' || dsr.Request_Type__c  == 'Media Technical Consultant')){
                dsrRequestTypeChange.add(dsr);
            }*/
            if(( dsr.Request_Sub_Type__c =='Gating Review' ||  dsr.Request_Sub_Type__c =='Integration Review') &&
            (Trigger.isUpdate && dsr.Approval_Status__c != dsrTriggerOldMap.get(dsr.Id).Approval_Status__c)){
            dsrToProcessApprovals.put(dsr.id,dsr );
            }
            
        }

        if(DSR_OppId.size()>0){
            DealSupportRequestTriggerClass.addAccountToDSR(DSR_OppId);
        }

        if(dsrsToPopulatePEOnStatusChange.size()>0){
            DealSupportRequestTriggerClass.populatePrimarySEOnStatusChange(dsrsToPopulatePEOnStatusChange);
        }
        /*
        if(dsrRequestTypeChange.size()>0){
            DealSupportRequestTriggerClass.actionRequestTypeChange(dsrRequestTypeChange);
        }*/
        
        if(changeStatustoInprogressOnSEChange.size() > 0){
            DealSupportRequestTriggerClass.changeStatustoInProgress(changeStatustoInprogressOnSEChange);
        }

        if(newDsrList.size() > 0){
            DealSupportRequestTriggerClass.populatePrimarySE(newDsrList);
        }
        if(!dsrToProcessApprovals.isEmpty()){
            DealSupportRequestTriggerClass.ProcessApprovalComments(dsrToProcessApprovals);
        }

        ByPassAndLimitUtils.setAkamField(Trigger.isInsert, Trigger.isUpdate, dsrTriggerNew);
    }
    
    public override void afterInsertAfterUpdateTrigger(){
        List<Deal_Support_Request__c> dsrTriggerNew = (List<Deal_Support_Request__c>)newList;
        Map<Id,Deal_Support_Request__c> dsrTriggerOldMap = (Map<Id,Deal_Support_Request__c>)oldMap;
        Map<Id,Deal_Support_Request__c> dsrTriggerNewMap = (Map<Id,Deal_Support_Request__c>)newMap;
        List<Deal_Support_Request__c> dsrToCreateTracking = new List<Deal_Support_Request__c>();
        List<string> requestTypes = GsmUtilClass.getGSMSettingValue('DSR_CreateTracking').split(',');

        Map<Id, Set<String>> IdToFieldSet = new Map<Id, Set<String>>();
        Map<Id, Deal_Support_Request__c> IdToDSR = new Map<Id, Deal_Support_Request__c>();
        List<Deal_Support_Request__c> otmToInsertList = new List<Deal_Support_Request__c>();
        List<Deal_Support_Request__c> sendEmailDSRList = new List<Deal_Support_Request__c>();
        List<Deal_Support_Request__c> dsrChimeStatusUpdate =  new List<Deal_Support_Request__c>();
        set<Id> dsrAprovalComments = new set<Id>();
        Map<Id, Deal_Support_Request__c> dsrOldMap = new Map<Id, Deal_Support_Request__c>();
        List<Deal_Support_Request__c> dsrNewMapList = new List<Deal_Support_Request__c>();


        Id ownerNotAssignedUserId = GsmUtilClass.getGSMSettingValue('Owner_Not_Assigned_User_Id');
        String stages = GsmUtilClass.getGSMSettingValue('DSR_Stages_For_Sending_Emails');
        String DSRRequestType = GsmUtilClass.getGSMSettingValue('DSR_Request_Type_For_Sending_Emails');

        if(Trigger.isUpdate && objectToFieldMapFirstRunFlag){
            objectToFieldMap = (Map <String, Object>) JSON.deserializeUntyped(GSMSettings.getVerbose('CustomNotesObjectFieldMapping'));
            objectToFieldMapFirstRunFlag = false;
        }
        
        for(Deal_Support_Request__c dsr : dsrTriggerNew){
            if(requestTypes.contains(dsr.Request_Type__c) && dsr.POC_Status__c != NULL && (Trigger.isInsert || (Trigger.isUpdate && (dsr.POC_Status__c != dsrTriggerOldMap.get(dsr.Id).POC_Status__c || dsr.Request_Type__c != dsrTriggerOldMap.get(dsr.Id).Request_Type__c)))){
                dsrToCreateTracking.add(dsr);
            }

            if(( dsr.Request_Sub_Type__c =='Gating Review' ||  dsr.Request_Sub_Type__c =='Integration Review') &&
                (Trigger.isInsert|| (Trigger.isUpdate && dsr.Approval_Status__c != dsrTriggerOldMap.get(dsr.Id).Approval_Status__c))){
                dsrChimeStatusUpdate.add(dsr );
                dsrAprovalComments.add(dsr.Id);
            
            }
            if(Trigger.isUpdate){

                Deal_Support_Request__c DsrRecNew = (Deal_Support_Request__c) dsr;
                Deal_Support_Request__c DsrRecOld = (Deal_Support_Request__c)oldMap.get(dsr.Id);

                //Start SFDC-5434
                    if(objectToFieldMap.keyset().contains('Deal_Support_Request__c')){
                        Object innerKeyValue = objectToFieldMap.get('Deal_Support_Request__c');
                        Map <String, Object> fieldMappingForKeyValue = (Map <String, Object>)innerKeyValue;
                        Set<String> fieldSet = new Set<String>();

                        for(String fieldname : fieldMappingForKeyValue.KeySet()){
                            if(Util.hasChanges(fieldname ,DsrRecOld, DsrRecNew)){
                                fieldSet.add(fieldname);
                            }
                                             
                        }
                        if(fieldSet.size()>0){
                            IdToFieldSet.put(DsrRecNew.Id, fieldSet);
                            IdToDSR.put(DsrRecNew.Id, DsrRecNew);    
                        }      

                    }

                //End SFDC-5434
                String preSalesReqRecTypeId = Schema.SObjectType.Deal_Support_Request__c.getRecordTypeInfosByDeveloperName().get('Pre_Sales_Request').getRecordTypeId();
                if(Trigger.isUpdate && (util.hasChanges('SE__c', DsrRecOld,DsrRecNew) || util.hasChanges('Opportunity__c', DsrRecOld,DsrRecNew)) && !String.valueOf(DsrRecNew.SE__c).contains(ownerNotAssignedUserId) && DsrRecNew.Opportunity__c != null && dsr.recordtypeid == preSalesReqRecTypeId){
                    otmToInsertList.add(DsrRecNew);
                }
            }

            if((Trigger.isInsert || (Trigger.isUpdate && Util.hasChanges('POC_Status__c', dsrTriggerOldMap.get(dsr.id), dsr))) && stages.contains(dsr.POC_Status__c) && DSRRequestType.containsIgnoreCase(dsr.Request_Type__c)){
                sendEmailDSRList.add(dsr);
            }

            if(Trigger.isUpdate && Util.hasChanges('SE__c', dsrTriggerOldMap.get(dsr.id), dsr) && DSRRequestType.containsIgnoreCase(dsr.Request_Type__c) &&  !String.valueOf(dsr.SE__c).contains(ownerNotAssignedUserId)){
                dsrOldMap.put(dsr.id, dsrTriggerOldMap.get(dsr.id));
                dsrNewMapList.add(dsr);
            }
        }

        if(dsrNewMapList.size() > 0){
            DealSupportRequestTriggerClass.sendEmailToChangedPrimarySE(dsrOldMap, dsrNewMapList);
        }

        if(IdToDSR.size()>0){
        GsmUtilClass.updateCustomNotes(IdToFieldSet, IdToDSR, 'Deal_Support_Request__c');
        }

        if(otmToInsertList.size() > 0){
            DealSupportRequestTriggerClass.insertOTM(otmToInsertList);
        }

        if(dsrToCreateTracking.size() > 0){
            DealSupportRequestTriggerClass.createAndUpdateDSRTracking(dsrToCreateTracking,dsrTriggerOldMap,Trigger.isUpdate);
        }
        
        if(sendEmailDSRList.size() > 0){
            DealSupportRequestTriggerClass.sendEmail(sendEmailDSRList);
        }
        if(dsrChimeStatusUpdate.size() > 0){
            DealSupportRequestTriggerClass.updateChimeApprovalStatus(dsrChimeStatusUpdate);
        }
        if(dsrAprovalComments.size() > 0){
            DealSupportRequestTriggerClass.ProcessApprovalCommentsFuture(dsrAprovalComments);
        }
    }
    
    public override void beforeDeleteBeforeUndeleteTrigger(){
        
    }
    
    public override void afterDeleteAfterUndeleteTrigger(){
        
    }
}