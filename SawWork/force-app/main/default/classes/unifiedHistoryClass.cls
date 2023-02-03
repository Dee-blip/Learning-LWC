global class unifiedHistoryClass implements comparable {
        
        //fields generic to History , action history and Approval
        // this variable identifies weather a history, action History or Approval
      @AuraEnabled  public Boolean insertMe {get;set;}
       @AuraEnabled public String objecttype {get; set;}
       @AuraEnabled public String datetime_unified {get; set;}
       @AuraEnabled public String action {get; set;}
       @AuraEnabled public String record_action {get; set;}
       @AuraEnabled public String user_staff_name {get; set;}
        
        //history specific fields
       @AuraEnabled public Id user {get; set;}
       @AuraEnabled public String connection {get; set;}
       @AuraEnabled public String who {get; set;}
        
        //Action History specific field
       @AuraEnabled public Id incident_History_ID {get; set;}
       @AuraEnabled public String incident_History_ID_name {get; set;}
       @AuraEnabled public Id user_staff_ID {get; set;}
       @AuraEnabled public String action_History_Description {get; set;}
       @AuraEnabled public String duration {get; set;}
       @AuraEnabled public String note {get; set;}
       @AuraEnabled public String richNote {get; set;}
       @AuraEnabled public String actionId {get; set;}
        
        //Approval History specific field
       @AuraEnabled public String approval_overall_Status {get; set;}
       @AuraEnabled public List<unifiedStepsandworkitemClass> stepandworkitemunifiedlist {get; set;}
    
    
      public enum SORT_BY 
      {
        Bydatetime_unified,Byobjecttype
      }


        
       public unifiedHistoryClass(){
           this.insertMe = false;
           this.action='';
        }
    //Variable to decide the member on which sorting should be performed
    public static SORT_BY sortBy = SORT_BY.Bydatetime_unified;
    
      global Integer compareTo(Object objToCompare) 
      {
       //Sort by BookName Alphabetically
      if(sortBy == SORT_BY.Byobjecttype)
      {
              return objecttype.compareTo(((unifiedHistoryClass)objToCompare).objecttype);
      }
      else
      {
        if (datetime_unified == ((unifiedHistoryClass)objToCompare).datetime_unified) return 0;
        if (datetime_unified > ((unifiedHistoryClass)objToCompare).datetime_unified) return 1;
              return -1;
       }

      }//global Integer compareTo(Object objToCompare) 
    
        
    }//END unifiedHistoryClass