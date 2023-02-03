public class PSA_GDRAT_Controller {

    public PageReference updateOldRegions() {
    
        PSA_RealignRegions ex = new PSA_RealignRegions();
        ex.updateOldRegions();
        return null;
    }


    public Pagereference deletOldGDRAT() 
    {
        PSA_RealignRegions ex= new PSA_RealignRegions();
        ex.deleteOldRegions();
        
        return NULL;
    }


    public Pagereference updateRR() 
    {
        PSA_ReallignRR reallignRR= new PSA_ReallignRR();
        database.executebatch(reallignRR);
        return NULL;
    }


    public Pagereference updateProjects() 
    {
    
    PSA_ReallignProjects reAlignProjects = new PSA_ReallignProjects();
    database.executebatch(reAlignProjects);
    return NULL;
        
    }


    public Pagereference updateGDRAT() 
    {
      
      PSA_updateGDRATalignment ex = new PSA_updateGDRATalignment();
      ex.updateGDRAT();
      return null;
        
    }


    public PageReference save() {
        return null;
    }

}