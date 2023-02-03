public class GsmLite_AccntReAssignmentCtrl
{
    PageReference pageRef;

    public static Id recordId, recordTypeId,accReassignId;

    public PageReference init()
    {
        String fromButton;

        fromButton   = ApexPages.currentPage().getParameters().get('fromButton');
        recordId     = ApexPages.currentPage().getParameters().get('recordId');
        accReassignId = ApexPages.currentPage().getParameters().get('accReassignId');

        if(!String.isBlank(fromButton))
        {
            if(fromButton == 'Escalate')
            {
                pageRef = escalate();
                return pageRef;
            }
        }

        return null;
    }

    public PageReference escalate()
    {
        String result,resultMessage;

        try
        {
            result = AccountReassignmentInterfaceClass.EscalateButton(accReassignId);
        }

        catch(Exception err)
        {
            String myRegExp = 'INSUFFICIENT_ACCESS';
            String errString = err+'';
            if(errString.contains(myRegExp) != true)
                resultMessage = '0:You do not have sufficient access to escalate. Please mail Globalsalesops@akamai.com for further assistance.';
            else
                resultMessage = '0:An unexpected error has occurred. Please contact your System Administrator\n' + 'Error : ' + err;
        }

        

        if(result == '1')
        {
            pageRef = new PageReference('/apex/AccountReassignmentEscalation');
            pageRef.setRedirect(true);
            pageRef.getParameters().put('id', accReassignId);
            return pageRef;
        }

        else
        {
            System.debug('resultMessage :'+resultMessage);
            if(resultMessage!=null && resultMessage!='')
            {
                String resultFlag = resultMessage.substring(0, resultMessage.indexOf(':'));
                String message = resultMessage.substring(resultMessage.indexOf(':') + 1, resultMessage.length());
                ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, message));
            }
            if(result!=null)
	            ApexPages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, result));
            return null;
        }
    }


}