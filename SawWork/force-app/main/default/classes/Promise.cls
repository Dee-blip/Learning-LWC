/*
	Usage - 


   new Promise(new AsyncAction()).then(new YetAnotherAsyncAction()).execute();


   where AsyncAction and YetAnotherAsyncAction both implement theb resolve method

   Heavily based on - https://github.com/ChuckJonas/APEX-Q
                      https://github.com/codefriar/promise

 */



Public Virtual Class Promise Implements Queueable, Database.AllowsCallouts {

    Protected List<Promise.Deferred> promiseStack = new List<Promise.Deferred>();

    Protected Object promiseData;
    Protected Promise.Error errorHandler;


    Public Promise(Promise.Deferred deferred) {
        then(deferred);
    }
    
    Public Promise() {}

    Public Promise then(Promise.Deferred deferred) {
        promiseStack.add(deferred);
        return this;
    }

    Public Promise error(Promise.Error errorHandler) {
        this.errorHandler = errorHandler;
        return this;
    }

    Public Void execute(Object input) { promiseData = input; System.enqueueJob(this); }

    Public Void execute() {
        System.enqueueJob(this);
    }

    Public Void execute(QueueableContext context) 
    {
        try 
        {
            Promise.Deferred currentPromise = promiseStack.remove(0);
            promiseData = currentPromise.resolve(promiseData);
            if (promiseStack.size() > 0) 
            {
                System.enqueueJob(this);return;
            }
        } 
        catch (Exception e) 
        {
            promiseData = errorHandler.error(e);
        }
    }

    Public Interface Deferred {
        Object resolve(Object input);
    }

    Public Interface Error {
        Object error(Exception e);
    }

}