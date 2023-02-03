public with sharing class HDApprovalHomeComponent {

public ID loggedInUser{
get{
return Userinfo.getUserId();
}}
private Integer Maxrowlimit  = 200;
private Integer maxbatchsize = 1;
public Integer currentBatchNumber{get;set;}

public Integer currentrowlimit{get;set;}
public Integer workitemidsretrived{get;set;}
public Integer showmorenumber{get;set;}


//constructor
public HDApprovalHomeComponent(){
//change this to increase the row displayed at a time
currentrowlimit = 4;
//batch number initial page
currentBatchNumber = 1;

}//contructor



public List<ApprovalProcessDetailsforUser> getApprovaldetails()
{
 
//Getting the ActorId and actor Related Queue 
List<Id> ActorId = new List<Id>();
//adding the Current UserId first
ActorId.add(loggedInUser);
List<GroupMember> ActorPartofQueueIds = new List<GroupMember>();
ActorPartofQueueIds = [ SELECT Id, Group.Name,Group.Id FROM GroupMember WHERE UserOrGroupId =:loggedInUser AND Group.Type = 'Queue' Limit 200 ];
//adding the GroupMember id to ActorId List
for( GroupMember grpmem : ActorPartofQueueIds){ ActorId.add(grpmem.Group.Id);}
System.debug('Actor Ids List --->'+ActorId);

List<ProcessInstanceWorkitem> processinsWI = new List<ProcessInstanceWorkitem>();
List<Id> processinsWIID = new List<Id>();
//map to create the mapping between ProcessInstance Id and WorkItem ID
Map<Id,Id> processInstanancetoWorkitemIdmap = new Map<Id,Id>();

List<ProcessInstance> processInstanceList = new List<ProcessInstance>();
List<ApprovalProcessDetailsforUser> ApprovalProcessDetailsforUserList = new List<ApprovalProcessDetailsforUser>();

//List for storing Id if type is Incident
List<Id> incidentTypeIDList = new List<Id>();
List<BMCServicedesk__Incident__c> incidentrecordList = new List<BMCServicedesk__Incident__c>();

processinsWI = [Select Id, ActorId,ProcessInstanceId From ProcessInstanceWorkitem  Where Actorid IN:ActorId ORDER BY CreatedDate DESC LIMIT 200];
//setting Worklitemrow size
workitemidsretrived = processinsWI.size();
if(processinsWI.size() > 0)
{
System.debug(' WorkItem ID ---> '+processinsWI);
//getting Id's for the associated Process Instance
for(ProcessInstanceWorkitem pwI : processinsWI )
{ 
processinsWIID.add(pwI.ProcessInstanceId);
processInstanancetoWorkitemIdmap.put(pwI.ProcessInstanceId,pwI.Id); 
}

System.debug(' processinsWIID List ---> '+processinsWIID);
System.debug(' processInstanancetoWorkitemIdmap Map ---> '+processinsWIID);
processInstanceList = [SELECT Id,TargetObjectId,TargetObject.Name,TargetObject.type,CreatedDate,Status,LastActor.Name, (SELECT Id, ActorId, Actor.Name, OriginalActorId, OriginalActor.Name, StepStatus, Comments,CreatedDate  FROM StepsAndWorkitems WHERE StepStatus='Approved' OR StepStatus='Pending'  ORDER BY CreatedDate DESC LIMIT 20) FROM ProcessInstance Where status ='Pending' AND id IN:processinsWIID  ORDER BY CreatedDate DESC  LIMIT :currentrowlimit];
System.debug('processInstanceList ---> '+processInstanceList);
System.debug('processInstanceList size ---> '+processInstanceList.size());

//calculate show more number while loading
if( workitemidsretrived > currentrowlimit )
{
showmorenumber = workitemidsretrived - currentrowlimit;
}//
else
{
showmorenumber = 0;
}//if( workitemidsretrived > currentrowlimit )



if( processInstanceList.size() > 0 )
{
for(ProcessInstance proins : processInstanceList)
{
 ApprovalProcessDetailsforUser apprprocDetforusr = new ApprovalProcessDetailsforUser();
 apprprocDetforusr.realtedtoName = proins.TargetObject.Name;
 apprprocDetforusr.realtedtoId = proins.TargetObjectId;
 Schema.SObjectType token = proins.TargetObjectId.getSObjectType();
 Schema.DescribeSObjectResult dr = token.getDescribe();
 //adding logic to change the type based upon Incident Ids
 if( dr.getLabel() == 'Incident')
 {
  incidentTypeIDList.add(proins.TargetObjectId);
 } 
 apprprocDetforusr.type = dr.getLabel();
 System.debug('processInstanancetoWorkitemIdmap.get(proins.Id) ----> '+processInstanancetoWorkitemIdmap.get(proins.Id));
 apprprocDetforusr.WorkItemId = processInstanancetoWorkitemIdmap.get(proins.Id);
 
 //setting Date
 apprprocDetforusr.DateSubmitted = proins.CreatedDate;
 
//lets get last approval one record only
for(ProcessInstanceHistory stepwiLastApproval : proins.StepsAndWorkitems)
{
if( stepwiLastApproval.StepStatus == 'Approved' )
{
  
 apprprocDetforusr.mostRecentApprover = stepwiLastApproval.Actor.Name;
 apprprocDetforusr.mostRecentApproverID = stepwiLastApproval.ActorId;
 break;
}//if( stepwiLastApproval.StepStatus = approval )

if( stepwiLastApproval.StepStatus == 'Pending' && stepwiLastApproval.ActorId == loggedInUser )
{
apprprocDetforusr.displayFlag = true;
//apprprocDetforusr.WorkItemId = stepwiLastApproval.Id;
}//

}//for(ProcessInstanceHistory stepwiLastApproval : proins.StepsAndWorkitems)

//adding through approvals which are in the User name
//if(apprprocDetforusr.displayFlag ==true)
//{
ApprovalProcessDetailsforUserList.add(apprprocDetforusr);
//}

}//for(ProcessInstance proins : processInstanceList)

}//if( processInstanceList.size() > 0 )

}//if(processinsWI.size() > 0)

System.debug('ApprovalProcessDetailsforUserList ---> '+ApprovalProcessDetailsforUserList );
//Lets change the type name here
if( incidentTypeIDList.size() > 0 )
{
incidentrecordList = [Select id,BMCServiceDesk__Type__c from BMCServiceDesk__incident__c WHERE Id IN:incidentTypeIDList ]; 
System.Debug(' incidentrecordList ----> ' +incidentrecordList);
for(ApprovalProcessDetailsforUser appprcdetfUsr : ApprovalProcessDetailsforUserList)
{
 for(BMCServiceDesk__incident__c  inc : incidentrecordList)
 {
   if(appprcdetfUsr.realtedtoId == inc.id)
   {
     appprcdetfUsr.type = inc.BMCServiceDesk__Type__c;
   }//if(appprcdetfUsr.realtedtoId == inc.id)
 }//for(BMCServiceDesk__incident__c  inc : incidentrecordList)
}//for(ApprovalProcessDetailsforUser appprcdetfUsr : ApprovalProcessDetailsforUserList)
}//if( incidentTypeIDList.size() > 0 ) 


return ApprovalProcessDetailsforUserList;
}//

public void approvalrow()
{
//calculate the next number of records to be show based in the batch size
currentBatchNumber = currentBatchNumber +1;
//Integer number of batches
Integer noOfbatches = ( workitemidsretrived / maxbatchsize);

if ( currentBatchNumber < noOfbatches )
{
currentrowlimit = (noOfbatches - currentrowlimit) + currentrowlimit;
}
else
{
currentrowlimit = currentrowlimit + noOfbatches ;
}


//calculate show more number while loading
if( workitemidsretrived >= currentrowlimit )
{
showmorenumber = workitemidsretrived - currentrowlimit;
}



getApprovaldetails();
}//public void approvalrow()


//Wrapper class for the Approval Model
public class ApprovalProcessDetailsforUser
{

public boolean displayFlag{get;set;}
public Id WorkItemId{get;set;}
public String realtedtoName{get;set;}
public String realtedtoId{get;set;}
public String type{get;set;}
public String mostRecentApprover{get;set;}
public String mostRecentApproverID{get;set;}
public datetime DateSubmitted{get;set;}


}//public class ApprovalProcessDetailsforUser


}//ENDItem