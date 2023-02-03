trigger ContentVersionTrigger_bi_bu on ContentVersion (before insert, before update) {
    for(ContentVersion cvRec : Trigger.new)
    {
        cvRec.Tag__c = cvRec.TagCsv;
    }
    for(ContentVersion cv : Trigger.new){
        if(cv.Display_Title__c==null){
            cv.Display_Title__c=cv.Title;
        }
    }
    
}