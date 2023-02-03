public with sharing class PACE_FeedManagement {

   // public static String conceptKeyPrefix = PACE_Concept__c.sObjectType.getDescribe().getKeyPrefix();
    public static String phaseKeyPrefix = PACE_Phase__c.sObjectType.getDescribe().getKeyPrefix();

    public static boolean firstRun = true; 


    public static Map<Id,Id> createPhaseProgramMap(Id [] phaseId){

        Map<Id,Id> phaseProgramMap = new Map<Id,Id>();

        for(PACE_Phase__c phase: [Select p.Id, p.PACE_Program__c From PACE_Phase__c p where p.Id in :phaseId]){
            phaseProgramMap.put(phase.Id,phase.PACE_Program__c);
        }
        return  phaseProgramMap;
    }


    public static void afterFeedInsert(FeedItem [] feedList){


        if(PACE_FeedManagement.firstRun){
            List<Id> phaseIds = new List<Id>(); 
            List<FeedItem> feedForAdd = new List<FeedItem>(); 
            //List<Id> feedForDelete = new List<Id>(); 

            Map<Id,Id> phaseProgramMap = null;

            for (FeedItem f : feedList){
                String parentId = f.parentId;
                if(parentId.startsWith(phaseKeyPrefix)){
                    phaseIds.add(f.ParentId);
                }
            }

            phaseProgramMap = createPhaseProgramMap(phaseIds);

            for (FeedItem f : feedList)
            {
                String parentId = f.parentId;
                //We compare the start of the 'parentID' field to the Concept & Phase key prefix to
                //restrict the trigger to act on posts made to the Concept and Phase object.
                if (parentId.startsWith(phaseKeyPrefix))
                {

                    FeedItem notification = new FeedItem();
                    if(f.Type == 'TextPost'){
                        notification.type = 'TextPost';
                        notification.ParentId = phaseProgramMap.get(f.parentId);
                        notification.Title = f.Title;
                        notification.Body = f.Body;
                        feedForAdd.add(notification);
                    }
                    else if(f.Type == 'LinkPost'){
                        notification.type = 'LinkPost';
                        notification.ParentId = phaseProgramMap.get(f.parentId);
                        notification.Body = f.Body;
                        notification.LinkUrl = f.LinkUrl;
                        feedForAdd.add(notification);
                    }           
                }

            }

            PACE_FeedManagement.firstRun = false;
            insert feedForAdd;

        }
    }





}