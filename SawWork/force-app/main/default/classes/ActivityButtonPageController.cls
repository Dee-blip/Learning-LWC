//SFDC-1659
public class ActivityButtonPageController
{
    PageReference pageRef;

    public static Id recordId;
    public static String taskType;
    public boolean oATask{get;set;}

    public PageReference init()
    {
      //  oATask = false;
      /* SFDC-4178
        String fromButton;
        fromButton   = ApexPages.currentPage().getParameters().get('fromButton');

        if(!String.isBlank(fromButton))
        {
            if(fromButton == 'CreateOATask')
            {
                pageRef = createOATask();
                return pageRef;
            }
        }
        */
        return null;
    }

    //SFDC-2043
    public PageReference backToOrderApprovalPage(){

        recordId = ApexPages.currentPage().getParameters().get('recordId');
        pageRef = new PageReference('/'+recordId);

        pageRef.setRedirect(true);
        return pageRef;
    }

    //SFDC-2043
    public PageReference backToAccountPage(){
        recordId = ApexPages.currentPage().getParameters().get('recordId');
        Order_Approval__c order = [select id, Associated_Opportunity__r.accountid from Order_Approval__c where id = :recordId];
        System.debug('Mayank, order : ' +order);
        String accId = order.Associated_Opportunity__r.accountid;
        System.debug('Mayank, accId : ' +accId);
        pageRef = new PageReference('/'+accId);
        pageRef.setRedirect(true);
        return pageRef;
    }

    /* SFDC-4178
    public PageReference createOATask()
    {
        
        oATask = true;
        String URL;
        // put it in try catch - in case of error, put it in page message
        recordId = ApexPages.currentPage().getParameters().get('recordId');
        taskType = ApexPages.currentPage().getParameters().get('TaskType');

        //SFDC-2043
       Order_Approval__c oac = [select Associated_Account__c, Associated_Opportunity__r.accountid,
                                    Associated_Opportunity__r.account.billingCountry, Associated_Opportunity__r.account.gst__c
                                   from Order_Approval__c 
                                   where Id=:recordId];
        if(oac.Associated_Opportunity__r.account.BillingCountry.touppercase() == 'INDIA' && oac.Associated_Opportunity__r.account.GST__c == null){
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please add GST# to this account.To create an order form, GST# is required.Please return to the order approval.'));
            return null;
        }

        try
        {
            URL = OrderApprovalClass.Create_Task(recordId,taskType);
        }

        catch(Exception e)
        {
            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Task creation failed. '+e.getMessage()));
            return null;
        }

        pageRef = new PageReference(URL);
        pageRef.setRedirect(true);

        return pageRef;
        
    }
    */
}