public class WizardsIdeaHistory {
    
    List<Idea> newIdeas;
    Map<Id,Idea> oldIdeasMap;
    Map<String,String> reviewerFields;
    Map<String,String> sponsorFields;
    public WizardsIdeaHistory(List<Idea> newList,Map<Id,Idea> oldMap){
        newIdeas=newList;
        oldIdeasMap=oldMap;
        reviewerFields = WizardsIdeaHistory.getUpdatableFilds();
        sponsorFields = WizardsIdeaHistory.getSponsorFields();

    }


    public static Map<String,String> getUpdatableFilds(){
        //Hardcoded the fields to be tracked
        //TODO : move the fields to custom settings or describe sobject to determine the updatable fields
        return new Map<String,String>
            {   
            'Review_Status__c'=>'Review Status',
            'Review_Sub_Status__c'=>'Review Sub-Status',
            'Reviewer_Email__c'=>'Reviewer',
            'Project_Type__c'=>'Idea Category',
            'Idea_Sub_Category__c'=>'Idea Sub-Category',
            'Feedback__c'=>'Reviewer Feedback',
            'Duplicate_Idea__c'=>'Duplicate of',
            'Similar_to_Idea__c'=>'Similar to',
            'SME_Name__c'=>'SME',
            'SME_Notes__c'=>'SME Notes'
            };
        
    }

    public static Map<String,String> getSponsorFields(){
        return new Map<String,String> 
            {
                'Sponsor_Name__c'=>'Sponsor',
                'Implementation_Status__c'=>'Implementation Status',
                'Sponsor_Notes__c'=>'Sponsor Notes'    
            };
    }


    public Idea_History__c createHistoryRecord(Idea i,String fieldApiName,String field,String section){
        String newValue,oldValue;
        if((String)i.get(fieldApiName)!=null && ((String)i.get(fieldApiName)).length()>200)
            newValue = ((String)i.get(fieldApiName)).substring(1, 200); 
        else
            newValue = (String)i.get(fieldApiName);  

        if( ((String)oldIdeasMap.get(i.Id).get(fieldApiName)!=null) && ((String)oldIdeasMap.get(i.Id).get(fieldApiName)).length()>200)
            oldValue = ((String)oldIdeasMap.get(i.Id).get(fieldApiName)).substring(1, 200); 
        else
            oldValue = (String)oldIdeasMap.get(i.Id).get(fieldApiName);
        
        return new Idea_History__c(
                        Idea__c=i.Id,
                        NewValue__c= newValue,
                        OldValue__c=oldValue,
                        Field__c=field,
                        Section__c=section
                    );
    }
    public void storeHistory(){
        List<Idea_History__c> newData = new List<Idea_History__c>();
        for(Idea i : newIdeas){
            for(String fieldApiName : reviewerFields.keySet()){        
                if(i.get(fieldApiName)!=oldIdeasMap.get(i.Id).get(fieldApiName)){
                    newData.add(createHistoryRecord(i,fieldApiName,reviewerFields.get(fieldApiName),'Reviewer'));
                }
            }
            for(String fieldApiName : sponsorFields.keySet()){        
                if(i.get(fieldApiName)!=oldIdeasMap.get(i.Id).get(fieldApiName)){
                    newData.add(createHistoryRecord(i,fieldApiName,sponsorFields.get(fieldApiName),'Sponsor'));
                }
            }
        }
        
        if(newData.size()>0){
            insert newData;
        }
    }
}