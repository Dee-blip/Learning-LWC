public class LawgPlatformEventTriggerHandler
{
    public static void afterInsert(List<Lawg__e> lgs)
    {
        if(lgs==null || lgs.size()==0) return;

        try 
        {
                Sawyer.saw(lgs);
        } 
        catch (Exception e) 
        {
            // dont retry
        }
    }

}