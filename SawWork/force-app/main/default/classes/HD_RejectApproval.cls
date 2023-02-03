global without sharing class HD_RejectApproval {
	
    //@RemoteAction
    webservice static String rejectApproval(Id currentIncidentId){
        //Error Message Code
        //E101 = 'Nothing to Approve'
        //E102 = 'Invalid User' 

        //Approval.UnLockResult lrList = Approval.unlock(currentIncidentId, false);
        //Approval.unlock(currentIncidentId);
        //query the owner. if owner is a user compare against logged in user
        //if owner is a queue --- query the user in queue-if result is 1
        //then procced
        String errorSuccess = 'SUCCESS';
        Approval.ProcessResult pr;
        String loggedInUser = userinfo.getUserId();
		Boolean trueUser = false;
		BMCServiceDesk__Incident__c inc = [Select ownerId from BMCServiceDesk__Incident__c where id =: currentIncidentId];
		if(inc != null){
    		if(String.valueOf(inc.ownerId).substring(0,3)  == '005'){
        		System.debug('found user');
        		if(loggedInUser == inc.ownerId){
            		trueUser = true;
        		}
        	//compare with the logged in user
    		} else if (String.valueOf(inc.ownerId).substring(0,3) == '00G'){
        		System.debug('found a queue');
        		List<GroupMember> usersInQueue = [Select UserOrGroupId From GroupMember where GroupId =: inc.ownerId and UserOrGroupId =: loggedInUser ];
        		System.debug(usersInQueue.size());
        		if(usersInQueue.size() == 1){
            		trueUser = true;
        		}
    		}
		}

        if(trueUser){
            try{
            	Approval.ProcessWorkitemRequest pwr = new Approval.ProcessWorkitemRequest();
    			Id objectId = currentIncidentId;
    			List<ProcessInstance> procins = new List<ProcessInstance>([select Id from ProcessInstance where Status = 'Pending' and TargetObjectId = :objectId]);
                if(procins.size()>0){
                    List<ProcessInstanceWorkitem>  workitem = new List<ProcessInstanceWorkitem>([select Id from ProcessInstanceWorkitem where ProcessInstanceId = :procins[0].id]);
    				if ((workitem != null) && (workitem.size() > 0)){
                    	pwr.SetComments('Rejected by Staff User');
                    	pwr.setWorkItemId(workitem[0].id);
                    	pwr.setAction('Reject'); 
                    	pr = Approval.process(pwr);
    					system.debug(pr);
       				} 
                    // add a note
                    if(pr.success){
                        List<BMCServiceDesk__Action__c> actionList = [select Id from BMCServiceDesk__Action__c where BMCServiceDesk__Abbreviation__c = 'APPROVAL_INFO'];
            			BMCServiceDesk__IncidentHistory__c currentNote = new BMCServiceDesk__IncidentHistory__c();
            			currentNote.BMCServiceDesk__FKIncident__c=currentIncidentId;
            			currentNote.BMCServiceDesk__description__c='Approval Information';
            			currentNote.BMCServiceDesk__note__c='';
            			currentNote.HD_Action__c='APPROVAL_INFO';
            			currentNote.BMCServiceDesk__FKAction__c=actionList[0].Id;
            			insert currentNote;
                    }
                }else {
                    errorSuccess = 'E01';
                }
            } catch (Exception e){
                System.debug('Error : ' + e);
            }
                
    			
        } else{
            errorSuccess = 'E02';
        }
        return errorSuccess;
    }    
}