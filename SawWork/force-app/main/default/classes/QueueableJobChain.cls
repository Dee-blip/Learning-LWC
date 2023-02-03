/**
* @Class Name : QueueableJobChain
 * @Created By : Aayushi Agrawal 
 * @Created Date : 11 March - 2021
 * @purpose  - Implements a chain of Queueable jobs.
 */
public class QueueableJobChain {

    public integer runCount ;
    // Here we store the current list
    public List<ChainedQueueable> chain; 
      
    public QueueableJobChain() {
        this.chain = new List<ChainedQueueable>(); 
    }
    /**
     * Adds a queueable to the beginning of the chain.
     */ 
    public void chainFirst(ChainedQueueable cq) {
        this.chain.add( cq);
        
    }
    /** 
     * Checks if there are more items in the chain left to be run
     */ 
    public Boolean hasNext() {
        return this.chain.size() > 0; 
    }
 
    
    /**
     * Runs the first queueable in the list.
     */ 
    public void runNext() { 
        if (this.hasNext()) { 
            ChainedQueueable cq = this.chain.remove(0);
            cq.setChain(this);
            System.debug(cq);
            if(!test.isRunningTest()){
                System.enqueueJob(cq);   
            }
                    
        } 
    }//end of runNext method
}//end of QueueableJobChain class