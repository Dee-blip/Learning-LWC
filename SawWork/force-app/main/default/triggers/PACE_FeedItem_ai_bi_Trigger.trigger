trigger PACE_FeedItem_ai_bi_Trigger on FeedItem(after insert) {
    
        if(Trigger.isInsert && (Trigger.isAfter)){
            PACE_FeedManagement.afterFeedInsert(Trigger.new);
           }  
   
}