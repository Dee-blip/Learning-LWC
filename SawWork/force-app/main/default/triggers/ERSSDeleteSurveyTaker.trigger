trigger ERSSDeleteSurveyTaker on RSS_Form__c (before delete) {

    List<SurveyTaker__c> lSurveyTakerToDelete = new List<SurveyTaker__c>();
    List<Id> lRSSFormId = new List<Id>();
    List<RSS_Form__c> lRSSFormWithProducts = new List<RSS_Form__c>();
    
    Map<Id,String> mRSSFormIdAndProducts = new Map<Id,String>();

    if(Trigger.isDelete && Trigger.isBefore)
    {
        for(RSS_Form__c objRSSForm: Trigger.Old)
        {
            lRSSFormId.add(objRSSForm.Id);
        }
        
        for(SurveyTaker__c objSurveytaker: [SELECT Id FROM SurveyTaker__c WHERE RSS_Form__c IN :lRSSFormId])
        {
            lSurveyTakerToDelete.add(objSurveytaker);
        }
        
        if(lSurveyTakerToDelete.size()>0)
        {
            try
            {
                delete lSurveyTakerToDelete;
            }
            
            catch(Exception e)
            {
                system.debug('Exception in Trigger #ERSSDeleteSurveyTaker' + e);
            }
        }
    }
    
    
}