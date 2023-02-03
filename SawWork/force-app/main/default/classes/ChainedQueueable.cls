/** 
 * @Class Name : ChainedQueueable 
 * @Created By : Aayushi Agrawal 
 * @Created Date : 11 March - 2021
 * @purpose  - This is meant to be the super-class for any Queueable job class we want to participate in a chain.
*/ 
public abstract class ChainedQueueable implements Queueable {
    // Reference to the chain this queueable belongs to, because we can't allow callbacks to the parent chain
    // for when this class's execute method ends. 
    public QueueableJobChain chain;
    /**
     * The constructor receives a chain as parameter. 
     */ 
    public ChainedQueueable(QueueableJobChain chain) {
        this.chain = chain;  
    } 
    
    /**
     * Executes the next queueable in the chain, if this queueable is in a chain. 
     */ 
    protected void executeNext() { 
        if (this.isChained()) {
            this.chain.runNext();
        }
    }
    
    /**
     * Sets the job's chain.
     */ 
    public void setChain(QueueableJobChain chain) {
        this.chain = chain;
       
    }
    
    
    /**
     * execute method from the Queueable interface. You're meant to override this in any sub-class.
     */ 
    public virtual void execute(QueueableContext context) {
        this.executeNext();
    }
    
    /**
     * Tells us if the job is in a chain or not. 
     */ 
    protected boolean isChained() {
        return this.chain != null;
    }

    /**
     * 
     */
    public virtual void chainOneMoreInstance(ChainedQueueable cq){
        this.chain.chainFirst(cq);
    }
}