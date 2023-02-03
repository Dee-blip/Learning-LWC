/***
    PSA_RR_Actions
    @author Samir Jha
    @Description : This Class contains methods to capture the OLA at RR (CR:2808372)
                 
    @History
    --Developer           --Date            --Change
    Samir Jha         5/5/2015     Created the class.       
*/
public class PSA_RR_Actions 
{
    //Start timer when status is moved to Ready to Staff
    public static void startTimer(list<pse__Resource_Request__c> RRStartTimerList)
    {
        for(pse__Resource_Request__c rr1:RRStartTimerList)
        {
            rr1.Ready_to_Staff_Timer_Start__c  = system.now();
            
        }
    }
    //Ready to staff timer should stop when status is changed.
    public static void StopTimer(list<pse__Resource_Request__c> RRStopTimerList)
    {
       
       if(CheckRecursion.runOnce())
       {
        for(pse__Resource_Request__c rr1:RRStopTimerList)
        {
            rr1.Ready_to_Staff_Timer_Stop__c  = system.now(); 
            if(rr1.Hours_in_Ready_to_Staff__c == NULL)
            {
                rr1.Hours_in_Ready_to_Staff__c = (Double)((Double)(system.now().getTime() - rr1.Ready_to_Staff_Timer_Start__c.getTime())/(1000*60*60));
                system.debug('#New'+ rr1.Hours_in_Ready_to_Staff__c);
            }
            else
            {
                rr1.Hours_in_Ready_to_Staff__c += (Double)((Double)(system.now().getTime() - rr1.Ready_to_Staff_Timer_Start__c.getTime())/(1000*60*60));
                system.debug('#Old'+ rr1.Hours_in_Ready_to_Staff__c);
            }
            
            }
       }
    }
}