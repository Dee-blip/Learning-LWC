/*
 	Modification Log ===============================================================
    Date    			      Author  		    Modification
	  Dec  21st, 2020     Aneesh Budnar   PRTORES-342 - Test class code coverage - 6th and Final
*/
public with sharing class HD_Approval_History_component {
    
    public ID TargetObjectIdvalue{get;set;}
    public ID WorkItemIDValue{get;set;}
    public Id loggedInUser{get{ return Userinfo.getUserId();
                              }}
    
    public List<ProcessInstance> processInsList{get;set;}
    public Map<ID,boolean> User_Part_of_Queue{get;set;}
    
    
    
    public boolean IsApprovalPending{get;set;}
    
    public List<ProcessInstance> getApprovalHistory()
    {
        User_Part_of_Queue = new Map<ID,boolean>();
        User_Part_of_Queue.put(loggedInUser,false);
        processInsList = new List<ProcessInstance>();
        List<ProcessInstance>  processInsListPendingStatus =  new List<ProcessInstance>();
        processInsList = [ SELECT Id,TargetObjectId,CreatedDate,Status, (SELECT Id, ActorId, Actor.Name, OriginalActorId, OriginalActor.Name, StepStatus, Comments,CreatedDate  FROM StepsAndWorkitems ORDER BY CreatedDate DESC ) FROM ProcessInstance where TargetObjectId =:TargetObjectIdvalue ORDER BY CreatedDate DESC  LIMIT 20 ];
        processInsListPendingStatus  = [ SELECT Id, Status, CreatedDate,(SELECT Id, ActorId, Actor.Name, OriginalActorId, OriginalActor.Name, StepStatus, Comments,CreatedDate  FROM StepsAndWorkitems ORDER BY CreatedDate DESC ) FROM ProcessInstance where TargetObjectId =:TargetObjectIdvalue ORDER BY CreatedDate DESC LIMIT 1 ];
        //getting if the uder is part of queue or not
        List<GroupMember> ActorPartofQueueIds = new List<GroupMember>();
        ActorPartofQueueIds = [ SELECT Id, Group.Name,Group.Id FROM GroupMember WHERE UserOrGroupId =:loggedInUser AND Group.Type = 'Queue' Limit 200 ];
        if(processInsListPendingStatus.size() > 0)
        {
            for(ProcessInstance prcIns : processInsListPendingStatus)
            {
                
                if(prcIns.Status == 'Pending')
                {
                    
                    IsApprovalPending = true;
                    for( ProcessInstanceHistory stepswiid : prcIns.StepsAndWorkitems)
                    {
                        if(stepswiid.StepStatus == 'Pending')
                        { 
                            
                            //checking if the USer is part of queue or not
                            if(ActorPartofQueueIds.size() > 0)
                            {
                                for(  GroupMember grpmem : ActorPartofQueueIds )
                                {
                                    if( grpmem.Group.Id == stepswiid.OriginalActorId )
                                    {
                                        //adding to MAp
                                        User_Part_of_Queue.put(loggedInUser,true);
                                    }//
                                    
                                }//for( ActorPartofQueueIds )
                            }//if(ActorPartofQueueIds.size() > 0)
                            // else
                            //{
                            //   User_Part_of_Queue.put(loggedInUser,false);
                            // } //else of if(ActorPartofQueueIds.size() > 0)
                            
                            
                            WorkItemIDValue = stepswiid.id;
                            break;
                        }//
                    }
                    
                }//if(prcIns.Status == '')
                else
                {
                    IsApprovalPending = false;
                }
            }//for(ProcessInstance prcIns : processInsListPendingStatus)
        }//if(processInsListPendingStatus.size() > 0)
        return processInsList;
    }// 
    
    //method for Approval submit
    public pagereference submitApproval()
    {
        try{
            String ApprovalUrl = '/p/process/Submit?id='+TargetObjectIdvalue;
            pagereference pr = new pagereference(ApprovalUrl);
            //if(Test.isRunningTest() == false)
            {
                blob currentpagecontent =  pr.getContent();
                System.debug('--BLOB-->'+ currentpagecontent.toString());
                
            }
            pr.setRedirect(false);    
            IsApprovalPending = true;
        }//try
        catch(Exception ee)
        {
            String exceptionmsg = ee.getMessage();
            if(ee.getMessage().contains('500 status code'))
            {
                exceptionmsg = 'We found your request cannot be fulfilled :[ You do not have permission on this record to submitApproval ]';
            }
            ApexPages.Message msg = new ApexPages.Message(ApexPages.Severity.WARNING,exceptionmsg);
            ApexPages.addMessage(msg);
            system.debug('[]Exception : '+ee.getMessage() );
            
        }//catch
        return null;
        
    } // 
    
    
    private String comment = 'Approving request';
    private String action = 'Approved';
    private String workItemId = '';
    
    public void setComment(String comment){  this.comment = comment; }//
    public String getComment() { return comment; }
    
    public void setAction(String action){  this.action = action; }//
    public String getAction() { return action; }
    
    public void setWorkItemId(String workItemId){  this.workItemId = workItemId; }//
    public String getWorkItemId() { return workItemId; }
    
    //method to approve or reject the page
    public pagereference approveReject()
    {
        try{
            System.debug('--comment--> '+comment+' --action--> '+action+' --workItemId--> '+workItemId);
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setComments(comment);
            req.setAction(action);
            req.setNextApproverIds(new Id[] {UserInfo.getUserId()});
            req.setWorkitemId(workItemId);
            //submit the approval process
            Approval.ProcessResult result =  Approval.process(req);
            if(result.isSuccess())
            {
                IsApprovalPending  = false;
            }//
            
        }//try
        catch(Exception e)
        {
            System.debug('[]Exception: '+e.getMessage());
        }
        return null;
    }// 
    
}//END of class