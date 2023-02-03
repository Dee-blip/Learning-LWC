//Created by Ujjawal Somani as part of MARIT
public class MARIT_OpportunityTriggerHandler extends ApexTriggerHandlerAbstractClass{
    public override void beforeInsertBeforeUpdateTrigger(){
        
        List<String> OpportunityFormulaFieldsForCDP = MarketingUtilClass.getMarketingSettingValuePartialMatch('OpportunityFormulaFieldsForCDP');
        OpportunityFormulaFieldsForCDP = String.join(OpportunityFormulaFieldsForCDP,',').split('\\s*,\\s*');
        Set<String> ChangesInOpportunityFormulaFieldsForCDP = new Set<String>(OpportunityFormulaFieldsForCDP);
        //MARIT-1070
        Map<Id,Opportunity> opportunityForPopulatingLeadOwner = new Map<Id,Opportunity>();
        
        for(SObject so: newList)
        {
            Opportunity oppRecNew = (Opportunity)so;
            Opportunity oppRecOld = Trigger.isUpdate ? (Opportunity)oldMap.get(oppRecNew.Id) : null;
            if(Util.hasChanges(ChangesInOpportunityFormulaFieldsForCDP,oppRecOld,oppRecNew)){
                oppRecNew.Updated_Date_For_CDP__c=System.now();
            }
            //MARIT-1070
            if(Util.hasChanges('Associated_Lead__c',oppRecOld,oppRecNew)){
                if(oppRecNew.Associated_Lead__c == null){
                    oppRecNew.Associated_Lead_Owner__c = null;
                }else{
                   opportunityForPopulatingLeadOwner.put(oppRecNew.Associated_Lead__c,oppRecNew); 
                }
            }
            
        }
        
        //MARIT-1070
        if(opportunityForPopulatingLeadOwner != null && !opportunityForPopulatingLeadOwner.isEmpty()){
            MARIT_OpportunityTriggerClass.updateAssociatedLeadOwner(opportunityForPopulatingLeadOwner);
        }
    }
    
    public override void beforeDeleteBeforeUndeleteTrigger(){
        
    }
    
    public override void afterInsertAfterUpdateTrigger(){
        
    }
    
    public override void afterDeleteAfterUndeleteTrigger(){
        
    }
}