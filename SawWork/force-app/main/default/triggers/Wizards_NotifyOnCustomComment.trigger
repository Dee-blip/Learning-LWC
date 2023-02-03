trigger Wizards_NotifyOnCustomComment on IdeaComment__c (after insert) {
    List<IdeaComment__c> comments = new List<IdeaComment__c>();
    Map<Id,IdeaComment__c> newICMap = new Map<Id,IdeaComment__c>();
    Wizards_ICAfterTriggerClass notifyOnComment = new Wizards_ICAfterTriggerClass();
        Integer j = 0;
        while (j < trigger.new.size())
        {
          IdeaComment__c curComment = trigger.new.get(j);
          if(!curComment.IsDataLoad__c)
          {
            comments.add(curComment);
            newICMap.put(curComment.Id, curComment);
          }
          j++;
        }
    if(comments.size() > 0){
        notifyOnComment.sendNotification(comments, newICMap);
    }
}