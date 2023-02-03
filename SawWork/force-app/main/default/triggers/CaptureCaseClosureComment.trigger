/*
   
Last Modified BY      Last Modified Date  Purpose
----------------      ------------------  ---------
Akhila                06-01-14        CR#2883378 : Added DR bypass condition
*/

trigger CaptureCaseClosureComment on Case (after update)
{
 if(!UserInfo.getName().equalsIgnoreCase('Connection User'))
 {
    List<Case> listOfNewCases = Trigger.new;
List<casecomment> lstcommnet = listOfNewCases [0].casecomments;

    Integer numberOfCases = listOfNewCases.size();
    if(numberOfCases == 1) {         
        //put first element of list in Case object...
        Case c=listOfNewCases.get(0);
        system.debug('case Id'+c.Id);
        if(c.Status == 'Closed' && c.Origin == 'Jive' && c.Postback_Options__c!=NULL){
            system.debug('Checking condition');
            List<CaseComment> caseCommentsList = [select CommentBody from CaseComment where ParentId = :c.Id ORDER BY LastModifiedDate DESC LIMIT 1];       
            //add order by
            List<Community_Case_Closure_Comments__c> list_commentToInsert = new List<Community_Case_Closure_Comments__c>();
           
            for (CaseComment eachComment : caseCommentsList ) {
          
                list_commentToInsert.add
                (    
                    new Community_Case_Closure_Comments__c
                    (  
                        Case_Closure_Comments__c= eachComment.CommentBody,
                        Community_Postback_Notifications__c = c.Postback_Options__c,
                        Case__c = c.Id
                    )
                );  
               
                upsert list_commentToInsert;
            } 
    
        }        
          
    }
    else{
        //do nothing as this is a bulk insert
    }
 }
}