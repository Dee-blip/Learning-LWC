trigger ERSSUpdateProductsOnRSSForm on SurveyTaker__c (after insert, after delete)
{
    //Trigger for Updating Products on RSS Form
    
    List<Id> lRSSToUpdateId = new List<Id>();
    //List<Id> lRSSFormId = new List<Id>();
    List<RSS_Form__c> lRSSFormWithProducts = new List<RSS_Form__c>();
    
     Map<Id,String> mRSSFormIdAndProducts = new Map<Id,String>();
    
    if(Trigger.isInsert && Trigger.isAfter)
    {
        for(SurveyTaker__c objSurveyTaken : Trigger.New)
        {
            lRSSToUpdateId.add(objSurveyTaken.RSS_Form__c);
            //lRSSFormId.add(objSurveyTaken.RSS_Form__c);
        }
        
        RSSUtility.updateProductInfoOnRSSForm(lRSSToUpdateId);
        
        
    }
    
    if(Trigger.isAfter && Trigger.isDelete)
    {
        for(SurveyTaker__c objSurveyTaken : Trigger.Old)
        {
            lRSSToUpdateId.add(objSurveyTaken.RSS_Form__c);
        }
        
        RSSUtility.updateProductInfoOnRSSForm(lRSSToUpdateId);
    }

}