public class PromiseErrorDebugger implements Promise.Error{
private String errorMessage;

    public PromiseErrorDebugger() {
    }
    public Object error(Exception e) {
      //for now, just dump it to the logs
      system.debug(LoggingLevel.Error, 'Error Handler received the following exception ' + e.getmessage() + '\n\n' + e.getStackTraceString());
      //Make the error available for testing.
      this.errorMessage = e.getMessage();
      //Alternatively, you could do any number of things with this exception like:
      // 1. retry the promise chain. For instance, if an external service returns a temp error, retry
      return e;
    }

  }