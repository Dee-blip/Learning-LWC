/**
 * @description       : Controller class for all Manage DSRs
 * @author            : apyati
 * @team              : GSM
 * @last modified on  : 01-17-2022
 * @last modified by  : apyati
 * Modifications Log
 * Ver   Date         Author   Modification
 * 1.0   11-16-2021   apyati   SFDC-8653 Initial Version
**/
public class ChimeDSRController {
  
    @AuraEnabled
    public static List<Deal_Support_Request__c> getChimeProductApprovalDSRs(string chimeId){

        List<Deal_Support_Request__c> lstDSRs = new List<Deal_Support_Request__c>();
        try {

            lstDSRs = [SELECT Id, Name, Product__c,Account__c, Account__r.Name, Opportunity__c, Opportunity__r.Name, CHIME__c, CHIME__r.Name, Request_Type__c, Approval_Status__c ,Notes__c, Request_Sub_Type__c
                        FROM Deal_Support_Request__c  WHERE CHIME__c = : chimeId AND (Request_Sub_Type__c = 'Gating Review' OR Request_Sub_Type__c = 'Integration Review')];

            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        
        return lstDSRs;
    }

    @AuraEnabled
    public static List<Deal_Support_Request__c> getUnAssociatedChimePOCDSRs(string chimeId, string opportunityId){

        
        List<Deal_Support_Request__c> lstDSRs = new List<Deal_Support_Request__c>();
        try {

            lstDSRs = [SELECT Id, Name, Product__c,POC_Status__c,Start_Date__c, Success_Criteria__c,Account__c, Account__r.Name, Opportunity__c, Opportunity__r.Name, CHIME__c, CHIME__r.Name, Request_Type__c, Approval_Status__c ,Notes__c
                        FROM Deal_Support_Request__c  WHERE Opportunity__c = : opportunityId AND CHIME__c = Null AND Request_Type__c='POC' ];

            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        System.debug('DSRS'+ lstDSRs);

        return lstDSRs;
    }


    @AuraEnabled
    public static List<Deal_Support_Request__c> getAssociatedChimePOCDSRs(string chimeId){

        List<Deal_Support_Request__c> lstDSRs = new List<Deal_Support_Request__c>();
        try {

            lstDSRs = [SELECT Id, Name, Account__c,Product__c,POC_Status__c,Start_Date__c, Success_Criteria__c, Account__r.Name, Opportunity__c, Opportunity__r.Name, CHIME__c, CHIME__r.Name, Request_Type__c, Approval_Status__c ,Notes__c
                        FROM Deal_Support_Request__c  WHERE CHIME__c = : chimeId AND Request_Type__c='POC'];

            
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        System.debug('DSRS'+ lstDSRs);

        return lstDSRs;
    }

    @AuraEnabled
    public static string associateChimePOCDSRs(List<Deal_Support_Request__c> selectedDSRs , String chimeId){
        String msg= '';
        System.debug('DSRS'+ selectedDSRs);
        System.debug('chimeId'+ chimeId);

        try {
            if(selectedDSRs?.size()>0){
                for(Deal_Support_Request__c dsr :selectedDSRs){
                    dsr.CHIME__c = chimeId;
                }
                update selectedDSRs;


                msg='POC DSRs associated to Chime Successfullly';
            }
            else{
                msg='No DSR selected to associate to Chime';
            }
               

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

         return msg;
    }


    @AuraEnabled
    public static string disassociateChimePOCDSRs(List<Deal_Support_Request__c> chimeDSRs ){
        String msg= '';
        System.debug('DSRS'+ chimeDSRs);
        try {
            if(chimeDSRs?.size()>0){
                for(Deal_Support_Request__c dsr :chimeDSRs){
                    dsr.CHIME__c = null;
                }
                update chimeDSRs;
                msg='POC DSRs are removed from  Chime Successfullly';
            }
            else{
                msg='No DSR selected to remove from Chime';
            }

        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }

         return msg;
    }


    @Auraenabled(cacheable=true)
    public static map<string,List<string>>  getLayoutFields(string objectName)
    {
        String layoutname = GsmUtilClass.getGSMSettingValue('CHIME_DSRPOCLayout');
        return getFields(objectName,layoutname);
    }


    



    static map<string,List<string>> getFields( string objectName,string layout ) {

        Map<String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap();
        string layoutName=String.format('{0}-{1}', new String[]{objectName, layout}); 
        List<Metadata.Metadata> layouts = Metadata.Operations.retrieve(Metadata.MetadataType.Layout, new List<String> {layoutName});
        //get only layout name
        map<string,List<string>> sectionFields=new  map<string,List<string>>();
        Metadata.Layout layoutMd = (Metadata.Layout)layouts.get(0);
        for (Metadata.LayoutSection section : layoutMd.layoutSections) {
            if(section.label!= 'System Information' && section.label!='Custom Links'){
                List<string> fields=new  List<string>();
                Integer length = section?.layoutColumns[0]?.layoutItems?.size()> section?.layoutColumns[1]?.layoutItems?.size() ? section?.layoutColumns[0]?.layoutItems?.size() : section?.layoutColumns[1]?.layoutItems?.size();
                for(Integer i=0; i<length; i++){
                    if(i <section?.layoutColumns[0]?.layoutItems?.size()){
                        fields.add(section?.layoutColumns[0]?.layoutItems[i]?.field);
                    }
                    if(i <section?.layoutColumns[1]?.layoutItems?.size()){
                        fields.add(section?.layoutColumns[1]?.layoutItems[i]?.field);
                    }
                    
                }
                /*
                for (Metadata.LayoutColumn column : section.layoutColumns) {
                    if (column.layoutItems != null) {
                        for (Metadata.LayoutItem item : column.layoutItems) {
                            fields.add(item.field);
                        }
                    }
                }*/
                sectionFields.put(section.label, fields);
            }
        }
        return sectionFields;
    }

}