trigger ERSSQuestionClone on Survey_Question__c (before update) {
    /*
    Map<String,Survey_Question__c > mUniqueNameAndQues = new Map<String,Survey_Question__c>();
    Map<String, Survey_Question__c> mUniqueNameAndQuesOld = new Map<String,Survey_Question__c>();
    system.debug('####' + mUniqueNameAndQues);
    if(Trigger.isInsert && Trigger.isBefore)
    {
        for(Survey_Question__c objsurvey : Trigger.New)
        {
            mUniqueNameAndQues.put(objsurvey.UniqueName__c,objsurvey );
        }
        
        system.debug('###0' + mUniqueNameAndQues);
        
        if(mUniqueNameAndQues.keySet().size()>0)
        {
            for(Survey_Question__c objsurvey :[SELECT Id, UniqueName__c,Choices__c,Question__c,Type__c 
                                               FROM Survey_Question__c WHERE UniqueName__c IN : mUniqueNameAndQues.keySet() ORDER BY createdDate DESC])
            {
                if(! mUniqueNameAndQuesOld.containsKey(objsurvey.UniqueName__c))
                {
                    mUniqueNameAndQuesOld.put(objsurvey.UniqueName__c,objsurvey);
                }    
            }
            
            system.debug('###1' + mUniqueNameAndQuesOld);
            system.debug('###2' + mUniqueNameAndQues);
            for(String objTemp : mUniqueNameAndQues.keySet())
            {
                system.debug('###3' + mUniqueNameAndQuesOld.containsKey(objTemp));
                if(mUniqueNameAndQuesOld.containsKey(objTemp))
                {
                    system.debug('###4' + mUniqueNameAndQuesOld.containsKey(objTemp));
                    if(mUniqueNameAndQuesOld.get(objTemp).Choices__c != mUniqueNameAndQues.get(objTemp).Choices__c ||
                       mUniqueNameAndQuesOld.get(objTemp).Question__c != mUniqueNameAndQues.get(objTemp).Question__c ||
                       mUniqueNameAndQuesOld.get(objTemp).Type__c != mUniqueNameAndQues.get(objTemp).Type__c)
                    {
                        mUniqueNameAndQues.get(objTemp).UniqueName__c = GuidUtil.NewGuid();
                    }   
                }
            }
            
            //insert mUniqueNameAndQues.values();
        }
        
        */
        for(Survey_Question__c objsurvey : Trigger.New)
        {    
            system.debug('###1' + Trigger.New);
            system.debug('###2' + objSurvey.Choices__c != Trigger.oldMap.get(objSurvey.Id).Choices__c
               && objSurvey.Question__c != Trigger.oldMap.get(objSurvey.Id).Question__c
               && objSurvey.Type__c != Trigger.oldMap.get(objSurvey.Id).Type__c);
            if(objSurvey.Choices__c != Trigger.oldMap.get(objSurvey.Id).Choices__c
               || objSurvey.Question__c != Trigger.oldMap.get(objSurvey.Id).Question__c
               || objSurvey.Type__c != Trigger.oldMap.get(objSurvey.Id).Type__c)
            {
                objSurvey.UniqueName__c = GuidUtil.NewGuid();
            }
            
        } 
   // }

}