public class PSA_CronGDRATController 
{
	public string executeGDRATAlignment()
    {
        PSA_updateGDRATalignment ex = new PSA_updateGDRATalignment();
      	ex.updateGDRAT();
        
        PSA_ReallignProjects reAlignProjects = new PSA_ReallignProjects();
    	database.executebatch(reAlignProjects);
        
        return '1:completed'; 
        
    }
    
}