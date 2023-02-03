/*
Author: janantha
Description: Check for recursion in triggers.
Created date: 27/01/2015

Developer               Date                        Action
Sharath Prasanna        23 Dec 2016                 Added a function to reset the variables
*/

public Class CheckRecursion
{
    private static boolean run = true;
    //Created by shprasan for insert check
    private static boolean runInsert = true;
    public static boolean runOnce()
    {
        if(run)
        {
            run=false;
            return true;
        }
        else
        {
            return run;
        }
    }
    //start of changes by shprasan 
    public static boolean runInsertOnce()
    {
        if(runInsert)
        {
            runInsert = false;
            return true;
        }
        else
        {
            return runInsert;
        }
    }

    //Changes by Sharath: Added the function reset. This resets the variables, run and runInsert
    public static void reset()
    {
        run = true;
        runInsert = true;
    }

    //end of changes by shprasan        
}