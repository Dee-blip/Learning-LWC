/*
Author          : Pinkesh / Sumukh SS
Description     : Apex Controller for SOCC Car RunBooks
Test Class      : SC_SOCC_RunBooks_TC, SC_SOCC_Instruction_Manager_TC

Date                 Developer                  JIRA #          Description                                                       
-----------------------------------------------------------------------------------------------------------------
23 Sep 2019         Sumukh/Pinkesh 								SOCC CAR 2 - RunBooks 
13 June 2020		Sumukh SS					ESESP-3694		Handler Creation bugs
27 OCT 2021         Jay              ESESP-6265     Added LIMIT 50000 to unbounded SOQLs
------------------------------------------------------------------------------------------------------------------
*/
public class SC_SOCC_Handler_Controller {
    
    @AuraEnabled
    public static HandlerEscContact saveHandlerCreateInstruction(String Name,String HandlerId,String HandlerType,String pdId,String ElId,String SitInst,String IgnrCon)
    {
        List<SC_SOCC_Escalation_Contact__c> escalationcontactList = new List<SC_SOCC_Escalation_Contact__c>();
        SC_SOCC_Escalation_List__c EscalationList = new SC_SOCC_Escalation_List__c();
        Handler__c newHandler;
        
        //Query Handler Type based on Value 
        String handlerTypeId = [Select Id From Handler_Type__c where Name=:HandlerType limit 1].Id;
        
        if(HandlerId!=null)
        {
            newHandler = new Handler__c(Id=HandlerId);
            newHandler.Name = Name;
            newHandler.Handler_Type__c = handlerTypeId;
            newHandler.Escalation_List__c = ElId;
        }
        else
        {
            newHandler = new Handler__c();
            newHandler.Name = Name;
            newHandler.Handler_Type__c = handlerTypeId;
            newHandler.Policy_Domain__c = pdId;
            newHandler.Escalation_List__c = ElId;
        }
        
        upsert newHandler;
        
        //Create an Instruction and send it for Approval
        List<Instruction__c> lExistingInstruction = [SELECT Id, CreatedBy.Name FROM Instruction__c WHERE Handler__c =:newHandler.Id AND Status__c = 'In Progress' LIMIT 1];
        if(lExistingInstruction.size()>0)
            throw new AuraHandledException('There already exists a pending instruction submitted by ' + lExistingInstruction[0].CreatedBy.Name + '. Please contact him/her for further details.');
        else
        {
            Map<String, String> mInstructionTypeValue = new Map<String, String>();
            //susubram : Detect if just space is there in the instructions 
            if(SitInst!=null)
            { string SitInstwithouthtml = SitInst.replaceAll('<[^>]+>','').replaceAll(' ','');
              if(SitInstwithouthtml.length()>0) mInstructionTypeValue.put('Situation Instruction',SitInst);
            }
            if(IgnrCon!=null)
            {	string Ignrconwithouthtml=IgnrCon.replaceAll('<[^>]+>','').replaceAll(' ','');       
                if(Ignrconwithouthtml.length()>0) mInstructionTypeValue.put('Ignore Condition',IgnrCon);
            }
            
            SC_SOCC_Instruction_Manager.saveInstructionCreateCase(pdId, newHandler.Id, mInstructionTypeValue);
            
        }
        
        
        
        //If EscalationList Id exists query escalation Contacts
        if(newHandler.Escalation_List__c!=null)
        {
            EscalationList = getEscalationListContactDetails(newHandler.Escalation_List__c);
        }
        
        //Create a new Instance of wrapper class
        HandlerEscContact HEscContact = new HandlerEscContact();
        HEscContact.Handler=newHandler;
        HEscContact.EscalationList = EscalationList;
        
        return HEscContact;
    }
    
    @AuraEnabled
    public static SC_SOCC_Escalation_List__c getEscalationListContactDetails(Id EscalationListId)
    {
        return [SELECT Id, Name, Policy_Domain__c,Policy_Domain__r.Account_Name__c, Instructions__c, CreatedBy.Name, CreatedDate,
                (SELECT Id, Name, Order_Number__c, Authorized_Contact__r.Contact_Name__r.Primary_Contact_Method__c,
                 Authorized_Contact__r.Contact_Name__r.Secondary_Contact_Method__c,Authorized_Contact__r.Contact_Name__r.Phone, 
                 Authorized_Contact__r.Contact_Name__r.MobilePhone FROM SC_SOCC_Escalation_Contacts__r ORDER BY Order_Number__c)
                FROM SC_SOCC_Escalation_List__c where Id=:EscalationListId];
    }
    /*Wrapper Class to hold Escalation Contact , Handler and check if the handler has any pending instructions*/
    public class HandlerEscContact 
    {
        @AuraEnabled public Handler__c Handler{get;set;}
        @AuraEnabled public SC_SOCC_Escalation_List__c EscalationList{get;set;}
        @AuraEnabled public boolean HasActiveInstruction{get;set;}
    }
    
