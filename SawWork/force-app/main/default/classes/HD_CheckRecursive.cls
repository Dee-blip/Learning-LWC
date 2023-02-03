/*
Template: Apex Class/Trigger Template 

CopyRight: Hemant Kumar @ Akamai Technologies Ltd.

Version: 1.0

Created Date : 

Base Line : Used as apart of Utility Class

Purpose : an implementation for Recursion control
          
Usage : used as an implementation for the trigger to avoid executing trigger more than onces.
          
Test Class Asssociated : NONE

Controller (Boolean): False

Page Used/Asssociated (default -> NONE) : NONE

Trigger Associated : [ HD_Problem_Customization, ]
Class used : 
              
*/
public class HD_CheckRecursive {
	private static boolean trigger_run = true; 
    public static boolean sharingRevoked = true;
    
    public static boolean revokeOnce(){
        
        if(sharingRevoked)
		{
			sharingRevoked=false;
			return true;
		}//if(trigger_run)
		else
		{
			return sharingRevoked;
		}//else
    }
    
	public static boolean runOnce()
	{
		if(trigger_run)
		{
			trigger_run=false;
			return true;
		}//if(trigger_run)
		else
		{
			return trigger_run;
		}//else
	}
	

}//END