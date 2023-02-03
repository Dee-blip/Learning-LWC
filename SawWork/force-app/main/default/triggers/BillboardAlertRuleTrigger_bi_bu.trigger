trigger BillboardAlertRuleTrigger_bi_bu on Billboard_Alert_Rule__c (before insert, before update) {
    for(Billboard_Alert_Rule__c bb : Trigger.New){
        if(bb.Start_Time__c==NULL)
            bb.Start_Time__c = Datetime.newInstance(bb.Alert_Start_Date__c, Time.newInstance(0, 0, 0, 0));

        if(bb.End_Time__c==NULL)
            bb.End_Time__c= Datetime.newInstance(bb.Alert_End_Date__c, Time.newInstance(23, 59, 59, 59));
    }
}