    @AuraEnabled
    public static HandlerEscContact getHandlerEscalationContact(Id handlerId)
    {
        Handler__c Handler = [Select Id, Name,Handler_Type__c,Handler_Type__r.Fields_To_Show__c, Policy_Domain__c,Escalation_List__c,Situation_Instruction__c,Ignore_Condition__c,Handler_Type__r.Name from Handler__c where Id=:handlerId];
        SC_SOCC_Escalation_List__c EscalationList = new SC_SOCC_Escalation_List__c();
        
        if(Handler.Escalation_List__c!=null)
        {
            EscalationList = getEscalationListContactDetails(Handler.Escalation_List__c);
        }
        
        //Create a new Instance of wrapper class
        HandlerEscContact HEscContact = new HandlerEscContact();
        HEscContact.Handler=Handler;
        HEscContact.EscalationList = EscalationList;
        
        list<Instruction__c>  PendingInstructions = new list<Instruction__c>();
        PendingInstructions=[select id from Instruction__c where Handler__c =:handlerId and Status__c ='In Progress'];
        if(PendingInstructions.size() > 0)
            HEscContact.HasActiveInstruction=true;
        else
            HEscContact.HasActiveInstruction=false;
        return HEscContact;
        
    }
    
    
    
    /** New Wrapper to Hold policy domain/Handler Type/EsclationList record for Handler Edit Custom Component **/
    public class HandlerCompleteRecord
    {
        @AuraEnabled public Policy_Domain__c policyDomain{get;set;}
        @AuraEnabled public Handler_Type__c handlerType {get;set;}
        @AuraEnabled public Handler__c handler{get;set;}
        @AuraEnabled public SC_SOCC_Escalation_List__c escalationList{get;set;}
        
    }
    
    @AuraEnabled
    public static HandlerCompleteRecord getHandlerCompleteDetails(Id handlerId)
    {
        System.debug('handlerId'+handlerId);
        //get pd Id
        List<Handler__c> handlerrec  = [Select Id,Name,Policy_Domain__c,Situation_Instruction__c,Ignore_Condition__c,Escalation_List__c,Handler_Type__r.Name from Handler__c where Id=:handlerId limit 1];
        
        List<Policy_Domain__c> policyDomain = [Select Id,Name from Policy_Domain__c where Id=:handlerrec[0].Policy_Domain__c limit 1];
        
        //Create a Handler Type Object Instance
        Handler_Type__c handlertyperec = [Select Id,Name,fields_to_show__c from Handler_Type__c where Name=:handlerrec[0].Handler_Type__r.Name];
        
        
        //Get Escalation List and contacts
        SC_SOCC_Escalation_List__c escalationListdet = new SC_SOCC_Escalation_List__c();
        if(handlerrec[0].Escalation_List__c!=null)
        {
            escalationListdet = getEscalationListContactDetails(handlerrec[0].Escalation_List__c);
        }
        
        
        
        HandlerCompleteRecord HandlerCompleteRecord = new HandlerCompleteRecord();
        HandlerCompleteRecord.policyDomain = policyDomain[0];
        HandlerCompleteRecord.handlerType  = handlertyperec;
        HandlerCompleteRecord.handler  = handlerrec[0];
        HandlerCompleteRecord.escalationList = escalationListdet;
        
        System.debug(HandlerCompleteRecord);
        
        return HandlerCompleteRecord;
        
        
    }
    
    /** Method to Prepopulate Policy Domain when creating new Handler **/
    @AuraEnabled
    public static Policy_Domain__c getPolicyDomainRecord(String pdID)
    {
        List<Policy_Domain__c> policyDomainList =  [Select Id,Name from Policy_Domain__c where Id=:pdID];
        return policyDomainList[0];
    }
    /** End of Method to Prepopulate Policy Domain when creating new Handler **/
    
    /*** Method to fetch fields to show for HandlerType **/
    @AuraEnabled(cacheable=true)
    public static list<Handler_Type__C> getFieldstoShow()
    {
        return [Select Name,Fields_to_Show__C from Handler_Type__C LIMIT 50000];
    }
    
    /** End of Method to fetch fields to show for HandlerType ***/
    
    
}