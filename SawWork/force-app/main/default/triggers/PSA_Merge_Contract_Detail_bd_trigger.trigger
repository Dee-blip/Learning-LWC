trigger PSA_Merge_Contract_Detail_bd_trigger on Merge_Contract_Detail__c (before delete) {
    If(trigger.isBefore && trigger.isDelete){
        System.debug('pt evnt ');
        List<PSA_Contract_Detail_Delete__e> publishEvents = new List<PSA_Contract_Detail_Delete__e>();
        for(Merge_Contract_Detail__c conDetail : Trigger.old){
            PSA_Contract_Detail_Delete__e eve = new PSA_Contract_Detail_Delete__e();
            eve.Contract_Detail_ID__c = conDetail.Name ;
            publishEvents.add(eve);            
        }
        if(publishEvents.size()>0){
            System.debug('ins' );
            EventBus.publish(publishEvents);
            //System.debug('buss :' + Eventbus) ;
        }
        
    }

}