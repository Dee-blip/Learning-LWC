/*
* File Name: HD_SRHiddenFields
* Description : 
* @author :
* Modification Log ===============================================================
* Date 				Author 				Modification
* Aug 08th, 2020    Aneesh Budnar       PRTORES-1810 - Code scanner fixes
*/
public class HD_SRHiddenFields {

    public String incId;
    
    public List<BMCServiceDesk__SRM_RequestDetailInputs__c> requestInputs;

    public void setIncId(String id_value){
        incId = id_value;
    }
    public String getIncId(){
        return incId;
    }
    
    
    
    @TestVisible private List<BMCServiceDesk__SRM_RequestDetail__c> getRequestDetail(Id incID){
        return [select id, BMCServiceDesk__FKRequestDefinition__r.name from BMCServiceDesk__SRM_RequestDetail__c 
                where id in (select BMCServiceDesk__FKRequestDetail__c  from 
                             BMCServiceDesk__Incident__c where id =:incID)  limit 1];
        
    }  
    
    
    public List<BMCServiceDesk__SRM_RequestDetailInputs__c> getRequestInputs(){
        
        List<BMCServiceDesk__SRM_RequestDetail__c> rd = getRequestDetail(this.incID);
        if(rd == null || rd.size()==0){
            return new List<BMCServiceDesk__SRM_RequestDetailInputs__c>();
        }
		ID reqId = (ID)getRequestDetail(this.incID)[0].id;      
        
        
        return [select Id,Name,BMCServiceDesk__Input__c,BMCServiceDesk__Response__c, 
                HD_Ffi_Response_Type__c, HD_Input_Prompt_Type__c  from 
                BMCServiceDesk__SRM_RequestDetailInputs__c where 
                BMCServiceDesk__FKRequestDetail__c =:reqId and 
                BMCServiceDesk__FKFulfillmentInputs__c !=null 
                order by BMCServiceDesk__FKFulfillmentInputs__r.BMCServiceDesk__Order__c asc  limit 100 ];
        
    }
	
}