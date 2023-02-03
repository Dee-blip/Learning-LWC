public with sharing class PA_EscalationClass{

    
    public static String CronJobHandler()
    {
        DateTime dt_now=System.Now();
        DateTime dt_prev = System.Now();
        
        if(dt_now.format('E') == 'Mon')
            dt_prev=System.Now().addHours(-48);
        
        String res='1:';
        if(dt_now.format('E') == 'Sat')
            if (!Test.isRunningTest()) {return res;}
        if(dt_now.format('E') == 'Sun')
            if (!Test.isRunningTest()) {return res;}
        System.Debug('Outside for loop');
        try{

            Integer firstEscalationWindow = 1;
            Integer secondEscalationWindow = 1;
            List<Product_Approvals__c> patoupdate = new List<Product_Approvals__c>();
        
            for (Product_Approvals__c pa : [Select Id,Escalation_Status__c,LastModifiedDate,Status__c,Assigned_Time__c, Approval_workflow__r.First_Escalation_Window__c, Approval_workflow__r.Second_Escalation_Window__c from Product_Approvals__c WHERE Escalation_Status__c!='CANCELLED' AND Escalation_Status__c!='SECOND' AND Status__c='PENDING-APPROVAL'])
            {
                System.debug('Inside For loop');
                firstEscalationWindow = pa.Approval_workflow__r.First_Escalation_Window__c == null ? 1 : Integer.ValueOf(pa.Approval_workflow__r.First_Escalation_Window__c);
                secondEscalationWindow = pa.Approval_workflow__r.Second_Escalation_Window__c == null ? 1 : Integer.ValueOf(pa.Approval_workflow__r.Second_Escalation_Window__c);

                if(pa.Escalation_Status__c=='NEW'){
                    dt_prev = dt_prev.addHours(firstEscalationWindow * -24);
                    if(pa.Assigned_Time__c < dt_prev){
                        pa.Escalation_Status__c='FIRST';
                        patoupdate.add(pa);
                        System.debug('New changed');
                    }
                }  
                else if(pa.Escalation_Status__c=='FIRST'){
                    dt_prev = dt_prev.addHours(secondEscalationWindow * -24);
                    if(pa.Assigned_Time__c < dt_prev){
                        pa.Escalation_Status__c='SECOND';
                        patoupdate.add(pa);
                        System.debug('first changed');
                    }
                }
            }
            
            System.debug('pa to update'+patoupdate.size());
            if (patoupdate.size()>0)
            {
                update patoupdate;
            }

        }
        catch(Exception e)
        {
            res='0:'+ e.getMessage();
        }
        return res;
        
    }
}