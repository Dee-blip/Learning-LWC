@isTest
public class TestUtils
{
    public static void verifyPageMessageDisplayed(String pgMessage)
    {
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        boolean found = false;
        String tape='';
        for(Apexpages.Message msg:msgs){
            tape += msg.getDetail()+msg.getSummary();
            if (msg.getDetail().containsIgnoreCase(pgMessage)) 
                found = true;
        }

        System.Assert(found, 'Apex page messages : '+ tape);
    }

    public static void verifyNoErrorDisplayed()
    {
        List<Apexpages.Message> msgs = ApexPages.getMessages();
        boolean found = false;
        for(Apexpages.Message msg:msgs){
            if (!String.isBlank(msg.getDetail()))
            {
                found = true;
            }
        }

        System.Assert(!found, 'Apex page messages : '+ msgs);
    }

    public static void submitForApproval(Sobject rec)
    {
        if(rec.getSObjectType()==SFDC_MDF__c.sObjectType)
        {
            Test.setCurrentPage(Page.FundRequestButtonPage);
            ApexPages.currentPage().getParameters().put('fromButton','SubmitForApproval');
            ApexPages.currentPage().getParameters().put('recordId',rec.Id);

            FundRequestButtonPageController frbpc = new FundRequestButtonPageController();

            PageReference pageRef = frbpc.init();
        }
        else if(rec.getSObjectType()==SFDC_MDF_Claim__c.sObjectType)
        {
            String res= PRM_opportunity.submitForApproval(rec.Id);
            System.assert(res.toLowerCase().contains('succesfully submitted for approval'), 'Error while submitting fund claim:'+res);
        }
        else if(rec.getSObjectType()==Opportunity.sObjectType)
        {
            Test.setCurrentPage(Page.OpportunityButtonPage);
            ApexPages.currentPage().getParameters().put('fromButton','SubmitForApproval');
            ApexPages.currentPage().getParameters().put('recordId',rec.Id);
            ApexPages.currentPage().getParameters().put('rebate', 'false');
            ApexPages.currentPage().getParameters().put('fcm', 'Not Null');

            OpportunityButtonPageController op = new OpportunityButtonPageController();

            PageReference pageRef = op.init();

            Opportunity opp = [select id,FCM__c,Registration_Status__c,isRebateTCToShow__c,RecordTypeId from Opportunity where id=:rec.id];

            System.assert(opp.Registration_Status__c=='Pending', 'Opportunity did not get submitted:'+opp);

        }
    }

    public static void reviewRecord(Sobject rec, Boolean isApproved)
    {
        String reviewAction = isApproved ? 'Approve':'Reject';
        String reviewComments = isApproved ? 'Approving request in TestUtils':'Rejecting request in TestUtils';
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setComments(reviewComments);
        req.setAction(reviewAction);

        if(rec.getSObjectType() == SFDC_MDF__c.sObjectType)
        {
            req.setNextApproverIds(TestUtils.getNextApproverId(rec));
        }

        req.setWorkitemId(getWorkItemId(rec.Id));
        Approval.ProcessResult result =  Approval.process(req);

    }

    public static void approveRecordWithoutSettingNextApprover(Sobject rec)
    {
        Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        req.setComments('Approving');
        req.setAction('Approve');

        req.setWorkitemId(getWorkItemId(rec.Id));
        Approval.ProcessResult result =  Approval.process(req);
        System.assert(result.isSuccess(), 'Result Status:'+result.isSuccess());

        System.assertEquals(  'Approved', result.getInstanceStatus(),'Instance Status'+result.getInstanceStatus());

    }

    public static Id getWorkItemId(Id targetObjectId)
    {
        Id retVal = null;

        Integer tt=0;
        String approvers='';
        for(ProcessInstanceWorkitem workItem  : [Select Id,OriginalActor.Name from ProcessInstanceWorkitem where ProcessInstance.TargetObjectId =: targetObjectId order by createddate desc])
        {
            retVal  =  workItem.Id;
            tt++;
            approvers += workItem.OriginalActor.Name + ', ';

        }

        System.assert(tt==1, 'More than one approval items'+ approvers);
        return retVal;
    }

    public static String getApproverName(Id targetObjectId)
    {

        String approverName='';
        for(ProcessInstanceWorkitem workItem  : [Select Id,OriginalActor.Name from ProcessInstanceWorkitem where ProcessInstance.TargetObjectId =: targetObjectId order by createddate desc])
        {
            approverName += workItem.OriginalActor.Name + ',';

        }

        return approverName;
    }

    public static void approveRecord(Sobject rec)
    {
        reviewRecord(rec, true);
    }

    public static void rejectRecord(Sobject rec)
    {
        reviewRecord(rec, false);
    }

    public static List<Id> getNextApproverId(Sobject rec)
    {
        if(rec.getSObjectType()==SFDC_MDF__c.sObjectType)
        {
            Group regionalManagerQueue = [select id from Group where developername='Regional_Manager'];
            return new List<Id> {regionalManagerQueue.Id};
        }
        return new List<Id>{}; // SFORCE-80
    }

    public static Id getNextApproverUserId(Sobject rec)
    {
        if(rec.getSObjectType()==SFDC_MDF__c.sObjectType)
        {
            Set<Id> queueMembers = new Set<Id>();
            
            for(GroupMember gm :[select UserOrGroupId from GroupMember where Group.Developername='Regional_Manager' limit 10])
            {
                queueMembers.add(gm.UserOrGroupId);
            }

            User u1 = [select id from User where id in :queueMembers and isActive=true limit 1];
            return u1.Id;
        }
        return null;

    }

    public static Attachment attachFile(Id parentId)
    {
        Attachment att = (Attachment)new SobjectBuilder(Attachment.sObjectType)
            .eagerPopulate()
            .put(Attachment.ParentId, parentId)
            .create()
            .getRecord();

        return att;

    }


}